#!/usr/bin/env bash
# tests/e2e/tier2_boundary_corner.sh
# Tier 2: Boundary & Corner Cases Verification Suite
# Verifies non-NVIDIA machine baseline, missing Bus ID handling, modern standby fallback,
# empty/malformed option safety, and unfree predicate scoping.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

log_tier "TIER 2: BOUNDARY & CORNER CASES VERIFICATION"

# -----------------------------------------------------------------------------
# Test 2.01: Non-NVIDIA Machine Baseline Isolation
# Verifies that generic fleet hosts (hosts/default) disable NVIDIA by default,
# ensuring systems with Intel iGPU, AMD Radeon, or VM run cleanly without NVIDIA drivers.
# -----------------------------------------------------------------------------
log_info "Running Test 2.01: Non-NVIDIA Machine Configuration Isolation..."
HOST_DEFAULT="${PROJECT_ROOT}/hosts/default/default.nix"
NVIDIA_MOD="${PROJECT_ROOT}/modules/hardware/nvidia.nix"

assert_file_exists "T2.01.1" "${HOST_DEFAULT}" "Default fleet host config must exist"
if [[ -f "${HOST_DEFAULT}" ]]; then
    assert_file_contains "T2.01.2" "${HOST_DEFAULT}" "nvidia.enable = false;" "Default fleet host must explicitly disable NVIDIA"
fi

if [[ -f "${NVIDIA_MOD}" ]]; then
    assert_file_contains "T2.01.3" "${NVIDIA_MOD}" "lib.mkIf cfg.enable" "NVIDIA module must be strictly guarded behind cfg.enable"
fi

# -----------------------------------------------------------------------------
# Test 2.02: NVIDIA Bus IDs Assertion & Validation Handling
# Verifies that PRIME hybrid configuration enforces valid PCI Bus IDs format
# and prevents unconfigured Bus ID evaluation errors.
# -----------------------------------------------------------------------------
log_info "Running Test 2.02: NVIDIA Bus IDs Format and Validation..."
OPTIONS_MOD="${PROJECT_ROOT}/modules/core/options.nix"
assert_file_exists "T2.02.1" "${OPTIONS_MOD}" "Options module must exist"
if [[ -f "${OPTIONS_MOD}" ]]; then
    assert_file_contains "T2.02.2" "${OPTIONS_MOD}" "intelBusId" "options.nix must declare intelBusId option"
    assert_file_contains "T2.02.3" "${OPTIONS_MOD}" "nvidiaBusId" "options.nix must declare nvidiaBusId option"
    assert_file_contains "T2.02.4" "${OPTIONS_MOD}" "PCI:0:2:0" "Default intelBusId must match surveyed Intel UHD iGPU"
    assert_file_contains "T2.02.5" "${OPTIONS_MOD}" "PCI:1:0:0" "Default nvidiaBusId must match surveyed NVIDIA RTX 2050 dGPU"
    assert_file_matches_regex "T2.02.6" "${OPTIONS_MOD}" 'PCI:[0-9]+:[0-9]+:[0-9]+' "Bus IDs must adhere to standard NixOS PCI:BUS:SLOT:FUNCTION format"
fi

# -----------------------------------------------------------------------------
# Test 2.03: Modern Standby Fallback Safety
# Verifies that systems lacking ACPI S3 deep sleep support can disable s3Sleep,
# and that power.nix guards kernel parameters so the kernel falls back to s2idle.
# -----------------------------------------------------------------------------
log_info "Running Test 2.03: Modern Standby Fallback Safety..."
POWER_MOD="${PROJECT_ROOT}/modules/hardware/power.nix"
assert_file_exists "T2.03.1" "${POWER_MOD}" "Power module must exist"
if [[ -f "${POWER_MOD}" ]]; then
    assert_file_contains "T2.03.2" "${POWER_MOD}" "lib.mkIf cfg.s3Sleep" "S3 deep sleep settings must be guarded by cfg.s3Sleep"
    assert_file_contains "T2.03.3" "${POWER_MOD}" "AllowSuspend = \"yes\";" "Suspend must remain allowed"
fi

