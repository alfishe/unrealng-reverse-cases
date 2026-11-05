; The two images that hold another HRUM block (src/sfx/blocks.asm, INNER): the intro and bank 7's boot image. The
; rest of their bytes are the depacked originals (src/res/img, docs/03-build-and-load.md 4).

    DEVICE ZXSPECTRUM128

; The intro program, $6600-$A3AC; its picture's block at $7537 (the intro copies it to bank 7 $C000 and calls it)
    ORG $6600
IntroImage:
    INCBIN "build/intro/intro-6600.bin", 0, $0F37
    INCBIN "build/blk/introscreen.bin"
    INCBIN "build/intro/intro-6600.bin", $172D
IntroImageEnd:
    ASSERT IntroImageEnd - IntroImage == 15789
    SAVEBIN "build/img/intro-6600.bin", IntroImage, IntroImageEnd - IntroImage

; Bank 7's image of the boot, $C000-$FFFF: the $9C40 part's block first
    ORG $C000
Bank7Image:
    INCBIN "build/blk/d07.bin"
    INCBIN "build/disk/d06-c000-bank7.bin", $0E09
    SAVEBIN "build/img/d06-c000-bank7.bin", Bank7Image, $4000
