; --------------------------------------------------------------------------------------------------------------------
; dialogs.asm: The menus' descriptions and actions, the line editor
;
; The SYSTEM, OPTIONS, DISASTERS and WINDOWS menus, the dialogs (confirm, about, load, save, file name, tape, speed,
; level, old landscape) and their actions; the options' flags; the name and gene editor.
; --------------------------------------------------------------------------------------------------------------------

; The power station menu's answer: 0 none, 1 nuclear, 2 coal
PlantChoice:
  DEFB $00

; the menu: SELECT TYPE, NUCLEAR POWER STATION $5000, COAL POWER STATION $3000,
; NONE
PlantMenu:
  INCLUDE "res/text/menus/Plant.inc"

; NONE: PlantChoice 0 (not run in the recordings)
NoPlant:
  LD A,$00
  LD (PlantChoice),A
  RET

; PlantChoice 1
;
; L1 3.
ChooseNuclear:
  LD A,$01
  LD (PlantChoice),A
  RET
ChooseCoal:
  LD A,$02                ; PlantChoice 2
  LD (PlantChoice),A
  RET

; ARE YOU SURE ?: carry set for YES
;
; L1 5.
Confirm:
  CALL ShowInlineWindow

; ConfirmMenu
ConfirmMenu:
  INCLUDE "res/text/menus/Confirm.inc"

; OR A
ConfirmNo:
  OR A
  RET
ConfirmYes:
  SCF                     ; SCF
  RET

; SYSTEM: about, start new city, use old landscape, load, save, exit
SystemMenu:
  INCLUDE "res/text/menus/System.inc"

; EXIT SIMCITY: confirmed, a new city with a new landscape
ExitSimCity:
  CALL Confirm
  RET NC
  JR NewCityItem
NewCityItem:
  CALL Confirm            ; START NEW CITY: confirmed, the gene from the random
                          ; seed, then NewCity
  RET NC
  LD HL,(RandomSeed)
  LD (Gene),HL
; This entry point is used by the routine at LoadMap.
NewCity:
  CALL LevelMenu          ; the difficulty menu, then NewLandscape
  JP NewLandscape

; ABOUT SIM CITY
AboutWindow:
  CALL ShowInlineWindow

; AboutText
AboutText:
  INCLUDE "res/text/menus/About.inc"

; LOADING MENU
LoadMenu:
  CALL ShowInlineWindow

; LoadMenuText
LoadMenuText:
  INCLUDE "res/text/menus/Load.inc"

; SAVING MENU
SaveMenu:
  CALL ShowInlineWindow

; SaveMenuText
SaveMenuText:
  INCLUDE "res/text/menus/Save.inc"

; TYPE FILE NAME, THEN PRESS ENTER
;
; Used by the routines at SaveCity and LoadCity.
FileNameWindow:
  CALL ShowInlineWindow

; FileNameText
FileNameText:
  INCLUDE "res/text/menus/FileName.inc"

; TAPE LOADING ERROR
;
; Used by the routine at LoadMap.
LoadErrorWindow:
  CALL ShowInlineWindow

; LoadErrorText
LoadErrorText:
  INCLUDE "res/text/menus/LoadError.inc"

; START TAPE AND PRESS SPACE: wait for SPACE
;
; Used by the routine at SaveCity.
WaitTapeStart:
  CALL TapeWindow
WaitTapeLoop:
  LD A,$7F
WaitTapeIn:
  IN A,($FE)
WaitTapeTest:
  RRA
  RET NC
WaitTapeAgain:
  JR WaitTapeLoop

; TapeWindow
;
; Used by the routine at WaitTapeStart.
TapeWindow:
  CALL ShowInlineWindow

; TapeText
TapeText:
  INCLUDE "res/text/menus/Tape.inc"

; the options (toggles): AUTO-BULLDOZE 1, AUTO-BUDGET 0, SOUND 1, ZONE DEMOLISH
; WAIT 1
AutoBulldoze:
  DEFB $01
AutoBudget:
  DEFB $00
SoundOn:
  DEFB $01
DemolishWait:
  DEFB $01

; OPTIONS: the four toggles, SIMULATION SPEED, EXIT MENU
OptionsMenu:
  INCLUDE "res/text/menus/Options.inc"

; 0 fast, 1 normal, 2 slow, 3 paused
Speed:
  DEFB $01

; SIMULATION SPEED
SpeedMenu:
  CALL ShowInlineWindow

; SpeedMenuText
SpeedMenuText:
  INCLUDE "res/text/menus/Speed.inc"

; Speed = A; the asterisk moved to (HL)
SetSpeedItem:
  LD (Speed),A
  LD A,$20
  LD (SpeedMarkFast),A
  LD (SpeedMarkNormal),A
  LD (SpeedMarkSlow),A
  LD (SpeedMarkPaused),A
  LD (HL),$2A
  RET
SpeedFast:
  LD A,$00
  LD HL,SpeedMarkFast
  JR SetSpeedItem
SpeedNormal:
  LD A,$01
  LD HL,SpeedMarkNormal
  JR SetSpeedItem
