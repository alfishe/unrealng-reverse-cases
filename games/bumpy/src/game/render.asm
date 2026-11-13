; --------------------------------------------------------------------------------------------------------------------
; render.asm: The screen: attributes, the side panels, the play area and the CPC-to-Spectrum line table
;
; The game draws with Amstrad CPC screen addresses ($C000 + line AND 7 x $800 + row x 80 + byte). LineAddress $B515
; turns the line and column ScreenAddrToLine $C71F found into a Spectrum address: SpectrumLines $B52D gives the
; Spectrum line of each of the 200 CPC lines (the first 7 and the last 8 go to a scratch area at $FCE0, off the
; Spectrum screen), $B52C the Spectrum byte column (the CPC byte column / 2).
;
; The platform-change animations (a platform worn by the ball: 2, then 3, then 4, then gone), the spring and tilt of
; the platforms, the crumbling bricks, the flames and the water that puts them out, the opening locks and the turning
; walls. Each is a little machine stepped once a frame by MainLoop: an active flag, a step number and a table of step
; routines; most steps XOR the previous frame off and the next one on (DrawSpriteXor $E3EE).
;
; The game draws in Amstrad CPC screen addresses ($C000 + line in the character row x $800 + character row x 80 + byte
; column) and converts each one to a Spectrum line with ScreenAddrToLine $C71F and the line table $B52D. The pictures
; are CPC mode-1 bytes; the Spectrum shows their low nibbles (XOR $E3EE, store $E318, with ink $E3E5).
;
; The animations below are lists of routines, one a step: a player calls entry N at its N-th call and stops when an
; entry clears its active flag.
; --------------------------------------------------------------------------------------------------------------------

  ORG $B471

; All attributes = A (7: white ink, black paper), the border = A >> 3 (black)
;
; Witness: L1 9 (c1, gameover, menu, twoname).
ClearAttrs:
  LD A,$07
  LD HL,$5800
  LD DE,$5801
  LD BC,$02FF
  LD (HL),A
  LDIR
  SRL A
  SRL A
  SRL A
  OUT ($FE),A
  RET

; Draws the side panels: $6398 at the CPC address $F800 and $6518 at $F83C, 192
; lines each ($E318)
;
; Witness: L1 9 (c1, gameover, menu, twoname).
DrawSides:
  LD HL,SidePanels
  LD DE,$F800
  LD A,$02
  LD (SpriteWidth),A
  LD B,$C0
  LD C,$7C
  CALL DrawSprite
  LD HL,SidePanelRight
  LD DE,$F83C
  LD B,$C0
  LD C,$3E
  CALL DrawSprite
  RET

; Stores C into B lines of one byte column from the CPC address DE: never
; called
;
; Converts DE ($C71F, $B515) and stores C at each line's Spectrum address. No
; code calls it (known only from the code).
;
; Witness: L1 0 ().
FillColumn:
  PUSH IX
  PUSH HL
  PUSH BC
  EX DE,HL
  CALL ScreenAddrToLine
  CALL LineAddress
  POP BC
  POP HL
FillColumnLoop:
  PUSH BC
  LD E,(IX+$00)
  LD D,(IX+$01)
  LD A,(SpectrumColumn)
  OR E
  LD E,A
  LD A,C
  LD (DE),A
  INC IX
  INC IX
  POP BC
  DJNZ FillColumnLoop
  AND A
  POP IX
  RET

; Clears columns 1-29 of the 200 lines (the blank $6708), then the play
; attributes (ink 7)
;
; Witness: L1 151 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
ClearPlayArea:
  PUSH IX
  LD IX,SpectrumLines
  LD B,$C8
ClearPlayAreaLoop:
  PUSH BC                 ; one line
  LD E,(IX+$00)
  LD D,(IX+$01)
  LD A,$01
  OR E
  LD E,A
  LD HL,BlankPicture
  LD BC,$001D
  LDIR
  INC IX
  INC IX
  POP BC
  DJNZ ClearPlayAreaLoop
  POP IX
  LD A,$07
  CALL SetPlayAttrs
  RET

; Each attribute row: column 0 and 30 yellow (6), columns 1-29 = A; column 31
; untouched
;
; Witness: L1 149 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
SetPlayAttrs:
  LD HL,$5800
  LD B,$18
SetPlayAttrsLoop:
  PUSH BC                 ; one attribute row
  LD (HL),$06
  INC HL
  PUSH HL
  POP DE
  INC DE
  LD (HL),A
  LD BC,$001C
  LDIR
  INC HL
  LD (HL),$06
  LD BC,$0002
  ADD HL,BC
  POP BC
  DJNZ SetPlayAttrsLoop
  RET

; IX = SpectrumLines + 2 x the line ($C751), $B52C = the CPC column ($C750) / 2
;
; Input the line $C751 and column $C750 from ScreenAddrToLine $C71F. Output IX
; points at the Spectrum line address; the caller ORs $B52C into its low byte.
;
; Witness: L1 324616 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
LineAddress:
  LD A,(PixelLine)
  LD L,A
  LD H,$00
  ADD HL,HL
  EX DE,HL
  LD IX,SpectrumLines
  ADD IX,DE
  LD A,(ByteColumn)
  SRL A
  LD (SpectrumColumn),A
  RET

; LineAddress's Spectrum byte column (the CPC byte column / 2)
SpectrumColumn:
  DEFB $00

; The Spectrum address of the start of each CPC line 0-206: 7 lines at $FCE0,
; the 192 screen lines from $4000, 8 more at $FCE0
SpectrumLines:
  DEFW $FCE0,$FCE0,$FCE0,$FCE0,$FCE0,$FCE0,$FCE0,$4000
  DEFW $4100,$4200,$4300,$4400,$4500,$4600,$4700,$4020
  DEFW $4120,$4220,$4320,$4420,$4520,$4620,$4720,$4040
  DEFW $4140,$4240,$4340,$4440,$4540,$4640,$4740,$4060
  DEFW $4160,$4260,$4360,$4460,$4560,$4660,$4760,$4080
  DEFW $4180,$4280,$4380,$4480,$4580,$4680,$4780,$40A0
  DEFW $41A0,$42A0,$43A0,$44A0,$45A0,$46A0,$47A0,$40C0
  DEFW $41C0,$42C0,$43C0,$44C0,$45C0,$46C0,$47C0,$40E0
  DEFW $41E0,$42E0,$43E0,$44E0,$45E0,$46E0,$47E0,$4800
  DEFW $4900,$4A00,$4B00,$4C00,$4D00,$4E00,$4F00,$4820
  DEFW $4920,$4A20,$4B20,$4C20,$4D20,$4E20,$4F20,$4840
  DEFW $4940,$4A40,$4B40,$4C40,$4D40,$4E40,$4F40,$4860
  DEFW $4960,$4A60,$4B60,$4C60,$4D60,$4E60,$4F60,$4880
  DEFW $4980,$4A80,$4B80,$4C80,$4D80,$4E80,$4F80,$48A0
  DEFW $49A0,$4AA0,$4BA0,$4CA0,$4DA0,$4EA0,$4FA0,$48C0
  DEFW $49C0,$4AC0,$4BC0,$4CC0,$4DC0,$4EC0,$4FC0,$48E0
  DEFW $49E0,$4AE0,$4BE0,$4CE0,$4DE0,$4EE0,$4FE0,$5000
  DEFW $5100,$5200,$5300,$5400,$5500,$5600,$5700,$5020
  DEFW $5120,$5220,$5320,$5420,$5520,$5620,$5720,$5040
  DEFW $5140,$5240,$5340,$5440,$5540,$5640,$5740,$5060
  DEFW $5160,$5260,$5360,$5460,$5560,$5660,$5760,$5080
  DEFW $5180,$5280,$5380,$5480,$5580,$5680,$5780,$50A0
  DEFW $51A0,$52A0,$53A0,$54A0,$55A0,$56A0,$57A0,$50C0
  DEFW $51C0,$52C0,$53C0,$54C0,$55C0,$56C0,$57C0,$50E0
  DEFW $51E0,$52E0,$53E0,$54E0,$55E0,$56E0,$57E0,$FCE0
  DEFW $FCE0,$FCE0,$FCE0,$FCE0,$FCE0,$FCE0,$FCE0

  ORG $B8C2

; Write the new platform type of a platform-change animation into its cell
;
; PlatformCells $AA6B[$AB1B] = $AB20 (the cell and the new type StartWearTo3
; $C3D5, StartWearTo4 $C3F8 or StartFallAway $C41B left there). Called by the
; first or last step of each change ($C1C3, $C1FF, $C211).
;
; Witness: L1 1400 (menu, l x12, rzx x91).
SetPlatformCell:
  LD A,(CrumbleCell)
  LD D,$00
  LD E,A
  LD HL,CellPlatforms
  ADD HL,DE
  LD A,(CrumbleNewType)
  LD (HL),A
  RET

  ORG $BBCD

; Every 4 frames, the next flame frame on every burning platform
;
; $AA0C counts frames; at 4, NextFireFrame $BC8B steps the frame $AA16 (1-3),
; and each of the 36 cells whose FireFlags $AAB3 byte is set gets the flame
; frame $814D + 30 × (frame - 1) (6 bytes × 5 rows, colour $C2) stored at
; CellAddrs $E131[cell] + $17B1 (DrawSpriteInk $E2A0). Called by MainLoop
; ($ACDB) and the level end ($B32E).
;
; Witness: L1 93190 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
AnimateFires:
  AND A
  LD A,(FireTick)
  INC A
  LD (FireTick),A
  CP $04
  RET NZ
  AND A
  CALL NextFireFrame
  LD B,$24
