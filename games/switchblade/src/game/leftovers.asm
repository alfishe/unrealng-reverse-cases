; --------------------------------------------------------------------------------------------------------------------
; leftovers.asm: Bytes no code reads
; --------------------------------------------------------------------------------------------------------------------

  ORG $72FE

; Two zero bytes between the code at $72DE and the room tables, read by no
; recording
;
; No keyed recording reads or writes $72FE-$72FF (work/stage1 L1 profiles).
Leftover72FE:
  INCBIN "res/leftovers/leftover-72fe.bin",$0000,2

  ORG $D0F9

; Eleven zero bytes after the last room
;
; Between room 127 (ends `$D0F8`) and the tile set `$D104`. No recording reads
; them (the rooms recording reads the room records only through the room table
; `$7100`).
RoomDataPad:
  INCBIN "res/leftovers/room-data-pad.bin",$0000,11
