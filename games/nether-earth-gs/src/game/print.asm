; --------------------------------------------------------------------------------------------------------------------
; print.asm: text: the inline print routine, the font characters, big characters, the numbers
;
; All text goes through PrintInline: it prints the bytes after its CALL and returns past them, so every string sits
; inline in the routine that prints it. The bytes: 0 the end, 1 Y X a position (row, column), 2 A the attribute, 3 the
; next row in the same column, 4 N the size (high nibble the height in rows, low nibble the width in bytes; 0 normal),
; anything else a character. nether-earth/docs/08-hud-and-text.md 8.1.
;
; The chain: PrintInline (in the alternate registers) -> PrintControl -> SetPosition / SetAttr / PrintNewline /
; SetSize, or a character: PrintChar (8 lines of the 64-glyph font at $6780, codes $20-$5F, glyph = $6680 + 8 * code)
; or PrintBigChar (each glyph line repeated PrintHeight times, and each pixel doubled for width 2). SetPrintPos turns
; PrintRow / PrintColumn into PrintAddr and PrintAttrAddr. docs/08 8.2.
;
; The numbers: PrintDigit counts how often a negative power of ten fits into HL; E = $20 means "still in the leading
; zeros", which print as spaces. PrintNumber5 (the day), PrintNumber3, PrintTensUnits, PrintNumber2 (blank leading
; zero) and PrintNumber2Zero (the clock, the robot counts) are entries into the same chain; PrintCharKeep prints with
; BC, DE, HL kept. docs/08 8.6.
;
; The control handlers read their operand two stack levels up: PrintControl's return address on top, PrintInline's
; string pointer under it (POP DE; POP HL; ... PUSH HL; PUSH DE). Variables: PrintAddr $FD04, PrintAttr $FD13,
; PrintAttrAddr $FD14, PrintHeight $FD16, PrintWidth $FD17, PrintColumn $FD31, PrintRow $FD32.
; --------------------------------------------------------------------------------------------------------------------

; Print A (0-99) as two digits, a leading zero blank
;
; In: A. HL = A, E = $20, then PrintTensUnits: a space for a leading zero. Used
; for the resources (PrintResourceValues), the construction menu values and the
; miles of ADVANCE / RETREAT. A value of 100 or more would print a tens "digit"
; above 9 (":" and on); the game caps every resource at 99.
PrintNumber2:
  LD L,A                  ; HL = the value
  LD H,$00                ; (H = 0)
  LD E,$20                ; a leading zero prints as a space
  JR PrintTensUnits       ; the tens and the units

; Print A (0-99) as two digits with a leading zero
;
; The clock ($AD90, 6828 calls: "20.20") and the robot counts of the panel.
PrintNumber2Zero:
  LD L,A                  ; HL = the value
  LD H,$00                ; (H = 0)
  LD E,$00                ; every zero prints as 0
  JR PrintTensUnits       ; the tens and the units

; Print HL as five digits, leading zeros blank
;
; Used by $AD90 for the day number ("DAY:    4"). Falls into PrintNumber3.
PrintNumber5:
  LD BC,$D8F0             ; -10000
  LD E,$20                ; leading zeros blank
  CALL PrintDigit         ; the ten thousands
  LD BC,-1000             ; -1000
  CALL PrintDigit         ; the thousands

; Print HL as three digits (E = $20: leading zeros blank, else printed)
;
; The operand $FF9C is -100 (the source writes it so with @isub; as a label it
; would read Buildings+155, a false symbol). Used by PrintMenuTotal and $A833.
PrintNumber3:
  LD BC,-100              ; -100
  CALL PrintDigit         ; the hundreds

; Print the tens and the units of HL
;
; HL = the value (0-99, else the tens "digit" runs past 9: 200 prints as "D0"),
; E = the leading-zero flag. The tens by PrintDigit, the units always printed.
; The tail of PrintNumber2, PrintNumber2Zero, PrintNumber3 and PrintNumber5.
PrintTensUnits:
  LD BC,-10               ; -10
  CALL PrintDigit         ; the tens
  LD A,L                  ; the units digit, always printed
  ADD A,$30               ; as a digit
  JP PrintCharKeep        ; print it and return

