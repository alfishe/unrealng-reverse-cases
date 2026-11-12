; --------------------------------------------------------------------------------------------------------------------
; mainloop.asm: The main loop, the IM 2 handler and its tick, the input read, the actor dispatch
; --------------------------------------------------------------------------------------------------------------------

  ORG $831A

; Show message 4 (the game over) and wait up to 200 frames or for fire
;
; A = 4, CALL $66C8 (the message actor in the globals page: message 4, run
; until it ends), then falls into WaitFireLong. Callers: the game over $5C42
; and the quit from the pause ($668E: fire while paused).
;
; Witness: L1 10 (gameover, hiscore, menu, opt x3, rzx x4).
ShowGameOverWait:
  LD A,$04
  CALL ShowMessage

; Wait 40 x 5 frames or until fire: Z = fire pressed
;
; H = $28, then WaitFireFrames. Callers: $5D4F, $5DD8 (the title and intro),
; $A73A (the high-score table).
;
; Witness: L1 122 (deaths, gameover, hiscore, menu, throw, c x2, opt x3, rzx
; x6).
WaitFireLong:
  LD H,$28

; Wait H x 5 frames (HALT) or until fire: Z = fire, NZ on time out
;
; Reads the input (ReadInput $8529, Z = fire), EI, 5 HALTs; returns Z at once
; on fire; H counts down; at 0 DEC H once more so the return is NZ. Callers:
; $5D4F, $5DDE, $A6F5 (H = 1: 5 frames).
;
; Witness: L1 6408 (deaths, gameover, havok, hiscore, menu, throw, c x2, opt
; x3, rzx x6, rzxroom x2).
WaitFireFrames:
  CALL ReadInput
  EI
  LD B,$05
WaitFireHalt:
  HALT                    ; five frames
  DJNZ WaitFireHalt
  RET Z
  DEC H
  JR NZ,WaitFireFrames
  DEC H
  RET

; Busy-wait $6000 loops (about 0.18 s)
;
; Witness: L1 144 (gameover, havok, hiscore, menu, opt x3, rzx x7).
PauseLong:
  LD BC,$6000

; Busy-wait BC loops of 26 T-states (BC = 0: 65 536)
;
; Callers: PauseLong, $5D4F, HavokFade $8756, $66AB.
;
; Witness: L1 4580939 (deaths, gameover, havok, hiscore, menu, throw, c x2, opt
; x3, rzx x9).
DelayBC:
  DEC BC
  LD A,B
  OR C
  JR NZ,DelayBC
  RET

  ORG $8456

; The IM 2 handler: the game tick (when the flag at $845F is 0), the sound,
; every frame
;
; Entered through $FDFD (JP $8456) from the vector table $FE00. Saves HL, DE,
; BC, AF, IX, IY; LD A,n at $845E: the operand $845F is 0 in play ($5CF4) and 1
; on the title, the high-score and the game-over screens ($A747, $A842), and
; only 0 runs GameTick; EffectPlayer $853F every frame (on a 128K the glue to
; bank 4); EI, RETI.
;
; Witness: L1 222542 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
InterruptHandler:
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH AF
  PUSH IX
  PUSH IY
  LD A,$01                ; LD A,n: n = 0 in play, 1 elsewhere
  OR A
  CALL Z,GameTick
  CALL EffectPlayer
  POP IY
  POP IX
  POP AF
  POP BC
  POP DE
  POP HL
  EI
  RETI

; The frame counter, the actor timers, the pause key, the input and the fire
; charge
;
; LD HL,n at $8472: n ($8473) is a 16-bit frame counter. For the ten pages
; $5D00-$66FF (H = $5D-$66, the nine actors and the message actor) whose +2 bit
; 0 is set: +$1D counted down to 0 every frame; unless paused ($664C bit 7) the
; word +$1E counted down and, at 0, +$10 bit 5 set (and for page $65 $6651
; cleared). P (port $DFFE bit 0) sets $664C = $80 (the main loop calls the
; pause $6682).
;
; The input: E = the last fire bit ($6648); A = ReadInput $8529, kept at $850D
; for ReadDirection; AND the fire mask (the operand at $84CA, 1, set by the
; options $6A9B); $6648 = the fire bit (0 pressed). Fire held: if $6652 bit 6
; (the end text is up) set bit 7 (the main loop leaves for the end $5C45) and
; return; else the charge $6645 += $6644, at most $20. Fire released this
; frame: C = the charge, the charge back to $6647; $8E77 must return Z and the
; message actor ($6602 bit 0) be off; then $69E3 = C and the power $6650 = 3
; (charge $19 or more), 2 ($09-$18) or 1.
;
; Witness: L1 177113 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
GameTick:
  LD HL,$0000
  INC HL
  LD (GameTick+$0001),HL
  LD H,$5D
  LD B,$0A
