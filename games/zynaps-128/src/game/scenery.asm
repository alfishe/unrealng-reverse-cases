; --------------------------------------------------------------------------------------------------------------------
; scenery.asm: The scenery scripts: a coroutine that writes the level's tiles into the map ring
;
; The level's scenery is written by a script that runs as a coroutine on its own stack (top $FDFB): ResumeScript
; switches to it, YieldScript switches back. Every 16 scrolled columns (ScriptRoom $801F) the script runs until it has
; placed one group of objects 16 columns further on (ScriptColumn $801E).
;
; A script (the word table $72E1 indexed by ScriptNumber $81DD) is a byte list: below $80 = draw the object group n
; (the word table $749A) and yield; $80 n = call script n; $A0-$AF = the variant mask ($8021) for the groups that
; follow; $81-$9F = copy the 8-byte cell pattern n ($72A9 + 8n) to WorkCell ($FFD8); $FF = end.
; --------------------------------------------------------------------------------------------------------------------

; Set up the scenery coroutine for a level
;
; Script stack top $FDFB holds the entry ScriptMain, ScriptSP ($801A) = $FDFB,
; ScriptBusy ($8020) = 0; falls into ResumeScript. Called from the level start
; $AF49 (48K c2: 1 entry).
StartScript:
  LD HL,ScriptStackTop
  LD (ScriptSP),HL
  LD HL,ScriptMain
  LD (ScriptStackTop),HL
  XOR A
  LD (ScriptBusy),A

; Run the scenery script when 16 more columns have scrolled
;
; When ScriptBusy is 0: returns unless ScriptRoom >= 16; then ScriptRoom - 16,
; ScriptColumn + 16, ScriptBusy = $FF. Saves the main SP ($8018), switches to
; ScriptSP and RETs into the script; it returns here through YieldScript.
;
; Called from the frame handler cycle $AA96 (48K c2: 524 entries) and from the
; catch-up loop $AF90/$AF96.
ResumeScript:
  LD HL,ScriptBusy
  LD A,(HL)
  AND A
  JR NZ,SwitchToScript
  LD A,(ScriptRoom)
  SUB $10
  RET C
  LD (ScriptRoom),A
  LD A,(ScriptColumn)
  ADD A,$10
  LD (ScriptColumn),A
  LD A,$FF
  LD (HL),A
SwitchToScript:
  LD (MainSP),SP
  LD SP,(ScriptSP)
  RET

; Switch from the script back to the main stack
;
; ScriptSP = SP, SP = the main SP: the RET returns to ResumeScript's caller.
; 48K c2: 90 entries.
YieldScript:
  LD (ScriptSP),SP
  LD SP,(MainSP)
  RET

; The coroutine's body: run the level's script for ever
;
; A = ScriptNumber ($81DD), RunScript, again. Its first RET came from
; StartScript; 48K c2 shows no entry because the loop never ends during a level
; (1 dispatch at the start).
ScriptMain:
  LD A,(ScriptNumber)
  CALL RunScript

; ScriptMainAgain
ScriptMainAgain:
  JR ScriptMain           ; the main script ended: run it again

; Run the script A
;
; HL = the script's address from the word table $72E1, then ScriptStep. 48K c2:
; 4 entries (the main script and its sub-scripts).
RunScript:
  LD HL,SceneryScriptTable
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL

; Interpret the script bytes at HL
;
; Below $80: DrawGroup n, ScriptBusy = 0, YieldScript, go on. $FF: return. $80
; n: call script n (ScriptVariant saved and restored, ScriptReturn). $A0-$AF:
; ScriptVariant = the low nibble moved to the high nibble. Other $81-$9F:
; ScriptSetCell (the pattern n AND 7).
ScriptStep:
  LD A,(HL)
  INC HL
  AND A
  JP M,ScriptCommand
  PUSH HL
  CALL DrawGroup
  XOR A
  LD (ScriptBusy),A
  CALL YieldScript
  POP HL
  JR ScriptStep
ScriptCommand:
  CP $FF
  RET Z
  AND $7F
  JR Z,ScriptCall
  BIT 5,A
  JR Z,ScriptPattern
  AND $0F
  RRCA
  RRCA
  RRCA
  RRCA
  LD (ScriptVariant),A
  JR ScriptStep
ScriptPattern:
  AND $07
  PUSH HL
  CALL ScriptSetCell
  POP HL
  JR ScriptStep
ScriptCall:
  LD A,(HL)
  INC HL
  PUSH HL
  LD HL,(ScriptBusy)
  PUSH HL
  CALL RunScript

; ScriptReturn
ScriptReturn:
  POP AF                  ; back from a sub-script: the variant restored
  LD (ScriptVariant),A
  POP HL
  JR ScriptStep

