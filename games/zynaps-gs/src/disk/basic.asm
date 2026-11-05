; basic.asm: "ZYNAP_GS", the BASIC program the disk starts with (TR-DOS: RUN or RUN "ZYNAP_GS"), and the rest of
; its sector as the disk has it. docs/03-build-and-load.md 3.2.
;
; The catalogue gives the file 255 sectors from track 1 sector 0, but its length is 65: TR-DOS's RUN loads one
; sector to PROG ($5D3B, TR-DOS has moved CHANS) and starts line 1. The program is:
;
;   1 RANDOMIZE USR VAL "23882"        $5D4A: the machine code that follows the line
;
; The code is not a BASIC line: its first two bytes ($F3 $AF, DI and XOR A) would be the line number $F3AF, which
; is past 16383, so BASIC sees the end of the program there. The REM after the code carries the author's credit.
; BootLoader reads the next two sectors over the program (to $5D3B) and returns into them: the boot code
; (src/disk/boot/, the generated source of src/disk/boot.ann).
;
;   sjasmplus src/disk/basic.asm   ->  build/disk/basic.bin (256 bytes: the disk's sector 1:0)

  DEVICE ZXSPECTRUM128

TRDOS_ENTRY   EQU $3D13  ; the TR-DOS ROM's entry for machine code: C = the function (5: read B sectors from D:E to HL)
TRDOS_5D06    EQU $5D06  ; TR-DOS system variables zeroed before the read (the same bytes the TR-DOS read paths use)
TRDOS_5D10    EQU $5D10
TRDOS_SECTOR  EQU $5CF4  ; TR-DOS: the track and sector after the last one read (here 1:1, past this sector)
BORDCR        EQU $5C48  ; the border colour and the lower screen's attribute
BootStart     EQU $5D3B  ; where the two boot sectors go: the boot code's first instruction (src/disk/boot.ann)

  ORG $5D3B
Program:
; line 1: RANDOMIZE USR VAL "23882"
  DB $00,$01            ; the line number, 1 (high byte first)
  DW Line1End-Line1     ; the line's length
Line1:
  DB $F9,$C0,$B0        ; RANDOMIZE USR VAL
  DB '"23882"'          ; = BootLoader
  DB $0D
Line1End:

; BootLoader: RANDOMIZE USR 23882 enters here. Two sectors from track 1 sector 1 over the program itself, then
; RET into them (the return address BootStart pushed first).
BootLoader:
  DI
  XOR A
  LD SP,$8000
  LD HL,BootStart
  PUSH HL               ; the read's "return": the boot code
  LD (TRDOS_5D10),A
  LD (TRDOS_5D06),A
  LD (BootLoader+11),A  ; a zero into this code's own operand (the LD above has run): no effect
  LD (BORDCR),A         ; a black border, black lower screen
  LD DE,(TRDOS_SECTOR)  ; the next sector, 1:1
  LD BC,$0205           ; B = 2 sectors, C = 5: read
  JP TRDOS_ENTRY        ; to HL = $5D3B, then RET to it
BootLoaderEnd:

; the author's credit: REM bytes after the code, never run nor listed
  DB $EA,"MIKE BLUM (C)1997",$0D
ProgramEnd:

; TR-DOS's autostart mark after the program: $80, $AA and the line (1)
  DB $80,$AA
  DW 1

; The rest of the sector: what TR-DOS's SAVE found in the buffer past the program (older memory of the author's
; machine). Not read by anything.
  DB 0,0,0,0,0,0,0,0, $0D,$80,0,0,0,0,0,$0E, 0,0,0,$3D,0,$0D,$80,$CA, $80,$5E,$06,0,0,0,$80,$5E
  DB $06,0,0,0,$01
  DS $87-($-Program),0
  DB $B1,$33,$8C,$5E,$07
  DS 256-($-Program),0

  ASSERT ProgramEnd-Program == 65
  SAVEBIN "build/disk/basic.bin",Program,256
