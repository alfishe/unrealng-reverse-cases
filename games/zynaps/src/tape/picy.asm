; "picy", the tape's block 6 (4096 bytes at $8000): the loading screen packed, with its own unpacker. The Hewson
; loader loads it and calls $8001 (docs/03-build-and-load.md 3.4). The screen is src/res/screens/loading.scr;
; tools/picy.py packs it into the three streams the build INCBINs (build/res/picy-*.bin).
;
; The format: the 6912 screen bytes are written in order from $4000. The flag stream has one byte per 64 output
; bytes, one bit (LSB first) per 8 of them: set, a mask byte follows in the mask stream; clear, the mask is 0. A mask
; has one bit (LSB first) per output byte: set repeats the previous output byte, clear takes the next literal. The
; first byte is always a literal (the carry kept in F' at the start). The packer marks every byte equal to the one
; before it as a repeat, so each stream is fixed by the screen.
;
; The unpacker is position independent: it finds its own address with a two-byte probe (POP HL; JP (HL)) written to
; $4000, which the screen clear then wipes, and reads the stream offsets relative to it.

  DEVICE ZXSPECTRUM48
  ORG $8000

Screen      EQU $4000
ScreenSize  EQU $1B00           ; 6144 pixel bytes and 768 attributes
Groups      EQU ScreenSize/64   ; 108 flag bytes

Picy:
  DB 0                          ; the byte before the entry (not run)
PicyEntry:
  JR Unpack                     ; the loader calls here
PicyHeader:                     ; the offsets below are from PicyEntry
  DB 0
  DW Literals-PicyEntry         ; +3
  DW Masks-PicyEntry            ; +5
  DW Flags-PicyEntry            ; +7
  DB 0                          ; +9: the border colour, black

Unpack:
  DI
  PUSH IX
  PUSH IY
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  LD HL,$E9E1                   ; POP HL; JP (HL)
  LD (Screen),HL
  CALL Screen                   ; HL = the address after this CALL
WhereAmI:
  LD DE,PicyEntry-WhereAmI      ; -28: HL = PicyEntry
  ADD HL,DE
  PUSH HL
  POP IX                        ; IX: the header
  PUSH HL
  LD A,(IX+9)
  OUT ($FE),A                   ; the border
  LD HL,Screen                  ; the screen cleared (the probe too)
  LD DE,Screen+1
  LD BC,ScreenSize-1
  LD (HL),0
  LDIR
  POP DE                        ; DE = PicyEntry
  LD L,(IX+3)
  LD H,(IX+4)
  ADD HL,DE
  PUSH HL
  POP IY                        ; IY: the literals
  LD L,(IX+5)
  LD H,(IX+6)
  ADD HL,DE
  PUSH HL                       ; the masks
  LD L,(IX+7)
  LD H,(IX+8)
  ADD HL,DE
  EX DE,HL                      ; DE: the flags
  POP HL                        ; HL: the masks
  LD IX,Screen                  ; IX: the output
  SCF                           ; carry' set: the first byte is a literal
  EX AF,AF'
  LD B,Groups
UnpackGroup:
  LD C,1                        ; the flag bit
UnpackEight:
  LD A,(DE)
  AND C
  LD A,0                        ; no mask byte: eight literals
  JR Z,UnpackMask
  LD A,(HL)
  INC HL
UnpackMask:
  PUSH BC
  LD C,A                        ; C: the mask
  LD B,1                        ; the mask bit
UnpackByte:
  EX AF,AF'
  JR C,UnpackLiteral            ; the first byte
  LD A,C
  AND B
  JR NZ,UnpackRepeat
UnpackLiteral:
  LD A,(IY+0)
  LD (IX+0),A
  INC IY
  JR UnpackNext
UnpackRepeat:
  DEC IX                        ; the previous output byte again
  LD A,(IX+0)
  INC IX
  LD (IX+0),A
UnpackNext:
  INC IX
  XOR A                         ; carry' clear from now on
  EX AF,AF'
  SLA B
  JR NC,UnpackByte
  POP BC
  SLA C
  JR NC,UnpackEight
  INC DE
  DJNZ UnpackGroup
  POP AF
  POP BC
  POP DE
  POP HL
  POP IY
  POP IX
  EI
  RET

Literals:
  INCBIN "res/picy-literals.bin"
Masks:
  INCBIN "res/picy-masks.bin"
Flags:
  INCBIN "res/picy-flags.bin"
  DS 6                          ; zeros to the block's 4096 bytes
PicyEnd:

  ASSERT PicyEnd-Picy == 4096
  SAVEBIN "picy.bin",Picy,PicyEnd-Picy
