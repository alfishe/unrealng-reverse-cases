; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The development link, the graphics and the level data: the font, the characters, the blocks, the room maps and the sprites
;
; DEMO's code block loads at $61A8 like part 2's, and its first 314 bytes are part 2's development link byte for byte
; but the return address word $62BE ($DB4B here). The graphics follow part 1's at +$258 (font, characters, blocks);
; the sprites are part 1's set without the roll call and with the tutor's arrow ($88FC).
; --------------------------------------------------------------------------------------------------------------------

; Leftover: the development link's code, part 2's own (DevLink in
; src/rex2/graphics.asm): pages the link in, saves every register, then serves
; the host's commands until a return
;
; Byte for byte part 2's but the word at $62BE (the return address the host's
; command $B5 sets: $DB4B in DEMO, $D6C6 in REX 2). Nothing calls it.
DevLink:
  INCBIN "res/leftovers/demo-devlink.bin",$0000,283
DevLinkGet:
  ; $62C3 code: E = a byte from the host (port $1F) after the handshake on
  ;   port $3F
  INCBIN "res/leftovers/demo-devlink.bin",$011B,16
DevLinkPut:
  ; $62D3 code: a byte to the host (port $1F), then the handshake on port
  ;   $3F
  INCBIN "res/leftovers/demo-devlink.bin",$012B,15

; The link's state: a work word, the 26 bytes it sends ($62E4), the saved HL,
; return address and SP; tape garbage, never written in play
DevLinkState:
  INCBIN "res/leftovers/demo-devlink.bin",$013A,28

; Leftover: 58 zero bytes before the font (its codes 25-31 would be at
; $6300-$6337); nothing reads them
Unused62FE:
  INCBIN "res/leftovers/demo-devlink.bin",$0156,58

; The font: 64 characters, codes 32-95 (space to underscore), 8 bytes each, at
; $6238 + 8 x code
;
; PrintChar, PrintDigits and the box frame of PrintBoxed read it.
Font:
  INCBIN "res/fonts/demo.bin",$0000,512

; The cell type of each of the 256 room characters: what Rex and the objects
; test in the room grid
;
; DrawRoomCell copies CharFlags[c] into the grid for each character drawn; the
; types are part 1's.
CharFlags:
  INCBIN "res/tables/demo-char-flags.bin",$0000,256

; The 256 room characters, 8 bytes each
CharGraphics:
  INCBIN "res/chars/demo.bin",$0000,88
AnimChar11:
  ; $6690 character 11, rolled by RollCharLeft every pass (the main loop)
  INCBIN "res/chars/demo.bin",$0058,120
AnimChar26:
  ; $6708 character 26, rolled by RollCharLeft
  INCBIN "res/chars/demo.bin",$00D0,16
AnimChar28:
  ; $6718 character 28, rolled by RollCharLeft
  INCBIN "res/chars/demo.bin",$00E0,320
AnimChar68:
  ; $6858 character 68: frames from FramesChar68 (AnimateCells)
  INCBIN "res/chars/demo.bin",$0220,344
AnimChar111:
  ; $69B0 character 111: each line rotated right (RRC) by the main loop
  INCBIN "res/chars/demo.bin",$0378,128
AnimChar127:
  ; $6A30 character 127: frames from FramesChar127 (AnimateCells)
  INCBIN "res/chars/demo.bin",$03F8,128
AnimChar143:
  ; $6AB0 character 143: each line rotated left (RLC)
  INCBIN "res/chars/demo.bin",$0478,848
AnimChar249:
  ; $6E00 character 249: frames from FramesList3 (AnimateRestart)
  INCBIN "res/chars/demo.bin",$07C8,8
AnimChar250:
  ; $6E08 character 250: frames from FramesList2 (AnimateCells2)
  INCBIN "res/chars/demo.bin",$07D0,16
AnimChar252:
  ; $6E18 characters 252-255: AnimFramesA / AnimFramesB on alternate passes
  ;   (AnimateCells)
  INCBIN "res/chars/demo.bin",$07E0,32

