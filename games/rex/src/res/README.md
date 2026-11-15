# Resources

Every resource of the three parts (REX 1, REX 2, DEMO) and the loading screens, cut out of the code by the `@res`
lines of `src/game/game.ann`, `src/rex2/rex2.ann`, `src/demo/demo.ann` and `src/screen/screen.ann`, in an editable
format. `tools/res_formats.py build` turns them back into the bytes the sources INCBIN (`tools/build.sh` does it
first), `tools/res_formats.py check` proves the round trip (0 bad), `tools/build.sh` the whole tape bit for bit.
`tools/room_maps.py` draws every room and the world map of each part from `rooms/`, `blocks/` and `chars/`.

Each folder's README gives the format. The files (the `.bin` is the name the source INCBINs, written by `build`):

| File | Bytes | Part | Entries | Address | Size | Readers |
| --- | --- | --- | --- | --- | --- | --- |
| `leftovers/rex1-devlink.bin` | `leftovers/rex1-devlink.bin` | REX 1 | DevLinkStub, Unused607E | `$6018-$60DF` | 200 | none (leftover) |
| `fonts/rex1.png` | `fonts/rex1.bin` | REX 1 | Font | `$60E0-$62DF` | 512 | PrintChar, PrintDigits, PanelBox, the DEFINE echo |
| `tables/rex1-char-flags.csv` | `tables/rex1-char-flags.bin` | REX 1 | CharFlags | `$62E0-$63DF` | 256 | DrawRoomCell (the room grid) |
| `chars/rex1.png` | `chars/rex1.bin` | REX 1 | CharGraphics, CharAttrs | `$63E0-$6CDF` | 2304 | DrawRoomCell, the animated cells |
| `blocks/rex1.csv` | `blocks/rex1.bin` | REX 1 | BlockDefs | `$6CE0-$75DF` | 2304 | DrawRoom |
| `rooms/rex1.txt` | `rooms/rex1-maps.bin` | REX 1 | RoomMaps | `$75E0-$7F71` | 2450 | DrawRoom |
| `sprites/rex1.png` | `sprites/rex1.bin` | REX 1 | Sprites | `$7F72-$9479` | 5384 | DrawSprite, DrawMirrored, DrawCharBlock |
| `tables/rex1-kill-scores.csv` | `tables/rex1-kill-scores.bin` | REX 1 | KillScores | `$994E-$9967` | 26 | KillObject (DEMO: ShowPoints) |
| `texts/rex1-hud.txt` | `texts/rex1-hud.bin` | REX 1 | HudTexts | `$A24C-$A289` | 62 | DrawHud (PrintText) |
| `texts/rex1-code.txt` | `texts/rex1-code.bin` | REX 1 | CodeText | `$A884-$A89C` | 25 | CodePanel |
| `tables/rex1-attract-rooms.txt` | `tables/rex1-attract-rooms.bin` | REX 1 | AttractRooms | `$A90C-$A914` | 9 | Attract |
| `texts/rex1-game.txt` | `texts/rex1-game.bin` | REX 1 | GameTexts | `$AAAE-$ABDC` | 303 | PrintText (the HUD, the panels, the end) |
| `rooms/rex1.txt` | `rooms/rex1-objects.bin` | REX 1 | RoomObjectLists | `$AECD-$B132` | 614 | ReadExits, MakeObjects |
| `rooms/rex1.txt` | `rooms/rex1-exits.bin` | REX 1 | RoomExits | `$B133-$B204` | 210 | ReadExits, ChangeRoom |
| `sound/rex1-effects.txt` | `sound/rex1-effects.bin` | REX 1 | SfxGun | `$D763-$D831` | 207 | StartSfx, SoundStep |
| `texts/rex1-roll-call.txt` | `texts/rex1-roll-call.bin` | REX 1 | RollCallTexts | `$DC26-$DD53` | 302 | TitleMenu, RollCallText (PrintText) |
| `texts/rex1-menu.txt` | `texts/rex1-menu.bin` | REX 1 | MenuTexts | `$DF05-$E00A` | 262 | TitleMenu (PrintText) |
| `screens/rex1-title.png` | `screens/rex1-title.bin` | REX 1 | TitleScreen | `$E4FF-$FFF9` | 6907 | TitleMenu |
| `leftovers/rex2-devlink.bin` | `leftovers/rex2-devlink.bin` | REX 2 | DevLink, DevLinkState, Unused62FE | `$61A8-$6305` | 350 | none (leftover) |
| `fonts/rex2.png` | `fonts/rex2.bin` | REX 2 | Font | `$6306-$6505` | 512 | PrintChar, PrintDigits, PanelBox, the DEFINE echo |
| `tables/rex2-char-flags.csv` | `tables/rex2-char-flags.bin` | REX 2 | CharFlags | `$6506-$6605` | 256 | DrawRoomCell (the room grid) |
| `chars/rex2.png` | `chars/rex2.bin` | REX 2 | CharGraphics, CharAttrs | `$6606-$6F05` | 2304 | DrawRoomCell, the animated cells |
| `blocks/rex2.csv` | `blocks/rex2.bin` | REX 2 | BlockDefs | `$6F06-$7805` | 2304 | DrawRoom |
| `rooms/rex2.txt` | `rooms/rex2-maps.bin` | REX 2 | RoomMaps | `$7806-$8197` | 2450 | DrawRoom |
| `sprites/rex2.png` | `sprites/rex2.bin` | REX 2 | Sprites | `$8198-$946F` | 4824 | DrawSprite, DrawMirrored, DrawCharBlock |
| `tables/rex2-kill-scores.csv` | `tables/rex2-kill-scores.bin` | REX 2 | KillScores | `$9896-$98AF` | 26 | KillObject (DEMO: ShowPoints) |
| `texts/rex2-hud.txt` | `texts/rex2-hud.bin` | REX 2 | HudTexts | `$A3F4-$A431` | 62 | DrawHud (PrintText) |
| `texts/rex2-game.txt` | `texts/rex2-game.bin` | REX 2 | GameTexts | `$AAF7-$AC91` | 411 | PrintText (the HUD, the panels, the end) |
| `rooms/rex2.txt` | `rooms/rex2-objects.bin` | REX 2 | RoomObjectLists | `$AFC2-$B1A6` | 485 | ReadExits, MakeObjects |
| `rooms/rex2.txt` | `rooms/rex2-exits.bin` | REX 2 | RoomExits | `$B1A7-$B242` | 156 | ReadExits, ChangeRoom |
| `sound/rex2-effects.txt` | `sound/rex2-effects.bin` | REX 2 | SfxGun | `$D4FB-$D5C9` | 207 | StartSfx, SoundStep |
| `texts/rex2-code.txt` | `texts/rex2-code.bin` | REX 2 | CodeTexts | `$DCA7-$DD1E` | 120 | EnterCode, the INVALID CODE panel |
| `texts/rex2-menu.txt` | `texts/rex2-menu.bin` | REX 2 | MenuTexts | `$DFC6-$E0C6` | 257 | TitleMenu (PrintText) |
| `screens/rex2-title.png` | `screens/rex2-title.bin` | REX 2 | TitleScreen | `$E4FF-$FFF9` | 6907 | TitleMenu |
| `leftovers/demo-devlink.bin` | `leftovers/demo-devlink.bin` | DEMO | DevLink, DevLinkState, Unused62FE | `$61A8-$6337` | 400 | none (leftover) |
| `fonts/demo.png` | `fonts/demo.bin` | DEMO | Font | `$6338-$6537` | 512 | PrintChar, PrintDigits, PanelBox, the DEFINE echo |
| `tables/demo-char-flags.csv` | `tables/demo-char-flags.bin` | DEMO | CharFlags | `$6538-$6637` | 256 | DrawRoomCell (the room grid) |
| `chars/demo.png` | `chars/demo.bin` | DEMO | CharGraphics, CharAttrs | `$6638-$6F37` | 2304 | DrawRoomCell, the animated cells |
| `blocks/demo.csv` | `blocks/demo.bin` | DEMO | BlockDefs | `$6F38-$7837` | 2304 | DrawRoom |
| `rooms/demo.txt` | `rooms/demo-maps.bin` | DEMO | RoomMaps | `$7838-$79DB` | 420 | DrawRoom |
| `sprites/demo.png` | `sprites/demo.bin` | DEMO | Sprites | `$79DC-$8A83` | 4264 | DrawSprite, DrawMirrored, DrawCharBlock |
| `tables/demo-kill-scores.csv` | `tables/demo-kill-scores.bin` | DEMO | KillScores | `$8EA8-$8EB7` | 16 | KillObject (DEMO: ShowPoints) |
| `texts/demo-hud.txt` | `texts/demo-hud.bin` | DEMO | HudTexts | `$9D41-$9D7E` | 62 | DrawHud (PrintText) |
| `tables/demo-tutor-rooms.txt` | `tables/demo-tutor-rooms.bin` | DEMO | TutorRooms | `$A2A2-$A2A6` | 5 | NextTutorRoom |
| `texts/demo-bonus.txt` | `texts/demo-bonus.bin` | DEMO | BonusTexts | `$A3D2-$A430` | 95 | BonusRoulette |
| `texts/demo-tutor.txt` | `texts/demo-tutor.bin` | DEMO | TutorTexts | `$A431-$AC85` | 2133 | TutorPanel, the credits |
| `rooms/demo.txt` | `rooms/demo-objects.bin` | DEMO | RoomObjectLists | `$AFEE-$B032` | 69 | ReadExits, MakeObjects |
| `rooms/demo.txt` | `rooms/demo-exits.bin` | DEMO | RoomExits | `$B033-$B056` | 36 | ReadExits, ChangeRoom |
| `sound/demo-effects.txt` | `sound/demo-effects.bin` | DEMO | SfxGun | `$D967-$DA35` | 207 | StartSfx, SoundStep |
| `leftovers/demo-workspace.bin` | `leftovers/demo-workspace.bin` | DEMO | WorkSpace | `$DB4D-$FFF9` | 9389 | none on the tape (work space) |
| `screens/rex1.png` | `screens/rex1.bin` | REX 1 | LoadingScreenRex1 | `$4000-$5AFF` | 6912 | the ROM loader (LOAD "" SCREEN$) |
| `screens/rex2.png` | `screens/rex2.bin` | REX 2 | LoadingScreenRex2 | `$4000-$5AFF` | 6912 | the ROM loader |
| `screens/demo.png` | `screens/demo.bin` | DEMO | LoadingScreenDemo | `$4000-$5AFF` | 6912 | the ROM loader |

Notes:

- REX 2's title screen (`screens/rex2-title.png`) is REX 1's byte for byte; each part carries its own copy.
- The `.bin` files are not kept in `src/res`: `build` writes them into `build/res` from the editable files.
- `leftovers/` holds the bytes no code reads (leftovers/README.md); every other byte of the three images stays in the
  `.asm` as code or `DEFB` / `DEFW` lines.
