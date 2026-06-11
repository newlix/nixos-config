{ config, pkgs, ... }:

{
  # ── Samba ──────────────────────────────────────────────────────────────────
  services.samba = {
    enable = true;
    # Do NOT open to the whole LAN/WAN. Firewall is opened only on tailscale0 below.
    openFirewall = false;
    # nmbd = NetBIOS broadcast (SMB1-era) — cannot run on the point-to-point
    # tailscale0 interface and isn't needed (macOS discovers shares via Avahi/Bonjour).
    # winbindd is unused on a standalone server with local users.
    nmbd.enable = false;
    winbindd.enable = false;
    settings = {
      global = {
        workgroup = "WORKGROUP";
        "server role" = "standalone server";
        # Exposure is controlled by the firewall below: 445/139 are opened ONLY on
        # tailscale0, so LAN/public packets to SMB are dropped by nftables even
        # though smbd listens on all interfaces. ("bind interfaces only" is not used
        # because smbd refuses to bind the point-to-point tailscale0 interface.)
        # (Incident 2026-06-11: SMB was exposed via openFirewall and hit by
        # WantToCry ransomware through the writable shares.)
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

  # Open SMB ports ONLY on the Tailscale interface, never on the LAN/public NIC.
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 139 445 ];
    allowedUDPPorts = [ 137 138 ];
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
