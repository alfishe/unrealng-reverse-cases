; --------------------------------------------------------------------------------------------------------------------
; vars.asm: The actor pages, the globals, the buffers
;
; One actor is one 256-byte page: the record is +$00..+$41; +$82..+$FF of the ten pages $5D00-$6600 hold the page
; tails (PageTailTemplate), the gap between is the spare rest. The room is six planes of 256 cells ($6700-$6CFF, cell
; = row x 20 + column, 220 cells; cells $EC-$FF a copy of the row above); the cells $DC-$EB of each plane hold the
; room's variables (the @var labels in the image).
; --------------------------------------------------------------------------------------------------------------------

  ORG $6B5C

; The page tails: ten rows of 126 bytes copied to +$82..+$FF of the pages
; $5D00-$6600; row 0 starts with the score table
;
; BuildPageTails `$5D07` copies row n to page `$5D` + n. The rows hold the
; actor kind templates (18 bytes each, pointed at by KindTemplates `$7200`),
; the size classes (`$6082`), the touch zones (`$5FAC`), the item records, and
; three pieces of code: SetTune/HavokRoomEnter/HavokRoomLeave (row 2, to
; `$5FC0`), TitleWhiteRows (row 8, to `$65EE`), and PauseGame, PendingMessage,
; RunBanner, ShowMessage (row 9, to `$6682-$66F6`), with TitleColours
; (`$66FA`).
;
; The bytes `$6F00-$7047` are copied first, then BuildPageTails overwrites them
; with the tables OutlineMask, RowBase and NameBoxPlaces.
;
; The template is cut into its tables, each a resource
; (src/res/tables/README.md), and the three pieces of code, kept as data rows.
; The first, here: the score records, 20 x 4 bytes (run time `$5D82` + 4 n):
; the score sprite and three BCD bytes of points (AddScore `$99E7`,
; tables/score-table.csv).
PageTailTemplate:
  INCBIN "res/tables/score-table.bin",$0000,80

; The pickup kinds' records (row 0 from run time $5DD2, row 1 from $5E82):
; frame, score record, two bytes
;
; KindTemplates `$7200` points the pickup kinds (below `$23`) here;
; CollectPickup `$98B6` and SetWeapon `$98F3` read them (tables/items.csv).
; `$6BD8-$6BD9` is spare.
ItemRecords:
  INCBIN "res/tables/items.bin",$0000,46
PageTail5E:
  INCBIN "res/tables/items.bin",$002E,2
RoomAbove:
  INCBIN "res/tables/items.bin",$0030,1
Room:
  INCBIN "res/tables/items.bin",$0031,2
StripStep:
  INCBIN "res/tables/items.bin",$0033,1
BackWallSet:
  INCBIN "res/tables/items.bin",$0034,1
FillRowStart:
  INCBIN "res/tables/items.bin",$0035,1
FillStopCell:
  INCBIN "res/tables/items.bin",$0036,1
CellProperty:
  INCBIN "res/tables/items.bin",$0037,83

; Walk frame lists (run time $5EDE): [n] then n frames, an actor's +$05
WalkLists:
  INCBIN "res/tables/walk-lists.bin",$0000,27

; The thrown weapons' records, kinds $40-$46 (run time $5EF9, $5F82-$5FAB): 7
; bytes patched into WeaponTemplate
WeaponRecords:
  INCBIN "res/tables/weapons.bin",$0000,7
PageTail5F:
  INCBIN "res/tables/weapons.bin",$0007,42

; The touch zones (run time TouchZones $5FAC): five of Y from, Y to, X from, X
; to, signed
TouchZoneRecords:
  INCBIN "res/tables/touch-zones.bin",$0000,20

; Code kept as data: run time $5FC0 SetTune, HavokRoomLeave $5FCB,
; HavokRoomEnter $5FD4 (57 bytes)
SetTuneCode:
  DEFB $32,$52,$84,$21,$DD,$6B,$7E,$FE
  DEFB $7B,$C0,$35,$3E,$FF,$32,$8F,$87
  DEFB $3E,$EB,$18,$01,$AF,$32,$EE,$5F
  DEFB $32,$F7,$5F,$21,$1D,$7F,$11,$00
  DEFB $6E,$06,$60,$CD,$EE,$5F,$21,$EB
  DEFB $80,$11,$00,$6D,$06,$90,$00,$7E
  DEFB $12,$36,$00,$23,$13,$10,$F8,$00
  DEFB $C9
  DEFB $00,$00,$00,$00,$00,$00,$00 ; spare (to $5FFF)

