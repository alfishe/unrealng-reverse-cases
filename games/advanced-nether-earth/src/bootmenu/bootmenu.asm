; Advanced Nether Earth (Eternity Industry 1998): the boot program $6060-$F6D4, the boot menu and the help,
; as its HRUM block unpacks it (src/sfx/blocks.asm, Block05; entry $61A8).
; Written by kit/mkgame.py from src/bootmenu/bootmenu.ann and the recordings; edit bootmenu.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; Constants: addresses outside this image, ROM entries, ports (@const)
PAGE_PORT          EQU $7FFD  ; the 128's paging port
AY_SELECT          EQU $FFFD  ; the AY's register select (its data port is $BFFD: B = $BF)
ROM_RET            EQU $0052  ; a RET in the 48 BASIC ROM: CALL ROM_RET leaves the caller's address under SP
ROM_HL_ALT         EQU $2758  ; the value the BASIC ROM keeps in HL' (the depacker leaves it there)
BANK_WINDOW        EQU $C000  ; the start of the paged bank: the entry of the block or player that bank holds
PLAYER_PLAY        EQU $C005  ; bank 1: the boot tune player's play-one-frame entry (Pt3PlayEntry, src/music/pt3-player.asm)
STARTER            EQU $9C40  ; where the game starter's block runs (it unpacks itself there)
STARTER_LENGTH     EQU $0E09  ; the game starter's HRUM block at bank 7 $C000
GAME_BLOCK         EQU $6731  ; the game's HRUM block: copied here from bank 4 and bank 3, run with JP
GAME_HEAD_LENGTH   EQU $4000  ; the game block's first part, bank 4 $C000-$FFFF
GAME_TAIL          EQU $E79E  ; bank 3: the game block's last part (behind Dead End)
GAME_TAIL_AT       EQU $A731  ; GAME_BLOCK + GAME_HEAD_LENGTH: where the last part goes
GAME_TAIL_LENGTH   EQU $0392  ; 914 bytes
MUSIC_BLOCK        EQU $EB30  ; bank 3: the game music's HRUM block, for bank 1 $C000
MUSIC_BLOCK_LENGTH EQU $0F98
DISK_BLOCK         EQU $F637  ; bank 6: the disk module's HRUM block, for bank 4 $C000
DISK_BLOCK_LENGTH  EQU $08B1
SAMPLE             EQU $CE09  ; bank 7: the sample boot menu key 3 plays (after the starter's block)
SAMPLE_LENGTH      EQU $31F6  ; 12790 bytes, one a sample
DEPACK_GETBIT_ORG  EQU $62D5  ; GetBit where the authors assembled the depacker ($6203 + $D2): ScreenDepack writes the real address over these CALL operands before it runs

; The variables past the loaded image (game.ann @equ)
Screen         EQU $4000  ; the screen: ScreenDepack's output, the printer's and the pointer's
Im2Table       EQU $5B00  ; the IM 2 vector table BootMenu fills with $60 (I = $5B: every vector reads $6060)
  ORG $6060
  INCLUDE "boot.asm"  ; the entry, the interrupt, paging, the game's start, the sample
  INCLUDE "helppic.asm"  ; the picture of help item 1
  INCLUDE "depack.asm"  ; the screen depacker (Hrust 1)
  INCLUDE "pictures.asm"  ; the help's pictures and the boot menu's (Hrust 1 streams)
  INCLUDE "menus.asm"  ; the boot menu, the help menu, the pointer, the controls
  INCLUDE "help.asm"  ; the help items: pictures and typed pages
  INCLUDE "print.asm"  ; the help's text printer, the page keys, the game key
  INCLUDE "texts.asm"  ; the help menu's names and the 28 pages

  SAVEBIN "d05-6060.bin",$6060,$9675
