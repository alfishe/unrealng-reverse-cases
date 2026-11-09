; --------------------------------------------------------------------------------------------------------------------
; course.asm: The main loop, the course interpreter, the course commands and the first object handlers
;
; The main loop MainLoop $9696 reads the course script one segment at a time with the interpreter CourseRun $9751 and
; runs the call list MainLoopCalls $96FA once a pass; when the buggy has died it returns. One pass of the list runs
; the object list at $BEF8 (ObjectListRun $9745) with the same interpreter.
;
; The script ($B7E8 Beginner, $BB24 Champion) is a list of command words, each followed by its data: CourseRun jumps
; to the word with HL past it, and the command returns HL past its data. A segment is SegmentLength $976C (the passes
; until the next segment), then the commands, then SegmentEnd $9760. Most commands are spawners: for each data byte up
; to $FF (the delay in object-list passes before the object acts) they append an object record to the list at the
; write pointer $B261: the handler's word, the delay, then the handler's own fields. SegmentEnd writes the list's end
; word $975E.
;
; The object list is the same kind of program: ObjectListRun runs every record's handler, which counts its delay down
; and then acts; a finished object puts a "skip" routine in its word (the RET end of its own handler), so the record
; stays and costs a few instructions. The list starts again at $BEF8 at every MainLoop entry (life start, after each
; bonus screen, the course switch).
;
; The record fields used here: +0 the handler word, +2 the delay, then for the obstacles the sprite, y, x, height,
; width (the box $A7FE compares with the buggy's at $B212 and the forward shot's at $5B60). The handlers from $9B6B on
; are in the next module.
; --------------------------------------------------------------------------------------------------------------------

; The main loop of a life or a sector: reads a course segment when its time is
; up, runs the call list
;
; Saves SP at $B25F (the bonus screen $A4EE and the course switches $BB07 /
; $BED4 come back here with LD SP,($B25F) / JP $9696), enables the object list
; ($B238 = 0), starts it at $BEF8 ($B261 the write pointer) and sets the
; restart pointer $B27F to the course pointer $B27A. Then MainLoopSegment $96AA
; reads the next segment (CourseRun $9751 with DE = the write pointer) and
; MainLoopPass runs MainLoopCalls.
;
; MainLoopPass $96BB: when the buggy's death has run its course ($B216 = 8):
; the last frame erased (sprite $26 at y - 9), $B216 / $B217 = $FF, the course
; pointer back to the restart point $B27F, SetIm1 $A7CB, and RET: the life is
; over (LifePlay $90CC returns). Else the pass counter $B23B goes down by 1 and
; the segment time $B23C by 1; at 0 the segment start $B281 = the course
; pointer and the next segment is read.
;
; One pass has no frame sync: 3601 passes in about 30 175 frames of i1
; (WALKTHROUGH 1). Witness: game 20 runs (1559-16753), a1 3, g1 4, p2 8, h1 4,
; i1 7, i2 7 (the life start, five bonus screens, the course switch); segments
; read ($96AA) i1 37, i2 40; deaths ($96C5) game 19, a1 2, g1 4, p2 8, h1 4, h2
; 1.
MainLoop:
  LD (LoopStack),SP
  XOR A
  LD (ObjectsOff),A
  LD HL,ObjectList        ; the object list from $BEF8
  LD (ObjectWrite),HL
  LD HL,(PlayerCourse)    ; the restart point = where this life (or sector)
                          ; starts
  LD (PlayerRestart),HL
; This entry point is used by the routine at MainLoopPass.
MainLoopSegment:
  LD DE,(ObjectWrite)     ; the next segment: commands append objects at the
                          ; write pointer
  LD HL,(PlayerCourse)
  CALL CourseRun
  LD (ObjectWrite),DE
  LD (PlayerCourse),HL

; MainLoopPass
MainLoopPass:
  CALL MainLoopCalls      ; one pass of the call list; the death ends the life
  LD A,(DeathStep)
  CP $08
  JR NZ,MainLoopTimer
  LD HL,(BuggyY)          ; the death is over: erase, the restart point, IM 1,
                          ; return
  LD A,L
  SUB $09
  LD L,A
  LD A,$26
  CALL DrawSprite
  LD A,$FF
  LD (DeathStep),A
  LD (WreckStep),A
  LD HL,(PlayerRestart)
  LD (PlayerCourse),HL
  CALL SetIm1
  RET
MainLoopTimer:
  LD HL,PassCount         ; the pass counter and the segment time
  DEC (HL)
  LD HL,(SegmentWait)
  DEC HL
  LD (SegmentWait),HL
  LD A,H
  OR L
  JR NZ,MainLoopPass
  LD HL,(PlayerCourse)    ; the time is up: remember the segment start, read
                          ; the next one
  LD (PlayerSegment),HL
  JR MainLoopSegment

