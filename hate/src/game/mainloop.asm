; The game's entry: interrupts off
;
; Entered from $C2B1 after loading. Interrupts stay off from here on: no pass
; waits for a frame (docs/04-game-loop.md 4.5). Runs on into MainLoop.
GameEntry:
  DI                      ; interrupts off for good

; Menu, game start, round start and the pass loop
;
; The whole game state machine; it never returns (docs/04-game-loop.md
; 4.1-4.4). $CF33 calls the menu, then starts a game or the demo; RoundStart
; ($CF68) starts a round or a retry, pre-rolls 32 strips and enters the pass
; loop PassLoop ($CFAC). A lost vehicle (CheckLost, $CFEF) retries the round,
; falls back to an earlier one (LookBack, $D017) or ends in GameOver ($D0A5).
; The pass also reads the abort (U+G) and pause (P) keys (docs/05-controls.md
; 5.5). GAME OVER and ABORT return to $CF33.
MainLoop:
  CALL Menu               ; the menu; returns when a game or the demo starts
  LD HL,RoundTable+$0001  ; SCORE ($EF49) = round 0's saved SCORE
  LD DE,Score
  LD BC,$0005
  LDIR
  XOR A                   ; round number $C2F7 = 0
  LD (RoundNumber),A
  LD (SoundRequests),A    ; no sound requests
  LD A,$04                ; carried lives $ECE4 = 4
  LD (Followers),A
  LD HL,CourseTable       ; a game starts with the record of round 1
  LD A,(DemoFlag)         ; the demo?
  AND A
  JR Z,l_CF65
  CALL Random             ; random number in HL
  LD A,L
  AND $1C                 ; the demo: one of records 3-10, (L AND $1C) + 8
                          ; bytes in
  ADD A,$08
  LD C,A
  LD B,$00
  LD HL,CourseTable
  ADD HL,BC
l_CF65:
  LD (RestartRecord),HL   ; the record a round start uses
RoundStart:
  LD HL,(RestartRecord)   ; a round start or a retry
  LD (CourseRecord),HL
  LD HL,ProfileBuffer     ; clear the ground profile $6000-$62FF
  LD DE,ProfileBuffer+$0001
  LD (HL),L
  LD BC,$02FF
  LDIR
  LD (StripCount),BC      ; strips drawn $C3FA = 0
  LD (ScrollDistance),BC  ; scroll distance = 0
  LD HL,PlayerRecord      ; 11 records from $C000: free ($8B), then the end of
                          ; the list
  LD B,$0B
  LD DE,$0010
l_CF8A:
  LD (HL),$8B
  ADD HL,DE
  DJNZ l_CF8A
  LD (HL),$FF
  LD A,$02                ; $C2F6, the new height worked on by the mover, = 2
  LD (MoverHeight),A
  XOR A
  LD (ScrollPage),A       ; scroll state: page offset 0, half 0
  LD (ScrollHalf),A
  LD HL,(CourseRecord)
  CALL CourseExpand       ; the course into RowList
  LD B,$80                ; pre-roll: 128 scroll steps, 32 strips; the last one
                          ; calls RoundSetup
l_CFA5:
  PUSH BC
  CALL ScrollStep
  POP BC
  DJNZ l_CFA5
PassLoop:
  LD A,(DemoFlag)         ; one pass of the game
  AND A
  JR Z,ShotGauge
  LD HL,DemoMessage       ; " DEMO " in the status window
  CALL PrintString
  XOR A
  LD (PlayerRecord+$0006),A ; the demo: player's speed 0
  JP PassWork
ShotGauge:
  LD A,(AutoCountdown)    ; the shot gauge, not during the AUTO start
  AND A
  JR NZ,CheckLost
  LD HL,PlayerShotRecords ; count the free ones of the 5 shot slots (bit 7)
  LD DE,$0010
  LD B,$05
  XOR A
l_CFCE:
  BIT 7,(HL)
  JR Z,l_CFD3
  INC A
l_CFD3:
  ADD HL,DE
  DJNZ l_CFCE
  LD HL,ShotGaugeText+$0007 ; the gauge text at $C333: five spaces, then a "/"
                            ; per free slot
  LD B,$05
l_CFDB:
  LD (HL),$20
  DEC HL
  DJNZ l_CFDB
  AND A
  JR Z,l_CFE9
  LD B,A
