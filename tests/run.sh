#!/usr/bin/env bash
# Run the skill on each test case and check the results with plain shell
# checks (no model grades anything).
#
#   tests/run.sh                      run every case in tests/cases/
#   tests/run.sh resume-handles-answers-and-feedback
#   tests/run.sh --check <run dir>    re-check a finished run; no model call
#
# Each case is one real `claude -p` run on your Claude login (subscription
# usage, or billed if ANTHROPIC_API_KEY is set). Never run this without the
# user's go-ahead.
#
# A case is tests/cases/<name>/ with prompt.md (the user's message), check.sh
# (checks, using tests/lib.sh) and optionally files/ (copied over the
# tests/fixtures/todo-app project). Each run is kept in its own directory:
# project/ (what the agent worked on), result.json and final.md.
#
# Environment: ASKLOOP_TEST_MODEL (default: your default model),
# ASKLOOP_TEST_BUDGET (per-run ceiling in USD, default 1).
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TESTS=$ROOT/tests

check_run() { # RUN_DIR
  local run=$1 name
  name=$(cat "$run/case")
  WORK=$run/project FINAL=$run/final.md
  echo "$name ($run)"
  # Without a reply there's nothing to check, and some checks would pass
  # vacuously.
  if [ ! -s "$FINAL" ]; then
    printf '  FAIL  the run produced no reply (see result.json)\n'
    FAILED=1
    return
  fi
  check "the reply has an \"Open questions:\" line" eval 'asked | has_lines'
  # shellcheck source=/dev/null
  source "$TESTS/cases/$name/check.sh"
}

run_case() { # NAME
  local name=$1 case=$TESTS/cases/$1 run
  run=$(mktemp -d "${TMPDIR:-/tmp}/askloop-test.XXXXXX")
  echo "$name" > "$run/case"
  mkdir "$run/project"
  cp -R "$TESTS/fixtures/todo-app/." "$run/project/"
  [ -d "$case/files" ] && cp -R "$case/files/." "$run/project/"

  local model=()
  [ -n "${ASKLOOP_TEST_MODEL:-}" ] && model=(--model "$ASKLOOP_TEST_MODEL")
  # Only the plugin under test: no user settings, plugins, hooks or MCP
  # servers, which would add tokens and noise to every run.
  (cd "$run/project" && claude -p "$(cat "$case/prompt.md")" \
    --plugin-dir "$ROOT" --setting-sources project --strict-mcp-config \
    --no-session-persistence --permission-mode dontAsk \
    --allowedTools Read Write Edit Bash Glob Grep Skill \
    --disallowedTools Agent \
    --max-budget-usd "${ASKLOOP_TEST_BUDGET:-1}" ${model[@]+"${model[@]}"} \
    --output-format json) > "$run/result.json" || true
  python3 -c 'import json, sys; print(json.load(open(sys.argv[1])).get("result", ""))' \
    "$run/result.json" > "$run/final.md" 2>/dev/null || : > "$run/final.md"
  check_run "$run"
}

# shellcheck source=lib.sh
source "$TESTS/lib.sh"

if [ "${1:-}" = --check ]; then
  shift
  for run in "$@"; do check_run "$run"; done
else
  cases=("$@")
  [ ${#cases[@]} -eq 0 ] && cases=($(ls "$TESTS/cases"))
  # Check every name first: an unknown one would still start a paid run, with
  # an empty prompt.
  for name in "${cases[@]}"; do
    if [ ! -f "$TESTS/cases/$name/prompt.md" ] || [ ! -f "$TESTS/cases/$name/check.sh" ]; then
      echo "no such test case: $name (see tests/cases/)" >&2
      exit 2
    fi
  done
  for name in "${cases[@]}"; do run_case "$name"; done
fi

exit $FAILED
