; --------------------------------------------------------------------------------------------------------------------
; countdown.asm: The countdown and the lost game
; --------------------------------------------------------------------------------------------------------------------

  ORG $935D

; One minute off the countdown; when it runs out, the game is lost
;
; Called once a pass by MainLoop `$9018`. The countdown is three plain binary
; bytes: days `$5BFB`, hours `$5BFC`, minutes `$5BFD` (InitGame sets 30, 23,
; 59; c1 frame 23500 holds 30, 23, 11). Minutes - 1; below 0 it is 59 and the
; hours - 1 (440 runs of `$9364`); below 0, 23 and the days - 1 (`$936B`, 13
; runs in rzx: about every 4000 frames); below 0 the time is up: falls into
; LoseGame `$9372` (not executed in any recording: the rzx run ended with 18
; days left).
;
; Witness: L1 26514 (c1, explorers, gameover, rzx x31).
CountDown:
  LD HL,CountdownMinutes
  DEC (HL)
  BIT 7,(HL)
  RET Z
  LD (HL),$3B
  DEC HL
  DEC (HL)
  BIT 7,(HL)
  RET Z
  LD (HL),$17
  DEC HL
  DEC (HL)
  BIT 7,(HL)
  RET Z

; The game is lost: the hero in room $28 for the space scene
;
; Reached by falling in from CountDown `$935D` (the time is up) and by `JP
; Z,$9372` at `$A9FE` in `$A9EE` when the last life is lost (gameover frame
; 1502).
;
; The hero's frame `$5B06` = `$7F` (the blank sprite), Room `$5C01` = `$28` and
; the room set-up `$9855`; the respawn state too: room `$28` (`$5C2D`),
; StatusTimer 0 (`$5C2C`), Status `$1D` (`$5C2B`); `JP $AE85` with A = `$1D`:
; Status = `$1D`, StatusTimer = 0. Status `$1D` is Frozen `$A90E`, which only
; holds; SpaceScene `$B0B6`, room `$28`'s script, plays the asteroid striking
; (gameover frames 1509-1961) and sets GameOver; EndGame `$906D` follows (frame
; 1962). After the last life the respawn (`$9090`, LifeLost still set) restores
; the same room and event.
;
; The time running out, on a clone (work/stage2/probe_points.py A: the RZX
; state at 44000 in room `$3B`, the countdown poked to 0 days 0 hours 2
; minutes): the pass after 0/0/0 falls in here (days wrap to 255, the clock
; goes on counting: 255/23/59), Room `$28` 10 frames after the poke, status 29
; from frame 20, GameOver `$5BFF` at frame 430: the same space scene as the
; last life's (no other end for the time running out).
;
; Witness: L1 1 (gameover).
LoseGame:
  LD A,$7F
  LD (Hero+2),A
  LD A,$28
  LD (Room),A
  CALL SetUpRoom
  LD A,$28
  LD (RespawnRoom),A
  XOR A
  LD (RespawnTimer),A
  LD A,$1D
  LD (RespawnStatus),A
  JP SetStatus
