; --------------------------------------------------------------------------------------------------------------------
; tables.asm: The tables: bullet paths, key names, the scripted spawn, the shards, the texts, the screen lines, the mirror and shift tables, the rooms' objects and exits
; --------------------------------------------------------------------------------------------------------------------

; The long bullet's path (bullet type 7, MoveBeam $B7FC): Y offset, picture
; pairs, then $1E and the beam's end records at BeamEnd $A9C9
BeamPath:
  DEFB $FB,$00
  DEFB $FC,$00
  DEFB $FD,$04
  DEFB $FE,$04
  DEFB $FF,$04
  DEFB $00,$08
  DEFB $01,$08
  DEFB $02,$0C
  DEFB $03,$0C
  DEFB $04,$10
  DEFB $05,$10
  DEFB $06,$14
  DEFB $07,$14
BeamEnd:
  DEFB $08,$14            ; the beam's last frames
  DEFB $1E

; The key characters of the 40 keys in the order of KeyPorts $E0E0 (CAPS as
; "-", ENTER "+", SYMBOL "."; key 0 also shows as "-"): DEFINE echoes them
;
; ScanKey $DBAE indexes it by half-row x 5 + bit. "1"-"5" are the last
; half-row; SPACE and H are refused (the smart bomb and pause keys).
KeyNames:
  DEFB $2D,$5A,$58,$43,$56,$41,$53,$44
  DEFB $46,$47,$51,$57,$45,$52,$54,$50
  DEFB $4F,$49,$55,$59,$2B,$4C,$4B,$4A
  DEFB $48,$20,$2E,$4D,$4E,$42,$2D,$39
  DEFB $38,$37,$36,$31,$32,$33,$34,$35

; The scripted spawn of rooms 2, 3, 4, 6 and 20: $1E then records [kind
; $85/$83/$84][X $E8][Y $12][delay 8], $FF ends
ScriptSpawn:
  DEFB $1E,$85,$E8,$12,$08
  DEFB $83,$E8,$12,$08,$83
  DEFB $E8,$12,$08,$83,$E8
  DEFB $12,$08,$83,$E8,$12
  DEFB $08,$84,$E8,$12,$08
  DEFB $FF

; The explosion's six shards (BlowUp $BD6B): 8 X, Y offset pairs each, $FF ends
ShardPaths:
  DEFB $0A,$1C,$0B,$18,$0C,$16,$0D,$14,$0E,$15,$0F,$16,$10,$17,$11,$18
  DEFB $06,$1C,$05,$1A,$04,$18,$03,$16,$02,$17,$01,$18,$00,$19,$FF,$1A
  DEFB $0A,$2C,$0B,$30,$0C,$34,$0D,$38,$0E,$40,$0F,$48,$10,$50,$11,$58
  DEFB $06,$2C,$05,$30,$04,$34,$03,$38,$02,$40,$01,$48,$00,$50,$FF,$58
  DEFB $08,$20,$08,$1A,$08,$14,$08,$10,$08,$0C,$08,$0A,$08,$08,$08,$07
  DEFB $09,$3A,$09,$3C,$09,$40,$09,$46,$09,$4E,$09,$56,$09,$5E,$09,$64

; The explosion shards' pictures, 8 bytes each (DrawShard $BF66)
ShardPictures:
  DEFB $00,$00,$28,$7C,$38,$7C,$28,$00
  DEFB $00,$00,$38,$6C,$44,$6C,$38,$00
  DEFB $00,$00,$28,$44,$00,$44,$28,$00
  DEFB $00,$24,$42,$00,$00,$42,$24,$00
  DEFB $42,$81,$00,$00,$00,$00,$81,$42
  DEFB $81,$00,$00,$00,$00,$00,$00,$81
  DEFB $00,$01,$80,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$40,$00,$00,$00

; The game's text records: [attribute][column][line] text, 0
;
; PhaseOneText (3 records: PHASE ONE:PROCEED / ON FOOT THROUGH / UNDERGROUND
; COMPLEX), GameOverText, HiScoreText, HumansKilledText, PressFireText (2:
; PRESS FIRE / TO BEGIN), the bonus panels (SPEED UP, SHIELD LOSS, 1000 BONUS,
; ENERGY LOSS, 100 RAPID SHOTS) and the weapon panels, each after a flag byte
; that keeps it to one showing (DOUBLE FIRE, LASER, MULTIPLE, SPRAY). A ":"
; prints as "-" in the font.
GameTexts:
  INCBIN "res/texts/rex1-game.bin",$0000,63
GameOverText:
  ; $AAED GAME OVER
  INCBIN "res/texts/rex1-game.bin",$003F,13
HiScoreText:
  ; $AAFA HI:SCORE 0000000
  INCBIN "res/texts/rex1-game.bin",$004C,20
HumansKilledText:
  ; $AB0E HUMANS KILLED:00000
  INCBIN "res/texts/rex1-game.bin",$0060,23
PressFireText:
  ; $AB25 PRESS FIRE / TO BEGIN
  INCBIN "res/texts/rex1-game.bin",$0077,28
BonusTexts:
  ; $AB41 the bonus panels, 19 bytes each: SPEED UP
  INCBIN "res/texts/rex1-game.bin",$0093,19
