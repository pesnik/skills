# pesnik/skills

Personal collection of Claude Code skills. Each skill is a hands-on reference built from real usage — things I've set up myself or found useful from third parties.

## Structure

```
<category>/
  <skill-domain>/
    SKILL.md                  # Top-level context skill (optional — use for multi-skill domains)
    <sub-skill>/
      SKILL.md                # Focused, single-purpose skill
      scripts/                # Runnable scripts Claude can execute or reference
        <script>.applescript
        <script>.sh
        <script>.js
LICENSE
Makefile                      # Install/uninstall skill symlinks
README.md
CLAUDE.md                     # This file
```

## How skills load into Claude Code

Claude Code loads skills from `~/.claude/skills/`. Since this repo lives at `~/Pesnik/skills/`, skills are wired in via symlinks:

```bash
make install    # symlink all skills → ~/.claude/skills/
make list       # check install status
make uninstall  # remove all symlinks
```

After `make install`, skills appear in `/skills` and are available globally across all projects in both CLI and Desktop.

## Skill philosophy

**One skill = one job.** A skill is invoked to *do* something specific, not to be a reference manual. If a domain has multiple distinct operations, split them into separate skills — each with its own SKILL.md and its own `scripts/` folder.

**Skills are not just SKILL.md.** The skill directory should include anything Claude needs to execute the task: AppleScript files, shell scripts, JS snippets, config templates, or any other supporting artifact. Claude reads SKILL.md for instructions and can reference or run scripts in the same directory.

**Domain grouping.** Related skills live under a shared domain folder (e.g. `enterprise/oracle-fusion/`). The domain folder can have its own top-level SKILL.md for shared context (setup steps, auth, conventions), but each sub-skill is independently invocable via its own `SKILL.md`.

**Good skill anatomy:**
```
submit-overtime/
├── SKILL.md        ← what it does, parameters, known quirks
└── scripts/
    └── submit-overtime.applescript   ← the actual runnable implementation
```

**Bad skill anatomy:**
```
oracle-fusion/
└── SKILL.md        ← 300 lines of reference docs covering 5 different operations
```

## Adding a new skill

1. Create `<category>/<domain>/<skill-name>/SKILL.md` (and a `scripts/` folder if needed)
2. Run `make install` (picks up new symlinks automatically)
3. Update the skills table in `README.md`
4. Commit and push

## IMPORTANT — Before every commit

Always scan staged changes for sensitive data before committing. Check for:

- Real IP addresses (e.g. `192.168.x.x`, `172.16.x.x`, `10.x.x.x`)
- Auth accessor IDs (e.g. `auth_ldap_xxxxxxxx` — use `xxxxxxxx` as placeholder)
- Tokens, passwords, or API keys
- Usernames or internal hostnames

If any are found, replace with placeholders before committing. Use `localhost` for URLs and `xxxxxxxx` for opaque IDs.

### SKILL.md format

```markdown
---
name: skill-name
description: One-line description — Claude uses this to decide when to invoke it.
---

# Skill Title

Content here...
```

## Current skills

| Skill | Category |
|-------|----------|
| `hashicorp-vault` | Infrastructure |
| `oracle-fusion` | Enterprise — shared context/setup |
| `oracle-fusion-list-overtime-candidates` | Enterprise — find Preapproval OT with no claim |
| `oracle-fusion-submit-overtime` | Enterprise — submit one Overtime absence request |
