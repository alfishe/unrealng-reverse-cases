; --------------------------------------------------------------------------------------------------------------------
; briefing.asm: The briefing screen: the notes folder, the mission's text, the map
;
; BriefingScreen $C98A is node $750E (zones BriefingZones $CA10). It copies the chosen mission's texts from the
; catalogue (CopyMissionText $70F6) to MissionData $DBF3, unpacks PicBriefing ($E949 of bank 7), adds three graphics
; and prints the briefing text at ($70A3). Its zones show the mission's map (ShowPauseOnce $7084: BriefingMapFrame
; $DACB and BriefingMap $DB64), print the title again ($709E) or go back.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C98A

; The briefing: picture, three graphics, the mission text, then the zones with
; the map blit
;
; The shadow screen, ShowBriefingMapOnce armed (`$7084` = 0), the Dragonfly's
; title hook `$6C56` = `RET`, the arrow pointer, SetBriefingBlit `$DBAA`,
; CopyMissionText, DrawBank7Picture `$E949`, BriefingBoxes, BriefingGraphicA-C,
; PrintString (`$70A3`), the map blit (`$83E6` = BlitMapView `$DBBD`),
; PointerZones until the view flag; then the 3D blit back (`$8999`) and
; NextView. Witness: L1 10 (menu).
BriefingScreen:
  CALL $7268
  XOR A
  LD ($83BF),A
  LD ($7084),A
  LD A,$C9
  LD ($6C56),A
  LD HL,PointerShapes
  LD (ShiftPointer+$0001),HL
  CALL SetBriefingBlit
  CALL $70F6
  LD DE,TitleGraphicB+$0005
  CALL $74AA
  LD HL,BriefingBoxes
  CALL $6CFB
  LD HL,BriefingBoxB
  CALL $6CFB
  LD HL,BriefingGraphicA
  LD D,$07
  LD C,$10
  EXX
  LD C,$00
  LD A,$18
  CALL $6D7F
  LD HL,BriefingGraphicB
  LD D,$07
  LD C,$10
  EXX
  LD C,$00
  LD A,$50
  CALL $6D7F
  LD HL,BriefingGraphicC
  LD D,$07
  LD C,$10
  EXX
  LD C,$00
  LD A,$60
  CALL $6D7F
  LD HL,($70A3)
  CALL $6FB3
  CALL SavePointerBackground
  LD A,$FF
  LD ($83BF),A
  CALL $725F
  LD HL,BlitMapView
  LD ($83E6),HL
BriefingLoop:
  CALL $6D42
  LD A,($6A6D)
  AND A
  JR Z,BriefingLoop
  CALL ShowWaitPointer
  LD HL,$8999
  LD ($83E6),HL
  JP $6A91

; Zone table of the briefing
;
; `$709E` (BriefingTextOnce), ShowBriefingMapOnce `$7084` (the map), ScreenZero
; (back).
BriefingZones:
  DEFB $03,$34,$52,$5B,$9E,$70
  DEFB $03,$34,$1A,$24,$84,$70
  DEFB $03,$34,$63,$6D,$5A,$70
  DEFB $00

; CopyMissionText $70F6 called from bank 6
;
; Called by LoadMissionIfAllowed `$759A`. Witness: L1 15 (c1, death, m2erbe,
; missions, play, play2).
CopyMissionTextB6:
  CALL $70F6
  RET

; Unused: an older copy of the mission's texts from the back buffer to $F9C4
;
; Known only from the code: nothing calls it. Once per mission (the operand
; `$CA2E`), from the catalogue's copy at `$8AF1`; sets `$70A3`, `$7D3C`,
; `$7D39`, `$7C55` and calls `$7D35`.
CopyMissionTextOld:
  LD A,($757D)
  LD HL,CopyMissionTextOld+$0007
  LD C,$FF
  CP C
  CP (HL)
  RET Z
  LD (CopyMissionTextOld+$0007),A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD H,$00
  LD L,A
  ADD HL,HL
  LD DE,$8AF1
  ADD HL,DE
  LD D,$00
  LD E,$1B
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD C,(HL)
  INC HL
  LD B,$00
  PUSH DE
  PUSH BC
  LD HL,$8AF1
  LD B,H
  LD C,L
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD ($70A3),HL
  PUSH HL
  PUSH DE
  EX DE,HL
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD ($7D3C),HL
  DEC HL
  DEC HL
  ADD HL,BC
  LD ($7D39),HL
  LD DE,Bank6FillB+$0001
  POP BC
  POP HL
  LDIR
  LD HL,Bank6FillB+$0001
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD ($70A3),HL
  ADD HL,BC
  LD ($7C55),HL
  CALL $7D35
  RET

; The attribute box of the stores screen
;
; Read by StoresScreen `$CB1C`.
StoresTitleBox:
  DEFB $47,$02,$12,$0C,$16
