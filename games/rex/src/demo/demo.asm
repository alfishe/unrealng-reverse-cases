; Rex, Martech Games 1988 (The Light): DEMO, the Tutor Mode, $61A8-$FFF9 as the ROM loader leaves it
; (tools/parts.py: side 2 blocks 4 and 6 of orig/Rex.tzx.zip); entry $8A84.
; Written by kit/mkgame.py from src/demo/demo.ann and the recordings; edit demo.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Temp1          EQU $5B60  ; scratch and inputs
Temp2          EQU $5B62
Temp3          EQU $5B64
Temp4          EQU $5B66
BoxAttr        EQU $5B6C  ; PrintBoxed: the box's attribute
RandomSeed     EQU $5B6E  ; Random $C6CE's seed
RandomSeed2    EQU $5B70  ; Random2 $9E6A's seed
DigitTemp      EQU $5B71  ; ToDigits $9EE8's work
Digits         EQU $5B73  ; ToDigits $9EE8's five digits, units first
ControlXor     EQU $5B7B  ; XORed with every port read: 0 keys, $FF Kempston
SpriteX        EQU $5B7C  ; DrawSprite: X in pixels
SpriteY        EQU $5B7D  ; Y in lines
SpriteWidth    EQU $5B7E  ; width in bytes
SpriteHeight   EQU $5B7F  ; height in lines
RexFrame       EQU $5B80  ; Rex's walking frame
RexX           EQU $5B83  ; Rex: X in pixels
RexY           EQU $5B84  ; Y in lines
Room           EQU $5B85  ; the room Rex is in
RoomColumn     EQU $5B86  ; DrawRoom's column
RexFacing      EQU $5B88  ; 0 right, 1 left
FallSpeed      EQU $5B89  ; Rex's fall speed
Jumping        EQU $5B8A  ; Rex is jumping
JumpPtr        EQU $5B8D  ; the jump's step in JumpSteps $D3C8
RexSpeed       EQU $5B8F  ; Rex's sideways speed
ObjectCount    EQU $5B90  ; the room's object records (its list's first byte & $1F)
RoomRight      EQU $5B91  ; the room's exits (RoomExits $B033): right
RoomUp         EQU $5B92  ; up
RoomDown       EQU $5B93  ; down
RoomLeft       EQU $5B94  ; left
FireLatch      EQU $5E9B  ; 1 while fire is held (one shot a press for the slow weapons)
Weapon         EQU $5E9C  ; the weapon in use: 0 gun, 1 double fire, 2 laser, 3 multiple (drones), 4 spray
PowerLevel     EQU $5E9D  ; the weapon's power, 1-6 (the power bar)
PowerBarPtr    EQU $5E9E  ; the HUD address of the power bar's end
PassToggle     EQU $5EA0  ; flips every pass (the animations run every other pass)
PowerCount     EQU $5EA1  ; power pods towards the next power level
RexCellPtr     EQU $5EA2  ; Rex's place in the room grid (CellPointer $9FD7)
ObjectCellPtr  EQU $5EA4  ; the current object's place in the grid (ObjectCell $CCF8)
RoomCellPtr    EQU $5EA6  ; DrawRoom's grid pointer
ObjectListPtr  EQU $5EA9  ; the room's object list (RoomObjectLists)
BoxX           EQU $5EB1  ; PrintBoxed: the box's column
BoxY           EQU $5EB2  ; PrintBoxed: the box's line
BoxWidth       EQU $5EB3  ; PrintBoxed: the box's width
BoxHeight      EQU $5EB4  ; PrintBoxed: the box's height
SpawnLeft      EQU $5EB5  ; the room spawns from the left
SpawnRight     EQU $5EB6  ; the room spawns from the right
SpawnTop       EQU $5EB7  ; the room spawns from the top
SmartBombSteps EQU $5EB8  ; the smart bomb's steps left (16)
SmartBombOn    EQU $5EB9  ; a smart bomb runs
SmartBombPtr   EQU $5EBA  ; the next object to kill
SpriteMirror   EQU $5EBC  ; DrawSprite: bit 7 a fixed frame, SpritePicture, the frame list ignored (mirroring, through MirrorTable $AE0E, is A not 0 at the call)
SpritePicture  EQU $5EBD  ; DrawSprite: the picture
ArrowPathPtr   EQU $5EBF  ; the tutor arrow's place in ArrowPath (TutorArrow)
ArrowMoving    EQU $5EC1  ; the arrow moves along its path (0: held at the start)
KillFlashPtr   EQU $5EC2  ; the combo row cell lit by the latest hit (REX 1's; DEMO keeps no combo)
ComboCount     EQU $5EC4  ; kills in a row
ComboTimer     EQU $5EC5  ; passes left for the next kill to count in the row
Score          EQU $5EC7  ; the score, in hundreds
RapidShotsOn   EQU $5EC9  ; the 100 RAPID SHOTS bonus runs
RapidShotsLeft EQU $5ECA  ; its shots left
FadeStepIndex  EQU $5ECB  ; the power pod's HUD flash step, $FF at rest (FadeStep $9A4C)
SpawnTimer     EQU $5ECC  ; passes to the next random spawn
SpawnPeriod    EQU $5ECD  ; the room's spawn period
ScriptSpawnStep EQU $5ECE  ; the scripted spawn's step (ScriptSpawn $A9F4), 0 off
ScriptSpawnTimer EQU $5ECF  ; passes to the next scripted spawn
ScriptSpawnCount EQU $5ED1  ; scripted spawns made
ShieldOn       EQU $5ED2  ; the shield is on
ShieldKeyLatch EQU $5ED5  ; the down key is held (one toggle a press)
ShieldEnergy   EQU $5ED6  ; the shield's energy, 0-99
ShieldDrainRate EQU $5ED7  ; passes for one unit of energy while the shield is on
WeaponIcon     EQU $5ED8  ; the gun held (always 1): BestWeapon reads it as entry 0 before HasDoubleFire .. HasSpray
HasDoubleFire  EQU $5ED9  ; the weapons held: double fire
HasLaser       EQU $5EDA  ; laser
HasMultiple    EQU $5EDB  ; multiple (drones)
HasSpray       EQU $5EDC  ; spray
EnemyShotKind  EQU $5EDD  ; the kind of the next enemy bullet
Dying          EQU $5EDE  ; Rex is dying
DeathTimer     EQU $5EDF  ; the death animation's passes left
DeathShardPtr  EQU $5EE0  ; the shards' path pointer
RestartX       EQU $5EE2  ; the restart point: X
RestartY       EQU $5EE3  ; Y
RestartRoom    EQU $5EE4  ; room
RestartFacing  EQU $5EE5  ; facing
RexPresent     EQU $5EE6  ; 1 when Rex is fully there (he moves and fires), 0 while he materialises or after he vanished
SparkleCount   EQU $5EE7  ; the sparkle's cell mask step (18 to 0 in, 0 to 18 out)
SparkleOn      EQU $5EE8  ; the sparkle's dots run
SparkleMode    EQU $5EE9  ; the sparkle is shown
SparkleTimer   EQU $5EEA  ; the dots' passes left
Vanishing      EQU $5EEB  ; 1: the sparkle takes Rex out (a death), 0: it brings him in
Lives          EQU $5EEC  ; lives left (4 at the start, up to 9)
SweepPos       EQU $5EED  ; the HUD sweep's position
SweepCount     EQU $5EEE  ; sweeps made at this width
SweepDir       EQU $5EEF  ; the sweep's direction
SweepWidth     EQU $5EF0  ; the sweep's width (12 after ResetSweep; Rex dies when it would drop to 0)
FireDelay      EQU $5EF1  ; passes between shots
AnimCount1     EQU $5EF2  ; animation counters of the cells
AnimCount2     EQU $5EF3
AnimCount3     EQU $5EF4
Bombs          EQU $5EF5  ; smart bombs left
ObjectTable    EQU $5EF6  ; the room's object records, 23 bytes each (UpdateObjects, SmartBombMark)
WeaponRank     EQU $6067  ; the best weapon held
BonusRoll      EQU $6068  ; the bonus roulette's position
Immune         EQU $606A  ; Rex cannot die (never set)
SpeedUp        EQU $606B  ; the SPEED UP bonus: passes left
SpeedUpPhase   EQU $606C
ExtraLifeCount EQU $606F  ; hundreds of points towards the next life
HeatColour     EQU $6071  ; the colour of the HUD cell $5817 (ShowHeat): 7 at a death, + 1 every 100 passes (HeatStep)
HeatCount      EQU $6072  ; passes to the next HeatStep
OnLift         EQU $6074  ; Rex stands on a ladder or lift
ShotSide       EQU $6075  ; FindShotSlot: 0 Rex's bullets, 1 the enemies'
AnimCount4     EQU $6076  ; the animated cells' counter (AnimateCells)
BonusDelay     EQU $6077  ; the bonus roulette's step count, smaller each step
TutorInput     EQU $6079  ; the input the script holds now, bits low = pressed: 0 fire, 1 up, 2 down, 3 right, 4 left
TutorUnused    EQU $607F  ; set to 0 by TutorReset, never read
TutorScriptPtr EQU $6080  ; the [input][count] pair in play
TutorCount     EQU $6082  ; passes left on this pair
TutorFrame     EQU $6083  ; passes since the room's tutor began (the panels' clock)
TutorRoomPtr   EQU $6085  ; the next room in TutorRooms $A2A2
TutorDone      EQU $6087  ; room 2's tutor shown

