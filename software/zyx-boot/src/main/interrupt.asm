; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The IM 2 interrupt: the music, the clocks, the twinkle, the glint, the cursor, the name's spin, the keys
;
; Interrupt $6757 runs at every frame through Im2Jump $FCFC. It saves every register, puts back HL' and IY for the
; ROM, plays the music (CALL $C00E, src/music), adds 1 to Frames $5C78 and 2 to TwinkleClock $DEAC, draws the twinkle
; (TwinkleStar $6BA5) and the logo's glint (LogoGlint $6D04). Every 4th frame it paints the cursor. When Frames' low
; byte is 50, 60, 70 or 80 (in every 256 frames, 5.12 s) the cursor's name is turned by 90 degrees, so it spins once;
; at 90 the screen gets the name as it stands. Every 8th frame ReadKeyboard $6864 reads the keys.
; --------------------------------------------------------------------------------------------------------------------

  ORG $6757

; The IM 2 handler
;
; Witness: L1 13932 (c1-c4).
Interrupt:
  PUSH IY
  PUSH IX
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  EXX
  PUSH HL
  PUSH DE
  PUSH BC
  LD HL,(SavedHLAlt)
  EXX
  EX AF,AF'
  PUSH AF
  LD IY,(SavedIY)
  CALL MusicPlay
  LD HL,(Frames)
  INC HL
  LD (Frames),HL
  LD A,(TwinkleClock)
  ADD A,$02
  LD (TwinkleClock),A
  CALL TwinkleStar
  CALL LogoGlint
  LD A,(Frames)
  AND $03
  CP $03
  JR NZ,CheckSpin
  CALL CursorAttrAddr
  LD DE,(CursorLength)
  LD B,E
PaintCursor:
  LD (HL),D
  INC HL
  DJNZ PaintCursor
  BIT 6,D
  SET 6,D
  JR Z,StoreCursorAttr
  RES 6,D
  INC D
  BIT 3,D
  JR Z,StoreCursorAttr
  INC D
  INC D
  RES 3,D
StoreCursorAttr:
  LD A,D
  LD (CursorAttr),A
CheckSpin:
  LD A,(Frames)            ; Frames low byte 50: spin the cursor's name
  CP $32
  JR NZ,CheckSpinMore
  LD HL,(CursorRow)
  LD (RotateRow),HL
  LD A,(CursorLength)
  LD (RotateLength),A

; Turn each character of the cursor's name by 90 degrees in ScreenCopy
;
; RotateAddr $DEAE = the name's address in ScreenCopy (from CursorAttrAddr's
; offset); each character's 8 rows to CharBuffer $B3ED, then written back
; column by column. At Frames 90 the LD A at $67D8 is made a RET for one call:
; only the address is worked out.
;
; Witness: L1 276 (c1-c4).
RotateCursorName:
  LD HL,RotateRow
  LD (CursorAttrAddr+$0002),HL
  CALL CursorAttrAddr
  LD HL,(CursorAttrOffset)
  LD A,H
  RLCA
  RLCA
  RLCA
  OR ScreenCopy>>8
  LD H,A
  LD (RotateAddr),HL
SpinCharacters:
  LD A,(RotateLength)            ; LD A,(RotateLength): a RET at Frames 90
  LD B,A
RotateNextChar:
  PUSH BC                 ; the next character
  PUSH HL
  LD DE,CharBuffer
  PUSH DE
  LD B,$08
RotateCopyRow:
  LD A,(HL)
  LD (DE),A
  INC H
  INC DE
  DJNZ RotateCopyRow
  POP HL
  POP DE
  PUSH DE
  LD B,$08
RotateColumn:
  LD C,$08
  PUSH HL
RotateColumnShift:
  RL (HL)
  RRA
  INC HL
  DEC C
  JR NZ,RotateColumnShift
  LD (DE),A
  INC D
  POP HL
  DJNZ RotateColumn
  POP HL
  INC HL
  POP BC
  DJNZ RotateNextChar

; Copy the name from ScreenCopy to the screen (CopyNameToScreen) and leave
;
; Witness: L1 276 (c1-c4).
ShowRotatedName:
  LD HL,CursorRow
  LD (CursorAttrAddr+$0002),HL
  CALL CopyNameToScreen
  JR InterruptExit
; This entry point is used by the routine at Interrupt.
CheckSpinMore:
  CP $3C
  JR Z,RotateCursorName
  CP $46
  JR Z,RotateCursorName
  CP $50
  JR Z,RotateCursorName
  CP $5A
  JR NZ,InterruptExit
  LD A,$C9
  LD (SpinCharacters),A
  CALL RotateCursorName
  LD A,$3A
  LD (SpinCharacters),A
  JR ShowRotatedName

; Every 8th frame read the keys; restore the registers, EI, RET
;
; Witness: L1 13931 (c1-c4).
InterruptExit:
  LD A,(Frames)
  AND $07
  CP $07
  CALL Z,ReadKeyboard
  EXX
  POP AF
  EX AF,AF'
  POP BC
  POP DE
  POP HL
  EXX
  POP AF
  POP BC
  POP DE
  POP HL
  POP IX
  POP IY
  EI
  RET

  ORG $6CA2

; Copy the 8 rows of the rotated name from ScreenCopy to the screen
;
; Witness: L1 276 (c1-c4).
CopyNameToScreen:
  LD HL,(RotateAddr)
  LD A,H
  AND $FF^(ScreenCopy>>8^$40)
  LD D,A
  LD E,L
  LD B,$08
CopyNameRow:
  PUSH BC
  LD A,(RotateLength)
  LD C,A
  LD B,$00
  PUSH HL
  PUSH DE
  LDIR
  POP DE
  POP HL
  INC H
  INC D
  POP BC
  DJNZ CopyNameRow
  RET
