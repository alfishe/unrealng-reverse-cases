; The options menu (driver file $C8AD, run at $6D60)
; Written by tools/part_mkasm.py from src/disk/menu.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
PAGE_ROM48         EQU $10  ; port $7FFD values (the 48 ROM): bank 0 ...
PAGE_BANK7         EQU $17  ; ... bank 7

; The variables past the loaded image (game.ann @equ)
ROM_FONT       EQU $3D00  ; the 48 ROM's character set (codes 32-127)
Screen         EQU $4000  ; the screen's bitmap
Attrs          EQU $5800  ; the attribute file
BANKM          EQU $5B5C  ; the 128 system variable: the last value written to port $7FFD
SaturnsOption  EQU $646F  ; in the trampolines (src/disk/install.asm, run at $B464): OptionSaturns, 1 = YES
ShootingOption EQU $6470  ; ... OptionShooting ($B465): 0 NORMAL, 1 DISABLED, 2 CHANNEL
SoundModeOption EQU $6491  ; ... the EffectsOnly operand ($B486): 0 music and effects, 1 effects only
TimerOperand1  EQU $66EA  ; in the driver file: Gate's EFFECTS TIMER operand (bank 1 $C237) ...
TimerOperand2  EQU $670F  ; ... and PlayFxDefault's (bank 1 $C25C)
TurboOption    EQU $6C88  ; in the driver file: the loader copy's TurboTest operand (loader $6533): 1 = YES
ShipHitJump    EQU $9B50  ; Zynaps: the JP after the invulnerability test at $9B4C; INFINITE LIFE writes RET ($C9) there
LevelSelectCode EQU $B073  ; Zynaps: LD B,(HL) / INC B, the level the game goes on to; SELECT LEVEL writes LD B,n
RoundsJump     EQU $B218  ; Zynaps: a JR NC at $B218; INFINITE ROUNDS writes JR ($18)
Font           EQU $FC00  ; bank 7: the menu's bold copy of ROM_FONT (codes 32-127 at $FD00-$FFFF)
  ORG $6D60
  INCLUDE "menu.asm"  ; the options menu: ZYNAPS OPTIONS, the keys 1-7 and the hidden 0, 8 and level select

  SAVEBIN "build/disk/menu.bin",$6D60,$06A0
