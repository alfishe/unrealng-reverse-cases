# Sound effects (GS)

The 22 sampled effects the conversion plays on the card, as WAV: 8-bit unsigned mono PCM, the data chunk is the
effect byte for byte (`tools/disk_media.py`). The rate in the header (11025 Hz) is nominal: the card plays an
effect at the pitch of the note the driver sends with it (`#40`), not at a stored rate. Any sound editor that keeps
8-bit unsigned mono edits them.

Where they go on the disk ([3](../../../docs/03-build-and-load.md)): `fx-start` and FX 1-10 in the boot banks (bank 1
from `$D3CB`, then banks 3, 4 and 6), uploaded at every level change; FX 11-21 in four disk sets, uploaded only in
effects-only mode (FX 21 only with SATURNS on). Which game event plays each, from the driver
(`src/disk/driver.ann`) and witnessed in play ([9](../../../docs/09-sound.md)):

| File | Bytes | Played by (driver entry) | Game event | Note |
| --- | ---: | --- | --- | --- |
| `fx-start.wav` | 9946 | the loader's StartFx | the game start, with PREPARE FOR COMBAT | `$33` |
| `fx01.wav` | 650 | PodAppearsSound | a weapon pod appears | `$26` |
| `fx02.wav` | 5207 | NextWeaponSound | the pod selects the next weapon | `$32` + 0-3 |
| `fx03.wav` | 5006 | WeaponOnSound | a weapon switched on | `$32` |
| `fx04.wav` | 1396 | EnemyFireSound, PlasmaLaunchSound | an enemy fires; a plasma ball is launched | `$30` + 0-1; `$2A` + 0-1 |
| `fx05.wav` | 6308 | MissileLaunchSound | a homing missile or a seeker is launched | `$32` + 0-1 |
| `fx06.wav` | 1347 | PlasmaBounceSound | a plasma ball bounces | `$3C` + 0-1 |
| `fx07.wav` | 9562 | ExplosionSound | an enemy explodes | `$2C` + 0-3 |
| `fx08.wav` | 10679 | ShipExplodesSound | the ship explodes; in music mode also a big enemy destroyed | `$2D` |
| `fx09.wav` | 3827 | ShotSound | a laser shot, laser level 0-1 (player 1's level: `$7FA6`) | `$34` + 0-1 |
| `fx10.wav` | 6548 | ShotSound | a laser shot, laser level 2-3 | `$32` + 0-1 |
| `fx11.wav` | 11282 | BigEnemyDestroyedSound | a big enemy destroyed (effects only: in channels 0 and 3, with FX 8 and 7) | `$28` + 0-3 |
| `fx12.wav` | 4216 | BigEnemyHitSound | a big enemy hit, levels 7 and 11 | `$2C` + 0-1 |
| `fx13.wav`, `fx14.wav` | 3450, 3554 | BigEnemyHitSound | a big enemy hit, the other levels (one of the two at random) | `$31` + 0-1 |
| `fx15.wav` | 2516 | SceneryBounceSound | an enemy bounces off the scenery | `$2D` + 0-1 |
| `fx16.wav` | 4464 | Path682CSound | path 2 at its 6th byte with 10 frames left: a turn of that formation | `$3C` |
| `fx17.wav` | 4589 | DiveSound | an enemy starts a dive | `$3C` on level 4, else `$28` |
| `fx18.wav` | 1442 | ArenaBounceSound | an enemy bounces off the arena's edge | `$3A` |
| `fx19.wav` | 3532 | Path6850Sound | path 4 at its 4th byte | `$28` |
| `fx20.wav` | 4147 | PathSound, Path685BSound, Path68F9Sound | path 3 at its 4th byte; paths 5 and 23 at their 5th byte | `$24`; `$28` |
| `fx21.wav` | 9144 | SaturnSound | SATURNS: path 1's objects when their movement changes | `$32` |

FX 11-21 play only in effects-only mode (CallDriverFx), except the music-mode branch of BigEnemyDestroyedSound,
which plays FX 8.
