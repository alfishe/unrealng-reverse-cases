; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The graphics and the level data: the font, the characters, the blocks, the room maps and the sprites
;
; The tape loads the code block at $6018 (CLEAR 24599). Its first bytes are a leftover of the authors' development
; link (DevLinkStub $6018-$607D); the menu copies the object explosion picture from $E336 over it (192 bytes,
; $6018-$60D7), so the stub never runs. Then come the tables every room is built from: the 64-character font (Font
; $60E0, characters 32-95, found at $5FE0 + 8 x code), a flag byte for each of the 256 room characters (CharFlags
; $62E0: the cell types Rex and the objects test), the 256 characters (CharGraphics $63E0, 8 bytes each), their
; attributes (CharAttrs $6BE0), the 256 blocks of 3 x 3 characters (BlockDefs $6CE0) and the rooms (RoomMaps $75E0, 7
; rows of 10 blocks, 70 bytes a room).
;
; The sprites follow from $7F72 to $9479. Each is stored pre-shifted: a frame list of 8 offsets (ShiftFrames $AE5D and
; the like, one an X & 7) picks the copy for the pixel phase, and DrawSprite $B258 ORs it into the back buffer, width
; and height from $A0B1 / $A0B2. Their owners are named at each label.
; --------------------------------------------------------------------------------------------------------------------

; Leftover: 102 bytes of the authors' development link, overwritten by the menu
; before they could run
;
; No instruction jumps here. The menu (TitleMenu $DAC0) copies ExplosionPicture
; $E336 to $6018 (192 bytes) before anything else, and the objects use $6018 as
; the explosion picture from then on (UpdateObject $BA86). Kept byte for byte
; as a documented leftover (src/res/leftovers/README.md).
DevLinkStub:
  INCBIN "res/leftovers/rex1-devlink.bin",$0000,102

; Leftover: 98 bytes after the stub (overwritten by the explosion picture up to
; $60D7); nothing reads them before
Unused607E:
  INCBIN "res/leftovers/rex1-devlink.bin",$0066,98

; The font: 64 characters, codes 32-95 (space to underscore), 8 bytes each, at
; $5FE0 + 8 x code
;
; PrintChar $A2E9, PrintDigits $A3C8, the box frame of PanelBox $CE7B and the
; DEFINE key echo (FontChar $DEF0) read it. The box frame uses six characters
; as corner and edge pieces ($6120 "(", $6130 "*", $6140 ",", $6158 "/", $61B8
; ";", $61C8 "=").
Font:
  INCBIN "res/fonts/rex1.bin",$0000,512

; The cell type of each of the 256 room characters: what Rex and the objects
; test in the room grid
;
; DrawRoomCell $C7E2 copies CharFlags[c] into the grid $E1FF for each character
; drawn. The values tested: 0 empty, 2, 4, 5, 6 solid (SolidCells $D096), $07
; the restart marker, $08 the shield recharger, $0A-$0D the weapon stations,
; $0E-$12 solid platform kinds, $12 the ladder or lift (CellsUnderRex $9F5F).
CharFlags:
  INCBIN "res/tables/rex1-char-flags.bin",$0000,256

; The 256 room characters, 8 bytes each
;
; Drawn by DrawRoomCell $C7E2 into the back buffer; the animated ones are
; rotated in place each pass by the main loop ($6438, $64B0, $64C0, $6600,
; $6758, $67D8, $6858, $6BA8, $6BB0, $6BC0).
CharGraphics:
  INCBIN "res/chars/rex1.bin",$0000,88
AnimChar11:
  ; $6438 character 11, rolled one line up by RollCharUp $A7A9 every pass
  ;   (MainAnimate)
  INCBIN "res/chars/rex1.bin",$0058,120
AnimChar26:
  ; $64B0 character 26, rolled one line down by RollCharDown $A7BA
  INCBIN "res/chars/rex1.bin",$00D0,16
AnimChar28:
  ; $64C0 character 28, rolled one line down by RollCharDown
  INCBIN "res/chars/rex1.bin",$00E0,320
AnimChar68:
  ; $6600 character 68: frames from FramesList1 $A60C (AnimateCells $A55E,
  ;   CopyFrame)
  INCBIN "res/chars/rex1.bin",$0220,344
AnimChar111:
  ; $6758 character 111: each line rotated right (RRC) by the main loop
  INCBIN "res/chars/rex1.bin",$0378,128
AnimChar127:
  ; $67D8 character 127: frames from FramesList4 $A61A (CopyFrame)
  INCBIN "res/chars/rex1.bin",$03F8,128
AnimChar143:
  ; $6858 character 143: each line rotated left (RLC)
  INCBIN "res/chars/rex1.bin",$0478,848
AnimChar249:
  ; $6BA8 character 249: frames from FramesList3 $A5F4 (AnimateRestart
  ;   $A5B7)
  INCBIN "res/chars/rex1.bin",$07C8,8
AnimChar250:
  ; $6BB0 character 250: frames from FramesList2 $A602 (AnimateCells2
  ;   $A5A7)
  INCBIN "res/chars/rex1.bin",$07D0,16
AnimChar252:
  ; $6BC0 characters 252-255: AnimFramesA $AE8D / AnimFramesB $AEAD on
  ;   alternate passes (AnimateCells)
  INCBIN "res/chars/rex1.bin",$07E0,32

; The attribute of each of the 256 room characters
CharAttrs:
  INCBIN "res/chars/rex1.bin",$0800,256

; The 256 blocks: 3 x 3 character codes each, rows top to bottom
BlockDefs:
  INCBIN "res/blocks/rex1.bin",$0000,2304

