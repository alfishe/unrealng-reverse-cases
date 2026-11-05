; --------------------------------------------------------------------------------------------------------------------
; objects.asm: Enemy fire, explosions, weapon pods and enemy shots
;
; The per-kind handlers of the moving objects that are not enemies proper. An object record is 44 bytes (IY); +0/+1
; points at its animation record ($7EA1 explosion, $7EBB pod), +2 is the animation frame, +3..+6 the X and Y (fixed
; point, high bytes the cell), +7 the kind, +8 flags, +$24 the object's bit in the per-pass masks, +$25 the colour,
; +$26/+$27 per-kind counters.
;
; The handler of an object is found by its kind in a pointer table: kind 3 (explosion) is ExplosionStep (pointer at
; $8100), kind 4 (weapon pod) is PodStep ($8102), kind 5 (enemy shot) is EnemyShotStep ($8104). An enemy turns into an
; explosion with StartExplosion; an explosion with a pod to leave (+$26 not zero) turns into a pod with ExplosionToPod
; when its 9 frames are out.
;
; EnemyFire is called by the enemy movers: it spends one of the three enemy shot records at $F474 when the enemy's
; fire rate wins against a random number, with a fixed, a random or an aimed direction (the player at $F36C).
; --------------------------------------------------------------------------------------------------------------------

; Let the enemy at IY fire a shot
;
; IY: an enemy record. An enemy fires when its fire rate +$18 is not zero and
; either it has not fired yet (+8 bit 6 clear) and stands in the trigger column
; $80E7, or in a pass its bit +$24 selects ($7F63 PassBit) a random number
; (Random $8544) less $80E8 is below the rate.
;
; A shot costs one of the shots left in $8074 (none left: no shot) and takes
; the first free of the three shot records at $F474 (44 bytes each, +8 bit 7
; the busy flag). It starts at the enemy's position + $0180 (1.5 cells right
; and down, Y clamped to row 15), takes its speed from +$19 (bits 0-2 the step,
; bits 3-7 the speed index), its colour from +$20, its lifetime from +$22 and
; its direction from +$21:
;
; +$21 bits 0-1 = 00: the fixed direction in bits 2-7; 10: a random direction
; ($7F71 & $3F); x1: aimed at the player (DirectionTo $989F from the shot to
; the player record $F36C), with bit 1 set spread by -4..+3 ($7F71 & 7 - 4).
; The direction (0-63) goes to +$16, SetVelocity $98F1 turns it into the
; velocity, sound 1 (StartSound $B2F0) plays, the enemy's +8 bit 6 records the
; shot.
;
; Callers: the enemy movers at $9FA2, $9FEB and $A06E (EnemyHandler). Evidence:
; c2 L1 entries at $A0EB during waves with firing enemies; the record layout
; read off the stores below.
EnemyFire:
  LD A,(IY+$18)           ; no fire rate: the enemy never fires
  AND A
  RET Z
  BIT 6,(IY+$08)          ; fired already: only the random test
  JR NZ,EnemyFireRandom
  LD A,(WeaponRatingMask) ; the first shot when the enemy reaches the trigger
                          ; column
  CP (IY+$04)
  JR Z,EnemyFireSpend
EnemyFireRandom:
  LD HL,PassBit           ; the enemy's turn this pass ($7F63 PassBit AND its
                          ; bit)
  LD A,(IY+$24)
  AND (HL)
  RET Z
  CALL Random             ; Random - $80E8 below the fire rate: fire
  LD HL,WeaponRatingValue
  SUB (HL)
  JR C,EnemyFireSpend
  CP (IY+$18)
  RET NC
EnemyFireSpend:
  LD HL,EnemyShotsLeft    ; a shot left?
  LD A,(HL)
  AND A
  RET Z
  DEC (HL)
  LD IX,EnemyShots        ; the three enemy shot records
  LD DE,$002C
  LD B,$03
EnemyFireFindSlot:
  BIT 7,(IX+$08)          ; the first record without bit 7 of +8
  JR Z,EnemyFireShot
  ADD IX,DE
  DJNZ EnemyFireFindSlot
