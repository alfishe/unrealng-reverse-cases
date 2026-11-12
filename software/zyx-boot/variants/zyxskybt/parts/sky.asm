; ZYX boot, variant zyxskybt (Skynet Games): its picture, bars, scroller and set-up, loaded at $6FE0-$79A7.
; Written by kit/mkgame.py from variants/zyxskybt/parts/sky.ann; edit sky.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Addresses outside this image (@equ in the annotations)
BarRows        EQU $4046  ; the screen bytes the bars wave: 24 pixel rows of 19 bytes from column 6
PictureScreen  EQU $5066  ; the picture's screen place: pixel row 152 (char row 19), column 6
ScrollRow      EQU $5694  ; the scroller's window: 10 bytes ending here (columns 11-20), 16 pixel rows from line 6 of char row 20, inside the picture's window
PictureAttrs   EQU $5A66  ; the picture's attributes: rows 19-23, columns 6-25
MoveStarsLoaded EQU $648F  ; MoveStars after it loaded HL (src/main/stars.asm)
MoveStarsHidden EQU $64AC  ; MoveStars' path for a star it does not draw (code switch sky-stars)
CyrillicGlyphs EQU $9900  ; the glyph base for codes $60-$7F (CyrillicFont copied to $9C00 = $9900 + $60 x 8)
CyrillicCopy   EQU $9C00  ; where SkyScrollSetup copies CyrillicFont
MenuFont       EQU $A600  ; where the menu's font loads (src/main/font.asm FontBase + $100)
FontGlyphs     EQU $A884  ; the menu font's base once SkySetup moved it to $A984 (code $20 at $A984)
ScrollVars     EQU $A974  ; the scroller's variables (IX): +0/+1 the text pointer, +2 the pixel columns of this letter done (0-16), +3/+4 the glyph row pointer, +5 the glyph bit mask, +6/+7 the glyph base for $60-$7F, +8..+11 the two markers' screen addresses, +12 the gap counter, +13 its start ($AA)
MenuFontMoved  EQU $A984  ; where SkySetup moves it, out of the scroller's way
MusicPlay      EQU $C001  ; the Sound Tracker player's frame entry (the music piece at $BFFB)

; the picture and the Cyrillic font, run where they load: $6FE0-$74A6
  ORG $6FE0
  INCLUDE "sky/skypicture.asm"  ; The Skynet picture, its attributes, its drawing and the Cyrillic font

; the bars, copied to and run at $FE0D: $74A7-$7518, run at $FE0D
  ORG $74A7
SkyBarsLoad:
  DISP $FE0D
  INCLUDE "sky/skybars.asm"  ; The waving bars
  ENT

; the scroller, copied to and run at $A500: $7519-$78DC, run at $A500
  ORG $7519
SkyScrollerLoad:
  DISP $A500
  INCLUDE "sky/skyscroller.asm"  ; The scroll text and the code SkySetup copies to $A500
  ENT

; the set-up, run where it loads: $78DD-$79A7
  ORG $78DD
  INCLUDE "sky/skysetup.asm"  ; Set the Skynet screen up

  SAVEBIN "sky.bin",$6FE0,2504
