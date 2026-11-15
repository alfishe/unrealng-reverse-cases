; --------------------------------------------------------------------------------------------------------------------
; level3data.asm: Level 3
;
; The level's body: the header the game reads at $C4AE, the sprites, the object table, the metatiles, the map, the
; wave script, the enemy kinds and their movement scripts, the two mover tables and the movers.
; --------------------------------------------------------------------------------------------------------------------

; The level header: restart point, checkpoints and the pointers the game reads
;
; Restart column $00, restart wave $0000; checkpoint columns $00, $FF, $FF with
; wave entries $E856, $EA31, $EA31; objects $DD8E, map $E716, kinds $ED50,
; movers $F0A6 and $F0C6.
L3Header:
  DEFB $00
L3RestartWave:
  DEFB $00,$00            ; the wave entry a life restarts at (the game keeps
                          ; its live copy here)
L3Checks:
  DEFB $00,$FF,$FF        ; three checkpoint columns (CheckRestart)
L3WaveStarts:
  DEFB $56,$E8,$31,$EA,$31,$EA ; the wave entries of the start and the
                               ; checkpoints
L3Pointers:
  DEFB $8E,$DD,$16,$E7,$50,$ED,$A6,$F0 ; objects, map, kinds, movers 1, movers
  DEFB $C6,$F0                         ; 2

; zeros up to the sprites
L3Spare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object
; table points at
L3Sprites:
  INCBIN "res/levels/level3/sprites.bin",$0000,6318

; The level's object table: width, height, the cells' address (LevelObject)
L3Objects:
  INCBIN "res/levels/level3/objects.bin",$0000,424

; The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from
; the map: metatile n at $E716 - 144 x (n + 1) (MetatileAddress); 14 of them
L3Metatiles:
  INCBIN "res/levels/level3/metatiles.bin",$0000,2016

; The map: 5 bytes a block column (64 columns), each byte a metatile (bits 0-5)
; and its drawer (bits 6-7)
L3Map:
  INCBIN "res/levels/level3/map.bin",$0000,320

