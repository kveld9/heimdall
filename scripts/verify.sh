#!/usr/bin/env bash
set -eo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${REPO_DIR}"

echo "=== [Heimdall] Running Quality & Modularity Verification Pipeline ==="

# 1. Python Syntax & Compilation Gate
echo "[*] Step 1/4: Compiling Python modules..."
python3 -m py_compile \
    daemon/*.py \
    daemon/heimdall/*.py \
    daemon/heimdall/collectors/*.py
echo "[+] Python compilation successful."

# 2. Collector Smoke Test Gate
echo "[*] Step 2/4: Running collector smoke test..."
python3 -c "
import sys
sys.path.insert(0, '${REPO_DIR}/daemon')
from heimdall.collectors.network import NetworkCollector
from heimdall.collectors.compute import ComputeCollector
from heimdall.collectors.storage import StorageCollector
from heimdall.collectors.health import HealthCollector

net = NetworkCollector().collect()
assert isinstance(net, dict) and 'down_rate_kb' in net, 'NetworkCollector failed'

comp = ComputeCollector().collect()
assert isinstance(comp, dict) and 'cpu_pct' in comp, 'ComputeCollector failed'

stor = StorageCollector().collect()
assert isinstance(stor, dict) and 'partitions' in stor, 'StorageCollector failed'

hlt = HealthCollector().collect()
assert isinstance(hlt, dict) and 'system_state' in hlt, 'HealthCollector failed'

print('[+] All 4 telemetry collectors initialized and executed successfully.')
"

# 3. Strict Emoji Prohibition Gate
echo "[*] Step 3/4: Auditing repository for prohibited emojis and non-ascii glyphs..."
python3 -c "
import re, glob, sys

emoji_pattern = re.compile(
    '['
    '\U0001F600-\U0001F64F'  # emoticons
    '\U0001F300-\U0001F5FF'  # symbols & pictographs
    '\U0001F680-\U0001F6FF'  # transport & map
    '\U0001F1E0-\U0001F1FF'  # flags
    '\U00002702-\U000027B0'
    '\U000024C2-\U0001F251'
    '\U0001F900-\U0001F9FF'  # supplemental symbols
    '\U0001FA70-\U0001FAFF'  # symbols extended
    '\U000025A0-\U000025FF'  # geometric shapes
    ']+', flags=re.UNICODE)

files = (
    glob.glob('daemon/**/*.py', recursive=True) +
    glob.glob('plasmoid/**/*', recursive=True) +
    glob.glob('scripts/*.sh') +
    glob.glob('*.md')
)

violations = 0
for f in files:
    try:
        with open(f, 'r', encoding='utf-8') as fh:
            for i, line in enumerate(fh, 1):
                matches = emoji_pattern.findall(line)
                if matches:
                    print(f'[-] PROHIBITED GLYPH: {f}:{i} -> {matches}', file=sys.stderr)
                    violations += 1
    except Exception:
        pass

if violations > 0:
    print(f'[!] Verification failed: {violations} prohibited emoji(s) detected.', file=sys.stderr)
    sys.exit(1)
print('[+] Zero emojis found. Repository is 100% compliant.')
"

# 4. QML & Package Metadata Gate
echo "[*] Step 4/4: Verifying Plasmoid package metadata and files..."
python3 -c "
import json
with open('plasmoid/metadata.json', 'r', encoding='utf-8') as f:
    meta = json.load(f)
assert meta.get('KPlugin', {}).get('Id') == 'org.kde.plasma.heimdall'
print('[+] Plasmoid metadata verified.')
"

echo "=== [Heimdall] Verification Pipeline PASSED: Clean, Modular, and Ready! ==="
