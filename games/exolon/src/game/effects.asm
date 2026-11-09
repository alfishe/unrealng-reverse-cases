; --------------------------------------------------------------------------------------------------------------------
; effects.asm: The small XOR sprites and their wall probes, the grenade blast, the debris, the puffs
; --------------------------------------------------------------------------------------------------------------------

; XOR an 8 x 8 sprite, pre-shifted, at a pixel position
;
; In: A = the frame, E = X in 2-pixel units (0-127), D = Y in pixels. Every
; register is kept. The frame is 64 bytes at $ED40 + 64 A: four copies shifted
; by 0, 2, 4 and 6 pixels (E AND 3), 16 bytes each, 2 bytes a pixel line, 8
; lines. $B088 gives the screen address of the line; the bytes are read with
; POP (SP saved at $78DA), two lines per loop, the screen address moved down a
; line in the Spectrum layout (C = 7 the line mask).
;
; Each call adds 1 to $9E98, the sprites drawn this pass ($9E85 pads the pass
; with more draws, the main loop clears it). Frames seen in the code: 0 / 1 the
; grenade facing right / left, 2 a debris piece, 3-5 the puff, 6 blank, 7 the
; ball, 8 the gun's shot (the frames are SmallSprites $ED40 in the image: 24
; sprites of 4 pre-shifted 16-byte copies, up to $EF7F).
;
; c1: 52 160 calls, the most called routine of this range.
DrawSmallSprite:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  CALL PixelAddress
  PUSH HL
  ADD A,A
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,E
  AND $03
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD BC,SmallSprites
  ADD HL,BC
  POP DE
  LD (SpriteSavedSP),SP   ; SP = the frame's bytes
  LD SP,HL
  EX DE,HL
  LD BC,$0407             ; B = 4 pairs of lines, C = 7
DrawSmallSpriteLoop:
  POP DE                  ; line 1: left byte, right byte
  LD A,E
  XOR (HL)
  LD (HL),A
  INC L
  LD A,D
  XOR (HL)
  LD (HL),A
  INC H                   ; the next line down
  LD A,H
  AND C
  JR NZ,DrawSmallSpriteLine2
  LD A,L
  ADD A,$20
  LD L,A
  JR C,DrawSmallSpriteLine2
  LD A,H
  SUB $08
  LD H,A
DrawSmallSpriteLine2:
  POP DE                  ; line 2: the right byte first, back to the left
  LD A,D
  XOR (HL)
  LD (HL),A
  DEC L
  LD A,E
  XOR (HL)
  LD (HL),A
  INC H
  LD A,H
  AND C
  JR NZ,DrawSmallSpriteNext
  LD A,L
  ADD A,$20
  LD L,A
  JR C,DrawSmallSpriteNext
  LD A,H
  SUB $08
  LD H,A
DrawSmallSpriteNext:
  DJNZ DrawSmallSpriteLoop ; the next pair
  LD SP,(SpriteSavedSP)
  LD HL,XorSpriteCount    ; one more sprite drawn this pass
  INC (HL)
  POP HL
  POP DE
  POP BC
  POP AF
  RET

; The map cells to the right of an 8 x 8 object
;
; In: E = X (2-pixel units), D = Y. Out: A = the map ($6100) byte of the cell
; right of the object's cell, OR the one below it when Y is not on a cell line;
; 0 when X is not on a cell column (the object is between cells, nothing to
; meet). NZ = blocked. BC, DE, HL kept. Callers: MoveGrenade, MoveBalls, the
; player's shots $83DD.
ProbeRight:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,E
  AND $03
  LD A,$00
  JR NZ,ProbeRightDone
  CALL BlockMapCell
  INC L                   ; the next cell right
  LD BC,$0020
  LD A,(HL)
  LD E,A
  LD A,D
  AND $07
  LD A,E
  JR Z,ProbeRightDone
  ADD HL,BC               ; Y between rows: the cell below as well
  OR (HL)
ProbeRightDone:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; The map cells to the left of an 8 x 8 object
;
; As ProbeRight with the cell on the left (L - 1). Callers: GrenadeLeftWall,
; MoveBalls, $83DD.
ProbeLeft:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,E
  AND $03
  LD A,$00
  JR NZ,ProbeLeftDone
  CALL BlockMapCell
  DEC L
  LD BC,$0020
  LD A,(HL)
  LD E,A
  LD A,D
  AND $07
  LD A,E
  JR Z,ProbeLeftDone
  ADD HL,BC
  OR (HL)
