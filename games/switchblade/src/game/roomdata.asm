; --------------------------------------------------------------------------------------------------------------------
; roomdata.asm: The packed rooms
;
; The 127 rooms, one record each, found through the room table `$7100` (word 2 x room): a header byte (the counts of
; the three placement groups), the placements (2 bytes each), the command list (a byte: code in the low nibble, repeat
; in the high nibble, then the operands; code `$F` ends it), then the reveal zones, a counts byte (enemies << 4 |
; pickups), the pickups and the enemy starts (2 bytes each). BuildMap `$9F63` turns the first part into the cell
; planes `$6700-$6CFF`, RoomObjects `$A41E` reads the rest. Rooms 122 and 123 share one record; room 0's pointer
; `$C9F0` points into room 103 (no room 0 is ever built). The format: ROOM.md.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A928

; Room 1: map row 0, column 0; 4 placements, 2 zone records, 2 pickups, 7
; enemies
;
; 85 bytes `$A928-$A97C`. Header `$12`. The room above: none.
Room1:
  INCBIN "res/rooms/rooms.bin",$0000,85

; Room 2: map row 0, column 1; 3 placements, 2 zone records, 3 pickups, 2
; enemies
;
; 51 bytes `$A97D-$A9AF`. Header `$11`. The room above: none.
Room2:
  INCBIN "res/rooms/rooms.bin",$0055,51

; Room 3: map row 0, column 2; 0 placements, the default zone, 0 pickups, 0
; enemies
;
; 22 bytes `$A9B0-$A9C5`. Header `$00`. The room above: none.
Room3:
  INCBIN "res/rooms/rooms.bin",$0088,22

; Room 4: map row 0, column 3; 0 placements, the default zone, 1 pickup, 0
; enemies
;
; 18 bytes `$A9C6-$A9D7`. Header `$00`. The room above: none.
Room4:
  INCBIN "res/rooms/rooms.bin",$009E,18

; Room 5: map row 0, column 4; 0 placements, the default zone, 0 pickups, 1
; enemy
;
; 12 bytes `$A9D8-$A9E3`. Header `$00`. The room above: none.
Room5:
  INCBIN "res/rooms/rooms.bin",$00B0,12

; Room 6: map row 0, column 5; 0 placements, the default zone, 1 pickup, 2
; enemies
;
; 30 bytes `$A9E4-$AA01`. Header `$00`. The room above: none.
Room6:
  INCBIN "res/rooms/rooms.bin",$00BC,30

; Room 7: map row 0, column 6; 0 placements, the default zone, 0 pickups, 2
; enemies
;
; 21 bytes `$AA02-$AA16`. Header `$00`. The room above: none.
Room7:
  INCBIN "res/rooms/rooms.bin",$00DA,21

; Room 8: map row 0, column 7; 2 placements, 2 zone records, 0 pickups, 1 enemy
;
; 46 bytes `$AA17-$AA44`. Header `$10`. The room above: none.
Room8:
  INCBIN "res/rooms/rooms.bin",$00EF,46

; Room 9: map row 1, column 7; 7 placements, 3 zone records, 3 pickups, 4
; enemies
;
; 74 bytes `$AA45-$AA8E`. Header `$15`. The room above: room 8 (its bottom row
; is built into cells `$EC-$FF`).
Room9:
  INCBIN "res/rooms/rooms.bin",$011D,74

; Room 10: map row 2, column 7; 10 placements, 2 zone records, 1 pickup, 3
; enemies
;
; 90 bytes `$AA8F-$AAE8`. Header `$57`. The room above: room 9 (its bottom row
; is built into cells `$EC-$FF`).
Room10:
  INCBIN "res/rooms/rooms.bin",$0167,90

; Room 11: map row 2, column 18; 9 placements, 3 zone records, 1 pickup, 10
; enemies
;
; 100 bytes `$AAE9-$AB4C`. Header `$5D`. The room above: none.
Room11:
  INCBIN "res/rooms/rooms.bin",$01C1,100

; Room 12: map row 2, column 19; 9 placements, 2 zone records, 5 pickups, 3
; enemies
;
; 91 bytes `$AB4D-$ABA7`. Header `$64`. The room above: none.
Room12:
  INCBIN "res/rooms/rooms.bin",$0225,91

; Room 13: map row 2, column 20; 8 placements, the default zone, 1 pickup, 4
; enemies
;
; 69 bytes `$ABA8-$ABEC`. Header `$0F`. The room above: none.
Room13:
  INCBIN "res/rooms/rooms.bin",$0280,69

; Room 14: map row 2, column 21; 13 placements, 3 zone records, 7 pickups, 5
; enemies
;
; 116 bytes `$ABED-$AC60`. Header `$76`. The room above: none.
Room14:
  INCBIN "res/rooms/rooms.bin",$02C5,116

