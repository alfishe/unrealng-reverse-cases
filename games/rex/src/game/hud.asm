; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The HUD, the text printer, the numbers
;
; The HUD fills the top three character rows: the score, lives, shield, weapons, bombs and the power bar. Texts are
; records [attribute][column][line in pixels] then characters ending with 0; PrintText prints one, PrintBoxed prints B
; records in a framed box (PanelBox $CE7B). Numbers go through ToDigits (five decimal digits, Digits $A0A6) and
; PrintDigits.
;
; HudSweep is the bar that runs along the HUD's attribute row $582B: every 5 round trips it gets one narrower
; (SweepWidth $A067, 12 after ResetSweep $A133); when the width would drop to 0 ($A119-$A11B: DEC A, OR A, JP
; Z,RexDies) Rex dies. Room changes and deaths (RexDies) reset it. It stands still while the power pod's HUD flash
; runs (FadeStepIndex not $FF). p1-gameover lets it run down from width 2. The magazines' infinite-time POKE 43545,0
; ($AA19) hits data in this release (ShardPaths); POKE 41241,0 (the DEC A at $A119 made a NOP) keeps the width.
; --------------------------------------------------------------------------------------------------------------------

; One step of the HUD sweep (none while FadeStepIndex is not $FF); every 5
; round trips one narrower; the width dropping to 0 kills Rex
;
; Witness: L1 18614 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
HudSweep:
  LD A,(FadeStepIndex)
  CP $FF
  RET NZ
  LD A,(SweepPos)
  LD E,A
  LD D,$00
  LD HL,$582B
  ADD HL,DE
  LD (HL),$46
  INC HL
  LD A,(HL)
  CP $04
  JP Z,SweepMove
  LD (HL),$06
SweepMove:
  LD A,(SweepDir)         ; the sweep's step by its direction
  OR A
  JP Z,SweepLeft
  JP SweepRight
SweepLeft:
  LD A,(SweepPos)         ; moving left
  INC A
  LD (SweepPos),A
  LD HL,SweepWidth
  CP (HL)
  RET NZ
  LD A,$01
  LD (SweepDir),A
  RET
SweepRight:
  LD A,(SweepPos)         ; moving right
  DEC A
  LD (SweepPos),A
  OR A
  RET NZ
  XOR A
  LD (SweepDir),A
  LD A,(SweepCount)
  DEC A
  LD (SweepCount),A
  OR A
  RET NZ
  LD A,$05
  LD (SweepCount),A
  LD A,(SweepWidth)
  DEC A
  OR A
  JP Z,RexDies
  LD (SweepWidth),A
  LD E,A
  LD D,$00
  PUSH DE
  LD HL,$582C
  ADD HL,DE
  LD (HL),$04
  POP DE
  LD HL,SweepAttrs
  ADD HL,DE
  LD (HL),$04
  RET

; The sweep back to full width (BuildRoom, RexDies)
;
; Witness: L1 122 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-rooms238, p1-speedup, p1-room x5, rzx-p1- x32).
ResetSweep:
  LD A,$0C
  LD (SweepWidth),A
  LD A,$05
  LD (SweepCount),A
  RET

; Print B text records from IX in a framed box (attribute A, box from the first
; record), the panel sound
;
; Witness: L1 52 (c1, menu-rollcall, p1-code, p1-cursor, p1-define,
; p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).
PrintBoxed:
  PUSH IX
  PUSH BC
  LD A,$01
  LD (Temp2),A
BoxedRecord:
  LD A,$01                ; each record
  LD (Temp1),A
  LD DE,$0003
  ADD IX,DE
BoxedSize:
  LD A,(IX+$00)           ; the box's size from the records
  OR A
  JP Z,BoxedDraw
  LD HL,Temp1
  INC (HL)
  INC IX
  JP BoxedSize
BoxedDraw:
  LD A,(Temp1)            ; the box
  LD HL,Temp2
  CP (HL)
  JP C,BoxedNext
  LD (Temp2),A
BoxedNext:
  DJNZ BoxedRecord        ; the next record
  POP BC
  POP IX
  PUSH IX
  PUSH BC
  LD A,B
  CP $01
  JP NZ,BoxedPrint
  LD HL,Temp2
  INC (HL)
BoxedPrint:
  LD A,(IX+$01)           ; print the records into it
  SUB $03
  LD H,A
  LD A,(IX+$02)
  SRL A
  SRL A
  SRL A
  DEC A
  LD L,A
  LD E,B
  LD A,(Temp2)
  SUB $02
  LD D,A
  LD A,$47
  LD C,$07
  CALL PanelBox
  POP BC
  POP IX
  CALL PrintTextHL
  RET

; Draw the HUD: its texts (HudTexts $A24C), the frame, the weapon icons and the
; bombs
;
; Witness: L1 9 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1-00000,
; rzx-p1-64000).
DrawHud:
  LD B,$03
  LD IX,HudTexts
  CALL PrintTextHL
  LD HL,$5801
  LD B,$02
  LD E,$0A
  LD A,$01
  CALL FillAttrs
  LD HL,$5819
  LD B,$02
  LD E,$06
  LD A,$02
  CALL FillAttrs
  CALL ShowWeaponIcons

; Draw the bomb icons for Bombs $A06C (BombIcons $A202)
;
; Witness: L1 20 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room30,
; rzx-p1- x7).
ShowBombs:
  LD A,(Bombs)
  SLA A
  SLA A
  LD E,A
  LD D,$00
  LD HL,BombIcons
  ADD HL,DE
  CALL DrawBombIcons
  RET

; Three icons from HL: the column at $A1F3 from 25
;
; Witness: L1 20 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room30,
; rzx-p1- x7).
DrawBombIcons:
  LD B,$03
  LD A,$19
  LD (HudIconParams+$0002),A

; One HUD icon: SpriteHudIcons $8C0A + offset (HL), by DrawCharBlock $D8C0 with
; the inline parameters
;
; Witness: L1 60 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room30,
; rzx-p1- x7).
DrawHudIcon:
  PUSH BC
  LD E,(HL)
  PUSH HL
  LD D,$00
  LD HL,SpriteHudIcons
  ADD HL,DE
  LD (HudIconParams),HL
  CALL DrawCharBlock

; DrawCharBlock's inline parameters: picture $8CCA (self-written), column 25
; (self-written), line 0, 2 x 16
HudIconParams:
  DEFB $CA,$8C,$19,$00,$02,$10

; The next icon two columns on
;
; Witness: L1 60 (c1, p1-code, p1-cursor, p1-define, p1-kempston, p1-room30,
; rzx-p1- x7).
NextHudIcon:
  LD HL,HudIconParams+$0002
  INC (HL)
  INC (HL)
  POP HL
  INC HL
  POP BC
  DJNZ DrawHudIcon
  RET

; The bomb icons by bombs left (0-3): three offsets each, $A0 empty and $C0
; full
BombIcons:
  DEFB $A0,$A0,$A0,$00
  DEFB $C0,$A0,$A0,$00
  DEFB $C0,$C0,$A0,$00
  DEFB $C0,$C0,$C0,$00

; Draw the weapon icons: WeaponIcon $A04F selects the lit one
;
; Witness: L1 104 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1- x9).
ShowWeaponIcons:
  LD A,$01
  LD (WeaponIconParams+$0002),A
  LD DE,WeaponIcon
  LD HL,SpriteHudIcons
  LD B,$05

; One weapon icon: SpriteHudIcons2 $8CAA + offset, DrawCharBlock with the
; inline parameters
;
; Witness: L1 520 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1- x9).
DrawWeaponIcon:
  PUSH BC
  PUSH DE
  PUSH HL
  LD (WeaponIconParams),HL
  LD A,(DE)
  OR A
  JP NZ,WeaponIconCall
  LD HL,SpriteHudIcons2
  LD (WeaponIconParams),HL
WeaponIconCall:
  CALL DrawCharBlock      ; the call with the inline parameters

; DrawCharBlock's inline parameters: picture $8C0A (self-written), column 1
; (self-written), line 0, 2 x 16
WeaponIconParams:
  DEFB $0A,$8C,$01,$00,$02,$10

; The next weapon icon two columns on
;
; Witness: L1 520 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1- x9).
NextWeaponIcon:
  LD A,(WeaponIconParams+$0002)
  ADD A,$02
  LD (WeaponIconParams+$0002),A
  POP HL
  LD DE,$0020
  ADD HL,DE
  POP DE
  INC DE
  POP BC
  DJNZ DrawWeaponIcon
  RET

; The HUD's texts: a row of "#", the figures 0000000:99:3, the icon row ("]\ ^\
; _\ @\ ..." are the HUD's own characters)
HudTexts:
  INCBIN "res/texts/rex1-hud.bin",$0000,62

; Copy the back buffer's 168 play lines to the screen through ScreenLines $AC0D
; (the stack as the pointer)
;
; Witness: L1 18698 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
BufferToScreen:
  LD (Temp1),SP
  LD SP,ScreenLines
  LD HL,BufferPlayOrigin
  LD BC,$13B0
BufferLine:
  POP DE                  ; each line: its screen address from ScreenLines
  INC DE
  INC HL
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
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  INC HL
  JP PE,BufferLine
  LD SP,(Temp1)
  RET

; Print the text record at HL (PrintText)
;
; Witness: L1 142 (c1, menu-rollcall, p1-code, p1-cursor, p1-define,
; p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).
PrintTextHL:
  PUSH BC
  CALL PrintText
  INC IX
  POP BC
  DJNZ PrintTextHL
  RET

; Print character A at column Temp2, line Temp3 (pixels) from Font $60E0
; through ScreenLineTable $ABDD
;
; Witness: L1 1949 (c1, menu-rollcall, p1-code, p1-cursor, p1-define,
; p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).
PrintChar:
  LD A,(Temp3)
  LD L,A
  LD H,$00
  ADD HL,HL
  LD DE,ScreenLineTable
  ADD HL,DE
  PUSH HL
  LD L,(IX+$00)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,$5FE0
  ADD HL,DE
  EX DE,HL
  POP IY
  LD B,$08
  RET

; Print a text record: [attribute][column][line] characters, 0 ends; the
; attributes set
;
; Witness: L1 152 (c1, menu-rollcall, p1-code, p1-cursor, p1-define,
; p1-gameover, p1-kempston, p1-speedup, rzx-p1- x7).
PrintText:
  LD A,(IX+$00)
  LD (Temp1),A
  LD A,(IX+$01)
  LD (Temp2),A
  LD A,(IX+$02)
  LD (Temp3),A
  LD DE,$0003
  ADD IX,DE
PrintTextChar:
  CALL PrintChar          ; each character
PrintTextLine:
  LD L,(IY+$00)           ; each of the character's 8 lines; the attribute
                          ; after them
  LD H,(IY+$01)
  PUSH DE
  LD A,(Temp2)
  LD E,A
  LD D,$00
  ADD HL,DE
  POP DE
  LD A,(DE)
  LD (HL),A
  INC DE
  INC IY
  INC IY
  DJNZ PrintTextLine
  LD A,(IX+$00)
  CP $20
  JR Z,PrintTextNext
  LD A,(Temp3)
  AND $F8
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD A,(Temp2)
  LD E,A
  LD D,$00
  ADD HL,DE
  LD DE,$5800
  ADD HL,DE
  LD A,(Temp1)
  LD (HL),A
PrintTextNext:
  INC IX                  ; the next character
  LD HL,Temp2
  INC (HL)
  LD A,(IX+$00)
  OR A
  JR Z,PrintTextEnd
  JR PrintTextChar
PrintTextEnd:
  RET                     ; the end

; Leftover: LD HL,($A0A1): INC HL: LD A,H: AND $3F: LD H,A: LD A,(HL): LD
; ($A0A1),HL: RET, a random routine nothing calls
;
; Known only from the code: the bytes are a routine that walks RandomSeed
; through the ROM's first 16 K (the ROM as noise), Random $A375's older form.
UnusedRandom:
  DEFB $2A,$A1,$A0,$23,$7C,$E6,$3F,$67,$7E,$22,$A1,$A0,$C9

; A = a random byte: the byte at RandomSeed $A0A1 (walking $0000-$3FFF, the
; ROM) plus R
;
; Witness: L1 56999 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room x5,
; rzx-p1- x32).
Random:
  PUSH HL
  LD A,(RandomSeed)
  SLA A
  SLA A
  LD HL,RandomSeed
  ADD A,(HL)
  ADD A,$15
  LD (RandomSeed),A
  POP HL
  RET

; A = a random byte from RandomSeed2 $A0A3 and R
;
; Witness: L1 14250 (c1, p1-cursor, p1-define, p1-gameover, p1-kempston,
; p1-poke41241, p1-rooms238, p1-shots, p1-speedup, p1-room14, p1-room24,
; p1-room26, p1-room30, rzx-p1- x29).
Random2:
  PUSH HL
  LD (Temp1),BC
  LD B,$08
Random2Loop:
  LD A,(RandomSeed)       ; 8 shifts
  AND $48
  ADC A,$38
  RLA
  RLA
  LD HL,RandomSeed2
  RL (HL)
  DEC HL
  RL (HL)
  DEC HL
  RL (HL)
  DJNZ Random2Loop
  LD A,(RandomSeed)
  LD BC,(Temp1)
  POP HL
  RET

; Clear the screen's bitmap and attributes
;
; Witness: L1 9 (c1, p1-code, p1-cursor, p1-define, p1-kempston, rzx-p1-00000,
; rzx-p1-64000).
ClearScreen:
  LD HL,$4000
  LD DE,$4001
  LD BC,$1AFF
  LD (HL),$00
  LDIR
  LD HL,$5800
  LD DE,$5801
  LD BC,$02FF
  LD (HL),A
  LDIR
  RET

; Print B digits of Digits $A0A6 at HL on the screen
;
; Witness: L1 1861 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).
PrintDigits:
  PUSH IX
  LD IX,Digits
  LD H,$00
  ADD HL,HL
  LD D,$00
  PUSH DE
  LD DE,ScreenLineTable
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  POP HL
  ADD HL,DE
  EX DE,HL
DigitLoop:
  PUSH BC                 ; each digit
  PUSH DE
  LD L,(IX+$00)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD BC,$5FE0
  ADD HL,BC
  CALL ScreenDown
  INC IX
  POP DE
  DEC DE
  POP BC
  DJNZ DigitLoop
  POP IX
  RET

; HL one pixel line down the screen
;
; Witness: L1 4599 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).
ScreenDown:
  LD B,$08
ScreenDownCell:
  LD A,(HL)               ; the next character row or third
  LD (DE),A
  INC HL
  INC D
  DJNZ ScreenDownCell
  RET

; HL into five decimal digits at Digits $A0A6 (units first)
;
; Witness: L1 1866 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).
ToDigits:
  PUSH IX
  LD (DigitTemp),HL
  XOR A
  LD (Digits+$0004),A
  LD (Digits+$0003),A
  LD (Digits+$0002),A
  LD (Digits+$0001),A
  LD (Digits),A
  LD DE,$2710
  CALL DigitOf
  LD (Digits+$0004),A
  LD DE,$03E8
  CALL DigitOf
  LD (Digits+$0003),A
  LD DE,$0064
  CALL DigitOf
  LD (Digits+$0002),A
  LD DE,$000A
  CALL DigitOf
  LD (Digits+$0001),A
  LD DE,$0001
  CALL DigitOf
  LD (Digits),A
  POP IX
  RET

; One digit: count how many times DE goes into HL
;
; Witness: L1 9330 (c1, p1-code, p1-cursor, p1-define, p1-gameover,
; p1-kempston, p1-rooms238, p1-shots, p1-speedup, p1-room x5, rzx-p1- x33).
DigitOf:
  LD HL,(DigitTemp)
  LD IX,$0000
  LD B,$00
DigitCount:
  AND A                   ; subtract DE while it goes
  SBC HL,DE
  JR C,DigitStore
  ADD IX,DE
  INC B
  JR DigitCount
DigitStore:
  PUSH IX                 ; the digit
  POP DE
  LD HL,(DigitTemp)
  AND A
  SBC HL,DE
  LD (DigitTemp),HL
  LD A,B
  ADD A,$30
  RET
