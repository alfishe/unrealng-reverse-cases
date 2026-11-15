; --------------------------------------------------------------------------------------------------------------------
; level6data.asm: Level 6
;
; The level's body: the header the game reads at $C4AE, the sprites, the object table, the metatiles, the map, the
; wave script, the enemy kinds and their movement scripts, the two mover tables and the movers.
; --------------------------------------------------------------------------------------------------------------------

; The level header: restart point, checkpoints and the pointers the game reads
;
; Restart column $00, restart wave $DADD; checkpoint columns $00, $27, $FF with
; wave entries $DADD, $DBFA, $DD26; objects $CC33, map $D9A7, kinds $E362,
; movers $E612 and $E620.
L6Header:
  DEFB $00
L6RestartWave:
  DEFB $DD,$DA            ; the wave entry a life restarts at (the game keeps
                          ; its live copy here)
L6Checks:
  DEFB $00,$27,$FF        ; three checkpoint columns (CheckRestart)
L6WaveStarts:
  DEFB $DD,$DA,$FA,$DB,$26,$DD ; the wave entries of the start and the
                               ; checkpoints
L6Pointers:
  DEFB $33,$CC,$A7,$D9,$62,$E3,$12,$E6 ; objects, map, kinds, movers 1, movers
  DEFB $20,$E6                         ; 2

; zeros up to the sprites
L6Spare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object
; table points at
L6Sprites:
  INCBIN "res/levels/level6/sprites.bin",$0000,1875

; The level's object table: width, height, the cells' address (LevelObject)
L6Objects:
  INCBIN "res/levels/level6/objects.bin",$0000,132

; The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from
; the map: metatile n at $D9A7 - 144 x (n + 1) (MetatileAddress); 23 of them
L6Metatiles:
  INCBIN "res/levels/level6/metatiles.bin",$0000,3312

; The map: 5 bytes a block column (62 columns), each byte a metatile (bits 0-5)
; and its drawer (bits 6-7)
L6Map:
  INCBIN "res/levels/level6/map.bin",$0000,310

; The wave script: entries (scroll position, kind, script) RunWaves starts;
; then the enemies' movement scripts
L6Waves:
  INCBIN "res/levels/level6/waves.bin",$0000,2181

