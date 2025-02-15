import { DamageFlagZero, ModCallback } from "isaac-typescript-definitions";
import { Callback, isMissedTear } from "isaacscript-common";
import {
  getBabyPlayerFromEntity,
  isValidForMissedTearsEffect,
} from "../../utils";
import { Baby } from "../Baby";

const v = {
  run: {
    numTearMisses: 0,
  },

  room: {
    tearPtrHashes: new Set<PtrHash>(),
  },
};

/** Every Nth missed tear causes damage. */
export class CursedPillowBaby extends Baby {
  v = v;

  override isValid(player: EntityPlayer): boolean {
    return isValidForMissedTearsEffect(player);
  }

  // 40
  @Callback(ModCallback.POST_TEAR_UPDATE)
  postTearUpdate(tear: EntityTear): void {
    const ptrHash = GetPtrHash(tear);
    if (!v.room.tearPtrHashes.has(ptrHash)) {
      return;
    }

    const player = getBabyPlayerFromEntity(tear);
    if (player === undefined) {
      return;
    }

    if (!isMissedTear(tear)) {
      return;
    }

    const num = this.getAttribute("num");

    v.run.numTearMisses++;
    if (v.run.numTearMisses === num) {
      v.run.numTearMisses = 0;
      player.TakeDamage(1, DamageFlagZero, EntityRef(player), 0);
    }
  }

  // 61
  @Callback(ModCallback.POST_FIRE_TEAR)
  postFireTear(tear: EntityTear): void {
    const ptrHash = GetPtrHash(tear);
    v.room.tearPtrHashes.add(ptrHash);
  }
}
