# 7. Objects

What this covers: the GS conversion's view of Zynaps's objects. The records, slots, kinds, movers and collisions are
Zynaps's, unchanged ([12](12-routine-reference.md), the 48K case's chapter 7); the conversion hooks sounds onto them.

## 7.1 Where the sounds sit

Each new sound is a call placed in an object handler or a path command ([9.4](09-sound.md#94-where-the-game-makes-a-sound)):

| Site (Zynaps code) | Hook | FX | Event |
| --- | --- | --- | --- |
| `$9FBE` in EnemyHandler, `$A034` in LockableHandler | ExplodeHook | 7 | an enemy explodes |
| `$9B51` in PlayerHandler | ShipHitHook | 8 | the ship explodes |
| `$9C77` (the laser's sound) | ShotHook | 9, 10 | the laser shot (the menu's SHOOTING) |
| `$9CA6` in PlasmaFrame | PlasmaLaunchHook | 4 | a plasma ball launched |
| `$9CFA` in HomingFrame, `$9D1F` SeekerLaunch | MissileLaunchHook | 5 | a homing missile, a seeker launched |
| `$9EA5` in PlasmaHandler | PlasmaBounceHook | 6 | a plasma ball bounces |
| `$A31D` in ExplosionToPod | PodAppearsHook | 1 | a weapon pod appears |
| `$A226`, `$A21F` in PodStep | NextWeaponHook, WeaponOnHook | 2, 3 | the pod selects, switches on a weapon |
| `$A1C4` in EnemyFire | EnemyFireHook | 4 | an enemy fires |
| `$A0BA`, `$A0D5` in BigEnemyHandler | BigEnemyHitHook, BigEnemyDestroyedHook | 12-14; 8 or four FX | the big enemy hit, destroyed |
| `$95E7` in PathOpBounce | SceneryBounceHook | 15 | an enemy bounces off the scenery moving down |
| `$9823` PathArenaFlipY | ArenaBounceHook | 18 | an enemy bounces off the arena's top or bottom |
| `$9856` in PathOpDive | DiveHook | 17 | a diving enemy starts its dive |
| `$969D` in PathOpAimPlayer | AimPlayerHook | 19, 20 | PathSound by the path pointer |
| `$9694` PathDriftMove, `$9747` | ObjectSoundStub (`$B2F0`) | 16, 20, 21 | a moment of a path (7.2) |
| `$9954` EnemyGone | SlotGoneHook (`$B47F`) | - | the object's SATURNS slot cleared |

FX 1-10 play in both sound modes; the hooks of FX 11-21 go through CallDriverFx and play only in the effects-only
mode, except BigEnemyDestroyedHook, which plays FX 8 with the music. The counts seen in play are in
[9.4](09-sound.md#94-where-the-game-makes-a-sound).

## 7.2 Path sounds

ObjectSound and PathSound do not ask what kind of object moves: they look at the object's path pointer (`IY+$1D`,
the next command of its path bytecode) and at the frames its path command has left (`IY+$1B`). A sound marks one moment
of one path, so it belongs to the formations that fly that path, on whatever level uses it:

| Path pointer | Path | Condition | Sound |
| --- | --- | --- | --- |
| `$682C` | path 2 + 6 | 10 frames left | FX 16, note `$3C` |
| `$685B` | path 5 + 5 | 17 frames left | FX 20, note `$28` |
| `$68F9` | path 23 + 5 | 18 frames left | FX 20, note `$28` |
| `$6850` (or E = `$EE`) | path 4 + 4 | at AimPlayer | FX 19, note `$28` |
| `$6846` | path 3 + 4 | at AimPlayer | FX 20, note `$24` |
| `$6820` | path 1's start | SATURNS on, the movement flags changed, then 8 calls quiet for that slot | FX 21, note `$32` |

SaturnSound keeps, per enemy slot (0-6, from `IY`), the last movement flags it played with and a countdown
(`SlotValues`, `SlotCounters`); SlotGoneHook clears a slot's value when its object goes.
