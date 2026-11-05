; --------------------------------------------------------------------------------------------------------------------
; rounds.asm: the level start, the player records, the title pages
;
; LevelStart prints the level's banner and scrolls the playfield to where the level (re)starts: the checkpoint keeps
; the number of columns already scrolled ($81DB), and the start replays them, the ones more than $40 back without
; drawing (ReplayFast $7F76 = $FF), the last $40 drawn. So a restart after a lost life is the same scroll run again,
; not a saved screen.
;
; PlayersSetup builds the two player records ($7F9C and $7FCC, 48 bytes each: +1 the score's high part, +4 the lives,
; +5 the deaths, +6 the level order index, +7 the pod selector, +8 the side weapon, +9 the double plasma, +$0A the
; laser level 0-3, +$0B the speed $40-$A0, +$0C the extra-life index, +$0D-+$2F the script checkpoint) and shuffles
; the middle levels: LevelOrder ($8003, 12 bytes) keeps levels 0-2 and 9-11 in place and draws a new order of 3-8 for
; every game from Random $8544. SetLevelStart puts a level's 8-byte entry ($6B2D + 8 n, F5's table) and the stack set-
; up ($81FA) into a record's checkpoint. RoundSetup does the rest of a level's start.
;
; The title pages: CreditsPage (message $15, both players' last scores, the title tune, the menu's key wait) and
; HiScorePage (message $16, the table of five at $8261, 500 frames); MainLoop shows them in turn until fire starts a
; game.
; --------------------------------------------------------------------------------------------------------------------

; the level banner and the scroll to the start point
;
; LevelSetUp $8C3B (the playfield model, the map buffer), MenuScreenSetup
; $A685, sets the print position ($80B0 = $60, $80B9 = $4B), prints message $18
; ($A423), sets $801F = $10 and $801E = $60, StartScript $8D35 (the scenery
; script); then ReplayScroll. Called by RoundSetup; 48K c2: 1 entry.
LevelStart:
  CALL LevelSetUp
  CALL MenuScreenSetup
  LD A,$60                ; the print position
  LD (RasterLines),A
  LD A,$4B
  LD (RasterFrames),A
  LD A,$18                ; message $18: the level banner
  CALL PrintMessage
  LD A,$10
  LD (ScriptRoom),A
  LD A,$60
  LD (ScriptColumn),A
  CALL StartScript

; ReplayScroll
ReplayScroll:
  LD HL,(ScrollCount)     ; the columns already scrolled before the checkpoint
  LD DE,$0000             ; zeroed: the scroll counts them again
  LD (ScrollCount),DE
  LD A,L
  LD BC,$0040
  AND A                   ; up to $40 of them drawn
  SBC HL,BC
  JR Z,ReplayDrawn
  JR NC,ReplayFastPart
  LD C,A                  ; $40 or fewer: all drawn
  LD B,$00
  JR ReplayDrawn
ReplayFastPart:
  LD C,L                  ; the ones before the last $40 with ReplayFast = $FF:
                          ; nothing drawn
  LD B,H
  LD A,$FF
  CALL ReplayColumns
  LD BC,$0040             ; then the last $40 drawn
ReplayDrawn:
  XOR A                   ; ReplayFast = 0

; scroll BC columns, ReplayFast = A
;
; A is stored in ReplayFast ($7F76, read by $8DCA: $FF skips the drawing). Each
; column: StartColumn $894D and three rounds of ResumeScript $8D45 (the scenery
; script) and BuildColumn $896D, then ScrollStep $8AED scrolls one column (and
; counts $81DB up). 48K c2: AF9F 192 rounds at a level start.
ReplayColumns:
  LD (SkipDraw),A
  PUSH BC
  JR ReplayStep           ; the first column without the scroll
; This entry point is used by the routine at ReplayRoundEnd.
ReplayColumn:
  PUSH BC
  CALL ScrollStep         ; one column scrolled

; ReplayStep
;
; Used by the routine at ReplayColumns.
ReplayStep:
  CALL StartColumn
  LD B,$03

; ReplayRound
;
; Used by the routine at ReplayRoundEnd.
ReplayRound:
  PUSH BC
  CALL ResumeScript

; ReplayRoundEnd
ReplayRoundEnd:
  CALL BuildColumn
  POP BC
  DJNZ ReplayRound
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,ReplayColumn
  RET

