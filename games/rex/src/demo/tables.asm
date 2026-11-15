; --------------------------------------------------------------------------------------------------------------------
; tables.asm: The tables: the room list, the beam path, the scripted spawns, the shards, the texts, the screen lines, the mirror and frame tables, the rooms' objects and exits, the tutor's input scripts
; --------------------------------------------------------------------------------------------------------------------

  ORG $A2A2

; The rooms the demo plays in turn: 4, 1, 0, 2, then $FF (again from the start:
; NextTutorRoom)
TutorRooms:
  INCBIN "res/tables/demo-tutor-rooms.bin",$0000,5

; The long shot's path (MoveBeam): dX, dY pairs from $FB, 0 up to 8, $14;
; MoveBeam stops at $A2C1
BeamPath:
  DEFB $FB,$00,$FC,$00,$FD,$04,$FE,$04,$FF,$04,$00,$08,$01,$08,$02,$0C,$03,$0C,$04,$10,$05,$10,$06,$14,$07,$14,$08,$14,$1E

; Room 0's scripted spawn (TutorRoom0): the first delay, then records [kind
; $80][X $E8][Y][delay], $FF ends
TutorSpawn0:
  DEFB $32,$80,$E8,$12,$64,$80,$E8,$12,$64,$80,$E8,$12,$64,$80,$E8,$12
  DEFB $09,$80,$E8,$12,$09,$80,$E8,$12,$09,$80,$E8,$12,$09,$80,$E8,$12
  DEFB $09,$80,$E8,$12,$64,$80,$E8,$12,$01,$80,$E8,$0F,$63,$80,$E8,$12
  DEFB $01,$80,$E8,$0F,$01,$80,$E8,$0C,$64,$FF
TutorSpawn2:
  DEFB $0A,$0C,$30,$01,$1E,$0C,$38,$01,$1E,$0C,$40,$01,$1E,$0C,$30,$01 ; room 2's
  DEFB $1E,$0C,$30,$01,$1E,$0C,$40,$01,$1E,$FF                         ; (TutorRoom2):
                                                                       ; kind $0C
                                                                       ; walkers
                                                                       ; from the
                                                                       ; left
TutorSpawn3:
  DEFB $64,$0C,$F8,$01,$0A,$0C,$F8,$03,$0A,$0C,$F8,$05,$0A,$0C,$F8,$07 ; room 3's
  DEFB $0A,$0C,$F8,$09,$0A,$0C,$F8,$0B,$0A,$FF                         ; (MainLoop):
                                                                       ; six kind
                                                                       ; $0C from
                                                                       ; the right

; The six shards' paths of an explosion (BlowUp, DrawShard): 16 bytes each,
; [dX][dY] pairs
ShardPaths:
  DEFB $0A,$1C,$0B,$18,$0C,$16,$0D,$14,$0E,$15,$0F,$16,$10,$17,$11,$18
  DEFB $06,$1C,$05,$1A,$04,$18,$03,$16,$02,$17,$01,$18,$00,$19,$FF,$1A
  DEFB $0A,$2C,$0B,$30,$0C,$34,$0D,$38,$0E,$40,$0F,$48,$10,$50,$11,$58
  DEFB $06,$2C,$05,$30,$04,$34,$03,$38,$02,$40,$01,$48,$00,$50,$FF,$58
  DEFB $08,$20,$08,$1A,$08,$14,$08,$10,$08,$0C,$08,$0A,$08,$08,$08,$07
  DEFB $09,$3A,$09,$3C,$09,$40,$09,$46,$09,$4E,$09,$56,$09,$5E,$09,$64

; The shards' pictures, 4 bytes each, by step (DrawShard)
ShardPictures:
  DEFB $00,$00,$28,$7C,$38,$7C,$28,$00,$00,$00,$38,$6C,$44,$6C,$38,$00
  DEFB $00,$00,$28,$44,$00,$44,$28,$00,$00,$24,$42,$00,$00,$42,$24,$00
  DEFB $42,$81,$00,$00,$00,$00,$81,$42,$81,$00,$00,$00,$00,$00,$00,$81
  DEFB $00,$01,$80,$00,$00,$00,$00,$00,$00,$00,$00,$00,$40,$00,$00,$00

