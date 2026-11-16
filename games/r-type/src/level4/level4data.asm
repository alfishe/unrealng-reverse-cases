; --------------------------------------------------------------------------------------------------------------------
; level4data.asm: Level 4
;
; The level's body: the header the game reads at $C4AE, the sprites, the object table, the metatiles, the map, the
; wave script, the enemy kinds and their movement scripts, the two mover tables and the movers.
; --------------------------------------------------------------------------------------------------------------------

; The level header: restart point, checkpoints and the pointers the game reads
;
; Restart column $00, restart wave $0000; checkpoint columns $00, $29, $FF with
; wave entries $E693, $E80F, $EABC; objects $DB15, map $E521, kinds $EF8A,
; movers $F2AE and $F2CE.
L4Header:
  DEFB $00
L4RestartWave:
  DEFB $00,$00            ; the wave entry a life restarts at (the game keeps
                          ; its live copy here)
L4Checks:
  DEFB $00,$29,$FF        ; three checkpoint columns (CheckRestart)
L4WaveStarts:
  DEFB $93,$E6,$0F,$E8,$BC,$EA ; the wave entries of the start and the
                               ; checkpoints
L4Pointers:
  DEFB $15,$DB,$21,$E5,$8A,$EF,$AE,$F2 ; objects, map, kinds, movers 1, movers
  DEFB $CE,$F2                         ; 2

; zeros up to the sprites
L4Spare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object
; table points at
L4Sprites:
  INCBIN "res/levels/level4/sprites.bin",$0000,5685

; The level's object table: width, height, the cells' address (LevelObject)
L4Objects:
  INCBIN "res/levels/level4/objects.bin",$0000,412

; The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from
; the map: metatile n at $E521 - 144 x (n + 1) (MetatileAddress); 15 of them
L4Metatiles:
  INCBIN "res/levels/level4/metatiles.bin",$0000,2160

; The map: 5 bytes a block column (74 columns), each byte a metatile (bits 0-5)
; and its drawer (bits 6-7)
L4Map:
  INCBIN "res/levels/level4/map.bin",$0000,370

; The wave script: entries (scroll position, kind, script) RunWaves starts;
; then the enemies' movement scripts
L4Waves:
  INCBIN "res/levels/level4/waves.bin",$0000,2295

