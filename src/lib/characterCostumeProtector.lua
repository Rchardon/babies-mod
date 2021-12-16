local VERSION = "1.2.2"

--Character Costume Protector by Sanio! (Sanio46 on Steam and Twitter)
--This local library has the goal of protecting the unique looks of custom characters that regularly
--interfere with how costumes look while allowing customization between different characters with ease.

--For any questions, contact Sanio or leave a comment under the workshop upload, preferably the latter.

local ccp = {}
local game = Game()

local playerToProtect = {}
local playerCostume = {}
local playerSpritesheet = {}
local playerItemCostumeWhitelist = {}
local playerNullItemCostumeWhitelist = {}
local playerTrinketCostumeWhitelist = {}
local defaultItemWhitelist = {
	[CollectibleType.COLLECTIBLE_HOLY_MANTLE] = true,
	[CollectibleType.COLLECTIBLE_DADS_RING] = true,
}
local defaultNullItemWhitelist = {}
local nullEffectsBlacklist = {}
local CallbacksTable = {
	["MC_POST_COSTUME_RESET"] = {},
	["MC_POST_COSTUME_DEINIT"] = {},
	["MC_POST_COSTUME_INIT"] = {}
}

--List of player data for convenience and explanation--
--[[
	data.CCP.HasCostumeInitialized: Boolean. Used for initializing the player data adding them to the system in place.

	data.CCP.NumCollectibles: Int. Tracking player:GetCollectibleCount for a change to reset costume

	data.CCP.NumTemporaryEffects: Int. Tracking the length of player:GetEffects():GetEffectsList() for a change to reset costume.

	data.CCP.CustomFlightCostume: Boolean. Tracks when you suddenly gain/lose flight to reset costume.

	data.CCP.DelayCostumeReset: Boolean. For lots of various callbacks in this code, the costume is added after its callback. This is set to true
	and immediately resets your costume before returning to nil on the next frame.

	data.CCP.QueueCostumeRemove: Table. Similar to DelayCostumeReset, but the table contains items to remove only that item's costume.
	Used for Modeling Clay, Whore of Babylon, Empty Vessel, and Taurus.

	data.CCP.DelayTaurusCostumeReset: Boolean. When entering an uncleared room, waits for you to reach max speed to remove Taurus' costume.

	data.CCP.AstralProjectionDisabled = Boolean. As Astral Projection's temporary effect is not auto-removed when returning to your normal form,
	unlike Spirit Shackles, manual detection is needed. This is to stop adding Astral Projection's costume during a costume reset.
	True after getting hit in your ghost form or clearing a room. False upon losing the temporary effect.

	data.CCP.MineshaftEscape = Boolean. Set to true to reset your costume once upon confirming you're in the Mineshaft Escape Sequence dimension
	As of writing this, there's a bug where costumes can't be added inside the dimension anyway. Hopefully the code works as intended if it's fixed.
]]

---------------------
--  API FUNCTIONS  --
---------------------

local function apiError(isBasic, func, invalidVar, num, expectedType)
	if isBasic == true and func ~= nil then
		local err = "(CCP) Something went wrong in ccp:"..func.."!"
		error(err)
		Isaac.DebugString(err)
	elseif not isBasic then
		if invalidVar == nil
		or type(invalidVar) ~= expectedType
		then
			err = "Bad Argument #"..num.." in "..func.."(Attempt to index a " .. type(invalidVar) .. " value, field '" .. tostring(invalidVar) .. "', expected "..expectedType..")."
			error(err)
			Isaac.DebugString(err)
		end
	end
end

local function initiateItemWhitelist(playerType)
	playerItemCostumeWhitelist[playerType] = {}
	for itemID, boolean in pairs(defaultItemWhitelist) do
		playerItemCostumeWhitelist[playerType][itemID] = boolean
	end
end

local function initiateNullItemWhitelist(playerType)
	playerNullItemCostumeWhitelist[playerType] = {}
	for nullItemID, boolean in pairs(defaultNullItemWhitelist) do
		playerNullItemCostumeWhitelist[playerType][nullItemID] = boolean
	end
end

