; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: Graphics: tiles, sprites, icons, pictures
; --------------------------------------------------------------------------------------------------------------------

  ORG $7BE5

; The font: 103 glyphs of 8 bytes for the codes $20-$86, seven rows and a blank
; one
;
; PrintString $837B: glyph = $7BE5 + (code - $20) x 8. $20-$5A the letters and
; digits, $22-$29 the frame of the name cursor, $2A / $26 and $65 / $66 the
; effects and music icons, $67-$84 the pieces of the Fireblade panel icons,
; $85-$86 MeterGlyphs. A glyph is 7 rows over a blank 8th; the tall mode
; (PrintStringTall) at an aligned Y draws row 4 twice and drops row 7; at a
; straddling Y it draws the upper cell's last row again (9 rows).
;
; Witness: $7BE5-$7DCB, $7E0D-$7E1C, $7F0D-$7F1B read by PrintGlyph $83F9 in
; every recording.
Font:
  INCBIN "res/graphics/font.bin",$0000,808
MeterGlyphs:
  INCBIN "res/graphics/font.bin",$0328,16

; The 16 panel pictures of the Fireblade as it grows: six glyph codes each
;
; $FF3C: when $664E (the pieces found) changes and is not 0, effect 5, and 6
; bytes from $7F17 + 6 x $664E are copied into FirebladePanelText $82D9 and
; printed. Witness: not read in the keyed recordings (no piece found); the code
; alone.
FirebladeIcons:
  INCBIN "res/graphics/fireblade-icons.bin",$0000,96

