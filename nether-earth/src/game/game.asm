; Nether Earth, Argus Press Software 1987: the game image as the loader N1 leaves it ($4000-$FCE8, entry $A600).
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
RandomSeed     EQU $FD00  ; the shift register of Random, seeded $39,$30,$39,$30 by Start
PrintAddr      EQU $FD04  ; the screen address of the next printed character
MapView        EQU $FD06  ; the map byte at the view's left column: $DD00 + ViewX
SavedSP        EQU $FD08  ; SP kept while ClearViewBuffer pushes and while the menu music runs
ViewX          EQU $FD0A  ; the map column at the view's left edge, follows ShipX
Input          EQU $FD0C  ; the controls read this game turn: bit 0 right, 1 left, 2 down, 3 up, 4 fire, 5 save, 6 abort, 7 pause
ShipY          EQU $FD0D  ; the ship's row, 1-15
ShipX          EQU $FD0E  ; the ship's column, $000E-$01F5
Altitude       EQU $FD10  ; the ship's height: fire raises it by 2 to $30, released it sinks by 1 to what is under it
ShipDrawPos    EQU $FD11  ; the ship's view position while its drawing is deferred (column, row); 0 = not deferred
PrintAttr      EQU $FD13  ; the attribute of printed characters
PrintAttrAddr  EQU $FD14  ; the attribute address of the next printed character
PrintHeight    EQU $FD16  ; big characters: each font row printed this many times (PrintInline code 4, high nibble)
PrintWidth     EQU $FD17  ; big characters: the width in bytes, 0 normal (PrintInline code 4, low nibble)
RadarPhase     EQU $FD1A  ; toggled each frame: 0 shows the player's radar layer, 1 the enemy's
RadarLeft      EQU $FD1B  ; the radar window's left edge in units of 8 map columns, 0-$30
RadarColumn    EQU $FD1C  ; RadarLeft x 8: the radar window's first map column
RadarBlink     EQU $FD1E  ; bit 0: the ship's radar blip is drawn
MenuCursor     EQU $FD1F  ; the construction menu: the column (0 EXIT MENU, 1 START ROBOT, 2 the parts), the part row; the robot menu: its last item
MenuParts      EQU $FD21  ; the parts chosen, bit = part row; the new robot's +$07
Resources      EQU $FD22  ; general, electronics, nuclear, phasers, missiles, cannon, chassis
MenuResources  EQU $FD29  ; the copy the construction menu spends; back to Resources on START ROBOT
ClimbTurns     EQU $FD30  ; game turns the ship still climbs by itself: 3 at a new game, 5 after a menu
PrintColumn    EQU $FD31  ; the print position's column
PrintRow       EQU $FD32  ; the print position's row
TitleColourPhase EQU $FD33  ; 0-15, TitleColourCycle's frame counter
TurnFrames     EQU $FD34  ; frames counted by PlayInterrupt; a game turn waits for 10
Clock          EQU $FD35  ; minutes (by 5), hours, days (16 bits)
PanelBusy      EQU $FD39  ; 1 while a robot menu owns the right panel
PlayerBuildings EQU $FD3A  ; the player's buildings by type: warbases, then factories in the Resources order
PlayerRobotCount EQU $FD41  ; live robots in slots 0-23
EnemyBuildings EQU $FD42  ; the enemy's buildings, the same order; no warbase left = the game is won
EnemyRobotCount EQU $FD49  ; live robots in slots 24-47
EnemyResources EQU $FD4A  ; the enemy's resources, the order of Resources
Side           EQU $FD51  ; the side being processed: 0 the player's, 1 the enemy's
RadarDirty     EQU $FD52  ; 1: rebuild the radar layers from the map at the next ship mark
SoundFx        EQU $FD53  ; 1-$7F a falling tone (fire), $FC a miss, $FA a hit, $C8 a robot destroyed; PlayInterrupt counts it on
BassReturnPos  EQU $FD54  ; menu music: the bass track's return point
LeadReturnPos  EQU $FD56  ; menu music: the lead track's return point
Warbases       EQU $FD70  ; 4 capture points of 5 bytes: X (2), Y, owner (bit 6 player, 5 enemy, 7 destroyed) + type, turns a robot has stood at the door (144 captures)
Factories      EQU $FD84  ; 24 capture points of 5 bytes, the same shape
Handler        EQU $FDFE  ; the interrupt handler: the IM 2 vector's JP at $FDFD jumps here
Buildings      EQU $FF01  ; 56 records of 3 bytes: the map cell address, the type (0 a warbase pad, 1-6 factories, 7 the player's flag, 8 the enemy's)
  ORG $5B00

; The view's back buffer: 160 lines of 20 bytes (160 x 160 pixels)
;
; The isometric view is composed here and copied to the screen at $4021
; (character columns 1-20, rows 1-20) by CopyViewToScreen, an unrolled LDI x 20
; a pixel line. Line N is at $5B00 + 20 * N, top line first. ClearViewBuffer
; clears it (198 x 8 PUSHes from $6780 down, then $5B00-$5B1F by LDIR; SP saved
; in $FD08), FillViewCorner lays the black triangle above the map's back edge
; (runs of $FF, 10 bytes on the top 8 lines, 2 fewer each 8 lines) and
; DrawViewBackground the diagonal edges from ViewEdgeA / ViewEdgeB; DrawSprite
; blits every sprite into it (SpriteByteLoop: AND mask, OR graphic, the rows
; upward, 20 bytes a line). Other uses of the same bytes: ShowRobotDesign draws
; the robot preview of ConstructionMenu here and copies 4 bytes x 72 lines from
; $6168 to the screen at $48E0; NuclearFlash (the nuclear blast's flash) saves
; the view's 20 x 20 attributes into $5B00-$5C8F and puts them back; the tape
; save / load SaveGameBlocks / LoadGameBlocks keep the 2-byte checksum of the
; saved block at $5B00 (its first tape block).
;
; In the image it is zero up to $6731; $6732-$677F hold 78 bytes of leftovers
; of the loading (ROM addresses, a BASIC stack copy), never read before the
; first clear. The font index (PrintChar, PrintBigChar: $6680 + code x 8)
; starts inside this buffer: codes below $20 would take their glyphs from its
; last 256 bytes; no text prints them.
ViewBuffer:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$FF,$00,$00,$00
  DEFB $0D,$05,$23,$0D,$0D,$23,$05,$00,$00,$00,$00,$00,$01,$00,$06,$00,$0B,$00,$01,$00
  DEFB $01,$00,$06,$00,$10,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$3C,$40,$00,$FF,$CD,$00,$7C,$67,$00
  DEFB $00,$00,$00,$00,$FF,$FE,$FF,$03,$38,$00,$00,$CB,$5C,$00,$00,$B6,$5C,$BB,$5C,$CB
  DEFB $5C,$E8,$5C,$CA,$5C,$CC,$5C,$E1,$5C,$E7,$5C,$00,$00,$E9,$5C,$E9,$5C,$E9,$5C,$2D
  DEFB $92,$5C,$00,$02,$00,$00,$00,$00,$00,$00,$00,$00,$B6,$1A,$00,$00,$ED,$3A,$00,$58
  DEFB $FF,$00,$00,$21,$00,$5B,$21,$17,$C0,$40,$E0,$50,$21,$12,$21,$17,$03,$38,$00,$38
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$7F,$67,$FF,$FF,$F4,$09
  DEFB $A8,$10,$4B,$F4,$09,$C4,$15,$53,$81,$0F,$C4,$15,$52,$F4,$09,$C4,$15,$50,$80,$80
  DEFB $EF,$22,$22,$AA,$3A,$F2,$30,$0E,$00,$00,$00,$00,$00,$3A,$F9,$C0,$36,$35,$33,$36
  DEFB $38,$0E,$00,$00,$58,$FF,$00,$0D,$80,$00,$00,$58,$FF,$00,$20,$20,$20,$20,$20,$20
  DEFB $00,$1B,$00,$40,$00,$00,$03,$73,$63,$72,$65,$65,$6E,$20,$20,$20,$20,$00,$1B,$50
  DEFB $C3,$00,$80,$AA,$CE,$5C,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$E0,$57,$71,$0E,$00,$01,$30,$0D,$DB,$02,$4D,$00,$B7,$5C,$F3,$0D,$CE,$0B
  DEFB $E6,$50,$CE,$0B,$E7,$50,$1A,$16,$DC,$0A,$CE,$0B,$ED,$50,$14,$16,$DC,$0A,$DB,$02
  DEFB $4D,$00,$08,$5C,$5C,$00,$F3,$0D,$B7,$2D,$E9,$5C,$E4,$5C,$58,$FF,$2B,$2D,$65,$33
  DEFB $58,$27,$ED,$10,$0D,$00,$09,$00,$85,$1C,$10,$1C,$52,$1B,$76,$1B,$03,$13,$00,$3E

; Font: 64 glyphs of 8 bytes, codes $20-$5F
;
; Glyph = $6680 + code * 8, top line first, 1 = ink. Codes $20-$5F: space,
; punctuation, digits, "@" is the (c) sign, A-Z, then "[", "\", "]" and an up
; arrow at $5B-$5E, $5F blank. Read by PrintChar ($D4C2: 8 lines straight to
; the screen, one attribute from $FD13 to the cell at ($FD14)) and PrintBigChar
; ($D4F5: each line repeated $FD16 times; with $FD17 >= 2 ($D50C) each pixel
; doubled to 16 pixels wide). Every text of the game goes through them
; (PrintInline and the number printers). Image: d1-img/6780-Font.png.
Font:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$18,$18,$18,$18,$00,$18,$00
  DEFB $00,$36,$6C,$00,$00,$00,$00,$00
  DEFB $00,$24,$7E,$24,$24,$7E,$24,$00
  DEFB $18,$3E,$78,$3C,$1E,$1E,$7C,$18
  DEFB $00,$00,$66,$4C,$18,$32,$66,$00
  DEFB $38,$44,$4C,$38,$6E,$46,$3B,$00
  DEFB $00,$18,$30,$00,$00,$00,$00,$00
  DEFB $04,$0C,$18,$18,$18,$18,$0C,$04
  DEFB $20,$30,$18,$18,$18,$18,$30,$20
  DEFB $00,$00,$14,$08,$3E,$08,$14,$00
  DEFB $00,$00,$08,$08,$3E,$08,$08,$00
  DEFB $00,$00,$00,$00,$0C,$0C,$0C,$08
  DEFB $00,$00,$00,$00,$3E,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$18,$18,$00
  DEFB $00,$00,$06,$0C,$18,$30,$60,$00
  DEFB $36,$77,$67,$6B,$73,$77,$36,$00
  DEFB $0C,$3C,$1C,$1C,$1C,$1C,$1C,$00
  DEFB $3C,$76,$36,$04,$08,$7E,$7E,$00
  DEFB $34,$76,$06,$04,$26,$76,$34,$00
  DEFB $17,$17,$37,$77,$77,$07,$07,$00
  DEFB $7F,$70,$66,$07,$37,$77,$36,$00
  DEFB $16,$36,$70,$74,$76,$76,$34,$00
  DEFB $7E,$7E,$02,$0C,$1C,$38,$78,$00
  DEFB $36,$77,$77,$36,$77,$77,$36,$00
  DEFB $36,$77,$77,$37,$07,$76,$34,$00
  DEFB $00,$00,$18,$18,$00,$18,$18,$00
  DEFB $00,$00,$18,$18,$00,$18,$18,$10
  DEFB $00,$08,$18,$30,$60,$30,$18,$08
  DEFB $00,$00,$00,$3E,$00,$3E,$00,$00
  DEFB $00,$20,$30,$18,$0C,$18,$30,$20
  DEFB $2C,$6E,$6E,$0C,$00,$0C,$0C,$00
  DEFB $3E,$59,$45,$5D,$55,$5D,$3E,$00
  DEFB $3E,$77,$77,$77,$7F,$77,$77,$00
  DEFB $76,$77,$76,$74,$76,$77,$76,$00
  DEFB $17,$33,$71,$70,$71,$33,$17,$00
  DEFB $74,$76,$77,$77,$77,$76,$74,$00
  DEFB $77,$71,$70,$76,$70,$71,$77,$00
  DEFB $77,$71,$70,$76,$70,$70,$70,$00
  DEFB $17,$33,$71,$70,$77,$37,$16,$00
  DEFB $77,$77,$77,$7F,$77,$77,$77,$00
  DEFB $1C,$1C,$1C,$1C,$1C,$1C,$1C,$00
  DEFB $07,$07,$07,$07,$37,$77,$36,$00
  DEFB $77,$76,$74,$70,$74,$76,$77,$00
  DEFB $70,$70,$70,$70,$71,$73,$77,$00
  DEFB $63,$77,$7F,$7F,$77,$77,$77,$00
  DEFB $67,$77,$7F,$7F,$7F,$77,$73,$00
  DEFB $36,$77,$77,$77,$77,$77,$36,$00
  DEFB $74,$76,$76,$76,$74,$70,$70,$00
  DEFB $36,$77,$77,$77,$77,$7E,$37,$00
  DEFB $74,$76,$76,$76,$74,$76,$77,$00
  DEFB $37,$79,$7C,$3E,$1F,$4F,$76,$00
  DEFB $7F,$5D,$5D,$1C,$1C,$1C,$1C,$00
  DEFB $77,$77,$77,$77,$77,$77,$36,$00
  DEFB $63,$63,$63,$63,$77,$3E,$1C,$00
  DEFB $6B,$6B,$6B,$6B,$77,$7F,$36,$00
  DEFB $77,$77,$36,$14,$36,$77,$77,$00
  DEFB $77,$77,$36,$3E,$1C,$1C,$1C,$00
  DEFB $77,$4F,$1F,$3E,$7C,$79,$77,$00
  DEFB $00,$0E,$0C,$0C,$0C,$0C,$0E,$00
  DEFB $00,$00,$60,$30,$18,$0C,$06,$00
  DEFB $00,$70,$10,$10,$10,$10,$70,$00
  DEFB $00,$10,$38,$54,$10,$10,$10,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$FF

; Sprite 22 (even column; SpriteTable 44): tracks, moving along X (directions
; 0-1), 27 rows x 3 bytes
;
; The sprites run from here to $A569, 88 blocks, each reached through
; SpriteTable (sprite id x 2 + the column parity). A block: the height in pixel
; lines, the width in bytes, then the rows from the BOTTOM line up, each row
; width x (mask, graphic) byte pairs: screen = (screen AND mask) OR graphic
; (SpriteByteLoop into ViewBuffer, DrawMaskedUp straight to the screen). The
; parity is bit 0 of the half-byte column DrawSprite computes (2 x X + Y - 24):
; the odd entry is the same picture shifted right by 4 pixels (one byte wider
; where it needs to), except where noted: for map objects the column parity is
; the row parity, and map types 12, 13, 14, 17, 18 use the two entries for two
; different pictures.
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprTracksX:
  DEFB $1B,$03

; SprTracksX: 27 rows of 3 (mask, graphic) pairs, bottom line first
SprTracksXRows:
  DEFB $FF,$00,$7F,$80,$FF,$00
  DEFB $FE,$01,$1F,$E0,$FF,$00
  DEFB $FC,$02,$07,$F8,$FF,$00
  DEFB $FC,$02,$01,$BE,$FF,$00
  DEFB $F8,$05,$00,$9F,$7F,$80
  DEFB $F8,$04,$00,$FB,$1F,$E0
  DEFB $F8,$06,$00,$79,$07,$F8
  DEFB $F8,$04,$00,$9F,$01,$BE
  DEFB $F8,$04,$00,$A7,$00,$9F
  DEFB $FC,$03,$00,$29,$00,$FB
  DEFB $EF,$10,$00,$CA,$00,$79
  DEFB $C3,$3C,$C0,$32,$00,$9F
  DEFB $80,$5F,$F0,$0C,$00,$A7
  DEFB $80,$57,$3C,$C3,$00,$29
  DEFB $00,$B3,$0F,$F0,$01,$CA
  DEFB $00,$9F,$03,$7C,$C1,$32
  DEFB $00,$CF,$00,$3F,$F3,$0C
  DEFB $00,$93,$00,$F7,$3F,$C0
  DEFB $00,$94,$00,$F3,$1F,$E0
  DEFB $80,$65,$00,$3F,$1F,$60
  DEFB $E0,$19,$00,$4F,$1F,$20
  DEFB $F8,$06,$00,$53,$1F,$E0
  DEFB $FE,$01,$00,$94,$1F,$E0
  DEFB $FF,$00,$80,$65,$1F,$20
  DEFB $FF,$00,$E0,$19,$3F,$40
  DEFB $FF,$00,$F8,$06,$3F,$40
  DEFB $FF,$00,$FE,$01,$7F,$80

; Sprite 22 (odd column; SpriteTable 45): tracks, moving along X (directions
; 0-1), 27 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprTracksXOdd:
  DEFB $1B,$04

; SprTracksXOdd: 27 rows of 4 (mask, graphic) pairs, bottom line first
SprTracksXOddRows:
  DEFB $FF,$00,$F7,$08,$FF,$00,$FF,$00
  DEFB $FF,$00,$E1,$1E,$FF,$00,$FF,$00
  DEFB $FF,$00,$C0,$2F,$7F,$80,$FF,$00
  DEFB $FF,$00,$C0,$2B,$1F,$E0,$FF,$00
  DEFB $FF,$00,$80,$59,$07,$F8,$FF,$00
  DEFB $FF,$00,$80,$4F,$01,$BE,$FF,$00
  DEFB $FF,$00,$80,$67,$00,$9F,$7F,$80
  DEFB $FF,$00,$80,$49,$00,$FB,$1F,$E0
  DEFB $FF,$00,$80,$4A,$00,$79,$0F,$F0
  DEFB $FF,$00,$C0,$32,$00,$9F,$0F,$B0
  DEFB $FE,$01,$F0,$0C,$00,$A7,$0F,$90
  DEFB $FC,$03,$3C,$C3,$00,$29,$0F,$F0
  DEFB $F8,$05,$0F,$F0,$00,$CA,$0F,$70
  DEFB $F8,$05,$03,$7C,$C0,$32,$0F,$90
  DEFB $F0,$0B,$00,$3F,$F0,$0C,$1F,$A0
  DEFB $F0,$09,$00,$F7,$3C,$C3,$1F,$20
  DEFB $F0,$0C,$00,$F3,$0F,$F0,$3F,$C0
  DEFB $F0,$09,$00,$3F,$03,$7C,$FF,$00
  DEFB $F0,$09,$00,$4F,$01,$3E,$FF,$00
  DEFB $F8,$06,$00,$53,$01,$F6,$FF,$00
  DEFB $FE,$01,$00,$94,$01,$F2,$FF,$00
  DEFB $FF,$00,$80,$65,$01,$3E,$FF,$00
  DEFB $FF,$00,$E0,$19,$01,$4E,$FF,$00
  DEFB $FF,$00,$F8,$06,$01,$52,$FF,$00
  DEFB $FF,$00,$FE,$01,$03,$94,$FF,$00
  DEFB $FF,$00,$FF,$00,$83,$64,$FF,$00
  DEFB $FF,$00,$FF,$00,$E7,$18,$FF,$00

; Sprite 23 (even column; SpriteTable 46): tracks, moving along Y (directions
; 2-3), 28 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprTracksY:
  DEFB $1C,$03

; SprTracksY: 28 rows of 3 (mask, graphic) pairs, bottom line first
SprTracksYRows:
  DEFB $FF,$00,$3F,$C0,$FF,$00
  DEFB $FE,$01,$0F,$B0,$FF,$00
  DEFB $FE,$01,$03,$CC,$FF,$00
  DEFB $FC,$02,$03,$B4,$FF,$00
  DEFB $FC,$02,$03,$CC,$FF,$00
  DEFB $F8,$07,$03,$34,$CF,$30
  DEFB $F8,$07,$03,$8C,$83,$6C
  DEFB $F0,$0A,$03,$64,$80,$73
  DEFB $F0,$0B,$07,$18,$00,$AD
  DEFB $E0,$1C,$07,$C8,$00,$B3
  DEFB $E0,$1E,$0E,$31,$00,$CD
  DEFB $C0,$29,$0E,$91,$00,$E3
  DEFB $C0,$2C,$1C,$62,$00,$99
  DEFB $80,$73,$1C,$22,$01,$C6
  DEFB $80,$78,$38,$C7,$01,$32
  DEFB $00,$A6,$38,$47,$03,$8C
  DEFB $00,$B1,$70,$8A,$03,$64
  DEFB $00,$CC,$70,$8B,$07,$18
  DEFB $00,$E3,$E0,$1C,$07,$C8
  DEFB $00,$99,$E0,$1E,$0F,$30
  DEFB $01,$C6,$C0,$29,$0F,$90
  DEFB $C1,$32,$C0,$2C,$1F,$60
  DEFB $F3,$0C,$C0,$33,$1F,$20
  DEFB $FF,$00,$C0,$38,$3F,$C0
  DEFB $FF,$00,$C0,$26,$3F,$40
  DEFB $FF,$00,$C0,$31,$7F,$80
  DEFB $FF,$00,$F0,$0C,$7F,$80
  DEFB $FF,$00,$FC,$03,$FF,$00

; Sprite 23 (odd column; SpriteTable 47): tracks, moving along Y (directions
; 2-3), 28 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprTracksYOdd:
  DEFB $1C,$04

; SprTracksYOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first
SprTracksYOddRows:
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$1B,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$1C,$3F,$C0,$FF,$00
  DEFB $FF,$00,$C0,$2B,$3F,$40,$FF,$00
  DEFB $FF,$00,$C0,$2C,$3F,$C0,$FF,$00
  DEFB $FF,$00,$80,$73,$3C,$43,$FF,$00
  DEFB $FF,$00,$80,$78,$38,$C6,$3F,$C0
  DEFB $FF,$00,$00,$A6,$38,$47,$0F,$30
  DEFB $FF,$00,$00,$B1,$70,$8A,$0F,$D0
  DEFB $FE,$01,$00,$CC,$70,$8B,$0F,$30
  DEFB $FE,$01,$00,$E3,$E0,$1C,$0F,$D0
  DEFB $FC,$02,$00,$99,$E0,$1E,$0F,$30
  DEFB $FC,$02,$01,$C6,$C0,$29,$0F,$90
  DEFB $F8,$07,$01,$32,$C0,$2C,$1F,$60
  DEFB $F8,$07,$03,$8C,$80,$73,$1F,$20
  DEFB $F0,$0A,$03,$64,$80,$78,$3F,$C0
  DEFB $F0,$0B,$07,$18,$00,$A6,$3F,$40
  DEFB $F0,$0C,$07,$C8,$00,$B1,$7F,$80
  DEFB $F0,$0E,$0E,$31,$00,$CC,$7F,$80
  DEFB $F0,$09,$0E,$91,$00,$E3,$FF,$00
  DEFB $F0,$0C,$1C,$62,$00,$99,$FF,$00
  DEFB $FC,$03,$1C,$22,$01,$C6,$FF,$00
  DEFB $FF,$00,$3C,$C3,$01,$32,$FF,$00
  DEFB $FF,$00,$FC,$03,$03,$8C,$FF,$00
  DEFB $FF,$00,$FC,$02,$03,$64,$FF,$00
  DEFB $FF,$00,$FC,$03,$07,$18,$FF,$00
  DEFB $FF,$00,$FF,$00,$07,$C8,$FF,$00
  DEFB $FF,$00,$FF,$00,$CF,$30,$FF,$00

; Sprite 24 (even column; SpriteTable 48): bipod legs, along X, 30 rows x 3
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprBipodX:
  DEFB $1E,$03

; SprBipodX: 30 rows of 3 (mask, graphic) pairs, bottom line first
SprBipodXRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$01,$7F,$80,$FF,$00
  DEFB $FE,$01,$1F,$60,$FF,$00
  DEFB $FC,$03,$07,$58,$FF,$00
  DEFB $FC,$03,$01,$56,$FF,$00
  DEFB $F8,$07,$00,$D5,$7F,$80
  DEFB $F8,$06,$00,$55,$1F,$60
  DEFB $F8,$06,$00,$35,$07,$58
  DEFB $F8,$04,$00,$15,$03,$54
  DEFB $E0,$1E,$00,$0D,$03,$54
  DEFB $E0,$17,$00,$1D,$03,$54
  DEFB $C0,$35,$00,$98,$03,$FC
  DEFB $C0,$35,$00,$78,$03,$84
  DEFB $80,$7D,$00,$78,$07,$88
  DEFB $80,$65,$00,$78,$07,$88
  DEFB $80,$63,$00,$7C,$0F,$F0
  DEFB $80,$41,$00,$73,$7F,$80
  DEFB $80,$60,$00,$F0,$3F,$C0
  DEFB $E0,$11,$00,$A1,$3F,$40
  DEFB $F0,$09,$00,$B1,$3F,$C0
  DEFB $F8,$07,$00,$8F,$3F,$40
  DEFB $FC,$03,$00,$8A,$7F,$80
  DEFB $FC,$03,$00,$88,$7F,$80
  DEFB $FC,$03,$00,$CF,$FF,$00
  DEFB $FC,$03,$07,$38,$FF,$00
  DEFB $FC,$03,$07,$08,$FF,$00
  DEFB $FC,$02,$0F,$10,$FF,$00
  DEFB $FC,$03,$0F,$10,$FF,$00
  DEFB $FF,$00,$1F,$E0,$FF,$00
  DEFB $FF,$00,$DF,$20,$FF,$00

; Sprite 24 (odd column; SpriteTable 49): bipod legs, along X, 30 rows x 4
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprBipodXOdd:
  DEFB $1E,$04

; SprBipodXOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first
SprBipodXOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$E7,$18,$FF,$00,$FF,$00
  DEFB $FF,$00,$E1,$16,$FF,$00,$FF,$00
  DEFB $FF,$00,$C0,$35,$7F,$80,$FF,$00
  DEFB $FF,$00,$C0,$35,$1F,$60,$FF,$00
  DEFB $FF,$00,$80,$7D,$07,$58,$FF,$00
  DEFB $FF,$00,$80,$65,$01,$56,$FF,$00
  DEFB $FF,$00,$80,$63,$00,$55,$7F,$80
  DEFB $FF,$00,$80,$41,$00,$55,$3F,$40
  DEFB $FE,$01,$00,$E0,$00,$D5,$3F,$40
  DEFB $FE,$01,$00,$71,$00,$D5,$3F,$40
  DEFB $FC,$03,$00,$59,$00,$8F,$3F,$C0
  DEFB $FC,$03,$00,$57,$00,$88,$3F,$40
  DEFB $F8,$07,$00,$D7,$00,$88,$7F,$80
  DEFB $F8,$06,$00,$57,$00,$88,$7F,$80
  DEFB $F8,$06,$00,$37,$00,$CF,$FF,$00
  DEFB $F8,$04,$00,$17,$07,$38,$FF,$00
  DEFB $F8,$06,$00,$0F,$03,$0C,$FF,$00
  DEFB $FE,$01,$00,$1A,$03,$14,$FF,$00
  DEFB $FF,$00,$00,$9B,$03,$1C,$FF,$00
  DEFB $FF,$00,$80,$78,$03,$F4,$FF,$00
  DEFB $FF,$00,$C0,$38,$07,$A8,$FF,$00
  DEFB $FF,$00,$C0,$38,$07,$88,$FF,$00
  DEFB $FF,$00,$C0,$3C,$0F,$F0,$FF,$00
  DEFB $FF,$00,$C0,$33,$7F,$80,$FF,$00
  DEFB $FF,$00,$C0,$30,$7F,$80,$FF,$00
  DEFB $FF,$00,$C0,$21,$FF,$00,$FF,$00
  DEFB $FF,$00,$C0,$31,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0E,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$02,$FF,$00,$FF,$00

; Sprite 25 (even column; SpriteTable 50): bipod legs, along Y, 29 rows x 3
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprBipodY:
  DEFB $1D,$03

; SprBipodY: 29 rows of 3 (mask, graphic) pairs, bottom line first
SprBipodYRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$01,$7F,$80,$FF,$00
  DEFB $FE,$01,$1F,$60,$FF,$00
  DEFB $FC,$03,$07,$58,$FF,$00
  DEFB $FC,$03,$03,$54,$FF,$00
  DEFB $F8,$07,$02,$D5,$7F,$80
  DEFB $F8,$06,$02,$75,$1F,$60
  DEFB $F0,$0E,$00,$1F,$07,$58
  DEFB $F0,$0E,$00,$07,$03,$54
  DEFB $E0,$1E,$00,$07,$03,$D4
  DEFB $E0,$1C,$00,$0E,$03,$74
  DEFB $C0,$3C,$00,$0E,$03,$1C
  DEFB $C0,$3F,$00,$0E,$03,$04
  DEFB $80,$7C,$00,$DE,$03,$04
  DEFB $80,$7C,$00,$3C,$07,$08
  DEFB $80,$7C,$00,$1C,$07,$08
  DEFB $80,$5C,$00,$1F,$07,$08
  DEFB $80,$7E,$00,$1C,$0F,$D0
  DEFB $E0,$19,$00,$9C,$0F,$30
  DEFB $E0,$18,$00,$7C,$0F,$10
  DEFB $E0,$10,$00,$1C,$0F,$10
  DEFB $E0,$18,$00,$3E,$0F,$10
  DEFB $F8,$06,$00,$39,$0F,$90
  DEFB $FE,$01,$20,$D8,$0F,$70
  DEFB $FF,$00,$A0,$50,$0F,$10
  DEFB $FF,$00,$E0,$18,$1F,$20
  DEFB $FF,$00,$F8,$06,$1F,$20
  DEFB $FF,$00,$FE,$01,$3F,$C0
  DEFB $FF,$00,$FF,$00,$BF,$40

; Sprite 25 (odd column; SpriteTable 51): bipod legs, along Y, 29 rows x 4
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprBipodYOdd:
  DEFB $1D,$04

; SprBipodYOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first
SprBipodYOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$E7,$18,$FF,$00,$FF,$00
  DEFB $FF,$00,$E1,$16,$FF,$00,$FF,$00
  DEFB $FF,$00,$C0,$35,$7F,$80,$FF,$00
  DEFB $FF,$00,$C0,$35,$3F,$40,$FF,$00
  DEFB $FF,$00,$80,$7D,$27,$58,$FF,$00
  DEFB $FF,$00,$80,$67,$21,$56,$FF,$00
  DEFB $FF,$00,$00,$E1,$00,$F5,$7F,$80
  DEFB $FF,$00,$00,$E0,$00,$75,$3F,$40
  DEFB $FE,$01,$00,$E0,$00,$7D,$3F,$40
  DEFB $FE,$01,$00,$C0,$00,$E7,$3F,$40
  DEFB $FC,$03,$00,$C0,$00,$E1,$3F,$C0
  DEFB $FC,$03,$00,$F0,$00,$E0,$3F,$40
  DEFB $F8,$07,$00,$CD,$00,$E0,$3F,$40
  DEFB $F8,$07,$00,$C3,$00,$C0,$7F,$80
  DEFB $F8,$07,$00,$C1,$00,$C0,$7F,$80
  DEFB $F8,$05,$00,$C1,$00,$F0,$7F,$80
  DEFB $F8,$07,$00,$E1,$00,$CD,$FF,$00
  DEFB $FE,$01,$00,$99,$00,$C3,$FF,$00
  DEFB $FE,$01,$00,$87,$00,$C1,$FF,$00
  DEFB $FE,$01,$00,$01,$00,$C1,$FF,$00
  DEFB $FE,$01,$00,$83,$00,$E1,$FF,$00
  DEFB $FF,$00,$80,$63,$00,$99,$FF,$00
  DEFB $FF,$00,$E2,$1D,$00,$87,$FF,$00
  DEFB $FF,$00,$FA,$05,$00,$01,$FF,$00
  DEFB $FF,$00,$FE,$01,$01,$82,$FF,$00
  DEFB $FF,$00,$FF,$00,$81,$62,$FF,$00
  DEFB $FF,$00,$FF,$00,$E3,$1C,$FF,$00
  DEFB $FF,$00,$FF,$00,$FB,$04,$FF,$00

; Sprite 26 (even column; SpriteTable 52): anti-grav unit, every direction, 23
; rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprAntiGrav:
  DEFB $17,$03

; SprAntiGrav: 23 rows of 3 (mask, graphic) pairs, bottom line first
SprAntiGravRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$3F,$C0,$FF,$00
  DEFB $FF,$00,$0F,$F0,$FF,$00
  DEFB $FE,$01,$03,$BC,$FF,$00
  DEFB $FE,$01,$01,$0E,$FF,$00
  DEFB $FC,$03,$01,$42,$3F,$C0
  DEFB $FC,$02,$00,$2A,$0F,$F0
  DEFB $FC,$03,$00,$F5,$03,$BC
  DEFB $FF,$00,$00,$F5,$01,$0E
  DEFB $F3,$0C,$C0,$3B,$01,$42
  DEFB $F0,$0F,$C0,$32,$01,$2A
  DEFB $E0,$1B,$00,$CF,$03,$F4
  DEFB $E0,$10,$00,$C3,$03,$F4
  DEFB $C0,$34,$00,$98,$07,$F8
  DEFB $C0,$22,$00,$A6,$1F,$20
  DEFB $C0,$3F,$00,$22,$3F,$40
  DEFB $F0,$0F,$00,$42,$1F,$E0
  DEFB $FC,$02,$00,$64,$1F,$A0
  DEFB $FC,$03,$00,$1D,$1F,$A0
  DEFB $FF,$00,$00,$C1,$3F,$40
  DEFB $FF,$00,$C0,$33,$3F,$40
  DEFB $FF,$00,$F0,$0F,$7F,$80
  DEFB $FF,$00,$FD,$02,$FF,$00

; Sprite 26 (odd column; SpriteTable 53): anti-grav unit, every direction, 23
; rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprAntiGravOdd:
  DEFB $17,$04

; SprAntiGravOdd: 23 rows of 4 (mask, graphic) pairs, bottom line first
SprAntiGravOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0F,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$1B,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$10,$1F,$E0,$FF,$00
  DEFB $FF,$00,$C0,$34,$13,$2C,$FF,$00
  DEFB $FF,$00,$C0,$22,$00,$AF,$FF,$00
  DEFB $FF,$00,$C0,$3F,$00,$5B,$3F,$C0
  DEFB $FF,$00,$F0,$0F,$00,$50,$1F,$E0
  DEFB $FF,$00,$3C,$C3,$00,$B4,$1F,$20
  DEFB $FF,$00,$0C,$F3,$00,$22,$1F,$A0
  DEFB $FE,$01,$00,$BC,$00,$FF,$3F,$40
  DEFB $FE,$01,$00,$0C,$00,$3F,$3F,$40
  DEFB $FC,$03,$00,$49,$00,$8F,$7F,$80
  DEFB $FC,$02,$00,$2A,$01,$62,$FF,$00
  DEFB $FC,$03,$00,$F2,$03,$24,$FF,$00
  DEFB $FF,$00,$00,$F4,$01,$2E,$FF,$00
  DEFB $FF,$00,$C0,$26,$01,$4A,$FF,$00
  DEFB $FF,$00,$C0,$31,$01,$DA,$FF,$00
  DEFB $FF,$00,$F0,$0C,$03,$14,$FF,$00
  DEFB $FF,$00,$FC,$03,$03,$34,$FF,$00
  DEFB $FF,$00,$FF,$00,$07,$F8,$FF,$00
  DEFB $FF,$00,$FF,$00,$DF,$20,$FF,$00

; Sprite 27 (even column; SpriteTable 54): cannon facing X+ (direction 0), 28
; rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonXp:
  DEFB $1C,$03

; SprCannonXp: 28 rows of 3 (mask, graphic) pairs, bottom line first
SprCannonXpRows:
  DEFB $FF,$00,$3F,$C0,$FF,$00
  DEFB $FF,$00,$0F,$B0,$FF,$00
  DEFB $FE,$01,$03,$AC,$FF,$00
  DEFB $FE,$01,$00,$AB,$FF,$00
  DEFB $FC,$03,$00,$AA,$3F,$C0
  DEFB $FC,$02,$00,$AA,$0F,$B0
  DEFB $F8,$07,$00,$EA,$03,$AC
  DEFB $F8,$05,$00,$3A,$00,$AB
  DEFB $F0,$0F,$00,$0E,$00,$AB
  DEFB $F0,$0A,$00,$03,$01,$AE
  DEFB $E0,$1E,$00,$60,$01,$FA
  DEFB $E0,$14,$00,$98,$03,$34
  DEFB $C0,$3C,$00,$86,$03,$14
  DEFB $C0,$29,$00,$01,$07,$A8
  DEFB $80,$79,$00,$01,$07,$28
  DEFB $80,$52,$00,$01,$07,$78
  DEFB $00,$F3,$00,$82,$03,$5C
  DEFB $00,$A4,$00,$62,$1F,$A0
  DEFB $00,$E4,$00,$1C,$1F,$A0
  DEFB $00,$C8,$00,$05,$3F,$40
  DEFB $00,$C8,$00,$09,$3F,$40
  DEFB $00,$8C,$00,$0B,$3F,$C0
  DEFB $00,$C3,$00,$12,$1F,$E0
  DEFB $C0,$30,$00,$D5,$FF,$00
  DEFB $F0,$0C,$01,$27,$FF,$00
  DEFB $FC,$03,$01,$0A,$FF,$00
  DEFB $FF,$00,$03,$CC,$FF,$00
  DEFB $FF,$00,$C7,$38,$FF,$00

; Sprite 27 (odd column; SpriteTable 55): cannon facing X+ (direction 0), 28
; rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonXpOdd:
  DEFB $1C,$04

; SprCannonXpOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first
SprCannonXpOddRows:
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0B,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$1A,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$1A,$0F,$B0,$FF,$00
  DEFB $FF,$00,$C0,$3A,$03,$AC,$FF,$00
  DEFB $FF,$00,$C0,$2A,$00,$AB,$FF,$00
  DEFB $FF,$00,$80,$7E,$00,$AA,$3F,$C0
  DEFB $FF,$00,$80,$53,$00,$AA,$0F,$B0
  DEFB $FF,$00,$00,$F0,$00,$EA,$0F,$B0
  DEFB $FF,$00,$00,$A0,$00,$3A,$1F,$E0
  DEFB $FE,$01,$00,$E6,$00,$0F,$1F,$A0
  DEFB $FE,$01,$00,$49,$00,$83,$3F,$40
  DEFB $FC,$03,$00,$C8,$00,$61,$3F,$40
  DEFB $FC,$02,$00,$90,$00,$1A,$7F,$80
  DEFB $F8,$07,$00,$90,$00,$12,$7F,$80
  DEFB $F8,$05,$00,$20,$00,$17,$7F,$80
  DEFB $F0,$0F,$00,$38,$00,$25,$3F,$C0
  DEFB $F0,$0A,$00,$46,$01,$2A,$FF,$00
  DEFB $F0,$0E,$00,$41,$01,$CA,$FF,$00
  DEFB $F0,$0C,$00,$80,$03,$54,$FF,$00
  DEFB $F0,$0C,$00,$80,$03,$94,$FF,$00
  DEFB $F0,$08,$00,$C0,$03,$BC,$FF,$00
  DEFB $F0,$0C,$00,$31,$01,$2E,$FF,$00
  DEFB $FC,$03,$00,$0D,$0F,$50,$FF,$00
  DEFB $FF,$00,$00,$C2,$1F,$70,$FF,$00
  DEFB $FF,$00,$C0,$30,$1F,$A0,$FF,$00
  DEFB $FF,$00,$F0,$0C,$3F,$C0,$FF,$00
  DEFB $FF,$00,$FC,$03,$7F,$80,$FF,$00

; Sprite 28 (even column; SpriteTable 56): cannon facing X- (direction 1), 30
; rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonXm:
  DEFB $1E,$03

; SprCannonXm: 30 rows of 3 (mask, graphic) pairs, bottom line first
SprCannonXmRows:
  DEFB $FF,$00,$3F,$C0,$FF,$00
  DEFB $FF,$00,$0F,$B0,$FF,$00
  DEFB $FE,$01,$03,$3C,$FF,$00
  DEFB $FE,$01,$00,$17,$FF,$00
  DEFB $FC,$02,$00,$1D,$3F,$C0
  DEFB $FC,$02,$00,$0D,$0F,$70
  DEFB $F8,$04,$00,$0D,$03,$5C
  DEFB $E0,$1C,$00,$05,$00,$57
  DEFB $F0,$0F,$00,$47,$00,$55
  DEFB $F0,$09,$00,$C9,$00,$D5
  DEFB $E0,$14,$00,$48,$00,$75
  DEFB $E0,$12,$00,$12,$00,$1D
  DEFB $C0,$21,$00,$15,$00,$87
  DEFB $00,$E0,$00,$A4,$00,$61
  DEFB $80,$7A,$00,$A8,$01,$1A
  DEFB $80,$4E,$00,$48,$01,$12
  DEFB $00,$C2,$00,$50,$03,$14
  DEFB $00,$F0,$00,$90,$03,$24
  DEFB $80,$50,$00,$AC,$07,$28
  DEFB $C0,$29,$00,$23,$07,$48
  DEFB $C0,$29,$00,$40,$0F,$D0
  DEFB $E0,$1A,$00,$40,$0F,$90
  DEFB $E0,$1A,$00,$80,$1F,$A0
  DEFB $F0,$0C,$00,$E1,$1F,$20
  DEFB $F8,$06,$00,$19,$3F,$40
  DEFB $FE,$01,$00,$86,$3F,$40
  DEFB $FF,$00,$80,$62,$7F,$80
  DEFB $FF,$00,$E0,$18,$7F,$80
  DEFB $FF,$00,$F8,$07,$FF,$00
  DEFB $FF,$00,$FE,$01,$FF,$00

; Sprite 28 (odd column; SpriteTable 57): cannon facing X- (direction 1), 30
; rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprCannonXmOdd:
  DEFB $1E,$04

; SprCannonXmOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first
SprCannonXmOddRows:
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0B,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$13,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$11,$0F,$70,$FF,$00
  DEFB $FF,$00,$C0,$21,$03,$DC,$FF,$00
  DEFB $FF,$00,$C0,$20,$00,$D7,$FF,$00
  DEFB $FF,$00,$80,$40,$00,$D5,$3F,$C0
  DEFB $FE,$01,$00,$C0,$00,$55,$0F,$70
  DEFB $FF,$00,$00,$F4,$00,$75,$0F,$50
  DEFB $FF,$00,$00,$9C,$00,$9D,$0F,$50
  DEFB $FE,$01,$00,$44,$00,$87,$0F,$50
  DEFB $FE,$01,$00,$21,$00,$21,$0F,$D0
  DEFB $FC,$02,$00,$11,$00,$58,$0F,$70
  DEFB $F0,$0E,$00,$0A,$00,$46,$0F,$10
  DEFB $F8,$07,$00,$AA,$00,$81,$1F,$A0
  DEFB $F8,$04,$00,$E4,$00,$81,$1F,$20
  DEFB $F0,$0C,$00,$25,$00,$01,$3F,$40
  DEFB $F0,$0F,$00,$09,$00,$02,$3F,$40
  DEFB $F8,$05,$00,$0A,$00,$C2,$7F,$80
  DEFB $FC,$02,$00,$92,$00,$34,$7F,$80
  DEFB $FC,$02,$00,$94,$00,$0D,$FF,$00
  DEFB $FE,$01,$00,$A4,$00,$09,$FF,$00
  DEFB $FE,$01,$00,$A8,$01,$0A,$FF,$00
  DEFB $FF,$00,$00,$CE,$01,$12,$FF,$00
  DEFB $FF,$00,$80,$61,$03,$94,$FF,$00
  DEFB $FF,$00,$E0,$18,$03,$64,$FF,$00
  DEFB $FF,$00,$F8,$06,$07,$28,$FF,$00
  DEFB $FF,$00,$FE,$01,$07,$88,$FF,$00
  DEFB $FF,$00,$FF,$00,$8F,$70,$FF,$00
  DEFB $FF,$00,$FF,$00,$EF,$10,$FF,$00

; Sprite 29 (even column; SpriteTable 58): cannon facing Y+ (direction 2), 30
; rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonYp:
  DEFB $1E,$03

; SprCannonYp: 30 rows of 3 (mask, graphic) pairs, bottom line first
SprCannonYpRows:
  DEFB $FF,$00,$3F,$C0,$FF,$00
  DEFB $FF,$00,$0F,$B0,$FF,$00
  DEFB $FE,$01,$03,$8C,$FF,$00
  DEFB $FE,$01,$00,$87,$FF,$00
  DEFB $FC,$03,$00,$04,$3F,$C0
  DEFB $FC,$03,$00,$09,$0F,$30
  DEFB $F8,$07,$00,$09,$03,$0C
  DEFB $F8,$07,$00,$32,$00,$0B
  DEFB $F0,$0A,$00,$32,$00,$11
  DEFB $F0,$0A,$00,$32,$00,$13
  DEFB $E0,$1B,$00,$04,$00,$63
  DEFB $E0,$1C,$00,$C4,$01,$62
  DEFB $C0,$2C,$00,$34,$01,$66
  DEFB $C0,$29,$00,$8C,$01,$06
  DEFB $80,$69,$00,$63,$01,$06
  DEFB $80,$72,$00,$18,$03,$C4
  DEFB $00,$B2,$00,$0E,$03,$34
  DEFB $00,$A4,$00,$09,$03,$8C
  DEFB $00,$A4,$00,$10,$07,$48
  DEFB $00,$C8,$00,$10,$07,$48
  DEFB $00,$C8,$00,$20,$0F,$90
  DEFB $00,$98,$00,$20,$0F,$90
  DEFB $00,$C6,$00,$41,$1F,$20
  DEFB $C0,$31,$00,$C1,$1F,$20
  DEFB $F0,$0C,$00,$62,$3F,$40
  DEFB $FC,$03,$00,$1A,$3F,$40
  DEFB $FF,$00,$00,$C4,$7F,$80
  DEFB $FF,$00,$C0,$30,$7F,$80
  DEFB $FF,$00,$F0,$0D,$FF,$00
  DEFB $FF,$00,$FC,$03,$FF,$00

; Sprite 29 (odd column; SpriteTable 59): cannon facing Y+ (direction 2), 30
; rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonYpOdd:
  DEFB $1E,$04

; SprCannonYpOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first
SprCannonYpOddRows:
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0B,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$18,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$18,$0F,$70,$FF,$00
  DEFB $FF,$00,$C0,$30,$03,$4C,$FF,$00
  DEFB $FF,$00,$C0,$30,$00,$93,$FF,$00
  DEFB $FF,$00,$80,$70,$00,$90,$3F,$C0
  DEFB $FF,$00,$80,$73,$00,$20,$0F,$B0
  DEFB $FF,$00,$00,$A3,$00,$21,$0F,$10
  DEFB $FF,$00,$00,$A3,$00,$21,$0F,$30
  DEFB $FE,$01,$00,$B0,$00,$46,$0F,$30
  DEFB $FE,$01,$00,$CC,$00,$46,$1F,$20
  DEFB $FC,$02,$00,$C3,$00,$46,$1F,$60
  DEFB $FC,$02,$00,$98,$00,$C0,$1F,$60
  DEFB $F8,$06,$00,$96,$00,$30,$1F,$60
  DEFB $F8,$07,$00,$21,$00,$8C,$3F,$40
  DEFB $F0,$0B,$00,$20,$00,$E3,$3F,$40
  DEFB $F0,$0A,$00,$40,$00,$98,$3F,$C0
  DEFB $F0,$0A,$00,$41,$00,$04,$7F,$80
  DEFB $F0,$0C,$00,$81,$00,$04,$7F,$80
  DEFB $F0,$0C,$00,$82,$00,$09,$FF,$00
  DEFB $F0,$09,$00,$82,$00,$09,$FF,$00
  DEFB $F0,$0C,$00,$64,$01,$12,$FF,$00
  DEFB $FC,$03,$00,$1C,$01,$12,$FF,$00
  DEFB $FF,$00,$00,$C6,$03,$24,$FF,$00
  DEFB $FF,$00,$C0,$31,$03,$A4,$FF,$00
  DEFB $FF,$00,$F0,$0C,$07,$48,$FF,$00
  DEFB $FF,$00,$FC,$03,$07,$08,$FF,$00
  DEFB $FF,$00,$FF,$00,$0F,$D0,$FF,$00
  DEFB $FF,$00,$FF,$00,$CF,$30,$FF,$00

; Sprite 30 (even column; SpriteTable 60): cannon facing Y- (direction 3), 25
; rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonYm:
  DEFB $19,$03

; SprCannonYm: 25 rows of 3 (mask, graphic) pairs, bottom line first
SprCannonYmRows:
  DEFB $FF,$00,$3F,$C0,$FF,$00
  DEFB $FF,$00,$0F,$F0,$FF,$00
  DEFB $FE,$01,$03,$FC,$FF,$00
  DEFB $FE,$01,$00,$FF,$FF,$00
  DEFB $FC,$02,$00,$DF,$3F,$C0
  DEFB $FC,$02,$00,$F7,$0F,$F0
  DEFB $F8,$06,$00,$FD,$03,$FC
  DEFB $F8,$07,$00,$3F,$00,$7F
  DEFB $F0,$0B,$00,$0F,$00,$DF
  DEFB $F0,$0A,$00,$63,$00,$F7
  DEFB $E0,$1A,$00,$58,$00,$FD
  DEFB $E0,$1C,$00,$86,$00,$3F
  DEFB $C0,$2C,$00,$83,$00,$8F
  DEFB $C0,$29,$00,$04,$00,$63
  DEFB $80,$69,$00,$04,$01,$12
  DEFB $80,$72,$00,$08,$01,$12
  DEFB $00,$F1,$00,$88,$03,$24
  DEFB $00,$CC,$00,$70,$03,$24
  DEFB $C0,$33,$00,$18,$07,$48
  DEFB $F0,$0E,$00,$C6,$07,$48
  DEFB $F0,$07,$00,$31,$0F,$90
  DEFB $F1,$04,$00,$CC,$0F,$10
  DEFB $FF,$00,$E0,$3B,$1F,$20
  DEFB $FF,$00,$C0,$1D,$1F,$E0
  DEFB $FF,$00,$C0,$13,$7F,$80

; Sprite 30 (odd column; SpriteTable 61): cannon facing Y- (direction 3), 25
; rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprCannonYmOdd:
  DEFB $19,$04

; SprCannonYmOdd: 25 rows of 4 (mask, graphic) pairs, bottom line first
SprCannonYmOddRows:
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0F,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$1F,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$1F,$0F,$F0,$FF,$00
  DEFB $FF,$00,$C0,$2D,$03,$FC,$FF,$00
  DEFB $FF,$00,$C0,$2F,$00,$7F,$FF,$00
  DEFB $FF,$00,$80,$6F,$00,$DF,$3F,$C0
  DEFB $FF,$00,$80,$73,$00,$F7,$0F,$F0
  DEFB $FF,$00,$00,$B0,$00,$FD,$0F,$F0
  DEFB $FF,$00,$00,$A6,$00,$3F,$0F,$70
  DEFB $FE,$01,$00,$A5,$00,$8F,$0F,$D0
  DEFB $FE,$01,$00,$C8,$00,$63,$0F,$F0
  DEFB $FC,$02,$00,$C8,$00,$38,$0F,$F0
  DEFB $FC,$02,$00,$90,$00,$46,$0F,$30
  DEFB $F8,$06,$00,$90,$00,$41,$1F,$20
  DEFB $F8,$07,$00,$20,$00,$81,$1F,$20
  DEFB $F0,$0F,$00,$18,$00,$82,$3F,$40
  DEFB $F0,$0C,$00,$C7,$00,$02,$3F,$40
  DEFB $FC,$03,$00,$31,$00,$84,$7F,$80
  DEFB $FF,$00,$00,$EC,$00,$64,$7F,$80
  DEFB $FF,$00,$00,$73,$00,$19,$FF,$00
  DEFB $FF,$00,$10,$4C,$00,$C1,$FF,$00
  DEFB $FF,$00,$DC,$03,$01,$B2,$FF,$00
  DEFB $FF,$00,$FC,$01,$01,$DE,$FF,$00
  DEFB $FF,$00,$FC,$01,$07,$38,$FF,$00

; Sprite 31 (even column; SpriteTable 62): missile pod along X, 27 rows x 3
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprMissilesX:
  DEFB $1B,$03

; SprMissilesX: 27 rows of 3 (mask, graphic) pairs, bottom line first
SprMissilesXRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$01,$FF,$00,$FF,$00
  DEFB $FE,$01,$3F,$C0,$FF,$00
  DEFB $FC,$02,$0F,$B0,$FF,$00
  DEFB $FC,$02,$03,$8C,$FF,$00
  DEFB $FC,$03,$00,$03,$FF,$00
  DEFB $FE,$01,$00,$08,$3F,$C0
  DEFB $FF,$00,$00,$C8,$0F,$30
  DEFB $FF,$00,$00,$F0,$03,$8C
  DEFB $FF,$00,$00,$EC,$01,$82
  DEFB $FE,$01,$00,$43,$00,$09
  DEFB $FE,$01,$00,$C0,$00,$C9
  DEFB $FC,$02,$00,$B0,$00,$31
  DEFB $BC,$43,$00,$8C,$31,$4E
  DEFB $88,$75,$00,$63,$3F,$40
  DEFB $00,$AF,$00,$18,$7F,$80
  DEFB $00,$A6,$00,$C6,$7F,$80
  DEFB $00,$C6,$00,$31,$FF,$00
  DEFB $80,$44,$00,$0D,$FF,$00
  DEFB $C0,$33,$01,$02,$FF,$00
  DEFB $F0,$0C,$00,$C3,$FF,$00
  DEFB $FC,$03,$00,$34,$7F,$80
  DEFB $FF,$00,$00,$CC,$3F,$40
  DEFB $FF,$00,$C0,$30,$3F,$40
  DEFB $FF,$00,$F0,$0C,$3F,$40
  DEFB $FF,$00,$FC,$03,$7F,$80

; Sprite 31 (odd column; SpriteTable 63): missile pod along X, 27 rows x 4
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprMissilesXOdd:
  DEFB $1B,$04

; SprMissilesXOdd: 27 rows of 4 (mask, graphic) pairs, bottom line first
SprMissilesXOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$EF,$10,$FF,$00,$FF,$00
  DEFB $FF,$00,$E3,$1C,$FF,$00,$FF,$00
  DEFB $FF,$00,$C0,$2B,$FF,$00,$FF,$00
  DEFB $FF,$00,$C0,$28,$3F,$C0,$FF,$00
  DEFB $FF,$00,$C0,$30,$0F,$30,$FF,$00
  DEFB $FF,$00,$E0,$10,$03,$8C,$FF,$00
  DEFB $FF,$00,$F0,$0C,$00,$83,$FF,$00
  DEFB $FF,$00,$F0,$0F,$00,$08,$3F,$C0
  DEFB $FF,$00,$F0,$0E,$00,$C8,$1F,$20
  DEFB $FF,$00,$E0,$14,$00,$30,$0F,$90
  DEFB $FF,$00,$E0,$1C,$00,$0C,$0F,$90
  DEFB $FF,$00,$C0,$2B,$00,$03,$0F,$10
  DEFB $FB,$04,$C0,$38,$03,$C4,$1F,$E0
  DEFB $F8,$07,$80,$56,$03,$34,$FF,$00
  DEFB $F0,$0A,$00,$F1,$07,$88,$FF,$00
  DEFB $F0,$0A,$00,$6C,$07,$68,$FF,$00
  DEFB $F0,$0C,$00,$63,$0F,$10,$FF,$00
  DEFB $F8,$04,$00,$40,$0F,$D0,$FF,$00
  DEFB $FC,$03,$00,$30,$1F,$20,$FF,$00
  DEFB $FF,$00,$00,$CC,$0F,$30,$FF,$00
  DEFB $FF,$00,$C0,$33,$07,$48,$FF,$00
  DEFB $FF,$00,$F0,$0C,$03,$C4,$FF,$00
  DEFB $FF,$00,$FC,$03,$03,$04,$FF,$00
  DEFB $FF,$00,$FF,$00,$03,$C4,$FF,$00
  DEFB $FF,$00,$FF,$00,$C7,$38,$FF,$00

; Sprite 32 (even column; SpriteTable 64): missile pod along Y, 28 rows x 3
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprMissilesY:
  DEFB $1C,$03

; SprMissilesY: 28 rows of 3 (mask, graphic) pairs, bottom line first
SprMissilesYRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$9F,$60,$FF,$00
  DEFB $FF,$00,$0F,$90,$FF,$00
  DEFB $FF,$00,$07,$88,$FF,$00
  DEFB $FE,$01,$07,$88,$FF,$00
  DEFB $FE,$01,$07,$48,$FF,$00
  DEFB $FC,$02,$03,$3C,$F3,$0C
  DEFB $FC,$02,$00,$17,$E1,$12
  DEFB $F8,$04,$00,$3D,$20,$D1
  DEFB $F8,$05,$00,$37,$00,$71
  DEFB $F0,$08,$00,$FD,$00,$E9
  DEFB $F0,$08,$00,$4F,$01,$46
  DEFB $E0,$10,$00,$93,$01,$C2
  DEFB $E0,$14,$00,$94,$03,$E4
  DEFB $C0,$23,$00,$25,$03,$34
  DEFB $C0,$21,$00,$29,$07,$28
  DEFB $80,$42,$00,$4A,$07,$28
  DEFB $80,$52,$00,$52,$0F,$50
  DEFB $00,$8E,$00,$94,$0F,$50
  DEFB $02,$85,$00,$A4,$1F,$A0
  DEFB $07,$88,$80,$68,$1F,$A0
  DEFB $87,$48,$E0,$19,$3F,$40
  DEFB $CF,$30,$F0,$0D,$3F,$40
  DEFB $FF,$00,$E0,$12,$7F,$80
  DEFB $FF,$00,$E0,$10,$7F,$80
  DEFB $FF,$00,$E0,$11,$FF,$00
  DEFB $FF,$00,$F0,$09,$FF,$00
  DEFB $FF,$00,$F9,$06,$FF,$00

; Sprite 32 (odd column; SpriteTable 65): missile pod along Y, 28 rows x 4
; bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprMissilesYOdd:
  DEFB $1C,$04

; SprMissilesYOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first
SprMissilesYOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F9,$06,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$09,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$08,$7F,$80,$FF,$00
  DEFB $FF,$00,$E0,$18,$7F,$80,$FF,$00
  DEFB $FF,$00,$E0,$14,$7F,$80,$FF,$00
  DEFB $FF,$00,$C0,$23,$3F,$C0,$3F,$C0
  DEFB $FF,$00,$C0,$21,$0E,$71,$1F,$20
  DEFB $FF,$00,$80,$43,$02,$DD,$0F,$10
  DEFB $FF,$00,$80,$53,$00,$77,$0F,$10
  DEFB $FF,$00,$00,$8F,$00,$DE,$0F,$90
  DEFB $FF,$00,$00,$84,$00,$F4,$1F,$60
  DEFB $FE,$01,$00,$09,$00,$3C,$1F,$20
  DEFB $FE,$01,$00,$49,$00,$4E,$3F,$40
  DEFB $FC,$02,$00,$32,$00,$53,$3F,$40
  DEFB $FC,$02,$00,$12,$00,$92,$7F,$80
  DEFB $F8,$04,$00,$24,$00,$A2,$7F,$80
  DEFB $F8,$05,$00,$25,$00,$25,$FF,$00
  DEFB $F0,$08,$00,$E9,$00,$45,$FF,$00
  DEFB $F0,$08,$20,$5A,$01,$4A,$FF,$00
  DEFB $F0,$08,$78,$86,$01,$8A,$FF,$00
  DEFB $F8,$04,$7E,$81,$03,$94,$FF,$00
  DEFB $FC,$03,$FF,$00,$03,$D4,$FF,$00
  DEFB $FF,$00,$FE,$01,$07,$28,$FF,$00
  DEFB $FF,$00,$FE,$01,$07,$08,$FF,$00
  DEFB $FF,$00,$FE,$01,$0F,$10,$FF,$00
  DEFB $FF,$00,$FF,$00,$0F,$90,$FF,$00
  DEFB $FF,$00,$FF,$00,$9F,$60,$FF,$00

; Sprite 33 (even column; SpriteTable 66): phasers facing X+, 28 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersXp:
  DEFB $1C,$03

; SprPhasersXp: 28 rows of 3 (mask, graphic) pairs, bottom line first
SprPhasersXpRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$8F,$70,$FF,$00
  DEFB $FF,$00,$03,$8C,$FF,$00
  DEFB $FE,$01,$00,$03,$FF,$00
  DEFB $FC,$02,$00,$20,$3F,$C0
  DEFB $FC,$02,$00,$A4,$0F,$B0
  DEFB $F8,$04,$00,$A4,$0F,$90
  DEFB $F8,$04,$00,$04,$07,$88
  DEFB $F0,$0A,$00,$70,$07,$88
  DEFB $F0,$09,$00,$8C,$07,$88
  DEFB $E0,$16,$00,$03,$0F,$90
  DEFB $E0,$12,$00,$00,$0F,$90
  DEFB $C0,$24,$00,$61,$1F,$20
  DEFB $C0,$34,$00,$19,$1F,$20
  DEFB $C0,$28,$00,$03,$3F,$C0
  DEFB $80,$48,$00,$03,$0F,$F0
  DEFB $80,$71,$00,$87,$0F,$70
  DEFB $80,$50,$00,$65,$0F,$D0
  DEFB $80,$60,$00,$08,$0F,$70
  DEFB $80,$60,$00,$0C,$0F,$10
  DEFB $80,$46,$00,$13,$1F,$20
  DEFB $80,$41,$03,$9C,$1F,$E0
  DEFB $80,$40,$1F,$20,$FF,$00
  DEFB $C0,$20,$1F,$20,$FF,$00
  DEFB $E0,$10,$3F,$40,$FF,$00
  DEFB $F0,$0C,$3F,$40,$FF,$00
  DEFB $FC,$03,$7F,$80,$FF,$00
  DEFB $FF,$00,$7F,$80,$FF,$00

; Sprite 33 (odd column; SpriteTable 67): phasers facing X+, 28 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersXpOdd:
  DEFB $1C,$04

; SprPhasersXpOdd: 28 rows of 4 (mask, graphic) pairs, bottom line first
SprPhasersXpOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F8,$07,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$08,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$10,$0F,$30,$FF,$00
  DEFB $FF,$00,$C0,$22,$03,$0C,$FF,$00
  DEFB $FF,$00,$C0,$2A,$00,$4B,$FF,$00
  DEFB $FF,$00,$80,$4A,$00,$49,$FF,$00
  DEFB $FF,$00,$80,$40,$00,$48,$7F,$80
  DEFB $FF,$00,$00,$A7,$00,$08,$7F,$80
  DEFB $FF,$00,$00,$98,$00,$C8,$7F,$80
  DEFB $FE,$01,$00,$60,$00,$39,$FF,$00
  DEFB $FE,$01,$00,$20,$00,$09,$FF,$00
  DEFB $FC,$02,$00,$46,$01,$12,$FF,$00
  DEFB $FC,$03,$00,$41,$01,$92,$FF,$00
  DEFB $FC,$02,$00,$80,$03,$3C,$FF,$00
  DEFB $F8,$04,$00,$80,$00,$3F,$FF,$00
  DEFB $F8,$07,$00,$18,$00,$77,$FF,$00
  DEFB $F8,$05,$00,$06,$00,$5D,$FF,$00
  DEFB $F8,$06,$00,$00,$00,$87,$FF,$00
  DEFB $F8,$06,$00,$00,$00,$C1,$FF,$00
  DEFB $F8,$04,$00,$61,$01,$32,$FF,$00
  DEFB $F8,$04,$00,$19,$31,$CE,$FF,$00
  DEFB $F8,$04,$01,$02,$FF,$00,$FF,$00
  DEFB $FC,$02,$01,$02,$FF,$00,$FF,$00
  DEFB $FE,$01,$03,$04,$FF,$00,$FF,$00
  DEFB $FF,$00,$03,$C4,$FF,$00,$FF,$00
  DEFB $FF,$00,$C7,$38,$FF,$00,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00,$FF,$00

