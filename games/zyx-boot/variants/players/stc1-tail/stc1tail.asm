; --------------------------------------------------------------------------------------------------------------------
; stc1tail.asm: The stop routine's end
;
; Stop (in the head) selects AY register 12 and jumps here with A = 0: write A and count it up to 0 again (256 writes
; of the envelope period's high byte), then select register 7 and write $FF: tone and noise off on all three channels.
; --------------------------------------------------------------------------------------------------------------------

; Write 0-255 to the selected register, then $FF to the mixer (register 7)
StopEnd:
  OUT (C),A
  INC A
  JR NZ,StopEnd
  LD B,$FF
  LD A,$07
  OUT (C),A
  LD BC,$BFFD
  LD A,$FF
  OUT (C),A
  RET
