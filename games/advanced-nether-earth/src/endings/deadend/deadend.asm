; --------------------------------------------------------------------------------------------------------------------
; deadend.asm: Dead End: the sequence and its starfield
;
; The game jumps to DeadEnd when the player loses (bank 3 paged at $C000, interrupt mode 1). The sequence: the Dead
; End picture (LzScreen) with Syrus's tune NETHER EARTH (END) played from an interrupt of its own (mode 2, the vector
; table Im2Table, the handler Im2Handler); a key; the GAME OVER screen (HrustScreen) under a starfield of 120 stars in
; four layers moving right at 1, 2, 4 and 8 pixels a frame; a key; the AY silenced, the screen cleared, interrupt mode
; 1 again and back to the game through Restart.
;
; The starfield is drawn the fast way: SP points into the star tables and each POP gives one star's screen address.
; Every frame StarsRestore puts back the 120 screen bytes saved under the stars, StarsMove moves them, StarsSave saves
; the bytes under their new places and StarsDraw ORs each layer's pixel in. A star's address only ever moves one byte
; right (INC of its low byte), so a star walks along its pixel line and drops to the next character row at the right
; edge.
; --------------------------------------------------------------------------------------------------------------------

; Dead End: the picture, the tune, GAME OVER and the stars, then the game menu
;
; Entered by a jump from the game's end test with bank 3 at $C000 when the
; player has no buildings left (the recording work/endings/de: PlayerBuildings
; $FD3A poked to 0 in a saved game). Never returns: it ends with JP Restart.
DeadEnd:
  LD SP,$0000             ; the stack at the top of memory (SP = 0: the first
                          ; push goes to $FFFE)
  CALL ClearScreen        ; a black screen
  DI
  CALL nst.Init              ; start the tune: the player's init (it leaves
                          ; interrupts enabled; mode 1 is still on)
  CALL LzScreen           ; the Dead End picture to the screen
  LD HL,Im2Table          ; the vector table: 257 bytes of $FD, so any data bus
                          ; value gives the handler at $FDFD
  LD DE,Im2Table+$0001
  LD (HL),$FD
  LD BC,$0100
  LDIR
  LD A,Im2Table/$100      ; I = the table's page
  LD I,A
  IM 2
  EI                      ; from now on the tune plays every frame
  HALT
DeadEndKey:
  XOR A                   ; wait for any key (all half rows, the five key bits)
  IN A,($FE)
  CPL
  AND $1F
  JR Z,DeadEndKey
  CALL ClearScreen        ; the GAME OVER screen
  CALL HrustScreen
  HALT
  CALL StarsSave          ; save the bytes under the stars' first places
DeadEndStars:
  HALT                    ; a frame of the starfield
  CALL StarsRestore
  CALL StarsMove
  CALL StarsSave
  CALL StarsDraw
  XOR A                   ; until a key
  IN A,($FE)
  CPL
  AND $1F
  JR Z,DeadEndStars
  CALL nst.Init              ; silence the AY (the player's init writes the silent
                          ; registers)
  CALL ClearScreen
  LD A,$3F                ; I as the ROM keeps it, interrupt mode 1, back to
                          ; the game menu
  LD I,A
  IM 1
  EI
  JP Restart

; clear the screen (pixels and attributes) to 0
;
; Writes 0 from $5AFF down and reads it back: RAM reads 0 and the loop goes on;
; the first byte that reads non-zero is the ROM's below $4000. Out: HL there, A
; that ROM byte.
ClearScreen:
  XOR A
  LD HL,$5B00
ClearScreenLoop:
  DEC HL
  LD (HL),A
  OR (HL)
  JR Z,ClearScreenLoop
  RET

; save the screen byte under each of the 120 stars
;
; SP walks the star tables (StarsLayer1 .. StarsLayer4), DE the save buffer
; StarsSaved; one LDI a star. C = $FF keeps the LDIs from carrying into B, the
; outer count (4 x 30). Ends through StarsRet, which restores SP.
StarsSave:
  LD (StarsRet+$0001),SP  ; SP into StarsRet's operand
  LD SP,StarsLayer1
  LD DE,StarsSaved
  LD C,$FF                ; C = $FF: the LDIs count C down, not B
  LD B,$04                ; 4 rounds of 30 stars
StarsSaveLoop:
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  POP HL
  LDI
  DJNZ StarsSaveLoop
  JP StarsRet

; put the saved bytes back under the 120 stars
;
; The reverse of StarsSave: SP walks the star tables, HL the save buffer; one
; LDI from the buffer to each star's address.
StarsRestore:
  LD (StarsRet+$0001),SP
  LD HL,StarsSaved
  LD SP,StarsLayer1
  LD C,$FF
  LD B,$04
StarsRestoreLoop:
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  POP DE
  LDI
  DJNZ StarsRestoreLoop
  JP StarsRet

