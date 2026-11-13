; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The graphics: the CPC mode-1 pictures of the play screen, the ball, the objects and the cells
;
; Every picture here is Amstrad CPC mode-1 data: a byte holds 4 pixels in two planes (pen = bit 7-i + 2 x bit 3-i).
; The Spectrum's blitters (DrawSprite $E318, XorSprite $E3EE, the coloured $E3E5) show the low nibble only, one bit a
; pixel, so a CPC byte is 4 Spectrum pixels and a picture w bytes wide is 4w pixels; the bricks (XorBricks $E4C4) show
; the high nibble. Width and height are never stored: each caller sets SpriteWidth $A9FE and the rows in B. The
; resources are 4-pen PNGs (src/res/sprites/README.md).
;
; The leftovers $61A8, $6758, $75A8 and $8385 are bytes no routine reads (no recording reads them either); they look
; like more CPC pictures of the original.
; --------------------------------------------------------------------------------------------------------------------

; Never read: 496 bytes of CPC mode-1 picture data left from the original
; (known only from the bytes)
;
; No instruction refers to $61A8-$6397 and no recording reads it
; (work/stage1/memmap-use.txt). The bytes are mostly $F0 and $0F runs, the
; shape of a CPC frame or panel. Kept as leftovers/unused-61a8.bin.
UnusedPicture61A8:
  INCBIN "res/leftovers/unused-61a8.bin",$0000,496

; The two side panels, each 2 bytes x 192 lines, drawn by DrawSides $B488
;
; DrawSides $B488 draws SidePanels at the CPC address $F800 (left edge, B = $C0
; lines, SpriteWidth 2) and SidePanelRight $6518 at $F83C (right edge) once per
; game start. Witness: read by every recording that starts a game (c1, menu,
; gameover, rzx).
SidePanels:
  INCBIN "res/sprites/sides.bin",$0000,384
SidePanelRight:
  INCBIN "res/sprites/sides.bin",$0180,384

; The EXIT sign: two pictures of 8 bytes x 7 lines, read only by the unrun
; DrawExitSign $D08E
;
; DrawExitSign $D08E (never called) would XOR the first picture one character
; row above the exit's cell. No recording reads these 112 bytes. Known only
; from the code.
ExitSign:
  INCBIN "res/sprites/exit-sign.bin",$0000,112

; 80 zero bytes: the blank picture that erases a cell, the ball's last burst
; frame and the exit's first frame
;
; Read by the burst's last step ($B1CB, 4 x 14), FillColumn ($B4E1), OpenExit
; ($BCE1, 8 x 10), the fire put-out ($C126) and the lock opening's end ($C4B8).
; Its bytes are all zero, so a stored blank clears and an XOR leaves the screen
; as it is.
BlankPicture:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 144 zero bytes no routine reads
Unused6758:
  DEFS $90

; The ball: 16 pictures of 4 bytes x 10 lines for player 1, then 16 for player
; 2 at BallPictures2 $6A68
;
; BallPictures (the round ball) and the 15 rolling frames $6810-$6A40, 40 bytes
; apart, chosen by BallFramesRight $C4E2 / BallFramesLeft $C502 for each step
; of a move. Player 2's ball is the same set $280 bytes on ($ADE6 adds $0280
; when CurrentPlayer $ADDB is 2).
;
; Witness: read every frame of play (the ball is drawn by XOR, erased and drawn
; again); BallPictures2 is read only in two-player turns of player 2
; (work/stage2/rec/twoplayer).
BallPictures:
  INCBIN "res/sprites/ball.bin",$0000,640
BallPictures2:
  INCBIN "res/sprites/ball.bin",$0280,640

; The objects 1-40: 4 bytes x 14 lines each (56 bytes), kind k at $6CB0 + 56k
;
; TakeObject $B958 and BuildLevelObject $CFF4 find kind k at $6CB0 + 56 x k
; (kind 0, no object, is never drawn, so $6CB0 is only a base inside
; BallPictures2). Drawn in the ink ObjectInks $C6F6[k] by $E3E5. Kinds: 1
; hammer, 2 key, 3 water, 4 bottle (an extra life), 5-40 prizes
; (src/res/sprites/README.md).
ObjectPictures:
  INCBIN "res/sprites/objects.bin",$0000,2240

; Never read: 480 bytes of CPC picture data left from the original (known only
; from the bytes)
UnusedPicture75A8:
  INCBIN "res/leftovers/unused-75a8.bin",$0000,480

; Platform type 1 (and the plain one under a fire, type 8): rest, two take-off
; and three spring pictures, 8 bytes wide
;
; Rest $7788 (4 lines), take-off $77A8 and $77F8 (10 lines each, also the
; conveyors 6 and 7, PlatDraw6/7), spring $7848 (7), $7880 (9), $78C8 (7): the
; pictures SpringPics $C5D6 and TakeoffPics $C64E name for type 1. Drawn by XOR
; at the cell's screen address CellScrAddr $AB2D.
Platform1Pictures:
  INCBIN "res/sprites/platform-1.bin",$0000,32
Platform1Takeoff:
  INCBIN "res/sprites/platform-1.bin",$0020,80
Platform1Takeoff2:
  INCBIN "res/sprites/platform-1.bin",$0070,80
Platform1Spring:
  INCBIN "res/sprites/platform-1.bin",$00C0,184

