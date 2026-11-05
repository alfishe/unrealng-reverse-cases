; Copied from ../advanced-nether-earth/src/sfx/hrum35.asm (the cases stay apart: no include across them). The
; boot file's HRUM block is the same HRUM 3.5 self-extractor, byte for byte (src/trd/boot/boot.asm).
;
; HRUM 3.5 (Dmitry Pyankov, credited in NETHER+.W): the self-extracting block every packed part of ANE is stored
; as. docs/03-build-and-load.md 4.
;
; A block is 31 bytes of set-up, the 119-byte depacker and the packed stream. The set-up copies the depacker to a
; free place (Depacker: $5B89 in the loader's blocks, $FE4C in the game's, $5B00 for bank 7's), moves the stream up
; so that it ends where the unpacked bytes will end (LDDR, run by the depacker copy as its first instruction: the
; set-up RETs into it) and the depacker unpacks it from Out upwards, over the stream's own start: the output never
; catches up with the unread stream because the stream is shorter. The last 5 bytes of the output are not in the
; stream: they sit in the depacker's tail (.dpTail) and are copied last, over the stream's last bytes.
;
; The stream (tools/hrum.py has the format and the packer): words of 16 flag bits read with POP (the first word is
; the bit count 16 and the bits left, then the first flag word), bytes read with DEC SP; POP AF. After the first
; literal: flag 1 a literal byte; flag 0 a match, its length code a 2-bit Elias-like sequence (1, 2, 3, a byte,
; 4-15), its offset 3 bits (length 1), a byte (length 2, or a flag 0) or 4 bits and a byte (a flag 1).
;
; HRUM_SFX parameters (all set per block by the block's own file):
;   EntryEi   1: the set-up starts with EI (the boot menu's blocks, run from a CALL in a program that keeps
;             interrupts on), 0: DI
;   SpSave    where the set-up keeps SP: the depacker copy's LD SP operand (the block returns to its caller), or
;             0 (written to the ROM, lost: the block ends with ExitSp)
;   Depacker  where the depacker runs
;   Out       the first unpacked byte
;   OutLen    the unpacked length (with the 5 tail bytes)
;   Stream    the packed stream's file (tools/hrum.py pack), StreamLen its length
;   TailFile  the unpacked file: its last 5 bytes are the tail
;   ExitSp    the SP the depacker sets at the end (0 with SpSave: the saved one)
;   ExitEi    1: EI at the end, 0: DI
;   ExitJp    0: RET (to the set-up's caller), else JP ExitJp

  MACRO HRUM_SFX EntryEi, SpSave, Depacker, Out, OutLen, Stream, StreamLen, TailFile, ExitSp, ExitEi, ExitJp
.setup:
    IF EntryEi
      EI
    ELSE
      DI
    ENDIF
    IF SpSave
      LD (.depacker + .dpSp + 1 - .dpStart),SP  ; the caller's SP into the copy's LD SP,nn
    ELSE
      LD (0),SP                 ; nowhere: this block does not return
    ENDIF
    LD HL,.depacker
    LD DE,Depacker
    LD BC,.dpEnd - .dpStart
    PUSH DE                     ; the set-up's RET enters the copy
    LDIR
    LD DE,Out                   ; DE' = the output pointer
    EXX
    LD HL,.stream + StreamLen - 1     ; LDDR: the stream's last byte ...
    LD DE,Out + OutLen - 1            ; ... to the output's last byte
    LD BC,StreamLen
    RET
.depacker:
    DISP Depacker
.dpStart:
    LDDR                        ; move the stream up (overlapping, so from its end)
    LD D,3                      ; the length code's limit for a 2-bit step
    LD SP,Out + OutLen - StreamLen    ; SP = the stream's first byte after the move
    POP BC                      ; C = 16 (bits a flag word), B = the bits of the first word
    POP HL                      ; the first flag word
.dpLiteral:
    DEC SP
    POP AF                      ; A = the next stream byte (SP + 1)
    EXX
    LD (DE),A                   ; out
    INC DE
.dpNext:
    EXX
    ADD HL,HL                   ; the next flag: carry
    DJNZ .flag1
    POP HL                      ; the word is used up: the next one, read at once
    LD B,C
.flag1:
    JR C,.dpLiteral          ; 1: a literal
    LD E,1                      ; 0: a match; its length code, E the base
.code:
    LD A,$80                    ; two bits into A (the marker bit falls out after the second)
.code2:
    ADD HL,HL
    DJNZ .flag2
    POP HL
    LD B,C
.flag2:
    RLA
    JR C,.code2
    CP D
    JR C,.codeEnd               ; 0-2: the code is E + A
    ADD A,E                     ; 3: E + 3, and two more bits, until E = 16
    LD E,A
    XOR C
    JR NZ,.code
.codeEnd:
    ADD A,E                     ; A = the code, 1-16
    CP D
    CCF
    JR NC,.dpOffset          ; 1, 2: the length itself, no offset flag (carry clear)
    SBC A,D
    JR Z,.dpLong             ; 4: the length in a byte
    ADC A,D                     ; 3: 3; 5-16: 4-15
.dpFarFlag:
    ADD HL,HL                   ; the offset flag: 1 = 12 bits, 0 = 8 bits
    DJNZ .dpOffset
    POP HL
    LD B,C
.dpOffset:
    EXX
    LD C,A                      ; BC' = the length (B' is 0 after every LDIR)
    LD H,$FF
    DEC A
    LD A,$3F                    ; 3 bits of offset (the marker in bit 5)
    JR Z,.bits                  ; length 1: offset -8..-1
    JR NC,.dpLow             ; flag 0 (or length 2): offset -256..-1, a byte
    RES 5,A                     ; flag 1: 4 bits, then a byte
.bits:
    EXX
.bit:
    ADD HL,HL
    DJNZ .flag3
    POP HL
    LD B,C
.flag3:
    RLA
    JR NC,.bit
    EXX
    JR Z,.dpCopy             ; length 1: the 3 bits are the offset's low byte ($F8-$FF)
    LD H,A                      ; else the high byte ($F0-$FF)
.dpLow:
    DEC SP
    POP AF                      ; the offset's low byte
.dpCopy:
    LD L,A
    ADD HL,DE                   ; HL = DE + the (negative) offset
    LDIR
    JR .dpNext
.dpLong:
    DEC SP
    POP AF                      ; the length byte; 0 ends the stream
    AND A
    JR NZ,.dpFarFlag
    EXX
    LD HL,.dpTail            ; the 5 last bytes, kept here
    LD C,5
    LDIR
    LD HL,$2758                 ; HL' as BASIC needs it
    EXX
.dpSp:
    LD SP,ExitSp                ; with SpSave: the caller's SP, written by the set-up
    IF ExitEi
      EI
    ELSE
      DI
    ENDIF
    IF ExitJp
      JP ExitJp
    ELSE
      RET
      DW 0
    ENDIF
.dpTail:
    INCBIN TailFile,-5
.dpEnd:
    ENT
.stream:
    INCBIN Stream
  ENDM
