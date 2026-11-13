; --------------------------------------------------------------------------------------------------------------------
; beam.asm: The beam: the laser, the receiver, the trace
;
; FindLaser $8AC1 finds the laser in the grid at the level's set-up: the beam's start (direction and the half-cell in
; front of it) and the cursor's first cell. OpenReceiver $8B3F blows the element in front of the receiver once the
; last cell burns. TraceBeam $8ED6 follows the beam from the laser through the grid each pass: BeamStep $8EDD looks at
; the cell under each whole-cell position and chooses what the beam does there (on through empty cells and blocks, a
; reflection by a mirror, a cell burnt, a mine, the grey grid, the fibre optics, the receiver, the laser), the step
; code from $906E (the next annotator's) draws it and moves on.
;
; Positions are in half-cells: x 0-32, y 0-20, both even at a cell's centre (cell (r, c) at x = 2c + 2, y = 2r + 2;
; the character (y - 1, x - 1) is its top-left). Directions are 0-15 clockwise from east in steps of 22.5 degrees (4
; down, 8 west, 12 up); the table $8170 gives each direction's (dx, dy) in half-cells.
; --------------------------------------------------------------------------------------------------------------------

  ORG $8000

; The beam's glyphs round a vertex: 4 bytes for each direction, two sets of 16
; directions
;
; BeamVertex `$906E` (at `$90C7`) and the outgoing pass (`$91E3`) point DE at
; `$8000` + 4 x direction + BeamGlyphSet `$8381` (`LD D,$80`): set 0 at
; `$8000`, set 1 (`$8381` = `$40`, the flashing beam while the energy is
; critical) at `$8040`. The four bytes are the characters up-left, up-right,
; down-left and down-right of the vertex.
;
; A byte's bits 7-6 say which pass draws it: 00 the incoming pass BeamInChar
; `$9278`, 01 the outgoing pass BeamOutChar `$94FD`, 10 the corner pass
; BeamCornerChar `$9440` (a slanted beam cutting a character's corner); bits
; 5-0 the glyph, BeamGlyphs `$D500` + 8 x glyph. The glyphs used are 0-38. Read
; in every recording with a beam; the editable form is
; tables/beam-glyph-bytes.csv.
BeamGlyphBytes:
  INCBIN "res/tables/beam-glyph-bytes.bin",$0000,128

; A slanted beam's bounce in the outgoing pass: 8 bytes for each new direction
;
; BeamReflectOut `$960D` (at `$965C`, a slope or diagonal meeting a wall or a
; yellow polariser) takes `$8080` + 8 x the new direction: two words, the
; offsets from the vertex's up-left character in the character map of the two
; characters to test, then four directions by which of them are walls
; (`$31-$72`): none, the first, the second, both. BeamCornerChar (at `$94E9`,
; two corners met) reads only the last byte, `$8087` + 8 x direction.
;
; The rows of the axis directions 0, 4, 8 and 12 are never read (an axis beam
; grazes or goes straight back: `$8190`); `$80CF` and `$80DF` (the "both" of
; directions 9 and 11) were read by no recording. Editable form:
; tables/out-bounce.csv.
OutBounceTable:
  INCBIN "res/tables/out-bounce.bin",$0000,128

; A diagonal beam's bounce in the incoming pass: 16 bytes for each of the
; diagonals 2, 6, 10, 14
;
; ReflectInCorner `$93F2` (`$93F4`): InBounceTable gives `$80` + n for a
; diagonal, and `$8100` + n holds two words (the offsets of the characters
; above or below and beside the corner) and four answers of three bytes (the
; new direction, dx, dy) by which of them are walls: none (+4), the first (+7),
; the second (+10), both (+13). None or both send the beam back (OVERLOAD), one
; turns it a quarter.
;
; No play reads it: the trace's first vertex is the only one whose incoming
; pass meets a wall the outgoing pass before it has not
; (work/docs/integrate/corner_level1.py), and that vertex is the laser's front,
; on an axis. Read only on a clone, `corner` (game0.szx with the beam's start
; `$8376-$8378` POKEd to x 10, y 16, direction 10: 342 passes, the beam turned
; a quarter to direction 14). Editable form: tables/in-corner.csv.
InCornerTable:
  INCBIN "res/tables/in-corner.bin",$0000,64

; A slanted beam's bounce in the incoming pass: the new direction and the step,
; 3 bytes a direction
;
; BeamReflectIn `$938F` (at `$93DE`, ReflectInSlant): `$8140` + 3 x direction.
; Byte 0 is the bounced direction (a slope's mirror image off the wall it can
; meet: 1 to 7, 7 to 1, 9 to 15, 15 to 9 off an upright wall; 3 to 13, 5 to 11,
; 11 to 5, 13 to 3 off a level one), or `$80` + n for a diagonal (InCornerTable
; `$8100` + n decides); bytes 1-2 the step (dx, dy) to the vertex the beam
; leaves from, given to BeamMove `$9235`.
;
; Only the slopes' and diagonals' rows are read (the axis rows 0, 4, 8, 12 are
; there for the index, and the recordings read the slope rows only: 21 949
; bounces in 33 RZX segments). Editable form: tables/in-bounce.csv.
InBounceTable:
  INCBIN "res/tables/in-bounce.bin",$0000,48

; The step of each of the 16 beam directions: dx, dy in half-cells (signed), 0
; east, clockwise
;
; (2,0) (2,1) (1,1) (1,2) (0,2) (-1,2) (-1,1) (-2,1) (-2,0) (-2,-1) (-1,-1)
; (-1,-2) (0,-2) (1,-2) (1,-1) (2,-1): a step is one cell along the axes, a
; character on the diagonals, two by one on the slopes. Read by BeamStep
; `$9226` (`$9230`, 2 x direction), FindLaser `$8AC1` (`$8AF7`, the half-cell
; in front of the laser: 8 x the laser's direction index) and OpenReceiver
; `$8B3F` (`$8B6A`, the cell in front of the receiver).
;
; Editable form: tables/beam-deltas.csv.
BeamDeltas:
  INCBIN "res/tables/beam-deltas.bin",$0000,32

; The character across an axis beam's line: 8 offsets in the character map
;
; When an axis beam meets a wall character, the character across the beam line
; decides between grazing and stopping: BeamAbsorbIn `$9344` (at `$9357`),
; BeamReflectIn (`$93A2`) and the outgoing tests (`$95D5`, `$9620`) read the
; word at `$8190` + 2 x (the character's number in the pass - 1) + direction,
; so word (k - 1) + direction / 2: +31, -33, -31, -33, +33, -31, +33, +31 (the
; character map is 32 wide).
;
; For direction 12 the third and fourth characters of a pass would read
; `$81A0`-`$81A3`, the start of PolariserCells; whether the passes ever reach
; them there is not known from the recordings. Editable form:
; tables/graze-offsets.csv.
GrazeOffsets:
  INCBIN "res/tables/graze-offsets.bin",$0000,16

; The three other characters of a polariser: 3 offsets for each of its four
; characters
;
; PolariserPassIn (`$9320`) and the outgoing pass (`$959E`): a beam along a
; polariser's axis lights the polariser's other three characters. The row is
; `$81A0` + 6 x (character code AND 3); the polariser characters `$31-$70` run
; top left, top right, bottom left, bottom right from `$x1`, so row 0 is the
; bottom-right character (-33, -32, -1), row 1 the top-left (+1, +32, +33), row
; 2 the top-right (+31, +32, -1), row 3 the bottom-left (+1, -32, -31).
;
; Editable form: tables/polariser-cells.csv.
PolariserCells:
  INCBIN "res/tables/polariser-cells.bin",$0000,24

  ORG $8AC1

; Find the laser ($47-$4A) in the grid: the beam's start and direction, the
; cursor's first cell
;
; Scans the grid backwards from its last cell `$FDB9` (B = column + 1, C = row
; + 1) for a code `$47-$4A` (the laser; bit 7 clear). None: `$8378` = `$FF`,
; and MainLoop traces no beam.
;
; Found: `$8374` = 2B, `$8375` = 2C (the laser's centre in half-cells); the
; direction `$8378` = 4 x ((code - `$43`) AND 3): `$47` east, `$48` down, `$49`
; west, `$4A` up. The direction's (dx, dy) from `$8170`: the beam's start
; `$8376` = x + dx and `$8377` = y + dy (the half-cell in front; it returns if
; that is off the field: x 32 or more, y 20 or more).
;
; The cursor (`$96C3` column, `$96C4` row) starts on the cell in front of the
; laser and moves on by (dx / 2, dy / 2) until a cell is not empty: the cursor
; starts on the first element the laser points at (level 1: the mirror at row
; 7, column 0, left of the laser). The walk has no bound but the elements it
; meets.
;
; From SetUpLevel (`$8547`).
;
; Witness: L1 200 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston,
; menu, mine, nameedit, overload, practice, L x20, rzx x59).
FindLaser:
  LD HL,LevelGrid+185
  LD C,$09
FindLaserRow:
  LD B,$0F
FindLaserCell:
  LD A,(HL)
  CP $4B
  JR NC,FindLaserNext
  CP $47
  JR NC,FindLaserFound
FindLaserNext:
  DEC L
  DJNZ FindLaserCell
  DEC HL                  ; the next row up: past the two guards
  DEC HL
  DEC C
  JR NZ,FindLaserRow
  LD A,$FF                ; no laser
  LD (BeamStartDirection),A
  RET
FindLaserFound:
  LD D,A                  ; the laser's centre in half-cells
  LD A,B
  ADD A,A
  LD (HighlightX),A
  LD B,A
  LD A,C
  ADD A,A
  LD (HighlightY),A
  LD C,A
  LD A,D                  ; its direction: 4 x ((code - $43) AND 3)
  SUB $43
  AND $03
  ADD A,A
  ADD A,A
  LD (BeamStartDirection),A
  ADD A,A                 ; (dx, dy) from the direction table $8170
  LD HL,BeamDeltas
  ADD A,L
  LD L,A
  LD A,(HL)               ; the beam's start x, the cursor's column
  LD D,A
  ADD A,B
  CP $20
  RET NC
  LD (BeamStartX),A
  SRL A
  DEC A
  LD (CursorX),A
  INC L                   ; the beam's start y, the cursor's row
  LD A,(HL)
  LD E,A
  ADD A,C
  CP $14
  RET NC
  LD (BeamStartY),A
  SRL A
  DEC A
  LD (CursorY),A
  SRA D                   ; (dx / 2, dy / 2): one cell
  SRA E
FindLaserCursor:
  LD A,(CursorX)          ; the cursor on along the beam to the first element
  ADD A,D
  LD (CursorX),A
  LD C,A
  LD A,(CursorY)
  ADD A,E
  LD (CursorY),A
  LD B,A
  LD A,$12                ; the grid address: $FD12 + 17 (row + 1) + column
  INC B
FindLaserRowAdd:
  ADD A,$11
  DJNZ FindLaserRowAdd
  ADD A,C
  LD L,A
  LD H,$FD
  LD A,(HL)
  AND A
  RET NZ
  JR FindLaserCursor

; The last cell burnt: the element in front of the receiver starts to explode
; (its door)
;
; From PassEnd (`$85E1`) when CellsLeft `$8380` reaches 0. Finds the receiver
; (`$4B-$4E`, scanning backwards like FindLaser); none: drops its return
; address and jumps to MainLoop (`$8B58`).
;
; The receiver's direction (code - `$4B`) AND 3 gives (dx, dy) from `$8170`;
; the cell in front of it (x + dx, y + dy, returning if off the field) goes
; into the first explosion slot `$81B8` (grid address high, low, y, x), and
; CellsLeft = `$FF` (no second call); the door's own explosion then decrements
; it to `$FE` when its slot empties. PassEnd then explodes it like a burnt cell
; (the code `$57`, then `$58-$5C`, then empty).
;
; In levels 1-60 the element in front of the receiver is a mine (`$41`, 23
; levels), a wall (`$21-$3E`, 32), a block (4) or a fibre-optic end (`$53`, 1):
; the receiver is shut until every cell burns.
;
; Run 21 times, all in RZX segments (once in each level the last cell burns).
;
; Witness: L1 41 (L x20, rzx x21).
OpenReceiver:
  LD HL,LevelGrid+185
  LD C,$09
OpenReceiverRow:
  LD B,$0F
OpenReceiverCell:
  LD A,(HL)
  CP $4F
  JR NC,OpenReceiverNext
  CP $4B
  JR NC,OpenReceiverFound
OpenReceiverNext:
  DEC L
  DJNZ OpenReceiverCell
  DEC HL
  DEC HL
  DEC C
  JR NZ,OpenReceiverRow
  POP HL                  ; no receiver: back to MainLoop
  JP MainLoop
OpenReceiverFound:
  LD D,A
  LD A,B
  ADD A,A
  LD B,A
  LD A,C
  ADD A,A
  LD C,A
  LD A,D                  ; its direction's (dx, dy)
  SUB $4B
  AND $03
  ADD A,A
  ADD A,A
  ADD A,A
  LD HL,BeamDeltas
  ADD A,L
  LD L,A
  LD A,(HL)
  ADD A,B
  CP $20
  RET NC
  LD B,A
  INC L
  LD A,(HL)
  ADD A,C
  CP $14
  RET NC
  LD C,B                  ; the cell in front into the first explosion slot: x,
                          ; y
  LD B,A
  LD HL,ExplosionSlots+$0003
  LD (HL),C
  DEC L
  LD (HL),B
  SRL B
  SRL C
  XOR A                   ; its grid address
  INC B
OpenReceiverRowAdd:
  ADD A,$11
  DJNZ OpenReceiverRowAdd
  ADD A,C
  LD E,A
  LD D,$FD
  DEC L
  LD (HL),E
  DEC L
  LD (HL),D
  LD A,$FF                ; CellsLeft $FF: done
  LD (CellsLeft),A
  RET

  ORG $8EBF

; The beam trace's state, and the pass's outcome flags
;
; Cleared by TraceBeam, BeamStep and the step code from `$906E`. LevelDone,
; LifeLost, BeamOnMine and BeamInLaser are cleared by SetUpLevel; PassEnd reads
; LevelDone and LifeLost, the overload code `$A683` reads BeamOnMine and
; BeamInLaser and clears them (`$A6C7`, `$A6CA`) once it has added their steps.
BeamSteps:
  DEFB $00                ; the trace's step count ($925E): the 40th calls
                          ; BeamBackToLaser (an overlong beam), 150 ends the
                          ; trace
  DEFB $00                ; cleared each trace; read and written at $96AC-$96B0
BeamAtCentre:
  DEFB $00                ; $FF at a cell's centre (set before the cell is
                          ; read), 0 between cells and for the blocks $11-$20
BeamReflected:
  DEFB $00                ; $FF after a mirror this step
  DEFB $00                ; six flags cleared each step at $906F-$907E (the
  DEFB $00                ; step code's)
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00
  DEFB $00                ; a word written at $92CB and $9552 (the step code's)
  DEFB $00
BeamDirection:
  DEFB $00                ; the beam's direction 0-15, $FF ended; set from the
                          ; laser's by MainLoop
BeamNextDirection:
  DEFB $00                ; the direction after this cell; $FF: the beam ends
                          ; here
BeamX:
  DEFB $00                ; the beam's x in half-cells (0-32)
BeamY:
  DEFB $00                ; the beam's y in half-cells (0-20)
  DEFB $00                ; written at $9063, read at $91CB (the fibre optics)
  DEFB $00                ; written at $9068, read at $91D1
  DEFB $00                ; cleared each step; set and read by the step code
                          ; ($9043, $91BF)
LevelDone:
  DEFB $00                ; $FF: the beam entered the receiver's front
                          ; (BeamStep $8FA9)
LifeLost:
  DEFB $00                ; $FF: a life is lost (the overload full $A6F0, the
                          ; energy drained $A67C)
BeamOnMine:
  DEFB $00                ; $FF: the beam met a mine this pass ($8F6C)
BeamInLaser:
  DEFB $00                ; $FF: the beam came back into the laser this pass
                          ; (BeamBackToLaser $8FC7)

; Trace the beam from the laser: the step count cleared, then BeamStep until
; the beam ends
;
; From MainLoop (`$859B`) with BeamDirection, BeamX, BeamY at the laser's
; front. Clears BeamSteps and `$8EC0`, then BeamStep, which loops (through the
; step code's `JP $8EDD` at `$926A` / `$9274`) and returns when the beam ends.
;
; BeamStep runs about 11.7 times a trace (1 038 316 against 88 519).
;
; Witness: L1 112689 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
TraceBeam:
  XOR A
  LD (BeamSteps),A
  LD (BeamSteps+$0001),A

; One step of the beam: at a cell's centre, what the cell does to it; then the
; step code ($906E)
;
; BeamNextDirection = BeamDirection (`$FF`: return, the beam has ended). When
; BeamX or BeamY is odd the beam is between cells: on to `$906E`. Else the cell
; (row y/2 - 1, column x/2 - 1) at `$FD12` + 17 (y/2) + x/2, BeamAtCentre =
; `$FF`, and the code with bit 7 cleared (a turning element acts as its current
; angle):
;
; - `$00` empty: on (`$906E`);
;
; - `$01-$10` a mirror: BeamMirror `$8FFB`;
;
; - `$11-$20` a block: BeamAtCentre = 0, on (`$906E`, the step code decides);
;
; - `$21-$3E` a wall: on (`$906E`, which reads BeamAtCentre);
;
; - `$3F` (no level holds it), `$40` a cell: burnt (BeamBurn);
;
; - `$41` a mine: BeamOnMine, the beam ends, SoundFlags bit 1 (BeamMine);
;
; - `$42` the grey grid: `$9014` (a random scatter, the next annotator's);
;
; - `$43-$4A` the laser (and `$43-$46`, which no level holds): BeamAtLaser
; `$8FAE`;
;
; - `$4B-$4E` the receiver: BeamReceiver;
;
; - `$4F-$57` the fibre optics: `$903E`;
;
; - `$58` and up (a cell exploding): return, the beam ends.
;
; Witness: L1 1251228 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamStep:
  XOR A
  LD (BeamAtCentre),A
  LD (BeamReflected),A
  LD (BeamY+$0003),A
  LD A,(BeamDirection)
  CP $FF
  RET Z
  LD (BeamNextDirection),A
  LD A,(BeamX)            ; x / 2: odd, between cells
  SRL A
  LD C,A
  JP C,BeamVertex
  LD A,(BeamY)            ; y / 2: odd, between cells
  SRL A
  LD B,A
  JP C,BeamVertex
  XOR A                   ; the cell: $FD12 + 17 (y/2) + x/2
  INC B
BeamStepRowAdd:
  ADD A,$11
  DJNZ BeamStepRowAdd
  ADD A,C
  LD L,A
  LD H,$FD
  LD A,$FF                ; at a cell's centre
  LD (BeamAtCentre),A
  LD A,(HL)               ; the code, a turning element as its current angle
  RES 7,A
  AND A
  JP Z,BeamVertex
  CP $11
  JP C,BeamMirror
  CP $21
  JR C,BeamBlock
  CP $58
  RET NC
  CP $4F
  JP NC,FibreEntry
  CP $4B
  JR NC,BeamReceiver
  CP $43
  JP NC,BeamAtLaser
  CP $42
  JP Z,PrismTurn
  CP $3F
  JP C,BeamVertex
  CP $41
  JR Z,BeamMine
BeamBurn:
  EX DE,HL                ; a cell: into a free explosion slot (six looked at;
                          ; the seventh if all are taken)
  LD B,$06
  LD HL,ExplosionSlots
BeamBurnSlot:
  LD A,(HL)
  AND A
  JR Z,BeamBurnStore
  INC L
  INC L
  INC L
  INC L
  DJNZ BeamBurnSlot
BeamBurnStore:
  LD (HL),D               ; the slot: grid address (high, low), y, x
  INC L
  LD (HL),E
  INC L
  LD A,(BeamY)
  LD (HL),A
  INC L
  LD A,(BeamX)
  LD (HL),A
  LD A,$FF                ; the beam ends at the cell
  LD (BeamNextDirection),A
CellPoints:
  LD B,$18                ; LD B,n: the points of a cell (x10); n set by
                          ; SetUpLevel (12, or 3)
  CALL AddScore
  JP BeamVertex
BeamMine:
  LD A,$FF                ; a mine: BeamOnMine, the beam ends, SoundFlags bit 1
  LD (BeamOnMine),A
  LD (BeamNextDirection),A
  LD A,(SoundFlags)
  SET 1,A
  LD (SoundFlags),A
  JP BeamVertex
BeamBlock:
  XOR A                   ; a block: no element at the centre for the step code
  LD (BeamAtCentre),A
  JP BeamVertex
BeamReceiver:
  SUB $4B                 ; the receiver: entered from its front?
  AND $03
  LD B,A
  LD A,(BeamDirection)    ; the beam must be on an axis (direction a multiple
                          ; of 4) ...
  LD C,A
  AND $03
  RET NZ
  LD A,C                  ; ... and opposite the receiver's facing: ((direction
                          ; + 8) AND 12) / 4 = (code - $4B) AND 3
  ADD A,$08
  AND $0C
  SRL A
  SRL A
  CP B
  RET NZ
  LD A,(BeamX)            ; contact: the receiver's centre to highlight,
                          ; LevelDone
  LD (HighlightX),A
  LD A,(BeamY)
  LD (HighlightY),A
  LD A,$FF
  LD (LevelDone),A
  JR HighlightCell

; The beam at the laser: from its front, BeamBackToLaser; else the beam ends
;
; From BeamStep (`$8F2F`) for the codes `$43-$4A`. As BeamReceiver: B = (code -
; `$43`) AND 3 (the laser's facing); the beam must run on an axis and against
; that facing (((direction + 8) AND 12) / 4 = B), else return: the beam ends
; against the laser's side or back. Then falls into BeamBackToLaser.
;
; Run 1094 times in 18 RZX segments; the front test passed 89 times (`$8FBA`, 7
; segments).
;
; Witness: L1 1135 (L x10, rzx x18).
BeamAtLaser:
  SUB $43
  AND $03
  LD B,A
  LD A,(BeamDirection)
  LD C,A
  AND $03
  RET NZ
  LD A,C
  ADD A,$08
  AND $0C
  SRL A
  SRL A
  CP B
  RET NZ

; BeamInLaser = $FF, then HighlightCell on the laser's cell
;
; From BeamAtLaser and from the step code (`$91B5`, `$926E` the 40th step,
; `$93D9`, `$9438`, `$9657`, `$96A4`, `$96B9`). HighlightCell uses `$8374` /
; `$8375`, the laser's centre FindLaser left there (BeamReceiver changes them
; only at contact, which ends the level).
;
; 6521 runs: `mine`, `overload` and 54 RZX segments. The `overload` recording
; sets BeamInLaser by a POKE (WALKTHROUGH 6.0).
;
; Witness: L1 7109 (hof, mine, nameedit, overload, L x20, rzx x54).
BeamBackToLaser:
  LD A,$FF
  LD (BeamInLaser),A

; Colour the cell at ($8374, $8375) bright magenta ($43) in ColourBuffer and
; mark it twice
;
; The cell whose centre is x = `$8374`, y = `$8375` (half-cells): its four
; colours at ColourBuffer `$E600` + 32 (y - 1) + x - 1 = `$43` (bright magenta
; on black), its four DrawMarks = 2. CopyPlayArea copies the colours every
; pass, so the cell shows magenta until DrawMarkedChars draws its characters
; again with their own colours (the next pass, as the mark is still 1).
;
; From BeamReceiver (`$8FAC`) and BeamBackToLaser. 6539 runs.
;
; Witness: L1 7147 (hof, mine, nameedit, overload, L x20, rzx x55).
HighlightCell:
  LD A,(HighlightY)
  DEC A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,(HighlightX)
  DEC A
  ADD A,L
  LD L,A
  LD BC,ColourBuffer             ; ColourBuffer + 32 (y - 1) + x - 1
  ADD HL,BC
  PUSH HL
  LD A,$43                ; the four colours $43
  LD (HL),A
  INC L
  LD (HL),A
  LD BC,$001F
  ADD HL,BC
  LD (HL),A
  INC L
  LD (HL),A
  POP HL                  ; DrawMarks (three pages down): 2
  DEC H
  DEC H
  DEC H
  LD A,$02
  LD (HL),A
  INC L
  LD (HL),A
  ADD HL,BC
  LD (HL),A
  INC L
  LD (HL),A
  RET

; A mirror: BeamNextDirection = (code - 1 - BeamDirection + 8) AND 15,
; BeamReflected; on to $906E
;
; C = code - 1, the mirror's angle 0-15 (`$01` upright: an east beam goes back
; west; `$05` an east beam goes up; `$09` lies along the east-west axis). The
; new direction is (16 - direction + C + 8) AND 15: the reflection of the beam
; in a mirror line turned C x 11.25 degrees from upright. BeamReflected =
; `$FF`; then `$906E`.
;
; From BeamStep (`$8F1A`).
;
; Witness: L1 218110 (c1, c1g, cheat, controls, energy, energy-out, hof,
; kempston, menu, mine, nameedit, overload, practice, L x20, rzx x58).
BeamMirror:
  LD C,A
  DEC C
  LD A,(BeamDirection)
  LD B,A
  LD A,$10
  SUB B
  ADD A,C
  ADD A,$08
  AND $0F
  LD (BeamNextDirection),A
  LD A,$FF
  LD (BeamReflected),A
  JP BeamVertex

; The prism ($42): the beam leaves in a random direction, up to four sixteenths
; either side
;
; Jumped to by the trace `$8EDD` (at `$8F34`) when the vertex is the centre of
; a prism cell (code `$42`, the grey grid). It takes a 16-bit number from the
; generator `$8E15` (HL) and turns the beam: when bit 7 of H is set the new
; direction `$8ECC` = (direction `$8ECB` + 4 - (H AND 7)) AND 15, else
; (direction - 4 + (H AND 7)) AND 15, so the beam leaves 4 to 12 sixteenths off
; its reverse, never straight back: 4 and 12 sixteenths away from the arrival
; come from one case each, the seven between from both.
;
; It skips the drawing of this vertex (`BeamVertex` `$906E`) and goes straight
; to the move `$9226`: the beam is not drawn over the prism's centre. A prism
; is turned anew on every pass of the trace, so its beam flickers from pass to
; pass (the generator advances on every call).
;
; Experiment: `work/ann/02-beam/prism.py` puts a prism in the beam of level 1
; (`play0.bin`, the beam arriving westwards, direction 8) and traces with 64
; seeds of `$8E32`: the beam leaves in the directions 4-12 only.
;
; Witness: L1 16015 (L x8, rzx x20).
PrismTurn:
  CALL Random
  LD A,(BeamDirection)
  BIT 7,H
  JR Z,PrismTurnBack
  ADD A,$04               ; H bit 7 set: direction + 4 - (H AND 7)
  LD B,A
  LD A,H
  AND $07
  LD H,A
  LD A,B
  SUB H
  AND $0F
  LD (BeamNextDirection),A
  JP BeamNewDirection
PrismTurnBack:
  SUB $04                 ; H bit 7 clear: direction - 4 + (H AND 7)
  LD B,A
  LD A,H
  AND $07
  ADD A,B
  AND $0F
  LD (BeamNextDirection),A ; the new direction; move on without drawing the
                           ; prism's vertex
  JP BeamNewDirection

; A fibre-optic end ($4F-$57): find the paired end and arm the jump to it
;
; Jumped to by the trace `$8EDD` (at `$8F26`) with A = the cell code
; (`$4F`-`$57`, bit 7 cleared) at the centre of a fibre-optic cell. The pair of
; an end is the code with bit 0 flipped (`$50`/`$51`, `$52`/`$53`, `$54`/`$55`,
; `$56`/`$57`; each level holds each code at most once). `$8ED1` = 2 marks the
; entry.
;
; The search runs backwards over the level grid from its last cell `$FDB9` (row
; 8, column 14), 9 rows of 15 cells, skipping the two guard bytes of each
; 17-byte row. Found: the partner's vertex is kept in `$8ECF` (x = 2 x column +
; 2) and `$8ED0` (y = 2 x row + 2), the centre of its cell in the trace's
; character units. Then the vertex is drawn (`$906E`), and at its end (`$91C6`)
; the beam is moved to the partner and leaves it in its arrival direction. Not
; found: the beam stops here (`$8ECC` = `$FF`; known only from the code, no
; level lacks a partner).
;
; Experiment: `work/ann/02-beam/elements.py 50 7 1 51 2 5` (a `$50` in the beam
; of level 1, its `$51` at row 2 column 5): the beam enters at x 4 y 16 going
; west and leaves the partner at x 12 y 6 going west.
;
; Witness: L1 4105 (L x6, rzx x15).
FibreEntry:
  XOR $01                 ; D = the partner's code
  LD D,A
  LD A,$02                ; $8ED1 = 2: the beam enters a fibre at this vertex
  LD (BeamY+$0003),A
  LD HL,LevelGrid+185             ; HL = the grid's last cell (row 8, column 14)
  LD C,$09
FibreSearchRow:
  LD B,$0F                ; B = 15 cells a row
FibreSearchCell:
  LD A,(HL)
  CP D
  JR Z,FibrePartner
  DEC L
  DJNZ FibreSearchCell
  DEC HL                  ; skip the row's two guard bytes
  DEC HL
  DEC C
  JR NZ,FibreSearchRow
FibreNoPartner:
  LD A,$FF                ; no partner: the beam ends here
  LD (BeamNextDirection),A
  JP BeamVertex
FibrePartner:
  LD A,B                  ; the partner's vertex: x = 2B, y = 2C
  ADD A,A
  LD (BeamY+$0001),A
  LD A,C
  ADD A,A
  LD (BeamY+$0002),A
  JP BeamVertex

; Draw the beam round one vertex in three passes, then take the outgoing
; direction
;
; The heart of the beam: reached from the trace `$8EDD` for every vertex once
; the cell at the vertex (if any) has set the outgoing direction `$8ECC` (= the
; incoming one by default), and from the fibre jump and the slanted wall
; reflection (`$96B5`). A vertex is a corner of four characters of the play
; area, x = `$8ECD` (0-`$20`), y = `$8ECE` (0-`$14`); the centre of the cell at
; column c, row r is x = 2c + 2, y = 2r + 2.
;
; It clears the per-vertex flags `$8EC3`-`$8EC8`, stops the trace (`$8ECC` =
; `$FF`) on the play area's edge (x 0 or `$20`, y 0 or `$14`: the vertex is
; still drawn), and keeps two pointers to the character up and left of the
; vertex: `$8914` into the character map `$E000` (`$DFDF` + 32y + x) and
; `$8916` into the pixel buffer `$E900` (`$E7FF` + 256y + x).
;
; The glyphs come from the table `$8000`: four bytes for each direction and set
; (E = 4 x direction + `$8381`, D = `$80`; `$8381` is `$40` on the flashing
; frames of the warning set by `$A623`), one byte for each of the four
; characters round the vertex (up-left, up-right, down-left, down-right). Bits
; 7-6 of the byte say which pass draws it, bits 5-0 are the glyph (`$D500` + 8
; x glyph): 00 the incoming pass `BeamInChar` `$9278`, bit 7 the corner pass
; `BeamCornerChar` `$9440` (the characters a slanted beam cuts through a
; corner), bit 6 the outgoing pass `BeamOutChar` `$94FD`.
;
; 1. The incoming pass with the incoming direction `$8ECB` (none when it is
; `$FF`: after a fibre jump or a wall's turn). 2. The corner pass with the same
; bytes, but only for the characters inside the play area. 3. When the new
; direction is the reverse of the incoming one (a mirror at right angles, a
; wall hit head on), the beam goes back into the laser: `$8FC5` (OVERLOAD,
; `$8ED5` = `$FF`) and the trace ends. 4. At a fibre entry (`$8ED1` = 2) the
; vertex moves to the partner's (`$91C6`) and the vertex is drawn again with no
; incoming pass. 5. The outgoing pass with the new direction, then the move
; (`BeamStep` `$9226`).
;
; Any pass may end the trace on a wall or an absorbing polariser (its handler
; drops the return addresses and returns from the trace). 1 046 773 vertices
; drawn over all recordings (c1g, controls, energy, kempston, menu, mine,
; overload and the 59 RZX level segments).
;
; Witness: L1 1276460 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamVertex:
  XOR A                   ; clear the per-vertex flags $8EC3-$8EC8
  LD (BeamReflected+$0001),A
  LD (BeamReflected+$0002),A
  LD (BeamReflected+$0003),A
  LD (BeamReflected+$0004),A
  LD (BeamReflected+$0005),A
  LD (BeamReflected+$0006),A
  LD A,(BeamX)            ; C = x; beyond $20: no vertex
  LD C,A
  CP $21
  RET NC
  DEC A                   ; x 0 or $20: the beam ends here
  CP $1F
  JR C,BeamVertexY
  LD A,$FF
  LD (BeamNextDirection),A
BeamVertexY:
  LD A,(BeamY)            ; B = y; beyond $14: no vertex
  LD B,A
  CP $15
  RET NC
  DEC A
  CP $13
  JR C,BeamVertexPointers
  LD A,$FF                ; y 0 or $14: the beam ends here
  LD (BeamNextDirection),A
BeamVertexPointers:
  LD HL,$E7FF             ; $8916 = the pixel buffer at the up-left character
  ADD HL,BC
  LD (PixelPointer),HL
  LD L,B                  ; $8914 = the character map at the up-left character
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,$DFDF
  ADD HL,DE
  LD B,$00
  ADD HL,BC
  LD (CharMapPointer),HL
  LD A,(BeamDirection)    ; incoming direction $FF: no incoming pass
  CP $FF
  JP Z,BeamOutgoing
  ADD A,A                 ; DE = $8000 + 4 x direction + $8381: the four glyph
                          ; bytes
  ADD A,A
  LD E,A
  LD A,(BeamGlyphSet)
  ADD A,E
  LD E,A
  LD D,$80
  CALL BeamInChar         ; the incoming pass: up-left, up-right, down-left,
                          ; down-right
  LD HL,(CharMapPointer)
  INC HL
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  INC HL
  LD (PixelPointer),HL
  CALL BeamInChar
  LD HL,(CharMapPointer)
  LD BC,$001F
  ADD HL,BC
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  LD BC,$00FF
  ADD HL,BC
  LD (PixelPointer),HL
  CALL BeamInChar
  LD HL,(CharMapPointer)
  INC HL
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  INC HL
  LD (PixelPointer),HL
  CALL BeamInChar
  LD HL,(CharMapPointer)
  LD BC,$FFDF
  ADD HL,BC
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  LD BC,Im2Table+255
  ADD HL,BC
  LD (PixelPointer),HL
  DEC E                   ; back to the first glyph byte for the corner pass
  DEC E
  DEC E
  DEC E
  LD A,(BeamX)            ; the corner pass: up-left unless on the top or left
                          ; edge
  AND A
  JR Z,BeamCornerUpRight
  LD A,(BeamY)
  AND A
  JR Z,BeamCornerUpRight
  CALL BeamCornerChar
BeamCornerUpRight:
  LD HL,(CharMapPointer)  ; up-right unless on the top or right edge
  INC HL
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  INC HL
  LD (PixelPointer),HL
  INC E
  LD A,(BeamY)
  AND A
  JR Z,BeamCornerDownLeft
  LD A,(BeamX)
  CP $20
  JR Z,BeamCornerDownLeft
  CALL BeamCornerChar
BeamCornerDownLeft:
  LD HL,(CharMapPointer)  ; down-left unless on the bottom or left edge
  LD BC,$001F
  ADD HL,BC
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  LD BC,$00FF
  ADD HL,BC
  LD (PixelPointer),HL
  INC E
  LD A,(BeamX)
  AND A
  JR Z,BeamCornerDownRight
  LD A,(BeamY)
  CP $14
  JR Z,BeamCornerDownRight
  CALL BeamCornerChar
BeamCornerDownRight:
  LD HL,(CharMapPointer)  ; down-right unless on the bottom or right edge
  INC HL
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  INC HL
  LD (PixelPointer),HL
  INC E
  LD A,(BeamX)
  CP $20
  JR Z,BeamCornerDone
  LD A,(BeamY)
  CP $14
  JR Z,BeamCornerDone
  CALL BeamCornerChar
BeamCornerDone:
  LD HL,(CharMapPointer)  ; back to the up-left character
  LD BC,$FFDF
  ADD HL,BC
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  LD BC,Im2Table+255
  ADD HL,BC
  LD (PixelPointer),HL
  LD A,(BeamNextDirection) ; the new direction the reverse of the incoming one:
                           ; back into the laser (OVERLOAD)
  LD B,A
  LD A,(BeamDirection)
  ADD A,$08
  AND $0F
  CP B
  JP Z,BeamBackToLaser
BeamOutgoing:
  LD A,(BeamNextDirection) ; the outgoing direction; $FF: the beam ends at this
                           ; vertex
  CP $FF
  RET Z
  LD E,A
  LD A,(BeamY+$0003)      ; a fibre entry ($8ED1 = 2)?
  CP $02
  JR C,BeamOutPass
FibreJump:
  LD A,$01                ; $8ED1 = 1: the vertex moves to the partner end, the
                          ; direction kept, no incoming pass
  LD (BeamY+$0003),A
  LD A,(BeamY+$0001)
  LD (BeamX),A
  LD A,(BeamY+$0002)
  LD (BeamY),A
  LD A,$FF
  LD (BeamDirection),A
  JP BeamVertex
BeamOutPass:
  LD A,E                  ; DE = $8000 + 4 x the new direction + $8381: the
                          ; outgoing pass, four characters
  ADD A,A
  ADD A,A
  LD E,A
  LD A,(BeamGlyphSet)
  ADD A,E
  LD E,A
  LD D,$80
  CALL BeamOutChar
  LD HL,(CharMapPointer)
  INC HL
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  INC HL
  LD (PixelPointer),HL
  CALL BeamOutChar
  LD HL,(CharMapPointer)
  LD BC,$001F
  ADD HL,BC
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  LD BC,$00FF
  ADD HL,BC
  LD (PixelPointer),HL
  CALL BeamOutChar
  LD HL,(CharMapPointer)
  INC HL
  LD (CharMapPointer),HL
  LD HL,(PixelPointer)
  INC HL
  LD (PixelPointer),HL
  CALL BeamOutChar

; Take the new direction and move the beam to its next vertex
;
; Falls in from `BeamVertex` `$906E`, and is jumped to by `PrismTurn` `$9014`.
; The new direction `$8ECC` becomes the direction `$8ECB`; `$FF` ends the
; trace. HL = the step of the direction in the table `$8170` (two bytes a
; direction, dx then dy: `$02,$00` for 0 (east), `$02,$01`, `$01,$01`,
; `$01,$02`, `$00,$02` for 4 (south), and so on round to `$02,$FF` for 15): a
; step is one cell (two characters) along the axes, a character on the
; diagonals, and two by one on the eight slopes between, so the 16 directions
; are 22.5 degrees apart only roughly (26.6 and 63.4 degrees for the slopes).
;
; Falls into `BeamMove` `$9235`.
;
; Witness: L1 1108934 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamNewDirection:
  LD A,(BeamNextDirection)
  LD (BeamDirection),A
  CP $FF
  RET Z
  ADD A,A
  LD HL,BeamDeltas
  ADD A,L
  LD L,A

; Move the vertex by the step at HL, count the beam's length, trace on
;
; Entered from `BeamNewDirection` (the step of the direction) and from the
; reflections of `BeamReflectIn` `$938F` with HL at a step of their own tables
; (`$8140`, `$8100`). x + dx must stay below `$21` and y + dy below `$15` (a
; negative result is above too): else the trace ends.
;
; The length `$8EBF` counts the steps, the diagonal ones (directions 2, 6, 10,
; 14, one character a step) only at even x, so it counts about one a cell. At a
; length of 40 (`$28`) the trace calls `$8FC5`: OVERLOAD (`$8ED5` = `$FF`) as
; if the beam had come back into the laser, and the laser lit; the trace still
; goes on, up to 150 (`$96`) steps, then stops. So a beam longer than 40 cells
; overloads the laser on every pass (the RZX segments reach 40 in 14 of the 59
; level segments, `$926D` 2010 runs in all).
;
; Then back to the trace `$8EDD` for the next vertex.
;
; Witness: L1 1139437 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamMove:
  LD A,(BeamX)            ; B = x, C = y
  LD B,A
  LD A,(BeamY)
  LD C,A
  LD A,(HL)               ; x + dx: off the area ($21 or more, or below 0): the
                          ; trace ends
  ADD A,B
  CP $21
  RET NC
  LD (BeamX),A
  INC L
  LD A,(HL)               ; y + dy: off the area: the trace ends
  ADD A,C
  CP $15
  RET NC
  LD (BeamY),A
  LD A,(BeamDirection)    ; the diagonals (2, 6, 10, 14) count at even x only
  DEC A
  DEC A
  AND $03
  JR NZ,BeamCountStep
  LD A,(BeamX)
  BIT 0,A
  JR Z,BeamLengthCheck
BeamCountStep:
  LD A,(BeamSteps)        ; length + 1
  INC A
  LD (BeamSteps),A
BeamLengthCheck:
  LD A,(BeamSteps)        ; under 40: the next vertex
  CP $28
  JP C,BeamStep
  LD D,A                  ; exactly 40: OVERLOAD, as if back in the laser
  CALL Z,BeamBackToLaser
  LD A,D                  ; under 150: the next vertex; else the beam stops
  CP $96
  JP C,BeamStep
  RET

; The incoming pass: one character round the vertex, its glyph, the walls and
; the polarisers it meets
;
; Called four times by `BeamVertex` `$906E` with DE at the glyph byte of the
; character (`$8000` table) and `$8914` / `$8916` at the character. A byte with
; bit 7 or 6 set is not this pass's: nothing drawn, only the colour of the next
; step (`BeamInNext` `$92DE`). `$8EC4` counts the characters of this pass
; (1-4).
;
; At a cell's centre (`$8EC1` set by the trace, not for polarisers) only the
; walls count: `$71` absorbs (`BeamAbsorbIn` `$9344`), `$72` reflects
; (`BeamReflectIn` `$938F`), anything else is drawn over: the beam crosses the
; element's own characters. Elsewhere, by the character in the map: 0 drawn;
; `$01`-`$30` (a mirror's art) and `$7C`-`$7F` (a prism's), `$B0` and up (fibre
; ends, the explosion) not drawn; `$31`-`$70` a polariser (`$92FD`); `$71`
; absorbs, `$72` reflects; `$73`-`$7B` (cells, mines) drawn; `$80`-`$AF` (the
; laser, the receiver) absorb.
;
; Witness: L1 4870383 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamInChar:
  LD A,(DE)
  LD C,A
  PUSH DE
  LD HL,(CharMapPointer)
  AND $C0                 ; bit 7 or 6: not the incoming pass's glyph
  JR NZ,BeamInNext
  LD A,(BeamReflected+$0002) ; count the characters of this pass ($8EC4)
  INC A
  LD (BeamReflected+$0002),A
  LD A,(BeamAtCentre)     ; at a cell's centre: only the walls stop the beam
  AND A
  JR NZ,BeamInOnCell
  LD A,(HL)               ; the character in the map
  AND A
  JR Z,BeamPlotGlyph
  CP $31
  JR C,BeamInNext
  CP $71
  JR C,BeamInPolariser
  CP $B0
  JR NC,BeamInNext
  CP $80
  JP NC,BeamAbsorbIn
  CP $7C
  JR NC,BeamInNext
BeamInOnCell:
  LD A,(HL)               ; $71: an absorbing wall; $72: a reflecting wall
  CP $71
  JP Z,BeamAbsorbIn
  CP $72
  JP Z,BeamReflectIn

; Draw a beam glyph into the pixel buffer: mark the character and colour it
;
; Falls in from `BeamInChar` `$9278`, jumped to by the polariser's pass
; `$9341`. The character gets the draw mark 2 (`$E300`, so `$8A09` copies it)
; and the colour `$43` (bright magenta on black, `$E600`); the glyph C (`$D500`
; + 8C) is ORed into the eight pixel rows at `$8916`, whose address is kept in
; `$8EC9`: a wall met at the next character of the pass erases it (`$9381`).
;
; Falls into `BeamInNext` `$92DE`.
;
; Witness: L1 1533825 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamPlotGlyph:
  INC H                   ; the draw mark: $E300
  INC H
  INC H
  LD (HL),$02
  INC H                   ; the colour: $E600, bright magenta
  INC H
  INC H
  LD (HL),$43
  LD L,C                  ; DE = the glyph $D500 + 8C
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,BeamGlyphs
  ADD HL,DE
  LD DE,(PixelPointer)    ; $8EC9 = the pixel address of the last glyph drawn
  LD (BeamReflected+$0007),DE
  EX DE,HL
  LD B,$08
BeamPlotRows:
  LD A,(DE)               ; OR eight rows, 32 bytes apart
  OR (HL)
  LD (HL),A
  INC E
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ BeamPlotRows

; The next glyph byte; light the character on a mirror or at a fibre entry
;
; The common end of the incoming pass (`BeamInChar` `$9278`, `BeamPlotGlyph`,
; the walls when they let the beam by). DE moves to the next glyph byte. When
; the vertex is the centre of a mirror (`$8EC2` set by `$8FFB`) the character
; is coloured `$43` and marked: the mirror the beam bounces off lights up in
; the beam's colour. At a fibre entry (`$8ED1` = 2) it takes `$7B` (bright,
; white paper, magenta ink).
;
; The entry point `$92FD` is the polariser: the polariser's angle is (character
; - `$31`) AND `$1F` / 4 (eight angles, four characters each, `$31`-`$50` the
; cyan ones of cells `$11`-`$18`, `$51`-`$70` the yellow ones of `$19`-`$20`).
; A beam whose direction AND 7 is the angle (along its axis, either way)
; passes: three more characters round the cell get the mark and the colour
; (offsets `$81A0`, six bytes for each of the four characters) and the glyph is
; drawn. Otherwise a cyan polariser absorbs (`BeamAbsorbIn`) and a yellow one
; reflects (`BeamReflectIn`).
;
; Experiment (`elements.py`, the beam going west through row 7 column 1 of
; level 1): `$11` and `$19` (angle 0) pass it, `$13` (angle 2) absorbs it,
; `$1B` (angle 2) sends it back into the laser (OVERLOAD).
;
; Witness: L1 4831391 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamInNext:
  POP DE
  INC E                   ; the next glyph byte
  LD B,$43                ; B = $43: lit on a mirror
  LD A,(BeamReflected)
  AND A
  JR NZ,BeamLightChar
  LD A,(BeamY+$0003)      ; at a fibre entry: B = $7B
  CP $02
  RET NZ
  LD B,$7B