; Sprite 34 (even column; SpriteTable 68): phasers facing X-, 29 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersXm:
  DEFB $1D,$03

; SprPhasersXm: 29 rows of 3 (mask, graphic) pairs, bottom line first
SprPhasersXmRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F8,$07,$FF,$00
  DEFB $FF,$00,$C0,$39,$3F,$C0
  DEFB $FF,$00,$80,$43,$0F,$30
  DEFB $FF,$00,$80,$43,$07,$08
  DEFB $FF,$00,$00,$95,$07,$48
  DEFB $F3,$0C,$00,$85,$03,$44
  DEFB $F0,$0F,$00,$09,$03,$54
  DEFB $E0,$1F,$00,$C9,$03,$14
  DEFB $E0,$1D,$00,$F1,$03,$C4
  DEFB $E0,$1F,$00,$72,$03,$34
  DEFB $E0,$1B,$00,$D2,$03,$0C
  DEFB $E0,$10,$00,$F4,$03,$0C
  DEFB $E0,$18,$00,$34,$03,$04
  DEFB $F8,$06,$00,$29,$03,$84
  DEFB $F8,$05,$00,$A8,$03,$64
  DEFB $FC,$02,$00,$D0,$03,$04
  DEFB $FC,$03,$00,$10,$07,$08
  DEFB $FE,$01,$00,$26,$07,$08
  DEFB $FE,$01,$00,$21,$0F,$90
  DEFB $FE,$01,$00,$40,$0F,$10
  DEFB $FE,$01,$00,$40,$1F,$20
  DEFB $FE,$01,$00,$98,$1F,$20
  DEFB $FE,$01,$00,$86,$3F,$40
  DEFB $FE,$01,$00,$00,$3F,$40
  DEFB $FF,$00,$00,$E1,$7F,$80
  DEFB $FF,$00,$E1,$1E,$FF,$00

; Sprite 34 (odd column; SpriteTable 69): phasers facing X-, 29 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprPhasersXmOdd:
  DEFB $1D,$04

; SprPhasersXmOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first
SprPhasersXmOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$8F,$70,$FF,$00
  DEFB $FF,$00,$FC,$03,$03,$9C,$FF,$00
  DEFB $FF,$00,$F8,$04,$00,$33,$FF,$00
  DEFB $FF,$00,$F8,$04,$00,$30,$7F,$80
  DEFB $FF,$00,$F0,$09,$00,$54,$7F,$80
  DEFB $FF,$00,$30,$C8,$00,$54,$3F,$40
  DEFB $FF,$00,$00,$F0,$00,$95,$3F,$40
  DEFB $FE,$01,$00,$FC,$00,$91,$3F,$40
  DEFB $FE,$01,$00,$DF,$00,$1C,$3F,$40
  DEFB $FE,$01,$00,$F7,$00,$23,$3F,$40
  DEFB $FE,$01,$00,$BD,$00,$20,$3F,$C0
  DEFB $FE,$01,$00,$0F,$00,$40,$3F,$C0
  DEFB $FE,$01,$00,$83,$00,$40,$3F,$40
  DEFB $FF,$00,$80,$62,$00,$98,$3F,$40
  DEFB $FF,$00,$80,$5A,$00,$86,$3F,$40
  DEFB $FF,$00,$C0,$2D,$00,$00,$3F,$40
  DEFB $FF,$00,$C0,$31,$00,$00,$7F,$80
  DEFB $FF,$00,$E0,$12,$00,$60,$7F,$80
  DEFB $FF,$00,$E0,$12,$00,$19,$FF,$00
  DEFB $FF,$00,$E0,$14,$00,$01,$FF,$00
  DEFB $FF,$00,$E0,$14,$01,$02,$FF,$00
  DEFB $FF,$00,$E0,$19,$01,$82,$FF,$00
  DEFB $FF,$00,$E0,$18,$03,$64,$FF,$00
  DEFB $FF,$00,$E0,$10,$03,$04,$FF,$00
  DEFB $FF,$00,$F0,$0E,$07,$18,$FF,$00
  DEFB $FF,$00,$FE,$01,$1F,$E0,$FF,$00

; Sprite 35 (even column; SpriteTable 70): phasers facing Y+, 29 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersYp:
  DEFB $1D,$03

; SprPhasersYp: 29 rows of 3 (mask, graphic) pairs, bottom line first
SprPhasersYpRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$9C,$63,$FF,$00
  DEFB $FE,$01,$00,$9E,$3F,$C0
  DEFB $F8,$06,$00,$06,$3F,$40
  DEFB $F0,$0C,$00,$4F,$3F,$40
  DEFB $F0,$0B,$00,$0C,$1F,$E0
  DEFB $E0,$18,$00,$DC,$0F,$90
  DEFB $E0,$1A,$00,$19,$0F,$10
  DEFB $C0,$2A,$00,$B9,$0F,$50
  DEFB $C0,$2A,$00,$B2,$0F,$10
  DEFB $C0,$28,$00,$B2,$0F,$D0
  DEFB $C0,$2C,$00,$24,$0F,$30
  DEFB $C0,$33,$00,$35,$0F,$10
  DEFB $C0,$30,$00,$CD,$0F,$50
  DEFB $C0,$22,$00,$31,$0F,$50
  DEFB $C0,$22,$00,$0C,$0F,$50
  DEFB $C0,$24,$00,$23,$0F,$10
  DEFB $C0,$24,$00,$20,$0F,$D0
  DEFB $C0,$20,$00,$42,$0F,$30
  DEFB $E0,$10,$00,$42,$1F,$20
  DEFB $E0,$10,$00,$04,$1F,$20
  DEFB $F0,$0C,$00,$04,$3F,$40
  DEFB $FC,$03,$00,$00,$3F,$40
  DEFB $FF,$00,$00,$E1,$7F,$80
  DEFB $FF,$00,$E1,$1E,$FF,$00

; Sprite 35 (odd column; SpriteTable 71): phasers facing Y+, 29 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersYpOdd:
  DEFB $1D,$04

; SprPhasersYpOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first
SprPhasersYpOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F9,$06,$CF,$30,$FF,$00
  DEFB $FF,$00,$E0,$19,$03,$EC,$FF,$00
  DEFB $FF,$00,$80,$60,$03,$64,$FF,$00
  DEFB $FF,$00,$00,$C4,$03,$F4,$FF,$00
  DEFB $FF,$00,$00,$B0,$01,$CE,$FF,$00
  DEFB $FE,$01,$00,$8D,$00,$C9,$FF,$00
  DEFB $FE,$01,$00,$A1,$00,$91,$FF,$00
  DEFB $FC,$02,$00,$AB,$00,$95,$FF,$00
  DEFB $FC,$02,$00,$AB,$00,$21,$FF,$00
  DEFB $FC,$02,$00,$8B,$00,$2D,$FF,$00
  DEFB $FC,$02,$00,$C2,$00,$43,$FF,$00
  DEFB $FC,$03,$00,$33,$00,$51,$FF,$00
  DEFB $FC,$03,$00,$0C,$00,$D5,$FF,$00
  DEFB $FC,$02,$00,$23,$00,$15,$FF,$00
  DEFB $FC,$02,$00,$20,$00,$C5,$FF,$00
  DEFB $FC,$02,$00,$42,$00,$31,$FF,$00
  DEFB $FC,$02,$00,$42,$00,$0D,$FF,$00
  DEFB $FC,$02,$00,$04,$00,$23,$FF,$00
  DEFB $FE,$01,$00,$04,$01,$22,$FF,$00
  DEFB $FE,$01,$00,$00,$01,$42,$FF,$00
  DEFB $FF,$00,$00,$C0,$03,$44,$FF,$00
  DEFB $FF,$00,$C0,$30,$03,$04,$FF,$00
  DEFB $FF,$00,$F0,$0E,$07,$18,$FF,$00
  DEFB $FF,$00,$FE,$01,$1F,$E0,$FF,$00

; Sprite 36 (even column; SpriteTable 72): phasers facing Y-, 26 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersYm:
  DEFB $1A,$03

; SprPhasersYm: 26 rows of 3 (mask, graphic) pairs, bottom line first
SprPhasersYmRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$8F,$70,$FF,$00
  DEFB $FE,$01,$03,$8C,$FF,$00
  DEFB $FC,$02,$00,$03,$FF,$00
  DEFB $FC,$02,$00,$20,$3F,$C0
  DEFB $F8,$05,$00,$24,$0F,$30
  DEFB $F8,$05,$00,$04,$07,$08
  DEFB $F0,$08,$00,$70,$07,$48
  DEFB $F0,$0D,$00,$8C,$03,$54
  DEFB $E0,$1A,$00,$03,$03,$14
  DEFB $E0,$1A,$00,$20,$03,$C4
  DEFB $C0,$2C,$00,$20,$03,$34
  DEFB $E0,$1C,$00,$42,$03,$0C
  DEFB $E0,$18,$00,$42,$03,$0C
  DEFB $F0,$0C,$00,$04,$03,$24
  DEFB $FC,$03,$00,$04,$03,$24
  DEFB $FE,$01,$00,$C0,$03,$44
  DEFB $FE,$01,$00,$F0,$03,$44
  DEFB $FC,$03,$00,$8C,$07,$08
  DEFB $FC,$03,$0C,$93,$07,$08
  DEFB $FC,$03,$0F,$10,$0F,$D0
  DEFB $FC,$03,$1F,$20,$CF,$30
  DEFB $FC,$02,$1F,$20,$FF,$00
  DEFB $FC,$03,$3F,$40,$FF,$00
  DEFB $FF,$00,$3F,$C0,$FF,$00

; Sprite 36 (odd column; SpriteTable 73): phasers facing Y-, 26 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprPhasersYmOdd:
  DEFB $1A,$04

; SprPhasersYmOdd: 26 rows of 4 (mask, graphic) pairs, bottom line first
SprPhasersYmOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F8,$07,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$18,$3F,$C0,$FF,$00
  DEFB $FF,$00,$C0,$20,$0F,$30,$FF,$00
  DEFB $FF,$00,$C0,$22,$03,$0C,$FF,$00
  DEFB $FF,$00,$80,$52,$00,$43,$FF,$00
  DEFB $FF,$00,$80,$50,$00,$40,$7F,$80
  DEFB $FF,$00,$00,$87,$00,$04,$7F,$80
  DEFB $FF,$00,$00,$D8,$00,$C5,$3F,$40
  DEFB $FE,$01,$00,$A0,$00,$31,$3F,$40
  DEFB $FE,$01,$00,$A2,$00,$0C,$3F,$40
  DEFB $FC,$02,$00,$C2,$00,$03,$3F,$40
  DEFB $FE,$01,$00,$C4,$00,$20,$3F,$C0
  DEFB $FE,$01,$00,$84,$00,$20,$3F,$C0
  DEFB $FF,$00,$00,$C0,$00,$42,$3F,$40
  DEFB $FF,$00,$C0,$30,$00,$42,$3F,$40
  DEFB $FF,$00,$E0,$1C,$00,$04,$3F,$40
  DEFB $FF,$00,$E0,$1F,$00,$04,$3F,$40
  DEFB $FF,$00,$C0,$38,$00,$C0,$7F,$80
  DEFB $FF,$00,$C0,$39,$C0,$30,$7F,$80
  DEFB $FF,$00,$C0,$31,$F0,$0D,$FF,$00
  DEFB $FF,$00,$C1,$32,$FC,$03,$FF,$00
  DEFB $FF,$00,$C1,$22,$FF,$00,$FF,$00
  DEFB $FF,$00,$C3,$34,$FF,$00,$FF,$00
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00

; Sprite 37 (even column; SpriteTable 74): nuclear bomb (the ball with the
; trefoil), every direction, 29 rows x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. No recording drew it.
SprNuclear:
  DEFB $1D,$03

; SprNuclear: 29 rows of 3 (mask, graphic) pairs, bottom line first
SprNuclearRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$E3,$1C,$FF,$00
  DEFB $FF,$00,$00,$FB,$FF,$00
  DEFB $FC,$03,$00,$F8,$3F,$C0
  DEFB $FC,$03,$00,$DA,$0F,$30
  DEFB $F8,$07,$00,$78,$0F,$10
  DEFB $F8,$07,$00,$DA,$0F,$50
  DEFB $F0,$0B,$00,$78,$07,$18
  DEFB $F0,$0B,$00,$FC,$07,$58
  DEFB $E0,$13,$00,$E3,$07,$18
  DEFB $E0,$13,$00,$00,$03,$DC
  DEFB $C0,$24,$00,$7E,$03,$3C
  DEFB $C0,$25,$00,$FF,$03,$9C
  DEFB $C0,$29,$00,$3F,$03,$DC
  DEFB $C0,$2A,$00,$1E,$03,$CC
  DEFB $C0,$32,$00,$1C,$03,$6C
  DEFB $C0,$36,$00,$38,$03,$2C
  DEFB $C0,$27,$00,$EC,$03,$24
  DEFB $C0,$27,$00,$C4,$07,$68
  DEFB $C0,$27,$00,$EF,$07,$C8
  DEFB $E0,$17,$00,$3F,$0F,$D0
  DEFB $E0,$12,$00,$0F,$0F,$90
  DEFB $E0,$13,$00,$0F,$1F,$A0
  DEFB $F0,$09,$00,$8F,$1F,$20
  DEFB $F0,$0C,$00,$7C,$3F,$40
  DEFB $FC,$03,$00,$00,$3F,$C0
  DEFB $FF,$00,$00,$C7,$FF,$00
  DEFB $FF,$00,$C7,$38,$FF,$00

; Sprite 37 (odd column; SpriteTable 75): nuclear bomb (the ball with the
; trefoil), every direction, 29 rows x 4 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprNuclearOdd:
  DEFB $1D,$04

; SprNuclearOdd: 29 rows of 4 (mask, graphic) pairs, bottom line first
SprNuclearOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FE,$01,$3F,$C0,$FF,$00
  DEFB $FF,$00,$F0,$0F,$0F,$B0,$FF,$00
  DEFB $FF,$00,$C0,$3F,$03,$8C,$FF,$00
  DEFB $FF,$00,$C0,$3D,$00,$A3,$FF,$00
  DEFB $FF,$00,$80,$77,$00,$81,$FF,$00
  DEFB $FF,$00,$80,$7D,$00,$A5,$FF,$00
  DEFB $FF,$00,$00,$B7,$00,$81,$7F,$80
  DEFB $FF,$00,$00,$BF,$00,$C5,$7F,$80
  DEFB $FE,$01,$00,$3E,$00,$31,$7F,$80
  DEFB $FE,$01,$00,$30,$00,$0D,$3F,$C0
  DEFB $FC,$02,$00,$47,$00,$E3,$3F,$C0
  DEFB $FC,$02,$00,$5F,$00,$F9,$3F,$C0
  DEFB $FC,$02,$00,$93,$00,$FD,$3F,$C0
  DEFB $FC,$02,$00,$A1,$00,$EC,$3F,$C0
  DEFB $FC,$03,$00,$21,$00,$C6,$3F,$C0
  DEFB $FC,$03,$00,$63,$00,$82,$3F,$C0
  DEFB $FC,$02,$00,$7E,$00,$C2,$3F,$40
  DEFB $FC,$02,$00,$7C,$00,$46,$7F,$80
  DEFB $FC,$02,$00,$7E,$00,$FC,$7F,$80
  DEFB $FE,$01,$00,$73,$00,$FD,$FF,$00
  DEFB $FE,$01,$00,$20,$00,$F9,$FF,$00
  DEFB $FE,$01,$00,$30,$01,$FA,$FF,$00
  DEFB $FF,$00,$00,$98,$01,$F2,$FF,$00
  DEFB $FF,$00,$00,$C7,$03,$C4,$FF,$00
  DEFB $FF,$00,$C0,$30,$03,$0C,$FF,$00
  DEFB $FF,$00,$F0,$0C,$0F,$70,$FF,$00
  DEFB $FF,$00,$FC,$03,$7F,$80,$FF,$00

; Sprite 38 (even column; SpriteTable 76): electronics dome facing X+, 24 rows
; x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsXp:
  DEFB $18,$03

; SprElectronicsXp: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsXpRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$9F,$60,$FF,$00
  DEFB $FF,$00,$87,$58,$FF,$00
  DEFB $FF,$00,$01,$C6,$FF,$00
  DEFB $FF,$00,$00,$D9,$7F,$80
  DEFB $FE,$01,$00,$5E,$1F,$60
  DEFB $FE,$01,$00,$E7,$1F,$A0
  DEFB $FC,$02,$00,$99,$1F,$A0
  DEFB $FC,$03,$00,$06,$1F,$20
  DEFB $F8,$05,$00,$01,$1F,$A0
  DEFB $F8,$06,$00,$00,$1F,$60
  DEFB $F0,$0A,$00,$18,$3F,$40
  DEFB $F0,$0C,$00,$3C,$3F,$40
  DEFB $F0,$0C,$00,$7C,$7F,$80
  DEFB $F0,$08,$00,$6C,$7F,$80
  DEFB $F0,$0C,$00,$5F,$FF,$00
  DEFB $FC,$03,$00,$7D,$7F,$80
  DEFB $FF,$00,$01,$FA,$FF,$00
  DEFB $FF,$00,$81,$72,$FF,$00
  DEFB $FF,$00,$E3,$1C,$FF,$00

; Sprite 38 (odd column; SpriteTable 77): electronics dome facing X+, 24 rows x
; 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsXpOdd:
  DEFB $18,$03

; SprElectronicsXpOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsXpOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F9,$06,$FF,$00
  DEFB $FF,$00,$F8,$05,$7F,$80
  DEFB $FF,$00,$F0,$0C,$1F,$60
  DEFB $FF,$00,$F0,$0D,$07,$98
  DEFB $FF,$00,$E0,$15,$01,$E6
  DEFB $FF,$00,$E0,$1E,$01,$7A
  DEFB $FF,$00,$C0,$29,$01,$9A
  DEFB $FF,$00,$C0,$30,$01,$62
  DEFB $FF,$00,$80,$50,$01,$1A
  DEFB $FF,$00,$80,$60,$01,$06
  DEFB $FF,$00,$00,$A1,$03,$84
  DEFB $FF,$00,$00,$C3,$03,$C4
  DEFB $FF,$00,$00,$C7,$07,$C8
  DEFB $FF,$00,$00,$86,$07,$C8
  DEFB $FF,$00,$00,$C5,$0F,$F0
  DEFB $FF,$00,$C0,$37,$07,$D8
  DEFB $FF,$00,$F0,$0F,$1F,$A0
  DEFB $FF,$00,$F8,$07,$1F,$20
  DEFB $FF,$00,$FE,$01,$3F,$C0

; Sprite 39 (even column; SpriteTable 78): electronics dome facing X-, 24 rows
; x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsXm:
  DEFB $18,$03

; SprElectronicsXm: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsXmRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$9F,$60,$FF,$00
  DEFB $FF,$00,$87,$58,$FF,$00
  DEFB $FF,$00,$01,$C6,$FF,$00
  DEFB $FF,$00,$00,$D9,$7F,$80
  DEFB $FE,$01,$00,$5E,$1F,$60
  DEFB $FE,$01,$00,$E7,$1F,$A0
  DEFB $FC,$02,$00,$99,$1F,$A0
  DEFB $FC,$03,$00,$06,$1F,$20
  DEFB $F8,$05,$00,$01,$1F,$A0
  DEFB $F8,$06,$00,$00,$1F,$60
  DEFB $F0,$0A,$00,$18,$3F,$40
  DEFB $F0,$0C,$00,$2C,$3F,$40
  DEFB $F0,$0D,$00,$8E,$7F,$80
  DEFB $F0,$08,$00,$6E,$7F,$80
  DEFB $F0,$0C,$00,$1F,$FF,$00
  DEFB $FC,$03,$00,$4D,$FF,$00
  DEFB $FF,$00,$01,$DE,$FF,$00
  DEFB $FF,$00,$81,$5A,$FF,$00
  DEFB $FF,$00,$C3,$34,$FF,$00

; Sprite 39 (odd column; SpriteTable 79): electronics dome facing X-, 24 rows x
; 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights. Also the part's icon in ConstructionMenu ($C86D, drawn straight
; to the screen by DrawMaskedUp).
SprElectronicsXmOdd:
  DEFB $18,$03

; SprElectronicsXmOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsXmOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F9,$06,$FF,$00
  DEFB $FF,$00,$F8,$05,$7F,$80
  DEFB $FF,$00,$F0,$0C,$1F,$60
  DEFB $FF,$00,$F0,$0D,$07,$98
  DEFB $FF,$00,$E0,$15,$01,$E6
  DEFB $FF,$00,$E0,$1E,$01,$7A
  DEFB $FF,$00,$C0,$29,$01,$9A
  DEFB $FF,$00,$C0,$30,$01,$62
  DEFB $FF,$00,$80,$50,$01,$1A
  DEFB $FF,$00,$80,$60,$01,$06
  DEFB $FF,$00,$00,$A1,$03,$84
  DEFB $FF,$00,$00,$C2,$03,$C4
  DEFB $FF,$00,$00,$D8,$07,$E8
  DEFB $FF,$00,$00,$86,$07,$E8
  DEFB $FF,$00,$00,$C1,$0F,$F0
  DEFB $FF,$00,$C0,$34,$0F,$D0
  DEFB $FF,$00,$F0,$0D,$1F,$E0
  DEFB $FF,$00,$F8,$05,$1F,$A0
  DEFB $FF,$00,$FC,$03,$3F,$40

