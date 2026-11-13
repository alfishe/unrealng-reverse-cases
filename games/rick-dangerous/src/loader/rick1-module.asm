; --------------------------------------------------------------------------------------------------------------------
; rick1-module.asm: Rick1: the first loader stage, which loads tape group 1
;
; TZX block 4, loaded by the BASIC's LOAD "Rick1" CODE 52480 at $CD00 and entered by its RANDOMIZE USR 52480. It loads
; the 48 blocks of tape group 1 (marker $64) one by one into BlockBuffer $FE00, checks each one's number and checksum,
; copies its 256-byte payload where the block says, and jumps into the block's own tail: a JP back to NextBlock, or
; for block 46 a JP into the second stage at $5D00 (src/loader/stage2.asm).
;
; Its tape reader LoadBlock is the ROM's LD-BYTES with four changes: a 100-pulse leader instead of 256, no flag check,
; no BREAK, and no parity check (CheckBlock makes a checksum instead). The timing constants are the ROM's, so the
; "turbo" blocks run at ROM speed with a short pilot. Rick1's own 512 bytes are the cipher's key material too: the
; second stage XORs the key page with them, so a changed byte here spoils every keyed block.
; --------------------------------------------------------------------------------------------------------------------

; Rick1's entry: open the screen, print the colours and "Searching 00", then
; load group 1
;
; Entered by the BASIC's RANDOMIZE USR 52480. Opens stream 2 (ChanOpen), sets
; DfSz to 0, prints INK 9 PAPER 8 (PrintInline: contrasting ink, transparent
; paper), sets D, the block wanted, to 0, prints "Searching 00" (ShowSearching)
; and sets NextFiller to 8, the first block's filler length.
;
; Witness: L1 1 (c1).
Rick1Start:
  LD A,$02
  CALL ChanOpen
  XOR A
  LD (DfSz),A
  CALL PrintInline

; INK 9, PAPER 8: the print colours (contrasting ink, transparent paper), $FF
; the end
ColoursText:
  DEFM $10,$09,$11,$08,$FF

; Rick1Start after its string: D = 0, "Searching 00", the first block's filler
; length
;
; Witness: L1 1 (c1).
Rick1Begin:
  LD D,$00                ; D = 0: the block wanted
  CALL ShowSearching
  LD A,$08                ; the first block's filler is 8 bytes long
  LD (NextFiller),A

; Load the next block of group 1, check it, store it and jump into its tail
;
; LoadBlock, then the marker: a block other than `$64` is skipped. A number
; other than D, or a checksum CheckBlock does not match: BadBlock, and the next
; block. A good block's payload is copied (StoreBlock) and "Loading NN" printed
; (ShowLoading).
;
; Then the tail: HL steps over the N filler bytes to the block's last byte, the
; checksum, whose bits 0-2 + 1 are the next block's N (NextFiller); D + 1, and
; `JP (HL)` into the block's `JP` after the filler: `JP NextBlock` for blocks
; 0-45, `JP $5D00` (the second stage) for block 46. The filler's bytes are
; never run.
;
; Witness: L1 47 (c1).
NextBlock:
  CALL LoadBlock
  LD A,(BlockBuffer)
  CP $64
  JR NZ,NextBlock
  LD A,(BlockNumber)
  CP D
  JR Z,CheckThisBlock
  CALL BadBlock
  JR NextBlock
CheckThisBlock:
  CALL CheckBlock         ; the block wanted: its checksum
  CP (HL)
  JR Z,BlockGood
  CALL BadBlock
  JR NextBlock
BlockGood:
  CALL StoreBlock         ; store the payload, print "Loading NN"
  CALL ShowLoading
  LD HL,BlockFiller
  LD A,(HL)
SkipFiller:
  INC HL                  ; HL = BlockFiller + N
  DEC A
  JR NZ,SkipFiller
  INC HL
  INC HL
  INC HL
  INC HL
  LD A,(HL)               ; the checksum: bits 0-2 + 1 = the next block's N
  DEC HL
  DEC HL
  DEC HL
  AND $07
  INC A
  LD (NextFiller),A
  INC D                   ; the next block wanted
  JP (HL)                 ; into the tail: JP NextBlock (block 46: the second
                          ; stage)

; Copy the block's 256-byte payload to its address; leave IX = the caller's
; return address
;
; LDIRs BlockPayload to the address in BlockDest. The payload is copied as it
; comes: group 1's cipher is undone later by the second stage. Last it pops the
; return address into IX and pushes it back, so IX = `$CD3E`, inside Rick1: the
; second stage keeps that IX and makes the key from Rick1's page (`$5D12`).
;
; Witness: L1 47 (c1).
StoreBlock:
  PUSH DE
  PUSH HL
  LD DE,(BlockDest)
  LD HL,BlockPayload
  LD BC,$0100
  LDIR
  POP HL
  POP DE
  POP IX
  PUSH IX
  RET

