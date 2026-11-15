; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The title, the menu, DEFINE KEYS, the roll call
;
; TitleMenu shows the title screen (loaded with the code at $E4FF and copied to the screen), prints the menu (SELECT
; 1:DEFINE 2:KEMPSTON 3:CURSOR 4:SINCLAIR) and, while it waits, rolls through the enemies with their names and scores
; (RollCallTexts $DC26, RollCallSprites $E067). A key 1-4 chooses the controls and asks to confirm (Y or N; N goes
; back to the menu). DEFINE asks for UP, DOWN, LEFT, RIGHT and FIRE; each key is read by ScanKey and written into the
; reader's port and BIT operands.
;
; The title screen's bytes, the roll call's pictures and the key table are needed only here: after the menu GameEntry
; clears $E4FF-$E7FE for the attribute shadow, and the room grid ($E19F-$E4FE) is built over the roll call's pictures.
; The menu copies the explosion picture ExplosionPicture $E336 to $6018 first, so it survives.
; --------------------------------------------------------------------------------------------------------------------

  ORG $DAC0

; The title and menu: the title on, the menu text, the roll call, the keys 1-4
;
; Witness: L1 1 (c1).
TitleMenu:
  LD A,$00
  OUT ($FE),A
  LD DE,DevLinkStub
  LD HL,ExplosionPicture
  LD BC,$00C0
  LDIR
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
  LD DE,$4000
  LD HL,TitleScreen
  LD BC,$1B00
  LDIR
  XOR A
  LD (RollFrame),A
  LD (RollShow),A
  LD HL,RollCallSprites-12
  LD (RollTextPtr),HL
  LD A,$32
  LD (SweepCount),A
  LD HL,RollCallTexts
  LD (RollTextNext),HL
; This entry point is used by the routine at RollCallNext.
MenuLoop:
  LD HL,(RollTextPtr)     ; the menu's wait: keys 1-4, the roll call
  CALL RollCallSprite
  LD BC,$07D0
  CALL Delay
  LD BC,$F7FE
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
  LD A,(SweepCount)
  DEC A
  LD (SweepCount),A
  OR A
  JP NZ,MenuLoop
  LD A,$32
  LD (SweepCount),A
  LD A,(RollShow)
  XOR $01
  LD (RollShow),A
  OR A
  JP Z,RollCallTitle
  LD HL,(RollTextPtr)
  LD DE,$000C
  ADD HL,DE
  LD A,(HL)
  CP $FF
  JP NZ,RollCallText

; Code: LD HL,RollCallSprites ($21 $67 $E0): the roll call from its first
; sprite again, then RollCallText
;
; TitleMenu's loop falls in here when the next sprite record is the list's $FF.
; No recording stays in the menu that long (known only from the code); the kit
; keeps it as bytes because a recording reads these bytes as data (c1, frames
; 18550-20469, in play; the reader is not identified) and a c seed cannot win
; over a read (work/stage2/NOTES.md, For the lead).
RollCallRestart:
  DEFB $21,$67,$E0

; The next enemy's name and score (2 text records), the next record; at the
; list's end RollCallTextStart
;
; Witness: L1 4 (c1).
RollCallText:
  LD (RollTextPtr),HL
  LD IX,(RollTextNext)
  LD B,$02
  CALL PrintBoxed
  LD A,(IX+$00)
  CP $FF
  JP NZ,RollCallNext

; Code: LD IX,RollCallTexts ($DD $21 $26 $DC): the names from the first again,
; then RollCallNext
;
; RollCallText falls in here at the texts' $FF; never run in the recordings
; (known only from the code); the kit keeps it as bytes because a recording
; reads these bytes as data (c1, frames 18550-20469, in play; the reader is not
; identified) and a c seed cannot win over a read (work/stage2/NOTES.md, For
; the lead).
RollCallTextStart:
  DEFB $DD,$21,$26,$DC

