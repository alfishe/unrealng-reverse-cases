# trd-boot-menu

**What it is.** The texts of the TRD's boot menu, "Work Loader v1.2" by TRON (1999): the title, the credit, two
status lines and the key help. The menu (`src/trd/boot/menu.asm`) lists the disk's BASIC files and RUNs the one
chosen.

**The file.** The TRD's file `boot`, inside its HRUM block: in the unpacked menu at `$6610-$6737` (296 bytes, ten
strings with no end marks: `DrawFrame` and `ShowSorting` print each through the ROM's PR-STRING with its length).
CP866 (the Russian DOS code page; the menu's own 64-column font draws those codes as Cyrillic). Build input:
[`src/res/text/trd-boot-menu.txt`](../../src/res/text/trd-boot-menu.txt), one string a line with its padding
before the `|`, encoded by `tools/trd_text.py` (`#codec cp866`) for `src/trd/boot/menu.asm`.

## The original

The strings in the order they are stored, with their addresses, lengths and where `DrawFrame` puts them (row,
column of the 64-column grid):

| Address | Length | Place | Text |
| --- | --- | --- | --- |
| `$6610` | 16 | 21, 5 | `Work Loader v1.2` |
| `$6620` | 22 | 22, 5 | `Prepared by TRON 1999` |
| `$6636` | 19 | 23, 5 | `Жди, читаю каталог!` |
| `$6649` | 20 | 23, 5 | `Сортировка каталога.` (replaces the line above) |
| `$665D` | 42 | 17, 5 | `                        '0...9'           ` |
| `$6687` | 42 | 18, 5 | `Cursor keys             'ENTER'           ` |
| `$66B1` | 42 | 19, 5 | `Q,A,O,P                 'SPACE'           ` |
| `$66DB` | 42 | 15, 5 | `Управление:             Старт программы:  ` |
| `$6705` | 21 | 13, 10 | `'EDIT' читать каталог` |
| `$671A` | 30 | 11, 17 | `'SS+CS' альтернативный каталог` |

The screen's lower part, rows 11-23 from column 5 (the empty rows left out):

```text
            'SS+CS' альтернативный каталог
     'EDIT' читать каталог
Управление:             Старт программы:
                        '0...9'
Cursor keys             'ENTER'
Q,A,O,P                 'SPACE'
Work Loader v1.2
Prepared by TRON 1999
Жди, читаю каталог!
```

## In English

```text
            'SS+CS' alternative catalogue
     'EDIT' read the catalogue
Control:                Program start:
                        '0...9'
Cursor keys             'ENTER'
Q,A,O,P                 'SPACE'
Work Loader v1.2
Prepared by TRON 1999
Wait, reading the catalogue!       (then: Sorting the catalogue.)
```
