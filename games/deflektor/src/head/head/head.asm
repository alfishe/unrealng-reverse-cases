; --------------------------------------------------------------------------------------------------------------------
; head.asm: The main block's head: where it is, and the chain moved up to $7B52
;
; The loader's last step (MoveStub $5B00: LDIR; RET) returns to $5C00 with the turbo block's sixth and seventh loads
; in place: $5C00-$9BFF and $9C00-$9DEF, the eighth's first $1F0 bytes at $C000-$FFFF (src/loader/stage2.ann). The
; block is encrypted except these 39 bytes: BlockHead works out its own address (a POP HL; JP (HL) planted in the
; printer buffer, so the block runs wherever it is loaded) and copies the rest of the block, $5C27-$DDEF, up to
; $7B52-$FD1A with LDDR (the two ranges overlap: the copy runs backwards), then returns into the copy at $7B52, the
; chain.
; --------------------------------------------------------------------------------------------------------------------

; Find the block's address with a stub at $5B00, move $5C27-$DDEF up to $7B52
; and run the chain there
;
; 1. DI; `$E9E1` (POP HL; JP (HL)) at MoveStub `$5B00`; CALL it: HL = `$5C0A`,
; the address after the CALL.
;
; 2. HL + 29 = `$5C27`, the first encrypted byte; BC = `$81C9` (33225 bytes,
; `$5C27-$DDEF`); DE = `$7B52`, pushed: the RET's target.
;
; 3. The source below the target (it is): BlockMoveUp, HL and DE moved to the
; ends (+ BC - 1) and LDDR, so the overlap copies right. Else BlockMoveDown
; `$5C24`, LDIR (never taken on the tape).
;
; 4. RET to `$7B52`.
;
; c1: one run, 33225 bytes moved.
;
; Witness: L1 1 (c1).
BlockHead:
  DI
  LD HL,$E9E1
  LD (MoveStub),HL
  CALL MoveStub
  LD DE,$001D             ; HL = this address: + 29 is the block's first
                          ; encrypted byte
  ADD HL,DE
  LD BC,$81C9
  LD DE,$7B52
  PUSH DE
  LD A,L                  ; the source below the target: copy backwards
  SUB E
  LD A,H
  SBC A,D
  JR NC,BlockMoveDown
BlockMoveUp:
  ADD HL,BC               ; LDDR from the ends
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  DEC HL
  DEC DE
  LDDR
  RET
BlockMoveDown:
  LDIR                    ; LDIR (the source above the target; not taken)
  RET
