; --------------------------------------------------------------------------------------------------------------------
; worldstate.asm: The moving things of a game: shots, the two radar pictures, the save staging, the robot slots
;
; The game's live state below the map, set up by the start-up and BuildMap. Only Shots ($D7D3, 45 bytes) and the first
; $80 bytes of RadarOwn ($D800-$D87F, map rows 0-7) lie inside the '98 file: the REM loader reads whole sectors, 113 x
; 256 bytes up to $D87F, and the file holds zeros there (NE's tape block has zeros there too). The rest (RadarOwn's
; rows 8-15, RadarEnemy $D900, Robots $DA00, EnemyRobots $DB80) is outside the file. NE saved this state to tape with
; the map and the variables; the '98 has no save (SaveGame $C28D is a RET). NE's docs: 07-objects.md 7.2 (robots), 7.4
; (shots), 06-rendering.md 6.7 (radar), 03-build-and-load.md 3.6 (the saved game).
;
; Contents in address order: Shots (5 records of 9), RadarOwn and RadarEnemy (two 256-byte radar pictures,
; PlayInterrupt shows one each frame), Robots (24 player slots of 16) and EnemyRobots (24 enemy slots); NE's save
; staging over the tail of RadarEnemy ($D92B) has no user left in the '98. Each entry's description gives the record
; fields and who reads and writes them.
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
; Cleared by the start-up ($A661). Zero in the file.
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
; colour. Cleared with the map by BuildMap ($BC87). The file holds zeros for
; rows 0-7 ($D800-$D87F), the last bytes of its last sector; rows 8-15 lie past
; the file.
RadarOwn:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 0
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 1
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 2
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 3
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 4
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 5
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 6
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; map row 7
