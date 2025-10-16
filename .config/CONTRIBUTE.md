This monorepo contains many projects. the .config folder furnishes the git hooks, build scripts and development environments for each of them.

Each project in this monorepo contains tooling for exactly ONE language.

Each language stores its configuration in one subfolder of .config.

```
projects
|
|-.config/
|   |
|   |- CONTRIBUTE.md          <- YOU ARE HERE
|   |
|   |- devShell.nix           <- merges all languages' dev shell configs,
|   |                            makes default dev shell config, imports
|   |                            ./configVscode.nix and ./configZed.nix
|   |
|   |- configVscode.nix       <- merges all languages' VSCode configs
|   |
|   |- configZed.nix          <- merges all languages' Zed configs
|   |
|   |- stubProject.nix        <- merges all languages' project configs
|   |
|   |- nix/
|   |   |
|   |   |- configVscode.nix       <- Nix VSCode configuration
|   |   |
|   |   |- configZed.nix          <- Nix Zed configuration
|   |   |
|   |   |- devShell.nix           <- Nix development tools
|   |   |
|   |   '- stubProject.nix        <- Nix project templates
|   |
|   |- go/
|   |   |
|   |   |- configVscode.nix       <- Go VSCode configuration
|   |   |
|   |   |- configZed.nix          <- Go Zed configuration
|   |   |
|   |   |- devShell.nix           <- Go development tools
|   |   |
|   |   '- stubProject.nix        <- Go project templates
|   |
|   :
|   :
|   '- typescript/
|       |
|       |- configVscode.nix       <- TypeScript VSCode configuration
|       |
|       |- configZed.nix          <- TypeScript Zed configuration
|       |
|       |- devShell.nix           <- TypeScript development tools
|       |
|       '- stubProject.nix        <- TypeScript project templates
|
|
:
:
|- flake.nix              <- imports devShell.nix, stubProject.nix
:
:
```

<details>
<summary>Why Language Subfolders?</summary>

**Separation of Concerns**: Each language folder contains ALL the configuration needed for that specific language:

- Development tools (compilers, linters, formatters)
- Project templates (files created for new projects)
- Editor settings (syntax highlighting, language servers)
- Debug configurations
- Build tasks

```
  __________
/ flake.nix |
|           |
|           |
|           |
|           |
|_____ _____|
      ^
      |
   imports
      |
.----.______
| .config   |
|           <------------,---------------,
'____,______'            |               |
     |                ___|___         ___|___
     |               /       |       /       |
     |               | stubProject   | devShell
     |               | .nix  |       | .nix  |
     |               |___ ___|       |___ ___|
     |                   ^               ^
     |                   |               |
     |                   |               +----------------,---------------,
     |                   |               |                |               |
     |                   |               |             ___|___         ___|___
     |                   |               |            /       |       /       |
     |                   |               |            | configVscode  | configZed
     |                   |               |            | .nix  |       | .nix  |
     |                   |               |            |___ ___|       |___ ___|
     |                   |               |                ^               ^
     |                   |               |                |               |
     |                   |               |                |               |
     |                   '---------------'-------,--------'---------------'
     |                                           |
     |                                        imports
     |                                           |
     |                                        ___|___
     |                                       /       |
     |                                       | importFromLanguageFolder.nix
     |                                       |       |
     |                                       |_______|
     |                                           |
     |                                           |
     |                                        imports
     |                                           |
     |                                           |
     |  ,----.____       ,---------------,-------'--------,---------------,
     '--| <language>     |               |                |               |
        |         |      |               |                |               |
        '---------'      |               |                |               |
             ^           |               |                |               |
             |           |               |                |               |
         contains        |               |                |               |
             |           |               |                |               |
             |           |               |                |               |
             |           |               |                |               |
             |        ___|___         ___|___          ___|___         ___|___
             |       /       |       /       |        /       |       /       |
             |       | stubProject   | devShell       | configVscode  | configZed
             |       | .nix  |       | .nix  |        | .nix  |       | .nix  |
             |       |_______|       |_______|        |_______|       |_______|
             |           |               |                |               |
             |           |               |                |               |
             |           |               |                |               |
             '-----------'---------------'----------------'---------------'


```

`Flake.nix` imports `.config/devShell.nix`, `.config/stubProject.nix`

`config/devShell.nix`imports `config/configVscode.nix`, `config/configZed.nix`.
Each of these files imports the corresponding files from each language folder in .config.

This makes it easy to add, remove, or modify support for any language without affecting others.

```
Without Language Separation (BAD):
 ________________
|                |
| One Giant      |  <- Go settings mixed with
| Config File    |     Python settings mixed with
|                |     Nix settings = MESS
|________________|

With Language Separation (GOOD):
  ______   ______   ______   ______
|      | |      | |      | |      |
| Nix  | | Go   | |Python| |TypeS-|
| Only | | Only | | Only | |cript |
|      | |      | |      | | Only |
|______| |______| |______| |______|
```

</details>

## Adding Support for a New Language

To add support for a new language (e.g., `rust`):

