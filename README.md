# skills

A personal collection of Claude Code skills — tools, workflows, and reference guides accumulated from hands-on usage and third-party discovery.

## Setup

To make all skills in this repo available in every Claude Code session (CLI and Desktop), add the repo to your `additionalDirectories` in `~/.claude/settings.json`:

```json
{
  "permissions": {
    "additionalDirectories": [
      "~/Pesnik/skills"
    ]
  }
}
```

Claude Code automatically loads `.claude/skills/` from any directory listed there. Skills are picked up via live change detection — no restart needed after adding new ones.

### One-time setup

```bash
git clone git@github.com:pesnik/skills.git ~/Pesnik/skills
```

Then add the config above to `~/.claude/settings.json`. Done.

## Adding a skill

```
.claude/skills/
└── <skill-name>/
    └── SKILL.md
```

`SKILL.md` requires a frontmatter header:

```markdown
---
name: skill-name
description: One-line description — used by Claude to decide when to invoke it.
---

# Skill content here
```

## Skills

| Skill | Category | Description |
|-------|----------|-------------|
| [hashicorp-vault](.claude/skills/hashicorp-vault/SKILL.md) | Infrastructure | Deploy Vault in Docker, configure LDAP auth, manage policies, use with varlock |
| [oracle-fusion](.claude/skills/oracle-fusion/SKILL.md) | Enterprise | Automate Oracle Fusion Cloud HCM via Chrome AppleScript — navigate absences, read lists, submit overtime requests |
