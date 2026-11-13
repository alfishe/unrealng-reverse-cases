; --------------------------------------------------------------------------------------------------------------------
; logo.asm: The logo over a starfield, the box's shimmer and colours, the box wiped by dissolving
;
; ShowLogo $785A puts LogoScreen $79DB on the screen: the attributes made black first, the 6144 bitmap bytes, 20
; frames, then the 768 attribute bytes. The starfield is part of the picture (blue dots in its bitmap): no code moves
; it. LogoWaitSpace $7942 then runs two effects every two frames until SPACE: ShimmerFrame $79AE rolls the yellow and
; bright yellow streaks of ShimmerColours $78E2 over the logo box's attributes (rows 7-16, columns 6-25), and the
; box's inside is painted back over it (rows 14 and 15 there; PaintBoxColours $7971 later: rows 8-15, columns 7-24,
; red with magenta on rows 9, 11, 13, 15), so only the frame of the box shimmers. On SPACE, DissolveLogoBox $7889
; wipes the inside of the box (pixel lines 64-127, columns 7-24) in 8 dissolve steps; the credits and the menu are
; then printed into that space.
;
; Every later wait of the front (WaitOrSpace $9BA5, the highlight loops, ScanKeyboard, RevealStrip $9E4D) calls
; ShimmerFrame and PaintBoxColours every two frames too, so the frame shimmers through the credits and the menu.
; --------------------------------------------------------------------------------------------------------------------

; Black attributes, the logo's bitmap, 20 frames, its attributes; then wait for
; SPACE and wipe the box
;
; Attributes $5800-$5AFF := 0 (LDIR), LogoScreen's 6144 bitmap bytes to Screen
; $4000, WaitFrames $9BBF with BC = 20, then the 768 attribute bytes after them
; (LogoAttributes $91DB) to $5800: the picture appears at once, 20 frames after
; the bitmap was drawn invisibly. Then LogoWaitSpace $7942 and DissolveLogoBox
; $7889.
;
; c1: run once; the bitmap copy at frame 7828, the wait 7828-7848 ($9BBF ran 20
; times), the attributes at 7848 (the front's bytes: the LDIRs at $7865, $7870,
; $7880 ran 767, 6144 and 768 times).
;
; Witness: L1 2 (c1, rzx-r0).
ShowLogo:
  LD HL,Attributes
  LD DE,Attributes+1
  LD BC,$02FF
  LD (HL),$00
  LDIR
  LD HL,LogoScreen
  LD DE,Screen
  LD BC,$1800
  LDIR
ShowLogoWait:
  PUSH HL                 ; HL = LogoAttributes: kept over the wait
  LD BC,$0014
  CALL WaitFrames
  POP HL
  LD DE,Attributes
  LD BC,$0300
  LDIR
  CALL LogoWaitSpace
  CALL DissolveLogoBox
  RET

