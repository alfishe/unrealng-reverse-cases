# H.A.T.E. — how the reverse was done

A log of the work, in order: what was asked, which unreal-ng capability answered it, and what a snapshot
disassembler (SkoolKit, IDA, Ghidra on a memory dump) would have needed instead. Each step ends with what it
produced in this folder.

## 0. The medium

`orig/HATE.TAP` (md5 `e1c3c9060a7040d0f6ee573b3a6f48d3`), from Vortex's freeware archive:

| Block | Header | Length | Load address |
| --- | --- | --- | --- |
| 0, 1 | BASIC `H_A_T_E`, autostart line 10 | 413 | |
| 2, 3 | CODE `H_A_T_E.1` | 6432 | `$9C40` |
| 4, 5 | CODE `H_A_T_E.2` | 35495 | `$5FB4` |

All six checksums are good. The target of the source build is this file, byte for byte: all three blocks, packed
data included.

The release is not Vortex's own master: line 0 holds the text "Disked by INXS SOFT'89" and a banner routine. INXS
made a disk version and this tape back from it; [3. Build and load](docs/03-build-and-load.md) documents both
layers.

## 1. One recording from power-on

**Asked:** what runs, from the first instruction of the BASIC loader to play, in what order.

**Used:** TTD recording with the load included (`re_session.py capture --record-load`). The machine starts from a
power-on state with zeroed RAM (saved as `power-on.szx`); the recording starts before `LOAD ""` is typed, so the
loader, the banner, the screen unpacker, the depacker and the game are all in it. The session is saved once
(`time_travel dump`, 26 MB: every frame's checkpoint, the port journal of 12 M reads and 2.4 M writes, the write
journal) and loaded into a new instance for every later question (`re_session.py open --ttd`). A replay is exact,
so every later counter, window build or memory read sees the same run.

**Instead, without it:** a snapshot of the loaded game. The loader, the banner and the depacker would be gone, and
every question about timing would need a new play session that never repeats the last one.

**Produced:** `work/c2/hate.ttd` (45 260 frames), `work/c2/` (the first L1 build: 292 routines, 0 of 1811
checkpoints diverged).

