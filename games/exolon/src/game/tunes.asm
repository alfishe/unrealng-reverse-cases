; --------------------------------------------------------------------------------------------------------------------
; tunes.asm: The beeper tunes and the two-voice tone player
; --------------------------------------------------------------------------------------------------------------------

; Plays a two-voice beeper tune (3 bytes a note) until its end or a key: HL =
; the tune
;
; Waits for no key, keeps the pointer in TunePointer $7FEF. Each note: a key
; down ends the tune; the length byte (0 ends) into TuneNoteLength $7FEE, then
; two note numbers: both 0 is a rest (PlayTuneRest), else D, E = their periods
; from the table $8062 and $803D plays them together for the length. Plays on
; the beeper on both machines (no SoundIsAy test).
;
; Callers: MainMenu (TitleTune, 48K only), ZorbaCheat (JingleTune), GAME OVER
; $A02A (JingleTune). c1: 7 calls (the title tune at each load, GAME OVER).
PlayTune:
  XOR A
  IN A,($FE)
  CPL
  AND $1F
  JR NZ,PlayTune
  LD (TunePointer),HL
; This entry point is used by the routines at PlayTuneRest and PlayTuneNote.
TuneNextNote:
  XOR A                   ; a key ends the tune
  IN A,($FE)
  AND $1F
  CP $1F
  JP Z,BeeperTuneNote
TuneDone:
  RET
BeeperTuneNote:
  LD HL,(TunePointer)     ; the length (0 ends), the two note numbers
  LD A,(HL)
  OR A
  JP Z,TuneDone
  INC HL
  LD (TuneNoteLength),A
  LD C,(HL)
  INC HL
  LD B,(HL)
  INC HL
  LD (TunePointer),HL
  LD A,C
  OR B
  JP NZ,PlayTuneNote

; A rest: the silent twin $8004 for the note's length, then the next note
;
; Never ran: neither tune holds a rest (both note numbers 0).
PlayTuneRest:
  LD A,(TuneNoteLength)
  CALL BeeperRest
  JP TuneNextNote

; A note: D = the period of the first number, E of the second ($8062), A = the
; length; $803D plays it
;
; Used by the routine at PlayTune.
PlayTuneNote:
  LD H,$00
  LD L,C
  LD DE,NoteReloads
  ADD HL,DE
  LD D,(HL)
  LD H,$00
  LD L,B
  LD BC,NoteReloads
  ADD HL,BC
  LD E,(HL)
  LD A,(TuneNoteLength)
  CALL PlayTwoTones
  JP TuneNextNote

; 1 from Start to the first menu: the title tune is still to play (MainMenu
; clears it)
TitleTunePending:
  DEFB $00

; A short tune of 19 notes (length, note, note) and its end: the cheat's and
; GAME OVER's jingle
;
; Notes 18 x (15, n, m): falling arpeggios over the notes $1C-$17, then (45,
; $1C, $28); a length 0 ends. PlayTune from ZorbaCheat and $A030 (GAME OVER).
JingleTune:
  DEFB $0F,$1C,$28
  DEFB $0F,$1C,$2C
  DEFB $0F,$1C,$2F
  DEFB $0F,$1B,$27
  DEFB $0F,$1B,$2B
  DEFB $0F,$1B,$2E
  DEFB $0F,$1A,$26
  DEFB $0F,$1A,$2A
  DEFB $0F,$1A,$2D
  DEFB $0F,$19,$25
  DEFB $0F,$19,$29
  DEFB $0F,$19,$2C
  DEFB $0F,$18,$24
  DEFB $0F,$18,$28
  DEFB $0F,$18,$2B
  DEFB $0F,$17,$23
  DEFB $0F,$17,$27
  DEFB $0F,$17,$2A
  DEFB $2D,$1C,$28
  DEFB $00,$00            ; the end, and a spare 0

