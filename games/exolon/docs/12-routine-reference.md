# 12. Routine reference

Every code entry of the game, in address order by module (`src/game/<module>.asm`). The name, the title and
the description are the source's (`src/game/game.ann`); the rest is what the recordings saw: `work/game` (c1's whole run (the load and 16 000 frames of seeded random play)). They are local, not in the repository; the WALKTHROUGH's commands rebuild them.
Runs count the calls of the entry itself; the time is its own t-states (callees excluded) and their share
of the recording. Memory ranges name the entries they cover. An entry no recording reached says so.
Written by `kit/refdocs.py`; edit `src/game/game.ann`, then run `kit/mkgame.py --case . --install`
(see [3. Build and load](03-build-and-load.md)) and `kit/refdocs.py --case .`.

| Module | Entries | Code entries |
| --- | --- | --- |

## buffers

`src/game/buffers.asm`

### `l_6D60` (`$6D60`)

**l_6D60**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,473 t-states own (0.00 %) |
| Called from | `l_A02A` (tail) |
| Calls | `l_6DA1`, `sub_7B99`, `sub_7BEF` |
| Reads | `$71F0` (`data_718D`); `$AD8A`-`$AD8E` (`data_AD82`) |
| Writes | `$6E16` (`data_6E16`); `$7D67` (`data_7D67`); `$8523` (`data_8523`); `$8E7A` (`data_8E7A`); `$9CE2` (`data_9CE2`); `$9ED6`-`$9ED8` (`data_9ED6`); 1 more ranges |
| Ports out | `$00FE` |

### `l_6DA1` (`$6DA1`)

**l_6DA1**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 7 calls, 527,560 t-states own (0.03 %) |
| Called from | `l_6D60`, `l_6FAB` (tail) |
| Calls | `sub_6EA9`, `sub_6F83`, `sub_6F90`, `l_6FAB` (tail), `l_758A` (tail), `sub_7D17`, `sub_8DF5`, `sub_8E03`, `sub_8E11`, `sub_ACD1`, `sub_AF2B`, `sub_B04B`, `sub_B0F3`, `sub_B6EC` |
| Reads | `$5DBF`-`$5DDD` (system); `$6E16` (`data_6E16`); `$7B97` (`data_7B92`); `$7D67` (`data_7D67`) |
| Writes | `$5DC0`-`$5DDE` (system); `$7B97` (`data_7B92`); `$7D67` (`data_7D67`) |

### `sub_6EA9` (`$6EA9`)

**sub_6EA9**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,978 calls, 16,711,132 t-states own (0.83 %) |
| Called from | `l_6DA1` |
| Calls | `sub_6F1F`, `sub_7C8F`, `sub_8097`, `sub_AD36` |
| Reads | `$6100`-`$63DF` (system); `$6F4E`-`$6F82` (`data_6F4D`) |
| Writes | `$6F5E`-`$6F81` (`data_6F4D`) |

### `sub_6F1F` (`$6F1F`)

**sub_6F1F**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 42,144 calls, 3,644,333 t-states own (0.18 %) |
| Called from | `sub_6EA9` |
| Calls | `sub_795C` |
| Reads | `$6E16` (`data_6E16`) |

### `sub_6F83` (`$6F83`)

**sub_6F83**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 10 calls, 11,475 t-states own (0.00 %) |
| Called from | `l_6DA1`, `l_6FAB` |
| Reads | `$6F5E`-`$6F80` (`data_6F4D`) |
| Writes | `$6F5E`-`$6F81` (`data_6F4D`) |

### `sub_6F90` (`$6F90`)

**sub_6F90**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 13 calls, 7,054 t-states own (0.00 %) |
| Called from | `l_6DA1` |
| Calls | `sub_8097` |
| Reads | `$59EB`-`$59F7` (screen); `$5A2B`-`$5A37` (screen); `$5A6B`-`$5A77` (screen); `$7B97` (`data_7B92`) |
| Writes | `$59EB`-`$59F8` (screen); `$5A2B`-`$5A38` (screen); `$5A6B`-`$5A78` (screen) |

### `l_6FAB` (`$6FAB`)

**l_6FAB**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3 calls, 705,654 t-states own (0.04 %) |
| Called from | `l_6DA1` (tail) |
| Calls | `l_6DA1` (tail), `sub_6F83`, `sub_7C26`, `sub_8DF5`, `sub_8E03`, `sub_8E11`, `sub_ACD1`, `sub_AD18`, `sub_ADE1`, `sub_AF2B`, `sub_B04B`, `sub_B0B7`, `sub_B0F3`, `sub_B753` |
| Reads | `$5DBF`-`$5DDD` (system); `$708B`-`$7090` (`data_7046`) |
| Writes | `$5DC0`-`$5DDE` (system); `$705B` (`data_7046`); `$708B`-`$708F` (`data_7046`); `$7AF2`-`$7B1E` (`data_7AD9`); `$7B97` (`data_7B92`) |

### `l_7017` (`$7017`)

**l_7017**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_701E` (`$701E`)

**l_701E**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_7149` (`$7149`)

**l_7149**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_7522` (`$7522`)

**sub_7522**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_7568` (`$7568`)

**sub_7568**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_758A` (`$758A`)

**l_758A**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 4,664,603 t-states own (0.23 %) |
| Called from | `l_6DA1` (tail) |
| Calls | `sub_7690`, `sub_7B72`, `sub_81A4`, `sub_8338`, `sub_83DD`, `sub_8485`, `sub_8494`, `sub_8F54`, `sub_8F95`, `sub_90A2`, `sub_90EA`, `sub_9118`, `sub_9152`, `sub_9208`, `sub_925F`, `sub_955D`, `sub_9835`, `sub_98BA`, `sub_9942`, `sub_9A19`, `sub_9A23`, `sub_9BB4`, `sub_9C15`, `sub_9C8B`, `sub_9CE3`, `sub_9D7F`, `sub_9DD6`, `sub_9E64`, `sub_9E85`, `sub_9E99`, `sub_9EC1`, `sub_9EEE`, `sub_9F2D`, `sub_9FBD`, `sub_A26B`, `sub_A30B`, `sub_A360`, `sub_A553`, `sub_A5F4`, `sub_A7D6`, `sub_A817`, `sub_ABCF`, `sub_AC59`, `sub_AC7D`, `sub_AD21`, `sub_B04B`, `sub_B0B7`, `sub_B753`, `sub_BF7E` |
| Reads | `$768C`-`$768D` (`data_768C`); `$7BDA` (`data_7BDA`); `$925A` (`data_925A`); `$AC7B`-`$AC7C` (`data_AC78`) |
| Writes | `$768C`-`$768D` (`data_768C`); `$8269` (`data_8269`); `$82F3`-`$82FA` (`data_82F2`); `$8E5A`-`$8E66` (`data_8E5A`, `sub_8E5B`, `data_8E66`); `$9E98` (`data_9E98`); `$9EAE` (`data_9EAE`); 1 more ranges |

### `sub_7690` (`$7690`)

**sub_7690**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 426 t-states own (0.00 %) |
| Called from | `l_758A` |
| Calls | `sub_8E4F`, `sub_8E5B`, `sub_8E67`, `sub_8E7B` (tail), `sub_AF2B` |

### `l_76DA` (`$76DA`)

**l_76DA**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 980 calls, 405,630 t-states own (0.02 %) |
| Called from | `sub_8224` (tail) |
| Calls | `l_7712` |
| Reads | `$78CA`-`$78D7` (`data_78CA`) |
| Writes | `$78DA`-`$78DB` (`data_78CA`) |

### `l_7712` (`$7712`)

**l_7712**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 31,360 calls, 1,521,994 t-states own (0.08 %) |
| Called from | `l_76DA`, `l_7729` (tail), `l_7760` (tail) |
| Calls | `l_7719`, `l_7729`, `l_7750`, `l_7760` |

### `l_7719` (`$7719`)

**l_7719**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 333,617 t-states own (0.02 %) |
| Called from | `l_7712` |
| Calls | `l_7729` |

### `l_7729` (`$7729`)

**l_7729**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4,288 calls, 1,005,755 t-states own (0.05 %) |
| Called from | `l_7712`, `l_7719` |
| Calls | `l_7712` (tail), `l_776C` (tail) |
| Writes | `$78DC`-`$795B` (`data_78CA`) |

### `l_7750` (`$7750`)

**l_7750**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 252,524 t-states own (0.01 %) |
| Called from | `l_7712` |
| Calls | `l_7760` |

### `l_7760` (`$7760`)

**l_7760**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,328 calls, 2,012,339 t-states own (0.10 %) |
| Called from | `l_7712`, `l_7750` |
| Calls | `l_7712` (tail), `l_776C` |
| Writes | `$78DC`-`$795B` (`data_78CA`) |

### `l_776C` (`$776C`)

**l_776C**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 980 calls, 16,139,315 t-states own (0.80 %) |
| Called from | `l_7729` (tail), `l_7760` |
| Calls | `sub_789E`, `sub_78A0`, `sub_B088` |
| Reads | `$4844`-`$502B` (screen); `$5100`-`$512B` (screen); `$5200`-`$522B` (screen); `$5300`-`$532B` (screen); `$5400`-`$542B` (screen); `$5500`-`$552B` (screen); 12 more ranges |
| Writes | `$4844`-`$502B` (screen); `$5100`-`$512B` (screen); `$5200`-`$522B` (screen); `$5300`-`$532B` (screen); `$5400`-`$542B` (screen); `$5500`-`$552B` (screen); 6 more ranges |

### `sub_789E` (`$789E`)

**sub_789E**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,037 calls, 16,640 t-states own (0.00 %) |
| Called from | `l_776C` |
| Calls | `sub_78A0` |

### `sub_78A0` (`$78A0`)

**sub_78A0**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,024 calls, 3,623,082 t-states own (0.18 %) |
| Called from | `l_776C`, `sub_789E` |
| Reads | `$5C24`-`$5C27` (system); `$5C44`-`$5C47` (system); `$5C60`-`$5C8B` (system); `$5CA0`-`$5CAB` (system); `$5CC0`-`$5CCB` (system); `$5CE0`-`$5CEB` (system); 3 more ranges |
| Writes | `$78B2`-`$78BC` (`sub_78A0`); `$78DC`-`$795B` (`data_78CA`) |

### `sub_795C` (`$795C`)

**sub_795C**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 61,703 calls, 23,396,110 t-states own (1.16 %) |
| Called from | `sub_6F1F`, `sub_9E99` |
| Calls | `l_7990` |
| Reads | `$7AD9`-`$7ADA` (`data_7AD9`) |
| Writes | `$78DA`-`$78DB` (`data_78CA`) |

### `l_7990` (`$7990`)

**l_7990**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 987,248 calls, 24,825,820 t-states own (1.24 %) |
| Called from | `sub_795C`, `l_79C2` (tail) |
| Calls | `l_79C2` |

### `l_7994` (`$7994`)

**l_7994**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_799E` (`$799E`)

