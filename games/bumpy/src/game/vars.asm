; --------------------------------------------------------------------------------------------------------------------
; vars.asm: The game's variables: the ball, the cells of the level, the player, the animations
;
; The variables from $A9FD to $AB5E. Every value is written by the game before it is read; the bytes on the tape are
; zeros (the CPC original's state) except where said. One player's record (score, water, keys, hammers, level, lives)
; is a copy at $AAFB of Player1Record $AB09 or Player2Record $AB10.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A9FD

; 1 while the take-off picture of the cell the ball leaves is on the screen
TakeoffDrawn:
  DEFB $00

; The width in bytes of the next picture a blitter draws (the rows go in B)
SpriteWidth:
  DEFB $00

; The step of the ball's current move: 0-15 (bounce, left, right), 0-7 (up,
; down)
BallStep:
  DEFB $00

; The ball's state: 0 bounce in place, 1 left, 2 right, 3 up, 4 down, 5
; stopped, 6 burst, 7 fall out, 8 level end
BallState:
  DEFB $00

; The ball's current picture (in BallPictures $67E8)
BallSprite:
  DEFW $0000

; The ball's CPC screen address
BallScrAddr:
  DEFW $0000

; The address the ball was drawn at last, to erase it
BallOldAddr:
  DEFW $0000

; A cell's index as a word: the build's and the brick test's current cell
CellIndex:
  DEFW $0000

; two bytes never used
Unused1:
  DEFS $02

; Scratch: a cell's byte during the build, a brick's layers in the brick test
CellByte:
  DEFB $00

; Counts frames to the flames' next frame (every fourth)
FireTick:
  DEFB $00

; Counts frames to wall 4's next frame (every fourth)
WallTick:
  DEFB $00

; Counts frames to the exit's next frame
ExitTick:
  DEFB $00

; The exit's frame, 1-4
ExitFrame:
  DEFB $00

; The exit's screen address
ExitAnimAddr:
  DEFW $0000

; 1 once the exit is open
ExitOpen:
  DEFB $00

; 1 when the up key or fire armed the spring: the next landing goes up (state
; 3)
SpringArmed:
  DEFB $00

; A crumbling platform waits for the ball to leave
CrumblePending:
  DEFB $00

; A crumbling platform's animation runs
CrumbleActive:
  DEFB $00

; The flames' frame, 1-3
FireFrame:
  DEFB $00

; Wall 4's frame, 1-4
WallFrame:
  DEFB $00

; The screen address of the lock being opened
LockAnimAddr:
  DEFW $0000

; The lock animation's step table ($C592, $C596 or $C59A)
LockAnimSteps:
  DEFW $0000

; The lock animation's step
LockStep:
  DEFB $00

; A lock animation runs
LockActive:
  DEFB $00

; two bytes never used
Unused2:
  DEFS $02

; The current level's record, copied from LevelRecords: 36 cells, then
; BallCell, PrizesLeft, ExitCell
;
; BuildLevel $CF2E clears $AA20-$AAFA (219 bytes) and copies the 75-byte record
; here, so the record's byte 36 becomes BallCell $AA44, byte 37 PrizesLeft
; $AA45, byte 38 ExitCell $AA46 and bytes 39-74 CellObjects $AA47.
LevelRecord:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The ball's cell, 0-35 (the record's start cell at a life's start)
BallCell:
  DEFB $00

; The prizes still to take; at 0 OpenExit $BCB9 opens the exit
PrizesLeft:
  DEFB $00

; The cell the exit opens in
ExitCell:
  DEFB $00

; The object of each cell, 0 none, 1-40 (taken ones become 0)
CellObjects:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The platform type of each cell (the record's low nibbles; changed as
; platforms crumble, burn out or break)
CellPlatforms:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The wall type to the right of each cell (the record's high nibbles; lowered
; as keys open locks)
CellWalls:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 1 for a cell whose platform burns (types 8 and 9)
CellBurning:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The brick layers still standing in each cell (8 for a whole brick, type 10)
BrickLayers:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The current player's score
Score:
  DEFW $0000

; Water drops: one puts out a fire the ball lands on
Water:
  DEFB $00

; Keys: one opens a lock one step
Keys:
  DEFB $00

; Hammers: one breaks a whole brick's first layer
Hammers:
  DEFB $00

; The level, 0-99 (shown as is)
Level:
  DEFB $00

; Spare lives
Lives:
  DEFB $00

; Read with the record copies, never written: the byte after the player's
; record
AfterLives:
  DEFB $00

; never used
Unused3:
  DEFS $01

; The level's timer: 1000 at a life's start, one off a frame; the rest goes
; into the score at the level end
Timer:
  DEFW $0000

; Water at the level's start (given back when a life is lost)
WaterAtStart:
  DEFB $00

; Keys at the level's start
KeysAtStart:
  DEFB $00

; Hammers at the level's start
HammersAtStart:
  DEFB $00

; Player 1's record: score (word), water, keys, hammers, level, lives ($FA
; lives: the player is out)
Player1Record:
  DEFB $00,$00,$00,$00,$00,$00,$00

; Player 2's record, the same layout
Player2Record:
  DEFB $00,$00,$00,$00,$00,$00,$00

; Set by the bottle (an extra life): the CPC border flash, a RET on the
; Spectrum
BorderFlash:
  DEFB $00

; The column the next HUD figure prints at
HudColumn:
  DEFB $00

; never used
Unused4:
  DEFS $01

; The level's start cell (the record's byte 36)
StartCell:
  DEFB $00

; The cell of the crumbling platform
CrumbleCell:
  DEFB $00

; The platform type of the ball's cell (CellPlatforms[BallCell], set by $BB32)
CellPlatform:
  DEFB $00

; The object in the ball's cell
CellObject:
  DEFB $00

; The wall of the ball's cell (written by the unrun ReadWallCell $BB4A)
CellWall:
  DEFB $00

; never used
Unused5:
  DEFS $01

; The type the crumbling platform becomes
CrumbleNewType:
  DEFB $00

; The crumble animation's step
CrumbleStep:
  DEFB $00

; The crumble animation's step table
CrumbleSteps:
  DEFW $0000

; The crumbling platform's screen address
CrumbleAddr:
  DEFW $0000

; The fire put-out animation's step
FireOutStep:
  DEFB $00

; Its step table ($C55E, $C56E or $C57E)
FireOutSteps:
  DEFW $0000

; Its screen address
FireOutAddr:
  DEFW $0000

; A fire put-out animation runs
FireOutActive:
  DEFB $00

; never used
Unused6:
  DEFS $01

; The CPC screen address of the current cell (CellAddresses $E131)
CellScrAddr:
  DEFW $0000

; The CPC screen address of the current wall (WallAddresses $E179)
WallScrAddr:
  DEFW $0000

; The screen address of the brick layer being knocked off
BrickLayerAddr:
  DEFW $0000

; A brick animation runs
BrickActive:
  DEFB $00

; The brick animation's step
BrickAnimStep:
  DEFB $00

; The spring record of the ball's platform (24 bytes from SpringPics $C5D6): 4
; offsets, 4 pictures, 4 widths, 4 row counts
SpringRecord:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The take-off record (18 bytes from TakeoffPics $C64E): 3 offsets, 3 pictures,
; 3 widths, 3 row counts
TakeoffRecord:
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

; 29 zero bytes never used
Unused7:
  DEFS $1D
