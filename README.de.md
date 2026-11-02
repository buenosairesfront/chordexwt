[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · **Deutsch** · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex WT

Ein Wavetable-Akkordinstrument für [monome norns](https://monome.org/docs/norns/).
Eine Taste spielt einen vierstimmigen Akkord plus Bass (die tiefste gehaltene
Taste bestimmt den Grundton) über eine Wavetable-Engine: 8 Bänke mit je 8
Wellen, durch die die Stimme live wandert.

![Chordex WT, sechs Bänke](docs/sheet.png)

**Das Display ist die Tabelle**, gezeichnet mit derselben Formel, die den Klang
erzeugt:

- **Mitte:** die Wavetable in 3D, von vorne (Position 0) nach hinten
  (Position 1). Die helle Welle ist die, die gerade klingt: Sie bewegt sich mit
  E1, dem Sweep und dem Scan durch die Tabelle und ist bereits von Filter,
  Warp und Drive geformt. Der Geist ist Fatness, Funken sind Shimmer und
  Knistern, und jeder Arpeggio-Ton läuft wie ein Komet über die Welle. Seitlich
  die Positionsschiene (Strich = E1, Punkt = aktuelle Position).
- **links:** der Akkord auf einem 12-Ton-Rad, die Hüllkurve und die 9 Fader.
- **rechts:** Oszilloskop (eine Periode), Spektrum mit der Filterkurve darüber
  und darunter das Arpeggio-Muster.

## Funktionen

- **8 Wavetable-Bänke**: CRISTAL (Kristall), VOCAL, DIGITAL, ORGANO (Orgel),
  SYNC, METAL, BITS, RESO
- **Sweep** (jeder Ton startet versetzt in der Tabelle und wandert zurück),
  **Scan** (LFO auf die Position), Filter und **Warp** (Wavefolder)
- **10 Akkorde**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **Arpeggiator**: up, down, up-down, up x2, down x2, random und *arpa*
  (Harfe); Gate auf Maximum = echtes Legato
- **Akkordmodus** an/aus (aus = Einzeltöne) und **Halten**
- Knistern einer alten Schallplatte, wenn mehr als zwei Tasten gehalten werden
- folgt eingehender MIDI-Clock für das Arpeggio-Tempo
- alle Einstellungen werden automatisch gespeichert

<!-- u-ma:family -->
## Die Chordex-Familie

Gleiche Bedienung, andere Engines. Probier die anderen aus:

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.de.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.de.md)**<br>80er-Polysynth mit Outrun-Sonnenuntergang<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.de.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.de.md)**<br>FM mit 4 Operatoren, als Blume gezeichnet<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.de.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.de.md)**<br>Orchesterstreicher mit echter Bewegung einer gestrichenen Saite<br>`;install https://github.com/buenosairesfront/chordexstg` |

**Mehr von U-MA:** alle Instrumente und Werkzeuge an einem Ort → [U-MA-Übersicht](https://github.com/buenosairesfront/U-ma/blob/main/README.de.md)
<!-- /u-ma:family -->

## Voraussetzungen

- norns (shield, Standard oder fates)
- ein MIDI-Keyboard oder -Controller

## Installation

In maiden:

```
;install https://github.com/buenosairesfront/chordexwt
```

Danach **norns neu starten** (SYSTEM > RESTART), damit die neue Engine
`ChordexWT` kompiliert wird, und **chordexwt** über SELECT laden.

## Bedienung

| Bedienelement | Funktion |
|---|---|
| E1 | Position in der Tabelle |
| E2 | Fader wählen |
| E3 | Fader einstellen |
| K3 + E1 | Bank |
| K3 + E2 | Warp (Wavefolder) |
| K3 + E3 | Akkordtyp |
| K3 halten (ohne zu drehen) | Akkordmodus an/aus |
| K2 (antippen) | Arpeggiator an/aus |
| K2 + E1 | Arpeggio-Gate (Maximum = Legato) |
| K2 + E2 | Arpeggio-Muster |
| K2 + E3 | Arpeggio-Geschwindigkeit |
| K1 halten | Halten an/aus (kleiner Punkt oben rechts) |

**Fader:** Attack, Decay, Sweep, Scan, Filter, Verzerrung, Wobble, Fatness,
Shimmer.

**Menü PARAMETERS:** MIDI-Kanal (0 = alle, Standard), MIDI-Clock-Teiler,
Hall, Lautstärke und alles oben Genannte.

## Galerie

| | |
|---|---|
| ![CRISTAL](docs/1_cristal.png) CRISTAL · maj7 | ![VOCAL](docs/2_vocal.png) VOCAL · min7 |
| ![DIGITAL](docs/3_digital.png) DIGITAL | ![SYNC](docs/4_sync_warp.png) SYNC · Warp |
| ![METAL](docs/5_metal.png) METAL | ![BITS](docs/6_bits_arp.png) BITS · Arpeggio |

## Credits

Erstellt von [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
MIT-Lizenz.
