; --------------------------------------------------------------------------------------------------------------------
; levels.asm: The screens of a level: the exits, the load of a screen, the restart point, the map build
;
; A level is a chain of screens. A screen record (IX) gives: +0 the charset (0: $7100 with the attributes $7900, else
; $7A00 and $8200), +1/+2 the map's block table, +3/+4 the exit table, +5/+6 the object list ($FD7E). LoadScreen $AC83
; installs one, builds its map, places its objects and redraws the screen.
;
; The exit table has 5-byte entries: +0 the exit's kind (compared with $FD62), +1 the map row it lies on, +2/+3 the
; next screen record ($FFFF: the level's end), +4 the row offset for the next screen; $FF ends it. CheckScreenExit
; $AB93 runs when the game flags an exit ($FD61, $E3FD) and takes the entry of that kind within 3 rows of Rick.
;
; The map is 11 rows of 8 blocks; a block is 4x4 chars (16 bytes from $C31C + 16 block). ViewTopRow $ADB7 is the map
; row at the view's top.
;
; SaveRestartPoint $AD01 keeps the state at the screen's entry in RestartPoint $AD20; after a life is lost
; RestartScreen $AD29 restores it and loads the screen again.
;
; The level table LevelTable $E4AE holds 11 bytes a level: the intro text and where it goes, the attribute byte stored
; in `$7900`, Rick's x and y and the first zone record with its count for `$AC83`. Record 0 is the level being played:
; NewGame $E2DC and StartLevel $E32C read it; the level change `$ABF6` / `$AC07` reads record Level $E4AD, and record
; 4 is the closing text of the ending.
;
; The level and zone change itself (`$AB93`, `$ABF6`, `$AC83`) lies outside this fragment.
;
; SpawnObjects walks the zone's spawn list, 5-byte records sorted by row and ended by $FF, and starts the
;
; objects whose rows come into view. Its list pointer is the operand of its first instruction, which the zone
;
; setup writes ($ACCC).
; --------------------------------------------------------------------------------------------------------------------

  ORG $AB93

; Find the exit Rick takes and go to its screen (or end the level)
;
; C = Rick's map row (y $EAAE / 8 + ViewTopRow), B = the exit kind $FD62. Scans
; the exit table (the operand $AB95 of its first instruction, LD IX, written by
; LoadScreen $ACC3: 5-byte entries) for one of kind B whose row is at most 2
; above C; none: return. Found: the next screen record +2/+3; $FFFF falls into
; LevelEnd, else ExitToScreen with BC = ViewTopRow - (row - entry +4).
;
; Called from the game loop ($E403). Output: everything.
;
; Witness: L1 107 (c1, ending2, l1end, L1Z2-L1Z4, L1Z6, L2Z2-L2Z7, L3Z2-L3Z12,
; L4Z2-L4Z6, L4Z8, level1).
CheckScreenExit:
  LD IX,$0000
  LD A,(RickY)
  SRL A
  SRL A
  SRL A
  LD C,A
  LD A,(ViewTopRow)
  ADD A,C
  LD C,A
  LD A,(ExitSide)
  LD B,A

; ExitScan
;
; Used by the routine at ExitNoMatch.
ExitScan:
  LD A,(IX+$00)
  CP B
  JP NZ,ExitNoMatch
  LD A,C
  SUB (IX+$01)
  CP $03
  JP NC,ExitNextEntry
  LD A,(IX+$01)
  SUB (IX+$04)
  LD C,A
  LD A,(ViewTopRow)
  SUB C
  LD C,A
  LD B,$00
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD A,H
  CP $FF
  JP NZ,ExitToScreen
  CP L
  JP NZ,ExitToScreen

  ORG $AC72

; The tail of CheckScreenExit: IX = the next screen record, then LoadScreen
;
; Entered by jumps from CheckScreenExit only.
;
; Witness: L1 104 (c1, L1Z2-L1Z4, L1Z6, L2Z2-L2Z7, L3Z2-L3Z12, L4Z2-L4Z6, L4Z8,
; level1).
ExitToScreen:
  PUSH HL
  POP IX
  JP LoadScreen

; ExitNoMatch
;
; Used by the routine at ExitScan.
ExitNoMatch:
  CP $FF                  ; kind differs: $FF ends the table (return), else the
                          ; next entry
  RET Z
; This entry point is used by the routine at ExitScan.
ExitNextEntry:
  LD DE,$0005
  ADD IX,DE
  JP ExitScan

; Install the screen record IX with the view's top row BC
;
; Saves IX in RestartScreenRecord, clears $FD61, chooses the charset by +0
; (CharsetBase $7100 and the attribute table $79, DE = $F6C0; or $7A00, $82,
; $F6D0), stores +1/+2 in MapBlockTable, BC in ViewTopRow, +3/+4 in
; CheckScreenExit's operand $AB95, +5/+6 at $FD7E.
;
; Calls $F6A9 (with DE), BuildScreenMap, $EBF7, then $FD7D three times (D =
; ViewTopRow + 8, E = $18; D = ViewTopRow, E = 8; D = ViewTopRow + $20, E = 8),
; MarkAllDirty, RedrawScreen and SaveRestartPoint.
;
; Callers: the game start ($E351), ExitToScreen, NextLevel and RestartScreen.
; The other charset ran in level3 and level4 only. Output: everything.
;
; Witness: L1 439 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
LoadScreen:
  LD (RestartScreenRecord),IX
  XOR A
  LD (ZoneChange),A
  LD A,$79
  LD (AttrTableHigh+1),A
  LD (CounterAttrTableHigh+$0001),A
  LD DE,CharPropsSet0
  LD HL,CharSet0
  LD A,(IX+$00)
  AND A
  JR Z,LoadScreenCharset
  LD A,$82
  LD (AttrTableHigh+1),A
  LD (CounterAttrTableHigh+$0001),A
  LD DE,CharPropsSet1
  LD HL,CharSet1
LoadScreenCharset:
  LD (CharsetBase),HL
  LD L,(IX+$01)
  LD H,(IX+$02)
  LD (MapBlockTable),HL
  LD (ViewTopRow),BC
  LD L,(IX+$03)
  LD H,(IX+$04)
  LD (CheckScreenExit+$0002),HL
  LD L,(IX+$05)
  LD H,(IX+$06)
  LD (SpawnObjects+$0001),HL
  CALL BuildCharProps
  CALL BuildScreenMap
  CALL ResetObjects
  LD A,(ViewTopRow)
  ADD A,$08
  LD D,A
  LD E,$18
  CALL SpawnObjects
  LD A,(ViewTopRow)
  LD D,A
  LD E,$08
  CALL SpawnObjects
  LD A,(ViewTopRow)
  ADD A,$20
  LD D,A
  LD E,$08
  CALL SpawnObjects
  CALL MarkAllDirty
  CALL RedrawScreen
  CALL SaveRestartPoint
  RET

; Keep the screen's entry state in RestartPoint
;
; Copies $FD5A, Rick's x ($EAAD), y ($EAAE), byte +6 ($EAB2) and ViewTopRow to
; RestartPoint (LoadScreen has stored the screen record there).
;
; Witness: L1 438 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
SaveRestartPoint:
  LD A,(Crawling)
  LD (RestartPoint),A
  LD HL,(RickY)
  LD (RestartY),HL
  LD A,(RickX)
  LD (RestartX),A
  LD A,(RickMirror)
  LD (RestartFlags),A
  LD HL,(ViewTopRow)
  LD (RestartTopRow),HL
  RET

; The state at the current screen's entry: $FD5A, x, y (word), +6, the top row
; (word), the screen record (word)
RestartPoint:
  DEFB $00
RestartX:
  DEFB $00
RestartY:
  DEFB $00,$00
RestartFlags:
  DEFB $00
RestartTopRow:
  DEFB $00,$00
RestartScreenRecord:
  DEFB $00,$00

; After a life lost: clear the 25 bytes $FD54-$FD6C, restore RestartPoint and
; load the screen again
;
; Restores $FD5A, Rick's x, y and +6, clears $ECF1, then jumps to LoadScreen
; with IX and BC from RestartPoint. Called from the game loop ($E3C3).
;
; Witness: L1 323 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
RestartScreen:
  LD HL,RickVars
  LD B,$19
  XOR A
RestartClearLoop:
  LD (HL),A
  INC HL
  DJNZ RestartClearLoop
  LD A,(RestartPoint)
  LD (Crawling),A
  LD A,(RestartX)
  LD (RickX),A
  LD HL,(RestartY)
  LD (RickY),HL
  LD A,(RestartFlags)
  LD (RickMirror),A
  LD BC,(RestartTopRow)
  XOR A
  LD (BlastOn),A
  LD IX,(RestartScreenRecord)
  JP LoadScreen

; Expand the map's blocks into the char map $6500-$6A7F
;
; Source: MapBlockTable + 2 (ViewTopRow AND $FC), one byte a block. For 11 rows
; of 8 blocks: block b's 16 chars ($C31C + 16b, read in RAM 0) go to a 4x4
; square of the map. Interrupts off while it runs; SP saved and restored though
; it never changes.
;
; Callers: LoadScreen and the end of both scrolls. Output: everything (the
; alternate registers too).
;
; Witness: L1 525 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
BuildScreenMap:
  DI
  LD (BuildMapSP+$0001),SP
  LD A,(ViewTopRow)
  AND $FC
  LD L,A
  LD H,$00
  ADD HL,HL
  LD BC,(MapBlockTable)
  ADD HL,BC
  EX DE,HL
  LD HL,MusicImage+$0700
  EXX
  LD C,$0B
BuildMapRow:
  LD B,$08
BuildMapBlock:
  EXX
  EX DE,HL
  LD (BuildMapSource+$0001),HL
  LD A,(HL)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Tiles
  ADD HL,BC
  LD A,$04
  LD B,$00
BuildMapBlockRow:
  LD C,$20
  LDI
  LDI
  LDI
  LDI
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  DEC A
  JR NZ,BuildMapBlockRow
  EX DE,HL
  LD BC,$FF84
  ADD HL,BC
BuildMapSource:
  LD DE,$0000             ; its operand: the source byte of the block being
                          ; drawn
  INC DE
  EXX
  DJNZ BuildMapBlock
  EXX
  LD BC,$0060
  ADD HL,BC
  EXX
  DEC C
  JR NZ,BuildMapRow
BuildMapSP:
  LD SP,$0000             ; its operand: the caller's SP
  EI
  RET

; The current screen's map: the block numbers, 8 a row
MapBlockTable:
  DEFW $0000

; The map row at the view's top (read as a byte too)
ViewTopRow:
  DEFW $0000

  ORG $E32C

; Start the first level: wait for fire, place Rick, set up the first zone
;
; Waits for fire (`$A123` Z), then puts Rick at LevelTable's x and y (RickX
; $EAAD, RickY $EAAE), his size `$18` x `$15` (RickWidth $EAB3, RickHeight
; $EAB4), and sets up the zone with IX = the zone record and C = its count
; (`$AC83`).
;
; With lives left (always, at a new game) it goes on to NewLife $E3AF; with
; none it falls into Quit $E35A.
;
; Witness: L1 134127 (beeper48, c1, controls, gameover, level1-level4).
StartLevel:
  CALL StartPressed
  JR NZ,StartLevel
  LD A,(LevelRickX)
  LD (RickX),A
  LD HL,(LevelRickY)
  LD (RickY),HL
  LD A,$18
  LD (RickWidth),A
  LD A,$15
  LD (RickHeight),A
  LD IX,(LevelZone)
  LD A,(LevelViewTop)
  LD C,A
  LD B,$00
  CALL LoadScreen
  LD A,(Lives)
  AND A
  JR NZ,NewLife

  ORG $E4AE

