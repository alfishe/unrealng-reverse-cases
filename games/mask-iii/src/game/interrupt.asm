; --------------------------------------------------------------------------------------------------------------------
; interrupt.asm: The interrupt and the main loop
;
; The game runs free in its main loop MainLoop $CC03 (2.5-5.4 frames a pass, no HALT); everything that must keep time
; runs in the interrupt Interrupt $9226: the key reading (in the menu MenuInterrupt $9899), the AY music and effects
; on a 128K or the beeper effect on a 48K, the message scroller and the BREAK check.
; --------------------------------------------------------------------------------------------------------------------

; The IM 2 handler (via ImJump $FFF4): keys or menu, music and effects,
; scroller, BREAK
;
; Saves every register; FrameCounter $9224 + 1, OUT BorderColour. In play
; (MenuFlag $970E = 0) CheatCheck $BB4C; in the menu MenuInterrupt $9899. On a
; 128K (MachineFlag $FFFE = 0): pages RAM 4 ($7FFD = $14), starts TuneRequest
; $9222 (MusicStart) or StopRequest $9223 (MusicStop), runs StopEffects $946F
; and StartEffects $9421, MusicPlay $C003; in the menu (NotInPlay $970D) it
; restarts tune 1 when MusicTune ends; pages RAM 0 back ($10). On a 48K:
; StopBeeper $949F and BeeperTick $94C8. In play: Scroller $AF82, and CAPS
; SHIFT + SPACE (BREAK) aborts to GameStart $CBF9.
;
; Witness: L1 53798 (c1, door, play2, rzx- x10).
Interrupt:
  PUSH AF
  EX AF,AF'
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH BC
  EXX
  PUSH HL
  PUSH DE
  PUSH BC
  PUSH IX
  PUSH IY
  LD HL,FrameCounter
  INC (HL)
  LD A,(BorderColour)
  OUT ($FE),A
  LD A,(MenuFlag)
  AND A
  CALL Z,CheatCheck
  CALL NZ,MenuInterrupt
  LD A,(MachineFlag)
  AND A
  JR NZ,l_9291
  LD BC,$7FFD
  LD A,$14
  OUT (C),A
  LD A,(TuneRequest)
  AND A
  JR Z,l_9262
  DEC A
  CALL MusicStart
  XOR A
  LD (TuneRequest),A
l_9262:
  LD A,(StopRequest)
  AND A
  JR Z,l_926F
  CALL MusicStop
  XOR A
  LD (StopRequest),A
l_926F:
  CALL StopEffects
  CALL StartEffects
  CALL MusicPlay
  LD A,(NotInPlay)
  AND A
  JR Z,l_9288
  LD A,(MusicTune)
  CP $FF
  LD A,$00
  CALL NZ,MusicStart
l_9288:
  LD BC,$7FFD
  LD A,$10
  OUT (C),A
  JR l_9297
l_9291:
  CALL StopBeeper
  CALL BeeperTick
l_9297:
  LD A,(NotInPlay)
  AND A
  CALL Z,Scroller
  LD A,(NotInPlay)
  AND A
  JR NZ,l_92B3
  LD A,$7F
  IN A,($FE)
  LD L,A
  LD A,$FE
  IN A,($FE)
  OR L
  BIT 0,A
  JP Z,GameStart
l_92B3:
  POP IY
  POP IX
  POP BC
  POP DE
  POP HL
  EXX
  POP BC
  POP DE
  POP HL
  POP AF
  EX AF,AF'
  POP AF
  EI
  RET

; Random's three bytes of state
RandomSeed:
  DEFB $00,$00,$00

; A = a pseudo-random byte from RandomSeed and R
;
; Witness: L1 85196 (c1, door, play2, rzx- x10).
Random:
  PUSH HL
  PUSH DE
  LD HL,RandomSeed
  LD A,(HL)
  ADD A,$2D
  RRCA
  LD (HL),A
  LD E,A
  INC HL
  LD A,(HL)
  SUB $8D
  LD (HL),A
  ADD A,E
  INC HL
  RLCA
  RRC (HL)
  ADD A,(HL)
  LD (HL),A
  POP DE
  POP HL
  RET