; The call list of one main-loop pass: keys, the buggy, shots, scrollers,
; objects, ground, hold
;
; In order: the tune key $AF15, BreakKeyTest $9737 (result ignored), $ACF1,
; HudPrintTime $922A, $A846, $AAD3, $AA0F, $AB37, $AD61, ObjectListRun $9745,
; SceneryColoursRepaint $95F2, $AB37, $A8FD, $A89A, $AB37, $AF31, the ground
; $A932, the hold key $AECE, $AB37, $AF31.
;
; Called by MainLoopPass and the title's demo $8064. Witness: game 1576 runs
; (1559-16757), a1 292, g1 493, p2 664, h1 493, i1 3601, i2 3935, h2 40.
MainLoopCalls:
  CALL TuneToggleCheck
  CALL BreakKeyTest
  CALL FireShots
  CALL HudPrintTime
  CALL ScrollFarBand
  CALL BuggyErase
  CALL BuggyUpdate
  CALL WheelsFly
  CALL ShotsMove
  CALL ObjectListRun
  CALL SceneryColoursRepaint
  CALL WheelsFly
  CALL ScrollNearBand
  CALL ScrollMiddleBand
  CALL WheelsFly
  CALL SpeedGovernor
  CALL ScrollRoad
  CALL HoldCheck
  CALL WheelsFly
  CALL SpeedGovernor
  RET

; Reads the key '0' (row $EFFE): returns NZ when it is pressed; the caller
; ignores it
;
; IN of port $EFFE, OR $FE, INC A: Z when '0' is up. MainLoopCalls never tests
; the flag, and the stub CourseBreakToBasic $9740 after it is never called: a
; debug exit left in (a1 pressed '0', nothing happened). Witness: game 1576
; runs, a1 292, i1 3601, i2 3935.
BreakKeyTest:
  LD BC,$EFFE
  IN A,(C)
  OR $FE
  INC A
  RET

; Never called: the bytes of CALL SetIm1 $A7CB, RST 8, DEFB $14 (the report L
; BREAK into program)
;
; No reference to it in the image, never executed or read in any recording
; (game, a1, g1, t1, p2, h1, i1, i2, h2): known only from the bytes. Kept as
; data: as code the walk would run on into $9744 ($14 as INC D). With
; BreakKeyTest before it, it reads as a removed '0' = BREAK exit to BASIC (a JR
; NZ to here).
CourseBreakToBasic:
  DEFB $CD,$CB,$A7,$CF,$14

; Runs the object list at $BEF8 once (CourseRun), unless $B238 is set
;
; $B238 = 0 at MainLoop; the title's demo sets it to $80 ($819E): the demo runs
; without objects. Witness: game 1576 runs, a1 291, g1 493, p2 664, h1 493, i1
; 3601, i2 3934, h2 40.
ObjectListRun:
  LD A,(ObjectsOff)
  AND A
  RET NZ
  LD HL,ObjectList
  CALL CourseRun
  RET

; The interpreter of the course script and the object list: runs the routine at
; the word (HL), HL past it
;
; IX = the word, HL += 2, CourseRun pushed as the return address, JP (IX). Each
; routine leaves HL past its data and returns into CourseRun, which runs the
; next word; the end word $975E (ListStop) pops that return and RETs to
; CourseRun's caller. Called by MainLoop (the script: DE = the object list
; write pointer, HL = the course pointer) and ObjectListRun (HL = $BEF8).
;
; Witness: game 8038 runs, a1 967, g1 2799, p2 3352, h1 2799, i1 89827, i2
; 123263, h2 200.
CourseRun:
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  PUSH BC
  POP IX
  LD BC,CourseRun
  PUSH BC
  JP (IX)

