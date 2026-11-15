; --------------------------------------------------------------------------------------------------------------------
; level5data.asm: Level 5
;
; The level's body: the header the game reads at $C4AE, the sprites, the object table, the metatiles, the map, the
; wave script, the enemy kinds and their movement scripts, the two mover tables and the movers.
; --------------------------------------------------------------------------------------------------------------------

; The level header: restart point, checkpoints and the pointers the game reads
;
; Restart column $00, restart wave $0000; checkpoint columns $00, $23, $FF with
; wave entries $D62C, $D8E8, $DA5A; objects $D14E, map $D4BA, kinds $DEC4,
; movers $E1AC and $E1C8.
L5Header:
  DEFB $00
L5RestartWave:
  DEFB $00,$00            ; the wave entry a life restarts at (the game keeps
                          ; its live copy here)
L5Checks:
  DEFB $00,$23,$FF        ; three checkpoint columns (CheckRestart)
L5WaveStarts:
  DEFB $2C,$D6,$E8,$D8,$5A,$DA ; the wave entries of the start and the
                               ; checkpoints
L5Pointers:
  DEFB $4E,$D1,$BA,$D4,$C4,$DE,$AC,$E1 ; objects, map, kinds, movers 1, movers
  DEFB $C8,$E1                         ; 2

; zeros up to the sprites
L5Spare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object
; table points at
L5Sprites:
  INCBIN "res/levels/level5/sprites.bin",$0000,3182

; The level's object table: width, height, the cells' address (LevelObject)
L5Objects:
  INCBIN "res/levels/level5/objects.bin",$0000,156

; The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from
; the map: metatile n at $D4BA - 144 x (n + 1) (MetatileAddress); 5 of them
L5Metatiles:
  INCBIN "res/levels/level5/metatiles.bin",$0000,720

; The map: 5 bytes a block column (74 columns), each byte a metatile (bits 0-5)
; and its drawer (bits 6-7)
L5Map:
  INCBIN "res/levels/level5/map.bin",$0000,370

