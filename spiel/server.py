"""Static game and one shared SQLite save, without accounts or dependencies."""
import json
import math
import os
import sqlite3
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB = Path(os.environ.get('GAME_DB', str(ROOT / 'data' / 'game.sqlite')))
DB.parent.mkdir(parents=True, exist_ok=True)
with sqlite3.connect(DB) as conn:
    conn.execute('CREATE TABLE IF NOT EXISTS game (id INTEGER PRIMARY KEY CHECK(id=1), payload TEXT NOT NULL)')

class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header('X-Content-Type-Options', 'nosniff')
        self.send_header('Cache-Control', 'no-store')
        # Godot WebAssembly/audio workers require an isolated browser context.
        self.send_header('Cross-Origin-Opener-Policy', 'same-origin')
        self.send_header('Cross-Origin-Embedder-Policy', 'require-corp')
        super().end_headers()

    def reply(self, code, data):
        body = json.dumps(data, ensure_ascii=False).encode('utf-8')
        self.send_response(code)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path.split('?')[0] == '/api/state':
            try:
                with sqlite3.connect(DB) as conn:
                    row = conn.execute('SELECT payload FROM game WHERE id=1').fetchone()
                return self.reply(200, json.loads(row[0]) if row else {'items': []})
            except sqlite3.Error:
                return self.reply(503, {'error': 'Spielstand derzeit nicht verfügbar'})
        super().do_GET()

    def do_PUT(self):
        if self.path != '/api/state':
            return self.reply(404, {'error': 'Nicht gefunden'})
        try:
            size = int(self.headers.get('Content-Length', '0'))
            if not 0 < size <= 250_000:
                return self.reply(413, {'error': 'Spielstand zu groß'})
            data = json.loads(self.rfile.read(size))
            items = data['items']
            if not isinstance(items, list) or len(items) > 300:
                raise ValueError()
            unlocks = data.get('unlocks', [])
            if not isinstance(unlocks, list) or len(unlocks) > 3 or any(type(key) is not str or key not in {'cold', 'work', 'comfort'} for key in unlocks):
                raise ValueError()
            clean = []
            ids = set()
            for i in items:
                if i['type'] not in {'bench','fridge','beer','tools','sofa','radio','poster','bunting','shelf'} or i['room'] not in {'garage','workshop','oil'}:
                    raise ValueError()
                x, z = i['x'], i['z']
                if type(x) not in (int, float) or type(z) not in (int, float) or not 0 <= x <= 4 or not 0 <= z <= 7:
                    raise ValueError()
                if type(i['id']) is not int or i['id'] in ids or type(i['rot']) is not int or i['rot'] not in (0, 1, 2, 3):
                    raise ValueError()
                scale, level, height = i.get('scale', 1.0), i.get('level', 1), i.get('h', 110.0)
                if type(scale) not in (int, float) or not math.isfinite(scale) or not .6 <= scale <= 1.6:
                    raise ValueError()
                if type(level) is not int or level not in (1, 2) or type(height) not in (int, float) or not math.isfinite(height) or not 0 <= height <= 200:
                    raise ValueError()
                quest = {'bench':'work', 'tools':'work', 'fridge':'cold', 'beer':'cold', 'sofa':'comfort', 'radio':'comfort'}.get(i['type'])
                if level == 2 and (quest is None or quest not in unlocks):
                    raise ValueError()
                ids.add(i['id'])
                clean.append({**{k: i[k] for k in ('id','type','room','x','z','rot')}, 'scale': scale, 'level': level, 'h': height})
            payload = json.dumps({'items': clean, 'unlocks': sorted(set(unlocks))}, allow_nan=False)
            with sqlite3.connect(DB, timeout=10) as conn:
                conn.execute('INSERT INTO game VALUES (1, ?) ON CONFLICT(id) DO UPDATE SET payload=excluded.payload', (payload,))
            return self.reply(200, {'saved': True})
        except (ValueError, KeyError, TypeError):
            return self.reply(400, {'error': 'Ungültiger Spielstand'})
        except sqlite3.Error:
            return self.reply(503, {'error': 'Speichern derzeit nicht möglich'})

if __name__ == '__main__':
    server = ThreadingHTTPServer(('0.0.0.0', int(os.environ.get('PORT', '8080'))), partial(Handler, directory=str(ROOT / 'dist')))
    print(f"Dirks Garage läuft auf Port {server.server_port}", flush=True)
    server.serve_forever()