; Room 15: map row 3, column 5; 9 placements, 2 zone records, 4 pickups, 3
; enemies
;
; 99 bytes `$AC61-$ACC3`. Header `$87`. The room above: none.
Room15:
  INCBIN "res/rooms/rooms.bin",$0339,99

; Room 16: map row 3, column 6; 9 placements, 3 zone records, 2 pickups, 3
; enemies
;
; 87 bytes `$ACC4-$AD1A`. Header `$56`. The room above: none.
Room16:
  INCBIN "res/rooms/rooms.bin",$039C,87

; Room 17: map row 3, column 7; 10 placements, 4 zone records, 2 pickups, 3
; enemies
;
; 105 bytes `$AD1B-$AD83`. Header `$57`. The room above: room 10 (its bottom
; row is built into cells `$EC-$FF`).
Room17:
  INCBIN "res/rooms/rooms.bin",$03F3,105

; Room 18: map row 3, column 18; 8 placements, 2 zone records, 1 pickup, 7
; enemies
;
; 88 bytes `$AD84-$ADDB`. Header `$55`. The room above: room 11 (its bottom row
; is built into cells `$EC-$FF`).
Room18:
  INCBIN "res/rooms/rooms.bin",$045C,88

; Room 19: map row 3, column 21; 10 placements, 2 zone records, 3 pickups, 4
; enemies
;
; 80 bytes `$ADDC-$AE2B`. Header `$9D`. The room above: room 14 (its bottom row
; is built into cells `$EC-$FF`).
Room19:
  INCBIN "res/rooms/rooms.bin",$04B4,80

; Room 20: map row 4, column 7; 9 placements, 2 zone records, 5 pickups, 3
; enemies
;
; 100 bytes `$AE2C-$AE8F`. Header `$25`. The room above: room 17 (its bottom
; row is built into cells `$EC-$FF`).
Room20:
  INCBIN "res/rooms/rooms.bin",$0504,100

; Room 21: map row 4, column 10; 6 placements, 2 zone records, 2 pickups, 3
; enemies
;
; 70 bytes `$AE90-$AED5`. Header `$1B`. The room above: none.
Room21:
  INCBIN "res/rooms/rooms.bin",$0568,70

; Room 22: map row 4, column 15; 6 placements, 2 zone records, 1 pickup, 4
; enemies
;
; 78 bytes `$AED6-$AF23`. Header `$53`. The room above: none.
Room22:
  INCBIN "res/rooms/rooms.bin",$05AE,78

; Room 23: map row 4, column 16; 14 placements, 2 zone records, 3 pickups, 3
; enemies
;
; 74 bytes `$AF24-$AF6D`. Header `$3F`. The room above: none.
Room23:
  INCBIN "res/rooms/rooms.bin",$05FC,74

; Room 24: map row 4, column 17; 11 placements, 3 zone records, 0 pickups, 7
; enemies
;
; 101 bytes `$AF6E-$AFD2`. Header `$27`. The room above: none.
Room24:
  INCBIN "res/rooms/rooms.bin",$0646,101

; Room 25: map row 4, column 18; 11 placements, 2 zone records, 1 pickup, 8
; enemies
;
; 101 bytes `$AFD3-$B037`. Header `$6D`. The room above: room 18 (its bottom
; row is built into cells `$EC-$FF`).
Room25:
  INCBIN "res/rooms/rooms.bin",$06AB,101

; Room 26: map row 4, column 20; 14 placements, 2 zone records, 1 pickup, 7
; enemies
;
; 86 bytes `$B038-$B08D`. Header `$7E`. The room above: none.
Room26:
  INCBIN "res/rooms/rooms.bin",$0710,86

; Room 27: map row 4, column 21; 10 placements, 3 zone records, 0 pickups, 5
; enemies
;
; 80 bytes `$B08E-$B0DD`. Header `$65`. The room above: room 19 (its bottom row
; is built into cells `$EC-$FF`).
Room27:
  INCBIN "res/rooms/rooms.bin",$0766,80

; Room 28: map row 5, column 7; 12 placements, 3 zone records, 2 pickups, 4
; enemies
;
; 105 bytes `$B0DE-$B146`. Header `$2F`. The room above: room 20 (its bottom
; row is built into cells `$EC-$FF`).
Room28:
  INCBIN "res/rooms/rooms.bin",$07B6,105

; Room 29: map row 5, column 8; 9 placements, 2 zone records, 3 pickups, 8
; enemies
;
; 87 bytes `$B147-$B19D`. Header `$64`. The room above: none.
Room29:
  INCBIN "res/rooms/rooms.bin",$081F,87

; Room 30: map row 5, column 9; 12 placements, 2 zone records, 1 pickup, 7
; enemies
;
; 86 bytes `$B19E-$B1F3`. Header `$67`. The room above: none.
Room30:
  INCBIN "res/rooms/rooms.bin",$0876,86

; Room 31: map row 5, column 10; 9 placements, 2 zone records, 3 pickups, 5
; enemies
;
; 94 bytes `$B1F4-$B251`. Header `$25`. The room above: room 21 (its bottom row
; is built into cells `$EC-$FF`).
Room31:
  INCBIN "res/rooms/rooms.bin",$08CC,94

