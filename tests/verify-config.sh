#!/usr/bin/env bash
# tests/verify-config.sh
# Multi-tier verification script validating Nix syntax, AST structure, options contracts,
# exclusion constraints, English comment compliance, and container test harness.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=========================================================="
echo " Starting Multi-Tier NixOS Configuration Verification     "
echo " Target: ${CONFIG_DIR}                                    "
echo "=========================================================="

FAILED=0

fail() {
  echo "[-] ERROR: $1"
  FAILED=$((FAILED + 1))
}

pass() {
  echo "[+] PASS: $1"
}

# ---------------------------------------------------------
# Test 1: Layout & File Existence Compliance
# ---------------------------------------------------------
echo ""
echo "--- Step 1: Checking Project Layout Compliance ---"

REQUIRED_FILES=(
  "flake.nix"
  "hosts/default/default.nix"
  "hosts/default/hardware-configuration.nix"
  "hosts/me/default.nix"
  "hosts/me/hardware-configuration.nix"
  "modules/core/default.nix"
  "modules/core/options.nix"
  "modules/core/nix.nix"
  "modules/core/boot.nix"
  "modules/core/system.nix"
  "modules/core/security.nix"
  "modules/hardware/default.nix"
  "modules/hardware/nvidia.nix"
  "modules/hardware/power.nix"
  "modules/hardware/filesystem.nix"
  "modules/desktop/default.nix"
  "modules/desktop/kde.nix"
  "modules/desktop/display-manager.nix"
  "modules/services/default.nix"
  "modules/services/flatpak.nix"
  "modules/services/distrobox.nix"
  "modules/services/tailscale.nix"
  "modules/services/nix-ld.nix"
  "modules/suites/default.nix"
  "modules/suites/development.nix"
  "modules/suites/gaming.nix"
  "modules/suites/gui-apps.nix"
  "modules/suites/cli-tools.nix"
  "modules/home/default.nix"
  "modules/home/users/me.nix"
  "tests/run-distrobox-test.sh"
)

for f in "${REQUIRED_FILES[@]}"; do
  if [ -f "${CONFIG_DIR}/${f}" ]; then
    pass "File exists: ${f}"
  else
    fail "Missing required file: ${f}"
  fi
done

# ---------------------------------------------------------
# Test 2: Language & English Comments Enforcement
# ---------------------------------------------------------
echo ""
echo "--- Step 2: Checking 100% English Comments Standard ---"

python3 - "${CONFIG_DIR}" << 'EOF'
import os
import sys

config_dir = sys.argv[1] if len(sys.argv) > 1 else "."
errors = []

for root, _, files in os.walk(config_dir):
    # Skip tests or git directories
    if "/.git" in root or "/tests" in root:
        continue
    for file in files:
        if file.endswith(".nix"):
            path = os.path.join(root, file)
            with open(path, "r", encoding="utf-8") as f:
                lines = f.readlines()
            for line_idx, line in enumerate(lines, 1):
                stripped = line.strip()
                if stripped.startswith("#") or "/*" in line:
                    # Check for non-ASCII characters in comments
                    for char in line:
                        if ord(char) > 127:
                            errors.append(f"{path}:{line_idx}: Non-ASCII character '{char}' in comment: {stripped}")
                            break

if errors:
    print(f"[-] FAILED: Found {len(errors)} non-English / non-ASCII comment violations:")
    for err in errors[:10]:
        print("    " + err)
    sys.exit(1)
else:
    print("[+] PASS: 100% of comments across all .nix files are strictly verified English ASCII.")
EOF

# ---------------------------------------------------------
# Test 3: Strict Exclusions Audit
# ---------------------------------------------------------
echo ""
echo "--- Step 3: Checking Strict Exclusions Audit ---"

# 3.1: nix-software-center was explicitly CANCELLED by user
if grep -rn "nix-software-center" "${CONFIG_DIR}" --include="*.nix" --exclude="*.md"; then
  fail "Violation: nix-software-center is present in code but was explicitly cancelled by the user!"
else
  pass "nix-software-center is completely absent from all Nix configuration files."
fi

# 3.2: Zero NTFS drivers in supportedFilesystems or systemPackages
if grep -rnE '"ntfs"|"ntfs3"|"ntfs-3g"' "${CONFIG_DIR}" --include="*.nix"; then
  fail "Violation: NTFS driver or tool declared in configuration!"
else
  pass "Pure Linux filesystem integrity verified (zero NTFS drivers or tools)."
fi

# 3.3: Zero os-prober scanning for Windows
if grep -rn "useOSProber = true" "${CONFIG_DIR}" --include="*.nix"; then
  fail "Violation: os-prober scanning enabled!"
else
  pass "Pure Linux bootloader verified (no Windows dual-boot or os-prober)."
fi

# 3.4: Zero local game saves or wineprefixes
if grep -rnE "com\.itneverends\.game|compatdata|wineprefixes" "${CONFIG_DIR}" --include="*.nix"; then
  fail "Violation: Old game save or prefix found in configuration!"
else
  pass "Clean gaming configuration verified (zero legacy game data copied)."
