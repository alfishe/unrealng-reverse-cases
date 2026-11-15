# Screens

| File | Entry | Format |
| --- | --- | --- |
| `loading.png` + `loading-attr.csv` | LoadingScreen `$4000` (src/screen) | the 256 x 192 pixels, 1-bit; the 768 attributes, 32 a row |
| `menu-logo.png`, `menu-badge.png`, `menu-banner.png` | MenuLogo `$99F0` (10 x 6), MenuBadge `$9BD0` (2 x 1), MenuBanner `$9BE0` (12 x 2) | 1-bit, characters row by row |
| `panel.png` + `panel-attr.csv` | PlayPanel `$F600` (32 x 6), PanelAttrs `$FC64` | 1-bit; 32 attributes a row |

The panel as loaded is a saved play screen of the authors (score 00012042, masks BL Jr B L): the first game start
draws it, then DrawScore and DrawAllSlots write the new game's values over it.
