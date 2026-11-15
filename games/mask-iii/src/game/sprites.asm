; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: The pictures: control icons, Matt, the enemies, digits, mask icons
;
; Every moving picture is a run of characters (8 bytes each) stored column by column: a frame w characters wide and h
; high is w x h x 8 bytes, character (column c, row r) at 8 x (c x h + r). An object's frame is its picture +$16/+$17
; + (animation & mask) x the frame size of its mode (SelectFrame $A349: modes 2-3 48 bytes, 4 32, 5 8, 6 one frame, 7
; 72). DrawObject $A56F makes the mask and the mirror image at run time, so no masks are stored. The PNGs are 1-bit,
; frames side by side (src/res/sprites/README.md).
; --------------------------------------------------------------------------------------------------------------------

  ORG $CC80

; Seven 2 x 2 pictures: the four control icons of the menu and three more
;
; DrawMenu $9D1A draws the icons of the four control methods; the lit one
; blinks in MenuInterrupt. Witness: c1 menu.
ControlIcons:
  INCBIN "res/sprites/control-icons.bin",$0000,224

; Matt running: 8 frames of 4 x 4 characters (32 x 32 pixels)
;
; SelectFrame picks frame ((x / 4) & 7), backwards when he faces left. Witness:
; every pass of play (c1).
MattRun:
  INCBIN "res/sprites/matt-run.bin",$0000,1024

; Matt jumping or falling (states 8, 10, 12), 4 x 4
MattJump:
  INCBIN "res/sprites/matt-jump.bin",$0000,128

; Matt crouching (state 4), 4 x 4
MattCrouch:
  INCBIN "res/sprites/matt-crouch.bin",$0000,128

; Enemy kinds 1 and 12 (templates $BE3B, $BE9B): 4 frames of 2 x 2
SpriteFaller:
  INCBIN "res/sprites/faller.bin",$0000,128

; Enemy kind 2 ($BE47): 4 frames of 3 x 2
SpriteFlyer:
  INCBIN "res/sprites/flyer.bin",$0000,192

; The score digits 0-9, 1 x 2 characters (16 bytes) each (DrawDigit $AE78)
Digits:
  INCBIN "res/sprites/digits.bin",$0000,160

; The explosion ($BEFB): 4 frames of 2 x 2
SpriteExplosion:
  INCBIN "res/sprites/explosion.bin",$0000,128

; The big explosion ($BF07): 4 frames of 3 x 2
SpriteExplosion2:
  INCBIN "res/sprites/explosion-big.bin",$0000,192

; The 11 mask icons (EMPTY and the ten masks), 2 x 2 each (DrawIcon $B024,
; PlacePickup $A9DA)
MaskIcons:
  INCBIN "res/sprites/mask-icons.bin",$0000,352

; Matt's shots: 6 frames of 2 x 2, one a mask kind 5-10 (FireMask sets the
; animation to kind - 5)
SpriteShots:
  INCBIN "res/sprites/shots.bin",$0000,192

; The turret (kind 4, $BE53): 4 frames of 3 x 2
SpriteTurret:
  INCBIN "res/sprites/turret.bin",$0000,192

; The turret's shot (kind 5, $BE5F): 8 frames of 1 x 1
SpriteTurretShot:
  INCBIN "res/sprites/turret-shot.bin",$0000,64

; The wave flyer (kind 6, $BE6B): 6 frames of 2 x 2
SpriteWave:
  INCBIN "res/sprites/wave.bin",$0000,192

; The walker (kind 7, $BE77): 4 frames of 2 x 2
SpriteWalker:
  INCBIN "res/sprites/walker.bin",$0000,128

; The chaser (kind 8, $BE83): one picture of 8 x 3
SpriteChaser:
  INCBIN "res/sprites/chaser.bin",$0000,192

; Kind 16's picture ($BE8F, spawned only by a POKE in work/stage2/rec/kind6): 4
; frames of 2 x 3
SpriteKind16:
  INCBIN "res/sprites/kind16.bin",$0000,192

; One 4 x 3 picture ($BECB)
SpriteBig:
  INCBIN "res/sprites/big.bin",$0000,96

; The guard (kind 13, $BEA7): one picture of 4 x 4
SpriteGuard:
  INCBIN "res/sprites/guard.bin",$0000,128

; Kind 18's picture ($BF13): 4 frames of 3 x 3
SpritePart1:
  INCBIN "res/sprites/part1.bin",$0000,288

; Kind 19's picture ($BF1F): 4 frames of 3 x 3
SpritePart2:
  INCBIN "res/sprites/part2.bin",$0000,288

; Three 2 x 2 pictures ($BED7, $BEE3, $BEEF)
SpriteSmall1:
  INCBIN "res/sprites/small.bin",$0000,96

; The boss (kind 14, $BEB3): one picture of 4 x 4
SpriteBoss:
  INCBIN "res/sprites/boss.bin",$0000,128

; The boss's shot ($BEBF): one picture of 2 x 2
SpriteBossShot:
  INCBIN "res/sprites/boss-shot.bin",$0000,32
