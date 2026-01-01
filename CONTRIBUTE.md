# Contribute to Projects:

> [!TIP] Before you contribute to any project in this monorepo, you must [install nix](https://determinate.systems/nix-installer/) and [nix-direnv](https://github.com/nix-community/nix-direnv). This monorepo uses nix and nix-direnv to automatically bootstrap all dev tools. Don't install the dev tools for these projects manually. Use the versions provided by nix.

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

Nix-direnv automatically loads these dev tools to your $PATH, when you `cd` into this repo. It unloads these tools when you `cd ..`. You don't have to globally install _any_ dev tools (other than nix itself), you don't have to install version managers and you don't have to remember to switch between versions of tools when you switch between projects.
</details>

## Develop

`cd` into the root of the repository. `nix-direnv` will load `.envrc`, which will install git hooks, dev tools, and print a list of helper commands. If you are developing in [vscode](https://code.visualstudio.com/download) or [zed](https://zed.dev), `nix-direnv` will also configure your editor settings and extensions.

If you have installed [nix](https://docs.determinate.systems) and nix-direnv, you should see the following output:

```
✅ linked /nix/store/a6154vsavsldv23wwdwgb5q1hx7kly78-vscodeConfiguration to ./.vscode
✅ linked /nix/store/8s2f27ikvyxqf8mdzs4aa3p5jaa9cr05-zedConfiguration to ./.zed
✅ linked commit-msg hook
✅ linked pre-push hook

   project-install-vscode-configuration

  │ install .vscode/ configuration folder, if .vscode/ is not already present.
  │ Automatically run when this shell is opened.

   project-install-zed-configuration

  │ install .zed/ configuration folder, if .zed/ is not already present.
  │ Automatically run when this shell is opened

   project-install-git-hooks

  │ Install commit-msg and pre-push hooks in this project. Automatically run
  │ when
  │ this shell is opened

   project-stub-nix

  │ Stub a nix project

   project-lint-all

  │ project-lint all projects

   project-lint-semver-all

  │ project-lint-semver all projects

   project-build-all

  │ project-build all projects

   project-test-all

  │ project-test all projects
```

> [!TIP]
> if you did _not_ install nix-direnv, you can run `nix develop` in the root of the repository to set up the development environment.

`nix-direnv` automatically installs helper commands and IDE configuration files. If you are developing in VScode or Zed, restart your editor to pick up the configuration files.

That's it! There's no super-complicated, error prone setup. No asking "what version of node do I use", and no debugging weird native build failures. Install nix, `cd` into this repo, and develop.

### Repository Structure:

This monorepo is split into several projects. Each project has a language, and bootstraps the dev tools you need to code in that language. E.g. some projects use go, and ship with the `go` command suite. Other projects use typescript and ship with `bun` and `oxc`.

To load the dev tools, `cd` into the project. `nix-direnv` will read the `.envrc` in the project, and add the devtools to your $PATH. Then, it will print a list of commands you can use to lint, build and test the project.

All projects will contain a `project-lint`, `project-build`, and `project-test` command. Some projects may contain additional commands. These helper commands wrap the language-specific commands required to lint, build and test the project.

> [!TIP]
> Why not directly run the language-specific lint, build and test commands?
> You *can* run the project's language-specific lint, build and test commands! The project-lint, project-build, and project-test commands give the [git hooks](.config/installGitHooks.nix), [`project-lint-all`](.config/devShell.nix), [`project-lint-semver-all`](.config/devShell.nix), [`project-build-all`](.config/devShell.nix), [`project-test-all`](.config/devShell.nix), and [github actions](.github/workflows/push.yml) a project-agnostic command to call when they [recurse](.config/recurse.nix) through the projects in the monorepo.

All projects contain a `project-lint-semver` command. This command checks the semantic version of a project, and verifies that its semantic versions do not decrease over the course of the project's git history.

*This repository will prevent you from pushing _obviously_ broken code to Github.*

This repository [automatically runs](./.config/installGitHooks.nix) the `project-lint`, `project-lint-semver`, `project-build`, and `project-test` commands in every project in the _latest_ commit, [before you push](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks) commits to any remote, using the [pre-push hook](.config/installGitHooks.nix). It also runs these hooks on _every_ commit you push in [github actions](.github/workflows/push.yml), every time you push to github.

> [!WARN]
> This repository will NOT prevent you from pushing semantically incorrect code to Github. Your job is to test and bench your code thoroughly _before_ you push. Don't make it the next programmer's responsibility to find out and fix your code's nasty side effects.

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
     |- go-starter        |
     |                    |
     |- typescript-       |- example projects. Do not modify these.
     |  starter           |
     |                    |
     |                   -'
     |                   -,
     |- infrastructure    |- project that contains NixOS, NixOps, and Kubernetes code
     |                   -'  used to configure and deploy development hardware
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

If you _think_ you have a piece of code that can be shared between two existing projects, you probably don't. Just duplicate it in each existing project. In most cases, the piece of code will end up diverging over time, because the code will likely fulfill a different use case in each project.

If the code does _not_ diverge over time, it hasn't changed in at least 4 months, and other human beings want to use it, then it's a good candidate to refactor into its own project.

I will only merge a PR with a project if
1. It contains 100% unit test coverage of all public APIs
2. Exposes some kind of documentation (e.g. if it is an API server, it must have an API.json). If it is a library, it must have auto-generated documentation.
3. It is referenced by at least THREE other projects. Ideally, one of the three projects should be in a repository *other than this monorepo.*
4. Contains a README and a CONTRIBUTE that follow the style guide prescribed by [stubProject.nix](./.config/stubProject.nix)
5. Has a public API that has been untouched in the past 4 months.

### How to make a new project (if you _really_ need to)

`cd` to the root of this repository, and run one of the `project-stub-*` commands. For example, to create a nix project, run the `project-stub-nix` command. The command [will create a new project directory](./.config/stubProject.nix), complete with a development environment and all of the files needed to develop the project.

> [!TIP]
> If you need to make a project that combines multiple languages, or has a complicated build process, you can create a nix project. The nix project lets you define your own custom lint, build and test scripts.

### How to structure your code:

Each file should contain ONE class, interface, or function. If your file exceeds 500 lines of code, your class, interface or function is probably doing too much.

Do NOT shove multiple classes into a single file. If you do this, I WILL reject your PR, and ask you to split your code across multiple files.

Each file should do exactly ONE thing. If a file is repeatedly modified in several commits, that is usually a sign that it is doing too much.

In general, [follow design patterns](https://refactoring.guru) and the conventions for the language you are writing:

- [typescript style guide](https://google.github.io/styleguide/tsguide.html)
- [go style guide](https://go.dev/doc/effective_go)

If you do NOT follow these style guides, I will reject your PR and show you how to change your code so that it matches.

Organize your code according to import scope. No code should ever import from a parent folder

```
GOOD:

import code from ./path/to/code

BAD:

import code from ../../../code
```

When your code only imports from child folders, it prevents import cycles, and makes it easy for other contributors to reason about the dependencies.

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

- Run `project-lint-all` in the root of this repo to run ALL tests

- Run `project-lint` inside a project to run the project's tests.

## Build:

- Run `project-build-all` in the root of this repo to run ALL tests

- Run `project-build` inside a project to run the project's tests.

## Test:

- Run `project-test-all` in the root of this repo to run ALL tests

- Run `project-test` inside a project to run the project's tests.

Every exported function should have a unit test attached to it.

## Document:

When you stub a new project, it will create a README.md and a CONTRIBUTE.md. Follow the template instructions to document what the project does.

Every public API, exported method, and script must describe its inputs, outputs, and any irreversible side effects. Use languages' standard tools to document the API contract (e.g. [api.json](https://swagger.io/specification/) for REST APIs, [go doc comments](https://go.dev/blog/godoc) for exported go functions, [TSdoc for typescript](https://tsdoc.org), etc. )

## Publish:

All projects in this monorepo use [semantic versioning](https://semver.org/) (MAJOR.MINOR.PATCH format) with project-specific prefixes.

To publish a project, bump its semantic version with the languages' respective tools. Then, submit a PR. Once I approve your PR, github actions will iterate through the commits in your PR, and tag the ones that contain semantic version bumps as path/to/project/vMAJOR.MINOR.PATCH

- Multiple projects can be incremented in a single commit. In this case, each project will get its own tag, but all tags will point to the same commit.

Once github actions tags the commits, it will publish projects to the registries that match their manifest files:

e.g. 

| manifest file  | registry                                                |
|:---------------|:--------------------------------------------------------|
| `flake.nix`    | [flakehub](https://flakehub.com/flakes)                 |
| `package.json` | [npm](https://www.npmjs.com/)                           |
| `go.mod`       | [pkg.go.dev](https://pkg.go.dev/about#adding-a-package) |

You cannot manually publish a project from your terminal. Only Github Actions has the keys to package registries.
