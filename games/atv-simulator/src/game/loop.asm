; --------------------------------------------------------------------------------------------------------------------
; loop.asm: The entry's jumps, the game's variables, the main loop with its 7-frame wait, the interrupt
;
; GameEntry ($D7D6) copies the tune player and trail 6 out of the buffers' way, sets up IM 2 (I = $FE, a table of $80
; bytes, the vector $8080 = JP Interrupt) and runs the outer loop: Title, NewGame, CheckHiScore. NewGame clears the
; scores and runs the trails: Pass ($D851) is one pass of the game for both players, then it waits until the interrupt
; has counted FrameCount up to 7, so a pass is always 7 frames (7.14 passes a second) when its work fits. Interrupt
; ($D9D2) counts the frames in play and plays the engines' tones; in the front end (FrameCount $FF) it reads the
; controls.
; --------------------------------------------------------------------------------------------------------------------

  ORG $D6B0

; JP GameEntry; JP Restart
;
; The loader enters at $D6B0 (c1 frame 14 100); ItemTooLow jumps to Restart at
; $D6B3.
;
; Witness: L1 1 (c1).
EntryJumps:
  JP GameEntry
; This entry point is used by the routine at PlaceItem.
RestartJump:
  JP Restart

; The game's variables
LoopVars:
TrailListA:
  DEFB $00,$00            ; the trail's list A (SelectTrail)
TrailListB:
  DEFB $00,$00            ; the trail's list B
SavedSp0:
  DEFB $00,$00            ; SP at the entry
FrameCount:
  DEFB $00,$00            ; frames counted by Interrupt since the pass began;
                          ; $FF in the front end (the interrupt reads the
                          ; controls instead)
Riding:
  DEFB $00                ; the players still in: bit 0 player 1, bit 1 player
                          ; 2
Trail:
  DEFB $00                ; the trail, 0-5
FinishDistance:
  DEFB $00,$00            ; the trail's length - $48: a player whose distance
                          ; reaches it has finished
HudY:
  DEFB $00                ; the half's HUD line ($BE top, 6 bottom)
PassControls:
  DEFB $00                ; the current player's controls this pass
GroundY:
  DEFB $00,$00,$00,$00,$00 ; the ground under the ATV's wheels (GroundUnder):
                           ; the higher of $D6C5 (rear) and $D6C6 (front);
                           ; $D6C7 under the nose, $D6C8 the nose's line
Clock:
  DEFB $30                ; the clock: three ASCII digits; the last one counts
                          ; passes (ClockTick), not seconds
ClockTens:
  DEFB $30
ClockUnits:
  DEFB $30
MaxTime:
  DEFB $37,$30,$30        ; the trail's maximum: the clock's first two digits
                          ; at TIME OUT ("60" = 600 passes)
MaxTimes:
  DEFB $36,$30,$36,$30,$36,$30,$34,$30 ; each trail's maximum: "60", "60",
  DEFB $35,$30,$35,$30                 ; "60", "40", "50", "50"; "30" in the
                                       ; second round (ShowMaxTime)

; The game's jump table; the first entry JP TrailEnd
;
; The entries at $D6DE, $D6ED, $D6F0, $D6F3, $D6FC, $D702, $D705 and $D708 are
; called by no one (known only from the code; $D702 is JP $0000).
;
; Known only from the code: no recording runs it.
GameTable:
  JP TrailEnd

; JP NewGame
;
; Known only from the code: no recording runs it.
JpNewGame:
  JP NewGame

; JP LoadRecordP1
;
; Witness: L1 16 (c1, empty, fuel, kb, trail1, trails, warp).
JpLoadRecordP1:
  JP LoadRecordP1

; JP LoadRecordP2
;
; Witness: L1 2 (kb).
JpLoadRecordP2:
  JP LoadRecordP2

; JP SaveRecordP1
;
; Witness: L1 16 (c1, empty, fuel, kb, trail1, trails, warp).
JpSaveRecordP1:
  JP SaveRecordP1

; JP SaveRecordP2
;
; Witness: L1 2 (kb).
JpSaveRecordP2:
  JP SaveRecordP2

