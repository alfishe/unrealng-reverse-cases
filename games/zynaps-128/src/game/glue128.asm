; Zynaps 2 in 1: the 128K glue ($5B00)
; Written by tools/part_mkasm.py from src/game/glue.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
PAGE4              EQU $14  ; $7FFD: bank 4 at $C000 (the engine), the 48 BASIC ROM, screen 0
PAGE0              EQU $10  ; $7FFD: bank 0 at $C000 (the game)
PORT_7FFD          EQU $7FFD  ; the 128K paging port
EngineMusicOn      EQU $C968  ; the engine (page 4, src/sound/engine.asm): start the music
EngineMusicOff     EQU $C96B  ; stop the music
EnginePlay         EQU $C96E  ; one step of the music and the effects

; The variables past the loaded image (game.ann @equ)
PauseState     EQU $7F7C  ; the game's variable the routine at $B197 ends by setting to 4 (LD ($7F7C),A at $B1B0)
IntFlag        EQU $7F96  ; the game's variable its interrupt handler at $A9E4 sets ($80)
ClearScreen    EQU $858B  ; the game's routine: the attributes and the border cleared (from $858E)
IntTailSite    EQU $A581  ; the game's handler tail POP BC: POP DE: POP HL (its POP AF at $A584 stays)
IntTailRest    EQU $A584  ; the POP AF after it
ClearSite1     EQU $A620  ; a CALL ClearScreen's operand (the routine before $A623)
ClearSite2     EQU $A7F3  ; a CALL ClearScreen's operand (the game-over routine before $A7F7)
IntMenuSite    EQU $A9E5  ; LD HL,IntFlag in the game's interrupt handler at $A9E4
IntPlaySite    EQU $A9F7  ; PUSH IX: PUSH IY at the start of the game's main interrupt work
IntPlayRest    EQU $A9FB  ; the instruction after them
IntEndSite     EQU $AB03  ; POP IY: POP IX at the end of that work
IntEndRest     EQU $AB07  ; the instruction after them
Key4Site       EQU $ABDC  ; the operand of CALL Z,$B197 (key 4, row $F7FE bit 3, in the play loop)
LevelSetUp     EQU $AD56  ; the game's routine $B023 called first (it copies a level record to $81D7)
ClearSite3     EQU $AFB4  ; a CALL ClearScreen's operand (in $AFB0, which the main loop calls at $B200)
LevelSite      EQU $B024  ; the operand of CALL LevelSetUp at $B023 (the start of a game's level)
Key4Routine    EQU $B197  ; the game's routine key 4 calls (it ends at $B1B3, after a wait)
Key4End        EQU $B1B0  ; LD (PauseState),A at its end
MainLoopCall   EQU $B201  ; the operand of the main loop's CALL $AFB0 at $B200
BeeperSound    EQU $B2F0  ; the 48K's RequestEffect (A = the beeper effect, 1-6): RET on 128K
BeeperPlay     EQU $B30C  ; the 48K's EffectPlay (the beeper effect player, a main-loop job): RET on 128K
HookSound      EQU $B30D  ; the shared hook stub (src/game/stubs.asm)
BeeperTone     EQU $B446  ; the DI of TitleTune, the 48K's beeper title tune: a NOP on 128K
  ORG $5B00
  INCLUDE "glue.asm"  ; the 128K glue: the engine each frame, the music on and off, the patches

  SAVEBIN "build/obj/glue-5b00.bin",$5B00,$00E3
