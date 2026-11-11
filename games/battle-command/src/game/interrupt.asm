; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The IM 2 handler and the jobs it runs every frame
;
; The handler $8383 runs at every interrupt (the 257 vectors at $8200 all give $8383): it switches to its own stack
; (top $7C49 in bank 5), saves every register, and calls the tick routines: the sound ($7E6E bank 0), bank 4's tick,
; the mission clock, the warning blinkers, the keyboard, the pointer, the message timer; then in play (the flag $83BF)
; bank 6's display jobs, or in the menus the panel blits and the 3D view's blit (the routine in $83E6) when the frame
; is ready ($83BA).
; --------------------------------------------------------------------------------------------------------------------

  ORG $7D51

; Store the message timer: the attribute (IY+3) to $7D64, the hook $7D5D
; enabled
;
; Witness: L1 61 (death, missions, play, play2).
SetMessage:
  LD A,(IY+$03)
  LD HL,MessageOnce
  LD (HL),$00
  LD (MessageOnce+$0007),A
  RET

; Once: the timer $87D7 = 100, then the message of bank 0 ($D86B or $D84E)
; printed
;
; Patched to `RET` after one run. Witness: L1 3601 (death, m2erbe, missions,
; play, play2).
MessageOnce:
  RET
  LD A,$64
  LD (MessageTimer+$0001),A
  LD A,$00
  BIT 4,A
  JR Z,l_7D71
  CALL SoundExplosion
  LD HL,data_FEBB+$0114
  JR l_7D77
l_7D71:
  CALL SoundEffectA
  LD HL,data_FEBB+$0120
l_7D77:
  CALL PrintString
  LD A,$C9
  LD (MessageOnce),A
  RET

; Read the controls, move the pointer within the screen, test the fire
;
; `ReadControls` `$971A`, the X and Y steps (`$985E`, `$985F`) added to the
; pointer (`$7DC0`, `$7DC1`) within 8-247 and 8-183, then `PointerFire`
; `$7DC2`. Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu,
; missions, play, play2, search).
PointerTick:
  CALL ReadControls
  LD (PolyClipVars+$0002),A
  CALL PointerFire
  LD A,$FF
  AND A
  RET Z
  LD A,(PlayFlag+$0001)
  AND A
  RET Z
  LD A,(StepX)
  LD HL,PointerPos
  LD D,$08
  LD E,$F7
  CALL ClampStep
  INC HL
  LD A,(StepY)
  LD D,$08
  LD E,$B7

; ClampStep
;
; Used by the routine at PointerTick.
ClampStep:
  LD C,(HL)
  LD B,A
  AND A
  JP P,l_7DB6
  ADD A,C
  SUB D
  JR C,l_7DB4
  ADD A,D
  LD (HL),A
  RET
l_7DB4:
  LD (HL),D
  RET
l_7DB6:
  LD A,C
  ADD A,B
  SUB E
  JR NC,l_7DBE
  ADD A,E
  LD (HL),A
  RET
l_7DBE:
  LD (HL),E
  RET

; The pointer's X and Y (copied to $7C51 / $7C53 by $897E)
PointerPos:
  DEFB $32,$32

; Carry (the fire) held: after 25 frames a click ($6D43 = $FF) at the pointer,
; repeated every 5
;
; Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
PointerFire:
  RRA
  JR C,l_7DCA
  XOR A
  LD (FireHeld),A
  RET
l_7DCA:
  LD A,(FireHeld)
  AND A
  JR Z,l_7DE1
  LD A,(FireCount)
  DEC A
  LD (FireCount),A
  RET NZ
  LD A,$7F
  LD (PointerZones+$0001),A
  LD A,$05
  JR l_7DEB
l_7DE1:
  LD A,$FF
  LD (FireHeld),A
  LD (PointerZones+$0001),A
  LD A,$19
l_7DEB:
  LD (FireCount),A
  LD A,(FailReason+$0058)
  LD (ClickX),A
  LD A,(FailReason+$005A)
  LD (ClickY),A
  RET

; The mission clock: every 50 interrupts one second on in $68EA (seconds,
; minutes, hours)
;
; A `NOP` while it runs; the mission header's loader puts `RET` here (`$8612`)
; until play. Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean,
; menu, missions, play, play2, search).
ClockTick:
  NOP
  LD A,$32
  DEC A
  LD (ClockTick+$0002),A
  RET NZ
  LD A,$01
  LD (ClockTick+$0002),A
  LD HL,MissionClock
  LD A,(HL)
  CP $3B
  JR NC,l_7E13
  INC A
  LD (HL),A
  RET
