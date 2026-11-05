; --------------------------------------------------------------------------------------------------------------------
; menus.asm: the boot menu, the help menu, the pointer, the controls
;
; BootMenu installs the interrupt and shows its picture; its loop reads the keys 1-3 (half row $F7FE): 1 LeaveForGame
; (print.asm), 2 HelpMenu, 3 PlaySample (boot.asm). The help menu is a picture with seven empty bars; HelpMenu prints
; the item names into them at once (TypeAtOnce = 1) and runs a loop a frame: the arrow pointer is drawn (DrawPointer),
; the controls read (ReadControls), the pointer moved (MovePointer), a HALT, the pointer erased (ErasePointer);
; without fire the bar under the pointer is lit (FindItem, HighlightItem: ink and paper of its cells swapped), with
; fire RunItem jumps to the lit bar's routine through ItemRoutines.
;
; The pointer is a 16-line, 8-pixel arrow (PointerSprite, mask and image) drawn over the screen with the 16 x 2 bytes
; under it saved (PointerUnder); its place is Pointer (x, y in pixels, the hot spot one pixel right and down of the
; arrow's corner), kept within PointerLimits. It starts at x 195, y 55 (BootMenu) and stays where it was when a help
; item returns. It moves Speed pixels a frame: 1 at first, one more every 8 frames the same direction is held, at most
; 10; a change of the controls starts again at 1.
;
; The controls (Controls: bit 0 right, 1 left, 2 down, 3 up, 4 fire) are Q A O P and SPACE together with either the
; keys 6 7 8 9 0 (the Sinclair joystick: left, right, down, up, fire) or, with CAPS SHIFT held, the cursor keys 5 6 7
; 8 and 0. There is no Kempston read. The item's hit boxes (ItemBoxes) are the bars' text cells: columns 9-22 of rows
; 7, 9, ... 19.
; --------------------------------------------------------------------------------------------------------------------

; the boot menu: the tune's init again, the IM 2 interrupt, then ShowBootMenu
;
; From Start. Calls bank 1's $C000 (the player's init: the boot tune from its
; start), fills Im2Table with $60 (257 bytes), I = $5B, IM 2, EI and a HALT:
; BootInterrupt plays from the next frame on. Falls into ShowBootMenu.
BootMenu:
  LD A,$11                ; bank 1
  CALL SetPage
  CALL BANK_WINDOW        ; the tune from its start
  LD A,$10                ; bank 0
  CALL SetPage
  LD HL,Im2Table
  LD DE,Im2Table+1
  LD (HL),$60             ; every byte $60: whatever the data bus holds, the
                          ; vector read is $6060
  LD BC,256
  LDIR
  LD A,$5B                ; I = $5B
  LD I,A
  IM 2
  EI
  HALT                    ; the first BootInterrupt

; the boot menu's picture, the pointer's start, the key loop
;
; Also help item 7 ("Выход", through ItemRoutines). Border black, ClearScreen,
; BootMenuPicture, Pointer = x 195, y 55 (where the help menu will show it).
; The loop reads the half row 1-5: 1 LeaveForGame, 2 HelpMenu, 3 PlaySample and
; on; nothing waits for a key's release, so key 3 held plays the sample again
; and again.
ShowBootMenu:
  XOR A
  OUT ($FE),A             ; border black
  CALL ClearScreen
  LD HL,BootMenuPicture
  CALL ScreenDepack
  LD DE,55*256+195        ; y 55, x 195
  LD (Pointer),DE
BootMenuKeys:
  LD BC,$F7FE             ; the half row 1-5
  IN A,(C)
  RRA                     ; key 1: the game
  JP NC,LeaveForGame
  RRA                     ; key 2: the help
  JP NC,HelpMenu
  RRA                     ; key 3: the sample
  CALL NC,PlaySample
  JR BootMenuKeys

