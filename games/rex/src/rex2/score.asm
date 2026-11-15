; --------------------------------------------------------------------------------------------------------------------
; score.asm: The kills, the score, the lives and the shield figure; the big squidgy thing's explosion and the ending
; --------------------------------------------------------------------------------------------------------------------

  ORG $9807

; Kill the object at IX: a kind 3 counts its ten hits (HitKind3); in the play
; area its points picture, BIO GROWTHS KILLED counts every kind but 0, the
; kind's score (KillScores), the explosion sound
;
; Changed from REX 1's KillObject $981F (src/game/score.asm).
;
; Witness: L1 688 (c2, p2-room20, rzx-p2- x20).
KillObject:
  LD HL,ObjectBufferOrigin
  LD (KillFlashPtr),HL
  LD HL,$0000
  LD (ComboTimer),HL
  LD A,(IX+$09)
  CP $83
  CALL Z,HitKind3
  LD A,(IX+$01)
  CP $B0
  RET NC
  CP $10
  RET C
KillPointsSign:
  LD HL,SpritePoints      ; the points sign: SpritePoints $84D8, kind $FF (no
                          ; collisions), at rest
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0D),$08
  LD (IX+$0F),$18
  LD (IX+$0E),$03
  LD A,(IX+$09)
  OR A
  CALL NZ,CountKill
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

; BioGrowthsKilled $A222 + 1 (every kill but kind 0)
;
; Witness: L1 247 (c2, p2-room20, rzx-p2- x20).
CountKill:
  LD HL,(GrowthsKilled)
  INC HL
  LD (GrowthsKilled),HL
  RET

; Kind 3 takes ten hits: each one steps its picture a frame on; before the
; tenth it leaves KillObject (POP BC: RET), the object lives
;
; Witness: L1 189 (rzx-p2- x9).
HitKind3:
  LD A,(IX+$11)
  INC A
  LD (IX+$11),A
  CP $0A
  RET Z
  LD L,(IX+$04)
  LD H,(IX+$05)
  LD DE,$0020
  ADD HL,DE
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$14),$02
  POP BC
  RET

; The score of each object kind, in hundreds: kind 0 2, 1 3, 2 5, 3 3, 4 6, 5
; 1, 6 1, 7 1, 8 6, 9 4, 10-13 1, 14 0, then 1s
KillScores:
  INCBIN "res/tables/rex2-kill-scores.bin",$0000,26

; Fade the HUD's kill flash one step (attribute row $5840, 30 cells), then mark
; the latest kill's two cells white
;
; As REX 1's KillFlashFade $9992 (src/game/score.asm).
;
; Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).
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

; Print Score $A1D7 in the HUD
;
; As REX 1's ShowScore $99AB (src/game/score.asm).
;
; Witness: L1 97 (c2, rzx-p2- x18).
ShowScore:
  LD HL,(Score)
  CALL ToDigits
  LD E,$10
  LD L,$00
  LD B,$05
  CALL PrintDigits
  RET

; Print Lives $A1FC in the HUD
;
; As REX 1's ShowLives $99BB (src/game/score.asm).
;
; Witness: L1 35 (c2, p2-room20, rzx-p2- x12).
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

; ShieldDrainRate $A1E7 - 1: a hit on the shield drains it faster
; (EnemyBulletsHitRex, ObjectHitsRex)
;
; As REX 1's ShieldDrainFast $99CE (src/game/score.asm).
;
; Witness: L1 24 (rzx-p2- x11).
ShieldDrainFast:
  LD A,$01
  LD (ShieldDrainRate),A

; With the shield on, count ShieldDrainRate down; at 0 one unit of ShieldEnergy
; $A1E6 goes; none left switches the shield off
;
; As REX 1's ShieldDrain $99D3 (src/game/score.asm).
;
; Witness: L1 754 (c2, rzx-p2- x15).
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

; Print ShieldEnergy $A1E6 in the HUD and colour it: red when low, green
; otherwise ($E513, $E514 in the attribute shadow)
;
; As REX 1's ShowShield $99FA (src/game/score.asm).
;
; Witness: L1 669 (c2, p2-room20, rzx-p2- x20).
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
  LD (TitleScreen+$0015),A
  LD (TitleScreen+$0014),A
  RET

