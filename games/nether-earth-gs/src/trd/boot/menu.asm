; --------------------------------------------------------------------------------------------------------------------
; menu.asm: Work Loader v1.2 (TRON 1999): the boot program's catalogue menu
;
; Boot's line 1 loads 20 sectors to $61A8 and calls them: the HRUM block (src/trd/boot/boot.asm) unpacks this program
; over itself and returns; line 1 then jumps to Start. The screen says "Work Loader v1.2 / Prepared by TRON 1999": a
; file selector that reads the disk's catalogue, lists the BASIC files (type B) in four columns of 24 and RUNs the one
; chosen.
;
; The choice is not run from here: Run copies the file's 8-character name over the 8 spaces of boot's line 3 (RUN "
; ", RunName) and returns to BASIC, which goes on at line 2 (CLEAR 24999 : RANDOMIZE USR 23872 returned) and then line
; 3: CLEAR 65500 : RANDOMIZE USR 15619 : REM : RUN "name", TR-DOS's RUN of the file.
;
; Keys (KeyLoop): 0-9 the first ten files at once; Q/A/O/P, the cursor keys and the Sinclair arrows move the cursor
; (up, down, left, right); SPACE or ENTER runs the file under it; EDIT reads the catalogue again; SYMBOL SHIFT + CAPS
; SHIFT switches between the catalogue's order and the sorted one.
; --------------------------------------------------------------------------------------------------------------------

; the entry: system variables, the printer copied and set up, the catalogue
; read and shown
;
; Reached by JP $61A8 from boot's line 1 after the HRUM block returned. Sets
; BORDCR / ATTR_P to 7 (white ink on black), the keyboard repeat to 15 / 1, IM
; 1 with I = 0, copies the printer (Print64, $68CC-$71AC: the copy takes 2273
; bytes, one past the image) to $8156, then clears the screen, the work buffers
; and draws the frame.
Start:
  LD A,$07
  LD (BORDCR),A
  LD (ATTR_P),A
  LD A,$0F
  LD (REPDEL),A
  LD A,$01
  LD (REPPER),A
  DI
  LD A,$00
  LD I,A
  IM 1
  EI
  LD HL,PRINT64_IMAGE     ; the 64-column printer to $8156 (its variables run
                          ; on to $8DD8: past the copy)
  LD DE,PrintInit
  LD BC,PRINT64_COPY
  LDIR
; This entry point is used by the routine at Run.
Restart:
  LD A,$00                ; EDIT comes back here: clear, read the catalogue
                          ; again
  LD (FileCount),A        ; no files yet
  LD HL,$0000
  LD (CursorColumn),HL    ; the cursor at row 0, column 0
  CALL ClearScreen
  CALL ClearBuffers
  CALL PrintInit
  CALL HighlightRow       ; the frame, the titles and the help lines
  CALL DrawFrame
  CALL ReadCatalogue      ; track 0's 9 sectors to Catalogue
  CALL DriveReset         ; the drive's state after the read (DriveReset)
  DI
  CALL CatalogueFilter    ; the BASIC files' names into Screen (the scratch
                          ; buffer)
  CALL ShowSorting        ; "Сортировка каталога." on the status line
  CALL SortCatalogue      ; the sorted copy
  LD A,$00                ; the catalogue's order first
  LD (CatalogueOrder),A
  CALL ClearScreen
  CALL ListFiles          ; the file names, four columns of 24
  CALL HighlightRow
  CALL HighlightCursor    ; the cursor
; This entry point is used by the routines at CursorUp, CursorDown,
; CursorRight, CursorLeft, ToggleOrder and Run.
KeyLoop:
  EI                      ; wait for a key (FLAGS bit 5: a new LAST_K), then
                          ; dispatch it
  RES 5,(IY+$01)          ; FLAGS bit 5 is set by the ROM's key scan at the
                          ; interrupt
