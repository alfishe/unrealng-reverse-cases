# Screens

| File | Address | Size | Shown by |
| --- | --- | --- | --- |
| `rex1.png`, `rex2.png`, `demo.png` | `$4000` | 6912 | the BASIC loaders' `LOAD "" SCREEN$` (src/screen/screen.ann) |
| `rex1-title.png` | REX 1 `$E4FF` (TitleScreen) | 6907 | TitleMenu `$DAC0`, copied to `$4000` |
| `rex2-title.png` | REX 2 `$E4FF` (TitleScreen) | 6907 | TitleMenu, the same bytes as REX 1's |

Format: a 256 x 192 PNG whose palette has 64 Spectrum entries, index = flash x 32 + ink x 16 + bright x 8 + colour.
A cell that is all ink or all paper keeps its attribute in the PNG text chunk `tx-cells` (`hidden`). The title screens
end where the tape ends, `$FFF9`: the last 5 attributes are not on the tape, `tx-cells` says `"length": 6907` and
the PNG shows them as zero (black). The loader screens differ little: REX 2's is REX 1's with 142 bytes changed, DEMO's
REX 2's with 97 (docs/03-build-and-load.md 3.1).
