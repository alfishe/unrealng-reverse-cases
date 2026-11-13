; --------------------------------------------------------------------------------------------------------------------
; graphics.asm: The stage's pictures: GAME OVER, the stars, Dameron's head in its forms, the sprite bank, the item icons, the hero
;
; Stage 5's data runs from GameOverPicture $A367 to $BE7B; the rest of the block ($BE7C-$F03E) is zeros but for one
; byte. Everything is plain 1-bit bitmaps, rows top first, bit 7 the left pixel, no mask, copied (not ORed) straight
; to the screen through the screen-line tables. Each file of src/res/stage5/ is one entry (bitmaps-NAME-WxH: frames of
; W bytes x H lines one after another). s5-right reads the stars, Dameron's form-0 face, dome and back, the sprite
; bank's frames 0-3 ($B3BA-$B479, the fireballs), two item icons, the energy-bar pattern and the hero's frames; rzx-r5
; and ending (the duel won) also read face 1, face 2, dome 3, the curved shot's frames, the bolts and the bursts. Read
; in no recording: GameOverPicture, SpriteBankSpare, BitMasks, ItemIconSpare, UnusedWordTable and the zero runs.
; --------------------------------------------------------------------------------------------------------------------

  ORG $A367

; GAME OVER: 8 bytes x 8 lines (the last line blank)
;
; GameOverStep $7E9D copies it to column 12, line $1C of the item strip
; (CopyToScreen $7979, BC = $0C1C, DE = $0808) when GameOverTimer reaches $31.
; Nothing in stage 5 sets GameOverTimer, so it is never shown: not read in
; s5-right; known only from the code ($7EBD).
GameOverPicture:
  INCBIN "res/stage5/bitmaps-game-over-8x8.bin",$0000,64

; 89 zero bytes no code reads (no operand names $A3A7-$A3FF; no recording reads
; any)
UnusedA3A7:
  DEFS $59

; The slow star: two frames of 3 bytes x 3 lines ($A400, $A409)
;
; DrawStar $869C draws a slow star (+2 = 0) with the frame at $A400 when its X
; AND 7 is 0, else StarSlow1 $A409 (the star is 4 pixels on, half a byte). Read
; in s5-right (21103 + 10077 runs of the copy).
StarSlow:
  INCBIN "res/stage5/bitmaps-star-slow-3x3.bin",$0000,9
StarSlow1:
  INCBIN "res/stage5/bitmaps-star-slow-3x3.bin",$0009,9

; The fast star: two frames of 4 bytes x 5 lines ($A412, $A426)
;
; DrawStar $869C draws a fast star (+2 = 1) with $A412 on even passes and
; StarFast1 $A426 on odd ones (PassCounter bit 0): a twinkle. Read in s5-right.
StarFast:
  INCBIN "res/stage5/bitmaps-star-fast-4x5.bin",$0000,20
StarFast1:
  INCBIN "res/stage5/bitmaps-star-fast-4x5.bin",$0014,20

; Dameron's face, form 0: 7 bytes x 128 lines
;
; DrawDameronFace $8859 copies it (phase 0) at column (DameronX + $78) / 8,
; from line 48 + DameronY, with SP walking the line table; 128 lines, or $36
; while DameronY >= $5A. Read in s5-right (3259 passes).
DameronFace0:
  INCBIN "res/stage5/bitmaps-dameron-face0-7x128.bin",$0000,896

; The middle of Dameron's head, forms 0-2: 4 bytes x 128 lines
;
; DrawDameronDome $894D, at column (DameronX + $B0) / 8. Read in s5-right.
DameronDome:
  INCBIN "res/stage5/bitmaps-dameron-dome-4x128.bin",$0000,512

; The back of Dameron's head (the hair), every form: 4 bytes x 128 lines
;
; DrawDameronBack $899C, at column (DameronX + $D0) / 8. Read in s5-right.
DameronBack:
  INCBIN "res/stage5/bitmaps-dameron-back-4x128.bin",$0000,512

