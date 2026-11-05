; --------------------------------------------------------------------------------------------------------------------
; starter.asm: the game starter: the title picture shown in, then the game
;
; Run once, as the game starts: the screen and the 48 K system variables area are cleared, the title picture's pixels
; drawn with the attributes of a colour run, the border and the paper stepped through the 8 colours (two frames each),
; then the picture's own attributes; interrupts off and back to the boot program, which starts the game.
; --------------------------------------------------------------------------------------------------------------------

; Clear $4000-$5AFF, draw the title picture, fade it in through the 8 paper
; colours, its attributes
;
; Interrupts on (the HALTs of FillColour need them), border black. $5AFF down
; to the first non-zero byte below the screen is cleared (the loop stops on a
; byte that stays non-zero after LD (HL),0: the ROM). The 6144 pixel bytes of
; TitlePicture go to $4000; FlashColours' 8 attributes each fill the whole
; attribute area (FillColour); TitlePicture's 768 attributes go to $5800;
; interrupts off.
StartPicture:
  EI                      ; the HALTs below need interrupts
  XOR A
  OUT ($FE),A             ; border black
  LD HL,$5B00             ; the screen and on down, cleared ...
l_9C47:
  DEC HL
  LD (HL),A
  OR (HL)                 ; ... until a byte stays non-zero (the ROM)
  JR Z,l_9C47
  LD HL,TitlePicture      ; the picture's pixels to the screen
  LD DE,$4000
  LD BC,$1800
  LDIR
  LD HL,FlashColours      ; the 8 colours
  LD B,$08
l_9C5C:
  PUSH BC
  PUSH HL
  CALL FillColour
  POP HL
  POP BC
  INC HL
  DJNZ l_9C5C
  LD HL,TitlePicture+$1800 ; the picture's attributes
  LD DE,$5800
  LD BC,$0300
  LDIR
  DI                      ; the boot program goes on with interrupts off
  RET

; Every attribute and the border from the colour at HL; two frames
;
; A = (HL): all 768 attributes (an LDIR from $5800), the border A / 8 (the
; paper's colour); two HALTs.
FillColour:
  LD A,(HL)
  LD HL,$5800
  LD (HL),A
  RRCA                    ; the paper bits to the border's
  RRCA
  RRCA
  OUT ($FE),A
  LD D,H
  LD E,L
  INC E
  LD BC,$02FF
  LDIR
  HALT                    ; two frames
  HALT
  RET

; The 8 attributes of the fade: paper 0-7, ink black
FlashColours:
  DEFB $00,$08,$10,$18,$20,$28,$30,$38

; The title picture: 6144 pixel bytes ($9C90-$B48F), 768 attributes
; ($B490-$B78F)
TitlePicture:
  INCBIN "res/diskmod/title.bin",$0000,6912
