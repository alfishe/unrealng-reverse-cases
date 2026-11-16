; --------------------------------------------------------------------------------------------------------------------
; level8data.asm: Level 8
;
; The level's body: the header the game reads at $C4AE, the sprites, the object table, the metatiles, the map, the
; wave script, the enemy kinds and their movement scripts, the two mover tables and the movers.
; --------------------------------------------------------------------------------------------------------------------

; The level header: restart point, checkpoints and the pointers the game reads
;
; Restart column $00, restart wave $0000; checkpoint columns $00, $FF, $FF with
; wave entries $E6EC, $E8EF, $E8EF; objects $D99C, map $E354, kinds $EBCA,
; movers $EEAC and $EECC.
L8Header:
  DEFB $00
L8RestartWave:
  DEFB $00,$00            ; the wave entry a life restarts at (the game keeps
                          ; its live copy here)
L8Checks:
  DEFB $00,$FF,$FF        ; three checkpoint columns (CheckRestart)
L8WaveStarts:
  DEFB $EC,$E6,$EF,$E8,$EF,$E8 ; the wave entries of the start and the
                               ; checkpoints
L8Pointers:
  DEFB $9C,$D9,$54,$E3,$CA,$EB,$AC,$EE ; objects, map, kinds, movers 1, movers
  DEFB $CC,$EE                         ; 2

; zeros up to the sprites
L8Spare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object
; table points at
L8Sprites:
  INCBIN "res/levels/level8/sprites.bin",$0000,5308

; The level's object table: width, height, the cells' address (LevelObject)
L8Objects:
  INCBIN "res/levels/level8/objects.bin",$0000,184

; The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from
; the map: metatile n at $E354 - 144 x (n + 1) (MetatileAddress); 16 of them
L8Metatiles:
  INCBIN "res/levels/level8/metatiles.bin",$0000,2304

; The map: 5 bytes a block column (184 columns), each byte a metatile (bits
; 0-5) and its drawer (bits 6-7)
L8Map:
  INCBIN "res/levels/level8/map.bin",$0000,920

; The wave script: entries (scroll position, kind, script) RunWaves starts;
; then the enemies' movement scripts
L8Waves:
  INCBIN "res/levels/level8/waves.bin",$0000,1246

