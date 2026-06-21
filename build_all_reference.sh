#!/usr/bin/env bash

# Treat unset variables as errors and propagate pipeline failures.
set -uo pipefail

# Build all MQOM reference implementations from this repository root.
# Usage:
#   ./build_all_reference.sh
#   ./build_all_reference.sh --clean
#   ./build_all_reference.sh --schemes "cat1 cat3 cat5"
#   ./build_all_reference.sh --schemes "cat1_gf256 cat3_gf16_fast"

clean_first=0
schemes="cat1 cat3 cat5"

usage() {
    cat <<'EOF'
Usage: ./build_all_reference.sh [options]

Options:
  --clean                Run make clean before compilation
  --schemes "..."        Space-separated list passed to manage.py compile
                         Default: "cat1 cat3 cat5" (all categories)
  --help                 Show this help
EOF
}

# Step 1: Parse CLI options.
while [[ $# -gt 0 ]]; do
    case "$1" in
        --clean)
            clean_first=1
            shift
            ;;
        --schemes)
            schemes="${2:-}"
            if [[ -z "${schemes}" ]]; then
                echo "Error: --schemes requires a value." >&2
                exit 1
            fi
            shift 2
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            echo "Error: unknown option '$1'" >&2
            usage
            exit 1
            ;;
    esac
done

# Step 2: Resolve script location and run from repository root.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${script_dir}" || exit 1

# Step 3: Validate required tools and files.
if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 is required." >&2
    exit 1
fi

if [[ ! -f "${script_dir}/manage.py" ]]; then
    echo "Error: manage.py not found in ${script_dir}" >&2
    exit 1
fi

if [[ ${clean_first} -eq 1 ]]; then
    # Optional cleanup before compiling selected schemes.
    make clean || true
fi

# Step 4: Build requested schemes using the documented helper.
# shellcheck disable=SC2206
scheme_array=( ${schemes} )

if [[ ${#scheme_array[@]} -eq 0 ]]; then
    echo "Error: no schemes selected." >&2
    exit 1
fi

echo "Building MQOM reference implementations"
echo "Root: ${script_dir}"
echo "Schemes: ${scheme_array[*]}"

if ! python3 manage.py compile "${scheme_array[@]}"; then
    echo "Build failed for one or more MQOM schemes." >&2
    exit 1
fi

# Step 5: Success status.
echo "All requested MQOM schemes built successfully."
