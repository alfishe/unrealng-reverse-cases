; --------------------------------------------------------------------------------------------------------------------
; depack.asm: the screen depacker (Hrust 1)
;
; ScreenDepack unpacks a Hrust 1 stream (Dmitry Pyankov's packer, the depacker without its header) from HL into the
; screen at $4000. It is position-independent: CALL ROM_RET leaves its own address under SP, and it writes the address
; of GetBit over the operands of its eleven CALLs (RelocTable: the distances between them) before it starts; the image
; holds the operands as the authors assembled them (DEPACK_GETBIT_ORG).
;
; The stream: bits MSB first from 16-bit little-endian words, each fetched when the previous one's last bit is taken;
; a 0 bit is a literal byte, a 1 a match: the length from 2-4 more bits (2, 3, 4-5, 6-9) or a byte (10-263, $FE: a
; word, $FF: the end), then the distance: a 1 bit and a byte (1-256), or a 0, a prefix of 3-6 bits for the high byte
; (1-31) and a byte. A length-2 match has only the byte. tools/bootmenu_hrust.py packs as the authors' packer did: the
; longest match within 8192 bytes, the nearest of that length, unused bits of the last word set (a whole word fetched
; after the end code: 0).
; --------------------------------------------------------------------------------------------------------------------

; unpack the Hrust 1 stream at HL into the screen
;
; In: HL the stream. Uses both register sets: the main set holds the output
; (DE) and the match length (BC); the second the bit buffer (HL') and its count
; (B'). Called by BootMenu, HelpMenu and the help items; ClearScreen first, so
; the picture appears line by line in its own order (half a frame). Returns
; with HL' = ROM_HL_ALT for the ROM.
ScreenDepack:
  CALL ROM_RET            ; a RET in the ROM: the return address, DepackHere,
                          ; stays just under SP
DepackHere:
  DEC SP                  ; SP back onto it
  DEC SP
  POP DE                  ; DE = DepackHere: where this copy of the depacker
                          ; runs
  LD IX,RelocTable+11-DepackHere
  ADD IX,DE               ; IX = the end of RelocTable
  PUSH HL
  LD HL,GetBit-DepackHere
  LD B,H                  ; B = 0 (the main set's B stays 0: the high byte of a
                          ; short distance, of a byte length)
  ADD HL,DE
  EX DE,HL                ; DE = GetBit, HL = DepackHere
  LD A,$0B                ; eleven CALL operands
PatchCalls:
  DEC IX                  ; the next distance, from the table's end
  LD C,(IX+$00)
  ADD HL,BC               ; HL = the next CALL's operand
  LD (HL),E               ; = GetBit
  INC HL
  LD (HL),D
  DEC A
  JR NZ,PatchCalls
  POP IX                  ; IX = the stream
  LD DE,Screen            ; the output: the screen
  EXX                     ; the bit set: HL' the word, B' its bits left
  LD B,$01                ; the first GetBit only fetches the first word
  CALL DEPACK_GETBIT_ORG
  JR NextToken
Literal:
  LD A,(IX+$00)           ; a 0 bit: the next byte of the stream to the output
  INC IX
  EXX
  LD (DE),A
  INC DE
  EXX
NextToken:
  CALL DEPACK_GETBIT_ORG  ; the next bit into the carry: 0 a literal, 1 a match
  RRA
  JR NC,Literal
  SUB A                   ; a match: A = 0, then two bits of its length code
  CALL DEPACK_GETBIT_ORG
  CALL DEPACK_GETBIT_ORG
  RRA
  RL A                    ; A = 0-3 again, Z when 0 (code 00: length 3)
  JR Z,LengthCode
  CALL DEPACK_GETBIT_ORG  ; 01, 10, 11: a third bit (A = 2-7)
  CP $06
  JR C,LengthCode
  CALL DEPACK_GETBIT_ORG  ; 11x: a fourth (A = 12-15)
LengthCode:
  EXX                     ; the main set; H = 0 for a distance of one byte
  LD H,B
  CP $02                  ; 010: length 2 and only a distance byte (1-256)
  JR NZ,l_6921
  LD C,A
  JR CopyMatch
l_6921:
  JR C,l_6962             ; 00: length 3
  CP $03                  ; 011: a length byte follows
  JR NZ,l_695C
  LD A,(IX+$00)           ; $FF: the end
  INC IX
  INC A
  JR NZ,l_6934
  LD HL,ROM_HL_ALT        ; HL' as the ROM keeps it (the bit buffer is done)
  EXX
  RET
l_6934:
  INC A                   ; $FE: a word length follows
  JR Z,WordLength
  ADD A,$08               ; else the byte + 10
  JR NC,SetLength
  INC B                   ; past 255 (bytes $F6-$FD): B = 1 (no stream here has
                          ; one)
  JR SetLength
ShortDistance:
  EXX                     ; the main set, H = 0
CopyMatch:
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
  JR NextToken
WordLength:
  LD C,(IX+$00)           ; the length as a little-endian word
  INC IX
  LD B,(IX+$00)
  INC IX
  JR ReadDistance
l_695C:
  CP $06                  ; 100, 101: length 4 or 5
  JR C,SetLength
  SUB $09                 ; 1100-1111 (12-15): length 6-9
l_6962:
  ADD A,$03               ; 00: 0 + 3
SetLength:
  LD C,A                  ; C = the length (B: 0, or 1 past 255)
ReadDistance:
  EXX                     ; the bit set: a 1 bit is a distance of one byte
  CALL DEPACK_GETBIT_ORG
  RRA
  JR C,ShortDistance
  XOR A                   ; else the high byte's prefix: 3 bits first
  LD C,$03
HighBits:
  CALL DEPACK_GETBIT_ORG
  DEC C
  JR NZ,HighBits
  CP $02                  ; 000, 001: high 1, 2
  JR NC,l_697E
  INC A
SetHigh:
  EXX                     ; the main set: H = the distance's high byte, the
                          ; byte follows in the stream
  LD H,A
  JR CopyMatch
l_697E:
  CALL DEPACK_GETBIT_ORG  ; 010x, 011x (4-7): high 3-6
  CP $08
  JR NC,l_6988
  DEC A
  JR SetHigh
l_6988:
  CALL DEPACK_GETBIT_ORG  ; 1xxxx below 10111 (16-22): high 7-13
  CP $17
  JR NC,l_6993
  SUB $09
  JR SetHigh
l_6993:
  CALL DEPACK_GETBIT_ORG  ; 10111x-11111x (46-63): high 14-31
  AND $1F
  JR SetHigh

; the next bit into A's bit 0 (and the carry out of A's bit 7)
;
; In the second set: HL the bit buffer, B the bits left in it. Shifts HL left
; (the carry is the bit), counts B down and fetches the next word from the
; stream (IX) when the 16th bit is taken; RLA puts the bit into A. ScreenDepack
; calls it through the operands it patched.
GetBit:
  ADD HL,HL
  DJNZ l_69A9             ; bits left: done
  LD L,(IX+$00)           ; the next word, low byte first
  INC IX
  LD H,(IX+$00)
  INC IX
  LD B,$10
l_69A9:
  RLA                     ; the bit into A
  RET

; the distances between GetBit's CALL operands, read from the end
;
; ScreenDepack starts at DepackHere + $27 (the first CALL's operand, $68EF) and
; adds each byte from the table's end down: $68EF, $68FD, $6904, $6907, $690F,
; $6916, $6967, $6970, $697F, $6989, $6994.
RelocTable:
  DEFB $0A,$09,$0E,$08,$50,$06,$07,$02,$06,$0D,$27
