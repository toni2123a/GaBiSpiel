"""API integration tests use a temporary SQLite database and an ephemeral port."""
import concurrent.futures
import json
import os
from pathlib import Path
import runpy
import sqlite3
import tempfile
import threading
import unittest
from functools import partial
from http.server import ThreadingHTTPServer
from urllib.error import HTTPError
from urllib.request import Request, urlopen

class ApiTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix='gabi-api-qa-')
        cls.db = Path(cls.temp.name) / 'qa.sqlite'
        cls.old_db = os.environ.get('GAME_DB')
        os.environ['GAME_DB'] = str(cls.db)
        cls.module = runpy.run_path(str(Path(__file__).with_name('server.py')))
        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), partial(cls.module['Handler'], directory=cls.temp.name))
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()
        cls.base = f'http://127.0.0.1:{cls.server.server_port}'

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join(timeout=2)
        if cls.old_db is None:
            os.environ.pop('GAME_DB', None)
        else:
            os.environ['GAME_DB'] = cls.old_db
        cls.temp.cleanup()

    def request(self, method, path, data=None):
        body = json.dumps(data).encode() if data is not None else None
        request = Request(self.base + path, data=body, method=method, headers={'Content-Type':'application/json'})
        try:
            with urlopen(request, timeout=12) as response:
                return response.status, json.load(response)
        except HTTPError as response:
            with response:
                return response.code, json.load(response)

    def test_legacy_and_upgrade_state(self):
        item = {'id': 1, 'type':'fridge', 'room':'workshop', 'x':.2, 'z':1.1, 'rot':0}
        self.assertEqual(self.request('PUT','/api/state',{'items':[item]})[0],200)
        data = self.request('GET','/api/state')[1]
        self.assertEqual(data['items'][0]['level'],1)
        self.assertEqual(data['items'][0]['scale'],1)
        item.update(level=2, scale=1.2, rot=3)
        self.assertEqual(self.request('PUT','/api/state',{'items':[item]})[0],400)
        self.assertEqual(self.request('PUT','/api/state',{'items':[item],'unlocks':['cold']})[0],200)
        self.assertEqual(self.request('GET','/api/state')[1]['items'][0]['level'],2)
        poster = {**item,'id':2,'type':'poster','level':1,'h':65,'scale':1.1}
        self.assertEqual(self.request('PUT','/api/state',{'items':[poster],'unlocks':[]})[0],200)
        for bad in [{**poster,'scale':2},{**poster,'rot':True},{**poster,'h':float('nan')},{**poster,'level':2}]:
            self.assertEqual(self.request('PUT','/api/state',{'items':[bad]})[0],400)
        self.assertEqual(self.request('PUT','/api/state',{'items':[poster,poster]})[0],400)

    def test_catalog_crud_and_no_reseed(self):
        code, data = self.request('GET','/api/drinks')
        self.assertEqual(code,200)
        self.assertEqual({d['category'] for d in data['drinks']},{'water','beer','lemonade','cocktail'})
        record = {'id':'qa-water','category':'water','name':'Apfelschorle','stock':3,'note':'Test'}
        self.assertEqual(self.request('POST','/api/drinks',record)[0],200)
        record['name'] = 'Neue Schorle'
        self.assertEqual(self.request('POST','/api/drinks',record)[0],200)
        self.assertEqual(self.request('POST','/api/drinks/take',{'id':'qa-water'})[1]['drink']['stock'],2)
        self.assertEqual(self.request('DELETE','/api/drinks/qa-water')[0],200)
        self.assertEqual(self.request('DELETE','/api/drinks/water')[0],200)
        runpy.run_path(str(Path(__file__).with_name('server.py')))
        self.assertFalse(any(d['id']=='water' for d in self.request('GET','/api/drinks')[1]['drinks']))
        for bad in [{**record,'stock':-2},{**record,'stock':True},{**record,'name':''},{**record,'category':'unknown'}]:
            self.assertEqual(self.request('POST','/api/drinks',bad)[0],400)

    def test_stock_is_atomic(self):
        self.request('POST','/api/drinks',{'id':'last-two','category':'beer','name':'Letzte zwei','stock':2})
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            codes = list(pool.map(lambda _: self.request('POST','/api/drinks/take',{'id':'last-two'})[0],range(4)))
        self.assertEqual(sorted(codes),[200,200,409,409])
        drink = next(d for d in self.request('GET','/api/drinks')[1]['drinks'] if d['id']=='last-two')
        self.assertEqual((drink['stock'],drink['taken']),(0,2))
        with self.module['database']() as conn:
            self.assertEqual(conn.execute('PRAGMA integrity_check').fetchone()[0],'ok')

if __name__ == '__main__':
    unittest.main(verbosity=2)
