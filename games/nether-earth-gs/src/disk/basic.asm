; basic.asm: "neart GS", the BASIC program the disk starts with (TR-DOS: RUN "neart GS"; on the TRD also key 1 of
; the boot menu). docs/03-build-and-load.md 3.2.
;
; The program is the listing src/res/text/disk-basic.txt, tokenized by tools/basic_tok.py into
; build/res/text/disk-basic.bin (67 bytes):
;
;   10 CLEAR 24999                                      RAMTOP $61A7: the loader goes at $61A8
;   20 RANDOMIZE USR 15619:REM :LOAD "neart022"CODE     $3D03: TR-DOS runs the command after the REM: the loader
;                                                       neart022 to its catalogue address $61A8 (25000)
;   30 RANDOMIZE USR 25e3                               runs it: LoaderStart (src/disk/loader.asm). 25e3 is the
;                                                       authors' spelling; its number form is the integer 25000
;
; The file: the program, then TR-DOS's autostart mark ($80 $AA and the line, 10), as TR-DOS SAVE writes it after a
; program saved with LINE. The rest of the file's sector is not part of this source: zeros on the SCL, older memory
; on the TRD (src/media/trd.txt, src/res/media/README.md).
;
;   sjasmplus -Ibuild src/disk/basic.asm   ->  build/disk/basic.bin (71 bytes)

  OUTPUT "build/disk/basic.bin"
  ORG 0
Program:
  INCBIN "res/text/disk-basic.bin"
ProgramEnd:
; TR-DOS's autostart mark after the program
  DB $80,$AA
  DW 10
