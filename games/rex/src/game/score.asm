; --------------------------------------------------------------------------------------------------------------------
; score.asm: The kills, the score, the lives and the shield figure
;
; A killed object (KillObject $981F, from a bullet, the smart bomb, a collision or a fall) scores KillScores
; $994E[kind] x 100 points (AddScore $9A27), turns into the points sign (ShowPoints $97FD) and, for the six kinds that
; are people (0 foot man, 4, 5, 6, 7 and 12), adds one to HumansKilled $A089 and leaves the human's picture (KillHuman
; $98A7). The game over panel prints HumansKilled. Every 100 x 100 points (ExtraLifeCount $A076) gives a life, at most
; 9.
; --------------------------------------------------------------------------------------------------------------------

  ORG $97FD

; Turn the object at IX into the points sign: picture SpritePoints $81B2, kind
; $FF (no collisions), at rest
;
; Witness: L1 5 (rzx-p1-24000).
ShowPoints:
  LD HL,SpritePoints
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0D),$08
  LD (IX+$0F),$18
  LD (IX+$0E),$03
  LD (IX+$09),$FF
  LD (IX+$02),$00
  LD (IX+$03),$00
  RET

; Kill the object at IX: its score, the kill flash in the HUD, the explosion
; sound; people add to HumansKilled
;
; The kill flash: KillFlashPtr $A039 = the attribute address of the object's
; column in the HUD row (bright), timer $A03C. Kind 14 (the mine) scores
; nothing. Kinds 3 and 4 also end the scripted spawn (EndScriptSpawn $9968).
; Then KillHuman $98A7 or ShowPoints $97FD.
;
; Witness: L1 1009 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room24, p1-room30, rzx-p1- x32).
KillObject:
  LD HL,ObjectBufferOrigin
  LD (KillFlashPtr),HL
  LD HL,$0000
  LD (ComboTimer),HL
  LD A,(IX+$09)
  CP $90
  JP Z,KillScore
  LD A,(IX+$01)
  CP $B0
  RET NC
  CP $10
  RET C
  LD A,(IX+$09)
  CP $05
  CALL Z,EndScriptSpawn
  LD HL,SpritePoints
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0D),$08
  LD (IX+$0F),$18
  LD (IX+$0E),$03
  LD A,(IX+$09)
  OR A
  CALL Z,KillHuman
  CP $07
  CALL Z,KillHuman
  CP $06
  CALL Z,KillHuman
  CP $0C
  CALL Z,KillHuman
  CP $04
  CALL Z,KillHuman
  CP $05
  CALL Z,KillHuman
  AND $0F
  LD E,A
  LD D,$00
  LD HL,KillScores
  ADD HL,DE
  LD E,(HL)
  LD D,$00
  LD A,E
  OR A
  CALL NZ,AddScore
  LD DE,SfxExplosion
  CALL StartSfx
  LD (IX+$09),$FF
  LD (IX+$02),$00
  LD A,(IX+$01)
  SUB $08
  AND $F8
  LD (IX+$01),A
  LD (IX+$03),$00
  RET

; A person killed: HumansKilled $A089 + 1, the human's picture SpriteHuman
; $92F2, the panel of a kill
;
; For kinds 0, 7, 6, 12, 4 and 5. The object becomes a falling body;
; FindFreeObject $D858 and the human's initialiser ($CDA2, $CE67) set up its
; picture.
;
; Witness: L1 152 (c1, p1-room24, p1-room30, rzx-p1- x27).
KillHuman:
  LD HL,(HumansKilled)
  INC HL
  LD (HumansKilled),HL
  RET
; This entry point is used by the routine at KillObject.
KillScore:
  LD DE,$000A             ; the kind's score
  CALL AddScore
  CALL KillHumanPicture
  LD (IX+$12),$01
  LD A,$0F
  LD (ObjectCount),A
  LD HL,SpriteHuman
  LD (IX+$04),L
  LD (IX+$05),H
  LD A,(IX+$00)
  LD (Temp1),A
  LD A,(IX+$01)
  LD (Temp2),A
  LD A,(IX+$13)
  LD (Temp3),A
  INC (IX+$13)
  LD A,(IX+$13)
  CP $02
  JP NZ,KillHumanMake
  CALL InitKind12
  LD (IX+$16),E
  LD (IX+$17),D
  LD (IX+$15),$00
  LD (IX+$0A),L
  LD (IX+$0B),H
  LD (IX+$0E),$03
  LD (IX+$0F),$10
  LD (IX+$09),$0C
  LD (IX+$14),$08
