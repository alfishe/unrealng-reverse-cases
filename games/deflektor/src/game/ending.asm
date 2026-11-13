; --------------------------------------------------------------------------------------------------------------------
; ending.asm: The ending after level 60
; --------------------------------------------------------------------------------------------------------------------

  ORG $A8CE

; The ending: CONGRATULATIONS ..., the plug and the kettle joined by the cable,
; the tea, PRESS ANY KEY
;
; Called by `$87F3` (at `$8893`) after level 60, the buffers cleared (`$8885`).
; Prints EndingText (`$8E3A`) into the buffers, shows them (`$8B9B`), waits 16
; x `$8908`, draws EndingPlug at row 13 column 4 (2 x 16) and EndingKettle at
; row 12 scan line 4, column 25 (3 x 20) straight on the screen, waits 12,
; plays `$81F2`, draws the cable (two pixel rows of 19 bytes `$FF`: `$4FA6` and
; `$48C6`, row 13 line 7 and row 14 line 0, columns 6-24), waits 4, then sets
; the attributes of rows 17-18 to 7 and of row 23 columns 2-29 to 4: the lines
; printed in attribute 0 (THE TEA WILL BE READY IN FIVE MINUTES!, PRESS ANY
; KEY) appear.
;
; The joke: the circuit is a mains cable from the plug to an electric kettle.
;
; Evidence: ran once, `rzx-344752` (the RZX run's ending; screen 750).
;
; Witness: L1 2 (ending, rzx344752).
EndingScreen:
  LD HL,EndingText
  CALL PrintFull
  CALL CopyFullScreen
  LD A,$10
EndingWaitLoop:
  CALL Delay
  DEC A
  JR NZ,EndingWaitLoop
  LD HL,EndingPlug        ; the plug, rows 13-14 column 4
  LD DE,Screen+2212
  LD B,$08
EndingPlugTopLoop:
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  DEC E
  INC D
  INC L
  DJNZ EndingPlugTopLoop
  LD DE,Screen+2244
  LD B,$08
EndingPlugBottomLoop:
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  DEC E
  INC D
  INC L
  DJNZ EndingPlugBottomLoop
  LD DE,Screen+3225             ; the kettle: row 12 lines 4-7, then rows 13 and 14,
                          ; columns 25-27
  LD B,$04
EndingKettleTopLoop:
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  DEC E
  DEC E
  INC D
  INC L
  DJNZ EndingKettleTopLoop
  LD DE,Screen+2233
  LD B,$08
EndingKettleMiddleLoop:
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  DEC E
  DEC E
  INC D
  INC L
  DJNZ EndingKettleMiddleLoop
  LD DE,Screen+2265
  LD B,$08
EndingKettleBottomLoop:
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  INC L
  INC E
  LD A,(HL)
  LD (DE),A
  DEC E
  DEC E
  INC D
  INC L
  DJNZ EndingKettleBottomLoop
  LD A,$0C
EndingPauseLoop:
  CALL Delay
  DEC A
  JR NZ,EndingPauseLoop
  LD HL,ChargedSound      ; a sound, then the cable
  CALL PlaySound
  LD HL,Screen+4006
  LD B,$13
EndingCableTopLoop:
  LD (HL),$FF
  INC L
  DJNZ EndingCableTopLoop
  LD HL,Screen+2246
  LD B,$13
EndingCableBottomLoop:
  LD (HL),$FF
  INC L
  DJNZ EndingCableBottomLoop
  CALL Delay              ; a pause, then the hidden lines shown
  CALL Delay
  CALL Delay
  CALL Delay
  LD HL,Attributes+544
  LD B,$40
EndingTeaLoop:
  LD (HL),$07
  INC L
  DJNZ EndingTeaLoop
  LD HL,Attributes+738
  LD B,$1C
EndingKeyLoop:
  LD (HL),$04
  INC L
  DJNZ EndingKeyLoop
  RET

; The ending's text records for $8E3A: attribute | $80, column, row, text; $FF
;
; Attributes after the printer clears bit 7. Rows 12-14: spaces that only
; colour the picture's place (7 for the plug and kettle, 3 magenta for the
; cable). Rows 17, 18 and 23 are printed in attribute 0 (black on black) and
; shown later by EndingScreen.
;
; Evidence: read once (`rzx-344752`).
EndingText:
  INCBIN "res/texts/ending.bin",$0000,259

; The mains plug with its cable end: 16 x 16 pixels, 2 bytes a row
;
; Drawn by EndingScreen at `$48A4` (8 rows) and `$48C4` (8 rows): row 13-14,
; column 4.
EndingPlug:
  INCBIN "res/graphics/ending-plug.bin",$0000,32

; The kettle: 24 x 20 pixels, 3 bytes a row
;
; Drawn by EndingScreen at `$4C99` (4 rows, row 12 lines 4-7), `$48B9` and
; `$48D9` (8 rows each): columns 25-27.
EndingKettle:
  INCBIN "res/graphics/ending-kettle.bin",$0000,60
