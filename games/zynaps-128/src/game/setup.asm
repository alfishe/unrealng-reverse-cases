; --------------------------------------------------------------------------------------------------------------------
; setup.asm: block 2's set-up: the game moved, the 128K glue and hooks, the options, the start
;
; The loader jumps to $6000 after block 2's unpack and a key. The set-up moves the 48K game ($9800 bytes, LDDR from
; its end) to $6800-$FFFF, over itself. On a 128K (Is128 = 1) it installs the glue and its patches, copies the shared
; hook stub and the 15 hooks to $B30D on, writing each hook's address into its call site as it goes, writes the
; musician's name, sends the menu's loop back through $B200, and silences four OUT ($FE)s. On any machine it then
; applies the options: INF.LIVES makes the lives count's DEC an OR; K-MOUSE copies the mouse driver to $FE00 and
; patches four places with the bytes of MousePatches. Then JP GameStart.
; --------------------------------------------------------------------------------------------------------------------

; the game moved up, the 128K layer (when Is128), the options, JP GameStart
;
; The copies of the hooks run as one stream: HL walks the image from
; HooksImage, DE the destination from HookSound, each LDIR leaving DE on the
; next hook's address, which is written into its site before the next LDIR.
; Four sites lost a 3-byte instruction instead of a CALL's operand: their first
; byte is made $CD (CALL) first. The 15 mouse patch bytes are likewise one
; stream from MousePatches after the driver.
SetUp:
  LD HL,GameImage+GAME_LENGTH-1; the game: $6385-$FB84 to $6800-$FFFF
                                    ; (from the end: the two overlap)
  LD DE,GameTop
  LD BC,GAME_LENGTH
  LDDR
  LD A,(Is128)            ; 48K: only the options
  OR A
  JP Z,SetOptions
  LD HL,GlueImage         ; the glue to $5B00 and its patches
  LD DE,GlueRun
  LD BC,$00E3
  LDIR
  CALL GlueInstall
  LD HL,HooksImage        ; the shared hook stub HookSound ($22 bytes), then
                          ; each hook: its address to its site, LDIR on
  LD DE,HookSound
  LD BC,$0022
  LDIR
  LD (SiteShot+1),DE      ; HookShot (5 bytes) at the player's shot
  LD C,$05
  LDIR
  LD (SiteExtraLife+1),DE ; HookExtraLife (8)
  LD C,$08
  LDIR
  LD (SiteBombBounce+1),DE; HookBombBounce (8)
  LD C,$08
  LDIR
  LD (SiteHonour+1),DE    ; HookHonour (8)
  LD C,$08
  LDIR
  LD (SiteHonourResult+1),DE; HookHonourResult (8)
  LD C,$08
  LDIR
  LD A,$CD                ; HookShipLost (8): the site's LD ($8072),A becomes
                          ; CALL HookShipLost
  LD (SiteShipLost),A
  LD (SiteShipLost+1),DE
  LD C,$08
  LDIR
  LD (SiteHomingLaunch+1),DE; HookHomingLaunch (8)
  LD C,$08
  LDIR
  LD (SitePodTaken+1),DE  ; HookPodTaken (8)
  LD C,$08
  LDIR
  LD (SiteSpecialLaunch),A ; HookSpecialLaunch (8): the site's LD HL,$F36F
                           ; becomes a CALL (A is still $CD)
  LD (SiteSpecialLaunch+1),DE
  LD C,$08
  LDIR
  LD (SiteEnemyMissile+1),DE; HookEnemyMissile (5)
  LD C,$05
  LDIR
  LD (SiteWeaponSelect+1),DE; HookWeaponSelect (8)
  LD C,$08
  LDIR
  LD (SitePodAppears+1),DE; HookPodAppears (5)
  LD C,$05
  LDIR
  LD (SiteExplosion),A    ; HookExplosion (9): the site's LD HL,$D6ED becomes a
                          ; CALL
  LD (SiteExplosion+1),DE
  LD C,$09
  LDIR
  LD (SiteSelections),A   ; HookSelections (13): the site's LD HL,$82E0 becomes
                          ; a CALL
  LD (SiteSelections+1),DE
  LD C,$0D
  LDIR
  LD (SiteScreenWipe1+1),DE; HookScreenWipe (13), for both wipe sites
  LD (SiteScreenWipe2+1),DE
  LD C,$0D
  LDIR
  LD HL,MusicianName      ; "DAVE ROGERS " over "STEVE TURNER": the CPC
                          ; version's musician
  LD DE,CreditName
  LD C,$0C
  LDIR
  LD A,$E4                ; JR $B203 made JR $B200: after a game the menu loop
                          ; passes the main loop's CALL at $B200 again, which
                          ; the glue turned into MusicOn
  LD (MenuLoopJump+1),A
  LD HL,$0000             ; four OUT ($FE),A made NOP: NOP: the beeper's and
                          ; the effects' border clicks
  LD (BeeperOut1),HL
  LD (BeeperOut2),HL
  LD (BeeperOut3),HL
  LD (BeeperOut4),HL