# -----------------------------------------------------------------------------
# Test 2.04: Declarative Option Typing & Safe Defaults
# Verifies that every custom option in options.nix is strongly typed with safe defaults
# to prevent fatal type errors when users omit optional parameters.
# -----------------------------------------------------------------------------
log_info "Running Test 2.04: Declarative Option Typing and Safe Defaults..."
if [[ -f "${OPTIONS_MOD}" ]]; then
    assert_file_contains "T2.04.1" "${OPTIONS_MOD}" "lib.types.bool" "Boolean options must use lib.types.bool or mkEnableOption"
    assert_file_contains "T2.04.2" "${OPTIONS_MOD}" "lib.types.enum" "Constrained options must use lib.types.enum"
    assert_file_contains "T2.04.3" "${OPTIONS_MOD}" "lib.types.str" "String options must use lib.types.str"
    assert_file_contains "T2.04.4" "${OPTIONS_MOD}" "lib.types.int" "Integer thresholds must use lib.types.int"
    # Verify display manager enum includes both plasma-login-manager and sddm
    assert_file_contains "T2.04.5" "${OPTIONS_MOD}" '"plasma-login-manager" "sddm"' "Display manager option must support plasma-login-manager and sddm"
fi

# -----------------------------------------------------------------------------
# Test 2.05: Scoped Unfree License Predicate Isolation
# Verifies that proprietary software (NVIDIA, Steam) is admitted via precise whitelist
# rather than an unrestricted, uncurated global allowUnfree = true.
# -----------------------------------------------------------------------------
log_info "Running Test 2.05: Scoped Unfree License Predicate Isolation..."
if [[ -f "${NVIDIA_MOD}" ]]; then
    assert_file_contains "T2.05.1" "${NVIDIA_MOD}" "allowUnfreePredicate" "NVIDIA module must scope unfree licenses with allowUnfreePredicate"
    assert_file_contains "T2.05.2" "${NVIDIA_MOD}" '"nvidia-x11"' "Whitelist must explicitly name nvidia-x11"
    assert_file_contains "T2.05.3" "${NVIDIA_MOD}" '"steam"' "Whitelist must explicitly name steam"
    assert_file_contains "T2.05.4" "${NVIDIA_MOD}" '"steam-run"' "Whitelist must explicitly name steam-run"
fi

# -----------------------------------------------------------------------------
# Test 2.06: Display Manager Fallback Architecture
# Verifies display-manager.nix handles both plasma-login-manager and sddm
# without configuration conflict.
# -----------------------------------------------------------------------------
log_info "Running Test 2.06: Display Manager Fallback Architecture..."
DM_MOD="${PROJECT_ROOT}/modules/desktop/display-manager.nix"
assert_file_exists "T2.06.1" "${DM_MOD}" "Display manager module must exist"
if [[ -f "${DM_MOD}" ]]; then
    assert_file_contains "T2.06.2" "${DM_MOD}" "cfg.displayManager == \"plasma-login-manager\"" "Must have condition for plasma-login-manager"
    assert_file_contains "T2.06.3" "${DM_MOD}" "cfg.displayManager == \"sddm\"" "Must have condition for sddm fallback"
fi

# -----------------------------------------------------------------------------
# Test 2.07: Btrfs Subvolume and Mount Safety Audit
# Verifies that hardware configurations mount Btrfs with standard safe flags (compress=zstd, noatime)
# -----------------------------------------------------------------------------
log_info "Running Test 2.07: Btrfs Subvolume and Mount Safety Audit..."
HW_DEFAULT="${PROJECT_ROOT}/hosts/default/hardware-configuration.nix"
HW_ME="${PROJECT_ROOT}/hosts/me/hardware-configuration.nix"

assert_file_exists "T2.07.1" "${HW_DEFAULT}" "Default hardware configuration must exist"
assert_file_exists "T2.07.2" "${HW_ME}" "Me hardware configuration must exist"

if [[ -f "${HW_ME}" ]]; then
    assert_file_contains "T2.07.3" "${HW_ME}" "compress=zstd" "Btrfs mounts in hosts/me must enable zstd compression"
    assert_file_contains "T2.07.4" "${HW_ME}" "noatime" "Btrfs mounts in hosts/me must enable noatime for SSD endurance"
fi

log_info "Tier 2 complete: All boundary and corner case tests executed."
