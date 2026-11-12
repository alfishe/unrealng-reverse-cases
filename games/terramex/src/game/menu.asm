; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The title and device menu
; --------------------------------------------------------------------------------------------------------------------

  ORG $93AF

; The title and device menu: the frame, the logo, the options, the credits;
; keys 1-3 and 0
;
; Called by NewGame `$8F47` before every game (c1 2, explorers 5, gameover 1,
; rzx50000 1). Clears the screen, attributes `$44` (green ink), a 6 x 6 block
; of `$45` at `$5937` and a 3 x 3 block of `$47` at `$5942` (FillAttrs
; `$9526`).
;
; The frame is cut from the panel kept at `$E000-$E7FF` (the panel's screen
; third as loaded; after a game the one EndGame `$906D` saved): the panel's top
; row `$E000` to row 0, its bottom row `$E0E0` to row 23 (CopyCharRow `$94B0`),
; and the left and right edge cells of panel rows 1 and 2 (`$E020`, `$E040`)
; alternately down rows 1-22 (CopyEdgeCells `$94C2`, 11 times).
;
; The TERRAMEX logo TitleLogo `$95FD`, 3 rows of 25 cells at `$4063` (row 3,
; column 3), attribute `$46` (yellow); `$9F27` (the menu's pictures); the
; options MenuText `$9540` at row 8 column 8 (attribute `$44`) and the credits
; CreditsText `$9579` at row 17 column 2 (attribute `$47`) through PrintString
; `$94F9`.
;
; The loop (MenuLoop `$9440`), once a frame: the option box (rows 8-12, columns
; 8-21) gets attribute `$43` (magenta), the row of the chosen device
; (InputDevice `$94AF`: row 8 + 2 * device) `$47` (white); HALT; keys 1, 2, 3
; (half row `$F7FE`) choose keyboard, Kempston, Sinclair (explorers: all
; three); key 0 (half row `$EFFE`) returns. IY = 0 at every turn is never used
; here.
;
; Witness: L1 9 (c1, explorers, gameover, rzx50000).
DeviceMenu:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1AFF
  LD (HL),L
  LDIR
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$44
  LDIR
  LD HL,Attributes+311             ; a 6 x 6 block of attribute $45 at row 9, column 23
  LD B,$06
  LD C,B
  LD A,$45
  CALL FillAttrs
  LD HL,Attributes+322             ; a 3 x 3 block of attribute $47 at row 10, column 2
  LD B,$03
  LD C,B
  LD A,$47
  CALL FillAttrs
  LD HL,BackBuffer        ; the frame's top: the panel's top row
  LD DE,Screen
  CALL CopyCharRow
  LD HL,BackBuffer+$00E0  ; the frame's bottom: the panel's bottom row
  LD DE,Screen+4320
  CALL CopyCharRow
  LD DE,Screen+32             ; the frame's sides: rows 1-22
  LD B,$0B
MenuFrameSides:
  LD HL,BackBuffer+$0020
  CALL CopyEdgeCells
  LD HL,BackBuffer+$0040
  CALL CopyEdgeCells
  DJNZ MenuFrameSides
  LD HL,Screen+99             ; the logo: 3 rows of 25 cells at row 3, column 3
  LD DE,TitleLogo
  LD B,$03
MenuLogoRow:
  PUSH BC
  PUSH HL
  LD B,$19
MenuLogoCell:
  PUSH BC
  PUSH HL
  LD B,$08
MenuLogoByte:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ MenuLogoByte
  POP HL
  PUSH HL
  CALL ScreenToAttr
  LD (HL),$46             ; attribute $46
  POP HL
  INC L
  POP BC
  DJNZ MenuLogoCell
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ MenuLogoRow
  CALL DrawMenuGlobes     ; the menu's pictures
  CALL PrintMenuText      ; the options
  LD HL,Screen+4130             ; the credits at row 17, column 2, attribute $47
  LD DE,CreditsText
  EX AF,AF'
  LD A,$47
  EX AF,AF'
  CALL PrintString

; The device menu's loop: the option box and the chosen device's bar
; (DeviceMenu continued)
;
; Reached by falling in from DeviceMenu `$93AF` and from MenuKeys `$9468` (`JR
; $9440`) once a frame; an entry of the cut because the explorers recording
; starts inside the menu. The box (5 rows x 14 columns at row 8, column 8) gets
; attribute `$43`, the row of the chosen device (InputDevice `$94AF`; row 8 + 2
; * device) `$47` on its 14 columns. IY = 0 here is never used. Falls into
; MenuKeys.
;
; Witness: L1 6835 (c1, explorers, gameover, rzx00000, rzx50000).
MenuLoop:
  LD IY,$0000             ; the box: 5 rows x 14 columns of attribute $43 at
                          ; row 8, column 8
  LD BC,$050E
  LD HL,Attributes+264
  PUSH HL
  LD A,$43
  CALL FillAttrs
  LD A,(InputDevice)      ; the chosen device's row: 2 rows per option
  POP DE
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD E,L
  LD D,H
  INC DE
  LD BC,$000D
  LD (HL),$47             ; 14 attributes of $47
  LDIR

; The device menu's keys: 1-3 choose the device, 0 starts (DeviceMenu
; continued)
;
; HALT (one turn a frame), then half row `$F7FE`: a lone 1, 2 or 3 sets
; InputDevice `$94AF` to 0 (keyboard), 1 (Kempston), 2 (Sinclair); half row
; `$EFFE` bit 0, the key 0, returns from DeviceMenu `$93AF` to NewGame; else
; `JR $9440`. explorers chooses all three devices; c1 1, 3, 2 then 0.
;
; Witness: L1 6836 (c1, explorers, gameover, rzx00000, rzx50000).
MenuKeys:
  HALT                    ; one turn a frame
  LD BC,$F7FE             ; keys 1-5
  IN A,(C)
  AND $1F
  CP $1F
  JR Z,MenuCheckStart
  LD E,$00                ; 1: E = 0 (keyboard), 2: 1 (Kempston), 3: 2
                          ; (Sinclair)
  CP $1E
  JR Z,MenuSetDevice
  INC E
  CP $1D
  JR Z,MenuSetDevice
  INC E
  CP $1B
  JR NZ,MenuCheckStart