; Sprite 40 (even column; SpriteTable 80): electronics dome facing Y+, 24 rows
; x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsYp:
  DEFB $18,$03

; SprElectronicsYp: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsYpRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$9F,$60,$FF,$00
  DEFB $FF,$00,$87,$58,$FF,$00
  DEFB $FF,$00,$01,$C6,$FF,$00
  DEFB $FF,$00,$00,$D9,$7F,$80
  DEFB $FE,$01,$00,$5E,$1F,$60
  DEFB $FE,$01,$00,$E7,$1F,$A0
  DEFB $FC,$02,$00,$99,$1F,$A0
  DEFB $FC,$03,$00,$06,$1F,$20
  DEFB $F8,$05,$00,$01,$1F,$A0
  DEFB $F8,$06,$00,$00,$1F,$60
  DEFB $F0,$0A,$00,$3C,$3F,$40
  DEFB $F0,$0C,$00,$64,$3F,$40
  DEFB $F0,$0C,$00,$CA,$7F,$80
  DEFB $F0,$08,$00,$DA,$7F,$80
  DEFB $F0,$0C,$00,$D3,$FF,$00
  DEFB $FC,$03,$00,$C3,$FF,$00
  DEFB $FF,$00,$01,$E6,$FF,$00
  DEFB $FF,$00,$C1,$3A,$FF,$00
  DEFB $FF,$00,$F3,$0C,$FF,$00

; Sprite 40 (odd column; SpriteTable 81): electronics dome facing Y+, 24 rows x
; 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsYpOdd:
  DEFB $18,$03

; SprElectronicsYpOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsYpOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F9,$06,$FF,$00
  DEFB $FF,$00,$F8,$05,$7F,$80
  DEFB $FF,$00,$F0,$0C,$1F,$60
  DEFB $FF,$00,$F0,$0D,$07,$98
  DEFB $FF,$00,$E0,$15,$01,$E6
  DEFB $FF,$00,$E0,$1E,$01,$7A
  DEFB $FF,$00,$C0,$29,$01,$9A
  DEFB $FF,$00,$C0,$30,$01,$62
  DEFB $FF,$00,$80,$50,$01,$1A
  DEFB $FF,$00,$80,$60,$01,$06
  DEFB $FF,$00,$00,$A3,$03,$C4
  DEFB $FF,$00,$00,$C6,$03,$44
  DEFB $FF,$00,$00,$CC,$07,$A8
  DEFB $FF,$00,$00,$8D,$07,$A8
  DEFB $FF,$00,$00,$CD,$0F,$30
  DEFB $FF,$00,$C0,$3C,$0F,$30
  DEFB $FF,$00,$F0,$0E,$1F,$60
  DEFB $FF,$00,$FC,$03,$1F,$A0
  DEFB $FF,$00,$FF,$00,$3F,$C0

; Sprite 41 (even column; SpriteTable 82): electronics dome facing Y-, 24 rows
; x 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsYm:
  DEFB $18,$03

; SprElectronicsYm: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsYmRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$9F,$60,$FF,$00
  DEFB $FF,$00,$87,$58,$FF,$00
  DEFB $FF,$00,$01,$C6,$FF,$00
  DEFB $FF,$00,$00,$D9,$7F,$80
  DEFB $FE,$01,$00,$5E,$1F,$60
  DEFB $FE,$01,$00,$E7,$1F,$A0
  DEFB $FC,$02,$00,$99,$1F,$A0
  DEFB $FC,$03,$00,$06,$1F,$20
  DEFB $F8,$05,$00,$01,$1F,$A0
  DEFB $F8,$06,$00,$1C,$1F,$60
  DEFB $F0,$0A,$00,$3E,$3F,$40
  DEFB $F0,$0C,$00,$76,$3F,$40
  DEFB $F0,$0C,$00,$7A,$7F,$80
  DEFB $F0,$08,$00,$7E,$7F,$80
  DEFB $F0,$0C,$00,$7F,$FF,$00
  DEFB $FC,$03,$00,$3D,$FF,$00
  DEFB $FF,$00,$01,$DA,$FF,$00
  DEFB $FF,$00,$81,$72,$FF,$00
  DEFB $FF,$00,$F3,$0C,$FF,$00

; Sprite 41 (odd column; SpriteTable 83): electronics dome facing Y-, 24 rows x
; 3 bytes
;
; Drawn by DrawRobotPart through DrawSprite for every part of a robot in the
; view (sprite id = $16 + PartSpriteTable[part * 4 + direction]), stacked by
; PartHeights.
SprElectronicsYmOdd:
  DEFB $18,$03

; SprElectronicsYmOdd: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprElectronicsYmOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F9,$06,$FF,$00
  DEFB $FF,$00,$F8,$05,$7F,$80
  DEFB $FF,$00,$F0,$0C,$1F,$60
  DEFB $FF,$00,$F0,$0D,$07,$98
  DEFB $FF,$00,$E0,$15,$01,$E6
  DEFB $FF,$00,$E0,$1E,$01,$7A
  DEFB $FF,$00,$C0,$29,$01,$9A
  DEFB $FF,$00,$C0,$30,$01,$62
  DEFB $FF,$00,$80,$50,$01,$1A
  DEFB $FF,$00,$80,$61,$01,$C6
  DEFB $FF,$00,$00,$A3,$03,$E4
  DEFB $FF,$00,$00,$C7,$03,$64
  DEFB $FF,$00,$00,$C7,$07,$A8
  DEFB $FF,$00,$00,$87,$07,$E8
  DEFB $FF,$00,$00,$C7,$0F,$F0
  DEFB $FF,$00,$C0,$33,$0F,$D0
  DEFB $FF,$00,$F0,$0D,$1F,$A0
  DEFB $FF,$00,$F8,$07,$1F,$20
  DEFB $FF,$00,$FF,$00,$3F,$C0

; Sprite 42 (even column; SpriteTable 84): the player's flag, building type 7,
; 11 rows x 3 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording drew
; it.
SprFlagPlayer:
  DEFB $0B,$03

; SprFlagPlayer: 11 rows of 3 (mask, graphic) pairs, bottom line first
SprFlagPlayerRows:
  DEFB $FF,$00,$F7,$08,$FF,$00
  DEFB $FF,$00,$E3,$1C,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00
  DEFB $FF,$00,$F1,$0E,$FF,$00
  DEFB $FF,$00,$F0,$09,$3F,$C0
  DEFB $FF,$00,$F0,$0F,$1F,$20
  DEFB $FF,$00,$F0,$0F,$1F,$E0
  DEFB $FF,$00,$F0,$09,$1F,$E0
  DEFB $FF,$00,$F0,$0F,$1F,$20
  DEFB $FF,$00,$FE,$01,$1F,$E0

; Sprite 42 (odd column; SpriteTable 85): the player's flag, building type 7,
; 11 rows x 4 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height).
SprFlagPlayerOdd:
  DEFB $0B,$04

; SprFlagPlayerOdd: 11 rows of 4 (mask, graphic) pairs, bottom line first
SprFlagPlayerOddRows:
  DEFB $FF,$00,$FF,$00,$7F,$80,$FF,$00
  DEFB $FF,$00,$FE,$01,$3F,$C0,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80,$FF,$00
  DEFB $FF,$00,$FF,$00,$1F,$E0,$FF,$00
  DEFB $FF,$00,$FF,$00,$03,$9C,$FF,$00
  DEFB $FF,$00,$FF,$00,$01,$F2,$FF,$00
  DEFB $FF,$00,$FF,$00,$01,$FE,$FF,$00
  DEFB $FF,$00,$FF,$00,$01,$9E,$FF,$00
  DEFB $FF,$00,$FF,$00,$01,$F2,$FF,$00
  DEFB $FF,$00,$FF,$00,$E1,$1E,$FF,$00

; Sprite 43 (even column; SpriteTable 86): the enemy's flag, building type 8,
; 11 rows x 3 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording drew
; it.
SprFlagEnemy:
  DEFB $0B,$03

; SprFlagEnemy: 11 rows of 3 (mask, graphic) pairs, bottom line first
SprFlagEnemyRows:
  DEFB $FF,$00,$F7,$08,$FF,$00
  DEFB $FF,$00,$E3,$1C,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00
  DEFB $FF,$00,$F1,$0E,$FF,$00
  DEFB $FF,$00,$F0,$0D,$3F,$C0
  DEFB $FF,$00,$F0,$0A,$1F,$A0
  DEFB $FF,$00,$F0,$0D,$1F,$60
  DEFB $FF,$00,$F0,$0A,$1F,$A0
  DEFB $FF,$00,$F0,$0F,$1F,$60
  DEFB $FF,$00,$FE,$01,$1F,$E0

; Sprite 43 (odd column; SpriteTable 87): the enemy's flag, building type 8, 11
; rows x 4 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording drew
; it.
SprFlagEnemyOdd:
  DEFB $0B,$04

; SprFlagEnemyOdd: 11 rows of 4 (mask, graphic) pairs, bottom line first
SprFlagEnemyOddRows:
  DEFB $FF,$00,$FF,$00,$7F,$80,$FF,$00
  DEFB $FF,$00,$FE,$01,$3F,$C0,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80,$FF,$00
  DEFB $FF,$00,$FF,$00,$1F,$E0,$FF,$00
  DEFB $FF,$00,$FF,$00,$03,$DC,$FF,$00
  DEFB $FF,$00,$FF,$00,$01,$AA,$FF,$00
  DEFB $FF,$00,$FF,$00,$01,$D6,$FF,$00
  DEFB $FF,$00,$FF,$00,$01,$AA,$FF,$00
  DEFB $FF,$00,$FF,$00,$01,$F6,$FF,$00
  DEFB $FF,$00,$FF,$00,$E1,$1E,$FF,$00

; Sprite 44 (even column; SpriteTable 88): the warbase sign, building type 0,
; 17 rows x 3 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height). No recording drew
; it.
SprWarbaseSign:
  DEFB $11,$03

; SprWarbaseSign: 17 rows of 3 (mask, graphic) pairs, bottom line first
SprWarbaseSignRows:
  DEFB $FF,$00,$9F,$60,$FF,$00
  DEFB $FF,$00,$87,$58,$FF,$00
  DEFB $FF,$00,$01,$86,$FF,$00
  DEFB $FF,$00,$00,$B1,$7F,$80
  DEFB $FE,$01,$00,$38,$1F,$60
  DEFB $FE,$01,$00,$79,$07,$18
  DEFB $FC,$02,$00,$71,$07,$C8
  DEFB $FC,$02,$00,$FB,$0F,$D0
  DEFB $F8,$04,$00,$FF,$0F,$90
  DEFB $F8,$05,$00,$EF,$1F,$A0
  DEFB $F0,$09,$00,$C7,$1F,$20
  DEFB $F0,$0C,$00,$4F,$3F,$40
  DEFB $FC,$03,$00,$0E,$3F,$40
  DEFB $FF,$00,$00,$C6,$7F,$80
  DEFB $FF,$00,$C0,$30,$7F,$80
  DEFB $FF,$00,$F0,$0D,$FF,$00
  DEFB $FF,$00,$FC,$03,$FF,$00

; Sprite 44 (odd column; SpriteTable 89): the warbase sign, building type 0, 17
; rows x 4 bytes
;
; Drawn by DrawCellObject on a Buildings record of this type, through the table
; BuildingSprites (sprite id) / BuildingSprites+9 (height).
SprWarbaseSignOdd:
  DEFB $11,$04

; SprWarbaseSignOdd: 17 rows of 4 (mask, graphic) pairs, bottom line first
SprWarbaseSignOddRows:
  DEFB $FF,$00,$F9,$06,$FF,$00,$FF,$00
  DEFB $FF,$00,$F8,$05,$7F,$80,$FF,$00
  DEFB $FF,$00,$F0,$08,$1F,$60,$FF,$00
  DEFB $FF,$00,$F0,$0B,$07,$18,$FF,$00
  DEFB $FF,$00,$E0,$13,$01,$86,$FF,$00
  DEFB $FF,$00,$E0,$17,$00,$91,$7F,$80
  DEFB $FF,$00,$C0,$27,$00,$1C,$7F,$80
  DEFB $FF,$00,$C0,$2F,$00,$BD,$FF,$00
  DEFB $FF,$00,$80,$4F,$00,$F9,$FF,$00
  DEFB $FF,$00,$80,$5E,$01,$FA,$FF,$00
  DEFB $FF,$00,$00,$9C,$01,$72,$FF,$00
  DEFB $FF,$00,$00,$C4,$03,$F4,$FF,$00
  DEFB $FF,$00,$C0,$30,$03,$E4,$FF,$00
  DEFB $FF,$00,$F0,$0C,$07,$68,$FF,$00
  DEFB $FF,$00,$FC,$03,$07,$08,$FF,$00
  DEFB $FF,$00,$FF,$00,$0F,$D0,$FF,$00
  DEFB $FF,$00,$FF,$00,$CF,$30,$FF,$00

; Sprite 45 (even column; SpriteTable 90): cannon shell, flying along X, 16
; rows x 2 bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotCannonX:
  DEFB $10,$02

; SprShotCannonX: 16 rows of 2 (mask, graphic) pairs, bottom line first
SprShotCannonXRows:
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FC,$03,$3F,$C0
  DEFB $FE,$01,$1F,$E0
  DEFB $FF,$00,$0F,$F0
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $E1,$1E,$FF,$00
  DEFB $F0,$0F,$FF,$00
  DEFB $F8,$07,$7F,$80

; Sprite 45 (odd column; SpriteTable 91): cannon shell, flying along X, 16 rows
; x 2 bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotCannonXOdd:
  DEFB $10,$02

; SprShotCannonXOdd: 16 rows of 2 (mask, graphic) pairs, bottom line first
SprShotCannonXOddRows:
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$C3,$3C
  DEFB $FF,$00,$E1,$1E
  DEFB $FF,$00,$F0,$0F
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FE,$01,$1F,$E0
  DEFB $FF,$00,$0F,$F0
  DEFB $FF,$00,$87,$78

; Sprite 46 (even column; SpriteTable 92): cannon shell, flying along Y, 13
; rows x 3 bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotCannonY:
  DEFB $0D,$03

; SprShotCannonY: 13 rows of 3 (mask, graphic) pairs, bottom line first
SprShotCannonYRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00
  DEFB $FF,$00,$E7,$18,$FF,$00
  DEFB $FF,$00,$C7,$38,$FF,$00
  DEFB $FF,$00,$C7,$38,$DF,$20
  DEFB $FF,$00,$CF,$30,$9F,$60
  DEFB $FF,$00,$DF,$20,$1F,$E0
  DEFB $FF,$00,$FF,$00,$1F,$E0
  DEFB $FF,$00,$FF,$00,$3F,$C0
  DEFB $FF,$00,$FF,$00,$7F,$80

; Sprite 46 (odd column; SpriteTable 93): cannon shell, flying along Y, 13 rows
; x 3 bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotCannonYOdd:
  DEFB $0D,$03

; SprShotCannonYOdd: 13 rows of 3 (mask, graphic) pairs, bottom line first
SprShotCannonYOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80
  DEFB $FF,$00,$FE,$01,$7F,$80
  DEFB $FF,$00,$FC,$03,$7F,$80
  DEFB $FF,$00,$FC,$03,$7D,$82
  DEFB $FF,$00,$FC,$03,$F9,$06
  DEFB $FF,$00,$FD,$02,$F1,$0E
  DEFB $FF,$00,$FF,$00,$F1,$0E
  DEFB $FF,$00,$FF,$00,$F3,$0C
  DEFB $FF,$00,$FF,$00,$F7,$08

; Sprite 47 (even column; SpriteTable 94): missile, flying along X, 22 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotMissileX:
  DEFB $16,$03

; SprShotMissileX: 22 rows of 3 (mask, graphic) pairs, bottom line first
SprShotMissileXRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$3F,$C0,$FF,$00
  DEFB $FF,$00,$0F,$F0,$FF,$00
  DEFB $FF,$00,$C3,$3C,$FF,$00
  DEFB $FF,$00,$F0,$0F,$FF,$00
  DEFB $FF,$00,$FC,$03,$3F,$C0
  DEFB $FF,$00,$FF,$00,$0F,$F0
  DEFB $FF,$00,$FF,$00,$C3,$3C
  DEFB $FF,$00,$FF,$00,$F3,$0C
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $E7,$18,$FF,$00,$FF,$00
  DEFB $E1,$1E,$FF,$00,$FF,$00
  DEFB $F8,$07,$7F,$80,$FF,$00
  DEFB $FE,$01,$1F,$E0,$FF,$00
  DEFB $FF,$00,$87,$78,$FF,$00
  DEFB $FF,$00,$E1,$1E,$FF,$00
  DEFB $FF,$00,$F8,$07,$7F,$80
  DEFB $FF,$00,$FE,$01,$7F,$80

; Sprite 47 (odd column; SpriteTable 95): missile, flying along X, 22 rows x 4
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotMissileXOdd:
  DEFB $16,$04

; SprShotMissileXOdd: 22 rows of 4 (mask, graphic) pairs, bottom line first
SprShotMissileXOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0F,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$03,$3F,$C0,$FF,$00
  DEFB $FF,$00,$FF,$00,$0F,$F0,$FF,$00
  DEFB $FF,$00,$FF,$00,$C3,$3C,$FF,$00
  DEFB $FF,$00,$FF,$00,$F0,$0F,$FF,$00
  DEFB $FF,$00,$FF,$00,$FC,$03,$3F,$C0
  DEFB $FF,$00,$FF,$00,$FF,$00,$3F,$C0
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$01,$7F,$80,$FF,$00,$FF,$00
  DEFB $FE,$01,$1F,$E0,$FF,$00,$FF,$00
  DEFB $FF,$00,$87,$78,$FF,$00,$FF,$00
  DEFB $FF,$00,$E1,$1E,$FF,$00,$FF,$00
  DEFB $FF,$00,$F8,$07,$7F,$80,$FF,$00
  DEFB $FF,$00,$FE,$01,$1F,$E0,$FF,$00
  DEFB $FF,$00,$FF,$00,$87,$78,$FF,$00
  DEFB $FF,$00,$FF,$00,$E7,$18,$FF,$00

; Sprite 48 (even column; SpriteTable 96): missile, flying along Y, 22 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotMissileY:
  DEFB $16,$03

; SprShotMissileY: 22 rows of 3 (mask, graphic) pairs, bottom line first
SprShotMissileYRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$CF,$30,$FF,$00
  DEFB $FF,$00,$CF,$30,$FF,$00
  DEFB $FF,$00,$9F,$60,$FF,$00
  DEFB $FF,$00,$9F,$60,$FF,$00
  DEFB $FF,$00,$3F,$C0,$FF,$00
  DEFB $FF,$00,$3F,$C0,$F3,$0C
  DEFB $FE,$01,$7F,$80,$F3,$0C
  DEFB $FE,$01,$7F,$80,$E7,$18
  DEFB $FC,$03,$FF,$00,$E7,$18
  DEFB $FC,$03,$FF,$00,$CF,$30
  DEFB $F9,$06,$FF,$00,$CF,$30
  DEFB $F9,$06,$FF,$00,$9F,$60
  DEFB $F3,$0C,$FF,$00,$9F,$60
  DEFB $F3,$0C,$FF,$00,$3F,$C0
  DEFB $FF,$00,$FF,$00,$3F,$C0
  DEFB $FF,$00,$FE,$01,$7F,$80
  DEFB $FF,$00,$FE,$01,$7F,$80
  DEFB $FF,$00,$FC,$03,$FF,$00
  DEFB $FF,$00,$FC,$03,$FF,$00

; Sprite 48 (odd column; SpriteTable 97): missile, flying along Y, 22 rows x 4
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotMissileYOdd:
  DEFB $16,$04

; SprShotMissileYOdd: 22 rows of 4 (mask, graphic) pairs, bottom line first
SprShotMissileYOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$03,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$03,$FF,$00,$FF,$00
  DEFB $FF,$00,$F9,$06,$FF,$00,$FF,$00
  DEFB $FF,$00,$F9,$06,$FF,$00,$FF,$00
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F3,$0C,$FF,$00,$3F,$C0
  DEFB $FF,$00,$E7,$18,$FF,$00,$3F,$C0
  DEFB $FF,$00,$E7,$18,$FE,$01,$7F,$80
  DEFB $FF,$00,$CF,$30,$FE,$01,$7F,$80
  DEFB $FF,$00,$CF,$30,$FC,$03,$FF,$00
  DEFB $FF,$00,$9F,$60,$FC,$03,$FF,$00
  DEFB $FF,$00,$9F,$60,$F9,$06,$FF,$00
  DEFB $FF,$00,$3F,$C0,$F9,$06,$FF,$00
  DEFB $FF,$00,$3F,$C0,$F3,$0C,$FF,$00
  DEFB $FF,$00,$FF,$00,$F3,$0C,$FF,$00
  DEFB $FF,$00,$FF,$00,$E7,$18,$FF,$00
  DEFB $FF,$00,$FF,$00,$E7,$18,$FF,$00
  DEFB $FF,$00,$FF,$00,$CF,$30,$FF,$00
  DEFB $FF,$00,$FF,$00,$CF,$30,$FF,$00

