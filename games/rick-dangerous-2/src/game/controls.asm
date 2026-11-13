; --------------------------------------------------------------------------------------------------------------------
; controls.asm: The controls: the keyboard, Kempston, cursor and Sinclair joysticks, pause, quit and the cheat keys
;
; ReadControls $7254 runs in every interrupt (the IM 2 handler $FEFE calls it) and leaves the controls of the chosen
; method ControlMethod $7252 in Controls $7253, active low: bit 0 right, 1 left, 2 down, 3 up, 4 fire. The keyboard is
; Z left, X right, O up, K down, SPACE or ENTER fire; the cursor keys 5-8 and 0, Kempston port $1F and Sinclair 6-0
; are the other methods.
;
; The main loop polls the other keys directly: E quits ($724A), P pauses ($7242), C+S+3 together toggle the infinite
; lives ($71C0), SPACE+N+ENTER+J+Y together set a section cheat once the game has been completed ($71DC). The menus
; test 0-5 ($71F9-$7221) and wait on any fire key ($7229).
; --------------------------------------------------------------------------------------------------------------------

  ORG $71C0

; Z when C, S and 3 are held together (and no other key of their half rows)
;
; Reads the half rows $FEFE (C alone: AND $1F = $17), $FDFE (S alone: $1D) and
; $F7FE (3 alone: $1B); returns NZ at the first that does not match, Z when all
; three do. The main loop $7D33 then plays tune 1 and toggles $8066 (XOR $FF),
; the flag the life loss $8A26 tests before it takes a life (and $9593, $95ED,
; $96B4, $9B27 read): an infinite-lives cheat.
;
; Only the first half row ran: $71CA-$71DB (the S and 3 tests) ran in no
; recording, and the static walk takes them for data (every byte of the block
; is read once in the fast L1), so they are written as DEFB: LD B,$FD / IN
; A,(C) / AND $1F / CP $1D / RET NZ / LD B,$F7 / IN A,(C) / AND $1F / CP $1B /
; RET.
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
TestInfiniteLivesKeys:
  LD BC,$FEFE
  IN A,(C)
  AND $1F
  CP $17
  RET NZ
TestInfiniteLivesRest:
  LD B,$FD                ; LD B,$FD; IN A,(C); AND $1F; CP $1D (S); RET NZ; LD
                          ; B,$F7; IN A,(C); AND $1F; CP $1B (3); RET
  IN A,(C)
  AND $1F
  CP $1D
  RET NZ
  LD B,$F7
  IN A,(C)
  AND $1F
  CP $1B
  RET

; Z when SPACE+N, ENTER+J and Y are held together
;
; Reads $7FFE (SPACE and N: AND $1F = $16), $BFFE (ENTER and J: $16) and $DFFE
; (Y: $0F); NZ at the first mismatch. The main loop $7D49: when $8065 is set
; (the four levels completed in one game, which opens level 5) it plays tune 1
; and sets $8067 = $FF, whose bit 7 the section test $8993 reads ($89D9): a
; cheat that only works after the game is finished.
;
; $71E6-$71F8 (the ENTER+J and Y tests) ran in no recording and are DEFB (as
; $71CA): LD BC,$BFFE / IN A,(C) / AND $1F / CP $16 / RET NZ / LD B,$DF / IN
; A,(C) / AND $1F / CP $0F / RET.
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
TestSectionCheatKeys:
  LD BC,$7FFE
  IN A,(C)
  AND $1F
  CP $16
  RET NZ
TestSectionCheatRest:
  LD BC,$BFFE             ; LD BC,$BFFE; IN A,(C); AND $1F; CP $16 (ENTER+J);
                          ; RET NZ; LD B,$DF; IN A,(C); AND $1F; CP $0F (Y);
                          ; RET
  IN A,(C)
  AND $1F
  CP $16
  RET NZ
  LD B,$DF
  IN A,(C)
  AND $1F
  CP $0F
  RET

; Z when 0 is held
;
; One of six menu key tests, all called by the menu reader $8087 ($71F9-$7219
; every pass of the menus, $7221 only when level 5 is open): IN from the half
; row, BIT n, RET; Z = held.
;
; Witness: L1 198492 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TestKey0:
  LD BC,$EFFE
  IN A,(C)
  BIT 0,A
  RET

; Z when 1 is held
;
; Half row $F7FE bit 0. Called by $808D.
;
; Witness: L1 146738 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TestKey1:
  LD BC,$F7FE
  IN A,(C)
  BIT 0,A
  RET

; Z when 2 is held
;
; Half row $F7FE bit 1. Called by $8093.
;
; Witness: L1 146328 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TestKey2:
  LD BC,$F7FE
  IN A,(C)
  BIT 1,A
  RET

