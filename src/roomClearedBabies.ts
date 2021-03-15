import { ZERO_VECTOR } from "./constants";
import g from "./globals";
import * as misc from "./misc";

const functionMap = new Map<int, () => void>();
export default functionMap;

// Love Baby
functionMap.set(1, () => {
  // Local variables
  const roomSeed = g.r.GetSpawnSeed();

  // Random Heart
  g.g.Spawn(
    EntityType.ENTITY_PICKUP,
    PickupVariant.PICKUP_HEART,
    g.p.Position,
    ZERO_VECTOR,
    g.p,
    0,
    roomSeed,
  );
});

// Bandaid Baby
functionMap.set(88, () => {
  // Local variables
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
    ZERO_VECTOR,
    g.p,
    0,
    roomSeed,
  );
});

// Jammies Baby
functionMap.set(192, () => {
  // Extra charge per room cleared
  misc.addCharge();
  if (g.racingPlusEnabled) {
    // This is a no-op if the player does not have the Schoolbag or if the Schoolbag is empty
    RacingPlusSchoolbag.AddCharge(true);
  }
});

// Fishman Baby
functionMap.set(384, () => {
  // Local variables
  const roomSeed = g.r.GetSpawnSeed();

  // Random Bomb
  g.g.Spawn(
    EntityType.ENTITY_PICKUP,
    PickupVariant.PICKUP_BOMB,
    g.p.Position,
    ZERO_VECTOR,
    g.p,
    0,
    roomSeed,
  );
});
