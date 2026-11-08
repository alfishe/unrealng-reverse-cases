; --------------------------------------------------------------------------------------------------------------------
; death.asm: The player's contacts, the traps, the death
; --------------------------------------------------------------------------------------------------------------------

; Does a box at a position overlap the player?
;
; In: E = X, D = Y of the box's top left, C = its width in 2-pixel units, B =
; its height in lines. Out: A = 1 when it overlaps the player (X $82F5, Y
; $82F6): his box is 12 units wide (X-12..X+C-1 holds the box) and 32 lines
; tall, 26 lines (Y+6 on) when crouching ($82FB). HL kept.
;
; Callers: the missiles $90EA, BallsTouchPlayer, TrapContact, the gun shots
; $9E64, $A26B, $A30B, $A5F4, $AC7D. c1: 1719 tests, 59 hits; the crouched box
; (PlayerContactCrouched) 14 times in c1.
PlayerContact:
  PUSH HL
  LD A,C
  ADD A,$0C
  NEG
  LD L,A
  LD A,(PlayerX)          ; X - E - C within -(C + 12)..-1
  SUB E
  SUB C
  CP L
  LD A,$00
  JR C,PlayerContactDone
  LD A,(CrouchOffset)     ; crouching: the shorter box
  OR A
  JR NZ,PlayerContactCrouched
  LD A,B                  ; standing: Y - D - B within -(B + 32)..-1
  ADD A,$20
  NEG
  LD H,A
  LD A,(PlayerY)
  SUB D
  SUB B
  CP H
  LD A,$00
  JR C,PlayerContactDone
  INC A
PlayerContactDone:
  POP HL
  RET
PlayerContactCrouched:
  LD A,B                  ; Y + 6 - D - B within -(B + 26)..-1
  ADD A,$1A
  NEG
  LD H,A
  LD A,(PlayerY)
  ADD A,$06
  SUB D
  SUB B
  CP H
  LD A,$00
  JR C,PlayerContactDone
  INC A
  POP HL
  RET

; The traps: probes that rise out of the floor, hold, and sink again
;
; Main loop, every pass. The ZXDB traps POKE (39957) puts a RET at the first
; byte: every warp clone ran with it, so the body ($9C25-$9C6F) is data in the
; mechanical cut; exC's t1 (screen 14, three traps, no traps POKE) ran it 1047
; times.
;
; A record of TrapList: column, row, counter. Each pass the counter goes up by
; one: below $65 the trap rests, sunk; $65-$68 it rises one row a pass; $69-$73
; it stays up; $74-$77 it sinks one row a pass; at $78 the counter restarts at
; $14 + a random 0-63 (a wait of 25 to 81 passes). While it moves or stands up
; it is drawn each pass with $76DA: the big sprite $18 moved from the old row
; to the new at the column, with the trap's own background buffer (IX: $B201
; for the first trap, $80 bytes each), then its cells painted bright green
; ($44, $7C5F).
;
; TrapContact kills the player on it.
Traps:
  LD IX,WorkArea
  LD HL,TrapList
TrapsLoop:
  LD DE,$0080             ; IX: the next trap's buffer
  ADD IX,DE
  LD E,(HL)
  BIT 7,E
  RET NZ
  INC HL                  ; B = the row before the move; the counter counted up
  LD D,(HL)
  LD B,D
  INC HL
  LD A,(HL)
  INC (HL)
  INC HL
  CP $65                  ; resting
  JR C,TrapsLoop
  CP $69                  ; rising
  JR NC,TrapStanding
  DEC D
  DEC HL
  DEC HL
  LD (HL),D
  INC HL
  INC HL
  JR TrapDraw
TrapStanding:
  CP $74                  ; standing up
  JR C,TrapDraw
  CP $78                  ; sinking
  JR NC,TrapRestart
  INC D
  DEC HL
  DEC HL
  LD (HL),D
  INC HL
  INC HL
  JR TrapDraw
TrapRestart:
  DEC HL                  ; the next rest: $14 + a random 0-63
  CALL Random
  AND $3F
  ADD A,$14
  LD (HL),A
  INC HL
