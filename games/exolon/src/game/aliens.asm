; --------------------------------------------------------------------------------------------------------------------
; aliens.asm: The homing missile, the stars, the bonus pick-ups, the aliens on paths, the flickering pad
; --------------------------------------------------------------------------------------------------------------------

; Launches a homing missile from the right edge at a random height, while the
; screen's launcher stands
;
; Called by the screen set-up $8494 and by HomingMissileStep when no missile
; flies. Clears MissileLive; nothing when the screen has no launcher
; (MissileLauncher's $FF) or the player is dying ($9CE2). The launcher is tile
; 13: its cell in the map $6100 still holds kind $0D (the screen builder left
; it so; a grenade that destroys it changes it). Then MissileLive = $0D and the
; missile at X = $78 (the right edge), Y = $20 + (Random AND $7F).
HomingMissileStart:
  XOR A
  LD (MissileLive),A
  LD DE,(MissileLauncher)
  BIT 7,E
  RET NZ
  LD A,(DeathTimer)
  OR A
  RET NZ
  CALL CellOffset
  LD BC,CellTypes             ; the cell's kind in the map $6100
  ADD HL,BC
  LD A,(HL)
  CP $0D
  RET NZ
  LD (MissileLive),A
  CALL Random             ; the start height
  AND $7F
  ADD A,$20
  LD H,A
  LD L,$78
  LD (MissilePosition),HL
  RET

; The missile launcher's cell (column, row) from the screen builder (tile 13);
; $FF in the first byte: none
MissileLauncher:
  DEFB $00,$00

; The missile's X, Y; the builder's $FF end mark of MissileLauncher lands here
; first
MissilePosition:
  DEFB $00,$00

; $0D while the missile flies, 0 when not
MissileLive:
  DEFB $00

; Moves the homing missile: left, faster on the left part, one step toward the
; player's height a pass
;
; Main loop ($7638; c1: 3260). No missile: HomingMissileStart. The launcher
; gone (kind not $0D): 34 bonus ticks (850 points: the launcher's destruction
; pays while the missile is in the air), a blast at the missile, the missile
; removed. Else X - 1 (frame $0A); from X < $46 on, X - 2 (frame $0B); off the
; left edge (X = $FF): removed. Y moves 1 toward the player's Y ($82F6).
; Touching the player ($9BD6, B = $10, C = 8): KillPlayer, a blast, removed.
; Drawn in the slot $B4F1 in white ($47).
HomingMissileStep:
  LD A,(MissileLive)
  OR A
  JP Z,HomingMissileStart
  LD DE,(MissileLauncher)
  CALL CellOffset
  LD DE,(MissilePosition)
  PUSH DE
  LD BC,CellTypes
  ADD HL,BC
  LD A,(HL)
  CP $0D
  JR NZ,HomingMissileLauncherGone ; the launcher destroyed
  LD L,$0A                ; the slow frame
  DEC E
  LD A,E
  CP $FF
  JR NC,HomingMissileRemove
  CP $46
  JR NC,HomingMissileSteer
  INC L                   ; the fast frame, one more step
  DEC E
HomingMissileSteer:
  LD A,(PlayerY)          ; one step toward the player's height
  CP D
  JR Z,HomingMissileHit
  JR NC,HomingMissileYStep
  DEC D
  DEC D
HomingMissileYStep:
  INC D                   ; D one up (or one down after the two DECs)
HomingMissileHit:
  LD BC,$1008             ; the player touched?
  CALL PlayerContact
  OR A
  JR Z,HomingMissileDraw
  CALL KillPlayer
  JR HomingMissileBlast
HomingMissileLauncherGone:
  LD A,$22                ; 850 points in ticks
  CALL AddBonusTicks
HomingMissileBlast:
  CALL StartBlast
HomingMissileRemove:
  POP BC                  ; the slot cleared (frame 0), MissileLive 0, a new
                          ; launch at once
  XOR A
  LD HL,WorkArea+$0370
  CALL DrawSprite
  LD (MissileLive),A
  JP HomingMissileStart
HomingMissileDraw:
  LD (MissilePosition),DE
  POP BC
  LD A,L
  LD HL,WorkArea+$0370
  CALL DrawSprite
  LD C,$47
  JP ColourSprite

; The star field: 3 tries a row on rows 0-21, a star (character 3 of font
; $E840) where the cell is empty
;
; Called by the screen set-up $8494. For rows 21 down to 0, three random
; columns (Random AND $1F): when the map $5E00 holds 0 there (no scenery),
; PrintCharAttr $AE26 draws glyph 3 of TileSetE840 (one pixel, line 4) in a
; random bright ink $42-$47. So up to 66 stars, new each time a screen is
; built.
DrawStars:
  LD HL,TileSetE840
  LD (PrintChar+$000E),HL
  LD B,$16
DrawStarsRow:
  PUSH BC
  LD A,$03
DrawStarsTry:
  EX AF,AF'
  CALL Random
  AND $1F
  LD E,A
  LD D,B
  DEC D
  CALL CellOffset
  PUSH BC
  LD BC,AttrCopy
  ADD HL,BC
  POP BC
  LD A,(HL)
  OR A
  JR NZ,DrawStarsNext
  CALL Random
  AND $07
  OR $42
  LD C,A
  LD A,$03
  CALL PrintCharAttr
DrawStarsNext:
  EX AF,AF'
  DEC A
  JR NZ,DrawStarsTry
  POP BC
  DJNZ DrawStarsRow
  RET

; The bonus pick-ups of tile 14: the player touching one collects it for 1000
; points
;
; Main loop ($763B). Each live record of PickupList (column, row, live): the
; pixel box of the cell ($9936) against the player ($9BD6, B = 8, C = 4); on a
; touch the record dies, AY effect 5, and 40 bonus ticks (1000 points). The
; pick-up's picture is the screen's own tile; this code does not erase it (open
; question in exD.md).
PickupsVsPlayer:
  LD HL,PickupList
PickupsVsPlayerLoop:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,PickupsVsPlayerLoop
  PUSH DE
  CALL CellToPixels
  LD BC,$0804
  CALL PlayerContact
  POP DE
  OR A
  JR Z,PickupsVsPlayerLoop
  DEC HL                  ; collected
  LD (HL),$00
  CALL PlaySfxTrill
  LD A,$28
  JP AddBonusTicks

; The pick-ups of tile 14: up to 10 records of column, row, live (1); $FF at
; $A351
;
; The builder writes the column and row (its record size is 3, so the live byte
; is left as ClearPickups set it: 1 for the first four records).
PickupList:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $FF

; Sets the first 12 bytes of PickupList to 1 (four records live by default), at
; every screen set-up
;
; The builder then overwrites the column and row of the records it fills and
; puts $FF after the last; records past the screen's pick-ups are cut off by
; that $FF.
ClearPickups:
  LD HL,PickupList
  LD DE,PickupList+$0001
  LD BC,$000B
  LD (HL),$01
  LDIR
  RET

; Moves each live alien along its path and draws it
;
; Main loop ($763E; c1: 3260, AliensStepLoop 22 820). Alien n uses the slot
; $B521 + $30 n (6 aliens). A record of AlienList: +0 X, +1 Y, +2 live, +3/+4
; the path's start, +5/+6 the path pointer, +7 the hold count, +8 the animation
; counter, +9 the colour. The path (AlienPaths): a pair dX, dY (signed) moves
; one pass; $C4 n then a pair holds that move n passes; $C3 starts the path
; again. Off the playfield (X >= $80 or Y >= $B0): the alien dies and its slot
; is cleared. Frame = AlienFrame (patched per screen) + (animation AND 3), ink
; +9 ($7C8F).
AliensStep:
  LD IY,WorkArea+$03A0
  LD HL,AlienList

; AliensStepLoop
;
; Used by the routine at AliensNext.
AliensStepLoop:
  LD E,(HL)
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JP Z,AliensNext
  PUSH DE
  INC HL
  INC HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR NZ,AliensHoldMove
AliensPathRead:
  LD A,(BC)               ; the next path byte
  CP $C4
  JP Z,AliensPathHold
  CP $C3
  JP Z,AliensPathLoop
  ADD A,E
  LD E,A
  INC BC
  LD A,(BC)
  ADD A,D
  LD D,A
  INC BC
  DEC HL
  LD (HL),B
  DEC HL
  LD (HL),C
  JP AliensMoved
AliensHoldMove:
  DEC (HL)                ; a held move: count - 1, the same pair again
  LD A,(BC)
  ADD A,E
  LD E,A
  INC BC
  LD A,(BC)
  ADD A,D
  LD D,A
  JP AliensMoved
AliensPathHold:
  INC BC                  ; $C4 n: hold the next pair n passes
  LD A,(BC)
  DEC A
  LD (HL),A
  INC BC
  DEC HL
  LD (HL),B
  DEC HL
  LD (HL),C
  INC HL
  INC HL
  JR AliensHoldMove
AliensPathLoop:
  DEC HL                  ; $C3: back to the path's start
  DEC HL
  DEC HL
  LD B,(HL)
  DEC HL
  LD C,(HL)
  INC HL
  INC HL
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  JP AliensPathRead
AliensMoved:
  POP BC
  POP HL
  PUSH HL
  LD A,E
  CP $80
  JP NC,AliensOff
  LD A,D
  CP $B0
  JP NC,AliensOff
  LD (HL),E
  INC HL
  LD (HL),D
  PUSH DE
  LD DE,$0007
  ADD HL,DE
  LD A,(HL)
  INC (HL)
  AND $03
AlienFrame:
  ADD A,$01               ; ADD A,n: n = the screen's alien frame (AlienScreens
                          ; +3, patched by AliensSetUp)
  POP DE
  PUSH HL
  PUSH IY
  POP HL
  CALL DrawSprite
  POP HL
  INC HL
  LD C,(HL)
  CALL ColourSprite
  JP AliensNext
