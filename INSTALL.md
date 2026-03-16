# NixOS Installation Guide — lab

Migrating from Debian. Existing partitions are kept as-is.

## Partition layout (reference)

| Device | UUID | Mount | FS |
|--------|------|-------|----|
| sda1 | `13B1-77D0` | `/boot` | vfat |
| sda2 | `176fb7ff-d955-48c1-991e-d1c1c9535f0d` | `/` | xfs |
| sda3 | `9b6b038a-ff12-46b2-8447-4f793b4a2c53` | swap | — |
| sdb | `a6c40e89-ee46-45e7-9d53-0b08d7c808e4` | `/115` | xfs |
| ZFS pool `data` | hostid `6900e324` | `/data`, `/data/less`, `/home/newlix` | zfs |

---

## Step 1 — Boot NixOS installer

Download the minimal ISO from https://nixos.org/download and boot from USB.

---

## Step 2 — Mount partitions

```bash
# Root
mount /dev/disk/by-uuid/176fb7ff-d955-48c1-991e-d1c1c9535f0d /mnt

# Boot (must be /boot, not /boot/efi — systemd-boot expects this)
mkdir -p /mnt/boot
mount /dev/disk/by-uuid/13B1-77D0 /mnt/boot

# /115
mkdir -p /mnt/115
mount /dev/disk/by-uuid/a6c40e89-ee46-45e7-9d53-0b08d7c808e4 /mnt/115

# Swap
swapon /dev/disk/by-uuid/9b6b038a-ff12-46b2-8447-4f793b4a2c53
```

---

## Step 3 — Import ZFS pool

```bash
# -R /mnt sets the import root so datasets mount under /mnt
zpool import -R /mnt data
```

Verify datasets are mounted:

```bash
zfs list
# Should show: data, data/less, data/newlix
```

---

## Step 4 — Fix initrd kernel modules

Run `nixos-generate-config` to get the accurate kernel module list for this hardware,
then copy the result into `hardware-configuration.nix`.

```bash
nixos-generate-config --root /mnt
```

Open the generated file:

```bash
cat /mnt/etc/nixos/hardware-configuration.nix
```

Copy **only** these three lines into `hosts/lab/hardware-configuration.nix`:

```nix
boot.initrd.availableKernelModules = [ ... ];  # replace with generated value
boot.initrd.kernelModules = [ ... ];
boot.kernelModules = [ ... ];
```

Leave everything else (filesystems, ZFS, hostId) unchanged.

---

## Step 5 — Clone config

```bash
mkdir -p /mnt/etc/nixos
cd /mnt/etc/nixos
nix-shell -p git --run "git clone https://github.com/newlix/nixos-config ."
```

---

## Step 6 — Install

```bash
nixos-install --flake /mnt/etc/nixos#lab
```

Set root password when prompted. Then reboot:

```bash
reboot
```

---

## Step 7 — First boot checklist

**Login:** greetd + tuigreet will appear. Log in as `newlix`.

**Verify NVIDIA driver:**
```bash
nvidia-smi
```

**Verify ZFS:**
```bash
zpool status
zfs list
```

**Verify niri session:**
Select "niri" from tuigreet if not default, or just press Enter.

**Set up SSH key** (if not already in `~/.ssh`):
```bash
ssh-keygen -t ed25519
```

**Authenticate GitHub CLI:**
```bash
gh auth login
```

**Rebuild after any config change:**
```bash
nh os switch /etc/nixos
```
