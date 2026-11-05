; --------------------------------------------------------------------------------------------------------------------
; worldstate.asm: The moving things of a game: shots, the two radar pictures, the save staging, the robot slots
;
; The game's live state below the map, all zero in the image and set up by the start-up and BuildMap: what the save
; writes to tape together with the map and the variables $FD00-$FDFB. Docs: nether-earth/docs/07-objects.md 7.2
; (robots), 7.4 (shots), nether-earth/docs/06-rendering.md 6.7 (radar), nether-earth/docs/03-build-and-load.md 3.6
; (the saved game).
;
; Contents in address order: Shots (5 records of 9), RadarOwn and RadarEnemy (two 256-byte radar pictures,
; PlayInterrupt shows one each frame), SaveShots / SaveBuildings (the save's staging, laid over the tail of
; RadarEnemy), Robots (24 player slots of 16) and EnemyRobots (24 enemy slots). Each entry's description gives the
; record fields and who reads and writes them.
;
; The save block starts at SaveShots $D92B, so Shots and Buildings (which lie outside $D92B-$FDFB) are copied into the
; staging first and back after a load; the radar is rebuilt (RadarDirty) because the staging overwrote it.
; --------------------------------------------------------------------------------------------------------------------

; Shots in flight: 5 records of 9 bytes
;
; +0/+1 the map cell (+1 = 0: free), +2/+3 X, +4 Y, +5 the direction (bit 0
; X+2, 1 X-2, 2 Y+2, 3 Y-2), +6 steps left (5, 7 for missiles, 1 more with
; electronics), +7 the weapon (1 cannon, 2 missiles, 3 phasers: a random one of
; the robot's weapon bits 3-5), +8 the flight height ($0A: a cell at least that
; high stops it). FindFreeShot gives a robot a free slot of two: the player's
; at $D7DC / $D7E5, the enemy's at $D7EE / $D7F7; the first record $D7D3 is the
; player's COMBAT MODE shot, fired by CombatFireShot when it is free
; (FindFreeShot never hands it out). FireShot fires, UpdateShot (from
; WorldTurn, every turn) moves and hits, DrawCellObject / DrawMoverSprite draw.
; Cleared by the start-up ($A661), saved and loaded through SaveShots.
Shots:
  DEFB $00,$00            ; record 0, the player's COMBAT MODE shot: +0/+1 the
                          ; map cell (+1 = 0: free)
  DEFB $00,$00            ; +2/+3 X, the column
  DEFB $00                ; +4 Y, the row
  DEFB $00                ; +5 the direction (an Input bit)
  DEFB $00                ; +6 steps left: 5, 7 for missiles, 1 more with
                          ; electronics
  DEFB $00                ; +7 the weapon: 1 cannon, 2 missiles, 3 phasers
  DEFB $00                ; +8 the flight height: a cell this high stops it
                          ; ($0A)
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; record 1: our robots' first
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; record 2: our robots' second
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; record 3: the enemy's first
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; record 4: the enemy's second

; Radar bitmap with the player's robots: 16 lines of 16 bytes
;
; One pixel line per map row, one bit per map column, 128 columns from the
; radar's left edge ($FD1C, moved by 64 columns at a time). BuildRadar builds
; it (a bit is set where cell AND $1F >= $0F: blocks and posts), copies it to
; RadarEnemy, then ToggleRadarDot XORs a 2-line marker for every robot into the
; player's or the enemy's copy by the side bit of +$0A (also when a robot
; moves, PlaceRobot / RobotStep). PlayInterrupt shows the two copies on
; alternate frames ($FD1A) with ShowRadar at $50C6 (16 lines, 16 bytes) and
; attributes $4D / $4E in rows 22-23, so each side's robots blink in their own
; colour. Cleared with the map by BuildMap ($BC87).
RadarOwn:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 0
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 1
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 2
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 3
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 4
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 5
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 6
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 7
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 8
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 9
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 10
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 11
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 12
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 13
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 14
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 15

; Radar bitmap with the enemy's robots: 16 lines of 16 bytes
;
; The copy of RadarOwn the enemy's markers are XORed into; shown with attribute
; $4E. The save stages its last 213 bytes ($D92B-$D9FF) as SaveShots and
; SaveBuildings: the radar is rebuilt afterwards.
RadarEnemy:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 0
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 1
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 2

