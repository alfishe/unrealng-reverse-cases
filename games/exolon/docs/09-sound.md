# 9. Sound

What this covers:

- the two sound systems in one image: the beeper on the 48K, the AY-3-8912 on the 128K, and the flag that picks one;
- the beeper: the two-voice tune player, the two tunes, the noise and sweep effects;
- the AY: the three-channel title tune and its tick, the 16-slot effect engine and its 23 streams;
- what each sound sounds like, shown as rendered spectrograms and speaker plots (nothing here was played).

The recordings and renders it rests on:

- `c1` (the 48K reference run, no POKE): the title tune at the load (frames 12 390-12 800, cut by a key), GAME OVER.
- `c128` (the 128K tape load, 16 000 frames after load frame 12 200): the AY tune's tick counts.
- The 48K renders (an experiment, `tools/fig_sound.py render`): `work/snaps/entry.z80` on a live 48K instance, the
  six bytes at `$6DCB` patched per sound, unreal-ng's beeper output captured to `work/docs/docB/audio/*.wav`.
- The 128K renders (an experiment, `render-ay` and `render-sfx`): the instance `re_session.py capture --media
  build/Exolon.tzx --model 128K --load-frames 12200` leaves, its AY 1 output captured.
- The image itself for the tables and the models. The figures that rest on the image alone say so ("model").

Scope: when the effects are triggered in play is in [7. Objects](07-objects.md) and
[10. Gameplay logic](10-gameplay-logic.md); the main loop that ticks them is in [4. Game loop](04-game-loop.md).

## 9.1 One image, two sound systems

Start `$6D60` writes SoundIsAy `$6E16` once.
It is 0 on a 48K and non-zero on a 128K (`$DE` in the 128K rig).
The beeper routines (BeeperNoise, BeeperSweep, the debris crackle `$9597`) test it, and so do the callers of the
two title tunes (MainMenu `$6DC5`, DrawSparkle `$6F23`); PlayTune, TuneTick and SoundEffectsTick do not:

| Routine | Address | 48K | 128K |
| --- | --- | --- | --- |
| PlayTune (the beeper tunes) | `$7D17` | plays | plays (no test) |
| BeeperNoise | `$7C26` | plays | returns at once |
| BeeperSweep | `$7C3C` | plays | returns at once |
| The beeper title tune in MainMenu | `$6DCB` | plays at the first menu after each entry to Start (`c1`: 4 times) | skipped (`c128`: `$6DCB` never ran) |
| TuneTick (the AY title tune) | `$B767` | never called | every 4th star draw |
| SoundEffectsTick (the AY effects) | `$BF7E` | runs, its `OUT`s reach nothing | plays |

So the two machines hear different games:

- the 48K hears a 40-second two-voice title tune at the first menu after each load or GAME OVER, and short noise bursts in play;
- the 128K hears an 84-second three-channel title tune in every menu, and 11 shaped effects in play;
- both hear the jingle (GAME OVER, the ZORBA cheat): PlayTune has no SoundIsAy test.

The effect triggers are paired in the code.
FirePress `$835D` calls BeeperNoise (`$8368`, B `$3C`) and then PlaySfxShot (`$8372`).
On a 48K the first sounds and the second writes AY ports nobody listens to.
On a 128K the first returns at once and the second sounds.

## 9.2 The beeper engine: two square waves at once

PlayTwoTones `$803D` plays two notes together for a length.

The constants first:

- a voice is an 8-bit counter counted up by one each loop step; at its wrap to 0 the voice's speaker level flips
  (`XOR C`, C = `$10`, the speaker bit) and the counter reloads;
- the reload values come from NoteReloads `$8062` (53 entries, `$01` to `$F4`);
- a half-wave is (256 - reload) steps, so a full wave is 2 (256 - reload) steps;
- every path through the loop takes the same time: the `OR A` / `AND A` pads balance the branches;
- a length unit is 256 steps (B counts them, H counts the units).

