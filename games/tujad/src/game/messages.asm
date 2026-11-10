; --------------------------------------------------------------------------------------------------------------------
; messages.asm: The scroller's messages
;
; A message is a priority byte and its text, upper case, ending in '.'. QueueMessage $6ACD takes a message only when
; its priority is above the one shown (ScrollPriority); the interrupt's scroller $9640 scrolls it up a pixel line at a
; time, 19 characters a row, through the window at $402C (so the texts are padded to rows of 19). The editable form is
; src/res/text/Messages.txt (one message a line: the priority, a tab, the text).
; --------------------------------------------------------------------------------------------------------------------

; The ten messages: a priority byte, the text, '.'
;
; Readers: QueueMessage $6ACD (the priority), the interrupt's scroller $96A0
; (the text: L1 reads $63D2-$65AD). Queued by: Restart $690A (TUJAD FROM
; ORPHEUS), WinTest $69F3 (EDS COMPLETED), EnergyTick $7AC9 (WARNING ENERGY
; LOW), the pickups $7687 / $766A / $7671 (ENERGY SOURCE ABSORBED, WEAPON
; LOCATED AND STORED, GEN 19 COLLECTED), Teleport $778B (TRANSPORTING),
; LoseLife $6A51 (GEN 19 DESTROYED), the win $6A10 (CONGRATULATIONS) and the
; game over $6A94 (COMPUTER MALFUNCTION).
Messages:
  INCBIN "res/text/Messages.bin",$0000,21
MsgEdsCompleted:
  INCBIN "res/text/Messages.bin",$0015,59
MsgEnergyLow:
  INCBIN "res/text/Messages.bin",$0050,21
MsgEnergyAbsorbed:
  INCBIN "res/text/Messages.bin",$0065,40
MsgTransporting:
  INCBIN "res/text/Messages.bin",$008D,21
MsgWeaponStored:
  INCBIN "res/text/Messages.bin",$00A2,40
MsgGenCollected:
  INCBIN "res/text/Messages.bin",$00CA,21
MsgGenDestroyed:
  INCBIN "res/text/Messages.bin",$00DF,21
MsgCongratulations:
  INCBIN "res/text/Messages.bin",$00F4,135
MsgMalfunction:
  INCBIN "res/text/Messages.bin",$017B,97
