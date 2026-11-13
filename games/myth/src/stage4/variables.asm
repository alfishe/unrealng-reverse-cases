; --------------------------------------------------------------------------------------------------------------------
; variables.asm: The stage's work space: the play buffer's tail, the shadow attributes, the HUD picture and the records over it
;
; The block's first 5057 bytes ($6C3F-$77FF) are loaded with the stage but hold no code. $6C3F-$6CFF is the end of the
; play buffer PlayBuffer ($5B00-$6CFF: 18 character rows of 8 lines of 32 bytes, linear), $6D00-$6FFF the shadow of
; the screen's attributes. $7000-$76BF holds, as loaded, the HUD: its picture (48 lines of 32 bytes, linear) and its
; colours (6 rows of 32). StageSetUp $9715 copies the colours into the shadow and dissolves the picture onto the
; screen (DissolveHud $8FD6); from then on the space is the stage's records: the old room's colours and the burst's
; particles ($7040), the room's cells ($7280), the hero's and the 13 other actors' records ($74E0, $74F2), the 16
; missile records ($75E0), the digit picture ($7640) and the span table ($76A0). EndStage $7898 saves the screen's HUD
; lines and colours back into $7000 and $7600 before the next stage's block is loaded over them.
;
; An actor record (18 bytes, the hero's at $74E0 and 13 at $74F2): +0 X (byte column 0-29; $FF a free record), +1 Y
; (line in the play buffer), +2 width in bytes, +3 height in lines, +4/+5 the frame's bitmap, +6/+7 the handler, +8
; the frame or a counter, +9 flags (bit 0 opaque, bit 4 hit, bit 7 facing left), +$0A the state, +$0B the item kind or
; a step, +$0C the attribute, +$0D/+$0E the base X and Y (SetActorFrame $ABBD adds the frame's dx, dy to them), +$0F
; flags (bit 1 kept over a room change, bit 2 a body, bit 6 hidden, bit 7 drawn in the second pass), +$10 the
; placement's index or a counter, +$11 the pixel shift (1-99 drawn shifted by PreShiftSprite $7F89).
; --------------------------------------------------------------------------------------------------------------------

; The last 193 bytes of the play buffer PlayBuffer $5B00-$6CFF (character row
; 17's last lines)
;
; ClearBuffer $9A28 clears the play buffer to $6CFF with PUSH HL (SP from
; $6D00); RoomChange $97FB unpacks the stage's tiles and map into it from $5B00
; (stage 4: 5331 bytes, to $6FD2, on over the shadow attributes; RoomCells
; $9898 takes the map into Cells before RoomChange writes the room's colours);
; the actors are drawn into it every pass. Zero as loaded. Read and written in
; s4-right (all 193 bytes).
PlayBufferTail:
  DEFS $C1

; The shadow of the screen's 768 attributes, the screen's layout; the play area
; from $6DC2 (row 6, column 2)
;
; The HUD's colours are copied into rows 0-5 at the stage's set-up (StageSetUp
; $9715); RoomChange $97FB writes each cell's attribute into rows 6-23, the
; actors' colours are painted over them every pass, and UpdateAttributes $91D0
; copies the open cells to $5800 (ShowShadowAttributes $91C3 the whole of it).
; FillShadowAttributes $9193 paints rectangles into it with five bytes after
; its CALL. Zero as loaded. Read and written in s4-right (all 768 bytes).
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
; DissolveHud $8FD6 dissolves the 48 lines onto the screen's lines 0-47 and
; StageSetUp $9715 copies the 192 colours into the shadow rows 0-5, once, at
; the stage's start. EndStage $7898 saves the screen's lines 0-47 back here and
; the attributes $5800-$58BF to $7600 ($78B6), so the next stage's block shows
; the HUD as the player left it; the copy is CopyScreenToBlock $8FAE called at
; $7911 (its LDIR runs after EX DE,HL). Between the two the bytes are the
; records labelled inside (RoomAttributes, Cells, HeroRecord, Actors, Missiles,
; DigitBuffer, SpanTable). The picture: the frame of the HUD, the energy bar's
; box, the score box, the item strip's box, the lives and pieces boxes
; (docs/img). Read and written in s4-right (all 1728 bytes).
HudPicture:
  INCBIN "res/stage4/picture-hud-32x48.bin",$0000,64
RoomAttributes:
  INCBIN "res/stage4/picture-hud-32x48.bin",$0040,2
RoomAttributesCell:
  INCBIN "res/stage4/picture-hud-32x48.bin",$0042,574
Cells:
  INCBIN "res/stage4/picture-hud-32x48.bin",$0280,2
CellsPlay:
  INCBIN "res/stage4/picture-hud-32x48.bin",$0282,574
CellsFloor:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04C0,32
HeroRecord:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04E0,1
HeroY:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04E1,7
HeroFrame:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04E8,1
HeroFlags:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04E9,1
HeroState:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04EA,2
HeroAttribute:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04EC,1
HeroBaseX:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04ED,1
HeroBaseY:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04EE,2
HeroCounter:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04F0,2
Actors:
  INCBIN "res/stage4/picture-hud-32x48.bin",$04F2,216
LastActor:
  INCBIN "res/stage4/picture-hud-32x48.bin",$05CA,18
ActorsEnd:
  INCBIN "res/stage4/picture-hud-32x48.bin",$05DC,4
Missiles:
  INCBIN "res/stage4/picture-hud-32x48.bin",$05E0,32
HudColours:
  INCBIN "res/stage4/picture-hud-32x48.bin",$0600,16
MissilesHigh:
  INCBIN "res/stage4/picture-hud-32x48.bin",$0610,48
DigitBuffer:
  INCBIN "res/stage4/picture-hud-32x48.bin",$0640,96
SpanTable:
  INCBIN "res/stage4/picture-hud-32x48.bin",$06A0,32

; The span table's room past the HUD's colours: spans 6-42 ($76C0-$779B)
;
; BuildSpans $9959 and AddSpan $99E1 write the spans from $76A0 on; a room of
; many short runs reaches into this space. Zero as loaded. In s4-right 196 of
; its bytes are written (to $7783) and 31 read.
SpanTableRest:
  DEFS $DC

; 100 bytes no code reads or writes (s4-right; known only from the code: no
; operand in the block points into it); zero as loaded
;
; After SpanTableRest, up to the code at $7800; no instruction of the block
; names an address in it. Not read or written in any recording (the recordings
; checked: s4-right, rzx-r4); known only from the code.
Unused779C:
  DEFS $64
