; Chuckie Egg, A'n'F Software 1983 (Nigel Alderton): the game image $8214-$CBE7 as the loader at $5EF3 leaves it.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
BEEP           EQU $03F8  ; the ROM's BEEP: the duration and the pitch on the calculator stack
STACK_A        EQU $2D28  ; the ROM's STACK-A: A onto the calculator stack
Screen         EQU $4000  ; the display file
Attributes     EQU $5800  ; the screen attributes
KSTATE4        EQU $5C04  ; the ROM's KSTATE+4: $FF while no key is held
LAST_K         EQU $5C08  ; the ROM's last key pressed
ERR_SP         EQU $5C3D  ; the ROM's error stack pointer: tape block 3 sets it to 1, MainLoop checks it
LiveMap        EQU $61A8  ; five level maps of 672 bytes: the one in play, then one a player (1-4)
Score          EQU $6EC8  ; the score in play: six digits 0-9, the most significant first
PlayerScores   EQU $6ECE  ; the four players' scores, six digits each
EggsLeft       EQU $6EE6  ; the eggs left on the level in play (12 at its start)
PlayerEggs     EQU $6EE7  ; each player's eggs left
Level          EQU $6EEB  ; the level in play, from 0 (level 1)
PlayerLevels   EQU $6EEC  ; each player's level
PlayerLives    EQU $6EF0  ; each player's lives (5 at the start), the one in play included
SpriteBuffer   EQU $72A0  ; DrawSprite's 16 rows of 3 bytes
HarryX         EQU $72D8  ; Harry's x (the left of the sprite)
HarryY         EQU $72D9  ; Harry's y (the top of the sprite, up from the bottom)
HarryFrame     EQU $72DA  ; the walk frame 0-3
HarryDir       EQU $72DB  ; the frame base: 0 facing right, 4 facing left, $0D climbing
PassCounter    EQU $72DC  ; MainLoop's pass counter: the slow tick runs when it reaches 0 (every 130 passes)
CellBuffer     EQU $72DD  ; DrawSprite's background: 3 x 3 map cells as 24 lines of 3 bytes
JumpState      EQU $7325  ; 0 on foot, 1 drifting off an edge, 2 in the air
JumpDx         EQU $7326  ; the jump's x step: 1, $FF or 0
JumpCount      EQU $7327  ; the delay of the next vertical step, or the drift count
JumpDelay      EQU $7328  ; the passes to the next vertical step
JumpDy         EQU $732A  ; the vertical direction: 1 up, 0 the top, $FF down
ScrollDelay    EQU $732B  ; the scroller's shifts to the next character (8)
TextIndex      EQU $732C  ; the scroller's character index; the box colour of DrawBox
KeyType        EQU $732D  ; the key type: 6 type 1, 5 type 2, 3 type 3 (the bits of keys 1-3)
KeyTable       EQU $732E  ; the key set in play: (mask, port row) for up, down, left, right, jump, jump
Players        EQU $733A  ; the number of players 1-4
Player         EQU $733B  ; the player in play 1-4
LiftDelay      EQU $733C  ; the slow ticks to the next lift step (2)
ScoreScreenAddr EQU $733D  ; where AddScore prints the score: $3FFE + 7 x player
BonusDigits    EQU $733F  ; the bonus: three digits (then a printed 0)
TimeDigits     EQU $7342  ; the time: three digits
BonusDelay     EQU $7345  ; the slow ticks to the next bonus step (50)
TimeDelay      EQU $7346  ; the slow ticks to the next time step (10)
BonusRunning   EQU $7347  ; 1 while the bonus counts down
DuckX          EQU $7348  ; the duck's x
DuckY          EQU $7349  ; the duck's y
DuckDx         EQU $734A  ; the duck's x speed -5..5
DuckDy         EQU $734B  ; the duck's y speed -5..5
DuckDelay      EQU $734C  ; the slow ticks to the next duck step (12)
DuckFrame      EQU $734D  ; the duck's wing frame 0-1
Lift1          EQU $734E  ; the screen address of lift platform 1
LiftX          EQU $7350  ; the lift's x ($FF: no lift)
Lift1Row       EQU $7351  ; platform 1's height count 3-165
Lift2          EQU $7352  ; the screen address of platform 2
Lift2Row       EQU $7354  ; platform 2's height count
OnLift         EQU $7355  ; 1 while Harry rides a lift
HenTurn        EQU $7356  ; the hen MoveHen moves next 0-4
Hens           EQU $7357  ; five hen records: x ($FF: none), y, state, a spare byte
HenDelay       EQU $736B  ; the slow ticks to the next hen move (3, 2 from level 33)
RandomPtr      EQU $736C  ; MoveHen's pointer into the ROM's first 256 bytes
LastTenThousands EQU $736E  ; the score's 10 000s digit at the last extra life check
TitleTuneDone  EQU $736F  ; 1 once the title tune has played
SoundSweep     EQU $7370  ; the pickup sound's count ($FF after an egg or grain)
PhraseTimer    EQU $7373  ; the interrupts to the next phrase byte ($FF: no phrase)
PhrasePtr      EQU $7374  ; the phrase pair to send next
  ORG $8214
  INCLUDE "tables.asm"  ; The key sets, a leftover map row and the instructions page
  INCLUDE "graphics.asm"  ; The character set, the HUD characters and the sprites
  INCLUDE "hens.asm"  ; The hens: moving, eating grain, drawing, and the cell and screen addresses they use
  INCLUDE "render.asm"  ; The attributes under a sprite and the map cell address
  INCLUDE "screens.asm"  ; The title page, the HUD text, the lifts, the high score table and the cell colours
  INCLUDE "mainloop.asm"  ; The main loop and the pickup of eggs and grain
  INCLUDE "sprite.asm"  ; The sprite renderer and the duck's kill test
  INCLUDE "sound.asm"  ; Printing a character, the beeper and the speech phrases
  INCLUDE "harry.asm"  ; Harry on foot and on ladders, the map cell reader, the hen touch test
  INCLUDE "lifts.asm"  ; The two lift platforms
  INCLUDE "duck.asm"  ; The duck
  INCLUDE "timers.asm"  ; The bonus and the time
  INCLUDE "jump.asm"  ; The jump, the fall, catching a lift
  INCLUDE "score.asm"  ; The score and the extra life
  INCLUDE "flow.asm"  ; The menu, the turns, the level end, a life lost, the game over
  INCLUDE "hiscore.asm"  ; The name entry
  INCLUDE "effects.asm"  ; Boxes, delays and messages
  INCLUDE "keys.asm"  ; Redefining the keys and the speech picks
  INCLUDE "menudata.asm"  ; The tunes, the screen scroller, the high score page, the menu texts
  INCLUDE "level.asm"  ; Setting up a level
  INCLUDE "leveldata.asm"  ; The level phrases, the vector table, the edge fall, the maps, and the author's leftover text
  INCLUDE "speech.asm"  ; The speech phrases

  SAVEBIN "game.bin",$8214,$49D4
