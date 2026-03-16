# nixos-config

NixOS & nix-darwin configuration for two machines:

| Host | OS | Arch | Hardware |
|------|----|------|----------|
| **lab** | NixOS | x86_64-linux | AMD Ryzen 7 7700 + NVIDIA RTX 5070 Ti |
| **mac** | macOS (nix-darwin) | aarch64-darwin | Apple Silicon |

## Repo structure

```
flake.nix
├── hosts/
│   ├── lab/          # NixOS-specific (systemd, btrfs, samba, docker …)
│   └── mac/          # nix-darwin-specific (Homebrew casks, macOS defaults …)
└── home/
    └── common.nix    # Shared home-manager config (bash, git, tmux, direnv …)
```

## Common commands

```bash
nrs                                            # rebuild (works on both platforms)
nix flake update /etc/nixos                    # update all flake inputs (lab)
nix flake update ~/nixos-config                # update all flake inputs (mac)
nix-collect-garbage --delete-older-than 14d    # GC user generations
sudo nix-collect-garbage --delete-older-than 14d  # GC system generations
```

---

## lab — Storage layout

```
/           xfs     sdb2 (465G)
/boot       vfat    sdb1
/115        xfs     sda  (1.8T)
/data       btrfs   nvme0n1 + nvme1n1 (2x 2T, data=single, metadata=raid1)
├── @less
├── @more
├── @newlix          → also mounted at /home/newlix
└── @snapshots       btrbk snapshot dir
/backup     btrfs   sdc  (5.5T, noauto — mounted only during backup)
```

## lab — Backup (btrbk)

Daily `btrfs send/receive` from NVMe to sdc.

| Location | Retention |
|----------|-----------|
| `/data/@snapshots` (NVMe) | 7d daily + 4w weekly |
| `/backup` (sdc) | 30d daily + 10w weekly + 6m monthly |

- Backup disk auto-mounts before btrbk, unmounts after (stays spun down)
- Snapshots are read-only, browsable as normal directories
- Restore a file: `cp /data/@snapshots/@less.20260316/path/to/file /data/@less/`
- Manual backup: `sudo systemctl start btrbk-backup`

## lab — btrfs

```bash
btrfs filesystem show          # pool health
btrfs subvolume list /data     # list subvolumes
btrfs filesystem df /data      # space usage
sudo btrfs scrub start /data   # manual scrub
```

## lab — Backup disk

```bash
sudo mount /backup             # manual mount
ls /backup                     # browse snapshots
sudo umount /backup            # unmount (spins down)
```

## lab — Docker

```bash
cd ~/services/<name> && docker compose up -d   # start
cd ~/services/<name> && docker compose down    # stop
docker compose logs -f                         # logs
```

## lab — Samba

```bash
sudo smbpasswd -a newlix       # set/reset Samba password
```
