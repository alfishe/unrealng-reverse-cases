; Myth: History in the Making, System 3 Software 1989: the resident part $F000-$FFFF, as Boot $5B00 copies it there; the stage blocks
; load over $F000-$F03E, the rest stays from the load to the end.
; Written by kit/mkgame.py from src/resident/resident.ann and the recordings; edit resident.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (stage1.ann @equ)
Screen         EQU $4000  ; the bitmap
Attributes     EQU $5800  ; the attributes
TextBuffer     EQU $5B00  ; TextToBuffer's line of text, 32 bytes a pixel row, 8 rows
GlyphBuffer    EQU $5D00  ; one glyph shifted into place, 2 bytes a row
GameBlock      EQU $6C3F  ; where every turbo block loads: the front ($6C3F-$A83E) or a stage ($6C3F-$F03E)
GameMain       EQU $7800  ; the front's FrontMain and each stage's entry (src/front, src/stageN)
StageCheckByte EQU $BB80  ; the byte of a loaded stage block that names it (StageCheck)
  ORG $F000
  INCLUDE "init.asm"  ; Start-up: silence, the IM 2 set-up, the front
  INCLUDE "game.asm"  ; The game: the stage chain, PlayStage, the game over menu
  INCLUDE "print.asm"  ; Text and screen: the proportional print, the reveal, the attribute boxes, the colour cycle, the screen clear, the dissolve masks
  INCLUDE "ay.asm"  ; The AY driver: the effects and the three channels
  INCLUDE "stageload.asm"  ; The stage loader
  INCLUDE "im2.asm"  ; The IM 2 set-up, the handler and the table
  INCLUDE "font.asm"  ; The print font
  INCLUDE "vars.asm"  ; The resident's variables
  INCLUDE "score.asm"  ; The score: the decimal table and the score variables (the stages print it)
  INCLUDE "tables.asm"  ; The tables the stages share: bit reversal, screen lines
  INCLUDE "keys.asm"  ; The key readers
  INCLUDE "turbo.asm"  ; The turbo loader

  SAVEBIN "resident.bin",$F000,$1000
