; --------------------------------------------------------------------------------------------------------------------
; render.asm: Drawing: the fades, the screen copies, the play area's colours
;
; Stage 5 draws straight to the screen: the hero (DrawHero), its shots (DrawShots), the stars (DrawStar), Dameron's
; three parts (DrawDameronFace, DrawDameronDome, DrawDameronBack) and his missiles are copied to the screen with no
; mask, each picture carrying blank edges that wipe its trail. The play area's colours are one colour a pass
; (ColourPlayArea, from the cycle CycleColour $A021). The play buffer $5B00-$6CFF holds the two text pages.
;
; Stage 5 draws the duel straight to the screen: the shots, explosions and the hero's other frames come from one
; sprite bank at SpriteBank $B3BA (SpriteFrameAddress), the screen lines from tables (the resident ScreenLineTable
; $FB00 and two copies in the block, StageScreenLines and PlayLineTable). Stage 1's play-buffer sprite routines
; (DrawSprite and the others) are still in the block with no caller.
; --------------------------------------------------------------------------------------------------------------------

  ORG $793C

; Fade every coloured ink up to white over 7 frames, then down to black over 7
; frames
;
; As in stage 1 at $7925, the same code. Seven times (HALT each): every
; attribute whose ink is neither 0 nor 7 gets ink + 1. Then seven times (two
; HALTs each): every ink not 0 gets ink - 1. Inputs: none; changes the
; attributes $5800-$5AFF. Called by EndStage.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
FlashFadeScreen:
  LD B,$07
FadeUpFrame:
  PUSH BC
  HALT
  LD HL,Attributes
  LD BC,$0300
FadeUpCell:
  LD A,(HL)
  AND $07
  JP Z,FadeUpNext
  CP $07
  JP Z,FadeUpNext
  INC (HL)
FadeUpNext:
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,FadeUpCell
  POP BC
  DJNZ FadeUpFrame
  LD B,$07
FadeDownFrame:
  PUSH BC
  HALT
  HALT
  LD HL,Attributes
  LD BC,$0300
FadeDownCell:
  LD A,(HL)
  AND $07
  JP Z,FadeDownNext
  DEC (HL)
FadeDownNext:
  INC HL
  DEC BC
  LD A,B
  OR C
  JP NZ,FadeDownCell
  POP BC
  DJNZ FadeDownFrame
  RET

; Copy a block of bytes to the screen, line by line
;
; As in stage 1 at $79CC, the same code. Inputs: HL = the source, B = the
; screen column, C = the first pixel line, D = the width in bytes, E = the
; lines, A = the source's stride (added to HL after each line; 0 repeats one
; source line, used with the cleared buffer to clear a screen block). Patches
; the column into $7992 and the stride into $79A3, then for each line takes the
; line's address from ScreenLineTable and LDIRs D bytes. Destroys IX, BC, DE.
;
; Callers: EndStage, ShowScore, ShowItemCount, GameOverStep and RevealScore
; $967E (the score revealed at the start).
;
; Witness: L1 48 (ending, rzx-r5, s5-right).
CopyToScreen:
  LD (CopyToScreenLine+$0017),A
  LD A,B
  LD (CopyToScreenLine+$0006),A
  LD B,$00
  LD IX,ScreenLineTable
  ADD IX,BC
  ADD IX,BC
  LD B,E
  LD C,D
CopyToScreenLine:
  PUSH BC
  PUSH HL
  LD A,(IX+$00)
  ADD A,$00
  LD E,A
  LD D,(IX+$01)
  INC IX
  INC IX
  LD B,$00
  LDIR
  POP HL
  LD B,$00
  LD C,$00
  ADD HL,BC
  POP BC
  DJNZ CopyToScreenLine
  RET

  ORG $7A72

; Colour the whole play area (rows 6-23, columns 2-29) with this pass's cycle
; colour, then DuelHit
;
; A = CycleColour $A021 (the colour cycle by PassCounter AND 7: bright yellow,
; cyan, green, magenta, red, magenta, green, cyan, the bytes at CycleColours
; $A02F); fills 18 rows of 28 cells from $58C2, unrolled. Then JP DuelHit,
; which may paint Dameron's cells blue or flash the text over it. Every pass:
; the stars, the hero, the shots and Dameron all take the one colour.
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
ColourPlayArea:
  CALL CycleColour
  LD HL,Attributes+194
  LD B,$12
  LD DE,$0004
ColourPlayAreaRow:
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  LD (HL),A
  INC L
  ADD HL,DE
  DJNZ ColourPlayAreaRow
  JP DuelHit

  ORG $9378