; Dameron's face, form 1: 7 bytes x 128 lines
;
; DrawDameronFace $8859 in phase 1 (after the first 20 counted hits). Read in
; rzx-r5 and ending (896 bytes); s5-right counted no hit.
DameronFace1:
  INCBIN "res/stage5/bitmaps-dameron-face1-7x128.bin",$0000,896

; Dameron's face, form 2: 5 bytes x 128 lines (the skull)
;
; DrawDameronFace $8859 in phase 2, two columns further right. Read in rzx-r5
; and ending (640 bytes).
DameronFace2:
  INCBIN "res/stage5/bitmaps-dameron-face2-5x128.bin",$0000,640

; The middle of Dameron's head, form 3 (no face): 4 bytes x 128 lines
;
; DrawDameronDome $894D in phase 3. Read in rzx-r5 and ending (512 bytes).
DameronDome3:
  INCBIN "res/stage5/bitmaps-dameron-dome3-4x128.bin",$0000,512

; The sprite bank, frames 0-7: 3 bytes x 16 lines (fireballs 0-3, the curved
; shot 4-7)
;
; The bank holds 24 frames 3 bytes wide, found through SpriteFrameOffsets
; $938E: SpriteFrameAddress $9378 gives DE = $B3BA + SpriteFrameOffsets[A].
; Frames 0-3 are Dameron's fireball (FireballMissile, PassCounter AND 3), 4-7
; the curved shot's (MoveCurvedShot $9DC6 through CurvedShotFrames $9E94).
; s5-right read frames 0-3 only ($B3BA-$B479); rzx-r5 and ending read all
; eight.
SpriteBank:
  INCBIN "res/stage5/bitmaps-bank-3x16.bin",$0000,384

; The sprite bank, frames 8-11: 3 bytes x 9 lines, the bolt
;
; BoltMissile $834E (kind 3, forms 1 and 2). Read in rzx-r5 and ending (all 108
; bytes).
SpriteBankBolts:
  INCBIN "res/stage5/bitmaps-bank-3x9.bin",$0000,108

; The sprite bank, frames 12-23: 3 bytes x 24 lines, the hero's explosion and
; the bursts (13 blocks of 72 bytes)
;
; Frames 12-18 are the hero's explosion and re-forming (DrawHeroFrame $9D85:
; frame +5 + 12), $13-$17 the bursts round Dameron at a form change (kind 4).
; Frame 14's offset ($27C) is followed by 144 bytes to frame 15 ($30C): the 72
; bytes at SpriteBankSpare $B67E (SpriteBank $B3BA + $2C4) are a frame no
; offset names, read by no code. rzx-r5 read 360 bytes of the frames, ending
; 792; the spare frame was read in no recording.
SpriteBankBursts:
  INCBIN "res/stage5/bitmaps-bank-3x24.bin",$0000,72
SpriteBank13:
  INCBIN "res/stage5/bitmaps-bank-3x24.bin",$0048,72
SpriteBank14:
  INCBIN "res/stage5/bitmaps-bank-3x24.bin",$0090,72
SpriteBankSpare:
  INCBIN "res/stage5/bitmaps-bank-3x24.bin",$00D8,72
SpriteBank15:
  INCBIN "res/stage5/bitmaps-bank-3x24.bin",$0120,648

; 2 zero bytes no code reads
UnusedB94E:
  DEFS $02

; One bit a byte, bit 7 to bit 0 ($80, $40 ... $01): no reader
;
; No operand of stage 5's code names $B950-$B957 and no word in the code area
; points there (checked over $7800-$A366); no recording (s5-right, rzx-r5,
; ending) reads any of it. Known only from the bytes.
BitMasks:
  DEFB $80,$40,$20,$10,$08,$04,$02,$01

