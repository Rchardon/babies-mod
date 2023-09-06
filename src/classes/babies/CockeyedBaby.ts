import { ModCallback } from "isaac-typescript-definitions";
import {
  Callback,
  getPlayerFromEntity,
  getRandomInt,
} from "isaacscript-common";
import { Baby } from "../Baby";

const v = {
  run: {
    shootingExtraTear: false,
  },
};

/** Shoots extra tears with random velocity. */
export class CockeyedBaby extends Baby {
  v = v;

  @Callback(ModCallback.POST_FIRE_TEAR)
  postFireTear(tear: EntityTear): void {
    if (v.run.shootingExtraTear) {
      return;
    }

    const player = getPlayerFromEntity(tear);
    if (player === undefined) {
      return;
    }

    // Spawn a new tear with a random velocity.
    const rng = tear.GetDropRNG();
    const rotation = getRandomInt(0, 359, rng);
    const velocity = tear.Velocity.Rotated(rotation);
    v.run.shootingExtraTear = true;
    player.FireTear(player.Position, velocity, false, true, false);
    v.run.shootingExtraTear = false;
  }
}
