; --------------------------------------------------------------------------------------------------------------------
; enemies.asm: The enemies, the hazards and the bosses
;
; The room's actors come from its placements (LoadRoomActors $A4CC, the kinds in ActorKinds $9C8A) and from
; SpawnRandomEnemy $9353 (grid 0: a warrior rises from the ground every 30-61 passes). Stage 1's: the skeleton
; warriors (WarriorActor $94D0 and its head WarriorHeadActor $93F2), the hanging bodies (HangingActor $9186), the
; statue heads that spit (StatueActor $912B), the flame jets and fire pits (FlameJetActor $8DCC, FirePitActor $8D6D),
; the gate (GateActor $9065), the winged demon of room 12 (four parts, BossWingLeft $8E60 to BossHead $8E86, phases in
; BossPhase, its face RoomPicture drawn by DrawRoomPicture $8930) and the dragon of the arena, grid 2 (ArenaHeadActor
; $90E7, its body ArenaPicture drawn by DrawArenaPicture $89BB, 20 hits: ArenaBossHit $A14A).
; --------------------------------------------------------------------------------------------------------------------

  ORG $8233

; An actor that takes 6 hits, rises, bobs and then waits to be taken as a piece
; (1200 points)
;
; IY = the actor (18-byte record). Colour from the cycle ($B3BD). +$0B not 0:
; animates frames 2-9. Else by +$0A: 6 PieceRises, 7 PieceWaitsPickup; 0-5:
; each hit (+$09 bit 4, set by a shot or the hero's blow) clears the flag and
; adds 1 to +$0A; at 6 the next record's +0 is set $FF (the record after it
; freed). Frame 0. Draws with $AA02 (frames $E154, graphics $E06C). Its kind's
; handler pointer is at $9D5F.
;
; Witness: L1 5234 (rzx-r1, s1-right).
UpdatePieceActor:
  CALL SetCycleColour
  LD A,(IY+$0B)
  CP $00
  JR NZ,PieceActorAnimate
  LD A,(IY+$0A)
  CP $06
  JP Z,PieceRises
  CP $07
  JP Z,PieceWaitsPickup
  BIT 4,(IY+$09)
  JR Z,PieceActorStill
  RES 4,(IY+$09)
  INC (IY+$0A)
  LD A,(IY+$0A)
  CP $06
  JR NZ,PieceActorStill
  LD (IY+$12),$FF
PieceActorStill:
  LD A,$00
  JP PieceActorDraw
PieceActorAnimate:
  LD A,(IY+$08)
  INC A
  AND $07
  LD (IY+$08),A
  ADD A,$02
; This entry point is used by the routines at PieceRises and PieceWaitsPickup.
PieceActorDraw:
  CALL SetActorFrame

; $AA02's inline operands: the frame table $E154 and the graphics base $E06C
PieceFrames:
  DEFB $54,$E1,$6C,$E0

; State 6: rise and bob along RiseSteps for 30 steps (effect 3 at steps 16 and
; 25), then state 7
;
; Witness: L1 155 (rzx-r1).
PieceRises:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $1E
  JR Z,PieceRisesDone
  CP $10
  JP Z,PieceRisesSound
  CP $19
  JP NZ,PieceRisesMove
PieceRisesSound:
  LD DE,$0003
  CALL PlaySoundVector
PieceRisesMove:
  LD C,(IY+$08)
  LD B,$00
  LD HL,RiseSteps
  ADD HL,BC
  LD A,(HL)
  ADD A,(IY+$0E)
  LD (IY+$0E),A
  XOR A
  JP PieceActorDraw
PieceRisesDone:
  INC (IY+$0A)
  XOR A
  JP PieceActorDraw

; The rising piece's y change at each step 0-29
RiseSteps:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$01,$02,$03,$04,$05,$06
  DEFB $FC,$FD,$FE,$FF,$00,$01,$02,$03
  DEFB $04,$FE,$FF,$00,$01,$02

; State 7: when the hero touches it at its column (or the next): 1200 points,
; the piece's bit, freed
;
; $A11E (the hero within $14 lines); then the hero's x ($74E0) equal to +0 or
; +0 + 1: AddScore 1200, PieceTakenFlag = 1, PiecesMask |= +$10, freed ($B35E).
;
; Witness: L1 28 (rzx-r1).
PieceWaitsPickup:
  LD C,$14
  CALL HeroWithinY
  JR NC,PieceNotTaken
  LD A,(HeroRecord)
  LD E,(IY+$00)
  CP E
  JR Z,PieceTaken
  INC E
  CP E
  RET NZ
PieceTaken:
  LD BC,$04B0
  CALL AddScore
  LD A,$01
  LD (PieceTakenFlag),A
  LD A,(PiecesMask)
  OR (IY+$10)
  LD (PiecesMask),A
  JP RemoveActor
PieceNotTaken:
  XOR A
  JP PieceActorDraw

  ORG $8930

