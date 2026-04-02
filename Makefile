SKILLS_SRC  := $(CURDIR)/.claude/skills
SKILLS_DST  := $(HOME)/.claude/skills
SKILLS      := $(notdir $(wildcard $(SKILLS_SRC)/*))

.PHONY: install uninstall reinstall list

install: ## Symlink all skills into ~/.claude/skills/
	@mkdir -p $(SKILLS_DST)
	@for skill in $(SKILLS); do \
		ln -sf $(SKILLS_SRC)/$$skill $(SKILLS_DST)/$$skill && \
		echo "  linked: $$skill"; \
	done
	@echo "Done. Restart Claude Code or open /skills to reload."

uninstall: ## Remove symlinks from ~/.claude/skills/
	@for skill in $(SKILLS); do \
		if [ -L $(SKILLS_DST)/$$skill ]; then \
			rm $(SKILLS_DST)/$$skill && echo "  removed: $$skill"; \
		fi \
	done

reinstall: uninstall install ## Re-sync all symlinks

list: ## List skills and their install status
	@echo "Skills in repo:"
	@for skill in $(SKILLS); do \
		if [ -L $(SKILLS_DST)/$$skill ]; then \
			echo "  [✓] $$skill"; \
		else \
			echo "  [ ] $$skill (not installed)"; \
		fi \
	done

help: ## Show available targets
	@grep -E '^[a-zA-Z_-]+:.*##' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*##"}; {printf "  %-12s %s\n", $$1, $$2}'
