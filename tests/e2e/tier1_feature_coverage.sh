#!/usr/bin/env bash
# tests/e2e/tier1_feature_coverage.sh
# Tier 1: Feature Coverage Verification Suite
# Verifies all primary functional requirements derived from ORIGINAL_REQUEST.md & PROJECT.md:
# Flakes, Home Manager, pure Linux boot, pure filesystems, NVIDIA proprietary latest,
# S3 deep sleep, auto-maintenance, KDE Plasma 6 Wayland, Discover Flatpak store, tiered fallbacks, 100% English comments.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_tier "TIER 1: FEATURE COVERAGE VERIFICATION"

# -----------------------------------------------------------------------------
# Test 1.01: Flake Structure & Multi-Host Output
# Requirements: R2, PROJECT.md Table Item 1 & 13, User Stability Directive
# -----------------------------------------------------------------------------
log_info "Running Test 1.01: Flake Structure and Multi-Host Declaration..."
FLAKE_FILE="${PROJECT_ROOT}/flake.nix"
assert_file_exists "T1.01.1" "${FLAKE_FILE}" "Flake entrypoint flake.nix must exist"
if [[ -f "${FLAKE_FILE}" ]]; then
    assert_file_matches_regex "T1.01.2" "${FLAKE_FILE}" 'nixpkgs\.url\s*=\s*"github:nixos/nixpkgs/nixos-24\.11"' "flake.nix must pin primary nixpkgs to NixOS Stable 24.11 LTS"
    assert_file_matches_regex "T1.01.3" "${FLAKE_FILE}" 'home-manager.*release-24\.11' "flake.nix must pin home-manager to release-24.11"
    assert_file_matches_regex "T1.01.4" "${FLAKE_FILE}" '(nixosConfigurations\.default|default\s*=\s*mkHost)' "flake.nix must output default host profile"
    assert_file_matches_regex "T1.01.5" "${FLAKE_FILE}" '(nixosConfigurations\.me|me\s*=\s*mkHost)' "flake.nix must output me host profile"
    assert_file_contains "T1.01.6" "${FLAKE_FILE}" "nixpkgs.lib.nixosSystem" "flake.nix must construct systems via nixpkgs.lib.nixosSystem"
fi

# -----------------------------------------------------------------------------
# Test 1.02: Home Manager Fleet Integration
# Requirements: R2, PROJECT.md Table Item 25
# -----------------------------------------------------------------------------
log_info "Running Test 1.02: Home Manager Fleet Integration..."
HM_DEFAULT="${PROJECT_ROOT}/modules/home/default.nix"
HM_USER_ME="${PROJECT_ROOT}/modules/home/users/me.nix"
assert_file_exists "T1.02.1" "${HM_DEFAULT}" "Home manager module default.nix must exist"
assert_file_exists "T1.02.2" "${HM_USER_ME}" "User me configuration must exist"
if [[ -f "${HM_DEFAULT}" ]]; then
    assert_file_contains "T1.02.3" "${HM_DEFAULT}" "useGlobalPkgs = true;" "Home Manager must use global system packages"
    assert_file_contains "T1.02.4" "${HM_DEFAULT}" "useUserPackages = true;" "Home Manager must use user package allocations"
    assert_file_contains "T1.02.5" "${HM_DEFAULT}" 'backupFileExtension = "backup";' "Home Manager must set backupFileExtension to prevent file clobbering"
fi

# -----------------------------------------------------------------------------
# Test 1.03: Pure Linux Bootloader (Zero Windows Dual-Boot / os-prober)
# Requirements: R5, PROJECT.md Table Item 7
# -----------------------------------------------------------------------------
log_info "Running Test 1.03: Pure Linux Bootloader..."
BOOT_FILE="${PROJECT_ROOT}/modules/core/boot.nix"
assert_file_exists "T1.03.1" "${BOOT_FILE}" "Core boot module must exist"
if [[ -f "${BOOT_FILE}" ]]; then
    assert_file_matches_multiline_regex "T1.03.2" "${BOOT_FILE}" 'systemd-boot\s*=\s*\{.*?enable\s*=\s*true' "systemd-boot must be enabled"
    assert_file_matches_regex "T1.03.3" "${BOOT_FILE}" 'configurationLimit\s*=\s*10;' "Bootloader generation limit must be set to 10"
    assert_file_matches_regex "T1.03.4" "${BOOT_FILE}" 'canTouchEfiVariables\s*=\s*true;' "EFI variable touching must be enabled"
    assert_code_not_contains "T1.03.5" "${BOOT_FILE}" "useOSProber = true" "os-prober must not be enabled in code for Windows scanning"
    assert_code_not_matches_regex "T1.03.6" "${BOOT_FILE}" '(chainloader|boot\.loader\.grub\.enable\s*=\s*true)' "Boot configuration code must not enable GRUB or Windows chainloader"