SpeedSlow:
  LD A,$02
  LD HL,SpeedMarkSlow
  JR SetSpeedItem
SpeedPaused:
  LD A,$03
  LD HL,SpeedMarkPaused
  JR SetSpeedItem

; DISABLE ALL (a toggle): no random disasters
DisastersOff:
  DEFB $00

; DISASTERS: fire, flood, earthquake, air crash, tornado, nuclear meltdown
DisasterMenu:
  INCLUDE "res/text/menus/Disasters.inc"

; DisasterDue = the item + 1
;
; L1 6.
PickDisaster:
  LD A,(MenuSelected)
  INC A
  LD (DisasterDue),A
  RET

; WINDOWS: maps, budget, evaluation
WindowsMenu:
  INCLUDE "res/text/menus/Windows.inc"

; set by MAPS: the UI task opens the maps window
MapsDue:
  DEFB $00

; MapsItem
MapsItem:
  LD A,$01
  LD (MapsDue),A
  RET

; 0 easy, 1 medium, 2 difficult
Level:
  DEFB $00

; SELECT DIFFICULTY LEVEL
;
; Used by the routine at ExitSimCity.
LevelMenu:
  CALL ShowInlineWindow

; LevelMenuText
LevelMenuText:
  INCLUDE "res/text/menus/Level.inc"

; Level = the item
;
; L1 12.
SetLevel:
  LD A,(MenuSelected)
  LD (Level),A
  RET
InputCityName:
  LD HL,$0501             ; INPUT NEW CITY NAME: edit CityName at row 5
  LD (InputAt),HL
  LD HL,CityName
  LD (InputBuffer),HL
  LD A,$39
  LD (ShowInputLoop+$0003),A
  LD A,$B9
  LD (ShowInputLoop+$000B),A
  CALL InputName
  LD A,$47
  LD (ShowInputLoop+$0003),A
  LD A,$C7
  LD (ShowInputLoop+$000B),A
  CALL ToggleMenuLine
  CALL DrawNameFunds
  JP RunMenu
UseOldLandscape:
  LD HL,(Gene)            ; USE OLD LANDSCAPE: the gene into the menu's number,
                          ; the menu
  LD (GeneShown),HL
  CALL ShowInlineWindow

; OldLandscapeMenu
OldLandscapeMenu:
  INCLUDE "res/text/menus/OldLandscape.inc"

; INPUT NEW GENE: 5 digits at row 11, column 25
InputGene:
  LD HL,$0B19
  LD (InputAt),HL
  LD HL,Gene
  LD (InputBuffer),HL
  LD HL,$0501
  LD (InputDigits),HL
  CALL InputLine
  LD D,$01
  JR NC,InputGeneShow
  DEC D
InputGeneShow:
  PUSH DE
  LD HL,$0B19
  LD (PrintCol),HL
  LD HL,(Gene)
  CALL PrintNumberAt
  CALL ToggleMenuLine
  POP DE
  LD A,D
  LD (MenuSelected),A
  JP RunMenuShow

; CREATING LANDSCAPE, PLEASE WAIT
CreatingText:
  INCLUDE "res/text/menus/Creating.inc"

; the line editor: row, column, the buffer, the cursor, the digits flag, the
; length, a buffer of 12, the key delay
InputAt:
  DEFB $00,$00
InputBuffer:
  DEFB $00,$00
InputCursor:
  DEFB $00
InputDigits:
  DEFB $01
InputLength:
  DEFB $03
InputText:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
InputDelay:
  DEFB $00,$00
  DEFB $21,$01
  DEFB $03,$22
  DEFB $DD,$A6
  DEFB $18,$06

; Edit an 11-letter text at InputAt (InputLength = 11: CityName's twelfth
; letter cannot be typed) (letters, digits, space; CAPS SHIFT 5 / 8 cursor, 0
; blanks the cursor cell and the one before it)
;
; Used by the routines at SaveCity, LoadCity and SetLevel.
InputName:
  LD HL,$0B00
  LD (InputDigits),HL

; The line editor; with InputDigits a number (5 digits, carry when too large)
;
; L1 5.
InputLine:
  XOR A
  LD (InputCursor),A
  LD A,(InputDigits)
  AND A
  CALL NZ,NumberToInput
InputLoop:
  CALL ReadInput
  CALL KeyToChar
  JR C,InputNoKey
  CP $08
  JP Z,InputEnter
  LD B,A
  LD HL,(InputDelay)
  LD A,H
  OR L
  JR Z,InputKey
  DEC HL
  LD (InputDelay),HL
  JR InputShow
InputKey:
  LD HL,InputRepeat
  PUSH HL
  LD A,(KeyRows)
  AND $01
  JR NZ,InputChar
  LD HL,InputCursor
  LD A,B
  CP $38
  JR Z,CursorRight
  LD A,B
  CP $35
  JR Z,CursorLeft
  LD A,B
  CP $30
  JR Z,InputDelete
InputChar:
  LD A,(InputDigits)
  AND A
  JR Z,InputPrintable
  LD A,B
  CP $30
  JR C,InputDrop
  CP $3A
  JR NC,InputDrop