### 1. Create the Language Subfolder

```bash
mkdir .config/language-rust
```

> [!TIP] The language folder name must start with "language"; e.g. "language-rust", "language-zig", "language-swift"

### 2. Create `devShell.nix`

The devShell loads helper commands for managing a project. It runs whenever you `nix develop <name of dev shell>`. If you have (installed direnv)[../CONTRIBUTE.md#Develop], it automatically runs when you `cd` into a project directory.

e.g.

When you install direnv and `cd` into a nix project directory, direnv will read the .envrc

```
# .envrc
use ../flake.nix#.nix

```

and load the selected dev shell. In this example, it's the [nix dev shell](./language-nix/devShell.nix)

This dev shell will print a list of helper commands when it loads

```

   command       │ description
  ───────────────┼──────────────────────────────────────────────────────────
   lint          │ lint .nix files
   lintSemVer    │ validate the current semantic version of this project
   build         │ build .nix files
   runTest       │ test .nix files
   publishDryRun │ dry-run publish nix packages
   publish       │ publish nix packages
```

When you create a dev shell, you can specify as many helper commands as you would like. You MUST specify a
`lint`, `lintSemVer`, `build`, `runTest`, `publishDryRun`, and `publish` command. The devShell provides each of these commands with arguments, specified in [devShell.nix](./devShell.nix);

### 3. Create `stubProject.nix`

This expression contains the files you want to include in the project. It overrides the defaults included in [.config/stubProject.nix]

e.g.

```nix
# .config/rust/stubProject.nix
{ ... }{
  devShellName = "rust";

  "README.md" = ''
    # Rust Project
    A Rust application built with Cargo.
  '';

  "Cargo.toml" = ''
    [package]
    name = "project-name"
    version = "0.1.0"
    edition = "2021"
  '';

  "src/main.rs" = ''
    fn main() {
        println!("Hello, world!");
    }
  '';

  # Disable the default LICENSE file
  "LICENSE" = "";
}
```

This automatically creates a `rustStubProject` command that generates new Rust projects with your templates.

**File Template Rules:**

- **If a template is not provided**: The default template will be used
- **If a blank template is provided** (set to `""`): The file will be omitted entirely

### 4. Create `configVscode.nix`

Each attribute set in `configVscode.nix` adds properties to the corresponding VS Code configuration file:

| Configuration Key  | Target File               | Purpose                                                                |
| ------------------ | ------------------------- | ---------------------------------------------------------------------- |
| `vscodeSettings`   | `.vscode/settings.json`   | Editor settings, language server configurations, workspace preferences |
| `vscodeExtensions` | `.vscode/extensions.json` | Recommended extensions for the workspace                               |
| `vscodeLaunch`     | `.vscode/launch.json`     | Debug configurations and launch settings                               |
| `vscodeTasks`      | `.vscode/tasks.json`      | Build tasks, test runners, and custom commands                         |

```nix
# .config/rust/configVscode.nix
{ pkgs ? import <nixpkgs> {} }: {
  vscodeSettings = {
    "rust-analyzer.server.path" = "${pkgs.rust-analyzer}/bin/rust-analyzer";
    "rust-analyzer.checkOnSave.command" = "clippy";
  };
  vscodeExtensions = {
    "recommendations" = [
      "rust-lang.rust-analyzer"
    ];
  };
  vscodeLaunch = {
    "version" = "0.2.0";
    "configurations" = [
      {
        "type" = "lldb";
        "request" = "launch";
        "name" = "Debug Rust";
        "cargo" = {
          "args" = ["build" "--bin=main"];
        };
      }
    ];
  };
  vscodeTasks = {
    "version" = "2.0.0";
    "tasks" = [
      {
        "type" = "cargo";
        "command" = "build";
        "group" = "build";
      }
    ];
  };
}
```

### 5. Create `configZed.nix`

Each attribute set in `configZed.nix` adds properties to the corresponding Zed configuration file:

| Configuration Key | Target File          | Purpose                                                             |
| ----------------- | -------------------- | ------------------------------------------------------------------- |
| `zedSettings`     | `.zed/settings.json` | Editor settings, language configurations, and workspace preferences |
| `zedDebug`        | `.zed/debug.json`    | Debug adapter configurations and debugging settings                 |

```nix
# .config/rust/configZed.nix
{ pkgs ? import <nixpkgs> {} }: {
  zedSettings = {
    "auto_install_extensions" = {
      "Rust" = true;
    };
    "languages" = {
      "Rust" = {
        "language_servers" = ["rust-analyzer"];
        "formatter" = {
          "external" = {
            "command" = "${pkgs.rustfmt}/bin/rustfmt";
            "arguments" = ["--edition" "2021"];
          };
        };
      };
    };
    "lsp" = {
      "rust-analyzer" = {
        "binary" = {
          "path" = "${pkgs.rust-analyzer}/bin/rust-analyzer";
        };
      };
    };
  };
  zedDebug = {
    "rust" = {
      "adapter" = "lldb";
    };
  };
}
```
