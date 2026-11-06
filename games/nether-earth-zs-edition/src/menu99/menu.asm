; Nether Earth ZS Edition '99, the 128 K start-up menu in page 1 ($D800-$E6F3).
; Unpacked by the block of sectors 123-132 (read to $E800 of page 1); entered at MenuEntry $D800.
; Written by kit/mkgame.py from src/menu99/menu.ann and the recordings; edit menu.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (game.ann @equ)
RomClAddr      EQU $0E9E  ; ROM CL-ADDR past its LD A,$18 / SUB B: A = the text line from the top, HL its pixel address
RomPixelAdd    EQU $22B0  ; ROM PIXEL-ADD past its 175 - y: A = the pixel line from the top, C = x; HL the byte
EnemyPartsMask EQU $A5E5  ; patches block: the AND mask EnemyUpgrade applies to an enemy robot's parts
EnemyUpgrade   EQU $A5E7  ; patches block: the parts ORed into every enemy robot (bit 7 electronics .. bit 2 anti-gravs)
EnemyProduce   EQU $AE41  ; the game's daily income: LD HL,$FD4A, LD DE,$FD42, CALL ProduceSide (the enemy's)
SpawnResources EQU $B87E  ; the game's SpawnCheckWeapons: LD HL,$FD4A (the enemy's resources)
LoadDescription EQU $C103  ; MainMenu table: the description text into HL
LoadAdvices    EQU $C106  ; MainMenu table: the advices text into HL
LoadGreets     EQU $C109  ; MainMenu table: the greets text into HL
LoadAbout      EQU $C10C  ; MainMenu table: the about text into HL
MenuHook       EQU $C1E1  ; a word of the game's that MenuEntry sets to MenuRedraw (no window reads it)
LoadMap        EQU $C1FD  ; patches block: LOAD MAP (the disk catalogue's NELEV files)
RedefineKeys   EQU $C34A  ; the game's: the eight-key redefine screen
TitleColourCycle EQU $C820  ; the game's: cycles the ink of the title rows
ClearScreen    EQU $D0B9  ; the game's: pixels and attributes to 0, border black
InsgRobotCount EQU $D2C8  ; the game's PrintInsgCounts: CALL PrintNumber2Zero, CALL PrintInline (the enemy robots)
Controls       EQU $D3E4  ; the game's: 1 keyboard, 2 Kempston, 3 Interface 2
PrintInline    EQU $D42D  ; the game's: prints the bytes after the CALL (0 end, 1 Y X, 2 attribute, 3 next line, 4 size)
TextBuffer     EQU $E6F4  ; the text the viewer shows (copied there from page 3)
  ORG $D800
  INCLUDE "menumain.asm"  ; The menu screen, the pointer loop, the choices, START and its level patches
  INCLUDE "menuviewer.asm"  ; The text viewer: 64 columns, 16 lines a page, Q / A / SPACE
  INCLUDE "menupointer.asm"  ; The pointer sprite, the marks, the keys

  SAVEBIN "menu-d800.bin",$D800,$0EF4
