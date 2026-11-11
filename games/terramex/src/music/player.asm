; --------------------------------------------------------------------------------------------------------------------
; player.asm: The player's entry, the start and the end of a tune, the frame update
;
; MusicFrame $C000 is the only entry the game uses: the IM 2 handler $9491 pages RAM 6 ($7FFD = $16) and calls it at
; every interrupt when Has128K $5FFE is not 0 (no music on a 48K), from GameEntry $8F00 on (c1: GameEntry frame 21597,
; the first call frame 21599) through the selector, the play, the game over and the ending. MusicTick $C014 starts
; tune 0 (StartTune $C79F) when PlayerState $C027 is 0, else runs UpdateTune $C1E4. The image's PlayerState is 0, so
; the first call starts tune 0; EndTune $C780 sets it to 0 at the tune's end, so the next call starts tune 0 again.
;
; Who selects a tune: nobody. StartTune takes the tune number in A, but its only caller is the JP Z at $C018 with A =
; 0, and no code outside RAM 6 writes PlayerState, TuneNumberOp+1 or TunePointer (the game's only calls into $C000 are
; $94A0, the music, and $8F5E, which pages RAM 1 and calls the explorer selector). So Terramex plays tune 0 and only
; tune 0, in a loop of 9698 frames (9696 frames of notes, the end frame and the start frame; 3 min 14 s at 50 Hz):
; EndTune ran at frames 9581 (explorers), 1676 (r08000), 1374 (r18000), 1072 (r28000), 770 (r38000), 468 (r48000),
; 9698 frames apart through the RZX run. The tune table has four entries: 0, 2 and 3 are the same tune, 1 is a shorter
; tune made of tune 0's second half (known only from the code).
;
; Sound effects: the player plays none. Its AY writes are the only ones in the 34 recordings after the ROM's power-on
; set-up (AYWrite $CD56 is the one routine with ports $FFFD / $BFFD); the game's effects are beeper sounds through
; port $FE (the game's sound module).
;
; A frame (UpdateTune): for each channel whose note timer is 1 the note ends now (timer 0, NoteEndFlag $C14D up); then
; channels A, B and C in turn (UpdateChannel $C2E4 with IX = the channel record, DE = its pattern, the four self-
; modified order-list operands and SlotRowOp set for the channel); then WriteAY $C290, except on a frame where a note
; ended (NoteEndFlag not 0: the AY keeps the last frame's values and no channel runs its effects). 3590 T-states a
; frame on average (explorers: 54 533 870 T-states in 15 190 calls).
; --------------------------------------------------------------------------------------------------------------------

; Play one frame of music: the IM 2 handler's call
;
; Saves AF (in AF'), AF', DE, HL, IX and IY around MusicTick $C014 and returns
; with them. BC is not saved: the caller, the IM 2 handler $9491, saves it
; (PUSH BC at $9498) and pages RAM 6 before the CALL $C000 at $94A0 and the old
; page ($5FE5 Last7FFD) after it.
;
; Called once a frame: c1 runs it 5029 times in the 5029 frames from 21599 to
; 26627; explorers 15 190 of 15 190, gameover 6000 of 6000.
;
; Witness: L1 83616 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
MusicFrame:
  EX AF,AF'
  PUSH AF
  PUSH DE
  PUSH HL
  PUSH IX
  PUSH IY
  CALL MusicTick
  POP IY
  POP IX
  POP HL
  POP DE
  POP AF
  EX AF,AF'
  RET

; Start tune 0 if no tune is playing, else play one frame of it
;
; PlayerState $C027 = 0: JP StartTune $C79F with A = 0 (the tune number), which
; returns to MusicFrame. Else UpdateTune $C1E4 with IY saved.
;
; c1 runs StartTune once (frame 21599, the first call after GameEntry);
; explorers and the rzx pieces once after each EndTune.
;
; Witness: L1 83616 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
MusicTick:
  LD A,(PlayerState)
  OR A
  JP Z,StartTune          ; A = 0 here: the only tune StartTune is ever given
  PUSH IY
  LD IY,$0000             ; IY = 0: not read; SetInstrument $C3D8 sets IY
                          ; before every use
  CALL UpdateTune
  POP IY
  RET

  ORG $C1E4

; Play one frame of the tune: end the expiring notes, update channels A, B and
; C, write the AY
;
; Called by MusicTick $C014 while PlayerState $C027 is 1 (the RET Z at $C1E8 is
; a second guard: it never returns there in any recording).
;
; First, for each channel whose note timer (+$03) is 1: the timer becomes 0 and
; NoteEndFlag $C14D goes up, so the note lasts exactly its duration in frames
; and the channel reads its next event this frame. Then for each channel n = 0,
; 1, 2: ChannelIndex $C1E3 = n, SlotRowOp+1 = 8n, IX = the channel's record,
; the word n of the tune's entry (TunePointer $C14B) into the operands of
; OrderListOp1 $C315, OrderListOp2 $C7D6, OrderListOp3 $C7E9 and OrderListOp4
; $C807, DE = PatternPointers[n]; CALL UpdateChannel $C2E4. Last, H = $FF and L
; = $BF (the high bytes of the AY ports $FFFD and $BFFD), C = $FD, and WriteAY
; $C290 unless NoteEndFlag is up.
;
; Out: the channel records, PatternPointers and the AY registers updated,
; NoteEndFlag 0. When channel A meets its order list's end, EndTune $C780 drops
; UpdateChannel's return, so channels B and C are not updated that frame.
;
; Witness: L1 83609 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
UpdateTune:
  LD A,(PlayerState)
  OR A
  RET Z
  LD HL,NoteEndFlag       ; HL = NoteEndFlag
  LD A,(ChannelATimer)    ; channel A's timer 1: 0, and the flag up
  DEC A
  JR NZ,UpdateTuneB
  LD (ChannelATimer),A
  INC (HL)
UpdateTuneB:
  LD A,(ChannelBTimer)    ; channel B's timer
  DEC A
  JR NZ,UpdateTuneC
  LD (ChannelBTimer),A
  INC (HL)
UpdateTuneC:
  LD A,(ChannelCTimer)    ; channel C's timer
  DEC A
  JR NZ,UpdateTuneChannels
  LD (ChannelCTimer),A
  INC (HL)
UpdateTuneChannels:
  XOR A                   ; channel A: index 0, slot row 0
  LD (ChannelIndex),A
  LD IX,ChannelA
  LD (SlotRowOp+$0001),A
  LD HL,(TunePointer)     ; the tune's word 0: channel A's order list, into the
                          ; four self-modified operands
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (OrderListOp1+$0001),HL
  LD (OrderListOp2+$0001),HL
  LD (OrderListOp3+$0001),HL
  LD (OrderListOp4+$0001),HL
  LD DE,(PatternPointers) ; DE = channel A's pattern
  CALL UpdateChannel
  LD IX,ChannelB          ; channel B: index 1, the tune's word 1, slot row 8
  LD A,$01
  LD (ChannelIndex),A
  LD HL,(TunePointer)
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (OrderListOp1+$0001),HL
  LD (OrderListOp2+$0001),HL
  LD (OrderListOp3+$0001),HL
  LD (OrderListOp4+$0001),HL
  LD A,$08
  LD (SlotRowOp+$0001),A
  LD DE,(PatternPointers+$0002)
  CALL UpdateChannel
  LD IX,ChannelC          ; channel C: index 2, the tune's word 2, slot row 16
  LD A,$02
  LD (ChannelIndex),A
  LD HL,(TunePointer)
  LD DE,$0004
  ADD HL,DE
  LD A,(HL)
  INC HL
  LD H,(HL)
  LD L,A
  LD (OrderListOp1+$0001),HL
  LD (OrderListOp2+$0001),HL
  LD (OrderListOp3+$0001),HL
  LD (OrderListOp4+$0001),HL
  LD A,$10
  LD (SlotRowOp+$0001),A
  LD DE,(PatternPointers+$0004)
  CALL UpdateChannel
  LD HL,$FFBF             ; the AY port high bytes in H and L, the low byte in
                          ; C
  LD C,$FD
  LD A,(NoteEndFlag)      ; a note ended this frame: no AY write
  OR A
  JR NZ,EndFrame

  ORG $C780

; The order list's $FF: silence, PlayerState 0, the AY written, the frame over
;
; From ReadOrderList $C31F. The three volumes (+$1F) 0 (each written twice),
; PlayerState $C027 = 0, UpdateChannel's return dropped (POP AF: the channels
; after this one are not updated), then WriteAY $C290 with H = $FF, L = $BF, C
; = $FD, whatever NoteEndFlag. MusicTick's next call starts tune 0 again
; (StartTune $C79F): the frame after.
;
; Ran at frame 9581 in explorers and once in r08000, r18000, r28000, r38000 and
; r48000, 9698 frames apart.
;
; Witness: L1 6 (explorers, rzx, rzx, rzx, rzx, rzx).
EndTune:
  XOR A
  LD (ChannelAVolume),A
  LD (ChannelBVolume),A
  LD (ChannelCVolume),A
  LD (ChannelAVolume),A
  LD (ChannelBVolume),A
  LD (ChannelCVolume),A
  LD (PlayerState),A
  POP AF
  LD HL,$FFBF
  LD C,$FD
  JP WriteAY

; Start tune A: its entry, the empty patterns, the channel records cleared,
; PlayerState 1
;
; A = the tune (0-3; always 0: MusicTick's JP Z at $C018 is the only way in).
; TuneNumberOp+1 = A (channel C is written only for tune 0); TunePointer $C14B
; = TuneTable $C967 + 6A; PatternPointers $C1DA = EmptyPattern $C82D for all
; three; ChannelA-ChannelC ($C153-$C1D9) zero; PlayerState $C027 = 1. A is
; kept. SlotTable, MixerImage and the AY are not touched; nothing sounds this
; frame.
;
; Ran once in c1 (frame 21599), once in explorers (9582) and after each EndTune
; in the rzx pieces.
;
; Witness: L1 7 (c1, explorers, rzx, rzx, rzx, rzx, rzx).
StartTune:
  PUSH AF
  LD (TuneNumberOp+$0001),A
  ADD A,A                 ; HL = 6 x A
  LD L,A
  ADD A,A
  ADD A,L
  LD L,A
  LD H,$00
  LD DE,TuneTable
  ADD HL,DE
  LD (TunePointer),HL
  LD HL,EmptyPattern      ; every channel on the empty pattern
  LD (PatternPointers),HL
  LD (PatternPointers+$0002),HL
  LD (PatternPointers+$0004),HL
  LD HL,ChannelA          ; the three channel records zero
  LD DE,ChannelA+$0001
  LD BC,$0086
  LD (HL),$00
  LDIR
  LD A,$01
  LD (PlayerState),A
  POP AF
  RET
