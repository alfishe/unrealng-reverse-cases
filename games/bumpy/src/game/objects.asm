; --------------------------------------------------------------------------------------------------------------------
; objects.asm: The objects: hammers, keys, water, bottles and prizes; the score and the exit
;
; An object lies in a cell (ObjectCells $AA47, kinds 0-40). The ball takes it when it lands there: kinds 1-4 are tools
; and the extra life, 5 and up are prizes worth 15 points each; the last prize opens the exit.
;
; The ink of each object kind, read when the level is built.
; --------------------------------------------------------------------------------------------------------------------

  ORG $B958

; Take the object in the ball's cell, if any
;
; Kind = $AB1D (ReadCell $BB32). 0: nothing. Else erases the object's sprite
; (ObjectSprites $6CB0 + 56 × kind, 4 bytes × 14 rows, XOR at the cell's screen
; address $AB2D - $9E, DrawSpriteXorInk $E3E5 with colour 7), clears
; ObjectCells $AA47[cell], and for kinds 1-4 jumps through ObjectHandlers
; $BA3D. Kinds 5 and up are prizes: the pick-up sound $F3F6 (skipped once after
; a long sound, $ABA7 = 4), then AddScore $BA47 with 15. Called by the landing
; handlers ($C811, $CA46, $CC89, $CDF9, $CEC6). Witness: 936 objects taken in
; the recordings, 625 prizes.
;
; Witness: L1 8156 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
TakeObject:
  AND A
  LD A,(CellObject)
  LD HL,BallPictures2+$0248
  CP $00
  RET Z
  LD B,A
  LD DE,$0038
TakeObjectSprite:
  ADD HL,DE
  DJNZ TakeObjectSprite
  EX DE,HL
  LD HL,(CellScrAddr)
  LD BC,$FF62
  ADD HL,BC
  LD A,$04
  LD (SpriteWidth),A
  LD B,$0E
  LD C,$07
  CALL XorSpriteColoured
  LD A,(BallCell)
  LD D,$00
  LD E,A
  LD HL,CellObjects
  ADD HL,DE
  LD (HL),$00
  AND A
  LD A,(CellObject)
  CP $05
  JR NC,TakePrize
  AND A
  RLA
  LD E,A
  LD D,$00
  LD IX,ObjectHandlers
  ADD IX,DE
  LD E,(IX+$00)
  LD D,(IX+$01)
  PUSH DE
  POP IX
  JP (IX)
TakePrize:
  LD A,(ObjectFlag)
  CP $04
  JR Z,TakePrizeQuiet
  CALL SfxPickup
TakePrizeScore:
  LD BC,$000F
  JP AddScore
TakePrizeQuiet:
  LD A,$00
  LD (ObjectFlag),A
  JR TakePrizeScore

; ObjectHandlers[0]: RET (kind 0 is no object, filtered out before)
;
; Never run: TakeObject returns on kind 0 before the jump.
;
; Witness: L1 0 ().
TakeNothing:
  RET

; Kind 2, a key: Keys + 1 (at most 99) and the HUD
;
; The pick-up sound $F3F6 unless $ABA7 = 4 (then $ABA7 = 0), Keys $AAFE + 1
; unless 99, then JP $E5D3 (print the keys). Witness: 183 keys.
;
; Witness: L1 204 (c1, menu, l x9, rzx x60).
TakeKey:
  LD A,(ObjectFlag)
  CP $04
  JR Z,TakeKeyQuiet
  CALL SfxPickup
TakeKeyCount:
  LD A,(Keys)
  CP $63
  RET Z
  AND A
  INC A
  LD (Keys),A
  JP KeysToHud
TakeKeyQuiet:
  LD A,$00
  LD (ObjectFlag),A
  JR TakeKeyCount

; Kind 3, a water drop: Water + 1 (at most 99) and the HUD
;
; As TakeKey with Water $AAFD and $E5C0. Witness: 54 drops.
;
; Witness: L1 66 (c1, gameover, menu, twoname, l x5, rzx x29).
TakeWater:
  LD A,(ObjectFlag)
  CP $04
  JR Z,TakeWaterQuiet
  CALL SfxPickup
TakeWaterCount:
  LD A,(Water)
  CP $63
  RET Z
  AND A
  INC A
  LD (Water),A
  JP WaterToHud
TakeWaterQuiet:
  LD A,$00
  LD (ObjectFlag),A
  JR TakeWaterCount

; Kind 1, a hammer: Hammers + 1 (at most 99) and the HUD
;
; As TakeKey with Hammers $AAFF and $E5E6. Witness: 58 hammers.
;
; Witness: L1 63 (l x5, rzx x38).
TakeHammer:
  LD A,(ObjectFlag)
  CP $04
  JR Z,TakeHammerQuiet
  CALL SfxPickup
TakeHammerCount:
  LD A,(Hammers)
  CP $63
  RET Z
  AND A
  INC A
  LD (Hammers),A
  JP HammersToHud
TakeHammerQuiet:
  LD A,$00
  LD (ObjectFlag),A
  JR TakeHammerCount

; Kind 4, the bottle: an extra life
;
; $ABA7 = 4 (the next pick-up is silent), the sound $F40D, FirmwareStub $B747
; with B = C = 26 (a dropped CPC border flash), $AB17 = 1 (BottleFlashOff
; undoes it next frame), lives $AB01 + 1 unless 99, then JP $E5AD (print the
; lives). The only way to gain a life: 15 bottles in the RZX and one in the
; menu recording's demo, each one life.
;
; Witness: L1 20 (menu, l10, l36, l45, l68, rzx x15).
TakeBottle:
  LD A,$04
  LD (ObjectFlag),A
  CALL SfxExtraLife
  LD B,$1A
  LD C,B
  CALL FirmwareStub
  LD A,$01
  LD (BorderFlash),A
  LD A,(Lives)
  CP $63
  JR Z,TakeBottleStore
  INC A
