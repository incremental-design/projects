The .config folder contains all of the code needed to run commands defined in manifest files, such as `package.json`, `go.mod`, `cargo.toml`, `flake.nix`

To add support for a manifest file, see [dev-shell.nix](./dev-shell.nix) line ~332

commands use specific versions of dev tools: e.g. nix 2.33.1, go 1.26, etc.

To register a tool version, see [tool.nix](./tool.nix) line ~153

The config folder also contains commands to stub new projects. To add support for stubbing a new project, see [stub-project.nix](./stub-project.nix) line ~214
