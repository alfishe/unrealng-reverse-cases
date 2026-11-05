; Nether Earth ZS Edition '98 (ZS, 23.12.1998): the BASIC, sectors 0-1 of NEZSEd.B (512 bytes; TR-DOS loads the
; file's 340 bytes to PROG = $5D3B and runs line 10).
;
; Hand-written source (two BASIC lines, a 41-instruction loader, a dead 77-instruction one and the sectors'
; slack: too small for an annotation); every byte of the two sectors is here. Built by tools/build_intro98.sh
; into build/intro98/basic.bin and compared with work/media/98/basic.bin (tools/zs_media.py).
;
; The program (340 bytes, $5D3B-$5E8E; VARS = $5E8F, no variables):
;   line 1   REM <RemLoader> <the title string> <spaces>        $5D3B-$5DD5  (the loader's code and data)
;   line 10  CLEAR VAL "26495": RANDOMIZE USR VAL "23872"        $5DD6-$5DEE  (RAMTOP $677F; USR $5D40 = RemLoader)
;   then     160 bytes inside the program area after the last line (NXTLIN = $5DEF): Loader128, a 128 K loader of
;            an earlier build, assembled for $5D95, never run (see Loader128 below)
; and after it, in the rest of sector 1 (172 bytes, $5E8F-$5F3A): TR-DOS's tail of the saved file (4 bytes) and
; 168 bytes of slack, src/res/intro98/basic98-slack.bin.
;
; Witness: recording r98 (work/stage1/r98). The L1 window work/stage2/intro98/w-rem (frames 2000-2048): RemLoader
; $5D40-$5D81 run once, its bold-font loop ($5D55-$5D65) 384 times; the intro window w-intro (frames 2048-4500):
; $5D84-$5D91 once (after IntroMain returned at frame 4331), JP $A600 into the game at frame 4500. Nothing in
; $5D97-$5F3A runs in either window (no execute there; stage 1 found none in the whole recording).

  DEVICE ZXSPECTRUM128

; The 48 K BASIC ROM
RomBorder      EQU $229B  ; BORDER's body: A = the colour (also into BORDCR)
RomCls         EQU $0D6B  ; CLS: the whole screen cleared, channel 2 (the upper screen) open
RomPrString    EQU $203C  ; PR-STRING: BC bytes from DE to the current channel
RomFont        EQU $3D00  ; the ROM's character set, 96 glyphs from code $20
; TR-DOS (through its ROM's entry points in $3Dxx, which page it in)
TrDosEntry     EQU $3D13  ; TR-DOS's entry from BASIC: C = 5 reads B sectors from track D sector E to HL
TrDosRet       EQU $3D2F  ; TR-DOS ROM: NOP / RET: JP here pages TR-DOS in and RETs to the address on the stack
TrDosOutC      EQU $2A53  ; TR-DOS ROM: OUT (C),A / RET (a port of the WD1793 written)
TrDosReadSect  EQU $2090  ; TR-DOS ROM: the sector read (command $80, INI loop), then POP HL / LD A,(HL) / CP 1
TrDosWaitIrq   EQU $3EF5  ; TR-DOS ROM: wait for the controller's INTRQ (port $FF bit 7)
; System variables
CHARS          EQU $5C36  ; the character set - 256
DosSector      EQU $5CD6  ; TR-DOS's work byte: the sector being read (Loader128 checks it after each read)
DosNextSector  EQU $5CF4  ; TR-DOS: the sector (E) and track (D) after the last one read
DosDrive       EQU $5CF6  ; TR-DOS: the current drive (0-3)
ATTR_P         EQU $5C8D  ; the permanent colours
; Where the loader reads to
BoldFont       EQU $C000  ; the bold copy of the ROM font, overwritten by the intro block right after the title
IntroBlock     EQU $C000  ; NEZSEd.B sectors 2-43 (42 sectors, $C000-$E9FF): src/intro98/intro98.asm
IntroMain      EQU $D88F  ; the intro's entry (src/intro98/intromain.asm)
GameBlock      EQU $6780  ; NEZSEd.B sectors 44-156 (113 sectors, $6780-$D87F): src/game98/game98.asm
GameStart      EQU $A600  ; the game's entry

; BASIC tokens
TkREM          EQU $EA
TkCLEAR        EQU $FD
TkVAL          EQU $B0
TkRANDOMIZE    EQU $F9
TkUSR          EQU $C0

  ORG $5D3B

; Line 1: REM, then the loader's code and data
Line1:
  DEFB $00,$01            ; line number 1 (high byte first)
  DEFW Line1End-Line1Text ; the text's length: 151
Line1Text:
  DEFB TkREM

; RemLoader: the title, then the intro, then the game
;
; Entered by line 10's RANDOMIZE USR 23872 (r98, window w-rem). The screen white on black with a black border; the
; ROM font copied in bold to BoldFont and made the character set; the title printed with it; then the 42 sectors
; after this file's two (TR-DOS left their position in DosNextSector) read to $C000 (over the bold font: the title
; is already on the screen), IntroMain CALLed (it plays until a key, r98 frames 2048-4331), the game's 113
; sectors read to $6780 (over the player and the tune at $C000-$D87F) and the game entered at $A600 (frame 4500).
; Never returns.
RemLoader:
  LD A,$07                ; white ink on black paper ...
  LD (ATTR_P),A
  XOR A                   ; ... a black border ...
  CALL RomBorder
  CALL RomCls             ; ... and the screen cleared
  LD HL,RomFont           ; the 96 glyphs of the ROM font ...
  LD DE,BoldFont
  LD BC,$0180             ; ... 384 pairs of pixel rows
BoldLoop:
  LD A,(HL)               ; an even row: the row ORed with itself shifted right one pixel (OR clears the carry,
  RRA                     ; so RRA brings in 0)
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  LD A,(HL)               ; an odd row: shifted right two pixels (the row's bit 0 comes back as bit 7: only the
  RRA                     ; glyph $7F, the copyright sign, has bit 0 set on odd rows, so its right edge shows at
  RRA                     ; its left on rows 3 and 5)
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  DEC BC
  LD A,B
  OR C
  JR NZ,BoldLoop
  LD BC,BoldFont-256      ; CHARS = $BF00: the bold font is the character set
  LD (CHARS),BC
  LD DE,Title             ; the title (46 bytes) to channel 2, which CLS left open
  LD BC,TitleEnd-Title
  CALL RomPrString
  LD HL,IntroBlock        ; the intro block: 42 sectors to $C000-$E9FF
  LD DE,(DosNextSector)
  LD BC,$2A05             ; B = 42 sectors, C = 5: read
  CALL TrDosEntry
  CALL IntroMain          ; the intro, until a key (it returns with the screen faded out)
  LD HL,GameBlock         ; the game: 113 sectors to $6780-$D87F
  LD DE,(DosNextSector)
  LD BC,$7105             ; B = 113 sectors, C = 5: read
  CALL TrDosEntry
  JP GameStart

; The title, printed by RemLoader in the bold font: AT 0,8 "ZS'98 Presents:", ENTER, "    NETHER EARTH ZS EDITION"
Title:
  DEFB $16,$00,$08        ; AT 0,8
  DEFM "ZS'98 Presents:"
  DEFB $0D
  DEFM "    NETHER EARTH ZS EDITION"
TitleEnd:
  DEFM "                "    ; $5DC5-$5DD4: 16 spaces no code reads (the REM's padding)
  DEFB $0D                ; the line's ENTER
Line1End:

; Line 10: CLEAR VAL "26495": RANDOMIZE USR VAL "23872" (VAL of a string: no hidden 5-byte numbers in the line)
Line10:
  DEFB $00,$0A            ; line number 10
  DEFW Line10End-Line10Text ; 21
Line10Text:
  DEFB TkCLEAR,TkVAL
  DEFM "\"26495\""        ; RAMTOP = 26495 = $677F, below the game block's $6780
  DEFB ":",TkRANDOMIZE,TkUSR,TkVAL
  DEFM "\"23872\""        ; 23872 = $5D40: RemLoader
  DEFB $0D
Line10End:

; Loader128: a 128 K loader left from an earlier build (160 bytes, $5DEF-$5E8E, inside the program area but after
; its last line, so BASIC never sees it; never run, known from the code only)
;
; Its absolute operands fit only one place: assembled for $5D95 (DISP below; it lies $5A bytes higher, at $5DEF).
; There every CALL and every pushed address lands on an instruction of its own: Load128Block ($5DCD), WdOut
; ($5E06), WdCall ($5E0A), Seek128 ($5E0E), Load128Done ($5DF1), and Load128Ret ($5DDA) whose first byte is $01,
; the byte TR-DOS's sector read checks (TrDosReadSect: POP HL / LD A,(HL) / CP 1, RET on equal). $5D95 is 2 bytes
; before the end of this file's RemLoader, so it was made for another layout of line 1 (one without the title
; there; the earlier build itself is not known: not in Advanced Nether Earth either). In this file nothing jumps
; here, and at $5DCD, where its CALLs go, there are only the title's spaces: run here, it would crash.
;
; What it does: cancels 128 K BASIC's flag (RES 4,(IY+1)), reads with its own WD1793 code (through TR-DOS's ROM
; routines) from where TR-DOS stopped: 62 sectors to bank 1 at $C000, 37 to bank 7 at $DB00, 5 to bank 4 at $FB00;
; then pages bank 1 in, pokes a RET over $5D4A (in this file a byte of RemLoader's CALL RomCls; what it was in
; that layout is not known), and returns to BASIC with DE = $1303 (MAIN-4) and HL = $1B76 (STMT-RET), the ROM's
; return addresses, BC = $5FFF.
  DISP $5D95