TakeBottleStore:
  LD (Lives),A
  JP LivesToHud

; The handlers of object kinds 0-4, jumped to by TakeObject
;
; TakeNothing $B9BE, TakeHammer $B9FD, TakeKey $B9BF, TakeWater $B9DE,
; TakeBottle $BA1C.
ObjectHandlers:
  DEFW TakeNothing,TakeHammer,TakeKey,TakeWater,TakeBottle

; Add BC to the score, print it, and count a prize off
;
; Score $AAFB += BC, PrintScore $E5A1, PrizesLeft $AA45 - 1 and OpenExit $BCB9
; when it reaches 0. Only prizes come here (BC = 15).
;
; Witness: L1 690 (c1, menu, l x12, rzx00-rzx44, rzx46-rzx99).
AddScore:
  AND A
  LD HL,(Score)
  ADD HL,BC
  LD (Score),HL
  CALL ScoreToHud
  AND A
  LD A,(PrizesLeft)
  DEC A
  LD (PrizesLeft),A
  CP $00
  CALL Z,OpenExit
  RET

; The frame after a bottle: undo the border flash
;
; When $AB17 is set: clears it and calls FirmwareStub $B747 with B = C = 0 (a
; CPC border back to black; a RET here). Called by MainLoop ($ACE7) every
; frame.
;
; Witness: L1 92279 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
BottleFlashOff:
  LD A,(BorderFlash)
  CP $00
  RET Z
  LD A,$00
  LD (BorderFlash),A
  LD B,A
  LD C,B
  CALL FirmwareStub
  RET

  ORG $BCB9

; The last prize is taken: the exit cell becomes platform $0B and is drawn open
;
; The exit cell is $AA46 (from the level). PlatformCells[$AA46] = $0B; $AB2D =
; its screen address; the blank $6708 is stored at +$27B0 (8 bytes × 10 rows),
; the sprite $80CC at +$2FB0 and +$2FB7 (1 byte × 9 rows each, the two posts),
; then the exit animation is armed: $AA10 = the address + 1, $AA12 = 1
; (AnimateExit). Called by AddScore $BA47. Witness: 92 exits opened in the
; recordings.
;
; Witness: L1 104 (menu, l x12, rzx x91).
OpenExit:
  AND A
  LD A,(ExitCell)
  LD D,$00
  LD E,A
  LD HL,CellPlatforms
  ADD HL,DE
  LD (HL),$0B
  AND A
  LD A,(ExitCell)
  RLA
  LD D,$00
  LD E,A
  LD IX,CellAddresses
  ADD IX,DE
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD (CellScrAddr),HL
  LD DE,$27B0
  ADD HL,DE
  LD DE,BlankPicture
  EX DE,HL
  LD A,$08
  LD (SpriteWidth),A
  LD B,$0A
  CALL DrawSprite
  LD HL,(CellScrAddr)
  LD BC,$2FB0
  ADD HL,BC
  LD DE,ExitMark
  EX DE,HL
  LD A,$01
  LD (SpriteWidth),A
  LD B,$09
  CALL DrawSprite
  LD HL,(CellScrAddr)
  LD BC,$2FB7
  ADD HL,BC
  LD DE,ExitMark
  EX DE,HL
  LD B,$09
  CALL DrawSprite
  LD HL,(CellScrAddr)
  INC HL
  LD (ExitAnimAddr),HL
  LD A,$01
  LD (ExitOpen),A
  RET

; Every 2 frames, the next frame of the open exit
;
; When $AA12 is set: $AA0E counts frames, at 2 NextExitFrame $BD5C steps $AA0F
; (1-4) and the frame ExitFrames $C522[frame - 1] (6 bytes × 5 rows, colour
; $5E) is stored at $AA10. Called by MainLoop ($ACE1) and the level end
; ($B32B).
;
; Witness: L1 93188 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
AnimateExit:
  AND A
  LD A,(ExitOpen)
  CP $00
  RET Z
  LD A,(ExitTick)
  INC A
  LD (ExitTick),A
  CP $02
  RET NZ
  AND A
  CALL NextExitFrame
  AND A
  LD A,(ExitFrame)
  DEC A
  RLA
  LD D,$00
  LD E,A
  LD IX,FireFrames
  ADD IX,DE
  LD H,(IX+$01)
  LD L,(IX+$00)
  LD DE,(ExitAnimAddr)
  LD A,$06
  LD (SpriteWidth),A
  LD B,$05
  LD C,$5E
  CALL DrawSpriteColoured
  RET

; $AA0E = 0; the exit frame $AA0F steps 1, 2, 3, 4, 1 ...
;
; Witness: L1 6672 (menu, l x12, rzx x91).
NextExitFrame:
  LD A,$00
  LD (ExitTick),A
  LD A,(ExitFrame)
  CP $04
  JR Z,NextExitFrameWrap
  INC A
  LD (ExitFrame),A
  RET
NextExitFrameWrap:
  LD A,$01
  LD (ExitFrame),A
  RET

  ORG $C6F6

; The Spectrum attribute each object kind 0-40 is drawn with
;
; BuildLevelObject $CFF4 draws object kind K (sprite $6CB0 + 56 K, 14 lines of
; 4 bytes) with ink ObjectInks[K] (it patches the displacement of LD C,(IX+d)
; at $D01B). Kind 0 is no object and is never read. The values are attributes:
; $45 bright cyan, $46 bright yellow, $44 bright green, $42 bright red, $43
; bright magenta, $06 yellow and so on.
ObjectInks:
  INCBIN "res/tables/object-inks.bin",$0000,41