TickActorLoop:
  LD L,$02                ; L = 2: the actor's flags
  LD A,(HL)
  RRA
  JR NC,TickNextActor
  LD L,$1D
  XOR A
  OR (HL)
  JR Z,TickActorTimer
  DEC (HL)
TickActorTimer:
  LD A,(PauseFlag)        ; the 16-bit timer, not while paused
  RLA
  JR C,TickNextActor
  LD L,$1E
  LD E,(HL)
  INC L
  LD D,(HL)
  LD A,E
  OR D
  JR Z,TickNextActor
  DEC DE
  LD (HL),D
  DEC L
  LD (HL),E
  LD A,E
  OR D
  JR NZ,TickNextActor
  LD L,$10
  SET 5,(HL)
  LD A,H
  CP $65
  JR NZ,TickNextActor
  XOR A
  LD (Invulnerable),A
TickNextActor:
  INC H
  DJNZ TickActorLoop
  LD BC,$DFFE             ; the P key: port $DFFE bit 0
  IN A,(C)
  AND $01
  JR NZ,TickInput
  LD A,$80
  LD (PauseFlag),A
TickInput:
  LD A,(FirePrevious)     ; AND n at $84C9: the fire mask (options)
  LD E,A
  CALL ReadInput
  LD (ReadDirection+$0001),A
  AND $01
  LD (FirePrevious),A
  JR NZ,TickFireReleased
  LD HL,EndFlags
  BIT 6,(HL)
  JR Z,TickChargeFire
  SET 7,(HL)
  RET
TickChargeFire:
  LD L,$44                ; fire held: the charge
  LD A,(HL)
  INC L
  ADD A,(HL)
  CP $21
  JR C,TickChargeStore
  LD A,$20
TickChargeStore:
  LD (HL),A
  RET
TickFireReleased:
  XOR E                   ; fire released: the strike's power
  RET Z
  LD A,(ChargeReset)
  LD HL,Charge
  LD C,(HL)
  LD (HL),A
  CALL HiroBusy
  RET NZ
  LD A,(WeaponActor+$0002)
  RRA
  RET C
  LD A,C
  LD (FireHeld),A
  LD HL,FireRequest
  LD (HL),$03
  CP $19
  RET NC
  DEC (HL)
  CP $09
  RET NC
  DEC (HL)
  RET

; The direction of the input latched by GameTick: D, E = -1, 0 or +1, carry set
; when one is pressed
;
; LD A,n: n ($850D) is the raw input GameTick read this frame; falls into
; DecodeDirection. Caller: $9333.
;
; Witness: L1 32293 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x69, rzxroom x18).
ReadDirection:
  LD A,$00

