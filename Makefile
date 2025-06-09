# Makefile for generating shai.sh from multiple source files

SOURCE_FILES = src/shai.sh src/config.sh.example src/tui.sh src/logging.sh src/context.sh src/llm_prompt.sh src/llm.sh src/tmux.sh

OUTPUT = shai.sh

shai: $(OUTPUT)

$(OUTPUT): $(SOURCE_FILES)
	@echo "Generating $(OUTPUT)..."
	@echo "#!/bin/bash" > $(OUTPUT)
	@echo "" >> $(OUTPUT)
	@echo "" >> $(OUTPUT)
	@for file in $(SOURCE_FILES); do \
		echo "# =============================================================================" >> $(OUTPUT); \
		echo "# From: $$file" >> $(OUTPUT); \
		echo "# =============================================================================" >> $(OUTPUT); \
		echo "" >> $(OUTPUT); \
		sed '1{/^#!/d;}; /^source /d' "$$file" >> $(OUTPUT); \
		echo "" >> $(OUTPUT); \
	done
	@chmod +x $(OUTPUT)
	@echo "✓ $(OUTPUT) generated successfully"

clean:
	@echo "Removing $(OUTPUT)..."
	@rm -f $(OUTPUT)
	@echo "✓ Cleaned"

.PHONY: shai clean