; --------------------------------------------------------------------------------------------------------------------
; variables.asm: The game's variables
;
; All the state of a game sits in $A012-$A0C3, zero in the tape image: NewGame $9498 sets each before play. The
; temporaries $A093-$A09A are shared by many routines (a routine's input or scratch); the sprite parameters
; $A0AF-$A0B2 are DrawSprite's inputs.
; --------------------------------------------------------------------------------------------------------------------

; The variables $A012-$A0C3 (178 bytes, all zero on the tape)
Variables:
FireLatch:
  DEFB $00                ; 1 while fire is held (one shot a press for the slow
                          ; weapons)
Weapon:
  DEFB $00                ; the weapon in use: 0 gun, 1 double fire, 2 laser, 3
                          ; multiple (drones), 4 spray
PowerLevel:
  DEFB $00                ; the weapon's power, 1-6 (the power bar)
PowerBarPtr:
  DEFB $00,$00            ; the HUD address of the power bar's end
PassToggle:
  DEFB $00                ; flips every pass (the animations run every other
                          ; pass)
PowerCount:
  DEFB $00                ; power pods towards the next power level
RexCellPtr:
  DEFB $00,$00            ; Rex's place in the room grid (CellPointer $A503)
ObjectCellPtr:
  DEFB $00,$00            ; the current object's place in the grid (ObjectCell
                          ; $C72B)
RoomCellPtr:
  DEFB $00,$00,$00        ; DrawRoom's grid pointer
ObjectListPtr:
  DEFB $00,$00            ; the room's object list (RoomObjectLists)
HumanPicture:
  DEFB $00,$00,$00,$00,$00,$00 ; the human picture's offset by weapon
                               ; (KillHumanPicture $CE67)
BoxX:
  DEFB $00                ; PrintBoxed: the box's column
BoxY:
  DEFB $00                ; PrintBoxed: the box's line
BoxWidth:
  DEFB $00                ; PrintBoxed: the box's width
BoxHeight:
  DEFB $00                ; PrintBoxed: the box's height
SpawnLeft:
  DEFB $00                ; the room spawns from the left
SpawnRight:
  DEFB $00                ; the room spawns from the right
SpawnTop:
  DEFB $00                ; the room spawns from the top
SmartBombSteps:
  DEFB $00                ; the smart bomb's steps left (16)
SmartBombOn:
  DEFB $00                ; a smart bomb runs
SmartBombPtr:
  DEFB $00,$00            ; the next object to kill
SpriteMirror:
  DEFB $00                ; DrawSprite: bit 7 draws the picture mirrored
                          ; (MirrorTable $AD5D)
SpritePicture:
  DEFB $00,$00,$00,$00    ; DrawSprite: the picture
ObjectHitCount:
  DEFB $00                ; the hits an object took
KillFlashPtr:
  DEFB $00,$00            ; the HUD attribute address of the latest kill
ComboCount:
  DEFB $00                ; kills in a row
ComboTimer:
  DEFB $00,$00            ; passes left for the next kill to count in the row
Score:
  DEFB $00,$00            ; the score, in hundreds
RapidShotsOn:
  DEFB $00                ; the 100 RAPID SHOTS bonus runs
RapidShotsLeft:
  DEFB $00                ; its shots left
FadeStepIndex:
  DEFB $00                ; the screen flash's step (FadeStep $9A4C)
SpawnTimer:
  DEFB $00                ; passes to the next random spawn
SpawnPeriod:
  DEFB $00                ; the room's spawn period
ScriptSpawnStep:
  DEFB $00                ; the scripted spawn's step (ScriptSpawn $A9F4), 0
                          ; off
ScriptSpawnTimer:
  DEFB $00,$00            ; passes to the next scripted spawn
ScriptSpawnCount:
  DEFB $00                ; scripted spawns made
ShieldOn:
  DEFB $00,$00,$00        ; the shield is on
ShieldKeyLatch:
  DEFB $00                ; the down key is held (one toggle a press)
ShieldEnergy:
  DEFB $00                ; the shield's energy, 0-99
ShieldDrainRate:
  DEFB $00                ; passes for one unit of energy while the shield is
                          ; on
WeaponIcon:
  DEFB $00                ; the HUD weapon icon shown
HasDoubleFire:
  DEFB $00                ; the weapons held: double fire
HasLaser:
  DEFB $00                ; laser
HasMultiple:
  DEFB $00                ; multiple (drones)
HasSpray:
  DEFB $00                ; spray
EnemyShotKind:
  DEFB $00                ; the kind of the next enemy bullet
Dying:
  DEFB $00                ; Rex is dying
DeathTimer:
  DEFB $00                ; the death animation's passes left
DeathShardPtr:
  DEFB $00,$00            ; the shards' path pointer
RestartX:
  DEFB $00                ; the restart point: X
RestartY:
  DEFB $00                ; Y
RestartRoom:
  DEFB $00                ; room
RestartFacing:
  DEFB $00                ; facing
