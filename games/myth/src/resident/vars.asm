; --------------------------------------------------------------------------------------------------------------------
; vars.asm: The resident's variables
; --------------------------------------------------------------------------------------------------------------------

  ORG $F9A8

; TextToBuffer's bit within the column byte (also a scratch word with TextRow
; for RevealText and the stages)
BitShift:
  DEFB $00

; Print's pixel row
TextRow:
  DEFB $00

; The current glyph's width mask
CharMask:
  DEFB $00

; RevealText's place in ScreenLineTable
RowPointer:
  DEFW $0000

; The game's credits: 4 at NewGame, one less a game over
Credits:
  DEFB $00

; The stage in memory (0 the front, $FF none)
StageLoaded:
  DEFB $00

; The lives, passed to each stage in H and back
Lives:
  DEFB $00

  ORG $F9C9

; Zeros no code reads (known only from the code)
DecimalTablePad:
  DEFB $00,$00

  ORG $F9FE

; Zeros (known only from the code)
ResidentVarsPad:
  DEFB $00,$00

  ORG $FE01

; The work space of the front and the stages (zeros in the tape's image)
;
; The front: SavedIm2Jump, SavedStack, SavedReturn, ShimmerCount, ReaderBitOp,
; ReaderPort (src/front). The stages: $FE08-$FE6F (src/stageN). The resident's
; own: GameOverOption and FrameCounter.
WorkSpace:
  DEFB $00,$00,$00
SavedStack:
  DEFB $00,$00
SavedReturn:
  DEFB $00,$00
StageVars:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00
ShimmerCount:
  DEFB $00
GameOverOption:
  DEFB $00                ; GameOver's highlighted line, 0 or 1
StageVars2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00
FrameCounter:
  DEFB $00                ; CycleColours' frame count
StageVars3:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
ReaderBitOp:
  DEFB $00
ReaderPort:
  DEFB $00,$00
StageVars4:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00
