; basic.asm: "NetherE GS", Hood's tape BASIC (961 bytes, LINE 10), 2017. docs/03-build-and-load.md 3.3.
;
; The program is the listing src/res/text/tape-basic.txt, tokenized by tools/basic_tok.py into
; build/res/text/tape-basic.bin. It does the disk loader's work line by line: every file is a standard tape block
; loaded with LOAD "" CODE, and after each one a RANDOMIZE USR enters the loader neart0222 (src/tape/loader.asm) at
; the code that sends that file to the General Sound.
;
;   1   REM: "Conversion from TRD by Hood.7.4.2017.hood.speccy.cz"
;   10  colours, CLEAR 24999 (RAMTOP below the loader), the menu "1-music ON" / "2-music OFF"
;   11  waits for 1 or 2 (a$)
;   13  POKE 23739,111: the low byte of channel S's output routine ($09F4 -> $096F), the usual trick that keeps the
;       ROM's "Bytes: name" messages off the screen; the loader neart0222 and the loading screen neart000;
;       USR 25561 TickReturn (the first tick of the progress box)
;   16  "2": POKE 25311,201 (RET at StartModule: no #31), USR 25516 MusicOff (#F4 only), five ticks for the five
;       module files it does not load, GO TO 30
;   20  "1": USR 25022 GsStartModule (#F4 #30 #D1), the module neart002-006 each followed by its SendModule entry
;       (25037 ... 25073, the last one closing the stream)
;   30-50  the effects in the card's order 1-14: neart007-016, neart017 (the file the disk loader missed), neart018,
;       neart023, neart019 and neart020 (effect 14), each followed by its SendFx entry (25086 ... 25254); the last
;       one pages RAM bank 6 at $C000
;   60  neart021 (the driver, into bank 6), USR 25273 PageBank0; the game neart001, USR 25286 StartGame (the
;       module on, the volumes, JP $A600)
;
;   sjasmplus -Ibuild src/tape/basic.asm   ->  build/tape/basic.bin (961 bytes)

  OUTPUT "build/tape/basic.bin"
  ORG 0
Program:
  INCBIN "res/text/tape-basic.bin"
