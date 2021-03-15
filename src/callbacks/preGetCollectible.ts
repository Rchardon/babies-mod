// This callback is called when the game needs to get a new random item from an item pool
// It is undocumented, but you can return an integer from this callback in order to change the
// returned item pool type
// It is not called for "set" drops (like Mr. Boom from Wrath) and manually spawned items
// (like the Checkpoint)

import g from "../globals";
import * as misc from "../misc";
import preGetCollectibleBabyFunctions from "./preGetCollectibleBabies";

export function main(
  _itemPoolType: ItemPoolType,
  _decrease: boolean,
  _seed: int,
): number | null {
  // Local variables
  const [babyType, , valid] = misc.getCurrentBaby();
  if (!valid) {
    return null;
  }

  // Below, we will need to call the "itemPool.GetCollectible()" function,
  // which will cause this callback to be re-entered
  if (g.run.babyBool) {
    return null;
  }

  const babyFunc = preGetCollectibleBabyFunctions.get(babyType);
  if (babyFunc !== undefined) {
    return babyFunc();
  }

  return null;
}
