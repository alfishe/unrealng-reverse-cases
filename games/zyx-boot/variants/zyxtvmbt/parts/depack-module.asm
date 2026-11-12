; --------------------------------------------------------------------------------------------------------------------
; depack-module.asm: Move the packed stream to the top, unpack it to its place, return
;
; Called once by the loader. It saves SP, copies its last 100 bytes (DepackCopy) to DepackRun $5B8D in the printer
; buffer and returns into them; they move the packed stream up with LDDR so that it ends at the top of the area, then
; unpack it forward from the head's own address, the output overwriting the head and running up behind the stream's
; read position; three patch bytes are written last and the routine returns to the loader with the saved SP. The
; format: a byte 0lllhhhh and the next one copy lll+3 bytes from hhhh*256+next back, $80+n copies n literal bytes,
; $C0+n repeats the next byte n+3 times, $80 ends.
; --------------------------------------------------------------------------------------------------------------------

; Call the hook (a RET after the stream), save SP, copy DepackCopy to DepackRun
; and return into it with the stream's end, the top and the length in HL, DE,
; BC
Depack:
  CALL $C7D5
  DI
  LD (l_C06C+$0007),SP
  LD HL,DepackCopy
  LD DE,DepackRun
  LD BC,$0064
  PUSH DE
  LDIR
  LD HL,$C7D4
  LD DE,$C9D6
  LD BC,$0753
  RET

; Runs at DepackRun $5B8D: move the stream up (LDDR), then unpack it from its
; first byte to the head's address
DepackCopy:
  LDDR
  LD HL,$C284
  LD DE,Depack
  LD B,$00
DepackNext:
  LD A,(HL)               ; the next control byte
DepackTest:
  BIT 7,A                 ; A holds it (a copy or a fill ends here with it
                          ; already read)
  JR NZ,l_C04A
  AND $0F                 ; bit 7 clear: a copy from earlier output (RLD splits
                          ; the byte; the stream byte is changed, it is not
                          ; read again)
  LD B,A
  RLD
  ADD A,$03
  LD C,A
  INC HL
  LD A,E
  SUB (HL)
  INC HL
  LD SP,HL
  LD H,(HL)
  LD L,A
  LD A,D
  SBC A,B
  LD B,H
  LD H,A
  LD A,B
  LD B,$00
  LDIR
  LD H,B
  LD L,C
  ADD HL,SP
  JR DepackTest
l_C04A:
  AND $7F                 ; bit 7 set: $80 ends, $81-$BF literals, $C0-$FF a
                          ; fill
  JR Z,DepackEnd
  INC HL
  BIT 6,A
  JR NZ,l_C058
  LD C,A
  LDIR
  JR DepackNext
l_C058:
  AND $3F                 ; a fill: B = count, A = the byte, C = the next
                          ; control byte
  ADD A,$03
  LD B,A
  LD A,(HL)
  INC HL
  LD C,(HL)
l_C060:
  LD (DE),A
  INC DE
  DJNZ l_C060
  LD A,C
  JR DepackTest

; Write the three patch bytes (address, byte), restore SP (its operand written
; by Depack), return through RomRet
;
; Used by the routine at DepackCopy.
DepackEnd:
  LD SP,$5BE8
  LD B,$03
l_C06C:
  POP HL
  DEC SP
  POP AF
  LD (HL),A
  DJNZ l_C06C
  LD SP,$0000
  DI
  JP RomRet

; Three patches: address and byte (all zero: a byte 0 to $0000, the ROM)
DepackPatch:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00
