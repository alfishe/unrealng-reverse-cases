; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: the game's top loop, the play loop, the end of a life or level, the object set-up
;
; MainLoop: InterruptSetup once, then CreditsPage and HiScorePage in turn until fire (carry); PlayersSetup; then for
; every life or level RoundSetup, PlayLoop, EndOfPlay; NC from EndOfPlay goes on with the next round, carry (the game
; is over) back to the title pages. AbortGame (key Q in the pause) comes back with SP reset and lands on the title
; pages.
;
; PlayLoop: the frame rate counters, the events (only bit 2 posted, the pod icon), the play state zeroed, the play
; handler $A9ED installed, then EventDispatch until EndCode ($7F7D) is set by CheckPauseAndEnd. Everything else in
; play runs in the interrupt and in the jobs. EndOfPlay waits 50 frames, fades the screen and dispatches on the end
; code: 1 PlayerDied, 2 LevelDone, 3 and 4 AbortGame.
; --------------------------------------------------------------------------------------------------------------------

; after the play loop: dispatch on the end code
;
; In: A the end code (1-4). WaitFrames $A6AE for 50 frames, FadeAttributes
; $85AD, then EndHandlers ($B111) through $91E2 with code - 1. Out: carry when
; the game is over (from PlayerDied). Called by MainLoop.
EndOfPlay:
  PUSH AF
  LD A,$32
  CALL WaitFrames
  CALL FadeAttributes
  POP AF
  DEC A
  LD HL,EndHandlers       ; EndHandlers, jump-by-index
  CALL JumpTable
  RET

; the end codes 1-4: PlayerDied, LevelDone, AbortGame, AbortGame
EndHandlers:
  DEFW PlayerDied
  DEFW LevelDone
  DEFW AbortGame
  DEFW AbortGame

; end code 1: a life lost
;
; The record's deaths +5 + 1, +8 and +9 zeroed (the side weapon and the double
; plasma are lost), FuelOut $9C03 (Fuel = $5A, the laser level and the speed
; one step down). With no lives left: HighScoreEntry $A7F7, NextPlayer, and
; carry when the lives went negative (the game is over); with lives: NextPlayer
; and NC. 48K c2: 1 entry (indirect).
PlayerDied:
  LD IX,(PlayerRecord)
  INC (IX+$05)
  XOR A
  LD (IX+$08),A
  LD (IX+$09),A
  CALL FuelOut
  LD A,(IX+$04)           ; no lives left: the high score check
  AND A
  JR NZ,PlayerDiedLives
  PUSH IX
  CALL HighScoreEntry
  POP IX
  CALL NextPlayer
  LD A,(IX+$04)           ; NextPlayer took a life: negative = no player has
                          ; one
  AND A
  JP M,PlayerDiedOver
  RET
PlayerDiedLives:
  CALL NextPlayer
  AND A
  RET
PlayerDiedOver:
  SCF                     ; carry: the game is over
  RET

; the other player's turn, one life less
;
; One player: the life is taken from the current record. Two: when the other
; record has lives, it becomes PlayerRecord and Player flips (1 <-> 2); a life
; of the record in play then is taken ($B170).
;
; With INF.LIVES (on either machine) the set-up makes the DEC (IX+4) at $B170
; OR (IX+4): the lives never drop (src/game/setup.asm).
NextPlayer:
  LD A,(Players)
  DEC A
  JR Z,TakeLife
  LD HL,CurrentPlayer
  LD A,(HL)
  LD IY,Player1
  DEC A
  JR NZ,NextPlayerCheck
  LD IY,Player2
NextPlayerCheck:
  LD A,(IY+$04)           ; the other player's lives
  AND A
  JR Z,TakeLife
  PUSH IY
  POP IX
  LD (PlayerRecord),IX
  LD A,(HL)
  XOR $03
  LD (HL),A
TakeLife:
  DEC (IX+$04)            ; DEC lives: -1 is the game's end
  RET

; end code 2: the next level
;
; The record's +6 + 1, wrapping from 12 to 0, SetLevelStart. Not in 48K c1 or
; 48K c2; 48K r1 (the long bot run, 75001 frames) ran it 11 times (frames
; 6257-67115); seen in ../zynaps/work/f4/invuln.py (Invulnerable on, 30000
; frames): level 0 ended near frame 6500, 1 near 14500, 2 near 20500, 3 near
; 27500, and with LevelOrder 00 01 02 07 06 05 04 08 03 09 0A 0B the scripts
; ran $6B8D, $6C1A, $6C97, $70F6 (order 7), $7068 (order 6).
LevelDone:
  LD HL,(PlayerRecord)
  PUSH HL
  POP IX
  LD A,(IX+$06)
  INC A
  CP $0C
  JR NZ,LevelDoneStore
  XOR A
