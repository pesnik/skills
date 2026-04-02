-- oracle-fusion/submit-overtime/scripts/submit-overtime.applescript
-- Submits one Overtime absence in Oracle Fusion Cloud HCM.
-- Usage: osascript submit-overtime.applescript "18-Mar-2026" "08:30" "11:20"
-- Requires: Chrome open, logged into Oracle Fusion, JS from Apple Events enabled.

on run argv
    set absDate to item 1 of argv
    set startTime to item 2 of argv
    set endTime to item 3 of argv

    tell application "Google Chrome"
        set w to front window
        set t to active tab of w

        -- Navigate to New Absence form
        execute t javascript "window.location.href = 'https://' + window.location.hostname + '/fscmUI/redwood/absences/manage-absences/view-add-absences'; 'done';"
        delay 4

        -- 1. Select Absence Type: Overtime
        --    Type in filter + ArrowDown + Enter to commit and close dropdown
        execute t javascript "
            var el = document.getElementById('oj-searchselect-filter-absence-type-dropdown|input');
            el.focus(); el.click();
            var setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
            setter.call(el, 'Overtime');
            el.dispatchEvent(new Event('input', {bubbles:true}));
            'done';
        "
        delay 3
        execute t javascript "
            var el = document.getElementById('oj-searchselect-filter-absence-type-dropdown|input');
            el.dispatchEvent(new KeyboardEvent('keydown', {bubbles:true, key:'ArrowDown', keyCode:40}));
            el.dispatchEvent(new KeyboardEvent('keydown', {bubbles:true, key:'Enter', keyCode:13}));
            'done';
        "
        delay 2

        -- 2. Fill start date (OJ-INPUT-DATE): execCommand + ArrowDown + blur
        execute t javascript "
            var inp = document.getElementById('absence-start-date|input');
            inp.focus(); inp.select();
            document.execCommand('selectAll', false, null);
            document.execCommand('insertText', false, '" & absDate & "');
            inp.dispatchEvent(new KeyboardEvent('keydown', {bubbles:true, key:'ArrowDown', keyCode:40}));
            inp.blur();
            'done';
        "
        delay 2

        -- 3. Fill end date (same date for single-day OT)
        execute t javascript "
            var inp = document.getElementById('absence-end-date|input');
            inp.focus(); inp.select();
            document.execCommand('selectAll', false, null);
            document.execCommand('insertText', false, '" & absDate & "');
            inp.dispatchEvent(new KeyboardEvent('keydown', {bubbles:true, key:'ArrowDown', keyCode:40}));
            inp.blur();
            'done';
        "
        delay 2

        -- 4. Fill start time: set OJ element .value AND sync underlying input
        execute t javascript "
            var stOj = document.querySelectorAll('input[id*=startTime]')[0].parentElement.parentElement.parentElement;
            stOj.value = '" & startTime & "';
            var stInp = document.querySelectorAll('input[id*=startTime]')[0];
            stInp.focus(); stInp.select();
            document.execCommand('selectAll', false, null);
            document.execCommand('insertText', false, '" & startTime & "');
            stInp.dispatchEvent(new Event('input', {bubbles:true}));
            stInp.dispatchEvent(new Event('change', {bubbles:true}));
            stInp.blur();
            'done';
        "
        delay 2

        -- 5. Fill end time
        execute t javascript "
            var etOj = document.querySelectorAll('input[id*=endTime]')[0].parentElement.parentElement.parentElement;
            etOj.value = '" & endTime & "';
            var etInp = document.querySelectorAll('input[id*=endTime]')[0];
            etInp.focus(); etInp.select();
            document.execCommand('selectAll', false, null);
            document.execCommand('insertText', false, '" & endTime & "');
            etInp.dispatchEvent(new Event('input', {bubbles:true}));
            etInp.dispatchEvent(new Event('change', {bubbles:true}));
            etInp.blur();
            'done';
        "
        delay 2

        -- 6. Click Submit (main form)
        execute t javascript "
            var btns = document.querySelectorAll('button');
            for (var i=0; i<btns.length; i++) {
                if (btns[i].innerText.trim() === 'Submit' && !btns[i].disabled) { btns[i].click(); break; }
            }
            'done';
        "
        delay 5

        -- 7. Handle confirmation dialog
        --    Step A: Click warning banner Submit link (triggers proper dialog flow)
        execute t javascript "
            var el = document.getElementById('abs-warning-banner-readonly_primaryAction_ignorable_warning_message_with_action');
            if (el) { el.click(); return 'clicked warning submit'; }
            return 'warning submit not found';
        "
        delay 3

        --    Step B: Dismiss overlap warning Close button, then click enabled Submit
        execute t javascript "
            var btns = Array.from(document.querySelectorAll('button'));
            // Find the Close button that is near the warning message (not the dialog Close)
            var warningClose = btns.find(function(b, i) {
                if (b.innerText.trim() !== 'Close') return false;
                var submitAfter = btns.slice(i).find(function(x){ return x.innerText.trim() === 'Submit'; });
                return !submitAfter || submitAfter.disabled;
            });
            if (warningClose) warningClose.click();
            'done';
        "
        delay 2

        --    Step C: Click the now-enabled dialog Submit
        execute t javascript "
            var btns = Array.from(document.querySelectorAll('button'));
            var submitBtn = btns.find(function(b){ return b.innerText.trim() === 'Submit' && !b.disabled; });
            if (submitBtn) submitBtn.click();
            'done';
        "
        delay 6

        -- 8. Verify
        set pageText to execute t javascript "document.body.innerText.substring(0, 200)"
        return "Done. Page: " & pageText
    end tell
end run