AnimateFiresLoop:
  PUSH BC
  LD A,$24
  SUB B
  LD (CellByte),A
  LD D,$00
  LD E,A
  LD HL,CellBurning
  ADD HL,DE
  LD A,(HL)
  CP $00
  JR Z,AnimateFiresNext
  LD HL,FirePictures
  LD A,(FireFrame)
  DEC A
  LD B,A
  LD DE,$001E
AnimateFiresFrame:
  LD A,B
  CP $00
  JR Z,AnimateFiresDraw
  ADD HL,DE
  DEC B
  JR AnimateFiresFrame
AnimateFiresDraw:
  PUSH HL
  AND A
  LD A,(CellByte)
  RLA
  LD E,A
  LD D,$00
  LD IX,CellAddresses
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  LD HL,$17B1
  ADD HL,DE
  EX DE,HL
  POP HL
  LD A,$06
  LD (SpriteWidth),A
  LD B,$05
  LD C,$C2
  CALL DrawSpriteColoured
AnimateFiresNext:
  POP BC
  DJNZ AnimateFiresLoop
  RET

; Every 4 frames, the next frame of every turning wall (type 4)
;
; $AA0D counts frames; at 4, NextWallFrame $BCA2 steps $AA17 (1-4), and each
; cell whose WallCells $AA8F byte is 4 gets the frame $7E5C + 48 × (frame - 1)
; (2 bytes × 24 rows) XORed at WallAddrs $E179[cell] (DrawSpriteXorInk, colour
; $83). Called by MainLoop ($ACDE) and the level end ($B331).
;
; Witness: L1 93190 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
AnimateWalls:
  AND A
  LD A,(WallTick)
  INC A
  LD (WallTick),A
  CP $04
  RET NZ
  CALL NextWallFrame
  LD B,$24
AnimateWallsLoop:
  PUSH BC
  LD A,$24
  SUB B
  LD (CellByte),A
  LD D,$00
  LD E,A
  LD HL,CellWalls
  ADD HL,DE
  LD A,(HL)
  CP $04
  JR NZ,AnimateWallsNext
  LD HL,WallPictures
  LD A,(WallFrame)
  DEC A
  LD B,A
  LD DE,$0030
AnimateWallsFrame:
  LD A,B
  CP $00
  JR Z,AnimateWallsDraw
  ADD HL,DE
  DEC B
  JR AnimateWallsFrame
AnimateWallsDraw:
  LD A,(CellByte)
  RLA
  LD E,A
  LD D,$00
  LD IX,WallAddresses
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  LD A,$02
  LD (SpriteWidth),A
  LD B,$18
  LD C,$83
  CALL DrawSpriteColoured
AnimateWallsNext:
  AND A
  POP BC
  DJNZ AnimateWallsLoop
  RET

; $AA0C = 0; the flame frame $AA16 steps 1, 2, 3, 1 ...
;
; Witness: L1 23297 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
NextFireFrame:
  LD A,$00
  LD (FireTick),A
  LD A,(FireFrame)
  CP $03
  JR Z,NextFireFrameWrap
  INC A
  LD (FireFrame),A
  RET
NextFireFrameWrap:
  LD A,$01
  LD (FireFrame),A
  RET

; $AA0D = 0; the wall frame $AA17 steps 1, 2, 3, 4, 1 ...
;
; Witness: L1 23297 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
NextWallFrame:
  LD A,$00
  LD (WallTick),A
  LD A,(WallFrame)
  CP $04
  JR Z,NextWallFrameWrap
  INC A
  LD (WallFrame),A
  RET
NextWallFrameWrap:
  LD A,$01
  LD (WallFrame),A
  RET

  ORG $BD73

; Arm the spring of the platform under the ball (types 1-5)
;
; When SpringArmed $AA13 is 0 and the platform $AB1C is 1-5: copies the 24-byte
; spring record of the type (SpringRecords $C52A[type - 1]) to $AB35 (4
; offsets, 4 frame addresses, 4 widths, 4 row counts) and sets SpringArmed.
; Types 0 and 6 up (conveyors, fire, bricks, exit) have no spring. Called by
; the bounce handlers when up or fire (UpKey $B463) is down, or the demo byte
; is 9.
;
; Witness: L1 2286 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
LoadSpring:
  XOR A
  LD A,(SpringArmed)
  CP $00
  RET NZ
  LD A,(CellPlatform)
  CP $00
  RET Z
  CP $06
  RET NC
  AND $07
  RLA
  LD B,$02
  SUB B
  LD E,A
  LD D,$00
  LD IX,SpringCurves
  ADD IX,DE
  LD H,(IX+$01)
  LD L,(IX+$00)
  LD DE,SpringRecord
  LD BC,$0018
  LDIR
  LD A,$01
  LD (SpringArmed),A
  RET

; Spring frame 0 off, 1 on (the platform squeezes)
;
; Each SpringStep XORs two of the 4 spring frames (SpringPart0-3): the one
; shown off, the next on. Steps 1-6 show frames 1, 2, 1, 0, 3, 0: down, further
; down, back, rest, up, rest. Called by the bounce handlers at fixed steps of
; the bounce ($C800, $C80B, $C81C, $C827 and the like).
;
; Witness: L1 1319 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SpringStep1:
  AND A
  CALL SpringPart0
  CALL SpringPart1
  RET

; Spring frame 1 off, 2 on
;
; Witness: L1 1319 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SpringStep2:
  AND A
  CALL SpringPart1
  CALL SpringPart2
  RET

; Spring frame 2 off, 1 on
;
; Witness: L1 1319 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SpringStep3:
  AND A
  CALL SpringPart2
  CALL SpringPart1
  RET

; Spring frame 1 off, 0 on
;
; Witness: L1 1319 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SpringStep4:
  AND A
  CALL SpringPart1
  CALL SpringPart0
  RET

; Spring frame 0 off, 3 on (the platform flexes up as the ball leaves)
;
; Called by the up-move handler ($CD1D).
;
; Witness: L1 1319 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SpringStep5:
  AND A
  CALL SpringPart0
  CALL SpringPart3
  RET

; Spring frame 3 off, 0 on; the spring is done (SpringArmed = 0)
;
; Called by the up-move handler ($CD62).
;
; Witness: L1 1316 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SpringStep6:
  AND A
  CALL SpringPart3
  CALL SpringPart0
  LD A,$00
  LD (SpringArmed),A
  RET

; XOR spring frame 0 at the cell's address + its offset
;
; HL = $AB2D + the offset $AB35, DE = the frame $AB3D, width $AB45, rows $AB49,
; DrawSpriteXor $E3EE.
;
; Witness: L1 5273 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SpringPart0:
  LD HL,(CellScrAddr)
  LD BC,(SpringRecord)
  ADD HL,BC
  LD DE,(SpringRecord+$0008)
  LD A,(SpringRecord+$0010)
  LD (SpriteWidth),A
  LD A,(SpringRecord+$0014)
  LD B,A
  CALL XorSprite
  RET

; XOR spring frame 1 (offset $AB37, frame $AB3F, width $AB46, rows $AB4A)
;
; Witness: L1 5276 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SpringPart1:
  LD HL,(CellScrAddr)
  LD BC,(SpringRecord+$0002)
  ADD HL,BC
  LD DE,(SpringRecord+$000A)
  LD A,(SpringRecord+$0011)
  LD (SpriteWidth),A
  LD A,(SpringRecord+$0015)
  LD B,A
  CALL XorSprite
  RET

; XOR spring frame 2 (offset $AB39, frame $AB41, width $AB47, rows $AB4B)
;
; Witness: L1 2638 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SpringPart2:
  LD HL,(CellScrAddr)
  LD BC,(SpringRecord+$0004)
  ADD HL,BC
  LD DE,(SpringRecord+$000C)
  LD A,(SpringRecord+$0012)
  LD (SpriteWidth),A
  LD A,(SpringRecord+$0016)
  LD B,A
  CALL XorSprite
  RET

; XOR spring frame 3 (offset $AB3B, frame $AB43, width $AB48, rows $AB4C)
;
; Witness: L1 2635 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
SpringPart3:
  LD HL,(CellScrAddr)
  LD BC,(SpringRecord+$0006)
  ADD HL,BC
  LD DE,(SpringRecord+$000E)
  LD A,(SpringRecord+$0013)
  LD (SpriteWidth),A
  LD A,(SpringRecord+$0017)
  LD B,A
  CALL XorSprite
  RET

; XOR the platform's rest frame of the tilt record (offset $AB4D, frame $AB53,
; width $AB59, rows $AB5C)
;
; The tilt record (18 bytes at $AB4D: 3 offsets, 3 frames, 3 widths, 3 row
; counts) is copied by the move handlers ($C890, $CAD6) from TiltRecords
; $C5CC[type - 1] when the ball rolls off a platform sideways: TiltPart0 +
; TiltPart1 tilt it left, TiltPart0 + TiltPart2 right, and the reverse pair
; sets it back. The AND C after the ADD only sets flags.
;
; Witness: L1 2402 (c1, fire, gameover, menu, twoname, l x12, rzx x90).
TiltPart0:
  LD HL,(CellScrAddr)
  LD BC,(TakeoffRecord)
  ADD HL,BC
  AND C
  LD DE,(TakeoffRecord+$0006)
  LD A,(TakeoffRecord+$000C)
  LD (SpriteWidth),A
  LD A,(TakeoffRecord+$000F)
  LD B,A
  CALL XorSprite
  RET

