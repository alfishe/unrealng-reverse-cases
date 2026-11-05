# Sound effects

The six beeper effects of play as text. `tools/res_effects.py` turns `effects.fx.txt` into the bytes the source
INCBINs (`effects/effects.bin`, `$7E5A-$7E89`, 48 bytes) and back; `tools/res_formats.py check` proves both ways.

| File | Address | Size | Format | Reader |
| --- | --- | --- | --- | --- |
| `effects.fx.txt` | `$7E5A-$7E89` | 48 | 6 effects of 8 bytes, one line an effect | EffectPlay `$B30C`, requested by RequestEffect `$B2F0` |

## The format

```
effect 1 pitchA=$80 stepA=-2 pitchB=$01 stepB=+1 change=+0 segments=3 flags=%10000111 lenA=3 lenB=0
```

- `pitchA`, `pitchB`: the two pitches the tone loop starts from (a half period in counts of 25 T).
- `stepA`, `stepB`: what each frame adds to them (signed); `change`: what a segment's end adds to the steps.
- `segments`: how many segments the effect lasts; `lenA`, `lenB`: the frames of the two kinds of segment.
- `flags`: bit 7 two tones, bit 6 the pitches restart each segment, bit 5 SegLenA shortens, bits 4/3 step B/A
  reverse, bits 0-2 which pitch a one-tone segment plays by the segment count's parity.

The effect number is its priority: RequestEffect takes a request only when it is not below the effect playing, and
0 stops the sound. The users: 1 the enemy shot (`$A1C2`), 2 the laser (`$9C75`), 3 the plasma bounce, 4 a pod
appears (`$A31B`), 5 the next weapon (`$A224`), 6 a weapon on (`$A21D`). See docs/09-sound.md.
