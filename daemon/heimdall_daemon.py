#!/usr/bin/env python3
"""Heimdall Telemetry Daemon execution entry point."""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from heimdall.main import main

if __name__ == "__main__":
    main()