AliensOff:
  INC HL                  ; off the playfield: dead, the slot cleared
  INC HL
  LD (HL),$00
  XOR A
  PUSH IY
  POP HL
  CALL DrawSprite

; AliensNext
;
; Used by the routine at AliensStepLoop.
AliensNext:
  POP HL
  LD DE,$000A
  ADD HL,DE
  LD DE,$0030
  ADD IY,DE
  JP AliensStepLoop

; The 6 alien paths ($A406, $A445, $A490, $A4C5, $A4CE, $A4E3): dX dY pairs,
; $C4 n hold, $C3 loop
;
; $A406: a sine wave left (31 pairs of dX -1, dY 0 to +-3); $A445: the same
; wave, then 15 x (-1, 0), 6 x (-2, 0), 100 x (-4, 0) (it speeds off); $A490:
; 34 x (-2, 0), then a loop up and down over 30 passes, 100 x (-2, 0); $A4C5:
; 40 x (-1, 0), 100 x (-4, 0); $A4CE: 18 x (-2, 0), 32 x (0, -1), 24 x (0, +1),
; 6 still, 100 x (-4, 0); $A4E3: zig-zag, a box, 100 x (-4, 0). X is in 2-pixel
; units (128 across), Y in pixels. Every path ends with $C3.
AlienPaths:
  DEFB $FF,$00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FD,$FF,$FD
  DEFB $FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FE,$FF,$FE,$FF,$FF,$FF,$FF
  DEFB $FF,$00,$FF,$01,$FF,$01,$FF,$02,$FF,$02,$FF,$03,$FF,$03,$FF,$03
  DEFB $FF,$03,$FF,$03,$FF,$03,$FF,$02,$FF,$02,$FF,$01,$FF,$01,$C3