; Sprite 49 (even column; SpriteTable 98): phaser beam, along X, 17 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotPhaserX:
  DEFB $11,$03

; SprShotPhaserX: 17 rows of 3 (mask, graphic) pairs, bottom line first
SprShotPhaserXRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$01,$FF,$00,$FF,$00
  DEFB $FB,$04,$BF,$40,$FF,$00
  DEFB $FD,$02,$EF,$10,$FF,$00
  DEFB $FF,$00,$3B,$C4,$FF,$00
  DEFB $FD,$02,$DE,$21,$FF,$00
  DEFB $FF,$00,$73,$8C,$BF,$40
  DEFB $FF,$00,$DD,$22,$EF,$10
  DEFB $FF,$00,$F7,$08,$3F,$C0
  DEFB $FF,$00,$FD,$02,$DF,$20
  DEFB $FF,$00,$FF,$00,$7F,$80

; Sprite 49 (odd column; SpriteTable 99): phaser beam, along X, 17 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotPhaserXOdd:
  DEFB $11,$03

; SprShotPhaserXOdd: 17 rows of 3 (mask, graphic) pairs, bottom line first
SprShotPhaserXOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$EF,$10,$FF,$00
  DEFB $FF,$00,$BB,$44,$FF,$00
  DEFB $FF,$00,$DE,$21,$FF,$00
  DEFB $FF,$00,$F3,$0C,$BF,$40
  DEFB $FF,$00,$DD,$22,$EF,$10
  DEFB $FF,$00,$F7,$08,$3B,$C4
  DEFB $FF,$00,$FD,$02,$DE,$21
  DEFB $FF,$00,$FF,$00,$73,$8C
  DEFB $FF,$00,$FF,$00,$DD,$22
  DEFB $FF,$00,$FF,$00,$F7,$08

; Sprite 50 (even column; SpriteTable 100): phaser beam, along Y, 20 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotPhaserY:
  DEFB $14,$03

; SprShotPhaserY: 20 rows of 3 (mask, graphic) pairs, bottom line first
SprShotPhaserYRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FA,$05,$FF,$00
  DEFB $FF,$00,$FE,$01,$BF,$40
  DEFB $FF,$00,$F5,$0A,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80
  DEFB $FF,$00,$EB,$14,$FF,$00
  DEFB $FF,$00,$FA,$05,$FF,$00
  DEFB $FF,$00,$D7,$28,$FF,$00
  DEFB $FF,$00,$FD,$02,$FF,$00
  DEFB $FF,$00,$AF,$50,$FF,$00
  DEFB $FF,$00,$EB,$14,$FF,$00
  DEFB $FF,$00,$5F,$A0,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00
  DEFB $FE,$01,$BF,$40,$FF,$00
  DEFB $FF,$00,$AF,$50,$FF,$00

; Sprite 50 (odd column; SpriteTable 101): phaser beam, along Y, 20 rows x 3
; bytes
;
; Drawn by DrawMoverSprite for a Shots record: sprite id $2B + 2 x weapon +
; (direction >= 4: flying along Y). No recording drew it.
SprShotPhaserYOdd:
  DEFB $14,$03

; SprShotPhaserYOdd: 20 rows of 3 (mask, graphic) pairs, bottom line first
SprShotPhaserYOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$AF,$50
  DEFB $FF,$00,$FF,$00,$EB,$14
  DEFB $FF,$00,$FF,$00,$5F,$A0
  DEFB $FF,$00,$FF,$00,$F7,$08
  DEFB $FF,$00,$FE,$01,$BF,$40
  DEFB $FF,$00,$FF,$00,$AF,$50
  DEFB $FF,$00,$FD,$02,$7F,$80
  DEFB $FF,$00,$FF,$00,$DF,$20
  DEFB $FF,$00,$FA,$05,$FF,$00
  DEFB $FF,$00,$FE,$01,$BF,$40
  DEFB $FF,$00,$F5,$0A,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80
  DEFB $FF,$00,$EB,$14,$FF,$00
  DEFB $FF,$00,$FA,$05,$FF,$00

; Sprite 0 (even column; SpriteTable 0, 38, 39, 40, 41): the player's ship, 30
; rows x 4 bytes
;
; Drawn by DrawCell / ShipDraw (sprite id 0) at the height Altitude over the
; ship's cell.
SprShip:
  DEFB $1E,$04

; SprShip: 30 rows of 4 (mask, graphic) pairs, bottom line first
SprShipRows:
  DEFB $FF,$00,$3F,$C0,$FF,$00,$FF,$00
  DEFB $FF,$00,$0F,$B0,$FF,$00,$FF,$00
  DEFB $FE,$01,$03,$8C,$FF,$00,$FF,$00
  DEFB $FE,$01,$01,$A2,$FF,$00,$FF,$00
  DEFB $FC,$03,$01,$8A,$FF,$00,$FF,$00
  DEFB $FC,$03,$00,$C3,$CF,$30,$FF,$00
  DEFB $F8,$07,$00,$32,$43,$AC,$FF,$00
  DEFB $F8,$07,$00,$0E,$00,$63,$FF,$00
  DEFB $F8,$06,$00,$02,$00,$68,$7F,$80
  DEFB $F8,$06,$00,$04,$00,$62,$7F,$80
  DEFB $E0,$1C,$00,$06,$00,$70,$7F,$80
  DEFB $E0,$16,$00,$31,$00,$CC,$7F,$80
  DEFB $C0,$37,$00,$2C,$00,$43,$7F,$80
  DEFB $C0,$37,$00,$73,$00,$00,$7F,$80
  DEFB $80,$76,$00,$4C,$00,$C1,$FF,$00
  DEFB $80,$7E,$00,$C3,$00,$21,$FF,$00
  DEFB $00,$E4,$00,$80,$01,$E2,$FF,$00
  DEFB $00,$E1,$00,$80,$01,$32,$FF,$00
  DEFB $00,$C1,$00,$08,$03,$5C,$FF,$00
  DEFB $00,$C3,$00,$1C,$0B,$74,$FF,$00
  DEFB $00,$82,$00,$08,$0F,$B0,$FF,$00
  DEFB $00,$C3,$00,$08,$0F,$D0,$FF,$00
  DEFB $C0,$31,$00,$C9,$0F,$70,$FF,$00
  DEFB $F1,$0E,$C0,$29,$0F,$10,$FF,$00
  DEFB $FD,$02,$C0,$2A,$1F,$20,$FF,$00
  DEFB $FF,$00,$C0,$2A,$1F,$20,$FF,$00
  DEFB $FF,$00,$C0,$28,$3F,$40,$FF,$00
  DEFB $FF,$00,$E0,$08,$3F,$40,$FF,$00
  DEFB $FF,$00,$E0,$0B,$7F,$80,$FF,$00
  DEFB $FF,$00,$E3,$08,$7F,$80,$FF,$00

; Sprite 0 (odd column; SpriteTable 1): the player's ship, 30 rows x 4 bytes
;
; Drawn by DrawCell / ShipDraw (sprite id 0) at the height Altitude over the
; ship's cell.
SprShipOdd:
  DEFB $1E,$04

; SprShipOdd: 30 rows of 4 (mask, graphic) pairs, bottom line first
SprShipOddRows:
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0B,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$18,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$1A,$1F,$20,$FF,$00
  DEFB $FF,$00,$C0,$38,$1F,$A0,$FF,$00
  DEFB $FF,$00,$C0,$3C,$0C,$33,$FF,$00
  DEFB $FF,$00,$80,$73,$04,$2A,$3F,$C0
  DEFB $FF,$00,$80,$70,$00,$E6,$0F,$30
  DEFB $FF,$00,$80,$60,$00,$26,$07,$88
  DEFB $FF,$00,$80,$60,$00,$46,$07,$28
  DEFB $FE,$01,$00,$C0,$00,$67,$07,$08
  DEFB $FE,$01,$00,$63,$00,$1C,$07,$C8
  DEFB $FC,$03,$00,$72,$00,$C4,$07,$38
  DEFB $FC,$03,$00,$77,$00,$30,$07,$08
  DEFB $F8,$07,$00,$64,$00,$CC,$0F,$10
  DEFB $F8,$07,$00,$EC,$00,$32,$0F,$10
  DEFB $F0,$0E,$00,$48,$00,$0E,$1F,$20
  DEFB $F0,$0E,$00,$18,$00,$03,$1F,$20
  DEFB $F0,$0C,$00,$10,$00,$85,$3F,$C0
  DEFB $F0,$0C,$00,$31,$00,$C7,$BF,$40
  DEFB $F0,$08,$00,$20,$00,$8B,$FF,$00
  DEFB $F0,$0C,$00,$30,$00,$8D,$FF,$00
  DEFB $FC,$03,$00,$1C,$00,$97,$FF,$00
  DEFB $FF,$00,$1C,$E2,$00,$91,$FF,$00
  DEFB $FF,$00,$DC,$22,$01,$A2,$FF,$00
  DEFB $FF,$00,$FC,$02,$01,$A2,$FF,$00
  DEFB $FF,$00,$FC,$02,$03,$84,$FF,$00
  DEFB $FF,$00,$FE,$00,$03,$84,$FF,$00
  DEFB $FF,$00,$FE,$00,$07,$B8,$FF,$00
  DEFB $FF,$00,$FE,$00,$37,$88,$FF,$00

; Sprite 1 (even column; SpriteTable 2): the ship's shadow on the ground, 24
; rows x 3 bytes
;
; Drawn by DrawMapObjects (sprite id 1) at height 0 under the ship, before the
; map.
SprShadow:
  DEFB $18,$03

; SprShadow: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprShadowRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$BF,$40,$FF,$00
  DEFB $FF,$00,$0F,$F0,$FF,$00
  DEFB $FF,$00,$03,$FC,$FF,$00
  DEFB $FE,$01,$03,$FC,$FF,$00
  DEFB $FE,$01,$03,$FC,$FF,$00
  DEFB $FC,$03,$01,$FE,$EF,$10
  DEFB $FE,$01,$00,$FF,$43,$BC
  DEFB $FF,$00,$00,$FF,$00,$FF
  DEFB $FF,$00,$00,$FF,$00,$FF
  DEFB $F6,$09,$00,$FF,$01,$FE
  DEFB $F2,$0D,$00,$FF,$01,$FE
  DEFB $E0,$1F,$00,$FF,$03,$FC
  DEFB $E0,$1F,$00,$FF,$13,$EC
  DEFB $C0,$3F,$00,$FF,$3F,$C0
  DEFB $C0,$3F,$00,$FF,$3F,$C0
  DEFB $C0,$3F,$00,$FF,$7F,$80
  DEFB $F0,$0F,$80,$7F,$3F,$C0
  DEFB $FD,$02,$E0,$1F,$1F,$E0
  DEFB $FF,$00,$F0,$0F,$1F,$E0
  DEFB $FF,$00,$F0,$0F,$3F,$C0
  DEFB $FF,$00,$F0,$0F,$3F,$C0
  DEFB $FF,$00,$FC,$03,$7F,$80
  DEFB $FF,$00,$FF,$00,$7F,$80

; Sprite 1 (odd column; SpriteTable 3): the ship's shadow on the ground, 24
; rows x 4 bytes
;
; Drawn by DrawMapObjects (sprite id 1) at height 0 under the ship, before the
; map.
SprShadowOdd:
  DEFB $18,$04

; SprShadowOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first
SprShadowOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FB,$04,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0F,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0F,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$1F,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$1F,$3F,$C0,$FF,$00
  DEFB $FF,$00,$C0,$3F,$1E,$E1,$FF,$00
  DEFB $FF,$00,$E0,$1F,$04,$FB,$3F,$C0
  DEFB $FF,$00,$F0,$0F,$00,$FF,$0F,$F0
  DEFB $FF,$00,$F0,$0F,$00,$FF,$0F,$F0
  DEFB $FF,$00,$60,$9F,$00,$FF,$1F,$E0
  DEFB $FF,$00,$20,$DF,$00,$FF,$1F,$E0
  DEFB $FE,$01,$00,$FF,$00,$FF,$3F,$C0
  DEFB $FE,$01,$00,$FF,$01,$FE,$3F,$C0
  DEFB $FC,$03,$00,$FF,$03,$FC,$FF,$00
  DEFB $FC,$03,$00,$FF,$03,$FC,$FF,$00
  DEFB $FC,$03,$00,$FF,$07,$F8,$FF,$00
  DEFB $FF,$00,$08,$F7,$03,$FC,$FF,$00
  DEFB $FF,$00,$DE,$21,$01,$FE,$FF,$00
  DEFB $FF,$00,$FF,$00,$01,$FE,$FF,$00
  DEFB $FF,$00,$FF,$00,$03,$FC,$FF,$00
  DEFB $FF,$00,$FF,$00,$03,$FC,$FF,$00
  DEFB $FF,$00,$FF,$00,$C7,$38,$FF,$00
  DEFB $FF,$00,$FF,$00,$F7,$08,$FF,$00

; Sprite 2 (both columns; SpriteTable 4, 5): stones, map type 2, 21 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprStonesA:
  DEFB $15,$03

; SprStonesA: 21 rows of 3 (mask, graphic) pairs, bottom line first
SprStonesARows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FE,$01,$BC,$43,$FF,$00
  DEFB $FF,$00,$7D,$82,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$1F,$E0
  DEFB $FF,$00,$F7,$08,$BF,$40
  DEFB $FE,$01,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$F7,$08
  DEFB $FF,$00,$FF,$00,$BF,$40
  DEFB $FF,$00,$B7,$48,$FF,$00
  DEFB $FF,$00,$CF,$30,$FF,$00
  DEFB $F9,$06,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$03,$FF,$00
  DEFB $FF,$00,$CF,$30,$FF,$00
  DEFB $FF,$00,$EF,$10,$FF,$00

; Sprite 3 (both columns; SpriteTable 6, 7): stones, map type 3, 22 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprStonesB:
  DEFB $16,$03

; SprStonesB: 22 rows of 3 (mask, graphic) pairs, bottom line first
SprStonesBRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$3F,$C0,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FE,$01,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$97,$68,$D7,$28
  DEFB $FF,$00,$CF,$30,$E7,$18
  DEFB $FD,$02,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$1F,$E0
  DEFB $FF,$00,$CF,$30,$BF,$40
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $F4,$0B,$FF,$00,$FF,$00
  DEFB $FD,$02,$F9,$06,$7F,$80
  DEFB $FF,$00,$FD,$02,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00

; Sprite 4 (both columns; SpriteTable 8, 9): stones, map type 4, 21 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprStonesC:
  DEFB $15,$03

; SprStonesC: 21 rows of 3 (mask, graphic) pairs, bottom line first
SprStonesCRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$9F,$60,$FF,$00
  DEFB $FF,$00,$BF,$40,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$BF,$40
  DEFB $FF,$00,$CF,$30,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FA,$05,$FF,$00
  DEFB $F7,$08,$F9,$06,$F7,$08
  DEFB $FE,$01,$BF,$40,$FF,$00
  DEFB $FF,$00,$7F,$80,$FF,$00
  DEFB $FF,$00,$FF,$00,$BF,$40
  DEFB $F9,$06,$F5,$0A,$FF,$00
  DEFB $FD,$02,$F9,$06,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$CF,$30
  DEFB $F7,$08,$BF,$40,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FB,$04,$7F,$80
  DEFB $FF,$00,$FC,$03,$FF,$00

; Sprite 5 (both columns; SpriteTable 10, 11): stones, map type 5, 20 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprStonesD:
  DEFB $14,$03

; SprStonesD: 20 rows of 3 (mask, graphic) pairs, bottom line first
SprStonesDRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$9F,$60,$FF,$00
  DEFB $F8,$07,$FE,$01,$7F,$80
  DEFB $FD,$02,$FE,$01,$F7,$08
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$D7,$28,$FF,$00
  DEFB $FD,$02,$EF,$10,$9F,$60
  DEFB $FF,$00,$FF,$00,$DF,$20
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FC,$03,$7F,$80,$FF,$00
  DEFB $FE,$01,$F7,$08,$FF,$00
  DEFB $FF,$00,$FF,$00,$3F,$C0
  DEFB $FF,$00,$FF,$00,$7F,$80

; Sprite 8 (both columns; SpriteTable 16, 17): rocks, map type 8, 25 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprRocksA:
  DEFB $19,$03

; SprRocksA: 25 rows of 3 (mask, graphic) pairs, bottom line first
SprRocksARows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$3F,$00,$FF,$00
  DEFB $FF,$00,$0F,$00,$FF,$00
  DEFB $FE,$00,$03,$00,$FF,$00
  DEFB $FE,$00,$00,$44,$FF,$00
  DEFB $FE,$00,$00,$48,$7F,$80
  DEFB $FE,$01,$00,$21,$6F,$00
  DEFB $FE,$01,$00,$02,$07,$10
  DEFB $FE,$01,$00,$12,$03,$20
  DEFB $FF,$00,$00,$A4,$03,$A4
  DEFB $FF,$00,$00,$88,$07,$88
  DEFB $E3,$08,$80,$4A,$0F,$50
  DEFB $E0,$05,$C2,$31,$5F,$A0
  DEFB $C1,$12,$C3,$04,$C7,$00
  DEFB $81,$48,$C0,$29,$C7,$28
  DEFB $80,$51,$81,$12,$EF,$10
  DEFB $C1,$26,$01,$4C,$FF,$00
  DEFB $C7,$28,$00,$80,$3F,$40
  DEFB $EF,$10,$80,$48,$3F,$80
  DEFB $FF,$00,$C0,$25,$1F,$20
  DEFB $FF,$00,$E0,$11,$3F,$40
  DEFB $FF,$00,$E0,$12,$3F,$40
  DEFB $FF,$00,$F0,$08,$7F,$80
  DEFB $FF,$00,$F0,$0B,$FF,$00
  DEFB $FF,$00,$FB,$04,$FF,$00

; Sprite 9 (both columns; SpriteTable 18, 19): rocks, map type 9, 26 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprRocksB:
  DEFB $1A,$03

; SprRocksB: 26 rows of 3 (mask, graphic) pairs, bottom line first
SprRocksBRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$DF,$00,$FF,$00
  DEFB $FF,$00,$83,$20,$FF,$00
  DEFB $FF,$00,$80,$10,$FF,$00
  DEFB $FF,$00,$00,$11,$1F,$00
  DEFB $FF,$00,$00,$52,$07,$08
  DEFB $F8,$01,$00,$28,$0F,$10
  DEFB $F0,$00,$00,$84,$1F,$60
  DEFB $F0,$0A,$00,$83,$1F,$80
  DEFB $F8,$04,$00,$4C,$1F,$20
  DEFB $FC,$00,$00,$30,$0F,$C0
  DEFB $C8,$02,$00,$03,$07,$08
  DEFB $C0,$21,$00,$84,$07,$50
  DEFB $E0,$10,$00,$78,$0F,$20
  DEFB $E0,$14,$00,$01,$0F,$00
  DEFB $F0,$09,$00,$06,$1F,$20
  DEFB $F0,$08,$00,$A8,$1F,$A0
  DEFB $F0,$08,$00,$90,$3F,$40
  DEFB $F8,$04,$00,$51,$FF,$00
  DEFB $F8,$05,$01,$22,$FF,$00
  DEFB $F8,$05,$03,$04,$FF,$00
  DEFB $F8,$04,$03,$84,$FF,$00
  DEFB $FC,$03,$87,$68,$FF,$00
  DEFB $FF,$00,$EF,$10,$FF,$00

; Sprite 10 (both columns; SpriteTable 20, 21): rocks, map type 10, 23 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprRocksC:
  DEFB $17,$03

; SprRocksC: 23 rows of 3 (mask, graphic) pairs, bottom line first
SprRocksCRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$0F,$90,$FF,$00
  DEFB $FF,$00,$03,$48,$FF,$00
  DEFB $FE,$00,$00,$48,$FF,$00
  DEFB $FC,$02,$00,$48,$3F,$80
  DEFB $FC,$01,$00,$21,$1F,$20
  DEFB $F8,$05,$00,$20,$1F,$40
  DEFB $F8,$04,$00,$21,$0F,$80
  DEFB $FC,$02,$00,$12,$07,$08
  DEFB $FC,$02,$00,$4C,$00,$31
  DEFB $FE,$01,$00,$22,$01,$42
  DEFB $E4,$10,$00,$C5,$03,$8C
  DEFB $F0,$0A,$00,$03,$07,$10
  DEFB $F0,$09,$00,$29,$03,$04
  DEFB $F8,$06,$00,$49,$07,$18
  DEFB $FC,$02,$00,$45,$0F,$60
  DEFB $FE,$01,$00,$92,$1F,$80
  DEFB $FE,$01,$00,$08,$1F,$20
  DEFB $FE,$01,$00,$23,$3F,$40
  DEFB $FF,$00,$03,$AC,$7F,$80
  DEFB $FF,$00,$8F,$50,$FF,$00
  DEFB $FF,$00,$9F,$60,$FF,$00

; Sprite 11 (both columns; SpriteTable 22, 23): rocks, map type 11, 24 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprRocksD:
  DEFB $18,$03