; The 18 sound effects, 14 bytes each: the AY channel data, the channel choice
; (+$0A), the beeper pitch and length
;
; PlayEffect $93DC picks record A; on a 128K bytes +$0B-+$0D go to the effect
; channel blocks of the player, on a 48K the record drives BeeperTick $94C8.
; The CSV is src/res/tables/effects.csv.
EffectTable:
  INCBIN "res/tables/effects.bin",$0000,252

; Start sound effect A: an AY channel slot on a 128K, the beeper on a 48K
;
; 128K: record + $0A picks the slot (1 EffectSlotA $941B, 2 $941D, else $941F)
; that StartEffects $9421 reads at the next interrupt. 48K: BeeperStart $94AF.
;
; Witness: L1 554 (c1, door, play2, rzx- x9).
PlayEffect:
  PUSH AF
  PUSH HL
  PUSH DE
  PUSH IX
  LD L,A
  LD E,A
  LD H,$00
  LD D,H
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  ADD HL,DE
  ADD HL,HL
  LD DE,EffectTable
  ADD HL,DE
  PUSH HL
  POP IX
  LD A,(MachineFlag)
  AND A
  JR NZ,l_9416
  LD A,(IX+$0A)
  CP $01
  JR NZ,l_9404
  LD (EffectSlots),HL
  JR l_9410
l_9404:
  CP $02
  JR NZ,l_940D
  LD (EffectSlots+$0002),HL
  JR l_9410
l_940D:
  LD (EffectSlots+$0004),HL
l_9410:
  POP IX
  POP DE
  POP HL
  POP AF
  RET
l_9416:
  CALL BeeperRecord+$0001
  JR l_9410

; Three slots of (flag, record) for channels A, B and C
EffectSlots:
  DEFB $00,$00,$00,$00,$00,$00

; Interrupt, 128K: hand each waiting effect to the AY player (EffectStart with
; IX = the channel block)
;
; Witness: L1 16624 (c1, door, play2).
StartEffects:
  LD HL,(EffectSlots)
  LD A,H
  OR L
  JR Z,l_9441
  PUSH HL
  POP IY
  LD IX,EffectChannelA
  LD HL,$0000
  LD (EffectSlots),HL
l_9435:
  LD C,(IY+$0B)
  LD L,(IY+$0C)
  LD H,(IY+$0D)
  JP EffectStart
l_9441:
  LD HL,(EffectSlots+$0002)
  LD A,H
  OR L
  JR Z,l_9457
  PUSH HL
  POP IY
  LD IX,EffectChannelB
  LD HL,$0000
  LD (EffectSlots+$0002),HL
  JR l_9435
l_9457:
  LD HL,(EffectSlots+$0004)
  LD A,H
  OR L
  RET Z
  PUSH HL
  POP IY
  LD IX,EffectChannelC
  LD HL,$0000
  LD (EffectSlots+$0004),HL
  JR l_9435

; Three flags: stop the effect of channel A, B, C at the next interrupt
EffectStops:
  DEFB $00,$00,$00

