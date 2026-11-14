; --------------------------------------------------------------------------------------------------------------------
; menu.asm: The menu, the control choice, the new game, quit and GAME OVER
;
; The menu Menu $E219 prints the title, the four control methods and the credits, plays tune 5 and lights the chosen
; method's row until fire. Keys 1-4 (`$A103`, `$A10B`, `$A113`, `$A11B`) store the method in `$A14C` (0 keyboard, 1
; Kempston, 2 cursor, 3 Sinclair) and click (`$AB18` with `$AB45`).
;
; NewGame $E2DC clears the done flags of the level object lists, the level, the game-complete flag and the score,
; gives 6 lives, 6 bullets and 6 dynamite, prints the first level's intro text, plays tune 0 and waits for the fire
; key to be let go; StartLevel $E32C (module levels) then waits for fire.
;
; Quit $E35A (Q in the main loop, or the last life lost) and GameOver $E35D (also the way out after the ending) print
; GAME OVER, play tune 6, wait for a press and go back to the menu.
; --------------------------------------------------------------------------------------------------------------------

; The menu: title, control methods, credits; choose a method and start
;
; Waits until no key is pressed (`$A123` gives Z while fire or a key is down),
; plays tune 5 (`$A016`), clears the screen (`$AB03`) and prints three texts
; with `$AAE9`: ControlsText $EA1B at `$40EA`, TitleText $E9FB at `$4041`,
; CreditsText $EA51 at `$5047`.
;
; Then, every two frames, it lights the attribute row of the chosen method (DE
; the attribute address, C its width: `$58EE`/8, `$592E`/8, `$596E`/6,
; `$59AE`/8 for methods 0-3) by `$AB18` with the colour table `$AB3D`, and
; reads keys 1-4. A new method is stored in `$A14C` and its old row is put back
; with `$AB45`. Fire (`$A123` Z) leaves through MenuWaitRelease into NewGame
; $E2DC.
;
; Seen in c1, controls (all four methods), gameover, level1 and ending; the
; menu screen is work/images/menu.*.bin. The `LD DE,$780A` at `$E229` is dead:
; the next instruction loads DE again.
;
; Witness: L1 30069 (c1, controls, ending, ending2, gameover, level1).
Menu:
  CALL StartPressed
  JR Z,Menu
  LD A,$05
  CALL StartTune
  CALL ClearScreen
  LD HL,ControlsText
  LD DE,$780A             ; dead load: DE is set again at once
  LD DE,$40EA
  CALL PrintLines
  LD HL,TitleText
  LD DE,$4041
  CALL PrintLines
  LD HL,CreditsText
  LD DE,$5047
  CALL PrintLines
MenuLoop:
  LD DE,$58EE             ; DE, C = the attribute row and width of the chosen
                          ; method
  LD C,$08
  LD A,(ControlMethod)
  AND A
  JR Z,MenuShowRow
  LD DE,$592E
  LD C,$08
  CP $01
  JR Z,MenuShowRow
  LD DE,$596E
  LD C,$06
  CP $02
  JR Z,MenuShowRow
  LD DE,$59AE
  LD C,$08
MenuShowRow:
  LD A,C
MenuFrame:
  HALT                    ; two frames a pass
  HALT
  LD HL,CycleColours
  PUSH DE
  PUSH BC
  CALL CycleAttributes
  POP HL
  POP DE
  CALL Key1Pressed
  JR NZ,MenuTryKey2
  LD A,(ControlMethod)
  AND A
  JR Z,MenuTryKey2
  XOR A
  LD (ControlMethod),A
  LD A,L
  LD HL,PlainColours
  CALL CycleAttributes
MenuTryKey2:
  CALL Key2Pressed        ; 2: Kempston
  JR NZ,MenuTryKey3
  LD A,(ControlMethod)
  CP $01
  JR Z,MenuTryKey3
  LD A,$01
  LD (ControlMethod),A
  LD A,L
  LD HL,PlainColours
  CALL CycleAttributes
MenuTryKey3:
  CALL Key3Pressed        ; 3: cursor keys
  JR NZ,MenuTryKey4
  LD A,(ControlMethod)
  CP $02
  JR Z,MenuTryKey4
  LD A,$02
  LD (ControlMethod),A
  LD A,L
  LD HL,PlainColours
  CALL CycleAttributes
