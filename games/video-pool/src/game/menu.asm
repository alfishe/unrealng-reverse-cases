; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The main menu, the variations page, redefine keys, the settings and the menu's timeout
;
; MainMenu $B22E (called from $8037 after every restart) draws the options page (MenuTexts $B464, white on blue), the
; current variation line, the key names and a tick at the chosen players, pockets and control, then reads keys through
; the ROM (KEY-SCAN, K-TEST): 1 / 2 players, S / L pockets, K / I / J / C the control (keyboard, Interface 2,
; Kempston, cursor), B begins the game (MainMenu returns), V the variations page, E the editor ($C042), R redefine
; keys. 1500 frames without a key (MenuTimeout $B8C1, 30 s) run the attract sequence $B8C5 and then the menu again (w1
; frame 16300). Each key clicks (BEEPER, HL $03E8, DE $14).
;
; With a joystick chosen, its fire also begins the game: Kempston is polled every frame; for Interface 2 and cursor
; (whose fire is a key) $8106 is asked when a key the menu does not know is pressed. Choosing J probes the Kempston
; port: if $8106 reads anything while J is set, the old choice stays (no interface, a floating bus).
;
; A hidden toggle: WaitNoKey $B38E, run at every menu redraw and after every key, flips InfiniteLives $B8C4 when CAPS
; SHIFT, SPACE, 1 and 0 are held together (TestCheatKeys $B3B8); $9754 then skips the loss of a life. No recording
; flipped it (known only from the code; $B3A1 never ran).
;
; The text records here and everywhere the print routine $9E65 is used: row, column, attribute (bit 7 = double width:
; every character two cells), length, then the characters, no end marker. The characters are ASCII: a-z from Font
; $DEF4, 0-9 from Font+$D0, $7F the copyright sign at $9F2E, anything else (space, punctuation) from CHAR_SET $3D00
; ($9E7C).
; --------------------------------------------------------------------------------------------------------------------

; The main menu: draw the page, then take keys until B (or joystick fire)
; begins the game
;
; Clears the pixels, attributes $0F, border 1, BORDCR $08. Prints the records
; of MenuTexts $B464, the variation line (VariationStandard $B5D0 /
; Variation1Line $B5E3 / Variation2Line $B5F4 by Variation $B8C3), the key line
; (ShowKeys $B605), and XorTick $B89C at rows Players + 3, Pockets + 7 and
; Control + 10. Then MenuKeys $B293.
;
; Callers: $8037 (every restart from $8013), the ends of the timeout ($B2C3,
; $B6D4) and M on the variations page ($B6F7). Returns (to $803A, the game) on
; B, or on fire. Witness: game 2 (frames 6060, 9809), w1 2, f1 2, p2 2, v1 2,
; m1 4.
MainMenu:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  INC HL
  INC DE
  LD BC,$02FF
  LD (HL),$0F
  LDIR
  LD A,$01
  OUT ($FE),A
  LD A,$0F
  AND $38
  LD (BORDCR),A
  LD DE,MenuTexts
MenuTextLoop:
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  INC DE
  LD A,H
  OR L
  JR Z,MenuVariationLine
  PUSH DE
  CALL PrintText
  POP DE
  JR MenuTextLoop
MenuVariationLine:
  LD A,(Variation)
  LD HL,VariationStandard
  OR A
  JR Z,MenuDrawSettings
  LD HL,Variation1Line
  DEC A
  JR Z,MenuDrawSettings
  LD HL,Variation2Line
MenuDrawSettings:
  CALL PrintText
  CALL ShowKeys
  LD A,(Players)
  ADD A,$03
  CALL XorTick
  LD A,(Pockets)
  ADD A,$07
  CALL XorTick
  LD A,(Control)
  ADD A,$0A
  CALL XorTick
