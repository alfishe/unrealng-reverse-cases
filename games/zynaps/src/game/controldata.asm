; --------------------------------------------------------------------------------------------------------------------
; controldata.asm: The controls, the key names, the life marks, the event table and the level script's state
;
; The control state ReadControls $A6B6 leaves, the redefinable keys, the event scheduler's request and mask bytes and
; its handler table, and ScriptState: the 35 bytes the level script works in (copied from and to the player record).
; --------------------------------------------------------------------------------------------------------------------

; Passes fire has been held, 0 released (ReadControls $A725)
FireHeld:
  DEFB $00

; $FF when fire was pressed or released since the last read ($A73C)
FireChanged:
  DEFB $00

; Bit 0 right, 1 left, 2 down, 3 up ($A742)
ControlBits:
  DEFB $00

; Bit 0 Kempston, bit 1 Sinclair rather than cursor
JoystickFlags:
  DEFB $00

; 5 keys (fire up down left right) as port high byte and bit mask; P L SS A S
; by default
KeyTable:
  DEFB $DF,$01
  DEFB $BF,$02
  DEFB $7F,$02
  DEFB $FD,$01
  DEFB $FD,$02

; The half-rows WaitKeyPress scans: $FE $FD $FB $DF $BF $7F
KeyScanRows:
  DEFB $FE,$FD,$FB,$DF,$BF,$7F

; The 40 key names in the order of the half-rows $FEFE..$7FFE; 0-3 = messages
; 9-12 (CS SS SP EN)
KeyNames:
  DEFM $00,"ZXCV"
  DEFM "ASDFG"
  DEFM "QWERT"
  DEFM "12345"
  DEFM "09876"
  DEFM "POIUY"
  DEFM $03,"LKJH"
  DEFM $02,$01,"MNB"

; The attribute steps between the life marks (DrawLives $A4EF reads 6 bytes:
; the 6th is EventRequests, unused)
LifeSteps:
  DEFB $01,$E0,$E0,$1F,$E0

; A bit per job asked for (bit 7 first; EventDispatch $AC07)
EventRequests:
  DEFB $00

; The enabled jobs ($FF from the play loop's start)
EventMask:
  DEFB $FF

; The 8 job routines, bit 7 first
EventHandlers:
  DEFW SpriteBuildJob
  DEFW EventNone
  DEFW EventNone
  DEFW EventNone
  DEFW EventNone
  DEFW PodIconJob
  DEFW ScoreJob
  DEFW EffectJob

; The level script's state (35 bytes, $AD56 from the player record, $AED2 back)
;
; +0-+7 come from LevelTable, +8-+$0C from ScriptStateInit, the rest is the
; call stack. +0 ($81D7) is LevelTable's first byte (0 in every level; nothing
; reads it).
ScriptState:
  DEFB $00
ScriptPC:
  DEFB $00,$00            ; the step being waited for (word)
PlayFlags:
  DEFB $00                ; bit 5 the scroll on, bit 7 the stars shown
ScrollCount:
  DEFB $00,$00            ; word, +1 per scroll step (the level's start value
                          ; from LevelTable)
ScriptNumber:
  DEFB $00                ; the scenery script
ScriptLevelBias:
  DEFB $00                ; added to WeaponRating ($9B9B)
ScriptStackPtr:
  DEFB $00,$00            ; word: the script's call stack ($81F6 at the start,
                          ; two bytes a call)
ScriptWaitCount:
  DEFB $00                ; the counts waited for the current step (one a
                          ; WaveScriptStep run, 8 frames)
ScriptFlags:
  DEFB $00                ; the flags of the last counter op (the conditions
                          ; test them)
ScrollRestart:
  DEFB $00                ; $FF (op 1): start the scroll again at phase 4
                          ; (ScrollControl $A9A8)
ScriptCounter:
  DEFB $00,$00            ; the word every script loops on (ops 7 and 9)
ScriptCallStack:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; the call
  DEFB $00,$00,$00,$00                                                 ; stack, 16
                                                                       ; bytes
                                                                       ; below
                                                                       ; $81F6 (no
                                                                       ; script
                                                                       ; calls)

; Copied to the record's +$15-+$19 at a level's start: the stack pointer $81F6,
; wait 0, flags 0, restart 0
ScriptStateInit:
  DEFB $F6,$81,$00,$00,$00

; The level script ops 0-17 (JumpTable from WaveScriptStep $AD86)
ScriptCommands:
  DEFW CmdNop
  DEFW CmdSetFlag
  DEFW CmdScrollStop
  DEFW CmdModeOn
  DEFW CmdModeOff
  DEFW CmdLevelEnd
  DEFW CmdNop2
  DEFW CmdStore
  DEFW CmdCopy
  DEFW CmdDecrement
  DEFW CmdIncrement
  DEFW CmdTest
  DEFW CmdAdd
  DEFW CmdReturn
  DEFW CmdCheckpoint
  DEFW CmdResetRecords
  DEFW CmdEnemyEscape
  DEFW CmdEnemiesLeft

; The 7 jump conditions on ScriptFlags: always, Z, NZ, C, NC, P, M ($AE00)
ScriptConditions:
  DEFW CondAlways
  DEFW CondZero
  DEFW CondNonZero
  DEFW CondCarry
  DEFW CondNoCarry
  DEFW CondPositive
  DEFW CondNegative
