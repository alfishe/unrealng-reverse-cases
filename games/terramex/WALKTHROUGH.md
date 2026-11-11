# Terramex: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number. In this case
every load is at ROM speed (fast_tape and turbo_tape off), on the 128K.

## 0. The medium

The case starts from ZXDB 5195 (Terramex, Grandslam Entertainments, 1987; Teque Software Development). ZXDB lists
three tapes beside the original: the Quicksilva-labelled "Original Big Box Release", the Bug-Byte Premier re-release
and the Spanish Zafiro re-release. The original is `orig/Terramex.tzx.zip` from ZXDB's `pub/sinclair/games/t/`
(hashes in the [README](README.md)).

The release check (`tools/media_compare.py`, `work/stage1/media-compare.txt`): all four TZXs and the TAP hold the
same five data blocks byte for byte; the TAP's BASIC adds a wait for a key before `JP $8F00` (13 bytes), and the
Bug-Byte and Quicksilva TZXs add a TZX block `$2A` ("stop the tape if in 48K mode") before the last block. Every
other copy the collection index lists was copied unchanged into `work/candidates/<source>/` (`tools/fetch_copies.py`)
and scored by the share of the original's blocks it holds (`tools/copy_compare.py`, `work/stage1/copy-compare.tsv`):
the World of Spectrum FTP TAP, TOSEC's `(Europe).TZX`, the ULA+ TAP and zxart's Omega Ltd TAP carry the data blocks
whole; Astemex (Load 'n' Run, ZXDB's "unauthorized version", also filed by TOSEC 2005 as "Argus Press Software") is a
48K cut of two CODE blocks, and the Specman and Gryzor hacks are made from it; the TR-DOS and Microdrive copies are
packed. The table is in the README.

The tape is five standard-speed blocks: a BASIC header and line, the screen, a 38 648-byte block at `$6000` and a
36 352-byte block at `$7200` that loads over it ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)).
The BASIC hides its loader in the variables area ([doc 3, 3.2](docs/03-build-and-load.md#32-the-basic-loader-hidden-in-l)); no
packer, no turbo blocks.

Other sources: nzeemin's SkoolKit disassembly (cloned at `work/candidates/skoolkit-game-revs`, the starting point for
names, checked as we go: `work/stage1/NOTES.md`), the RZX archive's `terramex.rzx` (someone else's run to the
ending), ZXDB's instructions, maps and POKE file (`work/candidates/zxdb-*`).

## 1. One recording from power-on