l_7E13:
  LD (HL),$00
  INC HL
  LD A,(HL)
  CP $3B
  JR NC,l_7E1E
  INC A
  LD (HL),A
  RET
l_7E1E:
  LD (HL),$00
  INC HL
  LD A,(HL)
  CP $17
  JR NC,l_7E29
  INC A
  LD (HL),A
  RET
l_7E29:
  LD (HL),$00
  RET

; Two spare bytes and the mission loaded last ($7E2E, $FF none)
LoadedMission:
  DEFB $00,$00
LastLoadedMission:
  DEFB $FF

; The clock's string: position codes and "00:00", $FF
ClockText:
  DEFB $02,$30,$01,$0D,$47,$30,$30,$3A,$30,$30,$FF

; Print the clock's minutes and hours ($68EB, $68EC) as two digit pairs
;
; Witness: L1 530 (play, play2).
PrintClock:
  LD A,(MissionClock+$0001)
  LD C,$FF
l_7E3F:
  INC C
  SUB $0A
  JR NC,l_7E3F
  EX AF,AF'
  LD A,C
  ADD A,$30
  LD (ClockText+$0008),A
  EX AF,AF'
  ADD A,$3A
  LD (ClockText+$0009),A
  LD A,(MissionClock+$0002)
  LD C,$FF
l_7E56:
  INC C
  SUB $0A
  JR NC,l_7E56
  EX AF,AF'
  LD A,C
  ADD A,$30
  LD (ClockText+$0005),A
  EX AF,AF'
  ADD A,$3A
  LD (ClockText+$0006),A
  LD HL,ClockText
  JP PrintString

; The interrupt's sound step: bank 0's driver $D692, the bank kept
;
; Witness: L1 69896 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
SoundTick:
  CALL PageBank6Kept
  CALL PageBank0
  CALL SoundFrame
  JP PageBankKept

; $66CE and the click flag cleared
;
; Witness: L1 2966 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
ClearPointerState:
  XOR A
  LD (PolyClipVars+$0002),A
  LD (PointerZones+$0001),A
  RET

; 12 bytes of the mission header ($DBF1), copied by $8598
MissionParams:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$F7,$67,$20,$1E,$1E,$02,$08,$44,$05,$00
  DEFB $04,$98,$9C,$8C,$A4,$98,$88,$A0,$A4,$94,$9C,$A0
  DEFB $90,$0C,$04,$00,$08,$04,$02,$98,$9C,$8C,$88,$01
  DEFB $08,$04,$03,$A4,$98,$88,$94,$02,$08,$04,$02,$A0
  DEFB $A4,$94,$90,$03,$08,$04,$03,$9C,$A0,$90,$8C,$FF
  DEFB $00,$F7,$67,$20,$18,$04,$01,$28,$A7,$5E,$A8,$41
  DEFB $F0,$42,$F8,$43,$F0,$44,$1E,$A7,$45,$F0,$46,$F8
  DEFB $47,$F0,$48,$29,$A8,$5E,$A8,$49,$F0,$4A,$F8,$4B
  DEFB $F0,$4C,$1E,$A9,$4D,$F0,$4E,$F8,$4F,$F0,$50,$FF
  DEFB $02,$10,$02,$05,$00,$08,$20,$10,$08,$10,$30,$28
  DEFB $30,$40,$38,$40,$14,$1C,$14,$04,$0C,$04,$24,$2C
  DEFB $24,$34,$3C,$34,$20,$18,$0C,$08,$00,$08,$04,$03
  DEFB $20,$10,$08,$18,$01,$08,$04,$04,$10,$30,$28,$08
  DEFB $02,$08,$04,$03,$30,$40,$38,$28,$03,$08,$04,$04
  DEFB $40,$14,$1C,$38,$04,$08,$04,$03,$14,$04,$0C,$1C
  DEFB $05,$08,$04,$04,$04,$24,$2C,$0C,$06,$08,$04,$03
  DEFB $24,$34,$3C,$2C,$07,$08,$04,$04,$34,$20,$18,$3C
  DEFB $FF,$00,$F7,$67,$20,$30,$30,$01,$29,$A7,$5C,$22
  DEFB $A6,$A6,$61,$F8,$60,$29,$A5,$A9,$5F,$F8,$5E,$25
  DEFB $A3,$5D,$FF,$05,$00,$04,$7C,$70,$84,$84,$70,$78
  DEFB $78,$70,$80,$80,$70,$7C,$02,$06,$38,$0C,$04,$00
  DEFB $07,$03,$04,$7C,$70,$84,$01,$07,$03,$07,$84,$70
  DEFB $78,$02,$07,$03,$04,$78,$70,$80,$03,$07,$03,$07
  DEFB $80,$70,$7C,$03,$9F,$1D,$21,$1F,$A0,$1D,$1E,$20
  DEFB $C0,$FF,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  ORG $8383

