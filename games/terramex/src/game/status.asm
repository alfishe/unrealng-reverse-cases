; --------------------------------------------------------------------------------------------------------------------
; status.asm: The hero's statuses: jumps, rides, poses and deaths, one handler each
; --------------------------------------------------------------------------------------------------------------------

  ORG $A6CC

; Run the handler of the hero's status $5C06 (SK, renamed)
;
; Status 0: return. Else the word StatusHandlers $A72E[status - 1] is jumped to
; with C = $FF and the return into HeroUpdate $A3E1 still on the stack: every
; handler starts with POP (or ends without returning there), so the rest of the
; update is skipped. Called only from HeroUpdate ($A40C): 9430 dispatches in
; c1, explorers, gameover and 26 rzx segments.
;
; Witness: L1 26144 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
StatusDispatch:
  LD A,(Status)
  OR A
  RET Z
  LD C,$FF
  DEC A
  ADD A,A
  LD L,A
  LD H,$00
  PUSH DE
  LD DE,StatusHandlers
  ADD HL,DE

; Jump to the word at HL, if it is not 0
;
; HL = a table entry, DE on the stack. Pops DE, returns when the word is 0,
; else jumps to it. Shared by StatusDispatch $A6CC and the room handler
; dispatch $B7DD.
;
; Witness: L1 35947 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
JumpThroughWord:
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  POP DE
  LD A,H
  OR L
  RET Z
  JP (HL)

; The item the hero thinks of in each room: 72 bytes, a row a level, $FF none
;
; Read only by Think $AB6E (status 10, the T key): ThinkHints[room] goes to
; $5B9B and chooses BrightIdea $ABC7 (an item) or NoIdea $ABD9 ($FF). Written
; by GameInit (rooms $17, $1A = $FF, $0F = 7), by $98E9 (room $0F = 6, in room
; $10) and by Room1ADeath $A88F (rooms $17, $1A = $0C). No recording ran Think,
; so the reads are known only from the code. The items fit the rooms' handlers:
; room $1D = 9 (the barrel of BarrelSpot $AA3C), room $14 and $08 = $0A (Hover
; $AD32), room $0F = 7 (BalloonRide $AC35).
ThinkHints:
  INCBIN "res/tables/think-hints.bin",$0000,72

; The handlers of statuses 1-33 for StatusDispatch $A6CC (SK)
;
; Word N - 1 is status N. Where a status is set is said at each handler.
StatusHandlers:
  DEFW JumpArc            ; 1: the forced jump after three refusals (JumpArc)
  DEFW JumpArc            ; 2: the jump (fire)
  DEFW JumpArc            ; 3: the hop out of the ladder top in room $18
  DEFW Hover              ; 4: hover with item $0A
  DEFW BounceUp           ; 5: bounce up
  DEFW Status6Entry       ; 6: stay, animate only
  DEFW BalloonRide        ; 7: in the balloon
  DEFW BalloonRide        ; 8: in the balloon with item 6
  DEFW BalloonCrash       ; 9: the balloon falls
  DEFW Think              ; 10: think
  DEFW BrightIdea         ; 11: a bright idea
  DEFW NoIdea             ; 12: no idea
  DEFW BarrelSpot         ; 13: at the barrel spot
  DEFW BarrelRide         ; 14: the barrel ride (item 9)
  DEFW BarrelRideShort    ; 15: the barrel ride (item $1C), fatal
  DEFW BarrelRideLong     ; 16: the barrel ride (item $1B), fatal
  DEFW SinkInMud          ; 17: sink into the mud
  DEFW LoseLifeWait       ; 18: dying, the life is lost after 50 passes
  DEFW LiftUp             ; 19: lift up
  DEFW LiftDown           ; 20: lift down
  DEFW RideObject4        ; 21: ride object 4
  DEFW Teleport           ; 22: teleport
  DEFW SilentDeath        ; 23: the room $20 pad's death
  DEFW CreatureDeath      ; 24: the creature contact death
  DEFW Room1ADeath        ; 25: the room $1A death
  DEFW FallDeath          ; 26: the fall death
  DEFW Room43Anim         ; 27: room $43 animation
  DEFW Room2DAnim         ; 28: room $2D animation
  DEFW Frozen             ; 29: frozen
  DEFW LookIntoTelescope  ; 30: look into the telescope
  DEFW TelescopeView      ; 31: the telescope view
  DEFW DrinkPose          ; 32: room $2E, item 4 used
  DEFW FlashPose          ; 33: room $47, item 1 used

; Status 33: hold frame $3F for 64 passes, then the next step of room $47
;
; Set by ExplorerRoom47 $B18A when the hero uses item 1 at its spot. $5C07
; counts; at bit 6 RoomStep $5C41 + 1 and status 0. Not executed in any
; recording (c1, explorers, gameover, rzx x31); known only from the code.
;
; Witness: L1 0 ().
FlashPose:
  POP HL
  LD HL,StatusTimer
  INC (HL)
  LD (IX+$02),$3F
  BIT 6,(HL)
  RET Z
  LD HL,RoomStage
  INC (HL)
  JP ClearStatus

; Status 32: cycle the frames $3D-$3F (room $2E, item 4 used)
;
; Set by ExplorerRoom2E $B263. Frame $3D + (a 0, 1, 2, 2, 1, 0 pattern of
; $5C07); it never ends the status itself: ExplorerRoom2E does after its
; creature's frame list. Not executed in any recording; known only from the
; code.
;
; Witness: L1 0 ().
DrinkPose:
  POP HL
  LD HL,StatusTimer
  INC (HL)
  LD A,(HL)
  AND $07
  BIT 2,A
  JR Z,DrinkPoseClip
  LD A,(HL)
  CPL
  AND $03