l_620D:
  BIT 5,(IY+$01)
  JR Z,l_620D
  LD A,(IY-$32)           ; LAST_K
  DI
  CP $07                  ; EDIT: read the catalogue again
  JP Z,Restart
  CP $0E                  ; SS + CS (code 14): the other order
  JP Z,ToggleOrder
  CP $20                  ; SPACE / ENTER: run the file under the cursor
  JP Z,Run
  CP $0D
  JP Z,Run
  CP $30                  ; 0-9: a file by its number
  JP Z,NumberKey
  CP $31
  JP Z,NumberKey
  CP $32
  JP Z,NumberKey
  CP $33
  JP Z,NumberKey
  CP $34
  JP Z,NumberKey
  CP $35
  JP Z,NumberKey
  CP $36
  JP Z,NumberKey
  CP $37
  JP Z,NumberKey
  CP $38
  JP Z,NumberKey
  CP $39
  JP Z,NumberKey
  CP $51                  ; Q, q, cursor up ($0B)
  JP Z,CursorUp
  CP $71
  JP Z,CursorUp
  CP $0B
  JP Z,CursorUp
  CP $41                  ; A, a, cursor down ($0A)
  JP Z,CursorDown
  CP $61
  JP Z,CursorDown
  CP $0A
  JP Z,CursorDown
  CP $4F                  ; O, o, cursor left (8)
  JP Z,CursorLeft
  CP $6F
  JP Z,CursorLeft
  CP $08
  JP Z,CursorLeft
  CP $50                  ; P, p, cursor right (9)
  JP Z,CursorRight
  CP $70
  JP Z,CursorRight
  CP $09
  JP Z,CursorRight
  JP KeyLoop              ; any other key: wait again

; one row up (not past row 0)
;
; Used by the routine at Start.
CursorUp:
  LD HL,(CursorColumn)
  LD A,H
  CP $00
  JP Z,KeyLoop
  DEC H
  LD (CursorColumn),HL
  XOR A
  LD A,(CursorIndex)
  DEC A
  LD (CursorIndex),A
  CALL HighlightCursor
  JP KeyLoop

; one row down (not past row 23)
;
; Used by the routine at Start.
CursorDown:
  LD HL,(CursorColumn)
  LD A,H
  CP $17
  JP Z,KeyLoop
  INC H
  LD (CursorColumn),HL
  XOR A
  LD A,(CursorIndex)
  INC A
  LD (CursorIndex),A
  CALL HighlightCursor
  JP KeyLoop

; one column right (5 cells a column: column cells 0, 5, 10, ... 25), the index
; 24 on
;
; Used by the routine at Start.
CursorRight:
  LD HL,(CursorColumn)
  LD A,L
  CP $19
  JP Z,KeyLoop
  LD A,$05
  ADD A,L
  LD L,A
  LD (CursorColumn),HL
  LD A,(CursorIndex)
  ADD A,$18
  LD (CursorIndex),A
  CALL HighlightCursor
  JP KeyLoop

; one column left, the index 24 back
;
; The SBC instructions rely on the carry the CP 0 before them left clear (A is
; not 0 there).
CursorLeft:
  LD HL,(CursorColumn)
  LD A,L
  CP $00
  JP Z,KeyLoop
  LD L,$05
  SBC A,L
  LD L,A
  LD (CursorColumn),HL
  LD A,(CursorIndex)
  SBC A,$18
  LD (CursorIndex),A
  CALL HighlightCursor
  JP KeyLoop

; key 0-9: the file of that number in the first column, then Run
;
; A is the key's code: SBC A,"0" (carry clear from the CP that matched) gives
; the index, the cursor goes to row = the index in column 0.
NumberKey:
  SBC A,$30
  LD (CursorIndex),A
  LD HL,$0000
  ADD A,H
  LD H,A
  LD (CursorColumn),HL
  JP Run

; SS + CS: the catalogue's order <-> the sorted order; the cursor back to the
; first file
;
; Used by the routine at Start.
ToggleOrder:
  LD A,(CatalogueOrder)
  CP $01
  JR Z,l_6329
  CP $00
  JR Z,l_6330
l_6329:
  LD A,$00
  LD (CatalogueOrder),A
  JR l_6335
l_6330:
  LD A,$01
  LD (CatalogueOrder),A
