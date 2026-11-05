# Music

The title tune as text. `tools/res_tune.py` turns `titletune.tune.txt` into the bytes the source INCBINs
(`music/titletune.bin`, `$FF01-$FFD3`, 211 bytes) and back; `tools/res_formats.py check` proves both ways, and
`python3 tools/res_tune.py check FILE.bin` does it for one file of bytes.

| File | Address | Size | Format | Reader |
| --- | --- | --- | --- | --- |
| `titletune.tune.txt` | `$FF01-$FFD3` | 211 | 27 periods, 7 pattern pointers, 4 patterns (below) | TitleTune `$B446`, from CreditsPage `$B095` |

## The format

```
periods 0 242 231 ...     TunePeriods $FF01: the period of note n, in passes of the tone loop
order A A B A C C D       TuneOrder $FF1C: the patterns in play order (7 pointers)
pattern A                 a pattern: L<n> sets the note length, a number plays that note
  L1 7 6
  L2 4
end                       the pattern's $FF
```

The patterns are laid out in the text's order right after the order table, so a pattern may grow or shrink; the
code reads exactly 27 periods and 7 order entries. Lines from `#` on are comments; the header and the table of note
frequencies are written again on every install.

## How the player sounds it

TitleTune (`$B446`) runs with the interrupts off. A length command `$C0+n` (`L<n>`) sets the note to n x 16 x 256
passes of the tone loop (`$B486-$B49B`, 81 T a pass, so `L1` is 0.095 s on a 48K). A note byte n takes p =
TunePeriods[n] and runs two counters, p and p + 1 passes; each counter's wrap flips the speaker bit (both at once flip
it once). The speaker is the XOR of two square waves a pass apart: a pulse train at 3500000 / (81 x p) Hz, two
pulses per counter period, whose width grows a pass a period (a slow beat); the beeper capture confirms the pitch
([09](../../../docs/09-sound.md) 9.3). Note 1 (p = 242) is about 179 Hz, note 26 (p = 54) about 800 Hz; the periods
fall by about a semitone a step. Between notes the player checks fire (TitleFireCheck `$A748`) and the keys 1-5;
either ends the tune.

The four patterns: A (three times) the theme, B the climbing arpeggios, C (twice) an ostinato of 16 quavers, D the
closing phrase. Notes 3, 5, 8, 15, 22, 24 and 26 are never played (none of the four patterns holds them).
