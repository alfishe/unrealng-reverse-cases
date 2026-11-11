; --------------------------------------------------------------------------------------------------------------------
; roomscripts.asm: The room handlers and scripted puzzles
; --------------------------------------------------------------------------------------------------------------------

  ORG $AF3B

; In status 0: enter the balloon; room $1D's barrel spot
;
; Room $1D: left held at Y $48 with X $1C-$1F: X = $1E, status 13 (BarrelSpot
; $AA3C). Else in the balloon's room $5C27 within 2 pixels of $5C25 / $5C26:
; status 7.
;
; Witness: L1 16719 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
StatusZeroTriggers:
  LD HL,Room
  LD A,(HL)
  CP $1D
  JR Z,BarrelSpotTest
  LD A,(BalloonInRoom)
  CP (HL)
  RET NZ
  LD A,(BalloonY)
  SUB (IX+$01)
  ADD A,$02
  CP $04
  RET NC
  LD A,(BalloonX)
  SUB (IX+$00)
  ADD A,$02
  CP $04
  RET NC
  LD A,$07
  LD (Status),A
  RET
BarrelSpotTest:
  BIT 1,E
  RET Z
  LD A,(IX+$01)
  CP $48
  RET NZ
  LD A,(IX+$00)
  CP $1C
  RET C
  CP $20
  RET NC
  LD A,$1E
  LD (IX+$00),A
  LD A,$0D
  LD (Status),A
  RET

; The lift: object 4 at X $24, Y $5B9F; up or down on it starts a ride
;
; Called by the main loop ($9028) when the room is the lift's ($5B9E). On the
; platform (Y = $5B9F - 8, X $12-$37) $5BA0 = 0; at X $1A-$2F, status 0, 19 or
; 20, down gives status 20, up 19. Object 4 frame $9F. Evidence: 1406 calls in
; 6 rzx segments.
;
; Witness: L1 1406 (rzx, rzx, rzx, rzx, rzx, rzx).
LiftPlatform:
  LD A,$24
  LD (ObjectSlot4),A
  LD A,(LiftY)
  LD (ObjectSlot4+1),A
  SUB $08
  CP (IX+$01)
  JR NZ,LiftDraw
  LD A,(IX+$00)
  CP $12
  JR C,LiftDraw
  CP $38
  JR NC,LiftDraw
  PUSH AF
  XOR A
  LD (NotOnLift),A
  POP AF
  CP $1A
  JR C,LiftDraw
  CP $30
  JR NC,LiftDraw
  LD A,(Status)
  OR A
  JR Z,LiftInput
  CP $13
  JR Z,LiftInput
  CP $14
  JR NZ,LiftDraw
LiftInput:
  CALL ReadControls
  BIT 2,E
  JR Z,LiftUpKey
  LD A,$14
  CALL SetStatus
  JR LiftDraw
LiftUpKey:
  BIT 3,E
  JR Z,LiftDraw
  LD A,$13
  CALL SetStatus
LiftDraw:
  LD A,$9F
  LD (ObjectSlot4+2),A
  RET

; The room handler of rooms 3 and $0F: draw the balloon
;
; In the balloon's room ($5C27), unless the hero is dying (status 18 or 26):
; object 4 (the basket) at $5C25 / $5C26, object 3 (the envelope) 16 pixels
; above. Frames: $99 empty, $24 with the hero (statuses 7-9, facing as the
; hero); the envelope $9A, hidden ($7F) in status 9. Evidence: rzx14000,
; rzx14500 (1017 passes).
;
; Witness: L1 1017 (rzx, rzx).
BalloonRoom:
  LD HL,Room
  LD A,(BalloonInRoom)
  CP (HL)
  RET NZ
  LD A,(Status)
  CP $12
  RET Z
  CP $1A
  RET Z
  LD A,(BalloonX)
  LD (ObjectSlot4),A
  LD (ObjectSlot3),A
  LD A,(BalloonY)
  LD (ObjectSlot4+1),A
  SUB $10
  LD (ObjectSlot3+1),A
  LD A,(Status)
  LD C,$99
  CP $07
  JR Z,BalloonWithHero
  CP $08
  JR Z,BalloonWithHero
  CP $09
  JR Z,BalloonWithHero
  JR BalloonEnvelope
BalloonWithHero:
  PUSH AF
  LD C,$24
  LD A,(Hero+3)
  LD (ObjectSlot4+3),A
  LD (ObjectSlot3+3),A
  POP AF
  CP $09
  JR Z,BalloonBurst
BalloonEnvelope:
  LD A,$9A
BalloonSetFrames:
  LD (ObjectSlot3+2),A
  LD A,C
  LD (ObjectSlot4+2),A
  RET
BalloonBurst:
  LD A,$7F
  JR BalloonSetFrames