DrinkPoseClip:
  CP $03
  JR NZ,DrinkPoseSet
  LD A,$02
DrinkPoseSet:
  ADD A,$3D
  LD (IX+$02),A
  RET

; The frames of status 30 (looking into the telescope), $FF end
;
; Read by LookIntoTelescope $A822 through NextFrame $ABDE, each frame for 2
; passes. Never read in a recording (room $12 not reached).
TelescopeFrames:
  INCBIN "res/anims/telescope.bin",$0000,26

; Status 31: the asteroid in space and the time left to the collision
;
; Set by LookIntoTelescope $A822. On the first pass: the hero hidden (frame
; $7F), room $28 (the space background) set up ($9855 with A = $28), object 4
; ($5B14) = the asteroid at X $75, Y = 2 x (40 - days), frame $75: the fewer
; the days ($5BFB) the lower it stands. CollisionText $B07C is printed at $48A2
; ($94F9, colour $0F), the days, hours and minutes ($5BFB, $5BFC, $5BFD) at
; $48C7, $48D0 and $48DB ($90E1). Each later pass reprints the numbers, until
; $5C07 reaches $80: then room $12 again and status 0.
;
; Evidence of the countdown order: the text puts DAYS at column 2 and the first
; number ($5BFB) at column 7; c1 frame 23500 holds $1E, $17, $0B at $5BFB-$5BFD
; (30 days, 23 hours, 11 minutes). Not executed in any recording; known only
; from the code.
;
; Witness: L1 0 ().
TelescopeView:
  POP HL
  LD IY,ObjectSlot4
  LD HL,StatusTimer
  LD A,(HL)
  OR A
  JR NZ,TelescopeWait
  INC (HL)
  LD (IX+$02),$7F
  LD A,$28
  CALL SetUpRoom
  LD (IY+$00),$75
  LD A,(CountdownDays)
  SUB $28
  NEG
  ADD A,A
  LD (IY+$01),A
  LD (IY+$02),$75
  LD DE,CollisionText
  LD HL,Screen+2210
  LD A,$0F
  EX AF,AF'
  CALL PrintString
TelescopeNumbers:
  LD A,(CountdownDays)            ; days, hours, minutes
  LD DE,Screen+2247
  CALL PrintByte
  LD A,(CountdownHours)
  LD DE,Screen+2256
  CALL PrintByte
  LD A,(CountdownMinutes)
  LD DE,Screen+2267
  JP PrintByte
TelescopeWait:
  LD A,(CountdownDays)            ; 128 passes, then back to room $12
  SUB $28
  NEG
  ADD A,A
  LD (IY+$01),A
  INC (HL)
  LD A,(HL)
  CP $80
  JR NZ,TelescopeNumbers
  LD A,$12
  CALL SetUpRoom
  JP ClearStatus

; Status 30: the hero bends to the telescope, then the view
;
; Set by TelescopeRoom $B16A. Plays TelescopeFrames $A79F (Status28Anim's tail
; $A82C); at the end status 31 (TelescopeView $A7B9). Not executed in any
; recording.
;
; Witness: L1 0 ().
LookIntoTelescope:
  POP HL
  LD DE,TelescopeFrames
  JR FrameListStatus

; Status 28: the frame list of room $2D, then frozen
;
; Set by the room $2D handler ($B3A8, GD). Plays Room2DFrames $A83B; at its end
; the status steps to 29 (Frozen $A90E) and the timer is cleared. Evidence:
; rzx16000 frames 1721-1821 (43 passes, once to the end).
;
; Witness: L1 43 (rzx).
Room2DAnim:
  POP HL
  LD DE,Room2DFrames
; This entry point is used by the routine at LookIntoTelescope.
FrameListStatus:
  CALL NextFrame          ; DE = a frame list: one frame, at the end the next
                          ; status
  CP $FF
  JP NZ,SetHeroFrame
  LD HL,Status
  INC (HL)
  JP ClearStatusTimer

; The frames of status 28, $FF end
Room2DFrames:
  INCBIN "res/anims/room-2d.bin",$0000,22

; Status 27: a frame list, then item $1D in use and points
;
; Set by the room $43 handler ($B720, GD). Plays Room43Frames $A86E; at the end
; $5B98 = $1D, $9E5D, $BCF2 with DE = $004B (75), status 0. Evidence: rzx38000
; frames 2-135 (50 passes).
;
; Witness: L1 50 (rzx).
Room43Anim:
  POP HL
  LD DE,Room43Frames
  CALL NextFrame
  CP $FF
  JP NZ,SetHeroFrame
  LD A,$1D
  LD (HeldItem),A
  CALL DrawPortrait
  LD DE,$004B
  CALL AddScore
  JP ClearStatus

; The frames of status 27, $FF end
Room43Frames:
  INCBIN "res/anims/room-43.bin",$0000,26

; Status 26: the fall death: frame $1C, sound 0, then dying
;
; Set when the hero lands after 20 fall passes or more (HeroLand $A5B9), on
; tile $A5 (HeroTileChecks $A102), when the balloon lands falling (BalloonCrash
; $AC1A) and by the creatures of room $2E (ExplorerRoom2E $B2C5).
; FallDeathFrames $A8BF, then sound 0 and status 18 (StartDying $AAF0).
; Evidence: gameover frames 1363-1371 (the last life), rzx10000, rzx24000.
;
; Witness: L1 9 (gameover, rzx, rzx).
FallDeath:
  LD DE,FallDeathFrames
  LD C,$00
  JR DeathFrames

