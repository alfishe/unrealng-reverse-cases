; --------------------------------------------------------------------------------------------------------------------
; gameover.asm: the GAME OVER screen and its depacker (Hrust 1)
;
; HrustScreen unpacks the Hrust 1 stream that follows it (Dmitry Pyankov's packer, without its header) into the screen
; at $4000; the format of the boot program's pictures (aneM's ScreenDepack), in a variant that takes its stream at a
; fixed place after itself. It is position-independent: CALL RomRet leaves its own address (HrustHere) under SP; it
; writes the address of HrustGetBit over the operands of its eleven CALLs (HrustRelocTable, read from its end) before
; it starts; the image holds them as the authors assembled them (HrustGetBitOrg).
;
; The stream: bits MSB first from 16-bit little-endian words, each fetched when the previous one's last bit is taken;
; a 0 bit is a literal byte, a 1 a match: the length from 2-4 more bits (2, 3, 4-5, 6-9) or a byte (10-263, $FE: a
; word, $FF: the end), then the distance: a 1 bit and a byte (1-256), or a 0, a prefix of 3-6 bits for the high byte
; (1-31) and a byte. A length-2 match has only the byte. tools/endings_hrust.py packs it back byte for byte.
; --------------------------------------------------------------------------------------------------------------------

; unpack the GAME OVER stream (HrustStream) into the screen
;
; The main set holds the output (DE) and the match length (BC); the second set
; the bit buffer (HL') and its count (B'). IX walks the stream. Returns with
; HL' = RomHlAlt.
HrustScreen:
  CALL RomRet             ; a RET in the ROM: the return address, HrustHere,
                          ; stays just under SP
HrustHere:
  DEC SP                  ; SP back onto it: DE = HrustHere
  DEC SP
  POP DE
  LD IX,HrustStream-HrustHere ; IX = the stream (HrustHere + $EF), also the end
                              ; of HrustRelocTable
  ADD IX,DE
  PUSH IX
  LD HL,HrustGetBit-HrustHere ; B = 0 (the main set's B stays 0: the high byte
                              ; of a short distance or a byte length)
  LD B,H
  ADD HL,DE
  EX DE,HL                ; DE = HrustGetBit, HL = HrustHere
  LD A,$0B                ; eleven CALL operands
HrustPatchCalls:
  DEC IX                  ; the next distance, from the table's end
  LD C,(IX+$00)
  ADD HL,BC               ; HL = the next CALL's operand: = HrustGetBit
  LD (HL),E
  INC HL
  LD (HL),D
  DEC A
  JR NZ,HrustPatchCalls
  POP IX                  ; IX = the stream
  LD DE,$4000             ; the output: the screen
  EXX
  LD B,$01                ; the bit set: B' = 1, so the first HrustGetBit only
                          ; fetches the first word
  CALL HrustGetBitOrg
  JR HrustNextToken
HrustLiteral:
  LD A,(IX+$00)           ; a 0 bit: the next byte of the stream to the output
  INC IX
  EXX
  LD (DE),A
  INC DE
  EXX
HrustNextToken:
  CALL HrustGetBitOrg     ; the next bit: 0 a literal, 1 a match
  RRA
  JR NC,HrustLiteral
  SUB A                   ; a match: A = 0, then two bits of its length code
  CALL HrustGetBitOrg
  CALL HrustGetBitOrg
  RRA
  RL A
  JR Z,HrustLengthCode    ; 00: length 3
  CALL HrustGetBitOrg     ; 01, 10, 11: a third bit (A = 2-7)
  CP $06
  JR C,HrustLengthCode
  CALL HrustGetBitOrg     ; 11x: a fourth (A = 12-15)
HrustLengthCode:
  EXX                     ; the main set; H = 0 for a distance of one byte
  LD H,B
  CP $02
  JR NZ,HrustNotTwo
  LD C,A                  ; 010: length 2 and only a distance byte (1-256)
  JR HrustCopyMatch