; T held: status 10 (think)
;
; Port $FBFE is the half row Q W E R T; bit 4 is T (the instructions' Think).
; SK took it for ENTER. Not taken in any recording.
;
; Witness: L1 16037 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
ThinkKey:
  LD BC,$FBFE
  IN A,(C)
  AND $10
  RET NZ
  LD A,$0A
  JP SetStatus

; On a teleport pad: status 22
;
; TeleportPads $B073: room, Y, X; the hero at that Y with X in X..X+7 sets
; status 22 (Teleport $A8EA) unless PadLatch $B072 is set; off every pad
; PadLatch = 0.
;
; Witness: L1 16714 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
TeleportPadCheck:
  LD B,$03
  LD HL,TeleportPads
  LD A,(Room)
PadLoop:
  CP (HL)
  JR Z,PadRoom
  INC HL
  INC HL
  INC HL
  DJNZ PadLoop
PadNone:
  XOR A
  LD (PadLatch),A
  RET
PadRoom:
  INC HL
  LD A,(IX+$01)
  CP (HL)
  JR NZ,PadNone
  INC HL
  LD C,(HL)
  LD A,(IX+$00)
  CP C
  JR C,PadNone
  PUSH AF
  LD A,C
  ADD A,$08
  LD C,A
  POP AF
  CP C
  JR NC,PadNone
  LD A,(PadLatch)
  OR A
  RET NZ
  LD A,$16
  JP SetStatus

; Not 0 while the hero stands on the pad he arrived on
PadLatch:
  DEFB $00

; The three pads: room, Y, X (rooms $20, $3D, $30)
TeleportPads:
  INCBIN "res/tables/teleport-pads.bin",$0000,9

; "TIME REMAINING TO COLLISION", CR, "DAYS:   HOURS:   MINUTES:   ", 0
;
; Printed by TelescopeView $A7B9.
CollisionText:
  INCBIN "res/texts/collision.bin",$0000,58

  ORG $B165

; A = $5C00, Z when 0
;
; Called by the room $2D handler $B370.
;
; Witness: L1 346 (rzx, rzx).
KeyRoomDoneFlag:
  LD A,(BallThrown)
  OR A
  RET

; The room handler of room $12: right at the telescope starts status 30
;
; Status 0, the hero at X $C0, Y $40, right held: status 30. Not executed in
; any recording (room $12 not reached).
;
; Witness: L1 0 ().
TelescopeRoom:
  LD IY,ObjectSlot4
  LD A,(Status)
  OR A
  RET NZ
  LD A,(IX+$00)
  CP $C0
  RET NZ
  LD A,(IX+$01)
  CP $40
  RET NZ
  CALL ReadControls
  AND $01
  RET Z
  LD A,$1E
  JP SetStatus

; Room $47 (explorer 4): item 1 at the creature, or be eaten
;
; $5C00 set: nothing. RoomStage $5C41 0: object 4 at $80, $60, frame $64. 1:
; its frames $64-$67; with the hero left of X $B4: at Y $60 with item 1 in use
; status 33 (FlashPose $A770), else touching it: eaten (step 4, status 18).
; 2-3: two screen flashes ($916A), then $5C00 is set. Not executed in any
; recording.
;
; Witness: L1 0 ().
ExplorerRoom47:
  LD A,(BallThrown)
  OR A
  RET NZ
  LD HL,RoomStage
  LD IY,ObjectSlot4
  LD A,(HL)
  OR A
  JR NZ,Room47Step1
  LD (IY+$01),$60
  LD (IY+$00),$80
  LD (IY+$02),$64
  INC (HL)
  RET
Room47Step1:
  LD A,(HL)
  DEC A
  JR NZ,Room47Flash
  LD A,(PassCount)
  AND $01
  RET Z
  INC (IY+$03)
  RES 2,(IY+$03)
  LD A,$64
  ADD A,(IY+$03)
  LD (IY+$02),A
  LD A,(IX+$00)
  CP $B4
  RET NC
  LD A,(IX+$01)
  CP $60
  JR NZ,Room47Touch
  LD A,(HeldItem)
  CP $01
  JR NZ,Room47Touch
  LD A,(Status)
  CP $21
  RET Z
  LD A,$21
  JP SetStatus
Room47Flash:
  DEC A
  JR NZ,Room47Done
  LD (IY+$02),$68
  INC (HL)
  JP InvertPlayWindow
Room47Done:
  DEC A
  JR NZ,Room47Eaten
  CALL InvertPlayWindow
  INC A
  LD (BallThrown),A
  RET
Room47Touch:
  CALL Near
  RET NC
  LD (IX+$02),$3E
  LD A,(IX+$00)
  LD (IY+$00),A
  LD (IX+$01),$60
  LD (IY+$01),$50
  LD (IY+$02),$69
  LD (HL),$04
  JP StartDying
Room47Eaten:
  LD A,(PassCount)
  AND $01
  RET Z
  LD A,$6A
  SUB (IY+$02)
  ADD A,$69
  LD (IY+$02),A
  AND $01
  ADD A,$60
  LD (IX+$01),A
  RET

; Room $2F (explorer 2): with item 0 the hero rides the unicycle across
;
; At Y $48 with X $54-$B3: item 0 in use sets $5BFA = $3C (the unicycle frames,
; no jump); else left of $96 frame $3B, Y $4E, status 18. Not executed in any
; recording.
;
; Witness: L1 0 ().
ExplorerRoom2F:
  XOR A
  LD (UnicycleFrames),A
  LD A,(IX+$00)
  CP $B4
  RET NC
  CP $54
  RET C
  LD A,(IX+$01)
  CP $48
  RET NZ
  LD A,(HeldItem)
  OR A
  JR NZ,Room2FFall
  LD A,$3C
  LD (UnicycleFrames),A
  RET
Room2FFall:
  LD A,(IX+$00)
  CP $96
  RET NC
  LD A,(IX+$02)
  CP $3B
  RET Z
  LD (IX+$02),$3B
  LD (IX+$01),$4E
  JP StartDying

; Room $2E (explorer 1): item 4 at the creature, or it kills
;
; Object 4 at $A0, $48. Left of $B2: touching it status 26. At X $B2, Y $48
; with item 4: status 32 (DrinkPose $A783), its frame list Room2EFrames $B2D7,
; then status 0. Not executed in any recording.
;
; Witness: L1 0 ().
ExplorerRoom2E:
  LD IY,ObjectSlot3
  LD HL,RoomStage
  LD A,(HL)
  OR A
  JR NZ,Room2EStep1
  LD (IY+$04),$A0
  LD (IY+$05),$48
  LD (IY+$06),$3C
  LD (IY+$07),$00
  LD A,(IX+$00)
  CP $B2
  JR C,Room2ETouch
  RET NZ
  LD A,(IX+$01)
  CP $48
  RET NZ
  LD A,(HeldItem)
  CP $04
  RET NZ
  INC (HL)
  LD (IX+$03),$00
  LD A,$20
  JP SetStatus
Room2EStep1:
  LD A,(HL)
  DEC A
  JR NZ,Room2EStep3
  LD DE,Room2EFrames
  LD A,(StatusTimer)
  RRA
  LD L,A
  LD H,$00
  ADD HL,DE
  LD A,(HL)
  OR A
  JR Z,Room2EStep2
  LD (IY+$06),A
  RET
Room2EStep2:
  LD HL,RoomStage
  INC (HL)
  LD (IY+$06),$37
  RET
Room2EStep3:
  DEC A
  RET NZ
  INC (IY+$06)
  INC (HL)
  JP ClearStatus
Room2ETouch:
  LD IY,ObjectSlot4
  CALL Near
  RET NC
  LD A,$03
  LD (RoomStage),A
  LD A,$1A
  JP SetStatus

; Object 4's frames in room $2E after item 4, 0 end
Room2EFrames:
  INCBIN "res/anims/room-2e.bin",$0000,20

; Room $46 (explorer 3): item 3 rides the creature to the left, else death
;
; Object 4 at $C8, $48. Left of $DC without item 3: status 18. With it: the
; hero hidden, status 29, object 4 walks to X $A0, the hero at $94, $3E and
; status 1. Not executed in any recording.
;
; Witness: L1 0 ().
ExplorerRoom46:
  LD HL,RoomStage
  LD IY,ObjectSlot4
  LD A,(HL)
  OR A
  JR NZ,Room46Step1
  LD (IY+$02),$3E
  LD (IY+$00),$C8
  LD (IY+$01),$48
  LD A,(IX+$00)
  CP $DC
  RET NC
  LD A,(HeldItem)
  CP $03
  JR Z,Room46Ride
  LD (IY+$02),$3F
  LD (IX+$02),$1C
  LD (HL),$02
  XOR A
  LD (PassCount),A
  JP StartDying
Room46Ride:
  LD (IX+$02),$7F
  LD (IY+$02),$3A
  INC (HL)
  LD A,$1D
  JP SetStatus
Room46Step1:
  LD A,(HL)
  DEC A
  JR NZ,Room46Dead
  LD A,(PassCount)
  AND $06
  RRA
  ADD A,$3A
  LD (IY+$02),A
  DEC (IY+$00)
  LD A,(IY+$00)
  CP $A0
  RET NZ
  LD (IY+$02),$39
  LD (IX+$02),$00
  LD (IX+$00),$94
  LD (IX+$01),$3E
  INC (HL)
  INC (HL)
  LD A,$01
  CALL SetStatus
  LD A,$02
  LD (JumpDirection),A
  RET
Room46Dead:
  DEC A
  RET NZ
  LD A,(PassCount)
  AND $02
  RET Z
  LD (IY+$02),$3E
  RET

; Room $2D: throw the Cricket Ball, and the Formula falls into the explorer's
; hands
;
; The room script of room $2D (RoomScripts $B7EC). Does nothing once BallThrown
; $5C00 is set (KeyRoomDoneFlag $B165). Stage 0 (RoomStage $5C41 = 0) puts an
; object in slot $5B10 (X $64, Y $48, frame $4F; the target) every pass and
; waits for the explorer to stand at X $DC, Y $48 holding the Cricket Ball
; (HeldItem $5B98 = 2); then clears the explorer's facing bit (IX+3 bit 7),
; goes to stage 1 and sets status $1C (Room2DAnim $A828 through the status
; table $A72E; stage 1 then waits for the throw frame).
;
; Stage 1 waits for the explorer's frame $3E (the throw pose), then puts the
; ball in slot $5B14 (X $C8, Y $39, frame $39). Stage 2 flies the ball 4 pixels
; left and 1 down a pass until Y $52, then steps the target's frame ($4F to
; $50) and drops the Formula from the top: slot $5B14 X $DC, Y $08, frame $8F
; ($80 + 15; frames $80 + n show item n, as the professor's bubble does too:
; inferred from the two uses, a run request). Stage 3 lowers it 1 pixel a pass
; to Y $48 (the explorer's hands), then sets BallThrown, hides the slot, makes
; the Formula ($0F) the held item, redraws the hand icon ($9E5D) and clears the
; status ($AE84).
;
; Witness: rzx16000 runs stages 0-2 (the throw at $B3A1 once, the hit at $B3DB
; once), rzx18000 stage 3 ($B3F5 once): the RZX run gets the Formula here.
;
; Witness: L1 346 (rzx, rzx).
CricketBallScript:
  CALL KeyRoomDoneFlag
  RET NZ
  LD IY,ObjectSlot3
  LD HL,RoomStage
  LD A,(HL)
  OR A
  JR NZ,CricketWaitThrow
  LD (IY+$00),$64         ; stage 0: the target in slot $5B10
  LD (IY+$01),$48
  LD (IY+$02),$4F
  LD (IY+$03),$00
  LD A,(HeldItem)            ; wait for the Cricket Ball in hand ...
  CP $02
  RET NZ
  LD A,(Hero)            ; ... and the explorer at X $DC, Y $48
  CP $DC
  RET NZ
  LD A,(Hero+1)
  CP $48
  RET NZ
  INC (HL)
  RES 7,(IX+$03)
  LD A,$1C                ; status $1C: the throw
  JP SetStatus
CricketWaitThrow:
  LD A,(HL)               ; stage 1: wait for the explorer's throw frame $3E
  DEC A
  JR NZ,CricketBallFlight
  LD A,(IX+$02)
  CP $3E
  RET NZ
  INC (HL)
  LD (IY+$04),$C8         ; the ball in slot $5B14
  LD (IY+$05),$39
  LD (IY+$06),$39
  LD (IY+$07),$00
  RET
CricketBallFlight:
  DEC A                   ; stage 2: the ball flies left and down to Y $52
  JR NZ,CricketFormulaFalls
  INC (IY+$05)
  LD A,(IY+$04)
  SUB $04
  LD (IY+$04),A
  LD A,(IY+$05)
  CP $52
  RET NZ
  INC (HL)
  INC (IY+$02)            ; the target is hit: its next frame
  LD (IY+$04),$DC         ; the Formula (frame $8F) at the top of the room
  LD (IY+$05),$08
  LD (IY+$06),$8F
  RET
CricketFormulaFalls:
  INC (IY+$05)            ; stage 3: the Formula falls to the explorer's hands
                          ; at Y $48
  LD A,(IY+$05)
  CP $48
  RET NZ
  LD A,$01                ; BallThrown = 1: the script is over
  LD (BallThrown),A
  LD (IY+$06),$7F
  LD A,$0F                ; HeldItem = $0F, the Formula
  LD (HeldItem),A
  CALL DrawPortrait
  JP ClearStatus          ; status 0

; Room $3F: the basket that carries the explorer across the room
;
; The room script of room $3F. The basket is slot $5B14 (frame $9E: item sprite
; $80 + 30, SK "Busket"). Stage 0 places it at the side away from the explorer:
; X $D8 (the right end) with RoomFlag $5C40 = 1 when the explorer is left of X
; $C8, else X $08 with RoomFlag 0; Y $30.
;
; Stage 1: the basket travels toward the explorer one pixel a pass, only while
; the lever of rooms $3E and $40 allows it: from the right end (RoomFlag 1)
; while LeverState $5C42 is not 0 (BasketToLeft $B4B0), from the left end
; (RoomFlag 0) while LeverState is 0 (BasketToRight $B47E); a blocked move
; leaves E as the caller had it (known only from the code). At the end of its
; way (E = 0) it waits for the explorer to come near ($9140); then stage 2,
; RoomFlag flipped, status $15 (RideObject4 $A95F). Stage 2 carries it to the
; other end whatever the lever (BasketRight $B483 / BasketLeft $B4B5); at the
; end the explorer is set 8 pixels higher (IX+1 - 8), stage 3 (the script then
; does nothing until the room is entered again) and the status is cleared
; ($AE84).
;
; Witness: rzx28000 and rzx32750 each run stage 0 and the ride ($B44E once
; each), rzx28000 and rzx34000 the arrival ($B471).
;
; Witness: L1 870 (rzx, rzx, rzx).
BasketScript:
  LD IY,ObjectSlot4
  LD HL,RoomStage
  LD A,(HL)
  OR A
  JR NZ,BasketWait
  INC (HL)
  LD A,(IX+$00)
  LD C,$01
  CP $C8
  LD (IY+$00),$D8         ; start at the right end ...
  JR C,BasketPlace
  DEC C
  LD (IY+$00),$08         ; ... or at the left end when the explorer is right
                          ; of X $C8
BasketPlace:
  LD A,C                  ; RoomFlag = 1 (at the right end) or 0
  LD (RoomFlag),A
  LD A,$30
  LD (ObjectSlot4+1),A
  LD A,$9E
  LD (ObjectSlot4+2),A
  RET
BasketWait:
  CP $01                  ; stage 1: travel toward the explorer if the lever
                          ; allows, wait for him
  JR NZ,BasketRide
  LD A,(RoomFlag)
  LD C,A
  OR A
  PUSH AF
  CALL NZ,BasketToLeft
  POP AF
  CALL Z,BasketToRight
  LD A,E
  OR A
  RET NZ
  CALL Near               ; at its end: is the explorer near?
  RET NC
  LD (HL),$02
  LD A,(RoomFlag)
  XOR $01                 ; flip RoomFlag: the ride goes to the other end
  LD (RoomFlag),A
  LD A,$15                ; status $15
  LD (Status),A
  RET
BasketRide:
  CP $02                  ; stage 2: carry the explorer to the other end
  RET NZ
  LD A,(RoomFlag)
  LD C,A
  OR A
  PUSH AF
  CALL NZ,BasketLeft
  POP AF
  CALL Z,BasketRight
  LD A,E
  OR A
  RET NZ
  LD A,(IX+$01)           ; arrived: the explorer 8 pixels higher, stage 3,
                          ; status 0
  SUB $08
  LD (IX+$01),A
  LD (HL),$03
  JP ClearStatus

; Move the basket right one pixel if the lever selects the right end
;
; Returns at once (E unchanged) when LeverState $5C42 is not 0; else
; BasketRight $B483. Called by BasketScript $B409 in stage 1.
;
; Witness: L1 209 (rzx).
BasketToRight:
  LD A,(LeverState)
  OR A
  RET NZ

; Move the basket right one pixel, along the track's profile
;
; IY = the basket slot $5B14. Out: E = 0 when it is already at the right end (X
; $D8), else E = 1 and X + 1. The track: while X is below $38 the basket also
; rises 2 pixels a pass (Y - 2, not above Y 8); from X $C8 on it sinks 2 a pass
; back to Y $30 (BasketRightTail $B4A3); between them it keeps its height.
;
; Witness: L1 418 (rzx, rzx).
BasketRight:
  LD E,$00
  LD A,(IY+$00)
  CP $D8
  RET NC
  INC E
  LD B,(IY+$01)
  INC A
  LD (IY+$00),A
  CP $38
  JR NC,BasketRightTail
  LD C,A                  ; X below $38: rise 2 pixels, not above Y 8
  LD A,B
  SUB $02
  CP $08
  RET C
  LD (IY+$01),A
  RET

; Leftover: one byte $79 (LD A,C) between two routines
;
; No instruction runs or reads it in play (the load in c1 only); known only
; from the code.
BasketPad1:
  DEFB $79

; The right end of the track: from X $C8 sink 2 pixels a pass to Y $30
;
; Entered from BasketRight $B483 with A = the new X, B = Y.
;
; Witness: L1 322 (rzx, rzx).
BasketRightTail:
  CP $C8
  RET C
  LD A,B
  ADD A,$02
  CP $30
  RET NC
  LD (IY+$01),A
  RET

; Move the basket left one pixel if the lever selects the left end
;
; Returns at once when LeverState $5C42 is 0; else BasketLeft $B4B5.
;
; Witness: L1 209 (rzx).
BasketToLeft:
  LD A,(LeverState)
  OR A
  RET Z

; Move the basket left one pixel, along the track's profile
;
; Out: E = 0 at the left end (X 8), else E = 1 and X - 1. While X is below $1C
; the basket sinks 2 pixels a pass (Y + 2, below $30); from X $7B up it rises 2
; a pass, not above Y 8 (BasketLeftTail $B4D5); from $1C to $7A it keeps its
; height.
;
; Witness: L1 418 (rzx, rzx, rzx).
BasketLeft:
  LD E,$00
  LD A,(IY+$00)
  CP $09
  RET C
  INC E
  LD B,(IY+$01)
  DEC A
  LD (IY+$00),A
  CP $1C
  JR NC,BasketLeftTail
  LD C,A                  ; X below $1C: sink 2 pixels, below Y $30
  LD A,B
  ADD A,$02
  CP $30
  RET NC
  LD (IY+$01),A
  RET

; Leftover: one byte $79 (LD A,C) between two routines
;
; No instruction runs or reads it in play (the load in c1 only); known only
; from the code.
BasketPad2:
  DEFB $79

; X $1C or more: keep the height below X $7B, from X $7B up rise 2 pixels a
; pass, not above Y 8
;
; Entered from BasketLeft $B4B5 with A = the new X, B = Y. Evidence: rzx28000
; frames 527-1096, the basket from X $D8 at Y $30 up to Y 8 at X $C4, level
; down to X $1C, then down to Y $2E at X 8.
;
; Witness: L1 376 (rzx, rzx, rzx).
BasketLeftTail:
  CP $7B
  RET C
  LD A,B
  SUB $02
  CP $08
  RET C
  LD (IY+$01),A
  RET

; Room $39: the creature that flees from the Silver Cross
;
; The room script of room $39. The creature is slot $5B10 (X $A4, Y $40, frame
; $40, placed at stage 0). CrossState $5C45: 0 waiting, 1 fleeing, $FF gone.
; Waiting, it does nothing until the explorer's Y is below $48 and his X $62 or
; more; then if he holds the Silver Cross (HeldItem $5B98 = $1D) it starts to
; flee, else it turns to him (IX+3 bit 7 set, frame $44) and, if the status is
; below 4, sets status $17 (SilentDeath $A8A8).
;
; Fleeing: X + 2 a pass, frames $41-$44 by PassCount ($5C02 / 2 & 3); at X $E6
; it is gone: +150 score (AddScore $BCF2) and frame $7F every pass after.
;
; Witness: rzx40000 runs it 273 times: the placing ($B4ED) once, the flight
; ($B540) 33 times, the score ($B538) once. The attack branch ($B518) is not
; executed in any recording (c1, explorers, gameover, the 31 rzx builds).
;
; Witness: L1 273 (rzx).
SilverCrossScript:
  LD IY,ObjectSlot3
  LD HL,RoomStage
  LD A,(HL)
  OR A
  JR NZ,CrossCheck
  LD (IY+$00),$A4
  LD (IY+$01),$40
  LD (IY+$02),$40
  INC (HL)
CrossCheck:
  LD HL,CrossState             ; CrossState: $FF gone, 1 fleeing, 0 waiting
  LD A,(HL)
  CP $FF
  JR Z,CrossGone
  OR A
  JR NZ,CrossFlee
  LD A,(IX+$01)
  CP $48
  RET NC
  LD A,(IX+$00)
  CP $62
  RET C
  LD A,(HeldItem)            ; the Silver Cross in hand: flee
  CP $1D
  JR Z,CrossFlee
  SET 7,(IY+$03)          ; no cross: the creature turns and attacks (status
                          ; $17)
  LD (IY+$02),$44
  LD A,(Status)
  CP $04
  RET NC
  LD A,$17
  JP SetStatus
CrossFlee:
  LD (HL),$01             ; flee right until X $E6
  RES 7,(IY+$03)
  LD A,(IY+$00)
  CP $E6
  JR C,CrossStep
  LD DE,$0096             ; out of the room: +150
  CALL AddScore
  JR CrossGone
CrossStep:
  INC (IY+$00)            ; X + 2, frame $41 + (PassCount / 2 & 3)
  INC (IY+$00)
  LD C,$41
  LD A,(PassCount)
  SRL A
  AND $03
CrossSetFrame:
  ADD A,C
  LD (IY+$02),A
  RET
CrossGone:
  LD (HL),$FF             ; CrossState = $FF, frame $7F
  LD A,$7F
  JR CrossSetFrame

; Room $17: the two snakes that strike unless charmed by the Flute
;
; The room script of room $17: RunSnakes $B57C over two objects from slot $5B0C
; (the room's two still creatures, frames $51, RoomCreatures $C266). Witness:
; rzx04000 and rzx06000 run it 297 times.
;
; Witness: L1 297 (rzx, rzx).
SnakesRoom17:
  LD IY,ObjectSlot2
  LD B,$02
  JR RunSnakes

; Room $1A: three snakes that strike unless charmed by the Flute
;
; The room script of room $1A. Stage 0 copies SnakeTemplate $B5D1 into the
; slots $5B0C, $5B10, $5B14 (X $44, $70, $94, Y $60, frames $51-$53). Then
; every pass, for each of the 3 (2 in room $17, from SnakesRoom17 $B55A): frame
; $7F (gone) is skipped; frame $55 (struck the pass before) becomes $7F and
; sets status $19 (Room1ADeath $A88F); else the frame steps through $51-$54 (+
; PassCount bit 0, back to $51 after $54), and the snake strikes (frame $55)
; when its X equals the explorer's X rounded down to 4 pixels. The Flute
; (HeldItem $5B98 = $0C) stops the strike: in room $17 always, in room $1A only
; while the explorer's Y is below $3A (at Y $3A or more the alignment test runs
; without it).
;
; Witness: rzx08000, rzx10000, rzx12000 run it 437 times; the strike ($B5C2)
; and the bite ($B5C8) once each, in rzx10000.
;
; Witness: L1 437 (rzx, rzx, rzx).
SnakesRoom1A:
  LD IY,ObjectSlot2
  LD HL,RoomStage
  LD A,(HL)
  OR A
  JR NZ,SnakesThree
  INC (HL)
  LD HL,SnakeTemplate
  LD DE,ObjectSlot2
  LD BC,$000C
  LDIR                    ; three 4-byte objects from the template
  RET
SnakesThree:
  LD B,$03                ; room $1A: three snakes
; This entry point is used by the routine at SnakesRoom17.
RunSnakes:
  LD A,(IY+$02)           ; for each snake: gone, struck or charmed?
  CP $7F
  JR Z,SnakeNext
  CP $55
  JR Z,SnakeBite
  LD A,(PassCount)            ; the next frame, $51-$54
  AND $01
  ADD A,(IY+$02)
  CP $55
  JR NZ,SnakeFrameSet
  LD A,$51
SnakeFrameSet:
  LD (IY+$02),A
  LD A,(Room)            ; room $1A with the explorer at Y $3A or more: no
                          ; Flute check
  CP $17
  JR Z,SnakeFluteCheck
  LD A,(IX+$01)
  CP $3A
  JR NC,SnakeAlignCheck
SnakeFluteCheck:
  LD A,(HeldItem)            ; the Flute in hand: no strike
  CP $0C
  JR Z,SnakeNext
SnakeAlignCheck:
  LD A,(IX+$00)           ; the explorer straight above or below the snake?
  AND $FC
  CP (IY+$00)
  JR Z,SnakeStrike
SnakeNext:
  INC IY
  INC IY
  INC IY
  INC IY
  DJNZ RunSnakes
  RET
SnakeStrike:
  LD A,$55                ; frame $55: strikes
  LD (IY+$02),A
  RET
SnakeBite:
  LD (IY+$02),$7F         ; the bite: frame $7F, status $19
  LD A,$19
  JP SetStatus

; The three snakes of room $1A: X, Y, frame, flags
;
; Copied to $5B0C-$5B17 by SnakesRoom1A $B562 at stage 0. Witness: rzx08000 and
; rzx10000 read it once each.
SnakeTemplate:
  INCBIN "res/tables/snakes-1a.bin",$0000,12

; Room $3B, the lab: Professor Eyestrain asks for six items, the sixth ends the
; game
;
; The room script of room $3B (the lab). The professor is slot $5B14, his
; speech bubble slot $5B10 (its frame $80 + the item he wants: an item sprite).
; Every pass: when the explorer is near him ($9140) holding WantedItem $5C3C,
; the item is given: HeldItem = $FF, LastGift $5C3E = the item, the items of
; the room are scanned again ($B93F), the hand icon redrawn ($9E5D), +150
; score, GiftCount $5C3D + 1; the sixth gift ends the game (ProfessorEnding
; $B6EE).
;
; ProfessorState $5BA1 (0 on room entry): 0 places him (X $1A, Y $48, the
; bubble at Y $30) and sets 1; 1 (bits 0-6) he walks (ProfWalk $B676) with bit
; 7 the direction; 2 he plays the frames of ProfFrames $B6C1 one a pass through
; $ABE1 (step LabStep $B6ED) and goes back to 1 at their end mark $FF; while
; bit 7 is clear (he walks right) the first frame $4D ends the sequence
; instead, so he asks only on his way left. Each new frame $4D (his asking
; pose) shows the bubble: WantedItem = WantedItems[GiftCount] ($B6BB), the
; bubble frame $80 + that item. InitGame writes $FF at $8FA6, but its clear of
; $5BFA-$5C8D ($8FBE) runs after and zeroes $5C3C: WantedItem is 0 (the
; Unicycle) until he first asks (rzx44000 frames 0-415 and rzx24750 frame 613:
; $5C3C = 0). WantedItem is not reset after a gift (rzx44000 frames 460-723:
; $0F kept).
;
; Witness: rzx42000-rzx50000 run it 2293 times; the bubble ($B65E) 11 times,
; the gifts ($B5EF) 6 times (rzx44000 2, rzx46000 2, rzx48000 1, rzx50000 1),
; the ending once (rzx50000).
;
; Witness: L1 2293 (rzx, rzx, rzx, rzx, rzx).
ProfessorScript:
  LD IY,ObjectSlot4
  CALL Near
  JR NC,ProfState
  LD HL,HeldItem             ; the wanted item in hand?
  LD A,(WantedItem)
  CP (HL)
  JR NZ,ProfState
  PUSH IY
  PUSH IX
  LD (HL),$FF             ; given: HeldItem = $FF, LastGift = the item
  LD (LastGift),A
  CALL SpawnRoomItems
  CALL DrawPortrait
  LD DE,$0096             ; +150
  CALL AddScore
  POP IX
  POP IY
  LD HL,GiftCount             ; GiftCount + 1: the sixth ends the game
  INC (HL)
  LD A,(HL)
  CP $06
  JP Z,ProfessorEnding
ProfState:
  LD HL,ProfessorState             ; ProfessorState 0: place the professor
  LD A,(HL)
  OR A
  JR NZ,ProfMode
  INC (HL)
  XOR A
  LD (LabStep),A
  LD (IY+$01),$48         ; at X $1A, Y $48; the bubble at Y $30
  LD (IY+$00),$1A
  LD A,$30
  LD (ObjectSlot3+1),A
  RET
ProfMode:
  AND $7F                 ; 1: walk; 2: play the frame sequence
  CP $01
  JR Z,ProfWalk
  LD HL,LabStep           ; the next frame of ProfFrames ($ABE1 steps LabStep)
  LD DE,ProfFrames
  CALL NextFrameAt
  LD HL,ProfessorState
  CP $FF
  JR NZ,ProfSequenceStep
ProfSequenceEnd:
  LD A,$7F                ; end of the sequence: hide the bubble, back to
                          ; walking
  LD (ObjectSlot3+2),A
  DEC (HL)
  RET
ProfSequenceStep:
  BIT 7,(HL)              ; walking right (bit 7 clear): the first frame $4D
                          ; ends the sequence
  JR NZ,ProfSetFrame
  CP $4D
  JR Z,ProfSequenceEnd
ProfSetFrame:
  LD C,(IY+$02)
  LD (IY+$02),A
  CP $4D
  RET NZ
  LD A,C
  CP $4D
  RET Z
  LD A,(GiftCount)            ; a new frame $4D: he asks for WantedItems[GiftCount]
  LD L,A
  LD H,$00
  LD DE,WantedItems
  ADD HL,DE
  LD A,(HL)
  LD (WantedItem),A
  ADD A,$80               ; the bubble shows the item ($80 + item)
  LD (ObjectSlot3+2),A
  XOR A
  LD (ObjectSlot3+3),A
  RET
ProfWalk:
  LD A,(IY+$00)           ; walk 2 pixels a pass, the bubble with him
  SET 7,(IY+$03)
  LD C,$02
  BIT 7,(HL)
  JR Z,ProfWalkStep
  RES 7,(IY+$03)          ; ProfessorState bit 7 set: walk left
  LD C,$FE
ProfWalkStep:
  LD A,(IY+$00)
  ADD A,C
  LD (IY+$00),A
  LD (ObjectSlot3),A
  SUB $04                 ; every 32 pixels: stop and play the sequence
                          ; (ProfessorState 2)
  LD C,A
  AND $1F
  OR A
  JR NZ,ProfWalkFrame
  INC (HL)
  XOR A
  LD (LabStep),A
  LD A,C
  CP $C0                  ; X $C4 and right: turn left
  JR C,ProfLeftEdge
  SET 7,(HL)
  RET
ProfLeftEdge:
  CP $22                  ; X below $26: turn right
  RET NC
  RES 7,(HL)
  RET
ProfWalkFrame:
  LD A,(PassCount)            ; the walking frames $49-$4C
  SRL A
  AND $03
  ADD A,$49
  LD (IY+$02),A
  RET

; The six items the professor asks for, in order
;
; Read by ProfessorScript $B5DD at index GiftCount $5C3D: $0F Formula, $13 Coat
; Hanger, $12 Battery, $15 Atomic Pile, $11 Button, $17 Cup of tea (item names
; SK). Witness: rzx44000-rzx50000 read it at the bubbles, 11 times; the RZX run
; gives all six.
WantedItems:
  INCBIN "res/tables/wanted-items.bin",$0000,6

; The professor's frame sequence: 43 sprite frames and the end mark $FF
;
; Played one frame a pass by ProfessorScript $B5DD through $ABE1 (index LabStep
; $B6ED): $4E (11 passes), $45 x 3, $46, then $47 / $48 five times, $47, $46,
; $45 x 3, $4D (13 passes; the asking pose), $FF. SK took it for text
; ("NNNNNNNNNNNEEEFGHGHGHGHGHGFEEEMMMMMMMMMMMMM"). Witness: rzx42000-rzx50000
; read it while he stands.
ProfFrames:
  INCBIN "res/anims/professor.bin",$0000,44

; The step index into ProfFrames, a variable
;
; Cleared by ProfessorScript at the placing ($B61B) and at each stop ($B69D);
; stepped by $ABE1. Witness: rzx42000-rzx50000 read it 3744 times.
LabStep:
  DEFB $00

; The sixth gift: on to room $28 and the ending
;
; Room = $28, the room set up ($9855), GameWon $5BFE = $1D, status $1D (Frozen
; $A90E); SpaceScene $B0B6, room $28's script, plays the ending (and sets
; GameOver $5BFF), $5B06 = $7F. Called by ProfessorScript $B5DD. Witness:
; rzx50000 runs it once, before the ending at frame 729.
;
; Witness: L1 1 (rzx).
ProfessorEnding:
  LD A,$28
  LD (Room),A
  CALL SetUpRoom
  LD A,$1D
  LD (GameWon),A
  CALL SetStatus
  LD A,$7F
  LD (Hero+2),A
  RET