; The bonus roulette's five panels as text records [attribute][column][line]
; text 0: SPEED UP, SHIELD LOSS, 1000 BONUS, ENERGY LOSS, 100 RAPID SHOTS
; (BonusTextTable)
BonusTexts:
  INCBIN "res/texts/demo-bonus.bin",$0000,76
RapidShotsText:
  ; $A41E 100 RAPID SHOTS
  INCBIN "res/texts/demo-bonus.bin",$004C,19

; The tutor's panels: text records [attribute][column][line] text 0, a panel B
; records from its label (TutorPanel and the room tutors)
TutorTexts:
TextCollect:
  ; $A431 REX MUST FIRST COLLECT WEAPONS FROM THE PODS
  INCBIN "res/texts/demo-tutor.bin",$0000,54
TextBonus:
  ; $A467 AN EXTRA BONUS IS AWARDED FOR RAPID HITS ON THE SOLDIERS
  INCBIN "res/texts/demo-tutor.bin",$0036,69
TextLaser:
  ; $A4AC THE LASER CAN KILL A ROW OF THE ENEMY
  INCBIN "res/texts/demo-tutor.bin",$007B,47
TextStandard:
  ; $A4DB REX STARTS WITH THE STANDARD ISSUE APA:150 MACHINE GUN ...
  INCBIN "res/texts/demo-tutor.bin",$00AA,129
TextPower:
  ; $A55C EACH WEAPON HAS A POWER STATUS FROM: PINK:LOW UP TO WHITE: HIGH
  ;   ...
  INCBIN "res/texts/demo-tutor.bin",$012B,133
DoubleFireText:
  ; $A5E1 the station's flag (0: not shown yet), then its panel: APA:150
  ;   MKII, A DUEL SHOT VERSION OF THE OLD APA MKI
  INCBIN "res/texts/demo-tutor.bin",$01B0,66
LaserText:
  ; $A623 flag, TUSK LASER MKIV, USED IN THE GREAT LIFE WARS ...
  INCBIN "res/texts/demo-tutor.bin",$01F2,95
MultipleText:
  ; $A682 flag, REMOTE DRONE OFFENSIVE SYSTEM ...
  INCBIN "res/texts/demo-tutor.bin",$0251,99
SprayText:
  ; $A6E5 flag, MULTI:DIRECTIONAL SPRAY PROJECTILE LAUNCHER ...
  INCBIN "res/texts/demo-tutor.bin",$02B4,91
TextSpray3:
  ; $A740 3 WAY SPRAY
  INCBIN "res/texts/demo-tutor.bin",$030F,15
TextSpray5:
  ; $A74F 5 WAY SPRAY
  INCBIN "res/texts/demo-tutor.bin",$031E,15
TextSpray7:
  ; $A75E 7 WAY SPRAY
  INCBIN "res/texts/demo-tutor.bin",$032D,15
TextSpray4:
  ; $A76D 4 DIRECTIONAL SPRAY
  INCBIN "res/texts/demo-tutor.bin",$033C,23
TextSpray8:
  ; $A784 FULL 8 WAY SPRAY
  INCBIN "res/texts/demo-tutor.bin",$0353,20
TextShield:
  ; $A798 YOUR SHIELD CAN BE USED TO DESTROY THE ENEMY AND DEFLECT BULLETS
  INCBIN "res/texts/demo-tutor.bin",$0367,77
TextBubbles:
  ; $A7E5 COLLECT THE BUBBLES DROPPED BY THE ENEMY TO INCREASE YOUR WEAPONS
  ;   ENERGY
  INCBIN "res/texts/demo-tutor.bin",$03B4,85
TextBeamPads:
  ; $A83A USE BEAM:PADS TO RECORD POSITION
  INCBIN "res/texts/demo-tutor.bin",$0409,40