; Status 25: the death in room $1A; the thought for rooms $17 and $1A becomes
; item $0C
;
; Set by the room $1A handler ($B5CE, GD). ThinkHints $A6E6 of rooms $17 and
; $1A = $0C, then Room1ADeathFrames $A8E6, sound 4, status 18. Evidence:
; rzx10000 frames 1943-1958.
;
; Witness: L1 7 (rzx).
Room1ADeath:
  LD A,$0C
  LD (ThinkHints+$0017),A
  LD (ThinkHints+$001A),A
  LD DE,Room1ADeathFrames
  LD C,$04
  JR DeathFrames

; Status 24: the death by a creature's touch, sound 3 every pass
;
; Set by HitExplorer $C0F9 (a creature's touch, not standing) and by the beam
; hit $9262 (RoomEffects: within the beam's X span and 12 rows, status below
; 4). CreatureDeathFrames $A8E0 with sound 3 each pass, then status 18.
; Evidence: rzx06000, rzx22000, rzx32000 (33 passes).
;
; Witness: L1 33 (rzx, rzx, rzx).
CreatureDeath:
  LD DE,CreatureDeathFrames
  LD A,$03
  CALL PlaySound
  JR DeathFrames

; Status 23: a death with no sound: the teleport pad of room $20, the radiation
; of room $3C, the creature of room $39
;
; Set by Teleport $A8EA in room $20, by room $3C's script without the pills
; ($B796) and by room $39's creature without the Silver Cross ($B518).
; SilentDeathFrames $A8C1 with no sound (C = $FF from StatusDispatch), then
; status 18. Not executed in any recording; a clone probe
; (work/stage2/probe_points.py C: the RZX state at 44000, PillsTaken $5C3F = 0,
; room $3C entered from $3D) shows it: status 23 at frame 70 (RoomStage $5C41 =
; $15), status 18 at 225, Lives 3 -> 2 and the restart in room $3B (the last
; checkpoint) at 355.
;
; Witness: L1 0 ().
SilentDeath:
  LD DE,SilentDeathFrames

; Play a death's frame list; at its end sound C (none for $FF) and status 18
;
; DE = the list, C = the sound. Shared by statuses 23-26.
;
; Witness: L1 49 (gameover, rzx, rzx, rzx, rzx, rzx).
DeathFrames:
  CALL NextFrame
  POP HL
  CP $FF
  JP NZ,SetHeroFrame
  LD A,C
  CP $FF
  CALL NZ,PlaySound
  LD A,$12
  JP StartDying

; The death frame lists: status 26 ($1C), 23, 24, 25, each $FF ended
FallDeathFrames:
  INCBIN "res/anims/deaths.bin",$0000,2
SilentDeathFrames:
  INCBIN "res/anims/deaths.bin",$0002,31
CreatureDeathFrames:
  INCBIN "res/anims/deaths.bin",$0021,6
Room1ADeathFrames:
  INCBIN "res/anims/deaths.bin",$0027,4

; Status 22: the teleport pads of rooms $30 and $3D; the pad of room $20 kills
;
; Set by TeleportPadCheck $B03B. First pass ($5C07 = 0): the lift is reset to
; room $1F, Y $50 ($5B9E, $5B9F). Room $30 sends to room $3D, room $3D to room
; $20, each only while $5C44 is not 0 (else nothing happens and the status
; stays); the destination goes into TeleportDest $A959. Room $20: status 23
; (SilentDeath $A8A8).
;
; Witness: L1 36 (rzx, rzx).
Teleport:
  LD A,(StatusTimer)
  OR A
  JR NZ,TeleportFrame
  LD A,$1F
  LD (LiftRoom),A
  LD A,$50
  LD (LiftY),A
  LD A,(Room)
  LD C,$BD
  CP $30
  JR Z,TeleportStep
  LD C,$A0
  CP $3D
  JR Z,TeleportStep
  LD A,$17
  LD (Status),A

; Status 29: nothing; the hero waits for a room handler
;
; POP HL, RET: the update ends. Set by GameOver's path $938D (GB: the last
; life, the space scene), the room $2D handler ($B6FB) and ExplorerRoom46
; $B2EB; Room2DAnim $A828 steps into it. Evidence: 413 passes in gameover and 3
; rzx segments.
;
; Witness: L1 413 (gameover, rzx, rzx, rzx).
Frozen:
  POP HL
  RET

; Teleport, continued: the pad's frame list with the jump to the other room
;
; Reached from Teleport $A8EA ($A901, $A907, $A8EE). Plays TeleportFrames
; $A955; the byte with bit 7 set is the room: $5C07 skips it, the room is
; looked up in TeleportPads $B073 for the arrival Y and X, PadLatch $B072 = X
; (no new trigger on arrival) and the room is set up ($9855). The list's $FF
; ends the status. Evidence: two teleports (rzx24750 frames 732-780, rzx34000
; frames 1461-1512). The cut puts an entry here so that Frozen $A90E holds only
; its two instructions.
;
; Witness: L1 2 (rzx, rzx).
TeleportStep:
  LD A,(CrystalPlaced)
  OR A
  RET Z
  LD A,C
  LD (TeleportDest),A
; This entry point is used by the routine at Teleport.
TeleportFrame:
  POP HL
  LD DE,TeleportFrames
  CALL NextFrame
  BIT 7,A
  JR Z,TeleportShow
  CP $FF
  JP Z,ClearStatus
TeleportJump:
  LD HL,StatusTimer             ; the room byte: go there
  INC (HL)
  AND $7F
  LD (Room),A
  PUSH AF
  LD HL,TeleportPads
  LD B,$03
