; --------------------------------------------------------------------------------------------------------------------
; level1data.asm: Level 1
;
; The level's body: the header the game reads at $C4AE, the sprites, the object table, the metatiles, the map, the
; wave script, the enemy kinds and their movement scripts, the two mover tables and the movers.
; --------------------------------------------------------------------------------------------------------------------

; The level header: restart point, checkpoints and the pointers the game reads
;
; Restart column $00, restart wave $0000; checkpoint columns $06, $25, $4B with
; wave entries $E788, $E8AF, $EA44; objects $D7F9, map $E571, kinds $EFFB,
; movers $F365 and $F385.
L1Header:
  DEFB $00
L1RestartWave:
  DEFB $00,$00            ; the wave entry a life restarts at (the game keeps
                          ; its live copy here)
L1Checks:
  DEFB $06,$25,$4B        ; three checkpoint columns (CheckRestart)
L1WaveStarts:
  DEFB $88,$E7,$AF,$E8,$44,$EA ; the wave entries of the start and the
                               ; checkpoints
L1Pointers:
  DEFB $F9,$D7,$71,$E5,$FB,$EF,$65,$F3 ; objects, map, kinds, movers 1, movers
  DEFB $85,$F3                         ; 2

; zeros up to the sprites
L1Spare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00

; The level's sprites: cells of 9 bytes (attribute, 8 pixel bytes) the object
; table points at
L1Sprites:
  INCBIN "res/levels/level1/sprites.bin",$0000,4889

; The level's object table: width, height, the cells' address (LevelObject)
L1Objects:
  INCBIN "res/levels/level1/objects.bin",$0000,280

; The metatiles, 144 bytes each (4 x 4 cells of 9 bytes), numbered down from
; the map: metatile n at $E571 - 144 x (n + 1) (MetatileAddress); 22 of them
L1Metatiles:
  INCBIN "res/levels/level1/metatiles.bin",$0000,3168

; The map: 5 bytes a block column (107 columns), each byte a metatile (bits
; 0-5) and its drawer (bits 6-7)
L1Map:
  INCBIN "res/levels/level1/map.bin",$0000,535

