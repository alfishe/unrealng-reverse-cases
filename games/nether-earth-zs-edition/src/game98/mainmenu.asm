; --------------------------------------------------------------------------------------------------------------------
; mainmenu.asm: The main menu with ZS's title and LOAD NEW LEVEL!, the emptied tape save and load, the redefine-keys screen
;
; What the player sees before a game and when it ends: the title ZS EDITION'98, the six options 0-5, the menu tune,
; the redefine screen. NE's tape load (key 5, LOAD SAVED GAME) and tape save (the SAVE key in play) are gone: ZS
; cleared their code to zero bytes and put a level copy at the end of the old load path (LoadNewLevel), which reads no
; disk; SaveGame is three NOPs and a RET. NE's docs: 05-controls.md 5.2 (the menu, the redefine screen), 08-hud-and-
; text.md 8.1 (the inline strings).
;
; Calling order: Start ($A62A) calls MainMenu: ClearScreen, PrintTitle, the options (each option's colour from
; ControlsOptionAttr), then MainMenuKeys: wait for all keys up, MenuMusic (module music) until a number key, then KEY-
; SCAN and the ROM key table decide: 0 MenuStart (Z), 1-3 MenuSetControls (Controls, the options again: MenuMusic
; restarts), 4 RedefineKeys (then the whole menu), 5 LoadNewLevel (the 62 NOPs where NE's LoadGame was, the copy of
; 500 bytes from $DD00 to the level lists, then JP Start). MainMenu never returns NZ any more: the path of Start to
; EnterPlay for a loaded game ($A62D JR NZ) is dead.
;
; The menu does not use KeyTable or ReadControls: it reads the keyboard with the ROM's KEY-SCAN ($028E) and the ROM's
; key table ($0205), so 0-5 work whatever keys were defined. RedefineKeys clears and refills KeyTable (module
; controls) through DefineKey: a key value E becomes the 3-byte record (port high byte, bit mask, code) ReadControls
; reads.
;
; Inline strings everywhere: a CALL PrintInline is followed by its text (position, attribute and size codes, then
; characters, 0), and execution goes on after the 0. PrintKeyPrompt ends in JP PrintInline, so the key name after each
; CALL PrintKeyPrompt is a string too; the checks for SYM SH / ENTER / CAPS SH / SPACE each put a RET after their name
; string. DefineKeyDone ($C4A6) is also command 0 of the music tables.
;
; LOAD NEW LEVEL (docs of this part: work/stage2/STATE-game98.md): LoadNewLevel expects a 512-byte level file already
; at $DD00 in the format the '99's NELEV_xx.N files have (the scenery and base lists from offset 0, the four list
; addresses at offset $1F4) and puts it in place: 500 bytes to SceneryWest $BDA9 and the four addresses into
; BuildMap's LD HL operands. Nothing in the '98 reads such a file: no TR-DOS call is in the game (the only #3D13 calls
; of the release are the REM loader's two, $5D81 and $5D91), and the 62 bytes before the copy are zero. At $DD00 lies
; whatever the memory holds there: after the load, the intro's scroller text (the intro block was read to
; $C000-$E9FF), after a game the map. The '99 fills the same place ($C1FD-$C332, from its patches block) with the
; missing part: a catalogue read to $F000, a list of the NELEV files, a choice, a read of the file to $F000 and the
; same copy (499 bytes and five words) into the same operands.
; --------------------------------------------------------------------------------------------------------------------

