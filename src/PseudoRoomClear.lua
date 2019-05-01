local PseudoRoomClear = {}

-- Includes
local g = require("src/globals")

function PseudoRoomClear:PostUpdate()
  -- Local variables
  local roomType = g.r:GetType()
  local roomFrameCount = g.r:GetFrameCount()
  local roomClear = g.r:IsClear()

  -- Don't have this ability work in certain room types
  if roomType == RoomType.ROOM_BOSS or -- 5
     roomType == RoomType.ROOM_CHALLENGE or -- 11
     roomType == RoomType.ROOM_DEVIL or -- 14
     roomType == RoomType.ROOM_ANGEL or -- 15
     roomType == RoomType.ROOM_DUNGEON or -- 16
     roomType == RoomType.ROOM_BOSSRUSH or -- 17
     roomType == RoomType.ROOM_BLACK_MARKET then -- 22

    return
  end

  -- We need to wait for the room to initialize before enabling the pseudo clear feature
  if roomFrameCount == 0 then
    return
  end

  -- Customize the doors and initiate the pseudo clear feature
  -- (this does not work in the MC_POST_NEW_ROOM callback or on frame 0)
  if roomFrameCount == 1 and
     not roomClear then

    PseudoRoomClear:InitializeDoors()
    return
  end

  PseudoRoomClear:CheckPseudoClear()
end

