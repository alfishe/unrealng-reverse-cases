; --------------------------------------------------------------------------------------------------------------------
; keys.asm: The keys: the key table, the redefinition, keyboard or joystick
;
; The keys are read by self-modified code: TryLeft $83C3, TryRight $8437, TryUp $84AD, TryDown $84F9 and KeysStep
; $8759 each start LD A,row; OUT ($FF),A; IN A,($FE); AND mask (the OUT to port $FF has no effect: no 48K device
; decodes an odd port; IN A,($FE) puts A on the high address byte itself). RedefineKeys $8C30 takes a key with WaitKey
; $8C1D (KeyTable $A900: 40 records of half row, bit mask, character) and writes its row and mask into the sites. Keys
; 3 and 4 of the menu copy whole 9-byte code fragments into the sites: KeyboardControl $EBCA the copies saved at
; KeyboardCode $EB15, JoystickControl $EC2E the Kempston fragments KempstonCode $EAC4 (IN A,($1F) and a bit test).
; --------------------------------------------------------------------------------------------------------------------

  ORG $8C0E

; Wait 30 x 256 loop turns, then LineAddr
;
; Witness: L1 576 (c1, lives, menu).
Pause:
  PUSH BC
  LD C,$1E
PauseLoop:
  LD B,$00
PauseSkip:
  DJNZ PauseSkip
  DEC C
  JR NZ,PauseLoop
  POP BC
  CALL LineAddr
  RET

; Wait until a key of KeyTable is down
;
; Scans the 40 records over and over. Out: HL = the record's mask byte, the
; character at HL + 1.
;
; No release wait: a key still down when WaitKey is called again is taken again
; (the menu recording's redefinition took 2 for left, right and up).
;
; Witness: L1 69199 (c1, hiscore, lives, menu, rzx01).
WaitKey:
  LD B,$28
  LD HL,KeyTable
WaitKeyLoop:
  LD A,(HL)
  OUT ($FF),A
  IN A,($FE)
  INC HL
  AND (HL)
  RET Z
  INC HL
  INC HL
  DJNZ WaitKeyLoop
  JR WaitKey

; Key 2: define the left, right, up, down and fire keys
;
; ClearAndKeyboard $ECDC; for each prompt of KeyPrompts $A978: WaitKey, the
; key's character printed, its row and mask written into the key sites ($83C4 /
; $83CA, $876C / $8772 ...), RaspSound $90A0.
;
; Starts with ClearAndKeyboard: the keyboard code is back in the sites before
; the keys are written, so a redefinition always selects the keyboard. The fire
; prompt writes KeysStep only.
;
; Witness: L1 2 (c1, menu).
RedefineKeys:
  CALL ClearAndKeyboard
  LD B,$06