; The wave script: entries (scroll position, kind, script) RunWaves starts;
; then the enemies' movement scripts
L5Waves:
  DEFB $08,$01,$63,$04,$04,$09,$00,$01
  DEFB $1F,$0D,$09,$04,$02,$1F,$0D,$09
  DEFB $08,$02,$1F,$0D,$09,$0C,$02,$1F
  DEFB $0D,$09,$10,$02,$1F,$0D,$09,$14
  DEFB $02,$1F,$0D,$09,$16,$03,$1F,$0D
  DEFB $0A,$10,$0B,$1F,$08,$0A,$14,$0C
  DEFB $1F,$08,$0A,$18,$0C,$1F,$08,$0A
  DEFB $1C,$0C,$1F,$08,$0B,$00,$0C,$1F
  DEFB $08,$0B,$04,$0C,$1F,$08,$0B,$08
  DEFB $0C,$1F,$08,$0B,$0C,$0C,$1F,$08
  DEFB $0B,$10,$0C,$1F,$08,$0B,$14,$0C
  DEFB $1F,$08,$0B,$16,$0D,$1F,$08,$0C
  DEFB $06,$04,$1F,$06,$0D,$08,$0E,$10
  DEFB $12,$0D,$0C,$0F,$10,$12,$0D,$10
  DEFB $0F,$10,$12,$0D,$14,$0F,$10,$12
  DEFB $0D,$18,$0F,$10,$12,$0D,$1C,$0F
  DEFB $10,$12,$0E,$00,$0F,$10,$12,$0E
  DEFB $04,$0F,$10,$12,$0E,$06,$10,$10
  DEFB $12,$0E,$18,$2C,$06,$12,$0E,$1C
  DEFB $2D,$06,$12,$0F,$00,$2D,$06,$12
  DEFB $0F,$04,$2D,$06,$12,$0F,$08,$2D
  DEFB $06,$12,$0F,$0C,$2D,$06,$12,$0F
  DEFB $0E,$2E,$06,$12,$10,$0A,$36,$1E
  DEFB $FF,$11,$18,$36,$10,$FF,$12,$00
  DEFB $04,$1F,$07,$12,$00,$01,$1F,$0D
  DEFB $12,$04,$02,$1F,$0D,$12,$08,$02
  DEFB $1F,$0D,$12,$0C,$02,$1F,$0D,$12
  DEFB $10,$02,$1F,$0D,$12,$14,$02,$1F
  DEFB $0D,$12,$18,$02,$1F,$0D,$12,$1C
  DEFB $02,$1F,$0D,$13,$00,$02,$1F,$0D
  DEFB $13,$04,$02,$1F,$0D,$13,$06,$03
  DEFB $1F,$0D,$14,$18,$36,$1E,$FF,$15
  DEFB $00,$38,$1C,$14,$15,$04,$05,$1F
  DEFB $04,$16,$04,$0E,$06,$12,$16,$08
  DEFB $0F,$06,$12,$16,$0C,$0F,$06,$12
  DEFB $16,$10,$0F,$06,$12,$16,$14,$0F
  DEFB $06,$12,$16,$18,$0F,$06,$12,$16
  DEFB $1A,$0F,$06,$12,$16,$1C,$10,$06
  DEFB $12,$17,$0C,$1A,$1A,$01,$17,$10
  DEFB $1B,$1A,$01,$17,$14,$1B,$1A,$01
  DEFB $17,$18,$1B,$1A,$01,$17,$18,$0B
  DEFB $1F,$08,$17,$1C,$1B,$1A,$01,$17
  DEFB $1C,$0C,$1F,$08,$18,$00,$1B,$1A
  DEFB $01,$18,$00,$0C,$1F,$08,$18,$04
  DEFB $1B,$1A,$01,$18,$04,$0C,$1F,$08
  DEFB $18,$08,$1B,$1A,$01,$18,$08,$0C
  DEFB $1F,$08,$18,$0A,$1C,$1A,$01,$18
  DEFB $0C,$0C,$1F,$08,$18,$10,$0C,$1F
  DEFB $08,$18,$14,$0C,$1F,$08,$18,$14
  DEFB $36,$10,$FF,$18,$18,$0C,$1F,$08
  DEFB $18,$1C,$0C,$1F,$08,$18,$1E,$0D
  DEFB $1F,$08,$1A,$00,$38,$14,$14,$1B
  DEFB $08,$36,$1E,$FF,$1B,$08,$38,$04
  DEFB $14,$1B,$18,$08,$1F,$0C,$1D,$00
  DEFB $09,$1F,$0E,$1D,$02,$09,$1F,$04
  DEFB $1D,$04,$09,$1F,$0C,$1D,$06,$09
  DEFB $1F,$08,$1D,$10,$2F,$06,$12,$1D
  DEFB $14,$30,$06,$12,$1D,$18,$30,$06
  DEFB $12,$1D,$1C,$30,$06,$12,$1E,$00
  DEFB $30,$06,$12,$1E,$00,$09,$1F,$0E
  DEFB $1E,$02,$09,$1F,$0C,$1E,$04,$63
  DEFB $03,$19,$1E,$04,$09,$1F,$08,$1E
  DEFB $04,$30,$06,$12,$1E,$06,$63,$03
  DEFB $1A,$1E,$06,$09,$1F,$04,$1E,$06
  DEFB $31,$06,$12,$1E,$18,$32,$0E,$12
  DEFB $1E,$1C,$33,$0E,$12,$1F,$00,$33
  DEFB $0E,$12,$1F,$00,$63,$03,$1B,$1F
  DEFB $00,$09,$1F,$0E,$1F,$02,$09,$1F
  DEFB $08,$1F,$04,$09,$1F,$04,$1F,$04
  DEFB $33,$0E,$12,$1F,$08,$33,$0E,$12
  DEFB $1F,$0C,$33,$0E,$12,$1F,$0E,$34
  DEFB $0E,$12,$20,$00,$1D,$1F,$0E,$20
  DEFB $00,$20,$1F,$02,$20,$04,$1E,$1F
  DEFB $0E,$20,$04,$21,$1F,$02,$20,$08
  DEFB $1E,$1F,$0E,$20,$08,$21,$1F,$02
  DEFB $20,$0C,$1E,$1F,$0E,$20,$0C,$21
  DEFB $1F,$02,$20,$10,$1E,$1F,$0E,$20
  DEFB $10,$21,$1F,$02,$20,$14,$1E,$1F
  DEFB $0E,$20,$14,$21,$1F,$02,$20,$18
  DEFB $1E,$1F,$0E,$20,$18,$21,$1F,$02
  DEFB $20,$1C,$1E,$1F,$0E,$20,$1C,$21
  DEFB $1F,$02,$21,$00,$1E,$1F,$0E,$21
  DEFB $00,$21,$1F,$02,$21,$04,$1E,$1F
  DEFB $0E,$21,$04,$21,$1F,$02,$21,$06
  DEFB $1F,$1F,$0E,$21,$06,$22,$1F,$02
  DEFB $21,$08,$38,$04,$14,$21,$08,$36
  DEFB $04,$FF,$22,$14,$36,$14,$FF,$23
  DEFB $00,$38,$1E,$14,$23,$18,$17,$1F
  DEFB $0C,$24,$08,$17,$1F,$08,$24,$0E
  DEFB $3A,$02,$FF,$27,$00,$06,$1F,$04
  DEFB $2A,$18,$17,$1E,$04,$2B,$00,$36
  DEFB $14,$FF,$2F,$00,$08,$0C,$11,$30
  DEFB $00,$38,$1C,$14,$30,$10,$04,$1F
  DEFB $04,$31,$00,$38,$1E,$14,$33,$18
  DEFB $07,$1F,$07,$35,$08,$38,$1E,$14
  DEFB $35,$18,$17,$1F,$08,$36,$08,$38
  DEFB $1E,$14,$37,$18,$17,$1F,$0C,$39
  DEFB $18,$17,$1F,$04,$3A,$00,$36,$1E
  DEFB $FF,$3B,$00,$38,$1E,$14,$3E,$08
  DEFB $08,$10,$11,$3F,$00,$36,$0A,$FF
  DEFB $3F,$00,$17,$1F,$04,$3F,$10,$38
  DEFB $1E,$14,$3F,$10,$17,$1F,$08,$40
  DEFB $00,$38,$14,$14,$40,$00,$36,$1E
  DEFB $FF,$40,$00,$17,$1F,$0C,$45,$00
  DEFB $1A,$0C,$01,$45,$04,$1B,$0C,$01
  DEFB $45,$08,$1B,$0C,$01,$45,$0C,$1B
  DEFB $0C,$01,$45,$10,$1B,$0C,$01,$45
  DEFB $10,$0E,$12,$13,$45,$14,$1B,$0C
  DEFB $01,$45,$14,$0F,$12,$13,$45,$18
  DEFB $1B,$0C,$01,$45,$18,$0F,$12,$13
  DEFB $45,$1C,$1B,$0C,$01,$45,$1C,$0F
  DEFB $12,$13,$45,$1E,$1C,$0C,$01,$46
  DEFB $00,$0F,$12,$13,$46,$04,$0F,$12
  DEFB $13,$46,$08,$0F,$12,$13,$46,$0C
  DEFB $0F,$12,$13,$46,$0E,$10,$12,$13
  DEFB $47,$10,$05,$1F,$06,$47,$10,$36
  DEFB $08,$FF,$49,$18,$63,$01,$00,$49
  DEFB $18,$63,$03,$1B,$49,$18,$18,$0C
  DEFB $14,$49,$18,$23,$0A,$14,$49,$18
  DEFB $23,$09,$16,$49,$18,$23,$0F,$1A
  DEFB $49,$18,$23,$10,$18,$49,$18,$23
  DEFB $0D,$1B,$49,$18,$23,$13,$13,$49
  DEFB $18,$23,$0E,$16,$49,$18,$23,$0B
  DEFB $18,$49,$18,$23,$10,$14,$49,$18
  DEFB $23,$0B,$1A,$49,$18,$23,$13,$17
  DEFB $49,$18,$23,$0E,$13,$49,$18,$23
  DEFB $0C,$16,$49,$18,$23,$0C,$14,$49
  DEFB $18,$23,$0E,$18,$49,$18,$23,$12
  DEFB $19,$49,$18,$23,$11,$16,$49,$18
  DEFB $23,$14,$15,$49,$18,$23,$11,$13
  DEFB $49,$18,$23,$11,$1B,$49,$18,$23
  DEFB $0F,$18,$49,$18,$23,$11,$16,$49
  DEFB $18,$23,$10,$1B,$49,$18,$23,$13
  DEFB $1A,$5F,$00,$63,$05,$00,$FF,$FF
  DEFB $FF,$FF,$FF,$13,$10,$28,$FC,$E0
  DEFB $00,$E1,$DC,$E0,$1C,$E1,$1E,$E1
  DEFB $DC,$E0,$FC,$E0,$EC,$E0,$EC,$E0
  DEFB $00,$00,$14,$0A,$23,$FC,$E0,$00
  DEFB $E1,$DC,$E0,$14,$E1,$16,$E1,$DC
  DEFB $E0,$FC,$E0,$EC,$E0,$EC,$E0,$00
  DEFB $00,$15,$0A,$23,$02,$02,$E2,$01
  DEFB $22,$5C,$E0,$68,$E0,$70,$E0,$6C
  DEFB $E0,$5C,$E0,$68,$E0,$70,$E0,$6C
  DEFB $E0,$00,$00,$C2,$01,$22,$5C,$E0
  DEFB $68,$E0,$70,$E0,$6C,$E0,$5C,$E0
  DEFB $68,$E0,$70,$E0,$6C,$E0,$00,$00
  DEFB $F2,$01,$22,$5C,$E0,$68,$E0,$70
  DEFB $E0,$6C,$E0,$5C,$E0,$68,$E0,$70
  DEFB $E0,$6C,$E0,$00,$00,$B2,$01,$22
  DEFB $5C,$E0,$68,$E0,$70,$E0,$6C,$E0
  DEFB $5C,$E0,$68,$E0,$70,$E0,$6C,$E0
  DEFB $00,$00,$16,$41,$23,$58,$E0,$4C
  DEFB $E0,$5A,$E0,$52,$E0,$FF,$FF,$17
  DEFB $01,$14,$2C,$E0,$2C,$E0,$2C,$E0
  DEFB $2C,$E0,$00,$00,$00,$3F,$1C,$44
  DEFB $E0,$3C,$E0,$3C,$E0,$3C,$E0,$00
  DEFB $00,$23,$10,$28,$FC,$E0,$DE,$E0
  DEFB $E0,$E0,$1C,$E1,$1C,$E1,$20,$E1
  DEFB $DC,$E0,$DE,$E0,$FC,$E0,$EC,$E0
  DEFB $10,$E1,$E8,$E0,$28,$E1,$E8,$E0
  DEFB $10,$E1,$E8,$E0,$28,$E1,$F4,$E0
  DEFB $24,$E1,$E4,$E0,$0C,$E1,$EC,$E0
  DEFB $EC,$E0,$EC,$E0,$00,$00,$24,$0A
  DEFB $23,$FC,$E0,$DE,$E0,$E0,$E0,$14
  DEFB $E1,$14,$E1,$18,$E1,$DC,$E0,$DE
  DEFB $E0,$FC,$E0,$EC,$E0,$08,$E1,$E8
  DEFB $E0,$28,$E1,$E8,$E0,$08,$E1,$E8
  DEFB $E0,$28,$E1,$F4,$E0,$24,$E1,$E4
  DEFB $E0,$04,$E1,$EC,$E0,$EC,$E0,$EC
  DEFB $E0,$00,$00,$25,$0A,$23,$0C,$0C
  DEFB $33,$10,$28,$EC,$E0,$EC,$E0,$10
  DEFB $E1,$E4,$E0,$28,$E1,$F4,$E0,$F4
  DEFB $E0,$00,$00,$34,$0A,$23,$EC,$E0
  DEFB $EC,$E0,$08,$E1,$E4,$E0,$28,$E1
  DEFB $F4,$E0,$F4,$E0,$00,$00,$35,$0A
  DEFB $23,$0F,$0F,$43,$10,$28,$F4,$E0
  DEFB $F4,$E0,$F8,$E0,$28,$E1,$E4,$E0
  DEFB $E8,$E0,$10,$E1,$EC,$E0,$F0,$E0
  DEFB $0E,$E1,$E4,$E0,$E4,$E0,$00,$00
  DEFB $44,$0A,$23,$F4,$E0,$F4,$E0,$F8
  DEFB $E0,$28,$E1,$E4,$E0,$E8,$E0,$08
  DEFB $E1,$EC,$E0,$F0,$E0,$06,$E1,$E4
  DEFB $E0,$E4,$E0,$00,$00,$45,$0A,$23
  DEFB $12,$12,$53,$10,$28,$FC,$E0,$00
  DEFB $E1,$DC,$E0,$1C,$E1,$DC,$E0,$FC
  DEFB $E0,$DC,$E0,$1C,$E1,$1E,$E1,$00
  DEFB $00,$54,$0A,$23,$FC,$E0,$00,$E1
  DEFB $DC,$E0,$14,$E1,$DC,$E0,$FC,$E0
  DEFB $DC,$E0,$14,$E1,$16,$E1,$00,$00
  DEFB $55,$0A,$23,$15,$15,$18,$3E,$48
  DEFB $0C,$E0,$0C,$E0,$0C,$E0,$0C,$E0
  DEFB $0C,$E0,$0C,$E0,$0C,$E0,$0C,$E0
  DEFB $24,$E0,$00,$00,$2A,$3E,$4C,$0A
  DEFB $E0,$3C,$DF,$9C,$DF,$BC,$DF,$7C
  DEFB $DF,$8C,$DF,$FC,$DF,$5C,$DF,$5C
  DEFB $DF,$FC,$DF,$4C,$DF,$3C,$DF,$4C
  DEFB $DF,$BC,$DF,$7C,$DF,$8C,$DF,$CC
  DEFB $DF,$3C,$DF,$CC,$DF,$AC,$DF,$FC
  DEFB $DF,$4C,$DF,$7C,$DF,$8C,$DF,$AC
  DEFB $DF,$5C,$DF,$8C,$DF,$CC,$DF,$BC
  DEFB $DF,$4C,$DF,$BC,$DF,$6C,$DF,$54
  DEFB $DF,$EC,$DF,$00,$00,$63,$10,$28
  DEFB $F4,$E0,$F4,$E0,$20,$E1,$DC,$E0
  DEFB $00,$E1,$EC,$E0,$EC,$E0,$00,$00
  DEFB $64,$0A,$23,$F4,$E0,$F4,$E0,$18
  DEFB $E1,$DC,$E0,$00,$E1,$EC,$E0,$EC
  DEFB $E0,$00,$00,$65,$0A,$23,$1B,$1B
  DEFB $73,$10,$28,$DC,$E0,$DC,$E0,$DC
  DEFB $E0,$DC,$E0,$DC,$E0,$DC,$E0,$02
  DEFB $E1,$F0,$E0,$12,$E1,$E4,$E0,$E4
  DEFB $E0,$E4,$E0,$E4,$E0,$E4,$E0,$E8
  DEFB $E0,$00,$00,$74,$0A,$23,$DC,$E0
  DEFB $DC,$E0,$DC,$E0,$DC,$E0,$DC,$E0
  DEFB $DC,$E0,$02,$E1,$F0,$E0,$0A,$E1
  DEFB $E4,$E0,$E4,$E0,$E4,$E0,$E4,$E0
  DEFB $E4,$E0,$E8,$E0,$00,$00,$75,$0A
  DEFB $23,$1E,$1E,$83,$10,$28,$DC,$E0
  DEFB $DC,$E0,$DC,$E0,$DC,$E0,$DC,$E0
  DEFB $DC,$E0,$22,$E1,$F8,$E0,$2A,$E1
  DEFB $E4,$E0,$E4,$E0,$E4,$E0,$E4,$E0
  DEFB $E4,$E0,$E8,$E0,$00,$00,$84,$0A
  DEFB $23,$DC,$E0,$DC,$E0,$DC,$E0,$DC
  DEFB $E0,$DC,$E0,$DC,$E0,$1A,$E1,$F8
  DEFB $E0,$2A,$E1,$E4,$E0,$E4,$E0,$E4
  DEFB $E0,$E4,$E0,$E4,$E0,$E8,$E0,$00
  DEFB $00,$85,$0A,$23,$21,$21,$29,$1A
  DEFB $22,$0A,$E0,$3C,$DF,$9C,$DF,$BC
  DEFB $DF,$7C,$DF,$8C,$DF,$FC,$DF,$5C
  DEFB $DF,$5C,$DF,$FC,$DF,$4C,$DF,$3C
  DEFB $DF,$4C,$DF,$BC,$DF,$7C,$DF,$8C
  DEFB $DF,$CC,$DF,$3C,$DF,$CC,$DF,$AC
  DEFB $DF,$FC,$DF,$4C,$DF,$7C,$DF,$8C
  DEFB $DF,$AC,$DF,$5C,$DF,$8C,$DF,$CC
  DEFB $DF,$BC,$DF,$4C,$DF,$BC,$DF,$6C
  DEFB $DF,$54,$DF,$EC,$DF,$00,$00,$00
  DEFB $0A,$23,$2C,$E1,$2C,$E1,$2C,$E1
  DEFB $2C,$E1,$00,$00,$00,$00,$00,$0A
  DEFB $23,$3C,$E1,$3C,$E1,$3C,$E1,$3C
  DEFB $E1,$00,$00,$00,$00,$00,$0A,$23
  DEFB $4C,$E1,$4C,$E1,$4C,$E1,$4C,$E1
  DEFB $00,$00,$00,$00,$00,$0A,$23,$5C
  DEFB $E1,$5C,$E1,$5C,$E1,$5C,$E1,$00
  DEFB $00,$00,$00,$00,$0A,$23,$6C,$E1
  DEFB $6C,$E1,$6C,$E1,$6C,$E1,$00,$00
  DEFB $00,$00,$00,$0A,$23,$7C,$E1,$7C
  DEFB $E1,$7C,$E1,$7C,$E1,$00,$00,$00
  DEFB $00,$00,$0A,$23,$8C,$E1,$8C,$E1
  DEFB $8C,$E1,$8C,$E1,$00,$00,$00,$00
  DEFB $00,$0A,$23,$9C,$E1,$9C,$E1,$9C
  DEFB $E1,$9C,$E1,$00,$00,$00,$00,$93
  DEFB $10,$28,$EC,$E0,$EC,$E0,$10,$E1
  DEFB $E4,$E0,$28,$E1,$F4,$E0,$F4,$E0
  DEFB $00,$00,$94,$0A,$23,$EC,$E0,$EC
  DEFB $E0,$08,$E1,$E4,$E0,$28,$E1,$F4
  DEFB $E0,$F4,$E0,$00,$00,$95,$0A,$23
  DEFB $0F,$0F,$A3,$10,$28,$EC,$E0,$EC
  DEFB $E0,$10,$E1,$E4,$E0,$28,$E1,$F4
  DEFB $E0,$F4,$E0,$00,$00,$A4,$0A,$23
  DEFB $EC,$E0,$EC,$E0,$08,$E1,$E4,$E0
  DEFB $28,$E1,$F4,$E0,$F4,$E0,$00,$00
  DEFB $A5,$0A,$23,$0F,$0F,$B3,$10,$28
  DEFB $EC,$E0,$EC,$E0,$10,$E1,$E4,$E0
  DEFB $28,$E1,$F4,$E0,$F4,$E0,$00,$00
  DEFB $B4,$0A,$23,$EC,$E0,$EC,$E0,$08
  DEFB $E1,$E4,$E0,$28,$E1,$F4,$E0,$F4
  DEFB $E0,$00,$00,$B5,$0A,$23,$0F,$0F
  DEFB $1D,$41,$13,$7C,$E0,$7C,$E0,$00
  DEFB $00,$2D,$41,$13,$88,$E0,$88,$E0
  DEFB $00,$00,$3D,$41,$13,$94,$E0,$94
  DEFB $E0,$00,$00,$4D,$41,$13,$A0,$E0
  DEFB $A0,$E0,$00,$00,$5D,$41,$13,$AC
  DEFB $E0,$AC,$E0,$00,$00,$6D,$41,$13
  DEFB $B8,$E0,$B8,$E0,$00,$00,$7D,$41
  DEFB $13,$C4,$E0,$C4,$E0,$00,$00,$8D
  DEFB $41,$13,$D0,$E0,$D0,$E0,$00,$00

