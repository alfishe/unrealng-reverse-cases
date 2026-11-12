; --------------------------------------------------------------------------------------------------------------------
; ay.asm: The AY registers: the frame's write and the port access
;
; WriteAY $C290 writes registers 0-5 (the tone periods of A, B, C), 10 (C's volume), 7 (MixerImage $C14E), 8 and 9
; (the volumes of A and B), in that order, through AYWrite $CD56 (register select at port $FFFD, the value at $BFFD).
; Channel C's registers 4, 5 and 10 are written only for tune 0 (TuneNumberOp $C2AE: CP 1, JR NC), so a tune other
; than 0 would leave channel C free; tune 0 is the only one played. The noise period (6) and the envelope (11-13) are
; never written: noise instruments sound at the period the ROM's power-on set-up left (known only from the code).
; Volumes are 0-15, never the envelope mode bit (no peak is above 15).
; --------------------------------------------------------------------------------------------------------------------

  ORG $C290

; Write the periods, the mixer and the volumes to the AY
;
; In: H = $FF, L = $BF, C = $FD (the ports for AYWrite $CD56). Reached from
; UpdateTune $C1E4 when NoteEndFlag $C14D is 0, and from EndTune $C780 (the
; silence at the tune's end; it jumps here whatever the flag). Falls into
; EndFrame $C2DF.
;
; explorers: 13 411 writes in 15 190 frames (the other 1778 frames a note
; ended).
;
; Witness: L1 73906 (c1, explorers, gameover, rzx x31).
WriteAY:
  LD D,$00                ; registers 0 and 1: channel A's period
  LD A,(ChannelAPeriod)
  CALL AYWrite
  INC D
  LD A,(ChannelAPeriod+$0001)
  CALL AYWrite
  INC D
  LD A,(ChannelBPeriod)   ; registers 2 and 3: channel B's period
  CALL AYWrite
  INC D
  LD A,(ChannelBPeriod+$0001)
  CALL AYWrite
  INC D
TuneNumberOp:
  LD A,$00                ; LD A,n: n = the tune playing (self-modified by
                          ; StartTune $C7A0; always 0): channel C only for tune
                          ; 0
  CP $01
  JR NC,WriteAYMixer
  LD A,(ChannelCPeriod)   ; registers 4 and 5: channel C's period
  CALL AYWrite
  INC D
  LD A,(ChannelCPeriod+$0001)
  CALL AYWrite
  LD D,$0A                ; register 10: channel C's volume
  LD A,(ChannelCVolume)
  CALL AYWrite
WriteAYMixer:
  LD D,$07                ; register 7: the mixer
  LD A,(MixerImage)
  CALL AYWrite
  INC D                   ; registers 8 and 9: the volumes of A and B
  LD A,(ChannelAVolume)
  CALL AYWrite
  INC D
  LD A,(ChannelBVolume)
  CALL AYWrite

; Clear NoteEndFlag: the frame's update is over
;
; Reached by WriteAY $C290 falling in and by UpdateTune's JR NZ at $C28E (a
; frame with no AY write). Returns to MusicTick $C014, UpdateTune's caller
; (after EndTune too, which dropped UpdateChannel's return).
;
; Witness: L1 83609 (c1, explorers, gameover, rzx x31).
EndFrame:
  XOR A
  LD (NoteEndFlag),A
  RET

  ORG $CD56

; Write A to AY register D
;
; In: D = the register, A = the value, H = $FF, L = $BF, C = $FD. OUT ($FFFD),D
; selects the register, OUT ($BFFD),A writes it; B is left $BF. Called by
; WriteAY $C290 10 times a frame (7 for a tune other than 0).
;
; The recordings' only AY writer after the 128K ROM's power-on set-up
; (ports_out $FFFD, $BFFD in all 34). explorers: 134 110 calls in 13 411 writes
; (10 each).
;
; Witness: L1 739060 (c1, explorers, gameover, rzx x31).
AYWrite:
  LD B,H
  OUT (C),D
  LD B,L
  OUT (C),A
  RET