; The wave script: entries (scroll position, kind, script) RunWaves starts;
; then the enemies' movement scripts
L1Waves:
  DEFB $10,$00,$63,$04,$00,$10,$00,$01
  DEFB $1F,$04,$10,$05,$01,$1F,$01,$10
  DEFB $0A,$01,$1F,$07,$10,$0F,$01,$1F
  DEFB $03,$11,$10,$01,$1F,$0A,$11,$15
  DEFB $01,$1F,$07,$11,$1A,$01,$1F,$0D
  DEFB $11,$1F,$01,$1F,$09,$12,$00,$08
  DEFB $1F,$0F,$12,$1A,$05,$1F,$0E,$12
  DEFB $1D,$05,$1F,$0E,$13,$00,$05,$1F
  DEFB $0E,$13,$03,$05,$1F,$0E,$13,$06
  DEFB $05,$1F,$0E,$14,$00,$02,$1F,$0C
  DEFB $14,$03,$02,$1F,$0C,$14,$06,$02
  DEFB $1F,$0C,$14,$09,$02,$1F,$0C,$14
  DEFB $0C,$02,$1F,$0C,$15,$00,$01,$1F
  DEFB $0A,$15,$06,$01,$1F,$07,$15,$0C
  DEFB $01,$1F,$09,$17,$09,$01,$1F,$09
  DEFB $17,$12,$01,$1F,$03,$17,$1B,$01
  DEFB $1F,$01,$18,$04,$01,$1F,$08,$18
  DEFB $0D,$01,$1F,$03,$18,$16,$01,$1F
  DEFB $0A,$18,$1F,$01,$1F,$01,$19,$08
  DEFB $01,$1F,$03,$19,$11,$01,$1F,$09
  DEFB $19,$1A,$01,$1F,$02,$1A,$00,$01
  DEFB $1F,$05,$1A,$09,$01,$1F,$07,$1A
  DEFB $12,$01,$1F,$09,$1A,$1B,$01,$1F
  DEFB $01,$1B,$04,$01,$1F,$03,$1B,$08
  DEFB $18,$21,$05,$1B,$0D,$01,$1F,$09
  DEFB $1B,$16,$01,$1F,$04,$1B,$1F,$01
  DEFB $1F,$0A,$1C,$08,$01,$1F,$06,$1D
  DEFB $00,$0C,$18,$00,$1D,$00,$01,$1F
  DEFB $06,$1D,$10,$01,$1F,$04,$1D,$1C
  DEFB $08,$1F,$0F,$1E,$0A,$21,$1E,$0F
  DEFB $1E,$18,$08,$1F,$0F,$20,$00,$63
  DEFB $04,$04,$20,$00,$08,$1F,$0F,$21
  DEFB $10,$08,$1F,$0F,$21,$10,$07,$FE
  DEFB $0F,$23,$10,$0F,$1C,$07,$24,$00
  DEFB $02,$1F,$05,$24,$03,$02,$1F,$05
  DEFB $24,$06,$02,$1F,$05,$24,$09,$02
  DEFB $1F,$05,$24,$0C,$02,$1F,$05,$25
  DEFB $0E,$10,$19,$FD,$26,$0E,$2D,$FC
  DEFB $0F,$27,$10,$02,$1F,$0B,$2A,$06
  DEFB $0E,$1C,$FF,$2A,$12,$0E,$1F,$04
  DEFB $2A,$18,$0E,$1F,$12,$2A,$1E,$0E
  DEFB $1C,$12,$2C,$06,$0E,$16,$FF,$2C
  DEFB $0C,$0E,$1F,$FF,$2C,$18,$0E,$1F
  DEFB $12,$2C,$1E,$0E,$16,$12,$2E,$06
  DEFB $0E,$10,$FF,$2E,$0C,$0E,$1F,$FF
  DEFB $2E,$12,$0E,$1F,$08,$2E,$18,$0E
  DEFB $1F,$12,$30,$06,$0E,$0A,$FF,$30
  DEFB $0C,$0E,$1F,$FF,$30,$10,$0E,$1F
  DEFB $04,$30,$10,$0E,$1F,$0C,$30,$10
  DEFB $0E,$1F,$10,$30,$12,$0E,$1F,$0A
  DEFB $32,$0F,$13,$1F,$04,$32,$0F,$16
  DEFB $1F,$0E,$33,$0F,$13,$1F,$04,$33
  DEFB $0F,$16,$1F,$0E,$33,$10,$0F,$1C
  DEFB $07,$34,$0F,$13,$1F,$06,$34,$0F
  DEFB $16,$1F,$0C,$35,$0F,$13,$1F,$06
  DEFB $35,$0F,$16,$1F,$0C,$38,$10,$19
  DEFB $1F,$09,$39,$01,$21,$1F,$0F,$39
  DEFB $18,$1A,$1F,$09,$3C,$08,$03,$18
  DEFB $FE,$3C,$0C,$03,$18,$FE,$3C,$0F
  DEFB $63,$03,$19,$3C,$0F,$13,$1F,$02
  DEFB $3C,$10,$03,$18,$FE,$3C,$14,$03
  DEFB $18,$FE,$3C,$18,$03,$18,$FE,$3D
  DEFB $08,$63,$03,$08,$3D,$08,$2C,$24
  DEFB $10,$3D,$0C,$63,$03,$09,$3D,$0C
  DEFB $0A,$24,$10,$3D,$0F,$63,$03,$1A
  DEFB $3D,$0F,$13,$1F,$02,$3D,$10,$63
  DEFB $03,$0A,$3D,$10,$0A,$24,$10,$3D
  DEFB $14,$63,$03,$0B,$3D,$14,$0A,$24
  DEFB $10,$3D,$18,$63,$03,$0C,$3D,$18
  DEFB $2C,$24,$10,$3D,$1C,$63,$03,$0D
  DEFB $3D,$1C,$0A,$24,$10,$3E,$00,$63
  DEFB $03,$0E,$3E,$00,$0A,$24,$10,$3E
  DEFB $04,$63,$03,$0F,$3E,$04,$0A,$24
  DEFB $10,$3E,$08,$63,$03,$10,$3E,$08
  DEFB $2C,$24,$10,$3E,$0C,$63,$03,$11
  DEFB $3E,$0C,$0A,$24,$10,$3E,$10,$63
  DEFB $03,$12,$3E,$10,$0A,$24,$10,$3E
  DEFB $14,$63,$03,$13,$3E,$14,$0A,$24
  DEFB $10,$3E,$18,$63,$03,$14,$3E,$18
  DEFB $0B,$24,$10,$3E,$18,$63,$03,$15
  DEFB $3E,$18,$0A,$24,$10,$3E,$1C,$63
  DEFB $03,$16,$3E,$1C,$2C,$24,$10,$3F
  DEFB $00,$63,$03,$17,$3F,$00,$0A,$24
  DEFB $10,$3F,$04,$63,$03,$18,$3F,$04
  DEFB $0A,$24,$10,$48,$0F,$13,$1F,$04
  DEFB $49,$0F,$13,$1F,$04,$49,$10,$11
  DEFB $1C,$05,$4A,$0F,$13,$1F,$02,$4B
  DEFB $0F,$13,$1F,$02,$4C,$00,$01,$1F
  DEFB $07,$4C,$06,$01,$1F,$05,$4C,$0C
  DEFB $01,$1F,$08,$4C,$0F,$13,$1F,$02
  DEFB $4D,$01,$21,$1F,$0F,$4D,$0F,$13
  DEFB $1F,$02,$4E,$0C,$01,$1F,$0A,$4E
  DEFB $0F,$13,$1F,$02,$4E,$10,$1B,$1F
  DEFB $0F,$4E,$12,$01,$1F,$07,$4E,$18
  DEFB $01,$1F,$09,$4F,$0F,$13,$1F,$02
  DEFB $52,$01,$1C,$1E,$09,$52,$01,$01
  DEFB $1F,$0B,$52,$04,$03,$17,$FE,$52
  DEFB $08,$03,$17,$FE,$52,$0C,$03,$17
  DEFB $FE,$52,$0F,$13,$1F,$06,$52,$0F
  DEFB $16,$1F,$0C,$52,$10,$03,$17,$FE
  DEFB $52,$14,$03,$17,$FE,$52,$18,$03
  DEFB $17,$FE,$52,$1C,$03,$17,$FE,$53
  DEFB $00,$03,$17,$FE,$53,$04,$03,$17
  DEFB $FE,$53,$08,$03,$17,$FE,$53,$0F
  DEFB $13,$1F,$06,$53,$0F,$63,$03,$18
  DEFB $53,$0F,$16,$1F,$0C,$53,$18,$12
  DEFB $1C,$05,$54,$10,$1F,$0E,$FB,$56
  DEFB $18,$1D,$1E,$08,$5A,$0F,$13,$1F
  DEFB $02,$5B,$0F,$13,$1F,$02,$5C,$0F
  DEFB $13,$1F,$02,$5D,$01,$20,$19,$05
  DEFB $5D,$0F,$13,$1F,$02,$5E,$0F,$13
  DEFB $1F,$04,$5E,$16,$1E,$1E,$0A,$5F
  DEFB $0F,$13,$1F,$04,$63,$00,$63,$03
  DEFB $18,$63,$00,$20,$19,$05,$64,$00
  DEFB $63,$03,$01,$64,$00,$2A,$29,$00
  DEFB $64,$00,$63,$03,$02,$64,$00,$2E
  DEFB $C8,$C8,$64,$00,$63,$03,$19,$64
  DEFB $00,$17,$2D,$0F,$64,$00,$63,$03
  DEFB $14,$64,$00,$2E,$28,$01,$64,$00
  DEFB $63,$03,$15,$64,$00,$06,$28,$0F
  DEFB $64,$00,$63,$03,$16,$64,$00,$2E
  DEFB $2C,$09,$64,$00,$63,$03,$17,$64
  DEFB $00,$06,$2E,$0C,$6A,$00,$2B,$1F
  DEFB $04,$6A,$00,$2B,$1F,$08,$6A,$00
  DEFB $2B,$1F,$0C,$6A,$18,$04,$1C,$04
  DEFB $6A,$18,$04,$1C,$08,$6A,$18,$04
  DEFB $1C,$0C,$6B,$01,$63,$01,$00,$6B
  DEFB $01,$63,$03,$02,$6B,$01,$14,$16
  DEFB $09,$6B,$07,$15,$15,$09,$6B,$09
  DEFB $15,$15,$09,$6B,$0B,$15,$15,$09
  DEFB $6B,$0D,$15,$15,$09,$6B,$0F,$15
  DEFB $15,$09,$6B,$11,$15,$15,$09,$6C
  DEFB $07,$09,$15,$09,$6C,$09,$09,$15
  DEFB $09,$6C,$0B,$09,$15,$09,$6C,$0D
  DEFB $09,$15,$09,$6C,$0F,$09,$15,$09
  DEFB $6C,$11,$09,$15,$09,$6D,$07,$15
  DEFB $15,$09,$6D,$09,$15,$15,$09,$6D
  DEFB $0B,$15,$15,$09,$6D,$0D,$15,$15
  DEFB $09,$6D,$0F,$15,$15,$09,$6D,$11
  DEFB $15,$15,$09,$6E,$07,$09,$15,$09
  DEFB $6E,$09,$09,$15,$09,$6E,$0B,$09
  DEFB $15,$09,$6E,$0D,$09,$15,$09,$6E
  DEFB $0F,$09,$15,$09,$6E,$11,$09,$15
  DEFB $09,$6F,$07,$15,$15,$09,$6F,$09
  DEFB $15,$15,$09,$6F,$0B,$15,$15,$09
  DEFB $6F,$0D,$15,$15,$09,$6F,$0F,$15
  DEFB $15,$09,$6F,$11,$15,$15,$09,$70
  DEFB $07,$09,$15,$09,$70,$09,$09,$15
  DEFB $09,$70,$0B,$09,$15,$09,$70,$0D
  DEFB $09,$15,$09,$70,$0F,$09,$15,$09
  DEFB $70,$11,$09,$15,$09,$71,$07,$15
  DEFB $15,$09,$71,$09,$15,$15,$09,$71
  DEFB $0B,$15,$15,$09,$71,$0D,$15,$15
  DEFB $09,$71,$0F,$15,$15,$09,$71,$11
  DEFB $15,$15,$09,$72,$07,$09,$15,$09
  DEFB $72,$09,$09,$15,$09,$72,$0B,$09
  DEFB $15,$09,$72,$0D,$09,$15,$09,$72
  DEFB $0F,$09,$15,$09,$72,$11,$09,$15
  DEFB $09,$73,$07,$15,$15,$09,$73,$09
  DEFB $15,$15,$09,$73,$0B,$15,$15,$09
  DEFB $73,$0D,$15,$15,$09,$73,$0F,$15
  DEFB $15,$09,$73,$11,$15,$15,$09,$74
  DEFB $00,$63,$01,$00,$7B,$00,$63,$05
  DEFB $00,$00,$41,$12,$57,$F0,$57,$F0
  DEFB $57,$F0,$57,$F0,$00,$00,$00,$41
  DEFB $22,$67,$F0,$67,$F0,$00,$00,$00
  DEFB $41,$22,$87,$F0,$87,$F0,$8F,$F0
  DEFB $9B,$F0,$9B,$F0,$9B,$F0,$9B,$F0
  DEFB $00,$00,$00,$3F,$1C,$63,$F3,$FF
  DEFB $FF,$00,$41,$22,$A7,$F0,$A7,$F0
  DEFB $B5,$F0,$B5,$F0,$BB,$F0,$BB,$F0
  DEFB $00,$00,$03,$20,$33,$F5,$F1,$FF
  DEFB $FF,$11,$41,$12,$C9,$F0,$C9,$F0
  DEFB $C9,$F0,$C9,$F0,$C9,$F0,$C9,$F0
  DEFB $03,$F1,$C9,$F0,$C9,$F0,$00,$00
  DEFB $11,$41,$12,$D1,$F0,$D1,$F0,$D1
  DEFB $F0,$D1,$F0,$00,$00,$07,$3F,$1C
  DEFB $19,$F2,$19,$F2,$19,$F2,$19,$F2
  DEFB $2D,$F2,$00,$00,$15,$3F,$2C,$27
  DEFB $F1,$27,$F1,$27,$F1,$27,$F1,$27
  DEFB $F1,$27,$F1,$00,$00,$14,$02,$2C
  DEFB $0A,$0A,$0A,$1C,$45,$CF,$F1,$CF
  DEFB $F1,$CF,$F1,$CF,$F1,$CF,$F1,$D5
  DEFB $F1,$FF,$FF,$0B,$3F,$1C,$D7,$F1
  DEFB $D7,$F1,$00,$00,$1C,$41,$23,$F1
  DEFB $F1,$E5,$F1,$F3,$F1,$EB,$F1,$FF
  DEFB $FF,$11,$41,$12,$E1,$F0,$ED,$F0
  DEFB $D9,$F0,$EF,$F0,$19,$F1,$ED,$F0
  DEFB $D1,$F0,$D1,$F0,$00,$00,$11,$41
  DEFB $12,$E1,$F0,$E1,$F0,$E1,$F0,$ED
  DEFB $F0,$D9,$F0,$ED,$F0,$11,$F1,$11
  DEFB $F1,$D9,$F0,$C9,$F0,$ED,$F0,$D1
  DEFB $F0,$11,$F1,$11,$F1,$11,$F1,$11
  DEFB $F1,$D9,$F0,$C9,$F0,$D1,$F0,$C9
  DEFB $F0,$D9,$F0,$11,$F1,$D9,$F0,$19
  DEFB $F1,$00,$00,$11,$41,$12,$E1,$F0
  DEFB $ED,$F0,$D9,$F0,$EF,$F0,$F1,$F0
  DEFB $FF,$F0,$ED,$F0,$D1,$F0,$D1,$F0
  DEFB $00,$00,$11,$41,$12,$E1,$F0,$ED
  DEFB $F0,$D9,$F0,$EF,$F0,$F1,$F0,$ED
  DEFB $F0,$D9,$F0,$EF,$F0,$F1,$F0,$ED
  DEFB $F0,$D1,$F0,$D1,$F0,$00,$00,$66
  DEFB $41,$31,$35,$F2,$FF,$FF,$11,$3E
  DEFB $1C,$F9,$F1,$FF,$FF,$07,$3F,$1C
  DEFB $19,$F2,$19,$F2,$19,$F2,$19,$F2
  DEFB $25,$F2,$00,$00,$66,$41,$31,$45
  DEFB $F2,$FF,$FF,$09,$3F,$1C,$55,$F2
  DEFB $FF,$FF,$92,$01,$22,$77,$F1,$83
  DEFB $F1,$8B,$F1,$87,$F1,$77,$F1,$AF
  DEFB $F1,$9F,$F1,$AF,$F1,$8B,$F1,$87
  DEFB $F1,$00,$00,$E2,$01,$22,$77,$F1
  DEFB $83,$F1,$8B,$F1,$87,$F1,$83,$F1
  DEFB $83,$F1,$87,$F1,$8B,$F1,$00,$00
  DEFB $A2,$01,$22,$77,$F1,$83,$F1,$8B
  DEFB $F1,$83,$F1,$8F,$F1,$97,$F1,$9B
  DEFB $F1,$AF,$F1,$9F,$F1,$9F,$F1,$00
  DEFB $00,$72,$01,$22,$83,$F1,$8B,$F1
  DEFB $87,$F1,$77,$F1,$AF,$F1,$A7,$F1
  DEFB $A7,$F1,$A7,$F1,$AF,$F1,$8B,$F1
  DEFB $83,$F1,$77,$F1,$AF,$F1,$9F,$F1
  DEFB $9F,$F1,$B3,$F1,$B7,$F1,$C3,$F1
  DEFB $B7,$F1,$C3,$F1,$B7,$F1,$00,$00
  DEFB $D2,$01,$22,$83,$F1,$83,$F1,$77
  DEFB $F1,$AF,$F1,$9F,$F1,$9F,$F1,$9F
  DEFB $F1,$B3,$F1,$B7,$F1,$C3,$F1,$C7
  DEFB $F1,$B3,$F1,$9F,$F1,$AF,$F1,$8B
  DEFB $F1,$87,$F1,$77,$F1,$00,$00,$F2
  DEFB $01,$22,$83,$F1,$77,$F1,$87,$F1
  DEFB $8F,$F1,$8F,$F1,$99,$F1,$9B,$F1
  DEFB $AF,$F1,$9F,$F1,$AF,$F1,$8B,$F1
  DEFB $87,$F1,$00,$00,$B2,$01,$22,$8B
  DEFB $F1,$87,$F1,$77,$F1,$83,$F1,$8F
  DEFB $F1,$87,$F1,$97,$F1,$97,$F1,$9D
  DEFB $F1,$AF,$F1,$A7,$F1,$AF,$F1,$8B
  DEFB $F1,$8B,$F1,$87,$F1,$00,$00,$11
  DEFB $01,$12,$E1,$F0,$E1,$F0,$E1,$F0
  DEFB $ED,$F0,$D9,$F0,$EF,$F0,$F1,$F0
  DEFB $ED,$F0,$D1,$F0,$00,$00,$1D,$28
  DEFB $48,$57,$F2,$57,$F2,$5F,$F2,$67
  DEFB $F2,$67,$F2,$67,$F2,$5F,$F2,$8F
  DEFB $F2,$7F,$F2,$7F,$F2,$7F,$F2,$7F
  DEFB $F2,$6F,$F2,$6F,$F2,$6F,$F2,$00
  DEFB $00,$1E,$05,$15,$9F,$F2,$9F,$F2
  DEFB $DF,$F2,$B7,$F2,$E7,$F2,$C3,$F2
  DEFB $D3,$F2,$D3,$F2,$C3,$F2,$E7,$F2
  DEFB $9F,$F2,$DF,$F2,$BF,$F2,$C7,$F2
  DEFB $C7,$F2,$BF,$F2,$9F,$F2,$E7,$F2
  DEFB $C3,$F2,$D3,$F2,$D3,$F2,$C3,$F2
  DEFB $9F,$F2,$00,$00,$00,$01,$3C,$EF
  DEFB $F2,$EF,$F2,$05,$F3,$F9,$F2,$F9
  DEFB $F2,$00,$00,$00,$01,$3C,$EF,$F2
  DEFB $EF,$F2,$0D,$F3,$F9,$F2,$F9,$F2
  DEFB $00,$00,$00,$01,$3C,$EF,$F2,$EF
  DEFB $F2,$19,$F3,$F9,$F2,$F9,$F2,$00
  DEFB $00,$00,$01,$3C,$EF,$F2,$EF,$F2
  DEFB $21,$F3,$F9,$F2,$F9,$F2,$00,$00
  DEFB $1F,$01,$3C,$2D,$F3,$37,$F3,$3F
  DEFB $F3,$49,$F3,$FF,$FF,$1F,$01,$3C
  DEFB $37,$F3,$3F,$F3,$49,$F3,$2D,$F3
  DEFB $FF,$FF,$1F,$01,$3C,$3F,$F3,$49
  DEFB $F3,$2D,$F3,$37,$F3,$FF,$FF,$1F
  DEFB $01,$3C,$49,$F3,$2D,$F3,$37,$F3
  DEFB $3F,$F3,$FF,$FF,$08,$3F,$33,$51
  DEFB $F3,$FF,$FF,$00,$3F,$1C,$53,$F3
  DEFB $53,$F3,$53,$F3,$63,$F3,$00,$00
  DEFB $15,$7F,$2C,$0A,$0A,$11,$41,$12
  DEFB $C9,$F0,$C9,$F0,$C9,$F0,$11,$F1
  DEFB $D9,$F0,$11,$F1,$11,$F1,$11,$F1
  DEFB $D9,$F0,$11,$F1,$11,$F1,$11,$F1
  DEFB $D9,$F0,$00,$00,$03,$20,$33,$F7
  DEFB $F1,$FF,$FF

