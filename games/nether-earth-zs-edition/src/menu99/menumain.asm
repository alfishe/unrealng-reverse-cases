; --------------------------------------------------------------------------------------------------------------------
; menumain.asm: The menu screen, the pointer loop, the choices, START and its level patches
;
; MenuEntry runs once per MainMenu call: at the first one from the game's Start, after LOAD MAP (which JPs to Start),
; and after a game ends (aborted or over), each time from a fresh copy of page 1, so the level and the pointer start
; again at EASY and (8,8) (m99 frame 5961, after LOAD MAP). Controls, EnemyUpgrade and EnemyPartsMask live in the game
; and keep their values.
;
; The screen (MenuText, MenuBottomText through the game's PrintInline): the title, LEVEL: EASY MEDIUM HARD CRITICAL
; (rows 10-13, column 1, attribute 5), UPGRADING: the six robot parts (rows 10-15, column 11, attribute 6), CONTROL:
; KEYBOARD KEMPSTON INTERFACE REDEFINE (rows 10-13, column 23, attribute 5), and START, LOAD MAP, DESCRIPTION (row
; 17), ADVICES, GREETS, ABOUT ZS NE (row 21), attribute 2, double height. MenuRedraw marks the chosen level, the parts
; on and the control with PaintBar (attribute $47, 10 cells). The pointer (an arrow sprite) moves one pixel a pass
; with Q A O P (ReadMenuKeys: the keyboard only; no block of either release reads a $xxDF mouse port, and the only IN
; from $1F, the Kempston joystick, is the game's at $D3AC); SPACE picks the 8 x 8 cell under the pointer's corner.
;
; The choice by the cell's row and column (MenuSelect): rows 10-16 need attribute 5, 6 or $47 (an item); column 0-10
; the level (row - 9), 11-22 an upgrade toggle, 23-31 the control (rows 10-12) or REDEFINE (row 13). Rows 17 and more
; need attribute 2: row 17 columns 0-7 START, 8-17 LOAD MAP, 18-31 DESCRIPTION; row 21 columns 0-9 ADVICES, 10-17
; GREETS, 18-31 ABOUT.
;
; START (StartGame) writes three places of the game by the level and returns to Start's caller ($A603): EASY the
; game's own bytes (as Nether Earth); MEDIUM the enemy's resources 99 each time it builds (SpawnResources = CALL
; $A5F2) and "??" in place of its robot count (InsgRobotCount); HARD also EnemyProduce = CALL $A5D6 (the enemy's
; production replaced by EnemyUpgrade over its robots, game99's part); CRITICAL also EnemyUpgrade = $FC (every part)
; and EnemyPartsMask = 0. Witnessed in m99: CRITICAL frame 6500 SpawnResources CD F2 A5, InsgRobotCount 00 CD 2D D4 3F
; 3F, EnemyProduce 6 x 00 CD D6 A5, $A5E5-$A5E7 = 00 F6 FC; MEDIUM frame 7500 the first two patched and EnemyProduce
; the game's own; EASY frame 8000 all three the game's own.
; --------------------------------------------------------------------------------------------------------------------

; IM 0 with I = $3F, the stack at $677E, then the menu screen
;
; Entered from the stub at $6700 (page 0, m99 frame 2660). The return address
; (into Start, $A603) is moved onto the new stack at $677E (under stage 3's
; strings, which the stub overwrote). MenuHook = MenuRedraw: a dead store (no
; window reads $C1E1).
MenuEntry:
  DI
  LD A,$3F
  LD I,A
  IM 0
  POP HL                  ; the return address onto the new stack
  LD SP,$677E
  PUSH HL
  EI
  LD HL,MenuRedraw        ; MenuHook: never read
  LD (MenuHook),HL

; Clear the screen, attributes 7, print the menu (MenuText)
;
; Also the return after REDEFINE and after a text was shown (TextShow).
MenuScreen:
  CALL ClearScreen
  LD HL,$5800
  LD DE,$5801
  LD BC,$02FF
  LD (HL),$07
  LDIR
  CALL PrintInline

; the menu's upper part through PrintInline (src/res/menu99/menu-strings.txt
; [menu])
MenuText:
  INCBIN "res/menu99/menu-text.bin",$0000,236

; Save the attributes of rows 10-15, print START .. ABOUT ZS NE
; (MenuBottomText)
;
; SavedAttrs: the colours of the items without the marks; MenuRedraw restores
; them before it marks again.
MenuBottom:
  LD HL,$5940
  LD DE,SavedAttrs
  LD BC,$00C0
  LDIR
  CALL PrintInline

; the six items of rows 17 and 21 (menu-strings.txt [bottom])
MenuBottomText:
  INCBIN "res/menu99/menu-bottom.bin",$0000,71

; Restore rows 10-15, mark the control, the level and the parts on; then the
; pointer loop
;
; After a HALT, SavedAttrs back to $5940; PaintBar at column 23 for Controls,
; column 0 for the level (the operand of LD A at LevelLd), column 11 for each
; bit 7..2 of EnemyUpgrade (rows 10-15). PaintBar paints 10 cells, so the
; CONTROL bar from column 23 runs into columns 0-0 of the next row (2 cells,
; black on the empty left of the row).
MenuRedraw:
  HALT
  LD DE,$5940
  LD HL,SavedAttrs
  LD BC,$00C0
  LDIR
  LD HL,$5817             ; the control
  LD A,(Controls)
  CALL PaintBar
  LD HL,$5800             ; the level
LevelLd:
  LD A,$01                ; the level 1-4: this operand is the menu's level
                          ; variable (MenuSelect writes it, StartGame reads it)
  CALL PaintBar
  LD A,(EnemyUpgrade)            ; the parts: bit 7 electronics (row 10) .. bit 2
                          ; anti-gravs (row 15)
  LD C,A
  LD B,$06
  LD A,$01
MarkPartsLoop:
  RL C
  JR NC,MarkPartsNext
  PUSH AF
  PUSH BC
  LD HL,$580B
  CALL PaintBar
  POP BC
  POP AF
MarkPartsNext:
  INC A
  DJNZ MarkPartsLoop
PointerShow:
  CALL SavePointerBg      ; save the background under the pointer, draw it
  CALL DrawPointer
MenuLoop:
  CALL TitleColourCycle              ; the title colours, a delay, the keys
  LD C,$03
DelayOuter:
  LD B,$00
DelayInner:
  DJNZ DelayInner
  DEC C
  JR NZ,DelayOuter
  CALL ReadMenuKeys
  LD D,$00                ; D counts the moves of this pass
  LD BC,(DrawPointer+$0001)
  BIT 2,E                 ; Q: up (y 0 at least)
  JR NZ,KeyDown
  LD A,B
  OR A
  JR Z,KeyDown
  DEC B
  INC D
KeyDown:
  BIT 3,E                 ; A: down (y $B8 at most)
  JR NZ,KeyLeft
  LD A,B
  CP $B8
  JR NC,KeyLeft
  INC B
  INC D
KeyLeft:
  BIT 1,E                 ; O: left
  JR NZ,KeyRight
  LD A,C
  OR A
  JR Z,KeyRight
  DEC C
  INC D
KeyRight:
  BIT 0,E                 ; P: right (x $F8 at most)
  JR NZ,KeySpace
  LD A,C
  CP $F8
  JR Z,KeySpace
  INC C
  INC D
KeySpace:
  BIT 4,E                 ; SPACE: choose; no move: the next pass
  JR Z,MenuSelect
  LD A,D
  OR A
  JR Z,MenuLoop
  PUSH BC                 ; moved: the old background back, the new position,
                          ; draw again
  CALL RestorePointerBg
  POP BC
  LD (DrawPointer+$0001),BC
  JR PointerShow
MenuSelect:
  CALL RestorePointerBg   ; SPACE: the cell under the pointer's corner, by row
                          ; and column
  LD BC,(DrawPointer+$0001)
  RR B
  RR B
  RR B
  LD A,$1F
  AND B
  LD B,A
  CP $0A                  ; rows 0-9: nothing
  JR C,PointerShow
  RR C
  RR C
  RR C
  LD A,$1F
  AND C
  LD C,A
  LD H,$58
  LD L,C
  LD DE,$0020
  LD A,B
CellRowLoop:
  ADD HL,DE
  DJNZ CellRowLoop
  LD B,A
  CP $11                  ; rows 17 on: the bottom items
  JR NC,BottomItem
  LD A,(HL)               ; an item colour: 5 (level, control), 6 (part), $47
                          ; (marked)
  CP $05
  JR Z,SelectLevel
  CP $06
  JR Z,SelectLevel
  CP $47
  JR Z,SelectLevel
  JP PointerShow
SelectLevel:
  LD A,C                  ; columns 0-10: the level = row - 9
  CP $0B
  JR NC,ToggleUpgrade
  LD A,B
  SUB $09
  LD (LevelLd+$0001),A
  JP MenuRedraw
ToggleUpgrade:
  CP $17                  ; columns 11-22: the part of the row, XOR into
                          ; EnemyUpgrade
  JR NC,SelectControl
  LD A,B
  SUB $08
  XOR A                   ; A = $80 >> (row - 10): B = row - 8 RRAs of the
                          ; carry
  CCF
PartMaskLoop:
  RRA
  DJNZ PartMaskLoop
  LD HL,EnemyUpgrade
  XOR (HL)
  LD (HL),A
  AND $07                 ; any of bits 2-0 set: the mask $F8, else $FF
  LD A,$FF
  JR Z,SetPartsMask
  LD A,$F8
SetPartsMask:
  LD (EnemyPartsMask),A
WaitSpaceUp:
  CALL ReadMenuKeys       ; wait until SPACE is released
  HALT
  AND $10
  JR Z,WaitSpaceUp
  JP MenuRedraw
SelectControl:
  LD A,B                  ; columns 23-31: rows 10-12 Controls = row - 9, row
                          ; 13 REDEFINE
  CP $0D
  JR Z,RedefineItem
  JR NC,SelectControlDone
  SUB $09
  LD (Controls),A
SelectControlDone:
  JP MenuRedraw
RedefineItem:
  CALL RedefineKeys              ; REDEFINE: the game's screen, then the menu again
  JP MenuScreen
BottomItem:
  LD A,(HL)               ; rows 17 on: attribute 2 needed; row 21 on: the
                          ; second line
  CP $02
  JP NZ,MenuRedraw
  LD A,B
  CP $15
  LD A,C
  JP NC,BottomRow21
  CP $08
  JR NC,BottomColumn
StartGame:
  LD HL,LevelPatches      ; row 17, columns 0-7: the level's patches; RET to
                          ; Start ($A603)
  LD DE,SpawnResources
  LD BC,$0003
  LDIR
  LD DE,InsgRobotCount
  LD BC,$0006
  LDIR
  LD DE,EnemyProduce
  LD BC,$0009
  LDIR
  LD A,(LevelLd+$0001)    ; EASY ends here (A = 0)
  CP $01
  LD A,$00
  RET Z
  LD HL,PatchSpawn99      ; MEDIUM and up: the enemy's resources 99, its robot
                          ; count hidden
  LD DE,SpawnResources
  LD BC,$0003
  LDIR
  LD DE,InsgRobotCount
  LD BC,$0006
  LDIR
  LD A,(LevelLd+$0001)
  CP $02
  LD A,$00
  RET Z
  LD DE,EnemyProduce             ; HARD and up: the enemy's production upgraded
  LD BC,$0009
  LDIR
  LD A,(LevelLd+$0001)
  CP $03
  LD A,$00
  RET Z
  LD A,$FC                ; CRITICAL: every part, mask 0
  LD (EnemyUpgrade),A
  XOR A
  LD (EnemyPartsMask),A
  RET

; the bytes StartGame copies: EASY (the game's own), then MEDIUM and HARD
;
; Six pieces copied in order: 3 bytes to SpawnResources, 6 to InsgRobotCount, 9
; to EnemyProduce (EASY), then 3 and 6 (MEDIUM up) and 9 (HARD up).
LevelPatches:
PatchEasySpawn:
  DEFB $21,$4A,$FD        ; LD HL,$FD4A
PatchEasyInsg:
  DEFB $CD,$EC,$D3        ; CALL $D3EC (PrintNumber2Zero), CALL PrintInline
  DEFB $CD,$2D,$D4
PatchEasyProduce:
  DEFB $21,$4A,$FD        ; LD HL,$FD4A, LD DE,$FD42, CALL $AE4E (ProduceSide)
  DEFB $11,$42,$FD
  DEFB $CD,$4E,$AE
PatchSpawn99:
  DEFB $CD,$F2,$A5        ; CALL $A5F2: the enemy's resources 99 (game99's
                          ; part)
PatchInsgHidden:
  DEFB $00,$CD,$2D        ; NOP, CALL PrintInline, "??" over the first two
  DEFB $D4,$3F,$3F        ; bytes of the game's inline text
PatchProduceUpgrade:
  DEFB $00,$00,$00        ; six NOPs, CALL $A5D6: EnemyUpgrade over the enemy
  DEFB $00,$00,$00        ; robots (game99's part)
  DEFB $CD,$D6,$A5

; Row 17 past START: LOAD MAP (columns 8-17) or DESCRIPTION; row 21: ADVICES,
; GREETS, ABOUT
;
; LOAD MAP: JP LoadMap (the patches block's catalogue, m99 frames 5600-5960).
BottomColumn:
  CP $12
  JP C,LoadMap
  JP ShowDescription
; This entry point is used by the routine at MenuRedraw.
BottomRow21:
  CP $0A                  ; row 21: columns 0-9 ADVICES, 10-17 GREETS, 18-31
                          ; ABOUT
  JP C,ShowAdvices
  CP $12
  JP C,ShowGreets
  JP ShowAbout
ShowDescription:
  LD HL,TextBuffer             ; the description into TextBuffer, the screen, its
                          ; title
  CALL LoadDescription
  CALL ClearScreen
  CALL PrintInline

; "NETHER EARTH" / "DESCRIPTION" (menu-strings.txt [description])
DescTitle:
  INCBIN "res/menu99/title-description.bin",$0000,34

; to TextShow
DescView:
  JR TextShow

; The about text into TextBuffer (LoadAbout), the screen, its title, TextShow
;
; Used by the routine at BottomColumn.
ShowAbout:
  LD HL,TextBuffer
  CALL LoadAbout
  CALL ClearScreen
  CALL PrintInline

; "NETHER EARTH" / "ZS EDITION'99" (menu-strings.txt [about])
AboutTitle:
  INCBIN "res/menu99/title-about.bin",$0000,36

; The viewer from the start of TextBuffer, then the menu again
;
; Used by the routines at DescView, AdvicesView and GreetsView.
TextShow:
  LD HL,TextBuffer
  LD (ViewerTopLd+$0001),HL ; the viewer's top line: the start
  CALL TextViewer
  JP MenuScreen

; The advices text into TextBuffer (LoadAdvices), the screen, its title,
; TextShow
;
; Used by the routine at BottomColumn.
ShowAdvices:
  LD HL,TextBuffer
  CALL LoadAdvices
  CALL ClearScreen
  CALL PrintInline

; "NETHER EARTH" / "ADVICES" (menu-strings.txt [advices])
AdvicesTitle:
  INCBIN "res/menu99/title-advices.bin",$0000,30

; to TextShow
AdvicesView:
  JR TextShow

; The greets text into TextBuffer (LoadGreets), the screen, its title, TextShow
;
; Used by the routine at BottomColumn.
ShowGreets:
  LD HL,TextBuffer
  CALL LoadGreets
  CALL ClearScreen
  CALL PrintInline

; "NETHER EARTH" / "GREETS" (menu-strings.txt [greets])
GreetsTitle:
  INCBIN "res/menu99/title-greets.bin",$0000,29

; to TextShow
GreetsView:
  JR TextShow