; The enemy kinds StartWave reads (LevelKinds)
L6Kinds:
  DEFB $2B,$DD,$34,$DD,$41,$DD,$5A,$DD
  DEFB $69,$DD,$74,$DD,$8D,$DD,$9A,$DD
  DEFB $A9,$DD,$C4,$DD,$DB,$DD,$EC,$DD
  DEFB $FB,$DD,$12,$DE,$27,$DE,$3A,$DE
  DEFB $47,$DE,$52,$DE,$63,$DE,$76,$DE
  DEFB $99,$DE,$AA,$DE,$BF,$DE,$D8,$DE
  DEFB $FF,$DE,$1A,$DF,$35,$DF,$50,$DF
  DEFB $6B,$DF,$7E,$DF,$9D,$DF,$DC,$DF
  DEFB $F9,$DF,$04,$E0,$13,$E0,$2A,$E0
  DEFB $41,$E0,$5A,$E0,$73,$E0,$8C,$E0
  DEFB $B3,$E0,$D8,$E0,$FD,$E0,$3C,$E1
  DEFB $5D,$E1,$B8,$E1,$BF,$E1,$E4,$E1
  DEFB $05,$E2,$28,$E2,$4B,$E2,$6E,$E2
  DEFB $B7,$E2,$DC,$E2,$F7,$E2,$16,$E3
  DEFB $41,$E3,$01,$80,$05,$21,$05,$01
  DEFB $06,$21,$06,$01,$05,$21,$05,$01
  DEFB $07,$21,$07,$81,$05,$10,$05,$00
  DEFB $06,$10,$06,$00,$05,$10,$05,$00
  DEFB $07,$10,$07,$80,$08,$08,$08,$08
  DEFB $08,$08,$08,$08,$08,$08,$08,$88
  DEFB $07,$00,$07,$80,$08,$14,$08,$10
  DEFB $08,$98,$08,$09,$08,$09,$08,$09
  DEFB $08,$09,$08,$09,$08,$09,$08,$09
  DEFB $08,$89,$07,$01,$07,$81,$08,$25
  DEFB $08,$21,$08,$A9,$07,$01,$07,$01
  DEFB $07,$01,$07,$01,$07,$01,$07,$01
  DEFB $07,$01,$07,$01,$07,$01,$07,$01
  DEFB $07,$01,$07,$01,$07,$01,$07,$01
  DEFB $07,$01,$07,$81,$0D,$18,$0D,$18
  DEFB $0D,$18,$0D,$18,$0D,$18,$0D,$98
  DEFB $0D,$10,$0D,$10,$0D,$10,$0D,$90
  DEFB $0D,$14,$0D,$14,$0D,$14,$0D,$14
  DEFB $0D,$14,$0D,$94,$0D,$08,$0D,$08
  DEFB $0D,$08,$0D,$88,$0B,$10,$09,$10
  DEFB $0B,$10,$0A,$90,$0B,$21,$09,$21
  DEFB $0B,$21,$0A,$A1,$0B,$21,$09,$A1
  DEFB $0C,$00,$0C,$80,$0C,$01,$0C,$81
  DEFB $0D,$25,$0D,$25,$0D,$25,$0D,$25
  DEFB $0D,$25,$0D,$A5,$0D,$21,$0D,$21
  DEFB $0D,$21,$0D,$A1,$0D,$29,$0D,$29
  DEFB $0D,$29,$0D,$29,$0D,$29,$0D,$A9
  DEFB $0D,$09,$0D,$09,$0D,$09,$0D,$89
  DEFB $0F,$10,$0F,$10,$10,$10,$10,$10
  DEFB $11,$10,$11,$10,$10,$10,$10,$90
  DEFB $0F,$20,$0F,$20,$10,$20,$10,$20
  DEFB $11,$20,$11,$20,$10,$20,$10,$A0
  DEFB $0F,$04,$0F,$04,$10,$04,$10,$04
  DEFB $11,$04,$11,$04,$10,$04,$10,$84
  DEFB $0F,$08,$0F,$08,$10,$08,$10,$08
  DEFB $11,$08,$11,$08,$10,$08,$10,$88
  DEFB $13,$00,$14,$00,$15,$00,$16,$20
  DEFB $17,$00,$18,$00,$19,$00,$12,$20
  DEFB $13,$00,$14,$00,$15,$00,$16,$20
  DEFB $17,$00,$18,$00,$19,$00,$12,$20
  DEFB $13,$00,$14,$00,$15,$00,$16,$20
  DEFB $17,$00,$18,$00,$19,$00,$12,$20
  DEFB $13,$00,$14,$00,$15,$00,$16,$20
  DEFB $17,$00,$18,$00,$19,$00,$12,$A0
  DEFB $13,$00,$14,$00,$15,$00,$16,$A0
  DEFB $13,$01,$14,$01,$15,$01,$16,$11
  DEFB $17,$01,$18,$01,$19,$01,$12,$11
  DEFB $13,$01,$14,$01,$15,$01,$16,$11
  DEFB $17,$01,$18,$01,$19,$01,$12,$11
  DEFB $13,$01,$14,$01,$15,$01,$16,$11
  DEFB $17,$01,$18,$01,$19,$01,$12,$11
  DEFB $13,$01,$14,$01,$15,$01,$16,$11
  DEFB $17,$01,$18,$01,$19,$01,$12,$91
  DEFB $13,$01,$14,$01,$15,$01,$16,$91
  DEFB $1B,$02,$1C,$02,$1D,$02,$1E,$22
  DEFB $1F,$02,$20,$02,$21,$02,$1A,$22
  DEFB $1B,$02,$1C,$02,$1D,$02,$1E,$22
  DEFB $1F,$02,$20,$02,$21,$02,$1A,$22
  DEFB $1B,$02,$1C,$02,$1D,$02,$1E,$22
  DEFB $1F,$02,$20,$02,$21,$02,$1A,$22
  DEFB $1B,$02,$1C,$02,$1D,$02,$1E,$22
  DEFB $1F,$02,$20,$02,$21,$02,$1A,$A2
  DEFB $1B,$02,$1C,$02,$1D,$02,$1E,$A2
  DEFB $1B,$03,$1C,$03,$1D,$03,$1E,$13
  DEFB $1F,$03,$20,$03,$21,$03,$1A,$13
  DEFB $1B,$03,$1C,$03,$1D,$03,$1E,$13
  DEFB $1F,$03,$20,$03,$21,$03,$1A,$13
  DEFB $1B,$03,$1C,$03,$1D,$03,$1E,$13
  DEFB $1F,$03,$20,$03,$21,$03,$1A,$13
  DEFB $1B,$03,$1C,$03,$1D,$03,$1E,$13
  DEFB $1F,$03,$20,$03,$21,$03,$1A,$93
  DEFB $1B,$03,$1C,$03,$1D,$03,$1E,$93

; The first mover of each kind (7 words, LevelMoves)
L6MoversA:
  DEFW L6MoverA0
  DEFW L6MoverA1
  DEFW L6MoverA2
  DEFW L6MoverA3
  DEFW L6MoverA4
  DEFW L6MoverA5
  DEFW L6MoverA6

; The second mover of each kind (16 words, LevelMoves2)
L6MoversB:
  DEFW L6MoverB0
  DEFW L6MoverB1
  DEFW L6MoverB2
  DEFW L6MoverB2
  DEFW L6MoverB4
  DEFW L6MoverB4
  DEFW L6MoverB4
  DEFW L6MoverB4
  DEFW L6MoverB8
  DEFW L6MoverB9
  DEFW L6MoverB10
  DEFW L6MoverB10
  DEFW L6MoverB9
  DEFW L6MoverB13
  DEFW L6MoverB14
  DEFW L6MoverB15

