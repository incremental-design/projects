This monorepo contains many projects. the .config folder furnishes the git hooks, build scripts and development environments for each of them.

```
.----.______
|  project  |
|     A     <---------------,
'___________'               |                 .----.______
                            |                 | language- |
                            +---- tooling ----+ typescript|
.----.______                |                 '___________'
|  project  |               |
|     B     <---------------'
'___________'

.----.______
|  project  |
|     C     <---------------,
'___________'               |
                            |
.----.______                |                 ,---._______
|  project  |               |                 | langauge- |
|     D     <---------------+---- tooling ----+ go        |
'___________'               |                 '___________'
                            |
.----.______                |
|  project  |               |
|     D     <---------------'
'___________'

.----.______                                  ,---._______
|  project  |                                 | langauge- |
|     D     <-------------------- tooling ----+ nix       |
'___________'                                 '___________'

```

Each project in this monorepo uses tooling for exactly ONE language.

Each language stores its configuration in a language-\* Subfolder:

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
|   |- language-nix/
|   |   |
|   |   |- configVscode.nix       <- Nix VSCode configuration
|   |   |
|   |   |- configZed.nix          <- Nix Zed configuration
|   |   |
|   |   |- devShell.nix           <- Nix development tools
|   |   |
|   |   '- stubProject.nix        <- Nix project templates
|   |
|   |- language-go/
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
|   '- language-typescript/
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

Each language's tooling configures your IDE, stubs new projects, and configures a development environment

| file             | what it does                                                              |
| :--------------- | :------------------------------------------------------------------------ |
| configVscode.nix | Configures VSCode for the language                                        |
| configZed.nix    | Configures Zed for the language                                           |
| devShell.nix     | creates a development environment with language tools and helper commands |
| stubProject.nix  | Configures template files for new projects                                |

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

</details>

## Adding Support for a New Language

To add support for a new language (e.g., `rust`):

### 1. Create the Language Subfolder

```bash
mkdir .config/language-rust
```

> [!TIP] The language folder name must start with "language"; e.g. "language-rust", "language-zig", "language-swift"

### 2. Create `devShell.nix`

This nix expression adds packages and a shell hook to your language configuration.

```
.----.______                                  ,---._______
|  project  |                                 | langauge- |
|     D     <-------------------- tooling ----+ nix       |
'___________'                                 '___________'

^^^                                           ^^^
`cd` into this project        ...             load this language's devShell

```

`nix-direnv` loads the packages in the devShell into your `$PATH` whenever you `cd` into a project directory.
It reads the `.envrc` in the project directory to determine which language's dev shell to load:

```
 ___________
/ .envrc    |
|           |
| use ../flake.nix#.<language>
|           |
|           |
|___________|

```