; XOR the left-tilt frame (offset $AB4F, frame $AB55, width $AB5A, rows $AB5D)
;
; Witness: L1 1106 (c1, fire, gameover, menu, twoname, l x11, rzx x85).
TiltPart1:
  LD HL,(CellScrAddr)
  LD BC,(TakeoffRecord+$0002)
  ADD HL,BC
  AND C
  LD DE,(TakeoffRecord+$0008)
  LD A,(TakeoffRecord+$000D)
  LD (SpriteWidth),A
  LD A,(TakeoffRecord+$0010)
  LD B,A
  CALL XorSprite
  RET

; XOR the right-tilt frame (offset $AB51, frame $AB57, width $AB5B, rows $AB5E)
;
; Witness: L1 1296 (c1, gameover, menu, twoname, l x12, rzx x89).
TiltPart2:
  LD HL,(CellScrAddr)
  LD BC,(TakeoffRecord+$0004)
  ADD HL,BC
  AND C
  LD DE,(TakeoffRecord+$000A)
  LD A,(TakeoffRecord+$000E)
  LD (SpriteWidth),A
  LD A,(TakeoffRecord+$0011)
  LD B,A
  CALL XorSprite
  RET

; Run the next step of the brick crumble animation, if one is active
;
; When $AB33 is set: jumps to BrickSteps $C534[$AB34] and advances $AB34. Steps
; BrickCrumble1-4 clear the hit layer at $AB31 in four checkered passes. Called
; by MainLoop ($ACCF).
;
; Witness: L1 92281 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
BrickStep:
  AND A
  LD A,(BrickActive)
  CP $00
  RET Z
  AND A
  LD IX,BrickBreakSteps
  LD A,(BrickAnimStep)
  RLA
  LD D,$00
  LD E,A
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  PUSH DE
  POP IX
  LD A,(BrickAnimStep)
  INC A
  LD (BrickAnimStep),A
  JP (IX)

; The brick sound and the first pass of the crumble
;
; The sound $F4E2, then with interrupts off: the layer's address $AB31 to a
; pixel line (ScreenAddrToLine $C71F, LineAddr $B515) and 8 of the 16 bytes of
; its 4 lines × 4 bytes set to 0 in a checker (BrickNextLine $BF06 between
; lines). Each crumble pass clears another pattern; the four leave the layer
; empty.
;
; Witness: L1 409 (l51, l59, l96, l98, rzx x27).
BrickCrumble1:
  CALL SfxAnimB
  DI
  PUSH IY
  AND A
  LD HL,(BrickLayerAddr)
  CALL ScreenAddrToLine
  CALL LineAddress
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(SpectrumColumn)
  OR L
  LD L,A
  PUSH HL
  POP IY
  LD (IY+$00),$00
  LD (IY+$02),$00
  CALL BrickNextLine
  LD (IY+$01),$00
  LD (IY+$03),$00
  CALL BrickNextLine
  LD (IY+$00),$00
  LD (IY+$02),$00
  CALL BrickNextLine
  LD (IY+$01),$00
  LD (IY+$03),$00
  POP IY
  EI
  RET

; IY = the next screen line's address at the same column
;
; IX += 2 in the line table ($B52D), IY = the line's address with the column
; $B52C ORed in.
;
; Witness: L1 4908 (l51, l59, l96, l98, rzx x27).
BrickNextLine:
  INC IX
  INC IX
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(SpectrumColumn)
  OR L
  LD L,A
  PUSH HL
  POP IY
  RET

; The second pass of the crumble
;
; Witness: L1 409 (l51, l59, l96, l98, rzx x27).
BrickCrumble2:
  DI
  PUSH IY
  LD HL,(BrickLayerAddr)
  CALL ScreenAddrToLine
  CALL LineAddress
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(SpectrumColumn)
  OR L
  LD L,A
  PUSH HL
  POP IY
  LD (IY+$01),$00
  LD (IY+$03),$00
  CALL BrickNextLine
  LD (IY+$00),$00
  LD (IY+$03),$00
  CALL BrickNextLine
  LD (IY+$01),$00
  LD (IY+$02),$00
  CALL BrickNextLine
  LD (IY+$01),$00
  LD (IY+$03),$00
  POP IY
  EI
  RET

; The third pass of the crumble
;
; Witness: L1 409 (l51, l59, l96, l98, rzx x27).
BrickCrumble3:
  DI
  PUSH IY
  LD HL,(BrickLayerAddr)
  CALL ScreenAddrToLine
  CALL LineAddress
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(SpectrumColumn)
  OR L
  LD L,A
  PUSH HL
  POP IY
  LD (IY+$00),$00
  LD (IY+$02),$00
  CALL BrickNextLine
  LD (IY+$00),$00
  LD (IY+$02),$00
  CALL BrickNextLine
  LD (IY+$01),$00
  LD (IY+$03),$00
  CALL BrickNextLine
  LD (IY+$00),$00
  LD (IY+$02),$00
  POP IY
  EI
  RET

; The last pass of the crumble; the animation ends ($AB33 = 0)
;
; Witness: L1 409 (l51, l59, l96, l98, rzx x27).
BrickCrumble4:
  DI
  PUSH IY
  LD HL,(BrickLayerAddr)
  CALL ScreenAddrToLine
  CALL LineAddress
  LD L,(IX+$00)
  LD H,(IX+$01)
  LD A,(SpectrumColumn)
  OR L
  LD L,A
  PUSH HL
  POP IY
  LD (IY+$01),$00
  LD (IY+$03),$00
  CALL BrickNextLine
  LD (IY+$01),$00
  LD (IY+$02),$00
  CALL BrickNextLine
  LD (IY+$00),$00
  LD (IY+$03),$00
  CALL BrickNextLine
  LD (IY+$00),$00
  LD (IY+$02),$00
  LD A,$00
  LD (BrickActive),A
  POP IY
  EI
  RET

; Run the next step of the put-out-the-fire animation, if one is active
;
; When $AB2B is set: jumps to the step table at $AB27 (WaterStepsA $C55E, B
; $C56E or C $C57E, chosen by the landing handler: $CA30, $CC73, $CE74), entry
; $AB26, and advances $AB26. Each sequence lets a drop fall (3 or 4 frames, the
; sprite WaterDrop $C0FE XORed at $AB29 + an offset), puts out the fire
; (ExtinguishFire $C10C), then shows 4 frames of steam. Called by MainLoop
; ($ACD2).
;
; Witness: L1 92281 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
WaterStep:
  AND A
  LD A,(FireOutActive)
  CP $00
  RET Z
  LD IX,(FireOutSteps)
  LD A,(FireOutStep)
  RLA
  LD D,$00
  LD E,A
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  PUSH DE
  POP IX
  LD A,(FireOutStep)
  INC A
  LD (FireOutStep),A
  JP (IX)

; Sequence A: the water sound $F427, drop frame A1 on
;
; Witness: L1 12 (l59, rzx x8).
WaterA1:
  CALL SfxAnimA
  JP DropA1

; Drop A1 off, A2 on
;
; Witness: L1 12 (l59, rzx x8).
WaterA2:
  CALL DropA1
  JP DropA2

; Drop A2 off, A3 on
;
; Witness: L1 12 (l59, rzx x8).
WaterA3:
  CALL DropA2
  JP DropA3

; Drop A3 off, the fire out (ExtinguishFire) and steam 1 on
;
; Witness: L1 12 (l59, rzx x8).
WaterA4:
  CALL DropA3
  JP ExtinguishFire

; Steam 1 off, 2 on
;
; Witness: L1 12 (l59, rzx x8).
WaterA5:
  CALL Steam1
  JP Steam2

; Steam 2 off, 3 on
;
; Witness: L1 12 (l59, rzx x8).
WaterA6:
  CALL Steam2
  JP Steam3

; Steam 3 off, 4 on
;
; Witness: L1 12 (l59, rzx x8).
WaterA7:
  CALL Steam3
  JP Steam4

; Steam 4 off; the animation ends ($AB2B = 0)
;
; Witness: L1 12 (l59, rzx x8).
WaterA8:
  CALL Steam4
  LD A,$00
  LD (FireOutActive),A
  RET

; Sequence B: the water sound, drop frame B1 on
;
; Witness: L1 25 (l36, l59, rzx x17).
WaterB1:
  CALL SfxAnimA
  JP DropB1

; Drop B1 off, B2 on
;
; Witness: L1 25 (l36, l59, rzx x17).
WaterB2:
  CALL DropB1
  JP DropB2

; Drop B2 off, B3 on
;
; Witness: L1 25 (l36, l59, rzx x17).
WaterB3:
  CALL DropB2
  JP DropB3

; Drop B3 off, the fire out and steam 1 on
;
; Witness: L1 25 (l36, l59, rzx x17).
WaterB4:
  CALL DropB3
  JP ExtinguishFire

; Steam 1 off, 2 on
;
; Witness: L1 25 (l36, l59, rzx x17).
WaterB5:
  CALL Steam1
  JP Steam2

; Steam 2 off, 3 on
;
; Witness: L1 25 (l36, l59, rzx x17).
WaterB6:
  CALL Steam2
  JP Steam3

; Steam 3 off, 4 on
;
; Witness: L1 25 (l36, l59, rzx x17).
WaterB7:
  CALL Steam3
  JP Steam4

; Steam 4 off; the animation ends
;
; Witness: L1 25 (l36, l59, rzx x17).
WaterB8:
  CALL Steam4
  LD A,$00
  LD (FireOutActive),A
  RET

