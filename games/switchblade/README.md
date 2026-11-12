# Switchblade (Gremlin Graphics, 1991)

State: docs written, in review: 12 documents, 62 figures (PNG), 42 animations (GIF), 98 mermaid diagrams and 31 audio
files (24 MP3, 7 short WAV; 6.9 MB), counted on 2026-11-12 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs/audio -name '*.mp3' | wc -l; find docs/audio -name '*.wav' | wc -l; du -sh docs/audio
```

| | |
| --- | --- |
| Machine | 48K and 128K: one tape for both. The second loader stage tests the paging (`$618E`: a byte of bank 4 written, bank 0 read back) and loads the last block (8441 bytes, bank 4) only on a 128K ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)). ZXDB marks the entry "ZX-Spectrum 48K/128K"; the instructions name "Spectrum 48k/128k/+2". What bank 4 adds: [WALKTHROUGH 0.4](WALKTHROUGH.md#04-the-machine-48k-and-128k) |
| Profile (AGENTS.md 4.0) | a flip-screen platform arcade adventure on one tape for 48K and 128K: Hiro walks, jumps, climbs ladders and falls through 127 rooms on a 20-row map, reveals each room zone by zone, fights with three fist strikes picked by the fire charge or six thrown weapons, and gathers 16 Fireblade fragments to kill four giants and Havok ([doc 1](docs/01-game-design.md), [doc 10](docs/10-gameplay-logic.md)). The engine: an IM 2 tick and a main loop with no `HALT` and no frame sync (a pass from 0.02 to 11.6 frames, up to 72 with a room build; zone reveals stall it for 10-27 frames and room changes for 27-72, [doc 4](docs/04-game-loop.md)); one actor record a 256-byte page, ten pages, 73 kinds ([doc 7](docs/07-objects.md)); 3-bit column pictures read through the stack with an outline made on the fly into a chunk buffer, the surface ground taken from the 48K ROM's keyword table ([doc 6](docs/06-rendering.md)); a 48K beeper effect player and, on a 128K, Ben Daglish's AY player in bank 4 behind a 162-byte glue ([doc 9](docs/09-sound.md)). Details: [below](#profile) |
| Authors | Jeff Calder (program), John Smyth (graphics), Ben Daglish (music): ZXDB entry 5089, authors in this order with the roles "A" (graphics) for John Smyth and "M" (music) for Ben Daglish. The game's own high-score table starts with "JEFF C"; the AY rip names "Benn Daglish", "(c) 1991 Gremlin Graphics". A conversion of Simon Phipps' Switchblade (Atari ST, Amiga, 1989); the Spectrum code is Jeff Calder's |
| Release | ZXDB 5089, "Arcade Game: Platform": Gremlin Graphics Software Ltd, 1991, £9.99 (tape) and £14.99 (+3 disk); the budget re-release by GBH (release 1, 1991, £3.99, barcode 5013658080268). A playable demo was given away on the Your Sinclair issue 63 covertape ("Six Pack", with Earth Shaker) and on MicroHobby 210 |
| Original | `orig/Switchblade.tzx.zip` (md5 `f936c7a55ce01b1cb3abc4faf87892ab`, SHA-1 `37480759aecc2a64cf6429ea6ed1cc96c99cac5f`), ZXDB download 31610 (`/pub/sinclair/games/s/Switchblade.tzx.zip`, source type "original"), holding `Switch Blade.tzx` (52 995 bytes, md5 `8e752fb706580cee0be855f9d58cafb6`, SHA-1 `f2f90e9604d3c69472034ecc4d310755a61c1eb0`, SHA-256 `2ad3bcf69a45376ee33edfcfbcf0e0f2e4cda97dba11fe5b46d058b31add6f5c`, "Created with Ramsoft MakeTZX"): a BASIC "( Switch )" whose line 0 runs machine code in the program, then four headerless blocks at ROM speed (2060, 37 537, 4497, 8441 bytes) read by the game's own copy of LD-BYTES at `$FF00` ([doc 3, 3.1](docs/03-build-and-load.md#31-the-tape-block-by-block)) |

## Profile

Picked in phase 0 from the instructions (`work/candidates/docs/Switchblade.txt`, ZXDB 5089) and the first recordings
(AGENTS.md 4.0); the documents settled each row (the links).

| Row | What applies here |
| --- | --- |
| Genre: arcade adventure, flip-screen platform game | Hiro, the last Bladeknight, explores the Undercity of Thraxx screen by screen (run, jump, climb ladders, drop through floors) to collect the 16 fragments of the Fireblade, then fights Havok with it. The world is one connected labyrinth of flip screens with hidden rooms and passages; the screen shows only the blocks Hiro has visited in the current game ("self-mapping"), so the map is drawn from the image's own room data, every room and every block, with the route the RZX run takes through it. Four boss creatures (Giant Spikelouse, Giant Scorpoid, Giant Cybat, Giant Roborganism) and Havok at the end ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)) |
| Objects and puzzles | bonus gems (50-700), the flask (700), orbs (1000-5000, shattered if they hit the floor), the letters of EXTRA (a life) and BONUS (10 000), weapon shields (fist, blade, scorchball, dart, spinblade, needle bolts, trispike), the bullet, power-up, speed-up and reset shields, vitality, invulnerability, the 16 Fireblade fragments (10 000 each, 50 000 for the whole blade); the Fireblade builds up in the HUD. Each object kind is placed on the map from the data |
| Enemies and hazards | flames, proximity floor spikes, bladeballs, spikelice, cybats, mansnakes, spidorbs, crestheds, reptilons, scorpoids, flamehogs, kobras, striders, razorbs (the instructions' list, each to be matched with its sprite and code), the four bosses and Havok |
| Combat | the fire button held builds the combat power meter; let go, Hiro punches, high-kicks or sweeps by the meter's quarter, or fires the cyber-arm's weapon with a bullet count |
| Rendering: flip-screen, revealed blocks | each screen built from block data; the unvisited blocks stay black and are revealed as Hiro walks in; sprites over the background; the HUD (score, lives, the Fireblade, the vitality and power meters, EXTRA and BONUS) |
| Engine: 128K paging | one bank (4) loaded on a 128K only; the rest of the program is the same on both machines (the 48K memory at the menu equals the 128K one except 322 bytes, [WALKTHROUGH 0.4](WALKTHROUGH.md#04-the-machine-48k-and-128k)); the bootstrap patches five call sites and copies the glue ([doc 3, 3.3](docs/03-build-and-load.md#33-the-bootstrap-4000-and-the-128k-set-up)) |
| Sound | on a 128K Ben Daglish's AY player in bank 4: three tunes (the title, the start jingle, the in-game music) and 14 effects; the title chooses music or effects (left or right), and in music mode no effect is heard. On a 48K a beeper player in the interrupt plays the same 14 effect numbers as bursts once a frame; the renders are in `docs/audio` ([doc 9](docs/09-sound.md)) |

## Other releases and copies

Every copy found was copied unchanged into `work/candidates/<source>/` and compared block by block with the original
([WALKTHROUGH 0.2](WALKTHROUGH.md#02-the-release-check)): the ZXDB downloads and the NVG mirror (`software/zxdb/files`),
the TOSEC set in the 2026 "knobchez" pack, the AY rips, the POKE files and the RZX Archive run. A name search of the
NAS `WDC14Tb-3/Consoles/ZX Spectrum` (300 s) found no Switchblade file. The ZXDB instructions text was not in the
local tree; it was fetched from its ZXDB URL and matches the md5 ZXDB gives (`48bcd4d5941b6e3b791d6ac2cb35ee2f`).

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| ZXDB 31610 `Switchblade.tzx.zip`; WoS `games.zip` `Switchblade.tzx.zip`; TOSEC `Switchblade (1991)(Gremlin Graphics)(128K)` (45124, identical file) | the original Gremlin tape | the file in `orig/` |
| ZXDB 31612 `Switchblade(GBH).tzx.zip` (`Switch Blade (GBH).tzx`); TOSEC `(GBH)(128K)[re-release]` (45123) | the GBH budget re-release | the same six blocks byte for byte; the two TZX files differ in 7 bytes, the pause lengths only |
| ZXDB 31611 `Switchblade.tap.zip` (`SWITCHBL.TAP`); TOSEC `(48K-128K)` (45129) | a TAP of the original with the loader patched | header "SW.BLADE"; the BASIC's loader code has `JP $0562` where the original has `IN A,($FE) / RRA` (offset 123), so the ROM's LD-BYTES reads the blocks; the four data blocks are the original's |
| TOSEC `(128K)[a]` (45125) | an alternative dump | the 37 537-byte block differs in 26 bytes, `$8127-$816D`: the names of entries 1-4 (JEFF C, LINDA, SIMES, DANGERSTU) replaced by JOSE LUIS, RUI, CARLOS, FC PORTO ([doc 3, 3.5](docs/03-build-and-load.md#35-the-releases-and-the-hacks)) |
| TOSEC `(48K-128K)[a]` (45130) | a cheat | header "Sw.Blade+"; one byte of the 37 537-byte block: `$C9` for `$3A` at offset 10 958 (`$962A` at the load address: the first byte of LoseLife, `$C9` (`RET`) for `$3A` (`LD A,(EndFlags)`): losing all energy costs no life) |
| NVG `switchblade.zip` (`SWITCBLD.TAP`, with `Readme.txt`); TOSEC `(128K)[m]` (45127, 45128) | Ramsoft's "Switchblade & Trainer" (Stefano Donati, from Theo Devil's disk crack) | standard headers "SWITCH", "BladeIntro", "BladeCode" (38 750 bytes), "BladePage4" (8441 bytes, the original's last block) |
| TOSEC `[h Alexey Sorokin]`, `[h Sukin And Son Corp.]` | 48K hacks | the blocks of 2060, 37 537 and 4497 bytes are the original's; no bank 4 block (48K only); own BASIC |
| TOSEC `[h Pavel Nikitin]`, `[t Pokes]` | a re-saved copy with headers, a trainer | the four data blocks are the original's, each behind a standard header; own BASIC |
| TOSEC `[h Saposoftware]`, `[h Atossoft]` (= zxart `(EN)[h Atossoft].tap`) | hacks | re-packed: Saposoftware four blocks of 182, 1288, 6710, 36 236 bytes; Atossoft a screen and one 42 367-byte turbo block |
| zxart `(EN)[h2].tap`, `(EN)(128K).dsk` = ZXDB `Switchblade.dsk.zip` (+3), the TR-DOS hacks (TOSEC `[h Universe]`, `[h Fanatic S.]`, `[h Golden Disk]`, `[h Scorpion Soft '94]`, `[h Bil '94]`, `[h Auryn]`, `[h Himik, Phantom]`, `[h Grand Graphic]`, `[h Gold Graphic][tr ru]`, `[h Rapeware Corporation '95]`, `[h Action Group '95]`; zxart `[h 1994 Silicon Brains]`, `[h 1994 Golden Disk Corporation]`, `[h Gerasimov Brothers]`), the crack intros | disk conversions and hacks (index only) | not copied: conversions for other media; the +3 disk copied to `work/candidates/zxdb-entry/` and not compared |
| NVG `switchbl.zip` = TOSEC `(demo)...[Your Sinclair Covertape]` TZX; TOSEC demo TAP, Z80s; NVG `switchblade-demo.zip` | the Your Sinclair 63 demo | another program: a 24 964-byte block |
| NVG `switch_b.zip` (`SWITCH_B.Z80`) | a snapshot of the game | not compared |
| `rzxarchive/switchblade.rzx` | the RZX Archive run, "recorded by xmikex and Jamie Angus (with rollback)", SPIN 0.5, a 48K Z80 start snapshot, 142 989 frames | a witness of another player's complete game (the end text and the high-score entry "XMIKEX J"); its start snapshot is the game at the menu ([WALKTHROUGH 0.4](WALKTHROUGH.md#04-the-machine-48k-and-128k)) |
| `ay/` | Ben Daglish's three tunes as AY rips (ayplay.ru, zxart 44550-44552) | not compared yet |
| `pokes/`, `zxdb-entry/*.pok` | the POKE files (Hackers Anonymous, the Tipshop, ZXDB) | two of them fit this release: 38421 (`$9615`, the energy loss) and 38913 (`$9801`) are instruction starts; 41501 (`$A21D`), 41469 (`$A1FD`) and ZXDB's 38475 (`$964B`) are not, they belong to another release ([WALKTHROUGH 6.3](WALKTHROUGH.md#63-the-state-variables-and-the-pokes)) |

The original is the Gremlin tape: ZXDB marks download 31610 as the original, GBH's tape carries the same blocks, and
every other copy either re-saves these blocks (with headers, a patched loader, a cheat byte) or re-packs them.

## Sources and credits

- The game: Switchblade, Gremlin Graphics Software Ltd, 1991. Program Jeff Calder, graphics John Smyth, music Ben
  Daglish (ZXDB 5089); a conversion of Simon Phipps' Switchblade (Atari ST, Amiga, 1989).
- The tape: ZXDB download 31610 (`/pub/sinclair/games/s/Switchblade.tzx.zip`, "Created with Ramsoft MakeTZX"), the
  file in `orig/`.
- The RZX run: the RZX Archive's `switchblade.rzx`, "recorded by xmikex and Jamie Angus (with rollback)", SPIN 0.5,
  142 989 frames: another player's complete game, used, and said so, for the rooms no keyed play of ours reached, the
  end and the high-score entry ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)).
- The instructions: ZXDB 5089's text; the POKE files of Hackers Anonymous, the Tipshop and ZXDB
  ([WALKTHROUGH 6.3](WALKTHROUGH.md#63-the-state-variables-and-the-pokes)).
- The published maps: Spectrum Computing's screenshot maps (`/pub/sinclair/games-maps/s/Switchblade_2.gif`, "The Map
  by Sherwin", and `Switchblade_3.png`) show 126 of the 127 rooms in our grid places; room 122 is missing from both
  ([doc 1, 1.4](docs/01-game-design.md#14-the-127-rooms)).
- No earlier disassembly was found; every name is ours.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```sh
tools/mkasm_all.sh                  # the five .ann -> src/*/*.asm, each checked identical to the original's bytes
sh tools/build.sh $SJASMPLUS        # build/Switchblade.tzx, compared with orig/ byte for byte
python3 tools/res_formats.py check  # every editable resource back to its bytes
```

`tools/build.sh` prints `build: Switchblade.tzx identical to orig/Switchblade.tzx.zip's Switch Blade.tzx`
([doc 3, 3.6](docs/03-build-and-load.md#36-the-build)). The map of the 127 rooms is drawn from `src/res` by
`tools/fig_rooms.py` ([doc 2, 2.4](docs/02-architecture.md#24-the-map)).
