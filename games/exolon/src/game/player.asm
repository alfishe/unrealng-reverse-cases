; --------------------------------------------------------------------------------------------------------------------
; player.asm: The cell map helpers, the player's walk, jump and fall, the shots
; --------------------------------------------------------------------------------------------------------------------

; HL = 32 * D + E: the offset of cell row D, column E in a 32-column map
;
; D the row (signed: SRA keeps a negative row negative), E the column 0-31.
; Output HL; A destroyed. The base of every map lookup: the block map $6100
; (BlockMapCell $80C1), the attribute shadow $5E00 (AttrShadowCell $80DA), the
; attributes $5800 (the blinking cells $9118), and the object handlers ($8F95
; AnimateTurrets, $91CF, $A23A, $A26B, $A2D5, $AB97, $ABCF), and the menu's
; $6EA9 and $6F90. c1: 1.26 million entries over the 104 recordings.
CellOffset:
  LD A,D
  SRA A
  SRA A
  SRA A
  LD H,A
  LD A,D
  AND $07
  RRCA
  RRCA
  RRCA
  ADD A,E
  LD L,A
  RET

; Code that never runs: HL = the open-cell map ($5B00) address of pixel
; position D, E
;
; The same as BlockMapCell $80C1 with the base $5B00: column = E / 4, row = D /
; 8, HL = $5B00 + 32 row + column; AF and DE kept. No instruction in the image
; calls or jumps to $80A8 and no recording ran it: a left-over. The sprite
; drawers $777F and $79DD compute the same address inline.
;
; Bytes F5 D5 7B E6 7C 0F 0F 5F 7A E6 F8 0F 0F 0F 57 CD 97 80 11 00 5B 19 D1 F1
; C9: PUSH AF, PUSH DE, LD A,E, AND $7C, RRCA, RRCA, LD E,A, LD A,D, AND $F8,
; RRCA x3, LD D,A, CALL CellOffset, LD DE,$5B00, ADD HL,DE, POP DE, POP AF,
; RET. A `c` entry is refused by mkgame ("the recordings say data"): c1's L1
; (the read build) also covers the load, whose depacker read these addresses at
; frame 1808, and those reads stop the static walk.
OpenMapCell:
  DEFB $F5,$D5,$7B,$E6,$7C,$0F,$0F,$5F
  DEFB $7A,$E6,$F8,$0F,$0F,$0F,$57,$CD
  DEFB $97,$80,$11,$00,$5B,$19,$D1,$F1
  DEFB $C9

; HL = the block map ($6100) address of pixel position D (Y), E (X)
;
; Input: D the Y in pixels, E the X in units of 2 pixels (0-$7F: 4 units a
; character column). Output: HL = $6100 + 32 (D / 8) + E / 4. AF and DE kept.
; The block map holds one byte per cell of the 22-row play area: 0 empty, 1
; solid scenery, 2 and up an object cell kind (BuildScreen $8494 and
; IndexObjectCells $8E86).
;
; Called by the four collision tests ($80F3, $8122, $814E, $8179), SpawnShot
; $8391, the shots' wall tests $9362 / $9382, $93A2, $93C2 and the print code
; $EB of $AF2B.
BlockMapCell:
  PUSH AF
  PUSH DE
  LD A,E
  AND $7C
  RRCA
  RRCA
  LD E,A
  LD A,D
  AND $F8
  RRCA
  RRCA
  RRCA
  LD D,A
  CALL CellOffset
  LD DE,CellTypes
  ADD HL,DE
  POP DE
  POP AF
  RET

; HL = the attribute shadow ($5E00) address of pixel position D, E
;
; As BlockMapCell with the base $5E00: the copy of the screen's attributes
; SaveAttributes $8E11 takes once a screen is built. Called by $7CA7 (the
; player's colour: cells whose shadow attribute is 0, black, are painted
; white).
AttrShadowCell:
  PUSH AF
  PUSH DE
  LD A,E
  AND $7C
  RRCA
  RRCA
  LD E,A
  LD A,D
  AND $F8
  RRCA
  RRCA
  RRCA
  LD D,A
  CALL CellOffset
  LD DE,AttrCopy
  ADD HL,DE
  POP DE
  POP AF
  RET

