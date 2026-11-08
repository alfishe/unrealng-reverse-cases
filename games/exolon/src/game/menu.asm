; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The entry, the machine test, the menu with its stars, the define keys and the ZORBA cheat
; --------------------------------------------------------------------------------------------------------------------

; The entry: the machine test, the new-game reset, then the menu (or the Hall
; of Fame after a name entry)
;
; Entered at load with DI (SP $6D5E from the loader), and again by GAME OVER
; and the name entry ($A02A, $A13A jump here). Sets SP to $0000 (the stack
; grows down from $FFFF).
;
; The machine test: A = ($386E) - $FF. The byte is $FF in the 48K ROM and $DD
; in the 128K's 48 BASIC ROM, so SoundIsAy $6E16 = 0 on a 48K (the beeper) and
; non-zero on a 128K (the AY). c1 / c128: one image, the two paths.
;
; The reset: border black and speaker off, $9CE2, $9ED8, the screen number
; $8523 and the word $9ED6 zeroed; TitleTunePending $7D67 = 1; the screen line
; tables (BuildLineTables $7BEF) and the bit-reverse table (BuildReverseTable
; $7B99) built; the score $AD8A = "000000"; the lives $8E7A = 9.
;
; Then ShowHallOfFame $71F0: non-zero after a name entry (h1: set by $A13A)
; goes to ShowHallOfFameFirst $7145, else falls into MainMenu. c1: 4 runs,
; c128: 2, every warp run 1.
Start:
  DI
  LD SP,$0000
  LD A,($386E)            ; the machine test: $386E is $FF on a 48K ROM, $DD on
                          ; the 128K's 48 BASIC ROM
  SUB $FF
  LD (SoundIsAy),A        ; SoundIsAy: 0 = beeper (48K), $DE = AY (128K)
  XOR A                   ; border 0, speaker and MIC off
  OUT ($FE),A
  LD (DeathTimer),A
  LD (ExoSuit),A
  LD (ScreenNumber),A     ; the screen number back to 0 (the warp clones NOP
                          ; this store)
  LD HL,$0000
  LD (BonusTicks),HL
  INC A                   ; A = 1: the title tune is still to play
  LD (TitleTunePending),A
  CALL BuildLineTables    ; the screen line address tables $6500 / $6600 /
                          ; $6700
  CALL BuildReverseTable  ; the bit-reverse table $6400 for the mirrored player
                          ; frames
  LD HL,Score             ; the score's six ASCII digits at $AD8A = "000000"
  LD DE,Score+$0001
  LD (HL),$30
  LD BC,$0005
  LDIR
  LD A,$09                ; nine lives
  LD (Lives),A
  LD A,(ShowHallOfFame)   ; set by the name entry: show the Hall of Fame before
                          ; the menu
  OR A
  JP NZ,ShowHallOfFameFirst

; The main menu: draws it, plays the title tune once on a 48K, then waits for
; 1-5 while the stars twinkle
;
; Clears the screen ($B04B), the occupancy map $6100 ($8DF5) and the foreground
; map $5B00 ($8E03, filled with $FF; the LDIR here carries the fill 31 bytes
; further, over row 22 of the map). Prints MenuText $6E17 (the logo, BY
; RAFFAELE CECCO, the five options, the copyright) and HighlightControl $6F90
; marks the current control type in bright white. $B6EC sets up the AY title
; music.
;
; TitleTunePending $7D67 (set by Start) is cleared on the first pass: on a 48K
; (SoundIsAy 0) PlayTune $7D17 plays TitleTune $7DA3 once on the beeper, any
; key stops it. A 128K skips it (c128: $6DCB never ran); its title music is the
; AY tune ticked by DrawSparkle.
;
; Then the attribute copy $5E00 ($8E11: ColourCells writes a sprite colour only
; where it holds 0), the sprite save buffers cleared ($B0F3) and the sparkle
; slots cleared (ClearMenuStars $6F83).
;
; MenuLoop runs $09C4 = 2500 passes: one MenuSparkles step, one key read
; ($ACD1, ASCII, 0 = none). 1 starts the game (StartGame $758A), 2 defines the
; keys (DefineKeys $6FAB), 3 / 4 / 5 set ControlType $7B97 to 0 keyboard, 1
; Interface 2, 2 Kempston and print the menu again with the new highlight. When
; the count runs out the Hall of Fame rolls (HallOfFameRoll $7149). c1: 3978
; passes, x1 / m1: the options 2-5 and 1 taken.
MainMenu:
  CALL ClearScreen
  CALL ClearBlockMap
  CALL FillOpenMap
  LD BC,$001F
  LDIR
  LD HL,MenuText
  CALL PrintString
  CALL HighlightControl   ; the current control type in bright white
  CALL TuneStart          ; the AY title music's start ($B6EC)
  LD A,(TitleTunePending)
  OR A
  JR Z,MenuReady
  XOR A
  LD (TitleTunePending),A
  LD A,(SoundIsAy)        ; a 128K has its AY music: no beeper tune
  OR A
  JR NZ,MenuReady
  LD HL,TitleTune         ; the title tune on the beeper (c1: 4 times, once
                          ; after each entry to Start)
  CALL PlayTune
