# GaBi bei Dirk · Godot 2D

Spielbarer Godot-Port mit Figurenwahl, Start vor dem Haus, Sektionaltor, Mauslaufwegen mit AStarGrid2D, Garage, Werkstatt, Wandluke und Einrichtung. Das Öllager ist nicht begehbar. Der Papierkulissenstil und die Figuren aus dem bereitgestellten Charactersheet bleiben erhalten.

## Im Editor

`project.godot` mit Godot 4.7.2 Standard öffnen und F6/F5 verwenden. F5 startet das gesamte Spiel. Die portable Engine liegt lokal unter `../tools/godot/`. Für die native Vorschau muss der vorhandene Speicherserver auf http://localhost:8085 laufen.

Die Hauptszene ist `scenes/main.tscn`, die Figur `scenes/player.tscn`. `scripts/game.gd` steuert Eingaben, Godot-UI, AStarGrid2D und API-Aufrufe. `scripts/world.gd` zeichnet die Papierkulissen mit Godot CanvasItem. `scripts/player.gd` zeichnet die ausgeschnittene Figur aus dem Sheet und animiert sie beim Laufen. Kein Browser-Canvas-Spiel wird eingebettet.

## Browser-Export

```powershell
.\build-web.ps1
```

Exportvorlagen und portable Engine liegen unter `../tools/godot/`. Das Web-Preset verwendet den Compatibility-Renderer, GDScript und die Vorlage ohne Threads. Exportdateien liegen in `build/`.

## Docker

Im Ordner `../spiel`:

```sh
docker compose -f compose.yaml -f compose.godot.yaml up -d --build
```

http://localhost:8085 öffnet die Godot-Version. Der Godot-Webexport ist im Image enthalten und benötigt keine lokale Dateifreigabe. Das bestehende Volume `spiel_game-data` bleibt die SQLite-Datenbank. Der Spielstand ist gemeinsam und hat keinen Login. API und Speicherformat sind mit dem bisherigen Prototyp kompatibel.

Für den Server diese Dateien mitnehmen: `godot/build/`, `godot/Dockerfile`, `spiel/server.py`, `spiel/compose.yaml`, `spiel/compose.godot.yaml` und die `.dockerignore` im Projektstamm. Das Datenvolume separat sichern und übertragen. Die Exportdateien brauchen einen Webserver; direktes Öffnen von `index.html` als lokale Datei funktioniert nicht.

## Bedienung und Tests

Beim Start Dirk oder Ela wählen. Boden anklicken zum Laufen, geschlossenes Tor anklicken zum Öffnen, erneut anklicken zum Betreten. Die Brandschutztür führt eine Stufe hinauf zur Werkstatt. Die Wandluke zeigt nur die Ölcontainer. Möbel rechts wählen, Boden anklicken zum Platzieren. Vorhandene Möbel anklicken zum Verschieben. R dreht, Entf entfernt, Esc beendet das Einrichten. F schaltet Vollbild um.

`node test-godot.mjs` im Ordner `spiel` prüft die Godot-Version auf Port 8085 mit einem simulierten Spielstand. Der echte SQLite-Spielstand wird dabei nicht geändert. Testbilder liegen unter `spiel/output/godot-qa/`.

Der erste Port ist für Desktop und Querformat ausgelegt. Das Hochformat zeigt derzeit die gesamte Oberfläche verkleinert. Live-Multiplayer, eigene Avatare und Bierstatus folgen als getrennte Erweiterungen.
