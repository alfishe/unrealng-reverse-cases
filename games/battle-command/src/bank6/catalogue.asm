; --------------------------------------------------------------------------------------------------------------------
; catalogue.asm: The mission catalogue screen: the list of the ten missions from the catalogue, the selection, the description
;
; MissionCatalogueScreen $C790 is screen node $7504 of the screen list (ScreenList $74E6). On the first visit the
; catalogue is not yet in memory (IsCatalogueLoaded $C870 compares its head with "MISSION"): the screen asks for the
; mission tape and loads it (LoadDirectory $715D). Then BuildMissionNames $C030 makes ten printable lines from the
; catalogue's names, PrintMissionList $CFA9 prints them, a tick (TickGraphic $C978) marks every completed mission
; (MissionsDone $6799), and the pointer's zones (CatalogueZones $C851) load a mission, pick a line, go to the briefing
; or the stores.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C030

; Copy the catalogue's head, then build the ten mission name lines at $93D9
; with their pointers at $93B9
;
; CopyCatalogueHead `$70C6` puts the catalogue's first 1 K into the back buffer
; at `$8AF1`. For each of the ten 27-byte names there: code 13 with the
; attribute `$46`, the name up to its 0 byte, spaces to 27 characters, code 11
; and the end `$FF`; the line's address goes to the next word of `$93B9`.
;
; Output: the strings in `$93D9-$950E` and the table `$93B9-$93CC` (in the back
; buffer, bank 2). Witness: L1 32 (c1, death, m10, m2erbe, m2ocean, menu,
; missions, play, play2, search).
BuildMissionNames:
  CALL $70C6
  LD DE,$93D9
  LD HL,$8AF1
  LD C,$06
  EXX
  LD A,$0A
  LD B,A
  LD HL,$93B9
NameLoop:
  EXX
  PUSH DE
  LD A,$0D
  LD (DE),A
  INC DE
  LD A,$46
  LD (DE),A
  INC DE
  LD B,$1B
NameCopy:
  LD A,(HL)
  AND A
  JR Z,NamePad
  LD (DE),A
  INC DE
  INC HL
  DJNZ NameCopy
NamePad:
  LD A,$20
NamePadLoop:
  LD (DE),A
  INC DE
  INC HL
  DJNZ NamePadLoop
  LD A,$0B
  LD (DE),A
  INC DE
  LD A,$FF
  LD (DE),A
  INC DE
  EXX
  POP DE
  LD (HL),E
  INC HL
  LD (HL),D
  INC HL
  DJNZ NameLoop
  RET

; Wait until the interrupt's fire test sets ClickFlag $6D43, then clear it
;
; Known only from the code: nothing calls it.
WaitForClick:
  LD HL,$6D43
WaitClickLoop:
  LD A,(HL)
  AND A
  JR Z,WaitClickLoop
  LD (HL),$00
  RET

  ORG $C75F

; Unused: return when no mission is chosen ($757D = $FF), else
; DrawCatalogueTitles
;
; Known only from the code: nothing calls it.
DrawCatalogueTitlesIf:
  LD A,($757D)
  CP $FF
  RET Z

; The catalogue's two title graphics and their attribute boxes
;
; CopyGraphic of CatalogueGraphicA (9 x 32 at line `$A0`) and CatalogueGraphicC
; (9 x 16 at line `$90`), AttrBox `$C74F` and `$C754`. Witness: L1 33 (c1,
; death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).
DrawCatalogueTitles:
  LD HL,CatalogueGraphicA
  LD D,$09
  LD C,$20
  EXX
  LD C,$04
  LD A,$A0
  CALL $6D7F
  LD HL,CatalogueGraphicC
  LD D,$09
  LD C,$10
  EXX
  LD C,$04
  LD A,$90
  CALL $6D7F
  LD HL,CatalogueTitleBoxA
  CALL $6CFB
  LD HL,CatalogueTitleBoxB
  CALL $6CFB
  RET

