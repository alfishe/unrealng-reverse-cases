; --------------------------------------------------------------------------------------------------------------------
; stageload.asm: The stage loader
;
; LoadStage loads the turbo block of the stage C (LoadBlock and TurboLoad), unless it is already in memory. Every
; turbo block has the flag $56 and the stage blocks have one length, so the loader takes whichever stage block comes
; next on the tape; LoadBlock then compares the block's byte at StageCheckByte with StageCheck for the stage wanted. A
; wrong block gives NZ: PlayStage marks no stage loaded and loads again, with no message. So a tape wound on to
; another stage loads that stage's block, rejects it and waits for the next block; only the stage wanted is accepted,
; and the stage wanted moves on only when a stage is completed.
; --------------------------------------------------------------------------------------------------------------------

  ORG $F5E4

; Load stage C's block (B, H, L its length) unless it is the one loaded; Z when
; it is in memory
;
; Inputs: C the stage (0 the front), B, H, L the length parameters (to
; LoadLength). StageLoaded = C: wait 120 frames, Z. Else StageLoaded := C,
; HALT, LoadBlock; NZ (a wrong block or a load error) returns NZ; else clear
; the line, STOP THE TAPE, WaitFrames, Z. Witness: L1 8 (c1, joystick, menu,
; stageload, rzx-r0, rzx-r1).
LoadStage:
  LD A,B
  LD (LoadLengthB),A
  LD A,H
  LD (LoadLength),A
  LD A,L
  LD (LoadLengthL),A
  LD A,(StageLoaded)
  CP C
  JR Z,LoadStageLoaded
  LD A,C
  LD (StageLoaded),A
  HALT
  CALL LoadBlock
  RET NZ
  CALL Print              ; Print: the text follows

; The text: column 0, bit 0, row 36, a space
TextClearTop:
  INCBIN "res/resident/text-clear-top.bin",$0000,5

; LoadStage2
LoadStage2:
  CALL Print

; The text: column byte 10, bit 3, row 52, STOP THE TAPE
TextStopTape:
  INCBIN "res/resident/text-stop-tape.bin",$0000,17

; WaitFrames, then Z
LoadStage3:
  CALL WaitFrames
  LD A,$00
  CP $00
  RET
; This entry point is used by the routine at LoadStage.
LoadStageLoaded:
  LD BC,$0078             ; already in memory: 120 frames, Z
  JP WaitBC

  ORG $FF54

; Load the next block with TurboLoad; with a stage wanted, check its byte at
; StageCheckByte; Z when right
;
; DI; Im2Jump := SavedLoaderBytes (the loader's code); TurboLoad;
; SaveLoaderBytes; SetIm2 (Im2Handler). StageLoaded 0 (the front): Z. Else Z
; when the byte at StageCheckByte equals StageCheck's for StageLoaded, NZ for
; another stage's block. A load error does not return here: TurboExit's RST 8
; ends in the ROM's error report. Witness: L1 7 (c1, joystick, menu, stageload,
; rzx-r0, rzx-r1).
LoadBlock:
  DI
  LD HL,SavedLoaderBytes
  LD DE,Im2Jump
  LD BC,$0003
  LDIR
  CALL TurboLoad
  CALL SaveLoaderBytes
  LD HL,Im2Handler
  CALL SetIm2
  LD A,(StageLoaded)
  CP $00
  RET Z
  LD C,A
  LD B,$00
  LD HL,StageCheckFront
  ADD HL,BC
  LD A,(StageCheckByte)
  CP (HL)
  RET

; Unused slot 0 of StageCheck (the front is not checked)
StageCheckFront:
  DEFB $00

; The byte at StageCheckByte of stages 1-5: $16, $4B, $FA, $E0, $80
;
; Read by LoadBlock (c1: stage 1; sN-right: stages 2-5). Each value is the
; stage block's byte at $BB80 (work/mkgame/stageN.bin).
StageCheck:
  DEFB $16,$4B,$FA,$E0,$80