; The enemy kinds StartWave reads (LevelKinds)
L4Kinds:
  DEFB $C1,$EA,$C8,$EA,$D5,$EA,$D5,$EA
  DEFB $E2,$EA,$0F,$EB,$1E,$EB,$2D,$EB
  DEFB $3C,$EB,$4B,$EB,$52,$EB,$59,$EB
  DEFB $64,$EB,$6F,$EB,$7E,$EB,$8D,$EB
  DEFB $AE,$EB,$C7,$EB,$D8,$EB,$F7,$EB
  DEFB $14,$EC,$23,$EC,$34,$EC,$41,$EC
  DEFB $4E,$EC,$7B,$EC,$8E,$EC,$A7,$EC
  DEFB $C2,$EC,$DB,$EC,$E6,$EC,$F5,$EC
  DEFB $0A,$ED,$0F,$ED,$14,$ED,$27,$ED
  DEFB $2C,$ED,$3B,$ED,$50,$ED,$55,$ED
  DEFB $5A,$ED,$69,$ED,$06,$EE,$A7,$EE
  DEFB $4C,$EF,$59,$EF,$59,$EF,$59,$EF
  DEFB $60,$EF,$67,$EF,$6E,$EF,$75,$EF
  DEFB $7C,$EF,$83,$EF,$0C,$80,$0B,$80
  DEFB $0A,$80,$37,$10,$38,$18,$39,$10
  DEFB $38,$14,$37,$14,$38,$10,$39,$18
  DEFB $38,$90,$34,$04,$34,$04,$34,$04
  DEFB $34,$04,$34,$04,$34,$04,$34,$04
  DEFB $34,$84,$34,$0A,$34,$0A,$34,$0A
  DEFB $34,$0A,$34,$0A,$34,$0A,$34,$0A
  DEFB $34,$8A,$36,$11,$36,$11,$36,$11
  DEFB $36,$11,$36,$11,$36,$11,$36,$11
  DEFB $36,$91,$36,$20,$36,$20,$36,$20
  DEFB $36,$20,$36,$20,$36,$20,$36,$20
  DEFB $36,$A0,$35,$15,$35,$15,$35,$15
  DEFB $35,$15,$35,$15,$35,$15,$35,$15
  DEFB $35,$95,$35,$24,$35,$24,$35,$24
  DEFB $35,$24,$35,$24,$35,$24,$35,$24
  DEFB $35,$A4,$35,$1B,$35,$1B,$35,$1B
  DEFB $35,$1B,$35,$1B,$35,$1B,$35,$1B
  DEFB $35,$9B,$35,$2A,$35,$2A,$35,$2A
  DEFB $35,$2A,$35,$2A,$35,$2A,$35,$2A
  DEFB $35,$AA,$20,$20,$20,$22,$20,$20
  DEFB $20,$22,$20,$20,$20,$22,$20,$20
  DEFB $20,$A2,$31,$00,$31,$08,$31,$01
  DEFB $31,$89,$31,$02,$31,$06,$31,$03
  DEFB $31,$87,$2E,$00,$2E,$20,$2E,$02
  DEFB $2E,$A2,$2E,$01,$2E,$11,$2E,$03
  DEFB $2E,$93,$23,$08,$23,$08,$23,$08
  DEFB $23,$08,$23,$08,$23,$08,$23,$08
  DEFB $23,$08,$22,$18,$22,$18,$22,$98
  DEFB $21,$10,$21,$10,$21,$10,$21,$10
  DEFB $21,$10,$21,$90,$1C,$10,$1D,$10
  DEFB $1C,$10,$1E,$10,$1C,$10,$1D,$10
  DEFB $1C,$10,$1E,$90,$1C,$21,$1D,$21
  DEFB $1C,$21,$1E,$21,$1C,$21,$1D,$21
  DEFB $1C,$21,$1E,$A1,$1F,$08,$1F,$08
  DEFB $1F,$08,$1F,$08,$1F,$88,$1E,$00
  DEFB $1E,$80,$1F,$14,$1F,$10,$1F,$98
  DEFB $1F,$09,$1F,$09,$1F,$09,$1F,$89
  DEFB $1E,$01,$1E,$81,$1F,$25,$1F,$21
  DEFB $1F,$A9,$09,$18,$09,$18,$09,$18
  DEFB $09,$18,$09,$98,$09,$10,$09,$10
  DEFB $09,$10,$09,$90,$09,$14,$09,$14
  DEFB $09,$14,$09,$14,$09,$94,$07,$10
  DEFB $05,$10,$07,$10,$06,$10,$07,$10
  DEFB $05,$10,$07,$10,$06,$90,$08,$00
  DEFB $08,$80,$08,$01,$08,$81,$09,$25
  DEFB $09,$25,$09,$25,$09,$A5,$09,$21
  DEFB $09,$A1,$08,$00,$08,$00,$08,$00
  DEFB $08,$10,$08,$00,$08,$00,$08,$00
  DEFB $08,$10,$08,$00,$08,$00,$08,$00
  DEFB $08,$10,$08,$00,$08,$00,$08,$00
  DEFB $08,$90,$13,$00,$14,$00,$14,$80
  DEFB $15,$00,$14,$00,$14,$80,$13,$80
  DEFB $15,$80,$0E,$10,$0F,$10,$10,$10
  DEFB $0F,$10,$0E,$10,$0F,$10,$10,$10
  DEFB $0F,$90,$0E,$21,$0F,$21,$10,$21
  DEFB $0F,$21,$0E,$21,$0F,$21,$10,$21
  DEFB $0F,$A1,$11,$00,$11,$80,$11,$01
  DEFB $11,$81,$12,$00,$12,$00,$12,$00
  DEFB $12,$00,$12,$00,$12,$80,$12,$01
  DEFB $12,$01,$12,$01,$12,$01,$12,$01
  DEFB $12,$81,$0E,$00,$0E,$00,$0E,$00
  DEFB $0E,$80,$0E,$01,$0E,$01,$0E,$01
  DEFB $0E,$81,$2A,$04,$2A,$04,$2A,$04
  DEFB $2A,$84,$2A,$0A,$2A,$0A,$2A,$0A
  DEFB $2A,$0A,$2A,$8A,$2B,$14,$2C,$10
  DEFB $2C,$10,$2B,$9A,$2B,$14,$2B,$14
  DEFB $2C,$10,$2C,$10,$2B,$1A,$2B,$9A
  DEFB $2B,$25,$2C,$21,$2C,$21,$2B,$AB
  DEFB $2B,$25,$2B,$25,$2C,$21,$2C,$21
  DEFB $2B,$2B,$2B,$AB,$19,$04,$19,$04
  DEFB $19,$04,$19,$04,$19,$04,$19,$04
  DEFB $19,$04,$19,$84,$19,$08,$19,$08
  DEFB $19,$08,$19,$08,$19,$08,$19,$08
  DEFB $19,$08,$19,$88,$19,$10,$19,$10
  DEFB $19,$10,$19,$10,$19,$10,$19,$10
  DEFB $19,$10,$19,$90,$19,$20,$19,$20
  DEFB $19,$20,$19,$20,$19,$20,$19,$20
  DEFB $19,$20,$19,$A0,$19,$14,$19,$14
  DEFB $19,$14,$19,$14,$19,$14,$19,$14
  DEFB $19,$14,$19,$94,$19,$24,$19,$24
  DEFB $19,$24,$19,$24,$19,$24,$19,$24
  DEFB $19,$24,$19,$A4,$19,$18,$19,$18
  DEFB $19,$18,$19,$18,$19,$18,$19,$18
  DEFB $19,$18,$19,$98,$19,$28,$19,$28
  DEFB $19,$28,$19,$28,$19,$28,$19,$28
  DEFB $19,$28,$19,$A8,$19,$00,$19,$00
  DEFB $19,$00,$19,$00,$19,$00,$19,$00
  DEFB $19,$00,$19,$80

