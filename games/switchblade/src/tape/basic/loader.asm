; --------------------------------------------------------------------------------------------------------------------
; loader.asm: The tape loader at $FF00: the ROM's LD-BYTES with red stripes and its own end
;
; Copied by BasicCode to $FF00-$FFFC (from $5D37) and run from LoaderStart $FFEE, which loads TZX block 3 (stage 2,
; $080C bytes) to $609C and jumps to it. Stage 2 then calls LoadBlock $FF00 for the blocks 4-6. The page stays until
; the bootstrap copies the game's panel code over $FF01-$FFFE.
;
; LdBytes $FF02 is the 48K ROM's LD-BYTES ($0556) moved here with four changes: SCF first (always a load, the caller
; needs no carry), the border $0A (red, MIC) at the start instead of $0F, the return address LoadEnd $FFB2 pushed
; instead of SA/LD-RET $053F, and AND $02 instead of AND $07 in LD-SAMPLE, so the border stripes are red and black for
; the pilot and the data alike. The rest (LD-START, LD-LEADER, LD-SYNC, LD-8-BITS, LD-EDGE-2 / LD-EDGE-1 with their
; timing constants) is byte for byte the ROM's.
; --------------------------------------------------------------------------------------------------------------------

; Load a block with flag $FF: IX = the address, DE = the length
;
; A = `$FF`, then LdBytes. Called by stage 2 for the blocks 4, 5 and (on a
; 128K) 6.
;
; Witness: L1 8 (c x2).
LoadBlock:
  LD A,$FF

; The ROM's LD-BYTES with red / black stripes; returns through LoadEnd
;
; A = the flag byte, IX = the address, DE = the length. The carry is set by the
; routine itself (`SCF` at `$FF02`: a load, never a verify). The border goes to
; `$0A` (red); LoadEnd `$FFB2` is pushed as the return address; then the ROM's
; code: an edge, the leader (`$9C`/`$C6` timing), the sync, the flag byte, the
; data bytes with the parity in H, the stripes from C (`AND $02`: red / black).
;
; Every return (an error, BREAK or the end) goes to LoadEnd, with carry set for
; a good load.
;
; Witness: L1 11 (c x2).
LdBytes:
  SCF
  INC D                   ; the ROM's LD-BYTES from here (INC D; EX AF,AF'; DEC
                          ; D: the flag kept in A')
  EX AF,AF'
  DEC D
  DI
  LD A,$0A                ; border red (the ROM: white), the return to LoadEnd
  OUT ($FE),A
  LD HL,LoadEnd
  PUSH HL
  IN A,($FE)              ; C = the current EAR level and the stripe colour 2
  RRA
  AND $20
  OR $02
  LD C,A
  CP A
LdBreak:
  RET NZ
LdStart:
  CALL LdEdge1            ; an edge within the timeout, then about 1 s of
                          ; silence
  JR NC,LdBreak
  LD HL,$0415
LdWait:
  DJNZ LdWait
  DEC HL
  LD A,H
  OR L
  JR NZ,LdWait
  CALL LdEdge2
  JR NC,LdBreak
LdLeader:
  LD B,$9C                ; 256 leader pulses in a row
  CALL LdEdge2
  JR NC,LdBreak
  LD A,$C6
  CP B
  JR NC,LdStart
  INC H
  JR NZ,LdLeader
LdSync:
  LD B,$C9                ; the sync pulse
  CALL LdEdge1
  JR NC,LdBreak
  LD A,B
  CP $D4
  JR NC,LdSync
  CALL LdEdge1
  RET NC
  LD A,C                  ; the data's stripes: C XOR 3 (AND $02 leaves red /
                          ; black)
  XOR $03
  LD C,A
  LD H,$00
  LD B,$B0
  JR LdMarker
LdLoop:
  EX AF,AF'               ; the flag byte first, then the data
  JR NZ,LdFlag
  JR NC,LdVerify
  LD (IX+$00),L
  JR LdNext
LdFlag:
  RL C                    ; the flag: compare with A'
  XOR L
  RET NZ
  LD A,C
  RRA
  LD C,A
  INC DE
  JR LdDec
LdVerify:
  LD A,(IX+$00)           ; not reached: the carry is always set
  XOR L
  RET NZ
LdNext:
  INC IX
LdDec:
  DEC DE
  EX AF,AF'
  LD B,$B2
LdMarker:
  LD L,$01                ; one byte of 8 bits
Ld8Bits:
  CALL LdEdge2
  RET NC
  LD A,$CB
  CP B
  RL L
  LD B,$B0
  JP NC,Ld8Bits
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,LdLoop
  LD A,H                  ; the parity: carry set when the load is good
  CP $01
  RET

; The ROM's LD-EDGE-2: two edges
;
; Witness: L1 1196411 (c x2).
LdEdge2:
  CALL LdEdge1
  RET NC

; The ROM's LD-EDGE-1: wait 358 T, then count B up to the next edge; the border
; stripe
;
; Out: carry = an edge found; NC = timeout (B wrapped) or BREAK (SPACE, `$7FFE`
; bit 0, as in the ROM). The stripe colour is C AND `$02` (the ROM: AND `$07`),
; with MIC.
;
; Witness: L1 2405444 (c x2).
LdEdge1:
  LD A,$16
LdDelay:
  DEC A
  JR NZ,LdDelay
  AND A
LdSample:
  INC B
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  RET NC
  XOR C
  AND $20
  JR Z,LdSample
  LD A,C
  CPL
  LD C,A
  AND $02
  OR $08
  OUT ($FE),A
  SCF
  RET

; LD-BYTES returns here: on a good load border black, EI, return; else TAPE
; LOADING ERROR
;
; Carry set (good): border 0, EI, then LoadReturn (POP AF, RET to the caller of
; LdBytes, the flags kept). Carry clear: LoadError, which never returns.
;
; Witness: L1 647 (c x2).
LoadEnd:
  PUSH AF
  JR NC,LoadError
  XOR A
  OUT ($FE),A
  EI
  JR LoadReturn
LoadError:
  LD A,$02                ; border red, the attributes $47 (white on black),
                          ; print TapeErrorText with RST $10, then hang
  OUT ($FE),A
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$47
  LDIR
  LD HL,TapeErrorText
  LD B,$14
LoadErrorPrint:
  LD A,(HL)
  INC HL
  RST $10
  DJNZ LoadErrorPrint
LoadErrorHang:
  JR LoadErrorHang

; The error message: ENTER "TAPE LOADING ERROR" ENTER (20 bytes, printed by RST
; $10)
TapeErrorText:
  INCBIN "res/texts/tape-error.bin",$0000,20

; POP AF and return: the end of LoadEnd
;
; Witness: L1 11 (c x2).
LoadReturn:
  POP AF
  RET

; The loader's entry: load stage 2 (TZX block 3, $080C bytes) to $609C and run
; it
;
; From BasicCode's `JP $FFEE`. LdBytes with A = `$FF`, IX = `$609C`, DE =
; `$080C`, then `JP $609C` (stage 2, src/stage2). The stack is still SP =
; `$5D37` from BasicCode.
;
; Witness: L1 5 (c x2).
LoaderStart:
  LD A,$FF
  LD IX,$609C
  LD DE,$080C
  CALL LdBytes
  JP $609C
