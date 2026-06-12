{ config, pkgs, ... }:

{
  # ── Samba ──────────────────────────────────────────────────────────────────
  services.samba = {
    enable = true;
    # Firewall (below) admits SMB from Tailscale + the LAN subnet only — never WAN.
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
        # Exposure is controlled by the firewall below: smbd listens on all
        # interfaces, but the firewall only admits SMB from tailscale0 and the LAN
        # subnet (192.168.0.0/24) — WAN sources are dropped. ("bind interfaces only"
        # is not used because smbd refuses to bind the point-to-point tailscale0.)
        # (Incident 2026-06-11: SMB was WAN-exposed via openFirewall and hit by
        # WantToCry ransomware through the writable shares — hence source-scoping.)
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
    };
  };

  # SMB reachability:
  #  - Tailscale (always): open 445/139 on the tailscale0 interface.
  #  - LAN 192.168.0.0/24: admitted by SOURCE SUBNET via the iptables rules below,
  #    NOT by opening the eno1 interface — so even if the router ever port-forwards
  #    445, WAN-sourced packets (source outside 192.168.0.0/24) are still dropped.
  #    (After the 2026-06-11 WantToCry incident, SMB must never be WAN-reachable.)
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [ 139 445 ];
    allowedUDPPorts = [ 137 138 ];
  };
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw -p tcp -s 192.168.0.0/24 -m multiport --dports 139,445 -j nixos-fw-accept
    iptables -I nixos-fw -p udp -s 192.168.0.0/24 -m multiport --dports 137,138 -j nixos-fw-accept
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D nixos-fw -p tcp -s 192.168.0.0/24 -m multiport --dports 139,445 -j nixos-fw-accept || true
    iptables -D nixos-fw -p udp -s 192.168.0.0/24 -m multiport --dports 137,138 -j nixos-fw-accept || true
  '';

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
