# 11. Data reference

Every data entry of the game image `$6018`-`$FFF9`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text; an inner label (a field, a row) is a row of its own under
its entry, its size up to the next label; an entry with inner labels gives its own bytes, up to the first,
of the whole entry's ("17 of 34"). The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/stage1/c1`, local and not in the repository), then those only the case's other recordings (`read_builds`) saw, with the first of them in brackets, and, marked
"(code)", the routines (the label at or below the instruction) whose `LD` through `(nn)`, or through `HL`, `DE` or `BC` loaded with `nn` in the same block, reads or writes it where the recordings did not see them do so.
Written by `kit/refdocs.py`.
The parts of the medium (`case.json` `ref_parts`: The BASIC of REX 1, The BASIC of REX 2, The BASIC of DEMO, REX 1's
loading screen, REX 2's loading screen, DEMO's loading screen, Part 2 (REX 2), DEMO) follow the game, each under its
own heading with its modules, its source, its annotations and its recordings.

## graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6018` | `DevLinkStub` | 102 | Leftover: 102 bytes of the authors' development link, overwritten by the menu before they could run. No instruction jumps here. The menu (TitleMenu `$DAC0`) copies ExplosionPicture `$E336` to `$6018` (192 bytes) before anything else, and the objects use `$6018` as the explosion picture from then on (UpdateObject `$BA86`). Kept byte for byte as a documented leftover (src/res/leftovers/README.md). | `DrawSprite`, `EnemyBulletsHitRex`, `BulletLoop` (`stage1/rec/rzx-p1-06000`), `BulletsHitObject` (`stage1/rec/rzx-p1-24000`), `DrawMirrored` (`stage1/rec/rzx-p1-56000`) +1 | `TitleMenu` |
| `$607E` | `Unused607E` | 98 | Leftover: 98 bytes after the stub (overwritten by the explosion picture up to `$60D7`); nothing reads them before | `DrawSprite`, `EnemyBulletsHitRex`, `BulletLoop` (`stage1/rec/rzx-p1-06000`), `BulletsHitObject` (`stage1/rec/rzx-p1-24000`), `DrawMirrored` (`stage1/rec/rzx-p1-56000`) +1 | `TitleMenu` |
| `$60E0` | `Font` | 512 | The font: 64 characters, codes 32-95 (space to underscore), 8 bytes each, at `$5FE0` + 8 x code. PrintChar `$A2E9`, PrintDigits `$A3C8`, the box frame of PanelBox `$CE7B` and the DEFINE key echo (FontChar `$DEF0`) read it. The box frame uses six characters as corner and edge pieces (`$6120` "(", `$6130` "*", `$6140` ",", `$6158` "/", `$61B8` ";", `$61C8` "="). | `DrawChar`, `EnemyBulletsHitRex`, `PanelLine`, `PrintText`, `ScreenDown` +3 | - |
| `$62E0` | `CharFlags` | 256 | The cell type of each of the 256 room characters: what Rex and the objects test in the room grid. DrawRoomCell `$C7E2` copies CharFlags[c] into the grid `$E1FF` for each character drawn. The values tested: 0 empty, 2, 4, 5, 6 solid (SolidCells `$D096`), `$07` the restart marker, `$08` the shield recharger, `$0A-$0D` the weapon stations, `$0E-$12` solid platform kinds, `$12` the ladder or lift (CellsUnderRex `$9F5F`). | `DrawRoomCell`, `EnemyBulletsHitRex`, `BulletLoop` (`stage1/rec/rzx-p1-06000`), `BulletsHitObject` (`stage1/rec/rzx-p1-24000`), `ObjectHitsRex` (`stage1/rec/rzx-p1-00000`) | - |
| `$63E0` | `CharGraphics` | 88 of 2048 | The 256 room characters, 8 bytes each. Drawn by DrawRoomCell `$C7E2` into the back buffer; the animated ones are rotated in place each pass by the main loop (`$6438`, `$64B0`, `$64C0`, `$6600`, `$6758`, `$67D8`, `$6858`, `$6BA8`, `$6BB0`, `$6BC0`). | `Attract`, `DrawAnimCells`, `DrawRoomCell`, `EnemyBulletsHitRex`, `MainLoop` +7 | `AnimateCells`, `Attract`, `CopyFrame`, `MainLoop`, `RollCharDown` +3 |
| `$6438` | `AnimChar11` (`CharGraphics`+88) | 120 | character 11, rolled one line up by RollCharUp `$A7A9` every pass (MainAnimate) | `DrawAnimCells`, `DrawRoomCell`, `EnemyBulletsHitRex`, `RollCharUp`, `BulletLoop` (`stage1/rec/rzx-p1-06000`) +3 | `RollCharUp` |
| `$64B0` | `AnimChar26` (`CharGraphics`+208) | 16 | character 26, rolled one line down by RollCharDown `$A7BA` | `EnemyBulletsHitRex`, `RollCharDown`, `BulletLoop` (`stage1/rec/rzx-p1-06000`), `BulletsHitObject` (`stage1/rec/rzx-p1-24000`), `DrawAnimCells` (`stage1/rec/rzx-p1-12000`) +3 | `RollCharDown` |
| `$64C0` | `AnimChar28` (`CharGraphics`+224) | 320 | character 28, rolled one line down by RollCharDown | `DrawAnimCells`, `DrawRoomCell`, `EnemyBulletsHitRex`, `RollCharDown`, `BulletLoop` (`stage1/rec/rzx-p1-06000`) +3 | `RollCharDown` |
| `$6600` | `AnimChar68` (`CharGraphics`+544) | 344 | character 68: frames from FramesList1 `$A60C` (AnimateCells `$A55E`, CopyFrame) | `DrawAnimCells`, `DrawRoomCell`, `EnemyBulletsHitRex`, `BulletLoop` (`stage1/rec/rzx-p1-06000`), `BulletsHitObject` (`stage1/rec/rzx-p1-24000`) +2 | `CopyFrame` |
| `$6758` | `AnimChar111` (`CharGraphics`+888) | 128 | character 111: each line rotated right (RRC) by the main loop | `Attract`, `DrawAnimCells`, `DrawRoomCell`, `EnemyBulletsHitRex`, `MainLoop` +5 | `Attract`, `MainLoop`, `GameEntry` (`stage2/rec/p1-define`) |
| `$67D8` | `AnimChar127` (`CharGraphics`+1016) | 128 | character 127: frames from FramesList4 `$A61A` (CopyFrame) | `DrawAnimCells`, `DrawRoomCell`, `EnemyBulletsHitRex`, `BulletLoop` (`stage1/rec/rzx-p1-06000`), `BulletsHitObject` (`stage1/rec/rzx-p1-24000`) +2 | `CopyFrame` |
| `$6858` | `AnimChar143` (`CharGraphics`+1144) | 848 | character 143: each line rotated left (RLC) | `Attract`, `DrawAnimCells`, `DrawRoomCell`, `EnemyBulletsHitRex`, `MainLoop` +5 | `Attract`, `MainLoop`, `BulletsHitObject` (`stage1/rec/rzx-p1-24000`), `GameEntry` (`stage2/rec/p1-define`) |
| `$6BA8` | `AnimChar249` (`CharGraphics`+1992) | 8 | character 249: frames from FramesList3 `$A5F4` (AnimateRestart `$A5B7`) | `DrawAnimCells`, `DrawRoomCell`, `EnemyBulletsHitRex`, `NextCellPtr` (`stage1/rec/rzx-p1-18000`) | `CopyFrame` |
| `$6BB0` | `AnimChar250` (`CharGraphics`+2000) | 16 | character 250: frames from FramesList2 `$A602` (AnimateCells2 `$A5A7`) | `DrawAnimCells`, `DrawRoomCell`, `EnemyBulletsHitRex`, `BulletsHitObject` (`stage1/rec/rzx-p1-24000`), `NextCellPtr` (`stage1/rec/rzx-p1-18000`) +1 | `CopyFrame` |
| `$6BC0` | `AnimChar252` (`CharGraphics`+2016) | 32 | characters 252-255: AnimFramesA `$AE8D` / AnimFramesB `$AEAD` on alternate passes (AnimateCells) | `DrawAnimCells`, `DrawRoomCell`, `EnemyBulletsHitRex`, `BulletsHitObject` (`stage1/rec/rzx-p1-24000`), `NextCellPtr` (`stage1/rec/rzx-p1-18000`) +1 | `AnimateCells` |
| `$6BE0` | `CharAttrs` | 256 | The attribute of each of the 256 room characters | `DrawRoomCell`, `EnemyBulletsHitRex`, `MoveShots`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) | - |
| `$6CE0` | `BlockDefs` | 2304 | The 256 blocks: 3 x 3 character codes each, rows top to bottom | `DrawBlockRow`, `EnemyBulletsHitRex` (`stage1/rec/rzx-p1-40000`) | - |
| `$75E0` | `RoomMaps` | 2450 | The rooms 0-34: 7 rows of 10 block codes each (70 bytes a room); room n at `$75E0` + 70n. DrawRoom `$C745` builds the room in the grid and the back buffer from here. A room is 30 x 21 characters. | `DrawRoom` | - |
| `$7F72` | `Sprites` | 192 of 5384 | The sprites, pre-shifted: each label is a picture set its owner draws through a frame list. `$7F72` is the foot man (kind 0) and UpdateObject's default picture. The labels below name the other owners. | `CopyFrame`, `DrawCharBlock`, `DrawSprite`, `MoveShots`, `DrawMirrored` (`stage1/rec/rzx-p1-22000`) +1 | - |
| `$8032` | `SpriteStomper` (`Sprites`+192) | 192 | kind 1 (stomper) | `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-04000`) | - |
| `$80F2` | `SpriteRex` (`Sprites`+384) | 120 | Rex walking (DrawRex `$96A7`) | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-22000`) | - |
| `$816A` | `SpriteRexDeath` (`Sprites`+504) | 72 | the base of Rex's death shards (DeathAnimation `$9AC5`: frame n at +72 n, n 1-8, so SpritePoints' frames; these 72 bytes are never drawn) | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-22000`) | - |
| `$81B2` | `SpritePoints` (`Sprites`+576) | 576 | the points sign a kill leaves (ShowPoints `$97FD`) | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`) | - |
| `$83F2` | `SpriteKind5` (`Sprites`+1152) | 192 | kind 5 | `DrawSprite` | - |
| `$84B2` | `SpriteKind3` (`Sprites`+1344) | 192 | kind 3 | `DrawSprite` | - |
| `$8572` | `SpriteKind4` (`Sprites`+1536) | 192 | kind 4 | `DrawSprite` | - |
| `$8632` | `SpriteHitFlash` (`Sprites`+1728) | 96 | an object hit (HitObject `$D3C2`, HitObjectHard `$D41F`) | `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-02000`) | - |
| `$8692` | `SpriteRamTurn` (`Sprites`+1824) | 96 | the hit foot man turning (RamTurn `$BD44`) | `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-02000`) | - |
| `$86F2` | `SpritePodA` (`Sprites`+1920) | 192 | a pod left by an explosion (`$BDED`) | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`) | - |
| `$87B2` | `SpritePodB` (`Sprites`+2112) | 192 | a pod left by an explosion (`$BE18`) | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`) | - |
| `$8872` | `SpritePowerPod` (`Sprites`+2304) | 128 | the power pod's four frames (`$8872`, `$8892`, `$88B2`, `$88D2`: AnimatePod `$BED3`) | `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-00000`) | - |
| `$88F2` | `SpriteShield` (`Sprites`+2432) | 336 | the shield bubble round Rex, 4 x 21, through ShiftFrames2 (DrawShield `$9726`) | `DrawMirrored` (`stage1/rec/rzx-p1-22000`), `DrawSprite` (`stage1/rec/rzx-p1-00000`) | - |
| `$8A42` | `SpriteLaserA` (`Sprites`+2768) | 24 | the laser beam fired left: 6 frames of 4 bytes, copied by BeamByte `$B852` (`$B849`) | `MoveShots`, `DrawSprite` (`stage1/rec/rzx-p1-18000`), `MoveBeam` (`stage1/rec/rzx-p1-00000`) | - |
| `$8A5A` | `SpriteScanner` (`Sprites`+2792) | 256 | kind 8 (scanner) (`$C3B0`, `$C3D2`) | `DrawSprite` (`stage1/rec/rzx-p1-04000`) | - |
| `$8B5A` | `SpriteScanner2` (`Sprites`+3048) | 176 | kind 8's start picture (InitKind8 `$CCBF`) | `DrawSprite` (`stage1/rec/rzx-p1-04000`) | - |
| `$8C0A` | `SpriteHudIcons` (`Sprites`+3224) | 160 | the HUD's weapon and bomb icons (DrawHudIcons `$A1E2`) | `DrawCharBlock` | - |
| `$8CAA` | `SpriteHudIcons2` (`Sprites`+3384) | 64 | the HUD's weapon icons, second row (DrawWeaponIcon `$A21F`) | `DrawCharBlock` | - |
| `$8CEA` | `SpriteBonusPod` (`Sprites`+3448) | 32 | the bonus pod (kind `$7D`, `$BE39`) | `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-52000`) | - |
| `$8D0A` | `SpriteBonusPod2` (`Sprites`+3480) | 128 | (`$BE43`) | `CopyFrame`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-02000`) | - |
| `$8D8A` | `SpriteKind12` (`Sprites`+3608) | 192 | kind 12 (ramming pod) | `DrawSprite` (`stage1/rec/rzx-p1-08000`) | - |
| `$8E4A` | `SpriteKind11` (`Sprites`+3800) | 32 | kind 11 (launcher) | `DrawSprite`, `DrawCharBlock` (`docs/rxA/rec/menu-rollcall`) | - |
| `$8E6A` | `SpriteKind10` (`Sprites`+3832) | 32 | kind 10 (shooters) | `DrawSprite`, `DrawCharBlock` (`docs/rxA/rec/menu-rollcall`) | - |
| `$8E8A` | `SpriteKind6` (`Sprites`+3864) | 32 | kind 6 | `DrawMirrored` (`stage1/rec/rzx-p1-58000`), `DrawSprite` (`stage1/rec/rzx-p1-02000`) | - |
| `$8EAA` | `SpriteSwingGun` (`Sprites`+3896) | 160 | kind 9 (swing gun), its angles (SwingGunFrames `$BECB`) | `DrawSprite`, `DrawCharBlock` (`docs/rxA/rec/menu-rollcall`), `DrawMirrored` (`stage1/rec/rzx-p1-58000`) | - |
| `$8F4A` | `SpriteLaserB` (`Sprites`+4056) | 24 | the laser beam fired right: 6 frames of 4 bytes, copied by BeamByte `$B852` (`$B83F`) | `MoveShots`, `DrawMirrored` (`stage1/rec/rzx-p1-58000`), `DrawSprite` (`stage1/rec/rzx-p1-02000`), `MoveBeam` (`stage1/rec/rzx-p1-00000`) | - |
| `$8F62` | `SpriteRexJump` (`Sprites`+4080) | 192 | Rex jumping or falling, off a lift (DrawRex `$96C4`) | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-22000`) | - |
| `$9022` | `SpriteKind15` (`Sprites`+4272) | 128 | kind 15 (blob) | `DrawSprite` (`stage1/rec/rzx-p1-04000`) | - |
| `$90A2` | `SpriteKind13` (`Sprites`+4400) | 144 | kind 13 (mine layer) | `DrawSprite` (`stage1/rec/rzx-p1-18000`) | - |
| `$9132` | `SpriteKind14` (`Sprites`+4544) | 128 | kind 14 (mine) | `DrawSprite` (`stage1/rec/rzx-p1-18000`) | - |
| `$91B2` | `SpriteJumper` (`Sprites`+4672) | 32 | the jumping walkers (`$C5AB`) | `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-10000`) | - |
| `$91D2` | `SpriteKind16` (`Sprites`+4704) | 288 | kind 16 (the big gun) | `DrawSprite` (`stage1/rec/rzx-p1-22000`) | - |
| `$92F2` | `SpriteHuman` (`Sprites`+4992) | 392 | a human killed (`$98C1`) | `CopyFrame`, `DrawSprite` (`stage1/rec/rzx-p1-24000`) | - |

## score

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$994E` | `KillScores` | 26 | The score of each object kind, in hundreds: kind 0 1, 1 2, 2 1, 3 1, 4 2, 5 3, 6 1, 7 1, 8 6, 9 6, 10 5, 11 8, 12 3, 13 10, 14 0, 15 2, then 1s. The menu's roll call agrees: FOOT MAN 100, STOMPER 200, SCANNER 600, SWING GUN 600, SHOOTERS 500, LAUNCHER 800, RAMMING POD 300, MINE LAYER 1000, MINE no score, BLOB 200. | `KillObject` | - |
| `$9AB3` | `FadeSteps` | 18 | The fade's 17 steps: 1 six times, 0 five times, 2 six times, then `$FF` (the end) | `FadeStep` (`stage1/rec/rzx-p1-00000`) | - |