; Row 3 (to $6082-$60FF): the 24 sprite sets, SizeClasses $6082 at run time:
; half columns, rows, bytes a frame, address
;
; SpawnActor `$A65D` copies a set's five bytes to the actor's `+$15-+$19`
; (tables/sprite-sets.csv).
PageTail60:
  INCBIN "res/tables/sprite-sets.bin",$0000,42
HavokStashB:
  INCBIN "res/tables/sprite-sets.bin",$002A,78

; The last six bytes of row 3 (run time $60FA-$60FF): $18 $40 and four zeros,
; after the 24 sets
SpriteSetsTail:
  DEFB $18,$40,$00,$00,$00,$00

; Rows 4-8 (to $6182-$65FF): 34 actor templates of 18 bytes, copied to an
; actor's +$03..+$14 by SpawnActor
;
; KindTemplates `$7200` names the kinds of each (tables/actor-templates.csv);
; the run-time names WeaponTemplate, SharedEnemyTemplate, HiroTemplate and
; TitlePieceTemplate lie here.
PageTail61:
  INCBIN "res/tables/actor-templates.bin",$0000,126
PageTail62:
  INCBIN "res/tables/actor-templates.bin",$007E,44
TakenItems:
  INCBIN "res/tables/actor-templates.bin",$00AA,1
RevealedZones:
  INCBIN "res/tables/actor-templates.bin",$00AB,1
HavokStashA:
  INCBIN "res/tables/actor-templates.bin",$00AC,80
PageTail63:
  INCBIN "res/tables/actor-templates.bin",$00FC,126
PageTail64:
  INCBIN "res/tables/actor-templates.bin",$017A,48
GoneEnemies:
  INCBIN "res/tables/actor-templates.bin",$01AA,2
OutlineMask:
  INCBIN "res/tables/actor-templates.bin",$01AC,76
PageTail65:
  INCBIN "res/tables/actor-templates.bin",$01F8,108

; Code kept as data: run time $65EE: EXX; fill $59E0-$5ADF with $47; EXX; RET
TitleWhiteRowsCode:
  DEFB $D9,$21,$E0,$59,$01,$00,$01,$36
  DEFB $47,$5D,$54,$13,$ED,$B0,$D9,$C9
  DEFB $00,$00            ; spare

; Row 9, code kept as data: run time PauseGame $6682, PendingMessage $66B6,
; RunBanner $66BD, ShowMessage $66C8
PageTail66:
  DEFB $3A,$52,$66,$B7,$20,$29,$CD,$29
  DEFB $85,$FB,$20,$06,$CD,$1A,$83,$C3
  DEFB $4D,$5C,$3E,$03,$CD,$C8,$66,$CD
  DEFB $BD,$66,$01,$FE,$DF,$ED,$78,$E6
  DEFB $01,$FB,$06,$05,$76,$10,$FD,$20
  DEFB $F1,$01,$00,$40,$CD,$33,$83,$AF
  DEFB $32,$4C,$66,$C9,$CD,$C8
RowBase:
  DEFB $66,$AF,$32,$FF,$79,$21,$02,$66 ; built by GameEntry: the first cell of
  DEFB $CD,$2B,$8E,$7E                 ; each row, 0, 20 ... 220
NameBoxPlaces:
  DEFB $1F,$38,$F9,$C9,$F5,$21,$02,$66 ; built by GameEntry: 5 x 6 screen
  DEFB $7E,$1F,$30,$06,$CD,$A3,$97,$CD ; places (E, D)
  DEFB $BD,$66,$F1,$3D,$32,$63,$7B,$01
  DEFB $F0,$48,$11,$A6,$65,$AF,$CD,$5D
  DEFB $A6,$EB,$2E,$02,$36,$81,$CD,$2B
  DEFB $8E,$3A,$40,$66,$FE,$02,$20,$F6
  DEFB $C3,$30,$83

; The end of row 9 (run time $66F7-$66FF): the cell colours by plane nibble,
; the last six TitleColours
;
; The render's `$88BA` takes a revealed cell's attribute from CellColours
; `$66F7` by the high nibble of its plane `$6C` byte; TitleSequence `$A754`
; reads the last six (tables/cell-colours.csv).
CellColoursTemplate:
  INCBIN "res/tables/cell-colours.bin",$0000,9