function ccp:addPlayer(
player, playerType, spritesheetNormal, costumeFlight, spritesheetFlight, costumeExtra
)
	if player ~= nil
	and type(player) == "userdata"
	and playerType ~= nil
	and type(playerType) == "number"
	and spritesheetNormal ~= nil
	and type(spritesheetNormal) == "string" then
		playerToProtect[playerType] = true
		playerCostume[playerType] = {}
		playerSpritesheet[playerType] = {}
		playerSpritesheet[playerType]["Normal"] = spritesheetNormal
		initiateItemWhitelist(playerType)
		initiateNullItemWhitelist(playerType)
		playerTrinketCostumeWhitelist[playerType] = {}

		if costumeFlight ~= nil then
			playerCostume[playerType]["Flight"] = costumeFlight
		end
		if costumeExtra ~= nil then
			playerCostume[playerType]["Extra"] = costumeExtra
		end

		if spritesheetFlight ~= nil then
			playerSpritesheet[playerType]["Flight"] = spritesheetFlight
		end

		if not REPENTANCE
		or (REPENTANCE and not player:IsCoopGhost())
		then
			local data = player:GetData()

			ccp:mainResetPlayerCostumes(player)
			data.CCP = {}
			data.CCP.NumCollectibles = player:GetCollectibleCount()
			data.CCP.NumTemporaryEffects = player:GetEffects():GetEffectsList().Size
			data.CCP.TrinketActive = {}
			data.CCP.QueueCostumeRemove = {}
			data.CCP.HasCostumeInitialized = {
				[playerType] = true
			}
			ccp:afterCostumeInit(player)
		end
	else
		local func = "AddPlayer"
		if player == nil
		or type(player) ~= "userdata"
		then
			apiError(false, func, player, "1", "userdata")
		elseif playerType == nil
		or type(playerType) ~= "number"
		then
			apiError(false, func, playerType, "2", "number")
		elseif spritesheetNormal == nil
		or type(spritesheetNormal) ~= "string"
		then
			apiError(false, func, spritesheetNormal, "3", "string")
		else
			apiError(true, func)
		end
	end
end

function ccp:updatePlayer(
player, playerType, spritesheetNormal, costumeFlight, spritesheetFlight, costumeExtra
)
	if player ~= nil
	and type(player) == "userdata"
	and playerType ~= nil
	and playerToProtect[playerType] == true then

		if spritesheetNormal ~= nil then
			playerSpritesheet[playerType]["Normal"] = spritesheetNormal
		end

		if costumeFlight ~= nil then
			playerCostume[playerType]["Flight"] = costumeFlight
		else
			playerCostume[playerType]["Flight"] = nil
		end

		if spritesheetFlight ~= nil then
			playerSpritesheet[playerType]["Flight"] = spritesheetFlight
		else
			playerSpritesheet[playerType]["Flight"] = nil
		end

		if costumeExtra ~= nil then
			playerCostume[playerType]["Extra"] = costumeExtra
		else
			playerCostume[playerType]["Extra"] = nil
		end

		ccp:mainResetPlayerCostumes(player)
	else
		local func = "UpdatePlayer"
		if player == nil
		or type(player) ~= "userdata"
		then
			apiError(false, func, player, "1", "userdata")
		elseif playerType == nil
		or type(playerType) ~= "number"
		then
			apiError(false, func, playerType, "2", "number")
		else
			apiError(true, func)
		end
	end
end

function ccp:itemCostumeWhitelist(playerType, costumeList)
	if playerType ~= nil
	and type(playerType) == "number"
	and costumeList ~= nil
	and type(costumeList) == "table"
	then
		for itemID, bool in pairs(costumeList) do
			if itemID ~= nil
			and type(itemID) == "number"
			and bool ~= nil
			and type(bool) == "boolean"
			then
				playerItemCostumeWhitelist[playerType][itemID] = bool
			end
		end
	else
		local func = "ItemCostumeWhitelist"
		if playerType == nil
		or type(playerType) ~= "number" then
			apiError(false, func, player, "1", "userdata")
		elseif costumeList == nil
		or type(costumeList) ~= "table" then
			apiError(false, func, costumeList, "2", "table")
		else
			apiError(true, func)
		end
	end
end

function ccp:nullEffectWhitelist(playerType, costumeList)
	if playerType ~= nil
	and type(playerType) == "number"
	and costumeList ~= nil
	and type(costumeList) == "table"
	then
		for nullItemID, bool in pairs(costumeList) do
			if itemID ~= nil
			and type(itemID) == "number"
			and bool ~= nil
			and type(bool) == "boolean"
			then
				playerNullItemCostumeWhitelist[playerType][nullItemID] = bool
			end
		end
	else
		local func = "NullEffectWhitelist"
		if playerType == nil
		or type(playerType) ~= "number" then
			apiError(false, func, player, "1", "userdata")
		elseif costumeList == nil
		or type(costumeList) ~= "table" then
			apiError(false, func, costumeList, "2", "table")
		else
			apiError(true, func)
		end
	end
end