; The end of a list: drops CourseRun's return address and returns to its caller
;
; The word $975E ends the object list (SegmentEnd writes it). Witness: game
; 1598 runs, i1 3631, i2 3968 (the ends of the object-list passes, and
; SegmentEnd's JP).
ListStop:
  POP BC
  RET

; Script command: the end of a segment; writes the list end $975E at the write
; pointer (DE) and stops
;
; DE is not advanced: the next segment's objects go over the end word. Witness:
; game 22, a1 3, g1 6, p2 8, h1 6, i1 31, i2 34 (every segment read).
SegmentEnd:
  EX DE,HL
  LD BC,ListStop
  LD (HL),C
  INC HL
  LD (HL),B
  DEC HL
  EX DE,HL
  JP ListStop

; Script command (word): the segment's time in main-loop passes into $B23C
;
; Every segment starts with it: $7F (127) passes, 63 or 64 in the short point
; segments before a sector end. Witness: as SegmentEnd: i1 31, i2 34.
SegmentLength:
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (SegmentWait),BC
  RET

; Script command (delay, point): appends the point object ObjPoint and prints
; the coming point's letter at the bottom right
;
; Record: $9978, the delay, the point byte (bits 0-4 the point number, bit 5
; the Champion course). Prints TextPointAt $97A7 (x $F9 y $B1, font 2) and the
; letter (the code of HudPrintPointLetter inlined), then inverts the cell at
; $50DF (row 22, column 31): the letter shows in reverse until ObjPoint passes
; it. The delay is $3F (63), or $3E in the segment before a sector end.
;
; Witness: game 2 runs (8345-16173), g1 2, h1 2, i1 25 (A 1123 ... Z 28136:
; every Beginner point), i2 28 (the 25 Champion points and A-C of Beginner
; after the loop).
CmdPoint:
  EX DE,HL
  LD A,(DE)
  INC DE
  LD BC,ObjPoint
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  LD A,(DE)
  INC DE
  LD (HL),A
  INC HL
  EX DE,HL
  PUSH HL
  PUSH AF
  LD HL,TextPointAt
  CALL PrintText
  POP AF
  AND $1F
  CP $0F
  CCF
  ADC A,$40
  CALL PrintChar
  LD HL,Screen+4319
  LD B,$08
CmdPointInvert:
  LD A,(HL)
  XOR $7F
  LD (HL),A
  INC H
  DJNZ CmdPointInvert
  POP HL
  RET

; Print string: AT x $F9 y $B1, font 2 (CmdPoint prints the point letter after
; it)
TextPointAt:
  INCBIN "res/text/TextPointAt.bin",$0000,6

; Script command (delay, value pairs to $FF): appends warning-lamp objects
; ObjLamps
;
; Record: $99A3, the delay, the lamp value (0-3, HudLamps). Each point segment
; sets the lamps for what follows: 1 (CAUTION) with the UFO waves, 2 (DANGER!)
; with the CmdUfos11 waves and the boulders of Champion C and M, 3 with the low
; flyers from behind (Champion A, the segment after sector end P, Z) and a few
; mixed points (Beginner Y, Champion S, Y), 0 (all clear) in most points before
; a sector end (Beginner E, I, P, U; Champion E, J, P). Witness: game 2, g1 2,
; h1 2, i1 21, i2 27.
CmdLamps:
  EX DE,HL
CmdLampsLoop:
  LD A,(DE)
  INC DE
  CP $FF
  JR Z,CmdLampsDone
  LD BC,ObjLamps
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  LD A,(DE)
  LD (HL),A
  INC DE
  INC HL
  JR CmdLampsLoop
CmdLampsDone:
  EX DE,HL
  RET

; Script command (a delay a rock to $FF): appends rock objects ObjRock
;
; Record (8 bytes): $99C3, the delay, sprite $0F, y $94, x $F4 (off the right
; edge: not drawn yet), height $0C, width $0C. Witness: game 20 runs
; (1559-16323), a1 3, g1 4, p2 8, h1 4, i1 13 (first 263: the start segment,
; two rocks), i2 16.
CmdRocks:
  EX DE,HL
CmdRocksLoop:
  LD A,(DE)
  INC DE
  CP $FF
  JR Z,CmdRocksDone
  LD BC,ObjRock
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  LD (HL),$0F
  INC HL
  LD (HL),$94
  INC HL
  LD (HL),$F4
  INC HL
  LD (HL),$0C
  INC HL
  LD (HL),$0C
  INC HL
  JR CmdRocksLoop
CmdRocksDone:
  EX DE,HL
  RET

; Script command (a delay a crater to $FF): appends crater objects ObjCrater
;
; Record (4 bytes): $9A92, the delay, x 0 (the right edge, before the first
; move). Witness: game 20 runs, a1 3, g1 4, p2 8, h1 4, i1 16 (first 263), i2
; 9.
CmdCraters:
  EX DE,HL
CmdCratersLoop:
  LD A,(DE)
  INC DE
  CP $FF
  JR Z,CmdCratersDone
  LD BC,ObjCrater
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  LD (HL),$00
  INC HL
  JR CmdCratersLoop
CmdCratersDone:
  EX DE,HL
  RET

; Script command (a byte a mine to $FF: bits 0-6 the delay, bit 7 the blink
; phase): appends mine objects ObjMine
;
; Record (6 bytes): $9AEB, the delay, the phase ($00 or $80; the sprite goes in
; its low bits), y $A0, x $F8 (not drawn yet). Witness: i1 3 runs (11800-13545:
; the segment after sector end J, K, L), i2 5 (12337-28217); no other recording
; reaches the mines.
CmdMines:
  EX DE,HL
CmdMinesLoop:
  LD A,(DE)
  INC DE
  CP $FF
  JR Z,CmdMinesDone
  LD BC,ObjMine
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD C,A
  AND $7F
  LD (HL),A
  INC HL
  LD A,C
  AND $80
  LD (HL),A
  INC HL
  LD (HL),$A0
  INC HL
  LD (HL),$F8
  INC HL
  JR CmdMinesLoop
CmdMinesDone:
  EX DE,HL
  RET

; Script command (a delay a UFO to $FF): UFO objects of type 1 ($9B6B), any
; height
;
; A' = 1 the type, $B236 = 0; on at CmdUfos $9832. Witness: game 2, g1 2, h1 2,
; i1 10, i2 10.
CmdUfos1:
  XOR A
  EX AF,AF'
  LD A,$01
  JR CmdUfos

; Script command: UFO objects of type 5 ($9B6B), any height
;
; Witness: game 2, g1 2, h1 2, i1 10, i2 10.
CmdUfos5:
  XOR A
  EX AF,AF'
  LD A,$05
  JR CmdUfos

; Script command: UFO objects of type $0B ($9B6B), $B236 = $FF: start no lower
; than y $30, bit 3 in field +9
;
; Witness: i1 6 (3828-27176: points D, H, M, T, X, Y), i2 7. The lamp set with
; these waves is 2 (DANGER!) at D, H, M, T, X; Y sets 3.
CmdUfos11:
  LD A,$FF
  EX AF,AF'
  LD A,$0B

; The UFO spawner: a 20-byte record per data byte, $9B6B with the type, a
; random start side and height
;
; Record: +0 $9B6B, +2 the delay, +3 the type, +4 $FF, +5 0, +6 dx (+2 from the
; left, -2 from the right), +7 y = (R XOR FRAMES) AND $1F + $18 (capped to $30
; for CmdUfos11), +8 x = 0 or $F0 (bit 6 of R XOR FRAMES), +9 8 or $10 ($B236
; AND 8 + 8), +10 $0F, +11 R AND $1F + $10, +12 $1D, +13 $FF, +14 4, +15 4, +18
; 5, +19 5 (+16, +17 not written). What the handler $9B6B makes of the fields
; from +9 on is annotator 03's.
;
; Witness: game 4 runs, g1 4, h1 4, i1 26, i2 27; the cap to y $30 ($9868) i1
; 2, i2 6.
CmdUfos:
  EX AF,AF'
  LD (UfoWave),A
  EX DE,HL
CmdUfosLoop:
  LD A,(DE)
  INC DE
  CP $FF
  JR Z,CmdUfosDone
  LD BC,UfoHandler
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  EX AF,AF'
  LD (HL),A
  EX AF,AF'
  INC HL
  LD (HL),$FF
  INC HL
  LD (HL),$00
  INC HL
  INC HL
  LD A,R
  LD B,A
  LD A,(FRAMES)
  LD C,A
  XOR B
  AND $1F
  ADD A,$18
  LD (HL),A
  CP $30
  JR C,CmdUfosSide
  LD A,(UfoWave)
  AND A
  JR Z,CmdUfosSide
  LD (HL),$30
CmdUfosSide:
  INC HL                  ; the start side from bit 6 of R XOR FRAMES
  LD A,B
  XOR C
  BIT 6,A
  LD A,$F0
  LD C,$FE
  JR NZ,CmdUfosFields
  XOR A
  LD C,$02
CmdUfosFields:
  LD (HL),A
  DEC HL
  DEC HL
  LD (HL),C
  INC HL
  INC HL
  INC HL
  LD A,(UfoWave)
  AND $08
  ADD A,$08
  LD (HL),A
  INC HL
  LD (HL),$0F
  INC HL
  LD A,B
  AND $1F
  ADD A,$10
  LD (HL),A
  INC HL
  LD (HL),$1D
  INC HL
  LD (HL),$FF
  INC HL
  LD (HL),$04
  INC HL
  LD (HL),$04
  INC HL
  INC HL
  INC HL
  LD (HL),$05
  INC HL
  LD (HL),$05
  INC HL
  JR CmdUfosLoop
CmdUfosDone:
  EX DE,HL
  RET

; Script command (a delay to $FF): appends $9EA5, which sets $B237 when its
; delay is out: the UFOs fly off
;
; Record (3 bytes): $9EA5, the delay. $9EA5 (annotator 03) sets $B237 = $FF;
; the UFO handler $9B6B then moves each UFO 4 pixels a pass to the nearer edge
; and removes it off screen ($9BE6), and a new wave clears $B237 ($9B99). In
; the script it comes after each UFO part of the course (points C, E, H, I, P,
; U, Y, Z of Beginner). Witness: i1 8 runs (2935-28136), i2 11.
CmdUfosLeave:
  EX DE,HL
CmdUfosLeaveLoop:
  LD A,(DE)
  INC DE
  CP $FF
  JR Z,CmdUfosLeaveDone
  LD BC,UfoRetreatTimer
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  JR CmdUfosLeaveLoop
CmdUfosLeaveDone:
  EX DE,HL
  RET

; Script command (a delay to $FF): appends tank objects $9EBD (15 bytes)
;
; Record: $9EBD, the delay, $13, $8F, $E7, $11, $14, $08, $00, $93, $C1, $03,
; $07: by the shape the tank's sprite $13, y $8F, x $E7, box $11 x $14, then a
; second sprite / box (y $93, x $C1, 3 x 7: its shell); the handler is
; annotator 03's (scores 250 / 200). Witness: i1 4 runs (23662-27176: the
; segment after sector end U, points V, W, Y), i2 9.
CmdTanks:
  EX DE,HL