; Is the column right of the player (X, Y in E, D) blocked? NZ = blocked
;
; E the X, D the Y of the player's top left. X >= $74: never blocked (the
; player may walk off the right edge, PlayerFrame $8229 sees X = $80). X not on
; a cell boundary (X AND 3 not 0): not blocked (only a whole cell step meets a
; wall). Otherwise ORs the block map bytes of the column at X / 4 + 3 over the
; player's 4 rows, and a 5th when Y is not a multiple of 8.
;
; The player is 3 cells wide and 4 high (24 x 32 pixels). Output A (the OR of
; the bytes) and the Z flag; BC, DE, HL kept.
TestRight:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,E
  CP $74
  LD A,$00
  JR NC,TestRightDone
  LD A,E
  AND $03
  LD A,$00
  JR NZ,TestRightDone
  CALL BlockMapCell
  INC L
  INC L
  INC L
  LD BC,$0020
  LD A,(HL)
  ADD HL,BC
  OR (HL)
  ADD HL,BC
  OR (HL)
  ADD HL,BC
  OR (HL)
  LD E,A
  LD A,D
  AND $07
  LD A,E
  JR Z,TestRightDone
  ADD HL,BC
  OR (HL)
TestRightDone:
  OR A                    ; set Z from A
  POP HL
  POP DE
  POP BC
  RET

; Is the column left of the player blocked? NZ = blocked
;
; X = 0: blocked (A = 1): the left edge is a wall, there is no way back to the
; previous screen. X not on a cell boundary: not blocked. Otherwise the block
; map column at X / 4 - 1 over 4 (or 5) rows. Walking left is rare in the
; random play: 354 entries in c1 and c128 only.
TestLeft:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,E
  OR A
  LD A,$01
  JR Z,TestLeftDone
  LD A,E
  AND $03
  LD A,$00
  JR NZ,TestLeftDone
  CALL BlockMapCell
  DEC L
  LD BC,$0020
  LD A,(HL)
  ADD HL,BC
  OR (HL)
  ADD HL,BC
  OR (HL)
  ADD HL,BC
  OR (HL)
  LD E,A
  LD A,D
  AND $07
  LD A,E
  JR Z,TestLeftDone
  ADD HL,BC
  OR (HL)
TestLeftDone:
  OR A                    ; set Z from A
  POP HL
  POP DE
  POP BC
  RET

; Is there ground under the player's feet? NZ = ground
;
; Y not a multiple of 8: no ground (the player is between rows, still falling
; or jumping). Otherwise the block map row 4 below the top (+$80) at X / 4,
; then X / 4 + 1 and + 2, and + 3 when X is not on a cell boundary; at X >= $74
; only the first column (the part still on the screen). Also called by the
; death drop ($9CE3) and the respawn ($9D3F).
TestBelow:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,D
  AND $07
  LD A,$00
  JR NZ,TestBelowDone
  CALL BlockMapCell
  LD BC,$0080
  ADD HL,BC
  LD A,(HL)
  LD D,A
  LD A,E
  CP $74
  LD A,D
  JR NC,TestBelowDone
  INC L
  OR (HL)
  INC L
  OR (HL)
  LD D,A
  LD A,E
  AND $03
  LD A,D
  JR Z,TestBelowDone
  INC L
  OR (HL)
TestBelowDone:
  OR A                    ; set Z from A
  POP HL
  POP DE
  POP BC
  RET

; Is the row above the player's head blocked? NZ = blocked
;
; As TestBelow with the row above the top (-$20): a jump stops when its head
; meets scenery.
TestAbove:
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,D
  AND $07
  LD A,$00
  JR NZ,TestAboveDone
  CALL BlockMapCell
  LD BC,$FFE0
  ADD HL,BC
  LD A,(HL)
  LD D,A
  LD A,E
  CP $74
  LD A,D
  JR NC,TestAboveDone
  INC L
  OR (HL)
  INC L
  OR (HL)
  LD D,A
  LD A,E
  AND $03
  LD A,D
  JR Z,TestAboveDone
  INC L
  OR (HL)