; The mission catalogue: picture, the tape load if needed, the list, the ticks,
; then the zones
;
; The shadow screen, the pointer centred, DrawBank7Picture `$74AA` with `$CCC9`
; (PicMissionSelect), CatalogueGraphicB, DrawCatalogueTitles, the box `$C759`.
; When IsCatalogueLoaded says no: PrintRewind `$719B`, RewindText,
; LoadDirectory `$715D`. Then BuildMissionNames, PrintMissionList, a tick for
; every completed mission of MissionsDone, CataloguePointerLimits, the
; highlight of the selected line, the arrow pointer, the texts `$C93E`, `$C8D5`
; and the catalogue's title `$CF85`, RemarkMission `$8548`,
; PrintSelectedMission; then PointerZones until the view flag is set,
; ShowWaitPointer, NextView. Witness: L1 33 (c1, death, m10, m2erbe, m2ocean,
; menu, missions, play, play2, search).
MissionCatalogueScreen:
  CALL $7268
  XOR A
  LD ($83BF),A
  LD A,$80
  LD ($7DC0),A
  LD ($9715),A
  LD ($7C51),A
  LD ($7DC1),A
  LD ($9716),A
  LD ($7C53),A
  LD DE,NoPickupText+$000B
  CALL $74AA
  LD HL,CatalogueGraphicB
  LD D,$0B
  LD C,$10
  EXX
  LD C,$13
  LD A,$B0
  CALL $6D7F
  CALL DrawCatalogueTitles
  LD HL,CatalogueListBox
  CALL $6CFB
  CALL $725F
  CALL IsCatalogueLoaded
  JR Z,CatalogueLoaded
  CALL $719B
  LD HL,RewindText
  CALL $6FB3
  CALL SavePointerBackground
  CALL $715D
  CALL RestorePointerBackground
CatalogueLoaded:
  CALL BuildMissionNames
  CALL PrintMissionList
  LD C,$40
  LD B,$0A
  LD HL,$6799
TickLoop:
  LD A,(HL)
  AND A
  LD A,C
  JR Z,TickNext
  PUSH HL
  PUSH BC
  LD HL,TickGraphic
  LD C,$08
  LD D,$01
  EXX
  LD C,$02
  CALL $6D7F
  POP BC
  POP HL
TickNext:
  LD A,$08
  ADD A,C
  LD C,A
  INC HL
  DJNZ TickLoop
  CALL CataloguePointerLimits
SelectedLineOp:
  LD A,$FF                ; LD A,n: n ($C811) the selected line's pixel row
                          ; ($FF none), written by SelectMissionLine
  CP $FF
  JR Z,CatalogueNoHighlight
  CALL HighlightLine
CatalogueNoHighlight:
  LD HL,PointerShapes
  LD (ShiftPointer+$0001),HL
  LD HL,BlankTapeText
  CALL $6FB3
  LD HL,CataloguePos
  CALL $6FB3
  LD HL,CatalogueTitle
  CALL $6FB3
  CALL $8548
  CALL PrintSelectedMission
  CALL SavePointerBackground
  CALL $725F
  LD A,$FF
  LD ($83BF),A
CatalogueLoop:
  CALL $6D42
  LD A,($6A6D)
  AND A
  JR Z,CatalogueLoop
  CALL ShowWaitPointer
  JP $6A91

; Zone table of the catalogue
;
; LoadMissionHeader `$84FE`, LoadMissionIfAllowed `$759A`, ScreenOfMission
; `$757C`, `$67EE` (ScreenFour: the mission status), SelectMissionLine `$D013`
; (the list).
CatalogueZones:
  DEFB $22,$5E,$92,$9E,$FE,$84
  DEFB $22,$63,$B1,$B8,$9A,$75
  DEFB $22,$63,$A1,$AD,$7C,$75
  DEFB $9A,$EB,$B3,$B8,$EE,$67
  DEFB $10,$68,$41,$8E,$13,$D0
  DEFB $00

; Z when the catalogue head at $CF85 starts with "MISSION"
;
; Compares 7 bytes with CatalogueMagic. Witness: L1 33 (c1, death, m10, m2erbe,
; m2ocean, menu, missions, play, play2, search).
IsCatalogueLoaded:
  LD HL,CatalogueTitle
  LD DE,CatalogueMagic
  LD B,$07
MagicLoop:
  LD C,(HL)
  LD A,(DE)
  CP C
  RET NZ
  INC HL
  INC DE
  DJNZ MagicLoop
  RET

; "MISSION:TAPE:": the first 7 bytes are compared with the catalogue's head
;
; Read by IsCatalogueLoaded.
CatalogueMagic:
  DEFB $4D,$49,$53,$53,$49,$4F,$4E,$3A,$54,$41,$50,$45,$3A

