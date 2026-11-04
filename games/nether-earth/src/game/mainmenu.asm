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
  CALL ClearScreen

; The main menu without the clearing: the title, then the options
MainMenuTitle:
  CALL PrintTitle

; The main menu's options (re-entered after keys 1-3)
;
; Used by the routine at MainMenuKeys.
MainMenuOptions:
  CALL PrintInline

; "0..START GAME" at (11,8) in double height, yellow
;
; PrintInline codes: attribute $46, setting $21 (double height), position row
; 11 column 8, the text, setting $00.
MenuStartText:
  DEFM $02,"F",$04,"!",$01,$0B,$08,"0..START GAME",$04,$00,$00

; Option 1, KEYBOARD, in the colour of Controls 1
MenuKeyboardOption:
  LD C,$01
  CALL ControlsOptionAttr
  CALL PrintInline

; Two new lines and "1..KEYBOARD"
MenuKeyboardText:
  DEFM $03,$03,$03,"1..KEYBOARD",$00

; Option 2, KEMPSTON J/S, in the colour of Controls 2
MenuKempstonOption:
  LD C,$02
  CALL ControlsOptionAttr
  CALL PrintInline

; Two new lines and "2..KEMPSTON J/S"
MenuKempstonText:
  DEFM $03,$03,"2..KEMPSTON J/S",$00

; Option 3, INTERFACE 2, in the colour of Controls 3; then options 4 and 5
MenuInterface2Option:
  LD C,$03
  CALL ControlsOptionAttr
  CALL PrintInline

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
  CALL TitleColourCycle
  CALL $028E
  LD A,E
  OR A
  JP P,MainMenuKeys
  CALL MenuMusic          ; the title music, until a key
MenuWaitKey:
  HALT
  CALL TitleColourCycle
  CALL $028E
  LD A,E
  OR A
  JP M,MenuWaitKey
  LD HL,$0205             ; the key's character from the ROM's main key table
  ADD A,L
  LD L,A
  LD A,(HL)
  CP $35
  JR Z,LoadGame           ; 5: load a saved game
  CP $30
  JR Z,MenuStart          ; 0: start
  CP $31
  JR Z,MenuKeyboard
  CP $32
  JR Z,MenuKempston
  CP $33
  JR Z,MenuInterface2
  CP $34
  JR NZ,MenuWaitKey
  CALL RedefineKeys       ; 4: redefine the keys, then the whole menu again
  JP MainMenu
MenuStart:
  XOR A                   ; Z: a new game
  RET
MenuKeyboard:
  LD A,$01                ; 1: keyboard
  JR MenuSetControls
MenuKempston:
  LD A,$02                ; 2: Kempston
  JR MenuSetControls
MenuInterface2:
  LD A,$03                ; 3: Interface 2
MenuSetControls:
  LD (KeyTable+$0018),A   ; Controls, then the options again
  JP MainMenuOptions

; "NETHER" and "EARTH" in big white letters at the top
;
; Used by the routines at MainMenuTitle and PrintTitleEnd.
PrintTitle:
  CALL PrintInline

; "NETHER" at (1,10) and "EARTH" at (5,11), attribute $47, setting $32 (triple
; height, double width)
TitleText:
  DEFM $01,$01,$0A,$02,"G",$04,"2NETHER",$01,$05,$0B,"EARTH",$00

; PrintTitle's return; then the load option
PrintTitleEnd:
  RET
; This entry point is used by the routine at MainMenuKeys.
LoadGame:
  CALL PrintTitle         ; key 5: the title again, PRESS PLAY ON TAPE
  CALL PrintInline

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
  OUT ($FE),A
  LD IX,ViewBuffer        ; 2 bytes: the checksum
  LD DE,$0002
  XOR A                   ; flag $00, carry set: load
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  CALL $0562
  LD IX,SaveShots         ; the game block
  LD DE,$24D1
  XOR A
  SCF
  INC D
  EX AF,AF'
  DEC D
  DI
  CALL $0562
  XOR A
  OUT ($FE),A
  CALL SaveChecksum       ; DE = the block's sum
  LD HL,(ViewBuffer)      ; the saved sum
  AND A
  SBC HL,DE
  LD A,H
  OR L
  JR NZ,LoadBad
  LD HL,SaveShots         ; good: the staged tables back to their places
  LD DE,Shots             ; the 5 records of 9 bytes at $D7D3
  LD BC,$002D
  LDIR
  LD DE,Buildings             ; the buildings
  LD BC,$00A8
  LDIR
  EI
  OR $01                  ; NZ: a game was loaded
  RET
LoadBad:
  CALL PrintInline        ; LOADING ERROR!

; "LOADING ERROR!" at (22,2), white, double size
LoadErrorText:
  DEFM $01,$16,$02,$02,"G",$04,"\"LOADING ERROR!",$00

