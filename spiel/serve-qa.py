import os
import runpy
from pathlib import Path
from functools import partial
from http.server import ThreadingHTTPServer
root=Path(__file__).resolve().parents[1]
os.environ['GAME_DB']=str(root/'spiel/output/cartoon-qa.sqlite')
module=runpy.run_path(str(root/'spiel/server.py'))
server=ThreadingHTTPServer(('127.0.0.1',18087),partial(module['Handler'],directory=str(root/'godot/build')))
print('Isolated Godot QA at http://127.0.0.1:18087',flush=True)
server.serve_forever()