AlienPath2:
  DEFB $FF,$00,$FF,$00,$FF,$FF,$FF,$FF,$FF,$FE,$FF,$FE,$FF,$FD,$FF,$FD
  DEFB $FF,$FD,$FF,$FD,$FF,$FD,$FF,$FD,$FF,$FE,$FF,$FE,$FF,$FF,$FF,$FF
  DEFB $FF,$00,$FF,$01,$FF,$01,$FF,$02,$FF,$02,$FF,$03,$FF,$03,$FF,$03
  DEFB $FF,$03,$FF,$03,$FF,$03,$FF,$02,$FF,$02,$FF,$01,$FF,$01,$C4,$0F
  DEFB $FF,$00,$C4,$06,$FE,$00,$C4,$64,$FC,$00,$C3
AlienPath3:
  DEFB $C4,$22,$FE,$00,$C4,$04,$FE,$FE,$C4,$02,$FE,$F8,$C4,$03,$00,$F8
  DEFB $C4,$02,$02,$F8,$C4,$04,$02,$FE,$C4,$06,$02,$00,$C4,$04,$02,$02
  DEFB $C4,$02,$02,$08,$C4,$03,$00,$08,$C4,$02,$FE,$08,$C4,$04,$FE,$02
  DEFB $C4,$64,$FE,$00,$C3