BeamLightChar:
  LD HL,(CharMapPointer)  ; mark the character and give it colour B
  INC H
  INC H
  INC H
  LD (HL),$02
  INC H
  INC H
  INC H
  LD (HL),B
  RET
; This entry point is used by the routine at BeamInChar.
BeamInPolariser:
  LD D,A                  ; B = the polariser's angle (0-7)
  SUB $31
  AND $1F
  SRL A
  SRL A
  LD B,A
  LD A,(BeamDirection)    ; the beam along the axis passes
  AND $07
  CP B
  JR Z,PolariserPassIn
  LD A,D                  ; else: cyan ($31-$50) absorbs, yellow ($51-$70)
                          ; reflects
  CP $51
  JR C,BeamAbsorbIn
  JP BeamReflectIn
PolariserPassIn:
  PUSH BC                 ; the three other characters of the cell: marked and
                          ; lit ($81A0 + 6 x (character AND 3))
  PUSH HL
  LD A,D
  AND $03
  ADD A,A
  LD B,A
  ADD A,A
  ADD A,B
  LD HL,PolariserCells
  ADD A,L
  LD L,A
  LD BC,(CharMapPointer)
  INC B
  INC B
  INC B
  LD A,$03
PolariserMarkLoop:
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  EX DE,HL
  ADD HL,BC
  LD (HL),$02
  INC H
  INC H
  INC H
  LD (HL),$43
  EX DE,HL
  DEC A
  JR NZ,PolariserMarkLoop
  POP HL
  POP BC
  JP BeamPlotGlyph        ; and the glyph drawn