; The main menu: clear the screen, the title, the options; Z = start a new game
;
; Called by Start ($A62A); Start goes on to the new game set-up on Z ($A62D;
; the NZ path to play, NE's loaded game, is never taken: no key returns NZ).
; Prints the title (PrintTitle) and the options 0-5; the current controls
; (Controls, $D3E4) show in cyan, the others in yellow ($C336). Then
; MainMenuKeys. Keys 1-3 choose the controls and redraw the options, 4
; redefines the keys and redraws the whole menu, 5 runs LoadNewLevel (which
; ends in JP Start, not back here), 0 starts.
;
; Witness: r98 frame 4800 (work/stage2/game98/menu4800.png): ZS EDITION'98,
; 0..START GAME, 1..KEYBOARD (cyan), 2..KEMPSTON J/S, 3..INTERFACE 2,
; 4..REDEFINE KEYS, 5..LOAD NEW LEVEL!; game98/play ran it once (frame 4500),
; game98/key5menu twice (the second after LoadNewLevel's JP Start).
MainMenu:
  CALL ClearScreen        ; the menu starts on an empty black screen

; The main menu without the clearing: the title, then the options
;
; The entry of MainMenu after ClearScreen; nothing jumps here (MainMenuKeys key
; 4 jumps to MainMenu itself). Falls into MainMenuOptions.
MainMenuTitle:
  CALL PrintTitle         ; the title, ZS EDITION'98 in big letters

; The main menu's options (re-entered after keys 1-3)
;
; Used by the routine at MainMenuKeys.
MainMenuOptions:
  CALL PrintInline        ; option 0, START GAME

; "0..START GAME" at (11,8) in double height, yellow
;
; PrintInline codes: attribute $46, setting $21 (double height), position row
; 11 column 8, the text, setting $00.
MenuStartText:
  DEFM $02,"F",$04,"!",$01,$0B,$08 ; attribute $46 (yellow), size $21 (tall),
                                   ; AT (11,8)
  DEFM "0..START GAME"    ; "0..START GAME", rows 11-12
  DEFM $04,$00,$00        ; size 0 again for the options after it, then the end

; Option 1, KEYBOARD, in the colour of Controls 1
MenuKeyboardOption:
  LD C,$01                ; option 1: Controls value 1
  CALL ControlsOptionAttr ; cyan if it is the current choice, else yellow
  CALL PrintInline        ; the KEYBOARD text

; Three new lines and "1..KEYBOARD"
MenuKeyboardText:
  DEFM $03,$03,$03,"1..KEYBOARD",$00 ; three rows down, (14,8): "1..KEYBOARD",
                                     ; in the attribute ControlsOptionAttr just
                                     ; set

; Option 2, KEMPSTON J/S, in the colour of Controls 2
MenuKempstonOption:
  LD C,$02                ; option 2: Controls value 2
  CALL ControlsOptionAttr ; cyan if chosen, else yellow
  CALL PrintInline        ; the KEMPSTON J/S text

; Two new lines and "2..KEMPSTON J/S"
MenuKempstonText:
  DEFM $03,$03,"2..KEMPSTON J/S",$00 ; two rows down, (16,8): "2..KEMPSTON J/S"

; Option 3, INTERFACE 2, in the colour of Controls 3; then options 4 and 5
MenuInterface2Option:
  LD C,$03                ; option 3: Controls value 3
  CALL ControlsOptionAttr ; cyan if chosen, else yellow
  CALL PrintInline        ; INTERFACE 2, then options 4 and 5 in yellow

; "3..INTERFACE 2", then in yellow "4..REDEFINE KEYS", "5..LOAD NEW LEVEL!"
;
; ZS's text for option 5 in the place and length of NE's "5..LOAD SAVED GAME":
; the same 18 characters, the 0 at $C191 where NE has it.
MenuMoreText:
  DEFM $03,$03,"3..INTERFACE 2" ; two rows down, (18,8): "3..INTERFACE 2"
  DEFM $03,$03,$02,"F4..REDEFINE KEYS" ; (20,8) in $46 (yellow): "4..REDEFINE
                                       ; KEYS"
  DEFM $03,$03,"5..LOAD NEW LEVEL!",$00 ; (22,8): "5..LOAD NEW LEVEL!"

; The main menu's keys: the title music until a key, then 0-5
;
; Waits until no key is held (each frame cycling the title's colours, $C820),
; plays the title music until a key ($C4A7), waits for a key (KEY-SCAN $028E,
; the character from the ROM's key table $0205): 0 returns Z, 1-3 set Controls
; and redraw the options, 4 RedefineKeys then the whole menu, 5 LoadNewLevel
; (JR Z at $C1B5 to $C1FD, NE's LoadGame address). Any other key is ignored.
MainMenuKeys:
  HALT                    ; wait until no key is held
  CALL TitleColourCycle   ; the title's colours, also while keys are still held
  CALL $028E              ; ROM KEY-SCAN: E = the key value, $FF none
  LD A,E                  ; E bit 7 set: no key
  OR A                    ; sets S from bit 7
  JP P,MainMenuKeys       ; a key still held (from the last choice): wait
  CALL MenuMusic          ; the title music, until a key
MenuWaitKey:
  HALT                    ; back from MenuMusic: a number key is down; one
                          ; frame
  CALL TitleColourCycle   ; the title's colours
  CALL $028E              ; ROM KEY-SCAN
  LD A,E                  ; E = $FF: no key
  OR A                    ; sets S from bit 7
  JP M,MenuWaitKey        ; none yet: wait
  LD HL,$0205             ; the key's character from the ROM's main key table
  ADD A,L                 ; $0205 + E (no carry: E is at most $27)
  LD L,A                  ; L = $05 + E
  LD A,(HL)               ; A = the key's character
  CP $35                  ; "5"?
  JR Z,LoadNewLevel       ; 5: LoadNewLevel ($C1FD)
  CP $30                  ; "0"?
  JR Z,MenuStart          ; 0: start
  CP $31                  ; "1"?
  JR Z,MenuKeyboard       ; 1: keyboard
  CP $32                  ; "2"?
  JR Z,MenuKempston       ; 2: Kempston
  CP $33                  ; "3"?
  JR Z,MenuInterface2     ; 3: Interface 2
  CP $34                  ; "4"?
  JR NZ,MenuWaitKey       ; any other key: ignored, wait again
  CALL RedefineKeys       ; 4: redefine the keys, then the whole menu again
  JP MainMenu             ; the whole menu again (clear, title, options, keys)
MenuStart:
  XOR A                   ; Z: a new game
  RET                     ; Z: Start goes on into NewGameSetup ($A62D)
MenuKeyboard:
  LD A,$01                ; 1: keyboard
  JR MenuSetControls      ; Controls = 1
MenuKempston:
  LD A,$02                ; 2: Kempston
  JR MenuSetControls      ; Controls = 2
MenuInterface2:
  LD A,$03                ; 3: Interface 2
MenuSetControls:
  LD (Controls),A         ; Controls, then the options again
  JP MainMenuOptions      ; reprint the options in the new colours, then the
                          ; keys (MenuMusic restarts)

; "ZS EDITION'98" in big white letters at the top
;
; Prints the inline TitleText: ZS EDITION'98 and a space at row 1, column 2,
; white ($47), each glyph 3 rows high and 2 bytes wide (rows 1-3, columns
; 2-29). The attributes of rows 0-6, columns 0-30 are recoloured every 2 frames
; by TitleColourCycle while the menu waits. Called by MainMenuTitle only (NE's
; LoadGame, its other caller, is gone).
PrintTitle:
  CALL PrintInline        ; the inline title text

; "ZS EDITION'98 " at (1,2), attribute $47, setting $32 (triple height, double
; width)
;
; ZS's title in the first bytes of NE's two-line "NETHER" / "EARTH": one line
; of 14 characters, ended by 0 at $C1FB, so the RET of PrintTitleEnd stays at
; $C1FC.
TitleText:
  DEFM $01,$01,$02,$02,"G",$04,"2" ; AT (1,2) in $47 (white), size $32: double
                                   ; width, three rows high
  DEFM "ZS EDITION'98 ",$00 ; "ZS EDITION'98 ", then the end 0

; PrintTitle's return
PrintTitleEnd:
  RET                     ; back to the caller after the title text

; Menu key 5, LOAD NEW LEVEL!: 62 NOPs, then 500 bytes from $DD00 become the
; level and the game restarts
;
; Reached by MainMenuKeys' JR Z at $C1B5 (key 5), NE's jump to its tape load at
; this address. $C1FD-$C23A are 62 zero bytes: NE's LoadGame and LoadGameBlocks
; (the title again, PRESS PLAY ON TAPE, LD-BYTES of the two blocks) cleared,
; run as NOPs. Then LoadLevelCopy: LDIR of 500 ($1F4) bytes $DD00 -> $BDA9
; (SceneryWest .. BaseListEast and the first byte of ShapeTable, $BF9C); the
; words at $DEF4, $DEF6, $DEF8, $DEFA (offset $1F4-$1FB of the 512 bytes at
; $DD00) into the operands of BuildMap's four LD HL,list ($BC8A, $BC92, $BCA2,
; $BCAA); POP BC drops Start's return address ($A62D, from CALL MainMenu); JP
; Start. Start shows the menu again; the next START GAME builds the map from
; the patched list addresses.
;
; The layout it expects is the '99's NELEV_xx.N file (512 bytes: the lists from
; 0, the four list addresses at $1F4; the '99 copies 499 bytes and also takes
; $1F3 and $1FC-$1FF), so ZS meant a disk read of such a file to $DD00 to come
; before the copy, in the 62 bytes he had cleared. It is not there: nothing
; reads the disk. What $DD00 holds is the copy's input: after the load the '98
; intro's scroller text (the intro block is read to $C000-$E9FF and the game,
; read to $6780-$D87F, does not reach it), after a game the map (cleared by
; BuildMap at every START GAME).
;
; Witness game98/key5 (the menu snapshot of r98 frame 4800, key 5 at frame 50,
; key 0 at 400): the 62 NOPs and the copy ran once (frame 50); the words at
; $DEF4-$DEFB were $20 $20 ... (scroller spaces), so all four list addresses
; became $2020, inside the ROM; the menu came back; START GAME (frame 400) ran
; NewGameSetup and BuildMap, whose PlaceScenery read 3-byte records from the
; ROM at $2020 ($D7 $78 $D7, ...): rows like $D7 put cells at $DD00 + $200 *
; row, wrapping round the 64 K into the game, and the 2 x 2 blocks wrote over
; code (by frame 416 the CALL at $BD67 read CALL $ED48); the CPU then ran
; through the map and the overwritten code and reached $0000 at frame 462 (the
; ROM's reset: the 48 BASIC copyright screen from frame 500 on,
; work/stage2/game98/key5-sheet.png).
LoadNewLevel:
  NOP                     ; 62 NOPs ($C1FD-$C23A): NE's tape load cleared to
                          ; zero, the disk read never written in
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
LoadLevelCopy:
  LD HL,$DD00             ; the level from $DD00 ...
  LD DE,SceneryWest       ; ... to SceneryWest (the first list) ...
  LD BC,$01F4             ; ... 500 bytes: the four lists and one byte more,
                          ; $BF9C (the first byte of ShapeTable)
  LDIR
  LD BC,($DEF4)           ; offset $1F4 of the file: the west scenery list's
                          ; address
  LD (BuildMap+$001B),BC  ; into BuildMap's LD HL,SceneryWest
  LD BC,($DEF6)           ; offset $1F6: the east scenery list's address
  LD (BuildMap+$0023),BC  ; into BuildMap's LD HL,SceneryEast
  LD BC,($DEF8)           ; offset $1F8: the west bases list's address
  LD (BuildMap+$0033),BC  ; into BuildMap's LD HL,BaseListWest
  LD BC,($DEFA)           ; offset $1FA: the east bases list's address
  LD (BuildMap+$003B),BC  ; into BuildMap's LD HL,BaseListEast
  POP BC                  ; drop Start's return address (CALL MainMenu at
                          ; $A62A)
  JP Start                ; the start-up again: the IM 2 table, the seed, the
                          ; menu

; 35 zero bytes: NE's LOADING ERROR! text and LoadError, cleared
;
; $C26A-$C28C. Nothing reads or runs them (no recording touched them; no
; instruction addresses them).
MenuLoadSpare:
  DEFS $23

; The SAVE key in play: three NOPs and RET (NE's tape save cleared)
;
; Called by PlayLoop's CheckGameKeys ($A71A) when Input bit 5 (the SAVE key of
; KeyTable) is set; PlayLoop then jumps to EnterPlay ($A68E), which redraws the
; play screen: in the '98 the SAVE key only redraws the screen. NE has LD
; HL,StartInterrupt / LD (Handler),HL / CALL PrintInline ... here (its tape
; save); ZS cleared it to zero and wrote a RET at $C290.
SaveGame:
  NOP                     ; NOP x3: NE's LD HL,StartInterrupt cleared
  NOP
  NOP
  RET                     ; back: PlayLoop redraws the screen and plays on

; 148 zero bytes: NE's save prompt, SaveGameBlocks and SaveChecksum, cleared
;
; $C291-$C324. Nothing reads or runs them.
MenuSaveSpare:
  DEFS $8E
ChecksumNext:
  DEFS $06                ; carry added into D; the next byte

; Wait until no key is held, then until one is (all half rows of port $FE)
;
; Reads all eight half rows at once (IN with A = 0: every address line A8-A15
; low), bits 0-4 inverted: a key held. First waits for all keys up, then for
; any key down; returns with the key still held. No joystick, no debounce.
; Called by SaveGameBlocks (start the tape) and LoadError.
WaitAnyKey:
  XOR A                   ; A = 0: all eight half rows
  IN A,($FE)              ; IN with address $00FE: every half row
  CPL                     ; a pressed key reads 0: invert
  AND $1F                 ; bits 0-4: the five keys of each half row
  JR NZ,WaitAnyKey        ; any key still down: wait
WaitAnyKeyDown:
  XOR A                   ; all half rows again
  IN A,($FE)              ; every half row
  CPL                     ; inverted
  AND $1F                 ; the five key bits
  JR Z,WaitAnyKeyDown     ; no key yet: wait
  RET                     ; a key is down

; The attribute for menu option C: cyan ($45) when it is the current Controls,
; else yellow ($46)
;
; C = the option's Controls value (1-3). Prints an inline attribute code: $45
; (cyan, bright) when Controls ($D3E4) is C, else $46 (yellow, bright); the
; option text printed next takes it. Called by the three option entries before
; their text; A and the flags are lost.
ControlsOptionAttr:
  LD A,(Controls)         ; A = Controls (1 keyboard, 2 Kempston, 3 Interface
                          ; 2)
  CP C                    ; this option?
  JR Z,ControlsOptionMarked ; yes: the cyan attribute
  CALL PrintInline        ; no: the yellow attribute code

; PrintInline: attribute $46
OptionAttrPlain:
  DEFB $02,$46,$00        ; attribute $46 (yellow): a control option not chosen

; ControlsOptionAttr's return, the option not chosen
ControlsOptionPlain:
  RET                     ; back to the option, which prints its text next
; This entry point is used by the routine at ControlsOptionAttr.
ControlsOptionMarked:
  CALL PrintInline        ; the option chosen

; PrintInline: attribute $45
OptionAttrChosen:
  DEFB $02,$45,$00        ; attribute $45 (cyan): the control option chosen
                          ; (Controls)

; ControlsOptionAttr's return, the option chosen
ControlsOptionChosen:
  RET                     ; back to the option

; Redefine the eight keys: UP, DOWN, LEFT, RIGHT, FIRE, PAUSE, ABORT, SAVE
;
; Key 4 of the main menu. Clears the screen, prints REDEFINE KEYS, waits until
; no key is held, clears KeyTable and asks for each key in turn: PrintKeyPrompt
; prints "PRESS KEY FOR " and the name that follows the CALL, DefineKey waits
; for a key not yet taken and fills the KeyTable record whose third byte HL
; points at (the port's high byte, the bit mask, the key code) and prints the
; key. KeyTable's records 0-7 are PAUSE, ABORT, SAVE, FIRE, UP, DOWN, LEFT,
; RIGHT: Input bits 7 to 0. Waits for the last key's release and about 0.5 s,
; then back to the menu.
;
; Verified on NE's own instance: keys Q A O P M H B S gave KeyTable bf 10 48 /
; 7f 10 42 / fd 02 53 / 7f 04 4d / fb 01 51 / fd 01 41 / df 02 4f / df 01 50,
; the screen showed PRESS KEY FOR UP .. PAUSE with each key's letter, and the
; menu came back.
RedefineKeys:
  CALL ClearScreen        ; a blank screen for the redefine screen
  CALL PrintInline        ; the heading and the first print position

; "REDEFINE KEYS" at (2,9), white, double height, then position (5,3) and
; normal size
RedefineTitleText:
  DEFM $01,$02,$09,$02,"G",$04,"!REDEFINE KEYS" ; "REDEFINE KEYS" at (2,9) in
                                                ; $47 (white), tall (size $21)
  DEFM $01,$05,$03,$04,$00,$00 ; then AT (5,3) and size 0: the first PRESS KEY
                               ; FOR line goes two rows below

; Wait for no key, clear KeyTable, ask for UP
RedefineKeysBody:
  CALL $028E              ; wait until no key is held
  LD A,E                  ; E bit 7 set: no key
  OR A                    ; sets S from bit 7
  JP P,RedefineKeysBody   ; key 4 is still held: wait for its release
  LD HL,KeyTable          ; KeyTable: 24 bytes of 0
  LD DE,KeyTable+$0001    ; DE = HL + 1: the LDIR spreads the 0
  LD BC,$0017             ; 23 more bytes: the whole table, 8 records of 3
  LD (HL),$00             ; the first byte 0
  LDIR                    ; KeyTable all 0: no key is taken yet
  CALL PrintKeyPrompt     ; "PRESS KEY FOR" and the name below

; "   UP"
KeyNameUp:
  DEFM "   UP",$00        ; the action's name after PRESS KEY FOR: UP (Input
                          ; bit 3, KeyTable record 4)

; The key for UP (KeyTable record 4), then ask for DOWN
ReadUpKey:
  LD HL,KeyTable+$000E    ; HL = the code byte of record 4 (Input bit 3, UP)
  CALL DefineKey          ; wait for a free key, fill the record, print its
                          ; name
  CALL PrintKeyPrompt     ; the next prompt

; " DOWN"
KeyNameDown:
  DEFM " DOWN",$00        ; the action's name after PRESS KEY FOR: DOWN (Input
                          ; bit 2, KeyTable record 5)

; The key for DOWN (record 5), then ask for LEFT
ReadDownKey:
  LD HL,KeyTable+$0011    ; record 5 (Input bit 2, DOWN)
  CALL DefineKey          ; wait for the DOWN key, fill record 5, print its
                          ; name
  CALL PrintKeyPrompt     ; the next prompt

; " LEFT"
KeyNameLeft:
  DEFM " LEFT",$00        ; the action's name after PRESS KEY FOR: LEFT (Input
                          ; bit 1, KeyTable record 6)