RexPresent:
  DEFB $00                ; 1 when Rex is fully there (he moves and fires), 0
                          ; while he materialises or after he vanished
SparkleCount:
  DEFB $00                ; the sparkle's cell mask step (18 to 0 in, 0 to 18
                          ; out)
SparkleOn:
  DEFB $00                ; the sparkle's dots run
SparkleMode:
  DEFB $00                ; the sparkle is shown
SparkleTimer:
  DEFB $00                ; the dots' passes left
Vanishing:
  DEFB $00                ; 1: the sparkle takes Rex out (a death), 0: it
                          ; brings him in
Lives:
  DEFB $00                ; lives left (4 at the start, up to 9)
SweepPos:
  DEFB $00                ; the HUD sweep's position
SweepCount:
  DEFB $00                ; sweeps made at this width
SweepDir:
  DEFB $00                ; the sweep's direction
SweepWidth:
  DEFB $00                ; the sweep's width (8 at the start; at 1 Rex dies)
FireDelay:
  DEFB $00                ; passes between shots
AnimCount1:
  DEFB $00                ; animation counters of the cells
AnimCount2:
  DEFB $00
AnimCount3:
  DEFB $00
Bombs:
  DEFB $00,$00            ; smart bombs left
WeaponRank:
  DEFB $00                ; the best weapon held
BonusRoll:
  DEFB $00,$00            ; the bonus roulette's position
Immune:
  DEFB $00                ; Rex cannot die (never set in play)
SpeedUp:
  DEFB $00                ; the SPEED UP bonus: passes left
SpeedUpPhase:
  DEFB $00,$00,$00
ExtraLifeCount:
  DEFB $00,$00,$00,$00    ; hundreds of points towards the next life
OnLift:
  DEFB $00                ; Rex stands on a ladder or lift
ShotSide:
  DEFB $00                ; FindShotSlot: 0 Rex's bullets, 1 the enemies'
AnimCount4:
  DEFB $00
BonusDelay:
  DEFB $00,$00
RollFrame:
  DEFB $00,$00            ; the menu roll call: the frame
RollPtr:
  DEFB $00,$00            ; the roll call's sprite record
RollTextPtr:
  DEFB $00,$00            ; the roll call's text
RollShow:
  DEFB $00                ; the roll call shows a sprite
RollTextNext:
  DEFB $00,$00            ; the next roll call text record
SpawnKind:
  DEFB $00                ; the kind the room spawns
HumansKilled:
  DEFB $00,$00            ; the people killed (the game over panel)
HiScore:
  DEFB $00,$00            ; the high score, in hundreds
RoomRight:
  DEFB $00                ; the room's exits (RoomExits $B133): right
RoomUp:
  DEFB $00                ; up
RoomDown:
  DEFB $00                ; down
RoomLeft:
  DEFB $00                ; left
RexSpeed:
  DEFB $00                ; Rex's sideways speed
ObjectCount:
  DEFB $00                ; the room's object records
Temp1:
  DEFB $00,$00            ; scratch and inputs
Temp2:
  DEFB $00,$00
Temp3:
  DEFB $00,$00
Temp4:
  DEFB $00,$00,$00,$00,$00,$00
BoxAttr:
  DEFB $00,$00            ; PrintBoxed: the box's attribute
RandomSeed:
  DEFB $00,$00            ; Random $A375's seed
RandomSeed2:
  DEFB $00                ; Random2 $A388's seed
DigitTemp:
  DEFB $00,$00            ; ToDigits $A402's work
Digits:
  DEFB $00,$00,$00,$00,$00 ; ToDigits $A402's five digits, units first
DefinePort:
  DEFB $00,$00            ; DEFINE: the port of the key read
DefineBit:
  DEFB $00                ; DEFINE: the BIT opcode's second byte ($47 + 8 x
                          ; bit)
ControlXor:
  DEFB $00                ; XORed with every port read: 0 keys, $FF Kempston
SpriteX:
  DEFB $00                ; DrawSprite: X in pixels
SpriteY:
  DEFB $00                ; Y in lines
SpriteWidth:
  DEFB $00                ; width in bytes
SpriteHeight:
  DEFB $00                ; height in lines
RexFrame:
  DEFB $00,$00,$00        ; Rex's walking frame
RexX:
  DEFB $00                ; Rex: X in pixels
RexY:
  DEFB $00                ; Y in lines
Room:
  DEFB $00                ; the room Rex is in
RoomColumn:
  DEFB $00,$00            ; DrawRoom's column
RexFacing:
  DEFB $00                ; 0 right, 1 left
FallSpeed:
  DEFB $00                ; Rex's fall speed
Jumping:
  DEFB $00,$00,$00        ; Rex is jumping
JumpPtr:
  DEFB $00,$00            ; the jump's step in JumpSteps $D0D8
AttractFlag:
  DEFB $00                ; the attract mode runs
AttractTimer:
  DEFB $00                ; passes left in the attract room
