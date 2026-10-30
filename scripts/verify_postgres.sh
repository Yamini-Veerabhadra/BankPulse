#!/usr/bin/env bash
# Run from repository root against a FRESH, EMPTY PostgreSQL database.
# Example: PGHOST=localhost PGPORT=5432 PGUSER=postgres PGDATABASE=bankpulse bash scripts/verify_postgres.sh
# Supply password through the local environment / interactive psql prompt, never commit it.
set -Eeuo pipefail
cd "$(dirname "$0")/.."
: "${PGHOST:=localhost}"
: "${PGPORT:=5432}"
: "${PGUSER:=postgres}"
: "${PGDATABASE:=bankpulse}"
export PGHOST PGPORT PGUSER PGDATABASE
command -v psql >/dev/null || { echo 'ERROR: native PostgreSQL psql client is not installed' >&2; exit 1; }
LOG_DIR="$(mktemp -d)"
trap 'rm -rf "$LOG_DIR"' EXIT
PSQL=(psql -X -v ON_ERROR_STOP=1)
echo '==> Creating and importing source table (fresh database only)'
"${PSQL[@]}" -f scripts/setup_and_import.psql > "$LOG_DIR/import.txt"
for f in sql/0[2-7]_*.sql; do
  echo "==> PostgreSQL execute: $f"
  "${PSQL[@]}" -f "$f" > "$LOG_DIR/$(basename "$f").log"
done
# These explicit server-side DO assertions fail fast if KPI values or partitions diverge.
echo '==> PostgreSQL native validation assertions'
"${PSQL[@]}" -f sql/08_native_postgres_assertions.sql > "$LOG_DIR/assertions.txt"
echo 'PASS: Original source imported, all six analytic scripts executed in PostgreSQL, and native KPI/segment assertions passed.'
