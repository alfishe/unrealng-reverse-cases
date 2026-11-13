; --------------------------------------------------------------------------------------------------------------------
; missiles.asm: The missiles: shots, thrown objects, the bolt and flyers in 16 six-byte records at $75E0
; --------------------------------------------------------------------------------------------------------------------

  ORG $7FF5

; Missile kinds 2 and 3: an object the hero throws, left (2) or right (3), for
; 9 passes; it can hit the dragon
;
; IY = the missile record. Added by the hero's throw at $AED1 (the selected
; item's count - 1; C = 3 facing right, 2 left; +4 = $0A). Each pass the column
; moves 1 (kind 2 left, freed at 0; kind 3 right, freed at $1F) and +4 counts
; down (freed at 0); the frame is ThrownAmmoFrames[+4 - 1], drawn with
; DrawSprite (DrawSpriteMirrored for kind 2) and coloured 5 (cyan) by
; ColourSprite.
;
; In room 8 (grid 1's dragon room; the test reads only RoomNumber) while the
; dragon lives (DragonHits not $10), the object at column $14 sets
; DragonHitFlag = 1 and is freed: DrawDragon counts the hit. The hit path
; ($8056) ran 15 times in rzx-r3: the fifteen hits that kill the dragon
; (DrawDragon ends it at 15; screens 011012-012501).
;
; Witness: L1 200 (rzx-r3).
UpdateThrownAmmo:
  LD A,(IY+$02)
  CP $02
  JR NZ,ThrownAmmoRight
  DEC (IY+$00)
  JP Z,RemoveActor
  JR ThrownAmmoStep
ThrownAmmoRight:
  INC (IY+$00)
  LD A,(IY+$00)
  CP $1F
  JP Z,RemoveActor
ThrownAmmoStep:
  DEC (IY+$04)
  JP Z,RemoveActor
  LD C,(IY+$04)
  DEC C
  SLA C
  SLA C
  LD B,$00
  LD IX,ThrownAmmoFrames
  ADD IX,BC
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(IY+$02)
  CP $02
  JR Z,ThrownAmmoMirrored
  CALL DrawSprite
  LD C,$05
  CALL ColourSprite
  JR ThrownAmmoDragon
ThrownAmmoMirrored:
  CALL DrawSpriteMirrored
  LD C,$05
  CALL ColourSprite
ThrownAmmoDragon:
  LD A,(RoomNumber)            ; room 8: the dragon's head at column $14
  CP $08
  RET NZ
  LD A,(DragonHits)
  CP $10
  RET Z
  LD A,(IY+$00)
  CP $14
  RET NZ
  LD A,$01
  LD (DragonHitFlag),A
  JP RemoveActor

; UpdateThrownAmmo's 9 frame records: the graphics address, 1 byte wide, 4
; lines
;
; Indexed by +4 - 1 (8 down to 0): records 0-3 are $D30C, $D308, $D304, $D300,
; records 4-8 all $D300. Read by UpdateThrownAmmo at $8025 (all 36 bytes read
; in rzx-r3).
ThrownAmmoFrames:
  DEFB $0C,$D3,$01,$04
  DEFB $08,$D3,$01,$04
  DEFB $04,$D3,$01,$04
  DEFB $00,$D3,$01,$04
  DEFB $00,$D3,$01,$04
  DEFB $00,$D3,$01,$04
  DEFB $00,$D3,$01,$04
  DEFB $00,$D3,$01,$04
  DEFB $00,$D3,$01,$04

; Draw the missile IY with the frame record IX + BC: plain (A = 0) or mirrored,
; coloured red and yellow
;
; HL = the record's graphics word; A = 0: DrawSprite, ColourRedYellow $B41C and
; ColourSprite; else DrawSpriteMirrored and ColourSpriteMirrored. Reached from
; UpdateHeroShot ($80ED, BC = 0, A = its direction +4).
;
; Witness: L1 273 (rzx-r3).
DrawShotFrame:
  LD IX,ShotFrames
  ADD IX,BC
  LD L,(IX+$00)
  LD H,(IX+$01)
  CP $00
  JR NZ,DrawShotFrameMirrored
  CALL DrawSprite
  CALL ColourRedYellow
  JP ColourSprite
DrawShotFrameMirrored:
  CALL DrawSpriteMirrored
  CALL ColourRedYellow
  JP ColourSpriteMirrored

; Five frame records (graphics, width, lines); only the first, $D2A4 2 x 5, is
; read
;
; $D2A4 2 x 5, $D2AE 1 x $0F, $D2BD 1 x $0F, $D2CC 2 x $0D, $D2E6 2 x $0D: the
; layout of stage 1's ShotFrames ($813D). DrawShotFrame ($8088) and UpdateBolt
; ($826C) read only the first record (BC = 0); records 1-4 are read by no code
; (rw3.py: 4 of the 20 bytes read; no operand points into $80A8-$80B7).
ShotFrames:
  DEFB $A4,$D2,$02,$05
ShotFramesUnused:
  DEFB $AE,$D2,$01,$0F    ; records 1-4: no code reads them (stage 1's aimed
  DEFB $BD,$D2,$01,$0F    ; shot used them; stage 3 has no aimed shot)
  DEFB $CC,$D2,$02,$0D
  DEFB $E6,$D2,$02,$0D

; Missile kind 9: the item ThrowItem throws flies left or right; freed at the
; edge or on an actor it hits
;
; +4 = 0 left, else right. Freed at column 0 or $1F; in room 8 at column $16;
; or when ShotHitsActor finds an actor (it sets the actor's hit flag). Draws
; ShotFrames' first frame ($D2A4) through DrawShotFrame, mirrored when +4 is
; not 0. Added by ThrowItem $9646 (AddMissileHigh, C = 9).
;
; Stage 1's UpdateHeroShot ($8171) is the same but for the room-8 test.
;
; Witness: L1 329 (rzx-r3).
UpdateHeroShot:
  LD A,(IY+$04)
  CP $00
  JR Z,HeroShotLeft
  INC (IY+$00)
  LD A,(IY+$00)
  CP $1F
  JP Z,RemoveActor
  JR HeroShotRoom
HeroShotLeft:
  DEC (IY+$00)
  JP Z,RemoveActor
HeroShotRoom:
  LD A,(RoomNumber)
  CP $08
  JR NZ,HeroShotHit
  LD A,(IY+$00)
  CP $16
  JP Z,RemoveActor
HeroShotHit:
  CALL ShotHitsActor
  JP NZ,RemoveActor
  LD A,(IY+$04)
  LD BC,$0000
  JP DrawShotFrame

; Missile kind 4: a fireball the throne giant throws along one of four falling
; paths; hurts the hero by 2
;
; Added every 8th pass by $958A (grid 2, the throne room) at column $1A, line
; $50, +4 = a random path 0-3. Each pass: when the shot is 0-7 lines below the
; hero's line $74E1, DamageHero with C = 2; +3 counts 0-3 (the frame) and every
; other pass the column - 1 (freed at 0); +5 steps along the path
; (ThroneShotPaths, the path +4), whose byte is added to the line ($64 holds
; the last step); freed at line $82 or more. Draws ThroneShotFrames[+3] (2 x 8)
; with DrawSprite and the cycling colour (CycleColour $B4A3). The red stars
; around the throne in rzx-r3's screen 014505.
;
; Witness: L1 694 (rzx-r3).
UpdateThroneShot:
  LD A,(HeroY)
  LD E,A
  LD A,(IY+$01)
  SUB E
  JR C,ThroneShotMove
  CP $08
  JR NC,ThroneShotMove
  LD C,$02
  CALL DamageHero
ThroneShotMove:
  LD A,(IY+$03)
  INC A
  AND $03
  LD (IY+$03),A
  AND $01
  JR NZ,ThroneShotPath
  DEC (IY+$00)
  JP Z,RemoveActor
ThroneShotPath:
  LD A,(IY+$04)
  LD HL,ThroneShotPaths
  CP $00
  JR Z,ThroneShotStep
  LD HL,ThroneShotPath1
  CP $01
  JR Z,ThroneShotStep
  LD HL,ThroneShotPath2
  CP $02
  JR Z,ThroneShotStep
  LD HL,ThroneShotPath3
ThroneShotStep:
  INC (IY+$05)
ThroneShotRead:
  LD A,(IY+$05)
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  CP $64
  JR NZ,ThroneShotFall
  DEC (IY+$05)
  JR ThroneShotRead
ThroneShotFall:
  ADD A,(IY+$01)
  LD (IY+$01),A
  CP $82
  JP NC,RemoveActor
  LD A,(IY+$03)
  SLA A
  SLA A
  LD C,A
  LD B,$00
  LD IX,ThroneShotFrames
  ADD IX,BC
  LD L,(IX+$00)
  LD H,(IX+$01)
  CALL DrawSprite
  CALL CycleColour
  LD C,A
  JP ColourSprite

; The fireball's four frame records: $D264, $D274, $D284, $D294, each 2 bytes x
; 8 lines
;
; Read by UpdateThroneShot at $8160 (IX = $8170 + 4 x the frame).
ThroneShotFrames:
  DEFB $64,$D2,$02,$08
  DEFB $74,$D2,$02,$08
  DEFB $84,$D2,$02,$08
  DEFB $94,$D2,$02,$08

; The four paths of the throne giant's fireball: line steps (signed), $64 ends
; a path
;
; Path 0 at $8180, path 1 ThroneShotPath1, path 2 ThroneShotPath2, path 3
; ThroneShotPath3: each rises (-8 to -2 a pass) and falls faster and faster,
; the last step repeated at the $64. Read by UpdateThroneShot at $813B (138 of
; the 159 bytes read in rzx-r3).
ThroneShotPaths:
  DEFB $F8,$F8,$F9,$F9,$FA,$FA,$FB,$FB
  DEFB $FC,$FC,$FD,$FD,$FE,$FE,$FE,$FF
  DEFB $FF,$FF,$FF,$00,$00,$01,$01,$01
  DEFB $01,$02,$02,$02,$03,$03,$04,$04
  DEFB $05,$05,$06,$06,$07,$07,$08,$08
  DEFB $09,$09,$0A,$0A,$0B,$0B,$0C,$0C
  DEFB $0D,$0E,$0F,$10,$11,$12,$64
ThroneShotPath1:
  DEFB $F8,$F8,$F9,$F9,$F9,$FA,$FA,$FB ; path 1
  DEFB $FB,$FC,$FC,$FD,$FE,$FF,$FF,$FF
  DEFB $00,$00,$01,$01,$01,$02,$03,$04
  DEFB $04,$05,$05,$04,$06,$06,$07,$07
  DEFB $07,$08,$08,$08,$09,$09,$0A,$0A
  DEFB $0B,$0B,$0C,$0D,$0E,$0F,$10,$11
  DEFB $12,$64
ThroneShotPath2:
  DEFB $F6,$F7,$F8,$F8,$F9,$F9,$FA,$FB ; path 2
  DEFB $FC,$FD,$FE,$FF,$00,$00,$01,$02
  DEFB $03,$04,$05,$06,$07,$07,$08,$08
  DEFB $09,$0A,$0B,$0C,$0D,$0E,$64
ThroneShotPath3:
  DEFB $F6,$F8,$FA,$FB,$FC,$FD,$FE,$FF ; path 3
  DEFB $00,$00,$01,$02,$03,$04,$05,$06
  DEFB $08,$0A,$0B,$0C,$0D,$0E,$64

; Missile kind 5: the bolt FireBolt fires, left or right; in grid 2 it can hit
; the throne giant
;
; Added by $969A (item 7 selected, FIRE pressed: AddMissileHigh with C = 5, B =
; 1 facing right). In grid 2, at column $19 (column $1A when the bolt's line is
; under $48) it sets ThroneHitFlag = 1 and is freed ($9514 counts the hit).
; Else it moves one column a pass (+4 0 left, else right), freed at the room's
; edges and, in room 8, at column $16. Draws ShotFrames' first frame ($D2A4),
; coloured by $B427 (plain or mirrored by the direction). Unlike UpdateHeroShot
; it does not test ShotHitsActor. 33 hits in rzx-r3 ($8237).
;
; Witness: L1 99 (rzx-r3).
UpdateBolt:
  LD A,(GridNumber)
  CP $02
  JR NZ,BoltMove
  LD E,$19
  LD A,(IY+$01)
  CP $48
  JR NC,BoltColumn
  LD E,$1A
BoltColumn:
  LD A,(IY+$00)
  CP E
  JR NZ,BoltMove
  LD A,$01
  LD (ThroneHitFlag),A
  JP RemoveActor
BoltMove:
  LD A,(IY+$04)
  CP $00
  JR Z,BoltLeft
  INC (IY+$00)
  LD A,(IY+$00)
  CP $1F
  JP Z,RemoveActor
  JR BoltRoom
BoltLeft:
  DEC (IY+$00)
  JP Z,RemoveActor
BoltRoom:
  LD A,(RoomNumber)
  CP $08
  JR NZ,BoltDraw
  LD A,(IY+$00)
  CP $16
  JP Z,RemoveActor
BoltDraw:
  LD IX,ShotFrames
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(IY+$04)
  CP $00
  JR NZ,BoltMirrored
  CALL DrawSprite
  CALL ColourCyanCycle
  JP ColourSprite
BoltMirrored:
  CALL DrawSpriteMirrored
  CALL ColourCyanCycle
  JP ColourSpriteMirrored

  ORG $842E

; Kinds 7 and 8: a flyer along PathSteps, forwards (7) then back (8); OR-drawn
; 3 x 13 bytes
;
; +4 = the step into PathSteps (pairs: dx in half columns, dy), +5 = x in half
; columns, +3 a step counter. Kind 7 steps forwards; at the end mark ($64) it
; becomes kind 8 and is moved by RespawnShiftX (x 2) and RespawnShiftY, unless
; no lives are left (freed). Kind 8 steps back and is freed at step $FF. +0 =
; +5 / 2; the pre-shifted half ($B4B9 or $B4BD by +5's parity) is ORed into the
; buffer (3 bytes x 13 lines) when on screen (column under $1E, y under $78),
; then coloured ($B45A, $B4C9).
;
; Stage 1's UpdatePathFlyer at $842C is the same code.
;
; Witness: L1 2856 (s3-right).
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
; Stage 1's PathSteps at $84EE (found through the operands of the matched
; routines); the size and shape given here are stage 3's, from its bytes and
; readers.
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
  DEFB $04,$00,$04,$00,$64,$64

; NZ (and the actor's hit flag, +$09 bit 4) when the shot IY is over a
; shootable actor
;
; For the 13 actors at $74F2: not free, shootable (+$0F bit 0), same column,
; and the shot's y - the actor's y under its height (+3). Returns via $B37F
; (NZ, hit) or $B37A (Z, none).
;
; Stage 1's ShotHitsActor at $86A2 is the same code.
;
; Witness: L1 325 (rzx-r3).
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

  ORG $8629

; Missile kind 0 (no missile): flash the border from R for ever
;
; The entry 0 of the handler table at $B3B8, and the jumps at $87CC, $87CE,
; $87EA. A trap: never returns.
;
; Stage 1's HangFlashBorder at $876C is the same code.
;
; Not executed in any recording (the recordings checked: rzx-r3, s3-right);
; known only from the code.
HangFlashBorder:
  LD A,R
  OUT ($FE),A
  CALL KeyHook
  JP HangFlashBorder