function ccp:trinketCostumeWhitelist(playerType, costumeList)
	if playerType ~= nil
	and type(playerType) == "number"
	and costumeList ~= nil
	and type(costumeList) == "table"
	then
		for trinketID, bool in pairs(costumeList) do
			if itemID ~= nil
			and type(itemID) == "number"
			and bool ~= nil
			and type(bool) == "boolean"
			then
				playerTrinketCostumeWhitelist[playerType][trinketID] = bool
			end
		end
	else
		local func = "TrinketCostumeWhitelist"
		if playerType == nil
		or type(playerType) ~= "number" then
			apiError(false, func, player, "1", "userdata")
		elseif costumeList == nil
		or type(costumeList) ~= "table" then
			apiError(false, func, costumeList, "2", "table")
		else
			apiError(true, func)
		end
	end
end

function ccp.addCallback(callback, newFunction)
	if CallbacksTable[callback] then
		table.insert(CallbacksTable[callback], newFunction)
	else
		error("Bad Argument #1 in ccp.AddCallback (Attempt to index a " .. type(callback) .. "value, field '" .. tostring(callback) .. "'")
	end
end

-----------------
--  CALLBACKS  --
-----------------

--Callback logic provided by AgentCucco

function ccp:afterCostumeInit(player)
	for _, callback in ipairs(CallbacksTable["MC_POST_COSTUME_INIT"]) do
		callback(player)
	end
end

function ccp:afterCostumeReset(player)
	for _, callback in ipairs(CallbacksTable["MC_POST_COSTUME_RESET"]) do
		callback(player)
	end
end

function ccp:afterCostumeDeinit(player)
	for _, callback in ipairs(CallbacksTable["MC_POST_COSTUME_DEINIT"]) do
		callback(player)
	end
end

--------------
--  LOCALS  --
--------------

local collectiblesEffectsOnlyAddOnEffect = {
	[CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON] = true,
	[CollectibleType.COLLECTIBLE_MOMS_BRA] = true,
	[CollectibleType.COLLECTIBLE_EMPTY_VESSEL] = true,
	[CollectibleType.COLLECTIBLE_RAZOR_BLADE] = true,
	[CollectibleType.COLLECTIBLE_THE_NAIL] = true,
	[CollectibleType.COLLECTIBLE_MY_LITTLE_UNICORN] = true,
	[CollectibleType.COLLECTIBLE_GAMEKID] = true,
	[CollectibleType.COLLECTIBLE_SHOOP_DA_WHOOP] = true,
	[CollectibleType.COLLECTIBLE_DELIRIOUS] = true,
}

local activesToDelayCostumeReset = {
	[CollectibleType.COLLECTIBLE_RAZOR_BLADE] = true,
	[CollectibleType.COLLECTIBLE_MOMS_BRA] = true,
	[CollectibleType.COLLECTIBLE_THE_NAIL] = true,
	[CollectibleType.COLLECTIBLE_MY_LITTLE_UNICORN] = true,
	[CollectibleType.COLLECTIBLE_GAMEKID] = true,
	[CollectibleType.COLLECTIBLE_SHOOP_DA_WHOOP] = true,
	[CollectibleType.COLLECTIBLE_PONY] = true,
	[CollectibleType.COLLECTIBLE_WHITE_PONY] = true,
	[CollectibleType.COLLECTIBLE_D4] = true,
	[CollectibleType.COLLECTIBLE_D100] = true,
	[CollectibleType.COLLECTIBLE_DELIRIOUS] = true,

}

local costumeTrinkets = {
	[TrinketType.TRINKET_TICK] = true,
	[TrinketType.TRINKET_RED_PATCH] = true
}

local playerFormToNullItemID = {
	[PlayerForm.PLAYERFORM_GUPPY] = NullItemID.ID_GUPPY,
	[PlayerForm.PLAYERFORM_LORD_OF_THE_FLIES] = NullItemID.ID_LORD_OF_THE_FLIES,
	[PlayerForm.PLAYERFORM_MUSHROOM] = NullItemID.ID_MUSHROOM,
	[PlayerForm.PLAYERFORM_ANGEL] = NullItemID.ID_ANGEL,
	[PlayerForm.PLAYERFORM_BOB] = NullItemID.ID_BOB,
	[PlayerForm.PLAYERFORM_DRUGS] = NullItemID.ID_DRUGS,
	[PlayerForm.PLAYERFORM_MOM] = NullItemID.ID_MOM,
	[PlayerForm.PLAYERFORM_BABY] = NullItemID.ID_BABY,
	[PlayerForm.PLAYERFORM_EVIL_ANGEL] = NullItemID.ID_EVIL_ANGEL,
	[PlayerForm.PLAYERFORM_POOP] = NullItemID.ID_POOP,
	[PlayerForm.PLAYERFORM_BOOK_WORM] = NullItemID.ID_BOOK_WORM,
	[PlayerForm.PLAYERFORM_ADULTHOOD] = NullItemID.ID_ADULTHOOD,
	[PlayerForm.PLAYERFORM_SPIDERBABY] = NullItemID.ID_SPIDERBABY,
}

