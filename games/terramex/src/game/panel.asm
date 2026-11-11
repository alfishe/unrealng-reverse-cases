; --------------------------------------------------------------------------------------------------------------------
; panel.asm: The status panel: portrait, spare lives, bearers, score
; --------------------------------------------------------------------------------------------------------------------

  ORG $9E5D

; Draw the explorer's portrait and the held item in the panel
;
; The explorer's frame 9 ($6288, the front view) at screen $5092 (character row
; 20, columns 18-20) and the held item ($5B98, the item sprite at $8400;
; BlankSprite $5C46 when $FF) at $5032 (row 17, columns 18-20), through the
; column list PanelColumns $5BD6 and BlitColumns $9F86. The screenshot
; start-room-14.png shows the explorer at row 20, column 18 and no held item.
;
; Callers: GameInit at $9015, $A851 at $A862, $B370 at $B403, $B5DD at $B5FB,
; $B735 at $B759 (tail), $B9FA at $BA30 and $BA71, $BB6C at $BC0A: 81 runs in
; 30 builds.
;
; Witness: L1 81 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx).
DrawPortrait:
  LD HL,ExplorerSet+9*72
  LD IY,PanelColumns
  CALL AddColumnPointers
  LD B,$03
  LD HL,Screen+4242
  LD IY,PanelColumns
  CALL BlitColumns
  LD HL,BlankIcon             ; no item held: the blank sprite
  LD A,(HeldItem)
  CP $FF
  JR Z,DrawPortraitItem
  LD DE,ItemSprites
  CALL SpriteAddress
DrawPortraitItem:
  LD IY,PanelColumns
  CALL AddColumnPointers
  LD HL,Screen+4146
  LD B,$03
  LD IY,PanelColumns
  JP BlitColumns

; Draw the spare lives in the panel: up to three explorer figures
;
; Lives $5B97 = 0 returns. Otherwise three icons, frames 2, 3 and 4 of the
; explorer's set, the k-th (k = 1-3) shown when Lives - 1 >= k, else
; BlankSprite $5C46; drawn at $5081 (row 20, columns 1-9) by SpareLivesShow
; $9F1E. With the 4 lives of the start three figures show (start-room-14.png).
;
; Callers: GameInit at $8FF0, $A9EE at $AA01 (tail, the life lost): 11 runs in
; 7 builds; the blank icon ran in r06000, r10000, r24000, r32000.
;
; Witness: L1 11 (c1, explorers, rzx, rzx, rzx, rzx, rzx).
DrawSpareLives:
  LD A,(Lives)
  OR A
  RET Z
  DEC A
  LD IY,PanelColumns
  LD C,A
  LD B,$03
  LD A,$02                ; frame 2 first
DrawSpareLivesIcon:
  PUSH AF
  LD DE,ExplorerSet
  CALL SpriteAddress
  DEC C
  JP P,DrawSpareLivesStore
  LD HL,BlankIcon
DrawSpareLivesStore:
  CALL AddColumnPointers
  POP AF
  INC A
  DJNZ DrawSpareLivesIcon
  JP SpareLivesShow

; Draw the bearer row of the panel: the four carried items and the bearers
; under them
;
; DrawBearerItems $9EE3 draws the items first. Then four bearer figures from
; BearerFigures $9FDE, figure (log index AND 3) for the log entries BearerFirst
; $5C23 to +3 (wrapping at 27), at $5096 (row 20, columns 22-30) through
; BearerRowShow $9F6B. Only 9 of the 12 columns show, from column BearerScroll
; $5C22 (0-2), so the keys 1 and 2 (bearers left, right) scroll the row a
; character at a time.
;
; Callers: GameInit at $8FE8, $B9FA at $BA6E, $BB6C at $BC1C (tail), $BC1F at
; $BC50, $BC64, $BC69, $BC70 (scroll): 1139 runs in 29 builds.
;
; Witness: L1 1139 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
DrawBearers:
  CALL DrawBearerItems
  LD B,$04
  LD IY,PanelColumns
  LD A,(BearerIndex)
  LD C,A
DrawBearersFigure:
  LD A,C
  AND $03
  LD DE,BearerFigures
  CALL SpriteAddress
  CALL AddColumnPointers
  INC C
  LD A,C
  CP $1B
  JR NZ,DrawBearersNext
  XOR A
  LD C,A
DrawBearersNext:
  DJNZ DrawBearersFigure
  JP BearerRowShow

; Draw the four carried items from the inventory log, row 17 of the panel
;
; The entries InventoryLog $5B7C + BearerFirst $5C23 on (4, wrapping at 27):
; the item sprite ($8400 + 72 * item), or BlankSprite $5C46 for a free entry
; ($FF); drawn at $5036 (row 17, columns 22-30) by BearerItemsShow $9F70. The
; wrap ran in c1, explorers, r16000 and r34000.
;
; Witness: L1 1139 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
DrawBearerItems:
  LD B,$04
  LD A,(BearerIndex)
  LD IY,PanelColumns
  LD L,A
  LD C,A
  LD H,$00
  LD DE,BearerLoads
  ADD HL,DE
  PUSH HL
  POP IX
