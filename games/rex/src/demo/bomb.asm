; --------------------------------------------------------------------------------------------------------------------
; bomb.asm: The smart bomb; the kill and its points
; --------------------------------------------------------------------------------------------------------------------

; A smart bomb that costs nothing (Rex's death): unless one is running, mark
; the room's objects
;
; As REX 1's SmartBombFree $9749 (src/game/bomb.asm).
;
; Witness: L1 6 (d1, demo-cycle).
SmartBombFree:
  LD A,(SmartBombOn)
  OR A
  RET NZ
  JP SmartBombMark

; SPACE: one smart bomb from Bombs $5EF5 (none left, nothing), the HUD updated,
; the room's objects marked
;
; As REX 1's SmartBomb $9751 (src/game/bomb.asm).
;
; Witness: L1 4 (d1, demo-cycle).
SmartBomb:
  LD A,(SmartBombOn)
  OR A
  RET NZ
DrainRank:
  LD A,(Bombs)
  DEC A
  CP $FF
  RET Z
  LD (Bombs),A
  CALL ShowBombs

; Mark every object of the room for the smart bomb; SmartBombOn $5EB9 = 1, 16
; steps
;
; As REX 1's SmartBombMark $9763 (src/game/bomb.asm).
;
; Witness: L1 10 (d1, demo-cycle).
SmartBombMark:
  LD A,$01
  LD (SmartBombOn),A
  LD A,$10
  LD (SmartBombSteps),A
  LD HL,ObjectTable
  LD (SmartBombPtr),HL
  LD HL,$5D5D
  LD B,$14
MarkLoop:
  LD A,(HL)               ; the next object
  OR A
  JP Z,MarkNext
  LD (HL),$02
MarkNext:
  LD DE,$000F             ; the next record
  ADD HL,DE
  DJNZ MarkLoop
  RET

; One step of a running smart bomb: kill the next marked object, flash the
; screen
;
; As REX 1's SmartBombStep $9786 (src/game/bomb.asm).
;
; Witness: L1 6752 (d1, demo-cycle).
SmartBombStep:
  LD A,(SmartBombOn)
  OR A
  RET Z
  LD IX,(SmartBombPtr)
  LD A,(IX+$09)
  CP $FE
  JP Z,BombNextObject
  CP $FD
  JP Z,BombNextObject
  CP $FC
  JP Z,BombNextObject
  CP $90
  JP Z,BombNextObject
  CALL ShowPoints
BombNextObject:
  LD DE,$0017             ; the next marked object
  ADD IX,DE
  LD (SmartBombPtr),IX
  LD A,(SmartBombSteps)
  DEC A
  LD (SmartBombSteps),A
  OR A
  RET NZ
  XOR A
  LD (SmartBombOn),A
  CALL CopyAttrs
  RET

; The sound off, a count of 60000, the sound on: WeaponPanel's fixed wait (part
; 1 waits for fire)
;
; Witness: L1 7 (d1, demo-cycle).
WaitQuiet:
  CALL SoundSilence
  LD DE,60000
WaitFireCount:
  DEC DE                  ; the 50000-poll count
  LD A,D
  OR E
  JP NZ,WaitFireCount
  CALL SoundReset
  RET

; Leftover: REX 1's points sign set-up: picture SpritePoints, IX+$0D = 8, 3 x
; 24, kind $FF, at rest; no instruction reaches it
;
; LD HL,SpritePoints: the picture IX+4/5, IX+$0D = 8, the width IX+$0E = 3
; bytes, IX+$0F = 24 lines, kind IX+9 = $FF, the speed IX+2/3 = 0, RET. DEMO's
; ShowPoints jumps to FindSlot after setting the picture and never reaches
; these bytes (known only from the code).
;
; Witness: L1 0 ().
PointsLeftover:
  LD HL,SpritePoints
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0D),$08
  LD (IX+$0F),$18
  LD (IX+$0E),$03
  LD (IX+$09),$FF
  LD (IX+$02),$00
  LD (IX+$03),$00
  RET

