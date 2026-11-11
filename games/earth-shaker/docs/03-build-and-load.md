# 3. Build and load

What this covers: the medium block by block, loaders, packers and their formats, the unpack animations, the source build. The recordings it rests on: `c1` (power-on, the covertape side wound to the game, loaded at ROM speed, the fast LD-BYTES trap and turbo off; [WALKTHROUGH 1](../WALKTHROUGH.md#1-one-recording-from-power-on)).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - an animation of every unpack (`kit/memanim.py`) -->
<!-- - the build (mermaid) -->

## 3.1 The tape block by block

The original is a magazine covertape: Side 1 of the Your Sinclair issue 63 tape holds Biggles, Timewarp, two
headerless blocks, Earth Shaker and the Switchblade demo, one after another (`orig/YSIssue63-SixPack.tzx.zip`,
`Your Sinclair (Issue 63) - Side 1.tzx`). Earth Shaker is TZX blocks 9-13: a text block and four standard
ROM-speed blocks (`python3 tools/image.py --blocks`, `tools/tzxblocks.py`). A user winds the tape to the game and
types `LOAD ""`; unreal-ng's tape catalogue numbers the same BASIC header as block 7 (it lists the data blocks
only), the block `c1` is wound to with `/tape/seek` ([WALKTHROUGH 0](../WALKTHROUGH.md#0-the-medium)).

| TZX block | Kind | Bytes (with flag and parity) | Contents | Loads to | Time (pilot to last bit) | Pause after |
| --- | --- | --- | --- | --- | --- | --- |
| 9 | text (ID `$30`) | 28 | "Earth Shaker - Michael Batty" | | | |
| 10 | header, flag `$00` | 19 | Program "EARTH", length 107, LINE 1 | | 5.09 s | 1036 ms |
| 11 | data, flag `$FF` | 109 | the BASIC loader, one line (10) | PROG `$5CCB-$5D35` | 2.55 s | 4644 ms |
| 12 | header, flag `$00` | 19 | Bytes "EARTH", length 37 566, start 27 970 (`$6D42`), param2 32 768 | | 5.09 s | 1033 ms |
| 13 | data, flag `$FF` | 37 568 | the whole game | `$6D42-$FFFF` | 204.09 s | 10 570 ms |

The four blocks take 216.8 s of signal, 234.1 s with their pauses; the times are counted from the blocks' own
timings (pilot 2168 T, 8063 pulses for a header and 3223 for data, bits of 855 and 1710 T, 3.5 MHz).

The BASIC loader, as the ROM's LOAD leaves it at `$5CCB` (`work/mkgame/original.bin`):

```basic
10 INK 7: PAPER 0: BORDER 0: CLEAR 27000: PRINT AT 0,0;"EARTH SHAKER by M.BATTY": LOAD "" CODE : RANDOMIZE USR 35616
```

`CLEAR 27000` puts RAMTOP at `$6978`, below the game block, so the machine stack sits under the game (SP `$6955`
in play: `rzx-earth01` at its end). `LOAD "" CODE` takes the next block to the address its header names, `$6D42`;
`RANDOMIZE USR 35616` enters it at `$8B20`, the menu. There is no loading screen, no second-stage loader, no packer
and no turbo: the game is in memory as the ROM loads it, and `tools/image.py` builds that image
(`work/mkgame/original.bin`, `case.json`) from the two data blocks.
