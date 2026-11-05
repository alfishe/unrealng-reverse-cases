; --------------------------------------------------------------------------------------------------------------------
; objutil.asm: the end of an enemy, the wave bonus, the scenery tests and the playfield clamps
;
; An enemy leaves play in two ways: it flies off the playfield (EnemyEscaped) or it is destroyed (EnemyKilled). Both
; count the wave down; when the last object of a wave is gone the wave record is freed and $8073 lets the next wave
; in, and only a wave none of whose objects escaped pays its bonus (score index + 7 through $A489) and leaves its drop
; type in +$26 (bits 6-7 of the wave's bonus byte), which the explosion code turns into a pod.
;
; The scenery is a map of one byte a cell, 128 cells a row, from the word $8022 (the scroll position): SceneryCell
; gives the cell under the object's top-left corner, the SceneryAt routines OR 1, 2, 4 or 6 cells (2 wide, 1 to 3
; rows) and return carry when any is not 0.
; --------------------------------------------------------------------------------------------------------------------

; an enemy slot back: $8072 + 1, its bit out of $80BD/$80BE
;
; Its collision bit (+$24) is cleared from the masks $80BD and $80BE (the
; harmless enemies, set at $8D1A and by $A2C4/$A30E) and the slot deactivated.
; Used by the enemy handlers and $A1C8, $A1FD, $A2D6. 26 entries in 48K c2.
FreeEnemySlot:
  LD HL,FreeEnemySlots
  INC (HL)
  LD A,(IY+$24)
  CPL
  LD C,A
  LD HL,HarmlessMaskA
  AND (HL)
  LD (HL),A
  INC HL
  LD A,C
  AND (HL)
  LD (HL),A
  RES 7,(IY+$08)
  RET

; deactivate the object and $8074 + 1
;
; Used by $A263 (the kind 5 handler); $8074 is set at $8D0D and read at $A113.
; 1 entry in 48K c2.
FreeObject:
  RES 7,(IY+$08)
  LD HL,EnemyShotsLeft
  INC (HL)
  RET

; the object left the playfield: count its wave down, no bonus
;
; C = $FF: the wave record gets bit 7 (an escape), so the wave pays no bonus. 7
; entries in 48K c2.
EnemyEscaped:
  LD C,$FF
  JR EnemyGone

; the object was destroyed: count its wave down
;
; +$26 = 0 (no drop), C = 0, then EnemyGone. 9 entries in 48K c2.
EnemyKilled:
  LD (IY+$26),$00
  LD C,$00

; EnemyGone
;
; Used by the routine at EnemyEscaped.
EnemyGone:
  LD L,(IY+$00)           ; the sprite descriptor's use count - 1 when +$23
                          ; matches its +$0F
  LD H,(IY+$01)
  LD DE,$000F
  ADD HL,DE
  LD A,(HL)
  CP (IY+$23)
  JR NZ,EnemyGoneWave
  DEC HL
  DEC HL
  DEC (HL)                ; the use count - 1; 0: the sprite's record bit out
                          ; of $8087
  JR NZ,EnemyGoneWave
  AND $0F
  CPL
  LD HL,SpriteCacheMask
  AND (HL)
  LD (HL),A
EnemyGoneWave:
  LD A,(IY+$1A)           ; the wave record $8075 + 3 x +$1A
  LD L,A
  ADD A,A
  ADD A,L
  LD E,A
  LD D,$00
  LD HL,WaveRecords
  ADD HL,DE
  BIT 7,C
  JR Z,EnemyGoneCount
  SET 7,(HL)
EnemyGoneCount:
  DEC (HL)                ; count - 1; 0: the wave is over
  LD A,(HL)
  AND $7F
  RET NZ
  LD A,(WavesAllowed)     ; the wave is over: $8073 + 1, the record free ($FF);
                          ; an escape (bit 7): no bonus
  INC A
  LD (WavesAllowed),A
  LD A,(HL)
  LD (HL),$FF
  BIT 7,A
  RET NZ
  INC HL
  LD A,(HL)
  AND $C0
  RLCA
  RLCA
  LD (IY+$26),A
  LD A,(HL)
  AND $3F
  RET Z
  ADD A,$07
  CALL AddScore           ; the whole wave destroyed: the bonus score
  RET