AlienPath4:
  DEFB $C4,$28,$FF,$00,$C4,$64,$FC,$00,$C3
AlienPath5:
  DEFB $C4,$12,$FE,$00,$C4,$20,$00,$FF,$C4,$18,$00,$01,$C4,$06,$00,$00
  DEFB $C4,$64,$FC,$00,$C3
AlienPath6:
  DEFB $C4,$08,$FE,$FC,$C4,$08,$FE,$04,$C4,$08,$FE,$FC,$C4,$08,$00,$04
  DEFB $C4,$18,$FE,$00,$C4,$06,$00,$FC,$C4,$06,$02,$00,$C4,$06,$00,$04
  DEFB $C4,$64,$FC,$00,$C3

; The aliens: 6 records of 10 bytes (AliensStep), $FF at $A544
AlienList:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $FF

; Frees the 6 alien records (60 zeros), at every screen set-up
;
; Used by the routine at BuildScreen.
ClearAliens:
  LD HL,AlienList
  LD DE,AlienList+$0001
  LD BC,$003B
  LD (HL),$00
  LDIR
  RET

; Starts an alien from the right edge now and then, on the screens of
; AlienScreens
;
; Main loop ($762F). $9D78 returns from here too while the player is dying.
; Nothing on a screen without aliens (AliensHere 0), during AlienSpawnDelay, or
; when the player is at X >= $54 (the right part). A free record, then Random
; >= $C8 (56 in 256 passes): the alien at X = $78, Y = the player's Y - 10
; (Random >= $AF) or + 0..15, live, the path AlienPathStart (patched), hold 0,
; animation 3, the colour $40 + (Random AND 7) (1 becomes 5, 0 becomes 4: never
; black or blue), and the delay AlienSpawnDelay = the screen's delay.
AlienSpawn:
  CALL AbortIfDying
  LD A,(AliensHere)
  OR A
  RET Z
  LD HL,AlienSpawnDelay
  LD A,(HL)
  OR A
  JR Z,AlienSpawnFree
  DEC (HL)
  RET
AlienSpawnFree:
  LD A,(PlayerX)          ; find a free record
  CP $54
  RET NC
  LD HL,AlienList
  LD BC,$000A
AlienFindFree:
  LD E,(HL)               ; one 10-byte alien record a turn
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  INC HL
  LD A,(HL)
  OR A
  JR Z,AlienSpawnNew
  POP HL
  ADD HL,BC
  JR AlienFindFree
AlienSpawnNew:
  POP HL
  CALL Random
  CP $C8
  RET C
  LD (HL),$78
  INC HL
  LD DE,(PlayerX)
  CALL Random
  CP $AF
  JR C,AlienSpawnNear
  LD A,D
  SUB $0A
  JR AlienSpawnY
AlienSpawnNear:
  CALL Random             ; Y = the player's Y + 0..15
  AND $0F
  ADD A,D
AlienSpawnY:
  LD (HL),A
  INC HL
  LD (HL),$01
  INC HL
AlienPathStart:
  LD DE,AlienPaths        ; LD DE,nn: nn = the screen's path (patched by
                          ; AliensSetUp)
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$03
  INC HL
  CALL Random
  AND $07
  CP $02
  JR NC,AlienSpawnColour
  ADD A,$04
AlienSpawnColour:
  OR $40
  LD (HL),A
AlienDelaySet:
  LD A,$09                ; LD A,n: n = the screen's delay between aliens
                          ; (patched)
  LD (AlienSpawnDelay),A
  RET

; Passes before the next alien may start
AlienSpawnDelay:
  DEFB $00

; The player's shots against each live alien: a hit kills it (150 points)
;
; Called by the shot step $83DD. ShotHitsAlien for each, KillAlien on a hit.
; x2: 205 kills, warps: 1185 in 78 runs; none in c1.
AliensVsShots:
  LD IY,WorkArea+$03A0
  LD HL,AlienList
