# No number given, so the window is 3.
check "asks 1 to 3 questions" eval '[ "$(asked | count)" -ge 1 ] && asked | at_most 3'
check "set file records Window: 3" eval 'grep -qx "Window: 3" "$(set_file)"'
check "set file has at most 3 open" eval 'entries Open | at_most 3'
check "new questions aren't marked (still open)" eval '! grep -qi "still open" "$FINAL"'