; The 48K title tune: 195 notes (length, note, note), lengths 18 to 90 in steps
; of 18, notes up to 50
;
; PlayTune from MainMenu once per load on a 48K, any key cuts it. The note
; numbers index the period table $8062 (53 entries).
TitleTune:
  DEFB $12,$13,$2B
  DEFB $12,$13,$26
  DEFB $12,$13,$2B
  DEFB $12,$13,$2F
  DEFB $24,$13,$32
  DEFB $24,$13,$26
  DEFB $24,$18,$28
  DEFB $12,$18,$30
  DEFB $12,$18,$2F
  DEFB $12,$18,$30
  DEFB $12,$18,$2F
  DEFB $24,$18,$2D
  DEFB $12,$1A,$2D
  DEFB $12,$1A,$2A
  DEFB $12,$1A,$2B
  DEFB $24,$1A,$2D
  DEFB $12,$1A,$2A
  DEFB $24,$1A,$26
  DEFB $24,$13,$30
  DEFB $12,$13,$30
  DEFB $36,$13,$2F
  DEFB $24,$13,$2B
  DEFB $12,$13,$2B
  DEFB $12,$13,$26
  DEFB $12,$13,$2B
  DEFB $12,$13,$2F
  DEFB $24,$13,$32
  DEFB $24,$13,$26
  DEFB $24,$18,$28
  DEFB $12,$18,$30
  DEFB $12,$18,$2F
  DEFB $12,$18,$30
  DEFB $12,$18,$2F
  DEFB $24,$18,$2D
  DEFB $12,$1A,$2D
  DEFB $12,$1A,$2A
  DEFB $12,$1A,$2B
  DEFB $24,$1A,$2D
  DEFB $12,$1A,$2A
  DEFB $24,$1A,$26
  DEFB $24,$13,$30
  DEFB $12,$13,$30
  DEFB $36,$13,$2F
  DEFB $24,$13,$2D
  DEFB $24,$10,$2B
  DEFB $24,$10,$23
  DEFB $24,$10,$2B
  DEFB $12,$10,$23
  DEFB $24,$10,$2F
  DEFB $12,$10,$23
  DEFB $12,$10,$2F
  DEFB $12,$10,$23
  DEFB $12,$10,$2D
  DEFB $12,$10,$23
  DEFB $12,$10,$2B
  DEFB $12,$10,$23
  DEFB $24,$0C,$2B
  DEFB $24,$0C,$24
  DEFB $24,$0C,$2B
  DEFB $12,$0C,$24
  DEFB $24,$0C,$2F
  DEFB $12,$0C,$24
  DEFB $12,$0C,$2F
  DEFB $12,$0C,$24
  DEFB $12,$0C,$2D
  DEFB $12,$0C,$24
  DEFB $12,$0C,$2B
  DEFB $12,$0C,$24
  DEFB $24,$10,$2B
  DEFB $24,$10,$23
  DEFB $24,$10,$2B
  DEFB $12,$10,$23
  DEFB $24,$10,$2F
  DEFB $12,$10,$23
  DEFB $12,$10,$2F
  DEFB $12,$10,$23
  DEFB $12,$10,$2D
  DEFB $12,$10,$23
  DEFB $12,$10,$2B
  DEFB $12,$10,$23
  DEFB $24,$0C,$2B
  DEFB $24,$0C,$24
  DEFB $24,$0C,$2B
  DEFB $12,$0C,$24
  DEFB $24,$0C,$2F
  DEFB $12,$0C,$24
  DEFB $12,$0C,$2F
  DEFB $12,$0C,$24
  DEFB $12,$0C,$2D
  DEFB $12,$0C,$24
  DEFB $12,$0C,$2B
  DEFB $12,$0C,$24
  DEFB $24,$10,$2F
  DEFB $24,$10,$30
  DEFB $12,$10,$2D
  DEFB $24,$10,$2F
  DEFB $24,$10,$2B
  DEFB $24,$10,$2D
  DEFB $24,$10,$2A
  DEFB $12,$10,$2F
  DEFB $24,$10,$28
  DEFB $24,$10,$2F
  DEFB $24,$10,$30
  DEFB $12,$10,$2D
  DEFB $24,$10,$2F
  DEFB $24,$10,$2B
  DEFB $24,$10,$2D
  DEFB $24,$10,$2A
  DEFB $12,$10,$2F
  DEFB $24,$10,$28
  DEFB $24,$0C,$2D
  DEFB $12,$0C,$2D
  DEFB $5A,$0C,$2B
  DEFB $24,$0C,$18
  DEFB $12,$0C,$2B
  DEFB $24,$0C,$2D
  DEFB $12,$0C,$2D
  DEFB $24,$0C,$2B
  DEFB $24,$07,$28
  DEFB $12,$07,$28
  DEFB $5A,$07,$26
  DEFB $24,$07,$13
  DEFB $12,$07,$26
  DEFB $24,$07,$28
  DEFB $12,$07,$28
  DEFB $24,$07,$26
  DEFB $24,$10,$2F
  DEFB $24,$10,$30
  DEFB $12,$10,$2D
  DEFB $24,$10,$2F
  DEFB $24,$10,$2B
  DEFB $24,$10,$2D
  DEFB $24,$10,$2A
  DEFB $12,$10,$2F
  DEFB $24,$10,$28
  DEFB $24,$10,$2F
  DEFB $24,$10,$30
  DEFB $12,$10,$2D
  DEFB $24,$10,$2F
  DEFB $24,$10,$2B
  DEFB $24,$10,$2D
  DEFB $24,$10,$2A
  DEFB $12,$10,$2F
  DEFB $24,$10,$28
  DEFB $24,$0C,$2D
  DEFB $12,$0C,$2D
  DEFB $5A,$0C,$2B
  DEFB $24,$0C,$18
  DEFB $12,$0C,$2B
  DEFB $24,$0C,$2D
  DEFB $12,$0C,$2D
  DEFB $24,$0C,$2B
  DEFB $24,$07,$28
  DEFB $12,$07,$28
  DEFB $5A,$07,$26
  DEFB $24,$07,$13
  DEFB $12,$07,$26
  DEFB $24,$07,$28
  DEFB $12,$07,$26
  DEFB $12,$07,$28
  DEFB $12,$07,$26
  DEFB $48,$11,$24
  DEFB $48,$11,$21
  DEFB $24,$11,$24
  DEFB $12,$11,$21
  DEFB $24,$11,$24
  DEFB $12,$11,$21
  DEFB $12,$11,$28
  DEFB $12,$11,$26
  DEFB $48,$0C,$24
  DEFB $48,$0C,$1F
  DEFB $24,$0C,$24
  DEFB $12,$0C,$1F
  DEFB $24,$0C,$24
  DEFB $12,$0C,$1F
  DEFB $12,$0C,$28
  DEFB $12,$0C,$26
  DEFB $24,$11,$24
  DEFB $24,$11,$21
  DEFB $24,$11,$24
  DEFB $24,$11,$21
  DEFB $24,$11,$24
  DEFB $12,$11,$21
  DEFB $24,$11,$24
  DEFB $12,$11,$21
  DEFB $12,$11,$28
  DEFB $12,$11,$26
  DEFB $24,$0C,$24
  DEFB $24,$0C,$1F
  DEFB $24,$0C,$24
  DEFB $24,$0C,$1F
  DEFB $12,$0C,$24
  DEFB $12,$0C,$30
  DEFB $12,$0C,$30
  DEFB $24,$0C,$24
  DEFB $00,$00            ; the end, and a spare 0

