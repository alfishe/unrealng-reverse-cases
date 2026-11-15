# Sound

| File | Address | Size | Readers |
| --- | --- | --- | --- |
| `rex1-effects.txt` | REX 1 `$D763-$D831` (SfxGun and the labels after it) | 207 | StartSfx `$D5E7`, SoundStep, ChannelStep |
| `rex2-effects.txt` | REX 2 `$D4FB-$D5C9` | 207 | the same routines of part 2 |
| `demo-effects.txt` | DEMO `$D967-$DA35` | 207 | the same routines of DEMO |

The AY effect descriptors, one a line in the order of the labels (SfxGun, SfxEnemyShot, SfxLaser, SfxSpray,
SfxHitWall, SfxExplosion, SfxShield, SfxMaterialise, SfxDematerialise, SfxBigPod, SfxPowerPod, SfxBombPod,
SfxRestart, SfxRecharge; DEMO's SfxShieldHit starts 9 bytes into SfxShield's line). A line is the header
`channel noise steps volume period`, then the step records `| count period-change volume-change`:

- channel 1-3: the AY channel (A, B, C) and its 8 bytes at Channels;
- noise: 0 a tone (the period word goes to the channel's tone registers), else noise (its low byte to register 6;
  the mixer opens the channel's noise and closes its tone);
- steps: the number of step records the effect plays; volume: the start volume x 16 (register 8 + channel gets it / 16);
- period: the start tone (or noise) period word;
- each step: for `count` sound steps (two a pass of the main loop) add `period-change` (signed) to the period and
  `volume-change` to the volume.

The line holds the bytes up to the next descriptor; a descriptor whose `steps` asks for more records than its line
holds (SfxEnemyShot: 2 steps, one record) plays the next descriptor's first bytes as its last step. SfxShield's period
word (SfxShieldTone) is rewritten each time the shield's hum starts ($04B0 + a random 0-31).
