; --------------------------------------------------------------------------------------------------------------------
; missiles.asm: The missiles: shots, thrown objects and flyers in 16 six-byte records at $75E0
; --------------------------------------------------------------------------------------------------------------------

  ORG $826F

; Kind 1: a shot flying in one of 8 directions; hurts the hero by 6
;
; +4 = the direction 0-7 (ShotDirections: dx, dy, the frame's offset in
; ShotFrames, mirrored). ShotHitsHero with C = 6; moves; freed at column 0 or
; $1F, y under 8 or $80 and up; draws the direction's frame.
;
; As in stage 1 at $80DF, the same code.
;
; Witness: L1 2614 (rzx-r2, s2-right, stageload).
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

; DrawShotFrame
;
; Used by the routine at UpdateHeroShot.
DrawShotFrame:
  LD IX,ShotFrames        ; A = mirrored, C = the frame's offset in ShotFrames
  ADD IX,BC
  LD L,(IX+$00)
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

; Frame records: graphics address, width, lines ($C5D0 2x5, $C5DA 1x15, $C5E9
; 1x15, $C5F8 2x13, $C612 2x13)
;
; Five 4-byte records: the bitmap's address, the width in bytes, the height in
; lines. Read by DrawShotFrame ($82AB) with the offset from ShotDirections
; (UpdateAimedShot) or 0 (UpdateHeroShot: the 2 x 5 bolt). Read in both
; recordings.
ShotFrames:
  DEFB $D0,$C5,$02,$05
  DEFB $DA,$C5,$01,$0F
  DEFB $E9,$C5,$01,$0F
  DEFB $F8,$C5,$02,$0D
  DEFB $12,$C6,$02,$0D