; Keep the text pointer, back to the menu loop
;
; Witness: L1 4 (c1).
RollCallNext:
  LD (RollTextNext),IX
  JP MenuLoop
; This entry point is used by the routine at TitleMenu.
RollCallTitle:
  CALL ShowTitle
  JP MenuLoop

; The title screen ($E4FF) to the screen, the menu's attribute box
;
; Witness: L1 8 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).
ShowTitle:
  LD HL,$5800
  LD B,$04
  LD E,$0F
  LD A,$02
  CALL FillAttrs
  LD DE,$4000
  LD HL,TitleScreen
  LD BC,$1B00
  LDIR
  RET

; DEFINE: wait for a key not SPACE, not H and not taken; its port into
; DefinePort, its BIT opcode into DefineBit, its character in A
;
; Witness: L1 10 (c1, p1-define).
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
  JP NC,ScanKeyNextRow
  INC E
  DJNZ ScanKeyShift
  POP BC
  INC IX
  INC IX
  LD DE,$0005
  ADD IY,DE
  DJNZ ScanKeyBit
  JP ScanKeyRow
ScanKeyNextRow:
  POP BC
  PUSH DE
ScanKeyFound:
  LD C,(IX+$00)
  LD B,(IX+$01)
  IN A,(C)
  CP D
  JP Z,ScanKeyFound
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

; The roll call: for each enemy its name and its score as text records, then
; $FF
;
; FOOT MAN 100, STOMPER 200, SCANNER 600, RAMMING POD 300, LAUNCHER 800,
; SHOOTERS 500, SWING GUN 600, BLOB 200, MINE LAYER 1000, MINE no score.
RollCallTexts:
  INCBIN "res/texts/rex1-roll-call.bin",$0000,296
DefineTaken:
  ; $DD4E the characters of the keys chosen so far
  INCBIN "res/texts/rex1-roll-call.bin",$0128,6

; 1: DEFINE: PRESS a key for each of UP, DOWN, LEFT, RIGHT, FIRE (the setters
; $A4B5, $A4CE, $A483, $A49C, $A46A), then the confirm
;
; Witness: L1 2 (c1, p1-define).
DefineKeys:
  CALL ShowTitle
  LD HL,$0000
  LD (DefineTaken),HL
  LD (DefineTaken+$0002),HL
  LD (DefineTaken+$0004),HL
  LD IY,DefineTaken
  LD IX,PressText
  LD B,$06
  PUSH IY
  CALL PrintBoxed
  POP IY
DefineWait:
  LD BC,$F7FE
  IN A,(C)
  BIT 0,A
  JP Z,DefineWait
  LD IX,DefineUpText
  LD B,$01
  PUSH IY
  CALL PrintTextHL
  POP IY
  CALL ScanKey
  LD (IY+$00),A
  CALL FontChar
  LD HL,$488F
  CALL DrawChar
  CALL SetUp
  LD IX,DefineDownText
  LD B,$01
  PUSH IY
  CALL PrintTextHL
  POP IY
  CALL ScanKey
  LD (IY+$01),A
  CALL FontChar
  LD HL,$48AF
  CALL DrawChar
  CALL SetDown
  LD IX,DefineLeftText
  LD B,$01
  PUSH IY
  CALL PrintTextHL
  POP IY
  CALL ScanKey
  LD (IY+$02),A
  CALL FontChar
  LD HL,$48CF
  CALL DrawChar
  CALL SetLeft
  LD IX,DefineRightText
  LD B,$01
  PUSH IY
  CALL PrintTextHL
  POP IY
  CALL ScanKey
  LD (IY+$03),A
  CALL FontChar
  LD HL,$48EF
  CALL DrawChar
  CALL SetRight
  LD IX,DefineFireText
  LD B,$01
  PUSH IY
  CALL PrintTextHL
  POP IY
  CALL ScanKey
  LD (IY+$04),A
  CALL FontChar
  LD HL,$500F
  CALL DrawChar
  CALL SetFire
  LD IX,ConfirmKeysText
  JP KeysConfirm

