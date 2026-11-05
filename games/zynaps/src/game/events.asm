; --------------------------------------------------------------------------------------------------------------------
; events.asm: the event scheduler: one request bit a job, the sprite builds, the pod icon, the score, the effects
;
; The play loop ($B1E6) does nothing but call EventDispatch until EndCode is set; the work it runs is posted by
; setting a bit in EventRequests ($81C5) from the interrupt, the collisions and the weapons. EventMask ($81C6, $FF
; from the play loop's start) enables the bits; the highest requested and enabled bit wins (bit 7 first), its request
; bit is cleared and its handler runs from the table EventHandlers ($81C7, 8 words, bit 7 first) through JumpTable
; $91E2. The mask is kept over the handler, so a handler that narrows it (the redraw jobs allow only bit 7 while they
; run) narrows it for its own run only: a long job can be cut by a higher one posted meanwhile, since the effect
; player $B30C calls EventDispatch from its tone loop. c2: 68560 calls, 38 of them ran a handler.
;
; The bits: 7 the sprite cache's build ring (SpriteBuildJob, posted by QueueSpriteLoad $945B when a new kind needs its
; sprite), 6-3 unused (the RET at EventNone), 2 the pod selector's icon (PodIconJob, posted at $A243 and at the play
; loop's start), 1 the score and the extra life (ScoreJob, $A4AB), 0 an effect (EffectJob, posted by RequestEffect
; $B2F0).
;
; The build ring: DrawQueueRead $8024 (this side) and DrawQueueWrite $8025 (QueueSpriteLoad's side) index 8 entries of
; 3 bytes at $8026: the kind and the address of its sprite descriptor (the records of 16 bytes at $7EF2). Each entry
; gets its image built (LoadCellSprite: from the glyphs at $6400 by BuildCellSprite, or a big one by BuildBigSprite)
; and its pre-shifted copies made (SpriteBuildShifts), then bit 7 of the descriptor's +$0E (waiting) is cleared and
; the objects of that kind can be drawn. The builds run in the play loop's time, so a new wave's sprites cost no
; interrupt time.
; --------------------------------------------------------------------------------------------------------------------

; run the highest requested and enabled job; carry set when one ran
;
; In: EventRequests $81C5, EventMask $81C6. Out: NC (Z) when nothing was
; pending; carry after a handler ran. Clobbers AF, BC, DE, HL and what the
; handler uses. Callers: the play loop ($B1E6, c2: 68083 calls) and the effect
; player's tone loop ($B376, so a long effect does not stop the scheduler). The
; handler is jumped to through $91E2 with the index of the bit (0 = bit 7), its
; bit cleared in EventRequests first.
EventDispatch:
  LD HL,EventMask

; EventPending
EventPending:
  LD A,(EventRequests)    ; the requests

; EventEnabled
EventEnabled:
  AND (HL)                ; the enabled ones

; EventAny
EventAny:
  RET Z                   ; none: Z and NC
  LD B,(HL)               ; the mask is kept over the handler
  PUSH BC
  LD B,$FF                ; B counts the shifts: the index of the highest set
                          ; bit, 0 = bit 7
  LD C,A
  LD A,B
EventFindBit:
  INC B                   ; A halves until it is not above the requests: B
                          ; shifts = the bit's index
  RRA
  CP C
  JR NC,EventFindBit
  AND C                   ; AND C: the requests below the winner's bit stay
  LD (EventRequests),A
  LD A,B                  ; the bit's index selects the handler
  LD HL,EventHandlers
  CALL JumpTable          ; jump-by-index

; EventDone
EventDone:
  POP AF                  ; the mask back
  LD (EventMask),A
  SCF                     ; carry: a job ran
  RET

; the handler of the unused bits 6-3: RET
EventNone:
  RET

; event bit 2: the pod selector's icon and its colours
;
; Allows only bit 7 meanwhile (EventMask AND $80). Attributes $46 (bright
; yellow) at $5A86-$5A87 and $45 (bright cyan) at $5AA6-$5AA7; the 16 x 16 icon
; n = the player record's +7 (0-4, the selected pod) from PodIcons + 32 n drawn
; as two 2-cell rows at $5086 and $50A6 (screen third 2, rows 16-17, columns
; 6-7) by IconRow. c2: entries through $91E2 (indirect); posted by the play
; loop's start ($B1C7) and by the pod pick-up ($A243).
PodIconJob:
  LD HL,EventMask
  LD A,$80
  AND (HL)
  LD (HL),A
  LD HL,$4646             ; the upper cells bright yellow on black
  LD ($5A86),HL
  LD HL,$4545             ; the lower cells bright cyan on black
  LD ($5AA6),HL
  LD IX,(PlayerRecord)    ; the player record: +7 the pod selector, 0-4
  LD A,(IX+$07)
  RRCA                    ; three RRCAs and the split: DE = n * 32
  RRCA
  RRCA
  LD E,A
  AND $1F
  LD D,A
  XOR E
  LD E,A
  LD HL,PodIcons          ; PodIcons + n * 32
  ADD HL,DE
  EX DE,HL
  LD HL,$5086             ; the upper row of the icon, row 16 columns 6-7
  CALL IconRow

; IconLowerRow
IconLowerRow:
  LD A,L                  ; HL is one cell further twice: + $1E = the next
                          ; character row
  ADD A,$1E
  LD L,A

; two character cells of 8 lines from DE to the screen at HL
;
; In: DE the bytes (8 of the left cell, then 8 of the right), HL the screen
; address of the left cell. Out: DE past the 16 bytes, HL two cells right.
; Called twice by PodIconJob (the second time by falling in).
IconRow:
  LD C,$02

; IconCell
;
; Used by the routine at IconLine.
IconCell:
  PUSH HL
  LD B,$08

; IconLine
IconLine:
  LD A,(DE)               ; one line a pixel row down (INC H)
  LD (HL),A
  INC DE
  INC H
  DJNZ IconLine
  POP HL
  INC L
  DEC C
  JR NZ,IconCell
  RET

; event bit 0: play the requested sound effect
;
; Drops bit 0 from the mask (a second effect request waits; the effect player
; posts no more of itself) and calls the effect player $B30C, which keeps the
; scheduler going from its tone loop. Posted by RequestEffect ($B2F0).
EffectJob:
  LD HL,EventMask
  LD A,$FE
  AND (HL)
  LD (HL),A
  CALL EffectPlay

; EffectJobDone
EffectJobDone:
  RET

; event bit 1: print the score, the extra life
;
; Allows only bit 7 meanwhile. Prints the current player's score
; (PrintPlayerScore $A4AE with A = CurrentPlayer $7F98) and recomputes
; WeaponRating ($9B75: how fast the next waves fly). The extra life: when the
; record's +1 (the score's high part) is at least ExtraLifeScores[+$0C] ($800F:
; 1, 3, 5, 7, 9, then $FF), +$0C steps on, the lives (+4) + 1 and DrawLives
; $A4EF shows them. Posted by the score adder ($A4AB).
ScoreJob:
  LD HL,EventMask
  LD A,$80
  AND (HL)
  LD (HL),A
  LD A,(CurrentPlayer)    ; the score of the player in play
  CALL PrintPlayerScore

