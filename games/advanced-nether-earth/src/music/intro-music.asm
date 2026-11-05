; The intro's music: the Pro Tracker 2.40 player and Syrus's MAD NIGHT (15.02.98), assembled for bank 6 $C000. The
; intro's image holds it at $7D2D-$A3AC and copies $2681 bytes to bank 6 $C000 (LD HL,$7D2D at $661D, LDIR at
; $6626), then calls Init; the loader's interrupt plays it (src/loader.asm PlayerFrame). The image (aneI's) takes
; build/music/intro-music-7d2d.bin at $7D2D.
;
; The image ends one byte short of the copy: the tune's last byte (0, the third value of ornament 13) is not in
; the intro's block; the LDIR takes it from $A3AD, which nothing writes after the 128 ROM's reset cleared every bank.
; So the file written here stops at TuneEnd - 1 (the image's bytes) and the check in tools/build_music.sh asserts
; that the byte left out is that 0.

    DEVICE ZXSPECTRUM128
    ORG $C000
IntroMusic:
    INCLUDE "src/music/stp-player.asm"
TuneLength:
    DW TuneEnd - Tune
Tune:
    INCBIN "build/music/tunes/mad-night.bin"          ; src/res/music/mad-night.pt2 compiled for $CA45
TuneEnd:
    ASSERT TuneEnd - IntroMusic == $2681              ; the intro's LDIR length
    SAVEBIN "build/music/intro-music-7d2d.bin", IntroMusic, TuneEnd - 1 - IntroMusic
    SAVEBIN "build/music/intro-music-bank6.bin", IntroMusic, TuneEnd - IntroMusic
