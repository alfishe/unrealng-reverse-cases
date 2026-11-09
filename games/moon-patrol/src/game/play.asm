; --------------------------------------------------------------------------------------------------------------------
; play.asm: The play code: interrupt modes, the buggy, its jump, shots and death, the scrolling, the controls, the hold and the tune keys
;
; The routines of the main loop's call list $96FA and their helpers: SetIm1 / SetIm2, BuggyKill (every death goes
; through it), the box test, the sprite dispatch, the four scrolling bands, the buggy (BuggyUpdate, BuggyErase, the
; jump arcs, the speed governor), the wheels flying off at a death, the shots, the six control readers, the hold, the
; tune toggle and the BREAK abort.
;
; Variables: the buggy record $B212 (y, x, box height $0D, box width $1D), the buggy state $B216 ($FF alive, 0-8 the
; death frames), the wheel step $B217, the jump index $B223 ($FF not jumping) and arc $B221, the crater-death flag
; $B220, the flags $B288 (bit 0 T held, bit 1 fire held, bit 3 a narrow road texture, bit 4 H held, bit 7 tune off),
; the control type $B259 (1-6).
; --------------------------------------------------------------------------------------------------------------------

; IM 1 with I = $3F: the ROM's frame interrupt (menus, death, hold, bonus)
;
; DI, IM 1, I = $3F, EI. Called from the menu code ($81CD, $823D, $8250,
; $8328), the death ($96DF), SectorBonus $A50E, the abort $AACD and the hold
; $AEE0. Witness: game 27, a1 28, g1 5, t1 1, p2 10, h1 5, i1 6, i2 7, h2 1
; entries (a1 frames 153-21155).
SetIm1:
  DI
  IM 1
  LD A,$3F
  LD I,A
  EI
  RET

; IM 2 with I = $3A: the vector word at $3AFF in the ROM sends interrupts to
; $FFFF, the game's handler $7F14
;
; DI, I = $3A, IM 2, EI. Called from the life start ($9132) and the end of the
; hold ($AF0E). Witness: game 20, a1 5, g1 4, p2 8, h1 4, i1 6, i2 6 entries
; (a1 frames 1424-20428).
SetIm2:
  DI
  LD A,$3A
  LD I,A
  IM 2
  EI
  RET

; Kills the buggy: the death starts (state 0), 25 points, unless already dying
;
; Does nothing unless the buggy state $B216 is $FF (alive). Else $B216 = 0 (the
; first death frame: BuggyUpdate counts it to 8, the main loop $96BB ends the
; life there) and the wheel step $B217 = 0 (WheelsFly starts), then ScoreAdd
; $92D3 with DE = 0, BC = $0025: 25 points for the death (known only from the
; code: no run checked the score at a death). Keeps HL.
;
; The immune clones (i1, i2) patch the first byte to RET. Callers, one a death
; cause each (l1sum of the CALL): the rock $99F9 in $99C3 (command $97C5; game
; 1, a1 1, g1 4, p2 4, h1 4, i1 17, i2 27, h2 1), the UFO bomb $9E28 in $9CE0
; (dropped by the UFO handler $9B6B through $9E81; i1 16, i2 17), the tank
; $9EF3 in $9EBD (command $98BE; i2 6), the tank shell $9FD3 in $9F8F
; (installed by $A022; i1 6, i2 19), the low flyer $A0C4 in $A03B (command
; $98F3; i2 4), the boulders $A1CD in $A196 (commands $9917 / $991C / $9921; i2
; 22), the green plant $A358 in $A2C6 (command $9955; i2 8), and the crater
; $AA9C in BuggyUpdate (the ground probe; game 18, a1 1, p2 4, i1 69, i2 67).
; The rock, bomb, tank, shell, flyer, boulder and plant handlers test their box
; against the buggy's with BoxOverlap $A7FE first.
;
; The crater and mine handlers ($9A92, $9AEB) and the UFO saucers ($9B6B) never
; call it: a crater kills through the ground probe; how a mine kills (the probe
; or not at all) needs a run. Witness of the deaths that counted (not immune):
; game 19 = 1 rock + 18 craters, a1 2 = 1 + 1, g1 4 rocks, p2 8 = 4 + 4, h1 4
; rocks, h2 1 rock (l1sum $A7DD entries: game frames 2029-16149).
BuggyKill:
  LD A,(DeathStep)
  INC A
  RET NZ
  LD (DeathStep),A
  LD (WreckStep),A
  PUSH HL
  LD DE,$0000
  LD BC,$0025
  CALL ScoreAdd
  POP HL
  RET

; Plots E points left to right from (H = x, L = y) through $FD99
;
; E = the count. Calls $FD99 (the print code's plot) for x, x + 1, ...; keeps
; L. Callers: $8064 (the options page), the mine $9AEB, the bomb $9CE0, the
; plant $A2C6. Witness: a1 60 entries (frames 1218-18835), t1 3, i1 33, i2 63.
PlotRun:
  PUSH HL
  CALL UnplotPixel
  POP HL
  INC H
  DEC E
  JR NZ,PlotRun
  RET

; Do two boxes overlap? HL and HL' point at y, x, height, width; NC when they
; do
;
; B, C, D, E = the box at HL, B', C', D', E' = the box at HL' (the buggy $B212
; or a shot $5B60 / $5B65 for the object handlers). Carry as soon as one box
; ends above or left of the other: y + height < y', y' + height' < y, then the
; same with x and width. NC: they overlap. Witness: game 1055, a1 117, g1 518,
; p2 460, h1 518, i1 54 624, i2 54 655, h2 63 entries (i1 frames 604-30439).
BoxOverlap:
  LD B,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD E,(HL)
  EXX
  LD B,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD E,(HL)
  EXX
  LD A,B
  ADD A,D
  EXX
  SUB B
  EXX
  RET C
  EXX
  LD A,B
  ADD A,D
  EXX
  SUB B
  RET C
  LD A,C
  ADD A,E
  EXX
  SUB C
  EXX
  RET C
  EXX
  LD A,C
  ADD A,E
  EXX
  SUB C
  RET