; The wave script: entries (scroll position, kind, script) RunWaves starts;
; then the enemies' movement scripts
L3Waves:
  DEFB $09,$00,$63,$04,$1C,$0A,$08,$63
  DEFB $03,$01,$0A,$08,$0C,$20,$0C,$0A
  DEFB $08,$63,$03,$02,$0A,$08,$0D,$2C
  DEFB $04,$0A,$08,$63,$03,$03,$0A,$08
  DEFB $02,$22,$09,$0A,$08,$63,$03,$04
  DEFB $0A,$08,$02,$24,$08,$0A,$08,$63
  DEFB $03,$05,$0A,$08,$02,$26,$07,$0A
  DEFB $08,$63,$03,$06,$0A,$08,$12,$29
  DEFB $05,$0A,$08,$63,$03,$08,$0A,$08
  DEFB $02,$25,$0C,$0A,$08,$63,$03,$09
  DEFB $0A,$08,$04,$25,$10,$0A,$08,$63
  DEFB $03,$0A,$0A,$08,$10,$22,$0F,$0A
  DEFB $08,$63,$03,$0B,$0A,$08,$0E,$28
  DEFB $0F,$0A,$08,$63,$03,$0C,$0A,$08
  DEFB $04,$28,$0F,$0A,$08,$63,$03,$0D
  DEFB $0A,$08,$04,$2A,$0F,$0A,$08,$63
  DEFB $03,$0E,$0A,$08,$04,$28,$11,$0A
  DEFB $08,$63,$03,$0F,$0A,$08,$04,$2B
  DEFB $11,$0A,$08,$63,$03,$10,$0A,$08
  DEFB $21,$35,$11,$0A,$08,$63,$03,$11
  DEFB $0A,$08,$03,$32,$07,$0A,$08,$63
  DEFB $03,$12,$0A,$08,$03,$35,$08,$0A
  DEFB $08,$63,$03,$13,$0A,$08,$0F,$2C
  DEFB $0E,$0A,$08,$63,$03,$14,$0A,$08
  DEFB $13,$38,$08,$0A,$08,$63,$03,$15
  DEFB $0A,$08,$15,$3B,$10,$0A,$08,$63
  DEFB $03,$16,$0A,$08,$14,$35,$10,$0A
  DEFB $08,$63,$03,$17,$0A,$08,$15,$37
  DEFB $10,$0A,$08,$63,$03,$18,$0A,$08
  DEFB $14,$39,$10,$0A,$08,$63,$03,$19
  DEFB $0A,$08,$01,$22,$04,$0A,$08,$63
  DEFB $03,$1A,$0A,$08,$02,$23,$0C,$0A
  DEFB $08,$63,$03,$1B,$0A,$08,$11,$2D
  DEFB $0D,$0A,$08,$63,$03,$1C,$0A,$08
  DEFB $20,$C8,$C8,$0B,$08,$06,$1E,$03
  DEFB $0F,$00,$07,$1E,$08,$1D,$00,$05
  DEFB $1F,$0E,$1E,$08,$05,$1F,$0E,$1F
  DEFB $10,$05,$1F,$0E,$20,$18,$08,$1F
  DEFB $0C,$22,$18,$0B,$1F,$10,$22,$1E
  DEFB $0B,$1F,$10,$25,$08,$63,$03,$01
  DEFB $25,$08,$1D,$2D,$07,$25,$08,$63
  DEFB $03,$04,$25,$08,$17,$1F,$02,$25
  DEFB $08,$63,$03,$05,$25,$08,$17,$22
  DEFB $01,$25,$08,$63,$03,$08,$25,$08
  DEFB $18,$24,$00,$25,$08,$63,$03,$09
  DEFB $25,$08,$18,$27,$01,$25,$08,$63
  DEFB $03,$0B,$25,$08,$1E,$2E,$05,$25
  DEFB $08,$63,$03,$0C,$25,$08,$1A,$27
  DEFB $0C,$25,$08,$63,$03,$0D,$25,$08
  DEFB $1B,$29,$0B,$25,$08,$63,$03,$0E
  DEFB $25,$08,$17,$2A,$02,$25,$08,$63
  DEFB $03,$0F,$25,$08,$19,$25,$0D,$25
  DEFB $08,$63,$03,$13,$25,$08,$1F,$2D
  DEFB $03,$25,$08,$63,$03,$07,$25,$08
  DEFB $1C,$2A,$09,$25,$08,$63,$03,$1A
  DEFB $25,$08,$16,$19,$06,$36,$10,$63
  DEFB $03,$1B,$36,$10,$09,$00,$03,$40
  DEFB $00,$63,$01,$00,$48,$00,$63,$03
  DEFB $1B,$48,$00,$0A,$20,$0C,$65,$00
  DEFB $63,$05,$00,$FF,$FF,$FF,$FF,$FF
  DEFB $03,$3F,$22,$24,$EE,$24,$EE,$24
  DEFB $EE,$24,$EE,$54,$EE,$14,$EF,$14
  DEFB $EF,$14,$EF,$14,$EF,$24,$EE,$B4
  DEFB $EE,$B4,$EE,$B4,$EE,$B4,$EE,$A4
  DEFB $ED,$A4,$ED,$A4,$ED,$A4,$ED,$B4
  DEFB $EE,$B4,$EE,$24,$EE,$24,$EE,$24
  DEFB $EE,$54,$EE,$14,$EF,$14,$EF,$64
  DEFB $EE,$64,$EE,$64,$EE,$64,$EE,$64
  DEFB $EE,$64,$EE,$64,$EE,$64,$EE,$64
  DEFB $EE,$64,$EE,$64,$EE,$24,$EF,$24
  DEFB $EF,$24,$EF,$24,$EF,$24,$EF,$64
  DEFB $EE,$B4,$EE,$B4,$EE,$A4,$ED,$A4
  DEFB $ED,$24,$EE,$54,$EE,$14,$EF,$14
  DEFB $EF,$84,$EE,$B4,$EE,$B4,$EE,$A4
  DEFB $ED,$A4,$ED,$44,$EF,$44,$EF,$44
  DEFB $EF,$14,$EF,$54,$EE,$B4,$EE,$54
  DEFB $EE,$A4,$ED,$E4,$EE,$E4,$EE,$D4
  DEFB $ED,$44,$EF,$44,$EF,$54,$EE,$B4
  DEFB $EE,$E4,$EE,$E4,$EE,$84,$EE,$14
  DEFB $EF,$14,$EF,$14,$EF,$14,$EF,$54
  DEFB $EE,$84,$EE,$84,$EE,$B4,$EE,$A4
  DEFB $ED,$A4,$ED,$A4,$ED,$44,$EF,$44
  DEFB $EF,$44,$EF,$14,$EF,$24,$EE,$B4
  DEFB $EE,$54,$EE,$A4,$ED,$E4,$EE,$E4
  DEFB $EE,$D4,$ED,$44,$EF,$44,$EF,$54
  DEFB $EE,$B4,$EE,$E4,$EE,$E4,$EE,$84
  DEFB $EE,$14,$EF,$14,$EF,$14,$EF,$14
  DEFB $EF,$84,$EE,$84,$EE,$04,$EE,$04
  DEFB $EE,$04,$EE,$04,$EE,$04,$EE,$04
  DEFB $EE,$04,$EE,$00,$00,$04,$42,$2C
  DEFB $01,$01,$05,$48,$2C,$01,$01,$06
  DEFB $42,$2C,$01,$01,$00,$41,$12,$06
  DEFB $F0,$06,$F0,$06,$F0,$06,$F0,$00
  DEFB $00,$C2,$01,$22,$B2,$EF,$A6,$EF
  DEFB $B2,$EF,$BA,$EF,$C6,$EF,$C6,$EF
  DEFB $C6,$EF,$CC,$EF,$DE,$EF,$DE,$EF
  DEFB $CE,$EF,$CE,$EF,$CE,$EF,$00,$00
  DEFB $C2,$01,$22,$B6,$EF,$A6,$EF,$B2
  DEFB $EF,$BA,$EF,$B6,$EF,$A6,$EF,$B2
  DEFB $EF,$BA,$EF,$00,$00,$D2,$01,$22
  DEFB $AA,$EF,$DE,$EF,$CE,$EF,$CE,$EF
  DEFB $CE,$EF,$CE,$EF,$CE,$EF,$CE,$EF
  DEFB $CE,$EF,$00,$00,$B2,$01,$22,$F2
  DEFB $EF,$F6,$EF,$EE,$EF,$E6,$EF,$FE
  DEFB $EF,$FE,$EF,$FE,$EF,$04,$F0,$E2
  DEFB $EF,$D6,$EF,$DE,$EF,$BA,$EF,$B6
  DEFB $EF,$AA,$EF,$B2,$EF,$BE,$EF,$00
  DEFB $00,$B2,$01,$22,$AA,$EF,$DE,$EF
  DEFB $CE,$EF,$E2,$EF,$E6,$EF,$F2,$EF
  DEFB $00,$00,$11,$41,$12,$56,$F0,$56
  DEFB $F0,$56,$F0,$56,$F0,$00,$00,$27
  DEFB $3E,$2C,$01,$01,$37,$14,$2C,$01
  DEFB $01,$47,$3E,$2C,$01,$01,$57,$3E
  DEFB $2C,$01,$01,$28,$14,$2C,$01,$01
  DEFB $38,$14,$2C,$01,$01,$48,$14,$2C
  DEFB $01,$01,$58,$14,$2C,$01,$01,$29
  DEFB $28,$2C,$01,$01,$39,$28,$2C,$01
  DEFB $01,$0A,$20,$22,$64,$EE,$64,$EE
  DEFB $64,$EE,$64,$EE,$64,$EE,$64,$EE
  DEFB $64,$EE,$64,$EE,$24,$EF,$24,$EF
  DEFB $24,$EF,$24,$EF,$24,$EF,$64,$EE
  DEFB $B4,$EE,$B4,$EE,$A4,$ED,$A4,$ED
  DEFB $24,$EE,$54,$EE,$14,$EF,$14,$EF
  DEFB $84,$EE,$B4,$EE,$B4,$EE,$A4,$ED
  DEFB $A4,$ED,$44,$EF,$44,$EF,$44,$EF
  DEFB $14,$EF,$54,$EE,$B4,$EE,$54,$EE
  DEFB $A4,$ED,$E4,$EE,$E4,$EE,$D4,$ED
  DEFB $44,$EF,$44,$EF,$54,$EE,$B4,$EE
  DEFB $E4,$EE,$E4,$EE,$84,$EE,$14,$EF
  DEFB $14,$EF,$14,$EF,$14,$EF,$54,$EE
  DEFB $84,$EE,$84,$EE,$B4,$EE,$A4,$ED
  DEFB $A4,$ED,$A4,$ED,$44,$EF,$44,$EF
  DEFB $44,$EF,$14,$EF,$24,$EE,$B4,$EE
  DEFB $54,$EE,$A4,$ED,$E4,$EE,$E4,$EE
  DEFB $D4,$ED,$44,$EF,$44,$EF,$54,$EE
  DEFB $B4,$EE,$E4,$EE,$E4,$EE,$84,$EE
  DEFB $14,$EF,$14,$EF,$14,$EF,$14,$EF
  DEFB $84,$EE,$84,$EE,$04,$EE,$04,$EE
  DEFB $04,$EE,$04,$EE,$04,$EE,$04,$EE
  DEFB $04,$EE,$00,$00,$04,$42,$2C,$16
  DEFB $16,$05,$48,$2C,$16,$16,$06,$42
  DEFB $2C,$16,$16,$2B,$14,$2C,$16,$16
  DEFB $3B,$14,$2C,$16,$16,$4B,$14,$2C
  DEFB $16,$16,$5B,$CA,$2C,$16,$16,$6B
  DEFB $14,$2C,$16,$16,$0B,$14,$2C,$16
  DEFB $16,$0F,$3F,$2C,$A4,$EF,$FF,$FF
  DEFB $67,$3E,$2C,$01,$01,$11,$3F,$2C
  DEFB $16,$F0,$16,$F0,$16,$F0,$00,$00
  DEFB $11,$3F,$2C,$26,$F0,$26,$F0,$26
  DEFB $F0,$00,$00,$11,$3F,$2C,$36,$F0
  DEFB $36,$F0,$36,$F0,$00,$00,$11,$3F
  DEFB $2C,$46,$F0,$46,$F0,$46,$F0,$00
  DEFB $00,$1E,$01,$3C,$66,$F0,$78,$F0
  DEFB $6E,$F0,$00,$00,$1E,$01,$3C,$66
  DEFB $F0,$7E,$F0,$6E,$F0,$00,$00,$1E
  DEFB $01,$3C,$66,$F0,$86,$F0,$6E,$F0
  DEFB $00,$00,$1E,$01,$3C,$66,$F0,$8C
  DEFB $F0,$6E,$F0,$00,$00,$00,$3F,$2C
  DEFB $96,$F0,$96,$F0,$96,$F0,$96,$F0
  DEFB $00,$00