; JP Stop
;
; Known only from the code: no recording runs it.
JpStop:
  JP Stop

; JP Accelerate
;
; Known only from the code: no recording runs it.
JpAccelerate:
  JP Accelerate

; JP SlowDown
;
; Known only from the code: no recording runs it.
JpSlowDown:
  JP SlowDown

; JP ShowMaxTime
;
; Witness: L1 16 (c1, empty, fuel, kb, trail1, trails, warp).
JpShowMaxTime:
  JP ShowMaxTime

; JP ShowClock
;
; Witness: L1 16 (c1, empty, fuel, kb, trail1, trails, warp).
JpShowClock:
  JP ShowClock

; JP ClockTick
;
; Known only from the code: no recording runs it.
JpClockTick:
  JP ClockTick

; JP ShowBars
;
; Witness: L1 18 (c1, empty, fuel, kb, trail1, trails, warp).
JpShowBars:
  JP ShowBars

; JP $0000
;
; Known only from the code: no recording runs it.
JpNothing:
  JP $0000

; JP Players
;
; Known only from the code: no recording runs it.
JpPlayers:
  JP Players

; JP PrintShadow
;
; Known only from the code: no recording runs it.
JpPrintShadow:
  JP PrintShadow

; JP SetupIm2
;
; Witness: L1 10 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpSetupIm2:
  JP SetupIm2

  ORG $D80D

; A game: trail 1, scores "00000", the riding mask from Players; each trail:
; select, intro, panels, then Pass until the finish or TIME OUT
;
; Trail = 0, SecondRound = 0, Riding = 1 or 3 (PlayerCount); LoadIntro; then
; for each trail SelectTrail, FrameCount = $FF, InitListWidths, InitRecords,
; TrailIntro, ShowHud, ClearKeys, EI, and the passes. TrailEnd jumps back to
; NextTrail ($D82F).
;
; FrameCount = 0, ReadP1Controls, ReadP2Controls, ClearKeys, ClockTick,
; Players; then the wait loop on FrameCount (c1: 30 269 229 runs of $D86B over
; 5081 passes). Both players' Finished bits set (as Riding) end the trail
; (TrailEnd); the clock's first digit equal to MaxTime's: TIME OUT for both
; (TimeOut), then TrailEnd when someone finished, else 250 frames and the game
; ends.
;
; Witness: L1 7 (c1, empty, fuel, kb, trail1, trails, warp).
NewGame:
  XOR A
  LD (Trail),A
  XOR A
  LD (SecondRound),A
  LD HL,Scores
  LD DE,Scores+$0001
  LD BC,$0009
  LD (HL),$30
  LDIR
  LD A,(PlayerCount)
  SLA A
  OR $01
  LD (Riding),A
  CALL JpLoadIntro
; This entry point is used by the routine at TrailEnd.
NextTrail:
  LD HL,Attributes
  LD (AttrBase),HL
  XOR A
  LD (Finished),A
  CALL SelectTrail
  LD A,$FF
  LD (FrameCount),A
  CALL JpInitListWidths
  CALL InitRecords
  CALL JpTrailIntro
  CALL JpShowHud
  CALL JpClearKeys
  EI
; This entry point is used by the routine at RecordFieldP2.
Pass:
  XOR A                   ; One pass: the controls, the clock, both players'
                          ; updates, then wait for 7 frames; the finish and
                          ; TIME OUT
  LD (FrameCount),A
  XOR A
  LD (Controls1),A
  LD (Controls2),A
  CALL ReadP1Controls
  CALL ReadP2Controls
  CALL JpClearKeys
  CALL ClockTick
  CALL Players
WaitFrames:
  LD A,(FrameCount)
  CP $07
  JR C,WaitFrames
  CALL RecordFieldP1
  JR NZ,l_D89E
  CALL RecordFieldP2
  JR NZ,l_D89E
  LD A,(Riding)
  LD E,A
  LD A,(Finished)
  AND E
  CP E
  JP Z,TrailEnd
  JR l_D89E

