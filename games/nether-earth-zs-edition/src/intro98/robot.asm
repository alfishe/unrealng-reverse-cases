; --------------------------------------------------------------------------------------------------------------------
; robot.asm: the robot animation: its depacker and its four frames
;
; RobotFrame (from IntroLoop every 32 frames: 63 times in the window) draws the next frame of a four-frame animation
; of the robot into its box (column 13, row 16, 6 x 8 cells), each frame a delta from the screen as the previous one
; left it; after the fourth it starts again at the first, which redraws the whole robot. The code is position
; independent: it learns its address from the ROM (CALL $1FC6 lands on POP HL / RET Z / JP (HL) with Z clear), keeps
; the stream position in its own LD BC operand (RobotPos) and finds the stream at its own address + $B0. Not
; identified as a known depacker; tools/intro98_res.py implements it both ways (the frames as robot.png, the token
; list as robot.parse).
;
; The stream, one frame after the other, each ended by $C0. The output position DE starts at $4000 and runs through
; the decoder's order of the screen: down each column of bytes of a third (8 lines of a cell, then the next cell
; down), then the next column; the attributes ($5800-) in their own order. Codes: $00-$7F + a byte: copy (code >> 3 &
; 15) + 3 bytes from (code & 7) * 256 + byte - $800 behind; $80-$83 + a byte: skip (code & 3) * 256 + byte; $84-$BF:
; skip code - $83; $C0: the frame ends; $C1 + n + v: n times v; $C3 + n: n zeros (n = 0: 256); even $C2-$FE: (code -
; $C0) / 2 literal bytes; $C5, $C9 .. $FD (4j + 1): j + 2 times the next byte; $C7, $CB .. $FF (4j + 3): j + 1 zeros.
; --------------------------------------------------------------------------------------------------------------------

; the robot's next animation frame from RobotStream
;
; No input. Finds its own address (the ROM's $1FC6: POP HL, RET Z not taken, JP
; (HL): HL = RobotSelf), takes the stream position from RobotPos (the first
; time $FFFF, and after the last frame a position past the stream's end: both
; restart at RobotStream), decodes one frame into the screen (RobotNext ...
; RobotFrameEnd) and stores the position after its $C0 in RobotPos.
; Self-modifying (RobotPos). Uses all registers and the alternate set (BC' DE'
; HL', AF').
RobotFrame:
  XOR A                   ; A = 1: NZ for the ROM's RET Z
  INC A
  CALL $1FC6              ; to $1FC6 in the 48 K ROM: POP HL / RET Z / JP (HL):
                          ; back at RobotSelf with HL = RobotSelf

; where RobotFrame goes on: the ROM's JP (HL) at $1FC8 lands here with HL =
; RobotSelf
;
; The second half of RobotFrame, an entry of its own because it is reached from
; the ROM (the get-PC trick: RobotFrame CALLs $1FC6, whose POP HL takes the
; return address, RET Z is not taken with A = 1, and JP (HL) comes back here).
; Entered 63 times in the window (one per robot frame). All addresses of the
; robot (RobotStream, its end) are HL-relative from here, so the block could
; run at any address.
RobotSelf:
  LD BC,$FFFF             ; BC = the stream position (operand, RobotPos)
  EX DE,HL                ; DE = RobotSelf
  LD HL,$02C8             ; HL = RobotSelf + $2C8 = RobotStreamEnd - 1, the
                          ; last byte of the stream
  ADD HL,DE
  SBC HL,BC               ; carry: the position is past it ...
  LD H,B
  LD L,C
  JR NC,RobotStart        ; ... else go on from it
  LD HL,$00B0             ; restart: RobotSelf + $B0 = RobotStream
  ADD HL,DE
RobotStart:
  PUSH DE                 ; RobotSelf kept for the end
  LD C,$F8                ; C = $F8: the mask of the address conversion
  LD DE,$4000             ; DE = the output position, from $4000
