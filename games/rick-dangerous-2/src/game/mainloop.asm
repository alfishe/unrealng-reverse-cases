; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The new game, the level start, the main loop and GAME OVER
;
; The flow after the entry: NewGame shows the control menu, ChooseLevel the level menu, StartGame clears the object
; tables, resets the sections' objects and the score, LevelStart reads the level from tape when the one in memory is
; another, sets the lives, ammunition and detonators and Rick's start, and falls into MainLoop.
;
; A pass of MainLoop: the quit key E (GAME OVER), two cheat key chords, the pause P, Rick and the objects updated
; ($8B42, UpdateObjects), the sprites composed (DrawSprites), the frame wait for 2 counts ($7A53, C = 2), the cells
; redrawn ($76D4), the section exit and the level's end, the scroll up or down, the death and the lives. A level's end
; moves to the next level or to an ending; the last life ends in GAME OVER and the control menu again.
; --------------------------------------------------------------------------------------------------------------------

  ORG $7C7D

; A new game: the control menu, then the level menu
;
; Shows the control menu (ControlMenu) and returns when 0 (START GAME) is
; pressed; falls into ChooseLevel. Reached from CopyMusic once after the load
; and from GAME OVER ($7EB0) after every game.
;
; Evidence: c1 1, controls-keyboard 1, rzx-l5-full 2 (the start and the two
; GAME OVERs of the RZX level 5 run).
;
; Witness: L1 42 (controls-keyboard, rzx-l5-full, c1, c48, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
NewGame:
  CALL ControlMenu

; The level menu
;
; LevelMenu: the level chosen goes to Level ($7EF1). Falls into StartGame.
;
; Evidence: 11 runs in 10 builds (c1, the four controls-*, the four load-*,
; rzx-l5-full 2).
;
; Witness: L1 54 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ChooseLevel:
  CALL LevelMenu

; Clear the object tables, reset the sections' objects, start the game
;
; ClearObjectTables, ResetSectionObjects (bit 7 of every object record of every
; section cleared), then ResetGame, which runs the levels to GAME OVER and
; never returns.
;
; Evidence: 12 runs in 11 builds.
;
; Witness: L1 56 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
StartGame:
  CALL ClearObjectTables
  CALL ResetSectionObjects
  CALL ResetGame

; JP NewGame after ResetGame
;
; JP $7C7D, back to the control menu: ResetGame never returns (GAME OVER jumps
; to NewGame itself), so this is not executed in any recording; the static walk
; takes it as the code after StartGame's CALL.
;
; Witness: L1 0 ().
RestartJump:
  JP NewGame

; Rick's start in each level: section, row, x, y, a flag (6 bytes a level)
;
; LevelSetup takes the record of Level ($7EF1): IX = $7C8F + 6 x (level - 1).
; +0 the start section (A to the section setup $8A6D), +1 the view's top row in
; it ($88CF), +2 Rick's x (E: $9BAC, $9B8C), +3/+4 Rick's y, a word (HL: $9BAD,
; $9B8D), +5 a byte for $9BB1 (Rick's record +6: bit 7 the mirror; 0 in every
; level). Level 3 starts in section 1 with the view at row $90, level 5 at row
; $60, the others in section 0 at row 0; y is $CB in levels 1, 2, 4 and $AB in
; 3 and 5.
;
; Evidence: read by LevelSetup in every level start (reads $7C8F-$7CAC over the
; builds).
LevelStarts:
  INCBIN "res/tables/level-starts.bin",$0000,30

; A new game's state: score 0, levels done 0, six lives; then the levels
;
; Score ($7F1D-$7F22) = 0, LevelsDone ($7EF2) = 0, $8A24 = 0 (the level 5 code
; hooks off), lives ($8B3B) = 6. Falls into LevelStart and the main loop; never
; returns (GAME OVER goes to NewGame).
;
; Evidence: 12 runs in 11 builds, called from StartGame ($7C89).
;
; Witness: L1 56 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ResetGame:
  LD HL,$0000
  LD (Score),HL
  LD (Score+$0002),HL
  LD (Score+$0004),HL
  XOR A
  LD (LevelsDone),A
  LD (LevelHookOn),A
  LD A,$06
  LD (Lives),A

; Start the level in Level: from tape when another is in memory
;
; When Level ($7EF1) differs from LevelNumber ($C20C, the level in memory):
; tune 4 ($7AAD), $9BEB, LoadLevel (the tape messages and side B until the
; wanted level's block is in), then DecryptLevel. Reached from ResetGame and
; from MainLoop after a level's end ($7DD0).
;
; Evidence: 14 runs in 13 builds; the tape branch in the load-l2 ... load-l5
; recordings and rzx-l3-10000-poke, rzx-l4-20000-poke (the RZX run's own
; loader, a TAP version at $846A).
;
; Witness: L1 60 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l3-10000-poke, rzx-l4-20000-poke,
; rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
LevelStart:
  LD A,(Level)
  LD C,A
  LD A,(LevelNumber)
  CP C
  JP Z,LevelTune
  LD A,$04
  CALL StartTune
  CALL FreeAllObjects
  CALL LoadLevel

; Decrypt the new level's last 768 bytes of maps
;
; CALL $894E (the maps' cipher). Then LevelTune.
;
; Evidence: 9 runs in 9 builds (load-l2 ... load-l5,
; rzx-l2/l3/l4/l5-00000-poke, rzx-l5-full).
;
; Witness: L1 48 (rzx-l2-00000-poke, rzx-l3-00000-poke, rzx-l4-00000-poke,
; rzx-l5-00000-poke, rzx-l5-full, load-l2-load-l5, sec-l2-s7,
; sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5,
; sec-l5-s3, sec-l5-s5).
DecryptLevel:
  CALL DecryptMaps

; The level's tune; a life back when fewer than six
;
; Tune Level + 4 ($7AAD: 5 to 9). When lives ($8B3B) are not 6, AddLife adds
; one.
;
; Evidence: 17 runs in 15 builds; lives were 6 at every level start of the
; recordings (c1 starts a game, the RZX pieces have the infinite lives POKE),
; so AddLife is not executed in any recording.
;
; Witness: L1 100 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l2-00000-poke, rzx-l3-00000-poke,
; rzx-l4-00000-poke, rzx-l5-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
LevelTune:
  LD A,(Level)
  ADD A,$04
  CALL StartTune
  LD A,(Lives)
  CP $06
  JP Z,LevelSetup

; INC A / LD ($8B3B),A: one life more at a level start
;
; The code bytes INC A / LD ($8B3B),A: lives + 1 when they are below 6. Not
; executed in any recording (every level start had six lives); a level start
; with five lives or fewer would run it.
;
; Witness: L1 0 ().
AddLife:
  INC A
  LD (Lives),A

; Ammunition and detonators 6, Rick's start record, the first section
;
; Ammunition ($8B3C) and detonators ($8B3D) = 6, $945D, $9B99, $9B98 = 0. IX =
; LevelStarts + 6 x (Level - 1): $9BB1 = +5; A = +0 the section, C = +1 the top
; row, E = +2 x, HL = +3/+4 y, then the section setup $8A6D. Falls into
; MainLoop.
;
; Evidence: 17 runs in 15 builds.
;
; Witness: L1 100 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, rzx-l1-00000-poke, rzx-l2-00000-poke, rzx-l3-00000-poke,
; rzx-l4-00000-poke, rzx-l5-00000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
LevelSetup:
  LD A,$06
  LD (Ammunition),A
  LD (Detonators),A
  XOR A
  LD (RideMode),A
  LD (RickClimbing),A
  LD (RickCrawling),A
  LD A,(Level)
  DEC A
  ADD A,A
  LD C,A
  ADD A,A
  ADD A,C
  LD C,A
  LD B,$00
  LD IX,LevelStarts
  ADD IX,BC
  LD A,(IX+$05)
  LD (RickFacing),A
  LD A,(IX+$00)
  LD C,(IX+$01)
  LD E,(IX+$02)
  LD L,(IX+$03)
  LD H,(IX+$04)
  CALL SetupSection

; The main loop: quit, cheats, pause, the pass's work, the frame wait, scroll,
; death
;
; The quit key E ($724A, Z when pressed) goes to GameOver. $71C0 is Z when C, S
; and 3 are held together: CheatInfiniteKeys toggles CheatInfinite ($8066).
; Then MainLoopCheatB.
;
; Evidence: 50 163 runs in 65 builds (c1 1114, controls-keyboard 465, ...). E
; in c1 and controls-keyboard went to GAME OVER. The chord C+S+3: cheats (stage
; 2).
;
; Witness: L1 119172 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
MainLoop:
  CALL TestQuitKey
  JP Z,GameOver
  CALL TestInfiniteLivesKeys
  JP NZ,MainLoopCheatB

; C+S+3: toggle CheatInfinite
;
; The code bytes LD A,1 / CALL $7AAD (tune 1, the signal) / LD A,($8066) / XOR
; $FF / LD ($8066),A. CheatInfinite then stops the loss of lives ($8A26),
; ammunition ($9593) and detonators ($9B27, the reads of $8066).
;
; Evidence: cheats (stage 2: C, S and 3 held at frame 50 on the RZX run's level
; 5) 3 runs: the chord held 10 frames toggles three times in its first passes.
;
; Witness: L1 6 (cheats).
CheatInfiniteKeys:
  LD A,$01                ; LD A,1 / CALL $7AAD: tune 1
  CALL StartTune
  LD A,(CheatInfinite)    ; LD A,($8066) / XOR $FF / LD ($8066),A:
                          ; CheatInfinite toggled
  XOR $FF
  LD (CheatInfinite),A

; The second cheat chord: SPACE, N, ENTER, J and Y
;
; $71DC is Z when SPACE, N, ENTER, J and Y are held together; then
; CheatExitsKeys. Then MainLoopPause.
;
; Evidence: 50 161 runs in 65 builds; the chord: cheats (stage 2).
;
; Witness: L1 119134 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
MainLoopCheatB:
  CALL TestSectionCheatKeys
  JP NZ,MainLoopPause

; The chord with level 5 open: CheatExits on
;
; The code bytes LD A,($8065) / AND A / JP Z,$7D5D / LD A,1 / CALL $7AAD / LD
; A,$FF / LD ($8067),A: only when Level5Open is set, tune 1 and CheatExits
; ($8067) = $FF. The section exit test $8993 reads CheatExits (bit 7) before it
; tests bit 4 of an exit's kind ($89D9): which exits it opens is for the run.
; Not executed in any recording.
;
; Evidence: cheats (stage 2: SPACE, N, ENTER, J and Y held at frame 200,
; Level5Open set by the RZX run) 3 runs; long-l4 (POKE CheatExits = $FF on the
; RZX run's level 4 end) shows what it opens: LongLevelsTest sends the
; level-ending exit $82 of level 4 section 7 on to section 10.
;
; Witness: L1 6 (cheats).
CheatExitsKeys:
  LD A,(Level5Open)       ; LD A,($8065) / AND A / JP Z,$7D5D: only with level
                          ; 5 open
  AND A
  JP Z,MainLoopPause
  LD A,$01                ; LD A,1 / CALL $7AAD: tune 1
  CALL StartTune
  LD A,$FF                ; LD A,$FF / LD ($8067),A: CheatExits on
  LD (CheatExits),A

; The pause, the pass's work, the frame wait, the level's end, scroll, death;
; GAME OVER
;
; P ($7242, Z when pressed): wait for its release, a press and a release (the
; game stands still, the interrupt goes on with the music and the controls).
; Then the pass: $8B42 (Rick from the controls), ExitDirection ($88D3) = 0,
; UpdateObjects, DrawSprites; on a 48K ($7A76 not 0) CALL $7B66; the frame wait
; $7A53 with C = 2 (the pass takes at least two frames); the cells redrawn
; ($76D4).
;
; The level's end: when a routine set ExitDirection, the section exit test
; $8993; its result negative (M) is the level's end. LevelsDone ($7EF2) + 1;
; when it was 3 (the fourth level done in this game), Level5Open ($8065) = $FF.
; LevelsDone = 5 goes to BonusTally (the Fat Guy's end); Level 5 ended
; otherwise goes to Congratulations; level 4 goes to Congratulations unless
; Level5Open is set, then to level 5; levels 1-3 to the next. Then LevelStart.
;
; The scroll: unless $9B9C is set, Rick's y ($9BAD) below $60 with the view not
; at the top ($88CF) scrolls up ($7905); y at $CC or more with the top row
; below ViewLastRow ($88D2) scrolls down ($78A5).
;
; The death: when $9B9B is set, the last life (lives = 1) is GAME OVER, else
; $8A26 (a life off, the section again).
;
; GameOver ($7E1E): tune 2, the cell drawer's JP M at $775A turned into NOPs,
; $8985, the view buffer $6D60-$6DDF cleared, a 12 x 3 box at column 10, rows
; 11-13 of the screen: attributes $47, pixels 0; "GAME  OVER" falls into place
; (DropText at row $A0, column 11) and is printed on the screen ($7F23 at
; $488B); wait 512 frames or fire, SPACE, ENTER ($7229); LevelCellsMode,
; NewGame.
;
; Evidence: the pass 50 161 runs in 65 builds. The pause in c1 (7476 runs of
; PauseWaitRelease) and controls-keyboard. The level's end: $7DA6 (level 5
; opened) once in rzx-l4-20000-poke, the next level ($7DCC) in
; rzx-l3-10000-poke and rzx-l4-20000-poke; BonusTally and Congratulations not
; from this code in any recording (the RZX run's ending, rzx-l5-23000, starts
; inside TallyLives). GameOver 4 runs: c1 1 and controls-keyboard 1 (the key
; E), rzx-l5-full 2 (the lives lost).
;
; Witness: L1 119134 (cheats, controls-cursor, controls-kempston,
; controls-keyboard, controls-sinclair, end-congrats, long-l4,
; rzx-l1-00000-poke, rzx-l1-02000-poke, rzx-l1-04000-poke, rzx-l1-06000-poke,
; rzx-l1-08000-poke, rzx-l1-10000-poke, rzx-l1-12000-poke, rzx-l1-14000-poke,
; rzx-l1-16000-poke, rzx-l1-18000-poke, rzx-l1-20000-poke, rzx-l1-22000-poke,
; rzx-l1-24000-poke, rzx-l2-00000-poke, rzx-l2-02000-poke, rzx-l2-04000-poke,
; rzx-l2-06000-poke, rzx-l2-08000-poke, rzx-l2-10000-poke, rzx-l2-12000-poke,
; rzx-l2-14000-poke, rzx-l2-16000-poke, rzx-l2-18000-poke, rzx-l2-20000-poke,
; rzx-l2-22000-poke, rzx-l2-24000-poke, rzx-l3-00000-poke, rzx-l3-02000-poke,
; rzx-l3-04000-poke, rzx-l3-06000-poke, rzx-l3-08000-poke, rzx-l3-10000-poke,
; rzx-l4-00000-poke, rzx-l4-02000-poke, rzx-l4-04000-poke, rzx-l4-06000-poke,
; rzx-l4-08000-poke, rzx-l4-10000-poke, rzx-l4-12000-poke, rzx-l4-14000-poke,
; rzx-l4-16000-poke, rzx-l4-18000-poke, rzx-l4-20000-poke, rzx-l5-00000-poke,
; rzx-l5-02000-poke, rzx-l5-04000-poke, rzx-l5-06000-poke, rzx-l5-08000-poke,
; rzx-l5-10000-poke, rzx-l5-12000-poke, rzx-l5-14000-poke, rzx-l5-16000-poke,
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-full,
; sec-l1-s8, c1, c48, load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12,
; sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
MainLoopPause:
  CALL TestPauseKey
  JP NZ,PassWork
PauseWaitRelease:
  CALL TestPauseKey       ; P still held
  JP Z,PauseWaitRelease
PauseWaitPress:
  CALL TestPauseKey       ; paused: wait for P
  JP NZ,PauseWaitPress
PauseWaitRelease2:
  CALL TestPauseKey       ; wait for P's release, then play on
  JP Z,PauseWaitRelease2
PassWork:
  CALL ScanMapObjects     ; the pass's work
  XOR A
  LD (ExitDirection),A    ; no exit asked yet in this pass
  CALL UpdateObjects
  CALL DrawSprites
  LD A,(Machine48K)       ; a 48K: CALL $7B66
  AND A
  CALL NZ,PlayBeeperStep
  LD C,$02                ; two frame counts a pass
  CALL WaitFrames
  CALL DrawChangedCells   ; the cells that changed redrawn
  LD A,(ExitDirection)
  AND A
  JP Z,ScrollTest
  CALL CheckSectionExit   ; the section exit test: M = the level's end
  JP P,ScrollTest
  LD A,(LevelsDone)
  CP $03
  JP NZ,CountLevelDone
  XOR A                   ; the fourth level done in this game: level 5 opens
  DEC A
  LD (Level5Open),A
  LD A,$03
CountLevelDone:
  INC A                   ; LevelsDone + 1; 5 is the Fat Guy's end
  LD (LevelsDone),A
  CP $05
  JP Z,BonusTally
  LD A,(Level)
  CP $05
  JP Z,Congratulations
  CP $04
  JP NZ,NextLevel
  LD A,(Level5Open)
  AND A
  JP Z,Congratulations
  LD A,$04
NextLevel:
  INC A                   ; Level + 1, the next level's start
  LD (Level),A
  JP LevelStart
ScrollTest:
  LD A,(RickDying)        ; scroll up when Rick is high in the view
  AND A
  JP NZ,DeathTest
  LD HL,(RickY)
  LD DE,-$60
  ADD HL,DE
  JP C,ScrollDownTest
  LD A,(ViewTopRow)
  AND A
  JP Z,DeathTest
  CALL ScrollUp
  JP DeathTest
ScrollDownTest:
  LD HL,(RickY)           ; scroll down when Rick is low in the view
  LD DE,-$CC
  ADD HL,DE
  JP NC,DeathTest
  LD A,(ViewLastRow)
  LD C,A
  LD A,(ViewTopRow)
  CP C
  JP NC,DeathTest
  CALL ScrollDown
DeathTest:
  LD A,(DeathFallOver)    ; Rick dead: GAME OVER on the last life, else a life
                          ; off
  AND A
  JP Z,MainLoop
  LD A,(Lives)
  CP $01
  JP Z,GameOver
  CALL LoseLife
  JP MainLoop
; This entry point is used by the routines at MainLoop and EndTextExit.
GameOver:
  LD A,$02                ; GAME OVER (the last life lost, or the key E)
  CALL StartTune
  LD HL,$0000             ; NOP NOP NOP over the JP M at $775A
  LD (ComposeCellFrontTest),HL
  LD (ComposeCellFrontTest+$0001),HL
  CALL ClearRedraw
  LD HL,ViewCells+608             ; 129 bytes of the view buffer from $6D60 cleared
                          ; (under the box)
  LD DE,ViewCells+609
  LD (HL),$00
  LD BC,$0080
  LDIR
  LD HL,ScreenAttrs+362
  LD DE,ScreenAttrs+363
  LD (HL),$47
  LD BC,$000B
  LDIR
  LD HL,ScreenAttrs+394
  LD DE,ScreenAttrs+395
  LD (HL),$47
  LD BC,$000B
  LDIR
  LD HL,ScreenAttrs+426
  LD DE,ScreenAttrs+427
  LD (HL),$47
  LD BC,$000B
  LDIR
  LD HL,Screen+2154             ; the box's pixels: 3 rows of 8 lines, 12 bytes
  LD C,$03
GameOverClearRow:
  LD B,$08                ; a character row of the box
GameOverClearLine:
  PUSH BC                 ; a pixel line of the box
  PUSH HL
  LD D,H
  LD E,L
  INC DE
  LD (HL),$00
  LD BC,$000B
  LDIR
  POP HL
  INC H
  POP BC
  DJNZ GameOverClearLine
  LD DE,$20-$800          ; back 8 lines, down a character row
  ADD HL,DE
  DEC C
  JP NZ,GameOverClearRow
  LD A,$FF                ; "GAME  OVER" falls into the view (A = $FF)
  LD HL,GameOverText
  LD DE,$A00B
  CALL DropText
  LD DE,Screen+2187             ; and is printed on the screen
  LD HL,GameOverText
  CALL PrintText
  LD BC,512
GameOverWait:
  PUSH BC                 ; 512 frames or fire
  LD C,$01
  CALL WaitFrames
  CALL TestFireKeys
  POP BC
  JP Z,GameOverDone
  DEC BC
  LD A,B
  OR C
  JP NZ,GameOverWait
GameOverDone:
  CALL LevelCellsMode     ; the level cells back, the control menu
  JP NewGame

  ORG $7EF1

; The level to play, 1-5
;
; Set by LevelMenu (the key pressed) and by MainLoopPause at a level's end
; (Level + 1, or 5). LevelStart compares it with LevelNumber ($C20C);
; LevelSetup indexes LevelStarts with it, ResetSectionObjects SectionCounts,
; Congratulations writes it into the text; read by $95ED, $96B4, $988F, $9B07
; too. 1 in the image.
Level:
  DEFB $01

; The levels completed in this game
;
; 0 at ResetGame; + 1 at each level's end (MainLoopPause $7DAD). Done with 3
; (the fourth level of the game) it opens level 5 (Level5Open); 5 (all five in
; one game, so starting from level 1) is the Fat Guy's end, BonusTally.
LevelsDone:
  DEFB $00
