# Menus and windows

Menu descriptions as DrawMenu `$67C3` reads them, one item a line (the syntax is in each file's header and in
tools/res_formats.py): `header N`, then `text`, `number` (a selectable line with a field), `action ADDR` (the
routine a click runs), `toggle FLAG` (ON / OFF after it), `separator`, `end`. In the text `{tab}` is code `$21`,
`{byte F V M}` code 7 (a field: flag, value, maximum; the value the player edits lives in the text itself),
`{word ...}` code 6 and `{long ...}` code 5.

These files are the source the build assembles: `tools/res_formats.py build` writes each as
`build/res/text/menus/NAME.inc` (DB lines, a `DW` for each address, kit/resinc.py) and the game INCLUDEs it
(`@res text/menus/NAME.bin include` in game.ann). `ADDR` and `FLAG` are the game's labels (`action SpeedFast`,
`toggle AutoBulldoze`), so sjasmplus puts in their addresses: a routine that moves is followed, and a text that grows
moves the code after it. An address no label names stays a number (`action $6703`, inside MenuInput). The labels
the code uses inside a menu are written here too: `label NAME` before an item, `{=SpeedMarkFast}` before a letter,
`{byte 1 TaxRate=7 20}` on a field's value byte; the build fails when a name is no label.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `Budget.txt` | BudgetWindowText `$91BC` | 338 | BudgetWindow (`LD IX,BudgetWindowText` at `$91A5`) | FISCAL BUDGET: tax income, the tax rate field (TaxRate `$91E4`: 7, maximum 20), the three requests with their percentage fields (`$9256`, `$926F`, `$9288`: 100), the cash lines, GO WITH THESE FIGURES |
| `Evaluation.txt` | EvaluationText `$95D7` | 352 | EvaluationWindow `$95B8` | The poll, the worst problems, population, migration, value, category, level, score |
| `Plant.txt` | PlantMenu `$9F41` | 125 | PowerPlantTool `$74B4` | NUCLEAR (5000), COAL (3000), NONE |
| `Confirm.txt` | ConfirmMenu `$9FD3` | 84 | Confirm `$9FD0` (inline after `CALL ShowInlineWindow`) | ARE YOU SURE ?: NO THANKS, YES PLEASE |
| `System.txt` | SystemMenu `$A02B` | 134 | OpenMenuAt `$640E` | ABOUT SIM CITY, START NEW CITY, USE OLD LANDSCAPE, LOAD CITY, SAVE CITY, EXIT SIMCITY |
| `About.txt` | AboutText `$A0CA` | 297 | AboutWindow `$A0C7` (inline) | The credits |
| `Load.txt` | LoadMenuText `$A1F6` | 81 | LoadMenu `$A1F3` (inline) | LOAD CITY |
| `Save.txt` | SaveMenuText `$A24A` | 80 | SaveMenu `$A247` (inline) | SAVE CITY |
| `FileName.txt` | FileNameText `$A29D` | 63 | FileNameWindow `$A29A` (inline) | The file name prompt |
| `LoadError.txt` | LoadErrorText `$A2DF` | 31 | LoadErrorWindow `$A2DC` (inline) | TAPE LOADING ERROR |
| `Tape.txt` | TapeText `$A30C` | 31 | TapeWindow `$A309` (inline) | START TAPE AND PRESS SPACE |
| `Options.txt` | OptionsMenu `$A32F` | 124 | OpenMenuAt `$640E` | AUTO BULLDOZE, AUTO BUDGET, SOUND, ZONE DEMOLISH WAIT (toggles `$A32B-$A32E`) and SIMULATION SPEED |
| `Speed.txt` | SpeedMenuText `$A3AF` | 94 | SpeedMenu `$A3AC` (inline) | FAST, NORMAL, SLOW, PAUSED |
| `Disasters.txt` | DisasterMenu `$A43E` | 124 | OpenMenuAt `$640E` | The six disasters and DISABLE ALL |
| `Windows.txt` | WindowsMenu `$A4C2` | 79 | OpenMenuAt `$640E` | MAPS, BUDGET, EVALUATION |
| `Level.txt` | LevelMenuText `$A51C` | 141 | UiTask `$8FA0` | SELECT DIFFICULTY LEVEL: EASY, MEDIUM, DIFFICULT, INPUT NEW CITY NAME |
| `OldLandscape.txt` | OldLandscapeMenu `$A5E5` | 141 | SetLevel `$A5A9` (inline) | USE OLD LANDSCAPE: the current gene (the seed, a `{word}` field the code fills), INPUT NEW GENE, START CITY WITH THIS GENE |
| `Creating.txt` | CreatingText `$A6A4` | 52 | NewLandscape `$6A8E` | CREATING LANDSCAPE, PLEASE WAIT |

No leftovers: each description is read up to its `end`.
