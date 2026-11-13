; --------------------------------------------------------------------------------------------------------------------
; reader.asm: The block reader: edges, pilot, sync, bytes, the block table, the end check
;
; LoadStream reads a stream of blocks: a pilot of its own timing (32 edge pairs, then the sync pulse), seven timed
; edge pairs (EdgeWindows), a 6-bit mark that must be $3A, then the first block's bytes to IX, DE+1 of them, each byte
; stored as (L XOR $C1) + $11 by StoreByte (operands rewritten by tape blocks 19 and 21 to the real keys) and XORed
; into H. With LastStoreJump pointed at StoreLast (by the second stage) the last byte of a block is stored by
; StoreLast, which then walks BlockTable: each row pages $7FFD, takes the next block's address and length, and reads
; it after a 21-bit mark. An end row reads 14 more bytes and the check byte; LoadEnd wants H = 0.
;
; The bit timing: EdgeDelay waits A x 16 T, Edge counts the time to the next edge in B (from the value it is given; a
; timeout when B wraps), and a bit is 1 when B passed the threshold. Each edge sets the border from the tape level
; (C), masked by EdgeBorderMask: red and black at the pilot, blue and black for the data, black once the countdown
; starts.
; --------------------------------------------------------------------------------------------------------------------

; Wait for two edges; carry clear on a timeout
;
; Inputs: B the start count. Output: B the count at the second edge, carry set
; when both came in time. Witness: L1 78 (c1).
EdgePair:
  CALL Edge
  RET NC                  ; the first edge timed out: return with carry clear

; Wait about 350 T (A = $16), then for the next edge
;
; Witness: L1 3117 (c1).
Edge:
  LD A,$16

; EdgeDelay
;
; Used by the routines at LoadStream, StoreByte and ReadMark.
EdgeDelay:
  DEC A                   ; A x 16 T of delay, then EdgeWait
  JR NZ,EdgeDelay
; This entry point is used by the routines at AttrRevealStart and
; CountdownTask.
EdgeWait:
  AND A                   ; carry clear, then poll the EAR bit (port $7FFE bit
                          ; 6) until it changes, counting B up; B wrapping to 0
                          ; is a timeout (carry clear)
EdgeWaitLoop:
  INC B                   ; one poll
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  XOR C
  AND $20
  JR Z,EdgeWaitLoop
  LD A,C
  CPL
  LD C,A
EdgeBorderMask:
  AND $07                 ; AND n / OR n: the border colour from C (n
                          ; rewritten: 2 at the pilot, 1 for the data, 0 at the
                          ; countdown; the OR 8 turns into 8)
  OR $08
  OUT ($FE),A
  SCF
  RET

; Read the pilot, the sync and the timing pairs, then the first block to IX,
; DE+1 bytes, and the rest
;
; Inputs: IX the first block's address, DE its length less one; LastStoreJump
; where its last byte goes (LoadEnd at first, StoreLast once the second stage
; set it). DI; border mask 2; pushes LoadFail, so a timeout's RET NC ends the
; stream with carry clear; C := the EAR level. The pilot: 32 edge pairs each in
; the window B from $9C to above $C2; then edges until a short pulse (B under
; $D4); then the seven pairs of EdgeWindows; then a 6-bit mark (L := 4 shifted
; left) that must be $3A, else JP RomCrash. H := 0 (the XOR of the bytes), IY
; := BlockTable, and the bit loop. Output: carry set and H = 0 on a good stream
; (LoadEnd). Side effects: the blocks in memory, $7FFD paged by the table rows,
; the border.
;
; Witness: L1 2 (c1).
LoadStream:
  DI
  LD A,$02
  LD (EdgeBorderMask+$0001),A
  OR $08
  OUT ($FE),A
  LD HL,LoadFail
  PUSH HL
  IN A,($FE)
  RRA
  AND $20
  LD C,A
  PUSH DE
LoadPilotRestart:
  LD E,$20                ; a pair out of its window: start the pilot again
LoadPilotPair:
  LD B,$9C
  CALL EdgePair
  JR NC,LoadPilotRestart
  LD A,$C2
  CP B
  JR NC,LoadPilotRestart
  DEC E
  JR NZ,LoadPilotPair
LoadSync:
  LD B,$C9                ; edges until the short pulse
  CALL Edge
  JR NC,LoadPilotRestart
  LD A,B
  CP $D4
  JR NC,LoadSync
  CALL Edge
  JR NC,LoadPilotRestart
LoadTimingPairs:
  LD E,$07                ; the seven pairs of EdgeWindows, each between its
                          ; two bounds
  LD HL,EdgeWindows
LoadTimingPair:
  LD B,(HL)
  INC HL
  CALL EdgePair
  JR NC,LoadPilotRestart
  LD A,(HL)
  INC HL
  CP B
  JR NC,LoadPilotRestart
  DEC E
  JR NZ,LoadTimingPair
LoadMark:
  LD A,$01                ; the 6-bit mark: border mask 1, L := 4
  LD (EdgeBorderMask+$0001),A
  LD B,$9E
  POP DE
  LD L,$04
  LD A,$08
  JR LoadMarkBitWait
LoadMarkBit:
  LD A,$09
LoadMarkBitWait:
  CALL EdgeDelay
  RET NC
  NOP
  NOP
  LD A,$0E
  CALL EdgeDelay
  RET NC
  LD A,$13
  LD A,$BC
  CP B
  RL L
  LD B,$9E
  JP NC,LoadMarkBit
  LD A,$3A                ; the mark must be $3A
  CP L
  JP NZ,RomCrash             ; else JP RomCrash: a crash, no message
  LD H,$86                ; LD H,$86 then LD H,0: H the XOR of the bytes, from
                          ; 0
  LD H,$00
  LD B,$B2
  LD L,$01
  LD IY,BlockTable
  LD A,$04
  JR BitRead

