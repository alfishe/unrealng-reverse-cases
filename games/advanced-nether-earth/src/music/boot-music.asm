; =====================================================================================================================
; The boot music: bank 1 as the boot loads it (raw d04-c000-bank1.bin). PT 3 Player v1.0 by Nick of GDC at $C000
; (src/music/pt3-player.asm), X-Man's TOMY right after it at $CE21 (src/res/music/tomy.pt3, as Pro Tracker 3 saved it:
; the player relocates the module's offsets at Pt3Init). UltraXOR's sector reader CALLs Pt3Init after bank 1 is in;
; the boot program's interrupt calls Pt3PlayEntry each frame.
; =====================================================================================================================
    DEVICE ZXSPECTRUM128
    ORG $C000
BootMusic:
    INCLUDE "src/music/pt3-player.asm"
    INCBIN "src/res/music/tomy.pt3"
BootMusicEnd:
    ASSERT Pt3Module - BootMusic == $E21
    SAVEBIN "build/music/d04-c000-bank1.bin", BootMusic, BootMusicEnd - BootMusic
