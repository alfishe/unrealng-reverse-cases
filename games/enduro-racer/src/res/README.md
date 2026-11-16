# Resources

Every resource out of the code, in an editable format. `tools/res_formats.py build` turns them back into the bytes
the sources INCBIN (tools/build.sh runs it), `tools/res_formats.py check` proves the round trip (0 bad), and
`kit/mkgame.py --install` writes them from the image. Each folder's README gives its files, their entries and format.

| Folder | What | Format |
| --- | --- | --- |
| `font/` | the 8x8 font (`Font` `$7608`), the big digits (`BigDigits` `$7C54`) | PNG |
| `horizons/` | the three horizon pictures (`$E2C0`, `$E5E0`, `$E9E0`) | PNG |
| `screens/` | the loading screen (tape block 6) | SCREEN$ (`loading.png` a view) |
| `sound/` | the AY note periods and the two tunes | CSV, text |
| `sprites/` | every sprite the descriptors name (`$6BE8-$75AF`, `$B306-$E2BF`) | PNG sheet + CSV layout |
| `tables/` | the game's tables (controls, scores, perspective, edges, bends, crests, objects, riders, stages) | CSV, PNG for the countdown glyphs |
| `texts/` | the menu, credits, HUD, lap table, name grid, key names, EXTENDED PLAY, DEMO | UTF-8 text |
| `track/` | the five stages, the track's patterns, a drawing of each course | text, PNG views |
