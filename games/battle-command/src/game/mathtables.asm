; --------------------------------------------------------------------------------------------------------------------
; mathtables.asm: The 3D engine's tables in bank 5: logarithms, squares, sines, screen rows, fill patterns, work lists
;
; Read-only tables at $5C00-$66FF built into the bank 5 block, and the 3D work lists at $6680-$674F. The divide is
; done with logarithms ($5C00-$5EFF), the signed multiply with quarter squares ($5F00-$60FF), the rotations with three
; sine tables ($6100-$64FF). $6500 is the screen row table the view blits use. Witness: the L1 read ranges of the
; routines named in each entry (play, play2, missions, death).
; --------------------------------------------------------------------------------------------------------------------

; log2 fractions: byte n = 256 * frac(log2 n), n = 1..255
;
; 256 bytes in octave runs: `$5C01`, `$5C02-$5C03`, `$5C04-$5C07`, ...
; `$5C80-$5CFF` (n = 128..255: `$00 $03 $06 ... $FF`). `$5C00` is 0 (log of 0
; is not taken). With LogInteger, log2 n = `$5D00`[n] + `$5C00`[n] / 256 in
; 8.8.
;
; Readers: Divide `$A687` / DivideByLog `$A6D2` (`LD H,$5C` / `INC H`), bank 3
; `$C959` (the polygon slopes). L1 play: `$A6D2` reads `$5C00-$5EFF`.
LogFraction:
  DEFB $00,$00,$00,$96,$00,$52,$96,$CF,$00,$2C,$52,$76,$96,$B3,$CF,$E8,$00,$16,$2C,$3F,$52,$64,$76,$86,$96,$A5,$B3,$C1,$CF,$DC,$E8,$F4
  DEFB $00,$0B,$16,$21,$2C,$36,$3F,$49,$52,$5C,$64,$6D,$76,$7E,$86,$8E,$96,$9D,$A5,$AC,$B3,$BA,$C1,$C8,$CF,$D5,$DC,$E2,$E8,$EE,$F4,$FA
  DEFB $00,$06,$0B,$11,$16,$1C,$21,$26,$2C,$31,$36,$3B,$3F,$44,$49,$4E,$52,$57,$5C,$60,$64,$69,$6D,$71,$76,$7A,$7E,$82,$86,$8A,$8E,$92
  DEFB $96,$9A,$9D,$A1,$A5,$A9,$AC,$B0,$B3,$B7,$BA,$BE,$C1,$C5,$C8,$CB,$CF,$D2,$D5,$D8,$DC,$DF,$E2,$E5,$E8,$EB,$EE,$F1,$F4,$F7,$FA,$FD
  DEFB $00,$03,$06,$09,$0B,$0E,$11,$14,$16,$19,$1C,$1E,$21,$24,$26,$29,$2C,$2E,$31,$33,$36,$38,$3B,$3D,$3F,$42,$44,$47,$49,$4B,$4E,$50
  DEFB $52,$55,$57,$59,$5C,$5E,$60,$62,$64,$67,$69,$6B,$6D,$6F,$71,$74,$76,$78,$7A,$7C,$7E,$80,$82,$84,$86,$88,$8A,$8C,$8E,$90,$92,$94
  DEFB $96,$98,$9A,$9B,$9D,$9F,$A1,$A3,$A5,$A7,$A9,$AA,$AC,$AE,$B0,$B2,$B3,$B5,$B7,$B9,$BA,$BC,$BE,$C0,$C1,$C3,$C5,$C6,$C8,$CA,$CB,$CD
  DEFB $CF,$D0,$D2,$D4,$D5,$D7,$D8,$DA,$DC,$DD,$DF,$E0,$E2,$E4,$E5,$E7,$E8,$EA,$EB,$ED,$EE,$F0,$F1,$F3,$F4,$F6,$F7,$F9,$FA,$FC,$FD,$FF

; log2 integer parts: byte n = floor(log2 n); `$5D00` = `$F0`
;
; 256 bytes: 0 for n = 1, 1 for 2-3, 2 for 4-7, ... 7 for 128-255; byte 0 is
; `$F0` (a large negative log, so a zero numerator gives a zero quotient). Read
; beside LogFraction by `$A687`, `$A6D2`, bank 3 `$C959`.
LogInteger:
  DEFB $F0,$00,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03,$03,$03,$03,$03,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04,$04
  DEFB $05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05,$05
  DEFB $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
  DEFB $06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07
  DEFB $07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07,$07