EnemyFireShot:
  SET 7,(IX+$08)          ; take it
  LD DE,$0180             ; the shot starts 1.5 cells right and down from the
                          ; enemy
  LD L,(IY+$03)
  LD H,(IY+$04)
  ADD HL,DE
  LD (IX+$03),$00
  LD (IX+$04),H
  LD L,(IY+$05)
  LD H,(IY+$06)
  ADD HL,DE
  BIT 4,H                 ; past row 15: keep it on row 15
  JR Z,EnemyFireSetY
  LD H,$0F
EnemyFireSetY:
  LD (IX+$05),$00
  LD (IX+$06),H
  PUSH IY
  LD A,(IY+$19)           ; +$19: bits 0-2 the step count, bits 3-7 the speed
                          ; index
  AND $07
  LD B,A
  LD A,(IY+$20)           ; colour of the shot
  LD (IX+$27),A
  LD (IX+$28),A
  LD A,(IY+$19)
  LD C,A
  AND $07
  LD (IX+$17),A
  XOR C
  RRCA
  RRCA
  RRCA
  LD (IX+$2B),A
  LD A,(IY+$22)           ; lifetime of the shot
  LD (IX+$26),A
  LD A,(IY+$21)           ; +$21: the direction mode
  PUSH IX                 ; IY = the shot from here on
  POP IY
  BIT 0,A
  JR NZ,EnemyFireAimed
  BIT 1,A
  JR NZ,EnemyFireRandomDir
  AND $FC                 ; mode 00: a fixed direction in bits 2-7
  RRCA
  RRCA
  JR EnemyFireSetDir
EnemyFireRandomDir:
  LD A,(RandomSeed)       ; mode 10: any of the 64 directions
  AND $3F
  JR EnemyFireSetDir
EnemyFireAimed:
  BIT 1,A                 ; mode x1: at the player, bit 1 adds a spread of
                          ; -4..+3
  LD C,$00
  JR Z,EnemyFireAim
  LD A,(RandomSeed)
  AND $07
  SUB $04
  LD C,A
EnemyFireAim:
  LD IX,PlayerObject      ; the player's record
  PUSH BC
  CALL DirectionTo
  POP BC
  ADD A,C
  AND $3F
EnemyFireSetDir:
  LD (IY+$16),A           ; +$16 the direction 0-63, then the velocity from it
  LD B,(IY+$17)
  CALL SetVelocity
  POP IY
  SET 6,(IY+$08)          ; the enemy has fired
  LD A,$01                ; sound 1: the enemy shot
  CALL RequestEffect      ; GS: the installer points this CALL at EnemyFireHook
                          ; ($FF60): FX 4, an enemy fires
  RET

; Advance an explosion (object kind 3)
;
; IY: the explosion. Runs in odd passes only ($7F62 bit 0). +$27 counts down
; the passes a frame is held: while it lasts the colour +$25 is 0 (the frame is
; drawn black, a flash); when it runs out the animation frame +2 advances.
;
; After frame 8 the explosion ends: removed (RemoveObject $992A) when +$26 is
; 0, otherwise it leaves a weapon pod (ExplosionToPod). Handler pointer at
; $8100.
ExplosionStep:
  LD A,(PassCount)        ; every other pass
  AND $01
  RET Z
  DEC (IY+$27)            ; hold the frame
  JP M,ExplosionNextFrame
  XOR A                   ; black while held
  LD (IY+$25),A
  RET
ExplosionNextFrame:
  LD A,(IY+$02)
  INC A
  CP $09                  ; past frame 8: the end
  JR NZ,ExplosionAdvance
  LD A,(IY+$26)           ; a pod to leave?
  AND A
  JP Z,FreeEnemySlot
  JP ExplosionToPod

; A RET no code reaches
;
; $C9: a RET after the JP of ExplosionStep; no jump or call leads here (a
; leftover of an edit of the routine).
UnusedRet:
  DEFB $C9

