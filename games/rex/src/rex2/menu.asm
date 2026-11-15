; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The title, the menu, the code from part 1, DEFINE KEYS
; --------------------------------------------------------------------------------------------------------------------

  ORG $DAC0

; The title and menu: the title on, the five menu texts, then MenuCode (the
; code first, then the keys 1-4)
;
; Changed from REX 1's TitleMenu $DAC0 (src/game/menu.asm).
;
; Witness: L1 1 (c2).
TitleMenu:
  LD A,$00
  OUT ($FE),A
  LD DE,$4000
  LD HL,TitleScreen
  LD BC,$1B00
  LDIR
  LD B,$05
  LD IX,MenuTexts
  CALL PrintBoxed
  LD DE,TitleScreen
  LD HL,$4000
  LD BC,$1B00
  LDIR

; The title on, the code (EnterCode), the title again; then the keys 1-4:
; DEFINE, KEMPSTON, CURSOR, SINCLAIR
;
; Witness: L1 2 (c2).
MenuCode:
  LD DE,$4000
  LD HL,TitleScreen
  LD BC,$1B00
  LDIR
  CALL EnterCode
; This entry point is used by the routine at MenuAgain.
l_DAF1:
  LD DE,$4000
  LD HL,TitleScreen
  LD BC,$1B00
  LDIR
MenuWait:
  LD BC,$F7FE             ; the keys 1-4
  IN A,(C)
  BIT 3,A
  JP Z,ChooseSinclair
  LD BC,$F7FE
  IN A,(C)
  BIT 2,A
  JP Z,ChooseCursor
  LD BC,$F7FE
  IN A,(C)
  BIT 1,A
  JP Z,ChooseKempston
  LD BC,$F7FE
  IN A,(C)
  BIT 0,A
  JP Z,DefineKeys
  JP MenuWait

; INPUT YOUR CODE: the 13 characters unscrambled, each 9 - digit, the checksum;
; a good code sets the score, lives, weapons, shield and bombs of part 1's end;
; a bad one INVALID CODE, the menu
;
; Witness: L1 2 (c2).
EnterCode:
  CALL ReadCode
  LD A,(CodeTexts+$005A)
  LD (CodeTexts+$0067),A
  LD A,(CodeTexts+$004F)
  LD (CodeTexts+$0068),A
  LD A,(CodeTexts+$0053)
  LD (CodeTexts+$0069),A
  LD A,(CodeTexts+$0057)
  LD (CodeTexts+$006A),A
  LD A,(CodeTexts+$0055)
  LD (CodeTexts+$006B),A
  LD A,(CodeTexts+$0051)
  LD (CodeTexts+$006C),A
  LD A,(CodeTexts+$004E)
  LD (CodeTexts+$006D),A
  LD A,(CodeTexts+$0052)
  LD (CodeTexts+$006E),A
  LD A,(CodeTexts+$0054)
  LD (CodeTexts+$006F),A
  LD A,(CodeTexts+$0050)
  LD (CodeTexts+$0070),A
  LD A,(CodeTexts+$0059)
  LD (CodeTexts+$0071),A
  LD A,(CodeTexts+$0056)
  LD (CodeTexts+$0072),A
  LD A,(CodeTexts+$0058)
  LD (CodeTexts+$0073),A
  LD A,(CodeTexts+$005C)
  LD (CodeTexts+$0074),A
  LD A,(CodeTexts+$005D)
  LD (CodeTexts+$0075),A
  LD A,(CodeTexts+$005B)
  LD (CodeTexts+$0076),A
  LD B,$0D
  LD E,$00
  LD (Temp1),HL
  LD HL,CodeTexts+$0067
CodeDigitsLoop:
  LD C,(HL)               ; each digit: 9 - digit, the checksum summed
  LD A,$39
  SUB C
  ADD A,$30
  LD (HL),A
  SUB $30
  ADD A,E
  LD E,A
  INC HL
  DJNZ CodeDigitsLoop
  LD HL,CodeTexts+$004E
  LD B,$0D
  LD DE,$0000
