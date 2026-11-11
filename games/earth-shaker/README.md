# Earth Shaker (Your Sinclair, 1990)

State: docs written, in review.

| | |
| --- | --- |
| Machine | 48K |
| Profile (AGENTS.md 4.0) | puzzle, a boulder-and-gems mine game for one player: 32 caves ("32 DEADLY DIAMOND MINES" in the scroller text at `$6D42`), each 30 x 20 cells stored nibble-packed (300 bytes) plus 14 parameter bytes, 314 bytes a cave at `$C000 + (N-1) * $13A` (`$C000-$E73F`), unpacked into `$FDA8-$FFFF` when the cave starts (`$82B6-$82E5`); rendering: a scrolling window of 16 x 11 cells of 16 x 16 pixels over the cave, a panel line at the bottom (cave, gems needed, time, lives, score), the whole cave on one screen on F (the map, with its tune); no frame sync: the cave engine runs in passes as long as their work, the mean pass of a cave 5.5 frames (cave 20) to 9.4 (cave 13) in the RZX play ([doc 4.6](docs/04-game-loop.md#46-the-cost-of-a-pass-in-every-cave)); the scan: once a pass ScanCells `$8075` walks the grid bottom-up, right to left, so each object falls or rolls at most one cell a pass and a falling column opens one-cell gaps behind the vacated marks `$20` ([doc 10.2](docs/10-gameplay-logic.md#102-the-scan-and-why-its-order-matters)); only fire and falling objects kill (PlayerKilled `$7FFD` is set by Crush and WalkIntoFire alone; falling earth never kills; time out and H lose a life without it); the scroller's features (anti-gravity, 4D teleport, forcefields, bubbles, elixirs, jumping jelly beans) are special cells with four dispatchers, one a direction; a potion taken returns through the ROM: PotionScore leaves BC = `$0038` on the stack, so its RET runs the ROM's IM 1 routine, whose RET goes back to TakePotion `$91DA` ([doc 10.8](docs/10-gameplay-logic.md#108-the-special-cells)); a time bar of 1024 passes and a gem count per cave, lives (5, up to 9 with potions), a score, a password per cave (the cave's own 20-character name, the table at `$9700`; FindPassword `$8E91` compares 50 records, 18 of them past the names over code and data); the 1990 version over the 1988 one: CALL + NOP patches in the old routines (the patch chain AbortKey -> AnimateCellCodes -> SwitchClear -> AntiGravPass -> ScanCells), the old code and an unused test cave left in the image ([doc 2.8](docs/02-architecture.md#28-the-leftovers-and-the-1990-patches)); sound: the beeper only, the game's own two-voice player PlayTune `$88CE` (interrupts off) for 13 tunes (title, eight cave tunes one per four caves, map, life, game over, win), the effects through the ROM's BEEPER `$03B5` or their own loops ([doc 9](docs/09-sound.md)); controls: keyboard (redefinable; O P Q A M by default) or Kempston; IM 1 throughout; no packer, no turbo loader |
| Authors | Michael Batty: "CODING, ARTWORK AND MUSIC (C) 1990 MICHAEL BATTY" (the scroller text) and "(C) 1990 MICHAEL BATTY" on the menu |
| Release | ZXDB 1563: Earth Shaker, Your Sinclair, 1990, given away on the Your Sinclair issue 63 covertape ("Six Pack"; TOSEC dates the tape 1991: issue 63 of a monthly whose issue 1 is January 1986 is March 1991). The Earth Shaker Editor tape (ZXDB 14659, Sai Ming Wong, Your Sinclair 67) says the game came with issue 63 |
| Original | `orig/YSIssue63-SixPack.tzx.zip` (md5 `3eff40aa97d8fe13ee70437d7cc650b6`, SHA-1 `9bc75b056ccdd84d4cc722e8706cf332cebf894e`; ZXDB `pub/sinclair/magazines/YourSinclair/Issue63/Tape/`), the covertape: `Your Sinclair (Issue 63) - Side 1.tzx` (md5 `3c78324f30bef4a2c9e8b43330a0962d`, SHA-1 `b54d812bd56631454fab4eaac54bdffce950f20a`, 111 971 bytes; archive info "TZXed by Andrew Barker") and `Side 2.tzx` (md5 `8a0c5d0915b6395c798fe44487ec53b2`, SHA-1 `4a15ca5de095ab36675d2a407235adbad7d75a4a`). Earth Shaker is the fourth program of Side 1: TZX blocks 10-13, a BASIC loader "EARTH" (107 bytes) and one CODE block "EARTH" of 37 566 bytes at `$6D42-$FFFF`, both at ROM speed ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

## Other releases and copies

Every copy of the local collection (`software/zxdb` with the ZXDB magazine tape, `software/zxart.ee-offline`, the
TOSEC 2020 packs, the Knobchez 2026 TOSEC pack, the TOSEC MDR pack, Pardubak; `software/games` and `zxart.ee-delta`
hold none) was copied unchanged into `work/candidates/<source>/` and compared block by block and file by file with
the original's two data blocks by `tools/media_compare.py` (`work/stage1/media-compare.tsv`,
[WALKTHROUGH 0](WALKTHROUGH.md#0-the-medium)). Not copied: zxaaa's nested hobeta archive and the TOSEC 2012 `$B`
and SCL zips.

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| TOSEC covertape `Side A.tzx` (md5 `e6037669...`), `Side A[a].tzx` (= the original Side 1), `Side A[a2].tzx` (md5 `aeda530a...`), `Side A[m tzxtools].tap` (md5 `5b2d6239...`) | other dumps of the same covertape side | Earth Shaker's BASIC and game block byte for byte |
| TOSEC `Earth Shaker (1990)(Your Sinclair).tzx` (md5 `aa981f81...`), `[a].tzx`, `[a].tap` (md5 `6060cf20...`, = zxchip's issue 63 TAP) | Earth Shaker's blocks cut out of the covertape | the BASIC and the game block byte for byte |
| ZXDB `EarthShaker.tap.zip`: `EARTHSHA.TAP` (md5 `c8fb828b...`; = WoS, TOSEC `.tap`, zxart `(EN).tap`) | a re-save | the game block byte for byte; the BASIC is "Earth1", 113 bytes, LINE 10, `LOAD "Earth2" CODE`; the CODE header is named "Earth2", param2 146 |
| TOSEC `[different loading screen].tzx` (md5 `8b7e6f6c...`) | a re-release with a loading screen | a BASIC "EARTH S." of 132 bytes and a 6912-byte SCREEN at 24320 added; the game block byte for byte |
| zxart `(EN)[h].tap` | a hack | the game block's length, 23 bytes changed (`$86DE`, `$AB4D-$AB62`) |
| TOSEC `[a].z80`, `[a2].z80` | snapshots | the game block's bytes in `$6D42-$FFFF` |
| ZXDB `EarthShaker(different).z80.zip`: `EARTHOLD.Z80` (= TOSEC `(different).z80`) | a snapshot of another version | 315 bytes differ, all in `$9B9C-$9CB7` and `$9DB8-$9DFB` |
| Pardubak `(Magazine Your Sinclair - BrokImSoft)(48k).tap` | a re-save | a loading screen, the game as a 40 000-byte block at 24500 (36 530 bytes of the game in one run) and a 1036-byte block at 64500 |
| TR-DOS files (TOSEC 2020, Knobchez, zxart: Kicia, Sukin, Pokes, Kis/Senator, Klav, Artem Oparin and others), Russian translations and hacks | conversions | packed or relocated: runs of at most 28 927 bytes of the game block (Klav), most under 3 000 |
| TOSEC MDR files (Lady Eklipse and two more) | Microdrive conversions | no 256-byte run of the game block |
| Earth Shaker Editor TRDs (WAR Group 2001) | the editor's disks | a 41 216-byte file holding the game block whole |
| ZXDB `earthshaker.zip` (archive.org rzxarchive) | 32 RZX recordings `earth01.rzx`-`earth32.rzx` (Spectaculator 0.75.6, April 2011), one a cave | someone else's play, each from a snapshot at the cave's start whose key tests the game's own redefine menu set to the Kempston port (`$1F`); used, said so, for the cave completions ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)) |
| ZXDB `EarthShaker.ay.zip` | an AY rip of the beeper tunes | not a program of the tape |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

| Documents | Figures (PNG) | Animations (GIF) | WAVs | Lines of the documents |
| ---: | ---: | ---: | ---: | ---: |
| 12 | 126 | 25 | 31 | 10 834 |

Counted by `ls docs/[01][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l;
find docs/audio -name '*.wav' | wc -l; cat docs/[01][0-9]-*.md | wc -l`.

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/YSIssue63-SixPack.tzx and compares it with orig/ byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
