# Video Pool (Oxford Computer Publishing, 1985)

State: in progress (phase 0 and stage 1).

| | |
| --- | --- |
| Machine | 48K |
| Profile (AGENTS.md 4.0) | sports and physics simulation (pool: ball motion and friction, collisions, cushions and pockets, the aiming cursor and the power bar, three rule variations, a table editor, a hall of fame); sprites over a static table (the balls "flicker-free": the erase strategy is for stage 2); a turbo loader with a checksum (no cipher, no packer found so far); sound and the engine's details as stages 1 and 2 find them; port target UKNC (doc 14, [TODO.md](../../TODO.md)) |
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