MenuReady:
  CALL SaveAttributes     ; the attribute copy $5E00, the save buffers and the
                          ; sparkle slots cleared
  CALL ClearWorkArea
  CALL ClearMenuStars
  LD BC,$09C4             ; the menu's timeout: 2500 passes
MenuLoop:
  CALL MenuSparkles       ; one sparkle step, one key read
  CALL ReadKey
  CP $31                  ; only '1'-'5' count
  JR C,MenuCountdown
  CP $36
  JR NC,MenuCountdown
  CP $31
  JP Z,StartGame
  CP $32
  JP Z,DefineKeys
  SUB $33                 ; '3'-'5': the control type 0-2
  LD E,A
  LD A,(ControlType)
  CP E
  JR Z,MenuCountdown      ; the same type again: nothing to do
  LD A,E
  LD (ControlType),A
  LD HL,MenuText          ; the menu printed again (resets every option's
                          ; colour), then the new highlight
  PUSH BC
  CALL PrintString
  CALL HighlightControl
  POP BC
MenuCountdown:
  DEC BC                  ; the timeout: the Hall of Fame roll
  LD A,B
  OR C
  JP Z,HallOfFameRoll
  JP MenuLoop

; The sound flag: 0 on a 48K (the beeper), non-zero on a 128K (the AY), set by
; the machine test of Start
;
; Written once by Start ($6D69). Read by BeeperNoise $7C26 and BeeperSweep
; $7C3C (return at once when set), MainMenu $6DC5 (no beeper title tune),
; DrawSparkle $6F23 (the AY music tick) and $9597.
SoundIsAy:
  DEFB $00

