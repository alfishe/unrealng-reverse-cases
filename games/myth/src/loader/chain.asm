; Myth: History in the Making, System 3 Software 1989: the BASIC's enciphered tail in its plain view, $EDE4-$FF25: the 103 layers
; of the decryption chain as each one runs, then the SpeedLock 7 loader as the last layer leaves it.
; tools/speedlock.py masters these bytes back into the tape's (src/tape/basic.asm INCBINs the result).
; Written by kit/mkgame.py from src/loader/chain.ann and the recordings; edit chain.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (stage1.ann @equ)
RomStart       EQU $0000  ; the ROM's first byte, $F3 (DI) in every Spectrum ROM
RomModelByte   EQU $006D  ; a ROM byte: $28 in the +2A/+3 ROM (TimeCheck skips its compare there)
RomCrash       EQU $033A  ; the middle of the ROM's JP M,$034F at $0339: a jump there crashes the machine
Screen         EQU $4000  ; the bitmap: the countdown's digits at $5092 on
Attributes     EQU $5800  ; the attributes
ChainRam       EQU $5D00  ; the bottom of the memory LoaderMain clears
AttrBuffer     EQU $8000  ; the loading screen's attributes as the first table row loads them
AttrRevealOff  EQU $82FF  ; the last byte of AttrBuffer: zero while the bitmap loads (Sl1Start), the attributes' last byte after
TimeBuffer     EQU $9000  ; the edge counts TimeCheck measures
Sl1Start       EQU $FF26  ; the loader's second stage (src/loader/sl1.asm), tape block 7
BlockTable     EQU $FF49  ; the block table, five bytes a row (src/loader/sl1.asm)
  ORG $EDE4
  INCLUDE "chain-module.asm"  ; The decryption chain: 103 layers, each rewriting the rest and running into it
  INCLUDE "loader.asm"  ; The SpeedLock loader: the hardware check, the memory clear, the second stage, the timing check
  INCLUDE "reveal.asm"  ; The edge loop's task: the attribute reveal, then the countdown
  INCLUDE "reader.asm"  ; The block reader: edges, pilot, sync, bytes, the block table, the end check
  INCLUDE "timing.asm"  ; The timing check: load the second stage, sample the tape's edges, compare the two ends

  SAVEBIN "chain.bin",$EDE4,$1142
