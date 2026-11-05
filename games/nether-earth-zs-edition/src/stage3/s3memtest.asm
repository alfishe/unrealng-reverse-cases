; --------------------------------------------------------------------------------------------------------------------
; s3memtest.asm: MemoryTest: the paging scheme, the page count, the page select
;
; MemoryTest ($647B) finds how the machine pages memory and how many distinct 16 K pages it has, into two system
; variables the game keeps: $5CB0 (IY+$76) the scheme bits and $5CB1 (IY+$77) the count. Bit 7: the ROM paged in by
; $7FFD = $10 holds $C3 at $0008 (Scorpion's ROMs; also +2A / +3 ROM 1: data/rom of unreal-ng holds $C3 there; the 48
; K and 128 K ROMs hold $2A). Then the first of four tests that succeeds sets its bit and skips the rest: bit 3 "TURBO
; 2+" (ATM Turbo 2+: through the TR-DOS ROM, $FFF7 = $1F maps a ROM page into window 3; the word at $0457 equals the
; one at $C457); bit 2 "PROFI" ($DFFD = $10 makes $0080 writable; Profi's $DFFD bit 4 maps RAM at $0000, unreal-ng
; portdecoder_profi); bit 1 "KAY" ($1FFD = $11 makes $0080 writable: Scorpion and KAY $1FFD bit 0 = RAM at $0000; on a
; +2A / +3, $1FFD = $11 is the special paging mode 0, RAM page 0 at $0000, so it passes too); bit 4 "ATM" ($FDFD = $11
; and $FF select two pages at $C000: ATM Turbo 1, $FDFD bits 0-1 extend the window-3 page). Bit 0 "Spectrum" (always
; tested): $7FFD = $10 and $80 show different bytes at $0080 (two ROMs). Then CountPages, and bit 5 "Spectrum" when
; the count is 8 or more and the scheme is exactly 1 (a $7FFD-only machine with more than 128 K). Bit 6 is never set.
;
; Witnessed: Pentagon 128 r99 frame 2300 $5CB0 = $01, $5CB1 = 5; Scorpion ZS-256 s99 frame 2000 $83, $0D; the Pentagon
; locked in 48 K mode r99-48 frame 5300: 0, 0 (no OUT pages anything). Known only from the code: a +2A / +3 sets bits
; 7 and 1 ("Computer Scorpion", the KAY page select on $1FFD); a Profi bit 2; ATM Turbo 2+ bit 3 (PROFI, TURBO 2+, ATM
; and KAY were run by no recording).
;
; The count is the number of distinct pages of PageList (0-63 without 2 and 5) found at $C000, minus 1: 5 on a 128 K
; (0, 1, 3, 4, 6, 7), 13 on a 256 K Scorpion, 0 on a machine that cannot page. The one-page route of stage 3 (count =
; 1, "Memory 48Kb") needs exactly two distinct pages besides 2 and 5: no machine has that, so the one-page MainMenu
; table and the 48 K game are never set up; a 48 K + Beta 128 takes the 128 K route with count 0 (the lead's
; 48K-BETA128 run: $5CB0 = 0, $5CB1 = 0, "Memory 56Kb") and resets (Stage3Paged).
; --------------------------------------------------------------------------------------------------------------------

; Find the paging scheme ($5CB0) and the page count ($5CB1); ends with page 0
; at $C000, interrupts on
;
; Out: $5CB0 (IY+$76) the scheme bits (7 Scorpion ROM, 3 ATM Turbo 2+, 2 Profi,
; 1 KAY / Scorpion $1FFD, 4 ATM Turbo 1, 0 $7FFD, 5 more than 128 K on $7FFD
; alone), $5CB1 (IY+$77) the count. The bytes at $C000 of every page are put
; back (CountPages). Called once by Stage3Entry (r99 frame about 2200).
MemoryTest:
  XOR A
  LD (IY+$76),A
  INC A                   ; the count starts at 1
  LD (IY+$77),A
  DI
  LD BC,$7FFD             ; $7FFD = $10: page 0, ROM 1
  LD A,$10
  OUT (C),A
  NOP
  LD A,($0008)            ; $C3 at $0008 (JP): a Scorpion's ROM (or a +2A / +3
                          ; ROM 1)
  CP $C3
  JR NZ,TestAtm2
  SET 7,(IY+$76)
