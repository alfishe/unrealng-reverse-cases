; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The HUD, the text printer, the numbers
; --------------------------------------------------------------------------------------------------------------------

; One step of the HUD sweep (none while FadeStepIndex is not $FF); every 5
; round trips one narrower; the width dropping to 0 kills Rex
;
; As REX 1's HudSweep $A0C4 (src/game/hud.asm).
;
; Witness: L1 10871 (c2, p2-room20, rzx-p2- x21).
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
  LD HL,TitleScreen+$002C
  ADD HL,DE
  LD (HL),$04
  RET

; The sweep back to full width (BuildRoom, RexDies)
;
; As REX 1's ResetSweep $A133 (src/game/hud.asm).
;
; Witness: L1 68 (c2, p2-room20, rzx-p2- x18).
ResetSweep:
  LD A,$0C
  LD (SweepWidth),A
  LD A,$05
  LD (SweepCount),A
  RET

; Print B text records from IX in a framed box (attribute A, box from the first
; record), the panel sound
;
; As REX 1's PrintBoxed $A13E (src/game/hud.asm).
;
; Witness: L1 17 (c2, rzx-p2-00000, rzx-p2-40000).
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

; Draw the HUD: its texts (HudTexts $A3F4), the frame, the weapon icons and the
; bombs
;
; As REX 1's DrawHud $A1A5 (src/game/hud.asm).
;
; Witness: L1 5 (c2, rzx-p2-00000).
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

; Draw the bomb icons for Bombs $A205 (BombIcons $A3AA)
;
; As REX 1's ShowBombs $A1C9 (src/game/hud.asm).
;
; Witness: L1 6 (c2, rzx-p2-00000, rzx-p2-28000).
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
; As REX 1's DrawBombIcons $A1DB (src/game/hud.asm).
;
; Witness: L1 6 (c2, rzx-p2-00000, rzx-p2-28000).
DrawBombIcons:
  LD B,$03
  LD A,$19
  LD (HudIconParams+$0002),A

; One HUD icon: SpriteHudIcons $8AC0 + offset (HL), by DrawCharBlock $D658 with
; the inline parameters
;
; As REX 1's DrawHudIcon $A1E2 (src/game/hud.asm).
;
; Witness: L1 18 (c2, rzx-p2-00000, rzx-p2-28000).
DrawHudIcon:
  PUSH BC
  LD E,(HL)
  PUSH HL
  LD D,$00
  LD HL,SpriteHudIcons
  ADD HL,DE
  LD (HudIconParams),HL
  CALL DrawCharBlock

; DrawCharBlock's inline parameters: picture $8B80 (self-written), column 25
; (self-written), line 0, 2 x 16
;
; As REX 1's HudIconParams $A1F1 (src/game/hud.asm).
HudIconParams:
  DEFB $80,$8B,$19,$00,$02,$10

; The next icon two columns on
;
; As REX 1's NextHudIcon $A1F7 (src/game/hud.asm).
;
; Witness: L1 18 (c2, rzx-p2-00000, rzx-p2-28000).
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
;
; As REX 1's BombIcons $A3AA (src/game/hud.asm).
BombIcons:
  DEFB $A0,$A0,$A0,$00
  DEFB $C0,$A0,$A0,$00
  DEFB $C0,$C0,$A0,$00
  DEFB $C0,$C0,$C0,$00

; Draw the weapon icons: WeaponIcon $A1E8 selects the lit one
;
; As REX 1's ShowWeaponIcons $A212 (src/game/hud.asm).
;
; Witness: L1 5 (c2, rzx-p2-00000).
ShowWeaponIcons:
  LD A,$01
  LD (WeaponIconParams+$0002),A
  LD DE,WeaponIcon
  LD HL,SpriteHudIcons
  LD B,$05

; One weapon icon: SpriteHudIcons2 $8B60 + offset, DrawCharBlock with the
; inline parameters
;
; As REX 1's DrawWeaponIcon $A21F (src/game/hud.asm).
;
; Witness: L1 25 (c2, rzx-p2-00000).
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