; Room $43: stand at one spot holding the Silver Lining
;
; The room script of room $43. When the explorer stands at Y $20 with X from
; $76 to $83, holds the Silver Lining (HeldItem $5B98 = $0D) and the status is
; 0, sets status $1B (Room43Anim $A851). Witness: rzx36000-rzx40000 run it 737
; times; the explorer stands there with another item 100 times (rzx38000); the
; trigger ($B71E) is not executed in any recording (c1, explorers, gameover,
; the 31 rzx builds).
;
; Witness: L1 737 (rzx, rzx, rzx).
SilverLiningScript:
  LD A,(IX+$01)
  CP $20
  RET NZ
  LD A,(IX+$00)
  CP $84
  RET NC
  CP $76
  RET C
  LD A,(HeldItem)
  CP $0D
  RET NZ
  LD A,(Status)
  OR A
  RET NZ
  LD A,$1B                ; status $1B
  JP SetStatus

; Room $40: the lever at X 8
;
; The room script of room $40: slot $5B14 at X 8, then LeverScript $B735.
; Witness: rzx28000-rzx32750 run it 1036 times.
;
; Witness: L1 1036 (rzx, rzx, rzx, rzx).
LeverRoom40:
  LD IY,ObjectSlot4
  LD (IY+$00),$08
  JR LeverScript

