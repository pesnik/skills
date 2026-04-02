---
name: oracle-fusion
description: Oracle Fusion Cloud HCM automation toolkit — setup, navigation, and shared context for absence/overtime management via Chrome AppleScript on macOS.
---

# Oracle Fusion Cloud HCM

**Category:** Enterprise / HR Self-Service

Use this skill for context and setup. For specific tasks use:
- `/oracle-fusion-list-overtime-candidates` — find Preapproval Overtime entries with no OT claim yet
- `/oracle-fusion-submit-overtime` — submit an Overtime absence request for a specific date

---

## Setup (one-time per Chrome window)

1. Open Chrome and log in to Oracle Fusion.
2. Enable: **View > Developer > Allow JavaScript from Apple Events**
   - Must be re-enabled whenever Chrome is fully closed and reopened.

## Key URLs

- Home: `https://<tenant>.fa.ocs.oraclecloud.com/fscmUI/faces/FuseWelcome`
- New Absence: `https://<tenant>.fa.ocs.oraclecloud.com/fscmUI/redwood/absences/manage-absences/view-add-absences`
- Existing Absences: `https://<tenant>.fa.ocs.oraclecloud.com/fscmUI/redwood/absences/manage-absences`

## Oracle JET Component Rules

The Oracle Fusion UI uses Oracle JET custom elements. Standard DOM value-setting does not trigger validation. Key rules:

| Field type | Element tag | Working method |
|------------|-------------|----------------|
| Date picker | `OJ-INPUT-DATE` | `execCommand('insertText', 'DD-MMM-YYYY')` + `ArrowDown` keydown + `blur` on underlying `\|input` |
| Time text field | `OJ-INPUT-TEXT` | Set `.value` on OJ element **AND** `execCommand('insertText')` on underlying `\|input` |
| Dropdown select | `OJ-SELECT-SINGLE` | Set filter input value + fire `input` event + `ArrowDown` + `Enter` to commit and close |
