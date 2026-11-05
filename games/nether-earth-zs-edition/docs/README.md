# Nether Earth ZS Edition: the documents

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | both releases as a player meets them: the start-up, the intros, the '98 menu, the '99 start-up menu, the difficulty levels and the upgrades (what each level patches), the maps and LOAD MAP, play, what NE lacks, the authors' claims against the code (1.10) |
| [2. Architecture](02-architecture.md) | what the edition is, the machine, the memory maps of both releases, the stages from the disk to play, the third-party pieces |
| [3. Build and load](03-build-and-load.md) | the two SCLs, the '98 load, the '99 three-stage load and its 128K / one-page routes, the '99 backward LZ packer (bit-exact), the map files and LOAD MAP, the machines (Pentagon, Scorpion, 48K + Beta) and the ROM, the source build |
| [5. Controls](05-controls.md) | every key of the intros, the menus, REDEFINE, the text pages, LOAD MAP and play; no mouse |
| [6. Rendering](06-rendering.md) | every screen of both releases as recorded, side by side with Nether Earth where it has one |
| [8. HUD and text](08-hud-and-text.md) | the long texts and their encodings, the fonts, the panel and the end messages |

What is not here: the game's world, robots, AI and drawing are Nether Earth's, documented in the
[nether-earth case](../../nether-earth/docs/README.md); the annotated source of each part (`src/*/`) describes every
routine, including ZS's changes.

## Texts

The long texts of both releases as readable Markdown, the Russian original and a full English translation
([texts/README.md](texts/README.md)):

| Text | What |
| --- | --- |
| [NEabout.W](texts/NEabout.md) | about the edition (ZS, 29.01.1999) |
| [NEdescri.W](texts/NEdescri.md) | the description, the author's notes, a bug warning |
| [NEgreets.W](texts/NEgreets.md) | greetings |
| [NEadvice.W](texts/NEadvice.md) | "Advices of Expert" (Timofey Anisimov) |
| [NEZSEd99.W](texts/NEZSEd99.md) | the '99 readme |
| [the '98 scroller](texts/scroller98.md) | the '98 intro: greeting, story, the '98 changes |
| [the '99 scroller](texts/scroller99.md) | the '99 intro: keys, greeting, machines, story |

## Recordings

| Name | What |
| --- | --- |
| `r98`, `r99` | stage 1, from power-on on Pentagon 128 + TR-DOS (`work/stage1/`); `r98` frame = script + 1603, `r99` = script (+2) |
| `r99-48` | stage 1, the '99 from 48 BASIC with paging locked (`USR 15616`): the one-page route and the reset |
| `x98`, `x99` | the texts agent's tours of every screen (`work/stage2/texts/`) |
| `s98`, `s99`, `e98s`, `e99s` | both releases on the Scorpion ZS-256 model (`work/stage2/scorpion/`) |
| `play`, `deep`, `key5menu` | the '98 game: play, 9 game days, LOAD NEW LEVEL (`work/stage2/game98/`) |
| `r99-play`, `crit-play`, `loadmap-menu` | the '99 game: HARD + PHASERS, CRITICAL over several days, LOAD MAP (`work/stage2/game99/`) |
| `m99`, `r48-*` | the start-up menu over every item; the 48K paths (`work/stage2/menu99/`) |
| `ne-play` | Nether Earth's own recording, for the comparisons |

## Terms

- **'98**, **'99**: the two releases, `NEZSED98.SCL` (one BASIC monoblock) and `NEZSED.SCL` (packed blocks, texts,
  maps).
- **NE**: Nether Earth (Argus Press Software, 1987), the game both releases patch; its reverse is the
  nether-earth case. **ANE**: Advanced Nether Earth (Eternity Industry, 1998), another remake.
- **ZS**: Sergey Zotov, the author of both releases.
- **Block**: a '99 self-extracting packed block: 22 bytes of set-up, the depacker copied to `$5B00`, the backward LZ
  stream (3.4).
- **Slack**: the bytes of a file's last sector after its length; no program reads them.
- **Map**, **`NELEV`**: a 512-byte `N` file of the '99 disk: four record lists and a 13-byte tail (3.5).
- **Page**: a 16K bank of the 128K at `$C000` (`$7FFD`); the one-page route is the '99's path when paging fails.
- **The level table**: the five game places the '99 start-up menu writes for EASY .. CRITICAL (1.6).
