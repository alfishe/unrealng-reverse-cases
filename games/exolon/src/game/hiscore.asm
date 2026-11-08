; --------------------------------------------------------------------------------------------------------------------
; hiscore.asm: The Hall of Fame: the table of 50 and its rolling display
; --------------------------------------------------------------------------------------------------------------------

; After a name entry: clears ShowHallOfFame and rolls the Hall of Fame (into
; HallOfFameRoll)
;
; Start jumps here when ShowHallOfFame $71F0 is set ($A13A sets it after the
; name). h1: once, after EXOLON was entered. Not in the case's code builds (h1
; is a clone), so it was data in the cut.
ShowHallOfFameFirst:
  XOR A
  LD (ShowHallOfFame),A

; The Hall of Fame: a screen of planets, the 50 names and scores rolled up
; pixel line by pixel line
;
; Clears the screen with attribute $44 ($B04D), prints HallOfFameScreen $718D
; (the logo, the planets), points HallOfFamePtr $7588 at HallOfFame $71F1 and
; sets the font $D7E0 ($ADEF).
;
; Then $03C0 = 960 steps: every 16th step (C AND $0F = 0) PrintNextHallEntry
; prints the next entry on row 23, the other steps wait $0400 ($B0B7); each
; step ScrollHallOfFame moves rows 4-23 of columns 8-23 up one pixel line. 16
; lines an entry, so 60 entries' worth: the 50 entries, then 10 empty ones that
; roll the last up. A key ends it: 1 starts the game (StartGame), any other
; back to MainMenu; so does the end of the 960 steps.
;
; Reached from MainMenu's timeout and from ShowHallOfFameFirst. h1: the whole
; roll (960 steps); c128: one step, then key 1; c1: never.
HallOfFameRoll:
  LD C,$44
  CALL ClearScreenAttr
  LD HL,HallOfFameScreen
  CALL PrintString
  LD HL,HallOfFame
  LD (HallOfFamePtr),HL
  LD BC,$03C0
  LD HL,FontBase          ; the default font for the entries
  LD (PrintChar+$000E),HL
HallOfFameStep:
  PUSH BC                 ; one step: a print or a wait, then the scroll
  NOP
  NOP
  NOP
  LD A,C
  AND $0F
  OR A
  LD BC,$0400             ; the wait of the steps without a print
  CALL NZ,Delay
  CALL Z,PrintNextHallEntry
  CALL ScrollHallOfFame
  POP BC
  DEC BC
  LD A,B
  OR C
  JP Z,MainMenu
  CALL ReadKey            ; a key: 1 starts the game, any other the menu
  OR A
  JP Z,HallOfFameStep
  CP $31
  JP Z,StartGame
  JP MainMenu

