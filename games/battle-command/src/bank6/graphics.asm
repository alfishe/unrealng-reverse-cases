; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The menu graphics and the panel icons drawn by CopyGraphic $6D7F and DrawIcon $73E8
;
; Linear graphics: a row of N bytes per DEFB line, the rows from the top. The icons at $EF34-$F48B and $F59C are 3 x
; 24 (IconTable $75CA in bank 2, the stores' WeaponRecords).
; --------------------------------------------------------------------------------------------------------------------

; 10 x 32 graphic of the mission status card
;
; CopyGraphic source of MissionStatusScreen `$CDD7`.
StatusGraphicA:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$39,$0C,$1C,$18,$60,$CE,$7F,$FA
  DEFB $5F,$FF,$11,$99,$D9,$DC,$CE,$46,$7F,$FA
  DEFB $5F,$FF,$01,$98,$78,$7C,$CE,$42,$7F,$FA
  DEFB $5F,$FF,$29,$9C,$1C,$1C,$CE,$48,$7F,$FA
  DEFB $5F,$FF,$39,$9F,$0F,$0C,$CE,$4C,$7F,$FA
  DEFB $5F,$FF,$39,$9B,$CB,$CC,$CE,$4E,$7F,$FA
  DEFB $5F,$FF,$39,$08,$18,$18,$60,$CE,$7F,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$06,$02,$1E,$03,$06,$04,$30,$67,$3A
  DEFB $5E,$77,$3B,$3F,$3A,$72,$96,$67,$23,$3A
  DEFB $5E,$1F,$37,$3F,$36,$7F,$9E,$67,$21,$3A
  DEFB $5F,$07,$07,$3F,$06,$7F,$9E,$67,$24,$3A
  DEFB $5F,$C3,$37,$3F,$36,$7F,$9E,$67,$26,$3A
  DEFB $5E,$F3,$3B,$3B,$3A,$73,$9E,$67,$27,$3A
  DEFB $5E,$06,$02,$02,$03,$07,$0C,$30,$67,$3A
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 9 x 32 graphic of the catalogue's titles
;
; DrawCatalogueTitles `$C765`.
CatalogueGraphicA:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $58,$18,$18,$40,$40,$42,$73,$07,$FA
  DEFB $5C,$CC,$CC,$E7,$67,$66,$32,$73,$FA
  DEFB $5C,$CC,$CC,$E6,$E6,$E6,$12,$7F,$FA
  DEFB $5C,$1C,$1C,$E0,$E0,$E6,$42,$63,$FA
  DEFB $5C,$CC,$3C,$E6,$E6,$E6,$62,$73,$FA
  DEFB $5C,$CC,$9C,$E7,$67,$E6,$72,$73,$FA
  DEFB $58,$18,$C8,$40,$43,$C2,$73,$07,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$F0,$60,$21,$E0,$30,$60,$7F,$FA
  DEFB $5F,$E7,$73,$B3,$F3,$A7,$29,$7F,$FA
  DEFB $5F,$E1,$F3,$73,$F3,$67,$F9,$FF,$FA
  DEFB $5F,$F0,$70,$73,$F0,$67,$F9,$FF,$FA
  DEFB $5F,$FC,$33,$73,$F3,$67,$F9,$FF,$FA
  DEFB $5F,$EF,$33,$B3,$B3,$A7,$39,$FF,$FA
  DEFB $5F,$E0,$60,$20,$20,$30,$70,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

; 4 x 24 graphic of the stores
;
; StoresScreen `$CAEF`.
StoresGraphicA:
  DEFB $00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FE
  DEFB $40,$00,$00,$02
  DEFB $5F,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FA
  DEFB $5F,$E1,$FE,$1A
  DEFB $5F,$DD,$FD,$DA
  DEFB $5F,$BD,$FB,$DA
  DEFB $5F,$7D,$F7,$DA
  DEFB $5E,$FD,$EF,$DA
  DEFB $5D,$FD,$DF,$DA
  DEFB $5B,$FD,$BF,$DA
  DEFB $5B,$FD,$BF,$DA
  DEFB $5D,$FD,$DF,$DA
  DEFB $5E,$FD,$EF,$DA
  DEFB $5F,$7D,$F7,$DA
  DEFB $5F,$BD,$FB,$DA
  DEFB $5F,$DD,$FD,$DA
  DEFB $5F,$E1,$FE,$1A
  DEFB $5F,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FA
  DEFB $40,$00,$00,$02
  DEFB $7F,$FF,$FF,$FE
  DEFB $00,$00,$00,$00

; 4 x 24 graphic of the stores
;
; StoresScreen `$CAFE`.
StoresGraphicB:
  DEFB $00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FE
  DEFB $40,$00,$00,$02
  DEFB $5F,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FA
  DEFB $58,$7F,$87,$FA
  DEFB $5B,$BF,$BB,$FA
  DEFB $5B,$DF,$BD,$FA
  DEFB $5B,$EF,$BE,$FA
  DEFB $5B,$F7,$BF,$7A
  DEFB $5B,$FB,$BF,$BA
  DEFB $5B,$FD,$BF,$DA
  DEFB $5B,$FD,$BF,$DA
  DEFB $5B,$FB,$BF,$BA
  DEFB $5B,$F7,$BF,$7A
  DEFB $5B,$EF,$BE,$FA
  DEFB $5B,$DF,$BD,$FA
  DEFB $5B,$BF,$BB,$FA
  DEFB $58,$7F,$87,$FA
  DEFB $5F,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FA
  DEFB $40,$00,$00,$02
  DEFB $7F,$FF,$FF,$FE
  DEFB $00,$00,$00,$00

; 11 x 16 graphic of the title menu
;
; TitleMenu `$C446`.
TitleGraphicB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$87,$C1,$E3,$81,$F8,$3C,$73,$90,$1F,$FA
  DEFB $5F,$CF,$9C,$C1,$CC,$F3,$98,$31,$19,$DF,$FA
  DEFB $5F,$CF,$9C,$9C,$CC,$F3,$F3,$90,$19,$BF,$FA
  DEFB $5F,$CF,$9C,$9C,$CC,$F3,$13,$92,$98,$3F,$FA
  DEFB $5F,$CF,$9C,$80,$CC,$F3,$90,$13,$99,$BF,$FA
  DEFB $5F,$CE,$9C,$9C,$CC,$F3,$93,$93,$99,$DF,$FA
  DEFB $5F,$80,$C1,$9C,$81,$F8,$33,$93,$90,$1F,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 11 x 16 graphic of the title menu
;
; TitleMenu `$C437`.
TitleGraphicA:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$82,$07,$1C,$0C,$0F,$83,$C7,$39,$01,$FA
  DEFB $5F,$3A,$96,$0E,$65,$2F,$39,$83,$11,$9D,$FA
  DEFB $5F,$0F,$9C,$E6,$67,$3F,$3F,$39,$01,$9B,$FA
  DEFB $5F,$83,$9C,$E6,$0F,$3F,$31,$39,$29,$83,$FA
  DEFB $5F,$E1,$9C,$06,$1F,$3F,$39,$01,$39,$9B,$FA
  DEFB $5F,$79,$9C,$E6,$4F,$3F,$39,$39,$39,$9D,$FA
  DEFB $5F,$03,$0C,$E4,$66,$1F,$83,$39,$39,$01,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 176 bytes no routine reads (an 11 x 16 graphic by its size)
;
; Known only from the code.
SpareGraphic:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$F0,$70,$67,$20,$42,$72,$72,$03,$FF,$FA
  DEFB $5F,$E7,$27,$23,$29,$66,$32,$73,$3B,$FF,$FA
  DEFB $5F,$E7,$E7,$21,$39,$E6,$12,$73,$37,$FF,$FA
  DEFB $5F,$E7,$E7,$24,$39,$E6,$42,$73,$07,$FF,$FA
  DEFB $5F,$E7,$E7,$26,$39,$E6,$62,$73,$37,$FF,$FA
  DEFB $5F,$E7,$27,$27,$39,$E6,$72,$73,$3B,$FF,$FA
  DEFB $5F,$F0,$70,$67,$30,$C2,$73,$02,$03,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 11 x 16 graphic of the catalogue
;
; MissionCatalogueScreen `$C7B1`.
CatalogueGraphicB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$F8,$20,$71,$C0,$9C,$C1,$FF,$FF,$FA
  DEFB $5F,$FF,$F3,$A9,$60,$D2,$9C,$9D,$FF,$FF,$FA
  DEFB $5F,$FF,$F0,$F9,$CE,$73,$9C,$87,$FF,$FF,$FA
  DEFB $5F,$FF,$F8,$39,$CE,$73,$9C,$C1,$FF,$FF,$FA
  DEFB $5F,$FF,$FE,$19,$C0,$73,$9C,$F0,$FF,$FF,$FA
  DEFB $5F,$FF,$F7,$99,$CE,$73,$9C,$BC,$FF,$FF,$FA
  DEFB $5F,$FF,$F0,$30,$CE,$61,$C0,$81,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 11 x 16 graphic of the mission status card
;
; MissionStatusScreen `$CDC8`.
StatusGraphicB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$E0,$F1,$CE,$40,$3E,$0F,$1C,$E4,$07,$FA
  DEFB $5F,$CE,$E0,$CE,$67,$3C,$E6,$0C,$46,$77,$FA
  DEFB $5F,$C3,$CE,$64,$E6,$FC,$FC,$E4,$06,$6F,$FA
  DEFB $5F,$E0,$CE,$64,$E0,$FC,$C4,$E4,$A6,$0F,$FA
  DEFB $5F,$F8,$40,$71,$E6,$FC,$E4,$04,$E6,$6F,$FA
  DEFB $5F,$DE,$4E,$71,$E7,$3C,$E4,$E4,$E6,$77,$FA
  DEFB $5F,$C0,$CE,$7B,$C0,$3E,$0C,$E4,$E4,$07,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 12 x 16 graphic of the stores
;
; StoresScreen `$CB0D`.
StoresGraphicC:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $58,$20,$71,$C0,$C0,$E7,$21,$83,$83,$0C,$19,$CA
  DEFB $53,$A9,$60,$E6,$52,$E2,$33,$3B,$3B,$99,$C8,$CA
  DEFB $50,$F9,$CE,$66,$73,$E0,$33,$0F,$0F,$99,$C8,$4A
  DEFB $58,$39,$CE,$60,$F3,$E5,$33,$83,$83,$99,$C9,$0A
  DEFB $5E,$19,$C0,$61,$F3,$E7,$33,$E1,$E1,$99,$C9,$8A
  DEFB $57,$99,$CE,$64,$F3,$E7,$33,$79,$79,$99,$C9,$CA
  DEFB $50,$30,$CE,$46,$61,$E7,$21,$03,$03,$0C,$19,$CA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 7 x 16 graphic of the briefing
;
; BriefingScreen `$C9D5`.
BriefingGraphicC:
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$83,$0F,$83,$83,$01,$FA
  DEFB $5F,$39,$9F,$39,$3B,$9D,$FA
  DEFB $5F,$3F,$9F,$39,$0F,$9B,$FA
  DEFB $5F,$3F,$9F,$39,$83,$83,$FA
  DEFB $5F,$3F,$9F,$39,$E1,$9B,$FA
  DEFB $5F,$39,$9D,$39,$79,$9D,$FA
  DEFB $5F,$83,$01,$83,$03,$01,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00

; 7 x 16 graphic of the briefing
;
; BriefingScreen `$C9C6`.
BriefingGraphicB:
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FC,$08,$09,$C8,$1F,$FA
  DEFB $5F,$FD,$2C,$EC,$9A,$5F,$FA
  DEFB $5F,$FF,$3C,$DE,$3E,$7F,$FA
  DEFB $5F,$FF,$3C,$1E,$3E,$7F,$FA
  DEFB $5F,$FF,$3C,$DC,$9E,$7F,$FA
  DEFB $5F,$FF,$3C,$E9,$CE,$7F,$FA
  DEFB $5F,$FE,$18,$0B,$EC,$3F,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00

; 7 x 16 graphic of the briefing
;
; BriefingScreen `$C9B7`.
BriefingGraphicA:
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$39,$C7,$03,$FF,$FA
  DEFB $5F,$FF,$11,$83,$99,$FF,$FA
  DEFB $5F,$FF,$01,$39,$99,$FF,$FA
  DEFB $5F,$FF,$29,$39,$83,$FF,$FA
  DEFB $5F,$FF,$39,$01,$9F,$FF,$FA
  DEFB $5F,$FF,$39,$39,$9F,$FF,$FA
  DEFB $5F,$FF,$39,$39,$0F,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00

; 112 bytes no routine reads (a fourth 7 x 16 graphic by its size)
;
; Known only from the code.
SpareGraphicB:
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $58,$20,$60,$C0,$C0,$60,$FA
  DEFB $53,$A9,$4E,$66,$67,$4E,$FA
  DEFB $50,$F9,$CE,$66,$66,$C3,$FA
  DEFB $58,$39,$CE,$60,$E0,$E0,$FA
  DEFB $5E,$19,$CE,$61,$E6,$F8,$7A
  DEFB $57,$99,$CE,$64,$E7,$5E,$7A
  DEFB $50,$30,$E0,$C6,$40,$40,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00

; The 3 x 24 icons: 18 of IconTable's 19 and one unused, 72 bytes each
;
; IconTable `$75CA` entry t - 1 is the icon of type t; the weapon types 1-13
; are the stores' too (WeaponRecords +5). Entry 19 lies apart, Icon19 `$F59C`.
PanelIcons:
Icon16:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $1E,$81,$E8
  DEFB $08,$00,$80
  DEFB $1E,$82,$E8
  DEFB $2F,$01,$F0
  DEFB $1E,$82,$E8
  DEFB $2F,$01,$F0
  DEFB $1E,$38,$E8
  DEFB $2F,$39,$F0
  DEFB $1E,$FE,$E8
  DEFB $2F,$FF,$F0
  DEFB $1E,$38,$E8
  DEFB $2F,$39,$F0
  DEFB $1E,$82,$E8
  DEFB $2F,$01,$F0
  DEFB $04,$00,$40
  DEFB $0E,$00,$E0
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
IconSpare:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $07,$FF,$C0
  DEFB $08,$7C,$20
  DEFB $07,$FF,$C0
  DEFB $08,$7C,$20
  DEFB $07,$FF,$C0
  DEFB $08,$00,$20
  DEFB $07,$FF,$C0
  DEFB $0E,$7C,$E0
  DEFB $0F,$FF,$E0
  DEFB $0C,$00,$60
  DEFB $0D,$11,$60
  DEFB $0C,$92,$60
  DEFB $0D,$11,$60
  DEFB $0C,$00,$60
  DEFB $0F,$FF,$E0
  DEFB $07,$FF,$C0
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
Icon17:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $02,$FF,$58
  DEFB $06,$FF,$58
  DEFB $07,$FF,$FC
  DEFB $06,$FF,$5C
  DEFB $3F,$FF,$5C
  DEFB $3F,$EF,$5C
  DEFB $2A,$AF,$5C
  DEFB $00,$0F,$5C
  DEFB $02,$AA,$08
  DEFB $04,$55,$54
  DEFB $02,$AA,$08
  DEFB $00,$55,$10
  DEFB $00,$0E,$00
  DEFB $00,$7F,$80
  DEFB $00,$0E,$00
  DEFB $07,$FF,$F8
  DEFB $00,$4B,$D0
  DEFB $07,$FF,$F8
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
Icon18:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $50,$FF,$FC
  DEFB $76,$FF,$FC
  DEFB $7F,$FF,$FC
  DEFB $72,$FF,$FC
  DEFB $24,$AA,$A8
  DEFB $52,$55,$54
  DEFB $24,$AA,$A8
  DEFB $52,$55,$54
  DEFB $20,$AA,$A8
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
Icon14:
  DEFB $00,$00,$00
  DEFB $00,$38,$00
  DEFB $00,$24,$00
  DEFB $00,$42,$00
  DEFB $00,$41,$00
  DEFB $00,$40,$80
  DEFB $00,$42,$80
  DEFB $00,$03,$C0
  DEFB $00,$27,$CC
  DEFB $01,$27,$F0
  DEFB $03,$87,$C0
  DEFB $03,$C7,$20
  DEFB $07,$D6,$F0
  DEFB $07,$E2,$F0
  DEFB $07,$EB,$70
  DEFB $07,$E3,$70
  DEFB $0F,$C7,$B0
  DEFB $0F,$F3,$D0
  DEFB $0E,$93,$F0
  DEFB $0E,$F6,$E0
  DEFB $0C,$03,$00
  DEFB $2A,$BF,$D0
  DEFB $55,$7F,$A0
  DEFB $00,$00,$00
IconK40Mortar:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$F8
  DEFB $00,$03,$FC
  DEFB $00,$0F,$F4
  DEFB $00,$3F,$EA
  DEFB $00,$FF,$54
  DEFB $03,$FE,$A8
  DEFB $0B,$F5,$54
  DEFB $2D,$02,$A8
  DEFB $F6,$FD,$40
  DEFB $F9,$CE,$80
  DEFB $71,$B6,$00
  DEFB $6B,$B7,$00
  DEFB $13,$CF,$00
  DEFB $27,$B7,$80
  DEFB $17,$97,$80
  DEFB $0F,$B7,$C0
  DEFB $0F,$97,$C0
  DEFB $1F,$33,$E0
  DEFB $1A,$95,$60
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
Icon15:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $09,$F3,$00
  DEFB $1B,$33,$00
  DEFB $5B,$F3,$00
  DEFB $5B,$FB,$00
  DEFB $5F,$FF,$50
  DEFB $5B,$FB,$F8
  DEFB $59,$3F,$7C
  DEFB $4B,$37,$FE
  DEFB $51,$D3,$54
  DEFB $4A,$A7,$28
  DEFB $51,$53,$50
  DEFB $4A,$A6,$00
  DEFB $11,$D1,$00
  DEFB $0B,$22,$00
  DEFB $01,$D1,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
IconSlamLaser:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $3F,$00,$00
  DEFB $0C,$00,$00
  DEFB $1F,$F0,$00
  DEFB $7F,$FB,$C0
  DEFB $DF,$FF,$F8
  DEFB $FF,$FB,$DB
  DEFB $D4,$11,$48
  DEFB $C9,$CA,$80
  DEFB $13,$60,$00
  DEFB $02,$20,$00
  DEFB $03,$60,$00
  DEFB $03,$E0,$00
  DEFB $03,$E0,$00
  DEFB $07,$F0,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
IconBansheeIRSS:
  DEFB $00,$01,$C0
  DEFB $00,$03,$E0
  DEFB $00,$07,$F0
  DEFB $00,$07,$F0
  DEFB $00,$07,$F0
  DEFB $03,$83,$E0
  DEFB $03,$C1,$C0
  DEFB $03,$E0,$00
  DEFB $61,$F0,$00
  DEFB $31,$F8,$C0
  DEFB $18,$5C,$60
  DEFB $7F,$FE,$FC
  DEFB $FF,$FF,$FE
  DEFB $00,$FE,$FF
  DEFB $55,$5C,$FE
  DEFB $2A,$AA,$FC
  DEFB $18,$10,$60
  DEFB $30,$A8,$C0
  DEFB $61,$D0,$00
  DEFB $03,$E0,$00
  DEFB $03,$C0,$00
  DEFB $03,$80,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
IconBansheeRRSS:
  DEFB $00,$00,$80
  DEFB $00,$01,$80
  DEFB $00,$03,$80
  DEFB $00,$07,$80
  DEFB $00,$0F,$80
  DEFB $03,$9F,$A0
  DEFB $03,$C0,$70
  DEFB $03,$E1,$F8
  DEFB $61,$F0,$00
  DEFB $31,$F8,$C0
  DEFB $18,$5C,$60
  DEFB $7F,$FE,$FC
  DEFB $FF,$FF,$FE
  DEFB $00,$FE,$FF
  DEFB $55,$5C,$FE
  DEFB $2A,$AA,$FC
  DEFB $18,$10,$60
  DEFB $30,$A8,$C0
  DEFB $61,$D0,$00
  DEFB $03,$E0,$00
  DEFB $03,$C0,$00
  DEFB $03,$80,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
IconPhoenixIRSA:
  DEFB $0E,$00,$0E
  DEFB $1F,$00,$1F
  DEFB $3F,$81,$EA
  DEFB $3F,$80,$F5
  DEFB $3F,$80,$F2
  DEFB $1F,$01,$E8
  DEFB $0E,$03,$D4
  DEFB $00,$0D,$A8
  DEFB $00,$1E,$44
  DEFB $00,$3E,$00
  DEFB $00,$7D,$00
  DEFB $7F,$BA,$80
  DEFB $FF,$D5,$00
  DEFB $F5,$EA,$00
  DEFB $2B,$F0,$00
  DEFB $17,$F0,$00
  DEFB $0F,$B8,$00
  DEFB $1F,$58,$00
  DEFB $2E,$B8,$00
  DEFB $75,$78,$00
  DEFB $E2,$F8,$00
  DEFB $70,$78,$00
  DEFB $20,$78,$00
  DEFB $10,$30,$00
IconPhoenixRRSA:
  DEFB $02,$00,$0E
  DEFB $06,$00,$1F
  DEFB $0E,$01,$EA
  DEFB $1E,$00,$F5
  DEFB $3E,$00,$F2
  DEFB $7E,$81,$E8
  DEFB $01,$C3,$D4
  DEFB $07,$ED,$A8
  DEFB $00,$1E,$44
  DEFB $00,$3E,$00
  DEFB $00,$7D,$00
  DEFB $7F,$BA,$80
  DEFB $FF,$D5,$00
  DEFB $F5,$EA,$00
  DEFB $2B,$F0,$00
  DEFB $17,$F0,$00
  DEFB $0F,$B8,$00
  DEFB $1F,$58,$00
  DEFB $2E,$B8,$00
  DEFB $75,$78,$00
  DEFB $E2,$F8,$00
  DEFB $70,$78,$00
  DEFB $20,$78,$00
  DEFB $10,$30,$00
IconSleeperMine:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$18,$00
  DEFB $00,$FF,$00
  DEFB $00,$7E,$00
  DEFB $0A,$AB,$D0
  DEFB $00,$03,$80
  DEFB $0F,$FF,$F0
  DEFB $05,$57,$A0
  DEFB $00,$03,$80
  DEFB $1F,$FF,$F8
  DEFB $2A,$AF,$D4
  DEFB $55,$57,$AA
  DEFB $2A,$AB,$D4
  DEFB $55,$57,$AA
  DEFB $2A,$AB,$D4
  DEFB $55,$57,$AA
  DEFB $2A,$AF,$F4
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
IconDragonfly:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $F0,$00,$00
  DEFB $F8,$00,$00
  DEFB $7C,$00,$00
  DEFB $17,$FF,$50
  DEFB $FF,$FF,$FE
  DEFB $FF,$FF,$5F
  DEFB $00,$1F,$5E
  DEFB $2A,$AA,$50
  DEFB $54,$00,$00
  DEFB $E8,$00,$00
  DEFB $F0,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
IconSpectre:
  DEFB $00,$10,$00
  DEFB $00,$00,$00
  DEFB $20,$10,$04
  DEFB $00,$10,$00
  DEFB $08,$10,$10
  DEFB $04,$00,$20
  DEFB $02,$18,$40
  DEFB $00,$66,$00
  DEFB $00,$99,$00
  DEFB $01,$7E,$80
  DEFB $01,$7E,$80
  DEFB $02,$FF,$5D
  DEFB $BA,$FF,$40
  DEFB $01,$7E,$80
  DEFB $01,$7E,$80
  DEFB $00,$99,$00
  DEFB $00,$66,$00
  DEFB $02,$18,$40
  DEFB $04,$00,$20
  DEFB $08,$08,$10
  DEFB $00,$08,$00
  DEFB $20,$08,$04
  DEFB $00,$00,$00
  DEFB $00,$08,$00
IconK90Cluster:
  DEFB $00,$FF,$00
  DEFB $03,$FF,$C0
  DEFB $0F,$FF,$F0
  DEFB $1F,$FF,$F8
  DEFB $3F,$FF,$FC
  DEFB $7F,$FF,$FE
  DEFB $7F,$FF,$FE
  DEFB $FF,$FF,$FF
  DEFB $FF,$FF,$FF
  DEFB $20,$81,$04
  DEFB $10,$81,$08
  DEFB $08,$42,$10
  DEFB $04,$42,$20
  DEFB $02,$42,$40
  DEFB $01,$24,$80
  DEFB $00,$A5,$00
  DEFB $00,$7E,$00
  DEFB $06,$C3,$60
  DEFB $03,$81,$C0
  DEFB $01,$81,$80
  DEFB $00,$81,$00
  DEFB $00,$81,$00
  DEFB $00,$C3,$00
  DEFB $00,$7E,$00
IconPhantasm:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$07,$80
  DEFB $00,$1F,$E0
  DEFB $00,$78,$78
  DEFB $01,$E0,$1E
  DEFB $03,$80,$07
  DEFB $01,$E0,$1E
  DEFB $02,$78,$79
  DEFB $05,$1F,$E7
  DEFB $0A,$A7,$9E
  DEFB $05,$50,$7E
  DEFB $18,$AA,$FC
  DEFB $06,$55,$FC
  DEFB $11,$8B,$F8
  DEFB $2A,$65,$F8
  DEFB $55,$1B,$F0
  DEFB $AA,$AF,$F0
  DEFB $15,$4F,$C0
  DEFB $0A,$BF,$00
  DEFB $01,$5C,$00
  DEFB $00,$B0,$00
  DEFB $00,$40,$00
  DEFB $00,$00,$00
IconSkeetBomb:
  DEFB $00,$00,$00
  DEFB $2A,$F5,$54
  DEFB $05,$7A,$A0
  DEFB $00,$60,$00
  DEFB $02,$FD,$40
  DEFB $01,$7A,$80
  DEFB $00,$20,$00
  DEFB $02,$BA,$80
  DEFB $00,$7C,$00
  DEFB $38,$3A,$1C
  DEFB $38,$00,$1C
  DEFB $38,$00,$1C
  DEFB $38,$7A,$1C
  DEFB $38,$BD,$1C
  DEFB $38,$7A,$1C
  DEFB $FE,$B1,$7F
  DEFB $7C,$7A,$3E
  DEFB $38,$3C,$1C
  DEFB $10,$10,$08
  DEFB $00,$7A,$00
  DEFB $00,$10,$00
  DEFB $00,$3C,$00
  DEFB $00,$18,$00
  DEFB $00,$00,$00
IconTurret:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$3C,$00
  DEFB $3C,$18,$00
  DEFB $0E,$FF,$00
  DEFB $1F,$BD,$C0
  DEFB $17,$FF,$F0
  DEFB $0E,$C3,$78
  DEFB $3F,$81,$FC
  DEFB $7D,$81,$BE
  DEFB $7D,$81,$BE
  DEFB $FD,$81,$97
  DEFB $FC,$C3,$2A
  DEFB $7A,$FF,$55
  DEFB $15,$3C,$AA
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00

; 8 x 16 graphic of the title menu
;
; TitleMenu `$C455`.
TitleGraphicC:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5E,$0C,$0C,$08,$70,$67,$38,$3A
  DEFB $5C,$E6,$65,$2C,$E7,$23,$33,$BA
  DEFB $5C,$E6,$67,$3C,$E7,$21,$30,$FA
  DEFB $5C,$E6,$0F,$3C,$E7,$24,$38,$3A
  DEFB $5C,$E6,$7F,$3C,$E7,$26,$3E,$1A
  DEFB $5C,$E6,$7F,$3C,$E7,$27,$37,$9A
  DEFB $5E,$0C,$3E,$18,$70,$67,$30,$3A
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; 9 x 16 graphic of the catalogue's titles
;
; DrawCatalogueTitles `$C774`.
CatalogueGraphicC:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FC,$18,$0E,$38,$1C,$18,$47,$FA
  DEFB $5F,$F9,$DC,$EC,$1C,$C9,$CC,$EF,$FA
  DEFB $5F,$F8,$7C,$D9,$CC,$C9,$FC,$EF,$FA
  DEFB $5F,$FC,$1C,$19,$CC,$19,$FC,$0F,$FA
  DEFB $5F,$FF,$0C,$D8,$0C,$39,$FC,$EF,$FA
  DEFB $5F,$FB,$CC,$E9,$CC,$99,$CC,$EF,$FA
  DEFB $5F,$F8,$18,$09,$C8,$CC,$18,$47,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $5F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FA
  DEFB $40,$00,$00,$00,$00,$00,$00,$00,$02
  DEFB $7F,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FE
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

; The 3 x 24 icon of IconTable entry 19
;
; Read by DrawIcon through IconTable.
Icon19:
  DEFB $FF,$FF,$FF
  DEFB $FF,$FF,$FE
  DEFB $C0,$00,$00
  DEFB $DA,$AA,$99
  DEFB $D9,$55,$5A
  DEFB $C2,$AA,$81
  DEFB $D5,$55,$52
  DEFB $CA,$AA,$A9
  DEFB $D5,$55,$52
  DEFB $CA,$AA,$A9
  DEFB $D5,$55,$52
  DEFB $CA,$AA,$A9
  DEFB $D5,$55,$52
  DEFB $CA,$AA,$A9
  DEFB $D5,$55,$52
  DEFB $CA,$AA,$A9
  DEFB $D5,$55,$52
  DEFB $CA,$AA,$A9
  DEFB $C1,$55,$42
  DEFB $DA,$AA,$99
  DEFB $D9,$55,$5A
  DEFB $C0,$00,$01
  DEFB $AA,$AA,$AA
  DEFB $55,$55,$55
