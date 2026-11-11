; --------------------------------------------------------------------------------------------------------------------
; loader.asm: The SpeedLock 7 loader: the notice, the block reader, the stage at $BF0D
;
; LoaderStart checks for a Multiface, prints the copyright notice and clears the memory the chain used, then loads the
; second stage (tape block 7) at $BF0D and runs it. The block reader LoadBlocks reads a pilot of its own timing, the
; sync pulses and the bytes, each stored as (byte XOR k) + a by StoreByte (the operands are the keys, rewritten by the
; tape's blocks 17 and 19); BlockTable walks the blocks to their banks. While it waits for edges it runs a task
; through the pointer at $BDB7: the attribute reveal and the countdown.
;
; c1: LoaderStart at frame 2288; the stage entered at frame 2484; the last block read by frame 23856; the bootstrap
; entered at frame 23974 (docs/03 3.1).
; --------------------------------------------------------------------------------------------------------------------

; Check for a Multiface, clear the RAM, print the notice and load the stage
;
; Interrupts off, SP = $BFFF. IN A,($3F) and IN A,($9F) are the Multiface's
; page-in ports: if either pages a ROM in, the byte at $0000 is no longer the
; 128K ROM's DI ($F3) and JP $0000 restarts the machine. The OUTs to $1F, $7B
; and $BB page such interfaces out again. Then PrintNotice and LoaderMain.
; Known from the code; c1: L1 1.
LoaderStart:
  DI
  LD SP,$BFFF
  IN A,($3F)
  LD A,($0000)
  CP $F3
l_B904:
  JP NZ,$0000
  IN A,($9F)
  LD A,($0000)
  CP $F3
  JR NZ,l_B904
  XOR A
  LD L,A
  LD H,L
  OUT ($1F),A
  INC A
  LD E,$01
  OUT ($7B),A
  LD D,L
  OUT ($BB),A
  LD (HL),L
  LD A,$43
  LD BC,$3FFF
  LDIR
  DEC HL
  OUT ($7F),A
  LD BC,$3FFF
  DEC DE
  LD A,C
  LDDR
  CALL PrintNotice
  JP LoaderMain

; Print the copyright notice: the bars and the strings of NoticeText
;
; Used by the routine at LoaderStart.
PrintNotice:
  LD BC,$0008
  LD HL,NoticeText
  CALL PrintString
  LD BC,$0108
  LD A,$10
  CALL DrawBar
  LD BC,$0200
  CALL PrintString
  LD BC,$080C
  CALL PrintString
  LD BC,$090C
  LD A,$07
  CALL DrawBar
  LD BC,$0A00
  CALL PrintString
  LD BC,$1200
  CALL PrintString
  LD BC,$1608
  JP PrintString

; Draw a bar of A cells at the screen position BC, bright red attributes
;
; Used by the routine at PrintNotice.
DrawBar:
  PUSH HL
  PUSH AF
  CALL CellAddress
  POP AF
  EX DE,HL
  LD B,A
l_B974:
  PUSH BC
  PUSH HL
  PUSH HL
  LD A,H
  AND $18
  RRA
  RRA
  RRA
  LD B,A
  LD C,L
  LD HL,Attributes
  ADD HL,BC
  LD A,$42
  LD (HL),A
  POP HL
  LD B,$02
l_B989:
  LD (HL),$FF
  INC H
  DJNZ l_B989
  POP HL
  INC HL
  POP BC
  DJNZ l_B974
  POP HL
  RET

; Print the character A (from $20) with the ROM font at $3D00
;
; Used by the routine at PrintString.
PrintChar:
  SUB $20
  RET C
  PUSH HL
  LD HL,$3D00
  LD B,$00
  LD C,A
  SLA C
  RL B
  SLA C
  RL B
  SLA C
  RL B
  ADD HL,BC
  CALL DrawGlyph
  POP HL
  RET

; Copy the 8 bytes at HL to the screen cell DE, white attribute
;
; Used by the routine at PrintChar.
DrawGlyph:
  PUSH DE
  EX DE,HL
  LD A,H
  AND $18
  RRA
  RRA
  RRA
  LD B,A
  LD C,L
  LD HL,Attributes
  ADD HL,BC
  LD A,$47
  LD (HL),A
  EX DE,HL
  POP DE
  LD B,$08
l_B9C6:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ l_B9C6
  RET

; DE = the screen address of row B, column C
;
; Used by the routines at DrawBar and PrintString.
CellAddress:
  LD A,B
  AND $07
  RLCA
  RLCA
  RLCA
  RLCA
  RLCA
  LD E,A
  LD A,C
  AND $1F
  OR E
  LD E,A
  LD A,B
  AND $18
  OR $40
  LD D,A
  RET

; Print the string at HL up to a zero, from row B column C, wrapping at column
; 32
;
; Used by the routine at PrintNotice.
PrintString:
  LD A,(HL)
  INC HL
  OR A
  RET Z
  PUSH BC
  PUSH AF
  CALL CellAddress
  POP AF
  CALL PrintChar
  POP BC
  INC C
  LD A,C
  CP $20
  JR C,PrintString
  LD C,$00
  INC B
  JR PrintString

; The copyright notice and the FAST warning, zero-ended strings
;
; Read by PrintString (c1: L1 reads). Shown during the whole load.
NoticeText:
  DEFM "COPYRIGHT NOTICE",$00," This program is protected underU.K. Copyright L"
  DEFM "aw and may not  be copied, hired or reproduced, or otherwise modi"
  DEFM "fied without   the consent of the Copyright    Owner.",$00,"WARNING",$00,"  I"
  DEFM "t is a CRIMINAL OFFENCE to   sell, hire, offer or expose for sale"
  DEFM " or hire, or otherwise      distribute infringing (Illegal) copie"
  DEFM "s of this computer program and persons found doing so will be pro"
  DEFM "secuted.",$00,"Any information on Piracy shouldbe passed to the Federat"
  DEFM "ion     Against Software Theft -",$00,"Tel: 01 240 6756",$00

; The task the edge loop runs while it waits: the attribute reveal, then the
; countdown
;
; LoadBlocks calls it between two edges (CALL $BBF4 at $BDB6); the task's own
; code is reached through the pointer at $BDB7, which each step rewrites. Known
; from the code; the screen shows the attributes coming in and a countdown at
; the top right in c1.
WaitTask:
  EXX
  EX AF,AF'
  LD A,(AttrBuffer+767)
  CP $00
  LD B,$0C
  JR Z,l_BC16
  LD HL,l_BC16+$0003
  LD (l_BDB2+$0005),HL
  LD HL,AttrBuffer
  LD DE,Attributes
  LD A,$41
  LD B,$09
l_BC0F:
  DJNZ l_BC0F
  EX AF,AF'
  EXX
  JP l_BCFB
l_BC16:
  NOP
  JR l_BC0F
  EXX
  EX AF,AF'
  DEC A
  JR Z,l_BC3C
  EX AF,AF'
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  NOP
  EXX
  JP l_BCFB
l_BC3C:
  LD A,$01
  EX AF,AF'
  LD HL,data_BC5A
  LD (l_BDB2+$0005),HL
  XOR A
  LD (l_BCFC+$0010),A
  LD A,$08
  LD (l_BCFC+$0012),A
  LD B,$08
  LD B,$08
  LD B,$08
l_BC54:
  DJNZ l_BC54
  EXX
  JP l_BCFB

; data_BC5A
data_BC5A:
  DEFB $D9,$08,$FE,$98

; l_BC5E
l_BC5E:
  JR C,l_BCBD
  DEC C
  JR Z,l_BC71
  EX AF,AF'
  LD B,$04
l_BC66:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC D
  DJNZ l_BC66
  NOP
  LD B,$01
  JR l_BCAA
l_BC71:
  DEC A
  CP $98
  JR C,l_BCB0
  LD C,$03
  LD HL,data_BCEE+$0003
  LD DE,$40F2
  LD B,$08
  JR Z,l_BC9D
  DEC HL
  DEC E
  DEC E
  NOP
  NOP
  LD B,$05
  CP $99
  JR Z,l_BC9D
  DEC HL
  DEC E
  NOP
  LD B,$03
  CP $9A
  JR Z,l_BC9D
  DEC HL
  DEC E
  DEC E
  NOP
  NOP
  LD B,$01
l_BC9D:
  DJNZ l_BC9D
  LD L,(HL)
  LD H,$BF
  EX AF,AF'
  EXX
  JP l_BCFB
l_BCA7:
  LD B,$0D
l_BCA9:
  EX AF,AF'
l_BCAA:
  DJNZ l_BCAA
  EXX
  JP l_BCFB
l_BCB0:
  LD B,$0B
  JR l_BCA9
l_BCB4:
  LD (HL),A
l_BCB5:
  DJNZ l_BCB5
  JR l_BCE7
l_BCB9:
  NOP
  NOP
  JR l_BCE7
l_BCBD:
  DEC A
  JR NZ,l_BCA7
  LD A,$9C
  EX AF,AF'
  LD HL,data_BCEE+$0003
  LD DE,$78F8
  LD A,E
  ADD A,(HL)
  CP D
  LD B,$07
  JR NZ,l_BCB4
  LD (HL),$C8
  DEC HL
  LD A,E
  ADD A,(HL)
  CP D
  LD B,$04
  JR NZ,l_BCB5
  LD (HL),$C8
  DEC HL
  LD A,E
  ADD A,(HL)
  CP D
  JR NZ,l_BCB9
  LD (HL),$A8
  DEC HL
  LD A,E
  ADD A,(HL)
l_BCE7:
  LD (HL),A
  LD C,$01
  EXX
  JP l_BCFB

; data_BCEE
data_BCEE:
  DEFB $B0,$98,$C0,$B0

; Two edges: sample the EAR bit until it changes, twice
;
; Used by the routine at LoadBlocks.
LdEdge2:
  CALL sub_BCF6
  RET NC

; sub_BCF6
;
; Used by the routines at LdEdge2 and LoadBlocks.
sub_BCF6:
  LD A,$16

; sub_BCF8
;
; Used by the routines at LoadBlocks, StoreByte and ReadMark.
sub_BCF8:
  DEC A
  JR NZ,sub_BCF8
; This entry point is used by the routines at WaitTask and l_BC5E.
l_BCFB:
  AND A
l_BCFC:
  INC B
  RET Z
  LD A,$7F
  IN A,($FE)
  RRA
  XOR C
  AND $20
  JR Z,l_BCFC
  LD A,C
  CPL
  LD C,A
  AND $07
  OR $08
  OUT ($FE),A
  SCF
  RET

; Read the pilot, the sync and the bytes of a block to IX, DE bytes
;
; Used by the routine at TimeCheck.
LoadBlocks:
  DI
  LD A,$02
  LD (l_BCFC+$0010),A
  OR $08
  OUT ($FE),A
  LD HL,LoadEnd+$0001
  PUSH HL
  IN A,($FE)
  RRA
  AND $20
  LD C,A
  PUSH DE
l_BD28:
  LD E,$20
l_BD2A:
  LD B,$9C
  CALL LdEdge2
  JR NC,l_BD28
  LD A,$C2
  CP B
  JR NC,l_BD28
  DEC E
  JR NZ,l_BD2A
l_BD39:
  LD B,$C9
  CALL sub_BCF6
  JR NC,l_BD28
  LD A,B
  CP $D4
  JR NC,l_BD39
  CALL sub_BCF6
  JR NC,l_BD28
  LD E,$07
  LD HL,EdgeLimits
l_BD4F:
  LD B,(HL)
  INC HL
  CALL LdEdge2
  JR NC,l_BD28
  LD A,(HL)
  INC HL
  CP B
  JR NC,l_BD28
  DEC E
  JR NZ,l_BD4F
  LD A,$01
  LD (l_BCFC+$0010),A
  LD B,$9E
  POP DE
  LD L,$04
  LD A,$08
  JR l_BD6E
l_BD6C:
  LD A,$09
l_BD6E:
  CALL sub_BCF8
  RET NC
  NOP
  NOP
  LD A,$0E
  CALL sub_BCF8
  RET NC
  LD A,$13
  LD A,$BC
  CP B
  RL L
  LD B,$9E
  JP NC,l_BD6C
  LD A,$3A
  CP L
  JP NZ,$C3EB
  LD H,$86
  LD H,$00
  LD B,$B2
  LD L,$01
  LD IY,BlockTable
  LD A,$04
  JR l_BDB2

; Store a byte: (L XOR k) + a, k and a the operands of this code
;
; The tape's block 17 rewrites k ($BD9D: $C1, then $86); a ($BDA0) stays $11.
; src/tape/side1.txt and tools/mktape.py use the same operands in the other
; direction.
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
  JR l_BDB2
l_BDB0:
  LD A,$09
; This entry point is used by the routines at LoadBlocks and StoreLast.
l_BDB2:
  CALL sub_BCF8
  RET NC
  CALL WaitTask
  RET NC
  LD A,$13
  LD A,$D0
  CP B
  RL L
  LD B,$B2
  JP NC,l_BDB0
  LD A,H
  XOR L
  LD H,A
  LD A,D
  OR E
  JR NZ,StoreByte
  JP LoadEnd

; Store the last byte of a block the same way, with its own operands (block 19
; rewrites them)
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
  RET NC
  LD A,(IY+$04)
  OR A
  JR Z,l_BE41
  LD L,C
  LD BC,$7FFD
  OUT (C),A
  LD C,(IY+$00)
  LD B,(IY+$01)
  LD IX,$0000
  ADD IX,BC
  LD C,L
  LD A,$01
l_BE00:
  LD L,$02
  LD B,$B3
  CALL ReadMark
  RET NC
  LD A,$7F
  CP L
  JR Z,l_BE10
  LD (TimeFailed),A
l_BE10:
  LD E,(IY+$02)
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
  JP NZ,l_BDB2
  LD DE,LoadEnd
  LD (l_BDB2+$001C),DE
  LD DE,$000E
  LD A,$02
  JP l_BDB2
l_BE41:
  LD A,$06
  JR l_BE00
; This entry point is used by the routine at ReadMark.
l_BE45:
  LD A,$0C

; Read the bits of a mark between two blocks
;
; Used by the routine at StoreLast.
ReadMark:
  CALL sub_BCF8
  NOP
  NOP
  LD A,$0E
  CALL sub_BCF8
  RET NC
  LD A,$DB
  CP B
  RL L
  LD B,$B3
  JP NC,l_BE45
  RET

; Measure the tape's edges into TimeBuffer and compare them (replaced by tape
; block 37)
;
; Used by the routine at LoaderMain.
TimeCheck:
  CALL LoadBlocks
  LD HL,TimeBuffer
  LD B,$FF
