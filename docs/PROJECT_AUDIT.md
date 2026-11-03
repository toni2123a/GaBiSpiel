# Projektaudit vor der Umsetzung

Stand: 03.11.2026. Grundlage sind alle drei aktiven GDScripts, beide Szenen, Projekt- und Exportkonfiguration, Assets, Server, Compose-Dateien und die drei Godot-Browsersuiten. Der HTML-Prototyp bleibt als Altbestand erhalten. Bewertungen beziehen sich auf professionelle Indie-Veröffentlichungen, nicht auf den Umfang eines Geburtstagsspiels.

## Bestandsaufnahme

- Godot 4.7.2 Standard, Compatibility-Renderer, Web ohne Threads. Keine Plugins, Autoloads oder externen Godot-Bibliotheken. Webexport und portable Engine vorhanden.
- `main.tscn`: GaBi/World und HUD als CanvasLayer. `player.tscn`: einzelner Node2D. Oberfläche und modale Fenster entstehen im Code. HTTPRequest-Signale und Button-Callables verbinden Abläufe direkt.
- `game.gd` verbindet Navigation, Einrichtung, Oberfläche und API. `world.gd` zeichnet Kulisse und Möbel. `player.gd` maskiert und zeichnet acht Ansichten aus dem Originalsheet. Ressourcenreferenzen sind lokal und explizit.
- Vorhanden: verpflichtende Figurenwahl, Klicknavigation mit AStar und geglätteten Wegen, begehbare Zufahrt, Tor, Garage, Werkstatt, reine Öllageransicht, sechs Möbeltypen, Drehen/Verschieben/Löschen, gemeinsame SQLite-Speicherung, Einrichtungsziele, Vollbild.
- Eingaben: Maus sowie R/Entf/Esc/F direkt im Skript. Buttons grundsätzlich fokussierbar, aber keine gestalteten Fokuszustände oder initialen Dialogfoki. Weltbewegung ausschließlich per Klick.
- Nicht vorhanden: Dialogsystem mit Optionen, Audio, Pause/Einstellungen, Controller-Weltsteuerung, Multiplayer, eigene Avatare. Multiplayer und Bierstatus sind nur als spätere Ideen in progress.md vermerkt.

## Bewertung und belegbare Befunde

| Bereich | Vorher | Befund |
| --- | --- | --- |
| Projektstruktur | 7/10 | Kleine nachvollziehbare Szenen, keine Pluginlast; viel UI-/API-Logik in einer Datei. |
| Technische Qualität | 5/10 | Ladeprüfung greift auf ungeprüfte id/rot/x/z zu. Fehlgeschlagene asynchrone Saves setzen keinen offenen Speicherstatus. Wiederholtes Laden kann konkurrierende Requests auslösen. |
| Charakterdesign | 7/10 | Dirk und Ela bleiben durch Sheet-Ansichten erkennbar. Konturen und Randmasken erhalten Augen. Auswahlporträts verwenden noch unmaskierte Ausschnitte. |
| Animation | 3/10 | Gesamte Figur bewegt sich beim Laufen sinusförmig. Keine getrennten Beine, Idle- oder Interaktionsbewegung. Front nach Ankunft ist ausdrücklich getestetes Verhalten. |
| Visuelle Konsistenz | 6/10 | Einheitliche Konturen und warme Papierfarben. Straße wird auch im Innenraum gezeichnet. Möbel überdecken Figur nie korrekt, weil sie im Parent gezeichnet werden. |
| UI/UX | 5/10 | Gut lesbar am Desktop, feste 1400×930-Koordinaten. Hochformat verkleinert alles. Ungültige Vorschau verschwindet, R aktualisiert Gültigkeit erst nach Mausbewegung. |
| Game Feel | 5/10 | Stabile Blickrichtung und geglättete Wege vorhanden. Sofortiges Tempo, abrupte Raumwechsel, kaum Interaktionsrückmeldung. |
| Architektur | 6/10 | Verantwortlichkeiten grob getrennt, keine unnötigen Singletons. Daten und UI fest eingebaut. Neues Framework wäre für diesen Umfang unverhältnismäßig. |
| Performance | 6/10, vorläufig | Texturen gecacht. Welt und Figur werden dauernd neu gezeichnet. AStar-Raster entsteht pro Klick. Keine Messung auf schwachen Geräten. |
| Wartbarkeit | 6/10 | Kurze Dateien und explizite Ressourcen. Automatisierte Regressionen vorhanden, Fehlerpfade kaum abgedeckt. |
| Produktionsreife | 5/10 | Start- und Exportwerkzeuge vorhanden. Keine dokumentierten Assetlizenzen, keine Release-/Gerätematrix. |

## Prioritäten und Grenzen

Zuerst Lade-/Speicherfehler und Platzierungsfeedback beheben. Danach native Fokusdarstellung, maskierte Porträts, dezente Cutout-Bewegung, Raumüberblendung und korrekte Tiefensortierung. Originalbilder bleiben unverändert. Eine feste Kamera ist für die vollständig sichtbaren Räume sinnvoll; Kamerafahrten und Parallax würden hier die Bedienkoordinaten verschieben, ohne Navigation zu verbessern. Talk und Emotionen haben aktuell keinen Gameplay-Auslöser und werden nicht als fertige Systeme vorgetäuscht.

Der Ausgangszustand ist durch einen lokalen Git-Commit gesichert. Vorherbilder liegen in `spiel/output/quality-before/`. Die vorhandene Browsersuite wird als Baseline ausgeführt; Ergebnisse und Nachherbewertung folgen in QUALITY_REPORT.md. Die reale SQLite-Datenbank wird nicht bearbeitet.
