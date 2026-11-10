; --------------------------------------------------------------------------------------------------------------------
; speech.asm: The speech phrases
;
; The 33 phrases of the port $9F speech unit (SP0256-AL2 allophones), sent by PhraseInterrupt $9CC2.
; --------------------------------------------------------------------------------------------------------------------

; Leftover: the author's assembler source
;
; Never read (L1: no access); src/res/text/SourceLeftoverC8B0.txt.
SourceLeftoverC8B0:
  INCBIN "res/text/SourceLeftoverC8B0.bin",$0000,24

; The addresses of the 33 phrases, 34 zero bytes, then their (timer, allophone)
; pairs
;
; StartPhrase reads PhraseTable + 2 (N - 1). A phrase is pairs of (interrupts
; to wait, allophone), ended by $FF. Phrase 20 (the title) says "A and F
; software presents Chuckie Egg". The editable form is
; src/res/sound/Phrases.txt.
PhraseTable:
  INCBIN "res/sound/Phrases.bin",$0000,764

; 36 zeros
;
; Never read (L1: no access).
ZerosCBC4:
  DEFS $24
