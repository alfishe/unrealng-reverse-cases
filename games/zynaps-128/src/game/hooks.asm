; Zynaps 2 in 1: the 128K hook stubs ($B30D)
; Written by kit/mkgame.py from src/game/stubs.ann and the recordings; edit stubs.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
PAGE4              EQU $14  ; $7FFD: bank 4 at $C000 (the engine), the 48 BASIC ROM, screen 0
PAGE0              EQU $10  ; $7FFD: bank 0 at $C000 (the game)

; The variables past the loaded image (game.ann @equ)
MusicSwitch    EQU $5B50  ; the glue: A = 0 stops the music, else starts it (src/game/glue.asm)
PORT_7FFD      EQU $7FFD  ; the 128K paging port
ShipLostFlag   EQU $8072  ; the game's variable the ship-destroyed site wrote (LD ($8072),A), written here first
SelectionsText EQU $82E0  ; the game's argument the SELECTIONS site loaded (LD HL,$82E0)
SelectWeapon   EQU $91E2  ; the game's routine the weapon-select site called
BombBounceStep EQU $99A9  ; the game's routine the bomb-bounce site called
LaunchFromShip EQU $9CB0  ; the game's routine the homing site called (the shared launch from the ship's place)
ShowHonour     EQU $A423  ; the game's routine the role-of-honour site called
TakePod        EQU $A489  ; the game's routine the pod-taken site called
DrawLives      EQU $A4EF  ; the game's routine the extra-life site called (the lives redrawn)
HonourResult   EQU $A595  ; the game's routine the result site called
ScreenWipe     EQU $A685  ; the game's routine both wipe sites called
ExplosionPattern EQU $D6ED  ; the explosion's third pattern, loaded by the explosion site (LD HL,$D6ED)
ShipPlace      EQU $F36F  ; the ship's place, the argument the special-launch site loaded (LD HL,$F36F)
  ORG $B30D
  INCLUDE "stubs.asm"  ; the 128K hook stubs: one engine sound at each event the 48K beeped at

  SAVEBIN "build/obj/stubs-b30d.bin",$B30D,$009C
