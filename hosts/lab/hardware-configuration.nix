# Generated from hardware scan of lab (Debian → NixOS migration)
# CPU: AMD Ryzen 7 7700 | GPU: NVIDIA RTX 5070 Ti (GB203/Blackwell) + AMD Raphael iGPU
# Disks: sda=465G (boot/root/swap), sdb=1.8T (/115), ZFS data pool (2x NVMe 2TB)
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

  # ── ZFS ────────────────────────────────────────────────────────────────────
  # Pool "data" is a stripe of two Crucial CT2000T500SSD8 NVMe drives.
  # Datasets: data → /data, data/less → /data/less, data/newlix → /home/newlix
  boot.supportedFilesystems = [ "zfs" ];
  # Must match the hostid recorded in the ZFS pool's label (from current system)
  networking.hostId = "6900e324";
  boot.zfs.extraPools = [ "data" ];

  fileSystems."/data" = {
    device = "data";
    fsType = "zfs";
  };

  fileSystems."/data/less" = {
    device = "data/less";
    fsType = "zfs";
  };

  fileSystems."/home/newlix" = {
    device = "data/newlix";
    fsType = "zfs";
  };

  # ── CPU ────────────────────────────────────────────────────────────────────
  hardware.cpu.amd.updateMicrocode =
    lib.mkDefault config.hardware.enableRedistributableFirmware;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
