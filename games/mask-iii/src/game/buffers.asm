; --------------------------------------------------------------------------------------------------------------------
; buffers.asm: The live zone, the sprite characters and the buffers, with what the loader leaves in them
;
; $DF80-$FDFF are work space at run time. As loaded they hold zone 0's set (live), zone 1's first characters and
; attributes (copied down by GameEntry), and the play panel that the first game start draws; the rest are leftovers
; that are overwritten before any read (known only from the code).
; --------------------------------------------------------------------------------------------------------------------

; 128 bytes: Dissolve's frame
DissolveBuffer:
  DEFS $80

; The live zone's 256 characters: zone 0's as loaded
ZoneChars:
  INCBIN "res/charsets/zone0.bin",$0000,2048

; The sprite characters DrawObject allocates; as loaded 1536 bytes of leftovers
;
; DrawObject $A56F writes every sprite character from $E800 up before
; FlushDirty reads it; the loaded bytes are never read (known only from the
; code).
SpriteChars:
  INCBIN "res/leftovers/e800.bin",$0000,1536

; Zone 1's attributes, copied to $6300 by GameEntry; then the sprite
; characters' attributes
Zone1Attrs:
  INCBIN "res/charsets/zone1-attr.bin",$0000,256

; The live zone's attributes (bit 7 solid): zone 0's as loaded
ZoneAttrs:
  INCBIN "res/charsets/zone0-attr.bin",$0000,256

; Zone 1's characters 0-159, copied to $5B00 by GameEntry; then the masks, the
; character map ($F080) and the dirty map ($F3C0)
Zone1CharsLow:
MaskBuffer:
  INCBIN "res/charsets/zone1-low.bin",$0000,128
CharMap:
  INCBIN "res/charsets/zone1-low.bin",$0080,640
MirrorBuffer:
  INCBIN "res/charsets/zone1-low.bin",$0300,192
DirtyMap:
  INCBIN "res/charsets/zone1-low.bin",$03C0,320

; 256 bytes of leftovers, cleared as the dirty map before any read
LeftoverF500:
  INCBIN "res/leftovers/f500.bin",$0000,256

; The play panel (rows 18-23, 32 x 6 characters), drawn by Menu at the first
; start; then BuildTables' tables
PlayPanel:
BitReverse:
  INCBIN "res/screens/panel.bin",$0000,256
Dilate:
  INCBIN "res/screens/panel.bin",$0100,256
ShiftTables:
  INCBIN "res/screens/panel.bin",$0200,1024

; 100 bytes between the panel and its attributes (overwritten by BuildTables)
LeftoverFC00:
  INCBIN "res/leftovers/fc00.bin",$0000,100

; The panel's attributes, 6 rows of 32
PanelAttrs:
  INCBIN "res/screens/panel-attr.bin",$0000,192

; 220 bytes of leftovers, overwritten by BuildTables' shift tables
LeftoverFD24:
  INCBIN "res/leftovers/fd24.bin",$0000,220
