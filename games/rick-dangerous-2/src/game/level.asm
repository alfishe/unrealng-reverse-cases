; --------------------------------------------------------------------------------------------------------------------
; level.asm: The sections' objects reset at a new game
;
; A section's record in the section table ($C202, 8 bytes) holds at +6/+7 the offset of its objects list: 4-byte
; records, +0 the kind (bit 7 set once the object is used), +3 bits 0-1 the number of 4-byte extensions.
; ResetSectionObjects clears bit 7 in every record of the level's sections at a new game.
;
; A level is a set of sections, each a shaft one screen wide whose map is a column of rows of 8 block numbers (a block
; is 4 x 4 cells). LevelHeader+2 points to the section table, 8 bytes a section: +0/+1 the map's offset from the maps'
; base (LevelHeader+4), big-endian; +2 not read by any code (0 in every level); +3 the last view top row the scroll
; may reach (cells); +4/+5 the offset of the section's exit list from the table's start, big-endian; +6/+7 the offset
; of its map entry list (enemies, traps, pickups: the objects module), big-endian. SetupSection reads it.
;
; An exit list holds 4-byte records ended by a record whose bits 0, 1 and 3 are 0 (a 0 byte): +0 the flags (bits 0-1
; the side: 1 left, 2 right; bit 4 keeps a bit-7 exit a level end under the long-levels switch $8067; bit 5 sets $945D
; to $FF on the way in; bit 6 sets LevelHookOn; bit 7 the level ends here), +1 the section row of Rick's feet at which
; the exit is taken, +2 the section entered, +3 the row of that section Rick's feet arrive at. CheckSectionExit takes
; an exit when Rick leaves the view at a side (the exit request $88D3 = 1 or 2). The view: ViewTop $88CF is the
; section row at the top of ViewCells; the scroll ($78A5, $7905) moves it by 8 rows and BuildView builds the 44 rows
; again.
; --------------------------------------------------------------------------------------------------------------------

  ORG $8374

; The number of sections of each level: 9, 13, 10, 13, 8
;
; Read by ResetSectionObjects at SectionCounts - 1 + Level.
SectionCounts:
  INCBIN "res/tables/section-counts.bin",$0000,5

; Clear bit 7 (used) in every object record of every section of the level
;
; B = SectionCounts[Level]; for each section's 8-byte record from ($C202) + 6:
; the list at ($C202) + the big-endian word at +6; each 4-byte record until a
; kind 0: its byte +0 AND $7F, then skip as many more 4-byte records as +3 AND
; 3 says.
;
; Evidence: 12 runs in 11 builds (level 1: reads $ECF3-$ED2C and the lists
; $ED32-$F1FE, writes $ED32-$F1EC).
;
; Witness: L1 56 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ResetSectionObjects:
  LD A,(Level)
  LD C,A
  LD B,$00
  LD HL,SectionCounts-1
  ADD HL,BC
  LD B,(HL)
  LD HL,(LevelHeader+2)
  LD DE,$0006
  ADD HL,DE
ResetSectionLoop:
  PUSH BC                 ; a section
  PUSH HL
  LD D,(HL)
  INC HL
  LD E,(HL)
  LD HL,(LevelHeader+2)
  ADD HL,DE
  LD DE,$0004
ResetRecordLoop:
  LD A,(HL)               ; an object record
  AND $7F
  JP Z,ResetSectionNext
  LD (HL),A
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  AND $03
  JP Z,ResetRecordLoop
  LD B,A
SkipExtraLoop:
  ADD HL,DE               ; its extensions
  DJNZ SkipExtraLoop
  JP ResetRecordLoop
ResetSectionNext:
  POP HL                  ; the next section's record
  LD BC,$0008
  ADD HL,BC
  POP BC
  DJNZ ResetSectionLoop
  RET

  ORG $88CF

; The view's top row in the section (cells)
;
; Set by the section setup $8A6D (from LevelStarts +1 or the section entered)
; and by $8A26; moved by the scrolls $7905 (up) and $78A5 (down); read by the
; map builder $88D4, MainLoopPause's scroll tests, $8993 and others.
ViewTopRow:
  DEFB $00

; The section's map: the maps' base + the section's offset
;
; Set by $8A6D and $8A26, read by the map builder $88D4.
ViewMap:
  DEFW $0000