RedefineKeysLoop:
  LD C,$05
  LD A,$44
  LD D,$13
  CALL FillAttrs
  LD C,$19
  LD D,$01
  LD A,$46
  CALL FillAttrs
  INC B
  INC B
  LD A,B
  CP $10
  JR NZ,RedefineKeysLoop
  LD BC,$0605
  LD D,$13
  LD HL,KeyPrompts
  CALL PrintText
  CALL WaitKey
  INC HL
  LD BC,$0619
  LD D,$01
  PUSH HL
  CALL PrintText
  POP HL
  DEC HL
  LD A,(HL)
  LD (TryLeft+$0007),A
  LD (FireLeft+$0007),A
  DEC HL
  LD A,(HL)
  LD (TryLeft+$0001),A
  LD (FireLeft+$0001),A
  CALL RaspSound
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD BC,$0805
  LD D,$13
  LD HL,PromptRight
  CALL PrintText
  CALL WaitKey
  INC HL
  LD BC,$0819
  LD D,$01
  PUSH HL
  CALL PrintText
  POP HL
  DEC HL
  LD A,(HL)
  LD (TryRight+$0007),A
  LD (FireRight+$0007),A
  DEC HL
  LD A,(HL)
  LD (TryRight+$0001),A
  LD (FireRight+$0001),A
  CALL RaspSound
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD BC,$0A05
  LD D,$13
  LD HL,PromptUp
  CALL PrintText
  CALL WaitKey
  INC HL
  LD BC,$0A19
  LD D,$01
  PUSH HL
  CALL PrintText
  POP HL
  DEC HL
  LD A,(HL)
  LD (TryUp+$0007),A
  LD (FireUp+$0007),A
  DEC HL
  LD A,(HL)
  LD (TryUp+$0001),A
  LD (FireUp+$0001),A
  CALL RaspSound
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD BC,$0C05
  LD D,$13
  LD HL,PromptDown
  CALL PrintText
  CALL WaitKey
  INC HL
  LD BC,$0C19
  LD D,$01
  PUSH HL
  CALL PrintText
  POP HL
  DEC HL
  LD A,(HL)
  LD (TryDown+$0007),A
  LD (FireDown+$0007),A
  DEC HL
  LD A,(HL)
  LD (TryDown+$0001),A
  LD (FireDown+$0001),A
  CALL RaspSound
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD BC,$0E05
  LD D,$13
  LD HL,PromptFire
  CALL PrintText
  CALL WaitKey
  INC HL
  LD BC,$0E19
  LD D,$01
  PUSH HL
  CALL PrintText
  POP HL
  DEC HL
  LD A,(HL)
  LD (KeysStep+$0007),A
  DEC HL
  LD A,(HL)
  LD (KeysStep+$0001),A
  CALL RaspSound
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  CALL ClearScreen
  RET

  ORG $A900

; 40 keys: half row, bit mask, character
KeyTable:
  INCBIN "res/tables/keys.bin",$0000,120

; The five prompts of RedefineKeys, 19 characters each
KeyPrompts:
  INCBIN "res/texts/key-prompts.bin",$0000,19
PromptRight:
  INCBIN "res/texts/key-prompts.bin",$0013,19
PromptUp:
  INCBIN "res/texts/key-prompts.bin",$0026,19
PromptDown:
  INCBIN "res/texts/key-prompts.bin",$0039,19
PromptFire:
  INCBIN "res/texts/key-prompts.bin",$004C,19

  ORG $EAC3

; Leftover: one byte (RET)
MapCellAttrPad:
  DEFB $C9

; The joystick code fragments, 9 bytes for each key site
KempstonCode:
  INCBIN "res/tables/kempston-code.bin",$0000,81

; The saved keyboard code of each key site
KeyboardCode:
  INCBIN "res/tables/keyboard-code.bin",$0000,81

; Copy the key sites into KeyboardCode
;
; Witness: L1 2 (c1, menu).
SaveKeyboardCode:
  LD BC,$0009
  LD HL,TryLeft
  LD DE,KeyboardCode
  LDIR
  LD BC,$0009
  LD HL,TryRight
  LD DE,KeyboardCode+$0009
  LDIR
  LD BC,$0009
  LD HL,TryUp
  LD DE,KeyboardCode+$0012
  LDIR
  LD BC,$0009
  LD HL,TryDown
  LD DE,KeyboardCode+$001B
  LDIR
  LD BC,$0009
  LD HL,KeysStep
  LD DE,KeyboardCode+$0024
  LDIR
  LD BC,$0009
  LD HL,FireLeft
  LD DE,KeyboardCode+$002D
  LDIR
  LD BC,$0009
  LD HL,FireRight
  LD DE,KeyboardCode+$0036
  LDIR
  LD BC,$0009
  LD HL,FireUp
  LD DE,KeyboardCode+$003F
  LDIR
  LD BC,$0009
  LD HL,FireDown
  LD DE,KeyboardCode+$0048
  LDIR
  RET

