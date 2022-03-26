import {
  addRoomClearCharge,
  BOMB_EXPLODE_FRAME,
  directionToVector,
  getRandom,
  useActiveItemTemp,
} from "isaacscript-common";
import g from "../globals";
import { getRandomOffsetPosition } from "../utils";

const SHOCKWAVE_BOMB_VELOCITY_MULTIPLIER = 30;

const SHOCKWAVE_BOMB_VELOCITIES: readonly Vector[] = [
  directionToVector(Direction.LEFT).mul(SHOCKWAVE_BOMB_VELOCITY_MULTIPLIER), // 0
  directionToVector(Direction.UP).mul(SHOCKWAVE_BOMB_VELOCITY_MULTIPLIER), // 1
  directionToVector(Direction.RIGHT).mul(SHOCKWAVE_BOMB_VELOCITY_MULTIPLIER), // 2
  directionToVector(Direction.DOWN).mul(SHOCKWAVE_BOMB_VELOCITY_MULTIPLIER), // 3
];

export const postBombUpdateBabyFunctionMap = new Map<
  int,
  (bomb: EntityBomb) => void
>();

// Bomb Baby
postBombUpdateBabyFunctionMap.set(75, (bomb: EntityBomb) => {
  // 50% chance for bombs to have the D6 effect
  if (
    bomb.SpawnerType === EntityType.ENTITY_PLAYER &&
    bomb.FrameCount === BOMB_EXPLODE_FRAME
  ) {
    const d6chance = getRandom(g.run.room.rng);
    if (d6chance <= 0.5) {
      useActiveItemTemp(g.p, CollectibleType.COLLECTIBLE_D6);
    }
  }
});

// Tongue Baby
postBombUpdateBabyFunctionMap.set(97, (bomb: EntityBomb) => {
  // Recharge bombs
  if (
    bomb.SpawnerType === EntityType.ENTITY_PLAYER &&
    bomb.FrameCount === BOMB_EXPLODE_FRAME
  ) {
    addRoomClearCharge(g.p, true);
  }
});

// Skull Baby
postBombUpdateBabyFunctionMap.set(211, (bomb: EntityBomb) => {
  const gameFrameCount = g.g.GetFrameCount();

  if (
    bomb.SpawnerType !== EntityType.ENTITY_PLAYER ||
    bomb.FrameCount !== BOMB_EXPLODE_FRAME
  ) {
    return;
  }

  // Shockwave bombs
  for (const velocity of SHOCKWAVE_BOMB_VELOCITIES) {
    g.run.room.tears.push({
      frame: gameFrameCount,
      position: bomb.Position,
      velocity,
      num: 0,
    });
  }
});

// Bony Baby
postBombUpdateBabyFunctionMap.set(284, (bomb: EntityBomb) => {
  const data = bomb.GetData();

  if (
    bomb.FrameCount === 1 && // Frame 0 does not work
    data.doubled === undefined
  ) {
    const position = getRandomOffsetPosition(bomb.Position, 15, bomb.InitSeed);
    const doubledBomb = g.g
      .Spawn(
        bomb.Type,
        bomb.Variant,
        position,
        bomb.Velocity,
        bomb.SpawnerEntity,
        bomb.SubType,
        bomb.InitSeed,
      )
      .ToBomb();
    if (doubledBomb !== undefined) {
      doubledBomb.Flags = bomb.Flags;
      doubledBomb.IsFetus = bomb.IsFetus;
      if (bomb.IsFetus) {
        // There is a bug where Dr. Fetus bombs that are doubled have twice as long of a cooldown
        doubledBomb.SetExplosionCountdown(28);
      }
      doubledBomb.ExplosionDamage = bomb.ExplosionDamage;
      doubledBomb.RadiusMultiplier = bomb.RadiusMultiplier;
      doubledBomb.GetData().doubled = true;
    }
  }
});

// Barbarian Baby
postBombUpdateBabyFunctionMap.set(344, (bomb: EntityBomb) => {
  if (
    bomb.SpawnerType === EntityType.ENTITY_PLAYER &&
    bomb.FrameCount === BOMB_EXPLODE_FRAME
  ) {
    g.r.MamaMegaExplossion();
  }
});

// Orange Ghost Baby
postBombUpdateBabyFunctionMap.set(373, (bomb: EntityBomb) => {
  if (bomb.FrameCount === 1 && bomb.Variant !== BombVariant.BOMB_SUPERTROLL) {
    g.g.Spawn(
      bomb.Type,
      BombVariant.BOMB_SUPERTROLL,
      bomb.Position,
      bomb.Velocity,
      bomb.SpawnerEntity,
      bomb.SubType,
      bomb.InitSeed,
    );
    bomb.Remove();
  }
});
