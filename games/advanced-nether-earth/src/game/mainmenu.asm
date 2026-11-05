; --------------------------------------------------------------------------------------------------------------------
; mainmenu.asm: the main menu, the disk load and save hooks, the redefine-keys screen, the dead tape code
;
; What the player sees before a game: the menu picture (MenuPicture, drawn by bank 3's code), the six options 0..СТАРТ
; ИГРЫ to 5..ЗАГРУЗКА, the tune (MusicInterrupt), the redefine screen; key 5 loads a saved game from the disk
; (LoadGame -> GameLoad). In play the save key comes here too: PlayLoop jumps to SaveGameStage, which stages the shots
; and the buildings and goes on to GameSave.
;
; Calling order: Restart ($A62A) calls MainMenu: ClearScreen, MenuPicture, the options (each option's colour from
; ControlsOptionAttr), MenuOptionsEnd, then MainMenuKeys: wait for all keys up, then a key a frame, KEY-SCAN and the
; ROM key table decide: 0 MenuStart (Z), 1-3 MenuSetControls (Controls, the options again), 4 RedefineKeys (then the
; whole menu), 5 LoadGame (no return: the game comes back through LoadReturn).
;
; The menu does not use KeyTable or ReadControls: it reads the keyboard with the ROM's KEY-SCAN ($028E) and the ROM's
; key table ($0205), so 0-5 work whatever keys were defined. RedefineKeys clears and refills KeyTable (module
; controls) through DefineKey: a key value E becomes the 3-byte record (port high byte, bit mask, code) ReadControls
; reads.
;
; Inline strings everywhere: a CALL PrintInline is followed by its text (position, attribute and size codes, then
; characters, 0), and execution goes on after the 0. PrintKeyPrompt ends in JP PrintInline, so the key name after each
; CALL PrintKeyPrompt is a string too; the checks for SYM SH / ENTER / CAPS SH / SPACE each put a RET after their name
; string (KeySpaceDone for SPACE, in the next byte). The names of SYMBOL SHIFT and ENTER are Latin letters the Russian
; font draws as ЯУМ ЯН and ЕНТЕР.
;
; Dead code kept in the image: the tape load (LoadTapePrompt, LoadGameBlocks with its checksum test turned into NOPs,
; LoadBad, LoadError), the tape save's start (SaveGame, SaveGameBlocks' key wait) and its end (SaveTapeBlocks), and
; PrintTitle (NOPs). Their texts are translated too. Nothing jumps into them.
; --------------------------------------------------------------------------------------------------------------------

; The main menu: clear the screen, the title, the options; Z = start a new
; game, NZ = a game was loaded
;
; Called by Restart ($A62A), which falls into NewGameSetup with Z when it
; returns; a loaded game never returns here (LoadReturn goes on to NewGameSetup
; with NZ). Clears the screen, draws the menu picture (MenuPicture: bank 3's
; code) and the options 0-5; the current controls (Controls, $D3E4) show in
; cyan, the others in yellow ($C336). Then MainMenuKeys. Keys 1-3 choose the
; controls and redraw the options, 4 redefines the keys and redraws the whole
; menu, 5 loads a saved game, 0 starts.
MainMenu:
  CALL ClearScreen        ; the menu starts on an empty black screen

; The main menu without the clearing: the picture, then the options
MainMenuTitle:
  CALL MenuPicture        ; the menu picture from bank 3

; The main menu's options (re-entered after keys 1-3)
;
; Used by the routine at MainMenuKeys.
MainMenuOptions:
  CALL PrintInline        ; option 0, СТАРТ ИГРЫ (start game)

; "0..СТАРТ ИГРЫ" (start game) at (10,1), double height, yellow
;
; PrintInline codes: attribute $46, setting $21 (double height), position row
; 11 column 8, the text, setting $00.
MenuStartText:
  INCBIN "res/game/text/menu-start.bin",$0000,23

; Option 1, KEYBOARD, in the colour of Controls 1
MenuKeyboardOption:
  LD C,$01                ; option 1: Controls value 1
  CALL ControlsOptionAttr ; cyan if it is the current choice, else yellow
  CALL PrintInline        ; the KEYBOARD text

; Three new lines and "1..КЛАВИШИ" (keyboard)
MenuKeyboardText:
  INCBIN "res/game/text/menu-keyboard.bin",$0000,15