; Save / load staging: the 5 Shots records
;
; SaveGameBlocks (save) copies Shots here and Buildings after it, then writes
; two headerless tape blocks with the ROM's SA-BYTES: the 2-byte sum of the
; second (at ViewBuffer) and $24D1 bytes from here to $FDFB (staging, robots,
; map, the variables $FD00-$FDFB). LoadGameBlocks loads both, checks the sum
; (SaveChecksum) and copies the records back, else LOADING ERROR. Shares the
; bytes of RadarEnemy.
SaveShots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; Shots record 0, over RadarEnemy's
                                           ; map row 2 byte 11 on
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; Shots record 1
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; Shots record 2
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; Shots record 3
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00 ; Shots record 4

; Save / load staging: the 56 Buildings records
;
; 168 bytes, copied from and back to Buildings ($FF01) by SaveGameBlocks /
; LoadGameBlocks.
SaveBuildings:
  DEFB $00,$00,$00        ; Buildings record 0 ($FF01): cell (2 bytes, high
                          ; byte 0 free), type
  DEFB $00,$00,$00        ; Buildings record 1 ($FF04)
  DEFB $00,$00,$00        ; Buildings record 2 ($FF07)
  DEFB $00,$00,$00        ; Buildings record 3 ($FF0A)
  DEFB $00,$00,$00        ; Buildings record 4 ($FF0D)
  DEFB $00,$00,$00        ; Buildings record 5 ($FF10)
  DEFB $00,$00,$00        ; Buildings record 6 ($FF13)
  DEFB $00,$00,$00        ; Buildings record 7 ($FF16)
  DEFB $00,$00,$00        ; Buildings record 8 ($FF19)
  DEFB $00,$00,$00        ; Buildings record 9 ($FF1C)
  DEFB $00,$00,$00        ; Buildings record 10 ($FF1F)
  DEFB $00,$00,$00        ; Buildings record 11 ($FF22)
  DEFB $00,$00,$00        ; Buildings record 12 ($FF25)
  DEFB $00,$00,$00        ; Buildings record 13 ($FF28)
  DEFB $00,$00,$00        ; Buildings record 14 ($FF2B)
  DEFB $00,$00,$00        ; Buildings record 15 ($FF2E)
  DEFB $00,$00,$00        ; Buildings record 16 ($FF31)
  DEFB $00,$00,$00        ; Buildings record 17 ($FF34)
  DEFB $00,$00,$00        ; Buildings record 18 ($FF37)
  DEFB $00,$00,$00        ; Buildings record 19 ($FF3A)
  DEFB $00,$00,$00        ; Buildings record 20 ($FF3D)
  DEFB $00,$00,$00        ; Buildings record 21 ($FF40)
  DEFB $00,$00,$00        ; Buildings record 22 ($FF43)
  DEFB $00,$00,$00        ; Buildings record 23 ($FF46)
  DEFB $00,$00,$00        ; Buildings record 24 ($FF49)
  DEFB $00,$00,$00        ; Buildings record 25 ($FF4C)
  DEFB $00,$00,$00        ; Buildings record 26 ($FF4F)
  DEFB $00,$00,$00        ; Buildings record 27 ($FF52)
  DEFB $00,$00,$00        ; Buildings record 28 ($FF55)
  DEFB $00,$00,$00        ; Buildings record 29 ($FF58)
  DEFB $00,$00,$00        ; Buildings record 30 ($FF5B)
  DEFB $00,$00,$00        ; Buildings record 31 ($FF5E)
  DEFB $00,$00,$00        ; Buildings record 32 ($FF61)
  DEFB $00,$00,$00        ; Buildings record 33 ($FF64)
  DEFB $00,$00,$00        ; Buildings record 34 ($FF67)
  DEFB $00,$00,$00        ; Buildings record 35 ($FF6A)
  DEFB $00,$00,$00        ; Buildings record 36 ($FF6D)
  DEFB $00,$00,$00        ; Buildings record 37 ($FF70)
  DEFB $00,$00,$00        ; Buildings record 38 ($FF73)
  DEFB $00,$00,$00        ; Buildings record 39 ($FF76)
  DEFB $00,$00,$00        ; Buildings record 40 ($FF79)
  DEFB $00,$00,$00        ; Buildings record 41 ($FF7C)
  DEFB $00,$00,$00        ; Buildings record 42 ($FF7F)
  DEFB $00,$00,$00        ; Buildings record 43 ($FF82)
  DEFB $00,$00,$00        ; Buildings record 44 ($FF85)
  DEFB $00,$00,$00        ; Buildings record 45 ($FF88)
  DEFB $00,$00,$00        ; Buildings record 46 ($FF8B)
  DEFB $00,$00,$00        ; Buildings record 47 ($FF8E)
  DEFB $00,$00,$00        ; Buildings record 48 ($FF91)
  DEFB $00,$00,$00        ; Buildings record 49 ($FF94)
  DEFB $00,$00,$00        ; Buildings record 50 ($FF97)
  DEFB $00,$00,$00        ; Buildings record 51 ($FF9A)
  DEFB $00,$00,$00        ; Buildings record 52 ($FF9D)
  DEFB $00,$00,$00        ; Buildings record 53 ($FFA0)
  DEFB $00,$00,$00        ; Buildings record 54 ($FFA3)
  DEFB $00,$00,$00        ; Buildings record 55 ($FFA6)

