; --------------------------------------------------------------------------------------------------------------------
; stubs.asm: the 128K hook stubs: one engine sound at each event the 48K beeped at
;
; The set-up copies the shared stub HookSound first, then the hooks one after another, writing each hook's address
; into its call site in the game as it goes (docs/03-build-and-load.md 3.5). A hook is the instruction its site lost
; (when the site was not the beeper call itself), PUSH HL, LD L with the low byte of an engine entry, and a jump to
; HookSound. HookSound writes $C9 and L into its own CALL, pages the engine in, calls it, pages the game back and
; returns with the caller's HL (the PUSH HL of the hook): the site goes on as before.
; --------------------------------------------------------------------------------------------------------------------

; page 4 in, CALL $C9xx (xx = L), page 0 back; HL from the stack, every other
; register kept
;
; Input: L = the engine entry's low byte, the caller's HL on the stack (pushed
; by the hook), the site's return address under it. The entry is written into
; the CALL's operand (EngineCall + 1, self-modifying). IX, AF, DE and BC are
; kept around the call; HL is the one the hook pushed. It does not disable
; interrupts.
HookSound:
  LD H,$C9
  LD (EngineCall+$0001),HL
  PUSH IX                 ; IX, AF, DE, BC kept
  PUSH AF
  PUSH DE
  PUSH BC
  LD A,PAGE4              ; page 4: the engine
  LD BC,PORT_7FFD
  OUT (C),A
EngineCall:
  CALL $0000              ; CALL $C9xx: the operand written above
  LD A,PAGE0              ; page 0: the game
  LD BC,PORT_7FFD
  OUT (C),A
  POP BC                  ; the registers back, HL the hook's
  POP DE
  POP AF
  POP IX
  POP HL
  RET

; the player fires (site $9C77, the beeper call): sound $0E
;
; Entry $C971. The site is the shot routine's CALL $B2F0 (48K sound 2) after it
; takes a free shot slot.
HookShot:
  PUSH HL
  LD L,$71                ; the low byte of the engine entry $C971
  JR HookSound

; an extra life given (site $ACA2): CALL DrawLives, then sounds $0F + $10
;
; Entry $C975. $AC7A compares the score's second BCD byte with the $800F table
; (01 03 05 07 09 FF): a life at 10 000, 30 000, 50 000, 70 000 and 90 000 (INC
; (IX+12), INC (IX+4)); DrawLives redraws the ship icons first. Witnessed in r1
; frame 6590 (docs/09-sound.md 9.2).
HookExtraLife:
  CALL DrawLives
  PUSH HL
  LD L,$75                ; the low byte of the engine entry $C975
  JR HookSound

; a plasma bomb bounces off the ground (site $9EC2): CALL BombBounceStep, then
; sound $11
;
; Entry $C97B. The bomb handler $9E67 negates and halves the vertical speed on
; a scenery hit and counts DEC (IY+38): three bounces, then the bomb is removed
; at $9ECE. Witnessed in r1, 22 frames from 1141.
HookBombBounce:
  CALL BombBounceStep
  PUSH HL
  LD L,$7B                ; the low byte of the engine entry $C97B
  JR HookSound

; the role of honour shown (site $A81B): CALL ShowHonour, then sound $12
;
; Entry $C97F.
HookHonour:
  CALL ShowHonour
  PUSH HL
  LD L,$7F                ; the low byte of the engine entry $C97F
  JR HookSound

; the role of honour's result (site $A8B7): CALL HonourResult, then sounds $14
; + $15
;
; Entry $C987.
HookHonourResult:
  CALL HonourResult
  PUSH HL
  LD L,$87                ; the low byte of the engine entry $C987
  JR HookSound

; the player's ship destroyed (site $9BFF, which lost LD ($8072),A): the store,
; then sounds $14 + $15
;
; Entry $C987, the same as HookHonourResult's.
HookShipLost:
  LD (ShipLostFlag),A
  PUSH HL
  LD L,$87                ; the low byte of the engine entry $C987
  JR HookSound