DrawBearerItemsEntry:
  LD A,(IX+$00)
  CP $FF
  JR NZ,DrawBearerItemsItem
  LD HL,BlankIcon
  JR DrawBearerItemsStore
DrawBearerItemsItem:
  LD DE,ItemSprites
  CALL SpriteAddress
DrawBearerItemsStore:
  CALL AddColumnPointers
  INC IX
  INC C
  LD A,C
  CP $1B
  JR NZ,DrawBearerItemsNext
  LD C,$00
  LD IX,BearerLoads
DrawBearerItemsNext:
  DJNZ DrawBearerItemsEntry
  JR BearerItemsShow

; DrawSpareLives: blit the 9 columns at $5081
;
; Witness: L1 11 (c1, explorers, rzx, rzx, rzx, rzx, rzx).
SpareLivesShow:
  LD IY,PanelColumns
  LD HL,Screen+4225
  JR Blit9Columns

  ORG $9F6B

; DrawBearers: the bearer figures at $5096, scrolled by BearerScroll
;
; Witness: L1 1139 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
BearerRowShow:
  LD HL,Screen+4246
  JR ShowScrolled
; This entry point is used by the routine at DrawBearerItems.
BearerItemsShow:
  LD HL,Screen+4150             ; DrawBearerItems: the items at $5036

; Skip BearerScroll $5C22 columns of the column list, then blit 9
;
; Witness: L1 2278 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx).
ShowScrolled:
  LD IY,PanelColumns
  LD A,(BearerPhase)
  OR A
  JR Z,Blit9Columns
ShowScrolledSkip:
  INC IY
  INC IY
  DEC A
  JR NZ,ShowScrolledSkip

; Blit 9 columns of the column list
;
; Witness: L1 2289 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx).
Blit9Columns:
  LD B,$09

; Blit B 24-row columns from the pointer list IY to the screen at HL
;
; Each column: the 24 bytes at the next word of the list, one a pixel row down
; from HL (NextCharRow $9DBF past each character row), then HL one cell right.
; The panel's 24 x 24 icons go through it. Callers: DrawPortrait,
; DrawMenuGlobes, and the shows above (63 594 NextCharRow calls).
;
; Witness: L1 21217 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx).
BlitColumns:
  PUSH HL
  PUSH BC
  LD E,(IY+$00)
  LD D,(IY+$01)
  LD B,$18
BlitColumnsRow:
  LD A,(DE)
  INC DE
  LD (HL),A
  INC H
  LD A,H
  AND $07
  JR NZ,BlitColumnsNext
  PUSH DE
  CALL NextCharRow
  POP DE
BlitColumnsNext:
  DJNZ BlitColumnsRow
  POP BC
  POP HL
  INC L
  INC IY
  INC IY
  DJNZ BlitColumns
  RET

; HL = DE + 72 * A: sprite A of the table at DE
;
; Witness: L1 8130 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx).
SpriteAddress:
  PUSH DE
  LD L,A
  LD H,$00
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  PUSH HL
  ADD HL,HL
  ADD HL,HL
  ADD HL,HL
  POP DE
  ADD HL,DE
  POP DE
  ADD HL,DE
  RET

; Add the three column pointers HL, HL + 24, HL + 48 of a sprite to the list at
; IY
;
; Out: IY 6 on, HL + 48. Builds PanelColumns $5BD6 for BlitColumns.
;
; Witness: L1 9352 (c1, explorers, gameover, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx, rzx,
; rzx, rzx, rzx, rzx, rzx, rzx, rzx).
AddColumnPointers:
  LD (IY+$00),L
  LD (IY+$01),H
  INC IY
  INC IY
  LD DE,$0018
  ADD HL,DE
  LD (IY+$00),L
  LD (IY+$01),H
  ADD HL,DE
  INC IY
  INC IY
  LD (IY+$00),L
  LD (IY+$01),H
  INC IY
  INC IY
  RET

; The four bearer figures under the carried items, 24 x 24 sprites
;
; Drawn by DrawBearers $9EBD (figure = log index AND 3), each 72 bytes in three
; columns of 24 (a row of 24 below = one column). start-room-14.png shows three
; of them at row 20, columns 22-30. Read in every play build (246 722 reads).
BearerFigures:
  INCBIN "res/sprites/bearers.bin",$0000,72
BearerFigure1:
  INCBIN "res/sprites/bearers.bin",$0048,72
BearerFigure2:
  INCBIN "res/sprites/bearers.bin",$0090,72
BearerFigure3:
  INCBIN "res/sprites/bearers.bin",$00D8,72
