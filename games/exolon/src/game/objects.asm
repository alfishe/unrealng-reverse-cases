; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The object cells indexed into lists: flames, turrets and their shells, the colour cycle
; --------------------------------------------------------------------------------------------------------------------

; Turn the object cells the screen's strings marked in the block map into the
; kinds' lists
;
; First empties the 16 lists of KindTable (an $FF at each list's start, the
; write pointer back to it). Then walks the 704 bytes of the block map: each
; value 2-17 is an object cell (AddObjectCell). Called by BuildScreen once the
; elements are printed.
IndexObjectCells:
  LD HL,KindTable
  LD B,$10
IndexObjectCellsReset:
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,$FF
  LD (DE),A
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  INC HL
  INC HL
  DJNZ IndexObjectCellsReset
  LD HL,CellTypes
  LD BC,$02C0
IndexObjectCellsScan:
  LD A,(HL)
  CP $02
  CALL NC,AddObjectCell
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,IndexObjectCellsScan
  RET

; Append cell HL (block map address) of kind A to its list; replace the map
; byte
;
; The cell's column and row: (HL - $6100) AND 31 and / 32 ($8EB0 adds $9F00 =
; -$6100). The kind's record in KindTable ($8EE8 + 6 A, kinds from 2): the
; column and row are written at its write pointer, which moves on by the record
; size, and an $FF is put after them; the block map byte becomes the record's
; +5 value (0 for a cell that is not solid, 1 solid, or the kind kept: 3 and
; 13).
;
; 1838 entries over 103 recordings.
AddObjectCell:
  PUSH BC
  PUSH HL
  EX AF,AF'
  LD DE,-CellTypes
  ADD HL,DE
  LD A,L
  AND $1F
  LD E,A
  LD A,L
  SRL H
  RRA
  SRL H
  RRA
  AND $F8
  RRCA
  RRCA
  RRCA
  LD D,A
  EX AF,AF'
  LD L,A
  LD H,$00
  ADD HL,HL
  LD B,H
  LD C,L
  ADD HL,HL
  ADD HL,BC
  LD BC,KindTable-12
  ADD HL,BC
  PUSH HL
  POP IX
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD (HL),E
  INC HL
  LD (HL),D
  LD C,(IX+$04)
  LD B,$00
  DEC C
  ADD HL,BC
  LD (IX+$02),L
  LD (IX+$03),H
  LD (HL),$FF
  POP HL
  LD A,(IX+$05)
  LD (HL),A
  POP BC
  RET

; The 16 object cell kinds 2-17: the list, its write pointer, the record size,
; the map value after indexing
;
; +0/+1 the list's address, +2/+3 the write pointer (IndexObjectCells sets it
; to +0/+1), +4 the record length (2: column, row; 3: one more state byte), +5
; what the block map byte becomes. The kinds (the handlers are past exB's
; range; the names from the elements that mark them):
;
; 2 $8F89 (2, 0) the jets, AnimateFlames; 3 $9022 (3, 3) the gun turrets'
; barrels, AnimateTurrets; 4 $9135 (2, 0) blinking light cells, $9118
; (attribute = pass count AND 7 OR $40); 5 $91B0 (3, 1) the mines, $9152; 6
; $9930 (2, 1) the teleport booths, $98BA; 7 $99F2 (2, 0) the ammunition pod; 8
; $99F5 (2, 0) the grenade pod, both $9942; 9 $9B4B (2, 0) the ring, $9B07 /
; $9B52; 10 $9C70 (3, 1) the traps, $9C15 / $9C8B; 11 $9DC1 (2, 0) and 14 $A333
; (3, 0) the twin launchers, $9D7F and $A30B; 12 $9F6E (2, 1) the exoskeleton
; booth, $9F2D; 13 $A266 (2, 13) the spore pod, $A23A / $A26B; 15 $A814 (2, 0)
; the sector gate's top marks, $A7D6; 16 $AAEF (2, 0) the gate's floor mark,
; $A817; 17 $ABCC (2, 1) the drop pod, $AB97 / $ABCF.
KindTable:
  DEFB $89,$8F,$00,$00,$02,$00
  DEFB $22,$90,$00,$00,$03,$03
  DEFB $35,$91,$00,$00,$02,$00
  DEFB $B0,$91,$00,$00,$03,$01
  DEFB $30,$99,$00,$00,$02,$01
  DEFB $F2,$99,$00,$00,$02,$00
  DEFB $F5,$99,$00,$00,$02,$00
  DEFB $4B,$9B,$00,$00,$02,$00
  DEFB $70,$9C,$00,$00,$03,$01
  DEFB $C1,$9D,$00,$00,$02,$00
  DEFB $6E,$9F,$00,$00,$02,$01
  DEFB $66,$A2,$00,$00,$02,$0D
  DEFB $33,$A3,$00,$00,$03,$00
  DEFB $14,$A8,$00,$00,$02,$00
  DEFB $EF,$AA,$00,$00,$02,$00
  DEFB $CC,$AB,$00,$00,$02,$01