; A = RecordP1's field +9 (speed), Z when 0
;
; Witness: L1 5351 (c1, empty, fuel, kb, trail1, trails, warp).
RecordFieldP1:
  LD IX,RecordP1
  JR l_D894

; A = RecordP2's field +9
;
; Witness: L1 3592 (c1, empty, fuel, kb, trail1, trails, warp).
RecordFieldP2:
  LD IX,RecordP2
; This entry point is used by the routine at RecordFieldP1.
l_D894:
  LD DE,$0009
  CALL RecordField
  LD A,(HL)
  CP $00
  RET
; This entry point is used by the routine at NewGame.
l_D89E:
  LD A,(Clock)
  LD E,A
  LD A,(MaxTime)
  CP E
  JR NZ,Pass
  CALL RecordFieldP1
  LD (HL),$00
  CALL RecordFieldP2
  LD (HL),$00
  CALL TimeOut
  LD A,(Finished)
  AND $03
  JP NZ,TrailEnd
  LD B,$FA
l_D8BF:
  HALT
  DJNZ l_D8BF
  RET

; Controls off (player 2 on the keyboard... SinclairOn = 1), DetectKempston,
; the row tables, the text widths, FrameCount = $FF
;
; Witness: L1 1 (c1).
Init:
  XOR A
  LD (KempstonOn),A
  LD (Keyboard1Alt),A
  LD A,$01
  LD (SinclairOn),A
  CALL JpDetectKempston
  CALL JpClearKeys
  CALL JpBuildRowAddrs
  CALL JpBuildBufferRows
  CALL JpInitTextWidths
  LD HL,Screen
  LD (ScreenBase),HL
  LD A,$FF
  LD (FrameCount),A
  LD (Finished),A
  RET

; IM 2: I = $FE, the table $FE00-$FF00 all $80, JP Interrupt at $8080
;
; Witness: L1 20 (c1, empty, fuel, kb, menu, trail1, trails, warp).
SetupIm2:
  DI
  XOR A
  LD (BeeperByte),A
  LD A,$FE
  LD I,A
  IM 2
  LD A,$C3
  LD (Im2Jump),A
  LD HL,Interrupt
  LD (RenderVars+$0001),HL
  LD HL,Im2Table
  LD DE,Im2Table+$0001
  LD (HL),$80
  LD BC,$0100
  LDIR
  RET

; Controls1 = player 1's five tests as bits (4 left, 3 right, 2 up, 1 down, 0
; jump)
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
ReadP1Controls:
  LD IX,Controls1
  CALL JpP1Left
  JR NC,l_D91E
  SET 4,(IX+$00)
l_D91E:
  CALL JpP1Right
  JR NC,l_D927
  SET 3,(IX+$00)
l_D927:
  CALL JpP1Up
  JR NC,l_D930
  SET 2,(IX+$00)
l_D930:
  CALL JpP1Down
  JR NC,l_D939
  SET 1,(IX+$00)
l_D939:
  CALL JpP1Jump
  RET NC
  SET 0,(IX+$00)
  RET

; Controls2 from player 2's tests
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
ReadP2Controls:
  LD IX,Controls2
  CALL JpP2Left
  JP NC,l_D950
  SET 4,(IX+$00)
l_D950:
  CALL JpP2Right
  JR NC,l_D959
  SET 3,(IX+$00)
l_D959:
  CALL JpP2Up
  JR NC,l_D962
  SET 2,(IX+$00)
l_D962:
  CALL JpP2Down
  JR NC,l_D96B
  SET 1,(IX+$00)
l_D96B:
  CALL JpP2Jump
  RET NC
  SET 0,(IX+$00)
  RET

; A = (IX + DE), Z when 0
;
; Witness: L1 123050 (c1, empty, fuel, kb, trail1, trails, warp).
RecordField:
  PUSH IX
  POP HL
  ADD HL,DE
  LD A,(HL)
  CP $00
  RET

