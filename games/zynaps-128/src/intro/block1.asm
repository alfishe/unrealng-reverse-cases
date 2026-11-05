; Zynaps 2 in 1: block 1, the intro ($6000-$E8D4)
; Written by tools/part_mkasm.py from src/intro/intro.ann; edit the .ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
StarkosInit        EQU $8000  ; the STarKos player as it runs (src/sound/starkos.asm): init with DE = the song
StarkosPlay        EQU $8003  ; one frame of the tune
StarkosStop        EQU $8006  ; silence the AY
Sk10Song           EQU $8990  ; the SK10 song inside the copied player
EngineRun          EQU $C968  ; the page-4 sound engine as it runs (src/sound/engine.asm)
EngineDataRun      EQU $DE48  ; its data as it runs (in page 4)
PAGE4              EQU $14  ; $7FFD: bank 4 at $C000, the 48 BASIC ROM, screen 0
PAGE0              EQU $10  ; $7FFD: bank 0 at $C000
PORT_7FFD          EQU $7FFD  ; the 128K paging port

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the screen's pixels
Attrs          EQU $5800  ; the attribute file
AttrsRow16End  EQU $5A1F  ; the last attribute of row 16, where the lower colour bars start (going back)
OptionLives    EQU $5AEB  ; the attributes of "1.INF.LIVES" on the options screen's last row (row 23, columns 11-19)
OptionMouse    EQU $5AF8  ; the attributes of "2.K-MOUSE" (row 23, columns 24-30)
Is128          EQU $5D3B  ; the loader's flag: 1 = 128K (the paging test passed), 0 = 48K
InfLives       EQU $5D40  ; the option INF.LIVES: 0 off, 1 on (over the loader's first byte); block 2's set-up reads it
KMouse         EQU $5D41  ; the option K-MOUSE: 0 off, 1 on
Im2Table       EQU $FC00  ; the intro's IM 2 vector table: 509 bytes of $FD
Im2Jump        EQU $FDFD  ; JP IntroInterrupt, where every vector $FDFD points
  ORG $6000
  INCLUDE "intro.asm"  ; the intro: the engine to page 4, the tune, three pictures, the options

  SAVEBIN "build/obj/block1.bin",$6000,$88D5
