; --------------------------------------------------------------------------------------------------------------------
; vars.asm: The variables, the font and the high-score table
; --------------------------------------------------------------------------------------------------------------------

; The variables of play
;
; Read and written in the play recordings; cleared in parts by ClearPlayState
; and ClearShipStuff.
GameVars:
ColumnPtr:
  DEFB $00,$5E            ; the next byte of ColumnBuffer the metatile drawers
                          ; write
ScrollStep:
  DEFB $00                ; the step (0-7) in the 8-frame scroll cycle
MetaColumn:
  DEFB $00                ; the column (0-3) of the metatile the next column is
                          ; cut from
MapColumn:
  DEFB $00                ; the map block column the scroll has reached: the
                          ; level's position
MapReadPtr:
  DEFB $00,$00            ; the map byte the next metatile is read from
MapBlockPtr:
  DEFB $00,$00            ; the first of the 5 map bytes of the current block
                          ; column
FrameCounter:
  DEFB $00                ; counts the passes of the scroll (and the title
                          ; colour's steps)
IntTicks:
  DEFB $00                ; counts interrupts; the main loop waits until it
                          ; reaches 3
KempstonAbsent:
  DEFB $00                ; 0 when ProbeKempston found port $1F quiet: only
                          ; then does the title take the Kempston's fire
ExtraLives:
  DEFB $00                ; the extra lives given (CheckExtraLife)
DeathTimer:
  DEFB $00                ; set to 32 when the ship dies; LoseLife counts it
                          ; down
ScrollHalted:
  DEFB $00                ; non-zero while the scroll stands (a boss, wave
                          ; command 1)
WavesHalted:
  DEFB $00                ; non-zero once the level's end started
WavePtr:
  DEFB $00,$00,$00,$00    ; the next entry of the level's wave script
TextHeight:
  DEFB $00                ; 0: PrintText draws double height; 1: normal
HitCount:
  DEFB $00                ; the tags gathered into HitList by the last drawing
                          ; (14 at most)
HitResult:
  DEFB $00                ; ProcessHits' result
BeamMeter:
  DEFB $00                ; the BEAM meter's column
ShieldTimer:
  DEFB $00                ; the passes the ship carries the shield ($38 at the
                          ; first start, $20 at a later life, $30 from the
                          ; pick-up)
ScoreChanged:
  DEFB $00                ; non-zero when AddScore changed the score:
                          ; CheckExtraLife prints it
WaveOverride:
  DEFB $00                ; a wave command 3 value: the next wave's slot
LevelEndTimer:
  DEFB $00                ; counts down after the level's end command
DrawTag:
  DEFB $00                ; the tag DrawSprite writes into SolidMap for each
                          ; cell
StarFrame:
  DEFB $00                ; the star task's counter
ShooterLimit:
  DEFB $00                ; wave command 4: how many enemies may fire at once
Shooters:
  DEFB $00                ; the enemies firing now
Lives:
  DEFB $00                ; the lives (5 at the start)
ShipColumn:
  DEFB $00                ; the ship's column (1-28)
ShipRow:
  DEFB $00                ; the ship's row (0-19)
ForceAttached:
  DEFB $00                ; the Force: 0 free, 1 at the ship's nose, 2 at its
                          ; tail
ShipFrame:
  DEFB $00                ; the ship's sprite: 3 level, 2 and 4 the tilts
BitUpperOn:
  DEFB $00                ; the upper bit device is fitted
BitLowerOn:
  DEFB $00                ; the lower bit device is fitted
MissilesOn:
  DEFB $00                ; the homing missiles are fitted
ForceRecord:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the Force's records, 3 bytes each
  DEFB $00                             ; (state, column, row): $7AA8, $7AAB,
                                       ; $7AAE (ForceRecordOf)
BitPositions:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the bits' positions
  DEFB $00,$00,$00,$00
WeaponKind:
  DEFB $00                ; the Force's laser kind (the crystal's colour)
ForceLevel:
  DEFB $00                ; the Force's level: 0 none, 1-3
BeamCharge:
  DEFB $00                ; the beam's charge while fire is held, up to $3E (+2
                          ; a pass; $9A66 CP $40 keeps the old value at $40)
BeamPower:
  DEFB $00                ; the beam's strength left
Carriers:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the two pick-up carriers' records
BossBlast:
  DEFB $00                ; non-zero while the boss explodes (BossDestroyed)
