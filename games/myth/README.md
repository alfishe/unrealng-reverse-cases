# Myth: History in the Making (System 3 Software, 1989)

State: complete 2026-11-13 (two review rounds, kit gaps fixed, every case regressed identical). 12 documents, 77 figures (PNG), 35 animations (GIF), 56 mermaid
diagrams and 13 audio files (3 MP3, 10 short WAV; 328 KB), counted on 2026-11-13 with:

```sh
ls docs/[0-9][0-9]-*.md | wc -l; find docs/img -name '*.png' | wc -l; find docs/img -name '*.gif' | wc -l
cat docs/[0-9][0-9]-*.md | grep -c '^```mermaid'
find docs/audio -name '*.mp3' | wc -l; find docs/audio -name '*.wav' | wc -l; du -sh docs/audio
```

| | |
| --- | --- |
| Machine | 48K and 128K from one tape. The game runs in the 48K memory only: in the RZX run's 128K snapshots (`work/stage1/rzx/snap0-5.z80`) RAM 1, 3, 4 and 6 are empty and RAM 7 holds 198 bytes. What the 128K adds is the AY: the sound effects are played by the IM 2 handler through ports `$FFFD` / `$BFFD` (AyFrame `$F78A`, three channels at `$F85E`); on a 48K those writes go nowhere and the game is silent (no `OUT ($FE)` runs in the play of c1, [WALKTHROUGH 1](WALKTHROUGH.md#1-one-recording-from-power-on)). This case runs the 48K for the load (c1) and the 128K for the stage recordings |
| Profile (AGENTS.md 4.0) | a flip-screen action adventure across five ages for one player ([doc 1](docs/01-game-design.md)): the hero walks, jumps, crouches, strikes high, middle and low, and throws or fires the selected item through rooms of one stage at a time; a multiload, one 33 792-byte block a stage loaded over `$6C3F-$F03E` and told apart by StageCheck (Stage 1 The Road To Hell, 2 Greece 400 BC, 3 Scandinavia 500 AD, 4 Egypt 3000 BC, 5 Duel With Dameron; [doc 3](docs/03-build-and-load.md)); per stage five teleport icons to strike and take, then the master icon on the teleport pad ends the stage ([doc 10, 10.9](docs/10-gameplay-logic.md#109-the-icons-the-master-icon-and-the-teleport)); bosses: stage 1 the demon of room 12 (woken by the tenth object thrown into its pit, beaten by ten hits) and the dragon of the arena, stage 2 the hydra and Medusa, stage 3 the dragon and the giant on the throne, stage 4 the pharaoh's head, stage 5 Dameron's four forms and an ending that never exits ([doc 10, 10.10](docs/10-gameplay-logic.md#1010-stages-2-5-and-the-ending)); a HUD with score, an energy bar (46 units), five lives in six boxes, carried items and teleport icons ([doc 8](docs/08-hud-and-text.md)); the main loop `$7839` never waits for the frame in stages 1-4 (about 3 frames a pass, an 18-frame room change; stage 5 waits with a HALT; [doc 4](docs/04-game-loop.md)); scenery drawn once, actors into a play buffer copied through open spans ([doc 6](docs/06-rendering.md)); IM 2 (table `$FD00-$FE00` of `$FE`, `JP $F9B3` at `$FEFE`); sound: 13 AY effects, no music and no beeper, unheard on a 48K ([doc 9](docs/09-sound.md)); controls: Q W I J O, ENTER pause, SPACE the item window, CAPS SHIFT + SPACE quits, redefinable keys, Kempston, cursor or Sinclair joystick ([doc 5](docs/05-controls.md)); a Speedlock 7 loader (a 55-byte BASIC line with a hidden 59, a 103-layer decryption chain keyed on R, the turbo loader TurboLoad `$FE90-$FF53` with LoadBlock `$FF54`, the countdown drawn by the loader) |
| Authors | ZXDB 3354: Neil Dodwell, Dave Dew (Concept Animations). The game's own credits (c1 frames 7938-8310, [credits](docs/img/play/credits.png)): "Programmed by Neil Dodwell", "Graphics by Concept Animations", "Produced by System Three", "Original game design Mark Cale", "Sound effects by Neil Dodwell" |
| Release | ZXDB 3354 "Myth: History in the Making", ZX Spectrum 48K/128K, Arcade Game: Adventure: System 3 Software Ltd 1989 (£9.99), re-released by Kixx (1989, £3.99) and MCM Software S.A. (Spain); in the compilations "System 3 Pack", "Tips Amazing" and "ZX-Spectrum Vega" |
| Original | `orig/Myth-HistoryInTheMaking.tzx.zip` (ZXDB download 20803, "Original release (O)"; md5 `b9c25a45bfb57f14ff4dd78fd6f28ba3`, SHA-1 `f17ea8d1948dd6a9e5d979a876d201cbe33b4350`): `Myth - History In The Making.tzx` (201 203 bytes, md5 `24a8219180c25a0f864cc49d6a7036ab`, SHA-1 `7bdfbeeea03db0c4a6d908f14f9ba6b63e2d30d7`, SHA-256 `358dbb9fa142883b5d2908fbd7b7eeab785eb8894daa3df1eeb8133fc27bff4a`; TZX archive info "Speedlock 7", "Original", "TZXed by Andrew Barker"), 53 TZX blocks, 815.9 s with the pauses |

## Other releases and copies

Every copy found was copied unchanged into `work/candidates/<source>/` (ZXDB, the local World of Spectrum mirror,
NVG, the RZX archive, TOSEC, consoles-zx, vtrd, zxart and its later delta, the NAS collection; the POKE files).
`tools/copy_compare.py` compared every TAP and TZX, also inside zips, block by block with the original
(`work/stage1/copy-compare.tsv`; [WALKTHROUGH 0](WALKTHROUGH.md#0-the-medium)). The main block and the five stage
blocks are not enciphered on the tape, so every copy that carries the game carries them; only the loaders differ.

| Copy | What it is | How it differs from the original |
| --- | --- | --- |
| TOSEC `[SpeedLock 7] - 31177.tzx`, zxart `(EN)(128K).tzx`, NAS `Myth - History in the Making (Europe).tzx`, the WoS mirror's `Myth - History In The Making.tzx` | the same dump | identical file (md5 `24a82191...`) |
| ZXDB `Myth-HistoryInTheMaking(Kixx).tzx.zip` = TOSEC `(Kixx)[SpeedLock 7][re-release] - 31167.tzx` = zxart `[a 1989 Kixx]` | the Kixx re-release | every data block byte for byte; other pauses and pilot lengths, a "Ramsoft MakeTZX" text block |
| TOSEC `[a] - 31175.tzx` | another dump of the original | every data block byte for byte; other pauses and pilot lengths |
| TOSEC `- 31171.tzx` = NVG `speedlock4-myth.zip` | another dump | the same data, the Speedlock blocks encoded as one "SpeedLock 4" group with other pulse lengths, without the separate `$E8` / `$07` pieces |
| ZXDB `Myth-HistoryInTheMaking(MCMSoftwareS.A.).tzx.zip`, Side 1 and 2 (= TOSEC 31168, 31169, zxart Tape 1 / Tape 2) | the MCM Software (Spain) re-release on two sides | Side 2 holds the main block and the five stage blocks byte for byte; Side 1 has its own loader (6914 and 4098-byte blocks holding runs of the original's) |
| ZXDB `Myth-HistoryInTheMaking.tap.zip`: `MYTH.TAP` = TOSEC `- 31170.tap` = TOSEC `[h Raf] - 31164.tap` = zxart `(EN)(128K).tap` | a deprotected re-save | its own BASIC and 120, 4477 and 5404-byte loader blocks; the main block and the stage blocks byte for byte |
| TOSEC `[a] - 31174.tap` | the TAP re-save | the stage 1 block differs in 12 bytes |
| TOSEC `[a2] - 31173.tap`, `[h] - 31176.tzx` | the TAP re-save | the blocks byte for byte; trailing empty blocks |
| TOSEC `(Rainbird)(+3)[t Pokes] - 31165.tap` | a trainer | the game blocks byte for byte, its own loader |
| TOSEC `(Rainbird)(+3)[h Alexey Sorokin] - 31160.tap` (zxart the same) | a hack | its own loader; only three stage blocks. consoles-zx `MYTH_ALEXEY_SOROKIN.tap` has all five, the last differing in 277 bytes |
| TOSEC `[h Prospekt][tr ru] - 31163.tap` = consoles-zx `MYTH_RUSSIAN_VERSION.tap`; TOSEC `[tr ru] - 31166.tap` = zxart `(EN)[h].tap` | Russian translations | the main block differs in 1058-1068 bytes (the texts), stage 5 in 277 bytes; 31166 holds one stage block twice |
| TOSEC `[h Djs] - 31162.tap` | a hack | its own loader; stage 5 differs in 277 bytes |
| TOSEC `[h Atossoft] - 31161.tzx`, zxart `[h Atossoft].tap` | a hack | re-packed blocks holding runs of the main block |
| consoles-zx `MYTH_LESHIJ.tzx` | a hack | 740 small blocks with its own loader; not compared further |
| vtrd (17 SCL / TRD zips, two translations), zxart-delta `MYTH_TR4.trd`, `K128_Myth.kdi`, `K48_Myth.kdi`, MCM `.dsk` | disk conversions | not compared block by block (disk images) |
| NVG `slt-myth.zip`, `special-hacks-myth.zip`, `myth-ts2068-jlo.zip`; TOSEC `- 31172.z80`; NAS `Part 1 - Options.z80`, `Part 2.z80`, `Part 3.z80` | snapshots and conversions (a TS2068 port) | not the tape |
| RZX archive `myth.rzx` (SPIN 0.5, 128K, 100 151 frames in six segments, each a Z80 snapshot) | someone else's run through the five stages to the end | used, said so, to reach the later stages ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)) |
| ZXDB `.pok`, tipshop `.pok`, hackersanon `11949 Myth.pok` | POKEs: credits `62045,0` (`$F25D`), lives `65121` (`$FE61`), infinite lives `33611,0` (`$834B`), "go to stage N" at `31093-31219` | the hackersanon file is filed under ZXDB 11949, Rainbird's +3 text adventure "Myth" (Magnetic Scrolls); its POKEs belong to this game. TOSEC's "Myth (1989)(Rainbird)(+3)" tapes are likewise System 3's game |

## Sources and credits

- The game: Myth: History in the Making, System 3 Software Ltd, 1989 (ZXDB 3354). Program and sound effects Neil
  Dodwell, graphics Dave Dew (Concept Animations), original game design Mark Cale, as the game's own credits and ZXDB
  name them.
- The tape: ZXDB download 20803 ("Original release (O)", TZXed by Andrew Barker), the file in `orig/`.
- The RZX run: the RZX Archive's `myth.rzx`, recorded by xmikex with Rollback, SPIN 0.5, 128K, 100 151 frames:
  another player's complete game, used, and said so, for the stages, bosses and ending no keyed play of ours reached
  ([WALKTHROUGH 6.0](WALKTHROUGH.md#60-the-recordings)).
- The instructions: ZXDB 3354's text (`work/candidates/docs/Myth-HistoryInTheMaking.txt`, md5
  `695a060e8758699db56658eecbf2fe92`: the C64 text with the Spectrum keys), the maps; the POKE files of ZXDB, the
  Tipshop and Hackers Anonymous.
- No Spectrum disassembly of the game was found (a GitHub search; `vs-sr-dev/cd32-myth-doc` is about the Amiga CD32
  version) and no AY rip; every name is ours.

The documents: [docs/README.md](docs/README.md). How the reverse was done: [WALKTHROUGH.md](WALKTHROUGH.md).

## Build

```sh
. work/env.sh                       # SJASMPLUS, SKOOLKIT_VENV
tools/mkasm_all.sh                  # every .ann -> src/*/*.asm, each checked identical to the original's bytes
sh tools/build.sh $SJASMPLUS        # build/Myth.tzx, compared with orig/ byte for byte
python3 tools/res_formats.py check  # every editable resource back to its bytes
python3 ../../kit/refdocs.py --case .   # docs 11 and 12 from the annotations
```

`tools/build.sh` prints `build: Myth.tzx identical to orig/Myth-HistoryInTheMaking.tzx.zip's Myth - History In The
Making.tzx` ([doc 3](docs/03-build-and-load.md)); `res_formats.py check` reports 273 editable files, 0 bad.