; The enemy kinds StartWave reads (LevelKinds)
L3Kinds:
  DEFB $36,$EA,$23,$EB,$28,$EB,$2D,$EB
  DEFB $32,$EB,$3F,$EB,$5E,$EB,$73,$EB
  DEFB $8A,$EB,$AF,$EB,$C0,$EB,$CD,$EB
  DEFB $D2,$EB,$D7,$EB,$DC,$EB,$E1,$EB
  DEFB $E6,$EB,$EB,$EB,$F0,$EB,$F5,$EB
  DEFB $FA,$EB,$FF,$EB,$B2,$EC,$B7,$EC
  DEFB $BC,$EC,$C1,$EC,$C6,$EC,$CB,$EC
  DEFB $D0,$EC,$D5,$EC,$DA,$EC,$DF,$EC
  DEFB $E6,$EC,$EB,$EC,$F6,$EC,$01,$ED
  DEFB $0C,$ED,$17,$ED,$22,$ED,$2D,$ED
  DEFB $38,$ED,$43,$ED,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$84,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$88,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$08,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$88,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$10,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$90,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$A0,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$94,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$A4,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$98,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$A8,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$00,$29,$00,$29,$00
  DEFB $29,$00,$29,$80,$01,$80,$27,$18
  DEFB $27,$18,$27,$18,$27,$18,$27,$18
  DEFB $27,$98,$27,$10,$27,$10,$27,$10
  DEFB $27,$90,$27,$14,$27,$14,$27,$14
  DEFB $27,$14,$27,$14,$27,$94,$27,$08
  DEFB $27,$08,$27,$08,$27,$88,$25,$10
  DEFB $24,$10,$25,$10,$24,$90,$25,$21
  DEFB $24,$21,$25,$21,$24,$A1,$26,$00
  DEFB $26,$80,$26,$01,$26,$81,$27,$25
  DEFB $27,$25,$27,$25,$27,$A5,$27,$21
  DEFB $27,$21,$27,$21,$27,$A1,$27,$29
  DEFB $27,$29,$27,$29,$27,$A9,$27,$09
  DEFB $27,$09,$27,$09,$27,$89,$07,$10
  DEFB $08,$18,$09,$10,$08,$14,$07,$14
  DEFB $08,$10,$09,$18,$08,$90,$0A,$02
  DEFB $0B,$0A,$0A,$02,$0B,$0A,$0A,$02
  DEFB $0B,$0A,$0A,$02,$0B,$8A,$0C,$03
  DEFB $0D,$2B,$0C,$03,$0D,$2B,$0C,$03
  DEFB $0D,$2B,$0C,$03,$0D,$AB,$0E,$01
  DEFB $0F,$21,$0E,$01,$0F,$21,$0E,$01
  DEFB $0F,$21,$0E,$01,$0F,$A1,$0C,$01
  DEFB $0D,$25,$0C,$01,$0D,$25,$0C,$01
  DEFB $0D,$25,$0C,$01,$0D,$A5,$1F,$10
  DEFB $20,$10,$21,$10,$20,$10,$1F,$10
  DEFB $20,$10,$21,$10,$20,$90,$05,$04
  DEFB $05,$04,$05,$04,$05,$84,$05,$0A
  DEFB $05,$0A,$05,$0A,$05,$0A,$05,$8A
  DEFB $05,$14,$05,$10,$05,$9A,$05,$14
  DEFB $05,$14,$05,$1A,$05,$9A,$05,$25
  DEFB $05,$21,$05,$AB,$05,$25,$05,$25
  DEFB $05,$21,$05,$2B,$05,$AB,$02,$10
  DEFB $02,$12,$02,$10,$02,$12,$02,$10
  DEFB $02,$12,$02,$10,$02,$92

