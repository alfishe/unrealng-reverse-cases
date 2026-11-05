; neart482.asm: the TRD's file "Neart482" (BASIC, 116 bytes, 112 sectors from track 114 sector 5), all 112 sectors
; as the disk holds them: KIDSON of RAPEWARE CORP.'s intro (December 1995) and their Russian Nether Earth, one
; self-extracting block inside another. src/trd/neart482/README.md.
;
;   sector 0       the BASIC program (1 RANDOMIZE USR VAL "23881" + the loader's code in the same line), TR-DOS's
;                  autostart mark, zeros and a note (SectorNote)
;   sectors 1-111  the outer block (Block, at $6978): unpacks the intro (intro.asm) to $5FB4-$EF2D, jumps to its
;                  IntroStart; 137 bytes of older memory after it
;
; Run from the boot menu (RUN "Neart482"): line 1's USR 23881 enters Loader, the bytes right after the VAL string.
;
; Built by tools/build_trd_extras.sh: intro.asm gives build/trd/obj/n482-outer.bin, tools/trd_lz.py packs it
; (--raw 9) into build/trd/obj/n482-outer.lz, which this file takes (-Ibuild).
;
;   sjasmplus --fullpath -Ibuild src/trd/neart482/neart482.asm   ->  build/trd/Neart482.bin (28672 bytes)

  DEVICE NONE
  INCLUDE "lzsfx.asm"

PROG            EQU $5D3B   ; where TR-DOS loads a BASIC program
BORDER_PORT     EQU $FE
ERR_SP          EQU $5C3D   ; the BASIC error stack pointer
BORDCR          EQU $5C48   ; the border colour / lower screen attribute
ATTR_P          EQU $5C8D   ; the permanent attribute
TRDOS_HOOK      EQU $5CC2   ; TR-DOS's error hook (a RET normally)
NEXT_SECTOR     EQU $5CF4   ; TR-DOS: the sector after the last read
CLS             EQU $0D6B   ; the 48 ROM's CLS
TRDOS_ENTRY     EQU $3D13   ; C = 5: read B sectors from D:E to HL
TRDOS_CALL      EQU $3D2F   ; a RET in the TR-DOS ROM: the address under it runs with TR-DOS paged in
TRDOS_1FF3      EQU $1FF3   ; a TR-DOS ROM routine run with A = 0 before the block (as the menu's DriveReset does)
LOADER_STACK    EQU $5FB3   ; under the intro's output
BLOCK           EQU $6978
BLOCK_SECTORS   EQU 111
INTRO           EQU $5FB4
INTRO_END       EQU $EF2D
INTRO_START     EQU $5FD9   ; IntroStart (intro.asm)
OUTER_LEN       EQU 28148   ; the outer stream with its 9 raw bytes

  OUTPUT "build/trd/Neart482.bin"

; ----- sector 0 ----------------------------------------------------------------------------------------------------
  ORG PROG
Program:
Line1:
  DB 0,1
  DW Line1End - Line1Text
Line1Text:
  DB $F9,$C0,$B0,'"23881"'  ; RANDOMIZE USR VAL "23881": the code right after this string
; Loader ($5D49): the screen black, the error hook made harmless, three border flashes, the outer block read to
; BLOCK and run through the TR-DOS ROM (TRDOS_1FF3 first, then RET into Block).
Loader:
  LD SP,LOADER_STACK
  XOR A
  OUT (BORDER_PORT),A
  LD (ATTR_P),A
  LD (BORDCR),A
  LD (ERR_SP),A             ; ERR_SP's low byte zeroed (the stack is replaced: BASIC is not returned to)
  CALL CLS
  LD HL,$C9F1               ; POP AF; RET into TR-DOS's error hook: an error returns to the caller of the call
  LD (TRDOS_HOOK),HL
  LD A,1                    ; blue ...
  OUT (BORDER_PORT),A
  EI
  LD BC,11                  ; ... for 11 frames
.wait1:
  LD A,B
  OR C
  JR Z,.flash2
  DEC BC
  HALT
  JR .wait1
.flash2:
  LD A,6                    ; yellow for 9
  OUT (BORDER_PORT),A
  EI
  LD BC,9
.wait2:
  LD A,B
  OR C
  JR Z,.flash3
  DEC BC
  HALT
  JR .wait2
.flash3:
  LD A,4                    ; green for 11
  OUT (BORDER_PORT),A
  EI
  LD BC,11
.wait3:
  LD A,B
  OR C
  JR Z,.load
  DEC BC
  HALT
  JR .wait3
.load:
  DI
  XOR A
  OUT (BORDER_PORT),A
  LD DE,(NEXT_SECTOR)       ; the file's sector 1
  LD HL,BLOCK
  LD BC,BLOCK_SECTORS * 256 + 5     ; B = 111 sectors, C = 5: read
  CALL TRDOS_ENTRY
  XOR A
  LD HL,Block
  PUSH HL                   ; TRDOS_1FF3's RET goes to Block
  LD HL,TRDOS_1FF3
  PUSH HL
  JP TRDOS_CALL
  DB $0D
Line1End:
ProgramEnd:
  DB $80,$AA                ; TR-DOS's autostart mark ...
  DW 1                      ; ... line 1
  DS $98 - ($ - PROG), 0
; A note in the sector's tail, past the program (nothing reads it): src/res/text/trd-neart482-sector-note.txt,
; docs/texts/trd-neart482-sector-note.md
SectorNote:
  INCBIN "trd/text/trd-neart482-sector-note.bin"
  DS 256 - ($ - PROG), 0

  ASSERT Loader == 23881
  ASSERT ProgramEnd - Program == 116

; ----- sectors 1-111: the outer block --------------------------------------------------------------------------------
  ORG BLOCK                 ; fileorg-ok: the output goes on with sector 1, now at the load address
Block:
  LZ_SFX $5B8D, INTRO, INTRO_END, "trd/obj/n482-outer.lz", OUTER_LEN, INTRO_START
BlockEnd:
  ASSERT BlockEnd == $D7EF
; the rest of sector 111: older memory, not read
  INCBIN "../../res/trd/neart482/block-tail.bin"
  ASSERT $ == BLOCK + BLOCK_SECTORS * 256