CodeSumLoop:
  LD A,(HL)               ; the sum of the 13 typed digits
  SUB $30
  ADD A,E
  LD E,A
  INC HL
  DJNZ CodeSumLoop
  LD (CodeSum),DE
  LD A,E
  OR A
  JP Z,CodeBad
  LD A,$30
  LD (Digits),A
  LD (Digits+$0001),A
  LD A,(CodeTexts+$0076)
  LD (Digits+$0004),A
  LD A,(CodeTexts+$0074)
  LD (Digits+$0002),A
  LD A,(CodeTexts+$0075)
  LD (Digits+$0003),A
  CALL DigitsValue
  LD DE,(CodeSum)
  AND A
  SBC HL,DE
  JP NZ,CodeBad
  LD A,(CodeTexts+$0067)
  LD (Digits),A
  LD A,(CodeTexts+$0068)
  LD (Digits+$0001),A
  LD A,(CodeTexts+$0069)
  LD (Digits+$0002),A
  LD A,(CodeTexts+$006A)
  LD (Digits+$0003),A
  LD A,(CodeTexts+$006B)
  LD (Digits+$0004),A
  CALL DigitsValue
  LD (CodeScore),HL
  LD A,(CodeTexts+$006C)
  SUB $30
  LD (CodeLives),A
  LD A,(CodeTexts+$006D)
  SUB $30
  LD (HasDoubleFire),A
  LD A,(CodeTexts+$006E)
  SUB $30
  LD (HasLaser),A
  LD A,(CodeTexts+$006F)
  SUB $30
  LD (HasMultiple),A
  LD A,(CodeTexts+$0070)
  SUB $30
  LD (HasSpray),A
  LD A,$30
  LD (Digits),A
  LD (Digits+$0001),A
  LD (Digits+$0002),A
  LD A,(CodeTexts+$0071)
  LD (Digits+$0003),A
  LD A,(CodeTexts+$0072)
  LD (Digits+$0004),A
  CALL DigitsValue
  LD (CodeShield),HL
  LD A,(CodeTexts+$0073)
  SUB $30
  LD (CodeBombs),A
  CP $04
  JP NC,CodeBad
  RET
CodeBad:
  LD IX,CodeTexts         ; INVALID CODE, TRY AGAIN, back to the menu
  LD B,$02
  CALL PrintBoxed
  CALL ScanKey
  POP BC
  JP MenuCode

; HL = the five ASCII digits at CodeDigits $A23F as a number
;
; Witness: L1 4 (c2).
DigitsValue:
  LD HL,Digits
  LD B,$05
DigitsLoop:
  LD A,(HL)               ; each digit: ASCII to value
  SUB $30
  LD (HL),A
  INC HL
  DJNZ DigitsLoop
  LD HL,$0000
  LD IX,DigitTemp+$0001
  LD DE,$2710
  CALL AddDigit
  LD DE,$03E8
  CALL AddDigit
  LD DE,$0064
  CALL AddDigit
  LD DE,$000A
  CALL AddDigit
  LD DE,$0001
  CALL AddDigit
  RET

; HL + DE x the next digit
;
; Witness: L1 20 (c2).
AddDigit:
  INC IX
  LD A,(IX+$00)
  OR A
  RET Z
  LD B,A
AddDigitLoop:
  ADD HL,DE               ; HL + DE, digit times
  DJNZ AddDigitLoop
  RET

; The code panel's texts: INVALID CODE, TRY AGAIN, INPUT YOUR CODE, USE CAPS TO
; DELETE:, the blank input lines
CodeTexts:
  INCBIN "res/texts/rex2-code.bin",$0000,120

; Read the code: up to 16 keys echoed with a "?" cursor; CAPS ("-") deletes,
; ENTER ("+") ends
;
; Witness: L1 2 (c2).
ReadCode:
  LD HL,CodeTexts+$004D
  LD DE,CodeTexts+$004E
  LD BC,$0010
  LD (HL),$20
  LDIR
  LD HL,CodeTexts+$004D
  LD (HL),$20
  INC HL
  LD (HL),$3F
  INC HL
  LD (HL),$00
  LD IX,CodeTexts+$0020
  LD B,$03
  CALL PrintBoxed
  XOR A
  LD (CodeLength),A
  LD HL,CodeTexts+$004E
  LD (BoxAttr),HL
  JR ReadCodeWait
