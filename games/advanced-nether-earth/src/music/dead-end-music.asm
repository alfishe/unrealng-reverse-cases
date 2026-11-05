; Dead End's music in bank 3 ($C000-$D2EE of src/res/img/dead-end-c000-bank3.bin): the Pro Tracker 2.40 player and
; Syrus's NETHER EARTH (END) (Eternity Industry, 1998). The rest of bank 3 is Dead End's (aneE): its image takes
; build/music/dead-end-music-c000.bin at $C000.

    DEVICE ZXSPECTRUM128
    ORG $C000
DeadEndMusic:
    INCLUDE "src/music/stp-player.asm"
TuneLength:
    DW TuneEnd - Tune
Tune:
    INCBIN "build/music/tunes/nether-earth-end.bin"   ; src/res/music/nether-earth-end.pt2 compiled for $CA45
TuneEnd:
    SAVEBIN "build/music/dead-end-music-c000.bin", DeadEndMusic, TuneEnd - DeadEndMusic
