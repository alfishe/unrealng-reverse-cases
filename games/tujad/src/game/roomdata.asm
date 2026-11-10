; --------------------------------------------------------------------------------------------------------------------
; roomdata.asm: The world: the room layouts and the alien map
;
; Two tables of 128 rooms (8 across, 16 down: room + 1 is east, room + 8 south). Each starts with 128 words, the
; offset of the room's record from the table's start, then the records in room order. 102 rooms have records; the
; other 26 point at the empty layout $DB52 and the empty alien record $DFFA. The editable form is
; src/res/rooms/Rooms.txt (one section per room).
; --------------------------------------------------------------------------------------------------------------------

; The layout offsets: room n's tiles at RoomLayouts + RoomLayouts[n]
;
; DrawRoomLayout $6C93 reads it (L1 285 rooms drawn; 224 of the 256 bytes read,
; 560 reads). The offsets of the 102 full rooms rise in room order: the records
; are contiguous.
RoomLayouts:
  INCBIN "res/rooms/Rooms.bin",$0000,256

; The layouts: (column, row, tile) triples, ended by a byte with bit 7 set
; ($80)
;
; DrawRoomLayout $6C93 draws tile n (TileGraphics $6EA8, TileAttrs $6F36) with
; its top-left character at column, row (row from the top of the play area).
; L1: 7 343 of the 7 501 bytes read (19 362 reads; the rest are rooms no
; recording entered). The tiles of a room also make its cells (CellTable
; $60C0): bit 0 of a cell marks a wall.
RoomLayoutRecords:
  INCBIN "res/rooms/Rooms.bin",$0100,7500
EmptyLayout:
  INCBIN "res/rooms/Rooms.bin",$1E4C,1

; The alien map offsets: room n's record at AlienMap + the word at AlienMap +
; 2n
;
; RoomRecord $7B8F (L1 4 746 calls), DrawRoom (279), SaveRoomObjects $6ADC
; (276), the item pickup (50). L1: all 256 bytes read, 9 184 reads.
AlienMap:
  INCBIN "res/rooms/Rooms.bin",$1E4D,256

; The alien records: items, teleporter, enemies and objects of each room
;
; A record: item 1's position byte (0: none; else its kind follows), item 2's
; position (0 or position and kind), the teleporter's position (0 or position
; and target room), the enemy mask (bit k: enemy k may spawn here), object 1
; (0, or its 10-byte record as Objects holds it), object 2 (the same). A
; position byte is (column / 2) x 16 + the row in cells (ItemCell $6E88). The
; records change in play: ScrambleRooms $7BA0 moves the item kinds,
; SaveRoomObjects writes the objects back, a pickup zeroes a position; the
; image holds the start of a game as the authors saved it. L1: 937 of 941 bytes
; read (17 272 reads), 326 written (3 155 writes).
AlienRecords:
  INCBIN "res/rooms/Rooms.bin",$1F4D,935
EmptyAlienRecord:
  INCBIN "res/rooms/Rooms.bin",$22F4,6

; 2 zero bytes before the font; the scroller reads $E001 as line 0 of a space
;
; Interrupt $95D0 takes Font - 257 + 8 x code + ScrollLine, so line 0 of a
; character is the last line of the one before it; for a space that is $E001
; (L1 772 reads). $E000 is unread.
FontPad:
  DEFB $00,$00

; The font: 60 characters of 8 bytes, codes $20-$5B (space to '[')
;
; PrintText $8AB4 (LD BC,Font - 256: Font - $100 + 8 x code), the scroller
; (Font - 257 + 8 x code + the line). L1: 282 of the 480 bytes read (25 630
; reads); the characters no text uses stay unread.
Font:
  INCBIN "res/graphics/Font.bin",$0000,480

; The picture the ED pieces make: 50 tiles of 16 x 16 pixels (16 rows of 2
; bytes), 10 x 5
;
; Tile row x 10 + column. Piece n (kind $81 + n) is the tile at column (n - 1)
; / 5, row (n - 1) % 5, so EdFlags byte (n - 1) / 5 is a column of the picture
; and its bit (n - 1) % 5 the row. DrawItem $6E0D draws a piece lying in a room
; (LD HL,EdPieces - 352 at $6E34, then 32 a column and 320 a row; worked out
; for n = 1-50); ProgressScreen $8F53 draws the found tiles at $4886. L1: all 1
; 600 bytes read, 28 384 reads.
EdPieces:
  INCBIN "res/graphics/EdPieces.bin",$0000,1600

; The tile graphics: blocks of [width in bytes][height in pixel rows][width x
; height bytes, top row first]
;
; TileGraphics $6EA8 points at each tile's block; DrawRoomLayout draws them
; (DrawTilePixels $6CE8: the rows go down the screen, a byte column at a time;
; bytes over the HUD rows are skipped). The 70 blocks the table points at do
; not overlap and do not follow the tile order. Two parts no code reads: the 56
; zero bytes $F8A6-$F8DD between blocks, and the block of the 71st table word,
; $FDDC-$FDFD (2 x 16, a graphic no room uses: the word itself is never read),
; then 2 bytes $FDFE-$FDFF. L1: 4 728 of the 5 598 bytes read (479 258 reads);
; $FDDC-$FDFF: no access.
TileData:
  INCBIN "res/tiles/TileData.bin",$0000,5598