; The rooms 0-34: 7 rows of 10 block codes each (70 bytes a room); room n at
; $75E0 + 70n
;
; DrawRoom $C745 builds the room in the grid and the back buffer from here. A
; room is 30 x 21 characters.
RoomMaps:
  INCBIN "res/rooms/rex1-maps.bin",$0000,2450

; The sprites, pre-shifted: each label is a picture set its owner draws through
; a frame list
;
; $7F72 is the foot man (kind 0) and UpdateObject's default picture. The labels
; below name the other owners.
Sprites:
  INCBIN "res/sprites/rex1.bin",$0000,192
SpriteStomper:
  ; $8032 kind 1 (stomper)
  INCBIN "res/sprites/rex1.bin",$00C0,192
SpriteRex:
  ; $80F2 Rex walking (DrawRex $96A7)
  INCBIN "res/sprites/rex1.bin",$0180,120
SpriteRexDeath:
  ; $816A Rex's death (DeathAnimation $9AC5)
  INCBIN "res/sprites/rex1.bin",$01F8,72
SpritePoints:
  ; $81B2 the points sign a kill leaves (ShowPoints $97FD)
  INCBIN "res/sprites/rex1.bin",$0240,576
SpriteKind5:
  ; $83F2 kind 5
  INCBIN "res/sprites/rex1.bin",$0480,192
SpriteKind3:
  ; $84B2 kind 3
  INCBIN "res/sprites/rex1.bin",$0540,192
SpriteKind4:
  ; $8572 kind 4
  INCBIN "res/sprites/rex1.bin",$0600,192
SpriteHitFlash:
  ; $8632 an object hit (HitObject $D3C2, HitObjectHard $D41F)
  INCBIN "res/sprites/rex1.bin",$06C0,96
SpriteRamTurn:
  ; $8692 the ramming pod turning (RamTurn $BD44)
  INCBIN "res/sprites/rex1.bin",$0720,96
SpritePodA:
  ; $86F2 a pod left by an explosion ($BDED)
  INCBIN "res/sprites/rex1.bin",$0780,192
SpritePodB:
  ; $87B2 a pod left by an explosion ($BE18)
  INCBIN "res/sprites/rex1.bin",$0840,192
SpritePowerPod:
  ; $8872 the power pod's four frames ($8872, $8892, $88B2, $88D2:
  ;   AnimatePod $BED3)
  INCBIN "res/sprites/rex1.bin",$0900,128
SpriteShield:
  ; $88F2 the shield bubble round Rex, 4 x 21, through ShiftFrames2
  ;   (DrawShield $9726)
  INCBIN "res/sprites/rex1.bin",$0980,336
SpriteLaserA:
  ; $8A42 a long bullet ($B849)
  INCBIN "res/sprites/rex1.bin",$0AD0,24
SpriteScanner:
  ; $8A5A kind 8 (scanner) ($C3B0, $C3D2)
  INCBIN "res/sprites/rex1.bin",$0AE8,256
SpriteScanner2:
  ; $8B5A kind 8's start picture (InitKind8 $CCBF)
  INCBIN "res/sprites/rex1.bin",$0BE8,176
SpriteHudIcons:
  ; $8C0A the HUD's weapon and bomb icons (DrawHudIcons $A1E2)
  INCBIN "res/sprites/rex1.bin",$0C98,160
SpriteHudIcons2:
  ; $8CAA the HUD's weapon icons, second row (DrawWeaponIcon $A21F)
  INCBIN "res/sprites/rex1.bin",$0D38,64
SpriteBonusPod:
  ; $8CEA the bonus pod (kind $7D, $BE39)
  INCBIN "res/sprites/rex1.bin",$0D78,32
SpriteBonusPod2:
  ; $8D0A ($BE43)
  INCBIN "res/sprites/rex1.bin",$0D98,128
SpriteKind12:
  ; $8D8A kind 12 (ramming pod)
  INCBIN "res/sprites/rex1.bin",$0E18,192
SpriteKind11:
  ; $8E4A kind 11 (launcher)
  INCBIN "res/sprites/rex1.bin",$0ED8,32
SpriteKind10:
  ; $8E6A kind 10 (shooters)
  INCBIN "res/sprites/rex1.bin",$0EF8,32
SpriteKind6:
  ; $8E8A kind 6
  INCBIN "res/sprites/rex1.bin",$0F18,32
SpriteSwingGun:
  ; $8EAA kind 9 (swing gun), its angles (SwingGunFrames $BECB)
  INCBIN "res/sprites/rex1.bin",$0F38,160
SpriteLaserB:
  ; $8F4A a long bullet ($B83F)
  INCBIN "res/sprites/rex1.bin",$0FD8,24
SpriteRexJump:
  ; $8F62 Rex jumping or falling, off a lift (DrawRex $96C4)
  INCBIN "res/sprites/rex1.bin",$0FF0,192
SpriteKind15:
  ; $9022 kind 15 (blob)
  INCBIN "res/sprites/rex1.bin",$10B0,128
SpriteKind13:
  ; $90A2 kind 13 (mine layer)
  INCBIN "res/sprites/rex1.bin",$1130,144
SpriteKind14:
  ; $9132 kind 14 (mine)
  INCBIN "res/sprites/rex1.bin",$11C0,128
SpriteJumper:
  ; $91B2 the jumping walkers ($C5AB)
  INCBIN "res/sprites/rex1.bin",$1240,32
SpriteKind16:
  ; $91D2 kind 16 (the big gun)
  INCBIN "res/sprites/rex1.bin",$1260,288
SpriteHuman:
  ; $92F2 a human killed ($98C1)
  INCBIN "res/sprites/rex1.bin",$1380,392