TestAboveDone:
  OR A                    ; set Z from A
  POP HL
  POP DE
  POP BC
  RET

; One pass of the player's movement: fall, jump, crouch, walk; draws the player
;
; Called once a main loop pass (about 2 frames) from $75CC. SkipIfDying $9D78
; returns past it while the death timer runs. Clears ScreenChanged, takes DE =
; (PlayerX, PlayerY) and goes:
;
; FallFlag set: Fall ($8280). JumpStep set: the jump goes on ($81E3). No ground
; under the feet (TestBelow): Fall. Down held ($7B95): crouch: CrouchOffset =
; -6 and frame $0A. Up held ($7B94) on the ground: a jump, JumpStep from 22.
; Otherwise Walk ($8295 through $8280).
;
; A jump step: dy = JumpSteps[JumpStep], JumpStep - 1; down steps test
; TestBelow, up steps TestAbove; a blocked step ends the jump (JumpStep = 0,
; Fall). Then the jump keeps its horizontal move MoveDir: TestRight / TestLeft
; and X + MoveDir. Frame 3 while in the air.
;
; c1 checked: a jump at frame 17492 takes Y $70 -> $5E (18 pixels up) and back
; in 22 passes (JumpStep $15 down to 0 by frame 17542).
MovePlayer:
  CALL AbortIfDying
  XOR A
  LD (ScreenChanged),A
  LD DE,(PlayerX)
  LD A,(FallFlag)
  OR A
  JP NZ,Fall
  LD A,(JumpStep)
  OR A
  JR NZ,JumpStepNext
  CALL TestBelow
  JP Z,Fall
  LD A,$FA
  LD (CrouchOffset),A
  LD A,(ControlDuck)
  OR A
  LD A,$0A
  JP NZ,PlayerFrame
  XOR A
  LD (CrouchOffset),A
  LD A,(ControlJump)
  OR A
  JP Z,Fall
  CALL TestBelow
  JP Z,Fall
  LD A,$16
JumpStepNext:
  LD HL,PlayerFrameShown  ; A = JumpStep (22 at the take-off); JumpStep = A -
                          ; 1; dy = JumpSteps[A]
  LD C,A
  LD B,$00
  DEC A
  LD (JumpStep),A
  ADD HL,BC
  LD A,(HL)
  OR A
  JR Z,JumpMoveX
  CP $0A
  JR NC,JumpTestUp
  CALL TestBelow
  JR JumpTested
JumpTestUp:
  CALL TestAbove          ; a rising step (dy $FC-$FF): the head
JumpTested:
  JR Z,JumpMoveY          ; blocked: the jump ends, the player falls
  XOR A
  LD (JumpStep),A
  JP Fall
JumpMoveY:
  LD A,(HL)               ; Y + dy
  ADD A,D
  LD D,A
JumpMoveX:
  LD A,(MoveDir)          ; the jump keeps the walk direction of its take-off
  OR A
  JR Z,JumpFrame
  DEC A
  JR Z,JumpTestRight
  CALL TestLeft
  JR JumpTestedX
JumpTestRight:
  CALL TestRight
JumpTestedX:
  JR NZ,JumpFrame
  LD A,(MoveDir)
  ADD A,E
  LD E,A
JumpFrame:
  LD A,$03                ; frame 3: in the air