; The 8 directions: dx, dy, the frame's offset in ShotFrames, 1 mirrored
;
; Eight 4-byte records for directions 0-7 (up, up-right, right, down-right,
; down, down-left, left, up-left): dx in columns, dy in lines, the frame's
; offset (0, 4, 8, 12, 16), 1 when drawn mirrored. Read by UpdateAimedShot
; ($827E) with the shot's +4.
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
; +4 = 0 left, else right. Freed at column 0 or $1F, or when ShotHitsActor
; finds an actor (it sets the actor's hit flag). Draws ShotFrames' first frame
; ($C5D0), mirrored by the direction (DrawShotFrame with A = +4). rzx-r2: 451
; runs (frames 630-16286): the hero's magic bolts; none in s2-right.
;
; As in stage 1 at $8171.
;
; Witness: L1 451 (rzx-r2).
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

  ORG $85A2

; Kinds 7 and 8: a flyer along PathSteps, forwards (7) then back (8); OR-drawn
; 3 x 13 bytes
;
; +4 = the step into PathSteps (pairs: dx in half columns, dy), +5 = x in half
; columns, +3 a step counter. Kind 7 steps forwards; at the end mark ($64) it
; becomes kind 8 and is moved by RespawnShiftX (x 2) and RespawnShiftY, unless
; no lives are left (freed). Kind 8 steps back and is freed at step $FF. +0 =
; +5 / 2; the pre-shifted half ($B6DD or $B6E1 by +5's parity) is ORed into the
; buffer (3 bytes x 13 lines) when on screen (column under $1E, y under $78),
; then coloured ($B4C5, $B748).
;
; As in stage 1 at $842C, the same code.
;
; Witness: L1 5192 (rzx-r2, s2-right).
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
; 66 pairs (dx, dy), then the end mark $64 $64 at $86E8. Read by
; UpdatePathFlyer ($85CB) with the step +4.
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
; and the shot's y - the actor's y under its height (+3). Returns via $B410
; (NZ, hit) or $B40B (Z, none).
;
; As in stage 1 at $86A2, the same code.
;
; Witness: L1 441 (rzx-r2).
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

; NZ (and the actor's flag +$09 bit 5) when the thrown weapon IY is over an
; actor it can hit
;
; For the 13 actors at $74F2: not free, hit by thrown weapons (+$0F bit 0), the
; same column as the missile, and the missile's y - the actor's y under its
; height (+3): sets the actor's +9 bit 5 (read by HydraHeadHit) and returns via
; ReturnNZ. None: ReturnZ. The thrown weapons' handler $B56D (missile kinds 5
; and 6) calls it ($B5A9): 992 times in rzx-r2 (frames 10657-15270, the hydra
; fight), 29 hits. As ShotHitsActor with bit 5 instead of bit 4.
;
; Witness: L1 992 (rzx-r2).
ThrownHitsActor:
  LD IX,Actors
  LD B,$0D
ThrownHitsActorNext:
  PUSH BC
  LD A,(IX+$00)
  CP $FF
  JR Z,ThrownHitsActorSkip
  BIT 0,(IX+$0F)
  JR Z,ThrownHitsActorSkip
  LD A,(IX+$00)
  CP (IY+$00)
  JR NZ,ThrownHitsActorSkip
  LD E,(IX+$03)
  LD A,(IY+$01)
  SUB (IX+$01)
  CP E
  JR NC,ThrownHitsActorSkip
  SET 5,(IX+$09)
  POP BC
  JP ReturnNZ
ThrownHitsActorSkip:
  LD BC,$0012
  ADD IX,BC
  POP BC
  DJNZ ThrownHitsActorNext
  JP ReturnZ

; Hurt the hero by C when the missile IY is in its column and within 14 lines
;
; When the hero's x ($74E0) is the missile's +0 and $A91B (A = $0E, E = the
; hero's y $74E1, D = the missile's +1) gives carry (closer than 14 lines):
; runs on into DamageHero with C. Stage 1's shield test (item 1 selected: no
; harm) is gone. Called by UpdateAimedShot (C = 6) and $B6CA: 2252 calls in
; rzx-r2, 1676 in s2-right.
;
; As in stage 1 at $86EB without the shield.
;
; Witness: L1 4565 (rzx-r2, s2-right, stageload).
ShotHitsHero:
  LD A,(HeroRecord)
  CP (IY+$00)
  RET NZ
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,$0E
  CALL AbsDiffAtMost
  RET NC

  ORG $B3C5

; Add a missile to the slots 8-15 ($7610) of the missile records
;
; Called by HeroDeath ($B36E); jumped to from ThrowItem ($913E), ThrowItem
; ($9146).
;
; As in stage 1 at $B296, the same code.
;
; Witness: L1 107 (rzx-r2, s2-right).
AddMissileHigh:
  PUSH BC
  PUSH DE
  PUSH AF
  LD BC,MissilesHigh

; Add a missile to the eight slots from BC
;
; Jumped to from AddMissile ($B3C3).
;
; As in stage 1 at $B29C, the same code.
;
; Witness: L1 661 (rzx-r2, s2-right, stageload).
AddMissileFrom:
  LD D,$00
AddMissileSearch:
  LD A,(MissileCursor)
  INC A
  AND $07
  LD (MissileCursor),A
  SLA A
  LD L,A
  SLA A
  ADD A,L
  LD L,A
  LD H,$00
  ADD HL,BC
  INC D
  LD A,D
  CP $08
  JR Z,AddMissileFull
  LD A,(HL)
  CP $FF
  JR NZ,AddMissileSearch
  POP AF
  POP DE
  POP BC
  LD (HL),D
  INC HL
  LD (HL),E
  INC HL
  LD (HL),C
  INC HL
  LD (HL),$FF
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  CP $FA
  RET NZ
  PUSH HL
  CALL Random
  POP HL
  LD (HL),A
  LD A,$01
  CP $02
  RET
AddMissileFull:
  POP AF
  POP DE
  POP BC

; A = 1, Z set: the "yes" exit of the tests
;
; Jumped to from CheckWalkBarriers ($833F), ShotHitsActor ($8722),
; ThrownHitsActor ($875D), FreeIfOnHero ($A918), InStrikeReach ($AA31).
;
; As in stage 1 at $B2DC, the same code.
;
; Witness: L1 1428 (rzx-r2, s2-right, stageload).
ReturnZ:
  LD A,$01
  CP $01
  RET

; A = 1, Z clear: the "no" exit of the tests
;
; Jumped to from CheckFirstRoomLeft ($8353), ShotHitsActor ($8717),
; ThrownHitsActor ($8752), FindFreeActor ($8D84), FindFreeActorPair ($8DA1),
; InStrikeReach ($AA34), ShotMeetsHydraBody ($B617), ShotMeetsHydraBody
; ($B636).
;
; As in stage 1 at $B2E1, the same code.
;
; Witness: L1 1239 (rzx-r2, s2-right, stageload).
ReturnNZ:
  LD A,$01
  CP $00
  RET

; Run the handler of every missile in use (once a main-loop pass)
;
; Called by MainLoop ($784F).
;
; As in stage 1 at $B2E6, the same code.
;
; Witness: L1 8031 (rzx-r2, s2-right, stageload).
UpdateMissiles:
  PUSH IX
  LD B,$10
  LD IY,Missiles
  LD DE,$0006
UpdateMissilesLoop:
  LD A,(IY+$00)
  CP $FF
  JR Z,UpdateMissilesNext
  PUSH BC
  LD L,(IY+$02)
  SLA L
  LD H,$00
  LD BC,MissileHandlers
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (MissileCall+$0001),DE
MissileCall:
  CALL $0000              ; CALL nn: nn = the effect's handler, written by
                          ; UpdateMissiles
  POP BC
  LD DE,$0006
UpdateMissilesNext:
  ADD IY,DE
  DJNZ UpdateMissilesLoop
  POP IX
  RET

; The handler of each missile kind 0-9 (10 words; stage 1 has 12)
;
; 0 none ($0000), 1 UpdateAimedShot (the spirits' shots), 2 and 3
; UpdateDriftLeft (the harpy's and the hydra heads' shots), 4 UpdateFloorShot
; (Medusa's head), 5 and 6 UpdateHeroMissile (item kind 6, left and right), 7
; and 8 UpdatePathFlyer (the hero's death fragments), 9 UpdateHeroShot
; (ThrowItem's shot).
;
; Read by UpdateMissiles ($B42F) for every missile in use: s2-right and rzx-r2.
MissileHandlers:
  DEFW $0000
  DEFW UpdateAimedShot
  DEFW UpdateDriftLeft
  DEFW UpdateDriftLeft
  DEFW UpdateFloorShot
  DEFW UpdateHeroMissile
  DEFW UpdateHeroMissile
  DEFW UpdatePathFlyer
  DEFW UpdatePathFlyer
  DEFW UpdateHeroShot

; HL = the play-buffer address of the actor IY ($5B00 + line x 32 + column); DE
; = HL in
;
; Called by UpdatePathFlyer ($8648), DrawSprite ($B769), DrawSpriteMirrored
; ($B784).
;
; As in stage 1 at $B332, the same code.
;
; Witness: L1 10960 (rzx-r2, s2-right, stageload).
BufferAddressHL:
  PUSH HL
  LD L,(IY+$01)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
  LD BC,PlayBuffer
  ADD HL,BC
  POP DE
  RET

; HL = the attribute-shadow address of the actor IY ($6DC0 + line / 8 x 32 +
; column)
;
; Called by ColourSprite ($B749), ColourSpriteMirrored ($B7AE).
;
; As in stage 1 at $B349, the same code.
;
; Witness: L1 10960 (rzx-r2, s2-right, stageload).
AttrShadowAddress:
  LD A,(IY+$01)
  AND $F8

; AttrShadowAddressA
;
; Used by the routine at UpdateBurst.
AttrShadowAddressA:
  LD L,A                  ; entry with A = the line rounded down to 8
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
  LD BC,PlayAttributes
  ADD HL,BC
  RET

; Free the actor record IY (+0 = $FF)
;
; Called by MedusaHeadLies ($822D); jumped to from HydraHead1Actor ($7FBA),
; HydraHead1Actor ($7FD2), HydraHead2Actor ($7FF0), HydraHead2Actor ($8008),
; HydraHead3Actor ($8028), HydraHead3Actor ($8040), HydraHead1LowActor ($8060),
; HydraHead1LowActor ($8078) and 41 more.
;
; As in stage 1 at $B35E, the same code.
;
; Witness: L1 681 (rzx-r2, s2-right, stageload).
RemoveActor:
  LD (IY+$00),$FF
  RET

; C = $44 or $45 (bright green, bright cyan) on alternate passes
;
; Called by DrawFloorShot ($B5D9), DrawHeroMissile ($B602).
;
; As in stage 1 at $B36C, the same code.
;
; Witness: L1 1432 (rzx-r2).
ColourGreenCyan:
  LD A,(PassCounter)
  LD C,$44
  AND $01
  RET Z
  LD C,$45
  RET

; C = $42 or $43 (bright red, bright magenta) on alternate passes
;
; Called by DropActor ($A929), FragmentActor ($AA81).
;
; As in stage 1 at $B377, the same code.
;
; Witness: L1 4724 (rzx-r2, s2-right).
ColourRedMagenta:
  LD A,(PassCounter)
  LD C,$42
  AND $01
  RET Z
  LD C,$43
  RET

; C = $42 (bright red) or 6 (yellow) on alternate passes
;
; Called by UpdateAimedShot ($82BE), UpdateAimedShot ($82C7).
;
; As in stage 1 at $B382, the same code.
;
; Witness: L1 2741 (rzx-r2, s2-right, stageload).
ColourRedYellow:
  LD A,(PassCounter)
  LD C,$42
  AND $01
  RET Z
  LD C,$06
  RET

; The harpy actors' colour +$0C: bright white $47 while the hero is left of
; column 9, else one step darker a call, down to $43
;
; IY = the actor. The hero's column ($74E0) under 9: +$0C = $47. Else +$0C - 1
; unless it is $43 already.
;
; Called by HarpyFlameActor ($A768), HarpyLampActor ($A7EA) and HarpyRiseActor
; ($A8A4): 83 calls in s2-right, 107 in rzx-r2.
;
; Witness: L1 190 (rzx-r2, s2-right).
HeroNearGlow:
  LD A,(HeroRecord)
  CP $09
  JR C,HeroNearGlowWhite
  LD A,(IY+$0C)
  CP $43
  RET Z
  DEC (IY+$0C)
  RET
HeroNearGlowWhite:
  LD (IY+$0C),$47
  RET

; C = $46 or $43 (bright yellow, bright magenta) on alternate passes
;
; Called by UpdatePathFlyer ($865E); jumped to from DriftShotColour ($B4E0).
;
; As in stage 1 at $B38D, the same code.
;
; Witness: L1 5916 (rzx-r2, s2-right).
ColourYellowMagenta:
  LD A,(PassCounter)
  LD C,$46
  AND $01
  RET Z
  LD C,$43
  RET

; C = $45 or $44 on alternate passes
;
; As in stage 1 at $B398, the same code.
;
; No CALL, JP or table names it; not executed in any recording (the recordings
; checked: s2-right, rzx-r2); known only from the code.
ColourCyanGreen:
  LD A,(PassCounter)
  LD C,$45
  AND $01
  RET Z
  LD C,$44
  RET

; C = a drifting shot's colour: type 2 (the harpy's) ColourYellowMagenta, type
; 3 (the hydra's) DriftColours[pass AND 3]
;
; IY = the missile. +2 = 2: on into ColourYellowMagenta (a JR). Else C =
; DriftColours[PassCounter AND 3].
;
; Called by DrawMissileMirrored ($B6D6): 583 calls in s2-right, 2038 in rzx-r2.
;
; Witness: L1 2621 (rzx-r2, s2-right).
DriftShotColour:
  LD A,(IY+$02)
  CP $02
  JR Z,ColourYellowMagenta
  LD A,(PassCounter)
  AND $03
  LD C,A
  LD B,$00
  LD HL,DriftColours
  ADD HL,BC
  LD C,(HL)
  RET

; The hydra shots' colours: bright red, bright magenta, bright red, magenta
; ($42, $43, $42, 3)
;
; Read by DriftShotColour ($B4E9): all four in rzx-r2; not in s2-right (no
; hydra there).
DriftColours:
  DEFB $42,$43,$42,$03

; The actor IY's colour +$0C = CycleColour $B4FB
;
; Called by UpdatePieceActor ($842E), SpiritActor ($9028), ItemHandler ($9ACD).
;
; As in stage 1 at $B3BD, the same code.
;
; Witness: L1 5804 (rzx-r2, s2-right, stageload).
SetCycleColour:
  CALL CycleColour
  LD (IY+$0C),A
  RET

; A = CycleColours[pass AND 7]: bright cyan, green, magenta, red, blue, red,
; magenta, green
;
; Called by GameOverStep ($8593), HeroUpdate ($ADEC), SetCycleColour ($B4F4).
;
; As in stage 1 at $B3C4, the same code.
;
; Witness: L1 7864 (rzx-r2, s2-right, stageload).
CycleColour:
  LD A,(PassCounter)
  AND $07
  LD C,A
  LD B,$00
  LD HL,CycleColours
  ADD HL,BC
  LD A,(HL)
  RET

; the colour cycle
;
; $45, $44, $43, $42, $41, $42, $43, $44. Read through FlashPieces ($850E) and
; CycleColour ($B503): all 8 bytes in s2-right and rzx-r2. As in stage 1 at
; $B3D2.
CycleColours:
  DEFB $45,$44,$43,$42,$41,$42,$43,$44

; Missile type 4 (Medusa's head's shot): spins up, runs left along the floor,
; hurts the hero by 20 or is beaten back
;
; IY = the missile (+4 the frame, +5 the state; KindTwelveShot starts it with
; +4 = 1, +5 = 1). State 1: +4 + 1; at 5 state 2. State 2: at the hero's column
; + 1: the hero in state 7 at frame 2 facing right (the strike that meets it)
; turns it into state 3 with PlaySoundVector $0A; otherwise DamageHero with C =
; $14 and it goes on; elsewhere the column - 1 (from column 0 it becomes $FF:
; the record is free). State 3: +4 + 1 to $0B, then RemoveActor (frames 5-10:
; it breaks up). Every pass DrawFloorShot.
;
; MissileHandlers' kind 4: 128 passes in rzx-r2, the hero hurt once ($B556);
; s2-right never meets Medusa.
;
; Witness: L1 128 (rzx-r2).
UpdateFloorShot:
  LD A,(IY+$05)
  CP $03
  JR Z,UpdateFloorShotBreak
  CP $02
  JR Z,UpdateFloorShotRun
  INC (IY+$04)
  LD A,(IY+$04)
  CP $05
  JP NZ,DrawFloorShot
  LD (IY+$05),$02
UpdateFloorShotRun:
  LD A,(HeroRecord)
  ADD A,$01
  CP (IY+$00)
  JR NZ,UpdateFloorShotMove
  LD A,(HeroState)
  CP $07
  JR NZ,UpdateFloorShotHit
  LD A,(HeroFrame)
  CP $02
  JR NZ,UpdateFloorShotHit
  LD A,(HeroFlags)
  BIT 7,A
  JR NZ,UpdateFloorShotHit
  LD (IY+$05),$03
  LD DE,$000A
  CALL PlaySoundVector
  JR UpdateFloorShotBreak
UpdateFloorShotHit:
  LD C,$14
  CALL DamageHero
UpdateFloorShotMove:
  DEC (IY+$00)
  JR DrawFloorShot
UpdateFloorShotBreak:
  INC (IY+$04)
  LD A,(IY+$04)
  CP $0B
  JP Z,RemoveActor
  JR DrawFloorShot

; Missile types 5 and 6 (item kind 6, FireHeroMissile): spins up, flies left
; (5) or right (6), hits actors, stops at the hydra's body
;
; IY = the missile (+4 = 1, +5 = 1 from FireHeroMissile). State 1 (or any other
; but 2 and 3): +4 + 1; at 5 state 2. State 2, type 5: column - 1 (freed at 0),
; ThrownHitsActor; type 6: column + 1, ShotMeetsHydraBody (Z: state 3), freed
; at $1F, ThrownHitsActor. State 3: +4 + 1 to $0B, then RemoveActor (frames
; 5-10). Every pass DrawHeroMissile. The CP 1 / JR Z at $B577 jumps to the next
; instruction.
;
; MissileHandlers' kinds 5 and 6: 1368 passes in rzx-r2 (66 missiles); s2-right
; never selects item 6.
;
; Witness: L1 1368 (rzx-r2).
UpdateHeroMissile:
  LD A,(IY+$05)
  CP $03
  JR Z,UpdateHeroMissileBreak
  CP $02
  JR Z,UpdateHeroMissileFly
  CP $01
  JR Z,UpdateHeroMissileSpin
UpdateHeroMissileSpin:
  INC (IY+$04)
  LD A,(IY+$04)
  CP $05
  JR NZ,DrawHeroMissile
  LD (IY+$05),$02
  JR UpdateHeroMissileFly
UpdateHeroMissileFly:
  LD A,(IY+$02)
  CP $05
  JR Z,UpdateHeroMissileLeft
  INC (IY+$00)
  CALL ShotMeetsHydraBody
  JR NZ,UpdateHeroMissileRight
  LD (IY+$05),$03
  JR UpdateHeroMissileBreak
UpdateHeroMissileRight:
  LD A,(IY+$00)
  CP $1F
  JP Z,RemoveActor
  CALL ThrownHitsActor
  JR DrawHeroMissile
UpdateHeroMissileLeft:
  DEC (IY+$00)
  JP Z,RemoveActor
  CALL ThrownHitsActor
  JR DrawHeroMissile
UpdateHeroMissileBreak:
  INC (IY+$04)
  LD A,(IY+$04)
  CP $0B
  JP Z,RemoveActor
  JR DrawHeroMissile

; Draw the floor shot: frame +4 of SpinShotSprites $D4FD (1 byte x 12 lines),
; bright green or cyan
;
; HL = $D4FD + 12 x +4 (Multiply), IX = FloorShotImage; DrawSprite,
; ColourGreenCyan, ColourSprite (a JP).
;
; Jumped to from UpdateFloorShot ($B524, $B55E, $B56B): 123 times in rzx-r2.
;
; Witness: L1 123 (rzx-r2).
DrawFloorShot:
  LD A,(IY+$04)
  LD B,$0C
  CALL Multiply
  LD BC,SpinShotSprites
  ADD HL,BC
  LD IX,FloorShotImage
  CALL DrawSprite
  CALL ColourGreenCyan
  JP ColourSprite

; DrawSprite's descriptor for the floor shot: +2 = 1 byte wide, +3 = 12 lines
; (+0/+1 not read, 0)
;
; Read by DrawSprite and ColourSprite (+2 and +3) from DrawFloorShot: rzx-r2.
FloorShotImage:
  DEFB $00,$00,$01,$0C

; Draw the hero's missile: frame +4 of SpinShotSprites $D4FD, as it is for type
; 5 (left), mirrored for type 6; bright green or cyan
;
; HL = $D4FD + 12 x +4, IX = HeroMissileImage; +2 = 5: DrawSprite, else
; DrawSpriteMirrored; ColourGreenCyan, ColourSprite (a JP).
;
; Jumped to from UpdateHeroMissile: 1309 times in rzx-r2.
;
; Witness: L1 1309 (rzx-r2).
DrawHeroMissile:
  LD A,(IY+$04)
  LD B,$0C
  CALL Multiply
  LD BC,SpinShotSprites
  ADD HL,BC
  LD IX,HeroMissileImage
  LD A,(IY+$02)
  CP $05
  JR NZ,DrawHeroMissileMirrored
  CALL DrawSprite
  JR DrawHeroMissileColour
DrawHeroMissileMirrored:
  CALL DrawSpriteMirrored
DrawHeroMissileColour:
  CALL ColourGreenCyan
  JP ColourSprite

; DrawSprite's descriptor for the hero's missile: 1 byte x 12 lines (+0/+1 not
; read, 0)
;
; Read by DrawSprite / DrawSpriteMirrored and ColourSprite from
; DrawHeroMissile: rzx-r2.
HeroMissileImage:
  DEFB $00,$00,$01,$0C

; Z when the hero's missile IY meets the hydra's body: grid 1, the hydra alive,
; room 7, column $13 (line under $2A) or $11
;
; GridNumber not 1: NZ. HydraHeads = $64 (beaten): NZ (ReturnNZ). Room 7: E =
; $13, or $11 when the missile's line is $2A or more; Z when its column is E.
; Room 3 and the other rooms: NZ.
;
; Called by UpdateHeroMissile ($B596): 1051 times in rzx-r2.
;
; Witness: L1 1051 (rzx-r2).
ShotMeetsHydraBody:
  LD A,(GridNumber)
  CP $01
  RET NZ
  LD A,(HydraHeads)
  CP $64
  JP Z,ReturnNZ
  LD A,(RoomNumber)
  CP $07
  JR Z,ShotMeetsHydraBodyRoom7
  CP $03
  RET NZ
  JR ShotMeetsHydraBodyNo
ShotMeetsHydraBodyRoom7:
  LD E,$13
  LD A,(IY+$01)
  CP $2A
  JR C,ShotMeetsHydraBodyColumn
  LD E,$11
ShotMeetsHydraBodyColumn:
  LD A,(IY+$00)
  CP E
  RET Z
ShotMeetsHydraBodyNo:
  JP ReturnNZ

; Missile types 2 and 3 (the harpy's and the hydra heads' shots): fall left on
; one of four curves, hurt the hero by 4, fade on a solid cell
;
; IY = the missile (+3 the drift step, +4 the fall step, +5 a random byte: its
; curve). +4 $14 and up: the fade: +4 + 1, at $1A RemoveActor; else the line
; rounded to a cell and descriptor +4 - $11 (4-8: DriftFadeSprites) drawn by
; DrawMissileMirrored. The flight: +4 + 1 up to $0F; the line +
; DriftFallSteps[(+5 AND 3) x 16 + +4], freed at $82 and down; +3 = +3 + 1 AND
; 3, on odd steps the column - 1 (freed at 0); CellAtRow at column + 3, row
; line / 8 + 1: solid: DriftShotLands; else ShotHitsHero with C = 4, then on
; into DrawMissileMirrored with descriptor +3 (DriftShotSprites).
;
; MissileHandlers' kinds 2 and 3: 642 passes in s2-right, 2264 in rzx-r2.
;
; Witness: L1 2906 (rzx-r2, s2-right).
UpdateDriftLeft:
  LD A,(IY+$04)
  CP $14
  JR C,UpdateDriftLeftFly
  INC A
  LD (IY+$04),A
  CP $1A
  JP Z,RemoveActor
  SUB $11
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD IX,ImageDescriptors
  ADD IX,BC
  LD A,(IY+$01)
  AND $F8
  LD (IY+$01),A
  JR DrawMissileMirrored
UpdateDriftLeftFly:
  LD A,(IY+$04)
  INC A
  CP $10
  JR Z,UpdateDriftLeftFall
  LD (IY+$04),A
UpdateDriftLeftFall:
  LD A,(IY+$05)
  AND $03
  SLA A
  SLA A
  SLA A
  SLA A
  ADD A,(IY+$04)
  LD C,A
  LD B,$00
  LD HL,DriftFallSteps
  ADD HL,BC
  LD A,(HL)
  ADD A,(IY+$01)
  CP $82
  JP NC,RemoveActor
  LD (IY+$01),A
  LD A,(IY+$03)
  INC A
  AND $03
  LD (IY+$03),A
  AND $01
  JR Z,UpdateDriftLeftDraw
  DEC (IY+$00)
  JP Z,RemoveActor
UpdateDriftLeftDraw:
  LD A,(IY+$03)
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD IX,ImageDescriptors
  ADD IX,BC
  LD A,(IY+$00)
  ADD A,$03
  LD E,A
  LD D,(IY+$01)
  SRL D
  SRL D
  SRL D
  INC D
  CALL CellAtRow
  JR NZ,DriftShotLands
  LD C,$04
  CALL ShotHitsHero

; Draw the image IX points to, mirrored, and colour it
;
; Jumped to from UpdateDriftLeft ($B660).
;
; As in stage 1 at $B3DA, the same code.
;
; Witness: L1 2621 (rzx-r2, s2-right).
DrawMissileMirrored:
  LD L,(IX+$00)
  LD H,(IX+$01)
  CALL DrawSpriteMirrored
  CALL DriftShotColour
  CALL ColourSpriteMirrored
  RET

; Nine image descriptors (the image address, the width in bytes, the height in
; lines): 4 drift frames, 5 fade frames
;
; $E898, $E8BF, $E8E6, $E90D (DriftShotSprites, 3 x 13) and $E934, $E94C,
; $E964, $E97C, $E994 (DriftFadeSprites, 3 x 8). Stage 1 has the first four
; only. Read by UpdateDriftLeft ($B653, $B6AB) and DrawMissileMirrored: all 36
; bytes in s2-right and rzx-r2.
ImageDescriptors:
  DEFB $98,$E8,$03,$0D
  DEFB $BF,$E8,$03,$0D
  DEFB $E6,$E8,$03,$0D
  DEFB $0D,$E9,$03,$0D
  DEFB $34,$E9,$03,$08
  DEFB $4C,$E9,$03,$08
  DEFB $64,$E9,$03,$08
  DEFB $7C,$E9,$03,$08
  DEFB $94,$E9,$03,$08

; Four fall curves of 16 line steps (1-5): a drifting shot's line step at fall
; step 0-15, the curve by its +5 AND 3
;
; Read by UpdateDriftLeft ($B681): 56 of the 64 bytes in s2-right and rzx-r2.
DriftFallSteps:
  DEFB $01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$03,$03,$03,$03,$03,$04
  DEFB $01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$03,$03,$03,$03,$04,$04
  DEFB $01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$03,$03,$03,$04,$04,$05
  DEFB $01,$01,$01,$01,$01,$01,$01,$01,$02,$02,$02,$02,$02,$02,$03,$03

; A drifting shot on a solid cell: +4 = $14 (the fade), then UpdateDriftLeft
; again (a JP)
;
; Jumped to from UpdateDriftLeft ($B6C3 JR NZ): 30 times in s2-right, 104 in
; rzx-r2.
;
; Witness: L1 134 (rzx-r2, s2-right).
DriftShotLands:
  LD (IY+$04),$14
  JP UpdateDriftLeft

; Fill the attribute shadow under an image with C
;
; Jumped to from UpdateAimedShot ($82C1), UpdatePathFlyer ($8661),
; DrawFloorShot ($B5DC), DrawHeroMissile ($B605).
;
; As in stage 1 at $B40A, the same code.
;
; Witness: L1 6730 (rzx-r2, s2-right, stageload).
ColourSprite:
  PUSH BC
  CALL AttrShadowAddress
  POP BC
  LD DE,$0020
  LD B,(IX+$03)
  SRL B
  SRL B
  SRL B
  INC B
ColourSpriteRow:
  PUSH BC
  PUSH HL
  LD B,(IX+$02)
ColourSpriteCell:
  LD (HL),C
  INC L
  DJNZ ColourSpriteCell
  POP HL
  ADD HL,DE
  POP BC
  DJNZ ColourSpriteRow
  RET

; Copy an image to the play buffer at the actor's position (no mask)
;
; Called by UpdateAimedShot ($82BB), DrawFloorShot ($B5D6), DrawHeroMissile
; ($B5FA).
;
; As in stage 1 at $B42B, the same code.
;
; Witness: L1 1255 (rzx-r2, s2-right, stageload).
DrawSprite:
  CALL BufferAddressHL
  EX DE,HL
  LD B,(IX+$03)
DrawSpriteRow:
  PUSH BC
  PUSH DE
  LD C,(IX+$02)
  LD B,$00
  LDIR
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DrawSpriteRow
  RET

; Copy an image mirrored left to right (through the bit-reverse table $FA00)
;
; Called by UpdateAimedShot ($82C4), DrawHeroMissile ($B5FF),
; DrawMissileMirrored ($B6D3).
;
; As in stage 1 at $B446, the same code.
;
; Witness: L1 5539 (rzx-r2, s2-right, stageload).
DrawSpriteMirrored:
  CALL BufferAddressHL
  EX DE,HL
  LD B,(IX+$03)
DrawSpriteMirroredRow:
  PUSH BC
  PUSH DE
  LD A,E
  ADD A,(IX+$02)
  DEC A
  LD E,A
  LD B,(IX+$02)
DrawSpriteMirroredByte:
  PUSH BC
  LD B,$FA
  LD A,(HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  DEC DE
  INC HL
  POP BC
  DJNZ DrawSpriteMirroredByte
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DrawSpriteMirroredRow
  RET

; ColourSprite $B748 for a mirrored image (filled leftwards from its right
; edge)
;
; Called by DrawMissileMirrored ($B6D9); jumped to from UpdateAimedShot
; ($82CA).
;
; As in stage 1 at $B46F, the same code.
;
; Witness: L1 4230 (rzx-r2, s2-right, stageload).
ColourSpriteMirrored:
  PUSH BC
  CALL AttrShadowAddress
  LD C,(IX+$02)
  LD B,$00
  DEC HL
  ADD HL,BC
  POP BC
  LD DE,$0020
  LD B,(IX+$03)
  SRL B
  SRL B
  SRL B
  INC B
ColourSpriteMirroredRow:
  PUSH BC
  PUSH HL
  LD B,(IX+$02)
ColourSpriteMirroredCell:
  LD (HL),C
  DEC L
  DJNZ ColourSpriteMirroredCell
  POP HL
  ADD HL,DE
  POP BC
  DJNZ ColourSpriteMirroredRow
  RET
