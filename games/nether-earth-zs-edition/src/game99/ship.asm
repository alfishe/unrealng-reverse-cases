; --------------------------------------------------------------------------------------------------------------------
; ship.asm: the player's ship: its move, altitude, view follow, radar window and map mark
;
; The ship is the player's only body: a flying cursor that moves one cell a game turn over the 512 x 16 map, climbs on
; fire and sinks onto robots and warbase pads, where the robot menu and the construction menu open.
;
; MoveShip runs once a game turn from PlayLoop (and from UpdateRobot while a robot is under direct control). In
; calling order: LiftShipFromMap takes the ship's mark off the map; the X move (MoveShipX), the view follow
; (FollowView), the Y move (MoveShipY) and the altitude (AutoClimb, ClimbByFire, Sink) follow, each step tested by
; CheckShipMove; then ScrollRadar moves the radar window, RadarBlink counts and PutShipOnMap puts the mark back,
; falling into RefreshRadar and BlinkShipDot. MenuRadarTick is the blink step the robot menus call each pass.
;
; CheckShipMove gives the highest top under the ship's 2 x 2 footprint: CellTop (the terrain through TerrainTop, then
; ObjectTop) for the four own cells, ObjectTop alone for the five cells left of and below them, whose anchored objects
; reach into the footprint. KeepHigher is the shared max. The ship may not stand lower than that top.
;
; Data it owns: ShipX ($FD0E, kept in $0E-$1F5), ShipY ($FD0D, rows 1-15), Altitude ($FD10, 0-$30), ClimbTurns
; ($FD30), ViewX / MapView (the view's left column and its map address), RadarLeft / RadarColumn ($FD1B / $FD1C),
; RadarBlink ($FD1E), RadarDirty ($FD52), and BuildingTops (the heights of the 9 building types). The ship's map mark
; is bit 7 of its cell.
;
; Tricks: the ship has no record. Its map mark (bit 7) is lifted before the move and set on the new cell after it; the
; robots' probes read it. The ship's radar dot is XORed on odd RadarBlink ticks on both sides of the move: it blinks
; every other turn.
; --------------------------------------------------------------------------------------------------------------------

; the ship's move from Input: X by right / left, Y by down / up, each refused
; by CheckShipMove
;
; Also the auto-climb (ClimbTurns), the altitude (fire +2 up to $30, else -1
; down to what stands under the ship), the view follow (ViewX moves when the
; ship is at view column 13 or 22), the radar window (ScrollRadar) and the
; ship's mark: map bit 7 cleared on the old cell ($B01D) and set on the new one
; ($B024), the radar blip XORed. Called by PlayLoop, and by UpdateRobot ($B4A8)
; while a robot is under direct control.
MoveShip:
  CALL LiftShipFromMap    ; clear the ship's mark (map bit 7) and its radar
                          ; blip
  LD A,(Input)            ; up or down held?
  AND $0C                 ; Input bits 2-3: down, up
  JR Z,MoveShipX          ; neither: on to the X move
  LD A,(ClimbTurns)            ; the auto-climb runs out twice as fast
  OR A                    ; no forced climb left:
  JR Z,MoveShipX          ; nothing to speed up
  DEC A                   ; one climb turn less (AutoClimb takes another one)
  LD (ClimbTurns),A            ; ClimbTurns - 1
MoveShipX:
  LD A,(Input)            ; right / left, not both
  AND $03                 ; Input bits 0-1: right, left
  JR Z,MoveShipY          ; none: no X move
  CP $03                  ; both:
  JR Z,MoveShipY          ; they cancel, no X move
  LD HL,(ShipX)           ; HL = ShipX, the column 0-511
  RRCA                    ; carry: right
  JR C,ShipCheckRight     ; right: its own bound check
  LD A,H                  ; left: not past column $0E
  OR A                    ; a column of 256 or more:
  JR NZ,ShipStepLeft      ; always free to go left
  LD A,L                  ; the low byte:
  CP $0E                  ; column 14, the left limit?
  JR Z,MoveShipY          ; there: no X move
ShipStepLeft:
  DEC HL                  ; one column left
  JR ShipCheckX           ; test the new column
ShipCheckRight:
  LD A,H                  ; right: not past column $1F5
  OR A                    ; a column below 256:
  JR Z,ShipStepRight      ; always free to go right
  LD A,L                  ; the low byte:
  CP $F5                  ; column $1F5 (501), the right limit?
  JR Z,MoveShipY          ; there: no X move
ShipStepRight:
  INC HL                  ; one column right
ShipCheckX:
  LD A,(ShipY)            ; refused where the ship would be lower than what
                          ; stands there
  CALL CheckShipMove      ; carry: a top there is higher than Altitude
  JR C,FollowView         ; refused: ShipX stays, the view still follows
  LD (ShipX),HL           ; ShipX = the new column
FollowView:
  LD HL,(ShipX)           ; the view keeps the ship between its columns 13 and
                          ; 22
  LD DE,(ViewX)           ; DE = ViewX, the view's left map column
  XOR A                   ; no borrow for the subtraction
  SBC HL,DE               ; HL = the ship's column inside the view
  LD A,L                  ; A = it (the view is narrower than 256)
  CP $0D                  ; at view column 13?
  JR NZ,ViewCheckRight    ; at 13: the view one column left
  DEC DE                  ; ViewX - 1
ViewCheckRight:
  CP $16
  JR NZ,ViewStore         ; at 22: one column right
  INC DE                  ; ViewX + 1
ViewStore:
  LD (ViewX),DE
  LD HL,Map             ; MapView = $DD00 + ViewX
  ADD HL,DE               ; HL = the map row 0 address of the view's left
                          ; column
  LD (MapView),HL           ; MapView, where DrawView starts
MoveShipY:
  LD A,(ShipY)            ; down / up, not both
  LD C,A                  ; C = the row, changed below
  LD A,(Input)            ; the controls of this turn
  RRCA                    ; bits 2-3 (down, up)...
  RRCA                    ; ... to bits 0-1
  AND $03                 ; neither:
  JR Z,AutoClimb          ; no Y move
  CP $03                  ; both:
  JR Z,AutoClimb          ; they cancel, no Y move
  RRCA                    ; down: Y + 1
  JR NC,ShipCheckUp       ; not down
  INC C                   ; down: one row lower on the map (Y + 1)
ShipCheckUp:
  RRCA                    ; up: Y - 1
  JR NC,ShipCheckY        ; not up
  DEC C                   ; up: one row higher on the map (Y - 1)
ShipCheckY:
  LD A,C                  ; Y 0 (or 16) is off the map
  AND $0F                 ; row 0 or 16 (wrapped to 0)?
  JR Z,AutoClimb          ; off the map rows 1-15: no Y move
  LD HL,(ShipX)           ; HL = ShipX for the test
  LD B,A                  ; B = the new row (kept by CheckShipMove)
  CALL CheckShipMove      ; refused where the ship would be too low
  JR C,AutoClimb          ; refused: ShipY stays
  LD A,B                  ; the new row:
  LD (ShipY),A            ; ShipY = it
AutoClimb:
  LD A,(ClimbTurns)            ; $FD30 > 0: climb whatever fire says
  OR A                    ; no forced climb:
  JR Z,ClimbByFire        ; fire decides
  DEC A                   ; one climb turn less
  LD (ClimbTurns),A            ; ClimbTurns - 1
  JR Climb                ; climb as if fire were held
ClimbByFire:
  LD A,(Input)            ; fire: climb
  AND $10                 ; Input bit 4: fire
  JR Z,Sink               ; not held: sink
Climb:
  LD A,(Altitude)            ; 2 a turn up to $30
  CP $30                  ; at $30 (48), the ceiling?
  JR NC,MoveShipDone      ; yes: no higher
  ADD A,$02               ; two units up
  LD (Altitude),A            ; Altitude + 2
  JR MoveShipDone         ; on to the radar
Sink:
  LD A,(Altitude)            ; 1 a turn, not below 0
  DEC A                   ; one unit down
  JP M,MoveShipDone       ; already at 0: stays
  LD B,A                  ; C = the height under the ship
  LD A,(ShipY)            ; A = ShipY, HL = ShipX: the ship's own place
  LD HL,(ShipX)           ; HL = ShipX
  CALL CheckShipMove      ; C = the highest top under the ship (the carry is
                          ; not used)
  LD A,B                  ; A = the lower altitude
  CP C                    ; not below what is under it
  JR C,MoveShipDone       ; it would go into what is under the ship: stays
  LD (Altitude),A            ; Altitude - 1
MoveShipDone:
  CALL ScrollRadar        ; the radar window follows the ship
  LD HL,RadarBlink             ; the radar blink
  INC (HL)                ; RadarBlink + 1: the dot's next tick
  CALL PutShipOnMap       ; the ship's mark and blip at the new place
  RET                     ; the move is done

; Move the radar window by 64 columns when the ship nears its edge
;
; The radar shows 128 map columns: from column $FD1B x 8 ($FD1C = the same as a
; column, 16 bits). With A = ShipX / 8 - $FD1B: below 2 (the ship within 16
; columns of the left edge) the window moves 8 units left, unless it is at 0;
; 14 and more moves it 8 units right, at most to $30 (columns 384-511). A move
; sets $FD52 = 1: the radar bitmap is rebuilt from the map by BuildRadar at the
; ship's next mark ($B029). Called by MoveShip every turn (3332 times).
ScrollRadar:
  LD HL,(ShipX)           ; HL = ShipX, 9 bits
  LD A,(RadarLeft)            ; C = the window's left edge, in units of 8 columns
  LD C,A                  ; C = RadarLeft
  LD A,L                  ; A = ShipX / 8
  RR H                    ; bit 8 of ShipX into the carry...
  RRA                     ; ... into bit 7: A = ShipX / 2
  SRL A                   ; ShipX / 4
  SRL A                   ; ShipX / 8, 0-63
  SUB C                   ; the ship's place in the window, 0-15
  CP $02                  ; in the window's first 2 units (16 columns)?
  JR C,RadarScrollLeft    ; yes: the window left
  CP $0E                  ; in its last 2 units?
  JR NC,RadarScrollRight  ; yes: the window right
  RET                     ; inside: the window stays
RadarScrollLeft:
  LD A,C                  ; left by 8 units
  SUB $08                 ; the window would move 8 columns left
  RET M                   ; already at the left end: stay
  JR RadarSetWindow       ; store the new edge
RadarScrollRight:
  LD A,C                  ; the ship is 14 or more units right of the window's
                          ; left edge: 8 units right
  ADD A,$08               ; 8 units (64 columns) right
  CP $38                  ; $38 would pass the map's end: stay at $30 (columns
                          ; $180-$1FF)
  RET Z                   ; at the right end: stay