## death

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9C05` | `DeathShards` | 54 | The shards' 9 paths: X, Y step pairs, read by DeathAnimation | `DeathAnimation` | `DeathAnimation` |
| `$9F0C` | `SparkleMasks` | 8 of 83 | Eight bit masks `$80-$01`, then the particles' offsets (SparkleDots) | `Materialise`, `SparkleDraw` | `Materialise`, `SparkleDraw` |
| `$9F14` | `SparkleDots` (`SparkleMasks`+8) | 75 | the sparkle's particles: Y, X offset pairs | `Materialise`, `SparkleDraw` | `Materialise`, `SparkleDraw` |

## variables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A012` | `Variables` | 1 of 178 | The variables `$A012-$A0C3` (178 bytes, all zero on the tape) | `AddScore`, `AnimateCells`, `Attract`, `BlowUp`, `BufferAddress` +140 | `AddScore`, `Attract`, `BlowUp`, `BufferToScreen`, `BuildRoom` +136 |
| `$A013` | `Weapon` (`Variables`+1) | 1 | the weapon in use: 0 gun, 1 double fire, 2 laser, 3 multiple (drones), 4 spray | `BulletsHitObject`, `FindShotSlot`, `FindSlot`, `FireWeapon`, `MoveShots` +9 | `ResetPower`, `BestWeapon` (`stage1/rec/rzx-p1-00000`), `BufferToScreen` (`docs/integrate/rec/p1-shots`), `PowerDrain` (`stage1/rec/rzx-p1-04000`) |
| `$A014` | `PowerLevel` (`Variables`+2) | 1 | the weapon's power, 1-5 (the power bar; PowerGain never stores 6) | `FindShotSlot`, `PowerBarColour`, `PowerDrain`, `FireSpray` (`stage1/rec/rzx-p1-30000`), `FireWeapon` (`stage1/rec/rzx-p1-18000`) +2 | `ResetPower`, `PowerDrain` (`stage1/rec/rzx-p1-02000`), `PowerGain` (`stage1/rec/rzx-p1-00000`) |
| `$A015` | `PowerBarPtr` (`Variables`+3) | 2 | the HUD address of the power bar's end | `PowerBar`, `PowerDrain` (`stage1/rec/rzx-p1-04000`), `PowerGain` (`stage1/rec/rzx-p1-10000`) | `ResetPower`, `PowerDrain` (`stage1/rec/rzx-p1-04000`), `PowerGain` (`stage1/rec/rzx-p1-10000`) |
| `$A017` | `PassToggle` (`Variables`+5) | 1 | flips every pass (the animations run every other pass) | `AnimateCells`, `Attract`, `MainLoop`, `GameEntry` (`stage2/rec/p1-define`) | `Attract`, `BuildRoom`, `MainLoop`, `GameEntry` (`stage2/rec/p1-define`) |
| `$A018` | `PowerCount` (`Variables`+6) | 1 | power pods towards the next power level | `PowerDrain`, `PowerGain` (`stage1/rec/rzx-p1-00000`) | `NewGame`, `PowerDrain`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `PowerGain` (`stage1/rec/rzx-p1-00000`) |
| `$A019` | `RexCellPtr` (`Variables`+7) | 2 | Rex's place in the room grid (CellPointer `$A503`) | `CellsUnderRex`, `RexJump`, `RexWalk` | `MainLoop`, `GameEntry` (`stage2/rec/p1-define`) |
| `$A01B` | `ObjectCellPtr` (`Variables`+9) | 2 | the current object's place in the grid (ObjectCell `$C72B`) | `WalkLeft`, `DriftObject` (`stage1/rec/rzx-p1-18000`), `WalkRight` (`stage1/rec/rzx-p1-02000`) | `ObjectCell` |
| `$A01D` | `RoomCellPtr` (`Variables`+11) | 3 | DrawRoom's grid pointer | `DrawRoomCell`, `NextCellPtr` (`stage1/rec/rzx-p1-18000`) | `DrawRoom`, `DrawRoomCell`, `NextCellPtr` (`stage1/rec/rzx-p1-18000`) |
| `$A020` | `ObjectListPtr` (`Variables`+14) | 2 | the room's object list (RoomObjectLists) | `MakeObjects` | `ReadExits` |
| `$A022` | `HumanPicture` (`Variables`+16) | 6 | the human picture's offset by weapon (KillHumanPicture `$CE67`) | - | `KillHumanPicture` (`stage1/rec/rzx-p1-22000`) |
| `$A028` | `BoxX` (`Variables`+22) | 1 | PrintBoxed: the box's column | `PanelBox`, `PanelRow` | `PanelBox` |
| `$A029` | `BoxY` (`Variables`+23) | 1 | PrintBoxed: the box's line | `PanelBox` | `PanelBox` |
| `$A02A` | `BoxWidth` (`Variables`+24) | 1 | PrintBoxed: the box's width | `PanelBox`, `PanelLine` | `PanelBox` |
| `$A02B` | `BoxHeight` (`Variables`+25) | 1 | PrintBoxed: the box's height | `PanelBox` | `PanelBox` |
| `$A02C` | `SpawnLeft` (`Variables`+26) | 1 | the room spawns from the left | `SpawnFromLeft` | `ReadExits`, `SetSpawnLeft` (`stage1/rec/rzx-p1-02000`) |
| `$A02D` | `SpawnRight` (`Variables`+27) | 1 | the room spawns from the right | `SpawnFromRight` | `ReadExits`, `SetSpawnRight` |
| `$A02E` | `SpawnTop` (`Variables`+28) | 1 | the room spawns from the top | `SpawnFromTop` | `ReadExits`, `SetSpawnTop` |
| `$A02F` | `SmartBombSteps` (`Variables`+29) | 1 | the smart bomb's steps left (16) | `SmartBombStep` | `SmartBombMark`, `SmartBombStep`, `SmartBomb` (`stage1/rec/rzx-p1-00000`), `SmartBombFree` (`stage1/rec/rzx-p1-02000`) |
| `$A030` | `SmartBombOn` (`Variables`+30) | 1 | a smart bomb runs | `SmartBomb`, `SmartBombFree`, `SmartBombStep` | `NewGame`, `SmartBombMark`, `SmartBombStep`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `SmartBomb` (`stage1/rec/rzx-p1-00000`) +1 |
| `$A031` | `SmartBombPtr` (`Variables`+31) | 2 | the next object to kill | `SmartBombStep` | `SmartBombMark`, `SmartBombStep`, `SmartBomb` (`stage1/rec/rzx-p1-00000`), `SmartBombFree` (`stage1/rec/rzx-p1-02000`) |
| `$A033` | `SpriteMirror` (`Variables`+33) | 1 | DrawSprite: bit 7 a fixed frame, SpritePicture, the frame list ignored (mirroring, through MirrorTable `$AD5D`, is A not 0 at the call) | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-22000`) | `DeathAnimation`, `DrawRex`, `UpdateObject`, `DrawObject` (`stage1/rec/rzx-p1-08000`), `RexState` (`stage1/rec/rzx-p1-00000`) |
| `$A034` | `SpritePicture` (`Variables`+34) | 4 | DrawSprite: the picture | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`) | `DeathAnimation`, `UpdateObject`, `DrawObject` (`stage1/rec/rzx-p1-08000`) |
| `$A038` | `ObjectHitCount` (`Variables`+38) | 1 | the hits an object took | - | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A039` | `KillFlashPtr` (`Variables`+39) | 2 | the combo row cell lit by the latest hit (`$5843` + 3 a hit; at rest `$E9FF`) | `KillFlashFade`, `HitObjectHard` (`stage1/rec/rzx-p1-20000`) | `BuildRoom`, `KillObject`, `HitObject` (`stage1/rec/rzx-p1-02000`), `HitObjectHard` (`stage1/rec/rzx-p1-20000`), `ObjectFall` (`stage1/rec/rzx-p1-14000`) |
| `$A03B` | `ComboCount` (`Variables`+41) | 1 | kills in a row | `HitObjectHard` (`stage1/rec/rzx-p1-20000`) | `HitObject` (`stage1/rec/rzx-p1-02000`), `HitObjectHard` (`stage1/rec/rzx-p1-20000`) |
| `$A03C` | `ComboTimer` (`Variables`+42) | 2 | passes left for the next kill to count in the row | `HitObjectHard` (`stage1/rec/rzx-p1-20000`) | `KillObject`, `HitObject` (`stage1/rec/rzx-p1-02000`), `HitObjectHard` (`stage1/rec/rzx-p1-20000`), `ObjectFall` (`stage1/rec/rzx-p1-14000`) |
| `$A03E` | `Score` (`Variables`+44) | 2 | the score, in hundreds | `AddScore`, `LifeLost`, `ShowScore`, `CodePanel` (`stage2/rec/p1-code`) | `AddScore`, `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A040` | `RapidShotsOn` (`Variables`+46) | 1 | the 100 RAPID SHOTS bonus runs | `FireWeapon`, `MainLoop`, `GameEntry` (`stage2/rec/p1-define`) | `NewGame`, `BonusRoulette` (`stage1/rec/rzx-p1-50000`), `GameEntry` (`stage1/rec/rzx-p1-00000`), `FireGun` (code) |
| `$A041` | `RapidShotsLeft` (`Variables`+47) | 1 | its shots left | `FireWeapon` (`stage1/rec/rzx-p1-50000`) | `BonusRoulette` (`stage1/rec/rzx-p1-50000`), `FireWeapon` (`stage1/rec/rzx-p1-50000`) |
| `$A042` | `FadeStepIndex` (`Variables`+48) | 1 | the power pod's HUD flash step, `$FF` at rest (FadeStep `$9A4C`) | `FadeStep`, `HudSweep`, `PowerBar` | `NewGame`, `FadeStep` (`stage1/rec/rzx-p1-00000`), `GameEntry` (`stage1/rec/rzx-p1-00000`), `TakePowerPod` (`stage1/rec/rzx-p1-00000`) |
| `$A043` | `SpawnTimer` (`Variables`+49) | 1 | passes to the next random spawn | `SpawnRandom` | `ReadExits`, `SpawnRandom` |
| `$A044` | `SpawnPeriod` (`Variables`+50) | 1 | the room's spawn period | `SpawnRandom` | `ReadExits` |
| `$A045` | `ScriptSpawnStep` (`Variables`+51) | 1 | the scripted spawn's step (ScriptSpawn `$A9F4`), 0 off | `SpawnRandom`, `SpawnScripted`, `StartScriptSpawn` | `BuildRoom`, `SpawnScripted`, `StartScriptSpawn`, `StopObjectSpawn` (`stage1/rec/rzx-p1-04000`) |
| `$A046` | `ScriptSpawnTimer` (`Variables`+52) | 2 | passes to the next scripted spawn | `SpawnScripted` | `SpawnScripted`, `StartScriptSpawn` |
| `$A048` | `ScriptSpawnCount` (`Variables`+54) | 1 | scripted spawns made | `SpawnScripted` | `SpawnScripted`, `StartScriptSpawn` |
| `$A049` | `ShieldOn` (`Variables`+55) | 3 | the shield is on | `DrawRex`, `EnemyBulletsHitRex`, `CellsUnderRex` (`stage1/rec/rzx-p1-00000`), `ObjectHitsRex` (`stage1/rec/rzx-p1-00000`), `Recharge` (`stage1/rec/rzx-p1-04000`) +2 | `Dematerialise`, `LifeLost`, `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `ShieldDrain` (`stage1/rec/rzx-p1-24000`) +1 |
| `$A04C` | `ShieldKeyLatch` (`Variables`+58) | 1 | the down key is held (one toggle a press) | `ShieldToggle` (`stage1/rec/rzx-p1-00000`) | `MainLoop`, `GameEntry` (`stage2/rec/p1-define`), `ShieldToggle` (`stage1/rec/rzx-p1-00000`) |
| `$A04D` | `ShieldEnergy` (`Variables`+59) | 1 | the shield's energy, 0-99 | `ShowShield`, `CellsUnderRex` (`stage1/rec/rzx-p1-00000`), `CodePanel` (`stage2/rec/p1-code`), `Recharge` (`stage1/rec/rzx-p1-04000`), `ShieldDrain` (`stage1/rec/rzx-p1-00000`) +1 | `NewGame`, `RexDies`, `CellsUnderRex` (`stage1/rec/rzx-p1-00000`), `GameEntry` (`stage1/rec/rzx-p1-00000`), `Recharge` (`stage1/rec/rzx-p1-04000`) +1 |
| `$A04E` | `ShieldDrainRate` (`Variables`+60) | 1 | passes for one unit of energy while the shield is on | `ShieldDrain` (`stage1/rec/rzx-p1-00000`) | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `ShieldDrain` (`stage1/rec/rzx-p1-00000`), `ShieldDrainFast` (`stage1/rec/rzx-p1-00000`) |
| `$A04F` | `WeaponIcon` (`Variables`+61) | 1 | the gun held (always 1): BestWeapon reads it as entry 0 before HasDoubleFire .. HasSpray | `DrawWeaponIcon`, `BestWeapon` (`stage1/rec/rzx-p1-00000`), `PowerDrain` (`stage1/rec/rzx-p1-04000`) | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A050` | `HasDoubleFire` (`Variables`+62) | 1 | the weapons held: double fire | `DrawWeaponIcon`, `BestWeapon` (`stage1/rec/rzx-p1-10000`), `CodePanel` (`stage2/rec/p1-code`), `PowerDrain` (`stage1/rec/rzx-p1-14000`) | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `GiveDoubleFire` (`stage1/rec/rzx-p1-00000`) |
| `$A051` | `HasLaser` (`Variables`+63) | 1 | laser | `DrawWeaponIcon`, `BestWeapon` (`stage1/rec/rzx-p1-18000`), `CodePanel` (`stage2/rec/p1-code`), `PowerDrain` (`stage1/rec/rzx-p1-22000`) | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `GiveLaser` (`stage1/rec/rzx-p1-10000`) |
| `$A052` | `HasMultiple` (`Variables`+64) | 1 | multiple (drones) | `DrawWeaponIcon`, `BestWeapon` (`stage1/rec/rzx-p1-18000`), `CodePanel` (`stage2/rec/p1-code`), `PowerDrain` (`stage1/rec/rzx-p1-40000`) | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `GiveMultiple` (`stage1/rec/rzx-p1-18000`) |
| `$A053` | `HasSpray` (`Variables`+65) | 1 | spray | `DrawWeaponIcon`, `BestWeapon` (`stage1/rec/rzx-p1-30000`), `CodePanel` (`stage2/rec/p1-code`) | `NewGame`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`), `GiveSpray` (`stage1/rec/rzx-p1-26000`) |
| `$A054` | `EnemyShotKind` (`Variables`+66) | 1 | the kind of the next enemy bullet | `EnemyShot`, `EnemyShotFrom` (`stage1/rec/rzx-p1-20000`) | `ShootBoth`, `ShootForward`, `SwingGun`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `MineBurst` (`stage1/rec/rzx-p1-20000`) +1 |
| `$A055` | `Dying` (`Variables`+67) | 1 | Rex is dying | `AddScore`, `EnemyBulletsHitRex`, `MainLoop`, `ObjectHitsRex`, `RexState` +3 | `LifeLost`, `NewGame`, `RexDies`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A056` | `DeathTimer` (`Variables`+68) | 1 | the death animation's passes left | `DeathAnimation` | `DeathAnimation`, `RexDies`, `BufferToScreen` (`docs/integrate/rec/p1-shots`) |
| `$A057` | `DeathShardPtr` (`Variables`+69) | 2 | the shards' path pointer | `DeathAnimation`, `ShardBack`, `ShardNext` | `RexDies`, `ShardBack`, `ShardNext`, `BufferToScreen` (`docs/integrate/rec/p1-shots`) |
| `$A059` | `RestartX` (`Variables`+71) | 1 | the restart point: X | `LifeLost` | `NewGame`, `SaveRestart`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A05A` | `RestartY` (`Variables`+72) | 1 | Y | `LifeLost` | `NewGame`, `SaveRestart`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A05B` | `RestartRoom` (`Variables`+73) | 1 | room | `LifeLost` | `NewGame`, `SaveRestart`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A05C` | `RestartFacing` (`Variables`+74) | 1 | facing | - | `BuildRoom`, `NewGame`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A05D` | `RexPresent` (`Variables`+75) | 1 | 1 when Rex is fully there (he moves and fires), 0 while he materialises or after he vanished | `Dematerialise`, `FireWeapon`, `RexAppears`, `RexState`, `SparkleUpdate` | `Dematerialise`, `Materialise`, `RexAppears`, `SparkleDraw`, `SparkleUpdate` +3 |
| `$A05E` | `SparkleCount` (`Variables`+76) | 1 | the sparkle's cell mask step (18 to 0 in, 0 to 18 out) | `SparkleUpdate`, `SparkleOut` (code) | `Dematerialise`, `RexAppears`, `SparkleUpdate`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `SparkleOut` (code) |
| `$A05F` | `SparkleOn` (`Variables`+77) | 1 | the sparkle's dots run | `DrawRoom`, `SparkleDraw`, `SparkleIfOn` (code) | `Dematerialise`, `Materialise`, `SparkleDraw`, `BufferToScreen` (`docs/integrate/rec/p1-shots`) |
| `$A060` | `SparkleMode` (`Variables`+78) | 1 | the sparkle is shown | `EnemyBulletsHitRex`, `ObjectHitsRex`, `ShieldToggle`, `SparkleUpdate`, `FireWeapon` (`stage1/rec/rzx-p1-18000`) +1 | `Dematerialise`, `Materialise`, `SparkleDraw`, `SparkleUpdate`, `BufferToScreen` (`docs/integrate/rec/p1-shots`) +1 |
| `$A061` | `SparkleTimer` (`Variables`+79) | 1 | the dots' passes left | `SparkleDraw` | `Dematerialise`, `Materialise`, `SparkleDraw`, `SparkleUpdate`, `BufferToScreen` (`docs/integrate/rec/p1-shots`) +2 |
| `$A062` | `Vanishing` (`Variables`+80) | 1 | 1: the sparkle takes Rex out (a death), 0: it brings him in | `SparkleDraw`, `SparkleUpdate` | `Dematerialise`, `Materialise`, `BufferToScreen` (`docs/integrate/rec/p1-shots`) |
| `$A063` | `Lives` (`Variables`+81) | 1 | lives left (4 at the start, up to 9) | `DeathAnimation`, `LifeLost`, `RexDies`, `ShowLives`, `CodePanel` (`stage2/rec/p1-code`) +1 | `LifeLost`, `NewGame`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `ExtraLife` (`stage1/rec/rzx-p1-06000`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A064` | `SweepPos` (`Variables`+82) | 1 | the HUD sweep's position | `HudSweep` | `HudSweep`, `NewGame`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A065` | `SweepCount` (`Variables`+83) | 1 | sweeps made at this width | `HudSweep`, `TitleMenu` | `HudSweep`, `ResetSweep`, `TitleMenu`, `BufferToScreen` (`docs/integrate/rec/p1-shots`) |
| `$A066` | `SweepDir` (`Variables`+84) | 1 | the sweep's direction | `HudSweep` | `HudSweep`, `NewGame`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A067` | `SweepWidth` (`Variables`+85) | 1 | the sweep's width (12 after ResetSweep; Rex dies when it would drop to 0) | `HudSweep` | `HudSweep`, `ResetSweep`, `BufferToScreen` (`docs/integrate/rec/p1-shots`) |
| `$A068` | `FireDelay` (`Variables`+86) | 1 | passes between shots | `FireLaser` (`stage1/rec/rzx-p1-14000`), `FireWeapon` (`stage1/rec/rzx-p1-18000`), `MoveSplitShot` (`stage1/rec/rzx-p1-14000`) | `NewGame`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`), `PowerGain` (`stage1/rec/rzx-p1-00000`) |
| `$A069` | `AnimCount1` (`Variables`+87) | 1 | animation counters of the cells | `CopyFrame` | `CopyFrame`, `NewGame`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A06A` | `AnimCount2` (`Variables`+88) | 1 | - | `CopyFrame` | `CopyFrame`, `NewGame`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A06B` | `AnimCount3` (`Variables`+89) | 1 | - | `CopyFrame` | `CopyFrame`, `NewGame`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A06C` | `Bombs` (`Variables`+90) | 2 | smart bombs left | `ShowBombs`, `SmartBomb`, `CodePanel` (`stage2/rec/p1-code`), `DrawHud` (`stage1/rec/rzx-p1-64000`), `TakeBombPod` (`stage1/rec/rzx-p1-52000`) | `NewGame`, `SmartBomb`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `GameEntry` (`stage1/rec/rzx-p1-00000`), `TakeBombPod` (`stage1/rec/rzx-p1-52000`) |
| `$A06E` | `WeaponRank` (`Variables`+92) | 1 | the best weapon held | `PowerDrain`, `BestWeapon` (`stage1/rec/rzx-p1-00000`), `PowerGain` (`stage1/rec/rzx-p1-10000`) | `ResetPower`, `BufferToScreen` (`docs/integrate/rec/p1-shots`), `PowerDrain` (`stage1/rec/rzx-p1-04000`), `PowerGain` (`stage1/rec/rzx-p1-10000`) |
| `$A06F` | `BonusRoll` (`Variables`+93) | 2 | the bonus roulette's position | `BonusRoulette` (`stage1/rec/rzx-p1-50000`) | `BonusRoulette` (`stage1/rec/rzx-p1-50000`) |
| `$A071` | `Immune` (`Variables`+95) | 1 | Rex cannot die (never set in play) | `RexDies` | `NewGame`, `BufferToScreen` (`docs/integrate/rec/p1-speedup`), `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A072` | `SpeedUp` (`Variables`+96) | 1 | the SPEED UP bonus: passes left | `WalkLeftKey`, `WalkRightKey` | `NewGame`, `BonusRoulette` (`docs/integrate/rec/p1-speedup`), `GameEntry` (`stage1/rec/rzx-p1-00000`), `SpeedUpTick` (`docs/integrate/rec/p1-speedup`) |
| `$A073` | `SpeedUpPhase` (`Variables`+97) | 3 | - | `SpeedUpTick` (`docs/integrate/rec/p1-speedup`) | `NewGame`, `BonusRoulette` (`docs/integrate/rec/p1-speedup`), `GameEntry` (`stage1/rec/rzx-p1-00000`), `SpeedUpTick` (`docs/integrate/rec/p1-speedup`) |
| `$A076` | `ExtraLifeCount` (`Variables`+100) | 4 | hundreds of points towards the next life | `AddScore` | `AddScore`, `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A07A` | `OnLift` (`Variables`+104) | 1 | Rex stands on a ladder or lift | `DrawRex`, `RexState` (`stage1/rec/rzx-p1-00000`) | `CellsUnderRex` |
| `$A07B` | `ShotSide` (`Variables`+105) | 1 | FindShotSlot: 0 Rex's bullets, 1 the enemies' | `FindSlot`, `SetupShot`, `EnemyShot` (`stage2/rec/p1-gameover`), `FindEnemySlot` (`stage2/rec/p1-gameover`), `FindShotSlot` (`stage2/rec/p1-code`) +1 | `FindEnemySlot`, `FindShotSlot` |
| `$A07C` | `AnimCount4` (`Variables`+106) | 1 | - | `CopyFrame` | `CopyFrame`, `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A07D` | `BonusDelay` (`Variables`+107) | 2 | - | `BonusRoulette` (`stage1/rec/rzx-p1-50000`) | `BonusRoulette` (`stage1/rec/rzx-p1-50000`) |
| `$A07F` | `RollFrame` (`Variables`+109) | 2 | the menu roll call: the frame | `RollCallFrame`, `RollCallSprite` | `RollCallFrame`, `TitleMenu` |
| `$A081` | `RollPtr` (`Variables`+111) | 2 | the roll call's sprite record | `RollCallFrame`, `RollCallSprite` | `RollCallFrame`, `RollCallSprite` |
| `$A083` | `RollTextPtr` (`Variables`+113) | 2 | the roll call's text | `TitleMenu` | `TitleMenu`, `RollCallText` (code) |
| `$A085` | `RollShow` (`Variables`+115) | 1 | the roll call shows a sprite | `RollCallSprite`, `TitleMenu` | `TitleMenu` |
| `$A086` | `RollTextNext` (`Variables`+116) | 2 | the next roll call text record | `TitleMenu`, `RollCallText` (code) | `TitleMenu`, `RollCallNext` (code) |
| `$A088` | `SpawnKind` (`Variables`+118) | 1 | the kind the room spawns | `SpawnObject` | `ReadExits` |
| `$A089` | `HumansKilled` (`Variables`+119) | 2 | the people killed (the game over panel) | `KillHuman`, `LifeLost` | `KillHuman`, `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A08B` | `HiScore` (`Variables`+121) | 2 | the high score, in hundreds | `LifeLost` | `GameEntry`, `LifeLost` (`stage2/rec/p1-gameover`) |
| `$A08D` | `RoomRight` (`Variables`+123) | 1 | the room's exits (RoomExits `$B133`): right | `ExitRight` | `ReadExits`, `BufferToScreen` (`docs/rxA/rec/p1-rooms238`) |
| `$A08E` | `RoomUp` (`Variables`+124) | 1 | up | `ExitTop` (`stage1/rec/rzx-p1-32000`), `RexJump` (`stage1/rec/rzx-p1-04000`) | `ReadExits` |
| `$A08F` | `RoomDown` (`Variables`+125) | 1 | down | `RexFall` (`stage1/rec/rzx-p1-04000`) | `ReadExits` |
| `$A090` | `RoomLeft` (`Variables`+126) | 1 | left | `ExitLeft` (`stage1/rec/rzx-p1-18000`) | `ReadExits` |
| `$A091` | `RexSpeed` (`Variables`+127) | 1 | Rex's sideways speed | `RexWalk` | `LifeLost`, `NewGame`, `RexWalk`, `WalkLeftKey`, `WalkRightKey` +2 |
| `$A092` | `ObjectCount` (`Variables`+128) | 1 | the room's object records | `SpawnRandom`, `SpawnScripted`, `UpdateObjects`, `EndScriptSpawn` (`stage1/rec/rzx-p1-04000`), `FindFreeObject` (`stage1/rec/rzx-p1-18000`) | `ReadExits`, `KillObject` (`stage1/rec/rzx-p1-24000`), `KillScore` (code) |
| `$A093` | `Temp1` (`Variables`+129) | 2 | scratch and inputs | `BlowUp`, `BufferToScreen`, `ClearBuffer`, `CopyFrame`, `DeathAnimation` +26 | `BufferToScreen`, `ClearBuffer`, `CopyFrame`, `DrawCharBlock`, `DrawRoomChar` +34 |
| `$A095` | `Temp2` (`Variables`+131) | 2 | - | `BlowUp`, `CopyFrame`, `DeathAnimation`, `DrawAnimCells`, `DrawCharBlock` +15 | `CopyFrame`, `DrawAnimCells`, `DrawCharBlock`, `DrawRoomCell`, `EnemyShot` +15 |
| `$A097` | `Temp3` (`Variables`+133) | 2 | - | `MoveShots`, `PrintChar`, `PrintText`, `SetupShot`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) +4 | `EnemyShot`, `MoveShots`, `PrintText`, `RexShot`, `ShootersFire` +6 |
| `$A099` | `Temp4` (`Variables`+135) | 6 | - | `SetupShot`, `EnemyShot` (`stage2/rec/p1-gameover`), `RexShot` (`stage2/rec/p1-code`) | `EnemyShot`, `RexShot`, `ShootFromObject`, `EnemyShotFrom` (`stage1/rec/rzx-p1-20000`), `FireDouble` (`stage1/rec/rzx-p1-04000`) +2 |
| `$A09F` | `BoxAttr` (`Variables`+141) | 2 | PrintBoxed: the box's attribute | `PanelBox` | `PanelBox` |
| `$A0A1` | `RandomSeed` (`Variables`+143) | 2 | Random `$A375`'s seed | `Random`, `Random2` | `NewGame`, `Random`, `Random2`, `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A0A3` | `RandomSeed2` (`Variables`+145) | 1 | Random2 `$A388`'s seed | `Random2` | `NewGame`, `Random2`, `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A0A4` | `DigitTemp` (`Variables`+146) | 2 | ToDigits `$A402`'s work | `DigitOf` | `DigitOf`, `ToDigits` |
| `$A0A6` | `Digits` (`Variables`+148) | 5 | ToDigits `$A402`'s five digits, units first | `PrintDigits`, `CodePanel` (`stage2/rec/p1-code`) | `ToDigits` |
| `$A0AB` | `DefinePort` (`Variables`+153) | 2 | DEFINE: the port of the key read | `SetDown`, `SetFire`, `SetLeft`, `SetRight`, `SetUp` | `ScanKey`, `ChooseCursor` (`stage2/rec/p1-cursor`), `ChooseKempston` (`stage2/rec/p1-kempston`), `ChooseSinclair` (`stage1/rec/rzx-p1-00000`) |
| `$A0AD` | `DefineBit` (`Variables`+155) | 1 | DEFINE: the BIT opcode's second byte (`$47` + 8 x bit) | `SetDown`, `SetFire`, `SetLeft`, `SetRight`, `SetUp` | `ScanKey`, `ChooseCursor` (`stage2/rec/p1-cursor`), `ChooseKempston` (`stage2/rec/p1-kempston`), `ChooseSinclair` (`stage1/rec/rzx-p1-00000`) |
| `$A0AE` | `ControlXor` (`Variables`+156) | 1 | XORed with every port read: 0 keys, `$FF` Kempston | `ReadDown`, `ReadFire`, `ReadLeft`, `ReadRight`, `ReadUp` | `GameEntry`, `KeysConfirm`, `ChooseCursor` (`stage2/rec/p1-cursor`), `ChooseKempston` (`stage2/rec/p1-kempston`), `ChooseSinclair` (`stage1/rec/rzx-p1-00000`) |
| `$A0AF` | `SpriteX` (`Variables`+157) | 1 | DrawSprite: X in pixels | `BufferAddress`, `CellPointer`, `DrawShard`, `DrawSprite`, `SpawnObject` +4 | `BlowUp`, `DeathAnimation`, `DrawRex`, `DrawShard`, `DrawSprite` +16 |
| `$A0B0` | `SpriteY` (`Variables`+158) | 1 | Y in lines | `BufferAddress`, `CellPointer`, `DrawSprite`, `SpawnObject`, `DrawMirrored` (`stage1/rec/rzx-p1-22000`) | `BlowUp`, `DeathAnimation`, `DrawRex`, `DrawShard`, `MainLoop` +14 |
| `$A0B1` | `SpriteWidth` (`Variables`+159) | 1 | width in bytes | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-22000`) | `DeathAnimation`, `DrawRex`, `UpdateObject`, `DrawObject` (`stage1/rec/rzx-p1-08000`), `RexState` (`stage1/rec/rzx-p1-00000`) |
| `$A0B2` | `SpriteHeight` (`Variables`+160) | 1 | height in lines | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-22000`) | `DeathAnimation`, `DrawRex`, `UpdateObject`, `DrawObject` (`stage1/rec/rzx-p1-08000`), `RexState` (`stage1/rec/rzx-p1-00000`) |
| `$A0B3` | `RexFrame` (`Variables`+161) | 3 | Rex's walking frame | - | `LifeLost`, `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A0B6` | `RexX` (`Variables`+164) | 1 | Rex: X in pixels | `DeathAnimation`, `DrawRex`, `EnemyBulletsHitRex`, `MainLoop`, `ObjectHitsRex` +15 | `ExitRight`, `LifeLost`, `NewGame`, `RexWalk`, `BufferToScreen` (`docs/rxA/rec/p1-rooms238`) +2 |
| `$A0B7` | `RexY` (`Variables`+165) | 1 | Y in lines | `DeathAnimation`, `DrawRex`, `EnemyBulletsHitRex`, `MainLoop`, `ObjectHitsRex` +14 | `LifeLost`, `NewGame`, `RexFall`, `RexJump`, `SparkleDraw` +2 |
| `$A0B8` | `Room` (`Variables`+166) | 1 | the room Rex is in | `BuildRoom`, `ChangeRoom`, `DrawRoom`, `LifeLost`, `ReadExits` +1 | `Attract`, `ExitRight`, `LifeLost`, `NewGame`, `ExitLeft` (`stage1/rec/rzx-p1-18000`) +4 |
| `$A0B9` | `RoomColumn` (`Variables`+167) | 2 | DrawRoom's column | `DrawRoomCell` | `DrawRoom`, `DrawRoomCell` |
| `$A0BB` | `RexFacing` (`Variables`+169) | 1 | 0 right, 1 left | `DrawRex`, `MainLoop`, `RexFall`, `RexShot`, `RexWalk` +4 | `LifeLost`, `NewGame`, `WalkLeftKey`, `WalkRightKey`, `GameEntry` (`stage1/rec/rzx-p1-00000`) |
| `$A0BC` | `FallSpeed` (`Variables`+170) | 1 | Rex's fall speed | `DrawRex`, `RexFall`, `RexWalk`, `StartJump`, `RexState` (`stage1/rec/rzx-p1-00000`) +1 | `LifeLost`, `NewGame`, `RexFall`, `CellsUnderRex` (`stage1/rec/rzx-p1-32000`), `ExitTop` (`stage1/rec/rzx-p1-32000`) +3 |
| `$A0BD` | `Jumping` (`Variables`+171) | 3 | Rex is jumping | `DrawRex`, `RexFall`, `RexJump`, `RexWalk`, `StartJump` +2 | `LifeLost`, `NewGame`, `RexJump`, `StartJump`, `ExitTop` (`stage1/rec/rzx-p1-32000`) +3 |
| `$A0C0` | `JumpPtr` (`Variables`+174) | 2 | the jump's step in JumpSteps `$D0D8` | `RexJump` | `RexJump`, `StartJump` |
| `$A0C2` | `AttractFlag` (`Variables`+176) | 1 | the attract mode runs | `Attract` | `Attract`, `GameEntry` |
| `$A0C3` | `AttractTimer` (`Variables`+177) | 1 | passes left in the attract room | `Attract` | `Attract` |

## hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A1F1` | `HudIconParams` | 6 | DrawCharBlock's inline parameters: picture `$8CCA` (self-written), column 25 (self-written), line 0, 2 x 16 | `DrawCharBlock`, `NextHudIcon` | `DrawBombIcons`, `DrawHudIcon`, `NextHudIcon` |
| `$A202` | `BombIcons` | 16 | The bomb icons by bombs left (0-3): three offsets each, `$A0` empty and `$C0` full | `DrawHudIcon` | - |
| `$A233` | `WeaponIconParams` | 6 | DrawCharBlock's inline parameters: picture `$8C0A` (self-written), column 1 (self-written), line 0, 2 x 16 | `DrawCharBlock`, `NextWeaponIcon` | `DrawWeaponIcon`, `NextWeaponIcon`, `ShowWeaponIcons` |
| `$A24C` | `HudTexts` | 62 | The HUD's texts: a row of "#", the figures 0000000:99:3, the icon row ("]\ ^\ _\ @\ ..." are the HUD's own characters) | `PrintChar`, `PrintText` | - |
| `$A368` | `UnusedRandom` | 13 | Leftover: LD HL,(`$A0A1`): INC HL: LD A,H: AND `$3F`: LD H,A: LD A,(HL): LD (`$A0A1`),HL: RET, a random routine nothing calls. Known only from the code: the bytes are a routine that walks RandomSeed through the ROM's first 16 K (the ROM as noise), Random `$A375`'s older form. | - | - |

## grid

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A5F4` | `FramesList3` | 14 of 52 | The frame lists of the animated characters: restart marker (`$A5F4`), character 250 (`$A602`), `$A60C`, `$A61A` | `CopyFrame` | - |
| `$A602` | `FramesList2` (`FramesList3`+14) | 10 | - | `CopyFrame` | - |
| `$A60C` | `FramesList1` (`FramesList3`+24) | 14 | - | `CopyFrame` | - |
| `$A61A` | `FramesList4` (`FramesList3`+38) | 14 | - | `CopyFrame` | - |
| `$A6CB` | `DroneOrbit` | 128 of 192 | The drones' orbit: 64 X, Y offset pairs round Rex, then the drone pictures at DronePicture `$A74B` | `UpdateDrones` (`stage1/rec/rzx-p1-18000`) | - |
| `$A74B` | `DronePicture` (`DroneOrbit`+128) | 64 | the drone's pictures | `UpdateDrones` (`stage1/rec/rzx-p1-18000`) | - |

## weapons

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B436` | `SprayDirections` | 32 | The spray's 8 directions: [dX word][dY][..], read by FireSpray and by the mine layer's burst (MineBurst `$C03A`) | `SetShotDirection` (`stage1/rec/rzx-p1-20000`) | - |
| `$B943` | `SparkMasks` | 40 | The spark's masks by count: `$00`, `$04`, `$44`, `$54`, `$55`, `$D5`, `$DD`, `$DF`, then `$FF` | `MoveSparkShot` (`stage1/rec/rzx-p1-14000`) | - |

