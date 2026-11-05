; --------------------------------------------------------------------------------------------------------------------
; difficulty.asm: the room of the disk and paging pieces, the daily upgrade of the enemy's robots, the enemy's resources
;
; $A56A-$A5FF, free space after the sprites in Nether Earth, holds two kinds of bytes. $A56A-$A5D5 is room stage 3
; fills with pieces of the patches block (src/patches99): on 128 K paging128 at $A56A (the copy of a text from page 3
; and the paging routine $A58A) and diskread at $A598 (the TR-DOS sector reader LOAD MAP calls); on the tape path
; textload48 and taperead. The block's own bytes there are zeros, but for the four bytes at $A598, the first
; instruction of diskread.
;
; $A5D6-$A5FF holds the two routines of the start-up menu's difficulty levels. The start-up menu (its code at `$DA8E`)
; writes their calls into the game: MEDIUM and up CALL FillEnemyResources at $B87E (the enemy's build: its resources
; are 99 again before every robot) and NOP + "??" at $D2C8 (the enemy's robot count hidden); HARD and up 6 NOPs + CALL
; UpgradeEnemyRobots at $AE41 (the enemy's daily production replaced by the upgrade of its robots); CRITICAL also
; writes the upgrade's operands, $A5E7 = $FC and $A5E5 = 0. EASY writes back the block's own bytes (the code of Nether
; Earth). The start-up menu's UPGRADING items toggle bits 7-2 of $A5E7 and set $A5E5 to $F8 when anti-grav (bit 2) is
; on, else $FF.
;
; The parts byte of a robot (+$07): bit 0 bipod, 1 tracks, 2 anti-grav, 3 cannon, 4 missiles, 5 phasers, 6 nuclear, 7
; electronics. The image's values, AND $78, OR $84, keep each robot's weapons and give it electronics and anti-grav in
; place of its chassis.
; --------------------------------------------------------------------------------------------------------------------

; Zero: stage 3 copies paging128 or textload48 here ($A56A-$A597)
;
; On 128 K the patches block's paging128 (41 bytes, `$DA3F`), on one page or
; tape textload48 (46 bytes, `$DAE7`). The block's 46 zero bytes never run.
PieceRoomA56A:
  DEFS $2E

; The first 4 bytes of diskread: LD IX,$2F65 (DD 21 65 2F)
;
; Stage 3 copies diskread (or taperead) over $A598-$A5D5, so these bytes are
; always replaced. They equal the first instruction of diskread, which reads a
; sector through the TR-DOS ROM routine $2F65: a leftover of the author's own
; image, where the reader had been placed.
DiskReadLeftover:
  DEFB $DD,$21,$65,$2F

; Zero: the rest of the reader's room, up to $A5D5
;
; 58 zero bytes, replaced by diskread's (or taperead's) next bytes.
PieceRoomA59C:
  DEFS $3A

; Every enemy robot's parts: (parts AND [$A5E5]) OR [$A5E7]; HARD and up, once
; a game day
;
; Called from DailyProduction ($AE41) when the start-up menu has written the
; call there (HARD, CRITICAL). For the 24 enemy slots ($DB80, 16 bytes each,
; alive or not): +$07 = (+$07 AND mask) OR parts. The image's mask $78 keeps
; the four weapons (cannon, missiles, phasers, nuclear) and drops electronics
; and the chassis; the parts $84 add electronics and anti-grav. CRITICAL makes
; the mask 0 and the parts $FC: every enemy robot becomes anti-grav with all
; four weapons and electronics. UPGRADING in the start-up menu sets the parts'
; bits 7-2 one by one and the mask to $F8 (anti-grav chosen: the old chassis
; bits 0-1 dropped) or $FF (all kept).
;
; Only +$07 changes: the height +$09 its build computed from the parts stays as
; it was. The view draws a robot from its part bits (DrawRobot), so the new
; parts show at once, and the weapons code reads the same bits. A free slot
; gets parts too, but a new robot's record is written whole by its build. B =
; 24; IY kept.
UpgradeEnemyRobots:
  PUSH IY                 ; IY kept for the caller
  LD DE,$0010             ; the record size
  LD B,$18                ; the enemy's 24 slots
  LD IY,EnemyRobots             ; IY = the first enemy record
UpgradeEnemyRobot:
  LD A,(IY+$07)           ; the robot's parts
  AND $78                 ; AND the mask: $78 keeps the weapons (CRITICAL 0)
  OR $84                  ; OR the new parts: $84 electronics + anti-grav
                          ; (CRITICAL $FC)
  LD (IY+$07),A           ; back into the record
  ADD IY,DE               ; the next slot
  DJNZ UpgradeEnemyRobot  ; all 24
  POP IY                  ; IY back
  RET

; The enemy's resources = 99 each; HL = $FD4A
;
; Writes $63 (99) into the 8 bytes $FD4A-$FD51: the enemy's seven resources
; (EnemyResources: general, electronics, nuclear, phasers, missiles, cannon,
; chassis) and Side, which the side's searches read only as zero or not (the
; enemy's 1 becomes 99, same meaning). Returns HL = $FD4A, so that a CALL to it
; can replace LD HL,$FD4A: called by NewGameSetup ($A688) for every level and,
; MEDIUM and up, by the enemy's build ($B87E), so the enemy never runs short.
FillEnemyResources:
  LD HL,EnemyResources             ; the enemy's resources
  LD B,$08                ; 8 bytes (Side too)
FillEnemyResource:
  LD (HL),$63             ; 99
  INC HL                  ; the next
  DJNZ FillEnemyResource  ; 8 times
  LD HL,EnemyResources             ; HL = $FD4A, as the LD HL it replaces
  RET