; The main menu text (a print string of $AF2B: control codes inside, $FF ends)
;
; Printed by MainMenu at $6DB2 and again at $6E06 after a control change. $E8
; 01 first: every printed cell is marked 1 in the occupancy map $6100, so
; MenuSparkles keeps the stars off the text. Then the logo (LogoText $70FF at
; row 0 column 8), the font $D7E0, BY  RAFFAELE CECCO in attribute $44 at row
; 7, the options from row 11 column 9 two rows apart (the digit in bright
; magenta, the text in bright cyan), the copyright in bright red at row 23
; column 2.
;
; The print codes ($AF2B): below $61 a character; $61-$8F a move (rows + code -
; $78, columns + the next byte); $90-$CE the next row, columns + code - $AF;
; $CF-$DE the ink (code - $CF, 8 and up bright); $DF row column; $E0 the
; attribute; $E1 n ... $E2 a repeat; $E3 a sub-string at the word; $E4 / $E5 n
; char repeated across / down; $E6 the font address; $E7 a space; $E8 n the
; occupancy value; $E9 / $EA the foreground value 0 / $FF; $EB; anything else
; ends.
MenuText:
  DEFB $E8,$01
  DEFB $DF,$00,$08,$E3,$FF,$70 ; AT 0,8, then the logo sub-string LogoText
  DEFB $E6,$E0,$D7        ; the font at $D7E0
  DEFB $DF,$07,$07,$E0,$44,$42,$59,$20,$20,$52,$41,$46,$46,$41,$45,$4C ; AT 7,7,
  DEFB $45,$20,$43,$45,$43,$43,$4F                                     ; attribute
                                                                       ; $44: BY
                                                                       ; RAFFAELE
                                                                       ; CECCO
  DEFB $DF,$0B,$09,$DA,$31,$DC,$20,$53,$54,$41,$52,$54,$20,$47,$41,$4D ; AT 11,9: 1
  DEFB $45                                                             ; START GAME
  DEFB $7A,$F4,$DA,$32,$DC,$20,$44,$45,$46,$49,$4E,$45,$20,$4B,$45,$59 ; two rows
  DEFB $53                                                             ; down: 2
                                                                       ; DEFINE
                                                                       ; KEYS
  DEFB $7A,$F3,$DA,$33,$DC,$20,$4B,$45,$59,$42,$4F,$41,$52,$44 ; 3 KEYBOARD
  DEFB $7A,$F6,$DA,$34,$DC,$20,$49,$4E,$54,$45,$52,$46,$41,$43,$45,$20 ; 4
  DEFB $32                                                             ; INTERFACE
                                                                       ; 2
  DEFB $7A,$F3,$DA,$35,$DC,$20,$4B,$45,$4D,$50,$53,$54,$4F,$4E ; 5 KEMPSTON
  DEFB $DF,$17,$02,$D9,$45,$58,$4F,$4C,$4F,$4E,$20,$43,$4F,$50,$59,$52 ; AT 23,2,
  DEFB $49,$47,$48,$54,$20,$31,$39,$38,$37,$20,$48,$45,$57,$53,$4F,$4E ; bright
                                                                       ; red:
                                                                       ; EXOLON
                                                                       ; COPYRIGHT
                                                                       ; 1987
                                                                       ; HEWSON
  DEFB $FF                ; the end

; One step of the menu's twinkling stars: twelve slots, each a 16-frame twinkle
; at a free place
;
; Walks SparkleSlots $6F5E (3 bytes a slot: x, y, frames left; $FF ends), IY
; the slot's 48-byte save buffer at $B181 + 48 n. A slot with frames left draws
; its next frame (DrawSparkle $6F1F, sprite SparkleFrames[frames left] at x, y,
; erasing the previous one in place) and colours its 2x2 cells $47
; (ColourSprite $7C8F, only over attribute-0 cells). A free slot picks a random
; cell ($AD36): column (rnd AND $1E), row (rnd AND $1F) below 22; when the 2x2
; cells there are all 0 in the occupancy map $6100 (nothing printed: MenuText
; marks its cells 1) it takes x = 4 column (x counts 2-pixel steps), y = 8 row,
; 16 frames; else it waits for the next pass.
;
; Called once a MainMenu pass (c1: 3978 runs, 47 736 slot visits). Keeps every
; register.
MenuSparkles:
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IY
  LD IY,WorkArea          ; the slots' save buffers, 48 bytes each from $B181
  LD HL,SparkleSlots
SparkleNext:
  LD E,(HL)               ; the next slot: $FF ends
  BIT 7,E
  JR Z,SparkleSlot
  POP IY
  POP HL
  POP DE
  POP BC
  POP AF
  RET
SparkleSlot:
  PUSH HL                 ; D = y, A = frames left
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  OR A
  JR NZ,SparkleDraw
  CALL Random             ; a free slot: a random column (even, 0-30)
  AND $1E
  LD E,A
  CALL Random             ; a random row: 22 and over tries again next pass
  AND $1F
  CP $16
  JR NC,SparkleSkip
  LD D,A
  CALL CellOffset         ; HL = 32 row + column in the occupancy map $6100
  LD BC,CellTypes
  ADD HL,BC
  LD A,(HL)
  INC HL
  OR (HL)
  LD BC,$0020
  ADD HL,BC
  OR (HL)
  DEC HL
  OR (HL)
  JR NZ,SparkleSkip
  POP HL                  ; free: x = 4 column, y = 8 row, 16 frames
  PUSH HL
  LD A,E
  ADD A,A
  ADD A,A
  LD (HL),A
  INC HL
  LD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  LD (HL),A
  INC HL
  LD (HL),$10
  JR SparkleSkip
