; --------------------------------------------------------------------------------------------------------------------
; results.asm: The end of a mission, the mission status card and the score
;
; When a mission ends, the screen list runs MissionCompleteScreen $CD1E (node $755E) or MissionFailedScreen $CD84
; (node $7564); both unpack PicCompletion ($E51E of bank 7). The completed one adds the mission's score ($68E2-$68E5)
; to Score $CC79, sets the mission's completion flag and prints the mission's own completion text (at $7C55); the
; failed one prints "MISSION FAILED." and the reason (at $7BF9). MissionStatusScreen $CDBF (node $756A) shows the
; commander's card with the missions completed and the score.
; --------------------------------------------------------------------------------------------------------------------

  ORG $CC54

; Unused: the mission's score as ten digits into $D461, then FinalScoreText
;
; Known only from the code: nothing calls it.
PrintFinalScore:
  LD HL,($68E2)
  EXX
  LD HL,($68E4)
  LD DE,FinalScoreDigits
  CALL LongToDigits
  CALL DotLeadingZeros
  LD HL,FinalScoreText
  JP $6FB3

; Replace the leading "0" of the nine digits at $D49A with "[" (a full stop in
; SmallFont $7C59)
;
; Witness: L1 4 (m10, menu, missions).
DotLeadingZeros:
  LD HL,ScoreDigits
  LD B,$09
BlankScoreLoop:
  LD A,(HL)
  CP $30
  RET NZ
  LD (HL),$5B
  INC HL
  DJNZ BlankScoreLoop
  RET

; The 32-bit score of the missions completed
;
; Added to by MissionCompleteScreen, set from a password by PasswordScreen,
; printed by PrintScore, coded by EncodePassword.
Score:
  DEFB $00,$00,$00,$00

; Print the missions completed and the score (StatusText $D46C)
;
; LongToDigits `$D353` of Score into `$D49A`, DotLeadingZeros, PrintString
; `$D46C`. Witness: L1 4 (m10, menu, missions).
PrintScore:
  LD HL,(Score)
  EXX
  LD HL,(Score+$0002)
  LD DE,ScoreDigits
  CALL LongToDigits
  CALL DotLeadingZeros
  LD HL,StatusText
  JP $6FB3

; The number of missions completed
;
; Counted by PasswordScreen and MissionCompleteScreen, printed through code 8
; of StatusText.
MissionsCompleted:
  DEFB $00

; Texts: "MISSION FAILED." and the five reasons
;
; `$CC94` printed by MissionFailedScreen; the reason (the pointer `$7BF9`, set
; by the play code) is one of the five.
FailedTexts:
  DEFB $09,$07,$02,$20,$09,$0D,$68,$4D,$49,$53,$53,$49,$4F,$4E,$20,$46
  DEFB $41,$49,$4C,$45,$44,$2E,$FF
UnitDestroyedText:
  DEFB $07,$30,$0E,$55,$4E,$49,$54,$3A,$44,$45,$53,$54,$52,$4F,$59,$45
  DEFB $44,$5B,$FF
NoPickupText:
  DEFB $07,$30,$0B,$46,$41,$49,$4C,$45,$44,$3A,$54,$4F,$3A,$4D,$41,$4B
  DEFB $45,$3A,$50,$49,$43,$4B,$55,$50,$5B,$FF
DesertionText:
  DEFB $07,$30,$0E,$50,$4C,$41,$59,$45,$52,$3A,$44,$45,$53,$45,$52,$54
  DEFB $49,$4F,$4E,$5B,$FF
OutOfFuelText:
  DEFB $07,$30,$0E,$52,$41,$4E,$3A,$4F,$55,$54,$3A,$4F,$46,$3A,$46,$55
  DEFB $45,$4C,$5B,$FF
BridgeText:
  DEFB $07,$30,$09,$54,$41,$4E,$4B,$3A,$44,$45,$53,$54,$52,$4F,$59,$45
  DEFB $44,$3A,$4F,$4E,$3A,$42,$52,$49,$44,$47,$45,$5B,$FF

; Mission completed: PicCompletion, the score added, the flag set, the
; mission's text
;
; Sound off, DrawBank7Picture `$E51E`, Score += the mission's score,
; MissionsDone[mission] = `$FF`, PrintString (`$7C55`), SaveLoadedMission
; `$CD77`, the main screen, Delay, MissionsCompleted + 1, then the key wait of
; MissionFailedScreen (EndScreenKey). Known only from the code: no recording
; runs it on page 6 (bank 7 has c1 unpacking PicCompletion).
MissionCompleteScreen:
  CALL $7268
  LD DE,MapModelNegative
  CALL $74AA
  CALL $72DE
  LD HL,($68E2)
  LD DE,(Score)
  ADD HL,DE
  LD (Score),HL
  LD HL,($68E4)
  LD DE,(Score+$0002)
  ADC HL,DE
  LD (Score+$0002),HL
  LD A,($757D)
  LD HL,$6799
  LD E,A
  LD D,$00
  ADD HL,DE
  LD (HL),$FF
  LD HL,($7C55)
  CALL $6FB3
  CALL SaveLoadedMission
  CALL $725F
  CALL Delay
  LD HL,MissionsCompleted
  INC (HL)
  JP EndScreenKey

