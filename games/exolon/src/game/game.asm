; Exolon, Hewson Consultants 1987: the game image as the Hewson loader's move leaves it ($6D60-$FFFF, entry $6D60).
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
OpenCells      EQU $5B00  ; per character cell: $FF nothing drawn there (sprites show), 0 scenery in front
AttrCopy       EQU $5E00  ; the attributes as the screen builder left them; sprites colour only cells that are 0
CellTypes      EQU $6100  ; per cell: 0 empty, 1 solid, 2-17 an object cell while the screen is built
BitReverse     EQU $6400  ; each byte bit-reversed: the player's frames mirrored for facing left
LineAddrHigh   EQU $6500  ; the high byte of each pixel line's screen address
LineAddrLow    EQU $6600  ; the low byte
LineCol8Addr   EQU $6700  ; the address of column 8 of each pixel line (the Hall of Fame scroll)
  ORG $6D60
  INCLUDE "menu.asm"  ; The entry, the machine test, the menu with its stars, the define keys and the ZORBA cheat
  INCLUDE "hiscore.asm"  ; The Hall of Fame: the table of 50 and its rolling display
  INCLUDE "mainloop.asm"  ; The start of a game, the main loop and the HUD frame
  INCLUDE "sprites.asm"  ; The sprite drawers: 24x32 and 16x16, shifted, masked by the open cells
  INCLUDE "input.asm"  ; The controls (keyboard, Interface 2, Kempston) and the tables built at the start
  INCLUDE "beeper.asm"  ; The beeper noise and sweep effects
  INCLUDE "colour.asm"  ; The sprites' colour cells, and the wait for a key or fire
  INCLUDE "tunes.asm"  ; The beeper tunes and the two-voice tone player
  INCLUDE "player.asm"  ; The cell map helpers, the player's walk, jump and fall, the shots
  INCLUDE "screens.asm"  ; The screen change, the screen builder and its 62 scenery elements
  INCLUDE "hud.asm"  ; The cell maps cleared and saved, the HUD numbers
  INCLUDE "objects.asm"  ; The object cells indexed into lists: flames, turrets and their shells, the colour cycle
  INCLUDE "mines.asm"  ; The mines
  INCLUDE "grenade.asm"  ; The grenade: the throw, the arc, the walls
  INCLUDE "effects.asm"  ; The small XOR sprites and their wall probes, the grenade blast, the debris, the puffs
  INCLUDE "pickups.asm"  ; The teleports, the ammunition and grenade pods, the printers, the abort keys
  INCLUDE "balls.asm"  ; The balls and their spawners
  INCLUDE "death.asm"  ; The player's contacts, the traps, the death
  INCLUDE "guns.asm"  ; The guns and their shots, the shells against the shots and the player
  INCLUDE "passtime.asm"  ; The pass time pads, the bonus ticks, the teleport sparkles, the exoskeleton booth
  INCLUDE "blasts.asm"  ; The aliens hit, the blasts
  INCLUDE "gameover.asm"  ; GAME OVER and the Hall of Fame name entry
  INCLUDE "aliens.asm"  ; The homing missile, the stars, the bonus pick-ups, the aliens on paths, the flickering pad
  INCLUDE "zoneend.asm"  ; The end of a zone: the bonuses, the bonus screen, CONGRATULATIONS
  INCLUDE "forcefield.asm"  ; The force field and the idle missile
  INCLUDE "utils.asm"  ; The keyboard, the pause, the random numbers, the score
  INCLUDE "text.asm"  ; The character printers, the string interpreter, the screen helpers
  INCLUDE "workarea.asm"  ; The sprite save buffers
  INCLUDE "music.asm"  ; The 128K title tune on the AY
  INCLUDE "sound.asm"  ; The AY sound effects (silent on a 48K)
  INCLUDE "cpc.asm"  ; The Amstrad CPC keyboard scan, never run on the Spectrum, and the sound effects' empty channel
  INCLUDE "layouts.asm"  ; The screen table and the 125 screen layouts
  INCLUDE "graphics.asm"  ; The font, the scenery glyphs, the sprites
  INCLUDE "leftover.asm"  ; What the development machine left: the BASIC stack, the UDGs, a serial downloader

  SAVEBIN "game.bin",$6D60,$92A0
