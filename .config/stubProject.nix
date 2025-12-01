# PROJECT STUB GENERATORS
#
# This flake builds language-specific project stub generators using projectConfig script:
#
# Structure:
# projects/
#   |-- flake.nix                  <- defines stubProject function
#   :
#   |
#   '-- .config/
#       |-- nix/
#       |   |
#       |   '-- projectConfig.nix  <- contains script that stubs project files
#       |
#       |-- go/
#       |   |
#       |   '-- projectConfig.nix
#       |
#       '-- typescript/
#           |
#           '-- projectConfig.nix
#
#
# Generated stub commands:
# • project-stub-nix        <- creates Nix projects
# • project-stub-go         <- creates Go projects
# • project-stub-typescript <- creates TypeScript projects
#
# Usage example:
#   $ project-stub-nix
#   enter project name
#   > my-awesome-project
#
#   Creates directory with:
#   my-awesome-project/
#   |-- .gitignore      <- whitelists all of the following
#   |                      directory contents
#   |-- README.md
#   |-- CONTRIBUTE.md
#   |-- .envrc          <- generated to use correct devShell
#   '-- other files...  <- language-specific templates
#
#
#
{
  pkgs ? import <nixpkgs> {},
  stubProjectConfigs ? (import ./importFromLanguageFolder.nix {inherit pkgs;}).importStubProject,
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
        elif [ -e "$name" ]; then
          echo "$name already exists" >&2
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

        # update the root dir gitignore
        if [ -f .gitignore ]; then
        echo "!$name">>.gitignore
        echo "!$name/**">>.gitignore
        fi

        # locate the flake.nix at the root of the monorepo
        FLAKE_DIR="../"

        seekToRoot(){
          local parent
          parent=$(dirname "$(realpath "$*")")

          if [ -d .git ]; then
            return
          else
            FLAKE_DIR="$FLAKE_DIR../"
            seekToRoot "$parent"
          fi
        }

        seekToRoot "$(pwd)"

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
        * DO make diagrams. A diagram can help yoru reader organize information in ways that words alone can't.
            * Do not put more than 50 nodes and edges into a single diagram. It will turn into an indecipherable spaghetti-string mess. Keep diagrams simple.
        -->
        EOF

        cat <<-EOF > "$name/.envrc"
        use flake "$FLAKE_DIR#${stubProject.devShellName}"
        EOF

        # run the stubProject command, pass in the $name of the project and the $FLAKE_DIR
        stubProject "$name" "$FLAKE_DIR"

        cat <<-'EOF' >"$name/.gitignore"
        # ignore all
        *

        # and then whitelist what you want to track
        EOF

        # Whitelist files
        while read -r filename; do
            echo "!$filename" >> "$name/.gitignore"
        done < <(fd --type f --max-depth 1 . "$name" --no-ignore --hidden --exec basename {} \;)

        # Whitelist directories and their contents
        while read -r dirname; do
            echo "!$dirname" >> "$name/.gitignore"
            echo "!$dirname/**" >> "$name/.gitignore"
        done < <(fd --type d --max-depth 1 . "$name" --no-ignore --hidden --exec basename {} \;)

      '';
    };
  stubProjects =
    builtins.map (projectConfig: wrapStubProject projectConfig pkgs)
    validStubProjectConfigs;
in
  stubProjects
