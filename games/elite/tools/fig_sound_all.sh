#!/bin/bash
# The still figures of docs/09-sound.md (docs/img/sound/*.png) from the access traces of w1, f1 and k2
# (the k2 traces: work/trace_k2snd.sh). The animations are tools/fig_sound_anim.py.
cd "$(dirname "$0")/.."
python3 tools/fig_sound.py docs/img/sound/effects.png \
  --title "Every beeper effect the recordings reached: the scene sounds are slow pulse trains read from the ROM, the fight's are one-frame sweeps and noise" \
  "work/w1/traces/2100_0-2200_0.uatr:2100-2133:w1 2100, the jump (SoundJump, interrupts off)" \
  "work/w1/traces/4280_0-4380_0.uatr:4314-4361:w1 4314, the launch whistle after Game Over (SoundLaunch, interrupts off)" \
  "work/w1/traces/4280_0-4380_0.uatr:4303-4313:w1 4303, Game Over: SoundGameOver's phase, then the explosion request" \
  "work/w1/traces/3470_0-3620_0.uatr:3476-3481:w1 3477, one pulse laser shot (request bit 4, 2 sweep passes)" \
  "work/w1/traces/4280_0-4380_0.uatr:4285-4289:w1 4286, the player hit (request bit 6, noise)" \
  "work/f1/traces/1820_0-1920_0.uatr:1820-1824:f1 1821, the click (ROM BEEPER, HL 128, DE 96)"
python3 tools/fig_sound.py docs/img/sound/effects-k2.png \
  --title "The four effects only k2 reached: the missile and the bomb slide pass by pass, the E.C.M. warbles, a ship hit is noise" \
  "work/k2/traces/2540_0-2600_0.uatr:2540-2572:k2 2542, the missile launch (request bit 1, 8 pulse passes, step \$E4)" \
  "work/k2/traces/2540_0-2600_0.uatr:2573-2600:k2 2573, a Thargoid's E.C.M. (request bit 5, 8 sweep passes, step \$D3)" \
  "work/k2/traces/3185_0-3200_0.uatr:3185-3189:k2 3187, a ship hit by the laser (request bit 3, ROM noise from \$031A)" \
  "work/k2/traces/3302_0-3335_0.uatr:3304-3335:k2 3305, the energy bomb (request bit 0, 8 pulse passes, step \$FE)"
python3 tools/fig_sound.py docs/img/sound/spectrogram.png --spectrogram \
  --title "The effects as spectrograms: the laser is one tone with its odd harmonics, the pulse trains spread over many lines" \
  "work/w1/traces/2100_0-2200_0.uatr:2100-2133:w1 2100, the jump (SoundJump)" \
  "work/w1/traces/4280_0-4380_0.uatr:4314-4361:w1 4314, the launch whistle (SoundLaunch)" \
  "work/w1/traces/3470_0-3620_0.uatr:3476-3481:w1 3477, one pulse laser shot (request bit 4)" \
  "work/k2/traces/2540_0-2600_0.uatr:2540-2572:k2 2542, the missile launch (request bit 1)" \
  "work/w1/traces/4280_0-4380_0.uatr:4285-4289:w1 4286, the player hit (request bit 6, ROM noise)"
python3 tools/fig_sound.py docs/img/sound/timeline-fight.png --timeline work/w1/traces/3470_0-3620_0.uatr:3470-3619 \
  --title "The fight (w1 3470-3620): each laser shot is a 2.8-frame sweep inside the interrupt; the main loop and the next interrupt wait"
python3 tools/fig_sound.py docs/img/sound/timeline-death.png --timeline work/w1/traces/4280_0-4380_0.uatr:4280-4379 \
  --title "The death (w1 4280-4380): hits and a laser shot played from the interrupt, then Game Over's sounds hold the CPU for 58 frames"
# the animations (drawn, never played): the screen, the speaker bit scrolling, the pitch track, frame by frame
A="python3 tools/fig_sound_anim.py"
$A work/w1/traces/3470_0-3620_0.uatr:3476-3481 docs/img/sound/laser.gif --pictures 30 \
  --title "One pulse laser shot (w1 3477): SoundSweep plays two bursts near 530 Hz a frame apart, inside the interrupt"
$A work/f1/traces/960_0-1060_0.uatr:960-998 docs/img/sound/launch.gif --pictures 39 \
  --title "The launch from Lave (f1 960-998; the trace starts 9 frames after the key): SoundLaunch's whistle with the interrupts off; the screen stays on the chart, the tunnel only follows at 998"
$A work/w1/traces/2100_0-2200_0.uatr:2100-2133 docs/img/sound/jump.gif --pictures 34 \
  --title "The hyperspace jump (w1 2100-2133): SoundJump's pulse train with the interrupts off, the screen frozen until it ends"
$A work/w1/traces/4280_0-4380_0.uatr:4303-4361 docs/img/sound/gameover.gif --pictures 59 \
  --title "Game Over (w1 4303-4361): SoundGameOver's phase, the explosion, then the launch whistle; the main code plays, so the screen never changes"
$A work/k2/traces/2540_0-2600_0.uatr:2573-2600 docs/img/sound/ecm.gif --pictures 28 \
  --title "A Thargoid's E.C.M. (k2 2573-2600): one sweep pass, then HitFlash (our missile, blown up at 2572) holds DI and ten interrupts are lost; the sweep resumes at 2584"
$A work/k2/traces/2540_0-2600_0.uatr:2540-2572 docs/img/sound/missile.gif --pictures 33 \
  --title "The missile launch (k2 2542): eight pulse passes climbing to 11.7 kHz, falling to 560 Hz when D wraps, then climbing again"