; Room 32: map row 5, column 15; 3 placements, the default zone, 2 pickups, 3
; enemies
;
; 81 bytes `$B252-$B2A2`. Header `$0A`. The room above: room 22 (its bottom row
; is built into cells `$EC-$FF`).
Room32:
  INCBIN "res/rooms/rooms.bin",$092A,81

; Room 33: map row 5, column 18; 13 placements, 2 zone records, 2 pickups, 5
; enemies
;
; 95 bytes `$B2A3-$B301`. Header `$7D`. The room above: room 25 (its bottom row
; is built into cells `$EC-$FF`).
Room33:
  INCBIN "res/rooms/rooms.bin",$097B,95

; Room 34: map row 5, column 19; 9 placements, 2 zone records, 3 pickups, 3
; enemies
;
; 85 bytes `$B302-$B356`. Header `$6B`. The room above: none.
Room34:
  INCBIN "res/rooms/rooms.bin",$09DA,85

; Room 35: map row 5, column 20; 11 placements, 2 zone records, 0 pickups, 6
; enemies
;
; 89 bytes `$B357-$B3AF`. Header `$74`. The room above: room 26 (its bottom row
; is built into cells `$EC-$FF`).
Room35:
  INCBIN "res/rooms/rooms.bin",$0A2F,89

; Room 36: map row 6, column 7; 5 placements, the default zone, 6 pickups, 3
; enemies
;
; 80 bytes `$B3B0-$B3FF`. Header `$59`. The room above: room 28 (its bottom row
; is built into cells `$EC-$FF`).
Room36:
  INCBIN "res/rooms/rooms.bin",$0A88,80

; Room 37: map row 6, column 10; 10 placements, 2 zone records, 2 pickups, 5
; enemies
;
; 104 bytes `$B400-$B467`. Header `$1F`. The room above: room 31 (its bottom
; row is built into cells `$EC-$FF`).
Room37:
  INCBIN "res/rooms/rooms.bin",$0AD8,104

; Room 38: map row 6, column 11; 12 placements, 3 zone records, 5 pickups, 3
; enemies
;
; 101 bytes `$B468-$B4CC`. Header `$67`. The room above: none.
Room38:
  INCBIN "res/rooms/rooms.bin",$0B40,101

; Room 39: map row 6, column 12; 11 placements, the default zone, 2 pickups, 2
; enemies
;
; 76 bytes `$B4CD-$B518`. Header `$2E`. The room above: none.
Room39:
  INCBIN "res/rooms/rooms.bin",$0BA5,76

; Room 40: map row 6, column 13; 9 placements, 2 zone records, 2 pickups, 5
; enemies
;
; 86 bytes `$B519-$B56E`. Header `$64`. The room above: none.
Room40:
  INCBIN "res/rooms/rooms.bin",$0BF1,86

; Room 41: map row 6, column 14; 7 placements, 2 zone records, 2 pickups, 3
; enemies
;
; 94 bytes `$B56F-$B5CC`. Header `$07`. The room above: none.
Room41:
  INCBIN "res/rooms/rooms.bin",$0C47,94

; Room 42: map row 6, column 15; 10 placements, 3 zone records, 2 pickups, 3
; enemies
;
; 93 bytes `$B5CD-$B629`. Header `$3B`. The room above: room 32 (its bottom row
; is built into cells `$EC-$FF`).
Room42:
  INCBIN "res/rooms/rooms.bin",$0CA5,93

; Room 43: map row 6, column 19; 9 placements, the default zone, 1 pickup, 5
; enemies
;
; 83 bytes `$B62A-$B67C`. Header `$2C`. The room above: room 34 (its bottom row
; is built into cells `$EC-$FF`).
Room43:
  INCBIN "res/rooms/rooms.bin",$0D02,83

; Room 44: map row 6, column 20; 12 placements, 3 zone records, 3 pickups, 4
; enemies
;
; 95 bytes `$B67D-$B6DB`. Header `$A6`. The room above: room 35 (its bottom row
; is built into cells `$EC-$FF`).
Room44:
  INCBIN "res/rooms/rooms.bin",$0D55,95

; Room 45: map row 6, column 21; 10 placements, 2 zone records, 2 pickups, 7
; enemies
;
; 84 bytes `$B6DC-$B72F`. Header `$7A`. The room above: none.
Room45:
  INCBIN "res/rooms/rooms.bin",$0DB4,84

; Room 46: map row 6, column 22; 12 placements, 3 zone records, 0 pickups, 9
; enemies
;
; 125 bytes `$B730-$B7AC`. Header `$B4`. The room above: none.
Room46:
  INCBIN "res/rooms/rooms.bin",$0E08,125

