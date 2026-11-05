; Bank 1 as the game block leaves it ($C000-$E21A, src/res/img/music-c000-bank1.bin's bytes): the game music (the
; Pro Tracker 2.40 player and X-Man's TAIGA, 1997) and the title cards shown before the game.
;
;   sjasmplus -I<case> src/music/music-bank1.asm      (tools/build_music.sh: after the tunes and the title bitmaps)

    DEVICE ZXSPECTRUM128
    ORG $C000
Bank1Music:
    INCLUDE "src/music/stp-player.asm"
; the compiled tune's length, then the tune (src/res/music/taiga.pt2 compiled for $CA45 by tools/music_ptmodule.py:
; its 18 empty unused samples and 12 empty unused ornaments dropped, its pointers absolute)
TuneLength:
    DW TuneEnd - Tune
Tune:
    INCBIN "build/music/tunes/taiga.bin"
TuneEnd:
    INCLUDE "src/music/title-cards.asm"
Bank1MusicEnd:
    SAVEBIN "build/music/music-c000-bank1.bin", Bank1Music, Bank1MusicEnd - Bank1Music