SparkleDraw:
  DEC (HL)                ; A = the frames left before this one: the frame from
                          ; SparkleFrames
  LD L,A
  LD H,$00
  LD BC,AyTickCount
  ADD HL,BC
  LD A,(HL)
  LD B,D                  ; BC = DE: the star stays in place, the previous
                          ; frame erased where it was drawn
  LD C,E
  PUSH IY
  POP HL
  CALL DrawSparkle
  LD C,$47                ; bright white over the black cells
  CALL ColourSprite
SparkleSkip:
  POP HL                  ; the next slot and its buffer
  INC HL
  INC HL
  INC HL
  LD DE,$0030
  ADD IY,DE
  JR SparkleNext

; Draws one star frame (DrawSprite), and on a 128K ticks the AY title music
; every fourth draw
;
; A = the frame, DE = x, y, BC = the old x, y, HL = the save buffer: DrawSprite
; $795C. On a 128K (SoundIsAy set) AyTickCount $6F4D counts the draws and every
; fourth calls the AY music step $B767 with every register saved: the 128K's
; title music runs at the pace of the menu's star draws (c128: 42 219 draws, 10
; 554 ticks; c1: none).
DrawSparkle:
  CALL DrawSprite
  PUSH AF
  LD A,(SoundIsAy)        ; a 48K: no AY music
  OR A
  JR Z,DrawSparkleDone
  LD A,(AyTickCount)
  INC A
  LD (AyTickCount),A
  CP $04
  JR NZ,DrawSparkleDone
  XOR A                   ; every fourth draw: one step of the AY title music
  LD (AyTickCount),A
  PUSH AF
  PUSH BC
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  CALL TuneTick
  POP IY
  POP IX
  POP HL
  POP DE
  POP BC
  POP AF
DrawSparkleDone:
  POP AF                  ; F as DrawSprite left it
  RET

; Counts the star draws 0-3 on a 128K: the AY title music steps when it wraps
; (DrawSparkle)
AyTickCount:
  DEFB $00

; The star's 16 frames, indexed by the frames left (16 first, 1 last): 16x16
; sprites $0C-$0F, then 0
;
; MenuSparkles reads SparkleFrames[n] for n = 16 down to 1 ($6F4D + n): $0C $0C
; $0E $0D $0E $0E $0F $0F $0F $0E $0E $0D $0D $0C $0C, then sprite 0, which is
; blank ($F8E0: 32 zero bytes). The blank last frame matters: the next place's
; first draw erases the buffer's image at its own position, so the buffer must
; hold nothing.
SparkleFrames:
  DEFB $00,$0C,$0C,$0D,$0D,$0E,$0E,$0F,$0F,$0F,$0E,$0E,$0D,$0E,$0C,$0C

; The 12 star slots: x (2-pixel steps), y (pixels), frames left (0 = free); $FF
; ends
;
; Cleared by ClearMenuStars $6F83 (36 bytes), walked by MenuSparkles. The end
; mark at $6F82.
SparkleSlots:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $FF                ; the end mark

; Frees the 12 star slots (36 zero bytes from SparkleSlots)
;
; Called by MainMenu and DefineKeys. B is 0 after LD BC,$0023 (B = 0): the
; first byte is written 0, the LDIR copies it on.
ClearMenuStars:
  LD HL,SparkleSlots
  LD DE,SparkleSlots+$0001
  LD BC,$0023
  LD (HL),B
  LDIR
  RET

