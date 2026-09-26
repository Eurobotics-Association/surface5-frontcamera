#!/usr/bin/env python3
# SPDX-License-Identifier: GPL-2.0-only
"""Local-only server for the browser WebRTC diagnostic; stores textual events."""
from __future__ import annotations

import argparse
import json
from http import HTTPStatus
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from threading import Lock


class Handler(SimpleHTTPRequestHandler):
    root: Path
    events: Path
    access_log: Path
    write_lock = Lock()

    def log_message(self, fmt: str, *args: object) -> None:
        with self.write_lock, self.access_log.open("a", encoding="utf-8") as handle:
            handle.write("%s\n" % (fmt % args))

    def translate_path(self, path: str) -> str:
        relative = Path(super().translate_path(path)).name
        candidate = (self.root / relative).resolve()
        if candidate.parent != self.root or not candidate.is_file():
            return str(self.root / "webrtc-camera-test.html")
        return str(candidate)

    def do_POST(self) -> None:
        if self.path != "/report":
            self.send_error(HTTPStatus.NOT_FOUND)
            return
        length = int(self.headers.get("Content-Length", "0"))
        if length > 16_384:
            self.send_error(HTTPStatus.REQUEST_ENTITY_TOO_LARGE)
            return
        try:
            event = json.loads(self.rfile.read(length).decode("utf-8"))
            if not isinstance(event, dict) or not isinstance(event.get("event"), str):
                raise ValueError("event must be an object with an event string")
        except (UnicodeDecodeError, ValueError, json.JSONDecodeError) as error:
            self.send_error(HTTPStatus.BAD_REQUEST, str(error))
            return
        with self.write_lock, self.events.open("a", encoding="utf-8") as handle:
            json.dump(event, handle, ensure_ascii=False, separators=(",", ":"))
            handle.write("\n")
        self.send_response(HTTPStatus.NO_CONTENT)
        self.end_headers()


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--port", default=0, type=int)
    args = parser.parse_args()
    Handler.root = args.root.resolve()
    Handler.events = args.output / "webrtc-events.jsonl"
    Handler.access_log = args.output / "http-access.log"
    server = ThreadingHTTPServer(("127.0.0.1", args.port), Handler)
    host, port = server.server_address
    print(f"LISTENING http://{host}:{port}/webrtc-camera-test.html", flush=True)
    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
