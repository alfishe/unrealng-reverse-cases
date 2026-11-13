; --------------------------------------------------------------------------------------------------------------------
; leftovers.asm: Code and texts of an earlier build that nothing calls or reads
;
; Seven pieces of code and two blocks of bytes lie between the front's routines with no caller: no CALL, JP, JR or
; table of the resident or the block names them, and neither recording executes or reads them (c1, menu). Some call
; the front's routines the way the final code does (FillAttrBox $9D31 with five bytes after the CALL), others the old
; way (OldRevealPage $9CCF calls PrintText $9D72 with HL and A, where the final PrintText reads its parameters after
; the CALL): they are what an earlier version of the front left. Their names say what the code would do if it ran.
; --------------------------------------------------------------------------------------------------------------------

  ORG $94DB

; Clear the screen, then B attribute rows of C, every second row (no caller)
;
; In: B = rows, C = attribute, DE = pushed and popped into BC. Patches the
; height of the FillAttrBox $9D31 parameters after the CALL at $94E7 (column 0,
; row 0, 32 wide, height B, $42) and the LD A,n at $94FB with C, clears the
; screen (ClearScreen $9EBC), fills the box, then fills 32 attribute bytes with
; C on every second row from $5800, B times. No caller; not executed in any
; recording (c1, menu).
;
; Witness: L1 0 ().
OldStripedScreen:
  LD A,B
  LD (OldStripedScreen+$0013),A
  LD A,C
  LD (OldStripedRow+$0009),A
  PUSH DE
  CALL ClearScreen
  CALL FillAttrBox
  DEFB $00,$00,$20,$18,$42
  POP BC
  LD HL,Attributes
OldStripedRow:
  PUSH BC                 ; one attribute row of C (the LD A,n patched at
                          ; $94FB)
  PUSH HL
  PUSH HL
  POP DE
  INC DE
  LD BC,$001F
  LD A,$27
  LD (HL),A
  LDIR
  POP HL
  LD BC,$0040
  ADD HL,BC
  POP BC
  DJNZ OldStripedRow
  RET

  ORG $980B

; Five attribute boxes: one 16 x 18 of $44, four 16 x 1 of $45 on rows 11, 13,
; 15, 17 (no caller)
;
; Five FillAttrBox $9D31 calls (column 8, row 6, 16 x 18 cells of $44; then
; column 8, rows 11, 13, 15, 17, 16 x 1 of $45) and RET: an earlier layout of
; the menu box. No caller; not executed in any recording (c1, menu).
;
; Witness: L1 0 ().
OldPaintBoxes:
  CALL FillAttrBox
  DEFB $08,$06,$10,$12,$44
  CALL FillAttrBox
  DEFB $08,$0B,$10,$01,$45
  CALL FillAttrBox
  DEFB $08,$0D,$10,$01,$45
  CALL FillAttrBox
  DEFB $08,$0F,$10,$01,$45
  CALL FillAttrBox
  DEFB $08,$11,$10,$01,$45
  RET

  ORG $9A94

; Paint two boxes, and five one-cell bars that move along a row and bounce (no
; caller)
;
; Two FillAttrBox $9D31 calls (the second's row patched from OldBarVars+2 AND
; $F0), then, when the high nibbles of OldBarVars+2 and +3 differ, the five
; bars' columns (15-19) and steps (-1) are set in OldBarVars+4 to +13 and it
; returns; otherwise the five bars (attributes $41, 2, $42, 3, $43, each 1 x 2
; cells) are painted on the attribute row OldBarVars+3 AND $F0 and each bar
; moves by its step, the step negated when the two screen bytes there are both
; 0. No caller; not executed in any recording (c1, menu).
;
; Witness: L1 0 ().
OldBouncingBars:
  CALL FillAttrBox
  DEFB $08,$78,$0E,$09,$04
  LD A,(OldBarVars+$0002)
  AND $F0
  LD (OldBouncingBars+$0014),A
  CALL FillAttrBox
  DEFB $08,$00,$0E,$02,$06
  LD A,(OldBarVars+$0003)
  AND $F0
  LD L,A
  LD A,(OldBarVars+$0002)
  AND $F0
  CP L
  JP Z,OldBarsPaint
  LD A,$0F
  LD (OldBarVars+$0004),A
  INC A
  LD (OldBarVars+$0006),A
  INC A
  LD (OldBarVars+$0008),A
  INC A
  LD (OldBarVars+$000A),A
  INC A
  LD (OldBarVars+$000C),A
  LD A,$FF
  LD (OldBarVars+$0005),A
  LD (OldBarVars+$0007),A
  LD (OldBarVars+$0009),A
  LD (OldBarVars+$000B),A
  LD (OldBarVars+$000D),A
  RET