l_BE65:
  PUSH BC
  CALL sub_BE78
  LD (HL),E
  INC HL
  POP BC
  DJNZ l_BE65
  LD A,($006D)
  CP $28
  RET Z
  CALL sub_BE94
  RET

; sub_BE78
;
; Used by the routine at TimeCheck.
sub_BE78:
  LD E,$00
  LD C,E
  LD B,$FF
l_BE7D:
  LD A,$7F
  IN A,($FE)
  AND $40
  XOR C
  JR Z,l_BE8F
  INC E
  LD A,C
  CPL
  AND $40
  LD C,A
l_BE8C:
  DJNZ l_BE7D
  RET
l_BE8F:
  NOP
  NOP
  JP l_BE8C

; sub_BE94
;
; Used by the routine at TimeCheck.
sub_BE94:
  LD HL,$0000
  LD DE,TimeBuffer+50
  LD B,$32
l_BE9C:
  PUSH BC
  LD A,(DE)
  LD B,$00
  LD C,A
  ADD HL,BC
  INC DE
  POP BC
  DJNZ l_BE9C
  PUSH HL
  LD HL,$0000
  LD DE,TimeBuffer+205
  LD B,$32
l_BEAF:
  PUSH BC
  LD A,(DE)
  LD B,$00
  LD C,A
  ADD HL,BC
  INC DE
  POP BC
  DJNZ l_BEAF
  POP BC
  LD A,H
  CP $0D
  JR NC,l_BECC
  AND A
  SBC HL,BC
  RET C
  LD BC,$0032
  AND A
  SBC HL,BC
  RET C
  LD A,$01
