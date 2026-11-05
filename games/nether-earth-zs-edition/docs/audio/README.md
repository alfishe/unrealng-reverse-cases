# Nether Earth ZS Edition: the sound, rendered

The tunes and the sound effects of both releases as unreal-ng plays them, rendered from the machine by the
emulator's own audio output. Nothing was played aloud: the instance runs offscreen with its master muted, and the
capture reads the emulator's buffers. How the sounds work: [09-sound.md](../09-sound.md).

```
python3 tools/zsB_render_audio.py [--port-base 15430] [--only intro98,intro99,sfx99,pokes99] [--encode-only]
```

**The machine:** Pentagon 128 with TR-DOS (3.5 MHz, 71 680 T a frame: 20.48 ms, 48.83 frames a second), one AY-3-8910
in the AY socket (1.75 MHz, ABC stereo), a Kempston card. The capture machinery is advanced-nether-earth's
`tools/render_audio.py` (imported, not changed): `run_frames` in emulated frames while
`POST /api/v1/emulator/{id}/audio/capture` takes 44.1 kHz samples, re-armed every 1400 frames between two frames.
The WAVs (`work/zsB/audio/`) are cut, DC-blocked (3.5 Hz high-pass) and encoded with lame, CBR 192 kbit/s. No level
change.

**The tunes** are one pass from the point where the tune repeats, then 250 frames of the next pass faded out. The
pass lengths come from the players run on SkoolKit's simulator (`tools/zsB_ay_play.py`, 9.2 and 9.3), except the
'99 intro, whose pass in the running intro is 8 frames longer (9.3). "Loop check" is the correlation of the
loudness (20 ms RMS) of 6 s of the pass with the same 6 s one pass later; near 1 means the capture repeats there.

**The effects** come from two stages: `sfx99` (the '99 on HARD from `work/zsB/menu-hard/play.szx`, Nether Earth's
bot builds a bipod + cannon robot and orders it; the beeper's own buffer) and `pokes99` (the same snapshot with
`SoundFx` `$FD53` written by hand: an experiment; the game's interrupt plays what follows).

| File | What | Source routine | Length | How rendered |
| --- | --- | --- | --- | --- |
| [cool-winter.mp3](cool-winter.mp3) | "COOL WINTER" (KLIM/OHG/'97), the '98 intro tune, AY | `Pt3PlayEntry` `$C005` from `IntroInterrupt` `$DA0D`, module `Pt3Module` `$CE21` | 96.9 s (one pass 91.7 s + fade) | `intro98`: `NEZSED98.SCL`, `RUN "NEZSEd"` typed from `work/stage1/inputs/r98.txt`, the intro left alone; cut from the tune's onset + 323 frames (where its loop returns) for 4480 frames; loop check 0.942 |
| [menu-tune98.mp3](menu-tune98.mp3) | the '98 game menu tune, beeper, two voices and drums | `MenuMusic` `$C4A7` and `MenuInterrupt` `$C4FD` (`src/game98/music.asm`), started by the '98 main menu (`src/game98/mainmenu.asm`) | 111.5 s (one pass 106.3 s + fade) | `intro98` after SPACE: the game loads and its menu plays; cut from the onset for 5192 frames; loop check 0.876 |
| [intro-tune99.mp3](intro-tune99.mp3) | "SONG BY ST COMPILE", the '99 intro tune, AY | `Play` `$C00E` from `IM2Handler` `$6525`, module `$C4A8` | 146.8 s (one pass 141.7 s + fade) | `intro99`: `NEZSED.SCL` autostarted, the intro left alone; cut from the onset (frame 170) for 6920 frames; loop check 0.608 over 6 s, 0.987 over the first 3 s (9.3) |
| [sfx-cursor-click.mp3](sfx-cursor-click.mp3) | a click: a menu cursor moved | `Beep` `$CCAC`, A = `$14` (`CursorMoved` `$CB36`) | 0.06 s | `sfx99` frames 211-214 |
| [sfx-part-paid.mp3](sfx-part-paid.mp3) | a part paid in the construction menu | `Beep`, A = `$64` (`PartPaid` `$CA89`) | 0.12 s | `sfx99` frames 244-250 |
| [sfx-robot-start.mp3](sfx-robot-start.mp3) | START ROBOT: the rising chirp and the long low beep | `BuildChirp` `$CB82` (A = `$50` down to `$14` by 5), `LeaveConstructionMenu` `$CB8E` A = `$C8` | 0.90 s | `sfx99` frames 270-314 |
| [sfx-target-chosen.mp3](sfx-target-chosen.mp3) | a target chosen: the choice beep, then the order beep | `ListMenuChosen` `$AD2F` A = `$64`, `OrderSet` `$ABF5` A = `$78` | 0.29 s | `sfx99` frames 917-931 |
| [sfx-fire-sweep.mp3](sfx-fire-sweep.mp3) | a shot fired: the falling sweep | `SoundEffect` `$D5C4`, `SoundFx` 1 counted up to `$7F` | 2.62 s | `pokes99`, `SoundFx` = 1 at frame 10 |
| [sfx-miss.mp3](sfx-miss.mp3) | a shot ends on nothing | `SoundEffect`, `SoundFx` `$FC` (noise, 3 frames) | 0.10 s | `pokes99`, `SoundFx` = `$FC` at frame 160 |
| [sfx-hit.mp3](sfx-hit.mp3) | a robot hit | `SoundEffect`, `SoundFx` `$FA` (noise, 5 frames) | 0.14 s | `pokes99`, `SoundFx` = `$FA` at frame 190 |
| [sfx-kill.mp3](sfx-kill.mp3) | a robot destroyed | `SoundEffect`, `SoundFx` `$C8` (noise, 55 frames) | 1.17 s | `pokes99`, `SoundFx` = `$C8` at frame 220 |

The '98 game's effects are the same code at the same addresses ([09-sound.md](../09-sound.md), 9.6), so they are not
rendered twice. `--encode-only` redoes the cuts from `work/zsB/audio/`.
