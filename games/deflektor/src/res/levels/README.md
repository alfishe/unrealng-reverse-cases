# levels

levels.txt: LevelData `$B000`, 64 slots of 135 bytes (9 rows of 15 cells), read by BuildLevel `$891A` at `$B000 +
$87 x level`, copied into the grid `$FD23` (17 bytes a row). Slots 0-59 are levels 1-60, slots 60-62 (`$3C-$3E`) the
practice levels P1-P3 (only P1 recorded, `practice`); slot 63 is never set up: LevelCompletePause goes back to the
title when Level reaches 63 (`$887D`).

A `slot N` line starts a slot (the words after N are a comment), then 9 lines of 15 tokens:

| Token | Code | Element |
| --- | --- | --- |
| `...` | `$00` | empty |
| `Mnn` | `$01-$10` | mirror, angle nn (`M00` is `$10`): the player turns it, Right + 1, Left - 1 with fire held |
| `PCn` | `$11-$18` | cyan polariser, angle n: passes a beam along its axis, absorbs it across |
| `PYn` | `$19-$20` | yellow polariser: passes along, reflects across |
| `WAm` | `$21-$2F` | absorbing wall; m (hex) the quarters filled: 1 top left, 2 top right, 4 bottom left, 8 bottom right |
| `WRm` | `$30-$3E` | reflecting wall, same quarters |
| `CEL` | `$40` | a cell: burns when the beam reaches it |
| `MIN` | `$41` | a mine: the beam on it overloads the laser |
| `PRS` | `$42` | prism: the beam leaves in a random direction |
| `L-d` | `$47-$4A` | the laser facing d (E S W N) |
| `R-d` | `$4B-$4E` | the receiver, open to d |
| `Fna` / `Fnb` | `$50-$57` | fibre-optic pair n (0-3): a beam into one end leaves the other |
| lower case | bit 7 | the element turns by itself, one step a pass of RenderGrid `$8960` |
| `$HH` | any other | kept as the byte |

Each level holds one laser and one receiver. tools/level_maps.py draws every slot from this file with the game's own
builder and renderer.
