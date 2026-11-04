; Nether Earth, Argus Press Software 1987: the game image as the loader N1 leaves it ($4000-$FCE8, entry $A600).
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
RandomSeed     EQU $FD00  ; the shift register of Random, seeded $39,$30,$39,$30 by Start
PrintAddr      EQU $FD04  ; the screen address of the next printed character
MapView        EQU $FD06  ; the map byte at the view's left column: $DD00 + ViewX
SavedSP        EQU $FD08  ; SP kept while ClearViewBuffer pushes and while the menu music runs
ViewX          EQU $FD0A  ; the map column at the view's left edge, follows ShipX
Input          EQU $FD0C  ; the controls read this game turn: bit 0 right, 1 left, 2 down, 3 up, 4 fire, 5 save, 6 abort, 7 pause
ShipY          EQU $FD0D  ; the ship's row, 1-15
ShipX          EQU $FD0E  ; the ship's column, $000E-$01F5
Altitude       EQU $FD10  ; the ship's height: fire raises it by 2 to $30, released it sinks by 1 to what is under it
ShipDrawPos    EQU $FD11  ; the ship's view position while its drawing is deferred (column, row); 0 = not deferred
PrintAttr      EQU $FD13  ; the attribute of printed characters
PrintAttrAddr  EQU $FD14  ; the attribute address of the next printed character
PrintHeight    EQU $FD16  ; big characters: each font row printed this many times (PrintInline code 4, high nibble)
PrintWidth     EQU $FD17  ; big characters: the width in bytes, 0 normal (PrintInline code 4, low nibble)
RadarPhase     EQU $FD1A  ; toggled each frame: 0 shows the player's radar layer, 1 the enemy's
RadarLeft      EQU $FD1B  ; the radar window's left edge in units of 8 map columns, 0-$30
RadarColumn    EQU $FD1C  ; RadarLeft x 8: the radar window's first map column
RadarBlink     EQU $FD1E  ; bit 0: the ship's radar blip is drawn
MenuCursor     EQU $FD1F  ; the construction menu: the column (0 EXIT MENU, 1 START ROBOT, 2 the parts), the part row; the robot menu: its last item
MenuParts      EQU $FD21  ; the parts chosen, bit = part row; the new robot's +$07
Resources      EQU $FD22  ; general, electronics, nuclear, phasers, missiles, cannon, chassis
MenuResources  EQU $FD29  ; the copy the construction menu spends; back to Resources on START ROBOT
ClimbTurns     EQU $FD30  ; game turns the ship still climbs by itself: 3 at a new game, 5 after a menu
PrintColumn    EQU $FD31  ; the print position's column
PrintRow       EQU $FD32  ; the print position's row
TitleColourPhase EQU $FD33  ; 0-15, TitleColourCycle's frame counter
TurnFrames     EQU $FD34  ; frames counted by PlayInterrupt; a game turn waits for 10
Clock          EQU $FD35  ; minutes (by 5), hours, days (16 bits)
PanelBusy      EQU $FD39  ; 1 while a robot menu owns the right panel
PlayerBuildings EQU $FD3A  ; the player's buildings by type: warbases, then factories in the Resources order
PlayerRobotCount EQU $FD41  ; live robots in slots 0-23
EnemyBuildings EQU $FD42  ; the enemy's buildings, the same order; no warbase left = the game is won
EnemyRobotCount EQU $FD49  ; live robots in slots 24-47
EnemyResources EQU $FD4A  ; the enemy's resources, the order of Resources
Side           EQU $FD51  ; the side being processed: 0 the player's, 1 the enemy's
RadarDirty     EQU $FD52  ; 1: rebuild the radar layers from the map at the next ship mark
SoundFx        EQU $FD53  ; 1-$7F a falling tone (fire), $FC a miss, $FA a hit, $C8 a robot destroyed; PlayInterrupt counts it on
BassReturnPos  EQU $FD54  ; menu music: the bass track's return point
LeadReturnPos  EQU $FD56  ; menu music: the lead track's return point
Warbases       EQU $FD70  ; 4 capture points of 5 bytes: X (2), Y, owner (bit 6 player, 5 enemy, 7 destroyed) + type, turns a robot has stood at the door (144 captures)
Factories      EQU $FD84  ; 24 capture points of 5 bytes, the same shape
Handler        EQU $FDFE  ; the interrupt handler: the IM 2 vector's JP at $FDFD jumps here
Buildings      EQU $FF01  ; 56 records of 3 bytes: the map cell address, the type (0 a warbase pad, 1-6 factories, 7 the player's flag, 8 the enemy's)
  ORG $5B00
  INCLUDE "viewbuffer.asm"
  INCLUDE "font.asm"
  INCLUDE "sprites.asm"
  INCLUDE "start.asm"
  INCLUDE "robotmenu.asm"
  INCLUDE "gameturn.asm"
  INCLUDE "ship.asm"
  INCLUDE "world.asm"
  INCLUDE "enemy.asm"
  INCLUDE "bases.asm"
  INCLUDE "level.asm"
  INCLUDE "mainmenu.asm"
  INCLUDE "music.asm"
  INCLUDE "construction.asm"
  INCLUDE "view.asm"
  INCLUDE "screen.asm"
  INCLUDE "controls.asm"
  INCLUDE "print.asm"
  INCLUDE "interrupts.asm"
  INCLUDE "tables.asm"
  INCLUDE "worldstate.asm"
  INCLUDE "map.asm"

  SAVEBIN "game.bin",$5B00,$A1E9