; Antilogs: byte n = 256 * (2^(n / 256) - 1)
;
; 256 bytes `$00 $01 $01 $02 ... $FD $FF`: the 8-bit mantissa of 2^(n/256),
; with an implied leading 1 (`LD H,$01` after the lookup). Readers: DivideByLog
; `$A6D2` (`LD H,$5E`), bank 3 `$C959`.
ExpFraction:
  DEFB $00,$01,$01,$02,$03,$03,$04,$05,$06,$06,$07,$08,$08,$09,$0A,$0B,$0B,$0C,$0D,$0E,$0E,$0F,$10,$10,$11,$12,$13,$13,$14,$15,$16,$16
  DEFB $17,$18,$19,$19,$1A,$1B,$1C,$1D,$1D,$1E,$1F,$20,$20,$21,$22,$23,$24,$24,$25,$26,$27,$28,$28,$29,$2A,$2B,$2C,$2C,$2D,$2E,$2F,$30
  DEFB $30,$31,$32,$33,$34,$35,$35,$36,$37,$38,$39,$3A,$3A,$3B,$3C,$3D,$3E,$3F,$40,$41,$41,$42,$43,$44,$45,$46,$47,$48,$48,$49,$4A,$4B
  DEFB $4C,$4D,$4E,$4F,$50,$51,$51,$52,$53,$54,$55,$56,$57,$58,$59,$5A,$5B,$5C,$5D,$5E,$5E,$5F,$60,$61,$62,$63,$64,$65,$66,$67,$68,$69
  DEFB $6A,$6B,$6C,$6D,$6E,$6F,$70,$71,$72,$73,$74,$75,$76,$77,$78,$79,$7A,$7B,$7C,$7D,$7E,$7F,$80,$81,$82,$83,$84,$85,$87,$88,$89,$8A
  DEFB $8B,$8C,$8D,$8E,$8F,$90,$91,$92,$93,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9F,$A0,$A1,$A2,$A3,$A4,$A5,$A6,$A8,$A9,$AA,$AB,$AC,$AD
  DEFB $AF,$B0,$B1,$B2,$B3,$B4,$B6,$B7,$B8,$B9,$BA,$BC,$BD,$BE,$BF,$C0,$C2,$C3,$C4,$C5,$C6,$C8,$C9,$CA,$CB,$CD,$CE,$CF,$D0,$D2,$D3,$D4
  DEFB $D6,$D7,$D8,$D9,$DB,$DC,$DD,$DE,$E0,$E1,$E2,$E4,$E5,$E6,$E8,$E9,$EA,$EC,$ED,$EE,$F0,$F1,$F2,$F4,$F5,$F6,$F8,$F9,$FA,$FC,$FD,$FF

; Squares of the signed bytes, low bytes: `$5F00`[i] = low(i*i), i = -128..127
; as a byte
;
; With SquareHigh the 16-bit square of the signed byte i: `$5F00`+i low,
; `$6000`+i high (i = `$81` gives 127 squared, i = `$80` 128 squared). Readers:
; the quarter-square multiplies MulSigned `$A7BF`, MulFrac `$A7F2`, MulWordByte
; `$A82C` (L1 play: `$5F00-$60FF`).
SquareLow:
  DEFB $00,$01,$04,$09,$10,$19,$24,$31,$40,$51,$64,$79,$90,$A9,$C4,$E1
  DEFB $00,$21,$44,$69,$90,$B9,$E4,$11,$40,$71,$A4,$D9,$10,$49,$84,$C1
  DEFB $00,$41,$84,$C9,$10,$59,$A4,$F1,$40,$91,$E4,$39,$90,$E9,$44,$A1
  DEFB $00,$61,$C4,$29,$90,$F9,$64,$D1,$40,$B1,$24,$99,$10,$89,$04,$81
  DEFB $00,$81,$04,$89,$10,$99,$24,$B1,$40,$D1,$64,$F9,$90,$29,$C4,$61
  DEFB $00,$A1,$44,$E9,$90,$39,$E4,$91,$40,$F1,$A4,$59,$10,$C9,$84,$41
  DEFB $00,$C1,$84,$49,$10,$D9,$A4,$71,$40,$11,$E4,$B9,$90,$69,$44,$21
  DEFB $00,$E1,$C4,$A9,$90,$79,$64,$51,$40,$31,$24,$19,$10,$09,$04,$01
  DEFB $00,$01,$04,$09,$10,$19,$24,$31,$40,$51,$64,$79,$90,$A9,$C4,$E1
  DEFB $00,$21,$44,$69,$90,$B9,$E4,$11,$40,$71,$A4,$D9,$10,$49,$84,$C1
  DEFB $00,$41,$84,$C9,$10,$59,$A4,$F1,$40,$91,$E4,$39,$90,$E9,$44,$A1
  DEFB $00,$61,$C4,$29,$90,$F9,$64,$D1,$40,$B1,$24,$99,$10,$89,$04,$81
  DEFB $00,$81,$04,$89,$10,$99,$24,$B1,$40,$D1,$64,$F9,$90,$29,$C4,$61
  DEFB $00,$A1,$44,$E9,$90,$39,$E4,$91,$40,$F1,$A4,$59,$10,$C9,$84,$41
  DEFB $00,$C1,$84,$49,$10,$D9,$A4,$71,$40,$11,$E4,$B9,$90,$69,$44,$21
  DEFB $00,$E1,$C4,$A9,$90,$79,$64,$51,$40,$31,$24,$19,$10,$09,$04,$01

