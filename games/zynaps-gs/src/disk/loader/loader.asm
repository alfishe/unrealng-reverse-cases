; --------------------------------------------------------------------------------------------------------------------
; loader.asm: the level loader: the FX in the banks, the disk FX and the modules sent to the card
;
; Three entries, called by the driver's LevelChange: StartFx (the game start: the jingle uploaded from bank 1 and
; played), LoadFx (the 10 in-game FX from the banks; in effects-only mode the 11 disk FX after them) and LoadModule (a
; level's module, read from the disk record by record).
;
; The disk part is a table of 6-byte records (FxRecords, ModuleRecords): the number of sectors, flags (bit 0 delta
; coded: never set; bit 1 a Trush block; bit 7 the last record of a set), the sector and the track (written at start-
; up by the installer's FillRecords: the records lie one after another from the sector after Trush block 4), and a
; word: for the FX sets the address of the FX lengths, for a module part its length. The lengths are negative: the
; senders count BC up to 0.
;
; Each record is read to PackedAt with bank 7 paged; a Trush block there unpacks itself to $C000. The bytes go to the
; card through the data port, each after the card took the one before (status bit 7). While a module loads, bank 7's
; copy of the loading screen is on the screen.
; --------------------------------------------------------------------------------------------------------------------

; the game start: the jingle uploaded from bank 1 (StartFxData), then played:
; FX 1, note $33, channel 1
;
; The driver's load-once patch turns the CALL of this entry into a CALL of
; PlayStartFx: the jingle stays on the card.
StartFx:
  LD A,$11
  LD (NextPage+1),A
  LD HL,StartFxData
  LD IX,StartFxLength
  CALL UploadFxList
PlayStartFx:
  LD HL,$3301             ; FX 1 at note $33 in channel 1 (PlayFx, not the
                          ; patched PlayFxFrom: the jingle keeps handle 1)
  LD C,$01
  JP PlayFx

; the 10 in-game FX from bank 1 $FAA5 on; in effects-only mode the disk FX
; after them
;
; In effects-only mode with SATURNS off, the third FX record gets bit 7 (the
; last): FX 21 (the fourth record, the Saturn sound) is not loaded. The disk FX
; are loaded with the loading screen shown (bank 7's copy).
LoadFx:
  DI
  LD A,$11
  LD BC,$7FFD
  OUT (C),A
  LD (NextPage+1),A
  LD HL,InGameFxData
  LD IX,InGameFxLengths
  CALL UploadFxList
  LD A,(EffectsOnly)
  OR A
  JR Z,l_620F
  LD A,(OptionSaturns)
  OR A
  JR NZ,l_61E8
  LD A,($63C3)
  OR $80
  LD (FxRecords+$000D),A
l_61E8:
  LD A,$17                ; the loading screen from bank 7
  CALL SetPage
  LD HL,Bank
  LD DE,Screen
  LD BC,$1B00
  LDIR
  LD IX,FxRecords
  CALL LoadDiskFx
; This entry point is used by the routine at LoadModule.
ScreenToBank7:
  LD A,$17                ; the screen back to bank 7's copy
  CALL SetPage
  LD HL,Screen
  LD DE,Bank
  LD BC,$1B00
  LDIR
l_620F:
  LD BC,$7FFD             ; bank 1 again (the driver's)
  LD A,$11
  OUT (C),A
  RET

; one FX a negative length at IX (to a zero word): #38 (load FX), its handle
; read, the command $D1, the bytes, the command $D2
;
; Used by the routines at StartFx and LoadFx.
UploadFxList:
  LD C,(IX+$00)
  LD B,(IX+$01)
  LD A,C
  OR B
  RET Z
  LD A,$38
  OUT ($BB),A
  CALL WaitCommand
  IN A,($B3)
  LD A,$D1
  OUT ($BB),A
  CALL WaitCommand
  CALL SendBanked
  LD A,$D2
  OUT ($BB),A
  CALL WaitCommand
  INC IX
  INC IX
  JR UploadFxList

; BC (negative) bytes from HL to the card; past $FFFF the next bank of 1, 3, 4,
; 6, 7 at $C000
;
; Used by the routine at UploadFxList.
SendBanked:
  LD A,(HL)
  OUT ($B3),A
l_6243:
  IN A,($BB)
  RLCA
  JR C,l_6243
  INC L
  JR NZ,l_6268
  INC H
  JR NZ,l_6268
NextPage:
  LD A,$11                ; the bank being read (the operand of the LD A,
                          ; written by the entries and here)
  INC A
  CP $12
  CALL Z,SkipPage
  CP $15
  CALL Z,SkipPage
  PUSH BC
  LD BC,$7FFD
  OUT (C),A
  POP BC
  LD HL,Bank
  LD (NextPage+1),A
l_6268:
  INC C
  JR NZ,SendBanked
  INC B
  JR NZ,SendBanked
  RET

; banks 2 and 5 are skipped (they are the 128's fixed $8000 and $4000)
;
; Used by the routine at SendBanked.
SkipPage:
  INC A
  RET

; until the card has taken the command (status bit 0 clear)
;
; Used by the routines at UploadFxList, LoadModule, LoadDiskFx and
; UploadFxSets.
WaitCommand:
  IN A,($BB)
  RRCA
  RET NC
  JR WaitCommand

; the module of Level (13 when LoadKind is 2) from the disk: #30 (load module),
; its handle, the command $D1, the parts, the command $D2
;
; The handle goes to the driver's PlayModule (ModuleHandle), the level's volume
; from ModuleVolumes to ModuleVolume, the first record from ModuleRecords. Each
; part is read (ReadRecord) and sent from $C000 (a Trush part) or PackedAt (a
; raw part), plain or delta coded by its flags, until the record with bit 7.
LoadModule:
  DI
  LD A,$17
  CALL SetPage
  LD HL,Bank
  LD DE,Screen
  LD BC,$1B00
  LDIR
  LD A,$30
  OUT ($BB),A
  CALL WaitCommand
  IN A,($B3)
  LD (ModuleHandle),A
  LD A,$D1
  OUT ($BB),A
  CALL WaitCommand
  LD A,(LoadKind)
  CP $02
  LD A,$0D
  JR Z,l_62A7
  LD A,(Level)
l_62A7:
  DEC A
  LD C,A
  LD B,$00
  LD HL,ModuleVolumes
  ADD HL,BC
  ADD A,A
  LD C,A
  LD A,(HL)
  LD (ModuleVolume),A
  LD HL,LevelRecords
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  POP IX
l_62BF:
  CALL ReadRecord         ; one part
  LD HL,Bank
  JR NZ,l_62CA
  LD HL,PackedAt
l_62CA:
  LD C,(IX+$04)
  LD B,(IX+$05)
  LD A,(IX+$01)
  AND $01
  JR NZ,l_62DC
  CALL SendPlain
  JR l_62DF
l_62DC:
  CALL SendDelta
l_62DF:
  LD A,(IX+$01)
  LD DE,$0006
  ADD IX,DE
  AND $80
  JR Z,l_62BF
  LD A,$D2
  OUT ($BB),A
  CALL WaitCommand
  JP ScreenToBank7

; the disk FX sets (UploadFxSets from FxRecords), then #2B (FX volume) with $40
;
; Used by the routine at LoadFx.
LoadDiskFx:
  CALL UploadFxSets
  LD A,$40
  OUT ($B3),A
  LD A,$2B
  OUT ($BB),A
  JP WaitCommand

; the record at IX: its sectors to PackedAt with bank 7 paged, then run when it
; is a Trush block (bit 1)
;
; Returns NZ for a Trush part (its bytes are at $C000), Z for a raw one (at
; PackedAt).
ReadRecord:
  LD B,(IX+$00)
  LD E,(IX+$02)
  LD D,(IX+$03)
  LD HL,PackedAt
  CALL ReadSectors
  LD A,(IX+$01)
  AND $02
  PUSH AF
  PUSH IX
  LD A,$17
  CALL SetPage
  CALL NZ,PackedAt
  DI
  POP IX
  POP AF
  RET

; the FX records from IX: each read (ReadRecord), then its FX uploaded by the
; length list it points to
;
; Used by the routine at LoadDiskFx.
UploadFxSets:
  CALL ReadRecord
  LD HL,Bank
  JR NZ,l_6332
  LD HL,PackedAt
l_6332:
  LD E,(IX+$04)
  LD D,(IX+$05)
  LD A,(IX+$01)
  PUSH IX
  PUSH DE
  POP IX
  AND $01
  JR NZ,l_6349
  LD DE,SendPlain
  JR l_634C
l_6349:
  LD DE,SendDelta
l_634C:
  LD (SendCall+1),DE
l_6350:
  LD C,(IX+$00)           ; one FX
  LD B,(IX+$01)
  LD A,B
  OR C
  JR Z,l_637D
  LD A,$38
  OUT ($BB),A
  CALL WaitCommand
  IN A,($B3)
  LD (FxHandle),A
  LD A,$D1
  OUT ($BB),A
  CALL WaitCommand
SendCall:
  CALL $0000              ; the sender the record's bit 0 chose (SendPlain or
                          ; SendDelta; the operand written above)
  LD A,$D2
  OUT ($BB),A
  CALL WaitCommand
  INC IX
  INC IX
  JR l_6350
l_637D:
  POP IX                  ; the next record, until bit 7
  LD A,(IX+$01)
  AND $80
  RET NZ
  LD DE,$0006
  ADD IX,DE
  JR UploadFxSets

; the handle the card gave the last FX (kept, not used)
FxHandle:
  DEFB $00

; BC (negative) bytes from HL to the card
;
; Used by the routine at LoadModule.
SendPlain:
  LD A,(HL)
  OUT ($B3),A
l_6390:
  IN A,($BB)
  RLCA
  JP C,l_6390
  INC HL
  INC C
  JP NZ,SendPlain
  INC B
  JP NZ,SendPlain
  RET

; BC (negative) bytes from HL to the card, each the running sum of the bytes
; (no record uses it)
;
; Used by the routine at LoadModule.
SendDelta:
  XOR A
l_63A1:
  ADD A,(HL)
  OUT ($B3),A
  LD E,A
l_63A5:
  IN A,($BB)
  RLCA
  JP C,l_63A5
  LD A,E
  INC HL
  INC C
  JP NZ,l_63A1
  INC B
  JP NZ,l_63A1
  RET

; the disk FX: 4 records (FX 11-12 raw, FX 13-16 Trush, FX 17-20 raw, FX 21
; Trush)
;
; Their words are the addresses of FxSet1Lengths, FxSet2Lengths, FxSet3Lengths
; and FxSet4Lengths ($650C, $6512, $651C, $6526). The sector and track bytes
; are what the disk carries before FillRecords writes them: older values of
; another layout.
;
; LoadFx sets bit 7 of the third record's flags (FxRecords+13) when SATURNS is
; off.
FxRecords:
  DEFB $3D,$00,$00,$01,$0C,$65
  DEFB $2F,$02,$0D,$04,$12,$65
  DEFB $36,$00,$0C,$07,$1C,$65
  DEFB $18,$82,$02,$0B,$26,$65

; the 13 modules' 42 parts, in the disk's order: levels 9, 3, 13, 7, 5, 6, 1,
; 12, 2, 11, 4, 8, 10
;
; A part is 16384 bytes, the last one the rest; the words are the parts'
; negative lengths.
ModuleRecords:
  DEFB $1F,$02,$0A,$0C,$00,$C0
  DEFB $2B,$02,$09,$0E,$00,$C0
  DEFB $37,$02,$04,$11,$00,$C0
  DEFB $12,$82,$0B,$14,$6A,$ED
  DEFB $26,$02,$0D,$15,$00,$C0
  DEFB $3C,$02,$03,$18,$00,$C0
  DEFB $12,$80,$0F,$1B,$00,$EE
  DEFB $1B,$02,$01,$1D,$00,$C0
  DEFB $3F,$02,$0C,$1E,$00,$C0
  DEFB $3F,$02,$0B,$22,$00,$C0
  DEFB $09,$80,$0A,$26,$00,$F7
  DEFB $14,$02,$03,$27,$00,$C0
  DEFB $2A,$02,$07,$28,$00,$C0
  DEFB $29,$02,$01,$2B,$00,$C0
  DEFB $0F,$82,$0A,$2D,$00,$ED
  DEFB $11,$02,$09,$2E,$00,$C0
  DEFB $40,$00,$0A,$2F,$00,$C0
  DEFB $35,$02,$0A,$33,$00,$C0
  DEFB $1B,$82,$0F,$36,$00,$E4
  DEFB $31,$02,$0A,$38,$00,$C0
  DEFB $2F,$82,$0B,$3B,$00,$D0
  DEFB $09,$02,$0A,$3E,$00,$C0
  DEFB $40,$00,$03,$3F,$00,$C0
  DEFB $3E,$02,$03,$43,$00,$C0
  DEFB $1C,$82,$01,$47,$00,$D8
  DEFB $0B,$02,$0D,$48,$00,$C0
  DEFB $40,$00,$08,$49,$00,$C0
  DEFB $3C,$80,$08,$4D,$00,$C4
  DEFB $40,$00,$04,$51,$00,$C0
  DEFB $36,$02,$04,$55,$00,$C0
  DEFB $25,$82,$0A,$58,$00,$DA
  DEFB $40,$00,$0F,$5A,$00,$C0
  DEFB $40,$00,$0F,$5E,$00,$C0
  DEFB $21,$80,$0F,$62,$00,$DF
  DEFB $09,$02,$00,$65,$00,$C0
  DEFB $32,$02,$09,$65,$00,$C0
  DEFB $1C,$82,$0B,$68,$00,$E0
  DEFB $11,$02,$07,$6A,$00,$C0
  DEFB $40,$00,$08,$6B,$00,$C0
  DEFB $18,$82,$08,$6F,$00,$D2
  DEFB $1F,$02,$00,$71,$00,$C0
  DEFB $1E,$82,$0F,$72,$00,$D9

; 0: the end of the records for FillRecords
RecordsEnd:
  DEFB $00

; each level's first record (levels 1-13; 13 is the title module)
LevelRecords:
  DEFW $644C
  DEFW $6476
  DEFW $63E6
  DEFW $649A
  DEFW $6428
  DEFW $6440
  DEFW $6410
  DEFW $64AC
  DEFW ModuleRecords
  DEFW $64BE
  DEFW $6488
  DEFW $6464
  DEFW $63F8

; each level's module volume (#2A)
ModuleVolumes:
  DEFB $1A,$20,$3C,$28,$40,$20,$40,$20,$40,$20,$20,$26,$40

; the jingle's length (negative), then 0
StartFxLength:
  DEFW $D926
  DEFW $0000

; the 10 in-game FX lengths, then 0
InGameFxLengths:
  DEFW $FD76
  DEFW $EBA9
  DEFW $EC72
  DEFW $FA8C
  DEFW $E75C
  DEFW $FABD
  DEFW $DAA6
  DEFW $D649
  DEFW $F10D
  DEFW $E66C
  DEFW $0000

; FX 11, 12
FxSet1Lengths:
  DEFW $D3EE
  DEFW $EF88
  DEFW $0000

; FX 13-16
FxSet2Lengths:
  DEFW $F286
  DEFW $F21E
  DEFW $F62C
  DEFW $EE90
  DEFW $0000

; FX 17-20
FxSet3Lengths:
  DEFW $EE13
  DEFW $FA5E
  DEFW $F234
  DEFW $EFCD
  DEFW $0000

; FX 21
FxSet4Lengths:
  DEFW $DC48
  DEFW $0000

; B sectors from D:E to HL: the TURBO LOADER option (TurboTest) picks FastRead
; or TR-DOS's function 5
;
; Used by the routine at ReadRecord.
ReadSectors:
  PUSH IX
  PUSH IY
  LD IY,ERR_NR
TurboTest:
  LD A,$01                ; LD A,1: the menu's TURBO LOADER (YES = 1) writes
                          ; the operand
  OR A
  JR NZ,l_6546
  XOR A
  LD (TRDOS_5D10),A
  LD C,$05
  CALL TRDOS_ENTRY
l_6540:
  DI
  POP IY
  POP IX
  RET
l_6546:
  CALL FastRead
  JR l_6540

; TURBO LOADER: the sectors with TR-DOS's own FDC routines, each retried until
; it reads without error
;
; Used by the routine at ReadSectors.
FastRead:
  CALL SeekTrack
  LD IX,TRDOS_WAIT_INTRQ
  CALL RomCall
l_6555:
  LD A,(TRDOS_ERRORS)            ; one sector: TRDOS_ERRORS before
  PUSH HL
  PUSH BC
  EX AF,AF'
  CALL ReadSector
  DI
  EX AF,AF'
  LD HL,TRDOS_ERRORS
  CP (HL)
  JP Z,l_656B
  POP BC
  POP HL
  JR l_6555
l_656B:
  POP BC                  ; read: the next sector, the next track after 16
  POP HL
  INC E
  BIT 4,E
  JP Z,l_6579
  LD E,$00
  INC D
  CALL SeekTrack
l_6579:
  INC H
  DJNZ l_6555
  RET

; sector E + 1 to the FDC's sector register, then TR-DOS's read-sector code
; with BC = $017F
;
; The LD BC pushes this routine's own address before the jumps into the ROM: a
; word the ROM code takes from the stack on its way out.
ReadSector:
  LD BC,ReadSector
  PUSH BC
  LD A,E
  INC A
  LD C,$5F
  CALL WriteFdc
  LD BC,$017F
  LD IX,TRDOS_READ_SECTOR
  JR RomCall

; drive side from D bit 0 (system register), track D >> 1 to the data register,
; the seek command ($18)
;
; Used by the routine at FastRead.
SeekTrack:
  LD A,(TRDOS_SYSREG)
  OR $3C
  BIT 0,D
  JR Z,l_659C
  RES 4,A
l_659C:
  LD C,$FF
  CALL WriteFdc
  LD A,D
  AND A
  RRA
  LD C,$7F
  CALL WriteFdc
  LD A,$18
  LD C,$1F

; A to the port C through TRDOS_OUT_C
;
; Used by the routines at ReadSector and SeekTrack.
WriteFdc:
  LD IX,TRDOS_OUT_C

; IX run inside the TR-DOS ROM (PUSH IX; JP TRDOS_CALL)
;
; Used by the routines at FastRead and ReadSector.
RomCall:
  PUSH IX
  JP TRDOS_CALL

; A to port $7FFD and BANKM
;
; Used by the routines at LoadFx, LoadModule and ReadRecord.
SetPage:
  LD (BANKM),A
  PUSH BC
  LD BC,$7FFD
  OUT (C),A
  POP BC
  RET