TeleportFindPad:
  CP (HL)
  JR Z,TeleportArrive
  INC HL
  INC HL
  INC HL
  DJNZ TeleportFindPad
TeleportArrive:
  INC HL                  ; Y, X of the destination pad
  LD A,(HL)
  LD (IX+$01),A
  INC HL
  LD A,(HL)
  LD (IX+$00),A
  LD (PadLatch),A
  POP AF
  JP SetUpRoom
TeleportShow:
  LD (IX+$02),A
  RET

; The teleport's frames, the destination room ($80 + room) patched in, $FF end
TeleportFrames:
  INCBIN "res/anims/teleport.bin",$0000,4
TeleportDest:
  INCBIN "res/anims/teleport.bin",$0004,1
TeleportFramesArrive:
  INCBIN "res/anims/teleport.bin",$0005,5

; Status 21: the hero takes object 4's place, frame $2D
;
; Set by the room $3F handler ($B45A, GD). The hero's X, Y = object 4's ($5B14)
; every pass. Evidence: 418 passes (rzx28000, rzx32750, rzx34000).
;
; Witness: L1 418 (rzx, rzx, rzx).
RideObject4:
  LD HL,(ObjectSlot4)
  LD (Hero),HL
  LD (IX+$02),$2D
  POP AF
  RET

; Status 19: the lift up, 2 pixels a pass
;
; Set by LiftPlatform $AF81 (up on the platform). In room $1F it stops at its
; stop (LiftAtStop $A9A9) and calls $9AA1 (GB). Y - 2; above the top the room
; above (ExitUp $A69B) and the lift's Y and room ($5B9F, $5B9E) follow; $5B9F =
; Y + 8. Not executed in any recording.
;
; Witness: L1 0 ().
LiftUp:
  POP HL
  LD A,(Room)
  CP $1F
  JR NZ,LiftUpMove
  CALL LiftAtStop
  RET Z
LiftUpMove:
  LD A,(Room)
  CP $1F
  CALL Z,SaveRespawnPoint
  LD A,(IX+$01)
  SUB $02
  JR NC,LiftMoveY
  CALL ExitUp
  LD A,(IX+$01)
  LD (LiftY),A
  SUB $08
  LD (IX+$01),A
  LD A,(Room)
  LD (LiftRoom),A

; The lift is in the hero's room ($5B9E = $5C01)
;
; Witness: L1 4 (rzx, rzx).
LiftSetRoom:
  LD A,(Room)
  LD (LiftRoom),A
  RET
; This entry point is used by the routines at LiftUp and LiftDown.
LiftMoveY:
  LD (IX+$01),A           ; the hero's Y, the lift 8 lower
  ADD A,$08
  LD (LiftY),A

; Is the lift at its stop in this room? Then status 0
;
; LiftStops $A9E6 gives a stop Y for rooms $1F, $2B, $37, $43: when the room is
; listed and $5B9F equals it, status 0 (Z); not listed returns NZ.
;
; Witness: L1 263 (rzx, rzx).
LiftAtStop:
  LD HL,LiftStops
  LD B,$04
  LD A,(Room)
LiftStopLoop:
  CP (HL)
  JR Z,LiftStopFound
  INC HL
  INC HL
  DJNZ LiftStopLoop
  XOR A
  INC A
  RET
LiftStopFound:
  INC HL
  LD A,(LiftY)
  CP (HL)
  RET NZ
  JP ClearStatus

; Status 20: the lift down, 2 pixels a pass
;
; Set by LiftPlatform $AF81 (down on the platform). In room $43 it stops at Y
; $68. Y + 2; at $62 the room below (ExitDown $A6AE). Evidence: rzx20000 frames
; 628-805, rzx36000 frames 334-937 (220 passes).
;
; Witness: L1 220 (rzx, rzx).
LiftDown:
  POP HL
  LD A,(Room)
  CP $43
  JR NZ,LiftDownMove
  CALL LiftAtStop
  RET Z
LiftDownMove:
  LD A,(IX+$01)
  ADD A,$02
  CP $62
  JR C,LiftMoveY
  CALL ExitDown
  LD A,(IX+$01)
  ADD A,$08
  LD (LiftY),A
  JR LiftSetRoom

; The lift's stop in each room of its shaft: room, Y of $5B9F
;
; Rooms $1F, $2B, $37, $43 (column 7, levels 2-5).
LiftStops:
  INCBIN "res/tables/lift-stops.bin",$0000,8

; Status 18: wait 50 passes, then a life is lost: game over or the respawn (SK)
;
; $5C07 counts; at 50: $5C2A = $32 (the main loop's $902E sees it and runs the
; respawn $9090), Lives $5B97 - 1; 0 goes to $9372 (game over: the space
; scene), else $9E96. Set by StartDying $AAF0. Evidence: gameover frames
; 1374-1502 (the last life), 5 rzx segments. The POKE 43517,182 (SK, the
; "infinite lives" POKE) changes DEC (HL) at $A9FD.
;
; Witness: L1 292 (gameover, rzx, rzx, rzx, rzx, rzx).
LoseLifeWait:
  POP HL
  LD HL,StatusTimer
  INC (HL)
  LD A,(HL)
  CP $32
  RET NZ
  LD (LifeLost),A
  LD HL,Lives
LifeLossOp:
  DEC (HL)                ; Lives - 1: GameEntry makes it OR A when
                          ; InfiniteLives is 1
  JP Z,LoseGame
  JP DrawSpareLives