## codepanel

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A884` | `CodeText` | 8 of 25 | The CODE panel: [attribute 6][column 6][line `$50`] "CODE:" and 16 places for the digits, 0 | `CodePanel` (`stage2/rec/p1-code`), `PrintBoxed` (`stage2/rec/p1-code`), `PrintChar` (`stage2/rec/p1-code`), `PrintText` (`stage2/rec/p1-code`) | `CodePanel` (`stage2/rec/p1-code`) |
| `$A88C` | `CodeDigits` (`CodeText`+8) | 17 | the 16 places: 0 double fire, 1 score thousands, 2 spray, 3 lives, 4 laser, 5 score hundreds, 6 multiple, 7 score units, 8 shield units, 9 score tens, 10 bombs, 11 shield tens, 12 score ten-thousands, each written 9 - digit; 13-15 the checksum's units, hundreds and tens (the sum of the 13 shown digits) | `CodePanel` (`stage2/rec/p1-code`), `PrintBoxed` (`stage2/rec/p1-code`), `PrintChar` (`stage2/rec/p1-code`), `PrintText` (`stage2/rec/p1-code`) | `CodePanel` (`stage2/rec/p1-code`) |
| `$A90C` | `AttractRooms` | 9 | The attract mode's rooms: 6, 17, 1, 20, 10, 23, 29, 32, then `$FF` (again) | `Attract` | - |

## tables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A9AF` | `BeamPath` | 26 of 29 | The long bullet's path (bullet type 7, MoveBeam `$B7FC`): Y offset, picture pairs, then `$1E` and the beam's end records at BeamEnd `$A9C9` | `MoveShots`, `MoveBeam` (`stage1/rec/rzx-p1-00000`) | - |
| `$A9C9` | `BeamEnd` (`BeamPath`+26) | 3 | the beam's last frames | `MoveShots`, `MoveBeam` (`stage1/rec/rzx-p1-00000`) | - |
| `$A9CC` | `KeyNames` | 40 | The key characters of the 40 keys in the order of KeyPorts `$E0E0` (CAPS as "-", ENTER "+", SYMBOL "."; key 0 also shows as "-"): DEFINE echoes them. ScanKey `$DBAE` indexes it by half-row x 5 + bit. "1"-"5" are the last half-row; SPACE and H are refused (the smart bomb and pause keys). | `ScanKey` | - |
| `$A9F4` | `ScriptSpawn` | 26 | The scripted spawn of rooms 2, 3, 4, 6 and 20: `$1E` then records [kind `$85`/`$83`/`$84`][X `$E8`][Y `$12`][delay 8], `$FF` ends | `MakeObject`, `MakeObjectIY`, `SpawnScripted`, `StartScriptSpawn` | - |
| `$AA0E` | `ShardPaths` | 96 | The explosion's six shards (BlowUp `$BD6B`): 8 X, Y offset pairs each, `$FF` ends | `DrawShard` | - |
| `$AA6E` | `ShardPictures` | 64 | The explosion shards' pictures, 8 bytes each (DrawShard `$BF66`) | `OrChar` | - |
| `$AAAE` | `GameTexts` | 63 of 303 | The game's text records: [attribute][column][line] text, 0. PhaseOneText (3 records: PHASE ONE:PROCEED / ON FOOT THROUGH / UNDERGROUND COMPLEX), GameOverText, HiScoreText, HumansKilledText, PressFireText (2: PRESS FIRE / TO BEGIN), the bonus panels (SPEED UP, SHIELD LOSS, 1000 BONUS, ENERGY LOSS, 100 RAPID SHOTS) and the weapon panels, each after a flag byte that keeps it to one showing (DOUBLE FIRE, LASER, MULTIPLE, SPRAY). A ":" prints as "-" in the font. | `PrintBoxed`, `PrintChar`, `PrintText`, `WeaponPanel` (`stage1/rec/rzx-p1-00000`) | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `WeaponPanel` (`stage1/rec/rzx-p1-00000`) |
| `$AAED` | `GameOverText` (`GameTexts`+63) | 13 | GAME OVER | `PrintBoxed`, `PrintChar`, `PrintText` | - |
| `$AAFA` | `HiScoreText` (`GameTexts`+76) | 20 | HI:SCORE 0000000 | `PrintBoxed`, `PrintChar`, `PrintText` | - |
| `$AB0E` | `HumansKilledText` (`GameTexts`+96) | 23 | HUMANS KILLED:00000 | `PrintBoxed`, `PrintChar`, `PrintText` | - |
| `$AB25` | `PressFireText` (`GameTexts`+119) | 28 | PRESS FIRE / TO BEGIN | `PrintBoxed`, `PrintChar`, `PrintText` | - |
| `$AB41` | `BonusTexts` (`GameTexts`+147) | 19 | the bonus panels, 19 bytes each: SPEED UP | `PrintBoxed` (`stage1/rec/rzx-p1-50000`), `PrintChar` (`stage1/rec/rzx-p1-50000`), `PrintText` (`stage1/rec/rzx-p1-50000`) | - |
| `$AB54` | `ShieldLossText` (`GameTexts`+166) | 19 | SHIELD LOSS | `PrintChar` (`stage1/rec/rzx-p1-56000`), `PrintText` (`stage1/rec/rzx-p1-56000`) | - |
| `$AB67` | `BonusPointsText` (`GameTexts`+185) | 19 | 1000 BONUS | `PrintChar` (`stage1/rec/rzx-p1-56000`), `PrintText` (`stage1/rec/rzx-p1-56000`) | - |
| `$AB7A` | `EnergyLossText` (`GameTexts`+204) | 19 | ENERGY LOSS | `PrintChar` (`stage1/rec/rzx-p1-50000`), `PrintText` (`stage1/rec/rzx-p1-50000`) | - |
| `$AB8D` | `RapidShotsText` (`GameTexts`+223) | 19 | 100 RAPID SHOTS | `PrintChar` (`stage1/rec/rzx-p1-50000`), `PrintText` (`stage1/rec/rzx-p1-50000`) | - |
| `$ABA0` | `DoubleFireText` (`GameTexts`+242) | 17 | the flag (shown once), then DOUBLE FIRE | `PrintBoxed` (`stage1/rec/rzx-p1-00000`), `PrintChar` (`stage1/rec/rzx-p1-00000`), `PrintText` (`stage1/rec/rzx-p1-00000`), `WeaponPanel` (`stage1/rec/rzx-p1-00000`) | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `WeaponPanel` (`stage1/rec/rzx-p1-00000`) |
| `$ABB1` | `LaserText` (`GameTexts`+259) | 11 | flag, LASER | `PrintBoxed` (`stage1/rec/rzx-p1-10000`), `PrintChar` (`stage1/rec/rzx-p1-10000`), `PrintText` (`stage1/rec/rzx-p1-10000`), `WeaponPanel` (`stage1/rec/rzx-p1-10000`) | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `WeaponPanel` (`stage1/rec/rzx-p1-10000`) |
| `$ABBC` | `MultipleText` (`GameTexts`+270) | 14 | flag, MULTIPLE | `PrintBoxed` (`stage1/rec/rzx-p1-18000`), `PrintChar` (`stage1/rec/rzx-p1-18000`), `PrintText` (`stage1/rec/rzx-p1-18000`), `WeaponPanel` (`stage1/rec/rzx-p1-18000`) | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `WeaponPanel` (`stage1/rec/rzx-p1-18000`) |
| `$ABCA` | `SprayText` (`GameTexts`+284) | 11 | flag, SPRAY | `PrintBoxed` (`stage1/rec/rzx-p1-26000`), `PrintChar` (`stage1/rec/rzx-p1-26000`), `PrintText` (`stage1/rec/rzx-p1-26000`), `WeaponPanel` (`stage1/rec/rzx-p1-26000`) | `NewGame`, `GameEntry` (`stage1/rec/rzx-p1-00000`), `WeaponPanel` (`stage1/rec/rzx-p1-26000`) |
| `$ABD5` | `PixelMasks` (`GameTexts`+295) | 8 | `$80`, `$40`, ... `$01`: a pixel's mask by X & 7 | - | - |
| `$ABDD` | `ScreenLineTable` | 48 of 384 | The screen address of each of the 192 pixel lines (PrintChar, PrintDigits, PanelBox, DrawCharBlock) | `DrawCharBlock`, `PanelRow`, `PrintDigits`, `PrintText`, `SaveScreen` (`stage1/rec/rzx-p1-00000`) | - |
| `$AC0D` | `ScreenLines` (`ScreenLineTable`+48) | 336 | line 24 on: the play area's 168 lines, BufferToScreen's list | `DrawCharBlock`, `PanelRow`, `PrintDigits`, `PrintText`, `SaveScreen` (`stage1/rec/rzx-p1-00000`) | - |
| `$AD5D` | `MirrorTable` | 256 | Each byte with its bits reversed: DrawMirrored `$B2C1` draws a picture facing left through it | `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-22000`) | - |
| `$AE5D` | `ShiftFrames` | 8 of 112 | The pictures' frame lists: 8 offsets each, one a pixel phase (X & 7), into a pre-shifted picture. ShiftFrames (`$00` `$00` `$30` `$30` `$60` `$60` `$90` `$90`: a 3 x 16 picture shifted every 2 pixels) for Rex and most objects; ShiftFrames2 `$AE65` Rex jumping; `$AE6D`, `$AE75`, `$AE7D`, `$AE85` the other sizes. | `AnimateCells`, `DrawSprite`, `DrawMirrored` (`stage1/rec/rzx-p1-22000`) | - |
| `$AE65` | `ShiftFrames2` (`ShiftFrames`+8) | 8 | - | `DrawMirrored` (`stage1/rec/rzx-p1-22000`), `DrawSprite` (`stage1/rec/rzx-p1-00000`) | - |
| `$AE6D` | `ShiftFrames3` (`ShiftFrames`+16) | 8 | - | `DrawSprite` (`stage1/rec/rzx-p1-18000`) | - |
| `$AE75` | `ShiftFrames4` (`ShiftFrames`+24) | 8 | - | `DrawSprite` (`stage1/rec/rzx-p1-04000`) | - |
| `$AE7D` | `ShiftFrames5` (`ShiftFrames`+32) | 8 | - | `DrawSprite` (`stage1/rec/rzx-p1-04000`) | - |
| `$AE85` | `ShiftFrames6` (`ShiftFrames`+40) | 8 | - | `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-02000`) | - |
| `$AE8D` | `AnimFramesA` (`ShiftFrames`+48) | 32 | characters 252-255 on the passes with PassToggle 0: 4 x 8 bytes | `AnimateCells` | - |
| `$AEAD` | `AnimFramesB` (`ShiftFrames`+80) | 32 | characters 252-255 on the other passes: 4 x 8 bytes | `AnimateCells` | - |
| `$AECD` | `RoomObjectLists` | 614 | The rooms' object lists: a header [spawn sides: bit 7 top, 6 right, 5 left][spawn period][spawn kind] (ReadExits `$C8EF`), then up to 16 records [kind][X][Y] (MakeObjects `$CB52`), `$FF` ends | `MakeObject`, `MakeObjectIY`, `MakeObjects`, `ReadExits` | - |
| `$B133` | `RoomExits` | 210 | The exits of the rooms 0-34: up, right, down, left (0 none, 99 the end of part 1), then the word of the room's object list. ReadExits `$C8EF` reads Room x 6. Room 0's record has no exits but room 1 to the right; the game starts in room 0. | `ReadExits` | - |

## objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BE53` | `BigGunShots` | 8 | The big gun's shot timings: `$10`, `$20`, `$22`, `$19`, `$1D`, `$31`, `$34`, `$FF` | `BigGun` (`stage1/rec/rzx-p1-22000`) | - |
| `$BECB` | `SwingGunFrames` | 8 | The swing gun's picture offsets by angle: `$00`, `$20`, `$40`, `$60`, `$80`, `$60`, `$40`, `$20` | `SwingGun` | - |
| `$BF5B` | `PodFrames` | 11 | The pod's frame offsets: `$00-$A0` and back, `$FF` | `AnimatePod` | - |
| `$BFE7` | `FlashAttrs` | 8 | The attributes of the explosion's flash: `$02`, `$03`, `$06`, `$42`, `$43`, `$46`, `$06`, `$02` | `FlashCells` | - |
| `$C149` | `Signs` | 4 | `$FF`, `$01`, `$FF`, `$01` | `RandomSign` (`stage1/rec/rzx-p1-04000`) | - |
| `$C25A` | `ScannerFrames` | 36 | The scanner's picture words: `$8A5A`, `$8B1A`, `$8B3A`, repeated | `Scanner` (`stage1/rec/rzx-p1-04000`) | - |
| `$C5FA` | `ThreeReturns` | 3 | Leftover: RET: RET: RET (`$C9` x 3) that no instruction reaches. Known only from the code: JumperTimer `$C5B6` ends with its own RET just before; no jump, call or table names `$C5FA-$C5FC`. | - | - |

## panels

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D92E` | `UnusedD92E` | 52 of 402 | Leftover: `$C1` `$C9` (POP BC: RET, nothing calls it), then the animated cells' work space | `MoveShots`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) | `DrawRoomCell`, `MoveShots`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) |
| `$D962` | `SceneryCellList` (`UnusedD92E`+52) | 350 | every visible scenery cell of the room, 4 bytes each (buffer address, picture address), filled by DrawRoom and redrawn each pass by DrawAnimCells (364 cells in room 0: past entry 255 the one-byte index of CellIndexMap wraps) | `MoveShots`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) | `DrawRoomCell`, `MoveShots`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) |

## rexmove

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D096` | `SolidCells` | 4 of 10 | The solid cell types 2, 4, 5, 6 (IsSolid), then PassCells `$D09A`: 0, `$0E`, `$0F`, `$10`, `$11`, `$12` (IsPassable) | `InList` | - |
| `$D09A` | `PassCells` (`SolidCells`+4) | 6 | the cells a body or a bullet passes | `InList` | - |
| `$D0D8` | `JumpSteps` | 12 | The jump's rise a step: 6, 6, 4, 4, 2, 2, 0, 0, 0, 0, then `$FF` and the fall's start 8 | `RexJump`, `ObjectJump` (`stage1/rec/rzx-p1-00000`) | - |

## collisions

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D4AC` | `BonusTextTable` | 10 | The bonus roulette's five panels: SPEED UP, SHIELD LOSS, 1000 BONUS, ENERGY LOSS, 100 RAPID SHOTS | `BonusRoulette` (`stage1/rec/rzx-p1-50000`) | - |

## sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D763` | `SfxGun` | 9 of 207 | The effect descriptors. The gun's shot | `ChannelStep`, `StartSfxIY`, `MakeObject` (`stage1/rec/rzx-p1-02000`) | `BuildRoom`, `DeathAnimation`, `DrawRex` (`stage1/rec/rzx-p1-02000`), `RexState` (`stage1/rec/rzx-p1-00000`) |
| `$D76C` | `SfxEnemyShot` (`SfxGun`+9) | 9 | an enemy's shot | `ChannelStep`, `StartSfxIY` | - |
| `$D775` | `SfxLaser` (`SfxGun`+18) | 9 | the laser | `ChannelStep`, `StartSfxIY` (`stage1/rec/rzx-p1-14000`) | - |
| `$D77E` | `SfxSpray` (`SfxGun`+27) | 9 | the spray | `ChannelStep` (`stage1/rec/rzx-p1-30000`), `StartSfxIY` (`stage1/rec/rzx-p1-30000`) | - |
| `$D787` | `SfxHitWall` (`SfxGun`+36) | 9 | a bullet meeting a wall | `ChannelStep`, `StartSfxIY`, `MakeObject` (`stage1/rec/rzx-p1-04000`) | - |
| `$D790` | `SfxExplosion` (`SfxGun`+45) | 12 | an object killed (noise) | `ChannelStep`, `StartSfxIY`, `MakeObject` (`stage1/rec/rzx-p1-02000`) | `BuildRoom`, `DeathAnimation` |
| `$D79C` | `SfxShield` (`SfxGun`+57) | 4 | the shield's hum while it is on (DrawRex) | `ChannelStep` (`stage1/rec/rzx-p1-34000`), `StartSfxIY` (`stage1/rec/rzx-p1-00000`) | - |
| `$D7A0` | `SfxShieldTone` (`SfxGun`+61) | 14 | its period word: `$04B0` + a random 0-31, written by DrawRex each time it starts; the block's last nine bytes, `$D7A5-$D7AD`, are a full descriptor (DEMO's shield-hit sound, SfxShieldHit) that nothing refers to | `ChannelStep` (`stage1/rec/rzx-p1-00000`), `StartSfxIY` (`stage1/rec/rzx-p1-00000`) | `DrawRex` (`stage1/rec/rzx-p1-02000`), `RexState` (`stage1/rec/rzx-p1-00000`) |
| `$D7AE` | `SfxMaterialise` (`SfxGun`+75) | 12 | Rex appears | `ChannelStep`, `StartSfxIY`, `MakeObject` (`stage1/rec/rzx-p1-14000`) | - |
| `$D7BA` | `SfxDematerialise` (`SfxGun`+87) | 12 | Rex vanishes | `ChannelStep`, `StartSfxIY`, `MakeObject` (`stage1/rec/rzx-p1-02000`) | - |
| `$D7C6` | `SfxBigPod` (`SfxGun`+99) | 21 | a big power pod | `ChannelStep` (`stage1/rec/rzx-p1-00000`), `StartSfxIY` (`stage1/rec/rzx-p1-00000`) | - |
| `$D7DB` | `SfxPowerPod` (`SfxGun`+120) | 21 | a power pod | `ChannelStep` (`stage1/rec/rzx-p1-00000`), `StartSfxIY` (`stage1/rec/rzx-p1-00000`) | - |
| `$D7F0` | `SfxBombPod` (`SfxGun`+141) | 21 | a bomb pod | `ChannelStep` (`stage1/rec/rzx-p1-52000`), `StartSfxIY` (`stage1/rec/rzx-p1-52000`) | - |
| `$D805` | `SfxRestart` (`SfxGun`+162) | 33 | a restart point saved (three notes) | `ChannelStep` (`stage1/rec/rzx-p1-00000`), `StartSfxIY` (`stage1/rec/rzx-p1-00000`) | - |
| `$D826` | `SfxRecharge` (`SfxGun`+195) | 12 | the shield recharging | `ChannelStep` (`stage1/rec/rzx-p1-00000`), `StartSfxIY` (`stage1/rec/rzx-p1-00000`) | - |
| `$D832` | `Channels` | 35 of 38 | the three channels' state, 8 bytes each: [steps left or `$FF` free][count][step pointer][tone word][noise][volume] | `BulletsHitObject`, `ChannelStep`, `FindSlot`, `MoveShots`, `SaveRestart` +14 | `ChannelStep`, `SoundReset`, `SoundStep`, `StartSfxIY` |
| `$D855` | `Mixer` (`Channels`+35) | 2 | the mixer value (register 7) | `StartSfxIY`, `WriteMixer` | `SoundReset`, `StartSfxIY` |
| `$D857` | `ChannelNumber` (`Channels`+37) | 1 | the channel SoundStep is on | `ChannelStep`, `SoundStep`, `WriteVolume` | `SoundStep` |

## menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DC26` | `RollCallTexts` | 296 of 302 | The roll call: for each enemy its name and its score as text records, then `$FF`. FOOT MAN 100, STOMPER 200, SCANNER 600, RAMMING POD 300, LAUNCHER 800, SHOOTERS 500, SWING GUN 600, BLOB 200, MINE LAYER 1000, MINE no score. | `PrintBoxed`, `PrintChar`, `PrintText`, `ScanKey`, `TitleMenu` +1 | `DefineKeys`, `DrawRoomCell`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) |
| `$DD4E` | `DefineTaken` (`RollCallTexts`+296) | 6 | the characters of the keys chosen so far | `ScanKey` | `DefineKeys`, `DrawRoomCell` |
| `$DEEF` | `MenuAgainRet` | 1 | RET after MenuAgain's JP, never reached | `DrawRoom` | `DrawRoom`, `DrawRoomCell` |
| `$DF05` | `MenuTexts` | 64 of 262 | The menu's text records: SELECT, 1:DEFINE, 2:KEMPSTON, 3:CURSOR, 4:SINCLAIR; the confirms; DEFINE's PRESS, :UP, :DOWN, :LEFT, :RIGHT, :FIRE (twice, two colours) | `DrawRoom`, `MoveShots`, `PrintBoxed`, `PrintChar`, `PrintText` +1 | `DrawRoom`, `DrawRoomCell` |
| `$DF45` | `ConfirmSinclairText` (`MenuTexts`+64) | 24 | CONFIRM SINCLAIR Y.N | `DrawRoom`, `PrintBoxed` (`stage1/rec/rzx-p1-00000`), `PrintChar` (`stage1/rec/rzx-p1-00000`), `PrintText` (`stage1/rec/rzx-p1-00000`) | `DrawRoom`, `DrawRoomCell` |
| `$DF5D` | `ConfirmCursorText` (`MenuTexts`+88) | 22 | CONFIRM CURSOR Y.N | `DrawRoom`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`), `MoveShots` (`stage1/rec/rzx-p1-08000`), `PrintBoxed` (`stage2/rec/p1-cursor`), `PrintChar` (`stage2/rec/p1-cursor`) +1 | `DrawRoom`, `DrawRoomCell` |
| `$DF73` | `ConfirmKempstonText` (`MenuTexts`+110) | 24 | CONFIRM KEMPSTON Y.N | `DrawRoom`, `PrintBoxed` (`stage2/rec/p1-kempston`), `PrintChar` (`stage2/rec/p1-kempston`), `PrintText` (`stage2/rec/p1-kempston`) | `DrawRoom`, `DrawRoomCell` |
| `$DF8B` | `ConfirmKeysText` (`MenuTexts`+134) | 20 | CONFIRM KEYS Y.N | `DrawRoom`, `MoveShots`, `PrintBoxed`, `PrintChar`, `PrintText` +1 | `DrawRoom`, `DrawRoomCell` |
| `$DF9F` | `PressText` (`MenuTexts`+154) | 59 | PRESS | `DrawRoom`, `PrintBoxed`, `PrintChar`, `PrintText`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) +1 | `DrawRoom`, `DrawRoomCell` |
| `$DFDA` | `DefineUpText` (`MenuTexts`+213) | 8 | :UP in the second colour (the key chosen) | `DrawRoom`, `PrintChar`, `PrintText` | `DrawRoom`, `DrawRoomCell` |
| `$DFE2` | `DefineDownText` (`MenuTexts`+221) | 10 | :DOWN | `DrawRoom`, `PrintChar`, `PrintText` | `DrawRoom`, `DrawRoomCell` |
| `$DFEC` | `DefineLeftText` (`MenuTexts`+231) | 10 | :LEFT | `DrawRoom`, `PrintChar`, `PrintText`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`), `MoveShots` (`stage1/rec/rzx-p1-08000`) | `DrawRoom`, `DrawRoomCell` |
| `$DFF6` | `DefineRightText` (`MenuTexts`+241) | 11 | :RIGHT | `DrawRoom`, `PrintChar`, `PrintText`, `MoveShots` (`stage1/rec/rzx-p1-08000`) | `DrawRoom`, `DrawRoomCell` |
| `$E001` | `DefineFireText` (`MenuTexts`+252) | 10 | :FIRE | `DrawRoom`, `PrintChar`, `PrintText` | `DrawRoom`, `DrawRoomCell` |
| `$E049` | `RollSpriteParams` | 6 | DrawCharBlock's inline parameters (the picture word, column and line rewritten at `$E04D`, `$E04E`) | `DrawCharBlock`, `DrawRoom` | `DrawRoom`, `DrawRoomCell`, `RollCallSprite` |
| `$E067` | `RollCallSprites` | 121 of 1176 | The roll call's sprites: [picture word][width][height][8 frame offsets], `$FF` ends | `CellsUnderRex`, `DrawCharBlock`, `DrawRoom`, `FindGround`, `IsPassable` +16 | `DrawRoom`, `DrawRoomCell`, `MoveShots`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) |
| `$E0E0` | `KeyPorts` (`RollCallSprites`+121) | 16 | the 8 keyboard half-rows' ports, ScanKey's order | `DrawRoom`, `ScanKey` | `DrawRoom`, `DrawRoomCell` |
| `$E0F0` | `RollCallPictures` (`RollCallSprites`+137) | 174 | the roll call's pictures (`$E0F6`, `$E176`, `$E1F6`, `$E2B6`, `$E3F6`, `$E436`, `$E496`); the room grid is built over them after the menu | `DrawCharBlock`, `DrawRoom` | `DrawRoom`, `DrawRoomCell` |
| `$E19E` | `RoomGridLeft` (`RollCallSprites`+311) | 1 | the grid's origin one byte left (CellPointer with A = 0, Rex facing right) | `DrawCharBlock`, `DrawRoom` | `DrawRoom` |
| `$E19F` | `RoomGrid` (`RollCallSprites`+312) | 96 | the room grid's origin: the cell under (x, y) at `$E19F` + 32 x (y / 8) + x / 8; built over the roll call's pictures | `DrawCharBlock`, `DrawRoom`, `FlyBounce` (`stage1/rec/rzx-p1-14000`), `IsSolid` (`stage1/rec/rzx-p1-04000`), `WalkLeft` (`stage1/rec/rzx-p1-12000`) | `DrawRoom` |
| `$E1FF` | `RoomGridPlay` (`RollCallSprites`+408) | 311 | the grid's first play row (line 24) | `DrawCharBlock`, `DrawRoom`, `FindGround`, `IsPassable`, `MoveShots` +11 | `DrawRoom`, `DrawRoomCell`, `MoveShots`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) |
| `$E336` | `ExplosionPicture` (`RollCallSprites`+719) | 457 | the explosion's picture (192 bytes), copied to `$6018` by TitleMenu | `CellsUnderRex`, `DrawRoom`, `FindGround`, `IsPassable`, `IsSolid` +12 | `DrawRoom`, `DrawRoomCell`, `BulletHitsCell` (`stage1/rec/rzx-p1-20000`) |
| `$E4FF` | `TitleScreen` | 20 of 6907 | The title screen: 6912 bytes from `$E4FF`, the tape holding them to `$FFF9` (6907); shown by TitleMenu, then the attribute shadow (`$E4FF-$E7FE`) and the back buffer | `BufferToScreen`, `CopyAttrs`, `CopyCells`, `DrawSprite`, `FillShadowCells` +9 | `DrawAnimCells`, `DrawRoomCell`, `DrawSprite`, `FillCells3`, `GameEntry` +23 |
| `$E513` | `ShieldAttrs` (`TitleScreen`+20) | 24 | the shield figure's attributes in the shadow | `GameEntry`, `ShowTitle`, `TitleMenu`, `FadeStep` (`stage1/rec/rzx-p1-00000`) | `GameEntry`, `PowerBarColour`, `SaveAttrs`, `ShowShield`, `TitleMenu` +1 |
| `$E52B` | `SweepAttrs` (`TitleScreen`+44) | 52 | the HUD sweep's row in the shadow | `GameEntry`, `ShowTitle`, `TitleMenu`, `CopyCells` (`stage1/rec/rzx-p1-38000`), `FadeStep` (`stage1/rec/rzx-p1-00000`) +1 | `GameEntry`, `HudSweep`, `SaveAttrs`, `TitleMenu` |
| `$E55F` | `AttrShadowPlay` (`TitleScreen`+96) | 672 | the shadow's play rows (CopyAttrs puts them at `$5860`) | `CopyAttrs`, `CopyCells`, `FillShadowCells`, `GameEntry`, `ShowTitle` +1 | `DrawRoomCell`, `GameEntry`, `MoveShots`, `TitleMenu`, `BulletHitsCell` (`stage1/rec/rzx-p1-06000`) |
| `$E7FF` | `ShotBufferOrigin` (`TitleScreen`+768) | 160 | the back buffer's origin for a bullet: `$E7FF` + 32 x y + x / 8 | `ShowTitle`, `TitleMenu` | `TitleMenu` |
| `$E89F` | `SparkleBufferOrigin` (`TitleScreen`+928) | 96 | the sparkle's origin | `ShowTitle`, `TitleMenu` | `TitleMenu` |
| `$E8FF` | `SpriteBufferOrigin` (`TitleScreen`+1024) | 256 | DrawSprite's origin | `ShowTitle`, `TitleMenu`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-10000`) | `TitleMenu`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawShotByte` (`stage1/rec/rzx-p1-28000`), `DrawSprite` (`stage1/rec/rzx-p1-10000`) |
| `$E9FF` | `ObjectBufferOrigin` (`TitleScreen`+1280) | 256 | the objects' origin | `ShowTitle`, `TitleMenu`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-04000`) | `KillFlashFade`, `TitleMenu`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawShotByte` (`stage1/rec/rzx-p1-26000`), `DrawShotDot` (`stage1/rec/rzx-p1-36000`) +3 |
| `$EAFF` | `BufferPlayOrigin` (`TitleScreen`+1536) | 1 | the play lines' origin (one byte before the buffer) | `OrChar`, `ShowTitle`, `TitleMenu`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawSprite` (`stage1/rec/rzx-p1-04000`) | `OrChar`, `TitleMenu`, `DrawMirrored` (`stage1/rec/rzx-p1-56000`), `DrawShotDot` (`stage1/rec/rzx-p1-36000`), `DrawSprite` (`stage1/rec/rzx-p1-04000`) +3 |
| `$EB00` | `BackBuffer` (`TitleScreen`+1537) | 5370 | the back buffer's play lines, 32 bytes a line, to `$FFFF` | `BufferToScreen`, `DrawSprite`, `OrChar`, `ShowTitle`, `SparkleDraw` +4 | `DrawAnimCells`, `DrawRoomCell`, `DrawSprite`, `FillCells3`, `MoveShots` +15 |


