; --------------------------------------------------------------------------------------------------------------------
; loads.asm: The rest of the turbo block: the glyphs, the script and the game, and the move at the end
;
; LoadFiles reads its loads from LoadParams $BBD2 (the same code would load another game with other parameters): the
; loading screen's glyphs ($B326, $1D8 bytes: characters 32-90 over the ROM font's copy), the script ($998E, $1998
; bytes) and the main block ($81F0 bytes for $5C00-$DDEF). The main block covers this stage ($B326-$BBDE), so its last
; $4000 bytes ($9DF0-$DDEF) come first, to HighBuffer $C000; then $5C00-$9BFF and $9C00-$9DEF; then a 3-byte stub at
; $5B00 (LDIR; RET) copies $C000-$FFFF to $9DF0 over the loader and returns to $5C00, the main block's head
; (src/head).
;
; In c1 (work/ann/04-loader/hooks.py, the times from the pilot's end): glyphs at 7.98 s, script 11.34 s, $C000 57.83
; s, $5C00 174.05 s, $9C00 290.27 s; the block ends at 293.80 s.
; --------------------------------------------------------------------------------------------------------------------

; Load the glyphs and the script, start the script, load the main block in
; three loads, move its tail, run it
;
; From LoadRest's `JP $BACC`.
;
; 1. LoadBlock GlyphsAddr, GlyphsLen (when not 0).
;
; 2. LoadFlags bit 1 (the script on again), ScriptWait = ScriptDelay (230
; hooks), the print position to the window's top left, ScriptPtr = ScriptAddr;
; LoadBlock ScriptAddr, ScriptLen: the script runs while it loads.
;
; 3. MainLen of `$4000` or more: LoadBlock HighBuffer `$C000`, `$4000` (the
; block's last `$4000` bytes); MainLen - `$4000`.
;
; 4. IX = MainAddr (pushed: the return address at the end); LoadBlock `$4000`
; bytes while `$4000` or more are left; then the rest (when not 0). IX is now
; MainAddr + MainLen - `$4000`.
;
; 5. MainLen's high byte below 4: `RET` to MainAddr. Else `LDIR` (`$ED $B0`)
; and `RET` at MoveStub `$5B00`, HL = `$C000`, DE = IX (`$9DF0`), BC = `$4000`,
; `JP $5B00`: the copy runs from the printer buffer, outside the bytes it
; overwrites (this stage among them), and its `RET` goes to MainAddr `$5C00`.
;
; The test in step 5 reads MainLen's high byte against 4, not `$40`: a main
; block of `$0400-$3FFF` bytes would still be "moved". Deflektor's `$81F0`
; takes the move.
;
; Witness: L1 1 (c1).
LoadFiles:
  LD IX,(GlyphsAddr)
  LD DE,(GlyphsLen)
  LD A,D
  OR E
  CALL NZ,LoadBlock
  LD A,(LoadFlags)            ; the script on, after ScriptDelay hooks, from the
                          ; window's top left
  SET 1,A
  LD (LoadFlags),A
  LD A,(ScriptDelay)
  LD (ScriptWait),A
  LD DE,(WindowTop)
  LD (PrintRow),DE
  LD A,(WindowLeft)
  LD (PrintColumn),A
  LD IX,(ScriptAddr)
  LD (ScriptPtr),IX
  LD DE,(ScriptLen)
  CALL LoadBlock
  LD DE,(MainLen)         ; the main block: its last $4000 bytes to $C000 first
  LD A,D
  SUB $40
  JR C,LoadMainLow
  LD D,A
  PUSH DE
  LD IX,HighBuffer
  LD DE,$4000
  CALL LoadBlock
  POP DE
LoadMainLow:
  LD IX,(MainAddr)        ; from MainAddr up, $4000 bytes at a time
  PUSH IX
  LD A,D
  SUB $40
  JR C,LoadMainRest
  LD D,A
  PUSH DE
  LD DE,$4000
  CALL LoadBlock
  POP DE
LoadMainRest:
  LD A,D
  OR E
  CALL NZ,LoadBlock
  LD A,(MainLen+$0001)    ; MoveStub: LDIR; RET at $5B00, then $C000 to its
                          ; place, RET to MainAddr
  CP $04
  RET C
  LD HL,$B0ED
  LD (MoveStub),HL
  LD A,$C9
  LD (MoveStub+2),A
  LD HL,HighBuffer
  PUSH IX
  POP DE
  LD BC,$4000
  JP MoveStub