; The current note's length (PlayTune), passed in A to the tone routine
TuneNoteLength:
  DEFB $EE
TunePointer:
  DEFB $00,$00            ; the next note of the tune (PlayTune), a word

; The silent twin of the tone engine (the rest): the loop head, never ran
;
; $7FF1-$802A is the two-voice engine of $802B-$8061 assembled again with each
; OUT ($FE),A replaced by three NOPs (12 T-states for 11): the same loops and
; timing, no sound. So a rest lasts as long as a note of the same length.
; Entered at BeeperRest $8004 from PlayTuneRest. Never ran in any recording (no
; tune has a rest).
BeeperRestHead:
  AND $FF
  EX AF,AF'
  INC D
  JP NZ,RestTurnB
; This entry point is used by the routine at BeeperRest.
RestTurnA:
  NOP                     ; NOP NOP NOP where the engine has OUT ($FE),A
  NOP
  NOP
  XOR C
  LD D,L
  DJNZ RestLoop
  DEC H
  JP NZ,RestStep
  RET

; The silent twin's entry: H = the length, the same loop as $803D without the
; speaker writes (never ran)
;
; Used by the routine at PlayTuneRest.
BeeperRest:
  LD H,A
  LD IXL,E
  LD L,D
  LD C,$10
  XOR A
  EX AF,AF'
  XOR A
  LD B,A
; This entry point is used by the routine at BeeperRestHead.
RestLoop:
  OR A
  AND A
; This entry point is used by the routine at BeeperRestHead.
RestStep:
  EX AF,AF'
  INC E
  NOP                     ; the engine's OUT ($FE),A as NOPs
  NOP
  NOP
  JR NZ,BeeperRestHead
  XOR C
  LD E,IXL
  EX AF,AF'
  INC D
  JP Z,RestTurnA
; This entry point is used by the routine at BeeperRestHead.
RestTurnB:
  NOP                     ; the engine's OUT ($FE),A as NOPs
  NOP
  NOP
  OR A
  AND A
  DJNZ RestLoop
  DEC H
  JP NZ,RestStep
  RET

; The two-voice beeper engine's code before its entry $803D: the first voice's
; reload path
;
; Part of the engine entered at $803D (A = the length in 256-loop units, D and
; E the two periods from $8062). The voices are counters counting up to 0: on
; its overflow a voice flips the speaker (XOR C, C = $10) and reloads; $802B is
; reached from $804D (JR NZ) when the first voice has not overflowed. c1: 451
; 581 runs.
BeeperToneHead:
  AND $FF

