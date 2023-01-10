import {
  EntityType,
  FamiliarVariant,
  ModCallback,
} from "isaac-typescript-definitions";
import { Callback, removeAllMatchingEntities } from "isaacscript-common";
import { g } from "../../../globals";
import { Baby } from "../../Baby";

/** Shoots Blue Flies + flight. */
export class RottenBaby extends Baby {
  /** Remove all of the Blue Flies. */
  override onRemove(): void {
    removeAllMatchingEntities(EntityType.FAMILIAR, FamiliarVariant.BLUE_FLY);
  }

  @Callback(ModCallback.POST_FIRE_TEAR)
  postFireTear(tear: EntityTear): void {
    tear.Remove();
    g.p.AddBlueFlies(1, g.p.Position, undefined);
  }
}