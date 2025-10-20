# lint the commit message of the current commit
#
# HOW TO USE:
#
# To build this package, run:
#   cd .config && nix-build commitlint.nix
#
# After building, you will see a result/ folder with this structure:
#
#  result/
#  ├── bin/
#  │   └── commitlint  (symlink to wrapper script)
#  └── etc/
#      └── conf.yml  (symlink to config)
#
# You can run the commitlint command with:
#   ./result/bin/commitlint --help
#
{pkgs ? import <nixpkgs> {}}: let
  config = import ./commitlintConfig.nix {inherit pkgs;};
  bin = pkgs.buildGoModule {
    # see https://nixos.org/manual/nixpkgs/stable/#ssec-language-go

    pname = "commitlint-bin";
    version = "0.10.1";

    # see https://github.com/conventionalcommit/commitlint/blob/bf3d490c7a9b64db7694eb16f02ce86c711aa3d7/.goreleaser.yml#L13C5-L13C258
    ldflags = [
      "-X github.com/conventionalcommit/commitlint/internal.version=v0.10.1"
      "-X github.com/conventionalcommit/commitlint/internal.commit=e9a606ce7074ac884ea091765be1651be18356d4"
      "-X github.com/conventionalcommit/commitlint/internal.buildTime=21082025"
    ];

    src = pkgs.fetchFromGitHub {
      owner = "conventionalcommit";
      repo = "commitlint";
      rev = "e9a606ce7074ac884ea091765be1651be18356d4";
      hash = "sha256-OJCK6GEfs/pcorIcKjylBhdMt+lAzsBgBVUmdLfcJR0=";
    };

    vendorHash = "sha256-4fV75e1Wqxsib0g31+scwM4DYuOOrHpRgavCOGurjT8=";
  };

  # Wrapper script to run commitlint on the current commit, with config
  wrapperScript = pkgs.writeShellApplication {
    name = "lintCommit";
    runtimeInputs = [
      pkgs.git
      bin
    ];
    runtimeEnv = {
      COMMITLINT_CONFIG = "${config}";
    };
    text = ''

      MSG_FILE=''${*:-}

      if [ ! -f "$MSG_FILE" ]; then
        # Use HEAD for the current commit if no message file is provided
        git log -1 --pretty=%B HEAD > commit_message.txt
        MSG_FILE=commit_message.txt
      fi

      echo "$MSG_FILE"

      commitlint lint "$MSG_FILE"
    '';
  };
in
  pkgs.stdenv.mkDerivation {
    name = "lintCommit";

    # pkgs.stdenv.mkDerivation can copy files in from any folder. In this case,
    # we have no files to copy in, because everything we want to use is already
    # in the nix store
    #
    # When you define src, Nix copies the entire directory into the Nix store:
    #
    #  ,-----------------,                             ,-----------------,
    #  | Source Directory |     Nix Build Process      | Nix Store Copy  |
    #  | (mutable)        | -------------------------> | (immutable)     |
    #  |                  |                            |                 |
    #  | - Can change     |                            | - Never changes |
    #  | - Not tracked    |                            | - Hash-addressed|
    #  | - Local only     |                            | - Distributable |
    #  '-----------------'                             '-----------------'
    #
    # WHY? This guarantees reproducibility and purity:
    # 1. Prevents build-time changes to source affecting the result
    # 2. Ensures identical inputs always produce identical outputs
    # 3. Allows Nix to verify content with cryptographic hashes
    # 4. Enables distribution and sharing of source code
    # 5. Makes builds hermetic (isolated from the environment)
    src = null;

    # pkgs.stdenv.mkDerivation runs autotools by default. autotools has many phases
    # we don't actually need all of these phases when we wrap custom build scripts
    # we disable all the phase swe don't need
    phases = [
      # "unpackPhase"      # Extracts source archives (tar, zip, etc.) into the build directory
      # Default: Unpacks $src or sources listed in $srcs

      # "patchPhase"       # Applies patches listed in $patches to the source code
      # Default: Applies each patch in $patches with patch -p1

      # "preConfigurePhase" # Runs before configuration, for pre-config preparations
      # Default: Runs any preConfigure hooks and $preConfigurePhase

      # "configurePhase"   # Runs ./configure or equivalent (cmake, meson, etc.)
      # Default: Runs ./configure --prefix=$out with other standard flags

      # "preBuildPhase"    # Runs before building, for last-minute setup
      # Default: Runs any preBuild hooks and $preBuildPhase

      "buildPhase" # Normally compiles source code, in our case creates symlinks
      # Default: Runs 'make' or equivalent build command

      # "checkPhase"       # Runs the package's test suite to verify it works
      # Default: Runs 'make check' if doCheck = true

      # "preInstallPhase"  # Runs before installation
      # Default: Runs any preInstall hooks and $preInstallPhase

      # "installPhase"     # Copies built files to $out, creates directories as needed
      # Default: Runs 'make install' or equivalent

      # "fixupPhase"       # Post-processing: fixes shebangs, strips binaries, etc.
      # Default: Runs numerous fixup steps like patchShebangs

      # "installCheckPhase" # Verifies the installation worked correctly
      # Default: Runs 'make installcheck' if doInstallCheck = true

      # "distPhase"        # Creates source distributions (tarballs, etc.)
      # Default: Runs 'make dist' if doDist = true
    ];

    buildPhase = ''
      # Create directories
      mkdir -p $out/bin $out/etc

      # Create symlinks instead of copying to save on disk space
      ln -s ${wrapperScript}/bin/lintCommit $out/bin/lintCommit
      ln -s ${config} $out/etc/conf.yml
    '';
  }
