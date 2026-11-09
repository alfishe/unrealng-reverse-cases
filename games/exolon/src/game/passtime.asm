; --------------------------------------------------------------------------------------------------------------------
; passtime.asm: The pass time pads, the bonus ticks, the teleport sparkles, the exoskeleton booth
; --------------------------------------------------------------------------------------------------------------------

; Burns the time of the XOR sprite draws this pass did not make, up to 16
;
; Main loop, at its end ($766E). XorSprite $92FB counts every draw in
; XorSpriteCount (+1 at $9359); the main loop zeroes the count at its start
; ($75BF). With fewer than 16 draws this pass, the rest are made with sprite 6
; at whatever DE holds, so a pass takes about the same time whatever is on the
; screen (the game paces itself by the work, not by the frame). c1: 3260
; entries, one a pass. Whether sprite 6 is blank was not checked; the screens
; show no trace of it.
PadXorSprites:
  LD A,(XorSpriteCount)
  CP $10
  RET NC
  LD B,A
  LD A,$10
  SUB B
  LD B,A
  LD A,$06
PadXorSpritesLoop:
  CALL DrawSmallSprite
  DJNZ PadXorSpritesLoop
  RET

; The XOR sprite draws of this pass: zeroed at $75BF, +1 per XorSprite $92FB
; ($9359)
XorSpriteCount:
  DEFB $00

; The same pad for the slot sprites of $795C: up to 6 draws of an empty frame
;
; Main loop ($7671), after PadXorSprites. SlotSpriteCount is zeroed at $75C2
; and never raised anywhere in the image (no other reference to $9EAE), so this
; always draws 6 times: frame 0 (empty) into the slot $B101 with B = 6..1 as
; its Y. A pad whose counter was left out in this release (or never needed):
; its cost is constant.
PadSlotSprites:
  LD A,(SlotSpriteCount)
  CP $06
  RET NC
  LD B,A
  LD A,$06
  SUB B
  LD B,A
  LD HL,NoSaveBuffer
  XOR A
PadSlotSpritesLoop:
  CALL DrawSprite
  DJNZ PadSlotSpritesLoop
  RET

; Zeroed each pass ($75C2); no code raises it
SlotSpriteCount:
  DEFB $00

; Adds A ticks of 25 points to the pending bonus and asks for AY effect 5
;
; In: A = the ticks. BonusTicks += A; $C12E asks the AY for effect 5.
; PayBonusTick then pays one tick a pass. Callers: HomingMissileStep (34 ticks,
; 850 points, a launcher destroyed), PickupsVsPlayer (40 ticks, 1000 points),
; the force field's end $AC54 (40). Warp runs: 79 entries in 33 runs.
AddBonusTicks:
  PUSH HL
  PUSH DE
  CALL PlaySfxTrill
  LD E,A
  LD D,$00
  LD HL,(BonusTicks)
  ADD HL,DE
  LD (BonusTicks),HL
  POP DE
  POP HL
  RET

; One pending bonus tick a pass: 25 points and a click
;
; Main loop ($7629). While BonusTicks is not 0: BonusTicks - 1, AddScore
; Points25, Click $7C26 with B = $28 (the beeper only; it returns at once on a
; 128K). So a bonus counts up on the score 25 points a pass with a rattle,
; instead of at once.
PayBonusTick:
  LD HL,(BonusTicks)
  LD A,L
  OR H
  RET Z
  DEC HL
  LD (BonusTicks),HL
  LD DE,PointValues+$0005 ; the 6 digits ending at $AD96: 000025
  CALL AddScore
  LD B,$28
  JP BeeperNoise

; The pending bonus in ticks of 25 points (AddBonusTicks, PayBonusTick); 0 at a
; new game ($6D7B)
BonusTicks:
  DEFW $0000

; $0C while the player wears the exoskeleton, 0 without: the frame offset of
; his sprites
;
; Toggled by ExoSuitBooth (XOR $0C), cleared at a new game ($6D72) and at a
; zone's end (ZoneRefill $A8A5). $8224 adds it to every player frame number
; (the suited frames are $0C on). Read by the fire ($837B: a second shot 6
; lower while suited), by $9CAA (the mines and traps of the ZXDB POKEs $9CAE:
; the suit protects) and by ZoneBonus (no bravery bonus while suited).
ExoSuit:
  DEFB $00

