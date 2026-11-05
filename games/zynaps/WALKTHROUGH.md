# Zynaps: walkthrough

How the reverse was done, step by step, and which unreal-ng call answered each question. Terms:
[docs/README.md](docs/README.md). Recipes: `../recipes/`. The commands in full: `work/stage1/NOTES.md`.

Every recording is named with its load (ROM speed or the fast LD-BYTES trap) beside every frame number.

## 0. The medium

Two media: the WoS perfect TZX (the reference) and a TAP. `tools/tzxblocks.py list` showed nine standard blocks
and an archive-info block naming the loader "Hewson Countdown II": no turbo, the protection must be in the code.
The TAP turned out to be a 1993 re-tape of the same bytes ([03](docs/03-build-and-load.md) 3.6).

## 1. One recording from power-on

`c1`: `re_session.py capture --record-load` on 48K, the TZX, 4000 frames after the load. The emulator's fast load
took the BASIC and the loader (ROM LD-BYTES) in 250 frames; the Hewson loader's blocks played at signal speed, so the
game starts at `c1` frame 12323. `re_session.py stages` gave the eight stages ([03](docs/03-build-and-load.md) 3.5),
`interrupts` the IM2 handler `$A9E4` of the title.

## 2. Static pass over the medium

- The BASIC (`tools/basic_list.py`): `CLEAR 32767`, the loader at `$FC00`, `USR 64512`.
- The loader: 19 plain bytes that XOR each byte with the next over `$FC13-$FE9E`. In Python:

  ```python
  b = bytearray(open('work/blocks/tzx4.bin', 'rb').read())
  for i in range(0x13, 0x29F):
      b[i] ^= b[i + 1]
  ```

  The plain code is the ROM's LD-BYTES with its edge routine hooked to drive a byte counter
  ([03](docs/03-build-and-load.md) 3.3).
- picy: a 9-byte header with three stream offsets; `tools/depack_picy.py` reproduces the screen.
- `sig_scan` over every block and image: nothing known (NOTES).

## 3. The stages and the packers

`tools/check_load.py` read `c1` at each stage's moment through the TTD session (`time_travel memory_at`) and
compared it with the static decode: zero differences except the counter digits on the screen. So
`work/images/static-entry.bin` is the game exactly as `$8000` is entered.

## 4. The medium from source

Not started.

## 5. Tool gaps found and fixed in unreal-ng

| Gap | Fix | unreal-ng commit |
| --- | --- | --- |
| none found in stage 1 | | |

## 6. The game

- The disassembly of `static-entry.bin` from `$8000` (`JP $B6FF`): the start-up, the main loop `$B200`, the
  print routines (which gave the messages table, `tools/texts.py`), the controls at `$8188`, the player records at
  `$7F9C`.
- `tools/drive.py` ran the menu by an input script (`work/explore/menu/menu.txt`) to `play-start.szx`.
- `tools/bot.py` (Kempston, reads the player object and the screen) played: honest, 275 points and a death in 1500
  frames, recorded as `c2` from its input script and replayed exactly.
- The TAP's POKEs pointed at the lives and the kill routine; next to the kill the collision check reads `$FFD7`,
  which nothing writes: a developer invulnerability switch. With it set the bot reached level 2; clearing it
  gave game over and the high-score entry ([02](docs/02-architecture.md) 2.5).

## 7. Review
