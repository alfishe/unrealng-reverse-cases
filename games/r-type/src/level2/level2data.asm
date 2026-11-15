; --------------------------------------------------------------------------------------------------------------------
; level2data.asm: Level 2
;
; The level's body: the header the game reads at $C4AE, the sprites, the object table, the metatiles, the map, the
; wave script, the enemy kinds and their movement scripts, the two mover tables and the movers.
; --------------------------------------------------------------------------------------------------------------------

; The level header: restart point, checkpoints and the pointers the game reads
;
; Restart column $00, restart wave $0000; checkpoint columns $06, $2B, $FF with
; wave entries $E8B1, $EA55, $EE60; objects $D372, map $E762, kinds $F197,
; movers $F4BF and $F4D3.
L2Header:
  DEFB $00
L2RestartWave:
  DEFB $00,$00            ; the wave entry a life restarts at (the game keeps
                          ; its live copy here)
L2Checks:
  DEFB $06,$2B,$FF        ; three checkpoint columns (CheckRestart)
L2WaveStarts:
  DEFB $B1,$E8,$55,$EA,$60,$EE ; the wave entries of the start and the
                               ; checkpoints
L2Pointers:
  DEFB $72,$D3,$62,$E7,$97,$F1,$BF,$F4 ; objects, map, kinds, movers 1, movers
  DEFB $D3,$F4                         ; 2

; zeros up to the sprites
L2Spare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object
; table points at
L2Sprites:
  INCBIN "res/levels/level2/sprites.bin",$0000,3730

; The level's object table: width, height, the cells' address (LevelObject)
L2Objects:
  INCBIN "res/levels/level2/objects.bin",$0000,208

; The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from
; the map: metatile n at $E762 - 144 x (n + 1) (MetatileAddress); 34 of them
L2Metatiles:
  INCBIN "res/levels/level2/metatiles.bin",$0000,4896

; The map: 5 bytes a block column (67 columns), each byte a metatile (bits 0-5)
; and its drawer (bits 6-7)
L2Map:
  INCBIN "res/levels/level2/map.bin",$0000,335

; The wave script: entries (scroll position, kind, script) RunWaves starts;
; then the enemies' movement scripts
L2Waves:
  INCBIN "res/levels/level2/waves.bin",$0000,2278