l_6335:
  LD HL,$0000
  LD A,$00
  LD (CursorColumn),HL
  LD (CursorIndex),A
  CALL ListFiles
  CALL HighlightCursor
  JP KeyLoop

; the file under the cursor: its name to RunName, back to BASIC
;
; Nothing happens past the last file. The cursor bar blinks four times
; (HighlightRow / HighlightCursor, two HALTs each); the name is taken from
; Catalogue or SortedCatalogue by the order (ClearBuffers left the 8-byte names
; in both), the screen is cleared and the 8 bytes go to RunName. EI; RET ends
; the RANDOMIZE USR 23872 of boot's line 2 (the REM code jumped here, so this
; RET is its return): BASIC goes on to line 3 and RUNs the name.
Run:
  LD A,(FileCount)
  LD C,A
  LD A,(CursorIndex)
  CP C
  JP NC,KeyLoop
  EI
  LD B,$04
l_6357:
  PUSH BC
  CALL HighlightRow
  HALT
  HALT
  CALL HighlightCursor
  HALT
  HALT
  POP BC
  DJNZ l_6357
  LD A,(CatalogueOrder)
  CP $00
  JR Z,l_6373
  CP $01
  JR Z,l_6378
  JP Restart
l_6373:
  LD HL,Catalogue
  JR l_637B
l_6378:
  LD HL,SortedCatalogue
l_637B:
  LD A,(CursorIndex)
  CP $00
  JR Z,l_6389
l_6382:
  LD DE,$0008
  ADD HL,DE
  DEC A
  JR NZ,l_6382
l_6389:
  CALL ClearScreen
  LD DE,RunName
  LD BC,$0008
  LDIR
  EI
  RET

; the printer's position: L = the column, H = the row
;
; Used by the routines at DrawFrame, ShowSorting, ListFiles and PrintDigits.
SetPrintPosition:
  LD A,L
  LD (PrintColumn),A
  LD A,H
  LD (PrintRow),A
  RET

; the attribute frame: the screen white on black ($47), the ten left cells of
; every row $45
;
; Called before every cursor draw (it wipes the old cursor bar).
HighlightRow:
  LD HL,Attrs
  LD DE,Attrs+1
  LD BC,$02FF
  LD (HL),$47
  LDIR
  LD HL,Attrs
  LD B,$0A
  LD A,$45
l_63B3:
  LD (HL),A
  LD DE,$0020
  ADD HL,DE
  DJNZ l_63B3
  RET

; the screen's frame and texts: title, credit, status line and the key help
;
; The printer prints the texts through the 48 ROM's PR_STRING (channel 2 goes
; to the printer's ChannelOut after PrintInit). The texts are Texts (CP866
; Russian and English, src/res/text/trd-boot-menu.txt).
DrawFrame:
  LD HL,Attrs
  LD DE,Attrs+1
  LD BC,$0100
  LD (HL),$00
  LDIR
  LD HL,Attrs+671
  LD DE,Attrs+672
  LD BC,$001F
  LD (HL),$44
  LDIR
  LD HL,Attrs+704
  LD DE,Attrs+705
  LD BC,$001F
  LD (HL),$45
  LDIR
  LD HL,Attrs+736
  LD DE,Attrs+737
  LD BC,$001F
  LD (HL),$46
  LDIR
  LD B,$05                ; the key help's box: five rows of 9 attribute cells
  LD IX,Attrs+494
  LD A,$07
