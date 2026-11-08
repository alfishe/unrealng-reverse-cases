; --------------------------------------------------------------------------------------------------------------------
; pickups.asm: The teleports, the ammunition and grenade pods, the printers, the abort keys
; --------------------------------------------------------------------------------------------------------------------

; Up while standing in one teleport moves the player to the other
;
; Main loop, every pass. Up ($7B94, the Kempston bit 3 / the up key) not
; pressed: the latch TeleportLatch cleared. Pressed and the latch clear: the
; latch set, then if the player stands under pad 1 (his top line Y the line
; below the pad's row, his X within E-12..E+8) the teleport: a sparkle ($9ED9)
; at pad 1, the sound $C162, a sparkle at pad 2, the player put at pad 2 (X =
; pad X - 3, Y the line below its row, frame 5, $8224). Else the same test from
; pad 2 to pad 1.
;
; A screen has at most one pair (map value 6: TeleportPads, the map cell set to
; 1). Screens 2, 6, 8 have one; w clones teleported 4 times (pad 1 to 2) and 32
; times (pad 2 to 1).
Teleports:
  LD A,(ControlJump)
  OR A
  JR NZ,TeleportPressed
  LD (TeleportLatch),A
  RET
TeleportPressed:
  LD A,(TeleportLatch)    ; up held: once per press
  OR A
  RET NZ
  INC A
  LD (TeleportLatch),A
  LD DE,(TeleportPads)    ; pad 1: none on this screen ($FF)
  BIT 7,E
  RET NZ
  INC D
  CALL CellToPixels
  LD A,(PlayerY)          ; the player's top line under the pad?
  CP D
  JR NZ,TeleportFromPad2
  LD A,(PlayerX)
  SUB E
  SUB $09
  CP $EB
  JR C,TeleportFromPad2
  CALL StartSparkle       ; to pad 2
  LD DE,(TeleportPad2)
  INC D
  CALL CellToPixels
  CALL PlaySfxPulse
  CALL StartSparkle
  DEC E
  DEC E
  DEC E
  LD A,$05
  JP PlayerFrame
TeleportFromPad2:
  LD DE,(TeleportPad2)    ; the same from pad 2
  INC D
  CALL CellToPixels
  LD A,(PlayerY)
  CP D
  RET NZ
  LD A,(PlayerX)
  SUB E
  SUB $09
  CP $EB
  RET C
  CALL StartSparkle       ; to pad 1
  LD DE,(TeleportPads)
  INC D
  CALL CellToPixels
  CALL StartSparkle
  DEC E
  DEC E
  DEC E
  CALL PlaySfxPulse
  LD A,$05
  JP PlayerFrame

; The teleport pair of the screen: pad 1 (column, row), pad 2 (column, row),
; $FF, the latch
;
; Built by $8E86 from map value 6 (record 6 of $8EF4). $FF in the first byte:
; no teleports.
TeleportPads:
  DEFB $00,$00
TeleportPad2:
  DEFB $00,$00
  DEFB $FF                ; the end mark
TeleportLatch:
  DEFB $00                ; non-zero while up is held after a teleport test

; E = 4 E, D = 8 D: a cell (column, row) to a position (X in 2-pixel units, Y
; in pixels)
;
; Every register but DE kept. Callers: Mines, Teleports, Pods, SpawnBalls,
; Guns, Traps, TrapContact, and $9F2D, $A30B, $A7D6, $A817, $ABCF, $AC04,
; PrintString $B03E.
CellToPixels:
  PUSH AF
  LD A,E
  ADD A,A
  ADD A,A
  LD E,A
  LD A,D
  ADD A,A
  ADD A,A
  ADD A,A
  LD D,A
  POP AF
  RET

; The ammunition pod and the grenade pod: walking into one refills
;
; Main loop, every pass. AmmoPod (map value 7) and GrenadePod (map value 8,
; $99F5) hold one cell each ($FF: none). A pod is taken when the player's X is
; within 12 units left of its (column + 1) and his top line Y is two rows above
; its row: the pod's picture is printed again with printer 4 (XorMarkPrinter
; $AEE4: XOR erases it) from the strings $887E (ammunition) / $888F (grenades)
; of the element table, the pod marked $FF, the ammunition set to 99 ($8E5A,
; printed by $8E4F, sound $C0F4) or the grenades to 10 ($8E66, $8E5B, sound
; $C101); the player redrawn ($8269 forced to $FF, $8229) and five beeper
; sweeps $7C3C (48K only).
;
; w clones: 53 ammunition and 33 grenade pods taken.
Pods:
  LD DE,(AmmoPod)
  BIT 7,E
  JR NZ,GrenadePodTest
  DEC D                   ; the test point: two rows up, one column right
  DEC D
  INC E
  CALL CellToPixels
  LD A,(PlayerX)
  SUB E
  CP $F4
  JR C,GrenadePodTest
  LD A,(PlayerY)
  CP D
  JR NZ,GrenadePodTest
  LD DE,(AmmoPod)         ; taken: erase the pod
  LD A,$04
  CALL SetPrinter
  LD HL,ElementAmmoPod
  LD C,$00
  CALL PrintString
  XOR A
  CALL SetPrinter
  LD A,$FF
  LD (AmmoPod),A
  LD A,$63                ; ammunition 99
  LD (Ammo),A
  CALL PrintAmmo
  CALL PlaySfxAmmoRefill
  LD A,(PlayerFrameShown) ; the player redrawn (his frame kept)
  LD B,A
  LD A,$FF
  LD (PlayerFrameShown),A
  LD A,B
  LD DE,(PlayerX)
  CALL DrawPlayer
  LD B,$05                ; five chirps
