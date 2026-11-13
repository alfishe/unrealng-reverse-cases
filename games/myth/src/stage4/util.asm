; --------------------------------------------------------------------------------------------------------------------
; util.asm: Small helpers: keys, clears, copies, numbers, random numbers, delays
; --------------------------------------------------------------------------------------------------------------------

  ORG $8F79

; Is SPACE down?
;
; Calls KeyHook, then reads port $7FFE bit 0: Z when SPACE is held. Callers:
; MainLoop $7873, StageExit $7A69, ItemWindow. As in stage 1 at `$8A54`.
;
; Witness: L1 124497 (rzx-r4, s4-right).
TestSpaceKey:
  CALL KeyHook
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  RET

; Clear the screen's 768 attributes to 0
;
; Called by ClearScreen.
;
; Witness: L1 4 (rzx-r4, s4-right).
ClearAttributes:
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

; Clear the shadow attributes $6D00-$6FFF to 0
;
; Called by StageSetUp $9718.
;
; Witness: L1 2 (rzx-r4, s4-right).
ClearShadowAttributes:
  LD HL,ShadowAttributes
  LD DE,ShadowAttributes+$0001
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

; Clear $5B00-$6C30 to 0 (LDIR)
;
; Clears 4401 bytes of the play buffer (the LDIR form; ClearBuffer $9A28 is the
; fast form). Callers: StartStageExit, $A140 and $A196.
;
; Witness: L1 43 (rzx-r4, s4-right).
ClearPlayBuffer:
  LD HL,PlayBuffer
  LD DE,PlayBuffer+1
  LD BC,$1130
  LD (HL),$00
  LDIR
  RET

; Copy a block of bytes to the screen, one pixel line at a time
;
; HL = the source (lines packed one after the other), B = the screen column, C
; = the first pixel line, D = the width in bytes, E = the lines. Patches its
; ADD A,n at $8FC2 with the column; the line addresses come from
; ScreenLineTable. EndStageSave $7911 copies the HUD's saved 48 lines back from
; $7000 with it.
;
; Witness: L1 2 (rzx-r4, s4-right).
CopyBlockToScreen:
  LD A,B
  LD (CopyBlockLine+$0005),A
  LD B,$00
  LD IX,ScreenLineTable
  ADD IX,BC
  ADD IX,BC
  LD B,E
  LD C,D
CopyBlockLine:
  PUSH BC
  LD A,(IX+$00)
  ADD A,$00
  LD E,A
  LD D,(IX+$01)
  INC IX
  INC IX
  LD B,$00
  EX DE,HL
  LDIR
  EX DE,HL
  POP BC
  DJNZ CopyBlockLine
  RET

  ORG $904B

; HL = A x B (the smaller one as the loop count)
;
; Returns HL = 0 when A is 0. Called by $AB6A.
;
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code ($AB6A).
Multiply:
  LD HL,$0000
  CP B
  JR C,MultiplySet
  CP $00
  RET Z
  LD C,B
  LD B,A
  LD A,C
MultiplySet:
  LD E,A
  LD D,$00
MultiplyLoop:
  ADD HL,DE
  DJNZ MultiplyLoop
  RET

  ORG $909D

; RandomSeed = RandomSeed x 5 + $15; A = it
;
; Called by the actor set-up $A72A.
;
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code ($A72A).
NextSeed:
  LD A,(RandomSeed)
  LD C,A
  SLA A
  SLA A
  ADD A,C
  ADD A,$15
  LD (RandomSeed),A
  RET

; A = the next ROM byte
;
; RandomPointer + 1, kept in $0000-$3FFF; A = the ROM byte there. The game's
; random numbers.
;
; Witness: L1 2804 (rzx-r4, s4-right).
Random:
  LD HL,(RandomPointer)
  INC HL
  LD A,H
  AND $3F
  LD H,A
  LD A,(HL)
  LD (RandomPointer),HL
  RET

; Clear the attributes, then the 6144 pixel bytes
;
; Callers: EndStageSave $7917, StageSetUp $9715.
;
; Witness: L1 4 (rzx-r4, s4-right).
ClearScreen:
  CALL ClearAttributes
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  RET

; 32 zero bytes: the blank icon (item kind 4) and the source of every clear
; done by copying with stride 0
;
; ItemIcons' kind 4 points here (DrawItemIcon reads all 32 bytes); GameOverStep
; $8425 copies its first bytes with stride 0 to clear the item strip; the
; templates' frame word ($9EE5 and others) points here until SetActorFrame sets
; a frame. Read in both recordings.
BlankIcon:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; IY = the screen address of pixel line C (no caller)
;
; IY = ScreenLineTable + 2C (the word's address, not the word read). Nothing
; calls it: a leftover.
;
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code.
LineAddressToIY:
  LD DE,ScreenLineTable
  LD L,C
  LD H,$00
  ADD HL,HL
  ADD HL,DE
  PUSH HL
  POP IY
  RET

; HL = DE + (C / 8) x 32 + B: the cell of pixel line C, column B in a 32-wide
; map
;
; DE = the map (Attributes or the shadow $6D00). Used by FillAttributes and
; FillShadowAttributes.
;
; Witness: L1 288 (rzx-r4, s4-right).
CellAddress:
  SRL C
  SRL C
  SRL C
  LD H,$00
  LD L,C
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD E,B
  LD D,$00
  ADD HL,DE
  RET

  ORG $915C

; Wait BC interrupts (HALT each)
;
; Callers: EndStageSave $791D (100), StageSetUp $972C and $9738 (50 each).
;
; Witness: L1 400 (rzx-r4, s4-right).
WaitFrames:
  HALT
  DEC BC
  LD A,B
  OR C
  JR NZ,WaitFrames
  RET

  ORG $B4A2

; A = 1, Z set: the "yes" exit of the tests
;
; As in stage 1 at `$B2DC`.
;
; Witness: L1 656 (rzx-r4, s4-right).
ReturnZ:
  LD A,$01
  CP $01
  RET

; A = 1, Z clear: the "no" exit of the tests
;
; As in stage 1 at `$B2E1`.
;
; Witness: L1 77 (rzx-r4).
ReturnNZ:
  LD A,$01
  CP $00
  RET