; Draws sprite A at H = x, L = y (XOR) through the sprite table $B2D6: drawer
; word, graphics word
;
; The table $B2D6 holds 4 bytes a sprite: the drawer (one of the sprites
; module's DrawSprite16x4 ... DrawSprite40x23) and its graphics. Sprite 0 is
; the buggy ($E140, DrawSprite40x23), $1F-$26 its death frames, $3C-$3E the
; three wheels, $3B the forward shot's DrawShotForward. The drawer gets HL =
; the position, DE = the graphics and returns through DrawSpriteDone, which
; restores BC and DE; HL is the drawer's. Drawn twice (XOR) to erase. Witness:
; game 7358, a1 1375, g1 2268, t1 16, p2 3220, h1 2268, i1 35 224, i2 42 588,
; h2 322 entries (i1 frames 262-30439).
DrawSprite:
  PUSH BC
  PUSH DE
  PUSH HL
  LD DE,SpriteTable
  LD H,$00
  LD L,A
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  PUSH DE
  POP IX
  LD E,(HL)
  INC HL
  LD D,(HL)
  POP HL
  LD BC,DrawSpriteDone
  PUSH BC
  JP (IX)

; DrawSpriteDone
DrawSpriteDone:
  POP DE                  ; the drawers return here: BC and DE back
  POP BC
  RET

; The far band (lines 64-95): one pixel left a pass, 8 new columns from the
; mountains every 8 passes
;
; Only while the buggy is alive ($B216 = $FF). The counter $B224 runs 8 passes;
; at 0 the next 32 bytes of the mountains graphic ($B226 + $20, from $EBC0 up
; to $F000 and round) go to FeedMountains $5B00. Each pass every line of 64-95
; (the line table at $FC80) rolls left one pixel through its 32 bytes, the new
; bit from the line's FeedMountains byte. Witness: game 1576, a1 292, g1 493,
; p2 664, h1 493, i1 3601, i2 3935, h2 40 entries: once a main-loop pass.
ScrollMountains:
  LD A,(DeathStep)
  INC A
  RET NZ
  LD A,(HillsCountdown)
  AND A
  JR NZ,MountainsRoll
  LD HL,(HillsColumn)
  LD DE,$0020
  ADD HL,DE
  LD DE,HillsStrip+$0440
  PUSH HL
  AND A
  SBC HL,DE
  POP HL
  JR NZ,MountainsFeedSet
  LD HL,HillsStrip
MountainsFeedSet:
  LD (HillsColumn),HL     ; the next strip into FeedMountains, 8 passes
  LD DE,FeedMountains
  LD BC,$0020
  LDIR
  LD A,$08
MountainsRoll:
  DEC A                   ; the 32 lines from the line table at $FC80 (line 64)
  LD (HillsCountdown),A
  LD IX,FeedMountains
  LD C,$20
  LD HL,ScreenLineTable+$0080
MountainsLine:
  LD E,(HL)               ; HL = the line's last byte, one bit from the feed
                          ; byte
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,L
  ADD A,$1F
  LD L,A
  RLC (IX+$00)
  LD B,$20
MountainsByte:
  RL (HL)
  DEC HL
  DJNZ MountainsByte
  EX DE,HL
  INC IX
  DEC C
  JR NZ,MountainsLine
  RET

; The middle band (lines 96-127): two pixels left a pass, 8 new columns from
; the hills every 4 passes
;
; As ScrollMountains with the counter $B228 (4 passes), the source $B22A going
; from $B22C to $B22E and round (set at the life start by $95B0 from the
; scenery flag $B27D), the feed FeedHills $5B20 and the lines 96-127 ($FCC0).
; Witness: the same counts as ScrollMountains (i1 3600).
ScrollHills:
  LD A,(DeathStep)
  INC A
  RET NZ
  LD A,(MiddleCountdown)
  AND A
  JR NZ,HillsRoll
  LD HL,(MiddleColumn)
  LD DE,$0020
  ADD HL,DE
  LD DE,(MiddleEnd)
  PUSH HL
  AND A
  SBC HL,DE
  POP HL
  JR NZ,HillsFeedSet
  LD HL,(MiddleStart)
HillsFeedSet:
  LD (MiddleColumn),HL    ; the next strip into FeedHills, 4 passes
  LD DE,FeedHills
  LD BC,$0020
  LDIR
  LD A,$04
HillsRoll:
  DEC A                   ; the 32 lines from the line table at $FCC0 (line 96)
  LD (MiddleCountdown),A
  LD IX,FeedHills
  LD C,$20
  LD HL,ScreenLineTable+$00C0
HillsLine:
  LD E,(HL)               ; two bits from the feed byte
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,L
  ADD A,$1F
  LD L,A
  XOR A
  RLC (IX+$00)
  RLA
  RLC (IX+$00)
  RLA
  LD B,$20
HillsByte:
  RRCA
  RRCA
  RLA
  RL (HL)
  RLA
  RL (HL)
  RLA
  DEC HL
  DJNZ HillsByte
  EX DE,HL
  INC IX
  DEC C
  JR NZ,HillsLine
  RET

; The band of lines 128-159: two pixels left while the buggy is in the air,
; else the same time in a delay
;
; Only while alive. BuggyAirborne $AFA5 (buggy y < $89): the 32 lines from
; $FD00 (line 128) roll two pixels left with zero bits coming in; on the ground
; the delay $A929 ($0AF5 loops) instead, so the pass takes about as long.
; ScrollAdjustX moves what is drawn in this band by 2 to match (it holds the
; buggy: drawn at y - 9 = $89). Witness: same counts as ScrollMountains; the
; delay ran game 1114, i1 1524 of 3600 passes.
ScrollNearBand:
  LD A,(DeathStep)
  INC A
  RET NZ
  CALL BuggyAirborne
  JR NC,NearBandDelay
  LD C,$20
  LD HL,ScreenLineTable+$0100
NearBandLine:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,L
  ADD A,$1F
  LD L,A
  XOR A
  LD B,$20
NearBandByte:
  RLA
  RL (HL)
  RLA
  RL (HL)
  RLA
  RRCA
  RRCA
  DEC HL
  DJNZ NearBandByte
  EX DE,HL
  DEC C
  JR NZ,NearBandLine
  RET
NearBandDelay:
  LD BC,$0AF5             ; the buggy on the ground: no scroll, a delay of
                          ; $0AF5 loops
NearBandDelayLoop:
  DEC BC
  LD A,B
  OR C
  JR NZ,NearBandDelayLoop
  RET

; The road (lines 160-191): four pixels left a pass, new columns from RoadFeed
; every 2 passes; random texture on its top line
;
; Only while alive. The counter $B234 runs 2 passes; at 0 the 32 bytes at $B232
; (RoadFeed $A9AF, its crater edge strips set by the crater handler $9A92) go
; to FeedRoad $5B40. Each pass the 32 lines from $FD40 (line 160) roll four
; pixels left. Then random bits (FRAMES xor R, AND $0F, or AND $03 once when
; $B288 bit 3 is set, which it clears) are ORed into $509F, the last byte of
; line 160: the road's broken top edge.
;
; Witness: same counts as ScrollMountains (i1 3600). The h2 snapshot was taken
; inside it (PC $A981), which is why the cut had entries at $A957 / $A977 /
; $A981.
ScrollRoad:
  LD A,(DeathStep)
  INC A
  RET NZ
  LD A,(GroundCountdown)
  AND A
  JR NZ,RoadRoll
  LD HL,(GroundProfile)
  LD DE,FeedRoad
  LD BC,$0020
  LDIR
  LD A,$02
RoadRoll:
  DEC A                   ; the 32 lines from the line table at $FD40 (line
                          ; 160)
  LD (GroundCountdown),A
  LD IX,FeedRoad
  LD C,$20
  LD HL,ScreenLineTable+$0140

; RoadLine
;
; Used by the routine at RoadByteBits.
RoadLine:
  LD E,(HL)               ; four bits from the feed byte
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,L
  ADD A,$1F
  LD L,A
  XOR A
  RLC (IX+$00)
  RLA
  RLC (IX+$00)
  RLA
  RLC (IX+$00)
  RLA
  RLC (IX+$00)
  RLA
  LD B,$20

; RoadByte
;
; Used by the routine at RoadByteBits.
RoadByte:
  RRCA
  RRCA
  RRCA
  RRCA
  RLA
  RL (HL)
  RLA
  RL (HL)

; RoadByteBits
RoadByteBits:
  RLA
  RL (HL)
  RLA
  RL (HL)
  RLA
  DEC HL
  DJNZ RoadByte
  EX DE,HL
  INC IX
  DEC C
  JR NZ,RoadLine
  LD HL,PlayerFlags
  BIT 3,(HL)
  LD C,$0F
  JR Z,RoadTexture
  RES 3,(HL)
  LD C,$03
RoadTexture:
  LD A,(FRAMES)            ; C = $0F, or $03 once when $B288 bit 3 was set
  LD B,A
  LD A,R
  XOR B
  AND C
  LD B,A
  LD A,(Screen+4255)
  OR B
  LD (Screen+4255),A
  RET

; The road's feed strips: 32 bytes a strip, one a line of 160-191: plain road,
; then the crater's two walls
;
; ScrollRoad copies the strip at $B232 to FeedRoad every 2 passes. The life
; start ($90D3) and the crater handler ($9A92, x = $EC) set the plain strip,
; the crater handler the wall strips as the crater comes in from the right
; (RoadFeedWallA or RoadFeedWallB). l1sum --reads: every byte read (game 667,
; i1 1727 times each).
RoadFeed:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; plain
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; road: no
                                                                       ; bits under
                                                                       ; line 160
RoadFeedWallA:
  DEFB $FF,$FF,$7F,$7F,$3F,$3F,$3F,$3F,$1F,$1F,$1F,$1F,$0F,$0F,$07,$03 ; a crater
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; wall: $FF
                                                                       ; $FF $7F
                                                                       ; $7F $3F
                                                                       ; ... down
                                                                       ; to line
                                                                       ; 175, then
                                                                       ; nothing
RoadFeedWallB:
  DEFB $FF,$FF,$FE,$FE,$FC,$FC,$FC,$FC,$F8,$F8,$F8,$F0,$C0,$C0,$80,$00 ; the other
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; wall: $FF
                                                                       ; $FF $FE
                                                                       ; $FE $FC
                                                                       ; ... down
                                                                       ; to line
                                                                       ; 175, then
                                                                       ; nothing

; The buggy each pass: the controls, the jump, left / right, the crater probe,
; the draw; the death frames; the BREAK abort
;
; Alive ($B216 = $FF): ControlsRead $AE17 into C. Jump (bit 1): the jump index
; $B223 goes from $FF to 0 and then on, one step a pass even with the key up,
; through the arc at $B221 (JumpArcs, chosen by SpeedGovernor) until its $80
; ends it ($FF again). The step adds to the buggy y $B212.
;
; On the ground only: slow (bit 4) moves x $B213 two pixels left down to $29,
; fast (bit 3) two right up to $50, neither drifts back to $38 by two. Then the
; crater probe: five points x + 5, + 10, ... + 25 on the screen line 162
; ($5280, just under the road's top line 160, through the pixel table $FA00): a
; set pixel there is a crater's wall, BuggyKill $A7DD and the crater flag $B220
; = $FF.
;
; Then the draw at (x, y - 9) through ScrollAdjustIfAlive: sprite 0 alive, else
; the death frame: $B216 + 1 stored, sprite $1E + $B216 ($1F-$26). The main
; loop $96BB ends the life when $B216 reaches 8.
;
; Last the BREAK test: CAPS SHIFT (port $FEFE bit 0) and SPACE (port $7FFE bit
; 0) both down: SetIm1 and a jump to $8004, the title (a1 frame 3174, $AACD 1
; time). The test runs in play and during the death frames.
;
; Witness: game 1576, a1 292, g1 493, p2 664, h1 493, i1 3601, i2 3935, h2 40
; entries (i1 frames 263-30438); jump started (AA2A) game 463, i1 3249 steps;
; the probe hits $AA9C game 18, a1 1, p2 4, i1 69, i2 67.
BuggyUpdate:
  LD A,(DeathStep)
  CP $FF
  JP NZ,BuggyDrawAt
  CALL ControlsRead       ; C = the controls: bit 0 fire, 1 jump, 3 fast, 4
                          ; slow
  LD C,A
  AND $02
  LD D,$00
  LD A,(JumpStep)         ; the jump index $B223: $FF not jumping
  JR Z,BuggyNoJumpKey
  INC A
  JR BuggyJumpStep
BuggyNoJumpKey:
  INC A                   ; not jumping and no key: no step
  JR Z,BuggyMoveY
BuggyJumpStep:
  LD (JumpStep),A         ; the next byte of the arc: a y step, or $80 the end
  LD E,A
  LD HL,(JumpArc)
  ADD HL,DE
  LD A,(HL)
  CP $80
  JR NZ,BuggyJumpDelta
  XOR A
  LD D,A
  DEC A
  LD (JumpStep),A
  JR BuggyMoveY
BuggyJumpDelta:
  LD D,(HL)
BuggyMoveY:
  LD HL,(BuggyY)          ; y + the step
  LD A,L
  ADD A,D
  LD L,A
  LD (BuggyY),HL
  LD A,(JumpStep)
  INC A
  JR NZ,BuggyDraw         ; in the air: no left / right and no probe
  BIT 4,C
  JR Z,BuggyFast
  LD A,H
  CP $29
  JR C,BuggyFast
  DEC A
  DEC A
  LD H,A
BuggyFast:
  BIT 3,C                 ; bit 3: right, up to x = $50
  JR Z,BuggyDrift
  LD A,H
  CP $50
  JR NC,BuggyDrift
  INC A
  INC A
  LD H,A
BuggyDrift:
  LD A,C                  ; no key: back towards x = $38
  AND $18
  JR NZ,BuggyProbe
  LD A,H
  CP $38
  JR Z,BuggyProbe
  JR NC,BuggyDriftLeft
  INC H
  INC H
  JR BuggyProbe
BuggyDriftLeft:
  DEC H
  DEC H
BuggyProbe:
  LD (BuggyY),HL          ; five points of line 162 under the buggy, from x + 5
                          ; in steps of 5
  LD A,H
  ADD A,$05
  LD B,$05
BuggyProbeLoop:
  LD H,$7D                ; the pixel table $FA00: byte column and mask of x
  LD L,A
  SLA L
  RL H
  LD D,$00
  LD E,(HL)
  INC HL
  LD C,A
  LD A,(HL)
  LD HL,ScreenRow162
  ADD HL,DE
  AND (HL)
  JR NZ,BuggyFellInCrater
  LD A,C
  ADD A,$05
  DJNZ BuggyProbeLoop
  JR BuggyDrawAt
BuggyFellInCrater:
  CALL BuggyKill          ; a set pixel: the crater kills; flag $B220
  LD A,$FF
  LD (DeadFlag),A
BuggyDrawAt:
  LD HL,(BuggyY)
BuggyDraw:
  LD A,$F7                ; drawn 9 lines higher than its y
  ADD A,L
  LD L,A
  CALL ScrollAdjustIfAlive
  LD A,(DeathStep)
  CP $FF
  JR Z,BuggySprite
  INC A                   ; dying: the next death frame
  LD (DeathStep),A
  ADD A,$1D
BuggySprite:
  INC A                   ; sprite 0 alive, $1F-$26 dying
  CALL DrawSprite
BuggyBreakTest:
  LD BC,$FEFE             ; CAPS SHIFT and SPACE together: back to the title
  IN A,(C)
  LD E,A
  LD B,$7F
  IN A,(C)
  OR E
  AND $01
  RET NZ
  CALL SetIm1             ; the abort (a1 frame 3174)
  JP TitlePage

; Erases the buggy drawn last pass (XOR), alive or in a death frame
;
; HL = (x, y - 9). Alive: sprite 0. $B216 = 0 (killed this pass): the position
; through ScrollAdjustX and sprite 0. Dying: sprite $1E + $B216, the frame
; BuggyUpdate drew. Witness: the same counts as BuggyUpdate (game 1576, i1
; 3601).
BuggyErase:
  LD HL,(BuggyY)
  LD A,$F7
  ADD A,L
  LD L,A
  LD A,(DeathStep)
  AND A
  JR NZ,BuggyEraseFrame
  CALL ScrollAdjustX
  LD A,$FF
BuggyEraseFrame:
  CP $FF
  JR Z,BuggyEraseSprite
  ADD A,$1D
BuggyEraseSprite:
  INC A
  CALL DrawSprite
  RET

; The three jump arcs: y steps a pass, $80 ends; back position (short), centre,
; forward (long)
;
; SpeedGovernor sets $B221 to one of them from the buggy's x (JumpSpeeds
; $AF68), BuggyUpdate adds a byte a pass. The sums are 0: the buggy lands where
; it took off. l1sum --reads: all 71 bytes read.
JumpArcs:
  DEFB $FD,$FE,$FE,$FE,$FF,$00,$00,$01,$02,$02,$02,$03,$80 ; JumpArcs proper,
                                                           ; the back arc: x <
                                                           ; $38: 12 steps, 10
                                                           ; pixels up
JumpArcCentre:
  DEFB $FE,$FD,$FE,$FD,$FE,$FF,$FE,$FF,$FE,$00,$FF,$00,$00 ; x = $38: 24 steps,
  DEFB $01,$00,$02,$01,$02,$01,$02,$03,$02,$03,$02,$80     ; 19 pixels up
JumpArcForward:
  DEFB $FE,$FE,$FE,$FF,$FE,$FE,$FF,$FE,$FE,$FF,$FF,$FF,$00 ; x > $38: 32 steps,
  DEFB $FF,$00,$00,$00,$00,$01,$00,$01,$01,$01,$02,$02,$01 ; 20 pixels up
  DEFB $02,$02,$01,$02,$02,$02,$80

; At a death: the three wheels fly off for 32 steps along WheelPaths
;
; Only while dying ($B216 not $FF), four calls a main-loop pass. At wheel step
; $B217 = 0 the wheels start at y $97 and x + 1, x + $0A, x + $16 ($B21A,
; $B21C, $B21E; sprites $3C, $3D, $3E), the path pointer $B218 = WheelPaths.
; Each step every wheel still on screen is erased (WheelErase), moved by its
; two bytes (y up by the first, x by the second) and drawn; the first leaves
; left, the third right (a carry out of x ends a wheel, its word = 0). $B217 +
; 1.
;
; Witness: game 6303, a1 1164, g1 1972, p2 2656, h1 1972, i1 14 401, i2 15 737,
; h2 161 entries (the calls); the work after the alive test ran only when a
; death counted: $AB5F game 611, a1 67, g1 140, p2 268, h1 140, h2 35, none in
; i1 / i2 (BuggyKill is RET there).
WheelsFly:
  LD A,(DeathStep)
  INC A
  RET Z
  LD A,(WreckStep)
  AND A
  JR NZ,WheelsStep
  LD A,(BuggyX)
  LD L,$97
  ADD A,$01
  LD H,A
  LD (WreckPiece1),HL
  ADD A,$09
  LD H,A
  LD (WreckPiece2),HL
  ADD A,$0C
  LD H,A
  LD (WreckPiece3),HL
  LD HL,WheelPaths
  LD (WreckPath),HL
WheelsStep:
  LD IX,(WreckPath)       ; IX = the path, the three wheels in turn
  LD HL,(WreckPiece1)
  LD A,H
  OR L
  JR NZ,WheelOneMove
  INC IX
  INC IX
  JR WheelTwo
WheelOneMove:
  LD A,$3C                ; the left wheel: x - 3 a step
  CALL WheelErase
  LD A,(IX+$00)
  NEG
  LD E,A
  INC IX
  LD D,(IX+$00)
  INC IX
  LD A,H
  ADD A,D
  JR C,WheelOneDraw
  LD HL,$0000
  LD (WreckPiece1),HL
  JR WheelTwo
WheelOneDraw:
  LD H,A
  LD A,L
  ADD A,E
  LD L,A
  LD (WreckPiece1),HL
  LD A,$3C
  PUSH IX
  CALL DrawSprite
  POP IX
WheelTwo:
  LD HL,(WreckPiece2)     ; the middle wheel
  LD A,H
  OR L
  JR NZ,WheelTwoMove
  INC IX
  INC IX
  JR WheelThree
WheelTwoMove:
  LD A,$3D
  CALL WheelErase
  LD A,(IX+$00)
  NEG
  LD E,A
  INC IX
  LD D,(IX+$00)
  INC IX
  LD A,H
  ADD A,D
  JR NC,WheelTwoDraw
  LD HL,$0000
  LD (WreckPiece2),HL
  JR WheelThree
WheelTwoDraw:
  LD H,A
  LD A,L
  ADD A,E
  LD L,A
  LD (WreckPiece2),HL
  LD A,$3D
  PUSH IX
  CALL DrawSprite
  POP IX
WheelThree:
  LD HL,(WreckPiece3)     ; the right wheel
  LD A,H
  OR L
  JR NZ,WheelThreeMove
  INC IX
  INC IX
  JR WheelsStepDone
WheelThreeMove:
  LD A,$3E
  CALL WheelErase
  LD A,(IX+$00)
  NEG
  LD E,A
  INC IX
  LD D,(IX+$00)
  INC IX
  LD A,H
  ADD A,D
  JR NC,WheelThreeDraw
  LD HL,$0000
  LD (WreckPiece3),HL
  JR WheelsStepDone
WheelThreeDraw:
  LD H,A
  LD A,L
  ADD A,E
  LD L,A
  LD (WreckPiece3),HL
  LD A,$3E
  PUSH IX
  CALL DrawSprite
  POP IX
WheelsStepDone:
  LD (WreckPath),IX       ; the path pointer and the step $B217 + 1
  LD A,(WreckStep)
  INC A
  LD (WreckStep),A
  RET

; Erases wheel sprite A at HL, except at step 0 (nothing drawn yet)
;
; Witness: game 1598, a1 176, g1 376, p2 716, h1 376, h2 88 entries (a1 frames
; 2010-2886); none in i1 / i2.
WheelErase:
  LD C,A
  LD A,(WreckStep)
  AND A
  RET Z
  LD A,C
  PUSH HL
  PUSH IX
  CALL DrawSprite
  POP IX
  POP HL
  RET

; The wheels' paths: 32 steps of y up, x for the left, middle and right wheel
;
; Read by WheelsFly. The y steps (up positive) fall from 11 or 12 to -7 (the
; outer wheels) or -2 (the middle one): arcs; x steps -3, 0, +4. l1sum --reads:
; read in game, a1, g1, p2, h1, h2 (the deaths).
WheelPaths:
  DEFB $0B,$FD,$0C,$00,$0B,$04
  DEFB $0A,$FD,$0B,$00,$0A,$04
  DEFB $08,$FD,$0A,$00,$08,$04
  DEFB $07,$FD,$08,$00,$07,$04
  DEFB $05,$FD,$07,$00,$05,$04
  DEFB $04,$FD,$06,$00,$04,$04
  DEFB $02,$FD,$04,$00,$02,$04
  DEFB $01,$FD,$03,$00,$01,$04
  DEFB $FF,$FD,$02,$00,$FF,$04
  DEFB $FE,$FD,$01,$00,$FE,$04
  DEFB $FC,$FD,$FF,$00,$FC,$04
  DEFB $FB,$FD,$FE,$00,$FB,$04
  DEFB $F9,$FD,$FD,$00,$F9,$04
  DEFB $F8,$FD,$FC,$00,$F8,$04
  DEFB $F6,$FD,$FA,$00,$F6,$04
  DEFB $F5,$FD,$F9,$00,$F5,$04
  DEFB $07,$FD,$F8,$00,$07,$04
  DEFB $07,$FD,$F6,$00,$07,$04
  DEFB $05,$FD,$F5,$00,$05,$04
  DEFB $05,$FD,$F4,$00,$05,$04
  DEFB $03,$FD,$09,$00,$03,$04
  DEFB $03,$FD,$08,$00,$03,$04
  DEFB $01,$FD,$07,$00,$01,$04
  DEFB $01,$FD,$07,$00,$01,$04
  DEFB $FF,$FD,$05,$00,$FF,$04
  DEFB $FF,$FD,$04,$00,$FF,$04
  DEFB $FD,$FD,$04,$00,$FD,$04
  DEFB $FD,$FD,$02,$00,$FD,$04
  DEFB $FB,$FD,$02,$00,$FB,$04
  DEFB $FB,$FD,$00,$00,$FB,$04
  DEFB $F9,$FD,$FE,$00,$F9,$04
  DEFB $F9,$FD,$FE,$00,$F9,$04

; Fire: a forward shot and an upward shot on each new press
;
; Only while alive. ControlsRead bit 0; up: $B288 bit 1 cleared. A new press
; (bit 1 was clear) sets it, then: ShotForward $5B60 free ($FF): y + 1, x +
; $20, the end x + $80, drawn (DrawShotForward). And an upward shot when no
; shot in ShotsUp is still below line $6D: a free one gets y - 12 (AND $FC) and
; x + 8, drawn (DrawShotUp). Witness: game 1576, i1 3601 entries; new presses
; $AD06 game 153, a1 12, g1 42, p2 55, h1 42, i1 332, i2 367.
FireShots:
  LD A,(DeathStep)
  INC A
  RET NZ
  CALL ControlsRead
  AND $01
  LD A,(PlayerFlags)
  JR NZ,FireNewPress
  AND $FD
  LD (PlayerFlags),A
  RET
FireNewPress:
  BIT 1,A
  RET NZ
  OR $02
  LD (PlayerFlags),A
  LD DE,(BuggyY)
  LD HL,ShotForward
  LD A,(HL)
  INC A
  JR NZ,FireUpCheck
  LD A,E
  INC A
  LD (HL),A
  LD C,A
  INC HL
  LD A,D
  ADD A,$20
  LD (HL),A
  LD B,A
  INC HL
  INC HL
  INC HL
  ADD A,$60
  LD (HL),A
  LD H,B
  LD L,C
  CALL DrawShotForward
FireUpCheck:
  LD HL,ShotsUp             ; no new upward shot while one is still below line
                          ; $6D
  LD B,$04
FireUpCheckLoop:
  LD A,(HL)
  ADD A,$02
  CP $6F
  RET NC
  INC HL
  INC HL
  INC HL
  INC HL
  DJNZ FireUpCheckLoop
  LD HL,ShotsUp
  LD B,$04
FireUpFree:
  LD A,(HL)
  INC A
  JR Z,FireUpStart
  INC HL
  INC HL
  INC HL
  INC HL
  DJNZ FireUpFree
  RET
FireUpStart:
  LD A,E                  ; y - 12 on a multiple of 4, x + 8
  SUB $0C
  AND $FC
  LD (HL),A
  LD E,A
  INC HL
  LD A,D
  ADD A,$08
  LD (HL),A
  LD D,A
  EX DE,HL
  CALL DrawShotUp
  RET

; Moves the forward shot and the four upward shots
;
; ShotForwardMove then ShotsUpMove. Witness: game 1576, a1 291, g1 493, p2 664,
; h1 493, i1 3601, i2 3935, h2 40 entries.
ShotsMove:
  CALL ShotForwardMove
  CALL ShotsUpMove
  RET

; The forward shot: erase, 6 pixels right, end at its end x or when hit, draw
;
; Erased (DrawShotForward), first through ScrollAdjustX when the buggy was
; killed this pass by something else than a crater ($B216 = 1, $B220 = 0). Its
; height byte $FF (an object handler hit it): free ($5B60 = $FF). Else height
; 3, x + 6; at the end x free, else drawn again. Witness: same entry counts as
; ShotsMove; moves $AD9E game 440, i1 2640.
ShotForwardMove:
  LD HL,ShotForward
  LD A,(HL)
  INC A
  RET Z
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,(DeadFlag)
  LD C,A
  LD A,(DeathStep)
  DEC A
  OR C
  CALL Z,ScrollAdjustX
  CALL DrawShotForward
  EX DE,HL
  INC HL
  LD A,(HL)
  CP $FF
  LD (HL),$03
  DEC HL
  JR NZ,ShotForwardStep
  DEC HL
  LD (HL),A
  RET
ShotForwardStep:
  LD A,(HL)
  ADD A,$06
  INC HL
  INC HL
  INC HL
  CP (HL)
  DEC HL
  DEC HL
  DEC HL
  JR C,ShotForwardDraw
  DEC HL
  LD (HL),$FF
  RET
ShotForwardDraw:
  LD (HL),A
  LD D,A
  DEC HL
  LD E,(HL)
  EX DE,HL
  INC L
  CALL ScrollAdjustIfAlive
  DEC L
  CALL DrawShotForward
  RET

; The four upward shots: ShotUpMove on each one in use
;
; Witness: same entry counts as ShotsMove.
ShotsUpMove:
  LD HL,ShotsUp
  LD B,$04
ShotsUpLoop:
  PUSH BC
  LD A,(HL)
  INC A
  CALL NZ,ShotUpMove
  LD DE,$0004
  ADD HL,DE
  POP BC
  DJNZ ShotsUpLoop
  RET

; One upward shot: erase, 4 pixels up, end above line $18 or when hit, draw
;
; As ShotForwardMove with height 4 and DrawShotUp. Witness: game 951, a1 271,
; g1 987, p2 1236, h1 987, i1 7833, i2 8636 entries.
ShotUpMove:
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,(DeadFlag)
  LD C,A
  LD A,(DeathStep)
  DEC A
  OR C
  CALL Z,ScrollAdjustX
  CALL DrawShotUp
  EX DE,HL
  INC HL
  LD A,(HL)
  CP $FF
  LD (HL),$04
  DEC HL
  DEC HL
  JR NZ,ShotUpStep
  LD (HL),A
  RET
ShotUpStep:
  LD A,(HL)
  SUB $04
  CP $18
  JR NC,ShotUpDraw
  LD (HL),$FF
  RET
ShotUpDraw:
  LD (HL),A
  LD E,A
  INC HL
  LD D,(HL)
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  CALL DrawShotUp
  EX DE,HL
  RET

; The forward shot: 6 pixels across from (x, y + 1), XOR
;
; Also sprite $3B of the sprite table. Witness: game 936, a1 211, g1 709, p2
; 914, h1 709, i1 5642, i2 6103 entries.
DrawShotForward:
  LD A,$06
  INC L
DrawShotForwardLoop:
  EX AF,AF'
  CALL ShotPlot
  EX AF,AF'
  INC H
  DEC A
  JR NZ,DrawShotForwardLoop
  RET

; An upward shot: 4 pixels down from (x + 1, y), XOR
;
; Witness: game 1913, a1 545, g1 1980, p2 2483, h1 1980, i1 15 680, i2 17 284,
; h2 30 entries.
DrawShotUp:
  LD A,$04
  INC H
DrawShotUpLoop:
  EX AF,AF'
  CALL ShotPlot
  EX AF,AF'
  INC L
  DEC A
  JR NZ,DrawShotUpLoop
  RET

; One pixel through $FDB3, HL kept
;
; Witness: game 13 268, a1 3566, i1 97 928 entries.
ShotPlot:
  PUSH HL
  CALL FlipPixel
  POP HL
  RET

; Reads the chosen control (control type $B259, 1-6) and returns its bits
; active high: 0 fire, 1 up / jump, 2 down, 3 right / fast, 4 left / slow
;
; Jumps to ControlHandlers[$B259 - 1]; each handler returns the five bits
; active low with the others 1, and ControlsReadDone inverts them (CPL): bits
; 5-7 come back 0. Bit 2 (down) is read by no caller. Callers: the options page
; ($8227: fire alone starts the game when the control is not the keyboard),
; BuggyUpdate, FireShots, the hold.
;
; $B259 is the third option of the options page (keys Z X C V B K, the text at
; $8586; 6 in the entry image). Witness: game 2939, a1 28 792, g1 922, p2 1208,
; h1 922, i1 7202, i2 7870, h2 64 entries; the handler of each run below.
ControlsRead:
  LD HL,ControlHandlers
  LD D,$00
  LD A,(Controls)
  DEC A
  ADD A,A
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD DE,ControlsReadDone
  PUSH DE
  JP (HL)

; ControlsReadDone
ControlsReadDone:
  CPL                     ; active low to active high
  RET

; The six control readers by $B259 - 1, in the options page's order Z X C V B K
;
; Read by ControlsRead (l1sum --reads: $AE38 a1 28 753, g1 922, ... i1 7202:
; the keyboard; $AE2E game 2296, $AE30 game 643: c1's random keys chose
; Sinclair and Kempston; every word a1 7-8: the options page).
ControlHandlers:
  DEFW JoySinclair1       ; 1 Z: Sinclair with 1 Joystick
  DEFW JoyKempston        ; 2 X: Kempston Joystick
  DEFW JoyCursor          ; 3 C: Cursor Joystick
  DEFW JoyFuller          ; 4 V: Old-type Fuller Box with Joystick
  DEFW JoySinclair2       ; 5 B: Sinclair with 2 Joysticks
  DEFW KeysQAOP           ; 6 K: Keyboard (A slow, Q fast, O jump, P fire)

; Control 1 (Z, Sinclair with 1 Joystick): both Interface 2 sticks, keys 6-0
; and 1-5, ANDed
;
; Port $EFFE (6 left, 7 right, 8 down, 9 up, 0 fire: bits 4-0 already in the
; common order) into E; port $F7FE (1 left, 2 right, 3 down, 4 up, 5 fire) with
; its five bits reversed into C; C AND E OR $E0. Either stick drives the buggy.
; Witness: a1 8 runs (frames 779-833, the options page with Z chosen), game
; 2296 (c1's random keys chose it: frames 1395-13759). No joystick was moved:
; the paths ran with keys or nothing.
JoySinclair1:
  LD A,$EF
  IN A,($FE)
  LD E,A
; This entry point is used by the routine at JoySinclair2.
JoySinclairKeys1To5:
  LD A,$F7                ; port $F7FE, its bits 0-4 reversed (JoySinclair2
                          ; enters here with E = $FF for player 2)
  IN A,($FE)
  LD B,$05
JoySinclairReverse:
  RRA
  RL C
  DJNZ JoySinclairReverse
  LD A,C
  AND E
  OR $E0
  RET

; Control 5 (B, Sinclair with 2 Joysticks): one stick a player in a two-player
; game
;
; One player ($B257 = 1): as JoySinclair1. Two players: player 1 ($B271 = 1)
; reads port $EFFE (keys 6-0) only, player 2 port $F7FE (keys 1-5) only,
; through JoySinclairKeys1To5 with E = $FF. Witness: a1 8 runs (frames
; 1016-1069, the options page, one player); the two-player paths were not
; executed in any recording (game, a1, g1, t1, p2, h1, i1, i2, h2): known only
; from the code (p2 used the keyboard).
JoySinclair2:
  LD A,(Players)
  DEC A
  JR Z,JoySinclair1
  LD A,(Player)
  DEC A
  LD E,$FF
  JR NZ,JoySinclairKeys1To5
  LD A,$EF
  IN A,($FE)
  OR $E0
  RET

; Control 2 (X, Kempston Joystick): IN ($1F), active high bits 0 right, 1 left,
; 2 down, 3 up, 4 fire, put in the common order
;
; The five bits rotated through B into fire 0, up 1, down 2, right 3, left 4,
; then CPL and OR $E0: active low like the others. Witness: a1 8 runs (frames
; 841-894, the options page), game 643 (frames 13 766-16 753). The emulator had
; no Kempston input: the port read only what it gives when nothing is pressed.
JoyKempston:
  IN A,($1F)
  LD B,$00
  RRA
  RR B
  RRA
  RL B
  RL B
  RRA
  RL B
  RRA
  RL B
  RRA
  RL B
  LD A,B
  CPL
  OR $E0
  RET

; Control 3 (C, Cursor Joystick): 5 left, 6 down, 7 up, 8 right, 0 fire
;
; Port $F7FE bit 4 (5) to bit 4 left; port $EFFE bit 0 (0) fire, bit 3 (7) to
; bit 1 up, bit 4 (6) to bit 2 down, bit 2 (8) to bit 3 right. Witness: a1 7
; runs (frames 902-947, the options page); never in play.
JoyCursor:
  LD BC,$F7FE
  IN A,(C)
  OR $EF
  LD E,A
  LD B,$EF
  IN A,(C)
  OR $FE
  AND E
  LD E,A
  IN A,(C)
  OR $E7
  RRCA
  RRCA
  AND E
  LD E,A
  IN A,(C)
  OR $FB
  RLCA
  AND E
  RET

; Control 4 (V, Old-type Fuller Box with Joystick): IN ($7F), active low bits 0
; up, 1 down, 2 left, 3 right, 7 fire
;
; Rotated into fire 0, up 1, down 2, right 3, left 4 (the other bits 1).
; Witness: a1 8 runs (frames 955-1008, the options page); never in play.
JoyFuller:
  IN A,($7F)
  OR $70
  LD B,A
  RLCA
  OR $F8
  LD C,A
  LD A,B
  OR $F7
  AND C
  LD C,A
  LD A,B
  OR $FB
  RLCA
  RLCA
  AND C
  RET

; Control 6 (K, Keyboard): P fire, O jump, Q fast, A slow
;
; Port $FDFE bit 0 (A) to bit 4, port $FBFE bit 0 (Q) to bit 3, port $DFFE bits
; 0 (P) and 1 (O) to bits 0 and 1. The only control of every play recording: a1
; 28 753 runs (frames 1424-21149), g1 922, p2 1208, h1 922, i1 7202, i2 7870,
; h2 64.
KeysQAOP:
  LD BC,$FDFE
  IN A,(C)
  OR $FE
  RLCA
  LD E,A
  LD B,$FB
  IN A,(C)
  OR $FE
  AND E
  RLCA
  RLCA
  RLCA
  LD E,A
  LD B,$DF
  IN A,(C)
  OR $FC
  AND E
  RET

; The hold: H stops the game (IM 1, the clock frozen) until H again, S or fire
;
; Port $BFFE bit 4 (H). Up: $B288 bit 4 cleared (HoldKeyUp). Down while bit 4
; is set (still the same press): nothing. A new press: bit 4 set, SetIm1 (the
; game's handler and its clock $7F98 stop), wait for H up, 5 frames, then
; HoldLoop until fire (ControlsRead bit 0: at once), S (port $FDFE bit 1: at
; once) or H (5 frames); SetIm2 $A7D4 and back to the main loop.
;
; Witness: game 1575, a1 291, g1 493, p2 664, h1 493, i1 3600, i2 3934, h2 41
; entries; the hold itself only in a1 (a new press $AEE0 1 time,
; HoldWaitRelease 30 472 loops, HoldLoop 28 199, left with H through
; HoldResumeWait 5 HALTs: a1 frames 2060-2220 of NOTES). Leaving with S or fire
; was not executed in any recording: known only from the code.
HoldCheck:
  LD BC,$BFFE
  IN A,(C)
  OR $EF
  INC A
  LD HL,PlayerFlags
  JR Z,HoldKeyUp
  BIT 4,(HL)
  RET NZ
  SET 4,(HL)
  CALL SetIm1             ; IM 1: the game's clock stops while held
HoldWaitRelease:
  IN A,(C)                ; until H is up
  OR $EF
  INC A
  JR NZ,HoldWaitRelease
  LD B,$05
HoldWait:
  HALT
  DJNZ HoldWait
HoldLoop:
  CALL ControlsRead       ; fire, S or H again
  AND $01
  JR NZ,HoldResume
  LD BC,$FDFE             ; S: resume at once
  IN A,(C)
  OR $FD
  INC A
  JR NZ,HoldResume
  LD B,$BF                ; H: resume after 5 frames
  IN A,(C)
  OR $EF
  INC A
  JR Z,HoldLoop
  LD B,$05
HoldResumeWait:
  HALT
  DJNZ HoldResumeWait
HoldResume:
  CALL SetIm2             ; IM 2 again
  RET
HoldKeyUp:
  RES 4,(HL)              ; H up: the next press holds again
  RET

; T toggles the tune: $B288 bit 7 flips on each new press
;
; Port $FBFE bit 4 (T). Up: $B288 bit 0 cleared. A new press (bit 0 clear): bit
; 0 set and bit 7 flipped; the tune player $7F47 is silent while bit 7 is set.
; Witness: game 1576, a1 292, g1 493, p2 664, h1 493, i1 3601, i2 3935, h2 40
; entries; a1 pressed T at 2540 and 2740 (NOTES), the toggle path $AF22-$AF29
; a1 6 runs (292 - 286).
TuneToggleCheck:
  LD BC,$FBFE
  IN A,(C)
  OR $EF
  INC A
  LD A,(PlayerFlags)
  JR Z,TuneKeyUp
  BIT 0,A
  RET NZ
  OR $01
  XOR $80
  JR TuneFlagsStore
TuneKeyUp:
  AND $FE
TuneFlagsStore:
  LD (PlayerFlags),A
  RET

; The pace of the game: a delay a pass and the jump arc chosen by the buggy's x
;
; x $B213 against $38: forward (> $38) the index 0, centre 1, back (< $38) 2
; into JumpSpeeds $AF68: the jump arc to $B221 and the delay count, + $1800
; while dying. Then a busy loop of that many iterations: forward 1, centre
; $02EE, back $05DC. Called twice a main-loop pass (game 3151, a1 582, g1 986,
; p2 1328, h1 986, i1 7200, i2 7868, h2 81 entries).
SpeedGovernor:
  LD A,(DeathStep)
  INC A
  LD BC,$0000
  JR Z,SpeedFromX
  LD BC,$1800
SpeedFromX:
  LD A,(BuggyX)
  SUB $38
  JR Z,SpeedIndex
  AND $80
  RLCA
  RLCA
  DEC A
SpeedIndex:
  INC A
  RLCA
  RLCA
  LD E,A
  LD D,$00
  LD HL,JumpSpeeds
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  ADD HL,BC
  LD B,H
  LD C,L
  LD (JumpArc),DE
SpeedDelay:
  DEC BC
  LD A,B
  OR C
  JR NZ,SpeedDelay
  RET

; Three records by the buggy's position: jump arc, delay count
;
; l1sum --reads: forward $AF68 i1 7056 of 7200 (the immune runs held fast),
; centre $AF6C game 2663, back $AF70 game 228 only.
JumpSpeeds:
  DEFW JumpArcForward,$0001 ; forward (x > $38): JumpArcForward, 1 loop
  DEFW JumpArcCentre,$02EE ; centre (x = $38): JumpArcCentre, $02EE loops
  DEFW JumpArcs,$05DC     ; back (x < $38): JumpArcs (the back arc), $05DC
                          ; loops

; ScrollAdjustX, only while the buggy is alive
;
; Witness: game 3474, a1 716, g1 2054, p2 2534, h1 2054, i1 19 540, i2 25 107,
; h2 90 entries.
ScrollAdjustIfAlive:
  LD A,(DeathStep)
  INC A
  RET NZ

; Adds the scroll step of y's band to x (H): what is drawn there moves with its
; band
;
; L = y: below $40 nothing; $40-$5F the mountains' step $B225 (1); $60-$7F the
; hills' $B229 (2); $80-$9F the hills' step only while BuggyAirborne (the near
; band scrolls then); $A0 and down the road's $B235 (4). Returns through
; BuggyAirborne. Witness: game 3022, a1 672, g1 1932, p2 2277, h1 1932, h2 78
; entries (falls in from ScrollAdjustIfAlive in i1 / i2, so no entries there).
ScrollAdjustX:
  LD A,L
  CP $40
  JR C,BuggyAirborne
  CP $60
  JR NC,ScrollAdjustHills
  LD A,(HillsSpeed)
  JR ScrollAdjustAdd
ScrollAdjustHills:
  CP $80
  JR NC,ScrollAdjustNear
  LD A,(MiddleSpeed)
  JR ScrollAdjustAdd
ScrollAdjustNear:
  CP $A0
  JR C,ScrollAdjustNearBand
  LD A,(GroundSpeed)
  JR ScrollAdjustAdd
ScrollAdjustNearBand:
  LD A,(BuggyY)           ; lines $80-$9F: only while the buggy is in the air
  CP $89
  JR NC,BuggyAirborne
  LD A,(MiddleSpeed)
ScrollAdjustAdd:
  ADD A,H
  LD H,A

; Carry when the buggy is in the air: its y $B212 below $89 (on the ground $92)
;
; Witness: game 4445, a1 946, g1 2389, p2 2873, h1 2389, i1 23 140, i2 29 041,
; h2 109 entries.
BuggyAirborne:
  LD A,(BuggyY)
  CP $89
  RET