; The end picture: 61 rows of 6 bytes (48 x 61 pixels), drawn by DrawHavok
; $8769
;
; DrawHavok draws 10 x 8 lines of 6 bytes from $7F23 (or $7F3B) to the screen,
; so the picture is preceded by 90 or 66 bytes of FirebladeIcons on screen;
; ShiftHavokGraphic $87A6 rotates the 384 bytes $7F7D-$80FC in place (to $80FC:
; the first 18 bytes of the texts after it too). Witness: drawn in havok
; (Havok's hit points POKEd to 1).
HavokPicture:
  INCBIN "res/graphics/havok.bin",$0000,366

  ORG $D104

; The tile set: 174 tiles of 12 x 16 (tile n at `$D104` + 24 (n - 1),
; TileAddress `$8EA3`)
;
; The room cells (layers `$68-$6B`), the pickups (PickupTiles `$7BD8`) and the
; breakable blocks are all drawn from it. Tile `$43` is blank; tiles `$44-$4B`
; are the shade masks ANDed over a shaded cell (ShadeTile `$8A06`); tiles from
; `$4B` are drawn with an outline (MaskedColumn `$8C0F`). 4176 bytes
; `$D104-$E153`, 4 columns x 16 rows, 24 bytes a frame (6 bytes a column).
Tiles:
  INCBIN "res/graphics/tiles.bin",$0000,4176

; Set 1: 47 frames of 12 x 16, the small enemies and hazards
;
; Flying and walking enemies, the explosion, the spikes and flames (the sheet
; in ROOM-tmp/sheet-sprites.png). 1128 bytes `$E154-$E5BB`, 4 columns x 16
; rows, 24 bytes a frame (6 bytes a column).
EnemyFrames:
  INCBIN "res/graphics/enemies.bin",$0000,1128

; Set 2: 10 frames of 24 x 32, the giants
;
; The large enemies (the bosses' bodies) and their death cloud. 960 bytes
; `$E5BC-$E97B`, 8 columns x 32 rows, 96 bytes a frame (12 bytes a column).
GiantFrames:
  INCBIN "res/graphics/giants.bin",$0000,960

; Set 3: 51 frames of 12 x 32, Hiro
;
; Hiro's walk, climb, jump and fall frames and the energy column; actor `$5D00`
; holds this set in play (c1/end.szx). 2448 bytes `$E97C-$F30B`, 4 columns x 32
; rows, 48 bytes a frame (12 bytes a column).
HiroFrames:
  INCBIN "res/graphics/hiro.bin",$0000,2448

; Set 4: 7 frames of 15 x 32, Hiro's wider poses
;
; Hiro striking and kicking. 420 bytes `$F30C-$F4AF`, 5 columns x 32 rows, 60
; bytes a frame (12 bytes a column).
HiroFrames15:
  INCBIN "res/graphics/hiro-15.bin",$0000,420

; Set 5: 6 frames of 18 x 32, Hiro's widest poses
;
; Hiro with the arm stretched out. 432 bytes `$F4B0-$F65F`, 6 columns x 32
; rows, 72 bytes a frame (12 bytes a column).
HiroFrames18:
  INCBIN "res/graphics/hiro-18.bin",$0000,432

; Set 6: 2 frames of 21 x 32
;
; Hiro firing and crouching. 168 bytes `$F660-$F707`, 7 columns x 32 rows, 84
; bytes a frame (12 bytes a column).
HiroFrames21:
  INCBIN "res/graphics/hiro-21.bin",$0000,168

; Set 7: 22 frames of 6 x 8, sparks and shots
;
; Small shots, sparks and stars. 132 bytes `$F708-$F78B`, 2 columns x 8 rows, 6
; bytes a frame (3 bytes a column).
SparkFrames:
  INCBIN "res/graphics/sparks.bin",$0000,132

; Set 8: 10 frames of 9 x 8, shots
;
; The shots of the cyber-arm and the enemies. 90 bytes `$F78C-$F7E5`, 3 columns
; x 8 rows, 9 bytes a frame (3 bytes a column).
ShotFrames:
  INCBIN "res/graphics/shots.bin",$0000,90

; Set 9: 10 frames of 15 x 8, the score values
;
; 50, 100, 200, 400, 700, 1000, 2000, 5000, 7000 and a key. 150 bytes
; `$F7E6-$F87B`, 5 columns x 8 rows, 15 bytes a frame (3 bytes a column).
ScoreFrames:
  INCBIN "res/graphics/scores.bin",$0000,150

; Set 10: 4 frames of 27 x 16, the messages
;
; EXTRA LIFE, BONUS POINTS, PAUSE GAME, GAME OVER. 216 bytes `$F87C-$F953`, 9
; columns x 16 rows, 54 bytes a frame (6 bytes a column).
MessageFrames:
  INCBIN "res/graphics/messages.bin",$0000,216

; Set 11: the GREMLIN logo, 33 x 16
;
; Drawn on the title (the c48 recording reads it). 66 bytes `$F954-$F995`, 11
; columns x 16 rows, 66 bytes a frame (6 bytes a column).
GremlinLogo:
  INCBIN "res/graphics/gremlin-logo.bin",$0000,66

; Set 12: a piece of the title letters, 1 frame of 6 x 32
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 24 bytes `$F996-$F9AD`, 2 columns x 32 rows, 24
; bytes a frame (12 bytes a column).
TitlePiece12:
  INCBIN "res/graphics/title-12.bin",$0000,24

; Set 13: a piece of the title letters, 2 frames of 6 x 40
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 60 bytes `$F9AE-$F9E9`, 2 columns x 40 rows, 30
; bytes a frame (15 bytes a column).
TitlePiece13:
  INCBIN "res/graphics/title-13.bin",$0000,60

; Set 14: a piece of the title letters, 1 frame of 6 x 48
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 36 bytes `$F9EA-$FA0D`, 2 columns x 48 rows, 36
; bytes a frame (18 bytes a column).
TitlePiece14:
  INCBIN "res/graphics/title-14.bin",$0000,36

; Set 15: a piece of the title letters, 2 frames of 15 x 40
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 150 bytes `$FA0E-$FAA3`, 5 columns x 40 rows, 75
; bytes a frame (15 bytes a column).
TitlePiece15:
  INCBIN "res/graphics/title-15.bin",$0000,150

; Set 16: a piece of the title letters, 1 frame of 18 x 24
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 54 bytes `$FAA4-$FAD9`, 6 columns x 24 rows, 54
; bytes a frame (9 bytes a column).
TitlePiece16:
  INCBIN "res/graphics/title-16.bin",$0000,54

; Set 17: a piece of the title letters, 2 frames of 18 x 32
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 144 bytes `$FADA-$FB69`, 6 columns x 32 rows, 72
; bytes a frame (12 bytes a column).
TitlePiece17:
  INCBIN "res/graphics/title-17.bin",$0000,144

; Set 18: a piece of the title letters, 1 frame of 18 x 40
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 90 bytes `$FB6A-$FBC3`, 6 columns x 40 rows, 90
; bytes a frame (15 bytes a column).
TitlePiece18:
  INCBIN "res/graphics/title-18.bin",$0000,90

; Set 19: a piece of the title letters, 1 frame of 24 x 8
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 24 bytes `$FBC4-$FBDB`, 8 columns x 8 rows, 24
; bytes a frame (3 bytes a column).
TitlePiece19:
  INCBIN "res/graphics/title-19.bin",$0000,24

; Set 20: a piece of the title letters, 2 frames of 24 x 24
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 144 bytes `$FBDC-$FC6B`, 8 columns x 24 rows, 72
; bytes a frame (9 bytes a column).
TitlePiece20:
  INCBIN "res/graphics/title-20.bin",$0000,144

; Set 21: a piece of the title letters, 1 frame of 24 x 40
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 120 bytes `$FC6C-$FCE3`, 8 columns x 40 rows, 120
; bytes a frame (15 bytes a column).
TitlePiece21:
  INCBIN "res/graphics/title-21.bin",$0000,120

; Set 22: a piece of the title letters, 1 frame of 12 x 8
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 12 bytes `$FCE4-$FCEF`, 4 columns x 8 rows, 12
; bytes a frame (3 bytes a column).
TitlePiece22:
  INCBIN "res/graphics/title-22.bin",$0000,12

; Set 23: a piece of the title letters, 1 frame of 42 x 32
;
; Sets 12-23 are the pieces of the SWITCHBLADE title letters (the c48 recording
; reads them at the title). 168 bytes `$FCF0-$FD97`, 14 columns x 32 rows, 168
; bytes a frame (12 bytes a column).
TitlePiece23:
  INCBIN "res/graphics/title-23.bin",$0000,168
