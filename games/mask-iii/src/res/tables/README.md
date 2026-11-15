# Tables

CSV, a header line, hex bytes, a record a row (`end` holds bytes after the last whole record).

| File | Entry | Columns |
| --- | --- | --- |
| `rooms.csv` | RoomTable `$953B` | left, right, pod (rooms, FF none), exit3 (always FF), zone, arrival (x = (b & 1F) x 4 + 40, screen = b >> 5), the enemy kind of screens 0-5 |
| `pickups.csv` | PickupTable `$950E` | room (bit 7 taken), mask kind, x, y; the `end` row is the FF |
| `effects.csv` | EffectTable `$92E0` | 18 sound effects of 14 bytes; `slot` (+$0A) picks the AY channel |
| `enemies.csv` | EnemyTemplates `$BE3B` | score (BCD), picture, damage, animation, mask, width, height, mode, hits, colour (FF random) |
