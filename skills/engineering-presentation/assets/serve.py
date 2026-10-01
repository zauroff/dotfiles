#!/usr/bin/env python3
"""Serve this directory with caching switched off.

`python3 -m http.server` sends no cache headers, and Chrome caches ES modules
hard: edit a scene, refresh, and you are still running the old module. That
looks exactly like your change not working. Restarting the server does not
help, because the stale copy is in the browser.

    ./serve.py [port]        # default 8000
"""

import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class NoCacheHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store, must-revalidate")
        super().end_headers()

    def log_message(self, fmt, *args):
        if "GET / " in fmt % args or " 404 " in fmt % args:
            super().log_message(fmt, *args)


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    handler = partial(NoCacheHandler, directory=".")

    print(f"http://localhost:{port}  (no-store; edits show up on a plain refresh)")
    try:
        ThreadingHTTPServer(("", port), handler).serve_forever()
    except KeyboardInterrupt:
        print()


if __name__ == "__main__":
    main()
