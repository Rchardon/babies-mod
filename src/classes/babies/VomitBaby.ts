import { DamageFlagZero } from "isaac-typescript-definitions";
import { CallbackCustom, game, ModCallbackCustom } from "isaacscript-common";
import { g } from "../../globals";
import { Baby } from "../Baby";

const v = {
  run: {
    timer: 0,
  },
};

/** Takes damage if moving when the timer reaches 0. */
export class VomitBaby extends Baby {
  v = v;

  override onAdd(): void {
    this.resetTimer();
  }

  @CallbackCustom(ModCallbackCustom.POST_PEFFECT_UPDATE_REORDERED)
  postPEffectUpdateReordered(player: EntityPlayer): void {
    const gameFrameCount = game.GetFrameCount();

    const remainingGameFrames = g.run.babyCounters - gameFrameCount;
    if (remainingGameFrames <= 0) {
      this.resetTimer();

      const cutoff = 0.2;
      if (
        player.Velocity.X > cutoff ||
        player.Velocity.X < cutoff * -1 ||
        player.Velocity.Y > cutoff ||
        player.Velocity.Y < cutoff * -1
      ) {
        player.TakeDamage(1, DamageFlagZero, EntityRef(player), 0);
      }
    }
  }

  resetTimer(): void {
    const gameFrameCount = game.GetFrameCount();
    const num = this.getAttribute("num");

    v.run.timer = gameFrameCount + num;
  }
}