; ScoreJobRating
ScoreJobRating:
  CALL WeaponRating       ; WeaponRating
  LD IX,(PlayerRecord)    ; the next extra life's threshold: $800F + the
                          ; record's +$0C
  LD E,(IX+$0C)
  LD D,$00
  LD HL,ExtraLifeScores
  ADD HL,DE
  LD A,(IX+$01)           ; the record's +1 against it
  CP (HL)
  RET C
  INC (IX+$0C)            ; one threshold on, one life more
  INC (IX+$04)
  CALL DrawLives
  RET

; event bit 7: build the sprites waiting in the ring
;
; Sets the mask to 0 (nothing interrupts it), then builds every entry between
; DrawQueueRead ($8024) and DrawQueueWrite ($8025): entry k at $8026 + 3 k is
; the kind and the descriptor's address; LoadCellSprite the image,
; SpriteBuildShifts the shifted copies, then bit 7 of the descriptor's +$0E
; (waiting) is cleared. The read index wraps at 8 (RES 3). c2: 5 builds
; (BuildCellSprite 5 entries, RotateSprite 35).
SpriteBuildJob:
  LD HL,EventMask
  LD A,$00
  AND (HL)
  LD (HL),A

; SpriteBuildNext
;
; Used by the routine at SpriteBuildDone.
SpriteBuildNext:
  LD HL,DrawQueueRead     ; the read index against QueueSpriteLoad's
  LD A,(DrawQueueWrite)
  CP (HL)

; SpriteBuildEmpty
SpriteBuildEmpty:
  RET Z                   ; the ring is empty
  LD A,(HL)
  INC (HL)                ; one entry on, wrapping at 8
  RES 3,(HL)
  LD L,A                  ; the entry: 3 bytes an entry
  ADD A,A
  ADD A,L
  LD E,A
  LD D,$00
  LD HL,DrawQueue
  ADD HL,DE
  LD A,(HL)               ; A = the type, HL = the record
  INC HL
  LD E,(HL)
  INC HL
  LD D,(HL)
  EX DE,HL
  PUSH HL
  CALL LoadCellSprite
  CALL SpriteBuildShifts

; SpriteBuildDone
SpriteBuildDone:
  POP HL                  ; +$0E of the descriptor: bit 7 waiting, cleared
  LD DE,$000E
  ADD HL,DE
  RES 7,(HL)
  JR SpriteBuildNext