CmdTanksLoop:
  LD A,(DE)
  INC DE
  CP $FF
  JR Z,CmdTanksDone
  LD BC,TankHandler
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  LD (HL),$13
  INC HL
  LD (HL),$8F
  INC HL
  LD (HL),$E7
  INC HL
  LD (HL),$11
  INC HL
  LD (HL),$14
  INC HL
  LD (HL),$08
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$93
  INC HL
  LD (HL),$C1
  INC HL
  LD (HL),$03
  INC HL
  LD (HL),$07
  INC HL
  JR CmdTanksLoop
CmdTanksDone:
  EX DE,HL
  RET

; Script command (a delay to $FF): appends low flyer objects $A03B (Champion
; only)
;
; Record (9 bytes): $A03B, the delay, $14, (+4 not written), y $91, x 0 (from
; the left: behind the buggy), $08, $0C. Witness: i2 3 runs (1352-29178:
; Champion A, the sector after P, Z).
CmdFlyers:
  EX DE,HL
CmdFlyersLoop:
  LD A,(DE)
  INC DE
  CP $FF
  JR Z,CmdFlyersDone
  LD BC,LowFlyerHandler
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  LD (HL),$14
  INC HL
  INC HL
  LD (HL),$91
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$08
  INC HL
  LD (HL),$0C
  INC HL
  JR CmdFlyersLoop
