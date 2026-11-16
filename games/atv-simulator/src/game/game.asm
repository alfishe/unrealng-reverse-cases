; ATV Simulator, Code Masters 1987: the game image as the tape's loader leaves it (tape block 7, 40000 bytes at $6338).
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the screen's pixels
Attributes     EQU $5800  ; the screen's attributes
TunePlayerCopy EQU $5B00  ; the tune player's copy (GameEntry's LDIR from $F850), below the image
Trail6         EQU $60AC  ; trail 6 as GameEntry copies it from $F230: its record, then its lists
StackBelowImage EQU $6334  ; ItemTooLow's stack: four bytes below the image
StackRestart   EQU $FFDA  ; the stack AbortKey restarts on
StackTop       EQU $FFDC  ; the stack's top: the loader's first byte (GameEntry)
  ORG $6338
  INCLUDE "menu.asm"  ; The title, the tune's interrupt hook, the menus, the controls, one or two players, the split screen
  INCLUDE "render.asm"  ; The renderer: the draw modes, the sprites, the buffers, the trail lists, the copy to the screen
  INCLUDE "scores.asm"  ; The high score table and the name entry; the clock, the finish, the score, the lap, EXTENDED PLAY, TIME OUT
  INCLUDE "trails.asm"  ; The six trails: the records, the object lists, the animated objects
  INCLUDE "loop.asm"  ; The entry's jumps, the game's variables, the main loop with its 7-frame wait, the interrupt
  INCLUDE "vehicle.asm"  ; The ATV and its rider: the records, the controls, speed, steering, wheelies, jumps, the ground, crashes, tumbling, the rider on foot, mounting, fuel
  INCLUDE "entry.asm"  ; The entry: the copies out of the buffers' way, the initialisation, IM 2
  INCLUDE "sound.asm"  ; The sound: the tune player (two beeper channels and drums on its own interrupt), the tunes, the effects

  SAVEBIN "game.bin",$6338,$9C40
