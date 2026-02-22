# Contribute to Projects:

> [!TIP] 
> Before you contribute to any project in this monorepo, you must [install nix](https://determinate.systems/nix-installer/) and [nix-direnv](https://github.com/nix-community/nix-direnv). This monorepo uses nix and nix-direnv to automatically bootstrap all dev tools. Don't install the dev tools for these projects manually. Use the versions provided by nix.

<details>
<summary>Why a monorepo?</summary>
TL;DR life is short. I don't have time to leapfrog between different repos, and neither do you.

In many ways, programming is the pursuit of maximum efficiency. A skilled programmer doesn't just optimize the time complexity of the machine. They optimize the time complexity of their life. In this case, that means putting all the code we write in ONE place where we can all see it, debug it and reuse it. No messing with submodules, symlinks, or package proxies.
</details>

<details>
<summary>Why nix?</summary>
Nix is a _cross platform_, _deterministic_ build tool. With nix, if it works on your machine, it works on _all_ machines.

Nix makes reproducible builds possible. This is very important when working with platform-specific, compiled code. Without nix, build scripts, such as makefiles, link against whatever libraries they find on your development machine. These libraries change from one OS to the next, making it difficult to build the same software on different machines. Nix versions libraries, and provides them directly to build scripts.

```
         ;^'^i:r;,
 ,nIix.l'         p
n                  c
C       nixpkgs    D
`-._______,_____.-"
          |
       dev tools
          |
      ____V_____
    /           |
    | flake.nix |                ,-----.________
    |           |                |              |
    |           +---- copied ---->   /nix/store |
    |           |     into       |              |
    |___________|                '______,_______'
                                        |
                                        |
                                 _______V_______
                                |  nix-direnv   |
                                |_______,_______|
                                        |
                                        |
                                    symlinked
                                      into
        ,-------------------------------'
 _______V________
| $PATH          |
|                |
|                |
|________________|
```

Nix also makes makes reproducible development environments possible, without dev containers. Nix versions dev tools, such as npm, node, go, terraform, etc. in the same way that it versions libraries. 

Nix-direnv automatically loads these dev tools to your $PATH, when you `cd` into this repo. It unloads these tools when you `cd ..`. You don't have to globally install *any* dev tools (other than nix itself), you don't have to install version managers and you don't have to remember to switch between versions of tools when you switch between projects.
</details>

## Develop

`cd` into the root of the repository. `nix-direnv` will load `.envrc`, which will load the dev shell in [`flake.nix`](./flake.nix). This dev shell will
- install git hooks
- install dev tools, and load them into your $PATH
- automatically install EVERY project's dependencies
- symlink a [.vscode](https://code.visualstudio.com/download) configuration folder
- symlink a [.zed](https://zed.dev) configuration folder

If you have installed [nix](https://docs.determinate.systems) and nix-direnv, you should see output like the following:

```
✅ linked /nix/store/a6154vsavsldv23wwdwgb5q1hx7kly78-vscodeConfiguration to ./.vscode
✅ linked /nix/store/8s2f27ikvyxqf8mdzs4aa3p5jaa9cr05-zedConfiguration to ./.zed
✅ commit-msg hook replaced
✅ pre-push hook already linked

   project-lint

  recurse through the working directory and subdirectories, linting all
  projects that have a flake.nix

  • use flag --changed to skip projects that have not changed in the latest
  commit

   project-lint-semver

  recurse through the working directory and subdirectories, validating the
  semantic version of projects that have a flake.nix

  • use flag --changed to skip projects that have not changed in the latest
  commit

   project-build

  recurse through the working directory and subdirectories, building projects
  that have a flake.nix

  • use flag --changed to skip projects that have not changed in the latest
  commit

   project-test

  recurse through the working directory and subdirectories, testing projects
  that have a flake.nix

  • use flag --changed to skip projects that have not changed in the latest
  commit

   project-install-vscode-configuration

  symlink the .vscode configuration folder into the root of this repository.
  Automatically run when this shell starts

   project-install-zed-configuration

  symlink the .zed configuration folder into the root ofthis repository.
  Automatically run when this shell starts

   nix

  the version of nix to use in the current working directory

   project-stub-nix_v2.33.1

  Stub a project with nix_v2.33.1
```

> [!TIP]
> if you did *not* install nix-direnv, you can run `nix develop` in the root of the repository to set up the development environment.

`nix-direnv` automatically installs helper commands and IDE configuration files. If you are developing in VScode or Zed, restart your editor to pick up the configuration files.

That's it! There's no super-complicated, error prone setup. No asking "what version of node do I use", and no debugging weird native build failures. Install nix, `cd` into this repo, and develop.

### Repository Structure:

This monorepo is split into several projects. A project is any folder that contains a **manifest file** e.g. a `deno.json`, `go.mod`, `flake.nix`. 
- Project folders can be nested.
- A project folder can contain more than one manifest file.
- You can run any of the `project-*` commands in any project folder. The command will automatically detect the manifest files in the folder _and_ _subfolders_, and run the corresponding command. E.g. `project-lint` in a folder with a `deno.json` and a `go.mod` will run both `deno-lint` and `golangci-lint`.

> [!TIP]
> **Why not directly run the language-specific lint, build and test commands?**
> You *can* run the project's language-specific lint, build and test commands! The project-lint, project-build, and project-test commands give the [git hooks](.config/installGitHooks.nix), [`project-lint`](.config/dev-shell.nix), [`project-lint-semver`](.config/dev-shell.nix), [`project-build`](.config/dev-shell.nix), [`project-test`](.config/dev-shell.nix), and [github actions](.github/workflows/push.yml) a project-agnostic command to call when they recurse through the projects in the monorepo.

All projects contain a `project-lint-semver` command. This command checks the semantic version of a project, and verifies that its semantic versions do not decrease over the course of the project's git history.

**This repository will prevent you from pushing obviously broken code to Github.**

This repository [automatically runs](./.config/install-git-hooks.nix) the `project-lint`, `project-lint-semver`, `project-build`, and `project-test` commands in every project in the *latest* commit, [before you push](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) commits to any remote, using the [pre-push hook](.config/installGitHooks.nix). It also runs these hooks on *every* commit you push in [github actions](.github/workflows/push.yml), every time you push to github.

> [!WARN]
> This repository will NOT prevent you from pushing semantically incorrect code to Github. Your job is to test and bench your code thoroughly *before* you push. Don't make it the next programmer's responsibility to find out and fix your code's nasty side effects.

  ```
   projects/
     |                   -,
     |- .config/          |- configuration files included in flake.nix
     |                   -'
     |                   -,
     |- .github/          |- continuous integration configuration. Do not modify this.
     |                   -'
     |                   -,
     |- .vscode           |  configuration files for zed, vscode and cursor.
     |                    |- Do not modify these files. They are automatically
     |- .zed              |  generated by flake.nix
     |                   -'
     |                   -,
     |- .direnv           |  configuration and cache for nix-direnv. Do not modify
     |                    |- these.
     |- .envrc            |
     |                   -'
     |                   -,
     |- .gitignore        |- list of files to ignore
     |                   -'
     |                   -,
     |- flake.nix         |  installs dev environment when you `cd` into projects/
     |                    |- or open projects/ in zed editor. Auto-generates
     |- flake.lock        |  editor configuration folders.
     |                   -'
     |                   -,
     |- .../              |- folders that contain projects
     |                   -'  
     |                   -,
     |- go.work           |
     |                    |
     |- cargo.toml        |- workspace configuration files
     |                    |
     |- deno.json         |
     |                   -'
     :
     :
  ```

### When to make a new project:

TL;DR: almost never.

A project is a commitment to maintain a piece of code, indefinitely. When you make a project, it must have a stable API with 100% test coverage of all methods.

This is a lot of extra work! Especially if no one else is using your project!

  ```
   projects/
     |
     |- project-a/
     |
     |
     |- project-b/
     |
     |
     |- your-new-project/
     |    |
     |    '- your-fancy-code   <-- STOP. Don't do this
     :
  ```
Instead of making a project, modify an existing project. Make sure you don't break its API.

  ```
   projects/
     |
     |- project-a/
     |    |
     |    '- your-fancy-code    <- it's better to DUPLICATE
     |                             the code between two packages
     |                             than it is to commit to maintaining
     |- project-b/                 a third package.
     |    |
     |    '- your-fancy-code
     |
     :
     :
  ```

If you *think* you have a piece of code that can be shared between two existing projects, you probably don't. Just duplicate it in each existing project. In most cases, the piece of code will end up diverging over time, because the code will likely fulfill a different use case in each project.

If the code does *not* diverge over time, it hasn't changed in at least 4 months, and other human beings want to use it, then it's a good candidate to refactor into its own project.

I will only merge a PR with a project if
1. It contains 100% unit test coverage of all public APIs
2. Exposes some kind of documentation (e.g. if it is an API server, it must have an API.json). If it is a library, it must have auto-generated documentation.
3. It is referenced by at least THREE other projects. Ideally, one of the three projects should be in a repository *other than this monorepo.*
4. Contains a README and a CONTRIBUTE that follow the style guide prescribed by [stubProject.nix](./.config/stubProject.nix)
5. Has a public API that has been untouched in the past 4 months.

### How to make a new project (if you *really* need to)

`cd` to the root of this repository, and run one of the `project-stub-*` commands. For example, to create a nix project, run the `project-stub-nix_v2.33.1` command. The command [will create a new project directory](./.config/stub-project-nix_v2.33.1.nix), complete with a development environment and all of the files needed to develop the project.

> [!TIP]
> If you need to make a project that combines multiple languages, or has a complicated build process, you can create a nix project. The nix project lets you define your own custom lint, build and test scripts.

### How to use one project in another
Go, deno, python and nix all support workspaces. Workspaces _alias_ package imports to their corresponding local directory:

Each of these languages includes a workspace configuration file:

| language | workspace configuration file                                                |
|:---------|:----------------------------------------------------------------------------|
| Go       | [`go.work`](https://go.dev/doc/tutorial/workspaces)                         |
| Deno     | [`deno.json`](https://docs.deno.com/runtime/fundamentals/workspaces/)       |
| Python   | [`pyproject.toml`](https://docs.astral.sh/uv/concepts/projects/workspaces/) |
| Nix      | [`overlay.nix`](https://nixos.wiki/wiki/Overlays)                           |

When you run a `project-stub-*` command, it automatically adds your new project to all applicable workspaces. (e.g. a project with a go.mod will be added to [`./go.work`](./go.work), a project with both a `deno.json` and a `pyproject.toml` will be added to _both_ [`deno.json`](./deno.json) and [`pyproject.toml`](./pyproject.toml))

> [!TIP]
> A single project can contain manifests for more than one language, and can therefore be added to more than one language's workspace.

> [!TIP]
> Nix doesn't actually support workspaces

### How to delete a project:

TRY NOT TO DO THIS. You cannot erase a project from git history, and you cannot un-tag it if it has been semantically versioned. However, you CAN delete manifest files out of folders, or even move them from one folder to another.

- If you delete a manifest file, the project will no longer be auto-tagged for release, because there is no manifest off of which to determine its semantic version.

>[!WARN]
> You cannot delete a project in the HEAD of a branch. If you delete a project, you must author another commit on top of it. This is because the `project-lint-semver` script will detect the deletion of the project as a change. Then, it will try to read the project manifest, fail to find it, and error. However, if you author another commit, the commit will hide the deletion from the `project-lint-semver` script
> If you version a project, and then delete it, you can never re-create it. This is because the `project-lint-semver` script will detect the deletion, and fail to read the manifest at the commit in which it was deleted.

>[!WARN]
> If you move a manifest from one directory to another, the `project-lint-semver` script will detect it as a new project. 

### How to structure your code:

Each file should contain ONE class, interface, or function. If your file exceeds 500 lines of code, your class, interface or function is probably doing too much.

Do NOT shove multiple classes into a single file. If you do this, I WILL reject your PR, and ask you to split your code across multiple files.

Each file should do exactly ONE thing. If a file is repeatedly modified in several commits, that is usually a sign that it is doing too much.

In general, [follow design patterns](https://refactoring.guru) and the conventions for the language you are writing:

- [typescript style guide](https://google.github.io/styleguide/tsguide.html)
- [go style guide](https://go.dev/doc/effective_go)
- [python style guide](https://peps.python.org/pep-0008/)

If you do NOT follow these style guides, I will reject your PR and show you how to change your code so that it matches.

Organize the code within each project according to import scope. No code should ever import from a parent folder

```
GOOD:

import code from ./path/to/code
import code from "some-package"
import code from "@incremental.design/some/project" <- aliases to ./some/project

BAD:

import code from ../../../code
```

When your code only imports from child folders, it prevents import cycles, and makes it easy for other contributors to reason about the dependencies.

> [!TIP]
> It is OK to import code from another project, as long as you don't import from the relative path to the project. Use the project's package manager name instead.


### How to author a commit:
See [`commitlint-config.nix`](.config/commitlintConfig.nix)

### How to submit pull requests:

The only way to contribute your code to the main branch is to submit a pull request.

This repository will not let you merge your branch into main if the HEAD of main has diverged from the BASE of your branch.

```
Before pull request:

main     -----0-----1-----2-----3-----4-----5--.
                                                \
                                                 \
your                                              6-----7-----8-----9
branch

After pull request:

main     -----0-----1-----2-----3-----4-----5--.                       .--10
                                                \                     /   ^^^
                                                 \                   /    merge commit
your                                              6-----7-----8-----9
branch

```

Before your submit a pull request, make sure you rebase the main branch onto your branch, and resolve any conflicts.

Once your pull request is approved, you can merge it into the the main branch.

```
Before rebasing
your branch onto
MAIN

another
branch                                            6-----7-----8
                                                 /             \
                                                /               \
main     -----0-----1-----2-----3-----4-----5--:                 '--9 <-- merge commit
                                                \
                                                 \
your                                              6'----7'----8'----9'
branch                                                              ^^^
                                                                    cannot be merged, because HEAD of main is
                                                                    commit 9, and base of your branch is commit 5.
After rebasing
your branch onto main:

another
branch                                            6-----7-----8
                                                 /             \
                                                /               \
main     -----0-----1-----2-----3-----4-----5--:                 '--9 <-- merge commit
                                                                     \
                                                                      \
your                                                                   10----11----12----13
branch                                                                 ^^^
                                                                       can be merged, because HEAD of main is
                                                                       commit 9, and base of your branch is commit 9.


```

You must [sign all commits](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits) in a pull request before you can merge it back into main.

## Lint:

- Run `project-lint` in the root of this repo to run ALL tests in all projects in this directory and its subdirectories.
- Run `project-lint --changed` in the root of this repo to run tests in the projects that changed between the previous commit and HEAD in this directory and its subdirectories.

## Build:

- Run `project-build` in the root of this repo to run ALL tests in all projects in this directory and its subdirectories.
- Run `project-build --changed` in the root of this repo to build the projects that changed between the previous commit and HEAD in this directory and its subdirectories.

## Test:

- Run `project-test` in the root of this repo to run ALL tests in all projects in this directory and its subdirectories.
- Run `project-test --changed` in the root of this repo to run tests in the projects that changed between the previous commit and HEAD in this directory and its subdirectories.

**Make sure every exported function has a deterministic test**

## Document:

When you stub a new project, it will create a README.md and a CONTRIBUTE.md. Follow the template instructions to document what the project does.

Every public API, exported method, and script must describe its inputs, outputs, and any irreversible side effects. Use languages' standard tools to document the API contract (e.g. [api.json](https://swagger.io/specification/) for REST APIs, [go doc comments](https://go.dev/blog/godoc) for exported go functions, [TSdoc for typescript](https://tsdoc.org), etc. )

## Publish:

All projects in this monorepo use [semantic versioning](https://semver.org/) (MAJOR.MINOR.PATCH format) with project-specific prefixes.

To publish a project, bump its semantic version with the languages' respective tools. Then, submit a PR. Once I approve your PR, github actions will iterate through the commits in your PR, and tag the ones that contain semantic version bumps as path/to/project/vMAJOR.MINOR.PATCH

- Multiple projects can be incremented in a single commit. In this case, each project will get its own tag, but all tags will point to the same commit.

Once github actions tags the commits, it will publish projects to the registries that match their manifest files:

e.g. 

| manifest file   | registry                                                |
|:----------------|:--------------------------------------------------------|
| `flake.nix`     | [flakehub](https://flakehub.com/flakes)                 |
| `deno.json`     | [jsr](https://www.jsr.io/)                              |
| `go.mod`        | [pkg.go.dev](https://pkg.go.dev/about#adding-a-package) |
| `pyproject.toml`| [pypi](https://pypi.org)                                |

You cannot manually publish a project from your terminal. Only Github Actions has the keys to package registries.