; The IM 2 handler: own stack, the tick jobs, the play or menu jobs, RETI
;
; Witness: L1 69896 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
InterruptHandler:
  DI
  EX (SP),HL
  LD (SavedSP+$0001),SP
  LD SP,FailReason+$0050
  PUSH IY
  PUSH IX
  PUSH AF
  EX AF,AF'
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  EXX
  PUSH HL
  PUSH DE
  PUSH BC
  EXX
  CALL SoundTick
  CALL Bank4Tick
  NOP
  NOP
  NOP
  CALL ClockTick
  CALL TimeOfDay
  CALL BlinkWarning
  CALL BlinkLamp
  CALL KeyRepeat
  CALL PointerTick
  CALL MessageTimer
PlayMode:
  LD A,$00                ; LD A,n: $FF in the menus' quiet path ($83BA)
  INC A
  JR NZ,PlayJobs
PlayFlag:
  LD A,$00                ; LD A,n: non-zero in play ($83BF)
  AND A
  JP Z,MenuJobs
  CALL PageBank6Kept
  CALL RestorePointerBackground
  CALL CopyPointer
  CALL SavePointerBackground
  CALL ClearMarkColumn
  CALL CopyViewUnderPointer
  CALL DrawPointer
  CALL DrawPointerInView
  CALL PageBankKept
MenuJobs:
  CALL SkyColours
  CALL NightColours
  CALL ViewBlitFront
  CALL Bank4Tick
  CALL ClearBlitRequest
  JP HandlerExit

; A RET; behind it the clear of three bytes every 33 for 48 lines from $8AF1
; (unused)
;
; Witness: L1 2959 (death, m2erbe, missions, play, play2).
ClearMarkColumn:
  RET
  LD HL,BackBuffer
  LD DE,$001E
  LD B,$30
  XOR A
l_83FB:
  LD (HL),A
  INC HL
  LD (HL),A
  INC HL
  LD (HL),A
  ADD HL,DE
  DJNZ l_83FB
  RET
; This entry point is used by the routine at InterruptHandler.
PlayJobs:
  LD A,(PlayFlag+$0001)
  AND A
  JR Z,HandlerExit
  CALL PageBank6Kept
  CALL RestorePointerBackground
  CALL CopyPointer
  CALL SavePointerBackground
  CALL DrawPointer
  CALL PageBankKept

; HandlerExit
;
; Used by the routines at InterruptHandler and ClearMarkColumn.
HandlerExit:
  POP BC
  POP DE
  POP HL
  EXX
  POP BC
  POP DE
  POP HL
  POP AF
  EX AF,AF'
  POP AF
  POP IX
  POP IY
SavedSP:
  LD SP,$0000             ; LD SP,n: the interrupted stack ($842B)
  EX (SP),HL
  EI
  RETI

; Keep the current bank in $843B and page bank 6
;
; Witness: L1 195831 (c1, controls, death, m10, m2erbe, m2ocean, menu,
; missions, play, play2, search).
PageBank6Kept:
  LD A,(SaveBank+$0002)
  LD (PageBankKept+$0001),A
  JP PageBank6

; Page the bank PageBank6Kept kept
;
; Witness: L1 195831 (c1, controls, death, m10, m2erbe, m2ocean, menu,
; missions, play, play2, search).
PageBankKept:
  LD A,$00
  JP PageBankA

; The key E: bank 0's sound off $D807, bank 6 $DA09, the flags $D689 and $DB71
; cleared
;
; Witness: L1 13 (play2).
SoundOffKey:
  CALL SilenceAY
  CALL SaveBank
  CALL PageBank6
  CALL QuitPrompt
  CALL RestoreBank
  LD HL,HelicarrierData+$00B9
  LD (HL),$00
  LD HL,PickupAnnounce
  LD (HL),$00
  RET

