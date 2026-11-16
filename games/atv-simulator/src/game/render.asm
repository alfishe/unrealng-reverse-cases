; --------------------------------------------------------------------------------------------------------------------
; render.asm: The renderer: the draw modes, the sprites, the buffers, the trail lists, the copy to the screen
;
; Everything is drawn into a buffer of 22 bytes x 80 lines (BufferP1 $F03C for the top half, BufferP2 $F71C for the
; bottom half in a two-player game) and copied to the screen each pass (CopyBuffer, 22 LDIs a line). A sprite is a
; header (width in bytes, height in lines, advance, shift) and its bytes, line by line from the top; SpriteHeader
; ($865F) reads it into SpriteWidth.. and DrawSprite calls the current draw mode through ModeVector: the word table
; DrawModes for the front end, ListModes for the trail. There are no shifted copies: when SpriteX AND 7 differs from
; the shift a sprite's +3 byte keeps, SpriteHeader has ShiftLeftBy / ShiftRightBy (RotateSpriteLeft /
; RotateSpriteRight, a bit at a time over the whole sprite) move its bytes in place, and the bank stays so. In c1's
; heaviest pass (tools/pass_time.py: c1 frame 15356, 438 645 T, 89.7 % of the 7 frames) the two rotate routines take
; 31 % of the CPU, re-shifting the START sign's sprites ($7B 9 x 31, $A5 5 x 45) as they scroll off the left edge,
; with a landing's Tone.
; --------------------------------------------------------------------------------------------------------------------

  ORG $69F7

; The front end's draw modes: a routine each, picked by ModeVector ($82F8
; points at the word in use)
;
; +0 ModeNone (RET: measure only), +2 ModeCopyScreen, +4 ModeOrScreen (no
; caller), +6 ModeXorScreen, +8 ModeCopyBuffer, +10 ModeXorBuffer, +12
; ModeAttrsNone (RET), +14 ModeAttrsCopy (no caller), +16 BigPrint.
DrawModes:
  DEFW ModeNone
  DEFW ModeCopyScreen
  DEFW ModeOrScreen
  DEFW ModeXorScreen
  DEFW ModeCopyBuffer
  DEFW ModeXorBuffer
  DEFW ModeAttrsNone
  DEFW ModeAttrsCopy
  DEFW BigPrint

  ORG $8080

; The renderer's and the controls' variables
;
; In the image $8080-$80B2 hold "UND|" (the end of TrailsTextLeftover's
; "REGROUND|") and an older copy of KeyChars with c, e and s for CAPS SHIFT,
; ENTER and SYMBOL SHIFT: SetupIm2 writes the vector, ClearKeys the key states
; before any read.
RenderVars:
Im2Jump:
  DEFB $55,$4E,$44,$7C    ; JP Interrupt: every byte of the IM 2 table
                          ; ($FE00-$FF00) is $80, so the vector is $8080
                          ; (SetupIm2 writes the JP)
AttrBase:
  DEFB $00,$00            ; the attribute area the attribute routines write
                          ; ($5800, $5821 for the top half, $59A1 for the
                          ; bottom)
KempstonOn:
  DEFB $00                ; 1: player 1 uses the Kempston joystick
Keyboard1Alt:
  DEFB $00                ; nonzero: player 1's keys are the Sinclair keys 6-0
                          ; in a two-player game (no menu item sets it;
                          ; ChooseKeys1)
SinclairOn:
  DEFB $00                ; 0: player 2 uses the keyboard, 1 the Sinclair
                          ; joystick (keys 6-0)
JoyBits:
  DEFB $00                ; the Kempston's five bits ORed in by ScanKeys
FillByte:
  DEFB $00                ; FillAttrs's attribute byte
KeyStates:
  DEFB $63,$5A,$58,$43,$56,$41,$53,$44 ; 40 bytes, 1 for a key held: the eight
  DEFB $46,$47,$51,$57,$45,$52,$54,$31 ; half-rows from CAPS SHIFT-V to
  DEFB $32,$33,$34,$35,$30,$39,$38,$37 ; SPACE-B, five keys each, bit 0 first
  DEFB $36,$50,$4F,$49,$55,$59,$65,$4C
  DEFB $4B,$4A,$48,$73,$73,$4D,$4E,$42
KeyChars:
  DEFB $5F,$5A,$58,$43,$56,$41,$53,$44 ; the 40 keys' characters for the menus
  DEFB $46,$47,$51,$57,$45,$52,$54,$31 ; ("_" a key that cannot be chosen: CAPS
  DEFB $32,$33,$34,$35,$30,$39,$38,$37 ; SHIFT, ENTER, SYMBOL SHIFT, SPACE)
  DEFB $36,$50,$4F,$49,$55,$59,$5F,$4C
  DEFB $4B,$4A,$48,$5F,$5F,$4D,$4E,$42
SpriteX:
  DEFB $00,$00            ; x in pixels (a word for the trail lists: the item's
                          ; distance minus the scroll)
SpriteY:
  DEFB $00,$00            ; y, counted up from the bottom line
ScreenBase:
  DEFB $00,$00,$00,$00,$00,$00 ; the screen's base address for ScreenAddr
                               ; ($4000, or $4021 / $48A1 in play)
DestAddr:
  DEFB $00,$00            ; the buffer or screen address a draw mode writes
SpriteNum:
  DEFB $00                ; the sprite number
SpriteData:
  DEFB $00,$00            ; the sprite's bytes
MaskData:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; a mask sprite's bytes (the masked
                                       ; modes)
SpriteWidth:
  DEFB $00                ; width in bytes
SpriteHeight:
  DEFB $00                ; height in lines
ShiftPtr:
  DEFB $00,$00            ; the address of the sprite's shift byte (header +3)
SpriteAdvance:
  DEFB $00                ; the sprite's advance (header +2)
AttrDest:
  DEFB $00,$00            ; the attribute modes' destination
AttrSrc:
  DEFB $00,$00            ; a picture's attributes
AttrWidth:
  DEFB $00
AttrHeight:
  DEFB $00,$00,$00
LineCount:
  DEFB $00                ; ShiftBytesRight / ShiftBytesLeft's line counter
ShiftCount:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; ShiftLeftBy / ShiftRightBy's bit
  DEFB $00                             ; counter
KeyIndexes1:
  DEFB $06,$07,$08,$03,$01 ; player 1's five keys (KeyStates indexes: left,
                           ; right, up, down, jump): S, D, F, C, Z
KeyIndexes2:
  DEFB $22,$21,$20,$25,$27 ; player 2's: H, J, K, M, B
Controls1:
  DEFB $00                ; player 1's control bits this pass: 4 left, 3 right,
                          ; 2 up, 1 down, 0 jump
Controls2:
  DEFB $00                ; player 2's
ClipWidth:
  DEFB $00,$00,$00        ; the bytes drawn of a clipped sprite
ClipSkip:
  DEFB $00,$00            ; the bytes skipped of a clipped sprite's lines
ClipCode:
  DEFB $00                ; PlaceItem's verdict: 0 inside, 1 beyond the right
                          ; edge, 2 before the left edge, 3 cut at the right, 4
                          ; cut at the left
ListBase:
  DEFB $00,$00            ; the trail list being walked
ListIndexPtr:
  DEFB $00,$00            ; the address of the list's index word (DistanceIndex
                          ; / ScenIndex)
ListScroll:
  DEFB $00,$00            ; the list's scroll (the distance)
ItemFlags:
  DEFB $00                ; the item's draw flags: bit 0 attributes too, bits
                          ; 1-4 the mask's offset, bit 5 defer to DeferredB,
                          ; bit 6 defer to DeferredA, bit 7 masked
PlayerIndex:
  DEFB $00                ; 0 player 1, 1 player 2: whose pass this is
SeenCount:
  DEFB $00                ; the animated objects stepped this pass (AnimObject;
                          ; at most 30)
SeenIds:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; their ids: an object seen twice in a
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; pass (both players) moves once
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00
SavedSp:
  DEFB $00,$00            ; SP while ClearBuffer pushes zeros
BufferBase:
  DEFB $00,$00            ; the buffer being drawn ($F03C or $F71C)
