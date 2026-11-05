; --------------------------------------------------------------------------------------------------------------------
; gameentry.asm: The entry point the loader jumps to
;
; Three bytes in front of the variables: the 48K loader's jump target ($8000).
; --------------------------------------------------------------------------------------------------------------------

; JP MainLoop: the 48K's way in, past the start-up
;
; GS: JP MainLoop ($B200), where the 48K has JP Start ($B6FF): the image is the
; memory after the start-up, which must not run again (it would complement the
; sprite sets back). The installer's Mover does not come here either: it jumps
; to MainLoop itself. Nothing jumps here.
GameEntry:
  JP MainLoop
