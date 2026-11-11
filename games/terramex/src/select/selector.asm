; --------------------------------------------------------------------------------------------------------------------
; selector.asm: The explorer selector: the picture, the hand cursor, the choice and the copy of the chosen set
;
; SelectorEntry $C0D2 copies PagedReadStub $C4A6 to PagingStub $5FE6. On a 128K the first entry (GameLoaded $5FFF = 0,
; still inside the loader) only patches the stub to OUT (C),A; RET and runs it with A = $10: RAM 0 is paged at $C000
; and the RET returns to the loader, which loads the game. Every later entry (the game's menu, $8F5E) and the 48K
; entry run the selector: the picture SelectorPicture $CF0F, a 24 x 16 hand cursor moved 2 pixels a frame by the
; keyboard (Z X O K, SPACE), a Kempston joystick (port $1F) or Sinclair (6 7 8 9 0), all three polled every pass
; (ReadAnyDevice $C3BF). MoveCursor $C1D5 sets Explorer $5B70 from the cursor's place: 0 Fortisque-Smithe, 1 Herr
; Krusche, 2 Henri Beaucoup, 3 Big John Caine, 4 Wu Pong, $FE the Help box, $FF elsewhere. FIRE on an explorer copies
; that explorer's data set to ExplorerSet $6000 (CopyExplorerSet $C134) and returns; FIRE on Help shows the
; instructions (ShowHelp $C536).
;
; A 48K never pages: the setup relocated the block to $7200 and the loader's CALL $7200 runs it there before the game
; loads. After STOP THE TAPE / THEN PRESS SPACE KEY (ShowStopTape $C295) the selector runs; the choice copies the set
; from the tape's copy at $9CF8 to $6000, prints EXPLORER SELECTED / START TAPE and returns to the loader, which loads
; the game over the block and the sets. The game's menu does not call the selector on a 48K (Has128K = 0 at $8F4A), so
; the choice is final (the 48K Help text says so). Known only from the code.
; --------------------------------------------------------------------------------------------------------------------

  ORG $C0D2

; Copy the paging stub to $5FE6; on a 128K's first entry page RAM 0 and return
; to the loader
;
; Copies the 21 bytes of PagedReadStub $C4A6 to PagingStub $5FE6 on every
; entry. Has128K $5FFE nonzero and GameLoaded $5FFF zero: the first entry, from
; the loader through Setup and RelocateSelector. Then $5FE6-$5FE7 = $ED,$79
; (OUT (C),A) and $5FE8 = $C9 (RET), BC = $7FFD, A = $10 and JP $5FE6: RAM 0 at
; $C000, ROM 1, and the RET returns to the loader's CALL $7200 (to $5D64),
; whose stack still holds that address. Otherwise SelectorRun $C0FC.
;
; c1: the first entry at frame 11841 takes the patch ($C0E9-$C0F9 once; $5FE6
; then runs OUT and RET once); the second (frame 22215, from the game) runs the
; selector. explorers: six entries, all to the selector.
;
; Witness: L1 8 (c1, explorers).
SelectorEntry:
  LD HL,PagedReadStub
  LD DE,PagingStub
  LD BC,$0015
  LDIR
  LD A,(Has128K)
  OR A
  JR Z,SelectorRun
  LD A,(GameLoaded)
  OR A
  JR NZ,SelectorRun
  LD BC,$7FFD             ; a 128K inside the loader: make the stub OUT (C),A;
                          ; RET
  LD HL,$79ED             ; $ED,$79: OUT (C),A
  LD (PagingStub),HL
  LD A,$C9                ; RET after it
  LD (PagingStub+2),A
  LD A,$10                ; RAM 0, ROM 1: the RET goes back to the loader at
                          ; $5D64
  JP PagingStub
SelectorRun:
  CALL ClearScreen        ; clear the screen; on a 48K ask to stop the tape
                          ; first
  LD A,(Has128K)
  OR A
  CALL Z,ShowStopTape
; This entry point is used by the routine at ShowHelp.
SelectorRestart:
  CALL ClearScreen        ; Help returns here: clear, draw the picture, the
                          ; cursor at x 100, y 80
  CALL DrawSelectorPicture
  LD HL,80*256+100
  LD (CursorXY),HL
SelectorLoop:
  CALL DrawCursor         ; draw the cursor, read the devices, move, classify
  CALL MoveCursor
  BIT 4,E                 ; FIRE (bit 4)?
  JR Z,SelectorWait
  LD A,(Explorer)            ; on nothing: go on
  CP $FF
  JR Z,SelectorWait
  CP $FE                  ; on the Help box
  JP Z,ShowHelp
  JR CopyExplorerSet      ; on an explorer
SelectorWait:
  LD IY,$0000             ; IY = 0 for the ROM's IM 1 handler of the 48K path,
                          ; wait a frame, restore under the cursor
  HALT
  CALL RestoreUnderCursor
  JR SelectorLoop

; Copy the chosen explorer's data set ($1200 bytes) to ExplorerSet $6000
;
; Reached from SelectorLoop $C112 with FIRE on an explorer (Explorer $5B70 =
; 0-4). 128K: the set's bank and address: 0 RAM 4 $C000, 1 RAM 4 $D200, 2 RAM 4
; $E400, 3 RAM 3 $C000, 4 RAM 3 $D200 (where Setup $C005 put them); each byte
; is read through PagingStub $5FE6 (A = the bank, HL = the address; RAM 1 is
; paged back after each byte) and stored at $6000 up. RET returns to the game's
; menu ($8F61), which starts the game.
;
; 48K (CopySet48K $C175): the set at $9CF8 + $1200 x Explorer, where the tape
; put it, copied by LDIR; then stream 2 opened and StartTapeText $C2E8 printed
; by RST $10 up to its $0D, and RET to the loader at $5D64 with interrupts on.
; Known only from the code.
;
; c1: explorer 1 (Herr Krusche), 4608 stub calls; explorers: all five, each
; branch of the bank and address chain $C13F-$C159 taken.
;
; Witness: L1 6 (c1, explorers).
CopyExplorerSet:
  LD A,(Has128K)
  OR A
  JR Z,CopySet48K
  LD A,(Explorer)            ; E = the bank, HL = the set's address in it
  LD E,$04
  LD HL,$C000
  OR A
  JR Z,CopySetFromBank
  LD HL,$D200             ; explorer 1
  DEC A
  JR Z,CopySetFromBank
  LD HL,$E400             ; explorer 2
  DEC A
  JR Z,CopySetFromBank
  LD E,$03                ; explorers 3 and 4 are in RAM 3
  LD HL,$C000
  DEC A
  JR Z,CopySetFromBank
  LD HL,$D200             ; explorer 4
CopySetFromBank:
  LD BC,$1200             ; $1200 bytes through the stub to $6000
  LD IX,ExplorerSet
CopySetLoop:
  LD A,E                  ; one byte: page RAM E, read, page RAM 1
  PUSH BC
  CALL PagingStub
  POP BC
  LD (IX+$00),A
  INC IX
  INC HL
  DEC BC
  LD A,C
  OR B
  JR NZ,CopySetLoop
  RET
CopySet48K:
  LD A,(Explorer)            ; a 48K: the set from the tape's copy at $9CF8
  LD BC,$1200
  LD HL,TapeExplorerSets
  OR A
  JR Z,CopySetLdir
SetAddressLoop:
  ADD HL,BC               ; HL = $9CF8 + $1200 x Explorer
  DEC A
  JR NZ,SetAddressLoop
CopySetLdir:
  LD DE,ExplorerSet
  LDIR
  LD A,$02                ; stream 2, the upper screen
  CALL ChanOpen
  LD HL,StartTapeText
  LD IY,ErrNr
PrintStartTape:
  LD A,(HL)               ; print up to the $0D with the ROM's RST $10
  CP $0D
  EI
  RET Z
  DI
  PUSH HL
  RST $10
  POP HL
  INC HL
  JR PrintStartTape

; Put back the picture's bytes under the cursor (3 bytes x 16 rows)
;
; From CursorScreen $C4A4 (the screen address DrawCursor $C314 stored), each of
; 16 pixel rows: the 3 bytes at the same place in SelectorPicture $CF0F
; (address - $4000 + $CF0F) copied to the screen, then one row down (PixelDown
; $C35F). Called by SelectorWait $C12A after the HALT, before the next
; DrawCursor.
;
; c1: 1126 calls (frames 22225-23350).
;
; Witness: L1 3452 (c1, explorers).
RestoreUnderCursor:
  LD HL,(CursorScreen)
  EX DE,HL
  LD A,$10
RestoreRowLoop:
  EX AF,AF'               ; the picture's byte: the screen address with bit 14
                          ; off, plus SelectorPicture
  LD L,E
  LD H,D
  RES 6,H
  LD BC,SelectorPicture
  ADD HL,BC
  LD A,(HL)
  LD (DE),A
  INC HL
  INC DE
  LD A,(HL)
  LD (DE),A
  INC HL
  INC DE
  LD A,(HL)
  LD (DE),A
  DEC DE
  DEC DE
  PUSH DE
  POP BC
  CALL PixelDown
  PUSH BC
  POP DE
  EX AF,AF'
  DEC A
  JR NZ,RestoreRowLoop
  RET

; Copy SelectorPicture (6912 bytes) to the screen
;
; LDIR of SelectorPicture $CF0F to $4000-$5AFF. Called by SelectorRestart
; $C106. c1: once, frame 22221.
;
; Witness: L1 7 (c1, explorers).
DrawSelectorPicture:
  LD HL,SelectorPicture
  LD DE,Screen
  LD BC,$1B00
  LDIR
  RET

; Read the devices, move the cursor 2 pixels, set Explorer from its place
;
; Out: E = the device bits (ReadAnyDevice $C3BF: bit 0 right, 1 left, 2 down, 3
; up, 4 FIRE); CursorXY $C4A2 moved 2 pixels a step within x 0-$E8 and y 0-$A8
; (L = x, H = y: the cursor's top left); Explorer $5B70 set: 0 Fortisque-Smithe
; (y < $4D, $4C <= x < $91), 1 Herr Krusche ($0C <= y < $57, x >= $BC), 2 Henri
; Beaucoup ($6E <= y < $A9, $B0 <= x < $DB), 3 Big John Caine (x < $36, $3C <=
; y < $7D), 4 Wu Pong ($52 <= x < $7F, y >= $86), $FE Help ($0A <= x < $22, y
; >= $8C), else $FF; the tests in that order, the first that holds. Then three
; calls to ShowCoords $C4D6 (Explorer at $4040, x at $4000, y at $4020), which
; returns at once.
;
; c1: 1127 calls; explorers: every region reached ($C219, $C22A, $C23F, $C250,
; $C261, $C273 taken).
;
; Witness: L1 3459 (c1, explorers).
MoveCursor:
  CALL ReadAnyDevice
  LD E,A
  LD HL,(CursorXY)
  BIT 0,E
  JR Z,MoveLeft
  LD A,L
  CP $E8
  JR NC,MoveLeft
  INC L
  INC L
MoveLeft:
  BIT 1,E                 ; bit 1: x - 2 unless 0
  JR Z,MoveDown
  LD A,L
  OR A
  JR Z,MoveDown
  DEC L
  DEC L
MoveDown:
  BIT 2,E                 ; bit 2: y + 2 below $A8
  JR Z,MoveUp
  LD A,H
  CP $A8
  JR NC,MoveUp
  INC H
  INC H
MoveUp:
  BIT 3,E                 ; bit 3: y - 2 unless 0
  JR Z,ClassifyCursor
  LD A,H
  OR A
  JR Z,ClassifyCursor
  DEC H
  DEC H
ClassifyCursor:
  LD (CursorXY),HL        ; C = 0: Fortisque-Smithe's box
  LD C,$00
  LD A,H
  CP $4D
  JR NC,TryKrusche
  LD A,L
  CP $4C
  JR C,TryKrusche
  CP $91
  JR NC,TryKrusche
  JR StoreExplorer
TryKrusche:
  INC C                   ; C = 1
  LD A,H
  CP $0C
  JR C,TryBeaucoup
  CP $57
  JR NC,TryBeaucoup
  LD A,L
  CP $BC
  JR C,TryBeaucoup
  JR StoreExplorer
TryBeaucoup:
  INC C                   ; C = 2
  LD A,H
  CP $6E
  JR C,TryCaine
  CP $A9
  JR NC,TryCaine
  LD A,L
  CP $B0
  JR C,TryCaine
  CP $DB
  JR NC,TryCaine
  JR StoreExplorer
TryCaine:
  INC C                   ; C = 3
  LD A,L
  CP $36
  JR NC,TryWuPong
  LD A,H
  CP $3C
  JR C,TryWuPong
  CP $7D
  JR NC,TryWuPong
  JR StoreExplorer
TryWuPong:
  INC C                   ; C = 4
  LD A,L
  CP $52
  JR C,TryHelp
  CP $7F
  JR NC,TryHelp
  LD A,H
  CP $86
  JR C,TryHelp
  JR StoreExplorer
TryHelp:
  LD C,$FE                ; C = $FE: the Help box
  LD A,L
  CP $0A
  JR C,OnNothing
  CP $22
  JR NC,OnNothing
  LD A,H
  CP $8C
  JR C,OnNothing
  JR StoreExplorer
OnNothing:
  INC C                   ; C = $FF
StoreExplorer:
  LD A,C                  ; Explorer = C; the coordinate read-out (disabled)
  LD (Explorer),A
  PUSH DE
  PUSH HL
  LD DE,Screen+64
  CALL ShowCoords
  POP HL
  LD A,L
  PUSH HL
  LD DE,Screen
  CALL ShowCoords
  POP HL
  LD A,H
  LD DE,Screen+32
  CALL ShowCoords
  POP DE
  RET

; The 48K's first screen: STOP THE TAPE / THEN PRESS SPACE KEY, wait for SPACE
;
; Opens stream 2, sets Chars $5C36 to $3C00 (the ROM font), prints StopTapeText
; $C2B8 by RST $10 up to its $0D, then waits until SPACE (port $7FFE bit 0) is
; down. Called by SelectorRun $C0FC only when Has128K $5FFE = 0: not executed
; in any recording (c1, explorers: 128K). Known only from the code.
;
; Witness: L1 0 ().
ShowStopTape:
  LD A,$02
  CALL ChanOpen
  LD HL,RomCharSet
  LD (Chars),HL
  LD HL,StopTapeText
PrintStopTape:
  LD A,(HL)               ; RST $10 up to the $0D
  CP $0D
  JR Z,WaitSpace
  PUSH HL
  RST $10
  POP HL
  INC HL
  JR PrintStopTape
WaitSpace:
  LD BC,$7FFE             ; until SPACE is down
  IN A,(C)
  BIT 0,A
  JR NZ,WaitSpace
  RET

; The 48K's STOP THE TAPE / THEN PRESS SPACE KEY: ROM print codes, $0D ends
;
; For RST $10: INK 8, PAPER 8 (transparent), AT 10,9, FLASH 1, "STOP THE TAPE",
; FLASH 0, AT 12,6, "THEN PRESS SPACE KEY", $0D (the end mark ShowStopTape
; $C295 tests, not printed). Not read in any recording (128K).
StopTapeText:
  INCBIN "res/texts/stop-tape.bin",$0000,48

; The 48K's EXPLORER SELECTED / START TAPE: ROM print codes, $0D ends
;
; For RST $10 (PrintStartTape $C196): FLASH 0, INK 8, PAPER 8, AT 1,1,
; "EXPLORER", AT 2,1, "SELECTED", AT 5,0, FLASH 1, "START TAPE", $0D. Printed
; over the picture at the top left. Not read in any recording (128K).
StartTapeText:
  INCBIN "res/texts/start-tape.bin",$0000,44

; Draw the hand cursor at CursorXY, masked, from the frame for its pixel shift
;
; PixelToScreen $C39C gives BC = the screen address of CursorXY $C4A2 and A = x
; AND 6; BC is kept in CursorScreen $C4A4 for RestoreUnderCursor $C1A2. The
; frame: CursorSprites $CD8F + $60 x (A / 2), four frames pre-shifted 0, 2, 4,
; 6 pixels. Three columns of 16 rows (DrawColumn16 $C34B): screen = (screen AND
; mask) OR graphic, the graphic the frame's first 48 bytes, the mask the next
; 48.
;
; c1: 1127 calls; explorers: all four frames ($C333 taken 43 times).
;
; Witness: L1 3459 (c1, explorers).
DrawCursor:
  LD HL,(CursorXY)
  CALL PixelToScreen
  PUSH BC
  POP HL
  LD (CursorScreen),HL
  LD HL,CursorSprites
  OR A
  JR Z,CursorFrameChosen
  LD HL,CursorFrame2      ; x AND 6 = 2
  CP $02
  JR Z,CursorFrameChosen
  LD HL,CursorFrame4      ; 4
  CP $04
  JR Z,CursorFrameChosen
  LD HL,CursorFrame6      ; 6
CursorFrameChosen:
  PUSH HL                 ; DE = the mask, 48 bytes after the graphic
  LD DE,$0030
  ADD HL,DE
  EX DE,HL
  POP HL
  LD A,$03
DrawColumnLoop:
  PUSH AF                 ; three columns, BC one byte right each
  PUSH BC
  CALL DrawColumn16
  POP BC
  INC BC
  POP AF
  DEC A
  JR NZ,DrawColumnLoop
  RET

; Draw 16 rows of one cursor column: two DrawColumn8
;
; The chain $C34B, $C34E, $C351, $C354 each call the next and fall into it, so
; PlotCursorByte $C357 runs 16, 8, 4, 2 times from each entry. c1: 3381 calls
; (1127 x 3 columns).
;
; Witness: L1 10377 (c1, explorers).
DrawColumn16:
  CALL DrawColumn8

; 8 rows: two DrawColumn4
;
; Witness: L1 20754 (c1, explorers).
DrawColumn8:
  CALL DrawColumn4

; 4 rows: two DrawColumn2
;
; Witness: L1 41508 (c1, explorers).
DrawColumn4:
  CALL DrawColumn2

; 2 rows: two PlotCursorByte
;
; Witness: L1 83016 (c1, explorers).
DrawColumn2:
  CALL PlotCursorByte

; One cursor byte: (BC) = (BC) AND (DE) OR (HL), then a row down
;
; HL = the graphic, DE = the mask, BC = the screen; HL and DE step on and the
; code falls into PixelDown $C35F. c1: 54 096 runs (3381 x 16).
;
; Witness: L1 166032 (c1, explorers).
PlotCursorByte:
  LD A,(BC)
  EX DE,HL
  AND (HL)
  EX DE,HL
  OR (HL)
  LD (BC),A
  INC DE
  INC HL

; BC = the screen address one pixel row down
;
; The usual display-file walk: B + 1; across a character row back to its top
; and C + $20; across a third (C's top three bits all set) C AND $1F and B + 8.
; Used by PlotCursorByte $C357 and RestoreUnderCursor $C1A2.
;
; Witness: L1 221264 (c1, explorers).
PixelDown:
  INC B
  LD A,B
  AND $07
  RET NZ
  DEC B                   ; a character row crossed
  LD A,C
  CPL
  AND $E0
  JR Z,PixelDownThird
  LD A,C
  ADD A,$20
  LD C,A
  LD A,B
  AND $F8
  LD B,A
  RET
PixelDownThird:
  LD A,C                  ; the next third
  AND $1F
  LD C,A
  LD A,B
  AND $F8
  ADD A,$08
  LD B,A
  RET

; Black border, the bitmap cleared, attributes $47 (bright white on black)
;
; Called by SelectorRun $C0FC and SelectorRestart $C106. c1: twice (frames
; 22215-22221).
;
; Witness: L1 14 (c1, explorers).
ClearScreen:
  XOR A
  OUT ($FE),A
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$1AFF
  LD (HL),L
  LDIR
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$47
  LDIR
  RET

; Pixel x (L), y (H) to the screen address BC and the pixel shift A
;
; Out: BC = $4000 + the display-file address of the byte holding pixel (x, y);
; A = x AND 6 (x is always even); flags from the AND. Used by DrawCursor $C314.
;
; Witness: L1 3459 (c1, explorers).
PixelToScreen:
  LD A,L
  PUSH AF
  RRCA
  RRCA
  RRCA
  AND $1F
  LD C,A
  LD A,H
  RLCA
  RLCA
  AND $E0
  OR C
  LD C,A
  LD A,H
  AND $07
  LD B,A
  LD A,H
  AND $C0
  RRCA
  RRCA
  RRCA
  OR B
  OR $40
  LD B,A
  POP AF
  AND $06
  RET

  ORG $C4A2

; The cursor's place (L = x, H = y) and its screen address
;
; CursorXY: x 0-$E8 and y 0-$A8, the top left of the 24 x 16 hand;
; SelectorRestart $C106 sets x 100, y 80 ($5064), MoveCursor $C1D5 moves it.
; CursorScreen $C4A4: the screen address DrawCursor $C314 drew at, read by
; RestoreUnderCursor $C1A2. explorers writes $C4A2-$C4A5.
CursorXY:
  DEFW $0000
CursorScreen:
  DEFW $0000              ; the screen address of the drawn cursor

  ORG $CD8F

; The hand cursor: 4 frames pre-shifted 0, 2, 4, 6 pixels, 24 x 16, graphic
; then mask
;
; Each frame is 96 bytes: the graphic, 3 columns of 16 bytes (column-major, top
; to bottom), then the mask in the same order (AND before OR). DrawCursor $C314
; picks the frame by x AND 6. explorers reads all four.
CursorSprites:
  INCBIN "res/graphics/cursor.bin",$0000,48
CursorMask0:
  INCBIN "res/graphics/cursor.bin",$0030,48
CursorFrame2:
  INCBIN "res/graphics/cursor.bin",$0060,48
CursorMask2:
  INCBIN "res/graphics/cursor.bin",$0090,48
CursorFrame4:
  INCBIN "res/graphics/cursor.bin",$00C0,48
CursorMask4:
  INCBIN "res/graphics/cursor.bin",$00F0,48
CursorFrame6:
  INCBIN "res/graphics/cursor.bin",$0120,48
CursorMask6:
  INCBIN "res/graphics/cursor.bin",$0150,48

; The selector screen: the five explorers' portraits and names, the Help box
; (6912 bytes)
;
; A whole screen ($1800 bitmap, $300 attributes): Fortisque-Smithe (top
; middle), Herr Krusche (top right), Big John Caine (left), Henri Beaucoup
; (bottom right), Wu Pong (bottom middle) and a "?" Help box (bottom left),
; each named under the portrait. DrawSelectorPicture $C1C9 copies it to the
; screen; RestoreUnderCursor $C1A2 reads it back under the cursor.
SelectorPicture:
  INCBIN "res/screens/selector.bin",$0000,6144
SelectorAttributes:
  INCBIN "res/screens/selector.bin",$1800,768
