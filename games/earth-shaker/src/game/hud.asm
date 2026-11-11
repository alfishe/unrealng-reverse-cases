; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The HUD, the score, the time bar, the digits and the texts
;
; The bottom line (row 23) shows the cave, the gems still needed, the lives (ShowCounters $85AD) and the score
; (ShowScore $8342); the time bar is 4 pixel lines at $52C0 (row 22). Numbers are strings of decimal digits (0-9 a
; byte) printed with the digit glyphs at $BD80 (PrintDigits $832A); texts are ASCII printed with the font, glyph $BC00
; + 8 x code (PrintText $834F).
; --------------------------------------------------------------------------------------------------------------------

  ORG $8315

; Add 1 to a decimal digit string
;
; HL = the last digit, B = the digits. The carry runs left while a digit wraps
; from 9 to 0.
;
; Witness: L1 70071 (c1, rzx x32).
IncDigits:
  LD A,(HL)
  INC A
  LD (HL),A
  CP $0A
  RET NZ
  LD (HL),$00
  DEC HL
  DJNZ IncDigits
  RET

; Add 1 point to the score
;
; IncDigits on ScoreDigits $FD94-$FD99.
;
; Witness: L1 61386 (c1, rzx x32).
AddPoint:
  LD HL,ScoreDigits+$0005
  LD B,$06
  CALL IncDigits
  RET

; Print D decimal digits right to left
;
; HL = the last digit, B = the row, C = the last digit's column, D = the count.
; The glyph of digit k is $BD80 + 8k.
;
; Witness: L1 82024 (c1, hiscore, lives, menu, timer, rzx x32).
PrintDigits:
  PUSH DE
  LD A,(HL)
  RLCA
  RLCA
  RLCA
  LD DE,DigitGlyphs
  ADD A,E
  LD E,A
  PUSH BC
  PUSH HL
  CALL PrintGlyph
  POP HL
  POP BC
  POP DE
  DEC C
  DEC HL
  DEC D
  JR NZ,PrintDigits
  RET

; Print the score at row 23, columns 26-31
;
; Witness: L1 12513 (c1, hiscore, lives, timer, rzx x32).
ShowScore:
  LD B,$17
  LD C,$1F
  LD HL,ScoreDigits+$0005
  LD D,$06
  CALL PrintDigits
  RET

; Print D characters of ASCII text
;
; HL = the text, B = the row, C = the first column, D = the length. The glyph
; of code k is $BC00 + 8k (Font $BD00 is code $20).
;
; Witness: L1 5950 (c1, hiscore, lives, menu, timer, rzx x32).
PrintText:
  PUSH DE
  PUSH HL
  PUSH BC
  LD B,(HL)
  LD DE,$0008
  LD HL,Font-256
PrintTextLoop:
  ADD HL,DE
  DJNZ PrintTextLoop
  PUSH HL
  POP DE
  POP BC
  CALL PrintGlyph
  POP HL
  POP DE
  INC C
  INC HL
  DEC D
  JR NZ,PrintText
  RET

; Print HudLine $BCE0 on row 23
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
ShowHudLine:
  LD D,$20
  LD BC,$1700
  LD HL,HudLine
  CALL PrintText
  RET

; Add GemValue $FD9B points, one at a time
;
; Witness: L1 1680 (c1, rzx x32).
AddGemValue:
  LD A,(GemValue)
  LD B,A
AddGemValueLoop:
  PUSH BC
  CALL AddPoint
  POP BC
  DJNZ AddGemValueLoop
  RET

; Write the player's code at the player's cell
;
; CaveGrid + PlayerIndex = PlayerFacing $FD86.
;
; Witness: L1 44099 (c1, hiscore, lives, timer, rzx x32).
PutPlayer:
  LD HL,(PlayerIndex)
  LD DE,CaveGrid
  ADD HL,DE
  LD A,(PlayerFacing)
  LD (HL),A
  RET

; PlayerFacing = 4 (facing left)
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
FaceLeft:
  LD HL,PlayerFacing
  LD (HL),$04
  RET

; Count a gem; open the exit when enough are taken
;
; GemCount $FD92 + 1; when it equals GemsNeeded $FD9A, ExitOpen $FD85 = $FF.
; The gem digits GemsNeededDigits $FD9E count down.
;
; Witness: L1 1680 (c1, rzx x32).
CountGem:
  LD A,(GemCount)
  INC A
  LD (GemCount),A
  LD HL,CaveParams
  CP (HL)
  JR NZ,CountGemSkip
  LD HL,ExitOpen
  LD (HL),$FF
CountGemSkip:
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD HL,GemDigits+$0001
  LD B,$02
  CALL IncDigits
  LD HL,GemDigits+$0001
  LD BC,$1709
  LD D,$02
  CALL PrintDigits
  CALL GemSound
  RET

  ORG $85AD

; Print the cave number, the gems needed and the lives on row 23
;
; Witness: L1 54 (c1, hiscore, lives, timer, rzx x32).
ShowCounters:
  LD BC,$1702
  LD D,$02
  LD HL,CaveDigits+$0001
  CALL PrintDigits
  LD BC,$1706
  LD D,$02
  LD HL,GemsNeededDigits+$0001
  CALL PrintDigits
  LD BC,$170C
  LD D,$01
  LD HL,Lives
  CALL PrintDigits
  RET

  ORG $8654

; Fill the time bar (4 pixel lines of 32 bytes $FF from $52C0) and colour it
;
; Then BarColours $9224.
;
; Witness: L1 48 (c1, hiscore, lives, timer, rzx x32).
FillTimeBar:
  LD B,$04
  LD DE,Screen+4801
  LD HL,Screen+4800