; Paints the current control option of the menu bright white (14 cells from
; column 11)
;
; Row 15 + 2 ControlType $7B97 (KEYBOARD, INTERFACE 2 or KEMPSTON), columns
; 11-24 set to attribute $47. Called by MainMenu after each print of MenuText.
; c1 / x1 / m1 screens: the chosen option white, the others cyan.
HighlightControl:
  LD A,(ControlType)
  ADD A,A
  ADD A,$0F
  LD D,A
  LD E,$0B
  CALL CellOffset
  LD DE,$5800
  ADD HL,DE
  LD (HL),$47
  LD E,L
  LD D,H
  INC E
  LD BC,$000D
  LDIR
  RET

; Define keys: five prompts LEFT RIGHT JUMP DUCK FIRE, each key patched into
; ReadKeyboard; ZORBA toggles the infinite lives
;
; Silences the AY ($B753), clears the screen and the maps as MainMenu does,
; sets ControlType $7B97 = 0 (the keyboard) and prints DefineKeysText $7095.
; For each of the five prompts (from row 9 column 15, two rows apart): a ? in
; attribute $44, wait for no key ($AD18), wait for a key ($ACD1: A = its ASCII,
; D = the half-row's port high byte, E = its bit mask), then D and E go into
; the key test of ReadKeyboard (IX = $7AF0 + 10 n: LD B,row at +2, AND mask at
; +6), A into TypedKeys $708B. The key's name is printed in attribute $43
; (KeyNames: the character itself, or SPACE, ENTER, CAPS SHIFT, SYMBOL SHIFT
; for the codes $20, $0D, 1, 2) and BeeperNoise clicks ($C8 pulses).
;
; Then two delays of $C350 ($B0B7) and TypedKeys is compared with CheatWord
; $7090: a difference goes back to MainMenu; ZORBA runs ZorbaCheat $7046.
;
; m1: P O Q A M; exA1: Z O R B A (the cheat), then CS SS Q A M (the shift names
; ran: DefineKeyCapsShift, DefineKeySymbolShift).
DefineKeys:
  CALL AySilence
  CALL ClearScreen
  CALL ClearBlockMap
  CALL FillOpenMap
  LD BC,$001F
  LDIR
  XOR A
  LD (ControlType),A
  LD HL,DefineKeysText
  CALL PrintString
  CALL SaveAttributes     ; the attribute copy, the save buffers, the star
                          ; slots
  CALL ClearWorkArea
  CALL ClearMenuStars
  LD IX,KeyLeftTest       ; IX: the first key test of ReadKeyboard ($7AF0, 10
                          ; bytes each); IY: TypedKeys
  LD IY,TypedKeys
  LD DE,$090F             ; D = row 9, E = column 15: the first answer
  LD B,$05
; This entry point is used by the routine at DefineKeySymbolShift.
DefineKeyLoop:
  PUSH BC                 ; one prompt: ? in attribute $44
  LD A,$3F
  LD C,$44
  CALL PrintChar
  PUSH DE
  CALL WaitNoKey          ; wait for no key
DefineKeyWait:
  CALL ReadKey            ; wait for a key: A ASCII, D port high byte, E bit
                          ; mask
  OR A
  JR Z,DefineKeyWait
  LD (IX+$02),D           ; the key test's LD B,n and AND n operands of
                          ; ReadKeyboard
  LD (IX+$06),E
  LD DE,$000A
  ADD IX,DE
  LD (IY+$00),A           ; the ASCII for the cheat word check
  INC IY
  POP DE
  LD HL,KeyNames          ; the name: the character itself (KeyNames)
  CP $20                  ; SPACE
  JR NZ,DefineKeyNotSpace
  LD HL,KeyNames+$0004
DefineKeyNotSpace:
  CP $0D                  ; ENTER
  JR NZ,DefineKeyNotEnter
  LD HL,KeyNames+$000C
DefineKeyNotEnter:
  CP $01                  ; CAPS SHIFT (code 1)
  JR NZ,DefineKeyNotCaps

; The CAPS SHIFT name, and the test for SYMBOL SHIFT (part of DefineKeys)
;
; LD HL,$706F (KeyNames: CAPS SHIFT) when the key's code is 1. Never ran in the
; given recordings (no prompt took CAPS SHIFT; the static walk does not take
; the fall-through); exA1 ran it once (CS at the first prompt of its second
; round).
DefineKeyCapsShift:
  LD HL,KeyNames+$0014
; This entry point is used by the routine at DefineKeys.
DefineKeyNotCaps:
  CP $02                  ; SYMBOL SHIFT (code 2)
  JR NZ,DefineKeyShowName

; The SYMBOL SHIFT name, the name printed, the click, the loop, the cheat word
; check (part of DefineKeys)
;
; LD HL,$707C (KeyNames: SYMBOL SHIFT) when the key's code is 2: never ran in
; the given recordings, once in exA1 (SS at its second prompt). From $701E
; every prompt runs on here: the code stored in KeyNames' first byte, the name
; printed in attribute $43 (each name ends with a move back to the next
; answer's place, so DE steps two rows down), BeeperNoise with B = $C8, the
; next prompt.
;
; After the fifth: two delays of $C350, then TypedKeys $708B against CheatWord
; $7090, five bytes: the first difference goes back to MainMenu (c1: 3 times,
; m1 once); five equal bytes go on into ZorbaCheat $7046 (exA1 once).
DefineKeySymbolShift:
  LD HL,KeyNames+$0021
; This entry point is used by the routine at DefineKeyCapsShift.
DefineKeyShowName:
  LD (KeyNames),A         ; KeyNames[0] = the key's character (the name of an
                          ; ordinary key)
  LD C,$43
  CALL PrintString
  PUSH DE                 ; the click: a noise burst of $C8 pulses (none on a
                          ; 128K)
  LD B,$C8
  CALL BeeperNoise
  POP DE
  POP BC
  DJNZ DefineKeyLoop
  LD BC,$C350             ; the pause after the fifth key
  CALL Delay
  CALL Delay
  LD HL,TypedKeys         ; the typed keys against ZORBA
  LD DE,CheatWord
  LD B,$05
; This entry point is used by the routine at ZorbaCheat.
CheatCompare:
  LD A,(DE)               ; a difference: back to the menu
  CP (HL)
  JP NZ,MainMenu

; The cheat: keys defined as Z O R B A toggle the lives' DEC A at $9D1D to NOP
; and back, with a jingle when on
;
; The tail of the compare loop (INC HL / INC DE / DJNZ CheatCompare), then
; $9D1D XOR $3D: the lives decrement ($9D1D, the ZXDB POKE 40221) becomes NOP
; (0) or DEC A again. Turned on (the result 0, flag Z) it plays JingleTune
; $7D68 (PlayTune, on the beeper on both machines). Then MainMenu. The keys
; stay defined as Z O R B A (left, right, jump, duck, fire).
;
; Never ran in the given recordings (no definition spelled ZORBA). exA1 (exA's
; capture: 2, Z, O, R, B, A from entry.z80): the five compares passed, $9D1D
; became 0, the jingle played, and in play the instruction at $9D1D ran 10
; times as NOP: ten deaths, no life lost.
ZorbaCheat:
  INC HL
  INC DE
  DJNZ CheatCompare       ; five equal characters: the cheat word
  LD A,(DeathOver+$000F)  ; DEC A ($3D) <-> NOP ($00): the infinite lives
  XOR $3D
  LD (DeathOver+$000F),A
  LD HL,JingleTune        ; the jingle only when the cheat turns on
  CALL Z,PlayTune
  JP MainMenu

; The key names DefineKeys prints: a one-character slot, SPACE, ENTER, CAPS
; SHIFT, SYMBOL SHIFT
;
; Print strings of $AF2B. Each name ends with a move ($7A n: two rows down, n
; columns back) to the next answer's column, then $FF. The first slot's
; character is overwritten with the key's ASCII ($701E) before the print ("?"
; in the image).
KeyNames:
  DEFB $3F,$7A,$FF,$FF
  DEFB $53,$50,$41,$43,$45,$7A,$FB,$FF ; SPACE
  DEFB $45,$4E,$54,$45,$52,$7A,$FB,$FF ; ENTER
  DEFB $43,$41,$50,$53,$20,$53,$48,$49,$46,$54,$7A,$F6,$FF ; CAPS SHIFT
  DEFB $53,$59,$4D,$42,$4F,$4C,$20,$53,$48,$49,$46,$54,$7A,$F4,$FF ; SYMBOL
                                                                   ; SHIFT

