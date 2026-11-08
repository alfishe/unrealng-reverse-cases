# Texts

The readable texts that came with the game, set out as Markdown with notes on where the code agrees with them. They
are all in English, so there is no translation.

| Text | Source | What |
| --- | --- | --- |
| [instructions.md](instructions.md) | [`orig/Elite.txt`](../../orig/Elite.txt), the Spectrum Game Database's text | the controls (the box's Quick Key Control Guide), the story, the rating, the equipment, hints, docking, cheats, POKEs, the missions, trivia |
| [manual.md](manual.md) | ZXDB's `Elite(EN).pdf`, the "Space Traders Flight Training Manual" for the 48K Spectrum (scan, not committed) | the 64-page manual: the credits, loading, the cassette menu, navigation, combat, equipment, trading, the politics, the ship guide |
| [lenslok-instructions.md](lenslok-instructions.md) | ZXDB's `Elite_LenslokInstructions.pdf` (scans, not committed) | both printings of the Lenslok sheet |

The game's own texts (the token strings: the missions' messages, the planet descriptions, the screens) are in
[`src/res/text/tokens.txt`](../../src/res/text/tokens.txt). [08-hud-and-text.md](../08-hud-and-text.md) decodes them,
and `tools/tokens.py` prints them.
