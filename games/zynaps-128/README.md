# Zynaps 2 in 1 (goodboy and tiboh, 2018)

State: in progress (stage 1: the medium, the load, the images).

A TR-DOS release of Hewson's Zynaps (1987, Dominic Robinson; graphics Steve Crow): the 48K game with AY music and
effects taken from the Amstrad CPC version (music by Dave Rogers), an infinite-lives option, a Kempston mouse
option and timing changed for the Pentagon. "2 in 1": the loader's paging test picks the 128K path (AY music and
effects) or a 48K one (the original's beeper); the 48K branch is in the code and is not run here. The case covers the
128K version, which loads and plays on every unreal-ng model with TR-DOS and 128 K or more.

| | |
| --- | --- |
| Machine | 128K with TR-DOS (Pentagon 128 is the target) |
| Authors | goodboy, tiboh (2018); the game: Dominic Robinson, Steve Crow, Hewson Consultants 1987; music Dave Rogers (CPC) |
| ZXDB | 42055 |
| Original | `orig/Zynaps(2In1)(km).scl.zip` (md5 `ae426a3e580c096db8c8fc9ff5d545a0`, SHA-1 `19418754d64fdb71e1bed298bd8a0f4269b7319a`) |
| | `orig/Zynaps(2In1)(km).trd.zip` (md5 `978800f74bb41b7dedb57b6a47655f5a`, SHA-1 `e9ae3d7f1c790c048b71e5698b9d01830b5a22b6`) |
| Inside | `Zynaps(2In1)(km).scl` (35099 bytes, md5 `ff9a3a7b670039e9972b24011b77ba29`, SHA-1 `528aff7278e60c80308476d0149fbd6c94043893`) |
| | `Zynaps(2In1)(km).trd` (655360 bytes, md5 `ed6455389ec8600cb1ecc3247001e88f`, SHA-1 `330dd0f61108218984cf52955c3b4b900a0fea61`) |

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).
