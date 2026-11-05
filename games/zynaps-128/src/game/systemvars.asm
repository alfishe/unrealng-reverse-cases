; --------------------------------------------------------------------------------------------------------------------
; systemvars.asm: The level order, the scenery coroutine, the wave launcher and the print variables
;
; Variables of the scenery coroutine, the sprite queue, the wave launcher and its template, the sprite cache masks,
; the print position and the menu raster, the shots and the weapons.
; --------------------------------------------------------------------------------------------------------------------

; The order of the 12 levels: 0 1 2, six of 3-8 shuffled, 9 10 11
;
; PlayersSetup $AFB7 fills $8006-$800B with the levels 3-8 in a random order
; for each game; LevelStart $B06F takes LevelOrder[+6]. Block 2 holds 0 1 2 0 0
; 0 0 0 0 9 10 11.
LevelOrder:
  DEFB $00,$01,$02,$00,$00,$00,$00,$00,$00,$09,$0A,$0B

; The scores of the extra lives: the score's +1 byte (BCD) 01 03 05 07 09, then
; $FF
;
; $AC8A: when the score's +1 byte is at least ExtraLifeScores[+$0C], +$0C and
; the lives go up: extra lives at 10000, 30000, 50000, 70000 and 90000.
ExtraLifeScores:
  DEFB $01,$03,$05,$07,$09,$FF

; The glyph allocator: the slot index, the bitmap byte's low address ($E0-$FF),
; the bit mask
;
; Read and written by AllocGlyphs $8912.
GlyphAlloc:
  DEFB $01
GlyphAllocByte:
  DEFB $E1
GlyphAllocBit:
  DEFB $01

; The main stack pointer, saved while the scenery coroutine runs ($8D60, $8D69)
MainSP:
  DEFW $0000

; The scenery coroutine's stack pointer (its stack top $FDFB, StartScript
; $8D35)
ScriptSP:
  DEFW $0000

; The map ring pointer of the leading column ($B760 at the level start; +1 per
; scroll step)
ScrollColumn:
  DEFW $0000

; The column where the next group goes, +16 per group (ResumeScript $8D45)
ScriptColumn:
  DEFB $00

; The columns scrolled since the last group: +1 per scroll step, -16 per group
ScriptRoom:
  DEFB $00

; $FF while a group is being placed, 0 after it
ScriptBusy:
  DEFB $00

; The variant mask (high nibble) the group objects are tested with; $F0 in
; block 2
ScriptVariant:
  DEFB $F0

; The scenery map position: cell = ScrollMap + 128 Y + X ($B730 at the level
; start; SceneryCell $99FF)
ScrollMap:
  DEFW $0000

; The sprite build queue's read index 0-7 ($ACAD)
DrawQueueRead:
  DEFB $00

; Its write index (QueueSpriteLoad $9441)
DrawQueueWrite:
  DEFB $00

; 8 entries of 3 bytes: the kind, the record address
DrawQueue:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00

