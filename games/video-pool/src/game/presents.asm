; --------------------------------------------------------------------------------------------------------------------
; presents.asm: The presents page: the OCP banner rolling in, "presents", the attract loop
;
; PresentsPage $B8C5 is the game's first screen (called by GameStart $8000 before IM 2 is set up) and the attract
; sequence the menu falls into after its timeout ($B293, $B67E). It runs BannerRollIn $B96C (the magenta OCP banner
; slides in row by row), prints "presents", flips the banner's letters from OCP to POOL (LogoFlip $BB13), slides in
; "video" (VideoSlideIn $BC9E), lets a pen write "written by" and James Hutchby's signature (SignatureWrite $BD0C),
; prints "press any key to continue." and starts again. Every wait goes through PresentsFrame $B91B: one HALT and a
; key test; a key reloads the stack pointer saved at entry and returns from PresentsPage to its caller, whatever depth
; the sequence was at.
;
; The banner's drawing has its own pixel-address routine and 4-pixel XOR blocks: a row moves right 4 pixels a frame by
; XORing one block at the start and one past the end of each ink run (BannerRowEdges $BA0A), so a row costs two blocks
; per run, not a redraw.
; --------------------------------------------------------------------------------------------------------------------

; The presents page and the attract loop: banner, "presents", OCP to POOL,
; "video", the signature, "press any key"
;
; Saves SP in PresentsSP $BD09 (the abort target of PresentsFrame $B91B), draws
; the banner (BannerRollIn $B96C), prints "presents" (PresentsTexts $B936, row
; 16 column 12) for 75 frames, blanks it, flips the letters (LogoFlip $BB13),
; slides in "video" (VideoSlideIn $BC9E), waits 50 frames, runs the pen
; (SignatureWrite $BD0C), waits 25 frames, prints "press any key to continue."
; (row 23) and waits 500 frames (PresentsLongWait $B90F). Then, if PresentsDone
; $BD0B is zero (the first call, from GameStart $8000, which sets it to $FF
; only after the return), it starts again at once; otherwise it calls $A8FD,
; waits 500 frames more and starts again.
;
; Called by GameStart $8000 ($800B) and by the menu ($B293 after its timeout,
; $B67E). Returns only through a key (PresentsAbort $B931). Witness (l1sum.py
; B8C5): entered in every build; game 5556-6051 (a key on "presents" at 6051),
; f1 / p2 / v1 0-494, w1 twice (0-494 and the attract after the menu's timeout
; at 16 160-16 377), m1 0-4129 with two complete loops (the 500-frame wait
; PresentsLongWait ran at 1237 and 3474, then JP back, since PresentsDone was
; 0); the $A8FD branch ($B906) ran in no build.
PresentsPage:
  LD (PresentsSP),SP
  CALL BannerRollIn
  LD HL,PresentsTexts
  CALL PrintText
  LD B,$4B
PresentsHold1:
  CALL PresentsFrame      ; 75 frames with "presents" up
  DJNZ PresentsHold1
  LD HL,PresentsBlank
  CALL PrintText
  CALL LogoFlip
  CALL VideoSlideIn
  LD B,$32
PresentsHold2:
  CALL PresentsFrame      ; 50 frames after "video"
  DJNZ PresentsHold2
  CALL SignatureWrite
  LD B,$19
PresentsHold3:
  CALL PresentsFrame      ; 25 frames after the signature
  DJNZ PresentsHold3
  LD HL,PressAnyKey
  CALL PrintText
  CALL PresentsLongWait
  LD A,(PresentsDone)
  OR A
  JP Z,PresentsPage
  CALL ShowHallOfFame
  CALL PresentsLongWait
  JP PresentsPage

; Wait 500 frames, a key aborts
;
; 500 calls of PresentsFrame $B91B (BC = 500). m1 ran it twice (frames 1237 and
; 3474, 1000 loop passes); no other build reached the end of the sequence.
PresentsLongWait:
  LD BC,$01F4
