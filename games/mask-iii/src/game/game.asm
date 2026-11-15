; MASK III: VENOM Strikes Back, Gremlin Graphics 1988: $6000-$FDFF as the loader leaves it
; (tools/image.py: TZX blocks 5 and 6 of orig/MASKIII-VENOMStrikesBack.tzx.zip); entry $9100.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the screen bitmap
Attributes     EQU $5800  ; the screen attributes
ParkedZone1    EQU $5B00  ; zone 1's characters 0-159, parked: copied there from Zone1CharsLow $F000 at GameEntry
ImTable        EQU $FE00  ; the IM 2 vector table, all $FF (GameEntry)
StackTop       EQU $FFF0  ; the stack top
ImJump         EQU $FFF4  ; JP Interrupt, written by GameEntry
MachineFlag    EQU $FFFE  ; 0 on a 128K (the loader found RAM 4), non-zero on a 48K
ImJr           EQU $FFFF  ; $18, the JR that sends the vector $FFFF to $FFF4

; Addresses in other RAM banks (@bank)
MusicStart     EQU $C000  ; bank 4: the AY player: start tune A-1 (src/music/music.ann)
MusicPlay      EQU $C003  ; bank 4: the AY player: one frame of the tune
MusicTune      EQU $C006  ; bank 4: $FF while a tune runs from its start (MusicStart $C116), 0 when every channel has ended (MusicFrame $C12D / $C133) or MusicStop $C00B; the menu's interrupt restarts tune 1 when it is not $FF ($927E)
MusicStop      EQU $C00A  ; bank 4: the player: silence
EffectChannelA EQU $C334  ; bank 4: the player's effect block of channel A
EffectChannelB EQU $C346  ; bank 4: the effect block of channel B
EffectChannelC EQU $C358  ; bank 4: the effect block of channel C
EffectStart    EQU $C36A  ; bank 4: the player: start the effect of the block at IX
  ORG $6000
  INCLUDE "zones.asm"  ; The zone graphics: three parked sets of 256 characters and 256 attributes
  INCLUDE "rooms.asm"  ; The rooms: 16 maps of 48 x 5 blocks, the 192 blocks of 4 x 4 characters
  INCLUDE "entry.asm"  ; The entry and the new game
  INCLUDE "interrupt.asm"  ; The interrupt and the main loop
  INCLUDE "menu.asm"  ; The menu, the controls, DEFINE KEYS, the password
  INCLUDE "renderer.asm"  ; The renderer: zone swapping, the dirty map, the sprites drawn as characters
  INCLUDE "objects.asm"  ; The objects, the enemies, the score, the energy, the messages and the end
  INCLUDE "matt.asm"  ; Matt: walking, jumping, pods, falling, dying
  INCLUDE "sprites.asm"  ; The pictures: control icons, Matt, the enemies, digits, mask icons
  INCLUDE "buffers.asm"  ; The live zone, the sprite characters and the buffers, with what the loader leaves in them

  SAVEBIN "game.bin",$6000,$9E00