CmdFlyersDone:
  EX DE,HL
  RET

; Script command: small boulders (sprite $40, 8x8) for $A196
;
; Witness: i2 3 runs (3117-28218).
CmdBoulders40:
  EX AF,AF'
  LD A,$40
  JR CmdBoulders

; Script command: medium boulders (sprite $44, 12x12)
;
; Witness: i2 5 runs.
CmdBoulders44:
  EX AF,AF'
  LD A,$44
  JR CmdBoulders

; Script command: big boulders (sprite $4C, 16x16)
;
; Witness: i2 5 runs.
CmdBoulders4C:
  EX AF,AF'
  LD A,$4C

; The boulder spawner: an 8-byte record per data byte, $A196 with the sprite,
; y, x and the size
;
; Size s = sprite - $38 (- 4 more for $4C): 8, 12, 16. Record: $A196, the
; delay, the sprite, y = $A0 - s, x = -s (enters from the right edge), height
; s, width s. Scores in $A196 (annotator 03): 100 / 150 / 200 shot. Witness: i2
; 13 runs (3117-28218); Champion only.
CmdBoulders:
  EX AF,AF'
  EX DE,HL
CmdBouldersLoop:
  LD A,(DE)
  INC DE
  CP $FF
  JR Z,CmdBouldersDone
  LD BC,BoulderHandler
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  EX AF,AF'
  LD (HL),A
  LD B,A
  EX AF,AF'
  LD A,B
  CP $4C
  JR NZ,CmdBouldersSize
  SUB $04
CmdBouldersSize:
  SUB $38
  LD B,A
  INC HL
  LD A,$A0
  SUB B
  LD (HL),A
  INC HL
  XOR A
  SUB B
  LD (HL),A
  INC HL
  LD (HL),B
  INC HL
  LD (HL),B
  INC HL
  JR CmdBouldersLoop
CmdBouldersDone:
  EX DE,HL
  RET

; Script command (a delay to $FF): appends green plant objects $A2C6 (Champion
; only)
;
; Record (8 bytes): $A2C6, the delay, 0, y $90, x $E4, 0, 0. Witness: i2 8 runs
; (4011-28218).
CmdPlants:
  EX DE,HL
CmdPlantsLoop:
  LD A,(DE)
  INC DE
  CP $FF
  JR Z,CmdPlantsDone
  LD BC,PlantHandler
  LD (HL),C
  INC HL
  LD (HL),B
  INC HL
  LD (HL),A
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$90
  INC HL
  LD (HL),$E4
  INC HL
  LD (HL),$00
  INC HL
  LD (HL),$00
  INC HL
  JR CmdPlantsLoop
CmdPlantsDone:
  EX DE,HL
  RET

