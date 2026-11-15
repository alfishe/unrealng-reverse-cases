; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The menu, the controls, DEFINE KEYS, the password
;
; Menu $9723 wipes the screen, draws the logo and the 15 menu strings, and waits in MenuLoop $9775 for 1-4 (Kempston,
; Interface 2, Cursor, keyboard), K (DEFINE KEYS), P (ENTER PASSWORD) or fire (start). The interrupt animates the logo
; and colours in MenuInterrupt $9899.
; --------------------------------------------------------------------------------------------------------------------

  ORG $9723

; The menu: wipe, logo, strings; MenuLoop until fire, then the play screen's
; panel and tune 3
;
; Witness: L1 19 (c1, door3, kind6, masks, play2, rzx- x8).
Menu:
  LD A,$FF
  LD (NotInPlay),A
  LD A,(HudSaved)
  AND A
  CALL Z,SaveHud
  XOR A
  LD (HudSaved),A
  CALL MenuWipe
  CALL ClearScreen
  LD HL,CharMap+$0270
  LD DE,CharMap+$0271
  LD BC,$0050
  LD (HL),$00
  LDIR
  LD HL,MenuLogo
  LD DE,$000B
  LD BC,$0A06
  CALL DrawGraphic
  LD HL,MenuBadge
  LD DE,$0613
  LD BC,$0201
  CALL DrawGraphic
  LD HL,Screen+4832
  LD B,$20
  OR $FF
l_9765:
  LD (HL),A
  INC L
  DJNZ l_9765
  LD HL,MenuBanner
  LD DE,$160A
  LD BC,$0C02
  CALL DrawGraphic

; MenuLoop
;
; Used by the routine at EnterPassword.
MenuLoop:
  CALL DrawMenu           ; draw the strings and the lit icon, HALT, read a key
  CALL ColourScroll
  LD A,$FF
  LD (MenuFlag),A
l_9780:
  HALT
  LD A,(ControlMethod)
  PUSH AF
  CALL ReadKeyCode
  CP $30
  JR NZ,l_9797
  CALL KempstonTest
  JR NZ,l_9797
  XOR A
  LD (ControlMethod),A
  JR l_97F7
l_9797:
  CP $31
  JR NZ,l_97AD
  LD HL,KeysIf2
  LD DE,KeysNow
  LD BC,$0005
  LDIR
  LD A,$01
  LD (ControlMethod),A
  JR l_97F7
l_97AD:
  CP $32
  JR NZ,l_97C3
  LD HL,KeysCursor
  LD DE,KeysNow
  LD BC,$0005
  LDIR
  LD A,$02
  LD (ControlMethod),A
  JR l_97F7
l_97C3:
  CP $33
  JR NZ,l_97D9
  LD HL,KeysUser
  LD DE,KeysNow
  LD BC,$0005
  LDIR
  LD A,$03
  LD (ControlMethod),A
  JR l_97F7
l_97D9:
  CP $62
  JR NZ,l_97FF
  CALL DefineKeys
  CALL ClearMenuArea
  LD A,$03
  LD (ControlMethod),A
  LD HL,KeysNow
  LD DE,KeysUser
  LD BC,$0005
  LDIR
  POP AF
  JP MenuLoop
l_97F7:
  LD L,A
  POP AF
  CP L
  CALL NZ,DrawMenu
  JR l_9800
l_97FF:
  POP AF
l_9800:
  LD A,$50
  CALL KeyPressed
  JP Z,EnterPassword
  CALL ReadControls
  BIT 4,A
  JP Z,l_9780
  LD A,$03
  LD (TuneRequest),A
  CALL ScreenWipe
  XOR A
  LD (MenuFlag),A
  LD HL,PlayPanel
  LD DE,$1200
  LD BC,$2006
  CALL DrawGraphic
  LD HL,PanelAttrs
  LD DE,Attributes+576
  LD BC,$00C0
  LDIR
  LD DE,Screen+4321
  LD B,$0A
l_9838:
  LD A,$20
  CALL PrintChar
  DJNZ l_9838
  XOR A
  LD (ScrollerLeft),A
  LD (ScrollerShift),A
  LD (MessageState+$0003),A
  LD (NotInPlay),A
  RET

