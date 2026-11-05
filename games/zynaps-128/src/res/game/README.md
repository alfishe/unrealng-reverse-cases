# The 48K game

`game-6800.bin`: the 48K Zynaps as block 2 carries it, `$6800`-`$FFFF` (38 912 bytes), before the set-up's patches.
It is the Hewson tape's main block with 151 bytes changed in 11 runs (the default keys, the Pentagon delay counts, two
cleared tails: docs/03-build-and-load.md 3.6). A binary resource for now: when `../zynaps/src/game/game.ann` (the 48K
case's) is complete it becomes this case's `src/game/game.ann`, the 11 changes annotated.
