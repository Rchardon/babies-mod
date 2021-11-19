import { getRandomArrayIndex, log, nextSeed } from "isaacscript-common";
import { babyAdd } from "../babyAdd";
import { babyCheckValid } from "../babyCheckValid";
import { babyRemove } from "../babyRemove";
import g from "../globals";
import { GlobalsRunLevel } from "../types/GlobalsRunLevel";
import { getCurrentBaby } from "../util";

export function main(): void {
  const gameFrameCount = g.g.GetFrameCount();
  const stage = g.l.GetStage();
  const stageType = g.l.GetStageType();

  log(
    `MC_POST_NEW_LEVEL - ${stage}.${stageType} (game frame ${gameFrameCount})`,
  );

  // Racing+ has a feature to remove duplicate rooms,
  // so it may reseed the floor immediately upon reaching it
  // If so, we don't want to do anything, since this isn't really a new level
  if (gameFrameCount !== 0 && gameFrameCount === g.run.level.stageFrame) {
    return;
  }

  // Reset floor-related variables
  g.run.level = new GlobalsRunLevel(stage, stageType, gameFrameCount);

  // Reset baby-specific variables
  g.run.babyBool = false;
  g.run.babyCounters = 0;
  // babyCountersRoom are reset in the PostNewRoom callback
  g.run.babyFrame = 0;
  // babyTears are reset in the PostNewRoom callback
  g.run.babyNPC = {
    type: 0,
    variant: 0,
    subType: 0,
  };
  g.run.babySprite = null;

  // Display text describing the new baby
  g.run.showIntroFrame = gameFrameCount + 60; // 2 seconds

  // Set the new baby
  babyRemove();
  getNewBaby();
  babyAdd();
}

function getNewBaby() {
  // We want to use a seed corresponding to the current floor
  let seed = g.l.GetDungeonPlacementSeed();

  // Don't get a new baby if we did not start the run as the Random Baby character
  if (!g.run.enabled) {
    g.run.babyType = null;
    return;
  }

  // It will become impossible to find a new baby if the list of past babies grows too large
  // (when experimenting, it crashed upon reaching a size of 538,
  // so reset it when it gets over 500 just in case)
  if (g.pastBabies.length > 500) {
    g.pastBabies = [];
  }

  // Get a random co-op baby based on the seed of the floor
  // (but reroll the baby if they have any overlapping items)
  let babyType: int;
  let i = 0;
  do {
    i += 1;
    seed = nextSeed(seed);
    babyType = getRandomArrayIndex(g.babies, seed);

    // Don't randomly choose a co-op baby if we are choosing a specific one for debugging purposes
    if (g.debugBabyNum !== null) {
      babyType = g.debugBabyNum;
      break;
    }
  } while (!babyCheckValid(babyType));

  // Set the newly chosen baby type
  g.run.babyType = babyType;

  // Keep track of the babies that we choose so that we can avoid giving duplicates
  // on the same run / multi-character custom challenge
  g.pastBabies.push(babyType);

  const [, baby] = getCurrentBaby();
  log(`Randomly chose baby: ${babyType} - ${baby.name} - ${baby.description}`);
  log(`Tries: ${i}, total past babies: ${g.pastBabies.length}`);
}