; Draw the player as frame A (+ the suit's frame base) at DE
;
; A the frame: 0-9 the walk, 3 in the air, 5 standing, 9 falling, $0A
; crouching, $0B the death; SuitFrames $9ED8 (0, or $0C in the exoskeleton,
; toggled by $9F2D) is added. Falls into DrawPlayer $8229.
;
; Called by MovePlayer and its branches, the teleport $98BA, the death $9CAF /
; $9CE3 and the exoskeleton booth $9F2D.
PlayerFrame:
  LD C,A
  LD A,(ExoSuit)
  ADD A,C

; Draw the player's frame A' at D, E; X = $80 is the right edge: the next
; screen
;
; A the frame with the suit base (PickUpPods $9942 enters here with the frame
; it saved). E = $80: NextScreen ($8253). Otherwise paints the player's cells
; white ($7C5F with C = $47: the cells whose attribute shadow is black), stores
; DE in PlayerX/PlayerY and, unless the frame and the position are both
; unchanged (PlayerFrameShown and the old X/Y), stores the frame and jumps to
; the sprite drawer $76DA (HL = $B181). A frame is 96 bytes (3 bytes by 32
; lines) at $EF80 + 96 A.
DrawPlayer:
  EX AF,AF'
  LD A,E
  CP $80
  LD A,D
  JR Z,NextScreen
  LD C,$47
  EX AF,AF'
  CALL ColourBigSprite
  LD BC,(PlayerX)
  LD (PlayerX),DE
  LD HL,(PlayerFrameShown)
  CP L
  JR NZ,DrawPlayerSprite
  LD H,B
  LD L,C
  AND A
  SBC HL,DE
  RET Z
DrawPlayerSprite:
  LD (PlayerFrameShown),A ; remember the frame, draw it through $76DA
  LD HL,WorkArea
  JP DrawBigSprite

; The player walked off the right edge: raise the screen number, ask for the
; new screen
;
; A the player's Y. PlayerY and RestartY = Y, ScreenChanged = Y (not 0:
; ScreenChangeCheck $8485 builds the next screen in this pass), ScreenNumber +
; 1, PlayerFrameShown = $FF (redraw). The round end $A8A5 calls it too, taking
; ScreenNumber from $FF to 0.
;
; x2 (WALKTHROUGH 6.0): NextScreen runs at frames 743, 1471, 1770, 2419 and
; 2944 (ScreenNumber 0 -> 5), each when the player left the screen on the
; right; the builds end about 9 frames later (751, 1481, 1771, 2421, 2951).
NextScreen:
  LD (PlayerY),A
  LD (RestartY),A
  LD (ScreenChanged),A
  LD A,(ScreenNumber)
  INC A
  LD (ScreenNumber),A
  LD A,$FF
  LD (PlayerFrameShown),A
  RET

; The frame number last drawn; $FF forces a redraw (also JumpSteps' unused
; entry 0)
;
; Written by DrawPlayer, set to $FF by the game start $7593, NextScreen, the
; turn ($82E8) and the pod pick-ups $9989 / $99DF. MovePlayer reads the jump
; table from $8269 + JumpStep with JumpStep 1-22, so this byte is never a jump
; step.
PlayerFrameShown:
  DEFB $00

; The jump's Y steps, read from step 22 down to 1: up 18 pixels, then down 18
;
; Read backwards (JumpStep 22 first): -4, -4, -2, -2, -2, -1, -1, -1, -1, 0, 0,
; 0, 0, +1, +1, +1, +1, +2, +2, +2, +4, +4. A value below $0A is a fall step
; (TestBelow), above an up step (TestAbove); 0 moves only sideways.
JumpSteps:
  DEFB $04,$04,$02,$02,$02,$01,$01,$01,$01,$00,$00
  DEFB $00,$00,$FF,$FF,$FF,$FF,$FE,$FE,$FE,$FC,$FC

; No jump: on the ground walk, in the air drop 4 pixels
;
; FallFlag = 0; TestBelow: ground -> Walk ($8295). No ground: Y + 4, FallFlag =
; 9 and frame 9 (the fall). While FallFlag is set MovePlayer comes straight
; here: no jump or crouch in the air, and no move sideways.
Fall:
  XOR A
  LD (FallFlag),A
  CALL TestBelow
  JR NZ,Walk
  INC D
  INC D
  INC D
  INC D
  LD A,$09
  LD (FallFlag),A
  JR PlayerFrame