FillTimeBarLoop:
  PUSH BC
  LD BC,$001F
  PUSH HL
  PUSH DE
  LD (HL),$FF
  LDIR
  POP DE
  POP HL
  POP BC
  INC H
  INC D
  DJNZ FillTimeBarLoop
  CALL BarColours
  RET

; Leftover: 22 bytes, never run
FillTimeBarPad:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00

  ORG $89A7

; Print LEVEL, LIVES LEFT: and SCORE: with their values
;
; HudLabels $BB00 and the digits, for CaveIntro $92D4.
;
; Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).
ShowLevelLivesScore:
  LD HL,HudLabels
  LD BC,$060B
  LD D,$05
  CALL PrintText
  LD HL,LivesLeftText
  LD BC,$0A09
  LD D,$0B
  CALL PrintText
  LD HL,ScoreText
  LD BC,$0C09
  LD D,$06
  CALL PrintText
  LD HL,ScoreDigits+$0005
  LD BC,$0C15
  LD D,$06
  CALL PrintDigits
  LD HL,Lives
  LD BC,$0A15
  LD D,$01
  CALL PrintDigits
  LD HL,CaveDigits+$0001
  LD BC,$0612
  LD D,$02
  CALL PrintDigits
  RET

  ORG $8BEC

; Colour and print the cave intro's three lines
;
; Witness: L1 46 (c1, hiscore, lives, timer, rzx x31).
ColourLevelLivesScore:
  LD BC,$060B
  LD D,$08
  LD A,$46
  CALL FillAttrs
  LD BC,$0A09
  LD D,$0D
  LD A,$44
  CALL FillAttrs
  LD BC,$0C09
  LD D,$0D
  LD A,$42
  CALL FillAttrs
  CALL ShowLevelLivesScore
  RET

  ORG $91F7

; The jelly bean (8): the bar refilled with a sweep
;
; Witness: L1 132 (rzx x23).
JellyBean:
  LD B,$20
JellyBeanLoop:
  PUSH BC
  LD L,B
  LD H,$00
  LD A,L
  ADD A,$80
  LD L,A
  LD DE,$0014
  CALL RomBeeper
  DI
  POP BC
  PUSH BC
  LD A,$20
  SUB B
  LD L,A
  LD A,L
  ADD A,$80
  LD L,A
  LD H,$00
  LD DE,$0014
  CALL RomBeeper
  DI
  CALL TimeRefill
  POP BC
  DJNZ JellyBeanLoop
  JP Continue

; Colour the time bar from BarAttrs $BC92
;
; Witness: L1 105 (c1, hiscore, lives, timer, rzx x32).
BarColours:
  LD DE,Attributes+704
  LD BC,$0040
  LD HL,BarAttrs
  LDIR
  RET

  ORG $A8D5

; Add B points
;
; Witness: L1 31018 (rzx x29).
AddPoints:
  PUSH BC
  CALL AddPoint
  POP BC
  DJNZ AddPoints
  CALL ShowScore
  RET

; 20 points
;
; Witness: L1 6 (rzx x6).
PotionScore:
  CALL PotionTune
  PUSH BC
  LD B,$14
  PUSH HL
  PUSH BC
  PUSH DE
  PUSH AF
  CALL AddPoints
  POP AF
  POP DE
  POP BC
  POP HL
  RET

; Zeros (14 bytes)
AddPointsPad:
  DEFS $0E

  ORG $A9D7

; Refill the time bar: 32 steps, 2 points each
;
; Witness: L1 4224 (rzx x23).
TimeRefill:
  CALL TimeBarRefillStep
  LD B,$02
  CALL AddPoints
  CALL ShowScore
  RET

; The switch: 250 points and its sound
;
; Witness: L1 23 (rzx x23).
SwitchScore:
  CALL SwitchSound
  LD B,$FA
  CALL AddPoints
  CALL ShowScore
  RET

; The arrow taken: the sound, 200 points
;
; Witness: L1 16 (rzx x6).
AntiGravStart:
  CALL AntiGravSound
  LD B,$C8
  CALL AddPoints
  CALL ShowScore
  RET

; Leftover: 5 bytes, never run
AntiGravStartPad:
  DEFB $00,$00,$00,$00,$00

  ORG $BB00

; "LEVEL", "LIVES LEFT:", "SCORE:"
HudLabels:
  INCBIN "res/texts/hud-labels.bin",$0000,5
LivesLeftText:
  INCBIN "res/texts/hud-labels.bin",$0005,11
ScoreText:
  INCBIN "res/texts/hud-labels.bin",$0010,6

; Zeros (106 bytes)
HudLabelsPad:
  DEFS $6A

  ORG $BC92

; The time bar's attributes (2 lines of 32)
BarAttrs:
  INCBIN "res/tables/bar-attrs.bin",$0000,64

; Zeros (14 bytes)
BarAttrsPad:
  DEFS $0E

; The bottom line's text
HudLine:
  INCBIN "res/texts/hud-line.bin",$0000,32

; The font: characters $20-$7F, 8 bytes each
Font:
  INCBIN "res/graphics/font.bin",$0000,128
DigitGlyphs:
  INCBIN "res/graphics/font.bin",$0080,392
IconGlyphs:
  INCBIN "res/graphics/font.bin",$0208,16
AntiGravIcon:
  INCBIN "res/graphics/font.bin",$0218,8
AntiGravIconOff:
  INCBIN "res/graphics/font.bin",$0220,32
FontUnused:
  INCBIN "res/graphics/font.bin",$0240,192
