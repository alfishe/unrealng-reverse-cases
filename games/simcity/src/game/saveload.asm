; --------------------------------------------------------------------------------------------------------------------
; saveload.asm: Save and load
;
; SAVE TO TAPE and LOAD FROM TAPE: a 31-byte header and the 9216-byte map, both with flag $FF, through the ROM.
; --------------------------------------------------------------------------------------------------------------------

; SAVE TO TAPE: the name, START TAPE, then a 31-byte header (flag $FF) and the
; 9216-byte map (flag $FF)
;
; The header SaveHeader: the 12-letter file name, Funds, its spare byte, Month,
; Year (7 bytes), a spare byte, the city name (12). Nothing else is saved: not
; the tax, the fundings, the options or the arrays. Known only from the code
; (stage 1's save recording ran it: L1 at $9E09 none, as the save was reached
; through the menu action; see NOTES).
SaveCity:
  CALL FileNameWindow
  LD BC,$100C
  LD (InputAt),BC
  LD HL,SaveHeader
  LD (InputBuffer),HL
  CALL InputName
  CALL WaitTapeStart
  LD HL,Funds
  LD DE,SaveFunds
  LD BC,$0007
  LDIR
  LD HL,CityName
  LD DE,SaveCityName
  LD BC,$000C
  LDIR
  DI
  LD IX,SaveHeader
  LD DE,$001F
  LD A,$FF
  SCF
  CALL TapeSave
  LD B,$1E
  CALL TapePause
  LD IX,CityMap
  LD DE,$2400
  LD A,$FF
  SCF
  CALL TapeSave
  XOR A
  OUT ($FE),A
  EI
  RET

; LOAD FROM TAPE: the name, START TAPE, SEARCHING; headers until the name
; matches (any with a blank name), then the map
LoadCity:
  CALL FileNameWindow
  LD BC,$100C
  LD (InputAt),BC
  LD HL,SaveName
  LD (InputBuffer),HL
  CALL InputName
  DI
  CALL ClearTopBlack
  CALL ClearTopWhite
  CALL PrintInline

; PrintInline codes: a box, SEARCHING
SearchingText:
  INCBIN "res/text/inline/Searching.bin",$0000,18

; LoadHeader
LoadHeader:
  LD IX,SaveHeader
  LD DE,$001F
  LD A,$FF
  SCF
  CALL TapeLoad
  JR NC,LoadHeaderFailed
  CALL PrintFound
  LD HL,SaveName
  LD B,$0C
LoadHeaderBlank:
  LD A,(HL)
  CP $20
  JR NZ,LoadHeaderCompare
  INC HL
  DJNZ LoadHeaderBlank
  JR LoadHeaderMatch
LoadHeaderCompare:
  LD HL,SaveHeader
  LD IX,SaveName
  LD B,$0C
LoadHeaderLoop:
  LD A,(HL)
  CP (IX+$00)
  JR NZ,LoadHeader
  INC IX
  INC HL
  DJNZ LoadHeaderLoop
LoadHeaderMatch:
  CALL PrintInline

; PrintInline: LOADING
LoadingText:
  INCBIN "res/text/inline/Loading.bin",$0000,11

; The map; on success Funds, the date and the name from the header
LoadMap:
  LD IX,CityMap
  LD DE,$2400
  LD A,$FF
  SCF
  CALL TapeLoad
  JR NC,LoadMapFailed
  LD HL,SaveFunds
  LD DE,Funds
  LD BC,$0007
  LDIR
  LD HL,SaveCityName
  LD DE,CityName
  LD BC,$000C
  LDIR
  EI
  XOR A
  OUT ($FE),A
  CALL ClearTopBlack
  CALL DrawStatusPanel
  RET
LoadMapFailed:
  EI                      ; a bad map: the error window, then a new city
  XOR A
  OUT ($FE),A
  CALL ClearTopBlack
  CALL DrawStatusPanel
  CALL LoadErrorWindow
  JP NewCity
; This entry point is used by the routine at LoadHeader.
LoadHeaderFailed:
  EI
  XOR A
  OUT ($FE),A
  CALL ClearTopBlack
  CALL DrawStatusPanel
  CALL LoadErrorWindow
  RET

; FOUND :- and the header's name
;
; Used by the routine at LoadHeader.
PrintFound:
  CALL PrintInline

; FoundText
FoundText:
  INCBIN "res/text/inline/Found.bin",$0000,13

; The 12 letters at SaveName
PrintFileName:
  LD HL,SaveHeader
  LD B,$0C
PrintFileNameLoop:
  PUSH HL
  PUSH BC
  LD A,(HL)
  CP $20
  CALL NC,PrintGlyph
  CALL NextColumn
  POP BC
  POP HL
  INC HL
  DJNZ PrintFileNameLoop
  RET