BossBlastCount:
  DEFB $00                ; the random explosions left
BossBlastPos:
  DEFB $00,$00            ; the sweep position after the random ones
RandomPtr:
  DEFB $00,$00            ; the ROM pointer whose bytes are the random numbers
                          ; (NextRandom)
Scratch:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; scratch words of the shot and award
                                       ; routines
HitList:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the tags the last drawing gathered (15
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; bytes)
MissileLaunch:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the missiles' launch records, 6 bytes
  DEFB $00                             ; each ($7AE7, $7AED)

; The font: 8 bytes a character from '!' (the code - $20 from $7AE8; a space
; draws character $3B)
;
; PrintText draws it double height, PrintTextNormal as it is.
Font:
  INCBIN "res/graphics/font.bin",$0000,488

; Nine entries of 17 bytes: name (10), score (6 ASCII digits), $A0 (bit 7 ends
; the text)
;
; InsertHiScore inserts a new score, shifting the lower entries down; the names
; as loaded are the defaults.
HiScoreTable:
  INCBIN "res/texts/hiscores.bin",$0000,153

; the 17 bytes past the ninth entry the insertion shifts the last entry into
; (no recording reads them)
HiScoreSpare:
  INCBIN "res/leftovers/hiscore-spare.bin",$0000,17

; The homing missile's frame lists: (sprite, step) pairs, $FF ends a list
MissileFrames:
  DEFB $45,$04,$45,$00,$45,$00,$45,$00
  DEFB $45,$20,$FF,$45,$00,$45,$00,$45
  DEFB $00,$45,$00,$45,$20,$FF
MissileTurns:
  DEFB $45,$20,$FF,$49,$25,$47,$04,$47 ; the lists by direction ($7D98, $7D9B,
  DEFB $04,$47,$04,$47,$04,$FF,$49,$2B ; $7D9F, $7DA6, $7DAA)
  DEFB $47,$0A,$47,$0A,$47,$0A,$47,$0A
  DEFB $FF
AntiAirPathUp:
  DEFB $00,$3E,$00,$3F,$01,$40,$02,$41 ; the upward anti-air shot's path: (row
  DEFB $02,$42,$01,$43,$02,$42,$02,$43 ; step, sprite) pairs, $63 ends
  DEFB $02,$42,$02,$43,$02,$42,$02,$43
  DEFB $02,$42,$02,$43,$02,$42,$02,$43
  DEFB $02,$42,$02,$43,$63
AntiAirPathDown:
  DEFB $00,$3E,$FE,$3F,$FE,$40,$FD,$41 ; the downward path
  DEFB $FE,$42,$FE,$43,$FE,$42,$FE,$43
  DEFB $FE,$42,$FE,$43,$FE,$42,$FE,$43
  DEFB $FE,$42,$FE,$43,$FE,$42,$FE,$43
  DEFB $FE,$42,$63

; seven bytes the levels' own code uses; cleared at each start
LevelVars:
  DEFB $00,$00,$00,$00,$00,$00,$00

