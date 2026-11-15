; --------------------------------------------------------------------------------------------------------------------
; variables.asm: The game's variables
; --------------------------------------------------------------------------------------------------------------------

; 1 while fire is held (one shot a press for the slow weapons)
;
; As REX 1's FireLatch $A012 (src/game/variables.asm).
FireLatch:
  DEFB $00
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
  DEFB $00,$00            ; Rex's place in the room grid (CellPointer $A6AB)
ObjectCellPtr:
  DEFB $00,$00            ; the current object's place in the grid (ObjectCell
                          ; $C794)
RoomCellPtr:
  DEFB $00,$00,$00        ; DrawRoom's grid pointer
ObjectListPtr:
  DEFB $00,$00            ; the room's object list (RoomObjectLists)
HumanPicture:
  DEFB $00,$00,$00,$00,$00,$00 ; part 1's human picture offset; part 2 never
                               ; uses it
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
  DEFB $00                ; DrawSprite: bit 7 a fixed frame, SpritePicture, the
                          ; frame list ignored (mirroring, through MirrorTable
                          ; $AE52, is A not 0 at the call)
SpritePicture:
  DEFB $00,$00,$00,$00    ; DrawSprite: the picture
ObjectHitCount:
  DEFB $00                ; the hits an object took
KillFlashPtr:
  DEFB $00,$00            ; the combo row cell lit by the latest hit ($5843 + 3
                          ; a hit; at rest $E9FF)
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
  DEFB $00                ; the power pod's HUD flash step, $FF at rest
                          ; (FadeStep $996A)
SpawnTimer:
  DEFB $00                ; passes to the next random spawn
SpawnPeriod:
  DEFB $00                ; the room's spawn period
ScriptSpawnStep:
  DEFB $00                ; the scripted spawn's step 0 off (the scripted spawn
                          ; never starts in part 2)
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
  DEFB $00                ; the gun held (always 1): BestWeapon reads it as
                          ; entry 0 before HasDoubleFire .. HasSpray
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
  DEFB $00                ; the sweep's width (12 after ResetSweep; Rex dies
                          ; when it would drop to 0)
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
GrowthsKilled:
  DEFB $00,$00            ; BIO GROWTHS KILLED (every kill but kind 0; the game
                          ; over panel), started from the code's score
HiScore:
  DEFB $00,$00            ; the high score, in hundreds
RoomRight:
  DEFB $00                ; the room's exits (RoomExits $B1A7): right
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
  DEFB $00,$00,$00,$00
CodeKey:
  DEFB $00,$00            ; the key ReadCode read last (a digit, "-" delete or
                          ; "+" done)
BoxAttr:
  DEFB $00,$00            ; PrintBoxed: the box's attribute
RandomSeed:
  DEFB $00,$00            ; Random $A51D's seed
RandomSeed2:
  DEFB $00                ; Random2 $A530's seed
DigitTemp:
  DEFB $00,$00            ; ToDigits $A5AA's work
Digits:
  DEFB $00,$00,$00,$00,$00 ; ToDigits $A5AA's five digits, units first
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
  DEFB $00,$00            ; the jump's step in JumpSteps $CE68
AttractFlag:
  DEFB $00                ; the attract mode runs
AttractTimer:
  DEFB $00                ; passes left in the attract room
CellFound:
  DEFB $00                ; the type of the cell InList found last (IsSolid,
                          ; IsPassable)
SpriteSource:
  DEFB $00,$00            ; the picture DrawSprite or DrawPiece drew from;
                          ; written, never read
CodeLength:
  DEFB $00                ; digits typed into the code (ReadCode)
CodeSum:
  DEFB $00,$00            ; the code's checksum digit (EnterCode)
CodeScore:
  DEFB $00,$00            ; the score the code carries (NewGame; also the start
                          ; of BIO GROWTHS KILLED)
CodeShield:
  DEFB $00                ; the shield charge the code carries
CodeBombs:
  DEFB $00                ; the smart bombs the code carries
CodeLives:
  DEFB $00                ; the lives the code carries
BossDying:
  DEFB $00                ; the big squidgy thing is exploding (BossHit,
                          ; BossExplodes)
BossTimer:
  DEFB $00                ; the passes of the boss's explosion; at $64 the
                          ; ending text
BossAreaPtr:
  DEFB $00,$00            ; the explosion's area (ExplosionAreas $9CF7)
