; The HRUM 3.5 blocks of the SCL (docs/03-build-and-load.md 4), each assembled at the address it runs at and saved
; as build/blk/NAME.bin; tools/mkdisk.py (src/disk.txt) puts them on the disk, the loader (src/loader.asm) holds
; the intro's. Two passes of tools/build.sh: INNER set builds the two blocks that are part of another block's image
; (the intro's screen inside the intro, the boot program's $9C40 part inside bank 7's image), the second pass all
; the others, from images that hold the first pass's blocks.
;
; Per block: where it runs (ORG), what its set-up and its end do (HRUM_SFX's parameters, src/sfx/hrum35.asm) and
; the image it unpacks. Every value is the original block's; the streams come from tools/hrum.py, which gives the
; original streams byte for byte. tools/packall.py writes, per block NAME, the stream build/pk/NAME.hrm, a copy of
; the image build/pk/NAME.img (its last 5 bytes are the depacker's tail) and PK_NAME / UN_NAME (the stream's and the
; image's lengths) in build/pk/sizes.inc: which file each image comes from is tools/build.sh's choice.

    DEVICE ZXSPECTRUM128
    INCLUDE "src/sfx/hrum35.asm"
    INCLUDE "build/pk/sizes.inc"

  IFDEF INNER

; The intro's screen: run by the intro ($6600 + $0F37 holds this block, copied to bank 7 $C000 and called there),
; unpacks the Eternity Industry picture into bank 7's screen ($C000-$DAFF); returns with EI
    ORG $C000
IntroScreen:
    HRUM_SFX 0, 1, $5B89, $C000, UN_introscreen, "build/pk/introscreen.hrm", PK_introscreen, "build/pk/introscreen.img", 0, 1, 0
IntroScreenEnd:
    SAVEBIN "build/blk/introscreen.bin", IntroScreen, IntroScreenEnd - IntroScreen

; The first part of bank 7's image (BootBank7 below unpacks it to bank 7 $C000): the loader of $9C40 copies it to
; $9C40 and runs it; it unpacks over itself and jumps to its start
    ORG $9C40
Part9C40:
    HRUM_SFX 0, 1, $FE4C, $9C40, UN_d07, "build/pk/d07.hrm", PK_d07, "build/pk/d07.img", 0, 0, $9C40
Part9C40End:
    SAVEBIN "build/blk/d07.bin", Part9C40, Part9C40End - Part9C40

  ELSE

; The intro: the loader's CALL $6600 ($6226); unpacks the intro program over itself, then runs it (EI, JP $6600)
    ORG $6600
Intro:
    HRUM_SFX 0, 1, $5B89, $6600, UN_intro, "build/pk/intro.hrm", PK_intro, "build/pk/intro.img", 0, 1, $6600
IntroEnd:
    SAVEBIN "build/blk/intro.bin", Intro, IntroEnd - Intro

; Loaded to bank 7 $DB00, copied to $6600 by the loader ($623A) and called with interrupts on (the loader's music
; plays on): EI first, back with EI and a JP to the program
    ORG $6600
Block02:
    HRUM_SFX 1, 1, $5B89, $6600, UN_d02, "build/pk/d02.hrm", PK_d02, "build/pk/d02.img", 0, 1, $6600
Block02End:
    SAVEBIN "build/blk/d02.bin", Block02, Block02End - Block02

; Loaded to bank 4 $C000, copied to $6600 by the loader ($6293), the same way
    ORG $6600
Block03:
    HRUM_SFX 1, 1, $5B89, $6600, UN_d03, "build/pk/d03.hrm", PK_d03, "build/pk/d03.img", 0, 1, $6600
Block03End:
    SAVEBIN "build/blk/d03.bin", Block03, Block03End - Block03

; Bank 1 $C000, run in place: DI, back DI
    ORG $C000
Block04:
    HRUM_SFX 0, 1, $FE4C, $C000, UN_d04, "build/pk/d04.hrm", PK_d04, "build/pk/d04.img", 0, 0, 0
Block04End:
    SAVEBIN "build/blk/d04.bin", Block04, Block04End - Block04

; $6060: never returns; SP = $6060, JP $61A8
    ORG $6060
Block05:
    HRUM_SFX 0, 0, $FE4C, $6060, UN_d05, "build/pk/d05.hrm", PK_d05, "build/pk/d05.img", $6060, 0, $61A8
Block05End:
    SAVEBIN "build/blk/d05.bin", Block05, Block05End - Block05

; Bank 7 $C000, its depacker at $5B00 (its own image covers $FE4C)
    ORG $C000
BootBank7:
    HRUM_SFX 0, 1, $5B00, $C000, UN_d06, "build/pk/d06.hrm", PK_d06, "build/pk/d06.img", 0, 0, 0
BootBank7End:
    SAVEBIN "build/blk/d06.bin", BootBank7, BootBank7End - BootBank7

; The game's tunes and the PT3 player, bank 1 $C000; back with EI
    ORG $C000
Music:
    HRUM_SFX 0, 1, $FE4C, $C000, UN_music, "build/pk/music.hrm", PK_music, "build/pk/music.img", 0, 1, 0
MusicEnd:
    SAVEBIN "build/blk/music.bin", Music, MusicEnd - Music

; Dead End, the loss sequence, bank 3 $C000
    ORG $C000
DeadEnd:
    HRUM_SFX 0, 1, $FE4C, $C000, UN_deadend, "build/pk/deadend.hrm", PK_deadend, "build/pk/deadend.img", 0, 0, 0
DeadEndEnd:
    SAVEBIN "build/blk/deadend.bin", DeadEnd, DeadEndEnd - DeadEnd

; The disk save and load module, bank 4 $C000
    ORG $C000
DiskIo:
    HRUM_SFX 0, 1, $FE4C, $C000, UN_diskio, "build/pk/diskio.hrm", PK_diskio, "build/pk/diskio.img", 0, 0, 0
DiskIoEnd:
    SAVEBIN "build/blk/diskio.bin", DiskIo, DiskIoEnd - DiskIo

; The game: never returns; SP = $6731, JP $A5DA (GameEntry, src/game/start.asm)
    ORG $6731
Game:
    HRUM_SFX 0, 0, $FE4C, $6731, UN_game, "build/pk/game.hrm", PK_game, "build/pk/game.img", $6731, 0, $A5DA
GameEnd:
    SAVEBIN "build/blk/game.bin", Game, GameEnd - Game

; Final Cut, the win sequence: never returns; SP = $6060, JP $61A8
    ORG $6060
FinalCut:
    HRUM_SFX 0, 0, $FE4C, $6060, UN_finalcut, "build/pk/finalcut.hrm", PK_finalcut, "build/pk/finalcut.img", $6060, 0, $61A8
FinalCutEnd:
    SAVEBIN "build/blk/finalcut.bin", FinalCut, FinalCutEnd - FinalCut

  ENDIF
