; --------------------------------------------------------------------------------------------------------------------
; leftover.asm: Build leftovers below graphics A: bytes no code reads, with a copy of the tape header
;
; $60F8-$6131 (58 bytes) loads with the game and is never read, written or executed in any recording (l1sum.py --reads
; 60F8-6131: no reads in game, a1, g1, t1, p2, h1, i1, i2, h2). Kept as bytes, not as a resource.
; --------------------------------------------------------------------------------------------------------------------

; Build leftover: 38 unidentified bytes, then a copy of the CODE header of the
; game block
;
; Never read, written or executed (l1sum.py --reads 60F8-6131: no build reads a
; byte). The first 16 bytes ($0F $E0 $1F $E0 0 ...) look like the first rows of
; TitleMoon $6132, the next 22 are not code that any path reaches.
;
; $611E-$612E is a 17-byte CODE header: type 3, the name "MOON" + $AF (the CODE
; token) + five spaces, length $9F08 (the game block's 40712 bytes), start
; $60F8, parameter $80F8. The header on the tape (block 3) reads "MOON      "
; and parameter $8000, so this is a copy from the build, not the tape's. Stage
; 1 put the name at $611D; it is at $611F.
BuildLeftover:
  DEFB $0F,$E0,$1F,$E0,$00,$00,$00,$00
  DEFB $00,$00,$0F,$E0,$1F,$E0,$00,$01
  DEFB $F4,$09,$A8,$10,$4B,$F4,$09,$C4 ; 22 bytes, not identified
  DEFB $15,$53,$81,$0F,$C4,$15,$52,$F4
  DEFB $09,$C4,$15,$50,$80,$00
LeftoverHeader:
  DEFB $03                ; CODE header copy: type 3
  DEFB $4D,$4F,$4F,$4E,$AF,$20,$20,$20 ; the name: "MOON", $AF (CODE), five
  DEFB $20,$20                         ; spaces
  DEFB $08,$9F,$F8,$60,$F8,$80 ; length $9F08, start $60F8, parameter $80F8
  DEFB $F8,$08,$FF        ; three more bytes ($F8 $08 $FF)