LevelDoneStore:
  LD (IX+$06),A           ; 12 wraps to level 0
  CALL SetLevelStart
  RET

; end codes 3 and 4: back to the title pages
;
; DI, TitleInterrupt $A9E4, SP = $5C00 (whatever the stack held), JP
; MainLoopTitle: CreditsPage comes next. Code 4 is set by key Q in the pause.
AbortGame:
  DI
  LD HL,TitleInterrupt
  LD (InterruptHandler),HL
  LD SP,$5C00
  JP MainLoopTitle

; the pause: fire resumes, Q aborts
;
; StopAndSettle, then a loop: a delay of $2000 rounds, TitleFireCheck ($A748:
; fire, back to play), key Q (half row $FBFE, bit 0): EndPending = 4 (the play
; loop ends, AbortGame). Called by CheckPauseAndEnd on key 4, inside the play
; interrupt: the whole game stands. Measured (../zynaps/work/f4/pause.py):
; after key 4, PassCount $7F62 stayed $4D and the script PC $6B96 for 400
; frames; Q gave $7F7C/$7F7D = 4/4, Handler $A9E4 and the credits page.
;
; On a 128K: the glue makes the LD ($7F7C),A at $B1B0 JP Key4MusicOn ($5B82):
; the store, then the music on (src/game/setup.asm, glue.asm; docs/09-sound.md
; 9.2).
Pause:
  CALL StopAndSettle
PauseLoop:
  LD BC,$2000
PauseDelay:
  DEC BC
  LD A,C
  OR B
  JR NZ,PauseDelay
  CALL TitleFireCheck
  RET C
  LD A,$FB                ; key Q
  IN A,($FE)
  BIT 0,A
  JR NZ,PauseLoop
  LD A,$04                ; EndPending = 4: abort
  LD (EndPending),A
  RET

; a life or a level of play
;
; FrameRate $7F6A = $C8, $7F6B = 8; EventRequests = 0 and EventMask = $FF, then
; bit 2 posted (the pod icon); $7F65 (the interrupt phase), $7F64,
; CurrentEffect $7F97, EndPending, EndCode and $974C zeroed; one frame, the
; play handler $A9ED; then EventDispatch round after round (48K c2: 68083)
; until EndCode is set. The play interrupt does the frame's work meanwhile.
; Then TitleInterrupt, SavePanel $A98D, and A = EndCode. Called by MainLoop.
PlayLoop:
  LD A,$C8
  LD (ShiftPage),A
  LD A,$08
  LD (FineScrollToggle),A
  LD HL,$FF00             ; L = 0 the requests, H = $FF the mask
  LD (EventRequests),HL
  LD HL,EventRequests     ; bit 2: draw the pod icon first
  SET 2,(HL)
  XOR A
  LD (PassPhase),A
  LD (PassDepth),A
  LD (CurrentEffect),A
  LD (EndPending),A
  LD (EndCode),A
  LD (LandingFlag),A
  EI
  HALT
  DI
  LD HL,PlayInterrupt     ; the play handler
  LD (InterruptHandler),HL
  EI

; PlayLoopPass
;
; Used by the routine at PlayLoopAgain.
PlayLoopPass:
  CALL EventDispatch      ; one pass: the highest job

; PlayLoopCheck
PlayLoopCheck:
  LD A,(EndCode)          ; EndCode: set by CheckPauseAndEnd

; PlayLoopTest
PlayLoopTest:
  AND A

; PlayLoopBranch
PlayLoopBranch:
  JR NZ,PlayLoopEnd

; PlayLoopAgain
PlayLoopAgain:
  JR PlayLoopPass
; This entry point is used by the routine at PlayLoopBranch.
PlayLoopEnd:
  DI                      ; TitleInterrupt again
  LD HL,TitleInterrupt
  LD (InterruptHandler),HL
  EI
  CALL SavePanel
  LD A,(EndCode)
  RET

; the game's top loop
;
; Entered from Start ($B72C). InterruptSetup, then the title pages until fire,
; PlayersSetup, and the rounds of RoundSetup, PlayLoop and EndOfPlay. Never
; returns.
;
; On a 128K: the glue makes the CALL $AFB0 at $B200 CALL MusicOn ($5B49, the
; music on); the menu loop's JR $B203 at $B21A becomes JR $B200, so after a
; game it passes that CALL again: the music starts again (src/game/setup.asm,
; glue.asm; docs/09-sound.md 9.2).
;
; With K-MOUSE the CALL $B1B4 at $B212 becomes CALL MouseReset ($FE00) at a
; life's start (src/game/setup.asm).
MainLoop:
  CALL InterruptSetup