l_BECC:
  LD (TimeFailed),A
  RET

; Non-zero when the timing check failed (the mark check at $BE0D stores $7F
; when a mark's second group is not $7F; TimeCheck's $BECC stores 1)
TimeFailed:
  DEFB $00
EdgeLimits:
  DEFB $E9,$EA,$D2,$E2,$B6,$E0,$B6,$E0 ; seven pairs read by LoadBlocks $BD4C:
  DEFB $B6,$E0,$D2,$E2,$EC,$ED         ; the edge counter's start value and the
                                       ; count it must pass

; The end of a stream of blocks: the XOR in H must be 0
;
; Used by the routine at StoreByte.
LoadEnd:
  POP DE
  XOR A
  OUT ($FE),A
  LD A,H
  CP $01
  RET C
  CALL $C3EB

; Clear $5D00-$BBF3 (the chain), load the stage at $BF0D, clear the screen and
; run it
;
; Used by the routine at LoaderStart.
LoaderMain:
  LD HL,$5D00
  LD DE,$5D01
  LD BC,$5EF3
  LD (HL),L
  LDIR
  LD IX,Stage2
  LD DE,$00C3
  CALL TimeCheck
  LD HL,Attributes+767
  LD DE,Attributes+766
  LD BC,$1AFF
  LD (HL),$00
  LDDR