; Draw the jets (kind 2) one frame on: 2 glyphs below each marked cell, random
; bright colours
;
; Once a pass. FlamePhase steps 0, 1, 2; the glyphs $15 + 2 phase and $16 + 2
; phase of the font $DAB8 go one under the other below the marked cell (row + 1
; and + 2) in a random ink (Random $AD36 AND 7 OR $42: bright, on black). Plain
; print ($AE26): no map writes.
AnimateFlames:
  LD HL,TileGlyphs
  LD (PrintChar+$000E),HL
  LD A,(FlamePhase)
  INC A
  CP $03
  JR NZ,AnimateFlamesPhase
  XOR A
AnimateFlamesPhase:
  LD (FlamePhase),A
  ADD A,A
  ADD A,$15
  LD HL,FlameList
AnimateFlamesNext:
  BIT 7,(HL)
  RET NZ
  EX AF,AF'
  CALL Random
  AND $07
  OR $42
  LD C,A
  EX AF,AF'
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC D
  INC HL
  CALL PrintCharAttr
  INC D
  INC A
  CALL PrintCharAttr
  DEC A
  JR AnimateFlamesNext

; The jets' cells (kind 2): up to 5 of column, row; $FF ends
;
; Filled by IndexObjectCells; read by AnimateFlames. Screen 27 has five jet
; cells, which fill it exactly (the $FF lands on $8F93); a sixth would run over
; FlamePhase.
FlameList:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $FF                ; $FF: the end mark when the list is full

; The jets' animation frame 0-2
FlamePhase:
  DEFB $00

; The gun turrets (kind 3): fire at random, animate the barrel, notice a
; destroyed one
;
; Once a pass, font $DDD8. For each turret with a state (1-9; 0 = gone): its
; block map cell is no longer 3 (the turret was destroyed: GrenadeBlast $93E2
; prints element 5, a destructible, again with printer 3, and this branch XORs
; off the barrel and the $12/$13 pair): state 0 and the barrel XORed away (its
; frame, then the $12/$13 pair, in attribute 0). State 1 is idle: 6 times in
; 256 (Random >= $FA) the turret fires (FireShell to the left, C = $FF) and its
; state becomes 9. States 9 to 2 count down one a pass: the frame of the old
; state is XORed off and the new one on (attributes $46 and $06), through the
; glyph pairs $10, $1E, $1C, ... $12, $10 of TurretFrames.
AnimateTurrets:
  LD HL,TileSetDDD8
  LD (PrintChar+$000E),HL
  LD HL,TurretList
AnimateTurretsNext:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,AnimateTurretsSkip
  PUSH HL
  CALL CellOffset
  LD BC,CellTypes
  ADD HL,BC
  LD A,(HL)
  CP $03
  POP HL
  JR Z,TurretIdle
  PUSH HL
  LD A,(HL)
  LD (HL),$00
  CALL TurretFrame
  LD C,$00
  CALL XorCharAttr
  INC A
  INC E
  CALL XorCharAttr
  LD A,$13
  CALL XorCharAttr
  DEC A
  DEC E
  CALL XorCharAttr
  POP HL
  JR AnimateTurretsSkip