; The key for LEFT (record 6), then ask for RIGHT
ReadLeftKey:
  LD HL,KeyTable+$0014    ; record 6 (Input bit 1, LEFT)
  CALL DefineKey          ; the LEFT key into record 6
  CALL PrintKeyPrompt     ; the next prompt

; "RIGHT"
KeyNameRight:
  DEFM "RIGHT",$00        ; the action's name after PRESS KEY FOR: RIGHT (Input
                          ; bit 0, KeyTable record 7)

; The key for RIGHT (record 7), then ask for FIRE
ReadRightKey:
  LD HL,KeyTable+$0017    ; record 7 (Input bit 0, RIGHT)
  CALL DefineKey          ; the RIGHT key into record 7
  CALL PrintKeyPrompt     ; the next prompt

; " FIRE"
KeyNameFire:
  DEFM " FIRE",$00        ; the action's name after PRESS KEY FOR: FIRE (Input
                          ; bit 4, KeyTable record 3)

; The key for FIRE (record 3), a blank line, then ask for PAUSE
ReadFireKey:
  LD HL,KeyTable+$000B    ; record 3 (Input bit 4, FIRE)
  CALL DefineKey          ; the FIRE key into record 3
  CALL PrintNewline       ; a blank row between the moves and the game keys
  CALL PrintKeyPrompt     ; the next prompt