; a homing missile launched (site $9CFA): CALL LaunchFromShip, then sounds $1A
; + $1B
;
; Entry $C98B. $9CCA runs while fire is held with a lock ($80E2 not 0);
; LaunchFromShip goes through HookSpecialLaunch, so a launch plays $18 and then
; $1A + $1B in the same tick. Witnessed in r2 frames 127 and 287.
HookHomingLaunch:
  CALL LaunchFromShip
  PUSH HL
  LD L,$8B                ; the low byte of the engine entry $C98B
  JR HookSound

; a pod taken, the highlight moves on (site $A247): CALL TakePod, then sound
; $16
;
; Entry $C991.
HookPodTaken:
  CALL TakePod
  PUSH HL
  LD L,$91                ; the low byte of the engine entry $C991
  JR HookSound

; a special weapon placed at the ship (site $9CB0, which lost LD HL,$F36F): the
; load, then sound $18
;
; Entry $C999. $9CB0 is the shared launch from the ship's place, reached from
; the bombs ($9C83, fire held 3 frames), the homing missiles ($9CFA) and the
; seekers ($9D1F). Witnessed in r1 (bombs, 9 frames from 1113) and r2 (homing).
HookSpecialLaunch:
  LD HL,ShipPlace
  PUSH HL
  LD L,$99                ; the low byte of the engine entry $C999
  JR HookSound

; an enemy fires a missile at the ship (site $A1C4, the beeper call): sound $19
;
; Entry $C99D.
HookEnemyMissile:
  PUSH HL
  LD L,$9D                ; the low byte of the engine entry $C99D
  JR HookSound

; a weapon selected (site $A21A): CALL SelectWeapon, then sound $0F
;
; Entry $C9A1. A pod taken with fire held 8 frames or more ($8184 >= 8) runs
; the highlighted entry (player record +7) of the table at $80F0: 0 speed, 1
; laser, 2 bombs, 3 homing, 4 seekers. Witnessed in r1 frames 1097 and 1713.
HookWeaponSelect:
  CALL SelectWeapon
  PUSH HL
  LD L,$A1                ; the low byte of the engine entry $C9A1
  JR HookSound

; a pod appears (site $A31D, the beeper call): sound $1C
;
; Entry $C9A9. An object gets the pod descriptor $7EBB (29 times in r1).
HookPodAppears:
  PUSH HL
  LD L,$A9                ; the low byte of the engine entry $C9A9
  JR HookSound

; an explosion starts (site $A29F, which lost LD HL,ExplosionPattern): the
; load, then sound $1D
;
; Entry $C9AD.
HookExplosion:
  LD HL,ExplosionPattern
  PUSH HL
  LD L,$AD                ; the low byte of the engine entry $C9AD
  JP HookSound

; the SELECTIONS screen (site $A7BB, which lost LD HL,$82E0): the music off,
; the load, sounds $1E + $1F
;
; Entry $C9B1. Key 1 or 2 on the title's credits page runs $A76F, then $A790;
; MusicSwitch with A = 0 stops the tune first. Witnessed in r1 frame 23.
HookSelections:
  XOR A
  CALL MusicSwitch
  LD HL,SelectionsText
  PUSH HL
  LD L,$B1                ; the low byte of the engine entry $C9B1
  JP HookSound

; the screen wipe (sites $A5D1, title key 3 KEYBOARD DEFINITION, and $A7F7, the
; game over): the music off, CALL ScreenWipe, sounds $1E + $1F
;
; Entry $C9B1, the same as HookSelections's. Both sites are patched to this
; hook.
HookScreenWipe:
  XOR A
  CALL MusicSwitch
  CALL ScreenWipe
  PUSH HL
  LD L,$B1                ; the low byte of the engine entry $C9B1
  JP HookSound
