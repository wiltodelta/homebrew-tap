#!/usr/bin/env bash
set -euo pipefail

python3 -m unittest discover -s tests -p 'test_*.py'
brew ruby tests/formula_options.rb
brew ruby tests/wheel_linkage.rb
brew style .
python3 scripts/sync_remove_ai_watermarks.py --check