; The last top row the view may scroll down to in the section
;
; The section record's +3, set by $8A6D and $8A26; MainLoopPause scrolls down
; only while ViewTopRow is below it.
ViewLastRow:
  DEFB $00

; The exit Rick asks for in this pass: 0 none
;
; Cleared at each pass (MainLoopPause), set by Rick's movement ($945E, $95ED,
; $96B4, $988F, $9941) and by $8A26; when set, MainLoopPause runs the exit test
; $8993, which compares it with the exits' kinds (AND $0B).
ExitDirection:
  DEFB $00

; Build ViewCells: 11 rows of 8 blocks from the section's map, from the view's
; top row
;
; The map row is ViewTop $88CF / 4, rounded down to an even row ((ViewTop x 2)
; AND $FFF0, ViewTop being a multiple of 8): the bytes from the section's map
; $88D0 plus that offset. Each map byte is a block number; the block's 16 cell
; numbers (Blocks + 16 x n, four rows of four) go to ViewCells as a 4 x 4
; square, 8 blocks a row, 11 rows: 32 x 44 cells, $6B00-$707F.
;
; Runs with the interrupts off and SP borrowed: SP points at the block and POP
; DE takes two cell numbers at a time; the caller's SP is stored into the LD
; SP,n at $8946 and put back there (an interrupt in between is lost, NOTES).
; Then FindFirstMapEntry sets the map entry scan's start for the new view.
;
; Callers: the scroll down $78F2 (83 runs), the scroll up $7952 (89),
; SetupSection $8AE6 (97). Witness: 269 runs in 62 builds; reads the maps only
; ($E1ED-$E9D4 over all recordings), writes $6B00-$707F.
;
; Witness: L1 643 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-10000-poke,
; rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke, rzx-l1-18000-poke,
; rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke, rzx-l2-00000-poke,
; rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke, rzx-l2-08000-poke,
; rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke, rzx-l2-16000-poke,
; rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke, rzx-l3-00000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
BuildView:
  LD C,$0B
  LD A,(ViewTopRow)
  LD L,A
  LD H,$00
  ADD HL,HL
  LD A,L
  AND $F0
  LD L,A
  LD DE,(ViewMap)
  ADD HL,DE
  EX DE,HL
  LD HL,ViewCells
  LD (BuildViewDest+$0001),HL
  EX DE,HL
  EXX
BuildViewDest:
  LD HL,$0000             ; HL' = the destination: the operand is set to
                          ; ViewCells by $88EA
  EXX
  DI
  LD (BuildViewSP+$0001),SP ; the caller's SP into the LD SP,n at $8946
BuildViewRow:
  LD B,$08                ; a row of 8 blocks
BuildViewBlock:
  LD A,(HL)               ; HL: the map byte; HL': the block's top left cell in
                          ; ViewCells
  INC HL
  EXX
  EX DE,HL
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,Blocks
  ADD HL,BC
  LD SP,HL                ; SP = the block's 16 cell numbers
  EX DE,HL
  POP DE
  LD (HL),E
  INC L
  LD (HL),D
  INC L
  POP DE
  LD (HL),E
  INC L
  LD (HL),D
  LD BC,32-3              ; on to the next cell row, 3 columns back
  ADD HL,BC
  POP DE
  LD (HL),E
  INC L
  LD (HL),D
  INC L
  POP DE
  LD (HL),E
  INC L
  LD (HL),D
  ADD HL,BC
  POP DE
  LD (HL),E
  INC L
  LD (HL),D
  INC L
  POP DE
  LD (HL),E
  INC L
  LD (HL),D
  ADD HL,BC
  POP DE
  LD (HL),E
  INC L
  LD (HL),D
  INC L
  POP DE
  LD (HL),E
  INC L
  LD (HL),D
  LD BC,-3*32+1            ; back up 3 rows, on to the next block's column
  ADD HL,BC
  EXX
  DJNZ BuildViewBlock
  EXX
  LD BC,3*32              ; the next block row: 3 more cell rows down (the last
                          ; block's row ended one row down)
  ADD HL,BC
  EXX
  DEC C
  JP NZ,BuildViewRow
BuildViewSP:
  LD SP,$0000             ; the operand is the caller's SP, stored at $88F4
  EI
  CALL FindFirstMapEntry  ; the first map entry at or below the new top row
  RET

  ORG $8969

; Fill DirtyMap with 1: every screen cell is drawn on the next redraw
;
; 1280 bytes $6600-$6AFF set to 1, the mark $77B1 reads as "draw this cell
; whatever it held". Called by $7965 (the full redraw after a section setup and
; at the level start).
;
; Evidence: 97 runs in 43 builds, all from $7965.
;
; Witness: L1 271 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
RedrawAll:
  LD HL,DirtyMap
  LD DE,DirtyMap+1
  LD BC,$04FF
  LD (HL),$01
  LDIR
  RET