; the help menu: its picture, the items printed into the bars, the pointer loop
;
; Reached from ShowBootMenu (key 2), from every help item's end, from SPACE
; while a page types (PrintString) or after it (WaitPageKey): SP is set again,
; so nothing left on the stack matters. Border black, ClearScreen,
; HelpMenuPicture; TypeAtOnce = 1, the seven names and the copyright line
; printed at their places (row, column in 4-pixel cells: 7,25 9,22 11,19 13,20
; 15,24 17,28 19,29 and 22,8: each name centred on its bar); ResetPointerSpeed,
; LitItem = none. Then a frame a turn: DrawPointer, ReadControls, MovePointer,
; HALT; with fire RunItem (it does not come back when a bar is lit), else
; FindItem and HighlightItem; ErasePointer. The pointer is visible from the
; frame's start to its HALT, so the HALT shows it.
HelpMenu:
  LD SP,Stack+284         ; the stack from its top: the help menu is a fresh
                          ; start
  XOR A
  OUT ($FE),A             ; border black
  CALL ClearScreen
  LD HL,HelpMenuPicture
  CALL ScreenDepack
  LD A,$01                ; the names print at once
  LD (TypeAtOnce),A
  LD DE,7*256+25          ; row 7, column 25
  LD (PrintAt),DE
  LD HL,MenuDescription
  CALL PrintString
  LD DE,9*256+22          ; row 9, column 22
  LD (PrintAt),DE
  LD HL,MenuProduction
  CALL PrintString
  LD DE,11*256+19         ; row 11, column 19
  LD (PrintAt),DE
  LD HL,MenuComponents
  CALL PrintString
  LD DE,13*256+20         ; row 13, column 20
  LD (PrintAt),DE
  LD HL,MenuProgramming
  CALL PrintString
  LD DE,15*256+24         ; row 15, column 24
  LD (PrintAt),DE
  LD HL,MenuFeatures
  CALL PrintString
  LD DE,17*256+28         ; row 17, column 28
  LD (PrintAt),DE
  LD HL,MenuCredits
  CALL PrintString
  LD DE,19*256+29         ; row 19, column 29
  LD (PrintAt),DE
  LD HL,MenuExit
  CALL PrintString
  LD DE,22*256+8          ; the copyright line, row 22, column 8
  LD (PrintAt),DE
  LD HL,MenuCopyright
  CALL PrintString
  CALL ResetPointerSpeed  ; the pointer at 1 pixel a frame
  LD A,$FF                ; no bar lit
  LD (LitItem),A
HelpLoop:
  CALL DrawPointer
  CALL ReadControls
  CALL MovePointer
  HALT                    ; one frame with the pointer shown
  LD A,(Controls)
  AND $10                 ; fire?
  JR NZ,HelpFire
  CALL FindItem           ; no: the bar under the pointer, lit
  CALL HighlightItem
  CALL ErasePointer       ; the screen as it was for the next frame's pointer
  JR HelpLoop
HelpFire:
  CALL RunItem            ; RunItem does not come back when a bar is lit
  CALL ErasePointer
  JR HelpLoop

; the item under the pointer: A = 1-7, or $FF (CurrentItem then counts 8)
;
; The pointer's x and y divided by 8 give the cell; each ItemBoxes record
; (column, row, width) is tried: the cell's column within the box's and its row
; equal. CurrentItem counts the records from 1.
FindItem:
  LD IX,ItemBoxes
  LD A,$01                ; CurrentItem = 1
  LD (CurrentItem),A
  LD HL,(Pointer)         ; L = x, H = y
  SRL H                   ; H = y / 8: the cell's row
  SRL H
  SRL H
  LD A,H
  SRL L                   ; L = x / 8: its column
  SRL L
  SRL L
  LD H,L                  ; H = the column, L = the row
  LD L,A
FindItemNext:
  LD A,(IX+$00)           ; the box's first column ($FF: no more boxes, A =
                          ; $FF)
  CP $FF
  RET Z
  LD D,A
  LD A,H
  CP D
  JR C,FindItemSkip       ; left of the box
  LD A,D
  LD B,(IX+$02)
  DEC B
  ADD A,B                 ; A = its last column
  CP H
  JR C,FindItemSkip       ; right of it
  LD A,(IX+$01)           ; its row
  CP L
  JR NZ,FindItemSkip
  LD A,(CurrentItem)      ; A = the item
  RET
FindItemSkip:
  LD DE,$0003             ; the next record
  ADD IX,DE
  LD A,(CurrentItem)      ; CurrentItem + 1
  INC A
  LD (CurrentItem),A
  JR FindItemNext

