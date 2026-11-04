; A stale copy of $9F00-$9F69
;
; Never run. The bytes equal the start-up block $9F00-$9F69 (with its PRESS ANY
; KEY string at $862F): a copy left $1900 bytes below its place. The whole of
; $8700-$9FFF repeats $6E00-$86FF this way (next entries).
StartupCopy:
  INCBIN "res/leftovers/startup-copy.bin",$0000,106

; Unused, zero
StartupCopyTail:
  DEFS $96

; A stale copy of the sprite graphics $6E00-$7FFF
;
; Byte for byte the same as $6E00-$7FFF. The start-up head at $9F00 (not run in
; this version) moves $7C00-$9FFF down to $6300, which would put this copy in
; place; here the data is already there. Overwritten by the playfield in play.
SpriteGfxCopy:
  INCBIN "res/leftovers/sprite-gfx-copy.bin",$0000,4608

; A stale copy of the title player $8000-$85FF
;
; The same bytes as $8000-$85FF except the player's self-modified operands,
; which are 0 here ($9985 for $8085, $9C64 for $8364 and others): the player as
; assembled, before a run. The copy at $8000 carries the values of a run.
TitlePlayerCopy:
  INCBIN "res/leftovers/title-player-copy.bin",$0000,1536

; Start-up head (not run)
;
; DI; LD HL,$7C00; LD DE,$6300; LD BC,$2400; LDIR (move the font and graphics
; down to their place) then LD HL,$9F2F; CALL $EE17 (print PRESS ANY KEY). The
; game enters at $9F12, after these bytes; docs/08-hud-and-text.md 8.3.
StartupHead:
  DEFB $F3,$21,$00,$7C,$11,$00,$63,$01,$00
  DEFB $24,$ED,$B0,$21,$2F,$9F,$CD,$17,$EE

; Start-up: IM 2, the title music, then the game
;
; Called once from the entry $61A8. Sets IM 2 ($9F4B), plays tune 0 of the
; title player until it ends or a key is pressed, then copies the game screen
; image $A000-$BFFF to $4000-$5FFF, clears the lap $C2F8 and enters the game
; through $C2B1; docs/02-architecture.md 2.3.
Startup:
  CALL SetupIM2
  XOR A                   ; tune 0
  LD (TitlePlayer+$0002),A ; into the operand of LD C,n at $8001
  CALL TitlePlayer        ; the title music

; Start-up, after the title music: the play screen, then the game
;
; Reached when the title player returns (the tune ended or a key was pressed),
; not called: DI, the game screen image $A000-$BFFF copied to $4000-$5FFF (the
; play screen, its attributes and the renderer's tables at $5B00-$5FFF), the
; lap $C2F8 = 0, then JP $C2B1 into the main loop with interrupts off for good;
; docs/02-architecture.md 2.3.
StartGame:
  DI                      ; the music is over
  LD HL,GameScreenImage   ; the game screen image: pixels, attributes and
                          ; $5B00-$5FFF
  LD DE,$4000
  LD BC,$2000
  LDIR
  XOR A
  LD (LapNumber),A        ; lap 0
  JP GameStart            ; the main loop, interrupts off from here on

; "PRESS ANY KEY WHEN READY"
;
; A print string for $EE17 at (4,23), attribute 7. Only the start-up head $9F00
; and its copy print it; neither ran.
PressKeyText:
  DEFM $87,$04,$17,"PRESS ANY KEY WHEN READY",$FF

; Set up IM 2 with a safe vector
;
; Writes JP $9F68 at $FDFD, fills the 257 bytes $FE00-$FF00 with $FD and sets I
; = $FE, IM 2: whatever the bus holds, the vector is $FDFD;
; docs/02-architecture.md 2.3.
SetupIM2:
  LD A,$C3                ; JP opcode
  LD (Im2Jump),A
  LD HL,DefaultInterrupt  ; the default handler: EI; RET
  LD (Im2Jump+$0001),HL
  LD HL,Im2Table
  LD BC,$00FD             ; B = 0: 256 bytes, C = the fill byte $FD
FillVectorTable:
  LD (HL),C
  INC HL
  DJNZ FillVectorTable
  LD (HL),C               ; the 257th byte
  LD A,$FE                ; the vector table's page
  LD I,A
  IM 2
  RET

; Default IM 2 handler: EI; RET
;
; The target of JP $FDFD until the title player hooks it. Data in the
; recording: it never ran.
DefaultInterrupt:
  DEFB $FB,$C9

; Unused, zero
StartupPad:
  DEFS $96

; Game screen image: pixels
;
; The play screen with its panel, copied to $4000 by $9F1C when play starts
; ($A000-$B7FF the pixels). Part of the playfield buffer afterwards.
GameScreenImage:
  INCBIN "res/screens/game.scr",$0000,6144

; Game screen image: attributes
;
; Copied to $5800-$5AFF.
GameScreenAttrs:
  INCBIN "res/screens/game.scr",$1800,768

; Image of $5B00-$5FFF: the renderer's tables
;
; The last 1 280 bytes of the copy land at $5B00-$5FFF. The renderer reads them
; there: $5B00, $5B20, $5B40 ($E011-$E01E), $5B60, $5C60, $5BE0 ($DF23-$DF31)
; and $5DE8, $5EF0, $5CE0 ($DE1C-$DE29). $BFB4-$BFFF become ProfileMargin.
RendererTablesImage:
  INCBIN "res/tables/renderer-5b00.bin",$0000,1280
