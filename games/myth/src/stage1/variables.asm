; --------------------------------------------------------------------------------------------------------------------
; variables.asm: The stage's work space: the play buffer's tail, the shadow attributes, the HUD picture and the records over it
;
; The block's first 5057 bytes ($6C3F-$77FF) are loaded with the stage but hold no code. $6C3F-$6CFF is the end of the
; play buffer PlayBuffer ($5B00-$6CFF: 18 character rows of 8 lines of 32 bytes, linear), $6D00-$6FFF the shadow of
; the screen's attributes. $7000-$76BF holds, as loaded, the HUD: its picture (48 lines of 32 bytes, linear) and its
; colours (6 rows of 32). StageSetUp $97AC copies the colours into the shadow and dissolves the picture onto the
; screen (DissolveHud $8AB1); from then on the space is the stage's records: the old room's colours and the burst's
; particles ($7040), the room's cells ($7280), the hero's and the 13 other actors' records ($74E0, $74F2), the 16
; missile records ($75E0), the digit picture ($7640) and the span table ($76A0). EndStage $789E saves the screen's HUD
; lines and colours back into $7000 and $7600 before the next stage's block is loaded over them.
;
; An actor record (18 bytes, the hero's at $74E0 and 13 at $74F2): +0 X (byte column 0-29; $FF a free record), +1 Y
; (line in the play buffer), +2 width in bytes, +3 height in lines, +4/+5 the frame's bitmap, +6/+7 the handler, +8
; the frame or a counter, +9 flags (bit 0 opaque, bit 4 hit, bit 7 facing left), +$0A the state, +$0B the item kind or
; a step, +$0C the attribute, +$0D/+$0E the base X and Y (SetActorFrame $AA02 adds the frame's dx, dy to them), +$0F
; flags (bit 1 kept over a room change, bit 2 a body, bit 6 hidden, bit 7 drawn in the second pass), +$10 the
; placement's index or a counter, +$11 the pixel shift (1-99 drawn shifted by PreShiftSprite $7F4D).
; --------------------------------------------------------------------------------------------------------------------

; The last 193 bytes of the play buffer PlayBuffer $5B00-$6CFF (character row
; 17's last lines)
;
; ClearBuffer $9AB5 clears the play buffer to $6CFF with PUSH HL (SP from
; $6D00); RoomChange $988B unpacks the stage's tiles and map into it from $5B00
; (4295 bytes, to $6BC6); the actors are drawn into it every pass. Zero as
; loaded. Read in all four stage-1 builds (c1o, deaths, s1-idle, s1-right:
; CopyBuffer $9ADA).
PlayBufferTail:
  DEFS $C1

; The shadow of the screen's 768 attributes, the screen's layout; the play area
; from $6DC2 (row 6, column 2)
;
; The HUD's colours are copied into rows 0-5 at the stage's set-up (StageSetUp
; $97AC); RoomChange $988B writes each cell's attribute into rows 6-23, the
; actors' colours are painted over them every pass, and UpdateAttributes $8CAA
; copies the open cells to $5800 (ShowShadowAttributes $8C9D the whole of it).
; FillShadowAttributes $8C6D paints rectangles into it with five bytes after
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
; DissolveHud $8AB1 dissolves the 48 lines onto the screen's lines 0-47 and
; StageSetUp $97AC copies the 192 colours into the shadow rows 0-5, once, at
; the stage's start. EndStage $789E saves the screen's lines 0-47 back here
; ($7903, CopyBlockToScreen's reverse) and the attributes $5800-$58BF to $7600
; ($78B2), so the next stage's block shows the HUD as the player left it; the
; game-over path $790D copies it back to the screen. Between the two the bytes
; are the records labelled inside (RoomAttributes, Cells, HeroRecord, Actors,
; Missiles, DigitBuffer, SpanTable). The picture: the frame of the HUD, the
; energy bar's box, the score box, the item strip's box, the lives and pieces
; boxes (docs/img). Read in all four stage-1 builds.
HudPicture:
  INCBIN "res/stage1/picture-hud-32x48.bin",$0000,64
RoomAttributes:
  INCBIN "res/stage1/picture-hud-32x48.bin",$0040,2
RoomAttributesCell:
  INCBIN "res/stage1/picture-hud-32x48.bin",$0042,574
Cells:
  INCBIN "res/stage1/picture-hud-32x48.bin",$0280,2
CellsPlay:
  INCBIN "res/stage1/picture-hud-32x48.bin",$0282,574
CellsFloor:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04C0,32
HeroRecord:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04E0,1
HeroY:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04E1,7
HeroFrame:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04E8,1
HeroFlags:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04E9,1
HeroState:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04EA,2
HeroAttribute:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04EC,1
HeroBaseX:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04ED,1
HeroBaseY:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04EE,2
HeroCounter:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04F0,2
Actors:
  INCBIN "res/stage1/picture-hud-32x48.bin",$04F2,216
LastActor:
  INCBIN "res/stage1/picture-hud-32x48.bin",$05CA,18
ActorsEnd:
  INCBIN "res/stage1/picture-hud-32x48.bin",$05DC,4
Missiles:
  INCBIN "res/stage1/picture-hud-32x48.bin",$05E0,32
HudColours:
  INCBIN "res/stage1/picture-hud-32x48.bin",$0600,16
MissilesHigh:
  INCBIN "res/stage1/picture-hud-32x48.bin",$0610,48
DigitBuffer:
  INCBIN "res/stage1/picture-hud-32x48.bin",$0640,96
SpanTable:
  INCBIN "res/stage1/picture-hud-32x48.bin",$06A0,32

; The span table's room past the HUD's colours: spans 6-42 ($76C0-$779B)
;
; BuildSpans $99E9 and AddSpan $9A6E write the spans from $76A0 on; a room of
; many short runs reaches into this space. Zero as loaded. In the stage-1
; builds 34 of its bytes are read.
SpanTableRest:
  DEFS $DC

; 100 bytes no code reads or writes (the four stage-1 builds); zero as loaded
Unused779C:
  DEFS $64