; light the bar of item A (or none, $FF), the old one put back
;
; When A is LitItem nothing changes. Else the old lit bar (if any) is inverted
; back (InvertItem) and LitItem = A; the new one is inverted when it is a bar.
HighlightItem:
  LD L,A
  LD A,(LitItem)
  CP L                    ; the same bar: nothing to do
  RET Z
  CP $FF                  ; none lit yet
  JR Z,FirstLit
  PUSH AF                 ; LitItem = the new one
  LD A,L
  LD (LitItem),A
  POP AF
  CALL InvertItem         ; the old bar back
; This entry point is used by the routine at InvertItem.
InvertLit:
  LD A,(LitItem)          ; the new bar (none: done)
  CP $FF
  RET Z

; swap ink and paper over item A's bar
;
; IX = its ItemBoxes record; InvertCells at its column and row, its width
; cells.
InvertItem:
  DEC A
  LD H,$00
  LD L,A
  PUSH HL
  POP DE
  ADD HL,HL               ; HL = (A - 1) * 3
  ADD HL,DE
  EX DE,HL
  LD IX,ItemBoxes         ; IX = the record
  ADD IX,DE
  LD H,(IX+$00)           ; H = the column, L = the row
  LD L,(IX+$01)
  CALL InvertCells
  RET
; This entry point is used by the routine at HighlightItem.
FirstLit:
  LD A,L                  ; LitItem = the new one
  LD (LitItem),A
  JR InvertLit

; swap ink and paper of (IX + 2) cells from column H, row L
;
; The attribute address $5800 + row * 32 + column, computed from H and L. The
; first cell's attribute, swapped, is written to all the cells; bright and
; flash are dropped (the bars have neither).
InvertCells:
  LD A,H                  ; A = the column
  ADD HL,HL               ; L = row * 8 (rows 0-23 fit a byte)
  ADD HL,HL
  ADD HL,HL
  LD H,$16                ; H = $16: HL * 4 = $5800 + row * 32
  ADD HL,HL
  ADD HL,HL
  ADD A,L                 ; + the column
  LD L,A
  LD A,(HL)               ; the first cell's attribute
  PUSH AF
  AND $07                 ; the ink becomes the paper
  SLA A
  SLA A
  SLA A
  LD D,A
  POP AF
  AND $38                 ; the paper becomes the ink
  SRA A
  SRA A
  SRA A
  OR D
  LD B,(IX+$02)           ; the width
InvertCellsNext:
  LD (HL),A               ; every cell of the bar
  INC HL
  DJNZ InvertCellsNext
  RET

; fire: jump to the lit item's routine, dropping the caller (nothing lit:
; return)
;
; The routine's address from ItemRoutines; PUSH; RET. The routines end with JP
; HelpMenu (item 7 is ShowBootMenu itself), which sets SP again.
RunItem:
  LD A,(LitItem)
  CP $FF
  RET Z                   ; nothing lit: back to the loop
  POP HL                  ; HelpLoop's return address dropped
  DEC A
  ADD A,A
  LD D,$00
  LD E,A
  LD HL,ItemRoutines      ; the item's routine
  ADD HL,DE
  LD E,(HL)
  INC HL
  LD D,(HL)
  PUSH DE                 ; into it
  RET

; the seven bars' hit boxes: column, row, width in 8-pixel cells
;
; Columns 9-22 (14 cells) of rows 7, 9, 11, 13, 15, 17, 19; $FF ends the table.
ItemBoxes:
  DEFB $09,$07,$0E
  DEFB $09,$09,$0E
  DEFB $09,$0B,$0E
  DEFB $09,$0D,$0E
  DEFB $09,$0F,$0E
  DEFB $09,$11,$0E
  DEFB $09,$13,$0E
  DEFB $FF                ; the end

; the seven items' routines, in the menu's order
;
; HelpDescription, HelpProduction, HelpComponents, HelpProgramming,
; HelpFeatures, HelpCredits, ShowBootMenu ("Выход").
ItemRoutines:
  DEFW HelpDescription
  DEFW HelpProduction
  DEFW HelpComponents
  DEFW HelpProgramming
  DEFW HelpFeatures
  DEFW HelpCredits
  DEFW ShowBootMenu

