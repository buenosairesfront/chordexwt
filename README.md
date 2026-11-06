**English** · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex WT

A wavetable chord instrument for [monome norns](https://monome.org/docs/norns/).
One key plays a four-note chord plus bass (the lowest key held sets the root)
through a wavetable engine: 8 banks of 8 waves that the voice travels through
live.

![Chordex WT, six banks](docs/sheet.png)

**The screen is the table**, drawn with the same formula that makes the sound:

- **center:** the wavetable in 3D, from front (position 0) to back
  (position 1). The bright wave is the one sounding right now: it moves through
  the table with E1, the sweep and the scan, already shaped by the filter, warp
  and drive. The ghost is fatness, sparks are shimmer and crackle, and each
  arpeggio note runs along the wave like a comet. On the side, the position
  rail (tick = E1, dot = where the sound is).
- **left:** the chord on a 12-note wheel, the envelope and the 9 faders.
- **right:** oscilloscope (one cycle), spectrum with the filter curve on top,
  and below, the arpeggio pattern.

## Features

- **8 wavetable banks**: CRISTAL (crystal), VOCAL, DIGITAL, ORGANO (organ),
  SYNC, METAL, BITS, RESO
- **sweep** (each note starts shifted in the table and travels back), **scan**
  (an LFO on position), filter and **warp** (wavefolder)
- **10 chords**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **arpeggiator**: up, down, up-down, up x2, down x2, random and *arpa*
  (harp); gate at maximum = real legato
- **chord mode** on/off (off = single notes) and **hold**
- follows incoming MIDI clock for the arpeggio tempo
- all settings are saved automatically

<!-- u-ma:family -->
## The Chordex family

Same controls, different engines. Try the others:

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80)**<br>'80s polysynth with an outrun sunset<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm)**<br>4-operator FM, drawn as a flower<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg)**<br>orchestral strings with real bowed-string motion<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexchip"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip)**<br>chiptune: 8 console chips × 8 presets, drawn as a tracker<br>`;install https://github.com/buenosairesfront/chordexchip` |

**More from U-MA:** every instrument and tool in one place → [U-MA showcase](https://github.com/buenosairesfront/U-ma)
<!-- /u-ma:family -->

## Requirements

- norns (shield, standard or fates)
- a MIDI keyboard or controller

## Install

From maiden:

```
;install https://github.com/buenosairesfront/chordexwt
```

Then **restart norns** (SYSTEM > RESTART) so the new engine `ChordexWT` is
compiled, and load **chordexwt** from SELECT.

## Controls

| control | action |
|---|---|
| E1 | position in the table |
| E2 | select fader |
| E3 | adjust fader |
| K3 + E1 | bank |
| K3 + E2 | warp (wavefolder) |
| K3 + E3 | chord type |
| K3 held (without turning) | chord mode on/off |
| K2 (tap) | arpeggiator on/off |
| K2 + E1 | arpeggio gate (max = legato) |
| K2 + E2 | arpeggio pattern |
| K2 + E3 | arpeggio speed |
| K1 held | hold on/off (small dot, top right) |

**Faders:** attack, decay, sweep, scan, filter, distortion, wobble, fatness,
shimmer.

**PARAMETERS menu:** MIDI channel (0 = all, the default), MIDI clock divider,
hall, volume, and everything above.

## Gallery

| | |
|---|---|
| ![CRISTAL](docs/1_cristal.png) CRISTAL · maj7 | ![VOCAL](docs/2_vocal.png) VOCAL · min7 |
| ![DIGITAL](docs/3_digital.png) DIGITAL | ![SYNC](docs/4_sync_warp.png) SYNC · warp |
| ![METAL](docs/5_metal.png) METAL | ![BITS](docs/6_bits_arp.png) BITS · arpeggio |

## Credits

Made by [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Released under the MIT license.