; The enemy kinds StartWave reads (LevelKinds)
L1Kinds:
  DEFB $A1,$EC,$AE,$EC,$B7,$EC,$CA,$EC
  DEFB $D1,$EC,$E2,$EC,$E9,$EC,$00,$ED
  DEFB $0D,$ED,$1C,$ED,$2D,$ED,$32,$ED
  DEFB $43,$ED,$4C,$ED,$59,$ED,$6E,$ED
  DEFB $A3,$ED,$BA,$ED,$D7,$ED,$DE,$ED
  DEFB $E5,$ED,$F4,$ED,$FB,$ED,$02,$EE
  DEFB $1B,$EE,$30,$EE,$49,$EE,$78,$EE
  DEFB $9F,$EE,$BC,$EE,$DF,$EE,$F6,$EE
  DEFB $19,$EF,$4C,$EF,$5B,$EF,$6A,$EF
  DEFB $79,$EF,$88,$EF,$95,$EF,$A2,$EF
  DEFB $AF,$EF,$BC,$EF,$C3,$EF,$D0,$EF
  DEFB $D5,$EF,$F4,$EF,$31,$10,$32,$18
  DEFB $33,$10,$32,$14,$31,$14,$32,$10
  DEFB $33,$18,$32,$90,$12,$16,$12,$16
  DEFB $12,$16,$12,$16,$13,$10,$13,$10
  DEFB $13,$10,$13,$10,$12,$18,$12,$18
  DEFB $12,$18,$12,$18,$13,$10,$13,$10
  DEFB $13,$10,$13,$90,$11,$08,$11,$08
  DEFB $11,$08,$11,$88,$12,$18,$12,$18
  DEFB $13,$10,$13,$10,$13,$10,$13,$90
  DEFB $13,$10,$13,$10,$13,$10,$13,$10
  DEFB $13,$10,$13,$90,$12,$16,$12,$16
  DEFB $12,$16,$12,$16,$12,$16,$12,$16
  DEFB $12,$96,$13,$10,$13,$10,$13,$90
  DEFB $12,$18,$12,$18,$12,$18,$12,$18
  DEFB $12,$18,$12,$18,$12,$98,$35,$21
  DEFB $36,$21,$35,$21,$37,$A1,$35,$10
  DEFB $36,$10,$35,$10,$37,$10,$35,$10
  DEFB $36,$10,$35,$10,$37,$90,$38,$08
  DEFB $38,$08,$38,$08,$38,$08,$38,$08
  DEFB $38,$88,$37,$00,$37,$80,$38,$14
  DEFB $38,$14,$38,$10,$38,$10,$38,$10
  DEFB $38,$18,$38,$18,$38,$18,$38,$98
  DEFB $35,$01,$38,$25,$38,$25,$38,$25
  DEFB $38,$21,$38,$29,$37,$81,$37,$00
  DEFB $37,$00,$37,$00,$37,$80,$38,$14
  DEFB $38,$14,$38,$10,$38,$18,$38,$18
  DEFB $38,$18,$38,$98,$3A,$20,$3A,$20
  DEFB $3A,$20,$3A,$20,$3A,$20,$3B,$25
  DEFB $3B,$25,$3B,$25,$3B,$25,$3B,$25
  DEFB $3C,$05,$3C,$05,$3C,$05,$3C,$05
  DEFB $3C,$05,$3B,$17,$3B,$17,$3B,$17
  DEFB $3B,$17,$3B,$17,$3A,$12,$3A,$12
  DEFB $3A,$12,$3A,$12,$3A,$12,$3B,$1A
  DEFB $3B,$1A,$3B,$1A,$3B,$1A,$3B,$1A
  DEFB $3C,$08,$3C,$08,$3C,$08,$3C,$08
  DEFB $3C,$08,$3B,$28,$3B,$28,$3B,$28
  DEFB $3B,$28,$3B,$A8,$21,$18,$21,$18
  DEFB $21,$18,$21,$18,$21,$18,$21,$98
  DEFB $21,$10,$21,$10,$21,$10,$21,$90
  DEFB $21,$14,$21,$14,$21,$14,$21,$14
  DEFB $21,$14,$21,$94,$21,$08,$21,$08
  DEFB $21,$08,$21,$88,$1F,$10,$1E,$10
  DEFB $1F,$10,$1E,$90,$1F,$21,$1E,$21
  DEFB $1F,$21,$1E,$A1,$20,$00,$20,$80
  DEFB $20,$01,$20,$81,$21,$25,$21,$25
  DEFB $21,$25,$21,$25,$21,$25,$21,$A5
  DEFB $21,$21,$21,$A1,$21,$29,$21,$29
  DEFB $21,$29,$21,$A9,$29,$00,$29,$00
  DEFB $29,$00,$29,$80,$0C,$10,$0C,$10
  DEFB $0C,$10,$0C,$10,$0C,$10,$0C,$10
  DEFB $0C,$90,$23,$00,$24,$00,$24,$80
  DEFB $25,$00,$24,$00,$24,$80,$23,$80
  DEFB $25,$80,$40,$80,$40,$82,$41,$10
  DEFB $41,$00,$41,$10,$42,$00,$43,$00
  DEFB $43,$00,$43,$00,$43,$00,$43,$00
  DEFB $42,$00,$41,$00,$42,$20,$42,$20
  DEFB $42,$00,$42,$00,$42,$80,$26,$13
  DEFB $27,$13,$26,$10,$27,$10,$26,$13
  DEFB $27,$93,$26,$17,$27,$17,$26,$14
  DEFB $27,$94,$26,$1B,$27,$1B,$26,$18
  DEFB $27,$98,$44,$02,$44,$02,$44,$02
  DEFB $44,$02,$44,$02,$44,$02,$44,$02
  DEFB $44,$92,$44,$00,$44,$00,$44,$00
  DEFB $44,$00,$44,$00,$44,$00,$44,$00
  DEFB $44,$90,$39,$80,$2B,$08,$2B,$08
  DEFB $2B,$08,$2B,$88,$2B,$00,$2B,$00
  DEFB $2B,$00,$2B,$80,$2B,$10,$2C,$10
  DEFB $2B,$10,$2C,$90,$2B,$10,$2B,$10
  DEFB $2B,$10,$2B,$10,$2B,$10,$2B,$10
  DEFB $2B,$10,$2B,$90,$2B,$00,$2B,$00
  DEFB $2B,$00,$2B,$00,$2B,$00,$2B,$00
  DEFB $2B,$00,$2B,$00,$2B,$00,$2B,$00
  DEFB $2B,$00,$2B,$00,$2B,$00,$2B,$00
  DEFB $2B,$00,$2B,$80,$15,$10,$16,$10
  DEFB $17,$10,$16,$10,$15,$10,$16,$10
  DEFB $17,$10,$16,$90,$15,$21,$16,$21
  DEFB $17,$21,$16,$21,$15,$21,$16,$21
  DEFB $17,$21,$16,$A1,$18,$00,$18,$80
  DEFB $18,$01,$18,$81,$19,$00,$19,$00
  DEFB $19,$00,$19,$00,$19,$00,$19,$80
  DEFB $19,$01,$19,$01,$19,$01,$19,$01
  DEFB $19,$01,$19,$81,$15,$00,$15,$00
  DEFB $15,$00,$15,$80,$15,$01,$15,$01
  DEFB $15,$01,$15,$81,$02,$04,$02,$04
  DEFB $02,$04,$02,$04,$02,$84,$02,$0A
  DEFB $02,$0A,$02,$0A,$02,$0A,$02,$0A
  DEFB $02,$8A,$03,$14,$04,$10,$04,$10
  DEFB $03,$9A,$03,$14,$03,$14,$04,$10
  DEFB $04,$10,$03,$1A,$03,$9A,$03,$25
  DEFB $04,$21,$04,$21,$03,$AB,$03,$25
  DEFB $03,$25,$04,$21,$04,$21,$03,$2B
  DEFB $03,$AB,$05,$04,$05,$04,$06,$14
  DEFB $06,$14,$06,$94,$07,$10,$07,$10
  DEFB $06,$1A,$06,$9A,$05,$0A,$05,$0A
  DEFB $06,$2B,$06,$2B,$06,$AB,$07,$21
  DEFB $07,$21,$06,$25,$06,$A5,$08,$80
  DEFB $09,$00,$09,$00,$09,$00,$09,$00
  DEFB $09,$00,$09,$00,$09,$00,$09,$90
  DEFB $09,$80