; Sequence C: the water sound, drop frame C1 on
;
; Witness: L1 18 (menu, l10, l56, rzx x12).
WaterC1:
  CALL SfxAnimA
  JP DropC1

; Drop C1 off, C2 on
;
; Witness: L1 18 (menu, l10, l56, rzx x12).
WaterC2:
  CALL DropC1
  JP DropC2

; Drop C2 off, C3 on
;
; Witness: L1 18 (menu, l10, l56, rzx x12).
WaterC3:
  CALL DropC2
  JP DropC3

; Drop C3 off, C4 on
;
; Witness: L1 18 (menu, l10, l56, rzx x12).
WaterC4:
  CALL DropC3
  JP DropC4

; Drop C4 off, the fire out and steam 1 on
;
; Witness: L1 18 (menu, l10, l56, rzx x12).
WaterC5:
  CALL DropC4
  JP ExtinguishFire

; Steam 1 off, 2 on
;
; Witness: L1 18 (menu, l10, l56, rzx x12).
WaterC6:
  CALL Steam1
  JP Steam2

; Steam 2 off, 3 on
;
; Witness: L1 18 (menu, l10, l56, rzx x12).
WaterC7:
  CALL Steam2
  JP Steam3

; Steam 3 off, 4 on
;
; Witness: L1 18 (menu, l10, l56, rzx x12).
WaterC8:
  CALL Steam3
  JP Steam4

; Steam 4 off; the animation ends
;
; Witness: L1 18 (menu, l10, l56, rzx x12).
WaterC9:
  CALL Steam4
  LD A,$00
  LD (FireOutActive),A
  RET

; XOR the drop at $AB29 + $1715
;
; Each Drop entry loads its offset into BC and joins XorWaterDrop $C0E8.
;
; Witness: L1 24 (l59, rzx x8).
DropA1:
  LD BC,$1715
  JR XorWaterDrop

; XOR the drop at $AB29 - $089C ($F764)
;
; Witness: L1 24 (l59, rzx x8).
DropA2:
  LD BC,$F764
  JR XorWaterDrop

; XOR the drop at $AB29 + $1763
;
; Witness: L1 24 (l59, rzx x8).
DropA3:
  LD BC,$1763
  JR XorWaterDrop

; XOR the drop at $AB29 + $1711
;
; Witness: L1 50 (l36, l59, rzx x17).
DropB1:
  LD BC,$1711
  JR XorWaterDrop

; XOR the drop at $AB29 - $089E ($F762)
;
; Witness: L1 50 (l36, l59, rzx x17).
DropB2:
  LD BC,$F762
  JR XorWaterDrop

; XOR the drop at $AB29 + $1763
;
; Witness: L1 50 (l36, l59, rzx x17).
DropB3:
  LD BC,$1763
  JR XorWaterDrop

; XOR the drop at $AB29 + $1EC3
;
; Witness: L1 36 (menu, l10, l56, rzx x12).
DropC1:
  LD BC,$1EC3
  JR XorWaterDrop

; XOR the drop at $AB29 + $0713
;
; Witness: L1 36 (menu, l10, l56, rzx x12).
DropC2:
  LD BC,$0713
  JR XorWaterDrop

; XOR the drop at $AB29 + $2F13
;
; Witness: L1 36 (menu, l10, l56, rzx x12).
DropC3:
  LD BC,$2F13
  JR XorWaterDrop

; XOR the drop at $AB29 + $1763
;
; Witness: L1 36 (menu, l10, l56, rzx x12).
DropC4:
  LD BC,$1763

; XOR WaterDrop (2 bytes × 7 rows, colour 5) at $AB29 + BC
;
; DrawSpriteXorInk $E3E5. The offsets are CPC screen offsets ($0800 a pixel
; line, 80 a character row).
;
; Witness: L1 366 (menu, l10, l36, l56, l59, rzx x28).
XorWaterDrop:
  AND A
  LD HL,(FireOutAddr)
  ADD HL,BC
  LD A,$02
  LD (SpriteWidth),A
  LD DE,WaterDrop
  LD B,$07
  LD C,$05
  CALL XorSpriteColoured
  AND A
  RET

; The falling water drop: 2 bytes × 7 rows of CPC mode-1 pixels
;
; Read by XorWaterDrop $C0E8.
WaterDrop:
  DEFB $01,$88
  DEFB $13,$08
  DEFB $33,$88
  DEFB $17,$8C
  DEFB $67,$C4
  DEFB $36,$04
  DEFB $13,$08

; Put out the fire under the ball: platform 8 becomes 1, 9 becomes 5
;
; FireFlags $AAB3[$AA44] = 0; PlatformCells[$AA44] becomes 1 if it was 8, else
; 5; the blank $6708 is stored over the flames at $AB29 + $0FB1 (6 bytes × 6
; rows, colour $C6); then falls into Steam1. Witness: 49 fires put out (11 + 22
; + 16 by sequence).
;
; Witness: L1 55 (menu, l10, l36, l56, l59, rzx x28).
ExtinguishFire:
  AND A
  LD A,(BallCell)
  LD D,$00
  LD E,A
  LD HL,CellBurning
  ADD HL,DE
  LD (HL),$00
  LD HL,CellPlatforms
  ADD HL,DE
  LD A,(HL)
  LD (HL),$01
  CP $08
  JR Z,ExtinguishFireDraw
  LD (HL),$05
ExtinguishFireDraw:
  LD DE,BlankPicture
  PUSH DE
  LD HL,(FireOutAddr)
  LD BC,$0FB1
  ADD HL,BC
  POP DE
  EX DE,HL
  LD A,$06
  LD B,A
  LD (SpriteWidth),A
  LD C,$C6
  CALL DrawSpriteColoured

; XOR steam frame 1 ($81A7, 6 bytes × 6 rows) at $AB29 + $0FB1
;
; Witness: L1 110 (menu, l10, l36, l56, l59, rzx x28).
Steam1:
  AND A
  LD HL,(FireOutAddr)
  LD BC,$0FB1
  ADD HL,BC
  LD DE,SteamPictures
  LD A,$06
  LD B,A
  LD (SpriteWidth),A
  LD C,$C3
  CALL XorSpriteColoured
  RET

; XOR steam frame 2 ($81CB, 6 bytes × 3 rows) at $AB29 + $27B1
;
; Witness: L1 110 (menu, l10, l36, l56, l59, rzx x28).
Steam2:
  AND A
  LD HL,(FireOutAddr)
  LD BC,$27B1
  ADD HL,BC
  LD DE,SteamPictures+$0024
  LD A,$06
  LD (SpriteWidth),A
  LD B,$03
  LD C,$C5
  CALL XorSpriteColoured
  RET

; XOR steam frame 3 ($81DD, 6 bytes × 2 rows) at $AB29 + $2FB1
;
; Witness: L1 110 (menu, l10, l36, l56, l59, rzx x28).
Steam3:
  AND A
  LD HL,(FireOutAddr)
  LD BC,$2FB1
  ADD HL,BC
  LD DE,SteamPictures+$0036
  LD A,$06
  LD (SpriteWidth),A
  LD B,$02
  LD C,$87
  CALL XorSpriteColoured
  RET

; XOR steam frame 4 ($81E9, 4 bytes × 3 rows) at $AB29 + $27B2
;
; Witness: L1 110 (menu, l10, l36, l56, l59, rzx x28).
Steam4:
  AND A
  LD HL,(FireOutAddr)
  LD BC,$27B2
  ADD HL,BC
  LD DE,SteamSmall
  LD A,$04
  LD (SpriteWidth),A
  LD B,$03
  LD C,$87
  CALL XorSpriteColoured
  RET

