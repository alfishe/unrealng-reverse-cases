; ANE's changes to Nether Earth's game ($6731-$D7D7), assembled over NE's bytes by src/game/ane.asm.
;
; Every byte ANE changed is here (tools/mkpatch.py lists them: 90 runs, 3023 bytes with gaps of under 4 equal bytes
; merged); a patch's heading names the NE entry it falls in. Names are NE's (build/ne/ne.sym) where the code is
; NE's, ANE's own otherwise. The reasons, in short (docs/02-architecture.md 2):
;
; - Bank switching: ANE pages banks 1 (the music), 3 (Dead End, the menu picture), 4 (the disk module) and 6
;   (Final Cut) at $C000 while the game runs, so NE's IM 2 table at $FE00 (under paged memory) moves to $6800-$6900
;   with the vector $6969 and the handler word at $696A (in NE's font, which the game no longer needs there: the
;   new Cyrillic font is at $C500).
; - Music: an AY tune plays in the menus and in play, from bank 1 (MusicInterrupt, PlayMusic). NE's beeper title
;   tune and colour cycle are gone; their place ($C4A7-$C848) holds the new font.
; - The disk replaces the tape: LoadGame and SaveGameBlocks call the disk module in bank 4 (GameLoad, GameSave).
; - The endings: a won game runs Final Cut (bank 6), a lost one Dead End (bank 3), instead of NE's text line.
; - Russian texts in the new font (tools/game_text.py gives the letters; the comments show them).

; ---------------------------------------------------------------------------------------------------------------
; The glue in NE's font place, $6780-$697F
; ---------------------------------------------------------------------------------------------------------------

    ORG $6780