; Option 2, KEMPSTON J/S, in the colour of Controls 2
MenuKempstonOption:
  LD C,$02                ; option 2: Controls value 2
  CALL ControlsOptionAttr ; cyan if chosen, else yellow
  CALL PrintInline        ; the KEMPSTON J/S text

; Two new lines and "2..КЕМПСТОН ДЖ." (Kempston joystick)
MenuKempstonText:
  INCBIN "res/game/text/menu-kempston.bin",$0000,18

; Option 3, INTERFACE 2, in the colour of Controls 3; then options 4 and 5
MenuInterface2Option:
  LD C,$03                ; option 3: Controls value 3
  CALL ControlsOptionAttr ; cyan if chosen, else yellow
  CALL PrintInline        ; INTERFACE 2, then options 4 and 5 in yellow

; "3..ИНТЕРФЕИС 2", then in yellow "4..ЗАДАТЬ КЛАВ." (define keys),
; "5..ЗАГРУЗКА" (load)
MenuMoreText:
  INCBIN "res/game/text/menu-more.bin",$0000,50

; The options' last step after their text: one frame, then MainMenuKeys
;
; PrintInline returns here past the 0 of MenuMoreText: a HALT and 6 NOPs (zero
; bytes where a longer text ended), on into MainMenuKeys.
MenuOptionsEnd:
  HALT
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP

; The main menu's keys: wait for all keys up, then a key 0-5
;
; Waits until no key is held (KEY-SCAN $028E), then reads a key every frame
; (one HALT a pass; the tune plays from MusicInterrupt meanwhile) and takes its
; character from the ROM's key table ($0205): 0 returns Z, 1-3 set Controls and
; redraw the options, 4 RedefineKeys then the whole menu, 5 LoadGame. Any other
; key is ignored. The NOPs are 4 + 3 + 3 zero bytes where calls stood: the wait
; loops have nothing else to do.
MainMenuKeys:
  NOP                     ; wait until no key is held
  NOP
  NOP
  NOP
  CALL $028E              ; ROM KEY-SCAN: E = the key value, $FF none
  LD A,E                  ; E bit 7 set: no key
  OR A                    ; sets S from bit 7
  JP P,MainMenuKeys       ; a key still held (from the last choice): wait
  NOP
  NOP
  NOP
MenuWaitKey:
  HALT                    ; one frame a pass
  NOP
  NOP
  NOP
  CALL $028E              ; ROM KEY-SCAN
  LD A,E                  ; E = $FF: no key
  OR A                    ; sets S from bit 7
  JP M,MenuWaitKey        ; none yet: wait
  LD HL,$0205             ; the key's character from the ROM's main key table
  ADD A,L                 ; $0205 + E (no carry: E is at most $27)
  LD L,A                  ; L = $05 + E
  LD A,(HL)               ; A = the key's character
  CP $35                  ; "5"?
  JR Z,LoadGame           ; 5: load a saved game from the disk
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
  JP MainMenu             ; the whole menu again (clear, picture, options,
                          ; keys)
MenuStart:
  XOR A                   ; Z: a new game
  RET                     ; Z: Restart goes on into NewGameSetup ($A62D)
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
                          ; keys

; Code nothing calls: 25 NOPs and a RET
;
; 25 zero bytes and the RET, where a title print stood; the menu's title is in
; MenuPicture's picture.
PrintTitle:
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
  RET

; Key 5: load a saved game from the disk (GameLoad)
;
; Used by the routine at MainMenuKeys.
LoadGame:
  JP GameLoad

; Code nothing reaches: the PlayTapeText prompt, then on into LoadGameBlocks
;
; Left behind the JP of LoadGame. It prints its inline text and would fall into
; the tape load LoadGameBlocks.
LoadTapePrompt:
  CALL PrintInline

; "ВКЛЮЧИТЕ МАГНИТОФОН" (start the tape) at (22,7), cyan, double height:
; LoadTapePrompt's, never printed
PlayTapeText:
  INCBIN "res/game/text/play-tape.bin",$0000,27

