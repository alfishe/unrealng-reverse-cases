; --------------------------------------------------------------------------------------------------------------------
; start.asm: the start-up from the loader
;
; GS: Start never runs. The image is the memory after it ran (TileGraphics at $5C00 filled, the sprite sets turned),
; GameEntry goes to MainLoop, and its bytes stay in the block as a leftover. In the 48K: Start runs once, from the
; loader. It moves the block the tape put at $BC00-$C7FF down to $5C00-$67FF and turns the two graphics areas the tape
; holds inverted the right way round, then enters MainLoop. Its own bytes after $B6FF are gone at the first level:
; $B700-$BFFF is the playfield's map buffer, cleared by $8C3B at every LevelStart ($8CC0: 2304 bytes from $B700) and
; written by the scroll ($8AED, c2: writes $B700-$BFFF).
; --------------------------------------------------------------------------------------------------------------------

; the start: the code below the screen, the complemented graphics, the main
; loop
;
; Entered by the loader's jump ($B6FF). DI, SP = $5C00; $BC00-$C7FF (3072
; bytes) copied to $5C00-$67FF (the code and data the tape put above, now in
; their run place below $6800); the bytes $E000-$E747 (1864) and $F048-$F107
; (192) complemented (the tape holds them inverted); JP MainLoop. Overwritten
; from $B700 on by the playfield buffer at the first level start, so no restart
; comes back here (AbortGame jumps to MainLoopTitle).
Start:
  DI

; data_B700
data_B700:
  DEFB $31,$00,$5C        ; the stack under the copied block
  DEFB $21,$00,$BC,$11,$00,$5C,$01,$00 ; 3072 bytes from $BC00 to $5C00
  DEFB $0C,$ED,$B0
  DEFB $21,$00,$E0,$01,$48,$07 ; 1864 bytes from $E000 complemented
StartInvertA:
  DEFB $7E,$2F,$77,$23,$0B,$79,$B0,$20
  DEFB $F7
  DEFB $21,$48,$F0,$01,$C0,$00 ; 192 bytes from $F048 complemented
StartInvertB:
  DEFB $7E,$2F,$77,$23,$0B,$79,$B0,$20
  DEFB $F7
  DEFB $C3,$00,$B2        ; MainLoop