; The enemy kinds StartWave reads (LevelKinds)
L5Kinds:
  DEFB $5F,$DA,$76,$DA,$8D,$DA,$92,$DA
  DEFB $A7,$DA,$BC,$DA,$D1,$DA,$E6,$DA
  DEFB $F3,$DA,$00,$DB,$0D,$DB,$42,$DB
  DEFB $77,$DB,$7C,$DB,$8F,$DB,$A2,$DB
  DEFB $A7,$DB,$C4,$DB,$E1,$DB,$E6,$DB
  DEFB $FD,$DB,$14,$DC,$19,$DC,$30,$DC
  DEFB $79,$DC,$79,$DC,$8C,$DC,$9F,$DC
  DEFB $A4,$DC,$C7,$DC,$EA,$DC,$EF,$DC
  DEFB $12,$DD,$35,$DD,$3A,$DD,$83,$DD
  DEFB $92,$DD,$A1,$DD,$B0,$DD,$BF,$DD
  DEFB $CE,$DD,$DD,$DD,$EC,$DD,$FB,$DD
  DEFB $0E,$DE,$21,$DE,$26,$DE,$39,$DE
  DEFB $4C,$DE,$51,$DE,$64,$DE,$77,$DE
  DEFB $7C,$DE,$85,$DE,$8E,$DE,$97,$DE
  DEFB $A0,$DE,$A9,$DE,$B2,$DE,$BB,$DE
  DEFB $08,$00,$08,$04,$08,$00,$08,$04
  DEFB $08,$00,$08,$04,$08,$00,$08,$84
  DEFB $08,$00,$08,$08,$08,$00,$08,$08
  DEFB $08,$00,$08,$08,$08,$00,$08,$88
  DEFB $08,$00,$08,$10,$08,$00,$08,$10
  DEFB $08,$00,$08,$10,$08,$00,$08,$10
  DEFB $08,$00,$08,$10,$08,$00,$08,$10
  DEFB $08,$00,$08,$10,$08,$00,$08,$90
  DEFB $08,$00,$08,$20,$08,$00,$08,$20
  DEFB $08,$00,$08,$20,$08,$00,$08,$20
  DEFB $08,$00,$08,$20,$08,$00,$08,$20
  DEFB $08,$00,$08,$20,$08,$00,$08,$A0
  DEFB $08,$00,$08,$14,$08,$00,$08,$14
  DEFB $08,$00,$08,$14,$08,$00,$08,$14
  DEFB $08,$00,$08,$14,$08,$00,$08,$14
  DEFB $08,$00,$08,$14,$08,$00,$08,$94
  DEFB $08,$00,$08,$24,$08,$00,$08,$24
  DEFB $08,$00,$08,$24,$08,$00,$08,$A4
  DEFB $08,$00,$08,$18,$08,$00,$08,$18
  DEFB $08,$00,$08,$18,$08,$00,$08,$98
  DEFB $08,$00,$08,$28,$08,$00,$08,$28
  DEFB $08,$00,$08,$28,$08,$00,$08,$A8
  DEFB $08,$00,$08,$00,$08,$00,$08,$00
  DEFB $08,$00,$08,$00,$08,$00,$08,$00
  DEFB $08,$00,$08,$00,$08,$00,$08,$00
  DEFB $08,$00,$08,$00,$08,$00,$08,$80
  DEFB $1A,$00,$1A,$00,$1A,$00,$1A,$10
  DEFB $1A,$00,$1A,$00,$1A,$00,$1A,$10
  DEFB $1A,$00,$1A,$00,$1A,$00,$1A,$10
  DEFB $1A,$00,$1A,$00,$1A,$00,$1A,$90
  DEFB $1B,$10,$1C,$10,$1D,$10,$1C,$12
  DEFB $1B,$10,$1C,$10,$1D,$10,$1C,$92
  DEFB $02,$12,$02,$10,$02,$12,$02,$10
  DEFB $02,$12,$02,$10,$02,$12,$02,$90
  DEFB $05,$00,$06,$00,$06,$80,$07,$00
  DEFB $06,$00,$06,$80,$05,$80,$07,$80
  DEFB $0D,$18,$0D,$18,$0D,$18,$0D,$18
  DEFB $0D,$18,$0D,$98,$0D,$10,$0D,$10
  DEFB $0D,$10,$0D,$90,$0D,$14,$0D,$14
  DEFB $0D,$14,$0D,$14,$0D,$14,$0D,$94
  DEFB $0E,$21,$0E,$21,$0F,$29,$0F,$29
  DEFB $10,$08,$10,$88,$10,$08,$10,$08
  DEFB $0F,$18,$0F,$18,$0E,$10,$0E,$90
  DEFB $0E,$10,$0E,$10,$0F,$16,$0F,$16
  DEFB $10,$06,$10,$86,$10,$06,$10,$06
  DEFB $0F,$27,$0F,$27,$0E,$21,$0E,$A1
  DEFB $0E,$10,$0E,$10,$0F,$18,$0F,$18
  DEFB $10,$08,$10,$88,$10,$08,$10,$08
  DEFB $0F,$29,$0F,$29,$0E,$21,$0E,$A1
  DEFB $0E,$21,$0E,$21,$0F,$27,$0F,$27
  DEFB $10,$06,$10,$86,$10,$06,$10,$06
  DEFB $0F,$16,$0F,$16,$0E,$10,$0E,$90
  DEFB $13,$11,$13,$11,$13,$11,$13,$91
  DEFB $13,$22,$13,$22,$13,$22,$13,$A2
  DEFB $11,$05,$11,$05,$11,$05,$11,$85
  DEFB $11,$0A,$11,$0A,$11,$0A,$11,$8A
  DEFB $12,$15,$12,$15,$12,$15,$12,$95
  DEFB $12,$27,$12,$27,$12,$27,$12,$A7
  DEFB $12,$24,$12,$24,$12,$24,$12,$A4
  DEFB $12,$18,$12,$18,$12,$18,$12,$98
  DEFB $23,$18,$23,$18,$23,$18,$23,$98
  DEFB $12,$2A,$12,$2A,$12,$2A,$12,$AA
  DEFB $12,$04,$12,$06,$12,$07,$12,$05
  DEFB $12,$04,$12,$06,$12,$07,$12,$85
  DEFB $12,$24,$12,$26,$12,$27,$12,$25
  DEFB $12,$24,$12,$26,$12,$27,$12,$A5
  DEFB $12,$20,$12,$22,$12,$23,$12,$21
  DEFB $12,$20,$12,$22,$12,$23,$12,$A1
  DEFB $12,$28,$12,$2A,$12,$2B,$12,$29
  DEFB $12,$28,$12,$2A,$12,$2B,$12,$A9
  DEFB $12,$08,$12,$0A,$12,$0B,$12,$09
  DEFB $12,$08,$12,$0A,$12,$0B,$12,$89
  DEFB $12,$18,$12,$1A,$12,$1B,$12,$19
  DEFB $12,$18,$12,$1A,$12,$1B,$12,$99
  DEFB $12,$10,$12,$12,$12,$13,$12,$11
  DEFB $12,$10,$12,$12,$12,$13,$12,$91
  DEFB $12,$14,$12,$16,$12,$17,$12,$15
  DEFB $12,$14,$12,$16,$12,$17,$12,$95

