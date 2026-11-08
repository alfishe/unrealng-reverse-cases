; --------------------------------------------------------------------------------------------------------------------
; hud.asm: The cell maps cleared and saved, the HUD numbers
; --------------------------------------------------------------------------------------------------------------------

; Zero the block map $6100-$63BF (22 rows of 32)
;
; Called by BuildScreen and by the menu ($6DA1) and the define-keys screen
; ($6FAB), which print through $AF2B too.
ClearBlockMap:
  LD HL,CellTypes
  LD DE,CellTypes+1
  LD BC,$02BF
  LD (HL),$00
  LDIR
  RET

; Fill the open-cell map $5B00-$5DBF with $FF (all cells open)
;
; The printer writes 0 (or $FF after code $EA) into it for every glyph; the
; sprite drawers $777F / $79DD AND a sprite's cells: all $FF draws the fast
; way, a 0 cell means scenery in front.
FillOpenMap:
  LD HL,OpenCells
  LD DE,OpenCells+1
  LD BC,$02BF
  LD (HL),$FF
  LDIR
  RET

; Copy the screen attributes $5800-$5AFF to the shadow $5E00-$60FF
;
; The scenery's colours once a screen is built: the shot and shell drawers and
; the player's colouring look at it to colour only black cells.
SaveAttributes:
  LD DE,AttrCopy
  LD HL,$5800
  LD BC,$0300
  LDIR
  RET

; Print A (0-99) as two digits at D, E in attribute C, in the main font $D7E0
;
; The hundreds are taken off without printing ($8E37 with B = 100), then the
; tens and the units. BC, HL kept; E ends past the digits.
PrintTwoDigits:
  PUSH BC
  PUSH HL
  LD HL,FontBase
  LD (PrintChar+$000E),HL
  LD B,$64
  CALL HudDigit
  LD B,$0A
  CALL HudDigit
  LD B,$01
  CALL HudDigit
  POP HL
  POP BC
  RET

; L = A / B, A = A mod B; print L as a digit at D, E and step E (not for B =
; 100)
;
; Used by the routine at PrintTwoDigits.
HudDigit:
  LD L,$00
HudDigitCount:
  SUB B
  JR C,HudDigitOut
  INC L
  JR HudDigitCount
HudDigitOut:
  ADD A,B
  PUSH AF
  LD A,B
  CP $64
  JR Z,HudDigitDone
  LD A,L
  ADD A,$30
  CALL PrintCharAttr
  INC E
HudDigitDone:
  POP AF
  RET

; Print Ammo on the HUD: row 23 column 1, bright white ($47)
;
; Called by the HUD $7690, FireControl, the pod pick-up $9942 and the death
; $9CE3.
PrintAmmo:
  LD A,(Ammo)
  LD DE,$1701
  LD C,$47
  JP PrintTwoDigits

; The ammunition 0-99 (99 at the start, after a death and at an ammunition
; pod); the ZXDB POKE 33646 is its DEC A ($836E)
Ammo:
  DEFB $63

; Print Grenades on the HUD: row 23 column 8, bright red ($43)
;
; Used by the routines at DrawHud, GrenadeStart, Pods and PlayerDeath.
PrintGrenades:
  LD A,(Grenades)
  LD DE,$1708
  LD C,$43
  JP PrintTwoDigits

; The grenades 0-10 (10 at the start, after a death and at a grenade pod); POKE
; 37456 at $9250
Grenades:
  DEFB $0A

; Print Lives as one digit on the HUD: row 23 column 23, bright yellow ($46)
;
; Used by the routines at DrawHud and PlayerDeath.
PrintLives:
  LD A,(Lives)
  ADD A,$30
  LD DE,$1717
  LD C,$46
  LD HL,FontBase
  LD (PrintChar+$000E),HL
  JP PrintCharAttr

; The lives 0-9 (9 at the entry $6D97; - 1 at $9D1D, the ZXDB POKE 40221; + 1
; up to 9 at the round end)
Lives:
  DEFB $09

; Print ScreenNumber as ZONES on the HUD: row 23 column 28, bright yellow,
; three digits ($B0C6)
;
; Called by the HUD $7690 and ScreenChangeCheck.
PrintZone:
  LD A,(ScreenNumber)
  LD DE,$171C
  LD C,$46
  JP PrintNumber3