PresentsLongWaitLoop:
  CALL PresentsFrame
  DEC BC
  LD A,B
  OR C
  JR NZ,PresentsLongWaitLoop
  RET

; Wait one frame (HALT); a key returns from PresentsPage to its caller
;
; HALT, then the ROM's KEY-SCAN $028E and K-TEST $031E: no key (Z and K-TEST
; $FF) returns with all registers kept; a key (or more than two keys, NZ from
; KEY-SCAN) reloads SP from PresentsSP $BD09 and RETs, which returns from
; PresentsPage $B8C5 to the caller that saved it. Used by every wait of the
; attract sequence (BannerRollIn, LogoFlip, VideoSlideIn and the pen's steps in
; SignatureCommand $BD23).
;
; Witness: game 499 calls 5559-6060, w1 1084, m1 4353 (2-4500); the abort
; PresentsAbort ran once in every build (game 6051 / 6060, w1, f1, p2, v1 at
; 494-500, m1 at 4500, the SPACE of tests/inputs/m1.txt).
PresentsFrame:
  HALT
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  CALL KEY_SCAN
  JR NZ,PresentsAbort
  CALL K_TEST
  CP $FF
  JR NZ,PresentsAbort
  POP HL
  POP DE
  POP BC
  POP AF
  RET
PresentsAbort:
  LD SP,(PresentsSP)      ; a key: back to PresentsPage's caller
  RET

; The page's texts in the print format of $9E65: row, column, attribute,
; length, characters
;
; Three records for the print routine $9E65 (row, column, attribute, length,
; then the characters): "presents" (row 16, column 12, attribute $38), eight
; spaces over it, and "press any key to continue." (row 23, column 3, attribute
; $38, 26 characters). Read by PresentsPage $B8C5; the first 24 bytes in every
; build, the last record only in m1 (the only build that reached the end of the
; sequence).
PresentsTexts:
  INCBIN "res/text/PresentsTexts.bin",$0000,12
PresentsBlank:
  INCBIN "res/text/PresentsTexts.bin",$000C,12
PressAnyKey:
  INCBIN "res/text/PresentsTexts.bin",$0018,30

; Clear the screen and roll the magenta OCP banner in from the left, row by row
; (417 frames)
;
; Clears the display file, border white (OUT $07), attributes $38 (black on
; white), rows 4-12 $3B (magenta ink). Then the banner: HL is the x of the
; moving row as a signed 16-bit number, starting at -240 off the left edge; B
; is the pixel line of the top moving row (from 32), DE the run-length row of
; BannerData $BA86. Each frame (PresentsFrame $B91B) it calls BannerDrawRows
; $B9E0 and moves x 4 pixels right; when the top row reaches x 8 its line is
; done: B goes one line down, every second line DE moves to the next data row
; (each data row is two pixel lines), and x goes back 20 pixels for the row
; below. It ends at line 104 ($68), 72 lines (36 data rows), and sets the
; attribute $7B (bright) on rows 4-12, columns 1-30.
;
; Witness (l1sum.py B96C B9E0): 1 call per presents page, game 5556-5976;
; BannerDrawRows 417 calls each (game 5560-5976). WALKTHROUGH 6.1 m1 frame 300
; shows the staircase of rows half way in.
BannerRollIn:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  LD A,$07
  OUT ($FE),A
  INC HL
  INC DE
  LD BC,$02FF
  LD (HL),$38
  LDIR
  LD HL,Attributes+128
  LD DE,Attributes+129
  LD BC,$011F
  LD (HL),$3B
  LDIR
  LD HL,-$00F0
  LD DE,BannerData
  LD B,$20
BannerFrameLoop:
  CALL PresentsFrame      ; one frame: draw, x + 4
  CALL BannerDrawRows
  PUSH BC
  LD BC,$0004
  ADD HL,BC
  PUSH HL
  LD BC,$0008
  XOR A
  SBC HL,BC
  POP HL
  POP BC
  JR NZ,BannerFrameLoop
  INC B
  BIT 0,B
  JR Z,BannerNextRow
  LD C,$F0
