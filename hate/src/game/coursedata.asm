; The objects of round 1
;
; 16 records of 8 bytes, copied into the object slots $C0B0-$C1A0 at the round
; setup: +0 type, +1,+2 position along, +3 across, +4 height, +5 direction, +6
; speed, +7 behaviour bits (docs/07-objects.md 7.1-7.4). The course record of a
; round ($CF04, 4 bytes) points here: round 1 at $F300, then 128 bytes a round.
; docs/04-game-loop.md 4.2, docs/10-gameplay-logic.md 10.2.
RoundObjects1:
  DEFB $08,$CC,$01,$20,$06,$04,$01,$11
  DEFB $08,$DC,$01,$20,$0C,$04,$01,$11
  DEFB $08,$EC,$01,$20,$12,$04,$01,$11
  DEFB $0E,$4E,$02,$0C,$08,$04,$00,$48
  DEFB $03,$7C,$02,$0C,$12,$04,$00,$00
  DEFB $03,$F8,$02,$40,$0A,$04,$00,$00
  DEFB $03,$F8,$02,$32,$0A,$04,$00,$00
  DEFB $03,$AC,$03,$10,$0C,$04,$00,$00
  DEFB $08,$4C,$04,$1C,$14,$04,$02,$11
  DEFB $08,$5C,$04,$1C,$14,$04,$02,$11
  DEFB $08,$6C,$04,$1C,$14,$04,$02,$11
  DEFB $08,$7C,$04,$1C,$14,$04,$02,$11
  DEFB $08,$8C,$04,$1C,$14,$04,$02,$11
  DEFB $0E,$E2,$04,$04,$00,$04,$00,$48
  DEFB $0E,$84,$03,$40,$00,$04,$00,$18
  DEFB $0E,$48,$05,$3C,$08,$04,$00,$48

; The objects of round 2
RoundObjects2:
  DEFB $0E,$94,$01,$14,$00,$04,$00,$48
  DEFB $03,$D8,$01,$3C,$02,$04,$00,$00
  DEFB $03,$02,$02,$08,$02,$04,$00,$00
  DEFB $0E,$6C,$02,$3C,$08,$04,$00,$28
  DEFB $03,$12,$03,$2C,$12,$04,$00,$00
  DEFB $07,$34,$03,$40,$14,$04,$03,$11
  DEFB $07,$48,$03,$40,$14,$04,$03,$11
  DEFB $07,$5C,$03,$40,$14,$04,$03,$11
  DEFB $0E,$84,$03,$0C,$08,$04,$00,$18
  DEFB $03,$56,$04,$3C,$02,$04,$00,$00
  DEFB $07,$56,$04,$08,$02,$04,$03,$11
  DEFB $07,$6A,$04,$08,$02,$04,$03,$11
  DEFB $07,$7E,$04,$08,$02,$04,$03,$11
  DEFB $07,$92,$04,$08,$02,$04,$03,$11
  DEFB $07,$A6,$04,$08,$02,$04,$03,$11
  DEFB $0E,$16,$05,$2C,$08,$04,$00,$88

; The objects of round 3
RoundObjects3:
  DEFB $04,$A4,$01,$0C,$02,$02,$01,$22
  DEFB $04,$CC,$01,$04,$0A,$02,$01,$22
  DEFB $04,$F4,$01,$10,$02,$02,$01,$22
  DEFB $04,$1C,$02,$12,$08,$06,$01,$22
  DEFB $0E,$4E,$02,$08,$00,$04,$00,$28
  DEFB $0A,$F8,$02,$04,$08,$04,$00,$00
  DEFB $0A,$F8,$02,$14,$08,$04,$00,$00
  DEFB $0A,$F8,$02,$04,$16,$04,$00,$00
  DEFB $0A,$F8,$02,$14,$16,$04,$00,$00
  DEFB $0E,$4C,$03,$08,$00,$04,$00,$08
  DEFB $03,$98,$03,$02,$06,$04,$00,$00
  DEFB $03,$98,$03,$10,$06,$04,$00,$00
  DEFB $0E,$22,$04,$0C,$00,$04,$00,$18
  DEFB $03,$BA,$04,$20,$0C,$04,$00,$00
  DEFB $03,$54,$01,$1A,$0C,$04,$00,$00
  DEFB $0E,$32,$05,$3C,$10,$04,$00,$48