; The Hall of Fame screen: the logo, the score columns' attribute, twelve
; planet pictures round the edges
;
; Printed by HallOfFameRoll. The logo at row 0 column 8; attribute $43 and the
; font $D7E0; 19 rows of 8 spaces from row 4 column 16 (columns 16-23: the
; scores' side); then twelve sub-strings drawing the planets of the screen at
; the edges: $8A07 at 0,0 / 5,3 / 21,26, $8671 at 1,5 / 16,4 / 18,30, $864F at
; 10,0 / 0,26, $8A9D at 19,1 / 14,26, $8A75 at 5,26, $8A85 at 9,28 (the
; pictures are in the screen graphics strings). h1 screens.png: the roll
; between the planets.
HallOfFameScreen:
  DEFB $DF,$00,$08,$E3,$FF,$70,$E0,$43,$E6,$E0,$D7
  DEFB $DF,$04,$10,$E1,$13,$20,$20,$20,$20,$20,$20,$20,$20,$A7,$E2 ; AT 4,16:
                                                                   ; 19 rows of
                                                                   ; 8 spaces
  DEFB $DF,$00,$00,$E3,$07,$8A,$DF,$01,$05,$E3,$71,$86,$DF,$05,$03,$E3 ; the twelve
  DEFB $07,$8A,$DF,$0A,$00,$E3,$4F,$86,$DF,$10,$04,$E3,$71,$86,$DF,$13 ; planets
  DEFB $01,$E3,$9D,$8A,$DF,$00,$1A,$E3,$4F,$86,$DF,$05,$1A,$E3,$75,$8A
  DEFB $DF,$09,$1C,$E3,$85,$8A,$DF,$0E,$1A,$E3,$9D,$8A,$DF,$12,$1E,$E3
  DEFB $71,$86,$DF,$15,$1A,$E3,$07,$8A
  DEFB $FF                ; the end

; 1 after a name entry: Start shows the Hall of Fame before the menu
;
; Set by $A13A after the name, read by Start ($6D9A), cleared by
; ShowHallOfFameFirst.
ShowHallOfFame:
  DEFB $00

; The Hall of Fame: 50 entries of 16 bytes (a name of 10 characters, the score
; in 6 ASCII digits), $FF ends
;
; Highest first. The image holds RAFFAELE, SURYANI, SCRAGGY, SABATTA!, PADDY,
; LOFTY, ... HUMPTY, all 001000. $A073 compares the score $AD8A with the +10
; digits entry by entry, moves the lower entries down 16 bytes (LDDR from $7510
; to $7520: the last entry is pushed into $7511-$7520) and writes the end mark
; at $7511 again, then the new score; the name entry fills the 10 name bytes.
;
; HallOfFameRoll prints the entries 16 characters at a time; its scroll leaves
; columns 16-17 (the name's 9th and 10th characters) where they were printed,
; so a name longer than 8 characters keeps those two letters on row 23 only.
HallOfFame:
  DEFB $52,$41,$46,$46,$41,$45,$4C,$45,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $53,$55,$52,$59,$41,$4E,$49,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $53,$43,$52,$41,$47,$47,$59,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $53,$41,$42,$41,$54,$54,$41,$21,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $50,$41,$44,$44,$59,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4C,$4F,$46,$54,$59,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4A,$49,$4D,$42,$4F,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4C,$45,$4F,$20,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $47,$4C,$45,$4E,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4D,$4F,$52,$41,$4E,$47,$45,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $50,$55,$50,$50,$59,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4F,$4E,$49,$4F,$4E,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $52,$49,$50,$20,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $46,$49,$47,$41,$52,$4F,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $49,$4E,$4B,$20,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $50,$45,$4E,$20,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $44,$55,$4D,$42,$4F,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4D,$45,$50,$48,$49,$53,$54,$4F,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $51,$55,$45,$45,$4E,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $55,$4E,$59,$49,$4C,$20,$3F,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $45,$51,$55,$49,$4E,$4F,$58,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $52,$45,$41,$4C,$4D,$53,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4D,$41,$4A,$41,$4C,$41,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4C,$45,$4E,$47,$4B,$41,$50,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4A,$41,$5A,$5A,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $48,$45,$57,$53,$4F,$4E,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $54,$49,$4D,$2E,$4D,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $43,$45,$43,$43,$4F,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4C,$55,$43,$59,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $41,$4E,$54,$4F,$4E,$59,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4E,$49,$41,$45,$52,$45,$48,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $2A,$21,$2F,$3F,$21,$40,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $50,$4F,$44,$20,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $48,$55,$54,$4E,$45,$45,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $42,$55,$54,$4E,$45,$45,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4A,$4F,$48,$4E,$2E,$4F,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $43,$41,$52,$52,$4F,$54,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $43,$4F,$4C,$49,$4E,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $46,$4C,$41,$53,$48,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $53,$45,$56,$49,$4C,$4C,$45,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $54,$2D,$53,$54,$41,$54,$45,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $43,$4C,$55,$42,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $48,$57,$50,$20,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $43,$44,$50,$20,$20,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $54,$41,$43,$48,$59,$4F,$4E,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $4B,$49,$4C,$4C,$45,$52,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $44,$52,$4F,$4F,$50,$59,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $52,$20,$34,$20,$53,$20,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $52,$5A,$41,$53,$4D,$32,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $48,$55,$4D,$50,$54,$59,$20,$20,$20,$20,$30,$30,$31,$30,$30,$30
  DEFB $FF                ; the end mark
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 16 bytes
                                                                       ; after the
                                                                       ; end: the
                                                                       ; last entry
                                                                       ; lands here
                                                                       ; and is cut
                                                                       ; off by the
                                                                       ; end mark
                                                                       ; when an
                                                                       ; entry is
                                                                       ; inserted

; Moves screen lines 33-191 up one pixel line in columns 8-15 and 18-23, then
; clears the bottom line
;
; SP walks the line address table $6700 (the address of column 8 of each line)
; from line 32: each line's 14 bytes (columns 8-15, then 18-23; columns 16-17
; are skipped) are copied to the line above, 159 lines ($08B2 LDIs, 14 a line).
; The last line's address is patched into ScrollDest each time. Then 17 bytes
; from the last destination's end are cleared (the bottom line of the window).
; SP is kept in SpriteSavedSP $78DA. h1: 960 runs, 152 640 lines.
ScrollHallOfFame:
  PUSH BC
  LD (SpriteSavedSP),SP
  LD SP,LineCol8Addr+64
  LD BC,$08B2
  POP DE
ScrollLine:
  POP HL                  ; HL = the next line, which is the destination of the
                          ; line after it
  LD (ScrollDest+$0001),HL
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  INC L                   ; columns 16 and 17 stay
  INC E
  INC L
  INC E
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
ScrollDest:
  LD DE,$0000             ; LD DE,n: n = the line above (patched)
  JP PE,ScrollLine
  LD SP,(SpriteSavedSP)   ; the bottom line of the window cleared
  EX DE,HL
  LD E,L
  LD D,H
  INC E
  LD BC,$0010
  LD (HL),B
  LDIR
  POP BC
  RET

; Prints the next Hall of Fame entry (16 characters) on row 23 from column 8,
; then waits
;
; HallOfFamePtr $7588: at the end mark ($FF) only the wait (BC as the caller
; left it, $0400); else the 16 characters of the entry (name and score) through
; $AE26 at row 23 column 8, the pointer advanced, then a wait of $028E. h1: 60
; calls, 50 entries printed.
PrintNextHallEntry:
  LD HL,(HallOfFamePtr)
  LD A,(HL)
  CP $FF
  JP Z,Delay
  LD DE,$1708
  LD BC,$1000
HallEntryChar:
  LD A,(HL)               ; one character, the column on
  CALL PrintCharAttr
  INC E
  INC HL
  DJNZ HallEntryChar
  LD (HallOfFamePtr),HL
  LD BC,$028E
  JP Delay

; The next Hall of Fame entry to print (PrintNextHallEntry; HallOfFameRoll sets
; it to HallOfFame)
HallOfFamePtr:
  DEFW $0000