; Puts a sparkle of 20 passes at DE into the first free record of SparkleList
;
; In: DE = X, Y (pixels). Called twice by the teleport $98BA: one sparkle at
; the pad left, one at the pad reached. Full list: nothing. x2: 2 entries,
; warps: 72 in 30 runs.
StartSparkle:
  LD HL,SparkleList
StartSparkleLoop:
  BIT 7,(HL)
  RET NZ
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR NZ,StartSparkleLoop
  DEC HL
  LD (HL),$14             ; 20 passes of sparkle
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
  RET

; Each pass, one explosion at a random point of each live sparkle's 4 x 16 box
;
; Main loop ($762C). For each record with passes left: passes - 1, then an
; explosion ($981D, the small explosion list) at X + (Random AND 3), Y +
; (Random AND 15). So a teleport shows a column of small explosions over the
; booth for 20 passes.
RunSparkles:
  LD HL,SparkleList
RunSparklesLoop:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,RunSparklesLoop
  DEC HL
  DEC (HL)                ; passes left - 1
  INC HL
  CALL Random
  AND $03
  ADD A,E
  LD E,A
  CALL Random
  AND $0F
  ADD A,D
  LD D,A
  CALL AddPuff
  JR RunSparklesLoop

; The sparkles: 4 records of X, Y, passes left; $FF ends
SparkleList:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $FF

; Frees the 4 sparkle records (12 zeros), at every screen set-up
;
; Called by the screen set-up $8494 (c1: 4 entries, the 4 games' first screens;
; warps: 223).
ClearSparkles:
  LD HL,SparkleList
  LD DE,SparkleList+$0001
  LD BC,$000B
  LD (HL),B
  LDIR
  RET

; The exoskeleton booth: up pressed while standing in it puts the suit on or
; takes it off
;
; Main loop ($7635). UP ($7B94) is taken on its edge: BoothUpLatch holds 1
; while it stays pressed. The booth is the screen's tile 12, whose cell
; ExoBoothList holds (the screen builder's object table $8EF4: tile 12, 2
; bytes, the cell kind 1 left in the map). The player must stand on the cell's
; row + 1 in pixel units (Y = 8 (row + 1)) with X - 4 col in [-12, +8]. Then
; ExoSuit XOR $0C, AY effect 2 ($C0F4), and $8224 with A = 5 redraws the player
; in his new frames.
;
; The same shape as the teleport $98BA (two booths of tile 6), which this agent
; leaves to its range. c1: 3260 entries, no toggle; of all the recordings only
; the warp run w/108 toggled the suit ($9F59-$9F6C executed).
ExoSuitBooth:
  LD A,(ControlJump)
  OR A
  JR NZ,ExoSuitBoothPressed
  LD (BoothUpLatch),A
  RET
ExoSuitBoothPressed:
  LD A,(BoothUpLatch)     ; UP held: act only on the first pass
  OR A
  RET NZ
  INC A
  LD (BoothUpLatch),A
  LD DE,(ExoBoothList)
  BIT 7,E
  RET NZ
  INC D                   ; the row under the booth's top cell
  CALL CellToPixels
  LD A,(PlayerY)
  CP D
  RET NZ
  LD A,(PlayerX)
  SUB E
  SUB $09
  CP $EB
  RET C
  LD DE,(PlayerX)         ; the player is in the booth
  LD A,(ExoSuit)          ; the suit on or off
  XOR $0C
  LD (ExoSuit),A
  CALL PlaySfxAmmoRefill
  LD A,$05
  JP PlayerFrame

; 1 while UP stays pressed after a booth action, 0 when released
BoothUpLatch:
  DEFB $00

; The exoskeleton booth's cell (column, row), $FF when the screen has none
;
; Written by the screen builder ($8EAD through $8EF4's tile-12 record, which
; points here); one booth a screen at most (the $FF after the first record ends
; the list).
ExoBoothList:
  DEFB $00,$00,$FF
