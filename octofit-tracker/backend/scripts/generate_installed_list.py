import json
import subprocess
import re
from pathlib import Path
import sys

def main():
    req_path = Path(sys.argv[1])
    installed_path = Path(sys.argv[2])
    pip_path = sys.argv[3]
    req_names = set()
    for line in req_path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        if '#' in line:
            line = line.split('#', 1)[0].strip()
        line = line.split(';', 1)[0].strip()
        m = re.match(r"^([A-Za-z0-9_.\-]+)(?:\[.*\])?", line)
        if m:
            req_names.add(m.group(1))
    res = subprocess.run([pip_path, 'list', '--format=json'], capture_output=True, text=True)
    pip_list = json.loads(res.stdout)
    lines = []
    for pkg in pip_list:
        if pkg['name'] in req_names:
            lines.append(f"{pkg['name']} {pkg['version']}")
    installed_path.write_text('\n'.join(lines) + ('\n' if lines else ''))
    print('Wrote', installed_path)

if __name__ == "__main__":
    main()