; Squares of the signed bytes, high bytes: `$6000`[i] = high(i*i)
;
; Rises `$00`..`$3F` for i = 0..127, `$40` at i = `$80`, falls back for i =
; `$81`..`$FF` (the squares of -127..-1).
SquareHigh:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03,$03,$03,$03
  DEFB $04,$04,$04,$04,$05,$05,$05,$05,$06,$06,$06,$07,$07,$07,$08,$08
  DEFB $09,$09,$09,$0A,$0A,$0A,$0B,$0B,$0C,$0C,$0D,$0D,$0E,$0E,$0F,$0F
  DEFB $10,$10,$11,$11,$12,$12,$13,$13,$14,$14,$15,$15,$16,$17,$17,$18
  DEFB $19,$19,$1A,$1A,$1B,$1C,$1C,$1D,$1E,$1E,$1F,$20,$21,$21,$22,$23
  DEFB $24,$24,$25,$26,$27,$27,$28,$29,$2A,$2B,$2B,$2C,$2D,$2E,$2F,$30
  DEFB $31,$31,$32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F
  DEFB $40,$3F,$3E,$3D,$3C,$3B,$3A,$39,$38,$37,$36,$35,$34,$33,$32,$31
  DEFB $31,$30,$2F,$2E,$2D,$2C,$2B,$2B,$2A,$29,$28,$27,$27,$26,$25,$24
  DEFB $24,$23,$22,$21,$21,$20,$1F,$1E,$1E,$1D,$1C,$1C,$1B,$1A,$1A,$19
  DEFB $19,$18,$17,$17,$16,$15,$15,$14,$14,$13,$13,$12,$12,$11,$11,$10
  DEFB $10,$0F,$0F,$0E,$0E,$0D,$0D,$0C,$0C,$0B,$0B,$0A,$0A,$0A,$09,$09
  DEFB $09,$08,$08,$07,$07,$07,$06,$06,$06,$05,$05,$05,$05,$04,$04,$04
  DEFB $04,$03,$03,$03,$03,$02,$02,$02,$02,$02,$01,$01,$01,$01,$01,$01
  DEFB $01,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Sine, 16 bits, low bytes: sin(2 pi n / 256) * `$2000`
