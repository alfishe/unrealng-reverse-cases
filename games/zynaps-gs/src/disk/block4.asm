; block4.asm: what Trush block 4 unpacks to $61A8-$FFFF (40536 bytes): the installer and its stubs, the GS driver
; file (with the level loader and the options menu inside it), and Zynaps. docs/03-build-and-load.md 3.3-3.5.
;
; Zynaps is src/game/game.asm (kit/mkgame.py from src/game/game.ann), assembled to build/game.bin at its run
; addresses $5C00-$FFFF. The block holds three parts of it: $7400-$C7FF and $E000-$FFFF in place, and $5C00-$73FF at
; $C800-$DFFF, because the installer, the driver file and the menu lie at $61A8-$73FF while the block runs (the
; installer's Mover moves the part down and clears $C800-$DFFF, which the block does not carry: zeros in play until
; the glyph cache is built). The installer's 25 patches are made at run time (src/disk/install.asm).
;
;   sjasmplus -I. src/disk/block4.asm   ->  build/disk/block4.bin (after install, driver and build/game.bin)

  DEVICE ZXSPECTRUM128
  ORG $61A8
Block4:
  INCBIN "build/disk/install.bin"       ; $61A8-$64B2: src/disk/install.asm
DriverFile:
  INCBIN "build/disk/driver.bin"        ; $64B3-$73FF: src/disk/driver/ (copied to bank 1 $C000)
  ASSERT $ == $7400
Zynaps:
  INCBIN "build/game.bin",$7400-$5C00,$C800-$7400       ; $7400-$C7FF
ZynapsLow:
  INCBIN "build/game.bin",0,$7400-$5C00                 ; Zynaps's $5C00-$73FF, here at $C800-$DFFF
  INCBIN "build/game.bin",$E000-$5C00,$10000-$E000      ; $E000-$FFFF
  ASSERT $ == $10000
  SAVEBIN "build/disk/block4.bin",Block4,$10000-Block4