; Draw room 12's big picture and flash its eyes
;
; Only in room 12 ($FE30, else returns at once): draws the 53-row picture at
; $D5D5 (stage 1: the demon's face over
;
; the winged boss's lair) into the play buffer from column 9 of its first line
; (DrawRowPicture), every pass since
;
; the buffer is cleared every pass. Paints the shadow attributes $6DC0-$6E80
; red (2) and the two eye cells $6E89,
;
; $6E96, then sets the eyes' colours (SetEyeColour) to
; EyeFlashColours[EyeFlashStep] while a flash runs (10 steps),
;
; starting a new flash while EyeFlashRepeats is non-zero.
;
; Only the first test ran in the stage-1 recordings (no recording reached the
; room or the arena); the drawing is
;
; known only from the code.
;
; Witness: L1 19500 (c1o, deaths, rzx-r1, s1-idle, s1-right).
DrawRoomPicture:
  LD A,(RoomNumber)
  CP $0C
  RET NZ
  LD B,$35
  LD DE,PlayBuffer+9
  LD HL,RoomPicture
  CALL DrawRowPicture
  LD HL,PlayAttributes
  LD DE,PlayAttributes+$0001
  LD BC,$00C0
  LD (HL),$02
  LDIR
  LD HL,PlayAttributesCell+$00C7
  LD DE,PlayAttributesCell+$00C8
  LD BC,$0001
  LD (HL),$02
  LDIR
  LD HL,PlayAttributesCell+$00D4
  LD DE,PlayAttributesCell+$00D5
  LD BC,$0001
  LD (HL),$02
  LDIR
  LD A,$00
  CALL SetEyeColour
  LD A,(EyeFlashStep)
  CP $00
  JR Z,EyeFlashNext
  DEC A
  LD (EyeFlashStep),A
  LD C,A
  LD B,$00
  LD HL,EyeFlashColours
  ADD HL,BC
  LD A,(HL)

; Colour the room picture's two eye cells A
;
; Writes A to the shadow attributes $6E2E and $6E32.
;
; Witness: L1 846 (rzx-r1).
SetEyeColour:
  LD (PlayAttributesCell+$006C),A
  LD (PlayAttributesCell+$0070),A
  RET
; This entry point is used by the routine at DrawRoomPicture.
EyeFlashNext:
  LD A,(EyeFlashRepeats)            ; the flash ended: start another while
                          ; EyeFlashRepeats lasts
  CP $00
  RET Z
  DEC A
  LD (EyeFlashRepeats),A
  LD A,$0A
  LD (EyeFlashStep),A
  RET

; The eye colours of one flash, read backwards: black, then bright blue to cyan
; and back
EyeFlashColours:
  DEFB $00,$41,$42,$43,$44,$45,$44,$43,$42,$41

  ORG $89BB

; Draw the arena's boss picture (grid 2) and its colours
;
; Only in grid 2 (GridNumber) while ArenaBossBeaten is 0: draws the 92-row
; picture at $D0D8 (stage 1: the green
;
; dragon's body) into the play buffer from $5F8E (buffer row 4, column 14) with
; DrawRowPicture, then its attributes:
;
; the 12 x 16 block $D515 copied into the shadow $6E4E, or, when ArenaFlash is
; 1, painted red (2) where the block is
;
; non-zero and ArenaFlash cleared. Then colours the column $6E4D: 3 cells green
; (4) or red when flashing, 3 red.
;
; Only the first test ran in the stage-1 recordings (no recording reached the
; room or the arena); the drawing is
;
; known only from the code.
;
; Witness: L1 19500 (c1o, deaths, rzx-r1, s1-idle, s1-right).
DrawArenaPicture:
  LD A,(GridNumber)
  CP $02
  RET NZ
  LD A,(ArenaBossBeaten)
  CP $00
  RET NZ
  LD HL,ArenaPicture
  LD DE,PlayBuffer+1166
  LD B,$5C
  CALL DrawRowPicture
  LD A,(ArenaFlash)
  CP $01
  JR Z,ArenaFlashRed
  LD HL,ArenaAttributes
  LD DE,PlayAttributesCell+$008C
  LD B,$0C
ArenaAttrRow:
  PUSH BC                 ; copy one row of 16 attributes
  PUSH DE
  LD BC,$0010
  LDIR
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ ArenaAttrRow
  LD E,$04
  JR ArenaColumn
ArenaFlashRed:
  LD DE,ArenaAttributes   ; ArenaFlash: paint the picture's cells red
  LD HL,PlayAttributesCell+$008C
  LD B,$0C
ArenaFlashRow:
  PUSH BC
  LD B,$10
ArenaFlashCell:
  LD A,(DE)
  CP $00
  JR Z,ArenaFlashNext
  LD (HL),$02
ArenaFlashNext:
  INC L
  INC DE
  DJNZ ArenaFlashCell
  LD BC,$0010
  ADD HL,BC
  POP BC
  DJNZ ArenaFlashRow
  XOR A
  LD (ArenaFlash),A
  LD E,$02
ArenaColumn:
  LD HL,PlayAttributesCell+$008B ; the column of 6 cells left of the picture
  LD (HL),E
  LD BC,$0020
  ADD HL,BC
  LD (HL),E
  ADD HL,BC
  LD (HL),E
  ADD HL,BC
  LD (HL),$02
  ADD HL,BC
  LD (HL),$02
  ADD HL,BC
  LD (HL),$02
  RET

; Hurt the hero in a room's danger zone
;
; Grid 2 with the arena boss alive: the hero at column 16 or more ($74E0 >=
; $10) loses 4 (DamageHero $870C, C = 4).
;
; Grid 0: the hero at a column under 4 loses 4 each pass.
;
; Witness: L1 19500 (c1o, deaths, rzx-r1, s1-idle, s1-right).
ZoneDamage:
  LD A,(GridNumber)
  CP $02
  JR NZ,ZoneDamageGrid0
  LD A,(ArenaBossBeaten)
  CP $00
  RET NZ
  LD A,(HeroRecord)
  CP $10
  RET C
  LD C,$04
  JP DamageHero
ZoneDamageGrid0:
  CP $00
  RET NZ
  LD A,(HeroRecord)
  CP $04
  RET NC
  LD C,$04
  JP DamageHero

  ORG $8D6D

; Actor handler: a pit of fire that kills on touch
;
; Handler of the template at $9CCA. The first pass (+8 = 100) starts at a
; random frame 0-7; +8 counts 0-11, the
;
; frame is +8 / 2 of FirePitFrames; the colour +$0C flickers between $42 and
; $43 on PassCounter. The hero in the
;
; same column or one left of it and less than 15 lines above the pit's top
; loses a life at once (JP $7ECE) unless
;
; his state $74EA is $0F.
;
; Witness: L1 7664 (rzx-r1).
FirePitActor:
  LD A,(IY+$08)
  CP $64
  JR NZ,FirePitAnimate
  CALL Random
  AND $07
  LD (IY+$08),A
FirePitAnimate:
  LD A,(PassCounter)
  AND $01
  LD L,A
  LD H,$00
  LD BC,FirePitColours
  ADD HL,BC
  LD A,(HL)
  LD (IY+$0C),A
  LD A,(IY+$08)
  INC A
  CP $0C
  JR NZ,FirePitTouch
  XOR A
FirePitTouch:
  LD (IY+$08),A
  LD A,(HeroRecord)
  CP (IY+$00)
  JP Z,FirePitHeight
  DEC A
  CP (IY+$00)
  JR NZ,FirePitFrame
FirePitHeight:
  LD A,(HeroY)
  LD B,A
  LD A,(IY+$01)
  SUB B
  CP $0F
  JR NC,FirePitFrame
  LD A,(HeroState)
  CP $0F
  JP Z,FirePitFrame
  JP LoseLife
FirePitFrame:
  LD A,(IY+$08)
  SRL A
  CALL SetActorFrame

; SetFrame's data: the frame records $C36D, the sprite bytes $C2D1 (4 frames of
; flames)
FirePitFrames:
  DEFB $6D,$C3,$D1,$C2

; The pit's two colours, bright red and bright magenta on black
FirePitColours:
  DEFB $42,$43

; Actor handler: a jet of flame that rises out of the ground at random
;
; Handler of the template at $9C9D. +8 counts the frames 0 to +$0A ($0D long, 7
; short); at frame 3 the hero within
;
; 20 lines (A11E) and in the jet's column or the next loses $10 (DamageHero,
; unless the item guard $86DD). The
;
; colour comes from $B38D. At the end of a jet: the next one long (3 in 4) or
; short, after a pause of 66-129 passes
;
; (+8 = $BE + 0-63, counting up through 0); between jets +0 = $FE (not drawn).
; The frames from FlameJetLong /
;
; FlameJetShort, sprites $C391 (13 frames of a flame growing and dying).
;
; Witness: L1 26588 (c1o, deaths, rzx-r1, s1-idle, s1-right).
FlameJetActor:
  LD A,(IY+$08)
  CP $03
  JR NZ,FlameJetStep
  LD C,$14
  CALL HeroWithinY
  JR NC,FlameJetStep
  LD A,(HeroRecord)
  LD E,(IY+$00)
  CP E
  JR Z,FlameJetHit
  INC E
  CP E
  JR NZ,FlameJetStep
FlameJetHit:
  CALL IsShieldUp
  JR NZ,FlameJetStep
  LD C,$10
  CALL DamageHero
FlameJetStep:
  CALL ColourYellowMagenta
  LD (IY+$0C),C
  LD A,(IY+$08)
  CP (IY+$0A)
  JR NZ,FlameJetNext
  LD E,$0D
  CALL Random
  AND $03
  JR NZ,FlameJetPause
  LD E,$07
FlameJetPause:
  LD (IY+$0A),E
  CALL Random
  AND $3F
  ADD A,$BE
  LD (IY+$08),A
FlameJetNext:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $0D
  JR C,FlameJetShow
  LD (IY+$00),$FE
  RET
FlameJetShow:
  LD HL,FlameJetLong
  LD A,(IY+$0A)
  CP $07
  JR NZ,FlameJetFrame
  LD HL,FlameJetShort
FlameJetFrame:
  LD C,(IY+$08)
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  CALL SetActorFrame

; SetFrame's data: the frame records $C4E5, the sprite bytes $C391
FlameJetFrames:
  DEFB $E5,$C4,$91,$C3

; The long jet's frames
FlameJetLong:
  DEFB $00,$01,$02,$03,$04,$05,$06,$07,$08,$09,$0A,$0B,$0C

; The short jet's frames
FlameJetShort:
  DEFB $00,$01,$02,$03,$09,$0A,$0B,$0C

; Spawn the bridge slab (template $9D23) at column 15, line $87
;
; Jumped to by BossWingRight once BossPhase is 3 or more (rzx-r1 frame 15362
; on). Spawns into IY (SpawnActor $A4B1).
;
; Witness: L1 1 (rzx-r1).
SpawnBossBridge:
  LD HL,ActorTemplates
  LD D,$0F
  LD E,$87
  JP SpawnActor

; Actor handler: the winged boss's left wing
;
; Handler of the template at $9CD1. Sprite $DDE9, 3 bytes x $21 lines, then
; BossPart. Stage 1: the winged demon of
;
; room 12; rzx-r1 runs the four parts in room 12, frames 14980-15521 (BossPhase
; 2 at 14980, 3 at 15362, 4
;
; at 15521).
;
; Witness: L1 477 (rzx-r1).
BossWingLeft:
  LD HL,BossWingSprite
  LD B,$03
  LD C,$21
  JP BossPart

; Actor handler: the winged boss's right wing
;
; As BossWingLeft (template $9CDA); from BossPhase 3 on it turns into
; SpawnBossBridge.
;
; Witness: L1 477 (rzx-r1).
BossWingRight:
  LD A,(BossPhase)
  CP $03
  JP NC,SpawnBossBridge
  LD HL,BossWingSprite
  LD B,$03
  LD C,$21
  JP BossPart

