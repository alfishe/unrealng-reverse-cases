; --------------------------------------------------------------------------------------------------------------------
; missiles.asm: The missiles: shots, thrown objects and flyers in 16 six-byte records at $75E0
; --------------------------------------------------------------------------------------------------------------------

  ORG $803A

; Kind 1: a shot flying in one of 8 directions; hurts the hero by 6
;
; IY = the record, +4 = the direction 0-7 (ShotDirections: dx, dy, the frame's
; offset in ShotFrames, mirrored). ShotHitsHero with C = 6 (stage 4 has no
; shield test); moves; freed ($B520) at column 0 or $1F, y under 8 or $80 and
; up; draws the direction's frame with DrawSprite $B6B2 or DrawSpriteMirrored
; $B6CD, coloured red and yellow ($B53B).
;
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code (MissileHandlers $B4E2).
UpdateAimedShot:
  LD C,$06
  CALL ShotHitsHero
  LD A,(IY+$04)
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD HL,ShotDirections
  ADD HL,BC
  LD A,(IY+$00)
  ADD A,(HL)
  LD (IY+$00),A
  CP $00
  JP Z,RemoveActor
  CP $1F
  JP Z,RemoveActor
  INC HL
  LD A,(IY+$01)
  ADD A,(HL)
  LD (IY+$01),A
  CP $08
  JP C,RemoveActor
  CP $80
  JP NC,RemoveActor
  INC HL
  LD C,(HL)
  INC HL
  LD A,(HL)
  LD B,$00
; This entry point is used by the routine at UpdateHeroShot.
DrawShotFrame:
  LD IX,ShotFrames        ; A = mirrored, C = the frame's offset in ShotFrames
  ADD IX,BC

; DrawShotRecord
;
; Used by the routine at UpdateHeroBolt.
DrawShotRecord:
  LD L,(IX+$00)           ; IX = the frame record: graphics address, width,
                          ; lines
  LD H,(IX+$01)
  CP $00
  JR NZ,DrawShotMirrored
  CALL DrawSprite
  CALL ColourRedYellow
  JP ColourSprite
DrawShotMirrored:
  CALL DrawSpriteMirrored
  CALL ColourRedYellow
  JP ColourSpriteMirrored