l_63F7:
  CALL FillAttr9
  LD DE,$0020
  ADD IX,DE
  DJNZ l_63F7
  LD HL,21*256+5
  CALL SetPrintPosition
  LD DE,Texts
  LD BC,$0010
  CALL PR_STRING
  LD HL,22*256+5
  CALL SetPrintPosition
  LD DE,TextCredit
  LD BC,$0016
  CALL PR_STRING
  LD HL,23*256+5
  CALL SetPrintPosition
  LD DE,TextReading
  LD BC,$0013
  CALL PR_STRING
  LD HL,15*256+5
  CALL SetPrintPosition
  LD DE,TextHelp1
  LD BC,$002A
  CALL PR_STRING
  LD HL,17*256+5
  CALL SetPrintPosition
  LD DE,TextHelp2
  LD BC,$002A
  CALL PR_STRING
  LD HL,18*256+5
  CALL SetPrintPosition
  LD DE,TextHelp3
  LD BC,$002A
  CALL PR_STRING
  LD HL,19*256+5
  CALL SetPrintPosition
  LD DE,TextHelp4
  LD BC,$002A
  CALL PR_STRING
  LD HL,13*256+10
  CALL SetPrintPosition
  LD DE,TextEdit
  LD BC,$0015
  CALL PR_STRING
  LD HL,11*256+17
  CALL SetPrintPosition
  LD DE,TextSsCs
  LD BC,$001E
  CALL PR_STRING
  RET

; A into 9 attribute cells from IX
;
; Used by the routine at DrawFrame.
FillAttr9:
  LD (IX+$00),A
  LD (IX+$01),A
  LD (IX+$02),A
  LD (IX+$03),A
  LD (IX+$04),A
  LD (IX+$05),A
  LD (IX+$06),A
  LD (IX+$07),A
  LD (IX+$08),A
  RET

; the status line: "Сортировка каталога." on $42 (red on black, bright)
;
; Used by the routine at Start.
ShowSorting:
  LD HL,Attrs+736
  LD DE,Attrs+737
  LD BC,$001F
  LD (HL),$42
  LDIR
  LD HL,23*256+5
  CALL SetPrintPosition
  LD DE,TextSorting
  LD BC,$0014
  CALL PR_STRING
  RET

; the BASIC files (type B at +8) of Catalogue: their 8-byte names packed into
; Screen, the count to FileCount
;
; 133 entries ($85) are looked at (the catalogue has 128: the last ones read
; the disk's sector 9 too, which a name never starts there with a code >= 32
; and B at +8). An entry whose first byte is below 32 (0 = the end, 1 =
; deleted) is skipped.
CatalogueFilter:
  LD HL,Screen
  LD IX,Catalogue
  LD B,$85
l_64CB:
  LD A,(IX+$00)
  CP $20
  JR C,l_64FB
  LD A,(IX+$08)
  CP $42
  JR NZ,l_64FB
  LD A,(FileCount)
  INC A
  LD (FileCount),A
  PUSH HL
  PUSH HL
  POP DE
  PUSH IX
  POP HL
  PUSH BC
  LD BC,$0008
  LDIR
  POP BC
  POP HL
  LD DE,$0008
  ADD HL,DE
  LD DE,$0010
  ADD IX,DE
  DJNZ l_64CB
  JR ClearBuffers
l_64FB:
  LD DE,$0010
  ADD IX,DE
  DEC B
  JR NZ,l_64CB

; SortedCatalogue cleared ($3CAF + 1 bytes from $C350), then the names from
; Screen copied to Catalogue and SortedCatalogue
;
; Used by the routines at Start and CatalogueFilter.
ClearBuffers:
  LD HL,SortedCatalogue
  LD DE,SortedCatalogue+1
  LD BC,$3CAF
  LD (HL),$00
  LDIR
  LD HL,Screen
  LD DE,Catalogue
  LD BC,$0800
  LDIR
  LD HL,Screen
  LD DE,SortedCatalogue
  LD BC,$0800
  LDIR
  RET

; the names of SortedCatalogue sorted by their first character (32-254),
; through Screen
;
; For each character code from 32 to 254 every name starting with it is copied,
; in their order, to Screen; then the 2 K back to SortedCatalogue. Only the
; first character sorts: names with the same first character keep the disk's
; order.
SortCatalogue:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$07FF
  LD (HL),$00
  LDIR
  LD HL,Screen
  LD A,$20
  LD (SortKey),A
l_653C:
  LD A,(FileCount)
  LD IX,SortedCatalogue
