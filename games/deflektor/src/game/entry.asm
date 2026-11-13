; --------------------------------------------------------------------------------------------------------------------
; entry.asm: The entry, the title loop, a new game
;
; The game is entered at GameEntry $8382 (the mover at $FD00 jumps there with SP = $FFFF): Start sets up IM 2 ($A2FA)
; and falls into TitleLoop, the loop every game ends in: the hall-of-fame check of the last score ($9BC0), the title
; and the options panel ($A729), then NewGame (three lives, level 1, or the practice level P1 when the options panel's
; 6 set PracticeFlag) and LevelPanel, which draws the bottom panel afresh and falls into the level set-up $843C.
;
; LevelSettings $8385 is the per-level table the set-up reads: the energy bar's rate and the number of gremlins, two
; bytes for each of the 64 level slots.
; --------------------------------------------------------------------------------------------------------------------

  ORG $8382

; The game's entry: JP Start
;
; The mover of the last loader stage jumps here after moving the game to
; `$6000-$DFFF` (SP = `$FFFF`). One `JP` over the per-level table LevelSettings
; to Start `$8408`.
;
; Run once a load (`c1` and its game window `c1g`; the first instruction of
; `c1g`).
;
; Witness: L1 2 (c1, c1g).
GameEntry:
  JP Start

; The energy rate and the gremlin count of each level: 2 bytes for each of the
; 64 level slots
;
; Read by SetUpLevel `$843C` (at `$84CD`): slot `Level` x 2. Byte 0 goes to
; `$A63C`, the operand of the `CP $64` at `$A63B` in the energy routine
; `$A613`: the energy bar loses one pixel each time the interrupt's tick
; `$A506` reaches it, so it is the number of frames per pixel (70-140 in levels
; 1-60, 255 in the practice slots). Byte 1 goes to `$AB95`, the number of
; gremlin records `$AB63` the gremlin code walks (`$9AB6`, `$ABAD`): 0-5 in
; levels 1-59, 8 in level 60, 0 / 8 / 0 / 0 in the four practice slots.
;
; Levels 1-60 are slots 0-59; slots 60-62 are the practice levels P1-P3
; (PracticeFlag); slot 63 is never set up (LevelCompletePause `$887D` returns
; to the title when the level number reaches 63). Each row of the listing is
; eight levels.
LevelSettings:
  DEFB $5A,$00,$6E,$00,$5A,$02,$64,$02,$46,$02,$50,$02,$6E,$02,$5A,$02 ; levels 1-8
  DEFB $5A,$04,$46,$03,$5A,$02,$46,$02,$5A,$02,$82,$02,$55,$03,$46,$02 ; levels
                                                                       ; 9-16
  DEFB $64,$02,$6E,$02,$82,$02,$5A,$03,$82,$00,$64,$03,$82,$03,$6E,$03 ; levels
                                                                       ; 17-24
  DEFB $55,$02,$82,$00,$87,$04,$82,$01,$8C,$02,$5A,$02,$50,$03,$78,$03 ; levels
                                                                       ; 25-32
  DEFB $5A,$04,$88,$02,$64,$02,$78,$03,$82,$02,$64,$02,$82,$02,$5A,$03 ; levels
                                                                       ; 33-40
  DEFB $64,$03,$82,$02,$6E,$03,$78,$03,$64,$02,$6E,$03,$78,$03,$78,$03 ; levels
                                                                       ; 41-48
  DEFB $6E,$03,$5A,$03,$87,$00,$5A,$08,$78,$04,$78,$03,$64,$03,$8C,$00 ; levels
                                                                       ; 49-56
  DEFB $82,$02,$8C,$04,$82,$05,$5A,$08,$FF,$00,$FF,$08,$FF,$00,$FF,$00 ; levels
                                                                       ; 57-60,
                                                                       ; practice
                                                                       ; P1-P3, the
                                                                       ; unused
                                                                       ; slot 63
  DEFB $01,$00            ; unused: no code or recording reads them

