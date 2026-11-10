; --------------------------------------------------------------------------------------------------------------------
; system.asm: Printing glyphs, the input read, the tape, the UI stack and the IM 2 vector
;
; PrintGlyph with the print state, ReadInput (keys and joysticks every interrupt), TapeLoad, TapeSave, TapePause, the
; UI task's stack, InterruptJump $FCFC and the vector table $FD00.
; --------------------------------------------------------------------------------------------------------------------

; The print state: the character, the screen address, the column and row, the
; attribute
PrintCharCode:
  DEFB $41
PrintAddr:
  DEFB $00
  DEFB $40
PrintCol:
  DEFB $00
PrintRow:
  DEFB $00
PrintAttr:
  DEFB $38

; Character A from the ROM font, made bold (byte OR byte >> 1), at PrintAddr,
; with PrintAttr unless $FF
;
; L1 496 214.
PrintGlyph:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,RomFont
  ADD HL,BC
  EX DE,HL
  LD HL,(PrintAddr)
  LD B,$08
PrintGlyphLine:
  LD A,(DE)
  LD C,A
  SRL C
  OR C
  LD (HL),A
  INC DE
  INC H
  DJNZ PrintGlyphLine
; This entry point is used by the routine at DrawIconHere.
PrintGlyphAttr:
  LD A,(PrintAttr)
  CP $FF
  RET Z
; This entry point is used by the routines at DrawIcon and DrawCell.
PutAttr:
  LD C,A
  DEC H
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD (HL),C
  RET

; Read the eight half rows into KeyRows, then the Kempston and Sinclair
; joysticks into them
;
; L1 413 183.
ReadInput:
  LD HL,KeyRows
  LD BC,$FEFE
  LD D,$08
ReadInputRow:
  IN A,(C)
  LD (HL),A
  INC L
  RLC B
  DEC D
  JR NZ,ReadInputRow
  CALL ReadKempston
  JP ReadSinclair

; Leftover: RET, JP $FE0F, JP $FE0F (no code runs them)
ReadInputLeftover:
  DEFB $C9,$C3,$0F,$FE,$C3,$0F,$FE

; LD-BYTES through the ROM (border $0F): IX, DE, A flag, carry set
;
; Used by the routines at LoadHeader and LoadMap.
TapeLoad:
  INC D
  EX AF,AF'
  DEC D
  LD A,$0F
  OUT ($FE),A
  CALL RomLdBytesIn
  RET

; SA-BYTES through the ROM
;
; Used by the routine at SaveCity.
TapeSave:
  JP RomSaBytesOut

; B x 5000 loops
;
; Used by the routine at SaveCity.
TapePause:
  PUSH BC
  LD BC,$1388
TapePauseLoop:
  DEC BC
  LD A,B
  OR C
  JP NZ,TapePauseLoop
  POP BC
  DJNZ TapePause
  RET

; The UI task's stack, filled with $E5
UiStack:
  DEFS $0541,$E5

; JP Interrupt: the IM 2 vector $FCFC
InterruptJump:
  JP Interrupt

; InterruptSpare
InterruptSpare:
  DEFB $E5
VectorTable:
  DEFB $FC                ; 257 bytes $FC: with I = $FD any vector reads $FCFC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
  DEFB $FC
