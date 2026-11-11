; --------------------------------------------------------------------------------------------------------------------
; catalogue.asm: The mission catalogue: the directory load, the text of a mission
; --------------------------------------------------------------------------------------------------------------------

; Copy the catalogue's first 32 bytes to bank 6 $CF85 and the 1 K from $CB84 to
; the back buffer
;
; Pages bank 4, copies `$CB64` (32 bytes) via `$8AF1` to bank 6 `$CF85`, then
; `$CB84` (1024 bytes) to `$8AF1`. Witness: L1 32 (menu, missions, search).
CopyCatalogueHead:
  CALL SaveBank
  CALL PageBank4
  LD HL,l_CB56+$000E
  LD DE,BackBuffer
  LD BC,$0020
  LDIR
  CALL PageBank6
  LD HL,BackBuffer
  LD DE,ClusterParachute+$0005
  LD BC,$0020
  LDIR
  CALL PageBank4
  LD BC,$0400
  LD DE,BackBuffer
  LD HL,HitObstacle+$0018
  LDIR
  JP RestoreBank

; Copy mission ($757D)'s texts from the catalogue (bank 4) to bank 6 $DBF3
;
; Record n of the 8-byte index at `$CCA6`: the offset, two words stored at
; `$7143` and `$7151`, the end; the text is copied through `$8AF1` to `$DBF3`;
; `$70A3` and `$7C55` get the addresses of its two parts. Witness: L1 25 (menu,
; missions, search).
CopyMissionText:
  CALL SaveBank
  CALL PageBank4
  LD HL,l_CC98+$000E
  LD A,(ScreenOfMission+$0001)
  ADD A,A
  ADD A,A
  ADD A,A
  LD C,A
  LD B,$00
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE
  PUSH DE
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD (CopyMissionText+$004D),BC
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD (CopyMissionText+$005B),BC
  INC HL
  LD C,E
  LD B,D
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  AND A
  SBC HL,BC
  LD B,H
  LD C,L
  LD HL,l_CC56+$003C
  POP DE
  ADD HL,DE
  LD DE,BackBuffer
  PUSH BC
  LDIR
  CALL PageBank6
  LD HL,BackBuffer
  LD DE,PickupText+$005C
  POP BC
  LDIR
  LD HL,$0000
  POP BC
  AND A
  SBC HL,BC
  LD DE,PickupText+$005C
  ADD HL,DE
  LD (PrintTitleOnce+$0005),HL
  LD HL,$0000
  AND A
  SBC HL,BC
  ADD HL,DE
  LD (FailReason+$005C),HL
  JP RestoreBank

; Load the catalogue from side 2: the 17-byte header "DIRECTORY", then its
; block to bank 4 $CB64
;
; Loops until a header whose name is "DIRECTORY" (`$71B3`) loads, prints
; `$C90D` ("loading"), pages bank 4 and loads the block (length from the header
; `$8AFC`) to `$CB64`; retries until its first 9 bytes are "MISSION:T"
; (`$71BB`). Witness: L1 13 (c1, menu, missions, search).
LoadDirectory:
  LD IX,BackBuffer
  LD DE,$0011
  XOR A
  SCF
  DI
  LD (IX+$00),$00
  CALL LoadBlock
  JR NC,LoadDirectory
  CALL IsDirectoryHeader
  JR NZ,LoadDirectory
  CALL PrintRewind
  LD HL,l_C900+$000D
  CALL PrintString
  CALL PageBank4
l_7181:
  LD DE,(BackBuffer+$000B)
  LD IX,l_CB56+$000E
  LD A,$FF
  SCF
  CALL LoadBlock
  JR NC,LoadDirectory
  CALL IsCatalogue
  JR NZ,l_7181
  CALL PageBank6
  EI
  RET

; Print bank 6 $C93E
;
; Witness: L1 25 (c1, menu, missions, search).
PrintRewind:
  LD HL,l_C92E+$0010
  JP PrintString

; Z if the header at $8AF2 starts "MISSHDR:" (8 bytes)
;
; Witness: L1 19 (c1, m10, m2erbe, m2ocean, missions, search).
IsMissionHeader:
  LD DE,MissionHeaderName+$0001
  LD HL,BackBuffer+$0001
  LD B,$08
  JR CompareB

; Z if the block at $DBC6 starts "MISSION::" (9 bytes)
;
; Witness: known only from the code.
IsMissionBlock:
  LD DE,MissionBlockName
  LD HL,PickupText+$002F
  JR CompareNine

; Z if the header at $8AF2 is "DIRECTORY"
;
; Witness: L1 12 (c1, menu, missions, search).
IsDirectoryHeader:
  LD DE,DirectoryName
  LD HL,BackBuffer+$0001
  JR CompareNine

; Z if the catalogue at $CB64 starts "MISSION:T"
;
; Witness: L1 12 (c1, menu, missions, search).
IsCatalogue:
  LD DE,CatalogueName+$0001
  LD HL,l_CB56+$000E

; B = 9, then CompareB
;
; Witness: L1 24 (c1, menu, missions, search).
CompareNine:
  LD B,$09

; Compare B bytes at DE and HL: Z when equal
;
; Witness: L1 41 (c1, m10, m2erbe, m2ocean, menu, missions, search).
CompareB:
  LD A,(DE)
  CP (HL)
  RET NZ
  INC HL
  INC DE
  DJNZ CompareB
  RET

; "MISSION::", the name a mission block starts with
MissionBlockName:
  DEFM "MISSION::"

; "MISSHDR:", the name of a mission header
MissionHeaderName:
  DEFM ":MISSHDR:"

; "DIRECTORY"
DirectoryName:
  DEFM "DIRECTORY"

; "MISSION:T", the start of the catalogue
CatalogueName:
  DEFM ":MISSION:TA"