; DrawCharBlock's inline parameters: picture $8AC0 (self-written), column 1
; (self-written), line 0, 2 x 16
;
; As REX 1's WeaponIconParams $A233 (src/game/hud.asm).
WeaponIconParams:
  DEFB $C0,$8A,$01,$00,$02,$10

; The next weapon icon two columns on
;
; As REX 1's NextWeaponIcon $A239 (src/game/hud.asm).
;
; Witness: L1 25 (c2, rzx-p2-00000).
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
;
; As REX 1's HudTexts $A3F4 (src/game/hud.asm).
HudTexts:
  INCBIN "res/texts/rex2-hud.bin",$0000,62

; Copy the back buffer's 168 play lines to the screen through ScreenLines $ACCA
; (the stack as the pointer)
;
; As REX 1's BufferToScreen $A28A (src/game/hud.asm).
;
; Witness: L1 10900 (c2, p2-room20, rzx-p2- x21).
BufferToScreen:
  LD (Temp1),SP
  LD SP,ScreenLines
  LD HL,BufferPlayOrigin
  LD BC,$13B0
BufferLine:
  POP DE                  ; each line: 16 words through the stack
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
; As REX 1's PrintTextHL $A2DF (src/game/hud.asm).
;
; Witness: L1 92 (c2, rzx-p2-00000, rzx-p2-40000).
PrintTextHL:
  PUSH BC
  CALL PrintText
  INC IX
  POP BC
  DJNZ PrintTextHL
  RET

; Print character A at column Temp2, line Temp3 (pixels) from Font $6306
; through ScreenLineTable $AC9A
;
; As REX 1's PrintChar $A2E9 (src/game/hud.asm).
;
; Witness: L1 1224 (c2, rzx-p2-00000, rzx-p2-40000).
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
  LD DE,Font-256
  ADD HL,DE
  EX DE,HL
  POP IY
  LD B,$08
  RET

; Print a text record: [attribute][column][line] characters, 0 ends; the
; attributes set
;
; As REX 1's PrintText $A307 (src/game/hud.asm).
;
; Witness: L1 92 (c2, rzx-p2-00000, rzx-p2-40000).
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

; A = the byte at RandomSeed $A23A, the seed + 1 within $0000-$3FFF; nothing
; calls it (leftover)
;
; Witness: L1 0 ().
UnusedRandom:
  LD HL,(RandomSeed)
  INC HL
  LD A,H
  AND $3F
  LD H,A
  LD A,(HL)
  LD (RandomSeed),HL
  RET

; A = a random byte: the byte at RandomSeed $A23A (walking $0000-$3FFF, the
; ROM) plus R
;
; As REX 1's Random $A375 (src/game/hud.asm).
;
; Witness: L1 24087 (c2, p2-room20, rzx-p2- x21).
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

; A = a random byte from RandomSeed2 $A23C and R
;
; As REX 1's Random2 $A388 (src/game/hud.asm).
;
; Witness: L1 60211 (c2, p2-room20, rzx-p2- x21).
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
; As REX 1's ClearScreen $A3AE (src/game/hud.asm).
;
; Witness: L1 5 (c2, rzx-p2-00000).
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

; Print B digits of Digits $A23F at HL on the screen
;
; As REX 1's PrintDigits $A3C8 (src/game/hud.asm).
;
; Witness: L1 801 (c2, p2-room20, rzx-p2- x20).
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
  LD BC,Font-256
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
; As REX 1's ScreenDown $A3F9 (src/game/hud.asm).
;
; Witness: L1 1858 (c2, p2-room20, rzx-p2- x20).
ScreenDown:
  LD B,$08
ScreenDownCell:
  LD A,(HL)               ; the next character row or third
  LD (DE),A
  INC HL
  INC D
  DJNZ ScreenDownCell
  RET

; HL into five decimal digits at Digits $A23F (units first)
;
; As REX 1's ToDigits $A402 (src/game/hud.asm).
;
; Witness: L1 801 (c2, p2-room20, rzx-p2- x20).
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
; As REX 1's DigitOf $A447 (src/game/hud.asm).
;
; Witness: L1 4005 (c2, p2-room20, rzx-p2- x20).
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
