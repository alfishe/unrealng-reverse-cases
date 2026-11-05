; --------------------------------------------------------------------------------------------------------------------
; titlepic.asm: the title picture: a relocatable screen depacker and its packed screen
;
; UltraXOR's reader (src/boot/a-nether.asm) reads 13 sectors to $9C40 after the loader returns on SPACE and calls
; TitlePicture before it reads the boot program: the picture "АДСКАЯ ЗЕМЛЯ / ADVANCED NETHER EARTH / ETERNITY INDUSTRY
; PRODUCTION" (src/res/intro/title.png) unpacks straight into the shown screen at $4000 and stays there while the rest
; of the disk loads: the recording work/intro/i1 (inputs/i1-intro.txt: SPACE at script frame 6600) shows it in its
; screen of script frame 7000 (recording frame about 8600), the boot menu by 7250; tools/intro_trace.py runs it at
; frames 5954-5955.
;
; The code is position independent, as the authors' screen packer wrote it for any address: CALL $0052 (a RET in the
; 48 ROM) leaves its own return address under SP, which TitlePicture reads back as TitleBase, then patches the three
; CALLs to TitlePutByte with TitleBase + offset (their operands hold $74A6, the address the packer's template was
; assembled for) and takes the stream at TitleBase + $BE. The intro carries the same depacker for its picture
; (src/intro/intro.ann, LogoDepack $66C1).
;
; The stream (tools/intro_screen.py): a token byte with bit 7 clear copies ((b >> 3) & 15) + 3 bytes from ((b & 7) <<
; 8) + the next byte back, bit 7 set with bit 6 clear is a literal block of b & $3F bytes, bits 7 and 6 set repeat the
; next byte (b & $3F) + 3 times, $80 ends. The bytes go out in TitlePutByte's order: per third of the screen, column
; by column, the 8 character rows of a column top down, each 8 pixel lines; then the 768 attributes. A copy's source
; is the same order counted back, which TitleCopy turns into a screen address. 6912 bytes from 3034.
; --------------------------------------------------------------------------------------------------------------------

; the title picture unpacked to the screen
;
; Entered by UltraXOR's reader with the 48 ROM paged (CALL $0052 needs its RET
; there) and returns to it with interrupts on and HL' = $2758 (the ROM's value,
; for BASIC). DI first: the unpacking runs with no interrupt, about 14 frames (recording d1: 8215:18141-8229:52720).
TitlePicture:
  DI
  CALL $0052              ; the ROM's RET at $0052 returns at once and leaves
                          ; $9C44 below SP