; Room $3E: the lever at X $DC
;
; The room script of room $3E: slot $5B14 at X $DC, then LeverScript $B735.
; Witness: rzx26000, rzx28000, rzx34000 run it 571 times.
;
; Witness: L1 571 (rzx, rzx, rzx).
LeverRoom3E:
  LD IY,ObjectSlot4
  LD (IY+$00),$DC

; The lever of rooms $3E and $40: fit the Switch, then pull it to send the
; basket
;
; IY = slot $5B14, Y $12. Frame $56 before the Switch is fitted, $57 after
; (SwitchFitted $5C43 not 0). Not fitted: when the explorer comes near ($9140)
; holding the Switch (HeldItem $5B98 = $10) it is fitted: HeldItem = $FF,
; SwitchFitted = $FF, the hand icon redrawn. Fitted (in both rooms: one flag):
; the lever's mirror bit (IY+3 bit 7) shows LeverState $5C42 (set when 0), and
; each new touch (RoomFlag $5C40 from 0 to 1) flips LeverState; away from the
; explorer RoomFlag $5C40 is 0 again. LeverState chooses the end of room $3F
; the basket waits at (BasketScript $B409).
;
; Witness: the Switch is fitted once ($B751, rzx28000), the lever pulled twice
; ($B770, rzx28000 and rzx32750).
;
; Witness: L1 1607 (rzx, rzx, rzx, rzx, rzx, rzx).
LeverScript:
  LD (IY+$01),$12
  LD C,$56
  LD A,(SwitchFitted)
  OR A
  JR Z,LeverFrame
  INC C
