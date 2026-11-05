; neart481.asm: the TRD's file "Neart481" (BASIC, 572 bytes, 171 sectors from track 103 sector 10), all 171 sectors
; as the disk holds them: a 128K Nether Earth ("ASM COMPILATION OF ROBOT WARS/FACTORIES/ALIENS" in its packed
; data), a BASIC program whose line 1 loads six packed blocks into four RAM banks. src/trd/neart481/README.md.
;
;   sectors 0-2     the BASIC program (Program, 572 bytes), TR-DOS's autostart mark (line 10), 192 bytes of older
;                   memory
;   sectors 3-170   six blocks, read by Loader one after another (each read goes on from the sector the last ended)
;
; The program:
;
;   1 REM <code at $5D40: Loader>
;   10 BORDER NOT PI : CLEAR VAL "24999"
;   20 RANDOMIZE USR VAL "23872"
;   39 FOR n = VAL "50431" TO VAL "50433" : POKE n,NOT PI : NEXT n
;   40 POKE VAL "23388",VAL "19" : OUT VAL "32765",VAL "19" : RANDOMIZE USR VAL "57800"
;   41 POKE VAL "23388",VAL "22" : OUT VAL "32765",VAL "22" : RANDOMIZE USR VAL "65004"
;   42 POKE VAL "23388",VAL "16" : OUT VAL "32765",VAL "16" : RANDOMIZE USR VAL "24110" : RANDOMIZE USR VAL "42496"
;
; Line 20 runs Loader: it reads and runs the blocks (below) and returns to the statement after the USR, so BASIC
; goes on at line 39: three zero bytes at $C4FF-$C501 (bank 0), then bank 3's TitleTune (it plays until SPACE),
; bank 6's SamplePlayer, bank 0 again, FadeAttributes and the game's Start. (BANKM = 23388 is the 128's copy of
; port $7FFD = 32765; 19 = $13 bank 3, 22 = $16 bank 6, 16 = $10 bank 0, each with the 48 ROM.)
;
; The blocks are kept as bytes (src/res/trd/neart481/*.bin). Five are self-extracting blocks of one packer: DI, the
; caller's SP kept, a 192-byte depacker copied to $5B00, the stream moved up with LDDR, unpacked in place, the last
; 5 bytes from the depacker's tail, EI, RET. Its offsets use Hrust 1's codes (3, 4, 5 and 6-bit prefixes: v+1, v-1,
; v-9, v&31) and its bits come by POP from 16-bit words as Hrust 1's do: Hrust 1 (Dmitry Pyankov) in its
; self-extracting form, by the depacker's code (the disk does not name it and the signature base has no entry).
; Its length codes differ from the screen form tools of ../advanced-nether-earth (bootmenu_hrust.py); no packer
; for this form is written yet (work/stage2/NOTES-trd.md).
;
;   sjasmplus --fullpath -Ibuild src/trd/neart481/neart481.asm   ->  build/trd/Neart481.bin (43776 bytes)

  DEVICE NONE

PROG            EQU $5D3B   ; where TR-DOS loads a BASIC program
ATTRS           EQU $5800
ATTRS_END_HIGH  EQU $5B     ; the attributes end at $5AFF
ERR_SP          EQU $5C3D
NEWPPC          EQU $5C42
NSPPC           EQU $5C44
PPC             EQU $5C45
SUBPPC          EQU $5C47
CHANS           EQU $5C4F
TRDOS_HOOK      EQU $5CC2   ; TR-DOS's error hook: TrappedCall writes JP Trap there
TRDOS_5CD8      EQU $5CD8   ; a TR-DOS work byte DriveReset sets to $FF
NEXT_SECTOR     EQU $5CF4   ; TR-DOS: the sector after the last read
ROM_MAIN_4      EQU $1303   ; the 48 ROM's report exit (MAIN-4): an error's return through ERR_SP
ROM_STMT_RET    EQU $1B76   ; the 48 ROM's STMT-RET: Loader's RET goes on with the next statement
ROM_CHANNEL_P   EQU $15BE   ; the 48 ROM's initial channel data, channel P's two addresses
TRDOS_ENTRY     EQU $3D13   ; C = 5: read B sectors from D:E to HL
TRDOS_CALL1     EQU $3D30   ; the TR-DOS ROM's RET trick: PUSH an address, JP here
PAGE_PORT       EQU $7FFD
PAGE_BANK0      EQU $10     ; port $7FFD: the 48 ROM and RAM bank 0 at $C000 (+1 bank 1, +3 bank 3, ...)
BANK_WINDOW     EQU $C000   ; each banked block runs where it is loaded

; the program's entries in the blocks (after they unpacked)
SCREEN_BLOCK    EQU $7530   ; ScreenBlock: the loading screen (run once, then overwritten)
TITLE_TUNE      EQU $E1C8   ; bank 3 (line 40, USR 57800): plays the title tune (init $D396, one step a HALT) until
                            ; SPACE, then its stop ($D388), RET
SAMPLE_PLAYER   EQU $FDEC   ; bank 6 (line 41, USR 65004): an AY sample player (registers 2, 3 and 9; its table
                            ; pointer at $FDE8)
GAME_START      EQU $A600   ; line 42, USR 42496: the game's Start (bank 0's block unpacked to $61A8 on)
GAME_POKES      EQU 50431   ; line 39: $C4FF-$C501 zeroed in bank 0 before the game

  OUTPUT "build/trd/Neart481.bin"

; ----- sectors 0-2: the BASIC program --------------------------------------------------------------------------------
  ORG PROG
Program:
Line1:
  DB 0,1
  DW Line1End - Line1Text
Line1Text:
  DB $EA                    ; REM: the code follows
; Loader ($5D40, line 20's USR 23872): BASIC's return made safe, the blocks read and run one after another, RET to
; line 20's next statement (STMT-RET), so BASIC goes on at line 39.
Loader:
  LD HL,ROM_MAIN_4
  PUSH HL
  LD (ERR_SP),SP            ; a BASIC error now ends in the ROM's report, not in a stale stack
  LD HL,ROM_STMT_RET
  PUSH HL                   ; Loader's RET: STMT-RET
  LD HL,(PPC)
  LD (NEWPPC),HL            ; this line ...
  LD A,(SUBPPC)
  INC A
  LD (NSPPC),A              ; ... its next statement
  LD HL,(CHANS)
  LD DE,15
  ADD HL,DE                 ; channel P (the fourth channel, 5 bytes each)
  LD DE,ROM_CHANNEL_P
  EX DE,HL
  LD BC,4
  LDIR                      ; its output and input addresses back to the ROM's
  RES 4,(IY+1)              ; FLAGS bit 4: 48 BASIC
  CALL FadeAttributes       ; the screen fades out
  LD A,PAGE_BANK0
  LD HL,SCREEN_BLOCK
  LD B,12
  CALL LoadBlock            ; sectors 3-14 to $7530
  CALL SCREEN_BLOCK         ; the loading screen
  LD A,PAGE_BANK0 + 6
  LD HL,BANK_WINDOW
  LD B,45
  CALL LoadBlock            ; sectors 15-59 to bank 6
  CALL BANK_WINDOW          ; unpacked in place
  LD A,PAGE_BANK0 + 3
  LD HL,BANK_WINDOW
  LD B,15
  CALL LoadBlock            ; sectors 60-74 to bank 3
  CALL BANK_WINDOW
  LD A,PAGE_BANK0 + 4
  LD HL,BANK_WINDOW
  LD B,10
  CALL LoadBlock            ; sectors 75-84 to bank 4
  CALL BANK_WINDOW
  LD A,PAGE_BANK0 + 1
  LD HL,BANK_WINDOW
  LD B,14
  CALL LoadBlock            ; sectors 85-98 to bank 1
  CALL BANK_WINDOW
  LD A,PAGE_BANK0
  LD HL,$61A8
  LD B,72
  CALL LoadBlock            ; sectors 99-170 to $61A8-$A9A7 (bank 0 paged)
  CALL DriveReset
  CALL $61A8                ; the game unpacked
  EI
  RET                       ; STMT-RET: line 39

; LoadBlock: A to the paging port, B sectors from the file's next sector to HL
LoadBlock:
  PUSH BC
  LD BC,PAGE_PORT
  OUT (C),A
  POP BC
  LD DE,(NEXT_SECTOR)
  LD C,5
  CALL TRDOS_ENTRY
  RET

; DriveReset: the TR-DOS ROM's drive and controller reset after the reads, its errors trapped (the same routine as
; the boot menu's DriveReset, src/trd/boot/menu.asm)
DriveReset:
  LD IX,$2FC1
  CALL RomCall
  LD A,8                    ; restore the head ...
  LD C,$1F                  ; ... through the FDC's command port
  LD IX,$2A53
  CALL RomCall
  LD A,$FF
  LD (TRDOS_5CD8),A
  LD B,0
  CALL TrappedCall
  PUSH AF
  LD A,$C9                  ; the error hook a RET again
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

; RomCall: the TR-DOS ROM routine IX
RomCall:
  PUSH IX
  JP TRDOS_CALL1

; TrappedCall: the TR-DOS ROM's $2076 with the error hook set to JP Trap
TrappedCall:
  LD (Trap + 1),SP
  LD A,$C3
  LD (TRDOS_HOOK),A
  LD HL,Trap
  LD (TRDOS_HOOK + 1),HL
  LD IX,$2076
  JP RomCall

; Trap: TR-DOS's error hook jumps here: TrappedCall's SP, A = 0, back to DriveReset
Trap:
  LD SP,0                   ; the operand TrappedCall writes
  XOR A
  RET

; FadeAttributes ($5E2E; also line 42's USR 24110): every attribute's ink and paper one step darker, 7 times with a
; delay (bright and flash are dropped on the first pass)
FadeAttributes:
  LD B,7
.pass:
  LD HL,ATTRS
.cell:
  LD A,(HL)
  LD E,A
  AND 7                     ; the ink ...
  CP 0
  JR Z,.inkDone
  DEC A                     ; ... one darker
.inkDone:
  LD D,A
  LD A,E
  AND $38
  OR D
  LD E,A                    ; the paper with the new ink
  RRA
  RRA
  RRA
  AND 7                     ; the paper ...
  CP 0
  JR Z,.paperDone
  DEC A                     ; ... one darker
.paperDone:
  RLA
  RLA
  RLA
  LD D,A
  LD A,E
  AND 7
  OR D
  LD (HL),A
  INC HL
  LD A,H
  CP ATTRS_END_HIGH
  JR NZ,.cell
  LD DE,$0FA0               ; a delay
.delay:
  DEC DE
  LD A,D
  CP 0
  JR NZ,.delay
  DJNZ .pass
  RET
  DS Line1Text + 348 - $,' '   ; the REM's room, spaces (the line is 349 bytes)
  DB $0D
Line1End:

  ASSERT Loader == 23872
  ASSERT LoadBlock == $5DC3
  ASSERT DriveReset == $5DD4
  ASSERT FadeAttributes == 24110

; Lines 10-42: keywords as tokens, the numbers as VAL strings (no hidden number forms)
Line10:
  DB 0,10
  DW Line10End - $ - 2
  DB $E7,$C3,$A7,":",$FD,$B0,'"24999"',$0D      ; BORDER NOT PI : CLEAR VAL "24999"
Line10End:
Line20:
  DB 0,20
  DW Line20End - $ - 2
  DB $F9,$C0,$B0,'"23872"',$0D                  ; RANDOMIZE USR VAL "23872"
Line20End:
Line39:
  DB 0,39
  DW Line39End - $ - 2
  DB $EB,"n=",$B0,'"50431"',$CC,$B0,'"50433"'   ; FOR n=VAL "50431" TO VAL "50433"
  DB ":",$F4,"n,",$C3,$A7,":",$F3,"n",$0D       ; : POKE n,NOT PI : NEXT n
Line39End:
Line40:
  DB 0,40
  DW Line40End - $ - 2
  DB $F4,$B0,'"23388",',$B0,'"19"'              ; POKE VAL "23388",VAL "19"
  DB ":",$DF,$B0,'"32765",',$B0,'"19"'          ; : OUT VAL "32765",VAL "19"
  DB ":",$F9,$C0,$B0,'"57800"',$0D              ; : RANDOMIZE USR VAL "57800"
Line40End:
Line41:
  DB 0,41
  DW Line41End - $ - 2
  DB $F4,$B0,'"23388",',$B0,'"22"'              ; POKE VAL "23388",VAL "22"
  DB ":",$DF,$B0,'"32765",',$B0,'"22"'          ; : OUT VAL "32765",VAL "22"
  DB ":",$F9,$C0,$B0,'"65004"',$0D              ; : RANDOMIZE USR VAL "65004"
Line41End:
Line42:
  DB 0,42
  DW Line42End - $ - 2
  DB $F4,$B0,'"23388",',$B0,'"16"'              ; POKE VAL "23388",VAL "16"
  DB ":",$DF,$B0,'"32765",',$B0,'"16"'          ; : OUT VAL "32765",VAL "16"
  DB ":",$F9,$C0,$B0,'"24110"'                  ; : RANDOMIZE USR VAL "24110"
  DB ":",$F9,$C0,$B0,'"42496"',$0D              ; : RANDOMIZE USR VAL "42496"
Line42End:
ProgramEnd:
  DB $80,$AA                ; TR-DOS's autostart mark ...
  DW 10                     ; ... line 10
  ; the rest of sector 2: older memory (a fragment of another BASIC program, spaces, zeros), not the program's
  INCBIN "../../res/trd/neart481/basic-tail.bin"

  ASSERT ProgramEnd - Program == 572
  ASSERT $ == PROG + 3 * 256

; ----- sectors 3-170: the blocks ---------------------------------------------------------------------------------
; ScreenBlock (sectors 3-14, at $7530, bank 0 paged): finds its own address (CALL to a RET in the ROM, $33C5, then
; the return address read back under SP), puts three JP stubs at $5C94-$5C9B, unpacks the loading screen to $4000
; with its own depacker and returns.
  ORG SCREEN_BLOCK          ; fileorg-ok: each block follows the last in the file, at its load address
ScreenBlock:
  INCBIN "../../res/trd/neart481/screen-7530.bin"
; Bank 6 (sectors 15-59): the packer's block, unpacked in place at $C000; SAMPLE_PLAYER is in it
  ORG BANK_WINDOW           ; fileorg-ok
Bank6Block:
  INCBIN "../../res/trd/neart481/bank6-c000.bin"
; Bank 3 (sectors 60-74): unpacked in place; TITLE_TUNE is in it
  ORG BANK_WINDOW           ; fileorg-ok
Bank3Block:
  INCBIN "../../res/trd/neart481/bank3-c000.bin"
; Bank 4 (sectors 75-84): unpacked in place (what the game reads there is not traced here)
  ORG BANK_WINDOW           ; fileorg-ok
Bank4Block:
  INCBIN "../../res/trd/neart481/bank4-c000.bin"
; Bank 1 (sectors 85-98): unpacked in place (not traced either)
  ORG BANK_WINDOW           ; fileorg-ok
Bank1Block:
  INCBIN "../../res/trd/neart481/bank1-c000.bin"
; The game (sectors 99-170, at $61A8 with bank 0 at $C000): the packer's block, CALLed by Loader after DriveReset;
; it unpacks the game, whose Start is GAME_START
  ORG $61A8                 ; fileorg-ok
GameBlock:
  INCBIN "../../res/trd/neart481/game-61a8.bin"
