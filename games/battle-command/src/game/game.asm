; Battle Command, Ocean Software 1990 (Realtime Games; Spectrum by Stephen Hey): the game image at the
; entry `$68F4` as the SpeedLock 7 loader and the bootstrap at `$8000` leave it (tools/image.py, c1
; frame 23974): the Z80 view with banks 5, 2, 0 paged; all eight banks in work/mkgame/bankN.bin.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Addresses in other RAM banks (@bank)
FillPolygon    EQU $C4C4  ; bank 3
DrawLine       EQU $C9A7  ; bank 3
SetClipWidth   EQU $CFCD  ; bank 3
DrawDebris     EQU $D08C  ; bank 3
MoveAllDebris  EQU $D1EC  ; bank 3
StartTune      EQU $C000  ; bank 4
MusicTick      EQU $C0D2  ; bank 4
StopMusic      EQU $C1A2  ; bank 4
BriefPageBox   EQU $C079  ; bank 6
PrintStatusGrid EQU $C0F7  ; bank 6
TitleMenu      EQU $C409  ; bank 6
CopyMissionTextB6 EQU $CA23  ; bank 6
ShowWaitPointer EQU $CBF4  ; bank 6
Delay          EQU $CD63  ; bank 6
SavePointerBackground EQU $D0CA  ; bank 6
CopyViewUnderPointer EQU $D142  ; bank 6
DrawPointerInView EQU $D1BE  ; bank 6
RestorePointerBackground EQU $D251  ; bank 6
DrawPointer    EQU $D27C  ; bank 6
StatusViewMessage EQU $D3C9  ; bank 6
PanelAttributes EQU $D521  ; bank 6
UpdatePanelBars EQU $D58C  ; bank 6
QuitPrompt     EQU $DA09  ; bank 6
StatusMapFrame EQU $DA8C  ; bank 6
BriefingMapFrame EQU $DACB  ; bank 6
StatusMap      EQU $DB15  ; bank 6
BriefingMap    EQU $DB64  ; bank 6
SetStatusBlit  EQU $DBB6  ; bank 6
BlinkMarker    EQU $E5BE  ; bank 6
UnpackPicture  EQU $FE95  ; bank 7
  ORG $5B00
  INCLUDE "system.asm"  ; The 128K system area and the loader's leftovers at $5B00
  INCLUDE "mathtables.asm"  ; The 3D engine's tables in bank 5: logarithms, squares, sines, screen rows, fill patterns, work lists
  INCLUDE "gamevars.asm"  ; The game's variables in bank 5 below the entry
  INCLUDE "apivectors.asm"  ; The vectors the mission code calls: one JP per bank-2 service
  INCLUDE "boot.asm"  ; The entry: the IM 2 set-up and the jump to the title menu
  INCLUDE "missionflow.asm"  ; The mission's start, the play loops of the three views, the play keys
  INCLUDE "text.asm"  ; The screen text and attribute primitives: the print engine with control codes
  INCLUDE "screens.asm"  ; The menu screens: the screen list, the screen switch, the help lines
  INCLUDE "catalogue.asm"  ; The mission catalogue: the directory load, the text of a mission
  INCLUDE "tape.asm"  ; The tape: one block through the game's own LD-BYTES, the bank to stay in
  INCLUDE "paging.asm"  ; The paging routines: one entry per bank, the page kept in $728A
  INCLUDE "hud.asm"  ; The panel: the weapon slots, their bars and the gauges
  INCLUDE "interrupt.asm"  ; The IM 2 handler and the jobs it runs every frame
  INCLUDE "bootstrap.asm"  ; The bootstrap the loader leaves at $8000, and the stack
  INCLUDE "missionload.asm"  ; The mission load: the header, the block, the play state it sets
  INCLUDE "raster.asm"  ; The 3D view's raster: the back buffer, the blits to the screen, the clear, the projection, the clips, the arithmetic
  INCLUDE "input.asm"  ; The controls: keyboard, cursor, Sinclair, Kempston joystick and mouse
  INCLUDE "render.asm"  ; The 3D display-list interpreter: the frame start, the opcodes, the model scripts' renderers, the box generators
  INCLUDE "player.asm"  ; The player's tank: steering, fuel, armour, terrain and boundary checks, the weapons and their projectiles
  INCLUDE "objects.asm"  ; The object table: 24 records of 60 bytes, spawning from the mission list, transform, depth sort, collisions, radar
  INCLUDE "world.asm"  ; The world: the mission map (vertices, segments), its visibility, the terrain drawing, the camera
  INCLUDE "enemies.asm"  ; The resident enemy support: the hit test, kills, debris, the score of a kill
  INCLUDE "sound.asm"  ; The AY driver: the register shadow, the engine tone, the effect counters

  SAVEBIN "game.bin",$5B00,$A500