; Actor handler: the winged boss's body
;
; Template $9CE3. Sprite $DE4C, 6 bytes x $20 lines, then BossPart.
;
; Witness: L1 477 (rzx-r1).
BossBody:
  LD HL,BossBodySprites
  LD B,$06
  LD C,$20
  JP BossPart

; Actor handler: the winged boss's head, the part that takes the hits
;
; Template $9CEC. Sprite $DFCC, 2 bytes x $14 lines. BossFlash counts down; a
; hit (+9 bit 4, set by the hero's
;
; weapon) clears the bit, sets BossFlash to 1 and takes one of BossHits; at 0
; the boss is beaten (JP $A182).
;
; Then BossPart.
;
; Witness: L1 518 (rzx-r1).
BossHead:
  LD HL,BossHeadSprites
  LD B,$02
  LD C,$14
  LD A,(BossFlash)
  CP $00
  JR Z,BossHeadHit
  DEC A
  LD (BossFlash),A
BossHeadHit:
  BIT 4,(IY+$09)
  JP Z,BossPart
  RES 4,(IY+$09)
  LD A,$01
  LD (BossFlash),A
  LD A,(BossHits)
  DEC A
  JP Z,BossFlees
  LD (BossHits),A

; The winged boss's parts' common handler: sprite, then the phase
;
; HL, B, C = the part's sprite, width, height into +4/+5, +2, +3. BossPhase 1:
; nothing more. 4: the part is removed
;
; ($B35E). 3: the body (+0 = $10) falls (BossFall), the other parts are
; removed. 2: the flight: the lair's flag
;
; $9B84 set to 4, +$0E = $FF, the colour (BossColour), then +$0A: 0 wait +8
; passes; 1 rise to line +$0B; 2 hover
;
; by BossHoverPath (+8 indexes it; $80 ends: state 3); 3 the attack: +$0D
; counts to $1A, the body (+0 = $0E)
;
; changes its sprite at 10 (BossBodySprite), the head (+0 = $10) shows
; BossHeadFrames between 5 and $11 and at 10
;
; throws (JP $B18B); then back to state 2.
;
; Witness: L1 1947 (rzx-r1).
BossPart:
  LD (IY+$04),L
  LD (IY+$05),H
  LD (IY+$02),B
  LD (IY+$03),C
  LD A,(BossPhase)
  CP $01
  RET Z
  CP $04
  JP Z,RemoveActor
  CP $03
  JR NZ,BossFlight
  LD A,(IY+$00)
  CP $10
  JP NZ,RemoveActor
  JP BossFall
BossFlight:
  LD HL,Grid0Rooms+$000C
  LD (HL),$04
  LD (IY+$0E),$FF
  CALL BossColour
  LD A,(IY+$0A)
  CP $00
  JR NZ,BossRise
  DEC (IY+$08)
  RET NZ
  INC (IY+$0A)
  RET
BossRise:
  CP $01
  JR NZ,BossHover
  DEC (IY+$01)
  LD A,(IY+$01)
  CP (IY+$0B)
  RET NZ
  INC (IY+$0A)
  RET
BossHover:
  CP $02
  JR NZ,BossAttack
  INC (IY+$08)
  LD A,(IY+$08)
  AND $3F
  LD L,A
  LD H,$00
  LD BC,BossHoverPath
  ADD HL,BC
  LD A,(HL)
  CP $80
  JR Z,BossHoverEnd
  ADD A,(IY+$01)
  LD (IY+$01),A
  RET
BossHoverEnd:
  LD (IY+$0A),$03
  LD (IY+$0D),$00
  RET
BossAttack:
  INC (IY+$0D)
  LD A,(IY+$0D)
  CP $1A
  JR Z,BossAttackEnd
  LD A,(IY+$00)
  CP $0E
  JP Z,BossBodySprite
  CP $10
  RET NZ
  LD A,(IY+$0D)
  CP $05
  RET C
  CP $12
  RET NC
  SUB $05
  SLA A
  LD C,A
  LD B,$00
  LD HL,BossHeadFrames
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (IY+$04),E
  LD (IY+$05),D
  LD A,(IY+$0D)
  CP $0A
  JP Z,BossBurst
  RET
BossAttackEnd:
  LD (IY+$0A),$02
  RET

; The head's sprite at each attack step 5-17 (open and close the mouth)
BossHeadFrames:
  DEFW BossHead1,BossHead1
  DEFW BossHead2,BossHead2
  DEFW BossHead3,BossHead3
  DEFW BossHead3,BossHead3
  DEFW BossHead2,BossHead2
  DEFW BossHead1,BossHead1
  DEFW BossHeadSprites

; Set the boss part's colour: white on red while BossFlash, else
; BossColours[PassCounter & 7]
;
; Witness: L1 449 (rzx-r1).
BossColour:
  LD A,(BossFlash)
  CP $00
  JR Z,BossColourCycle
  LD A,$41
  LD (IY+$0C),A
  RET
BossColourCycle:
  LD A,(PassCounter)
  AND $07
  LD L,A
  LD H,$00
  LD BC,BossColours
  ADD HL,BC
  LD A,(HL)
  LD (IY+$0C),A
  RET

; The beaten boss's body falls; at the floor it turns into the next phase
;
; BossColour, then +$0E counts up to $14 and the body drops by
; BossFallSteps[+$0E / 2] lines to line $5C at most.
;
; +$0B - 2 each pass; at 0 the body is removed and $A098 spawns (D = the
; column, E = $60, sprite $EBAC, L = 7,
;
; H = $24) its remains; BossPhase = 4.
;
; Witness: L1 41 (rzx-r1).
BossFall:
  CALL BossColour
  LD A,(IY+$0E)
  INC A
  CP $14
  JR Z,BossFallDrop
  LD (IY+$0E),A
BossFallDrop:
  SRL A
  LD C,A
  LD B,$00
  LD HL,BossFallSteps
  ADD HL,BC
  LD A,(IY+$01)
  ADD A,(HL)
  CP $5C
  JR C,BossFallLine
  LD A,$5C
BossFallLine:
  LD (IY+$01),A
  DEC (IY+$0B)
  DEC (IY+$0B)
  RET NZ
  LD D,(IY+$00)
  LD E,$60
  LD L,$07
  LD H,$24
  LD BC,ItemIconKind7
  CALL RemoveActor
  CALL SpawnItem
  LD A,$04
  LD (BossPhase),A
  RET

; The lines the falling body drops by, from rising (-4) to falling fast (5)
BossFallSteps:
  INCBIN "res/stage1/table-boss-fall-steps.bin",$0000,11

; The body's sprite of the attack: $DF0C under step 10, $DE4C from it
;
; Witness: L1 22 (rzx-r1).
BossBodySprite:
  LD DE,BossBodySprites
  LD A,(IY+$0D)
  CP $0A
  JR NC,BossBodySpriteSet
  LD DE,BossBodyStill
BossBodySpriteSet:
  LD (IY+$04),E
  LD (IY+$05),D
  RET

; Grow a part's height to $20 while its state is 1 (no caller)
;
; Then BossPart. No template or code names $9007: a leftover.
;
; Not executed in any recording (the recordings checked: c1o, deaths, rzx-r1,
; s1-idle, s1-right); known only from the code.
BossGrowPart:
  LD A,(IY+$0A)
  CP $01
  JP NZ,BossPart
  LD A,(IY+$03)
  CP $20
  JP Z,BossPart
  INC (IY+$03)
  JP BossPart

; The boss's colours over 8 passes (ink 7 down to 3 and back)
BossColours:
  INCBIN "res/stage1/table-boss-colours.bin",$0000,8

; The line steps of the hover, 64 bytes (+8 & $3F); $80 ends the hover
BossHoverPath:
  INCBIN "res/stage1/table-boss-hover-path.bin",$0000,64

  ORG $90E7

; Actor handler: the arena boss's head (opens its mouth, breathes)
;
; Template $9D10. Removed once ArenaBossBeaten. +$0A counts down from 16-23
; (random); in state 6 it breathes
;
; ($B1D5); the frame is ArenaHeadMouth[min(+$0A, 7)] of ArenaHeadFrames
; (sprites $CED2: 6 x 40 closed, 7 x 38 open).
;
; Stage 1: the green dragon's head.
;
; Witness: L1 81 (rzx-r1).
ArenaHeadActor:
  LD A,(ArenaBossBeaten)
  CP $00
  JP NZ,RemoveActor
  LD A,(IY+$0A)
  CP $06
  CALL Z,BossShots
  LD A,(IY+$0A)
  CP $00
  JR NZ,ArenaHeadCount
  CALL Random
  AND $07
  ADD A,$10
  LD (IY+$0A),A