; The enemy kinds StartWave reads (LevelKinds)
L2Kinds:
  DEFB $65,$EE,$78,$EE,$8B,$EE,$9E,$EE
  DEFB $B1,$EE,$BA,$EE,$C7,$EE,$D6,$EE
  DEFB $E5,$EE,$F2,$EE,$FF,$EE,$0C,$EF
  DEFB $8D,$EF,$92,$EF,$97,$EF,$9C,$EF
  DEFB $A5,$EF,$C6,$EF,$DB,$EF,$F0,$EF
  DEFB $09,$F0,$50,$F0,$55,$F0,$5A,$F0
  DEFB $5F,$F0,$82,$F0,$87,$F0,$8C,$F0
  DEFB $91,$F0,$B8,$F0,$BD,$F0,$C2,$F0
  DEFB $C7,$F0,$E8,$F0,$ED,$F0,$F2,$F0
  DEFB $F7,$F0,$16,$F1,$25,$F1,$2C,$F1
  DEFB $4B,$F1,$5A,$F1,$67,$F1,$74,$F1
  DEFB $81,$F1,$8E,$F1,$20,$01,$21,$01
  DEFB $20,$01,$21,$25,$20,$01,$21,$01
  DEFB $20,$01,$21,$A5,$20,$25,$20,$25
  DEFB $20,$25,$20,$A5,$20,$00,$21,$00
  DEFB $20,$00,$21,$14,$20,$00,$21,$00
  DEFB $20,$00,$21,$94,$20,$14,$20,$14
  DEFB $20,$14,$20,$94,$20,$03,$21,$03
  DEFB $20,$03,$21,$2B,$20,$03,$21,$03
  DEFB $20,$03,$21,$AB,$20,$2B,$20,$2B
  DEFB $20,$2B,$20,$AB,$20,$02,$21,$02
  DEFB $20,$02,$21,$1A,$20,$02,$21,$02
  DEFB $20,$02,$21,$9A,$20,$1A,$20,$1A
  DEFB $20,$1A,$20,$9A,$10,$10,$11,$10
  DEFB $12,$10,$11,$10,$10,$10,$11,$10
  DEFB $12,$10,$11,$10,$10,$10,$11,$10
  DEFB $12,$10,$11,$10,$10,$10,$11,$10
  DEFB $12,$10,$11,$90,$26,$18,$26,$18
  DEFB $26,$18,$26,$18,$26,$18,$26,$98
  DEFB $26,$10,$26,$10,$26,$10,$26,$90
  DEFB $26,$14,$26,$14,$26,$14,$26,$14
  DEFB $26,$14,$26,$94,$26,$08,$26,$08
  DEFB $26,$08,$26,$88,$22,$10,$23,$10
  DEFB $22,$10,$24,$90,$22,$21,$23,$21
  DEFB $22,$21,$24,$A1,$25,$00,$25,$80
  DEFB $25,$01,$25,$81,$32,$29,$33,$29
  DEFB $34,$29,$33,$A9,$32,$18,$33,$18
  DEFB $34,$18,$33,$98,$1B,$11,$1B,$11
  DEFB $1B,$11,$1B,$91,$1B,$20,$1B,$20
  DEFB $1B,$20,$1B,$A0,$19,$04,$19,$04
  DEFB $19,$04,$19,$84,$19,$0A,$19,$0A
  DEFB $19,$0A,$19,$8A,$1A,$15,$1A,$15
  DEFB $1A,$95,$1A,$24,$1A,$24,$1A,$A4
  DEFB $1A,$1B,$1A,$1B,$1A,$9B,$1A,$2A
  DEFB $1A,$2A,$1A,$AA,$1B,$11,$1B,$11
  DEFB $1A,$15,$1A,$15,$1B,$11,$1B,$11
  DEFB $1A,$1B,$1A,$9B,$04,$00,$03,$00
  DEFB $04,$00,$03,$00,$04,$00,$03,$00
  DEFB $04,$00,$03,$80,$06,$00,$05,$00
  DEFB $06,$00,$05,$00,$06,$00,$05,$00
  DEFB $06,$00,$05,$80,$04,$01,$03,$01
  DEFB $04,$01,$03,$01,$04,$01,$03,$01
  DEFB $04,$01,$03,$81,$06,$01,$05,$01
  DEFB $06,$01,$05,$01,$06,$01,$05,$01
  DEFB $06,$01,$05,$81,$1B,$20,$1B,$20
  DEFB $1B,$20,$1A,$2A,$1A,$AA,$19,$0A
  DEFB $19,$0A,$1A,$1B,$1A,$9B,$1B,$11
  DEFB $1B,$11,$1B,$11,$1A,$15,$1A,$95
  DEFB $19,$04,$19,$04,$1A,$24,$1A,$A4
  DEFB $1B,$11,$1B,$11,$1B,$11,$1A,$1B
  DEFB $1A,$9B,$19,$0A,$19,$0A,$1A,$2A
  DEFB $1A,$AA,$1B,$20,$1B,$20,$1B,$20
  DEFB $1A,$24,$1A,$A4,$19,$04,$19,$04
  DEFB $1A,$15,$1A,$95,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$2A,$00,$2B,$00
  DEFB $2C,$00,$2C,$00,$2B,$00,$2A,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$2A,$00,$2B,$00,$2C,$00
  DEFB $2C,$00,$2B,$00,$2A,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $2A,$00,$2B,$00,$2C,$00,$2C,$00
  DEFB $2B,$00,$2A,$00,$29,$80,$2D,$04
  DEFB $2E,$05,$2D,$06,$2E,$84,$2D,$24
  DEFB $2E,$25,$2D,$26,$2E,$24,$2D,$20
  DEFB $2E,$21,$2D,$22,$2E,$20,$2D,$28
  DEFB $2E,$29,$2D,$2A,$2E,$28,$2D,$00
  DEFB $2E,$01,$2D,$02,$2E,$80,$13,$18
  DEFB $14,$18,$13,$19,$14,$18,$13,$10
  DEFB $14,$10,$13,$11,$14,$10,$13,$14
  DEFB $14,$14,$13,$15,$14,$14,$13,$04
  DEFB $14,$04,$13,$05,$14,$04,$13,$24
  DEFB $14,$24,$13,$25,$14,$24,$13,$20
  DEFB $14,$20,$13,$21,$14,$20,$13,$28
  DEFB $14,$28,$13,$29,$14,$28,$13,$08
  DEFB $14,$08,$13,$08,$14,$89,$2D,$08
  DEFB $2E,$09,$2D,$0A,$2E,$88,$2D,$28
  DEFB $2E,$29,$2D,$2A,$2E,$28,$2D,$20
  DEFB $2E,$21,$2D,$22,$2E,$20,$2D,$24
  DEFB $2E,$25,$2D,$26,$2E,$24,$2D,$00
  DEFB $2E,$01,$2D,$02,$2E,$80,$30,$00
  DEFB $30,$00,$30,$00,$30,$00,$30,$00
  DEFB $30,$00,$30,$00,$30,$10,$30,$00
  DEFB $30,$00,$30,$00,$30,$00,$30,$00
  DEFB $30,$00,$30,$00,$30,$90,$30,$02
  DEFB $30,$02,$30,$02,$30,$02,$30,$02
  DEFB $30,$02,$30,$02,$30,$12,$30,$02
  DEFB $30,$02,$30,$02,$30,$02,$30,$02
  DEFB $30,$02,$30,$02,$30,$92,$01,$80

