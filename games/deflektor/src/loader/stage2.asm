; Deflektor, Gremlin Graphics 1987: the loader's second stage, $B75A-$BBDE, loaded in three pieces by the
; first ($10F, $74 and $302 bytes): the countdown, the loading screen's script engine and the rest of the load.
; Written by kit/mkgame.py from src/loader/stage2.ann and the recordings; edit stage2.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
MoveStub       EQU $5B00  ; the printer buffer: LoadFiles writes LDIR; RET there and jumps to it
HookCount      EQU $B626  ; the first stage's variables (src/tape/basic.ann)
TickHooks      EQU $B627
Countdown      EQU $B628
LoadFlags      EQU $B62B
ScriptWait     EQU $B62C
PrintRow       EQU $B62D
PrintColumn    EQU $B62F
AttrPair       EQU $B630
PrintAttr      EQU $B631
ScriptPtr      EQU $B632
CountdownAt    EQU $B634
CountdownPair  EQU $B636
WindowLeft     EQU $B63B
WindowRight    EQU $B63C
WindowTop      EQU $B63D
WindowBottom   EQU $B63F
FontPtr        EQU $B641
FillChar       EQU $B643
RepeatCount    EQU $B644
PictureWidth   EQU $B645
PictureRows    EQU $B646
PictureAt      EQU $B647
PadPairs       EQU $B6FD  ; the first stage's routines (src/tape/basic.ann)
EdgePair       EQU $B70A
EdgeWait       EQU $B70E
EdgeNoDelay    EQU $B714
LoadBlock      EQU $B727
ByteHook       EQU $B752
HighBuffer     EQU $C000  ; where the main block's last $4000 bytes are loaded before the move
  ORG $B75A
  INCLUDE "loader2.asm"  ; The loader's second stage: the hook's work every 8th byte
  INCLUDE "script.asm"  ; The loading screen's script engine: one item a step, characters printed with the loader's font
  INCLUDE "countdown.asm"  ; The stage's own last pieces and the countdown in seconds
  INCLUDE "control.asm"  ; The script's control codes below 32
  INCLUDE "loads.asm"  ; The rest of the turbo block: the glyphs, the script and the game, and the move at the end
  INCLUDE "cells.asm"  ; Picture cells, the control-code table and the load parameters

  SAVEBIN "stage2.bin",$B75A,$0485