TurretIdle:
  LD A,(HL)               ; state 1: fire at random
  CP $01
  JR NZ,TurretRecoil
  CALL Random
  CP $FA
  JR C,AnimateTurretsSkip
  LD (HL),$09
  LD C,$FF
  PUSH HL
  CALL FireShell
  POP HL
  JR AnimateTurretsSkip
TurretRecoil:
  PUSH HL                 ; states 2-9: one frame of the barrel's animation
  DEC (HL)
  CALL TurretFrame
  LD C,$46
  CALL XorCharAttr
  INC A
  INC E
  LD C,$06
  CALL XorCharAttr
  DEC E
  DEC HL
  LD A,(HL)
  LD C,$46
  CALL XorCharAttr
  INC A
  INC E
  LD C,$06
  CALL XorCharAttr
  POP HL
AnimateTurretsSkip:
  INC HL
  JR AnimateTurretsNext

; A = TurretFrames[A - 1] (the barrel glyph of state A); HL = its address
;
; The table is read from $9018 + A ($9013 LD BC,$9018: the byte before
; TurretFrames, the RET here, is state 0, never asked).
TurretFrame:
  LD L,A
  LD H,$00
  LD BC,TurretFrames-1
  ADD HL,BC
  LD A,(HL)
  RET

; The barrel's first glyph for the states 1-9 (the second is the next glyph)
TurretFrames:
  DEFB $10,$12,$14,$16,$18,$1A,$1C,$1E,$10

; The turrets: up to 4 of column, row, state (2 after a screen is built); $FF
; ends (at most 2 on a screen: 7)
;
; ResetTurretList fills the state bytes with 2 before IndexObjectCells writes
; the columns and rows.
TurretList:
  DEFB $00,$00,$02
  DEFB $00,$00,$02
  DEFB $00,$00,$02
  DEFB $00,$00,$02
  DEFB $FF                ; $FF: the end mark when the list is full

; Fill TurretList's 12 bytes with 2: every turret starts in state 2
;
; Used by the routine at BuildScreen.
ResetTurretList:
  LD HL,TurretList
  LD DE,TurretList+$0001
  LD (HL),$02
  LD BC,$000B
  LDIR
  RET

; Draw or erase a shell at D (Y), E (X): a 2 x 2 pixel dot, XOR
;
; The pair of bits $C0 shifted to the X's 2-pixel phase on two pixel lines.
; When the shadow attributes of the dot's cell and the one left of it are
; black, the cell left of it becomes $47 (one cell left of the dot: the shells
; fly left, into it). AF, BC, DE, HL kept.
XorShell:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  CALL PixelAddress
  LD A,E
  AND $03
  INC A
  LD B,A
  LD A,$03
XorShellShift:
  RRCA
  RRCA
  DJNZ XorShellShift
  LD B,A
  XOR (HL)
  LD (HL),A
  INC H
  LD A,B
  XOR (HL)
  LD (HL),A
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  LD BC,AttrCopy
  ADD HL,BC
  LD A,(HL)
  DEC L
  OR (HL)
  JR NZ,XorShellDone
  LD BC,OpenCells-CellTypes
  ADD HL,BC
  LD (HL),$47
XorShellDone:
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; Fire a shell from the cell at D (row), E (column) in direction C
;
; The first free slot of ShellList (none: no shell): direction C, Y = 8 row +
; 3, X = 4 column; drawn; then the shot sound: 10 noise bursts ($7C26, B = $1E)
; and the AY effect $C148. Called by AnimateTurrets with C = $FF (to the left).
FireShell:
  LD HL,ShellList
FireShellFind:
  BIT 7,(HL)
  RET NZ
  INC HL
  INC HL
  LD A,(HL)
  OR A
  JR Z,FireShellSet
  INC HL
  JR FireShellFind
