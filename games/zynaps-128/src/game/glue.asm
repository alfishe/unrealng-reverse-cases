; --------------------------------------------------------------------------------------------------------------------
; glue.asm: the 128K glue: the engine each frame, the music on and off, the patches
;
; GlueInstall, called once by block 2's set-up on a 128K, writes the patches; the rest is what they reach. Each frame
; the game's interrupt handler now calls FramePlay through one of four small entries, which each do the instructions
; their patch overwrote: the engine plays one frame from page 4. The music is started after each screen clear the game
; does at its menus (ClearThenMusic, MusicOn) and when the pause routine ends (Key4MusicOn), and stopped at a level's
; start (LevelStartSound, which also plays an effect) and when key 4 is pressed (Key4MusicOff). The 48K beeper is cut
; off at its three routines.
; --------------------------------------------------------------------------------------------------------------------

; page 4 in, one frame of the engine (EnginePlay), page 0 back; DI, every
; register but HL kept
;
; Called from the game's interrupt handler through PlayAtA9E5, PlayAtA581,
; PlayAtA9F7 and PlayAtAB03. Leaves interrupts off (the handler enables them
; itself). AF, DE, BC, IX, IY kept; the engine may change HL.
FramePlay:
  DI
  PUSH AF                 ; AF, DE, BC, IX, IY kept
  PUSH DE
  PUSH BC
  PUSH IX
  PUSH IY
  LD A,PAGE4              ; page 4: the engine
  LD BC,PORT_7FFD
  OUT (C),A
  CALL EnginePlay
  LD A,PAGE0              ; page 0: the game
  LD BC,PORT_7FFD
  OUT (C),A
  POP IY
  POP IX
  POP BC
  POP DE
  POP AF
  RET

