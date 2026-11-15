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
  DEFB $08,$01,$63,$04,$02,$08,$17,$0A
  DEFB $1F,$06,$08,$17,$0A,$1F,$09,$08
  DEFB $18,$10,$1E,$08,$09,$0F,$0A,$1F
  DEFB $04,$09,$0F,$0A,$1F,$07,$09,$0F
  DEFB $0A,$1F,$09,$0A,$00,$0F,$1E,$09
  DEFB $0A,$18,$1F,$1E,$07,$0B,$10,$04
  DEFB $1E,$0E,$0B,$18,$04,$1E,$06,$0C
  DEFB $10,$0F,$1E,$01,$0D,$04,$05,$1F
  DEFB $0F,$0D,$08,$02,$1E,$05,$0D,$0F
  DEFB $0A,$1F,$04,$0E,$03,$02,$1E,$08
  DEFB $0F,$07,$02,$1E,$08,$0F,$08,$05
  DEFB $1E,$0F,$0F,$08,$0C,$0C,$FE,$0F
  DEFB $19,$02,$1E,$06,$10,$14,$02,$1E
  DEFB $0A,$11,$10,$20,$1E,$05,$12,$00
  DEFB $0E,$FE,$01,$12,$12,$02,$1E,$04
  DEFB $12,$18,$11,$1A,$FE,$13,$01,$17
  DEFB $1E,$0F,$13,$04,$02,$1E,$0A,$13
  DEFB $08,$0F,$1E,$09,$13,$0D,$02,$1E
  DEFB $05,$13,$10,$05,$1E,$0F,$14,$18
  DEFB $21,$1E,$02,$16,$08,$0C,$05,$FE
  DEFB $17,$01,$1A,$0C,$FE,$17,$01,$1B
  DEFB $0F,$FE,$18,$00,$04,$1E,$11,$19
  DEFB $0F,$2D,$14,$FE,$19,$12,$2D,$14
  DEFB $FE,$19,$15,$2D,$14,$FE,$19,$18
  DEFB $2D,$14,$FE,$19,$1B,$2D,$14,$FE
  DEFB $19,$1E,$2D,$14,$FE,$1A,$01,$2D
  DEFB $14,$FE,$1A,$04,$2D,$14,$FE,$1A
  DEFB $07,$2D,$14,$FE,$1A,$0A,$2D,$14
  DEFB $FE,$1B,$10,$0F,$1E,$00,$1B,$10
  DEFB $0D,$10,$14,$1B,$18,$0C,$11,$FE
  DEFB $1B,$18,$0E,$FE,$02,$1C,$00,$0F
  DEFB $1E,$07,$1C,$0C,$34,$04,$00,$1C
  DEFB $18,$0E,$FE,$08,$1E,$00,$0F,$1E
  DEFB $06,$1E,$00,$04,$FF,$08,$1E,$10
  DEFB $04,$1E,$10,$1F,$00,$0F,$1E,$07
  DEFB $20,$00,$0F,$1E,$08,$20,$08,$1C
  DEFB $0B,$FE,$20,$10,$1C,$0A,$FE,$20
  DEFB $18,$1C,$09,$FE,$21,$00,$1C,$08
  DEFB $FE,$21,$10,$22,$1E,$06,$22,$08
  DEFB $0F,$1E,$02,$22,$10,$34,$1A,$00
  DEFB $22,$17,$23,$1E,$0B,$23,$00,$1D
  DEFB $0A,$FE,$23,$08,$0E,$FE,$01,$23
  DEFB $08,$17,$1E,$0F,$23,$19,$17,$1E
  DEFB $0F,$24,$04,$05,$1E,$0F,$24,$08
  DEFB $19,$FE,$0F,$24,$18,$18,$FE,$0F
  DEFB $25,$00,$12,$18,$FE,$26,$00,$1D
  DEFB $01,$FE,$27,$00,$1D,$04,$FE,$28
  DEFB $00,$13,$FE,$0B,$2A,$08,$0C,$0E
  DEFB $FE,$2A,$10,$0C,$09,$FE,$2B,$00
  DEFB $04,$1E,$02,$2B,$14,$24,$1E,$02
  DEFB $2C,$08,$0D,$10,$14,$2D,$00,$0D
  DEFB $19,$14,$2D,$00,$0F,$1E,$05,$2D
  DEFB $08,$0F,$1E,$03,$2D,$08,$0F,$1E
  DEFB $08,$2D,$10,$35,$14,$13,$2E,$00
  DEFB $1A,$09,$FE,$2E,$10,$1B,$0D,$FE
  DEFB $2E,$10,$25,$1E,$04,$2F,$00,$04
  DEFB $FF,$0B,$2F,$08,$04,$08,$FF,$2F
  DEFB $10,$04,$14,$FF,$31,$10,$13,$FE
  DEFB $0B,$32,$00,$11,$18,$FE,$32,$0F
  DEFB $01,$1F,$02,$32,$17,$01,$1F,$02
  DEFB $32,$1F,$01,$1F,$02,$33,$00,$0F
  DEFB $1E,$09,$33,$04,$0F,$1E,$06,$33
  DEFB $07,$01,$1F,$02,$33,$08,$0F,$1E
  DEFB $0F,$33,$0C,$0F,$1E,$0C,$33,$0F
  DEFB $01,$1F,$02,$33,$10,$0F,$1E,$03
  DEFB $33,$17,$01,$1F,$02,$33,$1F,$01
  DEFB $1F,$02,$34,$07,$01,$1F,$02,$34
  DEFB $0F,$01,$1F,$02,$34,$17,$01,$1F
  DEFB $02,$34,$1F,$01,$1F,$02,$35,$07
  DEFB $01,$1F,$02,$35,$0F,$01,$1F,$02
  DEFB $35,$17,$01,$1F,$02,$35,$1F,$01
  DEFB $1F,$02,$36,$07,$01,$1F,$02,$36
  DEFB $0F,$01,$1F,$02,$36,$17,$01,$1F
  DEFB $02,$36,$1F,$0A,$1F,$02,$36,$1F
  DEFB $0A,$1F,$05,$36,$1F,$0A,$1F,$08
  DEFB $36,$1F,$01,$1F,$0F,$37,$07,$0A
  DEFB $1F,$02,$37,$07,$0A,$1F,$05,$37
  DEFB $07,$0A,$1F,$08,$37,$07,$01,$1F
  DEFB $0F,$37,$09,$26,$1E,$0C,$37,$0F
  DEFB $0A,$1F,$02,$37,$0F,$0A,$1F,$05
  DEFB $37,$0F,$0A,$1F,$08,$37,$0F,$01
  DEFB $1F,$0F,$37,$17,$0A,$1F,$02,$37
  DEFB $17,$0A,$1F,$05,$37,$17,$0A,$1F
  DEFB $08,$37,$17,$01,$1F,$0F,$37,$1F
  DEFB $01,$1F,$02,$38,$07,$01,$1F,$04
  DEFB $38,$0F,$01,$1F,$04,$38,$17,$01
  DEFB $1F,$04,$38,$18,$04,$1E,$0F,$38
  DEFB $18,$04,$1E,$0D,$38,$18,$04,$1E
  DEFB $09,$38,$1F,$01,$1F,$04,$39,$00
  DEFB $34,$10,$00,$39,$07,$01,$1F,$04
  DEFB $39,$0F,$01,$1F,$04,$39,$10,$27
  DEFB $1E,$0C,$39,$17,$01,$1F,$04,$39
  DEFB $1F,$01,$1F,$04,$3A,$07,$01,$1F
  DEFB $04,$3A,$0F,$01,$1F,$04,$3A,$10
  DEFB $28,$1E,$0E,$3A,$17,$0A,$1F,$04
  DEFB $3A,$17,$01,$1F,$0B,$3A,$1F,$0A
  DEFB $1F,$04,$3A,$1F,$01,$1F,$0B,$3B
  DEFB $00,$04,$1D,$FF,$3B,$07,$0A,$1F
  DEFB $04,$3B,$07,$01,$1F,$0B,$3B,$08
  DEFB $04,$1E,$07,$3B,$0F,$0A,$1F,$04
  DEFB $3B,$0F,$01,$1F,$0B,$3B,$17,$01
  DEFB $1F,$04,$3B,$1F,$01,$1F,$04,$3C
  DEFB $07,$01,$1F,$04,$3C,$0F,$01,$1F
  DEFB $04,$3C,$17,$01,$1F,$04,$3C,$1F
  DEFB $01,$1F,$04,$3D,$07,$01,$1F,$04
  DEFB $3D,$08,$04,$14,$FF,$3D,$08,$35
  DEFB $1A,$13,$3D,$0F,$01,$1F,$04,$3D
  DEFB $17,$01,$1F,$04,$3D,$18,$35,$0C
  DEFB $13,$3D,$1F,$01,$1F,$04,$3E,$00
  DEFB $29,$20,$FD,$3E,$00,$33,$00,$04
  DEFB $3E,$00,$33,$00,$07,$3E,$00,$33
  DEFB $00,$0B,$3E,$00,$33,$00,$0F,$3E
  DEFB $07,$01,$1F,$04,$3E,$0F,$01,$1F
  DEFB $00,$3E,$10,$34,$0F,$00,$3E,$17
  DEFB $01,$1F,$04,$3E,$18,$33,$00,$09
  DEFB $3E,$1F,$01,$1F,$04,$3F,$00,$04
  DEFB $08,$FF,$3F,$07,$01,$1F,$04,$3F
  DEFB $0F,$01,$1F,$04,$3F,$17,$01,$1F
  DEFB $00,$3F,$1F,$01,$1F,$00,$40,$00
  DEFB $34,$17,$00,$40,$07,$01,$1F,$00
  DEFB $40,$0F,$01,$1F,$00,$40,$17,$01
  DEFB $1F,$00,$40,$1F,$01,$1F,$00,$45
  DEFB $18,$15,$1E,$05,$46,$18,$0F,$1E
  DEFB $05,$47,$18,$16,$FE,$06,$4A,$00
  DEFB $63,$01,$00,$4A,$00,$63,$04,$04
  DEFB $4B,$00,$63,$03,$01,$4B,$00,$2C
  DEFB $F1,$05,$4B,$00,$63,$03,$02,$4B
  DEFB $00,$2B,$F5,$02,$4B,$00,$63,$03
  DEFB $03,$4B,$00,$2A,$EF,$02,$4B,$00
  DEFB $63,$03,$04,$4B,$00,$30,$F5,$08
  DEFB $4B,$00,$63,$03,$07,$4B,$00,$31
  DEFB $F6,$04,$4B,$00,$63,$03,$0A,$4B
  DEFB $00,$32,$F8,$07,$67,$10,$63,$05
  DEFB $00,$FF,$FF,$FF,$FF,$FF,$23,$3F
  DEFB $1C,$F6,$EF,$00,$00,$00,$41,$12
  DEFB $FC,$EF,$FC,$EF,$FC,$EF,$FC,$EF
  DEFB $00,$00,$1C,$41,$23,$90,$F1,$84
  DEFB $F1,$92,$F1,$8A,$F1,$FF,$FF,$1E
  DEFB $03,$15,$94,$F1,$D4,$F1,$B4,$F1
  DEFB $BC,$F1,$BC,$F1,$B4,$F1,$D4,$F1
  DEFB $94,$F1,$D4,$F1,$B4,$F1,$BC,$F1
  DEFB $BC,$F1,$B4,$F1,$94,$F1,$DC,$F1
  DEFB $B8,$F1,$C8,$F1,$C8,$F1,$94,$F1
  DEFB $94,$F1,$00,$00,$0F,$01,$3C,$E4
  DEFB $F1,$E4,$F1,$F6,$F1,$EC,$F1,$EC
  DEFB $F1,$00,$00,$0F,$01,$3C,$E4,$F1
  DEFB $E4,$F1,$FE,$F1,$EC,$F1,$EC,$F1
  DEFB $00,$00,$0F,$01,$3C,$E4,$F1,$E4
  DEFB $F1,$0A,$F2,$EC,$F1,$EC,$F1,$00
  DEFB $00,$0F,$01,$3C,$E4,$F1,$E4,$F1
  DEFB $12,$F2,$EC,$F1,$EC,$F1,$00,$00
  DEFB $24,$3F,$1C,$F8,$EF,$00,$00,$25
  DEFB $3F,$1C,$FA,$EF,$00,$00,$07,$01
  DEFB $24,$1C,$F0,$1C,$F0,$1C,$F0,$00
  DEFB $00,$08,$01,$24,$0C,$F0,$0C,$F0
  DEFB $0C,$F0,$00,$00,$06,$01,$24,$3C
  DEFB $F0,$3C,$F0,$3C,$F0,$3C,$F0,$44
  DEFB $F0,$00,$00,$06,$01,$24,$2C,$F0
  DEFB $2C,$F0,$2C,$F0,$2C,$F0,$34,$F0
  DEFB $00,$00,$06,$01,$24,$4C,$F0,$34
  DEFB $F0,$78,$F0,$28,$F0,$88,$F0,$28
  DEFB $F0,$78,$F0,$28,$F0,$88,$F0,$28
  DEFB $F0,$78,$F0,$34,$F0,$4C,$F0,$54
  DEFB $F0,$00,$00,$06,$01,$24,$1C,$F0
  DEFB $22,$F0,$72,$F0,$32,$F0,$52,$F0
  DEFB $14,$F0,$62,$F0,$42,$F0,$7C,$F0
  DEFB $7C,$F0,$00,$00,$06,$01,$24,$1C
  DEFB $F0,$2A,$F0,$70,$F0,$2C,$F0,$38
  DEFB $F0,$4C,$F0,$00,$00,$06,$01,$24
  DEFB $84,$F0,$44,$F0,$64,$F0,$44,$F0
  DEFB $84,$F0,$40,$F0,$64,$F0,$10,$F0
  DEFB $54,$F0,$30,$F0,$74,$F0,$20,$F0
  DEFB $7C,$F0,$00,$00,$06,$01,$24,$0C
  DEFB $F0,$0C,$F0,$64,$F0,$44,$F0,$84
  DEFB $F0,$24,$F0,$76,$F0,$36,$F0,$56
  DEFB $F0,$14,$F0,$5C,$F0,$5C,$F0,$00
  DEFB $00,$06,$01,$24,$52,$F0,$30,$F0
  DEFB $6C,$F0,$6C,$F0,$2C,$F0,$00,$00
  DEFB $06,$01,$24,$3C,$F0,$3C,$F0,$48
  DEFB $F0,$84,$F0,$24,$F0,$6C,$F0,$00
  DEFB $00,$11,$41,$12,$DE,$F0,$DE,$F0
  DEFB $DE,$F0,$DE,$F0,$00,$00,$11,$41
  DEFB $12,$EE,$F0,$EE,$F0,$EE,$F0,$EE
  DEFB $F0,$00,$00,$1E,$03,$15,$A4,$F1
  DEFB $DC,$F1,$B8,$F1,$C8,$F1,$C8,$F1
  DEFB $B8,$F1,$DC,$F1,$A4,$F1,$DC,$F1
  DEFB $B8,$F1,$C8,$F1,$C8,$F1,$B8,$F1
  DEFB $A4,$F1,$D4,$F1,$B4,$F1,$BC,$F1
  DEFB $BC,$F1,$A4,$F1,$A4,$F1,$00,$00
  DEFB $11,$41,$12,$FE,$F0,$FE,$F0,$FE
  DEFB $F0,$04,$F1,$08,$F1,$DE,$F0,$DE
  DEFB $F0,$00,$00,$11,$41,$12,$12,$F1
  DEFB $12,$F1,$14,$F1,$1A,$F1,$F6,$F0
  DEFB $F6,$F0,$1E,$F1,$12,$F1,$12,$F1
  DEFB $12,$F1,$00,$00,$11,$41,$12,$12
  DEFB $F1,$12,$F1,$14,$F1,$1A,$F1,$FA
  DEFB $F0,$1E,$F1,$14,$F1,$14,$F1,$1A
  DEFB $F1,$EE,$F0,$EE,$F0,$00,$00,$11
  DEFB $41,$12,$12,$F1,$12,$F1,$14,$F1
  DEFB $14,$F1,$14,$F1,$1A,$F1,$EE,$F0
  DEFB $EE,$F0,$EE,$F0,$EE,$F0,$00,$00
  DEFB $00,$3F,$1C,$8C,$F0,$8C,$F0,$8C
  DEFB $F0,$00,$00,$B2,$01,$22,$24,$F1
  DEFB $50,$F1,$54,$F1,$58,$F1,$60,$F1
  DEFB $00,$00,$E2,$01,$22,$24,$F1,$2E
  DEFB $F1,$36,$F1,$32,$F1,$24,$F1,$2E
  DEFB $F1,$36,$F1,$32,$F1,$00,$00,$D2
  DEFB $01,$22,$20,$20,$72,$01,$22,$20
  DEFB $20,$F2,$01,$22,$26,$F1,$50,$F1
  DEFB $50,$F1,$40,$F1,$40,$F1,$40,$F1
  DEFB $40,$F1,$00,$00,$C2,$01,$22,$20
  DEFB $20,$E2,$01,$22,$24,$F1,$50,$F1
  DEFB $54,$F1,$58,$F1,$60,$F1,$00,$00
  DEFB $D2,$01,$22,$64,$F1,$64,$F1,$64
  DEFB $F1,$64,$F1,$64,$F1,$64,$F1,$64
  DEFB $F1,$64,$F1,$00,$00,$D2,$01,$22
  DEFB $26,$26,$B2,$01,$22,$26,$26,$82
  DEFB $01,$22,$26,$F1,$50,$F1,$40,$F1
  DEFB $54,$F1,$58,$F1,$00,$00,$3A,$3F
  DEFB $4C,$4E,$F2,$4E,$F2,$4E,$F2,$52
  DEFB $F2,$42,$F2,$44,$F2,$36,$F2,$22
  DEFB $F2,$4E,$F2,$58,$F2,$3E,$F2,$48
  DEFB $F2,$2E,$F2,$34,$F2,$A2,$F2,$4E
  DEFB $F2,$5C,$F2,$3E,$F2,$4C,$F2,$1E
  DEFB $F2,$26,$F2,$AA,$F2,$2E,$F2,$36
  DEFB $F2,$1E,$F2,$26,$F2,$4E,$F2,$58
  DEFB $F2,$38,$F2,$3A,$F2,$3E,$F2,$48
  DEFB $F2,$74,$F2,$52,$F2,$84,$F2,$74
  DEFB $F2,$3E,$F2,$48,$F2,$2E,$F2,$36
  DEFB $F2,$4E,$F2,$52,$F2,$1E,$F2,$24
  DEFB $F2,$3E,$F2,$42,$F2,$9E,$F2,$9E
  DEFB $F2,$9E,$F2,$A2,$F2,$92,$F2,$42
  DEFB $F2,$72,$F2,$94,$F2,$24,$F2,$3E
  DEFB $F2,$48,$F2,$38,$F2,$96,$F2,$66
  DEFB $F2,$28,$F2,$9E,$F2,$4E,$F2,$52
  DEFB $F2,$2E,$F2,$34,$F2,$A2,$F2,$5E
  DEFB $F2,$64,$F2,$4C,$F2,$9E,$F2,$54
  DEFB $F2,$A0,$F2,$4E,$F2,$4E,$F2,$4E
  DEFB $F2,$00,$00,$4A,$3F,$4C,$4E,$F2
  DEFB $4E,$F2,$4E,$F2,$52,$F2,$42,$F2
  DEFB $44,$F2,$36,$F2,$22,$F2,$4E,$F2
  DEFB $58,$F2,$9E,$F2,$9E,$F2,$9E,$F2
  DEFB $2E,$F2,$36,$F2,$A8,$F2,$3E,$F2
  DEFB $4C,$F2,$1E,$F2,$26,$F2,$AA,$F2
  DEFB $2E,$F2,$36,$F2,$1E,$F2,$26,$F2
  DEFB $4E,$F2,$5C,$F2,$AA,$F2,$38,$F2
  DEFB $3A,$F2,$3E,$F2,$48,$F2,$74,$F2
  DEFB $52,$F2,$84,$F2,$74,$F2,$9E,$F2
  DEFB $A6,$F2,$3E,$F2,$3E,$F2,$4A,$F2
  DEFB $2E,$F2,$36,$F2,$4E,$F2,$4E,$F2
  DEFB $5A,$F2,$1E,$F2,$26,$F2,$3E,$F2
  DEFB $48,$F2,$9E,$F2,$84,$F1,$92,$F2
  DEFB $42,$F2,$72,$F2,$94,$F2,$24,$F2
  DEFB $3E,$F2,$48,$F2,$38,$F2,$96,$F2
  DEFB $66,$F2,$96,$F2,$50,$F2,$3E,$F2
  DEFB $42,$F2,$20,$F2,$4E,$F2,$52,$F2
  DEFB $9E,$F2,$3E,$F2,$48,$F2,$AC,$F2
  DEFB $54,$F2,$A0,$F2,$4E,$F2,$4E,$F2
  DEFB $4E,$F2,$00,$00,$5A,$3F,$4C,$4E
  DEFB $F2,$4E,$F2,$4E,$F2,$52,$F2,$42
  DEFB $F2,$44,$F2,$36,$F2,$22,$F2,$4E
  DEFB $F2,$58,$F2,$32,$F2,$A6,$F2,$5E
  DEFB $F2,$6A,$F2,$46,$F2,$9E,$F2,$AA
  DEFB $F2,$4E,$F2,$4E,$F2,$5A,$F2,$2E
  DEFB $F2,$3A,$F2,$1E,$F2,$2A,$F2,$AA
  DEFB $F2,$2E,$F2,$3A,$F2,$46,$F2,$9E
  DEFB $F2,$2A,$F2,$AA,$F2,$3A,$F2,$3E
  DEFB $F2,$48,$F2,$74,$F2,$52,$F2,$84
  DEFB $F2,$74,$F2,$34,$F2,$9E,$F2,$56
  DEFB $F2,$1E,$F2,$2A,$F2,$3E,$F2,$3E
  DEFB $F2,$4A,$F2,$2E,$F2,$3A,$F2,$4E
  DEFB $F2,$4E,$F2,$5A,$F2,$3E,$F2,$40
  DEFB $F2,$22,$F2,$92,$F2,$42,$F2,$72
  DEFB $F2,$94,$F2,$A4,$F2,$3E,$F2,$48
  DEFB $F2,$28,$F2,$96,$F2,$66,$F2,$96
  DEFB $F2,$50,$F2,$3E,$F2,$42,$F2,$9E
  DEFB $F2,$9E,$F2,$9E,$F2,$9E,$F2,$7A
  DEFB $F2,$24,$F2,$AA,$F2,$54,$F2,$30
  DEFB $F2,$4E,$F2,$4E,$F2,$4E,$F2,$00
  DEFB $00,$00,$41,$23,$BC,$F0,$D2,$F0
  DEFB $D2,$F0,$D2,$F0,$00,$00,$3B,$20
  DEFB $2C,$2A,$2A,$00,$00,$4B,$20,$2C
  DEFB $2B,$2B,$00,$00,$5B,$20,$2C,$2C
  DEFB $2C,$00,$00,$0D,$01,$22,$AC,$F0
  DEFB $FF,$FF,$0D,$01,$22,$9C,$F0,$FF
  DEFB $FF,$0D,$01,$22,$A4,$F0,$FF,$FF
  DEFB $0D,$01,$22,$B4,$F0,$FF,$FF

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
; Witness: L1 0 (none).
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
