# The effects

The 14 General Sound effect samples, one WAV each: 8-bit unsigned mono PCM, the WAV's `data` chunk is the file on
the media byte for byte (`tools/res_media.py` writes it; a pad byte after an odd-length chunk is not part of it).

**Rate.** The WAV header says 11 025 Hz, a nominal value: the GS ROM plays an effect at the pitch of its note (the
drivers set note 47 before every play, docs/09-sound.md 9.3), not at a rate stored with the sample. The playback rate
on the card was not measured; listen to the WAVs as approximations of the pitch.

**Effect numbers.** The card numbers effects in load order, 1-14; the WAV name gives the number and the file(s):

| WAV | File(s) | Bytes | Played for (game sound id, docs/09-sound.md 9.4) |
| --- | --- | --- | --- |
| `fx01-neart007.wav` | `neart007` | 14 798 | id 1, `$C8` (a robot started) |
| `fx02-neart008.wav` | `neart008` | 14 592 | id 2 (a robot destroyed), by the R register: never in practice (below) |
| `fx03-neart009.wav` | `neart009` | 23 296 | id 2 |
| `fx04-neart010.wav` | `neart010` | 19 456 | id 2 |
| `fx05-neart011.wav` | `neart011` | 26 880 | id 3 (the construction menu opens) |
| `fx06-neart012.wav` | `neart012` | 8 499 | id 4 (a shot fired) |
| `fx07-neart013.wav` | `neart013` | 15 427 | id 4 |
| `fx08-neart014.wav` | `neart014` | 19 187 | id 4, by the R register: never in practice (below) |
| `fx09-neart015.wav` | `neart015` | 9 056 | id `$78` (menu confirm) |
| `fx10-neart016.wav` | `neart016` | 176 | id `$14` (menu click) |
| `fx11-neart017.wav` | `neart017` | 401 | id `$64` |
| `fx12-neart018.wav` | `neart018` | 15 849 | id `$50` |
| `fx13-neart023.wav` | `neart023` | 12 560 | id `$0A` (a shot ends) |
| `fx14-neart019-020.wav` | `neart019` + `neart020` | 49 274 | id 9 (the nuclear blast) |

- **Effect 14** is one sample over two files: the build cuts it at 32 768 bytes (`neart019` = 32 768, `neart020`
  = 16 506); the loaders keep the card's stream open between them.
- **Effect 11** is `neart017` as Hood's tape loads it. The disk loader names `neart019` for effect 11, so on disk
  the card gets the first 401 bytes of `neart019` (the start of effect 14) and `neart017` is never read
  (`src/disk/loader.asm`). The WAV is the file the disk carries, `neart017`.
- **Never played**: the drivers pick among three effects for ids 2 and 4 by the top bits of the R register
  (`src/disk/driver.asm`, `RandomFxKill` / `RandomFxShot`). Nothing in the loader or the game writes R (no
  `LD R,A`), and the CPU's refresh counter never changes bit 7, so R is always `$00-$7F`: effects 2 and 8 (chosen
  for `$80-$FF`) are never played.
- The disk loader stores every effect as signed (each byte + `$80` on the card), Hood's tape loader effects 1-13 as
  unsigned and effect 14 as signed (docs/09-sound.md 9.2, 9.7); the files themselves are unsigned.

`python3 tools/res_media.py build --out build/res` writes `build/res/sfx/neartNNN.bin`.
