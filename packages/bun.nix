{ pkgs }:

let
  version = "1.3.14";
  sources = {
    "x86_64-linux" = {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-linux-x64.zip";
      hash = "sha256-lR7iruhV8IWVruxiJSJqKY0/6oOj3NZGXAnLzN9+hI8=";
    };
    "aarch64-darwin" = {
      url = "https://github.com/oven-sh/bun/releases/download/bun-v${version}/bun-darwin-aarch64.zip";
      hash = "sha256-2LliIYKK1vl6x6wKt+lYcjQa92MAHogD6CZ2UsJlJiA=";
    };
  };
  src = sources.${pkgs.stdenv.hostPlatform.system}
    or (throw "Unsupported system: ${pkgs.stdenv.hostPlatform.system}");
in
pkgs.bun.overrideAttrs (old: {
  inherit version;
  src = pkgs.fetchurl src;
})