; The enemy kinds StartWave reads (LevelKinds)
L8Kinds:
  DEFB $F4,$E8,$09,$E9,$1E,$E9,$3D,$E9
  DEFB $58,$E9,$6D,$E9,$74,$E9,$81,$E9
  DEFB $8E,$E9,$9B,$E9,$A8,$E9,$B5,$E9
  DEFB $C2,$E9,$CF,$E9,$DC,$E9,$E9,$E9
  DEFB $F6,$E9,$03,$EA,$10,$EA,$43,$EA
  DEFB $68,$EA,$77,$EA,$8C,$EA,$9D,$EA
  DEFB $BE,$EA,$CF,$EA,$F4,$EA,$FD,$EA
  DEFB $14,$EB,$2B,$EB,$30,$EB,$35,$EB
  DEFB $3A,$EB,$3F,$EB,$44,$EB,$49,$EB
  DEFB $4E,$EB,$53,$EB,$58,$EB,$5D,$EB
  DEFB $78,$EB,$7F,$EB,$86,$EB,$8D,$EB
  DEFB $94,$EB,$B5,$EB,$BC,$EB,$C3,$EB
  DEFB $07,$18,$07,$18,$07,$18,$07,$18
  DEFB $07,$18,$07,$98,$07,$10,$07,$10
  DEFB $07,$10,$07,$90,$07,$14,$07,$14
  DEFB $07,$14,$07,$14,$07,$14,$07,$94
  DEFB $07,$08,$07,$08,$07,$08,$07,$88
  DEFB $05,$10,$03,$10,$05,$10,$04,$90
  DEFB $06,$00,$06,$80,$18,$80,$0A,$15
  DEFB $0B,$15,$0A,$15,$0B,$95,$0A,$24
  DEFB $0B,$24,$0A,$24,$0B,$A4,$1C,$19
  DEFB $1D,$19,$1C,$19,$1D,$99,$1C,$28
  DEFB $1D,$28,$1C,$28,$1D,$A8,$0C,$15
  DEFB $0D,$15,$0C,$15,$0D,$95,$0C,$24
  DEFB $0D,$24,$0C,$24,$0D,$A4,$1E,$19
  DEFB $1F,$19,$1E,$19,$1F,$99,$1E,$28
  DEFB $1F,$28,$1E,$28,$1F,$A8,$0F,$11
  DEFB $0E,$15,$0F,$11,$0E,$15,$0F,$11
  DEFB $0E,$15,$0F,$11,$0E,$95,$0F,$20
  DEFB $0E,$24,$0F,$20,$0E,$24,$0F,$20
  DEFB $0E,$24,$0F,$20,$0E,$A4,$0F,$13
  DEFB $0E,$1B,$0F,$13,$0E,$1B,$0F,$13
  DEFB $0E,$1B,$0F,$13,$0E,$9B,$0F,$22
  DEFB $0E,$2A,$0F,$22,$0E,$2A,$0F,$22
  DEFB $0E,$2A,$0F,$22,$0E,$AA,$08,$04
  DEFB $08,$85,$08,$08,$08,$89,$08,$10
  DEFB $08,$11,$08,$10,$08,$91,$08,$10
  DEFB $08,$11,$08,$10,$08,$91,$08,$20
  DEFB $08,$A1,$08,$14,$08,$95,$08,$24
  DEFB $08,$A5,$08,$18,$08,$99,$08,$28
  DEFB $08,$A9,$08,$00,$08,$81,$11,$00
  DEFB $12,$00,$13,$00,$14,$00,$15,$00
  DEFB $16,$00,$17,$00,$10,$20,$11,$00
  DEFB $12,$00,$13,$00,$14,$00,$15,$00
  DEFB $16,$00,$17,$00,$10,$20,$11,$00
  DEFB $12,$00,$13,$00,$14,$00,$15,$00
  DEFB $16,$00,$17,$00,$10,$20,$11,$00
  DEFB $12,$00,$13,$00,$14,$00,$15,$00
  DEFB $16,$00,$17,$00,$10,$A0,$12,$00
  DEFB $14,$00,$16,$00,$10,$20,$12,$00
  DEFB $14,$00,$16,$00,$10,$20,$12,$00
  DEFB $14,$00,$16,$00,$10,$20,$12,$00
  DEFB $14,$00,$16,$00,$10,$A0,$20,$00
  DEFB $20,$00,$20,$00,$20,$00,$20,$00
  DEFB $20,$00,$20,$00,$20,$00,$20,$00
  DEFB $20,$04,$20,$00,$20,$00,$20,$00
  DEFB $20,$00,$20,$00,$20,$00,$20,$00
  DEFB $20,$00,$20,$00,$20,$04,$20,$00
  DEFB $20,$00,$20,$00,$20,$00,$20,$00
  DEFB $20,$00,$20,$00,$20,$00,$20,$00
  DEFB $20,$04,$20,$00,$20,$00,$20,$00
  DEFB $20,$00,$20,$00,$20,$00,$20,$00
  DEFB $20,$00,$20,$00,$20,$84,$29,$10
  DEFB $29,$00,$29,$10,$29,$00,$29,$10
  DEFB $29,$00,$29,$10,$29,$00,$29,$10
  DEFB $29,$80,$2A,$10,$2A,$00,$2A,$10
  DEFB $2A,$00,$2A,$10,$2A,$00,$2A,$10
  DEFB $2A,$00,$2A,$10,$2A,$80,$21,$00
  DEFB $21,$00,$22,$00,$22,$00,$23,$00
  DEFB $23,$00,$24,$00,$24,$00,$24,$00
  DEFB $23,$00,$23,$00,$22,$00,$22,$00
  DEFB $21,$80,$26,$00,$26,$00,$27,$00
  DEFB $27,$00,$28,$00,$25,$00,$25,$00
  DEFB $25,$00,$25,$00,$25,$00,$28,$00
  DEFB $27,$00,$27,$00,$26,$00,$26,$80
  DEFB $21,$02,$21,$02,$22,$02,$22,$02
  DEFB $23,$02,$23,$02,$24,$02,$24,$02
  DEFB $24,$02,$23,$02,$23,$02,$22,$02
  DEFB $22,$02,$21,$82,$26,$02,$26,$02
  DEFB $27,$02,$27,$02,$28,$02,$25,$02
  DEFB $25,$02,$25,$02,$25,$02,$25,$02
  DEFB $28,$02,$27,$02,$27,$02,$26,$02
  DEFB $26,$82,$2A,$00,$2A,$00,$2A,$00
  DEFB $2A,$00,$2A,$00,$2A,$00,$2A,$00
  DEFB $2A,$00,$2A,$00,$2A,$00,$2A,$00
  DEFB $2A,$00,$2A,$00,$2A,$00,$2A,$00
  DEFB $2A,$00,$2A,$00,$2A,$00,$2A,$00
  DEFB $2A,$00,$2A,$00,$2A,$00,$2A,$00
  DEFB $2A,$00,$2A,$00,$2A,$00,$2A,$00
  DEFB $2A,$00,$2A,$00,$2A,$00,$2A,$00
  DEFB $2A,$80,$2B,$00,$2C,$00,$2D,$00
  DEFB $2E,$00,$2E,$00,$2D,$00,$2C,$00
  DEFB $2B,$80

