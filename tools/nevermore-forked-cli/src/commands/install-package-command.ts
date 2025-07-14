/**
 * Install Nevermore packages from npm
 */

import { Argv, CommandModule } from "yargs";
import { OutputHelper } from "@quenty/cli-output-helpers";
import { NevermoreGlobalArgs } from "../args/global-args";
import {
  runCommandAsync,
} from "../utils/nevermore-cli-utils";
import * as fs from "fs/promises";
import * as path from "path";

export interface InstallPackageArgs extends NevermoreGlobalArgs {
  packages: string[];
}

/**
 * Install a Nevermore package from npm
 */
export class InstallPackageCommand<T> implements CommandModule<T, InstallPackageArgs> {
  public command = "install [packages..]";
  public aliases = ["i"];
  public describe = "Install Nevermore packages from npm";

  private static _validatePackageName(name: string): void {
    if (!name) {
      throw new Error("Package name is required!");
    }
  }

  private static async _getPackages(): Promise<string[]> {
    try {
      const response = await fetch(
        "https://registry.npmjs.org/-/v1/search?text=@quenty/&size=1000"
      );
      const data = await response.json();
      return data.objects
        .map((obj: any) => obj.package.name)
        .filter((name: string) => name.startsWith("@quenty/"))
        .map((name: string) => name.replace("@quenty/", ""))
        .sort();
    } catch {
      return [];
    }
  }

  private static async _updateLuaurcAliases(srcRoot: string, packages: string[]): Promise<void> {
    const luaurcPath = path.join(srcRoot, ".luaurc");

    let luaurc: any = {
      languageMode: "strict",
      typeErrors: true,
      lintErrors: true,
      aliases: {}
    };

    // Try to read existing .luaurc
    try {
      const existingContent = await fs.readFile(luaurcPath, "utf-8");
      luaurc = JSON.parse(existingContent);

      // Ensure aliases object exists
      if (!luaurc.aliases) {
        luaurc.aliases = {};
      }
    } catch {
      // File doesn't exist or is invalid, we'll create a new one
      OutputHelper.info("Creating new .luaurc file");
    }

    // Add new package aliases
    for (const packageName of packages) {
      const aliasName = InstallPackageCommand._getAliasName(packageName);
      const aliasPath = `node_modules/@quenty/${packageName}/src`;

      luaurc.aliases[aliasName] = aliasPath;
      OutputHelper.info(`Added alias: ${aliasName} -> ${aliasPath}`);
    }

    // Write updated .luaurc
    await fs.writeFile(luaurcPath, JSON.stringify(luaurc, null, 2), "utf-8");
    OutputHelper.info("Updated .luaurc file");
  }

  private static _getAliasName(packageName: string): string {
    // Convert package names to proper alias names
    // e.g., "baseobject" -> "BaseObject", "servicebag" -> "ServiceBag"
    // Handle special cases for common packages
    const specialCases: { [key: string]: string } = {
      "servicebag": "ServiceBag",
      "baseobject": "BaseObject",
      "maid": "Maid",
      "signal": "Signal",
      "binder": "Binder",
      "loader": "Loader"
    };

    if (specialCases[packageName.toLowerCase()]) {
      return specialCases[packageName.toLowerCase()];
    }

    // Default case: capitalize each word
    return packageName
      .split(/[-_]/)
      .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
      .join("");
  }

  public builder(args: Argv<T>) {
    args.positional("packages", {
      type: "string",
      array: true,
      describe: "Name of the package(s) to install",
      completion: async (current: string) => {
        const packages = await InstallPackageCommand._getPackages();
        return packages.filter(name => !current || name.startsWith(current));
      }
    });
    return args as Argv<InstallPackageArgs>;
  }

  public async handler(args: InstallPackageArgs) {
    const srcRoot = process.cwd();

    if (!args.packages?.length) {
      throw new Error("No packages specified!");
    }

    args.packages.forEach(packageName => InstallPackageCommand._validatePackageName(packageName));

    const availablePackages = await InstallPackageCommand._getPackages();
    const invalidPackages = args.packages.filter(
      packageName => !availablePackages.includes(packageName)
    );

    if (invalidPackages.length > 0) {
      throw new Error(`Invalid packages: ${invalidPackages.join(", ")}`);
    }

    const prefixedPackages = args.packages.map(packageName => `@quenty/${packageName}`);

    OutputHelper.info(`Installing packages: ${args.packages.join(", ")}`);

    await runCommandAsync(args, "npm", ["install", ...prefixedPackages], {
      cwd: srcRoot,
    });

    // Update .luaurc aliases after successful installation
    OutputHelper.info("Updating .luaurc aliases...");
    await InstallPackageCommand._updateLuaurcAliases(srcRoot, args.packages);

    OutputHelper.info("✅ Installation and alias setup complete!");
  }
}