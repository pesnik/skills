-- oracle-fusion/list-overtime-candidates/scripts/list-candidates.applescript
-- Scans Existing Absences and finds Preapproval Overtime entries with no Overtime claim.
-- Clicks each to extract approved start/end times.
-- Requires: Chrome open, logged into Oracle Fusion, JS from Apple Events enabled.
--
-- SELF-HEALED FIXES:
-- 1. JS strings are single-line with '\\n' — multi-line AppleScript JS returning complex
--    values (JSON.stringify etc.) returns missing value from Chrome's JS executor.
-- 2. Click via `a#editAbsencesId` (Nth Preapproval Overtime anchor) not leaf text node.
--    Clicking the leaf text bubbled through multiple handlers causing immediate flip-flop.
-- 3. MutationObserver removed — form stays open reliably with anchor click; observer
--    added complexity without benefit (failed to fire before redirect in tests).
-- 4. Post-click delay increased to 8s — Oracle JET form load time can exceed 5s.
-- 5. Navigation skipped when already on Existing Absences page.

tell application "Google Chrome"
    set w to front window
    set t to active tab of w

    -- Navigate only if not already on Existing Absences page
    set currentText to execute t javascript "document.body.innerText.substring(0, 200)"
    if currentText does not contain "Existing Absences" then
        execute t javascript "var allEls = document.querySelectorAll('*'); for (var i = 0; i < allEls.length; i++) { var el = allEls[i]; if (el.childElementCount === 0 && el.innerText && el.innerText.trim() === 'Time and Absences') { el.click(); break; } } 'done';"
        delay 3
        execute t javascript "var allEls = document.querySelectorAll('*'); for (var i = 0; i < allEls.length; i++) { var el = allEls[i]; if (el.childElementCount === 0 && el.innerText && el.innerText.trim() === 'Existing Absences / Overtime') { el.click(); break; } } 'done';"
        delay 5
    end if

    -- Parse Preapproval Overtime dates (single-line JS, \\n required)
    set preapprovals to execute t javascript "(function() { var lines = document.body.innerText.split('\\n').map(function(l){ return l.trim(); }).filter(function(l){ return l; }); var entries = []; var i = 0; while (i < lines.length) { if (lines[i] === 'Preapproval Overtime' && i+1 < lines.length) { entries.push(lines[i+1]); } i++; } return JSON.stringify(entries); })()"

    set overtimeDates to execute t javascript "(function() { var lines = document.body.innerText.split('\\n').map(function(l){ return l.trim(); }).filter(function(l){ return l; }); var dates = []; var i = 0; while (i < lines.length) { if (lines[i] === 'Overtime' && i+1 < lines.length) { dates.push(lines[i+1]); } i++; } return JSON.stringify(dates); })()"

    if preapprovals is missing value then set preapprovals to "[]"
    if overtimeDates is missing value then set overtimeDates to "[]"

    -- Find candidate indices: Preapproval with no matching Overtime
    set idxString to execute t javascript "(function() { var pa = " & preapprovals & "; var od = " & overtimeDates & "; var odSet = {}; od.forEach(function(d){ odSet[d] = true; }); var indices = []; for (var i = 0; i < pa.length; i++) { if (!odSet[pa[i]]) indices.push(i + 1); } return indices.join('\\n'); })()"

    if idxString is missing value or idxString is "" then
        return "No new overtime candidates found."
    end if

    set candidateList to paragraphs of idxString
    set results to "Date | Start Time | End Time\n"

    repeat with idx in candidateList
        -- Click Nth Preapproval Overtime via its anchor (not leaf text — that causes flip-flop)
        execute t javascript "(function() { var anchors = document.querySelectorAll('a#editAbsencesId'); var count = 0; for (var i = 0; i < anchors.length; i++) { if (anchors[i].innerText.trim() === 'Preapproval Overtime') { count++; if (count === " & idx & ") { anchors[i].click(); return 'clicked'; } } } return 'not found'; })()"

        -- 8s delay: Oracle JET form load can take longer than 5s
        delay 8

        -- Read fields: Tier 1 — known DFF ID patterns (startTime / endTime in id)
        -- Tier 2 — aria-label / label scan fallback
        -- Tier 3 — diagnostic dump so real IDs can be discovered and script updated
        set fieldData to execute t javascript "(function() { var inputs = Array.from(document.querySelectorAll('input')); var startDate='', startTime='', endTime=''; inputs.forEach(function(el) { var id = el.id||''; if (id === 'absence-start-date|input') startDate = el.value; if (id.indexOf('startTime') >= 0) startTime = el.value; if (id.indexOf('endTime') >= 0) endTime = el.value; }); if (startDate && startTime && endTime) { return startDate + ' | ' + startTime + ' | ' + endTime; } inputs.forEach(function(el) { var val = el.value||''; var sig = ((el.getAttribute('aria-label')||'') + ' ' + (el.id||'')).toLowerCase(); if (!startDate && sig.indexOf('start date') >= 0) startDate = val; if (!startTime && sig.indexOf('start time') >= 0) startTime = val; if (!endTime && sig.indexOf('end time') >= 0) endTime = val; }); if (startDate && startTime && endTime) { return startDate + ' | ' + startTime + ' | ' + endTime; } var dump = inputs.filter(function(el){ return el.id || el.getAttribute('aria-label') || el.value; }).map(function(el){ return JSON.stringify({id:el.id, lbl:el.getAttribute('aria-label')||'', val:el.value}); }); return 'DIAGNOSTIC:[' + dump.join(',') + ']'; })()"

        set results to results & fieldData & "\n"

        -- Cancel back to list
        execute t javascript "(function() { var btns = document.querySelectorAll('button'); for (var i=0; i<btns.length; i++) { if (btns[i].innerText.trim() === 'Cancel') { btns[i].click(); break; } } return 'done'; })()"
        delay 4
    end repeat

    return results
end tell