; Code nothing reaches: the tape load of a saved game, its checksum test gone
;
; The tape load, left in the image: red border, two headerless blocks (flag
; $00) through the ROM's LD-BYTES past its border set-up ($0562): 2 bytes to
; $5B00, then $24D1 bytes to $D92B-$FDFB; then SaveChecksum, and 10 NOPs where
; the comparison with the loaded sum stood, so the load would count as good:
; the first 45 bytes back to Shots, the next 168 to Buildings, NZ. LoadGame
; jumps to the disk load instead; nothing comes here.
LoadGameBlocks:
  LD A,$02                ; red border while it loads
  OUT ($FE),A             ; border red ($02)
  LD IX,ViewBuffer             ; 2 bytes: the checksum
  LD DE,$0002             ; DE = 2 bytes
  XOR A                   ; flag $00, carry set: load
  SCF                     ; carry set: LOAD, not VERIFY
  INC D                   ; INC D / DEC D with the flags saved between: NZ in
                          ; AF' as LD-BYTES wants
  EX AF,AF'               ; AF' = flag $00, load
  DEC D                   ; D back to 0
  DI                      ; LD-BYTES runs with interrupts off
  CALL $0562              ; ROM LD-BYTES past its border set-up and the
                          ; SA/LD-RET push
  LD IX,SaveShots             ; the game block
  LD DE,$24D1             ; DE = $24D1 bytes: $D92B-$FDFB
  XOR A
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  CALL $0562              ; ROM LD-BYTES: the robots, the map, the variables,
                          ; the staged shots and buildings
  XOR A                   ; border black again
  OUT ($FE),A
  CALL SaveChecksum       ; DE = the block's sum
  NOP                     ; 10 NOPs: no comparison, every load is good
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  LD HL,SaveShots             ; the staged tables back to their places
  LD DE,Shots             ; the 5 records of 9 bytes at Shots
  LD BC,$002D
  LDIR
  LD DE,Buildings             ; the buildings
  LD BC,$00A8
  LDIR
  EI                      ; LD-BYTES left interrupts off
  OR $01                  ; NZ: a game was loaded
  RET