; Room 47: map row 7, column 7; 7 placements, the default zone, 3 pickups, 5
; enemies
;
; 72 bytes `$B7AD-$B7F4`. Header `$0E`. The room above: room 36 (its bottom row
; is built into cells `$EC-$FF`).
Room47:
  INCBIN "res/rooms/rooms.bin",$0E85,72

; Room 48: map row 7, column 8; 4 placements, the default zone, 1 pickup, 5
; enemies
;
; 49 bytes `$B7F5-$B825`. Header `$12`. The room above: none.
Room48:
  INCBIN "res/rooms/rooms.bin",$0ECD,49

; Room 49: map row 7, column 9; 13 placements, 3 zone records, 2 pickups, 6
; enemies
;
; 104 bytes `$B826-$B88D`. Header `$A7`. The room above: none.
Room49:
  INCBIN "res/rooms/rooms.bin",$0EFE,104

; Room 50: map row 7, column 10; 12 placements, 3 zone records, 4 pickups, 4
; enemies
;
; 99 bytes `$B88E-$B8F0`. Header `$BB`. The room above: room 37 (its bottom row
; is built into cells `$EC-$FF`).
Room50:
  INCBIN "res/rooms/rooms.bin",$0F66,99

; Room 51: map row 7, column 14; 16 placements, 4 zone records, 5 pickups, 9
; enemies
;
; 138 bytes `$B8F1-$B97A`. Header `$BF`. The room above: room 41 (its bottom
; row is built into cells `$EC-$FF`).
Room51:
  INCBIN "res/rooms/rooms.bin",$0FC9,138

; Room 52: map row 7, column 18; 8 placements, the default zone, 1 pickup, 3
; enemies
;
; 75 bytes `$B97B-$B9C5`. Header `$2B`. The room above: none.
Room52:
  INCBIN "res/rooms/rooms.bin",$1053,75

; Room 53: map row 7, column 19; 5 placements, the default zone, 1 pickup, 0
; enemies
;
; 52 bytes `$B9C6-$B9F9`. Header `$4B`. The room above: room 43 (its bottom row
; is built into cells `$EC-$FF`).
Room53:
  INCBIN "res/rooms/rooms.bin",$109E,52

; Room 54: map row 7, column 22; 7 placements, 2 zone records, 0 pickups, 2
; enemies
;
; 44 bytes `$B9FA-$BA25`. Header `$38`. The room above: room 46 (its bottom row
; is built into cells `$EC-$FF`).
Room54:
  INCBIN "res/rooms/rooms.bin",$10D2,44

; Room 55: map row 7, column 23; 8 placements, the default zone, 1 pickup, 4
; enemies
;
; 58 bytes `$BA26-$BA5F`. Header `$6A`. The room above: none.
Room55:
  INCBIN "res/rooms/rooms.bin",$10FE,58

; Room 56: map row 8, column 13; 13 placements, 3 zone records, 3 pickups, 4
; enemies
;
; 106 bytes `$BA60-$BAC9`. Header `$76`. The room above: none.
Room56:
  INCBIN "res/rooms/rooms.bin",$1138,106

; Room 57: map row 8, column 14; 12 placements, 3 zone records, 2 pickups, 3
; enemies
;
; 102 bytes `$BACA-$BB2F`. Header `$67`. The room above: room 51 (its bottom
; row is built into cells `$EC-$FF`).
Room57:
  INCBIN "res/rooms/rooms.bin",$11A2,102

; Room 58: map row 8, column 18; 11 placements, 3 zone records, 2 pickups, 4
; enemies
;
; 113 bytes `$BB30-$BBA0`. Header `$6D`. The room above: room 52 (its bottom
; row is built into cells `$EC-$FF`).
Room58:
  INCBIN "res/rooms/rooms.bin",$1208,113

; Room 59: map row 8, column 19; 13 placements, 2 zone records, 1 pickup, 11
; enemies
;
; 114 bytes `$BBA1-$BC12`. Header `$6F`. The room above: room 53 (its bottom
; row is built into cells `$EC-$FF`).
Room59:
  INCBIN "res/rooms/rooms.bin",$1279,114

; Room 60: map row 8, column 20; 9 placements, 2 zone records, 2 pickups, 10
; enemies
;
; 110 bytes `$BC13-$BC80`. Header `$A3`. The room above: none.
Room60:
  INCBIN "res/rooms/rooms.bin",$12EB,110

; Room 61: map row 8, column 21; 11 placements, 2 zone records, 1 pickup, 11
; enemies
;
; 108 bytes `$BC81-$BCEC`. Header `$97`. The room above: none.
Room61:
  INCBIN "res/rooms/rooms.bin",$1359,108

; Room 62: map row 8, column 22; 6 placements, the default zone, 1 pickup, 5
; enemies
;
; 92 bytes `$BCED-$BD48`. Header `$14`. The room above: room 54 (its bottom row
; is built into cells `$EC-$FF`).
Room62:
  INCBIN "res/rooms/rooms.bin",$13C5,92