;
; 256 entries, low byte here and high byte at Sine16High `$6200`
; (`$6140`/`$6240` = `$2000`, `$61C0`/`$62C0` = `$E000`). Read by SinCos16
; `$A8A5` (the 16-bit box BoxRect16 `$AAF5`).
Sine16Low:
  DEFB $00,$C9,$92,$5A,$23,$EB,$B2,$78,$3E,$03,$C6,$89,$4A,$09,$C8,$84
  DEFB $3F,$F7,$AE,$63,$15,$C6,$73,$1E,$C7,$6D,$10,$B0,$4D,$E7,$7D,$10
  DEFB $A0,$2D,$B6,$3B,$BC,$3A,$B4,$29,$9B,$09,$72,$D8,$38,$95,$ED,$41
  DEFB $90,$DB,$21,$62,$9F,$D7,$0A,$39,$62,$87,$A7,$C2,$D8,$EA,$F6,$FD
  DEFB $00,$FD,$F6,$EA,$D8,$C2,$A7,$87,$62,$39,$0A,$D7,$9F,$62,$21,$DB
  DEFB $90,$41,$ED,$95,$38,$D8,$72,$09,$9B,$29,$B4,$3A,$BC,$3B,$B6,$2D
  DEFB $A0,$10,$7D,$E7,$4D,$B0,$10,$6D,$C7,$1E,$73,$C6,$15,$63,$AE,$F7
  DEFB $3F,$84,$C8,$09,$4A,$89,$C6,$03,$3E,$78,$B2,$EB,$23,$5A,$92,$C9
  DEFB $00,$37,$6E,$A5,$DD,$15,$4E,$87,$C2,$FD,$39,$77,$B6,$F6,$38,$7B
  DEFB $C1,$08,$51,$9D,$EA,$3A,$8C,$E1,$39,$93,$F0,$50,$B3,$19,$82,$EF
  DEFB $5F,$D3,$4A,$C5,$43,$C6,$4C,$D6,$64,$F7,$8D,$28,$C7,$6A,$12,$BF
  DEFB $6F,$25,$DF,$9D,$60,$28,$F5,$C7,$9D,$78,$58,$3D,$27,$16,$0A,$02
  DEFB $00,$02,$0A,$16,$27,$3D,$58,$78,$9D,$C7,$F5,$28,$60,$9D,$DF,$25
  DEFB $6F,$BF,$12,$6A,$C7,$28,$8D,$F7,$64,$D6,$4C,$C6,$43,$C5,$4A,$D3
  DEFB $5F,$EF,$82,$19,$B3,$50,$F0,$93,$39,$E1,$8C,$3A,$EA,$9D,$51,$08
  DEFB $C1,$7B,$38,$F6,$B6,$77,$39,$FD,$C2,$87,$4E,$15,$DD,$A5,$6E,$37

; Sine, 16 bits, high bytes
;
; See Sine16Low `$6100`.
Sine16High:
  DEFB $00,$00,$01,$02,$03,$03,$04,$05,$06,$07,$07,$08,$09,$0A,$0A,$0B
  DEFB $0C,$0C,$0D,$0E,$0F,$0F,$10,$11,$11,$12,$13,$13,$14,$14,$15,$16
  DEFB $16,$17,$17,$18,$18,$19,$19,$1A,$1A,$1B,$1B,$1B,$1C,$1C,$1C,$1D
  DEFB $1D,$1D,$1E,$1E,$1E,$1E,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F
  DEFB $20,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1F,$1E,$1E,$1E,$1E,$1D
  DEFB $1D,$1D,$1C,$1C,$1C,$1B,$1B,$1B,$1A,$1A,$19,$19,$18,$18,$17,$17
  DEFB $16,$16,$15,$14,$14,$13,$13,$12,$11,$11,$10,$0F,$0F,$0E,$0D,$0C
  DEFB $0C,$0B,$0A,$0A,$09,$08,$07,$07,$06,$05,$04,$03,$03,$02,$01,$00
  DEFB $00,$FF,$FE,$FD,$FC,$FC,$FB,$FA,$F9,$F8,$F8,$F7,$F6,$F5,$F5,$F4
  DEFB $F3,$F3,$F2,$F1,$F0,$F0,$EF,$EE,$EE,$ED,$EC,$EC,$EB,$EB,$EA,$E9
  DEFB $E9,$E8,$E8,$E7,$E7,$E6,$E6,$E5,$E5,$E4,$E4,$E4,$E3,$E3,$E3,$E2
  DEFB $E2,$E2,$E1,$E1,$E1,$E1,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0
  DEFB $E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E0,$E1,$E1,$E1,$E1,$E2
  DEFB $E2,$E2,$E3,$E3,$E3,$E4,$E4,$E4,$E5,$E5,$E6,$E6,$E7,$E7,$E8,$E8
  DEFB $E9,$E9,$EA,$EB,$EB,$EC,$EC,$ED,$EE,$EE,$EF,$F0,$F0,$F1,$F2,$F3
  DEFB $F3,$F4,$F5,$F5,$F6,$F7,$F8,$F8,$F9,$FA,$FB,$FC,$FC,$FD,$FE,$FF

