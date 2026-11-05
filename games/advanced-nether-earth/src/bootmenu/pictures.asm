; --------------------------------------------------------------------------------------------------------------------
; pictures.asm: the help's pictures and the boot menu's (Hrust 1 streams)
;
; Fourteen whole screens packed by Hrust 1 (ScreenDepack, depack.asm), each followed by one byte nothing reads.
; src/res/bootmenu/pictures holds them as PNG; the build packs them back to these bytes (tools/bootmenu_hrust.py). The
; eight of help item 3 (HelpComponents) show one robot part a page; the others one help item's pages each, the help
; menu and the boot menu.
; --------------------------------------------------------------------------------------------------------------------

; help item 3, page 1: "ЭЛЕКТРОНИКА"
ElectronicsPicture:
  INCBIN "res/pictures/electronics.hrust",$0000,1083

; never read
ElectronicsPictureSpare:
  DEFB $18

; help item 3, page 3: "ФАЗОРЫ"
PhasersPicture:
  INCBIN "res/pictures/phasers.hrust",$0000,886

; never read
PhasersPictureSpare:
  DEFB $C0

; help item 3, page 4: "РАКЕТЫ"
MissilesPicture:
  INCBIN "res/pictures/missiles.hrust",$0000,865

; never read
MissilesPictureSpare:
  DEFB $00

; help item 3, page 6: "АНТИГРАВЫ"
AntigravPicture:
  INCBIN "res/pictures/antigrav.hrust",$0000,1011

; never read
AntigravPictureSpare:
  DEFB $00

; help item 3, page 7: "ТРАКИ"
TracksPicture:
  INCBIN "res/pictures/tracks.hrust",$0000,933

; never read
TracksPictureSpare:
  DEFB $FF

; help item 3, page 8: "БИПОДЫ"
BipodsPicture:
  INCBIN "res/pictures/bipods.hrust",$0000,965

; never read
BipodsPictureSpare:
  DEFB $FF

; the help menu: the title, seven bars, the woman with the gun, the colour band
;
; The bars are empty: HelpMenu prints the items into them.
HelpMenuPicture:
  INCBIN "res/pictures/help-menu.hrust",$0000,3144

; never read
HelpMenuPictureSpare:
  DEFB $AA

; help item 5 "Особенности игры": a map, "Advises"
FeaturesPicture:
  INCBIN "res/pictures/features.hrust",$0000,985

; never read
FeaturesPictureSpare:
  DEFB $00

; help item 6 "CREDITZ": a computer and a book
CreditsPicture:
  INCBIN "res/pictures/credits.hrust",$0000,971

; never read
CreditsPictureSpare:
  DEFB $0C

; help item 3, page 5: "ПУШКИ"
CannonsPicture:
  INCBIN "res/pictures/cannons.hrust",$0000,951

; never read
CannonsPictureSpare:
  DEFB $00

; help item 2 "Производство роботов": a satellite, a purple craft, cables
ProductionPicture:
  INCBIN "res/pictures/production.hrust",$0000,965

; never read
ProductionPictureSpare:
  DEFB $BF

; help item 4 "Программирование роботов": a computer desk on a chequered floor,
; "Programming"
ProgrammingPicture:
  INCBIN "res/pictures/programming.hrust",$0000,1451

; never read
ProgrammingPictureSpare:
  DEFB $00

; help item 3, page 2: "АТОМНАЯ БОМБА"
BombPicture:
  INCBIN "res/pictures/bomb.hrust",$0000,797

; never read
BombPictureSpare:
  DEFB $00

; the boot menu: the "Адская Земля" logo, "Boot Menu: 1-Game 2-Help 3-NOT used"
BootMenuPicture:
  INCBIN "res/pictures/boot-menu.hrust",$0000,1542

; never read
BootMenuPictureSpare:
  DEFB $00
