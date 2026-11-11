; --------------------------------------------------------------------------------------------------------------------
; menus.asm: The entry, the title, the options page, the score advance table, the demo, the hi-score page, the tape
;
; The game's entry $8000 and the attract cycle, all in IM 1: TitlePage (100 passes) falls into OptionsPage (100
; passes), then ScoreAdvancePage (200 passes), DemoPage (100 main loop passes), HeroesPage (200 passes) and back to
; TitlePage. a1 went round it once while idle: the score advance table about 19 800, the demo about 20 800, the heroes
; about 21 200.
;
; Every page pass reads the keys through small checks that jump straight to the next page with SP reset from $B25D:
; MenuCheckStart (S or fire: the game $8F10), MenuCheckHeroes (H), MenuCheckTape (L load, J save, G verify the hi-
; score tables), MenuCheckAnyKey (the options page). The options page itself reads one key with the ROM's KEY_SCAN and
; sets the players $B257, the course $B258 and the controls $B259.
;
; The tape code saves, loads and verifies $12E bytes from $88AC (the all-time tables, HiScores module) with the flag
; byte $6C, with ERR_SP hooked to TapeErrorHandler $82F3 so that a BREAK (report D) comes back to the menu. A block
; whose flag byte is $6B is reported as an Atarisoft Robotron hi-score table: the tape code is shared with Atarisoft's
; Robotron.
;
; The pages draw a pixel frame (DrawPixelFrame) whose attribute rings change colour each pass (CycleFrameColours), and
; every text attribute steps through ColourCycle each pass (CycleScreenColours). The texts are print strings of $FFD0
; (codes in the notes: $10-$1A with arguments, $0D new line, $1F end).
;
; Two leftovers of a BREAK-to-BASIC exit: MenuBreakTest $8215 is called on every page but its result is never tested,
; and MenuBreakToBasic $8222, which nothing calls, would set IM 1 and stop with report L.
; --------------------------------------------------------------------------------------------------------------------

; The game's entry (USR 32768): keeps the BASIC's SP at $B25D, then the title
;
; Runs once, from BASIC's USR (c1 frame 256; the stage-1 recordings start here
; from the entry snapshot). The SP saved at $B25D ($C338 in c1) is the one
; every page reloads before jumping to the next, so the stack never grows over
; the pages, and the game never returns to BASIC.
;
; Witness: game 1, a1 1, g1 1, t1 1, p2 1, h1 1, i1 1, i2 1.
MenuEntry:
  LD (BasicStack),SP

; The title page: Moon Patrol, the copyright and the key list; 100 passes, then
; the options page
;
; SP = $B25D. The print variable $F0A2 = 8, the screen cleared with attribute
; $44 ($9044), the pixel frame (DrawPixelFrame) and its colours
; (CycleFrameColours). The two picture words through $AFAB: "Moon" from $6132
; (lines $18-$30, 10 bytes wide at x $58: $B247/$B248 = $18/$31, $B249/$B24A =
; $58/$0A) and "Patrol" from $622C (lines $37-$4F, 14 bytes at x $48). Then
; TitleText $8413.
;
; 100 passes, each: MenuCheckStart (S or fire: the game), MenuCheckHeroes (H),
; MenuCheckTape (L, J, G), MenuCheckAnyKey (any other key: the options page),
; CycleScreenColours, CycleFrameColours, MenuDelay 100. Unlike the other pages
; it does not call MenuBreakTest. After the 100th pass it falls into
; OptionsPage.
;
; Entered from MenuEntry, from HeroesPage at its end ($81FF) and from the abort
; $AABF. Witness: a1 2 (the start, the abort at 3190), h1 2, the others 1; the
; loop ran 100 passes and fell through only in t1 and h1 ($8063).
TitlePage:
  LD SP,(BasicStack)
  LD A,$08
  LD (FontDescriptors+$000C),A
  LD A,$44
  CALL ClearScreen
  CALL DrawPixelFrame
  CALL CycleFrameColours
  LD HL,$3118             ; "Moon": lines $18-$30, x $58, 10 bytes a line
  LD (BlitTop),HL
  LD HL,$0A58
  LD (BlitX),HL
  LD HL,TitleMoon
  CALL BlitRows
  LD HL,$50*256+$37       ; "Patrol": lines $37-$4F, x $48, 14 bytes a line
  LD (BlitTop),HL
  LD HL,$0E48
  LD (BlitX),HL
  LD HL,TitlePatrol
  CALL BlitRows
  LD HL,TitleText         ; the copyright line and the key list
  CALL PrintText
  CALL CycleFrameColours
  EXX
  LD B,$64                ; 100 passes
