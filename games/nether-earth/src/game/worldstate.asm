; --------------------------------------------------------------------------------------------------------------------
; worldstate.asm: The moving things of a game: shots, the two radar pictures, the save staging, the robot slots
;
; The game's live state below the map, all zero in the image and set up by the start-up and BuildMap: what the save
; writes to tape together with the map and the variables $FD00-$FDFB. Docs: 07-objects.md 7.2 (robots), 7.4 (shots),
; 06-rendering.md 6.7 (radar), 03-build-and-load.md 3.6 (the saved game).
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
; at $D7DC / $D7E5, the enemy's at $D7EE / $D7F7; no code fills the first
; record $D7D3, it is only cleared, saved and walked. FireShot fires,
; UpdateShot (from WorldTurn, every turn) moves and hits, DrawCellObject /
; DrawMoverSprite draw. Cleared by the start-up ($A661), saved and loaded
; through SaveShots.
Shots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

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
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Radar bitmap with the enemy's robots: 16 lines of 16 bytes
;
; The copy of RadarOwn the enemy's markers are XORed into; shown with attribute
; $4E. The save stages its last 213 bytes ($D92B-$D9FF) as SaveShots and
; SaveBuildings: the radar is rebuilt afterwards.
RadarEnemy:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; Save / load staging: the 5 Shots records
;
; SaveGameBlocks (save) copies Shots here and Buildings after it, then writes
; two headerless tape blocks with the ROM's SA-BYTES: the 2-byte sum of the
; second (at ViewBuffer) and $24D1 bytes from here to $FDFB (staging, robots,
; map, the variables $FD00-$FDFB). LoadGameBlocks loads both, checks the sum
; (SaveChecksum) and copies the records back, else LOADING ERROR. Shares the
; bytes of RadarEnemy.
SaveShots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

; Save / load staging: the 56 Buildings records
;
; 168 bytes, copied from and back to Buildings ($FF01) by SaveGameBlocks /
; LoadGameBlocks.
SaveBuildings:
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
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00

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
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The enemy's robots: slots 24-47, the same records
;
; +$0A has bit 7 set. EnemyCommander makes one (slot = an index x 16 from
; here); ConsiderBuilding, TargetRobotRecord and FindNearestOpponent search
; this array or Robots by the side in $FD51.
EnemyRobots:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
