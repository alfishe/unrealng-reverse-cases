; --------------------------------------------------------------------------------------------------------------------
; rex.asm: Rex: the shield, his state and his picture
; --------------------------------------------------------------------------------------------------------------------

; The shield key (input bit 2): unless the sparkle shows or the latch is held,
; ShieldFlip
;
; Changed from REX 1's ShieldToggle $967F (src/game/rex.asm).
;
; Witness: L1 23 (d1, demo-cycle).
ShieldToggle:
  LD A,(SparkleMode)
  OR A
  RET NZ
  LD A,(ShieldKeyLatch)
  OR A
  RET NZ

; Switch the shield (with energy left): ShieldKeyLatch set, ShieldOn flipped;
; ShieldToggle falls in, the tutor's panels jump here (rooms 0 and 4)
;
; Witness: L1 31 (d1, demo-cycle).
ShieldFlip:
  LD A,(ShieldEnergy)
  OR A
  RET Z
  LD A,$01
  LD (ShieldKeyLatch),A
  LD A,(ShieldOn)
  CPL
  LD (ShieldOn),A
  RET

; Rex's death animation while he is present and Dying $5EDE is set, else
; nothing
;
; As REX 1's RexState $969B (src/game/rex.asm).
;
; Witness: L1 6753 (d1, demo-cycle).
RexState:
  LD A,(RexPresent)
SpritePowerBar:
  OR A                    ; the power bar cells (PowerBar $C278)
  RET Z
  LD A,(Dying)
  OR A
  JP NZ,DeathAnimation

; Draw Rex: his picture by the frame lists RexFramesJump $AF5E (jumping or
; falling, off a lift) or RexFramesWalk $AF6E; with the shield on, its hum, its
; drain and the bubble (RexFrames $AF1E, 4 x 24)
;
; Changed from REX 1's DrawRex $96A7 (src/game/rex.asm).
;
; Witness: L1 6627 (d1, demo-cycle).
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
  LD HL,RexFramesJump
  LD A,(OnLift)
  OR A
  JP NZ,l_8D3A
  LD A,(Jumping)
  OR A
  JP NZ,DrawRexFacing
  LD A,(FallSpeed)
  OR A
  JP NZ,DrawRexFacing
l_8D3A:
  LD HL,RexFramesWalk
DrawRexFacing:
  LD A,(RexFacing)            ; the mirror flag by facing
DrawRexShieldOn:
  CALL DrawSprite         ; draw him, then the shield
  LD A,(ShieldOn)
  OR A
  RET Z
  LD A,(Channels+$0008)
  CP $FF
  JP NZ,DrawRexShield
  CALL Random2
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
  LD A,(RexY)            ; the bubble, 4 x 24 from four lines above Rex
  SUB $04
  LD (SpriteY),A
  LD A,$04
  LD (SpriteWidth),A
  LD A,$18
  LD (SpriteHeight),A
  XOR A
  LD (SpriteMirror),A
  LD HL,ShieldFrames
  LD A,(RexFacing)
  CALL DrawSprite
  RET