**l_799E**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_79B8` (`$79B8`)

**l_79B8**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_79C2` (`$79C2`)

**l_79C2**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 473,112,825 t-states own (23.54 %) |
| Called from | `l_7990` |
| Calls | `l_7990` (tail), `sub_7AB7`, `sub_7AB9`, `sub_B088` |
| Reads | `$4000`-`$51E0` (screen); `$5200`-`$52E0` (screen); `$5300`-`$53E0` (screen); `$5400`-`$54E0` (screen); `$5500`-`$55E0` (screen); `$5600`-`$56E0` (screen); 7 more ranges |
| Writes | `$4000`-`$51E0` (screen); `$5200`-`$52E0` (screen); `$5300`-`$53E0` (screen); `$5400`-`$54E0` (screen); `$5500`-`$55E0` (screen); `$5600`-`$56E0` (screen); 5 more ranges |

### `l_79CA` (`$79CA`)

**l_79CA**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_7AB7` (`$7AB7`)

**sub_7AB7**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 993 calls, 8,729 t-states own (0.00 %) |
| Called from | `l_79C2` |
| Calls | `sub_7AB9` |

### `sub_7AB9` (`$7AB9`)

**sub_7AB9**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 1,986 calls, 1,988,605 t-states own (0.10 %) |
| Called from | `l_79C2`, `sub_7AB7` |
| Reads | `$5B06`-`$5B08` (system); `$5B26`-`$5B28` (system); `$5B46`-`$5B48` (system); `$5B66`-`$5B6A` (system); `$5B88`-`$5B8A` (system); `$5DBE`-`$5DC0` (system); 2 more ranges |
| Writes | `$78DC`-`$790B` (`data_78CA`); `$7AC6`-`$7ACB` (`sub_7AB9`) |

### `l_7B22` (`$7B22`)

**l_7B22**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 443 calls, 104,908 t-states own (0.01 %) |
| Called from | `sub_7B72` (tail) |
| Calls | `sub_7B6D` |
| Writes | `$7B92`-`$7B96` (`data_7B92`) |
| Ports in | `$EFFE` |

### `l_7B4A` (`$7B4A`)

**l_7B4A**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,820 calls, 605,976 t-states own (0.03 %) |
| Called from | `sub_7B72` (tail) |
| Calls | `sub_7B6D` |
| Writes | `$7B92`-`$7B96` (`data_7B92`) |
| Ports in | `$001F` |

### `sub_7B6D` (`$7B6D`)

**sub_7B6D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,315 calls, 476,517 t-states own (0.02 %) |
| Called from | `l_7B22`, `l_7B4A` |

### `sub_7B72` (`$7B72`)

**sub_7B72**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 307,002 t-states own (0.02 %) |
| Called from | `l_758A` |
| Calls | `l_7B22` (tail), `l_7B4A` (tail), `sub_7B84` |
| Reads | `$7B97` (`data_7B92`) |

### `sub_7B84` (`$7B84`)

**sub_7B84**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 497,486 t-states own (0.02 %) |
| Called from | `sub_7B72` |
| Reads | `$7B92`-`$7B95` (`data_7B92`) |
| Writes | `$7B92`-`$7B96` (`data_7B92`) |

### `sub_7B99` (`$7B99`)

**sub_7B99**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 325,051 t-states own (0.02 %) |
| Called from | `l_6D60` |
| Writes | `$6400`-`$64FF` (system) |

### `sub_7BAA` (`$7BAA`)

**sub_7BAA**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 20 calls, 2,676,878 t-states own (0.13 %) |
| Called from | `l_8280`, `sub_9CE3` |
| Reads | `$6400`-`$64FE` (system); `$7BDA` (`data_7BDA`); `$EF80`-`$F87F` (`data_C7F4`) |
| Writes | `$7BDA` (`data_7BDA`); `$EF80`-`$F87F` (`data_C7F4`) |

### `sub_7BEF` (`$7BEF`)

**sub_7BEF**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 181,720 t-states own (0.01 %) |
| Called from | `l_6D60` |
| Calls | `sub_B099` |
| Writes | `$6500`-`$65BF` (system); `$6600`-`$66BF` (system); `$6700`-`$687F` (system) |

### `sub_7C26` (`$7C26`)

**sub_7C26**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 644 calls, 14,247,634 t-states own (0.71 %) |
| Called from | `l_6FAB`, `sub_8338`, `sub_9071` |
| Reads | `$6E16` (`data_6E16`) |
| Ports out | `$00FE`, `$08FE`, `$10FE`, `$18FE`, `$20FE`, `$28FE`, `$30FE`, `$38FE`, `$40FE`, `$48FE`, `$50FE`, `$58FE`, `$60FE`, `$68FE`, `$70FE`, `$78FE` |

### `sub_7C3C` (`$7C3C`)

**sub_7C3C**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_7C5F` (`$7C5F`)

**sub_7C5F**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,291 calls, 476,123 t-states own (0.02 %) |
| Called from | `sub_8224` |
| Calls | `l_7CA7` (tail) |
| Writes | `$7CB6`-`$7CC8` (`l_7CA7`) |

### `sub_7C77` (`$7C77`)

**sub_7C77**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_7C8F` (`$7C8F`)

**sub_7C8F**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 42,144 calls, 6,096,832 t-states own (0.30 %) |
| Called from | `sub_6EA9` |
| Calls | `l_7CA7` |
| Writes | `$7CB6`-`$7CC8` (`l_7CA7`) |

### `l_7CA7` (`$7CA7`)

**l_7CA7**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 45,435 calls, 34,712,302 t-states own (1.73 %) |
| Called from | `sub_7C5F` (tail), `sub_7C8F` |
| Calls | `sub_80DA` |
| Reads | `$5E00`-`$60DF` (system) |
| Writes | `$5800`-`$5ADF` (screen); `$7CD0`-`$7CDD` (`l_7CA7`) |

### `sub_7D17` (`$7D17`)

**sub_7D17**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 7 calls, 38,808,955 t-states own (1.93 %) |
| Called from | `l_6DA1`, `l_A02A` |
| Calls | `sub_803D` |
| Reads | `$7D68`-`$7D88` (`data_7D67`); `$7DA3`-`$7E29` (`data_7D67`); `$7FEE`-`$7FF0` (`data_7D67`); `$8072`-`$8094` (`data_8062`) |
| Writes | `$7FEE`-`$7FF0` (`data_7D67`) |
| Ports in | `$00FE` |

### `l_7D4E` (`$7D4E`)

**l_7D4E**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_802B` (`$802B`)

