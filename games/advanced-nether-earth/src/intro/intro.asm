; The intro's image, $6600-$A3AC, as HRUM block 1 inside the loader unpacks it (src/loader.asm, src/sfx/blocks.asm).
; Written by hand: it puts together the parts tools/intro_mkpart.py writes from their .ann files (it rewrites every
; .asm in those folders, so this file stays outside them).
;
;   $6600-$7536  Intro, LogoPicture, LogoStream                 intro/intromain.asm (src/intro/intro/intro.ann)
;   $7537-$7D2C  IntroScreenBlock: the plain logo's HRUM block    blk/introscreen.bin (the packing step, from
;                                                                src/res/intro/eternity.png) with -DINTRO_SCREEN_BLOCK;
;                                                                zero without it (as the raw image src/res/img holds it)
;   $7D2D-$A3AC  the player and MAD NIGHT for bank 6 $C000        music/intro-music-7d2d.bin (aneS: tools/build_music.sh,
;                                                                src/music/intro-music.asm)
;
; tools/build_intro.sh assembles it (cd build/intro, -I build/intro).

  DEVICE ZXSPECTRUM128

WaitFrames     EQU $6200        ; the loader's (src/loader.asm): wait BC frames
SetPage        EQU $6207        ; the loader's: A to $7FFD and BANKM

  ORG $6600
IntroImage:
  INCLUDE "intro/intromain.asm" ; the intro: the Eternity Industry logo, its music and the decorated picture

; The plain "ETERNITY industry" logo's HRUM block: Intro copies it to bank 7 $C000 and calls it there; it unpacks
; itself into screen 7 (src/res/intro/eternity.png, docs/03-build-and-load.md 4)
IntroScreenBlock:
  IFDEF INTRO_SCREEN_BLOCK
    INCBIN "blk/introscreen.bin"
  ELSE
    DS $07F6, 0
  ENDIF
IntroScreenBlockLength EQU $ - IntroScreenBlock
  ASSERT IntroScreenBlockLength == $07F6

; The intro's music as Intro copies it to bank 6 $C000 (NstPlayerCopyLength bytes: one past the image's end, the
; tune's last byte, which the 128 ROM's reset left zero at $A3AD): aneS's build of the player and MAD NIGHT
; (src/music/intro-music.asm: src/music/stp-player.asm, the tune's length word, src/res/music/mad-night.pt2)
NstPlayerImage:
  INCBIN "music/intro-music-7d2d.bin"
IntroImageEnd:
NstPlayerCopyLength EQU IntroImageEnd + 1 - NstPlayerImage
  ASSERT IntroImageEnd == $A3AD

  SAVEBIN "intro.bin", IntroImage, IntroImageEnd - IntroImage
