; --------------------------------------------------------------------------------------------------------------------
; aim.asm: The aim: the power while fire is held, the cursor that runs round the cushions, their variables
;
; The cursor is a point on the cushion line: CursorX $86BA 3..252 and CursorY $86BB 51..180. AimCursorDraw turns it
; into one coordinate round the rectangle (0 at the top left, clockwise: top 0-249, right 249-378, bottom 378-627,
; left 627-756), adds the signed speed CursorSpeed and turns it back, so left and right alone (or the four directions)
; run it round the table. The speed grows by one every 10 interrupts while a direction is held, up to 6.
; --------------------------------------------------------------------------------------------------------------------

; The power task: +2 a tick while fire is held; on the release, play the shot
;
; Task of AimTasks (w1 4425 runs). Fire held (InputState bit 4): Power + 2,
; back to 0 when it reaches $86 (the bar fills and starts again). Fire up with
; Power 0: nothing. Fire up with Power > 0 (AimShoot): erase the cursor
; ($9371), RemoveTasks AimTasks, RemoveTask $9CA7, ShotReset, the shot's
; velocity from the cursor and the power ($8A02, the ROM calculator) and
; InstallTasks MovingTasks. w1: 21 shots.
AimPower:
  LD A,(InputState)
  AND $10
  LD A,(Power)
  JR Z,AimShoot
  ADD A,$02
  CP $86
  JR C,AimPowerStore
  XOR A
AimPowerStore:
  LD (Power),A
  RET
AimShoot:
  OR A                    ; fire released: shoot if there is power
  RET Z
  CALL DrawCursor
  LD DE,AimTasks
  CALL RemoveTasks
  LD HL,LastShotBeepTask
  CALL RemoveTask
  CALL ShotReset
  CALL AimShot
  LD DE,MovingTasks       ; the balls move
  CALL InstallTasks
  RET

; Power = 0 and the bar erased
;
; B = the old Power for $935C (the bar), Power and PowerHigh = 0. Called by
; StartAim (w1 27).
AimPowerReset:
  LD A,(Power)
  LD B,A
  LD HL,$0000
  LD (Power),HL
  JP DrawPowerBar

; The cursor task: the direction and speed from the controls
;
; Task of AimTasks and of the editor (w1 4404 runs). When InputState changed
; since CursorLastInput: right (bit 0) gives +1 on the upper half (CursorY <
; $72) and -1 on the lower; left the opposite; up (bit 2) +1 on the left half
; (CursorX < $80), down +1 on the right half; no direction: speed 0. A new
; direction against the current sign restarts at +-1; the same one keeps
; accelerating (AimCursorAccel): every 10 counts of CursorAccel, |speed| + 1 up
; to 6.
AimCursorMove:
  LD DE,(CursorX)
  LD HL,CursorSpeed
  LD A,(CursorLastInput)
  LD B,A
  LD A,(InputState)
  CP B
  JR Z,AimCursorAccel
  LD (CursorLastInput),A
  AND $01
  JR Z,CursorMoveLeft
  LD A,D
  CP $72
  JR C,CursorForward
  JR CursorBack
CursorMoveLeft:
  LD A,(InputState)       ; left
  AND $02
  JR Z,CursorMoveUp
  LD A,D
  CP $72
  JR NC,CursorForward
  JR CursorBack
CursorMoveUp:
  LD A,(InputState)       ; up
  AND $04
  JR Z,CursorMoveDown
  LD A,E
  CP $80
  JR C,CursorForward
  JR CursorBack
CursorMoveDown:
  LD A,(InputState)       ; down
  AND $08
  JR Z,CursorMoveStop
  LD A,E
  CP $80
  JR NC,CursorForward
  JR CursorBack
CursorMoveStop:
  LD (HL),$00             ; nothing held: stop
  RET
CursorForward:
  LD A,(HL)               ; along the cushion's coordinate: +1 (or accelerate)
  OR A
  LD A,$01
  JR Z,CursorNewDirection
  JP M,CursorNewDirection
  JR AimCursorAccel
CursorBack:
  LD A,(HL)               ; -1 (or accelerate)
  OR A
  LD A,$FF
  JR Z,CursorNewDirection
  JP P,CursorNewDirection
  JR AimCursorAccel
CursorNewDirection:
  LD (HL),A               ; a new direction: speed +-1, countdown 10
  INC HL
  LD (HL),$0A
  RET
AimCursorAccel:
  LD A,(HL)               ; held: count down, then |speed| + 1 up to 6
  OR A
  RET Z
  INC HL
  DEC (HL)
  RET NZ
  LD (HL),$0A
  DEC HL
  LD A,(HL)
  OR A
  JP P,CursorAccelLimit
  NEG
CursorAccelLimit:
  CP $06
  RET Z
  BIT 7,(HL)
  JR NZ,CursorAccelDown
  INC (HL)
  RET
CursorAccelDown:
  DEC (HL)
  RET