; The first mover of each kind (16 words, LevelMoves)
L3MoversA:
  DEFW L3MoverA0
  DEFW L3MoverA1
  DEFW L3MoverA2
  DEFW L3MoverA3
  DEFW L3MoverA4
  DEFW L3MoverA5
  DEFW L3MoverA6
  DEFW L3MoverA7
  DEFW L3MoverA8
  DEFW L3MoverA9
  DEFW L3MoverA10
  DEFW L3MoverA11
  DEFW L3MoverA12
  DEFW L3MoverA12
  DEFW L3MoverA12
  DEFW L3MoverA15

; The second mover of each kind (16 words, LevelMoves2)
L3MoversB:
  DEFW L3MoverB0
  DEFW L3MoverB1
  DEFW L3MoverB2
  DEFW L3MoverB3
  DEFW L3MoverB4
  DEFW L3MoverB5
  DEFW L3MoverB6
  DEFW L3MoverB7
  DEFW L3MoverB8
  DEFW L3MoverB9
  DEFW L3MoverB10
  DEFW L3MoverB10
  DEFW L3MoverB9
  DEFW L3MoverB13
  DEFW L3MoverB14
  DEFW L3MoverB15

; Mover A0
;
; Witness: L1 0 (none).
L3MoverA0:
  JP C,MoveNext
  JP MoveStore

; Mover A1
;
; Witness: L1 840 (l3).
L3MoverA1:
  JP C,MoveNext
; This entry point is used by the routines at L3MoverA2 and L3MoverA12.
l_F0EF:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveStore
  JP MoveDraw

; Mover A2
;
; Witness: L1 230 (l3).
L3MoverA2:
  JR NC,l_F0EF
  JP MoveNext

; Mover A3
;
; Witness: L1 2832 (l3).
L3MoverA3:
  LD A,$9C
  LD (DrawTag),A
  LD A,(FrameCounter)
  AND $07
  JP NZ,MoveScript
  EX AF,AF'
  PUSH BC
  PUSH DE
  PUSH AF
  LD A,$29
l_F112:
  EX AF,AF'
  LD A,C
  CP $1F
  JR NC,l_F128
  AND A
  JR Z,l_F128
  EX AF,AF'
  PUSH BC
  PUSH AF
  CALL LevelObject
  CALL DrawSprite
  POP AF
  POP BC
  JR l_F129
l_F128:
  EX AF,AF'
l_F129:
  INC C
  INC A
  CP $57
  JR NZ,l_F112
  POP AF
  POP DE
  POP BC
  EX AF,AF'
  LD A,(DE)
  AND $FC
  LD (DE),A
  JP MoveStore

; Mover A4
;
; Witness: L1 1509 (l3).
L3MoverA4:
  JP C,MoveNext
  LD HL,$0019
  LD A,(ShipRow)
  CP B
  JR NC,l_F153
  LD L,$1B
  LD A,(ShipColumn)
  INC A
  CP C
  JR Z,l_F153
  DEC L
  JR C,l_F153
  INC H
; This entry point is used by the routines at L3MoverA5, L3MoverA6, L3MoverA7,
; L3MoverA8, L3MoverA9, L3MoverA10 and L3MoverA11.
l_F153:
  LD A,L
  EX AF,AF'
  LD A,(DE)
  AND $FC
  OR H
  LD (DE),A
  JP MoveStore

