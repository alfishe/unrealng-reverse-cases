; --------------------------------------------------------------------------------------------------------------------
; leveldata.asm: The level data: maps, tiles, object kinds, zones, exits, object lists, animations, scripts
;
; Rick Dangerous has four levels of 6, 7, 12 and 9 zones (34). A zone is a vertical strip of map rows; the player
; scrolls up and down inside it and leaves by its left or right edge into another zone (Exits). The level table at
; $E4AE (11 bytes a level) points at the level's first zone (bytes 8-9) and gives the starting map row (byte 10);
; $AC83 enters a zone.
;
; All of it is editable text in src/res/levels/ (tools/res_levels.py: one file a level, plus the tiles, the object
; kinds and the animation and movement lists); src/res/levels/README.md lists the files, addresses and readers.
;
; The range also holds three addresses that mean RAM bank 1 code: the music the entry copies to $C000 there; their
; @bank lines name them so these bytes stay data.
; --------------------------------------------------------------------------------------------------------------------

  ORG $AF64

; The zones' maps: rows of 8 tile numbers (32 x 4 chars), one map a zone, zone
; after zone
;
; DrawZone $AD5A draws 11 tile rows from map + (map row AND $FC) * 2: each byte
; a tile number, each tile 4 x 4 char codes from Tiles. The zone record +1-2
; points at the map. A map row is 4 char rows: the zone's map row variable
; $ADB7 counts char rows.
LevelMaps:
Level1Map:
  INCBIN "res/levels/maps.bin",$0000,120
Level1Map2:
  INCBIN "res/levels/maps.bin",$0078,216
Level1Map3:
  INCBIN "res/levels/maps.bin",$0150,72
Level1Map4:
  INCBIN "res/levels/maps.bin",$0198,264
Level1Map5:
  INCBIN "res/levels/maps.bin",$02A0,168
Level1Map6:
  INCBIN "res/levels/maps.bin",$0348,120
Level2Map:
  INCBIN "res/levels/maps.bin",$03C0,256
Level2Map2:
  INCBIN "res/levels/maps.bin",$04C0,200
Level2Map3:
  INCBIN "res/levels/maps.bin",$0588,120
Level2Map4:
  INCBIN "res/levels/maps.bin",$0600,104
Level2Map5:
  INCBIN "res/levels/maps.bin",$0668,112
Level2Map6:
  INCBIN "res/levels/maps.bin",$06D8,208
Level2Map7:
  INCBIN "res/levels/maps.bin",$07A8,288
Level3Map:
  INCBIN "res/levels/maps.bin",$08C8,144
Level3Map2:
  INCBIN "res/levels/maps.bin",$0958,80
Level3Map3:
  INCBIN "res/levels/maps.bin",$09A8,80
Level3Map4:
  INCBIN "res/levels/maps.bin",$09F8,176
Level3Map5:
  INCBIN "res/levels/maps.bin",$0AA8,128
Level3Map6:
  INCBIN "res/levels/maps.bin",$0B28,80
Level3Map7:
  INCBIN "res/levels/maps.bin",$0B78,176
Level3Map8:
  INCBIN "res/levels/maps.bin",$0C28,80
Level3Map9:
  INCBIN "res/levels/maps.bin",$0C78,176
Level3Map10:
  INCBIN "res/levels/maps.bin",$0D28,80
Level3Map11:
  INCBIN "res/levels/maps.bin",$0D78,128
Level3Map12:
  INCBIN "res/levels/maps.bin",$0DF8,120
Level4Map:
  INCBIN "res/levels/maps.bin",$0E70,96
Level4Map2:
  INCBIN "res/levels/maps.bin",$0ED0,224
Level4Map3:
  INCBIN "res/levels/maps.bin",$0FB0,80
Level4Map4:
  INCBIN "res/levels/maps.bin",$1000,224
Level4Map5:
  INCBIN "res/levels/maps.bin",$10E0,80
Level4Map6:
  INCBIN "res/levels/maps.bin",$1130,224
Level4Map7:
  INCBIN "res/levels/maps.bin",$1210,80
Level4Map8:
  INCBIN "res/levels/maps.bin",$1260,224
Level4Map9:
  INCBIN "res/levels/maps.bin",$1340,120

; 256 tiles of 4 x 4 char codes (16 bytes: 4 rows of 4), read by $AD76
;
; Tile T is at $C31C + 16T: rows top to bottom, 4 char codes a row. The char
; codes index the zone's char set (zone +0: set 0 bitmaps $7100 attributes
; $7900, set 1 bitmaps $7A00 attributes $8200).
Tiles:
  INCBIN "res/levels/tiles.bin",$0000,4096

