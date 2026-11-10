# Leftover

The authors' assembler source as their editor stored it (tokenised lines: [length][label][length][mnemonic]
[length][operands] and 3 zero bytes), left in the image where the game later keeps variables and buffers. No code
reads these bytes before writing them (L1; NewGame `$7A2F` and PlaceDroid `$7A6D` write the droid's variables,
DrawRoom `$6B22` the room's, NewGame zeroes `$65E5-$668B`). One stored line a line: label TAB mnemonic TAB operands;
`cut "..."` keeps the bytes of a line cut off at either end. Format: tools/res_formats.py.

| File | Address | Bytes | What |
| --- | --- | ---: | --- |
| `Source1.txt` | `$6359-$637F` | 39 | Under DroidVars: `inc de`, `ld hl,(pos)` |
| `Source2.txt` | `$639C-$63D1` | 54 | Under RoomVars: `ld bc,7`, `scf`, `ccf`, `sbc hl,bc` |
| `Source3.txt` | `$65E5-$6887` | 675 | Under ExhaustRows, BlankGraphic, EdFlags, DroidSave, EnemyBufferPtrs and EnemyBuffers: the end of a routine that calls `draw`, then `lookup` (the game's RoomRecord `$7B8F`: `alnmap` + `alnmap`[2 x c]) and `scram` (the game's ScrambleRooms `$7BA0`: rooms 0-123, the items whose kind has bit 6 clear passed one room on) |
