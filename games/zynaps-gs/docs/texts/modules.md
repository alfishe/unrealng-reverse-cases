# modules

**What it is.** The titles and the 31 sample names of the 13 Protracker modules on the disk (levels 1-12 and the
title, module 13). Trackers kept credits, greetings and notes in these fields; they are never shown by the game.

**The files.** `src/res/music/level01.mod` .. `level13.mod` (cut from the disk's module records,
[3](../03-build-and-load.md)): the title at offset 0 (20 bytes), each sample name at 20 + 30 n (22 bytes),
zero-padded, decoded as Latin-1. Only the names that are not empty are listed; the length is the sample's in bytes.
All are English; none needs a translation. Control characters are shown as `\xNN`.

## level01.mod (level 1): `from_wendetta_2175!`

| Sample | Name | Length |
| ---: | --- | ---: |
| 1 | `ripped_by_dangerous` | 7132 |
| 2 | `from` | 10234 |
| 3 | `###wendetta2175###` | 4026 |
| 4 | `by_wortex_design` | 1294 |
| 30 | `Noiseconverter of` | 0 |
| 31 | `Buggs/Defect used` | 0 |

## level02.mod (level 2): `zynaps2`

| Sample | Name | Length |
| ---: | --- | ---: |
| 1 | `softbass` | 4900 |
| 2 | `popsnare2` | 4000 |
| 3 | `bassdrum3` | 3400 |
| 4 | `hihat2` | 2000 |
| 5 | `analogstring` | 8800 |
| 6 | `bigbow` | 7800 |
| 7 | `digdug` | 3100 |

## level03.mod (level 3): no title

| Sample | Name | Length |
| ---: | --- | ---: |
| 30 | `Noiseconverter of` | 0 |
| 31 | `Buggs/Defect used` | 0 |

## level04.mod (level 4): `zynaps4`

| Sample | Name | Length |
| ---: | --- | ---: |
| 1 | `-- kbx128 / tesko! --` | 664 |
| 2 | `     october 1994` | 780 |
| 3 | `=====================` | 674 |
| 4 | `another tune for use` | 700 |
| 5 | ` with the excellent` | 2958 |
| 6 | `  " galaga deluxe "` | 5318 |
| 7 | `=====================` | 4348 |
| 8 | `uses channels 1 and 2` | 868 |
| 9 | `=====================` | 3860 |
| 10 | `a little bit depress-` | 1010 |
| 11 | `ing, don't you think?` | 1070 |
| 12 | `more positive tunes 4` | 0 |
| 13 | `gd on the way ......` | 0 |
| 14 | `=====================` | 0 |
| 15 | `  this uses ripped` | 0 |
| 16 | `samples.  all credit` | 0 |
| 17 | `  to the samplers,` | 0 |
| 18 | `  whoever you are.` | 0 |
| 19 | `=====================` | 0 |

## level05.mod (level 5): no title

| Sample | Name | Length |
| ---: | --- | ---: |
| 30 | `Noiseconverter of` | 0 |
| 31 | `Buggs/Defect used` | 0 |

## level06.mod (level 6): no title

| Sample | Name | Length |
| ---: | --- | ---: |
| 1 | `John Underwood` | 996 |

## level07.mod (level 7): no title

| Sample | Name | Length |
| ---: | --- | ---: |
| 30 | `Noiseconverter of` | 0 |
| 31 | `Buggs/Defect used` | 0 |

## level08.mod (level 8): `zynaps5`

| Sample | Name | Length |
| ---: | --- | ---: |
| 1 | `t3-snare` | 3080 |
| 2 | `slam bass d.` | 3422 |
| 3 | `hi-hat` | 724 |
| 4 | `smatter2` | 1854 |
| 7 | `t3-jazzband-` | 2972 |
| 9 | `ORCESTRA5` | 11630 |
| 11 | `t3-synthbass1` | 6326 |

## level09.mod (level 9): no title

| Sample | Name | Length |
| ---: | --- | ---: |
| 30 | `Noiseconverter of` | 0 |
| 31 | `Buggs/Defect used` | 0 |

## level10.mod (level 10): `zynaps6`

| Sample | Name | Length |
| ---: | --- | ---: |
| 1 | ` >>>nuke of lemon<<<` | 4334 |

## level11.mod (level 11): `zynaps3`

| Sample | Name | Length |
| ---: | --- | ---: |
| 1 | `MagFields` | 0 |
| 2 | `         by` | 3954 |
| 3 | `      dextrous` | 1088 |
| 5 | ` (c) dextrous 1990` | 0 |
| 6 | `if you rip and use it` | 2584 |
| 7 | `then don't be a lamer` | 2592 |
| 8 | `credit the author....` | 0 |
| 10 | `wanna contact me for` | 0 |
| 11 | `some music or to swap` | 0 |
| 12 | `some sample disks` | 0 |
| 14 | `1 myrtle grove` | 9138 |
| 15 | `auckley` | 10462 |
| 16 | `doncaster` | 0 |
| 17 | `south yorkshire` | 0 |
| 18 | `dn9 3hr` | 0 |
| 20 | `england 0302 770954` | 0 |
| 21 | `and ask for rich` | 0 |
| 22 | `also to swap techno` | 0 |
| 23 | `tapes etc.  but no` | 0 |
| 24 | `software trading...or` | 0 |
| 25 | `anything else illegal` | 0 |

## level12.mod (level 12): `zynaps1`

| Sample | Name | Length |
| ---: | --- | ---: |
| 1 | `music by pyratronik` | 3012 |
| 2 | `ST-08:xen-block` | 1290 |
| 3 | `ST-08:xen-bass` | 3230 |
| 4 | `ST-08:xen-ride2` | 6658 |
| 5 | `ST-08:xen-snaredrum` | 5242 |
| 6 | `ST-08:xen-block2` | 2242 |
| 7 | `ST-08:xen-granblast` | 4646 |
| 8 | `ST-08:xen-corda` | 5042 |
| 11 | `ST-09:beatbeep` | 1316 |

## level13.mod (the title module): no title

| Sample | Name | Length |
| ---: | --- | ---: |
| 30 | `Noiseconverter of` | 0 |
| 31 | `Buggs/Defect used` | 0 |