; 9 while the player falls (the fall's frame number), 0 on the ground
FallFlag:
  DEFB $00

; The walk: the left / right inputs move the player 1 unit (2 pixels) a pass
;
; MoveDir = left XOR right ($7B92 / $7B93 as one word): neither (or both):
; frame 5, standing. Facing = 1, left: MoveDir = Facing = $FF. A change of
; direction first mirrors the 24 player frames ($7BAA flips MirrorState $7BDA)
; and draws the standing frame for that pass (TurnAround). Then TestLeft /
; TestRight: blocked: frame 5; free: X + MoveDir, WalkPhase steps 0-9 and is
; the frame.
Walk:
  LD HL,(ControlLeft)
  LD A,H
  XOR L
  LD (MoveDir),A
  LD A,$05
  JP Z,PlayerFrame
  LD A,$01
  LD (Facing),A
  BIT 0,L
  JR Z,WalkRight
  LD A,$FF
  LD (MoveDir),A
  LD (Facing),A
  LD A,(PlayerFlipped)
  OR A
  CALL Z,FlipPlayerFrames
  JR Z,TurnAround
  CALL TestLeft
  JR WalkTested
WalkRight:
  LD A,(PlayerFlipped)    ; facing right: mirror back first if the frames are
                          ; mirrored
  OR A
  CALL NZ,FlipPlayerFrames
  JR NZ,TurnAround
  CALL TestRight
WalkTested:
  LD A,$05                ; blocked: standing frame
  JP NZ,PlayerFrame
  LD A,(MoveDir)
  ADD A,E
  LD E,A
  LD A,(WalkPhase)
  CP $0A
  JR NZ,WalkFrame
  XOR A
WalkFrame:
  LD B,A                  ; the frame = WalkPhase (0-9); WalkPhase + 1
  INC A
  LD (WalkPhase),A
  LD A,B
  JP PlayerFrame
TurnAround:
  LD A,$FF                ; the frames were just mirrored: force the redraw,
                          ; standing frame
  LD (PlayerFrameShown),A
  LD A,$05
  JP PlayerFrame

; Not 0: the player left the screen on the right this pass (NextScreen stores
; Y)
;
; Cleared by MovePlayer each pass; ScreenChangeCheck $8485 builds the next
; screen when it is set.
ScreenChanged:
  DEFB $00

; The X the player restarts at after a death ($9D3B), 0 on each new screen, $10
; at the game start
RestartX:
  DEFB $00

; The Y the player restarts at ($70 at the start; the Y he entered the screen
; at)
;
; The respawn $9D3B drops the player from (RestartX, RestartY) to the ground
; (TestBelow, Y + 1). The round end $A8D6 sets both from its restart table.
RestartY:
  DEFB $00

; The player's X, 2 pixels a unit, 4 a column ($10 at the start; $80 = off the
; right edge)
PlayerX:
  DEFB $00

; The player's Y in pixels, the top of the 32-pixel sprite ($70 at the start:
; on the ground of screen 0)
PlayerY:
  DEFB $00

; The jump's step 22-1, 0 when not jumping; cleared by the death $9CC2
JumpStep:
  DEFB $00

; The horizontal move of this pass: 0, 1 right, $FF left; a jump keeps it
MoveDir:
  DEFB $01

; The walk frame 0-9, + 1 each step that moves
WalkPhase:
  DEFB $00

; 1 right, $FF left: the shots' direction; 1 after a death ($9D17)
Facing:
  DEFB $01

; $FA (-6) while crouching, else 0: shots leave lower ($13 below the top, not
; $0E)
;
; Read by SpawnShot $83A7 and the grenade throw $922D.
CrouchOffset:
  DEFB $00