LeverFrame:
  LD (IY+$02),C           ; frame $56, or $57 when the Switch is fitted
  JR NZ,LeverShow
  LD A,(HeldItem)            ; not fitted: the Switch in hand?
  CP $10
  RET NZ
  CALL Near
  RET NC
  LD A,$FF                ; fitted: HeldItem = $FF, SwitchFitted = $FF
  LD (HeldItem),A
  LD (SwitchFitted),A
  JP DrawPortrait
LeverShow:
  LD A,(LeverState)            ; the lever's mirror bit from LeverState
  CALL LeverMirror
  LD HL,RoomFlag
  CALL Near
  JR C,LeverTouch
  LD (HL),$00
  RET
LeverTouch:
  LD A,(HL)               ; a new touch flips LeverState
  OR A
  RET NZ
  LD (HL),$01
  LD HL,LeverState
  LD A,(HL)
  XOR $FF
  LD (HL),A

; Set the lever's mirror bit when A = 0, clear it otherwise
;
; A = LeverState $5C42, IY = the lever slot. Out: IY+3 bit 7 set when A = 0.
; Called from LeverScript $B735 ($B75F) and fallen into after a flip ($B778).
;
; Witness: L1 1338 (rzx, rzx, rzx, rzx, rzx).
LeverMirror:
  OR A
  SET 7,(IY+$03)
  RET Z
  RES 7,(IY+$03)
  RET

