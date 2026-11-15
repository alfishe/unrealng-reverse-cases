; --------------------------------------------------------------------------------------------------------------------
; zones.asm: The zone graphics: three parked sets of 256 characters and 256 attributes
;
; MASK III draws every room from one of four zones' character sets (zone = room table byte 4: 0 the base, 1 the lava
; caves, 2 the moon, 3 the last zone). The live set is at ZoneChars $E000 (2048 bytes) and ZoneAttrs $EF00 (256 bytes,
; bit 7 = solid, IsSolid $B993); SwapZone $A198 swaps it byte for byte with a parked set at $5B00 + $900 x (slot - 1),
; ZoneSlots $A194 telling which zone sits where.
;
; As loaded, zone 0 is live, zone 2 is parked at Zone2Chars $6400 and zone 3 at Zone3Chars $6D00. Zone 1's set at
; $5B00 is split by the loader, which itself lives at $5E00: its characters 160-255 are loaded here at Zone1CharsHigh
; $6000, characters 0-159 and the attributes wait at Zone1CharsLow $F000 and Zone1Attrs $EE00 until GameEntry $9100
; copies them down.
;
; The resources are PNG sheets of 16 characters a row (src/res/charsets/README.md) and the attributes as CSV.
; --------------------------------------------------------------------------------------------------------------------

; Zone 1's characters 160-255 (768 bytes), parked in the set at $5B00
;
; Read by SwapZone $A198 when a room of zone 1 is drawn. Witness: the RZX
; segments reach the lava caves (work/stage1/rec/rzx-*).
Zone1CharsHigh:
  INCBIN "res/charsets/zone1-high.bin",$0000,768

; 256 bytes overwritten at the entry by Zone1Attrs $EE00: an older copy of zone
; 1's attributes
;
; GameEntry $9100 copies Zone1Attrs $EE00 over these bytes before anything
; reads them; 255 of the 256 bytes equal the copy, only the first differs ($00
; here, $47 at $EE00). Leftover, known only from the code.
Zone1AttrsLeftover:
  INCBIN "res/leftovers/zone1-attrs-old.bin",$0000,256

; Zone 2's (the moon's) 256 characters, parked
Zone2Chars:
  INCBIN "res/charsets/zone2.bin",$0000,2048

; Zone 2's attributes
Zone2Attrs:
  INCBIN "res/charsets/zone2-attr.bin",$0000,256

; Zone 3's 256 characters, parked
Zone3Chars:
  INCBIN "res/charsets/zone3.bin",$0000,2048

; Zone 3's attributes
Zone3Attrs:
  INCBIN "res/charsets/zone3-attr.bin",$0000,256