; This entry point is used by the routine at RedefineKeys.
MenuKeys:
  LD HL,$05DC             ; MenuTimeout = 1500 ($05DC), wait until no key, then
                          ; a key a frame
  LD (MenuTimeout),HL
  CALL WaitNoKey
MenuKeyLoop:
  HALT                    ; Kempston: $8106 every frame, fire begins
  LD A,(Control)
  CP $02
  JR NZ,MenuReadKey
  CALL ReadInput
  LD A,(InputState)
  AND $10
  RET NZ
MenuReadKey:
  CALL KEY_SCAN              ; no key: MenuTimeout - 1; at 0 the attract sequence,
                          ; then MainMenu again
  CALL K_TEST
  JR C,MenuKey
  LD HL,(MenuTimeout)
  DEC HL
  LD (MenuTimeout),HL
  LD A,H
  OR L
  JR NZ,MenuKeyLoop
  CALL PresentsPage
  JP MainMenu
MenuKey:
  PUSH AF                 ; click; "1" / "2" players
  LD HL,$03E8
  LD DE,$0014
  CALL BEEPER
  POP AF
  CP $31
  JR Z,MenuPlayers
  CP $32
  JR NZ,MenuPocketKeys
MenuPlayers:
  SUB $30                 ; XorTick off at the old row, on at the new
  LD B,A
  LD A,(Players)
  CP B
  JP Z,MenuKeys
  PUSH BC
  ADD A,$03
  CALL XorTick
  POP AF
  LD (Players),A
  ADD A,$03
  CALL XorTick
  JP MenuKeys
MenuPocketKeys:
  CP $53                  ; "S" small (0) / "L" large (1)
  JR Z,MenuPockets
  CP $4C
  JR NZ,MenuControlKeys
MenuPockets:
  SUB $53
  JR Z,MenuPocketsSet
  LD A,$01
MenuPocketsSet:
  LD B,A
  LD A,(Pockets)
  CP B
  JP Z,MenuKeys
  PUSH BC
  ADD A,$07
  CALL XorTick
  POP AF
  LD (Pockets),A
  ADD A,$07
  CALL XorTick
  JP MenuKeys
MenuControlKeys:
  LD B,$00                ; "K" 0, "I" 1, "J" 2, "C" 3
  CP $4B
  JR Z,MenuControl
  INC B
  CP $49
  JR Z,MenuControl
  INC B
  CP $4A
  JR Z,MenuControl
  INC B
  CP $43
  JR Z,MenuControl
  JR MenuOtherKeys
MenuControl:
  LD A,(Control)          ; J: Control = 2, $8106, anything read: Control back
                          ; to the old value
  LD C,A
  CP B
  JP Z,MenuKeys
  LD A,B
  CP $02
  JR NZ,MenuControlSet
  LD (Control),A
  PUSH BC
  CALL ReadInput
  LD A,(InputState)
  CP $00
  POP BC
  JR Z,MenuControlSet
  LD A,C
  LD (Control),A
  JP MenuKeys
MenuControlSet:
  PUSH BC
  LD A,C
  ADD A,$0A
  CALL XorTick
  POP AF
  LD (Control),A
  ADD A,$0A
  CALL XorTick
  JP MenuKeys
MenuOtherKeys:
  CP $42                  ; "B" begin, "V" variations, "E" the editor, "R"
                          ; redefine; another key: with a joystick, $8106 fire
                          ; begins
  RET Z
  CP $56
  JP Z,VariationsPage
  CP $45
  JP Z,EditorStart
  CP $52
  JR Z,RedefineKeys
  LD A,(Control)
  OR A
  JP Z,MenuKeys
  CALL ReadInput
  LD A,(InputState)
  AND $10
  RET NZ
  JP MenuKeys

