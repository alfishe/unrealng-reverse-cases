; --------------------------------------------------------------------------------------------------------------------
; texts.asm: Texts and small tables in the pixel shadow's spare halves
;
; The pixel shadow (the play field drawn off screen) is laid out like the screen at $6000-$77FF; the play field is 20
; character rows, so in its third third only the first 128 bytes of each 256-byte pixel line are used ($7000-$707F,
; $7100-$717F, ... $7700-$777F) and the game keeps its texts, small tables and some code in the other halves. A text
; ends at the byte with bit 7 set (PrintText $C081, PrintTextNormal $C084).
; --------------------------------------------------------------------------------------------------------------------

; The pixel shadow, third third, pixel line 0 (128 bytes)
;
; Written and read by the sprite drawers (DrawSprite and its three variants)
; and copied to the screen by ScrollRows. Zeros at the entry.
ShadowLine0:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; "PRESS A KEY FOR " and the six key names DefineKeys prints
KeyPromptText:
  DEFM "PRESS A KEY FOR",$A0
KeyNameLeft:
  DEFM "LEF",$D4          ; "LEFT"
KeyNameRight:
  DEFM "RIGH",$D4         ; "RIGHT"
KeyNameUp:
  DEFM "UP  ",$A0         ; "UP"
KeyNameDown:
  DEFM "DOW",$CE          ; "DOWN"
KeyNameFire:
  DEFM "FIR",$C5          ; "FIRE"
KeyNameDetach:
  DEFM "DETAC",$C8        ; "DETACH"

; "PILOT STAND BY $": printed after a life is lost
PilotStandByText:
  INCBIN "res/texts/pilot-stand-by.bin",$0000,17

; "MISSION OVER $": printed when the last life is gone
MissionOverText:
  INCBIN "res/texts/mission-over.bin",$0000,14

; "C O N T I N U E" over the countdown
ContinueText:
  INCBIN "res/texts/continue.bin",$0000,15

; '@': a full step of the BEAM meter
BeamMeterFull:
  DEFM "@"+$80

; '>': the step being filled
BeamMeterStep:
  DEFM ">"+$80

; The score awards: 10 pairs (place, digit) AwardScore hands to AddScore
;
; Indexed by the low nibble of an enemy kind's byte 2 less 1: place 3 with the
; digits 1-9, then place 4 with 1 (100-900 and 1000 points; known only from the
; code and the score in the level recordings).
ScoreAwards:
  INCBIN "res/tables/score-awards.bin",$0000,20

; zeros up to the next shadow line
ShadowLine0Tail:
  DEFB $04,$05,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The pixel shadow, third third, pixel line 1
ShadowLine1:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; "HI SCORE" on the HUD
HiScoreLabel:
  INCBIN "res/texts/hi-score.bin",$0000,8

; "BEAM-" on the HUD
BeamLabel:
  INCBIN "res/texts/beam.bin",$0000,5

; '%': the ship icon DrawLives repeats once a life
LifeChar:
  DEFM "%"+$80

; a space: DrawLives' end
BlankChar:
  DEFM " "+$80

; "R TYPE LEVEL 0 ": the digit is the level LoadLevel searches for
LevelText:
  DEFM "R TYPE LEVEL "
LevelDigit:
  DEFM "0",$A0            ; the level's ASCII digit

; "LOADED OK"
LoadedOkText:
  INCBIN "res/texts/loaded-ok.bin",$0000,9

; "STOP TAPE"
StopTapeText:
  INCBIN "res/texts/stop-tape.bin",$0000,9

; "START TAPE"
StartTapeText:
  INCBIN "res/texts/start-tape.bin",$0000,10

; "LOADING"
LoadingText:
  INCBIN "res/texts/loading.bin",$0000,7

; the eight characters of a pick-up carrier's animation (k l m n o n m l),
; NextCarrierFrame
CarrierFrames:
  DEFB $6B,$6C,$6D,$6E,$6F,$EE,$ED,$EC

; the score: six ASCII digits and the space that ends the text
;
; AddScore adds into it digit by digit; PrintScore prints it; InsertHiScore
; compares it with the table.
ScoreText:
  DEFM "000000",$A0

; scratch flags of the score and the name entry
ScoreDirty:
  DEFB $00
FirstPlay:
  DEFB $00                ; 0 before the first play: StartPlay gives the fly-in
                          ; once
NameLetter:
  DEFB $A0                ; the letter the name entry is on
NamePos:
  DEFB $00                ; the place in the name being typed
ForceShotsA:
  DEFB $00,$00,$00,$00,$00,$00 ; the reflect laser's shot pairs, 3 bytes a shot
                               ; (in ClearList: 12 bytes)
ForceShotsB:
  DEFB $00,$00,$00,$00,$00,$00 ; the second pair
HitCellCount:
  DEFB $00                ; the soft cells ($FA) gathered this frame, the index
                          ; into HitCells
HitCells:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the (column, row) of each soft cell
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; gathered
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00

; The pixel shadow, third third, pixel line 2
ShadowLine2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; "REWIND SIDE 2 THEN PRESS ANY KEY"
RewindSide2Text:
  INCBIN "res/texts/rewind-side-2.bin",$0000,32

; "SEARCHING FOR " (then LevelText)
SearchingText:
  INCBIN "res/texts/searching.bin",$0000,14

; "ERROR IN LOADING"
ErrorInLoadingText:
  INCBIN "res/texts/error-in-loading.bin",$0000,16

; "C R E D I T  5 ": the credits left
CreditText:
  DEFM "C R E D I T  "
CreditDigit:
  DEFM "5",$A0            ; '5' at the start; a continue spends one

; "PRESS FIRE BUTTON"
PressFireText:
  INCBIN "res/texts/press-fire.bin",$0000,17

; ten '<': the empty BEAM meter
BeamMeterEmpty:
  INCBIN "res/texts/beam-meter-empty.bin",$0000,10

; the countdown's work bytes
ContinueData:
  DEFB $40,$0C,$D0
ContinueRow:
  DEFB $02,$50,$00,$00,$00 ; the countdown's colour row, read and written by
                           ; Continue

; the bit masks $10, 8, 4, 2, 1 ReadKey turns a half-row bit into
KeyBitTable:
  DEFB $10,$08,$04,$02,$01

; bytes CarrierDraw reads by the carrier's kind
CarrierColours:
  DEFB $46,$45,$45,$46,$42,$47,$44

; zeros
ShadowLine2Tail:
  DEFB $00,$00,$00,$00

; The pixel shadow, third third, pixel line 3
ShadowLine3:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; the title's star states (2 bytes a star) the star task uses while the title
; runs
TitleStars:
  DEFB $03,$1E,$01,$0C,$00,$19,$02,$00
  DEFB $02,$08,$01,$1C,$03,$17,$00,$03
  DEFB $01,$12,$01,$1D,$00,$0C,$00,$19
  DEFB $02,$01,$03,$1A,$00,$14,$02,$10
  DEFB $01,$08,$01,$1C,$01,$10,$01,$18

; "()*+ ": unused (known only from the code: nothing reads it)
StarChars:
  DEFM "()*+",$A0

; six bytes TitleLogo reads
CollapseColumns:
  DEFB $01,$06,$0B,$10,$15,$1A

; '1'-'9': the place digits of the high-score table
DigitChars:
  DEFM $B1,$B2,$B3,$B4,$B5,$B6,$B7,$B8,$B9
