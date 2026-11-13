# 3. Build and load

What this covers: the medium block by block, loaders, packers and their formats, the unpack animations, the source build. The recordings it rests on: `c1` (power-on, the 10 Mega Games copy of the tape at ROM timing, [WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings)).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

`orig/Deflektor.tzx.zip` holds `Deflektor.tzx`, three blocks (`tools/tzxblocks.py`, times at 3.5 MHz):

| Block | TZX kind | Bytes | Flag | What it is | Time | Pause after |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | `$10` standard | 19 | `$00` | Program header "DEFLEKTOR", length 384, LINE 0, variables at 52 | 5.09 s | 989 ms |
| 1 | `$10` standard | 386 | `$FF` | the BASIC (384 bytes): `RANDOMIZE USR (PEEK 23635+256*PEEK 23636+58)`, and the loader's code after the line, run at `$5D05` | 4.12 s | 986 ms |
| 2 | `$11` turbo: pilot 2127 T x 4836, sync 693 / 693, zero 836, one 1670, 3 bits used in the last byte | 58 316 | `$19` | the game in the loader's own pulse code | 296.74 s | 0 |

Total 307.9 s, 15 396 frames. The turbo block's pulses are those of the ROM; what differs is how the loader reads
them (below), so the block's bytes are not the bytes it puts in memory.

The stages, each with its first instruction in `c1` (`$RS stages`, the frame and T-state of the jump):

| Stage | Entry | `c1` frame, T | What it does | Witness |
| --- | --- | --- | --- | --- |
| 0 | `$5D05` | 771 | the BASIC's machine code: moves `$134` bytes to `$B626` (LDIR), jumps to `$B65B` | `c1` stages; `work/stage1/blocks/code5d05.bin` |
| 1 | `$B65B` | 771, 61 700 | clears the screen, copies three character rows of the ROM font from `$3D00`, DI, finds the pilot and sync (`$B693`), loads the first `$010F` bytes to `$B75A` (`$B727`); a failed edge or checksum jumps to `$0000` | `c1` stages; `work/stage1/blocks/ldr_b626.bin` |
| 2 | `$B856` | 1006, 38 026 | the second loader just loaded (`$B75A-$B868`): prints the loading text and a countdown while it loads the rest; a per-byte hook at `$B752` falls into code the load has just written | `c1` stages, writes `$B75A-$B868` |
| 3 | `$5B00` | 15 635, 27 704 | `LDIR; RET` (`$ED $B0 $C9`), the loader's last step; its return goes to `$5C00` (what it moves: stage 2) | `c1` stages; `work/stage1/images/loaded.cpu.bin` at `$5B00` |
| 4 | `$5C00` | 15 640, 44 028 | the loaded block's head (`$5C00-$9DEF` written by `$B737`): DI, writes `POP HL; JP (HL)` at `$5B00` and calls it to learn where it runs, then moves `$81C9` bytes up to end at `$FD1A` (LDDR at `$5C21`) and returns to `$7B52` | `c1` stages, writes `$7B52-$FD1A` by `$5C21` |
| 5-7 | `$7B52`, `$7BC0`, `$7C8C` | 15 651 onward | a key from a generator and a sum over memory from `$4000`, an XOR pass over the moved code (known only from the code at `$5C27-$5C68` before the move; proved in stage 2) | `c1` stages |
| 8 | `$FD00` | before 15 752 | `LDIR` `$7D00-$FCFF` to `$6000-$DFFF`, `LD ($5C09),BC` (0), `LD SP,$FFFF`, bit 7 of R cleared, `JP $8382` | `work/stage1/images/entry.cpu.bin` at `$FD00-$FD1A` |
| 9 | `$8382` | 15 752, 33 930 | the game's entry: the menu | `c1` stages; the `c1g` game window starts here |

`orig/Deflektor.tzx` does not load in unreal-ng: block 2 ends with 3 used bits and no pause, the tape ends on the
last pulse and the loader's final edge never comes; the load times out at IX = `$9DF0`, about frame 15 640, and the
loader jumps to `$0000`. The TOSEC standard-timing dump and the 10 Mega Games tape (the same three blocks byte for byte,
16 561 ms pause after block 2) both load; `c1` uses the 10 Mega Games copy ([WALKTHROUGH 0](../WALKTHROUGH.md#0-the-medium)).
