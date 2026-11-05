; --------------------------------------------------------------------------------------------------------------------
; start.asm: the start-up from the loader
;
; Start runs once, from the loader. It moves the block the tape put at $BC00-$C7FF down to $5C00-$67FF and turns the
; two graphics areas the tape holds inverted the right way round, then enters MainLoop. Its own bytes after $B6FF are
; gone at the first level: $B700-$BFFF is the playfield's map buffer, cleared by $8C3B at every LevelStart ($8CC0:
; 2304 bytes from $B700) and written by the scroll ($8AED, c2: writes $B700-$BFFF).
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
  LD SP,$5C00             ; the stack under the copied block
  LD HL,TileSource        ; 3072 bytes from $BC00 to $5C00
  LD DE,$5C00
  LD BC,$0C00
  LDIR
  LD HL,SpritePad         ; 1864 bytes from $E000 complemented
  LD BC,$0748
StartInvertA:
  LD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,C
  OR B
  JR NZ,StartInvertA
  LD HL,PodSprite         ; 192 bytes from $F048 complemented
  LD BC,$00C0
StartInvertB:
  LD A,(HL)
  CPL
  LD (HL),A
  INC HL
  DEC BC
  LD A,C
  OR B
  JR NZ,StartInvertB
  JP MainLoop             ; MainLoop