; DE = $B3BA + SpriteFrameOffsets[A]: the bytes of sprite frame A
;
; Input: A = the frame 0-23. Output: DE = the frame's first byte. Preserves BC
; and HL. Callers: the straight shots $80B3 (frame PassCounter AND 3), the
; explosions $81ED (frames 19-23), $8383, DrawHeroFrame $9D8F (frames 12-23)
; and MoveCurvedShot $9E42 (frames 4-7).
;
; Witness: L1 13871 (ending, rzx-r5, s5-right).
SpriteFrameAddress:
  PUSH HL
  PUSH BC
  SLA A
  LD C,A
  LD B,$00
  LD HL,SpriteFrameOffsets
  ADD HL,BC
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD HL,SpriteBank
  ADD HL,BC
  EX DE,HL
  POP BC
  POP HL
  RET

; The offset of each of the 24 sprite frames in the bank $B3BA
;
; 0, $30 ... $150 (frames 0-7, 48 bytes each: 3 bytes x 16 lines), $180, $19B,
; $1B6, $1D1 (frame 8 27 bytes after frame 7's 48; frames 8-11 27 bytes: 3 x
; 9), $1EC, $234 (frames 12-13, 72 bytes: 3 x 24), $27C (frame 14, 144 bytes to
; the next), $30C, $354 ... $54C (frames 15-23, 72 bytes apart). Read by
; SpriteFrameAddress ($937F).
SpriteFrameOffsets:
  INCBIN "res/stage5/table-frame-offsets.bin",$0000,48

  ORG $94D0