fi

# -----------------------------------------------------------------------------
# Test 1.04: Pure Linux Filesystems (Zero NTFS Drivers or Mounts)
# Requirements: R5, PROJECT.md Table Item 8
# -----------------------------------------------------------------------------
log_info "Running Test 1.04: Pure Linux Filesystems..."
FS_FILE="${PROJECT_ROOT}/modules/hardware/filesystem.nix"
assert_file_exists "T1.04.1" "${FS_FILE}" "Hardware filesystem module must exist"
if [[ -f "${FS_FILE}" ]]; then
    assert_file_contains "T1.04.2" "${FS_FILE}" '"btrfs"' "Btrfs native Linux filesystem must be supported"
    assert_file_contains "T1.04.3" "${FS_FILE}" '"ext4"' "Ext4 native Linux filesystem must be supported"
    assert_file_contains "T1.04.4" "${FS_FILE}" '"xfs"' "XFS native Linux filesystem must be supported"
    assert_code_not_contains "T1.04.5" "${FS_FILE}" "ntfs-3g" "ntfs-3g package must not be included in packages"
    assert_code_not_contains "T1.04.6" "${FS_FILE}" '"ntfs"' "NTFS filesystem driver must not be included"
    assert_code_not_contains "T1.04.7" "${FS_FILE}" '"ntfs3"' "Kernel ntfs3 driver must not be included"
fi

# -----------------------------------------------------------------------------
# Test 1.05: NVIDIA Proprietary Stable LTS Driver (open = false)
# Requirements: R2, PROJECT.md Table Item 10 & 11, User Stable LTS Directive
# -----------------------------------------------------------------------------
log_info "Running Test 1.05: NVIDIA Proprietary Driver Stack..."
NVIDIA_FILE="${PROJECT_ROOT}/modules/hardware/nvidia.nix"
assert_file_exists "T1.05.1" "${NVIDIA_FILE}" "NVIDIA hardware module must exist"
if [[ -f "${NVIDIA_FILE}" ]]; then
    assert_file_matches_regex "T1.05.2" "${NVIDIA_FILE}" 'package\s*=\s*config\.boot\.kernelPackages\.nvidiaPackages\.stable;' "NVIDIA package must use official stable LTS driver"
    assert_file_matches_regex "T1.05.3" "${NVIDIA_FILE}" 'open\s*=\s*false;' "NVIDIA open driver must be strictly false (proprietary enforced)"
    assert_file_contains "T1.05.4" "${NVIDIA_FILE}" 'services.xserver.videoDrivers = [ "nvidia" ];' "Video driver must load nvidia module"
    assert_file_contains "T1.05.5" "${NVIDIA_FILE}" "allowUnfreePredicate" "Unfree predicate must permit official NVIDIA driver packages"
    assert_file_matches_multiline_regex "T1.05.6" "${NVIDIA_FILE}" 'hardware\.graphics\s*=\s*\{.*?enable\s*=\s*true' "Modern NixOS 24.11+ graphics acceleration must be enabled"
    assert_file_matches_regex "T1.05.7" "${NVIDIA_FILE}" 'enable32Bit\s*=\s*true;' "32-bit graphics support must be enabled for Steam/Proton"
fi