; The second voice's half of the PlayTwoTones loop (placed before the entry)
;
; Not called: the loop of PlayTwoTones ($803D) jumps here from $804D (JR NZ to
; $802B: the AND $FF there is the pad that equals the XOR C / LD E,IXL of the
; other branch) when voice 1's counter did not wrap. A' holds the speaker byte,
; C the speaker bit $10.
;
; INC D counts voice 2 up; on the wrap to 0 the speaker bit is output and
; toggled (Voice2Toggle), and D is reloaded from L (Voice2Reload); then the
; 256-step inner count B and the duration H as at $805B.
;
; The c1 and c128 L1 also list $802D-$8061 as entries from frame 1808: that is
; the loading-screen code (picy) that sat at these addresses during the load,
; not the game.
PlayTwoTonesVoice2:
  EX AF,AF'
  INC D
  JP NZ,TwoTonesNext

; Voice2Toggle
;
; Used by the routine at TwoTonesVoice1.
Voice2Toggle:
  OUT ($FE),A             ; voice 2 wrapped: output the current level, then
                          ; flip the speaker bit
  XOR C

; Voice2Reload
Voice2Reload:
  LD D,L                  ; D = voice 2's reload value; next step of the inner
                          ; count
  DJNZ TwoTonesStep
  DEC H                   ; the inner count done: one less unit of duration
  JP NZ,TwoTonesVoice1
  RET

; Play two square waves at once on the beeper for A units
;
; Input: A the duration (H: units of 256 loop steps), E voice 1's reload value,
; D voice 2's reload value (from NoteReloads $8062). Each voice counts its
; 8-bit counter up by one per loop step and toggles the speaker bit $10 (C)
; when it wraps to 0, then reloads it: the period is (256 - reload) steps. A
; holds voice 1's level, A' voice 2's; both are sent to port $FE every step,
; which mixes the two tones. The OR A / AND A / AND $FF pads make every path
; through the loop the same length.
;
; No border colour is kept (bits 0-2 of the OUT are 0). Called by the menu tune
; player at $7D4E (A = the note length from $7FEE, B and C the two note numbers
; looked up in NoteReloads); ran only in c1 and c128 (the warp runs start past
; the menu).
PlayTwoTones:
  LD H,A

; PlayTwoTonesSetUp
PlayTwoTonesSetUp:
  LD IXL,E                ; IXL = voice 1's reload, L = voice 2's reload, C =
                          ; the speaker bit, A = A' = 0, B = 0 (256 steps a
                          ; unit)
  LD L,D
  LD C,$10
  XOR A
  EX AF,AF'
  XOR A
  LD B,A

; TwoTonesStep
;
; Used by the routines at Voice2Reload and TwoTonesNext.
TwoTonesStep:
  OR A                    ; timing pad

; TwoTonesStepPad
TwoTonesStepPad:
  AND A                   ; timing pad

; TwoTonesVoice1
;
; Used by the routines at Voice2Reload and TwoTonesNext.
TwoTonesVoice1:
  EX AF,AF'               ; voice 1's step: count E up, output its level; no
                          ; wrap: voice 2's half at $802B
  INC E
  OUT ($FE),A
  JR NZ,BeeperToneHead
  XOR C                   ; voice 1 wrapped: toggle its level, reload E from
                          ; IXL
  LD E,IXL
  EX AF,AF'
  INC D                   ; voice 2: count D up; a wrap goes to Voice2Toggle
  JP Z,Voice2Toggle

; TwoTonesNext
;
; Used by the routine at PlayTwoTonesVoice2.
TwoTonesNext:
  OUT ($FE),A             ; output, pad, next of the 256 steps; then one less
                          ; unit of H
  OR A
  AND A
  DJNZ TwoTonesStep
  DEC H
  JP NZ,TwoTonesVoice1
  RET

; The counter reload of each note: 53 notes a semitone apart, lowest first
;
; PlayTwoTones counts from the reload value to 256, so the period of note n is
; 256 - NoteReloads[n] loop steps: 255, 240, 227, 215, 204, ... 13, 12.
; Successive periods differ by a factor 1.055-1.065 (a semitone is 1.0595):
; about four and a half octaves. Read by the tune player $7D4E (LD DE,$8062 and
; LD BC,$8062, index the note number).
;
; The c1 load ran code at $8063-$8096 at frame 1808 (the loading screen's
; depacker that lived here before the game was moved in); in the game these
; bytes are only read.
NoteReloads:
  DEFB $01,$10,$1D,$29,$34,$40,$4C,$54
  DEFB $5F,$69,$70,$78,$80,$87,$8E,$94
  DEFB $9A,$A0,$A5,$AA,$AF,$B4,$B8,$BC
  DEFB $C0,$C3,$C7,$CA,$CD,$D0,$D3,$D5
  DEFB $D8,$DA,$DC,$DE,$E0,$E2,$E4,$E5
  DEFB $E7,$E8,$E9,$EB,$EC,$ED,$EE,$EF
  DEFB $F0,$F1,$F2,$F3,$F4