; The objects of round 4
RoundObjects4:
  DEFB $03,$5E,$01,$08,$02,$04,$00,$00
  DEFB $0E,$86,$01,$08,$00,$04,$00,$48
  DEFB $0E,$D6,$01,$38,$00,$04,$00,$48
  DEFB $0E,$26,$02,$08,$00,$04,$00,$48
  DEFB $03,$20,$03,$08,$02,$04,$00,$00
  DEFB $03,$7C,$02,$40,$06,$04,$00,$00
  DEFB $0E,$DA,$02,$40,$00,$04,$00,$28
  DEFB $0E,$A2,$03,$28,$08,$04,$00,$88
  DEFB $0E,$C2,$03,$28,$08,$04,$00,$18
  DEFB $03,$F4,$03,$28,$04,$04,$00,$00
  DEFB $0E,$74,$04,$04,$00,$04,$00,$48
  DEFB $0E,$9C,$04,$12,$00,$04,$00,$48
  DEFB $0E,$C4,$04,$20,$00,$04,$00,$48
  DEFB $0E,$EC,$04,$2E,$00,$04,$00,$48
  DEFB $0E,$14,$05,$04,$00,$04,$00,$48
  DEFB $0F,$4C,$04,$3C,$00,$04,$00,$00

; The objects of round 5
RoundObjects5:
  DEFB $03,$D4,$01,$1C,$0A,$04,$00,$00
  DEFB $08,$DC,$01,$0A,$14,$04,$04,$01
  DEFB $08,$E6,$01,$16,$14,$04,$04,$01
  DEFB $08,$F0,$01,$22,$14,$04,$04,$01
  DEFB $03,$14,$02,$0C,$16,$04,$00,$00
  DEFB $03,$CC,$02,$24,$0A,$04,$00,$00
  DEFB $02,$C4,$04,$0C,$0E,$04,$01,$11
  DEFB $02,$E2,$04,$02,$08,$04,$01,$11
  DEFB $02,$00,$05,$14,$14,$04,$01,$11
  DEFB $0E,$A4,$03,$30,$08,$04,$00,$88
  DEFB $0E,$A4,$03,$18,$08,$04,$00,$88
  DEFB $08,$FA,$01,$2E,$14,$04,$04,$01
  DEFB $03,$50,$02,$34,$16,$04,$00,$00
  DEFB $0E,$24,$05,$0A,$00,$04,$00,$18
  DEFB $0F,$A4,$02,$24,$08,$04,$00,$00
  DEFB $08,$04,$02,$3C,$14,$04,$04,$01

; The objects of round 6
RoundObjects6:
  DEFB $03,$54,$01,$12,$02,$04,$00,$00
  DEFB $03,$68,$01,$12,$02,$04,$00,$00
  DEFB $0E,$D2,$01,$0C,$00,$04,$00,$48
  DEFB $03,$EC,$01,$0C,$02,$04,$00,$00
  DEFB $0A,$74,$02,$04,$04,$04,$00,$00
  DEFB $0A,$74,$02,$14,$04,$04,$00,$00
  DEFB $0A,$84,$02,$04,$04,$04,$00,$00
  DEFB $0A,$84,$02,$14,$04,$04,$00,$00
  DEFB $0A,$94,$02,$04,$04,$04,$00,$00
  DEFB $0A,$94,$02,$14,$04,$04,$00,$00
  DEFB $0F,$10,$03,$0A,$00,$04,$00,$00
  DEFB $0E,$72,$03,$10,$00,$04,$00,$48
  DEFB $03,$92,$03,$10,$02,$04,$00,$00
  DEFB $0E,$00,$04,$40,$08,$04,$00,$28
  DEFB $0E,$CE,$04,$40,$08,$04,$00,$88
  DEFB $0E,$3E,$05,$06,$08,$04,$00,$88

; The objects of round 7
RoundObjects7:
  DEFB $03,$20,$02,$32,$14,$04,$00,$00
  DEFB $02,$D2,$01,$10,$14,$04,$01,$19
  DEFB $02,$14,$02,$10,$14,$04,$01,$19
  DEFB $03,$44,$02,$32,$14,$04,$00,$00
  DEFB $0E,$CE,$02,$3C,$10,$04,$00,$48
  DEFB $0E,$CE,$02,$28,$10,$04,$00,$48
  DEFB $0E,$20,$03,$06,$10,$04,$00,$48
  DEFB $0E,$20,$03,$1A,$10,$04,$00,$48
  DEFB $03,$A2,$03,$3E,$08,$04,$00,$00
  DEFB $03,$B6,$03,$06,$08,$04,$00,$00
  DEFB $0E,$E8,$03,$3C,$00,$04,$00,$18
  DEFB $0E,$FE,$03,$3C,$00,$04,$00,$18
  DEFB $0E,$72,$04,$28,$08,$04,$00,$88
  DEFB $02,$C4,$04,$10,$14,$04,$01,$19
  DEFB $02,$0A,$05,$24,$14,$04,$01,$19
  DEFB $02,$50,$05,$30,$14,$04,$01,$19

