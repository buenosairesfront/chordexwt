[English](README.md) · [Español](README.es.md) · **Français** · [Deutsch](README.de.md) · [日本語](README.ja.md) · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex WT

Un instrument d'accords à tables d'ondes pour
[monome norns](https://monome.org/docs/norns/). Une touche joue un accord de
quatre notes plus la basse (la touche la plus grave enfoncée donne la
fondamentale) à travers un moteur wavetable : 8 banques de 8 ondes que la voix
parcourt en direct.

![Chordex WT, six banques](docs/sheet.png)

**L'écran est la table**, dessinée avec la même formule que celle qui produit
le son :

- **au centre :** la table d'ondes en 3D, de l'avant (position 0) vers
  l'arrière (position 1). L'onde lumineuse est celle qui sonne : elle se
  déplace dans la table avec E1, le balayage et le scan, déjà façonnée par le
  filtre, le warp et le drive. Le fantôme est le fatness, les étincelles sont
  le shimmer et le craquement, et chaque note d'arpège parcourt l'onde comme
  une comète. Sur le côté, le rail de position (repère = E1, point = position
  actuelle).
- **à gauche :** l'accord sur une roue de 12 notes, l'enveloppe et les 9
  faders.
- **à droite :** oscilloscope (un cycle), spectre avec la courbe du filtre
  par-dessus et, en dessous, le motif de l'arpège.

## Fonctions

- **8 banques d'ondes** : CRISTAL, VOCAL, DIGITAL, ORGANO (orgue), SYNC,
  METAL, BITS, RESO
- **balayage** (chaque note démarre décalée dans la table et revient),
  **scan** (LFO sur la position), filtre et **warp** (wavefolder)
- **10 accords** : maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **arpégiateur** : up, down, up-down, up x2, down x2, random et *arpa*
  (harpe) ; gate au maximum = vrai legato
- **mode accord** on/off (off = notes seules) et **maintien**
- suit l'horloge MIDI entrante pour le tempo de l'arpège
- tous les réglages sont sauvegardés automatiquement

<!-- u-ma:family -->
## La famille Chordex

Mêmes contrôles, moteurs différents. Essayez les autres :

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.fr.md)**<br>polysynthé des années 80 avec un coucher de soleil outrun<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.fr.md)**<br>FM à 4 opérateurs, dessinée comme une fleur<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.fr.md)**<br>cordes d'orchestre avec le vrai mouvement d'une corde frottée<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexchip/blob/main/README.fr.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip/blob/main/README.fr.md)**<br>chiptune : 8 puces de console × 8 presets, dessiné comme un tracker<br>`;install https://github.com/buenosairesfront/chordexchip` |

**Plus de U-MA :** tous les instruments et outils au même endroit → [vitrine U-MA](https://github.com/buenosairesfront/U-ma/blob/main/README.fr.md)
<!-- /u-ma:family -->

## Prérequis

- norns (shield, standard ou fates)
- un clavier ou contrôleur MIDI

## Installation

Depuis maiden :

```
;install https://github.com/buenosairesfront/chordexwt
```

Ensuite **redémarrez norns** (SYSTEM > RESTART) pour compiler le nouveau
moteur `ChordexWT`, puis chargez **chordexwt** depuis SELECT.

## Contrôles

| contrôle | action |
|---|---|
| E1 | position dans la table |
| E2 | choisir un fader |
| E3 | régler le fader |
| K3 + E1 | banque |
| K3 + E2 | warp (wavefolder) |
| K3 + E3 | type d'accord |
| K3 maintenu (sans tourner) | mode accord on/off |
| K2 (appui bref) | arpégiateur on/off |
| K2 + E1 | gate de l'arpège (max = legato) |
| K2 + E2 | motif de l'arpège |
| K2 + E3 | vitesse de l'arpège |
| K1 maintenu | maintien on/off (petit point en haut à droite) |

**Faders :** attaque, decay, balayage, scan, filtre, distorsion, wobble,
fatness, shimmer.

**Menu PARAMETERS :** canal MIDI (0 = tous, par défaut), diviseur d'horloge
MIDI, hall, volume, et tout ce qui précède.

## Galerie

| | |
|---|---|
| ![CRISTAL](docs/1_cristal.png) CRISTAL · maj7 | ![VOCAL](docs/2_vocal.png) VOCAL · min7 |
| ![DIGITAL](docs/3_digital.png) DIGITAL | ![SYNC](docs/4_sync_warp.png) SYNC · warp |
| ![METAL](docs/5_metal.png) METAL | ![BITS](docs/6_bits_arp.png) BITS · arpège |

## Crédits

Créé par [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA.
Licence MIT.
