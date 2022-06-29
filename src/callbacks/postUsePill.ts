import { ModCallback, PillEffect } from "isaac-typescript-definitions";
import { getCurrentBaby } from "../utils";
import { usePillBabyFunctionMap } from "./usePillBabyFunctionMap";

export function init(mod: Mod): void {
  mod.AddCallback(ModCallback.POST_USE_PILL, main);
}

function main(_pillEffect: PillEffect, player: EntityPlayer) {
  const [babyType, , valid] = getCurrentBaby();
  if (!valid) {
    return;
  }

  const usePillBabyFunction = usePillBabyFunctionMap.get(babyType);
  if (usePillBabyFunction !== undefined) {
    usePillBabyFunction(player);
  }
}