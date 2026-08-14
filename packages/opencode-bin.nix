# Self-packaged prebuilt OpenCode — pinned to the release that fixes the
# session-loop bug (lexicographic message-ID compare breaks after counter
# wrap; fixed upstream in 1.18.17/18, nixpkgs lags at 1.18.13).
# Interpreter is patched to store glibc via autoPatchelfHook — no nix-ld.
# Delete this file and restore plain `opencode` in home/packages.nix once
# nixpkgs ships >= 1.18.18.
{ pkgs }:

let
  version = "1.18.18";
in
pkgs.stdenv.mkDerivation {
  pname = "opencode-bin";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/anomalyco/opencode/releases/download/v${version}/opencode-linux-x64.tar.gz";
    hash = "sha256-DN3CIkGLhVNmmQWomAwM2nCI8A2iTYPWrHawHJ/bKq8=";
  };

  nativeBuildInputs = [ pkgs.autoPatchelfHook ];

  # release tarball contains the binary at the archive root (no subdirectory)
  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 opencode $out/bin/opencode
    runHook postInstall
  '';

  meta = {
    description = "OpenCode — prebuilt binary pinned ahead of nixpkgs";
    homepage = "https://opencode.ai";
    mainProgram = "opencode";
    platforms = [ "x86_64-linux" ];
  };
}
