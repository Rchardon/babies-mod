import fs from "node:fs";
import path from "node:path";
import url from "node:url";

/** A simplified version of `BabyDescription`. */
interface BabyDescriptionSimple {
  id: number;
  name: string;
  description: string;
  sprite: string;
}

const NUM_BABY_DESCRIPTION_SIMPLE_FIELDS = 4;

const __dirname = url.fileURLToPath(new URL(".", import.meta.url));

const REPO_ROOT = path.join(__dirname, "..");
const BABIES_TS_PATH = path.join(REPO_ROOT, "src", "objects", "babies.ts");
const BABIES_MD_PATH = path.join(REPO_ROOT, "docs", "babies.md");

main();

function main() {
  const babyDescriptions = getBabyDescriptionsFromBabiesTS();
  const markdownText = getMarkdownText(babyDescriptions);
  fs.writeFileSync(BABIES_MD_PATH, markdownText);
}

/**
 * We can't import the "babies.ts" file directly because it uses `isaacscript-common` and the
 * corresponding JavaScript files are never created. Thus, we revert to reading the file as text and
 * constructing a simplified babies object from it.
 */
function getBabyDescriptionsFromBabiesTS(): BabyDescriptionSimple[] {
  const babiesTS = fs.readFileSync(BABIES_TS_PATH, "utf8");
  const lines = babiesTS.split("\n");

  const babyDescriptions: BabyDescriptionSimple[] = [];

  let currentBabyDescription: Partial<BabyDescriptionSimple> = {};
  let onBabiesObject = false;
  let descriptionOnNextLine = false;

  for (const [i, line] of lines.entries()) {
    if (!onBabiesObject) {
      if (line === "export const BABIES = {") {
        onBabiesObject = true;
      }
      continue;
    }

    if (descriptionOnNextLine) {
      descriptionOnNextLine = false;

      const match = line.match(/"(.+)",/);
      if (match === null) {
        throw new Error(
          `Failed to parse a description on line ${i + 1}: ${line}`,
        );
      }

      const description = match[1];
      if (description === undefined) {
        throw new Error(
          `Failed to parse a description on line ${i + 1}: ${line}`,
        );
      }

      currentBabyDescription.description = description;
    }

    if (line.startsWith("  // ") && !line.startsWith("  // ---")) {
      const match = line.match(/ {2}\/\/ (\d+)/);
      if (match === null) {
        throw new Error(`Failed to parse a comment on line ${i + 1}: ${line}`);
      }

      const idString = match[1];
      if (idString === undefined) {
        throw new Error(`Failed to parse a comment on line ${i + 1}: ${line}`);
      }

      const id = Number.parseInt(idString, 10);
      if (Number.isNaN(id)) {
        throw new TypeError(
          `Failed to convert a string to a number on line ${i + 1}: ${line}`,
        );
      }

      currentBabyDescription.id = id;
    }

    const trimmedLine = line.trim();

    if (trimmedLine.startsWith("name: ")) {
      const match = trimmedLine.match(/name: "(.+)"/);
      if (match === null) {
        throw new Error(`Failed to parse a name on line ${i + 1}: ${line}`);
      }

      const name = match[1];
      if (name === undefined) {
        throw new Error(`Failed to parse a name on line ${i + 1}: ${line}`);
      }

      currentBabyDescription.name = name;
    } else if (trimmedLine.startsWith("description: ")) {
      const match = trimmedLine.match(/description: "(.+)"/);
      if (match === null) {
        throw new Error(
          `Failed to parse a description on line ${i + 1}: ${line}`,
        );
      }

      const description = match[1];
      if (description === undefined) {
        throw new Error(
          `Failed to parse a description on line ${i + 1}: ${line}`,
        );
      }

      currentBabyDescription.description = description;
    } else if (trimmedLine.endsWith("description:")) {
      descriptionOnNextLine = true;
    } else if (trimmedLine.startsWith("sprite: ")) {
      const match = trimmedLine.match(/sprite: "(.+)"/);
      if (match === null) {
        throw new Error(`Failed to parse a sprite on line ${i + 1}: ${line}`);
      }

      const sprite = match[1];
      if (sprite === undefined) {
        throw new Error(`Failed to parse a sprite on line ${i + 1}: ${line}`);
      }

      currentBabyDescription.sprite = sprite;

      // `sprite` is the final field.
      const numKeys = Object.keys(currentBabyDescription).length;
      if (numKeys !== NUM_BABY_DESCRIPTION_SIMPLE_FIELDS) {
        console.error("currentBabyDescription:", currentBabyDescription);
        throw new Error(
          `Failed to collect ${NUM_BABY_DESCRIPTION_SIMPLE_FIELDS} fields from a baby description. (See above error output.)`,
        );
      }
      babyDescriptions.push(currentBabyDescription as BabyDescriptionSimple);
      currentBabyDescription = {};
    }
  }

  return babyDescriptions;
}

function getMarkdownText(babyDescriptions: BabyDescriptionSimple[]): string {
  let text = "# Baby List\n\n";
  text += "<!-- markdownlint-disable MD033 -->\n\n";
  text += `There are ${babyDescriptions.length} babies in total.\n\n`;
  text += "| ID | Appearance | Name | Description |\n";
  text += "| -- | ---------- | ---- | ----------- |\n";

  for (const babyDescription of babyDescriptions) {
    const { id, name, description, sprite } = babyDescription;

    // We copy paste all of the vanilla PNG files into the "images" directory and then crop/resize
    // them using ImageMagick. (See the comment in "cropImages.sh".)
    const spriteURL = `./images/${sprite}`;

    const image =
      sprite === "invisible_baby.png" ? "" : `![${sprite}](${spriteURL})`;

    text += `| ${id} | ${image} | ${name} | ${description} |\n`;
  }

  return text;
}