; the IM 2 table and a clear screen, once at the start
;
; SetUpInterrupts $8516 (the IM 2 table) and ClearScreen $858B; called once by
; MainLoop (48K c1: 1 entry).
;
; On a 128K: the glue makes the CALL $858B at $AFB3 CALL ClearThenMusic ($5B46)
; (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).
InterruptSetup:
  CALL SetUpInterrupts
  CALL ClearScreen
  RET

; both player records and the level order of a new game
;
; CurrentPlayer $7F98 = 1, PlayerRecord $7F99 = $7F9C; both records (96 bytes
; from $7F9C) zeroed; player 1's lives = 2, player 2's = 3 when Players ($7F9B)
; is 2, else 0; the speed +$0B = $40 and the laser level +$0A = 1 for both;
; SetLevelStart for each (both at level 0). Then LevelOrder $8006-$800B: six
; different numbers 3-8 drawn from Random $8544 (one game measured: 07 06 05 04
; 08 03, ../zynaps/work/f4/invuln.py). Called by MainLoop.
PlayersSetup:
  LD A,$01
  LD (CurrentPlayer),A
  LD HL,Player1
  LD (PlayerRecord),HL
  LD HL,Player1
  LD DE,Player1+$0001
  LD BC,$005F
  LD (HL),$00
  LDIR
  LD A,$02
  LD (Player1Lives),A
  LD A,(Players)          ; Players: two players give player 2 three lives (the
                          ; extra one since player 1 is in play first)
  CP $02
  SBC A,A
  CPL
  AND $03
  LD (Player2Lives),A
  LD A,$40                ; the speed $40: the first speed step
  LD (Player1Speed),A
  LD (Player2Speed),A
  LD A,$01                ; the laser level 1
  LD (Player1LaserLevel),A
  LD (Player2LaserLevel),A
  LD IX,Player1
  CALL SetLevelStart
  LD IX,Player2
  CALL SetLevelStart
  LD DE,LevelOrder+$0003  ; LevelOrder + 3: the six shuffled levels
  LD C,$01
ShuffleDraw:
  XOR A                   ; the slot zeroed, a new number 0-5 from the random
                          ; generator
  LD (DE),A
  CALL Random
  AND $07
  CP $06
  JR NC,ShuffleDraw
  ADD A,$03               ; 3-8
  LD B,C
  LD HL,LevelOrder+$0003
ShuffleCheck:
  CP (HL)                 ; against the slots filled so far (and the zeroed
                          ; one)
  JR Z,ShuffleDraw
  INC HL
  DJNZ ShuffleCheck
  LD (DE),A               ; a new number: kept
  INC DE
  INC C
  LD A,C
  CP $07
  JR NZ,ShuffleDraw
  RET

