import {
  GAME_FRAMES_PER_SECOND,
  assertDefined,
  game,
  getHUDOffsetVector,
  newSprite,
  onAnyChallenge,
} from "isaacscript-common";
import { isRacingPlusEnabled } from "./utils";

class TimerSprites {
  clock = newSprite("gfx/timer/clock.anm2");

  colons = {
    afterMinutes: newSprite("gfx/timer/colon.anm2"),
    afterHours: newSprite("gfx/timer/colon.anm2"),
  };

  digits = {
    minute1: newSprite("gfx/timer/timer.anm2"),
    minute2: newSprite("gfx/timer/timer.anm2"),
    second1: newSprite("gfx/timer/timer.anm2"),
    second2: newSprite("gfx/timer/timer.anm2"),
    hour: newSprite("gfx/timer/timer.anm2"),
  };

  digitMini = newSprite("gfx/timer/timer_mini.anm2");
}

const DIGIT_LENGTH = 7.25;

const sprites = new TimerSprites();

/** Should be called from the `POST_RENDER` callback. */
export function timerDraw(finishTime: int | null): void {
  const hud = game.GetHUD();
  if (!hud.IsVisible()) {
    return;
  }

  // We want the timer to be drawn when the game is paused so that players can continue to see the
  // countdown if they tab out of the game.

  if (finishTime === null) {
    return;
  }

  // Calculate the starting draw position. It will be either to the right of the speed stat or to
  // the right of the "R+" icon if we are using Racing+ and not in a custom challenge.
  let x = 55;
  if (isRacingPlusEnabled() && onAnyChallenge()) {
    // To the right of the "S5" sprite on the left side of the screen.
    x = 83;
  }
  let y = 79;

  const HUDOffsetVector = getHUDOffsetVector();
  x += HUDOffsetVector.X;
  y += HUDOffsetVector.Y;

  const hourAdjustment = 2;
  let hourAdjustment2 = 0;

  // Find out how much time has passed.
  const gameFrameCount = game.GetFrameCount();
  const remainingGameFrames = finishTime - gameFrameCount;
  const remainingSeconds = remainingGameFrames / GAME_FRAMES_PER_SECOND;

  const timerValues = convertSecondsToTimerValues(remainingSeconds);
  if (timerValues === undefined) {
    return;
  }

  const { hours, minute1, minute2, second1, second2, tenths } = timerValues;

  const positionClock = Vector(x + 34, y + 45);
  sprites.clock.Render(positionClock);

  if (hours > 0) {
    // The format of the time will be "#.##.##" (instead of "##.##", which is the default).
    hourAdjustment2 = 2;
    x += DIGIT_LENGTH + hourAdjustment;
    const positionHours = Vector(x - DIGIT_LENGTH - hourAdjustment, y);
    sprites.digits.hour.SetFrame("Default", hours);
    sprites.digits.hour.Render(positionHours);

    const positionColon = Vector(x - DIGIT_LENGTH + 7, y + 19);
    sprites.colons.afterHours.Render(positionColon);
  }

  const positionMinute1 = Vector(x, y);
  sprites.digits.minute1.SetFrame("Default", minute1);
  sprites.digits.minute1.Render(positionMinute1);

  const positionMinute2 = Vector(x + DIGIT_LENGTH, y);
  sprites.digits.minute2.SetFrame("Default", minute2);
  sprites.digits.minute2.Render(positionMinute2);

  const positionColon1 = Vector(x + DIGIT_LENGTH + 10, y + 19);
  sprites.colons.afterMinutes.Render(positionColon1);

  const positionSecond1 = Vector(x + DIGIT_LENGTH + 11, y);
  sprites.digits.second1.SetFrame("Default", second1);
  sprites.digits.second1.Render(positionSecond1);

  const positionSecond2 = Vector(
    x + DIGIT_LENGTH + 11 + DIGIT_LENGTH + 1 - hourAdjustment2,
    y,
  );
  sprites.digits.second2.SetFrame("Default", second2);
  sprites.digits.second2.Render(positionSecond2);

  const positionTenths = Vector(
    x + DIGIT_LENGTH + 11 + DIGIT_LENGTH + 1 - hourAdjustment2 + DIGIT_LENGTH,
    y + 1,
  );
  sprites.digitMini.SetFrame("Default", tenths);
  sprites.digitMini.Render(positionTenths);
}

function convertSecondsToTimerValues(totalSeconds: int):
  | {
      hours: int;
      minute1: int;
      minute2: int;
      second1: int;
      second2: int;
      tenths: int;
    }
  | undefined {
  if (totalSeconds < 0) {
    return undefined;
  }

  // Calculate the hours digit.
  const hours = Math.floor(totalSeconds / 3600);

  // Calculate the minutes digits.
  let minutes = Math.floor(totalSeconds / 60);
  if (hours > 0) {
    minutes -= hours * 60;
  }
  const minutesStringUnpadded = minutes.toString();
  const minutesString = minutesStringUnpadded.padStart(2, "0");

  // The first character.
  const minute1String = minutesString[0] ?? "0";
  const minute1 = tonumber(minute1String);
  assertDefined(minute1, "Failed to parse the first minute of the timer.");

  // The second character.
  const minute2String = minutesString[1] ?? "0";
  const minute2 = tonumber(minute2String);
  assertDefined(minute2, "Failed to parse the second minute of the timer.");

  // Calculate the seconds digits.
  const seconds = Math.floor(totalSeconds % 60);
  const secondsStringUnpadded = seconds.toString();
  const secondsString = secondsStringUnpadded.padStart(2, "0");

  // The first character.
  const second1String = secondsString[0] ?? "0";
  const second1 = tonumber(second1String);
  assertDefined(second1, "Failed to parse the first second of the timer.");

  // The second character.
  const second2String = secondsString[1] ?? "0";
  const second2 = tonumber(second2String);
  assertDefined(second2, "Failed to parse the second second of the timer.");

  // Calculate the tenths digit.
  const rawSeconds = totalSeconds % 60; // 0.000 to 59.999
  const decimals = rawSeconds - Math.floor(rawSeconds);
  const tenths = Math.floor(decimals * 10);

  return { hours, minute1, minute2, second1, second2, tenths };
}