; IY = the screen address of pixel line C (no caller)
;
; IY = ScreenLineTable $FB00 + 2C (the word's address, not the word read). No
; CALL, JP or word in the block names $94D0 (work/stage2/stage5/B-raw.py). As
; in stage 1 at $8BC3, the same code.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
LineAddressToIY:
  LD DE,ScreenLineTable
  LD L,C
  LD H,$00
  ADD HL,HL
  ADD HL,DE
  PUSH HL
  POP IY
  RET

; HL = DE + (C / 8) x 32 + B: the cell of pixel line C, column B in a 32-wide
; map
;
; DE = the map (Attributes or the shadow ShadowAttributes $6D00). Used by
; FillAttributes and FillShadowAttributes. As in stage 1 at $8BCF, the same
; code.
;
; Witness: L1 27 (ending, rzx-r5, s5-right).
CellAddress:
  SRL C
  SRL C
  SRL C
  LD H,$00
  LD L,C
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,DE
  LD E,B
  LD D,$00
  ADD HL,DE
  RET

  ORG $954E

; Fill a rectangle of the screen's attributes (5 bytes after the CALL)
;
; The 5 bytes after the CALL: the column, the pixel line (/8 = the cell row),
; the width, the height in cells, the attribute. Returns after them (POP IX, IX
; + 5, PUSH IX). Called from $78B9, EndStageLives $78C1, $7C24 and $7ED1. As
; stage 1's FillAttributes $8C3D.
;
; Witness: L1 15 (ending, rzx-r5, s5-right).
FillAttributes:
  POP IX
  LD BC,$0005
  ADD IX,BC
  PUSH IX
  LD B,(IX-$05)
  LD C,(IX-$04)
  LD D,(IX-$03)
  LD E,(IX-$02)
  LD A,(IX-$01)
  PUSH DE
  LD DE,Attributes
  CALL CellAddress
  POP BC
  LD DE,$0020
FillAttributesRow:
  PUSH BC
  PUSH HL
FillAttributesCell:
  LD (HL),A
  INC HL
  DJNZ FillAttributesCell
  POP HL
  ADD HL,DE
  POP BC
  DEC C
  JP NZ,FillAttributesRow
  RET

; Fill a rectangle of the shadow attributes $6D00 (5 bytes after the CALL)
;
; As FillAttributes into the shadow; StageSetUp paints the HUD's boxes with it
; (HudBox1-HudBox4). As stage 1's FillShadowAttributes $8C6D.
;
; Witness: L1 12 (ending, rzx-r5, s5-right).
FillShadowAttributes:
  POP IX
  LD BC,$0005
  ADD IX,BC
  PUSH IX
  LD B,(IX-$05)
  LD C,(IX-$04)
  LD D,(IX-$03)
  LD E,(IX-$02)
  LD A,(IX-$01)
  PUSH DE
  LD DE,ShadowAttributes
  CALL CellAddress
  POP BC
  LD DE,$0020
FillShadowRow:
  PUSH BC
  PUSH HL
FillShadowCell:
  LD (HL),A
  INC HL
  DJNZ FillShadowCell
  POP HL
  ADD HL,DE
  POP BC
  DEC C
  JP NZ,FillShadowRow
  RET

; Copy the whole shadow $6D00-$6FFF to the attributes after a HALT
;
; Called twice by StageSetUp. As in stage 1 at $8C9D, the same code.
;
; Witness: L1 6 (ending, rzx-r5, s5-right).
ShowShadowAttributes:
  LD HL,ShadowAttributes
  LD DE,Attributes
  LD BC,$0300
  HALT
  LDIR
  RET

  ORG $96AC

; Clear the play buffer $5B00-$6CFF with PUSH HL (DI)
;
; SP = ShadowAttributes $6D00, 144 x 16 PUSHes of 0 (4608 bytes); SP saved in
; SavedSP $FE0E. Interrupts off meanwhile (DI ... EI). Called from $78B6. As in
; stage 1 at $9AB5, the same code.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
ClearBuffer:
  DI
  LD (SavedSP),SP
  LD HL,$0000
  LD SP,ShadowAttributes
  LD B,$90
ClearBufferLoop:
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  PUSH HL
  DJNZ ClearBufferLoop
  LD SP,(SavedSP)
  EI
  RET

; Copy the screen's attributes to the shadow at $6D00
;
; Called by StageSetUp. As in stage 1 at $B17F, the same code.
;
; Witness: L1 3 (ending, rzx-r5, s5-right).
SaveAttributes:
  LD HL,Attributes
  LD DE,ShadowAttributes
  LD BC,$0300
  LDIR
  RET

  ORG $9736

; Fill the attributes of screen rows 6-23 with 0 (black on black)
;
; As in stage 1 at $A057, the same code. No caller in stage 5's code (no CALL,
; JP or word names $9736: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
BlackOutPlayArea:
  LD HL,Attributes+192
  LD DE,Attributes+193
  LD BC,$023F
  LD (HL),$00
  LDIR
  RET

  ORG $97A5

; The screen address of each of the 192 pixel lines (a copy of the resident
; ScreenLineTable $FB00)
;
; Words Screen $4000, $4100 ... $57E0. Read from line 48 on (ScreenLinePlay) by
; $8838 (Dameron's head) and MoveCurvedShot $9E1E: a play-area line Y is
; ScreenLinePlay + 2Y. s5-right read none of its bytes through LD (the head
; walks it with POP, which the recordings do not count as reads); rzx-r5 and
; ending read 284 of them (MoveCurvedShot).
StageScreenLines:
  DEFW $4000,$4100,$4200,$4300,$4400,$4500,$4600,$4700
  DEFW $4020,$4120,$4220,$4320,$4420,$4520,$4620,$4720
  DEFW $4040,$4140,$4240,$4340,$4440,$4540,$4640,$4740
  DEFW $4060,$4160,$4260,$4360,$4460,$4560,$4660,$4760
  DEFW $4080,$4180,$4280,$4380,$4480,$4580,$4680,$4780
  DEFW $40A0,$41A0,$42A0,$43A0,$44A0,$45A0,$46A0,$47A0
ScreenLinePlay:
  DEFW $40C0,$41C0,$42C0,$43C0,$44C0,$45C0,$46C0,$47C0 ; line 48: the play
  DEFW $40E0,$41E0,$42E0,$43E0,$44E0,$45E0,$46E0,$47E0 ; area's top line
  DEFW $4800,$4900,$4A00,$4B00,$4C00,$4D00,$4E00,$4F00
  DEFW $4820,$4920,$4A20,$4B20,$4C20,$4D20,$4E20,$4F20
  DEFW $4840,$4940,$4A40,$4B40,$4C40,$4D40,$4E40,$4F40
  DEFW $4860,$4960,$4A60,$4B60,$4C60,$4D60,$4E60,$4F60
  DEFW $4880,$4980,$4A80,$4B80,$4C80,$4D80,$4E80,$4F80
  DEFW $48A0,$49A0,$4AA0,$4BA0,$4CA0,$4DA0,$4EA0,$4FA0
  DEFW $48C0,$49C0,$4AC0,$4BC0,$4CC0,$4DC0,$4EC0,$4FC0
  DEFW $48E0,$49E0,$4AE0,$4BE0,$4CE0,$4DE0,$4EE0,$4FE0
  DEFW $5000,$5100,$5200,$5300,$5400,$5500,$5600,$5700
  DEFW $5020,$5120,$5220,$5320,$5420,$5520,$5620,$5720
  DEFW $5040,$5140,$5240,$5340,$5440,$5540,$5640,$5740
  DEFW $5060,$5160,$5260,$5360,$5460,$5560,$5660,$5760
  DEFW $5080,$5180,$5280,$5380,$5480,$5580,$5680,$5780
  DEFW $50A0,$51A0,$52A0,$53A0,$54A0,$55A0,$56A0,$57A0
  DEFW $50C0,$51C0,$52C0,$53C0,$54C0,$55C0,$56C0,$57C0
  DEFW $50E0,$51E0,$52E0,$53E0,$54E0,$55E0,$56E0,$57E0

; 96 zero bytes: a blank text page, copied by ClearTextArea over the seven text
; lines
;
; Read by ClearTextArea ($8D49 ... $8D7F, seven times 96 bytes) when the intro
; ends.
BlankTextLine:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; 272 zero bytes after BlankTextLine: no code reads them
;
; No operand names $9985-$9A94 and no recording (s5-right, rzx-r5, ending) read
; any of them.
UnusedZeros1:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The screen address of each pixel line, 0 for the HUD's lines 0-47
;
; 192 words: 48 zeros (lines 0-47), then $40C0 ... $57E0 (lines 48-191). Read
; by UpdateBurst ($914B) and EraseParticle ($9355) at the word of line row x 8:
; a particle in the HUD rows gets address 0 + X and writes into the ROM.
PlayLineTable:
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
  DEFW $0000,$0000,$0000,$0000,$0000,$0000,$0000,$0000
PlayLineTablePlay:
  DEFW $40C0,$41C0,$42C0,$43C0,$44C0,$45C0,$46C0,$47C0 ; line 48
  DEFW $40E0,$41E0,$42E0,$43E0,$44E0,$45E0,$46E0,$47E0
  DEFW $4800,$4900,$4A00,$4B00,$4C00,$4D00,$4E00,$4F00
  DEFW $4820,$4920,$4A20,$4B20,$4C20,$4D20,$4E20,$4F20
  DEFW $4840,$4940,$4A40,$4B40,$4C40,$4D40,$4E40,$4F40
  DEFW $4860,$4960,$4A60,$4B60,$4C60,$4D60,$4E60,$4F60
  DEFW $4880,$4980,$4A80,$4B80,$4C80,$4D80,$4E80,$4F80
  DEFW $48A0,$49A0,$4AA0,$4BA0,$4CA0,$4DA0,$4EA0,$4FA0
  DEFW $48C0,$49C0,$4AC0,$4BC0,$4CC0,$4DC0,$4EC0,$4FC0
  DEFW $48E0,$49E0,$4AE0,$4BE0,$4CE0,$4DE0,$4EE0,$4FE0
  DEFW $5000,$5100,$5200,$5300,$5400,$5500,$5600,$5700
  DEFW $5020,$5120,$5220,$5320,$5420,$5520,$5620,$5720
  DEFW $5040,$5140,$5240,$5340,$5440,$5540,$5640,$5740
  DEFW $5060,$5160,$5260,$5360,$5460,$5560,$5660,$5760
  DEFW $5080,$5180,$5280,$5380,$5480,$5580,$5680,$5780
  DEFW $50A0,$51A0,$52A0,$53A0,$54A0,$55A0,$56A0,$57A0
  DEFW $50C0,$51C0,$52C0,$53C0,$54C0,$55C0,$56C0,$57C0
  DEFW $50E0,$51E0,$52E0,$53E0,$54E0,$55E0,$56E0,$57E0

; 368 zero bytes after PlayLineTable: only the burst's overrun reads four of
; them
;
; No operand names $9C15-$9D84. rzx-r5 and ending read $9C15/$9C16 and
; $9C25/$9C26: UpdateBurst and EraseParticle look up the word of line row x 8
; past the table's end for particles below the screen. The rest no code reads.
UnusedZeros2:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  ORG $9FE9

; HL = the play-buffer address of the actor IY ($5B00 + line x 32 + column); DE
; = HL in
;
; Called by DrawSprite and DrawSpriteMirrored. As in stage 1 at $B332, the same
; code.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
BufferAddressHL:
  PUSH HL
  LD L,(IY+$01)
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
  LD BC,PlayBuffer
  ADD HL,BC
  POP DE
  RET

; HL = the attribute-shadow address of the actor IY ($6DC0 + line / 8 x 32 +
; column)
;
; Called by ColourSprite and ColourSpriteMirrored. As in stage 1 at $B349, the
; same code.
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
AttrShadowAddress:
  LD A,(IY+$01)
  AND $F8
AttrShadowAddressA:
  LD L,A                  ; entry with A = the line rounded down to 8
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  LD C,(IY+$00)
  LD B,$00
  ADD HL,BC
  LD BC,PlayAttributes
  ADD HL,BC
  RET

  ORG $A01A

; The actor IY's colour +$0C = CycleColour
;
; As in stage 1 at $B3BD, the same code. No caller in stage 5's code (no CALL,
; JP or word names $A01A: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
SetCycleColour:
  CALL CycleColour
  LD (IY+$0C),A
  RET

; A = CycleColours[PassCounter AND 7]
;
; Called from ColourPlayArea $7A72 and GameOverColour $7ECB. As in stage 1 at
; $B3C4, the same code (its table holds other colours).
;
; Witness: L1 11696 (ending, rzx-r5, s5-right).
CycleColour:
  LD A,(PassCounter)
  AND $07
  LD C,A
  LD B,$00
  LD HL,CycleColours
  ADD HL,BC
  LD A,(HL)
  RET

; The colour cycle: bright yellow, cyan, green, magenta, red, magenta, green,
; cyan
;
; $46, $45, $44, $43, $42, $43, $44, $45 (bright ink on black). Read by
; CycleColour ($A029).
CycleColours:
  DEFB $46,$45,$44,$43,$42,$43,$44,$45

; Fill the attribute shadow under an image with C
;
; IY = the position, IX the image descriptor (+2 width, +3 height): (height / 8
; + 1) rows of the width. As in stage 1 at $B40A, the same code. No caller in
; stage 5's code (no CALL, JP or word names $A037:
; work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
ColourSprite:
  PUSH BC
  CALL AttrShadowAddress
  POP BC
  LD DE,$0020
  LD B,(IX+$03)
  SRL B
  SRL B
  SRL B
  INC B
ColourSpriteRow:
  PUSH BC
  PUSH HL
  LD B,(IX+$02)
ColourSpriteCell:
  LD (HL),C
  INC L
  DJNZ ColourSpriteCell
  POP HL
  ADD HL,DE
  POP BC
  DJNZ ColourSpriteRow
  RET

; Copy an image to the play buffer at the actor's position (no mask)
;
; HL = the image, IX the descriptor (+2 width in bytes, +3 height in lines), IY
; the position (BufferAddressHL). As in stage 1 at $B42B, the same code. No
; caller in stage 5's code (no CALL, JP or word names $A058:
; work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
DrawSprite:
  CALL BufferAddressHL
  EX DE,HL
  LD B,(IX+$03)
DrawSpriteRow:
  PUSH BC
  PUSH DE
  LD C,(IX+$02)
  LD B,$00
  LDIR
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DrawSpriteRow
  RET

; Copy an image mirrored left to right (through the bit-reverse table $FA00)
;
; As DrawSprite, each row written from right to left and each byte reversed by
; BitReverse $FA00. As in stage 1 at $B446, the same code. No caller in stage
; 5's code (no CALL, JP or word names $A073: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
DrawSpriteMirrored:
  CALL BufferAddressHL
  EX DE,HL
  LD B,(IX+$03)
DrawSpriteMirroredRow:
  PUSH BC
  PUSH DE
  LD A,E
  ADD A,(IX+$02)
  DEC A
  LD E,A
  LD B,(IX+$02)
DrawSpriteMirroredByte:
  PUSH BC
  LD B,$FA
  LD A,(HL)
  LD C,A
  LD A,(BC)
  LD (DE),A
  DEC DE
  INC HL
  POP BC
  DJNZ DrawSpriteMirroredByte
  POP DE
  EX DE,HL
  LD BC,$0020
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ DrawSpriteMirroredRow
  RET

; ColourSprite for a mirrored image (filled leftwards from its right edge)
;
; As in stage 1 at $B46F, the same code. No caller in stage 5's code (no CALL,
; JP or word names $A09C: work/stage2/stage5/B-raw.py).
;
; Not executed in any recording (the recordings checked: s5-right, rzx-r5,
; ending); known only from the code.
ColourSpriteMirrored:
  PUSH BC
  CALL AttrShadowAddress
  LD C,(IX+$02)
  LD B,$00
  DEC HL
  ADD HL,BC
  POP BC
  LD DE,$0020
  LD B,(IX+$03)
  SRL B
  SRL B
  SRL B
  INC B
ColourSpriteMirroredRow:
  PUSH BC
  PUSH HL
  LD B,(IX+$02)
ColourSpriteMirroredCell:
  LD (HL),C
  DEC L
  DJNZ ColourSpriteMirroredCell
  POP HL
  ADD HL,DE
  POP BC
  DJNZ ColourSpriteMirroredRow
  RET