; Leftover of a disk version: "INCORRECT DISK" and a red attribute bar
;
; Known only from the code: nothing calls it; the texts `$C8A0` and `$C8B2`
; speak of a disk.
ShowWrongDisk:
  LD HL,DiskTexts
  CALL $6FB3
  LD A,$EA
  LD HL,$58A4
  LD B,$0B
WrongDiskBar:
  LD (HL),A
  INC HL
  DJNZ WrongDiskBar
  RET

; Texts: "INCORRECT DISK", "INSERT DISK AND PRESS SPACE", the tape messages
;
; Small-font texts (code 7 at a line and column), `:` is the blank, `[` a full
; stop. `$C8A0` read by ShowWrongDisk; `$C8B2` and `$C90D` by nothing in bank
; 6.
DiskTexts:
  DEFB $07,$2A,$06,$49,$4E,$43,$4F,$52,$52,$45,$43,$54,$3A,$44,$49,$53
  DEFB $4B,$FF
InsertDiskText:
  DEFB $07,$2A,$05,$49,$4E,$53,$45,$52,$54,$3A,$44,$49,$53,$4B,$3A,$41
  DEFB $4E,$44,$07,$33,$07,$50,$52,$45,$53,$53,$3A,$53,$50,$41,$43,$45
  DEFB $FF
  DEFB $00,$00            ; two zero bytes
CataloguePos:
  DEFB $07,$20,$05,$FF    ; code 7 to line $20, column 5
                          ; (MissionCatalogueScreen `$C825`)
RewindText:
  DEFB $07,$20,$05,$52,$45,$57,$49,$4E,$44,$3A,$4D,$49,$53,$53,$49,$4F ; "REWIND
  DEFB $4E,$07,$2A,$05,$54,$41,$50,$45,$3A,$54,$4F,$3A,$53,$54,$41,$52 ; MISSION
  DEFB $54,$07,$34,$05,$41,$4E,$44,$3A,$50,$52,$45,$53,$53,$3A,$50,$4C ; TAPE TO
  DEFB $41,$59,$5B,$FF                                                 ; START AND
                                                                       ; PRESS
                                                                       ; PLAY"
FoundCatalogueText:
  DEFB $07,$20,$05,$46,$4F,$55,$4E,$44,$3A,$4D,$49,$53,$53,$49,$4F,$4E ; "FOUND
  DEFB $3A,$07,$2A,$05,$43,$41,$54,$41,$4C,$4F,$47,$55,$45,$3A,$41,$4E ; MISSION
  DEFB $44,$07,$34,$05,$4E,$4F,$57,$3A,$4C,$4F,$41,$44,$49,$4E,$47,$5B ; CATALOGUE
  DEFB $FF                                                             ; AND NOW
                                                                       ; LOADING"
BlankTapeText:
  DEFB $07,$20,$05,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A ; three
  DEFB $3A,$3A,$3A,$07,$2A,$05,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A ; blank
  DEFB $3A,$3A,$3A,$3A,$3A,$3A,$07,$34,$05,$3A,$3A,$3A,$3A,$3A,$3A,$3A ; lines:
  DEFB $3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$3A,$FF                         ; PrintRewind
                                                                       ; $719B

; The tick of a completed mission, 1 x 8
;
; CopyGraphic source of MissionCatalogueScreen `$C7F7`.
TickGraphic:
  DEFB $80
  DEFB $BE
  DEFB $BA
  DEFB $A6
  DEFB $AE
  DEFB $BE
  DEFB $80
  DEFB $FF

; Two attribute box records of the briefing
;
; Read by BriefingScreen `$C9AB` and `$C9B1`.
BriefingBoxes:
  DEFB $47,$02,$00,$07,$03
BriefingBoxB:
  DEFB $47,$04,$00,$07,$0A

  ORG $CFA9

; Print the ten mission lines of $93B9 (blanks as ":") 8 pixel lines apart from
; line $41
;
; Each line is copied over itself with spaces turned into `:` (the blank glyph
; of the small font) and printed after ListLinePos. Witness: L1 32 (c1, death,
; m10, m2erbe, m2ocean, menu, missions, play, play2, search).
PrintMissionList:
  LD A,$0A
  LD (ListCountOp+$0001),A
  LD HL,$93B9
  LD (ListPtrOp+$0001),HL
  LD A,$41
  LD (ListLinePos+$0001),A
