; --------------------------------------------------------------------------------------------------------------------
; options.asm: The options screen: the choice of the control device
;
; OptionsScreen $F8F4 is node $74F2 (from the title): it prints the five devices and waits for a key 1-5; the device
; goes to ControlDevice $67B6 (ReadControls $971A) and its line is shown in another colour.
; --------------------------------------------------------------------------------------------------------------------

; The options: print the devices, a key 1-5, the device to ControlDevice, its
; line highlighted
;
; ClearMenuScreen, OptionsText, the main screen; the key from KeyState `$8978`
; / `$8979`; the old line's attribute back to `$44` (HighlightedOp), the new
; line's to `$42`, ClickFlag cleared, ScreenZero, NextView. Witness: L1 4 (c1,
; menu).
OptionsScreen:
  CALL ClearMenuScreen
  LD HL,OptionsText
  CALL $6FB3
  CALL $725F
OptionsKey:
  LD HL,$8978
OptionsKeyLoop:
  LD A,(HL)
  AND $02
  JR Z,OptionsKeyLoop
  INC HL
  LD A,(HL)
  SUB $31
  JR C,OptionsKey
  CP $05
  JR NC,OptionsKey
HighlightedOp:
  LD HL,OptionsText+$0078 ; LD HL,n: n ($F913) the attribute byte of the
                          ; highlighted line
  LD (HL),$44
  LD ($67B6),A
  ADD A,A
  LD B,$00
  LD C,A
  LD HL,OptionLines
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD (HL),$42
  LD (HighlightedOp+$0001),HL
  XOR A
  LD ($6D43),A
  CALL $705A
  JP $6A91

; The attribute bytes of the five device lines inside OptionsText
;
; Read by OptionsScreen.
OptionLines:
  DEFW $F960
  DEFW $F978
  DEFW $F98A
  DEFW $F99F
  DEFW $F9B7

; Text: "SELECT CONTROL SYSTEM." and the five devices
;
; 1 Sinclair Joystick, 2 Cursor Keys, 3 Kempston Mouse, 4 Kempston Joystick, 5
; Keyboard. Printed by OptionsScreen; the attribute after code 13 of each line
; is written by it.
OptionsText:
  INCBIN "res/texts/options.bin",$0000,132

; 61 fill bytes ($E5, one $00) of the tape block: never read
Bank6FillB:
  DEFB $FF,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$00,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
  DEFB $E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5,$E5