; FindItem's count: the item under the pointer, 8 past the last
CurrentItem:
  DEFB $00

; the lit bar's item, $FF none (RunItem's choice)
LitItem:
  DEFB $00

; ten HALTs: no code calls it
;
; A routine left in the image: LD B,10, HALT, DJNZ, RET. Not referenced (the
; bytes $3A,$AC appear nowhere) and never run.
WaitFrames:
  LD B,$0A
WaitFramesNext:
  HALT
  DJNZ WaitFramesNext
  RET

; Speed = SpeedStart: the pointer at 1 pixel a frame again
;
; Also reached from PointerAcceleration when the controls change or no
; direction is held.
ResetPointerSpeed:
  LD HL,SpeedStart
  LD DE,Speed
  LD BC,3
  LDIR
  RET

; move the pointer by the controls: x first, then y, Speed pixels, clamped
;
; Controls' bits: 0 right, 1 left, 2 down, 3 up. PointerAcceleration first. A
; direction counts only alone on its axis (B = C XOR (C >> 1 AND 5): right with
; left cancel, down with up). StepAxis moves x (DE = Pointer, HL = its limits),
; then y (Pointer + 1, the y limits).
MovePointer:
  LD A,(Controls)
  PUSH AF
  CALL PointerAcceleration ; the speed for these controls
  POP AF
  LD C,A                  ; C = the controls
  RRCA                    ; B bit 0: right XOR left, bit 2: down XOR up
  AND $05
  XOR C
  LD B,A
  RRCA                    ; carry: x moves
  LD HL,PointerLimits     ; x's limits
  LD DE,Pointer
  PUSH BC
  CALL C,StepAxis         ; C bit 0 (right) adds, else (left) subtracts
  POP BC
  RRC C                   ; C bit 0 now: down
  RRC C
  LD A,B
  RRCA                    ; carry (B bit 2): y moves
  RRCA
  RRCA
  INC DE                  ; y
  LD HL,PointerLimits+$0002 ; y's limits
  JR C,StepAxis
  RET

; A = the controls: speed up while the same controls are held
;
; LastInput = A. A change from the last frame (fire too), or no direction:
; ResetPointerSpeed. Else Speed's delay counts down; at 0 it is reloaded (8
; frames) and, while the steps left (10 at the start) last, Speed's step grows
; by one: 1 pixel a frame, 2 after 8 frames, at most 10 after 72.
PointerAcceleration:
  LD BC,(LastInput)       ; C = the last frame's controls (B, PointerAddress's
                          ; low byte, is not used)
  LD (LastInput),A        ; this frame's for the next
  CP C                    ; changed: start slow again
  JR NZ,ResetPointerSpeed
  AND $0F                 ; no direction: the same
  JR Z,ResetPointerSpeed
  LD HL,Speed             ; Speed's delay
  DEC (HL)
  RET NZ
  LD A,(SpeedStart)       ; 8 frames on
  LD (HL),A
  INC HL
  LD A,(HL)               ; steps left
  DEC A
  RET Z                   ; none left: the fastest
  LD (HL),A
  INC HL
  INC (HL)                ; one pixel faster
  RET

; move one coordinate (DE) by Speed's step: C bit 0 set adds, clear subtracts;
; clamp to (HL) and (HL + 1)
;
; Subtracting below the minimum or past 0 gives the minimum; adding up to the
; maximum or past 255 gives the maximum.
StepAxis:
  LD A,C
  RRCA                    ; carry: add (right, down)
  LD A,(Speed+2)          ; the step
  LD C,A
  LD A,(DE)
  JR C,StepUp
  SUB C                   ; subtract (left, up)
  JR C,ClampAxis          ; past 0
  LD (DE),A
  CP (HL)                 ; below the minimum
  JR C,ClampAxis
  RET
StepUp:
  ADD A,C                 ; add
  INC HL                  ; HL on the maximum
  JR C,ClampAxis          ; past 255
  LD (DE),A
  CP (HL)                 ; below the maximum: done
  RET C
ClampAxis:
  LD A,(HL)               ; the limit
  LD (DE),A
  RET