; Status 17: sink one row into the mud
;
; Set by HeroTileChecks $A102 after 50 passes on tile $BC or $BD. SinkFrames
; $AA22, then $5C03 = 3, Y onto the next row down (+8) and status 0. Not
; executed in any recording.
;
; Witness: L1 0 ().
SinkInMud:
  POP HL
  LD DE,SinkFrames
  CALL NextFrame
  CP $FF
  JP NZ,SetHeroFrame
  LD A,$03
  LD (RefuseCount),A
  LD A,(IX+$01)
  AND $F8
  ADD A,$08
  LD (IX+$01),A
  JP ClearStatus

; The frames of status 17, $FF end
SinkFrames:
  INCBIN "res/anims/sink.bin",$0000,26

; Status 13: at the barrel spot of room $1D; the barrel item chooses the ride
;
; Set by StatusZeroTriggers $AF3B (room $1D, left at the spot). Frame $17,
; facing left; right gives up (status 0). After 5 passes: item 9 in use gives
; status 14, item $1C status 15, item $1B status 16 (sound 1); any other item
; waits. Evidence: rzx16000 frames 479-491 (item 9).
;
; Witness: L1 6 (rzx).
BarrelSpot:
  POP HL
  LD (IX+$02),$17
  RES 7,(IX+$03)
  BIT 0,E
  JP NZ,ClearStatus
  LD HL,StatusTimer
  LD A,(HL)
  CP $05
  JR Z,BarrelChoose
  INC (HL)
  RET
BarrelChoose:
  LD A,(HeldItem)
  LD C,$0E
  CP $09
  JR Z,BarrelGo
  INC C
  CP $1C
  JR Z,BarrelGo
  INC C
  CP $1B
  RET NZ
BarrelGo:
  LD A,C
  CALL SetStatus
  LD A,$01
  JP PlaySound

; Status 14: the ride in barrel item 9: 84 passes along BarrelArc
;
; X + 2 a pass, Y - BarrelArc $AAFA[$5C07], facing right, the frame up to $19,
; from pass 40 frame $1A. At pass 84 status 0. Evidence: rzx16000 frames
; 508-745.
;
; Witness: L1 85 (rzx).
BarrelRide:
  POP HL
  LD DE,BarrelArc
  LD HL,StatusTimer
  LD A,(HL)
  CP $54
  JP Z,ClearStatus
; This entry point is used by the routine at BarrelRideShort.
BarrelRideStep:
  INC (HL)                ; also status 15's
  LD L,A
  LD H,$00
  ADD HL,DE
  LD A,(IX+$01)
  SUB (HL)
  LD (IX+$01),A
  INC (IX+$00)
  INC (IX+$00)
  SET 7,(IX+$03)
  LD A,(IX+$02)
  CP $19
  JR Z,BarrelRideFrame
  INC (IX+$02)
BarrelRideFrame:
  LD A,(StatusTimer)
  CP $28
  RET C
  LD (IX+$02),$1A
  RET

; Status 15: the ride in item $1C: BarrelShortArc, fatal after 32 passes
;
; As BarrelRide $AA6F with BarrelShortArc $AB4E; at pass 32 frame $1C and
; status 18. Not executed in any recording.
;
; Witness: L1 0 ().
BarrelRideShort:
  POP HL
  LD DE,BarrelShortArc
  LD HL,StatusTimer
  LD A,(HL)
  CP $20
  JR NZ,BarrelRideStep
  LD (IX+$02),$1C
  JP StartDying

; Status 16: the ride in item $1B: on to the next room, fatal
;
; X + 2 a pass, Y - 1 on every other pair of passes; after 100 passes the room
; to the right (ExitRight $A671) at X 8, Y 8, frame $1B, then status 18. Not
; executed in any recording.
;
; Witness: L1 0 ().
BarrelRideLong:
  POP HL
  SET 7,(IX+$03)
  LD A,(IX+$02)
  CP $19
  JR Z,BarrelLongStep
  INC (IX+$02)
BarrelLongStep:
  LD HL,StatusTimer
  LD A,(HL)
  INC (HL)
  INC C
  INC (IX+$00)
  INC (IX+$00)
  SRL A
  BIT 1,A
  JR Z,BarrelLongEnd
  DEC (IX+$01)
BarrelLongEnd:
  CP $32
  RET NZ
  CALL ExitRight
  LD (IX+$00),$08
  LD (IX+$01),$08
  LD (IX+$02),$1B

; Status 18: the hero dies (LoseLifeWait counts down)
;
; Witness: L1 7 (gameover, rzx, rzx, rzx, rzx, rzx).
StartDying:
  LD A,$12
  LD (Status),A

; $5C07 = 0
;
; Witness: L1 8 (gameover, rzx, rzx, rzx, rzx, rzx, rzx).
ClearStatusTimer:
  XOR A
  LD (StatusTimer),A
  RET

; Y steps of status 14, one a pass (84), signed
BarrelArc:
  INCBIN "res/tables/barrel-arcs.bin",$0000,84
BarrelShortArc:
  INCBIN "res/tables/barrel-arcs.bin",$0054,32

; Status 10: the hero thinks; ThinkHints decides the idea
;
; Set by ThinkKey $B02E (T). ThinkFrames $ABEB; at the end the thought's place:
; $5B9A = Y (- $18 when Y >= $18), $5B99 = X - $18 or + $18 (the side the hero
; faces; turned at the edges), $5B9B = ThinkHints $A6E6[room]; status 12
; (NoIdea) for $FF, else 11 (BrightIdea). Not executed in any recording.
;
; Witness: L1 0 ().
Think:
  POP HL
  LD DE,ThinkFrames
  CALL NextFrame
  CP $FF
  JR NZ,SetHeroFrame
  LD A,(IX+$01)
  CP $18
  JR C,ThinkPlaceY
  SUB $18
