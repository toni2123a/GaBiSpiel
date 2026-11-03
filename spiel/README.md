# GaBi bei Dirk

Die aktive Version ist jetzt das Godot-2D-Projekt unter `../godot`. `docker compose up -d --build` baut standardmäßig die Godot-Version. Editor und Web-Export sind in `../godot/README.md` beschrieben. Vor dem Docker-Build muss `../godot/build-web.ps1` ausgeführt worden sein; der aktuelle Web-Export ist bereits vorhanden.

Der frühere HTML-Prototyp bleibt unter `dist` erhalten. Er kann bei Bedarf mit `docker compose -f compose.yaml -f compose.legacy.yaml up -d --build` gestartet werden.

Lokales Spiel mit SQLite und ohne Login. Alle Besucher teilen einen Spielstand.

Im Ordner `spiel` starten:

```sh
docker compose up -d --build
```

Danach http://localhost:8085 öffnen. Der Host-Port ist mit `GAME_PORT` anpassbar. `docker compose stop` hält das Spiel an. Mit `docker compose up -d --build` werden neue Spielversionen übernommen.

Die SQLite-Datenbank liegt unter `/data/game.sqlite` im Volume `spiel_game-data`. Dieses Volume beim Serverumzug übernehmen und sichern. `docker compose down` erhält es. `docker compose down -v` löscht die Spielstände.

Ohne Docker: `python server.py`, ebenfalls unter http://localhost:8080. Die Datenbank liegt dann in `data/game.sqlite`. Python verwendet nur die Standardbibliothek.

Für die eigene Website den Reverse Proxy auf Host-Port 8085 oder im gemeinsamen Docker-Netz auf Container-Port 8080 weiterleiten. Bei Einbindung unter einem Unterpfad den Präfix vor Weitergabe an den Container entfernen. Es gibt keine Anmeldung; alle Besucher können die gemeinsame Einrichtung ändern. Bei gleichzeitigen Änderungen wird der zuletzt gespeicherte Stand übernommen. Live-Anwesenheit und Mehrspielerbewegung sind noch nicht implementiert.

Raum über Reiter oder Durchgänge wechseln. Möbel im Katalog auswählen und auf dem Boden platzieren. Bestehende Möbel anklicken und versetzen. R dreht, Entf entfernt, Esc beendet das Platzieren. Pfeiltasten bewegen die aktive Figur. Dirk und Ela lassen sich rechts auswählen. F schaltet Vollbild um.

Beim Start Dirk oder Ela auswählen. Die Figur beginnt vor dem Haus. Auf den Boden klicken, um mit Wegsuche um Möbel zum Ziel zu laufen. Das Sektionaltor anklicken zum Öffnen, nochmal anklicken zum Betreten. Die Werkstatt ist der Treffpunkt für das Garagen-Bier. Das Öllager ist ausschließlich durch Öffnen der kleinen Wandluke einsehbar und nicht begehbar. Figuren werden direkt aus dem bereitgestellten Charactersheet dargestellt. Einrichtung wird automatisch über die API in SQLite gespeichert. Der Browser hält zusätzlich eine lokale Kopie für fehlgeschlagene Speicheranfragen.

Geplanter Ausbau: eigene Figuren, Bier-Status, gemeinsame GaBi-Runde mit Live-Anwesenheit, später begehbares Haus und Umgebung.