; Mover A5
;
; Witness: L1 2332 (l3).
L3MoverA5:
  JR C,l_F17E
  LD HL,$0017
  LD A,(ShipRow)
  CP B
  LD A,(ShipColumn)
  JR C,l_F172
  INC A
  CP C
  JR C,l_F153
  INC H
  JR l_F153
l_F172:
  LD L,$16
  CP C
  JR Z,l_F153
  LD L,$18
  JR C,l_F153
  INC H
  JR l_F153
l_F17E:
  LD DE,$0103
  CALL AddScore
  JP MoveDone

; Mover A6
;
; Witness: L1 5545 (l3).
L3MoverA6:
  JP C,MoveNext
  LD HL,$0219
  LD A,(ShipRow)
  DEC A
  CP B
  LD A,(ShipColumn)
  JR NC,l_F19D
  CP C
  JR C,l_F153
  INC H
  JR l_F153
l_F19D:
  LD L,$1B
  CP C
  JR Z,l_F153
  DEC L
  JR C,l_F153
  INC H
  JR l_F153

; Mover A7
;
; Witness: L1 7371 (l3).
L3MoverA7:
  JP C,l_F33E
  JR Z,l_F1B9
  LD A,(FrameCounter)
  AND $01
  JR Z,l_F1B9
  LD A,$47
  LD (CellMark+15),A
l_F1B9:
  CALL L3SecondMoverLess2
  CP $00
  JP NZ,l_F274
  PUSH DE
  PUSH BC
  LD HL,LevelVars
  LD A,(HL)
  AND A
  JR Z,l_F1EA
  LD E,A
  LD A,(FrameCounter)
  AND $07
  JP NZ,l_F26E
  LD A,E
  INC A
  LD (HL),A
  ADD A,A
  LD D,$00
  LD E,A
  LD HL,L3Tail+$0073
  ADD HL,DE
  POP BC
  LD A,C
  ADD A,(HL)
  LD C,A
  INC HL
  LD A,B
  ADD A,(HL)
  LD B,A
  PUSH BC
  JP l_F26E
l_F1EA:
  LD A,(IY+$00)
  CP $28
  JR NC,l_F1F6
  LD A,$01
  LD (LevelVars),A
l_F1F6:
  LD A,(MapColumn)
  CP $0B
  JR C,l_F26E
  ADD A,A
  ADD A,A
  LD L,A
  LD A,(MetaColumn)
  ADD A,L
  RRCA
  RRCA
  AND $03
  JR NZ,l_F239
  LD A,(FrameCounter)
  AND $1F
  JR NZ,l_F217
  LD HL,$0783
  CALL $F87C
l_F217:
  LD A,(DrawTag)
  LD L,A
  PUSH BC
  PUSH HL
  LD A,$80
  LD (DrawTag),A
  LD A,C
  SUB $06
  LD C,A
  LD A,(FrameCounter)
  AND $01
  ADD A,$22
  CALL LevelObject
  CALL DrawSprite
  POP HL
  POP BC
  LD A,L
  LD (DrawTag),A
l_F239:
  LD A,(FrameCounter)
  AND $07
  JR NZ,l_F26E
  LD A,(L3Tail+$0072)
  INC A
  CP $03
  JR NZ,l_F249
  XOR A
l_F249:
  LD (L3Tail+$0072),A
  CP $00
  JR NZ,l_F257
  LD A,$65
  LD HL,L3Tail+$0065
  JR l_F267
l_F257:
  CP $01
  JR NZ,l_F262
  LD A,$64
  LD HL,L3Tail+$0068
  JR l_F267
l_F262:
  LD A,$66
  LD HL,L3Tail+$006B
l_F267:
  LD (HL),A
  INC HL
  INC C
  INC C
  LD (HL),C
  INC HL
  LD (HL),B
l_F26E:
  LD HL,$001E
  JP l_F327
l_F274:
  CP $01
  JR NZ,l_F27E
  LD HL,$005E
  JP l_F153
l_F27E:
  CP $02
  JP NZ,l_F2AC
  LD HL,LevelVars+1
  LD A,(HL)
  AND A
  JR Z,l_F29A
  LD A,(FrameCounter)
  AND $07
  JP NZ,l_F2A6
  INC (HL)
  INC B
  LD HL,$001D
  JP l_F329
l_F29A:
  LD A,(IY+$00)
  CP $28
  JR NC,l_F2A6
  LD A,$01
  LD (LevelVars+1),A
l_F2A6:
  LD HL,$001D
  JP l_F153
l_F2AC:
  CP $03
  JR NZ,l_F2D7
  LD HL,LevelVars+2
  LD A,(HL)
  AND A
  JR Z,l_F2C5
  LD A,(FrameCounter)
  AND $07
  JR NZ,l_F2D1
  INC (HL)
  INC B
  LD HL,$001C
  JR l_F329
l_F2C5:
  LD A,(IY+$00)
  CP $28
  JR NC,l_F2D1
  LD A,$01
  LD (LevelVars+2),A
l_F2D1:
  LD HL,$001C
  JP l_F153
l_F2D7:
  LD A,(LevelVars+6)
  AND A
  JR Z,l_F2E3
  DEC A
  LD (LevelVars+6),A
  JR l_F300
l_F2E3:
  LD A,C
  CP $24
  JR NC,l_F300
  LD A,(ShipRow)
  DEC A
  CP B
  JR NZ,l_F300
  LD HL,L3Tail+$00C0
  LD (HL),B
  DEC HL
  LD (HL),C
  DEC HL
  LD (HL),$2A
  CALL StartWaveAt
  LD A,$10
  LD (LevelVars+6),A
