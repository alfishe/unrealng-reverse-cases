; --------------------------------------------------------------------------------------------------------------------
; countdown.asm: The stage's own last pieces and the countdown in seconds
;
; LoadRest loads the rest of this stage, turning the script (SerialText) and then the countdown on. CountdownTick
; counts the three ASCII digits at Countdown down by one every 20 hooks: 160 byte times of 13 short pairs, 3475776 T,
; 0.993 s at 3.5 MHz. The 294 at the start is the load's length in those seconds: in c1 the 294th tick shows 000 at
; 293.7 s, a tenth of a second before the last byte (work/ann/04-loader/hooks.py).
; --------------------------------------------------------------------------------------------------------------------

; Stage 2's entry: arm the hook, start the serial text, load the stage's last
; two pieces, then LoadFiles
;
; From Loader1Start's `JP $B856`, IX = `$B869` (just past the first piece) and
; H = the checksum.
;
; 1. HookCount = 8 (ByteHook works from now on); LoadFlags bit 1, the script
; (SerialText); LoadBlock `$74` bytes: `$B869-$B8DC`, the bytes this routine
; goes on with after the CALL.
;
; 2. LoadFlags bit 0, the countdown; LoadBlock `$302` bytes: `$B8DD-$BBDE`. `JP
; $BACC` (LoadFiles).
;
; Witness: L1 1 (c1).
LoadRest:
  LD A,$08
  LD (HookCount),A
  LD A,(LoadFlags)
  SET 1,A
  LD (LoadFlags),A
  LD DE,$0074
  CALL LoadBlock              ; the next piece: $B869-$B8DC, where this routine
                          ; goes on
  LD A,(LoadFlags)            ; the countdown on; the last piece, $B8DD-$BBDE
  SET 0,A
  LD (LoadFlags),A
  LD DE,$0302
  CALL LoadBlock
  JP LoadFiles

; One second less: Countdown - 1 in ASCII digits, shown at CountdownAt; past
; 000 the countdown stops
;
; Called by HookWork when TickHooks reaches 0 (EXX: the loader's HL, DE and B
; kept in the other set).
;
; The three digits from the last: `SBC A,0` with the borrow, `DAA`, below `$30`
; a borrow on and `SET 4,A` ('0' - 1 gives '9'). A borrow out of the first
; digit (past 000): LoadFlags bit 0 off, the marker bit set at bit 7, one pair
; (CountdownWait). Else the digits are printed at CountdownAt (`$5AC1`) with
; CountdownPair's B (CountdownAttr `$57`), each after one long pair
; (EdgeNoDelay, EdgeWait; `RL L` with bit 0 of C, the level byte, as the carry:
; its value does not matter, the marker set at bit 4 leaves after 4 pairs
; whatever comes in): 4 pairs.
;
; Out: A = 20 (TickHooks), B = LoadFlags. IgnoreCode `$B8DC` (the final `RET`)
; is also the control-code table's handler for the codes that do nothing.
;
; c1: 294 ticks, 3475776 T apart (0.993 s), from 293 at about 2.74 s to 000 at
; 293.70 s; the count never passed 000.
;
; Witness: L1 294 (c1).
CountdownTick:
  EXX
  LD HL,Countdown+2             ; the last digit first, with the borrow in
  LD B,$03
  SCF
CountdownDigit:
  LD A,(HL)
  SBC A,$00
  DAA
  CP $30
  SET 4,A
  LD (HL),A
  DEC HL
  DJNZ CountdownDigit
  JR NC,CountdownShow
  LD HL,LoadFlags             ; past 000: the countdown off, the marker for one
                          ; pair
  RES 0,(HL)
  EXX
  SET 7,L
  JR CountdownWait
CountdownShow:
  LD DE,(CountdownAt)           ; the three digits at CountdownAt, a pair before each
  EXX
  SET 4,L
  LD B,$B0
  CALL EdgeNoDelay
  JP NC,$0000
  CALL EdgeWait
  JP NC,$0000
  LD A,C
  RRA
  RL L
CountdownPrint:
  EXX
  INC HL
  LD A,(HL)
  PUSH DE
  PUSH HL
  LD BC,(CountdownPair)
  CALL PrintGlyph
  POP HL
  POP DE
  INC DE
  EXX
CountdownWait:
  LD B,$B0
  CALL EdgeNoDelay
  JP NC,$0000
  CALL EdgeWait
  JP NC,$0000
  LD A,C
  RRA
  RL L
  JR NC,CountdownPrint
  LD A,(LoadFlags)            ; A = 20 hooks to the next tick, B = the flags for
                          ; HookWork
  LD B,A
  LD A,$14
IgnoreCode:
  RET                     ; RET: the table's handler of the codes that do
                          ; nothing