ProbeLeftDone:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; The map cells under an 8 x 8 object
;
; In: E = X, D = Y. Out: A = the map byte of the cell under the object, OR the
; one under its right neighbour when X is not on a cell column; 0 when Y is not
; on a cell line. Callers: MoveGrenade, MoveBalls.
ProbeBelow:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,D
  AND $07
  LD A,$00
  JR NZ,ProbeBelowDone
  CALL BlockMapCell
  LD BC,$0020
  ADD HL,BC
  LD A,(HL)
  LD D,A
  LD A,E
  AND $03
  LD A,D
  JR Z,ProbeBelowDone
  INC L
  OR (HL)
ProbeBelowDone:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; The map cells above an 8 x 8 object
;
; As ProbeBelow one row up (HL - 32). Caller: MoveBalls (a ball going up).
ProbeAbove:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,D
  AND $07
  LD A,$00
  JR NZ,ProbeAboveDone
  CALL BlockMapCell
  LD BC,$FFE0
  ADD HL,BC
  LD A,(HL)
  LD D,A
  LD A,E
  AND $03
  LD A,D
  JR Z,ProbeAboveDone
  INC L
  OR (HL)
ProbeAboveDone:
  OR A
  POP HL
  POP DE
  POP BC
  RET

; The grenade's end: destroy the destructible scenery piece it is in
;
; In: E = X, D = Y of the grenade. Turns them into a cell (column = X / 4, row
; = Y / 8) and walks DestructibleList: the first record whose box holds the
; cell (x0 <= column < x1, y0 <= row < y1) and is not destroyed ($80) is: its
; element (the scenery string of $852E, the element number at +6) printed again
; at its place with printer 3 (XorDebrisPrinter: XOR erases it, every character
; throws two debris pieces and clears its cells in the maps), the record marked
; $80, the explosion sound $C148, 150 points ($ADA9: "000150", AddScore $AD53).
;
; A grenade that hits no such box ends silently. c128: 3 ends, x2 9 hits over
; 14 throws, 55 warp clones destroyed one.
GrenadeBlast:
  LD A,E
  AND $7C
  RRCA
  RRCA
  LD E,A
  LD A,D
  AND $F8
  RRCA
  RRCA
  RRCA
  LD D,A
  LD HL,DestructibleList  ; DE = (row, column)
BlastLoop:
  LD A,(HL)               ; $FF: the end; $80: destroyed already
  CP $FF
  RET Z
  CP $80
  PUSH HL
  JR Z,BlastNext
  LD A,E                  ; column in x0..x1-1, row in y0..y1-1
  CP (HL)
  INC HL
  JR C,BlastNext
  CP (HL)
  INC HL
  JR NC,BlastNext
  LD A,D
  CP (HL)
  INC HL
  JR C,BlastNext
  CP (HL)
  INC HL
  JR NC,BlastNext
  LD E,(HL)               ; DE = the element's place, A = the element
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  LD BC,ElementTable
  CALL TableWord
  LD A,$03                ; printer 3 (XOR + debris)
  CALL SetPrinter
  CALL PrintString
  XOR A
  CALL SetPrinter
  POP HL
  LD (HL),$80             ; the piece destroyed
  CALL PlaySfxBlast
  LD DE,Points150+$0005   ; 150 points
  JP AddScore
BlastNext:
  POP HL                  ; the next record (7 bytes)
  LD BC,$0007
  ADD HL,BC
  JR BlastLoop

