; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The menu's choice and the controls: the keyboard and the Kempston stick
;
; The demo plays these moves instead of the keys.
;
; Menu $EF33 prints the backdrop and the logo and waits: 0 starts the game, 1 toggles one and two players, 2-4 choose
; keyboard (Q A O P SPACE), Sinclair (9 8 6 7 0) or Kempston. After 3000 frames (60 s) without a key it returns for
; the demo or shows the hall of fame for 750 frames, alternately.
; --------------------------------------------------------------------------------------------------------------------

  ORG $B3B1

; The menu's choice: 0 one player, 1 the demo, 2 two players (written by Menu
; at $EF97, $F0C7)
MenuChoice:
  DEFB $00

; Builds a byte of the eight key slots held (bit 7 the last) into $B3CE: never
; called
;
; For the slots KeySlots $F084-$F08B in turn: E shifts right and bit 7 is set
; when TestKeyBit says the slot's key is held; the word DE goes to $B3CE.
; Nothing calls it and nothing reads $B3CE (known only from the code): a
; left-over of a control reader the game replaced by one TestKey call a slot.
;
; Witness: L1 0 ().
ReadControlMask:
  LD DE,$0000

; ReadControlMaskKeepDE
;
; Used by the routine at InstallIm2Key.
ReadControlMaskKeepDE:
  LD HL,KeySlots
  LD B,$08
ReadControlMaskLoop:
  SRL D
  RR E
  LD A,(HL)
  CALL TestKeyBit
  JR NZ,ReadControlMaskNext
  SET 7,E
ReadControlMaskNext:
  INC HL
  DJNZ ReadControlMaskLoop
  LD (ControlMask),DE
  RET

; ReadControlMask's result; never read (leftover)
ControlMask:
  DEFW $0000

; Z when the key of code A is held: patches BIT b,(IX+d) at $B3F3 with d = A >>
; 3 and b = A AND 7
;
; Input A a key code: row (A >> 3) 0-8 of KeyRows $B436 and bit (A AND 7). Rows
; 0-7 are the half-rows $7FFE, $BFFE, $DFFE, $EFFE, $F7FE, $FBFE, $FDFE, $FEFE
; (so $00 SPACE, $2B R, $31 S, $32 D, $3C V); row 8 is the Kempston stick ($40
; right, $41 left, $42 down, $43 up, $44 fire). Writes the displacement to
; $B3F5 and the bit into the opcode byte $B3F6 (self-modifying), then tests.
; Output Z when held (bit 0), NZ when not. Keeps IX.
;
; Witness: L1 423995 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
TestKeyBit:
  PUSH IX
  LD IX,KeyRows
  LD C,A
  SRL A
  SRL A
  SRL A
  LD (TestKeyBitTest+$0005),A
  LD A,$07
  AND C
  SLA A
  SLA A
  SLA A
  LD C,A
  LD A,(TestKeyBitTest+$0006)
  AND $C7
  OR C

; TestKeyBit's second half: stores the patched opcode (A) at $B3F6 and runs BIT
; b,(IX+d)
;
; The walk makes it an entry of its own (the recordings count one run more here
; than at TestKeyBit: a recording that starts inside the routine). Nothing
; calls or jumps here (known only from the code); it is the tail of TestKeyBit.
;
; Witness: L1 423996 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
TestKeyBitTest:
  LD (TestKeyBitTest+$0006),A
  BIT 0,(IX+$00)
  POP IX
  RET

; Waits until a key or the stick is held, then until all are released
;
; Witness: L1 14595 (menu).
WaitPress:
  CALL AnyControl
  JR Z,WaitPress
  JR WaitRelease

; Waits until no key and no stick direction is held
;
; Witness: L1 152206 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98,
; rzx x24).
WaitRelease:
  CALL AnyControl
  JR NZ,WaitRelease
  RET

; ReadControls, then Z when nothing is held (the AND of the nine KeyRows bytes
; is $FF)
;
; Witness: L1 501803 (c1, fire, gameover, menu, twoname, l51, l59, l96, l98,
; rzx x26).
AnyControl:
  CALL ReadControls
  LD HL,KeyRows
  LD B,$09
  LD A,$FF
AnyControlLoop:
  AND (HL)                ; AND the nine rows
  INC HL
  DJNZ AnyControlLoop
  CP $FF
  RET

