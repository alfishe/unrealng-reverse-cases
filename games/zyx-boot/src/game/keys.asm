; --------------------------------------------------------------------------------------------------------------------
; keys.asm: The keys, every 8th frame
;
; ReadKeyboard $6864: the letters A-X (KeyTable $6B53, src/res/tables/keys.txt) run the file with that letter at once
; (RunLetter $6A51); 1, 2, 6, 7 change the column, 3 and 8 move down, 4 and 9 up, 5, 0 and ENTER run the file under
; the cursor (the cursor keys of a Sinclair and a cursor joystick); CAPS SHIFT shows the first page, SYMBOL SHIFT the
; next one, SPACE reads the catalogue again (a new disk). A Kempston read is replaced by LD A,0: its five CALL C never
; call. The keys repeat while held: at 8 frames a read, a held key moves the cursor 6 times a second.
; --------------------------------------------------------------------------------------------------------------------

  ORG $6864

; Read the letters, the digits, ENTER, CAPS SHIFT, SYMBOL SHIFT and SPACE
;
; Witness: L1 1741 (c x4).
ReadKeyboard:
  LD C,$41
  LD HL,KeyTable
ReadNextLetter:
  LD A,(HL)               ; the next letter: the half-row from bits 7-5, the
                          ; key from bits 4-0
  RRCA
  RRCA
  AND $38
  OR $87
  LD (ReadLetterRow+$0001),A
  LD A,$FF
ReadLetterRow:
  RES 0,A                 ; RES n,A: the half-row's address bit, the opcode
                          ; from the table
  IN A,($FE)
  CPL
  LD B,A
  LD A,(HL)
  AND $1F
  AND B
  CALL NZ,RunLetter
  INC C
  INC HL
  LD A,C
  CP $59
  JR NZ,ReadNextLetter
  LD A,$F7
  IN A,($FE)
  RRA
  CALL NC,ColumnKey
  RRA
  CALL NC,ColumnKey
  RRA
  CALL NC,DownKey
  RRA
  CALL NC,UpKey
  RRA
  CALL NC,FireKey
  LD A,$EF
  IN A,($FE)
  RRA
  CALL NC,FireKey
  RRA
  CALL NC,UpKey
  RRA
  CALL NC,DownKey
  RRA
  CALL NC,ColumnKey
  RRA
  CALL NC,ColumnKey
Joystick:
  LD A,$00                ; the Kempston read: LD A,$00, so the five CALL C
                          ; after it never call (variants with IN A,($1F) read
                          ; the joystick, variants/README.md)
  RRA
  CALL C,ColumnKey
  RRA
  CALL C,ColumnKey
  RRA
  CALL C,DownKey
  RRA
  CALL C,UpKey
  RRA
  CALL C,FireKey
  LD A,$FE
  IN A,($FE)
  RRA
  JR C,ReadEnter
  LD HL,(PagePointer)
  LD BC,$9D01
  AND A
  SBC HL,BC
  JR C,ReadEnter
  CALL ShowCatalogue
  RET
ReadEnter:
  LD A,$BF                ; ENTER: fire
  IN A,($FE)
  RRA
  CALL NC,FireKey
  LD A,$7F
  IN A,($FE)
  RRA
  JR C,ReadSymbolShift
  LD HL,(SavedHLAlt)
  EXX
  LD IY,(SavedIY)
  CALL SoundOff
  LD HL,Catalogue
  LD DE,$0000
  LD BC,$0805
  DI
  IM 1
  CALL TrdosEntry
  DI
  IM 2
  CALL ShowCatalogue
  RET
ReadSymbolShift:
  RRA                     ; SYMBOL SHIFT: the next page, when there is one
  RET C
  LD A,(MorePages)
  AND A
  RET Z
  LD HL,(NextPagePointer)
  XOR A
  LD (MorePages),A
  LD (ShowCatalogueAt+$0002),HL
  CALL ShowCatalogue
  LD HL,Catalogue
  LD (ShowCatalogueAt+$0002),HL
  RET

  ORG $6B53

; The letters A-X: the half-row (bits 7-5) and the key's bit mask (bits 4-0)
;
; Read by ReadKeyboard $6864.
KeyTable:
  INCBIN "res/tables/keys.bin",$0000,24
