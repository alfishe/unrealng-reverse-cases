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
  AND $0C
  JR Z,MoveShipX
  LD A,(ClimbTurns)            ; the auto-climb runs out twice as fast
  OR A
  JR Z,MoveShipX
  DEC A
  LD (ClimbTurns),A
MoveShipX:
  LD A,(Input)            ; right / left, not both
  AND $03
  JR Z,MoveShipY
  CP $03
  JR Z,MoveShipY
  LD HL,(ShipX)
  RRCA                    ; carry: right
  JR C,ShipCheckRight
  LD A,H                  ; left: not past column $0E
  OR A
  JR NZ,ShipStepLeft
  LD A,L
  CP $0E
  JR Z,MoveShipY
ShipStepLeft:
  DEC HL                  ; one column left
  JR ShipCheckX
ShipCheckRight:
  LD A,H                  ; right: refused at column $1F5
  OR A
  JR Z,ShipStepRight
  LD A,L
  CP $F5
  JR Z,MoveShipY
ShipStepRight:
  INC HL                  ; one column right
ShipCheckX:
  LD A,(ShipY)            ; the new column: refused when the ship would stand
                          ; lower than what is there
  CALL CheckShipMove
  JR C,FollowView
  LD (ShipX),HL
FollowView:
  LD HL,(ShipX)           ; the view keeps the ship between its columns 13 and
                          ; 22
  LD DE,(ViewX)
  XOR A
  SBC HL,DE
  LD A,L
  CP $0D
  JR NZ,ViewCheckRight    ; at 13: the view one column left
  DEC DE
ViewCheckRight:
  CP $16                  ; the ship at view column 22: the view one column
                          ; right
  JR NZ,ViewStore         ; at 22: one column right
  INC DE
ViewStore:
  LD (ViewX),DE           ; ViewX and MapView = $DD00 + ViewX
  LD HL,Map               ; MapView = $DD00 + ViewX
  ADD HL,DE
  LD (MapView),HL
MoveShipY:
  LD A,(ShipY)            ; down / up, not both
  LD C,A
  LD A,(Input)
  RRCA
  RRCA
  AND $03
  JR Z,AutoClimb
  CP $03
  JR Z,AutoClimb
  RRCA                    ; down: Y + 1
  JR NC,ShipCheckUp
  INC C
ShipCheckUp:
  RRCA                    ; up: Y - 1
  JR NC,ShipCheckY
  DEC C
ShipCheckY:
  LD A,C                  ; the new row: 0 / 16 off the map, CheckShipMove
                          ; refuses a too low ship
  AND $0F
  JR Z,AutoClimb
  LD HL,(ShipX)
  LD B,A
  CALL CheckShipMove      ; refused where the ship would be too low
  JR C,AutoClimb
  LD A,B
  LD (ShipY),A
AutoClimb:
  LD A,(ClimbTurns)            ; $FD30 > 0: climb whatever fire says
  OR A
  JR Z,ClimbByFire
  DEC A
  LD (ClimbTurns),A
  JR Climb
ClimbByFire:
  LD A,(Input)            ; no forced climb: fire climbs, else the ship sinks
  AND $10
  JR Z,Sink
Climb:
  LD A,(Altitude)            ; 2 a turn up to $30
  CP $30
  JR NC,MoveShipDone
  ADD A,$02
  LD (Altitude),A
  JR MoveShipDone
Sink:
  LD A,(Altitude)            ; 1 a turn, not below 0
  DEC A
  JP M,MoveShipDone
  LD B,A                  ; C = the height under the ship
  LD A,(ShipY)
  LD HL,(ShipX)
  CALL CheckShipMove
  LD A,B
  CP C                    ; not below what is under it
  JR C,MoveShipDone
  LD (Altitude),A
MoveShipDone:
  CALL ScrollRadar        ; the radar window follows the ship
  LD HL,RadarBlink             ; the radar blink
  INC (HL)
  CALL PutShipOnMap       ; the ship's mark and blip at the new place
  RET

