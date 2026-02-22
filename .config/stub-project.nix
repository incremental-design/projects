{
  pkgs ? import <nixpkgs> {},
  stubProjectConfigs ?
    map (stubProjectNixDirent:
      (import ./${stubProjectNixDirent.name} {inherit pkgs;})
      // {
        devShellName = builtins.head (builtins.match "^stub-project-(.*).nix$" stubProjectNixDirent.name);
      })
    (
      import ./match-dirent.nix {
        pkgs = pkgs;
        from = ./.;
        matchDirentName = name: (builtins.match "^stub-project-.*\.nix$" name) != null;
        matchDirentType = type: (builtins.match "^regular$" type) != null;
      }
    ),
}: let
  validStubProjectConfigs = let
    configs =
      builtins.map (
        projectConfig:
          if builtins.isAttrs projectConfig && builtins.hasAttr "devShellName" projectConfig
          then projectConfig
          else builtins.throw "invalid projectConfig ${projectConfig}"
      )
      stubProjectConfigs;

    # Check for duplicate devShellName values
    names = builtins.map (config: config.devShellName) configs;
    uniqueNames = pkgs.lib.unique names;

    # Throw error if there are duplicates
    c =
      if builtins.length names != builtins.length uniqueNames
      then builtins.throw "Duplicate dev shell name values found: ${builtins.toJSON names}"
      else configs;
  in
    c;
  wrapStubProject = stubProject: pkgs:
    pkgs.writeShellApplication {
      name = "project-stub-" + stubProject.devShellName; # e.g. project-stub-nix project-stub-go
      meta = {
        description = "Stub a " + stubProject.devShellName + " project";
      };
      runtimeInputs = [
        pkgs.coreutils
        pkgs.fd
        pkgs.gnugrep
        stubProject
      ];
      text = ''
        if ! [ -e ".git" ]; then
            echo "please run this script from the root of the monorepo" >&2
            exit 1
        fi

        echo "enter project name" >&2
        read -r name

        # validate project name
        if [[ -z "$name" ]]; then
          echo "Error: Project name cannot be empty" >&2
          exit 1
        elif [[ ! "$name" =~ ^[a-z][a-z\/-]*[a-z]$ ]]; then
          echo "Error: Project name '$name' must be at least two characters long. it must start and end with a lowercase alphabetical character. It can only contain alphabetical characters and -" >&2
          echo "Valid examples: my-project, hello-world, abc, a-b-c, my/project, my/project/a-b-c" >&2
          exit 1
        fi

        if ! mkdir -p "$name"; then
        echo "❌ could not create directory $name" >&2
        exit 1
        fi

        # get path components out of name
        IFS="/" read -ra path_components <<< "$name"

        # update the root dir gitignore
        if [ -f .gitignore ]; then
          echo "!''${path_components[0]}">>.gitignore
        echo "!''${path_components[0]}/**">>.gitignore
        fi

        FLAKE_DIR=""

        for (( i=0; i<''${#path_components[@]}; i++ )); do
            FLAKE_DIR="''${FLAKE_DIR}../"
        done

        # add default readme and contribute
        cat <<-EOF > "$name/README.md"
        # $name
        <!--
        Add a banner image and badges
        see: https://towardsdatascience.com/how-to-write-an-awesome-readme-68bf4be91f8b
        For bonus points, make the banner animated with html, css and svg
        see: https://github.com/sindresorhus/css-in-readme-like-wat
        -->
        <!--
        Start with WHY:
            * What is the problem, and why does it exist?
            * Why does the problem need to be solved?
            * Why is your code the best way to solve the problem?
                    * Where does the problem originate?
                    * how does your code fix the problem at its origin?
                * What is the alternative to your code?
                * Compared to the alternative
                    * How much more time and money does your code save?
                    * How much more technical debt does your code avoid?
                    * How does your code improve the developer experience?
        -->
        <!--
        List any codebases, websites, apps, platforms or other products that use your code
          -->
        <!--
        link to your reader to your repository's bug page, and let them know if you're open to contributions
        -->
        ## How to use $name:
        <!--
        Link to a webpage, web shell (e.g. runkit), or downloadable executable that demonstrates the project.
                * note that when the reader is modifying the code, they will compare their modified version to the demo to see if their changes worked as they expected them to. Your demo is their reference
        -->
        ### Installation:
        <!--Explain how to import the modules of the project into the reader's codebase, install the containers of the project in the reader's cluster, or flash the binary of the project onto the reader's hardware-->
        ### API Methods | Modules:
        <!--
        List the methods or modules your project provides.
        -->
        ## How Project Name works:
        <!--
        Explain how execution works. What is the entry point for your code? Which files correspond to which functionality? What is the lifecycle of your project? Are there any singletons, side effects or shared state among instances of your project? Take extra care to explain design decisions. After all, you wrote an ENTIRE codebase around your opinions. Make sure that the people using it understand them.
        -->
        ## Roadmap:
        <!--
        List the releases that you have added to each project, and any future releases you would like to do. If there is a date for future release, put it here. If not, let people know that there is no defined timeframe for future releases.
        -->
        ## [Contribute](./CONTRIBUTE.md)
        EOF

        cat <<-EOF > "$name/CONTRIBUTE.md"
        # Contribute to $name:
        <!--
        What are the prerequisites for contributing to the code?
            * provide users with containerized development environments, virtual machines, or, if developing for an embedded system, a pre-built OS image. Don't make them set up an environment from scratch.
        -->
        ## Develop:
        <!--
        Tell your reader how to run the code in the development environment
        -->
        ### Repository Structure:
        <!--
        List each file, and what it does.
            * Identify whether you are open to pull requests for a specific file or not.
        -->
        | File or Folder | What does it do? | When should you modify it? |
        | :------------- | :--------------- | :------------------------- |
        |                |                  |                            |
        ## Test:
        <!--
        When the reader runs the code, what are the expected inputs and outputs?
        How can the reader tell if the code is malfunctioning?
        -->
        ## Document:
        <!--
        How should the reader document changes and additions to the code?
        -->
        ## Deploy:
        <!--
        How is the code deployed? When the reader submits a pull request, how is the code merged into main and converted into a package?
        -->
        <!--
        Additional tip: SHOW, don't TELL
        * DON'T try to sell your reader on using your code. Don't spend words on clever analogies or context. That material is great for a blog post or video, but bad for the documentation included in repository. Your reader wants to run the code, not read about it. Help your reader get to 'hello world' as fast as possible.
        * DO make diagrams. A diagram can help your reader organize information in ways that words alone can't.
            * Do not put more than 50 nodes and edges into a single diagram. It will turn into an indecipherable spaghetti-string mess. Keep diagrams simple.
        -->
        EOF

        # run the stubProject command, pass in the $name of the project and the $FLAKE_DIR
        stubProject "$name" "$FLAKE_DIR"

        for (( i=0; i<''${#path_components[@]}; i++)); do

            IFS="/"
            CURR_PC="''${path_components[*]:0:''$((i+1))}"

            if [ ! -s "''${CURR_PC}/.gitignore" ]; then
                cat <<-'EOF' >"''${CURR_PC}/.gitignore"
                # ignore all
                *

                # and then whitelist what you want to track
        EOF
            fi

            # Whitelist files
            while read -r filename; do
                if ! grep -Fxq "!$filename" "''${CURR_PC}/.gitignore"; then
                    echo "!$filename" >> "''${CURR_PC}/.gitignore"
                fi
            done < <(fd --type f --max-depth 1 . "$CURR_PC" --no-ignore --hidden --exec basename {} \;)

            # Whitelist directories and their contents
            while read -r dirname; do
                if ! grep -Fxq "!$dirname" "''${CURR_PC}/.gitignore"; then
                    echo "!$dirname" >> "''${CURR_PC}/.gitignore"
                fi
                if ! grep -Fxq "!$dirname/**" "''${CURR_PC}/.gitignore"; then
                    echo "!$dirname/**" >> "''${CURR_PC}/.gitignore"
                fi
            done < <(fd --type d --max-depth 1 . "$CURR_PC" --no-ignore --hidden --exec basename {} \;)
        done



      '';
    };
  stubProjects =
    builtins.map (projectConfig: wrapStubProject projectConfig pkgs)
    validStubProjectConfigs;
in
  stubProjects
#
# PROJECT TEMPLATES
#
# This nix expression builds a script that stubs projects
#
#
# each stubProject script creates the project manifests
# you need to work in a project.
#
# projects/
#   |-- flake.nix <------.
#   :                    |
#   |                 imports
#   '-- .config/         |
#       |                |
#       |- stub-project.nix <-------------------------------------,
#       |                                                         |
#       |                                                      imports
#       |                                                 -,      |
#       |- stub-project-nix_v2.33.1.nix                    |      |
#       |                                                  |      |
#       |- stub-project-go_v1.26.0.nix                     |      |
#       |                                                  +------'
#       |- stub-project-deno_v2.6.9.nix                    |
#       |                                                  |
#       |- stub-project-<tool>_v<MAJOR.MINOR.PATCH>.nix    |
#       |                                                 -'
#       :
#
#
# the root flake provides one project-stub-* command
# for each <tool>_v<MAJOR.MINOR.PATCH>
# i.e.
#
# project-stub-nix_v2.33.1 --- creates ---> nix project
#
# project-stub-go_v1.26.0  --- creates ---> go project
#
# project-stub-deno_v2.6.9 --- creates ---> deno project
#
# each project-stub-* command updates the
# monorepo as follows:
#
#  projects/
#   |
#   |- .config/
#   |
#   |- .github/
#   |
#   |- .envrc
#   |
#   |- .gitignore           <-- update .gitignore to
#   |                           whitelist name-of-project
#   |- flake.lock
#   |
#   |- flake.nix
#   |
#   |- LICENSE
#   |
#   :
#   |
#   '- name-of-project/     <-- create new project folder
#       |
#       |- README.md        <-- template for a README
#       |
#       |- CONTRIBUTE.md    <-- template for a CONTRIBUTE
#       |
#       '- ...              <-- any project-specific manifest files (e.g. deno.json, go.mod, flake.nix)
#
# WHY PROJECT TEMPLATES
#
# Project templates CONFIGURE a language's tooling. Tooling
# is the catch-22 of learning a new language: you have to know
# the language to configure the tools, but you can't learn
# the language without first setting up the tools! When you
# start with a template, you can skip the weeks of trial-and-error
# that you would otherwise need to get started, because I stumbled
# through it for you.
#
# Each project template sets up the package managers, linters,
# formatters, build and test tools needed to get to "hello world"
#
# You can change the project template to configure the language
# tooling to your project's specific needs.
#
# HOW TO SET UP A PROJECT TEMPLATE
#
# Each language-specific folder contains a stubProject.nix. This
# nix file must contain the following nix expression:
#
# {pkgs ? import <nixpkgs> {}}:
# pkgs.writeShellApplication {
#   name = "stubProject";                           <- name of the executable.
#                                                      it MUST be named "stubProject"
#   runtimeInputs = [
#     ...                                           <- any packages needed to create
#                                                      and modify the project files
#   ];
#   text = ''
#     PROJECT_DIR="$1"                              <- relative path from root of repository
#                                                      to project (will usually be <name of project>)
#     FLAKE_DIR="$2"                                <- relative path from project dir back to
#                                                      root of repository (will usually be ../)
#
#     cat <<-EOT > "$PROJECT_DIR"/<name-of-file>    <- logic to write project template files
#     ...
#     EOT
#   '';
# }
#
# This nix expression builds a script that is executed
# inside the project template directory. It is incredibly
# poweful. It can prompt for input. It can download files
# from the web, and it can read and modify ANY file in the
# monorepo.
#
# Use this power wisely. Do NOT delete or overwrite other
# project's files.
#
# this stubProject.nix composes the script in the language-specific
# stubProject.nix. It
#
#   1. creates project folder
#   2. whitelists project folder in monorepo root
#      .gitignore
#   3. stubs README.md
#   4. stubs CONTRIBUTE.md
#   5. stubs .envrc
#   6. runs the language-specific stubProject.nix
#      which stubs other project files and folders,
#      and can modify README.md, CONTRIBUTE.md, and
#      .envrc
#   7. creates a .gitignore and adds all stubbed
#      project files to it
#