TextRecharge:
  ; $A862 STAND ON DISC TO CHARGE YOUR SHIELD
  INCBIN "res/texts/demo-tutor.bin",$0431,42
TextQuestion:
  ; $A88C PICK UP QUESTION MARKS FOR A SKILL BONUS:USE FIRE TO SELECT
  INCBIN "res/texts/demo-tutor.bin",$045B,72
TextWalls:
  ; $A8D4 SOME WALLS CAN BE SHOT THROUGH
  INCBIN "res/texts/demo-tutor.bin",$04A3,37
TextExits:
  ; $A8F9 ARROWS SUGGEST EXITS FROM SCREEN:BUT LOOK FOR SECRET PASSAGES
  INCBIN "res/texts/demo-tutor.bin",$04C8,71
TextScanners:
  ; $A940 BEWARE OF SCANNERS THEY DETECT ANY MOVEMENT IN THE AREAS SHOWN
  INCBIN "res/texts/demo-tutor.bin",$050F,78
TextFalling:
  ; $A98E IF REX FALLS DOWN A SCREEN WITHOUT AN EXIT HE IS FORCED TO BEAM
  ;   OUT
  INCBIN "res/texts/demo-tutor.bin",$055D,80
TextTeleport:
  ; $A9DE AFTER TELEPORTATION REX IS TAKEN TO THE LAST BEAM:PAD
  INCBIN "res/texts/demo-tutor.bin",$05AD,63
TextSmartBombs:
  ; $AA1D SMART BOMBS CAN KILL ALL THE ENEMIES ON THE SCREEN:EXTRA ONES ARE
  ;   SOMETIMES LEFT BY THE ENEMY
  INCBIN "res/texts/demo-tutor.bin",$05EC,109
TutorIntro:
  ; $AA8A YOU ARE ABOUT TO SEE A DEMO OF REX THE DEBUT GAME BY THE LIGHT
  ;   SPACE:PAUSES DEMO
  INCBIN "res/texts/demo-tutor.bin",$0659,99
TutorPrologue:
  ; $AAED FIRST A SHORT PROLOGUE OF HOW REX INFILTRATED THE TOWER THROUGH
  ;   THE HIDDEN UNDERGROUND RIVER
  INCBIN "res/texts/demo-tutor.bin",$06BC,108
TutorText1:
  ; $AB59 NEXT AN EXPLANATION OF THE FIVE WEAPON SYSTEMS REX CAN USE
  INCBIN "res/texts/demo-tutor.bin",$0728,69
TutorText0:
  ; $AB9E YOU HAVE NOW SEEN THE HARDWARE:NOW THE EFFECT IT HAS ON THE ENEMY
  INCBIN "res/texts/demo-tutor.bin",$076D,75
TutorText2:
  ; $ABE9 AND FINALLY A FEW GUIDELINES ON HOW REX CAN MAKE THE BEST OF HIS
  ;   SUROUNDINGS
  INCBIN "res/texts/demo-tutor.bin",$07B8,89
TutorCredits:
  ; $AC42 ALL SOFTWARE SOUND AND VISION BY THE LIGHT
  INCBIN "res/texts/demo-tutor.bin",$0811,68