; Both players' engine tones (from Interrupt each frame in play)
;
; For each record with the rider mounted (+2) and a speed (+9): three bursts of
; a square wave whose half-period is $1E - speed + 1 (Tone): the pitch rises
; with the speed.
;
; Witness: L1 47176 (c1, empty, fuel, kb, trail1, trails, warp).
EngineSound:
  LD IX,RecordP1
  CALL EngineOne
  LD IX,RecordP2

; One record's engine tone
;
; Witness: L1 94352 (c1, empty, fuel, kb, trail1, trails, warp).
EngineOne:
  LD DE,$0002
  CALL RecordField
  RET Z
  LD DE,$0009
  CALL RecordField
  RET Z
  SUB $01
  LD E,A
  LD A,$1E
  SUB E
  LD C,A
  LD B,$03

; B bursts of a tone: Click, a delay of C x 3 loops
;
; Witness: L1 159723 (c1, empty, fuel, kb, trail1, trails, warp).
Tone:
  PUSH BC
  CALL Click
l_D9A2:
  LD B,$03
l_D9A4:
  DJNZ l_D9A4
  DEC C
  JR NZ,l_D9A2
  POP BC
  DJNZ Tone
  JP SpeakerOff

; C clicks with random delays (Random): the thump of a landing
;
; Witness: L1 1530 (c1, empty, fuel, kb, trail1, trails, warp).
Noise:
  CALL Click
  CALL JpRandom
  AND $7F
  LD B,A
l_D9B8:
  DJNZ l_D9B8
  LD B,$1E
l_D9BC:
  DJNZ l_D9BC
  DEC C
  JR NZ,Noise
; This entry point is used by the routine at Tone.
SpeakerOff:
  XOR A                   ; port $FE = 0, A = $FF
  OUT ($FE),A
  SUB $01
  RET

; Toggle the speaker bit in BeeperByte and send it
;
; Witness: L1 161253 (c1, empty, fuel, kb, trail1, trails, warp).
Click:
  LD A,(BeeperByte)
  XOR $10
  LD (BeeperByte),A
  OUT ($FE),A
  RET

; The IM 2 handler: in play count FrameCount and sound the engines; in the
; front end read both players' controls
;
; Saves every register. FrameCount < $FF: +1, ScanKeys, EngineSound. $FF:
; Controls1 = Controls2 = 0, ScanKeys, ReadP1Controls, ReadP2Controls. c1: 58
; 177 interrupts.
;
; Witness: L1 60445 (c1, empty, fuel, kb, menu, trail1, trails, warp).
Interrupt:
  DI
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  LD A,(FrameCount)
  CP $FF
  JR C,l_D9F4
  XOR A
  LD (Controls1),A
  LD (Controls2),A
  CALL JpScanKeys
  CALL ReadP1Controls
  CALL ReadP2Controls
  JR InterruptEnd
l_D9F4:
  ADD A,$01
  LD (FrameCount),A
  CALL JpScanKeys
  CALL EngineSound
  JR InterruptEnd

