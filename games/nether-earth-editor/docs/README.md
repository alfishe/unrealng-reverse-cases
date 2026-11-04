# Nether Earth Editor: the documents

The numbering follows the case standard ([GUIDE](../../../GUIDE.md)); the editor has no game loop, rendering engine,
objects or sound of its own, so documents 4, 6, 7 and 9 are absent, and its code is small enough that its
reference is the commented source (`src/mix/mix.asm`, `src/basic/*.bas`).

| Doc | Contents |
| --- | --- |
| [1. Game design](01-game-design.md) | the levels as a player meets them: the maps, the bases, the resources, what makes each different |
| [2. Architecture](02-architecture.md) | the editor: its stages, memory map, the address mapping to the game, the module map, time |
| [3. Build and load](03-build-and-load.md) | the tape block by block, the edition's loader and trampoline, the image against Nether Earth's, the saved-game format, the build |
| [5. Controls](05-controls.md) | the editor's menu, map editing, buildings, resources, hidden keys and quirks |
| [8. HUD and text](08-hud-and-text.md) | how it prints, the font and tiles, the screens, every string |
| [10. Gameplay logic](10-gameplay-logic.md) | what the save format means for the rules: what it carries, the checksum, out-of-play capture points, the clock |

The game itself is documented in [Nether Earth's documents](../../nether-earth/docs/README.md); names like `Map`,
`Robots`, `Warbases` are its names.
