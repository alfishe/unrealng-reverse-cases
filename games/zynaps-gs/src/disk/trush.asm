; trush.asm: one self-unpacking block of "COMPRESSOR BY ALEXANDER TRUSH ODESSA", the packer of every packed block on
; the disk (38 of them). docs/03-build-and-load.md 3.4.
;
; The block is loaded at TRUSH_BASE and called there. It moves its packed stream up so that the stream ends at
; TRUSH_DEST_END, copies its depacker over its own head and runs it; the depacker writes the output from
; TRUSH_BASE + $CE upwards, reading the stream through SP, then moves the output down so that it ends at
; TRUSH_DEST_END, and returns with interrupts enabled.
;
; The stream is tools/trush.py's (pack): bytes and 16-bit bit words interleaved in the order the depacker pops
; them. Token 0: a literal byte. Token 1 + a length code: 00 = 3, 010 = 2 (a one-byte offset follows), 011 = a
; length byte ($FF ends the stream, $FE: a 16-bit length follows, n: n + 10), 100 = 4, 101 = 5, 11xx = 6..9; then
; the offset: 1 + a byte (1..256) or 0 + a high-part code + a byte (257..8192). A copy may overlap (LDIR).
;
; Assembled with (tools/build.sh, one block at a time, in the block's own folder):
;   sjasmplus -DTRUSH_BASE=n -DTRUSH_DEST_END=n -DTRUSH_LEN=n src/disk/trush.asm
; with the stream in stream.bin; writes block.bin.

RomLdirRet      EQU $33C3       ; the 48K ROM's LDIR : RET (in the calculator's MOVE-FP), the block's copy gadget

  OUTPUT "block.bin"
  ORG TRUSH_BASE

; TrushBlock: the entry. Keeps HL' (the caller's), moves the stream up to end at TRUSH_DEST_END, puts SP on its
; first byte (IX keeps the caller's SP) and copies the depacker over this head through the ROM, which returns to it.
TrushBlock:
    DI
    LD B,16                     ; B' = 16: the bit counter of the first bit word
    EXX
    PUSH HL                     ; HL' of the caller
    LD HL,StreamEnd-1
    LD DE,TRUSH_DEST_END
    LD BC,StreamEnd-Stream
    PUSH DE                     ; the output's end, for the last move
    LDDR                        ; the stream up to end at TRUSH_DEST_END
    EX DE,HL
    INC HL                      ; HL = the stream's first byte, moved
    LD IX,0
    ADD IX,SP                   ; IX = SP (points at the output's end)
    LD SP,HL                    ; the depacker reads the stream through SP
    LD HL,Depacker
    LD DE,TrushBlock
    LD BC,DepackerEnd-Depacker
    PUSH DE                     ; the ROM gadget returns into the copied depacker
    JP RomLdirRet
Name:
    DB "COMPRESSOR BY ALEXANDER TRUSH ODESSA"

; Depacker: runs at TRUSH_BASE once copied (all its jumps are relative). B' = the bits left in HL', the bit word;
; DE' = the output, from TRUSH_BASE + $CE upwards; C' and A the token's length and offset parts.
Depacker:
  DISP TRUSH_BASE
Depack:
    EXX
    POP HL                      ; the first bit word
    JR NextToken
Literal:
    DEC SP
    POP AF                      ; A = the next stream byte
    EXX
    LD (DE),A
    INC DE
    EXX
NextToken:
    ADD HL,HL                   ; the token bit
    DJNZ .bit
    POP HL                      ; the word is used up: the next one at once
    LD B,16
.bit:
    JR NC,Literal
; a match: the length code, 2 to 4 bits, into A
    SUB A
    ADD HL,HL
    DJNZ .b1
    POP HL
    LD B,16
.b1:
    RLA
    ADD HL,HL
    DJNZ .b2
    POP HL
    LD B,16
.b2:
    RL A
    JR Z,Length                 ; 00: length 3
    ADD HL,HL
    DJNZ .b3
    POP HL
    LD B,16
.b3:
    RLA
    CP 6
    JR C,Length                 ; 010, 011, 100, 101
    ADD HL,HL
    DJNZ .b4
    POP HL
    LD B,16
.b4:
    RLA                         ; 11xx: 12..15
Length:
    EXX
    LD H,B                      ; H' = 0 (B' is 0 here): the offset's high part of a one-byte offset
    CP 2
    JR NZ,.long
    LD C,A                      ; 010: length 2, a one-byte offset
    JR ShortOffset
.long:
    JR C,Length3                ; 00
    CP 3
    JR NZ,LengthCode
    DEC SP                      ; 011: a length byte
    POP AF
    INC A
    JR Z,Done                   ; $FF: the end
    INC A
    JR Z,Length16               ; $FE: a 16-bit length
    ADD A,8                     ; n + 10
    JR NC,SetLength
    INC B                       ; past 255: B = 1
    JR SetLength
CopyBack:
    EXX
ShortOffset:
    DEC SP
    POP AF                      ; the offset's low byte
    LD L,A
    SCF
    LD A,E
    SBC A,L
    LD L,A
    LD A,D
    SBC A,H
    LD H,A                      ; HL = DE - offset (offset = H:L + 1)
    LDIR                        ; the copy (it may overlap)
    EXX
    JR NextToken
Length16:
    POP BC                      ; the 16-bit length
    JR OffsetKind
LengthCode:
    CP 6
    JR C,SetLength              ; 100, 101: 4, 5
    SUB 9                       ; 11xx: 6..9 (12..15 - 6)
Length3:
    ADD A,3                     ; 00: 0 + 3
SetLength:
    LD C,A
OffsetKind:
    EXX
    ADD HL,HL                   ; 1: a one-byte offset, 0: a high part first
    DJNZ .k
    POP HL
    LD B,16
.k:
    JR C,CopyBack
    XOR A                       ; the high-part code: 3 bits first
    ADD HL,HL
    DJNZ .h1
    POP HL
    LD B,16
.h1:
    RLA
    ADD HL,HL
    DJNZ .h2
    POP HL
    LD B,16
.h2:
    RLA
    ADD HL,HL
    DJNZ .h3
    POP HL
    LD B,16
.h3:
    RLA
    CP 2
    JR NC,.h4
    INC A                       ; 000, 001: 1, 2
.high:
    EXX
    LD H,A
    JR ShortOffset
.h4:
    ADD HL,HL
    DJNZ .h5
    POP HL
    LD B,16
.h5:
    RLA
    CP 8
    JR NC,.h6
    DEC A                       ; 0100..0111: 3..6
    JR .high
.h6:
    ADD HL,HL
    DJNZ .h7
    POP HL
    LD B,16
.h7:
    RLA
    CP $17
    JR NC,.h8
    SUB 9                       ; 10000..10110: 7..13
    JR .high
.h8:
    ADD HL,HL
    DJNZ .h9
    POP HL
    LD B,16
.h9:
    RLA
    AND $1F                     ; 101110..111111: 14..31
    JR .high
; Done: the output (DE' - 1 its last byte) moves down to end at TRUSH_DEST_END; back to the caller
Done:
    LD SP,IX
    DEC DE
    EX DE,HL
    POP DE                      ; TRUSH_DEST_END
    LD BC,TRUSH_LEN
    LDDR
    POP HL                      ; the caller's HL'
    EXX
    EI
    RET
  ENT
DepackerEnd:
Stream:
  INCBIN "stream.bin"
StreamEnd:
