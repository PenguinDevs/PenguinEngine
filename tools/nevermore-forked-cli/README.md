## Nevermore-CLI

This is a forked copy of [@quenty/nevermore-cli](https://www.npmjs.com/package/@quenty/nevermore-cli) intended to be used within [PenguinEngine](https://github.com/PenguinDevs/PenguinEngine)

Command line interface that helps you get started with Nevermore.

## Usage

In the command line or terminal:

```bash
# Install the PenguinDevs fork
npm install -g @penguindevs/nevermore-cli-fork@penguindevs

# Use the CLI
nevermore --help
nevermore init MyGameName
nevermore init-package MyPackage "Package description"
nevermore pack
```

## Design goals

1. Can initialize a new Nevermore package easily

## Build instructions

1. Clone the repository
2. Navigate to `tools/nevermore-forked-cli`
3. Run `npm install` to install dependencies
4. Run `npm run build` to compile TypeScript
5. Run `npm install -g .` to install locally for testing
6. Run `npm publish --tag penguindevs` to publish updates