; The incoming beam meets an absorbing wall ($71), a cyan polariser across it,
; the laser or the receiver
;
; From `BeamInChar` `$9278` and the polariser test `$92FD`. A beam on the
; slopes or diagonals (direction AND 3 not 0) is absorbed at once. A beam along
; an axis, at its first wall character of the vertex (`$8EC3`), runs between
; two characters: the one across the beam from this one (offsets `$8190`, one
; word for each character and axis) must be a wall or a polariser too
; (`$31`-`$72`), else the beam grazes the wall's side and goes on
; (`BeamInNext`). When it is, and this is not the first character of the pass,
; the glyph drawn last (`$8EC9`) is wiped with the blank character `$D700`.
;
; Absorbed: the two return addresses are dropped and the trace returns to
; MainPass: the beam ends here.
;
; Experiment (`elements.py`): a full absorbing wall `$2F` ends the beam
; (`absorb-in`); a single quarter `$21` is grazed and the beam goes on.
;
; Witness: L1 9309 (c1, c1g, L x10, rzx x29).
BeamAbsorbIn:
  LD A,(BeamDirection)    ; slope or diagonal: absorbed at once
  LD B,A
  AND $03
  JR NZ,AbsorbInEnd
  LD A,(BeamReflected+$0001) ; second wall character of the vertex: absorbed
  AND A
  JR NZ,AbsorbInEnd
  INC A
  LD (BeamReflected+$0001),A
  EX DE,HL                ; the character across the beam ($8190 + 2 x (pass
                          ; count - 1) + direction)
  LD HL,GrazeOffsets
  LD A,(BeamReflected+$0002)
  DEC A
  ADD A,A
  ADD A,B
  ADD A,L
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  EX DE,HL
  ADD HL,BC
  LD A,(HL)               ; not a wall or polariser: grazed, the beam goes on
  CP $31
  JP C,BeamInNext
  CP $73
  JP NC,BeamInNext
  LD A,(BeamReflected+$0002) ; first character of the pass: nothing to wipe
  CP $02
  JR C,AbsorbInEnd
  LD HL,(BeamReflected+$0007) ; wipe the last glyph with the blank character
  LD DE,CellGraphics
  LD B,$08