; Object: a point passed when the delay is out: $B27C, the restart point, the
; HUD
;
; HL = the delay. When out: $B27C = the point byte, the restart pointer $B27F =
; $B281 (the start of the segment that holds the point: a death restarts
; there), HudPrintPoint $9247, HudProgress $92AA, HudPrintScore $92DA; then its
; word becomes ObjPointDone. Witness: game 11 runs, g1 51, h1 51, i1 1595;
; points passed ($9980) i1 25, i2 27.
ObjPoint:
  LD A,(HL)
  AND A
  JR Z,ObjPointPassed
  DEC A
  LD (HL),A
  JR ObjPointDone
ObjPointPassed:
  INC HL
  LD A,(HL)
  LD (PlayerPoint),A
  PUSH HL
  LD HL,(PlayerSegment)
  LD (PlayerRestart),HL
  CALL HudPrintPoint
  CALL HudProgress
  CALL HudPrintScore
  POP HL
  DEC HL
  DEC HL
  LD BC,ObjPointDone
  LD (HL),B
  DEC HL
  LD (HL),C
  INC HL
  INC HL

; Object skip: past a 4-byte record (the delay and one byte); the end of
; ObjPoint
;
; Witness: i1 7930 runs (1595 entries from ObjPoint's word), i2 8495.
ObjPointDone:
  INC HL
  INC HL
  RET

; Object: sets the warning lamps when the delay is out ($B27E = value AND 3,
; HudLamps)
;
; The unmatched handler of stage 1: no enemy, the HUD's three lamps (HudLamps
; $927E) set at the course's own times. Then its word becomes ObjLampsDone.
; Witness: game 11 runs, g1 51, h1 51, i1 885, i2 841; set ($99AB) i1 24, i2
; 29.
ObjLamps:
  LD A,(HL)
  AND A
  JR Z,ObjLampsSet
  DEC A
  LD (HL),A
  JR ObjLampsDone
ObjLampsSet:
  PUSH HL
  INC HL
  LD A,(HL)
  AND $03
  LD (PlayerLights),A
  CALL HudLamps
  POP HL
  DEC HL
  LD BC,ObjLampsDone
  LD (HL),B
  DEC HL
  LD (HL),C
  INC HL
  INC HL

; Object skip: past a 4-byte record; the end of ObjLamps
;
; Witness: i1 7278 runs, i2 10082.
ObjLampsDone:
  INC HL
  INC HL
  RET

; Object: a rock on the ground, moving with the scroll; kills the buggy on
; contact, 100 when shot or hit, 80 jumped
;
; When the delay is out, each pass: erases the sprite at its old place (not on
; the first pass, x $F4), moves x left by the scroll step $B235 while the buggy
; is alive (x 0: removed, ObjRockRemove), then tests its box (y $94, x, 12 x
; 12) against the buggy's ($B212, $A7FE): contact calls the kill $A7DD and the
; rock explodes (ObjRockHit). Else against the forward shot at $5B60: a hit
; removes the shot ($5B62 = $FF) and the rock explodes. ObjRockHit: the sprite
; $2A, the word ObjRockExplode, 100 points (ScoreAdd), $B26F = 0. Else when the
; buggy's x AND $FC equals the rock's x: 80 points (jumped). Then drawn at the
; new place (sprite $0F through $AF74 / $A826).
;
; The rock of the SCORE ADVANCE TABLE (100 / 80) and of NOTES' candidate 97C5:
; the script's rocks start at i1 263 (two in the start segment), seen at i1
; 1200. Witness: game 3060 runs, a1 374, g1 871, p2 1296, h1 871, i1 3080, i2
; 4289, h2 72. Contact ($99F9): game 1, g1 4, i1 17 (immune: the kill is a RET,
; the rock still explodes); shot ($9A0B): game 1, i2 1; jumped ($9A37): game 1,
; g1 2, i1 10, i2 11.
ObjRock:
  LD A,(HL)
  AND A
  JR Z,ObjRockActive
  DEC A
  LD (HL),A
  JP ObjRockDone
ObjRockActive:
  PUSH HL                 ; the old place erased, unless still at x $F4
  INC HL
  LD C,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,D
  CP $F4
  JR Z,ObjRockMove
  LD A,C
  EX DE,HL
  CALL DrawSprite
  EX DE,HL
ObjRockMove:
  LD A,(DeathStep)        ; x - the scroll step while the buggy is alive; 0:
                          ; gone
  INC A
  JR NZ,ObjRockTest
  LD A,(GroundSpeed)
  NEG
  ADD A,(HL)
  LD (HL),A
  JP Z,ObjRockRemove
ObjRockTest:
  DEC HL                  ; the box against the buggy's
  EXX
  LD HL,BuggyY
  EXX
  CALL BoxOverlap
  JR C,ObjRockShotTest
  CALL BuggyKill
  JR ObjRockHit
