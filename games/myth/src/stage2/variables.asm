; --------------------------------------------------------------------------------------------------------------------
; variables.asm: The stage's work space: the play buffer's tail, the shadow attributes, the HUD picture and the records over it
;
; The block's first 5057 bytes ($6C3F-$77FF) are loaded with the stage but hold no code; they are laid out as stage
; 1's (the HUD picture $7000-$76BF is the same 1728 bytes as stage 1's). $6C3F-$6CFF is the end of the play buffer
; PlayBuffer ($5B00-$6CFF: 18 character rows of 8 lines of 32 bytes, linear), $6D00-$6FFF the shadow of the screen's
; attributes. $7000-$76BF holds, as loaded, the HUD: its picture (48 lines of 32 bytes, linear) and its colours (6
; rows of 32). StageSetUp $9177 copies the colours into the shadow and DissolveHud $8AD6 the picture onto the screen
; once, at the stage's start; then the space is reused: the old room's colours, the room's cells, the 14 actor
; records, the 16 missile records, the score's digit picture and the span table.
;
; An actor record (18 bytes, the hero's at $74E0 and 13 at $74F2) is stage 1's: +0 X (byte column 0-29; $FF a free
; record), +1 Y (line in the play buffer), +2 width in bytes, +3 height in lines, +4/+5 the frame's bitmap, +6/+7 the
; handler, +8 the frame or a counter, +9 flags (bit 0 opaque, bit 4 hit, bit 7 facing left), +$0A the state, +$0B the
; item kind or a step, +$0C the attribute, +$0D/+$0E the base X and Y, +$0F kept over a room change, +$10 the
; placement's number or a counter, +$11 the pixel shift (PreShiftSprite $7F10).
; --------------------------------------------------------------------------------------------------------------------

; The last 193 bytes of the play buffer PlayBuffer $5B00-$6CFF (character row
; 17's last lines)
;
; ClearBuffer $9484 clears the play buffer to $6CFF with PUSH HL (SP from
; $6D00); RoomChange $9257 unpacks the stage's tiles and map into it from $5B00
; (3852 bytes, to $6A0B); the actors are drawn into it every pass. Zero as
; loaded. Read and written in s2-right and rzx-r2 (CopyBuffer $94A9 copies it
; out).
PlayBufferTail:
  DEFS $C1

; The shadow of the screen's 768 attributes, the screen's layout; the play area
; from $6DC2 (row 6, column 2)
;
; The HUD's colours are copied into rows 0-5 at the stage's set-up (StageSetUp
; $9177); RoomChange $9257 writes each cell's attribute into rows 6-23, the
; actors' colours are painted over them every pass, and UpdateAttributes $8CD0
; copies the open cells to $5800 (ShowShadowAttributes $8CC3 the whole of it).
; FillShadowAttributes $8C93 paints rectangles into it with five bytes after
; its CALL. Zero as loaded.
ShadowAttributes:
  DEFS $C0
PlayAttributes:
  DEFS $02                ; row 6: the first row of the play area (the room's
                          ; 18 rows)
PlayAttributesCell:
  DEFS $023E              ; row 6, column 2: the room's first cell

; The HUD as loaded: 48 lines of 32 bytes (linear, top first), then their
; colours at $7600 (6 rows of 32)
;
; DissolveHud $8AD6 dissolves the 48 lines onto the screen's lines 0-47 and
; StageSetUp $9177 copies the 192 colours into the shadow rows 0-5, once, at
; the stage's start. EndStage $789D saves the screen's lines 0-47 back here and
; the attributes $5800-$58BF to $7600 when the stage ends, so the next stage's
; block shows the HUD as the player left it. The same 1728 bytes as stage 1's
; HudPicture (src/res/stage2/picture-hud-32x48.png).
HudPicture:
  INCBIN "res/stage2/picture-hud-32x48.bin",$0000,64
RoomAttributes:
  INCBIN "res/stage2/picture-hud-32x48.bin",$0040,2
RoomAttributesCell:
  INCBIN "res/stage2/picture-hud-32x48.bin",$0042,574
Cells:
  INCBIN "res/stage2/picture-hud-32x48.bin",$0280,2
CellsPlay:
  INCBIN "res/stage2/picture-hud-32x48.bin",$0282,574
CellsFloor:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04C0,32
HeroRecord:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04E0,1
HeroY:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04E1,7
HeroFrame:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04E8,1
HeroFlags:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04E9,1
HeroState:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04EA,2
HeroAttribute:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04EC,1
HeroBaseX:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04ED,1
HeroBaseY:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04EE,2
HeroCounter:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04F0,2
Actors:
  INCBIN "res/stage2/picture-hud-32x48.bin",$04F2,216
LastActor:
  INCBIN "res/stage2/picture-hud-32x48.bin",$05CA,18
ActorsEnd:
  INCBIN "res/stage2/picture-hud-32x48.bin",$05DC,4
Missiles:
  INCBIN "res/stage2/picture-hud-32x48.bin",$05E0,32
HudColours:
  INCBIN "res/stage2/picture-hud-32x48.bin",$0600,16
MissilesHigh:
  INCBIN "res/stage2/picture-hud-32x48.bin",$0610,48
DigitBuffer:
  INCBIN "res/stage2/picture-hud-32x48.bin",$0640,96
SpanTable:
  INCBIN "res/stage2/picture-hud-32x48.bin",$06A0,32

; The span table's room past the HUD's colours: spans 6-46 ($76C0-$77B9)
;
; BuildSpans $93B5 and AddSpan $943D write the spans from $76A0 on; rzx-r2
; fills them to $77B9 (47 spans; stage 1's recordings reached $779B). Zero as
; loaded.
SpanTableRest:
  DEFS $FA

; 70 bytes no code reads or writes (s2-right, rzx-r2); zero as loaded
Unused77BA:
  DEFS $46
