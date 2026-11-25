#!/usr/bin/env bash
# A small script that ShellCheck should pass.
set -euo pipefail
name="${1:-world}"
echo "hello, ${name}"
