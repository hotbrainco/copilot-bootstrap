#!/usr/bin/env bash
set -euo pipefail
# Auto-generate rich release notes between the latest two semantic tags.
# Zero args. Produces Markdown to stdout.
# Env flags:
#   RELEASE_NOTES_JSON_OUT=path  (optional JSON dump with structured data)

SEMVER_GLOB='v[0-9]*.[0-9]*.[0-9]*'
JSON_OUT="${RELEASE_NOTES_JSON_OUT:-}"

die() { echo "ERROR: $*" >&2; exit 1; }

all_tags=$(git tag --list "$SEMVER_GLOB" --sort=-version:refname || true)
[[ -n "$all_tags" ]] || die "No semantic version tags found"
NEW_TAG=""; PREV_TAG=""; idx=0
for t in $all_tags; do
  if [[ $idx -eq 0 ]]; then NEW_TAG="$t"; elif [[ $idx -eq 1 ]]; then PREV_TAG="$t"; break; fi; idx=$((idx+1)); done
[[ -n "$PREV_TAG" ]] || die "Need at least two tags to generate release notes"
RANGE="$PREV_TAG..$NEW_TAG"

# Use unit separator (US \x1f) between fields and record separator (RS \x1e) between commits.
raw=$(git log --no-merges --format='%H%x1f%s%x1f%b%x1e' "$RANGE" || true)

# Accumulators
sec_breaking=""; sec_feat=""; sec_fix=""; sec_perf=""; sec_ref=""; sec_docs=""; sec_tests=""; sec_chore=""; notes=""; uncategorized=""

append() { local var="$1" line="$2"; eval "cur=\"\${$var}\"" || cur=""; eval "$var=\"$cur$line\\n\""; }
normalize_type() { printf '%s' "$1" | tr 'A-Z' 'a-z'; }

# Parse each commit
while IFS=$'\x1e' read -r entry; do
  [[ -z "$entry" ]] && continue
  IFS=$'\x1f' read -r hash subject body <<<"$entry"
  [[ -z "$hash" ]] && continue
  # Skip if subject empty
  [[ -z "$subject" ]] && continue
  if [[ ! "$subject" =~ ^([a-zA-Z]+)(!?)\:?\s(.*)$ ]]; then
    uncategorized+="- ${subject} (${hash:0:7})\n"; continue
  fi
  raw_type="${BASH_REMATCH[1]}"; bang="${BASH_REMATCH[2]}"; rest="${BASH_REMATCH[3]}"
  base_type=$(normalize_type "$raw_type")
  breaking_local=""
  [[ -n "$bang" ]] && breaking_local="$subject"
  entry_line="- ${rest} (${hash:0:7})"
  case "$base_type" in
    feat) append sec_feat "$entry_line" ;;
    fix) append sec_fix "$entry_line" ;;
    perf) append sec_perf "$entry_line" ;;
    refactor) append sec_ref "$entry_line" ;;
    docs) append sec_docs "$entry_line" ;;
    test|tests) append sec_tests "$entry_line" ;;
    chore|ci|build) append sec_chore "$entry_line" ;;
    *) uncategorized+="- ${subject} (${hash:0:7})\n" ;;
  esac
  if [[ -n "$body" ]]; then
    while IFS= read -r line; do
      case "$line" in
        BREAKING\ CHANGE:*) breaking_local="${breaking_local}
${line#BREAKING CHANGE: }" ;;
        BREAKING:*) breaking_local="${breaking_local}
${line#BREAKING: }" ;;
        [Nn]ote:*) notes+="- ${line#*: } (${hash:0:7})\n" ;;
      esac
    done <<<"$body"
  fi
  if [[ -n "$breaking_local" ]]; then
    while IFS= read -r bl; do
      [[ -z "$bl" ]] && continue
      append sec_breaking "- $bl (${hash:0:7})"
    done <<<"$breaking_local"
  fi

done <<<"$raw"

count_lines() { printf '%s' "$1" | grep -v '^$' 2>/dev/null || true | wc -l | tr -d ' '; }

n_break=$(count_lines "$sec_breaking")
n_feat=$(count_lines "$sec_feat")
n_fix=$(count_lines "$sec_fix")
n_docs=$(count_lines "$sec_docs")
n_ref=$(count_lines "$sec_ref")
n_perf=$(count_lines "$sec_perf")
n_tests=$(count_lines "$sec_tests")
n_chore=$(count_lines "$sec_chore")
n_uncat=$(count_lines "$uncategorized")
n_notes=$(count_lines "$notes")

slug=$(git remote get-url origin 2>/dev/null | sed -E 's#(git@github.com:|https://github.com/)##;s/.git$//') || true

# Markdown output
cat <<EOF
## Release $NEW_TAG
${slug:+Compare: https://github.com/$slug/compare/$PREV_TAG...$NEW_TAG}

_Summary_: breaking=$n_break feat=$n_feat fix=$n_fix docs=$n_docs refactor=$n_ref perf=$n_perf tests=$n_tests chore=$n_chore misc=$n_uncat notes=$n_notes
EOF

print_section() { local title="$1" data="$2"; [[ -z "$data" ]] && return 0; echo "### $title"; printf '%s' "$data" | sed -E '/^\s*$/d'; echo; }
print_section "Breaking Changes" "$sec_breaking"
print_section "Features" "$sec_feat"
print_section "Fixes" "$sec_fix"
print_section "Performance" "$sec_perf"
print_section "Refactors" "$sec_ref"
print_section "Docs" "$sec_docs"
print_section "Tests" "$sec_tests"
print_section "Chore / Internal" "$sec_chore"
print_section "Uncategorized" "$uncategorized"
print_section "Notes" "$notes"

if [[ -n "$JSON_OUT" ]]; then
  printf '{"newTag":"%s","previousTag":"%s","counts":{"breaking":%s,"features":%s,"fixes":%s,"docs":%s,"refactors":%s,"perf":%s,"tests":%s,"chore":%s,"uncategorized":%s,"notes":%s}}\n' \
    "$NEW_TAG" "$PREV_TAG" \
    "$n_break" "$n_feat" "$n_fix" "$n_docs" "$n_ref" "$n_perf" "$n_tests" "$n_chore" "$n_uncat" "$n_notes" > "$JSON_OUT"
fi