; Advanced Nether Earth (Eternity Industry, 1998): the game block, $6731-$D7D7 (docs/03-build-and-load.md 4).
;
; The game is Nether Earth's (games/nether-earth/src/game, built by tools/build.sh into build/ne/game.bin at NE's
; addresses) with ANE's changes over it: src/game/ane-patches.asm, one ORG a change, each with the NE entry it
; falls in and its reason. The block holds $6731-$D7D7 only: NE's bytes below $6731 and from $D7D8 on are not in it
; (docs/02-architecture.md has what ANE keeps there).

    DEVICE ZXSPECTRUM48
    ORG $5B00
    INCBIN "build/ne/game.bin"  ; NE, $5B00-$FCE8
    INCLUDE "build/ne/ne.sym"   ; NE's names, for the patches
    INCLUDE "src/game/ane-patches.asm"
    SAVEBIN "build/img/game-6731.bin", $6731, $D7D8 - $6731