TrapDraw:
  CALL CellToPixels       ; C = X, B = the old Y, D = the new Y
  LD C,E
  LD A,B
  ADD A,A
  ADD A,A
  ADD A,A
  LD B,A
  LD A,$18                ; the big sprite $18 through the trap's buffer
  PUSH HL
  PUSH IX
  POP HL
  CALL DrawBigSprite
  LD C,$44                ; bright green
  CALL ColourBigSprite
  POP HL
  JR TrapsLoop

; Up to 4 traps (column, row, counter); $FF after the last
;
; Built by $8E86 from map value 10 (record size 3; the map cell then 1). The
; counter starts at $5F (ClearTraps): the first rise six passes after the
; screen starts. The ROM image holds zeros.
TrapList:
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $00,$00,$00
  DEFB $FF                ; the fixed end mark

; Fill the trap records with $5F, the counters' start
;
; Called by the screen builder $8494 before the lists are built: $5F in
; $9C70-$9C7B; the builder then writes each trap's column and row over the
; first two bytes.
ClearTraps:
  LD HL,TrapList
  LD DE,TrapList+$0001
  LD BC,$000B
  LD (HL),$5F
  LDIR
  RET

; A trap that is up kills the player it touches
;
; Main loop, every pass. For each trap with a counter of $65 or more (rising,
; up or sinking): PlayerContact with a box of $20 lines by $0C units at its
; current row; a touch jumps to ShieldedKill.
TrapContact:
  LD HL,TrapList
; This entry point is used by the routine at TrapTouch.
TrapContactLoop:
  LD E,(HL)               ; resting traps are harmless
  BIT 7,E
  RET NZ
  INC HL
  LD D,(HL)
  INC HL
  LD A,(HL)
  INC HL
  CP $65
  JR C,TrapContactLoop

; The contact test of a moving trap
;
; Data in the mechanical cut (the traps POKE kept the counters from rising in
; every warp clone); exC's t1 ran it 294 times, 34 touches.
TrapTouch:
  CALL CellToPixels
  LD BC,$200C
  CALL PlayerContact
  OR A
  JR Z,TrapContactLoop
  JP ShieldedKill

