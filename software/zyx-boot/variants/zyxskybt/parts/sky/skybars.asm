; --------------------------------------------------------------------------------------------------------------------
; skybars.asm: The waving bars
;
; Copied by SkySetup from $74A7 to $FE0D (after the menu's IM 2 jump at $FDFD); SkyFrame calls SkyBars once a frame.
; --------------------------------------------------------------------------------------------------------------------

; Shift each of the 24 pixel rows of the logo (BarRows, char rows 2-4) one
; pixel left or right, as BarDirections says
;
; BarPhase steps back one place a frame (mod 32); row n takes the direction at
; BarPhase + n (mod 32): 0 leaves the row, $FF shifts it right (the 18 bytes of
; columns 6-23), any other left (the 19 bytes of columns 7-25). The waves of 1s
; and $FFs in the table run down the logo as the phase turns. The two ADD A,n
; get the table's low byte first (self-modified, the same value they hold).
SkyBars:
  LD HL,BarRows
  LD DE,BarDirections
  LD A,E
  LD (SkyBarsBase+$0001),A
  LD (SkyBarsNextBase+$0001),A
  LD C,$18
  LD A,(BarPhase)
  DEC A
  AND $1F
  LD (BarPhase),A
SkyBarsBase:
  ADD A,$5E
  LD E,A
SkyBarsRow:
  PUSH HL
  LD A,(DE)
  OR A
  JR Z,SkyBarsNext
  INC A
  JR Z,l_FE3D
  LD A,L
  ADD A,$13
  LD L,A
  LD B,$13
l_FE36:
  RL (HL)
  DEC L
  DJNZ l_FE36
  JR SkyBarsNext
l_FE3D:
  LD B,$12
l_FE3F:
  RR (HL)
  INC L
  DJNZ l_FE3F
SkyBarsNext:
  LD A,E
  INC A
  AND $1F
SkyBarsNextBase:
  ADD A,$5E
  LD E,A
  POP HL
  INC H
  LD A,H
  AND $07
  JR NZ,l_FE5A
  LD A,H
  SUB $08
  LD H,A
  LD A,L
  ADD A,$20
  LD L,A
l_FE5A:
  DEC C
  JR NZ,SkyBarsRow
  RET

; 32 directions: 0 still, 1 left, $FF right
BarDirections:
  DEFB $00,$00,$00,$00,$FF,$00,$00,$FF,$00,$FF,$00,$00,$FF,$00,$00,$00
  DEFB $00,$00,$00,$00,$01,$00,$00,$01,$00,$01,$00,$00,$01,$00,$00,$00

; The table's start this frame (0-31)
BarPhase:
  DEFB $0C
