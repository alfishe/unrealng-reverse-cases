; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The development link, the graphics and the level data: the font, the characters, the blocks, the room maps and the sprites
;
; The tape loads part 2's code block at $61A8, 400 bytes above part 1's. Its first bytes are the authors' development
; link, here complete and never overwritten: DevLink $61A8 talks to a host over ports $1F, $3F, $5F, $7F and $7FFD
; (commands $B4-$BA: poke a block, send a block, page $7FFD, set a breakpoint, return), with the machine's state saved
; at $62F8. No instruction of the game reaches it. Then come the same tables as part 1, 550 bytes higher ($226): the
; font (Font $6306, characters 32-95, found at $6206 + 8 x code), the cell type, picture and attribute of the 256 room
; characters (CharFlags $6506, CharGraphics $6606, CharAttrs $6E06), the 256 blocks of 3 x 3 characters (BlockDefs
; $6F06), the room maps (RoomMaps $7806, 70 bytes a room; rooms 0-25 are used, RoomExits $B1A7) and the sprites
; ($8198-$946F).
;
; The sprites are stored pre-shifted as in part 1 (a frame list of 8 offsets picks the copy for X & 7; DrawSprite
; $B296 ORs it into the back buffer). Part 2's enemies are new: kinds 1-5 and 9 have their own pictures and behaviours
; (ObjectBehaviour $BD27); their names are not in the game (part 2 has no roll call), so the labels name them by kind.
; --------------------------------------------------------------------------------------------------------------------

; Leftover: the development link's code: pages the link in, saves every
; register, then serves the host's commands until a return
;
; OUT to $7F, $3F, $5F, $1F (DevLinkPut) and $7FFD; IN from $3F and $1F;
; DevLinkGet $62C3 and DevLinkPut $62D3 move one byte with a handshake on port
; $3F, data on $1F. Commands: $B4 pokes a block (address, length, bytes); $B5
; sets the return address ($62BE) and $CD00 ($62BC); $B6 sends a block
; (address, length; $624E); $B7 pages $7FFD ($6234); $B8 sends the 26 saved
; bytes at $62E4; $B9 receives 26 bytes there; $BA sets $62BC and $62BE from
; the host. $B5/$BA end by restoring the registers and calling DebugHook $D6C6.
; No instruction of the game reaches $61A8 (known only from the code; z80dasm
; of the bytes); the kit keeps it as bytes because recording c2 reads these
; bytes once. Kept as a documented leftover (src/res/leftovers/README.md).
DevLink:
  INCBIN "res/leftovers/rex2-devlink.bin",$0000,283
DevLinkGet:
  ; $62C3 code: E = a byte from the host (port $1F) after the handshake on
  ;   port $3F
  INCBIN "res/leftovers/rex2-devlink.bin",$011B,16
DevLinkPut:
  ; $62D3 code: a byte to the host (port $1F), then the handshake on port
  ;   $3F
  INCBIN "res/leftovers/rex2-devlink.bin",$012B,15

; The link's state: a work word, the 26 bytes it sends ($62E4), the saved HL,
; return address and SP ($62F8, $62FA, $62FC); tape garbage, never written in
; play
DevLinkState:
  INCBIN "res/leftovers/rex2-devlink.bin",$013A,28

; Eight zero bytes before the font (its codes 24-31 would be here); nothing
; reads them
Unused62FE:
  INCBIN "res/leftovers/rex2-devlink.bin",$0156,8

; The font: 64 characters, codes 32-95 (space to underscore), 8 bytes each, at
; $6206 + 8 x code
;
; PrintChar, PrintDigits, the box frame of PrintBoxed ($6346, $6356, $6366,
; $637E, $63DE, $63EE) and the menu's FontChar $DFB1 read it.
Font:
  INCBIN "res/fonts/rex2.bin",$0000,512

; The cell type of each of the 256 room characters: what Rex and the objects
; test in the room grid
;
; DrawRoomCell copies CharFlags[c] into the grid for each character drawn. As
; in part 1, plus part 2's types: 3 kills Rex when he walks, jumps or falls
; into it (RexWalkDeadly, RexJumpDeadly, RexFall) and a falling object
; (ObjectFall $C721), 4 is the big squidgy thing (BossHit $B743), $15 and $16
; make walkers dissolve (MaybeDissolve $C5B4, CellDissolve $C5BA).
CharFlags:
  INCBIN "res/tables/rex2-char-flags.bin",$0000,256

; The 256 room characters, 8 bytes each
CharGraphics:
  INCBIN "res/chars/rex2.bin",$0000,584
AnimChar73:
  ; $684E character 73, the restart marker: frames from FramesList3 $A77D
  ;   (AnimateRestart $A740)
  INCBIN "res/chars/rex2.bin",$0248,1416
AnimChar250:
  ; $6DD6 characters 250-251: frames from FramesList2 $A789 (AnimateCells2
  ;   $A730)
  INCBIN "res/chars/rex2.bin",$07D0,16
AnimChar252:
  ; $6DE6 characters 252-255: AnimFramesA $AF82 / AnimFramesB $AFA2 on
  ;   alternate passes (AnimateCells $A706)
  INCBIN "res/chars/rex2.bin",$07E0,32