if REPENTANCE then
	defaultNullItemWhitelist = {
		[NullItemID.ID_MARS] = true,
		[NullItemID.ID_TOOTH_AND_NAIL] = true,
		[NullItemID.ID_ESAU_JR] = true,
		[NullItemID.ID_SPIRIT_SHACKLES_SOUL] = true,
		[NullItemID.ID_SPIRIT_SHACKLES_DISABLED] = true,
		[NullItemID.ID_LOST_CURSE] = true
	}

	defaultItemWhitelist[CollectibleType.COLLECTIBLE_SPIRIT_SHACKLES] = true
	defaultItemWhitelist[CollectibleType.COLLECTIBLE_ASTRAL_PROJECTION] = true

	nullEffectsBlacklist = {
		[NullItemID.ID_HUGE_GROWTH] = true,
		[NullItemID.ID_ERA_WALK] = true,
		[NullItemID.ID_HOLY_CARD] = true,
		[NullItemID.ID_SPIN_TO_WIN] = true,
		[NullItemID.ID_INTRUDER] = true,
		[NullItemID.ID_REVERSE_HIGH_PRIESTESS] = true,
		[NullItemID.ID_REVERSE_STRENGTH] = true,
		[NullItemID.ID_REVERSE_TEMPERANCE] = true,
		[NullItemID.ID_EXTRA_BIG_FAN] = true,
		[NullItemID.ID_DARK_ARTS] = true,
		[NullItemID.ID_LAZARUS_SOUL_REVIVE] = true,
		[NullItemID.ID_SOUL_MAGDALENE] = true,
		[NullItemID.ID_SOUL_BLUEBABY] = true,
		[NullItemID.ID_MIRROR_DEATH] = true,
		[NullItemID.ID_SOUL_FORGOTTEN] = true,
		[NullItemID.ID_SOUL_JACOB] = true,
	}

	collectiblesEffectsOnlyAddOnEffect[CollectibleType.COLLECTIBLE_LARYNX] = true
	collectiblesEffectsOnlyAddOnEffect[CollectibleType.COLLECTIBLE_TOOTH_AND_NAIL] = true
	collectiblesEffectsOnlyAddOnEffect[CollectibleType.COLLECTIBLE_ASTRAL_PROJECTION] = true

	activesToDelayCostumeReset[CollectibleType.COLLECTIBLE_LARYNX] = true
	activesToDelayCostumeReset[CollectibleType.COLLECTIBLE_SULFUR] = true
	activesToDelayCostumeReset[CollectibleType.COLLECTIBLE_LEMEGETON] = true

	costumeTrinkets[TrinketType.TRINKET_AZAZELS_STUMP] = true
end

-----------------------
--  LOCAL FUNCTIONS  --
-----------------------

local function onSpiritShacklesGhost(player)
	local playerType = player:GetPlayerType()

	player:ClearCostumes()
	if playerCostume[playerType]["Extra"] ~= nil then
		local costumeExtra = playerCostume[playerType]["Extra"]
		player:AddNullCostume(costumeExtra)
	end
end

local function addAllWhitelistedCostumes(player)
	local playerType = player:GetPlayerType()
	local playerEffects = player:GetEffects()
	local data = player:GetData()

	--Item Costumes
	if playerItemCostumeWhitelist[playerType] then
		for itemID, _ in pairs(playerItemCostumeWhitelist[playerType]) do
			local itemCostume = Isaac.GetItemConfig():GetCollectible(itemID)

			if ccp:canAddCollectibleCostume(player, itemID)
			and playerItemCostumeWhitelist[playerType][itemID] == true then
				player:AddCostume(itemCostume, false)
			end
		end
	end

	--Item Costumes Only On Effect
	for itemID, boolean in pairs(collectiblesEffectsOnlyAddOnEffect) do
		if playerEffects:HasCollectibleEffect(itemID)
		and playerItemCostumeWhitelist[playerType][itemID] == true
		then
			local itemCostume = Isaac.GetItemConfig():GetCollectible(itemID)

			if itemID ~= CollectibleType.COLLECTIBLE_ASTRAL_PROJECTION then
				player:AddCostume(itemCostume)
			elseif not player:GetData().CCP_AstralProjectionDisabled then
				player:AddCostume(itemCostume)
			end
		end
	end

	--Null Costumes
	for nullItemID, _ in pairs(playerNullItemCostumeWhitelist) do
		if playerEffects:HasNullEffect(nullItemID)
		and not nullEffectsBlacklist[nullItemID] then
			if REPENTANCE and nullItemID == NullItemID.ID_SPIRIT_SHACKLES_SOUL then
				onSpiritShacklesGhost(player)
			end
			player:AddNullCostume(nullItemID)
		end
	end

	--Trinkets
	for trinketID, _ in pairs(costumeTrinkets) do
		if ((trinketID == TrinketType.TRINKET_TICK
		and player:HasTrinket(trinketID))
		or playerEffects:HasTrinketEffect(trinketID))
		and data.CCP.TrinketActive[trinketID]
		and playerTrinketCostumeWhitelist[playerType][trinketID] == true then
			local trinketCostume = Isaac.GetItemConfig():GetTrinket(trinketID)
			player:AddCostume(trinketCostume)
		end
	end

	--Transformations
	for playerForm, nullItemID in pairs(playerFormToNullItemID) do
		if player:HasPlayerForm(playerForm)
		and playerNullItemCostumeWhitelist[playerType][nullItemID] == true
		then
			player:AddNullCostume(nullItemID)
		end
	end