; Leftover: the bit masks $80, $40, ... $01 (part 2's PixelMasks); no code
; reads them here
PixelMasks:
  DEFB $80,$40,$20,$10,$08,$04,$02,$01

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

; Each byte with its bits reversed: DrawMirrored draws a picture facing left
; through it
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

; The pictures' frame lists: 8 picture words each, one a pixel phase (X & 7):
; kind 0, Rex, kinds 1 and 2, 12, 8, Rex jumping and shielded, the swing gun's
; turn, the hit flash
ShiftFrames:
  DEFW Sprites,Sprites,$7A0C,$7A0C,$7A3C,$7A3C,$7A6C,$7A6C
ShieldFrames:
  DEFW $811C,$811C,$817C,$817C,$81DC,$81DC,$823C,$823C ; the shield bubble
                                                       ; (DrawShield)
FramesKind1:
  DEFW $7A9C,$7A9C,$7ACC,$7ACC,$7AFC,$7AFC,$7B2C,$7B2C ; kinds 1 and 2
FramesKind12:
  DEFW $85E4,$85E4,$8614,$8614,$8644,$8644,$8674,$8674 ; kind 12
FramesKind8:
  DEFW $83B4,$83CA,$83E0,$83F6,$840C,$8422,$8438,$844E ; kind 8
RexFramesJump:
  DEFW $87BC,$87BC,$87EC,$87EC,$881C,$881C,$884C,$884C ; Rex jumping or
                                                       ; falling, off a lift
                                                       ; (DrawRex)
RexFramesWalk:
  DEFW $7B5C,$7B5C,$7B8C,$7B8C,$7BBC,$7BBC,$7BEC,$7BEC ; Rex walking or
                                                       ; standing (DrawRex)
FramesTurn:
  DEFW $7EBC,$7EBC,$7EBC,$7EBC,$7EEC,$7EEC,$7EEC,$7EEC ; kind 6's turn and kind
                                                       ; 7 (SwingGun)
FramesHit:
  DEFW $7E5C,$7E5C,$7E5C,$7E5C,$7E8C,$7E8C,$7E8C,$7E8C        ; an object hit
  DEFW SpritePoints,$7C64,$7CAC,$7CF4,$7D44,$7D84,$7DCC,$7E14 ; (HitObject,
                                                              ; HitObjectHard)

; The frames of the animated characters 252-255 on even passes: 4 x 8 bytes
; (AnimateCells)
AnimFramesA:
  DEFB $3E,$3E,$3E,$7F,$3E,$1C,$08,$00
  DEFB $00,$08,$1C,$3E,$7F,$3E,$3E,$3E
  DEFB $08,$1F,$3F,$7F,$3F,$1F,$08,$00
  DEFB $10,$F8,$FC,$FE,$FC,$F8,$10,$00
AnimFramesB:
  DEFB $00,$3E,$3E,$3E,$7F,$3E,$1C,$08 ; on odd passes
  DEFB $08,$1C,$3E,$7F,$3E,$3E,$3E,$00
  DEFB $10,$3E,$7E,$FE,$7E,$3E,$10,$00
  DEFB $08,$7C,$7E,$7F,$7E,$7C,$08,$00

; The rooms' object lists (RoomExits' words): a header [spawn sides: bit 7 top,
; 6 right, 5 left][spawn period] (ReadExits: no spawn kind in DEMO), then
; [kind][X][Y] records, $FF ends
RoomObjectLists:
  INCBIN "res/rooms/demo-objects.bin",$0000,69

; The exits of the rooms 0-5: up, right, down, left (0 none), then the word of
; the room's object list
RoomExits:
  INCBIN "res/rooms/demo-exits.bin",$0000,36

; Room 0's input script (TutorStep): the first count, then [input][count]
; pairs; input bits low = pressed: 0 fire, 1 up, 2 down (shield), 3 right, 4
; left
;
; 199 pairs, 698 passes. TutorScript1 $B1E7: 495 pairs, 1295 passes;
; TutorScript2 $B5C7: 309 pairs, 875 passes; TutorScript4 $B833: 327 pairs,
; 1005 passes. A script plays to its room's end (TutorNextRoom) or a death.
TutorScript0:
  DEFB $11,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$ED,$01,$ED,$01,$ED,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$04,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$0B,$FE
  DEFB $01,$FE,$17,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$E7,$01,$F7,$2E,$F6,$01,$F7,$01,$F6,$01,$F7,$01,$F6,$01,$F7
  DEFB $01,$F6,$01,$F7,$01,$F7,$01,$F6,$01,$F7,$01,$F6,$01,$F7,$01,$F6
  DEFB $01,$F7,$01,$F7,$01,$F6,$01,$F7,$56,$FE,$51,$FE,$01,$FE,$23,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$ED,$01,$ED,$01,$ED,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$03,$F7,$01,$F7,$01,$F7,$06,$F7,$57,$FE
  DEFB $2A,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$26,$FE,$20,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$04,$F7,$00,$00,$00,$00