; Room $3C: without the Anti Radiation Pills the explorer dies
;
; The room script of room $3C. RoomStage $5C41 counts the passes in the room to
; $14; at $14, if PillsTaken $5C3F is 0 (the pills, item $16, never picked up:
; PickUpItem $BB96 sets it), stage $15 and status $17 (SilentDeath $A8A8); with
; the pills it stays at $14. Witness: rzx26000 runs it 214 times, PillsTaken
; set (rzx14500 picks the pills up, $BB96 once); the death branch ($B796) is
; not executed in any recording (c1, explorers, gameover, the 31 rzx builds).
;
; Witness: L1 214 (rzx).
RadiationScript:
  LD HL,RoomStage
  LD A,(HL)
  CP $14
  JR Z,RadiationCheck
  CP $15
  RET Z
  INC (HL)
  RET
RadiationCheck:
  LD A,(PillsTaken)            ; 20 passes in the room: the pills?
  OR A
  RET NZ
  INC (HL)                ; no pills: status $17
  LD A,$17
  JP SetStatus

; Room $36: the flickering hazard floor, 21 tiles of row 10 from column 0
;
; B = 21 tiles from the tile map's $F940 (row 10), then FlickerFloor $B7A8.
; Witness: rzx20000 runs it 155 times.
;
; Witness: L1 155 (rzx).
FloorRoom36:
  LD B,$15
  LD HL,TileMap+$0140
  JR FlickerFloor

