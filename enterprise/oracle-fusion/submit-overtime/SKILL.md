---
name: oracle-fusion-submit-overtime
description: Submit an Overtime absence request in Oracle Fusion Cloud HCM for a given date, start time, and end time. Handles the Oracle JET form interaction quirks and the overlap-warning confirmation dialog.
---

# Submit Overtime

Submits one `Overtime` absence entry via the New Absence form in Oracle Fusion.

## Usage

```bash
osascript enterprise/oracle-fusion/submit-overtime/scripts/submit-overtime.applescript \
  "18-Mar-2026" "08:30" "11:20"
```

Or tell Claude:
> Submit overtime for 18-Mar-2026, 08:30 to 11:20

## What it does

1. Clicks **Add** on the Existing Absences page (or navigates to the New Absence URL directly)
2. Selects **Overtime** as the absence type (closes dropdown via `ArrowDown` + `Enter`)
3. Fills start date and end date via `execCommand` + `ArrowDown` + `blur` on the `OJ-INPUT-DATE` input
4. Fills start time and end time by setting both the `OJ-INPUT-TEXT.value` and the underlying `<input>` via `execCommand`
5. Clicks outside the form to close any open dropdowns
6. Clicks **Submit**
7. Handles the confirmation dialog:
   - Clicks the warning banner **Submit** link (`abs-warning-banner-readonly_primaryAction_ignorable_warning_message_with_action`)
   - Dismisses the overlap warning (Close button)
   - Clicks the now-enabled dialog **Submit** button
8. Verifies the entry appears in Existing Absences with status **Awaiting approval**

## Parameters

| Param | Format | Example |
|-------|--------|---------|
| date | `DD-MMM-YYYY` | `18-Mar-2026` |
| start\_time | `HH:MM` (24h) | `08:30` |
| end\_time | `HH:MM` (24h) | `11:20` |

## Known quirks

- **Absence type must be selected first**, but selecting it may reset time fields if re-interacted — always fill dates/times after the type is committed.
- **Times do not auto-sync** from `OJ-INPUT-TEXT.value` to the underlying `<input>` — both must be set explicitly.
- **Overlap warning is expected** when a Preapproval Overtime exists for the same date — this is normal, continue through it.
- Button indices for the dialog shift — the script dynamically finds them rather than using hardcoded indices.
