# pesnik/skills

Personal collection of Claude Code skills. Each skill is a hands-on reference built from real usage — things I've set up myself or found useful from third parties.

## Structure

```
.claude/skills/          # Claude Code skill definitions (auto-loaded via symlinks)
  <skill-name>/
    SKILL.md             # Frontmatter + instructions Claude reads
LICENSE
Makefile                 # Install/uninstall skill symlinks
README.md
CLAUDE.md                # This file
```

## How skills load into Claude Code

Claude Code loads skills from `~/.claude/skills/`. Since this repo lives at `~/Pesnik/skills/`, skills are wired in via symlinks:

```bash
make install    # symlink all skills → ~/.claude/skills/
make list       # check install status
make uninstall  # remove all symlinks
```

After `make install`, skills appear in `/skills` and are available globally across all projects in both CLI and Desktop.

## Adding a new skill

1. Create `.claude/skills/<skill-name>/SKILL.md`
2. Run `make install` (picks up new symlinks)
3. Update the skills table in `README.md`
4. Commit and push

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
