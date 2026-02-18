#!/usr/bin/env python3
"""A minimal local HTTP forwarding proxy.

Usage:
    python localhost_proxy.py --host 127.0.0.1 --port 8080

Then configure your client/app to use the proxy at that host/port.
"""

from __future__ import annotations

import argparse
import http.server
import socketserver
import urllib.error
import urllib.parse
import urllib.request


HOP_BY_HOP_HEADERS = {
    "connection",
    "keep-alive",
    "proxy-authenticate",
    "proxy-authorization",
    "te",
    "trailers",
    "transfer-encoding",
    "upgrade",
    "proxy-connection",
}


class ThreadingHTTPProxy(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True


class ProxyHandler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def do_GET(self) -> None:
        self._forward_request()

    def do_POST(self) -> None:
        self._forward_request()

    def do_PUT(self) -> None:
        self._forward_request()

    def do_DELETE(self) -> None:
        self._forward_request()

    def do_HEAD(self) -> None:
        self._forward_request()

    def do_PATCH(self) -> None:
        self._forward_request()

    def do_OPTIONS(self) -> None:
        self._forward_request()

    def do_CONNECT(self) -> None:
        self.send_error(501, "CONNECT tunneling is not supported by this proxy")

    def _forward_request(self) -> None:
        target_url = self.path

        # Most proxy-aware clients send absolute URLs. Fall back to Host + path.
        if not urllib.parse.urlsplit(target_url).scheme:
            host = self.headers.get("Host")
            if not host:
                self.send_error(400, "Missing Host header")
                return
            target_url = f"http://{host}{self.path}"

        content_length = int(self.headers.get("Content-Length", "0") or "0")
        body = self.rfile.read(content_length) if content_length > 0 else None

        outgoing_headers = {
            key: value
            for key, value in self.headers.items()
            if key.lower() not in HOP_BY_HOP_HEADERS
        }
        outgoing_headers.pop("Host", None)

        request = urllib.request.Request(
            url=target_url,
            data=body,
            headers=outgoing_headers,
            method=self.command,
        )

        try:
            with urllib.request.urlopen(request, timeout=30) as upstream:
                response_body = upstream.read()
                self.send_response(upstream.status)

                for key, value in upstream.getheaders():
                    if key.lower() in HOP_BY_HOP_HEADERS:
                        continue
                    if key.lower() == "content-length":
                        continue
                    self.send_header(key, value)

                self.send_header("Content-Length", str(len(response_body)))
                self.end_headers()

                if self.command != "HEAD" and response_body:
                    self.wfile.write(response_body)
        except urllib.error.HTTPError as exc:
            response_body = exc.read() if exc.fp else b""
            self.send_response(exc.code)

            for key, value in exc.headers.items():
                if key.lower() in HOP_BY_HOP_HEADERS:
                    continue
                if key.lower() == "content-length":
                    continue
                self.send_header(key, value)

            self.send_header("Content-Length", str(len(response_body)))
            self.end_headers()
            if self.command != "HEAD" and response_body:
                self.wfile.write(response_body)
        except Exception as exc:  # noqa: BLE001
            self.send_error(502, f"Bad gateway: {exc}")

    def log_message(self, format: str, *args: object) -> None:
        # Keep logs concise but useful.
        print(f"[{self.log_date_time_string()}] {self.address_string()} - {format % args}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run a local HTTP forwarding proxy.")
    parser.add_argument("--host", default="127.0.0.1", help="Host/interface to bind to")
    parser.add_argument("--port", type=int, default=8080, help="Port to listen on")
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    server = ThreadingHTTPProxy((args.host, args.port), ProxyHandler)
    print(f"Proxy listening on http://{args.host}:{args.port}")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down proxy...")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