; Wait until no key is held; flip InfiniteLives if CAPS SHIFT, SPACE, 1 and 0
; are held
;
; A frame each: KEY-SCAN, K-TEST; returns when no key. While a key is held
; TestCheatKeys $B3B8 is asked: all four held complements InfiniteLives $B8C4
; and waits for the release ($B3A8).
;
; Witness: game 73, w1 14, f1 14, p2 24, v1 36, m1 202 calls; $B3B8 asked game
; 70, m1 176 times; the flip ($B3A1) never.
WaitNoKey:
  HALT
  CALL KEY_SCAN
  JR NZ,WaitNoKeyHeld
  CALL K_TEST
  JR C,WaitNoKeyHeld
  CP $FF
  RET Z
WaitNoKeyHeld:
  CALL TestCheatKeys
  JR NZ,WaitNoKey
  LD A,(InfiniteLives)
  CPL
  LD (InfiniteLives),A
WaitNoKeyRelease:
  HALT
  CALL KEY_SCAN
  JR NZ,WaitNoKeyRelease
  CALL K_TEST
  JR C,WaitNoKeyRelease
  CP $FF
  JR NZ,WaitNoKeyRelease
  RET

; Z when CAPS SHIFT, SPACE, 1 and 0 are all held
;
; ORs bit 0 of the half-rows $FEFE (CAPS SHIFT), $7FFE (SPACE), $F7FE (1) and
; $EFFE (0) through IN A,(C): an IN from port $FE (doc 2.1 says there is none:
; wrong, see also $8216 and $822E). Witness: game 70, w1 12, f1 12, p2 21, v1
; 30, m1 176.
TestCheatKeys:
  LD BC,$FEFE
  IN A,(C)
  LD BC,$7FFE
  IN C,(C)
  OR C
  LD BC,$F7FE
  IN C,(C)
  OR C
  LD BC,$EFFE
  IN C,(C)
  OR C
  BIT 0,A
  RET

; "R": ask for the left, right and fire keys, store their K-TEST codes
;
; RedefinePrompt $B3F3 with PromptLeft $B407, PromptRight $B426, PromptFire
; $B445 into LeftKey $B8BE, RightKey $B8BF, FireKey $B8C0; ShowKeys; back to
; MenuKeys. Witness: m1 2 (frames 5462-5860, Q W P, then M, SYMBOL SHIFT, SPACE
; again; screens m1 frames 5550, 5860).
RedefineKeys:
  LD HL,PromptLeft
  CALL RedefinePrompt
  LD (LeftKey),A
  LD HL,PromptRight
  CALL RedefinePrompt
  LD (RightKey),A
  LD HL,PromptFire
  CALL RedefinePrompt
  LD (FireKey),A
  CALL ShowKeys
  JP MenuKeys

; Print the prompt at HL, wait for no key, then for a key: A = its K-TEST code
;
; Any key is taken, CAPS SHIFT alone ($27) and SYMBOL SHIFT alone ($18) too.
; Witness: m1 6, frames 5462-6090.
RedefinePrompt:
  CALL PrintText
  CALL WaitNoKey
RedefineWaitKey:
  HALT
  CALL KEY_SCAN
  JR NZ,RedefineWaitKey
  CALL K_TEST
  CP $FF
  JR Z,RedefineWaitKey
  RET

; "select key for left ?" (row 21, column 2, attribute $0F, 27 characters,
; space-padded)
;
; The three prompts, read by RedefinePrompt (m1 186 reads); each covers the key
; line at row 21.
PromptLeft:
  INCBIN "res/text/PromptLeft.bin",$0000,31
PromptRight:
  INCBIN "res/text/PromptLeft.bin",$001F,31
PromptFire:
  INCBIN "res/text/PromptLeft.bin",$003E,31

; The menu page's 15 text records, then a zero word
;
; Read by MainMenu (every recording, m1 128 reads).
MenuTexts:
  DEFW MenuTitle,MenuSelect
  DEFW MenuOnePlayer,MenuTwoPlayers
  DEFW MenuSmallPockets,MenuLargePockets
  DEFW MenuKeyboard,MenuInterface2
  DEFW MenuKempston,MenuCursor
  DEFW MenuBegin,MenuVariations
  DEFW MenuEdit,MenuRedefine
  DEFW MenuCopyright,$0000