; The first mover of each kind (16 words, LevelMoves)
L4MoversA:
  DEFW L4MoverA0
  DEFW L4MoverA1
  DEFW L4MoverA2
  DEFW L4MoverA3
  DEFW L4MoverA4
  DEFW L4MoverA5
  DEFW L4MoverA6
  DEFW L4MoverA7
  DEFW L4MoverA8
  DEFW L4MoverA9
  DEFW L4MoverA9
  DEFW L4MoverA11
  DEFW L4MoverA12
  DEFW L4MoverA13
  DEFW L4MoverA14
  DEFW L4MoverA15

; The second mover of each kind (16 words, LevelMoves2)
L4MoversB:
  DEFW L4MoverB0
  DEFW L4MoverB1
  DEFW L4MoverB2
  DEFW L4MoverB3
  DEFW L4MoverB4
  DEFW L4MoverB5
  DEFW L4MoverB6
  DEFW L4MoverB6
  DEFW L4MoverB8
  DEFW L4MoverB9
  DEFW L4MoverB10
  DEFW L4MoverB10
  DEFW L4MoverB9
  DEFW L4MoverB13
  DEFW L4MoverB14
  DEFW L4MoverB15

; Mover A0
;
; Witness: L1 161 (l4).
L4MoverA0:
  JP C,MoveNext
  JP MoveStore

; Mover A1
;
; Witness: L1 273 (l4).
L4MoverA1:
  JP C,MoveNext
; This entry point is used by the routines at L4MoverA2, L4MoverA9, L4MoverA11,
; L4MoverA12 and L4MoverA14.
l_F2F7:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveStore
  JP MoveDraw

; Mover A2
;
; Witness: L1 558 (l4).
L4MoverA2:
  JR NC,l_F2F7
  JP MoveNext

; Mover A3
;
; Witness: L1 59 (l4).
L4MoverA3:
  LD HL,$1401
  LD A,$14
  SUB B
  LD H,A
; This entry point is used by the routines at L4MoverA4 and L4MoverA5.
l_F30E:
  LD A,$FA
  LD (DrawTag),A
  DEC C
  LD A,$44
  CALL ClearCellsTag
  INC C
  LD A,$20
  CALL SetDrawLimitA
  CALL SoftCellsOn
  JP MoveStore

; Mover A4
;
; Witness: L1 22 (l4).
L4MoverA4:
  LD HL,$0301
  JR l_F30E