RadarSetWindow:
  LD (RadarLeft),A            ; RadarLeft ($FD1B) = A (in 8-column units)
  ADD A,A                 ; RadarColumn ($FD1C) = A * 8, the first map column
                          ; the radar shows
  ADD A,A                 ; A * 4 (at most $C0)
  LD L,A                  ; HL = A * 4...
  LD H,$00                ; (the high byte 0)
  ADD HL,HL               ; ... * 2: A * 8, up to $180
  LD (RadarColumn),HL           ; RadarColumn = the window's first map column
  LD A,$01                ; the radar must be rebuilt (PutShipOnMap does it)
  LD (RadarDirty),A            ; RadarDirty = 1
  RET                     ; the window moved

; clear the ship's occupant bit in its map cell, toggle its radar dot
;
; Called by MoveShip first thing each game turn, before the ship moves: the
; cell under the ship (ShipCell: $DD00 + $200 * ShipY + ShipX) loses bit 7, the
; occupant bit robots test (FreeDirections) when the ship hangs lower than
; their top, and the ship's dot on the radar is toggled off when it is on
; (BlinkShipDot). PutShipOnMap undoes both after the move.
LiftShipFromMap:
  CALL ShipCell           ; HL = the ship's map cell
  RES 7,(HL)              ; the ship is no longer in this cell
  JR BlinkShipDot         ; and the dot goes (when the tick is odd)