AliensVsShotsLoop:
  LD E,(HL)
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,AliensVsShotsNext
  CALL ShotHitsAlien
  OR A
  JR Z,AliensVsShotsNext
  POP HL
  PUSH HL
  CALL KillAlien
AliensVsShotsNext:
  POP HL
  LD DE,$000A
  ADD HL,DE
  LD DE,$0030
  ADD IY,DE
  JR AliensVsShotsLoop

; Each live alien against the player: a touch kills both
;
; Main loop ($765C). The box from X + 2, Y + 4 (B = 8, C = 4); then KillAlien
; and KillPlayer $9CAF.
AliensVsPlayer:
  LD IY,WorkArea+$03A0
  LD HL,AlienList
AliensVsPlayerLoop:
  LD E,(HL)
  BIT 7,E
  RET NZ
  PUSH HL
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR Z,AliensVsPlayerNext
  LD BC,$0804
  INC E
  INC E
  INC D
  INC D
  INC D
  INC D
  CALL PlayerContact
  OR A
  JR Z,AliensVsPlayerNext
  POP HL
  PUSH HL
  DEC E
  DEC D
  DEC D
  CALL KillAlien
  CALL KillPlayer
AliensVsPlayerNext:
  POP HL
  LD DE,$000A
  ADD HL,DE
  LD DE,$0030
  ADD IY,DE
  JR AliensVsPlayerLoop

; Kills the alien of record HL (slot IY): dead, the slot cleared, a blast, AY
; effect 8, 150 points
;
; In: HL = the record, IY = its slot. BC = X, Y for the blast.
KillAlien:
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  XOR A
  LD (HL),A
  PUSH IY
  POP HL
  CALL DrawSprite
  CALL StartBlast
  CALL PlaySfxExplosion
  LD DE,Points150+$0005   ; the 6 digits ending at $ADAE: 000150
  JP AddScore

; Looks the screen up in AlienScreens: sets AliensHere and patches the path,
; the frame and the delay
;
; Called by the screen set-up $8494. A screen not in the table: AliensHere = 0
; and no alien starts (the old patches stay, unused).
AliensSetUp:
  XOR A
  LD (AliensHere),A
  LD HL,AlienScreens
  LD A,(ScreenNumber)
  LD B,A
AliensSetUpLoop:
  LD A,(HL)
  CP $FF
  RET Z
  CP B
  JR Z,AliensSetUpFound
  INC HL
  INC HL
  INC HL
  INC HL
  INC HL
  JR AliensSetUpLoop
AliensSetUpFound:
  LD A,$01
  LD (AliensHere),A
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD (AlienPathStart+$0001),DE
  INC HL
  LD A,(HL)
  LD (AlienFrame+$0001),A
  INC HL
  LD A,(HL)
  LD (AlienDelaySet+$0001),A
  RET

; 1 when the current screen has aliens (AliensSetUp)
AliensHere:
  DEFB $00