TestAtm2:
  LD HL,($0457)           ; ATM Turbo 2+: $FFF7 = $1F, window 3 a ROM page
                          ; (bits 7-6 = 0)
  LD BC,$FFF7
  LD A,$1F
  CALL TrdosPortOut
  LD DE,($C457)           ; the same word at $0457 and at $C457: the ROM shows
                          ; at $C000
  AND A
  SBC HL,DE
  LD BC,$FFF7             ; $FFF7 = $FF: window 3 RAM under $7FFD again
  LD A,$FF
  CALL TrdosPortOut
  JR NZ,TestProfi
  SET 3,(IY+$76)
  JR TestTwoRoms
TestProfi:
  LD HL,$0080             ; Profi: $DFFD = $10 (bit 4: RAM at $0000)
  LD DE,$1000
  LD BC,$DFFD
  OUT (C),D
  NOP
  LD A,(HL)               ; writable at $0080?
  INC (HL)
  CP (HL)
  LD (HL),A
  OUT (C),L               ; $DFFD = $80
  JR Z,TestKay
  SET 2,(IY+$76)
  JR TestTwoRoms
TestKay:
  LD DE,$1110             ; KAY / Scorpion: $1FFD = $11 (bit 0: RAM at $0000)
  LD B,$1F
  OUT (C),D
  NOP
  LD A,(HL)
  INC (HL)
  CP (HL)
  LD (HL),A
  OUT (C),L               ; $1FFD = $80, then 0 on success
  NOP
  JR Z,TestAtm1
  XOR A
  OUT (C),A
  SET 1,(IY+$76)
  JR TestTwoRoms
TestAtm1:
  LD B,C                  ; ATM Turbo 1: $FDFD = $11, page 1 by $7FFD, $11 to
                          ; $FFFF
  LD HL,$FFFF
  OUT (C),D
  NOP
  LD B,$7F
  OUT (C),D
  NOP
  LD (HL),D
  LD B,C                  ; $FDFD = $FF, $FF to $FFFF
  OUT (C),L
  NOP
  LD B,$7F
  OUT (C),D
  NOP
  LD (HL),L
  LD B,C                  ; $FDFD = $11 again: $11 still there = two different
                          ; pages
  OUT (C),D
  NOP
  LD B,$7F
  OUT (C),D
  NOP
  LD A,(HL)
  CP D
  JR NZ,TestTwoRoms
  SET 4,(IY+$76)
TestTwoRoms:
  LD HL,$0080             ; two ROMs on $7FFD bit 4: $0080 with ROM 0 and ROM 1
  LD DE,$1000
  LD BC,$7FFD
  OUT (C),D
  NOP
  LD A,(HL)
  OUT (C),L
  NOP
  CP (HL)
  OUT (C),D
  NOP
  JR Z,TestCount
  SET 0,(IY+$76)
TestCount:
  CALL CountPages         ; the count
  LD A,(IY+$77)           ; 8 or more on a $7FFD-only machine: bit 5
  CP $08
  JR C,TestEnd
  LD A,(IY+$76)
  CP $01
  JR NZ,TestEnd
  SET 5,(IY+$76)
TestEnd:
  LD A,$00                ; page 0 at $C000
  CALL SelectPage
  EI
  RET

; Count the distinct pages: mark $C000 of pages 63..0, drop the aliases from
; PageList, restore the bytes
;
; Pages 63 down to 0 (SelectPage): the byte at $C000 is saved (PageSave, from
; $66B2 down) and replaced by the page number. Then each page of PageList is
; selected: if $C000 does not hold its number the page is an alias of a later
; one (or absent) and is removed from the list (the rest moved down, the count
; less 1). The count starts at 61 ($3D, the 62 entries minus 1). Then the 64
; saved bytes go back. Out: $5CB1 = the count, PageList = the distinct pages
; (r99 frame about 2200 writes $663A-$6671: the list compacted to 0 1 3 4 6 7).
CountPages:
  LD IX,$C000
  LD HL,PageSave+$003F
  LD B,$40
MarkPages:
  LD A,B                  ; page B-1: save its $C000 byte, write its number
                          ; there
  DEC A
  CALL SelectPage
  LD C,(IX+$00)
  LD (HL),C
  LD (IX+$00),A
  DEC HL
  DJNZ MarkPages
  PUSH AF
  LD A,$3D                ; 62 entries in the list, minus 1
  LD (IY+$77),A
  POP AF
  LD DE,PageList          ; each page of the list