; The first mover of each kind (14 words, LevelMoves)
L5MoversA:
  DEFW L5MoverA0
  DEFW L5MoverA1
  DEFW L5MoverA2
  DEFW L5MoverA3
  DEFW L5MoverA4
  DEFW L5MoverA5
  DEFW L5MoverA6
  DEFW L5MoverA7
  DEFW L5MoverA8
  DEFW L5MoverA9
  DEFW L5MoverA10
  DEFW L5MoverA11
  DEFW L5MoverA12
  DEFW L5MoverA13

; The second mover of each kind (16 words, LevelMoves2)
L5MoversB:
  DEFW L5MoverB0
  DEFW L5MoverB1
  DEFW L5MoverB2
  DEFW L5MoverB3
  DEFW L5MoverB3
  DEFW L5MoverB3
  DEFW L5MoverB3
  DEFW L5MoverB3
  DEFW L5MoverB8
  DEFW L5MoverB9
  DEFW L5MoverB10
  DEFW L5MoverB10
  DEFW L5MoverB9
  DEFW L5MoverB13
  DEFW L5MoverB14
  DEFW L5MoverB15

; Mover A0
;
; Witness: L1 0 (none).
L5MoverA0:
  JP C,MoveNext
  JP MoveStore

; Mover A1
;
; No recording ran it: known only from the code.
L5MoverA1:
  JP C,MoveNext