AbsorbInWipe:
  LD A,(DE)
  LD (HL),A
  INC E
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ AbsorbInWipe
AbsorbInEnd:
  POP DE                  ; drop the return addresses: the trace ends
  POP DE
  RET

; The incoming beam meets a reflecting wall ($72) or a yellow polariser across
; it
;
; From `BeamInChar` `$9278` and the polariser test `$92FD`. Along an axis the
; test is the absorbing wall's (`$9344`): grazed when the character across is
; free; else the beam goes straight back, which is the laser's OVERLOAD
; (`$8FC5`), and the trace ends (the second wall character of a vertex too).
;
; On a slope or diagonal it bounces (`$93DC`): the table `$8140` (three bytes a
; direction: the new direction, dx, dy) gives a slope's mirror image off the
; wall it can meet (1, 7, 9, 15 off an upright wall: 1 to 7, 7 to 1, 9 to 15,
; 15 to 9; 3, 5, 11, 13 off a level one: 3 to 13 and so on) and the step to the
; vertex it leaves from; a diagonal (bit 7 of the first byte) reads `$8100` +
; 16 x n: two words, the characters above and to the side of the corner, and
; four answers by which of them are walls: none or both send it back (the trace
; then sees the reverse direction and OVERLOADs), one turns it a quarter. If
; the new direction is the reverse: OVERLOAD. Then `BeamMove` `$9235` with that
; step.
;
; The diagonal branch `$93F2` ran in no play, only on the clone `corner`
; (InCornerTable `$8100`); the slope branch ran 21 949 times in 33 RZX
; segments.
;
; Experiment (`elements.py`): a full reflecting wall `$3E` and a yellow
; polariser across the beam (`$1B`) send the westward beam of level 1 straight
; back: `$8ED5` = `$FF`.
;
; Witness: L1 35456 (c1, c1g, cheat, corner, hof, nameedit, L x9, rzx x33).
BeamReflectIn:
  LD A,(BeamDirection)    ; slope or diagonal: bounce off
  LD B,A
  AND $03
  JR NZ,ReflectInSlant
  LD A,(BeamReflected+$0001) ; second wall character of the vertex: back into
                             ; the laser
  AND A
  JR NZ,ReflectInBack
  INC A
  LD (BeamReflected+$0001),A
  EX DE,HL                ; the character across the beam ($8190)
  LD HL,GrazeOffsets
  LD A,(BeamReflected+$0002)
  DEC A
  ADD A,A
  ADD A,B
  ADD A,L
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  EX DE,HL
  ADD HL,BC
  LD A,(HL)               ; not a wall or polariser: grazed, the beam goes on
  CP $31
  JP C,BeamInNext
  CP $73
  JP NC,BeamInNext
  LD A,(BeamReflected+$0002) ; wipe the last glyph unless this is the pass's
                             ; first character
  CP $02
  JR C,ReflectInBack
  LD HL,(BeamReflected+$0007)
  LD DE,CellGraphics
  LD B,$08