## The BASIC of REX 1 (`src/tape/basic-rex1.json`)

Rex, Martech Games 1988: tape side 1 block 2, the BASIC program "REX 1" (PROG `$5CCB`, LINE 1). Its entries are
`src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic-rex1.json`; the
readers and writers from `work/stage1/c1`.

### The BASIC of REX 1: basic-rex1

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine10` | 33 | Line 10: PAPER 0: INK 0: BORDER 0: CLS. Black paper, ink and border, then CLS: the ROM's tape messages that follow print black on black, and the loading screen comes onto a black frame. | - | - |
| `$5CEC` | `BasicLine20` | 17 | Line 20: CLEAR 24599. RAMTOP to `$6017`, one byte under the code block (`$6018`): the machine stack moves under the code, where the game keeps it (its own SP is set by the entry). | - | - |
| `$5CFD` | `BasicLine30` | 9 | Line 30: `LOAD "" SCREEN$`. Loads the next Bytes file to the screen at `$4000` whatever its header's start says (the header gives 40000). | - | - |
| `$5D06` | `BasicLine40` | 23 | Line 40: PRINT AT 0,0;. Puts the print position back at the top left, so the ROM's "Bytes: ds" message of the next LOAD prints in the black top line (INK 0 on PAPER 0) and not over the picture (known only from the BASIC: the message is not visible in the recording's screens). | - | - |
| `$5D1D` | `BasicLine50` | 9 | Line 50: LOAD "" CODE. Loads the code block at the start its header gives (`$6018`). | - | - |
| `$5D26` | `BasicLine60` | 18 | Line 60: RANDOMIZE USR 38010. Calls part 1's entry GameEntry `$947A` (src/game), which never returns. | - | - |
| `$5D38` | `BasicLine999` | 42 | Line 999: SAVE "t:": SAVE "REX 1" LINE 1: LOAD "a:": LOAD "make1". The authors' mastering line, never run (the program starts at line 1, and line 60 does not return). SAVE "t:" sends the next SAVE to the tape and LOAD "a:" makes a disk drive the default, the syntax of a disk interface's BASIC: so the program saves itself to tape with LINE 1 and then loads the next step, "make1", from the disk (known only from the BASIC's text). | - | - |


## The BASIC of REX 2 (`src/tape/basic-rex2.json`)

Rex, Martech Games 1988: tape side 1 block 8, the BASIC program "REX 2" (PROG `$5CCB`, LINE 1). Its entries are
`src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic-rex2.json`; the
readers and writers from `work/stage1/c1`.

### The BASIC of REX 2: basic-rex2

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine10` | 33 | Line 10: PAPER 0: INK 0: BORDER 0: CLS. Black paper, ink and border, then CLS: the ROM's tape messages that follow print black on black, and the loading screen comes onto a black frame. | - | - |
| `$5CEC` | `BasicLine20` | 17 | Line 20: CLEAR 24999. RAMTOP to `$61A7`, one byte under the code block (`$61A8`): the machine stack moves under the code, where the game keeps it (its own SP is set by the entry). | - | - |
| `$5CFD` | `BasicLine30` | 9 | Line 30: `LOAD "" SCREEN$`. Loads the next Bytes file to the screen at `$4000` whatever its header's start says (the header gives 40000). | - | - |
| `$5D06` | `BasicLine40` | 23 | Line 40: PRINT AT 0,0;. Puts the print position back at the top left, so the ROM's "Bytes: ds" message of the next LOAD prints in the black top line (INK 0 on PAPER 0) and not over the picture (known only from the BASIC: the message is not visible in the recording's screens). | - | - |
| `$5D1D` | `BasicLine50` | 9 | Line 50: LOAD "" CODE. Loads the code block at the start its header gives (`$61A8`). | - | - |
| `$5D26` | `BasicLine60` | 18 | Line 60: RANDOMIZE USR 38000. Calls part 2's entry `$9470` (src/rex2), which never returns. | - | - |
| `$5D38` | `BasicLine999` | 42 | Line 999: SAVE "t:": SAVE "REX 2" LINE 1: LOAD "a:": LOAD "make2". The authors' mastering line, never run (the program starts at line 1, and line 60 does not return). SAVE "t:" sends the next SAVE to the tape and LOAD "a:" makes a disk drive the default, the syntax of a disk interface's BASIC: so the program saves itself to tape with LINE 1 and then loads the next step, "make2", from the disk (known only from the BASIC's text). | - | - |


## The BASIC of DEMO (`src/tape/basic-demo.json`)

Rex, Martech Games 1988: tape side 2 block 2, the BASIC program "DEMO" (PROG `$5CCB`, LINE 1). Its entries are
`src/tape/<module>.asm`, written from `src/tape/basic.ann` by `kit/mkgame.py --part src/tape/basic-demo.json`; the
readers and writers from `work/stage1/c1`.

### The BASIC of DEMO: basic-demo

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$5CCB` | `BasicLine10` | 33 | Line 10: PAPER 0: INK 0: BORDER 0: CLS. Black paper, ink and border, then CLS: the ROM's tape messages that follow print black on black, and the loading screen comes onto a black frame. | - | - |
| `$5CEC` | `BasicLine20` | 17 | Line 20: CLEAR 24999. RAMTOP to `$61A7`, one byte under the code block (`$61A8`): the machine stack moves under the code, where the game keeps it (its own SP is set by the entry). | - | - |
| `$5CFD` | `BasicLine30` | 9 | Line 30: `LOAD "" SCREEN$`. Loads the next Bytes file to the screen at `$4000` whatever its header's start says (the header gives 40000). | - | - |
| `$5D06` | `BasicLine40` | 23 | Line 40: PRINT AT 0,0;. Puts the print position back at the top left, so the ROM's "Bytes: ds" message of the next LOAD prints in the black top line (INK 0 on PAPER 0) and not over the picture (known only from the BASIC: the message is not visible in the recording's screens). | - | - |
| `$5D1D` | `BasicLine50` | 9 | Line 50: LOAD "" CODE. Loads the code block at the start its header gives (`$61A8`). | - | - |
| `$5D26` | `BasicLine60` | 18 | Line 60: RANDOMIZE USR 35460. Calls DEMO's entry `$8A84` (src/demo), which never returns. | - | - |
| `$5D38` | `BasicLine999` | 41 | Line 999: SAVE "t:": SAVE "DEMO" LINE 1: LOAD "a:": LOAD "maked". The authors' mastering line, never run (the program starts at line 1, and line 60 does not return). SAVE "t:" sends the next SAVE to the tape and LOAD "a:" makes a disk drive the default, the syntax of a disk interface's BASIC: so the program saves itself to tape with LINE 1 and then loads the next step, "maked", from the disk (known only from the BASIC's text). | - | - |


## REX 1's loading screen (`src/screen/screen-rex1.json`)

Rex, Martech Games 1988: tape side 1 block 4, the loading screen of REX 1 (6912 bytes at `$4000`). Its entries are
`src/screen/<module>.asm`, written from `src/screen/screen.ann` by `kit/mkgame.py --part src/screen/screen-
rex1.json`; the readers and writers from `work/stage1/c1`.

### REX 1's loading screen: screen-rex1

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$4000` | `LoadingScreenRex1` | 6912 | REX 1's loading screen: 6144 bytes of pixels, 768 of attributes. Witness: c1 loads it at `$4000` (work/stage1/c1/screens); it stays on the screen while the code block loads. | - | - |


## REX 2's loading screen (`src/screen/screen-rex2.json`)

Rex, Martech Games 1988: tape side 1 block 10, the loading screen of REX 2 (6912 bytes at `$4000`). Its entries are
`src/screen/<module>.asm`, written from `src/screen/screen.ann` by `kit/mkgame.py --part src/screen/screen-
rex2.json`; the readers and writers from `work/stage1/c1`.

### REX 2's loading screen: screen-rex2

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$4000` | `LoadingScreenRex2` | 6912 | REX 2's loading screen: 6144 bytes of pixels, 768 of attributes. Witness: c2 loads it at `$4000` (work/stage1/c2/screens). | - | - |


## DEMO's loading screen (`src/screen/screen-demo.json`)

Rex, Martech Games 1988: tape side 2 block 4, the loading screen of DEMO (6912 bytes at `$4000`). Its entries are
`src/screen/<module>.asm`, written from `src/screen/screen.ann` by `kit/mkgame.py --part src/screen/screen-
demo.json`; the readers and writers from `work/stage1/c1`.

### DEMO's loading screen: screen-demo

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$4000` | `LoadingScreenDemo` | 6912 | DEMO's loading screen: 6144 bytes of pixels, 768 of attributes. Witness: d1 loads it at `$4000` (work/stage1/d1/screens). | - | - |


## Part 2 (REX 2) (`src/rex2/rex2.json`)

Rex, Martech Games 1988 (The Light): part 2 (REX 2), `$61A8-$FFF9` as the ROM loader leaves it (tools/parts.py: side
1 blocks 10 and 12 of orig/Rex.tzx.zip); entry `$9470`. Its entries are `src/rex2/<module>.asm`, written from
`src/rex2/rex2.ann` by `kit/mkgame.py --part src/rex2/rex2.json`; the readers and writers from `work/stage1/c1`,
`work/stage1/c2`, `work/stage1/rec/rzx-p2-00000`, `work/stage1/rec/rzx-p2-02000`, `work/stage1/rec/rzx-p2-04000`,
`work/stage1/rec/rzx-p2-06000`, `work/stage1/rec/rzx-p2-08000`, `work/stage1/rec/rzx-p2-10000`,
`work/stage1/rec/rzx-p2-12000`, `work/stage1/rec/rzx-p2-14000`, `work/stage1/rec/rzx-p2-16000`,
`work/stage1/rec/rzx-p2-18000`, `work/stage1/rec/rzx-p2-20000`, `work/stage1/rec/rzx-p2-22000`,
`work/stage1/rec/rzx-p2-24000`, `work/stage1/rec/rzx-p2-26000`, `work/stage1/rec/rzx-p2-28000`,
`work/stage1/rec/rzx-p2-30000`, `work/stage1/rec/rzx-p2-32000`, `work/stage1/rec/rzx-p2-34000`,
`work/stage1/rec/rzx-p2-36000`, `work/stage1/rec/rzx-p2-38000`, `work/stage1/rec/rzx-p2-40000`,
`work/stage2/rec/p2-room20`.

### Part 2 (REX 2): graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$61A8` | `DevLink` | 283 of 314 | Leftover: the development link's code: pages the link in, saves every register, then serves the host's commands until a return. OUT to `$7F`, `$3F`, `$5F`, `$1F` (DevLinkPut) and `$7FFD`; IN from `$3F` and `$1F`; DevLinkGet `$62C3` and DevLinkPut `$62D3` move one byte with a handshake on port `$3F`, data on `$1F`. Commands: `$B4` pokes a block (address, length, bytes); `$B5` sets the return address (`$62BE`) and `$CD00` (`$62BC`); `$B6` sends a block (address, length; `$624E`); `$B7` pages `$7FFD` (`$6234`); `$B8` sends the 26 saved bytes at `$62E4`; `$B9` receives 26 bytes there; `$BA` sets `$62BC` and `$62BE` from the host. `$B5`/`$BA` end by restoring the registers and calling DebugHook `$D6C6`. No instruction of the game reaches `$61A8` (known only from the code; z80dasm of the bytes); the kit keeps it as bytes because recording c2 reads these bytes once. Kept as a documented leftover (src/res/leftovers/README.md). | `ChooseKempston`, `DrawRoom`, `HitObjectHard`, `PrintBoxed`, `RexFall` +4 | - |
| `$62C3` | `DevLinkGet` (`DevLink`+283) | 16 | code: E = a byte from the host (port `$1F`) after the handshake on port `$3F` | `HitObjectHard`, `PrintBoxed`, `BulletLoop` (`stage1/rec/rzx-p2-20000`), `BulletsHitObject` (`stage1/rec/rzx-p2-08000`), `EnemyBulletsHitRex` (`stage1/rec/rzx-p2-00000`) +1 | - |
| `$62D3` | `DevLinkPut` (`DevLink`+299) | 15 | code: a byte to the host (port `$1F`), then the handshake on port `$3F` | `DrawRoom`, `HitObjectHard`, `PrintBoxed`, `BulletLoop` (`stage1/rec/rzx-p2-20000`), `BulletsHitObject` (`stage1/rec/rzx-p2-08000`) +2 | - |
| `$62E2` | `DevLinkState` | 28 | The link's state: a work word, the 26 bytes it sends (`$62E4`), the saved HL, return address and SP (`$62F8`, `$62FA`, `$62FC`); tape garbage, never written in play | `DrawRoom`, `HitObjectHard`, `BulletLoop` (`stage1/rec/rzx-p2-20000`), `BulletsHitObject` (`stage1/rec/rzx-p2-08000`), `EnemyBulletsHitRex` (`stage1/rec/rzx-p2-00000`) +1 | - |
| `$62FE` | `Unused62FE` | 8 | Eight zero bytes before the font (its codes 24-31 would be here); nothing reads them | `DrawRoom`, `HitObjectHard`, `BulletLoop` (`stage1/rec/rzx-p2-20000`), `BulletsHitObject` (`stage1/rec/rzx-p2-08000`), `EnemyBulletsHitRex` (`stage1/rec/rzx-p2-00000`) +1 | - |
| `$6306` | `Font` | 512 | The font: 64 characters, codes 32-95 (space to underscore), 8 bytes each, at `$6206` + 8 x code. PrintChar, PrintDigits, the box frame of PrintBoxed (`$6346`, `$6356`, `$6366`, `$637E`, `$63DE`, `$63EE`) and the menu's FontChar `$DFB1` read it. | `DrawRoom`, `DrawSprite`, `HitObjectHard`, `UpdateDrones`, `BulletLoop` (`stage1/rec/rzx-p2-20000`) +6 | `UpdateDrones` |
| `$6506` | `CharFlags` | 256 | The cell type of each of the 256 room characters: what Rex and the objects test in the room grid. DrawRoomCell copies CharFlags[c] into the grid for each character drawn. As in part 1, plus part 2's types: 3 kills Rex when he walks, jumps or falls into it (RexWalkDeadly, RexJumpDeadly, RexFall) and a falling object (ObjectFall `$C721`), 4 is the big squidgy thing (BossHit `$B743`), `$15` and `$16` make walkers dissolve (MaybeDissolve `$C5B4`, CellDissolve `$C5BA`). | `DrawRoom`, `DrawSprite`, `HitObjectHard`, `BulletLoop` (`stage1/rec/rzx-p2-20000`), `BulletsHitObject` (`stage1/rec/rzx-p2-08000`) +3 | `ToDigits` |
| `$6606` | `CharGraphics` | 584 of 2048 | The 256 room characters, 8 bytes each | `DrawRoom`, `DrawSprite`, `HitObjectHard`, `NewGame`, `RollCharUp` +7 | `ClearScreen`, `NewGame`, `RollCharUp`, `ToDigits`, `AnimateCells` (`stage1/c2`) +3 |
| `$684E` | `AnimChar73` (`CharGraphics`+584) | 1416 | character 73, the restart marker: frames from FramesList3 `$A77D` (AnimateRestart `$A740`) | `DrawRoom`, `DrawSprite`, `HitObjectHard`, `NewGame`, `RollCharUp` +7 | `ClearScreen`, `NewGame`, `RollCharUp`, `ToDigits`, `CopyFrame` (`stage1/c2`) +1 |
| `$6DD6` | `AnimChar250` (`CharGraphics`+2000) | 16 | characters 250-251: frames from FramesList2 `$A789` (AnimateCells2 `$A730`) | `DrawRoom`, `DrawAnimCells` (`stage1/rec/rzx-p2-02000`), `DrawRoomCell` (`stage1/rec/rzx-p2-02000`) | `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `CopyFrame` (`stage1/c2`) |
| `$6DE6` | `AnimChar252` (`CharGraphics`+2016) | 32 | characters 252-255: AnimFramesA `$AF82` / AnimFramesB `$AFA2` on alternate passes (AnimateCells `$A706`) | `DrawRoom`, `DrawAnimCells` (`stage1/c2`), `DrawRoomCell` (`stage1/c2`) | `AnimateCells` (`stage1/c2`) |
| `$6E06` | `CharAttrs` | 256 | The attribute of each of the 256 room characters | `DrawRoom`, `DrawRoomCell` (`stage1/c2`) | - |
| `$6F06` | `BlockDefs` | 2304 | The 256 blocks: 3 x 3 character codes each, rows top to bottom | `DrawRoom`, `ObjectFall`, `DrawBlockRow` (`stage1/c2`) | - |
| `$7806` | `RoomMaps` | 2450 | The room maps: 7 rows of 10 block codes each (70 bytes a room); room n at `$7806` + 70n; 35 slots, rooms 0-25 used. The slots 26-34 (`$8040-$8197`, 630 bytes) are a leftover: no exit leads to them (RoomExits holds 26 rooms) and they are REX 1's rooms 26-34 with 44-69 of each room's 70 codes the same (work/stage2/NOTES.md); drawn with part 2's blocks they look like part 1's late rooms (tools/room_maps.py). | `ClearBuffer`, `DrawRoom` (`stage1/c2`) | - |
| `$8198` | `Sprites` | 192 of 4824 | The sprites, pre-shifted: each label is a picture set its owner draws through a frame list. `$8198` is kind 0's picture (a walker, InitKind0 `$CC05`) and UpdateObject's default. | `ClearBuffer`, `SetupShot`, `ToDigits`, `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `CopyFrame` (`stage1/c2`) +3 | - |
| `$8258` | `SpriteHitFlash` (`Sprites`+192) | 96 | an object hit (HitObject, HitObjectHard) | `ClearBuffer`, `DrawSprite` (`stage1/rec/rzx-p2-10000`) | - |
| `$82B8` | `SpriteRamTurn` (`Sprites`+288) | 96 | the hit foot man turning (RamTurn `$C032`) | `ClearBuffer`, `DrawSprite` (`stage1/rec/rzx-p2-10000`) | - |
| `$8318` | `SpriteKind6` (`Sprites`+384) | 32 | kind 6 and the hop (InitKind6 `$CC18`, StartHop `$C5BE`) | `ClearBuffer`, `DrawSprite` (`stage1/c2`) | - |
| `$8338` | `SpriteJumper` (`Sprites`+416) | 32 | a walker turned jumper (MakeJumper `$C60D`) | `ClearBuffer`, `DrawSprite` (`stage1/c2`) | - |
| `$8358` | `SpriteRex` (`Sprites`+448) | 192 | Rex walking (DrawRex) | `ClearBuffer`, `DrawSprite` (`stage1/c2`) | - |
| `$8418` | `SpriteRexJump` (`Sprites`+640) | 120 | Rex jumping or falling, off a lift (DrawRex) | `ClearBuffer`, `DrawSprite` (`stage1/c2`) | - |
| `$8490` | `SpriteRexDeath` (`Sprites`+760) | 72 | Rex's death; also the big squidgy thing's explosion pieces (BossExplodes `$99E3`) | `ClearBuffer`, `DrawSprite` (`stage1/c2`) | - |
| `$84D8` | `SpritePoints` (`Sprites`+832) | 576 | the points sign a kill leaves (KillObject `$9807`) | `ClearBuffer`, `DrawPiece` (`stage1/rec/rzx-p2-40000`), `DrawSprite` (`stage1/c2`) | - |
| `$8718` | `SpritePodA` (`Sprites`+1408) | 192 | a pod left by an explosion (BlowUp) | `ClearBuffer`, `DrawSprite` (`stage1/c2`) | - |
| `$87D8` | `SpritePodB` (`Sprites`+1600) | 192 | a pod left by an explosion (BlowUp) | `ClearBuffer`, `DrawSprite` (`stage1/rec/rzx-p2-00000`) | - |
| `$8898` | `SpritePowerPod` (`Sprites`+1792) | 128 | the power pod's four frames (`$8898`, `$88B8`, `$88D8`, `$88F8`: AnimatePod `$C1CB`) | `DrawSprite` (`stage1/c2`) | - |
| `$8918` | `SpriteShield` (`Sprites`+1920) | 424 | the shield bubble round Rex, 4 x 21 (DrawShield) | `SetupShot`, `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `CopyFrame` (`stage1/c2`), `DrawSprite` (`stage1/c2`) | - |
| `$8AC0` | `SpriteHudIcons` (`Sprites`+2344) | 160 | the HUD's weapon and bomb icons | `DrawCharBlock` (`stage1/c2`) | - |
| `$8B60` | `SpriteHudIcons2` (`Sprites`+2504) | 64 | the HUD's weapon icons, second row | `DrawCharBlock` (`stage1/c2`) | - |
| `$8BA0` | `SpriteBonusPod` (`Sprites`+2568) | 32 | the bonus pod (BlowUp) | `DrawSprite` (`stage1/rec/rzx-p2-18000`) | - |
| `$8BC0` | `SpriteBonusPod2` (`Sprites`+2600) | 32 | the bonus pod (BlowUp, InitBonusPod `$CCBF`) | `DrawSprite` (`stage1/rec/rzx-p2-24000`) | - |
| `$8BE0` | `SpriteKind3` (`Sprites`+2632) | 320 | kind 3 (InitKind3 `$CC53`) | `DrawSprite` (`stage1/rec/rzx-p2-02000`) | - |
| `$8D20` | `SpriteKind2` (`Sprites`+2952) | 256 | kind 2 (InitKind2 `$CC75`) | `ToDigits`, `DrawSprite` (`stage1/c2`) | - |
| `$8E20` | `SpriteKind5` (`Sprites`+3208) | 224 | kind 5 (InitKind5 `$CCF3`) | `ClearBuffer`, `DrawSprite` (`stage1/c2`) | - |
| `$8F00` | `SpriteKind1` (`Sprites`+3432) | 192 | kind 1 (InitKind1 `$CC40`) | `ClearBuffer`, `SetupShot`, `DrawSprite` (`stage1/rec/rzx-p2-10000`) | - |
| `$8FC0` | `SpriteKind4` (`Sprites`+3624) | 128 | kind 4 (InitKind4 `$CC9D`) | `ClearBuffer`, `DrawSprite` (`stage1/c2`) | - |
| `$9040` | `SpriteKind9` (`Sprites`+3752) | 192 | kind 9 (InitKind9 `$CCD1`) | `DrawSprite` (`stage1/c2`) | - |
| `$9100` | `SpriteKind14` (`Sprites`+3944) | 128 | kind 14, the mine (InitKind14 `$CD15`) | `DrawSprite` (`stage1/c2`) | - |
| `$9180` | `ExplosionPicture` (`Sprites`+4072) | 752 | an exploding object's picture (UpdateObject `$BC50`); part 1 copied its own to `$6018` | `ToDigits`, `DrawSprite` (`stage1/c2`) | - |

### Part 2 (REX 2): score

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9896` | `KillScores` | 26 | The score of each object kind, in hundreds: kind 0 2, 1 3, 2 5, 3 3, 4 6, 5 1, 6 1, 7 1, 8 6, 9 4, 10-13 1, 14 0, then 1s | `KillObject` (`stage1/c2`) | - |
| `$99D1` | `FadeSteps` | 18 | The fade's 17 steps: 1 six times, 0 five times, 2 six times, then `$FF` (the end). As REX 1's FadeSteps `$9AB3` (src/game/score.asm). | `FadeStep` (`stage1/rec/rzx-p2-00000`) | - |
| `$9AE1` | `EndLeftover` | 4 | Leftover: CALL WaitFire: POP BC after the endless loop; no instruction reaches it | - | - |

### Part 2 (REX 2): death

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9CF7` | `ExplosionAreas` | 54 | The explosion areas: [size][mask] pairs `$10`/`$03`, `$20`/`$07`, `$40`/`$0F`; Rex's death starts at `$9CF7`, the boss's at `$9CF9`. A piece comes back at X = `$68` - size + 8 x (random AND mask), likewise Y (BossExplodes); the boss moves from the middle pair to the first at timer `$82` (ShrinkArea). | `BossExplodes` (`stage1/rec/rzx-p2-40000`) | `BossExplodes` (`stage1/rec/rzx-p2-40000`) |
| `$9EBF` | `SparkleLeftover` | 5 | Leftover: LD A,`$64`: LD (`$A1FA`),A after SparkleUpdate's JP; no instruction reaches it | - | - |
| `$9F0B` | `DissolveMasks` | 10 | The dissolve's masks by step: `$10`, `$22`, `$89`, `$65`, `$AB`, `$DB`, `$F7`, `$FF`, `$FF`, `$FF` | `LifeLost`, `MakeObject` (`stage1/c2`), `ObjectDissolve` (`stage1/c2`) | `LifeLost` |
| `$A0A5` | `SparkleMasks` | 8 of 83 | Eight bit masks `$80-$01`, then the particles' offsets (SparkleDots) | `BossExplodes`, `BufferToScreen`, `BulletLoop`, `BurstShot`, `ClearBuffer` +24 | `BestWeapon`, `BossExplodes`, `BufferToScreen`, `BulletLoop`, `BurstShot` +17 |
| `$A0AD` | `SparkleDots` (`SparkleMasks`+8) | 75 | the sparkle's particles: Y, X offset pairs | `BossExplodes`, `BufferToScreen`, `BulletLoop`, `BurstShot`, `ClearBuffer` +23 | `BestWeapon`, `BossExplodes`, `BulletLoop`, `BurstShot`, `ClearBuffer` +16 |

### Part 2 (REX 2): variables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A1AB` | `FireLatch` | 1 of 193 | 1 while fire is held (one shot a press for the slow weapons). As REX 1's FireLatch `$A012` (src/game/variables.asm). | `PrintBoxed`, `AddDigit` (`stage1/c2`), `AddScore` (`stage1/c2`), `AnimateCells` (`stage1/c2`), `AnimateCells2` (`stage1/rec/rzx-p2-04000`) +131 | `AddScore` (`stage1/rec/rzx-p2-00000`), `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `Attract` (`stage1/c2`), `BestWeapon` (`stage1/c2`), `BlowUp` (`stage1/c2`) +126 |
| `$A1AC` | `Weapon` (`FireLatch`+1) | 1 | the weapon in use: 0 gun, 1 double fire, 2 laser, 3 multiple (drones), 4 spray | `BulletLoop` (`stage1/rec/rzx-p2-20000`), `BulletsHitObject` (`stage1/rec/rzx-p2-08000`), `FindShotSlot` (`stage1/c2`), `FindSlot` (`stage1/c2`), `FireDouble` (`stage1/c2`) +7 | `BestWeapon` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-04000`), `StartWeapon` (`stage1/c2`) |
| `$A1AD` | `PowerLevel` (`FireLatch`+2) | 1 | the weapon's power, 1-5 (the power bar; PowerGain never stores 6) | `FindShotSlot` (`stage1/c2`), `FireSpray` (`stage1/rec/rzx-p2-12000`), `FireWeapon` (`stage1/rec/rzx-p2-02000`), `PowerBarColour` (`stage1/c2`), `PowerDrain` (`stage1/c2`) +2 | `PowerDrain` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-02000`), `StartWeapon` (`stage1/c2`) |
| `$A1AE` | `PowerBarPtr` (`FireLatch`+3) | 2 | the HUD address of the power bar's end | `PowerBar` (`stage1/c2`), `PowerDrain` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-02000`) | `PowerDrain` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-02000`), `StartWeapon` (`stage1/c2`) |
| `$A1B0` | `PassToggle` (`FireLatch`+5) | 1 | flips every pass (the animations run every other pass) | `AnimateCells` (`stage1/c2`), `Attract` (`stage1/c2`), `MainLoop` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) | `Attract` (`stage1/c2`), `BuildRoom` (`stage1/c2`), `MainLoop` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A1B1` | `PowerCount` (`FireLatch`+6) | 1 | power pods towards the next power level | `PowerDrain` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-00000`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `PowerDrain` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-00000`) |
| `$A1B2` | `RexCellPtr` (`FireLatch`+7) | 2 | Rex's place in the room grid (CellPointer `$A6AB`) | `CellsUnderRex` (`stage1/c2`), `RexJump` (`stage1/c2`), `RexWalk` (`stage1/c2`) | `MainLoop` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A1B4` | `ObjectCellPtr` (`FireLatch`+9) | 2 | the current object's place in the grid (ObjectCell `$C794`) | `DriftObject` (`stage1/c2`), `WalkLeft` (`stage1/c2`), `WalkRight` (`stage1/c2`) | `ObjectCell` (`stage1/c2`) |
| `$A1B6` | `RoomCellPtr` (`FireLatch`+11) | 3 | DrawRoom's grid pointer | `DrawRoomCell` (`stage1/c2`) | `DrawRoom` (`stage1/c2`), `DrawRoomCell` (`stage1/c2`) |
| `$A1B9` | `ObjectListPtr` (`FireLatch`+14) | 2 | the room's object list (RoomObjectLists) | `MakeObjects` (`stage1/c2`) | `ReadExits` (`stage1/c2`) |
| `$A1BB` | `HumanPicture` (`FireLatch`+16) | 6 | part 1's human picture offset; part 2 never uses it | - | - |
| `$A1C1` | `BoxX` (`FireLatch`+22) | 1 | PrintBoxed: the box's column | `PanelBox` (`stage1/c2`), `PanelRow` (`stage1/c2`) | `PanelBox` (`stage1/c2`) |
| `$A1C2` | `BoxY` (`FireLatch`+23) | 1 | PrintBoxed: the box's line | `PanelBox` (`stage1/c2`) | `PanelBox` (`stage1/c2`) |
| `$A1C3` | `BoxWidth` (`FireLatch`+24) | 1 | PrintBoxed: the box's width | `PanelBox` (`stage1/c2`), `PanelLine` (`stage1/c2`) | `PanelBox` (`stage1/c2`) |
| `$A1C4` | `BoxHeight` (`FireLatch`+25) | 1 | PrintBoxed: the box's height | `PanelBox` (`stage1/c2`) | `PanelBox` (`stage1/c2`) |
| `$A1C5` | `SpawnLeft` (`FireLatch`+26) | 1 | the room spawns from the left | - | `ReadExits` (`stage1/c2`), `SetSpawnLeft` (code) |
| `$A1C6` | `SpawnRight` (`FireLatch`+27) | 1 | the room spawns from the right | - | `ReadExits` (`stage1/c2`), `SetSpawnRight` (`stage1/c2`) |
| `$A1C7` | `SpawnTop` (`FireLatch`+28) | 1 | the room spawns from the top | - | `ReadExits` (`stage1/c2`), `SetSpawnTop` (code) |
| `$A1C8` | `SmartBombSteps` (`FireLatch`+29) | 1 | the smart bomb's steps left (16) | `SmartBombStep` (`stage1/c2`) | `SmartBomb` (`stage1/rec/rzx-p2-28000`), `SmartBombFree` (`stage1/c2`), `SmartBombStep` (`stage1/c2`) |
| `$A1C9` | `SmartBombOn` (`FireLatch`+30) | 1 | a smart bomb runs | `SmartBomb` (`stage1/rec/rzx-p2-28000`), `SmartBombFree` (`stage1/c2`), `SmartBombStep` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `SmartBomb` (`stage1/rec/rzx-p2-28000`), `SmartBombFree` (`stage1/c2`), `SmartBombStep` (`stage1/c2`) |
| `$A1CA` | `SmartBombPtr` (`FireLatch`+31) | 2 | the next object to kill | `SmartBombStep` (`stage1/c2`) | `SmartBomb` (`stage1/rec/rzx-p2-28000`), `SmartBombFree` (`stage1/c2`), `SmartBombStep` (`stage1/c2`) |
| `$A1CC` | `SpriteMirror` (`FireLatch`+33) | 1 | DrawSprite: bit 7 a fixed frame, SpritePicture, the frame list ignored (mirroring, through MirrorTable `$AE52`, is A not 0 at the call) | `DrawPiece` (`stage1/rec/rzx-p2-40000`), `DrawSprite` (`stage1/c2`) | `BossExplodes` (`stage1/rec/rzx-p2-40000`), `DrawObject` (`stage1/rec/rzx-p2-08000`), `DrawRex` (`stage1/c2`), `RexState` (`stage1/rec/rzx-p2-02000`), `UpdateObject` (`stage1/c2`) +1 |
| `$A1CD` | `SpritePicture` (`FireLatch`+34) | 4 | DrawSprite: the picture | `DrawPiece` (`stage1/rec/rzx-p2-40000`), `DrawSprite` (`stage1/c2`) | `BossExplodes` (`stage1/rec/rzx-p2-40000`), `DrawObject` (`stage1/rec/rzx-p2-08000`), `UpdateObject` (`stage1/c2`), `ShardLoop` (code) |
| `$A1D1` | `ObjectHitCount` (`FireLatch`+38) | 1 | the hits an object took | - | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A1D2` | `KillFlashPtr` (`FireLatch`+39) | 2 | the combo row cell lit by the latest hit (`$5843` + 3 a hit; at rest `$E9FF`) | `HitObjectHard` (`stage1/rec/rzx-p2-10000`), `KillFlashFade` (`stage1/c2`) | `BuildRoom` (`stage1/c2`), `HitObject` (`stage1/rec/rzx-p2-10000`), `HitObjectHard` (`stage1/rec/rzx-p2-10000`), `KillObject` (`stage1/c2`), `ObjectFall` (`stage1/rec/rzx-p2-14000`) |
| `$A1D4` | `ComboCount` (`FireLatch`+41) | 1 | kills in a row | `HitObjectHard` (`stage1/rec/rzx-p2-10000`) | `HitObject` (`stage1/rec/rzx-p2-10000`), `HitObjectHard` (`stage1/rec/rzx-p2-10000`) |
| `$A1D5` | `ComboTimer` (`FireLatch`+42) | 2 | passes left for the next kill to count in the row | `HitObjectHard` (`stage1/rec/rzx-p2-10000`) | `HitObject` (`stage1/rec/rzx-p2-10000`), `HitObjectHard` (`stage1/rec/rzx-p2-10000`), `KillObject` (`stage1/c2`), `ObjectFall` (`stage1/rec/rzx-p2-14000`) |
| `$A1D7` | `Score` (`FireLatch`+44) | 2 | the score, in hundreds | `AddScore` (`stage1/rec/rzx-p2-00000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `ShowScore` (`stage1/c2`), `GameOver` (code) | `AddScore` (`stage1/rec/rzx-p2-00000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A1D9` | `RapidShotsOn` (`FireLatch`+46) | 1 | the 100 RAPID SHOTS bonus runs | `FireWeapon` (`stage1/c2`), `MainLoop` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `FireGun` (code), `PrizeRapidShots` (code) |
| `$A1DA` | `RapidShotsLeft` (`FireLatch`+47) | 1 | its shots left | `FireGun` (code) | `FireGun` (code), `PrizeRapidShots` (code) |
| `$A1DB` | `FadeStepIndex` (`FireLatch`+48) | 1 | the power pod's HUD flash step, `$FF` at rest (FadeStep `$996A`) | `FadeStep` (`stage1/c2`), `HudSweep` (`stage1/c2`), `PowerBar` (`stage1/c2`) | `FadeStep` (`stage1/rec/rzx-p2-00000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `TakePowerPod` (`stage1/rec/rzx-p2-00000`) |
| `$A1DC` | `SpawnTimer` (`FireLatch`+49) | 1 | passes to the next random spawn | `SpawnRandom` (`stage1/c2`) | `ReadExits` (`stage1/c2`), `SpawnRandom` (`stage1/c2`) |
| `$A1DD` | `SpawnPeriod` (`FireLatch`+50) | 1 | the room's spawn period | `SpawnRandom` (`stage1/c2`) | `ReadExits` (`stage1/c2`) |
| `$A1DE` | `ScriptSpawnStep` (`FireLatch`+51) | 1 | the scripted spawn's step 0 off (the scripted spawn never starts in part 2) | `SpawnRandom` (`stage1/c2`), `SpawnScripted` (`stage1/c2`), `StartScriptSpawn` (code) | `BuildRoom` (`stage1/c2`), `ScriptEnd` (code), `ScriptRecord` (code), `StartScriptSpawn` (code) |
| `$A1DF` | `ScriptSpawnTimer` (`FireLatch`+52) | 2 | passes to the next scripted spawn | `ScriptNext` (code) | `ScriptNext` (code), `StartScriptSpawn` (code) |
| `$A1E1` | `ScriptSpawnCount` (`FireLatch`+54) | 1 | scripted spawns made | `SpawnScripted` (code) | `ScriptNext` (code), `SpawnScripted` (code), `StartScriptSpawn` (code) |
| `$A1E2` | `ShieldOn` (`FireLatch`+55) | 3 | the shield is on | `CellsUnderRex` (`stage1/rec/rzx-p2-14000`), `DrawRex` (`stage1/c2`), `EnemyBulletsHitRex` (`stage1/rec/rzx-p2-00000`), `ObjectHitsRex` (`stage1/c2`), `Recharge` (`stage1/rec/rzx-p2-04000`) +2 | `Dematerialise` (`stage1/c2`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `LifeLost` (`stage1/c2`), `NewGame` (`stage1/c2`), `ShieldDrain` (`stage1/c2`) +1 |
| `$A1E5` | `ShieldKeyLatch` (`FireLatch`+58) | 1 | the down key is held (one toggle a press) | `ShieldToggle` (`stage1/c2`) | `MainLoop` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `ShieldToggle` (`stage1/c2`) |
| `$A1E6` | `ShieldEnergy` (`FireLatch`+59) | 1 | the shield's energy, 0-99 | `CellsUnderRex` (`stage1/rec/rzx-p2-14000`), `Recharge` (`stage1/rec/rzx-p2-04000`), `ShieldDrain` (`stage1/c2`), `ShieldToggle` (`stage1/c2`), `ShowShield` (`stage1/c2`) | `CellsUnderRex` (`stage1/rec/rzx-p2-14000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `Recharge` (`stage1/rec/rzx-p2-04000`), `RexDies` (`stage1/c2`) +1 |
| `$A1E7` | `ShieldDrainRate` (`FireLatch`+60) | 1 | passes for one unit of energy while the shield is on | `ShieldDrain` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `ShieldDrain` (`stage1/c2`), `ShieldDrainFast` (`stage1/rec/rzx-p2-02000`) |
| `$A1E8` | `WeaponIcon` (`FireLatch`+61) | 1 | the gun held (always 1): BestWeapon reads it as entry 0 before HasDoubleFire .. HasSpray | `BestWeapon` (`stage1/c2`), `DrawWeaponIcon` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-04000`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A1E9` | `HasDoubleFire` (`FireLatch`+62) | 1 | the weapons held: double fire | `BestWeapon` (`stage1/c2`), `DrawWeaponIcon` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-04000`) | `EnterCode` (`stage1/c2`) |
| `$A1EA` | `HasLaser` (`FireLatch`+63) | 1 | laser | `BestWeapon` (`stage1/c2`), `DrawWeaponIcon` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-04000`) | `EnterCode` (`stage1/c2`) |
| `$A1EB` | `HasMultiple` (`FireLatch`+64) | 1 | multiple (drones) | `BestWeapon` (`stage1/rec/rzx-p2-02000`), `DrawWeaponIcon` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-04000`) | `EnterCode` (`stage1/c2`) |
| `$A1EC` | `HasSpray` (`FireLatch`+65) | 1 | spray | `BestWeapon` (`stage1/rec/rzx-p2-12000`), `DrawWeaponIcon` (`stage1/c2`) | `EnterCode` (`stage1/c2`) |
| `$A1ED` | `EnemyShotKind` (`FireLatch`+66) | 1 | the kind of the next enemy bullet | `EnemyShot` (`stage1/c2`) | `Kind5Burst` (`stage1/c2`), `Kind9Fan` (`stage1/c2`), `UpdateObject` (`stage1/c2`) |
| `$A1EE` | `Dying` (`FireLatch`+67) | 1 | Rex is dying | `AddScore` (`stage1/c2`), `EnemyBulletsHitRex` (`stage1/c2`), `MainLoop` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `ObjectHitsRex` (`stage1/c2`) +3 | `GameEntry` (`stage1/rec/rzx-p2-00000`), `LifeLost` (`stage1/c2`), `NewGame` (`stage1/c2`), `RexDies` (`stage1/c2`) |
| `$A1EF` | `DeathTimer` (`FireLatch`+68) | 1 | the death animation's passes left | `DeathTimerStep` (code), `ShardNextRecord` (code) | `RexDies` (`stage1/c2`), `ShardNextRecord` (code) |
| `$A1F0` | `DeathShardPtr` (`FireLatch`+69) | 2 | the shards' path pointer | `DeathTimerStep` (code), `ShardBack` (code), `ShardNext` (code) | `RexDies` (`stage1/c2`), `ShardBack` (code), `ShardNext` (code) |
| `$A1F2` | `RestartX` (`FireLatch`+71) | 1 | the restart point: X | `LifeLost` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `SaveRestart` (`stage1/c2`) |
| `$A1F3` | `RestartY` (`FireLatch`+72) | 1 | Y | `LifeLost` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `SaveRestart` (`stage1/c2`) |
| `$A1F4` | `RestartRoom` (`FireLatch`+73) | 1 | room | `LifeLost` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `SaveRestart` (`stage1/c2`) |
| `$A1F5` | `RestartFacing` (`FireLatch`+74) | 1 | facing | - | `BuildRoom` (`stage1/c2`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A1F6` | `RexPresent` (`FireLatch`+75) | 1 | 1 when Rex is fully there (he moves and fires), 0 while he materialises or after he vanished | `Dematerialise` (`stage1/c2`), `FireWeapon` (`stage1/c2`), `RexAppears` (`stage1/c2`), `RexState` (`stage1/c2`), `SparkleUpdate` (`stage1/c2`) | `Dematerialise` (`stage1/c2`), `Materialise` (`stage1/c2`), `RexAppears` (`stage1/c2`), `SparkleDraw` (`stage1/c2`), `SparkleUpdate` (`stage1/c2`) +2 |
| `$A1F7` | `SparkleCount` (`FireLatch`+76) | 1 | the sparkle's cell mask step (18 to 0 in, 0 to 18 out) | `SparkleUpdate` (`stage1/c2`), `SparkleOut` (code) | `Dematerialise` (`stage1/c2`), `RexAppears` (`stage1/c2`), `SparkleUpdate` (`stage1/c2`), `SparkleOut` (code) |
| `$A1F8` | `SparkleOn` (`FireLatch`+77) | 1 | the sparkle's dots run | `DrawRoom` (`stage1/c2`), `SparkleDraw` (`stage1/c2`) | `Dematerialise` (`stage1/c2`), `Materialise` (`stage1/c2`), `SparkleDraw` (`stage1/c2`) |
| `$A1F9` | `SparkleMode` (`FireLatch`+78) | 1 | the sparkle is shown | `EnemyBulletsHitRex` (`stage1/c2`), `FireWeapon` (`stage1/rec/rzx-p2-02000`), `ObjectHitsRex` (`stage1/c2`), `ShieldToggle` (`stage1/c2`), `SparkleUpdate` (`stage1/c2`) +1 | `Dematerialise` (`stage1/c2`), `Materialise` (`stage1/c2`), `SparkleDraw` (`stage1/c2`), `SparkleUpdate` (`stage1/c2`), `SparkleEnd` (code) |
| `$A1FA` | `SparkleTimer` (`FireLatch`+79) | 1 | the dots' passes left | `SparkleDraw` (`stage1/c2`) | `Dematerialise` (`stage1/c2`), `Materialise` (`stage1/c2`), `SparkleDraw` (`stage1/c2`), `SparkleUpdate` (`stage1/c2`), `SparkleTimer30` (code) |
| `$A1FB` | `Vanishing` (`FireLatch`+80) | 1 | 1: the sparkle takes Rex out (a death), 0: it brings him in | `SparkleDraw` (`stage1/c2`), `SparkleUpdate` (`stage1/c2`) | `Dematerialise` (`stage1/c2`), `Materialise` (`stage1/c2`) |
| `$A1FC` | `Lives` (`FireLatch`+81) | 1 | lives left (4 at the start, up to 9) | `DeathAnimation` (`stage1/c2`), `ExtraLife` (`stage1/rec/rzx-p2-10000`), `LifeLost` (`stage1/c2`), `RexDies` (`stage1/c2`), `ShowLives` (`stage1/c2`) | `ExtraLife` (`stage1/rec/rzx-p2-10000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `LifeLost` (`stage1/c2`), `NewGame` (`stage1/c2`) |
| `$A1FD` | `SweepPos` (`FireLatch`+82) | 1 | the HUD sweep's position | `HudSweep` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `HudSweep` (`stage1/c2`), `NewGame` (`stage1/c2`) |
| `$A1FE` | `SweepCount` (`FireLatch`+83) | 1 | sweeps made at this width | `HudSweep` (`stage1/c2`) | `HudSweep` (`stage1/c2`), `ResetSweep` (`stage1/c2`) |
| `$A1FF` | `SweepDir` (`FireLatch`+84) | 1 | the sweep's direction | `HudSweep` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `HudSweep` (`stage1/c2`), `NewGame` (`stage1/c2`) |
| `$A200` | `SweepWidth` (`FireLatch`+85) | 1 | the sweep's width (12 after ResetSweep; Rex dies when it would drop to 0) | `HudSweep` (`stage1/c2`) | `HudSweep` (`stage1/c2`), `ResetSweep` (`stage1/c2`) |
| `$A201` | `FireDelay` (`FireLatch`+86) | 1 | passes between shots | `FireLaser` (`stage1/c2`), `FireWeapon` (`stage1/rec/rzx-p2-02000`), `MoveSplitShot` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-02000`) |
| `$A202` | `AnimCount1` (`FireLatch`+87) | 1 | animation counters of the cells | `CopyFrame` (`stage1/c2`) | `CopyFrame` (`stage1/c2`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A203` | `AnimCount2` (`FireLatch`+88) | 1 | - | `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `CopyFrame` (`stage1/c2`), `MakeObject` (`stage1/c2`) | `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `CopyFrame` (`stage1/c2`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A204` | `AnimCount3` (`FireLatch`+89) | 1 | - | `MakeObject` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A205` | `Bombs` (`FireLatch`+90) | 2 | smart bombs left | `DrawHud` (`stage1/c2`), `MakeObject` (`stage1/c2`), `ShowBombs` (`stage1/rec/rzx-p2-28000`), `SmartBomb` (`stage1/rec/rzx-p2-28000`), `TakeBombPod` (code) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `SmartBomb` (`stage1/rec/rzx-p2-28000`), `TakeBombPod` (code) |
| `$A207` | `WeaponRank` (`FireLatch`+92) | 1 | the best weapon held | `BestWeapon` (`stage1/c2`), `PowerDrain` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-02000`) | `PowerDrain` (`stage1/c2`), `PowerGain` (`stage1/rec/rzx-p2-02000`), `StartWeapon` (`stage1/c2`) |
| `$A208` | `BonusRoll` (`FireLatch`+93) | 2 | the bonus roulette's position | `RouletteGive` (code), `RouletteWait` (code) | `KillHumanSet` (code), `RouletteWait` (code) |
| `$A20A` | `Immune` (`FireLatch`+95) | 1 | Rex cannot die (never set in play) | `RexDies` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A20B` | `SpeedUp` (`FireLatch`+96) | 1 | the SPEED UP bonus: passes left | `WalkLeftKey` (`stage1/c2`), `WalkRightKey` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `PrizeSpeedUp` (code), `SpeedUpTick` (code) |
| `$A20C` | `SpeedUpPhase` (`FireLatch`+97) | 3 | - | `SpeedUpTick` (code) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `PrizeSpeedUp` (code), `SpeedUpTick` (code) |
| `$A20F` | `ExtraLifeCount` (`FireLatch`+100) | 4 | hundreds of points towards the next life | `AddScore` (`stage1/rec/rzx-p2-00000`) | `AddScore` (`stage1/rec/rzx-p2-00000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A213` | `OnLift` (`FireLatch`+104) | 1 | Rex stands on a ladder or lift | `DrawRex` (`stage1/c2`), `RexState` (`stage1/rec/rzx-p2-02000`) | `CellsUnderRex` (`stage1/c2`) |
| `$A214` | `ShotSide` (`FireLatch`+105) | 1 | FindShotSlot: 0 Rex's bullets, 1 the enemies' | `FindShotSlot` (`stage1/rec/rzx-p2-22000`), `FindSlot` (`stage1/c2`), `RexShot` (`stage1/rec/rzx-p2-22000`), `SetupShot` (`stage1/c2`) | `FindEnemySlot` (`stage1/c2`), `FindShotSlot` (`stage1/c2`) |
| `$A215` | `AnimCount4` (`FireLatch`+106) | 1 | - | - | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A216` | `BonusDelay` (`FireLatch`+107) | 2 | - | `RouletteShow` (code), `RouletteWait` (code) | `KillHumanSet` (code), `RouletteWait` (code) |
| `$A218` | `RollFrame` (`FireLatch`+109) | 2 | the menu roll call: the frame | - | - |
| `$A21A` | `RollPtr` (`FireLatch`+111) | 2 | the roll call's sprite record | - | - |
| `$A21C` | `RollTextPtr` (`FireLatch`+113) | 2 | the roll call's text | - | - |
| `$A21E` | `RollShow` (`FireLatch`+115) | 1 | the roll call shows a sprite | - | - |
| `$A21F` | `RollTextNext` (`FireLatch`+116) | 2 | the next roll call text record | - | - |
| `$A221` | `SpawnKind` (`FireLatch`+118) | 1 | the kind the room spawns | `SpawnAnywhere` (`stage1/c2`) | `ReadExits` (`stage1/c2`) |
| `$A222` | `GrowthsKilled` (`FireLatch`+119) | 2 | BIO GROWTHS KILLED (every kill but kind 0; the game over panel), started from the code's score | `CountKill` (`stage1/c2`), `GameOverTexts` (code) | `CountKill` (`stage1/c2`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$A224` | `HiScore` (`FireLatch`+121) | 2 | the high score, in hundreds | `GameOver` (code), `GameOverTexts` (code) | `GameEntry` (`stage1/c2`), `GameOver` (code) |
| `$A226` | `RoomRight` (`FireLatch`+123) | 1 | the room's exits (RoomExits `$B1A7`): right | `ExitRight` (`stage1/rec/rzx-p2-00000`) | `ReadExits` (`stage1/c2`) |
| `$A227` | `RoomUp` (`FireLatch`+124) | 1 | up | `ExitTop` (`stage1/rec/rzx-p2-02000`), `RexJump` (`stage1/rec/rzx-p2-18000`) | `ReadExits` (`stage1/c2`) |
| `$A228` | `RoomDown` (`FireLatch`+125) | 1 | down | `RexFall` (`stage1/rec/rzx-p2-16000`) | `ReadExits` (`stage1/c2`) |
| `$A229` | `RoomLeft` (`FireLatch`+126) | 1 | left | `ExitLeft` (`stage1/rec/rzx-p2-02000`) | `ReadExits` (`stage1/c2`) |
| `$A22A` | `RexSpeed` (`FireLatch`+127) | 1 | Rex's sideways speed | `RexWalk` (`stage1/c2`) | `CellsUnderRex` (`stage1/c2`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `LifeLost` (`stage1/c2`), `NewGame` (`stage1/c2`), `RexWalk` (`stage1/c2`) +2 |
| `$A22B` | `ObjectCount` (`FireLatch`+128) | 1 | the room's object records | `SpawnRandom` (`stage1/c2`), `UpdateObjects` (`stage1/c2`), `SpawnScripted` (code) | `ReadExits` (`stage1/c2`) |
| `$A22C` | `Temp1` (`FireLatch`+129) | 2 | scratch and inputs | `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `BlowUp` (`stage1/c2`), `BossExplodes` (`stage1/rec/rzx-p2-40000`), `BufferToScreen` (`stage1/c2`), `ClearBuffer` (`stage1/c2`) +23 | `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `BufferToScreen` (`stage1/c2`), `BurstShot` (`stage1/c2`), `ClearBuffer` (`stage1/c2`), `ColourPiece` (`stage1/rec/rzx-p2-40000`) +28 |
| `$A22E` | `Temp2` (`FireLatch`+131) | 2 | - | `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `BlowUp` (`stage1/c2`), `BossExplodes` (`stage1/rec/rzx-p2-40000`), `ColourPiece` (`stage1/rec/rzx-p2-40000`), `CopyFrame` (`stage1/c2`) +11 | `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `ColourPiece` (`stage1/rec/rzx-p2-40000`), `CopyFrame` (`stage1/c2`), `DrawAnimCells` (`stage1/c2`), `DrawCharBlock` (`stage1/c2`) +9 |
| `$A230` | `Temp3` (`FireLatch`+133) | 2 | - | `PrintChar` (`stage1/c2`), `PrintText` (`stage1/c2`), `RexShot` (`stage1/rec/rzx-p2-22000`), `SetupShot` (`stage1/c2`) | `EnemyShot` (`stage1/c2`), `FireWeapon` (`stage1/rec/rzx-p2-02000`), `MoveSplitShot` (`stage1/c2`), `PrintText` (`stage1/c2`), `RexShot` (`stage1/c2`) |
| `$A232` | `Temp4` (`FireLatch`+135) | 4 | - | `RexShot` (`stage1/rec/rzx-p2-22000`), `SetupShot` (`stage1/c2`) | `EnemyShot` (`stage1/c2`), `FireDouble` (`stage1/c2`), `FireWeapon` (`stage1/rec/rzx-p2-02000`), `MoveSplitShot` (`stage1/c2`), `RexShot` (`stage1/c2`) |
| `$A236` | `CodeKey` (`FireLatch`+139) | 2 | the key ReadCode read last (a digit, "-" delete or "+" done) | `ReadCode` (`stage1/c2`) | `ReadCode` (`stage1/c2`) |
| `$A238` | `BoxAttr` (`FireLatch`+141) | 2 | PrintBoxed: the box's attribute | `PanelBox` (`stage1/c2`), `ReadCode` (`stage1/c2`) | `PanelBox` (`stage1/c2`), `ReadCode` (`stage1/c2`) |
| `$A23A` | `RandomSeed` (`FireLatch`+143) | 2 | Random `$A51D`'s seed | `Random` (`stage1/c2`), `Random2` (`stage1/c2`), `UnusedRandom` (code) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `Random` (`stage1/c2`), `Random2` (`stage1/c2`), `UnusedRandom` (code) |
| `$A23C` | `RandomSeed2` (`FireLatch`+145) | 1 | Random2 `$A530`'s seed | `Random2` (`stage1/c2`) | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `Random2` (`stage1/c2`) |
| `$A23D` | `DigitTemp` (`FireLatch`+146) | 2 | ToDigits `$A5AA`'s work | `DigitOf` (`stage1/c2`) | `DigitOf` (`stage1/c2`), `ToDigits` (`stage1/c2`) |
| `$A23F` | `Digits` (`FireLatch`+148) | 5 | ToDigits `$A5AA`'s five digits, units first | `AddDigit` (`stage1/c2`), `DigitsValue` (`stage1/c2`), `PrintDigits` (`stage1/c2`) | `DigitsValue` (`stage1/c2`), `EnterCode` (`stage1/c2`), `ToDigits` (`stage1/c2`) |
| `$A244` | `DefinePort` (`FireLatch`+153) | 2 | DEFINE: the port of the key read | `SetDown` (`stage1/c2`), `SetFire` (`stage1/c2`), `SetLeft` (`stage1/c2`), `SetRight` (`stage1/c2`), `SetUp` (`stage1/c2`) | `ChooseSinclair` (`stage1/c2`), `ScanKey` (`stage1/c2`), `ChooseCursor` (code), `ChooseKempston` (code) |
| `$A246` | `DefineBit` (`FireLatch`+155) | 1 | DEFINE: the BIT opcode's second byte (`$47` + 8 x bit) | `SetDown` (`stage1/c2`), `SetFire` (`stage1/c2`), `SetLeft` (`stage1/c2`), `SetRight` (`stage1/c2`), `SetUp` (`stage1/c2`) | `ChooseSinclair` (`stage1/c2`), `ScanKey` (`stage1/c2`), `ChooseCursor` (code), `ChooseKempston` (code) |
| `$A247` | `ControlXor` (`FireLatch`+156) | 1 | XORed with every port read: 0 keys, `$FF` Kempston | `ReadDown` (`stage1/c2`), `ReadFire` (`stage1/c2`), `ReadLeft` (`stage1/c2`), `ReadRight` (`stage1/c2`), `ReadUp` (`stage1/c2`) | `ChooseSinclair` (`stage1/c2`), `GameEntry` (`stage1/c2`), `ChooseCursor` (code), `ChooseKempston` (code) |
| `$A248` | `SpriteX` (`FireLatch`+157) | 1 | DrawSprite: X in pixels | `BufferAddress` (`stage1/c2`), `CellPointer` (`stage1/c2`), `DrawPiece` (`stage1/rec/rzx-p2-40000`), `DrawRex` (`stage1/c2`), `DrawShard` (`stage1/c2`) +3 | `BlowUp` (`stage1/c2`), `BossExplodes` (`stage1/rec/rzx-p2-40000`), `DrawObject` (`stage1/rec/rzx-p2-08000`), `DrawPiece` (`stage1/rec/rzx-p2-40000`), `DrawRex` (`stage1/c2`) +12 |
| `$A249` | `SpriteY` (`FireLatch`+158) | 1 | Y in lines | `BufferAddress` (`stage1/c2`), `CellPointer` (`stage1/c2`), `DrawPiece` (`stage1/rec/rzx-p2-40000`), `DrawSprite` (`stage1/c2`), `SpawnAnywhere` (`stage1/c2`) | `BlowUp` (`stage1/c2`), `BossExplodes` (`stage1/rec/rzx-p2-40000`), `DrawObject` (`stage1/rec/rzx-p2-08000`), `DrawRex` (`stage1/c2`), `DrawShard` (`stage1/c2`) +10 |
| `$A24A` | `SpriteWidth` (`FireLatch`+159) | 1 | width in bytes | `DrawPiece` (`stage1/rec/rzx-p2-40000`), `DrawSprite` (`stage1/c2`) | `BossExplodes` (`stage1/rec/rzx-p2-40000`), `DrawObject` (`stage1/rec/rzx-p2-08000`), `DrawRex` (`stage1/c2`), `RexState` (`stage1/rec/rzx-p2-02000`), `UpdateObject` (`stage1/c2`) +1 |
| `$A24B` | `SpriteHeight` (`FireLatch`+160) | 1 | height in lines | `DrawPiece` (`stage1/rec/rzx-p2-40000`), `DrawSprite` (`stage1/c2`) | `BossExplodes` (`stage1/rec/rzx-p2-40000`), `DrawObject` (`stage1/rec/rzx-p2-08000`), `DrawRex` (`stage1/c2`), `RexState` (`stage1/rec/rzx-p2-02000`), `UpdateObject` (`stage1/c2`) +1 |
| `$A24C` | `RexFrame` (`FireLatch`+161) | 3 | Rex's walking frame | `PrintBoxed` | `GameEntry` (`stage1/rec/rzx-p2-00000`), `LifeLost` (`stage1/c2`), `NewGame` (`stage1/c2`) |
| `$A24F` | `RexX` (`FireLatch`+164) | 1 | Rex: X in pixels | `PrintBoxed`, `DrawRex` (`stage1/c2`), `DriftObject` (`stage1/c2`), `EnemyBulletsHitRex` (`stage1/c2`), `FireWeapon` (`stage1/rec/rzx-p2-02000`) +13 | `ExitLeft` (`stage1/rec/rzx-p2-02000`), `ExitRight` (`stage1/rec/rzx-p2-00000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `LifeLost` (`stage1/c2`), `NewGame` (`stage1/c2`) +1 |
| `$A250` | `RexY` (`FireLatch`+165) | 1 | Y in lines | `PrintBoxed`, `CellsUnderRex` (`stage1/c2`), `DrawRex` (`stage1/c2`), `DriftObject` (`stage1/c2`), `EnemyBulletsHitRex` (`stage1/c2`) +14 | `ExitTop` (`stage1/rec/rzx-p2-02000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `LifeLost` (`stage1/c2`), `NewGame` (`stage1/c2`), `RexFall` (`stage1/c2`) +2 |
| `$A251` | `Room` (`FireLatch`+166) | 1 | the room Rex is in | `PrintBoxed`, `DrawRoom` (`stage1/c2`), `LifeLost` (`stage1/c2`), `ReadExits` (`stage1/c2`), `SaveRestart` (`stage1/c2`) | `Attract` (`stage1/c2`), `ExitLeft` (`stage1/rec/rzx-p2-02000`), `ExitRight` (`stage1/rec/rzx-p2-00000`), `ExitTop` (`stage1/rec/rzx-p2-02000`), `GameEntry` (`stage1/rec/rzx-p2-00000`) +4 |
| `$A252` | `RoomColumn` (`FireLatch`+167) | 2 | DrawRoom's column | `PrintBoxed`, `DrawRoomCell` (`stage1/c2`) | `DrawRoom` (`stage1/c2`), `DrawRoomCell` (`stage1/c2`) |
| `$A254` | `RexFacing` (`FireLatch`+169) | 1 | 0 right, 1 left | `PrintBoxed`, `DrawRex` (`stage1/c2`), `FireWeapon` (`stage1/rec/rzx-p2-02000`), `MainLoop` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) +5 | `GameEntry` (`stage1/rec/rzx-p2-00000`), `LifeLost` (`stage1/c2`), `NewGame` (`stage1/c2`), `WalkLeftKey` (`stage1/c2`), `WalkRightKey` (`stage1/c2`) |
| `$A255` | `FallSpeed` (`FireLatch`+170) | 1 | Rex's fall speed | `PrintBoxed`, `DrawRex` (`stage1/c2`), `RexFall` (`stage1/c2`), `RexState` (`stage1/rec/rzx-p2-02000`), `RexWalk` (`stage1/c2`) +1 | `CellsUnderRex` (`stage1/c2`), `ExitTop` (`stage1/rec/rzx-p2-02000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `Land` (`stage1/c2`), `LifeLost` (`stage1/c2`) +3 |
| `$A256` | `Jumping` (`FireLatch`+171) | 3 | Rex is jumping | `PrintBoxed`, `DrawRex` (`stage1/c2`), `RexFall` (`stage1/c2`), `RexJump` (`stage1/c2`), `RexState` (`stage1/rec/rzx-p2-02000`) +2 | `ExitTop` (`stage1/rec/rzx-p2-02000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `Land` (`stage1/c2`), `LifeLost` (`stage1/c2`), `NewGame` (`stage1/c2`) +3 |
| `$A259` | `JumpPtr` (`FireLatch`+174) | 2 | the jump's step in JumpSteps `$CE68` | `PrintBoxed`, `RexJump` (`stage1/c2`) | `RexJump` (`stage1/c2`), `StartJump` (`stage1/c2`) |
| `$A25B` | `AttractFlag` (`FireLatch`+176) | 1 | the attract mode runs | `PrintBoxed`, `Attract` (`stage1/c2`) | `Attract` (`stage1/c2`), `GameEntry` (`stage1/c2`) |
| `$A25C` | `AttractTimer` (`FireLatch`+177) | 1 | passes left in the attract room | `PrintBoxed`, `Attract` (`stage1/c2`) | `Attract` (`stage1/c2`) |
| `$A25D` | `CellFound` (`FireLatch`+178) | 1 | the type of the cell InList found last (IsSolid, IsPassable) | `PrintBoxed`, `ObjectFall` (`stage1/c2`), `RexFall` (`stage1/c2`), `RexJump` (`stage1/rec/rzx-p2-16000`), `RexWalk` (`stage1/c2`) | `InList` (`stage1/c2`) |
| `$A25E` | `SpriteSource` (`FireLatch`+179) | 2 | the picture DrawSprite or DrawPiece drew from; written, never read | `PrintBoxed` | `DrawPiece` (`stage1/rec/rzx-p2-40000`), `DrawSprite` (`stage1/c2`) |
| `$A260` | `CodeLength` (`FireLatch`+181) | 1 | digits typed into the code (ReadCode) | `PrintBoxed`, `ReadCode` (`stage1/c2`) | `ReadCode` (`stage1/c2`) |
| `$A261` | `CodeSum` (`FireLatch`+182) | 2 | the code's checksum digit (EnterCode) | `PrintBoxed`, `EnterCode` (`stage1/c2`) | `EnterCode` (`stage1/c2`) |
| `$A263` | `CodeScore` (`FireLatch`+184) | 2 | the score the code carries (NewGame; also the start of BIO GROWTHS KILLED) | `PrintBoxed`, `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) | `EnterCode` (`stage1/c2`) |
| `$A265` | `CodeShield` (`FireLatch`+186) | 1 | the shield charge the code carries | `PrintBoxed`, `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) | `EnterCode` (`stage1/c2`) |
| `$A266` | `CodeBombs` (`FireLatch`+187) | 1 | the smart bombs the code carries | `PrintBoxed`, `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) | `EnterCode` (`stage1/c2`) |
| `$A267` | `CodeLives` (`FireLatch`+188) | 1 | the lives the code carries | `PrintBoxed`, `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) | `EnterCode` (`stage1/c2`) |
| `$A268` | `BossDying` (`FireLatch`+189) | 1 | the big squidgy thing is exploding (BossHit, BossExplodes) | `PrintBoxed`, `BossHit` (`stage1/rec/rzx-p2-40000`), `MainLoop` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`), `RexDies` (`stage1/c2`) | `BossHit` (`stage1/rec/rzx-p2-40000`), `GameEntry` (`stage1/rec/rzx-p2-00000`), `LifeLost` (`stage1/c2`), `NewGame` (`stage1/c2`) |
| `$A269` | `BossTimer` (`FireLatch`+190) | 1 | the passes of the boss's explosion; at `$64` the ending text | `PrintBoxed`, `BossExplodes` (`stage1/rec/rzx-p2-40000`) | `BossExplodes` (`stage1/rec/rzx-p2-40000`), `BossHit` (`stage1/rec/rzx-p2-40000`) |
| `$A26A` | `BossAreaPtr` (`FireLatch`+191) | 2 | the explosion's area (ExplosionAreas `$9CF7`) | `PrintBoxed`, `BossExplodes` (`stage1/rec/rzx-p2-40000`), `ShrinkArea` (`stage1/rec/rzx-p2-40000`) | `BossHit` (`stage1/rec/rzx-p2-40000`), `ShrinkArea` (`stage1/rec/rzx-p2-40000`) |

