; --------------------------------------------------------------------------------------------------------------------
; init.asm: Start-up: silence, the IM 2 set-up, the front
;
; Boot jumps to ResidentEntry. ResidentInit silences the AY, saves the turbo loader's bytes under the IM 2 jump, sets
; IM 2 with Im2Handler, marks no stage loaded and loads the front, then runs it. The front returns into NewGame when
; START GAME is chosen.
; --------------------------------------------------------------------------------------------------------------------

; Border black, SP = $FFFF, silence, IM 2 on Im2Handler, no stage loaded, then
; the front
;
; Run once, from ResidentEntry (c1: the front loads after it; the stage blocks
; overwrite $F000-$F03E later, so ResidentInit is gone once a stage is loaded
; and the restart path goes to RestartFromStageOne instead). StageLoaded := $FF
; (none).
ResidentInit:
  XOR A
  OUT ($FE),A
  LD SP,$FFFF
  CALL SilenceAy
  CALL SaveLoaderBytes
  LD HL,Im2Handler
  CALL SetIm2
  LD A,$FF
  LD (StageLoaded),A
  JR ShowFront            ; to ShowFront

; Zeros up to ResidentEntry, overwritten by every stage block
;
; No code reads them: the stage blocks load $6C3F-$F03E over them (their last
; bytes, the stages' own). Known only from the code and tape.txt.
ResidentInitPad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00

; Interrupts off, then ResidentInit
;
; Boot's JP (HL) lands here (c1). Witness: L1 1 (c1).
ResidentEntry:
  DI
  JR ResidentInit

; Clear the screen and load the front
;
; Witness: L1 1 (c1).
ShowFront:
  CALL ClearScreen
  JR LoadFront

; REWIND THE TAPE, AND THEN PRESS PLAY, wait, then load the front again
;
; GameOver's second option (RESTART FROM STAGE ONE) jumps here: the front is
; the tape's first turbo block, so the tape has to go back. Not executed in any
; recording (the recordings checked: no game over chose it); known only from
; the code ($F2EE).
RestartFromStageOne:
  CALL ClearScreen
  CALL Print              ; Print: the text follows

; The text: column byte 9, bit 3, row 36, REWIND THE TAPE
TextRewind:
  INCBIN "res/resident/text-rewind.bin",$0000,19

; Print the second line
RestartFromStageOne2:
  CALL Print

; The text: column byte 7, bit 5, row 52, AND THEN PRESS PLAY
TextPressPlayAgain:
  INCBIN "res/resident/text-press-play-again.bin",$0000,23

; WaitFrames, then into LoadFront
RestartFromStageOne3:
  CALL WaitFrames

; Load the front (stage 0: B 3, H 2, L 1, 30 pages of 512 bytes) and run it
;
; LoadStage with C = 0: StageLoaded := 0, so LoadBlock does not check the
; block. Then CALL GameMain: the front; START GAME returns to NewGame below.
; Witness: L1 1 (c1).
LoadFront:
  LD C,$00
  LD D,$1E
  LD E,$08
  LD B,$03
  LD H,$02
  LD L,$01
  CALL LoadStage
  CALL GameMain              ; the front; START GAME comes back here