ReadCodeKey:
  LD A,(CodeLength)       ; a key typed: stored, echoed
  CP $10
  JP Z,ReadCodeWait
  LD A,(CodeKey)
  LD HL,(BoxAttr)
  LD (HL),A
  INC HL
  LD (BoxAttr),HL
  LD HL,CodeLength
  INC (HL)
  LD HL,(BoxAttr)
  LD (HL),$3F
  INC HL
  LD (HL),$20
  INC HL
  LD (HL),$00
  LD IX,CodeTexts+$004A
  LD B,$01
  CALL PrintTextHL
ReadCodeWait:
  CALL ScanKey            ; the next key
  CP $2D
  JR Z,CodeDelete
  CP $2B
  JR Z,CodeDone
  LD (CodeKey),A
  JR ReadCodeKey

; Code: CAPS: one character back (none typed: nothing), then the next key
;
; LD A,($A260): OR A: JR Z,$DD5F: LD HL,($A238): DEC HL: LD ($A238),HL: LD
; HL,$A260: DEC (HL): JR $DD52. No recording deleted a character (known only
; from the code); the kit keeps it as bytes because a recording reads these
; bytes as data.
CodeDelete:
  DEFB $3A,$60,$A2,$B7,$28,$D6,$2A,$38,$A2,$2B,$22,$38,$A2,$21,$60,$A2,$35,$18,$C9

; ENTER: RET
;
; Witness: L1 2 (c2).
CodeDone:
  RET

; DEFINE: wait for a key not SPACE, not H and not taken; its port into
; DefinePort, its BIT opcode into DefineBit, its character in A
;
; As REX 1's ScanKey $DBAE (src/game/menu.asm).
;
; Witness: L1 35 (c2).
ScanKey:
  PUSH IY
ScanKeyRow:
  LD IX,KeyPorts          ; each half-row
  LD IY,KeyNames
  LD B,$08
ScanKeyBit:
  PUSH BC
  LD C,(IX+$00)
  LD B,(IX+$01)
  LD (DefinePort),BC
  IN A,(C)
  LD B,$05
  LD E,$00
  LD D,A
ScanKeyShift:
  RRCA
  JP NC,ScanKeyFound
  INC E
  DJNZ ScanKeyShift
  POP BC
  INC IX
  INC IX
  LD DE,$0005
  ADD IY,DE
  DJNZ ScanKeyBit
  JP ScanKeyRow
ScanKeyFound:
  POP BC                  ; a key down: its port and bit kept
  PUSH DE
ScanKeyRelease:
  LD C,(IX+$00)           ; wait until the key is let go
  LD B,(IX+$01)
  IN A,(C)
  CP D
  JP Z,ScanKeyRelease
  LD A,E
  SLA A
  SLA A
  SLA A
  LD D,$47
  ADD A,D
  LD (DefineBit),A
  POP DE
  LD D,$00
  ADD IY,DE
  LD A,(IY+$00)
  POP IY
  CP $20
  JP Z,ScanKey
  CP $48
  JP Z,ScanKey
  LD IY,DefineTaken
  LD B,$05
ScanKeyTaken:
  CP (IY+$00)             ; a key already chosen?
  JP Z,ScanKey
  INC IY
  DJNZ ScanKeyTaken
  LD IY,DefineTaken
  RET

; the characters of the keys chosen so far
DefineTaken:
  DEFB $00,$00,$00,$00,$00,$00

