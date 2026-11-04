[English](README.md) · [Español](README.es.md) · [Français](README.fr.md) · [Deutsch](README.de.md) · **日本語** · [中文](README.zh.md) · [हिन्दी](README.hi.md)

# Chordex WT

[monome norns](https://monome.org/docs/norns/) 用のウェーブテーブル・コード楽器。
1 つのキーで 4 音のコード＋ベースを鳴らし（押さえている一番低いキーがルート）、8 波形 × 8 バンクのウェーブテーブルをボイスがリアルタイムで移動するエンジンで演奏します。

![Chordex WT の 6 つのバンク](docs/sheet.png)

**画面そのものがテーブルです。** 音を作っているのと同じ式で描かれています：

- **中央：** 3D のウェーブテーブル。手前（位置 0）から奥（位置 1）へ並びます。明るい波形がいま鳴っている波形で、E1、スイープ、スキャンに合わせてテーブル内を移動し、フィルター、ワープ、ドライブを通った後の形で表示されます。ゴーストはファットネス、火花はシマーとクラックル、アルペジオの各音は彗星のように波形の上を走ります。横には位置のレール（目盛り = E1、点 = 現在の位置）。
- **左：** 12 音の輪の上のコード、エンベロープ、9 本のフェーダー。
- **右：** オシロスコープ（1 周期）、フィルターカーブを重ねたスペクトラム、その下にアルペジオのパターン。

## 機能

- **8 つのウェーブテーブル・バンク**：CRISTAL（クリスタル）、VOCAL、DIGITAL、ORGANO（オルガン）、SYNC、METAL、BITS、RESO
- **スイープ**（各音がテーブル内でずれた位置から始まり戻ってくる）、**スキャン**（位置の LFO）、フィルター、**ワープ**（ウェーブフォルダー）
- **10 種類のコード**：maj, min, dim, aug, 7, maj7, min7, m7b5, sus2, sus4
- **アルペジエーター**：up, down, up-down, up x2, down x2, random, *arpa*（ハープ）。ゲート最大で本物のレガート
- **コードモード** オン/オフ（オフ = 単音）と**ホールド**
- 3 つ以上のキーを押すと古いレコードのクラックルノイズ
- アルペジオのテンポは受信した MIDI クロックに追従
- すべての設定は自動保存

<!-- u-ma:family -->
## Chordex ファミリー

操作は同じ、エンジンは別。ほかの楽器もどうぞ：

| | |
|---|---|
| <a href="https://github.com/buenosairesfront/chordex80/blob/main/README.ja.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordex80/main/docs/1_d50.png" width="200" alt="Chordex 80"></a> | **[Chordex 80](https://github.com/buenosairesfront/chordex80/blob/main/README.ja.md)**<br>アウトランの夕焼けを描く 80 年代ポリシンセ<br>`;install https://github.com/buenosairesfront/chordex80` |
| <a href="https://github.com/buenosairesfront/chordexfm/blob/main/README.ja.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexfm/main/docs/3_metal.png" width="200" alt="Chordex FM"></a> | **[Chordex FM](https://github.com/buenosairesfront/chordexfm/blob/main/README.ja.md)**<br>花として描かれる 4 オペレーター FM<br>`;install https://github.com/buenosairesfront/chordexfm` |
| <a href="https://github.com/buenosairesfront/chordexstg/blob/main/README.ja.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexstg/main/docs/2_tutti.png" width="200" alt="ChordexSTG"></a> | **[ChordexSTG](https://github.com/buenosairesfront/chordexstg/blob/main/README.ja.md)**<br>弓で擦った弦の実際の動きを描くオーケストラ弦楽<br>`;install https://github.com/buenosairesfront/chordexstg` |
| <a href="https://github.com/buenosairesfront/chordexchip/blob/main/README.ja.md"><img src="https://raw.githubusercontent.com/buenosairesfront/chordexchip/main/docs/1_nes.png" width="200" alt="Chordex CHIP"></a> | **[Chordex CHIP](https://github.com/buenosairesfront/chordexchip/blob/main/README.ja.md)**<br>チップチューン：ゲーム機チップ 8 種 × 8 プリセット、トラッカーとして描画<br>`;install https://github.com/buenosairesfront/chordexchip` |

**U-MA のほかの作品：** すべての楽器とツールをひとつに → [U-MA ショーケース](https://github.com/buenosairesfront/U-ma/blob/main/README.ja.md)
<!-- /u-ma:family -->

## 必要なもの

- norns（shield、標準モデル、fates）
- MIDI キーボードまたはコントローラー

## インストール

maiden から：

```
;install https://github.com/buenosairesfront/chordexwt
```

その後、新しいエンジン `ChordexWT` をコンパイルするために **norns を再起動**（SYSTEM > RESTART）し、SELECT から **chordexwt** を読み込みます。

## 操作

| 操作 | 機能 |
|---|---|
| E1 | テーブル内の位置 |
| E2 | フェーダー選択 |
| E3 | フェーダー調整 |
| K3 + E1 | バンク |
| K3 + E2 | ワープ（ウェーブフォルダー） |
| K3 + E3 | コードの種類 |
| K3 長押し（回さずに） | コードモード オン/オフ |
| K2（タップ） | アルペジエーター オン/オフ |
| K2 + E1 | アルペジオのゲート（最大 = レガート） |
| K2 + E2 | アルペジオのパターン |
| K2 + E3 | アルペジオの速度 |
| K1 長押し | ホールド オン/オフ（右上の小さな点） |

**フェーダー：** アタック、ディケイ、スイープ、スキャン、フィルター、ディストーション、ウォブル、ファットネス、シマー。

**PARAMETERS メニュー：** MIDI チャンネル（0 = 全チャンネル、初期値）、MIDI クロック分周、ホール、音量、および上記すべて。

## ギャラリー

| | |
|---|---|
| ![CRISTAL](docs/1_cristal.png) CRISTAL · maj7 | ![VOCAL](docs/2_vocal.png) VOCAL · min7 |
| ![DIGITAL](docs/3_digital.png) DIGITAL | ![SYNC](docs/4_sync_warp.png) SYNC · ワープ |
| ![METAL](docs/5_metal.png) METAL | ![BITS](docs/6_bits_arp.png) BITS · アルペジオ |

## クレジット

制作：[Buenos Aires Front](https://github.com/buenosairesfront) / U-MA。
MIT ライセンス。
