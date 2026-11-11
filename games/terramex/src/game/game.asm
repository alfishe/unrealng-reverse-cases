; Terramex, Grandslam Entertainments 1987 (Teque: Shaun Hollingworth, Pete Harrap, Ben Daglish): TZX block 5, the
; game $7200-$FFFF, as the loader's LD-BYTES leaves it over block 4 (tools/image.py).
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the screen's pixels
Attributes     EQU $5800  ; the screen's attributes
InfiniteLives  EQU $5B03  ; 1 when $8000 held $C9 before the load (the loader); GameEntry then makes $A9FD OR A
Hero           EQU $5B04  ; object slot 0, the hero: X, Y, frame ($7F hidden), flags (bit 7 facing)
ObjectSlot1    EQU $5B08  ; object slots 1-3: the room's creatures; the room scripts borrow 2-4
ObjectSlot2    EQU $5B0C
ObjectSlot3    EQU $5B10
ObjectSlot4    EQU $5B14
PrevActorRects EQU $5B24  ; last pass's ActorRects (RenderPass copies 32 bytes)
ActorRects     EQU $5B44  ; per slot: back-buffer address, row plotter
Explorer       EQU $5B70  ; the chosen explorer 0-4, $FF before the first choice
TilePixelsPtr  EQU $5B72  ; the tile pixels' base, TilePixels $F000
HiScore        EQU $5B78  ; 32 bits, low byte first
BearerLoads    EQU $5B7C  ; the item each of the 27 invisible bearers carries, $FF none
Lives          EQU $5B97  ; 4 at the start
HeldItem       EQU $5B98  ; the item in hand, $FF none
Thought        EQU $5B99  ; the thought bubble's X, Y and item ($FE: gone)
LiftRoom       EQU $5B9E  ; the room the lift is in
LiftY          EQU $5B9F  ; the lift platform's Y + 8
NotOnLift      EQU $5BA0  ; 1 each pass, 0 while the hero stands on the lift
ProfessorState EQU $5BA1  ; the professor's script state in room $3B
WellHole       EQU $5BA2  ; the tile-map address of the well's hole, 0 none
WellTiles      EQU $5BA4  ; the well back-tile's rows 1-2 in BackTiles
DigitBuffer    EQU $5BA6  ; PrintByte's three digits
PanelColumns   EQU $5BD6  ; up to 12 column pointers for BlitColumns
UnicycleFrames EQU $5BFA  ; $3C while riding the unicycle in room $2F
CountdownDays  EQU $5BFB  ; the countdown: 30 days 23:59 at the start
CountdownHours EQU $5BFC
CountdownMinutes EQU $5BFD
GameWon        EQU $5BFE  ; $1D after the professor's sixth gift: the asteroid is deflected
GameOver       EQU $5BFF
BallThrown     EQU $5C00  ; room $2D's cricket ball thrown
Room           EQU $5C01  ; level x 12 + column, $14 at the start
PassCount      EQU $5C02  ; +1 every main-loop pass
RefuseCount    EQU $5C03  ; refusals of a big drop in a row
Falling        EQU $5C04  ; 1 while falling
FallPasses     EQU $5C05  ; passes of the fall, 20 or more kill on landing
Status         EQU $5C06  ; the hero's status 0-33 (StatusHandlers)
StatusTimer    EQU $5C07  ; cleared by SetStatus, counted by the handlers
JumpDirection  EQU $5C08  ; the input bits a jump moves by
HeroSavedXY    EQU $5C09  ; X, Y at the start of the pass
BridgeState    EQU $5C0C  ; the expanding bridge of rooms $19 and $3A
BridgeReverse  EQU $5C0D
ItemSlot1      EQU $5C0E  ; the room's floor items: X, Y, item ($FF none, $FE taken), the ItemPlaces record
ItemSlot2      EQU $5C13
Score          EQU $5C18  ; 32-bit signed
NumberWork     EQU $5C1C  ; PrintNumber's copy
DigitShown     EQU $5C20  ; PrintNumber: a digit printed
BearerScrollDir EQU $5C21  ; 1 key 1 (right), 0 key 2
BearerPhase    EQU $5C22  ; the bearer row's 4-step scroll
BearerIndex    EQU $5C23  ; the first bearer shown, 0-$1A
RopeCount      EQU $5C24  ; the rope of room $10 ($0D whole), drawn in room $1C
BalloonX       EQU $5C25  ; the balloon of rooms 3 and $0F: X, Y, room
BalloonY       EQU $5C26
BalloonInRoom  EQU $5C27
MudTile        EQU $5C28  ; $BC / $BD under the feet, else 0
MudPasses      EQU $5C29  ; passes on mud, 50 sinks
LifeLost       EQU $5C2A  ; $32 when the death wait ends: MainLoop respawns
RespawnStatus  EQU $5C2B  ; the respawn point: Status, StatusTimer, Room, the hero's X, Y, frame, flags, LiftRoom, LiftY
RespawnTimer   EQU $5C2C
RespawnRoom    EQU $5C2D
RespawnXY      EQU $5C2E
RespawnFrame   EQU $5C30
RespawnLift    EQU $5C32
FloatVelocity  EQU $5C34  ; room $2C: C = X, B = Y velocity
WantedItem     EQU $5C3C  ; the item the professor asks for
GiftCount      EQU $5C3D  ; the gifts given, 0-6
LastGift       EQU $5C3E
PillsTaken     EQU $5C3F  ; the Anti Radiation Pills picked up
RoomFlag       EQU $5C40  ; per room: the basket's end ($3F), the lever latch ($3E, $40)
RoomStage      EQU $5C41  ; the room script's stage, cleared on room entry
LeverState     EQU $5C42
SwitchFitted   EQU $5C43
CrystalPlaced  EQU $5C44  ; the Energy Crystal placed in room $30: the teleport pads work
CrossState     EQU $5C45  ; the Silver Cross creature: 0 waiting, 1 fleeing, $FF gone
BlankIcon      EQU $5C46  ; 72 zero bytes, the empty panel icon
StackTop       EQU $5E00
Im2Jump        EQU $5F5F  ; JP Im2Handler, written by GameEntry
Last7FFD       EQU $5FE5  ; the last value sent to port $7FFD
PagedStub      EQU $5FE6  ; the selector's paging stub (OUT (C),A; RET once patched)
Has128K        EQU $5FFE  ; $11 on a 128K, 0 on a 48K
GameLoaded     EQU $5FFF  ; 1 from GameEntry: the selector returns to the game
ExplorerSet    EQU $6000  ; the chosen explorer's sprites: frames $00-$3F of the sprite space

