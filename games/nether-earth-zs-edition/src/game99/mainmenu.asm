; --------------------------------------------------------------------------------------------------------------------
; mainmenu.asm: The room of the main menu and LOAD MAP, the redefine-keys screen
;
; NE's main menu, its tape save and load of a game, are gone: $C100-$C334 is zero in the block. Stage 3 fills two
; parts of it with pieces of the patches block (src/patches99): $C100-$C17E with the menu piece (menu128 or menu48:
; jumps for the start-up menu, which itself runs at $D800 on 128 K, copied from page 1) and $C1FD-$C332 with LOAD MAP
; (diskmap or tapemap). Start ($A600) calls $C100; the start-up menu's LOAD MAP item jumps to $C1FD. $C17F-$C1FC and
; $C333-$C334 stay zero; the byte $C335 is the last of NE's WaitAnyKey (RET).
;
; What is left of NE's code here is the redefine-keys screen, called by the start-up menu (the item under the three
; control options, CALL $C34A at `$DA77`), which also sets Controls ($D3E4) for KEYBOARD, KEMPSTON J/S and INTERFACE 2
; ($DA71) and colours them through ControlsOptionAttr. The screen now asks seven keys: after ABORT, ReadAbortKey
; writes a fixed record for the SAVE key (ENTER) and returns, with no wait for the key's release.
;
; The redefine screen does not use KeyTable to read: DefineKey reads the keyboard with the ROM's KEY-SCAN ($028E) and
; the ROM's key table ($0205). RedefineKeys clears and refills KeyTable (module controls) through DefineKey: a key
; value E becomes the 3-byte record (port high byte, bit mask, code) ReadControls reads.
;
; Inline strings everywhere: a CALL PrintInline is followed by its text (position, attribute and size codes, then
; characters, 0), and execution goes on after the 0. PrintKeyPrompt ends in JP PrintInline, so the key name after each
; CALL PrintKeyPrompt is a string too; the checks for SYM SH / ENTER / CAPS SH / SPACE each put a RET after their name
; string. DefineKeyDone ($C4A6) is also command 0 of the music tables.
; --------------------------------------------------------------------------------------------------------------------

; Zero: stage 3 copies the start-up menu's piece here (menu128 or menu48)
;
; The 127 bytes $C100-$C17E. On 128 K stage 3 copies the patches block's
; menu128 piece here ($6340), on one page or the tape path menu48 ($6329): a
; table of jumps whose first, `JP $C112` / the 48 K one, is the start-up menu
; Start calls. The block's zeros never run.
MenuPieceRoom:
  DEFS $7F

; Zero, never written: NE's main menu keys, title and load code were here
;
; $C17F-$C1FC: nothing writes or reads these bytes in the '99 program.
MainMenuSpare:
  DEFS $7E

; Zero: stage 3 copies LOAD MAP here (diskmap from disk, tapemap on the tape
; path)
;
; The 310 bytes $C1FD-$C332, the size of the disk piece; the tape piece takes
; 147. The start-up menu's LOAD MAP item jumps to $C1FD; the piece reads a
; NELEV file, copies its lists over $BDA9-$BF9B and its tail into the game's
; operands (src/res/maps/README.md), then jumps to Start.
LoadMapRoom:
  DEFS $0136

; Two zeros and $C9, the RET that ended NE's WaitAnyKey
;
; Never run: nothing calls $C325 any more.
WaitAnyKeyEnd:
  DEFB $00,$00,$C9

; The attribute for menu option C: cyan ($45) when it is the current Controls,
; else yellow ($46)
;
; C = the option's Controls value (1-3). Prints an inline attribute code: $45
; (cyan, bright) when Controls ($D3E4) is C, else $46 (yellow, bright; the
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
; . PAUSE with each key's letter, and the menu came back.
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

; The key for ABORT (record 1), then the fixed SAVE record, back to the caller
; of RedefineKeys
;
; The last key the screen asks. Then KeyTable record 2 (Input bit 5, NE's SAVE)
; is written as $BF, $01, $0D: half row $BFFE, bit 0, ENTER; nothing reads
; Input bit 5 in play any more (PlayLoop $A715). Returns to the start-up menu
; (`$DA7A`) at once: no wait for the key's release, no pause.
ReadAbortKey:
  LD HL,KeyTable+$0005    ; record 1 (Input bit 6, ABORT)
  CALL DefineKey          ; the ABORT key into record 1
  LD HL,KeyTable+$0006    ; record 2 (Input bit 5)
  LD A,$BF                ; the port's high byte $BF: the half row H-ENTER
  LD (HL),A               ; +0
  INC HL
  LD A,$01                ; bit 0 of the half row: ENTER
  LD (HL),A               ; +1
  INC HL
  LD A,$0D                ; the key code $0D, ENTER
  LD (HL),A               ; +2
  RET                     ; back to the start-up menu

; Zero: 18 bytes up to PrintKeyPrompt
;
; Nothing reads or runs them.
RedefineKeysSpare:
  DEFS $12

; "PRESS KEY FOR " and then the key's name that follows the caller's CALL
;
; Called by the redefine-keys screen ($C37F, $C38E,... $C3EB) once for each of
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
  INC HL                  ; HL + 3...
  INC HL                  ; (3 bytes a record)
  INC HL                  ; ... the next record's code byte
  DJNZ KeyTakenLoop       ; eight codes compared
  POP HL                  ; HL = the entry's code byte
  LD (HL),A               ; store the code
  LD A,E                  ; C = the row index (0 = port $7FFE... 7 = port
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
  DJNZ KeyMaskShift       ; B rotations: $10 for E/8 = 0... $01 for E/8 = 4
  DEC HL                  ; the entry's mask byte
  LD (HL),A               ; store the mask
  LD B,C                  ; the port high byte: row + 1 RRAs of $FF with the
                          ; carry clear, the 0 walking right ($7F row 0... $FE
                          ; row 7)
  INC B                   ; B = row + 1 rotations
  XOR A                   ; A = 0, carry clear
  DEC A                   ; A = $FF; DEC leaves the carry clear
KeyPortShift:
  RRA                     ; the one 0 bit walks right ($7F, $BF... $FE), ones
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
