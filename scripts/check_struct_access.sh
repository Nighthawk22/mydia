#!/usr/bin/env bash
#
# check_struct_access.sh - Find potential Access behavior issues on structs
#
# Usage: ./scripts/check_struct_access.sh
#

set -e

echo "🔍 Searching for potential Access.get/3 errors on structs..."
echo ""

# List of known struct types in the project
STRUCT_TYPES=(
  "parsed_info"
  "quality"
  "match_result"
  "search_result"
  "quality_info"
  "file_analysis_result"
  "ranked_result"
)

errors_found=0

# Check for get_in usage on structs
echo "📌 Checking for get_in usage on known structs..."
for struct in "${STRUCT_TYPES[@]}"; do
  matches=$(grep -rn "get_in.*${struct}" lib/ --include="*.ex" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "⚠️  Found get_in on '$struct':"
    echo "$matches"
    echo ""
    ((errors_found++))
  fi
done

# Check for bracket notation on struct fields
echo "📌 Checking for bracket notation on struct fields..."
for struct in "${STRUCT_TYPES[@]}"; do
  matches=$(grep -rn "\.${struct}\[" lib/ --include="*.ex" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    echo "⚠️  Found bracket notation on '$struct':"
    echo "$matches"
    echo ""
    ((errors_found++))
  fi
done

# Check for Map.get on struct variables (heuristic - may have false positives)
echo "📌 Checking for Map.get usage (may have false positives)..."
matches=$(grep -rn "Map\.get(%[A-Z]" lib/ --include="*.ex" 2>/dev/null || true)
if [ -n "$matches" ]; then
  echo "⚠️  Found Map.get on potential structs (review manually):"
  echo "$matches"
  echo ""
  ((errors_found++))
fi

# Summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $errors_found -eq 0 ]; then
  echo "✅ No Access.get/3 issues found!"
else
  echo "⚠️  Found $errors_found potential issues - review output above"
  echo ""
  echo "Recommendations:"
  echo "  1. Replace get_in(struct, [:field]) with struct.field"
  echo "  2. Replace struct[:field] with struct.field"
  echo "  3. Replace Map.get(struct, :field) with struct.field"
  echo ""
  echo "See docs/preventing_access_errors.md for more info"
  exit 1
fi
