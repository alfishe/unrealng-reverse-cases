; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The frame counter and wait, the RAM 1 calls (the music and its effects)
;
; The IM 2 handler $FEFE increments FrameCounter $7A60 each interrupt; WaitFrames $7A53 waits until it reaches C and
; clears it, so the main loop (C = 2) runs a pass in two frames or more, and an interrupt lost while SP is borrowed
; slows the count.
;
; On a 128K the music lives in RAM 1 at $C000. CallRam1 $7A77 pages RAM 1 in with interrupts off, calls HL with A, and
; pages RAM 0 back: MusicFrameCall $7AB6 every interrupt, StartTune $7AAD, PlayEffect $7A97. The entry code sets
; Machine48K $7A76 when it finds no RAM 1; then the calls return at once and the effects go to the beeper ($7ADA,
; $7B66).
;
; The handler runs at $FEFE, copied there by SetupIm2 from Im2HandlerSource. Every interrupt it adds 1 to the frame
; counter $7A60 (which the frame wait $7A53 compares and clears), adds 1 to the 32-bit tick count Ticks (CountTicks),
; reads the controls into $7253 ($7254) and, on a 128K, runs the music player through $7AB6 (the CALL CopyMusic writes
; over its NOPs). The tick count feeds the random numbers of Random.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7A53

; Enable interrupts, wait until FrameCounter >= C, clear it
;
; C = the frames: 2 the main loop $7D8B (51 600), 1 the scroll steps, 10, 15,
; 20 the menus and texts ($7E9D, $8150, $82E4, $8743, $8784). 63 583 runs in 68
; builds.
;
; Witness: L1 185643 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
WaitFrames:
  EI

; WaitFramesLoop
;
; Used by the routine at WaitFramesUntil.
WaitFramesLoop:
  LD A,(FrameCounter)

; WaitFramesCompare
WaitFramesCompare:
  CP C

; WaitFramesUntil
WaitFramesUntil:
  JP C,WaitFramesLoop
  XOR A
  LD (FrameCounter),A
  RET

; Interrupts since the last WaitFrames: incremented by the IM 2 handler $FEFE,
; cleared by WaitFrames
FrameCounter:
  DEFB $00

  ORG $7A76

; $FF on a 48K (no RAM 1: no music, beeper effects), 0 on a 128K
;
; Set by the entry code $7B8F; read by CallRam1 $7A77, PlayEffect $7A97, the
; level start ($7CAD, $7CDB, $7CDE) and the main loop $7D80 (CALL NZ the beeper
; step). 0 in every recording (all 128K).
Machine48K:
  DEFB $00

; Call HL in RAM 1 with A, interrupts off; nothing on a 48K
;
; Stores A and HL into its own LD A,n and CALL nn, returns at once when
; Machine48K is set, else DI, port $7FFD = $11 (RAM 1 at $C000, ROM 1), the
; call, $7FFD = $10 (RAM 0). Interrupts stay off: the IM 2 handler's EI or the
; next WaitFrames puts them back. 133 677 runs in 68 builds: MusicFrameCall 127
; 035, PlayEffect 6585, StartTune 57.
;
; Witness: L1 333595 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
CallRam1:
  LD (CallRam1Arg+$0001),A
  LD A,(Machine48K)
  AND A
  RET NZ
  DI
  LD A,$11
  LD BC,$7FFD
  OUT (C),A
  LD (CallRam1Call+$0001),HL
CallRam1Arg:
  LD A,$00                ; LD A,n: n = the caller's A
CallRam1Call:
  CALL $0000              ; CALL nn: nn = the caller's HL
  LD A,$10
  LD BC,$7FFD
  OUT (C),A
  RET

; Start sound effect A: the RAM 1 music's effect, or the beeper's on a 48K
;
; Keeps AF, HL, BC. On a 128K CallRam1 with MusicEffect $CCC8; on a 48K
; SelectBeeperEffect $7ADA (effects 0-10). Callers: $937A, $9386, $93E7, $95A8,
; $9AA5 (4445), $9F67, $A2F2, $A58F, $A5A2, $A5B2, $8C59, the ending's tally
; $873E, and level 5's own code ($F956, $F969, $F96E). 6585 runs in 66 builds.
;
; Witness: L1 13692 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s12,
; sec-l3-s7, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
PlayEffect:
  PUSH AF
  PUSH HL
  PUSH BC
  LD C,A
  LD A,(Machine48K)
  AND A
  LD A,C
  JP NZ,SelectBeeperEffect
  LD HL,MusicEffect
  CALL CallRam1
  POP BC
  POP HL
  POP AF
  RET

; Start tune A in the RAM 1 music
;
; CallRam1 with MusicStartTune $CA27, keeps HL. The tunes: 0 the menu ($80B9)
; and the CONGRATULATIONS end ($875D), 1 a signal (the time bonus $9CC6 /
; $9CDB, both cheats), 2 GAME OVER ($7E20), 4 the tape load ($7CD2), 5-9 levels
; 1-5 (LevelTune $7CE3: Level + 4), 10 the Fat Guy's end ($874B). Callers: the
; level start ($7CD2, $7CE3), the game's end $7E20 (A = 2), the menu $80B9, the
; ending $874B, $9CC6, $9CDB, and the cheat keys ($7D3B, $7D55: A = 1). 57 runs
; in 34 builds.
;
; Witness: L1 259 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, rzx-l1-00000-poke,
; rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke,
; rzx-l2-12000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke,
; rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke,
; rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-14000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-23000, rzx-l5-full, sec-l1-s8,
; c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
StartTune:
  PUSH HL
  LD HL,MusicStartTune
  CALL CallRam1
  POP HL
  RET