RobotNext:
  LD A,(HL)               ; the next code
  INC HL
  SUB $C0                 ; $C0-$FF: the fills, literals and the end
  JR NC,RobotFill
  ADD A,$40               ; $00-$7F: a copy
  JR NC,RobotCopy
  AND $3F                 ; $80-$BF: a skip; $80-$83 with a byte, else code -
                          ; $83
  CP $04
  JR C,RobotSkipLong
  SUB $03
  ADD A,E
  LD E,A
  JR NC,RobotNext
  INC D
  JR RobotNext
RobotSkipLong:
  LD B,A                  ; DE + (code & 3) * 256 + the next byte
  LD A,(HL)
  ADD A,E
  LD E,A
  LD A,B
  ADC A,D
  LD D,A
  INC HL
  JR RobotNext
RobotCopy:
  PUSH HL                 ; HL = DE + the negative offset, B = the count; carry
                          ; set (the copy mode)
  LD L,(HL)
  LD B,A
  OR C
  LD H,A
  LD A,B
  SUB H
  ADD A,$90
  RRCA
  RRCA
  RRCA
  LD B,A
  ADD HL,DE
RobotCopyNext:
  EX AF,AF'               ; a source byte: past $57FF as it is, else through
                          ; the conversion
  LD A,H
  CP $58
  JR NC,RobotCopyAttr
  XOR L                   ; the screen address of HL into DE': H = H & $F8 | L
                          ; & 7, L = (L & $F8 | H & 7) rotated left twice
  AND C
  XOR L
  EXX
  LD D,A
  EXX
  XOR L
  XOR H
  RLCA
  RLCA
  EXX
  LD E,A
  EX AF,AF'
  LD A,(DE)               ; the source byte
  EXX
RobotPut:
  EX AF,AF'               ; a byte to the output: past $57FF as it is, else
                          ; through the conversion
  LD A,D
  CP $58
  JR NC,RobotPutAttr
  XOR E
  AND C
  XOR E
  EXX
  LD D,A
  EXX
  XOR E
  XOR D
  RLCA
  RLCA
  EXX
  LD E,A
  EX AF,AF'
  LD (DE),A               ; written
  EXX
RobotAdvance:
  INC DE                  ; the next position; carry: copy, zero: fill (the
                          ; same byte), else a literal (the next byte)
  JR C,RobotCopyStep
  JR Z,RobotRepeat
  INC HL
  LD A,(HL)
RobotRepeat:
  DJNZ RobotPut
  JR RobotNext
RobotCopyStep:
  INC HL
  DJNZ RobotCopyNext
  POP HL
  INC HL
  JR RobotNext
RobotFill:
  RRA                     ; $C1-$FF: bit 0 of code - $C0 clear: literals (n /
                          ; 2), set: fills
  LD B,A
  JR NC,RobotLiteral
  SRL B
  JR NZ,RobotFillShort
  LD B,(HL)
  INC HL
  JR NC,RobotFillByte
RobotZeros:
  XOR A                   ; A = 0 (zero set, carry clear: the fill mode)
  JR RobotPut
RobotFillShort:
  INC B
  JR C,RobotZeros
  INC B
  XOR A
RobotFillByte:
  LD A,(HL)               ; the fill's byte
  INC HL
  JR RobotPut
RobotLiteral:
  JR Z,RobotFrameEnd      ; n / 2 literal bytes (n = 0: the frame's end)
  LD A,(HL)
  JR RobotPut
RobotFrameEnd:
  POP DE                  ; $C0: the position after it into RobotPos
  INC DE
  EX DE,HL
  LD (HL),E
  INC HL
  LD (HL),D
  RET
RobotCopyAttr:
  EX AF,AF'               ; a source byte past $57FF
  LD A,(HL)
  EX AF,AF'
RobotPutAttr:
  EX AF,AF'               ; a byte past $57FF: written as it is
  LD (DE),A
  JR RobotAdvance

; the four frames (src/res/intro98/robot.png, robot.parse)
;
; 537 bytes: frame 1 (the whole robot, 303 bytes written), frames 2-4 (the
; changes, 78-80 bytes each); each frame skips $1342 positions first (four
; skips of 1023 and one of 838 or 922) to reach the box. Read by RobotFrame
; only (the window read all of it, $E4B3-$E6CB).
RobotStream:
  INCBIN "res/intro98/robot.bin",$0000,537
