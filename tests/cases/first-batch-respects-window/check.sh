# Window of 2, given in the prompt.
check "asks 1 or 2 questions" eval '[ "$(asked | count)" -ge 1 ] && asked | at_most 2'
check "each asked question is written out" eval 'for n in $(asked); do question_text $n | has_lines || exit 1; done'
check "plain numbers, no Q prefix" eval '! grep -qE "\bQ[0-9]+" "$FINAL"'
check "no tables" eval '! grep -qE "^\s*\|.*\|\s*$" "$FINAL"'
check "one question set file in .askloop/" set_file
check "set file has Open and Queued sections" eval 'f=$(set_file) && grep -qx "## Open" "$f" && grep -qx "## Queued" "$f"'
check "set file has at most 2 open" eval 'entries Open | at_most 2'
check ".askloop/ added to .gitignore" grep -qxE '/?\.askloop/?' "$WORK/.gitignore"
check "the fixture's own .gitignore entry is kept" grep -qx 'node_modules/' "$WORK/.gitignore"
check "new questions aren't marked (still open)" eval '! grep -qi "still open" "$FINAL"'
