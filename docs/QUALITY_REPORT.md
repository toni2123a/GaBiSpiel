# Qualitätsbericht

Stand: 03.11.2026. Ausgangspunkt ist Commit `61cc7f6`, die Bewertung vor Änderungen steht in PROJECT_AUDIT.md. Die wichtigsten risikoarmen Maßnahmen aus der todo.txt wurden umgesetzt. Das Projekt ist damit verbessert, aber kein in allen Bereichen mit 9/10 bewertetes Release.

## Umgesetzt

- Vollständige Prüfung geladener Möbelfelder, Mengenbegrenzung und Ablehnung doppelter IDs. Eine defekte Antwort überschreibt den letzten brauchbaren Zustand nicht. JSON-Zahlen werden vor der Übernahme korrekt geprüft und IDs/Rotation anschließend konvertiert.
- Fehlgeschlagene Saves behalten ihren offenen Zustand. Der Button „Speichern wiederholen“ sendet den aktuellen Stand erneut; Neuladen ist während offener oder laufender Saves gesperrt. Kein automatischer Retry-Sturm und keine Änderung an Server, Schema oder Datenvolume.
- Sofortige Aktualisierung der Vorschau beim Drehen und bei Werkzeugwahl. Rote Stellflächen erklären ungültige Positionen, grüne Flächen gültige. Möbel können nicht auf die Figur gestellt werden.
- Möbel haben eigene CanvasItems in `furniture.gd`. Figur und Möbel sortieren nach Bodentiefe; die Vorschau ist halbtransparent. Klickflächen folgen der projizierten Möbelhülle statt einem übergroßen Rechteck. Dadurch lassen sich freie Flächen hinter Möbeln wieder anwählen.
- Auswahlporträts verwenden dieselbe Randmaske wie die Spielfigur. Originalsheet und Identität von Dirk und Ela bleiben erhalten.
- Cutout-Beinsegmente mit gegenläufigem Schwingen, weiches Ein-/Ausblenden des Laufzyklus, dezente Idle-Bewegung und kurze Reaktion bei Toröffnung und Platzierung. Das vorhandene Frontbild nach Ankunft bleibt bestehen. Kein vollständiges Gesichtsrig oder neues Dialogsystem.
- Initialer Tastaturfokus in Figurenwahl und Luke, lesbare Fokus-Schriftfarbe, gemeinsamer Fokusstil im Theme. Enter bestätigt die Auswahl bzw. schließt die Luke. Bestehende Maus- und Tastaturbefehle bleiben erhalten.
- Kurze native Tween-Überblendung bei Raumwechsel. Modale Fenster halten die Laufanimation an. Die Straße wird nur noch draußen gezeichnet.

## Validierung

Tatsächlich ausgeführt:

| Prüfung | Ergebnis |
| --- | --- |
| Ausgangsversion `node test-godot.mjs` | Bestanden, Vorherbilder gesichert |
| `powershell -File .\godot\build-web.ps1` | Import und Webexport bestanden |
| Godot 4.7.2 `--headless --path godot --quit-after 120` | Start und Ende ohne Skript-/Ressourcenfehler |
| `docker compose up -d --build` in spiel | Aktualisierter Export läuft auf Port 8085 |
| `node test-godot.mjs` | Kernabläufe, Navigation, Räume, Einrichtung, Save/Load bestanden |
| `node test-directions.mjs` | Dirk und Ela in vier Richtungen, Front nach Ankunft bestanden |
| `node test-driveway.mjs` | Zufahrt, Rückweg, Pflastergrenzen, stabile Diagonale bestanden |
| `node test-quality.mjs` | Defekte Felder, doppelte IDs, Wiederladen, Tastaturfokus, Drehvorschau, Spielerabstand, HTTP-503 und Speicherwiederholung bestanden |
| `git diff --check` | Keine Whitespace-Fehler |

Die erste neue Ladeprüfung wurde durch die Regression nach Save/Load korrigiert: Godot liest JSON-Zahlen als Fließkommazahlen; die ursprüngliche Array-Mitgliedschaftsprüfung war dafür zu streng. Anschließend bestanden die Tests erneut. Frühere Sandbox-Läufe meldeten fehlenden Zugriff auf Zertifikate, Godot-Einstellungen und Browserdateien. Die finalen Build- und Headless-Läufe mit regulärem Zugriff waren fehlerfrei.

