# Leftovers

Bytes the tape holds and no code reads, kept as they are (plain bytes, no editable form).

| File | Address | Size | What |
| --- | --- | --- | --- |
| `rex1-devlink.bin` | REX 1 `$6018-$60DF` (DevLinkStub, Unused607E) | 200 | 102 bytes of the authors' development link and 98 bytes after it; the menu copies ExplosionPicture `$E336` over `$6018-$60D7` before anything runs |
| `rex2-devlink.bin` | REX 2 `$61A8-$6305` (DevLink, DevLinkState, Unused62FE) | 350 | the development link's code (pages the link in, saves every register, sends 26 bytes, calls DebugHook `$D6C6`), its state, 8 zeros |
| `demo-devlink.bin` | DEMO `$61A8-$6337` (DevLink, DevLinkState, Unused62FE) | 400 | REX 2's link but one word (`$62BE` = `$DB4B`, DEMO's DevLinkReturn), its state, 58 zeros |
| `demo-workspace.bin` | DEMO `$DB4D-$FFF9` (WorkSpace) | 9389 | zeros the game uses as its work space (room grid, attribute shadow, back buffer), one byte `$DCBA` set, the machine stack's residue `$FF25-$FF57` and the ROM's default UDGs A-U at `$FF58` |

The code's own leftovers (routines no instruction reaches: REX 1's UnusedRandom `$A368`, ThreeReturns `$C5FA`,
EnemyShotFromX `$B586`; DEMO's PointsLeftover `$8E2B`, SprayLeftover `$C589` and the rest) stay in the `.asm`, each
entry saying so, as does REX 2's map slots 26-34 (rooms/README.md).
