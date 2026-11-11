# 1. Game design

What this covers: the game as a player meets it.

- the premise and the goal: find Professor Eyestrain and bring him what he wants;
- every screen: the loading screen, the device menu, the explorer selector and Help, play and its panel, the lab,
  the space scene, the end;
- the five explorers;
- the eight kinds of creature;
- the controls;
- the rules as the game plays them: lives, the 30-day countdown, the score;
- the items and the professor's six wishes;
- the 72 rooms: the map, and every room on a contact sheet;
- a walkthrough of the RZX run's route;
- the end of a game, lost or won.

The recordings it rests on ([WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings)):

| Recording | Load | Used for |
| --- | --- | --- |
| `c1` | power-on, the original tape at ROM speed on the 128K | the load, the device menu, the selector, Herr Krusche in room `$14` |
| `explorers` | the menu after a ROM-speed 128K load | all five explorers, the menu, the selector, Help, the start room |
| `gameover` | the RZX state at 10000 with Lives `$5B97` poked to 1 (a POKE) | the last life lost, the space scene, the menu again |
| `rzx50000` and the other `rzxNNNNN` | the RZX archive's run (Bobby Lequay's game, recorded in Spectaculator), replayed in segments | the lab, the ending |
| the RZX dump | the RZX played in SkoolKit's simulator by `tools/rzx_dump.py` (no emulator instance), the variables every 25 frames (`work/docs/tmA/rzx25`) | the route, the score, the lives and the countdown of the whole run |

The route and the walkthrough are another player's game. Their frames are "RZX frames", counted from the RZX's start.

## 1.1 The game in one page

Terramex (Grandslam, 1987; written by Teque: Shaun Hollingworth and Pete Harrap, 128K music by Ben Daglish) is a
flip-screen arcade adventure.

The story, from the selector's Help pages (`src/res/texts/help-page1.txt`, `help-page2.txt`):

- Twenty years ago Professor Albert Eyestrain warned that a gigantic asteroid would hit the Earth. Nobody believed
  him, and he vanished.
- Now the asteroid will hit within a month. The professor said he might be able to solve the crisis when the time
  came.
- "Your job then is to find him and convince him to save the world."
- You are one of five explorers, in a desert mountain range "where strange creatures live, and where things do not
  behave normally".

How it plays:

- **Find him.** The professor sits in his lab, room `$3B`, deep in the mountain. The way there runs through 57 of the
  72 rooms in the RZX run.
- **Convince him.** He wants six things, one at a time, in a fixed order (WantedItems `$B6BB`): the Formula, a Coat
  Hanger, a Battery, the Atomic Pile, a Button and a Cup of tea. Each wish shows in his speech bubble.
- **In time.** A countdown of 30 days, 23 hours and 59 minutes runs from the start. When it runs out, the asteroid
  strikes.
- **With help.** Invisible bearers carry what the explorer is not holding. Only the item in the hand can be used.

```mermaid
flowchart LR
    A["the menu: choose the device"] --> B["the selector: choose an explorer"]
    B --> C["room $14: explore, collect, solve"]
    C --> D["the lab $3B: give the six wishes in order"]
    D --> E["room $28: the deflector turns the asteroid away"]
    C -->|"4 lives lost or the countdown at 0"| F["room $28: the asteroid strikes"]
    E --> G["the menu, the high score"]
    F --> G
```

**The point**: Terramex is a collecting game on a timer. Most of the map serves to gather the right items, and the
end is one room, the lab, where they are handed over in order.

## 1.2 The screens

![The screens of Terramex](img/design/screens.png)