; "PAUSE"
KeyNamePause:
  DEFM "PAUSE",$00        ; the action's name after PRESS KEY FOR: PAUSE (Input
                          ; bit 7, KeyTable record 0)

; The key for PAUSE (record 0), then ask for ABORT
ReadPauseKey:
  LD HL,KeyTable+$0002    ; record 0 (Input bit 7, PAUSE)
  CALL DefineKey          ; the PAUSE key into record 0
  CALL PrintKeyPrompt     ; the next prompt

; "ABORT"
KeyNameAbort:
  DEFM "ABORT",$00        ; the action's name after PRESS KEY FOR: ABORT (Input
                          ; bit 6, KeyTable record 1)

; The key for ABORT (record 1), then ask for SAVE
ReadAbortKey:
  LD HL,KeyTable+$0005    ; record 1 (Input bit 6, ABORT)
  CALL DefineKey          ; the ABORT key into record 1
  CALL PrintKeyPrompt     ; the last prompt

; " SAVE"
KeyNameSave:
  DEFM " SAVE",$00        ; the action's name after PRESS KEY FOR: SAVE (Input
                          ; bit 5, KeyTable record 2)

; The key for SAVE (record 2), wait for its release and a pause, back to the
; menu
ReadSaveKey:
  LD HL,KeyTable+$0008    ; record 2 (Input bit 5, SAVE)
  CALL DefineKey          ; the SAVE key into record 2