; This entry point is used by the routines at L5MoverA2, L5MoverA6, L5MoverA7,
; L5MoverA8, L5MoverA9 and L5MoverA10.
l_E1F1:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveStore
  JP MoveDraw

; Mover A2
;
; Witness: L1 101 (l5).
L5MoverA2:
  JR NC,l_E1F1
  JP MoveNext

; Mover A3
;
; Witness: L1 453 (l5).
L5MoverA3:
  JP NC,l_E706
  PUSH DE
  PUSH BC
  LD IX,EnemySlots
  LD DE,$0009
  LD B,$1C
  LD C,$03
l_E211:
  LD A,(IY+$05)
  AND $F0
  LD L,A
  LD A,(IX+$05)
  AND $F0
  CP L
  JR NZ,l_E23D
  LD A,C
  INC A
  CP $08
  JR NZ,l_E226
  XOR A
l_E226:
  LD C,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  SUB C
  LD H,$00
  LD L,A
  LD DE,L5Waves+$0757
  ADD HL,DE
  LD (IX+$06),L
  LD (IX+$07),H
  LD (IX+$08),$00
l_E23D:
  LD DE,$0009
  ADD IX,DE
  DJNZ l_E211
  POP BC
  POP DE
  JP MoveDone

; Mover A4
;
; Witness: L1 4378 (l5).
L5MoverA4:
  JP NC,l_E296
  PUSH DE
  PUSH BC
  LD IX,EnemySlots
  LD B,$1C
