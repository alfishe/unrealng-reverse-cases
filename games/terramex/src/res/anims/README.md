# Animations

The hero's frame lists, one list a line, each frame a sprite frame of the sprite space (`$00-$3F` the explorer's set,
`$40-$7E` the creatures, `$7F` blank), played one frame a main-loop pass by the status handlers (the status machine
`$5C06`, handlers at `$A72E`). Each list ends in `$FF`, except room-2e.txt (`$00`); teleport.txt has a byte the code
patches (the destination room, `$80 + room`), kept as on the tape.

| File | Address | Bytes | Readers | What |
| --- | --- | ---: | --- | --- |
| `deaths.txt` | FallDeathFrames `$A8BF` | 43 | FallDeath `$A888`, SilentDeath `$A8A8`, CreatureDeath `$A89E`, Room1ADeath `$A88F` | the four death lists: status 26 (the fall, frame `$1C`), 23 (the teleport pad of room `$20`, the radiation of room `$3C`, room `$39`'s creature; SilentDeathFrames `$A8C1`), 24 (a creature's touch, CreatureDeathFrames `$A8E0`), 25 (room `$1A`, Room1ADeathFrames `$A8E6`); status 18 `$A9EE` ends each death |
| `telescope.txt` | TelescopeFrames `$A79F` | 26 | LookIntoTelescope `$A822` (status 30) | looking into the telescope, before the countdown view |
| `room-2d.txt` | Room2DFrames `$A83B` | 22 | Room2DAnim `$A828` (status 28) | the frame list of room `$2D`, then the hero frozen |
| `room-43.txt` | Room43Frames `$A86E` | 26 | Room43Anim `$A851` (status 27) | the frame list of room `$43`, then item `$1D` in use and points |
| `teleport.txt` | TeleportFrames `$A955` | 10 | TeleportFrame `$A919`, TeleportJump `$A929` | the teleport |
| `sink.txt` | SinkFrames `$AA22` | 26 | SinkInMud `$AA04` (status 17) | sinking in the mud |
| `think.txt` | ThinkFrames `$ABEB` | 47 | Think `$AB6E` (statuses 10, 11, 12) | the T key: three lists |
| `refuse.txt` | RefuseFrames `$AECD` | 32 | RefuseShake `$A567` | the refusal of a drop of 5 rows or more (RefuseDrop `$A545`): the hero shakes his head |
| `room-2e.txt` | Room2EFrames `$B2D7` | 20 | Room2EStep1 `$B29C` | object 4's frames in room `$2E` after item 4 |
| `professor.txt` | ProfFrames `$B6C1` | 44 | ProfMode `$B62C` | the professor's 43 frames, `$FF` ends |