; Every 12 frames flip the attribute bits $30 of $5758 and $5078 (a RET while
; off)
;
; Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
BlinkWarning:
  RET
  LD A,$01
  DEC A
  LD (BlinkWarning+$0002),A
  RET NZ
  LD A,$0C
  LD (BlinkWarning+$0002),A
  LD HL,$5758
  LD A,(HL)
  XOR $30
  LD (HL),A
  LD HL,$5078
  LD A,(HL)
  XOR $30
  LD (HL),A
  RET

; Every 8 frames flip $3C on four pixel lines at $525C (a RET while off)
;
; Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
BlinkLamp:
  RET
  LD A,$01
  DEC A
  LD (BlinkLamp+$0002),A
  RET NZ
  LD A,$08
  LD (BlinkLamp+$0002),A
  LD HL,$525C
  LD B,$04
l_8487:
  LD A,(HL)
  XOR $3C
  LD (HL),A
  INC H
  DJNZ l_8487
  RET

; Scan the keyboard: a new key sets bit 0 of $8978 at once, a held key after 17
; frames, then every 2
;
; Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
KeyRepeat:
  CALL ScanKeyboard
  JR C,l_84A1
  LD HL,KeyState
  BIT 0,(HL)
  JR NZ,l_84C0
  XOR A
  LD (KeyCode),A
  JR l_84C0
l_84A1:
  LD C,A
  LD A,(KeyCode)
  CP C
  JR Z,l_84B3
  LD A,C
  LD (KeyCode),A
  LD A,$11
  LD (KeyRepeatCount),A
  JR l_84BB
l_84B3:
  LD HL,KeyRepeatCount
  DEC (HL)
  JR NZ,l_84C0
  LD (HL),$02
l_84BB:
  LD HL,KeyState
  SET 0,(HL)
l_84C0:
  RET

  ORG $87D6

; Count $87D7 down; at 0 print the message line $7C06 (or the blank $87F0)
;
; Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
MessageTimer:
  LD A,$00
  AND A
  RET Z
  DEC A
  LD (MessageTimer+$0001),A
  RET NZ
  LD A,$00
  AND A
  JR Z,l_87EA
  LD HL,FailReason+$000D
  JP PrintString
l_87EA:
  LD HL,BlankMessage
  JP PrintString

; The empty message line
BlankMessage:
  DEFM $07,"x",$11,"::::::::",$FF

; The key N: LD A,n (n = $87FD), then ToggleNight
;
; Witness: L1 6 (play).
NightKey:
  LD A,$00
  AND A

; Night sight on or off: the lamp attribute $5ACF, the text $BA6E / $BA7A,
; $757A from the table $88F8
;
; Witness: L1 33 (c1, death, m2erbe, missions, play, play2).
ToggleNight:
  LD HL,$5ACF
  JR NZ,l_8818
  LD C,$42
  LD (HL),C
  LD (PlayKeys+$000A),A
  LD (NightColours),A
  LD A,$FF
  LD (NightKey+$0001),A
  LD HL,ViewTexts
  JP PrintString
l_8818:
  LD C,$44
  LD (HL),C
  LD (PlayKeys+$000A),A
  XOR A
  LD (NightKey+$0001),A
  LD HL,HourTable
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  LD (ScreenList+$0094),A
  XOR A
  LD (SkyColours),A
  LD HL,IrSightBlank
  JP PrintString

; Each interrupt: the hour ($68EC) against the four 4-byte rows of $88F8; a
; match arms $885F
;
; Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
TimeOfDay:
  LD HL,HourTable
  LD DE,$0004
  LD B,E
  LD A,(MissionClock+$0002)
  LD C,A
l_8841:
  CP (HL)
  JR NZ,l_8848
  CP $00
  JR NZ,l_884C
l_8848:
  ADD HL,DE
  DJNZ l_8841
  RET
l_884C:
  LD A,(HL)
  LD (l_8841+$0004),A
  LD (NightBoxSelect+$0001),A
  LD (l_8818+$000B),HL
  LD A,$00
  AND A
  RET Z
  XOR A
  LD (SkyColours),A
  RET

