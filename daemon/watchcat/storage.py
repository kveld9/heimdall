"""Persistent storage for WatchCat daily network budget and weekly history."""

import datetime
import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional


class WatchCatStorage:
    """Manages daily bandwidth quotas, 30-day history pruning, and configuration."""

    def __init__(self, data_dir: Optional[str] = None) -> None:
        if data_dir is None:
            data_dir = os.path.expanduser("~/.local/share/watchcat")
        self.data_dir = Path(data_dir)
        self.data_dir.mkdir(parents=True, exist_ok=True)
        self.history_file = self.data_dir / "history.json"
        self.config_file = self.data_dir / "config.json"
        self._load_config()
        self._load_history()

    def _default_config(self) -> Dict[str, Any]:
        return {
            "daily_cap_bytes": 1024 * 1024 * 1024,  # 1.00 GB default
            "warning_threshold_bytes": 512 * 1024 * 1024,  # 512 MB default
            "interface": "auto",
            "theme_mode": "monochrome"
        }

    def _load_config(self) -> None:
        if self.config_file.exists():
            try:
                with open(self.config_file, "r", encoding="utf-8") as f:
                    self.config = {**self._default_config(), **json.load(f)}
            except Exception:
                self.config = self._default_config()
        else:
            self.config = self._default_config()
            self._save_config()

    def _save_config(self) -> None:
        try:
            with open(self.config_file, "w", encoding="utf-8") as f:
                json.dump(self.config, f, indent=2)
        except Exception as e:
            print(f"[WatchCatStorage] Error saving config: {e}")

    def _today_str(self) -> str:
        return datetime.date.today().isoformat()

    def _load_history(self) -> None:
        if self.history_file.exists():
            try:
                with open(self.history_file, "r", encoding="utf-8") as f:
                    self.history = json.load(f)
            except Exception:
                self.history = {"days": {}, "last_interface_counters": {}}
        else:
            self.history = {"days": {}, "last_interface_counters": {}}
            self._save_history()

    def _save_history(self) -> None:
        try:
            cutoff = (datetime.date.today() - datetime.timedelta(days=30)).isoformat()
            if "days" in self.history:
                self.history["days"] = {
                    k: v for k, v in self.history["days"].items() if k >= cutoff
                }
            with open(self.history_file, "w", encoding="utf-8") as f:
                json.dump(self.history, f, indent=2)
        except Exception as e:
            print(f"[WatchCatStorage] Error saving history: {e}")

    def record_traffic_delta(self, rx_delta: int, tx_delta: int, current_rate_bps: int = 0) -> None:
        """Records traffic increment for today's budget."""
        if rx_delta <= 0 and tx_delta <= 0:
            return

        today = self._today_str()
        days = self.history.setdefault("days", {})
        today_data = days.setdefault(today, {
            "down_bytes": 0,
            "up_bytes": 0,
            "total_bytes": 0,
            "peak_rate_bps": 0
        })

        today_data["down_bytes"] += max(0, rx_delta)
        today_data["up_bytes"] += max(0, tx_delta)
        today_data["total_bytes"] = today_data["down_bytes"] + today_data["up_bytes"]
        if current_rate_bps > today_data.get("peak_rate_bps", 0):
            today_data["peak_rate_bps"] = current_rate_bps

        self._save_history()

    def get_today_summary(self) -> Dict[str, Any]:
        """Calculates today's consumption against configured limits."""
        today = self._today_str()
        today_data = self.history.get("days", {}).get(today, {
            "down_bytes": 0,
            "up_bytes": 0,
            "total_bytes": 0,
            "peak_rate_bps": 0
        })
        cap = self.config.get("daily_cap_bytes", 1024 * 1024 * 1024)
        warn = self.config.get("warning_threshold_bytes", 512 * 1024 * 1024)
        total = today_data["total_bytes"]

        ratio_used = (total / cap) if cap > 0 else 0.0
        remaining = max(0, cap - total)

        down_pct = round((today_data["down_bytes"] / total * 100)) if total > 0 else 50
        up_pct = 100 - down_pct if total > 0 else 50

        return {
            "date": today,
            "down_bytes": today_data["down_bytes"],
            "up_bytes": today_data["up_bytes"],
            "total_bytes": total,
            "peak_rate_bps": today_data.get("peak_rate_bps", 0),
            "cap_bytes": cap,
            "warn_bytes": warn,
            "remaining_bytes": remaining,
            "ratio_used": min(1.0, max(0.0, ratio_used)),
            "down_pct": down_pct,
            "up_pct": up_pct
        }

    def get_weekly_breakdown(self) -> List[Dict[str, Any]]:
        """Returns a 7-day chronological list ending today."""
        result = []
        today = datetime.date.today()
        days_map = self.history.get("days", {})

        for offset in range(6, -1, -1):
            target_date = today - datetime.timedelta(days=offset)
            date_key = target_date.isoformat()
            day_name = target_date.strftime("%A")
            date_label = target_date.strftime("%d %b")

            record = days_map.get(date_key, {
                "down_bytes": 0,
                "up_bytes": 0,
                "total_bytes": 0,
                "peak_rate_bps": 0
            })

            result.append({
                "day": day_name,
                "date": date_label,
                "iso_date": date_key,
                "is_today": (offset == 0),
                "down_bytes": record["down_bytes"],
                "up_bytes": record["up_bytes"],
                "total_bytes": record["total_bytes"]
            })

        return result