; row 0 column 9, 14: "- video pool -"
;
; The records of MenuTexts, all attribute $0F (screen m1 frame 4620); read by
; MainMenu in every recording.
MenuTitle:
  INCBIN "res/text/MenuTitle.bin",$0000,18
MenuSelect:
  INCBIN "res/text/MenuTitle.bin",$0012,20
MenuOnePlayer:
  INCBIN "res/text/MenuTitle.bin",$0026,22
MenuTwoPlayers:
  INCBIN "res/text/MenuTitle.bin",$003C,22
MenuSmallPockets:
  INCBIN "res/text/MenuTitle.bin",$0052,20
MenuLargePockets:
  INCBIN "res/text/MenuTitle.bin",$0066,20
MenuKeyboard:
  INCBIN "res/text/MenuTitle.bin",$007A,15
MenuInterface2:
  INCBIN "res/text/MenuTitle.bin",$0089,29
MenuKempston:
  INCBIN "res/text/MenuTitle.bin",$00A6,24
MenuCursor:
  INCBIN "res/text/MenuTitle.bin",$00BE,22
MenuBegin:
  INCBIN "res/text/MenuTitle.bin",$00D4,17
MenuVariations:
  INCBIN "res/text/MenuTitle.bin",$00E5,22
MenuEdit:
  INCBIN "res/text/MenuTitle.bin",$00FB,17
MenuRedefine:
  INCBIN "res/text/MenuTitle.bin",$010C,28
MenuCopyright:
  INCBIN "res/text/MenuTitle.bin",$0128,36
VariationStandard:
  INCBIN "res/text/MenuTitle.bin",$014C,19
Variation1Line:
  INCBIN "res/text/MenuTitle.bin",$015F,17
Variation2Line:
  INCBIN "res/text/MenuTitle.bin",$0170,17

; Fill the key names into KeysLine and print it
;
; KeyName $B626 for LeftKey to $B668, RightKey to $B672, FireKey to $B67B, then
; KeysLine $B65F through $9E65 (a jump). The default line: "left='m' right=s/s
; fire=' '". Witness: game 2, w1 2, f1 2, p2 2, v1 2, m1 6 (frames 4506-8004).
ShowKeys:
  LD A,(LeftKey)
  LD HL,KeysLineLeft
  CALL KeyName
  LD A,(RightKey)
  LD HL,KeysLineRight
  CALL KeyName
  LD A,(FireKey)
  LD HL,KeysLineFire
  CALL KeyName
  LD HL,KeysLine
  JP PrintText

; Three characters at HL naming the K-TEST code A
;
; $0D "ent", $18 "s/s" (SYMBOL SHIFT), $27 "c/s" (CAPS SHIFT), else the
; character in quotes, letters lower-cased (+$20). Witness: game 6 ($B63C 4
; quoted, $B64D 2 s/s); m1 18; "ent" and "c/s" by no recording.
KeyName:
  CP $0D
  JR Z,KeyNameEnter
  CP $18
  JR Z,KeyNameSymbol
  CP $27
  JR Z,KeyNameCaps
  CP $41
  JR C,KeyNameQuoted
  CP $5B
  JR NC,KeyNameQuoted
  SUB $E0
KeyNameQuoted:
  LD (HL),$27
  INC HL
  LD (HL),A
  INC HL
  LD (HL),$27
  RET
KeyNameEnter:
  LD (HL),$65
  INC HL
  LD (HL),$6E
  INC HL
  LD (HL),$74
  RET
KeyNameSymbol:
  LD (HL),$73
  INC HL
  LD (HL),$2F
  INC HL
  LD (HL),$73
  RET
