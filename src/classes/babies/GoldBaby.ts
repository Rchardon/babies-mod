import {
  GridEntityType,
  PoopGridEntityVariant,
} from "isaac-typescript-definitions";
import { CallbackCustom, ModCallbackCustom } from "isaacscript-common";
import { g } from "../../globals";
import { Baby } from "../Baby";

/** Gold gear + gold poops + gold rooms. */
export class GoldBaby extends Baby {
  override onAdd(player: EntityPlayer): void {
    player.AddGoldenBomb();
    player.AddGoldenKey();
    player.AddGoldenHearts(12);
  }

  @CallbackCustom(
    ModCallbackCustom.POST_GRID_ENTITY_UPDATE,
    GridEntityType.POOP,
  )
  postGridEntityUpdatePoop(gridEntity: GridEntity): void {
    const gridEntityPoop = gridEntity as GridEntityPoop;
    const gridEntityVariant = gridEntityPoop.GetVariant();

    if (gridEntityVariant !== PoopGridEntityVariant.GOLDEN) {
      gridEntity.SetVariant(PoopGridEntityVariant.GOLDEN);
    }
  }

  @CallbackCustom(ModCallbackCustom.POST_NEW_ROOM_REORDERED)
  postNewRoomReordered(): void {
    g.r.TurnGold();
  }
}
