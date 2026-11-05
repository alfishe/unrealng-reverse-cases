; --------------------------------------------------------------------------------------------------------------------
; workspace.asm: The work space $FCE9-$FFFF: the variables, the IM 2 vector and table, the buildings, as the file holds them
;
; The last 791 bytes of neart001. The game uses them as work space: the variables $FD00-$FDFC, the JP of the IM 2
; vector at $FDFD (its operand Handler), the vector table $FE00-$FF00, the Buildings records $FF01-$FFA8 and the stack
; below $FFFF. Start rebuilds the table and the JP, NewGameSetup clears the variables and Buildings, so nothing the
; file holds here is read before it is written.
;
; What the file holds here is the memory of a running Nether Earth at its main menu, saved by the converter: Nether
; Earth's tape loader N1 from its 16th byte on (N1 lies at $FCDA-$FD8D and the game block's load ends over its first
; 15 bytes, MapTail), with the random seed $39,$30,$39,$30 written over $FD00-$FD03; zeros to $FDFC; JP MenuInterrupt
; at $FDFD (the handler of the main menu: the dump was taken in the menu); the 257 bytes $FD of the vector table;
; zeros and old records in Buildings; and the stack's bytes.
; --------------------------------------------------------------------------------------------------------------------

; Nether Earth's tape loader N1 from its 16th byte, as the memory dump kept it
;
; Work space no code reads before writing; the bytes are N1's ($FCE9 = N1+15:
; DEC D; DI; LD A,$0F; OUT ($FE),A; LD HL,$A600 ...). Not run here.
N1Leftover:
  DEFB $15,$F3,$3E,$0F,$D3,$FE,$21,$00,$A6,$E5,$DB,$FE,$1F,$E6,$20,$F6
  DEFB $02,$4F,$BF,$CD,$6D,$FD,$30

; The game's variables $FD00-$FDFC (their names below); in the file N1's bytes
; and zeros
;
; The variables of the game (each named at its address: RandomSeed, PrintAddr,
; ... Factories). In the file: the seed $39,$30,$39,$30 at $FD00, then N1's
; bytes to $FD8D (its edge and byte loops) and zeros. NewGameSetup clears
; $FD04-$FDFC and Start writes the seed before any read.
Variables:
  DEFB $39,$30,$39,$30    ; the shift register of Random, seeded
                          ; $39,$30,$39,$30 by Start
PrintAddr:
  DEFB $DA,$50            ; the screen address of the next printed character
MapView:
  DEFB $2B,$7C            ; the map byte at the view's left column: $DD00 +
                          ; ViewX
SavedSP:
  DEFB $FC,$FF            ; SP kept while ClearViewBuffer pushes and while the
                          ; menu music runs
ViewX:
  DEFB $F9,$CD            ; the map column at the view's left edge, follows
                          ; ShipX
Input:
  DEFB $69                ; the controls read this game turn: bit 0 right, 1
                          ; left, 2 down, 3 up, 4 fire, 5 save, 6 abort, 7
                          ; pause
ShipY:
  DEFB $FD                ; the ship's row, 1-15
ShipX:
  DEFB $30,$EC            ; the ship's column, $000E-$01F5
Altitude:
  DEFB $06                ; the ship's height: fire raises it by 2 to $30,
                          ; released it sinks by 1 to what is under it
ShipDrawPos:
  DEFB $9C,$CD            ; the ship's view position while its drawing is
                          ; deferred (column, row); 0 = not deferred
PrintAttr:
  DEFB $46                ; the attribute of printed characters
PrintAttrAddr:
  DEFB $DA,$5A            ; the attribute address of the next printed character
PrintHeight:
  DEFB $00                ; big characters: each font row printed this many
                          ; times (PrintInline code 4, high nibble)
PrintWidth:
  DEFB $00,$C6,$B8        ; big characters: the width in bytes, 0 normal
                          ; (PrintInline code 4, low nibble)
RadarPhase:
  DEFB $30                ; toggled each frame: 0 shows the player's radar
                          ; layer, 1 the enemy's
RadarLeft:
  DEFB $E0                ; the radar window's left edge in units of 8 map
                          ; columns, 0-$30
