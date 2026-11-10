# SimCity: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

Asked: which copy is the original Infogrames release, what is on it, and where does each block land?

ZXDB (entry 4509) lists the TZX 28075 (source type "O", the original release), the +3 DSK 28076 ("O"), a TAP 28077
("++") and the Erbe TZX 28078 ("R", re-release). All four are in the local ZXDB mirror and were copied unchanged to
`work/candidates/zxdb/` with the POKE file; every Sim City file of `software/zxart.ee-offline` (36, with the
"Lemmings & Sim City" compilation disk) went to `work/candidates/zxart-offline/` and the TOSEC pack's 16 files to
`work/candidates/tosec-knobchez-2026/`; `software/games` and `zxart.ee-delta` hold none. The TZX 28075 is
`orig/SimCity.tzx.zip`, still zipped. The manual (`work/info/SimCity.txt`, the multi-format manual with Spectrum
notes) came from worldofspectrum, the local `games-info/s/` being absent.

```bash
. work/env.sh
md5 orig/SimCity.tzx.zip; shasum orig/SimCity.tzx.zip
unzip -o orig/SimCity.tzx.zip -d work/media/zxdb-SimCity.tzx
python3 tools/tzxblocks.py list "work/media/zxdb-SimCity.tzx/Sim City.tzx"        # archive info + 7 ROM-speed blocks
for i in 1 2 3 4 5 6 7; do python3 tools/tzxblocks.py "work/media/zxdb-SimCity.tzx/Sim City.tzx" $i work/stage1/blocks/o-$i.raw; done
python3 tools/basic_list.py work/stage1/blocks/basic.bin                          # six lines
python3 tools/decrypt_tape.py loader work/stage1/blocks/o-4.raw                   # the R decryption of $FE80-$FFFF
python3 tools/decrypt_tape.py check "work/media/zxdb-SimCity.tzx/Sim City.tzx"   # 3 blocks decrypted and re-encrypted equal
python3 tools/media_compare.py "work/media/zxdb-SimCity.tzx/Sim City.tzx" work/candidates --out work/stage1/media-compare.tsv
python3 tools/image.py work/mkgame/original.bin                                   # the image at the entry $5B1B
z80dasm -a -t -g 0x5B00 work/stage1/game.bin > work/stage1/g.asm
python3 ../../kit/sig_scan.py work/mkgame/original.bin --base 0 --all --out work/stage1/sig-game.json
```

Found:

- **The original is ZXDB download 28075.** ZXDB marks it the original release, its archive info says it was sampled
  from the original cassette, and it is the only tape with the protected loader. Every other copy is the Erbe
  re-release (the same three blocks decrypted), a crack, a translation, a TR-DOS conversion, a snapshot or the +3
  disk; the README's table lists each with what differs, from `work/stage1/media-compare.tsv`.
- **The tape** ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)): a BASIC "Simcity" (LINE 0,
  144 bytes: `CLEAR 32767`, `LOAD "" CODE 65024`, `RANDOMIZE USR 65024`, and three mastering lines never reached), a
  512-byte loader at `$FE00`, and three headerless blocks with flag `$00` and a header's long pilot: the screen
  (6912), code1 (37 633 bytes to `$6B00-$FE00`) and code2 (4128 bytes to `$4000-$501F`). The signal lasts 315.74 s,
  322.2 s (16 110 frames) with the pauses.