TitleBase:
  DEC SP                  ; SP - 2 is the return address just left: BC =
                          ; TitleBase, wherever the code was loaded
  DEC SP
  POP BC
  LD HL,TitlePutByte-TitleBase ; DE = TitlePutByte
  ADD HL,BC
  EX DE,HL
  LD HL,TitleCopyCall+$0001-TitleBase ; the CALL of TitleCopy ...
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,TitleLiteralCall+$0001-TitleBase ; ... the CALL of TitleLiteral ...
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,TitleRunCall+$0001-TitleBase ; ... and the CALL of TitleRun to
                                     ; TitlePutByte
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,TitleStream-TitleBase ; HL = TitleStream, the packed screen
  ADD HL,BC
  LD DE,$4000             ; HL' = $4000, the first byte of the shown screen; DE
                          ; = $4000, the count of bytes out (as an address in
                          ; the stream's order)
  PUSH DE
  EXX
  EX AF,AF'
  LD A,$03                ; A' = 3: three thirds of pixels to go, NZ: pixels,
                          ; not attributes
  OR A
  LD B,$08                ; B' = 8 lines of a character row, C' = 8 rows of a
                          ; column
  LD C,B
  POP HL
  EX AF,AF'
  EXX
TitleNextToken:
  LD A,(HL)               ; the next token
  BIT 7,A
  JR NZ,TitleBlock        ; bit 7 set: a literal block, a run or the end
  AND $07                 ; a copy: C = the offset's high bits
  LD C,A
  LD A,(HL)               ; B = the length, bits 3-6 + 3: 3-18 bytes
  RRCA
  RRCA
  RRCA
  AND $0F
  ADD A,$03
  LD B,A
  INC HL                  ; the offset's low byte
  LD A,E                  ; HL = DE - offset: where the copy starts, in the
                          ; stream's order
  SUB (HL)
  INC HL
  PUSH HL
  LD L,A
  LD A,D
  SBC A,C
  LD H,A
TitleCopy:
  PUSH HL                 ; one byte of a copy: its stream position to a screen
                          ; address
  LD A,H                  ; the attributes ($5800-$5AFF) are in screen order
                          ; already
  AND $58
  CP $58
  JR Z,l_9CA8
  LD C,A                  ; C = $40 + third x 8 + the pixel line (L bits 0-2)
  LD A,L
  AND $07
  OR C
  LD C,A
  ADD HL,HL               ; HL x 4: H bits 0-4 the column, L bits 5-7 the
                          ; character row
  ADD HL,HL
  LD A,H
  AND $1F
  LD H,A
  LD A,L
  AND $E0
  OR H
  LD L,A
  LD H,C                  ; HL = the screen address of that byte
l_9CA8:
  LD A,(HL)               ; the byte from the screen, written again at the
                          ; current place
TitleCopyCall:
  CALL $74A6              ; operand patched to TitlePutByte
  POP HL
  INC HL                  ; the next source byte
  DJNZ TitleCopy
  POP HL                  ; the token's pointer back
  JR TitleNextToken
TitleBlock:
  AND $7F                 ; bit 7 set: the low 7 bits, 0 the end
  JR Z,TitleDone
  INC HL                  ; the byte after the token
  BIT 6,A                 ; bit 6 set: a run
  JR NZ,TitleRun
TitleLiteral:
  LD B,A                  ; a literal block of B bytes
l_9CBD:
  LD A,(HL)
TitleLiteralCall:
  CALL $74A6              ; operand patched to TitlePutByte
  INC HL
  DJNZ l_9CBD
  JR TitleNextToken
TitleRun:
  AND $3F                 ; a run: the next byte (b & $3F) + 3 times
  ADD A,$03
  LD B,A
  LD A,(HL)
TitleRunCall:
  CALL $74A6              ; operand patched to TitlePutByte
  DJNZ TitleRunCall
  INC HL
  JR TitleNextToken
TitleDone:
  EXX                     ; the end: HL' = $2758 as the ROM keeps it,
                          ; interrupts on
  LD HL,$2758
  EXX
  EI
  RET

; write A to the screen at HL' and step HL' in the stream's order
;
; DE counts the bytes out (TitleCopy reads its sources by that count). In the
; alternate set: HL' the screen address, B' the lines left in the character
; row, C' the rows left in the column, A' (with its flags) 3 - third and the
; columns done x 8; Z' set once the pixels are done: then HL' just counts on
; through the attributes.
TitlePutByte:
  INC DE
  EXX
  LD (HL),A
  EX AF,AF'
  JR Z,l_9CFA             ; Z': the attributes, one after another
  INC H                   ; the next pixel line down
  DJNZ l_9CFF
  LD DE,$F820             ; a character row done: H - 8 (back to its first
                          ; line), L + $20 (the next row)
  ADD HL,DE
  DEC C                   ; 8 rows: the column is done
  JR NZ,l_9CFD
  LD DE,$FF01             ; the next column, the third's top row (H - 1 undoes
                          ; the carry of the 8th row)
  ADD HL,DE
  ADD A,$08               ; A' + 8 a column: the 32nd carries
  JR NC,l_9CFB
  LD DE,$07E0             ; the third is done: on to the next third's first
                          ; column
  ADD HL,DE
  DEC A                   ; one third less: Z after the third third, the
                          ; attributes next
  JR l_9CFB
l_9CFA:
  INC HL                  ; an attribute: the next one
l_9CFB:
  LD C,$08                ; a new column: 8 rows
l_9CFD:
  LD B,$08                ; a new character row: 8 lines
l_9CFF:
  EX AF,AF'
  EXX
  RET

; the packed title picture, 3034 bytes
;
; Built from src/res/intro/title.png and src/res/intro/title.parse by
; tools/intro_screen.py pack (the authors' token choices kept in the parse: the
; same picture gives the same stream).
TitleStream:
  INCBIN "res/title.lz",$0000,3034

; 100 bytes after the stream: never read
;
; What the authors' tool left in the last of the 13 sectors after the stream
; ($A8DC-$A93F): a piece of some other packed data. Nothing reads it
; (tools/intro_trace.py: no read in the title's run); kept as the bytes on the
; disk.
TitleLeftover:
  INCBIN "res/title-leftover.bin",$0000,100
