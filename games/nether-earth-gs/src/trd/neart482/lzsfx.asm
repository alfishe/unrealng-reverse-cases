; lzsfx.asm: the self-extracting block Neart482 is stored as, twice (its outer block, neart482.asm, and the inner
; one inside the unpacked intro, intro.asm). The packer is not named on the disk and matches no entry of the
; signature base; its format and a packer that gives both streams back are tools/trd_lz.py.
;
; A block: CALL to a RET (BlockHook: the byte after the stream), the set-up (30 bytes), the 100-byte depacker, the
; stream, the RET. The set-up keeps the caller's SP in the depacker's LD SP, copies the depacker to Depacker ($5B8D,
; the printer buffer's end), moves the stream up with LDDR so that it ends at MovedEnd (run by the copy as its first
; instruction: the set-up RETs into it) and the copy unpacks from Out upwards. The packer leaves the last bytes of
; the data raw: the LDDR puts them in place, the stream ends before them.
;
; The stream, read forwards, a byte-aligned token at a time:
;   0LLLHHHH LLLLLLLL   a match: length LLL + 3, from HHHH:LLLLLLLL bytes back (RLD takes the length out)
;   10NNNNNN bytes      a literal run of NNNNNN bytes; $80 ends the stream
;   11NNNNNN B          NNNNNN + 3 copies of B
; Then three pokes from the table at the copy's end (address, byte; all zero here: three writes to ROM address 0),
; the caller's SP back, EI and JP ExitJp.
;
; LZ_SFX parameters:
;   Depacker   where the depacker runs ($5B8D)
;   Out        the first unpacked byte
;   MovedEnd   the moved stream's last byte: the unpacked data's last byte (the raw bytes end there)
;   Stream     the stream's file (tools/trd_lz.py pack --raw N), StreamLen its length (with the N raw bytes)
;   ExitJp     where the unpacked program starts

  MACRO LZ_SFX Depacker, Out, MovedEnd, Stream, StreamLen, ExitJp
.block:
    CALL .hook                  ; a RET: nothing (a place for a patch)
    DI
    LD (.depacker + .dpSp + 1 - .dpStart),SP  ; the caller's SP into the copy's LD SP,nn
    LD HL,.depacker
    LD DE,Depacker
    LD BC,.dpEnd - .dpStart
    PUSH DE                     ; the set-up's RET enters the copy
    LDIR
    LD HL,.stream + StreamLen - 1     ; LDDR: the stream's last byte ...
    LD DE,MovedEnd                    ; ... to the data's last byte
    LD BC,StreamLen
    RET
.depacker:
    DISP Depacker
.dpStart:
    LDDR                        ; the stream moved up (overlapping: from its end)
    LD HL,MovedEnd - StreamLen + 1    ; the moved stream's first token
    LD DE,Out
    LD B,0                      ; B = 0 for the LDIRs of the literal runs (every token leaves it 0)
.dpToken:
    LD A,(HL)
.dpTest:                        ; A = the token at HL
    BIT 7,A
    JR NZ,.dpNotMatch
    AND $0F                     ; a match: B = the offset's high bits
    LD B,A
    RLD                         ; A = the token's high nibble: the length - 3 (the token byte is spoiled)
    ADD A,3
    LD C,A                      ; BC: B the offset high, C the length
    INC HL
    LD A,E
    SUB (HL)                    ; the offset's low byte
    INC HL
    LD SP,HL                    ; SP keeps the next token's address
    LD H,(HL)                   ; H = the next token
    LD L,A
    LD A,D
    SBC A,B
    LD B,H                      ; B = the next token for a moment
    LD H,A                      ; HL = DE - the offset
    LD A,B                      ; A = the next token
    LD B,0                      ; BC = the length
    LDIR
    LD H,B
    LD L,C                      ; HL = 0 ...
    ADD HL,SP                   ; ... + SP: the next token's address
    JR .dpTest
.dpNotMatch:
    AND $7F
    JR Z,.dpEnd0                ; $80: the end
    INC HL
    BIT 6,A
    JR NZ,.dpRun
    LD C,A                      ; a literal run: C bytes copied (B = 0)
    LDIR
    JR .dpToken
.dpRun:
    AND $3F
    ADD A,3
    LD B,A                      ; the count
    LD A,(HL)                   ; the byte
    INC HL
    LD C,(HL)                   ; the next token
.dpFill:
    LD (DE),A
    INC DE
    DJNZ .dpFill
    LD A,C
    JR .dpTest
.dpEnd0:
    LD SP,.dpPokes
    LD B,3
.dpPoke:                        ; three pokes: (address, byte)
    POP HL
    DEC SP
    POP AF                      ; A = the byte after the address
    LD (HL),A
    DJNZ .dpPoke
.dpSp:
    LD SP,0                     ; the caller's SP, written by the set-up
    EI
    JP ExitJp
.dpPokes:
    DS 9                        ; the poke table: three times address 0, byte 0
.dpEnd:
    ENT
.stream:
    INCBIN Stream
.hook:
    RET
  ENDM