KillHumanMake:
  PUSH IX                 ; the human's body in a free record
  LD B,$05
KillHumanSet:
  PUSH BC                 ; its picture and size
  CALL FindFreeObject
  CALL ShowPoints
  CALL Random
  AND $01
  LD (IX+$15),A
  LD A,(Temp3)
  OR A
  JP NZ,KillHumanLive
  LD (IX+$15),$FF
KillHumanLive:
  LD (IX+$0C),$01         ; alive
  CALL Random
  AND $1F
  LD L,A
  LD A,(Temp1)
  ADD A,L
  LD (IX+$00),A
  CALL Random
  AND $1F
  LD L,A
  LD A,(Temp2)
  ADD A,L
  AND $F8
  LD (IX+$01),A
  POP BC
  DJNZ KillHumanSet
  POP IX
  RET

; The score of each object kind, in hundreds: kind 0 1, 1 2, 2 1, 3 1, 4 2, 5
; 3, 6 1, 7 1, 8 6, 9 6, 10 5, 11 8, 12 3, 13 10, 14 0, 15 2, then 1s
;
; The menu's roll call agrees: FOOT MAN 100, STOMPER 200, SCANNER 600, SWING
; GUN 600, SHOOTERS 500, LAUNCHER 800, RAMMING POD 300, MINE LAYER 1000, MINE
; no score, BLOB 200.
KillScores:
  INCBIN "res/tables/rex1-kill-scores.bin",$0000,26

; Stop the scripted spawn: the objects of kinds 3 and 4 lose their timer
; ($9989)
;
; Witness: L1 2 (rzx-p1-04000, rzx-p1-12000).
EndScriptSpawn:
  PUSH IY
  LD IY,$5E66
  LD A,(ObjectCount)
  LD B,A
EndSpawnLoop:
  LD A,(IY+$09)           ; each object
  CP $03
  CALL Z,StopObjectSpawn
  CP $04
  CALL Z,StopObjectSpawn
  LD DE,$0018
  ADD IY,DE
  DJNZ EndSpawnLoop
  POP IY
  RET

; IY's object: timer (IY+$10) = 0, ScriptSpawnStep $A045 = 0
;
; Witness: L1 10 (rzx-p1-04000, rzx-p1-12000).
StopObjectSpawn:
  LD (IY+$10),$00
  XOR A
  LD (ScriptSpawnStep),A
  RET

; Fade the HUD's kill flash one step (attribute row $5840, 30 cells), then mark
; the latest kill's two cells white
;
; Witness: L1 16926 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
KillFlashFade:
  LD HL,$5840
  LD B,$1E
FadeHudLoop:
  LD A,(HL)               ; each HUD attribute one step darker
  DEC A
  CP $FF
  JP Z,FadeHudNext
  LD (HL),A
FadeHudNext:
  INC HL                  ; the next cell
  DJNZ FadeHudLoop
  LD HL,(KillFlashPtr)
  LD (HL),$07
  INC HL
  LD (HL),$07
  RET

; Print Score $A03E in the HUD
;
; Witness: L1 299 (c1, p1-code, p1-room30, rzx-p1- x31).
ShowScore:
  LD HL,(Score)
  CALL ToDigits
  LD E,$10
  LD L,$00
  LD B,$05
  CALL PrintDigits
  RET

; Print Lives $A063 in the HUD
;
; Witness: L1 53 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room24,
; p1-room30, rzx-p1- x26).
ShowLives:
  LD A,(Lives)
  LD L,A
  LD H,$00
  CALL ToDigits
  LD E,$17
  LD L,$00
  LD B,$01
  CALL PrintDigits
  RET

; ShieldDrainRate $A04E - 1: a hit on the shield drains it faster
; (EnemyBulletsHitRex, ObjectHitsRex)
;
; Witness: L1 80 (p1-room30, rzx-p1- x21).
ShieldDrainFast:
  LD A,$01
  LD (ShieldDrainRate),A

