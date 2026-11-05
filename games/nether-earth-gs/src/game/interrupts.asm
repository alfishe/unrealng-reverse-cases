; --------------------------------------------------------------------------------------------------------------------
; interrupts.asm: the frame interrupts of play, the radar, the shot sounds
;
; The IM 2 handlers: the vector $FDFD jumps to Handler ($FDFE), which Start, EnterPlay and the menus switch.
; PlayInterrupt runs once a frame in play: TurnFrames + 1 (the play loop's 10-frame turn), one of the two radar
; pictures (ShowRadar, by RadarPhase), and the sound effect's event (SoundEffect, by SoundFx: a GS id once).
; StartInterrupt is EI; RET, the handler while the world must stand still (the start-up, the construction menu,
; saving, the game's end). The menu's handler MenuInterrupt is in the start module. nether-
; earth/docs/02-architecture.md 2.4.
;
; The radar: two pictures of 16 lines x 16 bytes, RadarOwn $D800 (the terrain + the player's robots, shown in $4D,
; cyan on blue) and RadarEnemy $D900 (the terrain + the enemy's, $4E, yellow on blue), one pixel a map cell for the
; 128 columns from RadarColumn. Shown in turns every frame at rows 22-23, columns 6-21: the terrain stays, each side's
; robots blink at 25 Hz in their colour. BuildRadar makes both from the map; ToggleRadarDot (with RadarDotAddress)
; XORs one robot's 2 x 2 dot in or out. nether-earth/docs/06-rendering.md 6.7, nether-earth/docs/08-hud-and-text.md
; 8.7.
;
; The sound: SoundFx is set by the shot code (1 a shot fired, $FC a miss, $FA a hit, $C8 a robot destroyed) and
; counted on by the interrupt, as in Nether Earth, where each count was one frame of a beeper burst (nether-
; earth/docs/09-sound.md 9.5). Here SoundEffect sends one GS id when the count reaches 2 (a shot), $FD (a miss, and a
; hit two frames later) or $C9 (a robot destroyed), and zeroes SoundFx; the counting code ($D586-$D594) is Nether
; Earth's, unchanged. docs/09-sound.md 9.5.
;
; The interrupt runs with interrupts off (the CPU's acceptance) and turns them on only at its last EI. The radar costs
; 8134 T a frame, 11 % of all the time in play (measured in Nether Earth; ShowRadar is the same bytes here).
; --------------------------------------------------------------------------------------------------------------------

; the interrupt handler of play, one a frame
;
; Installed by EnterPlay ($A694) and when the construction menu ends ($CBA2).
; Keeps AF, BC, DE, HL (not IX, IY, the alternate set: the routines it calls do
; not use them). TurnFrames + 1 (TurnPace $AE1D waits for 10, then zeroes it);
; RadarPhase toggled, ShowRadar with RadarOwn / $4D on phase 0, RadarEnemy /
; $4E on phase 1; SoundFx not 0: counted on (to 0 at $80 or when it wraps) and
; passed to SoundEffect, which sends a GS id for three of its values and then
; zeroes it. Ends in StartInterrupt's EI; RET. 34645 entries in Nether Earth's
; deep recording, one a frame of play.
PlayInterrupt:
  PUSH AF                 ; keep the interrupted code's registers
  PUSH BC                 ; (BC)
  PUSH DE                 ; (DE)
  PUSH HL                 ; (HL)
  LD HL,TurnFrames        ; the frame counter: the play loop waits for 10
                          ; ($AE1D)
  INC (HL)                ; one more frame of this turn
  LD HL,RadarOwn          ; the player's radar picture, cyan
  LD C,$4D                ; its attribute: bright cyan on blue
  LD A,(RadarPhase)       ; the other picture each frame
  XOR $01                 ; toggle
  LD (RadarPhase),A       ; kept for the next frame
  JR Z,InterruptRadar     ; phase 0: the player's picture
  LD HL,RadarEnemy        ; the enemy's radar picture, yellow
  LD C,$4E                ; bright yellow on blue
InterruptRadar:
  CALL ShowRadar          ; show this frame's radar picture
  LD A,(SoundFx)          ; a sound effect running?
  OR A                    ; (0: silent)
  JR Z,InterruptExit      ; silent: on to the exit
  INC A                   ; one step on each frame: to 0 at $80 (Nether Earth:
                          ; the tone's end) or past $FF
  CP $80                  ; $80: Nether Earth's end of the falling tone
  JR NZ,InterruptSoundStore ; no: keep the count
  XOR A                   ; the count ends: SoundFx = 0
InterruptSoundStore:
  LD (SoundFx),A          ; SoundFx = the count, the effect's next step
  OR A                    ; NZ: SoundEffect looks at the value (the M / P flags
                          ; were Nether Earth's choice of noise or tone;
                          ; SoundEffect compares A instead)
  CALL NZ,SoundEffect     ; SoundEffect: a GS id for 2, $FD and $C9
InterruptExit:
  POP HL                  ; restore the registers, on into EI; RET
  POP DE                  ; (DE)
  POP BC                  ; (BC)
  POP AF                  ; (AF); on into StartInterrupt

; the interrupt handler while the start-up runs
;
; Also the end of PlayInterrupt. Installed alone by Start (FillVectorTable
; $A614), GameStop ($AF0A), SaveGame ($C28D), the end of MenuMusic ($C520) and
; OpenConstructionMenu ($C85E): no frame counting, no radar, so the world
; stands while it is in place.
StartInterrupt:
  EI                      ; interrupts on again (the CPU turned them off on
                          ; acceptance)
  RET                     ; back to the interrupted code

; Show radar picture HL (16 lines x 16 bytes) at (22,6) in attribute C
;
; The interrupt alternates the two pictures $D800 (terrain + the player's
; robots, attribute $4D) and $D900 (terrain + the enemy's robots, $4E) every
; frame, so the terrain stays and each side's robots blink in their colour. The
; attributes are rows 22 and 23, columns 6-21.
ShowRadar:
  PUSH BC                 ; keep the attribute C
  LD B,$10                ; 16 lines
  LD DE,$50C6             ; screen line 0 of character row 22, column 6
RadarLineLoop:
  PUSH BC                 ; keep the count
  PUSH DE                 ; and the line's screen address
  LD BC,$0010             ; 16 bytes: 128 map columns
  LDIR                    ; one picture line onto the screen
  POP DE                  ; the line's start
  EX DE,HL                ; HL = the screen address (DE = the picture's next
                          ; line)
  CALL NextScreenLine     ; the next screen line
  EX DE,HL                ; back: DE = screen, HL = picture
  POP BC                  ; the count back
  DJNZ RadarLineLoop      ; the next line
  POP BC                  ; the attribute back
  LD HL,$5AC6             ; the attributes of row 22
  CALL FillAttr16         ; 16 cells of row 22
  LD L,$E6                ; row 23 ($5AE6), then on into FillAttr16 for its 16
                          ; cells

; Write C into 16 bytes from HL
;
; In: HL, C. Out: HL past the 16 bytes, B = 0. The tail of ShowRadar (rows 22
; and 23 of the radar).
FillAttr16:
  LD B,$10                ; 16 cells
FillAttrLoop:
  LD (HL),C               ; the attribute
  INC HL                  ; the next cell
  DJNZ FillAttrLoop       ; 16 cells
  RET                     ; done

; The interrupt's sound: SoundFx after its step to a GS id, once per event
;
; Called by PlayInterrupt with A = SoundFx after it has counted it on (never 0
; here). Three values sound, each once: 2 (a shot fired: SoundFx was 1) sends
; id 4 (GS effect 6 or 7 by R; the driver's third choice, 8, is never reached:
; docs/09-sound.md 9.4), $FD (a miss: SoundFx $FC counted on; a hit counts $FA,
; $FB, $FC to it two frames later) sends id $0A (effect 13), $C9 (a robot
; destroyed: $C8 counted on) sends id 2 (effect 3 or 4 by R; 2 never). After
; any of them SoundFx = 0, so PlayInterrupt stops counting. Any other value is
; left to count on: SoundFx 3-$7F never comes back here as 2, $FA-$FC run to
; $FD, and $CA-$FF wrap through 0.
;
; Seen in recording r1 only for the menus; the shots were checked in stage 1
; with SoundFx poked during play (x6: $01 -> effect 6, $FC -> 13, $FA -> 13 two
; frames later, $C8 -> 3; docs/09-sound.md 9.5).
SoundEffect:
  CP $02                  ; 2: a shot fired this frame
  JR NZ,SoundEffectMiss
  LD A,$04                ; id 4: the shot
  CALL GsSound            ; GsSound
; This entry point is used by the routine at SoundEffectKill.
SoundEffectDone:
  LD A,$00                ; SoundFx = 0: played once
  LD (SoundFx),A
  RET                     ; done
SoundEffectMiss:
  CP $FD                  ; $FD: a miss (or a hit, two frames on)
  JR NZ,SoundEffectKill
  LD A,$0A                ; id $0A
  CALL GsSound
  JR SoundEffectDone      ; SoundFx = 0

; A RET no path reaches (after the JR above)
;
; One byte, $C9; never run.
SoundEffectFillA:
  DEFB $C9

; SoundEffectKill
;
; Used by the routine at SoundEffect.
SoundEffectKill:
  CP $C9                  ; $C9: a robot destroyed
  JR NZ,SoundEffectNone
  LD A,$02                ; id 2: the explosion
  CALL GsSound
  JR SoundEffectDone      ; SoundFx = 0
SoundEffectNone:
  RET                     ; another value: keep counting

; The tail of Nether Earth's noise loop, no longer reached
;
; 13 bytes: a RET, then the last instructions of Nether Earth's noise branch as
; they were (LD B,$1E; CALL Random; AND $10; OUT ($FE),A; DJNZ back; RET: 30
; random speaker levels). The conversion's SoundEffect ends before them and
; nothing jumps here.
SoundEffectLeftover:
  DEFB $C9,$06,$1E,$CD,$58,$D3,$E6,$10
  DEFB $D3,$FE,$10,$F7,$C9

; Build both radar pictures for the 128 columns from $FD1C
;
; Each map cell of the window is one pixel: set when its block type is $0F or
; more (the tall blocks). Copies the terrain picture to $D900, then puts the
; dot of every robot in play (+$01 not 0, except the one under direct control,
; +$0A = 2) into its side's picture (ToggleRadarDot). Called by $B029 when the
; ship moves the window ($FD52); once in Nether Earth's deep recording, at
; frame 35.
BuildRadar:
  LD HL,RadarOwn          ; the player's picture first
  LD DE,(RadarColumn)     ; the window's first map column
  LD A,D                  ; its high byte ...
  ADD A,$DD               ; ... on the map's base: $DD00 + column, row 0
  LD D,A                  ; DE = the map cell
  LD BC,$1010             ; 16 rows of 16 bytes
RadarRowLoop:
  PUSH BC                 ; keep the counts
  PUSH DE                 ; and the row's first cell
RadarByteLoop:
  PUSH BC                 ; keep the counts
  LD B,$08                ; 8 cells a byte
RadarBitLoop:
  LD A,(DE)               ; the cell
  INC DE                  ; the next column
  AND $1F                 ; the block type
  CP $0F                  ; carry: the type is $0F or more
  CCF                     ; (CCF: carry now set for $0F and above)
  RL (HL)                 ; the pixel into the radar byte from the right
  DJNZ RadarBitLoop       ; 8 cells
  INC HL                  ; the next radar byte
  POP BC                  ; the counts back
  DJNZ RadarByteLoop      ; 16 bytes: 128 columns
  POP DE                  ; the row's first cell
  POP BC                  ; the counts back
  INC D                   ; the next map row
  INC D                   ; (+$200)
  DEC C                   ; one row less
  JR NZ,RadarRowLoop      ; the next of the 16 map rows
  LD HL,RadarOwn          ; the same terrain for the enemy's picture
  LD DE,RadarEnemy        ; into the enemy's picture
  LD BC,$0100             ; 256 bytes
  LDIR                    ; copy
  LD IY,Robots            ; the robots
  LD B,$30                ; 48 records
RadarRobotLoop:
  PUSH BC                 ; keep the count
  LD A,(IY+$01)           ; +$01, the cell's high byte
  OR A                    ; 0: a free slot
  JR Z,RadarRobotNext     ; skip it
  LD L,(IY+$02)           ; HL = the column, +$02 ...
  LD H,(IY+$03)           ; ... +$03
  LD C,(IY+$04)           ; C = the row +$04
  LD A,(IY+$0A)           ; the side flags +$0A
  RLCA                    ; bit 7, the enemy, ...
  AND $01                 ; ... to bit 0
  LD B,A                  ; B = the picture: 0 the player's, 1 the enemy's
  LD A,(IY+$0A)           ; not the robot under direct control (the ship's dot
                          ; stands for it)
  CP $02                  ; 2: direct control
  CALL NZ,ToggleRadarDot  ; XOR the robot's dot in
RadarRobotNext:
  LD DE,$0010             ; the next 16-byte robot record
  ADD IY,DE               ; IY = the next record
  POP BC                  ; the count back
  DJNZ RadarRobotLoop     ; the next robot
  RET                     ; both pictures are built

; XOR a 2x2 dot at map column HL, row C into radar picture B (0 player, 1
; enemy)
;
; The dot covers (x, y), (x+1, y) and the line above. Nothing outside the
; window (RadarDotAddress returns past this routine). XOR: the same call
; removes the dot again, so the robot code toggles the old position before
; PlaceRobot toggles the new one.
ToggleRadarDot:
  CALL RadarDotAddress    ; HL = the dot's byte, A = the mask (outside the
                          ; window: returns from here)
  LD C,A                  ; C = the pixel mask
  PUSH HL                 ; keep the byte's address
  LD A,(HL)               ; (x, y)
  XOR C                   ; flip the pixel
  LD (HL),A               ; back
  RRC C                   ; the next pixel, maybe in the next byte
  JR NC,RadarDotRight     ; carry: the mask wrapped to bit 7
  INC HL                  ; of the next byte
RadarDotRight:
  LD A,(HL)               ; the right pixel, maybe in the next byte
  XOR C                   ; flip (x+1, y)
  LD (HL),A               ; back
  POP HL                  ; (x, y) again
  LD A,L                  ; the line above
  SUB $10                 ; - 16: one line up (a row 0 dot would wrap to line
                          ; 15; probably never: row 0 is the map's edge)
  LD L,A                  ; (L)
  RLC C                   ; the mask back to x
  LD A,(HL)               ; (x, y-1)
  XOR C                   ; flip it
  LD (HL),A               ; back
  RRC C                   ; the mask to x+1
  JR NC,RadarDotAboveRight ; no wrap: the same byte
  INC HL                  ; wrapped: the next byte
RadarDotAboveRight:
  LD A,(HL)               ; the right pixel of the line above
  XOR C                   ; flip (x+1, y-1)
  LD (HL),A               ; back
  RET                     ; the dot is toggled

; HL = the radar byte of column HL, row C in picture B, A = the pixel mask
;
; Column x - $FD1C must be 0-126, else it pops the return address and returns
; from ToggleRadarDot. Address = $D800 + $100*B + 16*y + (x-$FD1C)/8, mask =
; $80 >> ((x-$FD1C) AND 7).
RadarDotAddress:
  LD DE,(RadarColumn)     ; the window's first column
  XOR A                   ; no borrow
  SBC HL,DE               ; HL = x - the window's left edge
  LD A,H                  ; the high byte
  OR A                    ; not 0: left (negative) or more than 255 right
  JR NZ,RadarDotOutside   ; outside
  LD A,L                  ; 0-255
  CP $7F                  ; 127 or more: the dot's right half would leave the
                          ; window
  JR NC,RadarDotOutside   ; outside
  LD A,$D8                ; $D800 or $D900
  ADD A,B                 ; + B, the picture
  LD H,A                  ; H = its page
  LD A,L                  ; the column
  AND $07                 ; the pixel in the byte
  INC A                   ; + 1: the shift count
  LD B,A                  ; B = it
  LD A,L                  ; L = 16*y + x/8
  RLCA                    ; the byte column x / 8 ...
  AND $F0                 ; ... to the high nibble
  OR C                    ; the row y in the low nibble
  RLCA                    ; nibbles ...
  RLCA                    ; ...
  RLCA                    ; ...
  RLCA                    ; ... swapped
  LD L,A                  ; L = 16 y + x / 8
  XOR A                   ; the mask: $80 shifted right x AND 7 times
  SCF                     ; the 1 ...
RadarMaskShift:
  RRA                     ; $80 shifted right (x AND 7) times
  DJNZ RadarMaskShift     ; B times
  RET                     ; HL = the byte, A = the mask
RadarDotOutside:
  POP HL                  ; outside the window: return from ToggleRadarDot too
  RET                     ; to ToggleRadarDot's caller: nothing drawn