; 2, Kempston: the readers on port $001F, ControlXor $FF; fire bit 4, up 3,
; down 2, right 0, left 1; the confirm
;
; The same shape as ChooseSinclair: LD HL,$001F: LD (DefinePort),HL and for
; each control LD A,BIT opcode: LD (DefineBit),A: CALL the setter, then
; ControlXor = $FF and JP Confirm (with ConfirmKempstonText). Run by
; p1-kempston (menu key 2, then play on the stick: the readers' operands read
; back as port $001F, bits 4, 1, 0, 3, 2, ControlXor $FF).
;
; Witness: L1 1 (p1-kempston)
ChooseKempston:
  CALL ShowTitle
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
  LD IX,ConfirmKempstonText
  JP Confirm

; 4: Sinclair (port $EFFE, keys 6-0): fire bit 0, up 1, down 2, right 3, left
; 4; the confirm
;
; Witness: L1 1 (rzx-p1-00000).
ChooseSinclair:
  CALL ShowTitle
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
  LD IX,ConfirmSinclairText

; ControlXor 0 (keys), then the confirm
;
; Witness: L1 4 (c1, p1-cursor, p1-define, rzx-p1-00000).
KeysConfirm:
  XOR A
  LD (ControlXor),A
  JP Confirm

; 3, Cursor: port $EFFE fire bit 0 (key 0), right 2 (8), up 3 (7), down 4 (6);
; left $F7FE bit 4 (5); the confirm
;
; Built like ChooseSinclair, ending with KeysConfirm (ControlXor 0). From $DE9F
; on, after the menu, these bytes are also CellIndexMap: the room's animated
; cell index of each grid cell, written by DrawRoom and read by BulletHitsCell,
; which is why every play recording reads them. Run by p1-cursor (menu key 3,
; then play on 5-8 and 0: the readers' operands read back as above).
;
; Witness: L1 1 (p1-cursor)
ChooseCursor:
  CALL ShowTitle
  LD HL,BackBuffer+$04FE
CellIndexMap:
  LD (DefinePort),HL      ; after the menu: each grid cell's index into
                          ; AnimCellList (DrawRoom, BulletHitsCell), over this
                          ; code and the menu's texts
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
  LD HL,BackBuffer+$0CFE
  LD (DefinePort),HL
  CALL SetLeft
  LD IX,ConfirmCursorText
  JP KeysConfirm

; The confirm text; Y returns (the game starts), N goes back to the menu
; (MenuAgain)
;
; Witness: L1 5 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).
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

; Code: JP $DAEE: RET: N at the confirm, back to the menu's text and wait
;
; Inside CellIndexMap's span, so the play reads it as data and the kit keeps it
; as bytes; no recording pressed N (known only from the code).
MenuAgain:
  DEFB $C3,$EE,$DA,$C9

; DE = the font's character A ($5FE0 + 8A)
;
; Witness: L1 10 (c1, p1-define).
FontChar:
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD DE,$5FE0
  ADD HL,DE
  EX DE,HL
  RET

; 8 bytes from DE down the screen at HL
;
; Witness: L1 10 (c1, p1-define).
DrawChar:
  LD B,$08
DrawCharLoop:
  LD A,(DE)
  LD (HL),A
  INC DE
  INC H
  DJNZ DrawCharLoop
  RET

; The menu's text records: SELECT, 1:DEFINE, 2:KEMPSTON, 3:CURSOR, 4:SINCLAIR;
; the confirms; DEFINE's PRESS, :UP, :DOWN, :LEFT, :RIGHT, :FIRE (twice, two
; colours)
MenuTexts:
  INCBIN "res/texts/rex1-menu.bin",$0000,64