; $FF in practice mode (the options panel's 6), else 0
;
; Cleared by TitleLoop `$840C`, set by the options panel (`$A7E5`, key 6). Read
; by NewGame (`$841E`: the start slot 60, P1), SetUpLevel (`$84DA`: the score
; cleared each level), LoseLife (`$86A0`: no life is taken), DrawMarkedChars
; (`$8A68`: the PRACTICE MODE line), `$9BCA`, `$A6E9` and `$A7E5`.
;
; No recording plays practice: the `menu` recording's key 6 did not take (its
; screen 7750 shows LEVEL 01, and NewGame's `$8424` ran in no build), so the
; practice path is known only from the code.
PracticeFlag:
  DEFB $00

; Interrupts off, IM 2 on (the jump at $FDFD and the vector table), then into
; TitleLoop
;
; `DI`, then `$A2FA` (the IM 2 set-up: `JP $A32A` at `$FDFD`, the table
; `$FE00-$FF00`, I = `$FE`). Falls into TitleLoop; interrupts stay off until
; LevelPanel's `EI` (`$843B`).
;
; Run once a load (`c1`, `c1g`).
;
; Witness: L1 2 (c1, c1g).
Start:
  DI
  CALL SetupInterrupts

; Demo and practice off, the hall-of-fame check, the title and options panel,
; then a new game
;
; The place every game ends: GameOver (`$8711`), the demo's last level
; (`$856E`), the end of practice (`$887F`), the ending (`$88AD`) and the abort
; keys (`$982C`) jump here.
;
; Clears the demo flag `$8379` and PracticeFlag; `$9BC0` (the score `$9B3E`
; against the hall of fame, the name entry); `$A729` (the title, the options
; panel; it returns when a game is to start, with `$8379` set by key 5 DEMO or
; PracticeFlag by key 6). Falls into NewGame.
;
; Witness: L1 14 (c1, c1g, controls, energy-out, gameover, hof, kempston, menu,
; mine, overload, rzx344752).
TitleLoop:
  XOR A
  LD (DemoFlag),A
  LD (PracticeFlag),A
  CALL HallOfFame         ; the hall-of-fame check of the last game's score
  CALL TitleScreen        ; the title and the options panel

; Three lives, the first level (or practice slot 60), the saved score cleared,
; then LevelPanel
;
; Lives `$837D` = 3; Level `$81FF` = 0, or `$3C` (P1) when PracticeFlag is set;
; two Delays (about 24 frames); `$9B30` clears the score saved at the level's
; start (`$9B44`, five spaces), so SetUpLevel starts the game's score at 0.
; Falls into LevelPanel.
;
; An entry of its own: the `energy` and `kempston` recordings start from a
; snapshot taken inside `$A729`, so their L1s mark a routine root here.
;
; Witness: L1 10 (c1, c1g, controls, energy, energy-out, kempston, menu).
NewGame:
  LD A,$03
  LD (Lives),A
  LD A,(PracticeFlag)
  AND A
  JR Z,NewGameLevel
  LD A,$3C
NewGameLevel:
  LD (Level),A            ; Level = 0, or $3C for practice
  CALL Delay              ; two Delays

; l_842C
l_842C:
  CALL Delay
  CALL ClearSavedScore    ; the saved score cleared: the game starts at 0

; Draw the bottom panel afresh, blank the COMPUTER line, interrupts on; into
; SetUpLevel
;
; From NewGame and LevelCompletePause (`$8882`, after a level's bonus). `$A50C`
; copies the panel's picture `$7B80` (four character rows, the LEVEL, LIVES,
; OVERLOAD, ENERGY, SCORE, HIGH and COMPUTER fields, three full life bars) to
; the screen's rows 20-23 with its attributes; MessageText `$A10E` = `$A199` (a
; blank line of three spaces that loops); `EI`. Falls into SetUpLevel.
;
; Witness: L1 90 (c1, c1g, controls, energy, energy-out, hof, kempston, menu, L
; x20, rzx x59).
LevelPanel:
  CALL DrawPanel
  LD HL,BlankMessage
  LD (MessageText),HL
  EI
