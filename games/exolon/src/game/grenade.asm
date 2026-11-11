; --------------------------------------------------------------------------------------------------------------------
; grenade.asm: The grenade: the throw, the arc, the walls
; --------------------------------------------------------------------------------------------------------------------

; Throw a grenade when fire has been held for 15 passes
;
; Main loop, every pass (c1: 3260). AbortIfDying first. No throw when the
; player's X ($82F5) is $76 or more (the right edge), when no grenades are left
; ($8E66), when the fire-hold count $83DC is below 15 (it counts the passes the
; fire button is held, $8338), or when a grenade is in flight (GrenadeTimer not
; 0).
;
; The throw: the timer $20, the position (player X + 4, player Y; 6 lower when
; crouching, ThrowFromCrouch), the direction from the facing $82FA ($FF left, 1
; right), the frame 1 facing left, 0 facing right; GrenadeStart draws it, takes
; one grenade (the DEC A at $9250 is ZXDB's grenades POKE 37456), plays $C1BE
; and prints the count ($8E5B).
;
; Thrown in c128 (3), x2 (14), w030 (8) and 78 warp clones.
ThrowGrenade:
  CALL AbortIfDying
  LD A,(PlayerX)          ; X at the right edge: no throw
  CP $76
  RET NC
  LD A,(Grenades)         ; no grenades left
  OR A
  RET Z
  LD A,(FireHeld)         ; fire held for fewer than 15 passes
  CP $0F
  RET C
  LD A,(GrenadeTimer)     ; one in flight already
  OR A
  RET NZ
  LD A,$20                ; the flight's 32-step timer
  LD (GrenadeTimer),A
  LD HL,(PlayerX)         ; L = X + 4, H = Y
  LD A,L
  ADD A,$04
  LD L,A
  LD A,(CrouchOffset)     ; $82FB: crouching (set to $FA by the movement $81C4)
  OR A
  JR Z,GrenadeStart

; A grenade thrown while crouching starts 6 pixels lower
;
; Y + 6 when $82FB is set. Data in the mechanical cut: no recording of c1 / x /
; w threw from a crouch; exC's t1 did (the crouch + fire hold at frame 410:
; $9221-$9245 ran once).
ThrowFromCrouch:
  LD A,H
  ADD A,$06
  LD H,A

; Store the new grenade, draw it, count it off
;
; In: HL = the start (L = X, H = Y). Stores GrenadeX / GrenadeY, the direction
; (the facing $82FA) and the frame (1 when the direction is $FF, else 0), draws
; it with DrawSmallSprite, takes one grenade from $8E66, plays $C1BE and jumps
; to $8E5B to print the count.
GrenadeStart:
  LD (GrenadeX),HL
  LD A,(Facing)
  LD (GrenadeDir),A
  EX DE,HL                ; DE = the position for DrawSmallSprite
  INC A
  LD A,$01
  JR Z,GrenadeFrameSet
  XOR A
GrenadeFrameSet:
  LD (GrenadeFrame),A     ; the frame: 1 left, 0 right
  CALL DrawSmallSprite
  LD A,(Grenades)
  DEC A                   ; the grenades POKE (ZXDB 37456): the DEC A
  LD (Grenades),A
  CALL PlaySfxGrenade     ; the throw sound
  JP PrintGrenades

; The grenade in flight: the flight timer $20 down to 1 (0: none)
;
; The timer indexes GrenadeArc. It stops at 1 (the fall goes on until the
; grenade lands). The main loop runs MoveGrenade once more twice a pass while
; the timer is below $13 ($7609, $7620): three steps a pass for the late
; flight.
GrenadeTimer:
  DEFB $00
GrenadeX:
  DEFB $00                ; X, in 2-pixel units
GrenadeY:
  DEFB $00                ; Y, in pixels
GrenadeDir:
  DEFB $00                ; the direction: $FF left, 1 right (the player's
                          ; facing at the throw)
GrenadeFrame:
  DEFB $00                ; the small-sprite frame: 0 facing right, 1 facing
                          ; left

