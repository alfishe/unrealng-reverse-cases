; The objects of round 1
;
; 16 records of 8 bytes, copied into the object slots $C0B0-$C1A0 at the round
; setup: +0 type, +1,+2 position along, +3 across, +4 height, +5 direction, +6
; speed, +7 behaviour bits (docs/07-objects.md 7.1-7.4). The course record of a
; round ($CF04, 4 bytes) points here: round 1 at $F300, then 128 bytes a round.
; docs/04-game-loop.md 4.2, docs/10-gameplay-logic.md 10.2.
RoundObjects1:
  INCBIN "res/course/objects-round-01.bin",$0000,128

; The objects of round 2
RoundObjects2:
  INCBIN "res/course/objects-round-02.bin",$0000,128

; The objects of round 3
RoundObjects3:
  INCBIN "res/course/objects-round-03.bin",$0000,128

; The objects of round 4
RoundObjects4:
  INCBIN "res/course/objects-round-04.bin",$0000,128

; The objects of round 5
RoundObjects5:
  INCBIN "res/course/objects-round-05.bin",$0000,128

; The objects of round 6
RoundObjects6:
  INCBIN "res/course/objects-round-06.bin",$0000,128

; The objects of round 7
RoundObjects7:
  INCBIN "res/course/objects-round-07.bin",$0000,128

; The objects of round 8
RoundObjects8:
  INCBIN "res/course/objects-round-08.bin",$0000,128

; The objects of round 9
RoundObjects9:
  INCBIN "res/course/objects-round-09.bin",$0000,128

; The objects of round 10
RoundObjects10:
  INCBIN "res/course/objects-round-10.bin",$0000,128

; The strips under the sprites, saved
;
; $D9D6 starts the pointer $DD6A at $F800 each pass and $DD47 copies the buffer
; strips under each sprite here before the sprites are drawn; $DDC9 puts them
; back. Nothing in the image here is read before it is written: a fill pattern
; ($FA,$FC) and, toward the end, bytes that look like Z80 code that never ran.
; In the recording the strips took 980 bytes at most ($F800-$FBD3): $FBD4-$FDFC
; was never read or written. docs/06-rendering.md 6.6.
SpriteSaveBuffer:
  INCBIN "res/leftovers/sprite-save-buffer.bin",$0000,1533

; The IM 2 jump
;
; Every interrupt vector of the table $FE00-$FF00 is $FDFD. The start-up $9F4B
; writes JP $9F68 here (EI; RET) and the title player $803A writes JP $8340,
; its handler; the image holds the latter. The game proper runs with interrupts
; off. docs/02-architecture.md 2.3-2.4.
Im2Jump:
  JP TitleInterrupt

; The IM 2 vector table, then the shadow list
;
; During the title, $9F4B fills $FE00-$FF00 with $FD and sets I = $FE, so any
; bus value gives the vector $FDFD. In play the table is no longer needed and
; $D9D6 builds the shadow list at $FE64 in it (8 bytes an object), drawn by
; $DDE7 before the blit. docs/02-architecture.md 2.3, docs/06-rendering.md 6.6.
Im2Table:
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD
  DEFB $FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD,$FD

; The depth list and the sprite list, then the stack
;
; $FF00 holds the depth list of $EFA5 (4 bytes an entry) and then, rebuilt by
; $D9D6 each pass, the sprite list drawn by $EAE3 (6 bytes an entry); its first
; byte is also the last vector byte of the IM 2 table. The stack grows down
; from $FFFF (SP = $FFFF at the entry, $61A8). The bytes in the image up to
; $FF57 are leftovers. The sprite list has no bound: with 16 entries drawn its
; end mark lands at $FF60, so it runs on into `UdgLeftover` ($FF58-$FF60 are
; written and read in the replay). docs/02-architecture.md 2.2.
SpriteListArea:
  DEFB $FD,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$F3,$0D,$CE,$0B,$E4,$50,$CE,$0B
  DEFB $E5,$50,$1C,$17,$DC,$0A,$CE,$0B,$EB,$50,$16,$17,$DC,$0A,$D7,$18
  DEFB $B1,$33,$DE,$5C,$05,$00,$DB,$02,$4D,$00,$5B,$56,$A5,$00,$5A,$56
  DEFB $8C,$08,$5C,$0E,$00,$47,$C0,$57,$71,$0E,$F3,$0D,$21,$17,$C6,$1E
  DEFB $EB,$5E,$76,$1B,$03,$13,$00,$3E

; The 48K BASIC's user-defined graphics, left in the image
;
; $FF58-$FFFF is where the Spectrum ROM keeps the UDGs, set up as copies of the
; letters A-U; the bytes are those copies, left from BASIC. The game never
; reads them as graphics: the sprite list runs over the first bytes
; ($FF58-$FF60 in the replay) and the stack over the last ones ($FFF5-$FFFE, SP
; from $FFFF); $FF61-$FFF4 is the free space between the two.
UdgLeftover:
  INCBIN "res/leftovers/udg.bin",$0000,168