end

local function addItemSpecificCostumes(player)
	local playerType = player:GetPlayerType()
	local playerEffects = player:GetEffects()
	local holyMantleCostume = Isaac.GetItemConfig():GetCollectible(CollectibleType.COLLECTIBLE_HOLY_MANTLE)

	--Empty Vessel
	if playerEffects:HasCollectibleEffect(CollectibleType.COLLECTIBLE_EMPTY_VESSEL)
	and playerItemCostumeWhitelist[playerType][CollectibleType.COLLECTIBLE_EMPTY_VESSEL] == true then
		player:AddNullCostume(NullItemID.ID_EMPTY_VESSEL)
	end

	if REPENTANCE then
		--Holy Card
		if REPENTANCE and playerEffects:HasNullEffect(NullItemID.ID_HOLY_CARD) then
			player:AddCostume(holyMantleCostume, false)
		end

		if player:GetCollectibleNum(CollectibleType.COLLECTIBLE_BRIMSTONE) >= 2 then
			ccp:AddNullCostume(NullItemID.ID_BRIMSTONE2)
		end

		local ID_DOUBLE_GUPPYS_EYE = 125
		local ID_DOUBLE_GLASS_EYE = 126

		--Double Guppy's Eye
		if player:GetCollectibleNum(CollectibleType.COLLECTIBLE_GUPPYS_EYE) >= 2 then
			if playerItemCostumeWhitelist[CollectibleType.COLLECTIBLE_GUPPYS_EYE] == true then
				player:AddNullCostume(ID_DOUBLE_GUPPYS_EYE)
			end
		end

		--Double Glass Eye
		if player:GetCollectibleNum(CollectibleType.COLLECTIBLE_GLASS_EYE) >= 2 then
			if playerItemCostumeWhitelist[CollectibleType.COLLECTIBLE_GLASS_EYE] == true then
				player:AddRemoveNullCostume(ID_DOUBLE_GLASS_EYE)
			end
		end
	end
end

local function updatePlayerSpritesheet(player)
	local playerType = player:GetPlayerType()
	local sprite = player:GetSprite()
	local spritesheetPath = playerSpritesheet[playerType]["Normal"]

	if player.CanFly and playerSpritesheet[playerType]["Flight"] ~= nil then
		spritesheetPath = playerSpritesheet[playerType]["Flight"]
	end

	sprite:ReplaceSpritesheet(12, spritesheetPath)
	sprite:ReplaceSpritesheet(4, spritesheetPath)
	sprite:ReplaceSpritesheet(2, spritesheetPath)
	sprite:ReplaceSpritesheet(1, spritesheetPath)
	sprite:LoadGraphics()
end

local function tryAddFlightCostume(player)
	local playerType = player:GetPlayerType()
	local data = player:GetData()

	if player.CanFly == true
	and playerCostume[playerType]["Flight"] ~= nil then
		local costumeFlight = playerCostume[playerType]["Flight"]
		player:AddNullCostume(costumeFlight)
	end
end

local function returnOnHemoptysis(player)
	local effects = player:GetEffects()
	local playerType = player:GetPlayerType()
	local hemo = CollectibleType.COLLECTIBLE_HEMOPTYSIS
	local shouldStopReset = false

	if effects:HasCollectibleEffect(hemo)
	and playerItemCostumeWhitelist[playerType]
	and playerItemCostumeWhitelist[playerType][hemo] ~= nil then
		shouldStopReset = true
	end
	return shouldStopReset
end

local function removeOldCostume(playerType)
	local basePath = playerCostume[playerType]
	player:TryRemoveNullCostume(basePath[1])
	if basePath[2] ~= nil then
		player:TryRemoveNullCostume(basePath[2])
	end
end

----------------------
--  MAIN FUNCTIONS  --
----------------------

