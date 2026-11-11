; --------------------------------------------------------------------------------------------------------------------
; basic-module.asm: The BASIC: line 0, whose USR enters the loader hidden in the variables area
;
; The program is one line, numbered 0 and auto-run (the header's LINE 0): RANDOMIZE USR (3+PEEK 23627+256*PEEK 23628),
; that is VARS + 3. LIST shows the digits "0", "00000", "000" and "00000": the five-byte forms after them hold 3,
; 23627, 256 and 23628. The line's length field says $FF36, far past the program's 58 bytes, so the ROM's line walk
; (LIST, editing, deleting) treats everything after the line as part of it.
;
; VARS $5D05 holds one string variable, l$ ($4C: a string named l), 241 bytes long: the loader $5D08-$5DF8. USR leaves
; its own address in BC, which the loader uses to find its parts, so it runs wherever PROG lies.
; --------------------------------------------------------------------------------------------------------------------

; Line 0: RANDOMIZE USR (0+(PEEK (00000)+000*PEEK (00000))), the hidden numbers
; 3, 23627, 256, 23628
;
; USR (3 + PEEK VARS + 256 x PEEK (VARS + 1)): VARS is the system variable at
; $5C4B; the call goes to VARS + 3 = $5D08, LoaderEntry, the first byte of l$'s
; text. The digits printed are zeros and the hidden five-byte forms are the
; real numbers, so LIST shows nothing useful. c1: the ROM runs the line after
; the load (USR at $34BB enters $5D08 at frame 696).
BasicLine0:
  DEFB $00,$00            ; the line number, 0 (high byte first)
  DEFB $36,$FF            ; the line's length, $FF36: runs past the program
  DEFB $F9,$C0,$28,$30    ; RANDOMIZE ($F9) USR ($C0) "(" "0"
  DEFB $0E,$00,$00,$03,$00,$00 ; $0E and 3
  DEFB $2B,$28,$BE,$28,$30,$30,$30,$30 ; "+(" PEEK ($BE) "(" "00000"
  DEFB $30
  DEFB $0E,$00,$00,$4B,$5C,$00 ; $0E and 23627 = $5C4B (VARS)
  DEFB $29,$2B,$30,$30,$30 ; ")+" "000"
  DEFB $0E,$00,$00,$00,$01,$00 ; $0E and 256
  DEFB $2A,$BE,$28,$30,$30,$30,$30,$30 ; "*" PEEK ($BE) "(" "00000"
  DEFB $0E,$00,$00,$4C,$5C,$00 ; $0E and 23628 = $5C4C
  DEFB $29,$29,$29,$0D    ; ")))" and ENTER

; The variables area: string variable l$, 241 bytes (the loader is its text)
;
; $4C = a string variable named l (bits 7-5 = 010), then its length $00F1 =
; 241: $5D08-$5DF8, the rest of the block. The ROM never evaluates l$; it is
; only a place the BASIC keeps intact.
LoaderString:
  DEFB $4C,$F1,$00

; The loader: break trap, clear, cheat test, load the screen and block 4, the
; setup, load the game
;
; Entered by line 0's USR with BC = $5D08 (its own address) and interrupts off
; by its DI. Position independent: it adds BC to three offsets: BreakMessage's
; address is patched into BreakHandler's LD HL operand ($5DA6), SP = $5FE6 and
; BreakHandler's address is pushed and ERR_SP pointed at it, so an error report
; (BREAK in LD-BYTES: "D BREAK - CONT repeats") lands in BreakHandler $5D83.
;
; The screen and attributes $4000-$5AFF cleared, border 0. Has128K $5FFE and
; GameLoaded $5FFF set to 0. InfiniteLives $5B03 = 1 when the byte at $8000 is
; $C9 (RET), else 0: memory before the load, so a POKE 32768,201 typed before
; LOAD "" gives the cheat; GameEntry $8F00 then writes OR A ($B7) over the DEC
; (HL) of the lives at $A9FD instead of keeping $35.
;
; LD-BYTES (flag $FF) the loading screen to $4000 ($1B00 bytes, TZX block 3)
; and block 4 to $6000 ($96F8 bytes, TZX block 4); the carry (a load error) is
; not tested. CALL $7200 with BC = $7200: the setup (src/select). On a 128K it
; returns through the paging stub at once; on a 48K after the explorer is
; chosen. Then KeyReleaseWait $5D64, LD-BYTES of block 5 to $7200 ($8E00 bytes)
; and JP $8F00 (GameEntry).
;
; c1: one run from frame 696: the screen loads, block 4, the setup at frame
; 11841, the game block, GameEntry at frame 21597.
;
; Witness: L1 1 (c1).
LoaderEntry:
  DI                      ; interrupts off; LD-BYTES turns them on again at its
                          ; end
  LD HL,BreakMessage-LoaderEntry ; BreakMessage's address ...
  ADD HL,BC
  EX DE,HL
  LD HL,BreakMessagePtr+1-LoaderEntry     ; ... into BreakHandler's LD HL
                                          ; operand
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,BreakHandler-LoaderEntry ; BreakHandler's address ...
  ADD HL,BC
  LD SP,PagingStub             ; ... on a new stack under $5FE6, ERR_SP pointing at
                          ; it
  PUSH HL
  LD (ErrSp),SP
  LD HL,Screen             ; clear the screen and the attributes to 0
  LD DE,Screen+1
  LD BC,$1AFF
  LD (HL),L
  LDIR
  XOR A                   ; border 0
  OUT ($FE),A
  LD HL,$0000             ; Has128K and GameLoaded = 0
  LD (Has128K),HL
  LD A,(CheatByte)            ; $C9 at $8000 before the load: infinite lives
  LD C,$00
  CP $C9
  JR NZ,SetInfiniteLives
  INC C
SetInfiniteLives:
  LD A,C
  LD (InfiniteLives),A
  LD IX,Screen             ; the loading screen, TZX block 3
  LD DE,$1B00
  LD A,$FF
  SCF
  CALL LdBytes
  LD IX,Block4             ; block 4: $6000-$F6F7
  LD DE,$96F8
  LD A,$FF
  SCF
  CALL LdBytes
  LD BC,SelectorSetup     ; the 128K setup; on a 48K the selector too
  CALL SelectorSetup
KeyReleaseWait:
  LD A,C                  ; the border cycles through the colours while any key
                          ; is down
  AND $07
  OUT ($FE),A
  INC C
  XOR A
  IN A,($FE)
  AND $1F
  CP $1F
  JR NZ,KeyReleaseWait
  LD IX,GameImage             ; the game, TZX block 5: $7200-$FFFF
  LD DE,$8E00
  LD A,$FF
  SCF
  CALL LdBytes
  JP GameEntry                ; GameEntry

; BREAK during the load: "User pressed break-reload!" on a blue screen, for
; ever
;
; ERR_SP points at this address (LoaderEntry $5D08), so the ROM's error report
; on BREAK in LD-BYTES comes here. Bitmap cleared, attributes $0F (blue paper,
; white ink), border 1, stream 2 opened, BreakMessage $5DB7 printed by RST $10
; up to its $FF; then back to the start, clearing and printing again with no
; way out but a reset. Not executed in any recording (c1 loads without BREAK);
; known only from the code.
;
; Witness: L1 0 ().
BreakHandler:
  LD HL,Screen
  LD DE,Screen+1
  LD (HL),L
  LD BC,$1800
  LDIR
  LD HL,Attributes             ; attributes $0F, border 1
  LD DE,Attributes+1
  LD (HL),$0F
  LD A,$01
  OUT ($FE),A
  LD BC,$02FF
  LDIR
  LD A,$02                ; stream 2, the upper screen
  CALL ChanOpen
BreakMessagePtr:
  LD HL,BreakMessage-LoaderEntry ; the operand LoaderEntry patches with
                                 ; BreakMessage's address
  LD IY,ErrNr
BreakPrintLoop:
  LD A,(HL)               ; RST $10 up to $FF, then clear and print again
  CP $FF
  JR Z,BreakHandler
  PUSH HL
  RST $10
  POP HL
  INC HL
  JR BreakPrintLoop

; AT 10,4; INK 7; PAPER 1; "User pressed break-reload!", $FF ends
;
; Printed by BreakHandler $5D83 through RST $10: the control codes $16 (AT)
; 10,4, $10 (INK) 7, $11 (PAPER) 1, the text, $FF the end mark. Not read in any
; recording.
BreakMessage:
  INCBIN "res/texts/break-message.bin",$0000,34

; 32 "*": the rest of l$'s 241 bytes, never read
;
; Filler to the end of the block; no code reads it.
StringPad:
  DEFM "********************************"