; Run the next step of a worn platform's animation, if one is active
;
; When $AA15 is set (copied from $AA14 by the landing handlers once the ball
; has left): jumps to the step table $AB22 (WearTo3Steps $C53C, WearTo4Steps
; $C544 or FallAwaySteps $C54C) entry $AB21 and advances $AB21. The frames are
; XORed at $AB24 (the cell's address when the change started). Called by
; MainLoop ($ACD5) and the move handlers ($CD80, $CD83, $CDA0, $CE8F).
;
; Witness: L1 93581 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
PlatformChangeStep:
  AND A
  LD A,(CrumbleActive)
  CP $00
  RET Z
  LD IX,(CrumbleSteps)
  LD A,(CrumbleStep)
  RLA
  LD D,$00
  LD E,A
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  PUSH DE
  POP IX
  LD A,(CrumbleStep)
  INC A
  LD (CrumbleStep),A
  JP (IX)

; Type 2 becomes 3: write the cell, platform 2 off, crack 2a on
;
; Witness: L1 250 (menu, l x9, rzx x56).
WearTo3Step1:
  CALL SetPlatformCell
  CALL XorPlatform2
  CALL XorCrack2a
  RET

; Crack 2a off, 2b on
;
; Witness: L1 250 (menu, l x9, rzx x56).
WearTo3Step2:
  CALL XorCrack2a
  CALL XorCrack2b
  RET

; Crack 2b off, 2c on
;
; Witness: L1 249 (menu, l x9, rzx x56).
WearTo3Step3:
  CALL XorCrack2b
  CALL XorCrack2c
  RET

; Crack 2c off, platform 3 on; done ($AA14 = $AA15 = 0)
;
; Witness: L1 249 (menu, l x9, rzx x56).
WearTo3Step4:
  CALL XorCrack2c
  CALL XorPlatform3
  LD A,$00
  LD (CrumblePending),A
  LD (CrumbleActive),A
  RET

; Type 3 becomes 4: platform 3 off, crack 3a on
;
; Witness: L1 385 (menu, l x11, rzx x77).
WearTo4Step1:
  CALL XorPlatform3
  CALL XorCrack3a
  RET

; Crack 3a off, 3b on
;
; Witness: L1 385 (menu, l x11, rzx x77).
WearTo4Step2:
  CALL XorCrack3a
  CALL XorCrack3b
  RET

; Crack 3b off, 3c on
;
; Witness: L1 385 (menu, l x11, rzx x77).
WearTo4Step3:
  CALL XorCrack3b
  CALL XorCrack3c
  RET

; Write the cell (4), crack 3c off, platform 4 on; done
;
; Witness: L1 385 (menu, l x11, rzx x77).
WearTo4Step4:
  CALL SetPlatformCell
  CALL XorCrack3c
  CALL XorPlatform4
  LD A,$00
  LD (CrumblePending),A
  LD (CrumbleActive),A
  RET

; Type 4 goes: write the cell (0), platform 4 off, fall frame 1 on
;
; Witness: L1 765 (l x11, rzx x87).
FallAwayStep1:
  CALL SetPlatformCell
  CALL XorPlatform4
  CALL XorFall1
  RET

; Fall frame 1 off, 2 on
;
; Witness: L1 765 (l x11, rzx x87).
FallAwayStep2:
  CALL XorFall1
  CALL XorFall2
  RET

; Fall frame 2 off, 3 on
;
; Witness: L1 765 (l x11, rzx x87).
FallAwayStep3:
  CALL XorFall2
  CALL XorFall3
  RET

; Fall frame 3 off, 4 on
;
; Witness: L1 765 (l x11, rzx x87).
FallAwayStep4:
  CALL XorFall3
  CALL XorFall4
  RET

; Fall frame 4 off, 5 on
;
; Witness: L1 765 (l x11, rzx x87).
FallAwayStep5:
  CALL XorFall4
  CALL XorFall5
  RET

; Fall frame 5 off, 6 on
;
; Witness: L1 765 (l x11, rzx x87).
FallAwayStep6:
  CALL XorFall5
  CALL XorFall6
  RET

; Fall frame 6 off, 7 on
;
; Witness: L1 765 (l x11, rzx x87).
FallAwayStep7:
  CALL XorFall6
  CALL XorFall7
  RET

; Fall frame 7 off, 8 on
;
; Witness: L1 765 (l x11, rzx x87).
FallAwayStep8:
  CALL XorFall7
  CALL XorFall8
  RET

; Fall frame 8 off: the platform is gone; done
;
; Witness: L1 765 (l x11, rzx x87).
FallAwayStep9:
  CALL XorFall8
  LD A,$00
  LD (CrumblePending),A
  LD (CrumbleActive),A
  RET

; XOR the type 2 platform ($7900, 8 bytes × 4 rows) at $AB24
;
; Each of the frame routines $C258-$C3BE XORs one frame at $AB24 plus a byte
; offset (DrawSpriteXor $E3EE): the platforms 2, 3 and 4 as the level shows
; them and the frames between.
;
; Witness: L1 250 (menu, l x9, rzx x56).
XorPlatform2:
  AND A
  LD DE,Platform2Pictures
  LD HL,(CrumbleAddr)
  LD A,$08
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7D84 (8 bytes × 4 rows) at $AB24
;
; Witness: L1 500 (menu, l x9, rzx x56).
XorCrack2a:
  AND A
  LD DE,CrumblePictures
  LD HL,(CrumbleAddr)
  LD A,$08
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7DA4 (6 bytes × 4 rows) at $AB24 + 1
;
; Witness: L1 499 (menu, l x9, rzx x56).
XorCrack2b:
  AND A
  LD DE,CrumbleType3
  LD HL,(CrumbleAddr)
  LD BC,$0001
  ADD HL,BC
  AND A
  LD A,$06
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7DBC (6 bytes × 4 rows) at $AB24 + 1
;
; Witness: L1 498 (menu, l x9, rzx x56).
XorCrack2c:
  AND A
  LD DE,CrumbleType3+$0018
  LD HL,(CrumbleAddr)
  LD BC,$0001
  ADD HL,BC
  AND A
  LD A,$06
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR the type 3 platform ($7A78, 6 bytes × 4 rows) at $AB24 + 1
;
; Witness: L1 634 (menu, l x11, rzx x78).
XorPlatform3:
  AND A
  LD DE,Platform3Pictures
  LD HL,(CrumbleAddr)
  LD BC,$0001
  ADD HL,BC
  AND A
  LD A,$06
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7DD4 (6 bytes × 4 rows) at $AB24 + 1
;
; Witness: L1 770 (menu, l x11, rzx x77).
XorCrack3a:
  AND A
  LD DE,CrumbleType3+$0030
  LD HL,(CrumbleAddr)
  LD BC,$0001
  ADD HL,BC
  AND A
  LD A,$06
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7DEC (4 bytes × 4 rows) at $AB24 + 2
;
; Witness: L1 770 (menu, l x11, rzx x77).
XorCrack3b:
  AND A
  LD DE,CrumbleType4
  LD HL,(CrumbleAddr)
  LD BC,$0002
  ADD HL,BC
  AND A
  LD A,$04
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7DFC (4 bytes × 4 rows) at $AB24 + 2
;
; Witness: L1 770 (menu, l x11, rzx x77).
XorCrack3c:
  AND A
  LD DE,CrumbleType4+$0010
  LD HL,(CrumbleAddr)
  LD BC,$0002
  ADD HL,BC
  AND A
  LD A,$04
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR the type 4 platform ($7B62, 4 bytes × 4 rows) at $AB24 + 2
;
; Witness: L1 1150 (menu, l x12, rzx x90).
XorPlatform4:
  AND A
  LD DE,Platform4Pictures
  LD HL,(CrumbleAddr)
  LD BC,$0002
  ADD HL,BC
  AND A
  LD A,$04
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7E0C (4 bytes × 4 rows) at $AB24 + 2
;
; Witness: L1 1530 (l x11, rzx x87).
XorFall1:
  AND A
  LD DE,CrumbleType4+$0020
  LD HL,(CrumbleAddr)
  LD BC,$0002
  ADD HL,BC
  AND A
  LD A,$04
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7E1C (2 bytes × 4 rows) at $AB24 + 3
;
; Witness: L1 1530 (l x11, rzx x87).
XorFall2:
  AND A
  LD DE,CrumbleSmall
  LD HL,(CrumbleAddr)
  LD BC,$0003
  ADD HL,BC
  AND A
  LD A,$02
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7E24 (2 bytes × 4 rows) at $AB24 + 3
;
; Witness: L1 1530 (l x11, rzx x87).
XorFall3:
  AND A
  LD DE,CrumbleSmall+$0008
  LD HL,(CrumbleAddr)
  LD BC,$0003
  ADD HL,BC
  AND A
  LD A,$02
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7E2C (2 bytes × 4 rows) at $AB24 + 3
;
; Witness: L1 1530 (l x11, rzx x87).
XorFall4:
  AND A
  LD DE,CrumbleSmall+$0010
  LD HL,(CrumbleAddr)
  LD BC,$0003
  ADD HL,BC
  AND A
  LD A,$02
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; XOR $7E34 (2 bytes × 5 rows) at $AB24 + 3
;
; Witness: L1 1530 (l x11, rzx x87).
XorFall5:
  AND A
  LD DE,CrumbleBits
  LD HL,(CrumbleAddr)
  LD BC,$0003
  ADD HL,BC
  AND A
  LD A,$02
  LD (SpriteWidth),A
  LD B,$05
  CALL XorSprite
  RET

; XOR $7E3E (2 bytes × 5 rows) at $AB24 + 3 - $0800 (a pixel line higher)
;
; Witness: L1 1530 (l x11, rzx x87).
XorFall6:
  AND A
  LD DE,CrumbleBits+$000A
  LD HL,(CrumbleAddr)
  LD BC,$F803
  ADD HL,BC
  AND A
  LD A,$02
  LD (SpriteWidth),A
  LD B,$05
  CALL XorSprite
  RET

; XOR $7E48 (2 bytes × 5 rows) at $AB24 + 3 - $0800
;
; Witness: L1 1530 (l x11, rzx x87).
XorFall7:
  AND A
  LD DE,CrumbleBits+$0014
  LD HL,(CrumbleAddr)
  LD BC,$F803
  ADD HL,BC
  AND A
  LD A,$02
  LD (SpriteWidth),A
  LD B,$05
  CALL XorSprite
  RET

; XOR $7E52 (2 bytes × 5 rows) at $AB24 + 3 - $0800
;
; Witness: L1 1530 (l x11, rzx x87).
XorFall8:
  AND A
  LD DE,CrumbleBits+$001E
  LD HL,(CrumbleAddr)
  LD BC,$F803
  ADD HL,BC
  AND A
  LD A,$02
  LD (SpriteWidth),A
  LD B,$05
  CALL XorSprite
  RET

; The ball bounced on a type 2 platform: arm its change to 3
;
; $AB24 = the cell's address $AB2D, $AA14 = 1 (pending until the ball leaves),
; the steps WearTo3Steps $C53C from 0, the cell $AB1B = $AA44, the new type
; $AB20 = 3. Called by the landing handlers ($C7C1, $C8C4, $CB0A, $CD23).
; Platforms 2, 3 and 4 wear: each bounce takes them one step towards nothing.
; Witness: 220 runs.
;
; Witness: L1 250 (menu, l x9, rzx x56).
StartWearTo3:
  AND A
  LD HL,(CellScrAddr)
  LD (CrumbleAddr),HL
  LD A,$01
  LD (CrumblePending),A
  LD HL,CrumbleSteps2
  LD (CrumbleSteps),HL
  LD A,$00
  LD (CrumbleStep),A
  LD A,(BallCell)
  LD (CrumbleCell),A
  LD A,$03
  LD (CrumbleNewType),A
  RET

; The ball bounced on a type 3 platform: arm its change to 4
;
; As StartWearTo3 with WearTo4Steps $C544 and the new type 4. Witness: 328
; runs.
;
; Witness: L1 385 (menu, l x11, rzx x77).
StartWearTo4:
  AND A
  LD HL,(CellScrAddr)
  LD (CrumbleAddr),HL
  LD A,$01
  LD (CrumblePending),A
  LD HL,CrumbleSteps3
  LD (CrumbleSteps),HL
  LD A,$00
  LD (CrumbleStep),A
  LD A,(BallCell)
  LD (CrumbleCell),A
  LD A,$04
  LD (CrumbleNewType),A
  RET

; The ball bounced on a type 4 platform: arm its fall (type 0, no platform)
;
; As StartWearTo3 with FallAwaySteps $C54C and the new type 0. Witness: 672
; runs.
;
; Witness: L1 765 (l x11, rzx x87).
StartFallAway:
  AND A
  LD HL,(CellScrAddr)
  LD (CrumbleAddr),HL
  LD A,$01
  LD (CrumblePending),A
  LD HL,CrumbleSteps4
  LD (CrumbleSteps),HL
  LD A,$00
  LD (CrumbleStep),A
  LD A,(BallCell)
  LD (CrumbleCell),A
  LD A,$00
  LD (CrumbleNewType),A
  RET

; Run the next step of a lock's opening, if one is active
;
; When $AA1D is set: jumps to the step table $AA1A (set by the wall handlers
; $C95D-$C971 and $CBA0-$CBB4 from the lock's type: LockSteps $C592 for 3,
; $C596 for 2, $C59A for 1) entry $AA1C and advances it. A key turns lock 3
; into 2, 2 into 1, and 1 into an open wall, each with its sound. Called by
; MainLoop ($ACD8).
;
; Witness: L1 92281 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
WallStep:
  AND A
  LD A,(LockActive)
  CP $00
  RET Z
  LD IX,(LockAnimSteps)
  LD A,(LockStep)
  RLA
  LD D,$00
  LD E,A
  ADD IX,DE
  LD D,(IX+$01)
  LD E,(IX+$00)
  PUSH DE
  POP IX
  LD A,(LockStep)
  INC A
  LD (LockStep),A
  JP (IX)

; Lock 3: the sound $F43E, lock 3 frame off, the flash frame on
;
; XorLock3 $D20A, XorLockFlash $D216.
;
; Witness: L1 24 (l36, l96, rzx x18).
Lock3Step1:
  CALL SfxWallBounce
  CALL DrawLock3Pic
  CALL DrawLockFlashPic
  RET

; Flash off, lock 2 frame on; done
;
; Witness: L1 24 (l36, l96, rzx x18).
Lock3Step2:
  CALL DrawLockFlashPic
  CALL DrawLock2Pic
  JR WallStepEnd

; Lock 2: the sound $F455, lock 2 off, flash on
;
; Witness: L1 38 (l36, l59, l96, rzx x24).
Lock2Step1:
  CALL SfxLockA
  CALL DrawLock2Pic
  CALL DrawLockFlashPic
  RET

; Flash off, lock 1 frame on; done
;
; Witness: L1 38 (l36, l59, l96, rzx x24).
Lock2Step2:
  CALL DrawLockFlashPic
  CALL DrawLock1Pic
  JR WallStepEnd

; Lock 1: the sound $F46C, lock 1 off, flash on
;
; Witness: L1 117 (menu, l x6, rzx x42).
Lock1Step1:
  CALL SfxLockB
  CALL DrawLock1Pic
  CALL DrawLockFlashPic
  RET

; Flash off, the opening frame $7FDC stored
;
; Witness: L1 117 (menu, l x6, rzx x42).
Lock1Step2:
  CALL DrawLockFlashPic
  LD HL,WallOpening
  CALL StoreWallFrame
  RET

; The opening frame $800C
;
; Witness: L1 117 (menu, l x6, rzx x42).
Lock1Step3:
  LD HL,WallOpening+$0030
  CALL StoreWallFrame
  RET

; The opening frame $803C
;
; Witness: L1 117 (menu, l x6, rzx x42).
Lock1Step4:
  LD HL,WallOpening+$0060
  CALL StoreWallFrame
  RET

; The opening frame $806C
;
; Witness: L1 117 (menu, l x6, rzx x42).
Lock1Step5:
  LD HL,WallOpening+$0090
  CALL StoreWallFrame
  RET

; The opening frame $809C
;
; Witness: L1 117 (menu, l x6, rzx x42).
Lock1Step6:
  LD HL,WallOpening+$00C0
  CALL StoreWallFrame
  RET

; The blank $6708: the wall is gone; done
;
; Witness: L1 117 (menu, l x6, rzx x42).
Lock1Step7:
  LD HL,BlankPicture
  CALL StoreWallFrame

; $AA1D = 0: the lock's animation is over
;
; Witness: L1 179 (menu, l x6, rzx x42).
WallStepEnd:
  LD A,$00
  LD (LockActive),A
  RET

; Store the wall frame HL (2 bytes × 24 rows) at $AA18
;
; DrawSprite $E318 (a store, not an XOR).
;
; Witness: L1 702 (menu, l x6, rzx x42).
StoreWallFrame:
  AND A
  LD DE,(LockAnimAddr)
  LD A,$02
  LD (SpriteWidth),A
  LD B,$18
  CALL DrawSprite
  AND A
  RET

  ORG $C534

; The four steps of a brick wall breaking
;
; $BE94 calls BrickBreakSteps[$AB34] once a frame while $AB33 is set: $BEBB,
; $BF19, $BF60, $BFA7 (1476 calls).
BrickBreakSteps:
  DEFW BrickCrumble1,BrickCrumble2,BrickCrumble3,BrickCrumble4

; The steps of a type-2 platform turning into type 3 after the ball leaves it
;
; Set by $C3D5 ($AB22); $C1C3 writes the new type ($B8C2: $AA6B[$AB1B] = $AB20
; = 3), the others redraw. Witness: the RZX, 220 starts.
CrumbleSteps2:
  DEFW WearTo3Step1,WearTo3Step2,WearTo3Step3,WearTo3Step4

; The steps of a type-3 platform turning into type 4
;
; Set by $C3F8 (328 starts); the new type $AB20 = 4.
CrumbleSteps3:
  DEFW WearTo4Step1,WearTo4Step2,WearTo4Step3,WearTo4Step4

; The steps of a type-4 platform vanishing
;
; Set by $C41B (672 starts); the new type $AB20 = 0, no platform; the last step
; $C24C clears $AA14 and $AA15.
CrumbleSteps4:
  DEFW FallAwayStep1,FallAwayStep2,FallAwayStep3,FallAwayStep4,FallAwayStep5,FallAwayStep6,FallAwayStep7,FallAwayStep8,FallAwayStep9

; The steps of the water putting out a fire, the ball moving left
;
; LeftStep9 $C9CE starts it ($AB27, $AB26 = 0, $AB29 the cell's screen address,
; $AB2B = 1) when the ball reaches a burning platform (type 8 or 9) and holds a
; water drop.
FireOutLeft:
  DEFW WaterA1,WaterA2,WaterA3,WaterA4,WaterA5,WaterA6,WaterA7,WaterA8

; The same, the ball moving right
;
; Started by RightStep9 $CC11.
FireOutRight:
  DEFW WaterB1,WaterB2,WaterB3,WaterB4,WaterB5,WaterB6,WaterB7,WaterB8

; The same, the ball falling onto the burning platform below
;
; Started by DownStep0 $CE24.
FireOutDown:
  DEFW WaterC1,WaterC2,WaterC3,WaterC4,WaterC5,WaterC6,WaterC7,WaterC8,WaterC9

; $B1CB, a word nothing reads
;
; Known only from the recordings: no read. It would be a tenth step of
; FireOutDown ($B1CB is inside the burst animation $B1A7-$B1E6).
LeftoverWord:
  DEFW BurstEnd

; The two steps of a lock of type 3 opening to type 2
;
; The ball hits the lock with a key: $AA1A points here, $C43E plays it ($AA1C
; the step, $AA1D active). $C464: sound $F43E, XOR out the type-3 picture, XOR
; the flash picture; $C46E: XOR the flash picture off, draw the type-2 picture,
; stop.
LockOpenSteps3:
  DEFW Lock3Step1,Lock3Step2

; The two steps of a lock of type 2 opening to type 1
;
; $C476 (sound $F455, XOR out the type-2 picture, flash), $C480 (flash off,
; draw the type-1 picture, stop).
LockOpenSteps2:
  DEFW Lock2Step1,Lock2Step2

; The seven steps of a lock of type 1 opening for good
;
; $C488 (sound $F46C, XOR out the type-1 picture, flash), $C492 (flash off,
; store $7FDC), then $800C, $803C, $806C, $809C and the blank $6708 stored over
; the wall's place ($AA18): the lock falls away. 97 openings in the recordings.
LockOpenSteps1:
  DEFW Lock1Step1,Lock1Step2,Lock1Step3,Lock1Step4,Lock1Step5,Lock1Step6,Lock1Step7

; The routine that draws each platform type 0-12 when the level is built
;
; BuildLevel's cell loop ($CFC8) jumps to PlatformDrawTable[type]; each routine
; draws at the cell's screen address $AB2D and goes on to BuildLevelObject
; $CFF4. Type 0 and type 11 (the exit) draw nothing: the exit appears only when
; OpenExit $BCB9 writes it.
PlatformDrawTable:
  DEFW PlatDrawNone,PlatDraw1,PlatDraw2,PlatDraw3,PlatDraw4,PlatDraw5,PlatDraw6,PlatDraw7,PlatDraw8,PlatDraw9,PlatDraw10,PlatDrawNone,PlatDraw12

; The routine that draws each wall type 0-4 when the level is built
;
; BuildLevelObject jumps to WallDrawTable[$AA8F[cell]]; each goes on to
; BuildLevelNextCell $D047.
WallDrawTable:
  DEFW WallDrawNone,WallDraw1,WallDraw2,WallDraw3,WallDraw4

  ORG $C71F

; Convert a CPC screen address to the character row, pixel line and byte column
;
; Input HL: an address in the CPC layout ($C000 + line in the row x $800 + row
; x 80 + byte). Output: ScanInRow $C74E = the line within the character row
; (0-7), CharRow $C74F = the row, ByteColumn $C750 = the byte column (0-79),
; PixelLine $C751 = row x 8 + line. Uses DivideHLbyBC $C752 for the division by
; 80. BC, DE, HL changed. Every picture drawn goes through it (277 064 calls in
; the recordings).
;
; Witness: L1 324616 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
ScreenAddrToLine:
  LD BC,$C000
  AND A
  SBC HL,BC
  LD A,H
  SRL A
  SRL A
  SRL A
  LD (ScanInRow),A
  PUSH AF
  LD A,H
  AND $07
  LD H,A
  LD BC,$0050
  CALL DivideHLbyBC
  LD A,L
  LD (CharRow),A
  SLA A
  SLA A
  SLA A
  POP BC
  ADD A,B
  LD (PixelLine),A
  LD A,E
  LD (ByteColumn),A
  RET

; The line within the character row (0-7)
ScanInRow:
  DEFB $00
CharRow:
  DEFB $00                ; The character row
ByteColumn:
  DEFB $00                ; The byte column (0-79)
PixelLine:
  DEFB $00                ; The pixel line, row x 8 + line

; Divide HL by BC: the quotient to DivQuotient, the remainder to DivRemainder
;
; A 16-step shift-and-subtract division. Input HL the dividend, BC the divisor.
; Output HL = DivQuotient $C774, DE = DivRemainder $C776. Only ScreenAddrToLine
; calls it (BC = 80).
;
; Witness: L1 324616 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
DivideHLbyBC:
  LD DE,$0000
  EX DE,HL
  LD A,$10
DivideStep:
  RL E                    ; one bit of the quotient a pass, 16 passes
  RL D
  ADC HL,HL
  SBC HL,BC
  JR NC,DivideBitDone
  ADD HL,BC
DivideBitDone:
  CCF
  DEC A
  JR NZ,DivideStep
  RL E
  RL D
  EX DE,HL
  LD (DivQuotient),HL
  LD (DivRemainder),DE
  RET

; The quotient of the last division
DivQuotient:
  DEFW $0000
DivRemainder:
  DEFW $0000              ; The remainder

  ORG $CF0C

; Draw the 72 x 200 picture PanelPicture at CPC $C03E (never called)
;
; Copies PanelPicture $D2B4 (18 bytes a line, 200 lines) to the CPC address
; $C03E with the store routine $E318. No instruction calls it and no table
; holds its address: known only from the code. It reads like the Amstrad
; version's side panel (the Spectrum draws the sides from $6398 and $6518 with
; $B488 instead).
;
; Witness: L1 0 ().
DrawPanelA:
  LD HL,PanelPicture
  LD DE,WaterA7+$0001
  LD A,$12
  LD (SpriteWidth),A
  LD B,$C8
  CALL DrawSprite
  RET