; 11 bytes a level: 0 jungle, 1 Egypt, 2 castle, 3 missile base, 4 the ending
;
; +0-1 the intro text, +2-3 its screen address, +4 the attribute stored in
; `$7900`, +5 Rick's x (RickX $EAAD), +6-7 Rick's y (RickY $EAAE), +8-9 the
; first zone record (to IX), +10 the first view row, passed in C to LoadScreen
; `$AC83`, which stores it in ViewTopRow $ADB7 (not a zone count).
;
; Record 0 is read by NewGame $E2DC and StartLevel $E32C; at a level change
; `$AC07` reads record Level $E4AD (`$AC56`). The ending's record has only the
; text and the attribute in use. The warp recordings copy record N over record
; 0 (WALKTHROUGH 6.0).
LevelTable:
  INCLUDE "res/levels/leveltable.inc"

  ORG $FD7D

; Start the objects of the spawn list in rows D to D + E - 1
;
; Inputs: the list at the operand `$FD7E` (set at `$ACCC` from the zone
; record), D = the first row, E = the count
;
; (the zone setup calls it three times: rows top + 8 for 24, top for 8, top +
; `$20` for 8; also `$ADE9`, `$AE1E`).
;
; A record: +0 row AND `$F8` (the low 3 bits are +3's), +1 kind (bit 7: none),
; +2 flags (bit 1: object 0, the solid
;
; block `$EA8E`, if free; bit 2: active, bit 7 of +0), +3 X AND `$F8` and the
; row's low bits, +4 the trigger box's X
;
; and row bits.
;
; A kind below `$10` goes to one of the 3 slots from `$EB9C` (FindSlotLowKind
; `$FEB2`, not when a slot already holds
;
; this record), else one of the 5 slots from `$EB06` (FindSlotHighKind
; `$FEA1`). The object: kind, X (+1, +F), Y =
;
; (row - the zone top `$ADB7`) x 8 (+3 unless object 0; +2/+3, +10/+11), mirror
; 0, width, height, frames from the
;
; kind's record at `$D31C` (8 bytes), the record pointer +9/+A and flags +B,
; the trigger box +C/+D/+E, +1D, and +18
;
; to +1C cleared.
;
; Outputs: none. Uses all registers, IX, IY.
;
; Evidence: active spawns (`$FE54`) in level2-level4; object 0 spawned
; (`$FDB6`) in level2 and level3.
;
; Witness: L1 1403 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
SpawnObjects:
  LD HL,$0000
SpawnFindRow:
  LD A,(HL)               ; skip the records above row D
  CP $FF
  RET Z
  CP D
  JR NC,SpawnRowFound
  LD BC,$0005
  ADD HL,BC
  JP SpawnFindRow
SpawnRowFound:
  PUSH HL
  POP IX
  LD A,D
  ADD A,E
  LD B,A
SpawnLoop:
  LD A,(IX+$00)           ; until $FF or row D + E
  CP $FF
  RET Z
  CP B
  RET NC
  PUSH BC
  AND $F8
  LD C,A
  LD A,(IX+$01)
  AND A
  JP M,SpawnNext
  LD B,A
  BIT 1,(IX+$02)
  JP Z,SpawnLowKind
  LD A,(ObjectTable)
  AND A
  JP NZ,SpawnNext
  LD HL,ObjectTable
  JP SpawnFill
SpawnLowKind:
  CP $10
  JP NC,SpawnHighKind
  PUSH BC
  CALL FindSlotLowKind
  POP BC
  JP NZ,SpawnNext
  JP SpawnFill
SpawnHighKind:
  PUSH BC
  CALL FindSlotHighKind
  POP BC
  JP NZ,SpawnNext
SpawnFill:
  LD (HL),B               ; HL = the slot: +0 = kind
  PUSH HL
  POP IY
  LD A,(IX+$03)
  LD D,A
  AND $F8
  LD (IY+$01),A
  LD (IY+$0F),A
  LD A,D
  AND $07
  LD D,A
  LD A,(ViewTopRow)
  LD B,A
  LD A,C
  SUB B
  ADD A,D
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  BIT 1,(IX+$02)
  JP NZ,SpawnSetY
  LD DE,$0003
  ADD HL,DE
SpawnSetY:
  LD (IY+$02),L
  LD (IY+$03),H
  LD (IY+$10),L
  LD (IY+$11),H
  LD (IY+$06),$00
  LD A,(IX+$01)
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD DE,ObjectKinds
  ADD HL,DE
  LD A,(HL)
  LD (IY+$07),A
  INC HL
  LD A,(HL)
  LD (IY+$08),A
  INC HL
  LD A,(HL)
  LD (IY+$12),A
  LD (IY+$04),A
  INC HL
  LD A,(HL)
  LD (IY+$13),A
  LD (IY+$05),A
  INC HL
  LD A,(HL)
  LD (IY+$14),A
  INC HL
  LD A,(HL)
  LD (IY+$15),A
  PUSH IX
  POP DE
  LD (IY+$09),E
  LD (IY+$0A),D
  LD A,(IX+$02)
  LD (IY+$0B),A
  BIT 2,A
  JP Z,SpawnTrigger
  SET 7,(IY+$00)
SpawnTrigger:
  LD A,(IX+$04)           ; the trigger box from the record's +4
  LD D,A
  AND $F8
  LD (IY+$0C),A
  LD A,D
  AND $07
  LD D,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD (IY+$1D),A
  LD A,(ViewTopRow)
  LD B,A
  LD A,(IX+$00)
  AND $F8
  SUB B
  ADD A,D
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$0003
  ADD HL,BC
  LD (IY+$0D),L
  LD (IY+$0E),H
  XOR A
  LD (IY+$18),A
  LD (IY+$19),A
  LD (IY+$1A),A
  LD (IY+$1B),A
  LD (IY+$1C),A
SpawnNext:
  LD BC,$0005
  ADD IX,BC
  POP BC
  JP SpawnLoop

; HL = a free slot of the 5 at $EB06
;
; Outputs: Z and HL = the slot (+0 = 0); NZ (A = 1) when all 5 are in use. Uses
; B, DE.
;
; Witness: L1 1386 (beeper48, c1, controls, gameover, spotL3Z7-51, L1Z1-L1Z6,
; L2Z1-L2Z7, L3Z1-L3Z12, L4Z1-L4Z9, level1-level4, spotL1Z4-43).
FindSlotHighKind:
  LD HL,ZoneObjects
  LD B,$05
  LD DE,$001E
FindSlotHighKindLoop:
  LD A,(HL)
  AND A
  RET Z
  ADD HL,DE
  DJNZ FindSlotHighKindLoop
  XOR A
  INC A
  RET

; HL = a free slot of the 3 at $EB9C, unless one holds this spawn record
;
; Input: IX = the spawn record. A slot in use whose +9/+A is IX: NZ (it is
; spawned already). Else Z and HL = the
;
; first free slot, NZ when none.
;
; Outputs: Z/NZ, HL. Uses B, DE, IY.
;
; Witness: L1 734 (c1, spotL3Z7-51, L1Z2-L1Z6, L2Z2-L2Z7, L3Z2-L3Z12,
; L4Z1-L4Z9, level1-level4, spotL1Z4-43).
FindSlotLowKind:
  LD IY,ZoneObjects+$0096
  LD B,$03
  PUSH IX
  POP HL
  LD DE,$001E
FindSlotLowKindDup:
  LD A,(IY+$00)
  AND A
  JP Z,FindSlotLowKindNext
  LD A,(IY+$09)
  CP L
  JP NZ,FindSlotLowKindNext
  LD A,(IY+$0A)
  CP H
  JP Z,FindSlotLowKindNone
FindSlotLowKindNext:
  ADD IY,DE
  DJNZ FindSlotLowKindDup
  LD HL,ZoneObjects+$0096
  LD B,$03
  LD DE,$001E
FindSlotLowKindFree:
  LD A,(HL)
  AND A
  RET Z
  ADD HL,DE
  DJNZ FindSlotLowKindFree
FindSlotLowKindNone:
  XOR A
  INC A
  RET

; 22 zero bytes, never used
FreeFEE8:
  DEFS $16
