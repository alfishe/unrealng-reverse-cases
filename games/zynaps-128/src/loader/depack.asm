; --------------------------------------------------------------------------------------------------------------------
; depack.asm: the Hrust 1 depacker (Dmitry Pyankov's HR format), unpacking in place
;
; The loader reads it to $5B00 and enters it by JP with HL = the packed block (its "HR" header) and DE = the
; destination; here both are $6000. The return address is the loader's: Depack ends with a RET.
;
; The block is first moved up so that its last byte lies on the last byte of the destination (LDDR), then unpacked
; forward from the destination: the output never overtakes the input. The six last bytes of the data, which the header
; holds apart, are put in a buffer under the stack (IX) and written by the end code as three words; the end code also
; points SP back at the return address.
;
; Two register sets. The main set: DE the output, HL the source of a copy, BC its length. The alternate set: HL the
; bit word (bits leave through ADD HL,HL, MSB first), B the bits left in it, C = 16, D the window's marker byte (its 0
; bit says how many high bits a long distance has: 2 at the start, one more after each $FE escape), E the length being
; built. Bit groups are read into A with a marker: A starts with a pattern whose first 0 bit, shifted out by RLA, ends
; the loop after the wanted number of bits.
;
; The tokens are those of tools/hrust1.py: flag 1 a literal; flag 0 then a length code (2-bit groups, 1 + 3 for each
; 11) and a distance code; 11 00 opens the special codes (an X ? X with a short distance, a run of literal words, a
; long length, the end).
; --------------------------------------------------------------------------------------------------------------------

; unpack the HR block at HL to DE in place, return to the caller's caller
;
; Input: HL = the packed block (header "HR", the unpacked length, the packed
; length, the last 6 bytes, the stream), DE = the destination. Output: the data
; at DE; SP back where it was; HL' = ROM_HL_ALT for BASIC. Uses every register,
; IX, the 12 bytes under the stack.
Depack:
  LD IX,$FFF4             ; IX: 12 bytes under the stack (the destination, then
                          ; the last 6 bytes)
  ADD IX,SP
  PUSH DE                 ; the destination at IX+10
  LD SP,HL                ; read the header through SP: "HR", the lengths
  POP BC
  EX DE,HL
  POP BC                  ; the unpacked length - 1: DE = the last byte of the
                          ; destination
  DEC BC
  ADD HL,BC
  EX DE,HL
  POP BC                  ; the packed length - 1: HL = the last byte of the
                          ; block
  DEC BC
  ADD HL,BC
  SBC HL,DE               ; the block's end below the destination's end: move
                          ; it up there; else it stays
  ADD HL,DE
  JR C,MoveBlock
  LD D,H                  ; no move: copy the block onto itself
  LD E,L
MoveBlock:
  LDDR                    ; the block to the top of the destination, from its
                          ; end down
  EX DE,HL
  LD D,(IX+$0B)           ; DE = the destination again
  LD E,(IX+$0A)
  LD SP,HL                ; SP on the moved block: skip "HR" and the two
                          ; lengths
  POP HL
  POP HL
  POP HL
  LD B,$06                ; the 6 last bytes to IX+6..IX+11, one byte a DEC SP
                          ; / POP AF
SaveLast6:
  DEC SP
  POP AF
  LD (IX+$06),A
  INC IX
  DJNZ SaveLast6
  EXX                     ; the bit reader: D = the window's marker (2 bits of
                          ; high distance), B = C = 16, the first word
  LD D,$BF
  LD BC,$1010
  POP HL
Literal:
  DEC SP                  ; a byte from the stream (DEC SP / POP AF takes one
                          ; byte), to the output
  POP AF
  EXX
PutByte:
  LD (DE),A               ; the byte in A to the output
  INC DE
NextToken:
  EXX                     ; back to the bit reader's set
TokenFlag:
  ADD HL,HL               ; the next bit: 1 a literal, 0 a match
  DJNZ TokenFlagIn
  POP HL
  LD B,C
TokenFlagIn:
  JR C,Literal
Match:
  LD E,$01                ; E = 1: the length is built from 2-bit groups
LengthGroup:
  LD A,$80                ; two bits into A (the marker $80)
LengthBit:
  ADD HL,HL
  DJNZ LengthBitIn
  POP HL
  LD B,C
LengthBitIn:
  RLA
  JR C,LengthBit
  CP $03                  ; 0-2 ends the code; 3 adds 3 to E and reads another
                          ; group, up to 16
  JR C,LengthDone
  ADD A,E
  LD E,A
  XOR C
  JR NZ,LengthGroup
LengthDone:
  ADD A,E                 ; A = the length code: 4 (11 00) opens the special
                          ; codes
  CP $04
  JR Z,Special
  ADC A,$FF               ; past 4 the code is the length + 1
  CP $02                  ; length 1: a 3-bit distance; length 2: its own
                          ; distance codes
  EXX
