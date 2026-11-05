; --------------------------------------------------------------------------------------------------------------------
; star.asm: the burning star: its points, its lines, the flames, the picture on the screen
;
; The left part of the screen under the logo: a pentagram whose five tips turn on a circle, drawn as glowing lines
; that burn upwards (the frames of work/intro/i1's sheet after the logo). It is drawn in StarBuffer, a grid of heat
; cells (one byte a cell, 0-15, a page a row: cell (x, y) at StarBuffer + y x 256 + x), and shown at a quarter of the
; resolution in dither patterns: a cell is 4 x 4 pixels, 40 x 38 cells from the screen's column 1, line 40.
;
; ScrollerStart runs once: black screen, ScrollerScreen (the logo and "Presents") copied to $4000, StarBuffer cleared,
; ScrollerInit (the tables), then the CALL to TextInterrupt patched into the loader's interrupt (LoaderHook), and the
; star's loop forever (the loader's interrupt ends it with SPACE: LoaderEnd). A pass of the loop: the five tips from
; StarPath (StarPoints), the pentagram's five lines at the heat StarHeat (StarLine), the flames (StarBurn), the
; picture to the screen (StarShow, two HALTs), StarHeat one up or down (15 down to 2 and back: the lines pulse).
;
; StarPath is a circle of 90 points; the tips are 18 points apart (72 degrees) and move one point a pass, so after 18
; passes the star looks as at the start and StarStep goes back to the table's first point.
; --------------------------------------------------------------------------------------------------------------------

