; --------------------------------------------------------------------------------------------------------------------
; password.asm: The level entry: the password screen, the line editor, the coding of the progress
;
; The progress (the completion flags MissionsDone $6799 and the 32-bit Score $CC79) is packed into ten characters:
; EncodePassword $CE2E takes 4 bits of the score for each of eight values with a mission's completion flag in bit 4,
; the last two hold the flags of missions 9-10 and a checksum of the score's bytes; PasswordToChars $CF1C maps the
; 5-bit values through PasswordAlphabet $CF5F. Entering a password (PasswordScreen $C578) runs the way back:
; CharsToPassword $CF3E, DecodePassword $CE8B (Z when the checksum agrees), then the flags and the score are taken
; over.
; --------------------------------------------------------------------------------------------------------------------

; Show the password of the progress so far: "THIS IS YOUR ENTRY STRING." and
; the ten characters
;
; Screen node `$74FE` (from the mission status screen). ClearMenuScreen,
; EncodePassword, PasswordToChars, PrintString of EntryStringText and
; PasswordText `$CEF6`, a delay (Delay `$CD63`), a key, ScreenZero and
; NextView. Witness: L1 1 (menu).
ShowPassword:
  CALL ClearMenuScreen
  CALL EncodePassword
  CALL PasswordToChars
  LD HL,EntryStringText
  CALL $6FB3
  LD HL,PasswordText
  CALL $6FB3
  CALL $725F
  CALL Delay
ShowPasswordKey:
  LD A,($8978)
  AND $02
  JR Z,ShowPasswordKey
  CALL $705A
  CALL $7E7A
  JP $6A91

; Clear the shadow screen's pixels and fill its attributes from the box $C74A
;
; PageShadowScreen `$7268`, ScreenRowFill of 192 lines of 32 bytes with 0,
; AttrBox `$C74A`. Witness: L1 6 (c1, menu).
ClearMenuScreen:
  CALL $7268
  XOR A
  EX AF,AF'
  XOR A
  LD BC,$0000
  EXX
  LD D,$20
  LD E,$C0
  CALL $6D22
  LD HL,MenuBoxes
  JP $6CFB

; Texts: "INVALID PASSWORD", then two blank lines that clear it and the entry
;
; Printed by PasswordScreen at `$C5A5`, `$C5AE` and `$C5B4`.
PasswordMessages:
  INCBIN "res/texts/password-messages.bin",$0000,22
InvalidBlank:
  INCBIN "res/texts/password-messages.bin",$0016,22
EntryBlank:
  INCBIN "res/texts/password-messages.bin",$002C,14

; The level entry screen: read ten characters, check them, take over the flags
; and the score
;
; Node `$74F8` (from the title). ClearMenuScreen, PasswordPrompt, the buffer
; filled with spaces, ReadPassword `$C620`; when the view flag is set (a click
; elsewhere), back. Otherwise CharsToPassword, DecodePassword: a bad checksum
; prints "INVALID PASSWORD" and asks again; a good one copies the score to
; Score `$CC79`, the ten flags to MissionsDone `$6799`, counts them into
; MissionsCompleted `$CC93`, ScreenZero and NextView. Witness: L1 1 (menu).
PasswordScreen:
  CALL ClearMenuScreen
  LD HL,PasswordPrompt
  CALL $6FB3
  CALL $725F
PasswordAgain:
  LD B,$0A
  LD HL,PasswordBuffer
PasswordClearLoop:
  LD (HL),$20
  INC HL
  DJNZ PasswordClearLoop
  CALL ReadPassword
  LD A,($6A6D)
  AND A
  JR Z,PasswordCheck
  CALL $7E7A
  JP $6A91
PasswordCheck:
  CALL CharsToPassword
  CALL DecodePassword
  JR Z,PasswordAccepted
  LD HL,PasswordMessages
  CALL $6FB3
  CALL Delay
  LD HL,InvalidBlank
  CALL $6FB3
  LD HL,EntryBlank
  CALL $6FB3
  JR PasswordAgain