function PseudoRoomClear:InitializeDoors()
  -- Local variables
  local type = g.run.babyType
  local baby = g.babies[type]

  g.r:SetClear(true)
  g.run.roomPseudoClear = false
  for i = 0, 7 do
    local door = g.r:GetDoor(i)
    if door ~= nil and
       (door.TargetRoomType == RoomType.ROOM_DEFAULT or -- 0
        door.TargetRoomType == RoomType.ROOM_MINIBOSS or -- 6
        door.TargetRoomType == RoomType.ROOM_SACRIFICE) then -- 13

      -- Keep track of which doors we lock for later
      g.run.roomDoorsModified[#g.run.roomDoorsModified + 1] = i

      -- Modify the door
      if baby.name == "Black Baby" then -- 27
        door:SetRoomTypes(door.CurrentRoomType, RoomType.ROOM_CURSE) -- 10
        door:Open()
      elseif baby.name == "Nerd Baby" then -- 90
        door:SetLocked(true)
      elseif baby.name == "Mouse Baby" then -- 351
        door:SetRoomTypes(door.CurrentRoomType, RoomType.ROOM_SHOP) -- 2
        door:SetLocked(true)
      end
    end
  end
end

function PseudoRoomClear:CheckPseudoClear()
  -- Local variables
  local gameFrameCount = g.g:GetFrameCount()

  -- Don't do anything if the room is already cleared
  if g.run.roomPseudoClear then
    return
  end

  -- If a frame has passed since an enemy died, reset the delay counter
  if g.run.roomClearDelayFrame ~= 0 and
     gameFrameCount >= g.run.roomClearDelayFrame then

    g.run.roomClearDelayFrame = 0
  end

  -- Get the current number of non-dead NPCs
  local aliveEnemiesCount = 0
  for i, entity in pairs(Isaac.GetRoomEntities()) do
    local npc = entity:ToNPC()
    if npc ~= nil and
       npc.CanShutDoors and -- This is a battle NPC
       not npc:IsDead() and
       (npc.Type ~= EntityType.ENTITY_RAGLING or
        npc.Variant ~= 1 or -- 246.1
        npc.State ~= NpcState.STATE_UNIQUE_DEATH) and -- Rag Man Raglings don't actually die
       not PseudoRoomClear:AttachedNPC(npc) then

      aliveEnemiesCount = aliveEnemiesCount + 1
    end
  end

  if aliveEnemiesCount == 0 and
     g.run.roomClearDelayFrame == 0 and
     PseudoRoomClear:CheckAllPressurePlatesPushed() and
     gameFrameCount > 1 then -- To prevent misc. bugs

    PseudoRoomClear:ClearRoom()
  end
end

-- This code is copied from Racing+
function PseudoRoomClear:AttachedNPC(npc)
  -- These are NPCs that have "CanShutDoors" equal to true naturally by the game,
  -- but shouldn't actually keep the doors closed
  if (npc.Type == EntityType.ENTITY_CHARGER and npc.Variant == 0 and npc.Subtype == 1) or -- My Shadow (23.0.1)
     -- These are the black worms generated by My Shadow; they are similar to charmed enemies,
     -- but do not actually have the "charmed" flag set, so we don't want to add them to the "aliveEnemies" table
     (npc.Type == EntityType.ENTITY_VIS and npc.Variant == 22) or -- Cubber Projectile (39.22)
     -- (needed because Fistuloids spawn them on death)
     (npc.Type == EntityType.ENTITY_DEATH and npc.Variant == 10) or -- Death Scythe (66.10)
     (npc.Type == EntityType.ENTITY_PEEP and npc.Variant == 10) or -- Peep Eye (68.10)
     (npc.Type == EntityType.ENTITY_PEEP and npc.Variant == 11) or -- Bloat Eye (68.11)
     (npc.Type == EntityType.ENTITY_BEGOTTEN and npc.Variant == 10) or -- Begotten Chain (251.10)
     (npc.Type == EntityType.ENTITY_MAMA_GURDY and npc.Variant == 1) or -- Mama Gurdy Left Hand (266.1)
     (npc.Type == EntityType.ENTITY_MAMA_GURDY and npc.Variant == 2) or -- Mama Gurdy Right Hand (266.2)
     (npc.Type == EntityType.ENTITY_BIG_HORN and npc.Variant == 1) or -- Small Hole (411.1)
     (npc.Type == EntityType.ENTITY_BIG_HORN and npc.Variant == 2) then -- Big Hole (411.2)

    return true
  else
    return false
  end
end

function PseudoRoomClear:CheckAllPressurePlatesPushed()
  -- If we are in a puzzle room, check to see if all of the plates have been pressed
  if not g.r:HasTriggerPressurePlates() or
     g.run.roomButtonsPushed then

    return true
  end

  -- Check all the grid entities in the room
  local num = g.r:GetGridSize()
  for i = 1, num do
    local gridEntity = g.r:GetGridEntity(i)
    if gridEntity ~= nil then
      local saveState = gridEntity:GetSaveState();
      if saveState.Type == GridEntityType.GRID_PRESSURE_PLATE and -- 20
         saveState.State ~= 3 then

        return false
      end
    end
  end

  g.run.roomButtonsPushed = true
  return true
end

-- This roughly emulates what happens when you normally clear a room
function PseudoRoomClear:ClearRoom()
  -- Local variables
  local type = g.run.babyType
  local baby = g.babies[type]

  g.run.roomPseudoClear = true
  Isaac.DebugString("Room is now pseudo-cleared.")

  -- This takes into account their luck and so forth
  g.r:SpawnClearAward()

  -- Reset all of the doors that we previously modified
  for i = 1, #g.run.roomDoorsModified do
    local doorNum = g.run.roomDoorsModified[i]
    local door = g.r:GetDoor(doorNum)

    if baby.name == "Black Baby" then -- 27
      door:SetRoomTypes(door.CurrentRoomType, RoomType.ROOM_DEFAULT) -- 1
    elseif baby.name == "Nerd Baby" then -- 90
      door:TryUnlock(true) -- This has to be forced
    elseif baby.name == "Mouse Baby" then -- 351
      door:TryUnlock(true) -- This has to be forced
    end
  end

  -- Give a charge to the player's active item
  -- (and handle co-op players, if present)
  for i = 1, g.g:GetNumPlayers() do
    local player = Isaac.GetPlayer(i - 1)
    local activeItem = player:GetActiveItem()
    local activeCharge = player:GetActiveCharge()
    local batteryCharge = player:GetBatteryCharge()

    if player:NeedsCharge() == true then
      -- Find out if we are in a 2x2 or L room
      local chargesToAdd = 1
      local shape = g.r:GetRoomShape()
      if shape >= 8 then
        -- L rooms and 2x2 rooms should grant 2 charges
        chargesToAdd = 2
      elseif player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) and -- 3
             activeCharge == g:GetItemMaxCharges(activeItem) - 2 then

        -- The AAA Battery grants an extra charge when the active item is one away from being fully charged
        chargesToAdd = 2
      elseif player:HasTrinket(TrinketType.TRINKET_AAA_BATTERY) and -- 3
             activeCharge == g:GetItemMaxCharges(activeItem) and
             player:HasCollectible(CollectibleType.COLLECTIBLE_BATTERY) and -- 63
             batteryCharge == g:GetItemMaxCharges(activeItem) - 2 then

        -- The AAA Battery should grant an extra charge when the active item is one away from being fully charged
        -- with The Battery (this is bugged in vanilla for The Battery)
        chargesToAdd = 2
      end

      -- Add the correct amount of charges
      local currentCharge = player:GetActiveCharge()
      player:SetActiveCharge(currentCharge + chargesToAdd)
    end
  end

  -- Play the sound effect for the doors opening
  if g.r:GetType() ~= RoomType.ROOM_DUNGEON then -- 16
    g.s:Play(SoundEffect.SOUND_DOOR_HEAVY_OPEN, 1, 0, false, 1) -- 36
  end
end

return PseudoRoomClear