ReflectInWipe:
  LD A,(DE)
  LD (HL),A
  INC E
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ ReflectInWipe
ReflectInBack:
  POP DE                  ; head on: back into the laser (OVERLOAD), the trace
                          ; ends
  POP DE
  JP BeamBackToLaser
ReflectInSlant:
  POP DE                  ; the bounce: $8140 + 3 x direction
  POP DE
  LD HL,InBounceTable
  LD A,B
  ADD A,A
  ADD A,B
  ADD A,L
  LD L,A
  LD A,(HL)
  BIT 7,A
  JR NZ,ReflectInCorner
  LD (BeamDirection),A    ; a slope: the new direction, then the step at HL
  INC L
  JP BeamMove
ReflectInCorner:
  RES 7,A                 ; a diagonal: $8100 + n, two neighbours to test
  LD HL,InCornerTable
  ADD A,L
  LD L,A
  EX DE,HL
  XOR A
  EX AF,AF'
  LD BC,(CharMapPointer)
  LD A,(DE)
  INC E
  LD L,A
  LD A,(DE)
  INC E
  LD H,A
  ADD HL,BC
  LD A,(HL)
  CP $31
  JR C,ReflectInCorner2
  CP $73
  JR NC,ReflectInCorner2
  EX AF,AF'
  ADD A,$03
  EX AF,AF'
