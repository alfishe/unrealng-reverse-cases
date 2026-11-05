; --------------------------------------------------------------------------------------------------------------------
; starkos-song.asm: the song SK10
;
; The intro tune, a STarKos song compiled for $8990 (its header holds the address; the player does not relocate it).
; 1845 bytes: the header, the transposition, height and special-track streams, the linker (48 patterns), the
; instrument table and 13 instruments, 38 tracks and one special track. The text src/res/music/sk10.txt holds it in
; STarKos's terms; tools/sk10.py encode builds build/sound/sk10.bin from it for the INCBIN.
; --------------------------------------------------------------------------------------------------------------------

; the song SK10 (src/res/music/sk10.txt)
;
; Read by Init (the header) and Play (the streams, the tracks, the
; instruments). Not written.
Song:
  INCBIN "build/sound/sk10.bin",$0000,1845