TitleLoop:
  EXX                     ; one pass: the keys, the colours, a delay
  CALL MenuCheckStart
  CALL MenuCheckHeroes
  CALL MenuCheckTape
  CALL MenuCheckAnyKey
  CALL CycleScreenColours
  CALL CycleFrameColours
  LD C,$64
  CALL MenuDelay
  EXX
  DJNZ TitleLoop
  EXX                     ; the passes ran out: the options page

; The options page: one or two players, the course, the controls; 100 passes,
; then the score advance table
;
; The screen cleared (attribute 0), the frame, OptionsText $84FA. The three
; normal colours of the option groups are reset ($B25A = 6, $B25B = $46, $B25C
; = 4) and OptionsHighlightLine marks the current choices in bright white: the
; players $B257 (row $19 + 8 x value), the course $B258 ($31 + 8 v), the
; controls $B259 ($49 + 8 v) and the line "S Start Game" ($99).
;
; 100 passes, each: MenuBreakTest (result unused), MenuCheckStart,
; MenuCheckHeroes, MenuCheckTape, CycleScreenColours, CycleColourRange over
; $B25A-$B25C (the un-highlight colours step through ColourCycle too, so a line
; un-highlighted later gets the current colour), CycleFrameColours, then one
; key from KEY_SCAN: a single key goes through OptionsSelect against
; OptionPlayerKeys (O, T), OptionCourseKeys (1, 2) and OptionControlKeys (Z X C
; V B K), which moves the highlight and stores the new value. MenuDelay 100. No
; MenuCheckAnyKey here: keys select. When the passes run out, ScoreAdvancePage.
;
; The values (initial ones in the image): $B257 1 one player, 2 two players
; (1); $B258 1 Beginner, 2 Champion (1); $B259 1 Sinclair with 1 joystick (Z),
; 2 Kempston (X), 3 Cursor (C), 4 Old-type Fuller Box (V), 5 Sinclair with 2
; joysticks (B), 6 Keyboard (K) (6). The play-time reading of $B259 is $AE17 /
; $AE2C (the table $AE2E indexed by $B259 - 1); MenuCheckStart uses it for
; fire.
;
; Entered from TitlePage and from MenuCheckAnyKey ($832F). Witness: a1 21
; entries (414-21 155), t1 2, p2 1 (153-334), h1 1, i2 1 (the 2 key: Champion),
; game 3. a1 typed O, T, 1, 2, Z, X, C, V, B, K: OptionsSelect a1 2619 calls
; (537-18 573).
OptionsPage:
  XOR A
  CALL ClearScreen
  CALL DrawPixelFrame
  CALL CycleFrameColours
  LD HL,OptionsText
  CALL PrintText
  LD A,$06                ; the normal colours of the three groups
  LD (OptionColour1),A
  LD A,$46
  LD (OptionColour2),A
  LD A,$04
  LD (OptionColour3),A
  LD A,(Players)          ; the current choices in bright white
  LD B,$19
  CALL OptionsHighlightLine
  LD A,(Course)
  LD B,$31
  CALL OptionsHighlightLine
  LD A,(Controls)
  LD B,$49
  CALL OptionsHighlightLine
  XOR A                   ; and "S Start Game"
  LD B,$99
  CALL OptionsHighlightLine
  CALL CycleFrameColours
  EXX
  LD B,$64
OptionsLoop:
  EXX                     ; one pass
  CALL MenuBreakTest
  CALL MenuCheckStart
  CALL MenuCheckHeroes
  CALL MenuCheckTape
  CALL CycleScreenColours
  LD DE,OptionColour1
  LD IX,BasicStack
  CALL CycleColourRange
  CALL CycleFrameColours
  CALL KEY_SCAN              ; one key: NZ = more than two keys
  JR NZ,OptionsNextPass
  INC E                   ; E = $FF: no key
  JR Z,OptionsNextPass
  DEC E
  LD B,$02                ; the players: O = 1, T = 2
  LD A,(OptionColour1)
  LD C,A
  LD A,(Players)
  LD D,A
  LD IX,OptionPlayerKeys
  CALL OptionsSelect
  LD A,D
  LD (Players),A
  JR Z,OptionsNextPass
  LD B,$02                ; the course: 1 = Beginner, 2 = Champion
  LD A,(OptionColour2)
  LD C,A
  LD A,(Course)
  LD D,A
  LD IX,OptionCourseKeys
  CALL OptionsSelect
  LD A,D
  LD (Course),A
  JR Z,OptionsNextPass
  LD B,$06                ; the controls: Z X C V B K = 1-6
  LD A,(OptionColour3)
  LD C,A
  LD A,(Controls)
  LD D,A
  LD IX,OptionControlKeys
  CALL OptionsSelect
  LD A,D
  LD (Controls),A
OptionsNextPass:
  LD C,$64                ; the delay, the next pass
  CALL MenuDelay
  EXX
  DJNZ OptionsLoop