```asm
PlayTwoTones:
  LD H,A                  ; the length in units of 256 steps
  LD IXL,E                ; voice 1's reload
  LD L,D                  ; voice 2's reload
  LD C,$10                ; the speaker bit
  ; ...
TwoTonesVoice1:
  EX AF,AF'               ; voice 1's step
  INC E
  OUT ($FE),A
  JR NZ,BeeperToneHead
  XOR C                   ; voice 1 wrapped: flip its level
  LD E,IXL
  ; ...
TwoTonesNext:
  OUT ($FE),A             ; output, pad, next of the 256 steps
  OR A
  AND A
  DJNZ TwoTonesStep
  DEC H
  JP NZ,TwoTonesVoice1
  RET
```

The algorithm:

```text
for unit in 1..length:
    repeat 256 times:
        counter1 += 1
        if counter1 wraps: level1 = not level1; counter1 = reload1
        counter2 += 1
        if counter2 wraps: level2 = not level2; counter2 = reload2
        output level1, then level2, to the speaker (the two OUTs mix the voices)
```

The step time: 96 T-states.
The witness is the render: TitleTune's 195 notes sum to 5706 units; the speaker moves for 40.09 s.
40.09 s x 3 500 000 / (5706 x 256) = 96.06 T a step. The game runs with interrupts off, so none of the 0.06 is
interrupt time: it is PlayTune's work between the notes and, likely, the ULA's contention of the `OUT ($FE)`s.
The code sits at `$803D`-`$8061`, above `$8000`, so no memory contention stretches it.

A worked example, the first note of TitleTune (`$7DA3`: `12 13 2B`):

- length `$12` = 18 units = 18 x 256 x 96 T = 442 368 T = 126 ms;
- note `$13` = 19: NoteReloads[19] = `$AA` = 170; a full wave is 2 x (256 - 170) x 96 = 16 512 T: 212.0 Hz;
- note `$2B` = 43: NoteReloads[43] = `$EB` = 235; 2 x 21 x 96 = 4032 T: 868.1 Hz;
- the render's spectrum of that note has its peaks at 206.8-216.2 Hz and 864.9-874.3 Hz (a 4096-point FFT, 10.8 Hz
  bins).

PlayTune `$7D17` feeds it three bytes a note:

```asm
PlayTune:
  XOR A
  IN A,($FE)              ; wait until no key is down
  CPL
  AND $1F
  JR NZ,PlayTune
  LD (TunePointer),HL
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
  ; ...
```

```text
wait for no key
for each note (length, n1, n2) from the tune until length = 0:
    if any key is down: stop
    if n1 = n2 = 0: silence for length units      (never in either tune)
    else: PlayTwoTones(NoteReloads[n1], NoteReloads[n2], length)
```

## 9.3 Beeper tunes on 48K

There are two tunes:

| Tune | Address | Notes | Units | Length | Callers |
| --- | --- | --- | --- | --- | --- |
| TitleTune | `$7DA3` | 195 | 5706 | 40.07 s (model), 40.09 s (render) | MainMenu `$6DCB`, 48K only, once after each entry to Start (TitleTunePending `$7D67`) |
| JingleTune | `$7D68` | 19 | 315 | 2.21 s (model and render) | ZorbaCheat `$7055`, GAME OVER `$A030`, both machines |