; Store a byte: (L XOR k) + a to (IX), DE down by one, then read the next byte
;
; k ($FDB6) and a ($FDB9) are the operands of this code: block 19 (the table's
; row 2, src/tape/tape.txt) rewrites them. Witness: L1 11405 (c1).
StoreByte:
  LD A,$C1
  XOR L
  ADD A,$11
  LD (IX+$00),A
  INC IX
  DEC DE
  LD B,$B2
  LD L,$01
  NOP
  LD A,$02
  JR BitRead
BitNext:
  LD A,$09                ; the next bit: A = 9 for EdgeDelay
; This entry point is used by the routines at LoadStream and StoreLast.
BitRead:
  CALL EdgeDelay          ; one bit: EdgeDelay with A, then the task, then the
                          ; threshold
  RET NC
BitHook:
  CALL AttrRevealStart    ; CALL the task (the operand: AttrRevealStart,
                          ; AttrReveal, CountdownTask): it ends at EdgeWait,
                          ; the second edge
  RET NC
  LD A,$13
BitThreshold:
  LD A,$D0                ; a bit is 1 when B passed $D0
  CP B
  RL L
  LD B,$B2
  JP NC,BitNext
ByteDone:
  LD A,H                  ; 8 bits: H := H XOR L; more bytes: StoreByte
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,StoreByte
LastStoreJump:
  JP LoadEnd              ; JP n: where a block's last byte goes (LoadEnd, then
                          ; StoreLast)

; Store a block's last byte with its own key, then the next table row
;
; Its operands ($FDEA and $FDED) are rewritten by block 21 (the table's row 3).
; Then the 7-bit mark after the block (ReadMark, L := 2); then the table row at
; IY: its $7FFD value (0 ends the table), its address to IX, a 21-bit mark
; whose middle 7 bits must be $7F (else FailFlag := $7F: the load goes on and
; fails at the end), its length less one to DE, IY moves 5 on, the last mark
; and BitRead. A length of 0 (the end row) puts LastStoreJump back to LoadEnd
; and reads 14 bytes and the check byte at IX (tape block 35, at $5B21).
; Witness: L1 11 (c1).
StoreLast:
  LD A,$C1
  XOR L
  ADD A,$11
  LD (IX+$00),A
  INC IX
  DEC DE
  LD L,$02
  LD A,$04
  LD B,$B3
  CALL ReadMark
NextTableRow:
  RET NC                  ; the row's $7FFD value; 0: the end
  LD A,(IY+$04)
  OR A
  JR Z,TableEndRow
  LD L,C
  LD BC,$7FFD
  OUT (C),A
  LD C,(IY+$00)
  LD B,(IY+$01)
  LD IX,$0000
  ADD IX,BC
  LD C,L
  LD A,$01
TableRowMark:
  LD L,$02                ; the 21-bit mark's middle part
  LD B,$B3
  CALL ReadMark
  RET NC
  LD A,$7F
  CP L
  JR Z,TableRowLength
  LD (FailFlag),A
TableRowLength:
  LD E,(IY+$02)           ; DE := the row's length less one, IY := the next row
  LD D,(IY+$03)
  LD L,C
  LD BC,$0005
  ADD IY,BC
  LD C,L
  LD L,$02
  LD A,$03
  LD B,$B3
  CALL ReadMark
  RET NC
  LD A,E
  OR D
  LD B,$B2
  LD L,$01
  LD A,$06
  JP NZ,BitRead
TableEnd:
  LD DE,LoadEnd           ; the end row: the last 14 bytes and the check, then
                          ; LoadEnd
  LD (LastStoreJump+$0001),DE
  LD DE,$000E
  LD A,$02
  JP BitRead
TableEndRow:
  LD A,$06                ; a zero $7FFD value: no OUT
  JR TableRowMark
; This entry point is used by the routine at ReadMark.
ReadMarkBit:
  LD A,$0C                ; A = 12 for the next bit

; Read the bits of a mark into L until its marker bit shifts out
;
; Inputs: L the marker (1 or 2, so 7 or 6 bits), A the first delay, B the start
; count. Output: L the bits, carry set; carry clear on a timeout. Witness: L1
; 231 (c1).
ReadMark:
  CALL EdgeDelay
  NOP
  NOP
  LD A,$0E
  CALL EdgeDelay
  RET NC
  LD A,$DB
  CP B
  RL L
  LD B,$B3
  JP NC,ReadMarkBit
  RET

  ORG $FEEA

; The seven timed pairs after the sync: the start count and the bound, a pair a
; row
;
; Read by LoadStream at $FD68 (c1). ($E9,$EA), ($D2,$E2), ($B6,$E0) three
; times, ($D2,$E2), ($EC,$ED).
EdgeWindows:
  DEFB $E9,$EA
  DEFB $D2,$E2
  DEFB $B6,$E0
  DEFB $B6,$E0
  DEFB $B6,$E0
  DEFB $D2,$E2
  DEFB $EC,$ED

; The stream's end: border black, H (the XOR of the bytes) must be 0, else
; RomCrash
;
; Reached through LastStoreJump with the pushed LoadFail on the stack (POP DE
; drops it), or by a timeout's RET NC straight into LoadFail. Output: carry set
; when H = 0. Witness: L1 2 (c1).
LoadEnd:
  POP DE
LoadFail:
  XOR A                   ; a timeout comes here with carry clear: border
                          ; black, and H decides as well
  OUT ($FE),A
  LD A,H
  CP $01
  RET C
  CALL RomCrash