Note: the emulator's fast tape loading (the ROM's LD-BYTES trap, on by default) loaded the blocks in a few frames
each; the load takes 2 540 frames instead of about 12 000. The game does not depend on it (all three blocks go
through the ROM's LD-BYTES); the real-speed tape is documented from the block lengths and the ROM timing.

## 2. Static pass over the tape

**Asked:** what each block is before running anything.

**Used:** a block splitter (checksums), the BASIC listing, z80dasm over the REM code and the start of each CODE
block, the ROM itself (`data/rom/48.rom`) to check every ROM address the loaders jump to.

Findings, each checked later on the recording (step 3):

- Line 10 is the whole loader: `PAPER 0: BORDER 0: POKE 23624,0: INK 0: CLEAR 24499: RANDOMIZE USR 23788:
  LOAD "H_A_T_E.1" CODE: CLS: RANDOMIZE USR 40000: POKE 23739,111: LOAD "H_A_T_E.2" CODE: RANDOMIZE USR 24500`.
  Line 20 is `REM NO POKE`; line 30, `RANDOMIZE USR 25000`, starts the game: BASIC falls through to it when the
  depacker returns.
- USR 23788 is INXS's banner in line 0's REM: a bold font made from the ROM's ($3D00, `b | b >> 1`, at $C350),
  "H.A.T.E." (line 1's REM) printed eight times at row 10 with INK 0 to 7, three frames apart (a fade in), then
  "Disked by INXS SOFT'89" sliding in from the right on row 12.
- `POKE 23739,111` points the S channel's output at $096F: a lone `RET` in the ROM (checked). The ROM's
  "Bytes: H_A_T_E.2" message is printed nowhere and the loading screen stays clean.
- `H_A_T_E.1` (USR 40000) is position independent: `CALL $007C` (a lone `RET` in the ROM) leaves its own address
  below SP. It unpacks a screen: RLE `00 N V`, the bitmap by pixel lines, then the attributes.
- `H_A_T_E.2` (USR 24500) moves its 55-byte depacker into the printer buffer ($5B8C), moves the packed data
  down $64 bytes with the ROM's `LDIR; RET` at $33C3 (checked) and unpacks backwards into $5FB4-$FFFF: RLE with
  the marker $97.

**Produced:** `work/tape/NOTES.md`, `work/tape/*.bin` (the blocks).

## 3. The packers, proved against the recording

**Asked:** do the static readings hold, and can the packed blocks be made again from their contents?

**Used:** TTD `memory_at` (the 64 K view at any frame and T-state of the recording, without running the machine)
and a binary search over frames.

- `tools/depack.py` (the depacker in Python) gives the memory $5FB4-$FFFF of frame 2613 exactly: 0 of 41 036 bytes
  differ. The search found 2613 as the first frame after the depacker's last write; at 2614 the game already
  writes its stack and variables.
- `tools/pack.py` packs that image back into the 35 395 bytes of the tape, identical. The rules came from the
  tokens of the tape's stream: runs from three bytes on; zeros 256 at a time while 256 remain, then up to 127;
  other bytes up to 127; a lone $97 escaped.
- `tools/screen_depack.py` gives the screen of frame 2531 exactly (0 of 6 912 bytes differ); at frame 2530 the
  unpacker is still on attribute row 21. `tools/screen_pack.py` packs it back into the tape's 5 965 bytes, identical
  (runs from four bytes on, zeros always a run).

**Instead, without it:** dumping memory at the right moment means stopping the game there with a breakpoint and
saving a snapshot, once per question; frame 2613 would have been a guess.

**Produced:** the four tools; `docs/img/load-1-inxs-banner.png`, `docs/img/load-2-loading-screen.png` (frames 2380
and 2531 rendered by `tools/zxscreen.py`).

## 4. The tape from source

**Asked:** can the tape be made again from sources, before the game itself is reversed?

**Used:** sjasmplus, the packers of step 3, a tape writer; `cmp` against `orig/HATE.TAP`.

- `src/loader.asm`: the BASIC program as tokens and the banner as code. The first build was two bytes short: the
  original has a space after each `LOAD` token, as it was typed. Identical since.
- `src/screen.asm`: assembling the unpacker found three misreadings of step 2, all in the parameter handling and
  the run state (the `INC HL` after each picture parameter is unconditional; `RES` of the run flag is skipped when no
  run is on; the picture's length counts two bytes past its data). `tools/screen_depack.py` was corrected with it.
  Identical since.
- `src/depacker.asm`: identical at once.
- `tools/tap.py`: the CODE headers hold $2020 as their second parameter, not the ROM's 32 768: the tape was made
  by a copier.

**Produced:** `tools/build.sh`: `build/HATE.TAP` identical to `orig/HATE.TAP`, all 42 415 bytes. The game image in
it is still unpacked from the original; replacing it with `src/game` is the rest of the work.

## 5. Tool gaps found and fixed in unreal-ng

The first L1 build over the whole recording showed three faults in the analysis. They were fixed in unreal-ng (with
fixtures and tests, branch `analysis-stages`) before going on:

| Gap | Seen as | Fix |
| --- | --- | --- |
| One build over a program that arrives in stages mixes the stages: the depacker's buffer and the game's code at the same address | the loader's bytes classified with the game's | **code arrivals**: the first run of bytes written during the recording, one per writer routine (where, when, who wrote it); **window builds** from any frame / T-state to any frame, with their own start image (`build --stage N`) |
| Every loaded byte that ran was marked self-modifying code | thousands of SMC marks on the game | SMC now means written after it ran |
| An overlay (code overwritten by a later stage) gave one finding per opcode | 174 near-duplicate findings | one finding per overwritten run (gap 32) |
| A host trap that runs as one instruction lost its writes: L1 kept 64 bus cycles per instruction, the fast tape load writes a whole block at the ROM loader's entry | the second build listed 31 arrivals: the loaded bytes had no load as their writer (the ROM's RAM test was the last one), so every return from the ROM into the banner was a new arrival, each "written $4000-$FFFF" | the events past 64 go to a buffer that grows once (up to 128 K); an arrival's run is the bytes its own writer wrote; one arrival per writer and run (`TrapWritesPastTheEventBuffer`, the fixture's stage 2 now calls back into the loader) |
| The L1 JSON held per-byte kinds only, no counts | no memory heatmap could be drawn from a build | `byte_counts`: reads, writes, first and last frame per byte, dense per page; `tools/heatmap.py` renders them |

New fixture `testdata/analysis/fixtures/stages.asm` (a loader, a depacker with two writers, an overlay); tests
`CodeArrivalsOnePerWriter`, `WindowFromAnArrival`, `OverlayIsOneFinding`; the recipe
`.recipe/analysis/reverse-engineering.md` got "Programs that arrive in stages".

## 6. The game stage (in progress)

### 6.1 The game window build

`re_session.py build --from-frame 2613 --from-tinframe 53257 --into work/game` builds L1 over the game alone, from
the moment the depacker returns: 42 647 frames, 357 575 330 instructions, replayed against 1 706 checkpoints with no
divergence. Its start image (`start.bin`) equals `tools/depack.py`'s output byte for byte. The build took 186 s.

**Why unreal-ng:** a window build is a replay of the TTD recording from any T-state. The analysis sees exactly the
game, with the loader's bytes out of the way. A trace-based tool would need the run again, and a static disassembler
has no run at all.

### 6.2 The interrupt handler, found automatically

`re_session.py interrupts --work work/game` lists the routines L1 saw entered by an interrupt, follows the jump
chain and costs it:

```text
interrupt $FDFD -> $8340: 27645 entries in 42647 frames (0.65 a frame), 123 T an entry, 0.1 % of the CPU
```

No address had to be known. The command was added to unreal-ng for this case (the recipe "Interrupt handlers" in
`.recipe/analysis/reverse-engineering.md`). It also shows what the address alone would not: all entries fall in
frames 2616-30260, the title, so the game itself runs with interrupts off.

### 6.3 The architecture

From the call graph (`calls`, `routines.profile`), the executed byte ranges (`instructions`) and the code around the
entry points: [docs/02-architecture.md](docs/02-architecture.md). Findings:

- the title music player is relocatable;
- its IM 2 handler doubles as the key exit and unwinds the stack to SP as saved at entry;
- the game loop has no frame lock;
- 2 319 passes of $CF33 averaged 6.2 frames each.
- Every role the document gives a routine is marked with the document that will confirm it.

### 6.4 Pictures from the recording

- `tools/memanim.py`: a GIF of memory over a stretch of the recording. It samples TTD `memory_at` (exact at any
  T-state) every N T-states and flashes the bytes written since the previous sample. First result:
  [the loading screen unpacking](docs/img/anim-loading-screen.gif), 77 pictures.
- `tools/heatmap.py`: per-byte read, write and execute heatmaps from L1's new `byte_counts` (5 in the gap table).
  Waiting for the build with the fix.
- `tools/check_docs.py`: every mermaid diagram in the docs is rendered with `mmdc`, and every link is checked. A
  diagram that GitHub's mermaid rejects fails here first.

The recording is open in an instance built from that branch; the whole-recording build lists the arrivals, then
each stage is built from its own arrival.
