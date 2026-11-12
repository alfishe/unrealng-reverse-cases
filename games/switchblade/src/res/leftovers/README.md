# Leftovers

Bytes of the game image that no code reads, kept as bytes. All are zeros.

| File | Address | Bytes | What |
| --- | --- | ---: | --- |
| `control-gap.bin` | ControlGap `$6B4D-$6B5B` | 15 | between the control menu (the end of block 5's start code) and the page-tail template |
| `leftover-72fe.bin` | Leftover72FE `$72FE-$72FF` | 2 | between RoomPatch `$72DE` and the room tables of page `$73` |
| `spare-73f9.bin` | Spare73F9 `$73F9-$73FF` | 7 | after ActorKindHandlers, before StructureRecords `$7400` |
| `room-data-pad.bin` | RoomDataPad `$D0F9-$D103` | 11 | after the last room, before Tiles `$D104` |
| `panel-end.bin` | PanelEnd `$FFFF` | 1 | the byte after the panel code, outside the bootstrap's copy |
