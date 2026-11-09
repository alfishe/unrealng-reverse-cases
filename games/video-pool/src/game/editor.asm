; --------------------------------------------------------------------------------------------------------------------
; editor.asm: The table editor: place the balls with a cursor, then play the table
;
; The menu's "e" (tests/inputs/m1.txt frame 6260) enters EditorStart $C042: the table with "- editor -", two boxed
; buttons "play" and "reset" above it, the balls where the last game left them (or the rack), a cross cursor at (128,
; 115). With the keyboard chosen, the input is switched to the cursor keys for the editor: 5 left, 8 right, 7 up, 6
; down, any other key fire (ReadCursorKeys $81C4); CAPS SHIFT + SPACE (BREAK) leaves to the menu.
;
; Fire on a ball (within 4 pixels in x and y) picks it up; the same keys then push it through the physics step $8701
; (cushions and pockets act on it) and fire puts it down. Fire on "reset" racks the balls; fire on "play" starts a
; game on the edited table with the game's own aim, power and ball tasks (EditorAimTasks $C518, EditorRollTasks $C528)
; but no score; when every object ball is down it returns to the menu.
; --------------------------------------------------------------------------------------------------------------------

; The editor's screen and its cursor loop: move the cursor, fire on a ball or a
; button
;
; Entered from the menu ($B293, through a JP after a CALL: the POP HL drops
; that return). Keeps the input mode $B8BD in EditorSavedMode $C590 and sets
; mode 3 (cursor keys) when it was 0 (keyboard). Clears the screen (border
; white, BORDCR $38; attributes $39 on rows 0-5 and 23, $60 on rows 6-22),
; draws the table ($9243), blanks rows 2-5 columns 18-31, prints "- editor -",
; "play", "reset" (EditorTexts $C54E) and boxes the two buttons (EditorBox
; $C1BE: x 148-187 and 204-251, lines 20-35). With no object ball on the table
; the balls are racked ($9D2C); the balls are drawn ($9520); with the cue ball
; off the table it is respotted ($9F4E = $FFFF, $93FF). The cursor goes to
; (128, 115) (EditorCursorHome) and is drawn ($9371).
;
; The loop (EditorLoop, one HALT a pass): ReadInput $8106; fire with BREAK
; leaves (EditorExit $C414); fire goes to EditorFire $C20B; a direction moves
; the cursor by the speed in EditorCursorSpeed $C58D (EditorCursorLeft / Right
; / Up / Down: x 3..252, y 18..180). The speed: 1 pixel a frame for 15 frames,
; then one more every 16 frames up to 5; it starts again at 1 when the input
; changes, is released or the cursor does not move.
;
; Witness (l1sum.py C042 C116 C196 C20B C414): m1 only: entered at 6262, the
; loop 6271-6830, 30 passes each of left (6600-6629), down (6640-6669), up
; (6680-6709), right (6720-6749), fire 110 passes (6420-6769, no ball in
; reach), BREAK at 6830 (EditorExit).
EditorStart:
  POP HL
  LD A,(Control)
  LD (EditorSavedMode),A
  OR A
  JR NZ,EditorKeepMode
  LD A,$03
EditorKeepMode:
  LD (Control),A
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  LD A,$07
  OUT ($FE),A
  LD A,$38
  LD (BORDCR),A
  INC HL
  INC DE
  LD BC,$003F
  LD (HL),$39
  LDIR
  INC HL
  INC DE
  LD BC,$007F
  LD (HL),$39
  LDIR
  INC HL
  INC DE
  LD BC,$021F
  LD (HL),$60
  LDIR
  INC HL
  INC DE
  LD BC,$001F
  LD (HL),$39
  LDIR
  CALL DrawTable
  LD HL,EditorButtonsBlank
  LD (HL),$02
  CALL PrintText
  LD HL,EditorButtonsBlank
  LD (HL),$03
  CALL PrintText
  LD HL,EditorButtonsBlank
  LD (HL),$04
  CALL PrintText
  LD HL,EditorButtonsBlank
  LD (HL),$05
  CALL PrintText
  LD HL,EditorTexts
  CALL PrintText
  LD HL,EditorPlayText
  CALL PrintText
  LD HL,EditorResetText
  CALL PrintText
  LD D,$14
  LD E,$94
  LD H,$23
  LD L,$BB
  CALL EditorBox
  LD D,$14
  LD E,$CC
  LD H,$23
  LD L,$FB
  CALL EditorBox
  LD IX,BallRecords
  LD DE,$000E
  LD B,$06