; Sine, 8 bits: sin(2 pi n / 256) * 127, signed
;
; 256 bytes `$00 $03 $06 ... $7F ... $81 ...`; the cosine is the entry n +
; `$40`. Readers: SinCos8 `$A899` (the mission vector `$67E8`), the boxes
; `$AA63`, `$AB7B`, `$ABFF`, the polar points `$A119`, SinCosHalf `$A8B2`.
Sine8:
  DEFB $00,$03,$06,$09,$0D,$10,$13,$16,$19,$1C,$1F,$22,$25,$28,$2B,$2E
  DEFB $31,$34,$37,$3A,$3C,$3F,$42,$44,$47,$4A,$4C,$4F,$51,$54,$56,$58
  DEFB $5B,$5D,$5F,$61,$63,$65,$67,$69,$6A,$6C,$6E,$6F,$71,$72,$74,$75
  DEFB $76,$77,$79,$7A,$7A,$7B,$7C,$7D,$7E,$7E,$7F,$7F,$7F,$7F,$7F,$7F
  DEFB $7F,$7F,$7F,$7F,$7F,$7F,$7F,$7E,$7E,$7D,$7C,$7B,$7A,$7A,$79,$77
  DEFB $76,$75,$74,$72,$71,$6F,$6E,$6C,$6A,$69,$67,$65,$63,$61,$5F,$5D
  DEFB $5B,$58,$56,$54,$51,$4F,$4C,$4A,$47,$44,$42,$3F,$3C,$3A,$37,$34
  DEFB $31,$2E,$2B,$28,$25,$22,$1F,$1C,$19,$16,$13,$10,$0D,$09,$06,$03
  DEFB $00,$FD,$FA,$F7,$F3,$F0,$ED,$EA,$E7,$E4,$E1,$DE,$DB,$D8,$D5,$D2
  DEFB $CF,$CC,$C9,$C6,$C4,$C1,$BE,$BC,$B9,$B6,$B4,$B1,$AF,$AC,$AA,$A8
  DEFB $A5,$A3,$A1,$9F,$9D,$9B,$99,$97,$96,$94,$92,$91,$8F,$8E,$8C,$8B
  DEFB $8A,$89,$87,$86,$86,$85,$84,$83,$82,$82,$81,$81,$81,$81,$81,$81
  DEFB $81,$81,$81,$81,$81,$81,$81,$82,$82,$83,$84,$85,$86,$86,$87,$89
  DEFB $8A,$8B,$8C,$8E,$8F,$91,$92,$94,$96,$97,$99,$9B,$9D,$9F,$A1,$A3
  DEFB $A5,$A8,$AA,$AC,$AF,$B1,$B4,$B6,$B9,$BC,$BE,$C1,$C4,$C6,$C9,$CC
  DEFB $CF,$D2,$D5,$D8,$DB,$DE,$E1,$E4,$E7,$EA,$ED,$F0,$F3,$F7,$FA,$FD

