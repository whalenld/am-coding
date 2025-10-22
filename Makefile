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
	$(PYTHON) - <<'PY'
import json, subprocess, re
from pathlib import Path
req_path=Path('$(REQ)')
installed_path=Path('$(INSTALLED)')
req_names=set()
for line in req_path.read_text().splitlines():
    line=line.strip()
    if not line or line.startswith('#'): continue
    if '#' in line: line=line.split('#',1)[0].strip()
    line=line.split(';',1)[0].strip()
    m=re.match(r"^([A-Za-z0-9_.\-]+)(?:\[.*\])?", line)
    if m: req_names.add(m.group(1))
res=subprocess.run(['$(PIP)','list','--format=json'], capture_output=True, text=True)
pip_list=json.loads(res.stdout)
lines=[]
for pkg in pip_list:
    if pkg['name'] in req_names:
        lines.append(f"{pkg['name']} {pkg['version']}")
installed_path.write_text('\n'.join(lines)+('\n' if lines else ''))
print('Wrote', installed_path)
PY

check: installed-list
	@echo "Checking installed packages against requirements (writes $(MISMATCH))"
	$(PYTHON) - <<'PY'
from pathlib import Path
import re
from packaging.version import Version
from packaging.specifiers import SpecifierSet
req_file=Path('$(REQ)')
inst_file=Path('$(INSTALLED)')
out_file=Path('$(MISMATCH)')
installed={}
for line in inst_file.read_text().splitlines():
    line=line.strip()
    if not line: continue
    parts=line.split()
    installed[parts[0]]=parts[1] if len(parts)>1 else ''
reqs=[]
for line in req_file.read_text().splitlines():
    raw=line.strip()
    if not raw or raw.startswith('#'): continue
    if '#' in raw: raw=raw.split('#',1)[0].strip()
    raw=raw.split(';',1)[0].strip()
    m=re.match(r"^([A-Za-z0-9_.\-]+)(?:\[.*\])?\s*([<>=!~].+)?$", raw)
    if not m: continue
    name=m.group(1)
    spec=m.group(2) or ''
    reqs.append((raw,name,spec))
missing_or_mismatched=[]
for raw,name,spec in reqs:
    inst_ver=installed.get(name)
    if inst_ver is None:
        missing_or_mismatched.append(f"MISSING: {raw} -> not installed")
        continue
    if not spec:
        continue
    try:
        specset=SpecifierSet(spec)
        ok=Version(inst_ver) in specset
    except Exception:
        ok=False
    if not ok:
        missing_or_mismatched.append(f"MISMATCH: {raw} -> installed {inst_ver} does not satisfy {spec}")
out_file.write_text('\n'.join(missing_or_mismatched)+('\n' if missing_or_mismatched else ''))
print('Wrote', out_file)
PY

freeze:
	@echo "Freezing full environment to $(FREEZE)"
	$(PIP) freeze > $(FREEZE)

clean:
	@echo "Removing virtualenv and generated files"
	rm -rf $(VENV_DIR) $(INSTALLED) $(MISMATCH) $(FREEZE)
	@echo "Clean complete"