; Fill the first 1280 bytes of ViewCells with cell $27
;
; $6B00-$6FFF set to cell 39 (the last 128 bytes of the 1408 stay). Called by
; the level menu $7F4D and $88B1 (the text screens: the menus, the endings),
; which draw on a blank view.
;
; Evidence: 27 runs in 11 builds (callers $7F4D 11, $88CA 16).
;
; Witness: L1 154 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l5-23000, rzx-l5-full, sec-l1-s8, c1,
; c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
BlankView:
  LD HL,ViewCells
  LD DE,ViewCells+1
  LD BC,$04FF
  LD (HL),$27
  LDIR
  RET

; Fill DirtyMap with 0: the next redraw draws only the cells that changed
;
; 1280 bytes $6600-$6AFF set to 0. Called around every scroll step ($78A5,
; $78FB, $7905, $795B), by the game over $7E2C, the level menu $7F4A, $88C7 and
; SetupSection ($8B0B).
;
; Evidence: 469 runs in 63 builds.
;
; Witness: L1 1205 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke,
; rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke, rzx-l1-16000-poke,
; rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke, rzx-l1-24000-poke,
; rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke, rzx-l2-06000-poke,
; rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke, rzx-l2-14000-poke,
; rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke, rzx-l2-22000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-04000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke,
; rzx-l4-12000-poke, rzx-l4-14000-poke, rzx-l4-16000-poke, rzx-l4-18000-poke,
; rzx-l5-00000-poke, rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke,
; rzx-l5-08000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke,
; rzx-l5-16000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-23000,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
ClearRedraw:
  LD HL,DirtyMap
  LD DE,DirtyMap+1
  LD BC,$04FF
  LD (HL),$00
  LDIR
  RET