; The score advance table: the enemies drawn on a piece of ground with their
; points; 200 passes, then the demo
;
; Entered when OptionsPage runs out of passes. The screen cleared, the ground
; drawn by $95B0 and $9541 with $B27D forced to $FF for the drawing (then put
; back), three gaps cut into the ground line at row $A0 ($A7F4: x $22 20
; pixels, x $3F 10, x $DE 28), sixteen sprites from ScoreTableSprites through
; $A826, then ScoreAdvanceText $8655 (the points in two rows: shot, jumped).
;
; 200 passes: MenuBreakTest, MenuCheckStart, MenuCheckHeroes, MenuCheckTape,
; MenuCheckAnyKey (any key: the options page), CycleScreenColours, MenuDelay
; 100. Then DemoPage.
;
; Witness: a1 20 times, t1 once ($8118). The 200 passes ran out once (a1 $8180,
; about 19 800-20 800); the other 19 times a key went back to the options page.
ScoreAdvancePage:
  EXX                     ; the options passes' counter put back
  XOR A
  CALL ClearScreen
  LD HL,PlayerScenery     ; $B27D = $FF while the ground is drawn
  LD A,(HL)
  PUSH AF
  LD (HL),$FF
  CALL SceneryColours
  CALL ScenerySetup
  POP AF
  LD (PlayerScenery),A
  LD HL,$22A0             ; three gaps in the ground line, row $A0
  LD E,$14
  CALL UnplotRun
  LD HL,$3FA0
  LD E,$0A
  CALL UnplotRun
  LD HL,$DE*256+$A0
  LD E,$1C
  CALL UnplotRun
  EXX
  LD E,$07                ; E' = 7
  EXX
  LD HL,ScoreTableSprites ; sixteen records: y, x, sprite
  LD B,$10
ScoreTableSpriteLoop:
  LD E,(HL)               ; HL = x, y; A = the sprite: $A826 draws it
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  EX DE,HL
  CALL DrawSprite
  EX DE,HL
  DJNZ ScoreTableSpriteLoop
  LD HL,ScoreAdvanceText  ; the title and the points
  CALL PrintText
  EXX
  LD B,$C8
ScoreTableLoop:
  EXX                     ; one pass
  CALL MenuBreakTest
  CALL MenuCheckStart
  CALL MenuCheckHeroes
  CALL MenuCheckTape
  CALL MenuCheckAnyKey
  CALL CycleScreenColours
  LD C,$64
  CALL MenuDelay
  EXX
  DJNZ ScoreTableLoop

; The demo: a life on the course run by the main loop for 100 passes, "DEMO"
; flashing; then the hi-score page
;
; The screen cleared, the clock zeroed ($B285/$B286 = 0, $B287 = 0), $B27D
; complemented (so successive demos alternate it), the life start $90D3 (which
; sets IM 2), the tune off ($B288 = $80) and $B238 = $80, DemoText $8706.
;
; 100 passes, each one pass of the main loop's call list $96FA, then
; MenuBreakTest, MenuCheckStart, MenuCheckHeroes, MenuCheckTape,
; MenuCheckAnyKey (each leaves through SetIm1 $A7CB) and CycleColourRange over
; the five attributes $58AE-$58B2 ("DEMO"). Then SetIm1 and HeroesPage.
;
; Witness: a1 once (about 20 800, the 100 passes completed, $81CD 1).
DemoPage:
  EXX
  XOR A
  CALL ClearScreen
  LD HL,$0000
  LD (PlayerTime),HL
  XOR A
  LD (PlayerFrames),A
  LD A,(PlayerScenery)
  CPL
  LD (PlayerScenery),A
  CALL LifeStart
  LD A,$80
  LD (PlayerFlags),A
  LD (ObjectsOff),A
  LD HL,DemoText          ; "DEMO"
  CALL PrintText
  LD BC,$0064             ; 100 passes of the main loop
DemoLoop:
  PUSH BC
  CALL MainLoopCalls
  CALL MenuBreakTest
  CALL MenuCheckStart
  CALL MenuCheckHeroes
  CALL MenuCheckTape
  CALL MenuCheckAnyKey
  LD DE,Attributes+174             ; "DEMO" changes colour
  LD IX,Attributes+179
  CALL CycleColourRange
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,DemoLoop
  CALL SetIm1             ; back to IM 1

; The hi-score page: the heroes and the all-time heroes; 200 passes, then the
; title
;
; The screen cleared, the frame, HeroesDrawTables $8AE0. 200 passes:
; MenuBreakTest, MenuCheckStart, MenuCheckTape, MenuCheckAnyKey,
; CycleScreenColours, CycleFrameColours, MenuDelay 100 (no MenuCheckHeroes: H
; does nothing here). Then TitlePage.
;
; Entered from MenuCheckHeroes (H), from DemoPage, from TapeLoadDone after a
; good load ($831E), and from the game over $8F9F after the hi-score entry.
; Witness: a1 2 (H at 153; the demo about 21 200), h1 1 (4524-6060), game 4;
; the 200 passes ran out only in h1 ($81FE).
HeroesPage:
  XOR A
  CALL ClearScreen
  CALL DrawPixelFrame
  CALL CycleFrameColours
  CALL HeroesDrawTables
  CALL CycleFrameColours
  EXX
  LD B,$C8