; Wipe the attributes diagonally (PokeAttr)
;
; Witness: L1 19 (c1, door3, kind6, masks, play2, rzx- x8).
MenuWipe:
  LD E,$F8
l_984F:
  CALL MenuWipeStep
  HALT
  INC E
  LD A,E
  CP $3E
  JR NZ,l_984F
  RET

; One diagonal of the wipe
;
; Witness: L1 1330 (c1, door3, kind6, masks, play2, rzx- x8).
MenuWipeStep:
  PUSH DE
  PUSH AF
  LD D,$00
l_985E:
  PUSH DE
  LD A,$47
l_9861:
  CALL PokeAttr
  DEC E
  DEC A
  CP $3F
  JP NZ,l_9861
  POP DE
  DEC E
  INC D
  LD A,D
  CP $18
  JR NZ,l_985E
  POP AF
  POP DE
  RET

; Set the attribute at row D, column E to A when they are on the screen
;
; Witness: L1 323612 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
PokeAttr:
  EX AF,AF'
  LD A,E
  CP $20
  JR NC,l_9897
  LD A,D
  CP $18
  JR NC,l_9897
  PUSH HL
  LD HL,Attributes
  SRL D
  RR L
  SRL D
  RR L
  SRL D
  RR L
  ADD HL,DE
  LD D,A
  EX AF,AF'
  LD (HL),A
  POP HL
  RET
l_9897:
  EX AF,AF'
  RET

; The menu's interrupt: the logo's raster colours, the lit control icon, the
; border bars, the colour scroll
;
; Witness: L1 16790 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
MenuInterrupt:
  CALL LogoRaster
  CALL ColourScroll
  LD A,$07
  LD HL,CharMap+$0040
  LD DE,Attributes+11
l_98A7:
  EX AF,AF'
  LD BC,$000A
  LDIR
  LD BC,$0046
  ADD HL,BC
  EX DE,HL
  LD BC,$0016
  ADD HL,BC
  EX DE,HL
  EX AF,AF'
  DEC A
  JR NZ,l_98A7
  LD BC,$01CC
  LD A,(MachineFlag)
  AND A
  JR Z,l_98C7
  LD BC,$01AF
l_98C7:
  DEC BC
  LD A,B
  OR C
  JR NZ,l_98C7
  LD A,(MenuColourCount)
  INC A
  LD (MenuColourCount),A
  LD HL,MenuColours
  AND $0F
  LD E,A
  LD D,$00
  ADD HL,DE
  LD C,(HL)
  LD A,(ControlMethod)
  LD L,A
  ADD A,A
  ADD A,L
  LD L,A
  LD H,$00
  LD DE,ControlIconPlaces
  ADD HL,DE
  LD D,(HL)
  INC HL
  LD E,(HL)
  LD A,C
  CALL PokeAttr
  INC E
  CALL PokeAttr
  INC D
  CALL PokeAttr
  DEC E
  CALL PokeAttr
  LD A,$04
  OUT ($FE),A
  LD BC,$0057
l_9904:
  DEC BC
  LD A,B
  OR C
  JR NZ,l_9904
  XOR A
  OUT ($FE),A
  LD BC,$0007
l_990F:
  DEC BC
  LD A,B
  OR C
  JR NZ,l_990F
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD A,$04
  OUT ($FE),A
  LD BC,$002A
l_9921:
  DEC BC
  LD A,B
  OR C
  JR NZ,l_9921
  NOP
  NOP
  NOP
  XOR A
  OUT ($FE),A
  JP l_9F2E

; Clear the bitmap and the attributes
;
; Witness: L1 19 (c1, door3, kind6, masks, play2, rzx- x8).
ClearScreen:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1800
  LD (HL),$00
  LDIR
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02C0
  LD (HL),$00
  LDIR
  LD (HL),$20
  LD BC,$003F
  LDIR
  RET

; Colour the logo line by line (LDI from the buffer at $F0CA in time with the
; beam)
;
; Witness: L1 16790 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
LogoRaster:
  LD BC,$021F