; Room 63: map row 9, column 12; 9 placements, the default zone, 0 pickups, 6
; enemies
;
; 86 bytes `$BD49-$BD9E`. Header `$72`. The room above: none.
Room63:
  INCBIN "res/rooms/rooms.bin",$1421,86

; Room 64: map row 9, column 16; 4 placements, the default zone, 0 pickups, 2
; enemies
;
; 46 bytes `$BD9F-$BDCC`. Header `$0B`. The room above: none.
Room64:
  INCBIN "res/rooms/rooms.bin",$1477,46

; Room 65: map row 9, column 17; 5 placements, the default zone, 1 pickup, 2
; enemies
;
; 42 bytes `$BDCD-$BDF6`. Header `$52`. The room above: none.
Room65:
  INCBIN "res/rooms/rooms.bin",$14A5,42

; Room 66: map row 9, column 18; 9 placements, the default zone, 1 pickup, 2
; enemies
;
; 48 bytes `$BDF7-$BE26`. Header `$64`. The room above: room 58 (its bottom row
; is built into cells `$EC-$FF`).
Room66:
  INCBIN "res/rooms/rooms.bin",$14CF,48

; Room 67: map row 10, column 12; 9 placements, 2 zone records, 1 pickup, 4
; enemies
;
; 68 bytes `$BE27-$BE6A`. Header `$9C`. The room above: room 63 (its bottom row
; is built into cells `$EC-$FF`).
Room67:
  INCBIN "res/rooms/rooms.bin",$14FF,68

; Room 68: map row 10, column 14; 7 placements, 2 zone records, 2 pickups, 5
; enemies
;
; 68 bytes `$BE6B-$BEAE`. Header `$62`. The room above: none.
Room68:
  INCBIN "res/rooms/rooms.bin",$1543,68

; Room 69: map row 10, column 15; 8 placements, 3 zone records, 7 pickups, 6
; enemies
;
; 91 bytes `$BEAF-$BF09`. Header `$55`. The room above: none.
Room69:
  INCBIN "res/rooms/rooms.bin",$1587,91

; Room 70: map row 10, column 16; 10 placements, the default zone, 0 pickups, 8
; enemies
;
; 78 bytes `$BF0A-$BF57`. Header `$26`. The room above: room 64 (its bottom row
; is built into cells `$EC-$FF`).
Room70:
  INCBIN "res/rooms/rooms.bin",$15E2,78

; Room 71: map row 11, column 12; 2 placements, the default zone, 0 pickups, 4
; enemies
;
; 47 bytes `$BF58-$BF86`. Header `$02`. The room above: room 67 (its bottom row
; is built into cells `$EC-$FF`).
Room71:
  INCBIN "res/rooms/rooms.bin",$1630,47

; Room 72: map row 11, column 14; 11 placements, 2 zone records, 2 pickups, 8
; enemies
;
; 87 bytes `$BF87-$BFDD`. Header `$5F`. The room above: room 68 (its bottom row
; is built into cells `$EC-$FF`).
Room72:
  INCBIN "res/rooms/rooms.bin",$165F,87

; Room 73: map row 11, column 19; 4 placements, 2 zone records, 0 pickups, 7
; enemies
;
; 97 bytes `$BFDE-$C03E`. Header `$0B`. The room above: none.
Room73:
  INCBIN "res/rooms/rooms.bin",$16B6,97

; Room 74: map row 11, column 20; 5 placements, the default zone, 2 pickups, 5
; enemies
;
; 56 bytes `$C03F-$C076`. Header `$05`. The room above: none.
Room74:
  INCBIN "res/rooms/rooms.bin",$1717,56

; Room 75: map row 11, column 21; 3 placements, 2 zone records, 2 pickups, 11
; enemies
;
; 108 bytes `$C077-$C0E2`. Header `$03`. The room above: none.
Room75:
  INCBIN "res/rooms/rooms.bin",$174F,108

; Room 76: map row 11, column 22; 6 placements, 3 zone records, 6 pickups, 3
; enemies
;
; 112 bytes `$C0E3-$C152`. Header `$0D`. The room above: none.
Room76:
  INCBIN "res/rooms/rooms.bin",$17BB,112

; Room 77: map row 11, column 23; 2 placements, the default zone, 2 pickups, 8
; enemies
;
; 68 bytes `$C153-$C196`. Header `$02`. The room above: none.
Room77:
  INCBIN "res/rooms/rooms.bin",$182B,68

; Room 78: map row 11, column 24; 5 placements, the default zone, 3 pickups, 7
; enemies
;
; 89 bytes `$C197-$C1EF`. Header `$0C`. The room above: none.
Room78:
  INCBIN "res/rooms/rooms.bin",$186F,89

; Room 79: map row 11, column 25; 3 placements, 3 zone records, 3 pickups, 4
; enemies
;
; 91 bytes `$C1F0-$C24A`. Header `$03`. The room above: none.
Room79:
  INCBIN "res/rooms/rooms.bin",$18C8,91

