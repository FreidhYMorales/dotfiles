#!/usr/bin/env python3
"""matugen output HTTP server — serves files + /notify and /version endpoints."""

from http.server import HTTPServer, SimpleHTTPRequestHandler
import os, sys

OUTPUT_DIR = os.path.expanduser('~/.config/matugen/output')
_version = 0


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=OUTPUT_DIR, **kwargs)

    def do_GET(self):
        path = self.path.split('?')[0]
        if path == '/notify':
            global _version
            _version += 1
            self._text(200, str(_version))
        elif path == '/version':
            self._text(200, str(_version))
        else:
            super().do_GET()

    def _text(self, code, body):
        data = body.encode()
        self.send_response(code)
        self.send_header('Content-Type', 'text/plain')
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Access-Control-Allow-Origin', '*')
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *_):
        pass


if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 9119
    HTTPServer(('127.0.0.1', port), Handler).serve_forever()
