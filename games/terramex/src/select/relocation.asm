; --------------------------------------------------------------------------------------------------------------------
; relocation.asm: The relocation pass and its table
;
; The tape holds every absolute address inside the block as an offset from the block's first byte. RelocateSelector
; $C0AB adds the run address (BC: $C000 in RAM 1 on a 128K, $7200 on a 48K) to each word RelocTable $EA0F lists (67
; words, a zero word ends the table) and marks the block relocated ($2F at its first byte). Addresses outside the
; block (the paging stub, the explorer sets in RAM 3 and 4, $C000 as the paging slot) are absolute and not listed.
; tools/parts.py reloc() does the same for the case's image, tools/mktape.py the inverse for the tape.
; --------------------------------------------------------------------------------------------------------------------

; The 48K path: back to the main registers, relocate at $7200
;
; Reached from Setup $C005 (JR Z at $C033) when the paging test found one RAM:
; EXX brings back HL = BC = $7200 and falls into RelocateSelector. Known only
; from the code (the 48K path is not recorded).
;
; Witness: L1 0 ().
RelocateInPlace:
  EXX

; Add the run address to every word RelocTable lists, mark the block relocated
;
; In: HL = BC = the block's address. Writes $2F at the first byte, reads
; RelocTableOffset $C003 (+3), then for each nonzero offset in RelocTable adds
; BC to the word at block + offset. Falls into SelectorEntry $C0D2 at the zero
; word.
;
; c1: run once at $C000 in RAM 1 (frame 11841): 68 table words read, 67 words
; relocated.
;
; Witness: L1 1 (c1).
RelocateSelector:
  LD (HL),$2F
  PUSH HL
  INC HL
  INC HL
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  POP HL
  PUSH HL
  ADD HL,DE
  EX DE,HL
  POP BC
RelocateLoop:
  EX DE,HL                ; next offset; zero ends the table
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD A,H
  OR L
  JR Z,SelectorEntry
  ADD HL,BC               ; HL = the word's address, add the base to the word
  PUSH DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  DEC HL
  LD (HL),E
  INC HL
  LD (HL),D
  POP DE
  JR RelocateLoop

  ORG $EA0F

; The offsets of the 67 relocatable words from the block's start, a zero word
; ends
;
; RelocateSelector $C0AB reads it once (c1: 68 words at frame 11841). The words
; listed are the block's own addresses: CALL, JP and LD operands; the stub,
; bank and paging-slot addresses are not in it.
RelocTable:
  DEFW $00FD,$0104,$0107,$010A,$0113,$0116,$0130,$01C0
  DEFW $01D6,$02A1,$0315,$0320,$0326,$032D,$0334,$01DA
  DEFW $0342,$034C,$034F,$0352,$0355,$03C1,$03C4,$03DD
  DEFW $03E7,$03ED,$0404,$040D,$0411,$0435,$043A,$0442
  DEFW $046C,$01A3,$031D,$0207,$03CB,$03E4,$0409,$0318
  DEFW $01CA,$00D3,$01AE,$0110,$0190,$0126,$0511,$0516
  DEFW $051B,$0526,$0531,$0289,$0291,$0280,$0557,$055A
  DEFW $055E,$0561,$0564,$056A,$056D,$0570,$05D5,$0551
  DEFW $0554,$053D,$0540
RelocTableEnd:
  DEFW $0000              ; the zero word
