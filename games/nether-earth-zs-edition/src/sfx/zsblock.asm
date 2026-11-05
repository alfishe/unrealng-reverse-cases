; zsblock.asm: the self-extracting block of NEZSEd99.B (every packed block of the '99 release).
;
; A block is read from disk to its address AT and entered there (CALL AT from the loader, or the BASIC reader's
; RET into $8000). Its 22-byte set-up copies the depacker to $5B00 (the printer buffer), points DE / HL / BC at the
; stream and RETs into the copy; the copy's first LDIR moves the packed stream down to AT (over the set-up), then
; the stream is read backwards from its last byte and the output written backwards from DST_END down to STOP + 1.
; The token format is in tools/zsdepack.py and docs/03-build-and-load.md 3.4; tools/zspack.py packs.
;
; The depacker copy at $5B00-$5B99 is also why the '99 hangs when started from the Pentagon 128 menu's TR-DOS
; item: the Pentagon 48 BASIC ROM's IM 1 handler then writes $5B88 (DepackGetBits+5, the RL C) in every frame.
;
; Assembled once a block by tools/build.sh, which gives the parameters with -D (src/sfx/blocks.txt):
;   AT       where the block is read and entered
;   LEN      the packed stream's length in bytes (STREAM's size)
;   DST_END  the last output byte (the depacker writes from here down)
;   STOP     the byte below the first output byte (the loop ends when DE drops below STOP + 1)
;   FARBITS  the far offset's bits: 11 (stage 2, the game) or 10 (stage 3, patches, menu)
;   DONE     where the depacker jumps when done: $61A8 for the two loader stages, $0052 (a RET in the ROM) for the
;            blocks stage 3 CALLs
;   STREAM   the packed stream file (tools/zspack.py output), a string
;   OUT      the block's file

  ORG AT
  OUTPUT OUT
Setup:                         ; at AT: copy the depacker to $5B00 and enter it
  LD DE,DepackStart             ; the copy's address, also the RET's target
  LD HL,Depacker
  PUSH DE
  LD BC,DepackEnd-DepackStart   ; $9A bytes
  LDIR
  LD DE,AT                      ; the stream goes down to AT ...
  LD HL,Stream                 ; ... from where it was read, AT+$B0
  LD BC,LEN
  RET                           ; into DepackStart
Depacker:
  DISP $5B00
DepackStart:
  LDIR                          ; the stream down to AT..AT+LEN-1 (over the set-up and the depacker's original)
  LD BC,$0108                   ; B' = 1: the first DepackGetBit loads a byte; C' = 8 bits a byte
  LD HL,AT+LEN-1                ; HL' = the stream's last byte, read first
  EXX
  PUSH HL                       ; the caller's HL' kept for the end
  LD DE,DST_END                 ; DE = the output, written downwards
DepackToken:
  LD HL,$0001                   ; L = 1: one literal unless a run says more
  CALL DepackGetBit
  JR NC,DepackLiteral           ; 0: a literal byte
  LD B,L                        ; 1: a match. B = 1 bit of length
  INC L                         ; L = 2
  CALL DepackGetBit
  JR C,DepackLength             ; 11 b: length 2 + b
  INC B                         ; B = 2 bits
  LD L,$04
  CALL DepackGetBit
  JR C,DepackLength             ; 101 bb: length 4 + bb
  CALL DepackGetBit
  JR NC,DepackLong              ; 1000: length 23 + bytes
  LD B,L                        ; 1001 bbbb (B = 4)
  CALL DepackGetBits
  ADD A,$08
  LD L,A
  CP $17
  JR C,DepackOffset             ; 8 + bbbb under 23: a match of that length
  LD B,$05                      ; bbbb = 15: a literal run of 14 + 5 bits bytes
  CALL DepackGetBits
  ADD A,$0E
  LD L,A
DepackLiteral:
  LD B,$08                      ; L literal bytes, 8 bits each
  CALL DepackGetBits
  LD (DE),A
  DEC DE
  DEC L
  JR NZ,DepackLiteral
  JR DepackNext
DepackLong:
  LD L,$17                      ; length 23 ...
DepackLongByte:
  LD B,$08
DepackLength:
  CALL DepackGetBits            ; ... + the next B bits (a byte $FF in the long form adds another byte)
  ADD HL,BC
  INC A
  JR Z,DepackLongByte
DepackOffset:
  PUSH HL                       ; the length
  CALL DepackGetBit
  LD HL,$0021
  JR C,DepackFar                ; 1: far offset
  LD B,$09                      ; 00 + 9 bits: $21 + n
  ADD HL,DE
  CALL DepackGetBit
  JR NC,DepackCopy
  LD B,$05                      ; 01 + 5 bits: 1 + n
  LD L,E
  LD H,D
  INC HL
  JR DepackCopy
DepackFar:
  LD B,FARBITS                  ; 1 + FARBITS bits: $221 + n
  LD H,$02
  ADD HL,DE
DepackCopy:
  CALL DepackGetBits            ; HL = DE + offset
  ADD HL,BC
  POP BC                        ; BC = the length
  LDDR                          ; the match, downwards
DepackNext:
  LD HL,STOP
  SBC HL,DE                     ; carry clear here: on while DE > STOP
  JR C,DepackToken
  POP HL
  EXX
  JP DONE
DepackGetBits:                  ; A:C = the next B bits (C the low 8, A the bits above), B = A on return
  XOR A
  LD C,A
DepackGetBitsLoop:
  CALL DepackGetBit
  RL C
  RLA
  DJNZ DepackGetBitsLoop
  LD B,A
  LD A,C
  RET
DepackGetBit:                   ; carry = the stream's next bit (E' shifted left; a new byte from (HL') every 8)
  EXX
  DJNZ DepackGetBitShift
  LD B,C
  LD E,(HL)
  DEC HL
DepackGetBitShift:
  RL E
  EXX
  RET
DepackEnd:
  ENT
Stream:
  INCBIN STREAM
  ASSERT $-Stream == LEN
