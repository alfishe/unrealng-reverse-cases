# Moon Patrol (Atarisoft (UK), 1984)

State: in progress.

| | |
| --- | --- |
| Machine | 48K |
| Authors | not named on the tape; a licensed port of the Irem / Williams arcade game (1982). ZXDB 3266: "Never released - recovered" |
| Original | `orig/MoonPatrol.tap.zip` (md5 `073fb9b14c2e684564384487b0b10892`, SHA-1 `1abc7b0f4448d287402d9baaf4ece5b9507ea89e`): `Moon Patrol.tap` (md5 `bff93417838c032a96c2fadbc456c658`, SHA-1 `e71a908fc4deded7ac3b66991aa191b756b488e1`); `orig/MoonPatrol.tzx.zip` (md5 `316686974206c9c0aa93f38f6de3992e`, SHA-1 `ea246ef46166a4d13907029f1d154c71925f00fb`): `Moon Patrol.tzx` (md5 `01736dd451f728e32dcc10cb7ce8c377`, SHA-1 `da611c68bca84d370ffd2f39a1ba828fe797851e`), the same four standard blocks; both from ZXDB |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```bash
tools/build.sh [SJASMPLUS]     # builds build/Moon Patrol.tap and compares it with the TAP in orig/MoonPatrol.tap.zip byte for byte
```

The game source is `src/game/*.asm`, written by `kit/mkgame.py` from `src/game/game.ann`; the resources are
`src/res/` (`src/res/README.md`).