**l_802B**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_802D` (`$802D`)

**l_802D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 451,582 calls, 8,128,488 t-states own (0.40 %) |
| Called from | `data_7D67`, `l_8049` |
| Calls | `l_8032`, `l_8035`, `l_8057` (tail) |
| Writes | `$4000` (screen) |

### `l_8032` (`$8032`)

**l_8032**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 6,759 calls, 101,414 t-states own (0.01 %) |
| Called from | `l_802D`, `l_8049` (tail) |
| Calls | `l_8035` |
| Ports out | `$00FE`, `$10FE` |

### `l_8035` (`$8035`)

**l_8035**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 6,760 calls, 298,684 t-states own (0.01 %) |
| Called from | `l_802D`, `l_8032` |
| Calls | `l_803E`, `l_8047` (tail), `l_8049` (tail) |
| Reads | `$4000`-`$5AFE` (screen); `$8004`-`$8005` (`data_7D67`) |
| Writes | `$4001`-`$5AFF` (screen) |

### `sub_803D` (`$803D`)

**sub_803D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 79 calls, 316 t-states own (0.00 %) |
| Called from | `sub_7D17` |
| Calls | `l_803E` |

### `l_803E` (`$803E`)

**l_803E**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 80 calls, 2,853 t-states own (0.00 %) |
| Called from | `l_8035`, `sub_803D` |
| Calls | `l_8047`, `l_8048` |
| Reads | `$8006`-`$8007` (`data_7D67`) |

### `l_8047` (`$8047`)

**l_8047**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 473,614 calls, 1,894,456 t-states own (0.09 %) |
| Called from | `l_8035` (tail), `l_803E`, `l_8057` (tail) |
| Calls | `l_8048` |

### `l_8048` (`$8048`)

**l_8048**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 473,615 calls, 1,894,467 t-states own (0.09 %) |
| Called from | `l_803E`, `l_8047` |
| Calls | `l_8049` |

### `l_8049` (`$8049`)

**l_8049**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 475,393 calls, 18,497,045 t-states own (0.92 %) |
| Called from | `l_8035` (tail), `l_8048`, `l_8057` (tail) |
| Calls | `l_802D`, `l_8032` (tail), `l_8057` |
| Reads | `$8008`-`$8009` (`data_7D67`) |
| Ports out | `$00FE`, `$10FE` |

### `l_8057` (`$8057`)

**l_8057**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 468,634 calls, 15,970,570 t-states own (0.79 %) |
| Called from | `l_802D` (tail), `l_8049` |
| Calls | `l_8047` (tail), `l_8049` (tail), `sub_8097` |
| Reads | `$4002`-`$4867` (screen); `$4878`-`$4A67` (screen); `$4A78`-`$4B67` (screen); `$4B78`-`$4C67` (screen); `$4C78`-`$4D67` (screen); `$4D78`-`$5AFE` (screen); 1 more ranges |
| Writes | `$4000`-`$5AFF` (screen) |
| Ports out | `$00FE`, `$10FE` |

### `sub_8097` (`$8097`)

**sub_8097**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 76,848 calls, 5,609,883 t-states own (0.28 %) |
| Called from | `sub_6EA9`, `sub_6F90`, `l_8057`, `sub_80C1`, `sub_80DA`, `sub_8F95`, `sub_9118`, `sub_A2D5` |

### `sub_80C1` (`$80C1`)

**sub_80C1**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4,218 calls, 590,520 t-states own (0.03 %) |
| Called from | `sub_80F3`, `sub_8122`, `sub_814E`, `sub_8179`, `sub_8391`, `sub_9362` |
| Calls | `sub_8097` |

### `sub_80DA` (`$80DA`)

**sub_80DA**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 45,435 calls, 6,360,900 t-states own (0.32 %) |
| Called from | `l_7CA7` |
| Calls | `sub_8097` |

### `sub_80F3` (`$80F3`)

**sub_80F3**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 60 calls, 10,172 t-states own (0.00 %) |
| Called from | `l_8280` |
| Calls | `sub_80C1` |
| Reads | `$62C6`-`$62CB` (system); `$62E6`-`$62EB` (system); `$6306`-`$630B` (system); `$6326`-`$632B` (system) |

### `sub_8122` (`$8122`)

**sub_8122**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 160 calls, 23,510 t-states own (0.00 %) |
| Called from | `sub_81A4`, `l_8280` |
| Calls | `sub_80C1` |
| Reads | `$6280`-`$6281` (system); `$62A0`-`$62A1` (system); `$62C0`-`$62C6` (system); `$62E0`-`$62E6` (system); `$6300`-`$6306` (system); `$6320`-`$6326` (system) |

### `sub_814E` (`$814E`)

**sub_814E**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4,421 calls, 967,068 t-states own (0.05 %) |
| Called from | `sub_81A4`, `l_8280`, `sub_9CE3` |
| Calls | `sub_80C1` |
| Reads | `$62C4`-`$62C6` (system); `$62E4`-`$62E6` (system); `$6300`-`$630B` (system); `$6320`-`$632B` (system); `$6340`-`$634B` (system) |

### `sub_8179` (`$8179`)

**sub_8179**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 72 calls, 10,669 t-states own (0.00 %) |
| Called from | `sub_81A4` |
| Calls | `sub_80C1` |
| Reads | `$6260`-`$6266` (system); `$6282`-`$6286` (system); `$62A2`-`$62A6` (system) |

### `sub_81A4` (`$81A4`)

**sub_81A4**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 451,733 t-states own (0.02 %) |
| Called from | `l_758A` |
| Calls | `sub_8122`, `sub_814E`, `sub_8179`, `sub_8224`, `l_8280` (tail), `sub_9D78` |
| Reads | `$7B94`-`$7B95` (`data_7B92`); `$826A`-`$827F` (`data_8269`); `$8294` (`data_8294`); `$82F5`-`$82F8` (`data_82F2`) |
| Writes | `$82F2`-`$82FB` (`data_82F2`) |

### `sub_8224` (`$8224`)

**sub_8224**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,291 calls, 611,145 t-states own (0.03 %) |
| Called from | `sub_81A4`, `l_8280` (tail), `sub_9CAF`, `sub_9CE3` (tail) |
| Calls | `l_76DA` (tail), `sub_7C5F` |
| Reads | `$8269`-`$826A` (`data_8269`); `$82F5`-`$82F6` (`data_82F2`); `$9ED8` (`data_9ED6`) |
| Writes | `$8269` (`data_8269`); `$82F5`-`$82F6` (`data_82F2`) |

### `sub_8229` (`$8229`)

**sub_8229**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_8253` (`$8253`)

**sub_8253**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_8280` (`$8280`)

**l_8280**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 1,528 calls, 199,096 t-states own (0.01 %) |
| Called from | `sub_81A4` (tail) |
| Calls | `sub_7BAA`, `sub_80F3`, `sub_8122`, `sub_814E`, `sub_8224` (tail) |
| Reads | `$7B92`-`$7B93` (`data_7B92`); `$7BDA` (`data_7BDA`); `$82F8`-`$82F9` (`data_82F2`) |
| Writes | `$8269` (`data_8269`); `$8294` (`data_8294`); `$82F8`-`$82FA` (`data_82F2`) |

### `l_8295` (`$8295`)

**l_8295**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_82FC` (`$82FC`)

**sub_82FC**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 848 calls, 344,727 t-states own (0.02 %) |
| Called from | `sub_8391` (tail), `sub_83DD` |
| Calls | `sub_B088` |
| Reads | `$4CA7`-`$4CB5` (screen); `$4EE7`-`$4EF5` (screen); `$5FA7`-`$5FB5` (system); `$5FE7`-`$5FF5` (system) |
| Writes | `$4CA7`-`$4CB5` (screen); `$4EE7`-`$4EF5` (screen); `$59AA`-`$59B5` (screen); `$59EA`-`$59F5` (screen) |