; The first mover of each kind (16 words, LevelMoves)
L8MoversA:
  DEFW L8MoverA0
  DEFW L8MoverA1
  DEFW L8MoverA2
  DEFW L8MoverA3
  DEFW L8MoverA4
  DEFW L8MoverA5
  DEFW L8MoverA6
  DEFW L8MoverA7
  DEFW L8MoverA8
  DEFW L8MoverA9
  DEFW L8MoverA10
  DEFW L8MoverA5
  DEFW L8MoverA5
  DEFW L8MoverA5
  DEFW L8MoverA5
  DEFW L8MoverA5

; The second mover of each kind (16 words, LevelMoves2)
L8MoversB:
  DEFW L8MoverB0
  DEFW L8MoverB1
  DEFW L8MoverB2
  DEFW L8MoverB3
  DEFW L8MoverB4
  DEFW L8MoverB4
  DEFW L8MoverB4
  DEFW L8MoverB4
  DEFW L8MoverB8
  DEFW L8MoverB9
  DEFW L8MoverB10
  DEFW L8MoverB10
  DEFW L8MoverB9
  DEFW L8MoverB13
  DEFW L8MoverB14
  DEFW L8MoverB15

; Mover A0
;
; No recording ran it: known only from the code.
L8MoverA0:
  JP C,MoveNext
  JP MoveStore

; Mover A1
;
; Witness: L1 2059 (l8).
L8MoverA1:
  JP C,MoveNext
; This entry point is used by the routines at L8MoverA2, L8MoverA7 and
; L8MoverA8.
l_EEF5:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveStore
  JP MoveDraw

; Mover A2
;
; Witness: L1 158 (l8).
L8MoverA2:
  JR NC,l_EEF5
  JP MoveNext

; Mover A3
;
; Witness: L1 2445 (l8).
L8MoverA3:
  LD A,(MapColumn)
  CP $36
  JR NZ,l_EF17
  LD A,(MetaColumn)
  LD L,A
  LD A,(ScrollStep)
  ADD A,L
  AND A
  JR Z,L8BossBurst
; This entry point is used by the routine at L8BossBurst.
l_EF17:
  LD A,(FrameCounter)
  AND $0F
  JP NZ,MoveStore
  PUSH DE
  LD DE,(ShipColumn)
  INC E
  CALL L8Random
  AND $03
  LD HL,L8Vars
  CP (HL)
  JR NZ,l_EF33
  INC A
  AND $03
l_EF33:
  LD (HL),A
  CP $03
  JR Z,l_EF62
  CP $02
  JR Z,l_EF58
  CP $01
  JR Z,l_EF4B
  LD A,E
  SUB D
  LD E,A
  INC E
  INC E
  LD D,$02
  LD A,$0A
  JR l_EF6D
l_EF4B:
  LD A,E
  ADD A,D
  LD E,A
  DEC E
  DEC E
  DEC E
  DEC E
  LD D,$02
  LD A,$09
  JR l_EF6D
l_EF58:
  LD A,E
  SUB D
  LD E,A
  INC E
  LD D,$12
  LD A,$08
  JR l_EF6D
l_EF62:
  LD A,E
  ADD A,D
  LD E,A
  DEC E
  DEC E
  LD D,$12
  LD A,$07
  JR l_EF6D