; save the 16 x 2 bytes under the pointer and draw it (mask and image) at
; Pointer
;
; The corner is one pixel left and up of Pointer (unless at 0). PointerAddress
; = the screen byte of the corner (where PointerUnder goes back); nothing is
; drawn when the corner is below the pixel area ($5800), and the drawing stops
; there. Each sprite line (PointerSprite: mask, image) is shifted to the pixel
; and laid over two screen bytes (AND the mask, OR the image); at column 31
; only the first byte. The save takes 16 lines even past the pixel area (reads
; only).
DrawPointer:
  LD DE,(Pointer)         ; E = x, D = y
  LD A,D                  ; y - 1 unless 0
  OR A
  JR Z,l_ACB8
  DEC D
l_ACB8:
  LD A,E                  ; x - 1 unless 0
  OR A
  JR Z,l_ACBD
  DEC E
l_ACBD:
  LD A,D                  ; HL = the screen address of the corner (x, y)
  RRA
  SCF
  RRA
  RRA
  AND $5F
  LD H,A
  XOR E
  AND $07
  XOR E
  RRCA
  RRCA
  RRCA
  LD L,A
  LD A,D
  XOR H
  AND $07
  XOR H
  LD H,A
  LD (PointerAddress),HL  ; for ErasePointer
  CP $58                  ; the corner below the pixel area: nothing drawn
  RET NC
  PUSH HL
  LD DE,PointerUnder      ; the bytes under the pointer
  LD BC,$10FF             ; B = 16 lines (C = $FF: the 32 LDIs leave B alone)
SaveUnder:
  LDI                     ; two bytes a line
  LDI
  DEC HL
  DEC HL
  CALL NextLineDown
  DJNZ SaveUnder
  POP HL
  LD A,(Pointer)          ; the shift: 8 - (x - 1) & 7, 1-8 (9 at x 0, which
                          ; PointerLimits keeps out)
  SUB $01
  JR C,l_ACF5
  AND $07
l_ACF5:
  SUB $08
  NEG
  LD B,A
  LD DE,PointerSprite     ; the sprite
  LD C,$10                ; 16 lines
DrawLine:
  EX DE,HL                ; HL = the sprite line, DE = the screen
  PUSH BC
  PUSH HL
  PUSH DE
  LD E,(HL)               ; D:E = $FF, the mask; H:L = 0, the image
  LD D,$FF
  INC HL
  LD L,(HL)
  LD H,$00
ShiftLine:
  SLL E                   ; SLL (undocumented: a 1 shifted in): the mask left
                          ; into D, the image into H
  RL D
  ADD HL,HL
  DJNZ ShiftLine
  LD B,H                  ; B:C = the image's two bytes
  LD C,L
  POP HL                  ; the left byte: AND the mask, OR the image
  LD A,(HL)
  AND D
  OR B
  LD (HL),A
  INC L                   ; past column 31 (L wraps to the next row): no right
                          ; byte
  LD A,L
  AND $1F
  JR Z,DrawLineNext
  LD A,(HL)               ; the right byte
  AND E
  OR C
  LD (HL),A
DrawLineNext:
  DEC L
  CALL NextLineDown
  POP DE
  POP BC
  INC DE
  INC DE
  LD A,H
  CP $58                  ; past the pixel area: stop
  RET NC
  DEC C
  JR NZ,DrawLine
  RET

; put back the bytes DrawPointer saved; PointerAddress then points past the
; pixels
;
; Stops at the pixel area's end as DrawPointer did. PointerAddress = $58xx
; afterwards, so a second erase restores nothing.
ErasePointer:
  LD HL,(PointerAddress)
  LD DE,PointerUnder
  LD B,$10
RestoreLine:
  LD A,H                  ; past the pixel area: stop
  CP $58
  RET NC
  LD A,(DE)
  LD (HL),A
  INC HL
  INC DE
  LD A,(DE)
  LD (HL),A
  INC DE
  DEC HL
  CALL NextLineDown
  DJNZ RestoreLine
  LD H,$58                ; a second erase stops at once
  LD (PointerAddress),HL
  RET

; HL = the screen address one pixel line down
;
; Past the screen's last line H becomes $58: the callers stop there.
NextLineDown:
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

