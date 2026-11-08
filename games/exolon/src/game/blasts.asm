; --------------------------------------------------------------------------------------------------------------------
; blasts.asm: The aliens hit, the blasts
; --------------------------------------------------------------------------------------------------------------------

; A = 1 when one of the player's shots overlaps the alien at DE (the shot is
; removed), else 0
;
; In: DE = the alien's X, Y. Walks the shot list $845F (X, Y, live; $FF ends):
; a live shot with shot X - (X + 2) in [-8, -1] and shot Y - Y - $11 in [-18,
; -1] hits; $82FC removes the shot's image and its live byte goes to 0. BC, DE,
; HL kept. Caller: AliensVsShots (x2: 49 331 entries).
ShotHitsAlien:
  PUSH BC
  PUSH DE
  PUSH HL
  INC E
  INC E
  LD HL,ShotList
ShotHitsAlienLoop:
  XOR A
  LD C,(HL)
  BIT 7,C
  JR NZ,ShotHitsAlienDone
  INC HL
  LD B,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,ShotHitsAlienLoop
  LD A,C
  SUB E
  CP $F8
  JR C,ShotHitsAlienLoop
  LD A,B
  SUB D
  SUB $11
  CP $EE
  JR C,ShotHitsAlienLoop
  LD D,B
  LD E,C
  CALL XorShot
  DEC HL
  LD (HL),$00
  LD A,$01
ShotHitsAlienDone:
  POP HL
  POP DE
  POP BC
  RET

; Starts a blast (the large explosion of 11 passes) at DE in the first free
; BlastList record
;
; In: DE = X, Y. AF and HL kept. Full list: nothing. Callers:
; HomingMissileStep, KillAlien, IdleMissileStep (its end). c128: 5, x2: 498,
; warps: 1331 entries.
StartBlast:
  PUSH AF
  PUSH HL
  LD HL,BlastList
StartBlastLoop:
  BIT 7,(HL)
  JR NZ,StartBlastDone
  INC HL
  INC HL
  LD A,(HL)
  OR A
  INC HL
  JR NZ,StartBlastLoop
  DEC HL
  LD (HL),$0B             ; 11 passes
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
StartBlastDone:
  POP HL
  POP AF
  RET

; Draws each live blast in its sprite slot: the frame by the passes left, a
; random colour and a crackle
;
; Main loop ($7632). Blast n uses the sprite slot $B401 + $30 n (5 slots).
; Frame = BlastFrames[passes left] (5 5 6 6 7 7 8 8 9 9 then 0, the empty frame
; that clears the slot), ink $42-$45 bright on black at random ($7C8F), then
; Click $7C26 for 1-32 rounds (the beeper). Passes left - 1 each pass.
RunBlasts:
  LD IY,WorkArea+$0280
  LD HL,BlastList
RunBlastsLoop:
  LD E,(HL)
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,RunBlastsNext
  DEC (HL)                ; passes left - 1 (A keeps the old count: 11..1)
  LD L,A
  LD H,$00
  LD BC,$A000             ; BlastFrames - 1 + passes left
  ADD HL,BC
  LD A,(HL)
  PUSH IY
  POP HL
  LD B,D
  LD C,E
  CALL DrawSprite
  CALL Random
  AND $03
  ADD A,$42
  LD C,A
  CALL ColourSprite
  CALL Random
  AND $1F
  INC A
  LD B,A
  CALL BeeperNoise
RunBlastsNext:
  LD BC,$0030             ; the next slot
  ADD IY,BC
  POP HL
  INC HL
  INC HL
  INC HL
  JR RunBlastsLoop

; The blast's frame for passes left 1..11: 0 (cleared), 9 9 8 8 7 7 6 6 5 5
BlastFrames:
  DEFB $00,$09,$09,$08,$08,$07,$07,$06,$06,$05,$05

; The blasts: 5 records of X, Y, passes left; $FF at $A01B ends
BlastList:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $FF

; Frees the 5 blast records (15 zeros), at every screen set-up
;
; Called by the screen set-up $8494 (c1: 4, warps: 223).
ClearBlasts:
  LD HL,BlastList
  LD DE,BlastList+$0001
  LD BC,$000E
  LD (HL),$00
  LDIR
  RET
