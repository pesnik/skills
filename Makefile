SKILLS_DST := $(HOME)/.claude/skills

# Find all SKILL.md files recursively, derive their parent dirs
SKILL_DIRS := $(patsubst %/SKILL.md,%,$(shell find . -path './.claude' -prune -o -name 'SKILL.md' -print))

.PHONY: install uninstall reinstall list

install: ## Symlink all skills into ~/.claude/skills/
	@mkdir -p $(SKILLS_DST)
	@for dir in $(SKILL_DIRS); do \
		skill=$$(basename $$dir); \
		ln -sf $(CURDIR)/$$dir $(SKILLS_DST)/$$skill && \
		echo "  linked: $$dir → ~/.claude/skills/$$skill"; \
	done
	@echo "Done. Restart Claude Code or open /skills to reload."

uninstall: ## Remove symlinks from ~/.claude/skills/
	@for dir in $(SKILL_DIRS); do \
		skill=$$(basename $$dir); \
		if [ -L $(SKILLS_DST)/$$skill ]; then \
			rm $(SKILLS_DST)/$$skill && echo "  removed: $$skill"; \
		fi \
	done

reinstall: uninstall install ## Re-sync all symlinks

list: ## List skills and their install status
	@echo "Skills in repo:"
	@for dir in $(SKILL_DIRS); do \
		skill=$$(basename $$dir); \
		if [ -L $(SKILLS_DST)/$$skill ]; then \
			echo "  [✓] $$skill ($$dir)"; \
		else \
			echo "  [ ] $$skill ($$dir) — not installed"; \
		fi \
	done

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-12s %s\n", $$1, $$2}'