OldBarsPaint:
  LD A,(OldBarVars+$0003) ; the bars painted
  AND $F0
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,Attributes
  ADD HL,BC
  LD E,L
  PUSH HL
  LD A,(OldBarVars+$0004)
  ADD A,E
  LD L,A
  LD (HL),$41
  LD BC,$0020
  ADD HL,BC
  LD (HL),$41
  POP HL
  PUSH HL
  LD A,(OldBarVars+$0006)
  ADD A,E
  LD L,A
  LD (HL),$02
  LD BC,$0020
  ADD HL,BC
  LD (HL),$02
  POP HL
  PUSH HL
  LD A,(OldBarVars+$0008)
  ADD A,E
  LD L,A
  LD (HL),$42
  LD BC,$0020
  ADD HL,BC
  LD (HL),$42
  POP HL
  PUSH HL
  LD A,(OldBarVars+$000A)
  ADD A,E
  LD L,A
  LD (HL),$03
  LD BC,$0020
  ADD HL,BC
  LD (HL),$03
  POP HL
  PUSH HL
  LD A,(OldBarVars+$000C)
  ADD A,E
  LD L,A
  LD (HL),$43
  LD BC,$0020
  ADD HL,BC
  LD (HL),$43
  POP HL
OldBarsMove:
  LD IX,OldBarVars+$0004  ; the bars moved
  LD B,$05
OldBarsNext:
  PUSH BC                 ; one bar
OldBarsStep:
  LD A,(IX+$00)           ; move it; bounce off a set screen byte
  ADD A,(IX+$01)
  LD (IX+$00),A
  LD A,(OldBarVars+$0002)
  AND $F0
  OR $03
  LD L,A
  CALL OldLineAddress
  LD A,(IY+$00)
  ADD A,(IX+$00)
  LD L,A
  LD H,(IY+$01)
  LD A,(HL)
  CP $00
  JP NZ,OldBarsDone
  INC HL
  LD A,(HL)
  CP $00
  JP NZ,OldBarsDone
  LD A,(IX+$01)
  NEG
  LD (IX+$01),A
  JP OldBarsStep
OldBarsDone:
  INC IX                  ; the next bar
  INC IX
  POP BC
  DJNZ OldBarsNext
  RET

; IY = ScreenLineTable + 2L (the entry of pixel line L) (no caller but
; OldBouncingBars)
;
; Called only from OldBouncingBars at $9B54. Not executed in any recording.
;
; Witness: L1 0 ().
OldLineAddress:
  LD DE,ScreenLineTable
  LD H,$00
  ADD HL,HL
  ADD HL,DE
  PUSH HL
  POP IY
  RET

; Wait BC frames; SPACE or the FIRE reader drops the caller's return (no
; caller)
;
; The earlier WaitOrSpace: one HALT a count, SPACE (ReadSpace $9D29) or KeyFire
; $FCCC (Z) ends it the way WaitOrSpace $9BA5 does. No caller; not executed in
; any recording.
;
; Witness: L1 0 ().
OldWaitSpaceOrFire:
  HALT
  PUSH BC
  CALL ReadSpace
  JP Z,OldWaitAbort
  CALL KeyFire
  JP Z,OldWaitAbort
  POP BC
  DEC BC
  LD A,B
  OR C
  JP NZ,OldWaitSpaceOrFire
  RET
OldWaitAbort:
  POP BC                  ; SPACE or FIRE: drop the caller's return
  POP HL
  RET

  ORG $9BC7

; Reveal 10 pixel lines from line C x 8, 24 bytes from column 4, from $5B00 in
; 8 dissolve steps (no caller but OldRevealPage)
;
; The earlier reveal: C = the character row; for 8 steps (HALT each) and 10
; lines, 24 bytes from column 4 merged from $5B00 under the masks $F9CB on, the
; mask set cycling 0-4 (byte $FE12 as its counter). Called only from
; OldRevealPage $9CCF. Not executed in any recording.
;
; Witness: L1 0 ().
OldRevealWide10:
  LD A,C
  LD (OldRevealStep10+$0005),A
  LD B,$08
  LD IX,$F9CB
OldRevealStep10:
  PUSH BC                 ; one step (HALT)
  PUSH IX
  HALT
  LD E,$00
  SLA E
  SLA E
  SLA E
  LD D,$00
  LD IY,ScreenLineTable
  ADD IY,DE
  ADD IY,DE
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD BC,$0004
  ADD HL,BC
  LD DE,TextBuffer
  LD A,$00
  LD ($FE12),A
  PUSH IY
  LD B,$0A
OldRevealLine10:
  PUSH BC                 ; one pixel line
  LD A,(IY+$00)
  ADD A,$04
  LD L,A
  LD H,(IY+$01)
  INC IY
  INC IY
  LD B,$18
OldRevealByte10:
  PUSH BC                 ; one byte, the mask set cycling
  PUSH IX
  LD A,($FE12)
  INC A
  CP $05
  JP NZ,OldRevealMaskSet10
  LD A,$00
