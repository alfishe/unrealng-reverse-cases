; --------------------------------------------------------------------------------------------------------------------
; menu.asm: the options menu: ZYNAPS OPTIONS, the keys 1-7 and the hidden 0, 8 and level select
;
; The boot calls Menu after the loading screen. It draws the options (Text, printed by PrintText with a bold copy of
; the ROM font) and waits: key 1 starts with music and effects, key 2 with effects only; keys 3-7 change an option and
; draw the menu again.
;
; Key 0 is not shown. It writes $16 (AT) over the zero that ends Text, so the two lines after it print too ("8.
; INFINITE LIFE" and "Q-P,A-S. SELECT LEVEL!!!"), turns key 8's jump into the INFINITE LIFE toggle and makes the key
; loop go on to the level keys: Q W E R T for levels 1-5, Y U I O P for 6-10, A and S for 11 and 12.
;
; An option is a byte the menu keeps and writes into the code at the start (Start) or a byte in the code it toggles
; directly: INFINITE ROUNDS (JR at RoundsJump), TURBO LOADER (the loader's reader), SATURNS (FX 21 and its sound),
; SHOOTING (the shot's channel or no shot sound), EFFECTS TIMER (the gate's length, 0-9), INFINITE LIFE (RET at
; ShipHitJump), SELECT LEVEL (LD B,n at LevelSelectCode).
; --------------------------------------------------------------------------------------------------------------------

; bank 7 paged for the font at $FD00, the menu run (MenuLoop), bank 0 paged
; back
Menu:
  LD A,$17
  LD (BANKM),A
  LD BC,$7FFD
  OUT (C),A
  CALL MenuLoop
  LD BC,$7FFD
  LD A,$10
  LD (BANKM),A
  OUT (C),A
  RET

; zeros
Spare:
  DEFS $4C

; the font, the screen cleared, then the values, Text and the key wait until
; key 1 or 2
;
; Used by the routine at Menu.
MenuLoop:
  CALL MakeFont
  CALL ClearScreen
; This entry point is used by the routines at Reveal, Toggle, ShootingKey and
; TimerKey.
Redraw:
  CALL ShowValues         ; after every option key: the values into Text and
                          ; Text printed again
  LD HL,Text
  CALL PrintText
  LD B,$0A                ; 10 frames before the keys are read again
l_6DD5:
  HALT
  DJNZ l_6DD5
; This entry point is used by the routines at LevelKeys and SelectLevel.
KeyLoop:
  LD BC,$F7FE             ; keys 1-5 (row $F7FE), then 0, 8, 7, 6 (row $EFFE)
  IN A,(C)
  RRCA
  LD E,$00
  JP NC,Start
  INC E
  RRCA
  JP NC,Start
  RRCA
  JP NC,InfiniteRoundsKey
  RRCA
  JP NC,TurboKey
  RRCA
  JP NC,SaturnsKey
  LD BC,$EFFE
  IN A,(C)
  RRCA
  JP NC,Reveal
  RRCA                    ; key 9: its bit passed over
  RRCA
KeyEight:
  JP NC,KeyLoop           ; key 8: JP NC to KeyLoop until key 0 sets
                          ; InfiniteLifeKey as its target
  RRCA
  JP NC,TimerKey
  RRCA
  JP NC,ShootingKey
NoKey:
  JP KeyLoop              ; JP KeyLoop until key 0 sets LevelKeys as its target

; key 0: the hidden lines shown (the end of Text becomes AT), key 8 and the
; level keys turned on
;
; Used by the routine at MenuLoop.
Reveal:
  LD A,$16
  LD (TextEnd),A
  LD HL,InfiniteLifeKey
  LD (KeyEight+1),HL
  LD HL,LevelKeys
  LD (NoKey+1),HL
  JP Redraw

; Q-T (row $FBFE) levels 1-5, P O I U Y (row $DFFE) 10-6, A S (row $FDFE) 11,
; 12
LevelKeys:
  LD B,$FB
  IN A,(C)
  LD E,$01
  RRCA
  JP NC,SelectLevel
  INC E
  RRCA
  JP NC,SelectLevel
  INC E
  RRCA
  JP NC,SelectLevel
  INC E
  RRCA
  JP NC,SelectLevel
  INC E
  RRCA
  JP NC,SelectLevel
  LD B,$DF
  LD E,$0A
  IN A,(C)
  RRCA
  JP NC,SelectLevel
  DEC E
  RRCA
  JP NC,SelectLevel
  DEC E
  RRCA
  JP NC,SelectLevel
  DEC E
  RRCA
  JP NC,SelectLevel
  DEC E
  RRCA
  JP NC,SelectLevel
  LD B,$FD
  LD E,$0B
  IN A,(C)
  RRCA
  JP NC,SelectLevel
  INC E
  RRCA
  JP NC,SelectLevel
  JP KeyLoop

; LD B,E ($06 E) at LevelSelectCode: the level the game goes on to is E
;
; Used by the routine at LevelKeys.
SelectLevel:
  LD A,$06
  LD (LevelSelectCode),A
  LD A,E
  LD (LevelSelectCode+1),A
  JP KeyLoop

; key 8: INFINITE LIFE toggled
InfiniteLifeKey:
  LD HL,InfiniteLife
  JR Toggle

; key 3: INFINITE ROUNDS toggled
;
; Used by the routine at MenuLoop.
InfiniteRoundsKey:
  LD HL,InfiniteRounds

; the byte at HL XOR 1, then Redraw
;
; Used by the routines at InfiniteLifeKey, TurboKey and SaturnsKey.
Toggle:
  LD A,(HL)
  XOR $01
  LD (HL),A
  JP Redraw

; key 4: TURBO LOADER toggled
;
; Used by the routine at MenuLoop.
TurboKey:
  LD HL,TurboOption
  JR Toggle

; key 5: SATURNS toggled
;
; Used by the routine at MenuLoop.
SaturnsKey:
  LD HL,SaturnsOption
  JR Toggle

; key 6: SHOOTING 0 NORMAL, 1 DISABLED, 2 CHANNEL, round
;
; Used by the routine at MenuLoop.
ShootingKey:
  LD A,(ShootingOption)
  INC A
  CP $03
  JR NZ,l_6E9D
  XOR A
l_6E9D:
  LD (ShootingOption),A
  JP Redraw

; key 7: the EFFECTS TIMER digit 0-9, round
;
; Used by the routine at MenuLoop.
TimerKey:
  LD A,(TimerDigit)
  INC A
  CP $3A
  JR NZ,l_6EAD
  LD A,$30
l_6EAD:
  LD (TimerDigit),A
  JP Redraw

; key 1 (E = 0) or 2 (E = 1): the sound mode and the options written into the
; code
;
; SoundModeOption = E; INFINITE LIFE: RET at ShipHitJump; INFINITE ROUNDS: JR
; at RoundsJump; EFFECTS TIMER: the digit's value to TimerOperand1 and
; TimerOperand2. TURBO LOADER, SATURNS and SHOOTING are written at once by
; their keys.
Start:
  LD A,E
  LD (SoundModeOption),A
  LD A,(InfiniteLife)
  OR A
  JR Z,l_6EC2
  LD A,$C9
  LD (ShipHitJump),A
l_6EC2:
  LD A,(InfiniteRounds)
  OR A
  JR Z,l_6ECD
  LD A,$18
  LD (RoundsJump),A
l_6ECD:
  LD A,(TimerDigit)
  SUB $30
  LD (TimerOperand1),A
  LD (TimerOperand2),A
  RET

; border black, bitmap and attributes zeroed
;
; Used by the routine at MenuLoop.
ClearScreen:
  XOR A
  OUT ($FE),A
  LD HL,Attrs+767
  LD DE,Attrs+766
  LD BC,$1AFF
  LD (HL),A
  LDDR
  RET

; the text at HL: 32 and up a character, $10 a the attribute, $0D a new line,
; $16 r c a position, 0 the end
;
; Other codes below 32 are skipped. A row of 24 or more and a column of 32 or
; more are taken as 0. The attribute is a letter in the texts: "A" $41 bright
; blue, "B" bright red, "C" bright magenta, "E" bright cyan, "F" bright yellow,
; "G" bright white.
PrintText:
  LD A,(HL)
  CP $20
  JP NC,PrintChar
  CP $10
  JR Z,l_6F01
  CP $0D
  JR Z,l_6F0A
  CP $16
  JP Z,l_6F24
  OR A
  RET Z
  INC HL
  JR PrintText
l_6F01:
  INC HL                  ; $10: the attribute into PrintChar's LD A
  LD A,(HL)
  LD (CharAttr+1),A
  INC HL
  JP PrintText
l_6F0A:
  INC HL                  ; $0D: column 0, the next row (row 23 goes back to 0)
  XOR A
  LD (CharPosition+1),A
  LD A,(CharPosition+2)
  INC A
  CP $17
  JR NC,l_6F1D
  LD (CharPosition+2),A
  JP PrintText
l_6F1D:
  XOR A
  LD (CharPosition+2),A
  JP PrintText
l_6F24:
  INC HL                  ; $16: row and column
  LD A,(HL)
  CP $18
  JR NC,l_6F3A
l_6F2A:
  LD (CharPosition+2),A
  INC HL
  LD A,(HL)
  CP $20
  JR NC,l_6F3E
l_6F33:
  LD (CharPosition+1),A
  INC HL
  JP PrintText
l_6F3A:
  XOR A
  JP l_6F2A
l_6F3E:
  XOR A
  JP l_6F33

; the character A at the position (CharPosition), the attribute (CharAttr), the
; column on
;
; Used by the routine at PrintText.
PrintChar:
  PUSH HL
  LD L,A
CharPosition:
  LD DE,$0000             ; LD DE,nn: the column (E) and row (D)
  LD A,E
  CP $20
  CALL NC,NextRow
  PUSH DE
  CALL CellAddress
  CALL GlyphAddress
  PUSH DE
  CALL CopyGlyph
  POP DE
  CALL AttrAddress
CharAttr:
  LD A,$07                ; LD A,n: the attribute
  LD (DE),A
  POP HL
  INC L
  LD (CharPosition+1),HL
  POP HL
  INC HL
  JP PrintText

; column 0, the next row (24 back to 0)
;
; Used by the routine at PrintChar.
NextRow:
  LD E,$00
  INC D
  LD A,D
  CP $18
  RET C
  LD D,$00
  RET

; DE = the screen address of row D, column E
;
; Used by the routine at PrintChar.
CellAddress:
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $E0
  OR E
  LD E,A
  LD A,D
  AND $18
  OR $40
  LD D,A
  RET

; D = the attribute row of the screen address in DE
;
; Used by the routine at PrintChar.
AttrAddress:
  LD A,D
  RRCA
  RRCA
  RRCA
  OR $58
  LD D,A
  RET

; HL = Font + L * 8
;
; Used by the routine at PrintChar.
GlyphAddress:
  LD A,L
  RLCA
  RLCA
  RLCA
  LD H,A
  AND $F8
  LD L,A
  LD A,H
  AND $07
  ADD A,$FC
  LD H,A
  RET

; 8 bytes from HL down the character cell at DE
;
; Used by the routine at PrintChar.
CopyGlyph:
  LD B,$08
l_6F9B:
  LD A,(HL)
  LD (DE),A
  INC D
  INC L
  DJNZ l_6F9B
  RET

; ROM_FONT to Font + $100 with every row ORed with itself shifted right: a bold
; font
;
; Used by the routine at MenuLoop.
MakeFont:
  LD HL,ROM_FONT
  LD DE,Font+256
  LD BC,$0003
l_6FAB:
  LD A,(HL)
  RRCA
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  DJNZ l_6FAB
  DEC C
  JR NZ,l_6FAB
  RET

; the options' values into Text: YES / NOP for the toggles, the SHOOTING word
;
; Used by the routine at MenuLoop.
ShowValues:
  LD HL,InfiniteRounds
  LD DE,RoundsValue
  CALL YesNo
  LD HL,InfiniteLife
  LD DE,LifeValue
  CALL YesNo
  LD HL,SaturnsOption
  LD DE,SaturnsValue
  CALL YesNo
  LD HL,TurboOption
  LD DE,TurboValue
  CALL YesNo
  LD A,(ShootingOption)
  LD DE,ShootingValue
  LD C,$08
  LD HL,Normal
  OR A
  JR Z,l_6FF2
  DEC A
  LD HL,Disabled
  JR Z,l_6FF2
  LD HL,Channel
l_6FF2:
  LDIR
  RET

; "YES" or "NOP" (the byte at HL not 0 / 0) to the 3 characters at DE
;
; Used by the routine at ShowValues.
YesNo:
  LD A,(HL)
  LD BC,$0003
  LD HL,Yes
  OR A
  JR NZ,l_7002
  LD HL,Nop
l_7002:
  LDIR
  RET

; 1: INFINITE ROUNDS YES (at the start)
InfiniteRounds:
  DEFB $01

; 0: INFINITE LIFE NOP
InfiniteLife:
  DEFB $00

; ZYNAPS OPTIONS, items 1-7, the credits; the end mark; then the hidden lines
; (the texts: docs/texts/menu.md)
Text:
  DEFM $16,$00,$09,$10,"BZYNAPS OPTIONS",$16,$03,$04,$10,"E1. START MUSIC & EFFECTS",$16,$04,$04,"2. START ONLY "
  DEFM "EFFECTS",$16,$06,$04,$10,"G3. INFINITE ROUNDS...",$10,"F"
RoundsValue:
  DEFM "YES",$16,$07,$04,$10,"G4. TURBO LOADER......",$10,"F" ; item 3's YES /
                                                              ; NOP
TurboValue:
  DEFM "YES",$16,$09,$04,$10,"G5. SATURNS...........",$10,"F" ; item 4's
SaturnsValue:
  DEFM "YES",$16,$0A,$04,$10,"G6. SHOOTING....." ; item 5's
ShootingValue:
  DEFM "..NORMAL",$16,$0B,$04,$10,"G7. EFFECTS TIMER.......",$10,"F" ; item 6's 8
                                                                     ; characters
TimerDigit:
  DEFM "2",$16,$11,$08,$10,"CGAME ADAPTED BY:",$16,$12,$0B,$10,"EMIKE BLUM",$16,$14,$06,$10,"CMUSIC & FX MIXED BY:",$16,$15,$03,$10 ; item 7's
  DEFM "EJOHN UNDERWOOD & DANGEROUS",$16,$17,$02,$10,"GCOPYRIGHT (C)1997 ZX-MASTERS"                                                ; digit ("2"
                                                                                                                                    ; at the
                                                                                                                                    ; start)
TextEnd:
  DEFM $00,$0D,$04,$10,"A8. INFINITE LIFE.....",$10,"F" ; the zero that ends
                                                        ; the visible text: key
                                                        ; 0 writes $16 (AT 13,4
                                                        ; with the next two
                                                        ; bytes)
LifeValue:
  DEFM "NOP",$16,$0E,$04,$10,"AQ-P,A-S. SELECT LEVEL!!!",$00 ; the hidden item
                                                             ; 8's YES / NOP

; "YES"
Yes:
  DEFM "YES"

; "NOP"
Nop:
  DEFM "NOP"

; "..NORMAL"
Normal:
  DEFM "..NORMAL"

; ".CHANNEL"
Channel:
  DEFM ".CHANNEL"

; "DISABLED"
Disabled:
  DEFM "DISABLED"

; zeros to the end of the driver file
MenuSpare:
  DEFS $0241