; Addresses in other RAM banks (@bank)
SelectorStart  EQU $C000  ; bank 1
MusicFrame     EQU $C000  ; bank 6
  ORG $7200
  INCLUDE "sprites.asm"  ; The sprite space past the explorer set: the creatures and the items
  INCLUDE "entry.asm"  ; GameEntry, the IM 2 table and the game's start
  INCLUDE "mainloop.asm"  ; The main loop, the end of a game and the restart after a lost life
  INCLUDE "util.asm"  ; Printing, distances, random numbers
  INCLUDE "ending.asm"  ; The game over, the space scene and the ending
  INCLUDE "rooms.asm"  ; The room set-up, the tile sets, the tile map and the room effects
  INCLUDE "countdown.asm"  ; The countdown and the lost game
  INCLUDE "menu.asm"  ; The title and device menu
  INCLUDE "interrupt.asm"  ; The IM 2 handler and the AY music call
  INCLUDE "render.asm"  ; The back buffer, the sprite plotter and the floor items
  INCLUDE "panel.asm"  ; The status panel: portrait, spare lives, bearers, score
  INCLUDE "player.asm"  ; The hero: tile probes, walking, climbing, falling, the room exits, the controls
  INCLUDE "status.asm"  ; The hero's statuses: jumps, rides, poses and deaths, one handler each
  INCLUDE "roomscripts.asm"  ; The room handlers and scripted puzzles
  INCLUDE "objects.asm"  ; The items: where they lie, pick up, the bearers, the swap
  INCLUDE "score.asm"  ; The score and the high score
  INCLUDE "creatures.asm"  ; The creatures of each room and their behaviours
  INCLUDE "sound.asm"  ; The beeper sound effects
  INCLUDE "tiles.asm"  ; The tiles: pixels, attributes, the alternate upper set

  SAVEBIN "game.bin",$7200,$8E00