ListLineLoop:
  LD HL,ListLinePos
  CALL $6FB3
ListPtrOp:
  LD HL,$0000             ; LD HL,n: n ($CFC0) the next pointer of $93B9
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (ListPtrOp+$0001),HL
  LD H,D
  LD L,E
  LD B,$12
ListCharLoop:
  LD A,(DE)
  CP $20
  JR NZ,ListCharStore
  LD A,$3A
ListCharStore:
  LD (DE),A
  INC DE
  DJNZ ListCharLoop
  LD A,$FF
  LD (DE),A
  CALL $6FB3
  LD A,(ListLinePos+$0001)
  ADD A,$08
  LD (ListLinePos+$0001),A
ListCountOp:
  LD A,$00                ; LD A,n: n ($CFE7) the lines left
  DEC A
  LD (ListCountOp+$0001),A
  JR NZ,ListLineLoop
  RET

; Text: code 7 to line $41 (moved for every line), column 5
;
; Written and printed by PrintMissionList.
ListLinePos:
  DEFB $07,$41,$05,$FF

; Print the name of mission ($757B) at SelectedPos (none when negative)
;
; Witness: L1 32 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
PrintSelectedMission:
  LD HL,SelectedPos
  CALL $6FB3
  LD A,($757B)
  AND A
  RET M
  DEC A
  ADD A,A
  LD HL,$93B9
  LD D,$00
  LD E,A
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  JP $6FB3

; Text: code 7 to line $2A, column 5; a zero byte
;
; Printed by PrintSelectedMission.
SelectedPos:
  DEFB $07,$2A,$05,$FF,$00

; Zone: the list line under the pointer becomes the mission ($757D),
; highlighted, its description printed
;
; The line from the pointer's Y (`$9716`): (Y - `$40`) / 8; the pixel row into
; SelectedLineOp. HighlightLine, the pointer saved again. Witness: L1 29 (c1,
; death, m10, m2erbe, m2ocean, menu, missions, play, play2, search).
SelectMissionLine:
  LD A,($9716)
  LD C,A
  SUB $40
  SRL A
  SRL A
  SRL A
  LD ($757D),A
  LD A,C
  AND $F8
  CP $FF
  RET Z
  LD (SelectedLineOp+$0001),A
  EX AF,AF'
  CALL RestorePointerBackground
  EX AF,AF'
  LD HL,$83BF
  LD (HL),$00
  CALL HighlightLine
  CALL SavePointerBackground
  LD HL,$83BF
  DEC (HL)
  RET

; Unhighlight the old line (attribute $4D), highlight row A ($4E), print the
; description
;
; The old row is the operand `$D026` (`$FF` none). Witness: L1 49 (c1, death,
; m10, m2erbe, m2ocean, menu, missions, play, play2, search).
HighlightLine:
  PUSH AF
  LD A,(SelectMissionLine+$0013)
  CP $FF
  JR Z,HighlightNew
  LD E,$4D
  CALL FillAttrRow
HighlightNew:
  POP AF
  LD (SelectMissionLine+$0013),A
  LD E,$4E
  CALL FillAttrRow
  JP PrintMissionDescription

; Fill 12 attributes of row A/8 from column 3 with E
;
; Witness: L1 88 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
FillAttrRow:
  LD BC,$5803
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,BC
  LD (HL),E
  LD E,L
  LD D,H
  INC DE
  LD BC,$000B
  LDIR
  RET

; Clear the description area and print mission ($757D)'s description from the
; catalogue
;
; ScreenRowFill, DescriptionPos, then the text at `$8BFF` + the word
; `$8BFF`[mission]. Witness: L1 49 (c1, death, m10, m2erbe, m2ocean, menu,
; missions, play, play2, search).
PrintMissionDescription:
  LD A,$FF
  EX AF,AF'
  LD A,$88
  LD BC,$0013
  EXX
  LD D,$0C
  LD E,$20
  CALL $6D22
  LD HL,DescriptionPos
  CALL $6FB3
  LD HL,$8BFF
  PUSH HL
  LD A,($757D)
  ADD A,A
  LD E,A
  LD D,$00
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  POP HL
  ADD HL,DE
  JP $6FB3

; Text: code 9, code 7 to line $88, column $12
;
; Printed by PrintMissionDescription.
DescriptionPos:
  DEFB $09,$22,$07,$88,$12,$FF
