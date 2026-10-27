# Helpers for check.sh files, sourced by run.sh. Every check works on plain
# files, so no model is needed to grade a run:
#   $WORK   the project directory the agent worked in
#   $FINAL  the agent's final response, as Markdown

FAILED=0

# check DESCRIPTION COMMAND...: run COMMAND and report PASS or FAIL.
check() {
  local desc=$1; shift
  if ( "$@" ) >/dev/null 2>&1; then
    printf '  PASS  %s\n' "$desc"
  else
    printf '  FAIL  %s\n' "$desc"
    FAILED=1
  fi
}

# The question set file the agent wrote; fails unless there's exactly one.
set_file() {
  local files=("$WORK"/.askloop/*.md)
  [ "${#files[@]}" -eq 1 ] && [ -f "${files[0]}" ] && printf '%s\n' "${files[0]}"
}

# section FILE NAME: the lines under "## NAME", up to the next "## ".
section() {
  awk -v want="## $2" '$0 == want {on = 1; next} /^## / {on = 0} on' "$1"
}

# Numbers of the entries ("- 7. …") in a section of the set file.
entries() {
  local f
  f=$(set_file) || return 1
  section "$f" "$1" | sed -nE 's/^- ([0-9]+)\..*/\1/p'
}

# Numbers listed in the last "Open questions: 1, 4, 5 (…)" line of the
# final response, one per line.
asked() {
  grep -E '^\**Open questions:' "$FINAL" | tail -1 \
    | sed -E 's/^\**Open questions:\**//; s/\(.*//' | grep -oE '[0-9]+'
}

# question_text N: question N as written in the final response, from its
# "N." line up to the next numbered question or the reply hint.
question_text() {
  awk -v n="$1" '
    match($0, /^\**[0-9]+\./) { on = ($0 ~ "^\\**" n "\\.") }
    /^Reply / { on = 0 }
    on' "$FINAL"
}

count() { wc -l | tr -d ' '; }
at_most() { [ "$(count)" -le "$1" ]; }
has_lines() { [ "$(count)" -ge 1 ]; }
