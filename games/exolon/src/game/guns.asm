; --------------------------------------------------------------------------------------------------------------------
; guns.asm: The guns and their shots, the shells against the shots and the player
; --------------------------------------------------------------------------------------------------------------------

; The gun emplacements fire at a player far enough to their left
;
; Main loop, every pass. For each gun of GunList, a random byte of $F7 or more
; (9 in 256 a pass) is a shot, when the player's X is below the gun's (4 column
; - 2) - $1E (more than 60 pixels to its left; a player not left of it ends the
; routine for the rest of the guns this pass). The shot takes a free record of
; GunShots (X = 4 column - 2, Y = 8 row, dx = -2), drawn (frame 8) with the
; sound $C13B. No free record: the routine ends.
;
; The guns are the scenery's cannons (w030's screen 30: the green cannon on its
; pedestal firing left). w clones: 426 shots on 46 screens.
Guns:
  LD HL,GunList
; This entry point is used by the routine at GunShotSlot.
GunsLoop:
  LD E,(HL)               ; $FF: the end
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  CALL Random             ; 9 chances in 256
  CP $F7
  JR C,GunsLoop
  CALL CellToPixels       ; C = the gun's X - 2 - $1E
  DEC E
  DEC E
  LD A,E
  SUB $1E
  LD C,A
  LD A,(PlayerX)          ; the player too close or right of it: done
  CP C
  RET NC
  PUSH HL
GunFindShot:
  LD HL,GunShots
; This entry point is used by the routine at GunShotSlot.
GunFindShotLoop:
  BIT 7,(HL)              ; bit 7: the end, no free record
  JR Z,GunShotSlot

; No free shot record: POP HL, RET (the rest of the guns wait)
;
; Data in the mechanical cut: no recording filled the 10 shot records.
GunShotsFull:
  POP HL
  RET

; The shot record search goes on; a free one gets the shot
;
; The next record (3 bytes; dx 0: free) back to GunFindShotLoop; a free one: dx
; -2, Y, X written, frame 8 drawn, the gun's sound $C13B, and Guns goes on with
; the next gun.
GunShotSlot:
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR NZ,GunFindShotLoop
  DEC HL                  ; dx -2, Y, X
  LD (HL),$FE
  DEC HL
  LD (HL),D
  DEC HL
  LD (HL),E
  LD A,$08                ; frame 8 and the gun's sound
  CALL DrawSmallSprite
  CALL PlaySfxNoiseSweep
  POP HL
  JR GunsLoop

; Up to 10 guns (column, row); $FF after the last (map value 11)
GunList:
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $00,$00
  DEFB $FF                ; the fixed end mark

; Move every gun shot two units left
;
; Main loop, every pass (c1: 3260, empty). For each shot (dx not 0): frame 8
; erased; at X 0 the record freed (dx 0); else X + dx, drawn, painted bright
; white ($47).
;
; w clones: 16 331 steps, 224 shots off the left edge.
MoveGunShots:
  LD HL,GunShots
MoveGunShotsLoop:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  LD C,A
  INC HL
  OR A
  JR Z,MoveGunShotsLoop
  PUSH HL
  LD A,$08
  CALL DrawSmallSprite
  LD A,E
  OR A
  JR NZ,GunShotStep
  DEC HL
  LD (HL),$00
  POP HL
  JR MoveGunShotsLoop
GunShotStep:
  LD A,C                  ; X + dx, drawn
  ADD A,E
  LD E,A
  LD A,$08
  CALL DrawSmallSprite
  LD C,$47
  CALL ColourCell
  DEC HL
  DEC HL
  DEC HL
  LD (HL),E
  POP HL
  JR MoveGunShotsLoop

; Clear the gun shot list (30 bytes)
;
; Called by the screen builder $8494.
ClearGunShots:
  LD HL,GunShots
  LD DE,GunShots+$0001
  LD (HL),$00
  LD BC,$001D
  LDIR
  RET

; Up to 10 gun shots (X, Y, dx); $FF after the last
;
; The shots hit by the player's shots ($9E37 / $9E4F) and the player ($9E64)
; are tested past this range.
GunShots:
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

; Tests every gun shell against the player's shots; a hit shell is destroyed
;
; Called by the shot step $83DD each pass (c1: 16 303 entries, five a main loop
; pass with its four other calls). Walks the shell list $9E18 (3 bytes a shell:
; X, Y, the step; $FF ends; a step of 0 is a free record), skips the free ones,
; and asks $9B82 whether one of the player's shots ($845F) overlaps the shell
; (A not 0: hit, the shot removed); then DestroyShell. Ends when E (the X byte)
; has bit 7 set, the list's $FF.
;
; The shells are launched by the guns of tile 11 ($9D7F) and moved left by
; $9DD6 (not in this range). Warp runs: DestroyShell 174 times in 27 runs, none
; in c1 (the random play never shot one).
ShellsVsShots:
  LD HL,GunShots
ShellsVsShotsLoop:
  LD E,(HL)               ; E = X; bit 7: the list's end
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A                    ; the step 0: a free record
  JR Z,ShellsVsShotsLoop
  CALL BallShot           ; A = 1: a shot of $845F hit (X, Y) = DE
  OR A
  CALL NZ,DestroyShell
  JR ShellsVsShotsLoop

; Removes the shell at DE: XOR-erased, its record freed, an explosion there,
; sound 8, 50 points
;
; In: DE = the shell's X, Y; HL = the record's next byte (the shell's step +
; 1). XorSprite $92FB draws sprite 8 (the shell) over itself, the step byte
; goes to 0, $981D starts an explosion at DE, $C155 asks the AY for effect 8,
; and AddScore adds Points50 (50). Callers: ShellsVsShots, ShellsVsPlayer.
DestroyShell:
  LD A,$08
  CALL DrawSmallSprite
  DEC HL                  ; the shell's step byte: 0 frees the record
  LD (HL),$00
  INC HL
  CALL AddPuff
  CALL PlaySfxExplosion
  LD DE,Points50+$0005    ; the 6 digits ending at $AD9C: 000050
  JP AddScore

; Tests every gun shell against the player: a shell that touches him is
; destroyed and kills him
;
; Main loop (c1: 3260 entries, one a pass). The same walk as ShellsVsShots;
; $9BD6 with B = 8, C = 4 (the shell's size) answers 1 when the shell overlaps
; the player ($82F5, $82F6). Then DestroyShell, sound 8 again and KillPlayer
; $9CAF (which does nothing while the player is dying or immune: $9CE2, $768D).
ShellsVsPlayer:
  LD HL,GunShots
ShellsVsPlayerLoop:
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  OR A
  JR Z,ShellsVsPlayerLoop
  LD BC,$0804             ; the shell is 4 wide and 8 high in the units of
                          ; $9BD6
  CALL PlayerContact
  OR A
  JR Z,ShellsVsPlayerLoop
  CALL DestroyShell
  CALL PlaySfxExplosion
  JP KillPlayer