; a level's start: the checkpoint, the objects, the banner, the panel
;
; RestoreCheckpoint, EnemiesSetup, ShotsSetup, PlayerSetup; the player's digit
; '0' + Player at $84BB (the banner's text), LevelStart; then RoundPlaySetup
; ($B03A). Called by MainLoop before each play loop (48K c2: 1 entry).
;
; On a 128K: the glue makes the CALL $AD56 at $B023 CALL LevelStartSound
; ($5B6D): the music off, sound $10 (the engine's $C9A5), then $AD56
; (src/game/setup.asm, glue.asm; docs/09-sound.md 9.2).
;
; WaitMenuRasterEnd $A595, ClearHitGrid $91C6 with interrupts off, Fuel = $5A,
; DeathTimer = $FF (the script runs), ClearScreen $858B, RestorePanel $A979,
; both scores (PrintPlayerScore $A4AE with 1 and 2), the lives (DrawLives
; $A4EF), WeaponRating $9B75.
RoundSetup:
  CALL RestoreCheckpoint
  CALL EnemiesSetup
  CALL ShotsSetup
  CALL PlayerSetup
  LD A,(CurrentPlayer)    ; '1' or '2' into the banner
  ADD A,$30
  LD (PlayerDigit),A
  CALL LevelStart

; RoundPlaySetup
RoundPlaySetup:
  CALL WaitMenuRasterEnd  ; the panel and the frame state
  DI
  CALL ClearHitGrid
  EI
  LD A,$5A                ; Fuel: $5A steps ($9A6D counts it down when bit 0 of
                          ; $7F63 is set; about 29 s, F2's measure)
  LD (Fuel),A
  LD A,$FF                ; DeathTimer: the script and the controls run
  LD (DeathTimer),A
  CALL ClearScreen
  CALL RestorePanel
  LD A,$01                ; both scores
  CALL PrintPlayerScore
  INC A
  CALL PrintPlayerScore
  CALL DrawLives
  CALL WeaponRating
  RET

; a level's start into a player record's checkpoint
;
; In: IX the record. +5 = 0, $81E3 = 0; the record's +$0D gets the 8 bytes of
; the level entry $6B2D + 8 * LevelOrder[+6] (the ScriptState $81D7-$81DE: +1
; the PC, +3 the scroll flags $FF, +4 the replay count), then the 5 bytes at
; $81FA (the stack pointer $81F6, zeros). Called by PlayersSetup for both
; players and by LevelDone.
SetLevelStart:
  LD (IX+$05),$00
  XOR A
  LD (ScrollRestart),A
  LD E,(IX+$06)
  LD D,$00
  LD HL,LevelOrder        ; LevelOrder[+6]
  ADD HL,DE
  LD B,(HL)
  INC B
  LD DE,$0008
  LD HL,LevelTable-$0008  ; $6B25 + 8 * (order + 1): the entry of that level
LevelEntryFind:
  ADD HL,DE
  DJNZ LevelEntryFind
  EX DE,HL
  PUSH IX
  POP BC
  LD HL,$000D
  ADD HL,BC
  EX DE,HL
  LD BC,$0008
  LDIR
  LD HL,ScriptStateInit   ; the script stack's start ($81FA: the pointer $81F6
                          ; and 3 zeros)
  LD BC,$0005
  LDIR
  RET

; the title page with both players' scores and the tune
;
; ClearScreen $858B, PrintMessage $15, the scores of both players at $5AA0 and
; $5AB8 (PrintBcd $A43E of record +0, C = '0') with the colour $05, plays the
; title tune (TitleTune $B446, until fire or keys 1-5), MenuKeys $A76F, then
; TitleFireCheck ($A748: carry = fire). 48K c1: 2 entries. Called by MainLoop.
CreditsPage:
  CALL ClearScreen
  LD A,$15
  CALL PrintMessage
  LD A,$05                ; the colour of the scores
  LD (PrintAttr),A
  EX AF,AF'
  LD HL,$5AA0             ; player 1's score at row 21, column 0
  LD (PrintPos),HL
  LD HL,Player1
  LD C,$30
  CALL PrintBcd
  LD HL,$5AB8             ; player 2's score at row 21, column 24
  LD (PrintPos),HL
  LD HL,Player2
  LD C,$30
  CALL PrintBcd
  CALL TitleTune          ; the tune: back at fire or a key 1-5

; l_B0C2
l_B0C2:
  CALL MenuKeys
  CALL TitleFireCheck
  RET

; the high score table, 500 frames or fire
;
; ClearScreen, PrintMessage $16, the five entries of HiScoreTable $8261 (14
; bytes each: the 10-byte print string with the initials through PrintString
; $A401, then the 4 BCD bytes through PrintBcd $A43E with C = '.') in $46; then
; 500 HALTs with TitleFireCheck polled. Out: carry when fire was pressed. 48K
; c1: 1 entry, 30 permille of the recording (the page's 10 s wait).
HiScorePage:
  CALL ClearScreen
  LD A,$16
  CALL PrintMessage
  LD A,$46
  LD (PrintAttr),A
  LD HL,HiScoreTable      ; the table: five entries
  LD B,$05
HiScoreEntry:
  PUSH BC
  CALL PrintString
  LD DE,$000A
  ADD HL,DE
  LD A,$46
  EX AF,AF'
  LD C,$2E
  CALL PrintBcd
  POP BC
  DJNZ HiScoreEntry
  LD BC,$01F4             ; 500 frames
HiScoreWait:
  HALT
  PUSH BC
  CALL TitleFireCheck
  POP BC
  RET C
  DEC BC
  LD A,C
  OR B
  JR NZ,HiScoreWait
  RET

; a lone RET ($C9) no code reaches
HiScoreSpare:
  DEFB $C9
