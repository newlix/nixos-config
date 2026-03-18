## home/packages.nix
- **Problem**: This file mixes system-level (`environment.systemPackages`) and home-manager (`home-manager.users.newlix.home.packages`) concerns in a single module imported at the system layer. The `home/` directory implies home-manager scope, but this file acts as both.
- **Options**: A) Move `home-manager.users.newlix.home.packages` entries into `home/common.nix` as `home.packages`, keep `packages.nix` as system-only. B) Leave as-is (works fine for single-user).
- **Status**: Not actioned (needs user decision)

## home/common.nix — ffmpeg withCuda override
- **Problem**: `ffmpeg.override { withCuda = true; }` in `hosts/lab/home.nix` enables CUDA filters but not `withUnfree = true` for libnpp. If only NVENC/NVDEC hardware transcode is needed, the default `pkgs.ffmpeg` may suffice.
- **Options**: A) Drop the override if only NVENC/NVDEC is needed. B) Add `withUnfree = true` if libnpp GPU filters are needed.
- **Status**: Not actioned (needs user to clarify intent)

## hosts/lab/configuration.nix — linuxPackages_latest + nvidiaPackages.stable
- **Problem**: `linuxPackages_latest` tracks the newest kernel in nixpkgs. When a major kernel bump lands before NVIDIA's stable driver adds support, the build breaks. Currently working (kernel 6.19.8, driver 580.142), but this is a recurring risk on nixos-unstable.
- **Options**: A) Switch to `nvidiaPackages.beta` (tracks newer kernels faster, currently 595.45). B) Switch to `linuxPackages` (LTS kernel, never breaks with stable NVIDIA, but loses latest hardware support). C) Keep as-is and accept occasional manual intervention.
- **Status**: Not actioned (needs user to decide risk tolerance)
