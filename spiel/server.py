"""Static game and one shared SQLite save, without accounts or dependencies."""
import json
import math
import os
import re
import uuid
import sqlite3
from functools import partial
from contextlib import contextmanager
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent
DB = Path(os.environ.get('GAME_DB', str(ROOT / 'data' / 'game.sqlite')))
DB.parent.mkdir(parents=True, exist_ok=True)

@contextmanager
def database():
    conn = sqlite3.connect(DB, timeout=10)
    try:
        with conn:
            yield conn
    finally:
        conn.close()

with database() as conn:
    conn.execute('CREATE TABLE IF NOT EXISTS game (id INTEGER PRIMARY KEY CHECK(id=1), payload TEXT NOT NULL)')
    conn.execute("CREATE TABLE IF NOT EXISTS drinks (id TEXT PRIMARY KEY, category TEXT NOT NULL, name TEXT NOT NULL, stock INTEGER NOT NULL DEFAULT -1, note TEXT NOT NULL DEFAULT '', taken INTEGER NOT NULL DEFAULT 0)")
    conn.execute('CREATE TABLE IF NOT EXISTS catalog_meta (key TEXT PRIMARY KEY, value TEXT NOT NULL)')
    if not conn.execute("SELECT 1 FROM catalog_meta WHERE key='drinks_seeded'").fetchone():
        conn.executemany('INSERT OR IGNORE INTO drinks (id,category,name,stock,note) VALUES (?,?,?,?,?)', [
            ('water','water','Mineralwasser',-1,'Mit oder ohne Feierabend.'),
            ('beer','beer','Garagen-Bier',-1,'Für die nächste GaBi.'),
            ('lemonade','lemonade','Zitronenlimonade',-1,'Kalt und spritzig.'),
            ('cocktail','cocktail','Haus-Cocktail',-1,'Die Mischung bestimmt ihr.')])
        conn.execute("INSERT INTO catalog_meta VALUES ('drinks_seeded','1')")

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
        if self.path.split('?')[0] == '/api/drinks':
            try:
                with database() as conn:
                    conn.row_factory = sqlite3.Row
                    rows = conn.execute('SELECT * FROM drinks ORDER BY category,name').fetchall()
                return self.reply(200, {'drinks': [dict(row) for row in rows]})
            except sqlite3.Error:
                return self.reply(503, {'error': 'Getränkekarte derzeit nicht verfügbar'})
        if self.path.split('?')[0] == '/api/state':
            try:
                with database() as conn:
                    row = conn.execute('SELECT payload FROM game WHERE id=1').fetchone()
                return self.reply(200, json.loads(row[0]) if row else {'items': []})
            except sqlite3.Error:
                return self.reply(503, {'error': 'Spielstand derzeit nicht verfügbar'})
        super().do_GET()

    def read_json(self):
        size = int(self.headers.get('Content-Length', '0'))
        if not 0 < size <= 16_000:
            raise ValueError()
        data = json.loads(self.rfile.read(size))
        if not isinstance(data, dict):
            raise ValueError()
        return data

    def do_POST(self):
        if self.path not in ('/api/drinks', '/api/drinks/take'):
            return self.reply(404, {'error': 'Nicht gefunden'})
        try:
            data = self.read_json()
            drink_id = data.get('id') or uuid.uuid4().hex
            if not isinstance(drink_id, str) or not re.fullmatch(r'[A-Za-z0-9_-]{1,64}', drink_id):
                raise ValueError()
            with database() as conn:
                conn.row_factory = sqlite3.Row
                if self.path == '/api/drinks/take':
                    changed = conn.execute('UPDATE drinks SET stock=CASE WHEN stock>0 THEN stock-1 ELSE stock END,taken=taken+1 WHERE id=? AND stock!=0', (drink_id,)).rowcount
                    if not changed:
                        return self.reply(409, {'error': 'Dieses Getränk ist leider gerade leer.'})
                    drink = dict(conn.execute('SELECT * FROM drinks WHERE id=?', (drink_id,)).fetchone())
                    conn.commit()
                    return self.reply(200, {'drink': drink})
                category, name, stock, note = data['category'], data['name'], data.get('stock', -1), data.get('note', '')
                if category not in {'water','beer','lemonade','cocktail'} or not isinstance(name, str) or not 1 <= len(name.strip()) <= 80:
                    raise ValueError()
                if type(stock) is not int or not -1 <= stock <= 9999 or not isinstance(note, str) or len(note) > 200:
                    raise ValueError()
                if not conn.execute('SELECT 1 FROM drinks WHERE id=?', (drink_id,)).fetchone() and conn.execute('SELECT COUNT(*) FROM drinks').fetchone()[0] >= 200:
                    raise ValueError()
                conn.execute('INSERT INTO drinks(id,category,name,stock,note) VALUES (?,?,?,?,?) ON CONFLICT(id) DO UPDATE SET category=excluded.category,name=excluded.name,stock=excluded.stock,note=excluded.note', (drink_id,category,name.strip(),stock,note))
            return self.reply(200, {'saved': True, 'id': drink_id})
        except (ValueError, KeyError, TypeError):
            return self.reply(400, {'error': 'Ungültiger Getränkeeintrag'})
        except sqlite3.Error:
            return self.reply(503, {'error': 'Getränkekarte derzeit nicht verfügbar'})

    def do_DELETE(self):
        if not self.path.startswith('/api/drinks/'):
            return self.reply(404, {'error': 'Nicht gefunden'})
        drink_id = self.path.removeprefix('/api/drinks/')
        if not re.fullmatch(r'[A-Za-z0-9_-]{1,64}', drink_id):
            return self.reply(400, {'error': 'Ungültiges Getränk'})
        try:
            with database() as conn:
                conn.execute('DELETE FROM drinks WHERE id=?', (drink_id,))
            return self.reply(200, {'deleted': True})
        except sqlite3.Error:
            return self.reply(503, {'error': 'Löschen derzeit nicht möglich'})

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
            with database() as conn:
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
