; --------------------------------------------------------------------------------------------------------------------
; level7data.asm: Level 7
;
; The level's body: the header the game reads at $C4AE, the sprites, the object table, the metatiles, the map, the
; wave script, the enemy kinds and their movement scripts, the two mover tables and the movers.
; --------------------------------------------------------------------------------------------------------------------

; The level header: restart point, checkpoints and the pointers the game reads
;
; Restart column $00, restart wave $0000; checkpoint columns $00, $2D, $FF with
; wave entries $E86A, $E9DC, $ED01; objects $D150, map $E6F8, kinds $F153,
; movers $F4B1 and $F4CF.
L7Header:
  DEFB $00
L7RestartWave:
  DEFB $00,$00            ; the wave entry a life restarts at (the game keeps
                          ; its live copy here)
L7Checks:
  DEFB $00,$2D,$FF        ; three checkpoint columns (CheckRestart)
L7WaveStarts:
  DEFB $6A,$E8,$DC,$E9,$01,$ED ; the wave entries of the start and the
                               ; checkpoints
L7Pointers:
  DEFB $50,$D1,$F8,$E6,$53,$F1,$B1,$F4 ; objects, map, kinds, movers 1, movers
  DEFB $CF,$F4                         ; 2

; zeros up to the sprites
L7Spare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object
; table points at
L7Sprites:
  INCBIN "res/levels/level7/sprites.bin",$0000,3184

; The level's object table: width, height, the cells' address (LevelObject)
L7Objects:
  INCBIN "res/levels/level7/objects.bin",$0000,216

; The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from
; the map: metatile n at $E6F8 - 144 x (n + 1) (MetatileAddress); 37 of them
L7Metatiles:
  INCBIN "res/levels/level7/metatiles.bin",$0000,5328

; The map: 5 bytes a block column (74 columns), each byte a metatile (bits 0-5)
; and its drawer (bits 6-7)
L7Map:
  INCBIN "res/levels/level7/map.bin",$0000,370

; The wave script: entries (scroll position, kind, script) RunWaves starts;
; then the enemies' movement scripts
;
; The entry at $EC16 has command $5D: no handler, it falls through CommandWave
; and does nothing (a data slip).
L7Waves:
  INCBIN "res/levels/level7/waves.bin",$0000,2281

