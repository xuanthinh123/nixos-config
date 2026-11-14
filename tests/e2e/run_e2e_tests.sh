#!/usr/bin/env bash
# tests/e2e/run_e2e_tests.sh
# Master E2E Test Suite Runner for NixOS Fleet Configuration Project
# Executes 4-tier requirement-driven verification methodology:
#   Tier 1: Feature Coverage (Flakes, Home Manager, pure Linux boot/filesystems, NVIDIA, S3 sleep, auto-maintenance, KDE, Discover)
#   Tier 2: Boundary & Corner Cases (Non-NVIDIA baseline, Bus IDs validation, modern standby fallback, typing/defaults)
#   Tier 3: Cross-Feature Combinations (PRIME + Steam GameMode, autoUpgrade + GC, dotfile backup collision prevention)
#   Tier 4: Real-World Scenarios (AST syntax balancing, import graph resolution, zero legacy game save audit, Distrobox harness)
#
# Generates TAP (Test Anything Protocol) and structured summary reports.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

SELECTED_TIER="all"
VERBOSE=false

show_help() {
    cat << EOF
NixOS Fleet Configuration E2E Test Suite Runner

Usage:
  ./run_e2e_tests.sh [OPTIONS]

Options:
  --all             Execute all 4 verification tiers (default)
  --tier=N          Execute a single tier (1, 2, 3, or 4)
  --verbose         Enable detailed diagnostic output
  --help, -h        Display this help message

Tiers:
  Tier 1            Feature Coverage Verification (R1-R5, R7, Flakes, KDE, NVIDIA, S3)
  Tier 2            Boundary & Corner Cases (Non-NVIDIA, Bus IDs, Modern Standby, Types)
  Tier 3            Cross-Feature Interactions (PRIME + Steam, GC + Upgrade, HM Collision)
  Tier 4            Real-World Scenarios (AST Parsing, Leakage Audit, Distrobox Harness)

EOF
}

# Parse command line arguments
for arg in "$@"; do
    case "${arg}" in
        --all)
            SELECTED_TIER="all"
            ;;
        --tier=1)
            SELECTED_TIER="1"
            ;;
        --tier=2)
            SELECTED_TIER="2"
            ;;
        --tier=3)
            SELECTED_TIER="3"
            ;;
        --tier=4)
            SELECTED_TIER="4"
            ;;
        --verbose)
            VERBOSE=true
            ;;
        --help|-h)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: ${arg}"
            show_help
            exit 2
            ;;
    esac
done

echo -e "${COLOR_BOLD}${COLOR_BLUE}======================================================================${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_BLUE}   NixOS Fleet Configuration — End-to-End (E2E) Test Suite            ${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_BLUE}   Target: ${PROJECT_ROOT}                                             ${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_BLUE}   Mode  : Tier ${SELECTED_TIER}                                       ${COLOR_RESET}"
echo -e "${COLOR_BOLD}${COLOR_BLUE}======================================================================${COLOR_RESET}"

START_TIME=$(date +%s)

# Execute selected tiers within current environment to accumulate metrics
if [[ "${SELECTED_TIER}" == "all" || "${SELECTED_TIER}" == "1" ]]; then
    source "${SCRIPT_DIR}/tier1_feature_coverage.sh"
fi

if [[ "${SELECTED_TIER}" == "all" || "${SELECTED_TIER}" == "2" ]]; then
    source "${SCRIPT_DIR}/tier2_boundary_corner.sh"
fi

if [[ "${SELECTED_TIER}" == "all" || "${SELECTED_TIER}" == "3" ]]; then
    source "${SCRIPT_DIR}/tier3_cross_feature.sh"
fi

if [[ "${SELECTED_TIER}" == "all" || "${SELECTED_TIER}" == "4" ]]; then
    source "${SCRIPT_DIR}/tier4_real_world.sh"
fi

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Generate final reports and summaries
generate_reports

echo -e "Execution completed in ${DURATION} second(s)."

if [[ ${TESTS_FAILED} -gt 0 ]]; then
    echo -e "${COLOR_BOLD}${COLOR_RED}[FAILED] E2E Suite encountered ${TESTS_FAILED} failure(s).${COLOR_RESET}"
    exit 1
else
    echo -e "${COLOR_BOLD}${COLOR_GREEN}[SUCCESS] All ${TESTS_PASSED} E2E test cases passed successfully!${COLOR_RESET}"
    exit 0
fi