; Mover A5
;
; No recording ran it: known only from the code.
L4MoverA5:
  LD HL,$0101
  JR l_F30E

; Mover A6
;
; Witness: L1 369 (l4).
L4MoverA6:
  CALL L4SoftDraw
  LD A,(DE)
  AND $3C
  CP $10
  JP Z,l_F3AE
  CP $20
  JP Z,l_F3F4
  INC B
  INC C
  INC C
; This entry point is used by the routines at L4MoverA7 and L4MoverA8.
l_F342:
  LD A,(FrameCounter)
  AND $07
  JR NZ,l_F351
  LD H,B
  LD L,C
  POP BC
  DEC C
  PUSH BC
  LD C,L
  LD B,H
  DEC C
l_F351:
  CALL L4OnField
  CALL GetCell
  DEC C
  DEC E
  LD A,(DE)
  CP $FA
  JR NC,l_F385
  INC E
  LD A,(DE)
  CP $FA
  JR NC,l_F385
  INC E
  LD A,(DE)
  DEC E
  CP $FA
  JR NC,l_F385
  XOR A
  LD (DE),A
  DEC E
  LD (DE),A
  INC E
  CALL L4ClearPair
  LD A,(FrameCounter)
  AND $07
  ADD A,$40
  PUSH DE
  CALL LevelObject
  CALL DrawSprite
  POP DE
  LD A,$FA
  LD (DE),A
; This entry point is used by the routines at L4OnField and L4ClearPair.
l_F385:
  CALL SoftCellsOff
  POP BC
  POP DE
  POP AF
  EX AF,AF'
  POP AF
  LD (DrawTag),A
  JP MoveStore

; Return while row B < 20 and column C is 1-30; else drop the return and go to
; the slot's end
;
; Witness: L1 439 (l4).
L4OnField:
  LD A,B
  CP $14
  JR NC,l_F3A0
  LD A,C
  CP $1F
  JR NC,l_F3A0
  CP $01
  RET NC
l_F3A0:
  POP HL
  JR l_F385

; Zero the bytes at DE + $300 and DE + $2FF (the cell and its left neighbour,
; three pages up)
;
; Witness: L1 302 (l4).
L4ClearPair:
  XOR A
  LD H,D
  INC D
  INC D
  INC D
  LD (DE),A
  DEC E
  LD (DE),A
  LD D,H
  INC E
  RET
; This entry point is used by the routine at L4MoverA6.
l_F3AE:
  INC B
  INC C
  INC C
  CALL L4OnField
  CALL GetCell
  LD A,(DE)
  CP $FA
  JP NC,l_F385
  DEC E
  LD A,(DE)
  CP $FA
  JP NC,l_F385
  XOR A
  LD (DE),A
  INC E
  LD (DE),A
  INC E
  LD A,(DE)
  DEC E
  CP $FA
  JR Z,l_F3E8
  LD A,(FrameCounter)
  AND $07
  ADD A,$40
l_F3D6:
  PUSH DE
  DEC C
  CALL LevelObject
  CALL DrawSprite
  POP DE
  LD A,$FA
  LD (DE),A
  CALL L4ClearPair
  JP l_F385
l_F3E8:
  LD A,(FrameCounter)
  DEC A
  XOR $07
  AND $07
  ADD A,$58
  JR l_F3D6
; This entry point is used by the routine at L4MoverA6.
l_F3F4:
  LD A,(FrameCounter)
  AND $07
  JR NZ,l_F3FE
  POP BC
  DEC C
  PUSH BC
l_F3FE:
  INC B
  INC C
  INC C
  CALL L4OnField
  CALL GetCell
  LD A,(DE)
  CP $FA
  JP NC,l_F385
  INC E
  LD A,(DE)
  CP $FA
  JP NC,l_F385
  XOR A
  LD (DE),A
  DEC E
  LD (DE),A
  DEC E
  LD A,(DE)
  INC E
  CP $FA
  JR Z,l_F441
  LD A,(FrameCounter)
  DEC A
  AND $07
  ADD A,$40
  PUSH DE
  DEC C
  CALL LevelObject
  CALL DrawSprite
  POP DE
  LD A,(FrameCounter)
  AND $07
  JR NZ,l_F438
  DEC E