; the scroller's start: the screen, the tables, the text's interrupt, the
; star's loop
;
; Called by LoaderMain at $6600 after the HRUM depacker, with bank 0 at $C000
; and interrupts on (IM 2 through the loader's LoaderInterrupt). Never returns:
; SPACE ends the boot in LoaderInterrupt (LoaderEnd), wherever this loop is.
ScrollerStart:
  XOR A                   ; black border
  OUT ($FE),A
  LD HL,$5AFF             ; the whole screen ($4000-$5AFF) to $FF: (HL) = L of
                          ; $5AFF, then LDDR spreads it down
  LD DE,$5AFE
  LD BC,$1B00
  LD (HL),L
  PUSH BC
  LDDR
  LD HL,ScrollerScreen    ; the logo screen over it
  LD DE,$4000
  POP BC
  LDIR
  LD HL,StarBuffer        ; StarBuffer-$BFFF to 0 (L = 0 of $9800): the heat
                          ; grid and the rows past it
  LD DE,StarBuffer+$0001
  LD BC,$27FF
  LD (HL),L
  LDIR
  CALL ScrollerInit       ; the dither patterns, the pair index, the row
                          ; address tables
  EI                      ; one frame
  HALT
  LD A,$CD                ; CALL TextInterrupt into LoaderHook: the text from
                          ; the next frame on
  LD (LoaderHook),A
  LD HL,TextInterrupt
  LD (LoaderHook+1),HL
  HALT
StarStep:
  LD A,$01                ; A = the passes left before StarPath starts again
                          ; (operand, from 1: the first pass restarts)
  DEC A
  JP NZ,StarStepStore
  LD HL,StarPath          ; back to the first point of the circle
  LD (StarPathPointer+$0001),HL
  LD A,$12                ; 18 passes, then again
StarStepStore:
  LD (StarStep+$0001),A   ; the passes left
StarPathPointer:
  LD HL,$0000             ; HL = the current point of tip 0 (operand)
  LD DE,$0022             ; the next tip: 18 points (36 bytes) on, 2 read
                          ; already
  LD C,(HL)               ; tip 0: C = x, B = y
  INC HL
  LD B,(HL)
  INC HL
  LD (StarPathPointer+$0001),HL ; the next pass starts one point on
  LD (StarPoints),BC
  ADD HL,DE               ; tip 1 ...
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (StarPoints+$0002),BC
  ADD HL,DE
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (StarPoints+$0004),BC
  ADD HL,DE
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (StarPoints+$0006),BC
  ADD HL,DE
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD (StarPoints+$0008),BC
  LD HL,(StarPoints)      ; the pentagram: tip 0 to tip 2 ...
  LD DE,(StarPoints+$0004)
  CALL StarLine
  LD HL,(StarPoints+$0004) ; ... 2 to 4 ...
  LD DE,(StarPoints+$0008)
  CALL StarLine
  LD HL,(StarPoints+$0008) ; ... 4 to 1 ...
  LD DE,(StarPoints+$0002)
  CALL StarLine
  LD HL,(StarPoints+$0002) ; ... 1 to 3 ...
  LD DE,(StarPoints+$0006)
  CALL StarLine
  LD HL,(StarPoints+$0006) ; ... and 3 to 0
  LD DE,(StarPoints)
  CALL StarLine
  CALL StarBurn           ; the flames
  CALL StarShow           ; to the screen (two frames)
HeatDirection:
  LD A,$FF                ; A = $FF while StarHeat rises, 0 while it falls
                          ; (operand, flipped at the ends)
  OR A
  JP Z,HeatFall
  LD A,(StarHeat)         ; rising: one up, to 15
  INC A
  CP $10
  JP Z,HeatTurn
  LD (StarHeat),A
  JP StarNext
HeatFall:
  LD A,(StarHeat)         ; falling: one down, to 2
  DEC A
  CP $01
  JP Z,HeatTurn
  LD (StarHeat),A
  JP StarNext
HeatTurn:
  LD A,(HeatDirection+$0001) ; at an end: the direction turns
  CPL
  LD (HeatDirection+$0001),A
StarNext:
  JP StarStep             ; the next pass

; never called: shows bank 7's screen (left over from another part)
;
; Nothing in the image calls it (no read or run of it in tools/intro_trace.py's
; run). It whitens the attributes, pages bank 7 with ScrollerSetPage, copies
; $DB00-$F5FF to the screen, pages bank 0 back: code of an earlier take of the
; boot left in the block.
ScrollerUnusedShow:
  LD HL,$5800
  LD DE,$5801
  LD (HL),$3F
  LD BC,$02FF
  LDIR
  LD A,$17
  CALL ScrollerSetPage
  HALT
  LD A,$07
  OUT ($FE),A
  LD HL,UnusedScreenPlace
  LD DE,$4000
  LD BC,$1B00
  LDIR
  LD A,$10
  CALL ScrollerSetPage
  RET

; the five tips of this pass: x (low byte), y (high byte), cells of StarBuffer
;
; Written by ScrollerStart from StarPath, read in pairs for StarLine.
StarPoints:
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW $0000

; StarBuffer to the screen in dither patterns
;
; Two frames: the first 29 rows of cells after one HALT (4 pixel lines each),
; the last 9 after the next (2 lines each), so the copy keeps behind the beam.
; The stack walks StarRows (a screen address a row) and the row of StarBuffer
; (IX, a page a row): POP takes two cells, SET 7,H makes the pair's index
; address in PairIndex ($80 + right cell, left cell), and its value C chooses
; the pattern bytes in DitherPatterns (page $7C + line, C). Each row is 20 such
; pairs, written out without a loop.
StarShow:
  EI
  HALT
  DI
  LD (StarShowSP+$0001),SP ; SP kept in the LD SP at the end
  LD HL,StarRows          ; HL = StarRows, C = 29 rows
  LD C,$1D
  EXX
  LD B,$7C                ; B' = the patterns' first page, IX = the first row
                          ; of StarBuffer
  LD IX,StarBuffer+$0001
  EXX
StarShowRow:
  LD SP,HL                ; SP = the row's entry in StarRows
  INC L
  INC L
  EXX
  POP DE                  ; DE = the row's screen address
  LD SP,IX                ; SP = the row of cells; IX the next row
  INC IXH
  POP HL                  ; L, H = two cells (x, x + 1)
  SET 7,H                 ; H = $80 + the right cell: the pair's place in
                          ; PairIndex
  LD C,(HL)               ; C = the pair's index, the low byte of its pattern
  LD A,(BC)               ; four lines of the pattern, down (the next pair up
                          ; again)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  EXX
  DEC C
  JP NZ,StarShowRow
StarShowSP:
  LD SP,$0000             ; SP back (operand)
  EI                      ; the next frame
  HALT
  DI
  LD (StarShowSP2+$0001),SP
  LD C,$09                ; the last 9 rows, 2 lines each
StarShowRowLow:
  LD SP,HL                ; one row of the bottom part: 20 bytes of 2 lines
  INC L
  INC L
  EXX
  POP DE
  LD SP,IX
  INC IXH
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC B
  INC D
  LD A,(BC)
  LD (DE),A
  INC E
  POP HL
  SET 7,H
  LD C,(HL)
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  DEC B
  DEC D
  LD A,(BC)
  LD (DE),A
  INC E
  EXX
  DEC C
  JP NZ,StarShowRowLow
StarShowSP2:
  LD SP,$0000             ; SP back (operand)
  EI
  RET

; the flames: every cell the mean of the four below it, the heat rising
;
; A cell (x, y) becomes (cell (x, y + 2) + cells (x - 1, y + 1), (x, y + 1), (x
; + 1, y + 1)) / 4, for 38 rows and the columns of a row from 1 (written out
; without a loop): the lines StarLine draws spread and fade upwards one row a
; pass. The rows are done top down, each from the rows below it as the last
; pass left them.
StarBurn:
  LD BC,$9801             ; BC = cell (1, 0): the cell written
  LD HL,StarBuffer+$0100  ; HL = cell (0, 1): the three cells under it
  LD DE,StarBuffer+$0201  ; DE = cell (1, 2): the one under those
  LD IXL,$26              ; 38 rows
StarBurnRow:
  LD A,(DE)               ; one row
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C
  LD A,(DE)
  INC E
  ADD A,(HL)
  INC L
  ADD A,(HL)
  INC L
  ADD A,(HL)
  DEC L
  SRL A
  SRL A
  LD (BC),A
  INC C                   ; the next row: columns from 1 again
  LD L,$00
  LD C,$01
  LD E,C
  INC H
  INC B
  INC D
  DEC IXL
  JP NZ,StarBurnRow
  RET

; a line of heat StarHeat in StarBuffer from cell (L, H) to cell (E, D)
;
; Bresenham's line: B and C the steps (+1 or -1) in y and x, the longer side
; counted in the loop, the shorter one's error kept in L or H with the step's
; correction written into the ADD after the step (StarLineXError,
; StarLineYError). A cell's address is (y + $98) x 256 + x. Called five times a
; pass by ScrollerStart.
StarLine:
  LD C,$FF                ; the steps -1 ...
  LD B,C
  LD A,E                  ; dx = x1 - x0; negative: +1
  SUB L
  JR NC,StarLineDy
  NEG
  LD C,$01
StarLineDy:
  LD L,A                  ; dy = y1 - y0; negative: +1
  LD A,D
  SUB H
  JR NC,StarLineLonger
  NEG
  LD B,$01
StarLineLonger:
  LD H,A                  ; dx >= dy: along x
  LD A,L
  SUB H
  JR C,StarLineSteep
  LD A,L                  ; dx = 0: one cell
  OR A
  JR NZ,StarLineX
  LD A,$98
  ADD A,D
  LD D,A
  LD A,(StarHeat)
  LD (DE),A
  RET
StarLineX:
  LD (StarLineXError+$0001),A ; along x: dx steps; the correction dx into the
                              ; error's ADD
  SRL L                   ; the error starts at dx / 2
StarLineXStep:
  EX AF,AF'               ; one cell, then x one step
  PUSH AF
  PUSH DE
  LD A,$98
  ADD A,D
  LD D,A
  LD A,(StarHeat)
  LD (DE),A
  POP DE
  POP AF
  LD A,E
  ADD A,C
  LD E,A
  LD A,L                  ; the error less dy; below 0: y one step
  SUB H
  LD L,A
  JR NC,StarLineXCount
StarLineXError:
  ADD A,$07               ; the error + dx (operand)
  LD L,A
  LD A,B
  ADD A,D
  LD D,A
StarLineXCount:
  EX AF,AF'               ; dx cells
  DEC A
  JR NZ,StarLineXStep
  LD A,$98                ; the last cell
  ADD A,D
  LD D,A
  LD A,(StarHeat)
  LD (DE),A
  RET
StarLineSteep:
  LD A,H                  ; dy > dx: along y
  OR A
  JR NZ,StarLineY
  LD A,$98
  ADD A,D
  LD D,A
  LD A,(StarHeat)
  LD (DE),A
  RET
StarLineY:
  LD (StarLineYError+$0001),A ; along y: dy steps
  SRL H
StarLineYStep:
  EX AF,AF'               ; one cell, then y one step
  PUSH AF
  PUSH DE
  LD A,$98
  ADD A,D
  LD D,A
  LD A,(StarHeat)
  LD (DE),A
  POP DE
  POP AF
  LD A,D
  ADD A,B
  LD D,A
  LD A,H
  SUB L
  LD H,A
  JR NC,StarLineYCount
StarLineYError:
  ADD A,$17               ; the error + dy (operand)
  LD H,A
  LD A,C
  ADD A,E
  LD E,A
StarLineYCount:
  EX AF,AF'               ; dy cells
  DEC A
  JR NZ,StarLineYStep
  LD A,$98
  ADD A,D
  LD D,A
  LD A,(StarHeat)
  LD (DE),A
  RET

; the heat StarLine draws: 2-15, one up or down a pass
StarHeat:
  DEFB $0F
