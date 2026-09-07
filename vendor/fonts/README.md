# Schriften für die PDF-Ausgabe

Chrome rendert Kopf- und Fußzeilen eines PDFs als eigene, isolierte Dokumente:
sie laden weder externe Stylesheets noch Schriften, und ein per `@font-face`
eingebettetes Font erreicht sie ebenfalls nicht. Grover liefert das HTML
obendrein per Request-Interception aus (`grover/js/processor.cjs`), sodass eine
Schrift zur Renderzeit am Netz hängen würde.

Deshalb liegen die beiden Schriften hier und werden im Image nach
`/usr/local/share/fonts` kopiert (siehe `Dockerfile`). Als Systemschriften
gelten sie für Fließtext, Überschriften *und* die laufende Kopfzeile — ohne
Netz, auf jedem Host gleich.

| Datei | Verwendung | Lizenz |
|-------|------------|--------|
| `NotoSans.ttf` | Fließtext (`pdf.scss`) | OFL 1.1, `OFL-NotoSans.txt` |
| `Orbitron.ttf` | Überschriften und die Marken-Zeile im Seitenkopf | OFL 1.1, `OFL-Orbitron.txt` |

Beides sind Variable Fonts; die Gewichte kommen aus derselben Datei.

## Lokale Vorschau

Damit eine lokal erzeugte Vorschau dasselbe zeigt wie die Produktion, müssen die
Schriften auch auf dem Entwicklungsrechner installiert sein:

```sh
cp vendor/fonts/*.ttf ~/Library/Fonts/     # macOS
cp vendor/fonts/*.ttf ~/.local/share/fonts/ && fc-cache -f   # Linux
```

Ohne das greift die Ersatzkette des Systems, und die Vorschau weicht ab — genau
der Zustand, der vorher überall herrschte.