; Score $A1D7 + HL; every 100 points ExtraLifeCount $A20F counts, at 100 an
; extra life (ExtraLife $D338)
;
; As REX 1's AddScore $9A27 (src/game/score.asm).
;
; Witness: L1 198 (c2, p2-room20, rzx-p2- x20).
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

; The HUD flash of a power pod (only TakePowerPod starts it): rows 0-1
; ($5800-$583F) stepped through FadeSteps $99D1 by FadeStepIndex $A1DB
;
; As REX 1's FadeStep $9A4C (src/game/score.asm).
;
; Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).
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
;
; As REX 1's FadeSteps $9AB3 (src/game/score.asm).
FadeSteps:
  DEFB $01,$01,$01,$01,$01,$01,$00,$00,$00,$00,$00,$02,$02,$02,$02,$02,$02,$FF

; One pass of the big squidgy thing's death: 16 pieces drawn and coloured at
; random places of its area; at timer $82 the area shrinks, at $64 the ending
;
; Runs while BossDying $A268 is set (MainLoop). Each of the 16 records of
; BossPieces $9CFD ([frame][X][Y]) is a piece of Rex's death picture ($8490 +
; 72 x frame) drawn by DrawPiece $9AE5 and coloured by ColourPiece $9B4D; after
; frame 8 the piece is cleared (CopyCells3) and, past timer $78 and 1 in 3 at
; random, comes back at a random place inside the area that BossAreaPtr $A26A
; points at, with a random explosion sound. BossTimer $A269 counts down from
; 200: at $82 ShrinkArea $9CBC, at $64 the ending text (EndingText $AB6E: WITH
; THE BIG SQUIDGY THING DESTROYED REX CAN GO HOME AND HAVE A NICE CUP OF TEA
; AND PUT HIS FEET UP) in a box, then the game stops in an endless JP to itself
; ($9ADE).
;
; Witness: L1 100 (rzx-p2-40000).
BossExplodes:
  LD IY,ExplosionAreas+$0006
  LD B,$10
BossPieceLoop:
  PUSH BC                 ; each of the 16 pieces
  LD A,(IY+$00)
  OR A
  JP Z,BossPieceAgain
  LD B,A
  LD DE,$0048
  CALL Multiply
  LD DE,SpriteRexDeath
  ADD HL,DE
  LD (SpritePicture),HL
  LD A,(IY+$01)
  LD (SpriteX),A
  LD A,(IY+$02)
  CP $A8
  JP NC,BossPieceAgain
  CP $18
  JP C,BossPieceAgain
  LD (SpriteY),A
  LD A,$03
  LD (SpriteWidth),A
  LD A,$18
  LD (SpriteHeight),A
  LD A,$FF
  LD (SpriteMirror),A
  XOR A
  CALL DrawPiece
  LD A,(IY+$01)
  LD (SpriteX),A
  LD A,(IY+$02)
  LD (SpriteY),A
  CALL ColourPiece
  LD A,(IY+$00)
  INC A
  LD (IY+$00),A
  CP $09
  JP NZ,BossPieceNext
  LD (IY+$00),$00
  LD HL,(Temp1)
  LD DE,(Temp2)
  CALL CopyCells3
BossPieceNext:
  LD DE,$0003             ; the next piece
  ADD IY,DE
  POP BC
  DJNZ BossPieceLoop
  LD A,(BossTimer)
  DEC A
  LD (BossTimer),A
  CP $82
  CALL Z,ShrinkArea
  CP $64
  JP Z,TheEnd
  RET
BossPieceAgain:
  LD A,(BossTimer)        ; a piece done: past timer $78 and at random it comes
                          ; back
  CP $78
  JP C,BossPieceNext
  CALL Random
  CP $96
  JP C,BossPieceNext
  LD HL,(BossAreaPtr)
  LD A,$68
  SUB (HL)
  LD E,A
  CALL Random2
  LD HL,(BossAreaPtr)
  INC HL
  AND (HL)
  SLA A
  SLA A
  SLA A
  ADD A,E
  AND $F8
  CP $F0
  JP NC,BossPieceNext
  LD (IY+$01),A
  LD (SpriteX),A
  LD A,$68
  LD HL,(BossAreaPtr)
  SUB (HL)
  LD E,A
  CALL Random2
  LD HL,(BossAreaPtr)
  INC HL
  AND (HL)
  SLA A
  SLA A
  SLA A
  ADD A,E
  AND $F8
  LD (IY+$02),A
  LD (SpriteY),A
  LD (IY+$00),$01
