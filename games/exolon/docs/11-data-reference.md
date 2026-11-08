# 11. Data reference

Every data entry of the game image `$6D60`-`$FFFF`, in address order by module (`src/game/<module>.asm`):
tables, buffers, records, variables, graphics, text. The name, the title and the description are the
source's (`src/game/game.ann`); the readers and writers are the routines the recordings saw touch it
(`work/game`, local and not in the repository).
Written by `kit/refdocs.py`.

## buffers

| Address | Name | Bytes | What | Read by | Written by |
| --- | --- | --- | --- | --- | --- |
| `$6E16` | `data_6E16` | 147 | data_6E16 | `l_6DA1`, `sub_6F1F`, `sub_7C26`, `sub_AF2B`, `sub_B0B7` | `l_6D60`, `sub_B0B7` |
| `$6F4D` | `data_6F4D` | 54 | data_6F4D | `sub_6EA9`, `sub_6F83`, `sub_B0B7` | `sub_6EA9`, `sub_6F83`, `sub_B0B7` |
| `$7014` | `data_7014` | 3 | data_7014 | `sub_B0B7` | `sub_B0B7` |
| `$701B` | `data_701B` | 3 | data_701B | `sub_B0B7` | `sub_B0B7` |
| `$7046` | `data_7046` | 259 | data_7046 | `l_6FAB`, `sub_AF2B`, `sub_B0B7` | `l_6FAB`, `sub_B0B7` |
| `$718D` | `data_718D` | 917 | data_718D | `l_6D60`, `l_A07A`, `l_A08B`, `sub_B0B7` | `sub_B0B7` |
| `$7588` | `data_7588` | 2 | data_7588 | `sub_B0B7` | `sub_B0B7` |
| `$768C` | `data_768C` | 4 | data_768C | `l_758A`, `sub_9118`, `sub_9CAF`, `sub_B0B7` | `l_758A`, `sub_8494`, `sub_9CAF`, `sub_B0B7` |
| `$76A2` | `data_76A2` | 56 | data_76A2 | `sub_AF2B`, `sub_B0B7` | `sub_B0B7` |
| `$7748` | `data_7748` | 8 | data_7748 | `sub_B0B7` | `sub_B0B7` |
| `$78CA` | `data_78CA` | 146 | data_78CA | `l_76DA`, `l_776C`, `l_79C2`, `sub_78A0`, `sub_7AB9` +2 | `l_76DA`, `l_7729`, `l_7760`, `l_776C`, `l_79C2` +5 |
| `$79B3` | `data_79B3` | 5 | data_79B3 | `sub_B0B7` | `sub_B0B7` |
| `$7AD9` | `data_7AD9` | 73 | data_7AD9 | `sub_795C`, `sub_B0B7` | `l_6FAB`, `sub_B0B7` |
| `$7B92` | `data_7B92` | 7 | data_7B92 | `l_6DA1`, `l_8280`, `sub_6F90`, `sub_7B72`, `sub_7B84` +5 | `l_6DA1`, `l_6FAB`, `l_7B22`, `l_7B4A`, `sub_7B84` +1 |
| `$7BDA` | `data_7BDA` | 21 | data_7BDA | `l_758A`, `l_8280`, `sub_7BAA`, `sub_9CE3`, `sub_B0B7` | `sub_7BAA`, `sub_B0B7` |
| `$7C24` | `data_7C24` | 2 | data_7C24 | `sub_B0B7` | `sub_B0B7` |
| `$7CEC` | `data_7CEC` | 43 | data_7CEC | `sub_B0B7` | `sub_B0B7` |
| `$7D45` | `data_7D45` | 9 | data_7D45 | `sub_B0B7` | `sub_B0B7` |
| `$7D67` | `data_7D67` | 708 | data_7D67 | `l_6DA1`, `l_8035`, `l_803E`, `l_8049`, `sub_7D17` +1 | `l_6D60`, `l_6DA1`, `sub_7D17`, `sub_B0B7` |
| `$8062` | `data_8062` | 53 | data_8062 | `sub_7D17`, `sub_B0B7` | `sub_B0B7` |
| `$80A8` | `data_80A8` | 25 | data_80A8 | `l_8057`, `sub_B0B7` | `sub_B0B7` |
| `$8269` | `data_8269` | 23 | data_8269 | `l_8057`, `sub_81A4`, `sub_8224`, `sub_B0B7` | `l_758A`, `l_8280`, `sub_8224`, `sub_B0B7` |
| `$8294` | `data_8294` | 1 | data_8294 | `l_8057`, `sub_81A4`, `sub_B0B7` | `l_8280`, `sub_B0B7` |
| `$82F2` | `data_82F2` | 10 | data_82F2 | `l_8057`, `l_8280`, `sub_81A4`, `sub_8224`, `sub_8338` +8 | `l_758A`, `l_8280`, `sub_81A4`, `sub_8224`, `sub_9CAF` +2 |
| `$83DC` | `data_83DC` | 1 | data_83DC | `l_8057`, `sub_8338`, `sub_9208`, `sub_B0B7` | `sub_8338`, `sub_9CAF`, `sub_B0B7` |
| `$845F` | `data_845F` | 25 | data_845F | `l_8057`, `sub_8391`, `sub_83DD`, `sub_8478`, `sub_B0B7` | `sub_8391`, `sub_83DD`, `sub_8478`, `sub_B0B7` |
| `$8523` | `data_8523` | 1 | data_8523 | `l_8057`, `sub_8494`, `sub_8E7B`, `sub_A645`, `sub_B0B7` | `l_6D60`, `sub_B0B7` |
| `$852E` | `data_852E` | 2247 | data_852E | `l_8057`, `sub_8524`, `sub_AF2B`, `sub_B0B7` | `sub_B0B7` |
| `$8E5A` | `data_8E5A` | 1 | data_8E5A | `l_8057`, `sub_8338`, `sub_8E4F`, `sub_B0B7` | `l_758A`, `sub_8338`, `sub_9CE3`, `sub_B0B7` |
| `$8E66` | `data_8E66` | 1 | data_8E66 | `l_8057`, `sub_8E5B`, `sub_9208`, `sub_B0B7` | `l_758A`, `sub_9CE3`, `sub_B0B7` |
| `$8E7A` | `data_8E7A` | 1 | data_8E7A | `l_8057`, `sub_8E67`, `sub_9CE3`, `sub_B0B7` | `l_6D60`, `sub_9CE3`, `sub_B0B7` |
| `$8EF4` | `data_8EF4` | 96 | data_8EF4 | `l_8057`, `sub_8E86`, `sub_8EAD`, `sub_B0B7` | `sub_8E86`, `sub_8EAD`, `sub_B0B7` |
| `$8F89` | `data_8F89` | 12 | data_8F89 | `sub_8F54`, `sub_B0B7` | `sub_8E86`, `sub_8EAD`, `sub_8F54`, `sub_B0B7` |
| `$9019` | `data_9019` | 22 | data_9019 | `sub_8F95`, `sub_9010`, `sub_902F`, `sub_B0B7` | `sub_8E86`, `sub_8EAD`, `sub_8F95`, `sub_902F`, `sub_B0B7` |
| `$90CB` | `data_90CB` | 31 | data_90CB | `sub_9071`, `sub_90A2`, `sub_90EA`, `sub_910B`, `sub_B0B7` | `sub_8E86`, `sub_9071`, `sub_90A2`, `sub_90EA`, `sub_910B` +1 |
| `$9135` | `data_9135` | 29 | data_9135 | `sub_9118`, `sub_B0B7` | `sub_8E86`, `sub_8EAD`, `sub_B0B7` |
| `$91AF` | `data_91AF` | 32 | data_91AF | `sub_9152`, `sub_91FA`, `sub_B0B7` | `sub_8E86`, `sub_9152`, `sub_91FA`, `sub_B0B7` |
| `$91ED` | `data_91ED` | 13 | data_91ED | `sub_B0B7` | `sub_B0B7` |
| `$9233` | `data_9233` | 4 | data_9233 | `sub_B0B7` | `sub_B0B7` |
| `$925A` | `data_925A` | 5 | data_925A | `l_758A`, `sub_925F`, `sub_B0B7` | `sub_8494`, `sub_B0B7` |
| `$928A` | `data_928A` | 7 | data_928A | `sub_B0B7` | `sub_B0B7` |
| `$92DB` | `data_92DB` | 32 | data_92DB | `sub_B0B7` | `sub_B0B7` |
| `$9437` | `data_9437` | 80 | data_9437 | `sub_B0B7` | `sub_8494`, `sub_9487`, `sub_B0B7` |
| `$94C6` | `data_94C6` | 51 | data_94C6 | `sub_9487`, `sub_B0B7` | `sub_B0B7` |
| `$9555` | `data_9555` | 8 | data_9555 | `sub_B0B7` | `sub_B0B7` |
| `$95B6` | `data_95B6` | 601 | data_95B6 | `sub_955D`, `sub_980F`, `sub_B0B7` | `sub_980F`, `sub_B0B7` |
| `$9865` | `data_9865` | 72 | data_9865 | `sub_9835`, `sub_98AD`, `sub_B0B7` | `sub_98AD`, `sub_B0B7` |
| `$9930` | `data_9930` | 6 | data_9930 | `sub_98BA`, `sub_B0B7` | `sub_8E86`, `sub_98BA`, `sub_B0B7` |
| `$99F2` | `data_99F2` | 6 | data_99F2 | `sub_9942`, `sub_B0B7` | `sub_8E86`, `sub_B0B7` |
| `$9A0F` | `data_9A0F` | 10 | data_9A0F | `sub_B0B7` | `sub_B0B7` |
| `$9A20` | `data_9A20` | 3 | data_9A20 | `sub_B0B7` | `sub_B0B7` |
| `$9A7E` | `data_9A7E` | 1 | data_9A7E | `sub_B0B7` | `sub_B0B7` |
| `$9A99` | `data_9A99` | 97 | data_9A99 | `l_9A26`, `sub_9AFA`, `sub_9B52`, `sub_9BB4`, `sub_B0B7` | `sub_9AFA`, `sub_B0B7` |
| `$9B4B` | `data_9B4B` | 7 | data_9B4B | `sub_9B07`, `sub_B0B7` | `sub_8E86`, `sub_B0B7` |
| `$9C25` | `data_9C25` | 88 | data_9C25 | `sub_9C15`, `sub_9C7D`, `sub_9C8B`, `sub_B0B7` | `sub_8E86`, `sub_9C7D`, `sub_B0B7` |
| `$9C9B` | `data_9C9B` | 15 | data_9C9B | `sub_B0B7` | `sub_B0B7` |
| `$9CAE` | `data_9CAE` | 1 | data_9CAE | `sub_B0B7` | `sub_B0B7` |
| `$9CE2` | `data_9CE2` | 1 | data_9CE2 | `sub_9CAF`, `sub_9CE3`, `sub_9D78`, `sub_B0B7` | `l_6D60`, `sub_9CAF`, `sub_9CE3`, `sub_B0B7` |
| `$9D47` | `data_9D47` | 49 | data_9D47 | `sub_9CE3`, `sub_B0B7` | `sub_B0B7` |
| `$9DA6` | `data_9DA6` | 2 | data_9DA6 | `sub_B0B7` | `sub_B0B7` |
| `$9DC1` | `data_9DC1` | 21 | data_9DC1 | `sub_9D7F`, `sub_B0B7` | `sub_8E86`, `sub_B0B7` |
| `$9E18` | `data_9E18` | 31 | data_9E18 | `sub_9DD6`, `sub_9E0A`, `sub_9E37`, `sub_9E64`, `sub_B0B7` | `sub_9E0A`, `sub_B0B7` |
| `$9E98` | `data_9E98` | 1 | data_9E98 | `sub_92FB`, `sub_9E85`, `sub_B0B7` | `l_758A`, `sub_92FB`, `sub_B0B7` |
| `$9EAE` | `data_9EAE` | 1 | data_9EAE | `sub_9E99`, `sub_B0B7` | `l_758A`, `sub_B0B7` |
| `$9ED6` | `data_9ED6` | 3 | data_9ED6 | `sub_8224`, `sub_8338`, `sub_9EC1`, `sub_B0B7` | `l_6D60`, `sub_B0B7` |
| `$9F13` | `data_9F13` | 13 | data_9F13 | `sub_9EEE`, `sub_9F20`, `sub_B0B7` | `sub_9F20`, `sub_B0B7` |
| `$9F6D` | `data_9F6D` | 4 | data_9F6D | `sub_9F2D`, `sub_B0B7` | `sub_8E86`, `sub_9F2D`, `sub_B0B7` |
| `$A001` | `data_A001` | 27 | data_A001 | `sub_9FBD`, `sub_A01C`, `sub_B0B7` | `sub_A01C`, `sub_B0B7` |
| `$A057` | `data_A057` | 28 | data_A057 | `sub_AF2B`, `sub_B0B7` | `sub_B0B7` |
| `$A095` | `data_A095` | 176 | data_A095 | `sub_B0B7` | `sub_B0B7` |
| `$A156` | `data_A156` | 228 | data_A156 | `sub_B0B7` | `sub_B0B7` |
| `$A266` | `data_A266` | 5 | data_A266 | `sub_A23A`, `sub_A26B`, `sub_B0B7` | `sub_8E86`, `sub_A23A`, `sub_B0B7` |
| `$A333` | `data_A333` | 31 | data_A333 | `sub_A30B`, `sub_A352`, `sub_B0B7` | `sub_8E86`, `sub_A352`, `sub_B0B7` |
| `$A406` | `data_A406` | 319 | data_A406 | `l_A367`, `sub_A545`, `sub_A5CA`, `sub_A5F4`, `sub_B0B7` | `sub_A545`, `sub_B0B7` |
| `$A5C9` | `data_A5C9` | 1 | data_A5C9 | `sub_B0B7` | `sub_B0B7` |
| `$A676` | `data_A676` | 352 | data_A676 | `sub_A553`, `sub_A645`, `sub_B0B7` | `sub_A645`, `sub_B0B7` |
| `$A814` | `data_A814` | 3 | data_A814 | `sub_A7D6`, `sub_B0B7` | `sub_8E86`, `sub_B0B7` |
| `$A8A1` | `data_A8A1` | 4 | data_A8A1 | `sub_B0B7` | `sub_B0B7` |
| `$A960` | `data_A960` | 567 | data_A960 | `sub_A817`, `sub_B0B7` | `sub_8E86`, `sub_B0B7` |
| `$ABCC` | `data_ABCC` | 3 | data_ABCC | `l_AB97`, `sub_ABCF`, `sub_AC04`, `sub_B0B7` | `sub_8E86`, `sub_B0B7` |
| `$AC2B` | `data_AC2B` | 46 | data_AC2B | `sub_B0B7` | `sub_B0B7` |
| `$AC78` | `data_AC78` | 5 | data_AC78 | `l_758A`, `sub_AC59`, `sub_AC7D`, `sub_B0B7` | `l_758A`, `sub_8494`, `sub_9CAF`, `sub_B0B7` |
| `$ACEF` | `data_ACEF` | 41 | data_ACEF | `sub_ACD1`, `sub_B0B7` | `sub_B0B7` |
| `$AD2A` | `data_AD2A` | 12 | data_AD2A | `sub_B0B7` | `sub_B0B7` |
| `$AD51` | `data_AD51` | 2 | data_AD51 | `sub_AD36`, `sub_B0B7` | `sub_AD36`, `sub_B0B7` |
| `$AD82` | `data_AD82` | 95 | data_AD82 | `l_6D60`, `l_A08B`, `sub_AF2B`, `sub_B0B7` | `l_6D60`, `sub_B0B7` |
| `$B0A8` | `data_B0A8` | 15 | data_B0A8 | `sub_B0B7` | `sub_B0B7` |
| `$B101` | `data_B101` | 1488 | data_B101 | `l_776C`, `l_79C2`, `sub_B0B7`, `sub_B0F3` | `l_776C`, `l_79C2`, `sub_B0B7`, `sub_B0F3` |
| `$B6DF` | `data_B6DF` | 13 | data_B6DF | `sub_B0B7`, `sub_B6D1`, `sub_B730` | `sub_B0B7`, `sub_B6EC`, `sub_B753` |
| `$B93D` | `data_B93D` | 7 | data_B93D | `sub_B0B7` | `sub_B0B7` |
| `$B999` | `data_B999` | 13 | data_B999 | `sub_B0B7` | `sub_B0B7` |
| `$B9AA` | `data_B9AA` | 12 | data_B9AA | `sub_B0B7` | `sub_B0B7` |
| `$B9BE` | `data_B9BE` | 26 | data_B9BE | `sub_B0B7` | `sub_B0B7` |
| `$B9F6` | `data_B9F6` | 1 | data_B9F6 | `sub_B0B7` | `sub_B0B7` |
| `$BA01` | `data_BA01` | 1388 | data_BA01 | `sub_B0B7` | `sub_B0B7`, `sub_B6D1`, `sub_B6EC`, `sub_B730` |
| `$C002` | `data_C002` | 19 | data_C002 | `sub_B0B7` | `sub_B0B7` |
| `$C077` | `data_C077` | 32 | data_C077 | `l_C05A`, `sub_B0B7` | `sub_B0B7` |
| `$C10E` | `data_C10E` | 32 | data_C10E | `sub_B0B7` | `sub_B0B7` |
| `$C16F` | `data_C16F` | 8 | data_C16F | `sub_B0B7` | `sub_B0B7` |
| `$C17F` | `data_C17F` | 42 | data_C17F | `sub_B0B7` | `sub_B0B7` |
| `$C218` | `data_C218` | 1499 | data_C218 | `l_C05A`, `l_C097`, `l_C0B1`, `sub_B0B7`, `sub_BF7E` +2 | `l_C05A`, `l_C097`, `l_C0B1`, `sub_B0B7`, `sub_BF7E` +3 |
| `$C7F4` | `data_C7F4` | 14348 | data_C7F4 | `sub_7BAA`, `sub_8494`, `sub_8524`, `sub_ADE1`, `sub_AE26` +2 | `sub_7BAA`, `sub_B0B7` |
