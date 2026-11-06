; Advanced Nether Earth (Eternity Industry, 1998): bank 3 as the game starter unpacks it ($C000-$FE1E):
; Dead End, the loss sequence, with its tune and player, and the game menu's picture routine.
; Written by kit/mkgame.py from src/endings/deadend.ann and the recordings; edit deadend.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Addresses outside this image (@equ in the annotations)
RomRet         EQU $0052  ; a RET in the 48 BASIC ROM: CALL RomRet leaves the caller's address just under SP
RomHlAlt       EQU $2758  ; HL' as the 48 ROM's interrupt routine needs it
LzPutByteOrg   EQU $74A6  ; PutByte where the authors assembled the LZ depacker: LzScreen and MenuPicture write the real address over these CALL operands before they run
HrustGetBitOrg EQU $A3B5  ; GetBit where the authors assembled HrustScreen: patched the same way
Restart        EQU $A5EF  ; the game's restart (aneD's Restart): back to the game menu

  ORG $C000
; $C000-$D2EE: the New SoundTrack player and Syrus's NETHER EARTH (END), aneS's sources (the player in module nst:
; nst.Init $C000, nst.Play $C005; the tune compiled for $CA45 from src/res/music/nether-earth-end.pt2)
  MODULE nst
  INCLUDE "src/music/stp-player.asm"
TuneLength:
  DW TuneEnd-Tune
Tune:
  INCBIN "res/music/nether-earth-end.bin"
TuneEnd:
  ENDMODULE
  ASSERT $ == $D2EF

; Dead End, bank 3 from $D2EF: $D2EF-$FE1E
  ORG $D2EF
  INCLUDE "deadend/deadend.asm"  ; Dead End: the sequence and its starfield
  INCLUDE "deadend/lzscreen.asm"  ; the Dead End picture and its depacker
  INCLUDE "deadend/gameover.asm"  ; the GAME OVER screen and its depacker (Hrust 1)
  INCLUDE "deadend/menupicture.asm"  ; the game menu's picture (the game calls it)
  INCLUDE "deadend/im2.asm"  ; the interrupt: the tune's frame

  SAVEBIN "deadend-c000-bank3.bin",$C000,15903
