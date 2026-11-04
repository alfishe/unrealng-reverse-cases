# Advanced Nether Earth (Eternity Industry, 1998)

State: stage 1 (2026-11-04): the media, the load, the memory map, and the game matched against
[Nether Earth](../nether-earth/README.md) routine by routine. Source and resources come in the next stages.

| | |
| --- | --- |
| Machine | Pentagon 128 with TR-DOS |
| Authors | Eternity Industry, 1998 (the 2017 disk is signed by Kalantaj Konstantin, Krivoy Rog); not in ZXDB |
| The game | `orig/Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl` (TOSEC 2023-09; md5 81a6278d05f539d25d64dd3c5a5c9337, SHA-1 5e12a67de4582f8f42fa3c0e07d7c160b6bb98f5) |
| "Final Cut" disk | `orig/anefc.zip` (md5 f4317f485fdc3267ca576a1413003441, SHA-1 bfe700feaa2cfc1ec278d5bea69cb87e4d2e78ec), holding `orig/ANE_FC.TRD` (md5 87478117f81e142f0190764e6f3d4b82, SHA-1 caa100b86ae2770ce13cc3fa9a7d0f0fee1c4360) |

A Russian 128K edition of Nether Earth. The results so far:

- **The game logic is Nether Earth's, byte for byte, at Nether Earth's addresses**: robots, shots, damage, capture,
  production, the enemy commander, the tables, and every known bug of NE's 10.12 except the menu tune's (the tune is
  gone) ([10](docs/10-gameplay-logic.md)).
- **What is new is around the game**: the IM 2 table moved to `$6800` so `$C000` can be paged, AY music (Pro Tracker)
  in play, a disk save, Russian texts with a Cyrillic font, an intro, a boot menu, a help program, and two endings,
  "Dead End" on a loss and "Final Cut" on a win ([2](docs/02-architecture.md), [3](docs/03-build-and-load.md)).
- **The authors' claims against the code**: "some bugs fixed" does not show in the game code; several numbers of
  the help (part costs, "up to 50 robots") disagree with it ([12](docs/12-claims.md), [10.4](docs/10-gameplay-logic.md#4-the-claims-against-the-code)).
- **The 2017 "Final Cut" disk is the win sequence alone**, repacked with Hrust 1: no game on it
  ([3.1](docs/03-build-and-load.md#1-the-final-cut-disk-2017-basic-hrust-1-the-final-cut-alone)).

How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).
