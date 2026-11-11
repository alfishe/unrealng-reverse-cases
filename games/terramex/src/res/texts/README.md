# Texts

Every text as UTF-8, one quoted string a line in the order of the bytes: printable ASCII as is, `©` for the
Spectrum's `$7F`, `\"` and `\\` escaped, any other byte as `\xNN` (control codes: `\x0D` new line, `\x16` AT row
column, `\x10` INK, `\x11` PAPER, `\x12` FLASH, `\x00`/`\x0D`/`\xFF` the end marks named per file). A line ends after
a `\x0D` or an end mark; a long line is split only where a byte was. The header comment of each file names its entry.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `menu.txt` | MenuText `$9540` (game) | 57 | PrintMenuText `$94EF` | the device menu: 1 KEYBOARD, 2 KEMPSTON, 3 SINCLAIR, 0 START GAME; `$00` ends |
| `credits.txt` | CreditsText `$9579` (game) | 132 | PrintString `$94F9`, called by DeviceMenu at `$943D` (row 17, column 2, attribute `$47`) | the five credit lines under the menu, rows 17-21 (Teque, Argus Press, 1987) |
| `collision.txt` | CollisionText `$B07C` (game) | 58 | TelescopeView `$A7B9` | the telescope view: TIME REMAINING TO COLLISION, DAYS HOURS MINUTES; the countdown is printed into the gaps |
| `stop-tape.txt` | StopTapeText `$C2B8` (selector) | 48 | ShowStopTape `$C295` | the 48K's STOP THE TAPE / THEN PRESS SPACE KEY, ROM print codes, RST `$10` up to `$0D` |
| `start-tape.txt` | StartTapeText `$C2E8` (selector) | 44 | CopySet48K `$C175` (CopySetLdir) | the 48K's EXPLORER SELECTED / START TAPE |
| `help-48k.txt` | Help48KText `$C5F9` (selector) | 271 | ShowHelp `$C536` | Help on a 48K: choose now, then restart the tape |
| `help-title.txt` | HelpTitle `$C708` (selector) | 25 | HelpPagesLoop `$C550` | the title card TERRAMEX INSTRUCTIONS, then `$01` (a pause) |
| `help-page1.txt` - `help-page3.txt` | HelpPage1 `$C721`, HelpPage2 `$C97F`, HelpPage3 `$CB7D` (selector) | 606, 510, 530 | PrintPage `$C574` | the three instruction pages; PrintPage codes `$16 c r` (AT), `$0D`, `$01` (pause), `$00` (wait for SPACE or ENTER) |
| `break-message.txt` | BreakMessage `$5DB7` (the BASIC loader, src/tape) | 34 | LoaderEntry `$5D08` | "User pressed break-reload!", printed when a block fails to load; `$FF` ends |

The spelling of the original is kept ("asteriod", "professorAlbert" across a line end: the pages are 32 columns wide
and the text relies on the wrap).