; The enemy kinds StartWave reads (LevelKinds)
L7Kinds:
  DEFB $06,$ED,$13,$ED,$28,$ED,$49,$ED
  DEFB $60,$ED,$7B,$ED,$94,$ED,$AB,$ED
  DEFB $C0,$ED,$E1,$ED,$F0,$ED,$05,$EE
  DEFB $05,$EE,$05,$EE,$12,$EE,$3F,$EE
  DEFB $4E,$EE,$5D,$EE,$6C,$EE,$7B,$EE
  DEFB $9E,$EE,$AB,$EE,$BE,$EE,$D3,$EE
  DEFB $E4,$EE,$F5,$EE,$02,$EF,$13,$EF
  DEFB $6C,$EF,$81,$EF,$90,$EF,$A9,$EF
  DEFB $BC,$EF,$DB,$EF,$FA,$EF,$09,$F0
  DEFB $18,$F0,$2B,$F0,$48,$F0,$57,$F0
  DEFB $6A,$F0,$7D,$F0,$8A,$F0,$97,$F0
  DEFB $A4,$F0,$B1,$F0,$C2,$F0,$CF,$F0
  DEFB $E0,$F0,$F5,$F0,$0A,$F1,$3B,$F1
  DEFB $48,$F1,$08,$10,$09,$18,$0A,$10
  DEFB $09,$14,$08,$14,$09,$10,$0A,$18
  DEFB $09,$90,$0B,$08,$0B,$08,$0B,$08
  DEFB $0B,$88,$0C,$18,$0C,$18,$0C,$18
  DEFB $0C,$98,$0D,$10,$0D,$10,$0D,$10
  DEFB $0D,$10,$0D,$10,$0D,$10,$0D,$10
  DEFB $0D,$90,$0C,$29,$0C,$A9,$0D,$21
  DEFB $0D,$21,$0D,$21,$0D,$21,$0D,$21
  DEFB $0D,$A1,$0C,$27,$0C,$27,$0C,$A7
  DEFB $0B,$06,$0B,$06,$0B,$06,$0B,$86
  DEFB $0C,$27,$0C,$A7,$31,$10,$31,$10
  DEFB $31,$10,$31,$10,$31,$10,$31,$10
  DEFB $31,$10,$31,$90,$31,$04,$31,$04
  DEFB $31,$84,$31,$08,$31,$08,$31,$88
  DEFB $32,$02,$32,$02,$32,$02,$32,$92
  DEFB $32,$02,$32,$02,$32,$02,$32,$02
  DEFB $32,$02,$32,$02,$32,$02,$32,$02
  DEFB $32,$02,$32,$02,$32,$22,$32,$02
  DEFB $32,$02,$32,$02,$32,$02,$32,$02
  DEFB $32,$02,$32,$02,$32,$02,$32,$02
  DEFB $32,$02,$32,$A2,$26,$10,$27,$10
  DEFB $28,$10,$27,$12,$26,$10,$27,$10
  DEFB $28,$10,$27,$92,$02,$12,$02,$10
  DEFB $02,$12,$02,$10,$02,$12,$02,$10
  DEFB $02,$12,$02,$90,$0E,$10,$0F,$10
  DEFB $0E,$10,$10,$10,$0E,$10,$0F,$10
  DEFB $0E,$10,$10,$90,$0E,$21,$0F,$21
  DEFB $0E,$21,$10,$A1,$11,$08,$11,$08
  DEFB $11,$08,$11,$08,$11,$08,$11,$88
  DEFB $10,$80,$11,$14,$11,$10,$11,$98
  DEFB $11,$09,$11,$09,$11,$09,$11,$89
  DEFB $10,$81,$11,$25,$11,$21,$11,$A9
  DEFB $11,$25,$11,$25,$11,$21,$11,$21
  DEFB $11,$29,$11,$A9,$11,$14,$11,$14
  DEFB $11,$14,$11,$14,$11,$14,$11,$14
  DEFB $11,$14,$11,$10,$11,$98,$11,$14
  DEFB $11,$14,$11,$10,$11,$10,$11,$18
  DEFB $11,$98,$25,$00,$25,$10,$25,$00
  DEFB $25,$10,$25,$00,$25,$10,$25,$00
  DEFB $25,$10,$25,$00,$25,$10,$25,$00
  DEFB $25,$90,$25,$10,$25,$18,$25,$18
  DEFB $25,$18,$25,$08,$25,$08,$25,$08
  DEFB $25,$88,$25,$10,$25,$10,$25,$90
  DEFB $2A,$10,$2A,$10,$2A,$90,$2A,$20
  DEFB $2A,$20,$2A,$A0,$2B,$00,$2C,$00
  DEFB $2D,$00,$2C,$00,$2B,$80,$16,$18
  DEFB $16,$18,$16,$18,$16,$18,$16,$18
  DEFB $16,$98,$16,$10,$16,$10,$16,$10
  DEFB $16,$90,$16,$14,$16,$14,$16,$14
  DEFB $16,$14,$16,$14,$16,$94,$16,$08
  DEFB $16,$08,$16,$08,$16,$88,$14,$10
  DEFB $12,$10,$14,$10,$13,$90,$14,$21
  DEFB $12,$21,$14,$21,$13,$A1,$15,$00
  DEFB $15,$80,$15,$01,$15,$81,$16,$25
  DEFB $16,$25,$16,$25,$16,$25,$16,$25
  DEFB $16,$A5,$16,$21,$16,$21,$16,$21
  DEFB $16,$A1,$16,$29,$16,$29,$16,$29
  DEFB $16,$29,$16,$29,$16,$A9,$16,$09
  DEFB $16,$09,$16,$09,$16,$89,$1E,$00
  DEFB $1F,$00,$1F,$80,$20,$00,$1F,$00
  DEFB $1F,$80,$1E,$80,$20,$80,$23,$08
  DEFB $23,$08,$23,$08,$23,$08,$23,$08
  DEFB $23,$08,$23,$08,$23,$88,$24,$08
  DEFB $24,$08,$24,$08,$24,$08,$24,$08
  DEFB $24,$08,$24,$08,$24,$88,$25,$08
  DEFB $25,$08,$25,$08,$25,$08,$25,$08
  DEFB $25,$08,$25,$08,$25,$88,$33,$00
  DEFB $33,$04,$33,$00,$33,$04,$33,$00
  DEFB $33,$04,$33,$00,$33,$04,$33,$00
  DEFB $33,$84,$33,$00,$33,$08,$33,$00
  DEFB $33,$08,$33,$00,$33,$08,$33,$00
  DEFB $33,$08,$33,$00,$33,$88,$33,$00
  DEFB $33,$00,$33,$00,$33,$80,$34,$80
  DEFB $35,$00,$35,$00,$35,$00,$35,$00
  DEFB $35,$00,$35,$00,$35,$00,$35,$80
  DEFB $36,$00,$36,$00,$36,$00,$36,$00
  DEFB $36,$00,$36,$00,$36,$00,$36,$80
  DEFB $19,$10,$1A,$10,$1B,$10,$1A,$10
  DEFB $19,$10,$1A,$10,$1B,$10,$1A,$90
  DEFB $19,$21,$1A,$21,$1B,$21,$1A,$21
  DEFB $19,$21,$1A,$21,$1B,$21,$1A,$A1
  DEFB $1C,$00,$1C,$80,$1C,$01,$1C,$81
  DEFB $1D,$00,$1D,$00,$1D,$00,$1D,$00
  DEFB $1D,$00,$1D,$80,$1D,$01,$1D,$01
  DEFB $1D,$01,$1D,$01,$1D,$01,$1D,$81
  DEFB $19,$00,$19,$00,$19,$00,$19,$80
  DEFB $19,$01,$19,$01,$19,$01,$19,$81
  DEFB $05,$04,$05,$04,$05,$04,$05,$04
  DEFB $05,$84,$05,$0A,$05,$0A,$05,$0A
  DEFB $05,$0A,$05,$0A,$05,$8A,$06,$14
  DEFB $07,$10,$07,$10,$06,$9A,$06,$14
  DEFB $06,$14,$07,$10,$07,$10,$06,$1A
  DEFB $06,$9A,$06,$25,$07,$21,$07,$21
  DEFB $06,$AB,$06,$25,$06,$25,$07,$21
  DEFB $07,$21,$06,$2B,$06,$AB