### Part 2 (REX 2): hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A399` | `HudIconParams` | 6 | DrawCharBlock's inline parameters: picture `$8B80` (self-written), column 25 (self-written), line 0, 2 x 16. As REX 1's HudIconParams `$A1F1` (src/game/hud.asm). | `DrawCharBlock` (`stage1/c2`), `NextHudIcon` (`stage1/c2`) | `DrawBombIcons` (`stage1/c2`), `DrawHudIcon` (`stage1/c2`), `NextHudIcon` (`stage1/c2`) |
| `$A3AA` | `BombIcons` | 16 | The bomb icons by bombs left (0-3): three offsets each, `$A0` empty and `$C0` full. As REX 1's BombIcons `$A3AA` (src/game/hud.asm). | `DrawHudIcon` (`stage1/c2`) | - |
| `$A3DB` | `WeaponIconParams` | 6 | DrawCharBlock's inline parameters: picture `$8AC0` (self-written), column 1 (self-written), line 0, 2 x 16. As REX 1's WeaponIconParams `$A233` (src/game/hud.asm). | `DrawCharBlock` (`stage1/c2`), `NextWeaponIcon` (`stage1/c2`) | `DrawWeaponIcon` (`stage1/c2`), `NextWeaponIcon` (`stage1/c2`), `ShowWeaponIcons` (`stage1/c2`) |
| `$A3F4` | `HudTexts` | 62 | The HUD's texts: a row of "#", the figures 0000000:99:3, the icon row ("]\ ^\ _\ @\ ..." are the HUD's own characters). As REX 1's HudTexts `$A3F4` (src/game/hud.asm). | `PrintChar` (`stage1/c2`), `PrintText` (`stage1/c2`) | - |

