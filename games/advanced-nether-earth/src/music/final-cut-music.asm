; =====================================================================================================================
; Final Cut's music: the same PT 3 Player v1.0 by Nick of GDC assembled for $DB00 (src/music/pt3-player.asm), X-Man's
; REM right after it at $E921 (src/res/music/rem.pt3). Final Cut's image (final-cut-6060.bin) holds these 6776 bytes
; at $8BF5-$A66C and its code calls them at their run address (CALL $DB05 at $6074, CALL $DB00 at $61BC); this file
; builds them for $DB00, for that image to INCBIN at $8BF5.
; =====================================================================================================================
    DEVICE ZXSPECTRUM128
    ORG $DB00
FinalCutMusic:
    INCLUDE "src/music/pt3-player.asm"
    INCBIN "src/res/music/rem.pt3"
FinalCutMusicEnd:
    ASSERT Pt3Module - FinalCutMusic == $E21
    ASSERT FinalCutMusicEnd - FinalCutMusic == $A66D - $8BF5
    SAVEBIN "build/music/final-cut-music-8bf5.bin", FinalCutMusic, FinalCutMusicEnd - FinalCutMusic