; Run the RAM 1 music player for this frame
;
; CallRam1 with MusicFrame $CAAF, keeps HL. Called by the IM 2 handler $FF14
; every interrupt: 127 035 runs in 68 builds (c1 4706).
;
; Witness: L1 319801 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, sec-l1-s8, c1,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
MusicFrameCall:
  PUSH HL
  LD HL,MusicFrame
  CALL CallRam1
  POP HL
  RET

  ORG $7C39

; The IM 2 handler as stored here; it runs at $FEFE (35 bytes)
;
; SetupIm2 copies these 35 bytes to $FEFE-$FF20 (LD HL,$7C39 / LD DE,$FEFE / LD
; BC,35 / LDIR); the code runs only there (in c1 4706 times, the IM 2 vector of
; every interrupt). DI; AF, BC, DE, HL, IX, IY pushed; the frame counter $7A60
; + 1; CALL $81D4 (CountTicks); CALL $7254 (the controls into $7253, the method
; in $7252); three NOPs, which CopyMusic turns into CALL $7AB6 on a 128K (the
; music player, through the RAM 1 call $7A77); the registers popped; EI; RET.
; The handler lasts until its EI, so an interrupt that comes while code runs
; with interrupts off (the blitters, the map builder, the RAM 1 calls, the
; tape) is lost (WALKTHROUGH 1).
;
; After the copy the bytes here are part of the object table A (from $7B8F) and
; of the falling letters' records.
Im2HandlerSource:
  DEFB $F3,$F5,$C5,$D5,$E5,$DD,$E5,$FD ; DI, then PUSH AF, BC, DE, HL, IX, IY
  DEFB $E5
  DEFB $3A,$60,$7A,$3C,$32,$60,$7A ; LD A,($7A60) / INC A / LD ($7A60),A: the
                                   ; frame counter
  DEFB $CD,$D4,$81        ; CALL $81D4: CountTicks
  DEFB $CD,$54,$72        ; CALL $7254: read the controls
  DEFB $00,$00,$00        ; NOP NOP NOP, at $FF14 in the copy: CALL $7AB6 (the
                          ; music) on a 128K
  DEFB $FD,$E1,$DD,$E1,$E1,$D1,$C1,$F1 ; POP IY, IX, HL, DE, BC, AF
  DEFB $FB,$C9            ; EI / RET

; Bytes of an earlier build after the handler (not executed in any recording)
;
; Not read as code by anything: they look like the tail of the handler of an
; earlier build, eight bytes higher (CALL $81DC, CALL $725C, the NOPs, the
; pops, EI, RET) and the start of an earlier NewGame (CALL $80B1 where this
; build has CALL $80B5 at $7C7D). The space belongs to the object table B
; ($7C20, four 23-byte records); ClearObjectTables writes its end mark $FF at
; $7C7C.
EntryDebris:
  DEFB $7A,$CD,$DC,$81,$CD,$5C,$72,$00
  DEFB $00,$00,$FD,$E1,$DD,$E1,$E1,$D1
  DEFB $C1,$F1,$FB,$C9,$00,$00,$00,$00
  DEFB $00,$CD,$AD,$CD,$AF,$CD,$B1,$80
ObjectTableBEnd:
  DEFB $CD                ; the end mark of the object table B ($FF after
                          ; ClearObjectTables)

  ORG $81AF

; A pseudo-random byte from the tick count: A and RandomValue
;
; HL = RandomValue + Ticks (low word) + 13 + Ticks (high word) with the carry;
; A (as given) XOR L XOR D XOR E XOR H becomes L; HL stored in RandomValue; A
; is the result. HL and DE kept.
;
; Evidence: 1018 runs in 21 builds (callers $A010 x999, $A016 x995, $A048 x19,
; $A05F x18).
;
; Witness: L1 3010 (rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke,
; rzx-l1-08000-poke, rzx-l1-16000-poke, rzx-l1-20000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l2-20000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-06000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-16000-poke,
; rzx-l4-18000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-12000-poke,
; c48, load-l2, load-l3, sec-l2-s7, sec-l2-s12, sec-l3-s5, sec-l4-s12,
; sec-l5-s5).
Random:
  PUSH HL
  PUSH DE
  LD HL,(RandomValue)
  LD DE,(Ticks)
  ADD HL,DE
  LD DE,$000D
  ADD HL,DE
  LD DE,(Ticks+$0002)
  ADC HL,DE
  XOR L
  XOR D
  XOR E
  XOR H
  LD L,A
  LD (RandomValue),HL
  POP DE
  POP HL
  RET

; The last random word (Random)
RandomValue:
  DEFW $0000

; The interrupts counted, 32 bits: the low word, then the high word
;
; Counted by CountTicks every interrupt, read by Random.
Ticks:
  DEFW $0000,$0000

; Ticks + 1 (32 bits); called by the IM 2 handler
;
; The low word + 1; when it wraps to 0 the high word + 1.
;
; Evidence: 127 035 runs in 68 builds, every call from $FF0E (the handler at
; $FEFE: the copy of $7C49); c1 4706.
;
; Witness: L1 324903 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
CountTicks:
  LD HL,(Ticks)
  INC HL
  LD (Ticks),HL
  LD A,L
  OR H
  RET NZ
  LD HL,(Ticks+$0002)
  INC HL
  LD (Ticks+$0002),HL
  RET
