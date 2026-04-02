-- oracle-fusion/list-overtime-candidates/scripts/list-candidates.applescript
-- Scans Existing Absences and finds Preapproval Overtime entries with no Overtime claim.
-- Clicks each to extract approved start/end times.
-- Requires: Chrome open, logged into Oracle Fusion, JS from Apple Events enabled.

on getTabJS(t, js)
    return execute t javascript js
end getTabJS

tell application "Google Chrome"
    set w to front window
    set t to active tab of w

    -- Navigate to Time and Absences
    execute t javascript "
        var allEls = document.querySelectorAll('*');
        for (var i = 0; i < allEls.length; i++) {
            var el = allEls[i];
            if (el.childElementCount === 0 && el.innerText && el.innerText.trim() === 'Time and Absences') {
                el.click(); break;
            }
        }
        'done';
    "
    delay 3

    -- Navigate to Existing Absences / Overtime
    execute t javascript "
        var allEls = document.querySelectorAll('*');
        for (var i = 0; i < allEls.length; i++) {
            var el = allEls[i];
            if (el.childElementCount === 0 && el.innerText && el.innerText.trim() === 'Existing Absences / Overtime') {
                el.click(); break;
            }
        }
        'done';
    "
    delay 4

    -- Read the full list
    set pageText to execute t javascript "document.body.innerText"

    -- Parse: find Preapproval Overtime entries and check for matching Overtime entries
    -- Count occurrences of each type per date
    set preapprovals to execute t javascript "
        var lines = document.body.innerText.split('\n').map(function(l){ return l.trim(); }).filter(function(l){ return l; });
        var entries = [];
        var i = 0;
        while (i < lines.length) {
            if (lines[i] === 'Preapproval Overtime' && i+1 < lines.length) {
                var dateRange = lines[i+1];
                entries.push(dateRange);
            }
            i++;
        }
        return JSON.stringify(entries);
    "

    set overtimeDates to execute t javascript "
        var lines = document.body.innerText.split('\n').map(function(l){ return l.trim(); }).filter(function(l){ return l; });
        var dates = [];
        var i = 0;
        while (i < lines.length) {
            if (lines[i] === 'Overtime' && i+1 < lines.length) {
                dates.push(lines[i+1]);
            }
            i++;
        }
        return JSON.stringify(dates);
    "

    -- Click each Preapproval Overtime entry to get times
    set candidateCount to execute t javascript "
        var allEls = document.querySelectorAll('*');
        var count = 0;
        for (var i = 0; i < allEls.length; i++) {
            if (allEls[i].childElementCount === 0 && allEls[i].innerText && allEls[i].innerText.trim() === 'Preapproval Overtime') count++;
        }
        return count.toString();
    "

    set results to "Date | Start Time | End Time\n"
    set n to candidateCount as integer

    repeat with idx from 1 to n
        -- Click the Nth Preapproval Overtime
        execute t javascript "
            var allEls = document.querySelectorAll('*');
            var count = 0;
            for (var i = 0; i < allEls.length; i++) {
                var el = allEls[i];
                if (el.childElementCount === 0 && el.innerText && el.innerText.trim() === 'Preapproval Overtime') {
                    count++;
                    if (count === " & idx & ") { el.click(); break; }
                }
            }
            'done';
        "
        delay 4

        -- Read field values
        set fieldData to execute t javascript "
            var inputs = Array.from(document.querySelectorAll('input')).filter(function(el){ return el.value; });
            var startDate = '', startTime = '', endTime = '';
            inputs.forEach(function(el) {
                if (el.id === 'absence-start-date|input') startDate = el.value;
                if (el.id.indexOf('startTime') >= 0) startTime = el.value;
                if (el.id.indexOf('endTime') >= 0) endTime = el.value;
            });
            return startDate + ' | ' + startTime + ' | ' + endTime;
        "
        set results to results & fieldData & "\n"

        -- Cancel back to list
        execute t javascript "
            var btns = document.querySelectorAll('button');
            for (var i=0; i<btns.length; i++) {
                if (btns[i].innerText.trim() === 'Cancel') { btns[i].click(); break; }
            }
            'done';
        "
        delay 3
    end repeat

    return results
end tell
