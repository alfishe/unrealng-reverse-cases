# Zynaps 2 in 1: the texts of the boot

Every text a player meets from power-on to the start of the intro, in UTF-8, with where it comes from and the screen
it is on. All of it is English; no translation is needed. The disk holds no readme or info file: its two files are
`ZYNAPS.B` and `boot.B` (the TRD; the SCL holds only `ZYNAPS.B`).

Screens: [01-power-on](../img/compare/01-power-on.png) and [02-load](../img/compare/02-load.png) (recording
`work/stage1/c1/session.ttd`, Pentagon 128, the TRD); the stage 1 shots `work/stage1/screens/01`-`04`.

## The machine (ROM texts, not on the disk)

Shown for completeness: these come from the Pentagon's ROMs, not from the game.

The 128 menu (frame 1615, [01-power-on](../img/compare/01-power-on.png), right):

```
128
 Tape Loader
 128 BASIC
 Calculator
 48 BASIC
 TR-DOS
© 1986 Sinclair Research Ltd
```

TR-DOS (frame 1700, `work/stage1/screens/02-trdos.png`), then `RUN` typed at the prompt:

```
* TR-DOS Ver 5.04T*
© 1986 Technology Research Ltd.
(U.K.)
BETA 128
A>
```

## The disk catalogue

| Where | Text |
| --- | --- |
| the disk label (catalogue sector, track 0 sector 9) | `ZYNAPS  ` |
| file 0 | `ZYNAPS  ` type `B`, 168 bytes, 137 sectors |
| file 1 | `boot    ` type `B`, 988 bytes, 4 sectors |

## `boot.B`

A generic TR-DOS boot. Its BASIC, line 1 (line 0 is a `REM` holding the boot's machine code, no readable text):

```
CLEAR VAL "29999": RANDOMIZE USR VAL "23872": CLEAR VAL "64e3": RANDOMIZE USR VAL "15619": REM : RUN "        "
```

(`RANDOMIZE USR 15619` with `REM : RUN "name"` is TR-DOS's command line from BASIC; in the file the name is eight
spaces.)

On screen (frame 1990, [02-load](../img/compare/02-load.png), the third panel; `work/stage1/screens/03-boot-list.png`):
a framed list on a blue screen, with no text of its own besides the names from the catalogue.

```
ZYNAPS          (the frame's title bar: the disk label)
ZYNAPS          (the list, first entry highlighted)
boot
```

## `ZYNAPS.B`

Line 0 is a `REM` holding the loader (`$5D40`), no readable text. Line 1:

```
CLEAR VAL "24575": RANDOMIZE USR VAL "23872"
```

The loader prints nothing: the screen stays clear while the blocks load (frame 2100), then the intro draws its
first picture ([intro.md](intro.md)).

## The 48K original, for comparison

The tape (`work/ref48/ZYNAPS.TAP`, a 1993 re-tape of the Hewson game, [differences.md](differences.md)): the 48 BASIC
ROM's `© 1982 Sinclair Research Ltd`, `LOAD ""` typed, then the blocks `Zynaps` (BASIC), `zynaps0.c` (the loading
screen) and `zynaps1.c` (the game).