; Place the object group A into the map ring
;
; Returns at once when SkipDraw ($7F76) bit 0 is set (the catch-up after a life
; lost runs the scripts without drawing).
;
; The group (word table $749A) is a list: a byte with bit 7 set and not $FF = a
; sub-group (the next byte) taken only when its bit 6 AND ScriptVariant is
; non-zero (recursion); $FF = end; otherwise an object of 3 bytes: the first
; byte (bits 0-4 the row, bits 5-7 the flags: bit 0 = flipped, bit 1 =
; mirrored), a variant/column byte (low nibble the column; ANDed with
; ScriptVariant), the shape number (the word table $7783).
;
; For each object the shape's cells are written column by column (PlaceColumn),
; with the direction of the row and column steps written into $8E94, $8EBF and
; $8EC0 for the flip and mirror, then YieldScript after every column, so the
; placement spreads over the frames.
;
; 48K c2: 15 entries.
DrawGroup:
  LD HL,SkipDraw
  BIT 0,(HL)
  RET NZ
  LD HL,GroupTable
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
GroupNext:
  LD A,(DE)
  INC DE
  AND A
  JP P,GroupObject
  CP $FF
  RET Z
  RLA
  LD HL,ScriptVariant
  AND (HL)
  LD A,(DE)
  INC DE
  JR Z,GroupNext
  PUSH DE
  CALL DrawGroup
  POP DE
  JR GroupNext
GroupObject:
  EX DE,HL
  LD E,A
  AND $1F
  LD D,A
  XOR E
  RLCA
  RLCA
  RLCA
  LD (PlaceFlags+$0001),A
  LD C,A
  LD A,(ScriptVariant)
  AND (HL)
  JR NZ,PlaceObject
  INC HL
  INC HL
  EX DE,HL
  JR GroupNext
PlaceObject:
  LD A,(HL)
  INC HL
  AND $0F
  LD E,A
  LD A,(HL)
  INC HL
  PUSH HL
  ADD A,A
  LD HL,ShapeTable
  ADD A,L
  LD L,A
  LD A,$00
  ADC A,H
  LD H,A
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  BIT 1,C
  LD A,$1C
  JR Z,ObjectDirections
  LD A,$07
  ADD A,E
  LD E,A
  LD A,$1D
ObjectDirections:
  LD (PlaceStepE),A
  SUB $10
  LD (PlaceStepC),A
  BIT 0,C
  LD A,$14
  JR NZ,ObjectRowFlipped
  LD (ObjectRowStep),A
  LD A,$12
  SUB D
  SUB (HL)
  JP M,ObjectRowClipped
  XOR A
ObjectRowClipped:
  ADD A,(HL)
  JR ObjectStart
ObjectRowFlipped:
  LD A,(HL)
  ADD A,D
  DEC A
  LD D,A
  LD A,$15
  LD (ObjectRowStep),A
  LD A,(HL)
ObjectStart:
  EXX
  LD B,A
  EXX
  LD A,D
  XOR C
  RRA
  PUSH AF
  RL E
  SRL D
  RR E
  LD A,$B7
  ADD A,D
  LD D,A
  LD A,(ScriptColumn)
  ADD A,E
  LD E,A
  SUB $40
  LD C,A
  LD B,D
  POP AF
  INC HL
  EXX
  LD H,$FF
  JR C,PlaceObjectColumnB
PlaceObjectColumn:
  EXX
  PUSH DE
  CALL PlaceColumn
  POP DE
  LD A,$80
  ADD A,E
  LD E,A
  SUB $40
  LD C,A
  EXX
  DJNZ PlaceObjectColumnB
  JR ObjectPlaced
PlaceObjectColumnB:
  EXX
  PUSH DE
  CALL PlaceColumn
  POP DE
  LD A,$80
  ADD A,E
  LD E,A
  SUB $40
  LD C,A
ObjectRowStep:
  INC D                   ; INC D or DEC D (written at $8E3C, $8E50)
  LD B,D
  EXX
  DJNZ PlaceObjectColumn
ObjectPlaced:
  EXX
  CALL YieldScript
  POP DE
  JP GroupNext

; Write one shape column into the map ring
;
; The column's header byte: bit 0 set = an attribute follows from the table at
; H = $FF (OR with the flags at PlaceFlags, stored into PlaceAttr). Then per
; cell a bit of the mask byte: set = the tile code goes to (DE) and the
; attribute to (BC); E and C step by PlaceStepE/PlaceStepC (INC or DEC, written
; by DrawGroup). A 0 bit ends the column.
;
; 48K c2: 209 entries.
PlaceColumn:
  LD A,(HL)
  INC HL
  BIT 0,A
  JR Z,PlaceFlags
  EXX
  RRCA
  LD L,A
  LD A,(HL)
  EXX
PlaceFlags:
  OR $00                  ; OR n: n = the object's flip/mirror bits (written at
                          ; $8DFD)
  LD (PlaceAttr+$0001),A
  LD A,(HL)
  INC HL
PlaceCell:
  ADD A,A
  JR NC,PlaceCellNext
  EX AF,AF'
  LD A,(HL)
  INC HL
  LD (DE),A
PlaceAttr:
  LD A,$00                ; LD A,n: n = the column's attribute (written at
                          ; $8EAE)
  LD (BC),A
  EX AF,AF'
PlaceCellNext:
  RET Z
PlaceStepE:
  INC E                   ; INC E or DEC E (written at $8E2E)
PlaceStepC:
  INC C                   ; INC C or DEC C (written at $8E33)
  JP PlaceCell

; A RET byte after the loop's JP: never reached
PlaceColumnSpare:
  DEFB $C9

; Copy the 8-byte cell pattern A to WorkCell
;
; HL = $72A9 + 8A, 8 bytes to $FFD8. 48K c2: 1 entry.
ScriptSetCell:
  RLCA
  RLCA
  RLCA
  LD E,A
  AND $07
  LD D,A
  XOR E
  LD E,A
  LD HL,CellPatterns
  ADD HL,DE
  LD DE,WorkGlyph
  LD BC,$0008
  LDIR
  RET
