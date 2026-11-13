# Texts

The game's texts, one `.txt` file each. `tools/res_texts.py` (a format module of `tools/res_formats.py`) turns each
into the bytes the game source INCBINs and back; `tools/res_formats.py check` proves the round trip.

| File | Address | Bytes | Entry | Printed by | What |
| --- | --- | --- | --- | --- | --- |
| `SouthAmericaText.txt` | `$E4E5` | 279 | SouthAmericaText | PrintLines `$AAE9` (LevelIntro) | level 1's intro: South America, the Goolu tribe |
| `EgyptText.txt` | `$E5FC` | 270 | EgyptText | PrintLines | level 2's intro: Egypt, the jewel of Ankhel |
| `CastleText.txt` | `$E70A` | 260 | CastleText | PrintLines | level 3's intro: Schwarzendumpf castle |
| `MissileBaseText.txt` | `$E80E` | 235 | MissileBaseText | PrintLines | level 4's intro: the secret missile base |
| `LondonText.txt` | `$E8F9` | 258 | LondonText | PrintLines | the ending's text: London |
| `TitleText.txt` | `$E9FB` | 32 | TitleText | PrintLines (Menu `$E219`) | the menu's title |
| `ControlsText.txt` | `$EA1B` | 54 | ControlsText | PrintLines (Menu) | the four control choices |
| `CreditsText.txt` | `$EA51` | 61 | CreditsText | PrintLines (Menu) | PRESS FIRE TO START and the two copyright lines |
| `GameOverBlankText.txt` | `$E397` | 12 | GameOverBlankText | PrintText `$AA8D` (GameOver `$E35D`) | 11 spaces: the band above and below GAME OVER |
| `GameOverText.txt` | `$E3A3` | 12 | GameOverText | PrintText (GameOver) | " GAME OVER " |

## The format

A byte is a font glyph, code - `$37` (the font: `../graphics/README.md`): `$37-$40` the digits, `$41-$5A` the
letters, `$5E` a comma, `$5F` a full stop, `$60` a question mark; `$20` is a space. `$FF` ends a line (PrintText
returns; PrintLines goes on at the next text row), `$FE` ends PrintLines' text. In the file:

- digits, letters, space, comma, full stop and question mark are themselves (the credits' "C 8@?@" is "C 1989");
- `$FF` is a line break; `$FE` is `{end}` and a line break;
- any other byte is `{XX}` in hex (none of the ten texts has one).

The text is upper case only; a character the font has not is refused. No line break may follow `{end}` other than
its own (it would be one more `$FF`).
