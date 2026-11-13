; --------------------------------------------------------------------------------------------------------------------
; sprites.asm: The 54 sprite frames: 24 x 21 pixels, a mask and pixels, 126 bytes each
;
; Frame F (0-53) is at `$8401` + 126F. An object's slot holds the frame's address (+4/+5): from its kind's graphic
; (ObjectKinds +2/+3, kinds 4-21), from its animation list (`$EE0B`: a frame byte B gives `$8383` + 126B, so B = F +
; 1, bit 7 the mirror), or from the code (Rick's frames, ChooseRickFrame `$FC60`; the dynamite's FuseFrames `$ECF2`
; and BlastFrames `$ECF6`). A falling enemy shows its graphic + 126 (`$F099`, `$F3ED`): the next frame.
;
; DrawSprite `$A419` sets SP to the frame and POPs HL, BC and DE for each of the 21 rows: the row's 6 bytes are OR3,
; OR2, OR1, AND1, AND3, AND2 for the columns 1-3 left to right (screen byte AND mask OR pixels); the mirrored draw
; (slot +6 bit 0) swaps columns 1 and 3 and reverses each byte through the table at `$5B00`. The editable form is
; src/res/sprites/frames.png (tools/res_gfx.py; src/res/sprites/README.md).
;
; Frames 20-22, 25, 26, 30 and 31 are named by no kind, animation list or instruction: known only as pictures.
; --------------------------------------------------------------------------------------------------------------------

  ORG $8401

; 54 frames x 21 rows x 6 bytes (OR3, OR2, OR1, AND1, AND3, AND2)
SpriteFrames:
RickWalk0:
  INCBIN "res/sprites/frames.bin",$0000,126
RickWalk1:
  INCBIN "res/sprites/frames.bin",$007E,126
RickWalk2:
  INCBIN "res/sprites/frames.bin",$00FC,126
RickDying:
  INCBIN "res/sprites/frames.bin",$017A,126
Frame4:
  INCBIN "res/sprites/frames.bin",$01F8,126
RickCrawl1:
  INCBIN "res/sprites/frames.bin",$0276,126
RickCrawl0:
  INCBIN "res/sprites/frames.bin",$02F4,126
RickFiring:
  INCBIN "res/sprites/frames.bin",$0372,126
RickPoking:
  INCBIN "res/sprites/frames.bin",$03F0,126
RickClimbing:
  INCBIN "res/sprites/frames.bin",$046E,126
DynamiteFuse:
  INCBIN "res/sprites/frames.bin",$04EC,126
BulletsPickup:
  INCBIN "res/sprites/frames.bin",$056A,126
Blast0:
  INCBIN "res/sprites/frames.bin",$05E8,126
Blast1:
  INCBIN "res/sprites/frames.bin",$0666,126
Blast2:
  INCBIN "res/sprites/frames.bin",$06E4,126
Frame15:
  INCBIN "res/sprites/frames.bin",$0762,126
Frame16:
  INCBIN "res/sprites/frames.bin",$07E0,126
Frame17:
  INCBIN "res/sprites/frames.bin",$085E,126
Frame18:
  INCBIN "res/sprites/frames.bin",$08DC,126
Frame19:
  INCBIN "res/sprites/frames.bin",$095A,126
Frame20:
  INCBIN "res/sprites/frames.bin",$09D8,126
Frame21:
  INCBIN "res/sprites/frames.bin",$0A56,126
Frame22:
  INCBIN "res/sprites/frames.bin",$0AD4,126
Frame23:
  INCBIN "res/sprites/frames.bin",$0B52,126
Frame24:
  INCBIN "res/sprites/frames.bin",$0BD0,126
Frame25:
  INCBIN "res/sprites/frames.bin",$0C4E,126
Frame26:
  INCBIN "res/sprites/frames.bin",$0CCC,126
Frame27:
  INCBIN "res/sprites/frames.bin",$0D4A,126
Frame28:
  INCBIN "res/sprites/frames.bin",$0DC8,126
Frame29:
  INCBIN "res/sprites/frames.bin",$0E46,126
Frame30:
  INCBIN "res/sprites/frames.bin",$0EC4,126
Frame31:
  INCBIN "res/sprites/frames.bin",$0F42,126
Frame32:
  INCBIN "res/sprites/frames.bin",$0FC0,126
Frame33:
  INCBIN "res/sprites/frames.bin",$103E,126
Frame34:
  INCBIN "res/sprites/frames.bin",$10BC,126
Frame35:
  INCBIN "res/sprites/frames.bin",$113A,126
Frame36:
  INCBIN "res/sprites/frames.bin",$11B8,126
Frame37:
  INCBIN "res/sprites/frames.bin",$1236,126
Frame38:
  INCBIN "res/sprites/frames.bin",$12B4,126
Frame39:
  INCBIN "res/sprites/frames.bin",$1332,126
Frame40:
  INCBIN "res/sprites/frames.bin",$13B0,126
Frame41:
  INCBIN "res/sprites/frames.bin",$142E,126
Frame42:
  INCBIN "res/sprites/frames.bin",$14AC,126
Frame43:
  INCBIN "res/sprites/frames.bin",$152A,126
Frame44:
  INCBIN "res/sprites/frames.bin",$15A8,126
Frame45:
  INCBIN "res/sprites/frames.bin",$1626,126
Frame46:
  INCBIN "res/sprites/frames.bin",$16A4,126
Frame47:
  INCBIN "res/sprites/frames.bin",$1722,126
Frame48:
  INCBIN "res/sprites/frames.bin",$17A0,126
Frame49:
  INCBIN "res/sprites/frames.bin",$181E,126
Frame50:
  INCBIN "res/sprites/frames.bin",$189C,126
Frame51:
  INCBIN "res/sprites/frames.bin",$191A,126
Frame52:
  INCBIN "res/sprites/frames.bin",$1998,126
Frame53:
  INCBIN "res/sprites/frames.bin",$1A16,126