; Mover A0
;
; Witness: L1 0 (none).
L6MoverA0:
  JP C,MoveNext
; This entry point is used by the routines at L6MoverA3 and L6MoverA4.
l_E643:
  JP MoveStore

; Mover A1
;
; No recording ran it: known only from the code.
L6MoverA1:
  JP C,MoveNext
; This entry point is used by the routines at L6MoverA2 and L6MoverA5.
l_E649:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveStore
  JP MoveDraw

; Mover A2
;
; Witness: L1 195 (l6).
L6MoverA2:
  JR NC,l_E649
  JP MoveNext

; Mover A3
;
; Witness: L1 2292 (l6).
L6MoverA3:
  JR C,l_E680
  LD A,(DE)
  AND $FE
  LD (DE),A
  LD A,(DrawTag)
  PUSH AF
  EX AF,AF'
  PUSH AF
  PUSH BC
  PUSH DE
  DEC C
  DEC C
  LD A,$9A
  LD (DrawTag),A
  LD A,$0E
  CALL LevelObject
  CALL DrawSprite
  POP DE
  POP BC
  POP AF
  EX AF,AF'
  POP AF
  LD (DrawTag),A
  JR l_E643
l_E680:
  LD HL,(Scratch+2)
  INC HL
  DEC (HL)
  DEC (HL)
  JP MoveNext

; Mover A4
;
; Witness: L1 161 (l6).
L6MoverA4:
  JP C,MoveNext
  LD A,(DE)
  OR $01
  LD (DE),A
  LD (DE),A
  LD A,(DrawTag)
  PUSH AF
  EX AF,AF'
  PUSH AF
  PUSH BC
  PUSH DE
  INC C
  INC C
  LD A,$9A
  LD (DrawTag),A
  LD A,$0E
  CALL LevelObject
  CALL DrawSpriteMirrored
  POP DE
  POP BC
  POP AF
  EX AF,AF'
  POP AF
  LD (DrawTag),A
  JR l_E643

; Mover A5
;
; Witness: L1 1 (l6).
L6MoverA5:
  JR NC,l_E6BC
  LD HL,(Scratch+2)
  LD (HL),$00
  JP MoveNext
l_E6BC:
  LD A,(EnemySlots+224)
  CP $0C
  JP Z,l_E649
  XOR A
  LD (IY+$00),A
  JP MoveDone

; Mover A6
;
; Witness: L1 733 (l6).
L6MoverA6:
  JP NC,MoveStore
  LD HL,(Scratch+2)
  INC HL
  INC HL
  DEC (HL)
  DEC (HL)
  DEC (HL)
  JP MoveNext

; Mover B0
;
; Witness: L1 8998 (l6).
L6MoverB0:
  JP MoveScript

; Mover B1
;
; Witness: L1 195 (l6).
L6MoverB1:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveScript
  JP MoveDone

; Mover B2, B3
;
; No recording ran it: known only from the code.
L6MoverB2:
  JR L6MoverB0

; Mover B4, B5, B6, B7
;
; No recording ran it: known only from the code.
L6MoverB4:
  LD L,$08
  JR l_E703

; Mover B8
;
; No recording ran it: known only from the code.
L6MoverB8:
  LD L,$09
  JR l_E703

; Mover B10, B11
;
; Witness: L1 97 (l6).
L6MoverB10:
  LD L,$03
  JR l_E703

; Mover B9, B12
;
; Witness: L1 87 (l6).
L6MoverB9:
  LD L,$04
  JR l_E703

; Mover B13
;
; No recording ran it: known only from the code.
L6MoverB13:
  LD L,$05
  JR l_E703

; Mover B14
;
; No recording ran it: known only from the code.
L6MoverB14:
  LD L,$06
  JR l_E703

; Mover B15
;
; Witness: L1 11 (l6).
L6MoverB15:
  LD L,$07
; This entry point is used by the routines at L6MoverB4, L6MoverB8, L6MoverB10,
; L6MoverB9, L6MoverB13 and L6MoverB14.
l_E703:
  CALL L6SlotBusy
  LD A,(Carriers)
  AND A
  JR NZ,l_E720
  LD (Carriers+2),BC
  LD A,L
  LD (Carriers),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+1),A
  JP L6MoverB1
l_E720:
  LD (Carriers+6),BC
  LD A,L
  LD (Carriers+4),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+5),A
  JP L6MoverB1

; Return while the slot is free; else drop the return and go on at Mover B1
; (Mover B15 calls it)
;
; Witness: L1 195 (l6).
L6SlotBusy:
  LD A,(IY+$00)
  AND A
  JR NZ,l_E73B
  RET
l_E73B:
  POP HL
  JP L6MoverB1