; 72 object kinds, 8 bytes each, indexed by an object record's kind (+1)
;
; SpawnObjects $FD7D copies, for kind K at $D31C + 8K: +0 to slot +7, +1 to
; slot +8, +2-3 (the animation list, AnimLists, or a graphic address
; $6A80-$914B for kinds 4-21) to slot +4/+5 and +$12/+$13, +4-5 (the movement
; script, ObjectScripts; 0 for kinds 0-23) to slot +$14/+$15. $F7C3 reads +6
; and +7 ($D322 + 8K). Kinds 0, 2, 3 and 71 are all zero. The meaning of +0,
; +1, +6 and +7 (sizes and hit boxes, it seems) is known only from the code.
ObjectKinds:
  INCBIN "res/levels/kinds.bin",$0000,576

; The 34 zones, 7 bytes: +0 char set, +1-2 map, +3-4 exits, +5-6 object list
;
; EnterZone $AC83 (IX = the record, C = the map row): +0 = 0 char set 0, else
; set 1 (attributes $79 or $82 patched into $A853 and $AA80); +1-2 the map
; ($ADB5); +3-4 the exit list (the operand of $AB93); +5-6 the object list (the
; operand of $FD7D). Levels 1-2 use set 0, levels 3-4 set 1.
Zones:
Level1Zones:
  INCBIN "res/levels/zones.bin",$0000,42
Level2Zones:
  INCBIN "res/levels/zones.bin",$002A,49
Level3Zones:
  INCBIN "res/levels/zones.bin",$005B,84
Level4Zones:
  INCBIN "res/levels/zones.bin",$00AF,63

; The exit lists, one a zone: 5-byte records, $FF ends a list
;
; CheckExit $AB93 runs when the player leaves the screen sideways ($FD62 = 0
; left, 1 right): a record matches when +0 is that side and the player's char
; row in the map is +1 to +1 + 2. +2-3 the zone entered ($FFFF: the level is
; complete, $ABD8), +4 the map row there that takes +1's place on the screen.
Exits:
Level1Exits:
  INCBIN "res/levels/exits.bin",$0000,66
Level2Exits:
  INCBIN "res/levels/exits.bin",$0042,77
Level3Exits:
  INCBIN "res/levels/exits.bin",$008F,192
Level4Exits:
  INCBIN "res/levels/exits.bin",$014F,99

; The object lists, one a zone: 5-byte records in map row order, then $FF and
; "term"
;
; SpawnObjects $FD7D (D = the first map row, E = the rows) starts at the first
; record whose +0 is D or more and spawns while +0 < D + E. +0 the map char row
; (bits 3-7) ; +1 the kind (ObjectKinds; bit 7 set: taken, never spawned again;
; NewGame $E2DC clears bit 7 of all 365 records from $D7FD); +2 flags (bit 1:
; the one special slot $EA8E, bit 2: slot +0 bit 7, the whole byte to slot
; +$0B); +3 the x (bits 3-7) and a row offset (bits 0-2); +4 a second x (bits
; 3-7) and row offset (bits 0-2), slot +$0C/+$1D.
;
; Each list ends with $FF and the 4 bytes "term", a 5-byte record of its own:
; the RES 7 loop steps over it.
Objects:
Level1Objects:
  INCBIN "res/levels/objects.bin",$0000,285
Level2Objects:
  INCBIN "res/levels/objects.bin",$011D,460
Level3Objects:
  INCBIN "res/levels/objects.bin",$02E9,545
Level4Objects:
  INCBIN "res/levels/objects.bin",$050A,535

; Animation lists: frame bytes, $FF wraps to the first; pointed at by
; ObjectKinds +2-3
;
; $EE0B steps slot +$18 through the list: a frame byte, $FF = back to the
; start, 0 = no picture; bit 7 goes to slot +6 (known only from the code: a
; mirror flag, it seems), bits 0-6 pick the graphic.
AnimLists:
  INCBIN "res/levels/anims.bin",$0000,102

; Movement scripts: 3-byte steps (frames, dx, dy), $FF ends; ObjectKinds +4-5
;
; $EE81 counts slot +$19 up to the step's frames, adding the signed dx to x
; (slot +1) and dy to y each frame; at a frames byte $FF the object is removed
; (slot +$0B bit 0, when $FD68 is 0) or restarts at its spawn place.
ObjectScripts:
  INCBIN "res/levels/scripts.bin",$0000,662