PasswordAccepted:
  LD HL,DecodedScore
  LD DE,Score
  LDI
  LDI
  LDI
  LDI
  LD HL,DecodedFlags
  LD DE,$6799
  LD BC,$000A
  LDIR
  LD B,$0A
  LD C,$00
  LD HL,$6799
CountFlagsLoop:
  LD A,(HL)
  INC HL
  AND A
  JR Z,CountFlagsNext
  INC C
CountFlagsNext:
  DJNZ CountFlagsLoop
  LD A,C
  LD (MissionsCompleted),A
  CALL $705A
  JP $6A91

; Text: "Type in your level entry:-"
;
; Printed by PasswordScreen `$C57B`.
PasswordPrompt:
  INCBIN "res/texts/password-prompt.bin",$0000,32

; The ten characters typed (EditLine's line)
;
; Filled with spaces by PasswordScreen, written by EditLine, read by
; CharsToPassword. The image holds leftover code bytes here.
PasswordBuffer:
  DEFB $22,$B9,$A9,$22,$50,$6B,$22,$55,$6B,$C9

; The buffer's end marks, then leftover bytes "...DAMAG": never read
;
; EditLine writes its end marks to `$C618-$C619`; no routine reads
; `$C61A-$C61F`.
PasswordLeftover:
  DEFB $07,$05,$03,$44,$41,$4D,$41,$47

; A short delay, the key state cleared, then EditLine at the screen place of
; the entry
;
; EditLine `$C644` with HL = PasswordBuffer, DE = `$488A` (the pixel address),
; BC = `$598A` (the attribute address). Witness: L1 1 (menu).
ReadPassword:
  LD BC,$4E20
ReadPasswordDelay:
  DEC BC
  LD A,B
  OR C
  JR NZ,ReadPasswordDelay
  XOR A
  LD ($8979),A
  LD HL,PasswordBuffer
  LD B,$00
  LD A,B
  LD C,B
  LD B,$00
  EX DE,HL
  LD HL,$598A
  ADD HL,BC
  LD B,H
  LD C,L
  EX DE,HL
  LD DE,$488A
  CALL EditLine
  RET

; Edit a line of up to 10 characters: keys add, DELETE takes back, ENTER ends
; when it is full
;
; Input: HL the buffer (set to `$C60E` here), DE the screen address, BC the
; cursor's attribute address. The state is in operands: the cursor's attribute
; address CursorAttrPtr, the end of the line (EditEndOp), the length
; (EditLengthOp), the maximum (EditMaxOp). Each key from WaitKey `$C6EC`: codes
; 0-1 ignored, 2 leaves through ScreenZero `$705A`, 3 (ENTER) ends when the
; length is the maximum, 4 (DELETE) takes one back, the others are added up to
; 14. PrintRawString `$C6FC` redraws the line after every key. Witness: L1 1
; (menu).
EditLine:
  EXX
  EX AF,AF'
  LD A,$0A
  LD (EditMaxOp+$0001),A
  LD HL,PasswordBuffer
  LD (EditLineBuffer),HL
  EX AF,AF'
  EXX
  JR EditLineStart

; Variant entry: A = the maximum, HL = the buffer, then EditLineStart
;
; Known only from the code: nothing calls it.
EditLineAt:
  LD (EditMaxOp+$0001),A
  LD (EditLineBuffer),HL
  XOR A
; This entry point is used by the routine at EditLine.
EditLineStart:
  LD (EditLengthOp+$0001),A
  LD (EditEndOp+$0001),HL
  LD (CursorAttrPtr),BC
  LD (EditRedraw+$0004),DE
  LD (HL),$FF
  INC HL
  XOR A
  LD (HL),A
  LD H,B
  LD L,C
  LD (HL),$C6
; This entry point is used by the routine at EditAddSpace.
EditRedraw:
  LD HL,(EditLineBuffer)
  LD DE,$0000
  CALL PrintRawString
; This entry point is used by the routine at EditAddSpace.
EditNextKey:
  CALL WaitKey
  CP $02
  JR C,EditNextKey
  JP Z,$705A
  CP $04
  JR C,EditEnter
  JR NZ,EditAddChar
  LD HL,EditLengthOp+$0001
  XOR A
  CP (HL)
  JR Z,EditNextKey
  DEC (HL)
  LD HL,(CursorAttrPtr)
  LD (HL),$46
  DEC HL
  LD (HL),$C6
  LD (CursorAttrPtr),HL
EditEndOp:
  LD HL,$0000             ; LD HL,n: n ($C6A0) the end of the typed line
  LD (HL),$20
  DEC HL
  LD (HL),$FF
  LD (EditEndOp+$0001),HL
  JR EditRedraw

; Unused: A = space, then the add path EditAddChar
;
; Known only from the code: no jump reaches it.
EditAddSpace:
  LD A,$20
; This entry point is used by the routine at EditLineAt.
EditAddChar:
  LD C,A
  LD HL,EditLengthOp+$0001
  LD A,(HL)
EditMaxOp:
  CP $0E                  ; CP n: n ($C6B4) the length that ends the line
  JR Z,EditNextKey
  INC (HL)
  LD HL,(CursorAttrPtr)
  LD (HL),$46
  INC HL
  LD (HL),$C6
  LD (CursorAttrPtr),HL
  LD HL,(EditEndOp+$0001)
  LD (HL),C
  INC HL
  LD (HL),$1F
  LD (EditEndOp+$0001),HL
  INC HL
  LD (HL),$00
  JR EditRedraw
; This entry point is used by the routine at EditLineAt.
EditEnter:
  LD A,(EditLengthOp+$0001)
  LD HL,EditMaxOp+$0001
  CP (HL)
  JR NZ,EditNextKey
  LD HL,(EditEndOp+$0001)
  LD (HL),$00
  LD HL,(EditLineBuffer)
EditLengthOp:
  LD A,$00                ; LD A,n: n ($C6E4) the length
  AND A
  LD HL,(CursorAttrPtr)
  LD (HL),$46
  RET

; Wait for a new key (bit 0 of KeyState $8978), clear the bit, A = the key code
; ($8979)
;
; Witness: L1 286697 (menu).
WaitKey:
  LD HL,($8978)
  BIT 0,L
  JR Z,WaitKey
  LD A,H
  RES 0,L
  LD ($8978),HL
  RET

; EditLine's cursor attribute address
;
; Written and read by EditLine.
CursorAttrPtr:
  DEFW $0000

; Draw the 0-terminated string at HL straight onto the screen at DE with the
; 8x8 font
;
; Characters `$20-$7F` take the glyph Font8x8 + 8 (c - `$20`), the others the
; space; 8 lines down the screen third, one column a character. No attributes,
; no control codes. Witness: L1 77 (menu).
PrintRawString:
  LD A,(HL)
  INC HL
  AND A
  RET Z
  PUSH HL
  XOR $80
  JP M,RawGlyph
RawSpaceGlyph:
  LD HL,Font8x8
  JR RawGlyphCopy
RawGlyph:
  SUB $A0
  JR C,RawSpaceGlyph
  ADD A,A
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD BC,Font8x8
  ADD HL,BC
RawGlyphCopy:
  PUSH DE
  LD B,$08
RawGlyphLine:
  LD A,(HL)
  INC HL
  LD (DE),A
  INC D
  DJNZ RawGlyphLine
  POP DE
  INC E
  POP HL
  JR PrintRawString

; EditLine's buffer address
;
; Written by EditLine `$C64E`, read at `$C673`.
EditLineBuffer:
  DEFW $0000

; Zone table of the password screen: empty
;
; PointerZones finds the end at once.
PasswordZones:
  DEFB $00

; Text: "THIS IS YOUR ENTRY STRING."
;
; Printed by ShowPassword.
EntryStringText:
  INCBIN "res/texts/entry-string-text.bin",$0000,32

; Attribute box records: the whole menu screen and the catalogue's titles
;
; `$C74A` read by ClearMenuScreen, `$C74F` and `$C754` by DrawCatalogueTitles,
; `$C759` by MissionCatalogueScreen. `$C75E` is a 0 byte.
MenuBoxes:
  DEFB $47,$18,$00,$20,$00
CatalogueTitleBoxA:
  DEFB $47,$04,$04,$09,$14
CatalogueTitleBoxB:
  DEFB $47,$02,$04,$09,$12
CatalogueListBox:
  DEFB $47,$02,$13,$0B,$16
  DEFB $00                ; a zero byte

  ORG $CE2E

; Pack MissionsDone and Score into the ten 5-bit values at $CEFB
;
; Eight values: 4 bits of the score (ScoreBits `$CF06`) and in bit 4 the flag
; of missions 1-8; the ninth and tenth: the flags of missions 9-10 (value 8
; bits 0, 1) and an 8-bit checksum, the XOR of the score's four bytes, split as
; its low 3 bits in value 8 (bits 2-4) and its high 5 bits in value 9. Witness:
; L1 1 (menu).
;
; A non-zero score: m1complete frame 22160 ("C5989999PB", score 500, mission
; 1), m4complete 21956 ("H59K9999PK", score 2500, missions 1 and 4).
EncodePassword:
  LD E,$08
  LD HL,Score
  LD A,(HL)
  EXX
  EX AF,AF'
  LD HL,$6799
  LD DE,PasswordValues
  LD B,$08
EncodeLoop:
  LD A,$04
  CALL ScoreBits
  LD C,A
  LD A,(HL)
  INC HL
  AND $10
  OR C
  LD (DE),A
  INC DE
  DJNZ EncodeLoop
  LD A,(HL)
  INC HL
  AND $01
  LD C,A
  NOP
  LD A,(HL)
  AND $02
  OR C
  LD C,A
  LD HL,Score
  XOR A
  LD B,$04
ChecksumLoop:
  XOR (HL)
  INC HL
  DJNZ ChecksumLoop
  SRA A
  RR B
  SRA A
  RR B
  SRA A
  RR B
  AND $1F
  INC DE
  LD (DE),A
  LD A,C
  RR B
  RR B
  RR B
  OR B
  DEC DE
  LD (DE),A
  RET

; The ten completion flags DecodePassword makes
;
; Copied to MissionsDone by PasswordScreen.
DecodedFlags:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The score DecodePassword makes
;
; Copied to Score by PasswordScreen.
DecodedScore:
  DEFB $00,$00,$00,$00

; Unpack the ten values at $CEFB into DecodedFlags and DecodedScore; Z when the
; checksum agrees
;
; Witness: L1 1 (menu).
DecodePassword:
  LD DE,DecodedFlags
  LD HL,DecodedScore
  EXX
  LD HL,PasswordValues
  LD B,$04
DecodeLoop:
  LD A,(HL)
  INC HL
  LD C,A
  AND $10
  JR Z,DecodeFlagA
  LD A,$FF
DecodeFlagA:
  EXX
  LD (DE),A
  INC DE
  EXX
  LD A,(HL)
  LD D,A
  INC HL
  AND $10
  JR Z,DecodeFlagB
  LD A,$FF
DecodeFlagB:
  EXX
  LD (DE),A
  INC DE
  EXX
  LD A,D
  AND $0F
  LD D,A
  LD A,C
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  AND $F0
  OR D
  EXX
  LD (HL),A
  INC HL
  EXX
  DJNZ DecodeLoop
  LD A,(HL)
  LD C,A
  AND $01
  JR Z,DecodeFlag9
  LD A,$FF
DecodeFlag9:
  EXX
  LD (DE),A
  INC DE
  EXX
  LD A,C
  AND $02
  JR Z,DecodeFlag10
  LD A,$FF
DecodeFlag10:
  EXX
  LD (DE),A
  EXX
  INC HL
  LD A,C
  AND $1C
  SRL A
  SRL A
  LD C,(HL)
  SLA C
  SLA C
  SLA C
  OR C
  LD C,A
  LD B,$04
  XOR A
  LD HL,DecodedScore
DecodeChecksum:
  XOR (HL)
  INC HL
  DJNZ DecodeChecksum
  CP C
  RET

; Text: the password line; its ten characters at $CEFB
;
; Written by EncodePassword, PasswordToChars and CharsToPassword (the values),
; printed by ShowPassword.
PasswordText:
  INCBIN "res/texts/password-text.bin",$0000,5
PasswordValues:
  INCBIN "res/texts/password-text.bin",$0005,11

; A = the next A bits of the score at HL' (E' bits left in the byte)
;
; Witness: L1 8 (menu).
ScoreBits:
  EXX
  LD B,A
  EX AF,AF'
  LD C,$00