; the handler at $A9E4 (the menu's): a frame of the engine, then the LD
; HL,IntFlag it lost
;
; Reached by CALL PlayAtA9E5 at IntMenuSite, which held LD HL,IntFlag (3
; bytes).
PlayAtA9E5:
  CALL FramePlay
  LD HL,IntFlag
  RET

; the handler tail at $A581: a frame of the engine, its POP BC: POP DE: POP HL,
; back to its POP AF
;
; Reached by JP PlayAtA581 at IntTailSite.
PlayAtA581:
  CALL FramePlay
  POP BC
  POP DE
  POP HL
  JP IntTailRest

; the main handler's work: DI, its PUSH IX: PUSH IY, a frame of the engine, on
; at IntPlayRest
;
; Reached by JP PlayAtA9F7 (and a NOP) at IntPlaySite.
PlayAtA9F7:
  DI
  PUSH IX
  PUSH IY
  CALL FramePlay
  JP IntPlayRest

; the main handler's other path ($AA00 jumps to $AB03): a frame of the engine,
; its POP IY: POP IX, on at IntEndRest
;
; Reached by JP PlayAtAB03 (and a NOP) at IntEndSite. The work from $A9FB
; always ends here (it runs to $AB03 or jumps there from $AA00), so the main
; handler (entered at $A9ED) steps the engine twice an interrupt: in c1 $A9ED
; ran 3221 times and PlayAtA9F7 and PlayAtAB03 3220 times each, while
; PlayAtA9E5 (2550) and PlayAtA581 (1403) step it once. Whether the in-play
; music and effects run at twice the menu's rate, or the in-play handler comes
; every second frame, is stage 3's (docs/09-sound.md).
PlayAtAB03:
  CALL FramePlay
  POP IY
  POP IX
  JP IntEndRest

; CALL ClearScreen, then MusicOn
;
; Replaces CALL ClearScreen at ClearSite1, ClearSite2 and ClearSite3 (the
; menu's and the game over's screen clears).
ClearThenMusic:
  CALL ClearScreen
; This entry point is used by the routine at Key4MusicOn.
MusicOn:
  LD HL,MusicOn           ; the main loop's CALL $AFB0 (at $B200) becomes CALL
                          ; MusicOn; A = $5B (not 0): the music on
  LD (MainLoopCall),HL
  LD A,H

; A = 0: the music stopped; else stopped and started again from its beginning
;
; Input: A. Pages 4 in, calls EngineMusicOff, then EngineMusicOn when A is not
; 0 (A is kept in the operand of the LD A at MusicFlag, self-modifying: page
; 4's paging needs A), pages 0 back and enables interrupts. Used by the stubs
; too (HookSelections, HookScreenWipe: A = 0).
MusicSwitch:
  DI
  LD (MusicFlag+$0001),A
  LD A,PAGE4              ; page 4
  LD BC,PORT_7FFD
  OUT (C),A
  CALL EngineMusicOff
MusicFlag:
  LD A,$00                ; LD A,the switch (the operand written above)
  OR A
  CALL NZ,EngineMusicOn
  LD A,PAGE0              ; page 0
  LD BC,PORT_7FFD
  OUT (C),A
  EI
  RET

; a level's start: the music off, the engine's effect $C9A5, then LevelSetUp
;
; Replaces CALL LevelSetUp at LevelSite (in $B023). Pushes LevelSetUp's address
; and calls HookSound with L = $A5: HookSound's last POP HL takes this
; routine's return address and its RET goes to LevelSetUp, whose RET returns to
; $B023's caller's place after the CALL: the effect starts, then LevelSetUp
; runs as before (HL is LevelSetUp's own).
LevelStartSound:
  XOR A
  CALL MusicSwitch
  LD HL,LevelSetUp             ; LevelSetUp, under HookSound's return address
  PUSH HL
  LD L,$A5
  CALL HookSound
  RET

; key 4 in play: the music off, then the game's routine Key4Routine
;
; Replaces the operand of CALL Z,Key4Routine at Key4Site. Key4Routine ends at
; Key4End, patched to Key4MusicOn.
Key4MusicOff:
  XOR A
  CALL MusicSwitch
  JP Key4Routine

; the end of Key4Routine: its LD (PauseState),A, then MusicOn
;
; Reached by JP Key4MusicOn at Key4End; MusicOn's RET (MusicSwitch's) returns
; from Key4Routine.
Key4MusicOn:
  LD (PauseState),A
  JR MusicOn

; the patches of the 48K game for the 128K (called once by block 2's set-up)
;
; In order: CALL PlayAtA9E5 at IntMenuSite; JP PlayAtA581 at IntTailSite; JP
; Key4MusicOn at Key4End; JP PlayAtA9F7 at IntPlaySite and JP PlayAtAB03 at
; IntEndSite, each followed by a NOP; BeeperTone's DI made a NOP; CALL
; ClearThenMusic at ClearSite3, ClearSite2, ClearSite1; CALL LevelStartSound at
; LevelSite; CALL Z,Key4MusicOff at Key4Site; RET at BeeperPlay and
; BeeperSound. The music is not started here: the first screen clear starts it.
GlueInstall:
  LD A,$CD
  LD (IntMenuSite),A
  LD HL,PlayAtA9E5
  LD (IntMenuSite+1),HL
  LD A,$C3                ; JP: the handler tail, the pause's end, the main
                          ; handler's two places
  LD (IntTailSite),A
  LD HL,PlayAtA581
  LD (IntTailSite+1),HL
  LD (Key4End),A
  LD HL,Key4MusicOn
  LD (Key4End+1),HL
  LD (IntPlaySite),A
  LD (IntEndSite),A
  LD HL,PlayAtA9F7
  LD (IntPlaySite+1),HL
  LD HL,PlayAtAB03
  LD (IntEndSite+1),HL
  XOR A                   ; NOPs after the two JPs, the beeper tone's DI off
  LD (IntPlaySite+3),A
  LD (IntEndSite+3),A
  LD (BeeperTone),A
  LD HL,ClearThenMusic    ; the screen clears call ClearThenMusic
  LD (ClearSite3),HL
  LD (ClearSite2),HL
  LD (ClearSite1),HL
  LD HL,LevelStartSound   ; the level's start, key 4
  LD (LevelSite),HL
  LD HL,Key4MusicOff
  LD (Key4Site),HL
  LD A,$C9                ; the beeper's player and sound start: RET
  LD (BeeperPlay),A
  LD (BeeperSound),A
  RET
