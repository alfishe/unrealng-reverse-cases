# src/res/pictures99: the intro screen of the '99 pictures block

The pictures block (`src/pictures99/pictures.asm`, `$7D87-$8A86`, sectors 19-31 of `NEZSEd99.B`) is a self-locating
RLE decoder followed by one packed screen. `tools/front99_res.py build` packs the PNG with the encoder rule below
into `res/pictures99/intro-screen.rle`, which `src/pictures99/pictures/picture.asm` INCBINs.

| File | Bytes it stands for | Size | Format | Who reads it |
| --- | --- | ---: | --- | --- |
| `intro-screen.png` | `PackedScreen` `$7DFA-$8A35` | 3 132 packed (6 912 unpacked) | 256 x 192 PNG, ZX palette, one ink / paper pair per 8 x 8 cell, FLASH and BRIGHT in a text chunk | `DecodeScreen` `$7D87`, called by stage 2 with the target `$8A87` (`PictureBuffer`); `RollInPicture` `$62DB` then rolls it onto the screen |
| `leftover-8a36.bin` | `SectorSlack` `$8A36-$8A86` | 81 | raw bytes | nobody: RLE bytes of another picture left in memory when the block was saved |

## The RLE format and the encoder

- The stream is the pixels in column-major screen order (each of the 32 columns: three thirds, eight character rows,
  eight pixel lines), then the 768 attributes in order.
- `$9A V N` is N copies of V; any other byte is itself.
- The encoder (`rle_pack`): a run of 3 or more equal bytes, or any `$9A` byte, becomes `$9A V N` with N at most 255;
  shorter runs stay literal. Re-packing the unpacked screen gives the original 3 132 bytes exactly. The longest run
  in this screen is 153, so the 255 cap is the decoder's limit, not a witnessed encoder choice.
- `tools/front99_res.py check` also compares the unpacked screen with the buffer `$8A87` in the r99 dumps
  (`work/stage2/front99/dumps/`, frames 473-2178): 0 bytes differ.
