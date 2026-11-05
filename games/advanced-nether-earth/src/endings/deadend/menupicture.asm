; --------------------------------------------------------------------------------------------------------------------
; menupicture.asm: the game menu's picture (the game calls it)
;
; Not Dead End's: the game draws its menu picture with this routine (the recording work/endings/de runs it at frame
; 1505, after Restart). A byte-identical copy of LzScreen (lzscreen.asm has the format), followed by its stream.
; --------------------------------------------------------------------------------------------------------------------

; unpack the game menu's picture (MenuPictureData) into the screen
;
; The same code as LzScreen at its own place: the operands it patches and the
; stream it takes are its own (MenuHere + ...). Called by the game with bank 3
; paged.
MenuPicture:
  EI
  CALL RomRet             ; a RET in the ROM: the return address, MenuHere,
                          ; stays just under SP
MenuHere:
  DEC SP                  ; SP back onto it: BC = MenuHere
  DEC SP
  POP BC
  LD HL,MenuPutByte-MenuHere
  ADD HL,BC
  EX DE,HL
  LD HL,MenuMatchCall+$0001-MenuHere
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,MenuLiteralCall+$0001-MenuHere
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,MenuRunCall+$0001-MenuHere
  ADD HL,BC
  LD (HL),E
  INC HL
  LD (HL),D
  LD HL,MenuPictureData-MenuHere
  ADD HL,BC
  LD DE,$4000
  PUSH DE
  EXX
  EX AF,AF'
  LD A,$03
  OR A
  LD B,$08
  LD C,B
  POP HL
  EX AF,AF'
  EXX
MenuToken:
  LD A,(HL)
  BIT 7,A
  JR NZ,MenuNotMatch
  AND $07
  LD C,A
  LD A,(HL)
  RRCA
  RRCA
  RRCA
  AND $0F
  ADD A,$03
  LD B,A
  INC HL
  LD A,E
  SUB (HL)
  INC HL
  PUSH HL
  LD L,A
  LD A,D
  SBC A,C
  LD H,A
MenuMatchByte:
  PUSH HL
  LD A,H
  AND $58
  CP $58
  JR Z,MenuMatchRead
  LD C,A
  LD A,L
  AND $07
  OR C
  LD C,A
  ADD HL,HL
  ADD HL,HL
  LD A,H
  AND $1F
  LD H,A
  LD A,L
  AND $E0
  OR H
  LD L,A
  LD H,C
MenuMatchRead:
  LD A,(HL)
MenuMatchCall:
  CALL LzPutByteOrg       ; (CALL MenuPutByte)
  POP HL
  INC HL
  DJNZ MenuMatchByte
  POP HL
  JR MenuToken
MenuNotMatch:
  AND $7F
  JR Z,MenuEnd
  INC HL
  BIT 6,A
  JR NZ,MenuRun
  LD B,A
MenuLiteralByte:
  LD A,(HL)
MenuLiteralCall:
  CALL LzPutByteOrg       ; (CALL MenuPutByte)
  INC HL
  DJNZ MenuLiteralByte
  JR MenuToken
MenuRun:
  AND $3F
  ADD A,$03
  LD B,A
  LD A,(HL)
MenuRunCall:
  CALL LzPutByteOrg       ; (CALL MenuPutByte)
  DJNZ MenuRunCall
  INC HL
  JR MenuToken
MenuEnd:
  EXX
  LD HL,RomHlAlt
  EXX
  EI
  RET

; the byte A to the screen in the depacker's order (LzPutByte's copy)
MenuPutByte:
  INC DE
  EXX
  LD (HL),A
  EX AF,AF'
  JR Z,MenuPutAttr
  INC H
  DJNZ MenuPutDone
  LD DE,-$07E0
  ADD HL,DE
  DEC C
  JR NZ,MenuPutLines
  LD DE,-$00FF
  ADD HL,DE
  ADD A,$08
  JR NC,MenuPutCells
  LD DE,$07E0
  ADD HL,DE
  DEC A
  JR MenuPutCells
MenuPutAttr:
  INC HL
MenuPutCells:
  LD C,$08
MenuPutLines:
  LD B,$08
MenuPutDone:
  EX AF,AF'
  EXX
  RET

; the game menu's picture (screen LZ, 2545 bytes)
MenuPictureData:
  INCBIN "res/pictures/game-menu.lz",$0000,2545