; SprRocksD: 24 rows of 3 (mask, graphic) pairs, bottom line first
SprRocksDRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$CF,$10,$FF,$00
  DEFB $FF,$00,$87,$28,$FF,$00
  DEFB $FF,$00,$E0,$19,$FF,$00
  DEFB $FF,$00,$B9,$06,$FF,$00
  DEFB $FC,$00,$07,$90,$8F,$40
  DEFB $FC,$00,$03,$50,$C3,$24
  DEFB $F8,$04,$01,$42,$C0,$29
  DEFB $F8,$03,$00,$44,$C1,$22
  DEFB $F0,$00,$00,$A4,$63,$94
  DEFB $F0,$06,$00,$61,$E3,$14
  DEFB $FE,$01,$00,$11,$F7,$08
  DEFB $DF,$20,$01,$92,$FF,$00
  DEFB $C1,$12,$83,$74,$83,$44
  DEFB $80,$49,$E7,$18,$07,$28
  DEFB $C0,$28,$FE,$01,$07,$28
  DEFB $C0,$24,$0F,$20,$0F,$90
  DEFB $C0,$24,$03,$C4,$8F,$50
  DEFB $E0,$11,$07,$18,$9F,$20
  DEFB $E0,$10,$1A,$20,$3F,$80
  DEFB $F0,$08,$30,$C3,$1F,$20
  DEFB $F0,$09,$F0,$09,$3F,$40
  DEFB $F9,$06,$F8,$04,$3F,$40
  DEFB $FF,$00,$FC,$03,$7F,$80

; Sprite 12 (even column; SpriteTable 24): trench start along Y (map type 12 on
; even rows), 20 rows x 3 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprTrenchStartY:
  DEFB $14,$03

; SprTrenchStartY: 20 rows of 3 (mask, graphic) pairs, bottom line first
SprTrenchStartYRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F3,$0C,$FF,$00
  DEFB $FF,$00,$F0,$0F,$FF,$00
  DEFB $FF,$00,$F0,$0F,$3F,$C0
  DEFB $FF,$00,$E0,$1F,$2F,$D0
  DEFB $FF,$00,$C0,$3F,$27,$D8
  DEFB $FF,$00,$C0,$3F,$2F,$D0
  DEFB $FF,$00,$C0,$3F,$AF,$50
  DEFB $FF,$00,$C0,$3F,$9F,$60
  DEFB $FF,$00,$80,$7F,$9F,$60
  DEFB $FF,$00,$82,$7D,$BF,$40
  DEFB $FF,$00,$82,$7D,$7F,$80
  DEFB $FF,$00,$02,$FD,$7F,$80
  DEFB $FF,$00,$2A,$D5,$FF,$00
  DEFB $FF,$00,$29,$D6,$FF,$00
  DEFB $FF,$00,$29,$D6,$FF,$00
  DEFB $FF,$00,$AB,$54,$FF,$00
  DEFB $FF,$00,$C3,$3C,$FF,$00
  DEFB $FF,$00,$EF,$10,$FF,$00

; Sprite 12 (odd column; SpriteTable 25): trench start along X (map type 12 on
; odd rows), 21 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprTrenchStartX:
  DEFB $15,$04

; SprTrenchStartX: 21 rows of 4 (mask, graphic) pairs, bottom line first
SprTrenchStartXRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F8,$07,$7F,$80,$FF,$00
  DEFB $FF,$00,$F0,$0F,$1F,$E0,$FF,$00
  DEFB $FF,$00,$E0,$1F,$07,$F8,$FF,$00
  DEFB $FF,$00,$E0,$1F,$03,$FC,$FF,$00
  DEFB $FF,$00,$C8,$37,$00,$FF,$FF,$00
  DEFB $FF,$00,$A8,$57,$00,$FF,$3F,$C0
  DEFB $FF,$00,$AA,$55,$00,$FF,$1F,$E0
  DEFB $FF,$00,$CA,$35,$00,$FF,$1F,$E0
  DEFB $FF,$00,$F2,$0D,$40,$BF,$3F,$C0
  DEFB $FF,$00,$FA,$05,$48,$B7,$3F,$C0
  DEFB $FF,$00,$FC,$03,$4A,$B5,$7F,$80
  DEFB $FF,$00,$FF,$00,$4A,$B5,$7F,$80
  DEFB $FF,$00,$FF,$00,$8A,$75,$FF,$00
  DEFB $FF,$00,$FF,$00,$F2,$0D,$FF,$00
  DEFB $FF,$00,$FF,$00,$FD,$02,$FF,$00

; Sprite 13 (even column; SpriteTable 26): trench middle along Y (map type 13
; on even rows), 23 rows x 3 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprTrenchMiddleY:
  DEFB $17,$03

; SprTrenchMiddleY: 23 rows of 3 (mask, graphic) pairs, bottom line first
SprTrenchMiddleYRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F3,$0C,$FF,$00
  DEFB $FF,$00,$F0,$0F,$FF,$00
  DEFB $FF,$00,$F0,$0F,$3F,$C0
  DEFB $FF,$00,$E0,$1F,$2F,$D0
  DEFB $FF,$00,$C0,$3F,$27,$D8
  DEFB $FF,$00,$80,$7F,$2F,$D0
  DEFB $FF,$00,$80,$7F,$2F,$D0
  DEFB $FF,$00,$00,$FF,$1F,$E0
  DEFB $FF,$00,$00,$FF,$3F,$C0
  DEFB $FF,$00,$00,$FF,$BF,$40
  DEFB $FF,$00,$00,$FF,$BF,$40
  DEFB $FE,$01,$02,$FD,$BF,$40
  DEFB $FC,$03,$02,$FD,$BF,$40
  DEFB $FC,$03,$02,$FD,$7F,$80
  DEFB $F8,$07,$02,$FD,$FF,$00
  DEFB $F8,$07,$09,$F6,$FF,$00
  DEFB $F0,$0F,$09,$F6,$FF,$00
  DEFB $FC,$03,$09,$F6,$FF,$00
  DEFB $FF,$00,$0B,$F4,$FF,$00
  DEFB $FF,$00,$C7,$38,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00

; Sprite 13 (odd column; SpriteTable 27): trench middle along X (map type 13 on
; odd rows), 21 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprTrenchMiddleX:
  DEFB $15,$04

; SprTrenchMiddleX: 21 rows of 4 (mask, graphic) pairs, bottom line first
SprTrenchMiddleXRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$CF,$30,$FF,$00,$FF,$00
  DEFB $FF,$00,$C3,$3C,$FF,$00,$FF,$00
  DEFB $FF,$00,$81,$7E,$FF,$00,$FF,$00
  DEFB $FF,$00,$80,$7F,$1F,$E0,$FF,$00
  DEFB $FF,$00,$00,$FF,$07,$F8,$FF,$00
  DEFB $FF,$00,$00,$FF,$01,$FE,$FF,$00
  DEFB $FE,$01,$40,$BF,$00,$FF,$FF,$00
  DEFB $FE,$01,$50,$AF,$00,$FF,$7F,$80
  DEFB $FC,$03,$51,$AE,$00,$FF,$1F,$E0
  DEFB $FF,$00,$51,$AE,$00,$FF,$1F,$E0
  DEFB $FF,$00,$91,$6E,$40,$BF,$3F,$C0
  DEFB $FF,$00,$E1,$1E,$50,$AF,$3F,$C0
  DEFB $FF,$00,$FE,$01,$52,$AD,$7F,$80
  DEFB $FF,$00,$FF,$00,$52,$AD,$FF,$00
  DEFB $FF,$00,$FF,$00,$92,$6D,$FF,$00
  DEFB $FF,$00,$FF,$00,$E2,$1D,$FF,$00
  DEFB $FF,$00,$FF,$00,$FD,$02,$FF,$00

; Sprite 14 (even column; SpriteTable 28): trench end along Y (map type 14 on
; even rows), 23 rows x 3 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprTrenchEndY:
  DEFB $17,$03

; SprTrenchEndY: 23 rows of 3 (mask, graphic) pairs, bottom line first
SprTrenchEndYRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$03,$FF,$00
  DEFB $FF,$00,$F8,$07,$3F,$C0
  DEFB $FF,$00,$F0,$0F,$1F,$E0
  DEFB $FF,$00,$F0,$0F,$2F,$D0
  DEFB $FF,$00,$C0,$3F,$AF,$50
  DEFB $FF,$00,$80,$7F,$9F,$60
  DEFB $FF,$00,$00,$FF,$9F,$60
  DEFB $FF,$00,$00,$FF,$BF,$40
  DEFB $FE,$01,$02,$FD,$7F,$80
  DEFB $FC,$03,$02,$FD,$7F,$80
  DEFB $FC,$03,$02,$FD,$7F,$80
  DEFB $F8,$07,$02,$FD,$FF,$00
  DEFB $F8,$07,$01,$FE,$FF,$00
  DEFB $F0,$0F,$09,$F6,$FF,$00
  DEFB $FC,$03,$0B,$F4,$FF,$00
  DEFB $FF,$00,$0B,$F4,$FF,$00
  DEFB $FF,$00,$CB,$34,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00

; Sprite 14 (odd column; SpriteTable 29): trench end along X (map type 14 on
; odd rows), 17 rows x 3 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprTrenchEndX:
  DEFB $11,$03

; SprTrenchEndX: 17 rows of 3 (mask, graphic) pairs, bottom line first
SprTrenchEndXRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$CF,$30,$FF,$00
  DEFB $FF,$00,$C1,$3E,$FF,$00
  DEFB $FF,$00,$80,$7F,$FF,$00
  DEFB $FF,$00,$80,$7F,$3F,$C0
  DEFB $FF,$00,$00,$FF,$07,$F8
  DEFB $FF,$00,$80,$7F,$03,$FC
  DEFB $FE,$01,$A0,$5F,$03,$FC
  DEFB $FE,$01,$A8,$57,$01,$FE
  DEFB $FC,$03,$A9,$56,$0A,$F5
  DEFB $FF,$00,$29,$D6,$2A,$D5
  DEFB $FF,$00,$C9,$36,$29,$D6
  DEFB $FF,$00,$F1,$0E,$09,$F6
  DEFB $FF,$00,$FE,$01,$73,$8C

; Sprite 15 (even column; SpriteTable 30): low block, map type 15, 32 rows x 4
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockLow:
  DEFB $20,$04

; SprBlockLow: 32 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockLowRows:
  DEFB $FF,$00,$3F,$C0,$FF,$00,$FF,$00
  DEFB $FF,$00,$0F,$B0,$FF,$00,$FF,$00
  DEFB $FE,$01,$03,$8C,$FF,$00,$FF,$00
  DEFB $FE,$01,$00,$83,$FF,$00,$FF,$00
  DEFB $FC,$02,$00,$80,$3F,$C0,$FF,$00
  DEFB $FC,$02,$00,$8C,$0F,$30,$FF,$00
  DEFB $F8,$06,$00,$8C,$03,$0C,$FF,$00
  DEFB $F8,$06,$00,$C0,$00,$C3,$FF,$00
  DEFB $F0,$0B,$00,$30,$00,$C0,$7F,$80
  DEFB $F0,$0B,$00,$0C,$00,$0C,$7F,$80
  DEFB $E0,$1A,$00,$03,$00,$0C,$7F,$80
  DEFB $E0,$1A,$00,$00,$00,$C0,$7F,$80
  DEFB $C0,$2C,$00,$00,$00,$30,$7F,$80
  DEFB $C0,$2C,$00,$00,$00,$0C,$7F,$80
  DEFB $80,$68,$00,$00,$00,$03,$7F,$80
  DEFB $80,$68,$00,$00,$00,$00,$7F,$80
  DEFB $00,$B0,$00,$00,$00,$01,$FF,$00
  DEFB $00,$B0,$00,$00,$00,$01,$FF,$00
  DEFB $00,$A0,$00,$00,$01,$02,$FF,$00
  DEFB $00,$A0,$00,$00,$01,$02,$FF,$00
  DEFB $00,$C0,$00,$00,$03,$04,$FF,$00
  DEFB $00,$C0,$00,$00,$03,$04,$FF,$00
  DEFB $00,$80,$00,$00,$07,$08,$FF,$00
  DEFB $00,$C0,$00,$00,$07,$08,$FF,$00
  DEFB $C0,$30,$00,$00,$0F,$10,$FF,$00
  DEFB $F0,$0C,$00,$00,$0F,$10,$FF,$00
  DEFB $FC,$03,$00,$00,$1F,$20,$FF,$00
  DEFB $FF,$00,$00,$C0,$1F,$20,$FF,$00
  DEFB $FF,$00,$C0,$30,$3F,$40,$FF,$00
  DEFB $FF,$00,$F0,$0C,$3F,$40,$FF,$00
  DEFB $FF,$00,$FC,$03,$7F,$80,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80,$FF,$00

; Sprite 15 (odd column; SpriteTable 31): low block, map type 15, 32 rows x 4
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockLowOdd:
  DEFB $20,$04

; SprBlockLowOdd: 32 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockLowOddRows:
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0B,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$18,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$18,$0F,$30,$FF,$00
  DEFB $FF,$00,$C0,$28,$03,$0C,$FF,$00
  DEFB $FF,$00,$C0,$28,$00,$C3,$FF,$00
  DEFB $FF,$00,$80,$68,$00,$C0,$3F,$C0
  DEFB $FF,$00,$80,$6C,$00,$0C,$0F,$30
  DEFB $FF,$00,$00,$B3,$00,$0C,$07,$08
  DEFB $FF,$00,$00,$B0,$00,$C0,$07,$C8
  DEFB $FE,$01,$00,$A0,$00,$30,$07,$C8
  DEFB $FE,$01,$00,$A0,$00,$0C,$07,$08
  DEFB $FC,$02,$00,$C0,$00,$03,$07,$08
  DEFB $FC,$02,$00,$C0,$00,$00,$07,$C8
  DEFB $F8,$06,$00,$80,$00,$00,$07,$38
  DEFB $F8,$06,$00,$80,$00,$00,$07,$08
  DEFB $F0,$0B,$00,$00,$00,$00,$0F,$10
  DEFB $F0,$0B,$00,$00,$00,$00,$0F,$10
  DEFB $F0,$0A,$00,$00,$00,$00,$1F,$20
  DEFB $F0,$0A,$00,$00,$00,$00,$1F,$20
  DEFB $F0,$0C,$00,$00,$00,$00,$3F,$40
  DEFB $F0,$0C,$00,$00,$00,$00,$3F,$40
  DEFB $F0,$08,$00,$00,$00,$00,$7F,$80
  DEFB $F0,$0C,$00,$00,$00,$00,$7F,$80
  DEFB $FC,$03,$00,$00,$00,$01,$FF,$00
  DEFB $FF,$00,$00,$C0,$00,$01,$FF,$00
  DEFB $FF,$00,$C0,$30,$01,$02,$FF,$00
  DEFB $FF,$00,$F0,$0C,$01,$02,$FF,$00
  DEFB $FF,$00,$FC,$03,$03,$04,$FF,$00
  DEFB $FF,$00,$FF,$00,$03,$C4,$FF,$00
  DEFB $FF,$00,$FF,$00,$C7,$38,$FF,$00
  DEFB $FF,$00,$FF,$00,$F7,$08,$FF,$00

; Sprite 16 (even column; SpriteTable 32): tall block with an arch, map type
; 16, 40 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockTall:
  DEFB $28,$04

; SprBlockTall: 40 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockTallRows:
  DEFB $FF,$00,$3F,$C0,$FF,$00,$FF,$00
  DEFB $FF,$00,$0F,$B0,$FF,$00,$FF,$00
  DEFB $FE,$01,$03,$8C,$FF,$00,$FF,$00
  DEFB $FE,$01,$03,$84,$FF,$00,$FF,$00
  DEFB $FC,$02,$03,$84,$FF,$00,$FF,$00
  DEFB $FC,$02,$03,$84,$EF,$10,$FF,$00
  DEFB $F8,$06,$03,$84,$E3,$1C,$FF,$00
  DEFB $F8,$06,$01,$86,$C0,$33,$FF,$00
  DEFB $F0,$0A,$00,$87,$40,$B0,$7F,$80
  DEFB $F0,$0A,$00,$87,$00,$D0,$7F,$80
  DEFB $E0,$1A,$00,$83,$00,$D0,$7F,$80
  DEFB $E0,$1A,$00,$90,$00,$D0,$7F,$80
  DEFB $C0,$2A,$00,$84,$00,$30,$7F,$80
  DEFB $C0,$2A,$00,$91,$00,$00,$7F,$80
  DEFB $80,$6A,$00,$84,$00,$40,$7F,$80
  DEFB $80,$6A,$00,$C1,$00,$10,$7F,$80
  DEFB $00,$AB,$00,$30,$00,$44,$7F,$80
  DEFB $00,$AB,$00,$0C,$00,$10,$7F,$80
  DEFB $00,$AA,$00,$03,$00,$04,$7F,$80
  DEFB $00,$AA,$00,$00,$00,$C0,$7F,$80
  DEFB $00,$AC,$00,$00,$00,$30,$7F,$80
  DEFB $00,$AC,$00,$00,$00,$0C,$7F,$80
  DEFB $00,$A8,$00,$00,$00,$03,$7F,$80
  DEFB $00,$A8,$00,$00,$00,$00,$7F,$80
  DEFB $00,$B0,$00,$00,$00,$01,$FF,$00
  DEFB $00,$B0,$00,$00,$00,$01,$FF,$00
  DEFB $00,$A0,$00,$00,$01,$02,$FF,$00
  DEFB $00,$A0,$00,$00,$01,$02,$FF,$00
  DEFB $00,$C0,$00,$00,$03,$04,$FF,$00
  DEFB $00,$C0,$00,$00,$03,$04,$FF,$00
  DEFB $00,$80,$00,$00,$07,$08,$FF,$00
  DEFB $00,$C0,$00,$00,$07,$08,$FF,$00
  DEFB $C0,$30,$00,$00,$0F,$10,$FF,$00
  DEFB $F0,$0C,$00,$00,$0F,$10,$FF,$00
  DEFB $FC,$03,$00,$00,$1F,$20,$FF,$00
  DEFB $FF,$00,$00,$C0,$1F,$20,$FF,$00
  DEFB $FF,$00,$C0,$30,$3F,$40,$FF,$00
  DEFB $FF,$00,$F0,$0C,$3F,$40,$FF,$00
  DEFB $FF,$00,$FC,$03,$7F,$80,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80,$FF,$00

; Sprite 16 (odd column; SpriteTable 33): tall block with an arch, map type 16,
; 40 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockTallOdd:
  DEFB $28,$04

; SprBlockTallOdd: 40 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockTallOddRows:
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0B,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$18,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$18,$3F,$40,$FF,$00
  DEFB $FF,$00,$C0,$28,$3F,$40,$FF,$00
  DEFB $FF,$00,$C0,$28,$3E,$41,$FF,$00
  DEFB $FF,$00,$80,$68,$3E,$41,$3F,$C0
  DEFB $FF,$00,$80,$68,$1C,$63,$0F,$30
  DEFB $FF,$00,$00,$A8,$04,$7B,$07,$08
  DEFB $FF,$00,$00,$A8,$00,$7D,$07,$08
  DEFB $FE,$01,$00,$A8,$00,$3D,$07,$08
  DEFB $FE,$01,$00,$A9,$00,$0D,$07,$08
  DEFB $FC,$02,$00,$A8,$00,$43,$07,$08
  DEFB $FC,$02,$00,$A9,$00,$10,$07,$08
  DEFB $F8,$06,$00,$A8,$00,$44,$07,$08
  DEFB $F8,$06,$00,$AC,$00,$11,$07,$08
  DEFB $F0,$0A,$00,$B3,$00,$04,$07,$48
  DEFB $F0,$0A,$00,$B0,$00,$C1,$07,$08
  DEFB $F0,$0A,$00,$A0,$00,$30,$07,$48
  DEFB $F0,$0A,$00,$A0,$00,$0C,$07,$08
  DEFB $F0,$0A,$00,$C0,$00,$03,$07,$08
  DEFB $F0,$0A,$00,$C0,$00,$00,$07,$C8
  DEFB $F0,$0A,$00,$80,$00,$00,$07,$38
  DEFB $F0,$0A,$00,$80,$00,$00,$07,$08
  DEFB $F0,$0B,$00,$00,$00,$00,$0F,$10
  DEFB $F0,$0B,$00,$00,$00,$00,$0F,$10
  DEFB $F0,$0A,$00,$00,$00,$00,$1F,$20
  DEFB $F0,$0A,$00,$00,$00,$00,$1F,$20
  DEFB $F0,$0C,$00,$00,$00,$00,$3F,$40
  DEFB $F0,$0C,$00,$00,$00,$00,$3F,$40
  DEFB $F0,$08,$00,$00,$00,$00,$7F,$80
  DEFB $F0,$0C,$00,$00,$00,$00,$7F,$80
  DEFB $FC,$03,$00,$00,$00,$01,$FF,$00
  DEFB $FF,$00,$00,$C0,$00,$01,$FF,$00
  DEFB $FF,$00,$C0,$30,$01,$02,$FF,$00
  DEFB $FF,$00,$F0,$0C,$01,$02,$FF,$00
  DEFB $FF,$00,$FC,$03,$03,$04,$FF,$00
  DEFB $FF,$00,$FF,$00,$03,$C4,$FF,$00
  DEFB $FF,$00,$FF,$00,$C7,$38,$FF,$00
  DEFB $FF,$00,$FF,$00,$F7,$08,$FF,$00

; Sprite 6 (even column; SpriteTable 12): boulders, map type 6, 25 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprBouldersA:
  DEFB $19,$03