l_9954:
  DEC BC
  LD A,B
  OR C
  JR NZ,l_9954
  NOP
  NOP
  NOP
  LD DE,Attributes+11
  LD HL,CharMap+$004A
  LD A,$07
l_9964:
  EX AF,AF'
  LD A,$07
  LD C,$FF
  LD B,E
l_996A:
  LD E,B
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
  NOP
  NOP
  NOP
  NOP
  DEC A
  JP NZ,l_996A
  LD A,E
  ADD A,$16
  LD E,A
  PUSH DE
  LD DE,$000A
  ADD HL,DE
  POP DE
  LD A,$08
l_9993:
  DEC A
  JR NZ,l_9993
  EX AF,AF'
  DEC A
  JR NZ,l_9964
  XOR A
  OUT ($FE),A
  RET

; HL = the screen address of character row D, column E
;
; Witness: L1 1013 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
ScreenAddr:
  LD HL,Screen
  LD A,D
  AND $18
  OR H
  LD H,A
  LD A,D
  AND $07
  LD D,A
  SRL D
  RR L
  SRL D
  RR L
  SRL D
  RR L
  ADD HL,DE
  RET

; Draw B x C characters from HL at row D, column E
;
; Witness: L1 351 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
DrawGraphic:
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH HL
  CALL ScreenAddr
  LD A,$20
  SUB B
  LD (l_99CE+$0011),A
  LD A,B
  LD (l_99E7+$0001),A
  POP DE
l_99CA:
  PUSH BC
  LD B,$04
  LD C,H
l_99CE:
  LD A,(DE)
  INC DE
  LD (HL),A
  INC H
  LD A,(DE)
  INC DE
  LD (HL),A
  INC H
  DJNZ l_99CE
  LD H,C
  INC L
  POP BC
  DJNZ l_99CA
  LD A,L
  ADD A,$00
  LD L,A
  JR NC,l_99E7
  LD A,H
  ADD A,$08
  LD H,A
l_99E7:
  LD B,$00
  DEC C
  JR NZ,l_99CA
  POP BC
  POP DE
  POP HL
  RET

; The menu's logo, 10 x 6 characters (Menu draws it at row 0, column 11)
MenuLogo:
  INCBIN "res/screens/menu-logo.bin",$0000,480

; A 2 x 1 picture drawn at row 6, column 19
MenuBadge:
  INCBIN "res/screens/menu-badge.bin",$0000,16

; A 12 x 2 picture drawn at row 22, column 10
MenuBanner:
  INCBIN "res/screens/menu-banner.bin",$0000,192

; Keep screen rows 18-23 at $F600 and their attributes at $FC64 (the play
; panel, restored at the start)
;
; Witness: L1 18 (door3, kind6, masks, play2, rzx- x8).
SaveHud:
  LD HL,Screen+4160
  LD DE,PlayPanel
  LD C,H
l_9CA7:
  LD B,$08
l_9CA9:
  LD A,(HL)
  INC H
  LD (DE),A
  INC DE
  DJNZ l_9CA9
  LD H,C
  INC L
  JR NZ,l_9CA7
  LD HL,Attributes+576
  LD DE,PanelAttrs
  LD BC,$00C0
  LDIR
  RET

; Print the bit-7-terminated string at HL at row D, column E
;
; Witness: L1 601 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).
PrintString:
  PUSH BC
  PUSH DE
  PUSH HL
  CALL ScreenAddr
  POP BC
  EX DE,HL
l_9CC7:
  LD A,(BC)
  CALL PrintChar
  LD A,(BC)
  AND $80
  JR NZ,l_9CD3
  INC BC
  JR l_9CC7
l_9CD3:
  POP DE
  INC BC
  LD H,B
  LD L,C
  POP BC
  RET

; Print character A (5-row glyph, attribute $47)
;
; Witness: L1 37418 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).
PrintChar:
  PUSH BC
  PUSH HL
  CALL CharGlyph
  JR NZ,l_9CFE
  LD C,D
  LD B,$05
  XOR A
  LD (DE),A
  INC D
  LD (DE),A
  INC D
