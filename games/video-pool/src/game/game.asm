; Video Pool, Oxford Computer Publishing 1985 (James Hutchby): the game image $8000-$E1A7 as the $F000 turbo loader leaves it.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
KEY_SCAN       EQU $028E  ; the ROM's KEY-SCAN: DE = the key values ($FF none), NZ for more than two keys
K_TEST         EQU $031E  ; the ROM's K-TEST: E = KEY-SCAN's value, A = the character ($FF none)
BEEPER         EQU $03B5  ; the ROM's BEEPER: HL = the period, DE = the cycles less one (it plays DE + 1 cycles, 2 DE + 2 speaker writes)
SET_MIN        EQU $16B0  ; the ROM's SET-MIN: clears the editing area and the calculator stack
STACK_A        EQU $2D28  ; the ROM's STACK-A: A onto the calculator stack
STACK_BC       EQU $2D2B  ; the ROM's STACK-BC: BC onto the calculator stack
FP_TO_BC       EQU $2DA2  ; the ROM's FP-TO-BC: the last value off the calculator stack into BC (rounded)
CHAR_SET       EQU $3D00  ; the ROM's character set, glyphs $20-$7F, 8 bytes each (upper case, digits, punctuation for the print routine)
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the attributes
ERR_NR         EQU $5C3A  ; the ROM's IY base (ERR_NR): IY must hold it while the ROM runs
BORDCR         EQU $5C48  ; the ROM's border colour, bits 3-5
Im2Jump        EQU $FCFC  ; the IM 2 target: EI; JP Im2Handler (written by the entry); $FCFD patched to RET by the frame wait
Im2Table       EQU $FE00  ; the IM 2 vector table, all $FC (I = $FE)

; Names that cannot be labels (@alias)
StackTop       EQU StackSpace+$40  ; the top of the machine stack, $D000 (the first byte above it is BallSprites)
  ORG $8000
  INCLUDE "main.asm"  ; The entry, the restart, the foreground sound loop, task lists, the frame wait, the interrupt handler
  INCLUDE "input.asm"  ; The controls: keyboard, Interface 2, Kempston, cursor; the key table; BREAK
  INCLUDE "shot.asm"  ; The balls in motion: the redraw task, the draw list, the end of a shot, the start of the aim
  INCLUDE "aim.asm"  ; The aim: the power while fire is held, the cursor that runs round the cushions, their variables
  INCLUDE "physics.asm"  ; The physics task: the motion step, rolling friction, ball against ball
  INCLUDE "shotsetup.asm"  ; The shot: direction and speed through the ROM calculator
  INCLUDE "balls.asm"  ; The ball records, the other player's records, the physics counters
  INCLUDE "cushions.asm"  ; The cushions and the pockets
  INCLUDE "friction.asm"  ; The rolling friction: the steps from the direction of motion
  INCLUDE "scheduler.asm"  ; The task scheduler of the interrupt: 25 slots, add, remove, clear
  INCLUDE "tabledraw.asm"  ; The table, the power bar and its box, the aiming cursor, the XOR line
  INCLUDE "balldraw.asm"  ; The ball sprites: the draw, the 3 x 16 XOR, the screen address, the cue ball's respot, clearing for a turn
  INCLUDE "hud.asm"  ; The new game's screen, the HUD texts, the 1up / 2up blink, the "last shot" blink
  INCLUDE "gameover.asm"  ; A life lost, the foul jingle, GAME OVER, the hi score and the hall of fame hand-over
  INCLUDE "tally.asm"  ; The score of a shot: frame x ball x pocket multiplier x 10, printed term by term and counted up into the score
  INCLUDE "turns.asm"  ; The FRAME banner, the next frame, the shots per frame, the turn swap, the last-shot beep, the messages task
  INCLUDE "printing.asm"  ; The pocket multiplier marks, the number printer, the text printer and its glyph lookup
  INCLUDE "racking.asm"  ; The player variables, the rack scripts and their interpreter
  INCLUDE "rackscripts.asm"  ; The rack-in scripts of sets 1-5: how the six object balls roll onto the table before frames 3-12
  INCLUDE "halloffame.asm"  ; The hall of fame: the qualifying test, the flags on their poles, the slide of the flags, the table
  INCLUDE "nameentry.asm"  ; The name entry: the "congratulations" page, the character grid, the cursor, the 7-character name
  INCLUDE "menu.asm"  ; The main menu, the variations page, redefine keys, the settings and the menu's timeout
  INCLUDE "presents.asm"  ; The presents page: the OCP banner rolling in, "presents", the attract loop
  INCLUDE "attract.asm"  ; The attract sequence's letters: OCP turning into POOL, "video" sliding in
  INCLUDE "signature.asm"  ; The pen that writes "written by" and the signature
  INCLUDE "editor.asm"  ; The table editor: place the balls with a cursor, then play the table
  INCLUDE "workspace.asm"  ; The free space and the machine stack below the sprites
  INCLUDE "sprites.asm"  ; The 56 pre-shifted ball sprites
  INCLUDE "penscript.asm"  ; The pen script: "written by" and the signature, as pen moves
  INCLUDE "physicstables.asm"  ; The physics tables: contact, jaw radius, friction, collision records
  INCLUDE "font.asm"  ; The game's own font: a-z and 0-9
  INCLUDE "devleftover.asm"  ; Code of the development system left in the image: never run, never read

  SAVEBIN "game.bin",$8000,$61A8