BannerSkipRow:
  LD A,(DE)               ; DE past one data row (runs summing to 240 pixels)
  INC DE
  ADD A,A
  NEG
  ADD A,C
  LD C,A
  JR NZ,BannerSkipRow
BannerNextRow:
  PUSH BC                 ; the next line's x: 20 pixels behind
  LD BC,-$0014
  ADD HL,BC
  POP BC
  LD A,B
  CP $68
  JR NZ,BannerFrameLoop
  LD HL,Attributes+128
  LD B,$09
  LD A,$7B
BannerBrightRows:
  PUSH BC                 ; attribute $7B on rows 4-12, columns 1-30
  LD B,$1E
  INC HL
BannerBrightLoop:
  LD (HL),A
  INC HL
  DJNZ BannerBrightLoop
  INC HL
  POP BC
  DJNZ BannerBrightRows
  RET

; Move every row from line B downwards that is on screen: 4 pixels right
;
; For the line B and each line below (x 20 pixels further left each, DE
; advancing every second line as in BannerRollIn $B96C): BannerRowEdges $BA0A,
; while the row's x is within -256..255 (H = 0 or $FF) and the line is above
; 104. Registers kept. game 417 calls, 4748 rows (BannerRowEdges).
BannerDrawRows:
  PUSH HL
  PUSH DE
  PUSH BC
BannerRowLoop:
  PUSH DE
  PUSH BC
  PUSH HL
  CALL BannerRowEdges
  POP HL
  LD BC,-$0014
  ADD HL,BC
  POP BC
  INC B
  BIT 0,B
  JR Z,BannerSameRow
  INC SP
  INC SP
  JR BannerRowClip
BannerSameRow:
  POP DE                  ; odd line: the same data row again
BannerRowClip:
  LD A,H                  ; stop when x is past -256..255 or the line reaches
                          ; 104
  OR A
  JR Z,BannerRowNext
  CP $FF
  JR NZ,BannerRowsDone
BannerRowNext:
  LD A,B
  CP $68
  JR NZ,BannerRowLoop
BannerRowsDone:
  POP BC
  POP DE
  POP HL
  RET

; One banner row 4 pixels right: XOR a block at the start and one at the end of
; each ink run
;
; DE = the row's runs in BannerData $BA86, HL = x, B = the line. For each run
; byte (bit 7 = ink, bits 0-6 = half the length): an ink run gets
; BannerEdgeBlock $BA31 at x and at x + length, which clears the 4 pixels the
; run leaves and sets the 4 it enters (the row was drawn 4 pixels to the left
; on the frame before). Runs until the lengths add up to 240 pixels (C counts
; down from $F0). game 4748 calls, 18 476 runs.
BannerRowEdges:
  LD C,$F0
BannerRunLoop:
  LD A,(DE)
  OR A
  JP P,BannerRunSkip
  PUSH HL
  CALL BannerEdgeBlock
  LD A,(DE)
  ADD A,A
  ADD A,L
  LD L,A
  JR NC,BannerRunEnd
  INC H
BannerRunEnd:
  CALL BannerEdgeBlock    ; the block at the run's end
  POP HL
BannerRunSkip:
  LD A,(DE)               ; x + length
  ADD A,A
  ADD A,L
  LD L,A
  JR NC,BannerRunNext
  INC H
BannerRunNext:
  LD A,(DE)
  INC DE
  ADD A,A
  NEG
  ADD A,C
  LD C,A
  JR NZ,BannerRunLoop
  RET

; XOR the 4-pixel block at x (HL signed) on line B, if x is on screen
;
; HL = x (signed), B = the line. x 0-255: BannerXorBlock $BA54 at x; x -4..-1:
; the block is drawn as far as it reaches onto the screen (x + 4 with B = that
; count). Registers kept. game 21 112 calls.
BannerEdgeBlock:
  PUSH HL
  PUSH BC
  PUSH DE
  LD A,H
  OR A
  JR NZ,BannerEdgeRight
  LD D,B
  LD E,L
  LD B,$04
  JR BannerEdgeXor
