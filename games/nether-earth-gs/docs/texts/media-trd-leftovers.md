# media-trd-leftovers

**What it is.** The readable words among the TRD's leftover bytes: buffer contents that TR-DOS wrote after the end of
some files, and a catalogue entry under the catalogue's end mark. No program reads them; they tell what was on the
author's disks before. The bytes are mostly binary, so they stay byte files
([`src/res/media/`](../../src/res/media/README.md)); this page is the readable copy of their text.

**The file.** The TRD `Nether Earth (1987)(...)[h 2002 Tron Z].trd`; ASCII names in TR-DOS catalogue entries
(8-character name, type letter) and in a BASIC command line. English / file names, no translation needed.

## In the tail of neart022 (sector 3, bytes 97-255): a catalogue of the author's work disk

```text
TS6.0    B
sts6.0   C
pc       B
bd       B
loader   S
neart000 C
128-48   S
nameload S
nameloa1 S
neart002 C
```

(the first entry's first letters are cut off by the tail's start, `TS6.0` may be `?TS6.0`; type `S` is not a
standard TR-DOS type letter; `neart002` is at track 21 sector 1 there, the same entry ends the tail of neart021)

## In the tail of "neart GS" (bytes 71-255): the BASIC command line at the time of the save

```text
eart GS" LINE 10
15616
```

(the end of, most likely, `SAVE "neart GS" LINE 10`, its first 3 bytes overwritten by the autostart mark; `15616`
is TR-DOS's entry `$3D00`, from a `RANDOMIZE USR 15616`)

## Catalogue entry 28 (under the end mark)

```text
?.EARTH  B   572 bytes, 171 sectors, track 121 sector 10
```

(its name's first byte is the `$00` that ends the catalogue; the sectors it names hold a whole copy of Neart481)
