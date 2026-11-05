; --------------------------------------------------------------------------------------------------------------------
; interrupts.asm: the frame interrupts of play, the radar, the shot sounds
;
; The IM 2 handlers: the vector $FDFD jumps to Handler ($FDFE), which Start, EnterPlay and the menus switch.
; PlayInterrupt runs once a frame in play: TurnFrames + 1 (the play loop's 10-frame turn), one of the two radar
; pictures (ShowRadar, by RadarPhase), and one step of the running sound effect (SoundEffect, by SoundFx).
; StartInterrupt is EI; RET, the handler while the world must stand still (the start-up, the construction menu,
; saving, the game's end). The menu's handler MenuInterrupt is in the start module.
;
; The radar: two pictures of 16 lines x 16 bytes, RadarOwn $D800 (the terrain + the player's robots, shown in $4D,
; cyan on blue) and RadarEnemy $D900 (the terrain + the enemy's, $4E, yellow on blue), one pixel a map cell for the
; 128 columns from RadarColumn. Shown in turns every frame at rows 22-23, columns 6-21: the terrain stays, each side's
; robots blink at 25 Hz in their colour. BuildRadar makes both from the map; ToggleRadarDot (with RadarDotAddress)
; XORs one robot's 2 x 2 dot in or out.
;
; The sound: SoundFx is set by the shot code (1 a shot fired, $FC a miss, $FA a hit, $C8 a robot destroyed) and
; counted on by the interrupt. 2-$7F: a burst of pulses from the ROM's bytes, fewer and further apart each frame, a
; falling sweep until $80; $C8-$FF: 30 random speaker levels a frame until it wraps to 0. At most 3.2 ms a frame.
;
; The interrupt runs with interrupts off (the CPU's acceptance) and turns them on only at its last EI. The radar costs
; 8134 T a frame, 11 % of all the time in play.
; --------------------------------------------------------------------------------------------------------------------

; the interrupt handler of play, one a frame
;
; Installed by EnterPlay ($A694) and when the construction menu ends ($CBA2).
; Keeps AF, BC, DE, HL (not IX, IY, the alternate set: the routines it calls do
; not use them). TurnFrames + 1 (TurnPace $AE1D waits for 10, then zeroes it;
; RadarPhase toggled, ShowRadar with RadarOwn / $4D on phase 0, RadarEnemy /
; $4E on phase 1; SoundFx not 0: counted on (a tone ends at $80, a noise when
; it wraps to 0) and SoundEffect plays this frame's step. Ends in
; StartInterrupt's EI; RET.
PlayInterrupt:
  PUSH AF                 ; keep the interrupted code's registers
  PUSH BC                 ; (BC)
  PUSH DE                 ; (DE)
  PUSH HL                 ; (HL)
  LD HL,TurnFrames             ; the frame counter: the play loop waits for 10
                          ; ($AE1D)
  INC (HL)                ; one more frame of this turn
  LD HL,RadarOwn             ; the player's radar picture, cyan
  LD C,$4D                ; its attribute: bright cyan on blue
  LD A,(RadarPhase)            ; the other picture each frame
  XOR $01                 ; toggle
  LD (RadarPhase),A            ; kept for the next frame
  JR Z,InterruptRadar     ; phase 0: the player's picture
  LD HL,RadarEnemy             ; the enemy's radar picture, yellow
  LD C,$4E                ; bright yellow on blue
InterruptRadar:
  CALL ShowRadar          ; show it
  LD A,(SoundFx)            ; a sound effect running?
  OR A                    ; (0: silent)
  JR Z,InterruptExit      ; silent: on to the exit
  INC A                   ; one step on each frame: a tone ends at $80, a noise
                          ; when it wraps past $FF to 0
  CP $80                  ; the tone's end?
  JR NZ,InterruptSoundStore ; no: keep the count
  XOR A                   ; the tone is over: silent
InterruptSoundStore:
  LD (SoundFx),A
  OR A                    ; the flags of A: M noise, P the falling tone
  CALL NZ,SoundEffect     ; this frame's burst (the flags of the OR above
                          ; choose its kind)
InterruptExit:
  POP HL
  POP DE                  ; (DE)
  POP BC                  ; (BC)
  POP AF                  ; (AF; on into StartInterrupt

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

; The interrupt's sound: A = $FD53 (1-$7F a falling tone, $C8-$FF noise)
;
; Called by PlayInterrupt with A = SoundFx after its step, the flags of A set
; (never 0 here). A positive (2-$7F, a shot fired: SoundFx 1 counted on): C =
; 500 / (A+2) + 1 pulses, B = A the delay between them; each pulse's level is
; bit 4 of the next ROM byte from $0000 (a rough noise), so the bursts get
; sparser and lower as A counts up each frame: a falling sweep over 126 frames,
; 3.2 ms at A = 2, about 2 ms from A = 40. A negative ($C8-$FF): 30 random
; speaker levels (Random): the crackle of a hit.
;
; The shot code sets 1 when a shot is fired ($B709), $FC a miss (3 frames), $FA
; a hit (5 frames), $C8 a robot destroyed (55 frames, the explosion)... $16,
; then $FA-$FF. Changes A, BC, DE, HL. The border stays black (bits 0-2 of the
; OUT are 0).
SoundEffect:
  JP M,NoiseSound         ; $80-$FF: the noise
  LD B,A                  ; B = the delay between pulses
  INC A                   ; A + 2...
  INC A                   ; ... the divisor
  LD HL,$01F4             ; C = about 500 / (A + 2) pulses
  LD E,A                  ; DE = A + 2
  LD D,$00                ; (D = 0)
  LD C,$00                ; C counts
  XOR A                   ; no borrow into the first SBC
PulseCountLoop:
  INC C                   ; one more pulse
  SBC HL,DE               ; 500 - n (A+2)
  JR NC,PulseCountLoop    ; until it goes below 0: C = 500 / (A+2) + 1
  LD HL,$0000             ; the ROM as noise
PulseLoop:
  PUSH BC                 ; keep the delay and the count
  LD A,(HL)               ; a ROM byte
  INC HL                  ; the next
  AND $10                 ; its bit 4: the speaker
  OUT ($FE),A             ; the speaker level (border black)
PulseDelay:
  DJNZ PulseDelay         ; wait B x 13 T
  POP BC                  ; the delay and the count back
  DEC C                   ; one pulse less
  JR NZ,PulseLoop         ; the next pulse
  XOR A                   ; speaker off
  OUT ($FE),A             ; (port $FE)
  RET                     ; this frame's burst is over
NoiseSound:
  LD B,$1E                ; 30 levels
NoiseLoop:
  CALL Random             ; a random byte
  AND $10                 ; its bit 4: the speaker
  OUT ($FE),A             ; the level
  DJNZ NoiseLoop          ; 30 times
  RET                     ; this frame's crackle is over

; Build both radar pictures for the 128 columns from $FD1C
;
; Each map cell of the window is one pixel: set when its block type is $0F or
; more (the tall blocks). Copies the terrain picture to $D900, then puts the
; dot of every robot in play (+$01 not 0, except the one under direct control,
; +$0A = 2) into its side's picture (ToggleRadarDot). Called by $B029 when the
; ship moves the window ($FD52;
BuildRadar:
  LD HL,RadarOwn             ; the player's picture first
  LD DE,(RadarColumn)           ; the window's first map column
  LD A,D                  ; its high byte...
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
  LD HL,RadarOwn             ; the same terrain for the enemy's picture
  LD DE,RadarEnemy             ; into the enemy's picture
  LD BC,$0100             ; 256 bytes
  LDIR                    ; copy
  LD IY,Robots             ; the robots
  LD B,$30                ; 48 records
RadarRobotLoop:
  PUSH BC                 ; keep the count
  LD A,(IY+$01)           ; +$01, the cell's high byte
  OR A                    ; 0: a free slot
  JR Z,RadarRobotNext     ; skip it
  LD L,(IY+$02)           ; HL = the column, +$02...
  LD H,(IY+$03)           ; ... +$03
  LD C,(IY+$04)           ; C = the row +$04
  LD A,(IY+$0A)           ; the side flags +$0A
  RLCA                    ; bit 7, the enemy,...
  AND $01                 ; ... to bit 0
  LD B,A                  ; B = the picture: 0 the player's, 1 the enemy's
  LD A,(IY+$0A)           ; not the robot under direct control (the ship's dot
                          ; stands for it)
  CP $02                  ; 2: direct control
  CALL NZ,ToggleRadarDot  ; XOR the robot's dot in
RadarRobotNext:
  LD DE,$0010
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
  LD A,(HL)
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
  LD A,(HL)
  XOR C                   ; flip (x+1, y-1)
  LD (HL),A               ; back
  RET                     ; the dot is toggled

; HL = the radar byte of column HL, row C in picture B, A = the pixel mask
;
; Column x - $FD1C must be 0-126, else it pops the return address and returns
; from ToggleRadarDot. Address = $D800 + $100*B + 16*y + (x-$FD1C)/8, mask =
; $80 >> ((x-$FD1C) AND 7).
RadarDotAddress:
  LD DE,(RadarColumn)           ; the window's first column
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
  RLCA                    ; the byte column x / 8...
  AND $F0                 ; ... to the high nibble
  OR C                    ; the row y in the low nibble
  RLCA                    ; nibbles...
  RLCA                    ; ...
  RLCA                    ; ...
  RLCA                    ; ... swapped
  LD L,A                  ; L = 16 y + x / 8
  XOR A                   ; the mask: $80 shifted right x AND 7 times
  SCF                     ; the 1...
RadarMaskShift:
  RRA
  DJNZ RadarMaskShift     ; B times
  RET                     ; HL = the byte, A = the mask
RadarDotOutside:
  POP HL                  ; outside the window: return from the caller too
  RET                     ; to ToggleRadarDot's caller: nothing drawn
