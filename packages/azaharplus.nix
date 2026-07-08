{ pkgs, ... }:

pkgs.appimageTools.wrapType2 {
  pname = "azaharplus";
  version = "unstable-2025-07-01";

  src = pkgs.fetchurl {
    url = "https://github.com/CaptainVisc/AzaharPlus/releases/download/latest/azaharplus.AppImage";
    hash = "";
  };

  extraInstallCommands =
    let
      appimageContents = pkgs.appimageTools.extract {
        pname = "azaharplus";
        inherit version src;
      };
    in
    ''
      install -Dm444 ${appimageContents}/org.azahar_emu.Azahar.desktop $out/share/applications/org.azahar_emu.Azahar.desktop
      substituteInPlace $out/share/applications/org.azahar_emu.Azahar.desktop \
        --replace-warn 'Exec=AppRun' 'Exec=azaharplus'
    '';
}
