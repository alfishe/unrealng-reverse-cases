; --------------------------------------------------------------------------------------------------------------------
; introtext.asm: the scroller's text
;
; The text ScrollStep shows, $DAC2-$E3B8: KOI-7 N2 letters ($40-$7F drawn as Cyrillic by IntroFont), $01 LO HI font
; switches ($3D00, the ROM's font, for the Latin names), $00 at the end followed by the address the scroller goes on
; from (ScrollTextLoop: the last "Press something..." is repeated until a key). src/res/intro98/scroll-text.txt is the
; UTF-8 copy the build turns back into these bytes; the translation is in work/stage1/texts.md, section 6. The
; window's run read $DAC2-$DBCF (the text up to where the key was pressed at frame 4203).
; --------------------------------------------------------------------------------------------------------------------

; the scroller text (src/res/intro98/scroll-text.txt)
;
; Signed "ZS. 23.12.1998": Sergey Zotov's greetings, the story of the edition,
; what he changed in the game, his phone and e-mail, the greetings; it ends
; with "Нажмите что-нибудь..." (press something), from ScrollTextLoop on again
; and again.
ScrollText:
  INCBIN "res/intro98/scroll-text.bin",$0000,2295
