; --------------------------------------------------------------------------------------------------------------------
; util.asm: Small helpers
;
; Stage 5's own helper in this range; the shared ones (clears, copies, random numbers, delays) are at $93BE-$9663.
;
; Most of these recur byte for byte from stage 1 (tools/stage_names.py) and keep stage 1's names. Stage 1's actor
; records and missile list ($74E0, HeroShots $75E0) are not used by stage 5's duel: their routines (SpawnActor to
; UpdateMissiles) have no caller in stage 5's code.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7FBE

; HL = the attribute address of pixel line A, pixel column C: $5800 + (A AND
; $F8) x 4 + C / 8
;
; Inputs A (a pixel line) and C (an X in pixels); output HL; B = 0, C
; destroyed.
;
; No caller in stage 5's code: no CALL, JP or pointer to $7FBE in list-all.txt.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
AttrAddress:
  AND $F8
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD B,$00
  SRL C
  SRL C
  SRL C
  ADD HL,BC
  LD BC,Attributes
  ADD HL,BC
  RET

  ORG $93BE

; Is SPACE down?
;
; Calls KeyHook $FCDB, then reads port $7FFE bit 0: Z when SPACE is held.
; Called from $7BD4, ItemWindowSpace $7C02 and ItemWindowRelease $7C08. As in
; stage 1 at $8A54, the same code.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
TestSpaceKey:
  CALL KeyHook
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  RET

; Clear the screen's 768 attributes to 0
;
; Called by ClearScreen. As in stage 1 at $8A5F, the same code.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
ClearAttributes:
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

; Clear the shadow attributes $6D00-$6FFF to 0
;
; Called by StageSetUp. As in stage 1 at $8A6D, the same code.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
ClearShadowAttributes:
  LD HL,ShadowAttributes
  LD DE,ShadowAttributes+$0001
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