function ccp:addCustomNullCostume(player, nullID)
	if nullID ~= -1 then
		player:AddNullCostume(nullID)
	else
		error("Custom Costume Protector Error: attempt to add costume returns nil")
	end
end

function ccp:canAddCollectibleCostume(player, itemID)
	local canAdd = false

	if (player:HasCollectible(itemID) or player:GetEffects():HasCollectibleEffect(itemID))
	and not collectiblesEffectsOnlyAddOnEffect[itemID]
	then
		return true
	end

	return canAdd
end

function ccp:mainResetPlayerCostumes(player)
	local playerType = player:GetPlayerType()

	if (REPENTANCE and playerToProtect[playerType] == true and not player:IsCoopGhost()) or (not REPENTANCE and playerToProtect[playerType] == true) then

		player:ClearCostumes()
		updatePlayerSpritesheet(player)

		if playerCostume[playerType]["Flight"] ~= nil then
			tryAddFlightCostume(player)
		end

		if playerCostume[playerType]["Extra"] ~= nil then
			local costumeExtra = playerCostume[playerType]["Extra"]
			ccp:addCustomNullCostume(player, costumeExtra)
		end

		addAllWhitelistedCostumes(player)
		addItemSpecificCostumes(player)
		ccp:afterCostumeReset(player)
	end
end

function ccp:addAllCostumes(player)
	local data = player:GetData()
	local playerEffects = player:GetEffects()


	for playerType, _ in pairs(data.CCP.HasCostumeInitialized) do

		removeOldCostume(playerType)

		--Item Costumes
		for itemID = 1, CollectibleType.NUM_COLLECTIBLES do
			local itemCostume = Isaac.GetItemConfig():GetCollectible(itemID)
			if ccp:canAddCollectibleCostume(player, itemID)
			and not playerItemCostumeWhitelist[playerType][itemID] then
				player:AddCostume(itemCostume, false)
			end
		end

		--Item Costumes Only On Effect
		for itemID, boolean in pairs(collectiblesEffectsOnlyAddOnEffect) do
			if playerEffects:HasCollectibleEffect(itemID)
			and not playerItemCostumeWhitelist[playerType][itemID] then
				player:AddCostume(itemCostume)
			end
		end

		--Null Costumes
		for nullItemID = 1, NullItemID.NUM_NULLITEMS do
			if playerEffects:HasNullEffect(nullItemID)
			and not nullEffectsBlacklist[nullItemID]
			and not playerNullItemCostumeWhitelist[playerType][itemID]then
				player:AddNullCostume(nullItemID)
			end
		end

		--Trinkets
		for trinketID, _ in pairs(costumeTrinkets) do
			if ((trinketID == TrinketType.TRINKET_TICK
			and player:HasTrinket(trinketID))
			or playerEffects:HasTrinketEffect(trinketID))
			and data.CCP.TrinketActive[trinketID]
			and not playerTrinketCostumeWhitelist[playerType][trinketID] then
				local trinketCostume = Isaac.GetItemConfig():GetTrinket(trinketID)
				player:AddCostume(trinketCostume)
			end
		end

		--Transformations
		for playerForm, nullItemID in pairs(playerFormToNullItemID) do
			if player:HasPlayerForm(playerForm) then
				player:AddNullCostume(nullItemID)
			end
		end
	end
end

function ccp:deinitPlayerCostume(player)
	local data = player:GetData()
	local playerType = player:GetPlayerType()

	if data.CCP
	and data.CCP.HasCostumeInitialized --Has the protection data
	and not data.CCP.HasCostumeInitialized[playerType] --For other characters given protection in their own copy of the library
	and not playerToProtect[playerType] then --PlayerType isn't in local protection system
		ccp:addAllCostumes(player)
		data.CCP = nil
		ccp:afterCostumeDeinit(player)
	end
end

function ccp:removeOldCCPData(player)
	local playerType = player:GetPlayerType()
	local data = player:GetData()

	for dataPlayerType, _ in pairs(data.CCP.HasCostumeInitialized) do
		if dataPlayerType ~= playerType then
			removeOldCostume(dataPlayerType)
			data.CCP.HasCostumeInitialized[dataPlayerType] = nil
		end
	end
end