; Sine, 8 bits, half a step on: sin(2 pi (n + 0.5) / 256) * 127
;
; 256 bytes `$02 $05 $08 ...`. Read only by SinCosHalf `$A8B2` when the angle
; word has its half-step bit (bit 7 of L) set; no recording reads it (known
; only from the code).
Sine8Half:
  DEFB $02,$05,$08,$0B,$0E,$11,$14,$17,$1B,$1E,$21,$24,$27,$2A,$2D,$30
  DEFB $32,$35,$38,$3B,$3E,$40,$43,$46,$48,$4B,$4E,$50,$52,$55,$57,$59
  DEFB $5C,$5E,$60,$62,$64,$66,$68,$6A,$6B,$6D,$6F,$70,$72,$73,$74,$76
  DEFB $77,$78,$79,$7A,$7B,$7C,$7D,$7D,$7E,$7E,$7F,$7F,$7F,$7F,$7F,$7F
  DEFB $7F,$7F,$7F,$7F,$7F,$7F,$7E,$7E,$7D,$7D,$7C,$7B,$7A,$79,$78,$77
  DEFB $76,$74,$73,$72,$70,$6F,$6D,$6B,$6A,$68,$66,$64,$62,$60,$5E,$5C
  DEFB $59,$57,$55,$52,$50,$4E,$4B,$48,$46,$43,$40,$3E,$3B,$38,$35,$32
  DEFB $30,$2D,$2A,$27,$24,$21,$1E,$1B,$17,$14,$11,$0E,$0B,$08,$05,$02
  DEFB $FE,$FB,$F8,$F5,$F2,$EF,$EC,$E9,$E5,$E2,$DF,$DC,$D9,$D6,$D3,$D0
  DEFB $CE,$CB,$C8,$C5,$C2,$C0,$BD,$BA,$B8,$B5,$B2,$B0,$AE,$AB,$A9,$A7
  DEFB $A4,$A2,$A0,$9E,$9C,$9A,$98,$96,$95,$93,$91,$90,$8E,$8D,$8C,$8A
  DEFB $89,$88,$87,$86,$85,$84,$83,$83,$82,$82,$81,$81,$81,$81,$81,$81
  DEFB $81,$81,$81,$81,$81,$81,$82,$82,$83,$83,$84,$85,$86,$87,$88,$89
  DEFB $8A,$8C,$8D,$8E,$90,$91,$93,$95,$96,$98,$9A,$9C,$9E,$A0,$A2,$A4
  DEFB $A7,$A9,$AB,$AE,$B0,$B2,$B5,$B8,$BA,$BD,$C0,$C2,$C5,$C8,$CB,$CE
  DEFB $D0,$D3,$D6,$D9,$DC,$DF,$E2,$E5,$E9,$EC,$EF,$F2,$F5,$F8,$FB,$FE

; The screen address of each pixel row, rows 0..191
;
; 192 words `$4000`, `$4100`, ... `$57E0`. The view blits pop them with `SP`
; pointed into the table: ViewBlitFront `$8999` from `$6540` (row 32),
; ViewBlitWide `$8A41` from `$6580` (row 64), ViewBlitNarrow `$8A98` from
; `$6550` (row 40).
ScreenRowTable:
  DEFW $4000,$4100,$4200,$4300,$4400,$4500,$4600,$4700
  DEFW $4020,$4120,$4220,$4320,$4420,$4520,$4620,$4720
  DEFW $4040,$4140,$4240,$4340,$4440,$4540,$4640,$4740
  DEFW $4060,$4160,$4260,$4360,$4460,$4560,$4660,$4760
  DEFW $4080,$4180,$4280,$4380,$4480,$4580,$4680,$4780
  DEFW $40A0,$41A0,$42A0,$43A0,$44A0,$45A0,$46A0,$47A0
  DEFW $40C0,$41C0,$42C0,$43C0,$44C0,$45C0,$46C0,$47C0
  DEFW $40E0,$41E0,$42E0,$43E0,$44E0,$45E0,$46E0,$47E0
  DEFW $4800,$4900,$4A00,$4B00,$4C00,$4D00,$4E00,$4F00
  DEFW $4820,$4920,$4A20,$4B20,$4C20,$4D20,$4E20,$4F20
  DEFW $4840,$4940,$4A40,$4B40,$4C40,$4D40,$4E40,$4F40
  DEFW $4860,$4960,$4A60,$4B60,$4C60,$4D60,$4E60,$4F60
  DEFW $4880,$4980,$4A80,$4B80,$4C80,$4D80,$4E80,$4F80
  DEFW $48A0,$49A0,$4AA0,$4BA0,$4CA0,$4DA0,$4EA0,$4FA0
  DEFW $48C0,$49C0,$4AC0,$4BC0,$4CC0,$4DC0,$4EC0,$4FC0
  DEFW $48E0,$49E0,$4AE0,$4BE0,$4CE0,$4DE0,$4EE0,$4FE0
  DEFW $5000,$5100,$5200,$5300,$5400,$5500,$5600,$5700
  DEFW $5020,$5120,$5220,$5320,$5420,$5520,$5620,$5720
  DEFW $5040,$5140,$5240,$5340,$5440,$5540,$5640,$5740
  DEFW $5060,$5160,$5260,$5360,$5460,$5560,$5660,$5760
  DEFW $5080,$5180,$5280,$5380,$5480,$5580,$5680,$5780
  DEFW $50A0,$51A0,$52A0,$53A0,$54A0,$55A0,$56A0,$57A0
  DEFW $50C0,$51C0,$52C0,$53C0,$54C0,$55C0,$56C0,$57C0
  DEFW $50E0,$51E0,$52E0,$53E0,$54E0,$55E0,$56E0,$57E0

