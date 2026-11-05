; --------------------------------------------------------------------------------------------------------------------
; effectdata.asm: The sound effects and the sprite descriptors of the ship, the shots and the explosions
;
; EffectPlay $B30C copies effect n (1-6) from EffectTable; the descriptors are the 13-byte sprite records an object's
; +0/+1 points at (the same layout as the first 13 bytes of a sprite cache record).
; --------------------------------------------------------------------------------------------------------------------

; The 6 sound effects, 8 bytes each, from effect 1
;
; EffectPlay $B30C: entry $7E5A + 8 (n - 1) -> EffectState $7F8A-$7F90 and the
; segment lengths $7F91/$7F92: +0 pitch A, +1 its step, +2 pitch B, +3 its
; step, +4 the step change per segment, +5 the segments, +6 the flags, +7 the
; segment lengths (nibbles). 48K c2 reads effects 1, 2 and 4 ($7E5A-$7E69,
; $7E72-$7E79).
EffectTable:
  INCBIN "res/effects/effects.bin",$0000,48

; 10 zero bytes after effect 6
;
; No reader in 48K c1/c2 (the request numbers in the code are 1-6 and $32).
EffectSpare:
  DEFB $00,$00,$00,$00,$00,$00,$00,$00,$00,$00

; The sprite descriptor of the ship (record $F36C +0/+1)
;
; +0/+1 the image ($E008), +4 and +6 the size of a shifted copy, +8 the height
; in rows (read by TestHitGrid $9150: $7E9C), +$0B the width (read $7E9F), +$0C
; the row mask.
ShipDescriptor:
  DEFB $08,$E0,$00,$00,$48,$00,$48,$00,$03,$07,$18,$03,$E0

; The explosion's sprite and animation record
;
; Set by StartExplosion $A293 (record +0/+1); MarkEnemyGrid $90CB reads +8/+$0B
; ($7EA9, $7EAC).
ExplosionAnim:
  DEFB $58,$E4,$30,$00,$00,$00,$00,$00,$03,$00,$18,$02,$E0

; The sight's sprite descriptor (record $F600, kind 6)
;
; TestHitGrid reads +8/+$0B ($7EB6, $7EB9).
SightDescriptor:
  DEFB $48,$E2,$00,$00,$48,$00,$48,$00,$03,$07,$18,$03,$E0

; The weapon pod's sprite and animation record
;
; Set by ExplosionToPod $A2D6; MarkEnemyGrid reads $7EC3, $7EC6.
PodAnim:
  DEFB $48,$F0,$00,$00,$30,$00,$18,$00,$03,$06,$10,$03,$C0

; The laser shot's sprite descriptor (the four records from $F4F8)
;
; TestHitGrid reads $7ED0, $7ED3.
LaserDescriptor:
  DEFB $08,$E6,$00,$00,$10,$00,$08,$00,$02,$06,$08,$02,$80

; The enemy shot's and the plasma ball's sprite descriptor
;
; MarkEnemyGrid and TestHitGrid read $7EDD, $7EE0.
ShotDescriptor:
  DEFB $48,$E6,$00,$00,$20,$00,$20,$00,$02,$07,$10,$02,$C0

; The sprite cache: record 0 and records 1-6, 16 bytes each
;
; GetSpriteCache $93A7 (48K c2: 7 entries): kinds $14 and up use record 0
; ($7EE2, its image at $C008, 7 x 7 cells) without caching; the others search
; records 1-6 for one of their kind (+$0E = kind OR $80, +$0D the use count) or
; take a free one. +0/+1 the image buffer ($E748, $E988, $EBC8, $EE08), +4/+6
; the size ($48, $60), +8 the rows, +$0B the width, +$0C the row mask, +$0F the
; record bit. LevelSetUp $8D28 clears the six use counts.
SpriteCache:
  DEFB $08,$C0,$00,$00,$F8,$01,$F8,$01,$07,$07,$38,$09,$FE,$00,$00,$00
SpriteCacheRecord1:
  DEFB $48,$E7,$00,$00,$48,$00,$48,$00,$03,$07,$18,$03,$E0 ; record 1 (the use
                                                           ; count +$0D at
                                                           ; $7EFF, the
                                                           ; search's first)
SpriteCacheUse1:
  DEFB $00,$00,$01        ; record 1's use count, the search's start ($93B3)
                          ; and LevelSetUp's ($8D22)
SpriteCacheRecord2:
  DEFB $88,$E9,$00,$00,$48,$00,$48,$00,$03,$07,$18,$03,$E0,$00,$00,$02
SpriteCacheRecord3:
  DEFB $C8,$EB,$00,$00,$48,$00,$48,$00,$03,$07,$18,$03,$E0,$00,$00,$04
SpriteCacheRecord4:
  DEFB $08,$EE,$00,$00,$48,$00,$48,$00,$03,$07,$18,$03,$E0,$00,$00,$08
SpriteCacheRecord5:
  DEFB $48,$E7,$00,$00,$60,$00,$60,$00,$03,$07,$18,$04,$E0,$00,$00,$03
SpriteCacheRecord6:
  DEFB $C8,$EB,$00,$00,$60,$00,$60,$00,$03,$07,$18,$04,$E0,$00,$00,$0C

; A seventh record of the same layout, out of the search (B = 6)
;
; No reader or writer in 48K c1/c2; its values follow the pattern of records 5
; and 6 (buffer $E988, size $60).
SpareCacheRecord:
  DEFB $88,$E9,$00,$00,$60,$00,$60,$00,$03,$07,$18,$04,$E0,$00,$00,$0C