; A second copy of DrawPanelA, never called
;
; Byte for byte the same code. Known only from the code.
;
; Witness: L1 0 ().
DrawPanelB:
  LD HL,PanelPicture
  LD DE,WaterA7+$0001
  LD A,$12
  LD (SpriteWidth),A
  LD B,$C8
  CALL DrawSprite
  RET

  ORG $D076

; A lone RET before DrawObjectXor
;
; Known only from the code: nothing calls it.
;
; Witness: L1 0 ().
UnusedRet:
  RET

; XOR the picture at $A9F6 over the current cell's object place (never called)
;
; The same place and size as BuildLevelObject's object ($AB2D - $9E, 14 lines
; of 4 bytes), the picture from the word $A9F6, drawn by XOR without ink.
; Nothing calls it: an earlier way to draw or wipe an object. Known only from
; the code.
;
; Witness: L1 0 ().
DrawObjectXor:
  AND A
  LD HL,(CellScrAddr)
  LD BC,$FF62
  ADD HL,BC
  LD DE,(LevelsEnd+$006E)
  LD A,$04
  LD (SpriteWidth),A
  LD B,$0E
  CALL XorSprite
  RET

; XOR the EXIT sign $6698 above the current cell (never called)
;
; Draws $6698 (7 lines of 8 bytes) at $AB2D + $F710, one character row above
; the platform. Nothing calls it; OpenExit $BCB9 would be its caller. Known
; only from the code.
;
; Witness: L1 0 ().
DrawExitSign:
  AND A
  LD HL,(CellScrAddr)
  LD BC,$F710
  ADD HL,BC
  LD DE,ExitSign
  LD A,$08
  LD (SpriteWidth),A
  LD B,$07
  CALL XorSprite
  RET

