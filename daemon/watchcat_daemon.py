#!/usr/bin/env python3
"""WatchCat Telemetry Daemon execution shim for backward-compatible invocations."""

import os
import sys

# Ensure daemon directory is on sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from watchcat.main import main

if __name__ == "__main__":
    main()
