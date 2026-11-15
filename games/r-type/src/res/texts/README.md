# Texts

The game's texts. PrintText `$C081` draws them double height, PrintTextNormal `$C084` as they are.

Format: UTF-8 text, one string a line (bit 7 of the last character ends a string in the game).

| File | Entry | Address | Bytes | What |
| --- | --- | --- | --- | --- |
| `pilot-stand-by.txt` | PilotStandByText (`src/game/game.ann`) | `$70AC` | 17 | "PILOT STAND BY $": printed after a life is lost |
| `mission-over.txt` | MissionOverText (`src/game/game.ann`) | `$70BD` | 14 | "MISSION OVER $": printed when the last life is gone |
| `continue.txt` | ContinueText (`src/game/game.ann`) | `$70CB` | 15 | "C O N T I N U E" over the countdown |
| `hi-score.txt` | HiScoreLabel (`src/game/game.ann`) | `$7180` | 8 | "HI SCORE" on the HUD |
| `beam.txt` | BeamLabel (`src/game/game.ann`) | `$7188` | 5 | "BEAM-" on the HUD |
| `loaded-ok.txt` | LoadedOkText (`src/game/game.ann`) | `$719E` | 9 | "LOADED OK" |
| `stop-tape.txt` | StopTapeText (`src/game/game.ann`) | `$71A7` | 9 | "STOP TAPE" |
| `start-tape.txt` | StartTapeText (`src/game/game.ann`) | `$71B0` | 10 | "START TAPE" |
| `loading.txt` | LoadingText (`src/game/game.ann`) | `$71BA` | 7 | "LOADING" |
| `rewind-side-2.txt` | RewindSide2Text (`src/game/game.ann`) | `$7280` | 32 | "REWIND SIDE 2 THEN PRESS ANY KEY" |
| `searching.txt` | SearchingText (`src/game/game.ann`) | `$72A0` | 14 | "SEARCHING FOR " (then LevelText) |
| `error-in-loading.txt` | ErrorInLoadingText (`src/game/game.ann`) | `$72AE` | 16 | "ERROR IN LOADING" |
| `press-fire.txt` | PressFireText (`src/game/game.ann`) | `$72CD` | 17 | "PRESS FIRE BUTTON" |
| `beam-meter-empty.txt` | BeamMeterEmpty (`src/game/game.ann`) | `$72DE` | 10 | ten '<': the empty BEAM meter |
| `title.txt` | TitleTexts (`src/game/game.ann`) | `$7480` | 99 | the title page's lines: BLAST OFF AND STRIKE / THE EVIL BYDO EMPIRE / PRESS FIRE TO PLAY / 'ENTER' SELECTS KEYS / (c) 1987 BY IREM CORP. |
| `enter-name.txt` | EnterNameText (`src/game/game.ann`) | `$74E3` | 23 | "ENTER YOUR NAME PILOT $" |
| `best-pilots.txt` | BestPilotsText (`src/game/game.ann`) | `$7580` | 19 | "TODAY'S BEST PILOTS" |
| `rewind-tape.txt` | RewindTapeText (`src/game/game.ann`) | `$76F5` | 11 | "REWIND TAPE" |
| `hiscores.txt` | HiScoreTable (`src/game/game.ann`) | `$7CD8` | 153 | Nine entries of 17 bytes: name (10), score (6 ASCII digits), $A0 (bit 7 ends the text) |
| `scroller.txt` | ScrollerText (`src/game/game.ann`) | `$81A9` | 466 | "STOP THE TAPE $" and the credits: R TYPE, PROGRAMMED BY BOB PAPE, GRAPHICS, SOUND, IREM 1987, ELECTRIC DREAMS 1988 |
| `paused.txt` | PausedText (`src/game/game.ann`) | `$C49A` | 12 | "GAME  PAUSED" |