HeroesPageLoop:
  EXX                     ; one pass
  CALL MenuBreakTest
  CALL MenuCheckStart
  CALL MenuCheckTape
  CALL MenuCheckAnyKey
  CALL CycleScreenColours
  CALL CycleFrameColours
  LD C,$64
  CALL MenuDelay
  EXX
  DJNZ HeroesPageLoop
  EXX                     ; the passes ran out: the title
  JP TitlePage

; Marks an option line bright white: A = the value, B = the first line's pixel
; row
;
; Row = 8 A + B; LineAttrAddress, then HighlightLine28 (28 cells $47 from the
; third column). Called four times by OptionsPage (the players, the course, the
; controls, and A = 0 for "S Start Game" at row $99). Witness: a1 84, game 12,
; t1 8, p2 4, h1 4, i2 4.
OptionsHighlightLine:
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,B
  CALL LineAttrAddress
  CALL HighlightLine28
  RET

; A delay of C x 256 DJNZ passes (C = 100 on the pages: about 333 000 T, near 5
; frames)
;
; B = 0, C counted down. Called once a pass by every page and by the bonus
; screen $A4EE. Witness: a1 2327 calls, i1 142.
MenuDelay:
  LD B,$00
MenuDelayLoop:
  DJNZ MenuDelayLoop
  DEC C
  JR NZ,MenuDelayLoop
  RET

; Dead BREAK test: A bit 0 = 0 when CAPS SHIFT and SPACE are both held; no
; caller tests it
;
; Reads half-rows $FE (CAPS SHIFT) and $7F (SPACE), ORs them and keeps bit 0: 0
; only when both keys are down. Every caller (OptionsPage, ScoreAdvancePage,
; DemoPage, HeroesPage, the tape message loop) goes on to its next call without
; looking at A or the flags, so CAPS+SPACE does nothing on the menus. It looks
; like the test that once led to MenuBreakToBasic $8222. Witness: a1 2424
; calls, h1 296, t1 216.
MenuBreakTest:
  LD BC,$FEFE
  IN E,(C)
  LD B,$7F
  IN A,(C)
  OR E
  AND $01
  RET

; Unreferenced stub: IM 1, then RST 8 with report L (BREAK into program): back
; to BASIC
;
; CALL SetIm1 $A7CB, RST 8, DEFB $14. Nothing calls or jumps here (no operand
; $8222 in the image) and no recording ran or read it (game, a1, g1, t1, p2,
; h1, i1, i2, h2): known only from the code. With MenuBreakTest it would have
; made CAPS+SPACE leave the game for BASIC, a development aid left in.
MenuBreakToBasic:
  CALL SetIm1
  RST $08                 ; RST 8: the byte after it, $14 (shown as INC D), is
                          ; report L, BREAK into program
  INC D

