; --------------------------------------------------------------------------------------------------------------------
; screen.asm: Screen helpers: the sides, the high-score table, the title colours
; --------------------------------------------------------------------------------------------------------------------

; Paint column 0 and column 31 of the 24 attribute rows with C (0: black)
;
; Witness: L1 66 (boss, c1, continue, ctl-if2, ctl-kempston, ctl-sinclair,
; deaths-l7, gameover, hiscore, hiscore-typed, restart, l1-l8).
ClearSides:
  LD HL,$5800
  LD DE,$001F
  LD BC,$1800
l_7689:
  LD (HL),C
  ADD HL,DE
  LD (HL),C
  INC HL
  DJNZ l_7689
  RET

; Clear the screen and show the high-score table
;
; ClearScreen, the black sides, the title colour task (task 4) on, then
; PrintHiScores.
;
; Witness: L1 9 (c1, gameover, hiscore, hiscore-typed).
ShowHiScores:
  CALL ClearScreen
  CALL ClearSides
  LD A,$01
  LD (TaskTable+$0016),A

; Print "TODAY'S BEST PILOTS" and the nine entries of HiScoreTable
;
; Each entry: its place digit (DigitChars), the name and the score, double
; height, from row 3 down.
;
; Witness: L1 1309 (c1, gameover, hiscore, hiscore-typed).
PrintHiScores:
  LD HL,BestPilotsText
  LD BC,$0006
  CALL PrintText
  LD BC,$0304
  LD HL,HiScoreTable
  LD DE,DigitChars
l_76AD:
  PUSH DE
  PUSH BC
  PUSH HL
  PUSH DE
  LD HL,NoText
  CALL PrintText
  POP HL
  CALL PrintText
  POP HL
  INC C
  CALL PrintText
  POP BC
  POP DE
  INC DE
  INC B
  INC B
  LD A,B
  CP $15
  JR C,l_76AD
  RET

; Interrupt task 4: step the screen's colours through the INKs on a black paper
;
; Paints the top attribute rows with the next colour and copies them down the
; screen: the whole screen follows.
;
; Witness: L1 807 (c1, ctl-if2, ctl-kempston, ctl-sinclair, ending, gameover,
; hiscore, hiscore-typed, l1-l7).
CycleTitleColour:
  LD HL,$5800
  PUSH HL
  LD BC,$0020
  PUSH BC
  INC L
  LD A,$47
  CALL FillBlock
  POP BC
  LD A,(FrameCounter)
  INC A
  AND $07
  JR NZ,l_76E3
  INC A
l_76E3:
  LD (FrameCounter),A
  ADD A,$40
  CALL FillBlock
  POP HL
  LD DE,$5840
  LD BC,$02C0
  LDIR
  RET

; "REWIND TAPE"
RewindTapeText:
  INCBIN "res/texts/rewind-tape.bin",$0000,11

; The pixel shadow, third third, pixel line 6
ShadowLine6:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; Six keys as (half-row port high byte, bit mask), DefineKeys / ReadKeys
;
; As loaded: $FB/1 Q, $FB/2 W, $DF/2 O, $BF/4 K, $DF/1 P, $7F/1 SPACE.
DefinedKeys:
  INCBIN "res/tables/defined-keys.bin",$0000,12

; The four control readers by ControlMethod: ReadIf2, ReadKeys, ReadKempston,
; ReadSinclair
ControlVectors:
  DEFW ReadIf2
  DEFW ReadKeys
  DEFW ReadKempston
  DEFW ReadSinclair

; the joystick methods' detach key: port $7F, bit 0 (SPACE)
DetachKey:
  DEFB $7F,$01

; The title: logo, texts and the high-score table in turn until a fire picks
; the control method
;
; Stars off, the play state cleared, TitleLogo, the title lines; DefineKeys
; while the title waits (ENTER defines keys); then the high-score table,
; polling SelectControl; round again. SelectControl leaves the loop through the
; stack with the method chosen.
;
; The two waits take C from the code before them: $0400 = 1024 turns (C = 0
; from FillBlock), then $5404 = 21 508 SelectControl polls (C = 4 from
; ShowHiScores).
;
; Witness: L1 8 (c1, gameover, hiscore).
TitleLoop:
  CALL StarsOff
  CALL ClearPlayState
  LD A,$02
  LD (FrameCounter),A
  CALL CycleTitleColour
  CALL TitleLogo
  LD BC,$030A
  LD HL,TitleTexts
  CALL PrintTextNormal
  LD BC,$040A
  CALL PrintTextNormal
  LD BC,$070A
  CALL PrintTextNormal
  LD BC,$0A0A
  CALL PrintTextNormal
  LD BC,$140B
  CALL PrintTextNormal
  LD HL,PlayAttrs+$00E0
  LD BC,$0020
  LD A,$43
  CALL FillBlock
  LD B,$04
l_77D5:
  PUSH BC
  CALL DefineKeys
  CALL StarTask
  LD HL,PlayAttrs
  LD DE,$5800
  LD BC,$0280
  LDIR
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,l_77D5
  CALL ShowHiScores
  LD B,$54
l_77F2:
  PUSH BC
  CALL SelectControl
  POP BC
  DEC BC
  LD A,B
  OR C
  JR NZ,l_77F2
  JP TitleLoop

; a byte no recording reads (known only from the heatmap)
Unused77FF:
  DEFB $00

; The play field's attribute shadow: 20 rows of 32 attributes
;
; Written by the scroll and the sprite drawers.
PlayAttrs:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
