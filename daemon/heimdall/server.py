"""Threaded HTTP API server and request routing for WatchCat telemetry."""

import json
from http.server import BaseHTTPRequestHandler, HTTPServer
from socketserver import ThreadingMixIn
from typing import Any, Callable, Dict


class ThreadedHTTPServer(ThreadingMixIn, HTTPServer):
    """Handles requests concurrently in separate threads to prevent head-of-line blocking."""
    daemon_threads = True


def make_api_handler(
    get_telemetry_fn: Callable[[], Dict[str, Any]],
    get_budget_fn: Callable[[], Dict[str, Any]],
    get_week_fn: Callable[[], Any]
) -> type:
    """Factory creating a BaseHTTPRequestHandler bound to live telemetry data providers."""

    class TelemetryRequestHandler(BaseHTTPRequestHandler):
        def _send_json(self, payload: Any, status: int = 200) -> None:
            data = json.dumps(payload).encode("utf-8")
            self.send_response(status)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.send_header("Content-Length", str(len(data)))
            self.send_header("Access-Control-Allow-Origin", "*")
            self.end_headers()
            self.wfile.write(data)

        def do_GET(self) -> None:
            path = self.path.split("?")[0]
            if path == "/api/telemetry":
                self._send_json(get_telemetry_fn())
            elif path == "/api/budget":
                self._send_json(get_budget_fn())
            elif path == "/api/week":
                self._send_json(get_week_fn())
            elif path == "/health":
                self._send_json({"status": "ok", "service": "heimdall-daemon", "version": "1.1.0"})
            else:
                self._send_json({"error": "Not Found", "endpoint": path}, status=404)

        def log_message(self, format: str, *args: Any) -> None:
            # Suppress normal access logs to prevent console/systemd journal noise
            pass

    return TelemetryRequestHandler