### `sub_8338` (`$8338`)

**sub_8338**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 205,277 t-states own (0.01 %) |
| Called from | `l_758A` |
| Calls | `sub_7C26`, `sub_8391`, `sub_8E4F`, `sub_9D78`, `sub_C177` |
| Reads | `$7B96` (`data_7B92`); `$82F5` (`data_82F2`); `$83DC` (`data_83DC`); `$8E5A` (`data_8E5A`); `$9ED8` (`data_9ED6`) |
| Writes | `$83DC` (`data_83DC`); `$8E5A` (`data_8E5A`) |

### `sub_8391` (`$8391`)

**sub_8391**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 9 calls, 2,865 t-states own (0.00 %) |
| Called from | `sub_8338` |
| Calls | `sub_80C1`, `sub_82FC` (tail) |
| Reads | `$62A7`-`$62A8` (system); `$62E7`-`$62E8` (system); `$82F5`-`$82FB` (`data_82F2`); `$845F`-`$8461` (`data_845F`) |
| Writes | `$845F`-`$8461` (`data_845F`) |

### `sub_83DD` (`$83DD`)

**sub_83DD**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,303 calls, 10,687,520 t-states own (0.53 %) |
| Called from | `l_758A` |
| Calls | `sub_82FC`, `sub_9362`, `sub_9B52`, `sub_9E37`, `sub_A5CA`, `sub_AC04` |
| Reads | `$82F5` (`data_82F2`); `$845F`-`$8477` (`data_845F`) |
| Writes | `$845F`-`$8461` (`data_845F`) |

### `sub_8478` (`$8478`)

**sub_8478**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 2,100 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$845F`-`$8475` (`data_845F`) |
| Writes | `$845F`-`$8476` (`data_845F`) |

### `sub_8485` (`$8485`)

**sub_8485**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 91,364 t-states own (0.00 %) |
| Called from | `l_758A` |
| Reads | `$82F2` (`data_82F2`) |

### `sub_8494` (`$8494`)

**sub_8494**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 9,116 t-states own (0.00 %) |
| Called from | `l_758A` |
| Calls | `sub_8478`, `sub_8524`, `sub_8DF5`, `sub_8E03`, `sub_8E11`, `sub_8E86`, `sub_902F`, `sub_910B`, `sub_91FA`, `sub_9487`, `sub_980F`, `sub_98AD`, `sub_9AFA`, `sub_9B07`, `sub_9C7D`, `sub_9E0A`, `sub_9F20`, `sub_A01C`, `sub_A23A`, `sub_A2D5`, `sub_A352`, `sub_A545`, `sub_A645`, `l_AB97` (tail), `sub_AF2B`, `sub_B061`, `sub_B0F3` |
| Reads | `$8523` (`data_8523`); `$C8EE`-`$C909` (`data_C7F4`) |
| Writes | `$768D` (`data_768C`); `$925A` (`data_925A`); `$9445` (`data_9437`); `$AC78`-`$AC7C` (`data_AC78`); `$AE1B`-`$AE21` (`sub_ADE1`) |

### `sub_8524` (`$8524`)

**sub_8524**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 40 calls, 2,680 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$8532`-`$8549` (`data_852E`); `$856A`-`$8571` (`data_852E`); `$C7F4`-`$C7F5` (`data_C7F4`) |

### `sub_8DF5` (`$8DF5`)

**sub_8DF5**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 253,135 t-states own (0.01 %) |
| Called from | `l_6DA1`, `l_6FAB`, `sub_8494` |
| Reads | `$6100`-`$63BE` (system) |
| Writes | `$6100`-`$63BF` (system) |

### `sub_8E03` (`$8E03`)

**sub_8E03**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 251,698 t-states own (0.01 %) |
| Called from | `l_6DA1`, `l_6FAB`, `sub_8494` |
| Reads | `$5B00`-`$5DBE` (system) |
| Writes | `$5B00`-`$5DBF` (system) |

### `sub_8E11` (`$8E11`)

**sub_8E11**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 287,046 t-states own (0.01 %) |
| Called from | `l_6DA1`, `l_6FAB`, `sub_8494` |
| Reads | `$5800`-`$5AFF` (screen) |
| Writes | `$5E00`-`$60FF` (system) |

### `l_8E1D` (`$8E1D`)

**l_8E1D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 79 calls, 11,850 t-states own (0.00 %) |
| Called from | `sub_8E4F` (tail), `sub_8E5B` (tail) |
| Calls | `sub_8E37` |
| Writes | `$ADEF`-`$ADF0` (`sub_ADE1`) |

### `sub_8E37` (`$8E37`)

**sub_8E37**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 237 calls, 45,522 t-states own (0.00 %) |
| Called from | `l_8E1D` |
| Calls | `sub_AE26` |

### `sub_8E4F` (`$8E4F`)

**sub_8E4F**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 44 calls, 1,760 t-states own (0.00 %) |
| Called from | `sub_7690`, `sub_8338`, `sub_9CE3` |
| Calls | `l_8E1D` (tail) |
| Reads | `$8E5A` (`data_8E5A`) |

### `sub_8E5B` (`$8E5B`)

**sub_8E5B**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 35 calls, 1,400 t-states own (0.00 %) |
| Called from | `sub_7690`, `sub_9CE3` |
| Calls | `l_8E1D` (tail) |
| Reads | `$8E66` (`data_8E66`) |

### `sub_8E67` (`$8E67`)

**sub_8E67**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 35 calls, 2,555 t-states own (0.00 %) |
| Called from | `sub_7690`, `sub_9CE3` |
| Calls | `sub_AE26` (tail) |
| Reads | `$8E7A` (`data_8E7A`) |
| Writes | `$ADEF`-`$ADF0` (`sub_ADE1`) |

### `sub_8E7B` (`$8E7B`)

**sub_8E7B**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 160 t-states own (0.00 %) |
| Called from | `sub_7690` (tail) |
| Calls | `l_B0C6` (tail) |
| Reads | `$8523` (`data_8523`) |

### `sub_8E86` (`$8E86`)

**sub_8E86**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 164,001 t-states own (0.01 %) |
| Called from | `sub_8494` |
| Calls | `sub_8EAD` |
| Reads | `$6100`-`$63BF` (system); `$8EF4`-`$8F4F` (`data_8EF4`) |
| Writes | `$8EF6`-`$8F51` (`data_8EF4`); `$8F89`-`$91B0` (`data_8F89`, `sub_8F95`, `sub_9010`, `data_9019` and 11 more); `$9930`-`$99F5` (`data_9930`, `sub_9936`, `sub_9942`, `data_99F2`); `$9B4B`-`$9C70` (`data_9B4B`, `sub_9B52`, `sub_9B6B`, `sub_9B82` and 4 more); `$9DC1` (`data_9DC1`); `$9F6E` (`data_9F6D`); 3 more ranges |

### `sub_8EAD` (`$8EAD`)

**sub_8EAD**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 36 calls, 15,068 t-states own (0.00 %) |
| Called from | `sub_8E86` |
| Reads | `$8EF6`-`$8F05` (`data_8EF4`) |
| Writes | `$61C1`-`$61C9` (system); `$6200`-`$620A` (system); `$6264`-`$6266` (system); `$62D4` (system); `$8EF6`-`$8F03` (`data_8EF4`); `$8F89`-`$8F8D` (`data_8F89`); 2 more ranges |

### `sub_8F54` (`$8F54`)

**sub_8F54**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 1,351,814 t-states own (0.07 %) |
| Called from | `l_758A` |
| Calls | `sub_AD36`, `sub_AE26` |
| Reads | `$8F89`-`$8F94` (`data_8F89`) |
| Writes | `$8F94` (`data_8F89`); `$ADEF`-`$ADF0` (`sub_ADE1`) |

### `sub_8F95` (`$8F95`)

**sub_8F95**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 990,552 t-states own (0.05 %) |
| Called from | `l_758A` |
| Calls | `sub_8097`, `sub_9010`, `sub_9071`, `sub_AD36`, `sub_AE5D` |
| Reads | `$62D4` (system); `$9019`-`$9025` (`data_9019`) |
| Writes | `$9024` (`data_9019`); `$ADEF`-`$ADF0` (`sub_ADE1`) |

### `sub_9010` (`$9010`)

**sub_9010**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 500 calls, 24,500 t-states own (0.00 %) |
| Called from | `sub_8F95` |
| Reads | `$901A`-`$9021` (`data_9019`) |

### `sub_902F` (`$902F`)