; The five ASCII codes typed in DefineKeys, compared with CheatWord
TypedKeys:
  DEFB $00,$00,$00,$00,$00

; ZORBA: the five keys that toggle the infinite lives (ZorbaCheat)
CheatWord:
  DEFM "ZORBA"

; The define keys screen: the logo, SELECT KEY FOR...., LEFT RIGHT JUMP DUCK
; FIRE, the copyright
;
; Printed by DefineKeys. The logo (LogoText) at row 0 column 8, attribute $46,
; SELECT KEY FOR.... at row 6 column 7, the five prompts in bright white from
; row 9 column 7 two rows apart, nine spaces down column 15 (the answers'
; column cleared), the copyright in bright red at row 23.
DefineKeysText:
  DEFB $DF,$00,$08,$E3,$FF,$70,$E0,$46,$DF,$06,$07,$E6,$E0,$D7
  DEFB $53,$45,$4C,$45,$43,$54,$20,$4B,$45,$59,$20,$46,$4F,$52,$2E,$2E ; SELECT KEY
  DEFB $2E,$2E                                                         ; FOR....
  DEFB $DE,$7B,$EE,$4C,$45,$46,$54,$7A,$FC,$52,$49,$47,$48,$54,$7A,$FB ; bright
  DEFB $4A,$55,$4D,$50,$7A,$FC,$44,$55,$43,$4B,$7A,$FC,$46,$49,$52,$45 ; white,
                                                                       ; three rows
                                                                       ; down: LEFT
                                                                       ; RIGHT JUMP
                                                                       ; DUCK FIRE
  DEFB $70,$04,$E5,$09,$20 ; back up to row 9 column 15: nine spaces down (the
                           ; answers)
  DEFB $DF,$17,$02,$D9,$45,$58,$4F,$4C,$4F,$4E,$20,$43,$4F,$50,$59,$52 ; AT 23,2,
  DEFB $49,$47,$48,$54,$20,$31,$39,$38,$37,$20,$48,$45,$57,$53,$4F,$4E ; bright
  DEFB $FF                                                             ; red:
                                                                       ; EXOLON
                                                                       ; COPYRIGHT
                                                                       ; 1987
                                                                       ; HEWSON