; set the ship's occupant bit in its new map cell, rebuild the radar if the
; window moved, toggle the ship's dot
;
; Called at the end of MoveShip (and by BuildMap). Sets bit 7 of the ship's
; cell, then goes on into RefreshRadar.
PutShipOnMap:
  CALL ShipCell           ; HL = the ship's map cell
  SET 7,(HL)              ; the ship occupies it

; rebuild the radar when RadarDirty is set, then blink the ship's dot
;
; RadarDirty ($FD52) is set when the window moved ($B017) and by other code
; that changes the map (the start, a loaded game). BuildRadar then redraws both
; radar layers $D800 / $D900 from the map (a pixel for every cell of type $0F
; or more, the high ground) and plots every live robot's dot; the flag is
; cleared. Falls into BlinkShipDot. Also reached from MenuRadarTick.
RefreshRadar:
  LD A,(RadarDirty)            ; the radar to rebuild?
  OR A                    ; RadarDirty 0:
  JR Z,BlinkShipDot       ; no: only the blink
  CALL BuildRadar         ; terrain bitmap of the 128-column window and all
                          ; robots' dots
  XOR A                   ; done until the window moves again
  LD (RadarDirty),A            ; RadarDirty = 0

; on odd ticks toggle the ship's 2x2 dot on the radar's player layer
;
; RadarBlink ($FD1E) counts the game turns (MoveShip increments it between
; LiftShipFromMap and PutShipOnMap, MenuRadarTick in the menus). When it is
; odd, ToggleRadarDot XORs a 2x2 dot at (ShipX, ShipY) into the layer B = 0
; ($D800, shown with attribute $4D by PlayInterrupt in alternate frames).
; Off-window positions draw nothing (RadarDotAddress). The pairs of toggles
; around each move leave the dot on every other turn: the ship's dot blinks.
BlinkShipDot:
  LD A,(RadarBlink)            ; the blink tick
  AND $01                 ; odd?
  RET Z                   ; even tick: no change
  LD HL,(ShipX)           ; HL = the ship's column
  LD A,(ShipY)            ; and its row:
  LD C,A                  ; C = ShipY
  LD B,$00                ; B = 0: the player's layer $D800
  JP ToggleRadarDot       ; XOR the dot, return from there

