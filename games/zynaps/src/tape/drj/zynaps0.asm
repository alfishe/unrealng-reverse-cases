; zynaps0.c of the 1993 re-tape (ZYNAPS.TAP block 3: 3252 bytes at $C350, entered by RANDOMIZE USR 5e4): the
; Hewson loading screen packed with a column-order RLE, and its unpacker. docs/03-build-and-load.md 3.6.
;
; The stream (tools/rle_drj.py packs src/res/screens/loading.scr into build/res/drj-screen.rle): the pixel bytes
; column by column (x 0-31; in each, the three thirds, their 8 character rows, each row's 8 lines top down), then
; the 768 attributes in order. $D1 n: n zeros; $D4 v n: n times v (n = 0: 256); any other byte is itself. The packer
; writes every run of 3 or more as a token (a zero run as $D1), shorter ones as bytes.

  DEVICE ZXSPECTRUM48
  ORG $C350

Screen      EQU $4000
Attrs       EQU $5800
RomRet      EQU $1792           ; a RET in the 48K ROM: the CALL comes straight back, its return address left
                                ; below SP, where the next three instructions read it
ZeroRun     EQU $D1
ValueRun    EQU $D4

Unrle:
  DI
  CALL RomRet                   ; returns at once: the address after the CALL stays below SP
WhereAmI:
  DEC SP
  DEC SP
  POP HL                        ; HL = WhereAmI
  LD DE,Stream-WhereAmI
  ADD HL,DE
  PUSH HL
  EXX
  POP DE                        ; DE': the stream
  LD B,0                        ; B': no run going
  EXX
  LD HL,Screen
  LD D,32                       ; columns
UnrleColumn:
  PUSH HL
  LD E,3                        ; thirds
UnrleThird:
  PUSH DE
  PUSH HL
  LD C,8                        ; character rows
UnrleRow:
  PUSH HL
  LD B,8                        ; lines
UnrleLine:
  EXX
  LD A,B
  CP 0
  JR NZ,UnrleRunByte
  LD A,(DE)
  LD C,0
  CP ZeroRun
  JR Z,UnrleCount
  CP ValueRun
  INC DE
  JR NZ,UnrlePut                ; a plain byte
  LD A,(DE)
  LD C,A                        ; the run's value
UnrleCount:
  INC DE
  LD A,(DE)
  LD B,A                        ; the run's length
  INC DE
UnrleRunByte:
  DEC B
  LD A,C
UnrlePut:
  EXX
  LD (HL),A
  INC H                         ; the next line down
  DJNZ UnrleLine
  POP HL
  LD DE,32                      ; the next character row
  ADD HL,DE
  DEC C
  JR NZ,UnrleRow
  POP HL
  LD DE,$0800                   ; the next third
  ADD HL,DE
  POP DE
  DEC E
  JR NZ,UnrleThird
  POP HL
  INC HL                        ; the next column
  DEC D
  JR NZ,UnrleColumn
  LD HL,Attrs
  LD BC,768
UnrleAttr:
  EXX
  LD A,B
  CP 0
  JR NZ,UnrleAttrRun
  LD A,(DE)
  LD C,0
  CP ZeroRun
  JR Z,UnrleAttrCount
  CP ValueRun
  INC DE
  JR NZ,UnrleAttrPut
  LD A,(DE)
  LD C,A
UnrleAttrCount:
  INC DE
  LD A,(DE)
  LD B,A
  INC DE
UnrleAttrRun:
  DEC B
  LD A,C
UnrleAttrPut:
  EXX
  LD (HL),A
  INC HL
  DEC BC
  LD A,B
  OR C
  JR NZ,UnrleAttr
  EI
  RET
Stream:
  INCBIN "res/drj-screen.rle"
Zynaps0End:

  SAVEBIN "zynaps0.bin",Unrle,Zynaps0End-Unrle
