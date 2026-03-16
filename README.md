# nixos-config

NixOS configuration for **lab** (AMD Ryzen 7 7700 + NVIDIA RTX 5070 Ti).

## Common Commands

### System rebuild

```bash
# Apply system + home-manager changes
nh os switch /etc/nixos

# Preview what would change without applying
nh os build /etc/nixos
```

### Home Manager

```bash
# Apply home-manager changes only (faster than full rebuild)
nh home switch /etc/nixos
```

### Nix

```bash
# Update all flake inputs (nixpkgs, home-manager, niri, etc.)
nix flake update /etc/nixos

# Garbage collect old generations
nix-collect-garbage --delete-older-than 14d
sudo nix-collect-garbage --delete-older-than 14d

# List installed generations
nh os list
```

### ZFS

```bash
# Check pool health
zpool status

# List datasets
zfs list

# Manual scrub
zpool scrub data

# Create snapshot
zfs snapshot data/newlix@$(date +%Y%m%d)

# List snapshots
zfs list -t snapshot
```

### Docker

```bash
# Start a service
cd ~/services/<name> && docker compose up -d

# Stop a service
cd ~/services/<name> && docker compose down

# View logs
docker compose logs -f

# GPU workload (lada)
cd ~/<project> && bash bin/lada.sh
```

### Samba

```bash
# Check Samba status
sudo systemctl status smbd

# Set/reset Samba password
sudo smbpasswd -a newlix
```

### SSH

```bash
# Generate key
ssh-keygen -t ed25519

# Copy key to remote
ssh-copy-id user@host
```