; Clear $5B00-$6C30 to 0 (LDIR)
;
; 4401 bytes. As in stage 1 at $8A7B, the same code. No caller in stage 5's
; code (no CALL, JP or word in the block names $93E5:
; work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
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
; = the first pixel line, D = the width in bytes, E = the lines. Patches its
; ADD A,n at CopyBlockColumn with the column; the line addresses come from
; ScreenLineTable $FB00. Each line: EX DE,HL, LDIR, EX DE,HL, so the screen's
; bytes go to the buffer (not the other way). Called from $7924 (EndStage saves
; the HUD's lines 0-47 into HudPicture $7000). The same code as stage 1's
; $8A89, which stage 1 names CopyBlockToScreen.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
CopyScreenToBlock:
  LD A,B
  LD (CopyBlockColumn+$0001),A
  LD B,$00
  LD IX,ScreenLineTable
  ADD IX,BC
  ADD IX,BC
  LD B,E
  LD C,D
CopyBlockLine:
  PUSH BC
  LD A,(IX+$00)
CopyBlockColumn:
  ADD A,$00               ; ADD A,n: n = the column, written at $93F4
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

  ORG $946F

; HL = A x B (the smaller one as the loop count)
;
; Returns HL = 0 when A is 0. As stage 1's Multiply $8B24. No caller in stage
; 5's code (no CALL, JP or word names $946F: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
Multiply:
  LD HL,$0000
  CP B
  JP C,MultiplySet
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

; RandomSeed = RandomSeed x 5 + $15; A = it
;
; RandomSeed $FE08 (low byte). Called from MoveStarNewLine $8656. As in stage 1
; at $8B76, the same code.
;
; Witness: L1 7885 (ending, rzx-r5, s5-right).
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
; RandomPointer $FE0A + 1, kept in $0000-$3FFF; A = the ROM byte there. Called
; from InitStarsLine $8603, $8612, UpdateBurst and StartBurst. As in stage 1 at
; $8B85, the same code.
;
; Witness: L1 617 (ending, rzx-r5, s5-right).
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
; Called by StageSetUp and from $792A. As in stage 1 at $8B92, the same code.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
ClearScreen:
  CALL ClearAttributes
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  RET

  ORG $9546

; Wait BC interrupts (HALT each)
;
; Called by StageSetUp (BC = 50, twice) and from $7930. As in stage 1 at $8C35,
; the same code.
;
; Witness: L1 300 (ending, rzx-r5, s5-right).
WaitFrames:
  HALT
  DEC BC
  LD A,B
  OR C
  JP NZ,WaitFrames
  RET

  ORG $95BD

; Clear the shots and free all 13 actor records ($74F2, 234 bytes of $FF)
;
; ClearShots, then $74F2-$75DB = $FF. As in stage 1 at $921E, the same code. No
; caller in stage 5's code (no CALL, JP or word names $95BD:
; work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
ClearActors:
  CALL ClearShots
  LD HL,ActorRecords+$0012
  LD DE,ActorRecords+$0013
  LD BC,$00E9
  LD (HL),$FF
  LDIR
  RET

; Fill the shot slots $75E0-$763F (96 bytes) with $FF
;
; Called only by ClearActors. As in stage 1 at $924B, the same code.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
ClearShots:
  LD HL,HeroShots
  LD DE,HeroShots+$0001
  LD BC,$0060
  LD (HL),$FF
  LDIR
  RET

; The actor IY's base line +$0E + C
;
; As in stage 1 at $92C9, the same code. No caller in stage 5's code (no CALL,
; JP or word names $95DC: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
MoveActorY:
  LD A,(IY+$0E)
  ADD A,C
  LD (IY+$0E),A
  RET

  ORG $9E9C

; Copy an 18-byte template (HL) into the record IY and put it at D, E
;
; Input: HL = the template, IY = the record, D, E = X and Y (also the entry X,
; Y at +$0D, +$0E). Preserves IY and DE. As in stage 1 at $A4B1, the same code.
; No caller in stage 5's code (no CALL, JP or word names $9E9C:
; work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
SpawnActor:
  PUSH IY
  PUSH DE
  PUSH IY
  POP DE
  LD BC,$0012
  LDIR
  POP DE
  LD (IY+$00),D
  LD (IY+$0D),D
  LD (IY+$01),E
  LD (IY+$0E),E
  POP IY
  RET

; Call the handler of every used actor record (the 14 records from $74E0)
;
; When +0 is not $FF, the handler +6/+7 is written into HandlerCall and called
; with IY = the record. As stage 1's RunActorHandlers $A5BD. No caller in stage
; 5's code (no CALL, JP or word names $9EB7: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
RunActorHandlers:
  LD B,$0E
  LD IY,ActorRecords
RunActorHandlersLoop:
  PUSH BC
  LD A,(IY+$00)
  INC A
  JP Z,RunActorHandlersNext
  LD L,(IY+$06)
  LD H,(IY+$07)
  LD (HandlerCall+$0001),HL
HandlerCall:
  CALL $0000              ; CALL n: n = the record's handler (written at $9ECB)
RunActorHandlersNext:
  POP BC
  LD DE,$0012
  ADD IY,DE
  DJNZ RunActorHandlersLoop
  RET

; Stage 1's two-pass actor drawing loops, with their drawing calls gone
;
; Two loops over the 14 records from ActorRecords $74E0 test +0 = $FF and +$0F
; bits 6 and 7 as stage 1's DrawActors $A5DF does, but every branch lands on
; the next record: nothing is drawn (stage 1's CALLs of ClipActor and
; DrawActorSprite are not there). The only word $9EDA in the block is at $70D1,
; inside the data. No caller in stage 5's code (work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
DrawActors:
  LD B,$0E
  LD IY,ActorRecords
DrawActorsLoop:
  PUSH BC
  LD A,(IY+$00)
  CP $FF
  JP Z,DrawActorsNext
  BIT 6,(IY+$0F)
  JP NZ,DrawActorsNext
  BIT 7,(IY+$0F)
  JP NZ,DrawActorsNext
DrawActorsNext:
  POP BC
  LD DE,$0012
  ADD IY,DE
  DJNZ DrawActorsLoop
  LD B,$0E
  LD IY,ActorRecords
DrawActorsTopLoop:
  PUSH BC
  LD A,(IY+$00)
  CP $FF
  JP Z,DrawActorsTopNext
  BIT 7,(IY+$0F)
  JP Z,DrawActorsTopNext
DrawActorsTopNext:
  POP BC
  LD DE,$0012
  ADD IY,DE
  DJNZ DrawActorsTopLoop
  RET

; DE = $5B00 + Y x 32 + X of the actor IY
;
; As stage 1's BufferAddressDE $A664. No caller in stage 5's code (no CALL, JP
; or word names $9F1E: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
BufferAddressDE:
  LD L,(IY+$01)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
  LD BC,PlayBuffer
  ADD HL,BC
  EX DE,HL
  RET

; Move the actor IY's base column +$0D by E (the other way when it faces left)
;
; As stage 1's MoveBaseX $B112. No caller in stage 5's code (no CALL, JP or
; word names $9F34: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
MoveBaseX:
  LD A,E
  BIT 7,(IY+$09)
  JP Z,MoveBaseXAdd
  NEG
MoveBaseXAdd:
  ADD A,(IY+$0D)
  LD (IY+$0D),A
  RET

; A = -A when the actor IY faces left (+9 bit 7)
;
; As in stage 1 at $B122, the same code. No caller in stage 5's code (no CALL,
; JP or word names $9F45: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
NegateIfFacingLeft:
  BIT 7,(IY+$09)
  RET Z
  NEG
  RET

; A = 4 - A when the actor IY faces left (+9 bit 7), else A
;
; No caller in stage 5's code (no CALL, JP or word names $9F4D:
; work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
NegatePlus4IfFacingLeft:
  BIT 7,(IY+$09)
  RET Z
  NEG
  ADD A,$04
  RET