; Move the radar window by 64 columns when the ship nears its edge
;
; The radar shows 128 map columns: from column $FD1B x 8 ($FD1C = the same as a
; column, 16 bits). With A = ShipX / 8 - $FD1B: below 2 (the ship within 16
; columns of the left edge) the window moves 8 units left, unless it is at 0;
; 14 and more moves it 8 units right, at most to $30 (columns 384-511). A move
; sets $FD52 = 1: the radar bitmap is rebuilt from the map by BuildRadar at the
; ship's next mark ($B029). Called by MoveShip every turn (3332 times).
ScrollRadar:
  LD HL,(ShipX)
  LD A,(RadarLeft)            ; C = the window's left edge, in units of 8 columns
  LD C,A
  LD A,L                  ; A = ShipX / 8
  RR H
  RRA
  SRL A
  SRL A
  SUB C                   ; the ship's place in the window, 0-15
  CP $02
  JR C,RadarScrollLeft
  CP $0E
  JR NC,RadarScrollRight
  RET
RadarScrollLeft:
  LD A,C                  ; the ship within 2 units of the window's left edge:
                          ; the window 8 units left
  SUB $08                 ; the window would move 8 columns left
  RET M                   ; already at the left end: stay
  JR RadarSetWindow
RadarScrollRight:
  LD A,C                  ; the ship is 14 or more units right of the window's
                          ; left edge: 8 units right
  ADD A,$08
  CP $38                  ; $38 would pass the map's end: stay at $30 (columns
                          ; $180-$1FF)
  RET Z
RadarSetWindow:
  LD (RadarLeft),A            ; RadarLeft ($FD1B) = A (in 8-column units)
  ADD A,A                 ; RadarColumn ($FD1C) = A * 8, the first map column
                          ; the radar shows
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  LD (RadarColumn),HL
  LD A,$01                ; the radar must be rebuilt (PutShipOnMap does it)
  LD (RadarDirty),A
  RET

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
; cell, then goes on into RefreshRadar. Recording: 3333 calls, once a game
; turn.
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
  LD A,(RadarDirty)
  OR A
  JR Z,BlinkShipDot
  CALL BuildRadar         ; terrain bitmap of the 128-column window and all
                          ; robots' dots
  XOR A                   ; done until the window moves again
  LD (RadarDirty),A

; on odd ticks toggle the ship's 2x2 dot on the radar's player layer
;
; RadarBlink ($FD1E) counts the game turns (MoveShip increments it between
; LiftShipFromMap and PutShipOnMap, MenuRadarTick in the menus). When it is
; odd, ToggleRadarDot XORs a 2x2 dot at (ShipX, ShipY) into the layer B = 0
; ($D800, shown with attribute $4D by PlayInterrupt in alternate frames).
; Off-window positions draw nothing (RadarDotAddress). The pairs of toggles
; around each move leave the dot on every other turn: the ship's dot blinks.
BlinkShipDot:
  LD A,(RadarBlink)
  AND $01
  RET Z                   ; even tick: no change
  LD HL,(ShipX)
  LD A,(ShipY)
  LD C,A
  LD B,$00                ; B = 0: the player's layer $D800
  JP ToggleRadarDot       ; XOR the dot, return from there

; one blink step of the ship's dot while a menu is open
;
; Called by the robot menu loop (DirectControl) and ListMenu each pass, so the
; world goes on and the ship's dot keeps blinking while the player sits in a
; menu: toggles the dot (BlinkShipDot), advances RadarBlink, rebuilds the radar
; if needed and toggles again on the new tick (RefreshRadar). 83 calls in the
; deep recording.
MenuRadarTick:
  CALL BlinkShipDot
  LD HL,RadarBlink
  INC (HL)                ; the next tick
  JP RefreshRadar         ; rebuild if dirty, toggle on the new tick