; Reads the 8 keyboard half-rows into KeyRows $B436-$B43D and the Kempston port
; $DF into $B43E
;
; DI, then IN ($FE) for each half-row, $7FFE first, each stored with bits 5-7
; set (OR $E0). Then IN A,($DF) (A, the high byte, holds the last row's value):
; the low five bits are the Kempston stick, 1 = pressed. When all five are 1
; (no interface: the port floats at $FF) the routine returns with interrupts
; still off and $B43E unchanged; else it stores the complement (0 = pressed,
; like the keys) and EI. A Kempston mouse answering on port $DF would be read
; as a stick here (known only from the code).
;
; Witness: L1 925798 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
ReadControls:
  DI
  LD HL,KeyRows
  LD B,$08
  LD C,$FE
ReadControlsLoop:
  LD A,C                  ; one half-row
  RRCA
  LD C,A
  IN A,($FE)
  OR $E0
  LD (HL),A
  INC HL
  DJNZ ReadControlsLoop
  IN A,($DF)
  AND $1F
  CP $1F
  RET Z
  CPL
  LD (HL),A
  EI
  RET

; The last read of the controls: 8 keyboard half-rows ($7FFE ... $FEFE) and the
; Kempston stick, 0 = held
KeyRows:
  DEFB $FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF

; One byte after KeyRows; nothing reads it (leftover)
UnusedByteB43F:
  DEFB $FF

; The pause key: wait for its release, then for a key and its release
;
; Called by MainLoop when the pause key (slot $F08A) is held in a game.
; Witness: 3 pauses in the recordings.
;
; Witness: L1 3 (menu).
Pause:
  CALL WaitRelease
  CALL WaitPress
  RET

; NZ when the left control (slot $F086) is held
;
; Witness: L1 5463 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
TestLeft:
  LD A,(KeySlots+$0002)
  CALL TestKey
  RET

; NZ when the right control (slot $F087) is held
;
; Witness: L1 4674 (c1, gameover, menu, twoname, l x12, rzx00-rzx77,
; rzx79-rzx99).
TestRight:
  LD A,(KeySlots+$0003)
  CALL TestKey
  RET

; NZ when the fire control (slot $F084) is held: never called
;
; TestUpOrFire $B463 tests fire itself; nothing calls this one (known only from
; the code).
;
; Witness: L1 0 ().
TestFire:
  LD A,(KeySlots)
  CALL TestKey
  RET

; NZ when the down control (slot $F085) is held
;
; Witness: L1 990 (l x12, rzx x94).
TestDown:
  LD A,(KeySlots+$0001)
  CALL TestKey
  RET

; NZ when up (slot $F088) or fire (slot $F084) is held: the spring
;
; Witness: L1 6352 (c1, fire, gameover, menu, twoname, l x12, rzx00-rzx99).
TestUpOrFire:
  LD A,(KeySlots+$0004)
  CALL TestKey
  RET NZ
  LD A,(KeySlots)
  CALL TestKey
  RET

  ORG $BB56

; The cheat R+SPACE+V: 99 water, keys, hammers and lives for both players,
; level 0
;
; Both player records ($AB09, $AB10): water, keys, hammers and lives 99 ($63),
; level 0. Called at the start of a game ($ABD0) when the keys $2B, $00 and $3C
; are all down. Witness: 1 run, in the menu recording (stage1/menu).
;
; Witness: L1 1 (menu).
CheatStock:
  LD IX,Player1Record
  LD A,$63
  LD (IX+$02),A
  LD (IX+$03),A
  LD (IX+$04),A
  LD (IX+$05),$00
  LD (IX+$06),A
  LD (IX+$09),A
  LD (IX+$0A),A
  LD (IX+$0B),A
  LD (IX+$0C),$00
  LD (IX+$0D),A
  RET

; Water, keys and hammers 3 for both players: never run
;
; Called at $ABDD each loop when $ADDD is not 0, which never happens ($ADDF is
; a RET before the store). Known only from the code: a disabled practice or
; cheat mode.
;
; Witness: L1 0 ().
PracticeStock:
  LD IX,Player1Record
  LD A,$03
  LD (IX+$02),A
  LD (IX+$03),A
  LD (IX+$04),A
  LD (IX+$09),A
  LD (IX+$0A),A
  LD (IX+$0B),A
  RET

  ORG $D25A

; The demo's move list: one byte a decision
;
; GameStart sets the demo pointer $ABA4 = $D25A; each decision reads the byte
; after it (from $D25B on, 48 bytes read): 0-5 the next ball state at a
; landing, 9 arm the spring at a step 9 (BounceStep9, LeftStep9 and the
; others). The first byte is never read.
DemoMoves:
  INCBIN "res/tables/demo-moves.bin",$0000,49

; 41 zeros after the demo moves, never read
DemoPad:
  DEFB $03,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00

  ORG $E7F7

; Draw the BUMPY logo at the top of the menu screen
;
; DrawSprite $E318: Logo $E808, CPC address $C066 (character row 1, CPC byte
; 22: Spectrum line 1, column 11), width 18 CPC bytes (72 pixels), 60 lines. No
; attributes: the colours are the backdrop's (MenuBackdropText $F0E8).
;
; Witness: L1 8 (c1, gameover, menu, twoname).
DrawLogo:
  LD DE,WaterB5+$0002
  LD HL,Logo
  LD A,$12
  LD (SpriteWidth),A
  LD B,$3C
  CALL DrawSprite
  RET

; The BUMPY logo: 60 lines of 18 CPC mode-1 bytes (72 x 60 pixels)
Logo:
  INCBIN "res/sprites/logo.bin",$0000,1080

  ORG $EF33

; The menu: draw it and wait for 0 (play), 1 (players), 2-4 (controls), or the
; time-out
;
; Border 0, ClearScreen, the backdrop (MenuBackdropText $F0E8), DrawLogo, then
; MenuPrint. Returns to GameStart with $B3B1 = 0 (one player), 2 (two players)
; or 4 (the demo).
;
; Witness: L1 8 (c1, gameover, menu, twoname).
Menu:
  XOR A
  OUT ($FE),A
  CALL ClearScreen
  LD HL,MenuBackdropText
  CALL PrintText
  CALL DrawLogo
  JR MenuPrint

; After an option: the pick-up sound, then MenuPrint
;
; Witness: L1 11 (c1, gameover, menu, twoname).
MenuRedraw:
  CALL SfxPickup

; Start the time-out (3000 frames) and print the options
;
; Witness: L1 19 (c1, gameover, menu, twoname).
MenuPrint:
  LD HL,$0BB8
  LD (MenuTimer),HL
  LD HL,MenuText
  CALL PrintText

; One frame of the menu: test the keys, count the time-out
;
; Each frame (HALT): key "0" (code $18) starts the game (LoadControls,
; SetPlayersMode); "1" ($20) MenuTogglePlayers; "2", "3", "4" ($21-$23)
; MenuSelectControls with 0, 1, 2. The time-out $EFED counts down; at 0
; MenuDemoToggle flips: 1 returns with $B3B1 = 4 (the demo), 0 shows the hall
; of fame (MenuShowHallOfFame).
;
; Witness: L1 7019 (c1, gameover, menu, twoname).
MenuLoop:
  EI

; MenuLoop's HALT
;
; Witness: L1 7022 (c1, gameover, menu, twoname).
MenuWait:
  HALT
  LD A,$18
  CALL TestKey
  JR NZ,MenuWaitSkip
  LD A,$20
  CALL TestKey
  JR NZ,MenuTogglePlayers
  LD A,$21
  CALL TestKey
  LD A,$00
  JR NZ,MenuSelectControls
  LD A,$22
  CALL TestKey
  LD A,$01
  JR NZ,MenuSelectControls
  LD A,$23
  CALL TestKey
  LD A,$02
  JR NZ,MenuSelectControls
  LD HL,(MenuTimer)
  DEC HL
  LD (MenuTimer),HL
  LD A,L
  OR H
  JR NZ,MenuLoop
  LD A,(MenuDemoToggle)
  INC A
  AND $01
  LD (MenuDemoToggle),A
  JP Z,MenuShowHallOfFame
  LD A,$04
  LD (MenuChoice),A
  RET
MenuWaitSkip:
  CALL LoadControls
  CALL SetPlayersMode
  RET

; Flipped at each menu time-out: 1 the demo, 0 the hall of fame
MenuDemoToggle:
  DEFB $00

; Key 1: one player or two
;
; Players $F062 = 1 - Players; the 11 bytes of PlayersTexts (+16 for two) are
; copied over the option's text at $F005; then MenuRedraw.
;
; Witness: L1 4 (c1, menu, twoname).
MenuTogglePlayers:
  LD A,(Players)
  INC A
  AND $01
  LD (Players),A
  SLA A
  SLA A
  SLA A
  SLA A
  LD E,A
  LD D,$00
  LD HL,PlayersTexts
  ADD HL,DE
  LD DE,MenuText+$0016
  LD BC,$000B
  LDIR
  JP MenuRedraw

; Keys 2-4: choose the controls A (0 keyboard, 1 Sinclair, 2 Kempston)
;
; ControlChoice $F083 = A; the three options' ink bytes ($F015, $F025, $F035)
; are set to 4 (green) and the chosen one to 7 (white); then MenuRedraw.
;
; Witness: L1 7 (c1, gameover, menu, twoname).
MenuSelectControls:
  PUSH AF
  LD DE,$0010
  LD HL,MenuText+$0026
  LD B,$03
MenuSelectControlsLoop:
  LD (HL),$04
  ADD HL,DE
  DJNZ MenuSelectControlsLoop
  POP AF
  LD (ControlChoice),A
  LD C,A
  LD L,A
  SLA L
  SLA L
  SLA L
  SLA L
  LD H,$00
  LD DE,MenuText+$0026
  ADD HL,DE
  LD (HL),$07
  JP MenuRedraw

; The menu's time-out in frames (3000; 750 on the hall of fame)
MenuTimer:
  DEFW $0000

; The options: 0 GAME, 1 ONE PLAYER, 2 KEYBOARD, 3 SINCLAIR, 4 KEMPSTON, and
; VERSIONED BY J250 <SPAIN> (PrintText)
MenuText:
  INCBIN "res/texts/menu.bin",$0000,115

; 0 one player, 1 two players (SetPlayersMode: $B3B1 = 2 x Players)
Players:
  DEFB $00

; "ONE PLAYER" and "TWO PLAYERS", 16 bytes each; MenuTogglePlayers copies 11
PlayersTexts:
  INCBIN "res/texts/players.bin",$0000,32

; The controls chosen in the menu: 0 keyboard, 1 Sinclair, 2 Kempston
ControlChoice:
  DEFB $00

; The controls in play: eight key codes (row x 8 + bit; row 8 the Kempston
; port)
;
; The key codes of the key test $B6CB / $B3D0: row 0-7 the half-rows $7FFE,
; $BFFE, $DFFE, $EFFE, $F7FE, $FBFE, $FDFE, $FEFE, row 8 the Kempston byte
; $B43E (inverted by $B418). The slots: +0 up, +1 down, +2 left, +3 right, +4
; fire, +5 a second fire (not read in this range), +6 $0C (H), +7 $2B (R). The
; tape holds the keyboard set; LoadControls copies the chosen set here when a
; game starts.
KeySlots:
  DEFB $28,$30,$11,$10,$00,$00,$0C,$2B

; The three sets of eight codes by ControlChoice: KeyboardKeys, SinclairKeys,
; KempstonKeys
ControlSets:
  DEFW KeyboardKeys
  DEFW SinclairKeys
  DEFW KempstonKeys

; The three control sets, eight key codes each (the KeySlots order): keyboard,
; Kempston, Sinclair
;
; KeyboardKeys: Q A O P SPACE SPACE H R. KempstonKeys: the Kempston bits 3 2 1
; 0 4 4 (up, down, left, right, fire, fire), H, R. SinclairKeys: 9 8 6 7 0, the
; Kempston fire, H, R.
KeyboardKeys:
  INCBIN "res/tables/control-sets.bin",$0000,8
KempstonKeys:
  INCBIN "res/tables/control-sets.bin",$0008,8
SinclairKeys:
  INCBIN "res/tables/control-sets.bin",$0010,8

; Copy the chosen control set into KeySlots
;
; Witness: L1 8 (c1, gameover, menu, twoname).
LoadControls:
  LD A,(ControlChoice)
  ADD A,A
  LD C,A
  LD B,$00
  LD HL,ControlSets
  ADD HL,BC
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  LD DE,KeySlots
  LD BC,$0008
  LDIR
  RET

; $B3B1 = 2 x Players (0 one player, 2 two players)
;
; Witness: L1 8 (c1, gameover, menu, twoname).
SetPlayersMode:
  LD A,(Players)
  SLA A
  LD (MenuChoice),A
  RET

; Clear the pixels and fill the attributes with TextVars' default ($E712)
;
; Witness: L1 12 (c1, gameover, menu, twoname).
ClearScreen:
  LD HL,$4000
  LD DE,$4001
  LD BC,$1800
  LD (HL),$00
  LDIR
  LD HL,$5800
  LD DE,$5801
  LD BC,$02FF
  LD A,(TextVars)
  LD (HL),A
  LDIR
  RET

; The menu's backdrop: coloured bars of spaces around the logo (PrintText)
MenuBackdropText:
  INCBIN "res/texts/menu-backdrop.bin",$0000,125

; Show the hall of fame for 750 frames (15 s) or until a key, then the menu
; again
;
; Witness: L1 1 (menu).
MenuShowHallOfFame:
  CALL ShowHallOfFame
  LD HL,$02EE
  LD (MenuTimer),HL
MenuShowHallOfFameLoop:
  EI
  HALT
  CALL AnyControl
  JR NZ,MenuShowHallOfFameSkip
  LD HL,(MenuTimer)
  DEC HL
  LD (MenuTimer),HL
  LD A,L
  OR H
  JR NZ,MenuShowHallOfFameLoop
MenuShowHallOfFameSkip:
  JP Menu
