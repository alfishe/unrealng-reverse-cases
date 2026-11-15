; --------------------------------------------------------------------------------------------------------------------
; bomb.asm: The smart bomb
; --------------------------------------------------------------------------------------------------------------------

; A smart bomb that costs nothing (Rex's death): unless one is running, mark
; the room's objects
;
; As REX 1's SmartBombFree $9749 (src/game/bomb.asm).
;
; Witness: L1 36 (c2, p2-room20, rzx-p2- x14).
SmartBombFree:
  LD A,(SmartBombOn)
  OR A
  RET NZ
  JP SmartBombStart

; SPACE: one smart bomb from Bombs $A266 (none left, nothing): the flash on
; $A1C9, the HUD, the timer 14, and the 20 enemy bullets marked (state 2)
;
; Changed from REX 1's SmartBomb $9751 (src/game/bomb.asm).
;
; Witness: L1 2 (rzx-p2-28000).
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
; This entry point is used by the routine at SmartBombFree.
SmartBombStart:
  LD A,$01                ; SmartBombOn $A1C9 = 1
  LD (SmartBombOn),A
  LD A,$0E
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
; As REX 1's SmartBombStep $9786 (src/game/bomb.asm).
;
; Witness: L1 10426 (c2, p2-room20, rzx-p2- x21).
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
  LD DE,$001B             ; the next marked object
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