; With the shield on, count ShieldDrainRate down; at 0 one unit of ShieldEnergy
; $A04D goes; none left switches the shield off
;
; Witness: L1 2693 (p1-code, p1-cursor, p1-define, p1-kempston, p1-room26,
; p1-room30, rzx-p1- x29).
ShieldDrain:
  LD A,(ShieldDrainRate)
  DEC A
  LD (ShieldDrainRate),A
  OR A
  RET NZ
  LD A,$04
  LD (ShieldDrainRate),A
  LD A,(ShieldEnergy)
  SUB L
  JP C,ShieldOff
  LD (ShieldEnergy),A
  CALL ShowShield
  RET
ShieldOff:
  XOR A                   ; no energy: the shield off
  LD (ShieldEnergy),A
  LD (ShieldOn),A
  CALL ShowShield
  RET

; Print ShieldEnergy $A04D in the HUD and colour it: red when low, green
; otherwise ($E513, $E514 in the attribute shadow)
;
; Witness: L1 1442 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room x5,
; rzx-p1- x32).
ShowShield:
  LD A,(ShieldEnergy)
  LD L,A
  LD H,$00
  CALL ToDigits
  LD E,$15
  LD L,$00
  LD B,$02
  CALL PrintDigits
  LD A,(ShieldEnergy)
  SRL A
  SRL A
  SRL A
  SRL A
  AND $07
  INC A
  LD ($5815),A
  LD ($5814),A
  LD (ShieldAttrs+$0001),A
  LD (ShieldAttrs),A
  RET

; Score $A03E + HL; every 100 points ExtraLifeCount $A076 counts, at 100 an
; extra life (ExtraLife $D5A0)
;
; Not while Rex is dying. Jumps to ShowScore.
;
; Witness: L1 442 (c1, p1-code, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-room24, p1-room30, rzx-p1- x32).
AddScore:
  LD A,(Dying)
  OR A
  RET NZ
  LD HL,(Score)
  ADD HL,DE
  LD (Score),HL
  LD HL,(ExtraLifeCount)
  ADD HL,DE
  LD (ExtraLifeCount),HL
  LD DE,$0064
  AND A
  SBC HL,DE
  JP C,AddScoreShow
  LD (ExtraLifeCount),HL
  CALL ExtraLife
AddScoreShow:
  JP ShowScore            ; print it

; The screen flash of a smart bomb or a bonus: the attribute shadow faded
; through FadeSteps $9AB3 by FadeStepIndex $A042
;
; Witness: L1 16926 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
FadeStep:
  LD A,(FadeStepIndex)
  CP $FF
  RET Z
  LD E,A
  LD D,$00
  LD HL,FadeSteps
  ADD HL,DE
  LD A,(HL)
  CP $FF
  JP NZ,FadeStepAttr
  LD A,$FF
  LD (FadeStepIndex),A
  RET
FadeStepAttr:
  LD (Temp1),A            ; the step's attribute change
  LD HL,$5800
  LD DE,TitleScreen
  LD B,$40
FadeCells:
  LD A,(Temp1)            ; each cell of the shadow
  CP $01
  JP Z,FadeIncrease
  OR A
  JP Z,FadeDecrease
  CP $02
  JP Z,FadeCopy
FadeNextCell:
  INC HL                  ; the next cell
  INC DE
  DJNZ FadeCells
  LD A,(FadeStepIndex)
  INC A
  LD (FadeStepIndex),A
  RET
FadeCopy:
  LD A,(DE)               ; the shadow to the screen
  CP (HL)
  JP Z,FadeNextCell
  LD A,(HL)
  INC A
  AND $07
  LD (HL),A
  JP FadeNextCell
FadeIncrease:
  LD A,(HL)               ; a brighter step
  INC A
  CP $07
  JP Z,FadeNextCell
  AND $07
  LD (HL),A
  JP FadeNextCell
FadeDecrease:
  LD A,(HL)               ; a darker step
  DEC A
  OR A
  JP Z,FadeNextCell
  AND $07
  LD (HL),A
  JP FadeNextCell

; The fade's 17 steps: 1 six times, 0 five times, 2 six times, then $FF (the
; end)
FadeSteps:
  DEFB $01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$FF