; This entry point is used by the routines at AbortGame, l_B207 and
; MainLoopEnd.
MainLoopTitle:
  AND A                   ; NC: the title pages (AbortGame and the end of a
                          ; game come here)
  CALL NC,CreditsPage

; l_B207
l_B207:
  CALL NC,HiScorePage
  JR NC,MainLoopTitle
  CALL PlayersSetup       ; fire: a new game

; MainLoopRound
;
; Used by the routine at MainLoopEnd.
MainLoopRound:
  CALL RoundSetup

; MainLoopPlay
MainLoopPlay:
  CALL PlayLoop

; MainLoopEnd
MainLoopEnd:
  CALL EndOfPlay
  JR NC,MainLoopRound     ; NC: the next life or level
  JR MainLoopTitle        ; carry: the game is over

; the player's ship and the objects tied to it
;
; The ship's record $F36C: X 0/$14, Y 0/8, active (bit 7 of +8), +$25 = $68;
; $F37C = $20, $F380 = $40; the record $F600 inactive; $80BF = 0. Then eight
; pairs of words below $80E0 written by PUSHes with SP moved there (DE = $0800,
; HL = $1400: 32 bytes $80C0-$80DF) with interrupts off. $F5D4 and $F5A8
; inactive. When the record's side weapon +8 is 2 or more (2 plasma, 3 homing
; missiles, 4 seeker), +8 = 0 and its pod action runs again through the pod
; table $80F0 (PodPlasma, PodHoming, PodSeeker), which arms it anew for the new
; ship. Called by RoundSetup.
PlayerSetup:
  LD IY,PlayerObject
  LD (IY+$03),$00
  LD (IY+$04),$14
  LD (IY+$05),$00
  LD (IY+$06),$08
  SET 7,(IY+$08)          ; active
  LD (IY+$25),$68
  LD A,$20
  LD (PlayerAccelX),A
  LD A,$40
  LD (PlayerAccelY),A
  LD IY,SightObject
  RES 7,(IY+$08)
  XOR A
  LD (ShipHistoryIndex),A
  DI                      ; interrupts off: SP is borrowed
  LD (FillRestoreSP+$0001),SP ; SP into the operand of LD SP at $B262
  LD SP,LockTarget
  LD HL,$1400             ; eight times the pair $1400, $0800 down from $80E0
  LD DE,$0800
  LD B,$08
FillPairs:
  PUSH DE
  PUSH HL
  DJNZ FillPairs
FillRestoreSP:
  LD SP,$0000             ; LD SP,old: the operand written at $B24F
  EI
  LD IY,SideShot
  RES 7,(IY+$08)
  LD IY,PlasmaBall2
  RES 7,(IY+$08)
  LD IX,(PlayerRecord)    ; the side weapon +8: 2 or more
  LD A,(IX+$08)
  CP $02
  RET C
  LD (IX+$08),$00
  LD HL,PodActions        ; the pod actions at $80F0, JumpTable on the side
                          ; weapon
  CALL JumpTable
  RET

; the five enemy records inactive, then the pod objects
;
; The five records of $2C bytes at $F398: inactive (bit 7 of +8), +$26 = $E0,
; +$27 = $80. Then PodsSetup. Called by RoundSetup.
EnemiesSetup:
  LD B,$05
  LD IY,EnemyObjects
EnemiesSetupNext:
  PUSH BC
  RES 7,(IY+$08)
  LD (IY+$26),$E0
  LD (IY+$27),$80
  LD BC,$002C
  ADD IY,BC
  POP BC
  DJNZ EnemiesSetupNext
  CALL PodsSetup
  RET

; the three objects at $F474 tied to the ship
;
; Three records of $2C bytes at $F474: +$25 = $48, kind +7 = 5, inactive,
; +$29/+$2A = $F36C (the ship's record).
PodsSetup:
  LD B,$03
  LD IY,EnemyShots
PodsSetupNext:
  PUSH BC
  LD (IY+$25),$48
  LD (IY+$07),$05
  RES 7,(IY+$08)
  LD BC,PlayerObject      ; the ship's record: a pointer
  LD (IY+$29),C
  LD (IY+$2A),B
  LD BC,$002C
  ADD IY,BC
  POP BC
  DJNZ PodsSetupNext
  RET

; the four shot records inactive
;
; $80BA = 4; four records of $2C bytes at $F4F8: +$0B = $80, +$25 = $78,
; inactive.
ShotsSetup:
  LD A,$04
  LD (LaserShotsFree),A
  LD B,$04
  LD IY,LaserShots
ShotsSetupNext:
  PUSH BC
  LD (IY+$0B),$80
  LD (IY+$25),$78
  RES 7,(IY+$08)
  LD BC,$002C
  ADD IY,BC
  POP BC
  DJNZ ShotsSetupNext
  RET
