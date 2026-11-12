; --------------------------------------------------------------------------------------------------------------------
; catalogue.asm: Reading the TR-DOS catalogue
;
; The catalogue is track 0's sectors 0-7 (128 entries of 16 bytes: name 8, type 1, start 2, length 2, sectors 1, first
; sector 1, track 1) read to Catalogue $9D00 by Start and again by SPACE. A first byte 0 ends it, 1 marks a deleted
; file.
; --------------------------------------------------------------------------------------------------------------------

  ORG $6737

; Compare the 9 bytes at HL (name and type) with "boot    B": C = 0 if equal,
; $FF if not
;
; Returns HL at the entry's type byte (+8) and E = C: the caller ANDs the type
; with E, so the boot file's type reads 0 and is never listed.
;
; Witness: L1 219 (c x4).
IsBootFile:
  PUSH DE
  LD C,$00
  LD B,$09
  LD DE,BootName
IsBootNext:
  LD A,(DE)
  CP (HL)
  JR Z,IsBootSame
  LD C,$FF
IsBootSame:
  INC HL
  INC DE
  DJNZ IsBootNext
  POP DE
  LD E,C
  DEC HL
  RET

; While the entry at HL is deleted (A = 1), go to the next one (HL + 16, A its
; first byte)
;
; Witness: L1 234 (c x4).
SkipDeleted:
  CP $01
  RET NZ
  LD BC,$0010
  ADD HL,BC
  LD A,(HL)
  JR SkipDeleted

  ORG $6B6B

; "boot    B": the name and type IsBootFile never lists
BootName:
  DEFM "boot    B"