l_9CE8:
  LD A,(HL)
  INC HL
  LD (DE),A
  INC D
  DJNZ l_9CE8
  XOR A
  LD (DE),A
  LD D,C
  LD L,E
  LD A,D
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD (HL),$47
  INC E
l_9CFE:
  POP HL
  POP BC
  RET

; The menu rows and columns of the lit control icons
ControlIconPlaces:
  DEFB $07,$00,$41,$09,$00,$44,$0B,$00
  DEFB $42,$0D,$00,$45,$0F,$00,$43,$11
  DEFB $00,$46,$13,$00,$45
Hiscore:
  DEFB $00,$00,$00,$00    ; the high score, 4 BCD bytes

; The 15 menu strings, the high score and the control icons
;
; Witness: L1 39 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).
DrawMenu:
  LD HL,MenuStrings
  LD B,$0F
l_9D1F:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  CALL PrintString
  DJNZ l_9D1F
  LD DE,$1418
  CALL ScreenAddr
  EX DE,HL
  LD HL,Hiscore
  LD B,$04
l_9D34:
  LD A,(HL)
  CALL PrintBcd
  INC HL
  DJNZ l_9D34
  XOR A
  LD HL,ControlIconPlaces
l_9D3F:
  LD D,(HL)
  INC HL
  LD E,(HL)
  INC HL
  PUSH AF
  PUSH HL
  LD HL,ControlIcons
  LD C,A
  LD B,$00
  ADD HL,BC
  LD BC,$0202
  CALL DrawGraphic
  POP HL
  LD A,(HL)
  INC HL
  CALL PokeAttr
  INC E
  CALL PokeAttr
  INC D
  CALL PokeAttr
  DEC E
  CALL PokeAttr
  POP AF
  ADD A,$20
  CP $E0
  JR NZ,l_9D3F
  RET

; The 15 menu strings: two place bytes (column, then row: $18, $09 for
; PROGRAM), the text with bit 7 on the last character
;
; Includes "P.ENTER PASSWOID" as the bytes have it (the original's typo; the
; screen shows it, work/stage1/c1).
MenuStrings:
  INCBIN "res/texts/menu.bin",$0000,164

; Clear the menu's text area
;
; Witness: L1 12 (c1, cheat, play2).
ClearMenuArea:
  LD HL,Screen+4256
  LD D,$00
l_9E15:
  DEC L
  LD A,L
  CP $FF
  JR NZ,l_9E1F
  LD A,H
  SUB $08
  LD H,A
l_9E1F:
  LD E,H
  LD (HL),D
  INC H
  LD (HL),D
  INC H
  LD (HL),D
  INC H
  LD (HL),D
  INC H
  LD (HL),D
  INC H
  LD (HL),D
  INC H
  LD (HL),D
  INC H
  LD (HL),D
  LD H,E
  LD A,L
  CP $E0
  JR NZ,l_9E15
  LD A,H
  CP $40
  JR NZ,l_9E15
  RET

; DEFINE KEYS: FIRE, UP, DOWN, LEFT, RIGHT, each a key not taken yet
;
; Witness: L1 1 (c1).
DefineKeys:
  XOR A
  LD (KeysNow),A
  LD (KeysNow+$0001),A
  LD (KeysNow+$0002),A
  LD (KeysNow+$0003),A
  LD (KeysNow+$0004),A
  CALL ClearMenuArea
  LD HL,DefinePrompts+$0015
  LD DE,$080A
  CALL PrintString
  LD HL,DefinePrompts
  LD E,$10
  CALL AskKey
  LD (KeysNow),A
  CALL AskKey
  LD (KeysNow+$0001),A
  CALL AskKey
  LD (KeysNow+$0002),A
  CALL AskKey
  LD (KeysNow+$0003),A
  CALL AskKey
  LD (KeysNow+$0004),A
  RET

; Wait for a key that is not one of the keys chosen so far
;
; Witness: L1 5 (c1).
AskKey:
  CALL PrintString
  PUSH HL
l_9E7F:
  CALL WaitKey
  EX AF,AF'
  LD HL,KeysNow
  LD B,$05