; The attribute of each of the 256 room characters
CharAttrs:
  INCBIN "res/chars/demo.bin",$0800,256

; The 256 blocks: 3 x 3 character codes each, rows top to bottom
BlockDefs:
  INCBIN "res/blocks/demo.bin",$0000,2304

; The room maps: 7 rows of 10 block codes each (70 bytes a room); room n at
; $7838 + 70n; rooms 0-5
;
; DrawRoom reads it; TutorRooms $A2A2 plays rooms 4, 1, 0 and 2, and room 2
; leads down to room 3.
RoomMaps:
  INCBIN "res/rooms/demo-maps.bin",$0000,420

; The sprites, pre-shifted: each label is a picture set its owner draws through
; a frame list (ShiftFrames $AF0E: 8 words, one a pixel phase)
Sprites:
SpriteKind0:
  ; $79DC kind 0, the foot man (ShiftFrames)
  INCBIN "res/sprites/demo.bin",$0000,504
SpriteRexDeath:
  ; $7BD4 Rex's death (DeathAnimation)
  INCBIN "res/sprites/demo.bin",$01F8,72
SpritePoints:
  ; $7C1C the points sign a kill leaves (ShowPoints $8E4D)
  INCBIN "res/sprites/demo.bin",$0240,768
SpritePodPower:
  ; $7F1C a power pod left by an explosion (BlowUp $C49A)
  INCBIN "res/sprites/demo.bin",$0540,192
SpritePodBig:
  ; $7FDC a big power pod left by an explosion (BlowUp)
  INCBIN "res/sprites/demo.bin",$0600,192
SpritePowerPod:
  ; $809C the power pod's four frames ($809C, $80BC, $80DC, $80FC:
  ;   AnimatePod)
  INCBIN "res/sprites/demo.bin",$06C0,512
SpriteLaserA:
  ; $829C a long bullet (MoveBeam)
  INCBIN "res/sprites/demo.bin",$08C0,24
SpriteScanner:
  ; $82B4 kind 8 (scanner: ScannerTurn, ScannerReset)
  INCBIN "res/sprites/demo.bin",$08D8,432
SpriteHudIcons:
  ; $8464 the HUD's weapon and bomb icons (DrawHudIcon)
  INCBIN "res/sprites/demo.bin",$0A88,160
SpriteHudIcons2:
  ; $8504 the HUD's weapon icons, second row (DrawWeaponIcon)
  INCBIN "res/sprites/demo.bin",$0B28,64
SpriteBombPod:
  ; $8544 the bomb pod ($FD: BlowUp; kind $7D: InitKind7D)
  INCBIN "res/sprites/demo.bin",$0B68,32
SpriteBonusPod:
  ; $8564 the bonus pod ($FC: BlowUp; kind $7C: InitKind7C)
  INCBIN "res/sprites/demo.bin",$0B88,320
SpriteKind11:
  ; $86A4 kind 11 (launcher, InitKind11)
  INCBIN "res/sprites/demo.bin",$0CC8,32
SpriteKind10:
  ; $86C4 kind 10 (shooters, InitKind10)
  INCBIN "res/sprites/demo.bin",$0CE8,32
SpriteKind6:
  ; $86E4 kind 6 (InitKind6)
  INCBIN "res/sprites/demo.bin",$0D08,32
SpriteSwingGun:
  ; $8704 kind 9 (swing gun), its angles (SwingGunFrames, SwingGun)
  INCBIN "res/sprites/demo.bin",$0D28,160
SpriteLaserB:
  ; $87A4 a long bullet (MoveBeam)
  INCBIN "res/sprites/demo.bin",$0DC8,216
SpriteJumper:
  ; $887C a walker turned jumper (MaybeJumper)
  INCBIN "res/sprites/demo.bin",$0EA0,128
SpriteArrow:
  ; $88FC the tutor's arrow in room 4 (TutorArrow $8EB8)
  INCBIN "res/sprites/demo.bin",$0F20,392