; Code nothing reaches: ОШИБКА ВВОДА (load error), its text inline, then
; LoadError
;
; The tape load's error branch; the test that jumped here is gone
; (LoadGameBlocks' NOPs).
LoadBad:
  CALL PrintInline

; "ОШИБКА ВВОДА !" (load error) at (22,2), white, double size: LoadBad's, never
; printed
LoadErrorText:
  INCBIN "res/game/text/load-error.bin",$0000,22

; Code nothing reaches: after the load error, a beep, a key, then Restart
;
; Beep with A = $FA, WaitAnyKey, then JP Restart. Reached only from LoadBad.
LoadError:
  LD A,$FA                ; the error beep: half-period delay $FA
  CALL Beep
  CALL WaitAnyKey         ; a key to go on
  JP Restart              ; the whole start-up again, then the menu

; Code nothing reaches: the menu handler, the tape prompt, then SaveGameBlocks
;
; The tape save's start, left in the image: ImHandler = MusicInterrupt, the
; inline RecordText prompt at row 22, and on into SaveGameBlocks' key wait.
; PlayLoop's save key jumps past all of it to SaveGameStage.
SaveGame:
  LD HL,MusicInterrupt    ; the menu handler: the music plays, the play handler
                          ; stops
  LD (ImHandler),HL       ; ImHandler
  CALL PrintInline        ; the prompt at row 22

; "ВКЛЮЧИТЕ МАГНИТОФОН", "И НАЖМИТЕ ЛЮБУЮ КЛАВ." at (22,0), cyan: SaveGame's
; tape prompt, never printed
RecordText:
  INCBIN "res/game/text/record.bin",$0000,51

; Save the game: a key (the unused part), the staging, then GameSave on the
; disk
;
; SaveGameBlocks itself (the key wait for the tape) is reached only from
; SaveGame, which nothing runs. PlayLoop's save key enters at SaveGameStage
; ($C2CC): RadarDirty = 1 (the staging overwrites the radar picture past
; RadarEnemy), the 45 bytes of Shots to SaveShots ($D92B) and the 168 of
; Buildings to SaveBuildings ($D958), so $D92B-$FDFB holds the whole game;
; interrupts off and JP GameSave, which comes back to PlayLoop's JP EnterPlay.
SaveGameBlocks:
  CALL WaitAnyKey         ; the tape's key wait (not reached)

; SaveGameStage
;
; Used by the routine at PlayLoop.
SaveGameStage:
  LD A,$01                ; the save key in play (PlayLoop $A71A) enters here
  LD (RadarDirty),A            ; RadarDirty: the staging below overwrites the tail
                          ; of RadarEnemy
  LD HL,Shots
  LD DE,SaveShots             ; to SaveShots
  LD BC,$002D             ; 45 bytes
  LDIR                    ; Shots -> SaveShots; DE now SaveBuildings
  LD HL,Buildings
  LD BC,$00A8             ; 168 bytes
  LDIR                    ; Buildings -> SaveBuildings: $D92B-$FDFB is now the
                          ; whole game
  DI                      ; interrupts off: GameSave turns them on for its HALT
  JP GameSave             ; the disk save in bank 4

; 14 zero bytes where the start of the tape save stood
SaveSpare:
  DEFS $0E

; Code nothing reaches: the rest of the old tape save, two ROM SA-BYTES calls
;
; XOR A; SCF; CALL $04D0 (the first block, its set-up gone with the zero bytes
; before it), then $24D1 bytes from SaveShots with flag $00, border black, EI.
; Nothing jumps here.
SaveTapeBlocks:
  XOR A                   ; flag $00
  SCF
  CALL $04D0              ; ROM SA-BYTES past its pilot choice: HL = the pilot,
                          ; A = the flag
  LD HL,$0900
  LD IX,SaveShots             ; from SaveShots ...
  LD DE,$24D1             ; ... $24D1 bytes, to $FDFB
  XOR A
  SCF
  CALL $04D0              ; ROM SA-BYTES: the game block
  XOR A
  OUT ($FE),A
  EI
  RET

; DE = the 16-bit sum of the $24D1 bytes at $D92B (the saved game block)
;
; Out: DE = the plain 16-bit sum of the $24D1 (9425) bytes $D92B-$FDFB, HL =
; $FDFC, BC = 0, A = 0. Keeps IX. Called by SaveGameBlocks (the sum is saved
; first, at $5B00) and by LoadGameBlocks (compared with the loaded one).
SaveChecksum:
  LD HL,SaveShots             ; HL = the block's start
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
; Called only by dead code: SaveGameBlocks (start the tape) and LoadError.
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
; Key 4 of the main menu. Clears the screen, prints ЗАДАТЬ КЛАВ. (define keys),
; waits until no key is held, clears KeyTable and asks for each key in turn:
; PrintKeyPrompt prints "НАЖМ. КЛАВИШУ (press the key for) " and the name that
; follows the CALL, DefineKey waits for a key not yet taken and fills the
; KeyTable record whose third byte HL points at (the port's high byte, the bit
; mask, the key code) and prints the key. KeyTable's records 0-7 are PAUSE,
; ABORT, SAVE, FIRE, UP, DOWN, LEFT, RIGHT: Input bits 7 to 0. Waits for the
; last key's release and about 0.5 s, then back to the menu.
;
; PAUSE with each key's letter, and the menu came back.
RedefineKeys:
  CALL ClearScreen        ; a blank screen for the redefine screen
  CALL PrintInline        ; the heading and the first print position

; "ЗАДАИТЕ КЛАВ." (define the keys) at (2,9), white, double height, then
; position (5,3) and size 0
RedefineTitleText:
  INCBIN "res/game/text/redefine-title.bin",$0000,26

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
  CALL PrintKeyPrompt     ; "НАЖМ. КЛАВИШУ (press the key for)" and the name
                          ; below

; "ВВЕРХ" (up)
KeyNameUp:
  INCBIN "res/game/text/key-name-up.bin",$0000,6

; The key for UP (KeyTable record 4), then ask for DOWN
ReadUpKey:
  LD HL,KeyTable+$000E    ; HL = the code byte of record 4 (Input bit 3, UP)
  CALL DefineKey          ; wait for a free key, fill the record, print its
                          ; name
  CALL PrintKeyPrompt     ; the next prompt

; " ВНИЗ" (down)
KeyNameDown:
  INCBIN "res/game/text/key-name-down.bin",$0000,6

; The key for DOWN (record 5), then ask for LEFT
ReadDownKey:
  LD HL,KeyTable+$0011    ; record 5 (Input bit 2, DOWN)
  CALL DefineKey          ; wait for the DOWN key, fill record 5, print its
                          ; name
  CALL PrintKeyPrompt     ; the next prompt

; "ВЛЕВО" (left)
KeyNameLeft:
  INCBIN "res/game/text/key-name-left.bin",$0000,6

; The key for LEFT (record 6), then ask for RIGHT
ReadLeftKey:
  LD HL,KeyTable+$0014    ; record 6 (Input bit 1, LEFT)
  CALL DefineKey          ; the LEFT key into record 6
  CALL PrintKeyPrompt     ; the next prompt

; "ВПР. " (right)
KeyNameRight:
  INCBIN "res/game/text/key-name-right.bin",$0000,6

; The key for RIGHT (record 7), then ask for FIRE
ReadRightKey:
  LD HL,KeyTable+$0017    ; record 7 (Input bit 0, RIGHT)
  CALL DefineKey          ; the RIGHT key into record 7
  CALL PrintKeyPrompt     ; the next prompt

; "ОГОНЬ" (fire)
KeyNameFire:
  INCBIN "res/game/text/key-name-fire.bin",$0000,6

; The key for FIRE (record 3), a blank line, then ask for PAUSE
ReadFireKey:
  LD HL,KeyTable+$000B    ; record 3 (Input bit 4, FIRE)
  CALL DefineKey          ; the FIRE key into record 3
  CALL PrintNewline       ; a blank row between the moves and the game keys
  CALL PrintKeyPrompt     ; the next prompt

; "ПАУЗА" (pause)
KeyNamePause:
  INCBIN "res/game/text/key-name-pause.bin",$0000,6

; The key for PAUSE (record 0), then ask for ABORT
ReadPauseKey:
  LD HL,KeyTable+$0002    ; record 0 (Input bit 7, PAUSE)
  CALL DefineKey          ; the PAUSE key into record 0
  CALL PrintKeyPrompt     ; the next prompt

; "СБРОС" (abort)
KeyNameAbort:
  INCBIN "res/game/text/key-name-abort.bin",$0000,6

; The key for ABORT (record 1), then ask for SAVE
ReadAbortKey:
  LD HL,KeyTable+$0005    ; record 1 (Input bit 6, ABORT)
  CALL DefineKey          ; the ABORT key into record 1
  CALL PrintKeyPrompt     ; the last prompt

; "ВЫГР." (save)
KeyNameSave:
  INCBIN "res/game/text/key-name-save.bin",$0000,6

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

; "НАЖМ. КЛАВИШУ (press the key for) " and then the key's name that follows the
; caller's CALL
;
; Called by the redefine-keys screen ($C37F, $C38E, ... $C3EB) once for each of
; the eight keys, with the key's name (UP, DOWN, LEFT, RIGHT, FIRE, PAUSE,
; ABORT, SAVE) as an inline string after the CALL. It prints its own inline
; text (two new lines, attribute $46, "НАЖМ. КЛАВИШУ (press the key for) ",
; attribute $45), then jumps (not calls) to PrintInline at $C424: the return
; address on the stack is then the caller's, so PrintInline prints the caller's
; name string and returns past it. One prompt takes two screen rows.
PrintKeyPrompt:
  CALL PrintInline        ; our own text first