; S, or fire on the chosen joystick: IM 1 kept, SP reset, the game $8F10
;
; Half-row $FD alone with S (bit 1) held starts the game. Otherwise, unless the
; controls $B259 are 6 (the keyboard), $AE17 reads the chosen joystick and A =
; 1 (fire) starts it. Start: SetIm1 $A7CB, SP = $B25D, JP $8F10. Witness:
; called a1 2450 times; the joystick read ran game 55, a1 39 (a1 chose a
; joystick on the options page); the start game 5, a1 1 (1314), g1, p2, h1, i1,
; i2 1 each.
MenuCheckStart:
  LD A,$FD
  IN A,($FE)
  OR $E0
  CP $FD
  JR Z,MenuStartGame
  LD A,(Controls)         ; the keyboard: no fire to read
  CP $06
  RET Z
  CALL ControlsRead       ; the joystick read of the chosen controls (annotator
                          ; 04's $AE17): A = 1 for fire
  CP $01
  RET NZ
MenuStartGame:
  CALL SetIm1             ; IM 1, the BASIC's SP, the game
  LD SP,(BasicStack)
  JP GameStart

; H (half-row $BF bit 4): IM 1, SP reset, the hi-score page
;
; Witness: called a1 2365 times; taken a1 once ($8250, frame 153).
MenuCheckHeroes:
  LD A,$BF
  IN A,($FE)
  OR $E0
  CP $EF
  RET NZ
  CALL SetIm1
  LD SP,(BasicStack)
  JP HeroesPage

; L, J or G: load, save or verify the hi-score tables on tape, with ERR_SP
; hooked to TapeErrorHandler
;
; Half-row $FD bit 4 (G) and half-row $BF bits 1 (L) and 3 (J); nothing held
; returns. Otherwise: SP saved at $B263, the word at ERR_SP (where the ROM's
; error report returns) swapped for $82F3 and kept at $B265, the keys kept at
; $B23A, then DE = $12E bytes, A = flag $6C:
;
; L: LD_BYTES with carry set (load) into the buffer $BEF8 (the object list,
; free on the menus). J: SA_BYTES from $88AC (the all-time tables, HiScores
; module), then ERR_SP put back, RET. G: LD_BYTES with carry clear (verify)
; against $88AC. When both run, L wins over J and G, and G over J.
;
; After LD_BYTES (TapeLoadOrVerify), ERR_SP put back; carry set (the flag and
; the checksum good) goes to TapeLoadDone $8309. A failure (carry clear) prints
; a message: A = L, the last byte LD_BYTES read; when that was the flag byte,
; $6B, the block is a Robotron table (the flag byte Atarisoft's Robotron saves
; its table with) and RobotronWarningText $873B is printed, anything else gives
; TapeErrorText $8716 "Tape error - hit any key." (TapeFailed). Then the
; message loop: the menu checks forever, any key goes to the options page.
;
; Witness: t1 J (SA_BYTES 153-479), L and G (LD_BYTES 1077-2650): $826B 3,
; $8290 2 (not L), $8299 1 (J), $82A9 2 (L and G). LD_BYTES never returned in
; t1: it waits for a tape edge until SPACE is pressed (the ROM has no time-out
; there), and SPACE ended both with report D through TapeErrorHandler. So
; $82AC-$82F2, the failure messages and the message loop, never ran in any
; recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code.
MenuCheckTape:
  LD A,$FD
  IN A,($FE)
  OR $EF
  LD E,A
  LD A,$BF
  IN A,($FE)
  OR $F5
  AND E
  CP $FF
  RET Z
  LD (TapeStack),SP       ; hook ERR_SP: the ROM's error return now goes to
                          ; TapeErrorHandler
  LD SP,(ERR_SP)
  LD HL,TapeErrorHandler
  EX (SP),HL
  LD (TapeErrSp),HL
  LD SP,(TapeStack)
  LD DE,$012E             ; $12E bytes, flag $6C, load into $BEF8 by default
  LD H,A
  LD (TapeKey),A
  LD A,$6C
  SCF
  LD IX,ObjectList
  BIT 1,H                 ; L: load
  JR Z,TapeLoadOrVerify
  AND A                   ; not L: verify (carry clear) or save, the tables at
                          ; $88AC
  LD IX,GreatestPoint
  BIT 4,H                 ; G: verify
  JR Z,TapeLoadOrVerify
  CALL SA_BYTES              ; J: save, ERR_SP back, return to the page
  LD SP,(ERR_SP)
  LD HL,(TapeErrSp)
  EX (SP),HL
  LD SP,(TapeStack)
  RET
TapeLoadOrVerify:
  CALL LD_BYTES              ; LD_BYTES: returns only with a tape signal (else
                          ; BREAK, report D)
  LD A,L                  ; A = L: the last byte read, the flag byte when the
                          ; flag did not match
  LD SP,(ERR_SP)
  LD HL,(TapeErrSp)
  EX (SP),HL
  LD SP,(TapeStack)
  JR C,TapeLoadDone       ; carry: loaded or verified
TapeFailed:
  LD HL,RobotronWarningText ; the flag byte $6B: an Atarisoft Robotron table
  CP $6B
  JR Z,TapeShowMessage
  LD HL,TapeErrorText     ; any other failure: "Tape error - hit any key."
TapeShowMessage:
  PUSH HL                 ; the screen cleared, the frame, the message
  XOR A
  CALL ClearScreen
  CALL DrawPixelFrame
  CALL CycleFrameColours
  POP HL
  CALL PrintText
  CALL CycleFrameColours
TapeMessageLoop:
  CALL MenuBreakTest      ; the menu checks forever: any key leaves for the
                          ; options page
  CALL MenuCheckStart
  CALL MenuCheckHeroes
  CALL MenuCheckTape
  CALL MenuCheckAnyKey
  CALL CycleScreenColours
  CALL CycleFrameColours
  LD C,$64
  CALL MenuDelay
  JR TapeMessageLoop

; The ROM's error report during a tape operation returns here: wait for
; CAPS/SPACE up, unhook ERR_SP, back to the page
;
; Reached by the ROM's error exit (LD SP,(ERR_SP), RET) while MenuCheckTape has
; the hook in: report D (BREAK) from SA_BYTES or LD_BYTES. Waits until neither
; CAPS SHIFT nor SPACE (bit 0 of half-rows $FE and $7F) is held, puts the old
; word back at ERR_SP, reloads the SP MenuCheckTape saved at $B263 and returns
; to the page that called MenuCheckTape.
;
; Witness: t1 twice (the L and the G load stopped with SPACE, frames
; 1390-2670), the wait loop 65 060 instructions; no entry count because it is
; reached by RET.
TapeErrorHandler:
  LD A,$7E                ; CAPS SHIFT or SPACE still held: wait
  IN A,($FE)
  OR $FE
  INC A
  JR NZ,TapeErrorHandler
  LD SP,(ERR_SP)           ; ERR_SP back, the SP of MenuCheckTape's call, return
                          ; to the page
  LD HL,(TapeErrSp)
  EX (SP),HL
  LD SP,(TapeStack)
  RET

; A good tape block: after G (verify) back to the page; after L the buffer
; copied over the tables and the hi-score page
;
; MenuCheckTape's success path ($82B9). $B23A bit 4 clear (G held) returns.
; Otherwise (L) the $12E bytes loaded at $BEF8 replace $88AC-$89D9, SP = $B25D,
; HeroesPage. The flag byte and the ROM's checksum are the only checks. Not
; executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2; there is no
; tape of a saved table): known only from the code.
TapeLoadDone:
  LD A,(TapeKey)
  BIT 4,A
  RET Z
  LD HL,ObjectList
  LD DE,GreatestPoint
  LD BC,$012E
  LDIR
  LD SP,(BasicStack)
  JP HeroesPage