; Print the digit of HL for the power -BC; HL keeps the rest
;
; Counts how often BC (a negative power of 10) can be added. A zero while E =
; $20 prints a space and keeps E; any printed digit increments E, so later
; zeros print as 0.
PrintDigit:
  XOR A                   ; the count
DigitCountLoop:
  ADD HL,BC               ; take the power once more
  INC A                   ; count it
  JR C,DigitCountLoop     ; carry: no borrow, it fitted
  SBC HL,BC               ; one too far: undo
  DEC A                   ; A = the digit
  JR NZ,DigitPrint        ; not 0: print it
  LD A,E                  ; a leading zero
  CP $20                  ; still in the leading zeros?
  JP Z,PrintCharKeep      ; blank: E = $20 is the space
  XOR A                   ; a zero after a printed digit
DigitPrint:
  INC E                   ; a digit: no more leading zeros, print "0" + A
  ADD A,$30               ; as a character

; PrintChar A with BC, DE, HL kept (EXX around)
;
; PrintChar in the alternate registers: the caller's BC, DE, HL are kept (the
; number printers keep HL, E and the loop counters in them). A and the flags
; change.
PrintCharKeep:
  EXX                     ; the alternate set
  CALL PrintChar          ; the character
  EXX                     ; the caller's registers back
  RET                     ; done

; print the text after the CALL: 0 ends, 1 Y X a position, 2 A an attribute, 3
; the next line, 4 N a setting, else a character
;
; In: the string after the CALL. Pops the return address, takes a byte, pushes
; the address one byte on, until a 0: the RET then lands after the string. Each
; byte goes to PrintControl (codes 1-4 and characters). Works in the alternate
; set (EXX at both ends), so the caller's BC, DE, HL are kept; A and the flags
; change. Callers also end in it with JP (PrintKeyPrompt $C40C), so the bytes
; after their own CALL are the string. About 60 call sites: every screen and
; panel text.
PrintInline:
  EXX                     ; the alternate set: the caller's BC, DE, HL stay
PrintInlineLoop:
  POP HL                  ; the next byte after the CALL: the return address
                          ; moves with it
  LD A,(HL)               ; the next string byte
  INC HL                  ; one on
  PUSH HL                 ; the return address follows it
  OR A                    ; 0?
  JR Z,PrintInlineEnd     ; the end of the string
  CALL PrintControl       ; a control code or a character
  JR PrintInlineLoop      ; the next byte
PrintInlineEnd:
  EXX                     ; 0: return past the string
  RET                     ; past the string

; PrintInline's byte A: control codes 1-4 or a character
;
; 1 Y X: the position (row Y, column X, kept in $FD32/$FD31). 2 A: the
; attribute $FD13. 3: newline (the next row, the same column). 4 N: the size,
; high nibble the height in character rows ($FD16), low nibble the width in
; bytes ($FD17); 0 = normal. A character goes to PrintChar for size 0, else to
; PrintBigChar. The operands are read through the caller's return address on
; the stack, two levels up.
PrintControl:
  CP $01                  ; 1: a position, Y X
  JR Z,SetPosition        ; (yes)
  CP $02                  ; 2: an attribute
  JR Z,SetAttr            ; (yes)
  CP $03                  ; 3: a newline
  JR Z,PrintNewline       ; (yes)
  CP $04                  ; 4: a size
  JR Z,SetSize            ; (yes)
  LD C,A                  ; a character
  LD A,(PrintWidth)       ; the size in use
  OR A                    ; 0: normal
  LD A,C                  ; the character back
  JR Z,PrintChar          ; size 0: normal
  JP PrintBigChar         ; scaled
SetAttr:
  POP DE                  ; 2 A
  POP HL                  ; HL = the string pointer, under PrintControl's
                          ; return
  LD A,(HL)               ; the operand
  INC HL                  ; past it
  PUSH HL                 ; the string pointer back
  PUSH DE                 ; and the return above it
  LD (PrintAttr),A        ; PrintAttr = A
  RET                     ; back to PrintInline
SetPosition:
  POP DE                  ; 1 Y X
  POP HL                  ; HL = the string pointer
  LD B,(HL)               ; B = the row
  INC HL                  ; (the next operand)
  LD C,(HL)               ; C = the column
  LD (PrintColumn),BC     ; PrintColumn = C, PrintRow = B
  INC HL                  ; past the operands
  PUSH HL                 ; the string pointer back
  PUSH DE                 ; and the return above it
  JP SetPrintPos          ; the screen and attribute addresses

