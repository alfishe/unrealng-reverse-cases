; --------------------------------------------------------------------------------------------------------------------
; font.asm: Printing: the ROM's RST $10 with the menu's font
;
; The menu prints through the ROM (RST $10 on channel 2) with Chars $5C36 pointing at Font $A600 - 256
; (src/res/graphics/font.png: 96 characters, space to the copyright sign). The texts are MenuHelp $6AFD and
; NoFilesText $6B41 (src/res/texts) and the catalogue lines built in EntryLine $B3CE. The launcher sets Chars back to
; the ROM's $3C00.
; --------------------------------------------------------------------------------------------------------------------

  ORG $6720

; Print the string at HL up to $FF through RST $10 on channel 2
;
; Puts back HL' and IY for the ROM (SavedHLAlt, SavedIY), opens channel 2
; (RomChanOpen $1601), then RST $10 for each byte: the control codes AT, INK,
; BRIGHT are the ROM's.
;
; Witness: L1 93 (c x4).
PrintString:
  PUSH HL
  LD HL,(SavedHLAlt)
  EXX
  LD IY,(SavedIY)
  LD A,$02
  CALL RomChanOpen
  POP HL
PrintStringNext:
  LD A,(HL)
  CP $FF
  RET Z
  RST $10
  INC HL
  JR PrintStringNext

  ORG $6AFD

; The help lines: SPACE  TO NEW DISK, "SS" TO NEXT PAGES, "CS" TO FIRST PAGE
; (rows 19-21)
;
; Printed by DrawScreen $6510 (c1: the screen from the first menu frame).
MenuHelp:
  INCBIN "res/texts/menu-help.bin",$0000,68

; NO EXE FILES ! at row 11, column 9
;
; Printed by ListCatalogue $65C7 when the page lists no file (c1 on the
; original disk, c4).
NoFilesText:
  INCBIN "res/texts/no-files.bin",$0000,18
