{ pkgs, lua }:
{
  version = pkgs.writeShellScriptBin "version" ''
    set -euo pipefail
    ${lua}/bin/lua -v
  '';

  test = pkgs.writeShellScriptBin "test" ''
    set -euo pipefail
    if [ -d "spec" ] || [ -d "test" ] || [ -d "tests" ]; then
      echo "Running tests with busted..."
      busted "$@"
    else
      echo "No test directory found (spec/, test/, or tests/)"
      exit 1
    fi
  '';

  build = pkgs.writeShellScriptBin "build" ''
    set -euo pipefail

    # Default values
    OUTPUT_NAME="$(basename "$PWD").pdx"
    SOURCE_DIR="source"
    STRIP=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
      case $1 in
        -o|--output)
          OUTPUT_NAME="$2"
          shift 2
          ;;
        -d|--dir)
          SOURCE_DIR="$2"
          shift 2
          ;;
        -s|--strip)
          STRIP="-s"
          shift
          ;;
        -h|--help)
          echo "Usage: build [-o|--output NAME] [-d|--dir DIRECTORY] [-s|--strip]"
          echo "  -o, --output NAME        Output .pdx name (default: <project-dir>.pdx)"
          echo "  -d, --dir DIRECTORY      Source directory (default: source)"
          echo "  -s, --strip              Strip debug info for release builds"
          exit 0
          ;;
        *)
          echo "Unknown option: $1"
          echo "Use -h or --help for usage information"
          exit 1
          ;;
      esac
    done

    if [ ! -f "$SOURCE_DIR/main.lua" ]; then
      echo "Error: No main.lua found in $SOURCE_DIR"
      echo "This doesn't appear to be a Playdate game directory"
      exit 1
    fi

    echo "Building Playdate game: $OUTPUT_NAME"
    pdc $STRIP "$SOURCE_DIR" "$OUTPUT_NAME"
    echo "Build complete: $OUTPUT_NAME"
    echo "Run with: open $OUTPUT_NAME  (or use the Playdate Simulator)"
  '';

  coverage = pkgs.writeShellScriptBin "coverage" ''
    set -euo pipefail
    if [ -d "spec" ] || [ -d "test" ] || [ -d "tests" ]; then
      echo "Running tests with coverage..."
      busted --coverage "$@"
      luacov
      echo ""
      echo "=== Coverage Report ==="
      cat luacov.report.out
    else
      echo "No test directory found (spec/, test/, or tests/)"
      exit 1
    fi
  '';

  docs = pkgs.writeShellScriptBin "docs" ''
    set -euo pipefail
    SRC="''${1:-source}"
    if [ ! -d "$SRC" ]; then
      echo "No source directory found at $SRC"
      echo "Usage: docs [source-dir]  (default: source)"
      exit 1
    fi
    echo "Generating documentation from $SRC/ into doc/..."
    ldoc "$SRC"
    echo "Documentation written to doc/index.html"
  '';

  sim = pkgs.writeShellScriptBin "sim" ''
    set -euo pipefail
    PDX="''${1:-game.pdx}"
    if [ ! -d "$PDX" ]; then
      echo "Error: $PDX not found. Run 'build' first."
      exit 1
    fi
    exec PlaydateSimulator "$PDX"
  '';

  watch = pkgs.writeShellScriptBin "watch" ''
    set -euo pipefail
    echo "Watching Lua files — re-running tests on change (Ctrl-C to stop)..."
    exec watchexec --exts lua -- busted
  '';

  watch-sim = pkgs.writeShellScriptBin "watch-sim" ''
    set -euo pipefail
    DIR="''${1:-source}"
    OUTPUT="''${2:-game.pdx}"

    echo "Watching $DIR for changes — rebuilding and restarting Simulator (Ctrl-C to stop)..."
    exec watchexec --exts lua,png,jpg,wav,mp3,json --restart -- sh -c "pdc '$DIR' '$OUTPUT' && PlaydateSimulator '$OUTPUT'"
  '';

  clean = pkgs.writeShellScriptBin "clean" ''
    set -euo pipefail

    echo "Cleaning build artifacts..."

    # Remove .pdx build output directories
    find . -maxdepth 1 -name "*.pdx" -type d -exec rm -rfv {} +

    # Remove .pdx.zip archives
    if ls *.pdx.zip 1> /dev/null 2>&1; then
      rm -v *.pdx.zip
    fi

    # Remove luac compiled files
    find . -name "luac.out" -type f -delete -print

    # Remove common Lua artifact patterns
    find . -name "*.src.rock" -type f -delete
    find . -name "lua_modules" -type d -exec rm -rf {} + 2>/dev/null || true
    find . -name ".luarocks" -type d -exec rm -rf {} + 2>/dev/null || true

    echo "Clean complete"
  '';
}
