; ZYX boot, ZYX Software 1993-1994: the menu's code ($61A8) and its font and graphics ($A600) as the BASIC
; loader leaves them in memory; the music at $C000 is the part src/music.
; Written by kit/mkgame.py from src/game/game.ann and the recordings; edit game.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; Constants: addresses outside this image, ROM entries, ports (@const)
MusicInit          EQU $C00B  ; the music piece's init entry (src/music: $C00B); a variant's music piece has its own (variants/)
ScreenCopyHigh     EQU $E0  ; OR'ed into a screen address's high byte: the same place in ScreenCopy ($80 where a variant keeps the copy at $C000)
GlintEdge          EQU $02  ; the glint's outer cells: red ink (GlintRed)
GlintCentre        EQU $42  ; the glint's middle cell: bright red ink (GlintBright)
MusicPlay          EQU $C00E  ; the music piece's one-frame entry, called by Interrupt

; The variables past the loaded image (game.ann @equ)
RomChanOpen    EQU $1601  ; ROM: open the channel A (2: the upper screen)
TrdosEntry     EQU $3D13  ; the TR-DOS ROM's entry for machine code: C = 5 reads B sectors from track D, sector E to HL
Screen         EQU $4000  ; the screen's pixels
Attributes     EQU $5800  ; the screen's attributes
Chars          EQU $5C36  ; ROM variable CHARS: the font's address - 256
Frames         EQU $5C78  ; ROM variable FRAMES: the menu's interrupt counter (Interrupt $6757 adds 1, the menu resets it)
LaunchToken    EQU $5D4C  ; in the BASIC: line 1's command token (src/basic: LaunchLine)
SavedIY        EQU $AFC8  ; IY at the entry (the ROM's $5C3A), put back for every ROM call
SavedHLAlt     EQU $AFCA  ; HL' at the entry, which the ROM's interrupt handler needs, put back for every ROM call
SavedSP        EQU $AFCC  ; SP at the entry: the launcher returns to the loader with it
SavedI         EQU $AFCE  ; I at the entry
MainTick       EQU $B3B0  ; the main loop's pass counter
PhaseTopLeft   EQU $B3B1  ; the step 0-31 in PhaseOrder of the top left rhombus
PhaseTopRight  EQU $B3B2  ; the step of the top right rhombus
PhaseBottomLeft EQU $B3B3  ; the step of the bottom left rhombus
PhaseBottomRight EQU $B3B4  ; the step of the bottom right rhombus
FileCount      EQU $B3B5  ; the files the page lists (from the page's first entry to the catalogue's end)
CursorRow      EQU $B3B6  ; the cursor's screen row (6-17; 11 for NO EXE FILES !)
CursorColumn   EQU $B3B7  ; the cursor's screen column: 14 (one column), 6 or 22 (two columns)
Columns        EQU $B3B8  ; the page's columns: 0 (no files), 1 or 2
MorePages      EQU $B3B9  ; 1: SYMBOL SHIFT shows the next page (more than 24 files from this page on)
ColumnsSpare   EQU $B3BA  ; cleared with Columns, not read
ColumnOneCount EQU $B3BB  ; the files in column 1
ColumnTwoCount EQU $B3BC  ; the files in column 2 (0: one column)
CursorLength   EQU $B3BE  ; the cursor's width in cells: 8 (a name) or 14 (NO EXE FILES !)
CursorAttr     EQU $B3BF  ; the cursor's attribute this time (Interrupt cycles it)
CursorIndex    EQU $B3C0  ; the cursor's file, 1-24 down column 1 then column 2
PagePointer    EQU $B3C1  ; the catalogue entry the page starts at (Catalogue $9D00 on the first page)
NextPagePointer EQU $B3C3  ; the entry after the page's 24th file
CursorAttrOffset EQU $B3C9  ; CursorAttrAddr's last result - $5800
CursorSavedAttr EQU $B3CB  ; the attribute under the cursor before it was drawn (the file's ink)
RotateRow      EQU $B3CC  ; the row and column of the name being rotated
EntryLine      EQU $B3CE  ; one catalogue line: AT row,col BRIGHT 1 INK 5 "X>  " INK n, the name, $FF
RotateLength   EQU $B3EC  ; the rotated name's width in cells
CharBuffer     EQU $B3ED  ; one character's 8 rows while it is rotated
RomPointer     EQU $DEA8  ; NewRandoms's index into the ROM's first 2K
TwinkleAddr    EQU $DEAA  ; the twinkle's screen address
TwinkleClock   EQU $DEAC  ; +2 a frame: the twinkle's phase and place
RotateAddr     EQU $DEAE  ; the rotated name's address in ScreenCopy
TwinklePause   EQU $DEB0  ; counts the 8 frames between two twinkles
ScreenCopy     EQU $E000  ; the clean screen: pixels $E000, attributes $F800; the twinkles, the glint and the rotated name restore from it
MenuStack      EQU $FCBC  ; the menu's stack top
Im2Jump        EQU $FCFC  ; JP Interrupt, where every IM 2 vector points
Im2Table       EQU $FD00  ; the IM 2 vector table: 257 bytes of $FC
  ORG $61A8
  INCLUDE "setup.asm"  ; The entry: save the caller's state, read the catalogue, IM 2, draw the screen, build the phases, the main loop
  INCLUDE "rhombi.asm"  ; The four corner rhombi: their 34 phases built at the start, printed one step at a time
  INCLUDE "stars.asm"  ; The falling stars and the twinkles
  INCLUDE "screen.asm"  ; The menu's screen, the pages and the cursor
  INCLUDE "font.asm"  ; Printing: the ROM's RST $10 with the menu's font
  INCLUDE "catalogue.asm"  ; Reading the TR-DOS catalogue
  INCLUDE "interrupt.asm"  ; The IM 2 interrupt: the music, the clocks, the twinkle, the glint, the cursor, the name's spin, the keys
  INCLUDE "keys.asm"  ; The keys, every 8th frame
  INCLUDE "launcher.asm"  ; Running the chosen file: the BASIC's launch line, the bell, the fade, back to the loader
  INCLUDE "fade.asm"  ; The corner gradients and the exit fade
  INCLUDE "logo.asm"  ; The ZYX logo: its glint and its reflection
  INCLUDE "sound.asm"  ; The AY: silence and the bell
  INCLUDE "buffers.asm"  ; The work space between the pieces: never loaded, cleared by the loader, filled by Start
  INCLUDE "graphics.asm"  ; The graphics piece: 8 sectors at $A600

  SAVEBIN "game.bin",$61A8,$4C58