RadarColumn:
  DEFB $24,$20            ; RadarLeft x 8: the radar window's first map column
RadarBlink:
  DEFB $F1                ; bit 0: the ship's radar blip is drawn
MenuCursor:
  DEFB $06,$C9            ; the construction menu: the column (0 EXIT MENU, 1
                          ; START ROBOT, 2 the parts), the part row; the robot
                          ; menu: its last item
MenuParts:
  DEFB $CD                ; the parts chosen, bit = part row; the new robot's
                          ; +$07
Resources:
  DEFB $6D,$FD,$30,$D6,$78,$FE,$D4 ; general, electronics, nuclear, phasers,
                                   ; missiles, cannon, chassis
MenuResources:
  DEFB $30,$F4,$CD,$6D,$FD,$79,$EE ; the copy the construction menu spends;
                                   ; back to Resources on START ROBOT
ClimbTurns:
  DEFB $03                ; game turns the ship still climbs by itself: 3 at a
                          ; new game, 5 after a menu
PrintColumn:
  DEFB $08                ; the print position's column
PrintRow:
  DEFB $16                ; the print position's row
TitleColourPhase:
  DEFB $05                ; 0-15, TitleColourCycle's frame counter
TurnFrames:
  DEFB $06                ; frames counted by PlayInterrupt; a game turn waits
                          ; for 10
Clock:
  DEFB $B0,$18,$17,$08    ; minutes (by 5), hours, days (16 bits)
PanelBusy:
  DEFB $20                ; 1 while a robot menu owns the right panel
PlayerBuildings:
  DEFB $05,$DD,$75,$00,$18,$09,$CB ; the player's buildings by type: warbases,
                                   ; then factories in the Resources order
PlayerRobotCount:
  DEFB $11                ; live robots in slots 0-23
EnemyBuildings:
  DEFB $AD,$79,$1F,$4F,$13,$18,$02 ; the enemy's buildings, the same order; no
                                   ; warbase left = the game is won
EnemyRobotCount:
  DEFB $DD                ; live robots in slots 24-47
EnemyResources:
  DEFB $23,$1B,$08,$06,$B2,$2E,$01 ; the enemy's resources, the order of
                                   ; Resources
Side:
  DEFB $CD                ; the side being processed: 0 the player's, 1 the
                          ; enemy's
RadarDirty:
  DEFB $69                ; 1: rebuild the radar layers from the map at the
                          ; next ship mark
SoundFx:
  DEFB $FD                ; 1-$7F a falling tone (fire), $FC a miss, $FA a hit,
                          ; $C8 a robot destroyed; PlayInterrupt counts it on
BassReturnPos:
  DEFB $86,$C6            ; menu music: the bass track's return point
LeadReturnPos:
  DEFB $0D,$C7,$15,$06,$B0,$D2,$51,$FD,$7C,$AD,$67,$7A,$B3,$20,$D3,$7C ; menu
  DEFB $FE,$01,$C9,$CD,$6D,$FD,$D0,$3E,$16,$3D                         ; music: the
                                                                       ; lead
                                                                       ; track's
                                                                       ; return
                                                                       ; point
Warbases:
  DEFB $20,$FD,$A7,$04,$C8,$3E,$7F,$DB,$FE,$1F,$D0,$A9,$E6,$20,$28,$F3 ; 4 capture
  DEFB $79,$2F,$4F,$ED                                                 ; points of
                                                                       ; 5 bytes: X
                                                                       ; (2), Y,
                                                                       ; owner (bit
                                                                       ; 6 player,
                                                                       ; 5 enemy, 7
                                                                       ; destroyed)
                                                                       ; + type,
                                                                       ; turns a
                                                                       ; robot has
                                                                       ; stood at
                                                                       ; the door
                                                                       ; (144
                                                                       ; captures)
Factories:
  DEFB $5F,$E6,$07,$F6,$08,$D3,$FE,$37,$C9,$00,$00,$00,$00,$00,$00,$00 ; 24 capture
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; points of
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 5 bytes,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; the same
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; shape
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00

