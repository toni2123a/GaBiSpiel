# Priorisierte Verbesserungen

Diese Roadmap wurde vor den Quellcodeänderungen erstellt. Der Durchlauf setzt die wichtigsten sicher umsetzbaren Punkte der todo.txt um.

| Prio | Maßnahme | Nutzen / Aufwand | Abnahme |
| --- | --- | --- | --- |
| P0 | Geladene Möbel vollständig prüfen, defekte Antwort geschlossen ablehnen | Hoch / klein | Fehlerpfadtest, danach gültiges Neuladen |
| P1 | Offene Saves nach HTTP-Fehler erhalten, gezielt erneut versuchen; paralleles Laden verhindern | Hoch / klein | Simulierter 503, Wiederholen, gespeicherter Inhalt |
| P1 | Vorschau bei Drehen sofort aktualisieren; ungültige Flächen rot zeigen; Spielerplatz freihalten | Hoch / klein | Rotation ohne Mausbewegung, abgelehnte Platzierung |
| P1 | Figur und Möbel nach Bodentiefe zeichnen | Hoch / mittel | Screenshots vor/hinter Werkbank |
| P2 | Gemeinsames Theme, sichtbarer Tastaturfokus, Dialogfokus und Escape | Mittel / klein | Auswahl und Luke mit Tastatur |
| P2 | Sheet unverändert lassen; maskierte Porträts, geteilte Cutout-Beine, ruhiges Idle und Interaktionsreaktion | Mittel / mittel | Beide Figuren in allen Ansichten visuell prüfen |
| P2 | Kurze Raumüberblendung, Bewegung in modalen Fenstern anhalten, Innenraum ohne Straße | Mittel / klein | Bestehende Raum- und Bewegungstests |
| P3 | Adaptive Hochformatoberfläche, mobile Touchaktionen für Drehen/Löschen | Hoch / groß | Separater Layoutdurchlauf mit Geräteprüfung erforderlich |
| P3 | Audio, Asset-Lizenzklärung, Gerätemessungen | Mittel / mittel | Vor öffentlicher Veröffentlichung |

Keine neuen Spielsysteme, Servermigration oder neue Abhängigkeiten in diesem Durchlauf. Endbewertungen bleiben kritisch; 9/10 ist ein Ziel und keine Abnahmebehauptung. Umsetzungsstand und verbliebene Schwächen stehen im Abschlussbericht.

## Stand nach Umsetzung

P0 und P1 sind umgesetzt und getestet. Die P2-Punkte sind bis auf Escape als explizite Dialogtaste umgesetzt; die Dialoge sind über Fokus und Enter bedienbar. Die Cutout-Erweiterung umfasst Beine, Idle und Aktionsreaktionen, kein vollständiges Gesichtsrig. P3 bleibt offen. Zusätzlich wurde die übergroße Möbel-Klickfläche korrigiert. Details, tatsächliche Testergebnisse und verbleibende Schwächen stehen in QUALITY_REPORT.md.

## Verbindlicher sichtbarer Umbau nach Nutzerreview
P1: Eigenständige Papier-Cartoon-Art-Direction für alle drei Räume und Möbel. P1: Neue Oberfläche und gestaltete Figurenwahl statt Entwurfspanels. P1: Getrennte Kopf-/Torso-/Beinbewegungen, Blinzeln und Interaktionsreaktionen. P2: Native Sounds, Pause/Tonsteuerung, kontextabhängige Hinweise und größere Bedienelemente. P2: Szenische Details, mehrere Hintergrundebenen und animierte Toröffnung. Abnahme: Vorher/Nachher-Bilder aller Räume und Figuren, vollständige Kernregression sowie Tests der neuen Steuerung. Die Tests allein ersetzen die Bildkontrolle nicht.
