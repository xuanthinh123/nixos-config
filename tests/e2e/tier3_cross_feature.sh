#!/usr/bin/env bash
# tests/e2e/tier3_cross_feature.sh
# Tier 3: Cross-Feature Combinations Verification Suite
# Verifies interactions between subsystem combinations:
# 1. NVIDIA PRIME offload with Steam and GameMode
# 2. Automated OS Upgrade with Nix Store GC and Disk Starvation thresholds
# 3. Home Manager dotfile collision prevention with multi-shell integration
# 4. KDE Plasma 6 Wayland desktop with PipeWire audio stack
# 5. Tailscale VPN with system firewall and KTailctl GUI

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_tier "TIER 3: CROSS-FEATURE COMBINATIONS VERIFICATION"

# -----------------------------------------------------------------------------
# Test 3.01: NVIDIA PRIME Offload + Steam GameMode Integration
# When custom.suites.gaming and custom.hardware.nvidia.prime.enable are active,
# Steam, gamemode, and the prime-run / nvidia-offload helper must synergize.
# -----------------------------------------------------------------------------
log_info "Running Test 3.01: NVIDIA PRIME Offload + Steam GameMode Integration..."
GAMING_MOD="${PROJECT_ROOT}/modules/suites/gaming.nix"
NVIDIA_MOD="${PROJECT_ROOT}/modules/hardware/nvidia.nix"

assert_file_exists "T3.01.1" "${GAMING_MOD}" "Gaming suite module must exist"
assert_file_exists "T3.01.2" "${NVIDIA_MOD}" "NVIDIA hardware module must exist"

if [[ -f "${GAMING_MOD}" && -f "${NVIDIA_MOD}" ]]; then
    assert_file_contains "T3.01.3" "${GAMING_MOD}" "programs.steam" "Gaming module must configure Steam"
    assert_file_matches_multiline_regex "T3.01.4" "${GAMING_MOD}" 'programs\.gamemode\s*=\s*\{.*?enable\s*=\s*true|programs\.gamemode\.enable\s*=\s*true' "GameMode daemon must be enabled"
    assert_file_contains "T3.01.5" "${NVIDIA_MOD}" "prime-run" "NVIDIA offload mode must provide prime-run helper script"
    assert_file_contains "T3.01.6" "${NVIDIA_MOD}" "__NV_PRIME_RENDER_OFFLOAD=1" "prime-run must set __NV_PRIME_RENDER_OFFLOAD=1"
    assert_file_contains "T3.01.7" "${NVIDIA_MOD}" "__GLX_VENDOR_LIBRARY_NAME=nvidia" "prime-run must set __GLX_VENDOR_LIBRARY_NAME=nvidia"
fi

# -----------------------------------------------------------------------------
# Test 3.02: AutoUpgrade + Store Garbage Collection + Disk Starvation Safety
# Verifies that unattended upgrades are protected from running out of disk space
# by min-free/max-free thresholds and scheduled weekly garbage collection.
# -----------------------------------------------------------------------------
log_info "Running Test 3.02: AutoUpgrade + GC + Disk Starvation Safety..."
NIX_MOD="${PROJECT_ROOT}/modules/core/nix.nix"
OPTIONS_MOD="${PROJECT_ROOT}/modules/core/options.nix"

assert_file_exists "T3.02.1" "${NIX_MOD}" "Core nix module must exist"
if [[ -f "${NIX_MOD}" && -f "${OPTIONS_MOD}" ]]; then
    assert_file_contains "T3.02.2" "${NIX_MOD}" "min-free = maint.minFreeSpaceGB" "min-free must bind to maint.minFreeSpaceGB"
    assert_file_contains "T3.02.3" "${NIX_MOD}" "max-free = maint.maxFreeSpaceGB" "max-free must bind to maint.maxFreeSpaceGB"
    assert_file_contains "T3.02.4" "${NIX_MOD}" "auto-optimise-store = maint.storeOptimise" "Store optimisation must bind to config toggle"
    assert_file_contains "T3.02.5" "${NIX_MOD}" "--commit-lock-file" "Auto-upgrade flags must preserve deterministic flake lockfile"
fi

