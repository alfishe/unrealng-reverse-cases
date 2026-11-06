; Advanced Nether Earth, Eternity Industry 1998: the game image in play, banks 5, 2 and 0 as the CPU sees them.
; The game block unpacks to $6731-$D7D7 (tools/build_game.sh adds its last 5 bytes, the first of Shots); entry GameEntry $A5DA.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
ViewBuffer     EQU $5B00  ; the view's back buffer, $5B00-$677F (160 lines of 20 bytes); its last 79 bytes are ViewBufferTail in the image
LAST_K         EQU $5C08  ; the ROM's last key: ENTER for the disk module
FLAGS          EQU $5C3B  ; the ROM's flags: $CC for the disk module's key reading
FLAGS2         EQU $5C6A  ; the ROM's flags 2: bit 3 CAPS LOCK, cleared for the disk module
Shots          EQU $D7D3  ; the shots in flight: 5 records of 9 bytes; the block's last 5 bytes (zero) are its first
RadarOwn       EQU $D800  ; the radar picture with the player's robots: 16 lines of 16 bytes
RadarEnemy     EQU $D900  ; the radar picture with the enemy's robots, 16 lines of 16 bytes; SaveShots overlays its tail
SaveShots      EQU $D92B  ; the save staging: the 5 Shots records (over RadarEnemy's tail)
SaveBuildings  EQU $D958  ; the save staging: the 56 Buildings records
Robots         EQU $DA00  ; the player's robots: slots 0-23, 16 bytes a record
EnemyRobots    EQU $DB80  ; the enemy's robots: slots 24-47, the same records
Map            EQU $DD00  ; the map: 16 rows of 512 cells, cell = $DD00 + $200 x Y + X
RandomSeed     EQU $FD00  ; the shift register of Random, seeded $39,$30,$39,$30 by Restart
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
MenuCursor     EQU $FD1F  ; the construction menu: the column (0 ВЫХОД, 1 ВЫПУСК, 2 the parts), the part row; the robot menu: its last item
MenuParts      EQU $FD21  ; the parts chosen, bit = part row; the new robot's +$07
Resources      EQU $FD22  ; general, electronics, nuclear, phasers, missiles, cannon, chassis
MenuResources  EQU $FD29  ; the copy the construction menu spends; back to Resources on ВЫПУСК (start the robot)
ClimbTurns     EQU $FD30  ; game turns the ship still climbs by itself: 3 at a new game, 5 after a menu
PrintColumn    EQU $FD31  ; the print position's column
PrintRow       EQU $FD32  ; the print position's row
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
Warbases       EQU $FD70  ; 4 capture points of 5 bytes: X (2), Y, owner (bit 6 player, 5 enemy, 7 destroyed) + type, turns a robot has stood at the door (144 captures)
Factories      EQU $FD84  ; 24 capture points of 5 bytes, the same shape
Buildings      EQU $FF01  ; 56 records of 3 bytes: the map cell address, the type (0 a warbase pad, 1-6 factories, 7 the player's flag, 8 the enemy's)

; Addresses in other RAM banks (@bank)
PlayerInit     EQU $C000  ; bank 1: the SoundTrack player's start: the tune from its beginning
PlayerFrame    EQU $C005  ; bank 1: the player's frame entry: one 50 Hz step of the tune
MusicStart     EQU $D8E1  ; bank 1: bank 1's start-up code, run once by GameEntry
DeadEnd        EQU $D2EF  ; bank 3: the lost game's ending
MenuPictureCode EQU $E73B  ; bank 3: the menu picture's depacker: the picture onto the screen
DiskLoad       EQU $4000  ; bank 4: IX for the disk module: load a saved game
DiskSave       EQU $4033  ; bank 4: IX for the disk module: save the game
DiskModule     EQU $C000  ; bank 4: the disk module's entry; IX selects the job
FinalCut       EQU $6060  ; bank 6: where GameWon copies the Final Cut block and runs it (over the game)
FinalCutBlock  EQU $C000  ; bank 6: the won game's ending, a block GameWon copies to FinalCut
  ORG $6731
  INCLUDE "viewtail.asm"  ; the tail of the view buffer the game block loads over
  INCLUDE "music.asm"  ; the AY music in the interrupts, the game's bank paging, the menu picture
  INCLUDE "im2.asm"  ; the IM 2 table and jump, and the disk save's bridge between them
  INCLUDE "sprites.asm"  ; The 89 sprite blocks: the ship, the map objects, the robot parts, the buildings' signs, the shots
  INCLUDE "disk.asm"  ; the disk load bridge and the stack the bank calls run on
  INCLUDE "start.asm"  ; the game's entry, the restart, the new game set-up and the play loop
  INCLUDE "robotmenu.asm"  ; the robot menu and its submenus: orders, distance, targets, combat, direct control
  INCLUDE "gameturn.asm"  ; the game turn: the clock, daily production, capture and the turn pacing
  INCLUDE "endings.asm"  ; the end of a game: Dead End or Final Cut, the AY silenced
  INCLUDE "ship.asm"  ; the player's ship: its move, altitude, view follow, radar window and map mark
  INCLUDE "world.asm"  ; the world turn: each robot's step (sight, fire, steering by order, movement) and each shot's flight
  INCLUDE "enemy.asm"  ; the computer's side: the enemy commander, its robot builds and orders, and the nuclear blast
  INCLUDE "bases.asm"  ; the bases: counts, owners, buildings, destruction and the new game's map
  INCLUDE "level.asm"  ; The level: the scenery and base lists, the shape table and the 11 shapes BuildMap turns into the map
  INCLUDE "mainmenu.asm"  ; the main menu, the disk load and save hooks, the redefine-keys screen, the dead tape code
  INCLUDE "font.asm"  ; the game's Cyrillic font and the free bytes round it
  INCLUDE "construction.asm"  ; the construction menu, robot placement on the map, the beeper tone
  INCLUDE "view.asm"  ; the isometric view: the buffer, the painter's walk over the map, the masked sprites
  INCLUDE "screen.asm"  ; the play screen: its frame and colours, the status panel, screen-line steps, Random
  INCLUDE "controls.asm"  ; the controls: KeyTable and the joystick into Input, the pause
  INCLUDE "print.asm"  ; text: the inline print routine, the font characters, big characters, the numbers
  INCLUDE "interrupts.asm"  ; the frame interrupt of play: the radar, the shot sounds, the frame count
  INCLUDE "tables.asm"  ; Lookup tables of the view and the robots: view edges, part sprites, sprite pointers, heights

  SAVEBIN "game.bin",$6731,$70A2