; Code: 1: DEFINE: PRESS a key for each of UP, DOWN, LEFT, RIGHT, FIRE
; (ScanKey, the setters), then the confirm
;
; Part 1's DefineKeys moved by $C5: DefineTaken cleared, PRESS, then for each
; control ScanKey and its setter (SetUp $A65D, SetDown $A676, SetLeft $A62B,
; SetRight $A644, SetFire $A612), ControlXor 0 and the confirm. No part 2
; recording chose DEFINE (known only from the code); the kit keeps it as bytes
; because recording c2 reads $DC2A-$DE45 once at frames 22596-22597 (the reader
; is not identified) and the rest lies in CellIndexMap's span.
DefineKeys:
  DEFB $21,$00,$00,$22,$13,$DE,$22,$15,$DE,$22,$17,$DE,$FD,$21,$13,$DE
  DEFB $DD,$21,$60,$E0,$06,$06,$FD,$E5,$CD,$E6,$A2,$FD,$E1,$01,$FE,$F7
  DEFB $ED,$78,$CB,$47,$CA,$36,$DE,$DD,$21,$9B,$E0,$06,$01,$FD,$E5,$CD
  DEFB $87,$A4,$FD,$E1,$CD,$9B,$DD,$FD,$77,$00,$CD,$B1,$DF,$21,$8F,$48
  DEFB $CD,$BD,$DF,$CD,$5D,$A6,$DD,$21,$A3,$E0,$06,$01,$FD,$E5,$CD,$87
  DEFB $A4,$FD,$E1,$CD,$9B,$DD,$FD,$77,$01,$CD,$B1,$DF,$21,$AF,$48,$CD
  DEFB $BD,$DF,$CD,$76,$A6,$DD,$21,$AD,$E0,$06,$01,$FD,$E5,$CD,$87,$A4
  DEFB $FD,$E1,$CD,$9B,$DD,$FD,$77,$02,$CD,$B1,$DF,$21,$CF,$48,$CD,$BD
  DEFB $DF,$CD,$2B,$A6,$DD,$21
CellIndexMap:
  DEFB $B7,$E0,$06,$01,$FD,$E5,$CD,$87,$A4,$FD,$E1,$CD,$9B,$DD,$FD,$77 ; after the
  DEFB $03,$CD,$B1,$DF,$21,$EF,$48,$CD,$BD,$DF,$CD,$44,$A6,$DD,$21,$C2 ; menu: each
  DEFB $E0,$06,$01,$FD,$E5,$CD,$87,$A4,$FD,$E1,$CD,$9B,$DD,$FD,$77,$04 ; grid
  DEFB $CD,$B1,$DF,$21,$0F,$50,$CD,$BD,$DF,$CD,$12,$A6,$AF,$32,$47,$A2 ; cell's
  DEFB $DD,$21,$4C,$E0,$C3,$93,$DF                                     ; index into
                                                                       ; SceneryCellList
                                                                       ; (DrawRoom),
                                                                       ; over this
                                                                       ; code and
                                                                       ; the menu's
                                                                       ; texts

; 2, Kempston: the readers on port $001F, ControlXor $FF; the confirm
;
; Built like ChooseSinclair. Inside CellIndexMap's span ($DE9F on): the play
; reads these bytes as data after the menu; @code keeps the menu's code here as
; code. No part 2 recording chose 2 (known only from the code; REX 1's
; ChooseKempston $DE20 ran in p1-kempston).
ChooseKempston:
  LD HL,$001F
  LD (DefinePort),HL
  LD A,$67
  LD (DefineBit),A
  CALL SetFire
  LD A,$5F
  LD (DefineBit),A
  CALL SetUp
  LD A,$57
  LD (DefineBit),A
  CALL SetDown
  LD A,$47
  LD (DefineBit),A
  CALL SetRight
  LD A,$4F
  LD (DefineBit),A
  CALL SetLeft
  LD A,$FF
  LD (ControlXor),A
  LD IX,MenuTexts+$006E
  JP Confirm

; 4: Sinclair (port $EFFE, keys 6-0): fire bit 0, up 1, down 2, right 3, left
; 4; the confirm
;
; Witness: L1 2 (c2, rzx-p2-00000).
ChooseSinclair:
  LD HL,$EFFE
  LD (DefinePort),HL
  LD A,$47
  LD (DefineBit),A
  CALL SetFire
  LD A,$4F
  LD (DefineBit),A
  CALL SetUp
  LD A,$57
  LD (DefineBit),A
  CALL SetDown
  LD A,$5F
  LD (DefineBit),A
  CALL SetRight
  LD A,$67
  LD (DefineBit),A
  CALL SetLeft
  XOR A
  LD (ControlXor),A
  LD IX,MenuTexts+$0040
  JP Confirm

