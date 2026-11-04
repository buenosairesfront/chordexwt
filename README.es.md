[English](README.md) · **Español** · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex WT

Instrumento de acordes wavetable para [monome norns](https://monome.org/docs/norns/).
Una tecla toca un acorde de cuatro notas más el bajo (la tecla más grave
apretada marca la raíz) a través de un motor wavetable: 8 bancos de 8 ondas
que la voz recorre en vivo.

![Chordex WT, seis bancos](docs/sheet.png)

**La pantalla es la tabla**, calculada con la misma fórmula que suena:

- **centro:** la tabla de ondas en 3D, de adelante (posición 0) hacia atrás
  (posición 1). La onda brillante es la que está sonando: se mueve por la
  tabla con E1, el barrido y el scan, y ya pasó por el filtro, el warp y el
  drive. El fantasma es el fatness, las chispas son shimmer y crackle, y cada
  nota del arpegio corre por la onda como un cometa. Al costado, el riel de
  posición (tick = E1, punto = dónde está).
- **izquierda:** el acorde en la rueda de 12 notas, la envolvente y los 9
  faders.
- **derecha:** osciloscopio (un ciclo), espectro con la curva del filtro
  encima y, abajo, el patrón del arpegio.

## Características

- **8 bancos de ondas**: CRISTAL, VOCAL, DIGITAL, ORGANO, SYNC, METAL, BITS,
  RESO
- **barrido** (la nota arranca corrida en la tabla y vuelve), **scan** (LFO
  de posición), filtro y **warp** (wavefolder)
- **10 acordes**: maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **arpegiador**: up, down, up-down, up x2, down x2, random y *arpa*; con el
  gate al máximo, legato real
- **modo acorde** on/off (off = una sola nota) y **retener**
- crackle de disco viejo con más de dos teclas apretadas
- sigue el clock MIDI entrante para el tempo del arpegio
- todo se guarda solo

<!-- u-ma:family -->
## La familia Chordex

Mismos controles, motores distintos. Probá los otros:

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.es.md)**<br>polisynth ochentoso con atardecer outrun<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.es.md)**<br>FM de 4 operadores, dibujado como una flor<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.es.md)**<br>cuerdas de orquesta con el movimiento real de una cuerda frotada<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexchip/blob/main/README.es.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip/blob/main/README.es.md)**<br>chiptune: 8 chips de consola × 8 presets, dibujado como un tracker<br>`;install https://github.com/buenosairesfront/chordexchip` |

**Más de U-MA:** todos los instrumentos y herramientas en un solo lugar → [muestrario U-MA](https://github.com/buenosairesfront/U-ma/blob/main/README.es.md)
<!-- /u-ma:family -->

## Requisitos

- norns (shield, estándar o fates)
- un teclado o controlador MIDI

## Instalación

Desde maiden:

```
;install https://github.com/buenosairesfront/chordexwt
```

Después **reiniciá la norns** (SYSTEM > RESTART) para que compile el engine
nuevo `ChordexWT`, y cargá **chordexwt** desde SELECT.

## Controles

| control | acción |
|---|---|
| E1 | posición en la tabla |
| E2 | elegir fader |
| E3 | ajustar fader |
| K3 + E1 | banco |
| K3 + E2 | warp (wavefolder) |
| K3 + E3 | tipo de acorde |
| K3 mantenido (sin girar nada) | modo acorde on/off |
| K2 (toque) | arpegiador on/off |
| K2 + E1 | gate del arpegio (al máximo, legato) |
| K2 + E2 | patrón del arpegio |
| K2 + E3 | velocidad del arpegio |
| K1 mantenido | retener on/off (puntito arriba a la derecha) |

**Faders:** ataque, decay, barrido, scan, filtro, distorsión, wobble,
fatness, shimmer.

**Menú PARAMETERS:** canal MIDI (0 = todos, por defecto), divisor del reloj
MIDI, hall, volumen y todo lo anterior.

## Galería

| | |
|---|---|
| ![CRISTAL](docs/1_cristal.png) CRISTAL · maj7 | ![VOCAL](docs/2_vocal.png) VOCAL · min7 |
| ![DIGITAL](docs/3_digital.png) DIGITAL | ![SYNC](docs/4_sync_warp.png) SYNC · warp |
| ![METAL](docs/5_metal.png) METAL | ![BITS](docs/6_bits_arp.png) BITS · arpegio |

## Créditos

Hecho por [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Licencia MIT.