ShieldLossText:
  ; $AB54 SHIELD LOSS
  INCBIN "res/texts/rex1-game.bin",$00A6,19
BonusPointsText:
  ; $AB67 1000 BONUS
  INCBIN "res/texts/rex1-game.bin",$00B9,19
EnergyLossText:
  ; $AB7A ENERGY LOSS
  INCBIN "res/texts/rex1-game.bin",$00CC,19
RapidShotsText:
  ; $AB8D 100 RAPID SHOTS
  INCBIN "res/texts/rex1-game.bin",$00DF,19
DoubleFireText:
  ; $ABA0 the flag (shown once), then DOUBLE FIRE
  INCBIN "res/texts/rex1-game.bin",$00F2,17
LaserText:
  ; $ABB1 flag, LASER
  INCBIN "res/texts/rex1-game.bin",$0103,11
MultipleText:
  ; $ABBC flag, MULTIPLE
  INCBIN "res/texts/rex1-game.bin",$010E,14
SprayText:
  ; $ABCA flag, SPRAY
  INCBIN "res/texts/rex1-game.bin",$011C,11
PixelMasks:
  ; $ABD5 $80, $40, ... $01: a pixel's mask by X & 7
  INCBIN "res/texts/rex1-game.bin",$0127,8

; The screen address of each of the 192 pixel lines (PrintChar, PrintDigits,
; PanelBox, DrawCharBlock)
ScreenLineTable:
  DEFW $4000,$4100,$4200,$4300,$4400,$4500,$4600,$4700
  DEFW $4020,$4120,$4220,$4320,$4420,$4520,$4620,$4720
  DEFW $4040,$4140,$4240,$4340,$4440,$4540,$4640,$4740
ScreenLines:
  DEFW $4060,$4160,$4260,$4360,$4460,$4560,$4660,$4760 ; line 24 on: the play
  DEFW $4080,$4180,$4280,$4380,$4480,$4580,$4680,$4780 ; area's 168 lines,
  DEFW $40A0,$41A0,$42A0,$43A0,$44A0,$45A0,$46A0,$47A0 ; BufferToScreen's list
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

; Each byte with its bits reversed: DrawMirrored $B2C1 draws a picture facing
; left through it
MirrorTable:
  DEFB $00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0
  DEFB $08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8
  DEFB $04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4
  DEFB $0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
  DEFB $02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2
  DEFB $0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
  DEFB $06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6
  DEFB $0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
  DEFB $01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1
  DEFB $09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9
  DEFB $05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5
  DEFB $0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
  DEFB $03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3
  DEFB $0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
  DEFB $07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7
  DEFB $0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF

; The pictures' frame lists: 8 offsets each, one a pixel phase (X & 7), into a
; pre-shifted picture
;
; ShiftFrames ($00 $00 $30 $30 $60 $60 $90 $90: a 3 x 16 picture shifted every
; 2 pixels) for Rex and most objects; ShiftFrames2 $AE65 Rex jumping; $AE6D,
; $AE75, $AE7D, $AE85 the other sizes.
ShiftFrames:
  DEFB $00,$00,$30,$30,$60,$60,$90,$90
ShiftFrames2:
  DEFB $00,$00,$54,$54,$A8,$A8,$FC,$FC
ShiftFrames3:
  DEFB $00,$00,$24,$24,$48,$48,$6C,$6C
ShiftFrames4:
  DEFB $00,$10,$20,$30,$40,$50,$60,$70
ShiftFrames5:
  DEFB $00,$16,$2C,$42,$58,$6E,$84,$9A
ShiftFrames6:
  DEFB $00,$00,$00,$00,$30,$30,$30,$30
AnimFramesA:
  DEFB $3E,$3E,$3E,$7F,$3E,$1C,$08,$00 ; characters 252-255 on the passes with
  DEFB $00,$08,$1C,$3E,$7F,$3E,$3E,$3E ; PassToggle 0: 4 x 8 bytes
  DEFB $08,$1F,$3F,$7F,$3F,$1F,$08,$00
  DEFB $10,$F8,$FC,$FE,$FC,$F8,$10,$00
AnimFramesB:
  DEFB $00,$3E,$3E,$3E,$7F,$3E,$1C,$08 ; characters 252-255 on the other
  DEFB $08,$1C,$3E,$7F,$3E,$3E,$3E,$00 ; passes: 4 x 8 bytes
  DEFB $10,$3E,$7E,$FE,$7E,$3E,$10,$00
  DEFB $08,$7C,$7E,$7F,$7E,$7C,$08,$00

; The rooms' object lists: a header [spawn sides: bit 7 top, 6 right, 5
; left][spawn period][spawn kind] (ReadExits $C8EF), then up to 16 records
; [kind][X][Y] (MakeObjects $CB52), $FF ends
RoomObjectLists:
  INCBIN "res/rooms/rex1-objects.bin",$0000,614

; The exits of the rooms 0-34: up, right, down, left (0 none, 99 the end of
; part 1), then the word of the room's object list
;
; ReadExits $C8EF reads Room x 6. Room 0's record has no exits but room 1 to
; the right; the game starts in room 1.
RoomExits:
  INCBIN "res/rooms/rex1-exits.bin",$0000,210
