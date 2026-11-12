; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC program, its loader in line 4, the autostart mark and the sector's tail
;
; Sector 0 of boot, the BASIC program TR-DOS loads at PROG $5D3B and starts at line 10 (the autostart mark $80 $AA $0A
; $00 after the program). The program's lines: 1 RANDOMIZE USR VAL "15619": REM : RUN "        " (the launch line the
; menu rewrites); 2 RANDOMIZE USR VAL "15619": REM : RUN; 3 RANDOMIZE USR VAL "15616"; 4 REM with the loader's machine
; code; 10 BORDER NOT PI: PAPER NOT PI: INK VAL "7": CLEAR VAL "65347": RANDOMIZE USR VAL "23936": RUN.
;
; RANDOMIZE USR 15619 is TR-DOS's entry for a command in a BASIC line: the statement after the REM is a TR-DOS
; command. Lines 2 and 3 are not reached in any recording (line 1's command runs the chosen file and does not come
; back); line 3, USR 15616, would enter TR-DOS's command line.
; --------------------------------------------------------------------------------------------------------------------

; Line 1: RANDOMIZE USR VAL "15619": REM : RUN "        " (26 bytes): the
; launch line
;
; Rewritten by the menu's launcher RunLetter $6A51 just before it returns: the
; token at $5D4C (LaunchToken) becomes RUN ($F7) for a BASIC file or GO TO
; ($EC) for a 192-sector CODE file, the 8 characters at $5D4E (LaunchName) the
; file's name, and the byte at $5D57 (LaunchSuffix) a space for RUN or the
; token CODE ($AF) for GO TO. Line 10's RUN then starts the program at this
; line, and TR-DOS runs the command.
;
; Witness: c2 ran TEST 03 and c3 ran TEST 30 after the menu wrote RUN "T03 "
; and RUN "T30     " here (the screens at the end of the recordings).
LaunchLine:
  INCBIN "res/basic/launch-lines.bin",$0000,17
LaunchToken:
  INCBIN "res/basic/launch-lines.bin",$0011,2
LaunchName:
  INCBIN "res/basic/launch-lines.bin",$0013,9
LaunchSuffix:
  INCBIN "res/basic/launch-lines.bin",$001C,2

; Line 2: RANDOMIZE USR VAL "15619": REM : RUN (15 bytes; not reached in any
; recording)
;
; A TR-DOS RUN without a name runs "boot" again. The program only gets here if
; line 1's command returns to BASIC without an error; no recording does.
LineTwo:
  INCBIN "res/basic/launch-lines.bin",$001E,19

; Line 3: RANDOMIZE USR VAL "15616" (11 bytes; not reached in any recording)
;
; USR 15616 enters TR-DOS's command line (the A> prompt).
LineThree:
  INCBIN "res/basic/launch-lines.bin",$0031,15

; Line 4: the header (line number, length 71) and the REM token before the
; loader
;
; The loader's code follows the REM token $EA at $5D7F; the line's $0D is at
; $5DC5.
LineFour:
  DEFB $00,$04,$47,$00,$EA

; Clear the menu's memory, read the code, the graphics and the music from the
; disk, run the menu, clear again
;
; Entered by line 10's RANDOMIZE USR 23936 with TR-DOS's TrdosNextSector $5CF4
; pointing at the sector after sector 0 of boot (TR-DOS just loaded the
; program). Clears $61A8-$FEAF (LDIR of $9D08 bytes), then three TrdosEntry
; $3D13 reads (C = 5), each starting at TrdosNextSector: 15 sectors to
; MenuStart $61A8 ($61A8-$70A7), 8 sectors to MenuGraphics $A600 ($A600-$ADFF),
; 22 sectors to MusicPiece $C000 ($C000-$D5FF). Then CALL MenuStart: the menu
; returns here when a file is chosen, with the launch line already rewritten.
; Clears $61A8-$FEAF again and returns to BASIC, which goes on with line 10's
; RUN.
;
; The memory is cleared because the menu builds its tables and buffers in the
; zero bytes between its pieces ($70A8-$A5FF, $AE00-$BFFF, $D600-$FEAF) and the
; program it starts should find clean memory.
;
; Witness: L1 4 (c x4).
Loader:
  LD HL,MenuStart
  LD DE,$61A9
  LD BC,$9D07
  LD (HL),$00
  LDIR
  LD HL,MenuStart             ; the code: 15 sectors from the sector after the
                          ; BASIC
  LD DE,(TrdosNextSector)
  LD BC,$0F05
  CALL TrdosEntry
  LD HL,MenuGraphics             ; the font and the graphics: 8 sectors
  LD DE,(TrdosNextSector)
  LD BC,$0805
  CALL TrdosEntry
  LD HL,MusicPiece             ; the music: 22 sectors
  LD DE,(TrdosNextSector)
  LD BC,MusicSectors*256+5
  CALL TrdosEntry
  CALL MenuStart              ; the menu: returns once a file is chosen (RunLetter)
  LD HL,MenuStart             ; clear the menu's memory again, then RET to BASIC
  LD DE,$61A9
  LD BC,$9D07
  LD (HL),$00
  LDIR
  RET

; Line 4's end ($0D)
LineFourEnd:
  DEFB $0D

; Line 10: BORDER NOT PI: PAPER NOT PI: INK VAL "7": CLEAR VAL "65347":
; RANDOMIZE USR VAL "23936": RUN
;
; The autostart line: black border and paper, white ink, RAMTOP $FF43 (the
; menu's stack $FCBC and IM 2 table $FD00-$FE00 lie below it), the loader
; $5D80, then RUN, which clears the variables and runs line 1.
LineTen:
  INCBIN "res/basic/line-ten.bin",$0000,41

; The program's end ($80) and TR-DOS's autostart mark: $AA and the line, 10
;
; TR-DOS writes the line number after $AA when a program is saved with LINE;
; RUN "boot" starts the program there.
AutostartMark:
  INCBIN "res/basic/line-ten.bin",$0029,4

; The sector's leftover bytes after the program: not loaded, not read
;
; 72 bytes that were in memory after the program when it was saved: `oot27"
; LINE 10` reads like the end of a `SAVE "boot27" LINE 10` statement, followed
; by number bytes and zeros. TR-DOS does not load them (it loads only the
; program and the autostart mark, $5D3B-$5DF2: at c1 frame 446 $5E07-$5E3A are
; zeros), and the Loader starts at the next sector, so they stay on the disk;
; the build reproduces them because the file holds them. A resource
; (spare/basic-tail.bin, bytes): in most variants they name another SAVE
; (`boot12`, `boot32`).
SectorTail:
  INCBIN "res/spare/basic-tail.bin",$0000,72
