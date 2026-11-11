# Screens

A screen is a 256 x 192 colour PNG of the 6912 bytes: the palette holds the 64 Spectrum attribute colours (index =
flash x 32 + ink x 16 + bright x 8 + colour) and grey, so each pixel says whether it is ink or paper and the bytes come
back exactly. The attribute of a cell that is all paper (or all ink) cannot be seen: the PNG text chunk `tx-cells`
keeps it. A screen third (panel.png) is 256 x 64, the same way (the chunk says `thirds` 1).

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `loading.png` | `$4000-$5AFF` (TZX block 3) | 6912 | the loader's first LD-BYTES (src/tape/basic.ann) | LoadingScreen (src/screen/screen.ann): the loading screen, on screen through the load of blocks 4 and 5 |
| `selector.png` | SelectorPicture `$CF0F` (selector, RAM 1) | 6912 | DrawSelectorPicture `$C1C9`, RestoreRowLoop (the cursor's background) | the explorer selector: the five portraits and names, Help |
| `panel.png` | BackBuffer `$E000-$E7FF` (pixels, a screen third) and SavedPanelAttrs `$E800-$E8FF` (game) | 2048 + 256 | InitGame `$8F69` (to `$5000`/`$5A00`), DeviceMenu `$93AF` and MenuFrameSides `$93F5` (the menu's frame), EndGame `$906D` (saves it back) | the status panel, the screen's bottom third, as the tape holds it; in play these bytes are the back buffer |
