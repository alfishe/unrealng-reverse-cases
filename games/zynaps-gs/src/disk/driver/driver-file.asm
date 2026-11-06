; The GS driver file (bank 1 $C000-$CF4C)
; Written by kit/mkgame.py from src/disk/driver.ann and the recordings; edit driver.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
GS_DATA            EQU $B3  ; the GS ports: the data register (write: to the card; read: the card's answer) ...
GS_CMD             EQU $BB  ; ... the command register (write) and the status (read: bit 0 command busy, bit 7 data busy)

; The variables past the loaded image (game.ann @equ)
SavedArea      EQU $5B00  ; the stub and the system variable area $5B00-$5D3A, swapped with SavedAreaCopy over a level load
LoaderStartFx  EQU $61A8  ; the level loader's entries once SwapLoader has put it at $61A8 (src/disk/loader.ann)
LoaderPlayStartFx EQU $61B7  ; inside LoaderStartFx: the jingle played without uploading it again
LoaderFx       EQU $61BF  ; the loader: the 10 in-game FX, and in effects-only mode the 11 disk FX
LoaderModule   EQU $6277  ; the loader: the module of level (Level)
ZynapsState    EQU $7F6A  ; a Zynaps byte: $C0 lets every sound past the gate (the game's play state, to be named with the game)
Player1LaserLevel EQU $7FA6  ; Zynaps: player 1's laser level 0-3 (its record $7F9C + $0A); 2 and up picks FX 10. Player 2's record is not read: in a two-player game the second player's shot sound follows player 1's laser
GateCountdown  EQU $AA29  ; the countdown the gate sets and the $AA28 stub counts down (the operand of its LD A,n)
LevelSelectCode EQU $B073  ; Zynaps's LD B,(HL) at $B073: the menu's level select writes LD B,n there ($06)
RoundWaitFrames EQU $B109  ; the operand of Zynaps's LD A,n at $B108: the frames of the wait between rounds
FxVolume       EQU $B45F  ; the variables the installer puts at $B446 (src/disk/install.asm): the FX volume ($40) ...
ModuleVolume   EQU $B460  ; ... the level's module volume (the loader sets it from its table)
Level          EQU $B461  ; ... the level whose sound is loaded (1-13, 13 the title)
NextLevel      EQU $B462  ; ... the level the game goes to (the $FF87 stub writes it)
LoadKind       EQU $B463  ; ... what LevelChange loads: 0 a level, 1 the game start (jingle and FX), 2 the title module
OptionSaturns  EQU $B464  ; ... the menu's "SATURNS": 0 = NO
OptionShooting EQU $B465  ; ... the menu's "SHOOTING": 0 NORMAL, 1 DISABLED (no shot sound), 2 CHANNEL
SoundOn        EQU $B472  ; the operand of CallDriver's LD A,1: the driver is called when it is not 0
EffectsOnly    EQU $B486  ; the operand of CallDriverFx's LD A,n: 0 music and effects, 1 effects only (menu key 1 / 2)
StackArea      EQU $BE00  ; Zynaps's bytes under the loader's stack, kept in StackAreaCopy over a level load
LoaderStack    EQU $BED3  ; the stack during a level load (below the Trush blocks' load address $BED4)
StackAreaCopy  EQU $CF90  ; bank 1: the copy of StackArea
SavedAreaCopy  EQU $D190  ; bank 1: the copy of SavedArea
  ORG $C000
  INCLUDE "driver.asm"  ; the GS driver: the sounds the patched sites ask for, the level change, the card commands

  SAVEBIN "build/disk/driver.bin",$C000,$0F4D
