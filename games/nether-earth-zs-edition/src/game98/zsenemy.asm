; --------------------------------------------------------------------------------------------------------------------
; zsenemy.asm: ZS's enemy helpers in the sprites' spare bytes: the daily robot upgrade and the enemy's 99s
;
; Two routines ZS wrote into NE's free space before Start ($A5D6-$A5FF, 42 bytes), NE has zeros here. They are the
; '98's "harder enemy": DailyProduction ($AE44, $AE47) calls both once a game day instead of NE's ProduceSide for the
; enemy, and NewGameSetup ($A688) calls FillEnemyResources once at a new game.
;
; Data they write, outside the module: the enemy's robot records EnemyRobots ($DB80, 24 x 16 bytes, +$07 the parts:
; bit 0 bipod, 1 tracks, 2 anti-grav, 3 cannon, 4 missiles, 5 phasers, 6 nuclear, 7 electronics) and EnemyResources
; ($FD4A, 7 bytes) plus the byte after it, Side ($FD51).
; --------------------------------------------------------------------------------------------------------------------

; every enemy record: +$07 = (+$07 AND $78) OR $84: anti-grav and electronics
; on, bipod and tracks off
;
; All 24 enemy slots, live or free (free slots have +$01 = 0 and are not
; checked): the weapons (bits 3-6) are kept, the chassis becomes anti-grav (bit
; 2; bits 0 and 1 cleared) and electronics (bit 7) are added. The step delay's
; column is the lowest part bit (SetStepDelay), so every enemy robot then steps
; like an anti-grav one (StepDelays: 3, 3, 4 turns on flat, low, high ground,
; against a bipod's 6, 8, 9), and electronics give it the longer sight in its
; facing direction (12 cells, SpotEnemies) and one more shot step. A free
; slot's +$07 is overwritten anyway when EnemyCommander builds a robot there,
; so a robot built during the day keeps its own parts until the next midnight.
; IY is kept (PUSH / POP). Called by DailyProduction ($AE44), once a game day:
; 9 runs (216 records) over the 9 midnights of this part's deep recording; at
; its end (day 9, 08:25) all 24 enemy records were live and each had bits 2 and
; 7 set, none a bipod or tracks.
UpgradeEnemyRobots:
  PUSH IY                 ; IY is the caller's
  LD DE,$0010             ; DE = 16, the record size
  LD B,$18                ; B = 24 records
  LD IY,$DB80             ; IY = EnemyRobots, slot 24
UpgradeEnemyRobotsLoop:
  LD A,(IY+$07)           ; +$07 the parts
  AND $78                 ; keep the weapons: cannon, missiles, phasers,
                          ; nuclear
  OR $84                  ; add electronics (bit 7) and anti-grav (bit 2)
  LD (IY+$07),A           ; store the new parts
  ADD IY,DE               ; the next record
  DJNZ UpgradeEnemyRobotsLoop ; 24 times
  POP IY                  ; IY back
  RET

; EnemyResources ($FD4A-$FD50) = 99 each, and Side ($FD51) = 99 too
;
; (HL) = $63 at $FD4A, then LDIR with BC = 7 copies it forward byte by byte to
; $FD4B-$FD51: eight bytes, one more than the seven resources, so Side ($FD51)
; is also set to 99. That is harmless: Side is written before it is read again
; (RobotStep at $B154 for each robot step, EnemyCommander at $B7F4 for the
; enemy's turn, the robot menu's search). With all seven at 99 every day, the
; enemy can always pay for any robot (PartCosts: all eight parts together cost
; 51), so its building counts no longer matter. Called by NewGameSetup ($A688,
; a new game) and DailyProduction ($AE47, each midnight): 10 runs in the deep
; recording (the new game and 9 midnights), and at its end EnemyResources read
; 99 in all seven, with the enemy at 24 robots and 3 warbases against the
; player's 4 robots and 1 warbase.
FillEnemyResources:
  LD BC,$0007             ; 7 bytes to copy
  LD HL,EnemyResources             ; the first enemy resource
  LD DE,EnemyResources+1             ; the next byte
  LD (HL),$63             ; 99
  LDIR                    ; spread it to $FD4B-$FD51 (Side included)
  RET