EditorAnyBall:
  ADD IX,DE               ; is an object ball on the table?
  BIT 7,(IX+$0D)
  JR NZ,EditorDrawBalls
  DJNZ EditorAnyBall
  CALL ResetBallPositions
EditorDrawBalls:
  CALL DrawAllBalls
  LD IX,BallRecords
  BIT 7,(IX+$0D)
  JR NZ,EditorCursorHome
  LD HL,$FFFF
  LD (LivesLeft),HL
  CALL RespotCueBall
; This entry point is used by the routine at EditorReset.
EditorCursorHome:
  LD H,$73                ; the cursor at (128, 115) (also EditorReset's way
                          ; back)
  LD L,$80
  LD (CursorX),HL
; This entry point is used by the routine at EditorFire.
EditorCursorShow:
  CALL DrawCursor         ; draw the cursor, previous input 0 (EditorFire's way
                          ; back)
  LD A,$00
  LD (CursorLastInput),A
; This entry point is used by the routine at EditorFire.
EditorSpeedReset:
  LD A,$F1                ; speed 1
  LD (EditorCursorSpeed),A
; This entry point is used by the routine at EditorFire.
EditorLoop:
  HALT                    ; one HALT a pass
  CALL ReadInput
  LD A,(CursorLastInput)
  LD B,A
  LD A,(InputState)
  LD (CursorLastInput),A
  CP B
  JR Z,EditorKeys
  LD A,$F1
  LD (EditorCursorSpeed),A
EditorKeys:
  LD A,(InputState)
  CP $00
  JR Z,EditorSpeedReset
  AND $20
  JP NZ,EditorExit
  LD A,(InputState)
  AND $10
  JP NZ,EditorFire
  LD A,(EditorCursorSpeed)
  SUB $10
  LD (EditorCursorSpeed),A
  JR NC,EditorMoveCursor
  AND $0F
  CP $05
  JR NC,EditorSpeedUp
  INC A
EditorSpeedUp:
  ADD A,$F0
  LD (EditorCursorSpeed),A
EditorMoveCursor:
  CALL DrawCursor         ; erase, move by the speed, draw
  LD A,(EditorCursorSpeed)
  AND $0F
  LD B,A
  LD HL,(CursorX)
  PUSH HL
  LD A,(InputState)
  AND $02
  CALL NZ,EditorCursorLeft
  LD A,(InputState)
  AND $01
  CALL NZ,EditorCursorRight
  LD A,(InputState)
  AND $04
  CALL NZ,EditorCursorUp
  LD A,(InputState)
  AND $08
  CALL NZ,EditorCursorDown
  LD (CursorX),HL
  CALL DrawCursor
  LD HL,(CursorX)
  POP DE
  OR A
  SBC HL,DE
  JP Z,EditorSpeedReset
  JP EditorLoop

; Cursor x - speed, not under 3
;
; L = x, B = the speed. m1 30 calls (6600-6629).
EditorCursorLeft:
  LD A,L
  SUB B
  LD L,A
  JR C,EditorLeftEdge
  CP $03
  RET NC
EditorLeftEdge:
  LD L,$03
  RET

; Cursor x + speed, not over 252
;
; m1 30 calls (6720-6749).
EditorCursorRight:
  LD A,L
  ADD A,B
  LD L,A
  JR C,EditorRightEdge
  CP $FC
  RET C
EditorRightEdge:
  LD L,$FC
  RET

; Cursor y - speed, not under 18 (the buttons' line is reachable, the cushion
; is at 51)
;
; m1 30 calls (6680-6709).
EditorCursorUp:
  LD A,H
  SUB B
  LD H,A
  CP $12
  RET NC
  LD H,$12
  RET

; Cursor y + speed, not over 180
;
; m1 30 calls (6640-6669).
EditorCursorDown:
  LD A,H
  ADD A,B
  LD H,A
  CP $B4
  RET C
  LD H,$B4
  RET

