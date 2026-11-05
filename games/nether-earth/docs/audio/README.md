# Nether Earth: the sound, rendered

The menu tune and the sound effects as unreal-ng plays them: rendered from the machine state by the
emulator's own audio output. `python3 tools/render_audio.py` makes all of them (an own unreal-qt instance
on port base 19310, muted: nothing reaches the speakers). How the sounds work: [09-sound.md](../09-sound.md).

**The machine:** ZX Spectrum 48K (3.5 MHz, 69888 T a frame: 19.97 ms, 50.08 a second), RAM powered on as
zeros, a Kempston card. The game sounds only the beeper (port `$FE` bits 4 and 3); the capture takes the
beeper's own buffer, so nothing else in the mix can reach the files. unreal-ng's beeper with no punch.

**How:** the emulator runs in emulated frames (`run_frames`) while its audio capture
(`POST /api/v1/emulator/{id}/audio/capture` with `source: beeper`, then `/audio/capture/result?wav=true`)
takes the beeper's own buffer at 44.1 kHz. The capture holds at most 30 s, so it is re-armed every 1400
frames between two frames: the pieces join without a lost or doubled sample. The WAVs (`work/audio/`) are
cut, the DC blocked (a 3.5 Hz high-pass, the output capacitor of the machine), and encoded with lame: CBR
192 kbit/s, mono. No level change.

**The tune** is one pass from the frame its interrupt sends the bass track back to its start to the frame
it does so again, found in the machine (`BassReturnPos` `$FD54` falls back), then 5 s of the next pass
faded out. A pass takes 5192 frames (103.7 s), not the 5120 of `tools/tune_roll.py`, which counts one
interrupt a frame: 72 frames a pass have no `MenuInterrupt` step (likely interrupts missed while a drum
plays inside the handler; not traced). The "loop check" is the correlation of the loudness (20 ms RMS) of
6 s of the pass with the same 6 s one pass later: near 1 means the capture really repeats there.

**The effects** come from `tools/bot.py`'s game (the run of `work/docC/fight`: the menus' Beeps as the
bot builds and orders its first robot, the first shot and the first kill in play), and from `SoundFx`
set in a play snapshot for the whole sweep and the noises alone. Beeps of the same A sound the same
wherever they are called (09-sound.md 9.6): one file each, the other sites in the table. The `$FA` beep
(`CombatRefused`, `GameOverWait`, `LoadError`, 530 Hz) happens in no run here.

| File | What | Source routine | Length | How rendered |
| --- | --- | --- | --- | --- |
| [menu-tune.mp3](menu-tune.mp3) | the main menu tune: two pulse voices and the drums, one pass from its start | `MenuMusic` `$C4A7` (the tone loop `$C4C3`) and `MenuInterrupt` `$C4FD`; tracks: bass `$C678`, lead `$C702`, drums `$C665` / `$C66C` | 108.7 s (one pass 103.7 s + fade 5.0 s) | `work/play/start.szx` (tune frame 93) left alone; cut from frame 5099, where the bass track goes back to its start, to frame 10291, where it does again, plus the fade; loop check 0.988 |
| [sfx-cursor-click.mp3](sfx-cursor-click.mp3) | a click: a cursor or a list menu highlight moved | `CursorMoved` `$CB47` (also `ListMenuKey` `$AD17`, `DistanceShow` `$AAB3`): `Beep` `$CCAC`, A = `$14` | 0.10 s | bot.py: the first part chosen in the construction menu (the cursor moved up); frames 296-298 of the stage |
| [sfx-part-paid.mp3](sfx-part-paid.mp3) | a part paid for (a list menu item chosen sounds the same) | `PartPaid` `$CA91` (also `ListMenuChosen` `$AD37`): `Beep`, A = `$64` | 0.16 s | bot.py: the first part put on in the construction menu; frames 280-285 of the stage |
| [sfx-target-chosen.mp3](sfx-target-chosen.mp3) | a target chosen: the choice beep and the order beep back to back (LEAVE ROBOT sounds the same) | `ListMenuChosen` `$AD37` (`Beep` A = `$64`), then `OrderSet` `$ABF7` (`Beep` A = `$78`; `LeaveRobot` `$A803` after LEAVE ROBOT) | 0.34 s | bot.py: the first robot's order, its target chosen; frames 956-970 of the stage |
| [sfx-robot-start.mp3](sfx-robot-start.mp3) | START ROBOT: the rising chirp and the long low beep | `BuildChirp` `$CB83`: `Beep` A = `$50` down to `$14` by 5, then `LeaveConstructionMenu` `$CB90` A = `$C8` | 0.94 s | bot.py: START ROBOT of the first robot; frames 356-400 of the stage |
| [sfx-shot-hit.mp3](sfx-shot-hit.mp3) | a shot fired, then the hit that cuts it off | `SoundEffect` `$D5C4` from `PlayInterrupt` `$D566`: `SoundFx` `$FD53` 1 counting up (`FireShot` `$B6D6`), then `$FA` (`MoveShot` `$B724`) | 0.60 s | bot.py's game: the first shot in play; frames 18680-18707 of the stage |
| [sfx-kill-in-play.mp3](sfx-kill-in-play.mp3) | a robot destroyed in play | `SoundEffect`, `SoundFx` `$C8` (`MoveShotKill` `$B7D7`) | 1.16 s | bot.py's game: the first kill; frames 19314-19369 of the stage |
| [sfx-fire-sweep.mp3](sfx-fire-sweep.mp3) | a shot fired: the falling sweep, its full 126 frames | `SoundEffect`, `SoundFx` 1 to `$7F` | 2.58 s | `work/ill1/snaps/deep-3000.szx`, `SoundFx` set to 1; frames 10-136 of the stage |
| [sfx-miss.mp3](sfx-miss.mp3) | a shot ends on a wall, a building or nothing | `SoundEffect`, `SoundFx` `$FC` (noise, 3 frames; `ShotGone` `$B7EA`) | 0.12 s | the same, `SoundFx` = `$FC`; frames 150-153 of the stage |
| [sfx-hit.mp3](sfx-hit.mp3) | a robot hit, still alive | `SoundEffect`, `SoundFx` `$FA` (noise, 5 frames) | 0.16 s | the same, `SoundFx` = `$FA`; frames 170-175 of the stage |
| [sfx-kill.mp3](sfx-kill.mp3) | a robot destroyed (the explosion) | `SoundEffect`, `SoundFx` `$C8` (noise, 55 frames) | 1.16 s | the same, `SoundFx` = `$C8`; frames 190-245 of the stage |

Stages (`tools/render_audio.py --only STAGE`): `menu`, `play` (bot.py's game to frame 19400, under a
minute), `pokes`. `--encode-only` redoes the cuts from `work/audio/`.
