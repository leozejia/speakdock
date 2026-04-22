#!/usr/bin/env python3

import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--port", type=int, required=True)
    parser.add_argument("--response-text", required=True)
    parser.add_argument("--status-code", type=int, default=200)
    parser.add_argument("--record-user-message")
    parser.add_argument("--advertised-model")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    def record_user_message(body: bytes) -> None:
        if not args.record_user_message:
            return

        extracted_text = ""

        try:
            payload = json.loads(body.decode("utf-8"))
            messages = payload.get("messages", [])
            for message in reversed(messages):
                if message.get("role") != "user":
                    continue

                content = str(message.get("content", ""))
                if "输入：" in content and "\n输出：" in content:
                    extracted_text = content.split("输入：", 1)[1].split("\n输出：", 1)[0].strip()
                else:
                    parts = content.split("\n\n", 1)
                    extracted_text = parts[1].strip() if len(parts) == 2 else content.strip()
                break
        except (UnicodeDecodeError, json.JSONDecodeError, AttributeError):
            extracted_text = ""

        with open(args.record_user_message, "w", encoding="utf-8") as handle:
            handle.write(extracted_text)

    class Handler(BaseHTTPRequestHandler):
        def do_GET(self) -> None:
            if self.path not in ("/v1/models", "/models"):
                self.send_error(404)
                return

            models = []
            if args.advertised_model:
                models.append({"id": args.advertised_model})

            encoded = json.dumps({"data": models}).encode("utf-8")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(encoded)))
            self.end_headers()
            self.wfile.write(encoded)

        def do_POST(self) -> None:
            if self.path not in ("/v1/chat/completions", "/chat/completions"):
                self.send_error(404)
                return

            length = int(self.headers.get("Content-Length", "0"))
            body = b""
            if length > 0:
                body = self.rfile.read(length)

            record_user_message(body)

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