ArenaHeadCount:
  DEC (IY+$0A)
  LD C,$07
  LD A,(IY+$0A)
  CP $08
  JR NC,ArenaHeadFrame
  LD C,A
ArenaHeadFrame:
  LD B,$00
  LD HL,ArenaHeadMouth
  ADD HL,BC
  LD A,(HL)
  CALL SetActorFrame

; SetFrame's data: the frame records $D0CC, the sprite bytes $CED2
ArenaHeadFrames:
  DEFB $CC,$D0,$D2,$CE

; The frame at each count 0-7 (1: the mouth open)
ArenaHeadMouth:
  DEFB $00,$01,$01,$01,$01,$01,$00,$00

; Actor handler: a statue head that spits at the hero and breaks after hits
;
; Templates $9CF7 and $9D09. Colour 3; a hit (+9 bit 4) flashes it ($41) and
; takes one of +$0B, at 0 it breaks
;
; (JP $A19B). Idle at frame 0 until Random & $0F is 4, then +8 counts 0-11
; (frames 0, 1, 2, 2, 1, 0 of
;
; StatueFrameSeq, +8 / 2) and at 3 spits (FireShot $B497). Sprites $DA00 (3 x
; 31: the horse-like head).
;
; Witness: L1 2167 (rzx-r1, s1-right).
StatueActor:
  LD (IY+$0C),$03
  BIT 4,(IY+$09)
  JR Z,StatueIdle
  RES 4,(IY+$09)
  LD (IY+$0C),$41
  DEC (IY+$0B)
  JP Z,ScoreBurst64
StatueIdle:
  LD A,(IY+$08)
  CP $00
  JR Z,StatueWait
StatueAnimate:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $03
  CALL Z,SpawnActorShot
  LD A,(IY+$08)
  CP $0C
  JP NZ,StatueFrame
  LD (IY+$08),$00
  JP StatueFrame
StatueWait:
  CALL Random
  AND $0F
  CP $04
  JR Z,StatueAnimate
StatueFrame:
  LD C,(IY+$08)
  SRL C
  LD B,$00
  LD HL,StatueFrameSeq
  ADD HL,BC
  LD A,(HL)
  CALL SetActorFrame

; SetFrame's data: the frame records $DB1A, the sprite bytes $DA00
StatueFrames:
  DEFB $1A,$DB,$00,$DA

; The frames of one spit
StatueFrameSeq:
  DEFB $00,$01,$02,$02,$01,$00

; Actor handler: a hanged body that swings and strikes the hero passing under
; it
;
; Templates $9C8B and $9C94. Sprite $C533, 2 bytes x $25 lines, 8 frames of 74
; bytes. A hit removes it ($A1CF,
;
; $A48E). State 0: the swing, a frame each 3rd pass; after +$0E swings state 1.
; State 1: frame 0; the hero within 2
;
; columns and less than $18 lines under it loses 4 (DamageHero), the body
; swings again for 4-11 times.
;
; Witness: L1 9786 (c1o, deaths, rzx-r1, s1-right).
HangingActor:
  LD (IY+$02),$02
  LD (IY+$03),$25
  BIT 4,(IY+$09)
  JR Z,HangingSwing
  CALL ScoreBurst160
  CALL MarkPlacementDone
  JP RemoveActor
HangingSwing:
  LD A,(IY+$0A)
  CP $00
  JP NZ,HangingStill
  LD A,(IY+$0B)
  INC A
  CP $03
  LD (IY+$0B),A
  RET NZ
  LD (IY+$0B),$00
  LD A,(IY+$08)
  INC A
  AND $07
  LD (IY+$08),A
  LD L,A
  LD H,$00
  ADD HL,HL
  PUSH HL
  ADD HL,HL
  ADD HL,HL
  PUSH HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  POP BC
  ADD HL,BC
  POP BC
  ADD HL,BC
  LD BC,HangingSprites
  ADD HL,BC
  LD (IY+$04),L
  LD (IY+$05),H
  LD A,(IY+$08)
  CP $00
  RET NZ
  DEC (IY+$0E)
  RET NZ
  LD (IY+$0A),$01
  RET
HangingStill:
  LD HL,HangingSprites
  LD (IY+$04),L
  LD (IY+$05),H
  LD E,(IY+$00)
  LD A,(HeroRecord)
  SUB $01
  LD D,A
  LD A,$02
  CALL AbsDiffBelow
  RET NC
  LD E,(IY+$01)
  LD A,(HeroY)
  SUB $10
  LD D,A
  LD A,$18
  CALL AbsDiffBelow
  RET NC
  LD (IY+$0A),$00
  CALL Random
  AND $07
  ADD A,$04
  LD (IY+$0E),A
  LD C,$04
  JP DamageHero

  ORG $9353

; Spawn a warrior (two records) at a random place of the room, when the room
; allows
;
; Needs a free pair (FindFreeActorPair). D = Random & 3 picks one of the room's
; 4 places (bits 3-0 of
;
; SpawnRooms[RoomNumber]); the place's column is D x 6 + 3, its line $1C, or
; $70 when bit 4 is set. Not when another
;
; body stands within 2 columns (IsColumnTaken). Spawns WarriorTemplate $9D7D (a
; warrior that rises from the ground,
;
; +$0B = 1 for the upper line) and its head $9D8F in the next record.
;
; Witness: L1 438 (c1o, deaths, rzx-r1, s1-idle, s1-right).
SpawnRandomEnemy:
  CALL FindFreeActorPair
  RET NZ
  LD A,(RoomNumber)
  LD C,A
  LD B,$00
  LD IX,SpawnRooms
  ADD IX,BC
  LD E,$08
  CALL Random
  AND $03
  LD D,A
  JR Z,SpawnPlaceTest
  LD B,A
SpawnPlaceShift:
  SRL E
  DJNZ SpawnPlaceShift
SpawnPlaceTest:
  LD A,(IX+$00)
  AND E
  RET Z
  LD A,D
  SLA A
  LD D,A
  SLA A
  ADD A,D
  ADD A,$03
  LD D,A
  LD E,$1C
  BIT 4,(IX+$00)
  JR Z,SpawnPlaceFree
  LD E,$70
SpawnPlaceFree:
  CALL IsColumnTaken
  RET NZ
  LD HL,WarriorTemplate
  CALL SpawnActor
  BIT 4,(IX+$00)
  JR NZ,SpawnHead
  LD (IY+$0B),$01
SpawnHead:
  LD BC,$0012
  ADD IY,BC
  LD HL,WarriorHeadTemplate
  LD D,$1F
  LD E,$A0
  CALL SpawnActor
  RET

; Per room: bits 0-3 the 4 spawn places allowed, bit 4 the lower line
SpawnRooms:
  DEFB $00,$0F,$00,$04,$06,$00,$00,$10,$15,$00,$00,$00,$00,$11,$15,$1C,$15,$00

; NZ when an actor with a body (+$0F bit 2) stands within 2 columns of D
;
; Over the 14 records from the hero $74E0.
;
; Witness: L1 67 (c1o, deaths, rzx-r1, s1-right).
IsColumnTaken:
  PUSH IX
  LD IX,HeroRecord
  LD B,$0E
IsColumnTakenLoop:
  PUSH BC
  PUSH DE
  BIT 2,(IX+$0F)
  JR Z,IsColumnTakenNext
  LD E,(IX+$0D)
  LD A,$02
  CALL AbsDiffBelow
  JR Z,IsColumnTakenYes
  JR NC,IsColumnTakenNext
IsColumnTakenYes:
  POP DE
  POP BC
  POP IX
  JP ReturnNZ
IsColumnTakenNext:
  LD BC,$0012
  ADD IX,BC
  POP DE
  POP BC
  DJNZ IsColumnTakenLoop
  POP IX
  JP ReturnZ

; Actor handler: the warrior's head (the record after the warrior)
;
; Follows the warrior one record before (IY - $12): while it rises (state 1)
; the head flies in onto its shoulders
;
; (WarriorHeadAssemble; then the warrior's state + 1); when it collapses (state
; 5) the head flies off
;
; (WarriorHeadFly); else the head is hidden (+$0F bit 6).
;
; Witness: L1 3809 (c1o, deaths, rzx-r1, s1-right).
WarriorHeadActor:
  RES 6,(IY+$0F)
  LD A,(IY-$08)
  CP $01
  JP Z,WarriorHeadAssemble
  CP $05
  JP Z,WarriorHeadFly
  SET 6,(IY+$0F)
  LD (IY+$08),$FF
  RET