; Names that cannot be labels (@alias)
ShadowOffset   EQU $E4FF-$5800  ; the distance from a screen attribute to its cell in the attribute shadow $E4FF (PowerBar adds it); not an address in the sprites
  ORG $61A8
  INCLUDE "graphics.asm"  ; The development link, the graphics and the level data: the font, the characters, the blocks, the room maps and the sprites
  INCLUDE "entry.asm"  ; The entry, a new demo game
  INCLUDE "rex.asm"  ; Rex: the shield, his state and his picture
  INCLUDE "bomb.asm"  ; The smart bomb; the kill and its points
  INCLUDE "score.asm"  ; The score, the lives, the shield figure, the HUD heat cell
  INCLUDE "death.asm"  ; Rex's death, the life lost, the restart points, the sparkle
  INCLUDE "cells.asm"  ; The cells under Rex: ladders, restart markers, the conveyor, the shield recharger, the weapon stations
  INCLUDE "tutor.asm"  ; The Tutor Mode: each room's set-up, the panels at their frames, the input scripts, the room list
  INCLUDE "hud.asm"  ; The HUD, the text printer, the numbers
  INCLUDE "controls.asm"  ; The controls: the tutor's input script in place of the keys, the pause
  INCLUDE "grid.asm"  ; The room grid, the animated cells, the drones
  INCLUDE "weapons.asm"  ; The weapons: firing, the bullets, the power level
  INCLUDE "tables.asm"  ; The tables: the room list, the beam path, the scripted spawns, the shards, the texts, the screen lines, the mirror and frame tables, the rooms' objects and exits, the tutor's input scripts
  INCLUDE "render.asm"  ; The renderer: the back buffer, the sprites, the animated cells
  INCLUDE "objects.asm"  ; The objects: the enemies, the pods, their moves, their shots, the explosions
  INCLUDE "rooms.asm"  ; The rooms: drawing a room, the exits, the objects made, the spawners
  INCLUDE "panels.asm"  ; The panels: the framed box, the attribute shadow, the weapon panels
  INCLUDE "rexmove.asm"  ; Rex's moves: walk, jump, fall, the edges of the room
  INCLUDE "collisions.asm"  ; The collisions: shots and objects against Rex, Rex's shots against objects, the pods
  INCLUDE "sound.asm"  ; The sound: the AY effects

  SAVEBIN "demo.bin",$61A8,$9E52
