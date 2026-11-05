; --------------------------------------------------------------------------------------------------------------------
; scoredata.asm: The points, the high-score table and the menu colour lists
;
; The award table AddScore reads, the five high scores (a print string and a BCD score each) and the run-length colour
; lists of the menu raster.
; --------------------------------------------------------------------------------------------------------------------

; 12 awards x 4 BCD bytes: 0 25 50 75 100 150 200 250 500 1000 2000 5000
;
; AddScore $A489 adds entry A from $8234 + 4A down (48K c2: 9 entries reading
; $8235-$823C: 25 and 50).
PointsTable:
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$25
  DEFB $00,$00,$00,$50
  DEFB $00,$00,$00,$75
  DEFB $00,$00,$01,$00
  DEFB $00,$00,$01,$50
  DEFB $00,$00,$02,$00
  DEFB $00,$00,$02,$50
  DEFB $00,$00,$05,$00
  DEFB $00,$00,$10,$00
  DEFB $00,$00,$20,$00
  DEFB $00,$00,$50,$00

; The high-score table: 5 entries of a print string (position, initials) and a
; 4-byte BCD score
;
; PrintString $A401 prints the strings, PrintBcd ($A43E) the scores;
; HighScoreEntry inserts a new one. The editable text:
; src/res/text/hiscores.hsc.txt.
HiScoreTable:
  INCBIN "res/text/hiscores.bin",$0000,70

; A run-length colour list: 48 lines into $FC20 (MenuScreenSetup $A692,
; SelectPlayers $A799)
ColoursTop:
  DEFB $86,$00,$02,$42,$42,$06,$46,$46,$46,$47,$47,$47,$47
  DEFB $47,$47,$46,$46,$46,$06,$42,$06,$46,$46,$46,$47,$47
  DEFB $47,$47,$88,$00,$07,$07,$45,$05,$44,$04,$04,$04,$FF

; 120 lines into $FC50 (MenuScreenSetup $A69D)
ColoursMenu:
  DEFB $07,$07,$46,$06,$06,$43,$42,$42,$FF

; 64 lines into $FC50 (SelectPlayers $A7A8, RedefineKeys $A5D5)
ColoursHighlight:
  DEFB $07,$07,$45,$05,$43,$43,$03,$03,$FF

; The sweeping bar of SelectPlayers ($A7BB); its $FF at $82ED is also the
; message list's start
ColoursBar:
  DEFB $42,$83,$06,$46,$46,$85,$47,$46,$46,$06,$06,$42,$00
MessageListBase:
  DEFB $FF                ; the $FF before message 0 (PrintMessage $A427 counts
                          ; A + 1 $FF bytes from here)