; Store the explosion's frame and fade its colour
;
; A: the next frame (1-8). The colour +$25 steps down by 8 (one INK step, the
; bright bit kept off by AND $78) until it reaches $50. Used by ExplosionStep.
ExplosionAdvance:
  LD (IY+$02),A
  LD A,(IY+$25)           ; colour $50: stop fading
  CP $50
  RET Z
  SUB $08
  AND $78
  LD (IY+$25),A
  RET

; A weapon pod (object kind 4): collected or carried by the scroll
;
; IY: the pod. Collected when the player's hit mask $F379 has the pod's bit
; +$24. IX = the current player's record ($7F99).
;
; Collecting with fire held for 8 or more passes ($8184 FireHeld) activates the
; weapon the selector record+7 points at: the selector goes back to 0 and the
; weapon's routine from the table $80F0 is called (CallFromTable $91E2), sound
; 6.
;
; Collecting without fire moves the selector to the next weapon (sound 5); past
; the fifth it wraps to 0, awards 1000 points (AddScore 9) and sets the power
; timer $80E6 to $B4. Either way the HUD bit 2 of $81C5 is set, 100 points are
; awarded (AddScore 4) and the pod is removed.
;
; Not collected: the pod moves with the scenery (ScrollObject $9640), its
; colour follows the colour cycle $80BC; once +8 bit 5 is clear (off the
; playfield) the power timer $80E6 is halved and the pod is removed. Handler
; pointer at $8102.
PodStep:
  LD A,(PlayerHitMask)    ; the player touches the pod?
  AND (IY+$24)
  JR Z,PodDrift
  LD IX,(PlayerRecord)
  LD A,(FireHeld)         ; fire held 8 passes or more: activate the selected
                          ; weapon
  CP $08
  JR C,PodSelectNext
  LD A,(IX+$07)           ; the selector back to the first weapon
  LD (IX+$07),$00
  LD HL,PodActions        ; the weapon routines: $9D4C $9D5D $9D68 $9DA5 $9DDD
  CALL JumpTable
  LD A,$06                ; sound 6: weapon on
  CALL RequestEffect      ; GS: the installer points this CALL at WeaponOnHook
                          ; ($FF75): FX 3, a weapon switched on
  JR PodCollected
PodSelectNext:
  LD A,$05                ; sound 5: next weapon
  CALL RequestEffect      ; GS: the installer points this CALL at
                          ; NextWeaponHook ($FF81): FX 2, the pod selects the
                          ; next weapon
  LD A,(IX+$07)
  INC A
  CP $05                  ; past the fifth weapon: a bonus
  JR C,PodSetSelector
  XOR A
  LD A,$09                ; 1000 points
  CALL AddScore
  LD A,$B4                ; the power timer
  LD (Fuel),A
  XOR A
PodSetSelector:
  LD (IX+$07),A
PodCollected:
  LD HL,EventRequests     ; the weapon panel needs a redraw
  SET 2,(HL)
  LD A,$04                ; 100 points
  CALL AddScore
  JR PodRemove
PodDrift:
  CALL PathOpScroll       ; not collected: move with the scenery
  LD A,(ColourCycle)      ; flashing with the colour cycle
  LD (IY+$25),A
  BIT 5,(IY+$08)          ; still on the playfield: keep it
  RET NZ
  LD HL,Fuel              ; lost: halve the power timer
  SRL (HL)
PodRemove:
  CALL FreeEnemySlot
  RET

; Move an enemy shot (object kind 5)
;
; IY: the shot. It ends (FreeShot $9941) when its lifetime +$26 runs out, when
; it hits the player ($F379 AND +$24), when the playfield collision test $99A9
; reports carry, or when after the move (MoveObject $96E2) its Y is outside
; rows 0-16 or its X is outside columns 16-48 (the visible window). Handler
; pointer at $8104.
EnemyShotStep:
  DEC (IY+$26)            ; lifetime
  JR Z,EnemyShotEnd
  LD HL,PlayerHitMask     ; the player's hit mask
  LD A,(IY+$24)
  AND (HL)
  JR NZ,EnemyShotEnd
  CALL SceneryAt1         ; hit the scenery?
  JR C,EnemyShotEnd
  CALL PathOpHome         ; move by the velocity
  LD A,(IY+$06)           ; above the top or below row 16: gone
  AND A
  JP M,EnemyShotEnd
  CP $11
  JR NC,EnemyShotEnd
  LD A,(IY+$04)           ; left of column 16 or right of column 48: gone
  SUB $10
  JP M,EnemyShotEnd
  CP $21
  RET C