l_F300:
  LD HL,LevelVars+3
  LD A,(HL)
  AND A
  JR Z,l_F315
  LD A,(FrameCounter)
  AND $07
  JR NZ,l_F321
  INC (HL)
  INC B
  LD HL,$0028
  JR l_F329
l_F315:
  LD A,(IY+$00)
  CP $28
  JR NC,l_F321
  LD A,$01
  LD (LevelVars+3),A
l_F321:
  LD HL,$0028
  JP l_F153
l_F327:
  POP BC
  POP DE
l_F329:
  LD A,B
  CP $11
  JP C,l_F153
  LD (IY+$00),$00
  DEC B
  DEC B
  LD (Scratch),BC
  PUSH BC
  CALL EnemyDies
  POP BC
l_F33E:
  LD HL,(Scratch+2)
  LD (HL),$48
  LD HL,$0A82
  CALL $F87C
  CALL L3SecondMoverLess2
  CP $04
  JR NZ,l_F369
  LD A,C
  ADD A,$05
  LD C,A
  LD (Scratch),BC
  CALL EnemyDies
  LD HL,$0A82
  CALL $F87C
  LD HL,(Scratch+2)
  LD (HL),$48
  CALL L3SecondMoverLess2
l_F369:
  LD D,$00
  LD E,A
  LD HL,L3Tail+$00A5
  ADD HL,DE
  LD D,(HL)
  LD E,$03
  CALL AddScore
  JP MoveDone

; Mover A8
;
; Witness: L1 3332 (l3).
L3MoverA8:
  JR C,l_F3EB
  PUSH DE
  CALL L3SecondMoverLess2
  PUSH AF
  LD H,$00
  LD L,A
  LD DE,L3Tail+$006E
  ADD HL,DE
l_F387:
  LD A,(HL)
  INC A
  CP $60
  JR NZ,l_F38E
  XOR A
l_F38E:
  LD (HL),A
  RRCA
  RRCA
  RRCA
  RRCA
  AND $07
  JR Z,l_F387
  ADD A,$5F
  LD L,A
  EX AF,AF'
  POP AF
  LD H,A
  PUSH BC
  PUSH HL
  LD A,(IY+$08)
  CP $01
  JR NZ,l_F3B1
  LD HL,L3Tail+$0029
  LD BC,$0045
  CALL $FDEF
  JR l_F3E5
l_F3B1:
  LD A,H
  ADD A,A
  ADD A,A
  ADD A,H
  ADD A,L
  SUB $60
  LD D,$00
  LD E,A
  LD HL,L3Tail+$0015
  ADD HL,DE
  LD L,(HL)
  PUSH HL
  LD HL,L3Tail+$0029
  ADD HL,DE
  ADD HL,DE
  ADD HL,DE
  PUSH HL
  EX AF,AF'
  SUB $60
  JR NZ,l_F3D1
  LD DE,$000F
  ADD HL,DE
l_F3D1:
  DEC HL
  DEC HL
  DEC HL
  LD (HL),$00
  POP HL
  POP DE
  LD A,(HL)
  AND A
  JR NZ,l_F3E5
  INC B
  INC C
  LD (HL),E
  SET 4,(HL)
  INC HL
  LD (HL),C
  INC HL
  LD (HL),B
l_F3E5:
  POP HL
  POP BC
  POP DE
  JP l_F153
l_F3EB:
  LD DE,$0503
  CALL AddScore
  JP MoveScript

; Mover A9
;
; Witness: L1 11328 (l3).
L3MoverA9:
  JR C,l_F472
  LD HL,$0065
  LD A,(MapColumn)
  CP $1F
  JP C,l_F153
  CP $33
  JP NC,l_F153
  PUSH DE
  LD A,(MapColumn)
  SUB $1F
  LD D,$00
  LD E,A
  LD HL,L3Tail+$00AA
  ADD HL,DE
  LD A,(HL)
  RLCA
  AND $01
  LD E,A
  LD A,(HL)
  AND $7F
  LD H,E
  LD L,A
  POP DE
  LD A,(MapColumn)
  AND $01
  JP Z,l_F153
  LD A,(FrameCounter)
  AND $1F
  CP $04
  JR NZ,l_F437
  PUSH HL
  LD HL,$0783
  CALL $F87C
  POP HL
l_F437:
  LD A,(DrawTag)
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,L
  INC A
  CP $66
  JR Z,l_F445
  DEC B
l_F445:
  EX AF,AF'
  LD A,$80
  LD (DrawTag),A
  LD A,H
  LD HL,DrawSprite
  AND A
  JR Z,l_F455
  LD HL,DrawSpriteMirrored
l_F455:
  LD (l_F455+$0011),HL
  INC B
  INC B
  LD A,(FrameCounter)
  AND $01
  LD L,A
  EX AF,AF'
  ADD A,L
  CALL LevelObject
  CALL $0000
  POP HL
  POP DE
  POP BC
  POP AF
  LD (DrawTag),A
  JP l_F153
l_F472:
  LD DE,$0803
  CALL AddScore
  JP MoveDone

; Mover A10
;
; Witness: L1 1968 (l3).
L3MoverA10:
  JP C,l_F54E
  JR Z,l_F48D
  LD A,(L3Tail+$00C2)
  CP $15
  JR Z,l_F48D
  LD A,(LevelVars+5)
  LD (IY+$00),A
