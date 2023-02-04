#!/bin/bash

set -e # Exit on any errors

# Get the directory of this script:
# https://stackoverflow.com/questions/59895/getting-the-source-directory-of-a-bash-script-from-within
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

SECONDS=0

cd "$DIR"

# Use Prettier to check formatting.
# "--loglevel warn" makes it only output errors.
npx prettier --loglevel warn --check .

# Use ESLint to lint the TypeScript.
# "--max-warnings 0" makes warnings fail in CI, since we set all ESLint errors to warnings.
npx eslint --max-warnings 0 .

# Check for unused imports.
# "--error" makes it return an error code of 1 if unused exports are found.
# @template-ignore-next-line
npx ts-prune --error --ignore "characterCostumeProtector.d.ts" # We ignore library definition files.

# Use `isaac-xml-validator` to validate XML files.
# (Skip this step if Python is not currently installed for whatever reason.)
if command -v python &> /dev/null; then
  pip install isaac-xml-validator --upgrade --quiet
  isaac-xml-validator --quiet
fi

# Step 5 - Spell check every file using CSpell.
# "--no-progress" and "--no-summary" make it only output errors.
npx cspell --no-progress --no-summary .

# Step 6 - Check for orphaned words.
bash "$DIR/check-orphaned-words.sh"

# Step 7 - Check for base file updates.
#bash "$DIR/check-file-updates.sh"
#npx isaacscript check # TODO

echo "Successfully linted in $SECONDS seconds."