; Room $35: the flickering hazard floor, 11 tiles of row 10 from column 20
;
; B = 11 tiles from $F954, then FlickerFloor $B7A8. Witness: rzx20000 runs it
; 187 times.
;
; Witness: L1 187 (rzx).
FloorRoom35:
  LD B,$0B
  LD HL,TileMap+$0154

; Write the hazard tiles $BC / $BD along the floor, alternating, and keep slot
; $5B14 on the explorer
;
; B = the tile count, HL = the first tile map byte. For each tile (the loop
; runs the whole body again): Y of the creature slots $5B09, $5B0D, $5B11 = 0,
; slot $5B14 at the explorer's X and 8 pixels below him (not below Y $5A), then
; the tile $BC + (B & 1) XOR (PassCount / 2 & 1) written through $9A4D. So the
; floor alternates $BC / $BD tile by tile and swaps every second pass; $BC and
; $BD are the tiles $A102 counts when stood on (SK: 50 of them set status $11,
; SinkInMud $AA04). What slot $5B14 shows here is known only from the code (a
; run request).
;
; Witness: L1 5312 (rzx).
FlickerFloor:
  XOR A
  LD (ObjectSlot1+1),A
  LD (ObjectSlot2+1),A
  LD (ObjectSlot3+1),A
  LD A,(IX+$00)
  LD (ObjectSlot4),A
  LD A,(IX+$01)
  ADD A,$08
  CP $5A
  JR NC,FlickerTile
  LD (ObjectSlot4+1),A
FlickerTile:
  LD A,(PassCount)            ; the tile: $BC or $BD by tile parity and PassCount
                          ; bit 1
  SRL A
  AND $01
  LD C,A
  LD A,B
  AND $01
  ADD A,$BC
  XOR C
  PUSH BC
  PUSH HL
  CALL SetTileBuffer
  POP HL
  INC HL
  POP BC
  DJNZ FlickerFloor
  RET

; Run the script of the room: the word of RoomScripts $B7EC
;
; HL = RoomScripts + 2 x Room ($5C01), then $A6DD jumps to the word (none when
; 0), with DE kept. Called every pass by $A3E1 with IX = the explorer object
; $5B04.
;
; Witness: L1 26517 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
RunRoomScript:
  LD A,(Room)
  LD L,A
  LD H,$00
  ADD HL,HL
  PUSH DE
  LD DE,RoomScripts
  ADD HL,DE
  JP JumpThroughWord

; The per-room script of each room $00-$47: a routine address, 0 for none
;
; RunRoomScript $B7DD jumps to word Room ($5C01) through $A6DD every pass, with
; IX = the explorer object $5B04; a zero word does nothing. 72 words: the 70
; map rooms $00-$45 and the two rooms $46, $47 that only the portals reach. 21
; rooms have a script; the ones in this range: $17 and $1A the snakes ($B55A,
; $B562), $2D the cricket ball ($B370), $35 and $36 the flickering floor
; ($B7A3, $B79C), $39 the Silver Cross ($B4E2), $3B the professor ($B5DD), $3C
; the radiation ($B784), $3E and $40 the lever ($B72D, $B723), $3F the basket
; ($B409), $43 the Silver Lining ($B704). The others go to $AFD7 (rooms $03,
; $0F), $B16A ($12), $B0B6 ($28), $A34B ($2C), $B263 ($2E), $B22D ($2F), $B2EB
; ($46) and $B18A ($47).
;
; Witness: the play builds read the words of the rooms they visit (rzx16000 and
; rzx18000 read word $2D, rzx42000-rzx50000 word $3B); words $46 and $47 are
; read only by the load in c1.
RoomScripts:
  DEFW $0000,$0000,$0000,BalloonRoom,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; level 0,
                                                                                     ; rooms
                                                                                     ; $00-$0B:
                                                                                     ; $03 $AFD7
  DEFW $0000,$0000,$0000,BalloonRoom,$0000,$0000,TelescopeRoom,$0000,$0000,$0000,$0000,SnakesRoom17 ; level 1,
                                                                                                    ; rooms
                                                                                                    ; $0C-$17:
                                                                                                    ; $0F $AFD7,
                                                                                                    ; $12 $B16A,
                                                                                                    ; $17 $B55A
  DEFW $0000,$0000,SnakesRoom1A,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000 ; level 2,
                                                                                      ; rooms
                                                                                      ; $18-$23:
                                                                                      ; $1A $B562
  DEFW $0000,$0000,$0000,$0000,SpaceScene,$0000,$0000,$0000,FloatInRoom2C,CricketBallScript,ExplorerRoom2E,ExplorerRoom2F ; level 3,
                                                                                                                          ; rooms
                                                                                                                          ; $24-$2F:
                                                                                                                          ; $28 $B0B6,
                                                                                                                          ; $2C $A34B,
                                                                                                                          ; $2D $B370,
                                                                                                                          ; $2E $B263,
                                                                                                                          ; $2F $B22D
  DEFW $0000,$0000,$0000,$0000,$0000,FloorRoom35,FloorRoom36,$0000,$0000,SilverCrossScript,$0000,ProfessorScript ; level 4,
                                                                                                                 ; rooms
                                                                                                                 ; $30-$3B:
                                                                                                                 ; $35 $B7A3,
                                                                                                                 ; $36 $B79C,
                                                                                                                 ; $39 $B4E2,
                                                                                                                 ; $3B $B5DD
  DEFW RadiationScript,$0000,LeverRoom3E,BasketScript,LeverRoom40,$0000,$0000,SilverLiningScript,$0000,$0000,ExplorerRoom46,ExplorerRoom47 ; level 5,
                                                                                                                                           ; rooms
                                                                                                                                           ; $3C-$47:
                                                                                                                                           ; $3C $B784,
                                                                                                                                           ; $3E $B72D,
                                                                                                                                           ; $3F $B409,
                                                                                                                                           ; $40 $B723,
                                                                                                                                           ; $43 $B704,
                                                                                                                                           ; $46 $B2EB,
                                                                                                                                           ; $47 $B18A

  ORG $BA97