; Z when 3 is held
;
; Half row $F7FE bit 2. Called by $8099.
;
; Witness: L1 146274 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TestKey3:
  LD BC,$F7FE
  IN A,(C)
  BIT 2,A
  RET

; Z when 4 is held
;
; Half row $F7FE bit 3. Called by $809F.
;
; Witness: L1 146216 (controls-cursor, controls-kempston, controls-keyboard,
; controls-sinclair, end-congrats, rzx-l1-00000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-full, sec-l1-s8, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TestKey4:
  LD BC,$F7FE
  IN A,(C)
  BIT 3,A
  RET

; Z when 5 is held (the level menu's level 5)
;
; Half row $F7FE bit 4. Called by $80AC after $80A5 has found $8065 set (level
; 5 open): it ran only in load-l5 (its POKE of $8065) and the RZX level 5
; recordings.
;
; Witness: L1 46269 (rzx-l5-23000, rzx-l5-24000-poke, rzx-l5-full, load-l5,
; sec-l5-s3, sec-l5-s5).
TestKey5:
  LD BC,$F7FE
  IN A,(C)
  BIT 4,A
  RET

; Z when ENTER, SPACE or the chosen method's fire is held
;
; ENTER ($BFFE bit 0) and SPACE ($7FFE bit 0) return Z at once; otherwise it
; calls ReadControls $7254 and tests bit 4 (fire) of Controls $7253. Used to
; wait for a key: the tape loader's message $8433 (over a million runs in
; load-l2 ... load-l5), the GAME OVER wait $7EA0 and the end text $8787.
;
; Witness: L1 1270451 (controls-keyboard, end-congrats, rzx-l2-00000-poke,
; rzx-l3-00000-poke, rzx-l4-00000-poke, rzx-l5-00000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, c1, c48, load-l2-load-l5,
; sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5, sec-l3-s7-sec-l3-s9,
; sec-l4-s x5, sec-l5-s3, sec-l5-s5).
TestFireKeys:
  LD BC,$BFFE
  IN A,(C)
  BIT 0,A
  RET Z
  LD BC,$7FFE
  IN A,(C)
  BIT 0,A
  RET Z
  CALL ReadControls
  LD A,(Controls)
  BIT 4,A
  RET

; Z when P is held
;
; $DFFE bit 0. The main loop $7D5D: P held waits for its release, then for a
; second press and its release (the pause); c1 and controls-keyboard press P
; (95 582 and 129 946 runs: the waiting loops).
;
; Witness: L1 573892 (cheats, controls-cursor, controls-kempston,
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
TestPauseKey:
  LD BC,$DFFE
  IN A,(C)
  BIT 0,A
  RET

; Z when E is held
;
; $FBFE bit 2. The main loop $7D2D jumps to the game's end $7E1E on Z (c1
; presses E at its end).
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
TestQuitKey:
  LD BC,$FBFE
  IN A,(C)
  BIT 2,A
  RET

; The control method: 0 keyboard, 1 Kempston, 2 cursor, 3 Sinclair
;
; Written by the control menu ($80B5, $8127), read by ReadControls $7254 /
; $725A. controls-keyboard, -kempston, -cursor and -sinclair each play with one
; value.
ControlMethod:
  DEFB $00

; The controls read in the last interrupt, active low: bit 0 right, 1 left, 2
; down, 3 up, 4 fire
;
; Written by ReadControls $7254 (set to $FF, then a bit cleared per control
; held); read by TestFireKeys $7229 and Rick's movement and weapons ($945E,
; $95ED, $9663, $96B4, $985F, $988F, $9AB7, $9B27).
Controls:
  DEFB $00

; Read the chosen control method into Controls
;
; Called by the IM 2 handler ($FF11) every interrupt and by TestFireKeys $7229.
; Sets Controls $7253 to $FF, then per ControlMethod $7252: 0 the keyboard (O
; up, else K down; Z left, else X right; ENTER and SPACE fire), 1 Kempston (IN
; ($1F) AND $1F, complemented: the joystick's bits are already right 0, left 1,
; down 2, up 3, fire 4), 2 the cursor keys (0 fire, 8 right, 7 up, else 6 down,
; 5 left unless right), 3 Sinclair (0 fire, 6 left, else 7 right, 9 up, else 8
; down). Keeps HL; changes A, BC, F.
;
; The recordings: 1 211 807 runs in 68 builds; Kempston $72B1 in
; controls-kempston (1255), cursor $72BE in controls-cursor and every RZX piece
; (the RZX run used CAPS SHIFT + 5-8, read here without the shift), Sinclair
; $72FA in controls-sinclair (1255) and c1 (85, its menu tour). ENTER as fire
; ($72A1) was never pressed.
;
; Witness: L1 1595354 (cheats, controls-cursor, controls-kempston,
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
; rzx-l5-18000-poke, rzx-l5-20000-poke, rzx-l5-22000-poke, rzx-l5-23000,
; rzx-l5-24000-poke, rzx-l5-26000-poke, rzx-l5-full, sec-l1-s8, c1, c48,
; load-l2-load-l5, sec-l2-s7, sec-l2-s10-sec-l2-s12, sec-l3-s3-sec-l3-s5,
; sec-l3-s7-sec-l3-s9, sec-l4-s x5, sec-l5-s3, sec-l5-s5).
ReadControls:
  PUSH HL
  LD HL,Controls
  LD (HL),$FF

