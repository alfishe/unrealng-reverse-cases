; --------------------------------------------------------------------------------------------------------------------
; input.asm: The Kempston flag and the key scans
;
; ReadPort1F, the key characters and ScanKey, KeyToChar and AnyKey: the typed input (the name and gene editor), the
; map keys and the "any key" waits.
; --------------------------------------------------------------------------------------------------------------------

; 1 when Entry found a Kempston interface (port $1F reads below $1F), else 0
;
; Read by ReadPort1F $5B80 every frame (L1 413 183 reads).
KempstonFound:
  DEFB $00

; A = the Kempston port's bits inverted, or $FF when no interface
;
; Output: A = NOT IN ($1F) when KempstonFound, else $FF (CPL of 0). Called by
; ReadKempston $7A01 from the interrupt (L1 413 183, one a frame).
ReadPort1F:
  LD A,(KempstonFound)
  AND A
  JR Z,ReadPort1FDone
  IN A,($1F)
ReadPort1FDone:
  CPL                     ; CPL
  RET

; The character of each key, five a half row in ScanKey's order (CAPS SHIFT
; first), then the key found
;
; Row $FEFE from bit 0: $03 (CAPS SHIFT), Z X C V; $FDFE A S D F G; $FBFE Q W E
; R T; $F7FE 1-5; $EFFE 0 9 8 7 6; $DFFE P O I U Y; $BFFE $08 (ENTER as
; delete), L K J H; $7FFE SPACE, ".", M N B (SYMBOL SHIFT reads as ".").
; KeyFound at $5BB2 is ScanKey's result: the key's index, or $FF for none. Read
; by KeyToChar $5BDF (L1 1193 reads).
KeyChars:
  DEFB $03,$5A,$58,$43,$56,$41,$53,$44,$46,$47,$51,$57,$45,$52,$54,$31,$32,$33,$34,$35,$30,$39,$38,$37,$36,$50,$4F,$49,$55,$59,$08,$4C,$4B,$4A,$48,$20,$2E,$4D,$4E,$42
KeyFound:
  DEFB $00                ; ScanKey's result: the index into KeyChars of the
                          ; first key down, $FF for none

; Find the first key down in the nine rows: KeyFound = its index (carry clear),
; or $FF (carry set)
;
; Reads KeyRows $5B00-$5B08; CAPS SHIFT is ignored in the first row (D = $FE
; masks it). Output: carry set and KeyFound = $FF when no key is down, else
; carry clear and KeyFound = 5 row + column. L1 5451.
ScanKey:
  LD HL,KeyRows
  LD BC,$0900
  LD D,$FE
ScanRow:
  LD A,(HL)               ; the row's five bits, without CAPS SHIFT in the
                          ; first
  CPL
  AND $1F
  AND D
  JR NZ,ScanBit
  LD D,$FF
  LD A,C
  ADD A,$05
  LD C,A
  INC HL
  DJNZ ScanRow
  LD A,$FF
  LD (KeyFound),A
  SCF
  RET
ScanBit:
  RRCA                    ; find the bit
  JR NC,ScanNextBit
  LD A,C
  LD (KeyFound),A
  OR A
  RET
ScanNextBit:
  INC C                   ; one column on
  JR ScanBit

; One byte no code reads (L1: 0 reads); kept as bytes
ScanSpare:
  DEFB $00

; A = the character of the key down (KeyChars), carry set when none
;
; Used by the typed input: the city name (InputName $A6F9), the gene digits and
; the tool shortcut keys (ToolKeys $6D2D). L1 5451, 1193 with a key.
KeyToChar:
  CALL ScanKey
  RET C
  LD A,(KeyFound)
  LD E,A
  LD D,$00
  LD HL,KeyChars
  ADD HL,DE
  LD A,(HL)
  RET

; Z clear when any key of the nine rows is down
;
; Output: A = the first row's bits inverted (NZ) or 0 with Z. L1 2523 (the
; menus' key repeat, NumberRepeat $6A31).
AnyKey:
  LD B,$09
  LD HL,KeyRows
AnyKeyRow:
  LD A,(HL)               ; the next row
  CPL
  AND $1F
  RET NZ
  INC L
  DJNZ AnyKeyRow
  XOR A
  RET