; Room 80: map row 11, column 26; 0 placements, the default zone, 0 pickups, 12
; enemies
;
; 89 bytes `$C24B-$C2A3`. Header `$00`. The room above: none.
Room80:
  INCBIN "res/rooms/rooms.bin",$1923,89

; Room 81: map row 11, column 27; 2 placements, 2 zone records, 0 pickups, 4
; enemies
;
; 52 bytes `$C2A4-$C2D7`. Header `$02`. The room above: none.
Room81:
  INCBIN "res/rooms/rooms.bin",$197C,52

; Room 82: map row 11, column 28; 0 placements, 2 zone records, 2 pickups, 7
; enemies
;
; 66 bytes `$C2D8-$C319`. Header `$00`. The room above: none.
Room82:
  INCBIN "res/rooms/rooms.bin",$19B0,66

; Room 83: map row 11, column 29; 6 placements, 3 zone records, 2 pickups, 7
; enemies
;
; 85 bytes `$C31A-$C36E`. Header `$0D`. The room above: none.
Room83:
  INCBIN "res/rooms/rooms.bin",$19F2,85

; Room 84: map row 12, column 11; 13 placements, 3 zone records, 6 pickups, 4
; enemies
;
; 90 bytes `$C36F-$C3C8`. Header `$6F`. The room above: none.
Room84:
  INCBIN "res/rooms/rooms.bin",$1A47,90

; Room 85: map row 12, column 12; 9 placements, 3 zone records, 2 pickups, 5
; enemies
;
; 78 bytes `$C3C9-$C416`. Header `$25`. The room above: room 71 (its bottom row
; is built into cells `$EC-$FF`).
Room85:
  INCBIN "res/rooms/rooms.bin",$1AA1,78

; Room 86: map row 12, column 13; 9 placements, 3 zone records, 1 pickup, 12
; enemies
;
; 89 bytes `$C417-$C46F`. Header `$2C`. The room above: none.
Room86:
  INCBIN "res/rooms/rooms.bin",$1AEF,89

; Room 87: map row 12, column 14; 12 placements, 3 zone records, 2 pickups, 12
; enemies
;
; 94 bytes `$C470-$C4CD`. Header `$67`. The room above: room 72 (its bottom row
; is built into cells `$EC-$FF`).
Room87:
  INCBIN "res/rooms/rooms.bin",$1B48,94

; Room 88: map row 12, column 19; 9 placements, 3 zone records, 2 pickups, 5
; enemies
;
; 120 bytes `$C4CE-$C545`. Header `$17`. The room above: room 73 (its bottom
; row is built into cells `$EC-$FF`).
Room88:
  INCBIN "res/rooms/rooms.bin",$1BA6,120

; Room 89: map row 12, column 20; 2 placements, 2 zone records, 1 pickup, 3
; enemies
;
; 59 bytes `$C546-$C580`. Header `$02`. The room above: room 74 (its bottom row
; is built into cells `$EC-$FF`).
Room89:
  INCBIN "res/rooms/rooms.bin",$1C1E,59

; Room 90: map row 12, column 21; 5 placements, 2 zone records, 4 pickups, 4
; enemies
;
; 105 bytes `$C581-$C5E9`. Header `$0C`. The room above: room 75 (its bottom
; row is built into cells `$EC-$FF`).
Room90:
  INCBIN "res/rooms/rooms.bin",$1C59,105

; Room 91: map row 12, column 24; 5 placements, 2 zone records, 2 pickups, 11
; enemies
;
; 101 bytes `$C5EA-$C64E`. Header `$05`. The room above: room 78 (its bottom
; row is built into cells `$EC-$FF`).
Room91:
  INCBIN "res/rooms/rooms.bin",$1CC2,101

; Room 92: map row 12, column 25; 1 placement, 3 zone records, 2 pickups, 15
; enemies
;
; 129 bytes `$C64F-$C6CF`. Header `$08`. The room above: room 79 (its bottom
; row is built into cells `$EC-$FF`).
Room92:
  INCBIN "res/rooms/rooms.bin",$1D27,129

; Room 93: map row 12, column 27; 3 placements, 2 zone records, 0 pickups, 4
; enemies
;
; 72 bytes `$C6D0-$C717`. Header `$11`. The room above: room 81 (its bottom row
; is built into cells `$EC-$FF`).
Room93:
  INCBIN "res/rooms/rooms.bin",$1DA8,72

; Room 94: map row 12, column 28; 0 placements, the default zone, 2 pickups, 8
; enemies
;
; 53 bytes `$C718-$C74C`. Header `$00`. The room above: room 82 (its bottom row
; is built into cells `$EC-$FF`).
Room94:
  INCBIN "res/rooms/rooms.bin",$1DF0,53

