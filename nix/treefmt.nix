{ ... }:
{
  projectRootFile = "flake.nix";

  programs = {
    deadnix.enable = true;
    nixfmt.enable = true;
    stylua.enable = true;
  };
}
