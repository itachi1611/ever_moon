#!/bin/bash
# check_architecture.sh — Lint Flutter project for architecture violations
# Based on project structure: pages/, services/, repositories/, models/
#
# Usage: ./scripts/check_architecture.sh [options]
#   --lib <path>        Path to lib/ directory (default: lib)
#   --feature <name>    Check a single feature only
#   --strict            Exit with code 1 if any violations found (useful in CI)
#
# Examples:
#   ./scripts/check_architecture.sh
#   ./scripts/check_architecture.sh --feature product
#   ./scripts/check_architecture.sh --strict

set -e

LIB_PATH="lib"
FEATURE_FILTER=""
STRICT=false
VIOLATIONS=0
WARNINGS=0

# ── Parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --lib) LIB_PATH="$2"; shift 2 ;;
    --feature) FEATURE_FILTER="$2"; shift 2 ;;
    --strict) STRICT=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

PAGES_DIR="${LIB_PATH}/pages"
SERVICES_DIR="${LIB_PATH}/services"
REPOS_DIR="${LIB_PATH}/repositories"
MODELS_DIR="${LIB_PATH}/models"

RED='\033[0;31m'
YELLOW='\033[0;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
RESET='\033[0m'

violation() { echo -e "  ${RED}[VIOLATION]${RESET} $1"; ((VIOLATIONS++)); }
warning()   { echo -e "  ${YELLOW}[WARNING]${RESET}   $1"; ((WARNINGS++)); }
ok()        { echo -e "  ${GREEN}[OK]${RESET}        $1"; }

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${CYAN}  Architecture Check — ${LIB_PATH}${RESET}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

if [ ! -d "$PAGES_DIR" ]; then
  echo "❌  pages/ directory not found at: ${PAGES_DIR}"
  exit 1
fi

# ── Determine features to check ───────────────────────────────────────────────
if [ -n "$FEATURE_FILTER" ]; then
  FEATURES=("${PAGES_DIR}/${FEATURE_FILTER}")