; 3, Cursor: port $EFFE fire bit 0 (key 0), right 2 (8), up 3 (7), down 4 (6);
; left $F7FE bit 4 (5); the confirm
;
; Inside CellIndexMap's span ($DE9F on), code by @code. No part 2 recording
; chose 3 (known only from the code; REX 1's ChooseCursor $DE99 ran in
; p1-cursor).
ChooseCursor:
  LD HL,BufferPlayOrigin+$04FF
  LD (DefinePort),HL
  LD A,$47
  LD (DefineBit),A
  CALL SetFire
  LD A,$57
  LD (DefineBit),A
  CALL SetRight
  LD A,$5F
  LD (DefineBit),A
  CALL SetUp
  LD A,$67
  LD (DefineBit),A
  CALL SetDown
  LD HL,BufferPlayOrigin+$0CFF
  LD (DefinePort),HL
  CALL SetLeft
  XOR A
  LD (ControlXor),A
  LD IX,MenuTexts+$0058
  JP Confirm

; The confirm text; Y returns (the game starts), N goes back to the menu
; (MenuAgain)
;
; As REX 1's Confirm $DED2 (src/game/menu.asm).
;
; Witness: L1 2 (c2, rzx-p2-00000).
Confirm:
  LD B,$01
  CALL PrintBoxed
ConfirmWait:
  LD BC,$DFFE             ; Y or N
  IN A,(C)
  BIT 4,A
  RET Z
  LD BC,$7FFE
  IN A,(C)
  BIT 3,A
  JP Z,MenuAgain
  JP ConfirmWait

; N at the confirm: back to the menu's text and wait (JP $DAF1)
;
; As REX 1's MenuAgain $DEEC (src/game/menu.asm). Inside CellIndexMap's span,
; code by @code; no recording pressed N (known only from the code).
MenuAgain:
  JP l_DAF1

; RET after MenuAgain's JP, never reached
MenuAgainRet:
  DEFB $C9

; DE = the font's character A ($6206 + 8A)
;
; Inside CellIndexMap's span ($DE9F-$E4FE, cleared and read by DrawRoom each
; room), code by @code; DEFINE's key echo calls it, as REX 1's FontChar $DEF0,
; and no part 2 recording chose DEFINE (known only from the code).
FontChar:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,DevLink+$005E
  ADD HL,DE
  EX DE,HL
  RET

; 8 bytes from DE down the screen at HL
;
; As REX 1's DrawChar $DEFC. Inside CellIndexMap's span, code by @code; with
; FontChar, DEFINE's key echo, which no part 2 recording chose (known only from
; the code).
DrawChar:
  LD B,$08
l_DFBF:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ l_DFBF
  RET

; The menu's text records: SELECT, 1:DEFINE, 2:KEMPSTON, 3:CURSOR, 4:SINCLAIR;
; the confirms; DEFINE's PRESS, :UP, :DOWN, :LEFT, :RIGHT, :FIRE (twice, two
; colours)
MenuTexts:
  INCBIN "res/texts/rex2-menu.bin",$0000,257

; Zeros to the title screen: the room grid's space after the menu
MenuSpace:
  DEFB $46,$49,$52,$45,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00
RoomGridLeft:
  DEFB $00                ; the grid's origin one byte left (CellPointer with A
                          ; = 0, Rex facing right)
RoomGrid:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; the room
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; grid's
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; origin:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; the cell
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; under (x,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; y) at
                                                                       ; $E19F + 32
                                                                       ; x (y / 8)
                                                                       ; + x / 8
RoomGridPlay:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; the grid's
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; first play
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row (line
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 24)
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The title screen (6912 bytes to $FFFF; the tape ends at $FFF9), shown by
; TitleMenu; then the attribute shadow ($E4FF-$E7FE) and the back buffer
TitleScreen:
  INCBIN "res/screens/rex2-title.bin",$0000,96
AttrShadowPlay:
  ; $E55F the shadow's play rows (CopyAttrs puts them at $5860)
  INCBIN "res/screens/rex2-title.bin",$0060,1184
ObjectBufferOrigin:
  ; $E9FF the objects' origin
  INCBIN "res/screens/rex2-title.bin",$0500,256
BufferPlayOrigin:
  ; $EAFF the play lines' origin (one byte before the buffer)
  INCBIN "res/screens/rex2-title.bin",$0600,5371