`c1`: the 128K from power-on, the original TZX at ROM speed (`tools/rs_capture.py --record-load --load-frames 21900`,
port base 37500), then `tests/inputs/c1.txt` (the menu, the selector, play, abort). The stages from the L1 arrivals
are in [doc 3, 3.3](docs/03-build-and-load.md#33-the-128k-set-up-at-7200-and-the-relocation): the loader at frame 696, the
set-up and the selector's relocation into RAM 1 at 11841, GameEntry `$8F00` at frame 21597 t 67875 (`time_travel find_last`, access execute).

The interrupts and the timing, a first look:

- **IM mode and handler.** Before the game the ROM's IM 1. GameEntry `$8F00` runs `DI`, fills `$8E00-$8F00` with
  `$5F`, writes `JP $9491` at `$5F5F`, sets `SP` = `$5E00`, `I` = `$8E`, `IM 2`, `EI` (the bytes at `$8F00` in the
  image; the instructions `$8F1C`, `$8F21`, `$8F23` in `c1`'s L1). The handler `$9491` pushes AF and, when the 128K
  flag `$5FFE` is set, pages RAM 6 in (`$7FFD` = `$16`), calls the music player at `$C000`, pages back and returns
  with `EI` (SK). In `c1` it ran 5029 times, about 3793 T each, 1 % of the CPU (`$RS interrupts`).
- **DI and EI in play.** None that costs an interrupt: `explorers` (15 190 frames), `gameover` (6000) and every RZX
  segment take as many interrupts as frames (the L1's `replay.interrupts`). `c1` takes 5214 in 26 628 frames: the
  load runs with interrupts off.
- **The main loop.** `$9018` (SK "main game loop") with no HALT: the room-entry check, the player, the items, the
  countdown, the creatures, the five party slots, the frame counter `$5C02` (so `$5C02` counts passes, not frames),
  and the pause and abort keys (Q, then CAPS SHIFT + Q to abort, A held to stay paused). The menu waits with a HALT at
  `$9468`.
- **Frames per pass**, measured on our instance (`tools/passes.py`: 300 passes from one `$9018` to the next with
  `/skip_until`, timed by `/video/beam`, 70 908 T a frame, no key held; `work/stage1/passes.json`):

| State (RZX snapshot) | Room | Median T a pass | Frames (median) | Heaviest pass | Frames |
| --- | --- | ---: | ---: | ---: | ---: |
| `snap-02000` | `$08` | 170 403 | 2.40 | 190 242 (pass 18) | 2.68 |
| `snap-12000` | `$1A` | 182 464 | 2.57 | 199 956 (pass 130) | 2.82 |
| `snap-24000` | `$32` | 193 191 | 2.72 | 198 704 (pass 6) | 2.80 |
| `snap-36000` | `$1F` | 197 754 | 2.79 | 203 107 (pass 262) | 2.86 |
| `snap-46000` | `$3B` | 220 476 | 3.11 | 232 943 (pass 151) | 3.29 |

A pass is 2.4 to 3.1 frames of work; the heaviest measured is 232 943 T (3.29 frames) in room `$3B`. The RZX's own
reads of the Kempston port at `$B8CC` agree: in its 51 148 frames the gap between reads is 2 frames 4376 times and 3
frames 12 178 times (`work/stage1/rzx/inputs.json`).

## 2. Static pass over the medium

## 3. The stages and the packers

## 4. The medium from source

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |

## 6. The game

### 6.0 The recordings

| Name | Session | Start (load) | Inputs | Frames | Reached |
| --- | --- | --- | --- | ---: | --- |
| `c1` | `work/stage1/c1/session.ttd` | power-on, the original TZX at ROM speed | `tests/inputs/c1.txt` | 26 628 | the load, the device menu (1, 3, 2, 0), the selector, Herr Krusche, room `$14`, jumps, bearer keys, T, 5, abort |
| `explorers` | `work/stage1/explorers/session.ttd` | `work/stage1/probe/load-128K/end.szx`, the menu after a ROM-speed 128K load of the original | `tests/inputs/explorers.txt` | 15 190 | the five explorers (`$5B70` = 0-4 at frames 1000, 3500, 6000, 9000, 11 500, `time_travel memory_at`), the three devices (Kempston; keyboard Z X O K SPACE; Sinclair 6 7 8 9 0), Help and its pages (13 750-15 190), five aborts |
| `gameover` | `work/stage1/gameover/session.ttd` | `rzx/snap-10000.z80` with lives `$5B97` = 1 (a POKE, said so; `work/stage1/probe/go/lives1.szx`) | `tests/inputs/gameover.txt` | 6000 | the RZX player's death in room `$1C` as the last life: `$9090` at frame 1509, the space scene, `$906D` (high score) at 1962, the menu at 1963 |
| `rzx00000` ... `rzx50000` (26) | `work/stage1/rzx/rNNNNN/session.ttd` | `work/stage1/rzx/snap-NNNNN.z80`, the RZX archive's run at frame NNNNN (`tools/rzx_dump.py` in SkoolKit's simulator; someone else's play) | `tests/inputs/rzx-NNNNN.txt` (`tools/rzx_script.py`: the RZX's port reads as held keys) | 2000 each, 1147 the last | the RZX run in pieces: 57 rooms, score 2300, one life lost, the ending (`$B0B6` sets `$5BFF` at `rzx50000` frame 729, the menu at 732) |
| `rzx06500`, `rzx14500`, `rzx23250`, `rzx24750`, `rzx32750` | as above | later snapshots where a segment drifted | as above | 750-1500 | the rest of those pieces in sync |

How they were made: `$RS capture --snapshot ... --model 128K --inputs ... --ranges 4000-FFFF --port-base 37510`
(`work/stage1/rzx_capture_all.sh`, `work/stage1/capture2.sh`). The RZX pieces were checked against the RZX's own
screen every 250 frames (under 3 % of the bitmap bytes differ); five pieces drifted after 500-1250 frames, the five
later starts cover their rest. More in `work/stage1/NOTES.md`.

Drift beyond the five later starts: `rzx10000` ends off the RZX's course. At its frame 1943 a snake of room `$1A` bites
(Room1ADeath `$A88F`, frames 1943-1958) that the RZX's own state at 12 000 does not have (3 lives, status 0, the Flute
in hand), so frames 1943-1999 of `rzx10000` are ours, not the RZX player's (doc 10, 10.8). `rzx38000` starts inside
status 27 (room `$43`'s Silver Lining): the trigger `$B71E` ran before its first frame (doc 10, 10.9).

Probes of stage 2 (no `.ttd`: each runs on a clone of a recording's state, POKEs said so and never in the image,
port base 37520, screenshots kept):

| Name | Command | From | What it gave |
| --- | --- | --- | --- |
| probe A | `python3 work/stage2/probe_points.py 37520` | the RZX state at 44000 (`work/stage2/points/base.szx`), the countdown poked to 0/0/2 | the time running out: room `$28` 10 frames later, status 29, GameOver at frame 430 (`work/stage2/points/a-*.png`) |
| probe B | `python3 work/stage2/probe_points.py 37520 B` | the same state, Room = R + 1 and X = 4 with Z held; Explorer 1, 2 for `$2E`, `$2F` | the 13 rooms the RZX run skips that a room exit reaches, on screen (`work/stage2/points/b-room-*.png`) |
| probe C | `python3 work/stage2/probe_points.py 37520 C` | the same state, room `$3C` entered without the pills | the radiation death: status 23 at frame 70, 18 at 225, Lives 3 -> 2, restart in room `$3B` at 355 (`work/stage2/points/c-*.png`) |
| 48K tries | `python3 work/stage2/probe_2a.py 37520 qs\|orig`, `probe_48k_orig.py`, `probe_48k_orig2.py` | power-on of a 48K, the Quicksilva TZX (`$2A` block) or the original | the selector's 48K screens and the set copy; the tape never resumes for block 5 (`work/stage2/p48/*/end.szx`, `sheet.png`) |

The writers made no new recording. They opened the sessions above on their own port bases and kept their traces in
work folders that name the session they read: `work/docs/tmA/{c1,exp,gameover,r02000,r12000,r24000,r36000,r46000,r50000}`,
`work/docs/tmB/{explorers,gameover,r02000}`, `work/docs/tmC/{go,r06,r247,r44}` (`gameover`, `rzx06000`, `rzx24750`,
`rzx44000`) and `work/docs/tmD/{c1,ex,go}`. tmA's RZX dump `work/docs/tmA/rzx25` (`tools/rzx_dump.py`, the
variables every 25 RZX frames, no instance) gives the route of doc 1, 1.10.

Not reached by the RZX run: 15 rooms (`$01 $02 $05 $06 $11 $12 $15 $1E $21 $24 $25 $2E $2F $46 $47`); probe B put 13 of
them on screen, `$46` and `$47` (the own rooms of explorers 3 and 4) are drawn from the data only (doc 1, 1.8). Never
executed in any recording: the 48K path past the selector, the Q + A freeze, the telescope (statuses 30-31), Think
(statuses 10-12), the cheat, the deaths 9, 15, 16 and 17, the beam hit, the cursor-key readers, tunes 1-3 (doc 1,
1.11; doc 10, 10.14).

### 6.1 Screens and rooms

Every screen reached, from our recordings at the frames named:

| Screen | Picture | Recording, frame |
| --- | --- | --- |
| the loading screen | [loading-screen.png](docs/img/play/loading-screen.png) | the tape's block 3 (the image `$4000-$5AFF`) |
| the device menu | [menu.png](docs/img/play/menu.png) | `explorers` 7750 |
| the explorer selector | [selector.png](docs/img/play/selector.png) | `explorers` 250 |
| Help: the title, the controls, the story | [help-1.png](docs/img/play/help-1.png), [help-2.png](docs/img/play/help-2.png), [help-3.png](docs/img/play/help-3.png) | `explorers` 13 750, 14 000, 15 000 |
| play, the start room `$14` | [start-room-14.png](docs/img/play/start-room-14.png) | `explorers` 750 |
| the last life lost: the space scene | [gameover-1509.png](docs/img/play/gameover-1509.png), [gameover-1700.png](docs/img/play/gameover-1700.png) | `gameover` 1509, 1700 |
| room `$3B` before the end | [ending-lab-r48000-1999.png](docs/img/play/ending-lab-r48000-1999.png) | `rzx48000` 1999 |
| the ending in room `$28` | [ending-room-28-r50000-500.png](docs/img/play/ending-room-28-r50000-500.png) | `rzx50000` 500 |
| the 57 rooms of the RZX run | [rooms-reached-1.png](docs/img/play/rooms-reached-1.png), [rooms-reached-2.png](docs/img/play/rooms-reached-2.png) | the in-sync rzx segments, one screen a room (below) |

The figures of the documents made of screenshots:

| Figure | Document | Recording, frames |
| --- | --- | --- |
| [screens.png](docs/img/design/screens.png) | doc 1, 1.2 | the screenshots above, nine screens |
| [explorers.png](docs/img/design/explorers.png) | doc 1, 1.3 | `explorers` 1250, 3750, 6250, 9250, 11 750 (the panel of each explorer) |
| [panel.png](docs/img/design/panel.png) | doc 1, 1.5 | `explorers` 1250 |
| [moments.png](docs/img/design/moments.png) | doc 1, 1.9 | `gameover` 1366, 1600, 1900; `rzx50000` 100 |
| [frame-r02000-2.png](docs/img/render/frame-r02000-2.png) | doc 6, 6.1 | `rzx02000` 2 |
| [text/panel.png](docs/img/text/panel.png) | doc 8, 8.5 | `explorers` 750 |
| `work/stage2/points/*.png` (not in a document) | stage 2 | probes A, B, C above |

The 57 rooms reached, one screen each (`tools/fig_rooms_reached.py`; the room from the RZX's `$5C01`, the picture
ours, kept where it matches the RZX's screen):

![Rooms reached, first half](docs/img/play/rooms-reached-1.png)

![Rooms reached, second half](docs/img/play/rooms-reached-2.png)

All 72 rooms drawn from the data are in [doc 1, 1.8](docs/01-game-design.md#every-room).

### 6.2 The animations

Every animation of the documents, with the recording and the frames it shows (`F:T` is frame and T-state). Each
caption gives the full command.

| Animation | Document | Recording | Frames |
| --- | --- | --- | --- |
| [load-memory.gif](docs/img/load/load-memory.gif) | doc 3, 3.5 | `c1` | 650-21 700, 83 pictures |
| [RelocateSelector.gif](docs/img/routines/RelocateSelector.gif) | doc 3, 3.3 | `c1` | 11841:26260-11841:41700 |
| [RenderPass.gif](docs/img/routines/RenderPass.gif) | doc 4, 4.3; doc 6, 6.7 | `rzx02000` | 1:9746-3:24326, 90 pictures |
| [StatusDispatch.gif](docs/img/routines/StatusDispatch.gif) | doc 4, 4.5; doc 10, 10.2 | `gameover` | 1355-1512 |
| [space-scene-lost.gif](docs/img/play/space-scene-lost.gif) | doc 1, 1.9; doc 4, 4.6 | `gameover` | 1500-1965, every 5th |
| [space-scene-won.gif](docs/img/play/space-scene-won.gif) | doc 1, 1.9; doc 4, 4.6; doc 10, 10.10 | `rzx50000` | 150-735, every 6th |
| [device-menu-keys.gif](docs/img/play/device-menu-keys.gif) | doc 5, 5.2 | `explorers` | 5130-5226 |
| [walk-keyboard.gif](docs/img/play/walk-keyboard.gif) | doc 5, 5.7 | `explorers` | 5950-6130 |
| [jump-kempston.gif](docs/img/play/jump-kempston.gif) | doc 5, 5.7 | `gameover` | 110-200 |
| [climb-kempston.gif](docs/img/play/climb-kempston.gif) | doc 5, 5.7; doc 10, 10.3 | `rzx02000` | 996-1240 |
| [HeroUpdate.gif](docs/img/routines/HeroUpdate.gif) | doc 5, 5.7 | `explorers` | 6004:13743-6004:27000 |
| [BearerKeys.gif](docs/img/routines/BearerKeys.gif) | doc 5, 5.8 | `explorers` | 6470:0-6483:0 |
| [DrawRoom.gif](docs/img/routines/DrawRoom.gif) | doc 6, 6.4 | `explorers` | 528-536 |
| [DrawSpriteColumn.gif](docs/img/routines/DrawSpriteColumn.gif) | doc 6, 6.9 | `explorers` | 6001:55856-6003:12474 |
| [CopyRects.gif](docs/img/routines/CopyRects.gif) | doc 6, 6.10 | `explorers` | 6003:12474-6003:59049 |
| [RestoreActorBackgrounds.gif](docs/img/routines/RestoreActorBackgrounds.gif) | doc 6, 6.10 | `explorers` | 6003:59049-6004:13644 |
| [EraseItem.gif](docs/img/routines/EraseItem.gif) | doc 6, 6.11 | `explorers` | 6097:60000-6098:20000 |
| [DrawPortrait.gif](docs/img/routines/DrawPortrait.gif) | doc 6, 6.12; doc 8, 8.6 | `c1` | 23509:66000-23510:13000 |
| [DrawCursor.gif](docs/img/routines/DrawCursor.gif) | doc 5, 5.6; doc 6, 6.13 | `explorers` | 5550-5553 |
| [DecodeRoomCreatures.gif](docs/img/routines/DecodeRoomCreatures.gif) | doc 7, 7.3 | `rzx24750` | 284:51900-284:54100 |
| [RunCreatures.gif](docs/img/routines/RunCreatures.gif) | doc 7, 7.4 | `rzx24750` | 0-60 |
| [creature-death-r06000.gif](docs/img/play/creature-death-r06000.gif) | doc 7, 7.6; doc 10, 10.7 | `rzx06000` | 520-700, every 3rd |
| [SpawnRoomItems.gif](docs/img/routines/SpawnRoomItems.gif) | doc 7, 7.8 | `gameover` | 492:58700-492:61300 |
| [PickUpItem.gif](docs/img/routines/PickUpItem.gif) | doc 7, 7.9 | `gameover` | 582:25000-582:28000 |
| [ItemsPass.gif](docs/img/routines/ItemsPass.gif) | doc 7, 7.10 | `rzx24750` | 608-624 |
| [PrintString.gif](docs/img/routines/PrintString.gif) | doc 8, 8.2 | `c1` | 21602:50000-21604:43000 |
| [PrintPage.gif](docs/img/routines/PrintPage.gif) | doc 8, 8.3 | `explorers` | 13857-13866 |
| [DrawBearers.gif](docs/img/routines/DrawBearers.gif) | doc 6, 6.12; doc 8, 8.7 | `c1` | 23935:30000-23938:60000 |
| [AddScore.gif](docs/img/routines/AddScore.gif) | doc 8, 8.8 | `c1` | 23508:800-23508:12400 |
| [NewHiScore.gif](docs/img/routines/NewHiScore.gif) | doc 8, 8.9 | `c1` | 26210:20300-26210:28300 |
| [MusicFrame.gif](docs/img/routines/MusicFrame.gif) | doc 9, 9.3 | `c1` | 23004:1870-23004:6900 |
| [MusicFrame-frames.gif](docs/img/routines/MusicFrame-frames.gif) | doc 9, 9.3 | `c1` | 23000-23025, one picture a frame |
| [JumpArc.gif](docs/img/routines/JumpArc.gif) | doc 10, 10.4 | `gameover` | 413-462 |
| [FallDeath.gif](docs/img/routines/FallDeath.gif) | doc 10, 10.5 | `gameover` | 1335-1373 |
| [teleport-r24750.gif](docs/img/play/teleport-r24750.gif) | doc 10, 10.6 | `rzx24750` | 716-786 |
| [ProfessorScript.gif](docs/img/routines/ProfessorScript.gif) | doc 10, 10.10 | `rzx44000` | 408-466 |
| [space-scene-strike.gif](docs/img/play/space-scene-strike.gif) | doc 10, 10.10 | `gameover` | 1504-1964, every 6th |

## 7. Review