; ReadControlsMethod
ReadControlsMethod:
  LD A,(ControlMethod)    ; A = ControlMethod: 0 the keyboard here, else
                          ; ReadKempston
  AND A
  JP NZ,ReadKempston
  LD BC,$DFFE
  IN A,(C)
  BIT 1,A
  JP NZ,ReadKeyDown
  RES 3,(HL)
  JP ReadKeyLeft
ReadKeyDown:
  LD BC,$BFFE             ; O not held: K = down
  IN A,(C)
  BIT 2,A
  JP NZ,ReadKeyLeft
  RES 2,(HL)
ReadKeyLeft:
  LD BC,$FEFE             ; Z = left
  IN A,(C)
  BIT 1,A
  JP NZ,ReadKeyRight
  RES 1,(HL)
  JP ReadKeyFire
ReadKeyRight:
  LD BC,$FEFE             ; Z not held: X = right
  IN A,(C)
  BIT 2,A
  JP NZ,ReadKeyFire
  RES 0,(HL)
ReadKeyFire:
  LD BC,$BFFE             ; ENTER = fire
  IN A,(C)
  BIT 0,A
  JP NZ,ReadKeySpace
ReadKeyEnterFire:
  RES 4,(HL)              ; RES 4,(HL): ENTER held (DEFB: no recording pressed
                          ; ENTER in play)
ReadKeySpace:
  LD BC,$7FFE             ; SPACE = fire
  IN A,(C)
  BIT 0,A
  JP NZ,ReadControlsDone
  RES 4,(HL)
ReadControlsDone:
  POP HL
  RET

; ReadKempston
;
; Used by the routine at ReadControlsMethod.
ReadKempston:
  CP $01                  ; method 1: Kempston, port $1F
  JP NZ,ReadCursor
  IN A,($1F)
  AND $1F
  CPL
  LD (HL),A
  POP HL
  RET
ReadCursor:
  CP $02                  ; method 2: the cursor keys, half row $EFFE (0 9 8 7
                          ; 6)
  JP NZ,ReadSinclair
  LD BC,$EFFE
  IN A,(C)
  BIT 0,A
  JP NZ,ReadCursorRight
  RES 4,(HL)
ReadCursorRight:
  BIT 2,A                 ; 8 = right
  JP NZ,ReadCursorUp
  RES 0,(HL)

; ReadCursorUp
;
; Used by the routine at ReadKempston.
ReadCursorUp:
  BIT 3,A                 ; 7 = up
  JP NZ,ReadCursorDown
  RES 3,(HL)
  JP ReadCursorLeft
ReadCursorDown:
  BIT 4,A                 ; 6 = down
  JP NZ,ReadCursorLeft
  RES 2,(HL)

; ReadCursorLeft
;
; Used by the routine at ReadCursorUp.
ReadCursorLeft:
  BIT 0,(HL)              ; 5 = left, only when right is not held
  JP Z,ReadCursorDone
  LD BC,$F7FE

; ReadCursorLeftKey
ReadCursorLeftKey:
  IN A,(C)
  BIT 4,A
  JP NZ,ReadCursorDone
  RES 1,(HL)

; ReadCursorDone
;
; Used by the routines at ReadCursorLeft and ReadCursorLeftKey.
ReadCursorDone:
  POP HL
  RET
; This entry point is used by the routine at ReadKempston.
ReadSinclair:
  LD BC,$EFFE             ; method 3: Sinclair joystick 1, half row $EFFE
  IN A,(C)
  BIT 0,A
  JP NZ,ReadSinclairLeft
  RES 4,(HL)
ReadSinclairLeft:
  BIT 4,A                 ; 6 = left
  JP NZ,ReadSinclairRight
  RES 1,(HL)
  JP ReadSinclairUp
ReadSinclairRight:
  BIT 3,A                 ; 7 = right
  JP NZ,ReadSinclairUp
  RES 0,(HL)
ReadSinclairUp:
  BIT 1,A                 ; 9 = up
  JP NZ,ReadSinclairDown
  RES 3,(HL)
  POP HL
  RET
ReadSinclairDown:
  BIT 2,A                 ; 8 = down
  JP NZ,ReadSinclairDone
  RES 2,(HL)
ReadSinclairDone:
  POP HL
  RET