; The grenade-destructible scenery pieces of the screen: 7-byte records, $FF
; after the last
;
; Written by AddDestructible while the screen builder $8494 prints the elements
; (IX from $9437, $FF written after the last by $850A). A record: +0 x0, +1 x1
; (columns, the box's left and its right + 1), +2 y0, +3 y1 (rows), +4 the
; element's column, +5 its row, +6 the element number. +0 = $80: destroyed. The
; ROM image holds zeros; 80 bytes: 11 records and 3 spare.
DestructibleList:
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00

; A scenery element of a destructible kind gets a box in DestructibleList
;
; Called by the screen builder ($84EF) for each element of the screen with A =
; the element, E = its column, D = its row, IX = the next free record. A kind
; found in DestructibleKinds writes the record (the box from the kind's offsets
; and sizes) and moves IX on by 7. AF, BC, HL kept.
;
; c1: 36 elements over its 4 builds of screen 0 (9 a build), 8 destructible (2
; a build: the turret and the spire).
AddDestructible:
  PUSH AF
  PUSH BC
  PUSH HL
  LD HL,DestructibleKinds
AddDestructibleLoop:
  BIT 7,(HL)              ; bit 7: the table's end
  JR NZ,AddDestructibleDone
  CP (HL)
  JR Z,AddDestructibleRecord
  LD BC,$0005
  ADD HL,BC
  JR AddDestructibleLoop
AddDestructibleDone:
  POP HL
  POP BC
  POP AF
  RET
AddDestructibleRecord:
  LD (IX+$06),A           ; a destructible kind: the record
  LD (IX+$04),E
  LD (IX+$05),D
  INC HL
  LD A,(HL)
  ADD A,E
  LD (IX+$00),A
  INC HL
  ADD A,(HL)
  LD (IX+$01),A
  INC HL
  LD A,(HL)
  ADD A,D
  LD (IX+$02),A
  INC HL
  ADD A,(HL)
  LD (IX+$03),A
  LD BC,$0007
  ADD IX,BC
  POP HL
  POP BC
  POP AF
  RET

; The 10 destructible element kinds: element, dx, width, dy, height; $FF ends
;
; The box of an element at (column, row): x0 = column + dx, x1 = x0 + width, y0
; = row + dy, y1 = y0 + height (signed offsets). Elements $05, $0D, $0F, $10,
; $12, $15, $1F, $28, $2C, $2E.
DestructibleKinds:
  DEFB $05,$FF,$08,$FE,$05
  DEFB $0D,$FD,$05,$FE,$0A
  DEFB $0F,$FE,$07,$FF,$09
  DEFB $10,$FE,$06,$FE,$08
  DEFB $12,$FA,$0B,$01,$07
  DEFB $15,$FE,$07,$FE,$08
  DEFB $1F,$FF,$06,$FE,$06
  DEFB $28,$FF,$06,$FE,$08
  DEFB $2C,$FF,$08,$FE,$04
  DEFB $2E,$FF,$05,$FE,$06
  DEFB $FF                ; the end mark

; Start one debris piece flying from a character cell
;
; Called twice per character by XorDebrisPrinter $AE95 (printer 3: the mine
; blast, the grenade blast). In: D = row, E = column, C = the attribute (the
; printer's colour). Takes the first free record of DebrisList (state 0; none
; free: nothing): state 1, X = 4 column, Y = 8 row, dx and dy from DebrisSpeeds
; by random numbers (dy doubled; drawn again until not both 0), draws frame 2
; there, colour C AND $47.
;
; c128: 98 pieces, x2 370.
AddDebris:
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH BC
  LD BC,$0006
  LD HL,DebrisList
DebrisFindSlot:
  LD A,(HL)               ; state 0: free; $FF: the end (full)
  OR A
  JR Z,DebrisSlotFound
  CP $FF
  JR Z,AddDebrisDone
  ADD HL,BC
  JR DebrisFindSlot
DebrisSlotFound:
  LD (HL),$01             ; the record
  INC HL
  LD A,E
  RLCA
  RLCA
  LD E,A
  LD (HL),E
  INC HL
  LD A,D
  RLCA
  RLCA
  RLCA
  LD D,A
  LD (HL),D
  INC HL
  CALL Random             ; dx
  AND $07
  CALL DebrisSpeed
  LD (HL),A
  LD C,A
  INC HL
DebrisDy:
  CALL Random             ; dy = 2 x a speed, not both 0
  AND $07
  CALL DebrisSpeed
  ADD A,A
  LD B,A
  OR C
  JR Z,DebrisDy
  LD (HL),B
  LD A,$02                ; frame 2
  CALL DrawSmallSprite
  POP BC
  PUSH BC
  INC HL
  LD A,C                  ; the colour: ink and bright of C
  AND $47
  LD (HL),A
AddDebrisDone:
  POP BC
  POP HL
  POP DE
  POP AF
  RET

; A = DebrisSpeeds[A] (A = 0-7)
;
; HL and BC kept.
DebrisSpeed:
  PUSH HL
  PUSH BC
  LD L,A
  LD H,$00
  LD BC,DebrisSpeeds
  ADD HL,BC
  LD A,(HL)
  POP BC
  POP HL
  RET

; The debris speeds: -4, -3, -2, 0, 0, 2, 3, 4
DebrisSpeeds:
  DEFB $FC,$FD,$FE,$00,$00,$02,$03,$04

; Move every debris piece; a beeper crackle on the 48K
;
; Main loop, every pass (c1: 3260, empty). For each piece of state 1: frame 2
; erased at (X, Y), X + dx (gone at $78 and more), Y + dy (gone at $A9 and
; more), drawn again, its cells painted in its colour ($7C77). On a 48K (flag
; $6E16 = 0) each moved piece also sends X x 8 AND $F8 to port $FE: bit 3 (MIC)
; and bit 4 (speaker) from X's bits 0-1, border black: the crackle of the
; debris. On a 128K the OUT is skipped (the AY branch at $9597; c128 ran $95A5
; 1134 times, never $959D).
;
; A piece leaves at the play area's edges only; it flies through walls.
MoveDebris:
  LD HL,DebrisList
MoveDebrisLoop:
  LD A,(HL)               ; $FF: the end; 1: a flying piece
  CP $FF
  RET Z
  CP $01
  JR Z,DebrisMove
  LD BC,$0006
  ADD HL,BC
  JR MoveDebrisLoop
DebrisMove:
  PUSH HL                 ; the record's X / Y, erased
  INC HL
  PUSH HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,$02
  CALL DrawSmallSprite
  INC HL
  LD A,E                  ; X + dx; off the right edge: gone
  ADD A,(HL)
  LD E,A
  CP $78
  JR NC,DebrisGone
  INC HL
  LD A,D                  ; Y + dy; off the bottom: gone
  ADD A,(HL)
  LD D,A
  CP $A9
  JR NC,DebrisGone
  INC HL
  LD C,(HL)
  POP HL                  ; stored, drawn, painted
  LD (HL),E
  INC HL
  LD (HL),D
  LD A,$02
  CALL DrawSmallSprite
  CALL ColourCell
DebrisSound:
  LD A,(SoundIsAy)        ; the AY branch: a 128K skips the beeper
  OR A
  JR NZ,MoveDebrisNext
  LD A,E                  ; the beeper: X's low bits to MIC and the speaker
  RLCA
  RLCA
  RLCA
  AND $F8
  OUT ($FE),A
MoveDebrisNext:
  POP HL
  LD BC,$0006
  ADD HL,BC
  JR MoveDebrisLoop
DebrisGone:
  POP HL                  ; state 0
  POP HL
  LD (HL),$00
  LD BC,$0006
  ADD HL,BC
  JR MoveDebrisLoop

; 100 debris pieces of 6 bytes: state, X, Y, dx, dy, colour; $FF ends
;
; Cleared by ClearDebris at each screen build. The ROM image holds zeros.
DebrisList:
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $FF                ; the end mark

; Clear the debris list (600 bytes)
;
; Called by the screen builder $8494.
ClearDebris:
  LD HL,DebrisList
  LD DE,DebrisList+$0001
  LD BC,$0257
  LD (HL),$00
  LDIR
  RET

; Start an explosion puff at a position
;
; In: E = X, D = Y (the small-sprite position). Takes the first record of
; PuffList with timer 0 and writes X, Y and the timer 10; the list full:
; nothing. HL kept. Callers: MoveGrenade (the trail), the player's shots at a
; wall ($83DD), BallHit, the gun shots hit ($9E4F), the teleport sparkle $9EEE,
; $AC7D.
AddPuff:
  PUSH HL
  LD HL,PuffList
AddPuffLoop:
  BIT 7,(HL)              ; $FF: the end
  JR NZ,AddPuffDone
  INC HL
  INC HL
  LD A,(HL)
  OR A
  INC HL
  JR NZ,AddPuffLoop
  DEC HL
  LD (HL),$0A
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
AddPuffDone:
  POP HL
  RET

; One frame step of every puff
;
; Main loop, every pass (c1: 3260, empty). For each puff with a timer t (10
; down to 1): t - 1 stored, frame PuffFrames[t] XORed (it erases last pass's
; frame) then PuffFrames[t - 1] drawn, the cells painted in a random bright ink
; with bit 1 set (LD A,R). Frames by pass: 3, 4, 5, 3, 5, 4, 5, 5, 5 and blank
; (6): the first pass's XOR of frame 6 and the last's are on a blank frame, so
; nothing is left.
;
; x2: 1955 puffs started.
AnimatePuffs:
  LD HL,PuffList
AnimatePuffsLoop:
  LD E,(HL)               ; $FF: the end; timer 0: free
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,AnimatePuffsLoop
  PUSH HL
  DEC HL                  ; the timer counted down
  DEC (HL)
  LD L,A                  ; HL = $9864 + t
  LD H,$00
  LD BC,PuffFrames-$0001
  ADD HL,BC
  INC HL
  LD A,(HL)
  CALL DrawSmallSprite
  DEC HL
  LD A,(HL)
  CALL DrawSmallSprite
  LD A,R                  ; a random ink
  AND $07
  OR $42
  LD C,A
  CALL ColourCell
  POP HL
  JR AnimatePuffsLoop

; The puff's frames by timer: index t at $9865 + t - 1 (t = 1-11)
;
; Read as $9864 + t + 1 and $9864 + t (LD BC,$9864 at $984A).
PuffFrames:
  DEFB $06,$05,$05,$05,$04,$05,$03,$05,$04,$03,$06

; 20 puffs (X, Y, timer); $FF ends
;
; Cleared by ClearPuffs at each screen build.
PuffList:
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
  DEFB $FF                ; the end mark

; Clear the puff list (60 bytes)
;
; Called by the screen builder $8494.
ClearPuffs:
  LD HL,PuffList
  LD DE,PuffList+$0001
  LD BC,$003B
  LD (HL),B
  LDIR
  RET