### Part 2 (REX 2): grid

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A77D` | `FramesList3` | 12 of 22 | The frame lists of the animated characters, picture words to `$FFFF`: the restart marker (character 73: `$8A68-$8A88` by 8), then FramesList2. As REX 1's FramesList3 `$A5F4` (src/game/grid.asm). | `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `CopyFrame` (`stage1/c2`) | - |
| `$A789` | `FramesList2` (`FramesList3`+12) | 10 | characters 250-251: `$8A90`, `$8AA0`, `$8AB0`, `$8AA0` | `AnimateCells2` (`stage1/rec/rzx-p2-04000`), `CopyFrame` (`stage1/c2`) | - |
| `$A836` | `DroneOrbit` | 128 of 192 | The drones' orbit: 64 X, Y offset pairs round Rex, then the drone pictures at DronePicture `$A8B6`. As REX 1's DroneOrbit `$A6CB` (src/game/grid.asm). | `UpdateDrones` (`stage1/rec/rzx-p2-02000`) | - |
| `$A8B6` | `DronePicture` (`DroneOrbit`+128) | 64 | the drone's pictures | `UpdateDrones` (`stage1/rec/rzx-p2-02000`) | - |

### Part 2 (REX 2): weapons

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$B47C` | `SprayDirections` | 32 | The spray's 8 directions: [dX word][dY][..], read by FireSpray (and by part 1's mine layer burst, a leftover in ObjectMoveCode `$C30A`). As REX 1's SprayDirections `$B436` (src/game/weapons.asm). | `SetShotDirection` (`stage1/rec/rzx-p2-14000`) | - |
| `$B781` | `ShotLeftover` | 143 | Leftover: POP HL: POP AF, the end of an instruction of REX 1's code; no instruction reaches it | - | - |
| `$B9BE` | `SparkMasks` | 40 | The spark's masks by count: `$00`, `$04`, `$44`, `$54`, `$55`, `$D5`, `$DD`, `$DF`, then `$FF`. As REX 1's SparkMasks `$B943` (src/game/weapons.asm). | `MoveSparkShot` (`stage1/c2`) | - |

### Part 2 (REX 2): attract

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A986` | `AttractRooms` | 8 | The attract mode's rooms: 6, 17, 1, 20, 10, 23, 29, 32, then `$FF` (again). As REX 1's AttractRooms `$A90C` (src/game/codepanel.asm). | `Attract` (`stage1/c2`) | - |

### Part 2 (REX 2): tables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$AA00` | `LobPaths` | 67 | The type 7 shot's four paths: Y steps, each list ending `$1E` (MoveLob `$B878`) | `BurstShot`, `MakeObject`, `ReadExits`, `MoveLob` (`stage1/c2`) | - |
| `$AA43` | `LobPicture` | 4 | The type 7 shot's picture: 4 lines `$60`, `$90`, `$D0`, `$60` | `BurstShot`, `MoveLob` (`stage1/c2`) | - |
| `$AA47` | `LobPathTable` | 16 | The four paths: [start][the step repeated after the end] word pairs | `BurstShot`, `MoveLob` (`stage1/c2`) | - |
| `$AA57` | `ShardPaths` | 96 | The explosion's six shards (BlowUp): 8 X, Y offset pairs each, `$FF` ends | `BurstShot`, `CellsUnderRex`, `PrintBoxed`, `PrintText`, `DrawShard` (`stage1/c2`) | - |
| `$AAB7` | `ShardPictures` | 64 | The explosion shards' pictures, 8 bytes each (DrawShard) | `CellsUnderRex`, `PrintBoxed`, `OrChar` (`stage1/c2`) | - |
| `$AAF7` | `GameTexts` | 58 of 411 | The game's text records: [attribute][column][line] text, 0 | `CellsUnderRex`, `DrawWeaponIcon`, `PrintBoxed`, `RexFall`, `PrintChar` (`stage1/c2`) +1 | `NewGame`, `GameEntry` (`stage1/rec/rzx-p2-00000`) |
| `$AB31` | `GameOverText` (`GameTexts`+58) | 13 | GAME OVER | `CellsUnderRex`, `PrintBoxed` | - |
| `$AB3E` | `HiScoreText` (`GameTexts`+71) | 20 | HI:SCORE 0000000 | `CellsUnderRex`, `PrintBoxed` | - |
| `$AB52` | `BioGrowthsText` (`GameTexts`+91) | 28 | BIO GROWTHS KILLED:00000 | - | - |
| `$AB6E` | `EndingText` (`GameTexts`+119) | 116 | WITH THE BIG SQUIDGY / THING DESTROYED REX / CAN GO HOME AND HAVE / A NICE CUP OF TEA / AND PUT HIS FEET UP | `DrawWeaponIcon`, `PrintBoxed`, `PrintChar` (`stage1/rec/rzx-p2-40000`), `PrintText` (`stage1/rec/rzx-p2-40000`) | `NewGame` |
| `$ABE2` | `PressFireText` (`GameTexts`+235) | 28 | PRESS FIRE / TO BEGIN | `PrintBoxed`, `RexFall`, `PrintChar` (`stage1/c2`), `PrintText` (`stage1/c2`) | - |
| `$ABFE` | `BonusTexts` (`GameTexts`+263) | 19 | the bonus panels, 19 bytes each: SPEED UP | `PrintBoxed`, `RexFall` | - |
| `$AC11` | `ShieldLossText` (`GameTexts`+282) | 19 | SHIELD LOSS | `PrintBoxed`, `RexFall` | - |
| `$AC24` | `BonusPointsText` (`GameTexts`+301) | 19 | 1000 BONUS | `RexFall` | - |
| `$AC37` | `EnergyLossText` (`GameTexts`+320) | 19 | ENERGY LOSS | - | - |
| `$AC4A` | `RapidShotsText` (`GameTexts`+339) | 19 | 100 RAPID SHOTS | `RexFall` | - |
| `$AC5D` | `DoubleFireText` (`GameTexts`+358) | 17 | the flag (shown once), then DOUBLE FIRE | `PrintBoxed`, `RexFall` | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$AC6E` | `LaserText` (`GameTexts`+375) | 11 | flag, LASER | `RexFall` | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$AC79` | `MultipleText` (`GameTexts`+386) | 14 | flag, MULTIPLE | `PrintBoxed`, `RexFall` | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$AC87` | `SprayText` (`GameTexts`+400) | 11 | flag, SPRAY | `PrintBoxed`, `RexFall` | `GameEntry` (`stage1/rec/rzx-p2-00000`), `NewGame` (`stage1/c2`) |
| `$AC92` | `PixelMasks` | 8 | `$80`, `$40`, ... `$01`: a pixel's mask by X & 7 | `PrintBoxed`, `RexFall` | - |
| `$AC9A` | `ScreenLineTable` | 48 of 384 | The screen address of each of the 192 pixel lines | `ClearBuffer`, `DrawWeaponIcon`, `PrintBoxed`, `RexFall`, `DrawCharBlock` (`stage1/c2`) +3 | - |
| `$ACCA` | `ScreenLines` (`ScreenLineTable`+48) | 336 | line 24 on: the play area's 168 lines, BufferToScreen's list | `ClearBuffer`, `DrawWeaponIcon`, `PrintBoxed`, `RexFall`, `PanelRow` (`stage1/c2`) +1 | - |
| `$AE1A` | `KeyPorts` | 16 | The 8 keyboard half-rows' ports, ScanKey's order | `ClearBuffer`, `ScanKey` (`stage1/c2`) | - |
| `$AE2A` | `KeyNames` | 40 | The key characters of the 40 keys in the order of KeyPorts (CAPS as "-", ENTER "+", SYMBOL "."): DEFINE and the code echo them | `ClearBuffer`, `ScanKey` (`stage1/c2`) | - |
| `$AE52` | `MirrorTable` | 256 | Each byte with its bits reversed: DrawMirrored draws a picture facing left through it | `ClearBuffer`, `ClearScreen`, `DrawRoomCell`, `MakeObject`, `MakeObjects` +1 | - |
| `$AF52` | `ShiftFrames` | 8 of 112 | The pictures' frame lists: 8 offsets each, one a pixel phase (X & 7), into a pre-shifted picture | `AnimateCells` (`stage1/c2`), `DrawSprite` (`stage1/c2`) | - |
| `$AF5A` | `ShiftFrames2` (`ShiftFrames`+8) | 8 | - | `DrawSprite` (`stage1/c2`) | - |
| `$AF62` | `ShiftFrames3` (`ShiftFrames`+16) | 8 | - | - | - |
| `$AF6A` | `ShiftFrames4` (`ShiftFrames`+24) | 8 | - | `DrawSprite` (`stage1/c2`) | - |
| `$AF72` | `ShiftFrames5` (`ShiftFrames`+32) | 8 | - | - | - |
| `$AF7A` | `ShiftFrames6` (`ShiftFrames`+40) | 8 | - | `DrawSprite` (`stage1/rec/rzx-p2-10000`) | - |
| `$AF82` | `AnimFramesA` (`ShiftFrames`+48) | 32 | the frames of animated characters 252-255, even passes: 32 bytes | `AnimateCells` (`stage1/c2`) | - |
| `$AFA2` | `AnimFramesB` (`ShiftFrames`+80) | 32 | the same, odd passes | `AnimateCells` (`stage1/c2`) | - |
| `$AFC2` | `RoomObjectLists` | 485 | The rooms' object lists: a header [spawn sides: bit 7 top, 6 right, 5 left][spawn period][spawn kind] (ReadExits), then up to 16 records [kind][X][Y] (MakeObjects), `$FF` ends | `DrawRoomCell`, `MakeObject` (`stage1/c2`), `MakeObjectIY` (`stage1/c2`), `MakeObjects` (`stage1/c2`), `ReadExits` (`stage1/c2`) | - |
| `$B1A7` | `RoomExits` | 156 | The exits of the rooms 0-25: up, right, down, left (0 none), then the word of the room's object list | `ReadExits` (`stage1/c2`) | - |

### Part 2 (REX 2): panels

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D6C6` | `DebugHook` | 668 of 1018 | Leftover: POP BC: RET, the routine the development link calls (`$62BD`) | `BonusRoulette`, `DeathAnimation`, `DrawCharBlock`, `SetShotDirection`, `SetupShot` | `BossExplodes`, `DrawCharBlock`, `DrawRoom`, `SetupShot`, `DrawRoomCell` (`stage1/c2`) |
| `$D962` | `SceneryCellList` (`DebugHook`+668) | 350 | every visible scenery cell of the room, 4 bytes each (buffer address, picture address), filled by DrawRoom and redrawn each pass by DrawAnimCells (364 cells in room 0: past entry 255 the one-byte index of CellIndexMap wraps) | `SetupShot` | `DrawRoom`, `SetupShot`, `DrawRoomCell` (`stage1/c2`) |

### Part 2 (REX 2): objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$BF4B` | `BurstSpeeds` | 4 | The burst shots' horizontal speeds: `$F8`, `$FC`, `$04`, `$08` | `Kind5Burst` (`stage1/c2`) | - |
| `$C253` | `PodFrames` | 11 | The pod's frame offsets: `$00-$A0` and back, `$FF`. As REX 1's PodFrames `$BF5B` (src/game/objects.asm). | `AnimatePod` (`stage1/c2`) | - |
| `$C2DF` | `PieceInks` | 8 | The random inks of the explosion pieces and of FlashCells: 2, 3, 6, 2, 3, 6, 2, 3 | `ColourPiece` (`stage1/rec/rzx-p2-40000`), `FlashCells` (`stage1/c2`) | - |
| `$C30A` | `ObjectMoveCode` | 183 | Code of ObjectMove's kinds that no recording reached; the kit keeps it as bytes | - | - |
| `$C66B` | `ThreeReturns` | 3 | Code: RET: RET: RET; no instruction reaches the last two (the static walk stops at the first) | - | - |

### Part 2 (REX 2): rexmove

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$CE22` | `SolidCells` | 5 of 14 | The solid cell types 2, 4, 5, 6, 3 (IsSolid), then PassCells `$CE27`: 0, `$0E`, `$0F`, `$10`, `$11`, `$12`, 3, `$15`, `$16` (IsPassable). Changed from REX 1's SolidCells `$D096` (src/game/rexmove.asm). | `InList` (`stage1/c2`) | - |
| `$CE27` | `PassCells` (`SolidCells`+5) | 9 | the cells a body or a bullet passes | `InList` (`stage1/c2`) | - |
| `$CE68` | `JumpSteps` | 12 | The jump steps (Rex's jump, StartJump; an object's fall, StartFall): 6, 6, 4, 4, 2, 2, 0, 0, 0, 0, then `$FF` and 8 | `ObjectJump` (`stage1/c2`), `RexJump` (`stage1/c2`) | - |

### Part 2 (REX 2): collisions

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D244` | `BonusTextTable` | 10 | The bonus panels' texts: `$ABFE`, `$AC11`, `$AC24`, `$AC37`, `$AC4A` | - | - |