; The objects of round 8
RoundObjects8:
  DEFB $03,$90,$01,$08,$02,$04,$00,$00
  DEFB $0E,$90,$01,$18,$00,$04,$00,$08
  DEFB $03,$3A,$02,$3C,$0A,$04,$00,$00
  DEFB $03,$76,$02,$3C,$0A,$04,$00,$00
  DEFB $0E,$BE,$02,$0E,$08,$04,$00,$88
  DEFB $0E,$10,$03,$0E,$08,$04,$00,$88
  DEFB $06,$84,$03,$22,$02,$04,$04,$81
  DEFB $06,$AC,$03,$0A,$02,$04,$04,$81
  DEFB $03,$E8,$03,$32,$04,$04,$00,$00
  DEFB $0E,$4C,$04,$20,$00,$04,$00,$48
  DEFB $0E,$74,$04,$20,$00,$04,$00,$48
  DEFB $0E,$BA,$04,$20,$00,$04,$00,$48
  DEFB $0E,$E2,$04,$20,$00,$04,$00,$48
  DEFB $0E,$14,$05,$20,$00,$04,$00,$48
  DEFB $0E,$50,$05,$3C,$00,$04,$00,$28
  DEFB $06,$5C,$03,$04,$02,$04,$04,$81

; The objects of round 9
RoundObjects9:
  DEFB $02,$E0,$01,$20,$16,$04,$03,$89
  DEFB $02,$08,$02,$30,$14,$04,$03,$89
  DEFB $03,$2C,$02,$0E,$08,$04,$00,$00
  DEFB $03,$80,$02,$34,$0C,$04,$00,$00
  DEFB $0E,$E4,$02,$30,$10,$04,$00,$88
  DEFB $0E,$02,$03,$30,$10,$04,$00,$88
  DEFB $03,$48,$03,$30,$14,$04,$00,$00
  DEFB $02,$E8,$03,$32,$14,$04,$02,$89
  DEFB $02,$E8,$03,$0A,$14,$04,$02,$89
  DEFB $0E,$42,$04,$38,$08,$04,$00,$48
  DEFB $0E,$50,$04,$24,$08,$04,$00,$48
  DEFB $0E,$5E,$04,$10,$08,$04,$00,$48
  DEFB $03,$92,$04,$24,$12,$04,$00,$00
  DEFB $0E,$00,$05,$3C,$00,$04,$00,$88
  DEFB $0E,$00,$05,$24,$00,$04,$00,$88
  DEFB $0E,$00,$05,$0C,$00,$04,$00,$88

; The objects of round 10
RoundObjects10:
  DEFB $0E,$A4,$01,$20,$00,$04,$00,$08
  DEFB $0E,$F4,$01,$20,$00,$04,$00,$08
  DEFB $03,$44,$02,$06,$02,$04,$00,$00
  DEFB $0E,$94,$02,$06,$00,$04,$00,$08
  DEFB $0E,$E4,$02,$06,$00,$04,$00,$08
  DEFB $03,$34,$03,$20,$02,$04,$00,$00
  DEFB $03,$FC,$03,$0C,$02,$04,$00,$08
  DEFB $0F,$38,$04,$04,$00,$04,$00,$00
  DEFB $0F,$60,$04,$14,$00,$04,$00,$00
  DEFB $0A,$2E,$04,$14,$02,$04,$00,$00
  DEFB $0A,$42,$04,$14,$02,$04,$00,$00
  DEFB $0A,$56,$04,$04,$02,$04,$00,$00
  DEFB $0A,$6A,$04,$04,$02,$04,$00,$00
  DEFB $03,$9C,$04,$0C,$02,$04,$00,$00
  DEFB $0E,$0A,$05,$1C,$00,$04,$00,$88
  DEFB $0E,$50,$05,$1C,$00,$04,$00,$88

