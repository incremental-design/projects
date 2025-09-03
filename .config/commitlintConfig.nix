# see: https://www.conventionalcommits.org/en/v1.0.0/#specification
# ___     ___     ________    ___           ___     ______________ _______
# \   \   \   \  /   ___  '. \   \    __   |   |   |_____    ____/  ___   \
#  \   \   \   \ \  \    \  \ \   \  |  \  |   |        /   /   /  /   /  /
#   \   \___\   \ \  \    \  \ \   \ |   \ |   |       /   /   /  /   /  /
#    \    ____   \ \  \    \  \ \   \'    \'   |      /   /   /  /   /  /
#     \   \   \   \ \  \    \  \ \     | \     |     /   /   /  /   /  /
#      \   \   \   \ \  '.___'  \ \    |  \    |    /   /   /  /___/  /
#       \___\   \___\ '.________/  \___|   \___|   /___/    \________/
#
#         _______     _______     ___      ___   ___     ___  ____________ _____________
#       .'  __   |  .' ___   \   /   |    /   | |    \  |   \ \____    ____\ ____    ____\
#      /  /   '--' /  /   /  /  /    |  /     | |     \ |    \     \   \        \   \
#     /  /        /  /   /  /  /     |/  /,   | |      \|     \     \   \        \   \
#    /  /        /  /   /  /  /   /\    / |   | |   |\    /\   \     \   \        \   \
#   /  /   __   /  /   /  /  /   /  \__/  |   | |   | \__/  \   \     \   \        \   \
#  /  '___/  / /   '--'  /  /   /         |   | |   |        \   \ .---'   '---.    \   \
#  \_______.'  \_______.'  /___/          |___| |___|         \___\ \___________\    \___\
#
#
# What are you going to be doing with your life in two years? Five years? A decade?
# You probably don't know for sure. Sit with that uncertainty for a second. That is
# exactly how the person maintaining your code in the future will feel when they have
# to fix a bug you introduced. They won't know why you wrote the code you did, unless
# you tell them. When they exclaim "Why would anyone ever write this? What on earth
# was this person thinking?!", your commit message should give them a compelling answer.
#
# We use a simplified version of conventional commit
#
#                                              -,
# chore: inject global logger into main actor   |- header
# --^--  --^---------------------------------  -'
# type   header message
#                                              -,
# * Mock the logger in tests                    |
# * Verify log calls                            |- body
# * Eliminate file I/O during test runs         |
#                                              -'
#
# Think of each commit as a step in a tutorial.
#
# When I review your PRs, I will step through each of your commits.
#
# Your commit message should read like an instruction, and it should describe what
# your code does. I should be able to follow your instruction, and write a different
# implementation of the same functionality
#
# When you submit a PR, Each commit must be independently buildable and testable.
#
{pkgs ? import <nixpkgs> {}}:
(pkgs.formats.yaml {}).generate "conf.yml" {
  version = "v0.10.1";
  formatter = "default";
  rules = [
    "header-min-length"
    "header-max-length"
    "body-max-line-length"
    "footer-max-line-length"
    "type-enum"
  ];
  severity = {
    default = "error";
  };
  settings = {
    header-min-length = {
      argument = 10;
    };
    header-max-length = {
      argument = 50;
    };
    body-max-line-length = {
      argument = 72;
    };
    footer-max-line-length = {
      argument = 72;
    };
    type-enum = {
      argument = [
        # we only use 3 of the 11 available commit types. Why?
        # Because code shouldn't be complicated. Asking a programmer
        # to choose between 11 different commit types forces them to
        # perform 50 subjective comparisons every. time. they. commit.
        #
        # Asking a programmer to choose between just 3 commit
        # types makes them perform just 3 subjective comparisons
        # for each commit. Here's when you should use each type
        # of commit:
        #
        #                         your commit
        #          ,------------------|------------------,
        #          |                  |                  |
        #         feat               fix               chore
        #   -------^--------   -------^--------   -------^--------
        #   exports something  fixes existing     literally everything
        #   new. Adds to       public API.        else
        #   public API.
        #
        #   Bumps major or     Bumps patch
        #   minor version      version number
        #   number

        "feat" # feat: New features that add functionality.

        # "docs"      # Documentation only changes.
        # We do not use this, because you should update
        # documentation in the same commit that you update
        # code

        "chore" # Regular maintenance tasks, no production code change.

        # "style"     # Changes that do not affect the meaning of the code
        # (white-space, formatting, etc). We do not use this
        # because you should NOT be changing the formatters.
        #
        # Doing so is a pet peeve of mine. Formatting changes
        # shadow the git blame. They make it harder to understand
        # who made a breaking change to the code, because a
        # formatting change isn't a breaking change.

        # "refactor"  # Code changes that neither fix a bug nor add a feature.
        # "perf"      # Changes that improve performance.
        # "test"      # Adding missing tests or correcting existing tests.
        # "build"     # Changes that affect the build system or external dependencies.
        # "ci"        # Changes to CI configuration files and scripts.
        #
        # These are all just other names for chores

        "fix" # fix: Bug fixes and corrections. Try to avoid this.
        # If you submit "fix" in a PR, I'm probably going to
        # ask you to fixup your branch so that you don't need
        # to commit the fix
        #
        # fix should only be used if we need to patch a production
        # bug

        #"revert"     # Reverts a previous commit
        # This is just another name for fix. Don't commit bugs in
        # the first place and you'll have nothing to revert
      ];
    };
  };
}