TutorScript1:
  DEFB $0E,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF ; room 1's
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$05,$FE,$01,$FE,$02,$FE,$03,$FE,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$0A,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$E7,$01,$F7,$01,$F7,$01,$FE,$01,$FE,$02,$FE,$03,$FE,$03,$FE
  DEFB $03,$FE,$03,$FE,$02,$F7,$01,$F6,$03,$FE,$02,$FE,$01,$FE,$02,$FE
  DEFB $01,$FE,$02,$FE,$01,$FE,$03,$FD,$01,$FD,$01,$FD,$01,$FD,$0D,$F7
  DEFB $29,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$0D,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$FE,$01,$FE,$03,$FE,$02,$FE,$01,$FE
  DEFB $02,$FE,$01,$FE,$02,$FE,$03,$FE,$03,$FE,$02,$FE,$01,$FE,$03,$FD
  DEFB $01,$FD,$01,$FC,$01,$FE,$02,$FE,$01,$FE,$02,$FE,$01,$FE,$02,$FE
  DEFB $01,$FE,$03,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F5,$01,$F5,$01,$F5,$01,$F5,$0C,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F5,$01,$F5,$01,$F5,$11,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$08,$F7,$01,$F7,$01,$F5,$01,$F5,$01,$F7
  DEFB $15,$F7,$01,$F7,$01,$F7,$1E,$F7,$01,$F7,$01,$F7,$01,$F6,$01,$F6
  DEFB $01,$F7,$01,$F7,$01,$F6,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$03,$EF,$01,$EF,$01,$FE,$03,$FE,$03,$FE,$02,$FE
  DEFB $01,$EF,$01,$EE,$01,$EE,$01,$EF,$01,$EE,$02,$FE,$01,$FE,$03,$FD
  DEFB $01,$FC,$01,$FE,$02,$FE,$02,$FE,$03,$FE,$02,$FE,$02,$FE,$03,$FE
  DEFB $02,$FE,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$ED,$01,$ED,$01,$ED,$01,$ED,$01,$ED
  DEFB $0C,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$33,$ED,$01,$EC,$01,$EC
  DEFB $01,$EF,$01,$FE,$01,$FE,$02,$FE,$03,$FE,$02,$FE,$01,$EC,$01,$EC
  DEFB $01,$ED,$01,$EC,$01,$EC,$01,$ED,$02,$FE,$01,$FE,$03,$FE,$05,$FC
  DEFB $01,$FD,$04,$EE,$01,$EE,$01,$EF,$01,$EF,$01,$EE,$01,$FE,$03,$FE
  DEFB $01,$F7,$01,$F7,$01,$F6,$01,$F7,$01,$F7,$01,$FE,$02,$FE,$01,$FE
  DEFB $02,$FE,$01,$F7,$01,$F7,$01,$F7,$01,$F5,$01,$F5,$01,$F4,$03,$FE
  DEFB $02,$FE,$01,$FE,$02,$FE,$02,$FE,$02,$FE,$02,$FE,$05,$F6,$01,$F7
  DEFB $01,$F7,$01,$F6,$02,$FE,$02,$FE,$05,$FE,$07,$FE,$02,$FE,$0A,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F5,$01,$F5,$01,$F5,$01,$F5,$01,$F5
  DEFB $13,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$1E,$F7,$01,$F5,$01,$F5
  DEFB $01,$F5,$01,$F5,$01,$F5,$01,$F5,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F5,$01,$F5,$01,$F5,$01,$F5,$01,$F5,$01,$F5
  DEFB $01,$F5,$01,$F5,$01,$F5,$01,$F5,$01,$F5,$01,$F5,$01,$F5,$01,$F5
  DEFB $01,$F5,$01,$F5,$01,$F5,$01,$F7,$01,$F7,$01,$F7,$07,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$03,$FE,$03,$FE,$01,$FE,$06,$FE,$01,$FE,$03,$FE
  DEFB $02,$FE,$03,$FE,$03,$FE,$02,$FE,$02,$FE,$03,$FE,$2C,$FE,$03,$FE
  DEFB $02,$FE,$03,$FE,$02,$FE,$03,$FE,$02,$FE,$03,$FE,$02,$FE,$2B,$FE
  DEFB $03,$FE,$02,$FE,$03,$FE,$02,$FE,$03,$FE,$02,$FE,$03,$FE,$03,$FE
  DEFB $02,$FE,$03,$FE,$03,$FE,$2B,$EF,$01,$ED,$01,$EF,$09,$EF,$01,$EF
  DEFB $01,$EF,$01,$FE,$03,$FE,$01,$FE,$02,$F6,$01,$F6,$01,$F7,$01,$F6
  DEFB $01,$FE,$0A,$FD,$01,$FD,$01,$FC,$01,$FC,$01,$FC,$02,$FE,$01,$FE
  DEFB $03,$FE,$01,$FE,$03,$F7,$01,$F5,$01,$F4,$01,$F4,$01,$F4,$01,$F5
  DEFB $01,$F7,$01,$F6,$01,$FE,$05,$FE,$01,$FE,$08,$FD,$03,$F7,$01,$F7
  DEFB $01,$F7,$05,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$04,$FE,$03,$FE,$02,$FE,$01,$FE
  DEFB $24,$FE,$0F,$EF,$01,$EC,$01,$EC,$03,$FE,$01,$FE,$0C,$EF,$0E,$EF
  DEFB $06,$FE,$03,$FE,$02,$FE,$02,$FE,$03,$EF,$01,$ED,$01,$EC,$01,$EC
  DEFB $03,$FE,$03,$FE,$01,$F7,$01,$F7,$01,$F6,$02,$FE,$03,$FE,$0A,$FD
  DEFB $01,$F5,$01,$F5,$01,$FD,$08,$FD,$01,$F5,$01,$F5,$01,$F5,$01,$F7
  DEFB $0E,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$ED
  DEFB $01,$ED,$14,$FD,$01,$FD,$09,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$ED,$01,$ED,$01,$EF,$10,$EF,$01,$EF,$01,$ED,$01,$ED
  DEFB $01,$EF,$10,$F7,$01,$F7,$06,$F7,$00,$00,$00,$00,$00,$00,$00,$00
