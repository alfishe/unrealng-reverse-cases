; --------------------------------------------------------------------------------------------------------------------
; progress.asm: The progress screen: the ED picture
; --------------------------------------------------------------------------------------------------------------------

; Show the ED circuit picture of the pieces taken; with A = $FF the percentage
;
; In: A the piece just taken (1-50), 0 (the win) or $FF (the game over). The
; sprite list is emptied and the energy timer stopped; a piece's bit is set in
; EdFlags (byte (n - 1) / 5, bit (n - 1) mod 5). The play area is cleared and
; coloured $31; the 10 x 5 picture is drawn at $4886 from EdPieces (a piece
; taken: its 16 x 16 tile, colour $67, 2 % each; not taken: colour $28, no
; pixels); the new piece's cells flash $67 / $64 nine times with long delays;
; with A = $FF the text YOU HAVE COMPLETED nn % OF TUJAD. Then the energy timer
; is restarted and Shot cleared. L1 36 (35 pieces, 1 game over).
;
; The delay loop at ProgressDelay (LD BC,$C350, 50 000 rounds) is the longest
; wait in the game: 9 x 50 000 x 26 T, about 3.3 s at 3.5 MHz.
ProgressScreen:
  LD HL,SpriteList
  LD (SpriteListEnd),HL
  LD (HL),$00
  INC L
  LD (HL),$00
  EI
  LD HL,EnergyTimer
  LD (HL),$00
  LD HL,ProgressPercentBcd
  LD (HL),$00
  LD (DrawMode),A
  CP $00
  JR Z,ProgressDraw
  CP $FF
  JR Z,ProgressDraw
  LD HL,EdFlags
ProgressByte:
  CP $06
  JR C,ProgressBit
  INC HL
  SUB $05
  JR ProgressByte
ProgressBit:
  LD C,$80
ProgressBitLoop:
  RLC C
  DEC A
  JR NZ,ProgressBitLoop
  LD A,(HL)
  OR C
  LD (HL),A
ProgressDraw:
  CALL ClearPlayArea
  LD HL,Attributes+192
  LD DE,Attributes+193
  LD BC,$023F
  LD (HL),$31
  LDIR
  LD HL,Screen+2182
  LD (RoomRecordPtr),HL
  LD DE,EdPieces
  LD BC,$0501
ProgressRow:
  PUSH BC
  LD HL,EdFlags
  LD B,$0A
ProgressPiece:
  LD A,(HL)
  AND C
  INC HL
  PUSH BC
  PUSH DE
  PUSH HL
  LD C,$67
  JR NZ,ProgressPieceTaken
  LD C,$28
  CALL ProgressCell
  JR ProgressPieceNext
ProgressPieceTaken:
  LD A,(ProgressPercentBcd)
  ADD A,$02
  DAA
  LD (ProgressPercentBcd),A
  LD HL,(RoomRecordPtr)
  CALL Blit16
  CALL ProgressCell
ProgressPieceNext:
  POP HL
  POP DE
  POP BC
  LD A,$20
  ADD A,E
  LD E,A
  JR NC,ProgressPieceLoop
  INC D
ProgressPieceLoop:
  DJNZ ProgressPiece
  POP BC
  SLA C
  DJNZ ProgressRow
  LD HL,Attributes+326
  LD A,(DrawMode)
  CP $00
  JR Z,ProgressDone
  CP $FF
  JR Z,ProgressDone
  LD C,A
ProgressFindNew:
  LD DE,$0040
  ADD HL,DE
  LD A,H
  CP $5A
  JR NZ,ProgressFindNext
  LD A,L
  AND $E0
  CP $C0
  JR NZ,ProgressFindNext
  LD DE,$013E
  SCF
  CCF
  SBC HL,DE
ProgressFindNext:
  DEC C
  JR NZ,ProgressFindNew
  LD DE,$001F
  LD A,$67
  LD (RoomRecordPtr),A
  LD B,$09
ProgressFlash:
  PUSH BC
  LD B,$02
  PUSH HL
  LD A,(RoomRecordPtr)
ProgressFlashCell:
  LD (HL),A
  INC L
  LD (HL),A
  ADD HL,DE
  DJNZ ProgressFlashCell
  POP HL
  XOR $03
  LD (RoomRecordPtr),A
  LD BC,$C350
ProgressDelay:
  DEC BC
  LD A,B
  OR C
  JR NZ,ProgressDelay
  POP BC
  DJNZ ProgressFlash
ProgressDone:
  XOR A
  LD (Shot),A
  LD HL,EnergyTimer
  LD A,(EnergyReload)
  LD (HL),A
  LD A,(DrawMode)
  CP $FF
  CALL Z,ProgressPercent
  DI
  RET

; Print YOU HAVE COMPLETED nn % OF TUJAD. with the BCD percentage
;
; The two digits go into ProgressText + 19 and + 20 ($9085, $9086; a leading 0
; a space). L1 1 (game-over).
ProgressPercent:
  LD A,(ProgressPercentBcd)
  AND $0F
  ADD A,$30
  LD (ProgressText+$0014),A
  LD A,(ProgressPercentBcd)
  SRL A
  SRL A
  SRL A
  SRL A
  ADD A,$30
  CP $30
  JR NZ,ProgressPercentTens
  LD A,$20
ProgressPercentTens:
  LD (ProgressText+$0013),A
  LD HL,ProgressText
  LD DE,Screen+2048
  LD A,$31
  CALL PrintText
  RET

; YOU HAVE COMPLETED   % OF TUJAD. (the digits at +19 and +20)
ProgressText:
  INCBIN "res/text/ProgressText.bin",$0000,32
ProgressPercentBcd:
  INCBIN "res/text/ProgressText.bin",$0020,1

; Colour a piece's 2 x 2 cells C and step to the next place of the picture
;
; L1 1 800.
ProgressCell:
  LD HL,(RoomRecordPtr)
  LD A,H
  RRCA
  RRCA
  RRCA
  AND $03
  OR $58
  LD H,A
  LD B,$02
  LD DE,$001F
ProgressCellRow:
  LD (HL),C
  INC L
  LD (HL),C
  ADD HL,DE
  DJNZ ProgressCellRow
  LD HL,(RoomRecordPtr)
  INC L
  INC L
  LD A,L
  AND $1F
  CP $1A
  JR NZ,ProgressCellNext
  LD A,L
  AND $E0
  OR $06
  ADD A,$40
  LD L,A
  JR NC,ProgressCellNext
  LD A,H
  ADD A,$08
  LD H,A
ProgressCellNext:
  LD (RoomRecordPtr),HL
  RET