; The first mover of each kind (16 words, LevelMoves)
L1MoversA:
  DEFW L1MoverA0
  DEFW L1MoverA1
  DEFW L1MoverA2
  DEFW L1MoverA3
  DEFW L1MoverA4
  DEFW L1MoverA5
  DEFW L1MoverA6
  DEFW L1MoverA7
  DEFW L1MoverA8
  DEFW L1MoverA9
  DEFW L1MoverA10
  DEFW L1MoverA11
  DEFW L1MoverA12
  DEFW L1MoverA13
  DEFW L1MoverA14
  DEFW L1MoverA15

; The second mover of each kind (16 words, LevelMoves2)
L1MoversB:
  DEFW L1MoverB0
  DEFW L1MoverB1
  DEFW L1MoverB2
  DEFW L1MoverB2
  DEFW L1MoverB2
  DEFW L1MoverB2
  DEFW L1MoverB6
  DEFW L1MoverB7
  DEFW L1MoverB8
  DEFW L1MoverB9
  DEFW L1MoverB10
  DEFW L1MoverB10
  DEFW L1MoverB9
  DEFW L1MoverB13
  DEFW L1MoverB14
  DEFW L1MoverB15

; Mover A0
;
; Witness: L1 0 (none).
L1MoverA0:
  JP C,MoveNext
  JP MoveStore

