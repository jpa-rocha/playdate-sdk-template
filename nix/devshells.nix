{
  age,
  git,
  mkShell,
  pkg-config,
  scripts,
  self,
  system,
  playdate-sdk,
  lua,
  lua-language-server,
  lux-cli,
  lux-lua,
  luacheck,
  busted,
  stylua,
  selene,
  ldoc,
  luacov,
  watchexec,
  git-cliff,
  semgrep,
  osv-scanner,
  ...
}:
{
  default = mkShell {
    packages = [
      age
      git
      playdate-sdk
      lua
      lua-language-server
      lux-cli
      luacheck
      busted
      stylua
      selene
      ldoc
      luacov
      watchexec
      git-cliff
      semgrep
      osv-scanner
      scripts.version
      scripts.test
      scripts.build
      scripts.clean
      scripts.sim
      scripts.coverage
      scripts.docs
      scripts.watch
      scripts.watch-sim
    ];

    # lux-lua is a C library; buildInputs makes its pkg-config metadata available
    buildInputs = [ lux-lua ];

    # pkg-config must be a native build tool so it can locate buildInputs
    nativeBuildInputs = [ pkg-config ];

    shellHook = ''
      ${self.checks.${system}.pre-commit-check.shellHook}
      export PLAYDATE_SDK_PATH="${playdate-sdk}"
      export SDL_AUDIODRIVER=pulseaudio
      ln -sfn "$PLAYDATE_SDK_PATH/CoreLibs" .playdate-corelibs
    '';
  };
}