MenuSetDevice:
  LD A,E
  LD (InputDevice),A
MenuCheckStart:
  LD B,$EF                ; key 0 starts the game
  IN A,(C)
  AND $01
  RET Z
  JR MenuLoop

  ORG $94AF

; The control device: 0 keyboard, 1 Kempston, 2 Sinclair
;
; Set by DeviceMenu `$93AF` (keys 1, 2, 3; c1 and explorers), read by the input
; routine `$B894` in play.
InputDevice:
  DEFB $00

; Copy a character row of 32 cells (8 pixel rows)
;
; HL = the source, DE = the destination, both at a cell's top pixel row in a
; screen-like layout. 32 bytes a pixel row, INC H and INC D between rows.
; Callers: DeviceMenu `$93E4`, `$93ED`.
;
; Witness: L1 18 (c1, explorers, gameover, rzx50000).
CopyCharRow:
  LD B,$08
CopyCharRowLoop:
  PUSH BC
  PUSH HL
  PUSH DE
  LD BC,$0020
  LDIR
  POP DE
  POP HL
  INC D
  INC H
  POP BC
  DJNZ CopyCharRowLoop
  RET

; Copy the left and right edge cells of a row; DE to the next character row
;
; HL = the source row (the left cell), DE = the destination row. Copies the
; cell at column 0, then the cell at column 31 of both (L OR `$1F`, E OR
; `$1F`), through CopyCell `$94E4`. Out: DE = the next character row's column 0
; (into the next screen third after row 7 of one); HL unchanged. Called 22
; times a menu by DeviceMenu.
;
; Witness: L1 198 (c1, explorers, gameover, rzx50000).
CopyEdgeCells:
  PUSH DE
  PUSH HL
  CALL CopyCell
  POP HL
  POP DE
  LD A,L
  OR $1F
  LD L,A
  LD A,E
  OR $1F
  LD E,A
  PUSH DE
  PUSH HL
  CALL CopyCell
  POP HL
  POP DE
  LD A,E
  AND $E0
  ADD A,$20
  LD E,A
  RET NC
  LD A,D                  ; past the third's last row: the next third
  ADD A,$08
  LD D,A
  RET

; Copy one cell, 8 pixel rows
;
; HL = the source, DE = the destination; INC H and INC D between rows. BC kept.
; Called by CopyEdgeCells `$94C2`.
;
; Witness: L1 396 (c1, explorers, gameover, rzx50000).
CopyCell:
  PUSH BC
  LD B,$08
CopyCellLoop:
  LD A,(HL)
  LD (DE),A
  INC H
  INC D
  DJNZ CopyCellLoop
  POP BC
  RET

; Print the device options at row 8, column 8, attribute $44
;
; DE = MenuText `$9540`, HL = `$4808`, A' = `$44`; falls into PrintString
; `$94F9`. Called by DeviceMenu `$9430`.
;
; Witness: L1 9 (c1, explorers, gameover, rzx50000).
PrintMenuText:
  LD DE,MenuText
  LD HL,Screen+2056
  EX AF,AF'
  LD A,$44
  EX AF,AF'

; Print a text with an attribute: 0 ends, $0D a new line
;
; DE = the text, HL = the screen address of the first cell, A' = the attribute.
; Each character goes through PrintChar `$90C6` and its cell's attribute
; (ScreenToAttr `$9536`) is A'. `$0D` starts the next character row under the
; line's first cell: the line start is kept in the operand at `$9517` (written
; here, so the image after a menu holds `$50A2`, the credits' last line); 0
; ends. `$7F` is the ROM font's copyright sign.
;
; Callers: PrintMenuText `$94EF` (falls in), DeviceMenu `$943D`, and `$A7EB`
; (the countdown text, not executed in any recording).
;
; Witness: L1 108 (c1, explorers, gameover, rzx50000).
PrintString:
  LD (PrintNewLine+$0001),HL ; the line start: the operand at $9517
