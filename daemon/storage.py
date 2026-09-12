#!/usr/bin/env python3
"""Backward-compatibility shim for HeimdallStorage."""

from heimdall.storage import HeimdallStorage, WatchCatStorage

__all__ = ["HeimdallStorage", "WatchCatStorage"]