; Read one Bleepload block from the tape into BlockBuffer: the ROM's LD-BYTES,
; changed
;
; DE = BlockLength (`$109` + N), IX = BlockBuffer, A' = `$FF` with carry set:
; load. C keeps the EAR level and the border colour: the leader stripes red and
; yellow (EdgeOne flips C with `XOR $24` from `$02`), the data blue and cyan (C
; `XOR 3` after the sync).
;
; Against the ROM's LD-BYTES (`$0556`): the leader needs only 100 pulses (`LD
; H,$64` where the ROM counts 256); the flag byte is read but not checked (a
; NOP where the ROM has RET NZ); verify mode hangs (`JR NC,$`); the end has no
; parity test: EI, the registers back and RET. Its edge routines EdgeTwo and
; EdgeOne keep the ROM's timing constants and drop the BREAK test.
;
; Witness: L1 48 (c1).
LoadBlock:
  PUSH DE
  PUSH HL
  PUSH IX
  LD IX,BlockBuffer
  CALL BlockLength
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
WaitEdge:
  CALL EdgeOne            ; the ROM's LD-START: wait for an edge
  JR NC,WaitEdge
  LD H,$64
  LD B,$00
  CALL EdgeTwo
  NOP                     ; a NOP over the ROM's 1 s delay
LeaderLoop:
  LD B,$9C                ; the ROM's LD-LEADER
  CALL EdgeTwo
  JR NC,WaitEdge
  LD A,$C6
  CP B
  JR NC,WaitEdge
  DEC H
  JR NZ,LeaderLoop
SyncLoop:
  LD B,$C9                ; the ROM's LD-SYNC
  CALL EdgeOne
  JR NC,WaitEdge
  LD A,B
  CP $D4
  JR NC,SyncLoop
  CALL EdgeOne
  JR NC,WaitEdge
  LD A,C                  ; the data's border: blue and cyan
  XOR $03
  LD C,A
  LD H,$00
  LD B,$B0
  JR ReadByte
ByteLoop:
  EX AF,AF'               ; the ROM's LD-LOOP
  JR NZ,FlagByte
VerifyHang:
  JR NC,VerifyHang        ; verify mode: never ends
  LD (IX+$00),L
  JR NextByte
FlagByte:
  RL C                    ; the ROM's LD-FLAG: no check (a NOP where the ROM
                          ; has RET NZ)
  XOR L
  NOP
  LD A,C
  RRA
  LD C,A
  INC DE
  JR CountByte
NextByte:
  INC IX                  ; the ROM's LD-NEXT
CountByte:
  DEC DE                  ; the ROM's LD-DEC
  EX AF,AF'
  LD B,$B2
ReadByte:
  LD L,$01                ; the ROM's LD-8-BITS
ReadBit:
  CALL EdgeTwo
  JR NC,LoadDone
  LD A,$CB
  CP B
  RL L
  LD B,$B0
  JP NC,ReadBit
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,ByteLoop
LoadDone:
  EI                      ; no parity check: back with the registers restored
  POP IX
  POP HL
  POP DE
  RET

; Time two edges: the ROM's LD-EDGE-2
;
; B = the time counter. Carry set: both edges came in time; reset: time out.
;
; Witness: L1 109221 (c1).
EdgeTwo:
  CALL EdgeOne
  RET NC

; Time one edge and flip the border colour: the ROM's LD-EDGE-1 without the
; BREAK test
;
; B = the time counter, +1 per pass of the sampling loop; C = the last level
; and the border colour. The ROM's `RET NC` after the `RRA` is a NOP, so BREAK
; does not stop the load. Each edge flips C's bits 2 and 5 (`XOR $24`) and
; writes the colour to the border.
;
; Witness: L1 224652 (c1).
EdgeOne:
  LD A,$16
EdgeDelay:
  DEC A
  JR NZ,EdgeDelay
  AND A
EdgeSample:
  INC B
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  NOP
  XOR C
  AND $20
  JR Z,EdgeSample
EdgeFound:
  LD A,C                  ; flip the level bit and the border colour
  XOR $24
  LD C,A
  AND $07
  OR $08
  OUT ($FE),A
  SCF
  RET

; DE = $109 + NextFiller: the length of the next block
;
; Witness: L1 96 (c1).
BlockLength:
  LD A,(NextFiller)
  LD DE,$0109
BlockLengthLoop:
  INC DE
  DEC A
  JR NZ,BlockLengthLoop
  RET

; A = the XOR of the block's bytes but its last; HL = that last byte, for the
; caller's CP (HL)
;
; Witness: L1 48 (c1).
CheckBlock:
  PUSH DE
  CALL BlockLength
  DEC DE
  LD HL,BlockBuffer
CheckLoop:
  XOR (HL)
  LD C,A
  INC HL
  DEC DE
  LD A,D
  OR E
  LD A,C
  JR NZ,CheckLoop
  POP DE
  RET

; Print BlockNumber in two hex digits (and add 1 to it in the buffer)
;
; Witness: L1 47 (c1).
PrintBlockNumber:
  LD HL,BlockNumber
  LD A,(HL)
  INC (HL)
; This entry point is used by the routines at ShowSearchingNumber and
; ShowRewindNumber.
PrintHexByte:
  PUSH AF                 ; A in two hex digits (ShowSearching and ShowRewind
                          ; enter here with D)
  RLCA
  RLCA
  RLCA
  RLCA
  CALL PrintHexDigit
  POP AF

; Print A's low nibble as a hex digit (RST $10)
;
; Witness: L1 96 (c1).
PrintHexDigit:
  AND $0F
  OR $30
  CP $3A
  JR C,PrintDigit
  ADD A,$07
PrintDigit:
  RST $10
  RET

; Clear row 10 (AT 10,10, twelve spaces), print "Loading NN" at AT 7,10
;
; NN is the block's number (PrintBlockNumber).
;
; Witness: L1 47 (c1).
ShowLoading:
  PUSH HL
  PUSH DE
  CALL PrintInline

; AT 10,10, twelve spaces (clear the search line), AT 7,10 "Loading   "
LoadingText:
  DEFM $16,$0A,$0A,"            ",$16,$07,$0A,"Loading   ",$FF

; ShowLoading after its string: the block's number
;
; Witness: L1 47 (c1).
ShowLoadingNumber:
  POP DE
  POP HL
  JP PrintBlockNumber

; A block not wanted, or a bad checksum: print "Block ? NN" at AT 7,10
;
; A = the block's number (the XOR CheckBlock made, when the checksum failed),
; kept in E. After the string, BadBlockAhead prints the number and chooses the
; hint. Not run in c1: the TZX plays every block in order.
;
; Witness: L1 0 ().
BadBlock:
  PUSH HL
  LD E,A
  PUSH DE
  CALL PrintInline

; AT 7,10 "Block ?   "
BlockText:
  DEFM $16,$07,$0A,"Block ?   ",$FF

; BadBlock's rest: the number, then "Rewind to NN" for a block past the one
; wanted, else "Searching NN"
;
; E (the block found) >= D (the block wanted): ShowRewind; else on into
; ShowSearching. Known only from the code: no recording loaded a block out of
; order.
;
; Witness: L1 0 ().
BadBlockAhead:
  CALL PrintBlockNumber
  POP DE
  LD A,E
  CP D
  JR NC,ShowRewind
  POP HL

; Print "Searching NN" at AT 10,10: NN = D, the block wanted
;
; Witness: L1 1 (c1).
ShowSearching:
  PUSH HL
  CALL PrintInline

; AT 10,10 "Searching "
SearchingText:
  DEFM $16,$0A,$0A,"Searching ",$FF

; ShowSearching after its string: D, the block wanted
;
; Witness: L1 1 (c1).
ShowSearchingNumber:
  LD A,D
  POP HL
  JP PrintHexByte

; Print "Rewind to NN" at AT 10,10: NN = D, the block wanted
;
; Known only from the code.
;
; Witness: L1 0 ().
ShowRewind:
  CALL PrintInline

; AT 10,10 "Rewind to "
RewindText:
  DEFM $16,$0A,$0A,"Rewind to ",$FF

; ShowRewind after its string: D, the block wanted
;
; Known only from the code.
;
; Witness: L1 0 ().
ShowRewindNumber:
  LD A,D
  POP HL
  JP PrintHexByte

; Print the bytes after the CALL up to $FF (RST $10) and return after them
;
; Witness: L1 49 (c1).
PrintInline:
  POP HL
PrintInlineLoop:
  LD A,(HL)
  INC HL
  CP $FF
  JR Z,PrintInlineEnd
  RST $10
  JR PrintInlineLoop
PrintInlineEnd:
  PUSH HL
  RET

; Rick1's last 44 bytes: zeros, which nothing reads but MakeKey $5D12 (the key
; material)
Rick1Spare:
  DEFS $2C