; The first mover of each kind (10 words, LevelMoves)
L2MoversA:
  DEFW L2MoverA0
  DEFW L2MoverA1
  DEFW L2MoverA2
  DEFW L2MoverA3
  DEFW L2MoverA4
  DEFW L2MoverA5
  DEFW L2MoverA6
  DEFW L2MoverA7
  DEFW L2MoverA8
  DEFW L2MoverA9

; The second mover of each kind (16 words, LevelMoves2)
L2MoversB:
  DEFW L2MoverB0
  DEFW L2MoverB1
  DEFW L2MoverB2
  DEFW L2MoverB3
  DEFW L2MoverB4
  DEFW L2MoverB5
  DEFW L2MoverB5
  DEFW L2MoverB5
  DEFW L2MoverB8
  DEFW L2MoverB9
  DEFW L2MoverB10
  DEFW L2MoverB10
  DEFW L2MoverB9
  DEFW L2MoverB13
  DEFW L2MoverB14
  DEFW L2MoverB15

; Mover A0
;
; Witness: L1 0 (none).
L2MoverA0:
  JP C,MoveNext
  JP MoveStore

; Mover A1
;
; No recording ran it: known only from the code.
L2MoverA1:
  JP C,MoveNext
; This entry point is used by the routines at L2MoverA2, L2MoverA3 and
; L2MoverA7.
l_F4FC:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveStore
  JP MoveDraw

; Mover A2
;
; Witness: L1 36 (l2).
L2MoverA2:
  JR NC,l_F4FC
  JP MoveNext

; Mover A3
;
; Witness: L1 1239 (l2).
L2MoverA3:
  JP C,MoveNext
  JR Z,l_F4FC
  LD A,$47
  LD (CellMark+15),A
  LD (LevelVars+1),A
  LD A,(FrameCounter)
  AND $01
  ADD A,$20
  EX AF,AF'
  JP MoveDraw

; Mover A4
;
; Witness: L1 795 (l2).
L2MoverA4:
  EX AF,AF'
  SUB $FD
  EX AF,AF'
  JP MoveStore

; Mover A5
;
; Witness: L1 10335 (l2).
L2MoverA5:
  JR C,l_F547
  LD A,(IY+$00)
  CP $FF
  JR Z,l_F54B
  LD A,(FrameCounter)
  AND $1F
  CALL Z,L2ShotBurst
  LD A,(FrameCounter)
  AND $01
  ADD A,$16
l_F543:
  EX AF,AF'
  JP MoveStore
l_F547:
  LD (IY+$00),$FF
l_F54B:
  LD A,$1F
  JR l_F543

; Mover A6
;
; Witness: L1 795 (l2).
L2MoverA6:
  EX AF,AF'
  SUB $FD
  EX AF,AF'
  LD A,(DE)
  AND $03
  XOR $03
  LD L,A
  LD A,(DE)
  AND $FC
  OR L
  LD (IY+$03),C
  LD (IY+$04),B
  JP MoveDrawA

; Mover A7
;
; Witness: L1 1056 (l2).
L2MoverA7:
  JR NZ,l_F57B
  LD A,(IY+$08)
  CP $01
  JR NZ,l_F578
  INC (IY+$08)
  LD HL,$0405
  CALL ClearCells
l_F578:
  JP l_F4FC
l_F57B:
  LD (IY+$00),$3E
  EX AF,AF'
  CP $2C
  JR Z,l_F588
  EX AF,AF'
  JP l_F4FC
l_F588:
  EX AF,AF'
  LD A,(LevelVars)
  INC A
  LD (LevelVars),A
  CP $10
  JR Z,l_F5A1
  LD A,(FrameCounter)
  AND $01
  ADD A,$46
  LD (CellMark+15),A
  JP l_F4FC
l_F5A1:
  PUSH BC
  PUSH DE
  LD HL,$0983
  CALL $F87C
  CALL BossDestroyed
  LD DE,$0804
  CALL AddScore
  LD A,$FF
  LD (DrawTag),A
  POP DE
  POP BC
  JP MoveStore

; Mover A8
;
; Witness: L1 288 (l2).
L2MoverA8:
  LD A,(IY+$08)
  CP $01
  JR NZ,l_F5F0
  LD A,$30