; OR each layer's pixel into its 30 stars
;
; Each layer's one-pixel mask is the operand StarsMove rotates (StarsMove+1 for
; layer 1, StarsMask2+1 .. StarsMask4+1); StarsPlot ORs it into the 30 screen
; bytes of the layer. B (3-6) is set for StarsPlot but not used there (it sets
; its own B).
StarsDraw:
  LD B,$03
  LD A,(StarsMove+$0001)
  LD HL,StarsLayer1
  CALL StarsPlot
  INC B
  LD A,(StarsMask2+$0001)
  LD HL,StarsLayer2
  CALL StarsPlot
  INC B
  LD A,(StarsMask3+$0001)
  LD HL,StarsLayer3
  CALL StarsPlot
  INC B
  LD A,(StarsMask4+$0001)
  LD HL,StarsLayer4
  CALL StarsPlot
  RET

; move the four layers: 1, 2, 4 and 8 pixels right a frame
;
; Each layer keeps its one-pixel mask in the operand of its LD A: rotated right
; 1 (layer 1), 2 (layer 2) or 4 (layer 3) bits a frame; when the pixel wraps
; from bit 0 to bit 7 (the carry), StarsStep moves the layer's stars one byte
; right. Layer 4's mask stays $80 and its stars step every frame. Layer 3's
; mask is stored twice (the second store after StarsStep is harmless: A is
; unchanged).
StarsMove:
  LD A,$80                ; layer 1's mask (the operand: StarsMove+1)
  OR A
  RRCA
  LD (StarsMove+$0001),A
  LD HL,StarsLayer1
  CALL C,StarsStep
StarsMask2:
  LD A,$80                ; layer 2's mask
  OR A
  RRCA
  RRCA
  LD (StarsMask2+$0001),A
  LD HL,StarsLayer2
  CALL C,StarsStep
StarsMask3:
  LD A,$80                ; layer 3's mask
  OR A
  RRCA
  RRCA
  RRCA
  RRCA
  LD (StarsMask3+$0001),A
  LD HL,StarsLayer3
  CALL C,StarsStep
  LD (StarsMask3+$0001),A
StarsMask4:
  LD A,$80                ; layer 4's mask: always $80
  LD HL,StarsLayer4
  CALL StarsStep
  RET

; move the 30 stars at HL one byte right
;
; INC of the low byte of each of the 30 addresses (HL steps over the high
; bytes). Saves SP like the others, so it can end through StarsRet.
StarsStep:
  LD B,$01
  LD (StarsRet+$0001),SP
StarsStepLoop:
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  INC (HL)
  INC HL
  INC HL
  DEC B
  JP NZ,StarsStepLoop

; restore SP and return
;
; The routines that borrow SP (StarsSave, StarsRestore, StarsStep, StarsPlot)
; store SP into this LD SP's operand first and jump here at the end.
StarsRet:
  LD SP,$0000             ; the operand: SP as it was
  RET

; OR the mask A into the 30 screen bytes whose addresses are at HL
;
; In: A the mask, HL one layer's table. Keeps the mask in StarMask (A is needed
; for the OR).
StarsPlot:
  LD (StarsRet+$0001),SP
  LD B,$01
  LD SP,HL
  LD (StarMask),A
StarsPlotLoop:
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  POP HL
  LD A,(StarMask)
  OR (HL)
  LD (HL),A
  DEC B
  JP NZ,StarsPlotLoop
  JP StarsRet

; StarsPlot's mask while it draws a layer
StarMask:
  DEFB $00

; layer 1 (1 pixel a frame): the screen addresses of its 30 stars
StarsLayer1:
  DEFW $462D,$4996,$40DD,$4169,$402C,$4842
  DEFW $4B52,$47B4,$4331,$41AE,$5481,$4701
  DEFW $5700,$48C4,$5752,$57DE,$5748,$57F6
  DEFW $44D1,$5798,$4E3B,$57B2,$5781,$47EE
  DEFW $4F39,$4EE0,$57D8,$5686,$480A,$4211

; layer 2 (2 pixels a frame)
StarsLayer2:
  DEFW $4458,$4C7B,$57D9,$461A,$4E72,$40B6
  DEFW $57E9,$5069,$57CB,$45C6,$4AAD,$575F
  DEFW $562B,$57E2,$5201,$4AAA,$4600,$4FBC
  DEFW $428F,$55E2,$48BF,$415D,$4178,$42E4
  DEFW $4B7F,$51CA,$54B5,$572F,$426E,$4F7D

; layer 3 (4 pixels a frame)
StarsLayer3:
  DEFW $4450,$57F4,$494B,$54E9,$5790,$4C15
  DEFW $47CC,$5460,$412F,$572B,$4F6B,$4720
  DEFW $5319,$42B8,$544C,$568F,$4C36,$5768
  DEFW $57D2,$40EA,$57AE,$4A42,$4E74,$4034
  DEFW $4246,$4B04,$55CA,$494F,$419A,$43A1

; layer 4 (8 pixels a frame)
StarsLayer4:
  DEFW $5773,$4E09,$575C,$4E7E,$572A,$4D4D
  DEFW $5484,$4E30,$4171,$5581,$4A33,$457D
  DEFW $4298,$5150,$5371,$498E,$565E,$4A7B
  DEFW $5741,$46E1,$4210,$4C58,$54EA,$4122
  DEFW $5153,$4EEC,$4929,$43D2,$579C,$5754

; the 120 screen bytes under the stars (StarsSave / StarsRestore), 0 in the
; image
StarsSaved:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
