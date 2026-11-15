; --------------------------------------------------------------------------------------------------------------------
; rex.asm: Rex: the shield, his state and his picture
;
; Rex is a sprite at RexX $A0B6 / RexY $A0B7 (pixels; the play area starts at line 24) facing RexFacing $A0BB. The
; down key toggles the shield (ShieldOn $A049), which drains ShieldEnergy $A04D while on and stops shots and enemies
; (EnemyBulletsHitRex $D1B9, ObjectHitsRex $D215 test it). RexState runs the death animation while Dying $A055 is set;
; DrawRex picks his picture: walking, jumping or shielded.
; --------------------------------------------------------------------------------------------------------------------

; The down key: switch the shield on or off (once a press, only with energy
; left)
;
; Called by MainPass when ReadDown $A4DB sees the key. ShieldKeyLatch $A04C
; keeps it to one toggle a press; the shield goes on only while ShieldEnergy
; $A04D is not 0 and Rex is not materialising ($A060).
;
; Witness: L1 293 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room30,
; rzx-p1- x32).
ShieldToggle:
  LD A,(SparkleMode)
  OR A
  RET NZ
  LD A,(ShieldKeyLatch)
  OR A
  RET NZ
  LD A,(ShieldEnergy)
  OR A
  RET Z
  LD A,$01
  LD (ShieldKeyLatch),A
  LD A,(ShieldOn)
  CPL
  LD (ShieldOn),A
  RET

; Rex's death animation while he is present and Dying $A055 is set, else
; nothing
;
; Returns while Rex is not present (RexPresent $A05D 0: he is materialising);
; then, if Dying $A055, JP DeathAnimation $9AC5. Called every pass.
;
; Witness: L1 16841 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
RexState:
  LD A,(RexPresent)
  OR A
  RET Z
  LD A,(Dying)
  OR A
  JP NZ,DeathAnimation

; Draw Rex: his picture (walking or jumping); with the shield on, its hum, its
; drain and the bubble
;
; Sets SpriteX $A0AF, SpriteY $A0B0, the size 3 x 16 ($A0B1, $A0B2) and the
; mirror flag by RexFacing; the picture through ShiftFrames $AE5D:
; SpriteRexJump $8F62 while jumping or falling (and not on a lift, OnLift
; $A07A), else SpriteRex $80F2. DrawSprite $B258. With ShieldOn $A049: the hum
; SfxShield (its period SfxShieldTone = $04B0 + Random & $1F) started when
; channel 2 is free, ShieldDrain $99D3 with L = 1, then the bubble SpriteShield
; $88F2, 4 x 21, through ShiftFrames2 $AE65, 4 pixels left of Rex (8 right of
; that facing left) and 2 lines up.
;
; Witness: L1 15408 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
DrawRex:
  LD A,(RexX)
  LD (SpriteX),A
  LD A,(RexY)
  LD (SpriteY),A
  LD A,$03
  LD (SpriteWidth),A
  LD A,$10
  LD (SpriteHeight),A
  XOR A
  LD (SpriteMirror),A
  LD HL,ShiftFrames
  LD DE,SpriteRexJump
  LD A,(OnLift)
  OR A
  JP NZ,DrawRexWalk
  LD A,(Jumping)
  OR A
  JP NZ,DrawRexFacing
  LD A,(FallSpeed)
  OR A
  JP NZ,DrawRexFacing
DrawRexWalk:
  LD HL,ShiftFrames       ; on a lift or on the ground: the walking picture
  LD DE,SpriteRex
DrawRexFacing:
  LD A,(RexFacing)        ; the mirror flag by facing
  CALL DrawSprite
  LD A,(ShieldOn)
  OR A
  RET Z
  LD A,(Channels+$0008)
  CP $FF
  JP NZ,DrawRexShield
  CALL Random
  AND $1F
  LD E,A
  LD D,$00
  LD HL,$04B0
  ADD HL,DE
  LD (SfxShieldTone),HL
  LD DE,SfxShield
  CALL StartSfx
DrawRexShield:
  LD L,$01                ; the shield on: drain it, the bubble's X
  CALL ShieldDrain
  LD A,(RexX)
  SUB $04
  LD (SpriteX),A
  LD A,(RexFacing)
  OR A
  JP Z,DrawShield
  LD A,(SpriteX)
  ADD A,$08
  LD (SpriteX),A
DrawShield:
  LD A,(RexY)             ; the bubble, 4 x 21 from two lines above Rex
  SUB $02
  LD (SpriteY),A
  LD A,$04
  LD (SpriteWidth),A
  LD A,$15
  LD (SpriteHeight),A
  XOR A
  LD (SpriteMirror),A
  LD HL,ShiftFrames2
  LD DE,SpriteShield
  LD A,(RexFacing)
  CALL DrawSprite
  RET