ReflectInCorner2:
  LD A,(DE)
  INC E
  LD L,A
  LD A,(DE)
  INC E
  LD H,A
  ADD HL,BC
  LD A,(HL)
  CP $31
  JR C,ReflectInPick
  CP $73
  JR NC,ReflectInPick
  EX AF,AF'
  ADD A,$06
  EX AF,AF'
ReflectInPick:
  EX AF,AF'               ; +3 / +6 by the walls found: the new direction and
                          ; its step
  ADD A,E
  LD E,A
  LD A,(BeamDirection)
  LD B,A
  LD A,(DE)
  LD (BeamDirection),A
  ADD A,$08
  AND $0F
  CP B                    ; straight back: OVERLOAD
  JP Z,BeamBackToLaser
  EX DE,HL                ; else move with the step
  INC L
  JP BeamMove

; The corner pass: the characters a slanted beam cuts through at a corner
;
; Called up to four times by `BeamVertex` `$906E` (the characters inside the
; play area) with DE at the glyph byte; only bytes with bit 7 set are this
; pass's (the slopes and diagonals: the beam crosses the corner of a character
; beside the vertex). Its glyph (bit 7 cleared) is ORed into the pixel buffer
; with the mark 2 and, on an empty character, the colour `$43`.
;
; By the character: 0 drawn and lit; `$01`-`$30` (mirrors) and `$7C` and up not
; drawn; a polariser (`$949C`) along the beam's axis is drawn only when the
; character is already lit (`$E600` = `$43`); across it, a cyan polariser's
; character counts as an absorbing corner and a yellow one's as a reflecting
; corner; `$71` and `$72` corners (`$94C4`, `$94D9`): the first one is passed;
; a second absorbing corner ends the beam; two corners of which one reflects
; turn it by the fourth byte of the direction's row of `$8080` (`$94E9`),
; mostly straight back (the OVERLOAD of `$91A9`). At a cell's centre (`$8EC1`)
; walls only, as in the incoming pass.
;
; Witness: L1 4597599 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamCornerChar:
  LD A,(DE)
  LD C,A
  PUSH DE
  LD HL,(CharMapPointer)
  BIT 7,A                 ; bit 7 clear: not the corner pass's glyph
  JR Z,BeamCornerNext
  LD A,(BeamAtCentre)
  AND A
  JR NZ,BeamCornerOnCell
  LD A,(HL)               ; the character in the map
  AND A
  JR Z,BeamCornerLit
  CP $31
  JR C,BeamCornerNext
  CP $71
  JR C,BeamCornerPolariser
  CP $7C
  JR NC,BeamCornerNext
BeamCornerOnCell:
  LD A,(HL)               ; $B0 and up: drawn, not lit; $71 / $72: the wall
                          ; corners
  CP $B0
  JR NC,BeamCornerPlot
  CP $71
  JR Z,BeamCornerAbsorb
  CP $72
  JR Z,BeamCornerReflect
BeamCornerLit:
  LD A,H                  ; colour $43
  ADD A,$06
  LD H,A
  LD (HL),$43
BeamCornerPlot:
  LD HL,(CharMapPointer)  ; mark 2, glyph (bit 7 cleared) ORed in
  INC H
  INC H
  INC H
  LD (HL),$02
  RES 7,C
  LD L,C
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,BeamGlyphs
  ADD HL,DE
  LD DE,(PixelPointer)
  EX DE,HL
  LD B,$08
BeamCornerRows:
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC E
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ BeamCornerRows
BeamCornerNext:
  POP DE
  RET
BeamCornerPolariser:
  LD D,A                  ; along the axis: drawn when the first pass lit the
                          ; character
  SUB $31
  AND $1F
  SRL A
  SRL A
  LD B,A
  LD A,(BeamDirection)
  AND $07
  CP B
  JR Z,BeamCornerPolariserPass
  LD A,D
  CP $51
  JR C,BeamCornerAbsorb
  JP BeamCornerReflect
BeamCornerPolariserPass:
  LD B,H
  LD A,H
  ADD A,$06
  LD H,A
  LD A,(HL)
  LD H,B
  CP $43
  JR Z,BeamCornerLit
  JP BeamCornerNext
BeamCornerAbsorb:
  LD A,(BeamReflected+$0003) ; an absorbing corner ($8EC5): the second one ends
                             ; the beam
  AND A
  JR NZ,BeamCornerAbsorbed
  INC A
  LD (BeamReflected+$0003),A
  LD A,(BeamReflected+$0004)
  AND A
  JR NZ,BeamCornerTurn
  JR BeamCornerNext
BeamCornerAbsorbed:
  POP DE                  ; drop the return addresses: the trace ends
  POP DE
  RET
BeamCornerReflect:
  LD A,(BeamReflected+$0004) ; a reflecting corner ($8EC6)
  AND A
  JR NZ,BeamCornerTurn
  INC A
  LD (BeamReflected+$0004),A
  LD A,(BeamReflected+$0003)
  AND A
  JR Z,BeamCornerNext
BeamCornerTurn:
  LD HL,OutBounceTable    ; two corners met: the new direction = byte 7 of
                          ; $8080 + 8 x direction
  LD A,(BeamDirection)
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$07
  ADD A,L
  LD L,A
  LD A,(HL)
  LD (BeamNextDirection),A
  JP BeamCornerNext

; The outgoing pass: one character round the vertex in the new direction
;
; Called four times by `BeamVertex` (at `$91EA`) with DE at the glyph byte of
; the new direction; only bytes with bit 6 set are this pass's (the half of the
; beam that leaves the vertex). `$8EC8` counts its characters. The tests mirror
; the incoming pass's (`BeamInChar` `$9278`): at a cell's centre only the
; walls; elsewhere 0 drawn, mirrors' and prisms' characters skipped, polarisers
; (`$957A`), `$71` and the laser / receiver characters absorb (`BeamAbsorbOut`
; `$95C2`), `$72` reflects (`BeamReflectOut` `$960D`). The polariser test
; compares the direction `$8ECB`, not the new one `$8ECC`; after a bounce in
; place (`$96A7`) `$8ECB` is `$FF`, so a polariser's character beside that
; vertex is judged as if the beam ran at angle 7 (known only from the code).
;
; Witness: L1 4498406 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamOutChar:
  LD A,(DE)
  LD C,A
  PUSH DE
  LD HL,(CharMapPointer)
  BIT 6,A                 ; bit 6 clear: not the outgoing pass's glyph
  JR Z,BeamOutNext
  LD A,(BeamReflected+$0006) ; count the characters of this pass ($8EC8)
  INC A
  LD (BeamReflected+$0006),A
  LD A,(BeamAtCentre)     ; at a cell's centre: only the walls stop the beam
  AND A
  JR NZ,BeamOutOnCell
  LD A,(HL)               ; the character in the map
  AND A
  JR Z,BeamOutPlot
  CP $31
  JR C,BeamOutNext
  CP $71
  JR C,BeamOutPolariser
  CP $B0
  JR NC,BeamOutNext
  CP $80
  JP NC,BeamAbsorbOut
  CP $7C
  JR NC,BeamOutNext
