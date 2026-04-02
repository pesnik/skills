---
name: oracle-fusion-list-overtime-candidates
description: Scan Oracle Fusion Existing Absences list and find all Preapproval Overtime entries that do not yet have a corresponding Overtime submission. Returns date, start time, and end time for each candidate.
---

# List Overtime Candidates

Navigates to Existing Absences / Overtime, reads all entries, identifies `Preapproval Overtime` (Completed) records with no matching `Overtime` entry, then clicks each to extract the approved start/end times.

## Usage

Run the script:

```bash
osascript enterprise/oracle-fusion/list-overtime-candidates/scripts/list-candidates.applescript
```

Or invoke directly: `/oracle-fusion-list-overtime-candidates`

## What it does

1. Navigates: Home → Time and Absences → Existing Absences / Overtime
2. Parses the full absence list
3. Identifies `Preapproval Overtime` entries that have no corresponding `Overtime` entry on the same date
4. Clicks each candidate to open its edit view
5. Reads `startTime` and `endTime` from the DFF fields
6. Returns a summary table

## Output format

```
Date          | Start Time | End Time
22-Mar-2026   | 03:30      | 05:30
19-Mar-2026   | 21:30      | 23:30
...
```