; Frame records: graphics address, width, lines ($CF29 2x5, $CF33 1x15, $CF42
; 1x15, $CF51 2x13, $CF6B 2x13)
;
; Read by DrawShotFrame $8076 (IX = ShotFrames + C). Five records of 4 bytes:
; the graphics word, the width in bytes, the lines. Read in rzx-r4
; (UpdateHeroShot).
ShotFrames:
  DEFB $29,$CF,$02,$05    ; the flat shot $CF29, 2 x 5 (also UpdateHeroShot's)
  DEFB $33,$CF,$01,$0F    ; $CF33, 1 x 15 (up)
  DEFB $42,$CF,$01,$0F    ; $CF42, 1 x 15
  DEFB $51,$CF,$02,$0D    ; $CF51, 2 x 13 (diagonal)
  DEFB $6B,$CF,$02,$0D    ; $CF6B, 2 x 13

; The 8 directions: dx, dy, the frame's offset in ShotFrames, 1 mirrored
;
; Read by UpdateAimedShot $8049 (+ 4 x the direction): 0 up, 1 up-right, 2
; right, 3 down-right, 4 down, 5 down-left, 6 left, 7 up-left (dy 8 lines a
; step). Read in neither recording (UpdateAimedShot did not run).
ShotDirections:
  DEFB $00,$F8,$04,$00
  DEFB $01,$F8,$0C,$01
  DEFB $01,$00,$00,$01
  DEFB $01,$08,$10,$01
  DEFB $00,$08,$08,$00
  DEFB $FF,$08,$10,$00
  DEFB $FF,$00,$00,$00
  DEFB $FF,$F8,$0C,$00

; Kind 9: a shot flying left or right; stops at the room's edge or on an actor
; it hits
;
; +4 = 0 left, else right: one column a pass, freed at column 0 or $1F, or when
; ShotHitsActor finds an actor (it sets the actor's hit flag). Draws
; ShotFrames' first record ($CF29, 2 x 5) through DrawShotFrame, mirrored when
; +4 is not 0.
;
; Witness: L1 297 (rzx-r4).
UpdateHeroShot:
  LD A,(IY+$04)
  CP $00
  JR Z,HeroShotLeft
  INC (IY+$00)
  LD A,(IY+$00)
  CP $1F
  JP Z,RemoveActor
  JR HeroShotHit
HeroShotLeft:
  DEC (IY+$00)
  JP Z,RemoveActor
HeroShotHit:
  CALL ShotHitsActor
  JP NZ,RemoveActor
  LD A,(IY+$04)
  LD BC,$0000
  JR DrawShotFrame

; Kind 2: a bolt that grows for two passes, then flies left or right; it hurts
; the boss of grid 8 room 2
;
; IY = the record: +3 the frame 0-2 (the first two passes it only grows), +4 =
; 1 left, else right. Then one column a pass, freed at column 0 or $1F or on an
; actor (ShotHitsActor). In grid 8 room 2 from column $18 on while BossPhase is
; not 2: BossPhase 1 (awake) sets BossFlash = 2 (a hit, counted by
; DrawBossPicture); at column $19 the bolt is freed. Draws HeroBoltFrames[+3]
; (mirrored by +4) through DrawShotRecord.
;
; Witness: L1 400 (rzx-r4).
UpdateHeroBolt:
  LD A,(IY+$03)
  CP $02
  JP Z,HeroBoltMove
  INC A
  LD (IY+$03),A
  JP HeroBoltBoss
HeroBoltMove:
  LD A,(IY+$04)
  CP $01
  JR Z,HeroBoltLeft
  INC (IY+$00)
  LD A,(IY+$00)
  CP $1F
  JP Z,RemoveActor
  JR HeroBoltHit
HeroBoltLeft:
  DEC (IY+$00)
  JP Z,RemoveActor
HeroBoltHit:
  CALL ShotHitsActor
  JP NZ,RemoveActor
HeroBoltBoss:
  LD A,(GridNumber)
  CP $08
  JR NZ,HeroBoltDraw
  LD A,(RoomNumber)
  CP $02
  JR NZ,HeroBoltDraw
  LD A,(IY+$00)
  CP $18
  JP C,HeroBoltDraw
  LD A,(BossPhase)
  CP $02
  JP Z,HeroBoltDraw
  CP $00
  JP Z,HeroBoltBossEdge
  LD A,$02
  LD (BossFlash),A
HeroBoltBossEdge:
  LD A,(IY+$00)
  CP $19
  JP Z,RemoveActor
HeroBoltDraw:
  LD A,(IY+$03)
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD IX,HeroBoltFrames
  ADD IX,BC
  LD A,(IY+$04)
  JP DrawShotRecord

; Three frame records (graphics, width, lines): $CF85, $CF95, $CFA5, each 2 x 8
;
; Read by UpdateHeroBolt $815D (IX = HeroBoltFrames + 4 x +3). Read in rzx-r4.
HeroBoltFrames:
  DEFB $85,$CF,$02,$08
  DEFB $95,$CF,$02,$08
  DEFB $A5,$CF,$02,$08

  ORG $8450

; Kinds 5 and 6: a small dart flying left (5) or right (6), freed on an actor
; it hits
;
; One column a pass (kind 5 left, 6 right), freed at column 0 or $1F, or when
; ShotHitsActor finds an actor (it sets the actor's hit flag). Drawn straight
; into the play buffer: the byte $18 on two pixel lines at BufferAddressHL
; $B4F4, its attribute white (7) at AttrShadowAddress $B50B. No stage-1 kind is
; drawn so.
;
; Witness: L1 74 (rzx-r4).
UpdateDart:
  LD C,$FF
  LD A,(IY+$02)
  CP $05
  JP Z,UpdateDartMove
  LD C,$01
UpdateDartMove:
  LD A,(IY+$00)
  ADD A,C
  LD (IY+$00),A
  CP $00
  JP Z,RemoveActor
  CP $1F
  JP Z,RemoveActor
  CALL ShotHitsActor
  JP NZ,RemoveActor
  CALL BufferAddressHL
  LD (HL),$18
  LD BC,$0020
  ADD HL,BC
  LD (HL),$18
  CALL AttrShadowAddress
  LD (HL),$07
  RET

; Kinds 7 and 8: a flyer along PathSteps, forwards (7) then back (8); OR-drawn
; 3 x 13 bytes
;
; +4 = the step into PathSteps (pairs: dx in half columns, dy), +5 = x in half
; columns, +3 a step counter. Kind 7 steps forwards; at the end mark ($64) it
; becomes kind 8 and is moved by RespawnShiftX (x 2) and RespawnShiftY, unless
; no lives are left (freed). Kind 8 steps back and is freed at step $FF. x = +5
; / 2; the image is ImageDescriptors $B62D (odd half column) or $B631, OR-drawn
; 3 bytes x 13 lines unless off the play area, coloured yellow and magenta
; ($B55C). As in stage 1 at `$842C`. In s4-right these flyers were the hero's
; death sparks (32 reached the path's end); rzx-r4 had none (no life lost).
;
; Witness: L1 3304 (s4-right).
UpdatePathFlyer:
  LD A,(IY+$02)
  CP $08
  JR NZ,PathFlyerForward
  DEC (IY+$03)
  LD A,(IY+$03)
  CP $FF
  JP Z,RemoveActor
  DEC (IY+$04)
  JR PathFlyerStep
PathFlyerForward:
  INC (IY+$03)
  INC (IY+$04)
PathFlyerStep:
  LD A,(IY+$04)
  CP $80
  JR NC,PathFlyerPlace
  LD C,A
  SLA C
  LD B,$00
  LD HL,PathSteps
  ADD HL,BC
  LD A,(HL)
  CP $64
  JR NZ,PathFlyerMove
  LD (IY+$02),$08
  LD A,(RespawnShiftX)
  LD E,A
  LD A,(Lives)
  CP $00
  JP Z,RemoveActor
  LD A,(IY+$05)
  SUB E
  SUB E
  LD (IY+$05),A
  LD A,(RespawnShiftY)
  LD E,A
  LD A,(IY+$01)
  SUB E
  LD (IY+$01),A
  RET
PathFlyerMove:
  LD A,(IY+$02)
  CP $08
  JR Z,PathFlyerBack
  LD A,(IY+$05)
  ADD A,(HL)
  LD (IY+$05),A
  INC HL
  LD A,(IY+$01)
  ADD A,(HL)
  LD (IY+$01),A
  JR PathFlyerPlace
PathFlyerBack:
  LD A,(IY+$05)
  SUB (HL)
  LD (IY+$05),A
  INC HL
  LD A,(IY+$01)
  SUB (HL)
  LD (IY+$01),A
PathFlyerPlace:
  LD A,(IY+$05)
  SRL A
  LD (IY+$00),A
  LD IX,ImageDescriptors
  LD A,(IY+$05)
  AND $01
  JR NZ,PathFlyerDraw
  LD IX,ImageDescriptors+$0004
PathFlyerDraw:
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(IY+$00)
  CP $1E
  RET NC
  LD A,(IY+$01)
  CP $78
  RET NC
  CALL BufferAddressHL
  LD B,$0D
PathFlyerLine:
  PUSH BC
  LD B,$03
PathFlyerByte:
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC DE
  INC HL
  DJNZ PathFlyerByte
  LD BC,$001D
  ADD HL,BC
  POP BC
  DJNZ PathFlyerLine
  CALL ColourYellowMagenta
  JP ColourSprite

; The flyer's path: dx (half columns), dy a step; $64 $64 ends
;
; Read by UpdatePathFlyer $84AD (+ 2 x the step). 66 pairs and the end mark $64
; $64 at $85CA. Read in s4-right.
PathSteps:
  DEFB $01,$FE,$01,$FD,$01,$FB,$FF,$FB
  DEFB $FF,$FD,$FF,$FE,$FF,$01,$FF,$02
  DEFB $FF,$03,$01,$03,$01,$02,$01,$01
  DEFB $01,$FF,$01,$FE,$01,$FD,$01,$FD
  DEFB $FF,$FD,$FF,$FD,$FF,$FE,$FF,$FE
  DEFB $FF,$FF,$FF,$FF,$FF,$01,$FF,$01
  DEFB $FF,$02,$FF,$02,$FF,$03,$FF,$03
  DEFB $FF,$01,$FF,$FE,$FF,$FC,$FF,$FA
  DEFB $01,$FA,$01,$FC,$01,$FE,$01,$FF
  DEFB $01,$01,$01,$02,$01,$03,$01,$02
  DEFB $01,$01,$01,$00,$01,$00,$02,$00
  DEFB $02,$00,$02,$00,$02,$00,$03,$00
  DEFB $03,$00,$03,$00,$03,$00,$03,$00
  DEFB $03,$00,$03,$00,$03,$00,$04,$00
  DEFB $04,$00,$04,$00,$04,$00,$04,$00
  DEFB $04,$00,$04,$00,$04,$00,$04,$00
  DEFB $04,$00,$04,$00,$64,$64

; NZ (and the actor's hit flag, +$09 bit 4) when the shot IY is over a
; shootable actor
;
; For the 13 actors at $74F2: not free, shootable (+$0F bit 0), same column,
; and the shot's y - the actor's y under its height (+3). Returns via ReturnNZ
; $B4A7 (hit) or ReturnZ $B4A2 (none). Callers: UpdateHeroShot, UpdateHeroBolt,
; UpdateDart. As in stage 1 at `$86A2`.
;
; Witness: L1 673 (rzx-r4).
ShotHitsActor:
  LD IX,Actors
  LD B,$0D
ShotHitsActorNext:
  PUSH BC
  LD A,(IX+$00)
  CP $FF
  JR Z,ShotHitsActorSkip
  BIT 0,(IX+$0F)
  JR Z,ShotHitsActorSkip
  LD A,(IX+$00)
  CP (IY+$00)
  JR NZ,ShotHitsActorSkip
  LD E,(IX+$03)
  LD A,(IY+$01)
  SUB (IX+$01)
  CP E
  JR NC,ShotHitsActorSkip
  SET 4,(IX+$09)
  POP BC
  JP ReturnNZ
ShotHitsActorSkip:
  LD BC,$0012
  ADD IX,BC
  POP BC
  DJNZ ShotHitsActorNext
  JP ReturnZ

; Hurt the hero by C when the missile IY is in its column and within 14 lines
;
; When the hero's x ($74E0) is +0 and $A92A (A = $0E, E = the hero's y, D = +1)
; finds them overlapping, falls into DamageHero. Stage 1's ShotHitsHero first
; let the shield (item 1) guard the hero; stage 4's has no such test. Callers:
; UpdateAimedShot $803C and $B5F2.
;
; Witness: L1 2178 (rzx-r4).
ShotHitsHero:
  LD A,(HeroRecord)
  CP (IY+$00)
  RET NZ
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,$0E
  CALL AbsDiffBelow
  RET NC

  ORG $8D68

; Missile kinds 0 and 4 (no missile): flash the border from R for ever
;
; The entries 0 and 4 of MissileHandlers $B4E0 and the words 0, 1 and 15 of
; RowPlotters. A trap: never returns (OUT ($FE) from R, KeyHook, again).
;
; Not executed in any recording (the recordings checked: rzx-r4, s4-right);
; known only from the code.
HangFlashBorder:
  LD A,R
  OUT ($FE),A
  CALL KeyHook
  JR HangFlashBorder

  ORG $95F8

; Free the missiles of kind 2 in the slots 8-15 ($7610)
;
; Witness: L1 32 (rzx-r4).
ClearKind2Missiles:
  LD IX,MissilesHigh
  LD B,$08
  LD DE,$0006
ClearKind2Loop:
  LD A,(IX+$02)
  CP $02
  JP NZ,ClearKind2Next
  LD (IX+$00),$FF
ClearKind2Next:
  ADD IX,DE
  DJNZ ClearKind2Loop
  RET

  ORG $B5C5

; Missile kind 3: the boss's shot, flying left and up or down by its direction
;
; IY = the missile (+4 its direction 0-4). Column - 1 a pass (removed at 0);
; line + HeadShotSteps[+4] (removed at line $88 and down); ShotHitsHero $8607
; with C = 2; the image HeadShotImages[+4] drawn (DrawSprite), coloured by
; HeadShotColour (JP ColourSprite).
;
; Witness: L1 2288 (rzx-r4).
HeadShot:
  DEC (IY+$00)
  JP Z,RemoveActor
  LD C,(IY+$04)
  LD B,$00
  LD HL,HeadShotSteps
  ADD HL,BC
  LD A,(HL)
  ADD A,(IY+$01)
  LD (IY+$01),A
  CP $88
  JP NC,RemoveActor
  LD A,(IY+$04)
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD IX,HeadShotImages
  ADD IX,BC
  LD C,$02
  CALL ShotHitsHero
  LD L,(IX+$00)
  LD H,(IX+$01)
  CALL DrawSprite
  CALL HeadShotColour
  JP ColourSprite

; Five image descriptors (address, width, height): $CFB5, $CFC5, $CFD5, $CFE5,
; $CFF5, each 2 x 8
;
; Read by HeadShot (LD IX,HeadShotImages + 4 x the direction). Read in rzx-r4
; (2178 passes); not in s4-right.
HeadShotImages:
  DEFB $B5,$CF,$02,$08
  DEFB $C5,$CF,$02,$08
  DEFB $D5,$CF,$02,$08
  DEFB $E5,$CF,$02,$08
  DEFB $F5,$CF,$02,$08

; The line change a pass for directions 0-4: -2, 0, 2, 5, 8
;
; Read by HeadShot (LD HL,HeadShotSteps + the direction). Read in rzx-r4 (2220
; passes); not in s4-right.
HeadShotSteps:
  DEFB $FE,$00,$02,$05,$08
