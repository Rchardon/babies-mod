import { addRoomClearCharge } from "isaacscript-common";
import g from "./globals";

export const roomClearedBabyFunctionMap = new Map<int, () => void>();

// Love Baby
roomClearedBabyFunctionMap.set(1, () => {
  const roomSeed = g.r.GetSpawnSeed();
  math.randomseed(roomSeed);
  const heartSubType = math.random(1, 11); // From "Heart" to "Bone Heart"

  // Random Heart
  Isaac.Spawn(
    EntityType.ENTITY_PICKUP,
    PickupVariant.PICKUP_HEART,
    heartSubType,
    g.p.Position,
    Vector.Zero,
    g.p,
  );
});

// Bandaid Baby
roomClearedBabyFunctionMap.set(88, () => {
  const roomType = g.r.GetType();
  const roomSeed = g.r.GetSpawnSeed();

  if (roomType === RoomType.ROOM_BOSS) {
    return;
  }

  // Random collectible
  const position = g.r.FindFreePickupSpawnPosition(g.p.Position, 1, true);
  g.g.Spawn(
    EntityType.ENTITY_PICKUP,
    PickupVariant.PICKUP_COLLECTIBLE,
    position,
    Vector.Zero,
    g.p,
    0,
    roomSeed,
  );
});

// Jammies Baby
roomClearedBabyFunctionMap.set(192, () => {
  // Extra charge per room cleared
  addRoomClearCharge(g.p);
});

// Fishman Baby
roomClearedBabyFunctionMap.set(384, () => {
  const roomSeed = g.r.GetSpawnSeed();

  // Random Bomb
  g.g.Spawn(
    EntityType.ENTITY_PICKUP,
    PickupVariant.PICKUP_BOMB,
    g.p.Position,
    Vector.Zero,
    g.p,
    0,
    roomSeed,
  );
});