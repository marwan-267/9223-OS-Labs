DIR ?= watched
MALICIOUS_DIR ?= malicious_dir
INTERVAL ?= 5

.PHONY: all run restore setup

all: run

# Pre-build step: create the quarantine (and watched) directory if missing
setup:
	mkdir -p $(MALICIOUS_DIR) $(DIR)

run: setup
	bash ./antivirusd.sh $(DIR) $(MALICIOUS_DIR) $(INTERVAL)

restore: setup
	bash ./restore.sh $(DIR) $(MALICIOUS_DIR)