Loader128:
  RES 4,(IY+1)            ; FLAGS: not 128 K BASIC
  LD HL,$C000
  LD A,$51                ; bank 1 (ROM 1: 48 K BASIC) ...
  LD B,$3E                ; ... 62 sectors to $C000-$FDFF
  LD DE,(DosNextSector)
  CALL Load128Block
  LD A,$57                ; bank 7: 37 sectors to $DB00-$FFFF
  LD B,$25
  LD H,$DB
  CALL Load128Block
  LD A,$54                ; bank 4: 5 sectors to $FB00-$FFFF
  LD B,$05
  LD H,$FB
  CALL Load128Block
  LD A,$51                ; bank 1 paged in for good
  OUT ($FD),A
  LD A,$C9                ; RET over $5D4A
  LD ($5D4A),A
  LD DE,$1303
  LD BC,$5FFF
  LD HL,$1B76
  EI
  RET

; One block: A = the page ($7FFD value; OUT ($FD),A puts A on the high half of the port, $51FD-$57FD decode as
; $7FFD), B sectors from track D sector E (0-15) to HL. Each sector: the head moved when the track is new (Seek128),
; the sector register, then TR-DOS's read with Load128Ret on the stack; the read is repeated while DosSector shows
; TR-DOS stepped it (its error path).
Load128Block:
  OUT ($FD),A
  INC A                   ; never 0 here: the block starts with a seek
