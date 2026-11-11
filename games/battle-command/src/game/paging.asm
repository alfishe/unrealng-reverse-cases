; --------------------------------------------------------------------------------------------------------------------
; paging.asm: The paging routines: one entry per bank, the page kept in $728A
; --------------------------------------------------------------------------------------------------------------------

  ORG $7225

; Wait until the interrupt clears $83BA (the 3D frame's blit is done)
;
; Witness: L1 3076073 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
WaitFrameDone:
  LD A,(BlitRequest+$0001)
  AND A
  JR NZ,WaitFrameDone
  RET

; The briefing map's legend: wait for the frame, the attribute boxes $DB01 and
; $DB0B, the text $DAE1 ("Roads." / "Rivers."); called by bank 6 BriefingMap
; $DB64
;
; Witness: L1 10 (menu).
BriefingMapLegend:
  CALL WaitFrameDone
  LD HL,HelicarrierInit+$0001
  CALL AttrBox
  LD HL,l_DB05+$0006
  CALL AttrBox
  LD HL,HelicarrierDescent+$0003
  JP PrintString

; The status view map's legend: wait for the frame, the boxes $DB10 and $DAC1,
; the text $DAA1; called by bank 6 StatusMap $DB15
;
; Witness: L1 40 (m2erbe, missions, play).
StatusMapLegend:
  CALL WaitFrameDone
  LD HL,l_DB0C+$0004
  CALL AttrBox
  LD HL,HelicarrierTemplate+$0015
  CALL PrintString
  LD HL,HelicarrierHit+$0016
  CALL AttrBox

; A NOP the first time: WaitFrameDone, then patched to RET
;
; Witness: L1 13555 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
FirstFrameHook:
  NOP
  CALL WaitFrameDone
  LD A,$C9
  LD (FirstFrameHook),A

; A = 0 then PageMain
;
; Witness: L1 9925 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe,
; m2ocean, m4complete, menu, missions, play, play2, search).
PageBank0Main:
  XOR A

; Set the screen bit ($7284, the OR operand) to A and re-page the current bank
;
; Witness: L1 10090 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
PageMain:
  LD (PageOut+$0004),A
  LD A,(SaveBank+$0002)
  JR PageOut

; A = 8 (the shadow screen bit of $7FFD) then PageMain
;
; Witness: L1 165 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe,
; m2ocean, m4complete, menu, missions, play, play2, search).
PageShadowScreen:
  LD A,$08
  JR PageMain

; Page bank 3 at $C000
;
; Witness: L1 266011 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
PageBank3:
  LD A,$03
  JR PageBankA

; Page bank 4 at $C000
;
; Witness: L1 135412 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
PageBank4:
  LD A,$04
  JR PageBankA

; Page bank 7 at $C000
;
; Witness: L1 142 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe,
; m2ocean, m4complete, menu, missions, play, play2, search).
PageBank7:
  LD A,$07
  JR PageBankA

; Page bank 6 at $C000
;
; Witness: L1 336465 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
PageBank6:
  LD A,$06
  JR PageBankA

; Page bank 0 at $C000
;
; Witness: L1 263276 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
PageBank0:
  XOR A

; Page bank A: kept in $728A, OR the screen bit, OUT to $7FFD
;
; Witness: L1 1454779 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
PageBankA:
  LD (SaveBank+$0002),A

; PageOut
;
; Used by the routine at PageMain.
PageOut:
  LD BC,$7FFD
  OR $00
  OUT (C),A
  RET

; Keep the current bank ($728A) in the operand $729D of RestoreBank
;
; Witness: L1 134817 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
SaveBank:
  PUSH AF
  LD A,$00
  LD (RestoreBank+$0002),A
  POP AF
  RET

; Save the bank, call bank 3 $C4C4 with A, restore
;
; Witness: L1 94721 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
Bank3SetObject:
  CALL SaveBank
  PUSH AF
  CALL PageBank3
  POP AF
  CALL FillPolygon

; Page the bank SaveBank kept (A and the flags kept)
;
; Witness: L1 134816 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
RestoreBank:
  PUSH AF
  LD A,$00
  CALL PageBankA
  POP AF
  RET

; Save the bank, call bank 3 $D08C and $D1EC, restore
;
; Witness: L1 9770 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; missions, play, play2).
Bank3Step:
  CALL SaveBank
  CALL PageBank3
  CALL DrawDebris
  CALL MoveAllDebris
  JR RestoreBank

; Save the bank, call bank 3 $C9A7 with A, restore
;
; Witness: L1 18311 (armour, c1, death, fuel, m1complete, m2erbe, m4complete,
; menu, missions, play, play2).
Bank3Lookup:
  CALL SaveBank
  PUSH AF
  CALL PageBank3
  POP AF
  CALL DrawLine
  JR RestoreBank

; Page bank 3, run the 3D frame driver $990F, page bank 6
;
; Witness: L1 3712 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe,
; m2ocean, m4complete, menu, missions, play, play2, search).
Bank3Render:
  CALL PageBank3
  CALL RunScript
  JR PageBank6

; Save the bank, call bank 4 $C000 with A = 0, restore
;
; Witness: L1 22 (c1, controls, fuel, m2erbe, menu, missions, play, play2).
Bank4Start:
  CALL SaveBank
  CALL PageBank4
  XOR A
  CALL StartTune
  JR RestoreBank

; The interrupt's call of bank 4 $C0D2, the bank kept and restored
;
; Witness: L1 135242 (armour, c1, controls, death, fuel, m10, m1complete,
; m2erbe, m2ocean, m4complete, menu, missions, play, play2, search).
Bank4Tick:
  CALL PageBank6Kept
  CALL PageBank4
  CALL MusicTick
  JP PageBankKept

; Save the bank, call bank 0 $D807 (the sound off), restore
;
; Witness: L1 26 (armour, c1, controls, fuel, m1complete, m2erbe, m4complete,
; menu, missions, play, play2).
Bank0SoundOff:
  CALL SaveBank
  CALL PageBank0
  CALL SilenceAY
  JR RestoreBank

; Save the bank, call bank 4 $C1A2, restore
;
; Witness: L1 32 (armour, c1, controls, death, fuel, m10, m1complete, m2erbe,
; m2ocean, menu, missions, play, play2, search).
Bank4Call:
  CALL SaveBank
  CALL PageBank4
  CALL StopMusic
  JR RestoreBank