; The item icons: 8 icons of 2 bytes x 16 lines (32 bytes each)
;
; DrawItemIcon $7DD0 copies the icon ItemIcons $7E8B names for the kind (kind 2
; and 7 $B958, 6 ItemIcon6 $B978, 5 ItemIcon5 $B998, 3 ItemIcon3 $B9B8, 8
; ItemIcon8 $B9D8, 1 ItemIcon1 $B9F8, 0 ItemIcon0 $BA38; kind 4 is the blank
; BlankIcon $94B0). The icon at ItemIconSpare $BA18 has no kind: no word names
; it. s5-right reads ItemIcon8 $B9D8 (kind 8, the item the hero starts with)
; and ItemIcon0 $BA38.
ItemIcons16:
  INCBIN "res/stage5/bitmaps-item-icons-2x16.bin",$0000,32
ItemIcon6:
  INCBIN "res/stage5/bitmaps-item-icons-2x16.bin",$0020,32
ItemIcon5:
  INCBIN "res/stage5/bitmaps-item-icons-2x16.bin",$0040,32
ItemIcon3:
  INCBIN "res/stage5/bitmaps-item-icons-2x16.bin",$0060,32
ItemIcon8:
  INCBIN "res/stage5/bitmaps-item-icons-2x16.bin",$0080,32
ItemIcon1:
  INCBIN "res/stage5/bitmaps-item-icons-2x16.bin",$00A0,32
ItemIconSpare:
  INCBIN "res/stage5/bitmaps-item-icons-2x16.bin",$00C0,32
ItemIcon0:
  INCBIN "res/stage5/bitmaps-item-icons-2x16.bin",$00E0,32

; 32 zero bytes no code reads
UnusedBA58:
  DEFS $20

; The energy bar's pattern: 6 bytes, the same on each of the bar's 6 lines
;
; DrawEnergyBar $9744 copies its whole bytes and a last partial byte (BarMasks
; $979D) to the HUD at EnergyBarScreen $4134, six lines, by the energy. Read in
; s5-right (138 lines drawn).
EnergyBarPattern:
  INCBIN "res/stage5/bitmaps-energy-bar-6x1.bin",$0000,6

  ORG $BAC6

; 43 words no code reads: 1, 1000 x 3, 900, 800, 700, 600 x 4, 500 x 2, 400,
; 300, 200, 100, 60 x 6, 1 x 17, then 0
;
; A falling table of numbers (a delay or speed schedule) that no stage-5 code
; uses: no operand names $BAC6-$BB1B and no word in the code area points there
; (checked over $7800-$A366); no recording (s5-right, rzx-r5, ending) reads any
; of it. Known only from the bytes.
UnusedWordTable:
  DEFW $0001,$03E8,$03E8,$03E8,$0384,$0320,$02BC,$0258
  DEFW $0258,$0258,$0258,$01F4,$01F4,$0190,$012C,$00C8
  DEFW $0064,$003C,$003C,$003C,$003C,$003C,$003C,$0001
  DEFW $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
  DEFW $0001,$0001,$0001,$0001,$0001,$0001,$0001,$0001
  DEFW $0001,$0001,$0001

; The hero: 12 frames of 3 bytes x 24 lines (3 animation steps x 4 shifts of 2
; pixels)
;
; DrawHero $8576 copies the frame HeroFrames $85D9 names (step (PassCounter AND
; 7) / 2, step 3 the same as step 1; the shift X AND 6) straight to the screen,
; no mask. Read in s5-right (1858 reads a byte at most).
HeroSprites:
  INCBIN "res/stage5/bitmaps-hero-3x24.bin",$0000,864

; 7742 zero bytes ($BE7C-$DCB9) no code reads
UnusedBE7C:
  DEFS $1E3E

; A lone $7F among the zeros: no code reads it (no operand or word names it)
StrayByte:
  DEFB $7F

; 4996 zero bytes to the block's end ($DCBB-$F03E) no code reads
UnusedDCBB:
  DEFS $1384
