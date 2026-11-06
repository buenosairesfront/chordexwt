[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · [日本語](README.ja.md) · **中文** · [हिन्दी](README.hi.md)

# Chordex WT

为 [monome norns](https://monome.org/docs/norns/) 设计的波表和弦乐器。按一个键会奏出一个四音和弦加低音（按住的最低键决定根音），由波表引擎发声：8 个音色库，每个库 8 个波形，声部会实时在其中移动。

![Chordex WT 的六个音色库](docs/sheet.png)

**屏幕就是波表**，用与发声相同的公式绘制：

- **中央：** 3D 波表，从前（位置 0）到后（位置 1）。最亮的波形就是正在发声的波形：它随 E1、扫描（sweep）和 scan 在波表中移动，显示的是经过滤波器、warp 和 drive 之后的形状。虚影代表 fatness，火花代表 shimmer 和噼啪声，每个琶音音符都会像彗星一样沿波形奔跑。侧边是位置导轨（刻度 = E1，点 = 当前位置）。
- **左侧：** 12 音轮上的和弦、包络和 9 个推子。
- **右侧：** 示波器（一个周期）、叠加滤波器曲线的频谱，下方是琶音型。

## 功能

- **8 个波表音色库**：CRISTAL（水晶）、VOCAL（人声）、DIGITAL（数字）、ORGANO（风琴）、SYNC、METAL（金属）、BITS、RESO
- **扫描**（每个音从波表中偏移的位置开始并移回）、**scan**（作用于位置的 LFO）、滤波器和 **warp**（波形折叠）
- **10 种和弦**：maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **琶音器**：up, down, up-down, up x2, down x2, random 和 *arpa*（竖琴）；门限调到最大即为真正的连奏
- **和弦模式** 开/关（关 = 单音）以及**保持**
- 琶音速度跟随外部 MIDI 时钟
- 所有设置自动保存

<!-- u-ma:family -->
## Chordex 系列

操作相同，引擎不同。也来试试其他几款：

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.zh.md)**<br>80 年代复音合成器，配 outrun 日落画面<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.zh.md)**<br>4 算子 FM，画成一朵花<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.zh.md)**<br>管弦乐弦乐，呈现真实的拉弦运动<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexchip/blob/main/README.zh.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip/blob/main/README.zh.md)**<br>芯片音乐：8 种游戏机芯片 × 8 个预设，画成 tracker<br>`;install https://github.com/buenosairesfront/chordexchip` |

**更多 U-MA 作品：** 所有乐器和工具汇集一处 → [U-MA 作品集](https://github.com/buenosairesfront/U-ma/blob/main/README.zh.md)
<!-- /u-ma:family -->

## 需求

- norns（shield、标准版或 fates）
- MIDI 键盘或控制器

## 安装

在 maiden 中输入：

```
;install https://github.com/buenosairesfront/chordexwt
```

然后**重启 norns**（SYSTEM > RESTART）以编译新引擎 `ChordexWT`，再从 SELECT 加载 **chordexwt**。

## 操作

| 操作 | 功能 |
|---|---|
| E1 | 波表中的位置 |
| E2 | 选择推子 |
| E3 | 调节推子 |
| K3 + E1 | 音色库 |
| K3 + E2 | warp（波形折叠） |
| K3 + E3 | 和弦类型 |
| 按住 K3（不转动旋钮） | 和弦模式 开/关 |
| K2（轻按） | 琶音器 开/关 |
| K2 + E1 | 琶音门限（最大 = 连奏） |
| K2 + E2 | 琶音型 |
| K2 + E3 | 琶音速度 |
| 按住 K1 | 保持 开/关（右上角的小点） |

**推子：** 起音、衰减、扫描、scan、滤波器、失真、wobble、fatness、shimmer。

**PARAMETERS 菜单：** MIDI 通道（0 = 全部，默认）、MIDI 时钟分频、大厅混响、音量，以及以上所有参数。

## 图库

| | |
|---|---|
| ![CRISTAL](docs/1_cristal.png) CRISTAL · maj7 | ![VOCAL](docs/2_vocal.png) VOCAL · min7 |
| ![DIGITAL](docs/3_digital.png) DIGITAL | ![SYNC](docs/4_sync_warp.png) SYNC · warp |
| ![METAL](docs/5_metal.png) METAL | ![BITS](docs/6_bits_arp.png) BITS · 琶音 |

## 致谢

由 [Buenos Aires Front](https://github.com/buenosairesfront) / U-MA 制作。
MIT 许可证。