; After LOADING ERROR!: a beep, a key, then the start again (Start)
LoadError:
  LD A,$FA
  CALL Beep
  CALL WaitAnyKey
  JP Start

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
  LD (Handler),HL
  CALL PrintInline

; "PRESS RECORD AND PLAY ", a new line, "     THEN ANY KEY     " at (22,0),
; cyan
RecordText:
  DEFM $01,$16,$00,$02,"EPRESS RECORD AND PLAY ",$03,"     THEN ANY KEY     ",$00

; After the prompt: a key, the staging, the checksum, the two blocks
SaveGameBlocks:
  CALL WaitAnyKey
  LD A,$01                ; the radar map is rebuilt afterwards
  LD (RadarDirty),A
  LD HL,Shots             ; stage the 5 records of 9 bytes at $D7D3 ...
  LD DE,SaveShots
  LD BC,$002D
  LDIR
  LD HL,Buildings             ; ... and the buildings at $D958
  LD BC,$00A8
  LDIR
  DI
  CALL SaveChecksum       ; the checksum
  LD (ViewBuffer),DE
  LD HL,$0900             ; a short pilot
  LD IX,ViewBuffer        ; the 2 checksum bytes, flag $00
  LD DE,$0002
  XOR A
  SCF
  CALL $04D0
  LD HL,$0900             ; the game block $D92B-$FDFB
  LD IX,SaveShots
  LD DE,$24D1
  XOR A
  SCF
  CALL $04D0
  XOR A
  OUT ($FE),A
  EI
  RET

; DE = the 16-bit sum of the $24D1 bytes at $D92B (the saved game block)
;
; Used by the routines at LoadGameBlocks and SaveGameBlocks.
SaveChecksum:
  LD HL,SaveShots
  LD BC,$24D1
  LD DE,$0000
ChecksumLoop:
  LD A,(HL)
  INC HL
  ADD A,E
  LD E,A
  JR NC,ChecksumNext
  INC D
ChecksumNext:
  DEC BC                  ; carry added into D; the next byte
  LD A,B
  OR C
  JR NZ,ChecksumLoop
  RET

; Wait until no key is held, then until one is (all half rows of port $FE)
;
; Used by the routines at LoadError and SaveGameBlocks.
WaitAnyKey:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,WaitAnyKey
WaitAnyKeyDown:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR Z,WaitAnyKeyDown
  RET

; The attribute for menu option C: cyan ($45) when it is the current Controls,
; else yellow ($46)
;
; Used by the routines at MenuKeyboardOption, MenuKempstonOption and
; MenuInterface2Option.
ControlsOptionAttr:
  LD A,($D3E4)
  CP C
  JR Z,ControlsOptionMarked
  CALL PrintInline

; PrintInline: attribute $46
OptionAttrPlain:
  DEFB $02,$46,$00

; ControlsOptionAttr's return, the option not chosen
ControlsOptionPlain:
  RET
; This entry point is used by the routine at ControlsOptionAttr.
ControlsOptionMarked:
  CALL PrintInline        ; the option chosen

; PrintInline: attribute $45
OptionAttrChosen:
  DEFB $02,$45,$00

; ControlsOptionAttr's return, the option chosen
ControlsOptionChosen:
  RET

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
  CALL ClearScreen
  CALL PrintInline

; "REDEFINE KEYS" at (2,9), white, double height, then position (5,3) and
; normal size
RedefineTitleText:
  DEFM $01,$02,$09,$02,"G",$04,"!REDEFINE KEYS",$01,$05,$03,$04,$00,$00

; Wait for no key, clear KeyTable, ask for UP
RedefineKeysBody:
  CALL $028E              ; wait until no key is held
  LD A,E
  OR A
  JP P,RedefineKeysBody
  LD HL,KeyTable          ; KeyTable: 24 bytes of 0
  LD DE,KeyTable+$0001
  LD BC,$0017
  LD (HL),$00
  LDIR
  CALL PrintKeyPrompt     ; "PRESS KEY FOR" and the name below

; "   UP"
KeyNameUp:
  DEFM "   UP",$00

; The key for UP (KeyTable record 4), then ask for DOWN
ReadUpKey:
  LD HL,KeyTable+$000E
  CALL DefineKey
  CALL PrintKeyPrompt

; " DOWN"
KeyNameDown:
  DEFM " DOWN",$00

; The key for DOWN (record 5), then ask for LEFT
ReadDownKey:
  LD HL,KeyTable+$0011
  CALL DefineKey
  CALL PrintKeyPrompt

; " LEFT"
KeyNameLeft:
  DEFM " LEFT",$00

; The key for LEFT (record 6), then ask for RIGHT
ReadLeftKey:
  LD HL,KeyTable+$0014
  CALL DefineKey
  CALL PrintKeyPrompt

; "RIGHT"
KeyNameRight:
  DEFM "RIGHT",$00

