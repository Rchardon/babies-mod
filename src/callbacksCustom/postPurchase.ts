import { ModCallbacksCustom, ModUpgraded } from "isaacscript-common";
import { getCurrentBaby } from "../utils";
import { postPickupCollectBabyFunctionMap } from "./postPickupCollectBabyFunctionMap";

export function init(mod: ModUpgraded): void {
  mod.AddCallbackCustom(ModCallbacksCustom.MC_POST_PURCHASE, main);
}

function main() {
  const [babyType, , valid] = getCurrentBaby();
  if (!valid) {
    return;
  }

  // When a player purchases a pickup,
  // it should trigger the same callbacks as when a player collects a pickup from the ground
  const postPickupCollectBabyFunction =
    postPickupCollectBabyFunctionMap.get(babyType);
  if (postPickupCollectBabyFunction !== undefined) {
    postPickupCollectBabyFunction();
  }
}