; the pointer's x, y in pixels (192, 55 in the image; ShowBootMenu sets 195,
; 55)
Pointer:
  DEFB $C0,$37

; x 1-255, y 9-182
PointerLimits:
  DEFB $01,$FF
  DEFB $09,$B6

; Speed's start: the delay 8, the steps 10, the step 1 pixel
SpeedStart:
  DEFB $08,$0A,$01

; the delay counter, the steps left, the step in pixels
Speed:
  DEFB $00,$00,$00

; the controls of the last frame
LastInput:
  DEFB $00

; the screen byte of the pointer's corner (where PointerUnder goes back)
PointerAddress:
  DEFW $5800

; the arrow: 16 lines of mask (AND), image (OR)
PointerSprite:
  INCBIN "res/sprites/pointer.bin",$0000,32

; the 16 x 2 screen bytes under the pointer
PointerUnder:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00

; 4 bytes nothing uses
PointerSpare:
  DEFB $00,$00,$00,$00

; Controls = Q A O P SPACE with 6 7 8 9 0, or with the cursor keys 5 6 7 8 0
; when CAPS SHIFT is held
;
; Bit 0 right, 1 left, 2 down, 3 up, 4 fire. Each reader shifts five keys into
; C, inverts them (1 = pressed) and stores Controls itself (the shared tail at
; StoreControls); the last store is the OR of both readers.
ReadControls:
  LD E,$00
  LD A,$FE                ; the half row CAPS SHIFT-V
  IN A,($FE)
  RRCA                    ; CAPS SHIFT in the carry
  JR NC,CursorControls    ; held: the cursor keys
  CALL ReadSinclairJoystick ; else the Sinclair joystick's keys
MergeControls:
  OR E
  LD E,A
  CALL ReadQaop           ; and Q A O P SPACE
  OR E
  LD E,A
; This entry point is used by the routine at ReadQaop.
StoreControls:
  AND $1F
  LD (Controls),A
  RET
CursorControls:
  CALL ReadCursorKeys
  JR MergeControls

; SPACE, Q, A, O, P into C's low five bits (fire, up, down, left, right)
;
; Used by the routine at ReadControls.
ReadQaop:
  LD A,$7F                ; SPACE
  IN A,($FE)
  RRCA
  RL C
  LD A,$FB                ; Q
  IN A,($FE)
  RRCA
  RL C
  LD A,$FD                ; A
  IN A,($FE)
  RRCA
  RL C
  LD A,$DF                ; P (bit 0) and O (bit 1)
  IN A,($FE)
; This entry point is used by the routine at ReadSinclairJoystick.
LeftRight:
  RRCA                    ; A's bit 1 (left), then its bit 0 (right)
  RRCA
  RL C
  RLCA
  RLCA
; This entry point is used by the routine at ReadCursorKeys.
LastBit:
  RL C
  LD A,C                  ; 1 = pressed
  CPL
  JR StoreControls

; with CAPS SHIFT: 0 fire, 7 up, 6 down, 5 left, 8 right
;
; Used by the routine at ReadControls.
ReadCursorKeys:
  LD A,$EF                ; 0 9 8 7 6
  IN A,($FE)
  RRCA                    ; 0: fire
  RL C
  RRCA                    ; 9 not used; 8 (right) into the carry, kept for last
  RRCA
  PUSH AF
  RRCA                    ; 7: up
  RL C
  RRCA                    ; 6: down
  RL C
  LD A,$F7                ; 5: left, on the next half row
  IN A,($FE)
  AND $10
  ADD A,$FF               ; the carry = 5 not pressed
  RL C
  POP AF                  ; 8: right
  JR LastBit

; 0 fire, 9 up, 8 down, 6 left, 7 right (the Sinclair joystick on the keys 6-0)
;
; Used by the routine at ReadControls.
ReadSinclairJoystick:
  LD A,$EF                ; 0 9 8 7 6
  IN A,($FE)
  LD B,$03                ; 0, 9, 8
SinclairNext:
  RRCA
  RL C
  DJNZ SinclairNext
  JR LeftRight            ; then 6 and 7 as O and P

; this frame's controls: bit 0 right, 1 left, 2 down, 3 up, 4 fire
Controls:
  DEFB $00