ScoreBitsLoop:
  SLA A
  RL C
  DEC E
  JR NZ,ScoreBitsNext
  LD E,$08
  INC HL
  LD A,(HL)
ScoreBitsNext:
  DJNZ ScoreBitsLoop
  EX AF,AF'
  LD A,C
  EXX
  RET

; Map the ten values at $CEFB to characters through PasswordAlphabet
;
; Twelve `NOP`s at `$CF26` are room left for a patch. Witness: L1 1 (menu).
PasswordToChars:
  LD BC,PasswordAlphabet
  EXX
  LD HL,PasswordValues
  LD B,$0A
ToCharsLoop:
  LD A,(HL)
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  EXX
  LD H,$00
  LD L,A
  ADD HL,BC
  LD A,(HL)
  EXX
  LD (HL),A
  INC HL
  DJNZ ToCharsLoop
  RET

; Map the ten typed characters to their places in PasswordAlphabet
;
; An unknown character gives 4 (B = 0 after the search: 36 AND 31); D, E, F and
; G give 0-3 like 9876. Witness: L1 1 (menu).
CharsToPassword:
  LD DE,PasswordValues
  LD HL,PasswordBuffer
  LD B,$0A
ToValuesLoop:
  LD A,(HL)
  INC HL
  EXX
  LD HL,PasswordAlphabet
  LD B,$24