; Two new lines, attribute $46, "НАЖМ. КЛАВИШУ " (press the key for), attribute
; $45
PressKeyForText:
  INCBIN "res/game/text/press-key-for.bin",$0000,21

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
DefineKey:
  PUSH HL                 ; keep the entry's address
  CALL PrintInline        ; two spaces, then the attribute of the name

; Two spaces, attribute $46
DefineKeyBlank:
  INCBIN "res/game/text/define-key-blank.bin",$0000,5

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

; The SYMBOL SHIFT key's name: the Latin "SYM SH" left as it was, so the font
; shows "ЯУМ ЯН"
KeyNameSymShift:
  INCBIN "res/game/text/key-name-sym-shift.bin",$0000,7

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

; The ENTER key's name: the Latin "ENTER", which the font shows as "ЕНТЕР"
KeyNameEnter:
  INCBIN "res/game/text/key-name-enter.bin",$0000,6

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

; "К. ШИФТ" (caps shift)
KeyNameCapsShift:
  INCBIN "res/game/text/key-name-caps-shift.bin",$0000,8

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

; "ПРОБЕЛ" (space)
KeyNameSpace:
  INCBIN "res/game/text/key-name-space.bin",$0000,7

; The end of DefineKey's SPACE branch: RET after its name string
;
; The SPACE name is one letter longer than the room it had, so its 0 ends on
; $C4A6 and its RET is this byte.
KeySpaceDone:
  RET