BeamOutOnCell:
  LD A,(HL)               ; $71: absorbing; $72: reflecting
  CP $71
  JP Z,BeamAbsorbOut
  CP $72
  JP Z,BeamReflectOut

; Draw an outgoing glyph: mark, colour $43, OR the glyph in
;
; As `BeamPlotGlyph` `$92B3` for the outgoing pass (glyph = the byte with bit 6
; cleared); the pixel address is kept in `$8EC9`. Falls into `BeamOutNext`
; `$9565`.
;
; Witness: L1 1357897 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamOutPlot:
  INC H
  INC H
  INC H
  LD (HL),$02
  INC H
  INC H
  INC H
  LD (HL),$43
  RES 6,C                 ; the glyph: bit 6 cleared
  LD L,C
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,BeamGlyphs
  ADD HL,DE
  LD DE,(PixelPointer)
  LD (BeamReflected+$0007),DE
  EX DE,HL
  LD B,$08
BeamOutRows:
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC E
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ BeamOutRows

; The next outgoing glyph byte; at a fibre end colour the character $7B
;
; The common end of the outgoing pass. While `$8ED1` is not 0 (a fibre entry,
; 2, or the partner end after the jump, 1) the character gets the colour `$7B`.
; The entry point `$957A` is the outgoing pass's polariser: passes along the
; axis (three characters marked through `$81A0`, then `BeamOutPlot`), else cyan
; absorbs, yellow reflects.
;
; Witness: L1 4448984 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
BeamOutNext:
  POP DE
  INC E                   ; the next glyph byte
  LD A,(BeamY+$0003)
  AND A
  RET Z
  LD HL,(CharMapPointer)  ; a fibre end: colour $7B
  INC H
  INC H
  INC H
  LD (HL),$02
  INC H
  INC H
  INC H
  LD (HL),$7B
  RET
; This entry point is used by the routine at BeamOutChar.
BeamOutPolariser:
  LD D,A                  ; B = the polariser's angle; compared with $8ECB, not
                          ; the new direction
  SUB $31
  AND $1F
  SRL A
  SRL A
  LD B,A
  LD A,(BeamDirection)
  AND $07
  CP B
  JP Z,PolariserPassOut
  LD A,D                  ; across: cyan absorbs, yellow reflects
  CP $51
  JR C,BeamAbsorbOut
  JP BeamReflectOut
PolariserPassOut:
  PUSH BC                 ; the three other characters marked and lit
  PUSH HL
  LD A,D
  AND $03
  ADD A,A
  LD B,A
  ADD A,A
  ADD A,B
  LD HL,PolariserCells
  ADD A,L
  LD L,A
  LD BC,(CharMapPointer)
  INC B
  INC B
  INC B
  LD A,$03
PolariserPassOutLoop:
  LD E,(HL)
  INC L
  LD D,(HL)
  INC L
  EX DE,HL
  ADD HL,BC
  LD (HL),$02
  INC H
  INC H
  INC H
  LD (HL),$43
  EX DE,HL
  DEC A
  JR NZ,PolariserPassOutLoop
  POP HL
  POP BC
  JP BeamOutPlot

; The outgoing beam meets an absorbing wall, a cyan polariser across it, the
; laser or the receiver
;
; As `BeamAbsorbIn` `$9344` with the new direction `$8ECC` and the pass's count
; `$8EC8`: along an axis the character across (`$8190`) must be a wall too,
; else the beam grazes it; then the last glyph (`$8EC9`) is wiped unless this
; is the pass's first character, and the trace ends. On a slope or a diagonal:
; absorbed at once.
;
; Experiment (`elements.py 21`): a quarter wall `$21` at the up-left of the
; cell is reached here and grazed; the beam goes on west.
;
; Witness: L1 5864 (c1, c1g, practice, L x17, rzx x36).
BeamAbsorbOut:
  LD A,(BeamNextDirection) ; slope or diagonal: absorbed at once
  LD B,A
  AND $03
  JR NZ,AbsorbOutEnd
  LD A,(BeamReflected+$0005) ; second wall character: absorbed
  AND A
  JR NZ,AbsorbOutEnd
  INC A
  LD (BeamReflected+$0005),A
  EX DE,HL                ; the character across the beam
  LD HL,GrazeOffsets
  LD A,(BeamReflected+$0006)
  DEC A
  ADD A,A
  ADD A,B
  ADD A,L
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  EX DE,HL
  ADD HL,BC
  LD A,(HL)
  CP $31
  JP C,BeamOutNext
  CP $73
  JP NC,BeamOutNext
  LD A,(BeamReflected+$0006) ; the pass's first character: nothing to wipe
  CP $02
  JR C,AbsorbOutEnd
  LD HL,(BeamReflected+$0007)
  LD DE,CellGraphics
  LD B,$08
AbsorbOutWipe:
  LD A,(DE)
  LD (HL),A
  INC E
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ AbsorbOutWipe
AbsorbOutEnd:
  POP DE                  ; drop the return addresses: the trace ends
  POP DE
  RET

; The outgoing beam meets a reflecting wall or a yellow polariser across it
;
; Along an axis as `BeamReflectIn` `$938F`: grazed, or straight back (OVERLOAD
; `$8FC5`, the trace ends). On a slope or a diagonal (`$965A`) the row of the
; new direction in `$8080` (eight bytes: two words, the two characters to test,
; then four directions by which of them are walls, +1 the first, +2 the second)
; gives the bounced direction. Its reverse: OVERLOAD. Else the beam is turned
; in place: the direction `$8ECB` = `$FF` (no incoming pass), the bounce count
; `$8EC0` + 1, and the vertex is drawn again (`BeamVertex` `$906E`) with the
; new direction. At 40 bounces OVERLOAD, at 150 the trace ends; the bounce
; count never passed 39 in the recordings (`$96B8` never ran).
;
; Witness: L1 50666 (c1, c1g, cheat, hof, nameedit, L x9, rzx x31).
BeamReflectOut:
  LD A,(BeamNextDirection) ; slope or diagonal: bounce
  LD B,A
  AND $03
  JR NZ,ReflectOutSlant
  LD A,(BeamReflected+$0005) ; second wall character: back into the laser
  AND A
  JR NZ,ReflectOutBack
  INC A
  LD (BeamReflected+$0005),A
  EX DE,HL                ; the character across the beam
  LD HL,GrazeOffsets
  LD A,(BeamReflected+$0006)
  DEC A
  ADD A,A
  ADD A,B
  ADD A,L
  LD L,A
  LD C,(HL)
  INC L
  LD B,(HL)
  EX DE,HL
  ADD HL,BC
  LD A,(HL)
  CP $31
  JP C,BeamOutNext
  CP $73
  JP NC,BeamOutNext
  LD A,(BeamReflected+$0006) ; wipe the last glyph unless this is the pass's
                             ; first character
  CP $02
  JR C,ReflectOutBack
  LD HL,(BeamReflected+$0007)
  LD DE,CellGraphics
  LD B,$08
ReflectOutWipe:
  LD A,(DE)
  LD (HL),A
  INC E
  PUSH DE
  LD DE,$0020
  ADD HL,DE
  POP DE
  DJNZ ReflectOutWipe
ReflectOutBack:
  POP DE                  ; straight back into the laser: OVERLOAD, the trace
                          ; ends
  POP DE
  JP BeamBackToLaser
ReflectOutSlant:
  POP DE                  ; $8080 + 8 x the new direction: two neighbours to
                          ; test
  POP DE
  LD HL,OutBounceTable
  LD A,B
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,L
  LD L,A
  EX DE,HL
  XOR A
  EX AF,AF'
  LD BC,(CharMapPointer)
  LD A,(DE)
  INC E
  LD L,A
  LD A,(DE)
  INC E
  LD H,A
  ADD HL,BC
  LD A,(HL)
  CP $31
  JR C,ReflectOutSlant2
  CP $73
  JR NC,ReflectOutSlant2
  EX AF,AF'
  ADD A,$01
  EX AF,AF'
ReflectOutSlant2:
  LD A,(DE)
  INC E
  LD L,A
  LD A,(DE)
  INC E
  LD H,A
  ADD HL,BC
  LD A,(HL)
  CP $31
  JR C,ReflectOutPick
  CP $73
  JR NC,ReflectOutPick
  EX AF,AF'
  ADD A,$02
  EX AF,AF'
ReflectOutPick:
  EX AF,AF'               ; +1 / +2 by the walls found: the bounced direction
  ADD A,E
  LD E,A
  LD A,(DE)
  LD (BeamNextDirection),A
  LD B,A
  LD A,(BeamDirection)
  ADD A,$08
  AND $0F
  CP B
  JP Z,BeamBackToLaser
  LD A,$FF                ; turned in place: no incoming pass, count the bounce
  LD (BeamDirection),A
  LD A,(BeamSteps+$0001)
  INC A
  LD (BeamSteps+$0001),A
  CP $28
  JP C,BeamVertex         ; under 40 bounces: draw the vertex again with the
                          ; new direction
  LD D,A                  ; exactly 40: OVERLOAD
  CALL Z,BeamBackToLaser
  LD A,D                  ; under 150: on; else the beam stops
  CP $96
  JP C,BeamVertex
  RET

; The cursor, the control bits, and the pause's save area
;
; CursorX `$96C3` (0-14) and CursorY `$96C4` (0-8): the cell under the cursor
; (0, 0 at the level set-up `$8498`, then the cell in front of the laser,
; `$8B08`-`$8B2B`; moved by `MoveCursor` `$9910`). ControlBits `$96C5`: this
; pass's controls from `ReadControls` `$9869` (bit 0 left, 1 right, 2 down, 3
; up, 4 fire). CursorMode `$96C6`: 0, or 7 while fire is held (cleared by
; `ReadKeys` `$97F0` each pass, set by `$995E` and `CursorFire` `$9A57`), which
; `DrawCursor` `$99C6` shows as a white square instead of inverted colours.
;
; PauseGame `$973A` keeps here what the INTERMISSION banner overwrites: the
; COMPUTER line's 14 bytes `$A104`-`$A111` (`$96C7`), the energy tick `$A506`
; (`$96D5`) and the sound flags `$A8A6` (`$96D6`), and five pixel rows of 16
; bytes of the screen at `$50E0` (`$96DB`). `$96D7`-`$96DA` are never used.
CursorVars:
CursorX:
  DEFB $00                ; 0-14