; The strips under the sprites, saved
;
; $D9D6 starts the pointer $DD6A at $F800 each pass and $DD47 copies the buffer
; strips under each sprite here before the sprites are drawn; $DDC9 puts them
; back. Nothing in the image here is read before it is written: a fill pattern
; ($FA,$FC) and, toward the end, bytes that look like Z80 code that never ran.
; docs/06-rendering.md 6.6.
SpriteSaveBuffer:
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC,$FA,$FC
  DEFB $FA,$69,$FA,$00,$00,$FC,$FA,$69,$FA,$FC,$FA,$69,$FA,$FC,$FA,$2C
  DEFB $F2,$01,$42,$AC,$FF,$DF,$FB,$49,$FC,$A8,$61,$5B,$F5,$40,$9A,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$B0,$C9,$21,$61,$FC,$11,$60,$FC,$01,$61,$A1
  DEFB $AF,$77,$ED,$B8,$FD,$21,$78,$FE,$1E,$E0,$FD,$6E,$00,$CB,$7D,$20
  DEFB $1D,$26,$00,$01,$00,$3C,$29,$29,$29,$09,$16,$50,$06,$08,$7E,$12
  DEFB $14,$23,$10,$FA,$16,$5A,$3E,$C7,$12,$1C,$FD,$23,$18,$DC,$3E,$00
  DEFB $32,$48,$5C,$06,$E0,$C5,$11,$05,$00,$21,$6A,$06,$CD,$B5,$03,$1E
  DEFB $04,$21,$05,$04,$CD,$B5,$03,$C1,$10,$EB,$C7,$7B,$FF,$4F,$4F,$F3
  DEFB $DD,$21,$4B,$FE,$2A,$49,$FE,$DD,$7E,$03,$07,$07,$07,$E6,$07,$3C
  DEFB $4F,$57,$D9,$DD,$6E,$00,$DD,$66,$01,$DD,$46,$02,$78,$E6,$3F,$5F
  DEFB $DD,$7E,$03,$E6,$1F,$87,$87,$87,$57,$78,$01,$04,$00,$DD,$09,$07
  DEFB $07,$E6,$03,$FD,$67,$43,$4D,$FE,$02,$30,$05,$FD,$6A,$42,$4D,$54
  DEFB $3C,$CD,$D3,$FD,$D9,$2B,$15,$20,$C9,$06,$00,$51,$7A,$D9,$CD,$1B
  DEFB $FD,$CD,$D3,$FD,$D9,$B0,$47,$15,$20,$F2,$78,$B7,$20,$EB,$7C,$B5
  DEFB $20,$A5,$FD,$21,$3A,$5C,$21,$58,$27,$D9,$C9,$CD,$C6,$FD,$ED,$73
  DEFB $2A,$FD,$F9,$F1,$E1,$D1,$C1,$FD,$E1,$31,$FF,$C3,$B7,$C8,$FD,$7C
  DEFB $FE,$02,$30,$1C,$CD,$9D,$FD,$CD,$B7,$FD,$CD,$84,$FD,$3E,$FF,$05
  DEFB $C0,$69,$62,$CD,$69,$FD,$4D,$54,$FD,$45,$3E,$FF,$1D,$C0,$3C,$C9
  DEFB $CD,$9D,$FD,$CD,$B7,$FD,$CD,$69,$FD,$3E,$FF,$05,$C0,$43,$69,$CD
  DEFB $84,$FD,$4D,$3E,$FF,$15,$C0,$3C,$C9,$FD,$7C,$B7,$EA,$71,$FD,$2D
  DEFB $C9,$2C,$C9,$24,$7C,$E6,$07,$C0,$7D,$C6,$20,$6F,$E6,$E0,$C8,$7C
  DEFB $D6,$08,$67,$C9,$FD,$7C,$B7,$EA,$73,$FD,$25,$7C,$2F,$E6,$07,$C0
  DEFB $7D,$D6,$20,$6F,$2F,$E6,$E0,$C8,$7C,$C6,$08,$67,$C9,$FD,$7C,$B7
  DEFB $7C,$EA,$A5,$FD,$2F,$E6,$07,$C0,$E5,$7C,$1F,$1F,$1F,$E6,$03,$F6
  DEFB $58,$67,$CD,$B7,$FD,$E1,$C9,$D5,$EB,$2A,$47,$FE,$73,$23,$72,$23
  DEFB $22,$47,$FE,$EB,$D1,$C9,$6F,$26,$00,$87,$87,$85,$87,$6F,$01,$ED
  DEFB $FD,$09,$C9,$E5,$C5,$F5,$D9,$7A,$D9,$CD,$C6,$FD,$01,$0A,$00,$09
  DEFB $22,$EB,$FD,$F1,$C1,$E1,$ED,$73,$F4,$FD,$31,$01,$FE,$FD,$E5,$C5
  DEFB $D5,$E5,$F5,$31,$FF,$C3,$C9,$50,$00,$00,$58,$20,$00

