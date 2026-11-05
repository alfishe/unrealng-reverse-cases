; --------------------------------------------------------------------------------------------------------------------
; music.asm: the AY music in the interrupts, the game's bank paging, the menu picture
;
; The game pages four other 16 K banks at $C000 while it runs: bank 1 (the tunes and their player), bank 3 (Dead End
; and the menu picture's code), bank 4 (the disk module) and bank 6 (the Final Cut block). Its own bank 0, which holds
; the code from $C000, the font, the radar, the robots and the map, is paged back every time (port $7FFD = $10: bank
; 0, screen 5, the 48 BASIC ROM).
;
; Two interrupt handlers play the tune, one frame a call, through the player's frame entry PlayerFrame ($C005 in bank
; 1): MusicInterrupt outside play (the main menu, the construction menu) and PlayMusic in play, which PlayInterrupt
; reaches by a JP in place of its CALL ShowRadar. Each pages bank 1 for the player and then pages back the bank in
; GameBank, so a frame of music can fall while bank 3 is paged.
;
; SetGameBank is the only writer of GameBank: MenuPicture pages bank 3 through it while bank 3's code draws the menu
; picture, on a stack in the code area (GlueStack, below GameEntry) because the game's own stack lies under the paged
; bank. The disk calls and the endings page their banks directly, after a HALT, with no music handler left to run in
; between.
; --------------------------------------------------------------------------------------------------------------------

; The interrupt handler outside play: one frame of the tune
;
; Installed in ImHandler by Restart ($A614) for the main menu and by
; ConstructionMenu ($C85E) while the construction menu is open (and by the
; unused SaveGame and GameStop). Keeps every register, the alternate set and
; IX, IY too, since the player in bank 1 uses them all: pages bank 1 ($11),
; calls PlayerFrame, pages back the bank in GameBank. No frame count, no radar:
; the world stands while it is in place.
MusicInterrupt:
  DI                      ; (the CPU has already turned interrupts off on
                          ; acceptance)
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  EXX
  EX AF,AF'
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  LD A,$11                ; bank 1: the tunes and their player
  LD BC,$7FFD
  OUT (C),A
  CALL PlayerFrame        ; one frame of the tune
  LD BC,$7FFD
  LD A,(GameBank)         ; the bank the game had paged
  OUT (C),A
  POP HL
  POP DE
  POP BC
  POP AF
  EX AF,AF'
  EXX
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  EI                      ; interrupts on again
  RET

; The music in play: PlayInterrupt's radar call, then one frame of the tune
;
; PlayInterrupt jumps here at $D582 in place of its CALL ShowRadar: ShowRadar
; runs as before, then bank 1's player plays a frame (the main registers and
; IX, IY kept), the bank in GameBank goes back, and the JP returns to
; PlayInterrupt after its call ($D585: the sound effect step, the exit).
PlayMusic:
  CALL ShowRadar          ; this frame's radar picture, as PlayInterrupt set it
                          ; up
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  LD A,$11                ; bank 1
  LD BC,$7FFD
  OUT (C),A
  CALL PlayerFrame        ; one frame of the tune
  LD BC,$7FFD
  LD A,(GameBank)         ; the game's bank again
  OUT (C),A
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
  JP InterruptSound       ; on in PlayInterrupt: the sound effect, the exit

; The $7FFD value the game last set: $10 (bank 0, screen 5, the 48 BASIC ROM)
;
; Written only by SetGameBank, read by both music handlers to page the game's
; bank back after the player. $13 while MenuPicture runs bank 3's code.
GameBank:
  DEFB $10

; Page the bank in A ($7FFD) and keep it in GameBank
;
; BC kept. Called by MenuPicture: bank 3 ($13) for the picture, bank 0 ($10)
; after it.
SetGameBank:
  PUSH BC
  LD BC,$7FFD
  LD (GameBank),A
  OUT (C),A
  POP BC
  RET

; The main menu's picture: bank 3's code draws it
;
; Called by MainMenuTitle ($C103). Bank 3 lies over $C000-$FFFF, the game's
; stack with it, so the picture code runs on GlueStack (SP = $A5ED); the old SP
; is kept in the operand of the LD SP at $67F9. Bank 3's MenuPictureCode
; ($E73B) unpacks the picture onto the screen; then bank 0 again.
MenuPicture:
  LD (MenuPictureSP+$0001),SP ; keep SP in the LD SP below
  LD SP,GlueStack+$0049   ; GlueStack: the bank-3 call needs a stack below
                          ; $C000
  LD A,$13                ; bank 3: Dead End and the picture
  CALL SetGameBank
  CALL MenuPictureCode    ; the picture onto the screen
  LD A,$10                ; bank 0, the game's own, again
  CALL SetGameBank
MenuPictureSP:
  LD SP,$0000             ; the old SP (self-modified operand)
  RET

; 3 bytes, never used
MusicSpare:
  DEFS $03