l_6543:
  PUSH AF
  LD A,(IX+$00)
  LD C,A
  LD A,(SortKey)
  CP C
  JR NZ,l_6566
  PUSH HL
  PUSH HL
  POP DE
  PUSH IX
  POP HL
  LD BC,$0008
  LDIR
  POP HL
  LD DE,$0008
  ADD HL,DE
  ADD IX,DE
  POP AF
  DEC A
  JR NZ,l_6543
  JR l_656F
l_6566:
  LD DE,$0008
  ADD IX,DE
  POP AF
  DEC A
  JR NZ,l_6543
l_656F:
  LD A,(SortKey)
  INC A
  LD (SortKey),A
  CP $FF
  JR NZ,l_653C
  LD HL,Screen
  LD DE,SortedCatalogue
  LD BC,$0800
  LDIR
  RET

; the digits 0-9, then every name of the order chosen, 24 rows a column,
; columns 10 cells apart
;
; Used by the routines at Start and ToggleOrder.
ListFiles:
  CALL PrintDigits
  LD A,(CatalogueOrder)
  CP $00
  JR NZ,l_6595
  LD DE,Catalogue
  JR l_6598
l_6595:
  LD DE,SortedCatalogue
l_6598:
  LD A,(FileCount)
  LD BC,$0008
  LD HL,0*256+2
l_65A1:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  CALL SetPrintPosition
  CALL PR_STRING
  POP BC
  POP DE
  POP HL
  INC DE
  INC DE
  INC DE
  INC DE
  INC DE
  INC DE
  INC DE
  INC DE
  INC H
  LD A,H
  CP $18
  JR NZ,l_65C2
  LD H,$00
  LD A,$0A
  ADD A,L
  LD L,A
l_65C2:
  POP AF
  DEC A
  JR NZ,l_65A1
  RET

; "0-" to "9-" in the first column's ten rows
;
; Used by the routine at ListFiles.
PrintDigits:
  LD HL,$0000
  LD A,$00
  LD B,$0A
l_65CE:
  PUSH HL
  PUSH BC
  PUSH AF
  CALL SetPrintPosition
  ADD A,$30
  RST $10
  LD A,$2D
  RST $10
  POP AF
  POP BC
  POP HL
  INC H
  INC A
  DJNZ l_65CE
  RET

; the cursor bar: 4 cells of $71 at the cursor's row and column (+1)
;
; Used by the routines at Start, CursorUp, CursorDown, CursorRight, CursorLeft,
; ToggleOrder and Run.
HighlightCursor:
  LD HL,(CursorColumn)
  LD IX,Attrs
  INC IX
  LD A,H
  CP $00
  JR Z,l_65F8
l_65F0:
  LD DE,$0020
  ADD IX,DE
  DEC A
  JR NZ,l_65F0
l_65F8:
  LD A,L
  CP $00
  JR Z,l_6602
l_65FD:
  INC IX
  DEC A
  JR NZ,l_65FD
l_6602:
  CALL HighlightRow
  LD B,$04
l_6607:
  LD (IX+$00),$71
  INC IX
  DJNZ l_6607
  RET

; the menu's texts, CP866: title, credit, status, help
; (src/res/text/trd-boot-menu.txt)
;
; PR_STRING prints them with counted lengths (BC), so no terminators: 16, 22,
; 19, 20 bytes, four 42-byte help lines, then 21 and 30.
Texts:
  INCBIN "trd/text/trd-boot-menu.bin",$0000,16
TextCredit:
  INCBIN "trd/text/trd-boot-menu.bin",$0010,22
TextReading:
  INCBIN "trd/text/trd-boot-menu.bin",$0026,19
TextSorting:
  INCBIN "trd/text/trd-boot-menu.bin",$0039,20
TextHelp2:
  INCBIN "trd/text/trd-boot-menu.bin",$004D,42
TextHelp3:
  INCBIN "trd/text/trd-boot-menu.bin",$0077,42
TextHelp4:
  INCBIN "trd/text/trd-boot-menu.bin",$00A1,42
TextHelp1:
  INCBIN "trd/text/trd-boot-menu.bin",$00CB,42
TextEdit:
  INCBIN "trd/text/trd-boot-menu.bin",$00F5,21
TextSsCs:
  INCBIN "trd/text/trd-boot-menu.bin",$010A,30

