# NixOS Installation Guide — lab

## Partition layout (reference)

| Device | UUID | Mount | FS |
|--------|------|-------|----|
| sda | `a6c40e89-ee46-45e7-9d53-0b08d7c808e4` | `/115` | xfs |
| sdb1 | `13B1-77D0` | `/boot` | vfat |
| sdb2 | `176fb7ff-d955-48c1-991e-d1c1c9535f0d` | `/` | xfs |
| sdb3 | `9b6b038a-ff12-46b2-8447-4f793b4a2c53` | swap | — |
| nvme0n1 + nvme1n1 | btrfs UUID (see hardware-configuration.nix) | `/data`, `/data/less`, `/home/newlix` | btrfs |
| sdc | btrfs UUID (see hardware-configuration.nix) | `/backup` | btrfs |

---

## Migrating ZFS → btrfs (one-time, from CachyOS live USB)

### 1. Install tools

```bash
pacman -Sy zfs-utils btrfs-progs rsync
```

### 2. Import backup pool (read-only)

```bash
zpool import -o readonly=on backup
mkdir -p /backup/replicas/data
zfs mount backup/replicas/data/less
zfs mount backup/replicas/data/newlix
```

### 3. Destroy old ZFS pool and backup pool

```bash
zpool destroy data

# After restoring data (step 7), wipe sdc for btrfs:
zpool export backup
wipefs -a /dev/sdc
```

### 4. Create btrfs filesystems

```bash
# NVMe pool: data=single spans both drives (~3.6T usable), metadata=raid1 for safety
mkfs.btrfs -d single -m raid1 /dev/nvme0n1 /dev/nvme1n1
UUID=$(blkid -s UUID -o value /dev/nvme0n1)
echo "NVMe btrfs UUID: $UUID"

# Backup disk
mkfs.btrfs /dev/sdc
BACKUP_UUID=$(blkid -s UUID -o value /dev/sdc)
echo "Backup btrfs UUID: $BACKUP_UUID"
```

### 5. Create subvolumes

```bash
mount /dev/nvme0n1 /mnt
btrfs subvolume create /mnt/@less
btrfs subvolume create /mnt/@more
btrfs subvolume create /mnt/@newlix
# btrbk snapshot_dir
btrfs subvolume create /mnt/@snapshots
umount /mnt
```

### 6. Mount btrfs subvolumes

```bash
mkdir -p /mnt/data /mnt/home/newlix
mount -o noatime /dev/nvme0n1 /mnt/data
mount -o subvol=@newlix,noatime /dev/nvme0n1 /mnt/home/newlix
```

### 7. Restore from backup

```bash
rsync -aHAX /backup/replicas/data/less/    /mnt/data/@less/
rsync -aHAX /backup/replicas/data/newlix/  /mnt/home/newlix/
```

### 8. Fill UUIDs into NixOS config

```bash
# Mount system root
mount /dev/disk/by-uuid/176fb7ff-d955-48c1-991e-d1c1c9535f0d /mnt/sysroot
mount /dev/disk/by-uuid/13B1-77D0 /mnt/sysroot/boot

sed -i "s/BTRFS-UUID-HERE/$UUID/g" \
  /mnt/sysroot/etc/nixos/hosts/lab/hardware-configuration.nix
sed -i "s/BACKUP-UUID-HERE/$BACKUP_UUID/g" \
  /mnt/sysroot/etc/nixos/hosts/lab/hardware-configuration.nix
```

### 9. Rebuild NixOS

```bash
nixos-enter --root /mnt/sysroot
nixos-rebuild switch --flake /etc/nixos#lab
exit
reboot
```

---

## Fresh install (from NixOS installer)

### Step 1 — Boot NixOS installer

Download the minimal ISO from https://nixos.org/download and boot from USB.

### Step 2 — Mount partitions

```bash
mount /dev/disk/by-uuid/176fb7ff-d955-48c1-991e-d1c1c9535f0d /mnt

mkdir -p /mnt/boot
mount /dev/disk/by-uuid/13B1-77D0 /mnt/boot

mkdir -p /mnt/115
mount /dev/disk/by-uuid/a6c40e89-ee46-45e7-9d53-0b08d7c808e4 /mnt/115

swapon /dev/disk/by-uuid/9b6b038a-ff12-46b2-8447-4f793b4a2c53
```

### Step 3 — Create btrfs and subvolumes

```bash
mkfs.btrfs -d single -m raid1 /dev/nvme0n1 /dev/nvme1n1
UUID=$(blkid -s UUID -o value /dev/nvme0n1)

mkfs.btrfs /dev/sdc
BACKUP_UUID=$(blkid -s UUID -o value /dev/sdc)

mount /dev/nvme0n1 /tmp/btrfs
btrfs subvolume create /tmp/btrfs/@less
btrfs subvolume create /tmp/btrfs/@more
btrfs subvolume create /tmp/btrfs/@newlix
btrfs subvolume create /tmp/btrfs/@snapshots
umount /tmp/btrfs

mkdir -p /mnt/data /mnt/home/newlix /mnt/backup
mount -o noatime /dev/nvme0n1 /mnt/data
mount -o subvol=@newlix,noatime /dev/nvme0n1 /mnt/home/newlix
mount -o noatime /dev/sdc /mnt/backup
```

### Step 4 — Fix initrd kernel modules

```bash
nixos-generate-config --root /mnt
cat /mnt/etc/nixos/hardware-configuration.nix
# Copy boot.initrd.availableKernelModules, boot.initrd.kernelModules,
# boot.kernelModules into hosts/lab/hardware-configuration.nix
```

### Step 5 — Clone config and fill UUID

```bash
mkdir -p /mnt/etc/nixos
cd /mnt/etc/nixos
nix-shell -p git --run "git clone https://github.com/newlix/nixos-config ."

sed -i "s/BTRFS-UUID-HERE/$UUID/g" hosts/lab/hardware-configuration.nix
sed -i "s/BACKUP-UUID-HERE/$BACKUP_UUID/g" hosts/lab/hardware-configuration.nix
```

### Step 6 — Install

```bash
nixos-install --flake /mnt/etc/nixos#lab
reboot
```

### Step 7 — First boot checklist

**Verify btrfs:**
```bash
btrfs filesystem show
btrfs subvolume list /data
```

**Verify NVIDIA driver:**
```bash
nvidia-smi
```

**Set Samba password:**
```bash
sudo smbpasswd -a newlix
```

**Set up SSH key:**
```bash
ssh-keygen -t ed25519
```

**Rebuild after any config change:**
```bash
nh os switch /etc/nixos
```