**sub_902F**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,104 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$9022`-`$902C` (`data_9019`) |
| Writes | `$9022`-`$902D` (`data_9019`) |

### `sub_903D` (`$903D`)

**sub_903D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 6,818 calls, 2,227,684 t-states own (0.11 %) |
| Called from | `sub_9071`, `sub_90A2`, `sub_90EA` |
| Calls | `sub_B088` |
| Reads | `$4BC0`-`$4BD4` (screen); `$4CC0`-`$4CD4` (screen); `$5FBF`-`$5FD4` (system) |
| Writes | `$4BC0`-`$4BD4` (screen); `$4CC0`-`$4CD4` (screen); `$59C3`-`$59D2` (screen) |

### `sub_9071` (`$9071`)

**sub_9071**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 62 calls, 47,664 t-states own (0.00 %) |
| Called from | `sub_8F95` |
| Calls | `sub_7C26`, `sub_903D`, `sub_C148` (tail) |
| Reads | `$90CB`-`$90D3` (`data_90CB`) |
| Writes | `$90CB`-`$90D3` (`data_90CB`) |

### `sub_90A2` (`$90A2`)

**sub_90A2**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 6,523 calls, 5,052,208 t-states own (0.25 %) |
| Called from | `l_758A` |
| Calls | `sub_903D` |
| Reads | `$90CB`-`$90E9` (`data_90CB`) |
| Writes | `$90CB`-`$90D1` (`data_90CB`) |

### `sub_90EA` (`$90EA`)

**sub_90EA**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,365,170 t-states own (0.12 %) |
| Called from | `l_758A` |
| Calls | `sub_903D`, `sub_9BD6`, `sub_9CAF` (tail) |
| Reads | `$90CB`-`$90E9` (`data_90CB`) |
| Writes | `$90CD`-`$90D3` (`data_90CB`) |

### `sub_910B` (`$910B`)

**sub_910B**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 2,604 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$90CB`-`$90E7` (`data_90CB`) |
| Writes | `$90CB`-`$90E8` (`data_90CB`) |

### `sub_9118` (`$9118`)

**sub_9118**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,992,725 t-states own (0.15 %) |
| Called from | `l_758A` |
| Calls | `sub_8097` |
| Reads | `$768C` (`data_768C`); `$9135`-`$9141` (`data_9135`) |
| Writes | `$5900`-`$590A` (screen); `$5964`-`$5966` (screen) |

### `sub_9152` (`$9152`)

**sub_9152**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 309,700 t-states own (0.02 %) |
| Called from | `l_758A` |
| Reads | `$91AF`-`$91B0` (`data_91AF`) |
| Writes | `$91AF` (`data_91AF`); `$ADEF`-`$ADF0` (`sub_ADE1`) |

### `sub_91CF` (`$91CF`)

**sub_91CF**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_91FA` (`$91FA`)

**sub_91FA**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 2,616 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$91B0`-`$91CC` (`data_91AF`) |
| Writes | `$91B0`-`$91CD` (`data_91AF`) |

### `sub_9208` (`$9208`)

**sub_9208**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 200,890 t-states own (0.01 %) |
| Called from | `l_758A` |
| Calls | `sub_9D78` |
| Reads | `$82F5` (`data_82F2`); `$83DC` (`data_83DC`); `$8E66` (`data_8E66`) |

### `l_9237` (`$9237`)

**l_9237**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_925F` (`$925F`)

**sub_925F**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 9,780 calls, 273,840 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$925A` (`data_925A`) |

### `l_9291` (`$9291`)

**l_9291**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_92FB` (`$92FB`)

**sub_92FB**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 52,160 calls, 54,140,681 t-states own (2.69 %) |
| Called from | `sub_9E85` |
| Calls | `sub_B088` |
| Reads | `$4004`-`$4005` (screen); `$4104`-`$4105` (screen); `$4204`-`$4205` (screen); `$4304`-`$4305` (screen); `$4404`-`$4405` (screen); `$4504`-`$4505` (screen); 4 more ranges |
| Writes | `$4004`-`$4005` (screen); `$4104`-`$4105` (screen); `$4204`-`$4205` (screen); `$4304`-`$4305` (screen); `$4404`-`$4405` (screen); `$4504`-`$4505` (screen); 4 more ranges |

### `sub_9362` (`$9362`)

**sub_9362**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 424 calls, 52,622 t-states own (0.00 %) |
| Called from | `sub_83DD` |
| Calls | `sub_80C1` |
| Reads | `$62A8`-`$62B5` (system); `$62E8`-`$62F5` (system) |

### `sub_9382` (`$9382`)

**sub_9382**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_93A2` (`$93A2`)

**sub_93A2**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_93C2` (`$93C2`)

**sub_93C2**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_93E2` (`$93E2`)

**l_93E2**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9487` (`$9487`)

**sub_9487**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 36 calls, 24,452 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$94C6`-`$94F8` (`data_94C6`) |
| Writes | `$9437`-`$9444` (`data_9437`) |

### `sub_94F9` (`$94F9`)

**sub_94F9**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9548` (`$9548`)

**sub_9548**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_955D` (`$955D`)

**sub_955D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 21,630,100 t-states own (1.08 %) |
| Called from | `l_758A` |
| Reads | `$95B6`-`$980E` (`data_95B6`) |

### `sub_980F` (`$980F`)

**sub_980F**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 50,496 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$95B6`-`$980C` (`data_95B6`) |
| Writes | `$95B6`-`$980D` (`data_95B6`) |

### `sub_981D` (`$981D`)

**sub_981D**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9835` (`$9835`)

**sub_9835**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 4,550,960 t-states own (0.23 %) |
| Called from | `l_758A` |
| Reads | `$9870`-`$98AC` (`data_9865`) |

### `sub_98AD` (`$98AD`)

**sub_98AD**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 5,124 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$9870`-`$98AA` (`data_9865`) |
| Writes | `$9870`-`$98AB` (`data_9865`) |

### `sub_98BA` (`$98BA`)

**sub_98BA**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 155,988 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$7B94` (`data_7B92`); `$9930`-`$9935` (`data_9930`) |
| Writes | `$9935` (`data_9930`) |

### `sub_9936` (`$9936`)

**sub_9936**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9942` (`$9942`)

**sub_9942**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 257,540 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$99F2`-`$99F6` (`data_99F2`) |

### `sub_99F8` (`$99F8`)

**sub_99F8**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9A19` (`$9A19`)

**sub_9A19**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 118,787 t-states own (0.01 %) |
| Called from | `l_758A` |
| Ports in | `$EFFE` |

### `sub_9A23` (`$9A23`)

**sub_9A23**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 32,600 t-states own (0.00 %) |
| Called from | `l_758A` |
| Calls | `l_9A26` |

### `l_9A26` (`$9A26`)

**l_9A26**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 9,004,120 t-states own (0.45 %) |
| Called from | `sub_9A23` |
| Reads | `$9A99`-`$9AF9` (`data_9A99`) |

### `l_9A7F` (`$9A7F`)

**l_9A7F**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9AFA` (`$9AFA`)

**sub_9AFA**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 8,148 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$9A99`-`$9AF7` (`data_9A99`) |
| Writes | `$9A99`-`$9AF8` (`data_9A99`) |

### `sub_9B07` (`$9B07`)

**sub_9B07**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 200 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$9B4B` (`data_9B4B`) |

### `sub_9B52` (`$9B52`)

**sub_9B52**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,303 calls, 29,541,036 t-states own (1.47 %) |
| Called from | `sub_83DD` |
| Reads | `$9A99`-`$9AF9` (`data_9A99`) |

### `sub_9B6B` (`$9B6B`)

**sub_9B6B**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9B82` (`$9B82`)

**sub_9B82**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9BB4` (`$9BB4`)

**sub_9BB4**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 5,907,120 t-states own (0.29 %) |
| Called from | `l_758A` |
| Reads | `$9A99`-`$9AF9` (`data_9A99`) |

### `sub_9BD6` (`$9BD6`)

**sub_9BD6**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 1,719 calls, 174,849 t-states own (0.01 %) |
| Called from | `sub_90EA` |
| Reads | `$82F5`-`$82FB` (`data_82F2`) |

### `sub_9C15` (`$9C15`)

**sub_9C15**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 244,500 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$9C70` (`data_9C25`) |

### `sub_9C7D` (`$9C7D`)

**sub_9C7D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,104 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$9C70`-`$9C7A` (`data_9C25`) |
| Writes | `$9C70`-`$9C7B` (`data_9C25`) |

