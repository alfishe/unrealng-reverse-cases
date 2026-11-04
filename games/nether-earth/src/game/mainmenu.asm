; --------------------------------------------------------------------------------------------------------------------
; mainmenu.asm: The main menu, the tape save and load of a game, the redefine-keys screen
;
; What the player sees before a game and when it ends: the title NETHER EARTH, the six options 0-5, the menu tune, the
; redefine screen, the saved-game tape load; and the SAVE key's tape save in play. Docs: 05-controls.md 5.2 (the menu,
; the redefine screen), 03-build-and-load.md 3.6 (the saved game), 08-hud-and-text.md 8.1 (the inline strings).
;
; Calling order: Start ($A62A) calls MainMenu: ClearScreen, PrintTitle, the options (each option's colour from
; ControlsOptionAttr), then MainMenuKeys: wait for all keys up, MenuMusic (module music) until a number key, then KEY-
; SCAN and the ROM key table decide: 0 MenuStart (Z), 1-3 MenuSetControls (Controls, the options again: MenuMusic
; restarts), 4 RedefineKeys (then the whole menu), 5 LoadGame -> LoadGameBlocks (NZ, or LOADING ERROR -> Start).
; SaveGame / SaveGameBlocks are called from the play loop ($A71A), not from the menu.
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
; The tape format: two headerless blocks with flag $00, the 2-byte sum (kept at ViewBuffer $5B00) and $24D1 bytes from
; SaveShots $D92B to $FDFB (Shots and Buildings staged there, the robots, the map, the variables). The ROM routines
; are entered past their set-up: LD-BYTES at $0562, SA-BYTES at $04D0 (no SA/LD-RET pushed, so the game does the
; border and the EI itself). Only the byte sum decides a good load; the key table and Controls are not saved.
; --------------------------------------------------------------------------------------------------------------------

; The main menu: clear the screen, the title, the options; Z = start a new
; game, NZ = a game was loaded
;
; Called by Start ($A62A); Start goes on to the new game set-up on Z and
; straight to play on NZ ($A62D). Prints the title (PrintTitle) and the options
; 0-5; the current controls (Controls, $D3E4) show in cyan, the others in
; yellow ($C336). Then MainMenuKeys. Keys 1-3 choose the controls and redraw
; the options, 4 redefines the keys and redraws the whole menu, 5 loads a saved
; game, 0 starts.
;
; Verified on the own instance: the menu reads 0..START GAME, 1..KEYBOARD
; (cyan), 2..KEMPSTON J/S, 3..INTERFACE 2, 4..REDEFINE KEYS, 5..LOAD SAVED
; GAME.
MainMenu:
  CALL ClearScreen        ; the menu starts on an empty black screen

; The main menu without the clearing: the title, then the options
;
; The entry of MainMenu after ClearScreen; nothing jumps here (MainMenuKeys key
; 4 jumps to MainMenu itself). Falls into MainMenuOptions.
MainMenuTitle:
  CALL PrintTitle         ; NETHER EARTH in big letters

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
  DEFM $02,"F",$04,"!",$01,$0B,$08,"0..START GAME",$04,$00,$00

; Option 1, KEYBOARD, in the colour of Controls 1
MenuKeyboardOption:
  LD C,$01                ; option 1: Controls value 1
  CALL ControlsOptionAttr ; cyan if it is the current choice, else yellow
  CALL PrintInline        ; the KEYBOARD text

; Two new lines and "1..KEYBOARD"
MenuKeyboardText:
  DEFM $03,$03,$03,"1..KEYBOARD",$00

; Option 2, KEMPSTON J/S, in the colour of Controls 2
MenuKempstonOption:
  LD C,$02                ; option 2: Controls value 2
  CALL ControlsOptionAttr ; cyan if chosen, else yellow
  CALL PrintInline        ; the KEMPSTON J/S text

; Two new lines and "2..KEMPSTON J/S"
MenuKempstonText:
  DEFM $03,$03,"2..KEMPSTON J/S",$00