; The next print row, the same column
;
; PrintRow + 1, then SetPrintPos. Reached by code 3 inside PrintInline and
; called directly by the number printers' callers (GameTurnEnd $AD96,
; ResourceValueLoop, PrintDigitColumn, ReadFireKey $C3CA). Changes A, BC, HL.
PrintNewline:
  LD BC,(PrintColumn)     ; C = the column, B = the row
  INC B                   ; the next row
  LD (PrintColumn),BC     ; kept
  JP SetPrintPos          ; the addresses
; This entry point is used by the routine at PrintControl.
SetSize:
  POP DE                  ; 4 N: height nibble, width nibble
  POP HL                  ; HL = the string pointer
  LD A,(HL)               ; N
  INC HL                  ; past it
  PUSH HL                 ; the string pointer back
  PUSH DE                 ; and the return above it
  LD C,A                  ; keep N
  RRCA                    ; the high nibble ...
  RRCA                    ; ...
  RRCA                    ; ...
  RRCA                    ; ... to the low one
  AND $0F                 ; the height in character rows
  LD (PrintHeight),A      ; PrintHeight
  LD A,C                  ; N again
  AND $0F                 ; the width in bytes, 0 normal
  LD (PrintWidth),A       ; PrintWidth
  RET                     ; back to PrintInline

; Print position: B = row, C = column -> $FD04 the screen address, $FD14 the
; attribute address
;
; In: B = row 0-23, C = column 0-31. PrintAddr = $4000 + (B AND $18) * 256 + (B
; AND 7) * 32 + C, the top line of the character cell; PrintAttrAddr = $5800 +
; 32 * B + C. Changes A, HL. Used by SetPosition and PrintNewline.
SetPrintPos:
  LD A,B                  ; the row
  AND $F8                 ; its third (rows 0, 8, 16) ...
  ADD A,$40               ; ... on the screen's start
  LD H,A                  ; H = the third's page
  LD A,B                  ; the row
  AND $07                 ; inside the third
  RRCA                    ; * 32 ...
  RRCA                    ; ...
  RRCA                    ; ... (three right rotations)
  ADD A,C                 ; + the column
  LD L,A                  ; L
  LD (PrintAddr),HL       ; the screen address
  LD A,H                  ; the third ...
  RRCA                    ; ...
  RRCA                    ; ...
  RRCA                    ; ... bits 3-4 of H to 0-1
  AND $03                 ; (0-2)
  OR $58                  ; the attributes' page $58-$5A
  LD H,A                  ; H = $58-$5A
  LD (PrintAttrAddr),HL   ; the attribute address (the same L)
  RET                     ; done

; Print character A at the print position in the print attribute, advance one
; column
;
; The font is at $6680 + 8*code ($6780 for the space, right after the view
; buffer). 8 lines into ($FD04), the attribute ($FD13) into ($FD14), both
; advanced.
PrintChar:
  LD H,$00                ; HL = the code
  LD L,A                  ; (L)
  ADD HL,HL               ; 2 x
  ADD HL,HL               ; 4 x
  ADD HL,HL               ; 8 x
  LD DE,Font-$100         ; the font
  ADD HL,DE               ; HL = the glyph
  LD DE,(PrintAddr)       ; the cell's top line
  PUSH DE                 ; kept
  LD B,$08                ; 8 lines