BannerEdgeRight:
  LD A,L                  ; x negative: try x + 4
  ADD A,$04
  LD L,A
  JR NC,BannerEdgeCheck
  INC H
BannerEdgeCheck:
  LD A,H
  OR A
  JR NZ,BannerEdgeDone
  LD D,B
  LD E,$00
  LD B,L
BannerEdgeXor:
  CALL BannerXorBlock
BannerEdgeDone:
  POP DE
  POP BC
  POP HL
  RET

; XOR 4 pixels (a nibble) at x E, line D: B = 0 draws nothing
;
; The screen byte from PresentsPixelAddress $BA6C, XORed with $F0 when x AND 7
; is 0 and $0F otherwise (the banner's x is always a multiple of 4). game 10
; 127 calls.
BannerXorBlock:
  LD A,B
  OR A
  RET Z
  LD H,D
  LD L,E
  CALL PresentsPixelAddress
  LD A,D
  AND $07
  ADD A,H
  LD H,A
  LD A,E
  AND $07
  LD A,$F0
  JR Z,BannerXorNibble
  CPL
BannerXorNibble:
  XOR (HL)
  LD (HL),A
  RET

; HL = the display-file address of pixel line H, x L (the byte; the caller adds
; the line within the cell)
;
; H = y, L = x in: L = (y AND $38) * 4 + x / 8, H = $40 + (y AND $C0) / 8. The
; caller adds y AND 7 to H. Used by BannerXorBlock $BA54 and VideoSlideIn
; $BC9E. game 9808 calls; the same code as PenPixelAddress $BFB2.
PresentsPixelAddress:
  LD A,H
  ADD A,A
  ADD A,A
  AND $E0
  SRL L
  SRL L
  SRL L
  ADD A,L
  LD L,A
  LD A,H
  SRL A
  SRL A
  SRL A
  AND $F8
  OR $40
  LD H,A
  RET

; The OCP banner: 36 rows of run lengths, 240 pixels each (bit 7 ink, bits 0-6
; half the length)
;
; One byte a run: bit 7 set = magenta ink, clear = paper; bits 0-6 = half the
; run's length in pixels. A row ends when its runs add up to 240 pixels: $F8
; alone is a full ink row, $78 a full paper row. The letters O, C and P are the
; paper gaps in the ink stripes (WALKTHROUGH 6.1, m1 frame 300). Read by
; BannerRowEdges $BA0A (and BannerRollIn $B96C, BannerDrawRows $B9E0 to skip
; rows); all 141 bytes in every build.
BannerData:
  DEFB $F8,$F8,$F8,$F8,$78,$F8,$F8,$94,$10,$90,$10,$8C,$14,$94,$78,$94
  DEFB $10,$90,$10,$8C,$14,$94,$F8,$90,$04,$90,$04,$88,$04,$90,$04,$88
  DEFB $04,$90,$04,$90,$78,$90,$04,$90,$04,$88,$04,$90,$04,$88,$04,$90
  DEFB $04,$90,$F8,$90,$04,$90,$04,$88,$04,$9C,$04,$90,$04,$90,$78,$90
  DEFB $04,$90,$04,$88,$04,$9C,$04,$90,$04,$90,$F8,$90,$04,$90,$04,$88
  DEFB $04,$9C,$14,$94,$78,$90,$04,$90,$04,$88,$04,$9C,$14,$94,$F8,$90
  DEFB $04,$90,$04,$88,$04,$90,$04,$88,$04,$A4,$78,$90,$04,$90,$04,$88
  DEFB $04,$90,$04,$88,$04,$A4,$F8,$94,$10,$90,$10,$8C,$04,$A4,$78,$94
  DEFB $10,$90,$10,$8C,$04,$A4,$F8,$F8,$78,$F8,$F8,$F8,$F8
