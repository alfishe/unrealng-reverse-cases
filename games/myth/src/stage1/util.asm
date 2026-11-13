; --------------------------------------------------------------------------------------------------------------------
; util.asm: Small helpers: keys, clears, copies, numbers, random numbers, delays
;
; Clears and copies of the screen and the shadow, the decimal printing helpers, the random numbers (Random $8B85 reads
; ROM bytes through RandomPointer; NextSeed $8B76 an LCG), WaitFrames and the small arithmetic the others share.
; --------------------------------------------------------------------------------------------------------------------

  ORG $79AB

; Busy wait: count BC down to 0
;
; Input BC (the rounds, 26 T-states each). Output BC = 0, A = 0. The interrupt
; returns land on its three instructions (L1 lists them as entries).
;
; Witness: L1 12491743 (c1o, deaths, rzx-r1, s1-idle, s1-right).
DelayBC:
  DEC BC

; DelayBCTest
DelayBCTest:
  LD A,B
  OR C

; DelayBCLoop
DelayBCLoop:
  JR NZ,DelayBC
  RET

  ORG $8A54

; Is SPACE down?
;
; Calls KeyHook, then reads port $7FFE bit 0: Z when SPACE is held. The main
; loop $7872 opens the item window on it.
;
; Witness: L1 156844 (c1o, deaths, rzx-r1, s1-idle, s1-right).
TestSpaceKey:
  CALL KeyHook
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  RET

; Clear the screen's 768 attributes to 0
;
; Witness: L1 5 (rzx-r1, s1-idle, s1-right).
ClearAttributes:
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

; Clear the shadow attributes $6D00-$6FFF to 0
;
; Witness: L1 3 (rzx-r1, s1-idle, s1-right).
ClearShadowAttributes:
  LD HL,ShadowAttributes
  LD DE,ShadowAttributes+$0001
  LD BC,$02FF
  LD (HL),$00
  LDIR
  RET

; Clear $5B00-$6C30 to 0 (LDIR)
;
; Clears 4401 bytes of the play buffer (the LDIR form; ClearBuffer $9AB5 is the
; fast PUSH form of the whole 4608).
;
; Called at $9F49 and $9F9F before a room change. Unrle overwrites 4295 of its
; 4401 bytes and RoomChange ends with
;
; ClearBuffer: the clear buys nothing (c1: 120 109 T of a room change).
;
; Witness: L1 94 (c1o, deaths, rzx-r1, s1-right).
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
; in bytes, E = the lines. Patches its ADD A,n at $8A9D with the column; the
; line addresses come from ScreenLineTable.
;
; Each line: EX DE,HL, LDIR, EX DE,HL, so the screen's bytes go to the buffer.
; EndStage saves the HUD's lines
;
; 0-47 into $7000 with it ($790D).
;
; Witness: L1 2 (rzx-r1, s1-right).
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

  ORG $8B24

; HL = A x B (the smaller one as the loop count)
;
; Returns HL = 0 when A is 0. Called by $A9AF.
;
; Witness: L1 1223 (rzx-r1).
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

  ORG $8B76

; RandomSeed = RandomSeed x 5 + $15; A = it
;
; Called by the actor set-up $A5A1.
;
; Not executed in any recording (the recordings checked: c1o, deaths, rzx-r1,
; s1-idle, s1-right); known only from the code.
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
; Witness: L1 6635 (c1o, deaths, rzx-r1, s1-idle, s1-right).
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
; Witness: L1 5 (rzx-r1, s1-idle, s1-right).
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
; ItemIcons' kind 4 points here (DrawItemIcon $7E19 reads all 32 bytes);
; CopyToScreen $79CC copies its first bytes with stride 0 to clear the play
; area (StageEntry), the HUD fields (EndStage) and the item strip
; (GameOverStep); the templates' frame word ($9D3B and others) points here
; until SetActorFrame sets a frame. Read in the stage-1 builds (DrawItemIcon,
; $79CC).
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
; Not executed in any recording (the recordings checked: c1o, deaths, rzx-r1,
; s1-idle, s1-right); known only from the code.
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
; Witness: L1 319 (rzx-r1, s1-idle, s1-right).
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

  ORG $8C35

; Wait BC interrupts (HALT each)
;
; Witness: L1 500 (rzx-r1, s1-idle, s1-right).
WaitFrames:
  HALT
  DEC BC
  LD A,B
  OR C
  JP NZ,WaitFrames
  RET

  ORG $B2DC

; A = 1, Z set: the "yes" exit of the tests
;
; Witness: L1 924 (c1o, deaths, rzx-r1, s1-right).
ReturnZ:
  LD A,$01
  CP $01
  RET

; A = 1, Z clear: the "no" exit of the tests
;
; Witness: L1 311 (c1o, deaths, rzx-r1, s1-right).
ReturnNZ:
  LD A,$01
  CP $00
  RET