# COMPOSING DERIVATIONS
#
# Nix packages are built as "derivations" - the fundamental building blocks in the Nix ecosystem.
# Each derivation creates an isolated directory structure in the Nix store that contains directories
# with names similar to those in a traditional Linux system, such as:
#
#  _______________________
# | Typical Nix Derivation |
# |                        |
# | bin/     → Executables |
# | etc/     → Config files|
# | lib/     → Libraries   |
# | include/ → Headers     |
# | share/   → Data files  |
# |________________________|
#
# see: https://tldp.org/LDP/Linux-Filesystem-Hierarchy/html/
#
# When you build a derivation, Nix creates this structure at a unique path in the Nix store
# (e.g., /nix/store/<hash>-<name>). This isolation ensures reproducibility and prevents
# conflicts between packages, unlike traditional Linux systems where packages install
# files into shared system directories.
#
# However, working with isolated components can be challenging. What if you need to
# combine multiple derivations into a cohesive whole? This is where composition comes in.
#
# Nix provides several mechanisms for composing derivations:
#
#  ,-----------------,      ,-----------------,
#  | Derivation A    |      | Derivation B    |
#  | /bin/tool-a     |      | /etc/tool-b.conf|
#  '-----------------'      '-----------------'
#           |                        |
#           |                        |
#           v                        v
#       ,----------------------------,
#       | Combined Derivation        |
#       | /bin/tool-a                |
#       | /etc/tool-b.conf           |
#       '----------------------------'
#
# Our commitlint example demonstrates this composition pattern:
#
#  ______________________       _______________________
# | commitlint-bin       |     | YAML Configuration    |
# |                      |     |                       |
# | /bin/commitlint  ◀---|-----┐                       |
# |______________________|     |                       |
#                              | /conf.yml             |
#                              |_______________________|
#            |                           |
#            |                           |
#            v                           v
#  ______________________       _______________________
# | Wrapper Script       |     | Config Directory      |
# |                      |     |                       |
# | /bin/commitlint      |     | /etc/commitlint-      |
# |______________________|     |     config.yml        |
#            |                 |_______________________|
#            |                           |
#            v                           v
#  _________________________________________
# | Final Package (stdenv.mkDerivation)     |
# |                                         |
# | /bin/commitlint → Wrapper Script        |
# |   that knows where to find:             |
# |   1. The actual binary                  |
# |   2. The configuration file             |
# |                                         |
# | /etc/commitlint-config.yml → Config file|
# |_________________________________________|
#
# The key components in our example are:
#
# 1. Building the Go binary (bin)
#    - Uses buildGoModule to compile the commitlint tool
#    - Creates a derivation with just the binary
#
# 2. Generating the YAML config file (config)
#    - Uses yamlFormatter.generate to create a structured config
#    - Results in a file, not a complete derivation structure
#
# 3. Creating a wrapper script that:
#    - Knows the exact paths to both the binary and config
#    - Passes the right arguments to make them work together
#
# 4. Organizing the config file in a standard location:
#    - Puts the config in /etc/ following filesystem conventions
#    - Makes it discoverable and accessible
#
# 5. Combining everything with stdenv.mkDerivation:
#    - Creates the directory structure we need
#    - Uses symlinks to reference the actual files
#    - Symlinks save disk space by avoiding file duplication