; The IM 2 jump
;
; Every interrupt vector of the table $FE00-$FF00 is $FDFD. The start-up $9F4B
; writes JP $9F68 here (EI; RET) and the title player $803A writes JP $8340,
; its handler; the image holds the latter. The game proper runs with interrupts
; off. docs/02-architecture.md 2.3-2.4.
Im2Jump:
  JP TitleInterrupt

; The IM 2 vector table, then the shadow list
;
; During the title, $9F4B fills $FE00-$FF00 with $FD and sets I = $FE, so any
; bus value gives the vector $FDFD. In play the table is no longer needed and
; $D9D6 builds the shadow list at $FE64 in it (8 bytes an object), drawn by
; $DDE7 before the blit. docs/02-architecture.md 2.3, docs/06-rendering.md 6.6.
Im2Table:
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD

; The depth list and the sprite list, then the stack
;
; $FF00 holds the depth list of $EFA5 (4 bytes an entry) and then, rebuilt by
; $D9D6 each pass, the sprite list drawn by $EAE3 (6 bytes an entry); its first
; byte is also the last vector byte of the IM 2 table. The stack grows down
; from $FFFF (SP = $FFFF at the entry, $61A8). The bytes in the image up to
; $FF57 are leftovers. docs/02-architecture.md 2.2.
SpriteListArea:
  DEFB $FD,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$F3,$0D,$CE,$0B,$E4,$50,$CE,$0B
  DEFB $E5,$50,$1C,$17,$DC,$0A,$CE,$0B,$EB,$50,$16,$17,$DC,$0A,$D7,$18
  DEFB $B1,$33,$DE,$5C,$05,$00,$DB,$02,$4D,$00,$5B,$56,$A5,$00,$5A,$56
  DEFB $8C,$08,$5C,$0E,$00,$47,$C0,$57,$71,$0E,$F3,$0D,$21,$17,$C6,$1E
  DEFB $EB,$5E,$76,$1B,$03,$13,$00,$3E

; The 48K BASIC's user-defined graphics, left in the image
;
; $FF58-$FFFF is where the Spectrum ROM keeps the UDGs, set up as copies of the
; letters A-U; the bytes are those copies, left from BASIC. The game never
; reads them; the top of the stack overwrites the last ones.
UdgLeftover:
  DEFB $00,$3C,$42,$42,$7E,$42,$42,$00
  DEFB $00,$7C,$42,$7C,$42,$42,$7C,$00
  DEFB $00,$3C,$42,$40,$40,$42,$3C,$00
  DEFB $00,$78,$44,$42,$42,$44,$78,$00
  DEFB $00,$7E,$40,$7C,$40,$40,$7E,$00
  DEFB $00,$7E,$40,$7C,$40,$40,$40,$00
  DEFB $00,$3C,$42,$40,$4E,$42,$3C,$00
  DEFB $00,$42,$42,$7E,$42,$42,$42,$00
  DEFB $00,$3E,$08,$08,$08,$08,$3E,$00
  DEFB $00,$02,$02,$02,$42,$42,$3C,$00
  DEFB $00,$44,$48,$70,$48,$44,$42,$00
  DEFB $00,$40,$40,$40,$40,$40,$7E,$00
  DEFB $00,$42,$66,$5A,$42,$42,$42,$00
  DEFB $00,$42,$62,$52,$4A,$46,$42,$00
  DEFB $00,$3C,$42,$42,$42,$42,$3C,$00
  DEFB $00,$7C,$42,$42,$7C,$40,$40,$00
  DEFB $00,$3C,$42,$42,$52,$4A,$3C,$00
  DEFB $00,$7C,$42,$42,$7C,$44,$42,$00
  DEFB $00,$3C,$40,$3C,$02,$42,$3C,$00
  DEFB $00,$FE,$10,$10,$10,$10,$10,$00
  DEFB $00,$42,$42,$42,$42,$42,$3C,$00