; The head comes down onto the rising warrior
;
; FollowLeader; +8 counts to $22, the frame WarriorHeadSteps[+8 / 2]; at $22
; the warrior's +8 = $FF and its state
;
; + 1.
;
; Witness: L1 1232 (c1o, deaths, rzx-r1, s1-right).
WarriorHeadAssemble:
  CALL FollowLeader
  INC (IY+$08)
  LD A,(IY+$08)
  CP $22
  JR NZ,WarriorHeadAssembleFrame
  LD (IY+$08),$00
  LD (IY+$08),$08
  LD (IY-$0A),$FF
  INC (IY-$08)
  RET
WarriorHeadAssembleFrame:
  SRL A
  LD C,A
  LD B,$00
  LD HL,WarriorHeadSteps
  ADD HL,BC
  LD A,(HL)
  JP WarriorSetFrame

; The head's frames while it comes down
WarriorHeadSteps:
  DEFB $0B,$0B,$0B,$0B,$0A,$09,$09,$09,$0A,$0B,$0C,$0D,$0D,$0D,$0C,$0B,$0B

; The head flies off the collapsing warrior
;
; A curve of $26 steps (+$0E by WarriorHeadArc, back by StepFineBack), frame
; $0D; at the end WarriorHeadLand.
;
; Witness: L1 663 (rzx-r1).
WarriorHeadFly:
  LD A,(IY+$08)
  CP $FF
  CALL Z,FollowLeader
  LD A,(IY-$09)
  LD (IY+$09),A
  INC (IY+$08)
  LD A,(IY+$08)
  CP $26
  JP Z,WarriorHeadLand
  CP $1E
  JR NC,WarriorHeadFlyFrame
  LD C,A
  LD B,$00
  LD HL,WarriorHeadArc
  ADD HL,BC
  LD A,(HL)
  ADD A,(IY+$0E)
  LD (IY+$0E),A
  LD A,$01
  CALL StepFineBack
WarriorHeadFlyFrame:
  LD A,$0D
  JP WarriorSetFrame

; The head's line steps of the flight (32 bytes)
WarriorHeadArc:
  DEFB $03,$FD,$FE,$FE,$FE,$FF,$FF,$FF
  DEFB $00,$01,$01,$01,$02,$02,$02,$03
  DEFB $03,$04,$05,$06,$FC,$FD,$FE,$FF
  DEFB $01,$02,$03,$04,$00,$00,$00,$00

; The flown head lands: an item or a pickup in its place
;
; BossPhase 4: $A87B with the head's cell (D, E); else spawns the template
; $EB2C ($B35E then $A098).
;
; Witness: L1 17 (rzx-r1).
WarriorHeadLand:
  LD D,(IY+$00)
  DEC D
  LD A,(IY+$01)
  SUB $08
  AND $F8
  LD E,A
  LD A,(BossPhase)
  CP $04
  JR NZ,WarriorHeadLandPickup
  LD A,E
  ADD A,$04
  LD E,A
  BIT 7,(IY+$09)
  JR Z,WarriorHeadLandBoss
  DEC D
  DEC D
WarriorHeadLandBoss:
  LD B,$00
  LD C,$00
  XOR A
  JP InitFragment
WarriorHeadLandPickup:
  LD L,$05
  LD H,$01
  LD BC,ItemIconKind5
  CALL RemoveActor
  JP SpawnItem

; Actor handler: the warrior (stage 1: a skeleton with sword and shield)
;
; Template $9D7D. By state +$0A: 0 WarriorRise, 2 WarriorFace, 3 WarriorWalk, 4
; WarriorFight, 5 WarriorCollapse,
;
; 6 WarriorBlock, 7 WarriorStrike; state 1 (the head coming down) only shows
; the frame, or WarriorHit on a hit.
;
; Witness: L1 3604 (c1o, deaths, rzx-r1, s1-right).
WarriorActor:
  LD A,(IY+$0A)
  CP $00
  JP Z,WarriorRise
  CP $02
  JP Z,WarriorFace
  CP $03
  JP Z,WarriorWalk
  CP $04
  JP Z,WarriorFight
  CP $05
  JP Z,WarriorCollapse
  CP $06
  JP Z,WarriorBlock
  CP $07
  JP Z,WarriorStrike
  BIT 4,(IY+$09)
  JP NZ,WarriorHit
  JP WarriorFrame

; A RET no code reaches
UnusedRet:
  DEFB $C9

; Copy the leader's base position (record before) into this record; drop both
; if one is gone
;
; When either record's +0 is $FF both are freed and the caller's caller returns
; (POP HL).
;
; Witness: L1 1249 (c1o, deaths, rzx-r1, s1-right).
FollowLeader:
  LD A,(IY-$05)
  LD (IY+$0D),A
  LD A,(IY-$04)
  LD (IY+$0E),A
  LD A,(IY-$12)
  CP $FF
  JR Z,FollowLeaderGone
  LD A,(IY+$00)
  CP $FF
  JR Z,FollowLeaderGone
  RET
FollowLeaderGone:
  LD (IY+$00),$FF
  LD (IY-$12),$FF
  POP HL
  RET

; State 0: the warrior comes up out of the ground (or down onto it)
;
; +$0B 0: up 4 lines a pass to line $4C; else down 4 to $5C or the floor
; (IsSolid $B162). Then +8 counts to 8 and
;
; the state becomes 1.
;
; Witness: L1 702 (c1o, deaths, rzx-r1, s1-right).
WarriorRise:
  LD A,(IY+$0B)
  CP $00
  JR Z,WarriorRiseUp
  LD A,(IY+$0E)
  CP $5C
  JR Z,WarriorRiseDone
  LD A,(IY+$0D)
  ADD A,$05
  LD E,A
  LD A,(IY+$0E)
  ADD A,$24
  LD D,A
  CALL CellAt
  JR NZ,WarriorRiseDone
  LD C,$04
  CALL MoveActorY
  JP WarriorFrame
WarriorRiseDone:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $08
  JP NZ,WarriorFrame
  INC (IY+$0A)
  JP WarriorFrame
WarriorRiseUp:
  LD A,(IY+$0E)
  CP $4C
  JR Z,WarriorRiseDone
  LD C,$FC
  CALL MoveActorY
  JP WarriorFrame

; State 2: turn to the hero, then walk
;
; Witness: L1 26 (c1o, deaths, rzx-r1, s1-right).
WarriorFace:
  LD A,(HeroRecord)
  CP (IY+$00)
  JR NC,WarriorFaceRight
  SET 7,(IY+$09)
  LD E,$FA
  CALL MoveBaseX
  INC (IY+$0A)
  LD (IY+$08),$06
  JP WarriorWalk
WarriorFaceRight:
  INC (IY+$0A)
  LD (IY+$08),$06

; State 3: walk toward the hero; fight when he is in reach
;
; +8 counts 0-$23; at $0B checks the floor ahead and the hero in reach
; (IsHeroInReach): turns (WarriorTurn) when
;
; he is behind, stops for another body ahead (IsWarriorAhead), else fights
; (state 4); at 0 and $12 one column
;
; forward, dropped at the room's edge (column 0 or $1F, $B363). The frame
; WarriorWalkFrames[+8 / 2].
;
; Witness: L1 1109 (c1o, deaths, rzx-r1, s1-right).
WarriorWalk:
  BIT 4,(IY+$09)
  JP NZ,WarriorCollapseStart
  INC (IY+$08)
  LD A,(IY+$08)
  CP $24
  JR NZ,WarriorWalkCheck
  LD (IY+$08),$00
  JR WarriorWalkMove
WarriorWalkCheck:
  CP $0B
  JR NZ,WarriorWalkStep
  LD A,$07
  BIT 7,(IY+$09)
  JR Z,WarriorWalkAhead
  LD A,$FD
WarriorWalkAhead:
  ADD A,(IY+$0D)
  LD E,A
  LD A,(IY+$0E)
  ADD A,$24
  LD D,A
  CALL CellAt
  JR Z,WarriorWalkStop
  CALL IsHeroInReach
  JR Z,WarriorWalkStop
  LD E,$00
  LD A,(HeroRecord)
  CP (IY+$00)
  JR NC,WarriorWalkFacing
  LD E,$80
WarriorWalkFacing:
  LD A,(IY+$09)
  AND $80
  CP E
  JP NZ,WarriorTurn
  CALL IsWarriorAhead
  JR Z,WarriorWalkFrame