l_F438:
  LD A,$FA
  LD (DE),A
  CALL L4ClearPair
  JP l_F385
l_F441:
  DEC E
  XOR A
  LD (DE),A
  PUSH DE
  LD A,(FrameCounter)
  DEC A
  XOR $07
  AND $07
  ADD A,$60
  DEC C
  CALL LevelObject
  CALL DrawSprite
  POP DE
  LD A,$FA
  LD (DE),A
  INC E
  JR l_F438

; Mover A7
;
; Witness: L1 40 (l4).
L4MoverA7:
  CALL L4SoftDraw
  INC C
  INC C
  DEC B
  JP l_F342

; Keep DrawTag, AF', DE and BC on the stack, DrawTag 0, SoftCellsOn, then back
; to the caller
;
; Witness: L1 439 (l4).
L4SoftDraw:
  POP HL
  LD A,(DrawTag)
  PUSH AF
  EX AF,AF'
  PUSH AF
  PUSH DE
  PUSH BC
  XOR A
  LD (DrawTag),A
  CALL SoftCellsOn
  PUSH HL
  RET

; Mover A8
;
; Witness: L1 30 (l4).
L4MoverA8:
  CALL L4SoftDraw
  INC B
  INC B
  INC B
  INC C
  JP l_F342

; Mover A9, A10
;
; Witness: L1 1161 (l4).
L4MoverA9:
  PUSH DE
  LD A,(IY+$05)
  AND $F0
  CP $30
  JR Z,l_F4D5
  CP $40
  JR Z,l_F497
  LD HL,LevelVars+2
  LD A,$1B
  JR l_F4DA
l_F497:
  LD A,(LevelVars+3)
  AND A
  JR Z,l_F4A3
  DEC A
  LD (LevelVars+3),A
  JR l_F4CE
l_F4A3:
  LD A,(ShipRow)
  LD L,A
  DEC L
  LD A,B
  CP L
  JR NC,l_F4CE
  ADD A,$05
  CP L
  JR C,l_F4CE
  LD A,(ShipColumn)
  LD L,A
  LD A,C
  ADD A,$0A
  CP L
  JR NC,l_F4CE
  LD HL,L4SpawnA+$0001
  LD (HL),A
  INC HL
  LD A,(ShipRow)
  LD (HL),A
  DEC HL
  DEC HL
  CALL StartWaveAt
  LD A,$06
  LD (LevelVars+3),A
l_F4CE:
  LD A,$1A
  LD HL,LevelVars+1
  JR l_F4DA
l_F4D5:
  LD A,$19
  LD HL,LevelVars
l_F4DA:
  EX AF,AF'
  LD A,(HL)
  AND A
  JR Z,l_F4E6
  DEC A
  LD (HL),A
  LD A,$47
  LD (CellMark+15),A
l_F4E6:
  POP DE
  JP l_F2F7

; A wave record (kind $1E) the movers fill and pass to StartWaveAt
L4SpawnA:
  DEFB $1E,$00,$00

; Mover A11
;
; Witness: L1 1161 (l4).
L4MoverA11:
  PUSH BC
  PUSH DE
  EX AF,AF'
  LD A,(IY+$05)
  AND $F0
  CP $30
  JR Z,l_F517
  CP $40
  JR Z,l_F50A
  LD HL,EnemySlots+81
  LD DE,EnemySlots
  LD BC,LevelVars+2
  LD A,$3E
  JR l_F522
l_F50A:
  LD A,$3C
  LD HL,EnemySlots+54
  LD DE,EnemySlots+9
  LD BC,LevelVars+1
  JR l_F522
l_F517:
  LD A,$3A
  LD HL,EnemySlots+27
  LD DE,EnemySlots+18
  LD BC,LevelVars