; Key 3: the keyboard code back into the key sites
;
; Witness: L1 4 (c1, menu).
KeyboardControl:
  LD BC,$0009
  LD DE,TryLeft
  LD HL,KeyboardCode
  LDIR
  LD BC,$0009
  LD DE,TryRight
  LD HL,KeyboardCode+$0009
  LDIR
  LD BC,$0009
  LD DE,TryUp
  LD HL,KeyboardCode+$0012
  LDIR
  LD BC,$0009
  LD DE,TryDown
  LD HL,KeyboardCode+$001B
  LDIR
  LD BC,$0009
  LD DE,KeysStep
  LD HL,KeyboardCode+$0024
  LDIR
  LD BC,$0009
  LD DE,FireLeft
  LD HL,KeyboardCode+$002D
  LDIR
  LD BC,$0009
  LD DE,FireRight
  LD HL,KeyboardCode+$0036
  LDIR
  LD BC,$0009
  LD DE,FireUp
  LD HL,KeyboardCode+$003F
  LDIR
  LD BC,$0009
  LD DE,FireDown
  LD HL,KeyboardCode+$0048
  LDIR
  RET

; Key 4: the joystick code into the key sites
;
; SaveKeyboardCode first: key 4 pressed twice saves the Kempston code over
; KeyboardCode, and key 3 then restores the Kempston code; a redefinition made
; after the last key 4 is lost on key 3 (KeyboardCode changes only here).
;
; Witness: L1 2 (c1, menu).
JoystickControl:
  CALL SaveKeyboardCode
  LD BC,$0009
  LD DE,TryLeft
  LD HL,KempstonCode
  LDIR
  LD BC,$0009
  LD DE,TryRight
  LD HL,KempstonCode+$0009
  LDIR
  LD BC,$0009
  LD DE,TryUp
  LD HL,KempstonCode+$0012
  LDIR
  LD BC,$0009
  LD DE,TryDown
  LD HL,KempstonCode+$001B
  LDIR
  LD BC,$0009
  LD DE,KeysStep
  LD HL,KempstonCode+$0024
  LDIR
  LD BC,$0009
  LD DE,FireLeft
  LD HL,KempstonCode+$002D
  LDIR
  LD BC,$0009
  LD DE,FireRight
  LD HL,KempstonCode+$0036
  LDIR
  LD BC,$0009
  LD DE,FireUp
  LD HL,KempstonCode+$003F
  LDIR
  LD BC,$0009
  LD DE,FireDown
  LD HL,KempstonCode+$0048
  LDIR
  RET

; "3 ..... KEYBOARD CONTROL", "4 ..... JOYSTICK CONTROL"
ControlTexts:
  INCBIN "res/texts/control.bin",$0000,24
JoystickText:
  INCBIN "res/texts/control.bin",$0018,24

; Print ControlTexts
;
; Witness: L1 10 (c1, lives, menu).
ShowControlTexts:
  LD HL,ControlTexts
  LD D,$18
  LD BC,$0F04
  CALL PrintText
  LD HL,JoystickText
  LD D,$18
  LD BC,$1104
  CALL PrintText
  RET

; ClearScreen, KeyboardControl
;
; Witness: L1 2 (c1, menu).
ClearAndKeyboard:
  CALL ClearScreen
  CALL KeyboardControl
  RET

; Keys 3 and 4 of the menu
;
; Witness: L1 5 (c1, menu).
ChooseControl:
  LD A,$F7
  OUT ($FF),A
  IN A,($FE)
  AND $04
  JR NZ,ChooseControlSkip
  CALL SwitchSound
  CALL KeyboardControl
  JP GameEntry
ChooseControlSkip:
  LD A,$F7
  OUT ($FF),A
  IN A,($FE)
  AND $08
  JR NZ,ChooseControlSkip2
  CALL SwitchSound
  CALL JoystickControl
  JP GameEntry
ChooseControlSkip2:
  JP ResetMachine

; Leftover: 28 bytes
ChooseControlPad:
  INCBIN "res/leftovers/choose-pad.bin",$0000,28
