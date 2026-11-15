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
  DEFB $08,$01,$63,$03,$1A,$08,$01,$01
  DEFB $64,$64,$08,$01,$63,$04,$08,$0A
  DEFB $00,$2A,$1F,$02,$0A,$00,$2F,$1F
  DEFB $11,$0A,$1D,$1D,$1F,$06,$0B,$00
  DEFB $02,$20,$08,$0B,$00,$03,$35,$02
  DEFB $0C,$00,$03,$31,$02,$0C,$10,$35
  DEFB $1F,$05,$0D,$00,$03,$2D,$02,$0E
  DEFB $00,$03,$29,$02,$0E,$08,$39,$1F
  DEFB $0B,$0F,$00,$03,$25,$02,$10,$00
  DEFB $02,$20,$02,$10,$08,$30,$1F,$11
  DEFB $11,$00,$02,$20,$02,$12,$00,$04
  DEFB $19,$F8,$12,$08,$2B,$1F,$02,$13
  DEFB $00,$05,$0E,$16,$13,$06,$06,$FD
  DEFB $0E,$13,$10,$21,$1D,$0A,$13,$18
  DEFB $21,$1D,$06,$14,$00,$04,$11,$F8
  DEFB $14,$18,$22,$1B,$01,$15,$00,$22
  DEFB $1A,$01,$15,$04,$02,$20,$02,$15
  DEFB $0E,$06,$F4,$0E,$15,$10,$31,$1F
  DEFB $11,$15,$18,$07,$09,$F8,$16,$00
  DEFB $36,$1F,$05,$16,$00,$02,$20,$02
  DEFB $16,$06,$06,$F1,$0E,$16,$1E,$06
  DEFB $EE,$0E,$18,$00,$08,$1F,$0E,$18
  DEFB $00,$0B,$FE,$0E,$19,$06,$09,$25
  DEFB $0E,$19,$1E,$09,$22,$0E,$1A,$18
  DEFB $0A,$F8,$02,$1C,$14,$0C,$26,$02
  DEFB $1F,$00,$0D,$00,$0E,$20,$14,$0E
  DEFB $14,$14,$21,$14,$0F,$18,$14,$22
  DEFB $10,$10,$1C,$FD,$24,$08,$23,$1B
  DEFB $FD,$24,$10,$11,$18,$14,$26,$00
  DEFB $25,$16,$FD,$26,$04,$25,$16,$FD
  DEFB $26,$08,$25,$15,$FD,$26,$0C,$25
  DEFB $15,$FD,$26,$10,$25,$14,$FD,$26
  DEFB $14,$25,$14,$FD,$26,$18,$24,$0A
  DEFB $FB,$26,$18,$25,$13,$FD,$26,$1C
  DEFB $25,$13,$FD,$27,$00,$23,$10,$FD
  DEFB $27,$00,$26,$12,$FD,$27,$04,$26
  DEFB $12,$FD,$27,$08,$26,$11,$FD,$27
  DEFB $0C,$26,$11,$FD,$27,$10,$26,$10
  DEFB $FD,$27,$14,$26,$10,$FD,$27,$18
  DEFB $26,$0F,$FD,$27,$1C,$26,$0F,$FD
  DEFB $28,$00,$27,$0E,$FD,$28,$04,$27
  DEFB $0E,$FD,$28,$08,$27,$0D,$FD,$28
  DEFB $0C,$27,$0D,$FD,$28,$10,$27,$0C
  DEFB $FD,$28,$14,$27,$0C,$FD,$28,$1C
  DEFB $28,$0B,$FD,$29,$0C,$12,$23,$02
  DEFB $2A,$00,$1E,$1E,$09,$2C,$08,$32
  DEFB $1F,$11,$2C,$10,$13,$2A,$0E,$2D
  DEFB $18,$13,$25,$0E,$2D,$1C,$37,$1F
  DEFB $05,$2D,$1C,$37,$1F,$0B,$2F,$00
  DEFB $13,$20,$0E,$2F,$08,$2C,$1F,$02
  DEFB $2F,$10,$14,$2C,$0E,$30,$00,$14
  DEFB $2A,$0E,$30,$01,$1F,$1F,$09,$30
  DEFB $08,$33,$1F,$11,$30,$10,$14,$28
  DEFB $0E,$32,$12,$0A,$F4,$02,$33,$04
  DEFB $38,$1F,$05,$33,$04,$38,$1F,$0B
  DEFB $33,$12,$0A,$F0,$02,$35,$08,$02
  DEFB $20,$08,$36,$08,$15,$20,$0E,$36
  DEFB $08,$16,$20,$02,$36,$0C,$2D,$1F
  DEFB $02,$37,$0A,$02,$20,$08,$37,$18
  DEFB $34,$1F,$11,$37,$1A,$17,$13,$FC
  DEFB $3B,$00,$63,$03,$19,$3B,$00,$20
  DEFB $1F,$0F,$3D,$07,$29,$17,$0F,$3D
  DEFB $10,$63,$01,$00,$3E,$00,$1A,$10
  DEFB $FD,$3E,$18,$19,$11,$FD,$3F,$10
  DEFB $19,$11,$FD,$40,$08,$1A,$10,$FD
  DEFB $41,$00,$19,$11,$FD,$41,$18,$1A
  DEFB $10,$FD,$42,$10,$1A,$10,$FD,$43
  DEFB $08,$19,$11,$FD,$44,$00,$1C,$0E
  DEFB $FD,$44,$18,$19,$11,$FD,$45,$10
  DEFB $19,$11,$FD,$46,$08,$1B,$0F,$FD
  DEFB $47,$00,$1A,$10,$FD,$47,$18,$19
  DEFB $11,$FD,$48,$10,$1C,$0E,$FD,$49
  DEFB $08,$1A,$10,$FD,$4C,$00,$63,$05
  DEFB $00,$FF,$FF,$FF,$FF,$FF,$00,$3F
  DEFB $2C,$D4,$E3,$D4,$E3,$FF,$FF,$03
  DEFB $0C,$4A,$B2,$E4,$B2,$E4,$B2,$E4
  DEFB $B2,$E4,$00,$00,$03,$0C,$4A,$B2
  DEFB $E4,$B2,$E4,$B2,$E4,$B2,$E4,$E2
  DEFB $E4,$EA,$E4,$C2,$E4,$C2,$E4,$C2
  DEFB $E4,$C2,$E4,$00,$00,$03,$0C,$4A
  DEFB $E2,$E4,$E2,$E4,$B2,$E4,$B2,$E4
  DEFB $B2,$E4,$00,$00,$03,$0C,$4A,$D2
  DEFB $E4,$B2,$E4,$B2,$E4,$00,$00,$03
  DEFB $0C,$4A,$C2,$E4,$C2,$E4,$C2,$E4
  DEFB $C2,$E4,$D2,$E4,$DA,$E4,$B2,$E4
  DEFB $B2,$E4,$B2,$E4,$B2,$E4,$00,$00
  DEFB $03,$0C,$4A,$E2,$E4,$E2,$E4,$D2
  DEFB $E4,$D2,$E4,$00,$00,$03,$0C,$4A
  DEFB $B2,$E4,$BA,$E4,$D6,$E4,$C2,$E4
  DEFB $C2,$E4,$00,$00,$03,$0C,$4A,$B2
  DEFB $E4,$B2,$E4,$B2,$E4,$D6,$E4,$C2
  DEFB $E4,$C2,$E4,$E6,$E4,$B2,$E4,$B2
  DEFB $E4,$B2,$E4,$B2,$E4,$00,$00,$03
  DEFB $0C,$4A,$C2,$E4,$C2,$E4,$C2,$E4
  DEFB $C2,$E4,$E2,$E4,$EA,$E4,$B2,$E4
  DEFB $B2,$E4,$B2,$E4,$00,$00,$04,$0C
  DEFB $4A,$CA,$E4,$C2,$E4,$D2,$E4,$DA
  DEFB $E4,$B2,$E4,$B2,$E4,$00,$00,$03
  DEFB $0C,$4A,$BA,$E4,$B2,$E4,$E2,$E4
  DEFB $E2,$E4,$E2,$E4,$00,$00,$03,$0C
  DEFB $4A,$C2,$E4,$C2,$E4,$D0,$E4,$D2
  DEFB $E4,$DA,$E4,$BC,$E4,$E2,$E4,$E2
  DEFB $E4,$E2,$E4,$00,$00,$03,$0C,$4A
  DEFB $DE,$E4,$D2,$E4,$D2,$E4,$B2,$E4
  DEFB $BA,$E4,$E2,$E4,$E2,$E4,$E2,$E4
  DEFB $00,$00,$03,$0C,$4A,$DE,$E4,$D2
  DEFB $E4,$D2,$E4,$CA,$E4,$E2,$E4,$E2
  DEFB $E4,$E2,$E4,$00,$00,$03,$0C,$4A
  DEFB $E2,$E4,$E6,$E4,$BE,$E4,$E2,$E4
  DEFB $00,$00,$03,$0C,$4A,$DA,$E4,$C2
  DEFB $E4,$CA,$E4,$00,$00,$03,$0C,$4A
  DEFB $BA,$E4,$B2,$E4,$E2,$E4,$C0,$E4
  DEFB $E2,$E4,$E2,$E4,$00,$00,$03,$0C
  DEFB $4A,$B2,$E4,$B2,$E4,$D2,$E4,$DA
  DEFB $E4,$C2,$E4,$C2,$E4,$C2,$E4,$00
  DEFB $00,$03,$0C,$4A,$B2,$E4,$B2,$E4
  DEFB $B2,$E4,$B2,$E4,$D2,$E4,$DA,$E4
  DEFB $C2,$E4,$C2,$E4,$D0,$E4,$E2,$E4
  DEFB $EA,$E4,$B2,$E4,$B2,$E4,$B2,$E4
  DEFB $B2,$E4,$00,$00,$03,$0C,$4A,$B2
  DEFB $E4,$B2,$E4,$C0,$E4,$C2,$E4,$CC
  DEFB $E4,$E2,$E4,$00,$00,$03,$0C,$4A
  DEFB $B2,$E4,$B2,$E4,$C0,$E4,$C2,$E4
  DEFB $CE,$E4,$E2,$E4,$E2,$E4,$E2,$E4
  DEFB $00,$00,$03,$0C,$4A,$E2,$E4,$E2
  DEFB $E4,$EE,$E4,$B2,$E4,$BA,$E4,$C2
  DEFB $E4,$CC,$E4,$B2,$E4,$B2,$E4,$BA
  DEFB $E4,$00,$00,$03,$0C,$4A,$C2,$E4
  DEFB $C2,$E4,$D0,$E4,$D6,$E4,$BC,$E4
  DEFB $E6,$E4,$C0,$E4,$E6,$E4,$C2,$E4
  DEFB $C2,$E4,$D6,$E4,$C0,$E4,$D6,$E4
  DEFB $BC,$E4,$E6,$E4,$C2,$E4,$C2,$E4
  DEFB $00,$00,$03,$0C,$4A,$E2,$E4,$E2
  DEFB $E4,$F0,$E4,$B2,$E4,$BE,$E4,$D2
  DEFB $E4,$DA,$E4,$CC,$E4,$E6,$E4,$B2
  DEFB $E4,$B2,$E4,$00,$00,$03,$0C,$4A
  DEFB $E2,$E4,$E2,$E4,$F0,$E4,$C2,$E4
  DEFB $CE,$E4,$D2,$E4,$DA,$E4,$BC,$E4
  DEFB $E6,$E4,$C2,$E4,$C2,$E4,$00,$00
  DEFB $04,$0C,$4A,$E2,$E4,$E2,$E4,$F0
  DEFB $E4,$B2,$E4,$BE,$E4,$D2,$E4,$DA
  DEFB $E4,$CC,$E4,$E6,$E4,$B2,$E4,$B2
  DEFB $E4,$00,$00,$04,$10,$4A,$E2,$E4
  DEFB $E2,$E4,$F0,$E4,$C2,$E4,$CE,$E4
  DEFB $D2,$E4,$DA,$E4,$BC,$E4,$E6,$E4
  DEFB $C2,$E4,$C2,$E4,$00,$00,$B2,$01
  DEFB $22,$52,$E4,$46,$E4,$68,$E4,$82
  DEFB $E4,$76,$E4,$86,$E4,$8A,$E4,$00
  DEFB $00,$C2,$01,$22,$6E,$E4,$6E,$E4
  DEFB $82,$E4,$60,$E4,$52,$E4,$52,$E4
  DEFB $66,$E4,$6C,$E4,$82,$E4,$6E,$E4
  DEFB $6E,$E4,$6E,$E4,$6E,$E4,$00,$00
  DEFB $B2,$01,$22,$6E,$E4,$6E,$E4,$6E
  DEFB $E4,$6E,$E4,$86,$E4,$94,$E4,$B0
  DEFB $E4,$86,$E4,$76,$E4,$7E,$E4,$86
  DEFB $E4,$94,$E4,$94,$E4,$AA,$E4,$AA
  DEFB $E4,$86,$E4,$6E,$E4,$82,$E4,$64
  DEFB $E4,$6C,$E4,$82,$E4,$6E,$E4,$6E
  DEFB $E4,$6E,$E4,$86,$E4,$82,$E4,$86
  DEFB $E4,$66,$E4,$66,$E4,$00,$00,$F2
  DEFB $01,$22,$6E,$E4,$6E,$E4,$6E,$E4
  DEFB $6E,$E4,$6E,$E4,$86,$E4,$94,$E4
  DEFB $B0,$E4,$86,$E4,$76,$E4,$76,$E4
  DEFB $7E,$E4,$00,$00,$00,$41,$12,$F6
  DEFB $E3,$F6,$E3,$F6,$E3,$00,$00,$00
  DEFB $41,$12,$FE,$E3,$06,$E4,$F6,$E3
  DEFB $F6,$E3,$F6,$E3,$00,$00,$00,$41
  DEFB $12,$FE,$E3,$FE,$E3,$02,$E4,$E6
  DEFB $E3,$E6,$E3,$06,$E4,$F6,$E3,$F6
  DEFB $E3,$F6,$E3,$00,$00,$00,$41,$12
  DEFB $0C,$E4,$0C,$E4,$1C,$E4,$D6,$E3
  DEFB $D6,$E3,$D6,$E3,$DE,$E3,$20,$E4
  DEFB $0C,$E4,$00,$00,$00,$41,$12,$14
  DEFB $E4,$26,$E4,$26,$E4,$26,$E4,$26
  DEFB $E4,$26,$E4,$20,$E4,$0C,$E4,$0C
  DEFB $E4,$14,$E4,$00,$00,$00,$41,$12
  DEFB $14,$E4,$26,$E4,$26,$E4,$26,$E4
  DEFB $26,$E4,$26,$E4,$20,$E4,$0C,$E4
  DEFB $0C,$E4,$14,$E4,$00,$00,$00,$41
  DEFB $12,$14,$E4,$26,$E4,$26,$E4,$26
  DEFB $E4,$26,$E4,$26,$E4,$20,$E4,$0C
  DEFB $E4,$0C,$E4,$14,$E4,$00,$00,$00
  DEFB $41,$12,$14,$E4,$26,$E4,$26,$E4
  DEFB $26,$E4,$26,$E4,$26,$E4,$36,$E4
  DEFB $20,$E4,$0C,$E4,$1C,$E4,$D6,$E3
  DEFB $D6,$E3,$20,$E4,$10,$E4,$1C,$E4
  DEFB $D6,$E3,$D6,$E3,$00,$00,$F5,$01
  DEFB $22,$82,$E4,$64,$E4,$6C,$E4,$82
  DEFB $E4,$6E,$E4,$6E,$E4,$6E,$E4,$6E
  DEFB $E4,$86,$E4,$94,$E4,$B0,$E4,$86
  DEFB $E4,$76,$E4,$76,$E4,$76,$E4,$76
  DEFB $E4,$FF,$FF,$06,$42,$43,$CA,$E5
  DEFB $A2,$E5,$CA,$E5,$EA,$E5,$82,$E5
  DEFB $A2,$E5,$FA,$E5,$CA,$E5,$CA,$E5
  DEFB $CA,$E5,$A2,$E5,$82,$E5,$CA,$E5
  DEFB $EA,$E5,$A2,$E5,$CA,$E5,$00,$00
  DEFB $06,$42,$43,$CA,$E5,$A2,$E5,$CA
  DEFB $E5,$EA,$E5,$82,$E5,$A2,$E5,$CA
  DEFB $E5,$CA,$E5,$CA,$E5,$FA,$E5,$82
  DEFB $E5,$82,$E5,$82,$E5,$B2,$E5,$CA
  DEFB $E5,$CA,$E5,$CA,$E5,$FA,$E5,$82
  DEFB $E5,$82,$E5,$B2,$E5,$C2,$E5,$CA
  DEFB $E5,$CA,$E5,$EA,$E5,$92,$E5,$C2
  DEFB $E5,$CA,$E5,$EA,$E5,$00,$00,$06
  DEFB $42,$43,$CA,$E5,$A2,$E5,$CA,$E5
  DEFB $EA,$E5,$82,$E5,$A2,$E5,$CA,$E5
  DEFB $CA,$E5,$CA,$E5,$FA,$E5,$82,$E5
  DEFB $B2,$E5,$CA,$E5,$DA,$E5,$00,$00
  DEFB $06,$42,$43,$CA,$E5,$A2,$E5,$CA
  DEFB $E5,$EA,$E5,$92,$E5,$32,$E5,$CA
  DEFB $E5,$CA,$E5,$EA,$E5,$92,$E5,$EA
  DEFB $E5,$A2,$E5,$EA,$E5,$A2,$E5,$EA
  DEFB $E5,$A2,$E5,$EA,$E5,$A2,$E5,$EA
  DEFB $E5,$A2,$E5,$EA,$E5,$A2,$E5,$EA
  DEFB $E5,$A2,$E5,$EA,$E5,$A2,$E5,$EA
  DEFB $E5,$A2,$E5,$EA,$E5,$A2,$E5,$EA
  DEFB $E5,$A2,$E5,$EA,$E5,$A2,$E5,$EA
  DEFB $E5,$A2,$E5,$EA,$E5,$A2,$E5,$EA
  DEFB $E5,$A2,$E5,$EA,$E5,$A2,$E5,$EA
  DEFB $E5,$00,$00,$06,$42,$43,$CA,$E5
  DEFB $00,$00,$00,$42,$43,$3A,$E5,$12
  DEFB $E5,$3A,$E5,$5A,$E5,$F2,$E4,$22
  DEFB $E5,$32,$E5,$3A,$E5,$3A,$E5,$3A
  DEFB $E5,$7A,$E5,$F2,$E4,$3A,$E5,$22
  DEFB $E5,$32,$E5,$3A,$E5,$00,$00,$00
  DEFB $42,$43,$3A,$E5,$12,$E5,$3A,$E5
  DEFB $5A,$E5,$F2,$E4,$3A,$E5,$3A,$E5
  DEFB $4A,$E5,$02,$E5,$32,$E5,$3A,$E5
  DEFB $22,$E5,$32,$E5,$3A,$E5,$00,$00
  DEFB $00,$42,$43,$3A,$E5,$12,$E5,$3A
  DEFB $E5,$5A,$E5,$F2,$E4,$12,$E5,$32
  DEFB $E5,$3A,$E5,$3A,$E5,$3A,$E5,$5A
  DEFB $E5,$F2,$E4,$12,$E5,$3A,$E5,$3A
  DEFB $E5,$00,$00,$00,$42,$43,$3A,$E5
  DEFB $7A,$E5,$12,$E5,$32,$E5,$3A,$E5
  DEFB $4A,$E5,$7A,$E5,$02,$E5,$3A,$E5
  DEFB $3A,$E5,$7A,$E5,$12,$E5,$32,$E5
  DEFB $3A,$E5,$6A,$E5,$00,$00,$00,$42
  DEFB $43,$3A,$E5,$12,$E5,$3A,$E5,$5A
  DEFB $E5,$F2,$E4,$12,$E5,$32,$E5,$3A
  DEFB $E5,$3A,$E5,$3A,$E5,$5A,$E5,$F2
  DEFB $E4,$22,$E5,$3A,$E5,$3A,$E5,$00
  DEFB $00,$00,$42,$43,$3A,$E5,$12,$E5
  DEFB $3A,$E5,$5A,$E5,$F2,$E4,$12,$E5
  DEFB $32,$E5,$3A,$E5,$3A,$E5,$3A,$E5
  DEFB $F2,$E4,$F2,$E4,$12,$E5,$3A,$E5
  DEFB $3A,$E5,$5A,$E5,$F2,$E4,$F2,$E4
  DEFB $12,$E5,$3A,$E5,$3A,$E5,$5A,$E5
  DEFB $F2,$E4,$F2,$E4,$12,$E5,$3A,$E5
  DEFB $3A,$E5,$5A,$E5,$F2,$E4,$F2,$E4
  DEFB $12,$E5,$3A,$E5,$3A,$E5,$5A,$E5
  DEFB $00,$00,$00,$42,$43,$3A,$E5,$12
  DEFB $E5,$3A,$E5,$5A,$E5,$02,$E5,$32
  DEFB $E5,$3A,$E5,$3A,$E5,$5A,$E5,$7A
  DEFB $E5,$02,$E5,$32,$E5,$3A,$E5,$22
  DEFB $E5,$32,$E5,$3A,$E5,$00,$00,$00
  DEFB $42,$43,$3A,$E5,$12,$E5,$3A,$E5
  DEFB $5A,$E5,$02,$E5,$3A,$E5,$3A,$E5
  DEFB $6A,$E5,$02,$E5,$3A,$E5,$3A,$E5
  DEFB $00,$00,$00,$42,$43,$3A,$E5,$12
  DEFB $E5,$3A,$E5,$5A,$E5,$02,$E5,$3A
  DEFB $E5,$3A,$E5,$6A,$E5,$02,$E5,$3A
  DEFB $E5,$22,$E5,$32,$E5,$3A,$E5,$00
  DEFB $00,$00,$42,$43,$3A,$E5,$22,$E5
  DEFB $32,$E5,$3A,$E5,$7A,$E5,$22,$E5
  DEFB $32,$E5,$3A,$E5,$7A,$E5,$22,$E5
  DEFB $32,$E5,$3A,$E5,$7A,$E5,$22,$E5
  DEFB $32,$E5,$3A,$E5,$22,$E5,$32,$E5
  DEFB $3A,$E5,$00,$00,$00,$42,$43,$3A
  DEFB $E5,$12,$E5,$3A,$E5,$5A,$E5,$F2
  DEFB $E4,$32,$E5,$3A,$E5,$3A,$E5,$3A
  DEFB $E5,$F2,$E4,$3A,$E5,$22,$E5,$32
  DEFB $E5,$3A,$E5,$00,$00

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
