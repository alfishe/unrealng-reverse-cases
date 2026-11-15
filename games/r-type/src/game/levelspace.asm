; --------------------------------------------------------------------------------------------------------------------
; levelspace.asm: The level space: what the loader left where each level is loaded
;
; LoadLevel loads each level's body to $C4AE; at the entry the space holds what the loader left: zeros, a stale copy
; of loader bytes and the title picture ShowLoadingScreen shows. Each level's own source is src/levelN.
; --------------------------------------------------------------------------------------------------------------------

; The level header and body (zeros at the entry)
LevelSpace:
LevelRestartColumn:
  DEFB $00                ; the block column a life restarts at
LevelRestartWave:
  DEFB $00,$00            ; the wave script entry a life restarts at
LevelChecks:
  DEFB $00,$00,$00        ; three checkpoint columns
LevelWaves:
  DEFB $00,$00,$00,$00,$00,$00 ; the wave script's start and the checkpoints'
                               ; entries
LevelObjects:
  DEFB $00,$00            ; the level's object table (LevelObject)
LevelMetatiles:
  DEFB $00,$00            ; the map, the metatiles below it (MetatileAddress)
LevelKinds:
  DEFB $00,$00            ; the enemy kinds (StartWave)
LevelMoves:
  DEFB $00,$00            ; the first movers (MoveEnemies)
LevelMoves2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the second movers
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00

; bytes the loader's last moves left, never read before a level overwrites them
LoaderLeftover:
  INCBIN "res/leftovers/loader-leftover.bin",$0000,6100

; The title picture (a SCREEN$) ShowLoadingScreen copies to the screen
TitleScreen:
  INCBIN "res/screens/title.scr",$0000,6912

; the bytes after the picture up to the sound's stack: level 1 loads over
; $F818-$F859; no play recording reads the rest
LevelSpaceTail:
  INCBIN "res/leftovers/level-space-tail.bin",$0000,90

; ten bytes the tone commands use as a stack (LD SP,$F87A: the four voice
; periods pushed, TonePlayer reads them from $F872); read in every play
; recording
SoundStack:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$01