; Mover A1
;
; Witness: L1 2430 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; gameover, hiscore, hiscore-typed, l1).
L1MoverA1:
  JP C,MoveNext
; This entry point is used by the routines at L1MoverA2, L1MoverA5, L1MoverA12,
; L1MoverA13, L1MoverA14 and L1MoverA15.
l_F3AE:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveStore
  JP MoveDraw

; Mover A2
;
; Witness: L1 231 (l1).
L1MoverA2:
  JR NC,l_F3AE
  JP MoveNext

; Mover A3
;
; Witness: L1 2205 (l1).
L1MoverA3:
  PUSH AF
  CALL L1DriftLeft
  POP AF
  JP NC,MoveStore
  LD HL,(Scratch+2)
  INC L
  DEC (HL)
  LD HL,LevelVars+1
  INC (HL)
  LD A,(HL)
  CP $04
  JP NZ,MoveNext
  LD A,$73
  LD (MapColumn),A
  LD HL,L1Waves+$050F
  LD (WavePtr),HL
  JP MoveNext

; Mover A4
;
; Witness: L1 479 (l1).
L1MoverA4:
  JR NC,l_F3F6
  LD A,(EnemySlots+84)
  CP (IY+$03)
  JR C,L1BossHit
  LD (IY+$00),$02
  LD HL,(Scratch+2)
  LD (HL),$00
