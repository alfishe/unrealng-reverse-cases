; --------------------------------------------------------------------------------------------------------------------
; setup.asm: The entry code: the 128K test, the music copy to RAM 1, the IM 2 set-up, the mirror table
;
; The tape loader at $FF00 jumps to Entry ($7B8F) once side A is in. The code runs once: it sets SP to 0, installs the
; IM 2 handler, finds out whether a 128K's RAM 1 is there (a write to $C000 with RAM 1 paged in, read back with RAM
; 0), copies the music $6000-$707F into RAM 1, patches the handler to call the music player, builds the 256-byte bit-
; reverse table at $6500 and goes to the control menu.
;
; Its bytes are then reused: ClearObjectTables ($83B8) zeroes $7B8F-$7C7C at every new game, and the area holds two
; tables of moving objects (six 24-byte records from $7B8F, end mark at $7C1F; four 23-byte records from $7C20, end
; mark at $7C7C) and, in the menus and the endings, the falling letters (8-byte records from $7B8F). The level start
; table LevelStarts at $7C8F is the only data here that stays.
; --------------------------------------------------------------------------------------------------------------------

; The game's entry: SP, the IM 2 handler, the 128K test (later the first object
; table)
;
; Called by the loader ($FF2A, JP) once, with interrupts off: SP = 0 (the stack
; grows down over the loader's tail), SetupIm2 copies the handler and sets IM
; 2. Then the 128K test: E = the byte at $C000 with RAM 0 paged in; RAM 1 is
; paged in (port $7FFD = $11: ROM 1, RAM 1), E + 1 written to $C000, RAM 0
; paged back ($10) and $C000 read again. The same value as before means the
; write went to another bank: a 128K, go to CopyMusic. Otherwise the machine
; has one bank there: Entry48K puts the byte back, sets $7A76 = $FF (no music)
; and skips the copy.
;
; From $83B8 on, the bytes from here are the object table A (six 24-byte
; records, updated by $A2F7 from UpdateObjects, drawn by $7329 from
; DrawSprites, +0 = 0 a free record, $FF at $7C1F the end) and the falling
; letters of DropText (8-byte records, see BuildLetters).
;
; Evidence: c1 runs it once at frame 13 998 (the L1: reads $C000 and
; $6000-$707F, writes $C000-$D07F in RAM 1, $FF14-$FF16, $6500-$65FF, ports
; $7FFD and $FE). The 48K branch Entry48K is not executed in any recording
; (every recording is a 128K).
;
; Witness: L1 2 (c1, c48).
Entry:
  DI
  LD SP,$0000
  CALL SetupIm2
  DI
  LD A,(PageC000)
  LD E,A
  LD BC,$7FFD
  LD A,$11
  OUT (C),A
  LD A,E
  INC A
  LD D,A
  LD (PageC000),A
  LD A,$10
  OUT (C),A
  LD A,(PageC000)
  CP E
  JP Z,CopyMusic

; The 48K branch of the entry
;
; The code bytes of the 48K case: LD A,E / LD ($C000),A puts the test byte back
; (on a 48K the write went to the only bank), LD A,$FF / LD ($7A76),A turns the
; music off (the RAM 1 calls at $7A77 return at once), JP $7BF0 skips the music
; copy and the handler patch (the handler keeps its three NOPs at $FF14) and
; goes on with the bit-reverse table. Kept as bytes: no recording ran it, and
; the object tables write over it, so the walk takes it for data. A 48K run
; would settle it.
;
; Evidence: c48 once, at the entry after side A (the 48K load).
;
; Witness: L1 1 (c48).
Entry48K:
  LD A,E                  ; LD A,E / LD ($C000),A: the test byte put back
  LD ($C000),A
  LD A,$FF                ; LD A,$FF / LD ($7A76),A: 48K, no music
  LD (Machine48K),A
  JP BuildMirrorTable     ; JP $7BF0: past the music copy and the handler patch

; 128K: copy the music to RAM 1, patch the handler to call the player, build
; the mirror table
;
; Copies the 4224 bytes $6000-$707F (the AY music as loaded) to $C000-$D07F in
; RAM 1, one byte at a time: the byte read with RAM 0 in, RAM 1 paged in ($7FFD
; = $11) for the write, RAM 0 back ($10); the source and destination pointers
; and the port are kept in the alternate registers. Then writes CALL $7AB6 over
; the three NOPs at $FF14-$FF16 of the IM 2 handler, so every interrupt runs
; the music player (through $7A77, which pages RAM 1 in). The 48K path joins at
; $7BF0: the 256-byte table at $6500, entry n = n with its bits reversed (the
; sprite blitter $7329 mirrors sprites through it, LD H,$65). Border black, EI,
; then the control menu (NewGame).
;
; Evidence: c1, once (writes $C000-$D07F in page 1, $FF14-$FF16, $6500-$65FF).
;
; Witness: L1 1 (c1).
CopyMusic:
  EXX
  LD BC,$7FFD
  LD HL,MusicImage
  LD DE,PageC000
  EXX
  LD A,$01
  EX AF,AF'
  LD BC,$1080             ; 4224 bytes
CopyMusicLoop:
  EXX                     ; one byte: read in RAM 0, written in RAM 1
  LD A,(HL)
  EX AF,AF'
  LD A,$11
  OUT (C),A
  EX AF,AF'
  LD (DE),A
  LD A,$10
  OUT (C),A
  INC DE
  INC HL
  EXX
  DEC BC
  LD A,B
  OR C
  JR NZ,CopyMusicLoop
  LD A,$CD                ; CALL $7AB6 into the handler's three NOPs
                          ; (Im2Handler+22)
  LD (Im2Handler+22),A
  LD HL,MusicFrameCall
  LD (Im2Handler+23),HL
; This entry point is used by the routine at Entry48K.
BuildMirrorTable:
  LD B,$00                ; the 48K path joins here
  LD H,$65
BitReverseLoop:
  LD L,B                  ; C = B with its 8 bits reversed, stored at $6500 + B
                          ; (B = 0, 255 ... 1)
  LD A,B
  LD C,$00
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  RLA
  RR C
  LD (HL),C
  DJNZ BitReverseLoop
  XOR A                   ; border black
  OUT ($FE),A
  EI
  JP NewGame

; Copy the IM 2 handler to $FEFE, fill the vector table, IM 2
;
; Copies the 35 bytes of Im2HandlerSource ($7C39) to $FEFE-$FF20, fills
; $FD00-$FE00 (257 bytes) with $FE, sets I = $FD and IM 2: whatever byte the
; bus holds, the vector read is $FEFE. Returns with interrupts off (DI); Entry
; enables them at the end of CopyMusic.
;
; Evidence: c1, once, called from $7B93 (reads $7C39-$7C5B, writes $FD00-$FE00
; and $FEFE-$FF20).
;
; Witness: L1 2 (c1, c48).
SetupIm2:
  DI
  LD HL,Im2HandlerSource
  LD DE,Im2Handler
  LD BC,35
  LDIR
  LD HL,Im2Table
  LD B,$00
FillIm2TableLoop:
  LD (HL),$FE             ; 256 bytes $FE, then the 257th
  INC HL
  DJNZ FillIm2TableLoop
  LD (HL),$FE
  LD A,$FD
  LD I,A
  IM 2
  RET