; the number of BASIC files listed
FileCount:
  DEFB $00

; SortCatalogue's current first character
SortKey:
  DEFB $00

; the file under the cursor: row + 24 * column
CursorIndex:
  DEFB $00

; 0 the disk's order (Catalogue), 1 sorted (SortedCatalogue)
CatalogueOrder:
  DEFB $00

; the cursor's column cell (0, 5, ... 25) ...
CursorColumn:
  DEFB $00

; ... and row (0-23): read and written as one word with CursorColumn
CursorRow:
  DEFB $00

; TR-DOS function 5: 9 sectors from track 0 sector 0 to Catalogue
;
; Used by the routine at Start.
ReadCatalogue:
  LD HL,Catalogue
  LD DE,$0000
  LD B,$09
  LD C,$05
  CALL TRDOS_ENTRY
  RET

; six RET bytes: unused
SpareRets:
  DEFB $C9,$C9,$C9,$C9,$C9,$C9

; unused: B sectors between HL and the disk at track D, sector E+1, by the
; FDC's ports (through TRDOS_CALL)
;
; No call in the program reaches it (it is a library routine of the author's
; loader). C bit 0 selects the transfer: 0 reads with the TR-DOS ROM's
; sector-read loop $3FE5 (command $80), 1 writes with $3FCA (command $A0); D's
; bit 0 is the side. It restores the head (command 8), seeks to the track
; ($18), then for each sector sets the sector register and starts the command,
; waiting at $67E9 for INTRQ with a time-out (FdcTimeout) that restarts the
; whole transfer. FdcCommand writes the FDC's command port $1F through the
; TR-DOS ROM's OUT (C),A ($2A53), FdcPort any port, FdcWait polls the status
; ($3C30, IN A,($1F)) until not busy.
FdcSectors:
  LD (FdcSide),A
  RR C
  LD IX,$3FE5
  LD A,$80
  JP NC,l_676B
  LD IX,$3FCA
  LD A,$6F
  LD (FdcWaitIntrq+$000C),A
  LD A,$A0
l_676B:
  LD (FdcCommandCode),A
  LD A,$5F
  LD (FdcWaitIntrq+$000C),A
  LD A,$FF
  LD (FdcTimeout),A
  LD A,$08
  CALL FdcCommand
  CALL FdcWait
l_6780:
  LD A,(FdcSide)
  ADD A,$3C
  LD C,D
  SRL C
  JR NC,l_678C
  SUB $10
l_678C:
  PUSH BC
  LD C,$FF
  CALL FdcPortIY
  POP BC
  LD A,C
  LD C,$7F
  CALL FdcPortIY
  LD A,$18
  CALL FdcCommand
  CALL FdcWait
; This entry point is used by the routine at FdcWaitIntrq.
l_67A1:
  PUSH HL
  CALL FdcTransfer
  CALL FdcWaitIntrq
  POP HL
  LD A,B
  CP $00
  RET Z
  INC H
  INC E
  LD A,E
  CP $10
  JR Z,l_67B7
  DJNZ l_67A1
  RET
l_67B7:
  LD E,$00
  INC D
  DEC B
  JP l_6780

; one sector: sector register, the command, then the ROM's read or write loop
; (IX)
;
; Used by the routine at FdcSectors.
FdcTransfer:
  PUSH DE
  LD A,E
  INC A
  LD C,$5F
  CALL FdcPortIY
  LD D,$14
  DI
  LD C,$1F
  LD A,(FdcCommandCode)
  CALL FdcPortIY
  LD C,$7F
  CALL FdcRomCall
  POP DE
  EI
  RET

; A to the FDC's command register ($1F) through the TR-DOS ROM
;
; Used by the routine at FdcSectors.
FdcCommand:
  LD C,$1F
  LD IY,$2A53

; A to port C through the ROM routine IY
;
; Used by the routines at FdcSectors and FdcTransfer.
FdcPortIY:
  PUSH IY
  JP TRDOS_CALL