; The collision map: one byte a cell of the 20 x 32 play field, the tag of what
; is there
;
; 0 empty; small values the ship and its shots; $80 + slot an enemy; $FA an
; enemy's soft part; $FB-$FF hard scenery (from the metatile attribute's bit
; 7). GetCell reads it.
SolidMap:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00
EntryCopySource:
  DEFB $40,$08,$80,$03,$50,$00,$40,$04,$80,$07,$50,$00,$40,$04,$80,$0A,$50,$00,$40,$04,$80,$07,$50,$00,$40,$04,$80,$03,$50,$00,$40,$08 ; the 414
  DEFB $80,$05,$50,$00,$40,$04,$80,$08,$50,$00,$40,$04,$80,$0C,$50,$00,$40,$04,$80,$08,$50,$00,$40,$04,$80,$05,$50,$00,$40,$08,$80,$07 ; bytes the
  DEFB $50,$00,$40,$04,$80,$0A,$50,$00,$40,$04,$80,$0E,$50,$00,$40,$04,$80,$0A,$50,$00,$40,$04,$80,$0E,$50,$00,$40,$0C,$80,$0F,$50,$00 ; entry
  DEFB $00,$00,$C6,$18,$C6,$30,$D6,$18,$D6,$00,$00,$00,$80,$22,$00,$00,$40,$10,$80,$03,$50,$00,$77,$22,$77,$30,$77,$27,$77,$2E,$77,$0B ; copies to
  DEFB $77,$05,$77,$0C,$77,$0C,$77,$0D,$77,$0D,$77,$0E,$77,$0E,$77,$0F,$77,$0F,$77,$10,$77,$10,$77,$12,$77,$12,$77,$14,$77,$14,$77,$17 ; EntryCopy
  DEFB $77,$17,$77,$1A,$77,$1A,$77,$1C,$77,$1E,$77,$20,$77,$22,$77,$25,$77,$28,$40,$0A,$77,$10,$77,$18,$77,$30,$50,$00,$40,$08,$80,$11 ; before
  DEFB $50,$00,$40,$08,$80,$14,$50,$00,$40,$08,$80,$16,$50,$00,$40,$06,$10,$00,$50,$00,$40,$08,$80,$16,$50,$00,$40,$08,$80,$14,$50,$00 ; SolidMap
  DEFB $40,$0A,$80,$11,$50,$00,$00,$00,$40,$06,$80,$07,$50,$00,$40,$06,$80,$05,$50,$00,$40,$06,$80,$03,$50,$00,$40,$06,$80,$05,$50,$00 ; is first
  DEFB $40,$06,$80,$07,$50,$00,$40,$08,$80,$0F,$50,$00,$00,$00,$11,$01,$80,$0E,$11,$01,$11,$01,$80,$0B,$11,$01,$11,$01,$80,$0C,$11,$01 ; cleared
  DEFB $11,$01,$80,$09,$11,$01,$11,$01,$80,$0A,$11,$01,$11,$01,$80,$07,$11,$01,$11,$01,$80,$0C,$11,$01,$11,$01,$80,$09,$11,$01,$41,$06
  DEFB $80,$0E,$51,$01,$41,$08,$80,$0F,$51,$01,$00,$00,$C4,$10,$C4,$20,$C4,$30,$D4,$18,$00,$00,$41,$02,$11,$01,$51,$01,$41,$0E,$80,$07
  DEFB $51,$01,$41,$28,$10,$00,$51,$01,$80,$05,$80,$09,$80,$0C,$80,$07,$80,$0A,$80,$0E,$80,$09,$80,$0C,$80,$10,$80,$11,$80,$15,$80,$18
  DEFB $80,$13,$80,$16,$80,$1A,$80,$15,$80,$18,$80,$1C,$80,$1D,$00,$00,$42,$04,$11,$01,$52,$02,$42,$0C,$80,$0A,$52,$02,$00,$00

; The 20 play rows: (screen address, attribute address) of each row's right end
;
; ScrollRows walks it; the star task starts at its second row.
RowTable:
  DEFB $1F,$40,$1F,$58
  DEFB $3F,$40,$3F,$58
  DEFB $5F,$40,$5F,$58
  DEFB $7F,$40,$7F,$58
  DEFB $9F,$40,$9F,$58
  DEFB $BF,$40,$BF,$58
  DEFB $DF,$40,$DF,$58
  DEFB $FF,$40,$FF,$58
  DEFB $1F,$48,$1F,$59
  DEFB $3F,$48,$3F,$59
  DEFB $5F,$48,$5F,$59
  DEFB $7F,$48,$7F,$59
  DEFB $9F,$48,$9F,$59
  DEFB $BF,$48,$BF,$59
  DEFB $DF,$48,$DF,$59
  DEFB $FF,$48,$FF,$59
  DEFB $1F,$50,$1F,$5A
  DEFB $3F,$50,$3F,$5A
  DEFB $5F,$50,$5F,$5A
  DEFB $7F,$50,$7F,$5A

; zeros after the table
RowTableEnd:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; the play's star states (2 bytes a star) for the star task
PlayStarStates:
  DEFB $03,$15,$01,$11,$00,$05,$02,$0A
  DEFB $02,$1C,$01,$16,$03,$10,$00,$08
  DEFB $01,$06,$01,$0E,$00,$0C,$00,$19
  DEFB $02,$00,$03,$1A,$00,$1C,$02,$17
  DEFB $01,$01,$01,$04,$01,$03,$01,$18

; 1 where a sprite cell is on the screen (set by ScrollRows' copy, cleared by
; its erase); the star task draws only where it is 0 (640 bytes cleared by
; ClearPlayState)
DrawnMap:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
