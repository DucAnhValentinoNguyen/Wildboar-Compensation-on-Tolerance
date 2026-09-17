#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 -m http.server "${PORT:-8000}" \
  --bind "${BIND:-0.0.0.0}" \
  --directory "$ROOT/results"
