# Text

UTF-8, one quoted string a line (tools/res_formats.py): printable ASCII as itself, `©` the ROM font's `$7F`,
`\xNN` any other byte.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `Messages.txt` | `$63D2-$65AD` | 476 | QueueMessage `$6ACD` (the priority), the scroller in Interrupt `$95D0` (the text) | The ten messages: a priority, then rows of 19 characters (the scroller's window), the last ending in `.` |
| `MenuTexts.txt` | `$8D38-$8D95` | 94 | Menu `$8854` (PrintText `$8AB4`) | TUJAD, 1 KEYBOARD, 2 CURSOR JOYSTICK, 3 KEMPSTON JOYSTICK, 0 START GAME, each ending in `.`; then the copyright line `$8D85` (`©` 1986 ORPHEUS LTD), read by no code: a leftover |
| `ProgressText.txt` | `$9072-$9092` | 33 | ProgressScreen `$8F53`, ProgressPercent `$9046` (the digits at + 19, + 20) | YOU HAVE COMPLETED nn% OF TUJAD. and the percentage byte `$9092` (BCD) |