KeyNameCaps:
  LD (HL),$63
  INC HL
  LD (HL),$2F
  INC HL
  LD (HL),$73
  RET

; "left=    right=    fire=   " (row 21, column 2, attribute $0F, 27
; characters); the names filled in
;
; Written by ShowKeys, read by $9E65 (every recording).
KeysLine:
  INCBIN "res/text/KeysLine.bin",$0000,9
KeysLineLeft:
  INCBIN "res/text/KeysLine.bin",$0009,10
KeysLineRight:
  INCBIN "res/text/KeysLine.bin",$0013,9
KeysLineFire:
  INCBIN "res/text/KeysLine.bin",$001C,3

; "V": the variations page; S / 1 / 2 choose, B begins, M back to the menu
;
; Clears the pixels (the attributes stay), prints VariationTexts $B731, ticks
; the variation (TickVariation $B71E), then like MenuKeys: MenuTimeout 1500,
; Kempston fire polled, a key a frame: S Variation 0, 1 variation 1, 2
; variation 2 (ticks moved), B returns (the game begins), M MainMenu; another
; key with a joystick asks $8106 for fire. Note $B6BC loops while KEY-SCAN
; reports more than two keys.
;
; Witness: v1 2 (frames 622-2595), m1 1 (5102-5372); screens m1 frame 5190, v1
; frame 700.
VariationsPage:
  LD HL,Screen
  LD DE,Screen+1
  LD BC,$17FF
  LD (HL),$00
  LDIR
  LD DE,VariationTexts
VariationsTextLoop:
  LD A,(DE)
  LD L,A
  INC DE
  LD A,(DE)
  LD H,A
  INC DE
  LD A,H
  OR L
  JR Z,VariationsTick
  PUSH DE
  CALL PrintText
  POP DE
  JR VariationsTextLoop
VariationsTick:
  CALL TickVariation
VariationsKeys:
  LD HL,$05DC
  LD (MenuTimeout),HL
  CALL WaitNoKey
VariationsKeyLoop:
  HALT
  LD A,(Control)
  CP $02
  JR NZ,VariationsReadKey
  CALL ReadInput
  LD A,(InputState)
  AND $10
  RET NZ
VariationsReadKey:
  CALL KEY_SCAN
  JR NZ,VariationsReadKey
  CALL K_TEST
  JR C,VariationsKey
  LD HL,(MenuTimeout)
  DEC HL
  LD (MenuTimeout),HL
  LD A,H
  OR L
  JR NZ,VariationsKeyLoop
  CALL PresentsPage
  JP MainMenu
VariationsKey:
  PUSH AF
  LD HL,$03E8
  LD DE,$0014
  CALL BEEPER
  POP AF
  LD B,$00
  CP $53
  JR Z,VariationsSet
  INC B
  CP $31
  JR Z,VariationsSet
  INC B
  CP $32
  JR Z,VariationsSet
  CP $42
  RET Z
  CP $4D
  JP Z,MainMenu
  LD A,(Control)
  OR A
  JR Z,VariationsKeys
  CALL ReadInput
  LD A,(InputState)
  AND $10
  RET NZ
  JR VariationsKeys
VariationsSet:
  LD A,(Variation)
  CP B
  JR Z,VariationsKeys
  PUSH BC
  CALL TickVariation
  POP AF
  LD (Variation),A
  CALL TickVariation
  JR VariationsKeys

; XorTick at the row of Variation: 4 (standard), 7 (1), 11 (2)
;
; Witness: v1 6, m1 7.
TickVariation:
  LD A,(Variation)
  LD B,$04
  OR A
  JR Z,TickVariationRow
  LD B,$07
  DEC A
  JR Z,TickVariationRow
  LD B,$0B
TickVariationRow:
  LD A,B
  JP XorTick