; one blink step of the ship's dot while a menu is open
;
; Called by the robot menu loop (DirectControl) and ListMenu each pass, so the
; world goes on and the ship's dot keeps blinking while the player sits in a
; menu: toggles the dot (BlinkShipDot), advances RadarBlink, rebuilds the radar
; if needed and toggles again on the new tick (RefreshRadar).
MenuRadarTick:
  CALL BlinkShipDot       ; toggle the dot on the current tick
  LD HL,RadarBlink             ; RadarBlink:
  INC (HL)                ; the next tick
  JP RefreshRadar         ; rebuild if dirty, toggle on the new tick

; carry: the ship may not stand at HL (X), A (Y)
;
; Tests a place for the ship: HL = the column X, A = the row Y. C = the highest
; top under the ship's 2 x 2 footprint (X, Y), (X+1, Y), (X, Y-1), (X+1, Y-1):
; the terrain height of each cell and the top of any robot (+$09 + +$0D) or
; building (BuildingTops) anchored there (CellTop; then ObjectTop alone on
; (X-1, Y-1), (X-1, Y) and, inside the map, the row Y+1 (X-1 to X+1), whose
; anchored objects reach into the footprint.
;
; Out: carry set when Altitude < C (the ship would be inside something there),
; C = the top, HL = X kept; B kept (ObjectTop saves BC), DE and A lost, IY may
; point at the robot or building found. Called by MoveShip for the X move
; (MoveShipX), the Y move (ShipCheckY) and, with the ship's own place, by Sink
; to get the floor under the ship.
CheckShipMove:
  PUSH HL                 ; keep X for MoveShip
  CALL MapCell            ; HL = the cell (X, Y)
  EX DE,HL                ; DE = the cell, HL free for the tests
  LD C,$00                ; C = the highest top found so far
  CALL CellTop            ; the 2x2 footprint, terrain and objects: (X, Y)
  INC DE                  ; one column right: (X+1, Y)
  CALL CellTop            ; (X+1, Y)
  DEC D                   ; one row up (a row is $200)...
  DEC D                   ; ... (X+1, Y-1)
  CALL CellTop            ; (X+1, Y-1)
  DEC DE                  ; one column left: (X, Y-1)
  CALL CellTop            ; (X, Y-1)
  DEC DE                  ; and one more: (X-1, Y-1)
  CALL ObjectTop          ; objects only, the anchors whose footprint overlaps
                          ; ours: (X-1, Y-1)
  INC D                   ; one row down...
  INC D                   ; ... (X-1, Y)
  CALL ObjectTop          ; (X-1, Y)
  INC D                   ; one row down...
  INC D                   ; ... (X-1, Y+1)
  LD A,D                  ; the row Y+1 only inside the map
  CP $FD                  ; past row 15 ($FD00 is past the map)?
  JR NC,ShipCompareTop    ; yes: no row below to test
  CALL ObjectTop          ; (X-1, Y+1), (X, Y+1), (X+1, Y+1)
  INC DE                  ; (X, Y+1)
  CALL ObjectTop          ; anything anchored there
  INC DE                  ; (X+1, Y+1)
  CALL ObjectTop          ; anything anchored there
ShipCompareTop:
  LD A,(Altitude)            ; carry when the ship is lower than the highest top:
                          ; C stays for MoveShip's sinking
  CP C                    ; carry: Altitude < C, the move is refused
  POP HL                  ; HL = X again
  RET                     ; C = the top, for Sink

; C = max(C, the ground height of the terrain type at DE)
;
; DE a map cell. The cell's type (bits 0-4) indexes the ground height table
; TerrainHeights $D7BC (00 00 02 02 02 02 03 03 06 06 06 06 00 00 00 07 0F 07
; 0F...: types 2-5 height 2, 6-7 (the wreck a destroyed robot leaves) 3, 8-$0B
; 6, $0F/$11 7, $10/$12 15). Keeps the higher of it and C (KeepHigher). Used by
; CheckShipMove (through CellTop) and GroundUnderFootprint; 39396 calls.
TerrainTop:
  LD A,(DE)               ; the cell byte
  AND $1F                 ; bits 0-4: the block type
  LD HL,TerrainHeights    ; TerrainHeights
  CALL AddAToHL           ; HL = its entry
  LD A,(HL)               ; A = the ground height of the type
  JR KeepHigher           ; keep the higher one

; C = max(C, the ground and the object on cell DE)
;
; TerrainTop, then falls into ObjectTop: the highest point of a cell, used for
; the 2x2 footprint in CheckShipMove.
CellTop:
  CALL TerrainTop         ; the ground first

; C = max(C, the top of a robot or a building anchored at cell DE)
;
; When the cell has bit 6 (an object anchored there): a robot (FindRobot)
; counts with its body height +$09 plus the ground under it +$0D; else a
; building (FindBuilding) with its height from BuildingTops by type. A cell
; with bit 6 that is neither (a shot) counts nothing. B and C are kept.
ObjectTop:
  LD H,D                  ; HL = the cell...
  LD L,E                  ; ... from DE (DE is kept for the caller's walk)
  BIT 6,(HL)              ; no object anchored here
  RET Z                   ; nothing: C stays
  PUSH BC                 ; keep C, the top so far (FindRobot uses BC)
  CALL FindRobot          ; a robot on this cell?
  JR NZ,ObjectTopBuilding ; not a robot: a building or a shot
  POP BC                  ; C = the top so far
  LD A,(IY+$09)           ; its top: the body height plus the ground it stands
                          ; on
  ADD A,(IY+$0D)          ; + the ground under it, +$0D

; C = max(C, A)
;
; The common tail of TerrainTop and ObjectTop.
KeepHigher:
  CP C                    ; higher than C?
  JR C,KeepHigherDone     ; no: C stays
  LD C,A                  ; yes: C = A
KeepHigherDone:
  RET
; This entry point is used by the routine at ObjectTop.
ObjectTopBuilding:
  CALL FindBuilding       ; not a robot: a building?
  POP BC                  ; C = the top so far
  RET NZ                  ; neither: a shot, nothing to count
  LD A,(IY+$02)           ; the building's type
  LD HL,BuildingTops      ; its height by type
  CALL AddAToHL           ; HL = the type's entry
  LD A,(HL)               ; A = the building's top
  JR KeepHigher           ; keep the higher one

; The heights of the building types 0-8 for the ship and the robots
;
; Read by ObjectTop with the type byte of the Buildings record: type 0 (the
; warbase pad) $0F, the factory types 1-6 $16, $15, $15, $16, $16, $16, types 7
; and 8 $19. The pad's 15 is the altitude the ship sinks to on it, where
; ConstructionMenu opens.
BuildingTops:
  DEFB $0F,$16,$15,$15,$16,$16,$16,$19,$19 ; type 0 the pad 15 (where the
                                           ; construction menu opens),
                                           ; factories 1-6 22 21 21 22 22 22,
                                           ; flags 7-8 25
