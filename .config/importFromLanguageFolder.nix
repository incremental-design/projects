#
# import configVscode.nix, configZed.nix, stubProject.nix, devShell.nix from language-* subfolders
#
{pkgs ? import <nixpkgs> {}}: let
  # Get all language directories
  configContents = builtins.readDir ./.;
  languageDirs =
    builtins.filter
    (name: pkgs.lib.hasPrefix "language-" name)
    (pkgs.lib.attrNames (pkgs.lib.filterAttrs (name: type: type == "directory") configContents));

  getExistingFiles = configFile:
    builtins.filter (path: builtins.pathExists path.file)
    (map (dir: {
        language = pkgs.lib.removePrefix "language-" dir;
        file = ./. + "/${dir}/${configFile}";
      })
      languageDirs);

  # Get all existing paths for each config type
  importConfigVscode = map (f: import f.file {inherit pkgs;}) (getExistingFiles "configVscode.nix");
  importConfigZed = map (f: import f.file {inherit pkgs;}) (getExistingFiles "configZed.nix");
  importStubProject = map (f: import f.file {inherit pkgs;}) (getExistingFiles "stubProject.nix");
  importDevShell = map (
    f:
      (import f.file {inherit pkgs;}) // {name = f.language;}
  ) (getExistingFiles "devShell.nix");
in {
  inherit importConfigVscode importConfigZed importStubProject importDevShell;
}
