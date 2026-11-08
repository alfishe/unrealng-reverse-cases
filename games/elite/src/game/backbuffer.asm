; --------------------------------------------------------------------------------------------------------------------
; backbuffer.asm: The back buffer, the dashboard save and restore, the choice of view or screen
;
; The 3D view (the top 128 lines) is drawn into the back buffer $C000-$CFFF, laid out like the screen's top two
; thirds, and copied to $4000-$4FFF once a frame (CopyBackBuffer). The dashboard (the bottom third and its attributes)
; is saved before a full-screen page and put back after (DashboardSave, DashboardRestore).
;
; The keys 1-4 and ENTER, L, K, P, O, I pick what is shown (SelectView): in flight 1-4 are the front, rear, left and
; right views; docked 1 launches and 2-4 are the buy, sell and equip screens; the six letters are the screens of the
; table at $D000 (ScreenTable).
; --------------------------------------------------------------------------------------------------------------------

; Copy the back buffer $C000-$CFFF to the screen's top two thirds
;
; Four CopyThird calls of 1024 bytes: the even pixel lines of the top third
; ($4000), the even lines of the middle third ($4800), then the odd lines of
; both ($4100, $4900). The buffer address is the screen address with bit 15
; set. It runs 1830 times in f1, w1, d1.
CopyBackBuffer:
  LD DE,$4000
  LD HL,BackBuffer
  CALL CopyThird
  LD DE,$4800
  LD HL,BackBuffer+$0800
  CALL CopyThird
  LD DE,$4100
  LD HL,BackBuffer+$0100
  CALL CopyThird
  LD DE,$4900
  LD HL,BackBuffer+$0900
  CALL CopyThird
  RET

; Copy every other pixel line of one third: 8 character rows of 4 lines of 32
; LDI
;
; Used by the routine at CopyBackBuffer.
CopyThird:
  LD B,$08

; CopyThirdRow
;
; Used by the routine at CopyThirdLine.
CopyThirdRow:
  PUSH DE
  LD C,$FF
  LD A,$04

; CopyThirdLine
CopyThirdLine:
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
  INC D
  INC D
  LD H,D
  SET 7,H
  LD L,E
  DEC A
  JP NZ,CopyThirdLine
  POP DE
  LD A,E
  ADD A,$20
  LD E,A
  LD L,A
  LD H,D
  SET 7,H
  DJNZ CopyThirdRow
  RET

; Put the dashboard back if a full-screen page wiped it (the top-left byte
; reads $FF)
;
; The screen byte $4000 is $FF only while a full page is up (ClearScreen draws
; the frame). Then: SoundOff $94FE, the page cleared (ClearScreenVector $D036),
; the side attributes of the top two thirds zeroed (columns 0 and 31), the
; dashboard's pixels from DashSave $C000 and its attributes from $5B00, the
; tints again, and the scanner put in save mode (ScannerSaveMode $98A2).
DashboardRestore:
  LD DE,$4000
  LD A,(DE)
  INC A
  RET NZ
  CALL ClearKeyBytes

; DashboardRestoreNow
;
; Used by the routine at Title.
DashboardRestoreNow:
  CALL ClearScreenVector
  LD DE,$001F
  LD B,$17
  LD A,$00
  LD HL,$5800
  LD (HL),A
DashboardRestoreLoop:
  ADD HL,DE
  LD (HL),A
  INC HL
  LD (HL),A
  DJNZ DashboardRestoreLoop
  ADD HL,DE
  LD (HL),A
  LD DE,$5000
  LD HL,BackBuffer
  LD BC,$0800
  LDIR
  LD DE,$5A00
  LD HL,ScannerSave
  LD BC,$0100
  LDIR
  CALL NovaTint
  CALL CloakRestore
  JP ScannerSaveOn

; Clear the back buffer with the view's frame: lines 0 and 127 solid, a pixel
; at each side
;
; With interrupts off and SP at $D000 it PUSHes 4096 bytes: the bottom line
; $FF, 126 lines of $01 ... $80 (the side pixels), the top line $FF. f1, w1,
; d1: 1827 runs.
ClearView:
  DI
  LD (ClearViewSP),SP
  LD SP,BackBuffer+$1000
  LD HL,$0000
  LD DE,$00FF
  LD IX,$FF*$100
  LD BC,$FFFF
  PUSH DE
  LD A,$0E
ClearViewBottom:
  PUSH BC
  DEC A
  JR NZ,ClearViewBottom
  PUSH IX
  LD E,$01
  LD IX,$8000
  LD B,$7E
