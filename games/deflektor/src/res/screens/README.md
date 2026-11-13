# screens

| File | Address | Size | Format | Read by |
| --- | --- | --- | --- | --- |
| title.png | `$6000` | 6912 | attribute PNG, `screen` (a whole Spectrum screen) | the title: copied whole to `$4000` |
| panel.png | `$7B80` | 1152 | attribute PNG, `linear` (1024 pixel bytes in plain rows of 32, then 128 attributes) | DrawPanel `$A50C`: rows 20-23 of the play screen |