else
  mapfile -t FEATURES < <(find "$PAGES_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
fi

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 1 — pages/ must not import from repositories/ directly
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[1] Pages importing repositories/ directly${RESET}"
FOUND=false
for feature_dir in "${FEATURES[@]}"; do
  matches=$(grep -rl "repositories/" "${feature_dir}" 2>/dev/null | grep "\.dart$" | grep -v "_test\.dart" || true)
  for f in $matches; do
    violation "$(basename "$f") imports from repositories/ — use services/ instead"
    FOUND=true
  done
done
$FOUND || ok "No pages import repositories/ directly"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 2 — pages/ must not import from models/data_class/ (raw models)
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[2] Pages importing raw models (data_class/)${RESET}"
FOUND=false
for feature_dir in "${FEATURES[@]}"; do
  matches=$(grep -rl "models/data_class" "${feature_dir}" 2>/dev/null | grep "\.dart$" || true)
  for f in $matches; do
    violation "$(basename "$f") imports models/data_class/ — use entities instead"
    FOUND=true
  done
done
$FOUND || ok "No pages use raw models"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 3 — models/entities/ must not import Flutter packages
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[3] Entities importing Flutter packages${RESET}"
FOUND=false
if [ -d "${MODELS_DIR}/entities" ]; then
  matches=$(grep -rl "package:flutter/" "${MODELS_DIR}/entities" 2>/dev/null | grep "\.dart$" || true)
  for f in $matches; do
    violation "$(basename "$f") imports Flutter — entities must be pure Dart"
    FOUND=true
  done
fi
$FOUND || ok "Entities are Flutter-free"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 4 — models/entities/ must not import json_annotation (entities ≠ models)
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[4] Entities using json_annotation (should be in data_class/)${RESET}"
FOUND=false
if [ -d "${MODELS_DIR}/entities" ]; then
  matches=$(grep -rl "json_annotation\|@JsonSerializable" "${MODELS_DIR}/entities" 2>/dev/null | grep "\.dart$" || true)
  for f in $matches; do
    violation "$(basename "$f") uses json_annotation — move to models/data_class/"
    FOUND=true
  done
fi
$FOUND || ok "Entities have no json_annotation"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 5 — services/ must not import network/ or Dio directly
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[5] Services importing network/ or Dio directly${RESET}"
FOUND=false
if [ -d "$SERVICES_DIR" ]; then
  matches=$(grep -rl "package:dio\|network/api_util\|import.*network/" "${SERVICES_DIR}" 2>/dev/null | grep "\.dart$" || true)
  for f in $matches; do
    violation "$(basename "$f") imports network layer — call repositories instead"
    FOUND=true
  done
fi
$FOUND || ok "Services do not touch network layer"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 6 — cubits must not import repositories/ directly
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[6] Cubits bypassing services (importing repositories/ directly)${RESET}"
FOUND=false
for feature_dir in "${FEATURES[@]}"; do
  cubit_files=$(find "${feature_dir}" -name "*_cubit.dart" 2>/dev/null || true)
  for f in $cubit_files; do
    if grep -q "repositories/" "$f" 2>/dev/null; then
      violation "$(basename "$f") imports repositories/ — route through services/"
      FOUND=true
    fi
  done
done
$FOUND || ok "Cubits go through services"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 7 — models/data_class/ must have matching .g.dart (build_runner ran)
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[7] Models missing generated .g.dart file${RESET}"
FOUND=false
if [ -d "${MODELS_DIR}/data_class" ]; then
  for f in "${MODELS_DIR}/data_class"/*.dart; do
    [[ "$f" == *.g.dart ]] && continue
    base="${f%.dart}"
    if grep -q "@JsonSerializable" "$f" 2>/dev/null; then
      if [ ! -f "${base}.g.dart" ]; then
        warning "$(basename "$f") is @JsonSerializable but ${base}.g.dart missing — run build_runner"
        FOUND=true
      fi
    fi
  done
fi
$FOUND || ok "All models have .g.dart files"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 8 — state files must use sealed class
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[8] State files not using sealed class${RESET}"
FOUND=false
for feature_dir in "${FEATURES[@]}"; do
  state_files=$(find "${feature_dir}" -name "*_state.dart" 2>/dev/null || true)
  for f in $state_files; do
    if ! grep -q "^sealed class" "$f" 2>/dev/null; then
      warning "$(basename "$f") does not use sealed class — consider upgrading for exhaustive switch"
      FOUND=true
    fi
  done
done
$FOUND || ok "All state files use sealed class"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# CHECK 9 — page files must not contain business logic (direct API calls)
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}[9] Business logic in page files (direct API/service calls)${RESET}"
FOUND=false
for feature_dir in "${FEATURES[@]}"; do
  page_files=$(find "${feature_dir}" -name "*_page.dart" 2>/dev/null || true)
  for f in $page_files; do
    if grep -qE "await.*service|await.*repositor|ApiUtil\." "$f" 2>/dev/null; then
      violation "$(basename "$f") contains direct service/API calls — move to cubit"
      FOUND=true
    fi
  done
done
$FOUND || ok "Pages contain no business logic"
echo ""

# ═══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ═══════════════════════════════════════════════════════════════════════════════
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
if [ "$VIOLATIONS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
  echo -e "${GREEN}  ✅  All checks passed!${RESET}"
else
  [ "$VIOLATIONS" -gt 0 ] && echo -e "  ${RED}Violations: ${VIOLATIONS}${RESET}"
  [ "$WARNINGS" -gt 0 ]   && echo -e "  ${YELLOW}Warnings:   ${WARNINGS}${RESET}"
fi
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""

if $STRICT && [ "$VIOLATIONS" -gt 0 ]; then
  exit 1
fi