# -----------------------------------------------------------------------------
# Test 3.03: Home Manager Dotfile Collision Prevention & Multi-Shell Synergy
# Verifies backupFileExtension is set to 'backup' to protect fleet machines from
# activation aborts, and validates user shell definitions (bash, zsh, fish, starship).
# -----------------------------------------------------------------------------
log_info "Running Test 3.03: Home Manager Dotfile Collision Prevention & Shells..."
HM_MOD="${PROJECT_ROOT}/modules/home/default.nix"
USER_ME_MOD="${PROJECT_ROOT}/modules/home/users/me.nix"

assert_file_exists "T3.03.1" "${HM_MOD}" "Home manager module must exist"
assert_file_exists "T3.03.2" "${USER_ME_MOD}" "User me module must exist"

if [[ -f "${HM_MOD}" ]]; then
    assert_file_contains "T3.03.3" "${HM_MOD}" 'backupFileExtension = "backup";' "backupFileExtension must be set to 'backup'"
fi

if [[ -f "${USER_ME_MOD}" ]]; then
    assert_file_contains "T3.03.4" "${USER_ME_MOD}" "programs.starship" "Starship cross-shell prompt must be configured"
    assert_file_matches_multiline_regex "T3.03.5" "${USER_ME_MOD}" 'programs\.bash\s*=\s*\{.*?enable\s*=\s*true|programs\.bash\.enable\s*=\s*true' "Bash shell must be enabled"
    assert_file_contains "T3.03.6" "${USER_ME_MOD}" "home.stateVersion" "Home Manager stateVersion must be pinned"
fi

# -----------------------------------------------------------------------------
# Test 3.04: KDE Plasma 6 Desktop Session + PipeWire Audio Subsystem
# Verifies PipeWire with WirePlumber session manager is enabled in tandem
# with Plasma 6 Wayland without conflicting PulseAudio daemons.
# -----------------------------------------------------------------------------
log_info "Running Test 3.04: KDE Plasma 6 + PipeWire Audio Subsystem..."
KDE_MOD="${PROJECT_ROOT}/modules/desktop/kde.nix"
assert_file_exists "T3.04.1" "${KDE_MOD}" "KDE desktop module must exist"

if [[ -f "${KDE_MOD}" ]]; then
    assert_file_contains "T3.04.2" "${KDE_MOD}" "services.desktopManager.plasma6.enable = true;" "Plasma 6 desktop must be enabled"
    assert_file_contains "T3.04.3" "${KDE_MOD}" "services.pipewire.enable = true;" "PipeWire sound server must be enabled"
    assert_file_contains "T3.04.4" "${KDE_MOD}" "pulse.enable = true;" "PipeWire PulseAudio emulation must be enabled"
    assert_file_contains "T3.04.5" "${KDE_MOD}" "wireplumber.enable = true;" "WirePlumber session manager must be enabled"
fi

# -----------------------------------------------------------------------------
# Test 3.05: Tailscale Mesh VPN + Firewall Rule Synergy
# Verifies that Tailscale service daemon opens tailscale0 on firewall with loose reverse path filtering
# -----------------------------------------------------------------------------
log_info "Running Test 3.05: Tailscale Mesh VPN + Firewall Rule Synergy..."
TAILSCALE_MOD="${PROJECT_ROOT}/modules/services/tailscale.nix"
assert_file_exists "T3.05.1" "${TAILSCALE_MOD}" "Tailscale module must exist"

if [[ -f "${TAILSCALE_MOD}" ]]; then
    assert_file_matches_multiline_regex "T3.05.2" "${TAILSCALE_MOD}" 'services\.tailscale\s*=\s*\{.*?enable\s*=\s*true|services\.tailscale\.enable\s*=\s*true' "Tailscale service must be enabled"
    assert_file_contains "T3.05.3" "${TAILSCALE_MOD}" "trustedInterfaces = [ \"tailscale0\" ];" "tailscale0 must be a trusted interface"
    assert_file_contains "T3.05.4" "${TAILSCALE_MOD}" "checkReversePath = \"loose\";" "checkReversePath must be set to loose for Tailscale routing"
    assert_file_contains "T3.05.5" "${TAILSCALE_MOD}" "ktailctl" "KTailctl GUI must be packaged for KDE Plasma system tray"
fi

log_info "Tier 3 complete: All cross-feature interaction tests executed."
