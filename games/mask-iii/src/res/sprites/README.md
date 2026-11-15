# Sprites

PNG, 1-bit, the frames side by side. A frame of w x h characters is w x h x 8 bytes stored column by column
(character at column c, row r at 8 x (c x h + r)), except `control-icons.png`, drawn by DrawGraphic `$99B8` row by
row. tools/res_formats.py SPRITES gives each file's w x h.

| File | Entry | Frames |
| --- | --- | --- |
| `control-icons.png` | ControlIcons `$CC80` | 7 of 2 x 2: Kempston, Interface 2, Cursor, keyboard and three more |
| `matt-run.png` | MattRun `$CD60` | 8 of 4 x 4 |
| `matt-jump.png`, `matt-crouch.png` | MattJump `$D160`, MattCrouch `$D1E0` | 1 of 4 x 4 each |
| `faller.png` | SpriteFaller `$D260` | 4 of 2 x 2 (kinds 1, 12) |
| `flyer.png` | SpriteFlyer `$D2E0` | 4 of 3 x 2 (kind 2) |
| `digits.png` | Digits `$D3A0` | 10 of 1 x 2 |
| `explosion.png`, `explosion-big.png` | `$D440`, `$D4C0` | 4 of 2 x 2, 4 of 3 x 2 |
| `mask-icons.png` | MaskIcons `$D580` | 11 of 2 x 2: EMPTY and the ten masks |
| `shots.png` | SpriteShots `$D6E0` | 6 of 2 x 2, Matt's shot per mask kind 5-10 |
| `turret.png`, `turret-shot.png` | `$D7A0`, `$D860` | 4 of 3 x 2, 8 of 1 x 1 |
| `wave.png`, `walker.png`, `chaser.png` | `$D8A0`, `$D960`, `$D9E0` | 6 of 2 x 2, 4 of 2 x 2, 1 of 8 x 3 |
| `kind16.png`, `big.png`, `guard.png` | `$DAA0`, `$DB60`, `$DBC0` | 4 of 2 x 3, 1 of 4 x 3, 1 of 4 x 4 |
| `part1.png`, `part2.png`, `small.png` | `$DC40`, `$DD60`, `$DE80` | 4 of 3 x 3 each, 3 of 2 x 2 |
| `boss.png`, `boss-shot.png` | `$DEE0`, `$DF60` | 1 of 4 x 4, 1 of 2 x 2 |