; Option 3, INTERFACE 2, in the colour of Controls 3; then options 4 and 5
MenuInterface2Option:
  LD C,$03                ; option 3: Controls value 3
  CALL ControlsOptionAttr ; cyan if chosen, else yellow
  CALL PrintInline        ; INTERFACE 2, then options 4 and 5 in yellow

; "3..INTERFACE 2", then in yellow "4..REDEFINE KEYS", "5..LOAD SAVED GAME"
MenuMoreText:
  DEFM $03,$03,"3..INTERFACE 2",$03,$03,$02,"F4..REDEFINE KEYS",$03,$03,"5..LOAD SAVED GAME",$00

; The main menu's keys: the title music until a key, then 0-5
;
; Waits until no key is held (each frame cycling the title's colours, $C820),
; plays the title music until a key ($C4A7), waits for a key (KEY-SCAN $028E,
; the character from the ROM's key table $0205): 0 returns Z, 1-3 set Controls
; and redraw the options, 4 RedefineKeys then the whole menu, 5 the load. Any
; other key is ignored.
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
  JR Z,LoadGame           ; 5: load a saved game
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

; "NETHER" and "EARTH" in big white letters at the top
;
; Prints the inline TitleText: NETHER at row 1 column 10 and EARTH at row 5
; column 11, white ($47), each glyph 3 rows high and 2 bytes wide. The
; attributes of rows 1-7, columns 10-21 are recoloured every 2 frames by
; TitleColourCycle while the menu waits. Called by MainMenuTitle and by
; LoadGame (which reprints it before PRESS PLAY ON TAPE).
PrintTitle:
  CALL PrintInline        ; the inline title text

; "NETHER" at (1,10) and "EARTH" at (5,11), attribute $47, setting $32 (triple
; height, double width)
TitleText:
  DEFM $01,$01,$0A,$02,"G",$04,"2NETHER",$01,$05,$0B,"EARTH",$00

; PrintTitle's return; then the load option
PrintTitleEnd:
  RET                     ; back to the caller after the title text
; This entry point is used by the routine at MainMenuKeys.
LoadGame:
  CALL PrintTitle         ; key 5: the title again, PRESS PLAY ON TAPE
  CALL PrintInline        ; the prompt, then on into the load

; "PRESS PLAY ON TAPE" at (22,7), cyan, double height
PlayTapeText:
  DEFM $01,$16,$07,$02,"E",$04,"!PRESS PLAY ON TAPE ",$00

; Load a saved game: the checksum block, the game block; NZ when it is good
;
; Red border. Loads two headerless blocks (flag $00) through the ROM's LD-BYTES
; past its border set-up ($0562, the INC D / EX AF,AF' / DEC D / DI before it
; done here): 2 bytes to $5B00 (the checksum), then $24D1 bytes to $D92B-$FDFB.
; If SaveChecksum of the block matches, the first 45 bytes go back to $D7D3
; (the 5 records of 9 bytes $B0E3 walks) and the next 168 to Buildings; returns
; NZ (MainMenu's caller skips the new game set-up). A mismatch prints LOADING
; ERROR!, beeps, waits for a key and restarts (Start).
;
; Not run in any recording; read from the code and the ROM's entry points. The
; block holds the robots ($DA00), the map ($DD00-$FCFF) and the variables
; $FD00-$FDFB (resources, clock, bases), so a load restores the whole game.
LoadGameBlocks:
  LD A,$02                ; red border while it loads
  OUT ($FE),A             ; border red ($02)
  LD IX,ViewBuffer        ; 2 bytes: the checksum
  LD DE,$0002             ; DE = 2 bytes
  XOR A                   ; flag $00, carry set: load
  SCF                     ; carry set: LOAD, not VERIFY
  INC D                   ; INC D / DEC D with the flags saved between: NZ in
                          ; AF' as LD-BYTES wants
  EX AF,AF'               ; AF' = flag $00, load
  DEC D                   ; D back to 0
  DI                      ; LD-BYTES runs with interrupts off
  CALL $0562              ; ROM LD-BYTES past its border set-up and the
                          ; SA/LD-RET push; its error carry is not looked at
  LD IX,SaveShots         ; the game block
  LD DE,$24D1             ; DE = $24D1 bytes: $D92B-$FDFB
  XOR A                   ; flag $00
  SCF                     ; load
  INC D                   ; NZ into AF' as before
  EX AF,AF'               ; AF' = flag $00, load, NZ
  DEC D                   ; D back to 0 (DE = $24D1)
  DI                      ; interrupts off
  CALL $0562              ; ROM LD-BYTES: the robots, the map, the variables,
                          ; the staged shots and buildings
  XOR A                   ; border black again
  OUT ($FE),A             ; (also MIC / EAR off)
  CALL SaveChecksum       ; DE = the block's sum
  LD HL,(ViewBuffer)      ; the saved sum
  AND A                   ; clear the carry for the SBC
  SBC HL,DE               ; HL = the saved sum - the sum of the loaded block
  LD A,H                  ; HL = 0: the sums agree
  OR L                    ; Z: equal
  JR NZ,LoadBad           ; they differ: LOADING ERROR!
  LD HL,SaveShots         ; good: the staged tables back to their places
  LD DE,Shots             ; the 5 records of 9 bytes at $D7D3
  LD BC,$002D             ; 45 bytes: 5 records of 9
  LDIR                    ; SaveShots -> Shots; HL now SaveBuildings
  LD DE,Buildings             ; the buildings
  LD BC,$00A8             ; 168 bytes: 56 records of 3
  LDIR                    ; SaveBuildings -> Buildings
  EI                      ; LD-BYTES left interrupts off
  OR $01                  ; NZ: a game was loaded
  RET                     ; NZ: Start skips the new game set-up and goes to
                          ; EnterPlay
LoadBad:
  CALL PrintInline        ; LOADING ERROR!

; "LOADING ERROR!" at (22,2), white, double size
LoadErrorText:
  DEFM $01,$16,$02,$02,"G",$04,"\"LOADING ERROR!",$00

; After LOADING ERROR!: a beep, a key, then the start again (Start)
;
; Beep with A = $FA (about 530 Hz for 0.24 s, the game standing still),
; WaitAnyKey, then JP Start: the whole start-up again (IM 2 table, seed, the
; menu). The tables LoadGameBlocks has half loaded are not cleaned up:
; NewGameSetup rebuilds everything at the next 0.
LoadError:
  LD A,$FA                ; the error beep: half-period delay $FA
  CALL Beep               ; about 530 Hz for 0.24 s
  CALL WaitAnyKey         ; a key to go on
  JP Start                ; the whole start-up again, then the menu

; Save the game to tape: the prompt, a key, the checksum block and the game
; block
;
; Called from the game loop when the SAVE key (Input bit 5, KeyTable record 2)
; is held ($A71A); the loop then redraws the screen and returns to play
; ($A68E). Installs StartInterrupt as the handler, prints PRESS RECORD AND PLAY
; / THEN ANY KEY at row 22, waits for a key, copies the 45 bytes at $D7D3 and
; Buildings to $D92B-$D9FF so that $D92B-$FDFB is one block, sums it into $5B00
; and saves the 2 bytes and the block (flag $00) through the ROM's SA-BYTES
; past its pilot choice ($04D0) with a short pilot (HL = $0900).
;
; Not run in any recording; read from the code and the ROM's entry points.
; LoadGameBlocks reads the same two blocks.
SaveGame:
  LD HL,StartInterrupt    ; the start-up's handler: the play handler's work
                          ; stops
  LD (Handler),HL           ; Handler: StartInterrupt
  CALL PrintInline        ; the prompt at row 22

; "PRESS RECORD AND PLAY ", a new line, "     THEN ANY KEY     " at (22,0),
; cyan
RecordText:
  DEFM $01,$16,$00,$02,"EPRESS RECORD AND PLAY ",$03,"     THEN ANY KEY     ",$00

; After the prompt: a key, the staging, the checksum, the two blocks
SaveGameBlocks:
  CALL WaitAnyKey         ; the player starts the tape and presses a key
  LD A,$01                ; the radar map is rebuilt afterwards
  LD (RadarDirty),A            ; RadarDirty: the staging below overwrites the tail
                          ; of RadarEnemy
  LD HL,Shots             ; stage the 5 records of 9 bytes at $D7D3 ...
  LD DE,SaveShots         ; to SaveShots ($D92B)
  LD BC,$002D             ; 45 bytes
  LDIR                    ; Shots -> SaveShots; DE now SaveBuildings
  LD HL,Buildings             ; ... and the buildings at $D958
  LD BC,$00A8             ; 168 bytes
  LDIR                    ; Buildings -> SaveBuildings: $D92B-$FDFB is now the
                          ; whole game
  DI                      ; no interrupts while the tape runs
  CALL SaveChecksum       ; the checksum
  LD (ViewBuffer),DE      ; the sum at $5B00, the first tape block
  LD HL,$0900             ; a short pilot
  LD IX,ViewBuffer        ; the 2 checksum bytes, flag $00
  LD DE,$0002             ; 2 bytes
  XOR A                   ; flag $00
  SCF                     ; carry set as for the ROM's own callers; this entry
                          ; does not use it
  CALL $04D0              ; ROM SA-BYTES past its pilot choice: HL = the pilot,
                          ; A = the flag
  LD HL,$0900             ; the game block $D92B-$FDFB
  LD IX,SaveShots         ; from SaveShots ...
  LD DE,$24D1             ; ... $24D1 bytes, to $FDFB
  XOR A                   ; flag $00
  SCF                     ; (unused, as above)
  CALL $04D0              ; ROM SA-BYTES: the game block
  XOR A                   ; border black
  OUT ($FE),A             ; (MIC off)
  EI                      ; interrupts back on (the caller then redraws the
                          ; play screen)
  RET                     ; back to the play loop ($A71D)

; DE = the 16-bit sum of the $24D1 bytes at $D92B (the saved game block)
;
; Out: DE = the plain 16-bit sum of the $24D1 (9425) bytes $D92B-$FDFB, HL =
; $FDFC, BC = 0, A = 0. Keeps IX. Called by SaveGameBlocks (the sum is saved
; first, at $5B00) and by LoadGameBlocks (compared with the loaded one).
SaveChecksum:
  LD HL,SaveShots         ; HL = the block's start
  LD BC,$24D1             ; BC = its length
  LD DE,$0000             ; DE = the sum, from 0
ChecksumLoop:
  LD A,(HL)               ; the next byte
  INC HL                  ; HL to the next byte
  ADD A,E                 ; added into E ...
  LD E,A                  ; E = the low byte of the sum
  JR NC,ChecksumNext      ; ... with the carry into D
  INC D                   ; the carry into the high byte
ChecksumNext:
  DEC BC                  ; carry added into D; the next byte
  LD A,B                  ; until BC = 0
  OR C                    ; Z when BC = 0
  JR NZ,ChecksumLoop      ; more bytes
  RET                     ; DE = the sum

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
  DEFB $02,$46,$00

; ControlsOptionAttr's return, the option not chosen
ControlsOptionPlain:
  RET                     ; back to the option, which prints its text next
; This entry point is used by the routine at ControlsOptionAttr.
ControlsOptionMarked:
  CALL PrintInline        ; the option chosen

; PrintInline: attribute $45
OptionAttrChosen:
  DEFB $02,$45,$00

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
; Verified on the own instance: keys Q A O P M H B S gave KeyTable bf 10 48 /
; 7f 10 42 / fd 02 53 / 7f 04 4d / fb 01 51 / fd 01 41 / df 02 4f / df 01 50,
; the screen showed PRESS KEY FOR UP .. PAUSE with each key's letter, and the
; menu came back.
RedefineKeys:
  CALL ClearScreen        ; a blank screen for the redefine screen
  CALL PrintInline        ; the heading and the first print position

; "REDEFINE KEYS" at (2,9), white, double height, then position (5,3) and
; normal size
RedefineTitleText:
  DEFM $01,$02,$09,$02,"G",$04,"!REDEFINE KEYS",$01,$05,$03,$04,$00,$00

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
  DEFM "   UP",$00

; The key for UP (KeyTable record 4), then ask for DOWN
ReadUpKey:
  LD HL,KeyTable+$000E    ; HL = the code byte of record 4 (Input bit 3, UP)
  CALL DefineKey          ; wait for a free key, fill the record, print its
                          ; name
  CALL PrintKeyPrompt     ; the next prompt

; " DOWN"
KeyNameDown:
  DEFM " DOWN",$00

; The key for DOWN (record 5), then ask for LEFT
ReadDownKey:
  LD HL,KeyTable+$0011    ; record 5 (Input bit 2, DOWN)
  CALL DefineKey          ; wait for the DOWN key, fill record 5, print its
                          ; name
  CALL PrintKeyPrompt     ; the next prompt

; " LEFT"
KeyNameLeft:
  DEFM " LEFT",$00

; The key for LEFT (record 6), then ask for RIGHT
ReadLeftKey:
  LD HL,KeyTable+$0014    ; record 6 (Input bit 1, LEFT)
  CALL DefineKey          ; the LEFT key into record 6
  CALL PrintKeyPrompt     ; the next prompt

; "RIGHT"
KeyNameRight:
  DEFM "RIGHT",$00

; The key for RIGHT (record 7), then ask for FIRE
ReadRightKey:
  LD HL,KeyTable+$0017    ; record 7 (Input bit 0, RIGHT)
  CALL DefineKey          ; the RIGHT key into record 7
  CALL PrintKeyPrompt     ; the next prompt

; " FIRE"
KeyNameFire:
  DEFM " FIRE",$00

; The key for FIRE (record 3), a blank line, then ask for PAUSE
ReadFireKey:
  LD HL,KeyTable+$000B    ; record 3 (Input bit 4, FIRE)
  CALL DefineKey          ; the FIRE key into record 3
  CALL PrintNewline       ; a blank row between the moves and the game keys
  CALL PrintKeyPrompt     ; the next prompt

; "PAUSE"
KeyNamePause:
  DEFM "PAUSE",$00

; The key for PAUSE (record 0), then ask for ABORT
ReadPauseKey:
  LD HL,KeyTable+$0002    ; record 0 (Input bit 7, PAUSE)
  CALL DefineKey          ; the PAUSE key into record 0
  CALL PrintKeyPrompt     ; the next prompt

; "ABORT"
KeyNameAbort:
  DEFM "ABORT",$00

; The key for ABORT (record 1), then ask for SAVE
ReadAbortKey:
  LD HL,KeyTable+$0005    ; record 1 (Input bit 6, ABORT)
  CALL DefineKey          ; the ABORT key into record 1
  CALL PrintKeyPrompt     ; the last prompt

; " SAVE"
KeyNameSave:
  DEFM " SAVE",$00

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
  DEFM $03,$03,$02,"FPRESS KEY FOR ",$02,"E",$00

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
  DEFM "  ",$02,"F",$00

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
  DEFM "SYM SH",$00

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
  DEFM "ENTER",$00

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
  DEFM "CAPS SH",$00

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
  DEFM "SPACE",$00

; RET: the end of DefineKey; also the target of the music's command 0
;
; The RET after the SPACE name. The two command tables of the menu music
; ($C553, $C572) point their command 0 here; command 0 never occurs in the
; tune, and it would not work: the dispatch leaves the voice pointer pushed, so
; this RET would return into the tune data.
DefineKeyDone:
  RET                     ; the end of DefineKey for SPACE