; The first mover of each kind (15 words, LevelMoves)
L7MoversA:
  DEFW L7MoverA0
  DEFW L7MoverA1
  DEFW L7MoverA2
  DEFW L7MoverA3
  DEFW L7MoverA4
  DEFW L7MoverA5
  DEFW L7MoverA6
  DEFW L7MoverA7
  DEFW L7MoverA8
  DEFW L7MoverA8
  DEFW L7MoverA10
  DEFW L7MoverA10
  DEFW L7MoverA10
  DEFW L7MoverA13
  DEFW L7MoverA13

; The second mover of each kind (16 words, LevelMoves2)
L7MoversB:
  DEFW L7MoverB0
  DEFW L7MoverB1
  DEFW L7MoverB2
  DEFW L7MoverB2
  DEFW L7MoverB4
  DEFW L7MoverB4
  DEFW L7MoverB6
  DEFW L7MoverB7
  DEFW L7MoverB8
  DEFW L7MoverB9
  DEFW L7MoverB10
  DEFW L7MoverB10
  DEFW L7MoverB9
  DEFW L7MoverB13
  DEFW L7MoverB14
  DEFW L7MoverB15

; Mover A0
;
; Witness: L1 4951 (deaths-l7, l7).
L7MoverA0:
  JP C,MoveNext
  JP MoveStore

; Mover A1
;
; Witness: L1 1741 (deaths-l7, l7).
L7MoverA1:
  JP C,MoveNext
; This entry point is used by the routines at L7MoverA2, L7MoverA3, L7MoverA5,
; L7MoverA7, L7MoverA10 and L7MoverA13.
l_F4F8:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveStore
  JP MoveDraw

; Mover A2
;
; Witness: L1 304 (deaths-l7, l7).
L7MoverA2:
  JR NC,l_F4F8
  JP MoveNext

; Mover A3
;
; Witness: L1 158 (l7).
L7MoverA3:
  JP C,MoveNext
  LD A,(FrameCounter)
  AND $0F
  JR NZ,l_F4F8
  LD HL,L7SpawnA+$0002
  LD A,(IY+$04)
  LD (HL),A
  DEC HL
  LD A,(IY+$03)
  DEC A
  DEC A
  LD (HL),A
  DEC HL
  CALL StartWaveAt
  JR l_F4F8

; A wave record (kind $24) the movers fill and pass to StartWaveAt
L7SpawnA:
  DEFB $24,$00,$09

; Mover A4
;
; Witness: L1 2011 (l7).
L7MoverA4:
  JP C,l_F534
  LD A,(IY+$04)
  CP $11
  JP NZ,MoveStore