RedefineWaitRelease:
  CALL $028E              ; until the SAVE key is let go
  LD A,E                  ; E bit 7 set: no key
  OR A                    ; sets S from bit 7
  JP P,RedefineWaitRelease ; the last key still held: wait
  LD BC,$0000             ; all keys up: a fixed pause of 65536 turns of the
                          ; loop below (about 2 million T, 0.56 s) before the
                          ; menu
RedefineKeysPause:
  DEC BC                  ; count BC down from $0000 through all 65536 values
RedefineKeysPauseNop:
  NOP                     ; a pad (the label is a false entry of the static
                          ; walk: the string bytes before it read as JR
                          ; NZ,$C406)
  LD A,C                  ; BC = 0 after 65536 turns?
  OR B                    ; Z when BC = 0
  JR NZ,RedefineKeysPause ; not yet
  RET                     ; back to the caller of $C34A, which restarts the
                          ; main menu ($C1CE)

; "PRESS KEY FOR " and then the key's name that follows the caller's CALL
;
; Called by the redefine-keys screen ($C37F, $C38E, ... $C3EB) once for each of
; the eight keys, with the key's name (UP, DOWN, LEFT, RIGHT, FIRE, PAUSE,
; ABORT, SAVE) as an inline string after the CALL. It prints its own inline
; text (two new lines, attribute $46, "PRESS KEY FOR ", attribute $45), then
; jumps (not calls) to PrintInline at $C424: the return address on the stack is
; then the caller's, so PrintInline prints the caller's name string and returns
; past it. One prompt takes two screen rows.
PrintKeyPrompt:
  CALL PrintInline        ; our own text first

