# Screen

| File | What | Size | Built into |
| --- | --- | --- | --- |
| `loading.png` | The loading screen: Zynaps's tape loading screen, byte for byte the 48K case's `loading.scr` | 6912 | Trush block 0 (`src/disk/screen/screen-block.asm` INCBINs `screen/loading.scr`) |

A 256 x 192 indexed PNG; its text chunk `zx-hidden` keeps the 6912 bytes, so `tools/disk_media.py build` gives the
screen back exactly (`build/res/screen/loading.scr`). The boot shows it with a fade (Trush block 0's code), the
loader shows bank 7's copy while a module loads, and the title stub shows it between the title pages
([3](../../../docs/03-build-and-load.md)).