ThinkPlaceY:
  LD (Thought+1),A
ThinkPlaceX:
  LD A,(IX+$00)
  JR NC,ThinkHint
  BIT 7,(IX+$03)
  JR NZ,ThinkPlaceRight
  SUB $18
  JR NC,ThinkHint
  SET 7,(IX+$03)
  JR ThinkPlaceX
ThinkPlaceRight:
  ADD A,$18
  CP $E7
  JR C,ThinkHint
  RES 7,(IX+$03)
  SCF
  JR ThinkPlaceX
ThinkHint:
  LD (Thought),A
  LD A,(Room)
  LD L,A
  LD H,$00
  LD DE,ThinkHints
  ADD HL,DE
  LD A,(HL)
  LD (Thought+2),A
  LD C,$0C
  CP $FF
  JR Z,ThinkResult
  DEC C
ThinkResult:
  LD A,C
  JP SetStatus

; (IX+2) = A
;
; Witness: L1 133 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
SetHeroFrame:
  LD (IX+$02),A
  RET

; Status 11: the idea frames, then $5B9B = $FE and status 0
;
; IdeaFrames $ABF4. Not executed in any recording.
;
; Witness: L1 0 ().
BrightIdea:
  LD DE,IdeaFrames
; This entry point is used by the routine at NoIdea.
ThoughtFrames:
  POP HL                  ; shared with NoIdea
  CALL NextFrame
  CP $FF
  JR NZ,SetHeroFrame
  DEC A
  LD (Thought+2),A
  JP ClearStatus

; Status 12: the no-idea frames (head shaking), then $5B9B = $FE and status 0
;
; NoIdeaFrames $AC0D. Not executed in any recording.
;
; Witness: L1 0 ().
NoIdea:
  LD DE,NoIdeaFrames
  JR ThoughtFrames

; The next frame of the list at DE, timed by $5C07 (SK, renamed)
;
; A = DE[$5C07 / 2], $5C07 + 1: each frame lasts 2 passes; the lists end with
; $FF.
;
; Witness: L1 178 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
NextFrame:
  LD HL,StatusTimer

; The same with the counter at HL
;
; Called by $B638 (GD) with its own counter.
;
; Witness: L1 2050 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
NextFrameAt:
  LD A,(HL)
  INC (HL)
  SRL A
  LD L,A
  LD H,$00
  ADD HL,DE
  LD A,(HL)
  RET

; The frames of status 10, then 11, then 12, each $FF ended
ThinkFrames:
  INCBIN "res/anims/think.bin",$0000,9
IdeaFrames:
  INCBIN "res/anims/think.bin",$0009,25
NoIdeaFrames:
  INCBIN "res/anims/think.bin",$0022,13

; Status 9: the balloon falls; landing kills
;
; Set by BalloonRide $AC35 at the top of room 3 with item 7. Sinks as
; BalloonRide does ($ACC4); on the ground object 3 (the envelope) is hidden and
; status 26 (FallDeath $A888). Not executed in any recording.
;
; Witness: L1 0 ().
BalloonCrash:
  POP HL
  LD A,(Room)
  LD (BalloonInRoom),A
  CALL HeroTileChecks
  LD A,(IY+$03)
  OR A
  JP NZ,BalloonSink
  LD A,$7F
  LD (ObjectSlot4+2),A
  LD A,$1A
  JP SetStatus

; Statuses 7 and 8: in the balloon: rise with item 6 or 7, else sink and step
; out
;
; Set by StatusZeroTriggers $AF3B (the hero at the balloon), status 8 here.
; $5C27 = the room (the balloon goes with the hero), frame $7F (the hero is
; drawn inside the basket by BalloonRoom $AFD7). In the air (probe +3 not 0)
; left and right move 2 pixels (right not in status 7). Item 6 in use: status
; 8, item 7: status 7; both rise 1 pixel a pass; at the top the room above, in
; room 3 status 8 hovers and status 7 becomes 9 (BalloonCrash $AC1A). Other
; items: the balloon sinks 2 pixels a pass (the room below at $66) and on the
; ground left or right steps out (status 0). $5C25 / $5C26 keep the balloon's X
; and Y. Evidence: rzx14000 frames 696-1104 (452 passes, item 6); the screen of
; rzx14000 frame 750 shows the balloon.
;
; Witness: L1 452 (rzx, rzx).
BalloonRide:
  POP HL
  LD A,(Room)
  LD (BalloonInRoom),A
  LD A,$7F
  LD (IX+$02),A
  PUSH DE
  CALL HeroTileChecks
  POP DE
  LD A,(IY+$03)
  OR A
  JP Z,BalloonItem
  LD A,(Status)
  CP $07
  LD A,(IX+$00)
  JR Z,BalloonLeft
  BIT 0,E
  JR Z,BalloonLeft
  BIT 0,(IY+$01)
  JR NZ,BalloonLeft
  INC A
  INC A
  CP $E4
  JR C,BalloonLeft
  DEC A
  DEC A
BalloonLeft:
  BIT 1,E
  JR Z,BalloonSetX
  BIT 0,(IY+$00)
  JR NZ,BalloonSetX
  SUB $02
  CP $08
  JR NC,BalloonSetX
  ADD A,$02
BalloonSetX:
  LD (BalloonX),A
  LD (IX+$00),A
BalloonItem:
  LD A,(HeldItem)            ; item 6 or 7 lifts it
  CP $06
  JR Z,BalloonItem6
  CP $07
  JR Z,BalloonItem7
  JR BalloonSink