WarriorWalkStop:
  INC (IY+$0A)
  RET
WarriorWalkStep:
  LD A,(IY+$08)
  CP $12
  JR NZ,WarriorWalkFrame
WarriorWalkMove:
  LD E,$01
  CALL MoveBaseX
  LD A,(IY+$00)
  CP $1F
  JP Z,RemoveActorPair
  CP $00
  JP Z,RemoveActorPair
WarriorWalkFrame:
  LD A,(IY+$08)
  SRL A
  LD C,A
  LD B,$00
  LD HL,WarriorWalkFrames
  ADD HL,BC
  LD A,(HL)
  JP WarriorSetFrame

; The walk's frames (14-17)
WarriorWalkFrames:
  DEFB $0E,$0E,$0E,$0E,$0E,$0E,$0F,$10,$11,$0E,$0E,$0E,$0E,$0E,$0E,$0F,$10,$11

; Z when the hero stands 3 columns in front, less than 10 lines below the
; warrior's top
;
; Witness: L1 118 (c1o, deaths, rzx-r1, s1-right).
IsHeroInReach:
  LD A,(HeroY)
  SUB (IY+$01)
  JP C,ReturnNZ
  CP $0A
  JP NC,ReturnNZ
  LD A,(HeroRecord)
  LD E,A
  LD A,$03
  BIT 7,(IY+$09)
  JR Z,IsHeroInReachColumn
  LD A,$FD
IsHeroInReachColumn:
  ADD A,(IY+$00)
  CP E
  RET

; State 4: block the hero's blows, strike at random
;
; The hero out of reach: back to walking (state 3) or turning. The hero
; striking (HeroAttacking $7FFA) and facing
;
; it: block (state 6) while +$10 lasts, else collapse. Else 1 in 8 passes
; strikes (state 7) for 4 (DamageHero,
;
; unless the item guard).
;
; Witness: L1 57 (c1o, deaths, rzx-r1, s1-right).
WarriorFight:
  BIT 4,(IY+$09)
  JP NZ,WarriorCollapseStart
  CALL IsHeroInReach
  JR Z,WarriorFightReach
  LD E,$00
  LD A,(HeroFlags)
  BIT 7,A
  JR Z,WarriorFightFacing
  LD E,$80
WarriorFightFacing:
  LD A,(IY+$09)
  AND $80
  CP E
  JP NZ,WarriorTurn
  CALL IsWarriorAhead
  JR NZ,WarriorFightReach
  LD (IY+$08),$00
  DEC (IY+$0A)
  JP WarriorWalk
WarriorFightReach:
  CALL IsHeroInReach
  JR NZ,WarriorFightStrike
  CALL IsHeroHitFrame6
  JR NZ,WarriorFightStrike
  LD A,(HeroFlags)
  AND $80
  LD C,A
  LD A,(IY+$09)
  AND $80
  CP C
  JR Z,WarriorFightStrike
  LD (IY+$0A),$06
  LD (IY+$08),$06
  LD A,(IY+$10)
  CP $00
  JP NZ,WarriorBlock
  JP WarriorCollapseStart
WarriorFightStrike:
  CALL Random
  AND $07
  CP $01
  RET NZ
  CALL IsShieldUp
  JR NZ,WarriorFightSwing
  LD C,$04
  CALL DamageHero
WarriorFightSwing:
  LD (IY+$0A),$07
  LD (IY+$08),$FF
  JP WarriorStrike

; A RET no code reaches
UnusedRet2:
  DEFB $C9