; Wipe pixel lines 64-127, columns 7-24 to paper in 8 dissolve steps, the masks
; picked by ROM bytes
;
; For step 0-7: the ADD A,n at $78C4 gets $CB + step; for each of the 64 lines
; from ScreenLineTable+128 ($FB80, line 64; DissolveLinePtr $9718 walks it) and
; each of its 18 bytes from column 7: BC = PixelShift's word + 1 (stored back),
; A = (BC) AND $18, mask = the byte at $F900 + A + $CB + step (the resident's
; dissolve masks $F9CB-$F9EA: four sets of 8, each set ending in $FF), screen
; byte := screen AND NOT mask. The word starts at 0, so the bytes that pick the
; mask set are the ROM's from $0001 up: a fixed pseudo-random pattern. After
; step 7 every mask is $FF and the 64 x 18 bytes are 0. No HALT: the 8 steps
; run back to back.
;
; c1 (the front's bytes): $7891 8 runs, $78A7 512, $78B7 9216 (8 x 64 x 18),
; right after SPACE at frame 7938.
;
; Witness: L1 2 (c1, rzx-r0).
DissolveLogoBox:
  LD HL,ScreenLineTable+128
  LD (DissolveLinePtr),HL
  LD B,$08
DissolveStep:
  PUSH BC                 ; one step: the mask offset $CB + step into the ADD
                          ; below
  LD A,$08
  SUB B
  ADD A,$CB
  LD (DissolveMaskOffset+$0001),A
  LD IY,(DissolveLinePtr)
  LD BC,$0000
  LD (PixelShift),BC
  LD B,$40
DissolveLine:
  PUSH BC                 ; one line: its screen address + 7 from the table
  LD A,(IY+$00)
  ADD A,$07
  LD L,A
  LD H,(IY+$01)
  INC IY
  INC IY
  LD B,$12
DissolveByte:
  PUSH BC                 ; one byte: the next ROM byte picks one of four masks
  LD BC,(PixelShift)
  INC BC
  LD (PixelShift),BC
  LD A,(BC)
  AND $18
DissolveMaskOffset:
  ADD A,$00               ; ADD A,n: n patched to $CB + step at $7897
  LD C,A
  LD B,$F9
  LD A,(BC)
  LD B,A
  LD A,$00
  AND B
  LD C,A
  LD A,B
  XOR $FF
  LD B,A
  LD A,(HL)
  AND B
  OR C
  LD (HL),A
  INC HL
  POP BC
  DJNZ DissolveByte
  POP BC
  DJNZ DissolveLine
  POP BC
  DJNZ DissolveStep
DissolveDone:
  RET                     ; after 8 steps

; The frame shimmer's attributes: a 32-byte pattern of yellow ($06) and bright
; yellow ($46), three times
;
; ShimmerFrame $79AE copies 20 bytes from ShimmerColours + phase + row to each
; of the 10 attribute rows 7-16 (columns 6-25), phase 0-31, so it reads
; $78E2-$791D (the menu recording reads exactly these 60 bytes). The last 36
; bytes ($791E-$7941) repeat the pattern and are never read (menu; known only
; from the code: the largest offset is 31 + 9 + 19 = 59).
ShimmerColours:
  INCBIN "res/front/shimmer.bin",$0000,96

; Shimmer the logo's frame every two frames until SPACE
;
; ShimmerCount $FE1D := 0, then: HALT, HALT, ShimmerFrame $79AE, the attribute
; rows 14 and 15 from column 7 (at $59C7 and $59E7, 18 bytes each) := $42 and
; 3, read port $7FFE bit 0 (SPACE); loop while it is up. Rows 8-13 of the box's
; inside keep the logo's own attributes.
;
; c1: from frame 7848 to SPACE seen at 7938: 45 passes of two frames ($7947 ran
; 45 times).
;
; Witness: L1 2 (c1, rzx-r0).
LogoWaitSpace:
  LD A,$00
  LD (ShimmerCount),A
LogoWaitLoop:
  HALT                    ; two frames, the shimmer, then SPACE?
  HALT
  CALL ShimmerFrame
  LD HL,Attributes+455
  LD DE,Attributes+456
  LD BC,$0011
  LD (HL),$42
  LDIR
  LD HL,Attributes+487
  LD DE,Attributes+488
  LD BC,$0011
  LD (HL),$03
  LDIR
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  JP NZ,LogoWaitLoop
  RET

; The box's inside: rows 8-15, columns 7-24 red ($42), then rows 9, 11, 13, 15
; magenta (3)
;
; FillAttrBox $9D31 (column 7, row 8, 18 x 8 cells, $42: bright red on black),
; then 17 bytes of 3 (magenta) on the attribute rows 9, 11, 13 and 15 from
; column 7. A printed text line (7 pixel lines from line 68, 84, 100 or 116)
; spans two attribute rows: its top half is red, its bottom half magenta. It
; also undoes the menu highlight bar of the last pass. Called every two frames
; by every wait after the logo.
;
; c1 (the front's bytes): 293 runs of its LDIRs, frames 7968-8554; menu: 775
; runs.
;
; Witness: L1 2921 (c1, joystick, menu, rzx-r0).
PaintBoxColours:
  CALL FillAttrBox
  DEFB $07,$08,$12,$08,$42
  LD HL,Attributes+295
  LD DE,Attributes+296
  LD BC,$0010
  LD (HL),$03
  LDIR
  LD HL,Attributes+359
  LD DE,Attributes+360
  LD BC,$0010
  LD (HL),$03
  LDIR
  LD HL,Attributes+423
  LD DE,Attributes+424
  LD BC,$0010
  LD (HL),$03
  LDIR
  LD HL,Attributes+487
  LD DE,Attributes+488
  LD BC,$0010
  LD (HL),$03
  LDIR
  RET

; Count ShimmerCount down and copy the shimmer pattern at its phase over the
; box's 10 x 20 attributes
;
; ShimmerCount $FE1D - 1; phase = (ShimmerCount >> 1) AND 31; for row 0-9: 20
; bytes from ShimmerColours $78E2 + phase + row to the attributes at $58E6 + 32
; x row (row 7, column 6 down). The phase moves every second call and the
; pattern repeats every 32 bytes, so at the usual two frames a call the streaks
; slide one cell every 4 frames and come round every 128 frames.
;
; menu: 775 runs; c1 (the front's bytes): 338 runs of its body.
;
; Witness: L1 3120 (c1, joystick, menu, rzx-r0).
ShimmerFrame:
  LD A,(ShimmerCount)
  DEC A
  LD (ShimmerCount),A
  LD A,(ShimmerCount)
  SRL A
  AND $1F
  LD C,A
  LD B,$00
  LD HL,ShimmerColours
  ADD HL,BC
  LD B,$0A
  LD DE,Attributes+230
ShimmerRow:
  PUSH BC                 ; 20 bytes, then the next attribute row and the next
                          ; pattern byte
  PUSH HL
  LD BC,$0014
  LDIR
  LD BC,$000C
  EX DE,HL
  ADD HL,BC
  EX DE,HL
  POP HL
  INC HL
  POP BC
  DJNZ ShimmerRow
  RET

; The logo screen: the MYTH logo in its box, HISTORY IN THE MAKING, over a
; starfield (6144 bitmap bytes, 768 attributes)
;
; Copied to the screen by ShowLogo $785A (c1 frame 7828; the attributes at
; 7848). The box is 20 x 10 cells (columns 6-25, rows 7-16); its inside (pixel
; lines 64-127, columns 7-24) is wiped by DissolveLogoBox $7889 and reused for
; the credits and the menu. The blue dots of the starfield are drawn in the
; bitmap: nothing animates them.
LogoScreen:
  INCBIN "res/front/logo.bin",$0000,6144
LogoAttributes:
  INCBIN "res/front/logo.bin",$1800,768

  ORG $9718

; DissolveLogoBox's pointer into ScreenLineTable (the next line's entry)
;
; Written at $788C (ScreenLineTable+128) and read and stepped by
; DissolveLogoBox $7889 for each of its 64 lines (c1, the front's bytes: $789A
; 8 runs). Zero on the tape.
DissolveLinePtr:
  DEFW $0000