l_F534:
  LD (IY+$00),$00
  LD A,(MapColumn)
  CP $5D
  JP NC,MoveStore
  CALL NextRandom
  PUSH DE
  EX DE,HL
  LD HL,L7SpawnB+$0002
  LD A,(DE)
  AND $07
  ADD A,$F9
  LD (HL),A
  DEC HL
  LD A,(IY+$03)
  LD (HL),A
  DEC HL
  LD A,(DE)
  AND $03
  ADD A,$2A
  CP $2D
  JR NZ,l_F565
  LD A,(DE)
  AND $C0
  LD A,$2C
  JR NZ,l_F565
  INC A
l_F565:
  LD (HL),A
  CALL StartWaveAt
  POP DE
  JP MoveNext

; A wave record the movers fill and pass to StartWaveAt
L7SpawnB:
  DEFB $00,$00,$00

; Mover A5
;
; Witness: L1 351 (l7).
L7MoverA5:
  JP NC,l_F589
  LD A,(LevelVars+1)
  INC A
  LD (LevelVars+1),A
  CP $04
  JP Z,l_F5AD
  LD HL,(Scratch+2)
  LD (HL),$00
  LD (IY+$00),$3E
  INC A
l_F589:
  JP Z,l_F598
  LD A,(FrameCounter)
  AND $01
  JR NZ,l_F598
  LD A,$47
  LD (CellMark+15),A
l_F598:
  EX AF,AF'
  PUSH AF
  PUSH BC
  PUSH DE
  LD A,$29
  INC C
  INC C
  CALL LevelObject
  CALL DrawSprite
  POP DE
  POP BC
  POP AF
  EX AF,AF'
  JP l_F4F8
l_F5AD:
  XOR A
  LD (CellMark+15),A
  EX AF,AF'
  PUSH BC
  CALL LevelObject
  CALL DrawSprite
  LD A,$29
  POP BC
  INC C
  INC C
  CALL LevelObject
  CALL DrawSprite
  CALL BossDestroyed
  LD DE,$0104
  CALL AddScore
  JP MoveDone

; Mover A6
;
; Witness: L1 378 (l7).
L7MoverA6:
  JR C,l_F5E4
  LD L,$00
  LD A,(ShipColumn)
  INC A
  CP C
  JR C,l_F5DC
  INC L
l_F5DC:
  LD A,(DE)
  AND $FE
  OR L
  LD (DE),A
  JP MoveStore
l_F5E4:
  PUSH BC
  LD (Scratch),BC
  CALL EnemyDies
  POP BC
  INC B
  INC B
  INC B
  LD (Scratch),BC
  CALL EnemyDies
  JP MoveDone

; Mover A7
;
; Witness: L1 840 (l7).
L7MoverA7:
  JR NC,l_F63A
  LD A,(LevelVars)
  INC A
  LD (LevelVars),A
  CP $06
  JR Z,l_F612
  LD HL,(Scratch+2)
  LD (HL),$00
  LD (IY+$00),$3E
  JR l_F648
l_F612:
  LD A,C
  ADD A,$06
  LD C,A
  LD (Scratch),BC
  CALL FreeExplosion
  CALL AwardScore
  LD BC,(Scratch)
  DEC C
  DEC C
  DEC C
  LD (Scratch),BC
  CALL FreeExplosion
  CALL AwardScore
  LD DE,$0404
  CALL AddScore
  JP MoveDone
l_F63A:
  JR Z,l_F648
  LD A,(FrameCounter)
  AND $01
  JR NZ,l_F648
  LD A,$47
  LD (CellMark+15),A
l_F648:
  LD A,$32
  PUSH AF
  PUSH BC
  PUSH DE
  INC B
  INC B
  CALL LevelObject
  CALL DrawSprite
  POP DE
  POP BC
  POP AF
  EX AF,AF'
  JP l_F4F8

; Mover A8, A9
;
; Witness: L1 196 (l7).
L7MoverA8:
  LD HL,$0206
  CALL ClearCells
  CALL SoftCellsOn
  LD A,$FF
  LD (DrawTag),A
  JP MoveStore

; Mover A10, A11, A12
;
; Witness: L1 4867 (deaths-l7, l7).
L7MoverA10:
  JP C,MoveNext
  LD A,(ShipColumn)
  CP C
  LD L,$01
  JR NC,l_F67A
  LD L,$00