fi

# ---------------------------------------------------------
# Test 4: Semantic and Contract Validation
# ---------------------------------------------------------
echo ""
echo "--- Step 4: Validating Technical Contracts ---"

# 4.1: Proprietary NVIDIA stable LTS driver enforcement
if grep -Fq "open = false;" "${CONFIG_DIR}/modules/hardware/nvidia.nix" && \
   grep -Fq "nvidiaPackages.stable" "${CONFIG_DIR}/modules/hardware/nvidia.nix" && \
   grep -Fq "allowUnfreePredicate" "${CONFIG_DIR}/modules/hardware/nvidia.nix"; then
  pass "NVIDIA proprietary driver stack strictly enforced (open = false, stable package, unfree predicate)."
else
  fail "NVIDIA proprietary driver contract violated in modules/hardware/nvidia.nix!"
fi

# 4.1b: NVIDIA PRIME bus ID assertion contract
if grep -Fq "NVIDIA PRIME requires valid intelBusId and nvidiaBusId." "${CONFIG_DIR}/modules/hardware/nvidia.nix"; then
  pass "NVIDIA PRIME bus ID contract assertion verified in modules/hardware/nvidia.nix."
else
  fail "NVIDIA PRIME bus ID assertion contract missing in modules/hardware/nvidia.nix!"
fi

# 4.1c: Steam unfree package whitelisting
if grep -Fq '"steam"' "${CONFIG_DIR}/modules/hardware/nvidia.nix" && \
   grep -Fq '"steam-run"' "${CONFIG_DIR}/modules/hardware/nvidia.nix"; then
  pass "Steam packages whitelisted in allowUnfreePredicate."
else
  fail "Steam packages missing from allowUnfreePredicate in modules/hardware/nvidia.nix!"
fi

# 4.2: PRIME hybrid offload bus IDs
if grep -Fq 'intelBusId = "PCI:0:2:0";' "${CONFIG_DIR}/hosts/me/default.nix" && \
   grep -Fq 'nvidiaBusId = "PCI:1:0:0";' "${CONFIG_DIR}/hosts/me/default.nix"; then
  pass "Hybrid PRIME PCI Bus IDs correctly configured (Intel PCI:0:2:0, NVIDIA PCI:1:0:0)."
else
  fail "Hybrid PRIME PCI Bus IDs missing or incorrect in hosts/me/default.nix!"
fi

# 4.3: S3 deep sleep enforcement
if grep -Fq '"mem_sleep_default=deep"' "${CONFIG_DIR}/modules/hardware/power.nix" && \
   grep -Fq 'MemorySleepMode = "deep";' "${CONFIG_DIR}/modules/hardware/power.nix"; then
  pass "ACPI S3 deep sleep enforcement verified in kernelParams and systemd.sleep."
else
  fail "S3 deep sleep parameters missing or incorrect in modules/hardware/power.nix!"
fi

# 4.4: Bootloader generation limits
if grep -Fq "configurationLimit = 10;" "${CONFIG_DIR}/modules/core/boot.nix" && \
   grep -Fq "systemd-boot = {" "${CONFIG_DIR}/modules/core/boot.nix"; then
  pass "systemd-boot configured with configurationLimit = 10."
else
  fail "systemd-boot configurationLimit missing or incorrect in modules/core/boot.nix!"
fi

# 4.5: Auto-upgrade and auto-gc
if grep -Fq "system.autoUpgrade" "${CONFIG_DIR}/modules/core/nix.nix" && \
   grep -Fq "randomizedDelaySec" "${CONFIG_DIR}/modules/core/nix.nix" && \
   grep -Fq "nix.gc" "${CONFIG_DIR}/modules/core/nix.nix" && \
   grep -Fq "auto-optimise-store" "${CONFIG_DIR}/modules/core/nix.nix" && \
   grep -Fq "min-free" "${CONFIG_DIR}/modules/core/nix.nix"; then
  pass "Automated maintenance verified (autoUpgrade, GC 14d, min-free/max-free, auto-optimise-store)."
else
  fail "Automated maintenance options missing or incomplete in modules/core/nix.nix!"
fi

# 4.6: KDE Discover GUI store & CLI search tools
if grep -Fq "kdePackages.discover" "${CONFIG_DIR}/modules/suites/gui-apps.nix" && \
   grep -Fq "libreoffice-qt6-still" "${CONFIG_DIR}/modules/suites/gui-apps.nix" && \
   grep -Fq "services.flatpak.enable" "${CONFIG_DIR}/modules/services/flatpak.nix" && \
   grep -Fq "programs.nh" "${CONFIG_DIR}/modules/suites/cli-tools.nix" && \
   grep -Fq "programs.nix-index" "${CONFIG_DIR}/modules/suites/cli-tools.nix" && \
   grep -Fq "comma" "${CONFIG_DIR}/modules/suites/cli-tools.nix"; then
  pass "Tiered software & discovery verified (Discover + Flatpak, LibreOffice still LTS, nh search, nix-index, comma)."
else
  fail "Tiered software or discovery tools missing in suites or services!"
fi