; The 44-byte object record LaunchWave builds once a wave and copies to each
; enemy
;
; Zeroed ($924A), filled from the kind ($9261-$92BB) and the sprite cache
; ($92C2), then copied into the record IY: +0-+8 and +$0B-+$2B ($9304-$9313;
; +9/+$0A stay the record's own).
WaveTemplate:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
WaveTarget:
  DEFB $00,$00,$00        ; +$29/+$2A the target, the player $F36C

; The path number of each enemy of the wave being launched ($9231-$9247)
WavePaths:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Free slots of the 8 enemy records at $F398 (5 at the level start)
FreeEnemySlots:
  DEFB $05

; Wave records that may be in use (6 at the level start); LaunchWave -1, the
; wave's end +1
WavesAllowed:
  DEFB $06

; Enemy shots that may still start (3 at the level start; EnemyFire $A113)
EnemyShotsLeft:
  DEFB $03

; 6 wave records of 3 bytes: the live count ($FF free, bit 7 one escaped), the
; bonus byte, the kind
WaveRecords:
  DEFB $FF,$00,$00
  DEFB $FF,$00,$00
  DEFB $FF,$00,$00
  DEFB $FF,$00,$00
  DEFB $FF,$00,$00
  DEFB $FF,$00,$00

; A bit per used sprite cache record ($93A7)
SpriteCacheMask:
  DEFB $00

; The free record of a use mask: low nibble, or the high one by bit 4 of the
; kind ($93D8)
SpriteCacheFree:
  DEFB $51,$62,$61,$64,$54,$04,$01,$04,$53,$72,$01,$03,$51,$02,$01,$00

; A 7 x 9 cell map (one bit a cell) for BuildBigSprite with A = 1
BigSpriteMap1:
  DEFB $30,$70,$7C,$7C,$FC,$FC,$F8,$F0,$00

; The cell map for BuildBigSprite with A <> 1
BigSpriteMap2:
  DEFB $34,$34,$7C,$7C,$FC,$FC,$78,$78,$00

; The print position, an attribute address $5800-$5AFF (PrintChar $A33B, print
; codes 3-6)
PrintPos:
  DEFW $5800

; The printed characters' attribute (print codes 0-2)
PrintAttr:
  DEFB $07

; Below $20: a print code waiting for its byte; $20 none (PrintChar $A326)
PrintPending:
  DEFB $20

; The colour table of the menu raster interrupt ($A520): $FC20
RasterTable:
  DEFW $0000

; The scan lines the menu raster colours: 168 or 112
RasterLines:
  DEFB $00

; The colour list ExpandNextColours takes ($A5B0)
RasterList:
  DEFW $0000

; Six bytes no routine reads or writes in 48K c1/c2
RasterSpare:
  DEFB $00,$00,$00,$00,$00,$00

; Frames the menu raster still runs (-1 a frame, $A578)
RasterFrames:
  DEFB $00

; Laser shots not in flight (4 at most, $B2D1); fire when it plus the laser
; level is 4 or more
LaserShotsFree:
  DEFB $04

; Per pass: the enemy bits hit by the ship or a laser (TestHitGrid $9150)
LaserHitMask:
  DEFB $00

; 8, $10, $18: +8 each pass ($AA1B); the pods' flashing colour
ColourCycle:
  DEFB $00

; Enemy bits that do not kill the ship nor stop a laser (StartExplosion,
; ExplosionToPod)
HarmlessMaskA:
  DEFB $00

; See HarmlessMaskA
HarmlessMaskB:
  DEFB $00

; The index into ShipHistory (PlayerHandler $9AF3)
ShipHistoryIndex:
  DEFB $00

; The ship's last 8 positions, 4 bytes each (X fraction, X, Y fraction, Y); the
; sight follows the oldest
;
; PlayerSetUp $B21C fills it by pushing 16 words below $80E0 (SP = $80E0 at
; $B253).
ShipHistory:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The enemy record the sight locked on ($9FFC)
LockTarget:
  DEFW $0000

; Its collision bit, 0 no lock
LockMask:
  DEFB $00

; Per pass: the enemies the homing missile hits (cleared by RunObjects $94B2)
MissileHitMask:
  DEFB $00

; Per pass: the enemies under the sight
SightMask:
  DEFB $00

; Per pass: the enemies the plasma or the seeker hit
PlasmaHitMask:
  DEFB $00

; The fuel / power timer: -1 on passes with PassBit bit 0, $B4 from a full pod
; cycle, halved when a pod is lost
Fuel:
  DEFB $00

; $FF or $30 (WeaponRating $9B75); EnemyFire $A0F6 reads it
WeaponRatingMask:
  DEFB $FF

; How fast the next waves fly (WeaponRating $9B75: + ScriptLevelBias);
; EnemyFire $A109
WeaponRatingValue:
  DEFB $00

; 0 or 8: picks the KindColours set (LaunchWave $9271)
WeaponRatingLevel:
  DEFB $00
