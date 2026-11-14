; --------------------------------------------------------------------------------------------------------------------
; text.asm: The texts
;
; The game's own character codes: `$FF` a new line, `$FE` the end of a text (`$AAE9`; GAME OVER's `$AA8D` stops at
; `$FF`). Digits are `$37` + the digit ('8' = 1, '9' = 2, '?' = 8, '@' = 9), '^' is a comma, '_' a full stop, '`' a
; question mark, 'C' before the year is a plain C (glyph 12); the font has no copyright sign.
;
; The five intro and closing texts are printed by NewGame $E2DC and the level change `$AC1A`; the three menu texts by
; Menu $E219.
; --------------------------------------------------------------------------------------------------------------------

  ORG $E4E5

; Level 1 intro: South America, the Goolu tribe
SouthAmericaText:
  INCBIN "res/texts/SouthAmericaText.bin",$0000,279

; Level 2 intro: Egypt, the jewel of Ankhel
EgyptText:
  INCBIN "res/texts/EgyptText.bin",$0000,270

; Level 3 intro: Europe, Schwarzendumpf castle
CastleText:
  INCBIN "res/texts/CastleText.bin",$0000,260

; Level 4 intro: Europe, the secret missile base
MissileBaseText:
  INCBIN "res/texts/MissileBaseText.bin",$0000,235

; The ending: London, the Barfian empire
LondonText:
  INCBIN "res/texts/LondonText.bin",$0000,258

; " R I C K    D A N G E R O U S "
TitleText:
  INCBIN "res/texts/TitleText.bin",$0000,32

; 1 KEYBOARD, 2 KEMPSTON, 3 CURSOR, 4 SINCLAIR
ControlsText:
  INCBIN "res/texts/ControlsText.bin",$0000,54

; PRESS FIRE TO START and the two copyright lines
CreditsText:
  INCBIN "res/texts/CreditsText.bin",$0000,61