Load128Seek:
  CALL NZ,Seek128         ; the DJNZ below comes back here: NZ (a new track) seeks, Z (the same track) does not
Load128Sector:
  LD A,E                  ; DosSector = E, the sector register = E + 1 (the WD1793 counts from 1)
  LD (DosSector),A
  INC A
  PUSH HL
  PUSH BC
Load128Ret:
  LD BC,Load128Done       ; TrDosReadSect's RET goes there (this instruction's $01 is what it checks)
  PUSH BC
  LD C,$5F                ; the sector register
  CALL WdOut
  LD BC,Load128Ret        ; for TrDosReadSect's POP HL / LD A,(HL) / CP 1
  PUSH BC
  LD BC,TrDosReadSect
  PUSH BC
  LD BC,$017F             ; C = $7F: the data register for its INI
TrDosJump:
  JP TrDosRet             ; TR-DOS paged in, RET to the address on the stack
Load128Done:
  DI
  LD A,(DosSector)        ; unchanged: the sector was read; else read it again
  CP E
  POP BC
  POP HL
  JR NZ,Load128Sector
  INC H                   ; the next 256 bytes
  INC E                   ; the next sector; after 15 the next track
  BIT 4,E
  JR Z,Load128Next        ; Z: the same track, no seek
  RES 4,E
  INC D                   ; NZ: a new track, Load128Seek moves the head
Load128Next:
  DJNZ Load128Seek
  RET

; A to the WD1793 port C through TR-DOS's OUT (C),A
WdOut:
  LD IX,TrDosOutC
WdCall:                   ; IX = a TR-DOS ROM routine, run with its RET back to the caller
  PUSH IX
  JR TrDosJump

; Seek128: the drive and side selected for track D (bit 0 = the side), the head moved to track D / 2
Seek128:
  LD A,(DosDrive)         ; the system register ($FF): the drive, no reset, head load ...
  OR $2C
  BIT 0,D
  JR NZ,Seek128Side
  OR $3C                  ; ... bit 4 set: side 0
Seek128Side:
  LD C,$FF
  CALL WdOut
  LD A,D                  ; the data register: the physical track
  RRA
  LD C,$7F
  CALL WdOut
  LD A,$18                ; SEEK, head loaded
  LD C,$1F
  CALL WdOut
  LD IX,TrDosWaitIrq      ; until the seek has finished
  CALL WdCall
  DI
  RET
  ENT

; The rest of sector 1: TR-DOS's tail of the saved file, then the slack
  DEFB $80                ; the end of the (empty) variables area
  DEFB $AA                ; TR-DOS: the autostart mark ...
  DEFW 10                 ; ... and the line it runs: 10
; 168 bytes no code reads ($5E93-$5F3A), the memory after the program when the file was saved, kept as they are in
; src/res/intro98/basic98-slack.bin (src/res/intro98/README.md). Known from the bytes only, by offset:
;   +$00 (8)   45 2E 22 CA 31 30 0D 80: the end of an edit line, 'E." LINE 10' ENTER, its first three bytes
;              overwritten by the four above (it began at E_LINE = $5E90): the SAVE ... LINE 10 that wrote the file?
;   +$08 (13)  "15616" + the hidden number 15616 ($3D00) + ENTER + $80: an older edit line's tail, a RANDOMIZE USR
;              15616 (TR-DOS's command line)
;   +$15 (19)  the calculator's workspace (two 5-byte numbers 93 5F 03 00 00 00 ...)
;   +$28 (66)  an old machine stack: ROM return addresses ($1F54, $02DB, $0DF3, $0BCE, $0ADC, $18D7, $33B1, $1303,
;              $1B76 at the top, $5EF9-$5EFC) between screen addresses ($50E4, $50E5, $50EB); +$6A: one byte $13
;   +$6B (61)  a Z80 fragment from $5EFE: an edit line built (a token, a quoted 8-character name, CODE for type 'C',
;              ENTER), CALLs to $6AA8, $6C79, $6C35 and CH_ADD = E_LINE: a disk shell's code, cut off at the sector's
;              end
  INCBIN "res/intro98/basic98-slack.bin",0,168

  SAVEBIN "basic.bin",$5D3B,512