; carry: the ship may not stand at HL (X), A (Y)
;
; Used by the routine at MoveShip.
CheckShipMove:
  PUSH HL                 ; keep X for MoveShip
  CALL MapCell            ; HL = the cell (X, Y)
  EX DE,HL
  LD C,$00                ; C = the highest top found so far
  CALL CellTop            ; the 2x2 footprint, terrain and objects: (X, Y)
  INC DE
  CALL CellTop            ; (X+1, Y)
  DEC D
  DEC D
  CALL CellTop            ; (X+1, Y-1)
  DEC DE
  CALL CellTop            ; (X, Y-1)
  DEC DE
  CALL ObjectTop          ; objects only, the anchors whose footprint overlaps
                          ; ours: (X-1, Y-1)
  INC D
  INC D
  CALL ObjectTop          ; (X-1, Y)
  INC D
  INC D
  LD A,D                  ; the row Y+1 only inside the map
  CP $FD
  JR NC,ShipCompareTop
  CALL ObjectTop          ; (X-1, Y+1), (X, Y+1), (X+1, Y+1)
  INC DE
  CALL ObjectTop
  INC DE
  CALL ObjectTop
ShipCompareTop:
  LD A,(Altitude)            ; carry: the ship's altitude below the highest top in
                          ; C
  CP C
  POP HL
  RET

; C = max(C, the ground height of the terrain type at DE)
;
; DE a map cell. The cell's type (bits 0-4) indexes the ground height table
; TerrainHeights $D7BC (00 00 02 02 02 02 03 03 06 06 06 06 00 00 00 07 0F 07
; 0F ...: types 2-5 height 2, 6-7 (the wreck a destroyed robot leaves) 3, 8-$0B
; 6, $0F/$11 7, $10/$12 15). Keeps the higher of it and C (KeepHigher). Used by
; CheckShipMove (through CellTop) and GroundUnderFootprint; 39396 calls.
TerrainTop:
  LD A,(DE)
  AND $1F
  LD HL,TerrainHeights    ; TerrainHeights
  CALL AddAToHL
  LD A,(HL)
  JR KeepHigher           ; keep the higher one

; C = max(C, the ground and the object on cell DE)
;
; TerrainTop, then falls into ObjectTop: the highest point of a cell, used for
; the 2x2 footprint in CheckShipMove.
CellTop:
  CALL TerrainTop

; C = max(C, the top of a robot or a building anchored at cell DE)
;
; When the cell has bit 6 (an object anchored there): a robot (FindRobot)
; counts with its body height +$09 plus the ground under it +$0D; else a
; building (FindBuilding) with its height from BuildingTops by type. A cell
; with bit 6 that is neither (a shot) counts nothing. B and C are kept.
ObjectTop:
  LD H,D
  LD L,E
  BIT 6,(HL)              ; no object anchored here
  RET Z
  PUSH BC
  CALL FindRobot          ; a robot on this cell?
  JR NZ,ObjectTopBuilding
  POP BC
  LD A,(IY+$09)           ; its top: the body height plus the ground it stands
                          ; on
  ADD A,(IY+$0D)

; C = max(C, A)
;
; The common tail of TerrainTop and ObjectTop.
KeepHigher:
  CP C
  JR C,KeepHigherDone
  LD C,A
KeepHigherDone:
  RET                     ; C is the bigger height
; This entry point is used by the routine at ObjectTop.
ObjectTopBuilding:
  CALL FindBuilding       ; not a robot: a building?
  POP BC
  RET NZ                  ; neither: a shot, nothing to count
  LD A,(IY+$02)           ; the building's type
  LD HL,BuildingTops
  CALL AddAToHL
  LD A,(HL)
  JR KeepHigher

; The heights of the building types 0-8 for the ship and the robots
;
; Read by ObjectTop with the type byte of the Buildings record: type 0 (the
; warbase pad) $0F, the factory types 1-6 $16, $15, $15, $16, $16, $16, types 7
; and 8 $19. The pad's 15 is the altitude the ship sinks to on it, where
; ConstructionMenu opens.
BuildingTops:
  DEFB $0F,$16,$15,$15,$16,$16,$16,$19,$19