; Draw or erase a shot at D (Y), E (X): 8 pixels of one line, XOR
;
; The pattern $BD (10111101) is shifted to the X's 2-pixel phase (HL = $00BD
; shifted left 2 ((NOT E AND 3) + 1) times) and XORed into the two screen bytes
; of the line ($B088: D the pixel line, E / 4 the column). When the attribute
; shadow of both cells is black the screen attributes of both become $47
; (bright white on black), so a shot shows on dark scenery.
;
; AF, BC, DE, HL kept. Called by SpawnShot, MoveShots and the shot tests $9B82,
; $9F71.
XorShot:
  PUSH AF
  PUSH BC
  PUSH HL
  PUSH DE
  LD L,$BD
  LD H,$00
  LD A,E
  CPL
  AND $03
  INC A
  LD B,A
XorShotShift:
  ADD HL,HL
  ADD HL,HL
  DJNZ XorShotShift
  PUSH HL
  CALL PixelAddress
  POP DE
  LD A,D
  XOR (HL)
  LD (HL),A
  INC L
  LD A,E
  XOR (HL)
  LD (HL),A
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  LD H,A
  LD BC,AttrCopy
  ADD HL,BC
  LD A,(HL)
  DEC L
  OR (HL)
  JR NZ,XorShotDone
  LD BC,OpenCells-CellTypes
  ADD HL,BC
  LD (HL),$47
  INC L
  LD (HL),$47
XorShotDone:
  POP DE
  POP HL
  POP BC
  POP AF
  RET

; The fire button: one shot a press (two in the exoskeleton), and the hold
; count for the grenade
;
; Once a pass from the main loop. SkipIfDying $9D78. X >= $76 (no room for a
; shot on the right): clears $7B98 (a byte past the inputs nobody reads) and
; returns. Fire ($7B96) up: FireHeld = 0. Fire held: FireHeld + 1, stopping at
; $FF (the grenade $9208 throws at 15; FireHeld stays 15 or more while fire is
; held, so ThrowGrenade throws again each time GrenadeTimer is 0). A new press:
; FireHeld = 1; with ammunition left: a beep ($7C26, B = $3C), Ammo - 1 (the
; ZXDB POKE 33646 at $836E), the AY effect $C177, the HUD ($8E4F) and
; SpawnShot. In the exoskeleton (SuitFrames $9ED8 not 0) a second shot 6 pixels
; lower.
FireControl:
  CALL AbortIfDying
  LD A,(PlayerX)
  CP $76
  JR C,FireTestButton
  XOR A
  LD (ControlSpare),A
  RET
FireTestButton:
  LD A,(ControlFire)
  OR A
  JR NZ,FireHeldCount
  LD (FireHeld),A
  RET
FireHeldCount:
  LD A,(FireHeld)         ; held: count the passes, no new shot
  OR A
  JR Z,FirePress
  INC A
  RET Z
  LD (FireHeld),A
  RET
FirePress:
  INC A                   ; a new press
  LD (FireHeld),A
  LD A,(Ammo)
  OR A
  RET Z
  LD B,$3C
  CALL BeeperNoise
  LD A,(Ammo)
  DEC A
  LD (Ammo),A
  CALL PlaySfxShot
  CALL PrintAmmo
  CALL SpawnShot
  LD A,(ExoSuit)
  OR A
  RET Z
  LD A,(PlayerY)
  PUSH AF
  ADD A,$06
  LD (PlayerY),A
  CALL SpawnShot
  POP AF
  LD (PlayerY),A
  RET

; Start a shot in the first free slot of ShotList at the player's gun
;
; No free slot (8 shots on the screen): nothing. The slot gets the direction
; Facing, Y = PlayerY + $0E (+ $13 crouching), X = PlayerX + $0C facing right
; or - 4 facing left. Outside X 4-$77 or with scenery in the cell or the next
; one (BlockMapCell): the slot is freed again. Otherwise drawn (XorShot).
SpawnShot:
  LD HL,ShotList
SpawnShotFind:
  BIT 7,(HL)
  RET NZ
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR NZ,SpawnShotFind
  DEC HL
  LD A,(Facing)
  LD (HL),A
  LD DE,(PlayerX)
  LD A,(CrouchOffset)
  OR A
  LD A,$0E
  JR Z,SpawnShotY
  LD A,$13