MenuTryKey4:
  CALL Key4Pressed        ; 4: Sinclair
  JR NZ,MenuTestFire
  LD A,(ControlMethod)
  CP $03
  JR Z,MenuTestFire
  LD A,$03
  LD (ControlMethod),A
  LD A,L
  LD HL,PlainColours
  CALL CycleAttributes
MenuTestFire:
  CALL StartPressed
  JP NZ,MenuLoop
MenuWaitRelease:
  CALL StartPressed
  JR Z,MenuWaitRelease

; New game: reset the game state, print the first level's intro
;
; Clears the screen, then bit 7 (done) of `$016D` records of 5 bytes from
; `$D7FD` (the level object lists: a taken or killed one-shot object stays
; gone), Level $E4AD, GameComplete $E440 and the score `$A9BE-$A9C3`. Lives
; `$A958`, bullets `$A976` and dynamite `$A967` = 6. `$A93D` draws the HUD.
;
; LevelIntro prints LevelTable's first text (SouthAmericaText $E4E5) at its
; screen address with `$AAE9`, C = `$47`, sets `$7900` to the record's
; attribute, plays tune 0 and waits until fire is let go; StartLevel $E32C
; follows.
;
; Run once per new game: c1 1, controls 4, gameover 1, level1 2 (the natural
; GAME OVER starts a new game).
;
; Witness: L1 9 (beeper48, c1, controls, gameover, level1).
NewGame:
  CALL ClearScreen
  LD HL,Objects+$0001
  LD BC,$016D
  LD DE,$0005
ClearDoneLoop:
  RES 7,(HL)
  ADD HL,DE
  DEC BC
  LD A,B
  OR C
  JR NZ,ClearDoneLoop
  XOR A
  LD (Level),A
  LD (GameComplete),A
  LD A,$06
  LD (Lives),A
  LD HL,$0000
  LD (Score),HL
  LD (Score+$0002),HL
  LD (Score+$0004),HL
  LD (Bullets),A
  LD (Dynamite),A
  CALL DrawHud
LevelIntro:
  LD HL,(LevelTextPtr)    ; LevelTable record 0: text, place, attribute
  LD DE,(LevelTextAt)
  LD C,$47
  CALL PrintLines
  LD A,(LevelAttr)
  LD (CharAttr0),A
  XOR A
  CALL StartTune
IntroWaitRelease:
  CALL StartPressed
  JR Z,IntroWaitRelease

  ORG $E35A

; Quit: Q in the main loop, or the last life lost
;
; Reached from MainLoop $E3C9 when `$A13C` gives Z (the Q key), from CheckDeath
; when the lives reach 0, and from StartLevel with no lives. Calls `$A73F`,
; then GAME OVER.
;
; Seen in c1 (Q), controls (Q after each method), gameover and level1 (six
; deaths).
;
; Witness: L1 8 (beeper48, c1, controls, gameover, level1).
Quit:
  CALL ComposeObjects

; GAME OVER: print it, tune 6, wait for a key, back to the menu
;
; Calls `$A90F` and `$A25D`, prints GameOverBlankText $E397, GameOverText $E3A3
; and GameOverBlankText again with `$AA8D` at `$484B`, `$486B`, `$488B`
; (attributes `$49`, `$4F`, `$49`), plays tune 6, waits until no key is down
; and then for a press, and jumps to Menu $E219.
;
; Also the end of the game: CheckGameComplete $E406 jumps here after the ending
; (the ending recording shows GAME OVER after the closing text).
;
; Witness: L1 10 (beeper48, c1, controls, ending, ending2, gameover, level1).
GameOver:
  CALL UpdateHud
  CALL DrawDirtyCells
  LD DE,$484B
  LD HL,GameOverBlankText
  LD C,$49
  CALL PrintText
  LD DE,$486B
  LD HL,GameOverText
  LD C,$4F
  CALL PrintText
  LD DE,$488B
  LD HL,GameOverBlankText
  LD C,$49
  CALL PrintText
  LD A,$06
  CALL StartTune
GameOverWaitRelease:
  CALL StartPressed
  JR Z,GameOverWaitRelease
GameOverWaitPress:
  CALL StartPressed
  JP Z,Menu
  JP GameOverWaitPress

; 11 spaces, ended by $FF: the band above and below GAME OVER
GameOverBlankText:
  INCBIN "res/texts/GameOverBlankText.bin",$0000,12

; " GAME OVER ", ended by $FF
GameOverText:
  INCBIN "res/texts/GameOverText.bin",$0000,12
