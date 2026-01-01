The .config folder contains all of the code needed to support projects of various languages

In this monorepo, we assume that each project is written in ONE language.

To add support for projects in a new language, create a `language-*/` folder containing:

```
language-go/
 |
 |-- .envrc             # direnv integration: use flake ../../#go
 |
 |-- .gitignore         # exclude everything except .nix files
 |
 |-- devShell.nix       # project-lint, project-build, project-test commands
 |
 |-- configVscode.nix   # LSP, formatter, extension settings for VSCode
 |
 |-- configZed.nix      # LSP, formatter, extension settings for Zed
 |
 |-- stubProject.nix    # script to scaffold new projects
 |
 '-- templateProject/   # files copied by stubProject.nix
```

Each nix expression points editors to nix-installed dev tools rather than
system-installed ones, ensuring consistent tooling across machines.

**Reference Documentation:**

| File               | Documentation                                          | Example                                                        |
| ------------------ | ------------------------------------------------------ | -------------------------------------------------------------- |
| `.envrc`           | use `flake ../../#nix`                                 | [language-nix/.envrc](language-nix/.envrc)                     |
| `.gitignore`       | exclude all except `.nix` files                        | [language-nix/.gitignore](language-nix/.gitignore)             |
| `devShell.nix`     | see [devShell.nix](devShell.nix) lines 617-722         | [language-nix/devShell.nix](language-nix/devShell.nix)         |
| `configVscode.nix` | see [configVscode.nix](configVscode.nix) lines 119-189 | [language-nix/configVscode.nix](language-nix/configVscode.nix) |
| `configZed.nix`    | see [configZed.nix](configZed.nix) lines 146-213       | [language-nix/configZed.nix](language-nix/configZed.nix)       |
| `stubProject.nix`  | see [stubProject.nix](stubProject.nix)                 | [language-nix/stubProject.nix](language-nix/stubProject.nix)   |