TutorScript2:
  DEFB $0B,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7 ; room 2's
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F5,$01,$F5,$01,$F7,$08,$EF
  DEFB $0C,$FE,$01,$FE,$10,$FE,$01,$FE,$15,$FE,$02,$FE,$02,$FE,$02,$FE
  DEFB $18,$FE,$01,$FE,$08,$FE,$01,$FE,$20,$FB,$01,$EF,$01,$ED,$01,$ED
  DEFB $01,$ED,$01,$EF,$0F,$F7,$01,$F7,$01,$F7,$05,$FD,$01,$F5,$01,$F5
  DEFB $01,$FD,$01,$FD,$0D,$EF,$01,$EF,$01,$EF,$02,$FB,$02,$FD,$01,$FD
  DEFB $03,$FE,$02,$FE,$03,$FE,$2A,$FE,$01,$FE,$0B,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $07,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F5,$0D,$FD,$01,$FD,$04,$F7,$09,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$06,$F7,$12,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$02,$EF,$01,$EF
  DEFB $01,$EF,$07,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$2E,$F7,$08,$FE,$01,$FE,$01,$FE,$01,$FE
  DEFB $01,$FE,$01,$FE,$01,$FE,$01,$FE,$08,$FC,$01,$FC,$01,$FC,$01,$FC
  DEFB $01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC
  DEFB $01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC
  DEFB $01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC,$01,$FC
  DEFB $01,$FC,$01,$FD,$05,$FE,$01,$FE,$01,$FE,$0A,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F5,$01,$F5,$01,$F5,$01,$F5,$01,$FD,$07,$F5,$01,$F5
  DEFB $01,$F5,$01,$F5,$01,$F5,$01,$F5,$01,$F5,$0C,$ED,$01,$ED,$01,$ED
  DEFB $01,$ED,$0B,$F5,$01,$F5,$01,$F5,$01,$FD,$10,$FD,$01,$FD,$01,$FD
  DEFB $11,$FD,$01,$FD,$01,$FD,$12,$FD,$01,$FD,$04,$FE,$01,$FE,$01,$FE
  DEFB $01,$FE,$01,$FE,$01,$FE,$01,$FE,$3F,$F5,$01,$F5,$15,$F7,$01,$F5
  DEFB $01,$F5,$01,$FD,$1D,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$19,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$0E,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