InputPrintable:
  LD A,B
  CP $20
  JR NC,InputPut
InputDrop:
  POP HL
InputNoKey:
  LD HL,$0000
  LD (InputDelay),HL
InputShow:
  CALL ShowInput
  JR InputLoop
InputRepeat:
  LD HL,$03E8
  LD (InputDelay),HL
  CALL ShowInput
  JR InputLoop
InputPut:
  LD A,(InputCursor)
  LD E,A
  LD D,$00
  LD HL,(InputBuffer)
  ADD HL,DE
  LD (HL),B
  LD HL,InputCursor
  JR CursorRight
InputDelete:
  CALL InputBlank
  LD HL,InputCursor
  CALL CursorLeft

; A space at the cursor
;
; Used by the routine at InputLine.
InputBlank:
  LD A,(InputCursor)
  LD E,A
  LD D,$00
  LD HL,(InputBuffer)
  ADD HL,DE
  LD (HL),$20
  RET

; CursorLeft
;
; Used by the routine at InputLine.
CursorLeft:
  LD A,(HL)
  SUB $01
  RET C
  LD (HL),A
  RET
; This entry point is used by the routine at InputLine.
CursorRight:
  LD A,(InputLength)
  LD C,A
  LD A,(HL)
  INC A
  CP C
  RET Z
  LD (HL),A
  RET

; The text at InputAt, the cursor's letter inverse ($C7)
;
; Used by the routine at InputLine.
ShowInput:
  LD BC,(InputAt)
  CALL ScreenAddr
  LD (PrintAddr),HL
  LD HL,(InputBuffer)
  LD A,(InputLength)
  LD B,A
  LD C,$00
ShowInputLoop:
  PUSH BC
  PUSH HL
  LD E,$47
  LD A,(InputCursor)
  CP C
  JR NZ,ShowInputChar
  LD E,$C7
ShowInputChar:
  LD A,E
  LD (PrintAttr),A
  LD A,(HL)
  CALL PrintGlyph
  CALL NextColumn
  POP HL
  POP BC
  INC HL
  INC C
  DJNZ ShowInputLoop
  RET

; The 16-bit number at (InputBuffer) as digits into InputText
;
; Used by the routine at InputLine.
NumberToInput:
  LD HL,InputText
  LD DE,InputText+$0001
  LD BC,$000B
  LD (HL),$20
  LDIR
  CALL NumberDigits
  LD HL,InputText
  LD (InputBuffer),HL
  RET

; NumberAt
NumberAt:
  DEFW $0000

; NumberDigits
;
; Used by the routine at NumberToInput.
NumberDigits:
  LD HL,(InputBuffer)
  LD (NumberAt),HL
  LD IY,InputText
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD A,(InputLength)
  LD C,A
  LD B,$05
  LD DE,-10000
  CALL NumberDigit
  LD DE,-1000
  CALL NumberDigit
  LD DE,$FF9C
  CALL NumberDigit
  LD DE,$FFF6
  CALL NumberDigit
  LD A,L
  CALL PutDigit
  RET

; NumberDigit
;
; Used by the routine at NumberDigits.
NumberDigit:
  LD A,C
  CP B
  JR C,NumberDigitSkip
  XOR A
NumberDigitLoop:
  INC A
  ADD HL,DE
  JR C,NumberDigitLoop
  SBC HL,DE
  DEC A

; PutDigit
;
; Used by the routine at NumberDigits.
PutDigit:
  ADD A,$30
  LD (PrintCharCode),A
  LD (IY+$00),A
  INC IY
; This entry point is used by the routine at NumberDigit.
NumberDigitSkip:
  DEC B
  RET
; This entry point is used by the routine at InputLine.
InputEnter:
  LD A,(InputDigits)      ; ENTER: a number is converted and stored (carry:
                          ; none or too large)
  AND A
  SCF
  RET Z
  CALL InputToNumber
  RET C
  EX DE,HL
  LD HL,(NumberAt)
  LD (HL),E
  INC HL
  LD (HL),D
  OR A
  RET

; A = E - '0', carry when E is not a digit
;
; Used by the routine at InputToNumber.
DigitValue:
  LD A,E
  CP $3A
  CCF
  RET C
  CP $30
  RET C
  SUB $30
  RET

; HL = the decimal digits of InputText, carry on overflow
;
; Used by the routine at PutDigit.
InputToNumber:
  LD IY,InputText
  LD HL,$0000
InputToNumberLoop:
  XOR A
  ADD HL,HL
  RLA
  LD D,H
  LD E,L
  ADD HL,HL
  RLA
  ADD HL,HL
  RLA
  ADD HL,DE
  RLA
  AND A
  JR NZ,InputToNumberOver
  LD E,(IY+$00)
  CALL DigitValue
  CCF
  RET NC
  LD E,A
  LD D,$00
  ADD HL,DE
  RET C
  INC IY
  LD E,(IY+$00)
  CALL DigitValue
  CCF
  RET NC
  JR InputToNumberLoop
InputToNumberOver:
  SCF
  RET
