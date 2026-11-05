; --------------------------------------------------------------------------------------------------------------------
; init.asm: the tables built once at the start, in bank 0
;
; ScrollerInit at $C000 (the block's part in bank 0, which the scroller keeps paged): DitherPatterns, PairIndex,
; StarRows and TextRows; then StarPath, the circle of the star's tips, and the block's zero end.
; --------------------------------------------------------------------------------------------------------------------

; the tables: DitherPatterns, PairIndex, StarRows, TextRows
;
; Called once by ScrollerStart (bank 0 at $C000: the block's last part lies
; there). DitherPatterns: for every pair of levels (b, c), 4 lines combined
; from DitherLevels. PairIndex: 0-255 over the first 16 bytes of pages $80-$8F.
; StarRows: 40 rows from $40A1 (column 1, line 40), 4 lines apart. TextRows: 24
; character rows of column 31 from $401F.
ScrollerInit:
  LD IX,DitherPatterns    ; IX = the pattern being built (page $7C, index B x
                          ; 16 + C)
  LD H,$80                ; H, D = DitherLevels' page
  LD D,H
  LD B,$00
  EXX
  LD H,$10                ; 16 levels b
ScrollerInitB:
  EXX                     ; 16 levels c
  LD C,$00
  EXX
  LD L,$10
ScrollerInitPair:
  EXX                     ; the pair (b, c): E = b x 4, L = c x 4 (the levels'
                          ; first lines)
  PUSH IX
  LD E,B
  OR A
  RL E
  RL E
  LD L,C
  OR A
  RL L
  RL L
  LD IYH,$04              ; 4 lines
ScrollerInitLine:
  LD A,(DE)               ; level b's left nibble with level c's right nibble,
                          ; swapped
  AND $F0
  LD IYL,A
  LD A,(HL)
  AND $0F
  OR IYL
  RLCA
  RLCA
  RLCA
  RLCA
  LD (IX+$00),A           ; line n on page $7C + n
  INC E
  INC L
  INC IXH
  DEC IYH
  JR NZ,ScrollerInitLine
  INC C
  POP IX
  INC IXL
  EXX
  DEC L
  JR NZ,ScrollerInitPair
  EXX
  INC B
  EXX
  DEC H
  JR NZ,ScrollerInitB
  LD H,$80                ; PairIndex: A = 0-255 over (page $80-$8F, 0-15)
  XOR A
  LD C,$10
ScrollerInitIndex:
  LD L,$00                ; 16 a page
  LD B,$10
ScrollerInitIndexByte:
  LD (HL),A               ; one index
  INC L
  INC A
  DJNZ ScrollerInitIndexByte
  INC H
  DEC C
  JR NZ,ScrollerInitIndex
  LD HL,StarRows          ; StarRows: 40 rows from $40A1, 4 lines apart
  LD DE,$40A1
  LD C,$28
ScrollerInitStarRow:
  LD (HL),E               ; a row's address
  INC L
  LD (HL),D
  INC L
  LD B,$04
ScrollerInitStarLines:
  CALL NextLine           ; 4 lines down
  DJNZ ScrollerInitStarLines
  DEC C
  JR NZ,ScrollerInitStarRow
  LD HL,TextRows          ; TextRows: 24 character rows of column 31
  LD DE,$401F
  LD C,$18
ScrollerInitTextRow:
  LD (HL),E               ; a row's address
  INC L
  LD (HL),D
  INC L
  LD B,$08
ScrollerInitTextLines:
  CALL NextLine           ; 8 lines down
  DJNZ ScrollerInitTextLines
  DEC C
  JR NZ,ScrollerInitTextRow
  RET

; DE one pixel line down the screen
;
; Used by the routine at ScrollerInit.
NextLine:
  INC D
  LD A,D
  AND $07
  RET NZ
  LD A,E
  ADD A,$20
  LD E,A
  RET C
  LD A,D
  SUB $08
  LD D,A
  RET

; the circle the star's tips run on: 90 points (x, y)
;
; Built from src/res/intro/scroller/star-path.txt. ScrollerStart reads tip k of
; pass s at point s + 18 k.
StarPath:
  INCBIN "res/scroller/star-path.bin",$0000,180

; zero
ScrollerTail:
  DEFS $19B2

; zero: where ScrollerUnusedShow would copy a screen from (bank 7 paged in)
UnusedScreenPlace:
  DEFS $2500