; One step of the grenade: erase, move along the arc, test the walls and the
; floor, draw, a trail
;
; Main loop, up to three times a pass. Nothing when GrenadeTimer is 0. HL =
; GrenadeArc - 1 + timer (the vertical step), the timer counted down to 1. The
; grenade is erased (DrawSmallSprite XORs), and the flight ends (GrenadeEnd) at
; X $7C or 0 (the screen's edges), at a wall on its side (ProbeLeft /
; ProbeRight), when the step is not -1 and ProbeBelow finds a solid cell under
; it, or at Y $A8 and more (the play area's bottom).
;
; Else X moves one unit (2 pixels) in GrenadeDir, Y by the arc step; the
; grenade is drawn and its cells painted bright white ($47, $7C77). While the
; timer is $13 or more a puff (AddPuff) is left 4 units behind it: the smoke
; trail of the climb.
;
; c128: 199 steps; x2: 396; the end in c128 3 times.
MoveGrenade:
  LD A,(GrenadeTimer)
  OR A
  RET Z
  LD C,A
  LD B,$00
  LD HL,GrenadeArc-1
  ADD HL,BC
  DEC A
  JR Z,GrenadeErase
  LD (GrenadeTimer),A
GrenadeErase:
  LD DE,(GrenadeX)        ; the old position, erased
  LD A,(GrenadeFrame)
  CALL DrawSmallSprite
  LD A,E                  ; at the right edge
  CP $7C
  JR Z,GrenadeEnd
  OR A                    ; at the left edge
  JR Z,GrenadeEnd
  LD A,(GrenadeDir)       ; B = the direction; $FF: moving left
  LD B,A
  INC A
  JR NZ,GrenadeRightWall

; A grenade moving left: the wall test on its left
;
; ProbeLeft at the grenade's position: a wall ends the flight, else the step
; goes on at GrenadeAdvance. Data in the cut: no recording threw a grenade to
; the left (the player faces right in every script; exC's t1 tried left + fire
; but the hold was too short for a throw).
GrenadeLeftWall:
  CALL ProbeLeft
  JR NZ,GrenadeEnd
  JR GrenadeAdvance

; A grenade moving right: the wall test on its right, then the step
;
; ProbeRight; a wall ends the flight (GrenadeEnd). Then the rest of
; MoveGrenade's step: X + direction, the arc, the floor, the draw, the trail.
GrenadeRightWall:
  CALL ProbeRight
  JR NZ,GrenadeEnd
; This entry point is used by the routine at GrenadeLeftWall.
GrenadeAdvance:
  LD A,B                  ; X + direction
  ADD A,E
  LD E,A
  LD (GrenadeX),A
  LD A,(GrenadeY)         ; D = Y, then the arc step
  LD D,A
  LD A,(HL)               ; a step of -1 (rising) skips the floor test
  CP $FF
  JR NC,GrenadeFall
  CALL ProbeBelow
  JR NZ,GrenadeEnd
GrenadeFall:
  LD A,(HL)               ; Y + the step
  ADD A,D
  LD D,A
  CP $A8                  ; below the play area: the end
  JR NC,GrenadeEnd
  LD (GrenadeY),A
  LD A,(GrenadeFrame)     ; the frame, painted bright white, drawn
  LD C,$47
  CALL ColourCell
  CALL DrawSmallSprite
  LD A,(GrenadeDir)       ; the trail's X: 4 units behind
  INC A
  LD A,$04
  JR Z,GrenadeTrailX
  NEG
GrenadeTrailX:
  ADD A,E
  LD E,A
  LD A,(GrenadeTimer)     ; a puff while the timer is $13 or more
  CP $13
  JP NC,AddPuff
  RET
; This entry point is used by the routines at MoveGrenade and GrenadeLeftWall.
GrenadeEnd:
  XOR A                   ; the flight over: the blast on the scenery
  LD (GrenadeTimer),A
  JP GrenadeBlast

; The grenade's vertical step for the timer 1-32 (index 1 first)
;
; MoveGrenade reads byte timer - 1 (HL = $92DA + timer; $92DA is the last byte
; of the JP at $92D8). From the throw (timer 32) on: -4, -4, -2, -2, -2, -1,
; -1, -1, -1 (a climb of 18 pixels in 9 steps), 22 steps level, then +1 a step
; at timer 1 for the rest of the flight (the fall, three steps a pass).
GrenadeArc:
  DEFB $01,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
  DEFB $FF,$FF,$FF,$FF    ; timer 24-27: -1
  DEFB $FE,$FE,$FE,$FC,$FC ; timer 28-30: -2; 31-32: -4