BalloonItem6:
  LD A,$08
  LD (Status),A
  JR BalloonRise
BalloonItem7:
  LD A,$07
  LD (Status),A
BalloonRise:
  LD A,(IX+$01)
  DEC A
  CP $18
  JR NC,BalloonSetY
  LD C,A
  LD A,(Room)
  CP $03
  LD A,C
  JR Z,BalloonTop
  CALL ExitUp
  LD A,(IX+$01)
BalloonSetY:
  LD (IX+$01),A
  LD (BalloonY),A
  RET
BalloonTop:
  LD A,(Status)            ; room 3's top: item 6 hovers, item 7 bursts
  CP $08
  RET Z
  LD A,$09
  LD (Status),A
  RET
; This entry point is used by the routine at BalloonCrash.
BalloonSink:
  LD A,(IY+$03)
  OR A
  JR Z,BalloonGround
  LD A,(IX+$01)
  ADD A,$02
  LD (IX+$01),A
  LD A,(IX+$01)
  CP $66
  JR C,BalloonSinkY
  PUSH IX
  CALL ExitDown
  POP IX
  LD A,(IX+$01)
  ADD A,$18
  LD (IX+$01),A
BalloonSinkY:
  LD A,(IX+$01)
  LD (BalloonY),A
  RET
BalloonGround:
  LD A,(IX+$01)           ; on the ground: left or right steps out
  LD (BalloonY),A
  LD A,E
  AND $03
  RET Z
  AND $02
  JR NZ,BalloonStepLeft
  LD A,(IX+$00)
  ADD A,$02
  CP $E7
  RET NC
  LD (IX+$00),A
  JP ClearStatus
BalloonStepLeft:
  LD A,(IX+$00)
  SUB $02
  RET C
  LD (IX+$00),A
  JP ClearStatus

; Status 5: rise 4 pixels a pass; on a floor the jump arc
;
; Set by $BBD5 (GD), which puts the hero on top of an object, frame $0F. Y - 4;
; above the top the room above. When the probes find a floor under the feet:
; status 2 (JumpArc $ADAC). Evidence: gameover, rzx10000, rzx22000 (67 passes).
;
; Witness: L1 67 (gameover, rzx, rzx).
BounceUp:
  POP HL
  LD A,(IX+$01)
  DEC A
  DEC A
  DEC A
  DEC A
  JP M,ExitUp
  LD (IX+$01),A
  CALL HeroTileChecks
  LD A,(IY+$03)
  OR A
  RET NZ
  LD A,$02
  JP SetStatus

; Status 4: hover with item $0A, four directions (rooms $14 and $08)
;
; Set by HeroUpdate $A3E1 (StartHover $A42B). While $5B98 is $0A: frame $1D,
; right / left 2 pixels within 4..$E6, up 2 pixels (the room above at the top,
; except in room $08), down 2 pixels (room $14: not below Y $57; elsewhere the
; room below at $67). Another item ends it ($5C03 = 2, status 0). Evidence:
; 4908 passes in c1, explorers and rzx00000, starting near the beginning of
; play in room $14 (explorers frame 963); the frames are known from the code,
; what $1D shows needs the screen.
;
; Witness: L1 4908 (c1, explorers, rzx, rzx).
Hover:
  POP HL
  LD A,(HeldItem)
  CP $0A
  JR Z,HoverMove
  LD A,$02
  LD (RefuseCount),A
  JP ClearStatus
HoverMove:
  LD A,$1D
  LD (IX+$02),A
  BIT 0,E
  JR Z,HoverLeft
  LD A,(IX+$00)
  ADD A,$02
  CP $E7
  JR NC,HoverLeft
  SET 7,(IX+$03)
  LD (IX+$00),A
HoverLeft:
  BIT 1,E
  JR Z,HoverUp
  LD A,(IX+$00)
  SUB $02
  CP $04
  JR C,HoverUp
  RES 7,(IX+$03)
  LD (IX+$00),A
HoverUp:
  BIT 3,E
  JR Z,HoverDown
  LD A,(IX+$01)
  DEC A
  JP M,HoverTop
  DEC A
  JP M,HoverTop
  LD (IX+$01),A
  RET
HoverTop:
  LD A,(Room)
  CP $08
  RET Z
  JP ExitUp
HoverDown:
  BIT 2,E
  RET Z
  LD A,(IX+$01)
  ADD A,$02
  LD C,A
  LD A,(Room)
  CP $14
  LD A,C
  JR NZ,HoverDownExit
  CP $57
  RET NC
  LD (IX+$01),C
  RET
HoverDownExit:
  CP $67
  JP NC,ExitDown
  LD (IX+$01),A
  RET

; Statuses 1, 2, 3: the jump: 17 passes of JumpFrames and JumpRise (SK,
; renamed)
;
; The frame is JumpFrames $AE8D[$5C07]; at step 17 Y goes onto the row and
; status 0. Else JumpStepY $AE37 moves Y, then the direction $5C08 moves X 2
; pixels (right: the room to the right at $E7; left: the room to the left at X
; 2 or 1); a wall at the leading edge puts the position back. Status 2 is fire
; (StartJump $A465), 1 the jump off an edge after three refusals, 3 the hop out
; of room $18's ladder top (no direction). Evidence: 2391 passes in gameover
; and 23 rzx segments.
;
; Witness: L1 2391 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
JumpArc:
  POP HL
  LD DE,JumpFrames
  CALL FrameFromTable
  LD HL,StatusTimer
  LD A,(HL)
  INC (HL)
  CP $11
  JR NZ,JumpMove
  LD A,(IX+$01)
  AND $F8
  LD (IX+$01),A
  JP ClearStatus
