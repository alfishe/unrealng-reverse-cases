; intro.asm: what Neart482's outer block unpacks: $5FB4-$EF2D (36730 bytes), the intro "KIDSON of RAPEWARE CORP.
; presents" with its scroller, and the inner block that holds KIDSON's Russian Nether Earth. src/trd/neart482/README.md.
;
; The outer block (neart482.asm) unpacks this to $5FB4 and jumps to IntroStart. The intro runs under IM 2 until
; SPACE, then jumps to InnerBlock: the inner block unpacks the game to $61A8-$FFFF (over the intro) and jumps to
; its Start, $A600.
;
; Kept as bytes (src/res/trd/neart482/intro-*.bin): the intro's code and data around the texts; its effects are
; not analysed here (IntroWait, IntroToggle). Written as source: the entry, the scroller text (from its UTF-8 copy,
; src/res/text/trd-neart482-scroller.txt), the signature text, and the inner block (lzsfx.asm, its stream packed by
; tools/trd_lz.py from src/res/trd/neart482/inner-61a8.bin).
;
;   sjasmplus --fullpath -Ibuild src/trd/neart482/intro.asm   ->  build/trd/obj/n482-outer.bin

  DEVICE NONE
  INCLUDE "lzsfx.asm"

INTRO           EQU $5FB4   ; the outer block's output
INTRO_VECTORS   EQU $1E     ; I under IM 2: the vector is read from the 48 ROM at $1EFF (an idle bus gives $FF)
IntroWait       EQU $67F8   ; called before and after the loop: 7 HALTs with a delay loop between (not analysed)
IntroWaitPatch  EQU $681E   ; a byte inside IntroWait the exit makes a RET (the second call returns early)
IntroToggle     EQU $8235   ; called after IM 2 is set and after IM 1: the intro's effect on and off (it copies code
                            ; to $5B8D and calls $8F43; not analysed)
CLS             EQU $0D6B   ; the 48 ROM's CLS
KEYS_B_SPACE    EQU $7F     ; the keyboard half-row SPACE, SYMBOL SHIFT, M, N, B
KEYS_CS_V       EQU $FE     ; the half-row CAPS SHIFT, Z, X, C, V
GAME_START      EQU $A600   ; the inner game's Start
INNER_OUT       EQU $61A8   ; the inner block's output, $61A8-$FFFF
INNER_LEN       EQU 21098   ; its stream with the 2 raw bytes

  OUTPUT "build/trd/obj/n482-outer.bin"
  ORG INTRO
  DS 37                     ; $5FB4-$5FD8: zero bytes
; The intro's entry: the outer block jumps here with interrupts on.
IntroStart:
  CALL IntroWait
  LD A,INTRO_VECTORS
  LD I,A
  IM 2
  CALL IntroToggle
  XOR A
  OUT ($FE),A
.wait:                      ; until SPACE (EI again every pass)
  EI
  LD A,KEYS_B_SPACE
  IN A,($FE)
  BIT 0,A
  JR Z,.space
  LD A,KEYS_CS_V
  IN A,($FE)
  BIT 3,A                   ; C: patched out (eight NOPs where its action was)
  JR Z,.noC
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
  NOP
.noC:
  NOP
  JR .wait
.space:
  LD A,$C9
  LD (IntroWaitPatch),A
  CALL IntroWait
  DI
  IM 1
  CALL IntroToggle
  CALL CLS
  JP InnerBlock
IntroCode:
  INCBIN "../../res/trd/neart482/intro-6017.bin"   ; $6017-$78DB: the intro's code and data
; The scroller's text ($78DC-$80E6, read from $621A and $6221): transliterated Russian, ended by a zero.
; docs/texts/trd-neart482-scroller.md
ScrollerText:
  INCBIN "trd/text/trd-neart482-scroller.bin"
  DB 0
  ASSERT ScrollerText == $78DC
IntroData:
  INCBIN "../../res/trd/neart482/intro-80e8.bin"   ; $80E8-$89F6
; A signature among the data: no code reads it. docs/texts/trd-neart482-hacked.md
HackedNote:
  INCBIN "trd/text/trd-neart482-hacked.bin"
  ASSERT HackedNote == $89F7
IntroData2:
  INCBIN "../../res/trd/neart482/intro-8a15.bin"   ; $8A15-$9C3F
; The inner block: KIDSON's Nether Earth, unpacked to $61A8-$FFFF, started at GAME_START.
InnerBlock:
  ASSERT InnerBlock == $9C40
  LZ_SFX $5B8D, INNER_OUT, $FFFF, "trd/obj/n482-inner.lz", INNER_LEN, GAME_START
  DB 0                      ; $EF2D: the last byte the outer block writes
  ASSERT $ == $EF2E