# -----------------------------------------------------------------------------
# Test 1.06: S3 Deep Sleep Power Management
# Requirements: R2, PROJECT.md Table Item 9
# -----------------------------------------------------------------------------
log_info "Running Test 1.06: S3 Deep Sleep Power Management..."
POWER_FILE="${PROJECT_ROOT}/modules/hardware/power.nix"
assert_file_exists "T1.06.1" "${POWER_FILE}" "Power management module must exist"
if [[ -f "${POWER_FILE}" ]]; then
    assert_file_contains "T1.06.2" "${POWER_FILE}" 'mem_sleep_default=deep' "Kernel cmdline must force mem_sleep_default=deep for ACPI S3"
    assert_file_contains "T1.06.3" "${POWER_FILE}" 'SuspendState=mem' "systemd-sleep must be configured for deep sleep mode"
fi

# -----------------------------------------------------------------------------
# Test 1.07: Automated OS Upgrades & Store Maintenance
# Requirements: R3, PROJECT.md Table Item 3, 4, 5, 6
# -----------------------------------------------------------------------------
log_info "Running Test 1.07: Automated OS Upgrades and Maintenance..."
NIX_FILE="${PROJECT_ROOT}/modules/core/nix.nix"
assert_file_exists "T1.07.1" "${NIX_FILE}" "Core nix module must exist"
if [[ -f "${NIX_FILE}" ]]; then
    assert_file_contains "T1.07.2" "${NIX_FILE}" "system.autoUpgrade" "Automated OS upgrade block must be declared"
    assert_file_contains "T1.07.3" "${NIX_FILE}" "randomizedDelaySec" "Auto-upgrade must use randomized jitter to protect fleet network"
    assert_file_contains "T1.07.4" "${NIX_FILE}" "nix.gc" "Automated store garbage collection must be declared"
    assert_file_contains "T1.07.5" "${NIX_FILE}" "--delete-older-than" "Store GC must specify generation retention policy"
    assert_file_contains "T1.07.6" "${NIX_FILE}" "auto-optimise-store" "Nix daemon inline store deduplication must be enabled"
    assert_file_contains "T1.07.7" "${NIX_FILE}" "min-free" "Emergency GC min-free threshold must be configured"
    assert_file_contains "T1.07.8" "${NIX_FILE}" "max-free" "Emergency GC max-free threshold must be configured"
fi

# -----------------------------------------------------------------------------
# Test 1.08: KDE Plasma 6 Wayland Desktop Session
# Requirements: R2, PROJECT.md Table Item 14 & 16
# -----------------------------------------------------------------------------
log_info "Running Test 1.08: KDE Plasma 6 Wayland Desktop Session..."
KDE_FILE="${PROJECT_ROOT}/modules/desktop/kde.nix"
assert_file_exists "T1.08.1" "${KDE_FILE}" "KDE desktop module must exist"
if [[ -f "${KDE_FILE}" ]]; then
    assert_file_contains "T1.08.2" "${KDE_FILE}" "services.desktopManager.plasma6.enable = true;" "KDE Plasma 6 desktop manager must be enabled"
    assert_file_contains "T1.08.3" "${KDE_FILE}" "services.pipewire" "PipeWire modern audio subsystem must be configured"
    assert_file_contains "T1.08.4" "${KDE_FILE}" "wireplumber.enable = true;" "WirePlumber session manager must be enabled"
fi

# -----------------------------------------------------------------------------
# Test 1.09: Display Manager Configuration (SDDM Wayland)
# -----------------------------------------------------------------------------
log_info "Running Test 1.09: Display Manager Configuration..."
DM_FILE="${PROJECT_ROOT}/modules/desktop/display-manager.nix"
assert_file_exists "T1.09.1" "${DM_FILE}" "Display manager module must exist"
if [[ -f "${DM_FILE}" ]]; then
    assert_file_contains "T1.09.2" "${DM_FILE}" "sddm" "SDDM display manager must be supported"
    assert_file_contains "T1.09.3" "${DM_FILE}" "wayland.enable = true;" "SDDM Wayland greeter must be enabled"
fi

# -----------------------------------------------------------------------------
# Test 1.10: GUI Discover Store & Flatpak Backend
# Requirements: R4, User update 2026-11-14T13:07:40Z, PROJECT.md Item 18
# -----------------------------------------------------------------------------
log_info "Running Test 1.10: Discover Store & Flatpak Backend..."
FLATPAK_FILE="${PROJECT_ROOT}/modules/services/flatpak.nix"
GUI_APPS_FILE="${PROJECT_ROOT}/modules/suites/gui-apps.nix"
assert_file_exists "T1.10.1" "${FLATPAK_FILE}" "Flatpak service module must exist"
assert_file_exists "T1.10.2" "${GUI_APPS_FILE}" "GUI apps suite must exist"
if [[ -f "${FLATPAK_FILE}" ]]; then
    assert_file_contains "T1.10.3" "${FLATPAK_FILE}" "services.flatpak.enable = true;" "Flatpak service must be enabled"