DeferredA:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; deferred sprites drawn before the ATV:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; the next free offset, $8148 the count,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; $8149 items of 8 bytes (x, y, advance,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; sprite, routine, clip code, flags)
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
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00
DeferredB:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; deferred sprites drawn after the ATV:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; offset, count ($81EB), items from
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; $81EC
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
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00
DeferredAttrs:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; deferred attribute copies: offset,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; count ($828E), items of 7 bytes from
  DEFB $00,$00,$00,$00,$00,$00,$00,$00 ; $828F
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
  DEFB $00,$00,$00,$00
ModeVector:
  DEFB $00,$00            ; the draw mode word in use (DrawModes or ListModes)
AttrModeVector:
  DEFB $00,$00            ; the attribute mode word in use
SpriteCall:
  DEFB $00,$00            ; the sprite routine SpriteGo calls (GameSprite,
                          ; MenuSprite)

; The renderer's jump table; the first entry JP ScreenAddr
;
; The entries at $8307, $830A, $834F, $835E, $8361 and $8367 are called by no
; one (known only from the code).
;
; Witness: L1 3662 (c1, empty, fuel, kb, menu, trail1, trails, warp).
GfxTable:
  JP ScreenAddr

; JP NextLineHL
;
; Witness: L1 26033 (c1, empty, fuel, kb, trail1, trails, warp).
JpNextLineHL:
  JP NextLineHL

; JP NextLineDE
;
; Witness: L1 63950 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpNextLineDE:
  JP NextLineDE

; JP PrevLineHL
;
; Known only from the code: no recording runs it.
JpPrevLineHL:
  JP PrevLineHL

; JP PrevLineDE
;
; Known only from the code: no recording runs it.
JpPrevLineDE:
  JP PrevLineDE

; JP ClearKeys
;
; Witness: L1 417838 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpClearKeys:
  JP ClearKeys

; JP ScanKeys
;
; Witness: L1 137129 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpScanKeys:
  JP ScanKeys

; JP GameSpriteAt
;
; Witness: L1 15850 (c1, empty, fuel, kb, trail1, trails, warp).
JpGameSpriteAt:
  JP GameSpriteAt

; JP GameSprite
;
; Witness: L1 60204 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpGameSprite:
  JP GameSprite

; JP MenuSpriteAt
;
; Witness: L1 49 (c1, empty, fuel, kb, trail1, trails, warp).
JpMenuSpriteAt:
  JP MenuSpriteAt

; JP MenuSprite
;
; Witness: L1 51 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpMenuSprite:
  JP MenuSprite

; JP Multiply
;
; Witness: L1 878 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpMultiply:
  JP Multiply

; JP P1Left
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpP1Left:
  JP P1Left

; JP P1Right
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpP1Right:
  JP P1Right

; JP P1Up
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpP1Up:
  JP P1Up

; JP P1Down
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpP1Down:
  JP P1Down

; JP P1Jump
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpP1Jump:
  JP P1Jump

; JP P2Left
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpP2Left:
  JP P2Left

; JP P2Right
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpP2Right:
  JP P2Right

; JP P2Up
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpP2Up:
  JP P2Up

; JP P2Down
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpP2Down:
  JP P2Down

; JP P2Jump
;
; Witness: L1 24779 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpP2Jump:
  JP P2Jump

; JP CopyBufferP1
;
; Witness: L1 5351 (c1, empty, fuel, kb, trail1, trails, warp).
JpCopyBufferP1:
  JP CopyBufferP1

; JP CopyBufferP2
;
; Witness: L1 814 (kb).
JpCopyBufferP2:
  JP CopyBufferP2

; JP CopyLines
;
; Witness: L1 181 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpCopyLines:
  JP CopyLines

; JP ClearBufferP1
;
; Witness: L1 5437 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpClearBufferP1:
  JP ClearBufferP1

; JP ClearBufferP2
;
; Witness: L1 813 (kb).
JpClearBufferP2:
  JP ClearBufferP2

; JP AttrAddrPlay
;
; Known only from the code: no recording runs it.
JpAttrAddrPlay:
  JP AttrAddrPlay

; JP BufferAddr
;
; Witness: L1 72650 (c1, empty, fuel, kb, menu, trail1, trails, warp).
JpBufferAddr:
  JP BufferAddr

; JP FlushAttrs
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
JpFlushAttrs:
  JP FlushAttrs

; JP FlushDeferredA
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
JpFlushDeferredA:
  JP FlushDeferredA

; JP FlushDeferredB
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
JpFlushDeferredB:
  JP FlushDeferredB

; JP DeferA
;
; Known only from the code: no recording runs it.
JpDeferA:
  JP DeferA

; JP DeferB
;
; Known only from the code: no recording runs it.
JpDeferB:
  JP DeferB

; JP WalkList
;
; Witness: L1 12323 (c1, empty, fuel, kb, trail1, trails, warp).
JpWalkList:
  JP WalkList

; JP PlaceClipped
;
; Known only from the code: no recording runs it.
JpPlaceClipped:
  JP PlaceClipped

; JP SpriteGo
;
; Witness: L1 593 (c1, empty, fuel, kb, trail1, trails, warp).
JpSpriteGo:
  JP SpriteGo

; The trail lists' draw modes: OR, OR clipped, masked, masked mirrored, masked
; XOR, masked clipped
;
; +0 OrBuffer, +2 OrBufferClip, +4 MaskBuffer, +6 MaskMirror, +8 MaskBufferAlt,
; +10 MaskBufferClip. PlaceClipped picks by ClipCode and ItemFlags bit 7.
ListModes:
  DEFW OrBuffer
  DEFW OrBufferClip
  DEFW MaskBuffer
  DEFW MaskMirror
  DEFW MaskBufferAlt
  DEFW MaskBufferClip

; A = SpriteX AND 7 XOR 7 + 1 bits set from the left (no caller)
;
; Known only from the code.
MaskFromLeft:
  LD A,(SpriteX)
  AND $07
  XOR $07
  ADD A,$01
  LD B,A
  XOR A
l_8384:
  SCF
  RL A
  DJNZ l_8384
  RET

; A = SpriteX AND 7 + 1 bits set from the right (no caller)
;
; Known only from the code.
MaskFromRight:
  LD A,(SpriteX)
  AND $07
  ADD A,$01
  LD B,A
  XOR A
l_8393:
  SCF
  RR A
  DJNZ l_8393
  RET

; HL = the screen address of SpriteX / SpriteY (y up from the bottom, RowAddrs)
; + ScreenBase
;
; Witness: L1 19561 (c1, empty, fuel, kb, menu, trail1, trails, warp).
ScreenAddr:
  LD A,(SpriteY)
  CP $C0
  JP C,l_83A6
  SUB $C0
  JP l_83AA
l_83A6:
  LD E,A
  LD A,$BF
  SUB E
l_83AA:
  LD E,A
  SLA E
  LD D,$00
  RL D
  LD HL,RowAddrs
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD A,(SpriteX)
  LD E,A
  SRL E
  SRL E
  SRL E
  LD D,$00
  LD A,(SpriteY)
  CP $C0
  JP NC,l_83D4
  ADD HL,DE
  LD DE,(ScreenBase)
  ADD HL,DE
  RET
l_83D4:
  PUSH DE
  XOR A
  SRL A
  LD DE,$0020
  ADD HL,DE
  EX DE,HL
  LD HL,(ScreenBase)
  SBC HL,DE
  POP DE
  ADD HL,DE
  RET

; HL = A x E (8 x 8 bits)
;
; Witness: L1 71671 (c1, empty, fuel, kb, menu, trail1, trails, warp).
Multiply:
  LD D,$00
  LD HL,$0000
  LD B,$08
l_83EC:
  SRL A
  JP NC,l_83F2
  ADD HL,DE
l_83F2:
  SLA E
  RL D
  DJNZ l_83EC
  RET

  ORG $8547

; Copy a sprite's lines into the buffer (no caller)
;
; Known only from the code.
CopyBlockUnused:
  LD HL,(SpriteData)
  LD DE,(DestAddr)
  LD A,(SpriteHeight)
  LD B,A