l_F3F6:
  LD A,(LevelVars)
  AND A
  JR Z,l_F404
  CP $07
  JR Z,l_F404
  DEC A
  LD (LevelVars),A
l_F404:
  EX AF,AF'
  ADD A,$03
  EX AF,AF'

; Mover A5
;
; Witness: L1 8143 (l1).
L1MoverA5:
  LD A,(LevelVars)
  CP $07
  JR NZ,l_F414
  CALL L1ExplosionsLast
  JR l_F45F
l_F414:
  AND A
  JR NZ,l_F447
; This entry point is used by the routine at L1BossHit.
l_F417:
  LD A,(EnemySlots+215)
  AND A
  JP Z,l_F3AE
  LD A,(FrameCounter)
  INC A
  AND $07
  JP NZ,l_F3AE
  DEC C
  JP l_F3AE

; two bytes between the movers ($30, $C9): no recording reads or runs them
; (known only from the code)
L1Gap:
  DEFB $30,$C9

; Mover A4's end: LevelVars = $1A, the slot indestructible ($3F), the
; explosions drawn first (L1ExplosionsFirst), points (AddScore with $0104 and
; $0503)
;
; No recording ran it: known only from the code.
L1BossHit:
  LD A,$1A
  LD (LevelVars),A
  LD (IY+$00),$3F
  PUSH DE
  CALL L1ExplosionsFirst
  LD DE,$0104
  CALL AddScore
  LD DE,$0503
  CALL AddScore
  POP DE
; This entry point is used by the routine at L1MoverA5.
l_F447:
  LD A,(DrawTag)
  AND $1F
  LD L,A
  LD A,(LevelVars)
  CP L
  JR NC,l_F417
  PUSH BC
  PUSH DE
  DEC C
  LD (Scratch),BC
  CALL EnemyDies
  POP DE
  POP BC
; This entry point is used by the routine at L1MoverA5.
l_F45F:
  LD A,$10
  EX AF,AF'
  LD (IY+$00),$3F
  JR l_F417

; Mover A6
;
; Witness: L1 4991 (l1).
L1MoverA6:
  JR C,l_F4C6
  LD A,(FrameCounter)
  AND $07
  JR Z,l_F47A
  LD (IY+$03),C
  LD (IY+$04),B
  JP MoveNext
l_F47A:
  LD A,(IY+$03)
  AND A
  JR NZ,l_F487
  LD (IY+$00),$00
  JP MoveDone
l_F487:
  LD A,$20
  CALL SetDrawLimitA
  DEC C
  LD HL,$0201
  LD A,$46
  CALL ClearCellsTag
  INC C
  LD HL,$0202
  CALL ClearCells
  LD A,(DrawTag)
  AND $1F
  ADD A,$DC
  LD (DrawTag),A
  CALL SoftCellsOn
  LD A,$44
  EX AF,AF'
  LD A,(ShipColumn)
  INC A
  CP C
  JR NZ,l_F4B9
  LD A,$45
  EX AF,AF'
  LD A,(DE)
  JR l_F4BD
l_F4B9:
  LD A,(DE)
  JR C,l_F4BD
  INC A
l_F4BD:
  LD (IY+$03),C
  LD (IY+$04),B
  JP MoveDrawA
l_F4C6:
  LD HL,$0203
  CALL ClearCells
  DEC C
  LD HL,(Scratch+2)
  INC L
  DEC (HL)
  LD A,$46
  EX AF,AF'
  JP MoveStore

; Mover A7
;
; Witness: L1 1188 (l1).
L1MoverA7:
  LD A,(IY+$08)
  CP $01
  JP NZ,MoveStore
  INC (IY+$08)
  LD HL,$0941
  CALL $F87C
  JP MoveStore

; Mover A8
;
; Witness: L1 736 (l1).
L1MoverA8:
  LD A,$9C
  LD (DrawTag),A
  CALL L1DriftLeft
  LD A,(MapColumn)
  CP $73
  JR C,l_F530
  JR NZ,l_F51B
  LD A,(FrameCounter)
  AND $1F
  CP $10
  JR NZ,l_F51B
  LD HL,EnemySlots+171
  PUSH DE
  PUSH BC
  CALL L1BlastRecord
  CALL L1BlastRecord
  CALL L1BlastRecord
  CALL L1BlastRecord
  POP BC
  POP DE
  JR l_F530