fi
if [[ -f "${GUI_APPS_FILE}" ]]; then
    assert_file_contains "T1.10.4" "${GUI_APPS_FILE}" "discover" "KDE Discover store package must be installed"
    assert_code_not_contains "T1.10.5" "${GUI_APPS_FILE}" "nix-software-center" "Unmaintained nix-software-center must not be included"
fi

# -----------------------------------------------------------------------------
# Test 1.11: Tiered Software Fallbacks (Distrobox, Podman, nix-ld)
# Requirements: R4, PROJECT.md Table Items 20 & 21
# -----------------------------------------------------------------------------
log_info "Running Test 1.11: Tiered Software Fallback Modules..."
DISTROBOX_FILE="${PROJECT_ROOT}/modules/services/distrobox.nix"
NIXLD_FILE="${PROJECT_ROOT}/modules/services/nix-ld.nix"
assert_file_exists "T1.11.1" "${DISTROBOX_FILE}" "Distrobox/Podman service module must exist"
assert_file_exists "T1.11.2" "${NIXLD_FILE}" "nix-ld service module must exist"
if [[ -f "${DISTROBOX_FILE}" ]]; then
    assert_file_contains "T1.11.3" "${DISTROBOX_FILE}" "distrobox" "Distrobox container tool must be configured"
    assert_file_contains "T1.11.4" "${DISTROBOX_FILE}" "virtualisation.podman" "Rootless Podman container engine must be configured"
fi
if [[ -f "${NIXLD_FILE}" ]]; then
    assert_file_matches_multiline_regex "T1.11.5" "${NIXLD_FILE}" 'programs\.nix-ld\s*=\s*\{.*?enable\s*=\s*true|programs\.nix-ld\.enable\s*=\s*true' "programs.nix-ld must be enabled for foreign FHS binaries"
fi

# -----------------------------------------------------------------------------
# Test 1.12: Interactive CLI Search Tools (nh, comma, nix-index)
# Requirements: R4, User directive 2026-11-14T13:07:40Z, PROJECT.md Item 19
# -----------------------------------------------------------------------------
log_info "Running Test 1.12: Interactive CLI Search Tools..."
CLI_TOOLS_FILE="${PROJECT_ROOT}/modules/suites/cli-tools.nix"
assert_file_exists "T1.12.1" "${CLI_TOOLS_FILE}" "CLI tools suite must exist"
if [[ -f "${CLI_TOOLS_FILE}" ]]; then
    assert_file_contains "T1.12.2" "${CLI_TOOLS_FILE}" "nh" "nh tool must be included for interactive search and management"
    assert_file_contains "T1.12.3" "${CLI_TOOLS_FILE}" "comma" "comma command-not-found runner must be included"
    assert_file_contains "T1.12.4" "${CLI_TOOLS_FILE}" "nix-index" "nix-index locator must be included"
fi

# -----------------------------------------------------------------------------
# Test 1.13: 100% English Comments Audit
# Requirements: R7, Acceptance Criteria, All `.nix` files
# -----------------------------------------------------------------------------
log_info "Running Test 1.13: 100% English Comments Audit across all Nix files..."
NIX_FILES_COUNT=0
ENGLISH_PASS_COUNT=0
while IFS= read -r nix_path; do
    NIX_FILES_COUNT=$((NIX_FILES_COUNT + 1))
    rel_path="${nix_path#"${PROJECT_ROOT}/"}"
    if assert_english_comments "T1.13.${NIX_FILES_COUNT}" "${nix_path}" "Comments in ${rel_path} must be 100% English"; then
        ENGLISH_PASS_COUNT=$((ENGLISH_PASS_COUNT + 1))
    fi
done < <(find "${PROJECT_ROOT}" -name "*.nix" -type f)

log_info "Tier 1 complete: Audited ${NIX_FILES_COUNT} Nix files for English comments."