l_8552:
  PUSH BC
  LD BC,(SpriteWidth)
  LD B,$00
  PUSH DE
  LDIR
  POP DE
  EX DE,HL
  LD BC,$0016
  ADD HL,BC
  EX DE,HL
  POP BC
  DJNZ l_8552
  RET

; XOR a sprite into the buffer, another copy of ModeXorBuffer (no caller)
;
; Known only from the code: no recording runs it.
XorBlockUnused:
  LD DE,(SpriteData)
  LD HL,(DestAddr)
  LD A,(SpriteHeight)
  LD C,A
l_8572:
  LD A,(SpriteWidth)
  LD B,A
  PUSH HL
l_8577:
  LD A,(DE)
  XOR (HL)
  LD (HL),A
  INC DE
  INC HL
  DJNZ l_8577
  POP HL
  PUSH DE
  LD DE,$0016
  ADD HL,DE
  POP DE
  DEC C
  JP NZ,l_8572
  RET

  ORG $85D0

; HL one screen line down
;
; Witness: L1 26033 (c1, empty, fuel, kb, trail1, trails, warp).
NextLineHL:
  INC H
  LD A,H
  AND $07
  RET NZ
  LD A,L
  ADD A,$20
  LD L,A
  RET C
  LD A,H
  SUB $08
  LD H,A
  RET

; DE one screen line down
;
; Witness: L1 571630 (c1, empty, fuel, kb, menu, trail1, trails, warp).
NextLineDE:
  INC D
  LD A,D
  AND $07
  RET NZ
  LD A,E
  ADD A,$20
  LD E,A
  RET C
  LD A,D
  SUB $08
  LD D,A
  RET

; HL one screen line up (no caller)
;
; Known only from the code.
PrevLineHL:
  DEC H
  LD A,H
  AND $07
  CP $07
  RET NZ
  LD A,L
  SUB $20
  LD L,A
  RET C
  LD A,H
  ADD A,$08
  LD H,A
  RET

; DE one screen line up (no caller)
;
; Known only from the code.
PrevLineDE:
  DEC D
  LD A,D
  AND $07
  CP $07
  RET NZ
  LD A,E
  SUB $20
  LD E,A
  RET C
  LD A,D
  ADD A,$08
  LD D,A
  RET

; DestAddr = the screen address; GameSprite
;
; Witness: L1 15850 (c1, empty, fuel, kb, trail1, trails, warp).
GameSpriteAt:
  CALL ScreenAddr
  LD (DestAddr),HL

; Draw in-game sprite SpriteNum (GameGfx): the header, the shift, the draw mode
;
; No sprite past the bank's count. HL = $8F5C + the word at $8F60 + 2 x
; SpriteNum: SpriteHeader.
;
; Witness: L1 182385 (c1, empty, fuel, kb, menu, trail1, trails, warp).
GameSprite:
  LD HL,GameGfx
  LD A,(SpriteNum)
  CP (HL)
  RET NC
  LD HL,GameGfx
  LD E,A
  LD D,$00
  SLA E
  RL D
  ADD HL,DE
  LD DE,$0004
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,GameGfx
  ADD HL,DE
  JP SpriteHeader

; DestAddr = the screen address; MenuSprite
;
; Witness: L1 49 (c1, empty, fuel, kb, trail1, trails, warp).
MenuSpriteAt:
  CALL ScreenAddr
  LD (DestAddr),HL

; Draw front-end picture SpriteNum (MenuGfx)
;
; Witness: L1 4165 (c1, empty, fuel, kb, menu, trail1, trails, warp).
MenuSprite:
  LD HL,MenuGfx
  LD A,(SpriteNum)
  CP (HL)
  RET NC
  LD HL,MenuGfx
  LD E,A
  LD D,$00
  SLA E
  RL D
  SLA E
  RL D
  ADD HL,DE
  LD DE,$0004
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD HL,MenuGfx
  ADD HL,DE

; Read a sprite's header (width, height, advance, shift) and shift it to
; SpriteX's bit offset; call the draw mode
;
; HL the header. +0 SpriteWidth, +1 SpriteHeight, +2 Advance, +3 the shift now
; in the bytes (ShiftPtr), +4 the bytes. When SpriteX AND 7 differs from the
; shift, ShiftLeftBy / ShiftRightBy move the bytes right or left the short way
; (up to 4 bits) and stores the new shift: the bank is shifted in place, on
; demand, and stays so. Then JP (the word at ModeVector).
;
; Witness: L1 186550 (c1, empty, fuel, kb, menu, trail1, trails, warp).
SpriteHeader:
  LD A,(HL)
  LD (SpriteWidth),A
  INC HL
  LD A,(HL)
  LD (SpriteHeight),A
  INC HL
  LD A,(HL)
  LD (SpriteAdvance),A
  INC HL
  LD (ShiftPtr),HL
  INC HL
  LD (SpriteData),HL
  JP l_8678
l_8678:
  LD A,(SpriteWidth)
  CP $01
  JP Z,l_86BC
  LD A,(SpriteX)
  AND $07
  LD E,A
  LD HL,(ShiftPtr)
  LD A,(HL)
  SUB E
  JP Z,l_86BC
  JP C,l_86A6
  CP $05
  JP P,l_869C
  CALL ShiftLeftBy
  JP l_86BC
l_869C:
  LD D,A
  LD A,$08
  SUB D
  CALL ShiftRightBy
  JP l_86BC
l_86A6:
  XOR $FF
  ADD A,$01
  CP $05
  JP NC,l_86B5
  CALL ShiftRightBy
  JP l_86BC
l_86B5:
  LD D,A
  LD A,$08
  SUB D
  CALL ShiftLeftBy
l_86BC:
  LD HL,(ModeVector)
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  JP (HL)

; Move every line's bytes one byte right (the last byte dropped, a zero in)
;
; Witness: L1 9604 (c1, empty, fuel, kb, menu, trail1, trails, warp).
ShiftBytesRight:
  LD A,(SpriteHeight)
  LD E,A
  LD A,(SpriteWidth)
  CALL Multiply
  LD DE,(SpriteData)
  ADD HL,DE
  DEC HL
  EX DE,HL
  LD H,D
  LD L,E
  DEC HL
  LD A,(SpriteHeight)
  LD (LineCount),A
l_86DE:
  LD BC,(SpriteWidth)
  LD B,$00
  DEC C
  LDDR
  LD A,$00
  LD (DE),A
  DEC HL
  DEC DE
  LD A,(LineCount)
  DEC A
  LD (LineCount),A
  JP NZ,l_86DE
  RET

; Move every line's bytes one byte left
;
; Witness: L1 9353 (c1, empty, fuel, kb, menu, trail1, trails, warp).
ShiftBytesLeft:
  LD DE,(SpriteData)
  LD HL,(SpriteData)
  INC HL
  LD A,(SpriteHeight)
  LD (LineCount),A
l_8705:
  LD BC,(SpriteWidth)
  LD B,$00
  DEC C
  LDIR
  LD A,$00
  LD (DE),A
  INC HL
  INC DE
  LD A,(LineCount)
  DEC A
  LD (LineCount),A
  JP NZ,l_8705
  RET

; Shift the sprite's bytes one bit left (the whole width)
;
; Witness: L1 61189 (c1, empty, fuel, kb, menu, trail1, trails, warp).
RotateSpriteLeft:
  LD A,(SpriteHeight)
  LD E,A
  LD A,(SpriteWidth)
  CALL Multiply
  LD DE,(SpriteData)
  ADD HL,DE
  DEC HL
  LD A,(SpriteHeight)
  LD C,A
l_8732:
  LD A,(SpriteWidth)
  LD B,A
  XOR A
  RRA
l_8738:
  RL (HL)
  DEC HL
  DJNZ l_8738
  DEC C
  JP NZ,l_8732
  RET

; Shift the sprite's bytes one bit right
;
; Witness: L1 61101 (c1, empty, fuel, kb, menu, trail1, trails, warp).
RotateSpriteRight:
  LD HL,(SpriteData)
  LD A,(SpriteHeight)
  LD C,A
l_8749:
  LD A,(SpriteWidth)
  LD B,A
  XOR A
  RRA