; XOR a rectangle's outline: E, D = left, top; L, H = right, bottom
;
; Four span calls ($93B3). EditorStart draws the button frames with it: play x
; 148-187, lines 20-35; reset x 204-251. m1 2 calls (6270).
EditorBox:
  PUSH DE
  PUSH HL
  LD A,L
  SUB E
  DEC A
  LD B,A
  INC E
  CALL XorLine
  POP HL
  POP DE
  PUSH DE
  PUSH HL
  INC E
  LD D,H
  CALL XorLine
  POP HL
  POP DE
  PUSH DE
  PUSH HL
  LD A,H
  SUB D
  DEC A
  LD C,A
  INC D
  LD B,$01
  PUSH BC
EditorBoxLeft:
  CALL XorLine
  INC D
  DEC C
  JR NZ,EditorBoxLeft
  POP BC
  POP HL
  POP DE
  INC D
  LD E,L
EditorBoxRight:
  CALL XorLine
  INC D
  DEC C
  JR NZ,EditorBoxRight
  RET

; Z if the cursor is strictly inside the box E, D - L, H (E < x < L, D < y < H)
;
; The cursor: x $86BA, y $86BB. Play box: x 149-186, y 21-34; reset box: x
; 205-250, y 21-34. m1 220 calls (two per fire pass), never inside.
EditorInBox:
  LD BC,(CursorX)
  LD A,C
  INC E
  CP E
  JR C,EditorOutsideBox
  CP L
  JR NC,EditorOutsideBox
  LD A,B
  INC D
  CP D
  JR C,EditorOutsideBox
  CP H
  JR NC,EditorOutsideBox
  XOR A
  RET
EditorOutsideBox:
  LD A,$FF
  OR A
  RET