CursorY:
  DEFB $00                ; 0-8
ControlBits:
  DEFB $00                ; bit 0 left, 1 right, 2 down, 3 up, 4 fire
CursorMode:
  DEFB $00                ; 7: fire held
PauseSavedMessage:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $A104-$A111
PauseSavedTick:
  DEFB $00                ; $A506
PauseSavedSound:
  DEFB $00                ; $A8A6
  DEFB $00,$00,$00,$00    ; four bytes never used
PauseSavedRows:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; five pixel
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; rows of
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; $50E0-$50EF
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; " INTERMISSION  ": the pause's banner, 15 characters
;
; Printed by PauseGame `$973A` over the screen's left half at `$50E1` (pixel
; rows 0-4 of the characters, the font from `$D202`); the screen's strip is
; saved in PauseSavedRows `$96DB` first.
IntermissionText:
  INCBIN "res/texts/intermission.bin",$0000,15

  ORG $9910

; Keep the control bits; with fire turn the mirror under the cursor, else move
; the cursor a cell
;
; The control bits A (from `ReadControls` `$9869`) go to ControlBits `$96C5`.
; Fire held: `TurnMirror` `$995E`. Else the four direction bits index
; CursorSteps `$993E` (dx, dy, diagonals included, opposite pairs cancel) and
; the cursor moves one cell, each axis only when it stays on the grid (column
; 0-14, row 0-8). No delay: the cursor moves a cell every pass of the main loop
; (4.85 frames a pass in the RZX run).
;
; Witness: L1 117259 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
MoveCursor:
  LD (ControlBits),A
  BIT 4,A                 ; fire: turn the mirror
  JP NZ,TurnMirror
  LD B,A                  ; no direction: nothing to do
  AND $0F
  RET Z
  LD A,B                  ; HL = CursorSteps + 2 x direction bits
  AND $0F
  ADD A,A
  LD HL,CursorSteps
  LD C,A
  LD B,$00
  ADD HL,BC
  LD A,(CursorX)          ; column + dx, kept when 0-14
  ADD A,(HL)
  CP $0F
  JR NC,MoveCursorRow
  LD (CursorX),A
MoveCursorRow:
  LD A,(CursorY)          ; row + dy, kept when 0-8
  INC HL
  ADD A,(HL)
  CP $09
  RET NC
  LD (CursorY),A
  RET

; dx, dy for each value of the direction bits (bit 0 left, 1 right, 2 down, 3
; up)
;
; 16 pairs read by `MoveCursor` `$9910`. Left and right together, or up and
; down together, cancel; the last four pairs (up and down both held) are zero.
CursorSteps:
  INCBIN "res/tables/cursor-steps.bin",$0000,32

; Fire held: turn the mirror under the cursor one sixteenth to the right or to
; the left
;
; CursorMode `$96C6` = 7 (the square cursor). The cell under the cursor
; (`$FD23` + 17 x row + column) must be a mirror, `$01`-`$10` with or without
; bit 7 (bit 7: a mirror that also turns by itself, one step each pass of the
; grid drawing `$8960`, at `$89B1`); right (bit 1) adds one, left (bit 0)
; subtracts one, round from 16 to 1 and back; both or neither: nothing. Bit 7
; is kept. Up and down do nothing while fire is held. One step a pass: a full
; turn takes 16 passes.
;
; The angle: the trace (`$8FFB`) reflects the beam off mirror m to (m - 1 -
; direction + 8) AND 15, so mirror m lies at (m + 7) x 11.25 degrees: 1
; upright, 9 level, a sixteenth of a turn of the beam per two steps of the
; mirror.
;
; Runs: 48 813 (c1g, controls, kempston, menu, 58 RZX segments); turned right
; `$9988` 7649, left `$998F` 4205 (RZX).
;
; Witness: L1 50258 (c1, c1g, controls, kempston, menu, L x20, rzx x58).
TurnMirror:
  LD A,$07
  LD (CursorMode),A
  LD A,(CursorX)
  LD C,A
  LD A,(CursorY)
  LD B,A
  LD A,$12                ; HL = $FD23 + 17 x row + column
  INC B
TurnMirrorRow:
  ADD A,$11
  DJNZ TurnMirrorRow
  ADD A,C
  LD L,A
  LD H,$FD
  LD A,(ControlBits)      ; neither or both of left and right: nothing
  LD D,A
  AND $03
  RET Z
  CP $03
  RET Z
  LD A,(HL)               ; a mirror, $01-$10 (bit 7 aside)?
  LD B,A
  RES 7,A
  DEC A
  CP $10
  RET NC
  BIT 1,D                 ; right: + 1
  JR Z,TurnMirrorLeft
  LD A,(HL)
  JR TurnMirrorStore
TurnMirrorLeft:
  BIT 0,D                 ; left: - 1
  RET Z
  LD A,(HL)
  DEC A
  DEC A
TurnMirrorStore:
  AND $0F                 ; round in 1-16, bit 7 put back
  INC A
  LD (HL),A
  BIT 7,B
  RET Z
  SET 7,(HL)
  RET

; Mark the four characters under the cursor for redrawing
;
; Called each pass by the main loop (`$854D`) before the grid is drawn
; (`$8960`): the draw marks `$E300` of the cursor cell's 2 x 2 characters
; (column 2x + 1, row 2y + 1 of the 32 x 20 map) are set to 2, so the cell's
; own graphics replace last pass's cursor.
;
; Witness: L1 117260 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
MarkCursorCells:
  LD A,(CursorX)
  ADD A,A
  INC A
  LD C,A
  LD A,(CursorY)
  ADD A,A
  INC A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,L
  ADD A,C
  LD L,A
  LD A,$E3
  ADD A,H
  LD H,A
  LD A,$02
  LD (HL),A
  INC L
  LD (HL),A
  LD DE,$001F
  ADD HL,DE
  LD (HL),A
  INC L
  LD (HL),A
  RET

; Show the cursor: the cell's colours inverted, or a white square while fire is
; held
;
; Called each pass by the main loop (`$85A1`) after the beam. HL = the colour
; buffer `$E600` at the cursor cell's up-left character. CursorMode `$96C6` =
; 0: `InvertColour` `$99F7` swaps ink and paper of the four characters (flash
; and bright kept). 7: the four colours are set to 7 (white on black) and the
; 16 x 16 square `CursorGraphic` `$9A37` is ORed into the pixel buffer `$E900`
; over the cell.
;
; Witness: L1 117171 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
DrawCursor:
  LD A,(CursorX)
  ADD A,A
  INC A
  LD C,A
  LD A,(CursorY)
  ADD A,A
  INC A
  LD B,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD A,L
  ADD A,C
  LD L,A
  LD A,$E6
  ADD A,H
  LD H,A
  LD A,(CursorMode)       ; fire held: the square
  AND A
  JP NZ,DrawCursorSquare
  CALL InvertColour       ; else invert the four colours
  INC L
  CALL InvertColour
  LD DE,$001F
  ADD HL,DE
  CALL InvertColour
  INC L

; Swap the ink and paper of the colour byte at HL
;
; Keeps bits 7-6 (flash, bright). Falls in from `DrawCursor` for the fourth
; character.
;
; Witness: L1 259824 (c1, c1g, cheat, controls, corner, energy, energy-out,
; hof, kempston, menu, mine, nameedit, overload, practice, L x20, rzx x59).
InvertColour:
  LD A,(HL)
  LD B,A
  AND $C0
  LD D,A
  LD A,B
  AND $38
  SRL A
  SRL A
  SRL A
  LD E,A
  LD A,B
  AND $07
  AND A
  RLA
  RLA
  RLA
  OR D
  OR E
  LD (HL),A
  RET

; Fire held: colour 7 and the square drawn round the cell
;
; Entered from `DrawCursor` `$99C6` with A = 7, HL at the colour buffer, B =
; the character row 2y + 1, C = the column 2x + 1.
;
; Witness: L1 52215 (c1, c1g, controls, kempston, menu, L x20, rzx x58).
DrawCursorSquare:
  LD (HL),A
  INC L
  LD (HL),A
  LD DE,$001F
  ADD HL,DE
  LD (HL),A
  INC L
  LD (HL),A
  LD DE,CursorGraphic     ; DE = the square, HL = the pixel buffer at the cell
  LD HL,PixelBuffer
  ADD HL,BC
  LD A,$10
  LD BC,$001F
DrawCursorSquareRow:
  EX AF,AF'               ; 16 rows of 2 bytes, ORed
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC L
  INC DE
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC DE
  ADD HL,BC
  EX AF,AF'
  DEC A
  JR NZ,DrawCursorSquareRow
  RET

; The cursor's square: 16 rows of 16 pixels, a one-pixel frame
;
; ORed into the pixel buffer round the cell under the cursor by
; `DrawCursorSquare` `$9A11` while fire is held.
CursorGraphic:
  INCBIN "res/graphics/cursor.bin",$0000,32

  ORG $D500

; The beam's 39 glyphs (8 bytes each): $D500 + 8 x the glyph number of
; BeamGlyphBytes
;
; ORed into the pixel buffer `$E900` by BeamPlotGlyph (`$92C3`), BeamCornerChar
; (`$9483`) and BeamOutPlot (`$954A`), one character a glyph, with the colour
; `$43`. Glyph numbers come only from BeamGlyphBytes `$8000`, whose largest is
; 38: so the glyphs end at `$D637`. Glyphs 28 and 36 were drawn by no
; recording. Editable form: graphics/beam-glyphs.png.
BeamGlyphs:
  INCBIN "res/graphics/beam-glyphs.bin",$0000,312

; 25 glyph slots past the last glyph BeamGlyphBytes names: 14 dotted beam
; drawings, then zeros
;
; No glyph byte of BeamGlyphBytes reaches glyphs 39-63 (`$D638-$D6FF`), and no
; recording reads them. Glyphs 39-52 hold beam pieces drawn as dotted lines
; (slopes and diagonals); 53-63 are zeros. A third glyph set the tables do not
; use: leftovers/beam-glyphs-spare.png.
SpareBeamGlyphs:
  INCBIN "res/leftovers/beam-glyphs-spare.bin",$0000,200