; The variations page's 13 text records, then a zero word
;
; Read by VariationsPage (v1 56, m1 28 reads).
VariationTexts:
  DEFW VariationsTitle,VariationsSelect
  DEFW VariationsS1,VariationsS2
  DEFW Variations11,Variations12
  DEFW Variations13,Variations21
  DEFW Variations22,Variations23
  DEFW Variations24,VariationsBegin
  DEFW VariationsMenu,$0000

; row 0 column 6, 19: "- game variations -"
;
; The records of VariationTexts, attribute $0F, read by VariationsPage in v1
; and m1.
VariationsTitle:
  INCBIN "res/text/VariationsTitle.bin",$0000,23
VariationsSelect:
  INCBIN "res/text/VariationsTitle.bin",$0017,20
VariationsS1:
  INCBIN "res/text/VariationsTitle.bin",$002B,33
VariationsS2:
  INCBIN "res/text/VariationsTitle.bin",$004C,26
Variations11:
  INCBIN "res/text/VariationsTitle.bin",$0066,31
Variations12:
  INCBIN "res/text/VariationsTitle.bin",$0085,30
Variations13:
  INCBIN "res/text/VariationsTitle.bin",$00A3,26
Variations21:
  INCBIN "res/text/VariationsTitle.bin",$00BD,29
Variations22:
  INCBIN "res/text/VariationsTitle.bin",$00DA,29
Variations23:
  INCBIN "res/text/VariationsTitle.bin",$00F7,28
Variations24:
  INCBIN "res/text/VariationsTitle.bin",$0113,27
VariationsBegin:
  INCBIN "res/text/VariationsTitle.bin",$012E,17
VariationsMenu:
  INCBIN "res/text/VariationsTitle.bin",$013F,16

; XOR a tick at the left of text row A (x 5, y 8 A + 4)
;
; Two one-pixel steps down-right, then seven up-right (XorLine $93B3, length
; 1). Drawing twice erases: the menus move a tick by drawing it at the old row
; and the new. Witness: game 6, w1 6, f1 6, p2 8, v1 12, m1 39.
XorTick:
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$04
  LD D,A
  LD E,$05
  LD B,$01
  LD C,$02
TickDown:
  CALL XorLine
  INC E
  INC D
  DEC C
  JR NZ,TickDown
  LD C,$07
TickUp:
  CALL XorLine
  INC E
  DEC D
  DEC C
  JR NZ,TickUp
  RET

; The menu's settings: first the players, 1 or 2 (keys 1 / 2), then pockets,
; control, the three keys, the timeout, the variation, the cheat
;
; One byte each (MenuTimeout a word). Readers and writers in the comments. The
; defaults in the image: one player, large pockets, keyboard, keys M / SYMBOL
; SHIFT / SPACE, standard game.
;
; Players is read by GameOverHallOfFame, NameEntryPage and the play code
; ($97AB, $97D0, $98D5, $9B36, $9C15, $9C7B)
Players:
  DEFB $01
Pockets:
  DEFB $01                ; 0 small, 1 large (keys S / L); read by the table
                          ; drawing and the pocket tests ($8B71, $8C74,
                          ; $9256-$9330)
Control:
  DEFB $00                ; 0 keyboard, 1 Interface 2, 2 Kempston, 3 cursor
                          ; (keys K / I / J / C); the handler index of $8106;
                          ; the editor sets 3 while it runs if it is 0 ($C042,
                          ; $C417, $C44E)
LeftKey:
  DEFB $4D                ; K-TEST codes of the keyboard control's keys, read
                          ; by $8123; set by RedefineKeys
RightKey:
  DEFB $18
FireKey:
  DEFB $20
MenuTimeout:
  DEFB $00,$00            ; frames left before the attract sequence (1500 at
                          ; each key)
Variation:
  DEFB $00                ; 0 standard, 1 numeric order, 2 own pockets; read by
                          ; $8C2F, $9BFA, $9C00
InfiniteLives:
  DEFB $00                ; non-zero: no life is lost ($9754); flipped by
                          ; WaitNoKey
