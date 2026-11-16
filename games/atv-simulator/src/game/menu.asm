; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The title, the tune's interrupt hook, the menus, the controls, one or two players, the split screen
;
; The front end. Title ($6DFB) copies the tune player back from $5B00 to $F850 (the second player's buffer overwrites
; it in play), shows the credits and the high scores, then MenuLoop ($737C) starts the title tune (TunePlay $F852,
; tune 0) with the interrupt hook TuneHook pointing at MenuTick ($7340): the menu runs inside the tune player's
; interrupt until a key stops the tune. A menu is a block of MenuDefs: a count, the box's x and y, its height, then a
; text and an action per item. The front end draws into the buffer $F03C (22 bytes a line, 80 lines: BufferRows) and
; copies it to the screen with ShowBuffer or Dissolve.
;
; Controls: player 1 has the keyboard (five keys, redefinable) or a Kempston joystick, player 2 the keyboard or a
; Sinclair joystick (keys 6-0). ReadP1Controls / ReadP2Controls ($D911 / $D942) turn them into five bits each in
; Controls1 / Controls2: 4 left, 3 right, 2 wheel up, 1 wheel down, 0 jump (fire).
; --------------------------------------------------------------------------------------------------------------------

; The front end's graphics bank: 14 pictures, each a sprite and its attributes
;
; +0 the count (14), +1 the bank's length word ($03C5: it ends at $66FD), +3
; zero, then a pair of words a picture from +4: the sprite's offset and the
; attributes' offset, both from $6338. A sprite is width (bytes), height
; (lines), advance, shift, then width x height bytes; the attributes are width,
; height (cells) and a byte a cell. MenuSprite ($863D) and MenuSpriteAttrs
; ($773D) read it (c1: the title's ATV and logo, the trail intro's number, the
; panel frames).
MenuGfx:
  INCBIN "res/sprites/menu.bin",$0000,965

; 35 zeros after the bank, never read
MenuGfxEnd:
  DEFS $23

; The menu's variables
MenuVars:
MenuBoxX:
  DEFB $00                ; the current menu box's x (pixels)
MenuBoxY:
  DEFB $00                ; its y (the top line, counted up from the bottom)
MenuBoxHeight:
  DEFB $00                ; its height (lines)
MenuCount:
  DEFB $00                ; its item count
TuneTimer:
  DEFB $00                ; a word from $04C8 (Title), counted by MenuTick each
                          ; tune interrupt and by MenuLoop each HALT: the high
                          ; scores at $0A00 in the tune (26.7 s), the title at
                          ; $8000 (MenuLoop)
MenuSpare:
  DEFB $00                ; written 0 by ClearMenuSpare, never read
MenuItem:
  DEFB $00                ; the highlighted item (0 up)

; The screen address of each of the 192 lines, top first (BuildRowAddrs fills
; it at the start; zeros in the image)
RowAddrs:
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

; The offset of each of the 80 buffer lines (22 bytes a line, from 22:
; BuildBufferRows fills it)
;
; Entry k is 22 (k + 1): one line off from what a 0-based table gives.
BufferRows:
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000

; Players and scores
PlayerVars:
PlayerCount:
  DEFB $00                ; 0 one player, 1 two players (MenuPlayerCount
                          ; toggles it)
Scores:
  DEFB $30,$33,$30,$30,$30 ; the two players' scores, five ASCII digits each;
                           ; "03000" and "02000" in the image, cleared to
                           ; "00000" by NewGame
ScoreP2:
  DEFB $30,$32,$30,$30,$30 ; player 2's five digits
NameColour:
  DEFB $00                ; the name entry's colour ($10 player 1, $28 player
                          ; 2)
NameRow:
  DEFB $00                ; the table row the name goes into
NameScorePtr:
  DEFB $00,$00            ; the row's score
NameTextPtr:
  DEFB $00,$00            ; the row's name
BigScaleX:
  DEFB $00                ; the big print's horizontal scale
BigScaleY:
  DEFB $00                ; its vertical scale (lines a pixel)
BigRepeat:
  DEFB $00                ; its repeat
BigClear:
  DEFB $00                ; 0 OR the pixels, 1 clear them (the shadow)
CursorPos:
  DEFB $00,$00            ; the name entry's cursor (y, x)
BigMask:
  DEFB $00                ; the big print's current bit

