# The boot program's resources (the boot menu and the help, `$6060-$F6D4`)

`tools/build_bootmenu.sh` turns each file back into the bytes `src/bootmenu/*.asm` INCBIN (`tools/bootmenu_res.py`
has the formats; `python3 tools/bootmenu_res.py check` encodes them all). `tools/bootmenu_mkasm.py --install` writes
them from the image.

| File | Bytes | Label | What |
| --- | --- | --- | --- |
| `pictures/description.png` | `$62DE`, 1510 | DescriptionPicture | help item 1 "Описание игры" |
| `pictures/electronics.png` | `$69B6`, 1083 | ElectronicsPicture | item 3, page 1 |
| `pictures/phasers.png` | `$6DF2`, 886 | PhasersPicture | item 3, page 3 |
| `pictures/missiles.png` | `$7169`, 865 | MissilesPicture | item 3, page 4 |
| `pictures/antigrav.png` | `$74CB`, 1011 | AntigravPicture | item 3, page 6 |
| `pictures/tracks.png` | `$78BF`, 933 | TracksPicture | item 3, page 7 |
| `pictures/bipods.png` | `$7C65`, 965 | BipodsPicture | item 3, page 8 |
| `pictures/help-menu.png` | `$802B`, 3144 | HelpMenuPicture | the help menu (its bars empty: HelpMenu prints the names) |
| `pictures/features.png` | `$8C74`, 985 | FeaturesPicture | item 5 "Особенности игры" |
| `pictures/credits.png` | `$904E`, 971 | CreditsPicture | item 6 "CREDITZ" |
| `pictures/cannons.png` | `$941A`, 951 | CannonsPicture | item 3, page 5 |
| `pictures/production.png` | `$97D2`, 965 | ProductionPicture | item 2 "Производство роботов" |
| `pictures/programming.png` | `$9B98`, 1451 | ProgrammingPicture | item 4 "Программирование роботов" |
| `pictures/bomb.png` | `$A144`, 797 | BombPicture | item 3, page 2 |
| `pictures/boot-menu.png` | `$A462`, 1542 | BootMenuPicture | the boot menu |
| `sprites/pointer.png` | `$AD6F`, 32 | PointerSprite | the help menu's arrow: 16 lines of mask and image |
| `fonts/latin.png` | `$B19D`, 768 | FontLatin | the printer's Latin font, 96 glyphs of 4 x 8 |
| `fonts/cyrillic.png` | `$B49D`, 768 | FontCyrillic | its Cyrillic font (the same codes) |
| `text/menu.txt` | `$B7CD`, 172 | MenuDescription ... MenuCopyright | the seven item names and the copyright line |
| `text/credits.txt` | `$B879` | CreditsPage1-3 | item 6, 3 pages |
| `text/description.txt` | `$C124` | DescriptionPage1-5 | item 1, 5 pages |
| `text/production.txt` | `$CE96` | ProductionPage1-4 | item 2, 4 pages |
| `text/components.txt` | `$D807` | ElectronicsPage ... BipodsPage | item 3, 8 pages |
| `text/programming.txt` | `$E204` | ProgrammingPage1-3 | item 4, 3 pages |
| `text/features.txt` | `$EA29` | FeaturesPage1-5 | item 5, 5 pages, to `$F6D4` |

Pictures are whole screens as indexed PNG (the colour of each pixel carries its cell's ink or paper, bright, flash;
a cell keeps one ink and one paper); the build packs them with Hrust 1 as the authors' packer did, so an unchanged
PNG gives the original stream. A picture or a text of another length moves everything after it: the labels follow.