; Any key (all half-rows at once): IM 1, SP reset, the options page
;
; Witness: called a1 445 times, h1 317; taken game 3, a1 21, t1 1, p2 1, i2 1
; ($8328).
MenuCheckAnyKey:
  XOR A
  IN A,($FE)
  OR $E0
  INC A
  RET Z
  CALL SetIm1
  LD SP,(BasicStack)
  JP OptionsPage

; Every attribute of the screen found in ColourCycle steps to the next colour
; there
;
; $5800-$5AFF, each byte searched in the ten bytes of ColourCycle and replaced
; by the byte after it; other attributes stay. The menu texts are printed in
; these colours, so they change colour each pass. Witness: a1 2327 calls, h1
; 413.
CycleScreenColours:
  LD DE,Attributes
CycleColoursLoop:
  LD A,(DE)
  LD HL,ColourCycle
  LD BC,$000A
  CPIR
  JR NZ,CycleColoursNext
  LD A,(HL)
  LD (DE),A
CycleColoursNext:
  INC DE
  LD A,D
  CP $5B
  JR NZ,CycleColoursLoop
  RET

; As CycleScreenColours for the bytes DE to IX - 1 only
;
; Used by OptionsPage on its three normal colours $B25A-$B25C, by DemoPage on
; "DEMO" ($58AE-$58B2) and by the bonus screen $A4EE. Witness: a1 2103 calls,
; i1 125 (the bonus screens), i2 144.
CycleColourRange:
  LD A,(DE)
  LD HL,ColourCycle
  LD BC,$000A
  CPIR
  JR NZ,CycleRangeNext
  LD A,(HL)
  LD (DE),A
CycleRangeNext:
  INC DE
  PUSH IX
  POP HL
  AND A
  SBC HL,DE
  JR NZ,CycleColourRange
  RET

; One option group: if key E is one of its B keys, highlight the new choice,
; un-highlight the old one, D = the new value
;
; IX = the group's table (records: key value, option value, pixel row), B = its
; records, C = the group's normal colour, D = the current value, E = the key.
; NZ: not this group's key. Z with D unchanged: the key's option is already
; chosen. Otherwise the new line goes bright white (HighlightLine28), the old
; value's line gets C in its 28 cells, D = the new value; the flags are those
; of AND A on it (NZ for every value the tables hold, 1-6), so the caller goes
; on to the next group.
;
; Witness: a1 2619 calls (537-18 573), a new choice a1 10 times ($836E), game
; 2, p2 1, i2 1.
OptionsSelect:
  PUSH IX
  POP HL
  LD A,E
  PUSH BC
  CALL OptionsFindEntry
  POP BC
  RET NZ
  INC HL                  ; A = the option value of the key
  LD A,(HL)
  CP D
  RET Z
  PUSH AF
  INC HL                  ; the new line bright white
  LD A,(HL)
  PUSH DE
  CALL LineAttrAddress
  POP DE
  CALL HighlightLine28
  PUSH IX                 ; find the line of the old value
  POP HL
  INC HL
  LD A,D
  CALL OptionsFindEntry
  INC HL
  LD A,(HL)
  PUSH DE
  CALL LineAttrAddress
  POP DE
  INC HL
  INC HL
  LD B,$1C
OptionsUnhighlightLoop:
  LD (HL),C               ; 28 cells in the group's normal colour
  INC HL
  DJNZ OptionsUnhighlightLoop
  POP AF
  LD D,A
  AND A
  RET