; The 70 screens with aliens: the screen, the path (word), the frame base, the
; delay; $FF ends
;
; Screens 3-124 (none on 0-2 or on screen 24 and many others; the zone ends 49,
; 74, 99 and 124 have aliens). The frame bases are $01, $10, $14, $18, $25 and
; $29 (six alien looks); the delays 8-40 passes. A screen's path and look are
; independent (e.g. screen 3: path $A406, frame $10, delay 20; screen 54:
; $A4E3, $29, 30). The full list is in exD.md.
AlienScreens:
  DEFB $03,$06,$A4,$10,$14
  DEFB $04,$06,$A4,$10,$14
  DEFB $05,$06,$A4,$10,$14
  DEFB $0A,$45,$A4,$18,$14
  DEFB $0B,$45,$A4,$18,$28
  DEFB $0D,$45,$A4,$18,$14
  DEFB $0F,$90,$A4,$01,$0D
  DEFB $10,$45,$A4,$18,$1E
  DEFB $11,$06,$A4,$10,$14
  DEFB $13,$C5,$A4,$18,$14
  DEFB $15,$06,$A4,$10,$1E
  DEFB $16,$90,$A4,$01,$0D
  DEFB $1A,$C5,$A4,$14,$08
  DEFB $1C,$06,$A4,$01,$10
  DEFB $1D,$C5,$A4,$18,$19
  DEFB $1E,$C5,$A4,$18,$0F
  DEFB $21,$06,$A4,$10,$14
  DEFB $24,$90,$A4,$14,$08
  DEFB $25,$45,$A4,$01,$14
  DEFB $26,$45,$A4,$01,$08
  DEFB $27,$06,$A4,$10,$14
  DEFB $2A,$C5,$A4,$18,$08
  DEFB $2B,$C5,$A4,$18,$08
  DEFB $2C,$06,$A4,$10,$14
  DEFB $30,$C5,$A4,$18,$14
  DEFB $31,$90,$A4,$10,$08
  DEFB $33,$CE,$A4,$25,$09
  DEFB $36,$E3,$A4,$29,$1E
  DEFB $37,$06,$A4,$10,$09
  DEFB $38,$45,$A4,$29,$09
  DEFB $3A,$E3,$A4,$10,$14
  DEFB $3B,$C5,$A4,$25,$09
  DEFB $3E,$CE,$A4,$01,$09
  DEFB $3F,$06,$A4,$25,$09
  DEFB $40,$C5,$A4,$18,$09
  DEFB $42,$E3,$A4,$18,$1E
  DEFB $44,$06,$A4,$14,$08
  DEFB $45,$C5,$A4,$18,$28
  DEFB $48,$E3,$A4,$10,$23
  DEFB $4A,$E3,$A4,$18,$0C
  DEFB $4B,$06,$A4,$10,$09
  DEFB $4C,$C5,$A4,$10,$09
  DEFB $4D,$CE,$A4,$25,$09
  DEFB $4F,$90,$A4,$01,$09
  DEFB $50,$E3,$A4,$29,$1E
  DEFB $53,$E3,$A4,$29,$09
  DEFB $54,$CE,$A4,$29,$09
  DEFB $55,$90,$A4,$10,$08
  DEFB $56,$C5,$A4,$14,$09
  DEFB $59,$45,$A4,$18,$09
  DEFB $5A,$C5,$A4,$25,$08
  DEFB $5B,$CE,$A4,$29,$19
  DEFB $5E,$45,$A4,$14,$10
  DEFB $60,$E3,$A4,$18,$1E
  DEFB $62,$E3,$A4,$29,$23
  DEFB $63,$90,$A4,$10,$08
  DEFB $65,$C5,$A4,$14,$08
  DEFB $67,$06,$A4,$01,$0A
  DEFB $68,$C5,$A4,$18,$0A
  DEFB $69,$C5,$A4,$18,$0A
  DEFB $6C,$06,$A4,$10,$0A
  DEFB $6F,$90,$A4,$14,$08
  DEFB $70,$45,$A4,$01,$14
  DEFB $71,$45,$A4,$01,$08
  DEFB $72,$06,$A4,$10,$0A
  DEFB $75,$C5,$A4,$18,$08
  DEFB $76,$C5,$A4,$18,$08
  DEFB $77,$06,$A4,$10,$0A
  DEFB $7B,$C5,$A4,$18,$0A
  DEFB $7C,$90,$A4,$10,$08
  DEFB $FF

; The flickering pad of tile 15: two sprites side by side, random frames
; $1C-$1F and random colours
;
; Main loop ($7641). When the screen has one (FlickerPadList), draws frame $1C
; + (Random AND 3) in the slot $B641 at the cell's pixels and the next frame in
; the slot $B671 16 pixels right, in a random bright ink $40-$47 ($7C8F both).
; Nothing else reads its cell: a decoration that is redrawn every pass (what it
; shows is an open question; exD.md).
FlickerPadStep:
  LD HL,FlickerPadList
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  CALL CellToPixels
  LD HL,WorkArea+$04C0
  LD B,D
  LD C,E
  CALL Random
  AND $03
  ADD A,$1C
  CALL DrawSprite
  LD BC,$0030
  ADD HL,BC
  LD C,A
  LD A,E
  ADD A,$08
  LD E,A
  LD A,C
  INC A
  LD B,D
  LD C,E
  CALL DrawSprite
  CALL Random
  AND $07
  OR $40
  LD C,A
  CALL ColourSprite
  LD B,A
  LD A,E
  SUB $08
  LD E,A
  JP ColourSprite

; The flickering pad's cell (column, row), $FF at $A816; $FF in the first byte:
; none
FlickerPadList:
  DEFB $00,$00,$FF
