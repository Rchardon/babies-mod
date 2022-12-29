import {
  EntityType,
  GridEntityXMLType,
  ModCallback,
} from "isaac-typescript-definitions";
import { g } from "../globals";
import { mod } from "../mod";
import { getCurrentBaby } from "../utilsBaby";
import { preRoomEntitySpawnBabyFunctionMap } from "./preRoomEntitySpawnBabyFunctionMap";

export function init(): void {
  mod.AddCallback(ModCallback.PRE_ROOM_ENTITY_SPAWN, main);
}

function main(
  entityTypeOrGridEntityXMLType: EntityType | GridEntityXMLType,
  _variant: int,
  _subType: int,
  _gridIndex: int,
  _seed: int,
): [EntityType | GridEntityXMLType, int, int] | undefined {
  const roomFrameCount = g.r.GetFrameCount();
  const [babyType] = getCurrentBaby();
  if (babyType === -1) {
    return undefined;
  }

  // We only care about replacing things when the room is first loading and on the first visit.
  if (roomFrameCount !== -1) {
    return undefined;
  }

  const preRoomEntitySpawnBabyFunction =
    preRoomEntitySpawnBabyFunctionMap.get(babyType);
  if (preRoomEntitySpawnBabyFunction !== undefined) {
    return preRoomEntitySpawnBabyFunction(entityTypeOrGridEntityXMLType);
  }

  return undefined;
}