; The attribute of each of the 256 room characters
CharAttrs:
  INCBIN "res/chars/rex2.bin",$0800,256

; The 256 blocks: 3 x 3 character codes each, rows top to bottom
BlockDefs:
  INCBIN "res/blocks/rex2.bin",$0000,2304

; The room maps: 7 rows of 10 block codes each (70 bytes a room); room n at
; $7806 + 70n; 35 slots, rooms 0-25 used
;
; The slots 26-34 ($8040-$8197, 630 bytes) are a leftover: no exit leads to
; them (RoomExits holds 26 rooms) and they are REX 1's rooms 26-34 with 44-69
; of each room's 70 codes the same (work/stage2/NOTES.md); drawn with part 2's
; blocks they look like part 1's late rooms (tools/room_maps.py).
RoomMaps:
  INCBIN "res/rooms/rex2-maps.bin",$0000,2450

; The sprites, pre-shifted: each label is a picture set its owner draws through
; a frame list
;
; $8198 is kind 0's picture (a walker, InitKind0 $CC05) and UpdateObject's
; default.
Sprites:
  INCBIN "res/sprites/rex2.bin",$0000,192
SpriteHitFlash:
  ; $8258 an object hit (HitObject, HitObjectHard)
  INCBIN "res/sprites/rex2.bin",$00C0,96
SpriteRamTurn:
  ; $82B8 the hit foot man turning (RamTurn $C032)
  INCBIN "res/sprites/rex2.bin",$0120,96
SpriteKind6:
  ; $8318 kind 6 and the hop (InitKind6 $CC18, StartHop $C5BE)
  INCBIN "res/sprites/rex2.bin",$0180,32
SpriteJumper:
  ; $8338 a walker turned jumper (MakeJumper $C60D)
  INCBIN "res/sprites/rex2.bin",$01A0,32
SpriteRex:
  ; $8358 Rex walking (DrawRex)
  INCBIN "res/sprites/rex2.bin",$01C0,192
SpriteRexJump:
  ; $8418 Rex jumping or falling, off a lift (DrawRex)
  INCBIN "res/sprites/rex2.bin",$0280,120
SpriteRexDeath:
  ; $8490 Rex's death; also the big squidgy thing's explosion pieces
  ;   (BossExplodes $99E3)
  INCBIN "res/sprites/rex2.bin",$02F8,72
SpritePoints:
  ; $84D8 the points sign a kill leaves (KillObject $9807)
  INCBIN "res/sprites/rex2.bin",$0340,576
SpritePodA:
  ; $8718 a pod left by an explosion (BlowUp)
  INCBIN "res/sprites/rex2.bin",$0580,192
SpritePodB:
  ; $87D8 a pod left by an explosion (BlowUp)
  INCBIN "res/sprites/rex2.bin",$0640,192
SpritePowerPod:
  ; $8898 the power pod's four frames ($8898, $88B8, $88D8, $88F8:
  ;   AnimatePod $C1CB)
  INCBIN "res/sprites/rex2.bin",$0700,128
SpriteShield:
  ; $8918 the shield bubble round Rex, 4 x 21 (DrawShield)
  INCBIN "res/sprites/rex2.bin",$0780,424
SpriteHudIcons:
  ; $8AC0 the HUD's weapon and bomb icons
  INCBIN "res/sprites/rex2.bin",$0928,160
SpriteHudIcons2:
  ; $8B60 the HUD's weapon icons, second row
  INCBIN "res/sprites/rex2.bin",$09C8,64
SpriteBonusPod:
  ; $8BA0 the bonus pod (BlowUp)
  INCBIN "res/sprites/rex2.bin",$0A08,32
SpriteBonusPod2:
  ; $8BC0 the bonus pod (BlowUp, InitBonusPod $CCBF)
  INCBIN "res/sprites/rex2.bin",$0A28,32
SpriteKind3:
  ; $8BE0 kind 3 (InitKind3 $CC53)
  INCBIN "res/sprites/rex2.bin",$0A48,320
SpriteKind2:
  ; $8D20 kind 2 (InitKind2 $CC75)
  INCBIN "res/sprites/rex2.bin",$0B88,256
SpriteKind5:
  ; $8E20 kind 5 (InitKind5 $CCF3)
  INCBIN "res/sprites/rex2.bin",$0C88,224
SpriteKind1:
  ; $8F00 kind 1 (InitKind1 $CC40)
  INCBIN "res/sprites/rex2.bin",$0D68,192
SpriteKind4:
  ; $8FC0 kind 4 (InitKind4 $CC9D)
  INCBIN "res/sprites/rex2.bin",$0E28,128
SpriteKind9:
  ; $9040 kind 9 (InitKind9 $CCD1)
  INCBIN "res/sprites/rex2.bin",$0EA8,192
SpriteKind14:
  ; $9100 kind 14, the mine (InitKind14 $CD15)
  INCBIN "res/sprites/rex2.bin",$0F68,128
ExplosionPicture:
  ; $9180 an exploding object's picture (UpdateObject $BC50); part 1 copied
  ;   its own to $6018
  INCBIN "res/sprites/rex2.bin",$0FE8,752