### Part 2 (REX 2): sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D4FB` | `SfxGun` | 9 of 207 | The effect descriptors. The gun's shot. As REX 1's SfxGun `$D763` (src/game/sound.asm). | `ChannelStep` (`stage1/c2`), `MakeObject` (`stage1/c2`), `StartSfxIY` (`stage1/c2`) | `BossExplodes` (`stage1/rec/rzx-p2-40000`), `BuildRoom` (`stage1/c2`), `DrawRex` (`stage1/c2`), `RexState` (`stage1/rec/rzx-p2-02000`), `DeathFlash` (code) |
| `$D504` | `SfxEnemyShot` (`SfxGun`+9) | 9 | an enemy's shot | `ChannelStep` (`stage1/c2`), `MakeObject` (`stage1/rec/rzx-p2-36000`), `StartSfxIY` (`stage1/c2`) | - |
| `$D50D` | `SfxLaser` (`SfxGun`+18) | 9 | the laser | `ChannelStep` (`stage1/c2`), `StartSfxIY` (`stage1/c2`) | - |
| `$D516` | `SfxSpray` (`SfxGun`+27) | 9 | the spray | `ChannelStep` (`stage1/rec/rzx-p2-12000`), `StartSfxIY` (`stage1/rec/rzx-p2-12000`) | - |
| `$D51F` | `SfxHitWall` (`SfxGun`+36) | 9 | a bullet meeting a wall | `ChannelStep` (`stage1/rec/rzx-p2-02000`), `MakeObject` (`stage1/rec/rzx-p2-18000`), `StartSfxIY` (`stage1/rec/rzx-p2-02000`) | - |
| `$D528` | `SfxExplosion` (`SfxGun`+45) | 12 | an object killed (noise) | `ChannelStep` (`stage1/c2`), `MakeObject` (`stage1/rec/rzx-p2-00000`), `StartSfxIY` (`stage1/c2`) | `BossExplodes` (`stage1/rec/rzx-p2-40000`), `BuildRoom` (`stage1/c2`), `DeathFlash` (code) |
| `$D534` | `SfxShield` (`SfxGun`+57) | 4 | the shield's hum while it is on (DrawRex) | `StartSfxIY` (`stage1/c2`) | - |
| `$D538` | `SfxShieldTone` (`SfxGun`+61) | 14 | its period word: `$04B0` + a random 0-31, written by DrawRex; the block's last nine bytes, `$D53D-$D545`, are a full descriptor (DEMO's shield-hit sound) that nothing refers to | `ChannelStep` (`stage1/c2`), `StartSfxIY` (`stage1/c2`) | `DrawRex` (`stage1/c2`), `RexState` (`stage1/rec/rzx-p2-02000`) |
| `$D546` | `SfxMaterialise` (`SfxGun`+75) | 12 | Rex appears | `ChannelStep` (`stage1/c2`), `MakeObject` (`stage1/rec/rzx-p2-16000`), `StartSfxIY` (`stage1/c2`) | - |
| `$D552` | `SfxDematerialise` (`SfxGun`+87) | 12 | Rex vanishes | `ChannelStep` (`stage1/c2`), `MakeObject` (`stage1/c2`), `StartSfxIY` (`stage1/c2`) | - |
| `$D55E` | `SfxBigPod` (`SfxGun`+99) | 21 | a big power pod (TakePowerPod) | `ChannelStep` (`stage1/rec/rzx-p2-00000`), `StartSfxIY` (`stage1/rec/rzx-p2-00000`) | - |
| `$D573` | `SfxPowerPod` (`SfxGun`+120) | 21 | a power pod | `ChannelStep` (`stage1/rec/rzx-p2-14000`), `StartSfxIY` (`stage1/rec/rzx-p2-00000`) | - |
| `$D588` | `SfxBombPod` (`SfxGun`+141) | 21 | a bomb pod | - | - |
| `$D59D` | `SfxRestart` (`SfxGun`+162) | 33 | a restart point saved (three notes) | `ChannelStep` (`stage1/rec/rzx-p2-02000`), `StartSfxIY` (`stage1/rec/rzx-p2-02000`) | - |
| `$D5BE` | `SfxRecharge` (`SfxGun`+195) | 12 | the shield recharging | `ChannelStep` (`stage1/rec/rzx-p2-04000`), `StartSfxIY` (`stage1/rec/rzx-p2-04000`) | - |
| `$D5CA` | `Channels` | 35 of 63 | the three channels' state, 8 bytes each: [steps left or `$FF` free][count][step pointer][tone word][noise][volume] | `BulletLoop` (`stage1/rec/rzx-p2-20000`), `BulletsHitObject` (`stage1/rec/rzx-p2-08000`), `CellsUnderRex` (`stage1/rec/rzx-p2-14000`), `ChannelStep` (`stage1/c2`), `DrawRex` (`stage1/c2`) +12 | `ChannelStep` (`stage1/c2`), `SoundReset` (`stage1/c2`), `SoundStep` (`stage1/c2`), `StartSfxIY` (`stage1/c2`) |
| `$D5ED` | `Mixer` (`Channels`+35) | 2 | the mixer value (register 7) | `StartSfxIY` (`stage1/c2`), `WriteMixer` (`stage1/c2`) | `SoundReset` (`stage1/c2`), `StartSfxIY` (`stage1/c2`) |
| `$D5EF` | `ChannelNumber` (`Channels`+37) | 26 | the channel SoundStep is on | `ChannelStep` (`stage1/c2`), `SoundStep` (`stage1/c2`), `WriteVolume` (`stage1/c2`) | `SoundStep` (`stage1/c2`) |

### Part 2 (REX 2): menu

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DCA7` | `CodeTexts` | 120 | The code panel's texts: INVALID CODE, TRY AGAIN, INPUT YOUR CODE, USE CAPS TO DELETE:, the blank input lines | `EnterCode` (`stage1/c2`), `PrintBoxed` (`stage1/c2`), `PrintChar` (`stage1/c2`), `PrintText` (`stage1/c2`), `ReadCode` (`stage1/c2`) | `DrawRoom`, `DrawRoomCell` (`stage1/c2`), `EnterCode` (`stage1/c2`), `ReadCode` (`stage1/c2`) |
| `$DD87` | `CodeDelete` | 19 | Code: CAPS: one character back (none typed: nothing), then the next key. LD A,(`$A260`): OR A: JR Z,`$DD5F`: LD HL,(`$A238`): DEC HL: LD (`$A238`),HL: LD HL,`$A260`: DEC (HL): JR `$DD52`. No recording deleted a character (known only from the code); the kit keeps it as bytes because a recording reads these bytes as data. | - | `DrawRoom`, `DrawRoomCell` (`stage1/c2`) |
| `$DE13` | `DefineTaken` | 6 | the characters of the keys chosen so far | `ScanKey` (`stage1/c2`) | `DrawRoom`, `DrawRoomCell` (`stage1/c2`) |
| `$DE19` | `DefineKeys` | 134 of 205 | Code: 1: DEFINE: PRESS a key for each of UP, DOWN, LEFT, RIGHT, FIRE (ScanKey, the setters), then the confirm. Part 1's DefineKeys moved by `$C5`: DefineTaken cleared, PRESS, then for each control ScanKey and its setter (SetUp `$A65D`, SetDown `$A676`, SetLeft `$A62B`, SetRight `$A644`, SetFire `$A612`), ControlXor 0 and the confirm. No part 2 recording chose DEFINE (known only from the code); the kit keeps it as bytes because recording c2 reads `$DC2A-$DE45` once at frames 22596-22597 (the reader is not identified) and the rest lies in CellIndexMap's span. | `ObjectFall`, `DrawRoom` (`stage1/c2`) | `DrawRoom`, `ObjectFall`, `DrawRoomCell` (`stage1/c2`) |
| `$DE9F` | `CellIndexMap` (`DefineKeys`+134) | 71 | after the menu: each grid cell's index into SceneryCellList (DrawRoom), over this code and the menu's texts | `ObjectFall`, `DrawRoom` (`stage1/c2`) | `DrawRoom`, `ObjectFall`, `DrawRoomCell` (`stage1/c2`) |
| `$DFB0` | `MenuAgainRet` | 1 | RET after MenuAgain's JP, never reached | `CellsUnderRex`, `ObjectFall`, `PrintBoxed`, `DrawRoom` (`stage1/c2`) | `DrawRoom`, `ObjectFall`, `DrawRoomCell` (`stage1/rec/rzx-p2-04000`) |
| `$DFC6` | `MenuTexts` | 257 | The menu's text records: SELECT, 1:DEFINE, 2:KEMPSTON, 3:CURSOR, 4:SINCLAIR; the confirms; DEFINE's PRESS, :UP, :DOWN, :LEFT, :RIGHT, :FIRE (twice, two colours) | `CellsUnderRex`, `ObjectFall`, `PrintBoxed`, `TitleMenu`, `DrawRoom` (`stage1/c2`) +2 | `DrawRoom`, `ObjectFall`, `DrawRoomCell` (`stage1/c2`) |
| `$E0C7` | `MenuSpace` | 215 of 1080 | Zeros to the title screen: the room grid's space after the menu | `BulletsHitObject`, `DeathAnimation`, `EnterCode`, `FindGround`, `NextBullet` +18 | `DrawRoom`, `ObjectFall`, `SetupShot`, `DrawRoomCell` (`stage1/c2`) |
| `$E19E` | `RoomGridLeft` (`MenuSpace`+215) | 1 | the grid's origin one byte left (CellPointer with A = 0, Rex facing right) | `ObjectFall`, `DrawRoom` (`stage1/c2`) | `ObjectFall`, `DrawRoom` (`stage1/c2`) |
| `$E19F` | `RoomGrid` (`MenuSpace`+216) | 96 | the room grid's origin: the cell under (x, y) at `$E19F` + 32 x (y / 8) + x / 8 | `ObjectFall`, `DrawRoom` (`stage1/c2`), `IsSolid` (`stage1/rec/rzx-p2-02000`) | `ObjectFall`, `DrawRoom` (`stage1/c2`) |
| `$E1FF` | `RoomGridPlay` (`MenuSpace`+312) | 768 | the grid's first play row (line 24) | `BulletsHitObject`, `DeathAnimation`, `FindGround`, `NextBullet`, `ObjectDissolve` +17 | `DrawRoom`, `ObjectFall`, `SetupShot`, `DrawRoomCell` (`stage1/c2`) |
| `$E4FF` | `TitleScreen` | 96 of 6907 | The title screen (6912 bytes to `$FFFF`; the tape ends at `$FFF9`), shown by TitleMenu; then the attribute shadow (`$E4FF-$E7FE`) and the back buffer | `ClearBuffer`, `DrawRoomCell`, `EnemyBulletsHitRex`, `EnterCode`, `GameEntry` +18 | `BossExplodes`, `ClearBuffer`, `DrawRoom`, `DrawSprite`, `EnemyBulletsHitRex` +30 |
| `$E55F` | `AttrShadowPlay` (`TitleScreen`+96) | 1184 | the shadow's play rows (CopyAttrs puts them at `$5860`) | `DrawRoomCell`, `EnemyBulletsHitRex`, `EnterCode`, `GameEntry`, `RexFall` +6 | `DrawRoom`, `GameEntry`, `SetupShot`, `TitleMenu`, `BossHit` (`stage1/rec/rzx-p2-40000`) +1 |
| `$E9FF` | `ObjectBufferOrigin` (`TitleScreen`+1280) | 256 | the objects' origin | `EnterCode`, `TitleMenu`, `DrawSprite` (`stage1/c2`), `MenuCode` (`stage1/c2`) | `FadeStep`, `TitleMenu`, `DrawShotDot` (`stage1/rec/rzx-p2-14000`), `DrawSprite` (`stage1/c2`), `KillFlashFade` (`stage1/c2`) +2 |
| `$EAFF` | `BufferPlayOrigin` (`TitleScreen`+1536) | 5371 | the play lines' origin (one byte before the buffer) | `ClearBuffer`, `EnterCode`, `HudSweep`, `LifeLost`, `PrintText` +9 | `ClearBuffer`, `DrawRoom`, `DrawSprite`, `LifeLost`, `PrintText` +18 |


## DEMO (`src/demo/demo.json`)

Rex, Martech Games 1988 (The Light): DEMO, the Tutor Mode, `$61A8-$FFF9` as the ROM loader leaves it
(tools/parts.py: side 2 blocks 4 and 6 of orig/Rex.tzx.zip); entry `$8A84`. Its entries are `src/demo/<module>.asm`,
written from `src/demo/demo.ann` by `kit/mkgame.py --part src/demo/demo.json`; the readers and writers from
`work/stage1/c1`, `work/stage1/d1`, `work/stage2/rec/demo-cycle`.

### DEMO: graphics

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$61A8` | `DevLink` | 283 of 314 | Leftover: the development link's code, part 2's own (DevLink in src/rex2/graphics.asm): pages the link in, saves every register, then serves the host's commands until a return. Byte for byte part 2's but the word at `$62BE` (the return address the host's command `$B5` sets: `$DB4B` in DEMO, `$D6C6` in REX 2). Nothing calls it. | `MineBurst`, `PanelBox`, `SetSpawnLeft`, `EnemyBulletsHitRex` (`stage1/d1`), `ObjectHitsRex` (`stage1/d1`) | - |
| `$62C3` | `DevLinkGet` (`DevLink`+283) | 16 | code: E = a byte from the host (port `$1F`) after the handshake on port `$3F` | `PanelBox`, `EnemyBulletsHitRex` (`stage1/d1`), `ObjectHitsRex` (`stage1/d1`) | - |
| `$62D3` | `DevLinkPut` (`DevLink`+299) | 15 | code: a byte to the host (port `$1F`), then the handshake on port `$3F` | `MineBurst`, `PanelBox`, `EnemyBulletsHitRex` (`stage1/d1`), `ObjectHitsRex` (`stage1/d1`) | - |
| `$62E2` | `DevLinkState` | 28 | The link's state: a work word, the 26 bytes it sends (`$62E4`), the saved HL, return address and SP; tape garbage, never written in play | `MineBurst`, `PanelBox`, `EnemyBulletsHitRex` (`stage1/d1`), `ObjectHitsRex` (`stage1/d1`) | - |
| `$62FE` | `Unused62FE` | 58 | Leftover: 58 zero bytes before the font (its codes 25-31 would be at `$6300-$6337`); nothing reads them | `MineBurst`, `PanelBox`, `EnemyBulletsHitRex` (`stage1/d1`), `ObjectHitsRex` (`stage1/d1`) | - |
| `$6338` | `Font` | 512 | The font: 64 characters, codes 32-95 (space to underscore), 8 bytes each, at `$6238` + 8 x code. PrintChar, PrintDigits and the box frame of PrintBoxed read it. | `MineBurst`, `PanelBox`, `EnemyBulletsHitRex` (`stage1/d1`), `ObjectHitsRex` (`stage1/d1`), `PanelLine` (`stage1/d1`) +2 | - |
| `$6538` | `CharFlags` | 256 | The cell type of each of the 256 room characters: what Rex and the objects test in the room grid. DrawRoomCell copies CharFlags[c] into the grid for each character drawn; the types are part 1's. | `MineBurst`, `PanelBox`, `DrawRoomCell` (`stage1/d1`), `EnemyBulletsHitRex` (`stage1/d1`), `ObjectHitsRex` (`stage1/d1`) | - |
| `$6638` | `CharGraphics` | 88 of 2048 | The 256 room characters, 8 bytes each | `CellsUnderRex`, `MineBurst`, `PanelBox`, `DrawAnimCells` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`) +5 | `CellsUnderRex`, `AnimateCells` (`stage1/d1`), `CopyFrame` (`stage1/d1`), `MainLoop` (`stage1/d1`), `RollCharDown` (`stage1/d1`) +1 |
| `$6690` | `AnimChar11` (`CharGraphics`+88) | 120 | character 11, rolled one line up by RollCharUp every pass (the main loop) | `MineBurst`, `PanelBox`, `DrawAnimCells` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`), `EnemyBulletsHitRex` (`stage1/d1`) +2 | `RollCharUp` (`stage1/d1`) |
| `$6708` | `AnimChar26` (`CharGraphics`+208) | 16 | character 26, rolled one line down by RollCharDown | `MineBurst`, `PanelBox`, `DrawAnimCells` (`stage2/rec/demo-cycle`), `DrawRoomCell` (`stage2/rec/demo-cycle`), `EnemyBulletsHitRex` (`stage1/d1`) +2 | `RollCharDown` (`stage1/d1`) |
| `$6718` | `AnimChar28` (`CharGraphics`+224) | 320 | character 28, rolled one line down by RollCharDown | `CellsUnderRex`, `MineBurst`, `PanelBox`, `DrawAnimCells` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`) +3 | `CellsUnderRex`, `RollCharDown` (`stage1/d1`) |
| `$6858` | `AnimChar68` (`CharGraphics`+544) | 344 | character 68: frames from FramesChar68 (AnimateCells) | `CellsUnderRex`, `MineBurst`, `PanelBox`, `DrawAnimCells` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`) +2 | `CellsUnderRex`, `CopyFrame` (`stage1/d1`) |
| `$69B0` | `AnimChar111` (`CharGraphics`+888) | 128 | character 111: each line rotated right (RRC) by the main loop | `MineBurst`, `PanelBox`, `DrawAnimCells` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`), `EnemyBulletsHitRex` (`stage1/d1`) +2 | `MainLoop` (`stage1/d1`) |
| `$6A30` | `AnimChar127` (`CharGraphics`+1016) | 128 | character 127: frames from FramesChar127 (AnimateCells) | `MineBurst`, `PanelBox`, `DrawAnimCells` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`), `EnemyBulletsHitRex` (`stage1/d1`) +1 | `CopyFrame` (`stage1/d1`) |
| `$6AB0` | `AnimChar143` (`CharGraphics`+1144) | 848 | character 143: each line rotated left (RLC) | `MineBurst`, `PanelBox`, `DrawAnimCells` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`), `EnemyBulletsHitRex` (`stage1/d1`) +2 | `MainLoop` (`stage1/d1`) |
| `$6E00` | `AnimChar249` (`CharGraphics`+1992) | 8 | character 249: frames from FramesList3 (AnimateRestart) | `MineBurst`, `DrawAnimCells` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`) | `CopyFrame` (`stage1/d1`) |
| `$6E08` | `AnimChar250` (`CharGraphics`+2000) | 16 | character 250: frames from FramesList2 (AnimateCells2) | `MineBurst`, `DrawAnimCells` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`) | `CopyFrame` (`stage1/d1`) |
| `$6E18` | `AnimChar252` (`CharGraphics`+2016) | 32 | characters 252-255: AnimFramesA / AnimFramesB on alternate passes (AnimateCells) | `MineBurst`, `DrawAnimCells` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`) | `AnimateCells` (`stage1/d1`) |
| `$6E38` | `CharAttrs` | 256 | The attribute of each of the 256 room characters | `MineBurst`, `BulletHitsCell` (`stage2/rec/demo-cycle`), `DrawRoomCell` (`stage1/d1`) | - |
| `$6F38` | `BlockDefs` | 2304 | The 256 blocks: 3 x 3 character codes each, rows top to bottom | `MineBurst`, `DrawBlockRow` (`stage1/d1`) | - |
| `$7838` | `RoomMaps` | 420 | The room maps: 7 rows of 10 block codes each (70 bytes a room); room n at `$7838` + 70n; rooms 0-5. DrawRoom reads it; TutorRooms `$A2A2` plays rooms 4, 1, 0 and 2, and room 2 leads down to room 3. | `DrawRoom` (`stage1/d1`) | - |
| `$79DC` | `Sprites` | 504 of 4264 | The sprites, pre-shifted: each label is a picture set its owner draws through a frame list (ShiftFrames `$AF0E`: 8 words, one a pixel phase) | `CopyFrame` (`stage1/d1`), `DrawCharBlock` (`stage1/d1`), `DrawSprite` (`stage1/d1`), `MoveBeam` (`stage1/d1`) | - |
| `$7BD4` | `SpriteRexDeath` (`Sprites`+504) | 72 | Rex's death (DeathAnimation) | `DrawSprite` (`stage1/d1`) | - |
| `$7C1C` | `SpritePoints` (`Sprites`+576) | 768 | the points sign a kill leaves (ShowPoints `$8E4D`) | `DrawSprite` (`stage1/d1`) | - |
| `$7F1C` | `SpritePodPower` (`Sprites`+1344) | 192 | a power pod left by an explosion (BlowUp `$C49A`) | `DrawSprite` (`stage1/d1`) | - |
| `$7FDC` | `SpritePodBig` (`Sprites`+1536) | 192 | a big power pod left by an explosion (BlowUp) | `DrawSprite` (`stage2/rec/demo-cycle`) | - |
| `$809C` | `SpritePowerPod` (`Sprites`+1728) | 512 | the power pod's four frames (`$809C`, `$80BC`, `$80DC`, `$80FC`: AnimatePod) | `DrawSprite` (`stage1/d1`) | - |
| `$829C` | `SpriteLaserA` (`Sprites`+2240) | 24 | a long bullet (MoveBeam) | `DrawSprite` (`stage2/rec/demo-cycle`), `MoveBeam` (`stage1/d1`) | - |
| `$82B4` | `SpriteScanner` (`Sprites`+2264) | 432 | kind 8 (scanner: ScannerTurn, ScannerReset) | `DrawSprite` (`stage2/rec/demo-cycle`) | - |
| `$8464` | `SpriteHudIcons` (`Sprites`+2696) | 160 | the HUD's weapon and bomb icons (DrawHudIcon) | `DrawCharBlock` (`stage1/d1`) | - |
| `$8504` | `SpriteHudIcons2` (`Sprites`+2856) | 64 | the HUD's weapon icons, second row (DrawWeaponIcon) | `DrawCharBlock` (`stage1/d1`) | - |
| `$8544` | `SpriteBombPod` (`Sprites`+2920) | 32 | the bomb pod (`$FD`: BlowUp; kind `$7D`: InitKind7D) | `DrawSprite` (`stage1/d1`) | - |
| `$8564` | `SpriteBonusPod` (`Sprites`+2952) | 320 | the bonus pod (`$FC`: BlowUp; kind `$7C`: InitKind7C) | `CopyFrame` (`stage1/d1`), `DrawSprite` (`stage2/rec/demo-cycle`) | - |
| `$86A4` | `SpriteKind11` (`Sprites`+3272) | 32 | kind 11 (launcher, InitKind11) | `DrawSprite` (`stage1/d1`) | - |
| `$86C4` | `SpriteKind10` (`Sprites`+3304) | 32 | kind 10 (shooters, InitKind10) | `DrawSprite` (`stage1/d1`) | - |
| `$86E4` | `SpriteKind6` (`Sprites`+3336) | 32 | kind 6 (InitKind6) | - | - |
| `$8704` | `SpriteSwingGun` (`Sprites`+3368) | 160 | kind 9 (swing gun), its angles (SwingGunFrames, SwingGun) | `DrawSprite` (`stage1/d1`) | - |
| `$87A4` | `SpriteLaserB` (`Sprites`+3528) | 216 | a long bullet (MoveBeam) | `DrawSprite` (`stage1/d1`), `MoveBeam` (`stage1/d1`) | - |
| `$887C` | `SpriteJumper` (`Sprites`+3744) | 128 | a walker turned jumper (MaybeJumper) | `CopyFrame` (`stage1/d1`), `DrawSprite` (`stage2/rec/demo-cycle`) | - |
| `$88FC` | `SpriteArrow` (`Sprites`+3872) | 392 | the tutor's arrow in room 4 (TutorArrow `$8EB8`) | `DrawSprite` (`stage1/d1`) | - |

### DEMO: bomb

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$8EA8` | `KillScores` | 16 | The score of each kind 0-15 (hundreds; ShowPoints) | `ShowPoints` (`stage1/d1`) | - |
| `$8F32` | `ArrowPath` | 71 | The arrow's Y positions (TutorArrow): `$8F32` its rest (`$5EBF` from NewGame), `$8F50` the loop, `$8F5A` ArrowPath2; `$FF` ends | `TutorArrow` (`stage1/d1`) | - |

### DEMO: score

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$90DD` | `FadeSteps` | 18 | The fade's 17 steps: 1 six times, 0 five times, 2 six times, then `$FF` (the end). As REX 1's FadeSteps `$9AB3` (src/game/score.asm). | `FadeStep` (`stage1/d1`) | - |

### DEMO: death

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9237` | `DeathShards` | 54 | The shards' spread (DeathShardPtr), then the 16 shard records [frame][X][Y] (DeathAnimation) | - | - |
| `$94F2` | `SparkleMasks` | 8 of 83 | The particle's pixel mask by X & 7 (SparkleDraw), then SparkleDots `$94FA`: [count][X offset][Y] records | `Materialise` (`stage1/d1`), `SparkleDraw` (`stage1/d1`) | `Materialise` (`stage1/d1`), `SparkleDraw` (`stage1/d1`) |
| `$94FA` | `SparkleDots` (`SparkleMasks`+8) | 75 | the sparkle's particles: Y, X offset pairs | `Materialise` (`stage1/d1`), `SparkleDraw` (`stage1/d1`) | `Materialise` (`stage1/d1`), `SparkleDraw` (`stage1/d1`) |

### DEMO: hud

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$9CE6` | `HudIconParams` | 2 of 6 | DrawCharBlock's inline parameters: picture `$8524` (self-written), column 25 (self-written), line 0, 2 x 16. As REX 1's HudIconParams `$A1F1` (src/game/hud.asm). | `DrawCharBlock` (`stage1/d1`), `NextHudIcon` (`stage1/d1`) | `DrawBombIcons` (`stage1/d1`), `DrawHudIcon` (`stage1/d1`), `NextHudIcon` (`stage1/d1`) |
| `$9CE8` | `HudIconColumn` (`HudIconParams`+2) | 4 | the column, self-written by DrawBombIcons | `DrawCharBlock` (`stage1/d1`), `NextHudIcon` (`stage1/d1`) | `DrawBombIcons` (`stage1/d1`), `NextHudIcon` (`stage1/d1`) |
| `$9CF7` | `BombIcons` | 16 | The bomb icons by bombs left (0-3): three offsets each, `$A0` empty and `$C0` full. As REX 1's BombIcons `$A202` (src/game/hud.asm). | `DrawHudIcon` (`stage1/d1`) | - |
| `$9D28` | `WeaponIconParams` | 6 | DrawCharBlock's inline parameters: picture `$8464` (self-written), column 1 (self-written), line 0, 2 x 16. As REX 1's WeaponIconParams `$A233` (src/game/hud.asm). | `DrawCharBlock` (`stage1/d1`), `NextWeaponIcon` (`stage1/d1`) | `DrawWeaponIcon` (`stage1/d1`), `NextWeaponIcon` (`stage1/d1`), `ShowWeaponIcons` (`stage1/d1`) |
| `$9D41` | `HudTexts` | 62 | The HUD's texts: a row of "#", the figures 0000000:99:3, the icon row ("]\ ^\ _\ @\ ..." are the HUD's own characters). As REX 1's HudTexts `$A24C` (src/game/hud.asm). | `PrintChar` (`stage1/d1`), `PrintText` (`stage1/d1`) | - |

### DEMO: grid

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A0C8` | `FramesList3` | 14 of 52 | The frame lists of the animated characters, picture words to `$FFFF`: the restart marker (FramesList3, character 249), character 250 (`$A0D6`), character 68 (`$A0E0`), character 127 (`$A0EE`). As REX 1's FramesList3 `$A5F4` (src/game/grid.asm). | `CopyFrame` (`stage1/d1`) | - |
| `$A0D6` | `FramesList2` (`FramesList3`+14) | 10 | character 250 (AnimateCells2) | `CopyFrame` (`stage1/d1`) | - |
| `$A0E0` | `FramesChar68` (`FramesList3`+24) | 14 | character 68 (AnimateCells, AnimCount3) | `CopyFrame` (`stage1/d1`) | - |
| `$A0EE` | `FramesChar127` (`FramesList3`+38) | 14 | character 127 (AnimateCells, AnimCount4) | `CopyFrame` (`stage1/d1`) | - |
| `$A19F` | `DroneOrbit` | 128 of 192 | The drones' orbit: X, Y offset pairs round Rex, then the drone pictures at `$A21F`. As REX 1's DroneOrbit `$A6CB` (src/game/grid.asm). | `SoundStep`, `UpdateDrones` (`stage2/rec/demo-cycle`) | - |
| `$A21F` | `DronePictures` (`DroneOrbit`+128) | 64 | the drones' pictures (UpdateDrones) | `SoundStep`, `UpdateDrones` (`stage2/rec/demo-cycle`) | - |

### DEMO: weapons

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C250` | `SparkMasks` | 40 | The spark's masks by count: `$00`, `$04`, `$44`, `$54`, `$55`, `$D5`, `$DD`, `$DF`, then `$FF`. As REX 1's SparkMasks `$B943` (src/game/weapons.asm). | `MoveSparkShot` (`stage1/d1`) | - |