; A hit: turn to the hero and collapse
;
; +$1A (the head's +8) = $FF; state 5.
;
; Witness: L1 13 (rzx-r1).
WarriorHit:
  LD E,$00
  LD A,(HeroRecord)
  CP (IY+$00)
  JR NC,WarriorHitTurn
  LD E,$80
WarriorHitTurn:
  LD A,(IY+$09)
  AND $80
  CP E
  JP Z,WarriorCollapseStart
  LD E,$06
  CALL MoveBaseX
  LD A,(IY+$09)
  XOR $80
  LD (IY+$09),A
; This entry point is used by the routines at WarriorWalk and WarriorFight.
WarriorCollapseStart:
  LD (IY+$0A),$05
  LD (IY+$08),$FF
  LD (IY+$1A),$FF
  JP WarriorCollapse

; Turn round (one column back when facing left) and rise again (state 0, +8 =
; 7)
;
; Witness: L1 12 (c1o, deaths, rzx-r1, s1-right).
WarriorTurn:
  BIT 7,(IY+$09)
  JR Z,WarriorTurnDone
  LD E,$06
  CALL MoveBaseX
  RES 7,(IY+$09)
WarriorTurnDone:
  LD (IY+$0A),$00
  LD (IY+$08),$07
  JP WarriorRise

; State 5: the warrior falls apart (14 frames), then is removed
;
; Witness: L1 485 (rzx-r1).
WarriorCollapse:
  RES 1,(IY+$0F)
  INC (IY+$08)
  LD A,(IY+$08)
  CP $1C
  JP Z,RemoveActor
  SRL A
  CALL SetActorFrame

; SetFrame's data: the frame records $DD95, the sprite bytes $DB2C
WarriorCollapseFrames:
  DEFB $95,$DD,$2C,$DB

; State 6: hold the shield up (frame $12) for +8 passes, then fight on (+$10 -
; 1)
;
; Not executed in any recording (the recordings checked: c1o, deaths, rzx-r1,
; s1-idle, s1-right); known only from the code.
WarriorBlock:
  LD A,$12
  DEC (IY+$08)
  JP NZ,WarriorSetFrame
  LD (IY+$0A),$04
  DEC (IY+$10)
  LD (IY+$08),$01
  LD A,$0E
  CALL WarriorSetFrame
  JP WarriorFight

; State 7: the sword swing (WarriorStrikeFrames), then fight on
;
; Witness: L1 27 (c1o, s1-right).
WarriorStrike:
  INC (IY+$08)
  LD A,(IY+$08)
  CP $08
  JR Z,WarriorStrikeEnd
  SRL A
  LD C,A
  LD B,$00
  LD HL,WarriorStrikeFrames
  ADD HL,BC
  LD A,(HL)
  JP WarriorSetFrame
WarriorStrikeEnd:
  LD (IY+$0A),$04
  LD (IY+$08),$01
  LD A,$0E
  CALL WarriorSetFrame
  JP WarriorFight

; The swing's frames
WarriorStrikeFrames:
  DEFB $13,$14,$14,$13

; Show frame +8 of the warrior's frames
;
; Witness: L1 1970 (c1o, deaths, rzx-r1, s1-right).
WarriorFrame:
  LD A,(IY+$08)

; Show frame A of the warrior's frames (SetFrame $AA02 with WarriorFrames)
;
; Witness: L1 4920 (c1o, deaths, rzx-r1, s1-right).
WarriorSetFrame:
  CALL SetActorFrame

; SetFrame's data: the frame records $CE14, the sprite bytes $C7DF (21 frames)
WarriorFrames:
  DEFB $14,$CE,$DF,$C7

; NZ when another body stands 1 or 2 columns ahead (B = 0: 2, 1: 1)
;
; Witness: L1 49 (c1o, deaths, rzx-r1, s1-right).
IsWarriorAhead:
  LD A,$02
  CALL NegateIfFacingLeft
  ADD A,(IY+$0D)
  LD E,A
  LD A,$01
  CALL NegateIfFacingLeft
  ADD A,(IY+$0D)
  LD D,A
  LD B,$0D
  LD IX,Actors
IsWarriorAheadLoop:
  PUSH BC
  BIT 2,(IX+$0F)
  JR Z,IsWarriorAheadNext
  LD A,(IX+$0D)
  CP E
  JR Z,IsWarriorAhead2
  CP D
  JR Z,IsWarriorAhead1
IsWarriorAheadNext:
  LD BC,$0012
  ADD IX,BC
  POP BC
  DJNZ IsWarriorAheadLoop
  JP ReturnZ
IsWarriorAhead2:
  POP BC
  LD B,$00
  JP ReturnNZ
IsWarriorAhead1:
  POP BC
  LD B,$01
  JP ReturnNZ

  ORG $A7B8

; Carry when |E - D| is under A
;
; In: A the limit, D and E the two values. Out: A = |E - D|, carry set when it
; is under the limit. It stores the
;
; limit into its own compare at AbsDiffLimit $A7C1. Used for the distances
; between the hero and an actor (reach,
;
; pick-up) by the strikeable actors, the fragments and the routines of the
; other modules.
;
; Witness: L1 11424 (c1o, deaths, rzx-r1, s1-idle, s1-right).
AbsDiffBelow:
  LD (AbsDiffLimit+$0001),A
  LD A,E
  SUB D
  JR NC,AbsDiffLimit
  NEG
AbsDiffLimit:
  CP $00                  ; the limit, written by the first instruction
  RET

; Per-pass handler of an actor that the hero's low strike hits (two hits
; destroy it)
;
; Its address is the handler word at $9CA6, $9CAF, $9CB8 and $9CC1 of the room
; data (UpdateActors $A5BD calls the
;
; record's +6/+7). IY = the actor record. When the hero's low strike lands this
; pass ($7FEE: hero state 7 at frame
;
; 4) and InStrikeReach $A816 says the actor is in front of the hero, the hit
; count (the record's +8, which is also
;
; the frame number) goes up: an odd count plays effect 2 and the actor shows
; its damaged frame; an even one destroys
;
; it: score +20 and an explosion ($A065), the actor marked dead in the grid's
; actor list ($A48E), then by the
;
; record's +$10 bits 0-1: 2 drops the object at $A0D6, 1 the object at $A0C3, 0
; bursts it into eight fragments
;
; (ShatterActor $A803).
;
; Each pass it shows frame (+8) of the frame table $E25A over the graphics at
; $E190 (SetActorFrame $AA02). In
;
; stage 1 these are the urns and chests (kinds 3-6 of ActorKinds); the hit path
; runs in rzx-r1 (frames 638 and
;
; 662: placement 2 of room 2 struck twice).
;
; Witness: L1 24767 (c1o, deaths, rzx-r1, s1-idle, s1-right).
StrikeableActor:
  CALL IsHeroHitFrame7
  JR NZ,StrikeableActorFrame
  CALL InStrikeReach
  JR NZ,StrikeableActorFrame
  INC (IY+$08)
  LD A,(IY+$08)
  AND $01
  JR Z,StrikeableActorDies
  LD DE,$0002
  CALL PlaySoundVector
  JP StrikeableActorFrame
StrikeableActorDies:
  CALL ScoreBurst20       ; the second hit: score, explosion, the dead mark,
                          ; then the drop by +$10
  CALL MarkPlacementDone
  LD A,(IY+$10)
  AND $03
  CP $02
  JP Z,DropItemKind1
  CP $01
  JP Z,DropItemKind8
  JP ShatterActor
StrikeableActorFrame:
  LD A,(IY+$08)
  CALL SetActorFrame

; SetActorFrame's parameters: the frame table, the graphics base
StrikeableActorSet:
  DEFW StrikeableFrameTable,StrikeableSprites

; Burst the actor into eight fragments and remove it
;
; IY = the actor. B = its column, C = its line rounded down to 8, +5;
; SpawnFragments $A846 with D = 8, then
;
; RemoveActor $B35E.
;
; Witness: L1 5 (rzx-r1).
ShatterActor:
  LD B,(IY+$00)
  LD A,(IY+$01)
  AND $F8
  ADD A,$05
  LD C,A
  LD D,$08
  CALL SpawnFragments
  JP RemoveActor

; Z when the actor IY stands where the hero's strike lands
;
; The actor's column must be the hero's column $74E0 + 3 when the hero faces
; right ($74E9 bit 7 clear), - 3 when
;
; he faces left, and its line within 24 ($18) of the hero's line $74E1
; (AbsDiffBelow $A7B8). Out: Z (ReturnZ
;
; $B2DC) in reach, NZ (ReturnNZ $B2E1) not.
;
; Witness: L1 54 (c1o, rzx-r1).
InStrikeReach:
  LD E,(IY+$00)
  LD A,(HeroFlags)
  BIT 7,A
  JR Z,InStrikeReachRight
  LD A,(HeroRecord)
  SUB $03
  CP E
  JR Z,InStrikeReachLine
  JR InStrikeReachMiss
InStrikeReachRight:
  LD A,(HeroRecord)
  ADD A,$03
  CP E
  JR NZ,InStrikeReachMiss
InStrikeReachLine:
  LD E,(IY+$01)
  LD A,(HeroY)
  LD D,A
  LD A,$18
  CALL AbsDiffBelow
  JR NC,InStrikeReachMiss
  JP ReturnZ
InStrikeReachMiss:
  JP ReturnNZ

; Start D fragment actors at column B, line C
;
; Seeds the random pointer RandomPointer $FE0A with $07CF (so every burst looks
; the same), writes B and C into the
;
; LD D / LD E at FragmentColumn $A85D and FragmentLine $A85F, and for each of
; the D fragments takes a free actor
;
; record (FindFreeActor $8D3A; it stops quietly when none is free), random
; parameters (RandomFragmentParams $A86D)
;
; and starts it (InitFragment $A87B). IY is kept.
;
; Witness: L1 5 (rzx-r1).
SpawnFragments:
  LD HL,$07CF
  LD (RandomPointer),HL
  LD A,B
  LD (FragmentColumn+$0001),A
  LD A,C
  LD (FragmentLine+$0001),A
  PUSH IY
  LD B,D
SpawnFragmentsLoop:
  PUSH BC
  CALL FindFreeActor
  JR NZ,SpawnFragmentsNext
FragmentColumn:
  LD D,$00                ; LD D,n: n = the column, written by SpawnFragments
FragmentLine:
  LD E,$00                ; LD E,n: n = the line, written by SpawnFragments
  CALL RandomFragmentParams
  CALL InitFragment
SpawnFragmentsNext:
  POP BC
  DJNZ SpawnFragmentsLoop
  POP IY
  RET

; B = its arc (0-3), C = its speed (0-3), A = its facing (bit 7)
;
; From two Random $8B85 bytes: B = the first AND 3, C = the second AND 3, A =
; the second AND $80.
;
; Witness: L1 37 (rzx-r1).
RandomFragmentParams:
  CALL Random
  AND $03
  LD B,A
  LD A,(HL)
  AND $03
  LD C,A
  LD A,(HL)
  AND $80
  RET

; Fill the actor record IY as a fragment and run its first step
;
; Copies the fragment template $9D6B into the record (InitActor $A4B1 with D, E
; the column and line), then the
;
; record's +9 = A (facing), +$0A = B (the arc), +8 = C (the speed in pixels a
; step), and goes on into FragmentActor.
;
; Also jumped to from $94C0 (a fragment with B = C = 0, A = 0).
;
; Witness: L1 44 (rzx-r1).
InitFragment:
  PUSH BC
  PUSH AF
  LD HL,FragmentTemplate
  CALL SpawnActor
  POP AF
  POP BC
  LD (IY+$09),A
  LD (IY+$0A),B
  LD (IY+$08),C
  JP FragmentActor

; Per-pass handler of a fragment: fly an arc, land, lie, sink, be picked up
;
; The handler word of the fragment template ($9D71). IY = the fragment. Its
; colour alternates (ColourRedMagenta
;
; $B377). The step counter +$0B runs from 0: steps 5, $0E, $14 and $17 play
; effect 3 (a bounce); each step moves
;
; it by +8 pixels a pass across (MoveFragment $A97A, reversed when facing left)
; and down by the step's entry of
;
; FragmentArc0 $A9CA (arc +$0A = 0) or FragmentArc1 $A9E6 (other arcs; doubled
; when +$0A bit 1 is set); from step
;
; $18 it no longer moves across. At steps 9, $10, $15 and $17 it looks at the
; cell under it (column + 2, line +
;
; $16, $14 or $0E; CellAt $B162): no solid ground there makes it fall (step
; $1C: 7 lines a pass, removed under line
;
; $90). Step $1B is the rest (FragmentRest $A91D): +$0E counts down; under 6 it
; sinks 3 lines a pass and at 0 it is
;
; removed. A fragment the hero touches (his column or the one left of it, his
; line within $20) is taken: the pending
;
; energy change EnergyChange $FE4E + 6, score +25, effect 5, and it is removed.
;
; Witness: L1 2817 (rzx-r1).
FragmentActor:
  CALL ColourRedMagenta
  LD (IY+$0C),C
  LD A,(IY+$0B)
  CP $1C
  JP Z,FragmentFall
  CP $1B
  JR Z,FragmentRest
  INC (IY+$0B)
  LD A,(IY+$0B)
  CP $05
  JR Z,FragmentBounce
  CP $0E
  JR Z,FragmentBounce
  CP $14
  JR Z,FragmentBounce
  CP $17
  JR NZ,FragmentStep
