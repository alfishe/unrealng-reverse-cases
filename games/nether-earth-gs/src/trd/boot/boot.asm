; boot.asm: the TRD's file "boot" (BASIC, 172 bytes, 13 sectors from track 1 sector 0), all 13 sectors as the disk
; holds them. TR-DOS runs it first (the name boot); its menu RUNs the file chosen. src/trd/boot/README.md.
;
;   sector 0       the BASIC program (Program, 172 bytes), TR-DOS's autostart mark, 80 bytes of older memory
;   sectors 1-12   the menu's HRUM 3.5 block (MenuBlock, loaded to $61A8 by line 1's code), the packer's credit,
;                  a filler of $CD bytes
;
; The program:
;
;   1 REM <code at $5D40: Boot>
;   2 CLEAR 24999 : RANDOMIZE USR 23872
;   3 CLEAR 65500 : RANDOMIZE USR 15619 : REM : RUN "        "
;
; Line 1 is run from line 2 (USR 23872 = $5D40, the REM's first byte). Boot clears the screen, reads 20 sectors
; from the next sector on (the 12 of the block and 8 more, see Boot) to $61A8, calls the block (it unpacks the menu
; to $61A8-$71AB and returns) and jumps to the menu (Start, src/trd/boot/menu.asm). The menu writes the chosen file's
; name over line 3's 8 spaces (RunName = $5DDD) and returns: BASIC goes on to line 3, which passes RUN "name" to
; TR-DOS (RANDOMIZE USR 15619: the rest of the line after the REM is a TR-DOS command).
;
; Built by tools/build_trd_extras.sh: the menu's two parts (boot-menu.asm, boot-print64.asm) are assembled, joined
; into build/trd/obj/menu.bin (4100 bytes) and packed by tools/hrum.py (--prefer 2348:264, NOTES-trd.md); this file
; takes the stream and the tail from there (-Ibuild).
;
;   sjasmplus --fullpath -Ibuild src/trd/boot/boot.asm   ->  build/trd/boot.bin (3328 bytes)

  DEVICE NONE
  INCLUDE "hrum35.asm"

PROG            EQU $5D3B   ; where TR-DOS loads a BASIC program (PROG with the TR-DOS system variables)
SCREEN          EQU $4000
SCREEN_LENGTH   EQU 6912
BORDER_PORT     EQU $FE
NEXT_SECTOR     EQU $5CF4   ; TR-DOS: the track and sector after the last read (the file's next sector)
TRDOS_ENTRY     EQU $3D13   ; TR-DOS's machine-code entry: C = 5 reads B sectors from D:E to HL
TRDOS_READ      EQU 5
MENU            EQU $61A8   ; the block's address and the unpacked menu's (Start, src/trd/boot/menu.asm)
MENU_LENGTH     EQU 4100    ; $61A8-$71AB
READ_SECTORS    EQU 20      ; 12 of the block, then 8 more: past the file's end (TRDOS_ENTRY reads on along the disk)

  OUTPUT "build/trd/boot.bin"

; ----- sector 0: the BASIC program --------------------------------------------------------------------------------
  ORG PROG
Program:
Line1:
  DB 0,1                    ; line 1
  DW Line1End - Line1Text
Line1Text:
  DB $EA                    ; REM: the code follows
; Boot ($5D40): run by line 2's USR 23872. Clears the screen and the border, loads the block and the 8 sectors
; after it to MENU, unpacks (CALL: the block returns) and runs the menu (JP: the menu's RET ends the USR).
Boot:
  LD HL,SCREEN
  LD DE,SCREEN + 1
  LD BC,SCREEN_LENGTH - 1
  LD (HL),0
  LDIR                      ; the screen and its attributes zeroed
  XOR A
  OUT (BORDER_PORT),A       ; the border black
  LD HL,MENU
  LD DE,(NEXT_SECTOR)       ; the file's sector 1 (TR-DOS left the position after loading sector 0)
  LD B,READ_SECTORS
  LD C,TRDOS_READ
  CALL TRDOS_ENTRY          ; sectors 1-12 and the 8 that follow on the disk (neart GS and 7 of neart000): the
                            ; depacker never reads them, they are overwritten by the unpacked menu
  CALL MENU                 ; MenuBlock: the menu unpacked over itself, RET
  JP MENU                   ; Start: the menu
  DS Line1Text + 91 - $,' '  ; the REM's room, spaces (the line is 92 bytes)
  DB $0D
Line1End:
Line2:
  DB 0,2                    ; line 2
  DW Line2End - Line2Text
Line2Text:
  DB $FD,"24999",$0E,0,0    ; CLEAR 24999 (and its hidden number: 24999 = $61A7, RAMTOP under the menu)
  DW 24999
  DB 0
  DB ":",$F9,$C0,"23872",$0E,0,0   ; : RANDOMIZE USR 23872
  DW Boot
  DB 0,$0D
Line2End:
Line3:
  DB 0,3                    ; line 3
  DW Line3End - Line3Text
Line3Text:
  DB $FD,"65500",$0E,0,0    ; CLEAR 65500
  DW 65500
  DB 0
  DB ":",$F9,$C0,"15619",$0E,0,0   ; : RANDOMIZE USR 15619 (TR-DOS's command entry $3D03)
  DW 15619
  DB 0
  DB ":",$EA,":",$F7,'"'    ; : REM : RUN "
RunName:                    ; $5DDD: the menu writes the file's name here
  DB "        "
  DB '"',$0D
Line3End:
ProgramEnd:
  DB $80,$AA                ; TR-DOS's autostart mark ...
  DW 1                      ; ... line 1
  ; the rest of the sector: older memory (the end of a BASIC line and variables), not the program's
  INCBIN "../../res/trd/boot/sector0-tail.bin"

  ASSERT RunName == $5DDD
  ASSERT Boot == $5D40
  ASSERT $ == PROG + 256

; ----- sectors 1-12: the menu's HRUM block ------------------------------------------------------------------------
; HRUM_SFX (hrum35.asm): DI, the caller's SP into the copy's LD SP, the 119-byte depacker run at $4000 (the cleared
; screen), the menu unpacked to $61A8-$71AB, the last 5 bytes from the depacker's tail, EI, RET to Boot.
  ORG MENU                  ; fileorg-ok: the output goes on with the next sector, now at the load address
MenuBlock:
  HRUM_SFX 0, 1, SCREEN, MENU, MENU_LENGTH, "trd/obj/menu.hrum", 2685, "trd/obj/menu.bin", 0, 1, 0
MenuBlockEnd:
; After the stream: the packer's credit, which HRUM 3.5 writes after the blocks it makes (lines ended by $80, the
; last by $81; src/res/text/trd-boot-hrum-credit.txt, docs/texts/trd-boot-hrum-credit.md). Nothing reads it.
HrumCredit:
  INCBIN "trd/text/trd-boot-hrum-credit.bin"
; the rest of the 12 sectors: the filler byte $CD
  DS MENU + 12 * 256 - $, $CD

  ASSERT MenuBlockEnd == $6CBB
  ASSERT $ == MENU + 12 * 256
