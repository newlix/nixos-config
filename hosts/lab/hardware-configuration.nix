# Generated from hardware scan of lab (Debian → NixOS migration)
# CPU: AMD Ryzen 7 7700 | GPU: NVIDIA RTX 5070 Ti (GB203/Blackwell) + AMD Raphael iGPU
# Disks: sdb=465G (boot/root/swap), btrfs data pool = 2x NVMe 2TB + sda Crucial MX500 2TB SATA SSD (data=single metadata=raid1)
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"
  ];
  # boot.initrd.kernelModules = [ "amdgpu" ];  # Disabled: iGPU will be turned off in BIOS
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # ── Filesystems ────────────────────────────────────────────────────────────
  # NOTE: when installing, mount sda1 at /mnt/boot (not /mnt/boot/efi)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e3e2a03d-5f1a-4740-9819-3662c0d00827";
    fsType = "xfs";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/13B1-77D0";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" "umask=0077" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/9b6b038a-ff12-46b2-8447-4f793b4a2c53"; }
  ];

  # ── btrfs ──────────────────────────────────────────────────────────────────
  # btrfs data pool: 2x Crucial CT2000T500SSD8 NVMe + 1x Crucial MX500 2TB SATA SSD.
  # data=single (spans all devices, ~5.4T usable), metadata=raid1 (mirrored).
  # /data is top-level (btrbk uses it as volume root for @snapshots).
  # NOTE: sda is a btrfs member via `btrfs device add` (stored in fs metadata, not
  # fstab) — the /data mount by-uuid auto-assembles all 3 devices at boot.
  boot.supportedFilesystems = [ "btrfs" ];

  # Top-level mount — @less, @more, @newlix, @snapshots visible under /data/
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/28d67838-6253-49c4-b6ff-7804faf474f5";
    fsType = "btrfs";
    options = [ "noatime" "compress=zstd" "discard=async" ];
  };

  fileSystems."/home/newlix" = {
    device = "/dev/disk/by-uuid/28d67838-6253-49c4-b6ff-7804faf474f5";
    fsType = "btrfs";
    options = [ "subvol=@newlix" "noatime" "compress=zstd" "discard=async" ];
  };

  # Curated, backed-up subvolumes mounted into the (unbacked) @newlix home.
  # Only @dotfiles + @github are sent to /backup (see backup.nix); the rest of
  # home (caches, models, playground, …) is regenerable and not backed up.
  # @dotfiles also holds the live ssh/gnupg keys (symlinked from ~ via link.sh).
  fileSystems."/home/newlix/dotfiles" = {
    device = "/dev/disk/by-uuid/28d67838-6253-49c4-b6ff-7804faf474f5";
    fsType = "btrfs";
    options = [ "subvol=@dotfiles" "noatime" "compress=zstd" "discard=async" ];
  };

  fileSystems."/home/newlix/github" = {
    device = "/dev/disk/by-uuid/28d67838-6253-49c4-b6ff-7804faf474f5";
    fsType = "btrfs";
    options = [ "subvol=@github" "noatime" "compress=zstd" "discard=async" ];
  };

  # BT downloads — @115 subvolume. nodatacow is set on the subvol via `chattr +C`
  # (not a mount option, which is unreliable for a secondary subvol mount) to
  # avoid btrfs fragmentation. Not in the btrbk backup set.
  fileSystems."/115" = {
    device = "/dev/disk/by-uuid/28d67838-6253-49c4-b6ff-7804faf474f5";
    fsType = "btrfs";
    options = [ "subvol=@115" "noatime" "discard=async" ];
  };

  # ── Backup disk ────────────────────────────────────────────────────────────
  # sdc: WDC WD6004FRYZ 5.5T — btrfs for btrbk send/receive targets
  fileSystems."/backup" = {
    device = "/dev/disk/by-uuid/692cb7a6-d375-4ad3-9212-57666e66732d";
    fsType = "btrfs";
    options = [ "noatime" "compress=zstd" "noauto" ];
  };

  # ── CPU ────────────────────────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