SetOptions:
  LD A,(InfLives)            ; INF.LIVES: DEC (IX+4) ($35) made OR (IX+4) ($B6):
                          ; the lives never drop
  OR A
  JR Z,SetMouse
  LD A,$B6
  LD (LoseLife+1),A
SetMouse:
  LD A,(KMouse)            ; K-MOUSE: the driver to $FE00, then its four patches
  OR A
  JR Z,StartGame
  LD HL,MouseImage
  LD DE,MouseReset
  LD BC,$00DD
  LDIR
  LD DE,StickRead         ; CALL MouseRead: NOP over the stick read
  LD C,$04
  LDIR
  LD DE,StartTest         ; LD A,$FA: IN A,($DF): AND 2 over the start test:
                          ; the left button (bit 1, active low) starts play in
                          ; mouse mode
  LD C,$06
  LDIR
  LD DE,Im2Fill+1         ; the IM 2 table fill from $FEE8, past the driver
  LD C,$02
  LDIR
  LD DE,LifeStartCall     ; CALL MouseReset at a life's start
  LD C,$03
  LDIR
StartGame:
  JP GameStart            ; the game's own start

; the hook stubs, copied to HookSound (156 bytes; src/game/stubs.asm)
HooksImage:
  INCBIN "obj/stubs-b30d.bin",$0000,156

; the credit's new name, copied over CreditName
MusicianName:
  DEFM "DAVE ROGERS "

; the 128K glue, copied to GlueRun (227 bytes; src/game/glue.asm)
GlueImage:
  INCBIN "obj/glue-5b00.bin",$0000,227

; the Kempston mouse driver, copied to MouseReset (221 bytes;
; src/game/mouse.asm)
MouseImage:
  INCBIN "obj/mouse-fe00.bin",$0000,221

; the K-MOUSE patches' bytes, copied after the driver to StickRead, StartTest,
; Im2Fill + 1, LifeStartCall
;
; CALL $FE1D: NOP (MouseRead, 4 bytes); LD A,$FA: IN A,($DF): AND 2 (6 bytes);
; $FEE8 (2 bytes, the fill's start); CALL $FE00 (MouseReset, 3 bytes).
MousePatches:
  DEFB $CD,$1D,$FE,$00    ; CALL MouseRead: NOP
  DEFB $3E,$FA,$DB,$DF,$E6,$02 ; LD A,$FA: IN A,($DF): AND 2
  DEFB $E8,$FE            ; $FEE8
  DEFB $CD,$00,$FE        ; CALL MouseReset

; the 48K game as it runs at $6800-$FFFF, with the 2 in 1's Pentagon timing and
; default keys (docs/03 3.6)
GameImage:
  INCBIN "../res/game/game-6800.bin",$0000,38912
