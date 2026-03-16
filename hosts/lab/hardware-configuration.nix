# Generated from hardware scan of lab (Debian → NixOS migration)
# CPU: AMD Ryzen 7 7700 | GPU: NVIDIA RTX 5070 Ti (GB203/Blackwell) + AMD Raphael iGPU
# Disks: sda=465G (boot/root/swap), sdb=1.8T (/115), btrfs (2x NVMe 2TB, data=single metadata=raid1)
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme" "xhci_pci" "ahci" "usbhid" "usb_storage" "sd_mod"
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # ── Filesystems ────────────────────────────────────────────────────────────
  # NOTE: when installing, mount sda1 at /mnt/boot (not /mnt/boot/efi)
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/176fb7ff-d955-48c1-991e-d1c1c9535f0d";
    fsType = "xfs";
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/13B1-77D0";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" "umask=0077" ];
  };

  fileSystems."/115" = {
    device = "/dev/disk/by-uuid/a6c40e89-ee46-45e7-9d53-0b08d7c808e4";
    fsType = "xfs";
    options = [ "noatime" ];
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/9b6b038a-ff12-46b2-8447-4f793b4a2c53"; }
  ];

  # ── btrfs ──────────────────────────────────────────────────────────────────
  # Two Crucial CT2000T500SSD8 NVMe drives in a single btrfs filesystem.
  # data=single (spans both, ~3.6T usable), metadata=raid1 (mirrored).
  # /data is top-level (btrbk uses it as volume root for @snapshots).
  # TODO: replace BTRFS-UUID-HERE with output of: blkid /dev/nvme0n1
  boot.supportedFilesystems = [ "btrfs" ];

  # Top-level mount — @less, @newlix, @snapshots visible under /data/
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/BTRFS-UUID-HERE";
    fsType = "btrfs";
    options = [ "noatime" "compress=zstd" "discard=async" ];
  };

  fileSystems."/home/newlix" = {
    device = "/dev/disk/by-uuid/BTRFS-UUID-HERE";
    fsType = "btrfs";
    options = [ "subvol=@newlix" "noatime" "compress=zstd" "discard=async" ];
  };

  # ── Backup disk ────────────────────────────────────────────────────────────
  # sdc: WDC WD6004FRYZ 5.5T — btrfs for btrbk send/receive targets
  # TODO: replace BACKUP-UUID-HERE with output of: blkid /dev/sdc after mkfs
  fileSystems."/backup" = {
    device = "/dev/disk/by-uuid/BACKUP-UUID-HERE";
    fsType = "btrfs";
    options = [ "noatime" "compress=zstd" ];
  };

  # ── CPU ────────────────────────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
