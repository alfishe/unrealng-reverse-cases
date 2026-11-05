; --------------------------------------------------------------------------------------------------------------------
; gameentry.asm: The entry point the loader jumps to
;
; Three bytes in front of the variables: the loader's jump target ($8000) goes on to Start.
; --------------------------------------------------------------------------------------------------------------------

; JP Start: the loader's way in
;
; c1: entered once by the loader's relocation code at $5B00 (frame 12323), a
; tail jump to Start ($B6FF). Nothing else jumps here.
GameEntry:
  JP Start