; Restart the game when key 0 (KeyStates+15) is down: FrameCount = $FF, SP =
; $FFDA, JP NewGame
;
; No jump reaches it (the handler's two paths jump over it to $DA14): a debug
; or abort key left in. Known only from the code.
AbortKey:
  LD A,(KeyStates+$000F)
  CP $00
  JR Z,InterruptEnd
  LD A,$FF
  LD (FrameCount),A
  LD SP,StackRestart
  EI
  JP NewGame
; This entry point is used by the routine at Interrupt.
InterruptEnd:
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EI
  RET

  ORG $EC7F

; Each riding player's pass: PassP1, PassP2
;
; Witness: L1 5349 (c1, empty, fuel, kb, trail1, trails, warp).
Players:
  XOR A
  LD (SeenCount),A
  LD (PlayerIndex),A
  LD A,(Riding)
  AND $01
  CALL NZ,PassP1
  LD A,$01
  LD (PlayerIndex),A
  LD A,(Riding)
  AND $02
  CALL NZ,PassP2
  RET

; TrailListA, TrailListB and FinishDistance from the trail's record
; (TrailRecords, Trail5, Trail6)
;
; Witness: L1 16 (c1, empty, fuel, kb, trail1, trails, warp).
SelectTrail:
  LD IX,Trail5
  LD A,(Trail)
  CP $04
  JP Z,l_ECBE
  LD IX,Trail6
  CP $05
  JP Z,l_ECBE
  LD IX,TrailRecords
  LD E,A
  LD A,$06
  CALL JpMultiply
  EX DE,HL
  ADD IX,DE
l_ECBE:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (TrailListA),HL
  LD L,(IX+$02)
  LD H,(IX+$03)
  LD (TrailListB),HL
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD DE,$0048
  XOR A
  SBC HL,DE
  LD (FinishDistance),HL
  RET

; The trail's end: the finish tune, the bonus counted into the scores, the next
; trail; after trail 6 the second round
;
; Riding = Finished; the tune player back from $5B00; TunePlay tune 1 with no
; hook (no key stops it); SetupIm2; 50 frames; the finished halves' colour
; bands; CountBonus; 100 frames; Trail + 1, NextTrail. After trail 6,
; SecondRound = 1 and Trail = 0 (trails: 9 trail ends).
;
; Witness: L1 9 (kb, trails, warp).
TrailEnd:
  LD A,(Finished)
  LD (Riding),A
  LD HL,TunePlayerCopy
  LD DE,TunePlay0
  LD BC,$05AB
  LDIR
  LD HL,$0000
  LD (TuneHook),HL
  LD (TuneHook+$0001),HL
  LD IY,$0200
  LD A,$01
  CALL TunePlay
  CALL SetupIm2
  EI
  LD A,$CD
  LD (TuneHook),A
  LD HL,TuneKeyCheck
  LD (TuneHook+$0001),HL
  LD B,$32
l_ED14:
  HALT
  DJNZ l_ED14
  LD HL,Attributes
  LD (AttrBase),HL
  LD A,(Finished)
  AND $01
  LD A,$18
  CALL NZ,BandP1
  LD A,(Finished)
  AND $02
  LD A,$18
  CALL NZ,BandP2
  CALL CountBonus
  LD B,$64
l_ED36:
  HALT
  DJNZ l_ED36
  LD A,(Trail)
  ADD A,$01
  LD (Trail),A
  CP $06
  JP C,NextTrail
  LD A,$01
  LD (SecondRound),A
  XOR A
  LD (Trail),A
  JP NextTrail

; Count each finished player's Bonus into the score, a point and a tone at a
; time
;
; Witness: L1 3611 (kb, trails, warp).
CountBonus:
  LD B,$00
l_ED54:
  DJNZ l_ED54
  CALL BonusP1
  CALL BonusP2
  RET
BonusTone:
  CALL BonusP2
  LD C,$0F
  LD B,$1E
  CALL Tone
  JP CountBonus

; Player 1's next bonus point
;
; Witness: L1 3611 (kb, trails, warp).
BonusP1:
  LD A,(Finished)
  AND $01
  RET Z
  CALL LoadRecordP1
  CALL BonusDec
  RET Z
  CALL SaveRecordP1
  POP DE
  LD DE,BonusTone
  PUSH DE
  JP ScoreUpP1

; Player 2's
;
; Witness: L1 3611 (kb, trails, warp).
BonusP2:
  LD A,(Finished)
  AND $02
  RET Z
  CALL LoadRecordP2
  CALL BonusDec
  RET Z
  CALL SaveRecordP2
  POP DE
  LD DE,BonusTone+$0003
  PUSH DE
  JP ScoreUpP2

; Bonus - 1; Z when it was 0
;
; Witness: L1 3813 (kb, trails, warp).
BonusDec:
  LD BC,(Bonus)
  LD A,B
  OR C
  RET Z
  DEC BC
  LD (Bonus),BC
  RET

; Colour player 1's band
;
; Witness: L1 9 (kb, trails, warp).
BandP1:
  LD H,$08
  LD L,$B0
  LD BC,$160A
  JP JpFillAttrs

; Colour player 2's band
;
; Witness: L1 1 (kb).
BandP2:
  LD H,$08
  LD L,$50
  LD BC,$160A
  JP JpFillAttrs
