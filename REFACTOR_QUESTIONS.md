# Refactor Questions

## [hosts/lab/configuration.nix] SSH password auth + passwordless sudo
- **Problem**: `PasswordAuthentication = true` + `wheelNeedsPassword = false` means anyone who brute-forces the SSH password gets immediate passwordless root.
- **Options**: A) Disable password auth (`PasswordAuthentication = false`) and use key-only SSH. B) Keep as-is if Tailscale-only access is the intended threat model.
- **Status**: Unresolved (skipped)

## [hosts/lab/home.nix] mpv uses OpenGL instead of Vulkan on NVIDIA+Wayland
- **Problem**: `vo = "gpu"` + `gpu-api = "opengl"` forces EGL/X fallback on a native Wayland+NVIDIA setup. `vo = "gpu-next"` + `gpu-api = "vulkan"` would use the native Vulkan WSI path.
- **Options**: A) Switch to vulkan/gpu-next for better Wayland integration. B) Keep opengl if vulkan causes issues with specific content.
- **Status**: Unresolved (skipped)

## [hosts/lab/home.nix] Hardcoded hwmon4 and eno1 in waybar widgets
- **Problem**: `hwmon4` kernel index and `eno1` NIC name are not stable across reboots/kernel updates. Currently work but will silently show 0 if they change.
- **Resolution**: Changed to dynamic lookup (k10temp driver name for hwmon, `ip route` for NIC).
- **Status**: Resolved

## [modules/desktop/niri.nix] Module lacks enable option gate
- **Problem**: The niri module is unconditionally active when imported. If a second host is added that doesn't want a GUI, there's no disable path.
- **Options**: A) Add `config.desktop.niri.enable` option. B) Keep as-is since only one Linux host exists.
- **Status**: Unresolved (skipped)