; Decode the input byte A into D (right +1, left -1) and E (up -1, down +1); NC
; when no direction
;
; AND n / CP n (operands $850F, $8511, $1E for Sinclair 1): all released
; returns Z, NC. RRA drops the fire bit (the opcode at $8513 is set per
; control: RRA here); then one RRA per direction and the four opcodes at $851A,
; $851E, $8522, $8526 (DEC E, INC E, INC D, DEC D here) are written by the
; options $6AA2-$6ABE, so each joystick's bit order maps to the same moves.
; Returns SCF. Callers: ReadDirection, $A861 (the name entry), the 128K glue
; $85A3 (the title's toggle).
;
; Witness: L1 680151 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
DecodeDirection:
  AND $1E
  CP $1E
  RET Z
  RRA
  LD DE,$0000
  RRA
  JR C,DirectionBit2
  DEC E
DirectionBit2:
  RRA
  JR C,DirectionBit3
  INC E
DirectionBit3:
  RRA
  JR C,DirectionBit4
  INC D
DirectionBit4:
  RRA
  JR C,DirectionDone
  DEC D
DirectionDone:
  SCF
  RET

; Read the controls: A = the input bits (active low, bit 0 fire), Z = fire
; pressed (an 18-byte slot the options rewrite)
;
; As loaded: LD A,$EF / IN A,($FE) / BIT 0,A, the 6-0 half row (Sinclair
; joystick 1: 0 fire, 9 up, 8 down, 7 right, 6 left). The options $6AC2 copy 18
; bytes from the 14-byte option records at $6B0A over $8529-$853A (option 3
; Kempston: IN A,($1F) and its fix-up, see opt3's L1 at $8529). Callers:
; WaitFireFrames, GameTick, $A6EF, $A76F (the 128K hooks call $859E there),
; $A894.
;
; Witness: L1 833030 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
ReadInput:
  LD A,$EF
  IN A,($FE)
  BIT 0,A
  RET

; The rest of the input slot: zeros as loaded, the options write up to $853A
ReadInputSpace:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00

  ORG $8DFE

; The main loop: the nine actors, the end, the pause, the per-pass jobs
;
; Entered by `JP $8DFE` at the start of play (`$5CF7`) and from `$5C68`; it
; never returns. Each pass: SP = `$5C00` (whatever a routine left on the stack
; is dropped); for the nine pages `$5D00`-`$6500` (B = 9, H stepped by `INC H`,
; L = 2 kept), ActorUpdate `$8E2B` when bit 0 of +`$02` (active) is set; then
; the end flag `$6652` bit 7 (set by the tick when fire is pressed after
; Havok's death, `$84D7`) jumps to the end `$5C45`; the pause flag `$664C` bit
; 7 (P, read by the tick) calls the pause `$6682`; `$79FF` not 0 calls `$66B6`;
; and the two jobs copied over the loader, `$FF01` and `$FF64`.
;
; The tenth page `$6600` (Hiro's thrown weapon, kinds `$40-$46`) is not in this
; loop: RunActorSteps `$9A4B` runs it on every second call. Nothing waits for
; the frame: a pass costs about 2400-4000 T on average (518 T of the loop's own
; instructions; ActorUpdate 1566-1753 T a call, inclusive; `$FF01` and `$FF64`
; about 100 T each), so in light rooms the loop turns about 26 times a frame
; (c1: 25068 passes in the 975 frames of play). The room build runs inside an
; actor update (Hiro's move `$9B56` -> `$955A`) and stalls the loop 60-72
; frames (WALKTHROUGH 1).
;
; Counts: c1 25068 passes, 28339 actor updates (1.13 active actors a pass, Hiro
; alone in room 4); deaths 108018 passes, 225247 updates; rooms 78837 and
; 107204; menu 133076; opt2-4 about 15680 each.
;
; Witness: L1 2036434 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
MainLoop:
  LD SP,$5C00             ; the stack is reset on every pass
  LD B,$09                ; nine pages, $5D-$65; HL = +$02 (the flags) of the
                          ; first
  LD HL,Hiro+$0002

; The main loop continued: the actor scan, the end, the pause and the per-pass
; jobs
;
; The loop body of MainLoop `$8DFE` (an entry of its own: the `DJNZ` comes back
; here). H = the page, L = 2: +`$02` bit 0 (active) calls ActorUpdate `$8E2B`;
; after the ninth page the flags and the jobs, then `JR $8DFE`.
;
; Witness: L1 18327840 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
MainLoopActors:
  LD A,(HL)               ; +$02 bit 0: the actor is active
  RRA
  CALL C,ActorUpdate
  INC H                   ; the next page
  DJNZ MainLoopActors
  LD A,(EndFlags)         ; $6652 bit 7: the end after Havok, JP $5C45
  RLA
  JP C,EndOfGame
  LD A,(PauseFlag)        ; $664C bit 7: the pause
  RLA
  CALL C,PauseGame
  LD A,(MessageRequest)   ; $79FF set: $66B6
  OR A
  CALL NZ,PendingMessage
  CALL PanelWeapon        ; the per-pass jobs copied over the loader
  CALL PanelMeters
  JR MainLoop

; One actor's update: one logic step (when its delay has run out) and the
; redraw of the actor that moved
;
; H = the actor page (L = 2), from MainLoop `$8E01` and from BossFire `$947D`
; (which runs page `$6000` to its end). HL and BC are kept.
;
; 1. RunActorSteps `$9A4B` sets IY to the page and runs at most one actor's
; logic: on every second call the weapon page `$6600` (or, with a boss in the
; room, the boss shot page `$6000`) first, then Hiro, then the pages with
; +`$02` bit 2, then this one, each only when its step delay +`$1D` is 0; the
; logic is a sequence step (+`$30`-`$38`) or the state handler at +`$03`/+`$04`
; (the `c` entries below). IY is then the actor that ran.
;
; 2. When that actor's +`$20` bit 0 (moved, redraw) is set: clear it,
; ActorBoxStore `$8F3B` (its screen box), and draw: kind `$25` (Havok) goes to
; `$872B` (his own draw and death count-down); a box wholly off the play window
; (ClipFlagsOff `$8E98` on the clip bits `$69DD`) or a Y of `$A8-$C7` (below
; the window) is not drawn; else the render's `$8907` with `$898C`, `$8A76`
; (every active actor, D = `$A0`, E = 1), `$8907` with `$8943`, `$8A73` (the
; actors with +`$02` bit 7, drawn over the rest) when any has it, and `$8C68`.
;
; Only 1.4 % of the calls run logic (c1: 398 of 28339; deaths 4222 of 225247)
; and 1.1-1.3 % redraw (c1 308, deaths 2980): the step delays (+`$1A`, Hiro 3
; frames) are counted by the IM 2 tick, so most passes find nothing to do.
;
; Witness: L1 3898690 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
ActorUpdate:
  PUSH HL
  PUSH BC
  CALL RunActorSteps      ; IY = the actor whose logic ran
  BIT 0,(IY+$20)          ; +$20 bit 0: it moved, redraw it
  JR Z,ActorUpdateDone
  RES 0,(IY+$20)
  CALL ActorBoxStore      ; +$2A-$2F and the render's variables
  LD L,$1C
  LD A,(HL)
  CP $25                  ; kind $25 is Havok: $872B
  JP Z,HavokFade
  LD A,(BoxClip)          ; the clip bits of the box: wholly off the window?
  CALL ClipFlagsOff
  JR Z,ActorUpdateDone
  LD L,$00
  LD A,(HL)               ; Y $A8-$C7: below the window, not drawn
  CP $A8
  JR C,ActorUpdateDraw
  CP $C8
  JR C,ActorUpdateDone
ActorUpdateDraw:
  LD BC,ComposeBackCell
  CALL ComposeActorCells
  LD DE,$A001             ; D = $A0, E = 1 (the active bit): a constant, not an
                          ; address
  CALL DrawActorsAll
  PUSH BC
  LD BC,ComposeFrontCell
  CALL ComposeActorCells
  POP BC
  RL C                    ; bit 7 of the OR of every +$02: some actor is drawn
                          ; on top
  CALL C,DrawFrontActors
  CALL BlitWindow
ActorUpdateDone:
  POP BC
  POP HL
  RET

; Is Hiro falling, hanging or in a sequence? NZ if so
;
; Called by the tick (`$84F1`) when fire is let go: the attack is taken
; (`$6650`, `$69E3`) only when this gives Z. NZ when Hiro's +`$02` has bit 1
; (airborne) or bit 3 (hanging), or any of his sequence counters +`$30`-`$38`
; is not 0 (ActorInSequence `$8E89`).
;
; Witness: L1 771 (bossgate, havok, menu, play48, throw, c x1, opt x3,
; poke-room x15, rzx x67, rzxroom x10).
HiroBusy:
  LD A,(Hiro+$0002)
  AND $0A
  RET NZ
  LD H,$5D
  JR ActorInSequence

; Unreferenced: Hiro's sequences +$31-$38 (all but the jump), NZ if any
;
; `LD H,$5D` / `LD L,$31` / `LD B,8` / `JR $8E8D` into ActorInSequence's loop.
; No code in the image calls or jumps here and no table holds the address (a
; search of the image for the word `$8E81`): a leftover variant of HiroBusy
; `$8E77`. Not run in the keyed recordings.
;
; Witness: L1 0 ().
HiroBusyNoJump:
  LD H,$5D
  LD L,$31
  LD B,$08
  JR ActorInSequenceScan

; NZ when one of the actor's nine sequence counters +$30-$38 is running
;
; H = the page. ORs +`$30`-`$38` and returns NZ at the first one that is not 0,
; else A = 0 and Z. Callers: HiroBusy `$8E77`, `$9BB6` (keeps the redraw bit
; while a sequence plays).
;
; Witness: L1 163322 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
ActorInSequence:
  LD L,$30
  LD B,$09
; This entry point is used by the routine at HiroBusyNoJump.
ActorInSequenceScan:
  XOR A                   ; B pages of counters from L (HiroBusyNoJump enters
                          ; here)
ActorInSequenceLoop:
  OR (HL)
  RET NZ
  INC L
  DJNZ ActorInSequenceLoop
  XOR A
  RET

; Z when the actor's box is wholly off the play window (+$20's clip bits)
;
; A = +`$20`, then ClipFlagsOff `$8E98`. Called by the render's `$8A90` for
; each actor it draws.
;
; Witness: L1 158778 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
ActorOffWindow:
  LD L,$20
  LD A,(HL)

; Z when clip bits 7 and 6 are both set (off left and right) or 5 and 4 (off
; top and bottom)
;
; A = the clip bits made by ActorScreenBox `$8F75` (bit 7: the box starts past
; the right edge, bit 6: it ends past it, bit 5: it starts above the top, bit
; 4: it ends below the bottom). Z when (A AND `$C0`) = `$C0` or (A AND `$30`) =
; `$30`: nothing of the box is inside the window. L = the bits on return.
; Callers: ActorUpdate `$8E48` (with `$69DD`), ActorOffWindow `$8E95`.
;
; Witness: L1 261190 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
ClipFlagsOff:
  LD DE,$C030             ; D = $C0, E = $30: two masks, not an address
  LD L,A
  AND D
  CP D
  RET Z
  LD A,L
  AND E
  CP E
  RET

; HL = $D104 + (A - 1) x 24: the 24-byte record of graphic A
;
; A = a 1-based number; DE kept. Used by the render (`$89D9`, `$8A06`) to find
; a sprite's record in the table at `$D104` (24 bytes a record; the render
; reads it).
;
; Witness: L1 549398 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
FrameRecord:
  DEC A
  LD H,$00
  LD L,A
  PUSH DE
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  LD E,L
  LD D,H
  ADD HL,HL
  ADD HL,DE
  LD DE,Tiles
  ADD HL,DE
  POP DE
  RET

; A = the room-cell index of the pixel at Y = L, X = H
;
; The play window is a grid of 20 columns of 8 pixels and rows of 16 pixels;
; RowBase `$7000` holds the index of each row's first cell (0, 20, 40 ...
; `$DC`). A = RowBase[L / 16] + H / 8. H is left `$70`. The index reads the
; room's cell arrays (`$6700`, `$6800`, `$6A00`) in the collision code.
; Callers: `$9C5B`, `$9C82`, `$9D81`, `$9E4C`.
;
; Witness: L1 192856 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
CellIndex:
  LD A,H
  RRA
  RRA
  RRA
  AND $1F
  LD H,$70
  SRL L
  SRL L
  SRL L
  SRL L
  ADD A,(HL)
  RET

; DE = the pixel corner of the cell $69E2 (the last cell CellIndex probed by
; $9E3E)
;
; Falls into CellPixel `$8ECA` with A = `$69E2`. Callers: `$965F`, `$9F29`.
;
; Witness: L1 108 (bossgate, play48, throw, rzx x31, rzxroom x4).
LastCellPixel:
  LD A,(Strike+$0001)

; Cell index A -> D = X (column x 8), E = Y (row x 16) of its top-left pixel
;
; Divides A by 20 by repeated subtraction (E counts from `$FF`). Caller:
; `$A5BF` (the room spawner), and LastCellPixel `$8EC7`.
;
; Witness: L1 645 (bossgate, deaths, gameover, hiscore, play48, rooms, throw, c
; x1, poke-room x13, rzx x63, rzxroom x18).
CellPixel:
  LD DE,$14FF             ; D = 20 (the row width), E = -1
CellPixelDivide:
  INC E
  SUB D
  JR NC,CellPixelDivide
  ADD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  LD D,A
  LD A,E
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  LD E,A
  RET

; HL = H x E (8 by 8 bits, shift and add)
;
; H and E unsigned; D is cleared, L ignored. Unrolled: eight `ADD HL,HL` / `ADD
; HL,DE` steps. Callers: the render `$8A90`, `$8B6A`, `$A0EE`, `$A91B`.
;
; Witness: L1 239246 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x72, rzxroom x19).
Multiply8:
  LD L,$00
  LD D,L
  ADD HL,HL
  JR NC,Multiply8Bit6
  ADD HL,DE
Multiply8Bit6:
  ADD HL,HL
  JR NC,Multiply8Bit5
  ADD HL,DE
Multiply8Bit5:
  ADD HL,HL
  JR NC,Multiply8Bit4
  ADD HL,DE
Multiply8Bit4:
  ADD HL,HL
  JR NC,Multiply8Bit3
  ADD HL,DE
Multiply8Bit3:
  ADD HL,HL
  JR NC,Multiply8Bit2
  ADD HL,DE
Multiply8Bit2:
  ADD HL,HL
  JR NC,Multiply8Bit1
  ADD HL,DE
Multiply8Bit1:
  ADD HL,HL
  JR NC,Multiply8Bit0
  ADD HL,DE
Multiply8Bit0:
  ADD HL,HL
  JR NC,Multiply8Done
  ADD HL,DE
Multiply8Done:
  RET

  ORG $9A4B

; Run the next due actor step: page $66 or the boss's shot, Hiro, the fallers,
; actor H
;
; Called by the actor update `$8E2B` with H = an active actor's page (562 575
; runs). IY = that page.
;
; Every other call (the operand at `$9A51` rotates `$AA`) page `$66` (Hiro's
; thrown weapon or the message banner) steps when it is active and due (the
; cyber-arm's shot moves at twice the rate); on the calls between, when a boss
; fight is on (`$9A59`), the actor in page `$60` (the boss's shot, BossFire).
; Bit 7 of `$6602` (the banner) stops here. Then Hiro when due; then every page
; `$5E-$65` that is falling (+2 bit 2) and due; then actor H when due. Each
; "due" step (`$9A8E`) pops its caller's return, so the call ends after one
; step.
;
; Witness: L1 3898691 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
RunActorSteps:
  LD L,$00
  PUSH HL
  POP IY
  LD A,$AA                ; LD A,n: n rotates $AA, one call in two
  RLCA
  LD (RunActorSteps+$0006),A
  JR C,StepBulletPage
  LD A,$00                ; LD A,n: n = the boss kind, 0 when no boss fight
                          ; (SpawnActor $A69D, KillActor $97BA, $A47A)
  OR A
  JR Z,StepHiroFirst
  LD D,$60                ; the boss's shot in page $60
  CALL StepIfActive
  JR StepHiroFirst
StepBulletPage:
  LD D,$66                ; page $66: Hiro's weapon or the banner
  CALL StepIfActive
StepHiroFirst:
  LD DE,WeaponActor+$0002 ; $6602 bit 7: no more this call
  LD A,(DE)
  RLA
  RET C
  LD D,$5D                ; Hiro
  CALL StepIfDue
  INC D
  LD B,$08                ; the eight others that are falling
StepFallersLoop:
  LD E,$02
  LD A,(DE)
  AND $04
  CALL NZ,StepIfDue
  INC D
  DJNZ StepFallersLoop
  XOR A                   ; actor H itself, when due
  LD L,$1D
  OR (HL)
  RET NZ
  JR StepActor

; Step page D when it is active and due
;
; Witness: L1 2054144 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
StepIfActive:
  LD E,$02
  LD A,(DE)
  RRA
  RET NC

; Step page D when its frame timer +$1D is zero
;
; Pops the caller's return (the call of RunActorSteps ends with this step), IY
; = HL = page D, falls into StepActor.
;
; Witness: L1 3977795 (bossgate, deaths, gameover, havok, hiscore, menu,
; play48, rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
StepIfDue:
  LD E,$1D
  LD A,(DE)
  OR A
  RET NZ
  POP BC
  EX DE,HL
  LD L,A
  PUSH HL
  POP IY

; One step of actor IY: the hold, the action slots, the falls, hurts and ends,
; the handler
;
; HL = IY = the actor. 8295 runs. The frame timer +$1D = the delay +$1A.
;
; **Hold** (+$28): counted down, the step waits that many frames; when it ends
; and +$0E holds an animation, `JP $9087` (the actor turns towards Hiro and
; starts it: rooms, 3 runs).
;
; StartLifetime `$9987`; the flag at `$9BE9` cleared.
;
; **The action slots** +$30-$38: the first that is not 0 runs its handler from
; the table `$73E7` (+$30 `$921C` the jump, +$31 `$9238`, +$32 `$91EE`, +$33
; `$91E1`, +$34 `$91F4` the combat move, +$35 `$920A` the fall damage, +$36
; `$9215`, +$37 `$91A9` the end, +$38 `$91D4`).
;
; Else: in the air (+2 bit 1) FallStep `$9CD9`; hurt (+$10 bit 4) `$904A`;
; expired (bit 5) `$9163`; bit 2 `$90A6`; Hiro with a combat move pending
; (`$6650`) `$926E`; else the handler at +3/+4 (RunHandler `$9AEC`).
;
; Witness: L1 277931 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
StepActor:
  LD L,$1A                ; the frame delay again
  LD E,(HL)
  LD L,$1D
  LD (HL),E
  LD L,$28                ; +$28: holding
  OR (HL)
  JR Z,StepActorSlots
  DEC (HL)
  JR Z,HoldExpired
  LD A,(HL)
  LD L,$1D
  LD (HL),A
  RET
HoldExpired:
  XOR A                   ; a wake animation in +$0E?
  LD L,$0E
  OR (HL)
  JP NZ,TurnToHiro
StepActorSlots:
  CALL StartLifetime      ; the kind's bit 7: its lifetime starts
  LD (AnimateFrame+$001A),A ; the slow-walk flag off
  LD DE,ActorKindHandlers ; the slot table $73E7 (DE + 2 first)
  LD L,$2F
  LD B,$09
FindSlotLoop:
  INC E
  INC E
  INC L
  OR (HL)
  JR NZ,RunSlotHandler
  DJNZ FindSlotLoop
  LD L,$02                ; in the air: fall
  BIT 1,(HL)
  JP NZ,FallStep
  LD L,$10                ; hurt
  BIT 4,(HL)
  JP NZ,FallSequenceStart
  BIT 5,(HL)              ; expired: its end
  JP NZ,ActorExpired
  BIT 2,(HL)              ; bit 2
  JP NZ,StartHurtSeq
  LD A,H                  ; Hiro: a combat move pending?
  CP $5D
  JR NZ,RunHandler
  LD A,(FireRequest)
  OR A
  JP NZ,HiroAttack

; Jump to the actor's behaviour handler at +3/+4
;
; Reached from StepActor and by `JP $9AEC` from `$920A`, `$926E` (and the
; handler `$9216`). The handler runs with HL = IY = the actor.
;
; Witness: L1 234521 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
RunHandler:
  LD L,$03
  LD C,(HL)
  INC L
  LD B,(HL)

; JP (BC)
;
; Witness: L1 262694 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x71, rzxroom x18).
JumpToHandler:
  PUSH BC
  POP IX
  JP (IX)
; This entry point is used by the routine at StepActor.
RunSlotHandler:
  EX DE,HL                ; BC = the slot's handler from the table
  LD C,(HL)
  INC L
  LD B,(HL)
  EX DE,HL
  JR JumpToHandler

  ORG $A652

; DE = the actor template of kind A (the word table at $7200)
;
; DE = the word at `$7200` + 2 (A AND `$7F`). Callers: `$926E`, `$98B6`,
; `$9ED7`, SpawnEnemy. 22 runs.
;
; Witness: L1 775 (bossgate, deaths, gameover, hiscore, play48, rooms, throw, c
; x1, poke-room x13, rzx x65, rzxroom x18).
TemplateForKind:
  AND $7F
  LD H,$72
  LD L,A
  RL L
  LD E,(HL)
  INC L
  LD D,(HL)
  RET

; Set up an actor page from an 18-byte template
;
; In: HL = the page (L ignored), C = Y, B = X, DE = the template, A = the kind.
; +0 Y, +1 X; `+$1C-$41` cleared; the template to +3-+`$14`; its last byte
; (+`$14`) is the frame: CopyFrameRecord `$A6D8` copies the frame's 5 bytes
; from `$6082` + 5 x frame to +`$15-$19`; +`$1A` = +`$1B` = 1; +`$3C` = the
; frame (the base); +2 = `$81` for kind `$2A`, else 1 (active); +`$1C` = the
; kind. Kinds `$25-$29` are kept in `$9A59` (read by the energy reload
; `$9615`).
;
; Out: DE = page + `$1C`, A = the kind. Callers: `$5C68` (Hiro at the start),
; `$926E`, `$947D`, `$965F`, `$9962`, `$9ED7`, SpawnEnemy, the title
; (LoadTitlePieces `$A7D7`). 899 runs (every recording).
;
; Witness: L1 2229 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x13, rzx x71, rzxroom x19).
InitActor:
  PUSH AF
  PUSH DE
  LD L,$00
  LD (HL),C
  INC L
  LD (HL),B
  LD L,$1C
  LD B,$26
  XOR A
InitActorClear:
  LD (HL),A
  INC L
  DJNZ InitActorClear
  LD D,H
  LD E,$03
  POP HL
  LD BC,$0012
  LDIR
  DEC HL
  LD A,(HL)
  CALL CopyFrameRecord
  LD A,$01
  LD (DE),A
  INC E
  LD (DE),A
  LD E,$14
  LD A,(DE)
  LD E,$3C
  LD (DE),A
  POP AF
  PUSH AF
  CP $2A
  LD A,$81
  JR Z,InitActorFlags
  LD A,$01
InitActorFlags:
  LD E,$02
  LD (DE),A
  POP AF
  LD E,$1C
  LD (DE),A
  CP $25
  RET C
  CP $2A
  RET NC
  LD (RunActorSteps+$000E),A
  RET

; Undo the X offset of the last frame step and show the base frame
;
; X (+1) -= +`$3D`, +`$3D` = 0; A = +`$3C` (the base frame); joins
; SetActorFrame `$A6D0`. Callers: `$9201`, `$9240`. 219 runs.
;
; Witness: L1 4446 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
ActorFrameBack:
  LD L,$3D
  LD A,(HL)
  LD (HL),$00
  NEG
  LD L,$01
  ADD A,(HL)
  LD (HL),A
  LD L,$3C
  LD A,(HL)
  JR SetActorFrame

; Show a frame from a 3-byte step at BC: X offset (by facing) and the frame
;
; +`$3D` = X; bit 7 of +`$1B` picks the first or the second byte as the X
; offset; X += it, +`$3D` = the offset; the third byte is the frame; BC moves
; past the step. Joins SetActorFrame. Caller: `$919F`. 284 runs.
;
; Witness: L1 6615 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
ActorFrameStep:
  LD L,$01
  LD A,(HL)
  LD L,$3D
  LD (HL),A
  LD L,$1B
  LD A,(HL)
  RLA
  LD L,$01
  JR NC,ActorFrameStepRight
  LD A,(BC)
  INC BC
  JR ActorFrameStepApply
ActorFrameStepRight:
  INC BC
  LD A,(BC)
ActorFrameStepApply:
  LD E,A
  ADD A,(HL)
  LD L,$3D
  LD (HL),E
  LD L,$01
  LD (HL),A
  INC BC
  LD A,(BC)
  INC BC

; +$14 = frame A, its 5-byte record to +$15
;
; Witness: L1 11061 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x1, opt x3, poke-room x15, rzx x70, rzxroom x18).
SetActorFrame:
  LD L,$14
  LD (HL),A
  PUSH HL
  EX DE,HL
  INC DE
  JR CopyFrameRecordBody

; Copy the 5 bytes of frame A from $6082 + 5A to DE
;
; HL and BC kept. 899 runs.
;
; Witness: L1 2229 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x13, rzx x71, rzxroom x19).
CopyFrameRecord:
  PUSH HL

; The copy itself (SetActorFrame joins here with HL already pushed)
;
; Witness: L1 13290 (bossgate, deaths, gameover, havok, hiscore, menu, play48,
; rooms, throw, c x2, opt x3, poke-room x15, rzx x71, rzxroom x19).
CopyFrameRecordBody:
  PUSH BC
  LD HL,SizeClasses
  LD BC,$0005
  OR A
  JR Z,CopyFrameRecordCopy
CopyFrameRecordStep:
  ADD HL,BC
  DEC A
  JR NZ,CopyFrameRecordStep
CopyFrameRecordCopy:
  LDIR
  POP BC
  POP HL
  RET
