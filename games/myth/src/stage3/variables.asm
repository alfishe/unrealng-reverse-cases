; --------------------------------------------------------------------------------------------------------------------
; variables.asm: The stage's work space: the play buffer's tail, the shadow attributes, the HUD picture and the records over it
;
; The block's first 5057 bytes ($6C3F-$77FF) are loaded with the stage but hold no code. $6C3F-$6CFF is the end of the
; play buffer PlayBuffer ($5B00-$6CFF: 18 character rows of 8 lines of 32 bytes, linear), $6D00-$6FFF the shadow of
; the screen's attributes. $7000-$76BF holds, as loaded, the HUD: its picture (48 lines of 32 bytes, linear) and its
; colours (6 rows of 32). StageSetUp $970D copies the colours into the shadow and dissolves the picture onto the
; screen (DissolveHud $8952); from then on the space is the stage's records: the old room's colours and the burst's
; particles ($7040), the room's cells ($7280), the hero's and the 13 other actors' records ($74E0, $74F2), the 16
; missile records ($75E0), the digit picture ($7640); the span table starts at $76E0 (stage 1: $76A0). EndStage $78B6
; saves the screen's HUD lines and colours back into $7000 and $7600 before the next stage's block is loaded over
; them. The layout is stage 1's but for the span table.
;
; An actor record (18 bytes, the hero's at $74E0 and 13 at $74F2): +0 X (byte column 0-29; $FF a free record), +1 Y
; (line in the play buffer), +2 width in bytes, +3 height in lines, +4/+5 the frame's bitmap, +6/+7 the handler, +8
; the frame or a counter, +9 flags (bit 0 opaque, bit 4 hit, bit 7 facing left), +$0A the state, +$0B the item kind or
; a step, +$0C the attribute, +$0D/+$0E the base X and Y (SetActorFrame $AC0A adds the frame's dx, dy to them), +$0F
; flags (bit 1 kept over a room change, bit 2 a body, bit 6 hidden, bit 7 drawn in the second pass), +$10 the
; placement's index or a counter, +$11 the pixel shift (drawn shifted by PreShiftSprite $7F43). As in stage 1.
; --------------------------------------------------------------------------------------------------------------------

; The last 193 bytes of the play buffer PlayBuffer $5B00-$6CFF (character row
; 17's last lines)
;
; ClearBuffer $9A7D clears the play buffer to $6CFF with PUSH HL (SP from
; $6D00); RoomChange unpacks the stage's tiles and map into it from $5B00 (4437
; bytes, to $6C54: StageGraphics); the actors are drawn into it every pass.
; Zero as loaded. Read and written in rzx-r3 and s3-right (all 193 bytes
; written in rzx-r3).
PlayBufferTail:
  DEFS $C1

; The shadow of the screen's 768 attributes, the screen's layout; the play area
; from $6DC2 (row 6, column 2)
;
; The HUD's colours are copied into rows 0-5 at the stage's set-up (StageSetUp
; $970D); RoomChange writes each cell's attribute into rows 6-23, the actors'
; colours are painted over them every pass, and UpdateAttributes copies the
; open cells to $5800 (ShowShadowAttributes $8B3E the whole of it).
; FillShadowAttributes $8B0E paints rectangles into it with five bytes after
; its CALL. The two big pictures paint their colour tables into it with $FF
; cells left alone: the dragon's at $6E92 (DragonAttributes, row 9 column 18)
; and the seated figure's at $6E59 (ThroneAttributes, row 9 column $19). Zero
; as loaded. All 768 bytes read and written in rzx-r3 and s3-right.
ShadowAttributes:
  DEFS $C0
PlayAttributes:
  DEFS $02                ; row 6: the first row of the play area (the room's
                          ; 18 rows)
PlayAttributesCell:
  DEFS $97                ; row 6, column 2: the room's first cell
ThroneAttributesCell:
  DEFS $39                ; row 9, column 25: where the seated figure's colours
                          ; (ThroneAttributes) go, 5 x 10 cells
DragonAttributesCell:
  DEFS $016E              ; row 9, column 18: where the dragon's colours
                          ; (DragonAttributes) go, 9 x 9 cells

; The HUD as loaded: 48 lines of 32 bytes (linear, top first), then their
; colours at $7600 (6 rows of 32)
;
; DissolveHud $8952 dissolves the 48 lines onto the screen's lines 0-47 and
; StageSetUp $970D copies the 192 colours into the shadow rows 0-5, once, at
; the stage's start. EndStage $78B6 saves the screen's lines 0-47 back here
; ($791B) and the attributes $5800-$58BF to $7600 ($78CA), so the next stage's
; block shows the HUD as the player left it. Between the two the bytes are the
; records labelled inside (RoomAttributes, Cells, HeroRecord, Actors, Missiles,
; DigitBuffer). The picture: the frame of the HUD, the energy bar's box, the
; score box, the item strip's box, the lives and pieces boxes. All 1728 bytes
; read and written in rzx-r3 and s3-right.
HudPicture:
  INCBIN "res/stage3/picture-hud-32x48.bin",$0000,64
RoomAttributes:
  INCBIN "res/stage3/picture-hud-32x48.bin",$0040,2
RoomAttributesCell:
  INCBIN "res/stage3/picture-hud-32x48.bin",$0042,574
Cells:
  INCBIN "res/stage3/picture-hud-32x48.bin",$0280,2
CellsPlay:
  INCBIN "res/stage3/picture-hud-32x48.bin",$0282,364
CellsDrawbridge:
  INCBIN "res/stage3/picture-hud-32x48.bin",$03EE,210
CellsFloor:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04C0,32
HeroRecord:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04E0,1
HeroY:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04E1,2
HeroHeight:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04E3,5
HeroFrame:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04E8,1
HeroFlags:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04E9,1
HeroState:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04EA,2
HeroAttribute:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04EC,1
HeroBaseX:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04ED,1
HeroBaseY:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04EE,2
HeroCounter:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04F0,2
Actors:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04F2,1
ActorsY:
  INCBIN "res/stage3/picture-hud-32x48.bin",$04F3,215
LastActor:
  INCBIN "res/stage3/picture-hud-32x48.bin",$05CA,18
ActorsEnd:
  INCBIN "res/stage3/picture-hud-32x48.bin",$05DC,4
Missiles:
  INCBIN "res/stage3/picture-hud-32x48.bin",$05E0,1
MissilesY:
  INCBIN "res/stage3/picture-hud-32x48.bin",$05E1,31
HudColours:
  INCBIN "res/stage3/picture-hud-32x48.bin",$0600,16
MissilesHigh:
  INCBIN "res/stage3/picture-hud-32x48.bin",$0610,1
MissilesHighY:
  INCBIN "res/stage3/picture-hud-32x48.bin",$0611,47
DigitBuffer:
  INCBIN "res/stage3/picture-hud-32x48.bin",$0640,128

; 32 bytes between the HUD's colours and the span table that no code reads or
; writes (rzx-r3, s3-right); zero as loaded
Unused76C0:
  DEFS $20

; The open spans CopyBuffer copies, 6 bytes each (the length, 0, the buffer
; address, the screen address; SpanCount spans), on to $77FF
;
; BuildSpans $99B1 and AddSpan $9A36 write the spans from here (stage 1 starts
; them at $76A0, over the HUD's colours; stage 3 keeps them clear of it);
; CopyBuffer $9AA2 reads them. rzx-r3 writes $76E0-$77A5 (33 spans), s3-right
; 26 spans; $77A6-$77FF (90 bytes) is never reached in the two recordings. Zero
; as loaded.
SpanTable:
  DEFS $0120
