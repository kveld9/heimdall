"""Heimdall Telemetry Daemon main orchestrator and entry point."""

import argparse
import signal
import sys
import threading
import time
from typing import Any, Dict

from .collectors.compute import ComputeCollector
from .collectors.health import HealthCollector
from .collectors.network import NetworkCollector
from .collectors.storage import StorageCollector
from .server import ThreadedHTTPServer, make_api_handler
from .storage import HeimdallStorage


class HeimdallDaemon:
    """Coordinates telemetry collectors, storage persistence, and HTTP serving."""

    def __init__(
        self,
        host: str = "127.0.0.1",
        port: int = 9871,
        interval: float = 1.0,
        interface: str = None,
        data_dir: str = None,
    ) -> None:
        self.host = host
        self.port = port
        self.interval = interval
        self.running = False
        self._lock = threading.Lock()

        # Initialize storage
        self.storage = HeimdallStorage(data_dir=data_dir)

        # Initialize collectors
        self.net_collector = NetworkCollector(interface=interface)
        self.compute_collector = ComputeCollector()
        self.storage_collector = StorageCollector()
        self.health_collector = HealthCollector()

        # Cached telemetry snapshot
        self.current_telemetry: Dict[str, Any] = {
            "timestamp": time.time(),
            "net": {},
            "budget": {},
            "compute": {},
            "storage": {},
            "health": {},
        }

        # Initialize HTTP server
        handler_cls = make_api_handler(
            get_telemetry_fn=self.get_telemetry,
            get_budget_fn=self.get_budget,
            get_week_fn=self.get_week,
        )
        self.server = ThreadedHTTPServer((self.host, self.port), handler_cls)

    def sample_telemetry(self) -> None:
        """Sample all kernel interfaces and update cached state."""
        net_data = self.net_collector.collect()
        compute_data = self.compute_collector.collect()
        storage_data = self.storage_collector.collect()
        health_data = self.health_collector.collect()

        # Record daily bandwidth deltas
        rate_bps = int(net_data["down_rate_kb"] * 1024 * 8)
        self.storage.record_traffic_delta(
            rx_delta=net_data["delta_rx"],
            tx_delta=net_data["delta_tx"],
            current_rate_bps=rate_bps,
        )
        budget_data = self.storage.get_today_summary()

        snapshot = {
            "timestamp": time.time(),
            "net": {
                "interface": net_data["interface"],
                "down_rate_kb": net_data["down_rate_kb"],
                "up_rate_kb": net_data["up_rate_kb"],
                "sparkline_down": net_data["sparkline_down"],
                "sparkline_up": net_data["sparkline_up"],
                "top_processes": net_data["top_processes"],
            },
            "budget": budget_data,
            "compute": compute_data,
            "storage": storage_data,
            "health": health_data,
        }

        with self._lock:
            self.current_telemetry = snapshot

    def get_telemetry(self) -> Dict[str, Any]:
        with self._lock:
            return self.current_telemetry

    def get_budget(self) -> Dict[str, Any]:
        return self.storage.get_today_summary()

    def get_week(self) -> Any:
        return self.storage.get_weekly_breakdown()

    def run_loop(self) -> None:
        """Collection loop running at specified interval."""
        while self.running:
            start = time.time()
            try:
                self.sample_telemetry()
            except Exception as e:
                print(f"[!] Collector error: {e}", file=sys.stderr)
            elapsed = time.time() - start
            sleep_time = max(0.05, self.interval - elapsed)
            time.sleep(sleep_time)

    def start(self) -> None:
        """Starts background collector thread and foreground HTTP server."""
        self.running = True
        self.sample_telemetry()  # Initial immediate sample

        collector_thread = threading.Thread(target=self.run_loop, daemon=True, name="TelemetryCollector")
        collector_thread.start()

        print(f"[*] Heimdall daemon listening on http://{self.host}:{self.port}")
        try:
            self.server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            self.stop()

    def stop(self) -> None:
        """Gracefully halts collectors and server."""
        if self.running:
            self.running = False
            self.server.shutdown()
            self.server.server_close()
            print("[-] Heimdall daemon stopped.")


WatchCatDaemon = HeimdallDaemon


def main() -> None:
    parser = argparse.ArgumentParser(description="Heimdall Telemetry Daemon")
    parser.add_argument("--host", default="127.0.0.1", help="Bind IP address (default: 127.0.0.1)")
    parser.add_argument("--port", type=int, default=9871, help="Bind port (default: 9871)")
    parser.add_argument("--interval", type=float, default=1.0, help="Sampling interval in seconds (default: 1.0)")
    parser.add_argument("--interface", default=None, help="Network interface to monitor (default: auto)")
    parser.add_argument("--data-dir", default=None, help="Custom data persistence directory")

    args = parser.parse_args()
    daemon = HeimdallDaemon(
        host=args.host,
        port=args.port,
        interval=args.interval,
        interface=args.interface,
        data_dir=args.data_dir,
    )

    def handle_signal(sig: int, frame: Any) -> None:
        daemon.stop()
        sys.exit(0)

    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)

    daemon.start()


if __name__ == "__main__":
    main()