ClearViewLine:
  PUSH DE
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
  PUSH IX
  DJNZ ClearViewLine
  LD BC,$FFFF
  LD E,$FF
  LD IX,$FF*$100
  PUSH DE
  LD A,$0E
ClearViewTop:
  PUSH BC
  DEC A
  JR NZ,ClearViewTop
  PUSH IX
  LD SP,(ClearViewSP)
  EI
  RET

; ClearView's and CallScreen's saved stack pointer
ClearViewSP:
  DEFW $0000

; Change the view or the screen on the keys 1-4, ENTER, L, K, P, O, I
;
; KeyViews $FC0A bits 0-3 are 1-4: in flight the views 0-3 (SetView); docked
; key 1 is the launch (SceneLaunch $93ED) and 2-4 the screens 4-6 (CallScreen).
; KeyScreens $FC08 bits 5 to 0 are I, O, P, K, L and ENTER: the screens 7-12.
; Nothing while TunnelLoop $D040 is set. The keys are cleared after
; (SelectViewDone).
SelectView:
  LD A,(TunnelLoop)
  AND A
  RET NZ
  LD A,(KeyViews)
  AND $0F
  JR Z,SelectViewScreens
  LD C,$00
  SRL A
  JR C,SelectViewKey1
  INC C
  SRL A
  JR C,SelectViewDocked
  INC C
  SRL A
  JR C,SelectViewDocked
  INC C
SelectViewDocked:
  LD A,(Condition)
  AND A
  JR NZ,SelectViewSet
  LD A,$03
  ADD A,C
  LD C,A
  CALL SetView
  SUB $04
  CALL CallScreen
  JR SelectViewDone
SelectViewSet:
  CALL SetView
  JR SelectViewDone
SelectViewKey1:
  LD A,(Condition)
  AND A
  JR NZ,SelectViewFront
  CALL SceneLaunch
  JR SelectViewDone
SelectViewFront:
  CALL SetView
  JR SelectViewDone
SelectViewScreens:
  LD A,(KeyScreens)
  AND $3F
  ADD A,A
  RET Z
  ADD A,A
  LD BC,$0607
SelectViewScreenBit:
  ADD A,A
  JR C,SelectViewScreen
  INC C
  DJNZ SelectViewScreenBit
SelectViewScreen:
  CALL SetView
  CP $07
  JR C,SelectViewDone
  SUB $04
  CALL CallScreen

; Clear the view keys
;
; Used by the routines at SelectView and SetView.
SelectViewDone:
  XOR A
  LD (KeyViews),A
  LD (KeyScreens),A
  RET

; Call the routine A of ScreenTable $D000 with SP at $D000 and the sound off
; after
;
; The CALL at $8153 is patched to $D000 + 3 A. The screens draw full pages; the
; dashboard comes back with DashboardRestore.
CallScreen:
  LD (ClearViewSP),SP
  LD SP,BackBuffer+$1000
  LD B,A
  ADD A,A
  ADD A,B
  LD HL,ScreenBuy
  ADD A,L
  LD L,A
  JR NC,CallScreenSetCallScreenCall1
  INC H
CallScreenSetCallScreenCall1:
  LD (CallScreenCall+$0001),HL

; CallScreenCall
CallScreenCall:
  CALL CallScreenCall
  LD SP,(ClearViewSP)
  JP ClearKeyBytes

; ViewIndex = C unless it is already (a screen 7 and up is drawn again)
;
; A screen's key while that screen is up does nothing; $D03F set takes the
; other way ($819A: below 4 a view, else ViewIndex 0).
SetView:
  LD A,(ViewIndex)
  LD B,A
  CP C
  JR NZ,SetViewNew
  LD A,C
  CP $07
  JR C,SetViewNew
  POP HL
  JR SelectViewDone
SetViewNew:
  LD A,(TunnelOn)
  AND A
  LD A,C
  JR NZ,SetViewOverride
; This entry point is used by the routine at DashboardSave.
SetViewSetViewIndex:
  LD (ViewIndex),A
  LD A,B
  CP $04
  LD A,C
  RET NC
  CP $04
  RET C

; Save the dashboard's pixels to DashSave $C000 and its attributes to $5B00
;
; Used by the routines at TitleLoad, TitleNext and SceneLaunch.
DashboardSave:
  PUSH AF
  CALL ScannerRestore
  POP AF
  LD DE,BackBuffer
  LD HL,$5000
  LD BC,$0800
  LDIR
  LD DE,ScannerSave
  LD HL,$5A00
  LD BC,$0100
  LDIR
  RET
; This entry point is used by the routine at SetView.
SetViewOverride:
  CP $04
  JR NC,SetViewSetViewIndex
  XOR A
  LD (ViewIndex),A
  RET