Alle Browsertests verwenden simulierte API-Daten. Im Fehlerfalltest ist HTTP 503 absichtlich erzeugt; übrige Browser-/Enginefehler werden als Fehler gewertet. Es gab keine Änderung der echten gemeinsamen Saves. Persistenz mit einer realen SQLite-Datenbank wurde in diesem Durchlauf nicht erneut getestet, da Server und Speicherformat unverändert sind.

Visuell geprüft wurden Auswahl, Werkstatt, Figur vor/hinter Werkbank, beide Figuren in Seitenansichten, Außenbereich und Hochformat. Vorherbilder liegen in `spiel/output/quality-before/`, Nachherbilder in `spiel/output/godot-qa/`, `spiel/output/directions/` und `spiel/output/quality/`. Die neue Suite prüft die Position der Figur bei den Tiefensortierungsbildern zusätzlich per Assertion. Hochformat ist weiterhin nur eine verkleinerte Desktopansicht und nicht gut bedienbar.

## Erreichte Qualität und verbleibende Schwächen

Die Zahlen sind begründete Einschätzungen, keine objektiven Messwerte. Aufwand: klein bis etwa ein Arbeitstag, mittel mehrere Tage, groß eigener Produktionsabschnitt. Pro Bereich stehen die drei wichtigsten offenen Punkte mit Nutzen und Aufwand.

| Bereich | Vorher → nachher | Drei verbleibende Punkte, Nutzen / Aufwand |
| --- | --- | --- |
| Charakterdesign | 7 → 7/10 | Separate Kopf-/Armteile: mittel/mittel; mehr Gesichtsausdrücke: mittel/groß; konsistente Detailstufe zwischen Figuren und Kulissen: mittel/groß. Originalidentität hat Vorrang. |
| Animationen | 3 → 6/10 | Kein Blinzeln: mittel/mittel; kein Arm-Follow-through: mittel/mittel; kein Richtungswechsel-Blending: mittel/mittel. Ein besseres Rig braucht gesondert vorbereitete Bildteile. |
| Visuelle Konsistenz | 6 → 7/10 | Wandtext kann aus der Wandfläche ragen: mittel/klein; Schatten der Möbel fehlen: mittel/mittel; Beleuchtung ist statisch: klein/mittel. Tiefensortierung und Porträtmasken sind verbessert. |
| UI/UX | 5 → 6/10 | Hochformat zu klein: hoch/groß; mobile Dreh-/Löschaktionen fehlen: hoch/mittel; kein Einstellungsmenü: mittel/mittel. Tastaturdialoge und Vorschau sind geprüft. |
| Game Feel | 5 → 6/10 | Kein Audio: mittel/mittel; Bewegungstempo weiterhin konstant: mittel/mittel; Interaktionshinweise nicht kontextabhängig: mittel/mittel. Überblendung und Aktionsreaktionen helfen bereits. |
| Architektur | 6 → 7/10 | API und UI noch in game.gd: mittel/mittel; Möbelmaße/Zeichenregeln nicht als Resources: klein/mittel; Hit-Test und Grafik teilen noch nicht sämtliche Detailformen: mittel/mittel. Eigenständige Möbel-CanvasItems lösen einen konkreten Darstellungsfehler. |
| Performance | 6 → 6/10, vorläufig | Kein Profil auf schwachen Geräten: hoch/mittel; Welt wird oft neu gezeichnet: mittel/mittel; Polygon-Clipping der Figur pro Frame: mittel/mittel. Keine FPS-, Speicher- oder Langzeitmessung, daher kein behaupteter Leistungsgewinn. |
| Wartbarkeit | 6 → 7/10 | Feste UI-Koordinaten: hoch/groß; alte HTML- und aktive Godot-Tests nebeneinander: klein/klein; keine CI: mittel/mittel. Die neue Fehlersuite deckt zuvor ungeprüfte Zustände ab. |

## Nächste sinnvolle Schritte

Zuerst einen eigenen Hochformat-Layoutdurchlauf mit Touchbedienung umsetzen. Danach Charakterteile für Blinzeln, Arme und Gesichter vorbereiten, bevor weitere Animationszustände entstehen. Vor einer öffentlichen Veröffentlichung Assetrechte dokumentieren und auf echten Zielgeräten CPU-, Speicher- und Ladezeiten messen. Mehrbenutzerkonflikte im gemeinsamen Save bleiben eine bekannte Grenze des unveränderten Servers.

Dieser Durchlauf endet nach bestandener Regression und Bildkontrolle. Ein vollständiges Rig, adaptive Oberflächen und Gerätemessungen sind eigene größere Arbeiten; weitere spontane Umbauten würden den geprüften Umfang erweitern.
