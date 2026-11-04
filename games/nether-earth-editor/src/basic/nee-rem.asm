; nee.bas line 1: the machine code in its REM, $5D16-$5D5E (23830-23902), 73 bytes. docs/02-architecture.md (editor).
;
; The line's first statement, RANDOMIZE USR 23830, runs TrapInstall: from then on every BASIC error that would stop
; the editor (a tape loading error, BREAK, an INPUT the user cut short, a number out of range ...) lands in TrapError,
; which sends the program to line 146 ("E R R O R", a key, GO TO 2: the main menu) instead of the ROM's report.
; OK, "8 End of file" and "9 STOP statement" still go to the ROM's report.
;
; The code assumes the program starts at $5CCB (PROG on a 48K without Interface 1): USR 23830 is its own address. It
; does not depend on that itself: TrapInstall finds its own address on the stack, so the code runs wherever the REM
; lies. tools/zxbasic.py puts these bytes into the REM ({<nee-rem.bin} in src/basic/nee.bas).

  DEVICE ZXSPECTRUM48

ERR_NR   EQU $5C3A       ; IY+$00: the error code - 1, $FF for none
FLAGS    EQU $5C3B       ; IY+$01: bit 7 set = running a program (not checking syntax)
ERR_SP   EQU $5C3D       ; the address of the error return on the machine stack
NEWPPC   EQU $5C42       ; the line to jump to
NSPPC    EQU $5C44       ; the statement in it
UNUSED1  EQU $5C81       ; two system variable bytes the ROM never uses (23681)
ROM_RET  EQU $007C       ; a RET in the ROM (the end of SKIP-OVER, TEMP-PTR2)
KEY_SCAN EQU $028E       ; ROM KEY-SCAN: E = the key, $FF when none
MAIN_4   EQU $1303       ; ROM MAIN-4: print the report, wait for a key, back to the editor
STMT_R_1 EQU $1B7D       ; ROM STMT-R-1: go on running at NEWPPC / NSPPC

ERROR_LINE EQU 146       ; nee.bas line 146: the ERROR screen

  ORG $5D16

; TrapInstall (USR 23830): make the error return on the machine stack point to TrapError.
TrapInstall:
  CALL ROM_RET           ; pushes $5D19 and returns at once ...
  DEC SP
  DEC SP
  POP HL                 ; ... and takes it again: HL = $5D19, this code's own address
  LD BC,TrapError-$5D19  ; 15
  ADD HL,BC
  EX DE,HL               ; DE = TrapError
  LD HL,(ERR_SP)
  LD (HL),E              ; the error return address (the ROM's MAIN-4 path) replaced:
  INC HL                 ; the ROM's error restart (ERROR-2: LD SP,(ERR_SP), RET)
  LD (HL),D              ; now comes here
  RET

; TrapError: the ROM's error exit returns here (SP = ERR_SP + 2), ERR_NR holds the error.
TrapError:
  DEC SP                 ; leave TrapError's address on the stack: ERR_SP points to it again, the trap stays set
  DEC SP
.release:
  CALL KEY_SCAN          ; wait until no key is held (BREAK released)
  LD A,E
  CP $FF
  JR NZ,.release
  LD A,(ERR_NR)
  CP $FF                 ; "0 OK"
  JR Z,.report
  CP $07                 ; "8 End of file"
  JR Z,.report
  CP $08                 ; "9 STOP statement"
  JR Z,.report
  INC A                  ; the report code (1-based) kept at 23681, which nee.bas never reads
  LD (UNUSED1),A
  LD (IY+$00),$FF        ; ERR_NR: no error
  LD HL,ERROR_LINE
  LD (NEWPPC),HL         ; GO TO 146
  XOR A
  LD (NSPPC),A           ; its first statement
  SET 7,(IY+$01)         ; FLAGS: running
  JP STMT_R_1            ; the interpreter goes on at line 146
.report:
  INC SP                 ; the trap's address off the stack, as the ROM's own error path leaves it
  INC SP
  JP MAIN_4              ; the ROM's report: the program stops

  SAVEBIN "nee-rem.bin",TrapInstall,$-TrapInstall