HrustNotTwo:
  JR C,HrustCodeShort     ; 00: length 3
  CP $03                  ; 011: a length byte follows
  JR NZ,HrustLongCode
  LD A,(IX+$00)
  INC IX
  INC A
  JR NZ,HrustByteLength   ; $FF: the end
  LD HL,RomHlAlt          ; HL' as the ROM keeps it (the bit buffer is done)
  EXX
  RET
HrustByteLength:
  INC A                   ; $FE: a word length follows
  JR Z,HrustWordLength
  ADD A,$08               ; else the byte + 10 (B = 1 past 255)
  JR NC,HrustSetLength
  INC B
  JR HrustSetLength
HrustCopyFar:
  EXX                     ; from the bit set
HrustCopyMatch:
  LD L,(IX+$00)           ; L = the distance byte, H = its high part: HL = DE -
                          ; HL - 1
  INC IX
  SCF
  LD A,E
  SBC A,L
  LD L,A
  LD A,D
  SBC A,H
  LD H,A
  LDIR                    ; the match, BC bytes
  EXX
  JR HrustNextToken
HrustWordLength:
  LD C,(IX+$00)           ; the length as a little-endian word
  INC IX
  LD B,(IX+$00)
  INC IX
  JR HrustReadDistance
HrustLongCode:
  CP $06                  ; 100, 101: length 4 or 5
  JR C,HrustSetLength     ; 1100-1111 (12-15): length 6-9
  SUB $09
HrustCodeShort:
  ADD A,$03               ; 00: 0 + 3
HrustSetLength:
  LD C,A                  ; C = the length (B: 0, or 1 past 255)
HrustReadDistance:
  EXX                     ; the bit set: a 1 bit is a distance of one byte
  CALL HrustGetBitOrg
  RRA
  JR C,HrustCopyFar
  XOR A                   ; else the high byte's prefix: 3 bits first
  LD C,$03
HrustHighBits:
  CALL HrustGetBitOrg
  DEC C
  JR NZ,HrustHighBits
  CP $02                  ; 000, 001: high 1, 2
  JR NC,HrustHigh3
  INC A
HrustSetHigh:
  EXX                     ; the main set: H = the distance's high byte, the
                          ; byte follows in the stream
  LD H,A
  JR HrustCopyMatch
HrustHigh3:
  CALL HrustGetBitOrg     ; 010x, 011x (4-7): high 3-6
  CP $08
  JR NC,HrustHigh7
  DEC A
  JR HrustSetHigh
HrustHigh7:
  CALL HrustGetBitOrg     ; 1xxxx below 10111 (16-22): high 7-13
  CP $17
  JR NC,HrustHigh14
  SUB $09
  JR HrustSetHigh
HrustHigh14:
  CALL HrustGetBitOrg     ; 10111x-11111x (46-63): high 14-31
  AND $1F
  JR HrustSetHigh

; the next bit into A's bit 0 (and the carry out of A's bit 7)
;
; In the second set: HL the bit buffer, B the bits left in it. Shifts HL left
; (the carry is the bit), counts B down and fetches the next word from the
; stream (IX) when the 16th bit is taken; RLA puts the bit into A. HrustScreen
; calls it through the operands it patched.
HrustGetBit:
  ADD HL,HL
  DJNZ HrustGetBitDone    ; bits left: done
  LD L,(IX+$00)           ; the next word, low byte first
  INC IX
  LD H,(IX+$00)
  INC IX
  LD B,$10
HrustGetBitDone:
  RLA                     ; the bit into A
  RET

; the distances between HrustGetBit's CALL operands, read from the end
;
; HrustPatchCalls starts at HrustHere and adds each byte from the table's end
; down, stepping one more for the operand's high byte: $E4D2, $E4E0, $E4E7,
; $E4EA, $E4F2, $E4F9, $E54A, $E553, $E562, $E56C, $E577.
HrustRelocTable:
  DEFB $0A,$09,$0E,$08,$50,$06,$07,$02,$06,$0D,$28

; the GAME OVER screen (Hrust 1, 418 bytes)
HrustStream:
  INCBIN "res/pictures/game-over.hrust",$0000,418