FireShellSet:
  LD (HL),C
  DEC HL
  LD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  INC A
  INC A
  INC A
  LD D,A
  LD (HL),A
  DEC HL
  LD A,E
  ADD A,A
  ADD A,A
  LD E,A
  LD (HL),A
  CALL XorShell
  LD B,$0A
FireShellNoise:
  PUSH BC
  LD B,$1E
  CALL BeeperNoise
  POP BC
  DJNZ FireShellNoise
  JP PlaySfxBlast

; Move every shell 1 unit (2 pixels); it ends at the screen edge (X >= $7F)
;
; Called twice a main loop pass. Shells do not stop at scenery.
MoveShells:
  LD HL,ShellList
MoveShellsNext:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,MoveShellsNext
  CALL XorShell
  ADD A,E
  LD E,A
  CP $7F
  JR C,MoveShellsStore
  DEC HL
  LD (HL),$00
  INC HL
  JR MoveShellsNext
MoveShellsStore:
  PUSH HL
  DEC HL
  DEC HL
  DEC HL
  LD (HL),E
  POP HL
  CALL XorShell
  JR MoveShellsNext

; The turrets' shells: 10 slots of X, Y, direction (0 free); $FF ends
ShellList:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $FF                ; $FF: the end mark

; A shell that touches the player is erased and kills him ($9CAF)
;
; For each live shell the box test $9BD6 (BC = 0) against the player; a hit
; frees the slot and jumps to the death $9CAF (which returns at once while the
; player is immune or already dying). Once a pass.
ShellsHitPlayer:
  LD HL,ShellList
ShellsHitPlayerNext:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,ShellsHitPlayerNext
  LD BC,$0000
  CALL PlayerContact
  OR A
  JR Z,ShellsHitPlayerNext
  CALL XorShell
  DEC HL
  LD (HL),$00
  JP KillPlayer

; Empty the turrets' shell list ShellList $90CB (10 records of 3 bytes)
;
; Called by the screen builder $8494 before it builds the object lists. Writes
; 30 zeros to $90CB-$90E8; $90E9 keeps its $FF end mark. The list belongs to
; $9071 (a missile fired, its record X, Y, speed), $90A2 (moves them right) and
; $90EA (kills the player on contact).
;
; c1: 4 runs (one per screen build).
ClearShellList:
  LD HL,ShellList
  LD DE,ShellList+$0001
  LD BC,$001D
  LD (HL),B               ; B = 0: the fill byte
  LDIR
  RET

; Paint every cell of the colour-cycle list in the pass counter's ink, bright
;
; Main loop (every pass, c1: 3260). For each (column, row) of ColourCycleList:
; the attribute at $5800 + 32 row + column = BRIGHT + ink (pass counter $768C
; AND 7), paper 0. The cells come from the screen builder: an element printed a
; 4 into the map $6100 there (record 4 of $8EF4, the map cell then set to 0).
;
; Screen 0: 6 cells (0,8) (5,8) (10,8) (4,11) (5,11) (6,11); screens 2, 6, 8: 8
; cells, the pillars of the two teleport booths (t1 at frame 1000: the booth
; pillars of screen 14 blink through the inks).
ColourCycle:
  LD HL,ColourCycleList
ColourCycleLoop:
  LD E,(HL)               ; E = column, bit 7 set: the end mark
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  PUSH HL
  CALL CellOffset         ; HL = 32 row + column
  LD DE,$5800
  ADD HL,DE
  LD A,(PassCount)        ; the ink from the pass counter
  AND $07
  OR $40
  LD (HL),A
  POP HL
  JR ColourCycleLoop

; Up to 14 cells (column, row) of the colour cycle; $FF after the last
;
; Filled by $8E86 / $8EAD from the map (map value 4), emptied ($FF in the first
; byte) by $8E86 at each screen build. The ROM image holds zeros.
ColourCycleList:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $FF                ; the fixed end mark (a full list of 14)