; The cursor back to the right cushion, a little at random, and drawn
;
; InputState and CursorLastInput = 0; CursorX = 252, CursorY = 115, or 114 /
; 116 by bits 6 and 0 of the R register; speed 0; draws the cursor ($9371 XOR).
; Called by StartAim (w1 21).
AimCursorReset:
  LD A,$00
  LD (InputState),A
  LD (CursorLastInput),A
  LD H,$73
  LD L,$FC
  LD A,R
  BIT 6,A
  JR Z,CursorResetStore
  DEC H
  BIT 0,A
  JR Z,CursorResetStore
  INC H
  INC H
CursorResetStore:
  LD (CursorX),HL
  XOR A
  LD (CursorSpeed),A
  JP DrawCursor

; The cursor draw task: move the cursor round the cushions by its speed
;
; Task of AimTasks and the editor (w1 4424 runs). Speed 0: nothing. Else erases
; the cursor ($9371), turns (CursorX, CursorY) into the perimeter coordinate
; HL, adds the signed speed modulo 756 ($2F4) and turns HL back; the return
; goes to $9371, which draws it at the new place.
AimCursorDraw:
  LD A,(CursorSpeed)
  OR A
  RET Z
  CALL DrawCursor
  LD HL,DrawCursor
  PUSH HL
  LD IX,CursorX
  LD A,(IX+$01)
  CP $33
  JR NZ,CursorOnBottom
  LD A,(IX+$00)
  SUB $03
  JR CursorOnTop
CursorOnBottom:
  CP $B4                  ; on the bottom cushion: 378 + (252 - x)
  JR NZ,CursorOnRight
  LD HL,$017A
  LD A,$FC
  SUB (IX+$00)
  JR CursorAddOffset
CursorOnRight:
  LD A,(IX+$00)           ; on the right cushion: 249 + (y - 51)
  CP $FC
  JR NZ,CursorOnLeft
  LD A,(IX+$01)
  SUB $33
  ADD A,$F9
  JR CursorOnTop
CursorOnLeft:
  LD HL,$0273             ; on the left cushion: 627 + (180 - y)
  LD A,$B4
  SUB (IX+$01)
CursorAddOffset:
  ADD A,L
  LD L,A
  JR NC,CursorAddSpeed
  INC H
  JR CursorAddSpeed
CursorOnTop:
  LD L,A                  ; on the top cushion: x - 3
  LD H,$00
  RL H
CursorAddSpeed:
  LD A,(CursorSpeed)      ; + the speed, modulo 756
  LD E,A
  LD D,$00
  OR A
  JP P,CursorSpeedSigned
  DEC D
CursorSpeedSigned:
  ADD HL,DE
  LD DE,$02F4
  BIT 7,H
  JR Z,CursorWrapHigh
  ADD HL,DE
  JR CursorToLeft
CursorWrapHigh:
  XOR A
  SBC HL,DE
  JR NC,CursorToLeft
  ADD HL,DE
CursorToLeft:
  LD DE,$0273             ; back to x, y: the left cushion?
  XOR A
  SBC HL,DE
  JR C,CursorToBottom
  LD A,$B4
  SUB L
  LD (IX+$01),A
  LD (IX+$00),$03
  RET
CursorToBottom:
  ADD HL,DE               ; the bottom?
  LD DE,$017A
  XOR A
  SBC HL,DE
  JR C,CursorToRight
  LD A,$FC
  SUB L
  LD (IX+$00),A
  LD (IX+$01),$B4
  RET
CursorToRight:
  ADD HL,DE               ; the right?
  LD DE,$00F9
  XOR A
  SBC HL,DE
  JR C,CursorToTop
  LD A,L
  ADD A,$33
  LD (IX+$01),A
  LD (IX+$00),$FC
  RET
CursorToTop:
  ADD HL,DE               ; the top
  LD A,L
  ADD A,$03
  LD (IX+$00),A
  LD (IX+$01),$33
  RET

; The draw list: 7 entries of 4 bytes, then the cursor and the power
;
; Written by BuildDrawList, read by BallRedraw: the ball's number, its y (the
; integer byte, the sort key), the record's address (2 bytes). Stage 1's "5
; bytes an entry" was wrong: 7 x 4 = 28 bytes, $869E-$86B9.
DrawList:
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
  DEFB $00,$00,$00,$00
CursorX:
  DEFB $00                ; the cursor's x on the cushion line, 3..252 (read
                          ; with CursorY as a word)
CursorY:
  DEFB $00                ; the cursor's y, 51..180
CursorSpeed:
  DEFB $00                ; the signed speed round the cushions, -6..6 (0 at
                          ; rest)
CursorAccel:
  DEFB $00                ; the countdown to the next +1 of the speed (10)
CursorLastInput:
  DEFB $00                ; InputState at the cursor task's last change
Power:
  DEFB $00                ; the shot's power, 0..$84 in steps of 2 (read with
                          ; PowerHigh as the word HL)
PowerHigh:
  DEFB $00                ; 0: the high byte of the power word
