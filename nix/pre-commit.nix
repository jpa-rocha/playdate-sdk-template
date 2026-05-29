{
  stylua,
  luacheck,
  selene,
  nixfmt-rfc-style,
  trufflehog,
  typos,
  ...
}:
{
  src = ./.;
  excludes = [
    "flake.lock"
    "^\.playdate-corelibs/"
  ];

  hooks = {
    check-yaml.enable = true;
    convco.enable = true;
    deadnix.enable = true;
    ripsecrets.enable = true;
    shellcheck.enable = true;

    nixfmt-rfc-style = {
      enable = true;
      package = nixfmt-rfc-style;
    };

    trufflehog = {
      enable = true;
      package = trufflehog;
    };

    stylua = {
      enable = true;
      package = stylua;
      entry = "stylua --check";
      files = "\\.lua$";
    };

    luacheck = {
      enable = true;
      package = luacheck;
      entry = "luacheck";
      files = "\\.lua$";
    };

    selene = {
      enable = true;
      package = selene;
      entry = "selene";
      files = "\\.lua$";
    };

    typos = {
      enable = true;
      package = typos;
    };
  };
}
