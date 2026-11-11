; --------------------------------------------------------------------------------------------------------------------
; screens.asm: The menu screens: the screen list, the screen switch, the help lines
;
; The menus are a list of screens (ScreenList $74E6): each screen is a pair of words, the routine that draws it and
; its pointer zone table. SetScreen $7060 takes the Nth pair (E = 2N): the routine goes to the loop's return address
; ($6A99) and the zone table to PointerZones; the view flag ends the current loop.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7040

; Remember key A, screen 2 (E = 4); the mission code's vector $67EE
;
; Witness: L1 9 (missions, play, play2).
ScreenFour:
  LD (PlayKeys+$000A),A
  LD E,$04
  JR SetScreen

; Remember key A, screen 3 (E = 6)
;
; Witness: known only from the code.
ScreenSix:
  LD (PlayKeys+$000A),A
  LD E,$06
  JR SetScreen

; Remember key A, screen 4 (E = 8)
;
; Witness: L1 14 (missions, play, play2).
ScreenEight:
  LD (PlayKeys+$000A),A
  LD E,$08
  JR SetScreen

; Key "C", screen 0
;
; Witness: L1 15 (menu, missions, play, play2).
ScreenFromClick:
  LD A,$43
  LD (PlayKeys+$000A),A

; Screen 0 (E = 0)
;
; Witness: L1 91 (c1, death, m2erbe, menu, missions, play, play2, search).
ScreenZero:
  LD E,$00
  JR SetScreen

; Screen 1 (E = 2)
;
; Witness: L1 12 (menu, missions, play2).
ScreenTwo:
  LD E,$02

; Switch to entry E/2 of the screen list: the draw routine to $6A99, the zone
; table to $6D47
;
; Witness: L1 121 (c1, death, m2erbe, menu, missions, play, play2, search).
SetScreen:
  LD HL,(ScreenList)
  LD D,$00
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  EX DE,HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (NextView+$0008),DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD (PointerZones+$0005),DE
  LD (ScreenList),HL

; $6A6D = $FF: the current loop ends
;
; Witness: L1 10 (play, play2).
SetViewFlag:
  LD A,$FF
  LD (ViewChangeFlag+$0001),A
  RET

; Once: the briefing map (bank 6's BriefingMapFrame $DACB and BriefingMap
; $DB64), then patched to RET
;
; Witness: L1 10 (menu, play, play2).
ShowBriefingMapOnce:
  NOP
  CALL SaveBank
  CALL PageBank6
  CALL BriefingMapFrame
  CALL BriefingMap
  CALL RestoreBank
  LD A,$C9
  LD (ShowBriefingMapOnce),A
  XOR A
  LD (BriefingTextOnce),A
  RET

; BriefingTextOnce
BriefingTextOnce:
  DEFB $00,$CD,$96,$C0,$21,$00,$00,$CD ; the briefing's TEXT button: the text
  DEFB $B3,$6F,$21,$B6,$C0,$CD,$FB,$6C ; at ($70A3), once
  DEFB $AF,$32,$84,$70,$3E,$C9,$18,$E4

; Once: bank 6's $C079, the title string at ($70A3), the attribute box $C0BB
;
; Witness: L1 1 (play).
DragonflyTitle:
  NOP
  CALL DragonflyTitleBox
  LD HL,(BriefingTextOnce+$0005)
  CALL PrintString
  LD HL,RadarAddBlip+$0009
  JP AttrBox