SpawnShotY:
  ADD A,D
  LD D,A
  DEC HL
  LD (HL),D
  DEC HL
  LD A,(Facing)
  INC A
  OR A
  LD A,$FC
  JR Z,SpawnShotX
  LD A,$0C
SpawnShotX:
  ADD A,E
  LD E,A
  CP $78
  JR NC,SpawnShotCancel
  CP $04
  JR C,SpawnShotCancel
  LD (HL),E
  PUSH HL
  CALL BlockMapCell
  LD A,(HL)
  INC L
  OR (HL)
  POP HL
  JP Z,XorShot
SpawnShotCancel:
  INC HL                  ; no room: free the slot
  INC HL
  LD (HL),$00
  RET

; The passes the fire button has been held, 0 when up, at most $FF; 15 throws a
; grenade ($9208)
FireHeld:
  DEFB $00

; The shots' step: the object hit tests, then every shot 1 unit along
;
; Called 5 times a main loop pass (so a shot moves 10 pixels a pass). First the
; hit tests of the objects that can be shot ($9B52, $9E37, $A5CA, $AC04, each
; reading ShotList). Then for each live shot: erase (XorShot), the wall test of
; the cell ahead ($9382 going left, $9362 going right, on the block map; a hit
; plays $C0E7 and goes to ShotHitWall); it dies at X $7C or 1, at PlayerX + $40
; (52 units from a right shot's start) or PlayerX - $34 (48 units from a left
; one's); otherwise X + direction and redrawn.
MoveShots:
  CALL ShotsHitBalls
  CALL GunShotsVsShots
  CALL AliensVsShots
  CALL ForceFieldVsShots
  LD HL,ShotList
MoveShotsNext:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,MoveShotsNext
  CALL XorShot
  LD B,A
  LD C,D
  LD A,D
  AND $F8
  LD D,A
  LD A,B
  INC A
  JR NZ,MoveShotRight
  CALL ProbeLeft
  CALL NZ,PlaySfxNoiseBurst
  JR NZ,ShotHitWall
  JR MoveShotRange
MoveShotRight:
  LD A,E
  CP $7C
  JR Z,ShotEnd
  CALL ProbeRight
  CALL NZ,PlaySfxNoiseBurst
  JR NZ,ShotHitWall
MoveShotRange:
  LD D,C                  ; the screen edges and the shot's range from the
                          ; player
  LD A,E
  CP $7C
  JR Z,ShotEnd
  CP $01
  JR Z,ShotEnd
  LD A,(PlayerX)
  ADD A,$40
  CP E
  JR Z,ShotEnd
  LD A,(PlayerX)
  SUB $34
  CP E
  JR Z,ShotEnd
  LD A,B
  ADD A,E
  LD E,A
  PUSH HL
  DEC HL
  DEC HL
  DEC HL
  LD (HL),E
  POP HL
  CALL XorShot
  JR MoveShotsNext
ShotHitWall:
  DEC HL                  ; free the slot, start the spark $981D at the shot,
                          ; 20 short noise bursts ($7C26, B = $14)
  LD (HL),$00
  INC HL
  LD D,C
  CALL AddPuff
  LD B,$14
ShotHitNoise:
  PUSH BC
  LD B,$14
  CALL BeeperNoise
  POP BC
  DJNZ ShotHitNoise
  JR MoveShotsNext
ShotEnd:
  DEC HL                  ; free the slot
  LD (HL),$00
  INC HL
  JR MoveShotsNext

; The player's shots: 8 slots of X, Y, direction (0 free, 1 right, $FF left)
;
; Written by SpawnShot, moved by MoveShots, cleared by ClearShots for each
; screen; read by the hit tests $9B82, $9F71, $AC0F.
ShotList:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $FF                ; $FF: the end mark

; Free all 8 shot slots (24 zero bytes, the end mark kept)
;
; Used by the routine at BuildScreen.
ClearShots:
  LD HL,ShotList
  LD DE,ShotList+$0001
  LD BC,$0017
  LD (HL),B
  LDIR
  RET