BossPieceSound:
  CALL Random             ; a random explosion sound (1-3)
  AND $03
  OR A
  JP Z,BossPieceSound
  LD (SfxExplosion),A
  LD DE,SfxExplosion
  CALL StartSfx
  JP BossPieceNext
TheEnd:
  LD IX,EndingText        ; the ending text
  LD B,$05
  CALL PrintBoxed
EndLoop:
  JP EndLoop              ; JP to itself: the game stops here

; Leftover: CALL WaitFire: POP BC after the endless loop; no instruction
; reaches it
EndLeftover:
  DEFB $CD,$D2,$97,$C1

; Copy a pre-shifted picture into the back buffer: HL the shift table (by
; SpriteX & 7), DE the picture, byte column SpriteX / 8, line SpriteY,
; SpriteWidth x SpriteHeight (written into $9B3D, $9B39); no mask
;
; Witness: L1 1064 (rzx-p2-40000).
DrawPiece:
  PUSH DE
  LD A,(SpriteX)
  AND $07
  LD E,A
  LD D,$00
  ADD HL,DE
  LD E,(HL)
  LD D,$00
  POP HL
  ADD HL,DE
  LD A,(SpriteX)
  SRL A
  SRL A
  SRL A
  LD (SpriteX),A
  PUSH HL
  LD A,(SpriteY)
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,AttrShadowPlay+$03A0
  ADD HL,DE
  LD A,(SpriteX)
  LD E,A
  LD D,$00
  ADD HL,DE
  EX DE,HL
  POP HL
  PUSH DE
  LD A,(SpriteWidth)
  LD (DrawPieceRow+$0003),A
  LD A,(SpriteHeight)
  LD (DrawPieceStore+$0006),A
  EX DE,HL
  LD A,(SpriteMirror)
  BIT 7,A
  JP Z,DrawPieceStore
  LD DE,(SpritePicture)
DrawPieceStore:
  LD (SpriteSource),DE    ; the picture kept in $A25E (never read)
  POP HL
  LD B,$00
DrawPieceRow:
  PUSH BC                 ; each line
  PUSH HL
  LD B,$00
DrawPieceByte:
  LD A,(DE)               ; each byte
  LD (HL),A
  INC DE
  INC HL
  DJNZ DrawPieceByte
  POP HL
  LD BC,$0020
  ADD HL,BC
  POP BC
  DJNZ DrawPieceRow
  RET

; A piece's 3 x 3 cells under SpriteX/SpriteY: a random ink of PieceInks $C2DF
; on the screen and in the attribute shadow
;
; Witness: L1 1064 (rzx-p2-40000).
ColourPiece:
  CALL BufferAddress
  LD DE,$0020
  ADD HL,DE
  LD (Temp1),HL
  LD DE,$5800
  AND A
  SBC HL,DE
  LD DE,TitleScreen
  ADD HL,DE
  EX DE,HL
  LD (Temp2),DE
  LD A,R
  AND $07
  LD E,A
  LD D,$00
  LD HL,PieceInks
  ADD HL,DE
  LD A,(HL)
  LD C,A
  LD HL,(Temp1)
  LD DE,(Temp2)
  CALL InkCells3
  RET

; Three rows of InkRow3
;
; Witness: L1 1064 (rzx-p2-40000).
InkCells3:
  CALL InkRow3
  CALL InkRow3
  CALL InkRow3
  RET

; Three cells at HL take ink C (paper kept: AND $38), HL and DE one row on
;
; Witness: L1 3192 (rzx-p2-40000).
InkRow3:
  LD A,(HL)
  AND $38
  OR C
  LD (HL),A
  INC HL
  LD A,(HL)
  AND $38
  OR C
  LD (HL),A
  INC HL
  LD A,(HL)
  AND $38
  OR C
  LD (HL),A
  PUSH DE
  LD DE,$001E
  ADD HL,DE
  POP DE
  PUSH HL
  LD HL,$001E
  ADD HL,DE
  EX DE,HL
  POP HL
  RET
