; --------------------------------------------------------------------------------------------------------------------
; sound.asm: The AY: silence and the bell
; --------------------------------------------------------------------------------------------------------------------

; Silence the AY: registers 0-13 from 30000, bytes of the work space nothing
; writes (zeros)
;
; 30000 is $7530, inside Unused1 $70A8 (cleared by the loader, never written),
; so every register gets 0: no tone, volume 0. Called by ShowCatalogue before
; every page, cutting the music for a moment.
;
; Witness: L1 9 (c1-c4).
SoundOff:
  LD HL,30000
  CALL WriteAY
  RET

; Write ExitSound to the AY registers 0-13: the bell when a file is chosen
;
; Witness: L1 2 (c2, c3).
PlayBell:
  LD HL,ExitSound
  CALL WriteAY
  RET

; Write 14 bytes from HL to the AY registers 0-13
;
; Witness: L1 11 (c1-c4).
WriteAY:
  XOR A
WriteAYNext:
  LD BC,$FFFD
  OUT (C),A
  PUSH AF
  LD A,(HL)
  LD BC,$BFFD
  OUT (C),A
  INC HL
  POP AF
  INC A
  CP $0E
  RET Z
  JR WriteAYNext

; The bell: AY registers 0-13
;
; Read by PlayBell.
ExitSound:
  INCBIN "res/tables/exit-sound.bin",$0000,14
