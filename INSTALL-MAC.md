# macOS Setup Guide — mac

## Step 1 — Install Determinate Nix

```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

## Step 2 — Clone config

```bash
git clone https://github.com/newlix/nixos-config ~/nixos-config
```

## Step 3 — Build

```bash
darwin-rebuild switch --flake ~/nixos-config#mac
```

## Step 4 — First boot checklist

```bash
# 驗證 nix-darwin
darwin-rebuild --list-generations

# 驗證 Homebrew casks
brew list --cask
```
