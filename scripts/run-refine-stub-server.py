#!/usr/bin/env python3

import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--response-text", required=True)
    parser.add_argument("--status-code", type=int, default=200)
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    class Handler(BaseHTTPRequestHandler):
        def do_POST(self) -> None:
            if self.path not in ("/v1/chat/completions", "/chat/completions"):
                self.send_error(404)
                return

            length = int(self.headers.get("Content-Length", "0"))
            if length > 0:
                _ = self.rfile.read(length)

            if args.status_code != 200:
                encoded = json.dumps({"error": {"message": "stub failure"}}).encode("utf-8")
                self.send_response(args.status_code)
                self.send_header("Content-Type", "application/json")
                self.send_header("Content-Length", str(len(encoded)))
                self.end_headers()
                self.wfile.write(encoded)
                return

            payload = {
                "choices": [
                    {
                        "message": {
                            "role": "assistant",
                            "content": args.response_text,
                        }
                    }
                ]
            }
            encoded = json.dumps(payload).encode("utf-8")

            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)

        def log_message(self, format: str, *args) -> None:
            return

    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    server.serve_forever()


if __name__ == "__main__":
    main()