GlyphLineLoop:
  LD A,(HL)               ; a glyph line
  LD (DE),A               ; onto the screen
  INC HL                  ; the next glyph line
  INC D                   ; the next pixel line of the cell
  DJNZ GlyphLineLoop      ; 8 lines
  POP DE                  ; the cell's top line
  INC DE                  ; the next column (no check for the row's end)
  LD (PrintAddr),DE       ; PrintAddr
  LD HL,(PrintAttrAddr)   ; the attribute cell
  LD A,(PrintAttr)        ; the attribute
  LD (HL),A               ; into the cell
  INC HL                  ; the next cell
  LD (PrintAttrAddr),HL   ; PrintAttrAddr
  RET                     ; done

; Print character A scaled: each line repeated $FD16 times, width 1 or 2 bytes
; ($FD17)
;
; Width 1: each glyph line written $FD16 times (2: a character two rows high,
; "RADAR:"). Width 2: each glyph byte doubled to 16 bits. Then the screen
; address moves on by the width and a block of width x height attribute cells
; gets $FD13. 180 calls in Nether Earth's deep recording.
PrintBigChar:
  LD H,$00                ; HL = the code
  LD L,A                  ; (L)
  ADD HL,HL               ; 2 x
  ADD HL,HL               ; 4 x
  ADD HL,HL               ; 8 x
  LD DE,Font-$100         ; the font: glyph = $6680 + 8 * code
  ADD HL,DE               ; HL = the glyph
  LD A,(PrintWidth)       ; the width
  CP $02                  ; width 2: doubled pixels
  JR NC,WideChar          ; 2 or more: the wide path
  EX DE,HL                ; DE = the glyph
  LD HL,(PrintAddr)       ; HL = the top line of the cell
  LD C,$08                ; 8 glyph lines
TallLineLoop:
  LD A,(PrintHeight)      ; each line ...
  LD B,A                  ; ... repeated PrintHeight times
TallRepeatLoop:
  LD A,(DE)               ; the glyph line
  LD (HL),A               ; onto the screen
  CALL NextScreenLine     ; the next screen line, across the cell boundaries
  DJNZ TallRepeatLoop     ; each copy
  INC DE                  ; the next glyph line
  DEC C                   ; one line less
  JR NZ,TallLineLoop      ; the next glyph line
  JR BigCharAttrs         ; the attributes
WideChar:
  PUSH IX                 ; IX kept
  PUSH HL                 ; IX = ...
  POP IX                  ; ... the glyph
  LD HL,(PrintAddr)       ; HL = the top line of the cell
  LD C,$08                ; 8 glyph lines
WideLineLoop:
  LD A,(IX+$00)           ; the glyph line
  LD B,$08                ; 8 pixels
WideBitLoop:
  RLCA                    ; each bit twice into DE
  PUSH AF                 ; keep the pixel (in the carry) for the second copy
  RL E                    ; into E ...
  RL D                    ; ... and on into D
  POP AF                  ; the same pixel
  RL E                    ; again into E ...
  RL D                    ; ... and D
  DJNZ WideBitLoop        ; each pixel: DE = the line 16 pixels wide
  LD A,(PrintHeight)      ; each line ...
  LD B,A                  ; ... repeated PrintHeight times
WideRepeatLoop:
  LD (HL),D               ; the left byte
  INC L                   ; (the next column)
  LD (HL),E               ; the right byte
  DEC L                   ; (back)
  CALL NextScreenLine     ; the next screen line
  DJNZ WideRepeatLoop     ; each copy
  INC IX                  ; the next glyph line
  DEC C                   ; one line less
  JR NZ,WideLineLoop      ; the next glyph line
  POP IX                  ; IX back
BigCharAttrs:
  LD HL,(PrintAddr)       ; advance, then the attribute block
  LD A,(PrintWidth)       ; the width
  CALL AddAToHL           ; the next character's top line
  LD (PrintAddr),HL       ; PrintAddr
  LD HL,(PrintAttrAddr)   ; the first attribute cell
  PUSH HL                 ; kept
  LD BC,(PrintHeight)     ; C = PrintHeight (rows), B = PrintWidth (cells)
  LD A,(PrintAttr)        ; the attribute
  LD E,A                  ; E = it
BigAttrRowLoop:
  PUSH HL                 ; keep the row's start
  PUSH BC                 ; and the counts
BigAttrCellLoop:
  LD (HL),E               ; one cell
  INC HL                  ; the next cell
  DJNZ BigAttrCellLoop    ; width cells
  POP BC                  ; the counts back
  POP HL                  ; the row's start
  LD A,L                  ; + 32: the row below
  ADD A,$20               ; (L)
  LD L,A                  ; (the low byte)
  LD A,H                  ; the carry ...
  ADC A,$00               ; ... into ...
  LD H,A                  ; ... H
  DEC C                   ; one row less
  JR NZ,BigAttrRowLoop    ; the next row
  POP HL                  ; the first cell
  LD A,B                  ; + the width
  CALL AddAToHL           ; the next character's attribute cell, on the top row
  LD (PrintAttrAddr),HL   ; PrintAttrAddr
  RET                     ; done
