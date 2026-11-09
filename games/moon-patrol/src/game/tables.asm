; --------------------------------------------------------------------------------------------------------------------
; tables.asm: Tables: a build-date string, the sprite table and the tune
; --------------------------------------------------------------------------------------------------------------------

; A print string with the build date 02:45 29/10/84, disabled like
; BuildDate0335 $7F00
;
; Bytes: $1F (the end, where an AT $16 would be), x 0, line $31, FONT 2 ($1A
; $02), "02:45 29/10/84", $1F. Printed by the life start at $912C (LD HL,$B2C2;
; CALL $FFD0): only the first byte is read (game 20, a1 4, g1 4, p2 8, h1 4, i1
; 6, i2 6), nothing appears.
BuildDate0245:
  INCBIN "res/text/BuildDate0245.bin",$0000,20

; The sprite table: 132 entries of two words, drawer and graphics, indexed by
; sprite number
;
; The sprite drawer $A826 takes A = sprite number, reads the entry at $B2D6 +
; 4A and jumps to the drawer (JP (IX)) with HL = graphics, H = x, L = y. The
; drawers and their formats: see the graphics A module. An entry with drawer 0
; is empty. 472 of the 528 bytes are read (the empty entries and the
; never-drawn $5C-$5F are not).
SpriteTable:
  DEFW DrawSprite40x23,Buggy ; $00: the buggy (Buggy $E140)
  DEFW DrawSprite24x8Attr,UfoA  ; $01-$04: UFO A, 4 frames (UfoA $E020)
  DEFW DrawSprite24x8Attr,$E080
  DEFW DrawSprite24x8Attr,$E0E0
  DEFW DrawSprite24x8Attr,$E080
  DEFW DrawSprite24x8Attr,UfoB  ; $05-$0A: UFO B, 6 frames (UfoB $DEA0)
  DEFW DrawSprite24x8Attr,$DF00
  DEFW DrawSprite24x8Attr,$DF60
  DEFW DrawSprite24x8Attr,$DFC0
  DEFW DrawSprite24x8Attr,$DF60
  DEFW DrawSprite24x8Attr,$DF00
  DEFW DrawSprite24x16Attr,Spinner ; $0B-$0E: the spinner, 4 frames (Spinner
  DEFW DrawSprite24x16Attr,$DC60   ; $DBA0)
  DEFW DrawSprite24x16Attr,$DD20
  DEFW DrawSprite24x16Attr,$DDE0
  DEFW DrawSprite24x12,Rock ; $0F: the rock (Rock $DB10)
  DEFW DrawSprite24x16,BombCrater ; $10: the bomb crater (BombCrater $DA50)
  DEFW DrawSprite16x4,Mine  ; $11-$12: the mine's two blink frames (Mine $D9D0)
  DEFW DrawSprite16x4,$DA10
  DEFW DrawSprite40x23,Tank ; $13: the tank (Tank $D7D0)
  DEFW DrawSprite24x8,LowFlyer ; $14: the low flyer (LowFlyer $D710)
  DEFW $0000,$0000        ; $15-$1C: eight empty entries
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW $0000,$0000
  DEFW DrawSprite16x4,UfoBomb ; $1D-$1E: the UFO bombs (UfoBomb $D690)
  DEFW DrawSprite16x4,$D6D0
  DEFW DrawSprite40x23,BuggyExplosion ; $1F-$26: the buggy's explosion, 8
  DEFW DrawSprite40x23,$6700          ; frames (BuggyExplosion $6500)
  DEFW DrawSprite40x23,$6900
  DEFW DrawSprite40x23,$6B00
  DEFW DrawSprite40x23,$6D00
  DEFW DrawSprite40x23,$6F00
  DEFW DrawSprite40x23,$7100
  DEFW DrawSprite40x23,$7300
  DEFW DrawSprite24x8Attr,BurstSmall ; $27-$2A: a UFO's small burst (BurstSmall
  DEFW DrawSprite24x8Attr,$7DE0      ; $7D80)
  DEFW DrawSprite24x8Attr,$7E40
  DEFW DrawSprite24x8Attr,$7EA0
  DEFW DrawSprite24x12,Debris ; $2B-$2E: a shot rock's debris (Debris $7900)
  DEFW DrawSprite24x12,$7990
  DEFW DrawSprite24x12,$7A20
  DEFW DrawSprite24x12,$7AB0
  DEFW DrawSprite24x16Attr,BurstLarge ; $2F-$32: a shot UFO's large burst,
  DEFW DrawSprite24x16Attr,$76C0      ; coloured (BurstLarge $7600)
  DEFW DrawSprite24x16Attr,$7780
  DEFW DrawSprite24x16Attr,$7840
  DEFW DrawSprite40x23,BuggyExplosion ; $33-$36: the tank's explosion:
  DEFW DrawSprite40x23,$6700          ; BuggyExplosion's first 4 frames
  DEFW DrawSprite40x23,$6900
  DEFW DrawSprite40x23,$6B00
  DEFW DrawSprite24x8Attr,BurstSmall ; $37-$3A: the low flyer's burst
  DEFW DrawSprite24x8Attr,$7DE0      ; (BurstSmall $7D80)
  DEFW DrawSprite24x8Attr,$7E40
  DEFW DrawSprite24x8Attr,$7EA0
  DEFW DrawShotForward,$0000 ; $3B: drawer $ADF7 with graphics 0
  DEFW DrawSprite16x9,$6350       ; $3C-$3E: the three wreck pieces
  DEFW DrawSprite16x9,BuggyWreck2 ; (BuggyWreck1-3)
  DEFW DrawSprite16x9,BuggyWreck3
  DEFW $0000,$0000        ; $3F: empty
  DEFW DrawSprite16x8,BoulderSmall ; $40-$43: the small boulder, 4 frames
  DEFW DrawSprite16x8,$D5D0        ; (BoulderSmall $D590)
  DEFW DrawSprite16x8,$D610
  DEFW DrawSprite16x8,$D650
  DEFW DrawSprite24x12,BoulderMedium ; $44-$4B: the medium boulder, 4 frames
  DEFW DrawSprite24x12,BoulderMedium ; each twice (BoulderMedium $D350)
  DEFW DrawSprite24x12,$D3E0
  DEFW DrawSprite24x12,$D3E0
  DEFW DrawSprite24x12,$D470
  DEFW DrawSprite24x12,$D470
  DEFW DrawSprite24x12,$D500
  DEFW DrawSprite24x12,$D500
  DEFW DrawSprite24x16,BoulderLarge ; $4C-$57: the big boulder, 4 frames each
  DEFW DrawSprite24x16,BoulderLarge ; three times (BoulderLarge $D050)
  DEFW DrawSprite24x16,BoulderLarge
  DEFW DrawSprite24x16,$D110
  DEFW DrawSprite24x16,$D110
  DEFW DrawSprite24x16,$D110
  DEFW DrawSprite24x16,$D1D0
  DEFW DrawSprite24x16,$D1D0
  DEFW DrawSprite24x16,$D1D0
  DEFW DrawSprite24x16,$D290
  DEFW DrawSprite24x16,$D290
  DEFW DrawSprite24x16,$D290
  DEFW DrawSprite24x12,BurstMedium ; $58-$5B: the medium boulder's burst
  DEFW DrawSprite24x12,$7BD0       ; (BurstMedium $7B40)
  DEFW DrawSprite24x12,$7C60
  DEFW DrawSprite24x12,$7CF0
  DEFW DrawSprite24x12,Debris ; $5C-$5F: Debris $7900 again, no user found
  DEFW DrawSprite24x12,$7990
  DEFW DrawSprite24x12,$7A20
  DEFW DrawSprite24x12,$7AB0
  DEFW DrawSprite24x16,BurstLarge ; $60-$63: the big boulder's burst,
  DEFW DrawSprite24x16,$76C0      ; uncoloured (BurstLarge $7600)
  DEFW DrawSprite24x16,$7780
  DEFW DrawSprite24x16,$7840
  DEFW DrawSprite32x16,PlantFrames ; $64-$72: the plant opening and closing, 15
  DEFW DrawSprite32x16,$C550       ; entries (PlantFrames $C450)
  DEFW DrawSprite32x16,$C650
  DEFW DrawSprite32x16,$C750
  DEFW DrawSprite32x16,$C850
  DEFW DrawSprite32x16,$C950
  DEFW DrawSprite32x16,$CA50
  DEFW DrawSprite32x16,$CB50
  DEFW DrawSprite32x16,$CA50
  DEFW DrawSprite32x16,$C950
  DEFW DrawSprite32x16,$C850
  DEFW DrawSprite32x16,$C750
  DEFW DrawSprite32x16,$C650
  DEFW DrawSprite32x16,$C550
  DEFW DrawSprite32x16,PlantFrames
  DEFW DrawSprite32x16,PlantScore ; $73: the 500 sign (PlantScore $7500)
  DEFW DrawSprite32x16,PlantSpray ; $74-$7A: the plant's spray, 7 entries
  DEFW DrawSprite32x16,$CD50      ; (PlantSpray $CC50)
  DEFW DrawSprite32x16,$CE50
  DEFW DrawSprite32x16,$CF50
  DEFW DrawSprite32x16,$CE50
  DEFW DrawSprite32x16,$CD50
  DEFW DrawSprite32x16,PlantSpray
  DEFW DrawSprite24x12,Debris ; $7B-$7E: a shot plant's debris (Debris $7900)
  DEFW DrawSprite24x12,$7990
  DEFW DrawSprite24x12,$7A20
  DEFW DrawSprite24x12,$7AB0
  DEFW $0000,$0000        ; $7F: empty
  DEFW DrawSprite16x8,BurstTiny ; $80-$83: the small boulder's burst (BurstTiny
  DEFW DrawSprite16x8,$C390     ; $C350)
  DEFW DrawSprite16x8,$C3D0
  DEFW DrawSprite16x8,$C410

; The tune played through the game: 384 words, one note every 3 interrupts,
; $FFFF ends it
;
; The interrupt routine (from $7F47) counts TuneDivider $B240 down from 3; at 0
; it takes the word at TunePointer $B23E. $0000 is a rest; another word is the
; period HL for the ROM BEEPER, with the duration DE chosen so a note lasts
; about 12 ms. $FFFF sends the pointer back to $B4E6 ($7F70). PlayerFlags bit 7
; silences it. All 770 bytes (with the end word) are read in the runs.
Tune:
  INCBIN "res/tune/Tune.bin",$0000,768
TuneEnd:
  INCBIN "res/tune/Tune.bin",$0300,2
