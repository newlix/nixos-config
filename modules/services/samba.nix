{ config, pkgs, ... }:

{
  # ── Samba ──────────────────────────────────────────────────────────────────
  services.samba = {
    enable = true;
    openFirewall = true;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server role" = "standalone server";
        # macOS (AFP over SMB) compatibility
        "vfs objects"                            = "catia fruit streams_xattr";
        "fruit:aapl"                             = "yes";
        "fruit:copyfile"                         = "yes";
        "fruit:model"                            = "MacSamba";
        "fruit:metadata"                         = "stream";
        "fruit:veto_appledouble"                 = "no";
        "fruit:posix_rename"                     = "yes";
        "fruit:wipe_intentionally_left_blank_rfork" = "yes";
        "fruit:delete_empty_adfiles"             = "yes";
        "map to guest"                           = "bad user";
        "usershare allow guests"                 = "no";
        # Disable SMB1 — macOS uses SMB2/3, SMB1 is a security risk
        "server min protocol"                    = "SMB2";
        "server signing"                         = "auto";
        # Shared defaults for all shares
        "create mask"        = "0700";
        "directory mask"     = "0700";
        "ea support"         = "yes";
        "veto files"         = "/.DS_Store/.Spotlight-V100/.Trashes/.fseventsd/";
        "delete veto files"  = "yes";
      };
      data = {
        path = "/data";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "newlix";
      };
      newlix = {
        path = "/home/newlix";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "newlix";
      };
      "115" = {
        path = "/115";
        browseable = "yes";
        "read only" = "no";
        "valid users" = "newlix";
      };
    };
  };

  # Avahi: mDNS for macOS to discover Samba shares via Bonjour
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true; # Added IPv6 support
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };
}