ConfirmSinclairText:
  ; $DF45 CONFIRM SINCLAIR Y.N
  INCBIN "res/texts/rex1-menu.bin",$0040,24
ConfirmCursorText:
  ; $DF5D CONFIRM CURSOR Y.N
  INCBIN "res/texts/rex1-menu.bin",$0058,22
ConfirmKempstonText:
  ; $DF73 CONFIRM KEMPSTON Y.N
  INCBIN "res/texts/rex1-menu.bin",$006E,24
ConfirmKeysText:
  ; $DF8B CONFIRM KEYS Y.N
  INCBIN "res/texts/rex1-menu.bin",$0086,20
PressText:
  ; $DF9F PRESS
  INCBIN "res/texts/rex1-menu.bin",$009A,59
DefineUpText:
  ; $DFDA :UP in the second colour (the key chosen)
  INCBIN "res/texts/rex1-menu.bin",$00D5,8
DefineDownText:
  ; $DFE2 :DOWN
  INCBIN "res/texts/rex1-menu.bin",$00DD,10
DefineLeftText:
  ; $DFEC :LEFT
  INCBIN "res/texts/rex1-menu.bin",$00E7,10
DefineRightText:
  ; $DFF6 :RIGHT
  INCBIN "res/texts/rex1-menu.bin",$00F1,11
DefineFireText:
  ; $E001 :FIRE
  INCBIN "res/texts/rex1-menu.bin",$00FC,10

; Draw the roll call's sprite (RollCallSprites record at HL) frame RollFrame by
; DrawCharBlock, its picture and column written into the inline parameters
;
; Witness: L1 446 (c1, p1-cursor, p1-define, p1-kempston, rzx-p1-00000).
RollCallSprite:
  LD A,(RollShow)
  OR A
  RET Z
  LD (RollPtr),HL
  LD IX,(RollPtr)
  LD A,(IX+$02)
  LD (RollSpriteParams+$0004),A
  LD A,(IX+$03)
  LD (RollSpriteParams+$0005),A
  LD A,(IX+$04)
  PUSH IX
  LD DE,$0004
  ADD IX,DE
  PUSH IX
  POP HL
  POP IX
  LD A,(RollFrame)
  LD E,A
  LD D,$00
  ADD HL,DE
  LD E,(HL)
  LD D,$00
  LD L,(IX+$00)
  LD H,(IX+$01)
  ADD HL,DE
  LD (RollSpriteParams),HL
  CALL DrawCharBlock

; DrawCharBlock's inline parameters (the picture word, column and line
; rewritten at $E04D, $E04E)
RollSpriteParams:
  DEFB $CA,$8C,$03,$10,$02,$10

; The next frame (8 a sprite), then the next record
;
; Witness: L1 224 (c1, p1-cursor, p1-define, p1-kempston).
RollCallFrame:
  LD HL,(RollPtr)
  LD DE,$000C
  ADD HL,DE
  LD (RollPtr),HL
  LD A,(RollFrame)
  INC A
  CP $08
  JP NZ,RollFrameStore
  XOR A
RollFrameStore:
  LD (RollFrame),A
  RET

; The roll call's sprites: [picture word][width][height][8 frame offsets], $FF
; ends
RollCallSprites:
  DEFB $F6,$E0,$02,$10,$00,$20,$40,$60,$00,$20,$40,$60
  DEFB $76,$E1,$02,$10,$00,$20,$40,$60,$00,$20,$40,$60
  DEFB $F6,$E1,$02,$10,$00,$20,$40,$60,$80,$A0,$00,$00
  DEFB $B6,$E2,$02,$10,$00,$20,$40,$60,$00,$20,$40,$60
  DEFB $4A,$8E,$02,$10,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $6A,$8E,$02,$10,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $AA,$8E,$02,$10,$00,$20,$40,$60,$80,$60,$40,$20
  DEFB $F6,$E3,$01,$08,$00,$08,$10,$18,$20,$28,$30,$38
  DEFB $36,$E4,$02,$0C,$00,$18,$30,$48,$00,$18,$30,$48
  DEFB $96,$E4,$01,$08,$00,$08,$10,$18,$20,$28,$30,$38
  DEFB $FF