l_EF6D:
  LD HL,L8Vars+$0001
  LD (HL),A
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  CALL NextRandom
  AND $03
  CP $03
  JR NZ,l_EF80
  LD A,$01
l_EF80:
  ADD A,A
  ADD A,A
  LD HL,L8Vars+$0001
  ADD A,(HL)
  LD (HL),A
  CALL StartWaveAt
  POP DE
  JP MoveStore

; Four bytes Mover A3's code keeps
L8Vars:
  DEFB $00,$00,$00,$00

; Mover A3's end: free four slots from EnemySlots + 171 and start a wave
; (L8SpawnA) at each one's position
;
; Witness: L1 2 (l8).
L8BossBurst:
  PUSH DE
  PUSH BC
  LD IX,EnemySlots+171
  LD B,$04
l_EF9A:
  LD (IX+$00),$00
  LD HL,L8SpawnA+$0001
  LD A,(IX+$03)
  LD (HL),A
  INC HL
  LD A,(IX+$04)
  LD (HL),A
  LD HL,L8SpawnA
  PUSH IX
  PUSH BC
  CALL StartWaveAt
  POP BC
  POP IX
  LD DE,$0009
  ADD IX,DE
  DJNZ l_EF9A
  POP BC
  POP DE
  JP l_EF17

; A wave record (kind $1B) filled with a slot's position and passed to
; StartWaveAt
L8SpawnA:
  DEFB $1B,$00,$00

; Mover A4
;
; Witness: L1 1120 (l8).
L8MoverA4:
  LD A,(ShipRow)
  CP B
  JR Z,l_EFD1
  JR C,l_EFD0
  INC B
  JR l_EFD1
l_EFD0:
  DEC B
l_EFD1:
  LD A,(ShipColumn)
  CP C
  JR Z,l_EFDD
  JR C,l_EFDC
  INC C
  JR l_EFDD
l_EFDC:
  DEC C
l_EFDD:
  JP MoveStore

; Mover A5, A11, A12, A13, A14, A15
;
; No recording ran it: known only from the code.
L8MoverA5:
  LD A,(IY+$05)
  AND $0F
  CP $05
  JR NZ,l_EFEB
  LD A,$0A
l_EFEB:
  SUB $08
  OR $40
  LD (CellMark+15),A
  JP MoveStore

; Mover A6
;
; No recording ran it: known only from the code.
L8MoverA6:
  LD A,(IY+$08)
  CP $02
  JR NZ,l_F014
  INC (IY+$08)
  CALL $73C2
  LD HL,$1F81
  CALL $F87C
  LD HL,$2041
  CALL $F87C
  LD HL,$2181
  CALL $F87C
l_F014:
  LD A,(FrameCounter)
  AND $07
  CP $02
  JR NC,l_F021
  AND $01
  ADD A,$06
l_F021:
  ADD A,$40
  LD (CellMark+15),A
  JP MoveStore

; Mover A7
;
; Witness: L1 1670 (l8).
L8MoverA7:
  LD A,(MapColumn)
  CP $20
  JP NZ,l_EEF5
  LD A,(MetaColumn)
  CP $01
  JP NZ,l_EEF5
  LD A,(ScrollStep)
  CP $01
  JP NZ,l_EEF5
  LD HL,$0205
  CALL ClearCells
  JP l_EEF5

; Mover A8
;
; Witness: L1 752 (l8).
L8MoverA8:
  JR C,l_F050
  JR Z,l_F068
  JR l_F05C
l_F050:
  LD A,$3E
  LD (IY+$00),A
  LD A,(LevelVars)
  INC A
  LD (LevelVars),A
l_F05C:
  LD A,(FrameCounter)
  AND $01
  JR NZ,l_F068
  LD A,$44
  LD (CellMark+15),A
l_F068:
  EX AF,AF'
  PUSH AF
  PUSH BC
  PUSH DE
  LD A,B
  ADD A,$04
  LD B,A
  LD A,$29
  CALL LevelObject
  CALL DrawSprite
  POP DE
  POP BC
  POP AF
  EX AF,AF'
  JP l_EEF5

; Mover A9
;
; Witness: L1 835 (l8).
L8MoverA9:
  LD A,(LevelVars)
  CP $0A
  JP NZ,L8MoverB1
  CALL BossDestroyed
  LD HL,L8Waves+$0140
  LD (WavePtr),HL
  LD A,$3D
  LD (MapColumn),A
  LD HL,EnemySlots
  LD BC,$00FC
  CALL $FDEF
  LD DE,$0105
  CALL AddScore
  LD DE,$0504
  CALL AddScore
  JP MoveNext