; PrintInline text: new line, new line, attribute $46, "PRESS KEY FOR ",
; attribute $45
PressKeyForText:
  DEFM $03,$03,$02,"FPRESS KEY FOR " ; two rows down, attribute $46 (yellow):
                                     ; "PRESS KEY FOR "
  DEFM $02,"E",$00        ; attribute $45 (cyan) for the action's name that
                          ; follows the CALL

; print the caller's inline key name and return past it
;
; The tail of PrintKeyPrompt: a JP to PrintInline with the caller's return
; address on top of the stack, so the bytes after the caller's CALL $C40C (the
; name of the key to press) are printed and skipped.
PrintKeyPromptName:
  JP PrintInline          ; the caller's string, and back past it

; wait for a free key, store its port, mask and code into a KeyTable entry,
; print its name
;
; HL = the code byte (the third byte) of a KeyTable entry; the redefine screen
; passes the entries in the order UP (+$0E), DOWN (+$11), LEFT (+$14), RIGHT
; (+$17), FIRE (+$0B), PAUSE (+$02), ABORT (+$05), SAVE (+$08), so the entries
; map to the Input bits 3, 2, 1, 0, 4, 7, 6, 5 (ReadControls shifts entry 0
; into bit 7). The screen cleared the whole table before the first key, so only
; keys already defined in this pass count as taken.
;
; It prints two spaces and sets attribute $46, then waits with the ROM KEY-SCAN
; ($028E) for a key; the key value E (0-39, row index 0-7 in bits 0-2, bit
; position from bit 4 down in bits 3-5) is turned into a code through the ROM
; key table $0205 (CAPS SHIFT gives $E3, the first byte past the table). A key
; whose code is already in one of the eight entries is refused and the wait
; goes on. Then it writes the code, the bit mask $20 >> (E/8 + 1) and the port
; high byte ($7F for row 0 down to $FE for row 7) backwards into the entry, and
; prints the key's name: SYM SH, ENTER, CAPS SH, SPACE, or the code as a
; character.
;
; Experiment: key 4 at the menu, then Q, Q, A, O, P, SPACE, ENTER, CAPS SHIFT,
; SYMBOL SHIFT left KeyTable = FB 01 51 / FD 01 41 / DF 02 4F / DF 01 50 for UP
; / DOWN / LEFT / RIGHT, 7F 01 20 for FIRE, BF 01 0D, FE 01 E3, 7F 02 0E for
; PAUSE / ABORT / SAVE; the second Q was refused.
DefineKey:
  PUSH HL                 ; keep the entry's address
  CALL PrintInline        ; two spaces, then the attribute of the name