KeyPorts:
  DEFB $FE,$FE,$FE,$FD,$FE,$FB,$FE,$DF,$FE,$BF,$FE,$7F ; the 8 keyboard
  DEFB $FE,$EF,$FE,$F7                                 ; half-rows' ports,
                                                       ; ScanKey's order
RollCallPictures:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$23,$00,$04,$00 ; the roll call's
  DEFB $24,$00,$13,$80,$20,$00,$0A,$80,$10,$B4,$0C,$40 ; pictures ($E0F6,
  DEFB $20,$40,$02,$00,$13,$00,$01,$00,$20,$00,$40,$A0 ; $E176, $E1F6, $E2B6,
  DEFB $20,$40,$00,$00,$23,$00,$04,$00,$24,$00,$13,$80 ; $E3F6, $E436, $E496);
  DEFB $20,$00,$0A,$80,$10,$B4,$0C,$40,$20,$40,$03,$00 ; the room grid is built
  DEFB $09,$80,$00,$80,$20,$00,$41,$00,$41,$80,$00,$00 ; over them after the
  DEFB $08,$C0,$01,$00,$09,$00,$04,$E0,$08,$00,$02,$A0 ; menu
  DEFB $04,$2D,$03,$10,$08,$50,$03,$00,$01,$00,$12,$00
  DEFB $20,$00,$24,$00,$06,$00,$11,$80,$02,$00,$12,$00
  DEFB $09,$C0,$10,$00,$05,$40,$08,$5A,$06,$20,$00,$20
  DEFB $13,$00,$02,$00,$06,$40,$00,$00,$08,$80,$11,$00
  DEFB $18,$80,$00,$00,$00,$00,$00,$00,$00,$00,$01,$00
  DEFB $01,$00,$01,$00,$02,$80,$01,$00,$00,$00,$06,$40
  DEFB $0E,$20,$17,$10,$2F,$08,$00,$00,$1B,$50,$00,$00
  DEFB $00,$00,$00,$00,$00,$80
RoomGridLeft:
  DEFB $01                ; the grid's origin one byte left (CellPointer with A
                          ; = 1)
RoomGrid:
  DEFB $00,$01,$00,$02,$80,$01,$00,$00,$00,$06,$40,$0E ; the room grid's
  DEFB $20,$17,$10,$2F,$08,$00,$00,$02,$80,$1B,$50,$00 ; origin: the cell under
  DEFB $00,$01,$00,$01,$00,$01,$00,$02,$80,$01,$00,$00 ; (x, y) at $E19F + 32 x
  DEFB $00,$06,$40,$0E,$20,$17,$10,$2F,$08,$00,$00,$02 ; (y / 8) + x / 8; built
  DEFB $80,$00,$00,$1B,$50,$00,$00,$00,$00,$00,$00,$00 ; over the roll call's
  DEFB $00,$02,$00,$01,$00,$01,$00,$02,$80,$01,$00,$00 ; pictures
  DEFB $00,$06,$40,$0E,$20,$17,$10,$2F,$08,$00,$00,$02
  DEFB $80,$1B,$50,$00,$00,$00,$00,$1E,$00,$AD,$40,$3F