ObjRockShotTest:
  DEC HL                  ; the box against the forward shot
  DEC HL
  DEC HL
  EXX
  LD HL,ShotForward
  EXX
  CALL BoxOverlap
  JR C,ObjRockMiss
  LD A,$FF
  LD (ShotForward+2),A
ObjRockHit:
  LD DE,-$0004            ; explodes: sprite $2A, the explosion handler, 100
                          ; points
  ADD HL,DE
  LD (HL),$2A
  DEC HL
  DEC HL
  LD DE,ObjRockExplode
  LD (HL),D
  DEC HL
  LD (HL),E
  LD DE,$0000
  LD BC,$0100
  CALL ScoreAdd
  XOR A
  LD (RockSeen),A
  JR ObjRockHitDone
ObjRockMiss:
  DEC HL                  ; jumped over: 80 points
  DEC HL
  LD A,(BuggyX)
  AND $FC
  CP (HL)
  JR NZ,ObjRockDraw
  LD DE,$0000
  LD BC,$0080
  PUSH HL
  CALL ScoreAdd
  POP HL
ObjRockDraw:
  LD D,(HL)
  DEC HL
  LD E,(HL)
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DE)
  CALL DrawSprite
  JR ObjRockNext
ObjRockHitDone:
  POP HL

; Object: a rock's explosion: sprites $2B-$2E moving with the ground, then
; removed
;
; Erases the previous frame (none after $2A), moves with the scroll while the
; buggy is alive, the next sprite; at $2F the record is removed
; (ObjRockRemove). Entered from ObjRockHit in the same pass and then by its
; word. Witness: game 10 runs, a1 5, g1 20, p2 20, h1 20, i1 85, i2 140, h2 5
; (about 4-5 passes an explosion).
ObjRockExplode:
  PUSH HL
  INC HL
  LD A,(HL)
  INC HL
  LD E,(HL)
  INC HL
  CP $2A
  JR Z,ObjRockExplodeMove
  LD D,(HL)
  EX DE,HL
  CALL DrawSprite
  EX DE,HL
ObjRockExplodeMove:
  LD A,(DeathStep)
  INC A
  JR NZ,ObjRockExplodeNext
  LD A,(GroundSpeed)
  NEG
  ADD A,(HL)
  LD (HL),A
ObjRockExplodeNext:
  LD D,(HL)
  DEC HL
  LD E,(HL)
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(DE)
  INC A
  LD (DE),A
  CP $2F
  JR NC,ObjRockRemove
  CALL DrawSprite

; The end of a rock pass: HL back to the record
;
; Reached by a jump from ObjRockMiss and by falling in from ObjRockExplode; an
; entry of the cut (the L1 builds record it as a routine entry). Witness: game
; 534, a1 62, g1 273, p2 244, h1 273, i1 1171, i2 1638, h2 35.
ObjRockNext:
  POP HL

; Object skip: past an 8-byte record (6 bytes after the delay); a rock's
; handler at its end
;
; Witness: i1 12370 runs, i2 13379.
ObjRockDone:
  LD BC,$0006
  ADD HL,BC
  RET

; A rock or its explosion removed: its word becomes ObjRockDone
;
; Witness: game 3 runs, a1 1, g1 6, p2 4, h1 6, i1 25, i2 37.
ObjRockRemove:
  POP HL
  DEC HL
  LD DE,ObjRockDone
  LD (HL),D
  DEC HL
  LD (HL),E
  INC HL
  INC HL
  JR ObjRockDone

; Object: a crater fed into the scrolling ground at the right edge; 100 when
; jumped
;
; No sprite: while the crater's x is above $EC (its first passes after the
; right edge) the ground pattern pointer $B232 points at the crater's columns
; ($A9CF or $A9EF, by bit 3 of x), at x $EC back to the plain ground $A9AF; the
; ground scroller $A932 copies from it. Then, as the crater moves left with the
; scroll ($B235, while the buggy is alive), the buggy's x AND $FC equal to its
; x scores 100 (jumped); at x 0 it is removed (its word ObjCraterDone). No
; contact test here: the buggy's fall into the crater is found elsewhere (the
; ground).
;
; The crater of the SCORE ADVANCE TABLE (100 jumped) and of NOTES' candidate
; 97E8: first i1 263, seen at i1 450. Witness: game 3039 runs, a1 371, g1 812,
; p2 1288, h1 812, i1 5432, i2 2857, h2 66; the crater columns ($9AB9) i1 148;
; jumped ($9AD2) game 3, a1 1, g1 6, p2 4, h1 6, i1 43, i2 28.
ObjCrater:
  LD A,(HL)
  AND A
  JR Z,ObjCraterActive
  DEC A
  LD (HL),A
  JR ObjCraterDone