l_E254:
  LD A,(IX+$00)
  AND A
  JR Z,l_E28A
  LD A,(IY+$05)
  AND $F0
  LD L,A
  LD A,(IX+$05)
  AND $F0
  CP L
  JR NZ,l_E28A
  LD A,(IY+$08)
  CP (IX+$08)
  JR NC,l_E28A
  LD C,$0B
  LD A,(IX+$05)
  AND $0F
  CP $05
  JR Z,l_E28A
  CP $03
  JR Z,l_E281
  LD C,$0C
l_E281:
  LD A,(IX+$05)
  AND $F0
  OR C
  LD (IX+$05),A
l_E28A:
  LD DE,$0009
  ADD IX,DE
  DJNZ l_E254
  POP BC
  POP DE
  JP MoveDone
l_E296:
  EX AF,AF'
  ADD A,$03
  EX AF,AF'
  JP l_E706

; Mover A5
;
; Witness: L1 616 (l5).
L5MoverA5:
  EX AF,AF'
  ADD A,$06
  EX AF,AF'
  JP l_E706

; Mover A6
;
; Witness: L1 39 (l5).
L5MoverA6:
  JP C,MoveDone
  LD A,(ShipColumn)
  CP C
  LD L,$01
  JR NC,l_E2B1
  LD L,$00
l_E2B1:
  LD A,(DE)
  AND $FE
  OR L
  LD (DE),A
  LD A,(IY+$08)
  AND $01
  JP Z,l_E1F1
  PUSH BC
  PUSH DE
  LD H,B
  LD L,C
  INC H
  INC L
  LD A,(ShipRow)
  CP H
  JR C,l_E2CF
  INC B
  INC H
  INC H
  JR l_E2D2
l_E2CF:
  DEC B
  DEC H
  DEC H
l_E2D2:
  LD A,(ShipColumn)
  CP L
  JR C,l_E2DD
  INC C
  INC L
  INC L
  JR l_E2E0
l_E2DD:
  DEC C
  DEC L
  DEC L
l_E2E0:
  PUSH BC
  PUSH HL
  POP BC
  CALL GetCell
  AND A
  JR Z,l_E2EF
  POP HL
  POP DE
  POP BC
  JP MoveStore
l_E2EF:
  POP BC
  POP DE
  POP HL
  JP MoveStore

; Mover A7
;
; Witness: L1 320 (l5).
L5MoverA7:
  JP C,MoveDone
  LD A,(FrameCounter)
  SUB $08
  AND $1F
  JP NZ,l_E1F1
  LD HL,L5SpawnA+$0002
  LD A,(IY+$04)
  LD (HL),A
  DEC HL
  LD A,(IY+$03)
  DEC A
  DEC A
  LD (HL),A
  DEC HL
  CALL StartWaveAt
  JP l_E1F1

; A wave record (kind $0A) the movers fill and pass to StartWaveAt
L5SpawnA:
  DEFB $0A,$00,$00

; Mover A8
;
; Witness: L1 1836 (l5).
L5MoverA8:
  JP C,MoveDone
  LD A,(FrameCounter)
  AND $1F
  JP NZ,l_E1F1
  LD HL,L5SpawnA+$0002
  LD A,R
  AND $03
  ADD A,(IY+$04)
  LD (HL),A
  DEC HL
  LD A,(IY+$03)
  DEC A
  DEC A
  LD (HL),A
  DEC HL
  CALL StartWaveAt
  JP l_E1F1

; A wave record (kind $0A): nothing in the level names it (known only from the
; code)
L5SpawnB:
  DEFB $0A,$00,$00

; Mover A9
;
; Witness: L1 4030 (l5).
L5MoverA9:
  JP C,MoveDone
  JP Z,l_E34C
  LD A,$46
  LD (CellMark+15),A
l_E34C:
  LD A,R
  AND $03
  LD L,A
  ADD A,$1E
  EX AF,AF'
  LD A,(DE)
  AND $FC
  OR L
  LD (DE),A
  LD A,(LevelVars)
  AND A
  JR Z,l_E368
  CALL L5SlotDir
  CALL L5StepDir
  JP MoveDraw
l_E368:
  LD A,(IY+$08)
  CP $03
  JP C,l_E1F1
  CALL L5SlotDir
  AND A
  JR NZ,l_E3D2
  LD A,(LevelVars+1)
  AND A
  JP NZ,l_E1F1
  LD A,(FrameCounter)
  AND $07
  JP NZ,l_E1F1
  LD A,R
  AND $07
  JP NZ,l_E1F1
  INC A
  LD (LevelVars+1),A
  PUSH DE
  PUSH BC
  PUSH HL
  INC B
  INC C
  LD L,$00
  LD A,(ShipRow)
  CP B
  JR Z,l_E3A5
  JR C,l_E3A3
  SET 1,L
  JR l_E3A5
l_E3A3:
  SET 0,L
l_E3A5:
  LD A,(ShipColumn)
  CP C
  JR Z,l_E3B3
  JR C,l_E3B1
  SET 3,L
  JR l_E3B3
l_E3B1:
  SET 2,L
