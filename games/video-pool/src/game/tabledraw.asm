; --------------------------------------------------------------------------------------------------------------------
; tabledraw.asm: The table, the power bar and its box, the aiming cursor, the XOR line
;
; Everything here is drawn with one primitive, XorLine $93B3: a horizontal run of B pixels from (x E, y D), XORed onto
; the screen, so drawing a figure twice erases it. The power bar and the cursor are redrawn every frame by the aim
; list's tasks; the table and the power box once per game (NewGameScreen $95DA) and once per editor visit ($C042).
;
; No aim line exists: the aim is the cursor itself, a 5 x 5 cross that runs round the cushion line (x 3..252, y
; 51..180); the cue ball and the object balls are sprites (balldraw).
; --------------------------------------------------------------------------------------------------------------------

; Draw the table: the outer frame and the six cushions, with gaps for the six
; pockets
;
; Called by NewGameScreen $95DA and the editor $C042, once each (game 1 at
; frame 6186, w1 1 at 626, v1 2, m1 2). Every run is a call of XorLine $93B3
; with D = y, E = x, B = length.
;
; The frame: the top line y 48 and the bottom line y 183, x 0-255 (two runs of
; 128 each); the left edge x 0 and the right edge x 255, y 49-182 (134
; one-pixel runs each).
;
; The four long cushions, 9 lines each, sloped at 45 degrees on their pocket
; side: top left y 49-57 from x 15+i to 117, top right from x 138 to 240-i (i =
; 0..8 the line); bottom left and bottom right the same mirrored, y 182 up to
; 174. The two side cushions: x 1-9 at the left and x 246-254 at the right, a
; 9-line slope in (y 63-71, run 1..9), 88 straight lines (y 72-159), a 9-line
; slope out (y 160-168).
;
; Large pockets ($B8BC <> 0, the menu's L key; the default in the image): the
; long cushions start 4 pixels later and run 96 pixels (x 19+i..114,
; 141..236-i), the side cushions start at y 67 and run 80 straight lines. Small
; pockets ($B8BC = 0, the S key, m1 frame 7110): the numbers above. The gaps
; left are the pockets: the four corners and the middle of the top and bottom
; (x 118-137 small, 115-140 large).
DrawTable:
  LD DE,$3000
  LD B,$80
  CALL XorLine
  LD E,B
  CALL XorLine
  LD DE,$310F
  LD B,$67
  LD C,$09
  LD A,(Pockets)
  OR A
  JR Z,TableTopLeft
  LD E,$13
  LD B,$60
TableTopLeft:
  CALL XorLine            ; top left cushion: x+1, y+1, length-1 a line
  INC D
  INC E
  DEC B
  DEC C
  JR NZ,TableTopLeft
  LD DE,$318A
  LD B,$67
  LD C,$09
  LD A,(Pockets)
  OR A
  JR Z,TableTopRight
  LD E,$8D
  LD B,$60
TableTopRight:
  CALL XorLine            ; top right cushion: y+1, length-1
  INC D
  DEC B
  DEC C
  JR NZ,TableTopRight
  LD DE,$B700             ; y 183, x 0: the bottom line (a y/x pair, not an
                          ; address)
  LD B,$80
  CALL XorLine
  LD E,B
  CALL XorLine
  LD DE,$B60F             ; y 182, x 15: the bottom left cushion, going up
  LD B,$67
  LD C,$09
  LD A,(Pockets)
  OR A
  JR Z,TableBottomLeft
  LD E,$13
  LD B,$60
TableBottomLeft:
  CALL XorLine            ; bottom left cushion: y-1, x+1, length-1
  DEC D
  INC E
  DEC B
  DEC C
  JR NZ,TableBottomLeft
  LD DE,$B68A             ; y 182, x 138: the bottom right cushion, going up
  LD B,$67
  LD C,$09
  LD A,(Pockets)
  OR A
  JR Z,TableBottomRight
  LD E,$8D
  LD B,$60
TableBottomRight:
  CALL XorLine            ; bottom right cushion: y-1, length-1
  DEC D
  DEC B
  DEC C
  JR NZ,TableBottomRight
  LD DE,$3100
  LD B,$01
  LD C,$86
TableLeftEdge:
  CALL XorLine            ; the left edge, x 0, y 49-182
  INC D
  DEC C
  JR NZ,TableLeftEdge
  LD DE,$3F01             ; y 63, x 1
  LD B,$01
  LD C,$09
  LD A,(Pockets)
  OR A
  JR Z,TableLeftSlopeIn
  LD D,$43
TableLeftSlopeIn:
  CALL XorLine            ; left cushion: run 1..9 from x 1, y 63 (67 large)
  INC D
  INC B
  DEC C
  JR NZ,TableLeftSlopeIn
  LD B,$09
  LD C,$58
  LD A,(Pockets)
  OR A
  JR Z,TableLeftStraight
  LD C,$50
TableLeftStraight:
  CALL XorLine            ; 88 lines (80 large) of 9 pixels
  INC D
  DEC C
  JR NZ,TableLeftStraight
  LD B,$09
  LD C,$09
TableLeftSlopeOut:
  CALL XorLine            ; run 9..1
  INC D
  DEC B
  DEC C
  JR NZ,TableLeftSlopeOut
  LD DE,$31FF
  LD B,$01
  LD C,$86
TableRightEdge:
  CALL XorLine            ; the right edge, x 255
  INC D
  DEC C
  JR NZ,TableRightEdge
  LD DE,$3FFE             ; y 63, x 254
  LD B,$01
  LD C,$09
  LD A,(Pockets)
  OR A
  JR Z,TableRightSlopeIn
  LD D,$43
TableRightSlopeIn:
  CALL XorLine            ; right cushion: x-1, run+1 from x 254
  INC D
  DEC E
  INC B
  DEC C
  JR NZ,TableRightSlopeIn
  INC E
  LD B,$09
  LD C,$58
  LD A,(Pockets)
  OR A
  JR Z,TableRightStraight
  LD C,$50
TableRightStraight:
  CALL XorLine            ; 88 / 80 lines of x 246-254
  INC D
  DEC C
  JR NZ,TableRightStraight
  LD B,$09
  LD C,$09
TableRightSlopeOut:
  CALL XorLine            ; x+1, run-1
  INC D
  INC E
  DEC B
  DEC C
  JR NZ,TableRightSlopeOut
  RET

; The aim list's power bar task: erase the bar drawn last frame, draw the bar
; for the power now
;
; A task of the aim list $84AA, period 0 (every interrupt while aiming): game
; 1443 runs, w1 4404, f1 2035, p2 1369, v1 846, m1 316 (also the editor's list
; $C518). $86BF is the power (grown by $8506 while fire is held), $86C0 the
; length drawn last time: DrawPowerBar $935C with B = $86C0 (XOR: erases), then
; with B = $86BF (draws), then $86C0 = $86BF. A power of 0 draws nothing
; (XorLine returns on B = 0).
PowerBarTask:
  LD HL,(Power)
  LD B,H
  CALL DrawPowerBar
  LD HL,(Power)
  LD B,L
  LD H,L
  LD (Power),HL

; XOR the power bar: 4 lines of B pixels (capped at 126) from x 4, y 10-13
;
; Input B = the length. Lengths of 128 and more are drawn as 126 (the power
; runs 0..$84, so the last three steps $80, $82, $84 look full). The bar lies
; inside PowerBox $9395 (x 2-131, y 8-15). Called by PowerBarTask $934D twice a
; frame (game 2893) and by $8539, which erases the bar and zeroes the power at
; each new aim.
DrawPowerBar:
  LD DE,$0A04
  LD C,$04
  LD A,B
  CP $80
  JR C,PowerBarLength
  LD A,$7E
PowerBarLength:
  LD B,A
PowerBarLine:
  CALL XorLine
  INC D
  DEC C
  JR NZ,PowerBarLine
  RET

; XOR the aiming cursor at ($86BA x, $86BB y): a cross of four 2-pixel arms,
; the centre left clear
;
; Pixels: (x+1, x+2 at y), (x-2, x-1 at y), (x at y-2, y-1, y+1, y+2); the
; centre (x, y) is never set, so the point aimed at stays visible. Drawn twice
; it erases: the cursor tasks $85EB (draw, move, draw), $8506 (erase on the
; shot), $85C8 (first draw at a new aim, x 252, y 114-116 at random) and the
; editor ($C042, $C116, $C20B, $C414, $C502, $C532). Counts: game 388, w1 1930,
; f1 122, p2 43, v1 46, m1 244.
DrawCursor:
  LD DE,(CursorX)
  INC E
  LD B,$02
  CALL XorLine
  DEC E
  DEC E
  DEC E
  CALL XorLine
  INC E
  INC E
  DEC D
  DEC D
  DEC B
  CALL XorLine
  INC D
  CALL XorLine
  INC D
  INC D
  CALL XorLine
  INC D
  JR XorLine

; Draw the power bar's box: a rectangle x 2-131, y 8-15
;
; The top y 8 and the bottom y 15, 130 pixels from x 2; the sides one pixel at
; x 2 and x 131 for y 9-14. Once a game (NewGameScreen $95DA, game 1 at frame
; 6185) and in the editor ($C414, v1 2).
DrawPowerBox:
  LD DE,$0802
  LD B,$82
  CALL XorLine
  LD BC,$0106
PowerBoxSides:
  INC D
  LD E,$02
  CALL XorLine
  LD E,$83
  CALL XorLine
  DEC C
  JR NZ,PowerBoxSides
  LD DE,$0F02
  LD B,$82

; XOR a horizontal run of B pixels starting at (x E, y D) onto the screen; B =
; 0 draws nothing
;
; Inputs D = y, E = x, B = length in pixels (up to 255). Keeps BC, DE; HL and A
; spoiled. The address: ScreenCell $95B3 of (y, x) plus y AND 7 in the high
; byte. The first byte's mask: B ones from bit 7 (or $FF when B >= 8), shifted
; right by x AND 7, the bits shifted out counted back into B; then whole bytes
; XOR $FF while 8 or more remain, then a last mask of the remaining B bits from
; the left. The run must not cross a byte column 31 boundary (INC HL).
;
; The busiest drawing routine: game 14976 calls, w1 57235, f1 17840, p2 12040,
; v1 8432, m1 28297; callers also outside this range ($A95A, $A990, $AB7B hall
; of fame, $B047, $B101, $B89C menu, $BC11 attract, $C1BE editor).
XorLine:
  LD A,B
  OR A
  RET Z
  PUSH BC
  LD H,D
  LD L,E
  CALL ScreenCell
  LD A,D
  AND $07
  ADD A,H
  LD H,A
  LD A,B
  SUB $08
  JR NC,XorLineFullMask
  LD C,$00
XorLineShortMask:
  SCF                     ; B < 8: C = B ones from the left
  RR C
  DJNZ XorLineShortMask
  JR XorLineShift
XorLineFullMask:
  LD B,A                  ; B >= 8: C = $FF, B = the pixels after it
  LD C,$FF
XorLineShift:
  LD A,E
  AND $07
  JR Z,XorLineFirst
XorLineShiftLoop:
  SRL C                   ; shift the mask right by x AND 7, counting the lost
                          ; bits back into B
  JR NC,XorLineShiftNext
  INC B
XorLineShiftNext:
  DEC A
  JR NZ,XorLineShiftLoop
XorLineFirst:
  LD A,(HL)               ; XOR the first byte
  XOR C
  LD (HL),A
  INC HL
XorLineBytes:
  LD A,B                  ; whole bytes
  OR A
  JR Z,XorLineDone
  SUB $08
  JR C,XorLineLast
  LD B,A
  LD A,(HL)
  XOR $FF
  LD (HL),A
  INC HL
  JR XorLineBytes
XorLineLast:
  LD C,$00                ; the last partial byte
XorLineLastMask:
  SCF
  RR C
  DJNZ XorLineLastMask
  LD A,(HL)
  XOR C
  LD (HL),A
XorLineDone:
  POP BC
  RET