; Mover A10
;
; Witness: L1 2697 (l8).
L8MoverA10:
  LD (IY+$00),$3E
  JP MoveStore

; Mover B0
;
; Witness: L1 6262 (l8).
L8MoverB0:
  JP MoveScript

; Mover B1
;
; Witness: L1 5474 (l8).
L8MoverB1:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveScript
  JP MoveDone

; Mover B2
;
; No recording ran it: known only from the code.
L8MoverB2:
  XOR A
  LD (CellMark+15),A
  JP MoveScript

; Mover B3
;
; Witness: L1 752 (l8).
L8MoverB3:
  XOR A
  LD (CellMark+15),A
  JR L8MoverB1

; Mover B4, B5, B6, B7
;
; No recording ran it: known only from the code.
L8MoverB4:
  LD L,$08
  JR l_F0E9

; Mover B8
;
; No recording ran it: known only from the code.
L8MoverB8:
  LD L,$09
  JR l_F0E9

; Mover B10, B11
;
; Witness: L1 34 (l8).
L8MoverB10:
  LD L,$03
  JR l_F0E9

; Mover B9, B12
;
; Witness: L1 13 (l8).
L8MoverB9:
  LD L,$04
  JR l_F0E9

; Mover B13
;
; Witness: L1 51 (l8).
L8MoverB13:
  LD L,$05
  JR l_F0E9

; Mover B14
;
; Witness: L1 60 (l8).
L8MoverB14:
  LD L,$06
  JR l_F0E9

; Mover B15
;
; No recording ran it: known only from the code.
L8MoverB15:
  LD L,$07
; This entry point is used by the routines at L8MoverB4, L8MoverB8, L8MoverB10,
; L8MoverB9, L8MoverB13 and L8MoverB14.
l_F0E9:
  CALL L8SlotBusy
  LD A,(Carriers)
  AND A
  JR NZ,l_F106
  LD (Carriers+2),BC
  LD A,L
  LD (Carriers),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+1),A
  JP L8MoverB1
l_F106:
  LD (Carriers+6),BC
  LD A,L
  LD (Carriers+4),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+5),A
  JP L8MoverB1

; RandomPtr + 1; A = the ROM byte there
;
; Witness: L1 152 (l8).
L8Random:
  LD HL,(RandomPtr)
  INC HL
  LD (RandomPtr),HL
  LD A,(HL)
  RET

; Return while the slot is free; else drop the return and go on at Mover B1
; (Mover B15 calls it)
;
; Witness: L1 158 (l8).
L8SlotBusy:
  LD A,(IY+$00)
  AND A
  JR NZ,l_F12A
  RET
l_F12A:
  POP HL
  JP L8MoverB1