### DEMO: tables

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$A2A2` | `TutorRooms` | 5 | The rooms the demo plays in turn: 4, 1, 0, 2, then `$FF` (again from the start: NextTutorRoom) | `NextTutorRoom` (`stage1/d1`) | - |
| `$A2A7` | `BeamPath` | 29 | The long shot's path (MoveBeam): dX, dY pairs from `$FB`, 0 up to 8, `$14`; MoveBeam stops at `$A2C1` | `MoveBeam` (`stage1/d1`) | - |
| `$A2C4` | `TutorSpawn0` | 58 of 110 | Room 0's scripted spawn (TutorRoom0): the first delay, then records [kind `$80`][X `$E8`][Y][delay], `$FF` ends | `MakeObjectIY` (`stage2/rec/demo-cycle`), `SpawnScripted` (`stage2/rec/demo-cycle`), `StartScriptSpawn` (`stage2/rec/demo-cycle`) | - |
| `$A2FE` | `TutorSpawn2` (`TutorSpawn0`+58) | 26 | room 2's (TutorRoom2): kind `$0C` walkers from the left | `MakeObjectIY` (`stage2/rec/demo-cycle`), `SpawnScripted` (`stage2/rec/demo-cycle`), `StartScriptSpawn` (`stage2/rec/demo-cycle`) | - |
| `$A318` | `TutorSpawn3` (`TutorSpawn0`+84) | 26 | room 3's (MainLoop): six kind `$0C` from the right | `MakeObjectIY` (`stage2/rec/demo-cycle`), `SpawnScripted` (`stage2/rec/demo-cycle`), `StartScriptSpawn` (`stage2/rec/demo-cycle`) | - |
| `$A332` | `ShardPaths` | 96 | The six shards' paths of an explosion (BlowUp, DrawShard): 16 bytes each, [dX][dY] pairs | `DrawShard` (`stage1/d1`) | - |
| `$A392` | `ShardPictures` | 64 | The shards' pictures, 4 bytes each, by step (DrawShard) | `OrChar` (`stage1/d1`) | - |
| `$A3D2` | `BonusTexts` | 76 of 95 | The bonus roulette's five panels as text records [attribute][column][line] text 0: SPEED UP, SHIELD LOSS, 1000 BONUS, ENERGY LOSS, 100 RAPID SHOTS (BonusTextTable) | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A41E` | `RapidShotsText` (`BonusTexts`+76) | 19 | 100 RAPID SHOTS | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A431` | `TutorTexts` | 54 of 2133 | The tutor's panels: text records [attribute][column][line] text 0, a panel B records from its label (TutorPanel and the room tutors) | `MoveBullets`, `ReadExits`, `Scanner`, `SetHop`, `SoundStep` +5 | `SparkleDraw`, `NewGame` (`stage1/d1`), `TutorRoom0` (`stage2/rec/demo-cycle`), `WeaponPanel` (`stage1/d1`) |
| `$A467` | `TextBonus` (`TutorTexts`+54) | 69 | AN EXTRA BONUS IS AWARDED FOR RAPID HITS ON THE SOLDIERS | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A4AC` | `TextLaser` (`TutorTexts`+123) | 47 | THE LASER CAN KILL A ROW OF THE ENEMY | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A4DB` | `TextStandard` (`TutorTexts`+170) | 129 | REX STARTS WITH THE STANDARD ISSUE APA:150 MACHINE GUN ... | `PrintBoxed` (`stage1/d1`), `PrintChar` (`stage1/d1`), `PrintText` (`stage1/d1`) | - |
| `$A55C` | `TextPower` (`TutorTexts`+299) | 133 | EACH WEAPON HAS A POWER STATUS FROM: PINK:LOW UP TO WHITE: HIGH ... | `PrintBoxed` (`stage1/d1`), `PrintChar` (`stage1/d1`), `PrintText` (`stage1/d1`) | - |
| `$A5E1` | `DoubleFireText` (`TutorTexts`+432) | 66 | the station's flag (0: not shown yet), then its panel: APA:150 MKII, A DUEL SHOT VERSION OF THE OLD APA MKI | `PrintBoxed` (`stage1/d1`), `PrintChar` (`stage1/d1`), `PrintText` (`stage1/d1`), `WeaponPanel` (`stage1/d1`) | `NewGame` (`stage1/d1`), `WeaponPanel` (`stage1/d1`) |
| `$A623` | `LaserText` (`TutorTexts`+498) | 95 | flag, TUSK LASER MKIV, USED IN THE GREAT LIFE WARS ... | `PrintBoxed` (`stage1/d1`), `PrintChar` (`stage1/d1`), `PrintText` (`stage1/d1`), `WeaponPanel` (`stage1/d1`) | `NewGame` (`stage1/d1`), `WeaponPanel` (`stage1/d1`) |
| `$A682` | `MultipleText` (`TutorTexts`+593) | 99 | flag, REMOTE DRONE OFFENSIVE SYSTEM ... | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`), `WeaponPanel` (`stage2/rec/demo-cycle`) | `NewGame` (`stage1/d1`), `WeaponPanel` (`stage2/rec/demo-cycle`) |
| `$A6E5` | `SprayText` (`TutorTexts`+692) | 91 | flag, MULTI:DIRECTIONAL SPRAY PROJECTILE LAUNCHER ... | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`), `WeaponPanel` (`stage2/rec/demo-cycle`) | `NewGame` (`stage1/d1`), `TutorRoom0` (`stage2/rec/demo-cycle`), `WeaponPanel` (`stage2/rec/demo-cycle`) |
| `$A740` | `TextSpray3` (`TutorTexts`+783) | 15 | 3 WAY SPRAY | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A74F` | `TextSpray5` (`TutorTexts`+798) | 15 | 5 WAY SPRAY | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A75E` | `TextSpray7` (`TutorTexts`+813) | 15 | 7 WAY SPRAY | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A76D` | `TextSpray4` (`TutorTexts`+828) | 23 | 4 DIRECTIONAL SPRAY | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A784` | `TextSpray8` (`TutorTexts`+851) | 20 | FULL 8 WAY SPRAY | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A798` | `TextShield` (`TutorTexts`+871) | 77 | YOUR SHIELD CAN BE USED TO DESTROY THE ENEMY AND DEFLECT BULLETS | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A7E5` | `TextBubbles` (`TutorTexts`+948) | 85 | COLLECT THE BUBBLES DROPPED BY THE ENEMY TO INCREASE YOUR WEAPONS ENERGY | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A83A` | `TextBeamPads` (`TutorTexts`+1033) | 40 | USE BEAM:PADS TO RECORD POSITION | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A862` | `TextRecharge` (`TutorTexts`+1073) | 42 | STAND ON DISC TO CHARGE YOUR SHIELD | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A88C` | `TextQuestion` (`TutorTexts`+1115) | 72 | PICK UP QUESTION MARKS FOR A SKILL BONUS:USE FIRE TO SELECT | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A8D4` | `TextWalls` (`TutorTexts`+1187) | 37 | SOME WALLS CAN BE SHOT THROUGH | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A8F9` | `TextExits` (`TutorTexts`+1224) | 71 | ARROWS SUGGEST EXITS FROM SCREEN:BUT LOOK FOR SECRET PASSAGES | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A940` | `TextScanners` (`TutorTexts`+1295) | 78 | BEWARE OF SCANNERS THEY DETECT ANY MOVEMENT IN THE AREAS SHOWN | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A98E` | `TextFalling` (`TutorTexts`+1373) | 80 | IF REX FALLS DOWN A SCREEN WITHOUT AN EXIT HE IS FORCED TO BEAM OUT | `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$A9DE` | `TextTeleport` (`TutorTexts`+1453) | 63 | AFTER TELEPORTATION REX IS TAKEN TO THE LAST BEAM:PAD | `MoveBullets`, `Scanner`, `SetHop`, `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`) +1 | - |
| `$AA1D` | `TextSmartBombs` (`TutorTexts`+1516) | 109 | SMART BOMBS CAN KILL ALL THE ENEMIES ON THE SCREEN:EXTRA ONES ARE SOMETIMES LEFT BY THE ENEMY | `MoveBullets`, `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$AA8A` | `TutorIntro` (`TutorTexts`+1625) | 99 | YOU ARE ABOUT TO SEE A DEMO OF REX THE DEBUT GAME BY THE LIGHT SPACE:PAUSES DEMO | `UpdateDrones`, `PrintBoxed` (`stage1/d1`), `PrintChar` (`stage1/d1`), `PrintText` (`stage1/d1`) | - |
| `$AAED` | `TutorPrologue` (`TutorTexts`+1724) | 108 | FIRST A SHORT PROLOGUE OF HOW REX INFILTRATED THE TOWER THROUGH THE HIDDEN UNDERGROUND RIVER | `UpdateDrones`, `PrintBoxed` (`stage1/d1`), `PrintChar` (`stage1/d1`), `PrintText` (`stage1/d1`) | - |
| `$AB59` | `TutorText1` (`TutorTexts`+1832) | 69 | NEXT AN EXPLANATION OF THE FIVE WEAPON SYSTEMS REX CAN USE | `PrintBoxed` (`stage1/d1`), `PrintChar` (`stage1/d1`), `PrintText` (`stage1/d1`) | - |
| `$AB9E` | `TutorText0` (`TutorTexts`+1901) | 75 | YOU HAVE NOW SEEN THE HARDWARE:NOW THE EFFECT IT HAS ON THE ENEMY | `SoundStep`, `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | `SparkleDraw` |
| `$ABE9` | `TutorText2` (`TutorTexts`+1976) | 89 | AND FINALLY A FEW GUIDELINES ON HOW REX CAN MAKE THE BEST OF HIS SUROUNDINGS | `ReadExits`, `SoundStep`, `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$AC42` | `TutorCredits` (`TutorTexts`+2065) | 68 | ALL SOFTWARE SOUND AND VISION BY THE LIGHT | `ReadExits`, `PrintBoxed` (`stage2/rec/demo-cycle`), `PrintChar` (`stage2/rec/demo-cycle`), `PrintText` (`stage2/rec/demo-cycle`) | - |
| `$AC86` | `PixelMasks` | 8 | Leftover: the bit masks `$80`, `$40`, ... `$01` (part 2's PixelMasks); no code reads them here | `ReadExits` | - |
| `$AC8E` | `ScreenLineTable` | 48 of 384 | The screen address of each of the 192 pixel lines (PrintChar, PrintDigits, PanelBox, DrawCharBlock) | `ReadExits`, `DrawCharBlock` (`stage1/d1`), `PanelRow` (`stage1/d1`), `PrintDigits` (`stage1/d1`), `PrintText` (`stage1/d1`) +1 | - |
| `$ACBE` | `ScreenLines` (`ScreenLineTable`+48) | 336 | line 24 on: the play area's 168 lines, BufferToScreen's list | `ReadExits`, `PanelRow` (`stage1/d1`), `PrintText` (`stage1/d1`), `SaveScreen` (`stage1/d1`) | - |
| `$AE0E` | `MirrorTable` | 256 | Each byte with its bits reversed: DrawMirrored draws a picture facing left through it | `SetHop`, `WalkLeft`, `DrawSprite` (`stage1/d1`) | - |
| `$AF0E` | `ShiftFrames` | 16 of 160 | The pictures' frame lists: 8 picture words each, one a pixel phase (X & 7): kind 0, Rex, kinds 1 and 2, 12, 8, Rex jumping and shielded, the swing gun's turn, the hit flash | `SetHop`, `WalkLeft`, `DrawSprite` (`stage1/d1`) | - |
| `$AF1E` | `ShieldFrames` (`ShiftFrames`+16) | 16 | the shield bubble (DrawShield) | `DrawSprite` (`stage1/d1`) | - |
| `$AF2E` | `FramesKind1` (`ShiftFrames`+32) | 16 | kinds 1 and 2 | `DrawSprite` (`stage1/d1`) | - |
| `$AF3E` | `FramesKind12` (`ShiftFrames`+48) | 16 | kind 12 | `SetHop`, `WalkLeft`, `DrawSprite` (`stage2/rec/demo-cycle`) | - |
| `$AF4E` | `FramesKind8` (`ShiftFrames`+64) | 16 | kind 8 | `DrawSprite` (`stage2/rec/demo-cycle`) | - |
| `$AF5E` | `RexFramesJump` (`ShiftFrames`+80) | 16 | Rex jumping or falling, off a lift (DrawRex) | `DrawSprite` (`stage1/d1`) | - |
| `$AF6E` | `RexFramesWalk` (`ShiftFrames`+96) | 16 | Rex walking or standing (DrawRex) | `DrawSprite` (`stage1/d1`) | - |
| `$AF7E` | `FramesTurn` (`ShiftFrames`+112) | 16 | kind 6's turn and kind 7 (SwingGun) | `DrawSprite` (`stage2/rec/demo-cycle`) | - |
| `$AF8E` | `FramesHit` (`ShiftFrames`+128) | 32 | an object hit (HitObject, HitObjectHard) | `DrawSprite` (`stage2/rec/demo-cycle`) | - |
| `$AFAE` | `AnimFramesA` | 32 of 64 | The frames of the animated characters 252-255 on even passes: 4 x 8 bytes (AnimateCells) | `AnimateCells` (`stage1/d1`) | - |
| `$AFCE` | `AnimFramesB` (`AnimFramesA`+32) | 32 | on odd passes | `AnimateCells` (`stage1/d1`) | - |
| `$AFEE` | `RoomObjectLists` | 69 | The rooms' object lists (RoomExits' words): a header [spawn sides: bit 7 top, 6 right, 5 left][spawn period] (ReadExits: no spawn kind in DEMO), then [kind][X][Y] records, `$FF` ends | `MakeObjectIY` (`stage1/d1`), `MakeObjects` (`stage1/d1`), `ReadExits` (`stage1/d1`) | - |
| `$B033` | `RoomExits` | 36 | The exits of the rooms 0-5: up, right, down, left (0 none), then the word of the room's object list | `ReadExits` (`stage1/d1`) | - |
| `$B057` | `TutorScript0` | 400 of 2668 | Room 0's input script (TutorStep): the first count, then [input][count] pairs; input bits low = pressed: 0 fire, 1 up, 2 down (shield), 3 right, 4 left. 199 pairs, 698 passes. TutorScript1 `$B1E7`: 495 pairs, 1295 passes; TutorScript2 `$B5C7`: 309 pairs, 875 passes; TutorScript4 `$B833`: 327 pairs, 1005 passes. A script plays to its room's end (TutorNextRoom) or a death. | `TutorReset` (`stage1/d1`), `TutorStep` (`stage1/d1`) | - |
| `$B1E7` | `TutorScript1` (`TutorScript0`+400) | 992 | room 1's | `TutorReset` (`stage1/d1`), `TutorStep` (`stage1/d1`) | - |
| `$B5C7` | `TutorScript2` (`TutorScript0`+1392) | 620 | room 2's | `TutorReset` (`stage2/rec/demo-cycle`), `TutorStep` (`stage2/rec/demo-cycle`) | - |
| `$B833` | `TutorScript4` (`TutorScript0`+2012) | 656 | room 4's | `TutorReset` (`stage1/d1`), `TutorStep` (`stage1/d1`) | - |

### DEMO: objects

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$C589` | `SprayLeftover` | 8 | Leftover: 8 bytes no code reads (`$10` `$20` `$22` `$19` `$1D` `$31` `$34` `$FF`) | - | - |
| `$C5E7` | `SwingGunFrames` | 8 | The swing gun's picture offsets by angle: `$00`, `$20`, `$40`, `$60`, `$80`, `$60`, `$40`, `$20`. As REX 1's SwingGunFrames `$BECB` (src/game/objects.asm). | `SwingGun` (`stage1/d1`) | - |
| `$C677` | `PodFrames` | 11 | The pod's frame offsets: `$00-$A0` and back, `$FF`. As REX 1's PodFrames `$BF5B` (src/game/objects.asm). | `AnimatePod` (`stage1/d1`) | - |
| `$C6FB` | `FlashAttrs` | 8 | The explosion flash's attributes (FlashCells): 2, 3, 6, `$42`, `$43`, `$46`, 6, 2 | `FlashCells` (`stage1/d1`) | - |
| `$C8E5` | `ScannerFrames` | 36 | The scanner's picture words: `$82B4`, `$8374`, `$8394`, repeated (ScannerAnimate). As REX 1's ScannerFrames `$C25A` (src/game/objects.asm). | `Scanner` (`stage2/rec/demo-cycle`) | - |

### DEMO: panels

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$DB4D` | `WorkSpace` | 169 of 9389 | The work space up to the tape's end `$FFF9`: zero on the tape but for one byte at `$DCBA`, the machine stack's remains at `$FF25-$FF57` and the ROM's default user graphics A-U at `$FF58` (the 48K UDG area, saved with the block); the game overwrites it all | `BlowUp`, `DrawCharBlock`, `DrawShard`, `InitKind0`, `InitKind11` +31 | `CopyFrame`, `DrawCharBlock`, `MineBurst`, `PrintChar`, `PrintText` +26 |
| `$DBF6` | `SceneryCellList` (`WorkSpace`+169) | 681 | every visible scenery cell of the room, 4 bytes each (buffer address, picture address), filled by DrawRoomCell and redrawn each pass by DrawAnimCells | `DrawCharBlock`, `UpdateDrones` | `MineBurst`, `DrawRoomCell` (`stage1/d1`) |
| `$DE9F` | `CellIndexMap` (`WorkSpace`+850) | 768 | each grid cell's index into SceneryCellList (DrawRoom, DrawRoomCell, BulletHitsCell) | `DrawCharBlock`, `MineBurst`, `SoundStep`, `UpdateDrones`, `BulletHitsCell` (`stage2/rec/demo-cycle`) +1 | `MineBurst`, `BulletHitsCell` (`stage2/rec/demo-cycle`), `DrawRoom` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`) |
| `$E19F` | `RoomGrid` (`WorkSpace`+1618) | 96 | the room grid's origin: the cell under (x, y) at `$E19F` + 32 x (y / 8) + x / 8 | `MineBurst`, `SoundStep`, `DrawRoom` (`stage1/d1`), `IsSolid` (`stage2/rec/demo-cycle`) | `MineBurst`, `DrawRoom` (`stage1/d1`) |
| `$E1FF` | `RoomGridPlay` (`WorkSpace`+1714) | 768 | the grid's first play row (line 24) | `BlowUp`, `DrawCharBlock`, `DrawShard`, `InitKind0`, `InitKind11` +16 | `MineBurst`, `BulletHitsCell` (`stage2/rec/demo-cycle`), `DrawRoom` (`stage1/d1`), `DrawRoomCell` (`stage1/d1`) |
| `$E4FF` | `AttrShadow` (`WorkSpace`+2482) | 20 | the attribute shadow (`$E4FF-$E7FE`): FadeStep, SaveAttrs, FlashCells | `DrawCharBlock`, `SparkleDraw`, `FadeStep` (`stage1/d1`) | `DrawCharBlock`, `SparkleDraw`, `SpawnRandom`, `PowerBarColour` (`stage1/d1`), `SaveAttrs` (`stage1/d1`) |
| `$E513` | `ShieldAttrs` (`WorkSpace`+2502) | 3 | the shield figure's attributes in the shadow | `DrawCharBlock`, `SparkleDraw`, `FadeStep` (`stage1/d1`) | `DrawCharBlock`, `SparkleDraw`, `SpawnRandom`, `TutorEvents1`, `SaveAttrs` (`stage1/d1`) +1 |
| `$E516` | `HeatAttr` (`WorkSpace`+2505) | 21 | HeatColour's cell in the shadow (ShowHeat) | `DrawCharBlock`, `SparkleDraw`, `FadeStep` (`stage1/d1`) | `DrawCharBlock`, `SparkleDraw`, `SpawnRandom`, `PowerBarColour` (`stage1/d1`), `SaveAttrs` (`stage1/d1`) +1 |
| `$E52B` | `SweepAttrs` (`WorkSpace`+2526) | 52 | the HUD sweep's row in the shadow | `DrawCharBlock`, `SparkleDraw`, `CopyCells` (`stage2/rec/demo-cycle`), `FadeStep` (`stage1/d1`), `FillShadowCells` (`stage2/rec/demo-cycle`) | `CopyFrame`, `DrawCharBlock`, `SparkleDraw`, `SpawnRandom`, `HudSweep` (`stage1/d1`) +1 |
| `$E55F` | `AttrShadowPlay` (`WorkSpace`+2578) | 672 | the shadow's play rows (CopyAttrs puts them at `$5860`) | `DrawCharBlock`, `ScannerUp`, `SparkleDraw`, `SpawnScripted`, `CopyAttrs` (`stage1/d1`) +2 | `DrawCharBlock`, `MineBurst`, `SparkleDraw`, `BulletHitsCell` (`stage2/rec/demo-cycle`), `DrawRoomCell` (`stage1/d1`) |
| `$E7FF` | `ShotBufferOrigin` (`WorkSpace`+3250) | 160 | the back buffer's origin for a bullet: `$E7FF` + 32 x y + x / 8 | `DrawCharBlock` | `DrawCharBlock` |
| `$E89F` | `SparkleBufferOrigin` (`WorkSpace`+3410) | 96 | the sparkle's origin | `DrawCharBlock` | `DrawCharBlock` |
| `$E8FF` | `SpriteBufferOrigin` (`WorkSpace`+3506) | 256 | DrawSprite's origin | `DrawCharBlock` | `DrawCharBlock` |
| `$E9FF` | `ObjectBufferOrigin` (`WorkSpace`+3762) | 256 | the objects' origin (the kill flash's start, MainLoop and ShowPoints) | `DrawCharBlock`, `DrawSprite` (`stage2/rec/demo-cycle`) | `DrawCharBlock`, `TutorEvents1`, `DrawShotDot` (`stage2/rec/demo-cycle`), `DrawSprite` (`stage2/rec/demo-cycle`), `KillFlashFade` (`stage1/d1`) |
| `$EAFF` | `BufferPlayOrigin` (`WorkSpace`+4018) | 1 | the play lines' origin (one byte before the buffer) | `DrawCharBlock`, `DrawSprite` (`stage2/rec/demo-cycle`), `OrChar` (`stage1/d1`) | `DrawCharBlock`, `DrawShotDot` (`stage2/rec/demo-cycle`), `DrawSprite` (`stage2/rec/demo-cycle`), `OrChar` (`stage1/d1`), `SaveScreen` (`stage1/d1`) |
| `$EB00` | `BackBuffer` (`WorkSpace`+4019) | 5370 | the back buffer's play lines, 32 bytes a line, to `$FFFF` | `DrawCharBlock`, `PrintText`, `RollCharUp`, `BufferToScreen` (`stage1/d1`), `DrawSprite` (`stage1/d1`) +4 | `DrawCharBlock`, `MineBurst`, `PrintChar`, `PrintText`, `DrawAnimCells` (`stage1/d1`) +15 |

### DEMO: rexmove

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D395` | `SolidCells` | 5 of 12 | The solid cell types 2, 4, 5, 6, 9 (IsSolid), then PassCells `$D39A`: 0, `$0E`, `$0F`, `$10`, `$11`, `$12`, `$14` (IsPassable). Changed from REX 1's SolidCells `$D096` (src/game/rexmove.asm). | `InList` (`stage1/d1`) | - |
| `$D39A` | `PassCells` (`SolidCells`+5) | 7 | the cells a body or a bullet passes | `InList` (`stage1/d1`) | - |
| `$D3C8` | `JumpSteps` | 12 | The jump steps (StartJump; an object's fall, StartFall): 6, 6, 4, 4, 2, 2, 0, 0, 0, 0, then `$FF` and 8 | `ObjectJump` (`stage2/rec/demo-cycle`), `RexJump` (`stage1/d1`) | - |

### DEMO: collisions

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D70C` | `BonusTextTable` | 10 | The bonus roulette's five panels: SPEED UP, SHIELD LOSS, 1000 BONUS, ENERGY LOSS, 100 RAPID SHOTS | `BonusRoulette` (`stage2/rec/demo-cycle`) | - |

### DEMO: sound

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$D967` | `SfxGun` | 9 of 207 | The effect descriptors. The gun's shot. As REX 1's SfxGun `$D763` (src/game/sound.asm). | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst`, `DrawRex` (`stage1/d1`), `MainLoop` (`stage1/d1`), `DeathFlash` (code) |
| `$D970` | `SfxEnemyShot` (`SfxGun`+9) | 9 | an enemy's shot | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$D979` | `SfxLaser` (`SfxGun`+18) | 9 | the laser | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$D982` | `SfxSpray` (`SfxGun`+27) | 9 | the spray | `ChannelStep` (`stage2/rec/demo-cycle`), `StartSfxIY` (`stage2/rec/demo-cycle`) | `MineBurst` |
| `$D98B` | `SfxHitWall` (`SfxGun`+36) | 9 | a bullet meeting a wall | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$D994` | `SfxExplosion` (`SfxGun`+45) | 12 | an object killed (noise) | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst`, `MainLoop` (`stage1/d1`), `DeathFlash` (code) |
| `$D9A0` | `SfxShield` (`SfxGun`+57) | 4 | the shield's hum while it is on (DrawRex) | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$D9A4` | `SfxShieldTone` (`SfxGun`+61) | 5 | its period word: `$04B0` + a random 0-31, written by DrawRex | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst`, `DrawRex` (`stage1/d1`) |
| `$D9A9` | `SfxShieldHit` (`SfxGun`+66) | 9 | an enemy bullet on the shield (ShieldHitSound) | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$D9B2` | `SfxMaterialise` (`SfxGun`+75) | 12 | Rex appears | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$D9BE` | `SfxDematerialise` (`SfxGun`+87) | 12 | Rex vanishes | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$D9CA` | `SfxBigPod` (`SfxGun`+99) | 21 | a big power pod | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$D9DF` | `SfxPowerPod` (`SfxGun`+120) | 21 | a power pod | `ChannelStep` (`stage2/rec/demo-cycle`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$D9F4` | `SfxBombPod` (`SfxGun`+141) | 21 | a bomb pod | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$DA09` | `SfxRestart` (`SfxGun`+162) | 33 | a restart point saved | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$DA2A` | `SfxRecharge` (`SfxGun`+195) | 12 | the shield recharging | `ChannelStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) | `MineBurst` |
| `$DA36` | `Channels` | 35 of 63 | the three channels' state, 8 bytes each: [steps left or `$FF` free][count][step pointer][tone word][noise][volume] | `CellsUnderRex` (`stage1/d1`), `ChannelStep` (`stage1/d1`), `DrawRex` (`stage1/d1`), `EnemyShotSound` (`stage1/d1`), `ObjectHitsRex` (`stage1/d1`) +7 | `MineBurst`, `ChannelStep` (`stage1/d1`), `SoundReset` (`stage1/d1`), `SoundStep` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) |
| `$DA59` | `Mixer` (`Channels`+35) | 2 | the mixer value (register 7) | `StartSfxIY` (`stage1/d1`), `WriteMixer` (`stage1/d1`) | `MineBurst`, `SoundReset` (`stage1/d1`), `StartSfxIY` (`stage1/d1`) |
| `$DA5B` | `ChannelNumber` (`Channels`+37) | 26 | the channel SoundStep is on | `ChannelStep` (`stage1/d1`), `SoundStep` (`stage1/d1`), `WriteVolume` (`stage1/d1`) | `MineBurst`, `SoundStep` (`stage1/d1`) |
