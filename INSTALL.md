# NixOS Installation Guide — lab

## Partition layout (reference)

| Device | UUID | Mount | FS |
|--------|------|-------|----|
| sda | `a6c40e89-ee46-45e7-9d53-0b08d7c808e4` | `/115` | xfs |
| sdb1 | `13B1-77D0` | `/boot` | vfat |
| sdb2 | `176fb7ff-d955-48c1-991e-d1c1c9535f0d` | `/` | xfs |
| sdb3 | `9b6b038a-ff12-46b2-8447-4f793b4a2c53` | swap | — |
| nvme0n1 + nvme1n1 | btrfs UUID (see hardware-configuration.nix) | `/data`, `/data/less`, `/home/newlix` | btrfs |
| sdc | — | backup pool | ZFS pool `backup` |

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

### 3. Destroy old ZFS pool

```bash
zpool destroy data
```

### 4. Create btrfs filesystem

```bash
# data=single spans both drives (~3.6T usable), metadata=raid1 for safety
mkfs.btrfs -d single -m raid1 /dev/nvme0n1 /dev/nvme1n1

UUID=$(blkid -s UUID -o value /dev/nvme0n1)
echo "btrfs UUID: $UUID"
```

### 5. Create subvolumes

```bash
mount /dev/nvme0n1 /mnt
btrfs subvolume create /mnt/@data
btrfs subvolume create /mnt/@data_less
btrfs subvolume create /mnt/@home_newlix
umount /mnt
```

### 6. Mount btrfs subvolumes

```bash
mkdir -p /mnt/data/less /mnt/home/newlix
mount -o subvol=@data,noatime /dev/nvme0n1 /mnt/data
mount -o subvol=@data_less,noatime /dev/nvme0n1 /mnt/data/less
mount -o subvol=@home_newlix,noatime /dev/nvme0n1 /mnt/home/newlix
```

### 7. Restore from backup

```bash
rsync -aHAX /backup/replicas/data/less/    /mnt/data/less/
rsync -aHAX /backup/replicas/data/newlix/  /mnt/home/newlix/
```

### 8. Fill UUID into NixOS config

```bash
# Mount system root
mount /dev/disk/by-uuid/176fb7ff-d955-48c1-991e-d1c1c9535f0d /mnt/sysroot
mount /dev/disk/by-uuid/13B1-77D0 /mnt/sysroot/boot

sed -i "s/BTRFS-UUID-HERE/$UUID/g" \
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

mount /dev/nvme0n1 /tmp/btrfs
btrfs subvolume create /tmp/btrfs/@data
btrfs subvolume create /tmp/btrfs/@data_less
btrfs subvolume create /tmp/btrfs/@home_newlix
umount /tmp/btrfs

mkdir -p /mnt/data/less /mnt/home/newlix
mount -o subvol=@data,noatime /dev/nvme0n1 /mnt/data
mount -o subvol=@data_less,noatime /dev/nvme0n1 /mnt/data/less
mount -o subvol=@home_newlix,noatime /dev/nvme0n1 /mnt/home/newlix
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
