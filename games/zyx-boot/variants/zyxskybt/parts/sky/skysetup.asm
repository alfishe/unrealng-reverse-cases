; --------------------------------------------------------------------------------------------------------------------
; skysetup.asm: Set the Skynet screen up
; --------------------------------------------------------------------------------------------------------------------

; Called by DrawScreen in place of printing the help text (code switch
; sky-screen): draw the picture, move the font, copy the bars and the scroller,
; set the scroller up
;
; The menu font moves from MenuFont $A600 to MenuFontMoved $A984 and
; $A600-$A983 is cleared (LD (HL),L: L is 0); the bars go to $FE0D, the
; scroller's code and text to $A500; then JP SkyScrollSetup. The variant's
; switch sky-screen points the menu at the moved font (FontBase $A884).
SkySetup:
  CALL DrawSkyPicture
  LD HL,MenuFont
  LD DE,MenuFontMoved
  LD BC,$0300
  LDIR
  LD HL,MenuFont
  LD DE,$A601
  LD BC,$0384
  LD (HL),L
  LDIR
  LD HL,SkyBarsLoad
  LD DE,SkyBars
  LD BC,$0072
  LDIR
  LD HL,SkyScrollerLoad
  LD DE,ScrollText
  LD BC,$03C4
  LDIR
  JP SkyScrollSetup

; zeros to the end of the loader's 24 sectors
SetupSpare:
  DEFS $98
