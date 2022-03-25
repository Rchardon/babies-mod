import { isCharacter } from "isaacscript-common";
import { PlayerTypeCustom } from "../types/PlayerTypeCustom";
import { getCurrentBaby } from "../utils";
import { evaluateCacheBabyFunctionMap } from "./evaluateCacheBabyFunctionMap";

export function init(mod: Mod): void {
  mod.AddCallback(ModCallbacks.MC_EVALUATE_CACHE, main);
}

function main(player: EntityPlayer, cacheFlag: CacheFlag) {
  const [babyType, baby, valid] = getCurrentBaby();
  if (!valid) {
    return;
  }

  // Give the Random Baby character a flat +1 damage as a bonus, similar to Samael
  if (
    cacheFlag === CacheFlag.CACHE_DAMAGE &&
    isCharacter(player, PlayerTypeCustom.PLAYER_RANDOM_BABY)
  ) {
    player.Damage += 1;
  }

  // Handle flying characters
  if (cacheFlag === CacheFlag.CACHE_FLYING && baby.flight === true) {
    player.CanFly = true;
  }

  const evaluateCacheBabyFunction = evaluateCacheBabyFunctionMap.get(babyType);
  if (evaluateCacheBabyFunction !== undefined) {
    evaluateCacheBabyFunction(player, cacheFlag);
  }
}