; The key for RIGHT (record 7), then ask for FIRE
ReadRightKey:
  LD HL,KeyTable+$0017
  CALL DefineKey
  CALL PrintKeyPrompt

; " FIRE"
KeyNameFire:
  DEFM " FIRE",$00

; The key for FIRE (record 3), a blank line, then ask for PAUSE
ReadFireKey:
  LD HL,KeyTable+$000B
  CALL DefineKey
  CALL PrintNewline
  CALL PrintKeyPrompt

; "PAUSE"
KeyNamePause:
  DEFM "PAUSE",$00

; The key for PAUSE (record 0), then ask for ABORT
ReadPauseKey:
  LD HL,KeyTable+$0002
  CALL DefineKey
  CALL PrintKeyPrompt

; "ABORT"
KeyNameAbort:
  DEFM "ABORT",$00

; The key for ABORT (record 1), then ask for SAVE
ReadAbortKey:
  LD HL,KeyTable+$0005
  CALL DefineKey
  CALL PrintKeyPrompt

; " SAVE"
KeyNameSave:
  DEFM " SAVE",$00

; The key for SAVE (record 2), wait for its release and a pause, back to the
; menu
ReadSaveKey:
  LD HL,KeyTable+$0008
  CALL DefineKey
RedefineWaitRelease:
  CALL $028E              ; until the SAVE key is let go
  LD A,E
  OR A
  JP P,RedefineWaitRelease
  LD BC,$0000             ; all keys up: a fixed pause of 65536 turns of the
                          ; loop below (about 2 million T, 0.56 s) before the
                          ; menu
RedefineKeysPause:
  DEC BC                  ; count BC down from $0000 through all 65536 values
RedefineKeysPauseNop:
  NOP                     ; a pad (the label is a false entry of the static
                          ; walk: the string bytes before it read as JR
                          ; NZ,$C406)
  LD A,C
  OR B
  JR NZ,RedefineKeysPause
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
  LD A,E
  OR A
  JP M,DefineKeyScan      ; no key yet
  LD HL,$0205             ; the ROM's key table: E -> the key's code
  ADD A,L
  LD L,A
  LD A,(HL)
  LD D,A                  ; D = the code
  LD HL,KeyTable+$0002    ; the code bytes of the eight entries
  LD B,$08
KeyTakenLoop:
  CP (HL)                 ; a code already used is refused: wait again
  JR Z,DefineKeyScan
  INC HL
  INC HL
  INC HL
  DJNZ KeyTakenLoop
  POP HL                  ; HL = the entry's code byte
  LD (HL),A               ; store the code
  LD A,E                  ; C = the row index (0 = port $7FFE ... 7 = port
                          ; $FEFE)
  AND $07
  LD C,A
  SRL E                   ; E / 8 = the key's place in its half-row, counted
                          ; from bit 4
  SRL E
  SRL E
  LD B,E
  INC B
  LD A,$20                ; the mask: $20 rotated right E/8 + 1 times
KeyMaskShift:
  RRCA
  DJNZ KeyMaskShift
  DEC HL                  ; the entry's mask byte
  LD (HL),A
  LD B,C                  ; the port high byte: $FF shifted right row + 1 times
                          ; with 0 coming in
  INC B
  XOR A
  DEC A
KeyPortShift:
  RRA
  DJNZ KeyPortShift
  DEC HL                  ; the entry's port byte
  LD (HL),A
  LD A,D                  ; the code decides the name
  CP $0E                  ; SYMBOL SHIFT
  JR NZ,CheckEnterKey
  CALL PrintInline        ; its name, and the RET after the string

; PrintInline text: "SYM SH"
KeyNameSymShift:
  DEFM "SYM SH",$00

; a RET ($C9): PrintInline returns here and the routine ends
KeyNameSymShiftEnd:
  RET

; DefineKey: is the new key ENTER?
;
; Part of DefineKey ($C427): code $0D prints "ENTER" and returns through the
; RET placed after the string.
CheckEnterKey:
  CP $0D                  ; ENTER
  JR NZ,CheckCapsShiftKey
  CALL PrintInline        ; its name, and the RET after the string

; PrintInline text: "ENTER"
KeyNameEnter:
  DEFM "ENTER",$00

; a RET ($C9) after the string
KeyNameEnterEnd:
  RET

; DefineKey: is the new key CAPS SHIFT?
;
; Part of DefineKey ($C427): code $E3 (the byte after the ROM's key table, what
; CAPS SHIFT alone looks up) prints "CAPS SH".
CheckCapsShiftKey:
  CP $E3                  ; CAPS SHIFT
  JR NZ,CheckSpaceKey
  CALL PrintInline        ; its name, and the RET after the string

; PrintInline text: "CAPS SH"
KeyNameCapsShift:
  DEFM "CAPS SH",$00

; a RET ($C9) after the string
KeyNameCapsShiftEnd:
  RET

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
  RET