l_F48D:
  LD A,(IY+$00)
  LD (LevelVars+5),A
  LD A,(DrawTag)
  PUSH AF
  PUSH DE
  LD A,(MapColumn)
  ADD A,A
  ADD A,A
  LD L,A
  LD A,(MetaColumn)
  ADD A,L
  AND $0F
  LD D,$00
  LD E,A
  LD (L3Tail+$00C1),A
  LD A,(FrameCounter)
  AND $07
  JR NZ,l_F4C2
  LD HL,L3Tail+$00C3
  ADD HL,DE
  LD A,(HL)
  CP $80
  JR C,l_F4BD
  INC C
  JR l_F4C2
l_F4BD:
  CP $40
  JR C,l_F4C2
  DEC C
l_F4C2:
  PUSH BC
  INC C
  LD A,$80
  LD (DrawTag),A
  LD A,$10
  CALL LevelObject
  CALL DrawSprite
  POP BC
  POP DE
  POP AF
  LD (DrawTag),A
  LD A,(L3Tail+$00C1)
  CP $03
  JR Z,l_F52A
  CP $04
  JR Z,l_F52A
  CP $05
  JR Z,l_F52A
  CP $06
  JR Z,l_F52A
  CP $0A
  JR Z,l_F508
  CP $0B
  JR Z,l_F508
  CP $0E
  JP Z,l_F518
  CP $0F
  JP Z,l_F518
  LD HL,$0015
  CP $0C
  JR NC,l_F547
  LD HL,$0011
  JR l_F547
l_F508:
  LD A,(FrameCounter)
  ADD A,$10
  RRCA
  RRCA
  AND $03
  ADD A,$12
  LD H,$00
  LD L,A
  JR l_F547
l_F518:
  LD A,(FrameCounter)
  ADD A,$10
  RRCA
  RRCA
  AND $03
  LD L,A
  LD A,$15
  SUB L
  LD H,$00
  LD L,A
  JR l_F547
l_F52A:
  LD A,(FrameCounter)
  AND $03
  JR NZ,l_F544
  LD HL,L3Tail+$00C0
  LD (HL),B
  DEC HL
  INC C
  LD (HL),C
  DEC HL
  LD A,R
  AND $03
  ADD A,$26
  LD (HL),A
  CALL StartWaveAt
  DEC C
l_F544:
  LD HL,$0011
l_F547:
  LD A,L
  LD (L3Tail+$00C2),A
  JP l_F153
l_F54E:
  LD DE,$0105
  CALL AddScore
  CALL BossDestroyed
  JP MoveDone

; Mover A11
;
; Witness: L1 7026 (l3).
L3MoverA11:
  JP C,l_F5E6
  LD A,(LevelVars+4)
  AND A
  JR Z,l_F567
  DEC A
  LD (LevelVars+4),A
l_F567:
  PUSH BC
  PUSH DE
  LD A,(ShipColumn)
  LD E,A
  INC E
  LD A,(ShipRow)
  LD D,A
  CALL L3SecondMoverLess2
  LD L,$58
  CP $00
  JR Z,l_F592
  INC L
  CP $01
  JR Z,l_F59F
  INC L
  CP $02
  JR Z,l_F5AD
  INC L
  CP $03
  JR Z,l_F59F
  INC L
  CP $04
  JR Z,l_F5AD
  INC L
  JR l_F5BA
l_F592:
  LD A,E
  CP C
  JR NZ,l_F5DF
  LD A,D
  CP B
  JR C,l_F5DF
  INC B
  LD A,$22
  JR l_F5C7
l_F59F:
  LD A,E
  SUB C
  LD H,A
  LD A,D
  SUB B
  CP H
  JR NZ,l_F5DF
  INC B
  INC C
  LD A,$23
  JR l_F5C7
l_F5AD:
  LD A,D
  CP B
  JR NZ,l_F5DF
  LD A,E
  CP C
  JR C,l_F5DF
  INC C
  LD A,$24
  JR l_F5C7
l_F5BA:
  LD A,E
  SUB C
  LD H,A
  LD A,D
  SUB B
  CPL
  INC A
  CP H
  JR NZ,l_F5DF
  DEC B
  LD A,$25
l_F5C7:
  PUSH HL
  LD HL,L3Tail+$00C0
  LD (HL),B
  DEC HL
  LD (HL),C
  DEC HL
  LD (HL),A
  LD A,(LevelVars+4)
  AND A
  JR NZ,l_F5DE
  CALL StartWaveAt
  LD A,$80
  LD (LevelVars+4),A
l_F5DE:
  POP HL
l_F5DF:
  POP DE
  POP BC
  LD H,$00
  JP l_F153
l_F5E6:
  LD DE,$0203
  CALL AddScore
  JP MoveDone

; Mover A12, A13, A14
;
; Witness: L1 2358 (l3).
L3MoverA12:
  PUSH DE
  CALL GetCell
  POP DE
  JP C,l_F0EF
  LD (IY+$00),$00
  LD (Scratch),BC
  CALL EnemyDies
  LD HL,$0382
  CALL $F87C
  JP MoveDone

; Mover A15
;
; Witness: L1 2904 (l3).
L3MoverA15:
  LD A,$80
  LD (DrawTag),A
  LD HL,L3Tail+$0029
  XOR A
l_F614:
  PUSH AF
  LD A,(HL)
  AND A
  JR Z,l_F61D
  CP $80
  JR C,l_F629
l_F61D:
  INC HL
l_F61E:
  INC HL
  INC HL
  POP AF
  INC A
  CP $17
  JR NZ,l_F614
  JP MoveDone
l_F629:
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  CALL MoveByBits
  EX AF,AF'
  LD A,B
  CP $14
  JR NC,l_F668
  LD A,C
  CP $1F
  JR NC,l_F668
  CALL GetCell
  AND A
  JR Z,l_F654
  CP $06
  JR C,l_F668
  CP $FA
  JR NC,l_F668
  CP $26
  JR C,l_F668
  PUSH HL
  CALL SlotFlags
  POP HL
  JR Z,l_F668