; Room 95: map row 12, column 29; 4 placements, 2 zone records, 2 pickups, 6
; enemies
;
; 86 bytes `$C74D-$C7A2`. Header `$04`. The room above: room 83 (its bottom row
; is built into cells `$EC-$FF`).
Room95:
  INCBIN "res/rooms/rooms.bin",$1E25,86

; Room 96: map row 13, column 11; 14 placements, 3 zone records, 1 pickup, 5
; enemies
;
; 98 bytes `$C7A3-$C804`. Header `$77`. The room above: room 84 (its bottom row
; is built into cells `$EC-$FF`).
Room96:
  INCBIN "res/rooms/rooms.bin",$1E7B,98

; Room 97: map row 13, column 18; 5 placements, 3 zone records, 1 pickup, 8
; enemies
;
; 91 bytes `$C805-$C85F`. Header `$0C`. The room above: none.
Room97:
  INCBIN "res/rooms/rooms.bin",$1EDD,91

; Room 98: map row 13, column 19; 6 placements, 2 zone records, 4 pickups, 5
; enemies
;
; 85 bytes `$C860-$C8B4`. Header `$06`. The room above: room 88 (its bottom row
; is built into cells `$EC-$FF`).
Room98:
  INCBIN "res/rooms/rooms.bin",$1F38,85

; Room 99: map row 13, column 20; 1 placement, 2 zone records, 1 pickup, 4
; enemies
;
; 58 bytes `$C8B5-$C8EE`. Header `$08`. The room above: room 89 (its bottom row
; is built into cells `$EC-$FF`).
Room99:
  INCBIN "res/rooms/rooms.bin",$1F8D,58

; Room 100: map row 13, column 21; 2 placements, the default zone, 0 pickups, 5
; enemies
;
; 71 bytes `$C8EF-$C935`. Header `$02`. The room above: room 90 (its bottom row
; is built into cells `$EC-$FF`).
Room100:
  INCBIN "res/rooms/rooms.bin",$1FC7,71

; Room 101: map row 14, column 9; 8 placements, the default zone, 0 pickups, 3
; enemies
;
; 46 bytes `$C936-$C963`. Header `$6A`. The room above: none.
Room101:
  INCBIN "res/rooms/rooms.bin",$200E,46

; Room 102: map row 14, column 10; 10 placements, the default zone, 3 pickups,
; 4 enemies
;
; 71 bytes `$C964-$C9AA`. Header `$2D`. The room above: none.
Room102:
  INCBIN "res/rooms/rooms.bin",$203C,71

; Room 103: map row 14, column 11; 9 placements, 2 zone records, 1 pickup, 5
; enemies
;
; 92 bytes `$C9AB-$CA06`. Header `$AA`. The room above: room 96 (its bottom row
; is built into cells `$EC-$FF`). Room 0's entry of the room table `$7100`
; points at `$C9F0` inside this record (no room 0 is built).
Room103:
  INCBIN "res/rooms/rooms.bin",$2083,92

; Room 104: map row 14, column 14; 7 placements, 3 zone records, 2 pickups, 5
; enemies
;
; 79 bytes `$CA07-$CA55`. Header `$15`. The room above: none.
Room104:
  INCBIN "res/rooms/rooms.bin",$20DF,79

; Room 105: map row 14, column 15; 5 placements, 3 zone records, 2 pickups, 11
; enemies
;
; 103 bytes `$CA56-$CABC`. Header `$13`. The room above: none.
Room105:
  INCBIN "res/rooms/rooms.bin",$212E,103

; Room 106: map row 14, column 16; 5 placements, 3 zone records, 2 pickups, 8
; enemies
;
; 89 bytes `$CABD-$CB15`. Header `$0C`. The room above: none.
Room106:
  INCBIN "res/rooms/rooms.bin",$2195,89

; Room 107: map row 14, column 17; 5 placements, 3 zone records, 1 pickup, 7
; enemies
;
; 102 bytes `$CB16-$CB7B`. Header `$0C`. The room above: none.
Room107:
  INCBIN "res/rooms/rooms.bin",$21EE,102

; Room 108: map row 14, column 18; 6 placements, 3 zone records, 3 pickups, 4
; enemies
;
; 103 bytes `$CB7C-$CBE2`. Header `$06`. The room above: room 97 (its bottom
; row is built into cells `$EC-$FF`).
Room108:
  INCBIN "res/rooms/rooms.bin",$2254,103

; Room 109: map row 14, column 20; 5 placements, the default zone, 0 pickups, 0
; enemies
;
; 43 bytes `$CBE3-$CC0D`. Header `$05`. The room above: room 99 (its bottom row
; is built into cells `$EC-$FF`).
Room109:
  INCBIN "res/rooms/rooms.bin",$22BB,43

; Room 110: map row 15, column 11; 8 placements, 3 zone records, 2 pickups, 7
; enemies
;
; 92 bytes `$CC0E-$CC69`. Header `$16`. The room above: room 103 (its bottom
; row is built into cells `$EC-$FF`).
Room110:
  INCBIN "res/rooms/rooms.bin",$22E6,92