l_F51B:
  LD A,(MapColumn)
  CP $73
  JR Z,l_F530
  LD A,(FrameCounter)
  AND $07
  JR NZ,l_F530
  LD A,(EnemySlots+12)
  DEC A
  LD (EnemySlots+12),A
l_F530:
  LD A,(FrameCounter)
  AND $07
  JP NZ,MoveDone
  JP MoveStore

; Free the record at HL: zero it, take its position less one column, start an
; explosion there (FreeExplosion)
;
; Witness: L1 4 (l1).
L1BlastRecord:
  PUSH HL
  LD A,(HL)
  AND A
  JR Z,l_F553
  LD (HL),$00
  INC L
  INC L
  INC L
  LD C,(HL)
  INC L
  LD B,(HL)
  DEC C
  LD (Scratch),BC
  CALL FreeExplosion
  CALL AwardScore
l_F553:
  POP HL
  LD A,L
  ADD A,$09
  LD L,A
  RET

; Mover A9
;
; Witness: L1 736 (l1).
L1MoverA9:
  CALL L1DriftLeft
  LD A,(FrameCounter)
  RRCA
  AND $0F
  LD E,A
  ADD A,A
  ADD A,A
  ADD A,A
  SUB E
  LD E,A
  LD D,$00
  LD HL,L1ShapeFrames
  ADD HL,DE
  LD A,$80
  LD (DrawTag),A
  LD B,$0F
  LD C,(IY+$03)
  LD A,$0E
l_F57A:
  PUSH AF
  AND $01
  LD A,(HL)
  JR Z,l_F585
  INC HL
  RRCA
  RRCA
  RRCA
  RRCA
l_F585:
  AND $0F
  CALL MoveByBits
  PUSH HL
  PUSH BC
  LD A,$39
  CALL LevelObject
  CALL DrawSprite
  POP BC
  POP HL
  POP AF
  DEC A
  JR NZ,l_F57A
  LD A,(EnemySlots+9)
  AND A
  JP NZ,MoveDone
  CALL BossDestroyed
  LD DE,$0304
  CALL AddScore
  JP MoveDone

; Mover A10
;
; Witness: L1 925 (l1).
L1MoverA10:
  JP C,MoveNext
  LD A,(IY+$08)
  CP $06
  JR Z,l_F5D0
  AND $01
  JP Z,MoveStore
  LD L,B
  INC L
  INC L
  LD A,(ShipRow)
  CP L
  JP Z,MoveStore
  JR C,l_F5CC
  INC B
  JP MoveStore
l_F5CC:
  DEC B
  JP MoveStore
l_F5D0:
  LD HL,L1SpawnA+$0002
  LD A,B
  INC A
  LD (HL),A
  LD HL,L1SpawnA
  CALL StartWaveAt
  LD HL,$0941
  CALL $F87C
  JP MoveStore

; A wave record (kind $0D, then the position the movers write) passed to
; StartWaveAt
L1SpawnA:
  DEFB $0D,$18,$00

; Mover A11
;
; Witness: L1 616 (l1).
L1MoverA11:
  DEC C
  JP MoveStore

; Mover A12
;
; Witness: L1 1779 (l1).
L1MoverA12:
  JP C,MoveNext
  LD A,(ShipColumn)
  CP C
  LD L,$01
  JR NC,l_F5F9
  LD L,$00
l_F5F9:
  LD A,(DE)
  AND $FE
  OR L
  LD (DE),A
  LD A,(IY+$08)
  AND $01
  JP Z,l_F3AE
  PUSH BC
  PUSH DE
  LD H,B
  LD L,C
  INC H
  INC L
  LD A,(ShipRow)
  CP H
  JR C,l_F617
  INC B
  INC H
  INC H
  JR l_F61A
l_F617:
  DEC B
  DEC H
  DEC H
l_F61A:
  LD A,(ShipColumn)
  CP L
  JR C,l_F625
  INC C
  INC L
  INC L
  JR l_F628
l_F625:
  DEC C
  DEC L
  DEC L
l_F628:
  PUSH BC
  PUSH HL
  POP BC
  CALL GetCell
  AND A
  JR Z,l_F637
  POP HL
  POP DE
  POP BC
  JP MoveStore
l_F637:
  POP BC
  POP DE
  POP HL
  JP MoveStore

; Mover A13
;
; Witness: L1 391 (l1).
L1MoverA13:
  JP C,MoveNext
  LD A,(IY+$08)
  CP $09
  JR C,l_F673
  LD L,B
  INC L
  INC L
  LD A,(ShipRow)
  CP L
  JR Z,l_F656
  JR C,l_F655
  INC B
  JR l_F656
l_F655:
  DEC B
l_F656:
  LD A,(FrameCounter)
  AND $0F
  JR NZ,l_F673
  LD HL,$1281
  CALL $F87C
  LD HL,EnemyShots+75
  LD A,(HL)
  AND A
  JR NZ,l_F673
  LD (HL),$B4
  INC L
  LD (HL),C
  INC (HL)
  INC L
  LD (HL),B
  INC (HL)
  INC (HL)
l_F673:
  EX AF,AF'
  CP $2B
  JR NZ,l_F681
  PUSH AF
  LD A,(IY+$04)
  CP $0D
  JR NZ,l_F6A4
  POP AF
l_F681:
  EX AF,AF'
l_F682:
  LD A,(FrameCounter)
  AND $1F
  JP NZ,l_F3AE
  LD A,$26
  PUSH BC
l_F68D:
  PUSH AF
  LD HL,L1SpawnB+$0005
  LD (HL),B
  DEC HL
  LD (HL),C
  DEC HL
  LD (HL),A
  CALL StartWaveAt
  INC C
  POP AF
  INC A
  CP $2A
  JR NZ,l_F68D
  POP BC
  JP l_F3AE
l_F6A4:
  PUSH BC
  PUSH IX
  PUSH DE
  EX DE,HL
  RES 0,(HL)
  INC B
  LD E,C
  INC E
  INC E
  INC E
  LD A,(ShipColumn)
  INC A
  CP E
  JR C,l_F6C0
  SET 0,(HL)
  LD A,$B8
  LD HL,DrawSpriteMirrored
  JR l_F6C9
l_F6C0:
  LD A,C
  ADD A,$04
  LD C,A
  LD A,$B4
  LD HL,DrawSprite
l_F6C9:
  LD (l_F656+$0015),A
  LD (l_F6C9+$0011),HL
  LD A,(FrameCounter)
  AND $01
  ADD A,$2F
  CALL LevelObject
  CALL DrawSprite
  POP DE
  POP IX
  POP BC
  POP AF
  EX AF,AF'
  JR l_F682