TitleTune uses 19 note numbers, from 7 (106 Hz, G#2) to 50 (1302 Hz, E6).
Voice 1 plays the bass (106-320 Hz), voice 2 the melody (mostly 500-1302 Hz; 16 of its 195 notes are lower,
down to 212 Hz).

![The 48K tunes are two square waves at once: every model note lies on the rendered spectrum](img/sound/beeper-tunes.png)

```sh
python3 tools/fig_sound.py render --work work/docs/docB/i48     # the WAVs (a live 48K instance, muted)
python3 tools/fig_sound.py beeptunes
```

How to read:

- Background: the spectrogram of the render, 60-4000 Hz on a log scale, bright = loud.
- Cyan lines: voice 1 of the model (`beeper_notes`: the tune bytes, NoteReloads, 96 T a step); green: voice 2.
- Top: TitleTune from its first note, 40 s. Bottom: JingleTune, 2.2 s, with a finer time step.
- The fainter bands above each line are the square waves' odd harmonics (3 f, 5 f).

What it shows:

- Every model line sits on a bright band of the render: the note table and the wave formula are right.
- The model's lengths end where the render goes quiet: the 96 T step holds over 40 s.
- The jingle's voice 1 stays at 268-357 Hz, voice 2 at 536-1072 Hz; it sounds the same on both machines.

The routine at work, eight frames of PlayTwoTones in `c1`:

![PlayTune in c1: PlayTwoTones counts both voices for the length](img/routines/PlayTune.gif)

```sh
python3 ../../kit/routine_anim.py --work work/docs/docB/c1 --window 12420:0-12428:0 --listing build/game.lst \
    --out docs/img/routines/PlayTune.gif --view none --range 7D00-80FF --pc 7D17-8061 --pictures 40 --delay 150 \
    --title 'PlayTune $7D17: three bytes a note, then PlayTwoTones $803D counts both voices for the length, c1 frames 12420-12428'
```

How to read:

- Right: the listing around the PC of each slice (13 978 T a slice), with the instructions run in it lit.
- Top left: memory `$7D00`-`$80FF`, 256 bytes a row; green = executed, blue = read.
- The trace holds 81 752 instructions in 8 frames and 11 638 port accesses: one `OUT` every 48 T.

What it shows:

- The CPU does nothing else while a tune plays: the menu waits for it.
- The tune bytes are read once a note: 10 memory reads in 8 frames.

## 9.4 Beeper effects

BeeperNoise `$7C26` makes a noise burst of B rounds:

```asm
BeeperNoise:
  LD A,(SoundIsAy)
  OR A
  RET NZ                  ; nothing on a 128K
BeeperNoiseLoop:
  LD A,R
  AND $F8                 ; speaker and MIC bits random, border 0
  OUT ($FE),A
  LD E,B
  INC E
BeeperNoiseWait:
  DEC E
  JR NZ,BeeperNoiseWait
  XOR A
  OUT ($FE),A
  DJNZ BeeperNoiseLoop
  RET
```

```text
for b = B down to 1:
    speaker = a random level (the refresh register R)
    wait b + 1 short loops (16 T each)
    speaker = 0
```

So each round is one loop shorter than the last: the pulses shrink and rise in pitch as the burst ends.
A round costs about 74 + 16 b T-states uncontended.
The code sits at `$7C26`, in contended memory: the render of B `$C8` takes 119.5 ms against 96 ms uncontended.

BeeperSweep `$7C3C` is a falling tone: 16 steps of 10 half-waves, the half-wave E loops long, E from `$30` to `$3F`.

The callers and their B:

| Caller | Address | B | Rounds | Rendered |
| --- | --- | --- | --- | --- |
| DefineKeys' key click | `$7029` | `$C8` | 200 | 119.5 ms |
| FirePress (the laser fired) | `$8368` | `$3C` | 60 | 8.7 ms |
| ShotHitNoise (a shot meets a thing) | `$844E` | `$14`, 20 times | 20 x 20 | 34.3 ms |
| FireShellNoise (a turret fires) | `$9096` | `$1E`, 10 times | 10 x 30 | 33.6 ms |
| PayBonusTick (one bonus tick paid) | `$9EC1` | `$28` | 40 | 4.3 ms |
| RunBlasts (each blast, each pass) | `$9FBD` | random 1-32 | 1-32 | not rendered |
| ZoneEndBravery (80 x 125 points) | `$A855` | `$3C`, 80 times | 80 x 60 | 974 ms (without AddScore's time) |
| Pods (a pod taken) | `$9996`, `$99EC` | BeeperSweep, 5 times | 5 x 16 x 10 half-waves | 43.0 ms one sweep (the render played one) |
| NoiseShort | `$7C24` | `$37` | no caller | none |

![The 48K effects: BeeperNoise is B pulses of random level, each one loop shorter](img/sound/beeper-effects.png)

```sh
python3 tools/fig_sound.py beepfx
```

How to read:

- One panel a render: the speaker level (filled = high) against ms from the first change. Each panel has its own
  time scale.
- The title of each panel: the caller, B, and how long the speaker moved.
- A round whose random level is low leaves no mark, so a burst shows fewer pulses than rounds.

What it shows:

- The single bursts (bonus tick, fire) last a few ms: clicks, not tones.
- The repeated calls make a rattle: twenty or ten bursts back to back, 34 ms in all.
- BeeperSweep's pulses widen step by step: its pitch falls.
- ZoneEndBravery's 80 bursts last a second; in the game AddScore runs between them, so it is longer.

The renders patch the code: an experiment, not a recording.
The six bytes `LD HL,TitleTune / CALL PlayTune` at `$6DCB` became `CALL $7DA3`, and a stub over TitleTune's data
called BeeperNoise R times with B (or BeeperSweep once).
The routines themselves are the game's.

## 9.5 The AY title tune

The 128K's menu plays a tune on the AY's three channels.
MainMenu calls TuneStart `$B6EC` on each entry (117 calls in the runs).
DrawSparkle `$6F1F`, the menu star's draw, calls TuneTick `$B767` every fourth draw on a 128K (`c128`: 42 219
draws, 10 554 ticks).
So the tune's tempo is the pace of the star draws, not a clock.

The streams:

| Channel | Stream | Record | Notes | Ticks to its `$FF` |
| --- | --- | --- | --- | --- |
| A | TuneStreamA `$BA01` | `$BE7D` | 340 | 6560 |
| B | TuneStreamB `$BB7E` | `$BECD` | 364 (48 of them on noise) | 6560 |
| C | TuneStreamC `$BD06` | `$BF1D` | 90 | 6480 |

The constants first:

- the AY clock is 1 773 400 Hz; a tone period P gives 1 773 400 / (16 P) Hz;
- a note n takes its period from the word at NotePeriodsTune `$C71B` + 2 n, which is entry 24 of the effects'
  NotePeriods `$C6EB`: the tune lies two octaves above the effects' notes;
- a channel record is 80 bytes: +0/+1 the period, +2 the ticks left of the note, +3 the volume, +6/+7 the AY
  registers, +8 the ceiling, +`$0A` the note length, +`$19`-`$1F` the pitch envelope, +`$35` on the volume envelope.

The codes TuneReadCode `$B89D` reads:

| Code | Meaning | In the streams |
| --- | --- | --- |
| `$00`-`$31` | a note of the current length (note 0 is a real period too) | yes |
| `$32`-`$63` n | the length = n, then the note code - `$32` | yes |
| `$64` | the mixer: XOR the channel's tone and noise bits (A `$09`, B `$12`, C `$24`) | yes |
| `$65`-`$74` | the volume ceiling = code - `$65` | no |
| `$75` lo hi / `$76` | call a stream / return | yes |
| `$77` n, `$78` lo hi | transpose, jump | no |
| `$79` n | the noise period = n | yes |
| `$89` n ..., `$8A` n ... | a pitch envelope, a volume envelope of n bytes | `$8A` only |
| `$FF` | the tune's end: the first channel to reach it stops all three (TuneEnd `$B9F7`) | yes |

```asm
TuneTick:
  XOR A
  LD (TuneStreamRead),A
  LD A,(TuneStopped)
  OR A
  JR NZ,TuneTickDone
  LD IX,TuneChannels
  LD IY,(TunePointerA)
  CALL TuneChannelStep
  LD (TunePointerA),IY
  ; ... the same for B ($BECD) and C ($BF1D)
```

```text
tick:
    if the tune is stopped: return
    for channel in A, B, C:
        if the channel's note has ticks left: count one down, step its envelopes
        else: read its stream up to the next note (only one channel reads in a tick;
              another one that wants to read waits for the next tick)
```

The one-read-a-tick rule is TuneStreamRead `$B6E1`: a channel finding it set marks its record +`$0D` and reads at
the next tick.
Two channels starting a note on the same model tick are read one tick apart.

![The 128K title tune: three channels of notes, 794 notes, no loop (model of the streams)](img/sound/ay-tune.png)

```sh
python3 tools/fig_sound.py aytune
```

How to read:

- One panel a channel; x is the tick, y the note on an octave grid, from the period.
- Orange bars on B: notes played on the noise generator, drawn at their noise period (31 or 15), not at a pitch.
- The dashed line: tick 6480, where C reaches its `$FF` and TuneEnd stops all three.

What it shows:

- B opens with the drums (48 noise notes) under a bass line; A carries the melody, C a slow middle voice.
- The tune does not loop: A and B have 80 ticks left when C ends it.

### The tune as rendered

The render left the 128K rig's machine alone for 7000 frames with AY 1 captured.
The machine was in play after the capture; GAME OVER came at about frame 1790 and MainMenu at frame 2510.
`render-ay` read TuneStopped `$B6E4` and the three stream pointers every frame.
A note's read frame is the first frame whose pointer equals the address after the note's code.

![The 128K title tune as rendered: all 794 model notes found in order, 1.54 ticks a frame](img/sound/ay-tune-measured.png)

```sh
python3 tools/fig_sound.py render-ay --work work/docs/docB/r128
python3 tools/fig_sound.py aymeasured
```

How to read:

- Top: seconds 60-75 of the capture as a spectrogram, with the model's tone notes drawn at their measured read
  frames (A green, B blue, C yellow).
- Middle: each note's read frame against its model tick; the dashed line is the fit; the grey line is the frame
  where TuneStopped became `$FF`.
- Bottom: each note's distance from the fit, in frames.

What it shows:

- The model's 794 notes were all found in order: the code table above covers this tune.
- The tick rate is steady at 1.544 ticks a frame (6.2 star draws a frame): 6480 ticks take 4196 frames, 83.9 s.
- No note is more than 2.6 frames off the line. The bands in the bottom panel come from the one-read-a-tick rule.
- TuneStopped became `$FF` at frame 6716, 2 frames after the fit puts tick 6480.

## 9.6 The AY effects

SoundEffectsTick `$BF7E` runs three times a main loop pass (`$75C5`, `$7601`, `$766B`; 237 645 times each in the
runs).
It walks 16 slots of 16 bytes at SfxSlots `$C5EB`.

The constants first:

- a slot: +0 `$FF` free / 0 active, +1/+2 the stream pointer, +3 the note's ticks left, +4 the volume, +5 the start
  volume, +6/+7 the decay counter and its reload, +8 the decay step, +9/+`$0A` the period, +`$0B` the mixer mask
  (0 tone and noise, 7 noise only, `$38` tone only), +`$0C` the note length;
- the first three active slots, in slot order, get channels A, B and C; a fourth and later run unheard;
- each starter puts its effect in a fixed slot, so a new shot restarts the old shot instead of taking a channel.

```asm
SoundEffectsTick:
  XOR A
  LD (SfxChannelIndex),A
  LD A,$BF
  LD (SfxMixer),A         ; all tones and noises off
  LD A,$F6
  LD (SfxChannelBits),A
  LD IX,SfxSlots
  LD B,$10
SoundEffectsSlot:
  PUSH IX
  PUSH BC
  LD A,(IX+$00)
  CP $FF
  JR Z,SoundEffectsNext
  CALL SfxSlotStep
  LD HL,SfxChannelBits
  RLC (HL)
  ; ...
```

```text
tick:
    mixer = all off; next channel = A
    for slot in 0..15:
        if the slot is active:
            note ticks -= 1; if 0: read the stream up to the next note
            decay counter -= 1; if 0: reload it, volume -= step
            if a channel is left: write period, volume and mixer bits to it
    write the noise period (register 6) and the mixer (register 7)
```

The stream codes SfxReadStream `$BFE1` reads:

| Code | Meaning |
| --- | --- |
| `$FF` | the end: the slot is freed |
| `$FE` n | the start volume = n |
| `$FD` p s | the decay reload p, the step s (only in the streams of the starters with no caller) |
| `$FC` m | the mixer mask = m |
| `$FB` n | the noise period = n, and n is also the note that follows |
| `$00`-`$5F` | a note of the slot's length: the period from NotePeriods `$C6EB` |
| `$60`-`$FA` n | the note code - `$60`, then the length n |

StartSoundEffect `$C1D3` sets a slot: A the slot, BC the stream; volume 15, length 1, tone only, the first read at the
next tick.

A worked example, ShotSound `$C5A1` (PlaySfxShot, slot 15):

- the bytes: `FC 00  FE 0D  FB 0F  74 01  FE 0B 14  FE 09 14  FE 07 14  FE 03 74 03  FE 02 14  FF`;
- tick 1: mixer mask 0 (tone and noise), volume 13, noise period 15 and note 15: period `$0647`, 69 Hz, 1 tick;
- tick 2: `74 01`: note `$14` = 20, period `$04B4`, 92 Hz, length 1;
- ticks 3-5: note 20 again at volumes 11, 9, 7;
- ticks 6-8: volume 3, note 20 for 3 ticks; ticks 9-11: volume 2, note 20 (the length is still 3); then `$FF`;
- 11 ticks at three a pass are about 3.7 passes, 7 frames (0.15 s): a low thud in noise. The render is loud for
  0.15 s.

The starters that ran and their triggers:

| Starter | Address | Slot | Called by |
| --- | --- | --- | --- |
| PlaySfxShot | `$C177` | 15 | FirePress `$8372` (2625 calls) |
| PlaySfxNoiseBurst | `$C0E7` | 13 | MoveShots `$8417` (419 calls), `$8408` (`c128`: 108 runs) |
| PlaySfxBlast | `$C148` | 6 | FireShell `$909F`, `$91A9`, GrenadeBlast `$9427`; ForceFieldDestroy `$AC51` never ran |
| PlaySfxExplosion | `$C155` | 8 | `$9B79`, `$9BD0`, `$9E5B`, `$9E7F`, `$A63C` (a thing shot) |
| PlaySfxGrenade | `$C1BE` | 9, 15 | ThrowGrenade `$9254` |
| PlaySfxNoiseSweep | `$C13B` | 7 | Guns `$9DBB` |
| PlaySfxTrill | `$C12E` | 5 | `$9EAF`, PickupsVsPlayer `$A32B` (156 calls) |
| PlaySfxAmmoRefill | `$C0F4` | 2 | `$9980`, `$9F65` |
| PlaySfxGrenadeRefill | `$C101` | 2 | `$99D6` |
| PlaySfxPulse | `$C162` | 13 | Teleports `$98F3`, `$9928` (38 and 8 calls) |
| PlaySfxHum | `$C1A9` | 1, 11 | ForceFieldStep `$ABD6` (9349 calls) |

Six starters have no caller and never ran: PlaySfxJingleA `$C10E`, PlaySfxJingleB `$C116`, PlaySfxWobble
`$C126`, PlaySfxRise `$C16F`, PlaySfxChord `$C17F`, PlaySfxFanfare `$C195`.
Their streams are the only ones with `$FD`.

![The 11 AY effects the game starts, rendered one by one, each with its caller](img/sound/ay-effects.png)

![The 6 AY effect starters no code calls, rendered the same way](img/sound/ay-effects-orphans.png)

```sh
python3 tools/fig_sound.py render-sfx --work work/docs/docB/r128
python3 tools/fig_sound.py ayfx     # both figures
```

How to read:

- First figure: the 11 effects with a caller; second figure: the 6 starters without one.
- One spectrogram an effect, 40-8000 Hz on a log scale, from its start; the title gives the starter, the time the
  render was loud and the trigger.
- The render is an experiment: the rig ran to MainMenu (frame 2520), `$6DC9` became `JP $803D`, and a stub there
  ran DI, AySilence `$B753`, the starter, then SoundEffectsTick and a 1680-loop delay forever (about 46 000 T a
  tick, a third of doc 04's median pass of 138 347 T). The stub's ticks are even; in the game the three ticks of a
  pass are uneven.

What it shows:

- Shot, noise burst, explosion and blast are noise with a falling tone under it, 0.1-0.6 s.
- The grenade throw is sweeps falling together over 0.9 s.
- The refills are a falling three-note arpeggio repeated as it fades; the trill is one note pulsing for 2.7 s.
- The hum is two low notes; ForceFieldStep restarts it every pass while the field is on, so in play it lasts.
- The six orphan effects play: they are tune phrases (jingles, a fanfare, a chord) left from the engine's earlier use.

## 9.7 What is known only from the code

- The rest in PlayTune (both note numbers 0): neither tune has one.
- NoiseShort `$7C24` (B `$37`): no caller.
- The AY tune codes `$65`-`$74`, `$77`, `$78`, `$89` and TuneBadCode: never in the streams.
- The effect code `$FD`: only the six orphan starters use it, and only the stub rendered them.
- The channel quirk of SoundEffectsTick (a slot that ends in a tick still rotates the channel bits): no figure
  shows it.
- RunBlasts' random bursts were not rendered.