l_9E88:
  CP (HL)
  JR Z,l_9E7F
  INC HL
  DJNZ l_9E88
  POP HL
  RET

; "FIRE", "UP", "DOWN", "LEFT", "RIGHT" and "Press"
DefinePrompts:
  DEFM "FIR",$C5,"UP ",$A0,"DOW",$CE,"LEF",$D4,"RIGH",$D4,"Pres",$F3,"GF",$07,$06,$FF

; The menu's colour bars, a random sequence a cycle
;
; Witness: L1 16815 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
ColourScroll:
  LD DE,CharMap+$0040
  LD HL,CharMap+$0270
  LD B,$38
l_9EB7:
  PUSH HL
  LD C,$14
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
  POP HL
  INC HL
  DJNZ l_9EB7
  RET

; The colour sequences of ColourScroll
ColourSequences:
  DEFB $D5,$9E,$FF,$E6,$9E,$EF,$9E,$F8
  DEFB $9E,$01,$9F,$0A,$9F,$13,$9F,$1C
  DEFB $9F,$25,$9F,$01,$03,$04,$06,$07
  DEFB $02,$03,$01,$FF,$05,$04,$03,$01
  DEFB $02,$03,$05,$06,$FF,$01,$02,$03
  DEFB $07,$06,$04,$05,$06,$FF,$07,$06
  DEFB $05,$04,$01,$02,$03,$01,$FF,$04
  DEFB $06,$03,$01,$01,$03,$06,$04,$FF
  DEFB $04,$05,$01,$03,$02,$07,$05,$01
  DEFB $FF,$03,$02,$01,$04,$05,$03,$01
  DEFB $02,$FF,$02,$07,$05,$04,$01,$03
  DEFB $02,$01,$FF

; l_9F2E
;
; Used by the routine at MenuInterrupt.
l_9F2E:
  LD HL,CharMap+$0271
  LD DE,CharMap+$0270
  LD BC,$004B
  LDIR
  LD HL,(ColourSequences)
  LD A,(HL)
  CP $FF
  JR NZ,l_9F53
  CALL Random
  AND $07
  ADD A,A
  LD L,A
  LD H,$00
  LD BC,$9ED6
  ADD HL,BC
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(HL)
l_9F53:
  OR $40
  LD (DE),A
  CALL Random
  CP $8C
  JR C,l_9F5E
  INC HL
l_9F5E:
  LD (ColourSequences),HL
  RET

; Z when port $1F reads with bits 5-7 clear 256 times (a Kempston interface)
;
; Witness: L1 5 (c1, play2, rzx-08000, rzx-28000).
KempstonTest:
  LD B,$00
l_9F64:
  IN A,($1F)
  AND $E0
  RET NZ
  DJNZ l_9F64
  XOR A
  RET

; MAYHEM, TRANSMOGRIFY, VALKYR entered; $9F70 PETALS OF DOOM (all three)
PasswordFlags:
  DEFB $00,$00,$00,$00
PasswordBuffer:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the 16 key codes typed, 0 at the end
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00

; ENTER PASSWORD: 16 keys, compared with the four passwords (key codes)
;
; Each matching password sets its flag; PETALS OF DOOM sets $9F70 only when the
; other three are set (the AND at $9FE9-$9FF2). Witness: work/stage2/rec/play2
; types the four passwords in order: each compare matches once, the four flags
; are written once each, and the next NewGame's PasswordPods $ACBC writes the
; open blocks $1E/$1F for all four doors (ACD1 run 4 times a call, ACC9 never).
; The flags let Matt into a door (MattWalk $B48D-$B4BB: room 0, screen 5,
; standing on character $1C, down held).
;
; Witness: L1 5 (cheat, play2).
EnterPassword:
  CALL ClearMenuArea
  LD HL,MenuStrings+$0084
  LD DE,$0809
  CALL PrintString
  LD HL,PasswordDots
  LD DE,$0A08
  CALL PrintString
  CALL ScreenAddr
  EX DE,HL
  LD HL,PasswordBuffer
  LD C,$00
