; --------------------------------------------------------------------------------------------------------------------
; stc1head.asm: The Sound Tracker 1 compilation's head: entries, title, stop
;
; A compiled tune of Sound Tracker 1 ("SOUND TRACKER COMPILATION OF ... BY ...", name and author left blank here)
; starts with 11 bytes the compiler leaves (state the player does not read), then three entries: +11 init, +14 play
; one frame, +17 stop (silence the AY). The menu of zyxtvmbt calls +11 through its depacker's place: MusicInit `$C000`
; depacks, then the menu calls MusicPlay `$C00E` every frame.
; --------------------------------------------------------------------------------------------------------------------

; 11 bytes the compiler leaves before the entries (not read by the player)
CompileState:
  DEFB $0B,$00,$0E,$00,$7E,$80,$81,$80,$80,$10,$1F

; Init: JR to InitModule
MusicInit:
  JR $C059

; data_C00D
data_C00D:
  DEFB $00

; Play one frame: JR to PlayJump
MusicPlay:
  JR $C05F

; data_C010
data_C010:
  DEFB $00

; Silence the AY: JR to Stop
MusicStop:
  JR Stop

; data_C013
data_C013:
  DEFB $00

; "SOUND TRACKER COMPILATION OF            BY            ": the title and
; author fields left blank
Title:
  DEFM "SOUND TRACKER COMPILATION OF            BY             ",$7F

; Select AY register 12, write 0, then StopEnd writes 1-255 and closes the
; mixer
;
; Used by the routine at MusicStop.
Stop:
  LD BC,$FFFD
  LD A,$0C
  OUT (C),A
  XOR A
  LD B,$BF
  JP StopEnd