; Interrupt, 128K: silence each channel whose EffectStops flag is set (writes
; the player's block +6)
;
; Witness: L1 16624 (c1, door, play2).
StopEffects:
  LD A,(EffectStops)
  AND A
  JR Z,l_947F
  XOR A
  LD (EffectChannelA+6),A
  LD (EffectStops),A
  LD (BeeperState),A
l_947F:
  LD A,(EffectStops+$0001)
  AND A
  JR Z,l_948F
  XOR A
  LD (EffectChannelB+6),A
  LD (EffectStops+$0001),A
  LD (BeeperState),A
l_948F:
  LD A,(EffectStops+$0002)
  AND A
  RET NZ
  XOR A
  LD (EffectChannelC+6),A
  LD (EffectStops+$0002),A
  LD (BeeperState),A
  RET

; Interrupt, 48K: the beeper's version of StopEffects
;
; Witness: L1 37174 (rzx- x10).
StopBeeper:
  LD HL,EffectStops
  LD A,(HL)
  AND A
  RET Z
  XOR A
  LD (BeeperState),A
  LD (HL),A
  RET

; The beeper effect: count, pitch, and the record pointer at $94AE that
; BeeperStart's own first instruction overwrites
;
; BeeperStart at $94AF begins with the byte $DD of LD ($94AE),IX: the
; instruction stores the record's address over $94AE-$94AF, its own prefix.
; After the first effect the byte at $94AF is the record's high byte, so later
; calls run it as another instruction (SUB D or SUB E for the records at
; $92xx-$93xx) and then LD ($94AE),HL at $94B0: the store still happens. mkgame
; keeps $94AB-$94AF as data and the code from $94B0 (known from the code and
; the 48K recording work/stage2/rec/c48).
BeeperState:
  DEFB $00,$00,$00
BeeperRecord:
  DEFB $00,$DD            ; the record pointer (its high byte is BeeperStart's
                          ; first byte)

; 48K: LD ($94AE),HL and the effect's count and pitch (entered at $94AF)
;
; Witness: L1 541 (rzx- x9).
BeeperStart:
  LD (BeeperRecord),HL
  LD A,(IX+$0B)
  LD (BeeperState),A
  LD L,(IX+$0C)
  LD H,(IX+$0D)
  LD (BeeperState+$0001),HL
  RET

; Never run: clear the beeper count
;
; Known only from the code.
BeeperOff:
  XOR A
  LD (BeeperState),A
  RET

; Interrupt, 48K: one burst of the beeper effect on bits 3-4 of port $FE
;
; Witness: L1 37174 (rzx- x10).
BeeperTick:
  LD A,(BeeperState)
  AND A
  RET Z
  CP $FF
  JR Z,l_94D5
  DEC A
  LD (BeeperState),A
l_94D5:
  LD IX,(BeeperRecord)
  LD HL,(BeeperState+$0001)
  LD E,(IX+$07)
  LD D,(IX+$08)
  ADD HL,DE
  LD (BeeperState+$0001),HL
  XOR A
  SUB L
  SRL A
  SRL A
  SRL A
  SRL A
  SRL A
  INC A
  LD B,A
l_94F4:
  LD A,(BorderColour)
  OR $18
  OUT ($FE),A
  LD H,L
l_94FC:
  DEC H
  JR NZ,l_94FC
  LD A,(BorderColour)
  OUT ($FE),A
  LD H,L
l_9505:
  JR NZ,l_9505
  DJNZ l_94F4
  RET

  ORG $CBF9

; The menu, a new game, then the main loop
;
; Witness: L1 16 (c1, play2, rzx- x8).
GameStart:
  LD SP,StackTop
  EI
  CALL Menu
  CALL NewGame
MainLoop:
  CALL ReadControls       ; one pass: controls, Matt, shot, hazards, objects,
                          ; fire, mask keys, score, death, energy, slot,
                          ; animation, draw
  CALL MattStep
  CALL MoveShot
  CALL Hazards
  CALL RunObjects
  CALL FireMask
  CALL MaskKeys
  CALL DrawScore
  LD A,(DeathFlag)
  AND A
  JP NZ,Death
  LD A,(Energy)
  AND A
  JR NZ,l_CC41
  LD A,(Objects)
  CP $09
  JR Z,l_CC41
  LD A,$09
  LD (Objects),A
  LD A,$32
  LD (Objects+$0010),A
  LD A,$01
  LD (DissolveCount),A
  LD (Dying),A
l_CC41:
  CALL DrawEnergyBar
  CALL DrawCurrentSlot
  CALL AnimateZone
  CALL DrawObjects
  LD HL,PassCounter
  INC (HL)
  LD HL,PassBcd
  LD A,(HL)
  ADD A,$01
  DAA
  LD (HL),A
  JP MainLoop

; A BCD pass counter (bit 0 times PENETRATOR's charges and the turret's bob)
PassBcd:
  DEFB $00

; 35 zero bytes no routine reads
PassBcdSpare:
  DEFS $23