; PrintInline text: two spaces, attribute $46
DefineKeyBlank:
  DEFM "  ",$02,"F",$00   ; two spaces after the name, then $46 (yellow) for
                          ; the key chosen

; wait for a key that no entry holds yet
;
; Continues DefineKey after its inline text. On exit the entry is filled and
; the name printed (the RET is the one after each name string, or the one in
; PrintCharKeep's path for a plain character).
DefineKeyScan:
  CALL $028E              ; ROM KEY-SCAN: E = the key value, $FF none
  LD A,E                  ; E bit 7 set: no key
  OR A                    ; sets S from bit 7
  JP M,DefineKeyScan      ; no key yet
  LD HL,$0205             ; the ROM's key table: E -> the key's code
  ADD A,L                 ; $0205 + E (CAPS SHIFT alone, E = $27, reads $E3
                          ; just past the table)
  LD L,A                  ; L = $05 + E (no carry: E is at most $27)
  LD A,(HL)               ; A = the key's code (a character, $0D ENTER, $0E SYM
                          ; SHIFT, $20 SPACE, $E3 CAPS SHIFT)
  LD D,A                  ; D = the code
  LD HL,KeyTable+$0002    ; the code bytes of the eight entries
  LD B,$08                ; eight records
KeyTakenLoop:
  CP (HL)                 ; a code already used is refused: wait again
  JR Z,DefineKeyScan      ; this code is taken: refused, scan again (the entry
                          ; address stays pushed)
  INC HL                  ; HL + 3 ...
  INC HL                  ; (3 bytes a record)
  INC HL                  ; ... the next record's code byte
  DJNZ KeyTakenLoop       ; eight codes compared
  POP HL                  ; HL = the entry's code byte
  LD (HL),A               ; store the code
  LD A,E                  ; C = the row index (0 = port $7FFE ... 7 = port
                          ; $FEFE)
  AND $07                 ; the row: bits 0-2 of E
  LD C,A                  ; C = the row index 0-7
  SRL E                   ; E / 2: three shifts make E / 8, the key's place in
                          ; its half-row from bit 4 down
  SRL E                   ; E / 4
  SRL E                   ; E / 8, 0-4
  LD B,E                  ; B = E/8 + 1 rotations
  INC B                   ; one more than the place
  LD A,$20                ; the mask: $20 rotated right E/8 + 1 times