FragmentBounce:
  LD DE,$0003
  CALL PlaySoundVector
FragmentStep:
  LD C,(IY+$0B)
  LD B,$00
  LD HL,FragmentArc0
  LD A,(IY+$0A)
  CP $00
  JR Z,FragmentArcEntry
  LD HL,FragmentArc1
FragmentArcEntry:
  ADD HL,BC
  LD A,(IY+$0B)
  CP $18
  JR C,FragmentDrop
  LD E,$00
  JR FragmentMove
FragmentDrop:
  LD E,(IY+$08)
  LD A,(IY+$01)
  ADD A,(HL)
  BIT 1,(IY+$0A)
  JR Z,FragmentSetLine
  ADD A,(HL)
FragmentSetLine:
  LD (IY+$01),A
FragmentMove:
  CALL MoveFragment
  LD A,(IY+$0B)
  LD C,$16
  CP $09
  JR Z,FragmentGround
  LD C,$14
  CP $10
  JR Z,FragmentGround
  CP $15
  JR Z,FragmentGround
  LD C,$0E
  CP $17
  RET NZ
FragmentGround:
  LD A,(IY+$00)
  ADD A,$02
  LD E,A
  LD A,(IY+$01)
  ADD A,C
  LD D,A
  CALL CellAt
  RET NZ
  LD (IY+$0B),$1C
  RET
FragmentRest:
  LD A,(IY+$0E)
  CP $00
  JR Z,FragmentTouch
  DEC A
  LD (IY+$0E),A
  CP $06
  JR NC,FragmentTouch
  CP $00
  JP Z,RemoveActor
  LD A,(IY+$01)
  ADD A,$03
  LD (IY+$01),A
FragmentTouch:
  LD A,(HeroRecord)
  LD E,A
  LD A,(IY+$00)
  CP E
  JR Z,FragmentTouchLine
  DEC E
  CP E
  RET NZ
FragmentTouchLine:
  LD A,(HeroY)
  LD E,A
  LD D,(IY+$01)
  LD A,$20
  CALL AbsDiffBelow
  RET NC
  LD A,(EnergyChange)
  ADD A,$06
  LD (EnergyChange),A
  LD BC,$0019
  CALL AddScore
  LD DE,$0005
  CALL PlaySoundVector
  JP RemoveActor
FragmentFall:
  LD A,(IY+$01)
  ADD A,$07
  LD (IY+$01),A
  CP $90
  JP NC,RemoveActor
  LD E,(IY+$08)

; Move the fragment E pixels across and point it at its pre-shifted image
;
; IY = the fragment, E = the pixels (negated when it faces left, +9 bit 7). The
; pixel column (+0 x 8 + the
;
; sub-column +$0D) moves by E; +0 and +$0D take the new column and pixel. The
; image pointer +4/+5 = $E9E4 + $21 x
;
; the shift (Multiply $8B24; the shift is the pixel, or 7 - the pixel when it
; faces left): eight pre-shifted copies
;
; of 33 bytes. A fragment that reaches column 0 or 31 is removed (RemoveActor
; $B35E).
;
; Witness: L1 1223 (rzx-r1).
MoveFragment:
  LD A,(IY+$00)
  SLA A
  SLA A
  SLA A
  ADD A,(IY+$0D)
  LD D,A
  LD A,E
  BIT 7,(IY+$09)
  JR Z,MoveFragmentColumn
  NEG
MoveFragmentColumn:
  ADD A,D
  LD D,A
  AND $07
  LD (IY+$0D),A
  SRL D
  SRL D
  SRL D
  LD (IY+$00),D
  LD A,(IY+$0D)
  BIT 7,(IY+$09)
  JR Z,MoveFragmentImage
  LD C,A
  LD A,$07
  SUB C
MoveFragmentImage:
  LD B,$21
  CALL Multiply
  LD BC,FragmentSprites
  ADD HL,BC
  LD (IY+$04),L
  LD (IY+$05),H
  LD A,(IY+$00)
  CP $01
  JP C,RemoveActor
  CP $1F
  JP NC,RemoveActor
  RET

; The line change of each step of a fragment's arc 0 (28 signed bytes)
;
; Read by FragmentActor $A891 (+$0B the step): up 8, 6, 4, 2, 1 lines, then
; down 1, 2, 4, 6, 8, a short second hop
;
; and the rest. Known only from the code (FragmentActor never ran in a
; recording with an L1).
FragmentArc0:
  DEFB $F8,$FA,$FC,$FE,$FF,$00,$01
  DEFB $02,$04,$06,$08,$FC,$FE,$FF
  DEFB $00,$01,$02,$04,$FE,$FF,$00
  DEFB $01,$02,$00,$00,$01,$01,$00
FragmentArc1:
  DEFB $FB,$FC,$FD,$FE,$FF,$00,$01 ; the arcs 1-3 (doubled for 2 and 3): a
  DEFB $02,$03,$04,$05,$FD,$FE,$FF ; lower hop
  DEFB $00,$01,$02,$03,$FE,$FF,$00
  DEFB $01,$02,$00,$00,$01,$01,$00

  ORG $B18B

; Throw eight shots round the boss (four of type 4, four of type 5)
;
; IY = the boss. Type 4 at its column + 3 .. + 1, line + $14, +4 = $FF, 1, 3,
; 4; type 5 at column - 2 .. - 0 with
;
; the same +4 values; effect 6. Jumped to from $8F64 (the boss's handler) when
; its +$0D is $0A.
;
; Witness: L1 1 (rzx-r1).
BossBurst:
  LD A,(IY+$00)
  ADD A,$03
  LD D,A
  LD A,(IY+$01)
  ADD A,$14
  LD E,A
  LD C,$04
  LD B,$FF
  CALL AddMissile
  INC D
  LD B,$01
  CALL AddMissile
  DEC D
  LD B,$03
  CALL AddMissile
  DEC D
  LD B,$04
  CALL AddMissile
  LD A,(IY+$00)
  SUB $02
  LD D,A
  LD C,$05
  LD B,$FF
  CALL AddMissile
  DEC D
  LD B,$01
  CALL AddMissile
  INC D
  LD B,$03
  CALL AddMissile
  INC D
  LD B,$04
  CALL AddMissile
  LD DE,$0006
  JP PlaySoundVector

; Two shots of type 5 from the boss, the pair alternating with each call
;
; IY = the boss; its +$0B counts the calls. Odd: +4 = 1 and 2; even: 3 and 4;
; at its column, line + $10; effect 8.
;
; Called from $90F2 when the boss's state is 6.
;
; Witness: L1 3 (rzx-r1).
BossShots:
  LD A,(IY+$00)
  ADD A,$00
  LD D,A
  LD A,(IY+$01)
  ADD A,$10
  LD E,A
  LD C,$05
  INC (IY+$0B)
  LD A,(IY+$0B)
  AND $01
  JP Z,BossShotsEven
  LD B,$01
  CALL AddMissile
  DEC D
  LD A,E
  ADD A,$02
  LD E,A
  LD B,$02
  CALL AddMissile
  LD DE,$0008
  JP PlaySoundVector
BossShotsEven:
  LD B,$03
  CALL AddMissile
  INC D
  LD B,$04
  CALL AddMissile
  LD DE,$0008
  JP PlaySoundVector

; A shot of type 2 at the actor IY with a random +5 ($FA asks AddMissile for
; one); effect 6
;
; No CALL, JP or word in the image reaches it.
;
; Not executed in any recording (the recordings checked: c1o, deaths, rzx-r1,
; s1-idle, s1-right); known only from the code.
AimedShot:
  LD A,(IY+$01)
  LD E,A
  LD A,(IY+$00)
  LD D,A
  LD C,$02
  LD B,$01
  LD A,$FA
  CALL AddMissile
  LD DE,$0006
  JP PlaySoundVector

  ORG $B497

; An actor shoots: a missile of kind $0A (facing right) or $0B (left) in front
; of it
;
; IY = the actor. Column + 1 (facing right) or its column (left), line + 2
; (AddMissile $B28D, B = A = 0). Called from
;
; $9152.
;
; Witness: L1 57 (rzx-r1, s1-right).
SpawnActorShot:
  LD D,(IY+$00)
  INC D
  LD A,(IY+$01)
  ADD A,$02
  LD E,A
  LD C,$0A
  BIT 7,(IY+$09)
  JR Z,SpawnActorShotAdd
  LD C,$0B
  DEC D
SpawnActorShotAdd:
  LD B,$00
  XOR A
  JP AddMissile