; the TR-DOS ROM routine IX
;
; Used by the routines at FdcTransfer, FdcWaitIntrq and FdcWait.
FdcRomCall:
  PUSH IX
  JP TRDOS_CALL

; wait for the end of the command (status bit 3? the ROM's $3C30): a 255-frame
; time-out
;
; Used by the routine at FdcSectors.
FdcWaitIntrq:
  PUSH IX
  PUSH IY
  LD IX,$3C30
  CALL FdcRomCall
  BIT 3,A
  JR NZ,l_6802
l_67F8:
  LD A,$FF
  LD (FdcTimeout),A
  POP IY
  POP IX
  RET
l_6802:
  LD A,(FdcTimeout)
  DEC A
  HALT
  LD (FdcTimeout),A
  CP $00
  JR Z,l_67F8
  POP IY
  POP IX
  POP HL
  POP HL
  JR l_67A1

; wait while the FDC is busy (status bit 0)
;
; Used by the routine at FdcSectors.
FdcWait:
  PUSH IY
  PUSH IX
  PUSH AF
l_681B:
  LD IX,$3C30
  CALL FdcRomCall
  BIT 0,A
  JR NZ,l_681B
  POP AF
  POP IX
  POP IY
  RET

; the time-out counter
FdcTimeout:
  DEFB $00

; FdcSpare
FdcSpare:
  DEFB $FF,$00

; the side flag FdcSectors keeps (written, then added to the system register
; value $3C)
FdcSide:
  DEFB $00

; the transfer's command ($80 read, $A0 write)
FdcCommandCode:
  DEFB $00

; the screen and attributes zeroed by PUSH from ClearStackTop down (216 x 16 x
; 2 = 6912 bytes); border black
;
; Used by the routines at Start and Run.
ClearScreen:
  PUSH BC
  PUSH AF
  PUSH IX
  XOR A
  OUT ($FE),A
  LD (SavedSp),SP
  LD SP,ClearStackTop
  LD B,$D8
  LD IX,$0000
l_6845:
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  PUSH IX
  DJNZ l_6845
  LD SP,(SavedSp)
  POP IX
  POP AF
  POP BC
  RET

; ClearScreen's SP while it pushes
SavedSp:
  DEFW $0000

; after the catalogue read: the TR-DOS ROM's drive and controller reset, with
; TR-DOS's errors trapped
;
; Calls TR-DOS ROM routines through TRDOS_CALL1: $2FC1 (select the drive),
; $2A53 with A = 8 C = $1F (restore the head), $2076 under the trap
; (DriveCall), $1FF3 and $1FEB, $2FC1 again. TRDOS_HOOK is put back to RET
; before the last calls. The routines' names in TR-DOS 5.0x are not checked
; here: what they do is read from the arguments only.
DriveReset:
  LD IX,$2FC1
  CALL RomCall
  LD A,$08
  LD C,$1F
  LD IX,$2A53
  CALL RomCall
  LD A,$FF
  LD (TRDOS_5CD8),A
  LD B,$00
  CALL DriveCall
  PUSH AF
  LD A,$C9
  LD (TRDOS_HOOK),A
  XOR A
  LD IX,$1FF3
  CALL RomCall
  LD IX,$1FEB
  CALL RomCall
  LD IX,$2FC1
  CALL RomCall
  POP AF
  RET

; the TR-DOS ROM routine IX (PUSH IX: JP TRDOS_CALL1)
;
; Used by the routines at DriveReset and DriveCall.
RomCall:
  PUSH IX
  JP TRDOS_CALL1

; $2076 with TR-DOS's error hook set to JP DriveTrap: an error returns here
; with A = 0 instead of a BASIC report
;
; Used by the routine at DriveReset.
DriveCall:
  LD (DriveTrap+$0001),SP
  LD A,$C3
  LD (TRDOS_HOOK),A
  LD HL,DriveTrap
  LD (TRDOS_HOOK+1),HL
  LD IX,$2076
  JP RomCall

; TR-DOS's error hook jumps here: the SP DriveCall saved (the operand), A = 0,
; RET to DriveReset
DriveTrap:
  LD SP,0
  XOR A
  RET