; "HI SCORE|" (the table's heading) and "A|" (the trail intro's big digit:
; TrailIntro writes the trail's character over the A)
HiScoreTitle:
  INCBIN "res/texts/hiscore.bin",$0000,9
BigChar:
  INCBIN "res/texts/hiscore.bin",$0009,2

; The high score table's five names, six characters and | each
HiNames:
  INCBIN "res/texts/hinames.bin",$0000,30

; The five scores, five digits and | each: 20000, 15000, 10000, 05000, 03000
HiScores:
  INCBIN "res/texts/hiscores.bin",$0000,30

; The front end's jump table; the first entry JP Title
;
; Each entry is a JP. The game calls Title, InitTextWidths, Random, Print,
; LoadIntro, TrailIntro, ShowHud, FillAttrs, PixelMask, MenuSpriteAttrs,
; DetectKempston, BuildRowAddrs, BuildBufferRows, InitListWidths and
; CheckHiScore through it; the entries at $69AC, $69AF, $69B5, $69B8, $69BB,
; $69BE, $69C7, $69CA, $69CD, $69D9, $69E2 and $69E5 are called by no one
; (known only from the code).
;
; Witness: L1 5 (c1, itemlow, trail1, warp).
MenuTable:
  JP Title

; JP InitTextWidths
;
; Witness: L1 2 (c1, itemlow).
JpInitTextWidths:
  JP InitTextWidths

; JP FrameBox
;
; Known only from the code: no recording runs it.
JpFrameBox:
  JP FrameBox

; JP Dissolve
;
; Known only from the code: no recording runs it.
JpDissolve:
  JP Dissolve

; JP Random
;
; Witness: L1 1710 (c1, dropout, empty, fuel, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
JpRandom:
  JP Random

; JP AnyKey
;
; Known only from the code: no recording runs it.
JpAnyKey:
  JP AnyKey

; JP SelectKey
;
; Known only from the code: no recording runs it.
JpSelectKey:
  JP SelectKey

; JP ReadNewKey
;
; Known only from the code: no recording runs it.
JpReadNewKey:
  JP ReadNewKey

; JP ShowBufferAt
;
; Known only from the code: no recording runs it.
JpShowBufferAt:
  JP ShowBufferAt

; JP Print
;
; Witness: L1 4614 (c1, dropout, empty, kb, trail1, trails, wallcrash, warp).
JpPrint:
  JP Print

; JP LoadIntro
;
; Witness: L1 14 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
JpLoadIntro:
  JP LoadIntro

; JP Checker
;
; Known only from the code: no recording runs it.
JpChecker:
  JP Checker

; JP SpriteList
;
; Known only from the code: no recording runs it.
JpSpriteList:
  JP SpriteList

; JP AttrBoxes
;
; Known only from the code: no recording runs it.
JpAttrBoxes:
  JP AttrBoxes

; JP TrailIntro
;
; Witness: L1 25 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
JpTrailIntro:
  JP TrailIntro

; JP ShowHud
;
; Witness: L1 25 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
JpShowHud:
  JP ShowHud

; JP FillAttrs
;
; Witness: L1 12 (dropout, kb, trails, wallcrash, warp).
JpFillAttrs:
  JP FillAttrs

; JP AttrAddr
;
; Known only from the code: no recording runs it.
JpAttrAddr:
  JP AttrAddr

; JP PixelMask
;
; Witness: L1 32140 (c1, dropout, empty, fuel, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
JpPixelMask:
  JP PixelMask

; JP MenuSpriteAttrs
;
; Witness: L1 3446 (c1, dropout, empty, fuel, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
JpMenuSpriteAttrs:
  JP MenuSpriteAttrs

; JP ClearPixels
;
; Known only from the code: no recording runs it.
JpClearPixels:
  JP ClearPixels

; JP FillAttrsBase
;
; Known only from the code: no recording runs it.
JpFillAttrsBase:
  JP FillAttrsBase

; JP DetectKempston
;
; Witness: L1 2 (c1, itemlow).
JpDetectKempston:
  JP DetectKempston

; JP BuildRowAddrs
;
; Witness: L1 2 (c1, itemlow).
JpBuildRowAddrs:
  JP BuildRowAddrs

; JP BuildBufferRows
;
; Witness: L1 2 (c1, itemlow).
JpBuildBufferRows:
  JP BuildBufferRows

; JP InitListWidths
;
; Witness: L1 25 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
JpInitListWidths:
  JP InitListWidths

; JP CheckHiScore
;
; Witness: L1 4 (c1, kb, trail1, warp).
JpCheckHiScore:
  JP CheckHiScore

  ORG $6A09

; The intro before the first menu: clear, a checkered band, the ATV and the
; boxes of the loading picture
;
; Clears the screen (ClearScreen), draws a checkered band (Checker) and the
; sprite list LoadIntroSprites with the menu bank, then the attribute boxes
; LoadIntroBoxes. Called through JpLoadIntro by NewGame.
;
; Witness: L1 14 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
LoadIntro:
  CALL ClearScreen
  HALT
  LD A,$C8
  LD (SpriteX),A
  LD A,$B6
  LD (SpriteY),A
  LD B,$07
  LD C,$B0
  CALL Checker
  LD HL,DrawModes+$0002
  LD (ModeVector),HL
  LD HL,JpMenuSpriteAt
  LD (SpriteListCall+$0001),HL
  LD IX,LoadIntroSprites
  CALL SpriteList
  LD IX,LoadIntroBoxes
  JP AttrBoxes

; The trail's intro: "TRAIL NO." and the trail's number in big print, the name,
; the panels
;
; Clears the screen's attributes and pixels, prints TrailNoText twice (shadow
; and face) at scale 2 x 5, the trail's number (Trail + "b", a big digit) at
; scale 2 x 4, dissolves the buffer onto the screen, waits 50 frames, copies
; the trail's name (CopyTrailName) and prints it and the intro picture
; (TrailIntroBoxes), waits 150 frames, then draws one or two players' panels
; (PanelP1, PanelP2), each coloured by TrailAttrs. Called through JpTrailIntro
; before each trail (c1 frame 15 800).
;
; Witness: L1 25 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
TrailIntro:
  LD HL,Attributes
  LD (AttrBase),HL
  XOR A
  CALL FillAllAttrs
  CALL ClearTopHalf
  CALL ClearBottomHalf
  LD A,$06
  CALL FillAllAttrs
  CALL JpClearBufferP1
  LD HL,BufferP1
  LD (BufferBase),HL
  XOR A
  LD (BigClear),A
  LD HL,DrawModes+$0010
  LD (ModeVector),HL
  LD IX,TrailTexts
  LD A,$02
  LD (BigScaleX),A
  LD HL,$0205
  LD (BigScaleY),HL
  LD HL,$004F
  CALL PrintAt
  LD A,$01
  LD (BigClear),A
  LD IX,TrailTexts
  LD A,$05
  LD (BigRepeat),A
  LD HL,$024E
  CALL PrintAt
  XOR A
  LD (BigClear),A
  LD IX,TrailTexts
  LD HL,$034E
  CALL PrintAt
  LD A,$02
  LD (BigScaleX),A
  LD HL,$0204
  LD (BigScaleY),HL
  LD A,(Trail)
  ADD A,$62
  LD IX,BigChar
  LD (IX+$00),A
  LD HL,$404F
  CALL PrintAt
  LD A,$01
  LD (BigClear),A
  LD A,$04
  LD (BigRepeat),A
  LD IX,BigChar
  LD HL,$424F
  CALL PrintAt
  XOR A
  LD (BigClear),A
  LD IX,BigChar
  LD HL,$434F
  CALL PrintAt
  LD H,$08
  LD L,$A5
  CALL ScreenAddrHL
  EX DE,HL
  LD HL,BufferP1
  CALL Dissolve
  LD B,$32
l_6AE6:
  HALT
  DJNZ l_6AE6
  CALL CopyTrailName
  CALL JpClearBufferP1
  LD HL,BufferP1
  LD (BufferBase),HL
  LD IX,TrailNameSlot
  LD A,$02
  LD (BigScaleX),A
  LD HL,$0203
  LD (BigScaleY),HL
  LD HL,$033F
  CALL PrintAt
  LD IX,TrailIntroBoxes
  CALL AttrBoxes
  LD HL,$084F
  CALL ShowBufferPlace
  LD B,$96
l_6B19:
  HALT
  DJNZ l_6B19
  LD HL,DrawModes+$0002
  LD (ModeVector),HL
  LD HL,JpGameSpriteAt
  LD (SpriteListCall+$0001),HL
  LD A,(Riding)
  AND $01
  CALL NZ,PanelP1
  LD A,(Riding)
  AND $02
  CALL NZ,PanelP2
  JP TrailAttrs

; Write E into B lines down from HL (screen)
;
; Witness: L1 4878 (c1, dropout, empty, fuel, itemlow, kb, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
FillColumn:
  LD (HL),E
  CALL JpNextLineHL
  DJNZ FillColumn
  RET

; The second player's half: its frame, its HUD, the FUEL and SPEED bars
;
; The bottom half's sprite list PanelP2Sprites, the side lines (E = $0F / $F0
; down 88 lines), the record copy (CopyRecordP2), the HUD at y 6, ShowBars,
; ShowMaxTime and the attribute boxes PanelP2Boxes. Only in a two-player game
; (menu: 2 runs).
;
; Witness: L1 3 (dropout, kb).
PanelP2:
  CALL ClearBottomHalf
  LD IX,PanelP2Sprites
  CALL SpriteList
  LD HL,$0058
  CALL ScreenAddrHL
  LD B,$58
  LD E,$0F
  CALL FillColumn
  LD E,$07
  LD (HL),E
  LD HL,GameGfx+$28FC
  CALL ScreenAddrHL
  LD B,$58
  LD E,$F0
  CALL FillColumn
  LD E,$E0
  LD (HL),E
  CALL JpLoadRecordP2
  LD A,$06
  LD (HudY),A
  CALL JpShowBars
  CALL JpSaveRecordP2
  LD IX,PanelP2Boxes
  CALL AttrBoxes
  LD IX,$0828
  LD IY,$0808
  JP TrailAttrs

; The first player's half: its frame, its HUD, the bars
;
; As PanelP2 for the top half (y $BE).
;
; Witness: L1 25 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
PanelP1:
  CALL ClearTopHalf
  LD IX,PanelP1Sprites
  CALL SpriteList
  LD HL,$00BF
  CALL ScreenAddrHL
  LD E,$07
  LD (HL),E
  CALL JpNextLineHL
  LD B,$57
  LD E,$0F
  CALL FillColumn
  LD HL,GameGfx+$2963
  CALL ScreenAddrHL
  LD E,$E0
  LD (HL),E
  CALL JpNextLineHL
  LD B,$57
  LD E,$F0
  CALL FillColumn
  CALL JpLoadRecordP1
  LD A,$BE
  LD (HudY),A
  CALL JpShowBars
  CALL JpSaveRecordP1
  LD IX,PanelP1Boxes
  CALL AttrBoxes
  LD IX,$0888
  LD IY,$0868
  JP TrailAttrs

; A checkered band: B columns of C lines from the position in SpriteX/SpriteY,
; $AA and $55 by turns
;
; Witness: L1 14 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
Checker:
  CALL GfxTable
  SRL C
l_6BE1:
  PUSH HL
  PUSH BC
  CALL CheckerColumn
  POP BC
  POP HL
  INC HL
  DJNZ l_6BE1
  RET

; One column of the band
;
; Witness: L1 98 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
CheckerColumn:
  LD E,$AA
  PUSH HL
  PUSH BC
  CALL FillEveryOther
  POP BC
  POP HL
  CALL JpNextLineHL
  LD E,$55

; Write E to every other line, C times
;
; Witness: L1 17248 (c1, dropout, empty, fuel, itemlow, kb, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
FillEveryOther:
  LD (HL),E
  CALL JpNextLineHL
  CALL JpNextLineHL
  DEC C
  JR NZ,FillEveryOther
  RET

; DestAddr = the buffer address of SpriteX / SpriteY; JP MenuSpriteGo
;
; Witness: L1 6 (c1, menu, trail1, warp).
PutMenuSprite:
  CALL JpBufferAddr
  LD (DestAddr),HL
  JP JpMenuSprite

; DestAddr = the buffer address; JP GameSpriteGo
;
; Witness: L1 24 (c1, menu, trail1, warp).
PutGameSprite:
  CALL JpBufferAddr
  LD (DestAddr),HL
  JP JpGameSprite

; Draw a list of sprites: x, y, sprite number, ending $FF
;
; IX the list. Each item through the routine in SpriteListCall ($6C2A, set by
; the caller to MenuSprite, GameSprite, PutMenuSprite or PutGameSprite).
;
; Witness: L1 290 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
SpriteList:
  LD A,(IX+$00)
  LD (SpriteX),A
  LD A,(IX+$01)
  LD (SpriteY),A
  LD A,(IX+$02)
  LD (SpriteNum),A
SpriteListCall:
  CALL JpMenuSpriteAt     ; CALL (the operand patched): the sprite routine
  LD DE,$0003
  ADD IX,DE
  LD A,(IX+$00)
  CP $FF
  RET Z
  JP SpriteList

; A = A / 8 + 1 (pixels to attribute cells)
;
; Witness: L1 953 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
CellCount:
  SRL A
  SRL A
  SRL A
  ADD A,$01
  RET

; Colour a list of boxes: x1, y1, x2, y2, attribute; ending $FF
;
; IX the list; each box FillAttrs over (x2-x1)/8+1 columns and (y1-y2)/8+1
; rows.
;
; Witness: L1 449 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
AttrBoxes:
  LD H,(IX+$00)
  LD A,(IX+$02)
  SUB H
  RET C
  CALL CellCount
  LD B,A
  LD L,(IX+$01)
  LD A,L
  LD E,(IX+$03)
  SUB E
  RET C
  CALL CellCount
  LD C,A
  LD A,(IX+$04)
  CALL FillAttrs
  LD DE,$0005
  ADD IX,DE
  LD A,(IX+$00)
  CP $FF
  RET Z
  JR AttrBoxes

; Zero the clock, draw the HUD's sprites and boxes, the maximum time and the
; clock
;
; Witness: L1 25 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
ShowHud:
  LD HL,$3030
  LD (Clock),HL
  LD (ClockTens),HL
  LD HL,Screen
  LD (ScreenBase),HL
  LD HL,DrawModes+$0002
  LD (ModeVector),HL
  LD HL,JpGameSpriteAt
  LD (SpriteListCall+$0001),HL
  LD IX,HudSprites
  CALL SpriteList
  LD IX,HudBoxes
  CALL AttrBoxes
  CALL JpShowClock
  JP JpShowMaxTime

; Sprite lists (x, y, sprite, $FF the end) and attribute box lists (x1, y1, x2,
; y2, attribute, $FF) of the panels, the HUD and the intros
;
; $6C9E PanelP1Sprites, $6CAB PanelP2Sprites, $6CB8 HudSprites, $6CBF
; LoadIntroSprites (sprite lists); $6CD5 LoadIntroBoxes, $6CEF PanelP2Boxes,
; $6D18 PanelP1Boxes, $6D41 HudBoxes (box lists).
PanelP1Sprites:
  INCBIN "res/tables/panels.bin",$0000,13
PanelP2Sprites:
  INCBIN "res/tables/panels.bin",$000D,13
HudSprites:
  INCBIN "res/tables/panels.bin",$001A,7
LoadIntroSprites:
  INCBIN "res/tables/panels.bin",$0021,22
LoadIntroBoxes:
  INCBIN "res/tables/panels.bin",$0037,26
PanelP2Boxes:
  INCBIN "res/tables/panels.bin",$0051,41
PanelP1Boxes:
  INCBIN "res/tables/panels.bin",$007A,41
HudBoxes:
  INCBIN "res/tables/panels.bin",$00A3,16

; Draw the frame of a box in the buffer (the menus' frames)
;
; The buffer address of SpriteX / SpriteY, B the width in pixels, C the height:
; a top line, C-2 sides ($0F ... $E0), a bottom line.
;
; Witness: L1 33 (c1, kb, menu, trail1, turn, warp).
FrameBox:
  CALL JpBufferAddr
  SRL B
  SRL B
  SRL B
  DEC B
  DEC B
  DEC C
  DEC C
  PUSH HL
  CALL FrameLine
  POP HL
  LD DE,$0016
  ADD HL,DE
l_6D67:
  PUSH HL
  LD (HL),$0F
  CALL FillFF
  LD (HL),$E0
  POP HL
  LD DE,$0016
  ADD HL,DE
  DEC C
  JR NZ,l_6D67

; A frame's top or bottom line: $03, $FF bytes, $C0
;
; Witness: L1 66 (c1, kb, menu, trail1, turn, warp).
FrameLine:
  LD (HL),$03
  CALL FillFF
  LD (HL),$C0
  RET

; B bytes of $FF after HL
;
; Witness: L1 1902 (c1, kb, menu, trail1, turn, warp).
FillFF:
  PUSH BC
  INC HL
l_6D81:
  LD (HL),$FF
  INC HL
  DJNZ l_6D81
  POP BC
  RET

; Bring the buffer onto the screen by eight passes of rotating its bits in from
; the sides
;
; HL the buffer, DE the screen address. Each pass rotates each line's 22 bytes,
; the left 11 through RotateLeft and the right through RotateRight, so the
; picture slides in from both sides, with a delay of $1E x 256 loops between
; passes. Used by the title, the high scores, the menus and the trail intro
; (c1: 28 calls).
;
; Witness: L1 39 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
Dissolve:
  LD C,$08
l_6D8A:
  PUSH DE
  PUSH HL
  LD B,$28
l_6D8E:
  PUSH BC
  PUSH DE
  LD B,$0B
l_6D92:
  CALL RotateLeft
  CALL RotateRight
  DJNZ l_6D92
  POP DE
  CALL JpNextLineDE
  PUSH DE
  LD B,$0B
l_6DA1:
  CALL RotateRight
  CALL RotateLeft
  DJNZ l_6DA1
  POP DE
  CALL JpNextLineDE
  POP BC
  DJNZ l_6D8E
  PUSH BC
  LD C,$1E
l_6DB3:
  LD B,$00
l_6DB5:
  DJNZ l_6DB5
  DEC C
  JR NZ,l_6DB3
  POP BC
  POP HL
  POP DE
  DEC C
  JR NZ,l_6D8A
  RET

; Rotate a buffer byte left into the screen byte
;
; Witness: L1 274560 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
RotateLeft:
  RL (HL)
  LD A,(DE)
  RLA
  LD (DE),A
  INC HL
  INC DE
  RET

; Rotate a buffer byte right into the screen byte
;
; Witness: L1 274560 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
RotateRight:
  RR (HL)
  LD A,(DE)
  RRA
  LD (DE),A
  INC HL
  INC DE
  RET

; Border black, clear the screen and its attributes ($45), wait for no key, 60
; frames
;
; Also the main menu's START action: the menu returns to NewGame.
;
; Witness: L1 37 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
ClearScreen:
  EI
  XOR A
  OUT ($FE),A
  LD HL,Screen
  LD (ScreenBase),HL
  LD HL,Attributes
  LD (AttrBase),HL
  LD A,$45
  LD (FillByte),A
  CALL FillAttrsBase
  CALL ClearPixels
  JP WaitKey60

; Copy the tune player from $5B00 back to $F850 (no caller; Title and TrailEnd
; do it inline)
;
; Known only from the code.
RestoreTunePlayer:
  LD HL,TunePlayerCopy
  LD DE,TunePlay0
  LD BC,$05AB
  LDIR
  RET

; The title sequence: the credits, the high scores, the menus, the title tune
;
; Copies TunePlayerCopy ($5B00, $5AB bytes) back to $F850, sets TuneTimer =
; $04C8, then credits (Credits), the high scores (HiScoreScreen), the menu
; pages; ends in MenuLoop. OuterLoop calls it through MenuTable ($69A6, JP
; Title) (c1: from frame 14 101; the menu at 14 640).
;
; Witness: L1 5 (c1, itemlow, trail1, warp).
Title:
  LD HL,TunePlayerCopy
  LD DE,TunePlay0
  LD BC,$05AB
  LDIR
  LD HL,$04C8
  LD (TuneTimer),HL
  CALL ClearScreen
  CALL WaitKey60
  CALL TrailListScreen
  LD HL,BufferP1
  CALL Dissolve
  CALL WaitKey60
  CALL WaitKey60
  CALL TrailListScreen
  CALL Scroller
  CALL WaitKey60
  CALL Credits
  CALL WaitKey60
  LD IY,MenuDefs
  CALL MenuBox
  CALL MenuDraw
  CALL MenuShowDissolve
  XOR A
  LD (MenuItem),A
  LD (HiScorePage),A
  CALL HiScoreScreen
  JP MenuLoop

; Wait 60 frames or a key or fire (carry set on a key)
;
; Witness: L1 60 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
WaitKey60:
  EI
  CALL JpClearKeys
  LD B,$3C
l_6E50:
  PUSH BC
  HALT
  CALL AnyKey
  POP BC
  RET C
  DJNZ l_6E50
  RET

; The random generator's seed word
RandomSeed:
  DEFB $00,$0C

; A byte from the ROM at RandomSeed; L + 3, but H AND $1B is taken before INC
; H, so the pointer stays in its page ($08): Noise reads the same 256 ROM bytes
; over and over
;
; HL = RandomSeed; H AND $1B (taken before the INC H, so H keeps its value), L
; + 3; A = the ROM's byte at the new HL. The noise effect (Noise $D9AF) is its
; only caller.
;
; Witness: L1 1710 (c1, dropout, empty, fuel, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
Random:
  LD HL,(RandomSeed)
  LD A,H
  INC H
  AND $1B
  LD H,A
  INC L
  INC L
  INC L
  LD (RandomSeed),HL
  LD A,(HL)
  RET

; Scroll the buffer's credits 32 times (the second credit screen)
;
; Witness: L1 5 (c1, itemlow, trail1, warp).
Scroller:
  LD B,$20
l_6E6E:
  PUSH BC
  PUSH DE
  LD HL,BufferP1
  CALL ShowBufferAt
  POP DE
  CALL JpNextLineDE
  CALL JpNextLineDE
  POP BC
  DJNZ l_6E6E
  RET

; The credits: the ATV picture, the sprites and boxes, "ALL TERRAIN VEHICLE"
; and the names
;
; Witness: L1 6 (c1, menu, trail1, warp).
Credits:
  LD H,$28
  LD L,$BF
  LD BC,$160F
  XOR A
  CALL FillAttrs
  CALL JpClearBufferP1
  LD HL,BufferP1
  LD (BufferBase),HL
  LD HL,DrawModes+$000A
  LD (ModeVector),HL
  LD HL,PutMenuSprite
  LD (SpriteListCall+$0001),HL
  LD IX,CreditSprites1
  CALL SpriteList
  LD HL,PutGameSprite
  LD (SpriteListCall+$0001),HL
  LD IX,CreditSprites2
  CALL SpriteList
  LD HL,ListModes
  LD (ModeVector),HL
  LD IX,MenuTexts+$00E8
  LD A,(IX+$01)
  SUB $38
  LD H,A
  LD L,$2F
  CALL PrintAt
  LD IX,CreditBoxes
  CALL AttrBoxes
  LD HL,$28BF
  JP ShowBufferPlace

; The trail intro's attribute boxes and the credits' sprite and box lists
;
; $6ED7 TrailIntroBoxes, $6EE2 CreditBoxes (box lists); $6EFC CreditSprites1,
; $6F00 CreditSprites2 (sprite lists).
TrailIntroBoxes:
  INCBIN "res/tables/credits.bin",$0000,11
CreditBoxes:
  INCBIN "res/tables/credits.bin",$000B,26
CreditSprites1:
  INCBIN "res/tables/credits.bin",$0025,4
CreditSprites2:
  INCBIN "res/tables/credits.bin",$0029,13
HiScorePage:
  INCBIN "res/tables/credits.bin",$0036,1

; Show the high score table (every other time: the trail list)
;
; Witness: L1 5 (c1, menu, trail1, warp).
HiScoreScreen:
  CALL ClearMenuSpare
  LD A,(HiScorePage)
  XOR $01
  LD (HiScorePage),A
  JR NZ,l_6F1E
  JP l_6F7E
l_6F1E:
  PUSH IY
  CALL JpClearBufferP1
  LD HL,BufferP1
  LD (BufferBase),HL
  LD A,$20
  LD (SpriteX),A
  LD A,$28
  LD (SpriteY),A
  CALL JpBufferAddr
  LD (DestAddr),HL
  LD A,$5D
  LD (SpriteNum),A
  LD HL,DrawModes
  LD (ModeVector),HL
  CALL JpGameSprite
  LD HL,(SpriteData)
  LD (MaskData),HL
  LD A,$5C
  LD (SpriteNum),A
  CALL JpGameSprite
  LD HL,(ListModes+$0006)
  LD DE,l_6F1E+$003F
  PUSH DE
  JP (HL)
  LD HL,(DestAddr)
  LD DE,$000D
  ADD HL,DE
  LD (DestAddr),HL
  LD HL,(ListModes+$0004)
  LD DE,l_6F1E+$0051
  PUSH DE
  JP (HL)
  CALL HiScoreLines
  CALL ShowAt284F
  LD HL,BufferP1
  CALL Dissolve
  POP IY
  RET
l_6F7E:
  PUSH IY
  CALL TrailListScreen
  CALL ShowAt284F
  LD HL,BufferP1
  CALL Dissolve
  POP IY
  RET

; DE = the screen address of x $28, y $4F (the menus' buffer place)
;
; Witness: L1 5 (c1, menu, trail1, warp).
ShowAt284F:
  LD HL,$284F
  CALL ScreenAddrHL
  EX DE,HL
  RET

; The six trail names in the buffer
;
; Witness: L1 11 (c1, itemlow, menu, trail1, warp).
TrailListScreen:
  CALL JpClearBufferP1
  LD HL,BufferP1
  LD (BufferBase),HL
  CALL TrailListLines
  LD HL,$288F
  CALL ScreenAddrHL
  EX DE,HL
  RET

; Print TrailList's lines
;
; Witness: L1 11 (c1, itemlow, menu, trail1, warp).
TrailListLines:
  LD HL,ListModes
  LD (ModeVector),HL
  LD IX,MenuTexts+$00FC
  LD A,$42
  LD (SpriteY),A
l_6FBA:
  LD A,(IX+$00)
  SUB $27
  LD (SpriteX),A
  INC IX
  INC IX
  CALL Print
  LD E,$0C
  INC IX
  LD A,(IX+$02)
  CP $4D
  JR Z,l_6FE0
  CP $50
  JR Z,l_6FE0
  LD A,(IX+$00)
  CP $FF
  RET Z
  LD E,$0A
l_6FE0:
  LD A,(SpriteY)
  SUB E
  LD (SpriteY),A
  JR l_6FBA

; A lone RET (no caller)
;
; Known only from the code.
ReturnByte:
  RET

; Print the five names and scores
;
; Witness: L1 4 (c1, trail1, warp).
HiScoreLines:
  LD HL,ListModes
  LD (ModeVector),HL
  LD HL,HiNames
  LD IY,HiScores
  LD A,$47
  LD (SpriteY),A
  LD B,$05
l_6FFE:
  PUSH BC
  PUSH HL
  LD A,$30
  LD (SpriteX),A
  PUSH HL
  POP IX
  CALL Print
  LD A,$60
  LD (SpriteX),A
  PUSH IY
  POP IX
  CALL Print
  LD A,(SpriteY)
  SUB $09
  LD (SpriteY),A
  LD DE,$0006
  POP HL
  ADD HL,DE
  ADD IY,DE
  POP BC
  DJNZ l_6FFE
  RET

; The menus: count, x, y, height, then for each item its text and its action (0
; none)
;
; $702A main (START $6DD1 ClearScreen, ONE/TWO PLAYERS MenuPlayers, CHOOSE
; CONTROL MenuControl), $703A player 1's controls (KEYBOARD, KEMPSTON, EXIT),
; $704A, $7056 player 2's (KEYBOARD, SINCLAIR), $7062 player 1's keys, $707E
; player 2's keys (five items each, RedefineKey), $709A PLAYER ONE, $70A2
; PLAYER TWO (titles).
MenuDefs:
  INCBIN "res/tables/menus.bin",$0000,16
MenuControls1:
  INCBIN "res/tables/menus.bin",$0010,16
MenuControls2a:
  INCBIN "res/tables/menus.bin",$0020,12
MenuControls2:
  INCBIN "res/tables/menus.bin",$002C,12
MenuKeys1:
  INCBIN "res/tables/menus.bin",$0038,28
MenuKeys2:
  INCBIN "res/tables/menus.bin",$0054,28
MenuPlayerOne:
  INCBIN "res/tables/menus.bin",$0070,8
MenuPlayerTwo:
  INCBIN "res/tables/menus.bin",$0078,8

; The front end's texts: two bytes (their centring and width, written by
; InitTextWidths), the characters, |
;
; "]" moves the print to x $78 (the key's column). $FF ends the list.
MenuTexts:
  INCBIN "res/texts/menu.bin",$0000,354

; Set the box from a menu (IY): x, y, item count; the line spacing $10 (or $0E
; for six or more items)
;
; Witness: L1 37 (c1, kb, menu, trail1, turn, warp).
MenuBox:
  LD A,(IY+$01)
  LD (MenuBoxX),A
  LD A,(IY+$02)
  LD (MenuBoxY),A
  LD A,$10
  LD (LineSpacing),A
  LD A,(IY+$00)
  LD (MenuCount),A
  SLA A
  ADD A,$01
  LD (MenuBoxHeight),A
  CP $09
  RET C
  LD A,(IY+$00)
  ADD A,$02
  LD (MenuBoxHeight),A
  LD A,$08
  LD (LineSpacing),A
  RET

; Clear the buffer and draw the menu's frame
;
; Witness: L1 33 (c1, kb, menu, trail1, turn, warp).
MenuBoxDraw:
  CALL JpClearBufferP1
  LD A,$08
  LD (SpriteX),A
  LD A,$4B
  LD (SpriteY),A
  LD HL,BufferP1
  LD (BufferBase),HL
  LD B,$90
  LD A,(MenuBoxHeight)
  SLA A
  SLA A
  SLA A
  ADD A,$06
  LD C,A
  JP FrameBox

; The frame (FrameBox) at the box's place
;
; Witness: L1 33 (c1, kb, menu, trail1, turn, warp).
MenuBoxFrame:
  LD A,(MenuBoxX)
  LD H,A
  LD A,(MenuBoxY)
  LD L,A
  LD B,$12
  LD A,(MenuBoxHeight)
  ADD A,$02
  LD C,A
  LD A,(IY+$03)
  CALL FillAttrs
  LD A,(MenuBoxX)
  ADD A,$08
  LD H,A
  LD A,(MenuBoxY)
  SUB $08
  LD L,A
  LD B,$10
  LD A,(MenuBoxHeight)
  LD C,A
  LD A,$1F
  JP FillAttrs

; Clear the box's attributes
;
; Witness: L1 5 (menu, turn).
MenuBoxClear:
  LD A,(MenuBoxX)
  LD H,A
  LD A,(MenuBoxY)
  LD L,A
  LD B,$12
  LD C,$0A
  XOR A
  CALL FillAttrs
  HALT
  RET

; The box into the screen by Dissolve
;
; Witness: L1 4 (c1, trail1, warp).
MenuShowDissolve:
  CALL MenuBoxScreen
  LD HL,BufferP1
  CALL Dissolve
  RET

; The box into the screen by ShowBuffer
;
; Witness: L1 27 (kb, menu, turn, warp).
MenuShow:
  CALL MenuBoxScreen
  HALT
  LD HL,BufferP1
  JP ShowBufferAt

; DE = the screen address of the box
;
; Witness: L1 31 (c1, kb, menu, trail1, turn, warp).
MenuBoxScreen:
  LD A,(MenuBoxX)
  SUB $08
  LD (SpriteX),A
  LD A,(MenuBoxY)
  LD (SpriteY),A
  CALL GfxTable
  EX DE,HL
  RET

; The menu's line spacing (lines)
LineSpacing:
  DEFB $10

; Print the menu's item texts, one under another
;
; Witness: L1 33 (c1, kb, menu, trail1, turn, warp).
MenuItems:
  PUSH IY
  LD HL,BufferP1
  LD (BufferBase),HL
  LD HL,DrawModes+$000A
  LD (ModeVector),HL
  LD A,(IY+$00)
  LD B,A
  INC IY
  INC IY
  INC IY
  INC IY
l_72E0:
  PUSH BC
  LD L,(IY+$00)
  LD H,(IY+$01)
  PUSH HL
  POP IX
  LD A,(IX+$00)
  SUB $2E
  LD (SpriteX),A
  LD A,(LineSpacing)
  CP $10
  JR Z,l_7303
  LD A,(SpriteX)
  AND $F8
  OR $05
  LD (SpriteX),A
l_7303:
  INC IX
  INC IX
  CALL Print
  LD A,(LineSpacing)
  LD E,A
  LD A,(SpriteY)
  SUB E
  LD (SpriteY),A
  LD DE,$0004
  ADD IY,DE
  POP BC
  DJNZ l_72E0
  POP IY
  RET

; Draw the menu (MenuDraw) and show it
;
; Witness: L1 19 (kb, menu, warp).
MenuRedraw:
  CALL MenuDraw
  JP MenuShow

; Draw a menu, show it and run the menu loop again
;
; Witness: L1 5 (menu, turn).
MenuOpen:
  CALL MenuDraw
  CALL MenuShow
  JP l_73A3

; The box, the frame and the items of the menu at IY
;
; Witness: L1 33 (c1, kb, menu, trail1, turn, warp).
MenuDraw:
  CALL MenuBox
  CALL MenuBoxDraw
  LD A,$3F
  LD (SpriteY),A
  CALL MenuItems
  JP MenuBoxFrame

; The title tune's interrupt hook: count TuneTimer, run the menu
;
; TuneHook calls it every frame while the title tune plays (c1: 1517 runs; 5388
; over the seven recordings); it counts TuneTimer (MenuTimer), checks the keys
; (any Kempston direction or fire when KempstonOn: port $1F AND $1F) and
; returns to the tune player. When TuneTimer's low byte wraps with the high
; byte's low nibble $0A it shows the high scores and stops the tune: first at
; $0A00 (Title starts the timer at $04C8: 1 336 interrupts, 26.7 s), then every
; $1000.
;
; Witness: L1 5424 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
MenuTick:
  CALL MenuTimer
  JR NZ,l_7353
  LD A,H
  AND $0F
  CP $0A
  JP NZ,l_7353
  CALL HiScoreScreen
  JP TuneStop
l_7353:
  LD A,(KempstonOn)
  CP $00
  JP Z,TuneKeyCheck
  LD BC,$001F
  IN A,(C)
  AND $1F
  JP Z,TuneKeyCheck
  JP TuneStop

; TuneTimer + 1; Z when its low byte wraps
;
; Witness: L1 5877 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
MenuTimer:
  LD HL,(TuneTimer)
  INC HL
  LD (TuneTimer),HL
  LD A,L
  CP $00
  RET

; Wait until no key and no fire
;
; Witness: L1 71072 (c1, menu, trail1, turn, warp).
WaitNoKey:
  CALL JpClearKeys
  CALL AnyKey
  JR C,WaitNoKey
  RET

; The menu: highlight, the title tune, keys up and down, select
;
; Starts TunePlay with tune 0 and TuneHook = MenuTick; after a key stops it,
; the loop moves the highlight (any key the next item), SPACE/fire selects
; (MenuDispatch); TuneTimer reaching $8000 (counted here once a HALT after the
; tune stops) goes back to Title; the $0400 test ($73C2) is never met (the
; timer starts at $04C8, Title resets it at $8000); the high scores come from
; MenuTick at $0A00.
;
; Witness: L1 7 (c1, menu, trail1, turn, warp).
MenuLoop:
  CALL WaitNoKey
  LD A,$5E
  CALL Highlight
  LD HL,MenuTick
  LD (TuneHook+$0001),HL
  PUSH IY
  LD IY,$0100
  XOR A
  CALL TunePlay
  CALL JpSetupIm2
  EI
  POP IY
  LD HL,TuneKeyCheck
  LD (TuneHook+$0001),HL
  JP l_73B5
; This entry point is used by the routine at MenuOpen.
l_73A3:
  CALL ClearMenuSpare
  XOR A
  LD (MenuItem),A
; This entry point is used by the routines at MenuKeys2Select and MenuPlayers.
l_73AA:
  LD A,$5E
  CALL Highlight
  CALL WaitNoKey
  CALL JpClearKeys
l_73B5:
  HALT
  LD A,(MenuCount)
  CP $06
  JR NC,l_73D3
  CALL MenuTimer
  JR NZ,l_73CD
  LD A,H
  CP $04
  JR NZ,l_73CD
  CALL HiScoreScreen
  JP MenuLoop
l_73CD:
  LD A,H
  CP $80
  JP Z,Title
l_73D3:
  CALL AnyKey
  JP NC,l_73B5
  CALL ClearMenuSpare
  CALL SelectKey
  JP C,MenuDispatch
  LD A,$1F
  CALL Highlight
  HALT
  HALT
  HALT
  LD A,(MenuCount)
  LD E,A
  LD A,(MenuItem)
  ADD A,$01
  CP E
  JR C,l_73F7
  XOR A
l_73F7:
  LD (MenuItem),A
  JP l_73AA

; MenuSpare ($6725) = 0: a byte written here and read by no one
;
; Witness: L1 45 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
ClearMenuSpare:
  XOR A
  LD (MenuSpare),A
  RET

; Carry when any key or the Kempston's fire is down
;
; Witness: L1 77950 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
AnyKey:
  CALL JpScanKeys
  LD HL,KeyStates
  LD B,$28
l_740A:
  LD A,(HL)
  ADD A,$FF
  RET C
  INC HL
  DJNZ l_740A
  LD A,(KempstonOn)
  CP $00
  RET Z
  LD A,(JoyBits)
  AND $1F
  ADD A,$FF
  RET

; Carry when SPACE, 0 or the Kempston's fire is down (ENTER is not read here:
; it moves)
;
; Witness: L1 35 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
SelectKey:
  LD A,(KeyStates+$0023)
  ADD A,$FF
  RET C
  LD A,(KeyStates+$0014)
  ADD A,$FF
  RET C
  LD A,(KempstonOn)
  CP $00
  RET Z
  LD A,(JoyBits)
  AND $10
  ADD A,$FF
  RET

; Colour the current item's line with A
;
; Witness: L1 45 (c1, menu, trail1, turn, warp).
Highlight:
  PUSH AF
  CALL ItemPtr
  PUSH HL
  POP IX
  LD A,(LineSpacing)
  LD E,A
  LD A,(MenuItem)
  CALL JpMultiply
  LD A,(MenuBoxY)
  SUB L
  SUB $10
  LD L,A
  LD A,(MenuBoxX)
  LD E,A
  LD A,(IX+$00)
  SUB $36
  ADD A,E
  LD H,A
  LD A,(IX+$01)
  CP $10
  JR C,l_7465
  LD A,$10
l_7465:
  LD B,A
  LD C,$01
  POP AF
  CALL FillAttrs
  RET

; IX = the current item's place in the menu (IY): HL its text
;
; Witness: L1 81 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
ItemPtr:
  PUSH IY
  POP IX
  LD DE,$0004
  ADD IX,DE
  LD A,(MenuItem)
  LD E,A
  SLA E
  SLA E
  LD D,$00
  ADD IX,DE
  LD L,(IX+$00)
  LD H,(IX+$01)
  RET

; Jump to the current item's action
;
; Witness: L1 25 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
MenuDispatch:
  CALL ItemPtr
  LD L,(IX+$02)
  LD H,(IX+$03)
  JP (HL)

; Show the main menu again
;
; Witness: L1 3 (menu, turn).
MenuMain:
  LD IY,MenuDefs
  CALL MenuDraw
  CALL MenuShow
  XOR A
  LD (MenuItem),A
  JP MenuLoop

; CHOOSE CONTROL: one player's menu, or both players' in turn
;
; Witness: L1 3 (menu, turn).
MenuControl:
  LD A,(PlayerCount)
  CP $00
  JR NZ,l_74B8
  LD IY,MenuControls1
  CALL MenuOpen
  CALL MenuBoxClear
  JP MenuMain
l_74B8:
  LD A,$02
  LD (PlayerCount),A
  CALL MenuBoxClear
  LD IY,MenuPlayerOne
  CALL MenuRedraw
  LD IY,MenuControls2a
  CALL MenuOpen
  LD A,$01
  LD (PlayerCount),A
  CALL MenuBoxClear
  LD IY,MenuPlayerTwo
  CALL MenuRedraw
  LD IY,MenuControls2
  CALL MenuOpen
  CALL Credits
  JP MenuMain

; Player 1's keyboard: Kempston off, redefine
;
; Witness: L1 1 (menu).
MenuKeys1Select:
  XOR A
  LD (KempstonOn),A
  LD (Keyboard1Alt),A
  LD IY,MenuKeys1
  JR l_7501

; Player 2's keyboard: Sinclair off, redefine
;
; Witness: L1 1 (menu).
MenuKeys2Select:
  XOR A
  LD (SinclairOn),A
  LD IY,MenuKeys2
  JR l_7501
; This entry point is used by the routine at MenuKeys1Select.
l_7501:
  CALL MenuDraw
  CALL MenuRedraw
  XOR A
  LD (MenuItem),A
  LD B,$05
l_750D:
  PUSH BC
  CALL RedefineKey
  LD A,(MenuItem)
  ADD A,$01
  LD (MenuItem),A
  POP BC
  DJNZ l_750D
  JP l_73AA

; Highlight a key's line, wait for a key, store it, print it
;
; Witness: L1 10 (menu).
RedefineKey:
  LD A,$F3
  CALL Highlight
  CALL ReadNewKey
  PUSH AF
  PUSH DE
  CALL ItemPtr
l_752C:
  INC HL
  LD A,(HL)
  CP $7C
  JR NZ,l_752C
  PUSH HL
  POP IX
  CALL KeySlot
  POP DE
  POP AF
  LD (IX-$01),A
  LD (HL),E
  CALL MenuRedraw
  RET

; Wait for a key: its index in KeyStates (0-39); any key is taken, even one
; already in use (no comparison with the table)
;
; Witness: L1 10 (menu).
ReadNewKey:
  CALL JpClearKeys
  CALL AnyKey
  JR C,ReadNewKey
l_754A:
  CALL AnyKey
  JR NC,l_754A
  LD A,$28
  SUB B
  CP $28
  JR Z,ReadNewKey
  LD E,A
  LD D,$00
  LD HL,KeyChars
  ADD HL,DE
  LD A,(HL)
  CP $5F
  JR Z,ReadNewKey
  RET

; HL = the player's key slot for the current item (KeyIndexes)
;
; Witness: L1 10 (menu).
KeySlot:
  PUSH AF
  LD A,(PlayerCount)
  SUB $01
  AND $01
  XOR $01
  LD E,$05
  CALL JpMultiply
  LD DE,KeyIndexes1
  ADD HL,DE
  LD A,(MenuItem)
  LD E,A
  LD D,$00
  ADD HL,DE
  POP AF
  RET

; The texts of the main menu's players item: ONE PLAYER, TWO PLAYERS
PlayerTexts:
  DEFW $70CA,$70D7

; ONE / TWO PLAYERS: toggle PlayerCount and the item's text
;
; Witness: L1 1 (menu).
MenuPlayers:
  LD A,(PlayerCount)
  XOR $01
  LD (PlayerCount),A
  LD E,A
  SLA E
  LD D,$00
  LD HL,PlayerTexts
  ADD HL,DE
  PUSH HL
  CALL ItemPtr
  PUSH IX
  POP DE
  POP HL
  LD BC,$0002
  LDIR
  CALL MenuRedraw
  JP l_73AA

; Player 1: Kempston on
;
; Witness: L1 1 (menu).
ChooseKempston:
  LD A,$01
  LD (KempstonOn),A
  RET

; Set Keyboard1Alt $8087 (the one-player method window's SINCLAIR line)
;
; Player 1's reader never tests Keyboard1Alt: no effect, KempstonOn stays set.
; Witness: turn (work/stage1/rec/turn, log.json: alt 1, the ATV still on the
; Kempston).
;
; Known only from the code.
ChooseKeys1:
  LD A,$01
  LD (Keyboard1Alt),A
  RET

; Player 2: Sinclair on
;
; Witness: L1 1 (menu).
ChooseSinclair:
  LD A,$01
  LD (SinclairOn),A
  RET

; HALT, copy the buffer (HL) to the screen (DE), $6E0 bytes
;
; Witness: L1 206 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
ShowBufferAt:
  HALT
  LD BC,$06E0
  JP JpCopyLines

; Measure each of MenuTexts and store its centring offset and width
;
; Witness: L1 2 (c1, itemlow).
InitTextWidths:
  LD HL,DrawModes
  LD (ModeVector),HL
  LD A,$4F
  LD (SpriteY),A
  LD IX,MenuTexts
l_75CF:
  LD A,(IX+$00)
  CP $FF
  RET Z
  XOR A
  LD (SpriteX),A
  PUSH IX
  INC IX
  INC IX
  CALL Print
  POP HL
  LD A,(SpriteX)
  LD E,A
  LD A,$FF
  SUB E
  SRL A
  LD (HL),A
  INC HL
  AND $07
  LD E,A
  LD A,(SpriteX)
  ADD A,E
  ADD A,$02
  CALL CellCount
  LD (HL),A
  INC IX
  JP l_75CF

; Print at H = x, L = y
;
; Witness: L1 193 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
PrintAt:
  LD A,H
  LD (SpriteX),A
  LD A,L
  LD (SpriteY),A

; Print the text at IX up to |, through the current draw mode
;
; " " moves 6 pixels, "]" moves to x $78, " ! . are glyphs $5B, $56, $6F;
; digits are big sprites $99-$A2 (the buffer's line above), a-j sprites
; $8D-$96, letters A-Z sprites $1E-$37. Each character's advance + 2.
;
; Witness: L1 68701 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
Print:
  LD A,(IX+$00)
  CP $7C
  RET Z
  CP $5D
  JR NZ,l_7619
  LD A,$78
  LD (SpriteX),A
  JR l_7679
l_7619:
  CP $20
  JR NZ,l_7627
  LD A,(SpriteX)
  ADD A,$06
  LD (SpriteX),A
  JR l_7679
l_7627:
  LD E,$5B
  CP $22
  JR Z,l_765F
  LD E,$56
  CP $21
  JR Z,l_765F
  LD E,$6F
  CP $2E
  JR Z,l_765F
  CP $3A
  JR NC,l_7650
  ADD A,$69
  LD (SpriteNum),A
  CALL JpBufferAddr
  LD DE,$0016
  XOR A
  SBC HL,DE
  LD (DestAddr),HL
  JR l_7669
l_7650:
  CP $61
  JR C,l_765C
  CP $6B
  JR NC,l_7660
  ADD A,$2C
  JR l_7660
l_765C:
  SUB $23
  LD E,A
l_765F:
  LD A,E
l_7660:
  LD (SpriteNum),A
  CALL JpBufferAddr
  LD (DestAddr),HL
l_7669:
  CALL JpGameSprite
  LD A,(SpriteAdvance)
  LD E,A
  LD A,(SpriteX)
  ADD A,E
  ADD A,$02
  LD (SpriteX),A
l_7679:
  INC IX
  JR Print

; Fill a box of attributes: A the byte, H/L the x/y, B columns, C rows
;
; Witness: L1 720 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
FillAttrs:
  LD (FillByte),A
  LD A,H
  LD (SpriteX),A
  LD A,L
  LD (SpriteY),A
  CALL AttrAddr
l_768B:
  PUSH BC
  PUSH HL
l_768D:
  LD A,(FillByte)
  LD (HL),A
  INC HL
  DJNZ l_768D
  POP HL
  POP BC
  LD DE,$0020
  ADD HL,DE
  DEC C
  JR NZ,l_768B
  RET

; HL = the attribute address of SpriteX / SpriteY (AttrBase)
;
; Witness: L1 4166 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
AttrAddr:
  LD A,(SpriteX)
  SRL A
  SRL A
  SRL A
  LD L,A
  LD H,$00
  LD A,(SpriteY)
  LD E,A
  LD A,$BF
  SUB E
  AND $F8
  LD E,A
  LD D,$00
  SLA E
  RL D
  SLA E
  RL D
  ADD HL,DE
  LD DE,(AttrBase)
  ADD HL,DE
  RET

; A = the bit of SpriteX within its byte
;
; Witness: L1 32140 (c1, dropout, empty, fuel, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
PixelMask:
  LD A,(SpriteX)
  AND $07
  ADD A,$01
  LD B,A
  XOR A
  SCF
l_76CF:
  RRA
  DJNZ l_76CF
  RET

; Draw mode 0: RET (measure only)
;
; Witness: L1 138555 (c1, dropout, empty, fuel, itemlow, kb, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
ModeNone:
  RET

; OR a sprite onto the screen (no mode word picks it)
;
; Known only from the code.
ModeOrScreen:
  LD DE,(DestAddr)
  LD HL,(SpriteData)
  LD A,(SpriteHeight)
  LD C,A
l_76DF:
  LD A,(SpriteWidth)
  LD B,A
  PUSH DE
l_76E4:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC HL
  INC DE
  DJNZ l_76E4
  POP DE
  CALL JpNextLineDE
  DEC C
  JR NZ,l_76DF
  RET

; Copy a sprite onto the screen
;
; Witness: L1 7508 (c1, dropout, empty, fuel, itemlow, kb, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
ModeCopyScreen:
  LD DE,(DestAddr)
  LD HL,(SpriteData)
  LD A,(SpriteHeight)
  LD C,A
l_76FE:
  LD A,(SpriteWidth)
  LD B,A
  PUSH DE
l_7703:
  LD A,(HL)
  LD (DE),A
  INC HL
  INC DE
  DJNZ l_7703
  POP DE
  CALL JpNextLineDE
  DEC C
  JR NZ,l_76FE
  RET

; XOR a sprite onto the screen
;
; Witness: L1 10396 (c1, dropout, empty, fuel, itemlow, kb, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
ModeXorScreen:
  LD DE,(DestAddr)
  LD HL,(SpriteData)
  LD A,(SpriteHeight)
  LD C,A
l_771C:
  LD A,(SpriteWidth)
  LD B,A
  PUSH DE
l_7721:
  LD A,(DE)
  XOR (HL)
  LD (DE),A
  INC HL
  INC DE
  DJNZ l_7721
  POP DE
  INC D
  LD A,D
  AND $07
  JR NZ,l_7739
  LD A,E
  ADD A,$20
  LD E,A
  JR C,l_7739
  LD A,D
  SUB $08
  LD D,A
l_7739:
  DEC C
  JR NZ,l_771C
  RET

; Read the attributes of a menu picture (MenuGfx): AttrSrc, AttrWidth,
; AttrHeight; call the attribute mode
;
; Witness: L1 3446 (c1, dropout, empty, fuel, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
MenuSpriteAttrs:
  CALL AttrAddr
  LD (AttrDest),HL
  LD HL,MenuGfx
  LD A,(SpriteNum)
  CP (HL)
  RET NC
  LD HL,MenuGfx
  LD E,A
  LD D,$00
  SLA E
  RL D
  SLA E
  RL D
  ADD HL,DE
  LD DE,$0006
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,MenuGfx
  ADD HL,DE
  LD A,(HL)
  LD (AttrWidth),A
  INC HL
  LD A,(HL)
  LD (AttrHeight),A
  INC HL
  LD (AttrSrc),HL
  LD HL,(AttrModeVector)
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  JP (HL)

; RET
;
; Witness: L1 3446 (c1, dropout, empty, fuel, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
ModeAttrsNone:
  RET

; Copy a picture's attributes (no mode word picks it)
;
; Known only from the code.
ModeAttrsCopy:
  LD HL,(AttrSrc)
  LD DE,(AttrDest)
  LD A,(AttrHeight)
  LD C,A
l_7786:
  PUSH BC
  PUSH DE
  LD BC,(AttrWidth)
  LD B,$00
  LDIR
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DEC C
  JR NZ,l_7786
  RET

; Clear the screen's pixels
;
; Witness: L1 37 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
ClearPixels:
  LD HL,Screen
  LD DE,Screen+1
  LD (HL),$00
  LD BC,$17FF
  LDIR
  RET

; Clear the screen's top half (96 lines)
;
; Witness: L1 50 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
ClearTopHalf:
  LD HL,Screen
  LD DE,Screen+1
  JP l_77BC

; Clear the lower half
;
; Witness: L1 28 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
ClearBottomHalf:
  LD HL,$005F
  CALL ScreenAddrHL
  PUSH HL
  POP DE
  INC DE
; This entry point is used by the routine at ClearTopHalf.
l_77BC:
  LD B,$60
l_77BE:
  PUSH BC
  PUSH HL
  PUSH HL
  POP DE
  INC DE
  LD (HL),$00
  LD BC,$0018
  LDIR
  POP HL
  CALL JpNextLineHL
  POP BC
  DJNZ l_77BE
  RET

; Fill all 24 attribute rows with A
;
; Witness: L1 50 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
FillAllAttrs:
  LD HL,$00B8
  LD BC,$1818
  JP FillAttrs

; Fill the 768 attributes at AttrBase with A
;
; Witness: L1 39 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
FillAttrsBase:
  LD HL,(AttrBase)
  LD DE,(AttrBase)
  INC DE
  LD BC,$02FF
  LD (HL),A
  LDIR
  RET

; KempstonOn = 1 unless one of 255 reads of port 31 gives all five bits set (no
; interface: the bus floats to $FF)
;
; Witness: L1 2 (c1, itemlow).
DetectKempston:
  LD E,$00
  LD A,$01
  LD (KempstonOn),A
l_77F1:
  DEC E
  RET Z
  LD BC,$001F
  IN A,(C)
  AND $1F
  CP $1F
  JR NZ,l_77F1
  XOR A
  LD (KempstonOn),A
  RET

; Fill RowAddrs with the 192 lines' screen addresses
;
; Witness: L1 2 (c1, itemlow).
BuildRowAddrs:
  LD HL,$0000
  LD DE,RowAddrs
  LD B,$C0
l_780B:
  LD A,L
  LD (DE),A
  INC DE
  LD A,H
  LD (DE),A
  INC DE
  CALL JpNextLineHL
  DJNZ l_780B
  RET

; Copy a sprite into the buffer (22 bytes a line)
;
; Witness: L1 25187 (c1, dropout, empty, kb, trail1, trails, wallcrash, warp).
ModeCopyBuffer:
  LD HL,(SpriteData)
  LD DE,(DestAddr)
  LD A,(SpriteHeight)
  LD B,A
l_7822:
  PUSH BC
  LD BC,(SpriteWidth)
  LD B,$00
  PUSH DE
  LDIR
  POP DE
  EX DE,HL
  LD BC,$0016
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ l_7822
  RET

; XOR a sprite into the buffer
;
; Witness: L1 10009 (c1, dropout, empty, fuel, kb, menu, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
ModeXorBuffer:
  LD DE,(SpriteData)
  LD HL,(DestAddr)
  LD A,(SpriteHeight)
  LD C,A
l_7842:
  LD A,(SpriteWidth)
  LD B,A
  PUSH HL
l_7847:
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC DE
  INC HL
  DJNZ l_7847
  POP HL
  PUSH DE
  LD DE,$0016
  ADD HL,DE
  POP DE
  DEC C
  JR NZ,l_7842
  RET

; Fill BufferRows: 80 offsets of 22
;
; Witness: L1 2 (c1, itemlow).
BuildBufferRows:
  LD IX,BufferRows
  LD HL,$0000
  LD DE,$0016
  LD B,$50
l_7865:
  ADD HL,DE
  LD (IX+$00),L
  LD (IX+$01),H
  INC IX
  INC IX
  DJNZ l_7865
  RET

; Fill both trail lists' item heights and advances from the sprites
;
; For each item of TrailListA and TrailListB: the sprite header (through the
; item's animation record when flags bits 3-7 are set); +2 (y) becomes the
; height when 0, +3 the advance. Before each trail (c1: 15 runs).
;
; Witness: L1 25 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
InitListWidths:
  LD HL,(TrailListA)
  CALL InitList
  LD HL,(TrailListB)

; One list (HL)
;
; Witness: L1 50 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
InitList:
  PUSH HL
  POP IY
  LD HL,DrawModes
  LD (ModeVector),HL
l_7885:
  LD HL,JpGameSprite
  LD (SpriteCall),HL
  LD A,(IY+$04)
  LD (SpriteNum),A
  LD A,(IY+$05)
  AND $F8
  JR Z,l_78B3
  LD L,(IY+$04)
  LD H,(IY+$05)
  LD A,(HL)
  LD (SpriteNum),A
  INC HL
  LD A,(HL)
  LD (ItemFlags),A
  BIT 0,A
  JR Z,l_78C0
  LD HL,JpMenuSprite
  LD (SpriteCall),HL
  JR l_78C0
l_78B3:
  LD A,(IY+$05)
  BIT 0,A
  JR Z,l_78C0
  LD HL,JpMenuSprite
  LD (SpriteCall),HL
l_78C0:
  CALL JpSpriteGo
  LD A,(IY+$02)
  CP $00
  JR NZ,l_78D0
  LD A,(SpriteHeight)
  LD (IY+$02),A
l_78D0:
  LD A,(SpriteAdvance)
  LD (IY+$03),A
  LD DE,$0006
  ADD IY,DE
  LD A,(IY+$01)
  CP $FF
  JR NZ,l_7885
  RET

; Draw mode 8: a sprite scaled by BigScaleX / BigScaleY, ORed or cleared
;
; Witness: L1 972 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
BigPrint:
  LD A,(SpriteX)
  PUSH AF
  XOR A
  LD (SpriteX),A
  CALL JpBufferAddr
  LD (DestAddr),HL
  POP AF
  LD (SpriteX),A
  AND $F8
  SRL A
  SRL A
  SRL A
  LD E,A
  LD A,(BigScaleX)
  CALL JpMultiply
  LD DE,(DestAddr)
  ADD HL,DE
  EX DE,HL
  LD HL,(SpriteData)
  LD A,(SpriteHeight)
  LD B,A
l_7911:
  PUSH BC
  PUSH DE
  LD A,(BigScaleX)
  LD B,A
  XOR A
l_7918:
  SCF
  RRA
  DJNZ l_7918
  LD (BigMask),A
  LD A,(SpriteWidth)
  LD B,A
l_7923:
  PUSH BC
  LD C,$80
  CALL BigByte
  INC HL
  POP BC
  DJNZ l_7923
  POP DE
  PUSH HL
  EX DE,HL
  LD A,(BigScaleY)
  LD B,A
l_7934:
  LD DE,$0016
  ADD HL,DE
  DJNZ l_7934
  EX DE,HL
  POP HL
  POP BC
  DJNZ l_7911
  LD A,(SpriteAdvance)
  LD (SpriteAdvance),A
  RET

; One sprite byte, scaled
;
; Witness: L1 12904 (c1, dropout, empty, fuel, itemlow, kb, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
BigByte:
  LD B,$08
l_7948:
  PUSH BC
  LD A,(HL)
  AND C
  JR Z,l_795C
  EX DE,HL
  PUSH HL
  PUSH DE
  LD A,(BigRepeat)
  LD B,A
l_7954:
  CALL BigPlot
  DJNZ l_7954
  POP DE
  POP HL
  EX DE,HL
l_795C:
  LD A,(BigScaleX)
  LD B,A
  LD A,(BigMask)
l_7963:
  RRCA
  DJNZ l_7963
  LD (BigMask),A
  JR NC,l_796C
  INC DE
l_796C:
  POP BC
  SRL C
  DJNZ l_7948
  RET

; One scaled pixel: OR the mask in or clear it
;
; Witness: L1 88985 (c1, dropout, empty, fuel, itemlow, kb, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
BigPlot:
  LD A,(BigClear)
  CP $01
  JR Z,l_7983
  LD A,(BigMask)
  OR (HL)
l_797D:
  LD (HL),A
  LD DE,$0016
  ADD HL,DE
  RET
l_7983:
  LD A,(BigMask)
  XOR $FF
  AND (HL)
  JP l_797D

; Copy the trail's 11-character name over the dots after "TRAIL NO."
; (TrailNameSlot)
;
; Witness: L1 25 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
CopyTrailName:
  LD DE,(Trail)
  SLA E
  LD D,$00
  LD IX,TrailNamePtrs
  ADD IX,DE
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD DE,TrailNameSlot
  LD BC,$000B
  LDIR
  RET

; Colour a half's playfield with the trail's attribute (TrailInks): 22 x 5
; cells at IX; trails 3 and 6 (Icebergs, Swamp) add a blue row (9) at IY
;
; Witness: L1 53 (c1, dropout, empty, fuel, itemlow, kb, overhang, speedcrash,
; throwoff, trail1, trails, turn, wallcrash, warp).
TrailAttrs:
  LD DE,(Trail)
  LD D,$00
  LD HL,TrailInks
  ADD HL,DE
  LD A,(HL)
  PUSH IX
  POP HL
  LD BC,$1605
  CALL FillAttrs
  LD A,(Trail)
  CP $02
  JR Z,l_79C9
  CP $05
  JR Z,l_79C9
  RET
l_79C9:
  PUSH IY
  POP HL
  LD BC,$1601
  LD A,$09
  JP FillAttrs

; The playfield's attribute of each trail: $30, $20, $78, $30, $20, $30
TrailInks:
  INCBIN "res/tables/trailinks.bin",$0000,6

; The six trail names' addresses
TrailNamePtrs:
  DEFW $79FC
  DEFW $7A07
  DEFW $7A12
  DEFW $7A1D
  DEFW $7A28
  DEFW $7A33

; "TRAIL NO.|", the slot "...........|" (TrailNameSlot) and the six names (11
; characters, no |)
TrailTexts:
  INCBIN "res/texts/trails.bin",$0000,10
TrailNameSlot:
  INCBIN "res/texts/trails.bin",$000A,78

  ORG $83F9

; Carry: player 1 reads the Kempston; else NZ: the Sinclair keys (two players
; and Keyboard1Alt)
;
; Witness: L1 149220 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P1UsesJoystick:
  LD A,(KempstonOn)
  SUB $01
  CCF
  RET C
  LD A,(PlayerCount)
  CP $00
  RET Z
  LD A,(Keyboard1Alt)
  CP $00
  RET

; Carry when player 1's left is held (the key KeyIndexes1+0, Kempston bit 1)
;
; Witness: L1 29844 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P1Left:
  CALL P1UsesJoystick
  JP C,l_8424
  JP NZ,SinclairLeft
  LD A,(KeyIndexes1)
  LD E,A
  LD D,$00
  LD HL,KeyStates
  ADD HL,DE
  LD A,(HL)
  CP $01
  CCF
  RET
l_8424:
  LD A,(JoyBits)
  AND $02
  CP $02
  CCF
  RET

; Player 1's right (KeyIndexes1+1, Kempston bit 0)
;
; Witness: L1 29844 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P1Right:
  CALL P1UsesJoystick
  JP C,l_8445
  JP NZ,SinclairRight
  LD A,(KeyIndexes1+$0001)
  LD E,A
  LD D,$00
  LD HL,KeyStates
  ADD HL,DE
  LD A,(HL)
  CP $01
  CCF
  RET
l_8445:
  LD A,(JoyBits)
  AND $01
  CP $01
  CCF
  RET

; Player 1's wheel up (KeyIndexes1+2, Kempston bit 3)
;
; Witness: L1 29844 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P1Up:
  CALL P1UsesJoystick
  JP C,l_8466
  JP NZ,SinclairUp
  LD A,(KeyIndexes1+$0002)
  LD E,A
  LD D,$00
  LD HL,KeyStates
  ADD HL,DE
  LD A,(HL)
  CP $01
  CCF
  RET
l_8466:
  LD A,(JoyBits)
  AND $08
  CP $08
  CCF
  RET

; Player 1's wheel down (KeyIndexes1+3, Kempston bit 2)
;
; Witness: L1 29844 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P1Down:
  CALL P1UsesJoystick
  JP C,l_8487
  JP NZ,SinclairDown
  LD A,(KeyIndexes1+$0003)
  LD E,A
  LD D,$00
  LD HL,KeyStates
  ADD HL,DE
  LD A,(HL)
  CP $01
  CCF
  RET
l_8487:
  LD A,(JoyBits)
  AND $04
  CP $04
  CCF
  RET

; Player 1's jump (KeyIndexes1+4, Kempston fire, bit 4)
;
; Witness: L1 29844 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P1Jump:
  CALL P1UsesJoystick
  JP C,l_84A8
  JP NZ,SinclairFire
  LD A,(KeyIndexes1+$0004)
  LD E,A
  LD D,$00
  LD HL,KeyStates
  ADD HL,DE
  LD A,(HL)
  CP $01
  CCF
  RET
l_84A8:
  LD A,(JoyBits)
  AND $10
  CP $01
  CCF
  RET

; Player 2's left: KeyIndexes2+0, or key 6 with the Sinclair joystick
;
; Witness: L1 29844 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P2Left:
  LD A,(SinclairOn)
  CP $00
  JP NZ,SinclairLeft
  LD A,(KeyIndexes2)
  LD E,A
  LD D,$00
  LD HL,KeyStates
  ADD HL,DE
  LD A,(HL)
  CP $01
  CCF
  RET
; This entry point is used by the routine at P1Left.
SinclairLeft:
  LD A,(KeyStates+$0018)  ; key 6
  CP $01
  CCF
  RET

; Player 2's right: KeyIndexes2+1 or key 7
;
; Witness: L1 29844 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P2Right:
  LD A,(SinclairOn)
  CP $00
  JP NZ,SinclairRight
  LD A,(KeyIndexes2+$0001)
  LD E,A
  LD D,$00
  LD HL,KeyStates
  ADD HL,DE
  LD A,(HL)
  CP $01
  CCF
  RET
; This entry point is used by the routine at P1Right.
SinclairRight:
  LD A,(KeyStates+$0017)  ; key 7
  CP $01
  CCF
  RET

; Player 2's wheel up: KeyIndexes2+2 or key 9
;
; Witness: L1 29844 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P2Up:
  LD A,(SinclairOn)
  CP $00
  JP NZ,SinclairUp
  LD A,(KeyIndexes2+$0002)
  LD E,A
  LD D,$00
  LD HL,KeyStates
  ADD HL,DE
  LD A,(HL)
  CP $01
  CCF
  RET
; This entry point is used by the routine at P1Up.
SinclairUp:
  LD A,(KeyStates+$0015)  ; key 9
  CP $01
  CCF
  RET

; Player 2's wheel down: KeyIndexes2+3 or key 8
;
; Witness: L1 29844 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P2Down:
  LD A,(SinclairOn)
  CP $00
  JP NZ,SinclairDown
  LD A,(KeyIndexes2+$0003)
  LD E,A
  LD D,$00
  LD HL,KeyStates
  ADD HL,DE
  LD A,(HL)
  CP $01
  CCF
  RET
; This entry point is used by the routine at P1Down.
SinclairDown:
  LD A,(KeyStates+$0016)  ; key 8
  CP $01
  CCF
  RET

; Player 2's jump: KeyIndexes2+4 or key 0
;
; Witness: L1 29844 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
P2Jump:
  LD A,(SinclairOn)
  CP $00
  JP NZ,SinclairFire
  LD A,(KeyIndexes2+$0004)
  LD E,A
  LD D,$00
  LD HL,KeyStates
  ADD HL,DE
  LD A,(HL)
  CP $01
  CCF
  RET
; This entry point is used by the routine at P1Jump.
SinclairFire:
  LD A,(KeyStates+$0014)  ; key 0
  CP $01
  CCF
  RET

  ORG $858A

; Zero KeyStates and JoyBits
;
; Witness: L1 420475 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
ClearKeys:
  LD BC,$0027
  LD HL,KeyStates
  LD DE,KeyStates+$0001
  LD (HL),$00
  LDIR
  XOR A
  LD (JoyBits),A
  RET

; Read the eight half-rows into KeyStates (1 a key held) and OR the Kempston's
; bits into JoyBits
;
; Ports $FEFE to $7FFE, five bits each; then IN 31. Called each frame by the
; interrupt in the front end and each pass in play. L is loaded but not used.
; The latch keeps a key for 3 scans: only the last 3 interrupts of a 7-frame
; pass count.
;
; Witness: L1 153629 (c1, dropout, empty, fuel, itemlow, kb, menu, overhang,
; speedcrash, throwoff, trail1, trails, turn, wallcrash, warp).
ScanKeys:
  LD L,$2F
  LD BC,$FEFE
  LD DE,KeyStates
l_85A4:
  IN A,(C)
  CPL
  AND $1F
  LD H,$05
l_85AB:
  SRL A
  JP NC,l_85B5
  PUSH AF
  LD A,$01
  LD (DE),A
  POP AF
l_85B5:
  INC DE
  DEC H
  JP NZ,l_85AB
  DEC L
  RLC B
  JP C,l_85A4
  LD A,(JoyBits)
  LD E,A
  LD BC,$001F
  IN A,(C)
  AND $1F
  OR E
  LD (JoyBits),A
  RET