l_874F:
  RR (HL)
  INC HL
  DJNZ l_874F
  DEC C
  JP NZ,l_8749
  RET

; Shift A bits left, a byte along when the shift wraps
;
; Witness: L1 30797 (c1, empty, fuel, kb, menu, trail1, trails, warp).
ShiftLeftBy:
  LD (ShiftCount),A
l_875C:
  LD HL,(ShiftPtr)
  LD A,(HL)
  DEC A
  AND $07
  LD (HL),A
  CP $07
  JP NZ,l_876C
  CALL ShiftBytesRight
l_876C:
  CALL RotateSpriteLeft
  LD HL,ShiftCount
  DEC (HL)
  JP NZ,l_875C
  RET

; Shift A bits right
;
; Witness: L1 29358 (c1, empty, fuel, kb, menu, trail1, trails, warp).
ShiftRightBy:
  LD (ShiftCount),A
l_877A:
  LD HL,(ShiftPtr)
  LD A,(HL)
  INC A
  AND $07
  LD (HL),A
  JP NZ,l_878E
  CALL RotateSpriteRight
  CALL ShiftBytesLeft
  JP l_8791
l_878E:
  CALL RotateSpriteRight
l_8791:
  LD HL,ShiftCount
  DEC (HL)
  JP NZ,l_877A
  RET

; HL = the attribute address of SpriteX / SpriteY in the play area (80 lines,
; AttrBase)
;
; Witness: L1 1902 (c1, empty, fuel, kb, trail1, trails, warp).
AttrAddrPlay:
  LD A,(SpriteY)
  LD E,A
  LD A,$50
  SUB E
  JP NC,l_87A4
  XOR A
l_87A4:
  AND $F8
  LD L,A
  LD H,$00
  SLA L
  RL H
  SLA L
  RL H
  LD DE,(AttrBase)
  ADD HL,DE
  LD A,(SpriteX)
  SRL A
  SRL A
  SRL A
  LD E,A
  LD D,$00
  ADD HL,DE
  RET

; HL = the buffer address of SpriteX / SpriteY (BufferRows, BufferBase)
;
; Witness: L1 113665 (c1, empty, fuel, kb, menu, trail1, trails, warp).
BufferAddr:
  LD A,(SpriteY)
  LD E,A
  LD A,$4F
  SUB E
  JP NC,l_87D0
  LD E,$00
l_87D0:
  LD E,A
  LD D,$00
  SLA E
  RL D
  LD HL,BufferRows
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  LD A,(SpriteX)
  SRL A
  SRL A
  SRL A
  LD L,A
  LD H,$00
  ADD HL,DE
  LD DE,(BufferBase)
  ADD HL,DE
  RET

; Masked draw: (buffer AND NOT mask) XOR sprite
;
; Witness: L1 643 (c1, empty, fuel, kb, trail1, trails, warp).
MaskBufferAlt:
  LD IX,(MaskData)
  LD DE,(DestAddr)
  LD HL,(SpriteData)
  LD A,(SpriteHeight)
  LD C,A
l_8800:
  LD A,(SpriteWidth)
  LD B,A
  PUSH DE
l_8805:
  LD A,(IX+$00)
  XOR $FF
  EX DE,HL
  AND (HL)
  EX DE,HL
  XOR (HL)
  LD (DE),A
  INC HL
  INC IX
  INC DE
  DJNZ l_8805
  POP DE
  PUSH HL
  LD HL,$0016
  ADD HL,DE
  EX DE,HL
  POP HL
  DEC C
  JP NZ,l_8800
  RET

; Masked draw of a clipped sprite (ClipWidth bytes a line)
;
; Witness: L1 1336 (c1, empty, fuel, kb, trail1, trails, warp).
MaskBufferClip:
  LD IX,(MaskData)
  LD HL,(SpriteData)
  LD DE,(DestAddr)
  LD A,(SpriteHeight)
  LD C,A
l_8831:
  PUSH BC
  PUSH IX
  PUSH HL
  PUSH DE
  LD A,(ClipWidth)
  LD B,A
l_883A:
  LD A,(IX+$00)
  XOR $FF
  EX DE,HL
  AND (HL)
  EX DE,HL
  XOR (HL)
  LD (DE),A
  INC IX
  INC DE
  INC HL
  DJNZ l_883A
  POP HL
  LD BC,$0016
  ADD HL,BC
  EX DE,HL
  POP HL
  LD BC,(SpriteWidth)
  LD B,$00
  ADD HL,BC
  POP IX
  ADD IX,BC
  POP BC
  DEC C
  JP NZ,l_8831
  RET

; Masked draw: (buffer OR mask) XOR sprite
;
; Witness: L1 10697 (c1, empty, fuel, kb, trail1, trails, warp).
MaskBuffer:
  LD IX,(MaskData)
  LD DE,(DestAddr)
  LD HL,(SpriteData)
  LD A,(SpriteHeight)
  LD C,A
l_8871:
  LD A,(SpriteWidth)
  LD B,A
  PUSH DE
l_8876:
  LD A,(IX+$00)
  EX DE,HL
  OR (HL)
  EX DE,HL
  XOR (HL)
  LD (DE),A
  INC HL
  INC IX
  INC DE
  DJNZ l_8876
  POP DE
  PUSH HL
  LD HL,$0016
  ADD HL,DE
  EX DE,HL
  POP HL
  DEC C
  JP NZ,l_8871
  RET

; Masked draw mirrored: the bytes and their bits reversed
;
; Witness: L1 1631 (c1, fuel, trail1, trails, warp).
MaskMirror:
  LD IX,(MaskData)
  LD DE,(DestAddr)
  LD HL,(SpriteData)
  LD A,(SpriteHeight)
  LD C,A
l_88A0:
  PUSH BC
  PUSH DE
  LD A,(SpriteWidth)
  LD B,A
l_88A6:
  LD A,(HL)
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  PUSH BC
  LD A,(IX+$00)
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  SRL A
  RL C
  LD A,C
  POP BC
  EX DE,HL
  OR (HL)
  EX DE,HL
  XOR C
  LD (DE),A
  INC HL
  INC IX
  DEC DE
  DJNZ l_88A6
  POP DE
  PUSH HL
  LD HL,$0016
  ADD HL,DE
  EX DE,HL
  POP HL
  POP BC
  DEC C
  JP NZ,l_88A0
  RET

; Draw DeferredA's sprites (before the ATV)
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
FlushDeferredA:
  LD A,(DeferredA+$0002)
  CP $00
  RET Z
  LD B,A
  LD HL,DeferredA+$0003
  JP l_891D

; Draw DeferredB's sprites (after the ATV)
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
FlushDeferredB:
  LD A,(DeferredB+$0002)
  CP $00
  RET Z
  LD B,A
  LD HL,DeferredB+$0003
; This entry point is used by the routine at FlushDeferredA.
l_891D:
  PUSH BC
  LD DE,SpriteX
  LDI
  LD DE,SpriteY
  LDI
  LD DE,SpriteAdvance
  LDI
  LD DE,SpriteNum
  LDI
  LD DE,SpriteCall
  LDI
  LDI
  LD DE,ClipCode
  LDI
  LD DE,ItemFlags
  LDI
  PUSH HL
  CALL PlaceClipped
  POP HL
  POP BC
  DJNZ l_891D
  RET

; An item with attributes: its picture's attributes into DeferredAttrs
;
; Witness: L1 1902 (c1, empty, fuel, kb, trail1, trails, warp).
DeferAttrs:
  LD HL,DrawModes+$000C
  LD (AttrModeVector),HL
  CALL JpMenuSpriteAttrs
  CALL AttrAddrPlay
  LD (AttrDest),HL
  LD HL,(AttrSrc)
  LD DE,(ClipSkip)
  ADD HL,DE
  LD (AttrSrc),HL
  LD DE,(AttrDest)
  JP AddDeferredAttr

; Copy one deferred attribute block to the screen
;
; Witness: L1 1902 (c1, empty, fuel, kb, trail1, trails, warp).
CopyAttrs:
  LD HL,(AttrSrc)
  LD DE,(AttrDest)
  LD A,(AttrHeight)
  LD B,A
