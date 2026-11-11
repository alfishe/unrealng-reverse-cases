; --------------------------------------------------------------------------------------------------------------------
; apivectors.asm: The vectors the mission code calls: one JP per bank-2 service
;
; The mission block (side 2, loaded at bank 0 $DBC5) is code as well as data; it reaches the resident routines through
; this table of 22 JP instructions at fixed addresses, so the resident code may move between releases without
; relinking the missions. Recording play: every vector runs (L1 counts in each entry); the callers are in $E1xx-$EBxx
; of the mission block.
; --------------------------------------------------------------------------------------------------------------------

; The mission code's service vectors: 22 JP instructions, $67BE-$67FF
;
; Each vector is a `JP` to a resident routine in bank 2 or 5: `$67BE` `$BFD1`,
; `$67C1` `$B766`, `$67C4` `$BCDA`, `$67C7` `$BD41`, `$67CA` `$C957`, `$67CD`
; `$CA3B`, `$67D0` `$A779`, `$67D3` `$A7AE`, `$67D6` `$A799`, `$67D9` `$A82C`,
; `$67DC` `$B660`, `$67DF` `$B6D1`, `$67E2` `$B282`, `$67E5` `$B6BD`, `$67E8`
; `$A899`, `$67EB` `$B611`, `$67EE` `$7040`, `$67F1` `$CC3C`, `$67F4` `$AA63`,
; `$67F7` `$AB7B`, `$67FA` `$AAF5`, `$67FD` `$AA47`. The mission code calls
; them (play: `$67D9` 220 482 times, `$67D6` 179 580).
;
; Witness: L1 15082 (death, m2erbe, missions, play, play2).
ApiVector00:
  JP MoveObject

; ApiVector01
;
; Used by the routines at TargetInConeBody and TurnToward.
ApiVector01:
  JP BearingTo

; ApiVector02
ApiVector02:
  JP FindFreeObject

; ApiVector03
;
; Used by the routines at FireCannon, LaunchProjectile, ActivateMissionObjects,
; LaunchDragonfly, LaunchMissile, FireDecoy and PlaceHelicarrier.
ApiVector03:
  JP ObjectSetType

; ApiVector04
;
; Used by the routines at FireCannon, LaunchProjectile, ActivateMissionObjects,
; LaunchDragonfly, LaunchMissile, FireDecoy and PlaceHelicarrier.
ApiVector04:
  JP RegisterCollision

; ApiVector05
;
; Used by the routines at KillGunEmplacement, HitTest, RemoveObject,
; ActivateMissionObjects, FindSlot, CameraToPlayer, PhantasmSpin and
; PlaceHelicarrier.
ApiVector05:
  JP UnregisterCollision

; ApiVector06
;
; Used by the routines at FlickerPlayer, Debris, DebrisVelocity,
; DebrisVelocityB, DrawRadar, PlayerHit, Cluster13Step and SoundFrame.
ApiVector06:
  JP Random

; ApiVector07
;
; Used by the routines at ResetViewOrigin, BearingOctant, CameraSinCos and
; RadarAddBlip.
ApiVector07:
  JP NegateHL

; ApiVector08
;
; Used by the routines at PlayerStep, TestVertexNearX, LaunchProjectile,
; ShowMortarRange, InRange, TargetInConeBody, TurnToward, HitSide,
; TerrainDiagonal, BoundaryCheck, SetAwolState and EngineTone.
ApiVector08:
  JP AbsA

; ApiVector09
;
; Used by the routines at BoxRect16 and RotateToView.
ApiVector09:
  JP MulWordByte

; ApiVector10
ApiVector10:
  JP HitTest

; ApiVector11
;
; Used by the routines at KillGunEmplacement, HitTest, Explode and
; MineCountdown.
ApiVector11:
  JP Debris

; ApiVector12
;
; Used by the routines at TerrainScanLoop and TerrainDiagonal.
ApiVector12:
  JP ByteToWorld

; ApiVector13
;
; Used by the routine at KillMissionObject.
ApiVector13:
  JP MarkDestroyed

; ApiVector14
;
; Used by the routines at OpPolarPoints, BoxRect, BoxTilted, RotateVertex,
; RotateAndStore, ShowMortarRange, GridVectors, SetElevation and
; PlaceHelicarrier.
ApiVector14:
  JP SinCos8

; ApiVector15
ApiVector15:
  DEFB $C3,$11,$B6

; ApiVector16
ApiVector16:
  JP ScreenFour

; ApiVector17
;
; Used by the routine at PlayerStep.
ApiVector17:
  JP TerrainCollision

; ApiVector18
;
; Used by the routine at BoxSquareTurret.
ApiVector18:
  JP BoxSquare

; ApiVector19
ApiVector19:
  JP BoxRect

; ApiVector20
ApiVector20:
  JP BoxRect16

; ApiVector21
ApiVector21:
  JP BoxSquareTurret

; Play work area $6800-$68A7 (play writes $6800-$682F)
PlayWork:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
  DEFB $00,$00,$00,$00,$00,$00,$00,$00

; The panel's gauges: five 6-byte records from $68AB, then the four slots'
; records from $68C9
;
; DrawWeaponBars `$72F9` redraws a record whose first byte (the value) changed;
; FlickerPlayer `$6B1D` tests `$68BD` (record 3) below 16.
PanelGauges:
  DEFB $00,$00,$00
GaugeRecords:
  DEFB $00,$05,$0F,$88,$00,$00
  DEFB $05,$0A,$16,$88,$00,$00
  DEFB $0F,$14,$1D,$88,$00,$00
  DEFB $00,$05,$16,$10,$00,$00
  DEFB $05,$0A,$1D,$10,$00,$00
SlotGauges:
  DEFB $12,$13,$16,$38,$0A,$00
  DEFB $11,$12,$1D,$38,$0F,$00
  DEFB $10,$0F,$16,$60,$14,$00
  DEFB $0E,$0D,$1D,$60,$19,$00
  DEFB $FF
GaugeEnd:
  DEFB $00,$00,$00,$00,$00,$00
  DEFB $00,$00
MissionClock:
  DEFB $00,$00,$11,$00,$00,$00 ; seconds, minutes, hours (ClockTick $7DFB);
  DEFB $00,$00,$00,$00         ; minutes and hours printed by PrintClock
