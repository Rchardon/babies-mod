// This is the configuration file for ESLint, the TypeScript linter:
// https://eslint.org/docs/latest/use/configure/
module.exports = {
  extends: [
    // The linter base is the IsaacScript mod config:
    // https://github.com/IsaacScript/isaacscript/blob/main/packages/eslint-config-isaacscript/mod.js
    "eslint-config-isaacscript/mod",
  ],

  // The ".prettierrc.cjs" file is ignored by default, so we have to un-ignore it.
  ignorePatterns: ["!.prettierrc.cjs"],

  parserOptions: {
    // ESLint needs to know about the project's TypeScript settings in order for TypeScript-specific
    // things to lint correctly. We do not point this at "./tsconfig.json" because certain files
    // (such at this file) should be linted but not included in the actual project output.
    project: "./tsconfig.eslint.json",
  },

  rules: {
    // Insert changed or disabled rules here, if necessary.

    // @template-customization-start
    "class-methods-use-this": "off",
    "no-restricted-syntax": [
      "error",
      {
        selector: "MethodDefinition[accessibility='public']",
        message: 'Using "public" class method modifiers are not allowed.',
      },
      {
        selector: "MethodDefinition[accessibility='private']",
        message: 'Using "private" class method modifiers are not allowed.',
      },
      {
        selector: "MethodDefinition[accessibility='protected']",
        message: 'Using "protected" class method modifiers are not allowed.',
      },
    ],
    // @template-customization-end
  },
};