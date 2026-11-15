; --------------------------------------------------------------------------------------------------------------------
; bomb.asm: The smart bomb
;
; SPACE fires a smart bomb (Bombs $A06C, 3 at the start, more from bomb pods): SmartBomb takes one, SmartBombMark
; marks every object of the room, and SmartBombStep kills them one a pass over 16 steps ($A02F) while the screen
; flashes. A life lost fires one for free (SmartBombFree $9749 from RexDies $9BDA), so the room is empty when Rex
; comes back.
; --------------------------------------------------------------------------------------------------------------------

; A smart bomb that costs nothing (Rex's death): unless one is running, mark
; the room's objects
;
; Witness: L1 42 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-room24, p1-room30, rzx-p1- x18).
SmartBombFree:
  LD A,(SmartBombOn)
  OR A
  RET NZ
  JP SmartBombMark

; SPACE: one smart bomb from Bombs $A06C (none left, nothing), the HUD updated,
; the room's objects marked
;
; Witness: L1 15 (c1, p1-cursor, rzx-p1- x5).
SmartBomb:
  LD A,(SmartBombOn)
  OR A
  RET NZ
  LD A,(Bombs)
  DEC A
  CP $FF
  RET Z
  LD (Bombs),A
  CALL ShowBombs

; Mark every object of the room for the smart bomb; SmartBombOn $A030 = 1, 16
; steps
;
; Writes the object pointers from ObjectTable $5E66 (ObjectCount $A092 records
; of 24 bytes) into the list at $5D28.
;
; Witness: L1 50 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-room24, p1-room30, rzx-p1- x22).
SmartBombMark:
  LD A,$01
  LD (SmartBombOn),A
  LD A,$10
  LD (SmartBombSteps),A
  LD HL,$5E66
  LD (SmartBombPtr),HL
  LD HL,$5D28
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
; Every pass; returns at once while SmartBombOn $A030 is 0. Each step
; KillObject $981F on the next object and CopyAttrs $C8BF; after 16 steps the
; bomb ends.
;
; Witness: L1 16814 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-room x5, rzx-p1- x32).
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
  CALL KillObject
BombNextObject:
  LD DE,$0018             ; the next marked object
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
