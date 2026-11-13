; --------------------------------------------------------------------------------------------------------------------
; levels.asm: The level builder
;
; BuildLevel $891A copies the level in Level from LevelData ($B000 + $87 x Level) to the grid LevelGrid $FD23 (15
; cells a row and two guard bytes, 17 bytes a row; the row above and the guards are zero), clears the character map,
; marks every character to be drawn, and falls into RenderGrid and DrawMarkedChars: the level is in the buffers when
; it returns.
; --------------------------------------------------------------------------------------------------------------------

  ORG $8912

; The current level's address in LevelData, and the renderer's and beam's
; character pointers
;
; LevelAddress: BuildLevel `$892A`, read by BuildLevel and SetUpLevel's count
; (`$8520`).
LevelAddress:
  DEFW $0000
CharMapPointer:
  DEFW $0000              ; the character map address being written: RenderGrid
                          ; ($8963), and the beam's drawing ($90B9 on)
PixelPointer:
  DEFW $0000              ; the beam's pixel-buffer address: $E7FF + 256 y + x
                          ; ($90A7 on)
  DEFW $0000              ; two bytes no code reads or writes

; Copy level Level to the grid, clear the character map, mark every character;
; into RenderGrid
;
; 1. LevelAddress = LevelData `$B000` + `$87` x Level (by Level additions of
; `$87`).
;
; 2. LevelGrid `$FD00-$FDFA` cleared: the row above the grid (`$FD12`), the
; guards and whatever the mover left there.
;
; 3. The character map `$E000-$E2FF` cleared (20 rows of 32 and 256 bytes after
; it); DrawMarks `$E300-$E5FF` set to 1: every character of the play area is
; drawn on the next DrawMarkedChars and copied once by CopyPlayArea.
;
; 4. The 135 level bytes go to `$FD23` in 9 rows of 15, each row followed by
; two zero guards (17 bytes a row): the cell (row r, column c) is at `$FD23` +
; 17 r + c, and the row above (r = -1) and the guards read as empty cells.
;
; 5. Falls into RenderGrid (and so DrawMarkedChars): the whole level is drawn
; into the buffers.
;
; Called by SetUpLevel (`$8509`) only. The tool `tools/level_maps.py` runs it
; in SkoolKit's simulator for every slot (docs/img/maps).
;
; Witness: L1 196 (c1, c1g, cheat, controls, energy, energy-out, hof, kempston,
; menu, mine, overload, L x20, rzx x59).
BuildLevel:
  LD A,(Level)
  LD B,A
  LD HL,LevelData
  LD DE,$0087
  AND A
  JR Z,BuildLevelGrid
BuildLevelAddLoop:
  ADD HL,DE
  DJNZ BuildLevelAddLoop
BuildLevelGrid:
  LD (LevelAddress),HL    ; the grid cleared
  LD HL,LevelGrid
  LD DE,LevelGrid+1
  LD (HL),$00
  LD BC,$00FA
  LDIR
  LD HL,CharMap             ; the character map cleared, every DrawMark 1
  LD DE,CharMap+1
  LD (HL),$00
  LD BC,$0300
  LDIR
  LD (HL),$01
  LD BC,$02FF
  LDIR
  LD HL,(LevelAddress)    ; 9 rows of 15 cells, two guards a row
  LD DE,LevelGrid+35
  LD A,$09
BuildLevelRowLoop:
  LD BC,$000F
  LDIR
  INC E
  INC E
  DEC A
  JR NZ,BuildLevelRowLoop

  ORG $B000

; The 64 level slots: 135 cell codes each (9 rows of 15), slot = Level, at
; $B000 + $87 x slot
;
; BuildLevel `$891A` (`$891E`: `LD HL,$B000`, then `$87` added Level times)
; copies a slot's 9 rows of 15 into the grid `$FD23` (17 bytes a row: two
; guards). Slots 0-59 are levels 1-60, slots 60-62 the practice levels P1-P3,
; slot 63 is never set up.
;
; A cell code: `$00` empty; `$01-$10` a mirror at 16 angles; `$11-$18` a cyan
; polariser and `$19-$20` a yellow one at 8 angles; `$21-$2F` an absorbing and
; `$30-$3E` a reflecting wall, by the quarters it fills; `$40` a cell to burn;
; `$41` a mine; `$42` a prism; `$47-$4A` the laser facing east, south, west,
; north; `$4B-$4E` the receiver open to the east, south, west, north; `$50-$57`
; the fibre-optic ends, pairs `$50/$51`, `$52/$53`, `$54/$55`, `$56/$57`. Bit 7
; set on a mirror or a polariser (`$81-$A0`): it turns by itself, one step a
; pass (RenderGrid `$8960`). Each level holds one laser and one receiver.
;
; Slot 63 is level 23 with five mirrors at other angles (rows 0, 4, 8): a draft
; or a copy left over. Slots 60-63 (`$CFA4-$D1BF`) were read by no recording
; (no practice game was played). Editable form: levels/levels.txt.
LevelData:
  INCBIN "res/levels/levels.bin",$0000,8640

; 64 bytes of 0 after the last level slot, below the font's first character
;
; No instruction addresses `$D1C0-$D1FF` and no recording reads or writes it.
; The printers address the font as `$D200` + 8 x (code - 32), so a notional
; base `$D100` would put characters 24-31 here; nothing prints a code below 32.
SpareD1C0:
  INCBIN "res/leftovers/spare-d1c0.bin",$0000,64