l_E3B3:
  DEC L
  LD H,$00
  LD DE,L5SlotDirs+$0048
  ADD HL,DE
  POP DE
  POP BC
  LD A,(HL)
  LD (DE),A
  INC DE
  LD A,(EnemySlots+237)
  SUB C
  CPL
  INC A
  LD (DE),A
  INC DE
  LD A,(EnemySlots+238)
  SUB B
  CPL
  INC A
  LD (DE),A
  POP DE
  JP l_E1F1
l_E3D2:
  CP $80
  JR NC,l_E3F2
  CALL L5StepDir
  LD A,C
  CP $01
  JR Z,l_E3ED
  CP $1C
  JR Z,l_E3ED
  LD A,B
  AND A
  JR Z,l_E3ED
  CP $11
  JR Z,l_E3ED
  JP MoveDraw
l_E3ED:
  SET 7,(HL)
  JP l_E1F1
l_E3F2:
  INC HL
  INC HL
  PUSH DE
  PUSH BC
  LD A,(EnemySlots+238)
  ADD A,(HL)
  DEC HL
  CP B
  JR Z,l_E404
  JR C,l_E403
  INC B
  JR l_E404
l_E403:
  DEC B
l_E404:
  LD A,(EnemySlots+237)
  ADD A,(HL)
  DEC HL
  CP C
  JR Z,l_E412
  JR C,l_E411
  INC C
  JR l_E412
l_E411:
  DEC C
l_E412:
  POP DE
  LD A,B
  CP D
  JR NZ,l_E41D
  LD A,C
  CP E
  JR NZ,l_E41D
  LD (HL),$00
l_E41D:
  POP DE
  JP l_E1F1

; Mover A10
;
; Witness: L1 212 (l5).
L5MoverA10:
  JR C,l_E429
  JP NZ,l_E4A9
  JP l_E4B5
l_E429:
  LD (IY+$00),$3E
  LD HL,(Scratch+2)
  LD (HL),$00
  LD A,(LevelVars+2)
  INC A
  LD (LevelVars+2),A
  CP $04
  JR NZ,l_E4A9
  LD (IY+$00),$00
  LD (HL),$30
  PUSH BC
  LD (Scratch),BC
  CALL EnemyDies
  POP BC
  INC C
  INC C
  INC C
  PUSH BC
  LD (Scratch),BC
  CALL EnemyDies
  POP BC
  INC B
  INC B
  INC B
  PUSH BC
  LD (Scratch),BC
  CALL EnemyDies
  POP BC
  DEC C
  DEC C
  DEC C
  LD (Scratch),BC
  CALL EnemyDies
  LD DE,$0204
  CALL AddScore
  PUSH IY
  LD IY,EnemySlots
  LD DE,$0009
  LD B,$1C
l_E47F:
  LD A,(IY+$00)
  AND A
  JR Z,l_E498
  PUSH BC
  LD (IY+$00),$00
  LD C,(IY+$03)
  LD B,(IY+$04)
  LD (Scratch),BC
  CALL EnemyDies
  POP BC
l_E498:
  LD DE,$0009
  ADD IY,DE
  DJNZ l_E47F
  LD A,$5D
  LD (MapColumn),A
  POP IY
  JP MoveDone
l_E4A9:
  LD A,(FrameCounter)
  AND $01
  JR Z,l_E4B5
  LD A,$47
  LD (CellMark+15),A
l_E4B5:
  XOR A
  LD (LevelVars+1),A
  LD A,(IY+$08)
  CP $01
  JR Z,l_E4E6
  CP $22
  JR NZ,l_E4F6
  PUSH BC
  PUSH DE
  LD HL,L5SlotDirs
  LD B,$18
  XOR A
l_E4CC:
  LD (HL),A
  INC (HL)
  INC A
  AND $07
  INC HL
  INC HL
  INC HL
  DJNZ l_E4CC
  POP DE
  POP BC
  LD A,$01
  LD (LevelVars),A
  INC (IY+$03)
  LD C,(IY+$03)
  JP MoveDraw
l_E4E6:
  PUSH BC
  PUSH DE
  LD HL,L5SlotDirs
  LD BC,$0048
  CALL $FDEF
  POP DE
  POP BC
  JP l_E1F1
l_E4F6:
  LD A,(DE)
  AND $FC
  LD (DE),A
  JP l_E1F1

; Mover A11
;
; Witness: L1 29 (l5).
L5MoverA11:
  JP l_E746

; Mover A12
;
; Witness: L1 328 (l5).
L5MoverA12:
  EX AF,AF'
  ADD A,$03
  EX AF,AF'
  JP l_E746

; Mover A13
;
; Witness: L1 568 (l5).
L5MoverA13:
  LD A,(IY+$08)
  CP $02
  JP NZ,l_E706
  LD A,C
  CP $28
  JR C,l_E518
  CP $F5
  JR C,l_E521
l_E518:
  LD A,B
  CP $1E
  JR C,l_E528
  CP $F5
  JR NC,l_E528
l_E521:
  LD (IY+$00),$00
  JP l_E706
l_E528:
  PUSH BC
  PUSH DE
  DEC (IY+$08)
  LD A,(ShipColumn)
  INC A
  LD L,A
  LD A,(ShipRow)
  LD H,A
  INC B
  INC C
  LD A,(IY+$05)
  RRCA
  RRCA
  RRCA
  RRCA
  AND $0F
  CP $01
  JR Z,l_E561
  CP $02
  JR Z,l_E567
  CP $03
  JR Z,l_E56D
  CP $04
  JR Z,l_E573
  CP $05
  JR Z,l_E561
  CP $06
  JR Z,l_E573
  CP $07
  JR Z,l_E56D
  CP $08
  JR Z,l_E567
l_E561:
  LD A,L
  CP C
  JR NC,l_E5AB
  JR l_E583
l_E567:
  LD A,H
  CP B
  JR NC,l_E5A1
  JR l_E58D
l_E56D:
  LD A,L
  CP C
  JR NC,l_E597
  JR l_E5BF
l_E573:
  LD A,H
  CP B
  JR NC,l_E579
  JR l_E5B5
l_E579:
  LD HL,L5Waves+$0850
  LD DE,L5Kinds+$01B8
  LD A,$10
  JR l_E5C7
l_E583:
  LD HL,L5Waves+$0859
  LD DE,L5Kinds+$01C4
  LD A,$20
  JR l_E5C7
l_E58D:
  LD HL,L5Waves+$0862
  LD DE,L5Kinds+$01D0
  LD A,$30
  JR l_E5C7
l_E597:
  LD HL,L5Waves+$086B
  LD DE,L5Kinds+$01DC
  LD A,$40
  JR l_E5C7
l_E5A1:
  LD HL,L5Waves+$0874
  LD DE,L5Kinds+$01E8
  LD A,$50
  JR l_E5C7
