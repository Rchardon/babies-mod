import { getCurrentBaby } from "../utils";
import { postBombUpdateBabyFunctionMap } from "./postBombUpdateBabyFunctionMap";

export function init(mod: Mod): void {
  mod.AddCallback(ModCallbacks.MC_POST_BOMB_UPDATE, main);
}

function main(bomb: EntityBomb) {
  const [babyType, , valid] = getCurrentBaby();
  if (!valid) {
    return;
  }

  const postBombUpdateBabyFunction =
    postBombUpdateBabyFunctionMap.get(babyType);
  if (postBombUpdateBabyFunction !== undefined) {
    postBombUpdateBabyFunction(bomb);
  }
}
