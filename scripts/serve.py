import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer


class Handler(SimpleHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".js": "text/javascript",
        ".mjs": "text/javascript",
        ".json": "application/json",
        ".svg": "image/svg+xml",
        ".mp3": "audio/mpeg",
        ".webmanifest": "application/manifest+json",
    }

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, default=5500)
parser.add_argument("--bind", default="0.0.0.0")
args = parser.parse_args()
ThreadingHTTPServer((args.bind, args.port), partial(Handler, directory=".")).serve_forever()