; carry if the cell under the object is not empty
;
; Used by PlasmaHandler, SeekerHandler and $A263. 18 entries in 48K c2.
SceneryAt1:
  CALL SceneryCell
  LD A,(HL)
  CP $01
  CCF
  RET

; carry if one of the 2 cells (X, X + 1) is not empty
;
; Used by LaserHandler (869 entries in 48K c2).
SceneryAt2:
  CALL SceneryCell
  LD A,(HL)
  INC L
  OR (HL)
  CP $01
  CCF
  RET

; carry if one of 2 x 2 cells is not empty
;
; Used by $A2D6. 2 entries in 48K c2.
SceneryAt4:
  CALL SceneryCell
  LD A,(HL)
  INC L
  OR (HL)
  LD E,A
  LD A,L
  ADD A,$80
  LD L,A
  BIT 0,(IY+$06)
  JR Z,SceneryAt4Row
  INC H
SceneryAt4Row:
  LD A,E                  ; the second row
  OR (HL)
  DEC L
  OR (HL)
  CP $01
  CCF
  RET

; carry if one of 2 x 3 cells is not empty
;
; The ship's and most movers' test: rows Y, Y + 1, Y + 2 of columns X and X + 1
; (a row is 128 bytes: + $80, with the carry into H on every second row). 1227
; entries in 48K c2.
SceneryAt6:
  CALL SceneryCell
  LD A,(HL)
  INC L
  OR (HL)
  LD E,A
  LD A,L
  ADD A,$80
  LD L,A
  BIT 0,(IY+$06)
SceneryAt6Row2:
  JR Z,SceneryAt6Row2Test ; the second row (an entry point of the L1 recording:
                          ; the interrupt returned here)
  INC H
SceneryAt6Row2Test:
  LD A,E                  ; the cells of row Y + 1
  OR (HL)
  DEC L
  OR (HL)
  LD E,A
  LD A,L
  ADD A,$80
  LD L,A
  BIT 0,(IY+$06)
  JR NZ,SceneryAt6Row3
  INC H
SceneryAt6Row3:
  LD A,E                  ; the cells of row Y + 2
  OR (HL)
  INC L
  OR (HL)
  CP $01
  CCF
  RET

; HL = the scenery cell of the object IY
;
; HL = ($8022) + Y x 128 + X with the integer parts +$06 and +$04. 2118 entries
; in 48K c2.
SceneryCell:
  LD DE,(ScrollMap)
  LD H,(IY+$06)
  XOR A
  SRL H
  RRA
  OR (IY+$04)
  ADD A,E
  LD L,A
  LD A,H
  ADD A,D
  LD H,A
  RET

; keep the object in rows 0-15
;
; A negative row: Y = 0.0; 16 or more: Y = 15 + $E0/256. 2028 entries in 48K
; c2.
ClampRow:
  LD A,(IY+$06)
  AND A
  JP P,ClampRowBottom
  LD (IY+$06),$00
  LD (IY+$05),$00
  RET
ClampRowBottom:
  CP $10                  ; 16 or more: the bottom row
  RET C
  LD (IY+$06),$0F
  LD (IY+$05),$E0
  RET

; keep the player in columns 16-45
;
; Below 16: X = 16.0; 46 or more: X = 45 + $E0/256. Only the player uses it
; (613 entries in 48K c2).
ClampColumn:
  LD A,(IY+$04)
  SUB $10
  JP P,ClampColumnRight
  LD (IY+$04),$10
  LD (IY+$03),$00
  RET
ClampColumnRight:
  CP $1E                  ; the right edge
  RET C
  LD (IY+$04),$2D
  LD (IY+$03),$E0
  RET

; the next ink colour 1-7 in +$25 (bits 3-5)
;
; The flash of the missiles, the plasma and the hit big enemy. Not run in 48K
; c1/c2; 48K r1 (all levels) runs it: 291 entries.
CycleColour:
  LD A,(IY+$25)
  ADD A,$08
  AND $38
  JR NZ,CycleColourSet
  ADD A,$08
CycleColourSet:
  LD (IY+$25),A           ; 0 skipped
  RET
