; Myth: History in the Making, System 3 Software 1989: stage 5 (TZX block 52), 33 792 bytes loaded at $6C3F by the
; resident stage loader over $6C3F-$F03E (tools/image.py).
; Written by kit/mkgame.py from src/stage5/stage5.ann and the recordings; edit stage5.ann, not the .asm.

  DEVICE ZXSPECTRUM48

; The variables past the loaded image (stage1.ann @equ)
Screen         EQU $4000  ; the screen's pixels
EnergyBarScreen EQU $4134  ; the HUD's energy bar: screen row 1, pixel line 1, column 20
Attributes     EQU $5800  ; the screen's attributes
PlayBuffer     EQU $5B00  ; the play buffer $5B00-$6CFF (its tail $6C3F-$6CFF is in the block): 18 character rows of 8 lines of 32 bytes, linear
TextGlyphRows  EQU $6A00  ; DrawTextLine's 7 (row, 0) pairs, inside the play buffer past the text pages
DigitGlyphs    EQU $F959  ; resident font from '0': 8 bytes a character, 7 rows drawn (RenderDigits)
PlaySoundVector EQU $F9B0  ; resident: JP to the AY effect starter (E = the effect number)
DecimalTable   EQU $F9BF  ; resident: the words 10000, 1000, 100, 10, 1
Score          EQU $F9FB  ; resident: the score's low four decimal digits, 0-9999 (AddScore)
ScoreHigh      EQU $F9FD  ; resident: the score's high two digits (ten thousands), 0-99 (AddScore)
BitReverse     EQU $FA00  ; resident: each byte with its bits reversed (the sprites drawn facing left)
ScreenLineTable EQU $FB00  ; resident: the screen address of each of the 192 pixel lines (words)
KeyUp          EQU $FC90  ; resident key reader: Z when UP is held (DEFINE KEYS / joystick patch its port and bit)
KeyDown        EQU $FC9F  ; resident key reader: Z when DOWN is held
KeyLeft        EQU $FCAE  ; resident key reader: Z when LEFT is held
KeyRight       EQU $FCBD  ; resident key reader: Z when RIGHT is held
KeyFire        EQU $FCCC  ; resident key reader: Z when FIRE is held
KeyHook        EQU $FCDB  ; resident: called before every key read (a RET, or the joystick / pause check DEFINE KEYS installs)
RandomSeed     EQU $FE08  ; NextSeed $9483: seed = seed x 5 + $15; $07CF at the stage start
RandomPointer  EQU $FE0A  ; Random $9492: a pointer into the ROM whose bytes are the random numbers; reseeded from R at the stage start, $0D7A at the burst
DrawSavedSP    EQU $FE0C  ; the real SP while Dameron's drawers walk SP over the line table
SavedSP        EQU $FE0E  ; the real SP while ClearBuffer, DrawHero and DrawHeroFrame walk SP over their tables
ShotCursor     EQU $FE2D  ; FindShotSlot's round robin 0-15 over the hero's shots (stage 1's MissileCursor $FE27)
ItemsChanged   EQU $FE2F  ; stage 1's $FE4A: 1 after AddItem; only RedrawItemsIfChanged (no caller) reads it
LineCount      EQU $FE30  ; the line counter of Dameron's drawers; 2 from InitStageState
InitOnly32     EQU $FE32  ; set to 1 by InitStageState, read by nothing (stage 1's InitOnly12)
ItemSelected   EQU $FE35  ; stage 1's $FE17: the slot of CarriedItems the HUD shows (6, then 3 from StageSetUp)
ItemLast       EQU $FE36  ; stage 1's $FE18: the last used slot of CarriedItems (6)
ItemFirst      EQU $FE37  ; stage 1's $FE19: the first slot of CarriedItems (6)
MissileCursor  EQU $FE38  ; AddMissileFrom's round robin over stage 1's missile records (kept, no caller)
FireLatch      EQU $FE3A  ; stage 1's $FE50: 1 armed (FIRE up), 0 after a press; the hero fires on the release
WorkByte       EQU $FE3B  ; scratch: StartBurst's shape bits (stage 1's WorkByte $FE14)
DameronArrived EQU $FE3D  ; 1 once Dameron's approach reached line $14: his path and his missiles start
DameronX       EQU $FE3E  ; Dameron's X offset in pixels (0, never changed)
DameronY       EQU $FE3F  ; Dameron's top line from line 48 ($8E at the start, $14 after the approach, then his path)
DameronPathIndex EQU $FE40  ; the step in DameronPath ($FF at the start)
PendingHits    EQU $FE41  ; 2 after a shot meets Dameron's mouth; DuelHit takes one a pass
FormChanged    EQU $FE42  ; 1 after a form change: the drawers clear the old picture
DuelPhase      EQU $FE43  ; $FF the intro, 0-3 Dameron's four forms, 4 won (the ending)
HitCounter     EQU $FE44  ; the hits on the current form, 0-19 (20 change the form)
DuelTimer      EQU $FE45  ; the texts' timer: $044C at the start, - 2 a pass; $FFC3 from the duel's start and again after the win
TextShown      EQU $FE47  ; 1 while the intro or the ending is on the screen (its rows flash)
BurstSmall     EQU $FE48  ; stage 1's $FE3E: 1 a small burst (14 steps, doubled moves), 0 a big one
BurstTimer     EQU $FE49  ; stage 1's $FE3D: the burst's step; $65 idle in stage 5, $FF just started, $64 StopBurst
TextPenShift   EQU $FE4A  ; DrawTextLine's pixel offset; also UpdateBurst's old particle column for EraseParticle
TextScratch    EQU $FE4B  ; a text line's third header byte (unused); also UpdateBurst's old particle row
GlyphWidthMask EQU $FE4C  ; the current glyph's width mask (DrawTextGlyph)
PassCounter    EQU $FE4D  ; stage 1's $FE31: + 1 every pass, the animations' clock
InitOnly4E     EQU $FE4E  ; set to $10 by InitStageState, read by nothing (stage 1's InitOnly3A)
Energy         EQU $FE4F  ; stage 1's $FE3F: the hero's energy, 0 to $2E (full)
InitOnly50     EQU $FE50  ; set to $0D by InitStageState, read by nothing (stage 1's InitOnly40)
InitOnly51     EQU $FE51  ; set to 1 by InitStageState, read by nothing (stage 1's InitOnly41)
EnergyShown    EQU $FE52  ; stage 1's $FE4D: the energy the HUD bar last drew
EnergyChange   EQU $FE53  ; stage 1's $FE4E: the pending energy change ($80 and up drains, under $80 refills 2 a pass)
LivesFlash     EQU $FE55  ; stage 1's $FE59: the lives boxes' flash step, 0-$10 ($10 idle)
GameOverTimer  EQU $FE56  ; stage 1's $FE5B: never set in stage 5 (only GameOverStep and InitStageState's clear write it)
Lives          EQU $FE58  ; stage 1's $FE61: lives left, from H at StageEntry
  ORG $6C3F
  INCLUDE "variables.asm"  ; The stage's work space: the play buffer's tail, the shadow attributes, the HUD picture and the records over it
  INCLUDE "entry.asm"  ; The stage's entry and set-up
  INCLUDE "mainloop.asm"  ; The main loop and its pass
  INCLUDE "render.asm"  ; Drawing: the fades, the screen copies, the play area's colours
  INCLUDE "duel.asm"  ; The duel with Dameron: the texts' timer, his four forms, his path, his missiles, the hits
  INCLUDE "hud.asm"  ; The energy, the lives, the score, the HUD and game over
  INCLUDE "hero.asm"  ; The hero: its movement, its shots, its explosion, and the item strip kept from stage 1
  INCLUDE "missiles.asm"  ; Dameron's missiles: 8 records of 6 bytes at $7000
  INCLUDE "util.asm"  ; Small helpers
  INCLUDE "stars.asm"  ; The stars streaming right to left behind the duel
  INCLUDE "texts.asm"  ; The intro and ending texts: their font, the drawing into buffers and the copy to the screen
  INCLUDE "graphics.asm"  ; The stage's pictures: GAME OVER, the stars, Dameron's head in its forms, the sprite bank, the item icons, the hero

  SAVEBIN "stage5.bin",$6C3F,$8400