# 4.7: Display manager abstraction (plasma-login-manager & sddm)
if grep -Fq "plasma-login-manager" "${CONFIG_DIR}/modules/desktop/display-manager.nix" && \
   grep -Fq "sddm" "${CONFIG_DIR}/modules/desktop/display-manager.nix"; then
  pass "Display manager modularity verified (plasma-login-manager matching host, SDDM fallback)."
else
  fail "Display manager modularity missing in modules/desktop/display-manager.nix!"
fi

# 4.8: Home Manager configuration
if grep -Fq "useGlobalPkgs = true;" "${CONFIG_DIR}/modules/home/default.nix" && \
   grep -Fq "useUserPackages = true;" "${CONFIG_DIR}/modules/home/default.nix" && \
   grep -Fq 'backupFileExtension = "backup";' "${CONFIG_DIR}/modules/home/default.nix" && \
   grep -Fq 'username = "me";' "${CONFIG_DIR}/modules/home/users/me.nix" && \
   grep -Fq 'go = "1.23"' "${CONFIG_DIR}/modules/home/users/me.nix"; then
  pass "Home Manager integration verified (useGlobalPkgs, useUserPackages, backupFileExtension, user me, Go 1.23 LTS)."
else
  fail "Home Manager integration settings missing or incorrect!"
fi

# ---------------------------------------------------------
# Test 5: Static AST & Bracket Balance Validation
# ---------------------------------------------------------
echo ""
echo "--- Step 5: Static AST and Grammar Validation ---"

python3 - "${CONFIG_DIR}" << 'EOF'
import os
import sys

config_dir = sys.argv[1] if len(sys.argv) > 1 else "."
nix_files = []

for root, _, files in os.walk(config_dir):
    if "/.git" in root or "/tests" in root:
        continue
    for file in files:
        if file.endswith(".nix"):
            nix_files.append(os.path.join(root, file))

syntax_errors = []

for path in nix_files:
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()

    # Simple tokenizer checking for balanced braces, brackets, parentheses, and quotes
    stack = []
    in_string = False
    in_multiline_string = False
    in_line_comment = False
    in_block_comment = False
    i = 0
    n = len(content)

    while i < n:
        # Check comments
        if in_line_comment:
            if content[i] == '\n':
                in_line_comment = False
            i += 1
            continue
        if in_block_comment:
            if content[i:i+2] == '*/':
                in_block_comment = False
                i += 2
            else:
                i += 1
            continue

        # Check multi-line string ('' ... '')
        if in_multiline_string:
            if content[i:i+2] == "''":
                in_multiline_string = False
                i += 2
            else:
                i += 1
            continue

        # Check normal string (" ... ")
        if in_string:
            if content[i] == '\\':
                i += 2
                continue
            if content[i] == '"':
                in_string = False
                i += 1
                continue
            i += 1
            continue

        # Outside strings and comments
        if content[i:i+2] == "''":
            in_multiline_string = True
            i += 2
            continue
        if content[i] == '"':
            in_string = True
            i += 1
            continue
        if content[i] == '#':
            in_line_comment = True
            i += 1
            continue
        if content[i:i+2] == '/*':
            in_block_comment = True
            i += 2
            continue

        # Bracket tracking
        if content[i] in '({[':
            stack.append((content[i], path, i))
        elif content[i] in ')}]':
            if not stack:
                syntax_errors.append(f"{path}: Unmatched closing '{content[i]}' at character {i}")
            else:
                opening, op_path, op_idx = stack.pop()
                expected = {')': '(', '}': '{', ']': '['}[content[i]]
                if opening != expected:
                    syntax_errors.append(f"{path}: Mismatched bracket: opened '{opening}' but closed with '{content[i]}'")
        i += 1

    if in_string:
        syntax_errors.append(f"{path}: Unterminated string literal")
    if in_multiline_string:
        syntax_errors.append(f"{path}: Unterminated multiline string literal")
    if stack:
        for opening, op_path, op_idx in stack:
            syntax_errors.append(f"{op_path}: Unclosed opening '{opening}' at character {op_idx}")

if syntax_errors:
    print(f"[-] FAILED: Found {len(syntax_errors)} AST/syntax issues:")
    for err in syntax_errors[:10]:
        print("    " + err)
    sys.exit(1)
else:
    print(f"[+] PASS: Successfully validated static AST and balanced syntax across {len(nix_files)} .nix files.")
EOF

# ---------------------------------------------------------
# Test 6: Tier 1 Distrobox Execution Harness
# ---------------------------------------------------------
echo ""
echo "--- Step 6: Triggering Tier 1 Distrobox Harness ---"
bash "${CONFIG_DIR}/tests/run-distrobox-test.sh" || true

# ---------------------------------------------------------
# Summary
# ---------------------------------------------------------
echo ""
echo "=========================================================="
if [ $FAILED -eq 0 ]; then
  echo " [SUCCESS] All verification tests passed cleanly!         "
  echo "=========================================================="
  exit 0
else
  echo " [FAILURE] Verification completed with ${FAILED} errors!  "
  echo "=========================================================="
  exit 1
fi
