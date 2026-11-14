#!/usr/bin/env bash
# tests/e2e/common.sh
# Shared assertion library, test harness, and reporting utilities for NixOS Fleet E2E tests.
# All comments and reporting output are strictly written in English.

set -uo pipefail

# ANSI color codes for terminal diagnostics
COLOR_RESET="\033[0m"
COLOR_BOLD="\033[1m"
COLOR_GREEN="\033[32m"
COLOR_RED="\033[31m"
COLOR_YELLOW="\033[33m"
COLOR_CYAN="\033[36m"
COLOR_BLUE="\033[34m"
COLOR_GRAY="\033[90m"

# Guard against variable reset when sourced multiple times across tiers
if [[ -z "${COMMON_SOURCED:-}" ]]; then
    COMMON_SOURCED=1
    TESTS_TOTAL=0
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_SKIPPED=0
    declare -a TEST_RESULTS=()
fi

# Determine project root directory (nixos_config)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Logging helper functions
log_info() {
    echo -e "${COLOR_BLUE}[INFO]${COLOR_RESET} $*"
}

log_pass() {
    echo -e "${COLOR_GREEN}[PASS]${COLOR_RESET} $*"
}

log_fail() {
    echo -e "${COLOR_RED}[FAIL]${COLOR_RESET} $*"
}

log_warn() {
    echo -e "${COLOR_YELLOW}[WARN]${COLOR_RESET} $*"
}

log_tier() {
    local tier_title="$1"
    echo -e "\n${COLOR_BOLD}${COLOR_CYAN}======================================================================${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}  ${tier_title}${COLOR_RESET}"
    echo -e "${COLOR_BOLD}${COLOR_CYAN}======================================================================${COLOR_RESET}\n"
}