l_F522:
  EX AF,AF'
  JP NC,l_F5A5
  PUSH DE
  LD DE,(Scratch+2)
  XOR A
  LD (DE),A
  POP DE
  PUSH HL
  POP IX
  LD (CellMark+15),A
  LD (IX+$00),A
  LD (IX+$09),A
  LD (IX+$12),A
  PUSH DE
  POP IX
  LD (IX+$00),A
  LD C,(IX+$03)
  LD B,(IX+$04)
  INC C
  PUSH BC
  INC C
  INC C
  INC B
  INC B
  LD (Scratch),BC
  CALL EnemyDies
  POP BC
  PUSH BC
  LD (Scratch),BC
  CALL EnemyDies
  POP BC
  LD A,C
  ADD A,$04
  LD C,A
  PUSH BC
  LD (Scratch),BC
  CALL EnemyDies
  POP BC
  LD A,B
  ADD A,$04
  LD B,A
  PUSH BC
  LD (Scratch),BC
  CALL EnemyDies
  POP BC
  LD A,C
  SUB $04
  LD C,A
  LD (Scratch),BC
  CALL EnemyDies
  LD DE,$0504
  CALL AddScore
  POP DE
  POP BC
  LD A,(EnemySlots)
  LD L,A
  LD A,(EnemySlots+9)
  LD H,A
  LD A,(EnemySlots+18)
  ADD A,H
  ADD A,L
  JP NZ,MoveDone
  LD A,$65
  LD (MapColumn),A
  JP MoveDone
l_F5A5:
  JR Z,l_F5AA
  LD A,$01
  LD (BC),A
l_F5AA:
  LD A,(FrameCounter)
  RRCA
  RRCA
  AND $40
  ADD A,$04
  LD (CellMark+15),A
  POP DE
  POP BC
  JP l_F2F7

; Mover A12
;
; Witness: L1 1313 (l4).
L4MoverA12:
  JP C,MoveNext
  LD A,(ShipColumn)
  CP C
  LD L,$01
  JR NC,l_F5C8
  LD L,$00
l_F5C8:
  LD A,(DE)
  AND $FE
  OR L
  LD (DE),A
  LD A,(IY+$08)
  AND $01
  JP Z,l_F2F7
  PUSH BC
  PUSH DE
  LD H,B
  LD L,C
  INC H
  INC L
  LD A,(ShipRow)
  CP H
  JR C,l_F5E6
  INC B
  INC H
  INC H
  JR l_F5E9
l_F5E6:
  DEC B
  DEC H
  DEC H
l_F5E9:
  LD A,(ShipColumn)
  CP L
  JR C,l_F5F4
  INC C
  INC L
  INC L
  JR l_F5F7
l_F5F4:
  DEC C
  DEC L
  DEC L
l_F5F7:
  PUSH BC
  PUSH HL
  POP BC
  CALL GetCell
  AND A
  JR Z,l_F606
  POP HL
  POP DE
  POP BC
  JP MoveStore
l_F606:
  POP BC
  POP DE
  POP HL
  JP MoveStore

; Mover A13
;
; Witness: L1 216 (l4).
L4MoverA13:
  LD A,B
  CP $14
  JP NC,l_F6A0
  LD A,C
  CP $1F
  JP NC,l_F6A0
  LD A,(ShipColumn)
  INC A
  LD L,A
  LD A,(ShipRow)
  LD H,A
  LD A,(DE)
  AND $3C
  CP $04
  JR Z,l_F644
  CP $08
  JR Z,l_F644
  LD A,C
  CP L
  JR Z,l_F638
  INC A
  CP L
  JR Z,l_F638
  INC A
  CP L
  JR NZ,l_F658
l_F638:
  LD A,B
  CP H
  LD HL,L4Waves+$08E9
  JR NC,l_F652
  LD HL,L4Waves+$08E2
  JR l_F652
l_F644:
  LD A,B
  CP H
  JR NZ,l_F658
  LD A,C
  CP L
  LD HL,L4Waves+$08F0
  JR NC,l_F652
  LD HL,L4Waves+$08DB
l_F652:
  LD (IY+$06),L
  LD (IY+$07),H
l_F658:
  LD (IY+$03),C
  LD (IY+$04),B
  LD HL,LevelObject
  LD (DrawPrepare+1),HL
  LD A,$01
  LD (ScoreDirty),A
  PUSH DE
  LD A,(DE)
  AND $03
  CP $01
  JR Z,l_F67F
  CP $02
  JR Z,l_F685
  CP $03
  JR Z,l_F68B
  EX AF,AF'
  CALL DrawGame
  JR l_F68F
l_F67F:
  EX AF,AF'
  CALL DrawGameMirrored
  JR l_F68F