; build a kind's image from its glyphs
;
; In: A the kind, HL the descriptor (+0/+1 the image's address). Kinds $14 and
; up go to BuildBigSprite $8F0C with kind - $13 (not reached in c1 or c2; r1: 6
; entries, frames 16855-66273: the big enemies). Else the glyphs are at $6400 +
; 32 kind (kinds 16-19: 48 bytes each, + 16 (kind - 16) + 32 more), B = 2 cells
; a column, C = 2 columns or 3 for bit 4 of the kind; BuildCellSprite $8EDB
; builds the complemented image with blank borders. HL is kept. c2: 5 entries.
LoadCellSprite:
  PUSH HL
  CP $14                  ; kinds $14 and up: the big sprite
  JR C,SpriteBuildSmall
  SUB $13
  CALL BuildBigSprite
  POP HL
  RET
SpriteBuildSmall:
  LD E,(HL)               ; DE = the record's screen address
  INC HL
  LD D,(HL)
  PUSH AF
  RRCA                    ; BC = kind * 32
  RRCA
  RRCA
  LD B,A
  AND $E0
  LD C,A
  XOR B
  LD B,A
  POP AF
  PUSH AF
  SUB $10                 ; kinds 16 and up: 48 bytes each
  LD HL,$0000
  JR C,SpriteBuildSource
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,A
  ADD A,$20
  LD L,A
SpriteBuildSource:
  ADD HL,BC               ; + $6400: the kinds' glyphs
  LD BC,$6400
  ADD HL,BC
  POP AF
  LD BC,$0202             ; 2 cells by 2 columns; 3 columns for bit 4
  BIT 4,A
  JR Z,SpriteBuildDraw
  LD C,$03
SpriteBuildDraw:
  CALL BuildCellSprite
  POP HL
  RET

; the pre-shifted copies of a sprite: seven one-pixel shifts, a new copy where
; the pattern says
;
; In: HL the descriptor. Its +4/+5 (the image's length), +9 (the shift pattern)
; and +$0A/+$0B (BC for RotateSprite: B the width in bytes, C the height in
; lines) are written into the operands of LD HL ($AD3E), LD A ($AD47) and LD BC
; ($AD4A): self-modified code. DE = the image (+0/+1). Seven rounds, one a
; pixel: the first always, and later each set bit of the pattern (RRA), copy
; the current image to the next slot (LDIR of the length) and continue on the
; copy; then RotateSprite $8F5A shifts it one pixel right. A clear bit shifts
; the last copy on without a new slot, so the pattern chooses which of the 8
; pixel positions get an image (8, 4 or 2 copies). c2: 5 entries, RotateSprite
; 35 times (7 a sprite).
SpriteBuildShifts:
  LD E,(HL)
  INC HL
  LD D,(HL)
  INC HL
  INC HL
  INC HL
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (SpriteShiftLength+$0001),BC ; the length into the LD HL operand
  INC HL
  INC HL
  INC HL
  LD A,(HL)
  INC HL
  LD (SpriteShiftPattern+$0001),A ; the bit pattern into the LD A operand
  LD C,(HL)
  INC HL
  LD B,(HL)
  LD (SpriteShiftCount+$0001),BC ; the count into the LD BC operand
  LD A,$01                ; the first pattern bit; seven rounds
  LD B,$07
  EX DE,HL

; SpriteShiftRound
;
; Used by the routine at SpriteShiftLoop.
SpriteShiftRound:
  PUSH BC
  RRA                     ; the next bit of the pattern

; SpriteShiftTest
SpriteShiftTest:
  JR NC,SpriteShiftStep   ; clear: no new copy, shift the last one on
  EX DE,HL
SpriteShiftLength:
  LD HL,$0000             ; LD HL,length: the operand written at $AD20
  LD B,H
  LD C,L
  ADD HL,DE
  EX DE,HL

; SpriteShiftCopy
SpriteShiftCopy:
  LDIR
SpriteShiftPattern:
  LD A,$00                ; LD A,pattern: the operand written at $AD29
; This entry point is used by the routine at SpriteShiftTest.
SpriteShiftStep:
  PUSH HL
SpriteShiftCount:
  LD BC,$0000             ; LD BC,count: the operand written at $AD2F
  PUSH AF
  CALL RotateSprite

; SpriteShiftNext
SpriteShiftNext:
  POP AF
  POP HL
  POP BC

; SpriteShiftLoop
SpriteShiftLoop:
  DJNZ SpriteShiftRound   ; seven rounds
  RET

; the wave script's state back from the player record
;
; Copies the player record's +$0D-+$2F (35 bytes, the checkpoint that
; CmdCheckpoint $AED2 and SetLevelStart $B062 write) to the VM state
; ScriptState $81D7-$81F9. Called by RoundSetup ($B023), so a level restarts at
; its last checkpoint after a lost life. c2: 1 entry.
RestoreCheckpoint:
  LD HL,(PlayerRecord)
  LD DE,$000D
  ADD HL,DE
  LD DE,ScriptState
  LD BC,$0023
  LDIR
  RET