l_8978:
  PUSH BC
  PUSH HL
  PUSH DE
  LD BC,(ClipWidth)
  LD B,$00
  LDIR
  POP DE
  LD HL,$0020
  ADD HL,DE
  EX DE,HL
  POP HL
  LD BC,(AttrWidth)
  LD B,$00
  ADD HL,BC
  POP BC
  DJNZ l_8978
  RET

; Copy every deferred attribute block
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
FlushAttrs:
  LD A,(DeferredAttrs+$0002)
  CP $00
  RET Z
  LD B,A
  LD HL,DeferredAttrs+$0003
l_899F:
  PUSH BC
  LD DE,AttrSrc
  LDI
  LDI
  LD DE,AttrDest
  LDI
  LDI
  LD DE,ClipWidth
  LDI
  LD DE,AttrWidth
  LDI
  LD DE,AttrHeight
  LDI
  PUSH HL
  CALL CopyAttrs
  POP HL
  POP BC
  DJNZ l_899F
  RET

; Append the attribute variables to DeferredAttrs
;
; Witness: L1 1902 (c1, empty, fuel, kb, trail1, trails, warp).
AddDeferredAttr:
  LD HL,DeferredAttrs+$0002
  INC (HL)
  LD HL,$0007
  LD DE,(DeferredAttrs)
  ADD HL,DE
  LD (DeferredAttrs),HL
  LD HL,DeferredAttrs+$0003
  ADD HL,DE
  EX DE,HL
  LD HL,AttrSrc
  LDI
  LDI
  LD HL,AttrDest
  LDI
  LDI
  LD HL,ClipWidth
  LDI
  LD HL,AttrWidth
  LDI
  LD HL,AttrHeight
  LDI
  RET

; Append the sprite's variables to DeferredA
;
; Witness: L1 5379 (c1, empty, fuel, kb, trail1, trails, warp).
DeferA:
  LD HL,DeferredA+$0002
  INC (HL)
  LD HL,$0008
  LD DE,(DeferredA)
  ADD HL,DE
  LD (DeferredA),HL
  LD HL,DeferredA+$0003
  ADD HL,DE
  EX DE,HL
  JP l_8A23

; Append the sprite's variables to DeferredB
;
; Witness: L1 182 (warp).
DeferB:
  LD HL,DeferredB+$0002
  INC (HL)
  LD HL,$0008
  LD DE,(DeferredB)
  ADD HL,DE
  LD (DeferredB),HL
  LD HL,DeferredB+$0003
  ADD HL,DE
  EX DE,HL
; This entry point is used by the routine at DeferA.
l_8A23:
  LD HL,SpriteX
  LDI
  LD HL,SpriteY
  LDI
  LD HL,SpriteAdvance
  LDI
  LD HL,SpriteNum
  LDI
  LD HL,SpriteCall
  LDI
  LDI
  LD HL,ClipCode
  LDI
  LD HL,ItemFlags
  LDI
  RET

