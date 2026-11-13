; --------------------------------------------------------------------------------------------------------------------
; header.asm: The level header, the level number and the sprite frame map
;
; Six bytes at $C200 tell the game where this level's tables are; the level number says which level the block is
; (LoadLevel reads blocks off side B until it matches); the frame map turns the animation scripts' frame numbers into
; sprite numbers.
; --------------------------------------------------------------------------------------------------------------------

; The addresses of this level's kind table, section table and maps
;
; Three words. +0 KindTable (read by SpawnMapObject $9D6C), +2 SectionTable
; (SetupSection $8A6D, CheckSectionExit's setup, ResetSectionObjects $8379), +4
; Maps, the base the section table's map offsets are added to (SetupSection,
; and DecryptMaps $894E: the 768 bytes from Maps + $600 come enciphered on side
; B).
LevelHeader:
  DEFW KindTable
  DEFW SectionTable       ; +2: the section table
  DEFW Maps               ; +4: the maps' base

; JP FatGuyStart: the Fat Guy's setup, from SetupSection
;
; Called by SetupSection ($8AF8) in place of ScanMapObjects when LevelHookOn is
; set: the section set up after the exit into section 7, and again after each
; of Rick's deaths there.
;
; Witness: L1 2 (rzx-l5-20000-poke).
LevelHookA:
  JP FatGuyStart

; JP FatGuyUpdate: a pass of the Fat Guy, from UpdateObjects
;
; Called by UpdateObjects ($8664) every pass while LevelHookOn is set, in place
; of the trap and enemy updates (Rick, his bullet and his detonator are still
; updated after it).
;
; Witness: L1 524 (rzx-l5-20000-poke, rzx-l5-22000-poke).
LevelHookB:
  JP FatGuyUpdate

; The level this block holds, 1-5
;
; LevelStart $7CC5 compares it with Level $7EF1: equal, the level is in memory;
; otherwise LoadLevel $840C reads the blocks of side B until this byte says the
; wanted level. ResetGame $7CAD reads it too.
LevelNumber:
  DEFB $05
  DEFB $00                ; 0 in every level: the place of frame 0
                          ; (SpriteFrameMap - 1 + frame; scripts number frames
                          ; from 1)

; A sprite number per animation frame 1-95: bit 7 mirrored, $7F none
;
; AnimateTrap $A608 reads the byte at SpriteFrameMap - 1 + frame for a frame of
; a trap's animation script: bits 0-6 the sprite (Sprites + 128n), bit 7 drawn
; mirrored (record +6 bit 7), $7F no sprite (the record's sprite word 0).
; Frames past the level's last (86-89 used) are 0. Frames 1-12 are sprites
; 1-12, 13-25 sprites 0-12 mirrored (Rick's), then the level's own sprites,
; several mirrored; frames 1-60 are the same in all five levels.
SpriteFrameMap:
  INCBIN "res/level/frame-map.bin",$0000,95

; The level's sprites, 128 bytes each, up to the maps
;
; Sprite n at Sprites + 128n (63 to 68 sprites: as far as the maps). Byte 0 a
; line offset added to the drawing row, byte 1 the number of rows (at most 21),
; then 21 rows of 6 bytes: data 2, data 1, data 0, mask 0, mask 2, mask 1 (data
; 0 the left byte; ComposeSprite $7329 pops them as HL, BC, DE). 24 pixels
; wide, 21 high; the mask is ANDed, then the data ORed; mirrored sprites go
; through MirrorTable $6500.
;
; Sprites 0-26 are the same bytes in every level (Rick, his shots, the blast,
; the ammunition and detonator boxes); 27 on are the level's own.
Sprites:
  INCBIN "res/level/sprites.bin",$0000,8576