; A sub-string that only sets the font to $D7E0: no string or code refers to it
FontResetText:
  DEFB $E6,$E0,$D7,$FF

; The EXOLON logo: glyphs 0-$31 of the logo font at $E6B0, two blocks of 8x3
; characters and two more below
;
; A sub-string ($E3) of MenuText, DefineKeysText, HallOfFameScreen and the
; texts at $A185, $A990, $AA6E. Sets the font to $E6B0 and the attribute $47:
; glyphs 0-7 bright white, 8-15 bright yellow, $10-$17 yellow (the left half,
; three rows), then two rows back up for $18-$2F (the right half, same
; colours), then glyphs $30-$31 one row down and two columns in from the right
; half's start. The caller sets the font again after it.
LogoText:
  DEFB $E6,$B0,$E6,$E0,$47,$DE
  DEFB $00,$01,$02,$03,$04,$05,$06,$07,$A7 ; glyphs 0-7, bright white
  DEFB $DD,$08,$09,$0A,$0B,$0C,$0D,$0E,$0F,$A7 ; next row: 8-$F, bright yellow
  DEFB $D5,$10,$11,$12,$13,$14,$15,$16,$17 ; next row: $10-$17, yellow
  DEFB $76,$00,$DE,$18,$19,$1A,$1B,$1C,$1D,$1E,$1F,$A7,$DD,$20,$21,$22 ; two rows
  DEFB $23,$24,$25,$26,$27,$A7,$D5,$28,$29,$2A,$2B,$2C,$2D,$2E,$2F     ; up: the
                                                                       ; right half
  DEFB $79,$F2,$30,$31    ; one row down, 14 columns back: glyphs $30, $31
  DEFB $FF                ; the end
