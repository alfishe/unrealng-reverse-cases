; --------------------------------------------------------------------------------------------------------------------
; viewbuffer.asm: The tail of the view's back buffer, $6590-$677F: the first bytes of the file
;
; The view's back buffer is $5B00-$677F (160 lines of 20 bytes, ViewBuffer): the isometric view is composed there
; every game turn and copied to the screen in one go. The file neart001 starts at $6590, inside it, so its last 496
; bytes are this entry; the rest lies below the file and is written by the game before any read (ClearViewBuffer).
; Line N is at ViewBuffer + 20 x N; this tail holds lines 135 (from its 4th byte) to 159.
;
; The loader neart022 runs at $61A8-$6508, inside the same buffer: once the game starts, the first ClearViewBuffer
; wipes it. Other users of the buffer: ShowRobotDesign (the construction menu's robot preview at $6168), NuclearFlash
; (the view's attributes at $5B00-$5C8F), SaveGameBlocks / LoadGameBlocks (the 2-byte sum at $5B00). The font index
; PrintChar uses, $6680 + 8 x code, starts inside this tail.
; --------------------------------------------------------------------------------------------------------------------

; The view buffer's lines 135-159, the bytes the file holds
;
; In the file: zeros to $6731, then 78 bytes of leftovers from Nether Earth's
; own tape load ($6732-$677F: ROM addresses and a BASIC stack copy, as the game
; block carried them). ClearViewBuffer zeroes them before the first view;
; nothing reads them first.
ViewBufferTail:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; lines
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 136-143,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; screen row
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 18
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; lines
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 144-151,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; screen row
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 19
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; lines
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 152-159,
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; screen row
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; 20; $6732
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00 ; on:
  DEFB $00,$00,$E0,$57,$71,$0E,$00,$01,$30,$0D,$DB,$02,$4D,$00,$B7,$5C ; leftovers
  DEFB $F3,$0D,$CE,$0B,$E6,$50,$CE,$0B,$E7,$50,$1A,$16,$DC,$0A,$CE,$0B ; of a tape
  DEFB $ED,$50,$14,$16,$DC,$0A,$DB,$02,$4D,$00,$08,$5C,$5C,$00,$F3,$0D ; load
  DEFB $B7,$2D,$E9,$5C,$E4,$5C,$58,$FF,$2B,$2D,$65,$33,$58,$27,$ED,$10
  DEFB $0D,$00,$09,$00,$85,$1C,$10,$1C,$52,$1B,$76,$1B,$03,$13,$00,$3E