; Platform type 2 (crumbling, first stage): rest 8 x 4, take-off 8 x 10 twice,
; spring 8 x 7, 8 x 9, 8 x 7
Platform2Pictures:
  INCBIN "res/sprites/platform-2.bin",$0000,376

; Platform type 3 (crumbling, second stage), 6 bytes wide: rest 6 x 4, take-off
; 6 x 8 twice, spring 6 x 6, 6 x 7, 6 x 6
Platform3Pictures:
  INCBIN "res/sprites/platform-3.bin",$0000,234

; Platform type 4 (crumbling, last stage), 4 bytes wide: rest 4 x 4, take-off 4
; x 6 twice, spring 4 x 5, 4 x 6, 4 x 5
Platform4Pictures:
  INCBIN "res/sprites/platform-4.bin",$0000,128

; Platform type 5 (the stopping platform, and the one under a fire, type 9):
; rest 8 x 4, take-off 8 x 10 twice, spring 8 x 7, 8 x 9, 8 x 7
Platform5Pictures:
  INCBIN "res/sprites/platform-5.bin",$0000,376

; Platform type 12, the spikes: 6 bytes x 7 lines (PlatDraw12 $D1B2)
SpikesPicture:
  INCBIN "res/sprites/spikes.bin",$0000,42

; The crumbling platforms' falling pictures: 8 x 4, then three of 6 x 4
; (CrumbleType3), three of 4 x 4, three of 2 x 4 and four of 2 x 5
;
; Drawn one a step by the crumble steps ($C258-$C3BF) at CrumbleAddr $AB24 as a
; platform wears from type 2 to 3, 3 to 4 and 4 to nothing.
CrumblePictures:
  INCBIN "res/sprites/crumble-8.bin",$0000,32

; Three falling pictures of 6 x 4
CrumbleType3:
  INCBIN "res/sprites/crumble-6.bin",$0000,72

; Three falling pictures of 4 x 4
CrumbleType4:
  INCBIN "res/sprites/crumble-4.bin",$0000,48

; Three falling pictures of 2 x 4
CrumbleSmall:
  INCBIN "res/sprites/crumble-2.bin",$0000,24

; Four falling pictures of 2 x 5, the last pieces
CrumbleBits:
  INCBIN "res/sprites/crumble-bits.bin",$0000,40

; The walls, 2 bytes x 24 lines each: wall 4's four frames, the locks 3, 2, 1,
; the flash, the lock's five opening frames
;
; Wall 4 (no key opens it) cycles $7E5C + 48n, n 0-3, every fourth frame
; (AnimateWalls $BC30). Locks: type 3 $7F1C, type 2 $7F4C, type 1 $7F7C
; (WallDraw3/2/1); $7FAC the flash of a key used; $7FDC-$809C the five frames
; of a type-1 lock opening ($C492-$C4B1). Drawn at WallScrAddr $AB2F.
WallPictures:
  INCBIN "res/sprites/walls.bin",$0000,192
WallLock3:
  INCBIN "res/sprites/walls.bin",$00C0,48
WallLock2:
  INCBIN "res/sprites/walls.bin",$00F0,48
WallLock1:
  INCBIN "res/sprites/walls.bin",$0120,48
WallFlash:
  INCBIN "res/sprites/walls.bin",$0150,48
WallOpening:
  INCBIN "res/sprites/walls.bin",$0180,240

; The exit: a 1-byte x 9-line mark, then four frames of 6 bytes x 5 lines at
; ExitFrames $80D5
;
; OpenExit $BCB9 draws ExitMark ($BCF6, SpriteWidth 1, 9 lines); AnimateExit
; $BD21 cycles the frames from the table $C522.
ExitMark:
  INCBIN "res/sprites/exit-mark.bin",$0000,9

; The exit's four frames, 6 x 5
ExitFrames:
  INCBIN "res/sprites/exit.bin",$0000,120

; Flames: three frames of 6 bytes x 5 lines over a burning platform (types 8
; and 9)
;
; AnimateFires $BBCD picks frame FireFrame $AA16 every fourth frame;
; PlatDraw8/9 draw the first at the build.
FirePictures:
  INCBIN "res/sprites/fire.bin",$0000,90

; The water drop's steam over a fire put out: 6 x 6, 6 x 3, 6 x 2, then 4 x 3
; at SteamSmall $81E9
;
; Drawn by the fire put-out steps ($C13E-$C185) at FireOutAddr $AB29.
SteamPictures:
  INCBIN "res/sprites/steam.bin",$0000,66

; the last steam picture, 4 x 3
SteamSmall:
  INCBIN "res/sprites/steam-small.bin",$0000,12

; The ball bursting: six pictures of 4 bytes x 14 lines (state 6, $B195-$B1C2),
; then BlankPicture
BurstPictures:
  INCBIN "res/sprites/burst.bin",$0000,336

; One brick layer: 8 bytes x 8 lines, drawn by XorBricks $E4C4 from the high
; nibbles
;
; DrawBricks $D180 draws it once a layer still standing (BrickLayers $AAD7, 8
; for a whole brick).
BrickPicture:
  INCBIN "res/sprites/bricks.bin",$0000,64

; Never read: 2231 bytes left from the original (known only from the bytes)
;
; No instruction refers to $8385-$8C3B; no recording reads it. The bytes look
; like more CPC mode-1 pictures. Note that LevelRecords is reached as $8BF1 +
; 75 x (level + 1) (BuildLevel $CF7E), an address inside this block that is
; never read.
Unused8385:
  INCBIN "res/leftovers/unused-8385.bin",$0000,2231