; The player's robots: slots 0-23, 16 bytes a record
;
; +0/+1 the map cell (+1 = 0: a free slot), +2/+3 X, +4 Y, +5 the last move's
; direction (likely), +6 a counter (unverified), +7 parts (bit 0 bipod ... 7
; electronics), +8 direction (bit 0 X+, 1 X-, 2 Y+, 3 Y-), +9 height (the sum
; of PartHeights), +$0A side / menu flags (1 the ship sits on it, 2 direct
; control, bit 7 enemy), +$0B order, +$0C strength ($64 at birth), +$0D the
; height its parts are drawn from (0, 2, 6 seen), +$0E target slot / distance,
; +$0F the move timer (RobotStep DEC, acts at 0). Walked by WorldTurn (every
; turn: UpdateRobot), FindRobot, BuildRadar, ConstructionMenu (a free slot of
; 0-23), the AI (ConsiderBuilding, TargetRobotRecord, FindNearestOpponent: the
; other side's array). Cleared by the start-up ($A63A, 768 bytes with
; EnemyRobots).
Robots:
  DEFB $00,$00            ; slot 0 (ours): +0/+1 the map cell of the anchor (+1
                          ; = 0: free)
  DEFB $00,$00            ; +2/+3 X, the column 0-511
  DEFB $00                ; +4 Y, the row 0-15
  DEFB $00                ; +5 the course, an Input bit (0 standing)
  DEFB $00                ; +6 steps left on the course
  DEFB $00                ; +7 parts: bit 0 bipod ... 7 electronics
  DEFB $00                ; +8 the facing, an Input bit
  DEFB $00                ; +9 the height (PartHeights summed)
  DEFB $00                ; +$0A control: 0 AI, 1 ship on it, 2 direct control,
                          ; $80 enemy
  DEFB $00                ; +$0B the order 0-8
  DEFB $00                ; +$0C strength, 100 at birth
  DEFB $00                ; +$0D the ground under it
  DEFB $00                ; +$0E the target (miles, slot or building)
  DEFB $00                ; +$0F turns to the next step
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 1
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 2
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 3
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 4
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 5
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 6
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 7
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 8
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 9
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 10
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 11
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 12
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 13
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 14
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 15
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 16
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 17
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 18
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 19
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 20
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 21
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 22
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 23

; The enemy's robots: slots 24-47, the same records
;
; +$0A has bit 7 set. EnemyCommander makes one (slot = an index x 16 from
; here); ConsiderBuilding, TargetRobotRecord and FindNearestOpponent search
; this array or Robots by the side in $FD51.
EnemyRobots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 24
                                                                       ; (enemy)
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 25
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 26
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 27
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 28
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 29
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 30
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 31
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 32
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 33
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 34
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 35
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 36
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 37
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 38
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 39
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 40
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 41
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 42
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 43
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 44
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 45
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 46
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; slot 47