; The interrupt outside play (NE's StartInterrupt: nothing a frame): one frame of the tune, bank 1's player at
; $C005, then the game's paging back. Installed by Start, ConstructionMenu, SaveGame and LoadError
MusicInterrupt:
    DI
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    PUSH IX
    PUSH IY
    EXX
    EX AF,AF'
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    LD A,$11                    ; bank 1: the tunes and their player
    LD BC,$7FFD
    OUT (C),A
    CALL $C005                  ; the player: one frame
    LD BC,$7FFD
    LD A,(GameBank)             ; the bank the game had paged
    OUT (C),A
    POP HL
    POP DE
    POP BC
    POP AF
    EX AF,AF'
    EXX
    POP IY
    POP IX
    POP HL
    POP DE
    POP BC
    POP AF
    EI
    RET

; PlayInterrupt's CALL ShowRadar ($D582) is a JP here: the radar, one frame of the tune, back into PlayInterrupt
PlayMusic:
    CALL ShowRadar
    PUSH AF
    PUSH BC
    PUSH DE
    PUSH HL
    PUSH IX
    PUSH IY
    LD A,$11
    LD BC,$7FFD
    OUT (C),A
    CALL $C005
    LD BC,$7FFD
    LD A,(GameBank)
    OUT (C),A
    POP IY
    POP IX
    POP HL
    POP DE
    POP BC
    POP AF
    JP PlayInterrupt + $1F      ; PlayInterrupt after its CALL ShowRadar

; The game's last $7FFD write (bank 0, screen 5, the 48 ROM: $10); the music handlers page it back
GameBank:
    DB $10

; Page A, kept in GameBank
SetGameBank:
    PUSH BC
    LD BC,$7FFD
    LD (GameBank),A
    OUT (C),A
    POP BC
    RET

; MainMenuTitle's CALL PrintTitle is a CALL here: the menu's picture, drawn by bank 3's code ($E73B) on a stack
; below the game's code
MenuPicture:
    LD (.sp + 1),SP
    LD SP,$A5ED                 ; the free bytes of NE's SpriteSpare
    LD A,$13
    CALL SetGameBank
    CALL $E73B                  ; bank 3: the picture
    LD A,$10
    CALL SetGameBank
.sp:
    LD SP,0
    RET

    DS $6800 - $, 0
; $6800-$6900: the IM 2 table, 257 bytes of $69 written by Start (ImTable); zero on the disk
ImTable:
    DS $6905 - $, 0

; SaveGameBlocks after its prompt ($C2E5): the disk module in bank 4 saves the game (IX = $4033, its save entry
; once it has copied itself to $4000) and comes back to SaveReturn
GameSave:
    LD (SaveReturn + 1),SP
    LD SP,$A5ED
    LD IX,$4033
    LD A,$14                    ; bank 4: the disk module
    EI
    HALT                        ; a frame's start, so the music handler does not run during the switch
    LD BC,$7FFD
    OUT (C),A
    LD A,$CC                    ; FLAGS: the ROM's key reading as the module's input expects
    LD ($5C3B),A
    LD A,$0D                    ; LAST_K = ENTER
    LD ($5C08),A
    LD HL,$5C6A                 ; FLAGS2: CAPS LOCK off
    RES 3,(HL)
    JP $C000                    ; the module: it returns with JP SaveReturn
SaveReturn:
    LD SP,0
    LD A,$68                    ; IM 2 through ImTable again
    LD I,A
    IM 2
    EI
    HALT
    JP PlayLoop + $83           ; PlayLoop's JP EnterPlay: the play screen again

    DS $6969 - $, 0
; $6969: JP Handler, written by Start ($A611: A = $C3); $696A the handler's address (NE: $FDFD / $FDFE)
ImJump:
    DB 0
ImHandler:
    DW 0
    DS $6980 - $, 0

; ---------------------------------------------------------------------------------------------------------------
; The game's new entries in NE's SpriteSpare, $A56A-$A5FF
; ---------------------------------------------------------------------------------------------------------------

    ORG $A56A
; LoadGame (key 5 of the main menu): the disk module in bank 4 loads a saved game (IX = $4000, its load entry)
GameLoad:
    LD (LoadReturn + 1),SP
    LD SP,$A5ED
    LD IX,$4000
    LD A,$14
    EI
    HALT
    LD BC,$7FFD
    OUT (C),A
    LD A,$CC
    LD ($5C3B),A
    LD A,$0D
    LD ($5C08),A
    LD HL,$5C6A
    RES 3,(HL)
    JP $C000
LoadReturn:
    LD SP,0
    LD A,$68
    LD I,A
    IM 2
    EI
    HALT
    LD HL,$FFFF                 ; $5B00: NE's saved-game checksum word, now a "loaded" mark
    LD ($5B00),HL
    JP NewGameSetup

    ORG $A5DA
; The game block's entry (its HRUM block ends with JP $A5DA, SP = $6731): the tune chosen (bank 1, $D8E1),
; then Restart
GameEntry:
    DI
    LD SP,0
    LD A,$11
    LD BC,$7FFD
    OUT (C),A
    CALL $D8E1                  ; bank 1: the tune's set-up
    LD A,$10
    LD BC,$7FFD
    OUT (C),A
; Every restart (NE's JP Start: abort key, a load error, the end of a game) comes here: the player initialised,
; then NE's Start from its IM 2 table on (Start's own DI and LD SP,0 are overwritten by this code's last bytes)
Restart:
    DI
    LD SP,0
    LD A,$11
    LD BC,$7FFD
    OUT (C),A
    CALL $C000                  ; bank 1: the player's init
    LD A,$10
    LD BC,$7FFD
    OUT (C),A                   ; $A602: Start + 2
; Start + 4: the IM 2 table at $6800 of $69 bytes (NE: $FE00 of $FD)
    LD HL,$6800
    LD BC,$0069

    ORG Start + $12
    DW ImJump                   ; Start: LD (ImJump),A, the JP opcode
    LD HL,MusicInterrupt        ; the handler outside play (NE: StartInterrupt)
    LD (ImHandler),HL
    LD A,$68                    ; I = $68 (NE: $FE)

    ORG EnterPlay + $A
    DW ImHandler                ; EnterPlay: LD (ImHandler),HL = PlayInterrupt

    ORG PlayLoop + $79
    DW Restart                  ; key I (abort): JP NZ,Restart

    ORG PlayLoop + $80
    JP SaveGameBlocks + 3       ; key 5 (save): NE's CALL SaveGame; JP EnterPlay becomes a jump past the tape
                                ; prompt of SaveGameBlocks (SaveGame and its prompt are not used)

    ORG UnusedTapeCode + 8
    DW Restart

; ---------------------------------------------------------------------------------------------------------------
; The end of a game: Dead End or Final Cut
; ---------------------------------------------------------------------------------------------------------------

    ORG CheckGameEnd + $B
; Lost (we have no warbase): the AY silenced, IM 1, bank 3, Dead End's entry. NE: CALL GameStop, the lost text
    CALL Silence
    LD A,$3F
    LD I,A
    IM 1
    EI
    LD A,$13
    LD BC,$7FFD
    OUT (C),A
    JP $D2EF                    ; bank 3: Dead End
    DS 10, 0
; The AY's registers 0-14 zero: no tone, no noise, volumes 0
Silence:
    XOR A
    HALT                        ; once: a frame's start
    DI
.reg:
    LD BC,$FFFD
    OUT (C),A
    PUSH AF
    XOR A
    LD B,$BF
    OUT (C),A
    POP AF
    INC A
    CP 15
    JR NZ,.reg
    RET
    DS 8, 0
; GameWon (the enemy has no warbase): bank 6's Final Cut block copied to $6060 and run (it unpacks there and
; never returns). NE: CALL GameStop, the won text
    ASSERT $ == GameWon
    CALL Silence
    LD A,$3F
    LD I,A
    IM 1
    EI
    LD A,$16
    LD BC,$7FFD
    OUT (C),A
    LD HL,$C000
    LD DE,$6060
    LD BC,$3637                 ; Final Cut's block: 13869 bytes; the copy takes a few more
    LDIR
    LD A,$10
    LD BC,$7FFD
    OUT (C),A
    JP $6060
    DS 10, 0
    DB "  "                     ; the rest of NE's WonText, unchanged after this

    ORG GameOverWait + $14
    DW Restart                  ; unreached now (both ends leave the game)

    ORG GameStop + $B
; GameStop: LD HL,MusicInterrupt; LD ($6D6A),HL. $6D6A is a typo for ImHandler ($696A): it writes into the view
; buffer and leaves the handler as it is. Harmless: CheckGameEnd no longer calls GameStop, nothing else does
    DW MusicInterrupt
    DB $22
    DW $6D6A

; ---------------------------------------------------------------------------------------------------------------
; Menus, the disk, the print routines
; ---------------------------------------------------------------------------------------------------------------

    ORG MainMenuTitle + 1
    DW MenuPicture              ; the picture instead of NE's title letters

    ORG MainMenuKeys + $C
; NE's CALL MenuMusic (the beeper tune, now gone) and CALL TitleColourCycle: NOPs; a HALT keeps the loop's pace
    NOP
    NOP
    NOP
    HALT
    NOP
    NOP
    NOP

    ORG PrintTitle
; PrintTitle: NE's CALL PrintInline and TitleText blanked; the RET stays (MenuPicture draws the title)
    DS 25, 0
    RET
; LoadGame (key 5): NE's CALL PrintTitle and tape load become the disk load
    JP GameLoad

    ORG LoadGameBlocks + $2A
; The checksum test of the tape load: NOPs (the tape path is no longer reached)
    DS 10, 0

    ORG LoadError + 9
    DW Restart                  ; LoadError: JP Restart
    ORG SaveGame
    LD HL,MusicInterrupt        ; SaveGame: the handler outside play
    LD (ImHandler),HL

    ORG SaveGameBlocks + $1C
; After the key: the disk save instead of the tape staging and blocks
    JP GameSave
    DS 13, 0

    ORG KeyNameSpace
; "ПРОБЕЛ" (SPACE), and MenuMusic reduced to a RET: $C4A8-$C4FF free, the font from $C500 (codes $20-$5F,
; PrintChar and PrintBigChar read glyph $C400 + 8 x code), $C700-$C848 free
    DB $57,$50,$4F,$5B,$45,$4C,$00   ; ПРОБЕЛ
    ASSERT $ == MenuMusic
    RET
    DB $FE
    DS $C500 - $, 0
GameFont:
    INCBIN "build/res/gfx/game-font.bin"
    DS ConstructionMenu - $, 0
    ASSERT $ == $C849

    ORG ConstructionMenu + $16
    DW MusicInterrupt           ; ConstructionMenu: LD HL,MusicInterrupt; LD (ImHandler),HL
    DB $22
    DW ImHandler

    ORG StartRobot + $54
    DW ImHandler                ; StartRobot: LD (ImHandler),HL = PlayInterrupt

    ORG PrintChar + 7
    DW $C400                    ; the glyph base: $C400 + 8 x code (NE: $6680, its font at $6780)
    ORG PrintBigChar + 7
    DW $C400

    ORG PlayInterrupt + $1C
    JP PlayMusic                ; NE: CALL ShowRadar

; ---------------------------------------------------------------------------------------------------------------
; The texts in Russian (tools/mkpatch.py; the comments are the letters of the game font, tools/game_text.py).
; Codes below $20 are PrintInline's controls, as in NE. Each heading: the NE text entry and what it said.
; ---------------------------------------------------------------------------------------------------------------

; RobotMenuText+5 (The robot menu: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT, -ORDERS-): 6 bytes
    ORG $A73D
    DB $57,$50,$53,$4D,$4F,$45                                           ; ПРЯМОЕ

; RobotMenuText+F (The robot menu: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT, -ORDERS-): 15 bytes
    ORG $A747
    DB $59,$57,$50,$41,$42,$4C,$2E,$03,$03,$4F,$54,$44,$41,$54,$52       ; УПРАВЛ...ОТДАТЬ

; RobotMenuText+23 (The robot menu: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT, -ORDERS-): 14 bytes
    ORG $A75B
    DB $57,$50,$49,$4B,$41,$33,$03,$03,$5B,$4F,$45,$42,$4F,$49           ; ПРИКАЗ..БОЕВОИ

; RobotMenuText+37 (The robot menu: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT, -ORDERS-): 24 bytes
    ORG $A76F
    DB $50,$45,$4A,$49,$4D,$03,$03,$4F,$43,$54,$41,$42,$49,$54,$52,$03   ; РЕЖИМ..ОСТАВИТЬ.
    DB $20,$20,$50,$4F,$5B,$4F,$54,$41                                   ;   РОБОТА

; RobotMenuText+53 (The robot menu: DIRECT CONTROL, GIVE ORDERS, COMBAT MODE, LEAVE ROBOT, -ORDERS-): 9 bytes
    ORG $A78B
    DB $20,$57,$50,$49,$4B,$41,$33,$20,$20                               ;  ПРИКАЗ  

; StrengthText+5 ("STRENGTH" at (22,23) attribute $46, then (23,25) attribute $47): 8 bytes
    ORG $A825
    DB $20,$20,$43,$49,$4C,$41,$20,$20                                   ;   СИЛА  

; OrderNames+0 (The names of the orders, 27 bytes each (order 0: STOP AND DEFEND)): 34 bytes
    ORG $A848
    DB $43,$54,$4F,$53,$54,$52,$20,$49,$03,$44,$45,$50,$4A,$41,$54,$52   ; СТОЯТЬ И.ДЕРЖАТЬ
    DB $20,$03,$4F,$5B,$4F,$50,$4F,$48,$59,$20,$00,$20,$42,$57,$45,$50   ;  .ОБОРОНУ . ВПЕР
    DB $45,$44                                                           ; ЕД

; OrderName1+16 (Order 1: ADVANCE (the miles are printed into the blank middle line)): 12 bytes
    ORG $A879
    DB $52,$20,$20,$20,$00,$20,$48,$41,$33,$41,$44,$20                   ; Ь   . НАЗАД 

; OrderName2+16 (Order 2: RETREAT (the miles in the middle line)): 166 bytes
    ORG $A894
    DB $52,$20,$20,$20,$00,$4C,$49,$4B,$42,$49,$44,$2E,$20,$03,$42,$50   ; Ь   .ЛИКВИД. .ВР
    DB $41,$4A,$45,$43,$4B,$2E,$03,$50,$4F,$5B,$4F,$54,$4F,$42,$20,$00   ; АЖЕСК..РОБОТОВ .
    DB $4C,$49,$4B,$42,$49,$44,$2E,$20,$03,$42,$50,$41,$4A,$45,$43,$4B   ; ЛИКВИД. .ВРАЖЕСК
    DB $2E,$03,$20,$33,$41,$42,$4F,$44,$51,$20,$00,$4C,$49,$4B,$42,$49   ; .. ЗАВОДЫ .ЛИКВИ
    DB $44,$2E,$20,$03,$42,$50,$41,$4A,$45,$43,$4B,$2E,$03,$20,$20,$5B   ; Д. .ВРАЖЕСК..  Б
    DB $41,$33,$51,$20,$20,$00,$20,$33,$41,$58,$42,$41,$54,$20,$03,$48   ; АЗЫ  . ЗАХВАТ .Н
    DB $45,$49,$54,$50,$41,$4C,$2E,$03,$20,$33,$41,$42,$4F,$44,$4F,$42   ; ЕИТРАЛ.. ЗАВОДОВ
    DB $00,$20,$33,$41,$58,$42,$41,$54,$20,$03,$42,$50,$41,$4A,$45,$43   ; . ЗАХВАТ .ВРАЖЕС
    DB $4B,$2E,$03,$20,$33,$41,$42,$4F,$44,$4F,$42,$00,$20,$33,$41,$58   ; К.. ЗАВОДОВ. ЗАХ
    DB $42,$41,$54,$20,$03,$42,$50,$41,$4A,$45,$43,$4B,$2E,$03,$20,$20   ; ВАТ .ВРАЖЕСК..  
    DB $5B,$41,$33,$20,$20,$20                                           ; БАЗ   

; OrdersMenuText+5 (GIVE ORDERS: SELECT ORDERS and the five items): 13 bytes
    ORG $A97C
    DB $4F,$54,$44,$41,$54,$52,$03,$57,$50,$49,$4B,$41,$33               ; ОТДАТЬ.ПРИКАЗ

; OrdersMenuText+17 (GIVE ORDERS: SELECT ORDERS and the five items): 26 bytes
    ORG $A98E
    DB $44,$45,$50,$4A,$41,$54,$51,$20,$03,$20,$4F,$5B,$4F,$50,$4F,$48   ; ДЕРЖАТЫ . ОБОРОН
    DB $59,$03,$03,$42,$57,$45,$50,$45,$44,$20                           ; У..ВПЕРЕД 

; OrdersMenuText+39 (GIVE ORDERS: SELECT ORDERS and the five items): 11 bytes
    ORG $A9B0
    DB $52,$20,$03,$03,$20,$48,$41,$33,$41,$44,$20                       ; Ь .. НАЗАД 

; OrdersMenuText+4C (GIVE ORDERS: SELECT ORDERS and the five items): 40 bytes
    ORG $A9C3
    DB $52,$20,$03,$03,$57,$4F,$49,$43,$4B,$20,$49,$20,$03,$4C,$49,$4B   ; Ь ..ПОИСК И .ЛИК
    DB $42,$49,$44,$2E,$20,$03,$03,$57,$4F,$49,$43,$4B,$20,$49,$20,$03   ; ВИД. ..ПОИСК И .
    DB $20,$33,$41,$58,$42,$41,$54,$20                                   ;  ЗАХВАТ 

; AdvanceTitle+5 ("ADVANCE " at (5,23), attribute $4F): 7 bytes
    ORG $AA24
    DB $20,$42,$57,$45,$50,$45,$44                                       ;  ВПЕРЕД

; RetreatTitleText+4 ("RETREAT " at (5,23), attribute $4F): 8 bytes
    ORG $AA36
    DB $20,$20,$48,$41,$33,$41,$44,$20                                   ;   НАЗАД 

; DistanceText+7 (The distance menu: ?? MILES, SELECT DISTANCE, 0 MILES): 2 bytes
    ORG $AA4A
    DB $52,$20                                                           ; Ь 

; DistanceText+F (The distance menu: ?? MILES, SELECT DISTANCE, 0 MILES): 15 bytes
    ORG $AA52
    DB $42,$51,$5B,$4F,$50,$20,$03,$44,$49,$43,$54,$41,$48,$2E,$20       ; ВЫБОР .ДИСТАН. 

; DistanceText+28 (The distance menu: ?? MILES, SELECT DISTANCE, 0 MILES): 2 bytes
    ORG $AA6B
    DB $52,$20                                                           ; Ь 

; DestroyMenuText+5 (SEARCH & DESTROY: SELECT TARGET, ENEMY ROBOTS, FACTORYS, WARBASES): 17 bytes
    ORG $AADD
    DB $57,$4F,$49,$43,$4B,$20,$49,$20,$03,$4C,$49,$4B,$42,$49,$44,$2E   ; ПОИСК И .ЛИКВИД.
    DB $20                                                               ;  

; DestroyMenuText+1B (SEARCH & DESTROY: SELECT TARGET, ENEMY ROBOTS, FACTORYS, WARBASES): 13 bytes
    ORG $AAF3
    DB $42,$51,$5B,$4F,$50,$20,$03,$5A,$45,$4C,$49,$20,$20               ; ВЫБОР .ЦЕЛИ  

; DestroyMenuText+2D (SEARCH & DESTROY: SELECT TARGET, ENEMY ROBOTS, FACTORYS, WARBASES): 55 bytes
    ORG $AB05
    DB $42,$50,$41,$4A,$45,$43,$4B,$2E,$03,$20,$50,$4F,$5B,$4F,$54,$51   ; ВРАЖЕСК.. РОБОТЫ
    DB $20,$03,$03,$42,$50,$41,$4A,$45,$43,$4B,$2E,$03,$33,$41,$42,$4F   ;  ..ВРАЖЕСК..ЗАВО
    DB $44,$51,$20,$20,$03,$03,$42,$50,$41,$4A,$45,$43,$4B,$2E,$03,$20   ; ДЫ  ..ВРАЖЕСК.. 
    DB $20,$5B,$41,$33,$51,$20,$20                                       ;  БАЗЫ  

; CaptureMenuText+4 (SEARCH & CAPTURE: SELECT TARGET, NEUTRAL FACTORYS, ENEMY FACTORYS, ENEMY WARBASES): 18 bytes
    ORG $AB58
    DB $20,$57,$4F,$49,$43,$4B,$20,$20,$49,$03,$20,$33,$41,$58,$42,$41   ;  ПОИСК  И. ЗАХВА
    DB $54,$20                                                           ; Т 

; CaptureMenuText+1B (SEARCH & CAPTURE: SELECT TARGET, NEUTRAL FACTORYS, ENEMY FACTORYS, ENEMY WARBASES): 13 bytes
    ORG $AB6F
    DB $42,$51,$5B,$4F,$50,$20,$03,$20,$5A,$45,$4C,$49,$20               ; ВЫБОР . ЦЕЛИ 

; CaptureMenuText+2D (SEARCH & CAPTURE: SELECT TARGET, NEUTRAL FACTORYS, ENEMY FACTORYS, ENEMY WARBASES): 55 bytes
    ORG $AB81
    DB $48,$45,$49,$54,$50,$2E,$20,$20,$03,$20,$33,$41,$42,$4F,$44,$51   ; НЕИТР.  . ЗАВОДЫ
    DB $20,$03,$03,$42,$50,$41,$4A,$45,$43,$4B,$2E,$03,$20,$33,$41,$42   ;  ..ВРАЖЕСК.. ЗАВ
    DB $4F,$44,$51,$20,$03,$03,$42,$50,$41,$4A,$45,$43,$4B,$2E,$03,$20   ; ОДЫ ..ВРАЖЕСК.. 
    DB $20,$5B,$41,$33,$51,$20,$20                                       ;  БАЗЫ  

; CombatMenuText+5 (COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE ROBOT, STOP COMBAT): 7 bytes
    ORG $AC0B
    DB $41,$54,$4F,$4D,$48,$41,$53                                       ; АТОМНАЯ

; CombatMenuText+11 (COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE ROBOT, STOP COMBAT): 12 bytes
    ORG $AC17
    DB $5B,$4F,$4D,$5B,$41,$03,$03,$4F,$47,$4F,$48,$52                   ; БОМБА..ОГОНЬ

; CombatMenuText+22 (COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE ROBOT, STOP COMBAT): 14 bytes
    ORG $AC28
    DB $46,$41,$33,$4F,$50,$4F,$42,$03,$03,$4F,$47,$4F,$48,$52           ; ФАЗОРОВ..ОГОНЬ

; CombatMenuText+34 (COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE ROBOT, STOP COMBAT): 15 bytes
    ORG $AC3A
    DB $20,$20,$20,$50,$41,$4B,$45,$54,$03,$03,$4F,$47,$4F,$48,$52       ;    РАКЕТ..ОГОНЬ

; CombatMenuText+49 (COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE ROBOT, STOP COMBAT): 15 bytes
    ORG $AC4F
    DB $20,$57,$59,$4E,$45,$4B,$03,$03,$20,$44,$42,$49,$4A,$45,$2D       ;  ПУШЕК.. ДВИЖЕ-

; CombatMenuText+5D (COMBAT MODE: NUCLEAR BOMB, FIRE PHASERS, FIRE MISSILES, FIRE CANNON, MOVE ROBOT, STOP COMBAT): 24 bytes
    ORG $AC63
    DB $48,$49,$45,$20,$20,$03,$03,$42,$51,$58,$4F,$44,$20,$49,$33,$03   ; НИЕ  ..ВЫХОД ИЗ.
    DB $20,$20,$4D,$45,$48,$55,$20,$20                                   ;   МЕНЮ  

; MenuStartText+5 ("0..START GAME" at (11,8) in double height, yellow): 15 bytes
    ORG $C10E
    DB $0A,$01,$30,$2E,$2E,$43,$54,$41,$50,$54,$20,$49,$47,$50,$51       ; ..0..СТАРТ ИГРЫ

; MenuKeyboardText+7 (Three new lines and "1..KEYBOARD"): 7 bytes
    ORG $C12F
    DB $4C,$41,$42,$49,$4E,$49,$20                                       ; ЛАВИШИ 

; MenuKempstonText+8 (Two new lines and "2..KEMPSTON J/S"): 9 bytes
    ORG $C147
    DB $57,$43,$54,$4F,$48,$20,$44,$4A,$2E                               ; ПСТОН ДЖ.

; MenuMoreText+6 ("3..INTERFACE 2", then in yellow "4..REDEFINE KEYS", "5..LOAD SAVED GAME"): 8 bytes
    ORG $C15F
    DB $48,$54,$45,$50,$46,$45,$49,$43                                   ; НТЕРФЕИС

; MenuMoreText+17 ("3..INTERFACE 2", then in yellow "4..REDEFINE KEYS", "5..LOAD SAVED GAME"): 13 bytes
    ORG $C170
    DB $33,$41,$44,$41,$54,$52,$20,$4B,$4C,$41,$42,$2E,$20               ; ЗАДАТЬ КЛАВ. 

; MenuMoreText+29 ("3..INTERFACE 2", then in yellow "4..REDEFINE KEYS", "5..LOAD SAVED GAME"): 20 bytes
    ORG $C182
    DB $33,$41,$47,$50,$59,$33,$4B,$41,$00,$76,$00,$00,$00,$00,$00,$00   ; ЗАГРУЗКА.v......
    DB $00,$00,$00,$00                                                   ; ....

; PlayTapeText+7 ("PRESS PLAY ON TAPE" at (22,7), cyan, double height): 19 bytes
    ORG $C20A
    DB $42,$4B,$4C,$55,$56,$49,$54,$45,$20,$4D,$41,$47,$48,$49,$54,$4F   ; ВКЛЮЧИТЕ МАГНИТО
    DB $46,$4F,$48                                                       ; ФОН

; LoadErrorText+7 ("LOADING ERROR!" at (22,2), white, double size): 13 bytes
    ORG $C273
    DB $4F,$4E,$49,$5B,$4B,$41,$20,$42,$42,$4F,$44,$41,$20               ; ОШИБКА ВВОДА 

; RecordText+5 ("PRESS RECORD AND PLAY ", a new line, "     THEN ANY KEY     " at (22,0), cyan): 44 bytes
    ORG $C29B
    DB $42,$4B,$4C,$55,$56,$49,$54,$45,$20,$4D,$41,$47,$48,$49,$54,$4F   ; ВКЛЮЧИТЕ МАГНИТО
    DB $46,$4F,$48,$20,$20,$20,$03,$49,$20,$48,$41,$4A,$4D,$49,$54,$45   ; ФОН   .И НАЖМИТЕ
    DB $20,$4C,$55,$5B,$59,$55,$20,$4B,$4C,$41,$42,$2E                   ;  ЛЮБУЮ КЛАВ.

; RedefineTitleText+7 ("REDEFINE KEYS" at (2,9), white, double height, then position (5,3) and normal size): 13 bytes
    ORG $C357
    DB $33,$41,$44,$41,$49,$54,$45,$20,$4B,$4C,$41,$42,$2E               ; ЗАДАИТЕ КЛАВ.

; KeyNameUp+0 ("   UP"): 5 bytes
    ORG $C382
    DB $42,$42,$45,$50,$58                                               ; ВВЕРХ

; KeyNameDown+1 (" DOWN"): 4 bytes
    ORG $C392
    DB $42,$48,$49,$33                                                   ; ВНИЗ

; KeyNameLeft+0 (" LEFT"): 5 bytes
    ORG $C3A0
    DB $42,$4C,$45,$42,$4F                                               ; ВЛЕВО

; KeyNameRight+0 ("RIGHT"): 5 bytes
    ORG $C3AF
    DB $42,$57,$50,$2E,$20                                               ; ВПР. 

; KeyNameFire+0 (" FIRE"): 5 bytes
    ORG $C3BE
    DB $4F,$47,$4F,$48,$52                                               ; ОГОНЬ

; KeyNamePause+0 ("PAUSE"): 5 bytes
    ORG $C3D0
    DB $57,$41,$59,$33,$41                                               ; ПАУЗА

; KeyNameAbort+0 ("ABORT"): 5 bytes
    ORG $C3DF
    DB $43,$5B,$50,$4F,$43                                               ; СБРОС

; KeyNameSave+0 (" SAVE"): 5 bytes
    ORG $C3EE
    DB $42,$51,$47,$50,$2E                                               ; ВЫГР.

; PressKeyForText+4 (PrintInline text: new line, new line, attribute $46, "PRESS KEY FOR ", attribute $45): 13 bytes
    ORG $C413
    DB $48,$41,$4A,$4D,$2E,$20,$4B,$4C,$41,$42,$49,$4E,$59               ; НАЖМ. КЛАВИШУ

; KeyNameEnter+1 (PrintInline text: "ENTER"): 4 bytes
    ORG $C482
    DB $48,$54,$45,$50                                                   ; НТЕР

; KeyNameCapsShift+0 (PrintInline text: "CAPS SH"): 7 bytes
    ORG $C48F
    DB $4B,$2E,$20,$4E,$49,$46,$54                                       ; К. ШИФТ

; ConstructionTitleText+7 (PrintInline text: "ROBOT" (double size) at row 0, "CONSTRUCTION" (double height) at row 2): 5 bytes
    ORG $C8C5
    DB $20,$5A,$45,$58,$20                                               ;  ЦЕХ 

; ConstructionTitleText+11 (PrintInline text: "ROBOT" (double size) at row 0, "CONSTRUCTION" (double height) at row 2): 12 bytes
    ORG $C8CF
    DB $20,$20,$50,$4F,$5B,$4F,$54,$4F,$42,$20,$20,$20                   ;   РОБОТОВ   

; PartNamesText+5 (PrintInline text: the part names at column 21, ELECTRONICS row 1 down to BIPOD row 22, every 3 rows): 51 bytes
    ORG $C8E2
    DB $24,$4C,$45,$4B,$54,$50,$4F,$48,$49,$4B,$41,$01,$04,$15,$41,$2D   ; ЭЛЕКТРОНИКА...А-
    DB $5B,$4F,$4D,$5B,$51,$01,$07,$15,$46,$41,$33,$4F,$50,$51,$20,$01   ; БОМБЫ...ФАЗОРЫ .
    DB $0A,$15,$50,$41,$4B,$45,$54,$51,$20,$20,$01,$0D,$15,$57,$59,$4E   ; ..РАКЕТЫ  ...ПУШ
    DB $4B,$49,$20                                                       ; КИ 

; PartNamesText+3C (PrintInline text: the part names at column 21, ELECTRONICS row 1 down to BIPOD row 22, every 3 rows): 8 bytes
    ORG $C919
    DB $48,$54,$49,$47,$50,$41,$42,$51                                   ; НТИГРАВЫ

; PartNamesText+48 (PrintInline text: the part names at column 21, ELECTRONICS row 1 down to BIPOD row 22, every 3 rows): 11 bytes
    ORG $C925
    DB $50,$41,$4B,$49,$20,$01,$16,$15,$5B,$49,$57                       ; РАКИ ...БИП

; ExitStartText+3 (PrintInline text: "EXIT START" / "MENU ROBOT" at rows 21-22, columns 5 and 10): 21 bytes
    ORG $C935
    DB $42,$51,$2D,$20,$20,$42,$51,$2D,$20,$20,$03,$58,$4F,$44,$20,$20   ; ВЫ-  ВЫ-  .ХОД  
    DB $57,$59,$43,$4B,$20                                               ; ПУСК 

; ResourceNamesText+A (PrintInline text: "-- RESOURCES --" / "-- AVAILABLE --", GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16, TOTAL row 18): 9 bytes
    ORG $C978
    DB $48,$41,$4C,$49,$56,$48,$51,$45,$20                               ; НАЛИЧНЫЕ 

; ResourceNamesText+1A (PrintInline text: "-- RESOURCES --" / "-- AVAILABLE --", GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16, TOTAL row 18): 9 bytes
    ORG $C988
    DB $20,$50,$45,$43,$59,$50,$43,$51,$20                               ;  РЕСУРСЫ 

; ResourceNamesText+2B (PrintInline text: "-- RESOURCES --" / "-- AVAILABLE --", GENERAL row 9, ELECTRONICS-CHASSIS rows 11-16, TOTAL row 18): 77 bytes
    ORG $C999
    DB $4F,$5B,$23,$49,$45,$20,$20,$01,$0B,$00,$24,$4C,$45,$4B,$54,$50   ; ОБЩИЕ  ...ЭЛЕКТР
    DB $4F,$48,$49,$4B,$41,$01,$0C,$04,$41,$2D,$5B,$4F,$4D,$5B,$51,$03   ; ОНИКА...А-БОМБЫ.
    DB $46,$41,$33,$4F,$50,$51,$20,$01,$0E,$03,$20,$50,$41,$4B,$45,$54   ; ФАЗОРЫ ... РАКЕТ
    DB $51,$20,$01,$0F,$05,$57,$59,$4E,$4B,$49,$20,$01,$10,$04,$4E,$41   ; Ы ...ПУШКИ ...ША
    DB $43,$43,$49,$20,$20,$01,$12,$06,$42,$43,$45,$47,$4F               ; ССИ  ...ВСЕГО

; PlayScreenText+7 (Inline string: " DAY:" and "TIME:" at (0,22), the tall "RADAR:" at (22,0)): 10 bytes
    ORG $D1CC
    DB $44,$45,$48,$52,$3A,$03,$20,$56,$41,$43                           ; ДЕНЬ:. ЧАС

; PlayScreenText+19 (Inline string: " DAY:" and "TIME:" at (0,22), the tall "RADAR:" at (22,0)): 5 bytes
    ORG $D1DE
    DB $50,$41,$44,$41,$50                                               ; РАДАР

; StatusPanelText+7 (Inline string: the STATUS and RESOURCES labels of the right panel): 17 bytes
    ORG $D1F2
    DB $43,$54,$41,$54,$59,$43,$03,$49,$48,$4F,$57,$2E,$20,$4C,$55,$44   ; СТАТУС.ИНОП. ЛЮД
    DB $49                                                               ; И

; StatusPanelText+1D (Inline string: the STATUS and RESOURCES labels of the right panel): 66 bytes
    ORG $D208
    DB $20,$20,$5B,$41,$33,$51,$20,$20,$03,$24,$4C,$45,$4B,$54,$50,$2E   ;   БАЗЫ  .ЭЛЕКТР.
    DB $20,$03,$41,$2D,$5B,$4F,$4D,$5B,$51,$03,$20,$46,$41,$33,$4F,$50   ;  .А-БОМБЫ. ФАЗОР
    DB $51,$03,$20,$50,$41,$4B,$45,$54,$51,$20,$03,$20,$57,$59,$4E,$4B   ; Ы. РАКЕТЫ . ПУШК
    DB $49,$20,$03,$20,$4E,$41,$43,$43,$49,$20,$03,$20,$50,$4F,$5B,$4F   ; И . ШАССИ . РОБО
    DB $54,$51                                                           ; ТЫ

; StatusPanelText+64 (Inline string: the STATUS and RESOURCES labels of the right panel): 9 bytes
    ORG $D24F
    DB $20,$50,$45,$43,$59,$50,$43,$51,$20                               ;  РЕСУРСЫ 

; StatusPanelText+71 (Inline string: the STATUS and RESOURCES labels of the right panel): 54 bytes
    ORG $D25C
    DB $4F,$5B,$23,$49,$45,$20,$20,$03,$24,$4C,$45,$4B,$54,$50,$2E,$03   ; ОБЩИЕ  .ЭЛЕКТР..
    DB $41,$54,$4F,$4D,$48,$2E,$20,$03,$46,$41,$33,$4F,$50,$51,$20,$03   ; АТОМН. .ФАЗОРЫ .
    DB $50,$41,$4B,$45,$54,$51,$20,$03,$57,$59,$4E,$4B,$49,$20,$03,$4E   ; РАКЕТЫ .ПУШКИ .Ш
    DB $41,$43,$43,$49,$20,$20                                           ; АССИ  