l_E5AB:
  LD HL,L5Waves+$087D
  LD DE,L5Kinds+$01F4
  LD A,$60
  JR l_E5C7
l_E5B5:
  LD HL,L5Waves+$0886
  LD DE,L5Kinds+$0200
  LD A,$70
  JR l_E5C7
l_E5BF:
  LD HL,L5Waves+$088F
  LD DE,L5Kinds+$020C
  LD A,$80
l_E5C7:
  LD (IY+$06),L
  LD (IY+$07),H
  LD (IY+$01),E
  LD (IY+$02),D
  LD L,A
  LD A,(IY+$05)
  AND $0F
  OR L
  LD (IY+$05),A
  POP DE
  POP BC
  JP l_E746

; Mover B0
;
; Witness: L1 1904 (l5).
L5MoverB0:
  JP MoveScript

; Mover B1
;
; Witness: L1 6505 (l5).
L5MoverB1:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveScript
  JP MoveDone

; Mover B2
;
; Witness: L1 4228 (l5).
L5MoverB2:
  XOR A
  LD (CellMark+15),A
  JR L5MoverB1

; Mover B3, B4, B5, B6, B7
;
; No recording ran it: known only from the code.
L5MoverB3:
  LD L,$08
  JR l_E610

; Mover B8
;
; No recording ran it: known only from the code.
L5MoverB8:
  LD L,$09
  JR l_E610

; Mover B10, B11
;
; Witness: L1 25 (l5).
L5MoverB10:
  LD L,$03
  JR l_E610

; Mover B9, B12
;
; Witness: L1 4 (l5).
L5MoverB9:
  LD L,$04
  JR l_E610

; Mover B13
;
; No recording ran it: known only from the code.
L5MoverB13:
  LD L,$05
  JR l_E610

; Mover B14
;
; Witness: L1 33 (l5).
L5MoverB14:
  LD L,$06
  JR l_E610

; Mover B15
;
; Witness: L1 39 (l5).
L5MoverB15:
  LD L,$07
; This entry point is used by the routines at L5MoverB3, L5MoverB8, L5MoverB10,
; L5MoverB9, L5MoverB13 and L5MoverB14.
l_E610:
  CALL L5SlotBusy
  LD A,(Carriers)
  AND A
  JR NZ,l_E62D
  LD (Carriers+2),BC
  LD A,L
  LD (Carriers),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+1),A
  JP L5MoverB1
l_E62D:
  LD (Carriers+6),BC
  LD A,L
  LD (Carriers+4),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+5),A
  JP L5MoverB1

; Three bytes a slot (by DrawTag): the direction L5SlotDir returns for Mover A9
L5SlotDirs:
  DEFB $40,$00,$00
  DEFB $00,$00,$00
  DEFB $4A,$0C,$00
  DEFB $00,$00,$42
  DEFB $00,$00,$00
  DEFB $00,$04,$00
  DEFB $00,$00,$00
  DEFB $42,$00,$00
  DEFB $00,$00,$0A
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
  DEFB $01,$02,$00
  DEFB $03,$05,$07
  DEFB $00,$04,$06
  DEFB $08

; A = the first byte of the slot's L5SlotDirs record (slot = DrawTag & $7F - 1)
;
; Witness: L1 3609 (l5).
L5SlotDir:
  PUSH DE
  LD A,(DrawTag)
  AND $7F
  DEC A
  LD E,A
  LD D,$00
  LD HL,L5SlotDirs
  ADD HL,DE
  ADD HL,DE
  ADD HL,DE
  LD A,(HL)
  POP DE
  RET

; Step the slot by A: 1 row - 1, 2 row + 1, 3 column - 1, 4 column + 1 ...
;
; Witness: L1 116 (l5).
L5StepDir:
  CP $01
  JR NZ,l_E6AF
  DEC (IY+$04)
  JR l_E6F4
l_E6AF:
  CP $02
  JR NZ,l_E6B8
  INC (IY+$04)
  JR l_E6F4
l_E6B8:
  CP $03
  JR NZ,l_E6C1
  DEC (IY+$03)
  JR l_E6F4
l_E6C1:
  CP $04
  JR NZ,l_E6CA
  INC (IY+$03)
  JR l_E6F4
l_E6CA:
  CP $05
  JR NZ,l_E6D6
  DEC (IY+$04)
  DEC (IY+$03)
  JR l_E6F4
l_E6D6:
  CP $06
  JR NZ,l_E6E2
  DEC (IY+$04)
  INC (IY+$03)
  JR l_E6F4
l_E6E2:
  CP $07
  JR NZ,l_E6EE
  INC (IY+$04)
  DEC (IY+$03)
  JR l_E6F4
l_E6EE:
  INC (IY+$04)
  INC (IY+$03)
l_E6F4:
  LD C,(IY+$03)
  LD B,(IY+$04)
  RET

; Return while the slot is free; else drop the return and go on at Mover B1
; (Mover B15 calls it)
;
; Witness: L1 101 (l5).
L5SlotBusy:
  LD A,(IY+$00)
  AND A
  JR NZ,l_E702
  RET
l_E702:
  POP HL
  JP L5MoverB1
; This entry point is used by the routines at L5MoverA3, L5MoverA4, L5MoverA5
; and L5MoverA13.
l_E706:
  LD A,(FrameCounter)
  AND $01
  JP Z,l_E714
  LD (IY+$03),C
  LD (IY+$04),B
l_E714:
  LD A,(DE)
  PUSH DE
  PUSH AF
  EX AF,AF'
  CALL LevelObject
  POP AF
  AND $03
  JR NZ,l_E725
  CALL DrawSprite
  JR l_E73A
l_E725:
  CP $01
  JR NZ,l_E72E
  CALL DrawSpriteMirrored
  JR l_E73A
l_E72E:
  CP $02
  JR NZ,l_E737
  CALL DrawSpriteFlipped
  JR l_E73A
l_E737:
  CALL DrawSpriteBoth
l_E73A:
  POP DE
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveScript
  JP MoveDone
; This entry point is used by the routines at L5MoverA11, L5MoverA12 and
; L5MoverA13.
l_E746:
  LD (IY+$03),C
  LD (IY+$04),B
  LD A,(DE)
  PUSH DE
  PUSH AF
  EX AF,AF'
  CALL LevelObject
  POP AF
  AND $03
  JR NZ,l_E75D
  CALL DrawSprite
  JR l_E772
l_E75D:
  CP $01
  JR NZ,l_E766
  CALL DrawSpriteMirrored
  JR l_E772
l_E766:
  CP $02
  JR NZ,l_E76F
  CALL DrawSpriteFlipped
  JR l_E772
l_E76F:
  CALL DrawSpriteBoth
l_E772:
  POP DE
  JP MoveScript