; Once per change: the sky and ground attributes of the hour's row, then the
; panel's copies
;
; Witness: L1 6657 (c1, death, m2erbe, missions, play, play2).
SkyColours:
  RET
  LD A,$02
  DEC A
  LD (SkyColours+$0002),A
  JR Z,l_8872
  LD HL,(l_8818+$000B)
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  LD (ScreenList+$0094),A
l_8872:
  LD A,$C9
  LD (SkyColours),A
  LD A,$02
  LD (SkyColours+$0002),A
  LD A,(NightKey+$0001)
  AND A
  JR NZ,NightBoxSelect
  LD HL,(l_8818+$000B)
  INC HL
  LD A,(HL)
  INC HL
  EXX
  LD B,A
  LD HL,SkyBoxes
  CALL AttrBoxAt
  EXX
  LD A,(HL)
  EXX
  LD B,A
  LD HL,SkyBoxes+$0004
  LD A,($5A02)
  CP $70
  JR NZ,l_88A5
  LD C,$06
  CALL AttrBoxAtC
  JR CopySkyRows
l_88A5:
  CALL AttrBoxAt

; CopySkyRows
;
; Used by the routines at SkyColours and NightBoxSelect.
CopySkyRows:
  LD A,($5940)
  LD HL,$59A0
  LD DE,$59C0
  LD BC,$000B
  LDIR
  LD HL,$5960
  LD DE,$59D5
  LD C,$0B
  LDIR
  LD DE,$59E1
  LD C,$02
  LDIR
  LD DE,$59FD
  LD C,$02
  LDIR
  RET

; Once: the night or day attribute box ($88EE / $88F3)
;
; Witness: L1 6657 (c1, death, m2erbe, missions, play, play2).
NightColours:
  RET
  LD A,$C9
  LD (NightColours),A

; NightBoxSelect
;
; Used by the routines at StartMission and SkyColours.
NightBoxSelect:
  LD A,$00                ; LD A,n: n ($88D6) the hour row
  CP $08
  JR Z,l_88E2
  LD HL,DayBox
  LD A,$FF
  JR l_88E6
l_88E2:
  LD HL,NightBox
  XOR A
l_88E6:
  LD (ScreenList+$0094),A
  CALL AttrBox
  JR CopySkyRows

; An attribute box record (AttrBox)
DayBox:
  DEFB $42,$0A,$00,$20,$04

; NightBox
NightBox:
  DEFB $7B,$0A,$00,$20,$04

; Four rows: the hour, two attributes, the light value for $757A
HourTable:
  DEFB $11,$08,$20,$00
  DEFB $12,$08,$00,$00
  DEFB $07,$28,$20,$00
  DEFB $08,$68,$60,$FF

; SkyBoxes
SkyBoxes:
  DEFB $06,$00,$20,$04
  DEFB $04,$00,$20,$0A

; Scan the eight half rows: the key's code from $8950 to $897B, bit 1 of $8978
; set; SYMBOL SHIFT with SPACE = "0"
;
; Witness: L1 69895 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
ScanKeyboard:
  LD BC,$7FFE
  LD HL,KeyCodes
l_8916:
  IN A,(C)
  LD DE,$0105
l_891B:
  RRA
  JR NC,l_892E
  RLC D
  INC HL
  DEC E
  JR NZ,l_891B
  RRC B
  JR C,l_8916
  LD HL,KeyState
  RES 1,(HL)
  RET
l_892E:
  LD A,(HL)
  LD (KeyRepeatCount+$0001),A
  LD HL,KeyState
  SET 1,(HL)
  LD E,B
  LD (KeyRepeatCount+$0002),DE
  CP $30
  JR NZ,l_894E
  LD BC,$FEFE
  IN A,(C)
  RRA
  LD A,$30
  RET C
  LD A,$04
  LD (KeyRepeatCount+$0001),A
l_894E:
  SCF
  RET

; 40 key codes, by half row and bit
KeyCodes:
  DEFB $02,$00,$4D,$4E,$42,$03,$4C,$4B
  DEFB $4A,$48,$50,$4F,$49,$55,$59,$30
  DEFB $39,$38,$37,$36,$31,$32,$33,$34
  DEFB $35,$51,$57,$45,$52,$54,$41,$53
  DEFB $44,$46,$47,$01,$5A,$58,$43,$56

; KeyFlags (bit 0 new or repeated, bit 1 a key is down), KeyCode, the repeat
; count, the raw key, the row
KeyState:
  DEFB $00
KeyCode:
  DEFB $00
KeyRepeatCount:
  DEFB $00,$00,$00,$00

; The pointer's X and Y to $7C51 and $7C53
;
; Witness: L1 49405 (c1, controls, death, m10, m2erbe, m2ocean, menu, missions,
; play, play2, search).
CopyPointer:
  LD A,(PointerPos)
  LD (FailReason+$0058),A
  LD A,(PointerPos+$0001)
  LD (FailReason+$005A),A
  RET
