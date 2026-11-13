; --------------------------------------------------------------------------------------------------------------------
; vars.asm: Rick's state
;
; Rick's movement and action flags. The zone setup at $AD29 clears $FD54-$FD6C (25 bytes) and then restores the
;
; crawl flag from $AD20.
; --------------------------------------------------------------------------------------------------------------------

; Rick's state, cleared by $AD29 (25 bytes)
;
; Flags are 0 or `$FF` unless said. `$FD54`, `$FD5D` and `$FD6B` are never
; used.
RickVars:
  DEFB $00
YFraction:
  DEFB $00                ; Rick's Y fraction (8.8 with YVelocity)
YVelocity:
  DEFB $00                ; Rick's Y velocity, 8.8 signed (2 bytes): +$80 per
  DEFB $00                ; frame, at most $0800; $FA80 a jump
Facing:
  DEFB $00                ; 1 left, 0 right (the sprite mirror)
Climbing:
  DEFB $00
Crawling:
  DEFB $00
Airborne:
  DEFB $00
AnimStep:
  DEFB $00                ; the step counter of ChooseRickFrame; $FF standing
  DEFB $00                ; not used
FireLatch:
  DEFB $00                ; set while fire with up is held: one shot per press
PrevCrawl:
  DEFB $00                ; Crawling of the frame before
PokeLatch:
  DEFB $00                ; one stick sound per press
ZoneChange:
  DEFB $00                ; set by ExitLeft / ExitRight, read at $E3FD
ExitSide:
  DEFB $00                ; 0 left, 1 right (read at $ABA6)
Poking:
  DEFB $00                ; the stick is out; the objects read PokeX / PokeY
                          ; ($EF57, $F019, $F273)
PokeX:
  DEFB $00
PokeY:
  DEFB $00                ; 16-bit
  DEFB $00
FireHeld:
  DEFB $00                ; fire with up held: the firing frame
Dying:
  DEFB $00
DeathDone:
  DEFB $00                ; Rick fell off the bottom: read at $E3EB
DeathDrift:
  DEFB $00                ; X step of the dying Rick: 3 or -3
  DEFB $00                ; not used
BonusActive:
  DEFB $00                ; set by BonusTrigger, the countdown at $E466

; Rick's walk frames by AnimStep / 2
;
; Read by ChooseRickFrame `$FC60` (FrameWalkTable `$FD47`).
WalkFrames:
  DEFW SpriteFrames,RickWalk1,RickWalk2,RickWalk1
CrawlFrames:
  DEFW RickCrawl0,RickCrawl0,RickCrawl1,RickCrawl1 ; the crawl frames by
                                                   ; AnimStep / 2
                                                   ; (FrameNotPoking $FC9F)
