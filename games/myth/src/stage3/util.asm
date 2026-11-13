; --------------------------------------------------------------------------------------------------------------------
; util.asm: Small helpers: keys, clears, copies, numbers, random numbers, delays
; --------------------------------------------------------------------------------------------------------------------

  ORG $7999

; Busy wait: count BC down to 0
;
; Input BC (the rounds, 26 T-states each). Output BC = 0, A = 0. The interrupt
; returns land on its three instructions (L1 lists them as entries).
;
; Stage 1's DelayBC at $79AB is the same code.
;
; Witness: L1 132000 (rzx-r3).
DelayBC:
  DEC BC
DelayBCTest:
  LD A,B
  OR C
DelayBCLoop:
  JR NZ,DelayBC
  RET

  ORG $88F5

; Is SPACE down?
;
; Calls KeyHook, then reads port $7FED bit 0: Z when SPACE is held. MainLoop
; ($7889) opens the item window on it; StageExit ($7A2C) and ItemWindow ($7C1D,
; $7C47, $7C4C) call it too.
;
; Stage 1's TestSpaceKey at $8A54 is the same code.
;
; Witness: L1 136488 (rzx-r3, s3-right).
TestSpaceKey:
  CALL KeyHook
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  RET

; Clear the screen's 768 attributes to 0
;
; Stage 1's ClearAttributes at $8A5F is the same code.
;
; Witness: L1 4 (rzx-r3, s3-right).
ClearAttributes:
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

; Clear the shadow attributes $6D00-$6FFF to 0
;
; Stage 1's ClearShadowAttributes at $8A6D is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
ClearShadowAttributes:
  LD HL,ShadowAttributes
  LD DE,ShadowAttributes+$0001
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

; Clear $5B00-$6C30 to 0 (LDIR)
;
; Clears 4401 bytes of the play buffer (the LDIR form; ClearBuffer $9A7D is the
; fast PUSH form of the whole 4608).
;
; Called at $9EBD and $9F13 before a room change.
;
; Stage 1's ClearPlayBuffer at $8A7B is the same code.
;
; Witness: L1 34 (rzx-r3, s3-right).
ClearPlayBuffer:
  LD HL,PlayBuffer
  LD DE,PlayBuffer+1
  LD BC,$1130
  LD (HL),$00
  LDIR
  RET

; Copy a block of the screen, one pixel line at a time, into a buffer
;
; HL = the buffer (lines packed one after the other), B = the screen column, C
; = the first pixel line, D = the width
;
; in bytes, E = the lines. Patches its ADD A,n at $893E with the column; the
; line addresses come from ScreenLineTable.
;
; Each line: EX DE,HL, LDIR, EX DE,HL, so the screen's bytes go to the buffer.
; EndStageSave ($7925) saves the
;
; HUD's 48 lines into $7000 with it.
;
; Stage 1's CopyScreenToBlock at $8A89 is the same code.
;
; Witness: L1 2 (rzx-r3, s3-right).
CopyScreenToBlock:
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

  ORG $89C5

; HL = A x B (the smaller one as the loop count)
;
; Returns HL = 0 when A is 0. Called by $ABB7.
;
; Stage 1's Multiply at $8B24 is the same code.
;
; Witness: L1 415 (rzx-r3).
Multiply:
  LD HL,$0000
  CP $00
  RET Z
  CP B
  JR C,MultiplySet
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

  ORG $8A17

; RandomSeed = RandomSeed x 5 + $15; A = it
;
; Called by LoadRoomActors ($A79F).
;
; Stage 1's NextSeed at $8B76 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
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
; Stage 1's Random at $8B85 is the same code.
;
; Witness: L1 10237 (rzx-r3, s3-right).
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
; Stage 1's ClearScreen at $8B92 is the same code.
;
; Witness: L1 4 (rzx-r3, s3-right).
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
; ItemIcons' kind 4 points here (DrawItemIcon $7E07 reads all 32 bytes);
; CopyToScreen $79BA copies its first bytes with stride 0 to clear the play
; area (StageEntry), the HUD fields (EndStage) and the item strip
; (GameOverStep); the templates' frame word ($9C76 and others) points here
; until SetActorFrame sets a frame.
;
; Stage 1's BlankIcon at $8BA3 (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
BlankIcon:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; IY = the screen address of pixel line C (no caller)
;
; IY = ScreenLineTable[C] (the word, not the address read). Nothing calls it: a
; leftover.
;
; Stage 1's LineAddressToIY at $8BC3 is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
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
; Stage 1's CellAddress at $8BCF is the same code.
;
; Witness: L1 269 (rzx-r3, s3-right).
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

  ORG $8AD6

; Wait BC interrupts (HALT each)
;
; Stage 1's WaitFrames at $8C35 is the same code.
;
; Witness: L1 400 (rzx-r3, s3-right).
WaitFrames:
  HALT
  DEC BC
  LD A,B
  OR C
  JP NZ,WaitFrames
  RET

  ORG $B37A

; A = 1, Z set: the "yes" exit of the tests
;
; Stage 1's ReturnZ at $B2DC is the same code.
;
; Witness: L1 360 (rzx-r3, s3-right).
ReturnZ:
  LD A,$01
  CP $01
  RET

; A = 1, Z clear: the "no" exit of the tests
;
; Stage 1's ReturnNZ at $B2E1 is the same code.
;
; Witness: L1 154 (rzx-r3).
ReturnNZ:
  LD A,$01
  CP $00
  RET
