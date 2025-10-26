# Makefile to reproduce OctoFit backend environment
# Usage: make <target>

VENV_DIR=octofit-tracker/backend/venv
PYTHON=$(VENV_DIR)/bin/python
PIP=$(VENV_DIR)/bin/pip
REQ=octofit-tracker/backend/requirements.txt
INSTALLED=installed_requirements.txt
MISMATCH=missing_or_mismatched_requirements.txt
FREEZE=requirements-frozen.txt

.PHONY: all venv install wheel-install installed-list check freeze clean

all: venv install wheel-install installed-list check

venv:
	@echo "Creating virtualenv at $(VENV_DIR)"
	python3 -m venv $(VENV_DIR)
	@echo "Virtualenv created. Activate with: source $(VENV_DIR)/bin/activate"

install: venv
	@echo "Installing requirements from $(REQ)"
	$(PIP) install -r $(REQ)

wheel-install: install
	@echo "Installing wheel and re-installing requirements to prefer wheel-built packages"
	$(PIP) install wheel
	$(PIP) install --upgrade --force-reinstall -r $(REQ)

installed-list: wheel-install
	@echo "Generating $(INSTALLED) by matching pip list to $(REQ)"
	$(PYTHON) $(shell pwd)/octofit-tracker/backend/scripts/generate_installed_list.py $(REQ) $(INSTALLED) $(PIP)

check: installed-list
	@echo "Checking installed packages against requirements (writes $(MISMATCH))"
	$(PIP) install packaging >/dev/null
	$(PYTHON) $(shell pwd)/octofit-tracker/backend/scripts/check_requirements.py $(REQ) $(INSTALLED) $(MISMATCH)

freeze:
	@echo "Freezing full environment to $(FREEZE)"
	$(PIP) freeze > $(FREEZE)

clean:
	@echo "Removing virtualenv and generated files"
	rm -rf $(VENV_DIR) $(INSTALLED) $(MISMATCH) $(FREEZE)
	@echo "Clean complete"