; Bytes after the code (words $F457, $F423 ..., $ED06 ...): no code of the
; level names them, no level 8 recording reads them
L8Tail:
  DEFB $F4,$57,$F4,$57,$F4,$57,$F4,$23
  DEFB $F4,$2B,$F4,$00,$00,$59,$3F,$2C
  DEFB $03,$F4,$03,$F4,$13,$F4,$13,$F4
  DEFB $00,$00,$59,$3F,$2C,$03,$F4,$03
  DEFB $F4,$01,$F4,$00,$00,$06,$ED,$13
  DEFB $ED,$28,$ED,$49,$ED,$60,$ED,$7B
  DEFB $ED,$94,$ED,$AB,$ED,$C0,$ED,$E1
  DEFB $ED,$F0,$40,$02,$41,$02,$80,$24
  DEFB $11,$01,$11,$01,$11,$01,$80,$24
  DEFB $11,$01,$11,$01,$11,$01,$80,$1F
  DEFB $11,$01,$11,$01,$11,$01,$80,$1F
  DEFB $11,$01,$11,$01,$11,$01,$80,$1C
  DEFB $11,$01,$11,$01,$11,$01,$80,$1C
  DEFB $11,$01,$11,$01,$11,$01,$80,$18
  DEFB $11,$01,$11,$01,$11,$01,$80,$18
  DEFB $11,$01,$11,$01,$11,$01,$51,$01
  DEFB $41,$02,$80,$29,$11,$01,$11,$01
  DEFB $11,$01,$80,$29,$11,$01,$11,$01
  DEFB $11,$01,$80,$24,$11,$01,$11,$01
  DEFB $11,$01,$80,$24,$11,$01,$11,$01
  DEFB $11,$01,$80,$21,$11,$01,$11,$01
  DEFB $11,$01,$80,$21,$11,$01,$11,$01
  DEFB $11,$01,$80,$1D,$11,$01,$11,$01
  DEFB $11,$01,$80,$1D,$11,$01,$11,$01
  DEFB $11,$01,$51,$01,$50,$00,$40,$20
  DEFB $80,$10,$50,$00,$40,$20,$80,$13
  DEFB $50,$00,$40,$40,$80,$0C,$50,$00
  DEFB $40,$20,$80,$10,$50,$00,$40,$20
  DEFB $80,$13,$50,$00,$40,$40,$80,$18
  DEFB $50,$00,$40,$20,$80,$1D,$50,$00
  DEFB $40,$20,$80,$21,$50,$00,$40,$20
  DEFB $80,$1C,$50,$00,$40,$20,$80,$1F
  DEFB $50,$00,$40,$20,$80,$1A,$50,$00
  DEFB $40,$20,$80,$1D,$50,$00,$40,$10
  DEFB $80,$0C,$50,$00,$40,$10,$80,$07
  DEFB $50,$00,$40,$10,$80,$04,$50,$00
  DEFB $40,$10,$80,$00,$50,$00,$40,$10
  DEFB $80,$0C,$80,$18,$50,$00,$00,$00
  DEFB $A2,$26,$10,$27,$10,$28,$10,$27
  DEFB $12,$26,$10,$27,$10,$28,$10,$27
  DEFB $92,$02,$12,$02,$10,$02,$12,$02
  DEFB $10,$02,$12,$02,$10,$02,$12,$02
  DEFB $90,$0E,$10,$0F,$10,$0E,$10,$10
  DEFB $10,$0E,$10,$0F,$10,$0E,$10,$10
  DEFB $90,$0E,$21,$0F,$21,$0E,$47,$02
  DEFB $46,$10,$80,$00,$56,$00,$46,$18
  DEFB $80,$00,$11,$01,$56,$06,$46,$10
  DEFB $80,$05,$56,$00,$46,$18,$80,$05
  DEFB $11,$01,$56,$06,$57,$07,$45,$08
  DEFB $46,$02,$80,$00,$47,$07,$11,$01
  DEFB $57,$07,$56,$06,$47,$04,$80,$07
  DEFB $57,$07,$47,$04,$80,$07,$11,$01
  DEFB $57,$07,$47,$04,$11,$01,$57,$00
  DEFB $55,$05,$45,$02,$46,$02,$80,$05
  DEFB $47,$07,$11,$01,$57,$07,$56,$06
  DEFB $47,$04,$80,$0C,$57,$07,$47,$04
  DEFB $80,$0C,$11,$01,$57,$07,$47,$04
  DEFB $11,$01,$57,$07,$55,$05,$45,$02
  DEFB $46,$02,$80,$04,$47,$07,$11,$01
  DEFB $57,$07,$56,$06,$47,$04,$80,$0B
  DEFB $57,$07,$47,$04,$80,$0B,$11,$01
  DEFB $57,$07,$47,$04,$11,$01,$57,$07
  DEFB $55,$05,$45,$02,$46,$02,$80,$03
  DEFB $47,$07,$11,$01,$57,$07,$56,$06
  DEFB $47,$04,$80,$0A,$57,$07,$47,$04
  DEFB $80,$0A,$11,$01,$57,$07,$47,$04
  DEFB $11,$01,$57,$07,$55,$05,$00,$00
  DEFB $14,$16,$94,$16,$08,$16,$08,$16
  DEFB $08,$16,$88,$14,$10,$12,$10,$14
  DEFB $10,$13,$90,$14,$21,$12,$44,$30
  DEFB $D6,$00,$43,$07,$11,$01,$53,$03
  DEFB $77,$1E,$43,$03,$11,$01,$53,$03
  DEFB $77,$00,$43,$03,$11,$01,$53,$03
  DEFB $54,$04,$00,$00
