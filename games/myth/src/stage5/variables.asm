; --------------------------------------------------------------------------------------------------------------------
; variables.asm: The stage's work space: the play buffer's tail, the shadow attributes, the HUD picture and the records over it
;
; The block's first 5057 bytes ($6C3F-$77FF) are loaded with the stage and hold no code; they are byte for byte stage
; 1's ($6C3F-$6FFF and $76C0-$77FF zeros, the HUD picture and its colours at $7000-$76BF). $6C3F-$6CFF is the end of
; the play buffer ($5B00-$6CFF), which in stage 5 holds the intro's and the ending's text pages ($5B00-$61FF,
; $6200-$68FF, DrawIntroText $8DAF, DrawEndingText $8DDE). $6D00-$6FFF is the shadow of the screen's attributes. After
; StageSetUp $95E4 has dissolved the HUD onto the screen, the picture's space holds stage 5's records: Dameron's
; missiles (Missiles $7000, 8 x 6 bytes), the burst's particles (Particles $7100, 4 bytes each), the hero's shots
; (HeroShots $75E0, 16 x 8 bytes) and the digit picture (DigitBuffer $7640). The hero's record and the stars lie in
; the data area (HeroRecord $BA7E, Stars $BA86).
; --------------------------------------------------------------------------------------------------------------------

; The last 193 bytes of the play buffer PlayBuffer $5B00-$6CFF
;
; ClearBuffer $96AC clears the play buffer to $6CFF with PUSH HL. In stage 5
; the buffer holds the two text pages from PlayBuffer $5B00 to $68FF; this tail
; is not written or read by stage 5's code (no recording reads or writes
; $6C3F-$6CFF: s5-right, rzx-r5, ending). Zero as loaded.
PlayBufferTail:
  DEFS $C1

; The shadow of the screen's 768 attributes, the screen's layout
;
; StageSetUp $95E4 copies the HUD's colours into rows 0-5 and shows the whole
; shadow (ShowShadowAttributes $95B0); FillShadowAttributes $957F paints its
; boxes into it (HudBox1-4, the play area black). The rest of stage 5 colours
; the screen's attributes directly (Attributes $5800). s5-right: 896 bytes
; written ($6D00-$707F, with the missile records), 9350 reads at most. Zero as
; loaded.
ShadowAttributes:
  DEFS $C0
PlayAttributes:
  DEFS $0240              ; row 6: the first row of the play area
                          ; (AttrShadowAddress $A000, kept from stage 1, no
                          ; caller)

; The HUD as loaded: 48 lines of 32 bytes (linear, top first), then their
; colours at $7600 (6 rows of 32)
;
; The same 1728 bytes as stage 1's (src/res/stage1/picture-hud-32x48.png).
; DissolveHud $941B dissolves the 48 lines onto the screen's lines 0-47 and
; StageSetUp $95E4 copies the 192 colours into the shadow rows 0-5, once, at
; the stage's start. EndStage $78B5 saves the screen's lines 0-47 back here
; ($78CC copies the colours to HudColours $7600, CopyScreenToBlock $93F3 the
; lines to $7000) before the next block is loaded.
;
; In play the picture's space holds the records below. s5-right reads
; $6D00-$76BF (the dissolve and the records) and writes $7000-$707F and
; $75E0-$766F.
HudPicture:
Missiles:
  INCBIN "res/stage5/picture-hud-32x48.bin",$0000,48
MissilesEnd:
  INCBIN "res/stage5/picture-hud-32x48.bin",$0030,208
Particles:
  INCBIN "res/stage5/picture-hud-32x48.bin",$0100,992
ActorRecords:
  INCBIN "res/stage5/picture-hud-32x48.bin",$04E0,256
HeroShots:
  INCBIN "res/stage5/picture-hud-32x48.bin",$05E0,32
HudColours:
  INCBIN "res/stage5/picture-hud-32x48.bin",$0600,16
HeroShots6:
  INCBIN "res/stage5/picture-hud-32x48.bin",$0610,48
DigitBuffer:
  INCBIN "res/stage5/picture-hud-32x48.bin",$0640,32
HudColoursRest:
  INCBIN "res/stage5/picture-hud-32x48.bin",$0660,96

; 320 bytes ($76C0-$77FF) no stage-5 code reads or writes
;
; Stage 1's span table room ($76A0-$779B) and its unused tail. Stage 5 copies
; no spans: no operand of its code names $7680-$77FF (checked over the listing
; $7800-$A366), and no recording (s5-right, rzx-r5, ending) reads or writes any
; of it. Zero as loaded.
Unused76C0:
  DEFS $0140

  ORG $BA7E

; The hero's record: +0 X in pixels, +1 the screen line, +4 the state, +5 the
; frame, +6 the game-over count
;
; InitHero $7EE9 sets X $40, line $68, state 0, the count $5A; HeroControl
; $7F1E moves it (X $12-$66, line $40-$96) and steps the explosion; DrawHero
; $8576 and DrawHeroFrame $9D85 draw it; CheckShotHitsHero $A33E tests the
; missiles against +0, +1. +2, +3 and +7 are read by no code. The bytes as
; loaded ($CC $7F $C1 $04 $00 $03 $1F $2B) are overwritten by InitHero before
; any read. s5-right: 16034 reads of +0/+1, the state 16187.
HeroRecord:
  DEFB $CC
HeroLine:
  DEFB $7F                ; +1 the screen line
HeroUnused2:
  DEFB $C1,$04            ; +2, +3: no reader
HeroState:
  DEFB $00                ; +4: 0 flying, 1 exploding, 2 re-forming, 3 game
                          ; over
HeroFrame:
  DEFB $03                ; +5 the explosion's frame
HeroGameOverCount:
  DEFB $1F                ; +6: $5A, - 1 on each even pass in state 3; at 0
                          ; MainLoop ends the stage (E = 0)
HeroUnused7:
  DEFB $2B                ; +7: no reader

; The 16 stars, 4 bytes each: +0 X in pixels, +1 the screen line, +2 the speed
; (0 slow, 1 fast), +3 a counter
;
; InitStars $85F9 seeds them; MoveStars $8627 moves them (4 or 8 pixels a pass
; to the left) and gives a wrapped star a new line; DrawStars $8672 draws them.
; The bytes as loaded are overwritten by InitStars. s5-right: 13441 reads.
Stars:
  DEFB $64,$48,$00,$00
  DEFB $8C,$B0,$00,$00
  DEFB $14,$58,$00,$00
  DEFB $D2,$60,$00,$00
  DEFB $28,$98,$00,$00
  DEFB $48,$80,$00,$00
  DEFB $B4,$88,$00,$00
  DEFB $C7,$50,$00,$00
  DEFB $1E,$68,$00,$00
  DEFB $7D,$70,$00,$00
  DEFB $9C,$78,$00,$00
  DEFB $F0,$90,$00,$00
  DEFB $3E,$A0,$00,$00
  DEFB $55,$A8,$00,$00
  DEFB $5A,$B8,$00,$00
  DEFB $86,$30,$00,$00