### `sub_9C8B` (`$9C8B`)

**sub_9C8B**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 117,360 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$9C70` (`data_9C25`) |

### `l_9CAA` (`$9CAA`)

**l_9CAA**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9CAF` (`$9CAF`)

**sub_9CAF**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 59 calls, 8,894 t-states own (0.00 %) |
| Called from | `sub_90EA` (tail) |
| Calls | `sub_8224` |
| Reads | `$768D` (`data_768C`); `$82F5`-`$82F6` (`data_82F2`); `$9CE2` (`data_9CE2`) |
| Writes | `$768D` (`data_768C`); `$82F7` (`data_82F2`); `$83DC` (`data_83DC`); `$9CE2` (`data_9CE2`); `$AC7B`-`$AC7C` (`data_AC78`) |

### `sub_9CE3` (`$9CE3`)

**sub_9CE3**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,263 calls, 288,695 t-states own (0.01 %) |
| Called from | `l_758A` |
| Calls | `sub_7BAA`, `sub_814E`, `sub_8224` (tail), `sub_8E4F`, `sub_8E5B`, `sub_8E67`, `l_A02A` (tail) |
| Reads | `$7BDA` (`data_7BDA`); `$82F3`-`$82F6` (`data_82F2`); `$8E7A` (`data_8E7A`); `$9CE2` (`data_9CE2`); `$9D4B`-`$9D77` (`data_9D47`) |
| Writes | `$82FA` (`data_82F2`); `$8E5A`-`$8E66` (`data_8E5A`, `sub_8E5B`, `data_8E66`); `$8E7A` (`data_8E7A`); `$9CE2` (`data_9CE2`) |

### `sub_9D78` (`$9D78`)

**sub_9D78**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 13,046 calls, 444,276 t-states own (0.02 %) |
| Called from | `sub_81A4`, `sub_8338`, `sub_9208`, `sub_A553` |
| Reads | `$9CE2` (`data_9CE2`) |

### `sub_9D7F` (`$9D7F`)

**sub_9D7F**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 117,360 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$9DC1` (`data_9DC1`) |

### `l_9DA8` (`$9DA8`)

**l_9DA8**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9DD6` (`$9DD6`)

**sub_9DD6**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,464,560 t-states own (0.12 %) |
| Called from | `l_758A` |
| Reads | `$9E18`-`$9E36` (`data_9E18`) |

### `sub_9E0A` (`$9E0A`)

**sub_9E0A**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 2,616 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$9E18`-`$9E34` (`data_9E18`) |
| Writes | `$9E18`-`$9E35` (`data_9E18`) |

### `sub_9E37` (`$9E37`)

**sub_9E37**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,303 calls, 11,672,948 t-states own (0.58 %) |
| Called from | `sub_83DD` |
| Reads | `$9E18`-`$9E36` (`data_9E18`) |

### `sub_9E4F` (`$9E4F`)

**sub_9E4F**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9E64` (`$9E64`)

**sub_9E64**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,334,160 t-states own (0.12 %) |
| Called from | `l_758A` |
| Reads | `$9E18`-`$9E36` (`data_9E18`) |

### `sub_9E85` (`$9E85`)

**sub_9E85**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 1,747,360 t-states own (0.09 %) |
| Called from | `l_758A` |
| Calls | `sub_92FB` |
| Reads | `$9E98` (`data_9E98`) |

### `sub_9E99` (`$9E99`)

**sub_9E99**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 792,132 t-states own (0.04 %) |
| Called from | `l_758A` |
| Calls | `sub_795C` |
| Reads | `$9EAE` (`data_9EAE`) |

### `sub_9EAF` (`$9EAF`)

**sub_9EAF**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9EC1` (`$9EC1`)

**sub_9EC1**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 114,100 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$9ED6`-`$9ED7` (`data_9ED6`) |

### `sub_9ED9` (`$9ED9`)

**sub_9ED9**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9EEE` (`$9EEE`)

**sub_9EEE**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 1,004,080 t-states own (0.05 %) |
| Called from | `l_758A` |
| Reads | `$9F13`-`$9F1F` (`data_9F13`) |

### `sub_9F20` (`$9F20`)

**sub_9F20**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,092 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$9F13`-`$9F1D` (`data_9F13`) |
| Writes | `$9F13`-`$9F1E` (`data_9F13`) |

### `sub_9F2D` (`$9F2D`)

**sub_9F2D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 156,290 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$7B94` (`data_7B92`); `$9F6D`-`$9F6F` (`data_9F6D`) |
| Writes | `$9F6D` (`data_9F6D`) |

### `sub_9F71` (`$9F71`)

**sub_9F71**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9FA3` (`$9FA3`)

**sub_9FA3**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_9FBD` (`$9FBD`)

**sub_9FBD**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,412,400 t-states own (0.12 %) |
| Called from | `l_758A` |
| Reads | `$A00C`-`$A01B` (`data_A001`) |

### `sub_A01C` (`$A01C`)

**sub_A01C**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,356 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$A00C`-`$A019` (`data_A001`) |
| Writes | `$A00C`-`$A01A` (`data_A001`) |

### `l_A02A` (`$A02A`)

**l_A02A**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3 calls, 87,900 t-states own (0.00 %) |
| Called from | `sub_9CE3` (tail) |
| Calls | `l_6D60` (tail), `sub_7D17`, `sub_A073`, `sub_ACD1`, `sub_AD18`, `sub_AF2B`, `sub_B0B7` |

### `sub_A073` (`$A073`)

**sub_A073**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3 calls, 72 t-states own (0.00 %) |
| Called from | `l_A02A` |
| Calls | `l_A07A` |

### `l_A07A` (`$A07A`)

**l_A07A**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 153 calls, 12,623 t-states own (0.00 %) |
| Called from | `sub_A073`, `l_A14C` (tail) |
| Calls | `l_A08B` |
| Reads | `$71F1`-`$7511` (`data_718D`) |

### `l_A08B` (`$A08B`)

**l_A08B**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 450 calls, 17,994 t-states own (0.00 %) |
| Called from | `l_A07A`, `l_A145` (tail) |
| Calls | `l_A145` (tail), `l_A14C` (tail) |
| Reads | `$71FB`-`$750D` (`data_718D`); `$AD8A`-`$AD8C` (`data_AD82`) |

### `l_A145` (`$A145`)

**l_A145**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 300 calls, 9,000 t-states own (0.00 %) |
| Called from | `l_A08B` (tail) |
| Calls | `l_A08B` (tail) |

### `l_A14C` (`$A14C`)

**l_A14C**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 150 calls, 7,350 t-states own (0.00 %) |
| Called from | `l_A08B` (tail) |
| Calls | `l_A07A` (tail) |

### `sub_A23A` (`$A23A`)

**sub_A23A**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,264 calls, 182,784 t-states own (0.01 %) |
| Called from | `sub_8494`, `sub_A26B` (tail) |
| Reads | `$A266`-`$A267` (`data_A266`) |
| Writes | `$A26A` (`data_A266`) |

### `sub_A26B` (`$A26B`)

**sub_A26B**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 88,020 t-states own (0.00 %) |
| Called from | `l_758A` |
| Calls | `sub_A23A` (tail) |
| Reads | `$A26A` (`data_A266`) |

### `sub_A2D5` (`$A2D5`)

**sub_A2D5**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 48,864 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Calls | `sub_8097`, `sub_AD36`, `sub_AE26` |
| Reads | `$5E02`-`$6075` (system); `$6089`-`$60BE` (system) |
| Writes | `$ADEF`-`$ADF0` (`sub_ADE1`) |

### `sub_A30B` (`$A30B`)

**sub_A30B**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 117,360 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$A333` (`data_A333`) |

### `sub_A352` (`$A352`)

**sub_A352**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 1,104 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$A333`-`$A33D` (`data_A333`) |
| Writes | `$A333`-`$A33E` (`data_A333`) |

### `sub_A360` (`$A360`)

**sub_A360**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 78,240 t-states own (0.00 %) |
| Called from | `l_758A` |
| Calls | `l_A367` |

### `l_A367` (`$A367`)

**l_A367**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 22,820 calls, 1,473,520 t-states own (0.07 %) |
| Called from | `sub_A360`, `l_A3F9` (tail) |
| Calls | `l_A3F9` (tail) |
| Reads | `$A508`-`$A544` (`data_A406`) |

### `l_A3F9` (`$A3F9`)