*Nine screens of the 128K version, from the screenshots in `docs/img/play/` ([WALKTHROUGH](../WALKTHROUGH.md)):
the loading screen (the tape's block 3), the menu (`explorers` frame 7750), the selector (`explorers` 250), Help's
title (`explorers` 13 750), play in room `$14` (`explorers` 750), the space scene (`gameover` 1700), the lab
(`rzx48000` 1999), the ending (`rzx50000` 500) and Help, page 1: the story (`explorers` 15 000). Made with `python3 tools/fig_design.py screens
docs/img/design/screens.png`.*

How to read it, in the order a player meets them:

- **The loading screen** (block 3 of the tape): the title art, shown for the six minutes the rest of the tape loads.
- **The device menu**: 1 KEYBOARD, 2 KEMPSTON, 3 SINCLAIR, 0 START GAME, the credits underneath. The menu redraws its
  frame from the saved panel.
- **The selector** (128K only, before every game): the five explorers' faces and a Help box. A hand cursor moves over
  them; FIRE chooses.
- **Help**: a title ("TERRAMEX INSTRUCTIONS") and three pages: the story on pages 1 and 2, the instructions and the controls on page 3.
  SPACE turns the page; ENTER goes back to the selector.
- **Play**: the room above, 256 x 128 pixels, and the panel below.
- **The space scene**: room `$28`, the end of every game.
- **The lab** `$3B`: the professor and his speech bubble.

| Screen | Where in the code | Recording, frame |
| --- | --- | --- |
| the loading screen | block 3 of the tape, `$4000` | `c1` 2600 |
| the device menu | DeviceMenu `$93AF` | `explorers` 7750 |
| the selector | SelectorEntry `$C0D2`, RAM 1 | `explorers` 250 |
| Help | ShowHelp `$C536`, RAM 1 | `explorers` 13 750-15 190 |
| play | MainLoop `$9018` | `explorers` 750 |
| the lab | room `$3B`'s script | `rzx48000` 1999 |
| the space scene | SpaceScene `$B0B6` | `gameover` 1509-1961, `rzx50000` 194-729 |

## 1.3 The five explorers

The selector offers five explorers. Each has a sprite set of 64 frames, a portrait in the panel, and a room of his own
left of room `$29` (ExplorerRooms `$A66C`), where he gets the Formula. In four of the rooms it lies on the floor
(ItemPlaces records 27-30). In room `$2D` it must be won: the explorer stands at X `$DC`, Y `$48` holding the Cricket
Ball, throws it at the target (status 28), and the Formula drops into his hand; the ball is gone (CricketBallScript
`$B370`, Room2DAnim `$A828`).

| Explorer | `$5B70` | Sprite set on the tape | 128K page | Own room |
| --- | ---: | --- | --- | --- |
| Fortisque-Smithe | 0 | `$9CF8` | RAM 4 `$C000` | `$2D` |
| Herr Krusche | 1 | `$AEF8` | RAM 4 `$D200` | `$2E` |
| Henri Beaucoup | 2 | `$C0F8` | RAM 4 `$E400` | `$2F` |
| Big John Caine | 3 | `$D2F8` | RAM 3 `$C000` | `$46` |
| Wu Pong | 4 | `$E4F8` | RAM 3 `$D200` | `$47` |

![The five explorers: each one's panel and sprite set](img/design/explorers.png)

*The five explorers. Left: the panel in play, from the `explorers` recording at frames 1250, 3750, 6250, 9250 and
11 750, one game each (`$5B70` = 0-4, read with `time_travel memory_at` at frames 1000, 3500, 6000, 9000 and 11 500),
2 x. Right: each explorer's sprite set,
`src/res/sprites/explorer-N.png`, frames `$00-$3F`. Made with `python3 tools/fig_design.py explorers
docs/img/design/explorers.png`.*

How to read it:

- The spare lives (left of the panel) and the hero are drawn with the chosen set, so they change with the explorer.
- The picture in the middle (the waterfall) and the bearers on the right are the same for all five. The portrait,
  the small figure under the held item (frame 9 of the set, DrawPortrait `$9E5D`), shows the chosen explorer.
- In each sheet the first rows are walking and standing, then climbing, jumping and the poses; the last row holds the
  deaths.

The explorer changes only the figures and the own room. The map, the creatures, the items and the professor's wishes
are the same. The RZX run plays Fortisque-Smithe. It enters room `$2D` at RZX frame 17 375 with the Cricket Ball, throws
it from RZX frame 17 725 (status 28) and has the Formula in the hand at 18 050, without a pickup score.

**The point**: the choice of explorer is cosmetic plus one room. It is the 128K's showpiece: the selector and the five
sets live in the extra pages, and a 48K player gets one explorer per load.

## 1.4 The controls

From Help page 3 (`src/res/texts/help-page3.txt`) and the code ([doc 5](05-controls.md)):

| Key | Action |
| --- | --- |
| Z, X | left, right |
| O, K | up, down: climb, enter a lift, use some items |
| SPACE | jump; FIRE on a joystick |
| S | swap the held item with the load of the first bearer shown in the row (BearerIndex `$5C23`, ItemsKeys `$BA36`; the Help says "with another nearest") |
| 1, 2 | move the bearers and their objects right, left: scroll the panel's bearer row |
| T | think: the explorer thinks of the item this room needs, if any (ThinkHints `$A6E6`) |
| CAPS SHIFT + Q | quit to the menu |
| Q + A | freeze while A is held (not in Help; known only from the code) |

- The device is chosen on the menu: 1 keyboard, 2 Kempston (port `$1F`), 3 Sinclair (keys 6-0).
- The selector reads all three devices at once (ReadAnyDevice `$C3BF`), whatever the menu says.
- The keys are read once a pass of the main loop, about 17 times a second ([doc 4](04-game-loop.md)).

## 1.5 The panel

![The status panel](img/design/panel.png)

*The status panel, the screen's bottom third, with explorer 0 in room `$14` (`explorers` frame 1250, 3 x). The boxes
mark its parts. Made with `python3 tools/fig_design.py panel docs/img/design/panel.png`.*

How to read it:

- **SCORE and HISCORE** (top left): four digits each, printed by PrintScore `$BD75`. The high score lasts from game to
  game until the tape is loaded again.
- **The spare lives** (bottom left): one figure of the explorer a spare life. A game starts with 4 lives, 3 figures.
- **The panel's picture** (middle): the waterfall, the same for all five explorers.
- **The item in the hand** (above the portrait): what the explorer holds and can use.
- **The portrait** (under the item): the chosen explorer, frame 9 of his set at `$5092` (row 20, columns 18-20),
  drawn by DrawPortrait `$9E5D` ([doc 8, 8.6](08-hud-and-text.md#86-the-portrait-the-held-item-and-the-spare-lives)).
- **The bearers** (right): a row of carried items, each above a bearer figure (DrawBearers `$9EBD`). Four are drawn and
  nine of their twelve columns show: three whole bearers at rest, parts of four while the row scrolls. Key 1 moves
  the bearers right, key 2 left: one bearer (3 columns, 24 pixels) a scroll, in 3 moves of one character column (5
  passes for key 1, 4 for key 2).

The panel has no clock. The time left is shown only by the telescope in room `$12` ([doc 4](04-game-loop.md)).

## 1.6 The rules

### Lives

- A game starts with 4 lives (InitGame `$8F69`).
- A death plays its frames, then the explorer lies still for 50 passes (status 18, LoseLifeWait
  `$A9EE`): 128 frames or 2.6 seconds in `gameover` (frames 1374-1502).
- Then a life is lost, and the explorer restarts at the entry of the last checkpoint room, as he entered it. The 44
  checkpoint rooms are listed at CheckpointRooms `$9AF5` (`src/res/tables/checkpoint-rooms.txt`).
- The last life lost takes the game to the space scene: the asteroid strikes.

The ways to die ([doc 10](10-gameplay-logic.md)):

| Death | Status | Seen in |
| --- | ---: | --- |
| a landing after 20 fall passes or more (FallPasses `$5C05`, not counted with the umbrella in use) | 26 | `gameover` frames 1360-1373; the RZX run's fall into `$1C` at RZX frames 11 350-11 375 (status 18 from 11 375) |
| a creature that touches him at its hit frame (Near `$9140`: both distances under 16 pixels, 8 for a drop; HitExplorer `$C0DA`) | 24 | `rzx06000`, `rzx22000`, `rzx32000`, all three drifts of our replays: the RZX dump never holds status 24 (WALKTHROUGH 6.0) |
| tile `$A5` under the feet (HeroTileChecks `$A102`, `$A12D`) | 26 | known only from the code |
| the creature of room `$2E` touched without item 4 (Room2ETouch `$B2C5`, ExplorerRoom2E `$B263`) | 26 | known only from the code |
| an electric beam: inside its X span, within 12 rows, status below 4 (RoomEffects, `$9260`) | 24 | known only from the code |
| the snakes of rooms `$17` and `$1A` (RunSnakes, shared) | 25 | `rzx10000` frames 1943-1958 (a drift of our replay: the RZX player was not bitten there, WALKTHROUGH 6.0) |
| silent: the pad of room `$20`, the radiation of room `$3C` without the pills, the creature of room `$39` without the Silver Cross | 23 | a clone probe only (stage 2) |
| the balloon landing while it falls (status 9), then the fall death | 26 | known only from the code |
| the barrel rides Small and Big | 15, 16 | known only from the code |

Sinking in the mud (status 17, after 50 passes on a mud tile) does not kill. The explorer drops one row and goes on.

### The countdown

- 30 days, 23 hours, 59 minutes at the start (InitGame).
- One minute goes every pass of the main loop: a day is 1440 passes, about 4090 frames or 82 seconds of play.
- At 0 the asteroid strikes: the same space scene as the last life's. There is no message.
- The whole countdown is 44 640 passes (44 639 to 0/0/0, the 44 640th runs out): about 126 800 frames or 42 minutes
  at the RZX run's 2.84 frames a pass ([doc 4](04-game-loop.md)). The RZX player finished with 18 days 15:32 left.

### The score

The score has five sources (AddScore `$BCF2` and its callers, `src/game/game.ann`):

| Event | Points | Code |
| --- | ---: | --- |
| an item picked up from the floor | +50 | PickUpItem `$BB6C`, `$BBE9` |
| the Energy Crystal placed in room `$30` | +75 | ItemsPass, `$BA2A` |
| the Silver Lining used in room `$43` | +75 | Room43Anim `$A851` |
| the creature of room `$39` driven off with the Silver Cross | +150 | `$B538` |
| each of the six gifts given to the professor | +150 | the lab's script, `$B5FE` |

Swapping between the hand and a bearer does not score. The Formula, given by the scene of the explorer's own room,
does not score either.

Worked example, the RZX run's final score of 2300:

- 22 pickups x 50 = 1100;
- the crystal and the Silver Lining, 2 x 75 = 150;
- room `$39` and the six gifts, 7 x 150 = 1050;
- 1100 + 150 + 1050 = 2300, the score in the RZX dump at RZX frame 50 200.

The score is printed as four digits. A negative score never becomes the high score (NewHiScore `$BD50`;
[doc 8](08-hud-and-text.md)).

**The point**: the score is a side show. It counts what was done, but the game is won or lost on the six gifts and
the clock.

## 1.7 The items and the professor's six wishes

![The 32 items, with the professor's six wishes](img/design/items.png)

*The 32 item sprites at `$8400`, 72 bytes each, drawn from `src/res/sprites/items.png` at 3 x, with their names. A
yellow ring and a number mark the professor's six wishes in their order (WantedItems `$B6BB`,
`src/res/tables/wanted-items.csv`). Made with `python3 tools/fig_design.py items docs/img/design/items.png`.*

How to read it:

- The names are the SkoolKit notes' (Items-Format.md), checked in play by stage 2.
- Items 25, 26, 30 and 31 (Basket, Balloon, Basket 2, Lift) are scenery that room scripts draw. They are never carried.
- ItemPlaces' 31 records place 27 distinct items: the Formula has four records (27-30), the Energy Crystal two (19,
  20). Items 25, 26, 29, 30 and 31 are never placed; 29, the Silver Cross, is given in room `$43`.
- The six ringed items are the goal. The rest open the way to them.

The six wishes, where each item lies, and when the RZX player gave it:

| Wish | Item | Lies in | Opened by | Given at RZX frame |
| ---: | --- | --- | --- | ---: |
| 1 | Formula (15) | the explorer's own room | in `$2D`, the Cricket Ball thrown at the target from X `$DC`, Y `$48` (CricketBallScript `$B370`) | 44 475 |
| 2 | Coat Hanger (19) | `$31` | | 45 225 |
| 3 | Battery (18) | `$34` | | 46 175 |
| 4 | Atomic Pile (21) | `$3C`, the radiation room | the Anti Rad. Pills held | 47 775 |
| 5 | Button (17) | `$42` | | 48 800 |
| 6 | Cup of tea (23) | `$45` | the Silver Cross past room `$39` | 50 200 |

Where the other items lie at the start is `src/res/tables/item-places.csv` (ItemPlaces `$B99D`); what each one does is
[doc 10](10-gameplay-logic.md)'s subject.

## 1.8 The map

The 72 rooms are numbered level x 12 + column: six levels of 12 columns, level 0 at the top (the sky) and level 5 at
the bottom (the deepest caves). Each level wraps round: the right exit of column 11 leads to column 0 of the same
level. Rooms `$2D`, `$2E`, `$2F`, `$46` and `$47` are the explorers' own rooms; a game reaches only its explorer's one,
through room `$29`'s left exit.

![The map with the RZX route](img/design/map-route.png)

*The map: the 72 rooms drawn from `src/res` by `tools/fig_rooms.py`'s room drawing, by level and column, and the RZX
run's route over them in red: the room every 25 RZX frames from the RZX dump (`work/docs/tmA/route-events.txt`); a room
left within 25 frames would be missed (none is suspected). Rooms the run never entered are greyed. Made with `python3 tools/fig_design.py map docs/img/design/map-route.png`.*

How to read it:

- Each small picture is a room. The label is its number; a grey label is a room the run never entered.
- The red line joins the rooms in the order the run entered them. A dot is a room.
- Most moves are to a neighbour: the room's left, right, top or bottom exit.
- Three lines run across a whole level: the wrap round from column 11 to column 0 (`$0B` to `$00`, `$17` to `$0C`,
  `$18` to `$23` and back).
- The other long lines are not walks: room `$29` to the explorer's room `$2D`, the teleport pads (TeleportPads
  `$B073`: rooms `$20`, `$3D`, `$30`; RZX frames 25 525 and 35 500), and the end, the lab `$3B` to room `$28`.
- Level 0 is the sky, level 1 the desert, levels 2-5 the caves. The rooms with the yellow blocks use the alternate tile
  set: `$12 $1E $1F $20 $2B $2C $37-$3C $43-$45` (AltTilesetRooms `$9AC6`).

The run never enters 15 rooms: `$01 $02 $05 $06 $11 $12 $15 $1E $21 $24 $25 $2E $2F $46 $47`. Four of them are the
other explorers' own rooms. Room `$12` holds the telescope. Probe B of stage 2 put 13 of them on screen, on a clone
with Room poked (`work/stage2/points/b-room-*.png`, [WALKTHROUGH 6.0](../WALKTHROUGH.md#60-the-recordings)); only `$46`
and `$47` are known from the data alone.

The published maps agree with this one. ZXDB 5195 ([Spectrum Computing](https://spectrumcomputing.co.uk/entry/5195))
holds four (`work/candidates/zxdb-maps/`): CRASH's of May 1988 (by Ian Bentley), Your Sinclair's "Tip o' the Month"
(by The Wizard, with room numbers of its own), Sinclair User 74's and one pieced from screens. All four draw the same rooms in the
same places: the sky and the desert along the top, the caves below, and on the right the block-built rooms of the
alternate tile set going down to the professor's lab. They draw the map flat, so the wrap round each level does not
show; the map here draws each level's 12 columns side by side, so a wrap is one of its long lines.

### Every room

![The rooms of levels 0-2](img/design/rooms-1.png)

*Rooms `$00-$23` (levels 0-2), each at 1 x from `src/res/rooms` and `src/res/tiles`, with its creatures (white) and
the items lying there at the start (yellow). Made with `python3 tools/fig_design.py rooms docs/img/design/rooms-1.png
--levels 0-2`.*

![The rooms of levels 3-5](img/design/rooms-2.png)

*Rooms `$24-$47` (levels 3-5), the same way. Made with `python3 tools/fig_design.py rooms docs/img/design/rooms-2.png
--levels 3-5`.*

How to read them:

- The label gives the room's number, its level and column; `*` marks the alternate tile set.
- The rooms are drawn from the resources, not from the screen: the creatures stand at their start places.
- The Energy Crystal of room `$30` is drawn, although InitGame `$8F86` marks that place (record 20, `$B9D9`) taken
  when a game starts: the figure shows the data as stored.
- Room `$14` (level 1, column 8) is the start, with the Vacuum Cleaner. Room `$3B` is the lab; room `$28` is space.

**The point**: the map is small but deep. The way down from the desert to the lab crosses all six levels, and the
items for the six wishes lie in levels 3-5.

## 1.9 The creatures

Each room holds up to three creatures, given by its records in RoomCreatures `$C152` (216 slots, 72 rooms x 3; 88 of them used). A record
names a type, which sets how the creature moves, and a first frame, which sets how it looks. The eight types:

![The eight creature types](img/design/creatures.png)

*The eight creature types, decoded from `build/res/rooms/table.bin` (built from `src/res/rooms/rooms.txt`) (RoomCreatures `$C152`): for each type the frames
from each first frame its records give (four frames from `src/res/sprites/creatures.png`, 2 x; type 8 shows explorer
0's frame), the number of records, and the rooms on the right. Made with `python3 tools/fig_design.py creatures
docs/img/design/creatures.png`.*

How to read it:

- A row is a type; its headline says how it moves. One type can look like several things: the walker is a bird, a
  flower or a box, depending on the record's first frame.
- The rooms list where the type lives at the start; the rooms of 1.8 show each creature at its start place.

| Type | Moves | Looks | Records, rooms | Kills |
| ---: | --- | --- | --- | --- |
| 1 walker | 2 pixels a pass along X, turns at walls and edges | bird (`$60`), flower (`$78`), box (`$6B`) | 10, 8: `$00 $01 $0E $15 $2C $33 $43 $45` | on touch |
| 2 climber | 2 pixels a pass along Y | box, flower | 2, 2: `$1F $38` | on touch |
| 3 left flier | waits unseen, crosses the room leftwards once, waits again | bird | 2, 2: `$0D $14` | on touch |
| 4 right flier | the same, rightwards | bird | 3, 3: `$07 $0D $31` | on touch |
| 5 drop | waits, falls 2 pixels a pass, splashes on the floor | drop (`$5C`) | 33, 18 | on touch, within 8 pixels |
| 6 still | animates in place | a crouching beast (`$64`), snakes (`$51`) | 8, 5: `$10 $17 $27 $32 $37` | the beasts on touch; the snakes never: the scripts of rooms `$17` and `$1A` make them strike unless the Flute is held (in `$1A` only while the explorer's Y < `$3A`, `$B59F`), status 25. Room `$1A`'s three snakes are not records: its script copies SnakeTemplate `$B5D1` into the slots |
| 7 riser | rises out of the ground through four frames, sinks, pauses | `$58-$5B` | 20, 16 | only when fully up |
| 8 scenery | never moves | an explorer frame (`$2C`, `$2B`) | 10, 7: `$04 $0D $20 $2C $30 $32 $42` | never |

"On touch" is the death of 1.6: Near `$9140` at the creature's hit frame, status 24. The creature code is
[doc 7, 7.5](07-objects.md#75-the-creature-types-one-by-one); the hazards that are not creatures (the beams, the pads,
the radiation) are [doc 10, 10.8](10-gameplay-logic.md#108-creatures-and-hazards).

**The point**: eight simple movers make all the creatures. None chases the explorer: each follows its own pattern, and
the game is in timing the way past.

## 1.10 The end of a game

Every game ends in room `$28`, the space scene: the asteroid falls towards the Earth.

- **Lost** (the last life or the countdown): the asteroid strikes the Earth.
- **Won** (the sixth gift given): the professor's deflector stands on top of the Earth and turns the asteroid away.

Either way the game returns to the menu, and the high score is kept if beaten.

![The space scene of a lost game](img/play/space-scene-lost.gif)

*The lost game: `gameover` frames 1500-1965 (the RZX state at 10000 with Lives poked to 1), every 5th frame, 4 x. Made
with `python3 ../../kit/screen_anim.py --work work/docs/tmA/gameover --from 1500 --to 1965 --step 5 --scale 4
docs/img/play/space-scene-lost.gif`.*

![The space scene of the ending](img/play/space-scene-won.gif)

*The ending: `rzx50000` frames 150-735 (the RZX run, replayed), every 6th frame, 4 x. Made with `python3
../../kit/screen_anim.py --work work/docs/tmA/r50000 --from 150 --to 735 --step 6 --scale 4
docs/img/play/space-scene-won.gif`.*

How to read them:

- The lost game opens on the dead hero in room `$1C` (frame 1500; Respawn at 1509 starts the space scene); the ending
  opens in the lab (frame 150, score 2150), and room `$28` follows from frame 194.
- In room `$28` both show the Earth at the bottom and the asteroid coming down. SpaceScene `$B0B6` moves it 4 pixels
  a pass, so it reaches the Earth about 20 passes after the scene starts.
- In the lost game the asteroid strikes the Earth and the Earth flashes.
- In the ending the deflector stands on top of the Earth; it fires and the asteroid flies off to the left.
- Both close as EndGame starts (the lost one already shows the updated high score); the menu that follows is not in
  the GIFs.

![Key moments of a game](img/design/moments.png)

*Four moments from the recordings: the fall death in room `$1C` (`gameover` frame 1366; the panel still shows three
spare figures because Lives was poked, not lost), the explorer lying dead, status 18 for 50 passes (`gameover` 1420),
the professor in the lab (`rzx50000` frame 100, score 2150, five gifts given) and the strike, the asteroid at the
Earth (`gameover` 1600). Made with `python3 tools/fig_design.py moments docs/img/design/moments.png` from
`time_travel memory_at` screens.*

![The RZX run: each new mechanism as it first appears](img/design/moments-2.png)

*Nine moments of the RZX run, from the RZX's own screens in the RZX dump (`work/docs/tmA/rzx25/screens.bin`, one
screen every 25 RZX frames, made by `tools/rzx_dump.py`), 1.3 x. Made with `python3 tools/fig_design.py moments2
docs/img/design/moments-2.png`.*

How to read it, left to right and down:

- the hover with the Vacuum Cleaner, a bird above (room `$14`, RZX frame 400);
- the respawn after the fall into `$1C`: room `$1B`, two spare figures left (RZX 11 525);
- the balloon rising with the Bellows in the hand (room `$0F`, RZX 14 900);
- the barrel ride: the cannon fires the Barrel Medium (room `$1D`, RZX 16 525);
- the Cricket Ball thrown at the target in the explorer's own room (room `$2D`, RZX 17 750);
- the lift down, status 20 (room `$2B`, RZX 20 675);
- the teleport pad, status 22 (room `$30`, RZX 25 500), and out of the teleport (room `$3D`, RZX 25 525);
- the ending: the asteroid falls while the deflector waits (room `$28`, RZX 50 225).

The creatures of 1.9 are in the rooms of 1.8; a sample is the bird of the first picture.

There is no ending text and no congratulation: the deflector scene is the reward. The professor's last gift, the Cup of
tea, starts it at once (RZX frame 50 200).

## 1.11 A walkthrough: the RZX run

The RZX archive's run (Bobby Lequay, Fortisque-Smithe) wins with one life lost, score 2300 and 18 days 15:32 left. Its
route, from the RZX dump every 25 RZX frames (`work/docs/tmA/route-events.txt`, made by
`work/docs/tmA/route_events.py`):

| Phase | RZX frames | Rooms | What happens |
| --- | --- | --- | --- |
| 1. The sky | 225-5 600 | `$14 $08 $07 $13 $14 $08 $09 $0A $0B $00 $0B $0A $16` | the Vacuum Cleaner in `$14`, then the items of levels 0 and 1: Barrel Medium, ACME Bridge, Party Manifesto, Silver Lining, Unicycle, Umbrella |
| 2. Down to the caves | 5 600-10 500 | `$16 $17 $0C $18 $23 $22 $23 $18 $19 $1A $1B $1C $10` | the Flute, the Cricket Ball, the Flashgun in `$22`; the ACME Bridge in the hand in `$19`, the Flute in `$1A`, the snakes' room |
| 3. The fall | 10 500-11 525 | `$10 $1C $1B` | the Bellows and the Spurs in `$10`; a fall into `$1C` kills (status 18 at 11 375-11 500); the restart in `$1B` with 3 lives |
| 4. The balloon | 11 525-15 950 | `$1A $19 $18 $0C $0D $0E $0F $03 $04 $10 $1C $1D` | the balloon of `$0F` with the Bellows in the hand (status 8), up to `$03`; the Anti Rad. Pills in `$04`; the Barrel Big in `$1D` |
| 5. The Formula | 15 950-18 275 | `$1D $29 $2D $29` | the barrels swapped in `$1D`; the explorer's own room `$2D`: the Cricket Ball, then the Formula |
| 6. The lift and the crystal | 18 275-25 525 | `$2A $2B $2C $2B $37 $36 $35 $34 $33 $27 $26 $32 $31 $30` | the Beer Barrel, the Energy Crystal of `$2C`; the lift down from `$2B`; the Battery in `$34`, the Switch, the Coat Hanger in `$31`; the crystal placed in `$30` (+75) |
| 7. The deep caves | 25 525-35 500 | `$3D $3C $3D $3E $3F $40 $41 $42 $41 $40 $3F $3E $3D` | the teleport `$30` to `$3D`; the Atomic Pile in `$3C` with the pills held; the Button in `$42` and back |
| 8. The Silver Cross | 35 500-43 050 | `$20 $1F $2B $37 $43 $44 $45 $44 $43 $44 $38 $39 $3A $3B` | the teleport to `$20`; the Silver Lining in `$43` (+75) gives the Silver Cross; the Cup of tea in `$45`; the Silver Cross drives off the creature of `$39` (+150) |
| 9. The lab | 43 050-50 200 | `$3B` | the six gifts, each +150: Formula 44 475, Coat Hanger 45 225, Battery 46 175, Atomic Pile 47 775, Button 48 800, Cup of tea 50 200 |
| 10. The end | 50 200-51 125 | `$28` | GameWon set, status 29: the deflector scene, then the menu |

```mermaid
flowchart TD
    A["1 the sky: Vacuum Cleaner, level 0 items"] --> B["2 down to the caves: Flute past the snakes"]
    B --> C["3 the fall: a life lost, restart in $1B"]
    C --> D["4 the balloon with the Bellows, the pills"]
    D --> E["5 the own room $2D: the Formula"]
    E --> F["6 the lift, the Battery, the Coat Hanger, the crystal in $30"]
    F --> G["7 the teleport, the Atomic Pile, the Button"]
    G --> H["8 the Silver Cross, the Cup of tea, room $39"]
    H --> I["9 the lab $3B: six gifts in order"]
    I --> J["10 room $28: the asteroid deflected"]
```

The run takes 83 room changes through 57 rooms. Its play, from RZX frame 225 to GameOver at 50 730, is 50 505 RZX
frames, about 17 minutes. 17 779 minutes of the countdown went in that time: 2.84 frames a pass of the main loop.
The pass-end test `$9052` gives the spread: gaps of 2 frames 4470 times, 3 frames 12 236, 4 frames 954, longer ones
125 times (room set-ups and the death wait) ([doc 4, 4.4](04-game-loop.md#44-frames-per-pass-and-the-pass-against-the-beam)).

**The point**: the route is a sweep, not a maze. It clears each level of what is needed, then goes down, and only the
lab's six gifts are taken in a fixed order.

## 1.12 Known only from the code

- The 48K path past the explorer's choice. Up to the choice it was seen on stage 2's 48K tries (STOP THE TAPE, the
  selector, the set copy; no `.ttd`; [doc 3, 3.4](03-build-and-load.md#34-the-48k-path-and-the-2a-stop-block)).
- The Q + A freeze.
- The time running out in a real game (seen only on a clone with the countdown poked, stage 2 probe A).
- The telescope of room `$12`: the asteroid and the time left (TelescopeView `$A7B9`).
- The think key's hint (statuses 10-12).
- The deaths: the balloon crash, the barrels Small and Big, tile `$A5`, room `$2E`'s creature, the beams, room
  `$20`'s pad, room `$39`'s creature.
- The mud sink (status 17), which is not a death.
- The infinite-lives hook of the loader (`$8000` = `$C9` before the load).
