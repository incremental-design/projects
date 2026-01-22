{
  pkgs ? import <nixpkgs> {},
  from ? "./.",
  # e.g. set to
  # name: (builtins.match "language-" name) != null
  # to match on dirents that contain "language-"
  matchDirentName ? name: true,
  # e.g. set to
  # type: (builtins.match "directory" type) != null
  # to match on dirents that are directories
  matchDirentType ? type: true,
}: let
  dirents =
    pkgs.lib.mapAttrsToList
    (name: value: {
      name = name;
      type = value;
    })
    (builtins.readDir from);
  matchingDirents =
    builtins.filter (
      dirent:
        matchDirentName dirent.name && matchDirentType dirent.type
    )
    dirents;
in
  matchingDirents