RoomGridPlay:
  DEFB $00,$00,$00,$7F,$80,$28,$00,$55,$00,$00,$00,$1E ; the grid's first play
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; row (line 24)
  DEFB $00,$00,$00,$1E,$00,$AD,$40,$3F,$00,$00,$00,$7F
  DEFB $80,$28,$00,$55,$00,$00,$00,$1E,$00,$04,$00,$08
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$1E
  DEFB $00,$AD,$40,$3F,$00,$00,$00,$7F,$80,$28,$00,$55
  DEFB $00,$00,$00,$1E,$00,$04,$00,$08,$00,$12,$00,$08
  DEFB $00,$00,$00,$00,$00,$00,$00,$1E,$00,$AD,$40,$3F
  DEFB $00,$00,$00,$7F,$80,$28,$00,$55,$00,$00,$00,$1E
  DEFB $00,$48,$00,$01,$00,$04,$00,$28,$00,$02,$00,$00
  DEFB $00,$00,$00,$1E,$00,$AD,$40,$3F,$00,$00,$00,$7F
  DEFB $80,$28,$00,$55,$00,$00,$00,$1E,$00,$00,$00,$00
  DEFB $00,$41,$00,$00,$00,$10,$00,$00,$00,$00,$00,$1E
  DEFB $00,$AD,$40,$3F,$00,$00,$00,$7F,$80,$28,$00,$55
  DEFB $00,$00,$00,$1E,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$80,$80,$03,$80,$08,$60,$00,$10,$23,$10,$04
  DEFB $08,$04,$08,$43,$84,$08,$04,$09,$24,$84,$C4,$00
  DEFB $00,$DE,$F6,$00,$00,$2A,$B8,$17,$40,$03,$80,$03
  DEFB $80,$08,$60,$00,$10,$23,$10,$04,$08,$04,$08,$43
  DEFB $84,$08,$04,$09,$24,$84,$C4,$00,$00,$BD,$EE,$00
  DEFB $00,$2B,$E8,$10,$10,$13,$90,$03,$80,$08,$60,$00
  DEFB $10,$23,$10,$04,$08,$04,$08,$43,$84,$08,$04,$09
  DEFB $24,$84,$C4,$00,$00,$7B,$DE,$00,$00,$3E,$A8,$01
  DEFB $40,$03,$80,$03,$80,$08,$60,$00,$10,$23,$10,$04
  DEFB $08,$04,$08,$43,$84,$08,$04,$09,$24,$84,$C4,$00
  DEFB $00,$EF,$7A,$00,$00,$3A,$A8,$07,$40,$03,$80