AmmoPodChirps:
  CALL BeeperSweep
  DJNZ AmmoPodChirps
GrenadePodTest:
  LD DE,(GrenadePod)      ; the same for the grenade pod
  BIT 7,E
  RET NZ
  DEC D
  DEC D
  INC E
  CALL CellToPixels
  LD A,(PlayerX)
  SUB E
  CP $F4
  RET C
  LD A,(PlayerY)
  CP D
  RET NZ
  LD DE,(GrenadePod)
  LD A,$04
  CALL SetPrinter
  LD HL,ElementGrenadePod
  LD C,$00
  CALL PrintString
  XOR A
  CALL SetPrinter
  LD A,$FF
  LD (GrenadePod),A
  LD A,$0A                ; grenades 10
  LD (Grenades),A
  CALL PrintGrenades
  CALL PlaySfxGrenadeRefill
  LD A,(PlayerFrameShown)
  LD B,A
  LD A,$FF
  LD (PlayerFrameShown),A
  LD A,B
  LD DE,(PlayerX)
  CALL DrawPlayer
  LD B,$05
GrenadePodChirps:
  CALL BeeperSweep
  DJNZ GrenadePodChirps
  RET

; The ammunition pod (column, row), $FF after it; $FF in the first byte: taken
; or none
AmmoPod:
  DEFB $00,$00
  DEFB $FF                ; the end mark
GrenadePod:
  DEFB $00,$00            ; the grenade pod (column, row), $FF after it
  DEFB $FF                ; the end mark

; Select the character printer of PrintString: A = 0-4 from Printers
;
; Patches the four CALL operands of PrintString $AF2B ($AF33, $AFC0, $AFD2,
; $AFFE) with Printers[A]. 0: $ADE1 (the plain printer, the maps written), 3:
; $AE95 (XOR, the maps cleared, two debris pieces a character), 4: $AEE4 (XOR,
; the maps cleared, no debris). Callers: MineBlast and GrenadeBlast (3), Pods
; (4); each sets 0 again after its print. BC, HL kept.
SetPrinter:
  PUSH BC
  PUSH HL
  LD BC,Printers
  CALL TableWord
  LD (PrintString+$0008),HL
  LD (PrintStringRowLoop+$0001),HL
  LD (PrintStringColumnLoop+$0001),HL
  LD (PrintStringSpace+$0012),HL
  POP HL
  POP BC
  RET

; The five character printers of SetPrinter: $ADE1, $AE26, $AE5D, $AE95, $AEE4
Printers:
  DEFW PrintChar,PrintCharAttr,XorCharAttr,EraseBlockDebris,EraseBlock

; 7, 8, 9 and 0 held together restart the game
;
; Main loop, every pass (c1: 3260). Reads the keyboard half-row $EFFE (0 9 8 7
; 6); with the four keys 0, 9, 8, 7 down (bits 0-3 all 0) it falls into
; AbortGame.
AbortKeys:
  LD A,$EF
  IN A,($FE)
  AND $0F
  RET NZ

; JP $6D60: back to the game's entry (the menu)
;
; Data in the mechanical cut: no recording held the four keys; exC's t1 did
; (frame 1750) and the jump ran once.
AbortGame:
  JP Start
