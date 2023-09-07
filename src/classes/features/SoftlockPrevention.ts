import { GridEntityType } from "isaac-typescript-definitions";
import {
  CallbackCustom,
  game,
  GAME_FRAMES_PER_SECOND,
  getGridEntities,
  log,
  ModCallbackCustom,
  openAllDoors,
} from "isaacscript-common";
import type { BabyDescription } from "../../interfaces/BabyDescription";
import { isValidRandomBabyPlayer } from "../../utils";
import { getCurrentBaby } from "../../utilsBaby";
import { BabyModFeature } from "../BabyModFeature";

const v = {
  room: {
    destroyedGridEntities: false,
    openedDoors: false,
  },
};

export class SoftlockPrevention extends BabyModFeature {
  v = v;

  @CallbackCustom(ModCallbackCustom.POST_PEFFECT_UPDATE_REORDERED)
  postPEffectUpdateReordered(player: EntityPlayer): void {
    if (!isValidRandomBabyPlayer(player)) {
      return;
    }

    const currentBaby = getCurrentBaby();
    if (currentBaby === undefined) {
      return;
    }
    const { baby } = currentBaby;

    this.checkSoftlockDestroyPoopsTNT(baby);
    this.checkSoftlockIsland(baby);
  }

  /**
   * On certain babies, destroy all poops and TNT barrels after a certain amount of time to prevent
   * softlocks.
   */
  checkSoftlockDestroyPoopsTNT(baby: BabyDescription): void {
    const room = game.GetRoom();
    const roomFrameCount = room.GetFrameCount();

    if (baby.softlockPreventionDestroyPoops !== true) {
      return;
    }

    // Check to see if we already destroyed the grid entities in the room.
    if (v.room.destroyedGridEntities) {
      return;
    }

    // Check to see if they have been in the room long enough.
    const secondsThreshold = 15;
    if (roomFrameCount < secondsThreshold * GAME_FRAMES_PER_SECOND) {
      return;
    }

    v.room.destroyedGridEntities = true;

    // Kill some grid entities in the room to prevent softlocks in some specific rooms. (Fireplaces
    // will not cause softlocks since they are killable with The Candle.)
    const gridEntities = getGridEntities(
      GridEntityType.TNT, // 12
      GridEntityType.POOP, // 14
    );
    for (const gridEntity of gridEntities) {
      gridEntity.Destroy(true);
    }

    log("Destroyed all poops & TNT barrels to prevent a softlock.");
  }

  /**
   * On certain babies, open the doors after 30 seconds to prevent softlocks with Hosts and island
   * enemies.
   */
  checkSoftlockIsland(baby: BabyDescription): void {
    const room = game.GetRoom();
    const roomFrameCount = room.GetFrameCount();

    // Check to see if this baby needs the softlock prevention.
    if (baby.softlockPreventionIsland === undefined) {
      return;
    }

    // Check to see if we already opened the doors in the room.
    if (v.room.openedDoors) {
      return;
    }

    // Check to see if they have been in the room long enough.
    const secondsThreshold = 30;
    if (roomFrameCount < secondsThreshold * GAME_FRAMES_PER_SECOND) {
      return;
    }

    v.room.openedDoors = true;
    room.SetClear(true);
    openAllDoors();

    log("Opened all doors to prevent a softlock.");
  }
}