; Turn the object at IX (in the play area) into the points sign SpritePoints:
; the kind's score (KillScores $8EA8), the explosion sound, kind $FF; the HUD
; kill flash reset
;
; ShowPoints is DEMO's KillObject: no combo, no people count.
;
; Witness: L1 155 (d1, demo-cycle).
ShowPoints:
  LD A,(IX+$01)
  CP $B0
  RET NC
  CP $10
  RET C
PointsPicture:
  LD HL,SpritePoints      ; the points sign's picture, size and kind
  LD (IX+$04),L
  LD (IX+$05),H
  LD (IX+$0D),$08
  LD (IX+$0F),$18
  LD (IX+$0E),$03
  LD A,(IX+$09)
  AND $7F
  LD E,A
  LD D,$00
  LD HL,KillScores
  ADD HL,DE
  LD E,(HL)
  LD D,$00
  LD A,E
  OR A
  CALL NZ,AddScore
  LD DE,SfxExplosion
  CALL StartSfx
  LD (IX+$09),$FF
  LD (IX+$02),$00
  LD A,(IX+$01)
  SUB $08
  AND $F8
  LD (IX+$01),A
  LD (IX+$03),$00
  LD HL,ObjectBufferOrigin
  LD (KillFlashPtr),HL
  LD HL,$0000
  LD (ComboTimer),HL
  RET

; The score of each kind 0-15 (hundreds; ShowPoints)
KillScores:
  INCBIN "res/tables/demo-kill-scores.bin",$0000,16

; Room 4 only, tutor frames 60-599: the arrow SpriteArrow $88FC drawn on its
; path ArrowPath $8F32, held at random; at frame 570 the path changes to
; ArrowPath2 (TutorArrowSwitch)
;
; Witness: L1 6752 (d1, demo-cycle).
TutorArrow:
  LD A,(Room)
  CP $04
  RET NZ
  LD DE,$003C
  LD HL,(TutorFrame)
  AND A
  SBC HL,DE
  RET C
  LD HL,(TutorFrame)
  LD DE,$0258
  AND A
  SBC HL,DE
  RET NC
  LD DE,$023A
  LD HL,(TutorFrame)
  AND A
  SBC HL,DE
  CALL Z,TutorArrowSwitch
  LD HL,(ArrowPathPtr)
  LD A,(HL)
  ADD A,$08
  LD (SpriteY),A
  LD A,(ArrowMoving)
  OR A
  JP Z,l_8EF6
  CALL Random2
  CP $C8
  JP C,l_8EF7
l_8EF6:
  INC HL
l_8EF7:
  LD A,(HL)
  CP $FF
  JP NZ,l_8F05
  LD HL,ArrowPath+$001E
  LD A,$01
  LD (ArrowMoving),A
l_8F05:
  LD (ArrowPathPtr),HL
  LD A,$10
  LD (SpriteX),A
  LD A,$0C
  LD (SpriteWidth),A
  LD A,$20
  LD (SpriteHeight),A
  LD A,$FF
  LD (SpriteMirror),A
  LD HL,SpriteArrow
  LD (SpritePicture),HL
  XOR A
  CALL DrawSprite
  RET

; The arrow's second path ArrowPath2 $8F5A, moving again
;
; Witness: L1 3 (d1, demo-cycle).
TutorArrowSwitch:
  LD HL,ArrowPath+$0028
  LD (ArrowPathPtr),HL
  XOR A
  LD (ArrowMoving),A
  RET

; The arrow's Y positions (TutorArrow): $8F32 its rest ($5EBF from NewGame),
; $8F50 the loop, $8F5A ArrowPath2; $FF ends
ArrowPath:
  DEFB $A6,$A5,$A4,$A3,$A2,$A1,$A0,$9F,$9E,$9D,$9C,$9B,$9A,$99,$98,$97
  DEFB $96,$95,$94,$93,$92,$91,$90,$8F,$8E,$8D,$8C,$8B,$8A,$89,$88,$89
  DEFB $8A,$8A,$8B,$8B,$8A,$89,$88,$FF,$89,$8A,$8B,$8C,$8D,$8E,$8F,$90
  DEFB $91,$92,$93,$94,$95,$96,$97,$98,$99,$9A,$9B,$9C,$9D,$9E,$9F,$A0
  DEFB $A1,$A2,$A3,$A4,$A5,$A6,$FF
