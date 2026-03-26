CONFIG     := tv_lift_esphome.yaml
DEVICE     := tv-lift.local
DOCKER_IMG := ghcr.io/esphome/esphome
DOCKER_RUN := docker run --rm --network host -v $(CURDIR):/config $(DOCKER_IMG)

.PHONY: compile flash logs clean help

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

compile: ## Compile firmware
	$(DOCKER_RUN) compile /config/$(CONFIG)

flash: ## Compile and flash over OTA
	$(DOCKER_RUN) run /config/$(CONFIG) --device $(DEVICE)

logs: ## Show live device logs
	$(DOCKER_RUN) logs /config/$(CONFIG) --device $(DEVICE)

clean: ## Remove build artifacts
	rm -rf .esphome/build .esphome/platformio