OldRevealMaskSet10:
  LD ($FE12),A            ; the mask set counter wrapped
  SLA A
  SLA A
  SLA A
  LD C,A
  LD B,$00
  ADD IX,BC
  LD B,(IX+$00)
  LD A,(DE)
  AND B
  LD C,A
  LD A,B
  XOR $FF
  LD B,A
  LD A,(HL)
  AND B
  OR C
  LD (HL),A
  INC DE
  INC HL
  POP IX
  POP BC
  DJNZ OldRevealByte10
  POP BC
  DJNZ OldRevealLine10
  POP IY
  POP IX
  POP BC
  INC IX
  DJNZ OldRevealStep10
  RET

; The same over 26 pixel lines (no caller but OldRevealPage2)
;
; Called only from OldRevealPage2 $9CF4. Not executed in any recording.
;
; Witness: L1 0 ().
OldRevealWide26:
  LD A,C
  LD (OldRevealStep26+$0005),A
  LD B,$08
  LD IX,$F9CB
OldRevealStep26:
  PUSH BC                 ; one step (HALT)
  PUSH IX
  HALT
  LD E,$00
  SLA E
  SLA E
  SLA E
  LD D,$00
  LD IY,ScreenLineTable
  ADD IY,DE
  ADD IY,DE
  LD L,(IY+$00)
  LD H,(IY+$01)
  LD BC,$0004
  ADD HL,BC
  LD DE,TextBuffer
  LD A,$00
  LD ($FE12),A
  PUSH IY
  LD B,$1A
OldRevealLine26:
  PUSH BC                 ; one pixel line
  LD A,(IY+$00)
  ADD A,$04
  LD L,A
  LD H,(IY+$01)
  INC IY
  INC IY
  LD B,$18
OldRevealByte26:
  PUSH BC                 ; one byte, the mask set cycling
  PUSH IX
  LD A,($FE12)
  INC A
  CP $05
  JP NZ,OldRevealMaskSet26
  LD A,$00
OldRevealMaskSet26:
  LD ($FE12),A            ; the mask set counter wrapped
  SLA A
  SLA A
  SLA A
  LD C,A
  LD B,$00
  ADD IX,BC
  LD B,(IX+$00)
  LD A,(DE)
  AND B
  LD C,A
  LD A,B
  XOR $FF
  LD B,A
  LD A,(HL)
  AND B
  OR C
  LD (HL),A
  INC DE
  INC HL
  POP IX
  POP BC
  DJNZ OldRevealByte26
  POP BC
  DJNZ OldRevealLine26
  POP IY
  POP IX
  POP BC
  INC IX
  DJNZ OldRevealStep26
  RET

; Clear $5B00, print with the old PrintText convention (HL, A = 24), reveal 10
; lines; B times, C + 2 (no caller)
;
; Calls PrintText $9D72 with HL = $5B00 and A = $18: the final PrintText reads
; its parameters after the CALL, so this code would print the bytes after the
; CALL as text. No caller; not executed in any recording.
;
; Witness: L1 0 ().
OldRevealPage:
  PUSH BC
  LD HL,TextBuffer
  LD DE,TextBuffer+1
  LD BC,$00F0
  LD (HL),$00
  LDIR
  LD HL,TextBuffer
  LD A,$18
  CALL PrintText

; OldRevealPage, after its PrintText call
;
; Not executed in any recording.
;
; Witness: L1 0 ().
OldRevealPageNext:
  POP BC
  PUSH IX
  PUSH BC
  CALL OldRevealWide10
  POP BC
  POP IX
  INC C
  INC C
  DJNZ OldRevealPage
  RET

; Clear $5B00-$5D6F, two old-style PrintText calls, reveal 26 lines (no caller)
;
; No caller; not executed in any recording.
;
; Witness: L1 0 ().
OldRevealPage2:
  PUSH BC
  LD HL,TextBuffer
  LD DE,TextBuffer+1
  LD BC,$0270
  LD (HL),$00
  LDIR
  LD HL,TextBuffer
  LD A,$18
  CALL PrintText

; OldRevealPage2, after its first PrintText call
;
; Not executed in any recording.
;
; Witness: L1 0 ().
OldRevealPage2Second:
  LD HL,TextBuffer
  LD A,$18
  CALL PrintText

; OldRevealPage2, after its second PrintText call: OldRevealWide26
;
; Not executed in any recording.
;
; Witness: L1 0 ().
OldRevealPage2Reveal:
  POP BC
  PUSH IX
  CALL OldRevealWide26
  POP IX
  RET

; Zeros: OldBouncingBars's variables (+2, +3: rows; +4 to +13: five columns and
; steps)
;
; Read and written only by OldBouncingBars $9A94 (never executed). Zeros on the
; tape.
OldBarVars:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  ORG $A124

; The texts of an earlier DEFINE KEYS: PRESS KEY FOR, UP, DOW\N (sic), LEFT,
; RIGHT, FIRE, each after two bytes, each ended by 0
;
; Nothing reads them (c1, menu; no operand names $A124-$A165): the final
; DefineKeys prints TextPressTheKeyFor and KeyNames. The two bytes before each
; text (5, 0 and 8, 0) are an older print routine's parameters.
OldDefineKeysTexts:
  INCBIN "res/front-texts/old-define-keys.bin",$0000,66
