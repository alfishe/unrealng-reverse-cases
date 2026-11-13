; --------------------------------------------------------------------------------------------------------------------
; util.asm: Small helpers: keys, clears, copies, numbers, random numbers, delays
; --------------------------------------------------------------------------------------------------------------------

  ORG $8A79

; Is SPACE down?
;
; Calls KeyHook, then reads port $7FFE bit 0: Z when SPACE is held. The main
; loop ($7873) opens the item window on it.
;
; As in stage 1 at $8A54, the same code.
;
; Witness: L1 123859 (rzx-r2, s2-right, stageload).
TestSpaceKey:
  CALL KeyHook
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  RET

; Clear the screen's 768 attributes to 0
;
; Called by ClearScreen ($8BB9).
;
; As in stage 1 at $8A5F, the same code.
;
; Witness: L1 5 (rzx-r2, s2-right, stageload).
ClearAttributes:
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

; Clear the shadow attributes $6D00-$6FFF to 0
;
; Called by StageSetUp ($917A).
;
; As in stage 1 at $8A6D, the same code.
;
; Witness: L1 3 (rzx-r2, s2-right, stageload).
ClearShadowAttributes:
  LD HL,ShadowAttributes
  LD DE,ShadowAttributes+$0001
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

; Clear $5B00-$6C30 to 0 (LDIR)
;
; Clears 4401 bytes of the play buffer (the LDIR form; ClearBuffer $9484 is the
; fast PUSH form of the whole 4608).
;
; Called by ShiftRoomColumns ($9966) and ShiftRoomRows ($99BC) before a room
; change.
;
; As in stage 1 at $8A7B, the same code.
;
; Witness: L1 34 (rzx-r2, s2-right, stageload).
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
; in bytes, E = the lines. Patches its ADD A,n at $8AC2 with the column; the
; line addresses come from ScreenLineTable.
;
; Each line: EX DE,HL, LDIR, EX DE,HL, so the screen's bytes go to the buffer.
; EndStageSave ($7916) saves the
;
; HUD's 48 lines into $7000 with it.
;
; As in stage 1 at $8A89, the same code.
;
; Witness: L1 2 (rzx-r2, s2-right).
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

  ORG $8B4B

; HL = A x B (the smaller one as the loop count)
;
; Returns HL = 0 when A is 0. Called by $9FCA, $A0BB and $AB9F: 4929 calls in
; rzx-r2 (frames 1205-17465), none in s2-right.
;
; As in stage 1 at $8B24.
;
; Witness: L1 4929 (rzx-r2).
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

  ORG $8B9D

; RandomSeed = RandomSeed x 5 + $15; A = it
;
; Called by WaterActor ($8789) and LoadRoomActors ($A507).
;
; As in stage 1 at $8B76, the same code.
;
; Witness: L1 5970 (rzx-r2, s2-right, stageload).
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
; As in stage 1 at $8B85, the same code.
;
; Witness: L1 5591 (rzx-r2, s2-right, stageload).
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
; Called by EndStageSave ($791C), StageSetUp ($9177).
;
; As in stage 1 at $8B92, the same code.
;
; Witness: L1 5 (rzx-r2, s2-right, stageload).
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
; Read through GameOverStep ($8577) and, as item kind 4's icon, through
; ItemIcons $7F00 (DrawItemIcon). As in stage 1 at $8BA3. All 32 bytes read in
; s2-right and rzx-r2.
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
; As in stage 1 at $8BC3, the same code.
;
; Not executed in any recording (the recordings checked: s2-right, rzx-r2);
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
; As in stage 1 at $8BCF, the same code.
;
; Witness: L1 629 (rzx-r2, s2-right, stageload).
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

  ORG $8C5C

; Wait BC interrupts (HALT each)
;
; Called by StageSetUp ($918E, $919A) and EndStageSave ($7922, 100 frames).
;
; As in stage 1 at $8C35.
;
; Witness: L1 500 (rzx-r2, s2-right, stageload).
WaitFrames:
  HALT
  DEC BC
  LD A,B
  OR C
  JR NZ,WaitFrames
  RET
