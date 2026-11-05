; --------------------------------------------------------------------------------------------------------------------
; gameentry.asm: The entry point the set-up jumps to
;
; Three bytes in front of the variables: the set-up's jump target ($8000, JP GameStart at $610B in block 2) goes on to
; Start.
; --------------------------------------------------------------------------------------------------------------------

; JP Start: the set-up's way in
;
; Entered once by block 2's set-up after the move (JP GameStart at $610B; c1
; frame 3313), a tail jump to Start ($B6FF). Nothing else jumps here. In the
; 48K the tape loader's relocation code jumped here.
GameEntry:
  JP Start