ObjCraterActive:
  PUSH HL
  LD A,(DeathStep)
  INC A
  JR NZ,ObjCraterNext
  INC HL
  LD A,(GroundSpeed)
  NEG
  ADD A,(HL)
  LD (HL),A
  JR Z,ObjCraterRemove
  CP $EC
  JR C,ObjCraterJump
  JR NZ,ObjCraterColumns
  LD HL,RoadFeed
  LD (GroundProfile),HL
  JR ObjCraterNext
ObjCraterColumns:
  CPL                     ; the crater's columns: $A9CF or $A9EF by bit 3 of x
  AND $08
  RLCA
  RLCA
  LD D,$00
  LD E,A
  LD HL,RoadFeedWallA
  ADD HL,DE
  LD (GroundProfile),HL
  JR ObjCraterNext
ObjCraterJump:
  LD A,(BuggyX)           ; the buggy over it: 100 points
  AND $FC
  CP (HL)
  JR NZ,ObjCraterNext
  LD DE,$0000
  LD BC,$0100
  CALL ScoreAdd
ObjCraterNext:
  POP HL

; Object skip: past a 4-byte record; the end of ObjCrater
;
; Witness: i1 18646 runs, i2 10593.
ObjCraterDone:
  INC HL
  INC HL
  RET
; This entry point is used by the routine at ObjCrater.
ObjCraterRemove:
  POP HL                  ; gone at x 0: the word becomes ObjCraterDone
  DEC HL
  LD DE,ObjCraterDone
  LD (HL),D
  DEC HL
  LD (HL),E
  INC HL
  INC HL
  JR ObjCraterDone

; Object: a blinking mine on the ground; 50 when jumped
;
; On the first pass (x $F8) it clears 10 pixels of the line y $A0 at x $F6-$FF
; ($A7F4, $FD99) and sets $B288 bit 3, which the ground routine reads once and
; clears ($A994); later passes erase the sprite. Moves left with the scroll
; while the buggy is alive (x 0: removed, ObjMineRemove); the buggy's x AND $FC
; equal to its x scores 50 (jumped). Then the sprite $11 / $12 by bit 2 of the
; pass counter $B23B XOR the record's phase bit, drawn at y $A0. No contact
; test here.
;
; The mines of the SCORE ADVANCE TABLE (50) and of NOTES: only in the segments
; after sector end J and at K, L (Beginner: 18 mines), and in Champion after
; sector end J and at K, L, V, Y. Witness: i1 2298 runs (11801-14790), i2 4455
; (12338-28908); first passes ($9B09) i1 18, i2 35; jumped ($9B2F) i1 17, i2
; 34.
ObjMine:
  LD A,(HL)
  AND A
  JR Z,ObjMineActive
  DEC A
  LD (HL),A
  JR ObjMineDone
ObjMineActive:
  PUSH HL
  INC HL
  LD C,(HL)
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,D
  CP $F8
  JR Z,ObjMineEnter
  LD A,C
  AND $7F
  EX DE,HL
  CALL DrawSprite
  EX DE,HL
  JR ObjMineMove
ObjMineEnter:
  PUSH HL                 ; the first pass: 10 ground pixels cleared, $B288 bit
                          ; 3
  LD HL,$F6A0
  LD E,$0A
  CALL UnplotRun
  LD HL,PlayerFlags
  SET 3,(HL)
  POP HL
ObjMineMove:
  LD A,(DeathStep)
  INC A
  JR NZ,ObjMineDraw
  LD A,(GroundSpeed)
  NEG
  ADD A,(HL)
  LD (HL),A
  JR Z,ObjMineRemove
  LD A,(BuggyX)
  AND $FC
  CP (HL)
  JR NZ,ObjMineDraw
  LD DE,$0000
  LD BC,$0050
  PUSH HL
  CALL ScoreAdd
  POP HL
ObjMineDraw:
  LD D,(HL)               ; the sprite $11 or $12: the blink
  DEC HL
  LD E,(HL)
  DEC HL
  EX DE,HL
  CALL ScrollAdjustIfAlive
  LD A,(PassCount)
  AND $04
  RRCA
  RRCA
  LD C,A
  LD A,(DE)
  AND $80
  LD B,A
  RLCA
  XOR C
  ADD A,$11
  OR B
  LD (DE),A
  AND $7F
  CALL DrawSprite
  POP HL

; Object skip: past a 6-byte record; the end of ObjMine
;
; Witness: i1 10169 runs, i2 19731.
ObjMineDone:
  LD BC,$0004
  ADD HL,BC
  RET
; This entry point is used by the routine at ObjMine.
ObjMineRemove:
  POP HL                  ; gone at x 0: the word becomes ObjMineDone
  DEC HL
  LD BC,ObjMineDone
  LD (HL),B
  DEC HL
  LD (HL),C
  INC HL
  INC HL
  JR ObjMineDone
