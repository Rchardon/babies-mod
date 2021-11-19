import { GlobalsRunBabyExplosion } from "./GlobalsRunBabyExplosion";
import { GlobalsRunBabyNPC } from "./GlobalsRunBabyNPC";
import { GlobalsRunBabyTears } from "./GlobalsRunBabyTears";
import { GlobalsRunLevel } from "./GlobalsRunLevel";
import { GlobalsRunRoom } from "./GlobalsRunRoom";

// Per-run variables
export class GlobalsRun {
  // Tracking per run
  // Set to true in the PostGameStarted callback if we are on the right character
  enabled = false;
  babyType: number | null = null;
  drawIntro = false;
  queuedItems = false;
  // Keep track of all of the pedestal items that we pick up over the course of the run
  passiveItems: int[] = [];
  animation = "";
  randomSeed: int;

  // Tracking per level
  // We start at stage 0 instead of stage 1 so that we can trigger the PostNewRoom callback after
  // the PostNewLevel callback
  level = new GlobalsRunLevel();

  // Tracking per room
  room = new GlobalsRunRoom();

  // Temporary variables
  reloadSprite = false;
  showIntroFrame = 0;
  showVersionFrame = 0;
  /** Used to make the player temporarily invulnerable. */
  invulnerable = false;
  /** Used to make the player temporarily invulnerable. */
  invulnerabilityUntilFrame: int | null = null;
  dealingExtraDamage = false;

  // Baby-specific variables
  babyBool = false;
  babyCounters = 0;
  babyCountersRoom = 0;
  babyFrame = 0;
  babyTears = new GlobalsRunBabyTears();
  babyNPC: GlobalsRunBabyNPC = {
    type: 0,
    variant: 0,
    subType: 0,
  };

  babyExplosions: GlobalsRunBabyExplosion[] = [];
  babySprite: Sprite | null = null;

  // Item-specific variables
  flockOfSuccubi = false;

  constructor(randomSeed = Random()) {
    this.randomSeed = randomSeed;
  }
}