; Two wave records (kinds $2A and $26) the movers fill and pass to StartWaveAt
L1SpawnB:
  DEFB $2A,$00,$00,$26,$00,$00

; Mover A14
;
; Witness: L1 633 (l1).
L1MoverA14:
  EX AF,AF'
  CP $19
  JR Z,l_F6F3
  EX AF,AF'
  JP l_F3AE
l_F6F3:
  EX AF,AF'
  LD A,(FrameCounter)
  AND $03
  JP NZ,l_F3AE
  LD HL,L1SpawnC+$0002
  LD (HL),B
  DEC HL
  LD (HL),C
  LD A,(DE)
  AND $01
  JR Z,l_F710
  DEC (HL)
  LD A,R
  AND $01
  ADD A,$24
  JR l_F717
l_F710:
  INC (HL)
  LD A,R
  AND $01
  ADD A,$22
l_F717:
  DEC HL
  LD (HL),A
  CALL StartWaveAt
  LD HL,$1121
  CALL $F87C
  JP l_F3AE

; A wave record the movers fill and pass to StartWaveAt
L1SpawnC:
  DEFB $00,$00,$00

; Mover A15
;
; Witness: L1 2149 (l1).
L1MoverA15:
  PUSH DE
  CALL GetCell
  POP DE
  JR NC,l_F734
  CP $9C
  JP NZ,l_F3AE
l_F734:
  LD (IY+$00),$00
  LD (Scratch),BC
  CALL EnemyDies
  JP MoveDone

; Mover B0
;
; Witness: L1 23922 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; gameover, hiscore, hiscore-typed, l1).
L1MoverB0:
  JP MoveScript

; Mover B1
;
; Witness: L1 17671 (c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; gameover, hiscore, hiscore-typed, l1).
L1MoverB1:
  LD A,(FrameCounter)
  AND $01
  JP NZ,MoveScript
  JP MoveDone

; Mover B2, B3, B4, B5
;
; No recording ran it: known only from the code.
L1MoverB2:
  CALL SoftCellsOff
  JR L1MoverB1

; Mover B6
;
; Witness: L1 4977 (l1).
L1MoverB6:
  CALL SoftCellsOff
  LD A,$1F
  CALL SetDrawLimitA
  JR L1MoverB0

; Mover B7
;
; Witness: L1 26 (l1).
L1MoverB7:
  LD L,$08
  JR l_F779

; Mover B8
;
; No recording ran it: known only from the code.
L1MoverB8:
  LD L,$09
  JR l_F779

; Mover B10, B11
;
; Witness: L1 58 (l1).
L1MoverB10:
  LD L,$03
  JR l_F779

; Mover B9, B12
;
; Witness: L1 17 (l1).
L1MoverB9:
  LD L,$04
  JR l_F779

; Mover B13
;
; Witness: L1 21 (l1).
L1MoverB13:
  LD L,$05
  JR l_F779

; Mover B14
;
; Witness: L1 50 (l1).
L1MoverB14:
  LD L,$06
  JR l_F779

; Mover B15
;
; Witness: L1 59 (l1).
L1MoverB15:
  LD L,$07
; This entry point is used by the routines at L1MoverB7, L1MoverB8, L1MoverB10,
; L1MoverB9, L1MoverB13 and L1MoverB14.
l_F779:
  CALL L1SlotBusy
  LD A,(Carriers)
  AND A
  JR NZ,l_F796
  LD (Carriers+2),BC
  LD A,L
  LD (Carriers),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+1),A
  JP MoveScript
l_F796:
  LD (Carriers+6),BC
  LD A,L
  LD (Carriers+4),A
  LD A,(FrameCounter)
  DEC A
  AND $07
  LD (Carriers+5),A
  JP MoveScript

; Move the CALL DrawExplosions from $866B to MainLoopPatch ($8656): the
; explosions drawn before the enemies
;
; No recording ran it: known only from the code.
L1ExplosionsFirst:
  PUSH DE
  LD DE,MainLoopPatch+21
  LD HL,MainLoopPatch
  JR l_F7BA

; Move the CALL DrawExplosions back from MainLoopPatch to $866B
;
; No recording ran it: known only from the code.
L1ExplosionsLast:
  PUSH DE
  LD DE,MainLoopPatch
  LD HL,MainLoopPatch+21
; This entry point is used by the routine at L1ExplosionsFirst.
l_F7BA:
  LD (HL),$CD
  INC HL
  LD (HL),$0E
  INC HL
  LD (HL),$C4
  XOR A
  LD (DE),A
  INC DE
  LD (DE),A
  INC DE
  LD (DE),A
  POP DE
  RET

; Unless MapColumn is $6B-$73: every 8th pass move the slot one column left
; (column - 1 into IY+3)
;
; Witness: L1 3677 (l1).
L1DriftLeft:
  LD A,(MapColumn)
  CP $74
  JR NC,l_F7D4
  CP $6B
  RET NC
l_F7D4:
  LD A,(FrameCounter)
  AND $07
  RET NZ
  DEC C
  LD (IY+$03),C
  RET

; Return while the slot is free; else drop the return and go on at Mover B1
; (Mover B15 calls it)
;
; Witness: L1 231 (l1).
L1SlotBusy:
  LD A,(IY+$00)
  AND A
  JR NZ,l_F7E6
  RET
l_F7E6:
  POP HL
  JP L1MoverB1

; 16 frames of 7 bytes, a nibble a row (14 rows): the column offsets Mover A9
; draws a shape of tag $80 from, a frame by FrameCounter
L1ShapeFrames:
  DEFB $00,$50,$55,$45,$64,$66,$46
  DEFB $00,$50,$55,$45,$44,$66,$66
  DEFB $00,$50,$55,$55,$44,$66,$66
  DEFB $00,$15,$11,$51,$45,$64,$66
  DEFB $00,$15,$11,$11,$51,$44,$66
  DEFB $00,$44,$15,$91,$99,$51,$44
  DEFB $40,$54,$11,$99,$99,$11,$45
  DEFB $40,$54,$15,$91,$99,$19,$51
  DEFB $40,$44,$54,$15,$99,$99,$99
  DEFB $40,$44,$44,$54,$15,$91,$99
  DEFB $40,$44,$44,$44,$55,$91,$99
  DEFB $40,$44,$64,$44,$54,$15,$99
  DEFB $00,$44,$44,$66,$44,$15,$91
  DEFB $00,$54,$45,$64,$46,$54,$91
  DEFB $00,$50,$55,$44,$66,$46,$15
  DEFB $00,$50,$55,$44,$64,$66,$54
