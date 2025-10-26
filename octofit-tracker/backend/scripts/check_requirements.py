from pathlib import Path
import re
from packaging.version import Version
from packaging.specifiers import SpecifierSet
import sys

def main():
    req_file = Path(sys.argv[1])
    inst_file = Path(sys.argv[2])
    out_file = Path(sys.argv[3])
    installed = {}
    for line in inst_file.read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split()
        installed[parts[0]] = parts[1] if len(parts) > 1 else ''
    reqs = []
    for line in req_file.read_text().splitlines():
        raw = line.strip()
        if not raw or raw.startswith('#'):
            continue
        if '#' in raw:
            raw = raw.split('#', 1)[0].strip()
        raw = raw.split(';', 1)[0].strip()
        m = re.match(r"^([A-Za-z0-9_.\-]+)(?:\[.*\])?\s*([<>=!~].+)?$", raw)
        if not m:
            continue
        name = m.group(1)
        spec = m.group(2) or ''
        reqs.append((raw, name, spec))
    missing_or_mismatched = []
    for raw, name, spec in reqs:
        inst_ver = installed.get(name)
        if inst_ver is None:
            missing_or_mismatched.append(f"MISSING: {raw} -> not installed")
            continue
        if not spec:
            continue
        try:
            specset = SpecifierSet(spec)
            ok = Version(inst_ver) in specset
        except Exception:
            ok = False
        if not ok:
            missing_or_mismatched.append(f"MISMATCH: {raw} -> installed {inst_ver} does not satisfy {spec}")
    out_file.write_text('\n'.join(missing_or_mismatched) + ('\n' if missing_or_mismatched else ''))
    print('Wrote', out_file)

if __name__ == "__main__":
    main()