; Searches B records of 3 bytes from HL for the byte A: Z and HL on it, or NZ
; (B = $FF)
;
; Witness: a1 2629 entries.
OptionsFindEntry:
  CP (HL)
  RET Z
  INC HL
  INC HL
  INC HL
  DJNZ OptionsFindEntry
  DEC B
  RET

; HL = the attribute address of pixel row A (the line address table at $7E00),
; column 0
;
; Witness: a1 104 calls.
LineAttrAddress:
  LD H,$7E
  LD L,A
  ADD HL,HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  RET

; 28 cells from HL + 2 set to $47 (bright white on black)
;
; Witness: a1 94 calls.
HighlightLine28:
  INC HL
  INC HL
  LD A,$1C
HighlightLoop:
  LD (HL),$47
  INC HL
  DEC A
  JR NZ,HighlightLoop
  RET

; The players group of the options page: key value, option value, pixel row (O
; = 1 at $21, T = 2 at $29)
;
; Read by OptionsPage $80D7 through OptionsSelect (a1 958 reads of $83BA). The
; key values are KEY_SCAN's ($1A = O, $05 = T); the row is the line's pixel row
; in OptionsText.
OptionPlayerKeys:
  DEFB $1A,$01,$21
  DEFB $05,$02,$29

; The course group: 1 = Beginner (key value $24, row $39), 2 = Champion ($1C,
; row $41)
OptionCourseKeys:
  DEFB $24,$01,$39
  DEFB $1C,$02,$41

; The controls group: Z X C V B K ($1F $17 $0F $07 $00 $11) = 1-6, rows $51-$79
;
; The values stored in $B259: 1 Sinclair with 1 joystick, 2 Kempston, 3 Cursor,
; 4 Old-type Fuller Box, 5 Sinclair with 2 joysticks, 6 Keyboard (OptionsText).
; a1 827 reads.
OptionControlKeys:
  DEFB $1F,$01,$51
  DEFB $17,$02,$59
  DEFB $0F,$03,$61
  DEFB $07,$04,$69
  DEFB $00,$05,$71
  DEFB $11,$06,$79

; The sixteen sprites of the score advance table: y, x, sprite number for $A826
;
; Read by ScoreAdvancePage $814F: a1 20 times, t1 once.
ScoreTableSprites:
  DEFB $1C,$08,$02
  DEFB $1C,$20,$05
  DEFB $2C,$18,$1E
  DEFB $2C,$30,$1E
  DEFB $18,$E0,$0C
  DEFB $2C,$F0,$1E
  DEFB $94,$0E,$0F
  DEFB $A0,$24,$10
  DEFB $A0,$41,$11
  DEFB $93,$59,$3B
  DEFB $8F,$66,$13
  DEFB $91,$84,$14
  DEFB $98,$A0,$40
  DEFB $94,$B6,$44
  DEFB $90,$CC,$4C
  DEFB $A0,$E0,$64

; The menu colour cycle: each attribute found in the first ten bytes becomes
; the one after it ($44 $04 $46 $06 $42 $41 $43 $03 $05 $45, back to $44)
;
; Read by CycleScreenColours and CycleColourRange (CPIR over ten bytes, the
; eleventh byte closes the loop). a1 1 793 645 reads.
ColourCycle:
  DEFB $44,$04,$46,$06,$42,$41,$43,$03,$05,$45,$44

; The title page text: the copyright line, "Press S to start." and the key list
;
; Printed by TitlePage $803C ($FFD0). Every build read it once a title (a1 2).
; A print string: codes in the notes; the first glyph "C" stands for the
; copyright sign in the title's look.
TitleText:
  INCBIN "res/text/TitleText.bin",$0000,231

; The options page text: SELECT OPTIONS, the players, the courses, the six
; controls, the keys
;
; Printed by OptionsPage $806E: a1 21 times. The control lines name the choices
; of $B259 in order 1-6; the keyboard line adds "A=Slow, Q=Fast, O=Jump,
; p=Fire".
OptionsText:
  INCBIN "res/text/OptionsText.bin",$0000,347

; The score advance table's text: the title, the underline and the points of
; each enemy (shot / jumped)
;
; Printed by ScoreAdvancePage $815C: a1 20, t1 1. The "???" is the game's own:
; the low flyer's points for a shot (stage 1 table).
ScoreAdvanceText:
  INCBIN "res/text/ScoreAdvanceText.bin",$0000,177

; "DEMO" in font 1, then font 2 selected
;
; Printed by DemoPage $81A1: a1 once.
DemoText:
  INCBIN "res/text/DemoText.bin",$0000,16

; "Tape error - hit any key.": printed by TapeFailed when a load or verify
; fails, never read
;
; Selected at $82C2 for any failed LD_BYTES whose last byte read was not $6B.
; Not read in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only
; from the code.
TapeErrorText:
  INCBIN "res/text/TapeErrorText.bin",$0000,37