l_F654:
  LD (HL),B
  DEC HL
  LD (HL),C
  PUSH HL
  EX AF,AF'
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  CALL LevelObject
  CALL DrawSprite
  POP HL
  JR l_F61E
l_F668:
  DEC HL
  DEC HL
  LD (HL),$80
  JR l_F61D

; Mover B0
;
; Witness: L1 13422 (l3).
L3MoverB0:
  JP MoveScript

; Mover B1
;
; Witness: L1 3393 (l3).
L3MoverB1:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveScript
  JP MoveDone

; Mover B2
;
; Witness: L1 27488 (l3).
L3MoverB2:
  XOR A
  LD (CellMark+15),A
  JP MoveScript

; Mover B3
;
; Witness: L1 10898 (l3).
L3MoverB3:
  JR L3MoverB2

; Mover B4
;
; Witness: L1 2000 (l3).
L3MoverB4:
  JR L3MoverB2

; Mover B5
;
; Witness: L1 2988 (l3).
L3MoverB5:
  JR L3MoverB2

; Mover B6
;
; Witness: L1 4277 (l3).
L3MoverB6:
  JR L3MoverB2

; Mover B7
;
; No recording ran it: known only from the code.
L3MoverB7:
  LD L,$08
  JR l_F6A5

; Mover B8
;
; No recording ran it: known only from the code.
L3MoverB8:
  LD L,$09
  JR l_F6A5

; Mover B10, B11
;
; Witness: L1 144 (l3).
L3MoverB10:
  LD L,$03
  JR l_F6A5

; Mover B9, B12
;
; Witness: L1 19 (l3).
L3MoverB9:
  LD L,$04
  JR l_F6A5

; Mover B13
;
; Witness: L1 67 (l3).
L3MoverB13:
  LD L,$05
  JR l_F6A5

; Mover B14
;
; No recording ran it: known only from the code.
L3MoverB14:
  LD L,$06
  JR l_F6A5

; Mover B15
;
; No recording ran it: known only from the code.
L3MoverB15:
  LD L,$07
; This entry point is used by the routines at L3MoverB7, L3MoverB8, L3MoverB10,
; L3MoverB9, L3MoverB13 and L3MoverB14.
l_F6A5:
  CALL L3SlotBusy
  LD A,(Carriers)
  AND A
  JR NZ,l_F6C2
  LD (Carriers+2),BC
  LD A,L
  LD (Carriers),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+1),A
  JP L3MoverB1
l_F6C2:
  LD (Carriers+6),BC
  LD A,L
  LD (Carriers+4),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+5),A
  JP L3MoverB1

; A = the slot's second mover number (high nibble of IY+5) less 2
;
; Witness: L1 17721 (l3).
L3SecondMoverLess2:
  LD A,(IY+$05)
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  DEC A
  DEC A
  RET

; Return while the slot is free; else drop the return and go on at Mover B1
; (Mover B15 calls it)
;
; Witness: L1 230 (l3).
L3SlotBusy:
  LD A,(IY+$00)
  AND A
  JR NZ,l_F6E9
  RET
l_F6E9:
  POP HL
  JP L3MoverB1

; Bytes after the movers: mover code no recording ran (JR Z / JP $F3AE ...) and
; the records the movers use at $F752-$F760 (read in the level 3 recording)
L3Tail:
  DEFB $28,$04,$08,$C3,$AE,$F3,$08,$3A
  DEFB $89,$7A,$E6,$03,$C2,$AE,$F3,$21
  DEFB $27,$F7,$70,$2B,$71,$05,$04,$06
  DEFB $02,$0A,$09,$08,$0A,$02,$06,$06
  DEFB $04,$05,$01,$09,$0A,$08,$09,$01
  DEFB $05,$22,$2B,$77,$CD,$25,$C2,$21
  DEFB $21,$11,$CD,$7C,$F8,$C3,$AE,$F3
  DEFB $00,$00,$00,$D5,$CD,$E4,$C0,$D1
  DEFB $30,$05,$FE,$9C,$C2,$AE,$F3,$FD
  DEFB $36,$00,$00,$ED,$43,$CF,$7A,$CD
  DEFB $99,$A5,$C3,$B1,$91,$C3,$A5,$91
  DEFB $3A,$89,$7A,$E6,$01,$C2,$A5,$91
  DEFB $C3,$B1,$91,$CD,$EE,$C3,$18,$F0
  DEFB $CD,$EE,$C3,$3E,$1F,$CD,$00,$00
  DEFB $00,$00,$00,$FF,$00,$FF,$00,$FF
  DEFB $00,$FF,$00,$FF,$00,$FF,$00,$FF
  DEFB $00,$FF,$01,$FF,$01,$FF,$01,$FF
  DEFB $01,$00,$01,$00,$01,$00,$01,$00
  DEFB $01,$00,$01,$00,$01,$00,$01,$00
  DEFB $01,$00,$01,$00,$01,$00,$01,$00
  DEFB $01,$00,$01,$00,$01,$06,$03,$04
  DEFB $04,$08,$65,$65,$65,$68,$68,$68
  DEFB $65,$65,$65,$65,$65,$E8,$E8,$E8
  DEFB $E8,$E8,$E8,$65,$65,$65,$00,$00
  DEFB $00,$00,$00,$40,$40,$40,$00,$00
  DEFB $00,$00,$80,$80,$80,$00,$00,$00
  DEFB $00,$00,$00