JumpMove:
  CALL JumpStepY
  LD A,(JumpDirection)
  LD E,A
  AND $03
  RET Z
  BIT 0,E
  JR Z,JumpLeft
  LD A,(IX+$00)
  INC A
  INC A
  CP $E7
  JR C,JumpRightWall
  PUSH IX
  PUSH IY
  CALL ExitRight
  POP IY
  POP IX
  LD A,(IX+$00)
JumpRightWall:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (IX+$00),A
  PUSH HL
  CALL HeroTileChecks
  LD A,(IY+$01)
  POP HL
  OR A
  RET Z
  LD (IX+$00),L
  LD (IX+$01),H
  RET
JumpLeft:
  LD A,(IX+$00)
  DEC A
  JR Z,JumpLeftExit
  DEC A
  JR NZ,JumpLeftWall
JumpLeftExit:
  PUSH IX
  PUSH IY
  CALL ExitLeft
  POP IY
  POP IX
  LD A,(IX+$00)
JumpLeftWall:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (IX+$00),A
  PUSH HL
  CALL HeroTileChecks
  LD A,(IY+$00)
  POP HL
  OR A
  RET Z
  LD (IX+$00),L
  LD (IX+$01),H
  RET

; One step of the jump's height
;
; A = the step. JumpHoleCheck $AF09 first (the last step over a hole falls
; through). Y - JumpRise $AE9E[step]; above the top the room above, at $68 the
; room below (ExitDownSaved $AE6A). Then the probes: a floor under the feet
; ends the jump early (frame 2, status 0).
;
; Witness: L1 2366 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
JumpStepY:
  CALL JumpHoleCheck
  LD L,A
  LD H,$00
  LD BC,JumpRise
  ADD HL,BC
  LD A,(IX+$01)
  SUB (HL)
  JP P,JumpStepDown
  PUSH IX
  PUSH IY
  CALL ExitUp
  POP IY
  POP IX
  RET
JumpStepDown:
  CP $68
  JR NC,ExitDownSaved
  LD (IX+$01),A
  CALL HeroTileChecks
  LD A,(IY+$03)
  OR A
  RET NZ
  LD (IX+$02),$02
  JR ClearStatus

; A RET no code reaches
;
; After JR $AE84 at $AE67; no jump or call targets it (known only from the
; code).
JumpLoneRet:
  DEFB $C9

; ExitDown with IX and IY kept
;
; Witness: L1 0 ().
ExitDownSaved:
  PUSH IX
  PUSH IY
  CALL ExitDown
  POP IY
  POP IX
  RET

; (IX+2) = DE[$5C07]
;
; Witness: L1 2391 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
FrameFromTable:
  LD A,(StatusTimer)
  PUSH HL
  LD L,A
  LD H,$00
  ADD HL,DE
  LD A,(HL)
  LD (IX+$02),A
  POP HL
  RET

; Status 0 (SK, renamed)
;
; Witness: L1 332 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
ClearStatus:
  XOR A

; Status = A, the status timer $5C07 = 0 (SK)
;
; Every status change but a few direct writes ($A15C, $A42D, $A476, $A564,
; $AC90, $AC97, $ACC0, $AF60, $AF7D and some in GD) goes through here.
;
; Witness: L1 360 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx).
SetStatus:
  LD (Status),A
  XOR A
  LD (StatusTimer),A
  RET

; The frames of the 17 jump steps
JumpFrames:
  INCBIN "res/tables/jump.bin",$0000,17
JumpRise:
  INCBIN "res/tables/jump.bin",$0011,17

; FrameListPtr = HL: a frame list replaces the hero's update until $FF
;
; Witness: L1 7 (rzx, rzx, rzx).
StartFrameList:
  LD (FrameListPtr),HL
  RET

; A frame list step if one is running (an entry no code uses)
;
; HeroUpdate $A3E1 makes the same test inline ($A3EC) and jumps to
; FrameListPlay $AEB9. No reference to $AEB3 in the code; not executed in any
; recording.
;
; Witness: L1 0 ().
FrameListStep:
  LD HL,(FrameListPtr)
  LD A,H
  OR L
  RET Z

; One frame of the list at HL; $FF ends it
;
; Witness: L1 224 (rzx, rzx, rzx).
FrameListPlay:
  LD A,(HL)
  CP $FF
  JR NZ,FrameListNext
  LD HL,$0000
  LD (FrameListPtr),HL
  RET
FrameListNext:
  LD (IX+$02),A
  INC HL
  LD (FrameListPtr),HL
  RET

; The frames played when the hero refuses a drop, $FF end
;
; Started by RefuseShake $A567. Evidence: 7 refusals in 3 rzx segments; the
; instructions: "your character will obey all your instructions, even stupid
; ones, although this may lead to some head shaking".
RefuseFrames:
  INCBIN "res/anims/refuse.bin",$0000,32

; The frame list being played, 0 when none
FrameListPtr:
  DEFW $0000

; B = room / 12 (the level), C = room mod 12 (the column) (SK)
;
; Witness: L1 92 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx).
RoomToLevelColumn:
  LD A,(Room)
  LD B,$FF
RoomToLevelLoop:
  INC B
  SUB $0C
  JR NC,RoomToLevelLoop
  ADD A,$0C
  LD C,A
  RET

; Room = B * 12 + C (SK)
;
; Witness: L1 87 (gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx).
LevelColumnToRoom:
  INC B
  LD A,$F4
LevelColumnLoop:
  ADD A,$0C
  DJNZ LevelColumnLoop
  ADD A,C
  LD (Room),A
  RET
