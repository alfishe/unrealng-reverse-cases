# Advanced Nether Earth: the sound, rendered

Every tune and sound effect of the game as unreal-ng plays it: rendered from the machine state by the
emulator's own audio output, not from the module files. `python3 tools/render_audio.py` makes all of them
(about two minutes; an own unreal-qt instance on port base 19310, muted: nothing reaches the speakers).

**The machine:** Pentagon 128 with TR-DOS 5.04T, one AY-3-8910 (the AY DAC curve, not the YM2149's) at
1.75 MHz (the Pentagon's 3.5 MHz / 2), **ABC stereo** (A left, B centre, C right: the levels A 100/10,
B 66/66, C 10/100 percent left/right, unreal-ng's `STEREO.ABC`). No TurboSound, General Sound or MoonSound
in the slots. unreal-ng's AY tone voicing `flat` (no tone shaping), no punch, no room, no beeper punch;
the AY synthesized at its native rate (218.75 kHz) and decimated to 44.1 kHz.

**How:** the emulator runs in emulated frames (`run_frames`) while its audio capture
(`POST /api/v1/emulator/{id}/audio/capture`, then `/audio/capture/result?wav=true`) takes what it computes:
the post-mix master (AY + beeper) for the tunes, the beeper's own buffer for the effects. The capture holds
at most 30 s, so it is re-armed every 1400 frames between two frames: the pieces join without a lost or
doubled sample. The WAVs (`work/audio/`) are cut, the DC blocked (a 3.5 Hz high-pass, the output
capacitor of the machine), and encoded with lame: CBR 192 kbit/s, stereo for the AY, mono for the beeper.
No level change: the files keep the emulator's levels.

**A tune** starts at its first sound (the player's init silences the AY first) and runs the module's
first pass (its length from the players run on SkoolKit's simulator, `work/docR/ay/*.json`: the frame the
AY writes start to repeat; TAIGA loops back to its position 13, the others to the start), then 5.1 s of
the next pass faded out. The "loop check" is the correlation of the loudness (20 ms RMS) of 6 s at the
loop's start with the 6 s one period later: near 1 means the capture really repeats there. A frame is
71680 T = 20.48 ms (48.8 a second).

| File | What | Source routine / module | Length | How rendered |
| --- | --- | --- | --- | --- |
| [mad-night.mp3](mad-night.mp3) | MAD NIGHT (Syrus/EI, 15.02.98), the intro | New SoundTrack Player (PT2 compile player, Phantom Family) in bank 6, `src/music/intro-music.asm`, `src/res/music/mad-night.pt2`; played from IM 2 by `LoaderMain` `$6221` while the intro and the scroller run | 238.3 s (one pass 233.2 s + fade 5.1 s) | power-on, the SCL, `RUN "A_NETHER"` typed (`r1-help.txt`), the intro left alone; stereo ABC; master mix from frame 440 of the stage; loop check 1.000 |
| [tomy.mp3](tomy.mp3) | TOMY (X-Man, 08.12.96), the boot music: the boot menu and the help | PT3 player (Nick of GDC) in bank 1 (`d04`), module at `$CE21`, `src/music/boot-music.asm`, `src/res/music/tomy.pt3`; the boot program plays it each frame | 188.6 s (one pass 183.5 s + fade 5.1 s) | the same run: SPACE at the scroller, the boot menu left alone; stereo ABC; master mix from frame 13612 of the stage; loop check 0.999 |
| [taiga.mp3](taiga.mp3) | TAIGA (X-Man, 05.03.97), the game music: the game menu, the menus and play | New SoundTrack Player in bank 1 `$C000`, module `$CA45`, `src/music/music-bank1.asm`, `src/res/music/taiga.pt2`; `MusicInterrupt` `$6780` (menus) and `PlayMusic` `$67B1` (play) | 178.2 s (one pass 173.1 s + fade 5.1 s) | the same run: boot menu key 1, the game starter, the title cards, the game menu left alone; stereo ABC; master mix from frame 24605 of the stage; loop check 0.998 |
| [nether-earth-end.mp3](nether-earth-end.mp3) | NETHER EARTH (END) (Syrus/EI), Dead End: the lost game | New SoundTrack Player in bank 3 `$C000`, `src/music/dead-end-music.asm`, `src/res/music/nether-earth-end.pt2`; Dead End `$D2EF` | 20.8 s (one pass 15.7 s + fade 5.1 s) | `work/stage3/x0/deadend-start.szx` (the r3 recording's start: `PlayerBuildings` `$FD3A` poked to 0), no key; stereo ABC; master mix from frame 29 of the stage; loop check 0.999 |
| [rem.mp3](rem.mp3) | REM (X-Man, 17.10.96), Final Cut: the won game | PT3 player at `$DB00` in the Final Cut image, module `$E921`, `src/music/final-cut-music.asm`, `src/res/music/rem.pt3` | 267.3 s (one pass 262.1 s + fade 5.1 s) | `work/stage3/r4/finalcut-start.szx` (the r4 recording's start: `EnemyBuildings` `$FD42` poked to 0); stereo ABC; master mix from frame 64 of the stage; loop check 0.957 |
| [sample.mp3](sample.mp3) | the boot menu's key 3 ("NOT used"): a digitized sample, 4-bit, 11401 Hz | `PlaySample` in the boot program (`src/bootmenu/boot.asm`), 12790 bytes of bank 7 `$CE09` through AY registers 8-10, 307 T a sample, interrupts off (the tune stops) | 1.12 s | the flow run: boot menu key 3; cut from the first to the last volume write of the AY log (38391 writes); stereo ABC, master mix |
| [sfx-part-accepted.mp3](sfx-part-accepted.mp3) | construction menu: a part put on (paid) | `PartPaid` (`src/game/construction.asm`): `Beep`, A = `$64` | 0.18 s | the tour (`tools/fig_tour.py`): fire on BIPOD; the beeper's own buffer (mono), frames 1116-1122 of the stage |
| [sfx-part-refused.mp3](sfx-part-refused.mp3) | construction menu: a part refused or taken off | `PartRefused`: `Beep`, A = `$78` | 0.20 s | the tour: fire on NUCLEAR (20 > 13 left); the beeper's own buffer (mono), frames 1233-1240 of the stage |
| [sfx-cursor-click.mp3](sfx-cursor-click.mp3) | a click: a menu cursor, a menu item or the miles moved | `DistanceShow` (also `CursorMoved`, `ListMenuKey`): `Beep`, A = `$14` | 0.10 s | the tour: the distance menu, up; the beeper's own buffer (mono), frames 3976-3978 of the stage |
| [sfx-item-chosen.mp3](sfx-item-chosen.mp3) | a list menu item chosen | `ListMenuChosen` (`src/game/robotmenu.asm`): `Beep`, A = `$64` | 0.18 s | the tour: SEARCH & CAPTURE in the orders; the beeper's own buffer (mono), frames 2039-2045 of the stage |
| [sfx-order-given.mp3](sfx-order-given.mp3) | an order given, LEAVE ROBOT, direct control ended | `DistanceDone` (also `OrderSet`, `LeaveRobot`): `Beep`, A = `$78` | 0.20 s | the tour: fire on 20 MILES; the beeper's own buffer (mono), frames 4096-4103 of the stage |
| [sfx-robot-start.mp3](sfx-robot-start.mp3) | START ROBOT: the rising chirp and the long low beep | `BuildChirp`: `Beep` A = `$50` down to `$14` by 5, then `LeaveConstructionMenu` A = `$C8` | 0.98 s | the tour: START in the construction menu; the beeper's own buffer (mono), frames 1348-1393 of the stage |
| [sfx-cannon-shot.mp3](sfx-cannon-shot.mp3) | a cannon shot fired by our robot, to its end on nothing | `SoundEffect` (`src/game/interrupts.asm`) from `PlayInterrupt` `$D566`: `SoundFx` `$FD53` 1 counting up (the falling sweep), then `$FC` (the miss) | 1.33 s | the tour: COMBAT MODE, FIRE CANNON; the beeper's own buffer (mono), frames 3753-3815 of the stage |
| [sfx-fire-sweep.mp3](sfx-fire-sweep.mp3) | a shot fired: the falling sweep, its full 126 frames | `SoundEffect`, `SoundFx` 1 to `$7F` | 2.64 s | `x0/play.szx`, `SoundFx` `$FD53` set to 1; the beeper's own buffer (mono), frames 10-136 of the stage |
| [sfx-miss.mp3](sfx-miss.mp3) | a shot ends on a wall, a building or nothing | `SoundEffect`, `SoundFx` `$FC` (noise, 3 frames) | 0.12 s | `x0/play.szx`, `SoundFx` = `$FC`; the beeper's own buffer (mono), frames 160-163 of the stage |
| [sfx-hit.mp3](sfx-hit.mp3) | a robot hit, still alive | `SoundEffect`, `SoundFx` `$FA` (noise, 5 frames) | 0.16 s | `x0/play.szx`, `SoundFx` = `$FA`; the beeper's own buffer (mono), frames 190-195 of the stage |
| [sfx-kill.mp3](sfx-kill.mp3) | a robot destroyed (the explosion) | `SoundEffect`, `SoundFx` `$C8` (noise, 55 frames) | 1.19 s | `x0/play.szx`, `SoundFx` = `$C8`; the beeper's own buffer (mono), frames 220-275 of the stage |
| [construction-menu-in-play.mp3](construction-menu-in-play.mp3) | the construction menu as heard: TAIGA with the beeps of five parts and START | `ConstructionMenu` `$C849` (`MusicInterrupt` plays TAIGA), `Beep` | 7.3 s | the tour, master mix, frames 1100-1457; stereo ABC |

Stages (`tools/render_audio.py --only STAGE`): `flow` (power-on to the game menu: MAD NIGHT, TOMY, the
sample, TAIGA), `deadend`, `finalcut`, `sfx` and `sfxmix` (`tools/fig_tour.py`'s tour, beeper / master),
`pokes` (`SoundFx` set in `x0/play.szx`: an experiment that runs the game's own effect code; the hit and
the kill happen in no recording). `--encode-only` redoes the cuts from `work/audio/`.
