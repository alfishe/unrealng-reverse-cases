; --------------------------------------------------------------------------------------------------------------------
; viewtail.asm: the tail of the view buffer the game block loads over
;
; The game block unpacks to $6731-$D7D7, so its first 79 bytes land in the last lines of ViewBuffer ($5B00-$677F, 20
; bytes x 160 lines, the play view's back buffer). ClearViewBuffer clears the whole buffer before the first view is
; drawn, so these bytes are never read: a leftover of the block's start, kept byte for byte.
; --------------------------------------------------------------------------------------------------------------------

; The last 79 bytes of ViewBuffer as the block loads them (lines 156-159, from
; byte 1 of line 156)
;
; Never read: DrawView clears ViewBuffer ($5B00-$677F) before it draws, and
; nothing else reads this part before that. A leftover of how the block was
; cut, kept as it is.
ViewBufferTail:
  DEFB $00,$E0,$57,$71,$0E,$00,$01,$30,$0D,$DB,$02,$4D,$00,$B7,$5C,$F3
  DEFB $0D,$CE,$0B,$E6,$50,$CE,$0B,$E7,$50,$1A,$16,$DC,$0A,$CE,$0B,$ED
  DEFB $50,$14,$16,$DC,$0A,$DB,$02,$4D,$00,$08,$5C,$5C,$00,$F3,$0D,$B7
  DEFB $2D,$E9,$5C,$E4,$5C,$58,$FF,$2B,$2D,$65,$33,$58,$27,$ED,$10,$0D
  DEFB $00,$09,$00,$85,$1C,$10,$1C,$52,$1B,$76,$1B,$03,$13,$00,$3E
