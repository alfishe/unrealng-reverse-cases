# 02. Capture

**Answers:** what runs, from the first instruction of the loader to play, and later every part of the game.

1. **From power-on, the load included** (the stages before the game are evidence too):

   ```bash
   cd $U && python3 tools/verification/analysis/re_session.py capture --work $C/work/c1 \
       --media $C/orig/GAME.TAP --model 48K --record-load --frames 30000 --port-base <yours>
   ```

   The machine starts with zeroed RAM; the recording starts before `LOAD ""`. Save it once
   (`work/c1/session.ttd`) and open it for every later question (`re_session.py open --ttd`). Note how the tape was
   loaded (fast load or at ROM speed): every frame number of the recording depends on it, and every document that
   gives a frame names the recording.
2. **The start image**: the memory at the game's entry (the frame and T-state the last loader stage jumps in),
   found by a binary search over frames with `memory_at` (recipe 03).
3. **Reach the game.** Random play and the demo reach the first screens. Read the game's own records (the
   player's position, the objects, the level) from memory each frame and steer from them: a bot
   (`hate/tools/autopilot.py` is the pattern). Record each run with the write journal on; keep the bot's log
   (frame, level, lives, score) and chart it (a chart script in the case's `tools/`, H.A.T.E.'s `tools/gamechart.py` the example).
4. **List what the recordings reached**: levels, modes, endings, high-score entry, every menu option. What none
   reached is written in the WALKTHROUGH as known only from the code, and reached later if possible (more bot runs,
   POKEs on a clone, input scripts).

**MCP:** take the control session first; `time_travel memory_at` for every read (any frame and T-state, no seek);
`time_travel explain_frame` to see what a frame did; `find_last` with the write journal for "who wrote this".

**Done when:** a power-on recording and recordings reaching each part of the game are saved, with their frames of
interest (entry, each level start, each mode) in a table in the WALKTHROUGH.
