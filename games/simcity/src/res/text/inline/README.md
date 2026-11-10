# Inline texts

Strings with PrintInline `$5DEF` codes, each placed right after a `CALL PrintInline`, which prints the bytes after
its return address and returns past them. The syntax (tools/res_formats.py): `{at R C}` code `$FF`, `{attr $XX}`
`$FB`, `{box R C W H}` `$FD` (a frame), `{num N}` `$FC`, `{end}` `$FE`; line breaks are only for reading.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `StatusBar.txt` | StatusBarText `$5F16` | 42 | DrawStatusPanel `$5F13` | The menu bar SYSTEM OPTIONS DISASTERS WINDOWS |
| `On.txt` | OnText `$686E` | 3 | DrawMenuToggle `$684C` | ON after a toggle |
| `Off.txt` | OffText `$6879` | 4 | DrawMenuToggle (DrawMenuToggleOn `$6871`) | OFF after a toggle |
| `MapsFrame.txt` | MapsFrameText `$7AA4` | 101 | DrawMapsFrame `$7A9E` | The maps window's frame and legend |
| `MapsKeys.txt` | MapsKeysText `$7B0C` | 67 | DrawMapsKeys `$7B09` | The maps window's choices |
| `Searching.txt` | SearchingText `$9E77` | 18 | LoadCity `$9E5A` | SEARCHING |
| `Loading.txt` | LoadingText `$9EC1` | 11 | LoadHeader `$9E89` | LOADING |
| `Found.txt` | FoundText `$9F1D` | 13 | PrintFound `$9F1A` | FOUND and the name |

No leftovers.
