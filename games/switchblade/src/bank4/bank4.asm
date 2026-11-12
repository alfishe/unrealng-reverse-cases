; Switchblade, Gremlin Graphics 1991: TZX block 6, loaded on a 128K only into bank 4 at $C000 (8441 bytes): the
; AY music player, its tunes and the intro's story pages; the glue at $853F pages it in once a frame.
; Written by kit/mkgame.py from src/bank4/bank4.ann and the recordings; edit bank4.ann, not the .asm.

  DEVICE ZXSPECTRUM128
  SLOT 3
  PAGE 4

; The variables past the loaded image (game.ann @equ)
Attributes     EQU $5800  ; the screen's attributes
BoxString      EQU $5B01  ; DrawStoryBox's string record for PrintString (in the buffer page $5B00)
WaitFireLong   EQU $831F  ; main memory: wait 40 x 5 frames or until key 0 (fire) is pressed (H = 40, then WaitFire)
WaitFire       EQU $8321  ; main memory: wait H x 5 frames (HALTs) or until key 0 is pressed; Z set when pressed
DelayBC        EQU $8333  ; main memory: a busy loop of BC passes
ClearScreen    EQU $8339  ; main memory: clear the pixels, fill the attributes with A
PrintString    EQU $837B  ; main memory: print a string record (Y, X, two style bytes, text, 0) in the game font
PrintNextLine  EQU $83C6  ; main memory: the position of the next text line (PrintPosition sets it, $FF in a string moves there)
PrintPosition  EQU $83CD  ; main memory: B = Y in pixels, C = X in half columns -> DE = the screen address
PrintGlyph     EQU $83F9  ; main memory: draw the 8-byte glyph at HL at DE (the style bytes set by PrintString)
  ORG $C000
  INCLUDE "player.asm"  ; The AY player's entries, the tune start, the frame update and the sequencer
  INCLUDE "state.asm"  ; The sequencer's state: the channel records, the instrument slots, the drum
  INCLUDE "tunes.asm"  ; The tunes: patterns, order lists, the tune table, arpeggios, instruments, effects, the note table
  INCLUDE "ay.asm"  ; Starting a note on a channel, the envelope phases, the vibrato, the AY writes
  INCLUDE "story.asm"  ; The 128K's intro story pages

  SAVEBIN "bank4.bin",$C000,$20F9