; An animated item: take its sprite and flags from its record and step the
; record's motions once a pass
;
; IY the item, IX its record: +0 sprite, +1 flags, +2 id, then up to three
; motions of (period, counter): the distance (+3/+4, step in +7's high nibble),
; y (+5/+6, step in +7's low nibble) and the sprite (+8 period and step, +9
; counter). A counter's bit 7 is the direction; it turns at the period. A
; motion with period $FF ends the record, 0 skips it. Each id moves once a pass
; (SeenIds). Trails 1-4: c1 4449 runs.
;
; Witness: L1 4985 (c1, empty, fuel, kb, trail1, trails, warp).
AnimObject:
  LD B,(IY+$05)
  PUSH BC
  POP IX
  LD A,(BC)
  LD (SpriteNum),A
  INC BC
  LD A,(BC)
  LD (ItemFlags),A
  BIT 0,A
  JP Z,l_8A63
  LD HL,MenuSprite
  LD (SpriteCall),HL
l_8A63:
  LD A,(PlayerIndex)
  CP $00
  JP Z,l_8A82
  LD A,(SeenCount)
  CP $00
  JP Z,l_8AA1
  LD B,A
  LD HL,SeenIds
l_8A77:
  LD A,(HL)
  CP (IX+$02)
  RET Z
  INC HL
  DJNZ l_8A77
  JP l_8AA1
l_8A82:
  LD A,(SeenCount)
  LD E,A
  ADD A,$01
  LD (SeenCount),A
  CP $1E
  JP C,AnimNewId

; More than 30 animated objects in a pass: blue border, hang
;
; Known only from the code.
ListOverflow:
  LD A,$01
  OUT ($FE),A
l_8A94:
  JP l_8A94
; This entry point is used by the routine at AnimObject.
AnimNewId:
  LD D,$00                ; the id into SeenIds
  LD HL,SeenIds
  ADD HL,DE
  LD A,(IX+$02)
  LD (HL),A
; This entry point is used by the routine at AnimObject.
l_8AA1:
  LD A,(IX+$03)
  CP $FF
  RET Z
  CP $00
  JP Z,l_8B0C
  LD E,A
  LD A,(IX+$04)
  BIT 7,A
  JP NZ,l_8AE0
  ADD A,$01
  CP E
  JP NZ,l_8ABD
  SET 7,A
l_8ABD:
  LD (IX+$04),A
  LD A,(IX+$07)
  AND $F0
  SRL A
  SRL A
  SRL A
  SRL A
  LD E,A
  LD D,$00
  LD L,(IY+$00)
  LD H,(IY+$01)
  ADD HL,DE
  LD (IY+$00),L
  LD (IY+$01),H
  JP l_8B0C
l_8AE0:
  AND $7F
  SUB $01
  JP Z,l_8AE9
  SET 7,A
l_8AE9:
  LD (IX+$04),A
  LD A,(IX+$07)
  AND $F0
  SRL A
  SRL A
  SRL A
  SRL A
  LD E,A
  LD D,$00
  LD L,(IY+$00)
  LD H,(IY+$01)
  XOR A
  RRA
  SBC HL,DE
  LD (IY+$00),L
  LD (IY+$01),H
l_8B0C:
  LD A,(IX+$05)
  CP $FF
  RET Z
  CP $00
  JP Z,l_8B54
  LD E,A
  LD A,(IX+$06)
  BIT 7,A
  JP NZ,l_8B3B
  ADD A,$01
  CP E
  JP NZ,l_8B28
  SET 7,A
l_8B28:
  LD (IX+$06),A
  LD A,(IX+$07)
  AND $0F
  LD E,A
  LD A,(IY+$02)
  ADD A,E
  LD (IY+$02),A
  JP l_8B54
l_8B3B:
  AND $7F
  SUB $01
  JP Z,l_8B44
  SET 7,A
l_8B44:
  LD (IX+$06),A
  LD A,(IX+$07)
  AND $0F
  LD E,A
  LD A,(IY+$02)
  SUB E
  LD (IY+$02),A
l_8B54:
  LD A,(IX+$08)
  CP $FF
  RET Z
  SRL A
  SRL A
  SRL A
  SRL A
  LD E,A
  LD A,(IX+$09)
  BIT 7,A
  JP NZ,l_8B86
  ADD A,$01
  CP E
  JP NZ,l_8B73
  SET 7,A
l_8B73:
  LD (IX+$09),A
  LD A,(IX+$08)
  AND $0F
  LD E,A
  LD A,(IX+$00)
  ADD A,E
  LD (IX+$00),A
  JP l_8B9F
l_8B86:
  AND $7F
  SUB $01
  JP Z,l_8B8F
  SET 7,A
l_8B8F:
  LD (IX+$09),A
  LD A,(IX+$08)
  AND $0F
  LD E,A
  LD A,(IX+$00)
  SUB E
  LD (IX+$00),A
l_8B9F:
  RET

; Draw an item by its clip code: whole (OrBuffer / MaskBuffer), cut at the
; right or at the left
;
; Witness: L1 41015 (c1, empty, fuel, kb, trail1, trails, warp).
PlaceClipped:
  LD A,(ClipCode)
  CP $00
  JP NZ,l_8BDE
  CALL BufferAddr
  LD (DestAddr),HL
  LD HL,ListModes
  LD (ModeVector),HL
  LD A,(ItemFlags)
  BIT 7,A
  JP Z,l_8BC5
  CALL LoadMask
  LD HL,ListModes+$0008
  LD (ModeVector),HL
l_8BC5:
  CALL SpriteGo
  LD A,(ItemFlags)
  BIT 0,A
  RET Z
  LD DE,$0000
  LD (ClipSkip),DE
  LD A,(SpriteWidth)
  LD (ClipWidth),A
  JP DeferAttrs
l_8BDE:
  CP $03
  JP NZ,l_8C35
  CALL BufferAddr
  LD (DestAddr),HL
  LD A,(SpriteX)
  AND $07
  LD E,A
  LD A,(SpriteAdvance)
  ADD A,E
  SRL A
  SRL A
  SRL A
  ADD A,$01
  LD (ClipWidth),A
  LD A,(SpriteAdvance)
  PUSH AF
  LD A,(ItemFlags)
  BIT 7,A
  CALL NZ,LoadMask
  POP AF
  LD (SpriteAdvance),A
  LD HL,ListModes+$0002
  LD (ModeVector),HL
  LD A,(ItemFlags)
  BIT 7,A
  JP Z,l_8C22
  LD HL,ListModes+$000A
  LD (ModeVector),HL
l_8C22:
  CALL SpriteGo
  LD A,(ItemFlags)
  BIT 0,A
  RET Z
  LD DE,$0000
  LD (ClipSkip),DE
  JP DeferAttrs
l_8C35:
  CP $04
  RET NZ
  LD A,(SpriteX)
  PUSH AF
  XOR $07
  ADD A,$01
  AND $07
  LD (SpriteX),A
  CALL BufferAddr
  LD (DestAddr),HL
  LD A,(SpriteAdvance)
  PUSH AF
  LD A,(ItemFlags)
  BIT 7,A
  CALL NZ,LoadMask
  POP AF
  LD (SpriteAdvance),A
  LD HL,DrawModes
  LD (ModeVector),HL
  CALL SpriteGo
  POP AF
  SUB $01
  AND $F8
  SRL A
  SRL A
  SRL A
  ADD A,$01
  LD E,A
  LD A,(SpriteWidth)
  SUB E
  LD (ClipWidth),A
  LD A,(ClipWidth)
  LD E,A
  LD A,(SpriteWidth)
  SUB E
  LD E,A
  LD D,$00
  LD (ClipSkip),DE
  LD HL,(SpriteData)
  ADD HL,DE
  LD (SpriteData),HL
  LD HL,(MaskData)
  ADD HL,DE
  LD (MaskData),HL
  LD HL,(ListModes+$0002)
  LD A,(ItemFlags)
  BIT 7,A
  JP Z,l_8CA4
  LD HL,(ListModes+$000A)
l_8CA4:
  LD DE,l_8CA4+$0005
  PUSH DE
  JP (HL)
  LD A,(ItemFlags)
  BIT 0,A
  RET Z
  JP DeferAttrs

; JP (SpriteCall)
;
; Witness: L1 110989 (c1, empty, fuel, kb, trail1, trails, warp).
SpriteGo:
  LD HL,(SpriteCall)
  JP (HL)

; MaskData = the sprite (SpriteNum + the flags' mask offset)'s bytes
;
; Witness: L1 1979 (c1, empty, fuel, kb, trail1, trails, warp).
LoadMask:
  LD A,(ItemFlags)
  AND $1E
  SRL A
  LD E,A
  LD A,(SpriteNum)
  PUSH AF
  ADD A,E
  LD (SpriteNum),A
  LD HL,DrawModes
  LD (ModeVector),HL
  CALL SpriteGo
  LD HL,(SpriteData)
  LD (MaskData),HL
  POP AF
  LD (SpriteNum),A
  RET

; Copy BufferP1 to the screen's top half ($4021)
;
; Witness: L1 5351 (c1, empty, fuel, kb, trail1, trails, warp).
CopyBufferP1:
  LD HL,BufferP1
  LD DE,Screen+33
  LD BC,$06E0
  JP CopyLines

; Copy BufferP2 to the bottom half ($48A1)
;
; Witness: L1 814 (kb).
CopyBufferP2:
  LD HL,BufferP2
  LD DE,Screen+2209
  LD BC,$06E0
  JP CopyLines

; Copy BC bytes from HL to the screen at DE, 22 a line (22 LDIs), DE down a
; line each
;
; Witness: L1 507680 (c1, empty, fuel, kb, menu, trail1, trails, warp).
CopyLines:
  PUSH DE
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  LDI
  POP DE
  CALL NextLineDE
  LD A,B
  OR C
  JR NZ,CopyLines
  RET

; Zero BufferP1 by PUSH (SP from $F71C down)
;
; Witness: L1 5437 (c1, empty, fuel, kb, menu, trail1, trails, warp).
ClearBufferP1:
  LD (SavedSp),SP
  LD SP,BufferP1+$06E0    ; the first buffer's end
  JP ClearByPush

; Zero BufferP2 (SP from $FDFC)
;
; Witness: L1 813 (kb).
ClearBufferP2:
  LD (SavedSp),SP
  LD SP,BufferP2+$06E0    ; the buffer's end, not the tune player's data
  JP ClearByPush
; This entry point is used by the routine at ClearBufferP1.
ClearByPush:
  LD HL,$0000             ; 80 x 11 pushes of zero
  LD B,$50
l_8D41:
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
  DJNZ l_8D41
  LD SP,(SavedSp)
  RET

; OR a sprite into the buffer
;
; Witness: L1 41154 (c1, empty, fuel, kb, menu, trail1, trails, warp).
OrBuffer:
  LD DE,(SpriteData)
  LD HL,(DestAddr)
  LD A,(SpriteHeight)
  LD C,A
l_8D5E:
  LD A,(SpriteWidth)
  LD B,A
  PUSH HL
l_8D63:
  LD A,(DE)
  OR (HL)
  LD (HL),A
  INC DE
  INC HL
  DJNZ l_8D63
  POP HL
  PUSH DE
  LD DE,$0016
  ADD HL,DE
  POP DE
  DEC C
  JP NZ,l_8D5E
  RET

; OR a clipped sprite into the buffer
;
; Witness: L1 11497 (c1, empty, fuel, kb, trail1, trails, warp).
OrBufferClip:
  LD HL,(SpriteData)
  LD DE,(DestAddr)
  LD A,(SpriteHeight)
  LD C,A
l_8D81:
  PUSH BC
  PUSH HL
  PUSH DE
  LD A,(ClipWidth)
  LD B,A
l_8D88:
  LD A,(DE)
  OR (HL)
  LD (DE),A
  INC DE
  INC HL
  DJNZ l_8D88
  POP HL
  LD BC,$0016
  ADD HL,BC
  EX DE,HL
  POP HL
  LD BC,(SpriteWidth)
  LD B,$00
  ADD HL,BC
  POP BC
  DEC C
  JP NZ,l_8D81
  RET

; Draw a trail list: skip the items behind, draw the ones on screen, stop at
; the first beyond
;
; ListBase the list, ListIndexPtr its index word (the first item not yet
; behind), ListScroll the distance. From the index item each item goes through
; PlaceItem: 2 (behind the left edge) moves the index on by 6, 1 (beyond the
; right edge) ends the walk; drawn items go to PlaceClipped or a deferred list
; by ItemFlags. Twice a pass a player (DistanceIndex for list A, ScenIndex for
; list B).
;
; Witness: L1 12323 (c1, empty, fuel, kb, trail1, trails, warp).
WalkList:
  LD HL,(ListIndexPtr)
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD HL,(ListBase)
  ADD HL,BC
  PUSH HL
  POP IY
  LD A,(IY+$01)
  CP $FF
  JP Z,l_8E10
  CALL PlaceItem
  CP $02
  JP Z,l_8DC3
  JP l_8E10
l_8DC3:
  LD DE,$0006
  ADD IY,DE
l_8DC8:
  LD A,(IY+$01)
  CP $FF
  RET Z
  CALL PlaceItem
  CP $02
  PUSH AF
  CALL Z,NextIndex
  POP AF
  CP $01
  RET Z
l_8DDB:
  CP $02
  JP Z,l_8DFC
  LD A,(ItemFlags)
  BIT 6,A
  JP NZ,l_8DF3
  BIT 5,A
  JP NZ,l_8DF9
  CALL PlaceClipped
  JP l_8DFC
l_8DF3:
  CALL DeferA
  JP l_8DFC
l_8DF9:
  CALL DeferB
l_8DFC:
  LD DE,$0006
  ADD IY,DE
  LD A,(IY+$01)
  CP $FF
  RET Z
  CALL PlaceItem
  CP $01
  JP NZ,l_8DDB
  RET
l_8E10:
  LD HL,(ListIndexPtr)
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD DE,$0006
  XOR A
  RRA
  SBC HL,DE
  JP C,l_8DC8
  EX DE,HL
  LD HL,(ListIndexPtr)
  LD (HL),E
  INC HL
  LD (HL),D
  JP WalkList

; The index word + 6
;
; Witness: L1 272 (c1, fuel, kb, trail1, trails, warp).
NextIndex:
  LD HL,(ListIndexPtr)
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH HL
  LD HL,$0006
  ADD HL,DE
  EX DE,HL
  POP HL
  LD (HL),D
  DEC HL
  LD (HL),E
  RET

; Set up an item: its sprite (or AnimObject's), flags, y, advance; x = its
; distance - ListScroll; the clip code
;
; A = 0 inside, 1 beyond the right (x > $AF), 2 behind the left, 3 / 4 cut at
; an edge. A y below the sprite's height is a broken list: ItemTooLow.
;
; Witness: L1 67402 (c1, empty, fuel, kb, trail1, trails, warp).
PlaceItem:
  LD HL,GameSprite
  LD (SpriteCall),HL
  LD A,$02
  LD (ItemFlags),A
  LD A,(IY+$04)
  LD C,A
  LD (SpriteNum),A
  LD A,(IY+$05)
  AND $F0
  CP $00
  JP Z,l_8E5E
  CALL AnimObject
  JP l_8E8C
l_8E5E:
  LD A,(IY+$05)
  BIT 0,A
  JP Z,l_8E74
  LD HL,MenuSprite
  LD (SpriteCall),HL
  LD A,(ItemFlags)
  OR $01
  LD (ItemFlags),A
l_8E74:
  LD A,(IY+$05)
  AND $0E
  JP Z,l_8E8C
  SLA A
  SLA A
  SLA A
  SLA A
  LD E,A
  LD A,(ItemFlags)
  OR E
  LD (ItemFlags),A
l_8E8C:
  PUSH IY
  POP HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  LD (SpriteY),A
  INC HL
  LD A,(HL)
  LD (SpriteAdvance),A
  EX DE,HL
  PUSH HL
  LD HL,DrawModes
  LD (ModeVector),HL
  CALL SpriteGo
  LD A,(SpriteHeight)
  LD E,A
  LD A,(SpriteY)
  CP E
  JP NC,PlaceItemX
ItemTooLow:
  LD A,$02                ; red border, SP = $6334, JP Restart (known only from
                          ; the code)
  OUT ($FE),A
  LD SP,StackBelowImage
  JP RestartJump

; Two instructions no path reaches (SpriteY = SpriteHeight)
;
; Known only from the code.
PlaceItemDead:
  LD A,(SpriteHeight)
  LD (SpriteY),A

; x and the clip code
;
; Witness: L1 67402 (c1, empty, fuel, kb, trail1, trails, warp).
PlaceItemX:
  POP HL
  LD DE,(ListScroll)
  XOR A
  RRA
  SBC HL,DE
  LD (SpriteX),HL
  JP C,l_8EEE
  LD A,H
  CP $00
  JP NZ,l_8F0E
  LD A,$AF
  SUB L
  JP C,l_8F0E
  LD E,A
  LD A,(SpriteAdvance)
  ADD A,$08
  SUB E
  JP C,l_8F09
  LD A,E
  LD (SpriteAdvance),A
  JP l_8F1A
l_8EEE:
  EX DE,HL
  LD HL,$0000
  XOR A
  RRA
  SBC HL,DE
  LD (SpriteX),HL
  LD A,H
  CP $00
  JP NZ,l_8F14
  LD A,(SpriteAdvance)
  SUB L
  JP C,l_8F14
  JP l_8F20
l_8F09:
  XOR A
  LD (ClipCode),A
  RET
l_8F0E:
  LD A,$01
  LD (ClipCode),A
  RET
l_8F14:
  LD A,$02
  LD (ClipCode),A
  RET
l_8F1A:
  LD A,$03
  LD (ClipCode),A
  RET
l_8F20:
  LD A,$04
  LD (ClipCode),A
  RET

; 54 bytes before the bank: code no path reaches, a leftover of an earlier
; build (it calls $9475, $9523 and reads $63F3)
GfxLeftover:
  DEFB $C9,$8F,$06,$12,$CD,$75,$94,$CD
  DEFB $23,$95,$3A,$F3,$63,$D6,$01,$32
  DEFB $F3,$63,$3E,$55,$32,$A0,$63,$06
  DEFB $02,$CD,$75,$94,$CD,$95,$71,$CD
  DEFB $65,$95,$C9,$E5,$11,$64,$00,$CD
  DEFB $2B,$64,$79,$CD,$80,$8F,$3A,$1D
  DEFB $64,$1E,$64,$CD,$40,$64

; The in-game sprite bank: 203 sprites (the ATV, the rider, the ground pieces,
; the obstacles, the scenery, the font, the digits)
;
; +0 the count (203), +1 the bank's length word ($471E: it ends at $D67A), +3
; zero, from +4 a word a sprite: its header's offset from $8F5C. Headers as
; SpriteHeader reads them; the shift byte (+3) is 0 in the image and changes in
; play. Twelve gaps of two or four bytes between sprites and the 54 bytes
; $D67A-$D6AF after the last are bytes no offset reaches (the end of a sprite's
; bytes in an older bank).
;
; ZXDB POKE 49433,81 ("infinite fuel") writes $51 over byte 46 of sprite 126
; ($C119, its line 7): a pixel byte, no effect on the fuel (recording pokes).
GameGfx:
  INCBIN "res/sprites/game.bin",$0000,18260

  ORG $DBD1

; A = y; clip a sprite at the play area's top (y $50): drop the lines above it
;
; Witness: L1 19368 (c1, empty, fuel, kb, trail1, trails, warp).
ClipY:
  CP $50
  JR C,l_DBD8
  CALL ClipTop
l_DBD8:
  LD (SpriteY),A
  CALL JpBufferAddr
  LD (DestAddr),HL
  RET

; Cut the sprite's lines above the play area
;
; Witness: L1 70 (c1, fuel, kb, trail1, trails, warp).
ClipTop:
  SUB $4F
  LD E,A
  LD A,(SpriteHeight)
  SUB E
  JR C,l_DBEF
  JR Z,l_DBEF
  JR l_DBF2
l_DBEF:
  POP AF
  POP AF
  RET
l_DBF2:
  LD (SpriteHeight),A
  LD A,(SpriteWidth)
  CALL JpMultiply
  EX DE,HL
  LD HL,(SpriteData)
  ADD HL,DE
  LD (SpriteData),HL
  LD HL,(MaskData)
  ADD HL,DE
  LD (MaskData),HL
  LD A,$4F
  RET

; The tumbling ATV's height offsets (6 bytes)
TumbleOffsets:
  DEFB $09,$09,$00,$0B,$0D,$00

; The ATV sprite's y from its height and frame (the tumble's offsets, the
; nose-down frames' WheelOffsets)
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
AtvY:
  LD A,(AtvFrame)
  CP $7D
  JR C,l_DC44
  CP $88
  JR NC,l_DC44
  SUB $7D
  SRL A
  LD E,A
  LD D,$00
  LD HL,TumbleOffsets
  ADD HL,DE
  LD E,(HL)
  LD A,(SpriteHeight)
  ADD A,$01
  LD D,A
  LD A,(AtvHeight)
  SUB E
  ADD A,$20
  LD (SpriteY),A
  CP D
  JP NC,ClipY
  LD A,D
  LD (SpriteY),A
  JP ClipY
l_DC44:
  LD B,$00
  LD A,(AtvFrame)
  CP $46
  JR C,l_DC5B
  CP $4E
  JR NC,l_DC5B
  SUB $38
  LD E,A
  LD D,$00
  LD HL,WheelOffsets+$0001
  ADD HL,DE
  LD B,(HL)
l_DC5B:
  LD A,(SpriteHeight)
  LD E,A
  LD A,(AtvHeight)
  ADD A,B
  ADD A,E
  CP E
  JP NC,ClipY
  LD A,(SpriteHeight)
  JP ClipY

; The rider sprite's y from his height
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
RiderY:
  LD A,(SpriteHeight)
  LD E,A
  LD A,(RiderHeight)
  ADD A,$01
  ADD A,E
  CP E
  JP NC,ClipY
  LD A,(SpriteHeight)
  JP ClipY

; DrawAtv, then DrawRider
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
DrawAtvAndRider:
  CALL DrawAtv
  JP DrawRider

; The ATV: body and wheels, mirrored when it faces left
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
DrawAtv:
  LD A,(Facing)
  CP $01
  JP Z,l_DCEC
  LD HL,DrawModes
  LD (ModeVector),HL
  LD A,(AtvX)
  LD (SpriteX),A
  LD A,(AtvFrame)
  ADD A,$01
  LD (SpriteNum),A
  CALL JpGameSprite
  LD HL,(SpriteData)
  LD (MaskData),HL
  LD A,(AtvFrame)
  LD (SpriteNum),A
  LD HL,DrawModes
  LD (ModeVector),HL
  CALL JpGameSprite
  CALL AtvY
  LD HL,(SpriteData)
  LD BC,(SpriteWidth)
  LD B,$00
  ADD HL,BC
  LD (SpriteData),HL
  LD A,(SpriteHeight)
  SUB $01
  LD (SpriteHeight),A
  LD DE,DrawAtv+$0054
  PUSH DE
  LD HL,(ListModes+$0004)
  JP (HL)
  LD A,(SpriteX)
  ADD A,$05
  LD (SpriteX),A
  LD A,$7A
  LD (SpriteNum),A
  JP Wheels
l_DCEC:
  LD HL,DrawModes
  LD (ModeVector),HL
  LD A,(AtvX)
  AND $F8
  LD E,A
  LD A,(AtvX)
  AND $07
  XOR $07
  LD A,E
  LD (SpriteX),A
  LD A,(AtvFrame)
  ADD A,$01
  LD (SpriteNum),A
  CALL JpGameSprite
  LD HL,(SpriteData)
  LD (MaskData),HL
  LD A,(AtvFrame)
  LD (SpriteNum),A
  CALL JpGameSprite
  CALL AtvY
  LD HL,(DestAddr)
  INC HL
  INC HL
  LD (DestAddr),HL
  LD HL,(SpriteData)
  LD BC,(SpriteWidth)
  LD B,$00
  ADD HL,BC
  LD (SpriteData),HL
  LD A,(SpriteHeight)
  SUB $01
  LD (SpriteHeight),A
  LD DE,DrawAtvUnused
  PUSH DE
  LD HL,(ListModes+$0006)
  JP (HL)

; Four instructions after DrawAtv's left-facing path that no jump reaches: x +
; 8, sprite $79, JP Wheels
;
; Known only from the code.
DrawAtvUnused:
  LD A,(SpriteX)
  ADD A,$08
  LD (SpriteX),A
  LD A,$79
  LD (SpriteNum),A
  JP Wheels

; The wheels under the body for the upright frames ($38-$4F)
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
Wheels:
  LD A,(AtvFrame)
  CP $38
  RET C
  CP $50
  RET NC
  LD A,(EngineNote)
  AND $80
  RET NZ
  CALL JpGameSprite
  CALL WheelY
  LD DE,Wheels+$001D
  PUSH DE
  LD HL,(DrawModes+$000A)
  JP (HL)
  LD A,(SpriteNum)
  SUB $2B
  LD (SpriteNum),A
  CALL JpGameSprite
  CALL WheelY
  LD HL,(DrawModes+$000A)
  JP (HL)

; The wheels' y
;
; Witness: L1 7048 (c1, empty, fuel, kb, trail1, trails, warp).
WheelY:
  LD A,(SpriteHeight)
  ADD A,$02
  LD E,A
  LD A,(AtvHeight)
  ADD A,E
  CP E
  JP NC,ClipY
  LD A,E
  JP ClipY

; The rider: walking, riding, thrown or lying, mirrored by RiderFacing
;
; Witness: L1 6160 (c1, empty, fuel, kb, trail1, trails, warp).
DrawRider:
  LD A,(AtvFrame)
  CP $5C
  RET Z
  LD A,(RiderFacing)
  CP $01
  JR Z,l_DDE0
  LD HL,DrawModes
  LD (ModeVector),HL
  LD A,(RiderX)
  LD (SpriteX),A
  LD A,(RiderFrame)
  ADD A,$09
  CP $12
  JR C,l_DDBA
  SUB $08
l_DDBA:
  LD (SpriteNum),A
  CALL JpGameSprite
  LD HL,(SpriteData)
  LD (MaskData),HL
  LD A,(RiderFrame)
  LD (SpriteNum),A
  LD HL,DrawModes
  LD (ModeVector),HL
  CALL JpGameSprite
  CALL RiderY
  LD DE,RiderDrawn
  PUSH DE
  LD HL,(ListModes+$0004)
  JP (HL)
l_DDE0:
  LD HL,DrawModes
  LD (ModeVector),HL
  LD A,(RiderX)
  AND $F8
  LD E,A
  LD A,(RiderX)
  AND $07
  XOR $07
  OR E
  LD (SpriteX),A
  LD A,(RiderFrame)
  ADD A,$09
  CP $12
  JR C,l_DE02
  SUB $08
l_DE02:
  LD (SpriteNum),A
  CALL JpGameSprite
  LD HL,(SpriteData)
  LD (MaskData),HL
  LD A,(RiderFrame)
  LD (SpriteNum),A
  CALL JpGameSprite
  CALL RiderY
  LD HL,(DestAddr)
  INC HL
  INC HL
  LD (DestAddr),HL
  LD DE,RiderDrawn
  PUSH DE
  LD HL,(ListModes+$0006)
  JP (HL)
RiderDrawn:
  RET                     ; DrawRider's return point (pushed before the masked
                          ; draw)
RiderSave:
  LD A,(RiderHeight)      ; RiderSavedHeight / RiderSavedX = now (RiderUpdate
                          ; pushes it as its return)
  LD (RiderSavedHeight),A
  LD A,(RiderX)
  LD (RiderSavedX),A
  RET

  ORG $F03C

; The first player's buffer, 22 x 80 bytes ($F03C-$F71B), cleared before each
; use; in the image: $FF and $C4 bytes of $60 (leftovers), zeros, and trail 6
; from $F230
BufferP1:
  DEFB $FF,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60,$60
  DEFB $60,$60,$60,$60,$60

; zeros (the buffer's middle)
BufferP1Zeros:
  DEFS $012F

; Trail 6 (SWAMP) as loaded: GameEntry copies $F230-$F4B9 to $60AC, where its
; addresses point
;
; Its record and lists; its last 147 bytes ($F427-$F4B9, the copy's
; $62A3-$6335) are assembler source text ("LD A,1", "JR MRIGHT", "RIGHT2:LD
; A,(BDIR)", "CP BOB+8"): the bytes after the trail in the developer's memory,
; copied along and never read.
Trail6Image:
  INCBIN "res/trails/trail6.bin",$0000,650

; one byte of the same source text after the copied range
BufferP1Byte:
  DEFB $41

; zeros to BufferP2
BufferP1Rest:
  DEFS $0261

; The second player's buffer, 22 x 80 bytes ($F71C-$FDFB): zeros in the image
; up to the tune player at $F850, which it overwrites in play
BufferP2:
  DEFS $0134
