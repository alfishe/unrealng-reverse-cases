; --------------------------------------------------------------------------------------------------------------------
; loadgroup-module.asm: LoadGroup: the loader of groups 2 and 3
;
; Group 1's blocks 44 and 45, deciphered at $FA00-$FBFF by the second stage, which calls it twice: group 2 (the game's
; $6E00-$F9FF) and group 3 (the game's $FA00-$FFFF, loaded into $4000-$45FF because it overwrites this code). It is
; Rick1 again with other block fields: every block is $109 bytes, each payload byte is XORed with the high byte of its
; address on the way (StorePage), the check byte covers the payload and the fields, and the group ends at the page its
; blocks name.
; --------------------------------------------------------------------------------------------------------------------

; Load a group of blocks (A = its marker) to their addresses; BC, DE = AT
; positions of the two message lines
;
; A goes to GroupMarker, BC to StatusAt (C the row, B the column), DE to
; ErrorAt. D, the block wanted, = 0. Opens stream 2, DfSz = 0, prints INK 9
; PAPER 8, clears the status line and prints "Searching 00" on the error line.
;
; Then per block: LoadGroupBlock, the marker (another is skipped), the number
; (not D: GroupBadBlock), CheckPage (bad: GroupBadBlock); a good block is
; deciphered and stored (StorePage), "Loading NN" printed (ShowGroupLoading), D
; + 1. After the block whose address' high byte is GroupEnd - 1: DfSz = 2, and
; GroupGo, 0 in both groups, returns.
;
; Group 2: 140 blocks, the lines at rows 19 and 20 under the picture. Group 3:
; 6 blocks on the cleared screen, rows 10 and 13.
;
; Witness: L1 2 (c1).
LoadGroup:
  DI
  LD (GroupMarker),A
  LD (StatusAt),BC
  LD (ErrorAt),DE
  LD D,$00
  LD A,$02
  CALL ChanOpen
  XOR A
  LD (DfSz),A
  CALL GroupPrintInline

; INK 9, PAPER 8, $FF the end
GroupColoursText:
  DEFM $10,$09,$11,$08,$FF

; LoadGroup after its string: clear the status line, "Searching 00", the first
; block
;
; Witness: L1 36 (c1).
LoadGroupBegin:
  CALL AtStatus
  CALL ClearMessage
  CALL ShowGroupSearching
  JR GroupNextBlock
GroupBlockGood:
  CALL StorePage          ; store the payload, print "Loading NN"
  CALL ShowGroupLoading
  INC D
  LD A,(BlockDest+1)            ; the group's last page?
  LD B,A
  LD A,(GroupEnd)
  DEC A
  CP B
  JR Z,GroupDone
GroupNextBlock:
  CALL LoadGroupBlock
  LD A,(BlockBuffer)
  LD B,A
  LD A,(GroupMarker)
  CP B
  JR NZ,GroupNextBlock
  LD A,(BlockNumber)
  CP D
  JR Z,GroupCheck
  CALL GroupBadBlock
  JR GroupNextBlock
GroupCheck:
  CALL CheckPage
  CP (HL)
  JR Z,GroupBlockGood
  CALL GroupBadBlock
  JR GroupNextBlock
GroupDone:
  LD A,$02
  LD (DfSz),A
  LD HL,(GroupGo)           ; GroupGo: 0 returns
  LD A,H
  OR L
  RET Z
  PUSH HL
  RET

; Copy the payload to its address, each byte XOR the address' high byte: the
; groups' cipher
;
; Group 3's pages are `$40-$45`, the screen's top third: its blocks show on the
; screen, deciphered, as they load.
;
; Witness: L1 146 (c1).
StorePage:
  PUSH DE
  PUSH HL
  LD DE,(BlockDest)
  LD HL,BlockPayload
  LD BC,$0100
StorePageLoop:
  LD A,(BlockDest+1)
  XOR (HL)
  LD (HL),A
  LDI
  JP PE,StorePageLoop
  POP HL
  POP DE
  RET

; Read one block into BlockBuffer: Rick1's LoadBlock with DE = $109
;
; The ROM's LD-BYTES with a 100-pulse leader and no flag, BREAK or parity test,
; as Rick1's LoadBlock (`$CD6E`).
;
; Witness: L1 146 (c1).
LoadGroupBlock:
  PUSH DE
  PUSH HL
  LD IX,BlockBuffer
  LD DE,$0109
  LD A,$FF
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  LD A,$0F
  OUT ($FE),A
  IN A,($FE)
  RRA
  AND $20
  OR $02
  LD C,A
  CP A
GroupWaitEdge:
  CALL GroupEdgeOne       ; LD-START
  JR NC,GroupWaitEdge
  LD H,$64
  LD B,$00
  CALL GroupEdgeTwo
  NOP                     ; a NOP over the ROM's delay
GroupLeaderLoop:
  LD B,$9C                ; LD-LEADER
  CALL GroupEdgeTwo
  JR NC,GroupWaitEdge
  LD A,$C6
  CP B
  JR NC,GroupWaitEdge
  DEC H
  JR NZ,GroupLeaderLoop
GroupSyncLoop:
  LD B,$C9                ; LD-SYNC
  CALL GroupEdgeOne
  JR NC,GroupWaitEdge
  LD A,B
  CP $D4
  JR NC,GroupSyncLoop
  CALL GroupEdgeOne
  JR NC,GroupWaitEdge
  LD A,C                  ; the data's border: blue and cyan
  XOR $03
  LD C,A
  LD H,$00
  LD B,$B0
  JR GroupReadByte
GroupByteLoop:
  EX AF,AF'               ; LD-LOOP
  JR NZ,GroupFlagByte
GroupVerifyHang:
  JR NC,GroupVerifyHang   ; verify mode: never ends
  LD (IX+$00),L
  JR GroupNextByte
GroupFlagByte:
  RL C                    ; LD-FLAG: no check
  XOR L
  NOP
  LD A,C
  RRA
  LD C,A
  INC DE
  JR GroupCountByte
GroupNextByte:
  INC IX
GroupCountByte:
  DEC DE
  EX AF,AF'
  LD B,$B2
GroupReadByte:
  LD L,$01
GroupReadBit:
  CALL GroupEdgeTwo
  JR NC,GroupLoadDone
  LD A,$CB
  CP B
  RL L
  LD B,$B0
  JP NC,GroupReadBit
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,GroupByteLoop
GroupLoadDone:
  POP HL                  ; no parity check
  POP DE
  RET

; Time two edges: the ROM's LD-EDGE-2
;
; Witness: L1 327022 (c1).
GroupEdgeTwo:
  CALL GroupEdgeOne
  RET NC

; Time one edge and flip the border colour: LD-EDGE-1 without the BREAK test
;
; Witness: L1 677895 (c1).
GroupEdgeOne:
  LD A,$16
GroupEdgeDelay:
  DEC A
  JR NZ,GroupEdgeDelay
  AND A
GroupEdgeSample:
  INC B
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  NOP
  XOR C
  AND $20
  JR Z,GroupEdgeSample
GroupEdgeFound:
  LD A,C
  XOR $24
  LD C,A
  AND $07
  OR $08
  OUT ($FE),A
  SCF
  RET

; A lone RET after GroupEdgeOne
;
; Known only from the code: no CALL or JP reaches it.
;
; Witness: L1 0 ().
GroupSpareRet:
  RET

; A = the XOR of $FE01-$FF07 (the payload and the fields); HL = $FF08, the
; block's check byte
;
; Witness: L1 198 (c1).
CheckPage:
  PUSH DE
  LD BC,$0107
  LD HL,BlockPayload
  SUB A
CheckPageLoop:
  XOR (HL)
  LD E,A
  INC HL
  DEC BC
  LD A,B
  OR C
  LD A,E
  JR NZ,CheckPageLoop
  POP DE
  RET

; Print BlockNumber in two hex digits (and add 1 to it in the buffer)
;
; Witness: L1 198 (c1).
GroupPrintNumber:
  LD HL,BlockNumber
  LD A,(HL)
  INC (HL)
; This entry point is used by the routines at ShowGroupSearchingNumber and
; ShowGroupRewindNumber.
GroupPrintHexByte:
  PUSH AF                 ; A in two hex digits
  RLCA
  RLCA
  RLCA
  RLCA
  CALL GroupPrintHexDigit
  POP AF

; Print A's low nibble as a hex digit
;
; Witness: L1 297 (c1).
GroupPrintHexDigit:
  AND $0F
  OR $30
  CP $3A
  JR C,GroupPrintDigit
  ADD A,$07
GroupPrintDigit:
  RST $10
  RET

; Clear the error line, print "Loading NN" on the status line
;
; Witness: L1 146 (c1).
ShowGroupLoading:
  PUSH HL
  PUSH DE
  CALL AtError
  CALL ClearMessage
  CALL AtStatus
  CALL GroupPrintInline

; "Loading   "
GroupLoadingText:
  DEFM "Loading   ",$FF

; ShowGroupLoading after its string: the block's number
;
; Witness: L1 146 (c1).
ShowGroupLoadingNumber:
  POP DE
  POP HL
  JR GroupPrintNumber

; A block not wanted, or a bad check byte: "Block ? NN" on the status line
;
; A = the block's number (the XOR CheckPage made, when the check failed), kept
; in E. Not run in c1.
;
; Witness: L1 0 ().
GroupBadBlock:
  PUSH HL
  LD E,A
  PUSH DE
  CALL AtStatus
  CALL GroupPrintInline

; "Block ?   "
GroupBlockText:
  DEFM "Block ?   ",$FF

; GroupBadBlock's rest: the number, then "Rewind to NN" (E >= D) or "Searching
; NN"
;
; Known only from the code: no recording loaded a block out of order.
;
; Witness: L1 0 ().
GroupBadBlockAhead:
  CALL GroupPrintNumber
  POP DE
  LD A,E
  CP D
  JR NC,ShowGroupRewind
  POP HL

; Print "Searching NN" on the error line: NN = D, the block wanted
;
; Witness: L1 2 (c1).
ShowGroupSearching:
  PUSH HL
  CALL AtError
  CALL GroupPrintInline

; "Searching "
GroupSearchingText:
  DEFM "Searching ",$FF

; ShowGroupSearching after its string: D, the block wanted
;
; Witness: L1 12 (c1).
ShowGroupSearchingNumber:
  LD A,D
  POP HL
  JP GroupPrintHexByte

; Print "Rewind to NN" on the error line: NN = D, the block wanted
;
; Known only from the code.
;
; Witness: L1 0 ().
ShowGroupRewind:
  CALL AtError
  CALL GroupPrintInline

; "Rewind to "
GroupRewindText:
  DEFM "Rewind to ",$FF

; ShowGroupRewind after its string: D, the block wanted
;
; Known only from the code.
;
; Witness: L1 0 ().
ShowGroupRewindNumber:
  LD A,D
  POP HL
  JP GroupPrintHexByte

; Print the bytes after the CALL up to $FF and return after them
;
; Witness: L1 594 (c1).
GroupPrintInline:
  POP HL
GroupPrintInlineLoop:
  LD A,(HL)
  INC HL
  CP $FF
  JR Z,GroupPrintInlineEnd
  RST $10
  JR GroupPrintInlineLoop
GroupPrintInlineEnd:
  PUSH HL
  RET

; Print twelve spaces (at the line AtStatus or AtError set)
;
; Witness: L1 148 (c1).
ClearMessage:
  CALL GroupPrintInline

; twelve spaces
SpacesText:
  DEFM "            ",$FF

; ClearMessage after its string: return
;
; Witness: L1 148 (c1).
ClearMessageEnd:
  RET

; Print AT row, column of the status line: StatusAt, set from BC by LoadGroup
;
; Witness: L1 150 (c1).
AtStatus:
  CALL GroupPrintInline

; AT row, column: the row and the column LoadGroup sets
StatusAtText:
  DEFM $16
StatusAt:
  DEFM $00,$00,$FF        ; the row, then the column: LoadGroup's C and B

; AtStatus after its string: return
;
; Witness: L1 148 (c1).
AtStatusEnd:
  RET

; Print AT row, column of the error line: ErrorAt, set from DE by LoadGroup
;
; Witness: L1 148 (c1).
AtError:
  CALL GroupPrintInline

; AT row, column: the row and the column LoadGroup sets
ErrorAtText:
  DEFM $16
ErrorAt:
  DEFM $00,$00,$FF        ; the row, then the column: LoadGroup's E and D

; AtError after its string: return
;
; Witness: L1 150 (c1).
AtErrorEnd:
  RET

; The marker of the group being loaded ($34 or $35), set by LoadGroup
GroupMarker:
  DEFB $00

; LoadGroup's last 12 bytes: zeros
LoadGroupSpare:
  DEFS $0C