SetLength:
  LD C,A                  ; C = the length (the main set)
Distance:
  EXX                     ; the distance's code: two bits under the marker $BF
  LD A,$BF
  JR C,ShortDistance
DistanceBit:
  ADD HL,HL
  DJNZ DistanceBitIn
  POP HL
  LD B,C
DistanceBitIn:
  RLA
  JR C,DistanceBit
  JR Z,Len2Distance       ; length 2: Len2Distance
  INC A                   ; length 3 and more: 00 -> $FE (-512 + a byte), 01 ->
                          ; $FF (-256 + a byte), 10 -> 5 bits, 11 -> the
                          ; window's high bits
  ADD A,D
  JR NC,HighBits
  SUB D
Len2Distance:
  INC A                   ; length 2: 00 / 01 / 10 -> high byte $FD / $FE / $FF
                          ; and a low byte; 11 -> 5 bits
  JR NZ,SetHigh
  LD A,$EF                ; a 5-bit distance (the marker $F7 after RRCA):
                          ; -32..-1
ShortDistance:
  RRCA                    ; length 1 comes here with $BF: RRCA makes $DF, 3
                          ; bits, -8..-1
  CP A
HighBits:
  ADD HL,HL               ; bits under the marker in A: the short distance, or
                          ; the high byte under the window's marker D
  DJNZ HighBitsIn
  POP HL
  LD B,C
HighBitsIn:
  RLA
  JR C,HighBits
SetHigh:
  EXX                     ; H = the high byte ($FF for a short distance), L =
                          ; the low byte: the copy's source
  LD H,$FF
  JR Z,CopyMatch
  LD H,A                  ; a high byte of $FF: the low byte may be an escape
  DEC SP
  INC A
  JR Z,ByteDistance
  POP AF                  ; the low byte from the stream
CopyMatch:
  LD L,A                  ; HL = DE + the negative distance; C bytes copied
  ADD HL,DE
  LDIR
NextTokenJump:
  JR NextToken
GrowWindow:
  EXX                     ; the $FE escape: the window's marker D rotated, one
                          ; more high bit for long distances
  RRC D
  JR TokenFlag
ByteDistance:
  POP AF                  ; a low byte with high byte $FF: below $E0 a distance
                          ; -256..-33, else an X ? X
  CP $E0
  JR C,CopyMatch
  RLCA                    ; rol(b) xor the length (2 or 3), + 1: $FE with
                          ; length 2 grows the window
  XOR C
  INC A
  JR Z,GrowWindow
  SUB $10                 ; the X ? X distance
InsertCopy:
  LD L,A                  ; X ? X: one byte from the distance, one literal, one
                          ; byte from the distance
  LD C,A
  LD H,$FF
  ADD HL,DE
  LDI
  DEC SP
  POP AF
  LD (DE),A
  INC HL
  INC DE
  LD A,(HL)
  JR PutByte
Special:
  LD A,$80                ; 11 00: 1 -> an X ? X with a 4-bit distance; 01 -> a
                          ; run of literal words; 00 -> a 7-bit length code
SpecialBit:
  ADD HL,HL
  DJNZ SpecialBitIn
  POP HL
  LD B,C
SpecialBitIn:
  ADC A,A
  JR NZ,FourBits
  JR C,SpecialBit
  LD A,$FC                ; 00: seven bits (the marker $FC)
  JR FourBit
LongLength:
  DEC SP                  ; a code below 15: the length is code * 256 + a byte
                          ; from the stream
  POP BC
  LD C,B
  LD B,A
  CCF
  JR Distance
LengthOrEnd:
  CP $0F                  ; the 7-bit code: below 15 a long length, 15 the end,
                          ; above it the length itself
  JR C,LongLength
  JR NZ,SetLength
  ADD A,$F4               ; the end: A = 3 words, SP on the six saved bytes
  LD SP,IX
  JR CopyWords
FourBits:
  SBC A,A                 ; four bits (the marker $EF): an X ? X distance
                          ; -16..-1, or the run's count
  LD A,$EF
FourBit:
  ADD HL,HL
  DJNZ FourBitIn
  POP HL
  LD B,C
FourBitIn:
  RLA
  JR C,FourBit
  EXX
  JR NZ,InsertCopy
  BIT 7,A                 ; a run of literals: (v + 6) words
  JR Z,LengthOrEnd
  SUB $EA
CopyWords:
  EX DE,HL                ; A words from SP to the output (a run from the
                          ; stream, or the six saved bytes at the end)
CopyWord:
  POP DE
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  DEC A
  JR NZ,CopyWord
  EX DE,HL
  JR NC,NextTokenJump     ; not the end: the next token
  LD HL,ROM_HL_ALT             ; the end: HL' as BASIC wants it; RET from the
                          ; restored SP to the caller
  EXX
  RET