; "WARNING- You have attempted to load an Atarisoft Robotron hi-score table.
; Please try again!!!", never read
;
; Selected at $82BB when the failed block's flag byte was $6B. Not read in any
; recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the code.
RobotronWarningText:
  INCBIN "res/text/RobotronWarningText.bin",$0000,113

; Plots D pixels across from x H, row L ($FD80 one pixel each)
;
; Witness: a1 400 calls.
FrameHLine:
  LD E,D
FrameHLineLoop:
  PUSH HL
  CALL PlotPixel
  POP HL
  INC H
  DEC E
  JR NZ,FrameHLineLoop
  RET

; Plots D pixels down from x H, row L
;
; Witness: a1 400 calls.
FrameVLine:
  LD E,D
FrameVLineLoop:
  PUSH HL
  CALL PlotPixel
  POP HL
  INC L
  DEC E
  JR NZ,FrameVLineLoop
  RET

; A rectangle inset B pixels from the left and right edges and C from the top
; and bottom of the 256 x 192 screen
;
; Top and bottom lines 256 - 2B wide, sides 192 - 2C high. Witness: a1 200
; calls.
FrameRectangle:
  LD H,B
  LD L,C
  LD A,B
  SLA A
  NEG
  LD D,A
  PUSH BC
  CALL FrameHLine
  POP BC
  LD H,B
  LD A,$BF
  SUB C
  LD L,A
  PUSH BC
  CALL FrameHLine
  POP BC
  LD H,B
  LD L,C
  LD E,C
  SLA E
  LD A,$C0
  SUB E
  LD D,A
  PUSH BC
  CALL FrameVLine
  POP BC
  LD L,C
  LD A,B
  CPL
  LD H,A
  PUSH BC
  CALL FrameVLine
  POP BC
  RET

; D rectangles, each one pixel further in (B, C + 1)
;
; Witness: a1 200 entries (50 calls).
FrameRectangles:
  PUSH DE
  CALL FrameRectangle
  POP DE
  INC C
  INC B
  DEC D
  JR NZ,FrameRectangles
  RET

; The pages' pixel frame: rectangles at insets 0-3 and 8-11, two four-pixel
; bands around the screen
;
; Called by TitlePage, OptionsPage, HeroesPage, TapeShowMessage and
; HiScoreEntry. Witness: a1 25, g1 2, t1 3, p2 3, h1 5, h2 1.
DrawPixelFrame:
  LD BC,$0000
  LD D,$04
  CALL FrameRectangles
  LD BC,$0808
  LD D,$04
  CALL FrameRectangles
  RET

; The frame's two attribute rings: D on the outer cells (row 0, row 23, columns
; 0 and 31), E on the ring inside
;
; Witness: a1 2162 calls.
PaintFrameAttrs:
  LD HL,Attributes
  LD B,$21
PaintFrameTop:
  LD (HL),D               ; row 0 and the first cell of row 1 in D
  INC HL
  DJNZ PaintFrameTop
  LD B,$1E
PaintFrameInnerTop:
  LD (HL),E               ; row 1 columns 1-30 in E
  INC HL
  DJNZ PaintFrameInnerTop
  LD (HL),D
  INC HL
  LD A,$14
PaintFrameSides:
  LD (HL),D               ; rows 2-21: D E at the left, E D at the right
  INC HL
  LD (HL),E
  LD BC,$001D
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  DEC A
  JR NZ,PaintFrameSides
  LD (HL),D
  INC HL
  LD B,$1E
PaintFrameInnerBottom:
  LD (HL),E               ; row 22 columns 1-30 in E
  INC HL
  DJNZ PaintFrameInnerBottom
  LD B,$21
PaintFrameBottom:
  LD (HL),D               ; the last cell of row 22 and row 23 in D
  INC HL
  DJNZ PaintFrameBottom
  RET

; The frame's eight colour pairs (outer ring, inner ring): each inner colour is
; the next pair's outer one
;
; Read by CycleFrameColours (a1 270 reads of $883D).
FrameColourPairs:
  DEFB $08,$2C
  DEFB $02,$21
  DEFB $13,$08
  DEFB $1E,$02
  DEFB $37,$13
  DEFB $3D,$1E
  DEFB $2C,$37
  DEFB $21,$3D

; The frame colours one step on: $B255 - 1 (0-7) picks a pair of
; FrameColourPairs for PaintFrameAttrs
;
; Called on every pass of TitlePage, OptionsPage, HeroesPage and the tape
; message, so the rings appear to move. Witness: a1 2162 calls, h1 422.
CycleFrameColours:
  LD A,(TitleColour)
  DEC A
  AND $07
  LD (TitleColour),A
  SLA A
  LD C,A
  LD B,$00
  LD HL,FrameColourPairs
  ADD HL,BC
  LD D,(HL)
  INC HL
  LD E,(HL)
  CALL PaintFrameAttrs
  RET