- **Two layers of protection** ([doc 3, 3.3](docs/03-build-and-load.md#33-the-loader-two-layers)): the loader's tail
  `$FE80-$FFFF` is XORed with the R register (key `(2 + 8 k) AND $7F`), and its tape routine `$FEBD`, the ROM's
  LD-BYTES copied and changed, stores every byte as `received XOR key XOR E` (key 0, 3, 6, ... per block, E the low
  byte of the count left). `tools/decrypt_tape.py` does both; the three blocks re-encrypt to the tape's bytes.
- **The mover** `$5000` (code2's last 32 bytes) copies `$4000-$4FFF` to `$5B00-$6AFF` and jumps to `$5B1B`.
- **The IM 2 table completes the last block**: code1 ends on `$FE00`, one byte over the loader's first instruction,
  because `$FD00-$FE00` is the 257-byte table of `$FC` for I = `$FD` (`JP $F70B` at `$FCFC`).
- **No known module**: the one exact hit of the signature scan, `$FFD4`, is 44 bytes of the ROM's character set
  (the letters R-U) left in the loader's padding, which the Zynaps entry also holds.
- **The image's text**: the menu bar "SYSTEM OPTIONS DISASTERS WINDOWS", the default name "HERESVILLE", the months,
  the tool names with their prices (`$6001-$606F`, "BULLDOZE `$1`" to "AIRPORT `$10000`"), the levels, the six city
  categories "VILLAGE" to "MEGALOPOLIS", and 27 advice and disaster messages (`$60C2-$62F5`, bit 7 ends each),
  found by a strings scan; no bankruptcy, impeachment, monster or scenario text exists.

## 1. One recording from power-on

Asked: what runs from power-on to play, and how is play paced?

`c1` records from power-on: the 48K with zeroed RAM and muted sound, `LOAD ""` typed and the original TZX played
with the fast LD-BYTES trap and turbo tape off (`tools/rs_capture.py`), so every block loads from the signal at ROM
speed through the game's own loader; 16 700 frames of load, then `tests/inputs/c1.txt`: the difficulty menu (A,
Q, SPACE: EASY), the landscape made, then play with the keyboard (SS+6 residential, the cursor moved with A / O / P,
SPACE places; SS+2 road; SS+8 industrial; the WINDOWS menu opened from the top bar, MAPS, back) and 3000 frames of
time. 21 535 frames in all, `session.ttd` 12.4 MB, L1 5392 interrupts, 0 diverged.

```bash
. work/env.sh
python3 tools/rs_capture.py --work work/stage1/c1 --media orig/SimCity.tzx.zip --model 48K --record-load \
    --load-frames 16700 --inputs tests/inputs/c1.txt --ranges 4000-FFFF --port-base 37030 --binary $BIN
python3 tools/ttdmem.py work/stage1/c1 16281 0x4000 0xC000 --out work/stage1/c1-16281.bin   # vs work/mkgame/original.bin
```

| Stage | Entered | Frame of `c1` (ROM-speed load) | What runs |
| --- | --- | --- | --- |
| 0 | `$FE00` | 1258, T 65 246 | the R decryption of the loader's tail |
| 1 | `$FE80` | 1259, T 13 443 | the loader: three calls of `$FEBD` (blocks in at 3561, 14 775, 16 2xx; [doc 3, 3.8](docs/03-build-and-load.md#38-the-load-in-c1)) |
| 2 | `$5000` | 16 279, T 8372 | the mover |
| 3 | `$5B1B` | 16 280, T 51 501 | the entry: SP = `$F6C2`, the Kempston test, IM 2 |
| 4 | `$8FA0` | 16 310 | the main program: the difficulty menu `$6944` (HALT at `$6955`) |
| 5 | `$835F` | 17 590 | the second task's first instruction: play |

Found, interrupts and the frame (first look; stage 2 reads the routines):

- **IM 2 through `$FCFC`**: `$5B3E-$5B44` sets I = `$FD`, IM 2 and EI; the table `$FD00-$FE00` comes from the tape
  (code1), not from code.
- **The handler `$F70B` is a two-task scheduler.** It saves every register (`$F70B-$F718`), calls the input routine
  `$F781`, then, when the byte `$F705` is 0, swaps the stack pointer between two saved values (`$F707` and `$F709`,
  the toggle `$F704` says which task is running) and returns with `EI; RET` (`$F74C`) into the other task. The main
  program starts the second task by `$830C-$831A`: its stack at `$F6EE`, preloaded with ten register words and the
  return address `$835F` at `$F702`, so the first switch pops them and "returns" into the simulation loop. Over
  `c1`'s play the switch was skipped on 2364 of 5224 interrupts (the branch at `$F720`, `$F705` not 0) and made on
  the other 2860.
- **The two tasks**: the user interface, the main loop UiLoop `$8FCC-$901B` (UiDelay `$8FD5`, a 2000-loop busy wait,
  then UiPass `$8FDA`: input, cursor, tools, menus, one step of the
  map display and of the counters each pass, the pass counter `$8F9F` at `$9008`); and the simulation loop
  `$835F-$839F` (15 calls a pass: the zone scan, the census, the advice `$99AD`, and, when the pass number `$835E`
  AND the speed mask `$8F6B` is 0, the month `$8E94` and the year end). The UI sets `$F705` to 1 around its drawing
  (`$8FE9-$8FF5`: `$6434` and `$7A6F`), a critical section in which the handler does not switch.
- **DI / EI**: the only `DI` and `EI` that run in `c1` after the load are the entry's (`$5B1B`, `$5B44`) and the
  handler's `EI` (`$F74C`, 5224 times). `HALT` runs only in the difficulty menu (`$6955`, 664 times: it waits 8
  frames between key polls). Elsewhere interrupts are off only around the ROM tape routines of save and load (`$9E35`,
  `$9E6D`) and inside the noise routine `$5B48` (`DI` ... `EI`, 200 samples), which the disasters call (`$78C2`,
  `$910F`, `$911E`, `$9138`; 30 406 of its `OUT` in `disasters`, L1).
- **Sound**: two beeper routines. `$5B48` is noise (the random routine `$5CC6` AND `$10` to port `$FE`), skipped when
  the SOUND option `$A32D` is 0; `$5B66` is a tone of 500 square cycles (`$10` and 0 to port `$FE`, delays 48 and 16
  `DJNZ` loops), reached by `JP $5B66` at `$71FC`, the refusal beep (1000 `OUT` pairs in `tools`, two beeps: the occupied cell
  at frame 13 434, traced, and one not located; 500 in `bankrupt`). The seaport refused for money is not one of them:
  SelectTool refuses a tool the funds do not cover with a silent `RET M`, and no beep was found near it (frames
  12 496-12 530 and 12 628-12 668, [doc 9, 9.9](docs/09-sound.md#99-not-reached-and-known-only-from-the-code)). No other `OUT ($FE)` runs in play but the save and load's border
  (`$9E56`, `$9EF3`, `$F7A4`).
- **Input in the interrupt**: `$F781` reads the eight keyboard half rows into `$5B00-$5B07` (bit 0 the outer key);
  `$7A01` folds the Kempston port (`$5B80`: `IN A,($1F)` inverted, or all released when the entry's test found no
  interface, `$5B7F` = 0) into the Q, A, O, P and SPACE bits; `$7A32` folds the keys 6-0 (the Sinclair joystick: 6
  left, 7 right, 8 down, 9 up, 0 fire) in the same way when neither shift is held.
- **Cost**: the handler takes about 1000-1100 T an interrupt (`$F70B` 349 T exclusive, `$F781` with the joystick folding
  760 T, L1 profiles over `c1`'s 5224 entries; 952-1062 T with the IM 2 acknowledge measured in `ports`, doc 5, 5.1),
  about 1.5 % of a 69 888 T frame. The L1 "inclusive" figure of the
  interrupt (34 748 T an entry) is not the handler's: after a switch the RET lands in the other task, and the
  profiler charges that task's work to the interrupt.
- **Passes and months** (`tools/ttdmem.py` over `growth`'s `session.ttd`, [6.0](#60-the-recordings)): the speed
  (`$A3AB`, 0 FAST to 3 PAUSED) copies a 5-byte row of `$8F6C` into `$8F67-$8F6B`; the month mask `$8F6B` is `$00`
  at FAST (a month every simulation pass), `$01` at NORMAL (every second pass), `$03` at SLOW, `$FF` when PAUSED.
  At FAST in the growth town (frames 12 000-51 850, sampled every 50 frames) 133 simulation passes gave 133 months:
  250-450 frames a month, 298 on average; eight passes timed to the frame from 20 000: 313, 278, 392, 291, 317, 284,
  289 frames. The UI task meanwhile made about 0.45 passes a frame (428 in frames 30 000-30 950; 1777 `$901D` calls in
  `c1`'s 3945 frames of play), as it runs only on the frames the scheduler gives it.
- **The heaviest pass**: a simulation pass is 250-450 frames, so a month at NORMAL takes 500-900 frames (the 800
  frames from JAN to MAR 1902 in the lab); the pass is long because the task runs on half the frames and scans the
  whole 96 x 96 map; its parts are timed in stage 2.

## 6. The game

### 6.0 The recordings

Asked: which recordings reach every part of the game, and how was each made?

Every recording keeps its `session.ttd`, `l1.json`, `states.json` (funds, date, cursor, view and pass counter every
500 frames and at each named moment; from `metro` on also the census `$8443`, the R, C and I totals, the year-end
population `$8E90` and the category `$975F`), its screenshots and `end.szx`, in `work/stage1/rec/<name>/` (`c1` in
`work/stage1/c1/`). All but `c1` are played by the bot `tools/play_bot.py` (a fresh muted 48K with the Kempston
interface on base 37020, the start state loaded, the TTD started, one plan of moves: the cursor is steered by reading
`$5CFC/$5CFD`, menus by reading the item `$6A7D`; L1 built at the end). Their start is `work/stage1/lab/loaded.szx`
(the level menu right after the tape load at signal speed, `tools/play_bot.py loaded`) or another recording's end.
The keys each pressed are its input script in `tests/inputs/<name>.txt`.

```bash
. work/env.sh
python3 tools/play_bot.py loaded --port-base 37020
PLANS="tools ports menus growth city city2 levels bankrupt" sh work/stage1/run_recs.sh     # then disasters from city2
python3 tools/play_bot.py record metro --start work/stage1/rec/city/end.szx --work work/stage1/rec/metro --port-base 37020
python3 tools/play_bot.py list                                                              # every plan's description
```

| Name | Start | Frames | How | What it reached |
| --- | --- | ---: | --- | --- |
| `c1` | power-on | 21 535 | `tools/rs_capture.py`, `tests/inputs/c1.txt` ([1](#1-one-recording-from-power-on)) | the tape at signal speed through the game's loader, the level menu (EASY), the landscape, R, road and I placed with the keyboard, the WINDOWS menu, 3000 frames of time |
| `tools` | loaded | 19 867 | bot, easy level, no POKE; AUTO-BUDGET on | every tool once: bulldozer on trees, road, power line, rail, park, R, C, I, police, fire, airport (`$10 000`), stadium, the power station dialog (nuclear `$5000`, coal `$3000`), a nuclear and a coal station; the seaport refused at `$386` (silently, by SelectTool: no beep found); a road on an occupied cell (the beep, frame 13 434); the view scrolled with CS+5..8; the icon shortcuts SS+1..0; JUN 1905, funds `$175` |
| `ports` | loaded | 8738 | bot, easy | the Kempston joystick steering the cursor and firing (the second control method); a seaport on the lake shore, a coal station, a stadium, power lines |
| `menus` | loaded | 30 136 | bot, easy, a town first | the about box; each OPTIONS toggle; the four speeds; the DISASTERS menu and DISABLE ALL; WINDOWS: MAPS with its 8 sub-maps (the 9 areas were NOT reached: the script pressed CAPS SHIFT + 1..9, the keys need SYMBOL SHIFT, so MapArea `$9C2B` stayed 0 and every screenshot shows area 1, [doc 5, 5.10](docs/05-controls.md#510-the-maps-window-layers-and-areas)), ENTER for the maps, the budget with the tax rate edited, the evaluation; save (name, "START TAPE AND PRESS SPACE", 2370 frames) and load ("SEARCHING", "FOUND", 720 frames of loading) from a tape rebuilt from memory (`tools/savetap.py`; the funds and map spoiled by a tool write in between and restored: `$0` back to `$14 325`); USE OLD LANDSCAPE with the gene 12345 (another island) and back to 00003; START NEW CITY with YES (a new landscape at EASY); EXIT SIMCITY (asked twice) |
| `growth` | loaded | 51 985 | bot, easy, a town with a coal station; NORMAL until about frame 11 000, FAST from 11 100 (SimPass 37) | 155 months in all (doc 4, 4.8), most of them at FAST (the speed measure in [1](#1-one-recording-from-power-on)); the evaluation every 10 000 frames; every map; the town stays a VILLAGE (year-end population 656 at DEC 1914) |
| `city` | loaded | 77 592 | bot, easy; funds written to 999 999 at `$8F97` twice (a tool write, not the POKE file: its `NOP`s break the category's comparison, `$6680`) | the start view filled: nuclear station, three roads, 17 R zones (18 laid; the one centred at (45, 35) was refused for water), 8 C and 8 I zones, police, fire, stadium, a power line; tax 7 %; FAST to SEP 1917; TOWN by the first evaluation (SEP 1908: population 6144) |
| `city2` | city's end | 82 012 | bot, FAST | the same city to DEC 1935: it levels off at 5500-6200; every map at NORMAL speed; the last evaluation |
| `metro` | city's end | 96 503 | bot; funds written to 999 999 twice | a second block at view (47, 53) with its own nuclear station; to OCT 1934 (Month 9 in the end state; the log's last date is SEP 1934 at frame 95 121); the year-end population rises to 9312 (1931) and falls back: TOWN, never CITY |
| `disasters` | city2's end | 13 050 | bot, NORMAL | each item of the DISASTERS menu with 2000 frames after it: fire, flood, earthquake, air crash, tornado, nuclear meltdown (the meltdown leaves the radiation tiles and burns the lower blocks) |
| `levels` | loaded | 2319 | bot | MEDIUM (`$10 000`); START NEW CITY with YES, the level menu's INPUT NEW CITY NAME (METRO: the name becomes "METROVILLE", the typed letters over "HERES"), DIFFICULT (`$5000`) |
| `bankrupt` | loaded | 25 095 | bot, difficult | the money spent on 24 R zones with no road, the tax at 0 %, ten spans of 2000 frames at FAST: the funds stay at `$2680` (no roads, no upkeep, no income), the budget window opens at each year end; no bankruptcy and no game over exist |

Each run with its command (from the case folder after `. work/env.sh`) and its `session.ttd`. The writers of docs
01-10 made no new TTD recording: they opened these sessions read-only into `work/docs/sc*/<name>/` (`kit/rs.py
open`, their own port bases) for probes and animations, and ran one clone experiment (the last row).

| Run | Command | `session.ttd` |
| --- | --- | --- |
| `c1` | the `tools/rs_capture.py` command of [1](#1-one-recording-from-power-on) | `work/stage1/c1/session.ttd`, 12 964 652 bytes |
| `tools` | `python3 tools/play_bot.py record tools --work work/stage1/rec/tools --port-base 37020` (through `run_recs.sh`) | `work/stage1/rec/tools/session.ttd`, 20 715 933 bytes |
| `ports` | `python3 tools/play_bot.py record ports --work work/stage1/rec/ports --port-base 37020` | `work/stage1/rec/ports/session.ttd`, 8 707 947 bytes |
| `menus` | `python3 tools/play_bot.py record menus --work work/stage1/rec/menus --port-base 37020` | `work/stage1/rec/menus/session.ttd`, 21 341 709 bytes |
| `growth` | `python3 tools/play_bot.py record growth --work work/stage1/rec/growth --port-base 37020` | `work/stage1/rec/growth/session.ttd`, 54 910 775 bytes |
| `city` | `python3 tools/play_bot.py record city --work work/stage1/rec/city --port-base 37020` | `work/stage1/rec/city/session.ttd`, 84 653 032 bytes |
| `city2` | `python3 tools/play_bot.py record city2 --start work/stage1/rec/city/end.szx --work work/stage1/rec/city2 --port-base 37020` | `work/stage1/rec/city2/session.ttd`, 91 918 689 bytes |
| `metro` | `python3 tools/play_bot.py record metro --start work/stage1/rec/city/end.szx --work work/stage1/rec/metro --port-base 37020` | `work/stage1/rec/metro/session.ttd`, 117 491 148 bytes |
| `disasters` | `python3 tools/play_bot.py record disasters --start work/stage1/rec/city2/end.szx --work work/stage1/rec/disasters --port-base 37020` | `work/stage1/rec/disasters/session.ttd`, 14 649 774 bytes |
| `levels` | `python3 tools/play_bot.py record levels --work work/stage1/rec/levels --port-base 37020` | `work/stage1/rec/levels/session.ttd`, 1 990 834 bytes |
| `bankrupt` | `python3 tools/play_bot.py record bankrupt --work work/stage1/rec/bankrupt --port-base 37020` | `work/stage1/rec/bankrupt/session.ttd`, 19 078 869 bytes |
| stage 2, the growth ceiling | `python3 work/stage2/ceiling.py`: metro's `end.szx`, TaxRate `$91E4` = 0, Funds 999 999, FAST, 80 000 frames on port base 37040 | none (no TTD by design); `work/stage2/ceiling.log` every 5000 frames, `work/stage2/ceiling-end.szx` |
| stage 2, the TTD failure | `python3 work/stage2/ttd139k.py`: city's `end.szx`, 145 000 frames recorded on port base 37040 | `work/stage2/ttd139k/session.ttd`, 57 788 179 bytes, partial: the dump failed (HTTP 409), not usable |
| doc 09, SOUND off | `python3 work/docs/scD/exp_soundoff.py`: city2's `end.szx`, FIRE due, SoundOn 1 then 0, 410 frames a run on port base 37080 | none (a clone experiment); `work/docs/scD/exp-soundoff.json` |

The growth-ceiling run reached what no recording did: at tax 0 the year-end population PopLastYear `$8E90` rose to
8256 (read in AUG 1935: the 1934 year end), 9728 (read in JUN 1936: 1935's) and **10 624 (read in APR 1937: the 1936
year end)**, over the CITY threshold, about two years after the run's start (OCT 1934), then 11 376-14 384 up to OCT
1947. The zones did not fill: the highest densities rose from 36-40 to 51-61, nine or ten R zones stayed at 0, and an
R block appeared only now and then (0 or 1). Category `$975F` stays 1 in memory, because
CategoryOf runs only when the evaluation opens ([doc 10,
10.10](docs/10-gameplay-logic.md#1010-the-category-and-the-growth-ceiling)). So the bot cities were held by the tax.

Not reached, and why:

- **The categories above TOWN** (CITY above 10 000, CAPITAL above 50 000, METROPOLIS above 100 000, MEGALOPOLIS above
  500 000; the thresholds at `$9750`, each exclusive): the bot's recorded cities level off at 6000 (one view) and 9300 (two), held by the tax
  penalty at 7 %; stage 2's ceiling run (above) passed 10 000 at tax 0 but did not open the evaluation, so the CITY
  title itself was not shown. A POKE of the population would not be a witness of the game.
- **Bankruptcy and game over**: the image has no text for them (the strings scan, [0](#0-the-medium)); `bankrupt`
  shows the funds cannot fall without spending; the tools refuse what the funds do not cover (`tools`, the seaport, silently).
- **Scenarios**: none exist; every city is made from a 5-digit gene (default 00003).
- **The Sinclair joystick** (keys 6-0, `$7A32`) and **the +3 disk release**: not played; the folding routine is read
  ([1](#1-one-recording-from-power-on)).
- **Each sound heard**: the recordings are muted by rule; the two beeper routines and where they run are in
  [1](#1-one-recording-from-power-on).

### 6.1 The screens

Every screenshot is the emulator's 512 x 384 picture at the frame its name gives (frames of its recording), in
`docs/img/play/<recording>-<frame>-<name>.png`.

| Screen | Recording, frame | What it shows |
| --- | --- | --- |
| [creating the landscape](docs/img/play/tools-000088-creating-landscape.png) | tools 88 | "CREATING LANDSCAPE PLEASE WAIT", about 700 frames |
| [the new city](docs/img/play/tools-000788-new-city.png) | tools 788 | the start view of gene 00003, JAN 1902, `$20 000` |
| [AUTO-BUDGET on](docs/img/play/tools-000956-auto-budget-on.png) | tools 956 | the OPTIONS menu |
| [bulldozer](docs/img/play/tools-001721-bulldozer.png), [road](docs/img/play/tools-002499-road.png), [power line](docs/img/play/tools-003248-power-line.png), [rail](docs/img/play/tools-003999-rail.png), [park](docs/img/play/tools-004719-park.png) | tools 1721-4719 | each tool with its price in the status box |
| [residential](docs/img/play/tools-005526-residential.png), [commercial](docs/img/play/tools-006332-commercial.png), [industrial](docs/img/play/tools-007137-industrial.png) | tools 5526-7137 | the three zones; an unpowered zone blinks its letter with a lightning cell; the advice changes ("MORE COMMERCIAL ZONES NEEDED") |
| [police](docs/img/play/tools-007944-police.png), [fire](docs/img/play/tools-008748-fire.png), [airport](docs/img/play/tools-009535-airport.png), [stadium](docs/img/play/tools-010346-stadium.png) | tools 7944-10346 | the buildings; icons the funds no longer cover are dimmed |
| [power station dialog](docs/img/play/tools-011069-select-power-type.png), [nuclear](docs/img/play/tools-011107-nuclear.png), [coal](docs/img/play/tools-011898-coal.png) | tools 11069-11898 | SELECT TYPE (nuclear `$5000`, coal `$3000`, NONE) and both stations |
| [seaport refused](docs/img/play/tools-012666-seaport-no-funds.png), [occupied cell](docs/img/play/tools-013457-occupied-beep.png) | tools 12666, 13457 | the two refusals: the seaport for money (silent, SelectTool), the occupied cell with the `$5B66` beep (frame 13 434) |
| [scroll](docs/img/play/tools-013497-scroll-cs8.png), [shortcut SS+6](docs/img/play/tools-013761-shortcut-ss6.png) | tools 13497, 13761 | the view moved by CS+8; the residential tool picked by SS+6 |
| [Kempston](docs/img/play/ports-001000-kempston-moved.png), [seaport](docs/img/play/ports-001989-seaport.png), [coal](docs/img/play/ports-002771-coal.png) | ports 1000-2771 | the cursor moved by the joystick; a seaport on the shore |
| [about](docs/img/play/menus-013854-about.png) | menus 13854 | the credits box ("FOR PROBE SOFTARE LIMITED") |
| [OPTIONS](docs/img/play/menus-014409-option-auto-budget-toggled.png), [speed](docs/img/play/menus-015767-speed-menu.png) | menus 14409, 15767 | AUTO-BULLDOZE, AUTO-BUDGET, SOUND, ZONE DEMOLISH WAIT, SIMULATION SPEED; FAST, NORMAL, SLOW, PAUSED |
| [DISASTERS](docs/img/play/menus-018484-disasters-menu.png), [DISABLE ALL](docs/img/play/menus-018666-disable-all.png) | menus 18484, 18666 | the six disasters and their switch |
| [WINDOWS](docs/img/play/menus-018965-windows-menu.png), [MAPS](docs/img/play/menus-019003-maps.png), [sub-map](docs/img/play/menus-019135-maps-sub3.png), ["region 5", in fact area 1](docs/img/play/menus-019501-maps-region5.png), [ENTER](docs/img/play/menus-019729-enter-maps.png) | menus 18965-19729 | MAPS, BUDGET, EVALUATION; the map window with CITY, POLLUTN, POLICE, FIREDEP, TRAFFIC, POWER, TRANSPT, CRIME and the 3 x 3 area keys (the "region 5" shot shows area 1: CAPS SHIFT was pressed, the keys need SYMBOL SHIFT) |
| [budget](docs/img/play/menus-020006-budget-tax.png), [evaluation](docs/img/play/menus-020323-evaluation.png) | menus 20006, 20323 | FISCAL BUDGET with the tax rate being edited; EVALUATION (approval, problems, population, category, score) |
| [save](docs/img/play/menus-020866-save-start-tape.png), [saving](docs/img/play/menus-020896-saving.png), [load](docs/img/play/menus-023647-load-searching.png), [loaded](docs/img/play/menus-026017-loaded.png) | menus 20866-26017 | the tape dialogs and the city back after the load |
| [USE OLD LANDSCAPE](docs/img/play/menus-026140-old-landscape.png), [gene 12345](docs/img/play/menus-026326-gene-12345.png), [its city](docs/img/play/menus-027132-gene-12345-city.png), [gene 00003 again](docs/img/play/menus-028247-gene-00003-city.png) | menus 26140-28247 | the gene dialog and two landscapes |
| [START NEW CITY](docs/img/play/menus-028370-start-new-city-yes.png), [its level menu](docs/img/play/menus-028438-start-new-city-level.png), [the new city](docs/img/play/menus-029276-start-new-city-easy.png) | menus 28370-29276 | ARE YOU SURE, the levels, a new landscape |
| [EXIT SIMCITY](docs/img/play/menus-029758-exit-simcity-yes.png), [asked again](docs/img/play/menus-029826-exit-simcity-1.png) | menus 29758, 29826 | the second confirmation |
| [level menu](docs/img/play/levels-001139-level-menu.png), [METROVILLE](docs/img/play/levels-001397-city-name-metro.png), [difficult](docs/img/play/levels-002309-difficult-city.png) | levels 1139-2309 | INPUT NEW CITY NAME; `$5000` at DIFFICULT |
| [town](docs/img/play/growth-010417-town-built.png), [evaluation](docs/img/play/growth-051472-evaluation-20.png) | growth 10417, 51472 | the bot's town and a VILLAGE after 13 years |
| [city built](docs/img/play/city-016450-city-built.png), [TOWN](docs/img/play/city-077514-evaluation-15.png) | city 16450, 77514 | the full view and its evaluation |
| [maps](docs/img/play/city2-081405-maps-sub1.png), [pollution](docs/img/play/city2-081513-maps-sub3.png), [evaluation](docs/img/play/city2-081964-evaluation-end.png) | city2 81405-81964 | 1935 |
| [second block](docs/img/play/metro-014277-block-built.png), [evaluation](docs/img/play/metro-075053-evaluation-30.png) | metro 14277, 75053 | population 8800, TOWN, approval 0 % |
| [the whole city](docs/img/play/096503-metro-city-map.png) | metro 96503 | the 96 x 96 map drawn from memory ([doc 2, 2.9](docs/02-architecture.md#29-the-map-tiles-and-a-whole-city)) |
| [fire](docs/img/play/disasters-000655-fire-1.png), [flood](docs/img/play/disasters-002784-flood-1.png), [earthquake](docs/img/play/disasters-004937-earthquake-1.png), [air crash (nothing: city2 has no airport)](docs/img/play/disasters-006614-air-crash-0.png), [tornado](docs/img/play/disasters-009315-tornado-1.png), [meltdown](docs/img/play/disasters-011540-meltdown-1.png) | disasters 655-11540 | each disaster on city2's city |
| [money spent](docs/img/play/bankrupt-002658-spent.png), [the year-end budget](docs/img/play/bankrupt-024891-window-10.png) | bankrupt 2658, 24891 | 24 R zones with no road; the budget at 0 % tax, `$2680` |

### 6.2 The city map and the state

Asked: where does the city live, and which variables hold the simulation's state?

- **The map**: 96 x 96 bytes at `$C450-$E84F`, row-major, `$C450 + 96 y + x` (MapAddr `$6BE6`; stage 1 had `$6BDB`); all `$02` (clear land)
  in the image, the landscape written over it when a city is made. A byte below `$80` is a cell (0-1 water, 2 land,
  6 trees, roads, rails, power lines, empty zones); `$80-$BF` starts a row of a building and `$C0-$FF` continues it
  ([doc 2, 2.9](docs/02-architecture.md#29-the-map-tiles-and-a-whole-city), where the map drawn this way matches the
  screen to the pixel). The view's origin is `$6507/$6508` (map cells), the cursor `$5CFC/$5CFD`.
- **Funds**: 24 bits at `$8F97` (`tools/play_bot.py` state). Every price is taken through the shared 24-bit
  subtraction `$6680` (`AND A; SBC HL,DE; LD A,C; SBC A,B`); the POKE file's "infinite money" (26241,0 and 26242,0)
  `NOP`s its `SBC HL,DE` at `$6681-$6682`, which also breaks the category's comparison through the same routine.
- **Date**: the month `$8F9B` (0 = JAN), the year word `$8F9C`, from JAN 1902 (`$830C` sets 1902).
- **Speed**: `$A3AB` (0 FAST to 3 PAUSED), its row of `$8F6C` copied into `$8F67-$8F6B`; the month mask `$8F6B`
  ([1](#1-one-recording-from-power-on)).
- **Population**: `$8443` (24 bits) is summed during the simulation pass (0 at its start, so a sample can read 0
  mid-pass: `metro`'s states); `$8E94` copies it to `$8E8A` each month; the year end keeps `$8E8D` (the previous
  year) and `$8E90`, which the category `$9760` compares with the thresholds at `$9750` (2000, 10 000, 50 000,
  100 000, 500 000) into `$975F` (0 VILLAGE ... 5 MEGALOPOLIS); a population must exceed a threshold (Sub24 and
  `RET P`), so 2000 is still a VILLAGE.
- **R, C, I**: the developed totals, words at `$8446`, `$8448`, `$844A` (metro at its height: 35, 16, 18). The
  advice `$99AD` picks its message (index `$9996`, text `$5FC6` by `$6317`) from their ratios: "MORE RESIDENTIAL ZONES
  NEEDED" when (R + C + I) / 4 >= R, commercial when the total / 8 >= C, industrial when the total / 8 >= I, then
  roads, rail, power, stadium, port, airport, police, fire, taxes, funding, pollution, crime, traffic. This is the
  game's RCI demand; there is no demand bar.
- **The save** (`$9E1F-$9E58`): 7 bytes from `$8F97` (funds, date) to `$A93C`, 12 from `$5F68` (the name) to
  `$A944`, of which the header saves 11 (the 12th lands at `$A94F`, past its 31 bytes), then the ROM's SA-BYTES (through `$F7AA`) writes two headerless blocks with flag `$FF`: `$1F` bytes from
  `$A930` and the `$2400`-byte map from `$C450`. The load (`$9E5A-$9EF8`, LD-BYTES through `$F79F`) prints
  SEARCHING, "FOUND :-" and the name, compares it and copies the state back; an error prints "TAPE LOADING ERROR"
  (`$9EFC`). `tools/savetap.py` builds that tape from a running instance's memory (the emulator records no tape).
- **The images**: as loaded, at the entry and in play, and what changes between them: [doc 2,
  2.4](docs/02-architecture.md#24-three-images-and-the-heatmap).

### 6.3 The animations

Every animation in `docs/` with the document that shows it, the recording it was made from (the writers' read-only
copy under `work/docs/sc*/` of the session named) and its frames; the full command is in each caption.

| Animation | Document | Recording | Frames |
| --- | --- | --- | --- |
| [load-c1.gif](docs/img/load/load-c1.gif) | [doc 3, 3.8](docs/03-build-and-load.md#38-the-load-in-c1) | `c1` | 1200-16 400, 103 pictures, one every 150 frames |
| [LoaderStart.gif](docs/img/routines/LoaderStart.gif) | [doc 3, 3.4](docs/03-build-and-load.md#34-layer-1-the-r-keyed-tail) | `c1` | 1258 (T 65 000) to 1259 (T 16 000), 48 pictures |
| [LoadBlock.gif](docs/img/routines/LoadBlock.gif) | [doc 3, 3.5](docs/03-build-and-load.md#35-layer-2-loadgame-and-loadblock) | `c1` | 3420-3460, 60 pictures |
| [Interrupt.gif](docs/img/routines/Interrupt.gif) | [doc 4, 4.3](docs/04-game-loop.md#43-the-interrupt-and-the-switch) | `c1` | 20 003, T 1700-3700, 50 pictures |
| [SimTask.gif](docs/img/routines/SimTask.gif) | [doc 4, 4.6](docs/04-game-loop.md#46-the-simulation-tasks-pass) and [doc 10, 10.1](docs/10-gameplay-logic.md#101-the-simulation-pass) | `city2` | 65 719-66 140 (pass 176), 86 pictures, one every 5 frames |
| [MovePointer.gif](docs/img/routines/MovePointer.gif) | [doc 5, 5.3](docs/05-controls.md#53-the-pointer-one-step-a-pass-no-acceleration) | `tools` | 800-806, 72 pictures, O held |
| [ShiftScroll.gif](docs/img/routines/ShiftScroll.gif) | [doc 5, 5.6](docs/05-controls.md#56-scrolling-caps-shift--5-8-and-the-scroll-corner) and doc 6, 6.4 | `tools` | 13 458-13 468, 80 pictures |
| [RunMenu.gif](docs/img/routines/RunMenu.gif) | [doc 5, 5.8](docs/05-controls.md#58-the-menus-an-input-state-machine) | `menus` | 19 802-19 816, 70 pictures |
| [DrawViewRowPass.gif](docs/img/routines/DrawViewRowPass.gif) | [doc 6, 6.3](docs/06-rendering.md#63-drawviewrowpass-one-view-row-a-pass) | `tools` | 19 255-19 300, 90 pictures |
| [blink-unpowered.gif](docs/img/play/blink-unpowered.gif) | [doc 6, 6.6](docs/06-rendering.md#66-the-blink-of-unpowered-zones) and doc 1, 1.6 | `tools` | 19 240-19 560, every 4th frame |
| [DrawMover.gif](docs/img/routines/DrawMover.gif) | [doc 6, 6.9](docs/06-rendering.md#69-the-movers-train-plane-and-tornado) | `tools` | 19 240-19 262, 88 pictures |
| [DrawOverview.gif](docs/img/routines/DrawOverview.gif) | [doc 6, 6.11](docs/06-rendering.md#611-the-overview-maps) | `menus` | 19 096-19 136, 80 pictures |
| [ResidentialStep.gif](docs/img/routines/ResidentialStep.gif) | [doc 7, 7.3](docs/07-objects.md#73-zones-the-map-is-the-record) | `growth` | 4528-4531 |
| [disasters-tornado.gif](docs/img/play/disasters-tornado.gif) | [doc 7, 7.6](docs/07-objects.md#76-the-movers-train-plane-tornado) and doc 1, 1.10 | `disasters` | 8780-11 000, every 40th frame |
| [ShowWindow.gif](docs/img/routines/ShowWindow.gif) | [doc 8, 8.9](docs/08-hud-and-text.md#89-menus-and-dialogs) | `menus` | 13 825-13 835, 80 pictures |
| [BudgetHook.gif](docs/img/routines/BudgetHook.gif) | [doc 8, 8.10](docs/08-hud-and-text.md#810-the-budget-window) | `menus` | 19 940-19 941, 70 pictures |
| [InputLine.gif](docs/img/routines/InputLine.gif) | [doc 8, 8.12](docs/08-hud-and-text.md#812-the-line-editor-and-the-city-name) | `levels` | 1249, T 8000-32 000, 50 pictures |
| [NoiseBurst.gif](docs/img/routines/NoiseBurst.gif) | [doc 9, 9.2](docs/09-sound.md#92-noiseburst-the-disaster-noise) | `disasters` | 2236 (T 40 400) to 2237 (T 40 000), 60 pictures |
| [ToneBeep.gif](docs/img/routines/ToneBeep.gif) | [doc 9, 9.4](docs/09-sound.md#94-tonebeep-the-refusal) | `tools` | 13 434 (T 32 000) to 13 435 (T 10 000), 60 pictures |
| [FloodFill.gif](docs/img/routines/FloodFill.gif) | [doc 10, 10.2](docs/10-gameplay-logic.md#102-power) | `growth` | 19 242-19 266 |
| [city-district-growth.gif](docs/img/play/city-district-growth.gif) | [doc 10, 10.4](docs/10-gameplay-logic.md#104-the-growth-rules-of-r-c-and-i) | `city` | 16 400-46 400, every 600th frame |
| [SimTask-growth.gif](docs/img/routines/SimTask-growth.gif) | [doc 10, 10.1](docs/10-gameplay-logic.md#101-the-simulation-pass) | `growth` | 19 232-19 532 (pass 65), 61 pictures |
| [NewLandscape.gif](docs/img/routines/NewLandscape.gif) | [doc 10, 10.11](docs/10-gameplay-logic.md#1011-the-city-generator) | `growth` | 90-710, every 20th frame |
| [disasters-earthquake-spread.gif](docs/img/play/disasters-earthquake-spread.gif) | [doc 10, 10.12](docs/10-gameplay-logic.md#1012-disasters) and doc 1, 1.10 | `disasters` | 4400-8780, every 80th frame |
| [disasters-meltdown.gif](docs/img/play/disasters-meltdown.gif) | [doc 10, 10.12](docs/10-gameplay-logic.md#1012-disasters) and doc 1, 1.10 | `disasters` | 11 000-13 040, every 40th frame |
