# 2. Architecture

What this covers: the machine budget, the memory map (a figure), stages from the medium to play, the frame, the main
loop's call graph, the module map. The recordings it rests on: c1 (power-on, side 1 at signal speed), and the
recordings started from the title after that load: menu, controls, missions, play, play2, death, search, m2ocean, m2erbe, m10
([WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings)).

<!-- Figures this document needs (GUIDE.md 4.2), remove each line when it is in: -->
<!-- - the stages from power-on to play (mermaid) -->

## 2.1 The memory map

The game uses the 128K banks as follows. The classes come from the L1 builds of the eight recordings after the load
(`work/stage1/bankmap.py` over their `l1.json`, 128-byte rows: "code" = an instruction executed in the row, "written",
"read" = data only, "-" = untouched); the names from the code and the dumps cited in each row. A bank's addresses are
those of the slot it is paged into (bank 5 at `$4000`, bank 2 at `$8000`, the others at `$C000` through `$7FFD`).

![The eight banks as heatmaps over the stage 1 recordings](img/arch/heatmap-banks.png)

*Drawn by `tools/fig_heatmap128.py` from the L1 builds of menu, play, play2, death, m2erbe, m2ocean, search and m10:
red written, green read, blue executed, per physical page.*

### Bank 5 (`$4000-$7FFF`, always paged)

| Range | Class | What it is | Witness |
| --- | --- | --- | --- |
| `$4000-$5AFF` | written | the screen | |
| `$5B00-$5BFF` | - | the 128K ROM's paging routine of the load (stage 0), unused in play | c1 stages |
| `$5C00-$63FF` | read | data, read only (what it holds is stage 2's) | bankmap |
| `$6780-$7FFF` | code, written | game code (entry `$68F4`, the paging routine `$7270-$7287` (entries `$7270` bank 4, `$7274` bank 7, `$7278` bank 6, `$727C` bank 0: `LD (n),A / LD BC,$7FFD / OR 0 / OUT (C),A`), the interrupt's callees `$72D2`, `$7D80`, `$7DFB`, `$7E6E`) and variables `$7600-$7C7F` (a table of 24 records of 60 bytes at `$75F0`, walked by the loop at `$C030` with `IX` step 60; the pointer X word `$7C51` and Y `$7C53`) | L1 patterns of c1; `tools/bcbot.py` |
| `$7C49` | | the interrupt handler's own stack top (`LD SP,$7C49` at `$8389`) | handler listing, [WALKTHROUGH 1](../WALKTHROUGH.md#1-interrupts-and-timing) |

### Bank 2 (`$8000-$BFFF`, always paged)

| Range | Class | What it is | Witness |
| --- | --- | --- | --- |
| `$8000-$8044` | - | the bootstrap the loader leaves (pages bank 1, copies `$C301-$FFFF` to `$8301`, jumps to `$68F4`), dead after the entry | [doc 3](03-build-and-load.md#the-stages) |
| `$8181-$8183` | | `JP $8383`, set at the entry | entry code `$68F4` |
| `$81B9-$81FF` | written | the main stack: `SP` = `$81FF` at the entry; the lowest byte written is `$81B9` in menu, `$81C5` in play, and down to `$8199` in c1 around the mission load (`$8199-$81B8` differ between frames 31954 and 32999): 22 bytes above the `JP` at `$8181` | L1 writes of page 2; `work/stage1/diffimg.py f31954 f32999` |
| `$8200-$8300` | read | the IM 2 vector table: 257 bytes of `$83` (`LDIR` at `$6903`), `I` = `$82`: every vector is `$8383` | entry code |
| `$8368-$837F` | written | the weapon slots: slot 1's ammunition at `$836D` (79 at death frame 7939, 69 at 9939, 59 at 11939, 49 at 13939; `$B550 LD HL,$836D / LD A,(HL) / DEC A`) | death, [WALKTHROUGH 6.3](../WALKTHROUGH.md#63-the-state-variables-and-the-pokes) |
| `$8383-$8442` | code | the interrupt handler | [WALKTHROUGH 1](../WALKTHROUGH.md#1-interrupts-and-timing) |
| `$8AF1-$96F0` | written | the 3D view's back buffer, 3072 bytes, cleared by `$96F1` (96 x 16 `PUSH HL` of zero with `SP` = `$96F1`) once a 3D frame | `$96F1` listing |
| `$9680-$BFFF` | code | the 3D engine and the game logic (the heaviest routines of play: `$A82C`, `$A6D2`, `$A687`, `$A745` by instructions) | playx L1 window 8400-9400 |

### Bank 0 (`$C000`, paged in play)

| Range | Class | What it is | Witness |
| --- | --- | --- | --- |
| `$C000-$DAFF` | code | play code: `$C026` walks the `$75F0` table; `$D7E4` / `$D7EB` write a port with `OUT (C),A` 10 907 times in c1 (the AY candidates) | c1 L1 |
| `$DBC5-$FB3E` | written, code | the mission block from side 2 (8058 bytes for Blast Em Mission), code in it at `$E381` (stage 31) | c1 dumps 28827 / 31954 |
| `$FC00-$FF7F` | written | four 128-byte rows at `$FC00`, `$FD00`, `$FE00`, `$FF00`, the same rows written in banks 3 and 6 | bankmap |

### Banks 1, 3, 4, 6, 7

| Bank | Classes | What it is | Witness |
| --- | --- | --- | --- |
| 1 | untouched after the load | the staging copy of `$8301-$BFFF` (tape block 27) | [doc 3](03-build-and-load.md#the-stages), the heatmap |
| 3 | code `$C000-$D27F`, read `$CB00-$CF7F`, written `$DC80-$FB7F` | code (paging `OUT` at `$C16F`), a mission-sized work area: `$DCBC-$FB3E` changes when the mission loads | c1 dumps 28827 / 31954 |
| 4 | code `$C000-$C77F`, read `$C780-$CAFF`, written `$CB00-$E77F` | menu code; the catalogue `$CB64-$E737` (7124 bytes from side 2: titles, briefings, maps) | c1 dumps 24508 / 28827 |
| 6 | code and data through `$C000-$F97F`, read `$E600-$F87F` | the stores screen and menus (the POKE file's bank-6 cheats `$C1B9`, `$C1C6`, `$C1AE` are here: the payload checks); paged in play too | play, play2 |
| 7 | read `$C000-$FE7F`, code `$FE80-$FFFF` | 14 K read-only data: the 3D models and graphics are the lead (stage 2), code at `$FE95` (stage 26) | heatmap |

## 2.2 The stages from power-on to play

| Stage | Where it runs | What it does | c1 frames |
| --- | --- | --- | --- |
| 128K ROM, Tape Loader | ROM 0, ROM 1 | loads the BASIC "BATTLE" | 0-2028 |
| BASIC machine code, decryption chain | `$5D06`, `$AC38-$BF0C` | 20 layers, then the SpeedLock loader | 2028-2484 |
| SpeedLock loader | `$BF0D` and the chain | the screen, then the banks 5, 0, 1, 3, 4, 6, 7 | 2484-23974 |
| bootstrap | `$8000` | bank 1 to `$8301-$BFFF` | 23974 |
| game | `$68F4` | IM 2, the title (frame 24508), the menus | 23974- |
| mission tape | game code | the catalogue (bank 4), one mission block (bank 0) a SELECT | 24777-31954 |

Details: [doc 3](03-build-and-load.md#31-the-tape-block-by-block).