; Room 111: map row 15, column 12; 10 placements, 2 zone records, 3 pickups, 4
; enemies
;
; 82 bytes `$CC6A-$CCBB`. Header `$26`. The room above: none.
Room111:
  INCBIN "res/rooms/rooms.bin",$2342,82

; Room 112: map row 15, column 13; 10 placements, 2 zone records, 1 pickup, 4
; enemies
;
; 109 bytes `$CCBC-$CD28`. Header `$57`. The room above: none.
Room112:
  INCBIN "res/rooms/rooms.bin",$2394,109

; Room 113: map row 15, column 14; 4 placements, 3 zone records, 2 pickups, 11
; enemies
;
; 111 bytes `$CD29-$CD97`. Header `$0B`. The room above: room 104 (its bottom
; row is built into cells `$EC-$FF`).
Room113:
  INCBIN "res/rooms/rooms.bin",$2401,111

; Room 114: map row 15, column 20; 0 placements, the default zone, 2 pickups, 5
; enemies
;
; 64 bytes `$CD98-$CDD7`. Header `$00`. The room above: room 109 (its bottom
; row is built into cells `$EC-$FF`).
Room114:
  INCBIN "res/rooms/rooms.bin",$2470,64

; Room 115: map row 15, column 21; 0 placements, the default zone, 1 pickup, 5
; enemies
;
; 60 bytes `$CDD8-$CE13`. Header `$00`. The room above: none.
Room115:
  INCBIN "res/rooms/rooms.bin",$24B0,60

; Room 116: map row 15, column 22; 0 placements, the default zone, 3 pickups, 5
; enemies
;
; 78 bytes `$CE14-$CE61`. Header `$00`. The room above: none.
Room116:
  INCBIN "res/rooms/rooms.bin",$24EC,78

; Room 117: map row 15, column 23; 0 placements, the default zone, 0 pickups, 9
; enemies
;
; 77 bytes `$CE62-$CEAE`. Header `$00`. The room above: none.
Room117:
  INCBIN "res/rooms/rooms.bin",$253A,77

; Room 118: map row 15, column 24; 0 placements, the default zone, 1 pickup, 4
; enemies
;
; 57 bytes `$CEAF-$CEE7`. Header `$00`. The room above: none.
Room118:
  INCBIN "res/rooms/rooms.bin",$2587,57

; Room 119: map row 16, column 24; 0 placements, the default zone, 0 pickups, 4
; enemies
;
; 54 bytes `$CEE8-$CF1D`. Header `$00`. The room above: room 118 (its bottom
; row is built into cells `$EC-$FF`).
Room119:
  INCBIN "res/rooms/rooms.bin",$25C0,54

; Room 120: map row 17, column 24; 0 placements, the default zone, 0 pickups, 3
; enemies
;
; 47 bytes `$CF1E-$CF4C`. Header `$00`. The room above: room 119 (its bottom
; row is built into cells `$EC-$FF`).
Room120:
  INCBIN "res/rooms/rooms.bin",$25F6,47

; Room 121: map row 18, column 24; 0 placements, the default zone, 2 pickups, 2
; enemies
;
; 59 bytes `$CF4D-$CF87`. Header `$00`. The room above: room 120 (its bottom
; row is built into cells `$EC-$FF`).
Room121:
  INCBIN "res/rooms/rooms.bin",$2625,59

; Rooms 122 and 123 (one record): map row 19, column 19; map row 19, column 20;
; 0 placements, the default zone, 0 pickups, 1 enemy
;
; 41 bytes `$CF88-$CFB0`. Header `$00`. The room above: none. Room 123 is
; Havok's room: BuildSurface `$A039` treats it apart (only layer `$6B` from
; cell `$C8`).
Room122And123:
  INCBIN "res/rooms/rooms.bin",$2660,41

; Room 124: map row 19, column 21; 2 placements, 3 zone records, 0 pickups, 8
; enemies
;
; 122 bytes `$CFB1-$D02A`. Header `$02`. The room above: none.
Room124:
  INCBIN "res/rooms/rooms.bin",$2689,122

; Room 125: map row 19, column 22; 0 placements, the default zone, 1 pickup, 7
; enemies
;
; 60 bytes `$D02B-$D066`. Header `$00`. The room above: none.
Room125:
  INCBIN "res/rooms/rooms.bin",$2703,60

; Room 126: map row 19, column 23; 0 placements, the default zone, 1 pickup, 7
; enemies
;
; 62 bytes `$D067-$D0A4`. Header `$00`. The room above: none.
Room126:
  INCBIN "res/rooms/rooms.bin",$273F,62

; Room 127: map row 19, column 24; 0 placements, the default zone, 0 pickups, 4
; enemies
;
; 84 bytes `$D0A5-$D0F8`. Header `$00`. The room above: room 121 (its bottom
; row is built into cells `$EC-$FF`).
Room127:
  INCBIN "res/rooms/rooms.bin",$277D,84
