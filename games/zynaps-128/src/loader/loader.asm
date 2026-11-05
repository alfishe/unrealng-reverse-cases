; --------------------------------------------------------------------------------------------------------------------
; loader.asm: ZYNAPS.B's BASIC: the REM loader and its RUN line
;
; TR-DOS's RUN "ZYNAPS" (the boot's list, or the user on the SCL) loads one sector of ZYNAPS.B: the catalogue says 168
; bytes (one sector) of a file of 137. The program is two lines. Line 0 is a REM whose text is the loader's machine
; code from $5D40; line 1, the autostart line, is CLEAR VAL "24575": RANDOMIZE USR VAL "23872" (23872 = $5D40).
;
; The loader reads the rest of the file by sector number from where TR-DOS's LOAD stopped (TRDOS_NEXT): sector 1, the
; depacker, to $5B00; 56 sectors (block 1, the intro) to $6000, unpacked in place and called; 79 sectors (block 2, the
; game) to $6000, unpacked in place. A key then starts the game's relocator at $6000.
;
; The "2 in 1" is decided here: a paging test writes 1 (128K) or 0 (48K) over the high byte of line 0's number, $5D3B
; (Is128); the intro and the game's set-up read it. The intro later zeroes $5D40 and $5D41 (the first two bytes of
; this code, which ran once) and uses them as the option flags INF.LIVES and K-MOUSE.
; --------------------------------------------------------------------------------------------------------------------

; line 0: the number (0; its high byte becomes the 128K flag), the length
; (139), REM
;
; The line number's high byte, $5D3B, is overwritten by SetIs128 with the
; paging test's result: 1 = the machine pages (128K), 0 = 48K. The intro (block
; 1) and the game's set-up (block 2) read it there. BASIC never runs this line
; again (the RANDOMIZE USR does not come back).
Is128:
  DEFB $00,$00,$8B,$00,$EA

; the REM's machine code: TR-DOS's hook, the stack for BASIC, channel P, the
; 128K test, the loads
;
; Entered from line 1's RANDOMIZE USR VAL "23872". Writes POP AF: RET ($F1 $C9)
; to TRDOS_HOOK so a TR-DOS error returns quietly, then calls the next
; instruction, LoaderBody. Its first two bytes become the option flags later
; (the intro zeroes them: $5D40 INF.LIVES, $5D41 K-MOUSE).
Loader:
  LD HL,$C9F1             ; F1 C9: POP AF, RET
  LD (TRDOS_HOOK),HL
  CALL LoaderBody         ; the next instruction, as a call

; the stack for a return to BASIC, channel P, the 128K test, the depacker, both
; blocks, a key, the game
;
; Reached by Loader's CALL (its return address is dropped at once). SP goes to
; the error return (ERR_SP), whose entry is replaced by ROM_MAIN_4 under
; ROM_STMT_RET: the shape of a USR's return, though nothing returns that way
; (the game never comes back). FLAGS bit 4 off (48 BASIC); channel P's
; addresses back to the ROM's.
;
; The paging test (IsItA128): $7FFD = $10 (bank 0, the 48 BASIC ROM) and $10 to
; $C000; $7FFD = $11 (bank 1) and $11 to $C000; $7FFD = $10 again and CP
; ($C000). On a 128K the read finds $10 (two pages): L = 1. On a 48K the port
; does nothing and the second write hit the same byte: $11, L = 0. Bank 1 keeps
; the $11, the only byte of it the program writes.
;
; Then the depacker to $5B00, block 1 read and unpacked and its intro called,
; block 2 read and unpacked, the border blue for three frames, a key, and JP
; $6000: block 2's relocator.
LoaderBody:
  DI                      ; the stack rebuilt so a later RET would end the
                          ; statement in BASIC
  LD SP,(ERR_SP)           ; the stack at the error return (ERR_SP)
  POP HL                  ; drop it
  LD HL,ROM_MAIN_4             ; MAIN-4, under STMT-RET: the return path of a USR
  PUSH HL
  LD HL,ROM_STMT_RET
  PUSH HL
  RES 4,(IY+$01)          ; FLAGS bit 4 off: 48 BASIC
  LD DE,ROM_CHANS_P             ; channel P's output and input addresses back to the
                          ; ROM's (TR-DOS's printer hook undone)
  LD HL,(CHANS)
  LD BC,$000F
  ADD HL,BC
  EX DE,HL
  LD C,$04
  LDIR
IsItA128:
  LD A,$10                ; the paging test: $10 and $11 to page 0's and page
                          ; 1's $C000, then page 0 read back
  LD HL,PagedSlot
  LD BC,$7FFD
  OUT (C),A
  LD (HL),A
  INC A
  OUT (C),A
  LD (HL),A
  DEC A
  OUT (C),A
  CP (HL)
  JR NZ,SetIs128
  INC L                   ; a 128K: L = 1 (H:L = $C001)
SetIs128:
  LD A,L                  ; the flag over line 0's number
  LD (Is128),A
  LD B,$01                ; sector 1 (the depacker) to $5B00
  LD HL,Depack
  CALL ReadSectors
  LD B,$38                ; block 1 (56 sectors): read to $6000, unpacked in
                          ; place
  CALL LoadBlock
  CALL BlockStart              ; the intro: the three pictures, the options, the
                          ; tune (128K)
  LD B,$4F                ; block 2 (79 sectors): read to $6000, unpacked in
                          ; place
  CALL LoadBlock
WaitKey:
  EI                      ; the border blue for three frames, black, then a key
  HALT
  LD A,$01
  OUT ($FE),A
  HALT
  HALT
  HALT
  XOR A
  OUT ($FE),A
WaitAnyKey:
  HALT                    ; until any key of any row is down (IN A,($FE) with A
                          ; = 0)
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR Z,WaitAnyKey
  JP BlockStart                ; the game's relocator (block 2's $6000)

; B sectors to $6000, then the depacker unpacks them in place
;
; Input: B = the sector count. Reads them through ReadSectors (TR-DOS goes on
; from TRDOS_NEXT), then JP Depack with HL = DE = $6000 (the packed block and
; its destination are the same place: the depacker moves the block to the end
; first). The depacker's RET returns to LoadBlock's caller.
LoadBlock:
  LD HL,BlockStart
  PUSH HL
  PUSH HL
  CALL ReadSectors
  POP HL
  POP DE
  DI
  JP Depack

; B sectors from the next one TR-DOS would read, to HL
;
; Input: B = the sector count, HL = the address. C = 5 (TR-DOS's read), DE =
; TRDOS_NEXT; JP TRDOS_ENTRY, whose RET returns to the caller. Leaves
; TRDOS_NEXT on the sector after the last.
ReadSectors:
  LD C,$05
  LD DE,(TRDOS_NEXT)
  DI
  JP TRDOS_ENTRY

; line 0's ENTER, then line 1: number 1, length 21, CLEAR VAL "24575":
; RANDOMIZE USR VAL "23872"
Line0End:
  DEFB $0D
  DEFB $00,$01,$15,$00    ; line 1: the number (big-endian), the length
  DEFB $FD,$B0,$22,$32,$34,$35,$37,$35 ; CLEAR VAL "24575": RAMTOP under $6000
  DEFB $22
  DEFB $3A,$F9,$C0,$B0,$22,$32,$33,$38 ; : RANDOMIZE USR VAL "23872": the
  DEFB $37,$32,$22                     ; loader at $5D40
  DEFB $0D                ; ENTER

; TR-DOS's autostart mark after the program: $80 $AA and the line, 1
Autostart:
  DEFB $80,$AA,$01,$00