l_F685:
  EX AF,AF'
  CALL DrawGameFlipped
  JR l_F68F
l_F68B:
  EX AF,AF'
  CALL DrawGameBoth
l_F68F:
  CALL ProcessHits
  POP DE
  LD HL,GameObject
  LD (DrawPrepare+1),HL
  XOR A
  LD (ScoreDirty),A
  JP MoveScript
l_F6A0:
  LD (IY+$00),$00
  JP MoveDone

; Mover A14
;
; Witness: L1 182 (l4).
L4MoverA14:
  EX AF,AF'
  CP $12
  JR Z,l_F6B0
  EX AF,AF'
  JP l_F2F7
l_F6B0:
  EX AF,AF'
  LD A,(FrameCounter)
  AND $03
  JP NZ,l_F2F7
  LD HL,L4SpawnB+$0002
  LD (HL),B
  DEC HL
  LD (HL),C
  LD A,(DE)
  AND $01
  JR Z,l_F6CD
  DEC (HL)
  LD A,R
  AND $01
  ADD A,$08
  JR l_F6D4
l_F6CD:
  INC (HL)
  LD A,R
  AND $01
  ADD A,$06
l_F6D4:
  DEC HL
  LD (HL),A
  CALL StartWaveAt
  LD HL,$1121
  CALL $F87C
  JP l_F2F7

; A wave record the movers fill and pass to StartWaveAt
L4SpawnB:
  DEFB $00,$00,$00

; Mover A15
;
; Witness: L1 130 (l4).
L4MoverA15:
  PUSH DE
  CALL GetCell
  POP DE
  JP C,MoveStore
  LD (IY+$00),$00
  LD (Scratch),BC
  CALL EnemyDies
  JP MoveDone

; Mover B0
;
; Witness: L1 730 (l4).
L4MoverB0:
  JP MoveScript

; Mover B1
;
; Witness: L1 4645 (l4).
L4MoverB1:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveScript
  JP MoveDone

; Mover B2
;
; Witness: L1 81 (l4).
L4MoverB2:
  CALL SoftCellsOff
  LD A,$1F
  CALL SetDrawLimitA
  JP MoveScript

; Mover B3
;
; Witness: L1 2319 (l4).
L4MoverB3:
  XOR A
  LD (CellMark+15),A
  JR L4MoverB1

; Mover B4
;
; Witness: L1 689 (l4).
L4MoverB4:
  JR L4MoverB3

; Mover B5
;
; Witness: L1 1143 (l4).
L4MoverB5:
  JR L4MoverB3

; Mover B6, B7
;
; Witness: L1 5 (l4).
L4MoverB6:
  LD L,$08
  JR l_F738

; Mover B8
;
; Witness: L1 39 (l4).
L4MoverB8:
  LD L,$09
  JR l_F738

; Mover B10, B11
;
; Witness: L1 284 (l4).
L4MoverB10:
  LD L,$03
  JR l_F738

; Mover B9, B12
;
; Witness: L1 17 (l4).
L4MoverB9:
  LD L,$04
  JR l_F738

; Mover B13
;
; Witness: L1 194 (l4).
L4MoverB13:
  LD L,$05
  JR l_F738

; Mover B14
;
; Witness: L1 12 (l4).
L4MoverB14:
  LD L,$06
  JR l_F738

; Mover B15
;
; Witness: L1 7 (l4).
L4MoverB15:
  LD L,$07
; This entry point is used by the routines at L4MoverB6, L4MoverB8, L4MoverB10,
; L4MoverB9, L4MoverB13 and L4MoverB14.
l_F738:
  CALL L4SlotBusy
  LD A,(Carriers)
  AND A
  JR NZ,l_F755
  LD (Carriers+2),BC
  LD A,L
  LD (Carriers),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+1),A
  JP L4MoverB1
l_F755:
  LD (Carriers+6),BC
  LD A,L
  LD (Carriers+4),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+5),A
  JP L4MoverB1

; Return while the slot is free; else drop the return and go on at Mover B1
; (Mover B15 calls it)
;
; Witness: L1 558 (l4).
L4SlotBusy:
  LD A,(IY+$00)
  AND A
  JR NZ,l_F770
  RET
l_F770:
  POP HL
  JP L4MoverB1