function ccp:miscCostumeResets(player)
	local playerType = player:GetPlayerType()
	local playerEffects = player:GetEffects()
	local data = player:GetData()

	if data.CCP.NumCollectibles
	and data.CCP.NumCollectibles ~= player:GetCollectibleCount()
	then
		data.CCP.NumCollectibles = player:GetCollectibleCount()
		ccp:mainResetPlayerCostumes(player)
	end

	if data.CCP.NumTemporaryEffects
	and data.CCP.NumTemporaryEffects ~= player:GetEffects():GetEffectsList().Size
	and returnOnHemoptysis(player)
	then
		data.CCP.NumTemporaryEffects = player:GetEffects():GetEffectsList().Size
		ccp:mainResetPlayerCostumes(player)
	end

	for trinketID, _ in pairs(costumeTrinkets) do
		if ((trinketID == TrinketType.TRINKET_TICK
		and player:HasTrinket(trinketID))
		or playerEffects:HasTrinketEffect(trinketID))
		then
			if not data.CCP.TrinketActive[trinketID] then
				if not playerTrinketCostumeWhitelist[playerType][trinketID] then
					local trinketCostume = Isaac.GetItemConfig():GetTrinket(trinketID)
					player:RemoveCostume(trinketCostume)
				end
				data.CCP.TrinketActive[trinketID] = true
			end
		elseif (trinketID == TrinketType.TRINKET_TICK
		and not player:HasTrinket(trinketID))
		or not playerEffects:HasTrinketEffect(trinketID)
		then
			if data.CCP.TrinketActive[trinketID] then
				data.CCP.TrinketActive[trinketID] = false
			end
		end
	end

	if player.CanFly and not data.CCP.CustomFlightCostume then
		ccp:mainResetPlayerCostumes(player)
		data.CCP.CustomFlightCostume = true
	elseif not player.CanFly and data.CCP.CustomFlightCostume then
		ccp:mainResetPlayerCostumes(player)
		data.CCP.CustomFlightCostume = false
	end
end

----------------------------------------------
--  RESETTING COSTUME ON SPECIFIC TRIGGERS  --
----------------------------------------------

--Code provided by piber20
local function ABPlusUseItemPlayer()
	local player
	for i = 0, Game():GetNumPlayers() - 1 do

		local thisPlayer = Isaac.GetPlayer(i)

		--check the player's input
		if Input.IsActionTriggered(ButtonAction.ACTION_ITEM, thisPlayer.ControllerIndex) or Input.IsActionTriggered(ButtonAction.ACTION_PILLCARD, thisPlayer.ControllerIndex) and thisPlayer:GetActiveItem() == itemID then

			player = thisPlayer
			break

		end

	end

	if player then return player end
end

function ccp:resetCostumeOnItem(
  itemID, rng, player, useFlags, activeSlot, customVarData
)
	local player = player or ABPlusUseItemPlayer()
	if player then
		local playerType = player:GetPlayerType()
		local data = player:GetData()
		local playerHasUsedItem = activesToDelayCostumeReset[itemID] == true

		if playerToProtect[playerType] and data.CCP then
			if data.CCP.HasCostumeInitialized and playerHasUsedItem then
				if playerItemCostumeWhitelist[playerType] and not playerItemCostumeWhitelist[playerType][itemID] then
					data.CCP.DelayCostumeReset = true
				end
			end
		end
	end
	return false
end

function ccp:resetOnCoopRevive(player)
	local data = player:GetData()
	if player:IsCoopGhost() and not data.CCP.WaitOnCoopRevive then
		data.CCP.WaitOnCoopRevive = true
	elseif not player:IsCoopGhost() and data.CCP.WaitOnCoopRevive then
		ccp:ReAddBaseCosutme(player)
		data.CCP.WaitOnCoopRevive = false
	end
end

function ccp:stopNewRoomCostumes(player)
	local playerType = player:GetPlayerType()
	local data = player:GetData()

	if player:HasCollectible(CollectibleType.COLLECTIBLE_TAURUS)
	and not playerItemCostumeWhitelist[playerType][CollectibleType.COLLECTIBLE_TAURUS] then
		table.insert(data.CCP.QueueCostumeRemove, CollectibleType.COLLECTIBLE_TAURUS)
		data.CCP.DelayTaurusCostumeReset = true
	end

	if player:HasCollectible(CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON)
	and not playerItemCostumeWhitelist[playerType][CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON] then
		if player:GetHearts() <= 1 then
			table.insert(data.CCP.QueueCostumeRemove, CollectibleType.COLLECTIBLE_WHORE_OF_BABYLON)
		end
	end

	if player:HasCollectible(CollectibleType.COLLECTIBLE_EMPTY_VESSEL)
	and not playerItemCostumeWhitelist[playerType][CollectibleType.COLLECTIBLE_EMPTY_VESSEL] then
		if player:GetHearts() == 0 then
			table.insert(data.CCP.QueueCostumeRemove, CollectibleType.COLLECTIBLE_EMPTY_VESSEL)
		end
	end
end

