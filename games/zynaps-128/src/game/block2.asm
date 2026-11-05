; Zynaps 2 in 1: block 2, the game and its 128K layer ($6000-$FB84)
; Written by tools/part_mkasm.py from src/game/setup.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
GameStart          EQU $8000  ; the game's own start (the menu)
GameTop            EQU $FFFF  ; the game's last byte once moved
GAME_LENGTH        EQU $9800  ; the game's length: $6800-$FFFF
HookSound          EQU $B30D  ; the hook stubs as they run (src/game/stubs.asm)
SiteShot           EQU $9C77  ; the game's call sites given a hook (docs/09-sound.md 9.2): CALL BeeperSound when the player fires
SiteExtraLife      EQU $ACA2  ; CALL $A4EF (the lives redrawn) after an extra life is given (10 000, 30 000 ... 90 000)
SiteBombBounce     EQU $9EC2  ; CALL $99A9 after a plasma bomb bounces off the ground (DEC (IY+38))
SiteHonour         EQU $A81B  ; CALL $A423: the role of honour shown
SiteHonourResult   EQU $A8B7  ; CALL $A595: its result
SiteShipLost       EQU $9BFF  ; LD ($8072),A: the ship destroyed (made a CALL)
SiteHomingLaunch   EQU $9CFA  ; CALL $9CB0: a homing missile launched (fire held with a lock)
SitePodTaken       EQU $A247  ; CALL $A489: a pod taken
SiteSpecialLaunch  EQU $9CB0  ; LD HL,$F36F: a special weapon placed at the ship (bombs, homing, seekers; made a CALL)
SiteEnemyMissile   EQU $A1C4  ; CALL BeeperSound: an enemy's missile
SiteWeaponSelect   EQU $A21A  ; CALL $91E2: a weapon selected (a pod taken with fire held 8 passes or more)
SitePodAppears     EQU $A31D  ; CALL BeeperSound: a pod appears (an object gets the pod descriptor $7EBB)
SiteExplosion      EQU $A29F  ; LD HL,$D6ED: an explosion starts (made a CALL)
SiteSelections     EQU $A7BB  ; LD HL,$82E0: the SELECTIONS screen (title key 1 or 2; made a CALL)
SiteScreenWipe1    EQU $A5D1  ; CALL $A685: the screen wipe before KEYBOARD DEFINITION (title key 3)
SiteScreenWipe2    EQU $A7F7  ; the routine at $A7F7 (the game over)'s first CALL $A685: the same wipe
CreditName         EQU $8484  ; the game's credits: the musician's name, "STEVE TURNER" in the 48K
MenuLoopJump       EQU $B21A  ; JR $B203 at the end of a game: made JR $B200, back through the main loop's CALL at $B200
BeeperOut1         EQU $B496  ; OUT ($FE),A of the 48K beeper's tone loop: made NOP: NOP
BeeperOut2         EQU $86D7  ; OUT ($FE),A: the explosion noise's toggle per playfield row (RowBeep $7F7E)
BeeperOut3         EQU $8FBD  ; OUT ($FE),A: its toggle per object strip (ObjectBeep $7F82)
BeeperOut4         EQU $949C  ; OUT ($FE),A: its toggle per object slot in RunObjects ($7F86)
LoseLife           EQU $B170  ; DEC (IX+4) (DD 35 04): the ship's lives counted down; the set-up changes its $35
StickRead          EQU $A6D4  ; IN A,($1F): AND $1F: the Kempston stick read in play
StartTest          EQU $A74E  ; IN A,($1F): AND $1F: CP $10: the menu's start test (the stick's fire alone)
Im2Fill            EQU $851D  ; LD HL,$FE00: the start of the game's IM 2 table fill
LifeStartCall      EQU $B212  ; CALL $B1B4 at a life's start

; The variables past the loaded image (game.ann @equ)
GlueRun        EQU $5B00  ; the 128K glue as it runs (src/game/glue.asm)
GlueInstall    EQU $5B87  ; its patching routine
Is128          EQU $5D3B  ; the loader's flag: 1 = 128K, 0 = 48K
InfLives       EQU $5D40  ; the intro's option INF.LIVES: not 0 = on
KMouse         EQU $5D41  ; the option K-MOUSE
MouseReset     EQU $FE00  ; the mouse driver as it runs (src/game/mouse.asm): its first entry
  ORG $6000
  INCLUDE "setup.asm"  ; block 2's set-up: the game moved, the 128K glue and hooks, the options, the start

  SAVEBIN "build/obj/block2.bin",$6000,$9B85