; Rooms $19 and $3A: the expanding bridge across the tile map's row 11
;
; A = the room. BridgeState $5C0C (0 on room entry, $9880): 0 idle; bits 0-6
; the tile being drawn (1-$10); bit 7 the second half. Idle, the bridge starts
; when the explorer stands at the left end (X $2C-$35) or the right end (X
; $B2-$B7) holding the ACME Expanding Bridge (HeldItem $5B98 = $0B) in room
; $19; in room $3A it starts once the professor has an item (LastGift $5C3E not
; 0) or with the Formula in hand ($0F). From the left end BridgeState = 1 and
; BridgeReverse $5C0D = 0; from the right end (X $7A or more) BridgeState = $10
; and BridgeReverse = 1.
;
; Every fourth pass (PassCount & 3 = 0) one tile is written into the tile map
; at $F968 + (BridgeState & $7F) - 1 (row 11, from column 8) through $9A52: the
; bridge tile $07 (room $19) or $BF (room $3A), or in the bit-7 half a tile of
; BridgeTiles $BB51 ($BB55 in room $3A) by the column (& 3). Forward
; (BridgeReverse 0): BridgeState + 1 up to $10; there it waits until the
; explorer reaches X $BA, then $81 runs a second sweep and ends at 0. Reverse:
; BridgeState - 1 down to 1, waits for the explorer below X $30, then $90 and
; back to 0.
;
; Witness: the bridge starts 3 times ($BACC: rzx08000, rzx12000, rzx42000);
; rzx08000 and rzx42000 cross forward ($BB37), rzx12000 in reverse ($BB4E).
;
; Witness: L1 857 (rzx, rzx, rzx, rzx).
BridgeEffect:
  LD C,A
  LD HL,BridgeState
  LD A,(HL)
  OR A
  JR NZ,BridgeDraw
  CALL AlwaysZero         ; a stub that always returns Z ($BB59)
  RET NZ
  LD A,C
  CP $3A
  JR NZ,BridgeNeedsItem
  LD A,(LastGift)            ; room $3A: the professor has an item, or the Formula
                          ; in hand
  OR A
  JR NZ,BridgeAtEnd
  LD A,(HeldItem)
  CP $0F
  JR Z,BridgeAtEnd
  RET
BridgeNeedsItem:
  LD A,(HeldItem)            ; room $19: the ACME Expanding Bridge in hand
  CP $0B
  RET NZ
BridgeAtEnd:
  LD A,(Hero)            ; the explorer at the left end X $2C-$35 or the right
                          ; end X $B2-$B7?
  CP $2C
  RET C
  CP $B8
  RET NC
  CP $36
  JR C,BridgeStart
  CP $B2
  RET C
BridgeStart:
  PUSH AF                 ; BridgeState 1, or $10 reversed from the right end
  XOR A
  LD (BridgeReverse),A
  POP AF
  LD (HL),$01
  CP $7A
  RET C
  LD (HL),$10
  LD A,$01
  LD (BridgeReverse),A
  RET
BridgeDraw:
  LD E,A                  ; every fourth pass: the next tile of row 11
  AND $7F
  LD HL,TileMap+$0168
  DEC A
  LD C,A
  LD B,$00
  LD A,(PassCount)
  AND $03
  RET NZ
  ADD HL,BC
  BIT 7,E
  JR Z,BridgePlainTile
  LD A,L
  AND $03
  EXX
  LD L,A
  LD H,$00
  LD DE,BridgeTiles
  LD A,(Room)
  CP $3A
  JR NZ,BridgePickTile
  LD DE,BridgeTiles3A
BridgePickTile:
  ADD HL,DE
  LD A,(HL)
  EXX
  JR BridgeWrite
BridgePlainTile:
  LD C,$07                ; tile $07, or $BF in room $3A
  LD A,(Room)
  CP $3A
  JR NZ,BridgeTileA
  LD C,$BF
BridgeTileA:
  LD A,C
BridgeWrite:
  CALL SetTile            ; write the tile; then step BridgeState
  LD HL,BridgeState
  LD A,(BridgeReverse)
  OR A
  JR NZ,BridgeReverseStep
  LD A,(HL)
  AND $7F
  CP $10
  INC (HL)
  RET C
  BIT 7,(HL)
  JR NZ,BridgeDone
  DEC (HL)
  LD A,(Hero)
  CP $BA
  RET C
  LD (HL),$81
  RET
BridgeDone:
  LD (HL),$00             ; BridgeState = 0
  RET
BridgeReverseStep:
  LD A,(HL)
  DEC (HL)
  AND $7E
  RET NZ
  LD A,(HL)
  CP $80
  JR Z,BridgeDone
  INC (HL)
  LD A,(Hero)
  CP $30
  RET NC
  LD (HL),$90
  RET

; The tiles of the bridge's second sweep: 4 for room $19, 4 for room $3A
;
; Indexed by the column & 3 in BridgeEffect $BA97. Room $19: $97, $9A, $9D,
; $9E; room $3A ($BB55): $81 x 4. Witness: rzx08000, rzx12000 read the first
; four, rzx42000 the second four.
BridgeTiles:
  INCBIN "res/tables/bridge-tiles.bin",$0000,4
BridgeTiles3A:
  INCBIN "res/tables/bridge-tiles.bin",$0004,4

  ORG $BC73

; Room $10: play the Flute at one spot and a rope grows down through the floor
;
; Called by ItemsPass in room $10, IX = the explorer. Does nothing when
; RopeCount $5C24 is $0D (the rope is whole) or the Flute is not in hand
; (HeldItem $5B98 = $0C). With the explorer at Y $48 or $46 and X $28-$33: his
; facing bit set, Y rocks between $46 and $48 by PassCount bit 0, and every
; fourth pass status 6 (Status6Entry $A5F0) and RopeCount + 1; from count 6 on
; the rope tiles $98, $99 (columns 8 and 9) are written into the tile map at
; $F928 + 32 x (12 - count) through $9A52: rows 15 up to 10, the rope growing
; up; at count $0C the status is cleared ($AE84). The room set-up ($98ED) reads
; RopeCount when room $1C is entered and writes the rope tiles $98, $99 into
; columns 8 and 9 of rows 0-11 of room $1C's tile map ($F808 on); every room
; entry then clears RopeCount ($9907), so room $1C must be the next room
; entered.
;
; Witness: rzx10000 and gameover stand at Y $46 / $48 with the Flute ($BC8A,
; once each) but never at X $28-$33: the rope ($BC91 on) is not executed in any
; recording (c1, explorers, gameover, the 31 rzx builds). SK called it a
; seesaw.
;
; Witness: L1 674 (gameover, rzx, rzx).
RopeTrick:
  LD HL,RopeCount
  LD A,(HL)
  CP $0D
  RET Z
  LD A,(HeldItem)
  CP $0C
  RET NZ
  LD A,(IX+$01)
  CP $48
  JR Z,RopeSpot
  CP $46
  RET NZ
RopeSpot:
  LD E,A                  ; X $28-$33
  LD A,(IX+$00)
  CP $34
  RET NC
  CP $28
  RET C
  SET 7,(IX+$03)          ; the explorer plays: facing bit, Y $46 / $48
  LD A,(PassCount)
  AND $01
  JR NZ,RopeGrow
  LD (IX+$01),$46
  LD A,E
  CP $48
  JR Z,RopeGrow
  LD (IX+$01),$48
RopeGrow:
  LD A,(PassCount)            ; every fourth pass: status 6, RopeCount + 1
  AND $03
  RET NZ
  LD A,$06
  LD (Status),A
  LD A,(HL)
  INC (HL)
  CP $0C
  JP Z,ClearStatus
  SUB $06
  RET C
  LD C,A                  ; from count 6: two rope tiles into row 9 + 12 -
                          ; count
  LD A,$06
  SUB C
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,TileMap+$0128
  ADD HL,DE
  PUSH HL
  LD A,$98
  CALL SetTile
  POP HL
  INC HL
  LD A,$99                ; the second tile $99
  JP SetTile
