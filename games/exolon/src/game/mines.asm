; --------------------------------------------------------------------------------------------------------------------
; mines.asm: The mines
; --------------------------------------------------------------------------------------------------------------------

; The mines: an armed one fires when the player stands on it, a spent one burns
;
; Main loop, every pass (c1: 3260 entries, the list always empty on screen 0; w
; clones: 51 682 records walked). Sets the font pointer of the character
; printer (the operand $ADEF of $ADE1) to $DAB8, the object glyphs, and flips
; MineFlameToggle between 0 and 2.
;
; A record of MineList is (column, row, state). State 1 (set by ArmMines) is
; armed: MineArmed tests the player's position. State 0 is spent: two flame
; glyphs $1D/$1E (or $1F/$20 on the other pass) are printed at (row, column)
; and (row, column + 1) in a random bright ink with bit 1 set (red, magenta,
; yellow or white).
;
; The mine's own picture is part of the scenery element that put a 5 into the
; map $6100 (record 5 of $8EF4: the map cell then 1, solid).
;
; w030: 1 mine fired; 23 warp clones fired one each.
Mines:
  LD HL,TileGlyphs
  LD (PrintChar+$000E),HL
  LD A,(MineFlameToggle)
  XOR $02
  LD (MineFlameToggle),A
  LD HL,MineList
MinesLoop:
  LD E,(HL)               ; E = column ($FF: the end), D = row, A = state
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  DEC A                   ; state 1: armed
  JR Z,MineArmed
  CALL Random             ; spent: the flames, a random bright red-ish ink
  AND $07
  OR $42
  LD C,A
  LD A,(MineFlameToggle)  ; glyph $1D or $1F
  ADD A,$1D
  CALL PrintChar
  INC A
  INC E
  CALL PrintChar
  JR MinesLoop
MineArmed:
  LD B,D                  ; BC = the cell; DE = its pixel position (X in
                          ; 2-pixel units, Y in pixels)
  LD C,E
  CALL CellToPixels
  DEC D
  LD A,(PlayerY)          ; the player's bottom line (Y + 31) must be the line
                          ; just above the mine
  ADD A,$1F
  CP D
  JR NZ,MinesLoop
  LD A,(PlayerX)          ; and his X within E-7..E+2
  ADD A,$06
  SUB E
  SUB $09
  CP $F6
  JR C,MinesLoop
MineFires:
  DEC HL                  ; state 0: spent
  LD (HL),$00
  LD D,B                  ; D = the row above the mine
  LD E,C
  DEC D
  CALL MineBlast          ; the debris, the explosion sound $C148, then the
                          ; kill unless the exoskeleton is worn
  CALL PlaySfxBlast
  JP ShieldedKill

; 0 or 2: which flame pair the spent mines show this pass
MineFlameToggle:
  DEFB $00

; Up to 10 mines (column, row, state); $FF after the last
;
; Built by $8E86 from map value 5 (record size 3: the builder writes column and
; row, the third byte keeps the 1 ArmMines put there). Mines sets the state to
; 0 when one fires.
MineList:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $FF                ; the fixed end mark

; Throw the debris of a fired mine: ten blank XOR characters, each spawning two
; debris pieces
;
; In: D = the row above the mine, E = its column. Selects printer 3
; (EraseBlockDebris $AE95, SetPrinter), takes the attribute of the cell two
; rows down (the floor under the mine) into the colour byte of MineBlastText,
; prints the text at (D, E), then selects printer 0 again.
;
; The text prints two spaces five times at the same place: each character XORed
; on the screen (a blank glyph: no change), its cell marked in the maps $5B00 /
; $5E00 / $6100, and AddDebris called twice for it: 20 debris pieces in the
; colour of the floor.
MineBlast:
  LD A,$03
  CALL SetPrinter
  INC D                   ; the attribute two rows down
  INC D
  CALL CellOffset
  DEC D
  DEC D
  LD BC,$5800
  ADD HL,BC
  LD A,(HL)
  LD (MineBlastText+$0004),A
  LD HL,MineBlastText     ; the debris text
  CALL PrintString
  XOR A
  JP SetPrinter

; The print string of MineBlast (control codes of PrintString $AF2B)
;
; $E6 $E0 $D7: the font $D7E0; $E0 n: the colour (patched with the floor's
; attribute at $91F1); $E1 5 ... $E2: repeat five times: two spaces, then $78
; $FE (row + 0, column - 2); $FF: the end.
MineBlastText:
  DEFB $E6,$E0,$D7,$E0,$05,$E1,$05,$20,$20,$78,$FE,$E2,$FF

; Set the state byte of the mine records to 1 (armed)
;
; Called by the screen builder $8494 before the lists are built: fills
; $91B0-$91CD with 1, so each record's third byte reads 1 once $8EAD has
; written its column and row.
ArmMines:
  LD HL,MineList
  LD DE,MineList+$0001
  LD (HL),$01
  LD BC,$001D
  LDIR
  RET