AlphabetSearch:
  CP (HL)
  INC HL
  JR Z,AlphabetFound
  DJNZ AlphabetSearch
AlphabetFound:
  LD A,$24
  SUB B
  AND $1F
  EXX
  LD (DE),A
  INC DE
  DJNZ ToValuesLoop
  RET

; The 36 password characters: "9876543210ZYXWVUTSRQPONMLKJIHABCDEFG"
;
; Read by PasswordToChars and CharsToPassword.
PasswordAlphabet:
  INCBIN "res/texts/password-alphabet.bin",$0000,36

; Two zero bytes, then the catalogue's first 32 bytes copied by
; CopyCatalogueHead
;
; `$CF85-$CFA4` is written by CopyCatalogueHead `$70C6`, compared by
; IsCatalogueLoaded and printed (the title) by MissionCatalogueScreen. The
; image holds leftover code bytes here; `$CFA5-$CFA8` are never read.
CatalogueHead:
  DEFB $00,$00
CatalogueTitle:
  DEFB $06,$01
  DEFB $08,$00
  DEFB $A7,$ED
  DEFB $42,$DD
  DEFB $75,$05
  DEFB $DD,$74
  DEFB $06,$01
  DEFB $2C,$01
  DEFB $A7,$ED
  DEFB $42,$D0
  DEFB $DD,$36
  DEFB $18,$AE
  DEFB $DD,$36
  DEFB $19,$CF
  DEFB $DD,$36
  DEFB $1C,$D0
  DEFB $FF,$00            ; leftover
  DEFB $B9,$93