; A delay of five times 65535 loops
;
; Witness: L1 36 (c1, death, m10, m2erbe, m2ocean, menu, missions, play, play2,
; search).
Delay:
  LD B,$05
DelayOuter:
  LD HL,$FFFF
DelayInner:
  DEC HL
  LD A,H
  OR L
  JR NZ,DelayInner
  DJNZ DelayOuter
  RET

; Zone table of the two mission end screens
;
; ScreenZero.
EndZones:
  DEFB $9B,$E3,$33,$4C,$5A,$70
  DEFB $00

; Put LoadedMission's two bytes ($7E2C) into the mission's header ($70A3 +1 and
; +3)
;
; Witness: L1 13 (m2erbe, missions, play, play2).
SaveLoadedMission:
  LD DE,($7E2C)
  LD HL,($70A3)
  INC HL
  LD (HL),E
  INC HL
  INC HL
  LD (HL),D
  RET

; Mission failed: PicCompletion, "MISSION FAILED." and the reason, then a key
;
; Known only from the code: no recording runs it on page 6.
;
; Seen in work/stage2/rec/fuel (a POKE recording, never the image: Fuel `$7C57`
; = 32 at frame 7704): the failure reason `$7BF9` = `$ED` by frame 7904,
; MissionFailedScreen at frame 7862 shows PicCompletion with "MISSION FAILED."
; / "RAN OUT OF FUEL.", SaveLoadedMission `$CD77` at 7892, then the title
; (SetTitleWindow `$D10E`, the music from Bank4Start) at 8051: a failure ends
; at the title, there are no lives.
MissionFailedScreen:
  CALL $7268
  LD DE,MapModelNegative
  CALL $74AA
  CALL $72DE
  LD HL,FailedTexts
  CALL $6FB3
  LD HL,($7BF9)
  CALL $6FB3
  CALL SaveLoadedMission
  CALL $725F
  CALL Delay
; This entry point is used by the routine at MissionCompleteScreen.
EndScreenKey:
  CALL $7E7A
EndKeyLoop:
  LD A,($8978)
  AND $02
  JR Z,EndKeyLoop
  CALL $705A
  JP $6A91

; Two attribute box records of the mission status card
;
; Read by MissionStatusScreen `$CDE6` and `$CDEC`.
StatusBoxes:
  DEFB $47,$02,$13,$0B,$03
StatusBoxB:
  DEFB $47,$04,$13,$0A,$06

; The mission status card: PicMissionStatus, two graphics, the score, then the
; zones
;
; DrawBank7Picture `$EC82`, StatusGraphicB (11 x 16), StatusGraphicA (10 x 32),
; the boxes, PrintScore, the pointer, PointerZones (StatusScreenZones) until
; the view flag, ShowWaitPointer, NextView. Witness: L1 4 (m10, menu,
; missions).
MissionStatusScreen:
  CALL $7268
  LD DE,StatusGraphicB+$007E
  CALL $74AA
  LD HL,StatusGraphicB
  LD D,$0B
  LD C,$10
  EXX
  LD C,$13
  LD A,$18
  CALL $6D7F
  LD HL,StatusGraphicA
  LD D,$0A
  LD C,$20
  EXX
  LD C,$13
  LD A,$30
  CALL $6D7F
  LD HL,StatusBoxes
  CALL $6CFB
  LD HL,StatusBoxB
  CALL $6CFB
  CALL PrintScore
  CALL SavePointerBackground
  CALL $725F
  LD A,$FF
  LD ($83BF),A
StatusCardLoop:
  CALL $6D42
  LD A,($6A6D)
  AND A
  JR Z,StatusCardLoop
  CALL ShowWaitPointer
  CALL $7E7A
  JP $6A91

; A zone table no routine reads: ScreenZero and ScreenTwo
;
; Known only from the code.
SpareZones:
  DEFB $07,$4E,$A7,$AE,$5A,$70
  DEFB $6E,$F6,$A7,$AE,$5E,$70
  DEFB $00

; Write 0-23 into the byte before each 60-byte record from $762B
;
; Called by StoresScreen after the object table is cleared. Witness: L1 15 (c1,
; death, m2erbe, missions, play, play2).
NumberObjectRecords:
  LD HL,$762B
  LD DE,$003C
  LD B,$18
  XOR A
NumberObjectsLoop:
  LD (HL),A
  ADD HL,DE
  INC A
  DJNZ NumberObjectsLoop
  RET