function ccp:stopTaurusCostumeOnInvincibility(player)
	local effects = player:GetEffects()
	local data = player:GetData()

	if player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_TAURUS)
	and player.MoveSpeed >= 2.0
	and data.CCP.DelayTaurusCostumeReset then
		table.insert(data.CCP.QueueCostumeRemove, CollectibleType.COLLECTIBLE_TAURUS)
		data.CCP.DelayTaurusCostumeReset = false
	end
end

function ccp:resetOnMissingNoNewFloor(player)
	if player:HasCollectible(CollectibleType.COLLECTIBLE_MISSING_NO) then
		ccp:mainResetPlayerCostumes(player)
	end
end

function ccp:modelingClay(player)
	local playerType = player:GetPlayerType()
	local data = player:GetData()
	local itemID = player:GetModelingClayEffect()

	if player:HasTrinket(TrinketType.TRINKET_MODELING_CLAY)
	and itemID ~= 0
	and playerItemCostumeWhitelist[playerType][itemID] == nil
	then
		table.insert(data.CCP.QueueCostumeRemove, itemID)
	end
end

local roomIsClear = true

function ccp:astralProjectionOnClear(player)
	local playerType = player:GetPlayerType()
	local data = player:GetData()
	local room = game:GetRoom()

	if player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_ASTRAL_PROJECTION) then
		if roomIsClear == false and room:IsClear() == true and not data.CCP.AstralProjectionDisabled then
			data.CCP.DelayCostumeReset = true
			data.CCP.AstralProjectionDisabled = true
		end
	else
		if data.CCP.AstralProjectionDisabled then
			data.CCP.AstralProjectionDisabled = nil
		end
	end
	roomIsClear = room:IsClear()
end

function ccp:astralProjectionOnHit(ent, amount, flags, source, countdown)
	local player = ent:ToPlayer()
	local playerType = player:GetPlayerType()
	local data = player:GetData()

	if playerToProtect[playerType] == true and data.CCP then
		if player:GetEffects():HasCollectibleEffect(CollectibleType.COLLECTIBLE_ASTRAL_PROJECTION) then
			data.CCP.DelayCostumeReset = true
			data.CCP.AstralProjectionDisabled = true
		end
	end
end

function ccp:delayInCostumeReset(player)
	local data = player:GetData()

	if data.CCP.DelayCostumeReset and data.CCP.DelayCostumeReset then
		ccp:mainResetPlayerCostumes(player)
		data.CCP.DelayCostumeReset = nil
	end

	if data.CCP.QueueCostumeRemove and data.CCP.QueueCostumeRemove[1] ~= nil then
		while #data.CCP.QueueCostumeRemove > 0 do
			local itemCostume = Isaac.GetItemConfig():GetCollectible(data.CCP.QueueCostumeRemove[1])
			player:RemoveCostume(itemCostume)
			table.remove(data.CCP.QueueCostumeRemove, 1)
		end
	end
end

----------------------------
--  INITIATING CALLBACKS  --
----------------------------

function ccp:init(mod)
	mod:AddCallback(ModCallbacks.MC_POST_PEFFECT_UPDATE, function(_, player)
		local playerType = player:GetPlayerType()
		local data = player:GetData()

		ccp:deinitPlayerCostume(player)

		if playerToProtect[playerType] == true and data.CCP then
			ccp:removeOldCCPData(player)
			ccp:miscCostumeResets(player)
			ccp:delayInCostumeReset(player)
			ccp:stopTaurusCostumeOnInvincibility(player)
			if REPENTANCE then
				ccp:astralProjectionOnClear(player)
			end
		end
	end)

	mod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, function()
		for i = 0, game:GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(i)
			local playerType = player:GetPlayerType()
			local data = player:GetData()

			if playerToProtect[playerType] == true and data.CCP then
				ccp:stopNewRoomCostumes(player)
				if REPENTANCE then
					ccp:modelingClay(player)
				end
			end
		end
	end)

	mod:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, function()
		for i = 0, game:GetNumPlayers() - 1 do
			local player = Isaac.GetPlayer(i)
			local playerType = player:GetPlayerType()
			local data = player:GetData()

			if playerToProtect[playerType] == true and data.CCP then
				ccp:resetOnMissingNoNewFloor(player)
			end
		end
	end)

	mod:AddCallback(ModCallbacks.MC_USE_ITEM, ccp.resetCostumeOnItem)

	if REPENTANCE then
		mod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, ccp.astralProjectionOnHit, EntityType.ENTITY_PLAYER)
	end
end

return {
	Init = ccp.init,
	AddPlayer = ccp.addPlayer,
	UpdatePlayer = ccp.updatePlayer,
	ItemCostumeWhitelist = ccp.itemCostumeWhitelist,
	NullEffectWhitelist = ccp.nullEffectWhitelist,
	TrinketCostumeWhitelist = ccp.trinketCostumeWhitelist,
	AddCallback = ccp.addCallback
}