PrintStringLoop:
  LD A,(DE)
  INC DE
  OR A
  RET Z
  CP $0D
  JR Z,PrintNewLine
  PUSH DE
  PUSH HL
  CALL PrintChar
  POP HL
  PUSH HL
  CALL ScreenToAttr
  EX AF,AF'               ; the cell's attribute = A'
  LD (HL),A
  EX AF,AF'
  POP HL
  INC L
  POP DE
  JR PrintStringLoop
PrintNewLine:
  LD HL,$0000             ; LD HL,n: n = the line start, written at $94F9
  LD A,L                  ; the next character row, the next third after row 7
                          ; of one
  ADD A,$20
  LD L,A
  JR NC,PrintString
  LD A,H
  ADD A,$08
  LD H,A
  JR PrintString

; A lone RET ($C9) that no code reaches
;
; No jump, call or table in the image names `$9525`; never executed or read in
; any recording.
UnusedRet:
  DEFB $C9

; Fill a block of B rows by C bytes with A, rows 32 bytes apart
;
; HL = the top-left address (an attribute in every caller), B = the rows, C =
; the bytes a row, A = the value. Out: HL = the address below the block; BC
; changed. Callers: DeviceMenu `$93D0`, `$93DB` and MenuLoop `$944D` (once a
; frame on the menu).
;
; Witness: L1 34256 (c1, explorers, gameover, rzx00000, rzx50000).
FillAttrs:
  PUSH BC
  PUSH HL
FillAttrsRow:
  LD (HL),A
  INC HL
  DEC C
  JR NZ,FillAttrsRow
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ FillAttrs
  RET

; The attribute address of a cell's screen address
;
; HL = a screen address at a cell's top row. Out: H = `$58` + the screen third,
; L unchanged: the cell's attribute. Callers: DeviceMenu `$941B`, PrintString
; `$950B`.
;
; Witness: L1 2268 (c1, explorers, gameover, rzx50000).
ScreenToAttr:
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  RET

; The device options: four lines a blank line apart, 0 ends
;
; Printed by PrintMenuText `$94EF` at row 8, column 8: "1 : KEYBOARD", "2 :
; KEMPSTON", "3 : SINCLAIR", "0 : START GAME", with `$0D $0D` between them
; (rows 8, 10, 12, 14). The option box of MenuLoop `$9440` covers rows 8-12.
MenuText:
  INCBIN "res/texts/menu.bin",$0000,57

; The credits: five lines, rows 17-21, 0 ends
;
; Printed by DeviceMenu `$943D` at row 17, column 2, attribute `$47`. "BY TEQUE
; SOFTWARE  DEV. LTD", "(c)   ARGUS PRESS SOFTWARE LTD" (`$7F` the ROM's
; copyright sign), "PROGRAM   SHAUN HOLLINGWORTH", "          PETE  HARRAP",
; "+2 MUSIC  BEN DAGLISH", each line ended by `$0D`, the last by 0 (`$95FC`).
; The "+2 MUSIC" line is printed on a 48K too.
CreditsText:
  INCBIN "res/texts/credits.bin",$0000,132

; The TERRAMEX logo of the menu: 3 rows of 25 cells, 8 bytes a cell from the
; top
;
; Drawn by DeviceMenu `$93AF` (`$9403`) at row 3, column 3, cell by cell along
; a row, attribute `$46` (yellow on black). 600 bytes, read in every menu (c1,
; explorers, gameover, rzx50000).
TitleLogo:
  INCBIN "res/graphics/title-logo.bin",$0000,600

  ORG $9F27

; Draw the Earth and the Moon on the device menu
;
; Frames $71-$74 counted from $6000 (the image's $7FC8-$80E7) are the Earth, a
; 48 x 48 picture: the first 6 columns at $4837 (rows 9-11, columns 23-28), the
; next 6 at $4897 (rows 12-14). Frame $75 ($80E8) is the Moon at $4842 (rows
; 10-12, columns 2-4). menu.png shows both there.
;
; Called by the menu $93AF at $942D: 9 runs (c1, explorers, gameover, r50000).
;
; Witness: L1 9 (c1, explorers, gameover, rzx50000).
DrawMenuGlobes:
  LD IY,PanelColumns
  LD B,$04
  LD A,$71
DrawMenuGlobesEarth:
  PUSH AF
  LD DE,ExplorerSet
  CALL SpriteAddress
  CALL AddColumnPointers
  POP AF
  INC A
  DJNZ DrawMenuGlobesEarth
  LD IY,PanelColumns
  LD B,$06
  LD HL,Screen+2103
  CALL BlitColumns
  LD B,$06
  LD HL,Screen+2199
  CALL BlitColumns
  LD IY,PanelColumns
  LD A,$75
  LD DE,ExplorerSet
  CALL SpriteAddress
  CALL AddColumnPointers
  LD B,$03
  LD HL,Screen+2114
  LD IY,PanelColumns
  JR BlitColumns