**l_A3F9**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 19,560 calls, 1,290,960 t-states own (0.06 %) |
| Called from | `l_A367` (tail) |
| Calls | `l_A367` (tail) |

### `sub_A545` (`$A545`)

**sub_A545**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 5,136 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$A508`-`$A542` (`data_A406`) |
| Writes | `$A508`-`$A543` (`data_A406`) |

### `sub_A553` (`$A553`)

**sub_A553**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 107,640 t-states own (0.01 %) |
| Called from | `l_758A` |
| Calls | `sub_9D78` |
| Reads | `$A676` (`data_A676`) |

### `sub_A5CA` (`$A5CA`)

**sub_A5CA**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,303 calls, 14,607,488 t-states own (0.73 %) |
| Called from | `sub_83DD` |
| Reads | `$A508`-`$A544` (`data_A406`) |

### `sub_A5F4` (`$A5F4`)

**sub_A5F4**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 2,920,960 t-states own (0.15 %) |
| Called from | `l_758A` |
| Reads | `$A508`-`$A544` (`data_A406`) |

### `sub_A62D` (`$A62D`)

**sub_A62D**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_A645` (`$A645`)

**sub_A645**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 20,436 t-states own (0.00 %) |
| Called from | `sub_8494` |
| Reads | `$8523` (`data_8523`); `$A677`-`$A7D5` (`data_A676`) |
| Writes | `$A676` (`data_A676`) |

### `sub_A7D6` (`$A7D6`)

**sub_A7D6**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 117,360 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$A814` (`data_A814`) |

### `sub_A817` (`$A817`)

**sub_A817**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 127,140 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$AAEF`-`$AAF0` (`data_A960`) |

### `l_A8A5` (`$A8A5`)

**l_A8A5**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_A8DB` (`$A8DB`)

**sub_A8DB**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_AB97` (`$AB97`)

**l_AB97**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 156 t-states own (0.00 %) |
| Called from | `sub_8494` (tail) |
| Reads | `$ABCC`-`$ABCD` (`data_ABCC`) |

### `sub_ABCF` (`$ABCF`)

**sub_ABCF**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 127,140 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$ABCC`-`$ABCD` (`data_ABCC`) |

### `sub_AC04` (`$AC04`)

**sub_AC04**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 16,303 calls, 635,817 t-states own (0.03 %) |
| Called from | `sub_83DD` |
| Reads | `$ABCC`-`$ABCD` (`data_ABCC`) |

### `sub_AC59` (`$AC59`)

**sub_AC59**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 254,280 t-states own (0.01 %) |
| Called from | `l_758A` |
| Reads | `$AC78`-`$AC7C` (`data_AC78`) |

### `sub_AC7D` (`$AC7D`)

**sub_AC7D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 91,280 t-states own (0.00 %) |
| Called from | `l_758A` |
| Reads | `$AC78` (`data_AC78`) |

### `sub_ACD1` (`$ACD1`)

**sub_ACD1**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 22,019 calls, 40,177,227 t-states own (2.00 %) |
| Called from | `l_6DA1`, `l_6FAB`, `l_A02A` |
| Reads | `$ACF0`-`$AD17` (`data_ACEF`) |
| Ports in | `$7FFE`, `$BFFE`, `$DFFE`, `$EFFE`, `$F7FE`, `$FBFE`, `$FDFE`, `$FEFE` |

### `sub_AD18` (`$AD18`)

**sub_AD18**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 18 calls, 55,733,542 t-states own (2.77 %) |
| Called from | `l_6FAB`, `l_A02A` |
| Ports in | `$00FE` |

### `sub_AD21` (`$AD21`)

**sub_AD21**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,260 calls, 142,709 t-states own (0.01 %) |
| Called from | `l_758A` |
| Ports in | `$F7FE` |

### `sub_AD36` (`$AD36`)

**sub_AD36**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 20,875 calls, 4,195,875 t-states own (0.21 %) |
| Called from | `sub_6EA9`, `sub_8F54`, `sub_8F95`, `sub_A2D5` |
| Reads | `$AD51`-`$AD52` (`data_AD51`) |
| Writes | `$AD51`-`$AD52` (`data_AD51`) |

### `sub_AD53` (`$AD53`)

**sub_AD53**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_ADE1` (`$ADE1`)

**sub_ADE1**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4,053 calls, 2,598,177 t-states own (0.13 %) |
| Called from | `l_6FAB`, `sub_AF2B` |
| Reads | `$D8E0`-`$D8E7` (`data_C7F4`); `$D950`-`$DAB7` (`data_C7F4`); `$DB38`-`$DB5F` (`data_C7F4`); `$DBE8`-`$DE57` (`data_C7F4`); `$DE68`-`$DE77` (`data_C7F4`); `$DED8`-`$E10F` (`data_C7F4`); 2 more ranges |
| Writes | `$4003`-`$5DFF` (screen); `$6103`-`$63FF` (system) |

### `sub_AE26` (`$AE26`)

**sub_AE26**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 13,392 calls, 7,710,927 t-states own (0.38 %) |
| Called from | `sub_8E37`, `sub_8E67` (tail), `sub_8F54`, `sub_A2D5`, `sub_B0E0` |
| Reads | `$ADEF`-`$ADF0` (`sub_ADE1`); `$D960`-`$D9AF` (`data_C7F4`); `$DB60`-`$DB8F` (`data_C7F4`); `$E858`-`$E85F` (`data_C7F4`) |
| Writes | `$4002`-`$5A33` (screen); `$5AE1`-`$5AFE` (screen) |

### `sub_AE5D` (`$AE5D`)

**sub_AE5D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,000 calls, 1,267,913 t-states own (0.06 %) |
| Called from | `sub_8F95` |
| Reads | `$48D4`-`$48D5` (screen); `$49D4`-`$49D5` (screen); `$4AD4`-`$4AD5` (screen); `$4BD4`-`$4BD5` (screen); `$4CD4`-`$4CD5` (screen); `$4DD4`-`$4DD5` (screen); 4 more ranges |
| Writes | `$48D4`-`$48D5` (screen); `$49D4`-`$49D5` (screen); `$4AD4`-`$4AD5` (screen); `$4BD4`-`$4BD5` (screen); `$4CD4`-`$4CD5` (screen); `$4DD4`-`$4DD5` (screen); 3 more ranges |

### `l_AE95` (`$AE95`)

**l_AE95**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_AEE4` (`$AEE4`)

**l_AEE4**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_AF2B` (`$AF2B`)

**sub_AF2B**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 134 calls, 634,077 t-states own (0.03 %) |
| Called from | `l_6DA1`, `l_6FAB`, `sub_7690`, `sub_8494`, `l_A02A` |
| Calls | `sub_ADE1` |
| Reads | `$6E17`-`$6EA8` (`data_6E16`); `$705B`-`$7144` (`data_7046`); `$76A2`-`$76D9` (`data_76A2`); `$85E0`-`$87D4` (`data_852E`); `$8A07`-`$8A6C` (`data_852E`); `$A057`-`$A072` (`data_A057`); 1 more ranges |
| Writes | `$ADEF`-`$ADF0` (`sub_ADE1`); `$AE1B`-`$AE21` (`sub_ADE1`) |

### `sub_B04B` (`$B04B`)

**sub_B04B**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 2,567,516 t-states own (0.13 %) |
| Called from | `l_6DA1`, `l_6FAB`, `l_758A` |
| Reads | `$4002`-`$5AFF` (screen) |
| Writes | `$4001`-`$5AFF` (screen) |

### `sub_B04D` (`$B04D`)

