; --------------------------------------------------------------------------------------------------------------------
; endings.asm: the end of a game: Dead End or Final Cut, the AY silenced
;
; CheckGameEnd runs once a game turn from GameTurn. When the enemy has no warbase left the game is won: GameWon copies
; the Final Cut block from bank 6 to $6060 and runs it. When we have none the game is lost: bank 3 is paged and its
; Dead End runs. Both silence the AY first (Silence), go back to IM 1 with I = $3F (the ROM's interrupt, the game's
; handlers no longer wanted) and never return; the machine is the ending's from then on.
;
; What follows them is the old end of a game that nothing reaches any more: GameOverWait (the beep, 100 frames, a key,
; Restart) and GameStop (the panel and the menu handler; its handler write misses ImHandler). The gaps between the
; routines are zero bytes and the last 9 bytes of an old text line.
; --------------------------------------------------------------------------------------------------------------------

; The end of the game: the enemy has no warbase (won) or we have none (lost)
;
; Called once a game turn by GameTurn. EnemyBuildings+0 = 0 (no enemy warbase):
; GameWon. Else PlayerBuildings+0 not 0: back to the turn. Else the game is
; lost: Silence, I = $3F, IM 1, EI, bank 3 ($13) and JP DeadEnd ($D2EF in bank
; 3). The lost path takes the CALL first only to empty the AY; nothing comes
; back.
CheckGameEnd:
  LD A,(EnemyBuildings)            ; the enemy's warbases
  OR A
  JR Z,GameWon            ; none left: won
  LD A,(PlayerBuildings)            ; ours
  OR A
  RET NZ                  ; we still have one: play on
  CALL Silence            ; lost: the tune off
  LD A,$3F                ; the ROM's I and IM 1: no game handler from here on
  LD I,A
  IM 1
  EI
  LD A,$13                ; bank 3: Dead End
  LD BC,$7FFD
  OUT (C),A
  JP DeadEnd              ; Dead End's entry, never back

; 10 bytes, never used
EndingsSpare1:
  DEFS $0A

; The AY's registers 0-14 to zero: no tone, no noise, volume 0 on all three
; channels
;
; Waits for one interrupt first (HALT), so the music handler has played its
; last frame, then turns interrupts off for good: the endings set their own. A
; counts the registers; each is selected at $FFFD and written 0 at $BFFD.
Silence:
  XOR A
  HALT                    ; the last frame of the tune
  DI                      ; no more handlers
SilenceRegister:
  LD BC,$FFFD             ; select register A
  OUT (C),A
  PUSH AF
  XOR A                   ; write 0 to it
  LD B,$BF
  OUT (C),A
  POP AF
  INC A                   ; the next register, up to 14
  CP $0F
  JR NZ,SilenceRegister
  RET

; 8 bytes, never used
EndingsSpare2:
  DEFS $08

; The enemy has no warbase left: the Final Cut block from bank 6 to $6060, and
; run
;
; Silence, I = $3F, IM 1, EI, bank 6 ($16), $3637 bytes from FinalCutBlock
; ($C000 in bank 6) copied to FinalCut ($6060, over the view buffer, the
; sprites and the code past it), bank 0 again and JP FinalCut: the block
; unpacks and plays the ending and never returns.
GameWon:
  CALL Silence            ; the tune off
  LD A,$3F                ; the ROM's I and IM 1
  LD I,A
  IM 1
  EI
  LD A,$16                ; bank 6: the Final Cut block
  LD BC,$7FFD
  OUT (C),A
  LD HL,FinalCutBlock     ; from bank 6's start
  LD DE,FinalCut
  LD BC,$3637             ; the block's bytes
  LDIR                    ; copied over the game itself
  LD A,$10                ; bank 0 at $C000 again
  LD BC,$7FFD
  OUT (C),A
  JP FinalCut             ; the Final Cut block's start

; 10 bytes, never used
EndingsSpare3:
  DEFS $0A

; The last 9 bytes of an old end-of-game text line: 8 spaces and its 0, never
; read
OldEndText:
  DEFB $20,$20,$20,$21,$20,$20,$20,$20
  DEFB $00

; Code nothing reaches: the old end of a game, a beep, a pause, a key, Restart
;
; Both ends of a game leave the game now, so no path comes here. The code: the
; beep with A = $FA, 100 frames of HALT, WaitRelease, then WaitKey until a
; control is held and JP Restart.
GameOverWait:
  LD A,$FA
  CALL Beep
  LD B,$64
GameOverPause:
  HALT                    ; 100 frames of HALT before the key is read
  DJNZ GameOverPause
  CALL WaitRelease
GameOverKey:
  CALL WaitKey            ; wait for a key, then back to Restart
  OR A
  JR Z,GameOverKey
  JP Restart

; Code nothing calls: give the panel back to the status, the menu handler
;
; PanelBusy = 0, ClearPanel, ShowStatusPanel, then LD HL,MusicInterrupt and LD
; ($6D6A),HL: a typo for ImHandler ($696A). Run, it would write the handler's
; address into the sprites ($6D6A) and leave the interrupt as it was. No CALL
; GameStop is left in the game.
GameStop:
  XOR A
  LD (PanelBusy),A
  CALL ClearPanel
  CALL ShowStatusPanel
  LD HL,MusicInterrupt
  LD ($6D6A),HL           ; meant for ImHandler: $6D6A is a byte of the sprites
  RET
