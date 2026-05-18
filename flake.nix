{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nix-filter.url = "github:numtide/nix-filter";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    playdate-sdk.url = "github:RegularTetragon/playdate-sdk-flake";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    { self, ... }@inputs:
    inputs.flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = inputs.nixpkgs.legacyPackages.${system};

        playdate-sdk = inputs.playdate-sdk.packages.${system}.default;

        lua = pkgs.luajit;
        lua-language-server = pkgs.lua-language-server;
        lux-cli = pkgs.lux-cli;
        luacheck = pkgs.luajitPackages.luacheck;
        busted = pkgs.luajitPackages.busted;
        stylua = pkgs.stylua;

        luacov = pkgs.luajitPackages.luacov;
        lux-lua = pkgs.luajitPackages.lux-lua;
        selene = pkgs.selene;
        ldoc = pkgs.luajitPackages.ldoc;
        watchexec = pkgs.watchexec;
        git-cliff = pkgs.git-cliff;
        typos = pkgs.typos;
        semgrep = pkgs.semgrep;
        osv-scanner = pkgs.osv-scanner;

        scripts = import ./nix/scripts.nix {
          inherit pkgs lua;
        };

        treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs ./nix/treefmt.nix;

        # What CI / checks use (not the dev shell)
        preCommit = import ./nix/pre-commit.nix {
          inherit
            stylua
            selene
            typos
            ;
          luacheck = pkgs.luajitPackages.luacheck;
          nixfmt-rfc-style = pkgs.nixfmt-rfc-style;
          trufflehog = pkgs.trufflehog;
        };
      in
      {
        devShells = import ./nix/devshells.nix {
          inherit
            self
            system
            playdate-sdk
            lua
            lua-language-server
            lux-cli
            lux-lua
            luacheck
            busted
            stylua
            selene
            ldoc
            scripts
            luacov
            watchexec
            git-cliff
            semgrep
            osv-scanner
            ;

          inherit (pkgs)
            age
            git
            mkShell
            pkg-config
            ;
        };

        checks = {
          formatting = treefmtEval.config.build.check inputs.self;

          pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run preCommit;
        };

        formatter = treefmtEval.config.build.wrapper;
      }
    );
}