; Fire: "play" or "reset" when the cursor is on them, else pick up the ball
; under the cursor and move it
;
; Play box (EditorPlay $C41D), reset box (EditorReset $C532), else the first
; ball record in order cue, 1-6 (data at $8A88, 14 bytes each) with |x - cursor
; x| < 5 and |y - cursor y| < 5 on the whole-pixel bytes +1 / +3, on the table
; or not (a potted ball sits at y 27, x 7 + 24 n: in the cursor's reach). No
; ball: back to the loop.
;
; EditorPickBall: EditorPickedBall $C58F = the ball, a beep (BEEPER 1000, 20),
; the cursor erased. A ball off the table is erased from the potted row, put at
; (128, 115) and shifted sideways (129, 126, 131, 124 ...) while a ball on the
; table is closer than 16 pixels in x and in y, then flagged on the table (+13
; = $80) and drawn. EditorWaitRelease $C401 waits for fire to go up.
;
; EditorBallLoop (one HALT a pass): fire puts the ball down (EditorDropBall: a
; beep, the cursor at the ball, wait for fire up, back to the cursor loop); a
; direction sets the ball's velocity high bytes (+5 x, +7 y) to +/- the speed
; in EditorBallSpeed $C58E (the same acceleration as the cursor), fractions and
; the other velocity zero, and runs one physics step $8701 for it (B holds the
; speed there, not the ball counter of the physics loop), clears $9F50, keeps
; the cue ball out of the potted path (+13 bit 5 cleared), moves the cursor
; with it and redraws it ($8297). When the step took the ball off the table
; (potted): a beep and back to the cursor loop.
;
; Witness: m1 110 calls (6420-6769), every one without a ball in reach. e1
; (stage 2, the editor recording): 2 calls (frames 700 and 840); at 700
; EditorPickBall picks ball 1 of the rack (EditorFindBall twice: the cue ball,
; then ball 1), EditorHoldBall $C2F4 entered at 702, EditorBallLoop 57 passes,
; EditorBallMove 20 (frames 720-739), EditorDropBall once; at 840 the play box.
; The off-table placement EditorPlaceBall $C288 and EditorOverlapLoop ran in no
; build (known only from the code).
EditorFire:
  LD D,$14
  LD E,$94
  LD H,$23
  LD L,$BB
  CALL EditorInBox
  JP Z,EditorPlay
  LD D,$14
  LD E,$CC
  LD H,$23
  LD L,$FB
  CALL EditorInBox
  JP Z,EditorReset
  LD IX,BallRecords
  LD DE,$000E
  LD B,$00
  LD HL,(CursorX)
EditorFindBall:
  LD A,(IX+$01)
  SUB L
  JR NC,EditorBallDx
  NEG
EditorBallDx:
  CP $05
  JR NC,EditorNextBall
  LD A,(IX+$03)
  SUB H
  JR NC,EditorBallDy
  NEG
EditorBallDy:
  CP $05
  JR NC,EditorNextBall
  JR EditorPickBall
EditorNextBall:
  ADD IX,DE
  INC B
  LD A,B
  CP $07
  JR NZ,EditorFindBall
  JP EditorLoop
EditorPickBall:
  LD A,B                  ; e1 once, frame 700 (ball 1)
  LD (EditorPickedBall),A
  PUSH IX
  LD HL,$03E8
  LD DE,$0014
  CALL BEEPER
  POP IX
  CALL DrawCursor
  BIT 7,(IX+$0D)
  JP NZ,EditorHoldBall
  PUSH IX
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  LD (SpritePos),HL
  LD A,(EditorPickedBall)
  CALL DrawBall
  LD L,$80
  LD H,$73
EditorPlaceBall:
  POP IX                  ; an off-table ball: at (128, 115), shifted while it
                          ; overlaps
  PUSH IX
  LD A,L
  LD (IX+$01),A
  LD (IX+$00),$00
  SUB $07
  LD (IX+$0A),A
  LD A,H
  LD (IX+$03),A
  LD (IX+$02),$00
  SUB $07
  LD (IX+$0B),A
  LD IX,BallRecords
  LD DE,$000E
  LD B,$07
EditorOverlapLoop:
  BIT 7,(IX+$0D)
  JR Z,EditorOverlapNext
  LD A,(IX+$01)
  SUB L
  JR NC,EditorOverlapDx
  NEG
EditorOverlapDx:
  CP $10
  JR NC,EditorOverlapNext
  LD A,(IX+$03)
  SUB H
  JR NC,EditorOverlapDy
  NEG
EditorOverlapDy:
  CP $10
  JR NC,EditorOverlapNext
  LD A,$80
  SUB L
  JR NC,EditorShiftRight
  DEC A
  JR EditorShiftApply
EditorShiftRight:
  INC A
EditorShiftApply:
  ADD A,$80
  LD L,A
  JR EditorPlaceBall
EditorOverlapNext:
  ADD IX,DE
  DJNZ EditorOverlapLoop
  POP IX
  LD (IX+$0D),$80
  LD L,(IX+$0A)
  LD H,(IX+$0B)
  LD (SpritePos),HL
  LD A,(EditorPickedBall)
  CALL DrawBall
EditorHoldBall:
  CALL EditorWaitRelease  ; wait for fire up, then move the ball
  LD A,$00
  LD (CursorLastInput),A
EditorBallSpeedReset:
  LD A,$F1
  LD (EditorBallSpeed),A
EditorBallLoop:
  HALT                    ; one HALT a pass
  CALL ReadInput
  LD A,(CursorLastInput)
  LD B,A
  LD A,(InputState)
  LD (CursorLastInput),A
  CP B
  JR Z,EditorBallKeys
  LD A,$F1
  LD (EditorBallSpeed),A
EditorBallKeys:
  LD A,(InputState)
  CP $00
  JR Z,EditorBallSpeedReset
  AND $20
  JP NZ,EditorExit
  LD A,(InputState)
  AND $10
  JP NZ,EditorDropBall
  LD A,(EditorBallSpeed)
  SUB $10
  LD (EditorBallSpeed),A
  JR NC,EditorBallMove
  AND $0F
  CP $05
  JR NC,EditorBallSpeedUp
  INC A
EditorBallSpeedUp:
  ADD A,$F0
  LD (EditorBallSpeed),A
EditorBallMove:
  LD A,(EditorBallSpeed)
  AND $0F
  LD B,A
  XOR A
  LD (IX+$05),A
  LD (IX+$04),A
  LD (IX+$07),A
  LD (IX+$06),A
  LD (IX+$00),A
  LD (IX+$02),A
  LD L,(IX+$01)
  LD H,(IX+$03)
  PUSH HL
  LD A,(InputState)
  AND $02
  CALL NZ,EditorBallLeft
  LD A,(InputState)
  AND $01
  CALL NZ,EditorBallRight
  LD A,(InputState)
  AND $04
  CALL NZ,EditorBallUp
  LD A,(InputState)
  AND $08
  CALL NZ,EditorBallDown
  PUSH IX
  CALL MoveBall
  POP IX
  XOR A
  LD (MessageStep),A
  LD A,(EditorPickedBall)
  OR A
  JR NZ,EditorBallRedraw
  RES 5,(IX+$0D)
EditorBallRedraw:
  LD L,(IX+$01)
  LD H,(IX+$03)
  LD (CursorX),HL
  SET 4,(IX+$0D)
  PUSH IX
  CALL RedrawBall
  POP IX
  POP DE
  BIT 7,(IX+$0D)
  JR NZ,EditorBallMoved
  LD HL,$03E8
  LD DE,$0014
  CALL BEEPER
  JP EditorCursorShow
EditorBallMoved:
  LD L,(IX+$01)
  LD H,(IX+$03)
  OR A
  SBC HL,DE
  JP Z,EditorBallSpeedReset
  JP EditorBallLoop
EditorDropBall:
  PUSH IX                 ; fire: put the ball down
  LD HL,$03E8
  LD DE,$0014
  CALL BEEPER
  POP IX
  LD L,(IX+$01)
  LD H,(IX+$03)
  LD (CursorX),HL
  CALL DrawCursor
  CALL EditorWaitRelease
  JP EditorSpeedReset

; Ball x velocity -speed (+5)
;
; e1: 20 runs, frames 720-739 (key 5 held 20 frames: ball 1 from x 190 to 170).
EditorBallLeft:
  LD A,B
  NEG
  LD (IX+$05),A
  RET

; Ball x velocity +speed
;
; No build runs it (known only from the code, the twin of EditorBallLeft).
EditorBallRight:
  LD (IX+$05),B
  RET

; Ball y velocity -speed (+7)
;
; No build runs it (known only from the code).
EditorBallUp:
  LD A,B
  NEG
  LD (IX+$07),A
  RET

; Ball y velocity +speed
;
; No build runs it (known only from the code).
EditorBallDown:
  LD (IX+$07),B
  RET

; Wait until fire is up (ReadInput in a loop); BREAK leaves the editor
;
; BREAK (bit 5 of InputState $827C) drops the return and goes to EditorExit
; $C414. e1: 3 entries (frames 702-844), 60 passes; its BREAK exit ran in no
; build.
EditorWaitRelease:
  CALL ReadInput
  LD A,(InputState)
  AND $20
  JR NZ,EditorBreakOut
  LD A,(InputState)
  AND $10
  JR NZ,EditorWaitRelease
  RET
EditorBreakOut:
  POP HL

; Leave the editor: the saved input mode back, restart at the menu ($80B0)
;
; $B8BD = EditorSavedMode $C590, JP $80B0 (BreakRestart). m1 once, frame 6830
; (CAPS SHIFT + SPACE).
EditorExit:
  LD A,(EditorSavedMode)
  LD (Control),A
  JP BreakRestart

; "play": blank the editor's texts, restore the input mode, start the aim on
; the edited table
;
; A beep, DI, the cursor erased, "- editor -" blanked (EditorTitleBlank $C56D),
; rows 2-4 columns 18-31 blanked, wait for fire up; $B8BD = EditorSavedMode;
; $9395, the power word $86BF = 0, EditorAimReset $C502, $8539; installs
; EditorAimTasks $C518, SoundRequest $827D = 0, EI and JP $8069 (the foreground
; sound loop): the editor's game runs on tasks from here. e1: once, frame 840
; (the screen at 878: texts gone, power box, cursor at (252, 115)).
EditorPlay:
  LD HL,$03E8
  LD DE,$0014
  CALL BEEPER
  DI
  CALL DrawCursor
  LD HL,EditorTitleBlank
  CALL PrintText
  LD HL,EditorButtonsBlank
  LD (HL),$02
  CALL PrintText
  LD HL,EditorButtonsBlank
  LD (HL),$03
  CALL PrintText
  LD HL,EditorButtonsBlank
  LD (HL),$04
  CALL PrintText
  CALL EditorWaitRelease
  LD A,(EditorSavedMode)
  LD (Control),A
  CALL DrawPowerBox
  LD HL,$0000
  LD (Power),HL
  CALL EditorAimReset
  CALL AimPowerReset
  LD DE,EditorAimTasks
  CALL InstallTasks
  XOR A
  LD (SoundRequest),A
  EI
  JP SoundLoop

; Task of the rolling list: all object balls down = back to the menu; all balls
; stopped = aim again
;
; With no object ball on the table: ClearTasks $91CF, then up to 150 frames
; (HALT, ReadInput) until fire or any key, then $80B0 (the menu). Otherwise,
; when no ball moves (+13 AND $70 zero for all seven): removes EditorRollTasks
; $C528, respots the cue ball when it is off the table ($93FF), EditorAimReset
; $C502, $8539, installs EditorAimTasks $C518. e1: 140 runs, frames 915-1054;
; the balls stopped at 1054 and the aim came back (EditorAimReset's second
; entry); the all-potted way to the menu (EditorShotEndWait $C488) ran in no
; build (known only from the code; its address is in EditorRollTasks).
EditorShotEnd:
  LD IX,BallRecords
  LD DE,$000E
  ADD IX,DE
  LD B,$06
EditorShotEndBalls:
  BIT 7,(IX+$0D)          ; any of balls 1-6 on the table?
  JR NZ,EditorShotEndMoving
  ADD IX,DE
  DJNZ EditorShotEndBalls
  CALL ClearTasks
  LD B,$96
EditorShotEndWait:
  HALT                    ; 150 frames, fire or a key: the menu
  PUSH BC
  CALL ReadInput
  LD A,(InputState)
  AND $10
  JP NZ,BreakRestart
  CALL KEY_SCAN
  JP NZ,BreakRestart
  CALL K_TEST
  CP $FF
  JP NZ,BreakRestart
  POP BC
  DJNZ EditorShotEndWait
  JP BreakRestart
EditorShotEndMoving:
  LD IX,BallRecords
  LD B,$07
EditorShotEndMovingLoop:
  LD A,(IX+$0D)           ; +13 AND $70: still moving
  AND $70
  RET NZ
  ADD IX,DE
  DJNZ EditorShotEndMovingLoop
  LD DE,EditorRollTasks
  CALL RemoveTasks
  LD IX,BallRecords
  BIT 7,(IX+$0D)
  CALL Z,RespotCueBall
  CALL EditorAimReset
  CALL AimPowerReset
  LD DE,EditorAimTasks
  JP InstallTasks

; Task of the aim list: fire held grows the power by 2 (wrap at $86); released
; with power: shoot
;
; Power $86BF + 2 per frame while fire is held, back to 0 at $86 (as AimPower
; $8506). Released with power not 0: the cursor erased, EditorAimTasks removed,
; $84C7, the aim $8A02 (the shot's velocity), EditorRollTasks installed. e1:
; 378 runs, frames 845-1367 (the shot released at 908, a second aim from 1054).
EditorPower:
  LD A,(InputState)
  AND $10
  LD A,(Power)
  JR Z,EditorPowerRelease
  ADD A,$02
  CP $86
  JR C,EditorPowerStore
  XOR A
EditorPowerStore:
  LD (Power),A
  RET
EditorPowerRelease:
  OR A                    ; fire up: shoot if there is power
  RET Z
  CALL DrawCursor
  LD DE,EditorAimTasks
  CALL RemoveTasks
  CALL ShotReset
  CALL AimShot
  LD DE,EditorRollTasks
  JP InstallTasks

; Input state 0, the cursor at (252, 115) and drawn
;
; $827C and $86BE = 0, CursorX/Y $86BA = (252, 115), $86BC = 0, JP $9371. e1: 2
; entries, frames 844 and 1054.
EditorAimReset:
  LD A,$00
  LD (InputState),A
  LD (CursorLastInput),A
  LD H,$73
  LD L,$FC
  LD (CursorX),HL
  XOR A
  LD (CursorSpeed),A
  JP DrawCursor

; The editor's aim task list (period, address): EditorPower, $934D, $8546,
; $85EB, ReadInput, $FF
;
; Installed by EditorPlay $C41D and EditorShotEnd $C46E, removed by EditorPower
; $C4D6. All periods 0. Read in e1 (each byte 3 times, frames 844-1054).
EditorAimTasks:
  DEFB $00,$D6,$C4
  DEFB $00,$4D,$93
  DEFB $00,$46,$85
  DEFB $00,$EB,$85
  DEFB $00,$06,$81
  DEFB $FF                ; end
EditorRollTasks:
  DEFB $00,$7E,$82        ; the rolling list: $827E (ball redraw), $86C1
  DEFB $00,$C1,$86        ; (physics), EditorShotEnd, $FF
  DEFB $00,$6E,$C4
  DEFB $FF                ; end

; "reset": rack the balls (the start positions $9D5D) and put the cursor home
;
; A beep, the cursor erased, HALT, the balls erased ($9520), racked ($9D2C),
; drawn ($9520), wait for fire up, JP EditorCursorHome $C102. No build runs it
; (known only from the code: e1 hit play, not reset).
EditorReset:
  LD HL,$03E8
  LD DE,$0014
  CALL BEEPER
  CALL DrawCursor
  HALT
  CALL DrawAllBalls
  CALL ResetBallPositions
  CALL DrawAllBalls
  CALL EditorWaitRelease
  JP EditorCursorHome

; The editor's texts for $9E65 (row, column, attribute, length, characters)
;
; "- editor -" (row 0, column 11), "play" (row 3, column 19, attribute $39),
; "reset" (row 3, column 26), then two blanks: 10 spaces over the title and 14
; spaces at column 18 whose row byte EditorStart / EditorPlay patch to 2, 3, 4
; (and 5). The first three read once in m1 (6262); EditorButtonsBlank 4 times;
; EditorTitleBlank once, in e1 (EditorPlay, frame 840).
EditorTexts:
  INCBIN "res/text/EditorTexts.bin",$0000,14
EditorPlayText:
  INCBIN "res/text/EditorTexts.bin",$000E,8
EditorResetText:
  INCBIN "res/text/EditorTexts.bin",$0016,9
EditorTitleBlank:
  INCBIN "res/text/EditorTexts.bin",$001F,14
EditorButtonsBlank:
  INCBIN "res/text/EditorTexts.bin",$002D,18

; The cursor's step counter: high nibble frames left, low nibble the speed
; (1-5), $F1 at a start
;
; Read and written by EditorStart's loop (m1 240 reads).
EditorCursorSpeed:
  DEFB $00
EditorBallSpeed:
  DEFB $00                ; the same for the moved ball (never used in a
                          ; recording)
EditorPickedBall:
  DEFB $00                ; the picked ball, 0 cue .. 6
EditorSavedMode:
  DEFB $00                ; the input mode $B8BD at entry (m1: written at 6262,
                          ; read at 6830)

; 111 bytes equal to $C34C-$C3BA (inside EditorBallMove): a stale copy, never
; read
;
; Byte for byte the code from the middle of LD (IX+4),A at $C34A ($C34C) to the
; opcode of the JP at $C3BA: the copy is cut by the block's end at $C600 before
; the JP's operand. A leftover of an earlier assembly in which this code sat
; higher. No build reads it (l1sum.py --reads C591-C5FF).
EditorStaleCopy:
  DEFB $77,$04,$DD,$77,$07,$DD,$77,$06,$DD,$77,$00,$DD,$77,$02,$DD,$6E
  DEFB $01,$DD,$66,$03,$E5,$3A,$7C,$82,$E6,$02,$C4,$EB,$C3,$3A,$7C,$82
  DEFB $E6,$01,$C4,$F2,$C3,$3A,$7C,$82,$E6,$04,$C4,$F6,$C3,$3A,$7C,$82
  DEFB $E6,$08,$C4,$FD,$C3,$DD,$E5,$CD,$01,$87,$DD,$E1,$AF,$32,$50,$9F
  DEFB $3A,$8F,$C5,$B7,$20,$04,$DD,$CB,$0D,$AE,$DD,$6E,$01,$DD,$66,$03
  DEFB $22,$BA,$86,$DD,$CB,$0D,$E6,$DD,$E5,$CD,$97,$82,$DD,$E1,$D1,$DD
  DEFB $CB,$0D,$7E,$20,$0C,$21,$E8,$03,$11,$14,$00,$CD,$B5,$03,$C3
