#!/usr/bin/env bash
# One-time setup: restic → pCloud via rclone backend
# Run as a regular user with sudo access.
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
die()  { echo -e "${RED}✗ $*${NC}" >&2; exit 1; }
ok()   { echo -e "${GREEN}✓${NC} $*"; }
info() { echo -e "${BOLD}==> $*${NC}"; }
warn() { echo -e "${YELLOW}⚠ $*${NC}"; }
ask()  { read -rp "$(echo -e "${BOLD}$* ${NC}")" _; }

[[ $EUID -eq 0 ]] && die "Run as a regular user, not root"
sudo -v || die "sudo access required"

# ── Step 1: /etc/secrets/ ──────────────────────────────────────────────────
info "Step 1/6 — Ensure /etc/secrets/ exists"
sudo mkdir -p /etc/secrets
sudo chmod 700 /etc/secrets
ok "/etc/secrets ready"

# ── Step 2: rclone config ──────────────────────────────────────────────────
info "Step 2/6 — Configure rclone pCloud remote"
echo "  When prompted:"
echo "   • n  (new remote)"
echo "   • name: pcloud"
echo "   • type: pcloud  (search for it)"
echo "   • client_id / client_secret: leave empty"
echo "   • hostname: api.pcloud.com  (US account)"
echo "   • Complete OAuth in the browser that opens"
echo ""
ask "Press Enter to launch rclone config ..."

RCLONE_CMD=""
if command -v rclone &>/dev/null; then
    RCLONE_CMD="rclone"
else
    RCLONE_CMD="nix-shell -p rclone --run rclone"
fi

$RCLONE_CMD config

# Verify remote was created
RCLONE_CONF="$HOME/.config/rclone/rclone.conf"
[[ -f "$RCLONE_CONF" ]] || die "rclone config not found at $RCLONE_CONF"

if command -v rclone &>/dev/null; then
    rclone listremotes --config "$RCLONE_CONF" | grep -q "^pcloud:" \
        || die "'pcloud' remote not found — re-run rclone config and name it 'pcloud'"
else
    nix-shell -p rclone --run "rclone listremotes --config $RCLONE_CONF" | grep -q "^pcloud:" \
        || die "'pcloud' remote not found — re-run rclone config and name it 'pcloud'"
fi

sudo cp "$RCLONE_CONF" /etc/secrets/rclone.conf
sudo chown root:root /etc/secrets/rclone.conf
sudo chmod 600 /etc/secrets/rclone.conf
ok "rclone config saved to /etc/secrets/rclone.conf"

# ── Step 3: restic password ────────────────────────────────────────────────
info "Step 3/6 — Generate restic repository password"
if [[ -f /etc/secrets/restic-pcloud.password ]]; then
    warn "Password file already exists — skipping generation"
else
    head -c 33 /dev/urandom | base64 | sudo tee /etc/secrets/restic-pcloud.password > /dev/null
    sudo chown root:root /etc/secrets/restic-pcloud.password
    sudo chmod 600 /etc/secrets/restic-pcloud.password
    ok "Password saved to /etc/secrets/restic-pcloud.password (back this up!)"
fi

# ── Step 4: nixos-rebuild ──────────────────────────────────────────────────
info "Step 4/6 — Apply NixOS config (nixos-rebuild switch)"
sudo nixos-rebuild switch --flake /etc/nixos#lab
ok "NixOS rebuilt successfully"

# ── Step 5: Test pCloud connectivity ──────────────────────────────────────
info "Step 5/6 — Test pCloud connection"
sudo rclone lsd pcloud: --config /etc/secrets/rclone.conf \
    || die "pCloud connection failed — check rclone config and OAuth token"
ok "pCloud reachable"

# ── Step 6: Init restic repository ────────────────────────────────────────
info "Step 6/6 — Initialize restic repository on pCloud"

# Check if already initialized (restic snapshots exits 0 if repo exists)
if sudo RCLONE_CONFIG=/etc/secrets/rclone.conf \
        nix-shell -p restic -p rclone --run \
        "restic -r rclone:pcloud:restic-lab -p /etc/secrets/restic-pcloud.password snapshots" \
        &>/dev/null; then
    warn "Repository already initialized — skipping"
else
    sudo RCLONE_CONFIG=/etc/secrets/rclone.conf \
        nix-shell -p restic -p rclone --run \
        "restic -r rclone:pcloud:restic-lab -p /etc/secrets/restic-pcloud.password init"
    ok "Repository initialized at pcloud:restic-lab"
fi

# ── Done ───────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}Setup complete!${NC}"
echo ""
echo "  Test backup now:"
echo "    sudo systemctl start restic-backups-pcloud.service"
echo "    journalctl -fu restic-backups-pcloud.service"
echo ""
echo "  Check next scheduled run:"
echo "    systemctl list-timers restic-backups-pcloud.timer"
echo ""
warn "IMPORTANT: Back up /etc/secrets/restic-pcloud.password somewhere safe."
warn "Without it you cannot restore from pCloud, even with the rclone token."