ExplosionPicture:
  DEFB $11,$80,$00,$02,$00,$00,$12,$00,$00,$09,$C0,$00 ; the explosion's
  DEFB $10,$00,$00,$05,$40,$00,$08,$5A,$00,$06,$20,$00 ; picture (192 bytes),
  DEFB $00,$20,$00,$13,$00,$00,$02,$00,$00,$06,$40,$00 ; copied to $6018 by
  DEFB $00,$00,$00,$08,$80,$00,$11,$00,$00,$18,$80,$00 ; TitleMenu
  DEFB $04,$60,$00,$00,$80,$00,$04,$80,$00,$02,$70,$00
  DEFB $04,$00,$00,$01,$50,$00,$02,$16,$80,$01,$88,$00
  DEFB $00,$08,$00,$04,$C0,$00,$00,$80,$00,$01,$90,$00
  DEFB $00,$00,$00,$02,$20,$00,$04,$40,$00,$06,$20,$00
  DEFB $01,$18,$00,$00,$20,$00,$01,$20,$00,$00,$9C,$00
  DEFB $01,$00,$00,$00,$54,$00,$00,$85,$A0,$00,$62,$00
  DEFB $00,$02,$00,$01,$30,$00,$00,$20,$00,$00,$64,$00
  DEFB $00,$00,$00,$00,$88,$00,$01,$10,$00,$01,$88,$00
  DEFB $00,$46,$00,$00,$08,$00,$00,$48,$00,$00,$27,$00
  DEFB $00,$40,$00,$00,$15,$00,$00,$21,$68,$00,$18,$80
  DEFB $00,$00,$80,$00,$4C,$00,$00,$08,$00,$00,$19,$00
  DEFB $00,$00,$00,$00,$22,$00,$00,$44,$00,$00,$62,$00
  DEFB $00,$00,$38,$7C,$6C,$28,$00,$00,$00,$18,$3C,$54
  DEFB $78,$30,$00,$00,$00,$14,$3E,$1E,$74,$70,$20,$00
  DEFB $0C,$56,$7D,$BA,$EE,$B0,$60,$00,$18,$3C,$3A,$54
  DEFB $78,$68,$20,$00,$00,$38,$54,$74,$68,$14,$18,$00
  DEFB $00,$00,$18,$34,$34,$10,$00,$00,$00,$00,$00,$18
  DEFB $10,$00,$00,$00,$03,$C0,$08,$10,$22,$04,$44,$02
  DEFB $00,$00,$AA,$AA,$00,$00,$5D,$B6,$03,$C0,$13,$C8
  DEFB $09,$90,$04,$20,$03,$C0,$08,$10,$22,$04,$44,$02
  DEFB $00,$00,$DD,$DD,$00,$00,$5C,$36,$01,$80,$11,$88
  DEFB $08,$10,$04,$20,$03,$C0,$08,$10,$22,$04,$44,$02
  DEFB $00,$00,$EE,$EE,$00,$00,$5C,$36,$00,$00,$10,$08
  DEFB $08,$10,$04,$20,$03,$C0,$08,$10,$22,$04,$44,$02
  DEFB $00,$00,$BB,$BB,$00,$00,$5C,$36,$01,$80,$11,$88
  DEFB $08,$10,$04,$20,$18,$00,$18,$BD,$B5,$18,$00,$18
  DEFB $08,$04,$58,$BC,$35,$1A,$20,$10,$00,$24,$5A,$3C
  DEFB $34,$5A,$24,$00,$10,$20,$1A,$3D,$B4,$58,$04,$08
  DEFB $18,$00,$18,$BD,$B5,$18,$00,$18,$08,$04,$58,$BC
  DEFB $35,$1A,$20,$10,$00,$24,$5A,$3C,$34,$5A,$24,$00
  DEFB $10,$20,$1A,$3D,$B4,$58,$04,$08,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00

; The title screen: 6912 bytes from $E4FF, the tape holding them to $FFF9
; (6907); shown by TitleMenu, then the attribute shadow ($E4FF-$E7FE) and the
; back buffer
TitleScreen:
  INCBIN "res/screens/rex1-title.bin",$0000,20
ShieldAttrs:
  ; $E513 the shield figure's attributes in the shadow
  INCBIN "res/screens/rex1-title.bin",$0014,24
SweepAttrs:
  ; $E52B the HUD sweep's row in the shadow
  INCBIN "res/screens/rex1-title.bin",$002C,52
AttrShadowPlay:
  ; $E55F the shadow's play rows (CopyAttrs puts them at $5860)
  INCBIN "res/screens/rex1-title.bin",$0060,672
ShotBufferOrigin:
  ; $E7FF the back buffer's origin for a bullet: $E7FF + 32 x y + x / 8
  INCBIN "res/screens/rex1-title.bin",$0300,160
SparkleBufferOrigin:
  ; $E89F the sparkle's origin
  INCBIN "res/screens/rex1-title.bin",$03A0,96
SpriteBufferOrigin:
  ; $E8FF DrawSprite's origin
  INCBIN "res/screens/rex1-title.bin",$0400,256
ObjectBufferOrigin:
  ; $E9FF the objects' origin
  INCBIN "res/screens/rex1-title.bin",$0500,256
BufferPlayOrigin:
  ; $EAFF the play lines' origin (one byte before the buffer)
  INCBIN "res/screens/rex1-title.bin",$0600,1
BackBuffer:
  ; $EB00 the back buffer's play lines, 32 bytes a line, to $FFFF
  INCBIN "res/screens/rex1-title.bin",$0601,5370
