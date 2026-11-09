# Video Pool (Oxford Computer Publishing, 1985)

State: complete (2026-11-09), after two review rounds: the tape's data blocks rebuilt byte for byte from the annotated
source, 39 editable resources in `src/res` (and the six rack maps in `src/res/maps`), docs 01-12 and 14 (13 documents, 77 mermaid diagrams, 52 figures, 56
screenshots, 22 GIFs: 17 routine animations and 5 screen captures, 8 sound files), counted by:

```bash
ls docs/[0-9][0-9]-*.md | wc -l; cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs/img -name '*.png' -not -path 'docs/img/play/*' | wc -l; find docs/img/play -name '*.png' | wc -l
find docs/img -name '*.gif' | wc -l; find docs -name '*.wav' | wc -l
```

| | |
| --- | --- |
| Machine | 48K |
| Profile (AGENTS.md 4.0) | sports and physics simulation: pool on a 48K with the beeper, no main loop (a 25-slot scheduler in the IM 2 interrupt, the foreground only plays the ball, cushion and pocket tones; doc 4); the balls drawn with XOR from 8 pre-shifted copies of each, no mask, over a table of XOR lines (doc 6); the physics in 8.8 fixed point with a friction table, self-patching jaws and a table-driven ball-ball exchange, matched byte for byte by a Python model over 475 sampled video frames of `w1` from the break on (1086-1560, the break and the still balls after it; doc 10.6); each shot set up through the ROM's calculator (AimShot about 455 000 T, 85 % of it the ROM's SQR; the interrupt holding it 6.92 video frames, six interrupts lost, seven in 11 of `w1`'s 21 set-ups; doc 4); no computer player and no randomness but the R register (docs 7, 10); three rule variations, two players, a table editor, a hall of fame, hidden infinite-lives keys (doc 10.10); a turbo loader with a 16-bit sum, no cipher, no packer (doc 3); the port to the UKNC planned in [doc 14](docs/14-porting-to-uknc.md) ([TODO.md](../../TODO.md)) |
| Authors | James Hutchby (the menu: "ocp 1984, written by j.hutchby"; ZXDB 5566 dates the release 1985) |
| Release | ZXDB 5566. `orig/VideoPool.tzx.zip` is the original release (the TZX's archive info: "Original", "TZXed by Andrew Barker For Tony Barnett"): a BASIC loader, a 256-byte turbo loader at `$F000` and the game, 25 000 bytes at `$8000`, in a turbo block |
| Original | `orig/VideoPool.tzx.zip` (md5 `90b667ceb1cc91c7b6d798b3d5d6cf79`, SHA-1 `849f27bd3f53af04656738d839470cf4a1d59b34`): `Video Pool.tzx` (md5 `01b54459c0217da4df7c2b21529f9931`, SHA-1 `43213180b893b96a5ee103db027c8b9985325130`) |
| The re-release | `orig/VideoPool(PaxmanPromotions).tzx.zip` (md5 `19e98c0b368a8b2d5dc85848b201fbc2`, SHA-1 `736729f8cc2e40a3a4d6c23c982209fa0ee86898`): `Video Pool (Paxman).tzx` (md5 `6041ddb5de60a2bfc518f28992b89883`, SHA-1 `68c941e7c03abf46cc69c10d26e732e1a1131621`), Paxman Promotions 1998: the same three data blocks byte for byte as the original, other pauses |
| A conversion | `orig/VideoPool.tap.zip` (md5 `446a1ab1c299a3b94f8a6220441b8d28`, SHA-1 `8e21693e31677944cd5abe7ae489a89588f4f59d`): `VIDPOOL.TAP` (md5 `655b920561f94d9edb211360fd7cf907`, SHA-1 `3672394a38ff51a6cd9b2f47876831adfbd3c8ca`), "Modify by JANSOFT 1985": a ROM-speed tape whose 25 000 bytes at `$8000` were saved from a game that had run (207 bytes differ from the original, all in variables, tables and the key names); and `SCRSHOT/VIDPOOL.SCR` (md5 `82514da9d3d5ab47645d65cf679e949d`, SHA-1 `e7ee881a1f3458d13636c66ec6005ccc64e280e3`). Not the case's source |
| Instructions | `orig/VideoPool.txt` (md5 `6fbc65eda969adaff93c8eea947b43f7`, SHA-1 `06e981eb54ec0225fb6878184c39e9ae67f3d5e4`) |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/Video Pool.tzx and compares it with the TZX in orig/VideoPool.tzx.zip byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
