; --------------------------------------------------------------------------------------------------------------------
; loader2.asm: The loader's second stage: the hook's work every 8th byte
;
; Loaded by the first stage in three pieces: $B75A-$B868 ($10F bytes, then Loader1Start jumps to LoadRest $B856 in
; it), $B869-$B8DC ($74) and $B8DD-$BBDE ($302), both loaded by LoadRest itself (the CALL that loads $B869 returns to
; the bytes it has just loaded). LoadRest arms the first stage's ByteHook and jumps to LoadFiles $BACC, which makes
; the other five loads.
;
; Every 8th call of ByteHook (7 bytes and the hook itself) runs HookWork $B75A, which does the countdown's tick when
; it is due (CountdownTick), steps the loading screen's script (ScriptStep), and then pads its time on tape to 7 pulse
; pairs (6 long, 1 short): the time of one byte. The tape's encoder (tools/tapesim.py) knows where the hook reads its
; pairs and writes them, so the hook's work costs no gap in the block. In c1 5882 hooks ran: 294 with a countdown
; tick, 1426 with script steps (1336 of them with 6 steps).
;
; The work every hook does is bounded by a marker bit in L (2 at the start): every pair the countdown or the script
; reads moves it one place up, and PadPairs (in the first stage) reads the rest until it leaves bit 7. A hook with a
; tick has room for 2 script steps, one without for 6.
; --------------------------------------------------------------------------------------------------------------------

; ByteHook's work: store the count; every 8th call the countdown tick, the
; script steps, the padding pairs
;
; Entered from ByteHook `$B752` in the first stage, which runs on into these
; bytes with A = HookCount - 1 and the return address in LoadBlock (`$B742`) on
; the stack.
;
; 1. HookCount = A; not 0: return. Else HookCount = 8, B = LoadFlags, L = 2
; (the marker bit).
;
; 2. Bit 0 (the countdown): TickHooks - 1; at 0 CountdownTick, which returns A
; = 20 (`$14`) for TickHooks.
;
; 3. Bit 1 (the script): ScriptWait - 1; at 0 (ScriptWait stays 1, so the next
; hook steps again) ScriptStep, which ends at ByteHook by itself. Else
; ScriptWait is stored and the hook pads.
;
; 4. HookPad `$B784`: PadPairs (the rest of the 7 pairs), B = `$B2`, `JR C` to
; ByteHook with L = `$FF`: the hook XORs `$FF` into the checksum, counts itself
; in HookCount (8 - 1 = 7) and returns to LoadBlock. A timeout: `JP $0000`.
;
; c1 (work/ann/04-loader/hooks.py): the first hook after 8 bytes of the second
; load, then one every 7 bytes and the hook (6 data bytes and the last load's
; checksum byte at the start of the third to eighth loads: LoadBlock runs on
; into ByteHook after the checksum); 5882 in all.
;
; Witness: L1 47063 (c1).
HookWork:
  LD (HookCount),A
  RET NZ
  LD A,$08                ; every 8th: HookCount = 8 again, L = the marker bit
  LD (HookCount),A
  LD A,(LoadFlags)
  LD B,A
  LD L,$02
  BIT 0,B
  JR Z,HookScript
  LD A,(TickHooks)            ; the countdown's tick every 20 hooks (5 for the
                          ; first)
  DEC A
  CALL Z,CountdownTick
  LD (TickHooks),A
HookScript:
  BIT 1,B                 ; the script: wait ScriptWait hooks, then step
  JR Z,HookPad
  LD A,(ScriptWait)
  DEC A
  JR Z,ScriptStep
  LD (ScriptWait),A
; This entry point is used by the routines at ScriptStep and CodePause.
HookPad:
  CALL PadPairs              ; the rest of the hook's 7 pairs, then ByteHook again
                          ; with L = $FF
  LD B,$B2
  JR C,ByteHook
; This entry point is used by the routine at ScriptStep.
HookFail:
  JP $0000                ; a timeout: reset
