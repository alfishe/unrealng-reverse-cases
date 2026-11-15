; --------------------------------------------------------------------------------------------------------------------
; rex.asm: Rex: the shield, his state and his picture
; --------------------------------------------------------------------------------------------------------------------

; The down key: switch the shield on or off (once a press, only with energy
; left)
;
; As REX 1's ShieldToggle $967F (src/game/rex.asm).
;
; Witness: L1 203 (c2, rzx-p2- x19).
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

; Rex's death animation while he is present and Dying $A1EE is set, else
; nothing
;
; As REX 1's RexState $969B (src/game/rex.asm).
;
; Witness: L1 10440 (c2, p2-room20, rzx-p2- x21).
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
; As REX 1's DrawRex $96A7 (src/game/rex.asm).
;
; Witness: L1 9413 (c2, p2-room20, rzx-p2- x21).
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