; Platform types 0 and 11: nothing to draw
;
; Witness: L1 1003 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x23).
PlatDrawNone:
  JP BuildLevelObject

; Platform type 1, the plain platform
;
; Witness: L1 1222 (c1, fire, gameover, menu, twoname, l51, l98, rzx x13).
PlatDraw1:
  CALL DrawPlatform1Pic
  JP BuildLevelObject

; XOR the plain platform $7788 at the cell
;
; Witness: L1 1290 (c1, fire, gameover, menu, twoname, l51, l98, rzx x13).
DrawPlatform1Pic:
  LD DE,Platform1Pictures
  JR DrawPlatformPic

; Platform type 2, the first crumbling stage
;
; Witness: L1 187 (fire, menu, l51, l96, l98, rzx x15).
PlatDraw2:
  CALL DrawPlatform2Pic
  JP BuildLevelObject

; XOR the picture $7900 at the cell
;
; Witness: L1 187 (fire, menu, l51, l96, l98, rzx x15).
DrawPlatform2Pic:
  LD DE,Platform2Pictures
  JR DrawPlatformPic

; Platform type 3, the second crumbling stage
;
; Witness: L1 141 (l51, l59, l96, l98, rzx x15).
PlatDraw3:
  CALL DrawPlatform3Pic
  JP BuildLevelObject

; XOR the picture $7A78 (6 bytes wide) one byte right of the cell
;
; Witness: L1 141 (l51, l59, l96, l98, rzx x15).
DrawPlatform3Pic:
  LD HL,(CellScrAddr)
  LD DE,$0001
  ADD HL,DE
  LD A,$06
  LD (SpriteWidth),A
  LD DE,Platform3Pictures
  LD B,$04
  CALL XorSprite
  RET

; Platform type 4, the last crumbling stage
;
; Witness: L1 229 (fire, l51, l59, l96, l98, rzx x14).
PlatDraw4:
  CALL DrawPlatform4Pic
  JP BuildLevelObject

; XOR the picture $7B62 (4 bytes wide) two bytes right of the cell
;
; Witness: L1 229 (fire, l51, l59, l96, l98, rzx x14).
DrawPlatform4Pic:
  LD HL,(CellScrAddr)
  LD DE,$0002
  ADD HL,DE
  LD A,$04
  LD (SpriteWidth),A
  LD DE,Platform4Pictures
  LD B,$04
  CALL XorSprite
  RET

; Platform type 5, the stopping platform
;
; Witness: L1 66 (menu, rzx x8).
PlatDraw5:
  CALL DrawPlatform5Pic
  JP BuildLevelObject

; XOR the picture $7BE2 at the cell
;
; Witness: L1 74 (fire, menu, rzx x9).
DrawPlatform5Pic:
  LD DE,Platform5Pictures
  JR DrawPlatformPic

; XOR the picture DE at the cell's address $AB2D: 8 bytes wide, 4 lines
;
; Witness: L1 1551 (c1, fire, gameover, menu, twoname, l51, l96, l98, rzx x21).
DrawPlatformPic:
  LD HL,(CellScrAddr)
  LD A,$08
  LD (SpriteWidth),A
  LD B,$04
  CALL XorSprite
  RET

; Platform type 6, the conveyor to the left
;
; Witness: L1 82 (menu, l51, l59, l98, rzx x11).
PlatDraw6:
  CALL DrawConveyorLeftPic
  JP BuildLevelObject

; XOR the picture $77A8 (10 lines) at $AB2D + $27B0
;
; Witness: L1 82 (menu, l51, l59, l98, rzx x11).
DrawConveyorLeftPic:
  LD HL,(CellScrAddr)
  LD DE,$27B0
  ADD HL,DE
  LD A,$08
  LD (SpriteWidth),A
  LD DE,Platform1Takeoff
  LD B,$0A
  CALL XorSprite
  RET

