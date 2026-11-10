# Resources

Every resource out of the code, in an editable format; `tools/res_formats.py build` turns them back into the bytes
the source INCBINs (tools/build.sh), `tools/res_formats.py check` proves the round trip (54 editable files, 0 bad).

| Folder | What |
| --- | --- |
| [graphics/](graphics/README.md) | The icon, cell and building tile sheets with their attributes, the pointer, the movers (PNG) |
| [tables/](tables/README.md) | 20 tables: terrain, tools, networks, cell flags, kernels, buildings, speeds, funding, categories (CSV) |
| [text/](text/README.md) | Month names and the game's 50 strings; [menus/](text/menus/README.md) 18 menu and window descriptions; [inline/](text/inline/README.md) 8 PrintInline texts (UTF-8 text) |
| [screen/](screen/README.md) | The loading screen (PNG) |

The font is the ROM's; the city map is made at run time from the seed, so neither is a resource. A city map from
the resources and a saved city: tools/fig_city.py.

Bytes no code reads stay in the source as named `b` entries (`...Spare`, `...Leftover`, `...Padding`), listed in
work/stage2/NOTES.md: in the game 14 (ScanSpare `$5BDE` ... InterruptSpare `$FCFF`, among them DivLeftover `$7657`
an older divide, TripLeftover `$85C4` dead code, ReadInputLeftover `$F798`), in the loader LoaderPadding `$FE14`
and LoaderFontLeftover `$FFA5` (91 bytes of the ROM font), in the mover MoverPadding `$500F`. The one table column
no code reads: SpeedTable's fourth (tables/README.md).