EnemyShotEnd:
  CALL FreeObject
  RET

; Turn the object at IY into an explosion
;
; Sets the three sound bit patterns ($7F80 = $FD00, $7F84 = $EDB2, $7F88 =
; $D6ED, shifted one bit a pass by PlayInterrupt: the explosion noise), kind 3,
; the animation record $7EA1 from frame 1, +$0B = $E0, +$27 = 0, colour $70 and
; X fraction 0. The object's bit +$24 leaves the mask $80BD and joins $80BE
; (from the shootable to the harmless objects).
;
; Callers: the hit handling at ScatterDebris and the enemy movers
; (EnemyHandler).
StartExplosion:
  LD HL,HitGridY          ; the explosion noise on the three channels
  LD (SoundPattern1),HL
  LD HL,SpriteCacheImages+$066A
  LD (SoundPattern2),HL
  LD HL,GlyphCacheUpper+$0EED
  LD (SoundPattern3),HL

; StartExplosionQuiet
;
; Used by the routines at ScatterDebris and LockableHandler.
StartExplosionQuiet:
  LD A,$03                ; kind 3: explosion (GS: the entry of $9BE6, $A034
                          ; and the explosion hook: the noise set-up above is
                          ; skipped)
  LD (IY+$07),A
  LD HL,ExplosionAnim     ; the explosion animation
  LD (IY+$00),L
  LD (IY+$01),H
  LD (IY+$02),$01
  LD (IY+$0B),$E0
  LD (IY+$27),$00
  LD A,(IY+$24)           ; the bit out of $80BD, into $80BE
  LD C,A
  CPL
  LD HL,HarmlessMaskA
  AND (HL)
  LD (HL),A
  INC HL
  LD A,(HL)
  OR C
  LD (HL),A
  LD (IY+$25),$70         ; the explosion colour
  XOR A
  LD (IY+$03),A
  RET

; Turn the finished explosion at IY into a weapon pod
;
; Rounds the Y to the nearest cell (+5 bit 7 carries into +6), then asks $99BB
; whether the cell is free (carry: no room, the object is removed). Otherwise:
; +$0B = $C0, kind 4, +$26 down by 2, the pod animation $7EBB (both branches of
; the JR Z load the same record), the bit +$24 back from $80BE to $80BD, colour
; 8, sound 4.
;
; Used by ExplosionStep.
ExplosionToPod:
  BIT 7,(IY+$05)          ; round Y to the cell
  LD (IY+$05),$00
  JR Z,ExplosionToPodPlace
  INC (IY+$06)
ExplosionToPodPlace:
  CALL SceneryAt4
  JP C,FreeEnemySlot
  LD A,$C0
  LD (IY+$0B),A
  LD A,$04                ; kind 4: pod
  LD (IY+$07),A
  LD A,(IY+$26)
  SUB $02
  LD (IY+$26),A
  LD HL,PodAnim           ; the pod animation (the same in both cases)
  JR Z,ExplosionToPodSet
  LD HL,PodAnim
ExplosionToPodSet:
  LD (IY+$00),L
  LD (IY+$01),H
  LD A,(IY+$24)           ; the bit out of $80BE, into $80BD
  LD C,A
  CPL
  LD HL,HarmlessMaskB
  AND (HL)
  LD (HL),A
  DEC HL
  LD A,(HL)
  OR C
  LD (HL),A
  LD (IY+$25),$08
  LD A,$04                ; sound 4: a pod appears
  CALL RequestEffect      ; GS: the installer points this CALL at
                          ; PodAppearsHook ($FF7B): FX 1, a weapon pod appears
  RET
