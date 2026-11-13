; Rick Dangerous, Firebird 1989 (Bleepload): group 1's block 46: the second loader stage at $5D00 (256 bytes, deciphered, as the tape holds it).
; Written by kit/mkgame.py from src/loader/stage2.ann and the recordings; edit stage2.ann, not the .asm.

  DEVICE ZXSPECTRUM128

; The variables past the loaded image (game.ann @equ)
KeyScan        EQU $028E  ; the ROM's KEY-SCAN: DE = the keys held, Z when the combination is valid
LdBytes        EQU $0556  ; the ROM's LD-BYTES: IX = the address, DE = the length, A = the flag, carry set to load, reset to verify
Screen         EQU $4000  ; the display file and the attributes
DfSz           EQU $5C6B  ; DF_SZ: the lines of the lower screen
NmiAdd         EQU $5CB0  ; NMIADD: the 128K ROM's NMI vector
GameLow        EQU $5E00  ; the game's $5E00-$6DFF (src/game): the AY player and tunes, copied to RAM 1 later
GameEntry      EQU $AB4D  ; the game's entry (src/game)
LoadBlock      EQU $CD6E  ; Rick1's tape reader (src/loader/rick1.asm)
CheckBlock     EQU $CE2A  ; Rick1's checksum
BadBlock       EQU $CE7E  ; Rick1's "Block ?" message
Group1Screen   EQU $CF00  ; group 1's $CF00-$E9FF, deciphered: the loading screen
Group1Low      EQU $EA00  ; group 1's $EA00-$F9FF, deciphered: the game's $5E00-$6DFF
LoadGroup      EQU $FA00  ; the loader of groups 2 and 3 (src/loader/loadgroup.asm)
KeyPagePtr     EQU $FEE7  ; in group 1's last block, the only bytes of it read: the key page, $C900
KeyedFrom      EQU $FEE9  ; ... the first address the key deciphers, $CF00
KeyedEnd       EQU $FEEC  ; ... the high byte after the last, $FC
  ORG $5D00
  INCLUDE "stage2-module.asm"  ; The second loader stage: the key, the deciphering, groups 2 and 3, the start

  SAVEBIN "stage2.bin",$5D00,$0100