l_F67A:
  LD A,(DE)
  AND $FE
  OR L
  LD (DE),A
  LD A,(IY+$08)
  AND $01
  JP Z,l_F4F8
  PUSH BC
  PUSH DE
  LD H,B
  LD L,C
  INC H
  INC L
  LD A,(ShipRow)
  CP H
  JR C,l_F698
  INC B
  INC H
  INC H
  JR l_F69B
l_F698:
  DEC B
  DEC H
  DEC H
l_F69B:
  LD A,(ShipColumn)
  CP L
  JR C,l_F6A6
  INC C
  INC L
  INC L
  JR l_F6A9
l_F6A6:
  DEC C
  DEC L
  DEC L
l_F6A9:
  PUSH BC
  PUSH HL
  POP BC
  CALL GetCell
  AND A
  JR Z,l_F6B8
  POP HL
  POP DE
  POP BC
  JP MoveStore
l_F6B8:
  POP BC
  POP DE
  POP HL
  JP MoveStore

; Mover A13, A14
;
; Witness: L1 1052 (deaths-l7, l7).
L7MoverA13:
  EX AF,AF'
  CP $1D
  JR Z,l_F6C7
  EX AF,AF'
  JP l_F4F8
l_F6C7:
  EX AF,AF'
  LD A,(FrameCounter)
  AND $03
  JP NZ,l_F4F8
  LD HL,L7SpawnC+$0002
  LD (HL),B
  DEC HL
  LD (HL),C
  LD A,(DE)
  AND $01
  JR Z,l_F6E4
  DEC (HL)
  LD A,R
  AND $01
  ADD A,$12
  JR l_F6EB
l_F6E4:
  INC (HL)
  LD A,R
  AND $01
  ADD A,$10
l_F6EB:
  DEC HL
  LD (HL),A
  CALL StartWaveAt
  LD HL,$1121
  CALL $F87C
  JP l_F4F8

; A wave record the movers fill and pass to StartWaveAt
L7SpawnC:
  DEFB $00,$00,$00

; Mover B0
;
; Witness: L1 5322 (deaths-l7, l7).
L7MoverB0:
  JP MoveScript

; Mover B1
;
; Witness: L1 9299 (deaths-l7, l7).
L7MoverB1:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveScript
  JP MoveDone

; Mover B2, B3
;
; Witness: L1 1191 (l7).
L7MoverB2:
  XOR A
  LD (CellMark+15),A
  JR L7MoverB1

; Mover B4, B5
;
; Witness: L1 196 (l7).
L7MoverB4:
  CALL SoftCellsOff
  JP MoveScript

; Mover B6
;
; Witness: L1 2011 (l7).
L7MoverB6:
  XOR A
  LD (CellMark+15),A
  JP MoveScript

; Mover B7
;
; Witness: L1 32 (l7).
L7MoverB7:
  LD L,$08
  JR l_F737

; Mover B8
;
; No recording ran it: known only from the code.
L7MoverB8:
  LD L,$09
  JR l_F737

; Mover B10, B11
;
; Witness: L1 86 (l7).
L7MoverB10:
  LD L,$03
  JR l_F737

; Mover B9, B12
;
; No recording ran it: known only from the code.
L7MoverB9:
  LD L,$04
  JR l_F737

; Mover B13
;
; Witness: L1 67 (l7).
L7MoverB13:
  LD L,$05
  JR l_F737

; Mover B14
;
; Witness: L1 113 (deaths-l7, l7).
L7MoverB14:
  LD L,$06
  JR l_F737

; Mover B15
;
; Witness: L1 6 (deaths-l7, l7).
L7MoverB15:
  LD L,$07
; This entry point is used by the routines at L7MoverB7, L7MoverB8, L7MoverB10,
; L7MoverB9, L7MoverB13 and L7MoverB14.
l_F737:
  CALL L7SlotBusy
  LD A,(Carriers)
  AND A
  JR NZ,l_F754
  LD (Carriers+2),BC
  LD A,L
  LD (Carriers),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+1),A
  JP MoveScript
l_F754:
  LD (Carriers+6),BC
  LD A,L
  LD (Carriers+4),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+5),A
  JP MoveScript

; Return while the slot is free; else drop the return and go on at Mover B1
; (Mover B15 calls it)
;
; Witness: L1 304 (deaths-l7, l7).
L7SlotBusy:
  LD A,(IY+$00)
  AND A
  JR NZ,l_F76F
  RET
l_F76F:
  POP HL
  JP L7MoverB1