It runs whenever you `nix develop <name of dev shell>`. If you have (installed direnv)[../CONTRIBUTE.md#Develop], it automatically runs when you `cd` into a project's dev shell directo

e.g.

When you install direnv and `cd` into a nix project directory, direnv will read the .envrc ...

```
# .envrc
use ../flake.nix#.nix

```
... and load the selected dev shell. In this example, it's the [nix dev shell](./language-nix/devShell.nix)

This dev shell will print a list of helper commands when it loads

When you create a dev shell, you can specify as many helper commands as you would like.

You MUST specify a `lint`, `lintSemVer`, `build`, `runTest`, `publishDryRun`, and `publish` command. The devShell wraps each of these commands, providing them with arguments, specified in [devShell.nix](./devShell.nix):

```
{pkgs ? import <nixpkgs> {}}: let
  devShellConfig = {
    packages = {                                                  # all dev tools and helper scripts you want to load

      lint = pkgs.writeShellApplication {                         # logic to lint files in project
        name = "lint";
        meta = {
          description = "...";                                    # description of what lint command does
        };
        runtimeInputs = with pkgs; [...];                         # include linter in runtimeInputs
        text = ''
        ...                                                       # include the lint command here. This script receives a
                                                                  # newline-separated list of files to lint and
                                                                  # MUST exit 0 if linting was successful and 1 if it failed
        '';
      };

      lintSemVer = pkgs.writeShellApplication {                   # logic to lint the semantic version of the project
        name = "build";
        meta = {
          description = "...;                                     # description of what lintSemVer command does
        };
        runtimeInputs = with pkgs; [...];                         # include git, and whatever you need to read the semantic
                                                                  # version at a specific commit hash here
        text = ''
        ...                                                       # receives a commit hash, and prints the semantic version
                                                                  # of the project, at that commit hash to stdout, or "none"
                                                                  # if the project has no semantic version. Always exits 0
                                                                  #
                                                                  # if your language uses a package manifest (e.g. package.json,
                                                                  # pyproject.toml, cargo.toml), read the semantic version
                                                                  # from the manifest at the commit hash and return it here
        '';
      };

      build = pkgs.writeShellApplication {                        # logic to build ALL files in the project
        name = "build";
        meta = {
          description = "...;                                     # description of what build command does
        };
        runtimeInputs = with pkgs; [...];                         # include whatever you need to build the project here
        text = ''
        ...                                                       # receives a newline-separated list of files to build
                                                                  #
                                                                  # builds the entire project, and prints newline-separated paths
                                                                  # to each built artifact to stdout. exits 0 if build succeeds
                                                                  # and 1 if build fails
        '';
      };

      runTest = pkgs.writeShellApplication {                      # logic to test files in the project
        name = "runTest";
        meta = {
          description = "...";                                    # description of what runTest command does
        };
        runtimeInputs = with pkgs; [...];                         # include language test framework here
        text = ''
        ...                                                       # include the test command here. This script receives a
                                                                  # newline-separated list of files to test and
                                                                  # MUST exit 0 if test was successful, 1 if it failed
        '';
      };

      publishDryRun = pkgs.writeShellApplication {                # logic to bump the semantic version of the project, and
        name = "publishDryRun";                                   # tag it as project/vMajor.Minor.Patch
        meta = {
          description = "...";                                    # description of what publishDryRun does
        };
        runtimeInputs = with pkgs; [...];                         # include whatever you need to bump the semantic version
                                                                  # here.
        text = ''
        ...                                                       # command to bump the semantic version. This script receives
                                                                  # newline-separated arguments:
                                                                  #
                                                                  # 1   |    current semantic version
                                                                  # 2   |    new semantic version
                                                                  # 3   |    changelog
                                                                  # ... |    changelog continued...
                                                                  #
                                                                  # it exits 0 if the current semantic version matches the semantic
                                                                  # version in the project manifest (if any) and 1 if not
        '';
      };

      publish = pkgs.writeShellApplication {                      # logic to bump the semantic version of the project, and
        name = "publishDryRun";                                   # tag it as project/vMajor.Minor.Patch
        meta = {
          description = "...";                                    # description of what publishDryRun does
        };
        runtimeInputs = with pkgs; [...];                         # include whatever you need to bump the semantic version
                                                                  # here.
        text = ''
        ...                                                       # command to bump the semantic version. This script receives
                                                                  # newline-separated arguments:
                                                                  #
                                                                  # 1   |    current semantic version
                                                                  # 2   |    new semantic version
                                                                  # 3   |    changelog
                                                                  # ... |    changelog continued...
                                                                  #
                                                                  # if the project's language has a manifest, and the current semantic
                                                                  # version matches the semantic version in that manifest, then
                                                                  # this script bumps the semantic version in the manifest to the
                                                                  # new semantic version.
                                                                  #
                                                                  # this script may also add the changelog to the project manifest,
                                                                  # project readme, or any other file in the project.
                                                                  #
                                                                  # if successful, the script exits 0, else it ROLLS BACK the changes
                                                                  # to the project manifest and other files, and exits 1
        '';
      };

  };
in
  devShellConfig
```

### 3. Create `stubProject.nix`

This shell script has complete control over project creation. It runs from the monorepo root and receives two arguments:

```
 ___________________    ____________________
| stubProject.nix   |  |   Arguments        |
| shell script      |  |                    |
|                   |  | PROJECT_DIR: "./my-proj"  <-- relative path to project
|                   |  | FLAKE_DIR:   "../"        <-- path back to repo root
|___________________|  |____________________|
         |                        |
         '--------+---------------'
                  |
                  v
         Runs in monorepo root with full access
```

**Template Structure:**
```
.config/language-rust/
|
'-- stubProject.nix    <- Shell script that creates project files
```

**Example Implementation:**

```nix
# .config/rust/stubProject.nix
{pkgs ? import <nixpkgs> {}}:
pkgs.writeShellApplication {
  name = "stubProject";
  runtimeInputs = [
    pkgs.coreutils
  ];
  text = ''
    PROJECT_DIR="$1"  # e.g., "my-rust-project"
    FLAKE_DIR="$2"    # e.g., "../" (path back to repo root)
    
    # Validate arguments
    if [ -z "$PROJECT_DIR" ]; then
        echo "PROJECT_DIR not passed as first argument" >&2
        exit 1
    fi
    
    if [ -z "$FLAKE_DIR" ]; then
        echo "FLAKE_DIR not passed as second argument" >&2
        exit 1
    fi
    
    PROJECT=$(basename "$PROJECT_DIR")
    
    # Create Cargo.toml
    cat <<-EOT > "$PROJECT_DIR/Cargo.toml"
    [package]
    name = "$PROJECT"
    version = "0.1.0"
    edition = "2021"
    EOT
    
    # Create src directory and main.rs
    mkdir -p "$PROJECT_DIR/src"
    cat <<-EOT > "$PROJECT_DIR/src/main.rs"
    fn main() {
        println!("Hello, {}!", "$PROJECT");
    }
    EOT
    
    # Create project-specific .envrc
    cat <<-EOT > "$PROJECT_DIR/.envrc"
    use flake "$FLAKE_DIR#rust"
    EOT
  '';
}
```

**Key Capabilities:**

- **Full Repository Access**: Can read/write any file in the monorepo
- **Dynamic Content**: Use shell variables, command substitution, and logic
- **Template Files**: Can `cat` heredocs or copy from template directories
- **Directory Creation**: Use `mkdir -p` to create nested structures
- **Conditional Logic**: Different files based on project name or other factors

This creates a `project-stub-rust` command that generates new Rust projects with your custom structure.

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
