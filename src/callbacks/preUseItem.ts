import g from "../globals";
import { getCurrentBaby } from "../util";

export function init(mod: Mod): void {
  mod.AddCallback(
    ModCallbacks.MC_PRE_USE_ITEM,
    poop,
    CollectibleType.COLLECTIBLE_POOP, // 36
  );

  mod.AddCallback(
    ModCallbacks.MC_PRE_USE_ITEM,
    lemonMishap,
    CollectibleType.COLLECTIBLE_LEMON_MISHAP, // 56
  );

  mod.AddCallback(
    ModCallbacks.MC_PRE_USE_ITEM,
    isaacsTears,
    CollectibleType.COLLECTIBLE_ISAACS_TEARS, // 323
  );

  mod.AddCallback(
    ModCallbacks.MC_PRE_USE_ITEM,
    smelter,
    CollectibleType.COLLECTIBLE_SMELTER, // 479
  );

  mod.AddCallback(
    ModCallbacks.MC_PRE_USE_ITEM,
    brownNugget,
    CollectibleType.COLLECTIBLE_BROWN_NUGGET, // 504
  );
}

// CollectibleType.COLLECTIBLE_POOP (36)
function poop(_collectibleType: number, _rng: RNG) {
  const [, baby, valid] = getCurrentBaby();
  if (!valid) {
    return false;
  }

  if (
    baby.name !== "Panda Baby" // 262
  ) {
    return false;
  }

  // Spawn White Poop next to the player
  Isaac.GridSpawn(
    GridEntityType.GRID_POOP,
    PoopGridEntityVariant.WHITE,
    g.p.Position,
    false,
  );

  g.sfx.Play(SoundEffect.SOUND_FART);

  return true; // Cancel the original effect
}

// CollectibleType.COLLECTIBLE_LEMON_MISHAP (56)
function lemonMishap(_collectibleType: number, _rng: RNG) {
  const [, baby, valid] = getCurrentBaby();
  if (!valid) {
    return false;
  }

  if (
    baby.name !== "Lemon Baby" // 232
  ) {
    return false;
  }

  g.p.UsePill(PillEffect.PILLEFFECT_LEMON_PARTY, PillColor.PILL_NULL);
  g.p.AnimateCollectible(
    CollectibleType.COLLECTIBLE_LEMON_MISHAP,
    PlayerItemAnimation.USE_ITEM,
    CollectibleAnimation.PLAYER_PICKUP,
  );
  return true; // Cancel the original effect
}

// CollectibleType.COLLECTIBLE_ISAACS_TEARS (323)
function isaacsTears(_collectibleType: number, _rng: RNG) {
  const [, baby, valid] = getCurrentBaby();
  if (!valid) {
    return false;
  }

  if (
    baby.name !== "Water Baby" // 3
  ) {
    return false;
  }

  let velocity = Vector(10, 0);
  for (let i = 0; i < 8; i++) {
    velocity = velocity.Rotated(45);
    const tear = g.p.FireTear(g.p.Position, velocity, false, false, false);

    // Increase the damage and make it look more impressive
    tear.CollisionDamage = g.p.Damage * 2;
    tear.Scale = 2;
    tear.KnockbackMultiplier = 20;
  }

  // When we return from the function below, no animation will play,
  // so we have to explicitly perform one
  g.p.AnimateCollectible(
    CollectibleType.COLLECTIBLE_ISAACS_TEARS,
    PlayerItemAnimation.USE_ITEM,
    CollectibleAnimation.PLAYER_PICKUP,
  );

  // Cancel the original effect
  return true;
}

// CollectibleType.COLLECTIBLE_SMELTER (479)
// This callback is used naturally by Gulp! pills
function smelter(_collectibleType: number, _rng: RNG) {
  const [, baby, valid] = getCurrentBaby();
  if (!valid) {
    return false;
  }

  if (baby.trinket === undefined) {
    return false;
  }

  // We want to keep track if the player smelts the trinket so that we don't give another copy back
  // to them
  const trinket1 = g.p.GetTrinket(0); // This will be 0 if there is no trinket
  const trinket2 = g.p.GetTrinket(1); // This will be 0 if there is no trinket
  if (trinket1 === baby.trinket || trinket2 === baby.trinket) {
    g.run.level.trinketGone = true;
  }

  // Go on to do the Smelter effect
  return false;
}

// CollectibleType.COLLECTIBLE_BROWN_NUGGET (504)
function brownNugget(_collectibleType: number, _rng: RNG) {
  const gameFrameCount = g.g.GetFrameCount();
  const [, baby, valid] = getCurrentBaby();
  if (!valid) {
    return false;
  }

  if (
    baby.name !== "Pizza Baby" // 303
  ) {
    return false;
  }
  if (baby.delay === undefined) {
    error(`The "delay" attribute was not defined for ${baby.name}.`);
  }

  // Mark to spawn more of them on subsequent frames
  if (g.run.babyCounters === 0) {
    g.run.babyCounters = 1;
    g.run.babyFrame = gameFrameCount + baby.delay;
  }

  return false;
}
