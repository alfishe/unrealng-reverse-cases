; --------------------------------------------------------------------------------------------------------------------
; setup.asm: The start code, the entry, the start of play, a new game and a new life
;
; The game is entered at GameEntry $5CFA (the bootstrap's JP on both machines): the control menu, the 48K intro, then
; the page tails: ten 126-byte rows of PageTailTemplate ($6B5C) go to +$82..+$FF of the pages $5D00-$6600 (the actor
; kind templates, the size classes, the touch zones and some run-time code), then the tables OutlineMask $6F00,
; RowBase $7000 and NameBoxPlaces $700C, and the room cells are cleared. From then on GameEntry's own bytes ($5D00 on)
; are Hiro's actor page.
;
; NewGame $5C4D is the title loop and the start of every game: the title and high-score table ($A73E), the cheat name
; check (a high-score name SLOPPY lets keys 1-4 choose the start room), the 128K intro hook, the globals from
; GlobalsInit, Hiro's actor, the first room, then the main loop $8DFE. GameOver $5C42 and EndOfGame $5C45 lead back to
; it.
; --------------------------------------------------------------------------------------------------------------------

; The globals' start values: 56 bytes copied to Vitality $6642 at a new game
;
; NewGame `$5CA9` copies these 56 bytes (LDIR, BC = `$38`) to `$6642-$6679`;
; the first 10 (7 when a boss kind is set, `$9A59`) are copied again when a
; life is lost (LoseEnergy `$9615`).
;
; Each shown copy (`$6643`, `$6646`, `$664A`, `$664F`) starts unequal to its
; value, so the first pass of the panel jobs ($FF01, $FF64) draws everything.
; The byte `$5C06` (FirePrevious) is written by ControlMenu `$6A9E` with the
; chosen fire mask.
;
; Two text records follow (for `$837B`): the score line (Y, X, two style bytes,
; eight digits "00000000", a skip of 7 cells, the lives "05", end) and the
; status line at Y `$B8` X `$12` (style `$FF` `$FF`: "EXTRA", glyph `$85`, the
; weapon icon `$5B` `$5C`, glyph `$86`, "BONUS", end); glyphs `$85`/`$86` are
; the weapon bar (`$7F0D`).
GlobalsInit:
  INCBIN "res/tables/start-values.bin",$0000,21

; The rest of GlobalsInit: the score line and the status line, two text records
; for $837B (to ScoreLine $6657, StatusLine $6667)
;
; Copied with GlobalsInit by NewGame; the panel draws them at run time from
; `$6657` and `$6667` (texts/panel.txt).
ScoreLineInit:
  INCBIN "res/texts/panel.bin",$0000,16
StatusLineInit:
  INCBIN "res/texts/panel.bin",$0010,19

; The attribute of an unlit EXTRA / BONUS letter ($42), five times
;
; Read by the letter check `$999F-$99CE`: when the five EXTRA letters
; (attributes `$5AE9`) match ExtraBonusLit they are reset from here and a life
; is added (message 1); the BONUS letters (`$5AF2`) give message 2 and a score
; bonus.
ExtraBonusUnlit:
  INCBIN "res/graphics/letter-attrs.bin",$0000,5

; The attribute of a lit EXTRA / BONUS letter ($47), five times
;
; The compare string for the letter check `$999F`.
ExtraBonusLit:
  INCBIN "res/graphics/letter-attrs.bin",$0005,5

; The game is lost: the GAME OVER banner, then the high-score entry and the
; title
;
; From LoseEnergy `$9651` (`JP M` when the lives run out). CALL `$831A`:
; ShowMessage `$66C8` with A = 4 (GAME OVER) and a wait of up to 40 x 5 frames
; or fire. Falls into EndOfGame.
;
; Witness: L1 6 (gameover, hiscore, rzx x4). Ran once in gameover.
GameOver:
  CALL ShowGameOverWait
; This entry point is used by the routine at MainLoopActors.
EndOfGame:
  LD A,$FF                ; from $8E12 too (EndFlags bit 7, after Havok): tune
                          ; $FF, the high-score entry $A806
  CALL SetTune
  CALL InsertHighScore

; The title loop and a new game: title, cheat, globals, Hiro, the first room,
; the main loop
;
; 1. SetTune `$5FC0` with A = `$80` (the title tune); the title sequence and
; high-score table `$A73E` returns when fire is pressed.
;
; 2. The cheat: MatchCheatName `$5C68` compares each of the ten high-score
; names (`$8126`, 21-byte records) with "SLOPPY    " (`$8214`). On a match the
; keys 1-4 (`$F7FE`) held then pick the start: 1 = row `$06` column `$0D`, 2 =
; `$09`/`$12`, 3 = `$0F`/`$0E`, 4 = `$0F`/`$14`; else (and without the name)
; row 0 column 3 (room 4). The pair goes to MapRow `$69DF` / MapColumn `$69E0`.
;
; 3. `$5C9A`: three NOPs on a 48K; on a 128K the bootstrap writes `CALL $85C5`
; here (the 128K intro with music, bank 4 `$D3D0`).
;
; 4. Clears `$6D00-$6EFF` (HavokStashB, TakenItems, RevealedZones, HavokStashA,
; GoneEnemies), copies GlobalsInit to `$6642`, sets the six bytes `$76D8` to 1.
;
; 5. SpawnActor `$A65D` for Hiro (page `$5D00`, kind `$24`, template `$65CA`,
; BC = `$4804`); Hiro +`$02` = 7; `$88AE` = 0; CLS (`$8339`); tune command 2
; (`$8452`).
;
; 6. The first room: IY = Hiro, `$95C3` (the map lookup and build), `$8365`
; (the score line), PanelAttrs `$FFEB` (Z in room 4: the attributes `$46`, else
; 7, through `$835A`), then the tick on (`$845F` = 0) and `JP $8DFE`, the main
; loop.
;
; Witness: L1 20 (deaths, gameover, havok, hiscore, menu, throw, c x2, opt x3,
; rzx x2, rzxroom x1).
NewGame:
  LD A,$80
  CALL SetTune
  CALL TitleSequence
TitleFired:
  LD HL,HiScoreEntries+$0009 ; the ten high-score names: is one of them SLOPPY?
  LD BC,$0A0A
NewGameNameLoop:
  PUSH BC
  CALL MatchCheatName
  ADD HL,BC
  LD C,$0B
  ADD HL,BC
  POP BC
  DJNZ NewGameNameLoop
  JR NewGameStart         ; no name matched: the normal start

; Compare 10 bytes at HL with the cheat name $8214 ("SLOPPY    "); on a match
; choose the start room by the keys 1-4
;
; HL = a high-score name. DE runs from `$8213` (pre-incremented), BC = 10 with
; CPI: a byte that differs returns NZ (BC as left). After ten equal bytes it
; does not return: it reads `$F7FE` (keys 1-5) and jumps into NewGame at
; `$5C96` with the start pair (C = row, B = column), so the rest of the name
; loop's stack (BC) is left behind; NewGame never returns, so the extra word
; does not matter.
;
; Witness: L1 150 (deaths, gameover, havok, hiscore, menu, play48, throw, c x1,
; opt x3, rzx x1, rzxroom x1). The key branch is known only from the code (no
; keyed recording has SLOPPY in the table).
MatchCheatName:
  LD DE,CopyrightText+$0023
  LD B,$00
MatchCheatNameLoop:
  INC DE
  LD A,(DE)
  CPI
  RET NZ
  XOR A
  OR C
  JR NZ,MatchCheatNameLoop
  LD BC,$F7FE             ; a match: the key held picks the start
  IN A,(C)
  RRA
  LD BC,$0D06
  JR NC,NewGameSetStart
  RRA
  LD BC,$1209
  JR NC,NewGameSetStart
  RRA
  LD BC,$0E0F
  JR NC,NewGameSetStart
  RRA
  LD BC,$140F
  JR NC,NewGameSetStart
; This entry point is used by the routine at NewGame.
NewGameStart:
  LD BC,$0300             ; row 0, column 3: room 4
NewGameSetStart:
  LD (MapRow),BC          ; MapRow, MapColumn
  NOP                     ; the 128K hook: CALL $85C5 (the 128K intro) is
                          ; written over these three NOPs
  NOP
  NOP
  LD HL,HavokStashB       ; clear $6D00-$6EFF
  LD (HL),L
  LD DE,HavokStashB+$0001
  LD BC,$01FF
  LDIR
  LD HL,GlobalsInit       ; the globals from GlobalsInit
  LD DE,Vitality
  LD BC,$0038
  LDIR
  LD HL,GateClosed        ; six flags $76D8 = 1
  LD B,$06
NewGameFlagsLoop:
  LD (HL),$01
  INC HL
  DJNZ NewGameFlagsLoop
  LD HL,Hiro              ; Hiro: SpawnActor $A65D, kind $24, template $65CA
  LD BC,Screen+2052
  LD DE,HiroTemplate
  LD A,$24
  CALL InitActor
  LD A,$07
  LD (Hiro+$0002),A
  XOR A
  LD (DrawCellLayers+$0012),A
  CALL ClearScreen
  LD A,$02
  LD (TuneRequest),A
  LD IY,Hiro              ; the first room
  CALL EnterRoom
  CALL PrintScore
  CALL PanelAttrsRoom
  LD A,$46
  JR Z,NewGameColour
  LD A,$07
NewGameColour:
  CALL FillPlayAttributes ; the play window's attributes: $46 in room 4, else 7
  XOR A                   ; the tick on, the main loop
  LD (InterruptHandler+$0009),A
  JP MainLoop

; The game's entry: the control menu, the intro, the page tails and tables,
; then NewGame
;
; Jumped to by the bootstrap (`JP Z,$5CFA` at `$4054` on a 48K, `JP $5CFA` at
; `$4092` on a 128K). ControlMenu `$6A7B`; then GameEntryIntro `$5CFD`.
;
; Witness: L1 2 (c x2).
GameEntry:
  CALL ControlMenu

; CALL Intro48 (the 128K bootstrap writes three NOPs over it), then build the
; page tails
;
; `CALL $5D4F` (Intro48); a 128K bootstrap overwrites these three bytes with
; `00 00 00` (its intro runs in NewGame instead). Then A = 10 rows, HL =
; PageTailTemplate `$6B5C`, D = `$5D` and BuildPageTails `$5D07`.
;
; An entry of its own: the address is a routine entry of the tape loader's
; BASIC code in the recordings.
;
; Witness: L1 11 (deaths, gameover, hiscore, menu, throw, c x2, opt x3, rzx
; x1).
GameEntryIntro:
  CALL Intro48
Hiro:
  LD A,$0A                ; Hiro's actor page (+$00-$41), over GameEntry's code
                          ; once the game runs
  LD HL,PageTailTemplate
  LD D,$5D

; Ten rows of 126 bytes from the template to +$82..+$FF of the pages $5D-$66,
; then the tables
;
; Each pass: BC = `$7E`, E = `$82`, LDIR (which leaves D one higher, the next
; page). Then:
;
; - OutlineMask `$6F00`: for a = 0..255, NOT (a OR a<<1 OR a>>1) (the pixels
; next to none of a's), the mask for drawing a sprite's dark outline (`$8C0A`,
; `$8C0F`, `$8CAD`, `$A4D1`);
;
; - RowBase `$7000`: 0, 20 ... 220, the first cell of each of the 12 rows
; (`$8EB5`, `$8F75`);
;
; - NameBoxPlaces `$700C`: 5 rows x 6 words (E = `$34` + `$10` row, D = `$12` +
; 4 column), the screen places of the name entry's letter boxes;
;
; - ClearRoomCells `$70EF` with C = `$DC`, B = `$24`: the cells `$DC-$FF` of
; the six planes (the spare cells and the row above) are cleared; `JP $5C4D`
; (NewGame).
;
; An entry of its own: `$5D07` is also the BASIC line's code (the tape loader),
; so the recordings mark a routine entry here.
;
; Witness: L1 122 (deaths, gameover, hiscore, menu, throw, c x2, opt x3, rzx
; x1, rzxroom x1).
BuildPageTails:
  LD BC,$007E
  LD E,$82
  LDIR
  DEC A
  JR NZ,BuildPageTails
  LD HL,OutlineMask       ; OutlineMask $6F00
BuildOutlineMaskLoop:
  PUSH AF
  LD E,A
  RL E
  OR E
  LD E,A
  RR E
  OR E
  CPL
  LD (HL),A
  INC HL
  POP AF
  INC A
  JR NZ,BuildOutlineMaskLoop
  LD B,$0C                ; RowBase $7000: 12 rows of 20 cells
BuildRowBaseLoop:
  LD (HL),A
  INC L
  ADD A,$14
  DJNZ BuildRowBaseLoop
  LD C,$05                ; NameBoxPlaces $700C: 5 rows of 6
  LD DE,$0E34
BuildBoxRowLoop:
  LD B,$06
  PUSH DE
BuildBoxPlaceLoop:
  LD A,$04
  ADD A,D
  LD D,A
  LD (HL),E
  INC L
  LD (HL),D
  INC L
  DJNZ BuildBoxPlaceLoop
  POP DE
  LD A,$10
  ADD A,E
  LD E,A
  DEC C
  JR NZ,BuildBoxRowLoop
  LD BC,$24DC             ; clear the room cells $DC-$FF of the six planes
  CALL ClearRoomCells
  JP NewGame