l_9FA0:
  CALL WaitKey
  CP $40
  JR Z,l_9FA0
  CP $0D
  JR Z,l_9FB6
  CALL PrintChar
  EX AF,AF'
  LD (HL),A
  INC HL
  INC C
  BIT 4,C
  JR Z,l_9FA0
l_9FB6:
  LD (HL),$00
  JR l_9FBA
l_9FBA:
  LD HL,Passwords
  CALL StringMatch
  JR NZ,l_9FC7
  LD A,$FF
  LD (PasswordFlags),A
l_9FC7:
  LD HL,Passwords+$0007
  CALL StringMatch
  JR NZ,l_9FD4
  LD A,$FF
  LD (PasswordFlags+$0001),A
l_9FD4:
  LD HL,Passwords+$0014
  CALL StringMatch
  JR NZ,l_9FE1
  LD A,$FF
  LD (PasswordFlags+$0002),A
l_9FE1:
  LD HL,Passwords+$001B
  CALL StringMatch
  JR NZ,l_9FF3
  LD HL,PasswordFlags
  LD A,(HL)
  INC HL
  AND (HL)
  INC HL
  AND (HL)
  INC HL
  LD (HL),A
l_9FF3:
  CALL ClearMenuArea
  JP MenuLoop

; The 16 dots EnterPassword prints at row $0A, column $08
PasswordDots:
  DEFM "...............",$AE

; MAYHEM, TRANSMOGRIFY, VALKYR, PETALS OF DOOM as key codes, each 0-terminated
;
; Key code = row x 16 + bit (row 0 = port $FEFE ... row 7 = $7FFE).
; src/res/texts/passwords.txt has them as letters.
Passwords:
  INCBIN "res/texts/passwords.bin",$0000,42

; Z when the buffer at HL equals the 0-terminated code string at DE
;
; Witness: L1 20 (cheat, play2).
StringMatch:
  LD DE,PasswordBuffer
l_A036:
  LD A,(DE)
  CP (HL)
  RET NZ
  LD A,(HL)
  AND A
  RET Z
  INC DE
  INC HL
  JR l_A036

; Close the screen from the top and the bottom, one line pair a HALT (88 steps)
;
; Witness: L1 21 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).
ScreenWipe:
  LD HL,Screen+6048
  EXX
  LD HL,Screen
  LD B,$58
l_A049:
  HALT
  EXX
  CALL ClearLine
  DEC H
  LD A,H
  AND $07
  CP $07
  JR NZ,l_A060
  LD A,L
  SUB $20
  LD L,A
  JR C,l_A060
  LD A,H
  ADD A,$08
  LD H,A
l_A060:
  EXX
  CALL ClearLine
  INC H
  LD A,H
  AND $07
  JR NZ,l_A074
  LD A,L
  ADD A,$20
  LD L,A
  JR C,l_A074
  LD A,H
  SUB $08
  LD H,A
l_A074:
  DJNZ l_A049

; Clear one pixel line
;
; Witness: L1 3717 (c1, cheat, door, door3, kind6, masks, play2, rzx- x8).
ClearLine:
  LD E,L
  LD D,$20
l_A079:
  LD (HL),$00
  INC L
  DEC D
  JR NZ,l_A079
  LD L,E
  RET

; Interface 2 keys (fire, up, down, left, right): 0 9 8 6 7
KeysIf2:
  DEFB $40,$41,$42,$44,$43
KeysCursor:
  DEFB $40,$43,$44,$34,$42 ; Cursor keys: 0 7 6 5 8
KeysUser:
  DEFB $70,$50,$61,$20,$21 ; the keyboard set (DEFINE KEYS): SPACE P L Q W as
                           ; loaded

; NZ when key code A is down (patches its own port and bit)
;
; Witness: L1 103894 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).
KeyPressed:
  PUSH BC
  PUSH AF
  LD B,A
  RRCA
  AND $38
  OR $80
  LD (KeyPressed+$001A),A
  LD A,B
  RLCA
  RLCA
  RLCA
  AND $38
  OR $41
  LD (KeyPressed+$001F),A
  LD BC,$FFFE
  RES 0,B
  IN C,(C)
  POP AF
  BIT 0,C
  POP BC
  RET

