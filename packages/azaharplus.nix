{ pkgs, ... }:

let
  version = "2125.1-A";
  src = pkgs.fetchzip {
    url = "https://github.com/AzaharPlus/AzaharPlus/releases/download/AZAHAR_PLUS_2125_1_A/azaharplus-${version}-linux.zip";
    hash = "sha256-SywHiIBR2ocK7O7v+/H8YYYrmXIZveE9Bjh8/gMmaDE=";
  };
  appimage = "${src}/azahar.AppImage";
in
pkgs.appimageTools.wrapType2 {
  pname = "azaharplus";
  inherit version;
  src = appimage;

  extraInstallCommands =
    let
      appimageContents = pkgs.appimageTools.extract {
        pname = "azaharplus";
        inherit version;
        src = appimage;
      };
    in
    ''
      install -Dm444 ${appimageContents}/azahar.desktop $out/share/applications/org.azahar_emu.Azahar.desktop
      substituteInPlace $out/share/applications/org.azahar_emu.Azahar.desktop \
        --replace-warn 'Exec=AppRun' 'Exec=azaharplus'
    '';
}
