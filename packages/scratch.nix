{ pkgs }:

let
  version = "0.10.0";
  src = pkgs.fetchurl {
    url = "https://github.com/erictli/scratch/releases/download/v${version}/Scratch_${version}_amd64.AppImage";
    hash = "sha256-vCzWIQG5V7Utp4ba9/Dr+Z+dhfoYM30irTAzTDt4T74=";
  };
in
pkgs.appimageTools.wrapType2 {
  pname = "scratch";
  inherit version src;

  extraInstallCommands =
    let
      appimageContents = pkgs.appimageTools.extract {
        pname = "scratch";
        inherit version src;
      };
    in
    ''
      # Desktop file
      install -Dm444 ${appimageContents}/Scratch.desktop $out/share/applications/scratch.desktop
      substituteInPlace $out/share/applications/scratch.desktop \
        --replace-warn 'Exec=AppRun' 'Exec=scratch'

      # Icons
      install -Dm444 ${appimageContents}/Scratch.png $out/share/icons/hicolor/256x256/apps/scratch.png
      cp -r ${appimageContents}/usr/share/icons $out/share/icons 2>/dev/null || true
    '';
}