CheckPage:
  LD A,(DE)               ; the next list entry, $FF ends
  CP $FF
  JR Z,RestorePages
  CALL SelectPage
  CP (IX+$00)
  JR Z,NextListPage
  PUSH DE                 ; not its own number: remove it, the count less 1
  LD HL,PageList+$003E
  AND A
  SBC HL,DE
  PUSH HL
  POP BC
  PUSH DE
  POP HL
  INC HL
  LDIR
  DEC (IY+$77)
  POP DE
  DEC DE
NextListPage:
  INC DE
  JR CheckPage
RestorePages:
  LD B,$40                ; the saved bytes back, pages 0..63
  LD HL,PageSave
RestoreLoop:
  LD A,$40
  SUB B
  CALL SelectPage
  LD A,(HL)
  LD (IX+$00),A
  INC HL
  DJNZ RestoreLoop
  RET

; Select the page PageList holds at index A (falls into SelectPage)
;
; Known only from the code: nothing in stage 3, the game, the patches or the
; menu block CALLs $65A3 (a byte search of work/media/99 for the address finds
; none).
ListPage:
  PUSH BC
  PUSH HL
  LD C,A
  LD B,$00
  LD HL,PageList
  ADD HL,BC
  LD A,(HL)
  POP HL
  POP BC

; Page A (0-63) in at $C000 by the scheme found; with no scheme bit nothing
; happens
;
; A = the page. Interrupts off. One extended register by priority (bit 1 $1FFD,
; bit 2 $DFFD, bit 3 the ATM Turbo 2+ register, bit 4 $FDFD), then $7FFD = page
; bits 0-2, bits 3-4 into $7FFD bits 6-7, bit 4 set (ROM 1); bits 0 and 7 alone
; use only $7FFD. AF, BC, HL kept.
SelectPage:
  DI
  PUSH HL
  PUSH AF
  PUSH BC
  BIT 1,(IY+$76)
  JR NZ,SelectKay
  BIT 2,(IY+$76)
  JR NZ,SelectProfi
  BIT 3,(IY+$76)
  JR NZ,SelectAtm2
  BIT 4,(IY+$76)
  JR NZ,SelectAtm1
  BIT 0,(IY+$76)
  JR NZ,Select7ffd
  BIT 7,(IY+$76)
  JR NZ,Select7ffd
  JR SelectDone
SelectAtm2:
  PUSH AF                 ; ATM Turbo 2+: NOT (A AND $18) through the TR-DOS
                          ; ROM to $7FF7
  PUSH IX
  AND $18
  CPL
  LD BC,$7FF7
  CALL TrdosPortOut
  POP IX                  ; open point: $7FF7 is window 1 ($4000) by
                          ; unreal-ng's IsPort_FFF7 (A15-A14), not window 3; no
                          ; ATM recording
  POP AF
  JR Select7ffd
SelectAtm1:
  LD BC,$FDFD             ; ATM Turbo 1: $FDFD = page bits 3-4
  PUSH AF
  RRCA
  RRCA
  RRCA
  AND $03
  JR SelectExtOut
SelectProfi:
  LD BC,$DFFD             ; Profi: $DFFD = page bits 3-5
  PUSH AF
  RRCA
  RRCA
  RRCA
  AND $07
  JR SelectExtOut
SelectKay:
  PUSH AF                 ; KAY / Scorpion: $1FFD = page bit 3 to bit 4, bits
                          ; 4-5 to bits 6-7
  LD B,A
  AND $08
  RLCA
  LD C,A
  LD A,B
  AND $30
  RLCA
  RLCA
  ADD A,C
  LD BC,$1FFD
SelectExtOut:
  OUT (C),A               ; the extended register
  NOP
  POP AF
Select7ffd:
  LD B,A                  ; $7FFD: bits 0-2 the page, 6-7 from page bits 3-4,
                          ; ROM 1
  AND $18
  RLCA
  RLCA
  RLCA
  LD C,A
  LD A,B
  AND $07
  ADD A,C
  OR $10
  LD BC,$7FFD
  OUT (C),A
  NOP
SelectDone:
  POP BC
  POP AF
  POP HL
  RET

; OUT (C),A with the TR-DOS ROM paged (TrdosRet into TrdosOut): the ATM decodes
; its xFF7 ports only then
;
; IX is changed.
TrdosPortOut:
  LD IX,TrdosOut
  PUSH IX
  JP TrdosRet