; Platform type 7, the conveyor to the right
;
; Witness: L1 89 (menu, l51, l59, l96, l98, rzx x13).
PlatDraw7:
  CALL DrawConveyorRightPic
  JP BuildLevelObject

; XOR the picture $77F8 (10 lines) at $AB2D + $27B0
;
; Witness: L1 89 (menu, l51, l59, l96, l98, rzx x13).
DrawConveyorRightPic:
  LD HL,(CellScrAddr)
  LD DE,$27B0
  ADD HL,DE
  LD A,$08
  LD (SpriteWidth),A
  LD DE,Platform1Takeoff2
  LD B,$0A
  CALL XorSprite
  RET

; Platform type 8: the plain platform on fire
;
; Draws the platform, then the flames.
;
; Witness: L1 68 (c1, gameover, menu, twoname, rzx x8).
PlatDraw8:
  CALL DrawPlatform1Pic
  CALL DrawFlames
  JP BuildLevelObject

; Mark the cell burning and draw the first flames
;
; $AAB3[$AA44] = 1 (the fire animation $BD21 then plays FireFrames there), and
; $814D is drawn with ink $C2 at $AB2D + $17B1 (5 lines of 6 bytes).
;
; Witness: L1 76 (c1, fire, gameover, menu, twoname, rzx x8).
DrawFlames:
  LD HL,CellBurning
  LD A,(BallCell)
  LD D,$00
  LD E,A
  ADD HL,DE
  LD (HL),$01
  CALL CellScreenAddr
  LD HL,(CellScrAddr)
  LD DE,$17B1
  ADD HL,DE
  LD DE,FirePictures
  LD A,$06
  LD (SpriteWidth),A
  LD B,$05
  LD C,$C2
  CALL XorSpriteColoured
  RET

; Platform type 9: the stopping platform on fire
;
; Witness: L1 8 (fire, rzx43, rzx59).
PlatDraw9:
  CALL DrawPlatform5Pic
  CALL DrawFlames
  JP BuildLevelObject

; Platform type 10, bricks
;
; Witness: L1 51 (fire, l98, rzx x6).
PlatDraw10:
  CALL DrawBricks
  JP BuildLevelObject

; Fill the cell with bricks: the counter 8 and four rows of the brick picture
;
; $AAD7[$AA44] = 8 (the brick counter: the moves left and right cannot enter
; the cell while it is not 0; $B8D1 counts it down), then $8345 four times, 8
; lines each, $50 bytes apart, through $E4BB with ink $82.
;
; Witness: L1 51 (fire, l98, rzx x6).
DrawBricks:
  LD HL,BrickLayers
  LD A,(BallCell)
  LD D,$00
  LD E,A
  ADD HL,DE
  LD (HL),$08
  CALL CellScreenAddr
  LD HL,(CellScrAddr)
  LD A,$08
  LD (SpriteWidth),A
  LD BC,$0EC0
  ADD HL,BC
  LD B,$04
DrawBricksRow:
  PUSH BC                 ; one of the four rows of bricks, $50 bytes (a
                          ; character row) apart
  PUSH HL
  LD DE,BrickPicture
  LD B,$08
  LD C,$82
  CALL XorBricksColoured
  POP HL
  LD BC,$0050
  ADD HL,BC
  POP BC
  DJNZ DrawBricksRow
  RET

; Platform type 12, spikes
;
; Witness: L1 217 (menu, l51, l59, l96, l98, rzx x15).
PlatDraw12:
  CALL DrawSpikesPic
  JP BuildLevelObject

; XOR the spikes $7D5A (7 lines, 6 bytes) at $AB2D + $2FB1
;
; Witness: L1 217 (menu, l51, l59, l96, l98, rzx x15).
DrawSpikesPic:
  LD HL,(CellScrAddr)
  LD DE,$2FB1
  ADD HL,DE
  LD A,$06
  LD (SpriteWidth),A
  LD DE,SpikesPicture
  LD B,$07
  CALL XorSprite
  RET

; Wall type 0: nothing to draw
;
; Witness: L1 2955 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98, rzx
; x24).
WallDrawNone:
  JP BuildLevelNextCell

; Wall type 1, the lock that opens with one key
;
; $BB1D gives the wall's address $AB2F, then DrawLock1Pic.
;
; Witness: L1 201 (menu, l59, l98, rzx x10).
WallDraw1:
  LD A,(BallCell)
  CALL WallScreenAddr
  CALL DrawLock1Pic
  JP BuildLevelNextCell

; Wall type 2, the lock that takes two keys
;
; Witness: L1 10 (l98, rzx56, rzx59).
WallDraw2:
  LD A,(BallCell)
  CALL WallScreenAddr
  CALL DrawLock2Pic
  JP BuildLevelNextCell

; Wall type 3, the lock that takes three keys
;
; Witness: L1 21 (rzx x7).
WallDraw3:
  LD A,(BallCell)
  CALL WallScreenAddr
  CALL DrawLock3Pic
  JP BuildLevelNextCell

; Wall type 4, the wall no key opens
;
; Witness: L1 176 (fire, menu, l51, l59, l98, rzx x12).
WallDraw4:
  LD A,(BallCell)
  CALL WallScreenAddr
  CALL DrawWall4Pic
  JP BuildLevelNextCell

; XOR the lock picture $7F7C at the wall
;
; Witness: L1 356 (menu, l x7, rzx x45).
DrawLock1Pic:
  LD DE,WallLock1
  JR DrawWallPic

; XOR the lock picture $7F4C at the wall
;
; Witness: L1 72 (l36, l59, l96, l98, rzx x26).
DrawLock2Pic:
  LD DE,WallLock2
  JR DrawWallPic

; XOR the lock picture $7F1C at the wall
;
; Witness: L1 45 (l36, l96, rzx x22).
DrawLock3Pic:
  LD DE,WallLock3
  JR DrawWallPic

; Draw the wall $7E5C with ink $83 at the wall
;
; Witness: L1 176 (fire, menu, l51, l59, l98, rzx x12).
DrawWall4Pic:
  LD DE,WallPictures
  LD C,$83
  JR DrawWallPicInk

; XOR the flash picture $7FAC at the wall (a lock opening)
;
; Witness: L1 358 (menu, l x6, rzx x42).
DrawLockFlashPic:
  LD DE,WallFlash
  JR DrawWallPic

; XOR the picture DE at the wall's address $AB2F: 2 bytes wide, 24 lines
;
; Witness: L1 831 (menu, l x7, rzx x47).
DrawWallPic:
  LD HL,(WallScrAddr)
  LD A,$02
  LD (SpriteWidth),A
  LD B,$18
  CALL XorSprite
  RET
; This entry point is used by the routine at DrawWall4Pic.
DrawWallPicInk:
  LD HL,(WallScrAddr)     ; the same with the ink C ($E3E5)
  LD A,$02
  LD (SpriteWidth),A
  LD B,$18
  CALL XorSpriteColoured
  RET

; Store the wall-4 frame $7E5C at the wall (never called)
;
; With DrawWall4Frame1-3 an animation of the wall of type 4 drawn by store
; ($E318), not XOR: the frames $7E5C, $7E8C, $7EBC, $7EEC (48 bytes, 24 lines
; of 2 bytes). Nothing calls them; the game animates that wall with $BC30.
; Known only from the code.
;
; Witness: L1 0 ().
DrawWall4Frame0:
  LD HL,WallPictures
  JR StoreWallPic

; Store the frame $7E8C (never called)
;
; Witness: L1 0 ().
DrawWall4Frame1:
  LD HL,WallPictures+$0030
  JR StoreWallPic

; Store the frame $7EBC (never called)
;
; Witness: L1 0 ().
DrawWall4Frame2:
  LD HL,WallPictures+$0060
  JR StoreWallPic

; Store the frame $7EEC (never called)
;
; Witness: L1 0 ().
DrawWall4Frame3:
  LD HL,WallPictures+$0090
  JR StoreWallPic

; Store the picture HL at the wall's address $AB2F, 2 bytes wide, 24 lines
; (never called)
;
; Witness: L1 0 ().
StoreWallPic:
  LD DE,(WallScrAddr)
  LD A,$02
  LD (SpriteWidth),A
  LD B,$18
  CALL DrawSprite
  RET

  ORG $D2B4

; A picture of 18 bytes x 200 lines in CPC mode 1, never read
;
; Only DrawPanelA and DrawPanelB (never called) would read it. 3600 bytes,
; $D2B4-$E0C3.
PanelPicture:
  INCBIN "res/sprites/panel.bin",$0000,3600

  ORG $E131

; The CPC screen address of each cell 0-35 (36 words)
;
; $BB05 sets $AB2D = the word for the ball's cell $AA44; the fire put-out code
; reads it too. Rows are $140 bytes ($C942, $CA82, $CBC2, $CD02, $CE42, $CF82
; for column 0), columns 10 bytes apart. Words that only look like program
; addresses.
CellAddresses:
  INCBIN "res/tables/cell-addresses.bin",$0000,72

; The CPC screen address of each wall 0-35 (36 words; the sixth of each row is
; 0)
;
; $BB1D sets $AB2F = the word for wall A. Wall N is between cell N and cell N +
; 1; the last of each row has no wall.
WallAddresses:
  INCBIN "res/tables/wall-addresses.bin",$0000,72