; The first key down as a key code, or none
;
; Witness: L1 34726 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
ScanKeyboard:
  LD B,$7F
l_A0B4:
  LD C,$FE
  IN C,(C)
  LD A,C
  AND $1F
  CP $1F
  JR NZ,l_A0C7
  RRC B
  JR C,l_A0B4
  OR $FF
  LD B,A
  RET
l_A0C7:
  XOR A
  RET

; A key code from ScanKeyboard
;
; Witness: L1 34726 (c1, cheat, door, door3, kind6, masks, play2, rzx- x9).
ReadKeyCode:
  PUSH BC
  CALL ScanKeyboard
  JR Z,l_A0D1
  POP BC
  RET
l_A0D1:
  SRL C
  JR NC,l_A0D8
  INC A
  JR l_A0D1
l_A0D8:
  SRL B
  JR NC,l_A0E0
  ADD A,$10
  JR l_A0D8
l_A0E0:
  LD C,A
  XOR A
  LD A,C
  POP BC
  RET

; Wait for a key: A the character, A' the key code
;
; Witness: L1 2470 (c1, cheat, play2).
WaitKey:
  CALL ReadKeyCode
  JR Z,WaitKey
l_A0EA:
  CALL ReadKeyCode
  JR NZ,l_A0EA
  JR KeyCodeToChar

; The 40 keys' characters, by key code
KeyChars:
  DEFB $40,$5A,$58,$43,$56,$41,$53,$44
  DEFB $46,$47,$51,$57,$45,$52,$54,$31
  DEFB $32,$33,$34,$35,$30,$39,$38,$37
  DEFB $36,$50,$4F,$49,$55,$59,$0D,$4C
  DEFB $4B,$4A,$48,$20,$40,$4D,$4E,$42

; A = the character of key code A
;
; Witness: L1 271 (c1, cheat, door, door3, play2, rzx- x5).
KeyCodeToChar:
  PUSH HL
  PUSH DE
  LD E,A
  EX AF,AF'
  LD A,E
  RRCA
  RRCA
  RRCA
  RRCA
  AND $07
  LD L,A
  ADD A,A
  ADD A,A
  ADD A,L
  LD L,A
  LD A,E
  AND $07
  ADD A,L
  LD L,A
  LD H,$00
  LD DE,KeyChars
  ADD HL,DE
  LD A,(HL)
  POP DE
  POP HL
  RET

; this pass's controls: bit 0 right, 1 left, 2 down, 3 up, 4 fire
Controls:
  DEFB $00
ControlsLast:
  DEFB $00                ; the last pass's
ControlMethod:
  DEFB $01                ; 0 Kempston, 1 Interface 2, 2 Cursor, 3 keyboard

; Controls from the Kempston port or the chosen keys; right beats left, down
; beats up
;
; Witness: L1 27243 (c1, cheat, door, door3, kind6, masks, play2, rzx- x10).
ReadControls:
  LD A,(Controls)
  LD (ControlsLast),A
  LD A,(ControlMethod)
  AND A
  JP NZ,l_A155
  IN A,($1F)
  AND $1F
  LD (Controls),A
  RET

; The five keys in use (copied from KeysIf2, KeysCursor or KeysUser)
KeysNow:
  DEFB $40,$41,$42,$44,$43

; l_A155
;
; Used by the routine at ReadControls.
l_A155:
  PUSH BC
  LD C,$00
  LD A,(KeysNow+$0004)
  CALL KeyPressed
  JR NZ,l_A164
  SET 0,C
  JR l_A16E
l_A164:
  LD A,(KeysNow+$0003)
  CALL KeyPressed
  JR NZ,l_A16E
  SET 1,C
l_A16E:
  LD A,(KeysNow+$0002)
  CALL KeyPressed
  JR NZ,l_A17A
  SET 2,C
  JR l_A184
l_A17A:
  LD A,(KeysNow+$0001)
  CALL KeyPressed
  JR NZ,l_A184
  SET 3,C
l_A184:
  LD A,(KeysNow)
  CALL KeyPressed
  JR NZ,l_A18E
  SET 4,C
l_A18E:
  LD A,C
  LD (Controls),A
  POP BC
  RET