; SprBouldersA: 25 rows of 3 (mask, graphic) pairs, bottom line first
SprBouldersARows:
  DEFB $FF,$00,$3F,$C0,$FF,$00
  DEFB $FF,$00,$0F,$B0,$FF,$00
  DEFB $FE,$01,$0B,$D4,$FF,$00
  DEFB $FE,$01,$08,$77,$FF,$00
  DEFB $FF,$00,$18,$A4,$7F,$80
  DEFB $FF,$00,$BC,$43,$CF,$30
  DEFB $F8,$07,$CF,$30,$C3,$2C
  DEFB $F8,$05,$82,$4D,$81,$56
  DEFB $F1,$0A,$83,$74,$81,$7A
  DEFB $F1,$0A,$03,$9C,$C9,$36
  DEFB $E1,$16,$0E,$D1,$7F,$80
  DEFB $E3,$1C,$DF,$20,$23,$DC
  DEFB $FF,$00,$FB,$04,$E1,$16
  DEFB $C7,$38,$39,$C6,$C1,$2A
  DEFB $87,$48,$90,$6F,$E1,$16
  DEFB $8C,$73,$F0,$09,$E7,$18
  DEFB $88,$56,$61,$96,$BF,$40
  DEFB $C8,$35,$21,$5A,$FF,$00
  DEFB $F8,$06,$73,$8C,$17,$E8
  DEFB $FC,$03,$7E,$81,$0F,$30
  DEFB $FF,$00,$FF,$00,$0F,$D0
  DEFB $FF,$00,$C9,$36,$9F,$60
  DEFB $FF,$00,$C0,$2D,$DF,$20
  DEFB $FF,$00,$E1,$12,$FF,$00
  DEFB $FF,$00,$F3,$0C,$FF,$00

; Sprite 6 (odd column; SpriteTable 13): boulders, map type 6, 24 rows x 4
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprBouldersAOdd:
  DEFB $18,$04

; SprBouldersAOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first
SprBouldersAOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$F8,$07,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0A,$3F,$C0,$FF,$00
  DEFB $FF,$00,$F8,$05,$33,$4C,$FF,$00
  DEFB $FF,$00,$F8,$06,$61,$92,$FF,$00
  DEFB $FF,$00,$DC,$23,$F1,$0A,$FF,$00
  DEFB $FF,$00,$FF,$00,$DB,$24,$9F,$60
  DEFB $FF,$00,$F3,$0C,$FF,$00,$07,$D8
  DEFB $FF,$00,$39,$C6,$8F,$70,$07,$A8
  DEFB $FE,$01,$1F,$20,$87,$58,$8F,$50
  DEFB $FF,$00,$33,$CC,$84,$4B,$DF,$20
  DEFB $FF,$00,$F0,$0B,$CC,$32,$7F,$80
  DEFB $FC,$03,$60,$9D,$FE,$01,$7F,$80
  DEFB $F8,$04,$60,$97,$FF,$00,$FF,$00
  DEFB $F8,$07,$E1,$1A,$E3,$1C,$FF,$00
  DEFB $F8,$05,$F9,$06,$C1,$2A,$FF,$00
  DEFB $FD,$02,$EF,$10,$C3,$24,$FF,$00
  DEFB $FF,$00,$3F,$C0,$87,$58,$FF,$00
  DEFB $FF,$00,$D8,$27,$9F,$60,$FF,$00
  DEFB $FF,$00,$FD,$02,$F9,$06,$FF,$00
  DEFB $FF,$00,$FF,$00,$FD,$02,$FF,$00
  DEFB $FF,$00,$FF,$00,$A7,$58,$FF,$00
  DEFB $FF,$00,$FF,$00,$CF,$30,$FF,$00

; Sprite 7 (even column; SpriteTable 14): boulders, map type 7, 25 rows x 3
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprBouldersB:
  DEFB $19,$03

; SprBouldersB: 25 rows of 3 (mask, graphic) pairs, bottom line first
SprBouldersBRows:
  DEFB $FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$6F,$90,$FF,$00
  DEFB $FF,$00,$F7,$08,$FF,$00
  DEFB $FE,$01,$5F,$A0,$FF,$00
  DEFB $FC,$02,$47,$B8,$3F,$C0
  DEFB $FC,$03,$C2,$2D,$3F,$40
  DEFB $FF,$00,$82,$55,$6F,$90
  DEFB $FD,$02,$C7,$28,$FC,$03
  DEFB $FC,$03,$66,$99,$3E,$C1
  DEFB $F8,$04,$3F,$40,$73,$8C
  DEFB $F8,$05,$3F,$40,$E0,$1B
  DEFB $F9,$06,$31,$CE,$E0,$15
  DEFB $CF,$30,$E0,$15,$F1,$0A
  DEFB $EC,$13,$F0,$0B,$9B,$64
  DEFB $FC,$02,$39,$C6,$8F,$50
  DEFB $98,$67,$3F,$40,$0F,$90
  DEFB $88,$54,$3F,$C0,$1F,$A0
  DEFB $9C,$62,$71,$8E,$BF,$40
  DEFB $FE,$01,$F0,$0B,$FF,$00
  DEFB $FF,$00,$99,$66,$CF,$30
  DEFB $FF,$00,$0F,$D0,$DF,$20
  DEFB $FF,$00,$8E,$51,$7F,$80
  DEFB $FF,$00,$DC,$22,$3F,$40
  DEFB $FF,$00,$FC,$03,$3F,$40
  DEFB $FF,$00,$FF,$00,$7F,$80

; Sprite 7 (odd column; SpriteTable 15): boulders, map type 7, 24 rows x 4
; bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprBouldersBOdd:
  DEFB $18,$04

; SprBouldersBOdd: 24 rows of 4 (mask, graphic) pairs, bottom line first
SprBouldersBOddRows:
  DEFB $FF,$00,$FF,$00,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$03,$FF,$00,$FF,$00
  DEFB $FF,$00,$FC,$02,$3F,$C0,$FF,$00
  DEFB $FF,$00,$F8,$04,$7F,$80,$FF,$00
  DEFB $FF,$00,$F8,$07,$E3,$1C,$FF,$00
  DEFB $FF,$00,$FB,$04,$C1,$2A,$FF,$00
  DEFB $FF,$00,$8E,$71,$C1,$2A,$FF,$00
  DEFB $FF,$00,$87,$58,$E3,$14,$FF,$00
  DEFB $FF,$00,$DF,$20,$37,$C8,$8F,$70
  DEFB $FF,$00,$FF,$00,$0E,$B1,$0F,$90
  DEFB $FE,$01,$79,$86,$87,$48,$9F,$60
  DEFB $FE,$01,$30,$49,$CF,$30,$FF,$00
  DEFB $FC,$02,$11,$AE,$FC,$03,$7F,$80
  DEFB $FE,$01,$3B,$44,$0C,$F2,$7F,$80
  DEFB $FE,$01,$7F,$80,$0E,$91,$FF,$00
  DEFB $FB,$04,$E3,$1C,$9F,$60,$FF,$00
  DEFB $FF,$00,$C1,$22,$B3,$4C,$FF,$00
  DEFB $FF,$00,$61,$9A,$FD,$02,$FF,$00
  DEFB $FF,$00,$FB,$04,$EF,$10,$FF,$00
  DEFB $FF,$00,$FF,$00,$C3,$2C,$FF,$00
  DEFB $FF,$00,$FE,$01,$41,$B6,$FF,$00
  DEFB $FF,$00,$FF,$00,$41,$AA,$FF,$00
  DEFB $FF,$00,$FF,$00,$C3,$34,$FF,$00
  DEFB $FF,$00,$FF,$00,$E7,$18,$FF,$00

; Sprite 21 (both columns; SpriteTable 42, 43): border post, map type 21, 36
; rows x 2 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprPost:
  DEFB $24,$02

; SprPost: 36 rows of 2 (mask, graphic) pairs, bottom line first
SprPostRows:
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$FF,$00
  DEFB $FF,$00,$3F,$C0
  DEFB $FF,$00,$0F,$F0
  DEFB $FE,$01,$03,$AC
  DEFB $FE,$01,$00,$D7
  DEFB $FC,$02,$00,$AB
  DEFB $FC,$03,$00,$D5
  DEFB $F8,$06,$00,$AB
  DEFB $F8,$05,$00,$D5
  DEFB $F8,$06,$00,$AB
  DEFB $F8,$05,$00,$D5
  DEFB $F8,$07,$00,$3B
  DEFB $F8,$05,$00,$0D
  DEFB $F8,$06,$00,$63
  DEFB $F8,$06,$01,$5A
  DEFB $F8,$04,$01,$EA
  DEFB $F8,$06,$03,$DC
  DEFB $FE,$01,$03,$EC
  DEFB $FF,$00,$07,$D8
  DEFB $FF,$00,$07,$E8
  DEFB $FF,$00,$07,$D8
  DEFB $FF,$00,$07,$E8
  DEFB $FF,$00,$07,$F8
  DEFB $FF,$00,$07,$B8
  DEFB $FF,$00,$0F,$F0
  DEFB $FF,$00,$CF,$30
  DEFB $FF,$00,$DF,$20
  DEFB $FF,$00,$DF,$20
  DEFB $FF,$00,$DF,$20
  DEFB $FF,$00,$DF,$20
  DEFB $FF,$00,$DF,$20
  DEFB $FF,$00,$DF,$20
  DEFB $FF,$00,$DF,$20

; Sprite 17 (even column; SpriteTable 34): low block with a door, map type 17
; on even rows, 32 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockDoor:
  DEFB $20,$04

; SprBlockDoor: 32 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockDoorRows:
  DEFB $FF,$00,$3F,$C0,$FF,$00,$FF,$00
  DEFB $FF,$00,$0F,$B0,$FF,$00,$FF,$00
  DEFB $FE,$01,$03,$8C,$FF,$00,$FF,$00
  DEFB $FE,$01,$00,$A3,$FF,$00,$FF,$00
  DEFB $FC,$03,$00,$A8,$3F,$C0,$FF,$00
  DEFB $FC,$03,$00,$AA,$0F,$30,$FF,$00
  DEFB $F8,$07,$00,$8A,$03,$8C,$FF,$00
  DEFB $F8,$07,$00,$C2,$00,$A3,$FF,$00
  DEFB $F0,$0F,$00,$30,$00,$A8,$7F,$80
  DEFB $F0,$0F,$00,$0C,$00,$2A,$7F,$80
  DEFB $E0,$1E,$00,$03,$00,$0A,$7F,$80
  DEFB $E0,$1E,$00,$00,$00,$C2,$7F,$80
  DEFB $C0,$3C,$00,$00,$00,$30,$7F,$80
  DEFB $C0,$3C,$00,$00,$00,$0C,$7F,$80
  DEFB $80,$78,$00,$00,$00,$03,$7F,$80
  DEFB $80,$78,$00,$10,$00,$00,$7F,$80
  DEFB $00,$F0,$00,$10,$00,$01,$FF,$00
  DEFB $00,$F0,$00,$21,$00,$01,$FF,$00
  DEFB $00,$E0,$00,$21,$01,$02,$FF,$00
  DEFB $00,$E0,$00,$42,$01,$02,$FF,$00
  DEFB $00,$C0,$00,$42,$03,$04,$FF,$00
  DEFB $00,$C0,$00,$04,$03,$04,$FF,$00
  DEFB $00,$80,$00,$04,$07,$08,$FF,$00
  DEFB $00,$C0,$00,$00,$07,$08,$FF,$00
  DEFB $C0,$30,$00,$00,$0F,$10,$FF,$00
  DEFB $F0,$0C,$00,$00,$0F,$10,$FF,$00
  DEFB $FC,$03,$00,$00,$1F,$20,$FF,$00
  DEFB $FF,$00,$00,$C0,$1F,$20,$FF,$00
  DEFB $FF,$00,$C0,$30,$3F,$40,$FF,$00
  DEFB $FF,$00,$F0,$0C,$3F,$40,$FF,$00
  DEFB $FF,$00,$FC,$03,$7F,$80,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80,$FF,$00

; Sprite 17 (odd column; SpriteTable 35): low block with a window, map type 17
; on odd rows, 32 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height.
SprBlockWindow:
  DEFB $20,$04

; SprBlockWindow: 32 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockWindowRows:
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0B,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$18,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$1A,$0F,$30,$FF,$00
  DEFB $FF,$00,$C0,$28,$03,$8C,$FF,$00
  DEFB $FF,$00,$C0,$2A,$00,$23,$FF,$00
  DEFB $FF,$00,$80,$68,$00,$88,$3F,$C0
  DEFB $FF,$00,$80,$6C,$00,$22,$0F,$30
  DEFB $FF,$00,$00,$B3,$00,$08,$07,$88
  DEFB $FF,$00,$00,$B0,$00,$C2,$07,$28
  DEFB $FE,$01,$00,$A0,$00,$30,$07,$88
  DEFB $FE,$01,$00,$A0,$00,$0C,$07,$28
  DEFB $FC,$02,$00,$C0,$00,$03,$07,$08
  DEFB $FC,$02,$00,$C3,$00,$00,$07,$C8
  DEFB $F8,$06,$03,$84,$00,$C0,$07,$38
  DEFB $F8,$06,$03,$84,$C0,$30,$07,$08
  DEFB $F0,$0B,$01,$0A,$E0,$1C,$0F,$10
  DEFB $F0,$0B,$00,$0D,$60,$9E,$0F,$10
  DEFB $F0,$0A,$00,$1A,$00,$FC,$1F,$20
  DEFB $F0,$0A,$00,$15,$00,$7C,$1F,$20
  DEFB $F0,$0C,$00,$2A,$00,$B8,$3F,$40
  DEFB $F0,$0C,$00,$35,$00,$78,$3F,$40
  DEFB $F0,$08,$00,$0E,$00,$B0,$7F,$80
  DEFB $F0,$0C,$00,$03,$00,$70,$7F,$80
  DEFB $FC,$03,$00,$00,$00,$E1,$FF,$00
  DEFB $FF,$00,$00,$C0,$00,$21,$FF,$00
  DEFB $FF,$00,$C0,$30,$01,$02,$FF,$00
  DEFB $FF,$00,$F0,$0C,$01,$02,$FF,$00
  DEFB $FF,$00,$FC,$03,$03,$04,$FF,$00
  DEFB $FF,$00,$FF,$00,$03,$C4,$FF,$00
  DEFB $FF,$00,$FF,$00,$C7,$38,$FF,$00
  DEFB $FF,$00,$FF,$00,$F7,$08,$FF,$00

; Sprite 18 (even column; SpriteTable 36): tall block with a grid face and a
; door, map type 18 on even rows, 40 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprBlockGrid:
  DEFB $28,$04

; SprBlockGrid: 40 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockGridRows:
  DEFB $FF,$00,$3F,$C0,$FF,$00,$FF,$00
  DEFB $FF,$00,$0F,$B0,$FF,$00,$FF,$00
  DEFB $FE,$01,$03,$8C,$FF,$00,$FF,$00
  DEFB $FE,$01,$00,$A3,$FF,$00,$FF,$00
  DEFB $FC,$02,$00,$A8,$3F,$C0,$FF,$00
  DEFB $FC,$02,$00,$AA,$0F,$30,$FF,$00
  DEFB $F8,$04,$00,$AA,$03,$8C,$FF,$00
  DEFB $F8,$04,$00,$AE,$00,$A3,$FF,$00
  DEFB $F0,$08,$00,$A9,$00,$A8,$7F,$80
  DEFB $F0,$0A,$00,$A8,$00,$6A,$7F,$80
  DEFB $E0,$12,$00,$A8,$00,$1A,$7F,$80
  DEFB $E0,$12,$00,$A8,$00,$0A,$7F,$80
  DEFB $C0,$22,$00,$AC,$00,$1A,$7F,$80
  DEFB $C0,$2A,$00,$AB,$00,$3A,$7F,$80
  DEFB $80,$4A,$00,$8A,$00,$FA,$7F,$80
  DEFB $80,$48,$00,$C2,$00,$BA,$7F,$80
  DEFB $00,$89,$00,$30,$00,$AA,$7F,$80
  DEFB $00,$A9,$00,$0C,$00,$2A,$7F,$80
  DEFB $00,$AA,$00,$43,$00,$0A,$7F,$80
  DEFB $00,$A2,$00,$10,$00,$C2,$7F,$80
  DEFB $00,$A4,$00,$84,$00,$30,$7F,$80
  DEFB $00,$A4,$00,$21,$00,$0C,$7F,$80
  DEFB $00,$A9,$00,$08,$00,$43,$7F,$80
  DEFB $00,$88,$00,$42,$00,$10,$7F,$80
  DEFB $00,$92,$00,$10,$00,$85,$FF,$00
  DEFB $00,$90,$00,$84,$00,$21,$FF,$00
  DEFB $00,$A4,$00,$21,$01,$0A,$FF,$00
  DEFB $00,$A1,$00,$08,$01,$42,$FF,$00
  DEFB $00,$C8,$00,$42,$03,$14,$FF,$00
  DEFB $00,$C2,$00,$10,$03,$84,$FF,$00
  DEFB $00,$90,$00,$84,$07,$28,$FF,$00
  DEFB $00,$C4,$00,$21,$07,$08,$FF,$00
  DEFB $C0,$31,$00,$08,$0F,$50,$FF,$00
  DEFB $F0,$0C,$00,$42,$0F,$10,$FF,$00
  DEFB $FC,$03,$00,$10,$1F,$A0,$FF,$00
  DEFB $FF,$00,$00,$C4,$1F,$20,$FF,$00
  DEFB $FF,$00,$C0,$31,$3F,$40,$FF,$00
  DEFB $FF,$00,$F0,$0C,$3F,$40,$FF,$00
  DEFB $FF,$00,$FC,$03,$7F,$80,$FF,$00
  DEFB $FF,$00,$FF,$00,$7F,$80,$FF,$00

; Sprite 18 (odd column; SpriteTable 37): tall block with a dotted face, map
; type 18 on odd rows, 40 rows x 4 bytes
;
; Drawn by DrawCell for a map cell whose bit 5 is clear: sprite id = cell AND
; $1F; TerrainHeights gives its height. No recording drew it.
SprBlockDotted:
  DEFB $28,$04

; SprBlockDotted: 40 rows of 4 (mask, graphic) pairs, bottom line first
SprBlockDottedRows:
  DEFB $FF,$00,$F3,$0C,$FF,$00,$FF,$00
  DEFB $FF,$00,$F0,$0B,$FF,$00,$FF,$00
  DEFB $FF,$00,$E0,$18,$3F,$C0,$FF,$00
  DEFB $FF,$00,$E0,$18,$0F,$30,$FF,$00
  DEFB $FF,$00,$C0,$2A,$03,$0C,$FF,$00
  DEFB $FF,$00,$C0,$28,$00,$83,$FF,$00
  DEFB $FF,$00,$80,$4A,$00,$08,$3F,$C0
  DEFB $FF,$00,$80,$58,$00,$A8,$0F,$30
  DEFB $FF,$00,$00,$D8,$00,$28,$07,$08
  DEFB $FF,$00,$00,$C8,$00,$22,$07,$88
  DEFB $FE,$01,$00,$CA,$00,$0A,$07,$28
  DEFB $FE,$01,$00,$C8,$00,$AA,$07,$88
  DEFB $FC,$03,$00,$CA,$00,$28,$07,$28
  DEFB $FC,$03,$00,$88,$00,$A2,$07,$08
  DEFB $F8,$05,$00,$A8,$00,$0A,$07,$08
  DEFB $F8,$05,$00,$0C,$00,$0A,$07,$88
  DEFB $F0,$09,$00,$53,$00,$08,$07,$28
  DEFB $F0,$08,$00,$10,$00,$C0,$07,$88
  DEFB $F0,$08,$00,$A4,$00,$30,$07,$28
  DEFB $F0,$0C,$00,$20,$00,$0C,$07,$08
  DEFB $F0,$0D,$00,$40,$00,$43,$07,$08
  DEFB $F0,$08,$00,$42,$00,$00,$07,$C8
  DEFB $F0,$0A,$00,$90,$00,$04,$07,$38
  DEFB $F0,$08,$00,$80,$00,$00,$07,$08
  DEFB $F0,$09,$00,$01,$00,$00,$0F,$50
  DEFB $F0,$09,$00,$00,$00,$02,$0F,$10
  DEFB $F0,$0A,$00,$42,$00,$10,$1F,$20
  DEFB $F0,$0A,$00,$00,$00,$00,$1F,$20
  DEFB $F0,$0C,$00,$04,$00,$21,$3F,$40
  DEFB $F0,$0C,$00,$20,$00,$00,$3F,$40
  DEFB $F0,$09,$00,$00,$00,$40,$7F,$80
  DEFB $F0,$0C,$00,$00,$00,$00,$7F,$80
  DEFB $FC,$03,$00,$10,$00,$05,$FF,$00
  DEFB $FF,$00,$00,$C0,$00,$21,$FF,$00
  DEFB $FF,$00,$C0,$31,$01,$02,$FF,$00
  DEFB $FF,$00,$F0,$0C,$01,$02,$FF,$00
  DEFB $FF,$00,$FC,$03,$03,$14,$FF,$00
  DEFB $FF,$00,$FF,$00,$03,$C4,$FF,$00
  DEFB $FF,$00,$FF,$00,$C7,$38,$FF,$00
  DEFB $FF,$00,$FF,$00,$F7,$08,$FF,$00

; Free space after the sprites (150 zero bytes)
;
; Zero, up to Start at $A600; nothing in the recordings reads or writes it.
SpriteSpare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
  INCLUDE "main.asm"

  SAVEBIN "game.bin",$5B00,$A1E9
