; --------------------------------------------------------------------------------------------------------------------
; gamevars.asm: The game variables: the play passes, the scroll, the sound, the current player
;
; The variables the play interrupt and the scheduler share. Names follow the routines that own them (F1-F4); the
; evidence for each is its reader or writer.
; --------------------------------------------------------------------------------------------------------------------

; +1 each play pass (PlayInterrupt $AA03); bit 0 = an odd pass
;
; 48K c2 (TTD frames 300-316): +1 every 2 frames. Read by the explosion step
; $A1C8, the panel $AB13.
PassCount:
  DEFB $00

; Rotated left each pass ($AA0A): AND an object's bit +$24 picks the objects
; that act this pass
;
; EnemyFire $A0FE, the fuel tick (bit 0) in PlayerHandler $9A5B.
PassBit:
  DEFB $01

; +1 on the entry of PlayInterrupt, -1 at its end: 1 = not nested
PassDepth:
  DEFB $00

; The play pass phase 1-4 then 0; 4 on entry: the pass is skipped ($A9FB)
;
; Phase 1 starts a pass ($AA49), 2 runs the level script ($AAAD), odd phases
; MarkEnemyGrid.
PassPhase:
  DEFB $00

; The drawing chain's current step: $AAE5, +5 each phase (PlayChain $AACC)
ChainStep:
  DEFW $0000

; The head of the span node free list (pool $F800; LevelSetUp $8C3E)
NodeFreeList:
  DEFW NodePool

; The glyph cache page of the fine scroll phase: $C0 $C8 $D8 $D0 (a Gray code)
ShiftPage:
  DEFB $C0

; $08 or $10, XORed into ShiftPage by ScrollControl $A9D2
FineScrollToggle:
  DEFB $00

; $FF when the pass scrolls one fine step, 0 when not; PathOpScroll $9640 tests
; bit 0
ScrollThisPass:
  DEFB $00

; The tile set pointer $5C00 of BuildGlyph $89C9 (L replaced by the tile)
TileSet:
  DEFW $5C00

; The renderer's row counter, 18 down to 0 (DrawPlayfield $85CA)
RowsLeft:
  DEFB $00

; Rows without nodes counted by the scroll step ($8AED)
EmptyRows:
  DEFB $00

; The five bytes of the random number generator (Random $8544, seeded by $8516)
RandomSeed:
  DEFB $00,$00,$00,$00,$00

; Bit 0 set: DrawGroup places nothing (the catch-up loop $AF6B)
SkipDraw:
  DEFB $00

; Set to 6 by FireLaser $9C1D when 0; the panel ($AB13) counts it down, a pair
; of cells moving out
PanelBurst:
  DEFB $00

; The panel spinners' frame 0-15, +1 each odd pass ($AB13)
SpinnerFrame:
  DEFB $00

; The spinners' ink, + SpinnerColourStep each odd pass, bouncing between 1 and
; 7
SpinnerColour:
  DEFB $41

; +1 or -1
SpinnerColourStep:
  DEFB $01

; $FF while the ship lives; $16 at its death, counted down (PlayerDying); not
; $FF stops the scroll and the level script
DeathTimer:
  DEFB $00

; The end of play asked for: 1 a life lost, 2 the level done (script op 5), 4
; abort
EndPending:
  DEFB $00

; EndPending moved here by $ABD5: ends the play loop ($B1E9)
EndCode:
  DEFB $00

; The beeper bit toggled XOR $18 per playfield row (the engine hum)
RowBeep:
  DEFB $00

; Its AND mask: the bit shifted out of SoundPattern1 each pass ($AA30)
RowBeepMask:
  DEFB $00

; A 16-bit pattern shifted left each pass; $FD00 for an explosion
; (StartExplosion $A293)
SoundPattern1:
  DEFW $0000

; The beeper bit toggled per object strip ($8F9B)
ObjectBeep:
  DEFB $00

; Its mask: the bit of SoundPattern2 ($AA3B)
ObjectBeepMask:
  DEFB $00

; $EDB2 for an explosion
SoundPattern2:
  DEFW $0000

; The beeper bit toggled per object slot (RunObjects $9463)
SlotBeep:
  DEFB $00

; Its mask: the bit of SoundPattern3 ($AA46)
SlotBeepMask:
  DEFB $00

; $D6ED for an explosion
SoundPattern3:
  DEFW $0000

; The playing effect's +0-+6 (EffectPlay $B30C), stepped by $B379
EffectState:
  DEFB $00,$00,$00,$00,$00,$00,$00

; The effect's segment length A (the low nibble of +7)
SegLenA:
  DEFB $00

; Segment length B (the high nibble)
SegLenB:
  DEFB $00

; The effect's pitch A
PitchA:
  DEFB $00

; Pitch B
PitchB:
  DEFB $00

; The frames left in the segment
EffectFrames:
  DEFB $00

; $80 from the title interrupt $A9E4 and a new effect request, $FF from
; PlayInterrupt
;
; The effect's tone loop runs until an interrupt changes it.
EffectTick:
  DEFB $00

; The effect playing (0 none, $80 stop); a request lower than it is refused
; (RequestEffect $B2F0)
CurrentEffect:
  DEFB $00

; 1 or 2 (AddScore $A495, PrintPlayerScore $A4BF; XOR 3 at the change, $B16D)
CurrentPlayer:
  DEFB $00

; The current player's record: $7F9C or $7FCC (10 readers in 48K c1/c2)
PlayerRecord:
  DEFW $0000

; 1 or 2 (SelectPlayers $A790; ChangePlayer $B149)
Players:
  DEFB $01