; Kill the player unless he wears the exoskeleton
;
; In: the exoskeleton offset $9ED8 (0, or $0C while it is worn: $9F5D toggles
; it, it shifts the player's frames by 12). Worn: return. Else into KillPlayer.
; Callers: Mines (MineFires), TrapContact. The ZXDB mines POKE (40110) is the
; RET NZ at $9CAE turned into RET: mines and traps never kill. w030 ran it
; once, t1 34 times.
ShieldedKill:
  LD A,(ExoSuit)
  OR A
  RET NZ                  ; the mines POKE (ZXDB 40110)

; Start the player's death
;
; Nothing while the death runs (DeathTimer) or while the guard $768D counts
; down (the main loop takes one off a pass, $767A). The ZXDB immunity POKE
; (40120) is the RET NZ at $9CB8 turned into RET: no death at all.
;
; Else: the screen time $AC7B cleared, $82F7 (the jump state) and the fire-hold
; count $83DC cleared, DeathTimer 46, the guard 66 (46 + 20: the player cannot
; die again for 20 passes after he reappears), the player drawn with frame $0B
; at his place, Y rounded down to 4 lines ($8224). AF, DE kept.
;
; c1: 59 calls, 31 deaths (x1, m1 and h1: 9 each, their nine lives).
KillPlayer:
  LD A,(DeathTimer)
  OR A
  RET NZ
  LD A,(ImmunityCount)    ; the guard after a death
  OR A
  RET NZ                  ; the immunity POKE (ZXDB 40120)
  PUSH AF
  PUSH DE
  LD HL,$0000             ; the screen timer from 0
  LD (IdleTime),HL
  XOR A
  LD (JumpStep),A
  LD (FireHeld),A
  LD A,$2E                ; 46 passes of death
  LD (DeathTimer),A
  ADD A,$14
  LD (ImmunityCount),A
  LD DE,(PlayerX)         ; frame $0B at the player's place
  LD A,D
  AND $FC
  LD D,A
  LD A,$0B
  CALL PlayerFrame
  POP DE
  POP AF
  RET

; The passes left of the player's death, 46 down to 0 (0: alive)
DeathTimer:
  DEFB $00

; One pass of the player's death: the leap, then a life lost and the restart
;
; Main loop, every pass (c1: 3263; 1426 death passes). DeathTimer t counted
; down. While t > 0: the vertical step DeathLeap[t] (HL = $9D49 + t): a step of
; $0A or more (negative: up) moves him; a step below $0A (0 or down) moves him
; only when the floor test $814E finds nothing under him. Frame $0B at the new
; place ($8224).
;
; At t = 0: the player's frames turned back to face right ($7BDA set: $7BAA
; mirrors them), the facing $82FA = 1, lives - 1 ($8E7A; the DEC A at $9D1D is
; ZXDB's lives POKE 40221), ammunition 99, grenades 10, the three printed
; ($8E4F, $8E5B, $8E67); no lives left: GAME OVER ($A02A). Else the player is
; put at the restart position $82F3 / $82F4 with frame 5, dropped to the floor
; first if there is none under it (DeathDropToFloor).
;
; x1: 9 deaths, the ninth to GAME OVER.
PlayerDeath:
  LD A,(DeathTimer)
  OR A
  RET Z
  LD DE,(PlayerX)
  LD C,A
  DEC A
  LD (DeathTimer),A
  JR Z,DeathOver
  LD HL,DeathLeap-$0001   ; the step of this pass
  LD B,$00
  ADD HL,BC
  LD A,(HL)
  CP $0A
  JR NC,DeathMove
  CALL TestBelow          ; falling: only into empty space
  LD A,$0B
  JP NZ,PlayerFrame
DeathMove:
  LD A,(HL)
  ADD A,D
  LD D,A
  LD A,$0B
  JP PlayerFrame
DeathOver:
  LD A,(PlayerFlipped)    ; the life lost
  OR A
  CALL NZ,FlipPlayerFrames
  LD A,$01                ; facing right
  LD (Facing),A
  LD A,(Lives)
  DEC A                   ; the lives POKE (ZXDB 40221)
  LD (Lives),A
  LD A,$63                ; ammunition 99, grenades 10
  LD (Ammo),A
  LD A,$0A
  LD (Grenades),A
  CALL PrintAmmo
  CALL PrintGrenades
  CALL PrintLives
  LD A,(Lives)            ; no lives: GAME OVER
  OR A
  JP Z,GameOver
  LD DE,(RestartX)        ; the restart position
; This entry point is used by the routine at DeathDropToFloor.
DeathRestartLoop:
  CALL TestBelow          ; floor under him: frame 5 there
  LD A,$05
  JP NZ,PlayerFrame

; No floor under the restart position: one line down and test again
;
; INC D, JR DeathRestartLoop. Data in the mechanical cut: the restart positions
; of every recording had a floor.
DeathDropToFloor:
  INC D
  JR DeathRestartLoop

; The death's vertical steps for DeathTimer 1-45 (index 1 first)
;
; PlayerDeath reads $9D49 + t ($9D49 is the JR operand before the table). From
; the start (t = 45) on: -4, -4, -2, -2, -2, -1 x 4, 0 x 4, then down 1 x 4, 2
; x 3 and 4 a pass to the end: a leap of 18 lines, then the fall.
DeathLeap:
  DEFB $04,$04,$04,$04,$04,$04,$04,$04
  DEFB $04,$04,$04,$04,$04,$04,$04,$04
  DEFB $04,$04,$04,$04,$04,$04,$04,$04
  DEFB $04,$04,$02,$02,$02,$01,$01,$01
  DEFB $01,$00,$00,$00,$00,$FF,$FF,$FF
  DEFB $FF
  DEFB $FE,$FE,$FE,$FC,$FC ; t = 41-45: the climb

; Return from the caller while the player dies
;
; DeathTimer not 0: POP the return address, so the RET returns from the caller.
; Called first by the movement $81A4, the fire $8338, ThrowGrenade and $A553.
; c1: 13 046 calls, 5642 of them during a death.
AbortIfDying:
  LD A,(DeathTimer)
  OR A
  RET Z
  POP AF
  RET