l_CFE4:
  INC HL
  LD (HL),$2F
  DJNZ l_CFE4
l_CFE9:
  LD HL,ShotGaugeText
  CALL PrintString
CheckLost:
  LD A,(PlayerRecord)     ; the player's record gone: the vehicle is lost
  BIT 7,A
  JR Z,ReadInput
  LD HL,SpriteGfxCopy+$0505 ; the loss beep
  CALL Beep
  LD A,(Lives)            ; lives less one, carried to the next round start
  DEC A
  LD (Followers),A
  JR NZ,RetryRound        ; lives left: the same round again
  LD HL,$5A58             ; no lives: hide the last dot
  LD (HL),$12
  CALL ShortPause         ; a short pause
  CALL UpdateMax          ; MAX from SCORE
  LD A,(RoundNumber)      ; round 1: GAME OVER
  DEC A
  JP Z,GameOver
LookBack:
  DEC A                   ; try the round before, down to round 2
  JP Z,GameOver
  LD (RoundNumber),A      ; the round number one less; RoundSetup counts it up
                          ; again
  ADD A,A
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,CourseTable       ; its course record
  ADD HL,BC
  LD (RestartRecord),HL
  LD A,(RoundNumber)
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,C
  LD C,A
  LD HL,RoundTable        ; its round table entry: lives at its start, then
                          ; SCORE
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD DE,Score             ; SCORE back to that round's start
  LD BC,$0005
  LDIR
  DEC A                   ; its lives less one
  LD (Followers),A
  JR Z,l_D04B
  CP $05                  ; 1-4 lives: restart that round
  JP C,RoundStart
l_D04B:
  LD A,(RoundNumber)
  JR LookBack
RetryRound:
  CALL UpdateMax          ; MAX from SCORE
  LD A,(RoundNumber)
  DEC A
  LD (RoundNumber),A
  ADD A,A
  LD B,A
  ADD A,A
  ADD A,B
  LD C,A
  LD B,$00
  LD HL,RoundTable+$0001  ; SCORE back to the round's start
  ADD HL,BC
  LD DE,Score
  LD BC,$0005
  LDIR
  JP RoundStart
ReadInput:
  CALL ReadControls       ; the device, or the AUTO start
PassWork:
  CALL MoveObjects        ; objects moved and hit tested
  CALL PlaceObjects       ; objects to screen positions
  CALL BuildSpriteLists   ; save the strips under the objects, shadow and
                          ; sprite lists
  CALL DrawShadows        ; shadows and sprites into the playfield buffer
                          ; (docs/06-rendering.md)
  CALL Blit               ; the playfield to the screen, then one scroll step
  CALL PlayEffect         ; the requested sound effect
  XOR A                   ; clear the sound requests
  LD (SoundRequests),A
  LD A,$DF                ; U ...
  IN A,($FE)
  BIT 3,A
  JR NZ,PauseKeys
  LD A,$FD                ; ... and G: abort
  IN A,($FE)
  BIT 4,A
  JR NZ,PauseKeys
  LD HL,AbortMessage      ; "ABORT!"
  CALL PrintString
  LD A,(DemoFlag)         ; the demo: no GAME OVER box
  AND A
  JR NZ,BackToMenu
GameOver:
  LD HL,GameOverBox       ; the GAME OVER box and two beeps
  CALL PrintString
  LD HL,TileRuns+$01D4
  CALL Beep
BackToMenu:
  LD HL,TileRuns+$01D4    ; one beep, back to the menu
  CALL Beep
  JP MainLoop
PauseKeys:
  LD A,$DF                ; P held, ENTER not: pause
  IN A,($FE)
  BIT 0,A
  JP NZ,PassLoop
  LD A,$BF
  IN A,($FE)
  BIT 0,A
  JP Z,PassLoop
  LD HL,$0F3C             ; pause beep
  CALL Beep
  LD HL,PauseMessage      ; "PAUSE!"
  CALL PrintString
PauseWait:
  LD A,$BF                ; wait for ENTER
  IN A,($FE)
  BIT 0,A
  JR NZ,PauseWait
  LD HL,$0F3C
  CALL Beep
  LD HL,BlankMessage      ; clear the status window
  CALL PrintString
  JP PassLoop
