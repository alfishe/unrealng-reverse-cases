; --------------------------------------------------------------------------------------------------------------------
; explorers-module.asm: The five explorers' sprite sets
;
; Block 4 carries the five sets after the selector; on a 128K the set-up copies sets 0-2 to RAM 4 ($C000, $D200,
; $E400) and sets 3-4 to RAM 3 ($C000, $D200), on a 48K the selector copies the chosen one straight from here. In play
; the chosen set is ExplorerSet $6000-$71FF: frames $00-$3F of the sprite space, followed by the creatures' frames
; $40-$7F of the game image ($7200).
; --------------------------------------------------------------------------------------------------------------------

; Set 0: Fortisque-Smithe
;
; Witness: the explorers recording plays all five explorers (Explorer $5B70 =
; 0-4 at frames 1000, 3500, 6000, 9000, 11 500) and reads each set in play at
; $6000.
FortisqueSmitheSet:
  INCBIN "res/sprites/explorer-0.bin",$0000,4608

; Set 1: Herr Krusche
HerrKruscheSet:
  INCBIN "res/sprites/explorer-1.bin",$0000,4608

; Set 2: Henri Beaucoup
HenriBeaucoupSet:
  INCBIN "res/sprites/explorer-2.bin",$0000,4608

; Set 3: Big John Caine
BigJohnCaineSet:
  INCBIN "res/sprites/explorer-3.bin",$0000,4608

; Set 4: Wu Pong
WuPongSet:
  INCBIN "res/sprites/explorer-4.bin",$0000,4608