; Rick left the view at a side: find the exit and set up the next section, or
; end the level
;
; Called by the main loop ($7D98) when the exit request $88D3 is set (1: Rick
; left at the left edge, 2: at the right; set by $9531, $9545, $9955, $9966).
; Rick's feet row in the section is L = ViewTop + (y $9BAD + 20) / 8. The exit
; list (its address stored into the LD IX,n here by SetupSection $8ACB) is
; scanned for the first record whose bits 0, 1, 3 equal the request and whose
; +1 equals L. None: return Z, A = 0 (positive), and nothing happens.
;
; Found: $945D = 0, then the flags (bits 4-7). Bit 7 set: return with A
; negative, the level is done (the main loop goes to $7D9E). Bit 5: $945D =
; $FF. Bit 6: LevelHookOn = 20. Then TakeExit: the new view top = +3 - (L -
; ViewTop), so Rick keeps his place on the screen; x = $E8 when he went out at
; the left (bits 0-1 = 1), else 0; y stays; SetupSection for section +2; return
; A = 0 (positive).
;
; The long-levels switch: when $8067 has bit 7 set, the bytes at $89E0 (BIT 4,C
; / JP Z,$89E8) skip the level-end test for an exit whose bit 4 is clear, so
; the exits $82 (level 2 section 7, level 3 section 6, level 4 section 7) lead
; on into the sections no recording shows (level 2 10-12, level 3 7-9, level 4
; 10-12) instead of ending the level; the exits $91 / $92 (bit 4 set) still end
; it. $8067 is set only by $7D4C (a key combination tested at $71DC, while
; level 5 is open $8065); no recording ran it. Known only from the code.
;
; Evidence: 1225 runs in 34 builds (all from $7D98); a matching exit 51 times
; (TakeExit), the flag test 12 times ($89E5), a level end 2 times
; (rzx-l3-10000-poke: level 3 section 6's exit $82; rzx-l4-20000-poke: level 4
; section 7's $82, the $7D9E runs).
;
; Witness: L1 2431 (end-congrats, long-l4, rzx-l1-00000-poke,
; rzx-l1-02000-poke, rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke,
; rzx-l1-14000-poke, rzx-l1-20000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke,
; rzx-l3-10000-poke, rzx-l4-02000-poke, rzx-l4-06000-poke, rzx-l4-08000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-16000-poke, rzx-l4-20000-poke,
; rzx-l5-06000-poke, rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-18000-poke,
; rzx-l5-20000-poke, rzx-l5-full, c1, c48, load-l2, load-l4, sec-l2-s11,
; sec-l2-s12, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
CheckSectionExit:
  LD IX,$0000
  LD HL,(RickY)           ; Rick's y in the view
  LD BC,$0014
  ADD HL,BC               ; + 20: his feet
  SRL H
  RR L
  SRL H
  RR L
  SRL H
  RR L
  LD A,(ViewTopRow)
  ADD A,L                 ; L = Rick's feet row in the section
  LD L,A
  LD DE,$0004
  LD A,(ExitDirection)    ; C = the exit request: 1 left, 2 right
  LD C,A
ExitScanLoop:
  LD A,(IX+$00)           ; bits 0, 1, 3 of +0: 0 ends the list
  AND $0B
  RET Z
  CP C
  JP Z,ExitRowTest
ExitScanNext:
  ADD IX,DE               ; 4 bytes a record
  JP ExitScanLoop
ExitRowTest:
  LD A,(IX+$01)           ; +1: the row the exit is taken at
  CP L
  JP NZ,ExitScanNext
  XOR A
  LD (RideMode),A
  LD A,(IX+$00)
  AND $F0                 ; the flag bits 4-7
  JP Z,TakeExit
  LD C,A
  LD A,(CheatExits)       ; $8067 bit 7: the long-levels switch
  AND A
  JP P,CheckExitFlags

; BIT 4,C / JP Z,$89E8: with the switch on, an exit without bit 4 never ends
; the level
;
; Reached from $89DD only when $8067 is negative. A bit-4 exit goes on to the
; level-end test at $89E5; any other skips it ($89E8).
;
; Evidence: long-l4 (stage 2, POKE CheatExits = $FF) once: the exit $82 at the
; end of level 4 section 7 took the JP Z and the level went on into section 10.
;
; Witness: L1 2 (long-l4).
LongLevelsTest:
  BIT 4,C
  JP Z,CheckExitRide

; CheckSectionExit, continued: the exit's flags
;
; C: the exit's flags (bits 4-7). Bit 7: return with A = C (negative): the
; level is done. Else $945D = 0, or $FF with bit 5 (a state of Rick's, read by
; $95ED; restored after a death through $9B91); bit 6: LevelHookOn = 20 (only
; level 5 section 6's exit $42 into section 7, the Fat Guy: rzx-l5-20000-poke,
; once).
;
; Evidence: 12 runs in 7 builds; bit 5 9 times (level 2 section 5 and 7, level
; 4 sections 3-5, level 5 section 1), bit 6 once.
;
; Witness: L1 26 (end-congrats, rzx-l2-20000-poke, rzx-l3-10000-poke,
; rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-20000-poke, rzx-l5-06000-poke,
; rzx-l5-20000-poke).
CheckExitFlags:
  LD A,C
  AND A
  RET M
; This entry point is used by the routine at LongLevelsTest.
CheckExitRide:
  XOR A                   ; the long-levels test lands here
  LD (RideMode),A
  BIT 5,C
  JP Z,CheckExitBit6
  DEC A
  LD (RideMode),A
CheckExitBit6:
  BIT 6,C
  JP Z,TakeExit
  LD A,$14
  LD (LevelHookOn),A
; This entry point is used by the routine at CheckSectionExit.
TakeExit:
  LD A,(ViewTopRow)       ; C = the new top row: +3 - Rick's feet row in the
                          ; view
  LD H,A
  LD A,L
  SUB H
  LD C,A
  LD A,(IX+$03)
  SUB C
  LD C,A
  LD E,$E8                ; x = $E8: he went out at the left, he comes in at
                          ; the right
  LD A,(IX+$00)
  AND $03
  CP $01
  JP Z,TakeExitSetup
  LD E,$00                ; x = 0: he comes in at the left
TakeExitSetup:
  LD A,(IX+$02)           ; A = the section, HL = Rick's y (kept)
  LD HL,(RickY)
  CALL SetupSection
  XOR A                   ; A = 0: positive, play goes on
  RET

; Nonzero: the level's own code (LevelHookA, LevelHookB) runs in place of the
; map entries
;
; Set to 20 by an exit with bit 6 ($89FC; level 5 into the Fat Guy's section)
; and by a death while it is set ($93E2); cleared at a new game ($7CBD). While
; it is nonzero, SetupSection calls LevelHookA ($C206) in place of
; ScanMapObjects, ScanMapObjects returns at once, and $865D calls LevelHookB
; ($C209) in place of the object updates; $91EB and level 5's own code ($F954)
; read it too. The second byte $8A25 is read by no code.
LevelHookOn:
  DEFB $00
  DEFB $00                ; read by no code

; Rick died: a life off, the bullets and detonators back to 6, restart where he
; entered the section
;
; Called by the main loop ($7E18) when Rick's death is over ($9B9B set) and
; more than one life is left. Lives $8B3B - 1 unless the cheat flag $8066 is
; set (toggled by $7D39, a key combination at $71C0; no recording ran it), the
; lives redrawn ($79C3); the word $9B95 = $0100 (the death sets $FB00 there,
; $93EA); Ammunition and Detonators = 6.
;
; Then the restart point $9B8C-$9B94 that SetupSection saved when Rick came
; into the section is put back: the facing $9BB1, $9B99, the crawl flag $9B98,
; $945D, then x, y, the view top and the section for SetupSection, into which
; it falls.
;
; Evidence: 29 runs in 13 builds (all from $7E18), from c1 (5) on; the life
; taken 33 times over the builds (the POKE $8A30 of the RZX pieces makes the
; lives infinite).
;
; Witness: L1 54 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full, c1, c48, load-l2,
; load-l4).
LoseLife:
  LD A,(CheatInfinite)
  AND A
  JP NZ,LoseLifeRestart
  LD A,(Lives)
  DEC A
  LD (Lives),A
LoseLifeRestart:
  CALL DrawLives          ; the lives redrawn
  XOR A
  LD (RickDy),A
  INC A
  LD (RickDy+$0001),A
  LD A,$06                ; ammunition and detonators back to 6
  LD (Ammunition),A
  LD (Detonators),A
  LD A,(RestartFacing)    ; the restart point back
  LD (RickFacing),A
  LD A,(RestartClimb)
  LD (RickClimbing),A
  LD A,(RestartCrawl)
  LD (RickCrawling),A
  LD A,(RestartRide)
  LD (RideMode),A
  LD A,(RestartTopRow)
  LD C,A
  LD HL,(RestartY)
  LD A,(RestartX)
  LD E,A
  LD A,(RickSection)      ; A = the section: on into SetupSection

; Set up section A: Rick at (E, HL), the view top C; the map, the exits and the
; entries from the table
;
; Inputs: A the section, E Rick's x, HL Rick's y (pixels from the view's top),
; C the view's top row. The section into $9B93, Rick's x and y into $9BAC /
; $9BAD, the dying flags $9B9B / $9B9C cleared, the view top into $88CF; a
; restart point is saved in $9B8C-$9B94 (x, y, the crawl flag $9B98, $9B99,
; $945D, the view top, the section, the facing $9BB1), which LoseLife puts
; back.
;
; The section table entry LevelHeader+2 + 8 x A: +0/+1 (big-endian) + the maps'
; base into $88D0, the section's map ($8AB8); +3 into $88D2 ($8ABE), the last
; top row the main loop scrolls down to ($7DFB); +4/+5 + the table's address
; into the LD IX,n of CheckSectionExit ($8ACB); +6/+7 + the table's address
; into SectionEntries ($8AD5). +2 is not read.
;
; Then Rick's record off ($9BAB = 0), $85FA, $76D4, the objects freed ($9BEB),
; BuildView, and the entries in the view spawned (ScanMapObjects with
; SpawnWholeView = $FF and $86DF = $FF), or LevelHookA when LevelHookOn is set;
; then $865D, ClearRedraw, Rick's record on ($9BAB = 1), $85FA, $796F, the
; bonus countdown stopped ($9BA9 = $9BAA = 0), the exit request $88D3 cleared,
; the full redraw ($7965, $76D4). The test of $88D3 = 1 at $8B23 leads to two
; identical tails.
;
; Callers: the level start $7D2A (17), TakeExit $8A1F (51), LoseLife (falls in,
; 27). Witness: 97 runs in 43 builds; LevelHookA called twice
; (rzx-l5-20000-poke).
;
; Witness: L1 271 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, long-l4, rzx-l1-00000-poke, rzx-l1-02000-poke,
; rzx-l1-06000-poke, rzx-l1-08000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-20000-poke, rzx-l2-00000-poke, rzx-l2-04000-poke, rzx-l2-08000-poke,
; rzx-l2-12000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l3-00000-poke, rzx-l3-02000-poke, rzx-l3-04000-poke, rzx-l3-06000-poke,
; rzx-l3-08000-poke, rzx-l3-10000-poke, rzx-l4-00000-poke, rzx-l4-02000-poke,
; rzx-l4-06000-poke, rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke,
; rzx-l4-16000-poke, rzx-l5-00000-poke, rzx-l5-06000-poke, rzx-l5-10000-poke,
; rzx-l5-12000-poke, rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
SetupSection:
  LD (RickSection),A
  LD (RestartY),HL
  LD (RickY),HL
  LD L,A
  LD H,$00
  XOR A                   ; Rick is not dying
  LD (RickDying),A
  LD (DeathFallOver),A
  LD A,E
  LD (RickX),A
  LD (RestartX),A
  LD A,(RickFacing)       ; the restart point: facing, $9B99, crawl flag, $945D
  LD (RestartFacing),A
  LD A,(RickClimbing)
  LD (RestartClimb),A
  LD A,(RickCrawling)
  LD (RestartCrawl),A
  LD A,(RideMode)
  LD (RestartRide),A
  LD A,C
  LD (ViewTopRow),A       ; the view's top row
  LD (RestartTopRow),A
  ADD HL,HL               ; the section table entry: 8 bytes
  ADD HL,HL
  ADD HL,HL
  LD BC,(LevelHeader+2)
  ADD HL,BC
  LD D,(HL)               ; +0/+1: the map's offset from the maps' base
                          ; (big-endian)
  INC HL
  LD E,(HL)
  INC HL
  EX DE,HL
  LD BC,(LevelHeader+4)
  ADD HL,BC
  LD (ViewMap),HL
  EX DE,HL
  INC HL                  ; +3: the scroll limit (+2 is skipped)
  LD A,(HL)
  LD (ViewLastRow),A
  INC HL
  LD D,(HL)               ; +4/+5: the exit list's offset from the table
  INC HL
  LD E,(HL)
  EX DE,HL
  LD BC,(LevelHeader+2)
  ADD HL,BC
  LD (CheckSectionExit+$0002),HL
  EX DE,HL
  INC HL
  LD D,(HL)               ; +6/+7: the map entry list's offset from the table
  INC HL
  LD E,(HL)
  EX DE,HL
  ADD HL,BC
  LD (SectionEntries),HL
  EX DE,HL
  XOR A                   ; Rick's record off while the section is drawn
  LD (RickRecord),A
  CALL DrawSprites
  CALL DrawChangedCells
  CALL FreeAllObjects
  CALL BuildView
  XOR A                   ; spawn every entry in the view, not only the edge
                          ; rows
  DEC A
  LD (SpawnWholeView),A
  LD (SectionBusy),A
  LD A,(LevelHookOn)
  AND A
  JP Z,SetupSectionEntries
  CALL LevelHookA
  JP SetupSectionDone
SetupSectionEntries:
  CALL ScanMapObjects
SetupSectionDone:
  XOR A                   ; back to the edge-rows rule
  LD (SpawnWholeView),A
  LD (SectionBusy),A
  CALL UpdateObjects
  CALL ClearRedraw
  LD A,$01                ; Rick's record on
  LD (RickRecord),A
  CALL DrawSprites
  CALL DrawHud
  XOR A                   ; the bonus countdown stops
  LD (BonusRunning),A
  LD (BonusPrescaler),A
  LD A,(ExitDirection)    ; the exit request cleared; both tails are the same
  CP $01
  LD A,$00
  LD (ExitDirection),A
  JP NZ,SetupSectionRedraw
  CALL RedrawView
  CALL DrawChangedCells
  RET
SetupSectionRedraw:
  CALL RedrawView
  CALL DrawChangedCells
  RET