KeyMaskShift:
  RRCA                    ; one place right: bit 4 - E/8 is the key's bit
  DJNZ KeyMaskShift       ; B rotations: $10 for E/8 = 0 ... $01 for E/8 = 4
  DEC HL                  ; the entry's mask byte
  LD (HL),A               ; store the mask
  LD B,C                  ; the port high byte: row + 1 RRAs of $FF with the
                          ; carry clear, the 0 walking right ($7F row 0 ... $FE
                          ; row 7)
  INC B                   ; B = row + 1 rotations
  XOR A                   ; A = 0, carry clear
  DEC A                   ; A = $FF; DEC leaves the carry clear
KeyPortShift:
  RRA                     ; the one 0 bit walks right ($7F, $BF ... $FE), ones
                          ; come in from the carry
  DJNZ KeyPortShift       ; B rotations
  DEC HL                  ; the entry's port byte
  LD (HL),A               ; store the port high byte: the record is complete
  LD A,D                  ; the code decides the name
  CP $0E                  ; SYMBOL SHIFT
  JR NZ,CheckEnterKey     ; not SYMBOL SHIFT
  CALL PrintInline        ; its name, and the RET after the string

; PrintInline text: "SYM SH"
KeyNameSymShift:
  DEFM "SYM SH",$00       ; the name of key code $0E: SYMBOL SHIFT (the default
                          ; KeyTable has $82 there)

; a RET ($C9): PrintInline returns here and the routine ends
KeyNameSymShiftEnd:
  RET                     ; the end of DefineKey

; DefineKey: is the new key ENTER?
;
; Part of DefineKey ($C427): code $0D prints "ENTER" and returns through the
; RET placed after the string.
CheckEnterKey:
  CP $0D                  ; ENTER
  JR NZ,CheckCapsShiftKey ; not ENTER
  CALL PrintInline        ; its name, and the RET after the string

; PrintInline text: "ENTER"
KeyNameEnter:
  DEFM "ENTER",$00        ; the name of key code $0D: ENTER

; a RET ($C9) after the string
KeyNameEnterEnd:
  RET                     ; the end of DefineKey

; DefineKey: is the new key CAPS SHIFT?
;
; Part of DefineKey ($C427): code $E3 (the byte after the ROM's key table, what
; CAPS SHIFT alone looks up) prints "CAPS SH".
CheckCapsShiftKey:
  CP $E3                  ; CAPS SHIFT
  JR NZ,CheckSpaceKey     ; not CAPS SHIFT
  CALL PrintInline        ; its name, and the RET after the string

; PrintInline text: "CAPS SH"
KeyNameCapsShift:
  DEFM "CAPS SH",$00      ; the name of key code $E3: CAPS SHIFT (the byte past
                          ; the ROM key table)

; a RET ($C9) after the string
KeyNameCapsShiftEnd:
  RET                     ; the end of DefineKey

; DefineKey: SPACE prints its name, any other key prints its own character
;
; Part of DefineKey ($C427). A code other than $20 goes to PrintCharKeep (print
; the character A) and returns from there.
CheckSpaceKey:
  CP $20                  ; SPACE
  JP NZ,PrintCharKeep     ; any other key: print its code as a character and
                          ; return
  CALL PrintInline        ; "SPACE"

; PrintInline text: "SPACE"
KeyNameSpace:
  DEFM "SPACE",$00        ; the name of key code $20: SPACE

; RET: the end of DefineKey; also the target of the music's command 0
;
; The RET after the SPACE name. The two command tables of the menu music
; ($C553, $C572) point their command 0 here; command 0 never occurs in the
; tune, and it would not work: the dispatch leaves the voice pointer pushed, so
; this RET would return into the tune data.
DefineKeyDone:
  RET                     ; the end of DefineKey for SPACE