TutorScript4:
  DEFB $01,$F7,$69,$FD,$01,$FD,$01,$FD,$04,$F7,$01,$F7,$01,$F7,$08,$FD ; room 4's
  DEFB $0A,$EF,$01,$EF,$01,$EF,$12,$FD,$01,$FD,$0A,$EF,$01,$EF,$01,$EF
  DEFB $01,$ED,$01,$ED,$01,$ED,$04,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$03,$FE,$02,$FE,$02,$FE,$02,$FE,$02,$FE,$01,$FE,$03,$FE
  DEFB $03,$FE,$02,$FE,$02,$FE,$1A,$FB,$02,$ED,$01,$ED,$01,$ED,$02,$F7
  DEFB $02,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$ED,$01,$ED,$01,$ED,$01,$ED,$01,$EF,$01,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$08,$FE,$02,$FE,$01,$FE
  DEFB $02,$FE,$05,$FB,$04,$FD,$02,$FE,$02,$FE,$03,$FE,$01,$FE,$05,$FE
  DEFB $01,$FE,$02,$FE,$01,$FE,$01,$FE,$06,$FD,$03,$FE,$01,$FE,$02,$FE
  DEFB $01,$FE,$02,$FE,$0B,$ED,$01,$ED,$0C,$F7,$01,$F5,$01,$F5,$0D,$ED
  DEFB $01,$ED,$01,$FD,$15,$F7,$06,$FD,$01,$FD,$01,$FD,$02,$F7,$07,$F7
  DEFB $01,$F7,$10,$FD,$03,$FE,$02,$FE,$02,$FE,$03,$FE,$02,$FD,$01,$FD
  DEFB $02,$FE,$02,$FE,$02,$FE,$01,$FE,$01,$FE,$07,$FD,$03,$FE,$02,$FE
  DEFB $01,$FE,$02,$FE,$0F,$FD,$01,$FD,$02,$FE,$02,$FE,$01,$FE,$02,$FE
  DEFB $0A,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F5,$01,$F5,$0E,$F5
  DEFB $01,$F5,$01,$F5,$0D,$FE,$01,$FE,$02,$FE,$02,$FE,$02,$FE,$03,$FE
  DEFB $02,$FE,$02,$FE,$03,$FE,$02,$FE,$02,$FE,$01,$FE,$02,$FE,$01,$FE
  DEFB $02,$FE,$03,$FE,$03,$FE,$03,$FE,$02,$FE,$02,$FE,$03,$FE,$03,$FE
  DEFB $03,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F3
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F3,$01,$F3,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $0E,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$04,$EF,$01,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$07,$F7,$04,$FE,$02,$FE,$02,$FE,$02,$FE,$02,$FE
  DEFB $02,$FE,$03,$FE,$02,$FE,$03,$FE,$02,$FE,$01,$FE,$03,$FE,$04,$FE
  DEFB $03,$FE,$18,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F3,$01,$F3,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$27,$FD
  DEFB $01,$ED,$01,$ED,$01,$ED,$01,$F7,$02,$EF,$02,$F7,$06,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F5,$01,$F5,$01,$F5,$0E,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$90,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F5,$01,$F5,$01,$F5,$01,$F5
  DEFB $01,$F5,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F5,$01,$F5,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7
  DEFB $01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$01,$F7,$07,$EF,$01,$EF
  DEFB $01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF,$01,$EF