; The IM 2 vector: JP Handler, the interrupt handler of the moment
;
; With I = $FE and the table $FE00-$FF00 all $FD, every interrupt jumps here.
; Its operand (Handler, $FDFE) is what Start (StartInterrupt), EnterPlay
; (PlayInterrupt), MenuMusic (MenuInterrupt) and the menus write to switch the
; frame's work. The file holds JP MenuInterrupt ($C3 $FD $C4): the dump's last
; handler; Start writes the JP and StartInterrupt before IM 2.
ImJump:
  JP MenuInterrupt

; The IM 2 vector table: 257 bytes of $FD
;
; Built by Start ($FE00-$FF00 = $FD, I = $FE) so the vector read from any data
; bus byte is $FDFD. The file already holds the same bytes.
ImTable:
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD

; 56 building records of 3 bytes: the map cell address, the type
;
; Type 0 a warbase pad, 1-6 factories, 7 the player's flag, 8 the enemy's
; (BuildMap writes them, SaveGameBlocks stages them at $D958). In the file:
; zeros and leftovers of the dumped game; NewGameSetup clears the records.
Buildings:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$F3
  DEFB $0D,$CE,$0B
  DEFB $E3,$50,$CE
  DEFB $0B,$E4,$50
  DEFB $1D,$17,$DC
  DEFB $0A,$CE,$0B
  DEFB $E7,$50,$1A
  DEFB $17,$DC,$0A
  DEFB $D7,$18,$38
  DEFB $00,$38,$00
  DEFB $0D,$19,$DB
  DEFB $02,$4D,$00
  DEFB $0D,$47,$F3
  DEFB $00,$0C,$47
  DEFB $9E,$18,$5C
  DEFB $0E,$00,$47
  DEFB $C0,$57,$71
  DEFB $0E,$F3,$0D
  DEFB $21,$17,$C6
  DEFB $1E,$FF,$FF
  DEFB $76,$1B,$03
  DEFB $13,$00,$3E
  DEFB $00,$3C,$42
  DEFB $42,$7E,$42
  DEFB $42,$00,$00
  DEFB $7C,$42,$7C
  DEFB $42,$42,$7C
  DEFB $00,$00,$3C
  DEFB $42,$40,$40
  DEFB $42,$3C,$00
  DEFB $00,$78,$44
  DEFB $42,$42,$44
  DEFB $78,$00,$00
  DEFB $7E,$40,$7C
  DEFB $40,$40,$7E
  DEFB $00,$00,$7E
  DEFB $40,$7C,$40
  DEFB $40,$40,$00
  DEFB $00,$3C,$42
  DEFB $40,$4E,$42
  DEFB $3C,$00,$00
  DEFB $42,$42,$7E
  DEFB $42,$42,$42
  DEFB $00,$00,$3E
  DEFB $08,$08,$08
  DEFB $08,$3E,$00
  DEFB $00,$02,$02
  DEFB $02,$42,$42
  DEFB $3C,$00,$00

; The stack's bytes and other leftovers to $FFFF
;
; The machine stack grows down from $FFFF (Start sets SP = 0 at its second
; instruction; Nether Earth's N1 had set SP = $FFE0 before it). In the file: a
; copy of 16 letters of a font (A-P, $FF5A-$FFD9 straddles Buildings and this
; area) and the stack words of the dump. Never read before written.
StackArea:
  DEFB $44,$48,$70,$48,$44,$42,$00,$00,$40,$40,$40,$40,$40,$7E,$00,$00
  DEFB $42,$66,$5A,$42,$42,$42,$00,$00,$42,$62,$52,$4A,$46,$42,$00,$00
  DEFB $3C,$42,$42,$42,$42,$3C,$00,$00,$7C,$42,$42,$7C,$40,$40,$00,$00
  DEFB $3C,$6C,$FD,$54,$FD,$00,$A6,$B7,$2D,$4E,$5E,$49,$5E,$DA,$FC,$2B
  DEFB $2D,$65,$33,$41,$C8,$01,$0C,$C8,$C6,$C8,$C6,$35,$05,$FD,$FD,$E4
  DEFB $C4,$02,$00,$A1,$C1,$2D,$A6
