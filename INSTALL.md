# NixOS Reinstall Guide — lab

重新安裝 NixOS，資料磁碟（btrfs NVMe、sda、sdc）不動，只重灌系統碟 sdb。

## Partition layout

| Device | Mount | FS | 說明 |
|--------|-------|----|------|
| sdb1 | `/boot` | vfat | EFI |
| sdb2 | `/` | xfs | 系統根目錄 |
| sdb3 | swap | — | |
| sda | `/115` | xfs | 資料碟 |
| nvme0n1 + nvme1n1 | `/data`, `/home/newlix` | btrfs | 資料（不重建） |
| sdc | `/backup` | btrfs | 備份碟（不重建） |

---

## Step 1 — Boot NixOS installer

Download minimal ISO from https://nixos.org/download, boot from USB.

## Step 2 — Format system disk (sdb only)

```bash
# 如果需要重建分割表：
# parted /dev/sdb -- mklabel gpt
# parted /dev/sdb -- mkpart ESP fat32 1MiB 512MiB
# parted /dev/sdb -- set 1 esp on
# parted /dev/sdb -- mkpart primary 512MiB -8GiB
# parted /dev/sdb -- mkpart primary linux-swap -8GiB 100%

# 格式化（只動 sdb，其他磁碟不要碰）
mkfs.fat -F 32 /dev/sdb1
mkfs.xfs -f /dev/sdb2
mkswap /dev/sdb3
```

## Step 3 — Mount all partitions

```bash
mount /dev/sdb2 /mnt
mkdir -p /mnt/boot
mount /dev/sdb1 /mnt/boot
swapon /dev/sdb3

# 資料碟（已存在，直接掛載）
mkdir -p /mnt/115
mount /dev/disk/by-uuid/a6c40e89-ee46-45e7-9d53-0b08d7c808e4 /mnt/115

mkdir -p /mnt/data
mount -o noatime,compress=zstd,discard=async /dev/nvme0n1 /mnt/data

mkdir -p /mnt/home/newlix
mount -o subvol=@newlix,noatime,compress=zstd,discard=async /dev/nvme0n1 /mnt/home/newlix
```

## Step 4 — Clone config

```bash
mkdir -p /mnt/etc/nixos
cd /mnt/etc/nixos
nix-shell -p git --run "git clone https://github.com/newlix/nixos-config ."
```

## Step 5 — Update UUIDs (if sdb was reformatted)

```bash
# 確認新 UUID
blkid /dev/sdb1 /dev/sdb2 /dev/sdb3

# 更新 hardware-configuration.nix 中 /、/boot、swap 的 UUID
vim hosts/lab/hardware-configuration.nix
```

btrfs UUID（nvme、sdc）不需要改，除非你重建了這些磁碟。

## Step 6 — Install

```bash
nixos-install --flake /mnt/etc/nixos#lab
reboot
```

## Step 7 — First boot checklist

```bash
# 驗證 btrfs
btrfs filesystem show
btrfs subvolume list /data

# 驗證 NVIDIA
nvidia-smi

# 設定 Samba 密碼
sudo smbpasswd -a newlix

# 設定 SSH key
ssh-keygen -t ed25519

# 驗證 Eternal Terminal
systemctl status eternal-terminal
```