**sub_B04D**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_B061` (`$B061`)

**sub_B061**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 733,843 t-states own (0.04 %) |
| Called from | `sub_8494` |
| Calls | `sub_B099` |
| Reads | `$4000`-`$50BE` (screen); `$5100`-`$51BE` (screen); `$5200`-`$52BE` (screen); `$5300`-`$53BE` (screen); `$5400`-`$54BE` (screen); `$5500`-`$55BE` (screen); 3 more ranges |
| Writes | `$4000`-`$50BF` (screen); `$5100`-`$51BF` (screen); `$5200`-`$52BF` (screen); `$5300`-`$53BF` (screen); `$5400`-`$54BF` (screen); `$5500`-`$55BF` (screen); 3 more ranges |

### `sub_B088` (`$B088`)

**sub_B088**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 185,192 calls, 17,171,519 t-states own (0.85 %) |
| Called from | `l_776C`, `l_79C2`, `sub_82FC`, `sub_903D`, `sub_92FB` |
| Reads | `$6500`-`$65A8` (system); `$6600`-`$66A8` (system) |

### `sub_B099` (`$B099`)

**sub_B099**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,240 calls, 68,552 t-states own (0.00 %) |
| Called from | `sub_7BEF`, `sub_B061` |

### `sub_B0B7` (`$B0B7`)

**sub_B0B7**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 3,272 calls, 50,184,765 t-states own (2.50 %) |
| Called from | `l_6FAB`, `l_758A`, `l_A02A` |
| Reads | `$4000`-`$FFFF` (`l_6D60`, `l_6DA1`, `data_6E16`, `sub_6EA9` and 344 more) |
| Writes | `$4000`-`$FFFF` (`l_6D60`, `l_6DA1`, `data_6E16`, `sub_6EA9` and 344 more) |

### `l_B0C6` (`$B0C6`)

**l_B0C6**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 4 calls, 600 t-states own (0.00 %) |
| Called from | `sub_8E7B` (tail) |
| Calls | `sub_B0E0` |
| Writes | `$ADEF`-`$ADF0` (`sub_ADE1`) |

### `sub_B0E0` (`$B0E0`)

**sub_B0E0**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 12 calls, 1,080 t-states own (0.00 %) |
| Called from | `l_B0C6` |
| Calls | `sub_AE26` |

### `sub_B0F3` (`$B0F3`)

**sub_B0F3**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 400,176 t-states own (0.02 %) |
| Called from | `l_6DA1`, `l_6FAB`, `sub_8494` |
| Reads | `$B181`-`$B6CF` (`data_B101`) |
| Writes | `$B181`-`$B6D0` (`data_B101`) |

### `sub_B6D1` (`$B6D1`)

**sub_B6D1**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 7 calls, 462 t-states own (0.00 %) |
| Called from | `sub_B6EC` |
| Reads | `$B6E0` (`data_B6DF`) |
| Writes | `$BE85` (`data_BA01`); `$BED5` (`data_BA01`); `$BF25` (`data_BA01`) |

### `sub_B6EC` (`$B6EC`)

**sub_B6EC**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 7 calls, 2,142 t-states own (0.00 %) |
| Called from | `l_6DA1` |
| Calls | `sub_B6D1`, `sub_B730`, `sub_B753` |
| Writes | `$B6E4`-`$B6EB` (`data_B6DF`); `$BE7F` (`data_BA01`); `$BECF` (`data_BA01`); `$BF1F` (`data_BA01`) |

### `sub_B730` (`$B730`)

**sub_B730**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 21 calls, 4,158 t-states own (0.00 %) |
| Called from | `sub_B6EC` |
| Reads | `$B6E0` (`data_B6DF`) |
| Writes | `$BE7D`-`$BE8A` (`data_BA01`); `$BECD`-`$BEDA` (`data_BA01`); `$BF1D`-`$BF2A` (`data_BA01`) |

### `sub_B753` (`$B753`)

**sub_B753**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 14 calls, 3,066 t-states own (0.00 %) |
| Called from | `l_6FAB`, `l_758A`, `sub_B6EC` |
| Calls | `sub_BF6D` |
| Writes | `$B6E5` (`data_B6DF`) |

### `sub_B767` (`$B767`)

**sub_B767**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_B79E` (`$B79E`)

**l_B79E**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_B79F` (`$B79F`)

**sub_B79F**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_B88F` (`$B88F`)

**sub_B88F**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_B944` (`$B944`)

**l_B944**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_B9A6` (`$B9A6`)

**l_B9A6**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_B9B6` (`$B9B6`)

**l_B9B6**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_B9D8` (`$B9D8`)

**l_B9D8**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_B9F7` (`$B9F7`)

**l_B9F7**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_BF6D` (`$BF6D`)

**sub_BF6D**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 27,713 calls, 3,270,134 t-states own (0.16 %) |
| Called from | `sub_B753`, `sub_BF7E` (tail), `l_C097` (tail), `l_C0B1` (tail) |
| Ports out | `$BFFD`, `$FFFD` |

### `sub_BF7E` (`$BF7E`)

**sub_BF7E**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 9,783 calls, 21,301,881 t-states own (1.06 %) |
| Called from | `l_758A` |
| Calls | `sub_BF6D` (tail), `sub_BFBF` |
| Reads | `$C5E7`-`$C6DB` (`data_C218`) |
| Writes | `$C5E7`-`$C5EA` (`data_C218`) |

### `sub_BFBF` (`$BFBF`)

**sub_BFBF**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,760 calls, 218,347 t-states own (0.01 %) |
| Called from | `sub_BF7E` |
| Calls | `sub_BFE1`, `l_C05A` (tail) |
| Reads | `$C64E`-`$C653` (`data_C218`); `$C6DE`-`$C6E1` (`data_C218`) |
| Writes | `$C64E`-`$C651` (`data_C218`); `$C6DE`-`$C6E1` (`data_C218`) |

### `sub_BFE1` (`$BFE1`)

**sub_BFE1**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 1,458 calls, 649,203 t-states own (0.03 %) |
| Called from | `sub_BFBF` |
| Reads | `$C305`-`$C33D` (`data_C218`); `$C5A1`-`$C5B9` (`data_C218`); `$C64C`-`$C657` (`data_C218`); `$C6DC`-`$C6E7` (`data_C218`); `$C703`-`$C73C` (`data_C218`) |
| Writes | `$C5E8` (`data_C218`); `$C64B`-`$C657` (`data_C218`); `$C6DB`-`$C6E7` (`data_C218`) |

### `l_C015` (`$C015`)

**l_C015**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `l_C05A` (`$C05A`)

**l_C05A**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 2,697 calls, 426,126 t-states own (0.02 %) |
| Called from | `sub_BFBF` (tail) |
| Calls | `l_C097`, `l_C0B1` |
| Reads | `$C077`-`$C07A` (`data_C077`); `$C5EA` (`data_C218`); `$C64F`-`$C655` (`data_C218`); `$C6DF`-`$C6E5` (`data_C218`) |
| Writes | `$C5EA` (`data_C218`) |

### `l_C097` (`$C097`)

**l_C097**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 327,180 t-states own (0.02 %) |
| Called from | `l_C05A` |
| Calls | `sub_BF6D` (tail) |
| Reads | `$C5E7`-`$C5E9` (`data_C218`); `$C656` (`data_C218`); `$C6E6` (`data_C218`) |
| Writes | `$C5E9` (`data_C218`) |

### `l_C0B1` (`$C0B1`)

**l_C0B1**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | run into, not called, 4,662 t-states own (0.00 %) |
| Called from | `l_C05A` |
| Calls | `sub_BF6D` (tail) |
| Reads | `$C5E7`-`$C5E9` (`data_C218`); `$C6E6` (`data_C218`) |
| Writes | `$C5E9` (`data_C218`) |

### `l_C0CC` (`$C0CC`)

**l_C0CC**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_C0E7` (`$C0E7`)

**sub_C0E7**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_C0F4` (`$C0F4`)

**sub_C0F4**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_C101` (`$C101`)

**sub_C101**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_C12E` (`$C12E`)

**sub_C12E**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_C13B` (`$C13B`)

**sub_C13B**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_C148` (`$C148`)

**sub_C148**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 62 calls, 5,332 t-states own (0.00 %) |
| Called from | `sub_9071` (tail) |
| Calls | `sub_C1D3` |

### `sub_C155` (`$C155`)

**sub_C155**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_C162` (`$C162`)

**sub_C162**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_C177` (`$C177`)

**sub_C177**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 9 calls, 243 t-states own (0.00 %) |
| Called from | `sub_8338` |
| Calls | `sub_C1D3` (tail) |

### `sub_C1A9` (`$C1A9`)

**sub_C1A9**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_C1BE` (`$C1BE`)

**sub_C1BE**

| | |
| --- | --- |
| Runs | not reached in the recordings |

### `sub_C1D3` (`$C1D3`)

**sub_C1D3**

| | |
| --- | --- |
| Runs (c1's whole run (the load and 16 000 frames of seeded random play)) | 71 calls, 29,110 t-states own (0.00 %) |
| Called from | `sub_C148`, `sub_C177` (tail) |
| Writes | `$C64B`-`$C657` (`data_C218`); `$C6DB`-`$C6E7` (`data_C218`) |

### `l_C7F3` (`$C7F3`)

**l_C7F3**

| | |
| --- | --- |
| Runs | not reached in the recordings |