l_F5C5:
  INC (IY+$08)
  EX AF,AF'
  LD HL,$0305
  CALL ClearCells
  LD HL,$0201
  DEC C
  LD A,(DE)
  AND $02
  LD A,$46
  JR Z,l_F5E1
  INC B
  CALL ClearCellsTag
  DEC B
  JR l_F5E4
l_F5E1:
  CALL ClearCellsTag
l_F5E4:
  INC C
  CALL SoftCellsOn
  LD A,$FF
  LD (DrawTag),A
  JP MoveStore
l_F5F0:
  CP $04
  JR NZ,l_F5F8
  LD A,$31
  JR l_F5C5
l_F5F8:
  CP $0A
  JR NZ,l_F600
  LD A,$30
  JR l_F5C5
l_F600:
  CP $0C
  JR NZ,l_F608
  LD A,$2F
  JR l_F5C5
l_F608:
  LD (IY+$03),C
  LD (IY+$04),B
  JP MoveNext

; Mover A9
;
; Witness: L1 544 (l2).
L2MoverA9:
  LD HL,$0505
  CALL ClearCells
  CALL SoftCellsOn
  LD A,$FF
  LD (DrawTag),A
  JP MoveStore

; Mover B0
;
; Witness: L1 14919 (l2).
L2MoverB0:
  JP MoveScript

; Mover B1
;
; Witness: L1 2164 (l2).
L2MoverB1:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveScript
  JP MoveDone

; Mover B2
;
; Witness: L1 1056 (l2).
L2MoverB2:
  XOR A
  LD (CellMark+15),A
  JR L2MoverB1

; Mover B3
;
; Witness: L1 1239 (l2).
L2MoverB3:
  LD A,(LevelVars+1)
  AND A
  JR Z,L2MoverB1
  XOR A
  LD (CellMark+15),A
  LD (LevelVars+1),A
  JP MoveDone

; Mover B4
;
; Witness: L1 832 (l2).
L2MoverB4:
  CALL SoftCellsOff
  JP MoveScript

; Mover B5, B6, B7
;
; No recording ran it: known only from the code.
L2MoverB5:
  LD L,$08
  JR l_F666

; Mover B8
;
; No recording ran it: known only from the code.
L2MoverB8:
  LD L,$09
  JR l_F666

; Mover B10, B11
;
; Witness: L1 17 (l2).
L2MoverB10:
  LD L,$03
  JR l_F666

; Mover B9, B12
;
; Witness: L1 12 (l2).
L2MoverB9:
  LD L,$04
  JR l_F666

; Mover B13
;
; No recording ran it: known only from the code.
L2MoverB13:
  LD L,$05
  JR l_F666

; Mover B14
;
; Witness: L1 7 (l2).
L2MoverB14:
  LD L,$06
  JR l_F666

; Mover B15
;
; No recording ran it: known only from the code.
L2MoverB15:
  LD L,$07
; This entry point is used by the routines at L2MoverB5, L2MoverB8, L2MoverB10,
; L2MoverB9, L2MoverB13 and L2MoverB14.
l_F666:
  CALL L2SlotBusy
  LD A,(Carriers)
  AND A
  JR NZ,l_F683
  LD (Carriers+2),BC
  LD A,L
  LD (Carriers),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+1),A
  JP L2MoverB1
l_F683:
  LD (Carriers+6),BC
  LD A,L
  LD (Carriers+4),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+5),A
  JP L2MoverB1

; Fire eight enemy shots from the slot's position, kinds $21, $22, $24, $28,
; $25, $26, $29, $2A (the eight directions)
;
; Witness: L1 228 (l2).
L2ShotBurst:
  PUSH IX
  LD IX,EnemyShots
  LD (IX+$00),$21
  LD (IX+$03),$22
  LD (IX+$06),$24
  LD (IX+$09),$28
  LD (IX+$0C),$25
  LD (IX+$0F),$26
  LD (IX+$12),$29
  LD (IX+$15),$2A
  LD H,B
  LD L,C
  INC H
  INC L
  LD A,$08
l_F6C3:
  LD (IX+$01),L
  LD (IX+$02),H
  INC IX
  INC IX
  INC IX
  DEC A
  JR NZ,l_F6C3
  POP IX
  LD HL,$0341
  CALL $F87C
  RET

; Return while the slot is free; else drop the return and go on at Mover B1
; (Mover B15 calls it)
;
; Witness: L1 36 (l2).
L2SlotBusy:
  LD A,(IY+$00)
  AND A
  JR NZ,l_F6E2
  RET
l_F6E2:
  POP HL
  JP L2MoverB1
