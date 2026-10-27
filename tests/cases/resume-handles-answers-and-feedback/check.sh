# 1 and 3 answered; 2 got feedback only ("not JWT"); 4-6 queued; window 3.
check "1 decided as SQLite" eval 'section "$(set_file)" Decided | grep -E "^- 1\." | grep -qi sqlite'
check "3 decided" eval 'entries Decided | grep -qx 3'
check "1 and 3 not asked again" eval '! asked | grep -qxE "1|3"'
check "2 asked again under the same number" eval 'asked | grep -qx 2 && question_text 2 | has_lines'
check "2 no longer offers JWT as an option" eval '! question_text 2 | grep -E "^[[:space:]]*[a-z]\)" | grep -qi jwt'
check "new questions numbered 4 or higher" eval 'for n in $(asked); do [ "$n" = 2 ] || [ "$n" -ge 4 ] || exit 1; done'
check "asks at most 3 questions" eval 'asked | at_most 3'
check "still a single set file" set_file
