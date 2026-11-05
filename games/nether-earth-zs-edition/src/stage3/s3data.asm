; --------------------------------------------------------------------------------------------------------------------
; s3data.asm: The page list, the saved bytes, the strings
;
; The data of stage 3: the 62 page numbers CountPages checks, the 64 bytes it saves, and the $FF-ended strings. The
; strings after $6780 (and the end of BattleText) are under the game block once ReadSectors has read it (r99 frame
; 2299 writes $6780-$67EB): the machine names are needed only before that.
; --------------------------------------------------------------------------------------------------------------------

; $FF in front of PageList (no window reads it)
PageListGuard:
  DEFB $FF

; the pages to count: 0 1 3 4 6 7 8 .. 63, $FF
;
; The 62 pages 0-63 without 2 and 5 (the fixed pages at $8000 and $4000), $FF
; at $6672. CountPages removes the aliases in place.
PageList:
  DEFB $00,$01,$03,$04,$06,$07,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F,$10,$11
  DEFB $12,$13,$14,$15,$16,$17,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F,$20,$21
  DEFB $22,$23,$24,$25,$26,$27,$28,$29,$2A,$2B,$2C,$2D,$2E,$2F,$30,$31
  DEFB $32,$33,$34,$35,$36,$37,$38,$39,$3A,$3B,$3C,$3D,$3E,$3F
  DEFB $FF                ; the end mark

; the byte at $C000 of pages 0-63 while CountPages marks them
PageSave:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; AT 0,10 INK 4 PAPER 0 FLASH 0 BRIGHT 0 "NETHER  EARTH" AT 1,10 "ZS
; Edition'99" INK 6 AT 3,1 "System checking..." CR "Computer " INK 5
TitleText:
  DEFB $16,$00,$0A,$10,$04,$11,$00,$12
  DEFB $00,$13,$00,$4E,$45,$54,$48,$45
  DEFB $52,$20,$20,$45,$41,$52,$54,$48
  DEFB $16,$01,$0A,$5A,$53,$20,$45,$64
  DEFB $69,$74,$69,$6F,$6E,$27,$39,$39
  DEFB $10,$06,$16,$03,$01,$53,$79,$73
  DEFB $74,$65,$6D,$20,$63,$68,$65,$63
  DEFB $6B,$69,$6E,$67,$2E,$2E,$2E,$0D
  DEFB $43,$6F,$6D,$70,$75,$74,$65,$72
  DEFB $20,$10,$05,$FF

; CR INK 6 "Memory " INK 5
MemoryText:
  DEFB $0D,$10,$06,$4D,$65,$6D,$6F,$72
  DEFB $79,$20,$10,$05,$FF

; INK 6 "Kb" CR "Using " INK 5
KbText:
  DEFB $10,$06,$4B,$62,$0D,$55,$73,$69
  DEFB $6E,$67,$20,$10,$05,$FF

; "TAPE RECORDER" (the tape path; no window reads it)
TapeRecorderText:
  DEFB $54,$41,$50,$45,$20,$52,$45,$43
  DEFB $4F,$52,$44,$45,$52,$FF

; AT 8,1 INK 6 "Loading... " CR "Game... "
LoadingText:
  DEFB $16,$08,$01,$10,$06,$4C,$6F,$61
  DEFB $64,$69,$6E,$67,$2E,$2E,$2E,$20
  DEFB $0D,$47,$61,$6D,$65,$2E,$2E,$2E
  DEFB $20,$FF

; INK 4 "O.k." INK 6 CR
OkText:
  DEFB $10,$04,$4F,$2E,$6B,$2E,$10,$06
  DEFB $0D,$FF

; "Drivers... "
DriversText:
  DEFB $44,$72,$69,$76,$65,$72,$73,$2E
  DEFB $2E,$2E,$20,$FF

; "Menus... "
MenusText:
  DEFB $4D,$65,$6E,$75,$73,$2E,$2E,$2E
  DEFB $20,$FF

; "RAM-Disk... "
RamDiskText:
  DEFB $52,$41,$4D,$2D,$44,$69,$73,$6B
  DEFB $2E,$2E,$2E,$20,$FF

; AT 20,5 INK 0 "Let the Battle begin!": nothing prints it
;
; No code of stage 3, the game, the patches or the menu block names $676F (byte
; search); its tail from $6780 is the game block's once loaded.
BattleText:
  DEFB $16,$14,$05,$10,$00,$4C,$65,$74
  DEFB $20,$74,$68,$65,$20,$42,$61,$74
  DEFB $74
GameBlock:
  DEFB $6C,$65,$20,$62,$65,$67,$69,$6E ; the game block's first byte once read
  DEFB $21,$FF                         ; (ReadSectors, 68 sectors): its entry

; AT 20,3 INK 2 PAPER 6 BRIGHT 1 FLASH 1 "Tape Error. System Halted."
TapeErrorText:
  DEFB $16,$14,$03,$10,$02,$11,$06,$13
  DEFB $01,$12,$01,$54,$61,$70,$65,$20
  DEFB $45,$72,$72,$6F,$72,$2E,$20,$53
  DEFB $79,$73,$74,$65,$6D,$20,$48,$61
  DEFB $6C,$74,$65,$64,$2E,$FF

; $FF, then "Scorpion" "Spectrum" "Spectrum" "ATM" "TURBO 2+" "PROFI" "KAY"
; "Spectrum": bits 7-0
;
; SkipStrings from the $FF at $67B0: the B-th string is the name of bit 8-B.
; Bit 6 is never set; bits 5 and 0 are both "Spectrum", NameDefault is used for
; scheme 0.
MachineNames:
  DEFB $FF
NameScorpion:
  DEFB $53,$63,$6F,$72,$70,$69,$6F,$6E
  DEFB $FF,$53,$70,$65,$63,$74,$72,$75
  DEFB $6D,$FF,$53,$70,$65,$63,$74,$72
  DEFB $75,$6D,$FF,$41,$54,$4D,$FF,$54
  DEFB $55,$52,$42,$4F,$20,$32,$2B,$FF
  DEFB $50,$52,$4F,$46,$49,$FF,$4B,$41
  DEFB $59,$FF
NameDefault:
  DEFB $53,$70,$65,$63,$74,$72,$75,$6D
  DEFB $FF