; Polygon work: the list clipped in X, two bytes a vertex (x, y)
;
; Written by the X clip of bank 3 (`$C218` and its states) for the span filler
; `$C4C4` / `$C542`, which also marks the top vertex (bit 7 of its y) and
; copies the list once more behind itself (`LDIR` at `$C514`) so the edge
; walkers can run round it. Up to 20 vertices.
PolyXClipped:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Polygon work: the list clipped in Y, three bytes a vertex (x word, y byte)
;
; Written by the Y clip of bank 3 (`$C000`, `$C02F`, `$C0DE`, `$C17B`) from
; PolyVerts `$6700`, read by the X clip `$C218`.
PolyYClipped:
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

; The near-plane clip's state: the first vertex (`$66CC`), the vertex count
; (`$66CD`), spare
;
; Set by FillFacesClipped `$9E20` / FillPolysClipped `$A07E` and read by
; ClipPolyNear `$A509`.
PolyClipVars:
  DEFB $00,$00,$00

; Unused bytes before the vertex counter
PolyWorkSpare:
  DEFB $00,$00,$00,$00,$00,$00

; The number of vertices ClipPolyNear `$A509` / AppendPolyVertex `$A677` put in
; PolyVerts
PolyOutCount:
  DEFB $00

; Fill patterns: two bytes for each colour 0..12 (`$66D6` + 2c)
;
; The span filler `$C86A` (bank 3) takes (a, b) = (`$66D6`+2c, `$66D7`+2c) for
; the colour c in `$7579`: the row byte is b on one row and b XOR a on the next
; (the `XOR $00` at `$C931` is patched to a), so each colour is a 2-row dither:
; 0 `00/00` black, 1 `00/FF` row stripes, 2 `00/AA`, 3 `FF/FF` solid ink, 4
; `FF/AA`, 5 `AA/AA`, 6 `AA/55` checker, 7 `FF/33`, 8 `55/11`, 9 `FF/55`, 10
; `11/01`, 11 `33/11`, 12 `44/44`. The model scripts use colours 0-9. With
; `$757A` = 0 every colour is solid ink (`LD B,$FF` at `$C875`).
FillPatterns:
  DEFB $00,$00
  DEFB $00,$FF
  DEFB $00,$AA
  DEFB $FF,$FF
  DEFB $FF,$AA
  DEFB $AA,$AA
  DEFB $AA,$55
  DEFB $FF,$33
  DEFB $55,$11
  DEFB $FF,$55
  DEFB $11,$01
  DEFB $33,$11
  DEFB $44,$44

; Keep masks right of a span end: `$7F $3F ... $00` for x AND 7 = 0..7
;
; Read by the span filler `$C86A` at the span's right end.
RightEdgeMasks:
  DEFB $7F,$3F,$1F,$0F,$07,$03,$01,$00

; Keep masks left of a span start: `$00 $80 $C0 ... $FE`
;
; Read by the span filler `$C86A` at the span's left end and for a one-byte
; span (`$C93C`).
LeftEdgeMasks:
  DEFB $00,$80,$C0,$E0,$F0,$F8,$FC,$FE

; Polygon work: the screen vertices of the face being filled, four bytes each
; (x word, y word)
;
; Filled by the face renderers (`$9D99`, `$9E20`, `$9ECD`, `$A07E`,
; ClipPolyNear `$A509`) from ProjectedPoints `$FC00`; the vertex count goes to
; `$68A9`, the colour to `$7579`, then `$7290` pages bank 3 and calls the
; filler `$C4C4`. Up to 8 vertices (`$6700-$671F`).
PolyVerts:
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00

; Bytes between the polygon list and the face flags
FaceWorkSpare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The visibility flag of each face slot 0..39: `$FF` front-facing, `$00`
; back-facing
;
; Written by TestFaces `$9BAF` (opcode 5) at `$6728` + slot (the slot base from
; the opcode's first operand): `$FF` when the screen cross product of three
; vertices is negative (counter-clockwise on screen), or when one or two of
; them are behind the eye; `$00` when all three are behind. Read by the face
; renderers, the edge lists (opcodes 4, 17) and the branches (opcodes 6, 7, 8,
; 10).
FaceFlags:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
