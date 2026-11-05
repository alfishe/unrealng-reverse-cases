; Nether Earth ZS Edition'99: stage 2, the intro, $61A8-$7D86: the unpacked bytes of NEZSEd99.B sectors 1-18
; (read to $8000 by the BASIC's reader, unpacked by the block's own depacker at $5B00, entered at $61A8).
; Written by tools/front99_mkgame.py from the annotations (src/stage2/stage2.ann) and the recordings; edit the annotations,
; not the .asm.

  DEVICE ZXSPECTRUM48

; Addresses outside this image (the annotations @equ lines): the ROMs, the system variables, the game
RomIM1         EQU $0038  ; the ROM's IM 1 handler (keyboard scan, FRAMES)
RomClAddr      EQU $0E9E  ; ROM CL-ADDR from $0E9E: A = the character row (0-23) -> HL = its screen address, column 0
RomPixelAddr   EQU $22B0  ; ROM PIXEL-ADD from $22B0: A = the pixel line from the top, C = x -> HL = the screen byte
TrDosEntry     EQU $3D13  ; TR-DOS's entry from BASIC ROM: C = 5 reads B sectors from track D sector E to HL
Screen         EQU $4000  ; the screen's pixels
Attrs          EQU $5800  ; the screen's attributes
DosNextSector  EQU $5CF4  ; TR-DOS: the sector and track after the last one read (E sector, D track)
Pictures       EQU $7D87  ; the pictures block (src/pictures99): DecodeScreen, its entry
DecodePixelsTo EQU $7D99  ; the pictures block's DecodeScreen: the operand of its LD HL,$4000 (the pixels' target)
DecodeAttrsTo  EQU $7DD7  ; the pictures block's DecodeScreen: the operand of its LD HL,$5800 (the attributes' target)
Stage3Load     EQU $8000  ; where stage 3's packed block is read and entered
PictureBuffer  EQU $8A87  ; the decoded picture's pixels (screen layout), $8A87-$A286
PictureBufferAttrs EQU $A287  ; the decoded picture's attributes, $A287-$A586
IM2Table       EQU $B000  ; the IM 2 vector table: 257 bytes $B1 (I = $B0)
IM2Jump        EQU $B1B1  ; JP IM2Handler, written here by IntroMain
Music          EQU $C000  ; the music block (src/music99): its first byte
MusicInit      EQU $C00B  ; the music block's Init
MusicPlay      EQU $C00E  ; the music block's Play
MusicMute      EQU $C011  ; the music block's Mute

; stage 2: $61A8-$7D86
  ORG $61A8
  INCLUDE "stage2/loader.asm"  ; the intro's sequence: the two reads, the picture, the scroller loop, the exit to stage 3
  INCLUDE "stage2/effects.asm"  ; the intro's screen effects and colour cycles
  INCLUDE "stage2/print.asm"  ; the 64-column print routine and its variables
  INCLUDE "stage2/interrupt.asm"  ; the IM 2 handler: the tune each frame
  INCLUDE "stage2/texts.asm"  ; the scroller's window, text and font

  SAVEBIN "stage2-61a8.bin",$61A8,7135