# Records test outcome into metrics and structured log
record_test() {
    local test_id="$1"
    local status="$2" # PASS, FAIL, SKIP
    local description="$3"

    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    if [[ "${status}" == "PASS" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_pass "${test_id}: ${description}"
    elif [[ "${status}" == "SKIP" ]]; then
        TESTS_SKIPPED=$((TESTS_SKIPPED + 1))
        log_warn "${test_id} [SKIPPED]: ${description}"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_fail "${test_id}: ${description}"
    fi

    TEST_RESULTS+=("${test_id}|${status}|${description}")
}

# Assertion: file exists
assert_file_exists() {
    local test_id="$1"
    local file_path="$2"
    local description="${3:-File ${file_path} must exist}"

    if [[ -f "${file_path}" ]]; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        record_test "${test_id}" "FAIL" "${description} (missing file: ${file_path})"
        return 1
    fi
}

# Assertion: file does NOT exist (for negative leakage tests)
assert_file_not_exists() {
    local test_id="$1"
    local file_path="$2"
    local description="${3:-File ${file_path} must not exist}"

    if [[ ! -e "${file_path}" ]]; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        record_test "${test_id}" "FAIL" "${description} (found unwanted artifact: ${file_path})"
        return 1
    fi
}

# Assertion: directory exists
assert_dir_exists() {
    local test_id="$1"
    local dir_path="$2"
    local description="${3:-Directory ${dir_path} must exist}"

    if [[ -d "${dir_path}" ]]; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        record_test "${test_id}" "FAIL" "${description} (missing directory: ${dir_path})"
        return 1
    fi
}

# Assertion: file contains exact literal string
assert_file_contains() {
    local test_id="$1"
    local file_path="$2"
    local expected_str="$3"
    local description="${4:-File ${file_path} must contain '${expected_str}'}"

    if [[ ! -f "${file_path}" ]]; then
        record_test "${test_id}" "FAIL" "${description} (file not found: ${file_path})"
        return 1
    fi

    if grep -F -q -- "${expected_str}" "${file_path}"; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        record_test "${test_id}" "FAIL" "${description} (pattern not found in ${file_path})"
        return 1
    fi
}

# Assertion: file does NOT contain string (negative constraint)
assert_file_not_contains() {
    local test_id="$1"
    local file_path="$2"
    local forbidden_str="$3"
    local description="${4:-File ${file_path} must NOT contain '${forbidden_str}'}"

    if [[ ! -f "${file_path}" ]]; then
        record_test "${test_id}" "FAIL" "${description} (file not found: ${file_path})"
        return 1
    fi

    if ! grep -F -q -- "${forbidden_str}" "${file_path}"; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        local matched_line
        matched_line="$(grep -F -n -- "${forbidden_str}" "${file_path}" | head -n 1)"
        record_test "${test_id}" "FAIL" "${description} (found forbidden text at line: ${matched_line})"
        return 1
    fi
}

# Assertion: code lines (ignoring comments) must NOT contain forbidden string
assert_code_not_contains() {
    local test_id="$1"
    local file_path="$2"
    local forbidden_str="$3"
    local description="${4:-File ${file_path} code must NOT contain '${forbidden_str}'}"

    if [[ ! -f "${file_path}" ]]; then
        record_test "${test_id}" "FAIL" "${description} (file not found: ${file_path})"
        return 1
    fi

    local code_only
    code_only=$(sed -e 's/#.*//' "${file_path}")
    if ! echo "${code_only}" | grep -F -q -- "${forbidden_str}"; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        local matched_line
        matched_line=$(echo "${code_only}" | grep -F -n -- "${forbidden_str}" | head -n 1)
        record_test "${test_id}" "FAIL" "${description} (found in code: ${matched_line})"
        return 1
    fi
}

# Assertion: file matches regular expression (extended grep)
assert_file_matches_regex() {
    local test_id="$1"
    local file_path="$2"
    local regex_pattern="$3"
    local description="${4:-File ${file_path} must match regex '${regex_pattern}'}"

    if [[ ! -f "${file_path}" ]]; then
        record_test "${test_id}" "FAIL" "${description} (file not found: ${file_path})"
        return 1
    fi

    if grep -E -q -- "${regex_pattern}" "${file_path}"; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        record_test "${test_id}" "FAIL" "${description} (regex not matched in ${file_path})"
        return 1
    fi
}

# Assertion: file matches multiline regular expression (via Python re with DOTALL)
assert_file_matches_multiline_regex() {
    local test_id="$1"
    local file_path="$2"
    local regex_pattern="$3"
    local description="${4:-File ${file_path} must match multiline pattern}"

    if [[ ! -f "${file_path}" ]]; then
        record_test "${test_id}" "FAIL" "${description} (file not found: ${file_path})"
        return 1
    fi

    local match_found
    match_found=$(python3 - "${file_path}" "${regex_pattern}" << 'EOF'
import sys
import re

filename = sys.argv[1]
pattern = sys.argv[2]

with open(filename, 'r', encoding='utf-8') as f:
    content = f.read()

if re.search(pattern, content, re.DOTALL | re.MULTILINE):
    print("MATCH")
    sys.exit(0)
else:
    print("NO_MATCH")
    sys.exit(1)
EOF
)
    if [[ $? -eq 0 && "${match_found}" == "MATCH" ]]; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        record_test "${test_id}" "FAIL" "${description} (multiline pattern not matched in ${file_path})"
        return 1
    fi
}

# Assertion: code lines (ignoring comments) must NOT match regular expression
assert_code_not_matches_regex() {
    local test_id="$1"
    local file_path="$2"
    local regex_pattern="$3"
    local description="${4:-File ${file_path} code must NOT match regex '${regex_pattern}'}"

    if [[ ! -f "${file_path}" ]]; then
        record_test "${test_id}" "FAIL" "${description} (file not found: ${file_path})"
        return 1
    fi

    local code_only
    code_only=$(sed -e 's/#.*//' "${file_path}")
    if ! echo "${code_only}" | grep -E -q -- "${regex_pattern}"; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        local matched_line
        matched_line=$(echo "${code_only}" | grep -E -n -- "${regex_pattern}" | head -n 1)
        record_test "${test_id}" "FAIL" "${description} (found in code: ${matched_line})"
        return 1
    fi
}

# Assertion: check bracket and quote balance in a Nix file (offline AST parser)
assert_nix_syntax_well_formed() {
    local test_id="$1"
    local nix_file="$2"
    local description="${3:-Nix file ${nix_file} must have balanced braces and well-formed syntax}"

    if [[ ! -f "${nix_file}" ]]; then
        record_test "${test_id}" "FAIL" "${description} (file not found: ${nix_file})"
        return 1
    fi

    local parse_result
    parse_result=$(python3 - "${nix_file}" << 'EOF'
import sys

filename = sys.argv[1]
with open(filename, 'r', encoding='utf-8') as f:
    content = f.read()

stack = []
pairs = { '}': '{', ']': '[', ')': '(' }
in_line_comment = False
in_block_comment = False
in_double_quote = False
in_multiline_str = False

i = 0
n = len(content)
line = 1
col = 1

while i < n:
    ch = content[i]
    if ch == '\n':
        line += 1
        col = 1
        in_line_comment = False
        i += 1
        continue

    # Handle line comments
    if not in_block_comment and not in_double_quote and not in_multiline_str:
        if ch == '#':
            in_line_comment = True
            i += 1
            col += 1
            continue

    if in_line_comment:
        i += 1
        col += 1
        continue

    # Handle block comments /* ... */
    if not in_line_comment and not in_double_quote and not in_multiline_str:
        if ch == '/' and i + 1 < n and content[i+1] == '*':
            in_block_comment = True
            i += 2
            col += 2
            continue

    if in_block_comment:
        if ch == '*' and i + 1 < n and content[i+1] == '/':
            in_block_comment = False
            i += 2
            col += 2
            continue
        i += 1
        col += 1
        continue

    # Handle multiline string '' ... ''
    if not in_line_comment and not in_block_comment and not in_double_quote:
        if ch == "'" and i + 1 < n and content[i+1] == "'":
            in_multiline_str = not in_multiline_str
            i += 2
            col += 2
            continue

    if in_multiline_str:
        i += 1
        col += 1
        continue

    # Handle double quote string " ... "
    if not in_line_comment and not in_block_comment:
        if ch == '"' and (i == 0 or content[i-1] != '\\'):
            in_double_quote = not in_double_quote
            i += 1
            col += 1
            continue

    if in_double_quote:
        i += 1
        col += 1
        continue

    # Check brackets
    if ch in '{[(':
        stack.append((ch, line, col))
    elif ch in '}])':
        if not stack:
            print(f"Unmatched closing '{ch}' at line {line}:{col}")
            sys.exit(1)
        expected = pairs[ch]
        top, top_line, top_col = stack.pop()
        if top != expected:
            print(f"Mismatched delimiter: opened '{top}' at {top_line}:{top_col}, closed with '{ch}' at {line}:{col}")
            sys.exit(1)

    i += 1
    col += 1

if stack:
    top, top_line, top_col = stack[-1]
    print(f"Unclosed delimiter '{top}' opened at line {top_line}:{top_col}")
    sys.exit(1)

print("OK")
sys.exit(0)
EOF
)
    local exit_code=$?
    if [[ ${exit_code} -eq 0 && "${parse_result}" == "OK" ]]; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        record_test "${test_id}" "FAIL" "${description} (syntax error: ${parse_result})"
        return 1
    fi
}

# Assertion: audit 100% English comments in a Nix file
assert_english_comments() {
    local test_id="$1"
    local nix_file="$2"
    local description="${3:-Nix file ${nix_file} must have 100% English comments}"

    if [[ ! -f "${nix_file}" ]]; then
        record_test "${test_id}" "FAIL" "${description} (file not found: ${nix_file})"
        return 1
    fi

    local check_result
    check_result=$(python3 - "${nix_file}" << 'EOF'
import sys
import re

filename = sys.argv[1]
with open(filename, 'r', encoding='utf-8') as f:
    lines = f.readlines()

vietnamese_pattern = re.compile(r'[àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ]')

violations = []
in_block_comment = False

for idx, line in enumerate(lines, start=1):
    # Check line comments
    if '#' in line:
        comment_part = line.split('#', 1)[1]
        if vietnamese_pattern.search(comment_part):
            violations.append((idx, line.strip()))

    # Check block comments
    if '/*' in line:
        in_block_comment = True
    if in_block_comment:
        if vietnamese_pattern.search(line):
            violations.append((idx, line.strip()))
        if '*/' in line:
            in_block_comment = False

if violations:
    print(f"Non-English comments detected at line {violations[0][0]}: {violations[0][1]}")
    sys.exit(1)

print("OK")
sys.exit(0)
EOF
)
    local exit_code=$?
    if [[ ${exit_code} -eq 0 && "${check_result}" == "OK" ]]; then
        record_test "${test_id}" "PASS" "${description}"
        return 0
    else
        record_test "${test_id}" "FAIL" "${description} (${check_result})"
        return 1
    fi
}

# Generate summary report and TAP / JUnit outputs
generate_reports() {
    local report_dir="${PROJECT_ROOT}/tests/e2e/reports"
    mkdir -p "${report_dir}"

    local tap_file="${report_dir}/results.tap"
    local summary_file="${report_dir}/summary.txt"

    # Write TAP file
    {
        echo "TAP version 13"
        echo "1..${TESTS_TOTAL}"
        local counter=1
        for res in "${TEST_RESULTS[@]}"; do
            IFS='|' read -r tid status desc <<< "${res}"
            if [[ "${status}" == "PASS" ]]; then
                echo "ok ${counter} - ${tid}: ${desc}"
            elif [[ "${status}" == "SKIP" ]]; then
                echo "ok ${counter} - # SKIP ${tid}: ${desc}"
            else
                echo "not ok ${counter} - ${tid}: ${desc}"
            fi
            counter=$((counter + 1))
        done
    } > "${tap_file}"

    # Write summary file
    {
        echo "=================================================="
        echo "  NixOS Fleet Configuration E2E Test Suite Summary"
        echo "  Date: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo "=================================================="
        echo "Total Tests Executed : ${TESTS_TOTAL}"
        echo "Passed Tests         : ${TESTS_PASSED}"
        echo "Failed Tests         : ${TESTS_FAILED}"
        echo "Skipped Tests        : ${TESTS_SKIPPED}"
        if [[ ${TESTS_FAILED} -eq 0 ]]; then
            echo "Final Verdict        : ALL TESTS PASSED (PASS)"
        else
            echo "Final Verdict        : SOME TESTS FAILED (FAIL)"
        fi
        echo "=================================================="
    } > "${summary_file}"

    # Print summary to stdout
    echo ""
    cat "${summary_file}"
    echo -e "\nDetailed TAP report generated at: ${COLOR_CYAN}${tap_file}${COLOR_RESET}"
}
