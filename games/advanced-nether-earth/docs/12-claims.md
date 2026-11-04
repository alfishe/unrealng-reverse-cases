# What the authors say: the texts of Advanced Nether Earth, verbatim

Every text on the two media and in the game that says what Advanced Nether Earth (ANE) is and what it changed, in
the original (Russian, or English where the authors wrote English) with an English translation. What the code says
about each claim: [10](10-gameplay-logic.md) section 4.

| Source | Where it was read |
| --- | --- |
| `NETHER+.W` | the TOSEC SCL (`orig/Advanced Nether Earth (1998)(Eternity Industry)(128K)(RU).scl`, file 4, 9143 bytes, CP866 text with CR LF): `src/res/text/nether-plus-w.txt` is the whole file decoded |
| the intro scroller | recording `work/stage1/s2/session.ttd` frame 5000, RAM bank 5 (`work/images/scl-intro-bank5.bin`) |
| the help program ("2-Help" in the boot menu) | the live instance of `work/stage1/s1` at the help menu, RAM banks 0 and 2 (`work/stage1/explore/help-bank*.bin`); all of it raw and decoded in `src/res/text/help-text.md` (`tools/help_text.py`) |
| the 2017 `ANE_FC.TRD` | the BASIC on the disk (`ane_fc.B`) and the unpacked image (`work/images/fc-unpacked-cpu.bin`) of recording `work/stage1/c1/session.ttd` |

The help program writes Russian in Latin letters that its font draws as Cyrillic (a=а ... w=в, q=я, [=ш, ]=щ, ^=ч,
@=ю, <=э, |=Э, ~=Ч, {=Ш); the quotations below are decoded. The game's own texts (menus, panel) use another mapping
(Latin letters chosen by shape: P=Р, H=Н, C=С ...) and are stage-2 work.

## 1. NETHER+.W: "a little history" and "what is new"

### 1.1 The history (abridged to the sentences that matter; the whole text is in nether-plus-w.txt)

> Примерно года 3-4 назад ... когда у меня был Spectrum 48К ... увидели скромную игру, которая была
> руссифицированна и не имела точного названия; помню:Базик-заголовок назывался NETHER и все.

About 3-4 years ago, when I had a Spectrum 48K, we saw a modest game, Russified, with no proper title; I remember
the BASIC header was just called NETHER.

> ко мне в руки попала ломанная дисковая версия данной игры. Она была настолько изуродована, что не подлежала
> никакому восстановлению. В ней все отгрузки состояний были занулены, а вместо них поставлены RET'ы; игра ОЧЕНЬ
> сильно глючила ... Немного позже этот же хакер ... выпустил еще одну версию этой игры. Эта версия оказалась еще
> глючнее предыдущей,хотя там были сделаны отгрузки состояний на диск. Но для чего ? Они совсем не работали.

A cracked disk version of the game came into my hands. It was so mutilated that it could not be restored: all the
state saves were zeroed and replaced by RETs; the game was VERY buggy ... A little later the same hacker released
another version. It turned out even buggier, though it had state saves to disk. But what for? They did not work at
all.

> нам нужна была , боле-менее , нормальная кассетная версия ... И вот вскоре Melted Snow у себя на кассетах нашел
> ту самую руссифицированную версию этой игры.

We needed a more or less normal tape version ... soon Melted Snow found that very Russified version on his tapes.

### 1.2 "ЧТО ЖЕ НОВОГО ПОЯВИЛОСЬ" (what is new), verbatim

> Итак, что же нового появилось в данной версии игры. Как Вы, наверное, уже успели заметить появилась прекрасная
> графика, т.е. заставочная и менюшная картинки, а также красивый final cut и не менее красивый dead end :-(. Это
> стало возможным благодаря Demiurge Ash'у и Paracels'у - нашим great gfx maker'ам, за что им огромное спасибо !
>
> Также появилась прекрасная музыка на AY'шку, за что спасибо X-Man'у и Syrus'у/EI.
>
> Сделаны НОРМАЛЬНЫЕ load/save процедуры. За что говорю огромное спасибо Paracels'у за его TURBO WG_DRIVER. Кстати
> этот драйвер обрабатывает всевозможные ошибки, возникающие при работе с диском !
>
> Исправлены некоторые баги, которые были найдены в процессе работы над игрой.
>
> Я решил не делать никаких cheat'ов,т.к. эту игруху очень легко пройти. Вот однажды мы сели поиграться в
> тестовую версию "Advanced Nether Earth'a" и прошли ее, выпустив всего 2 или 3 робота (!), так что cheat, я
> думаю, здесь ни к чему.

So, what is new in this version. As you have probably noticed, there are fine graphics: the title and menu pictures,
and a beautiful final cut and an equally beautiful dead end :-(. Thanks to Demiurge Ash and Paracels, our great gfx
makers.

There is also fine AY music, thanks to X-Man and Syrus/EI.

PROPER load/save procedures have been made. Many thanks to Paracels for his TURBO WG_DRIVER; it handles all kinds
of errors that arise when working with the disk!

**Some bugs that were found while working on the game have been fixed.**

I decided not to add any cheats, since the game is very easy to finish: once we played the test version of
"Advanced Nether Earth" and finished it releasing only 2 or 3 robots (!).

### 1.3 The credits of NETHER+.W, GAME part (verbatim, English in the original)

```text
D-Man/EI         - Add coding, disked, remixed, debuged, packed,
                   Dead End coding & all other things.
Paracels/EI      - Menu  screen, Final Cut  screen with exploded
                   plant & "Victory with U!", critics,  debuged,
                   Load/Save procedures (full WG'93 control),Fi-
                   nal Cut coding.
Demiurge Ash/EI  - Title screen, screen in Dead End, critics.
Syrus/EI         - Small muzak in Dead End.
Crazy/EI         - Testing, critics.
X-Man            - Muzak in game, muzak in Final Cut.
```

The text names no gameplay change. The only claim about the game's behaviour is the one-line "some bugs were fixed".

## 2. The intro scroller (English in the original, verbatim, the spaces collapsed)

> HEY GUYZZZ ! 'TIS ETERNITY INDUSTRY WITH OUR NEW COOLEZT RELEAZE CALLED 'ADVANCED NETHER EARTH' DA KOOLEZT REMIX
> OF GOOD REALTIME STRATEGY GAME 'NETHER EARTH' (C) 1998 REMIX ETERNITY INDUSTRY ... DA SMASHED UP CREDITZ: INTRO
> CODING.......SENAT GFX.............PARACELS MUZAK..............SYRUS VIOLENTLY PACKED...D-MAN MORAL
> SUPPORT.........EI XOR SERVICE.....PARACELS ... CHILLY GAME CREDITZ: PRODUCED..............EI
> SUPPLIED.....MELTED SNOW REMIXED............D-MAN PACKED.............D-MAN TESTED.............CRAZY ... PLATINUM
> RELEAZE DATE: 9TH OF MARCH 1998 ... (C) 1998 ETERNITY INDUSTRY KOVROV COOL CITY! ... PRESS 'SPACE' AND N'JOY !!!

"A remix" of Nether Earth; the game supplied by Melted Snow, remixed and packed by D-Man; released 9 March 1998. No
gameplay claim.

## 3. The help program (Russian in the original)

### 3.1 The credits page (English in the original, verbatim, line breaks of the 33-column page joined)

> GAME: D-Man/EI: add coding, restoring, packing, dead end coding. Paracels/EI: final cut coding, menu scrn, final
> cut scrn, turbo VG93 control. Demiurge Ash/EI: title scrn, dead end scrn. Syrus/EI: muzak in Dead End. X-Man:
> main muzak, muzak in Final Cut. ... Tape version was kindly supplied by Melted Snow

"Restoring" (not "fixing"): the game restored from the tape.

### 3.2 "ОСОБЕННОСТИ ИГРЫ" (features of the game), verbatim

> В процессе боя уничтожаются роботы обеих сторон. При их разрушении остаются обломки, затрудняющие движение
> других роботов. Если в одном месте будут последовательно уничтожены 3 робота, гора обломков достигнет такой
> высоты, что через нее не смогут проехать даже роботы на антигравах при массированном применении роботов (а в
> серьезных боях могут участвовать до 50 роботов с той и с другой стороны). Это приводит к образованию
> непроходимых завалов, парализующих боевые действия.

In battle robots of both sides are destroyed. They leave wreckage that hinders other robots. If 3 robots are
destroyed one after another in one place, the pile of wreckage gets so high that even anti-grav robots cannot pass
(and up to 50 robots a side may take part in serious battles). Impassable blockages form and paralyse the fighting.

> Для разбора такого завала подведите к нему робота с атомной бомбой и взорвите ее (вручную, войдя в боевой
> режим).Обломки при этом, скорее всего,не уничтожаться. Они слишком прочные. Однако уничтожаться стоящие вокруг
> здания,и на их месте образуются проходы.

To clear such a blockage bring a robot with an atomic bomb and set it off (by hand, in combat mode). The wreckage
will most likely survive, it is too strong, but the buildings around are destroyed and passages open.

> Сквозь здания и завалы выстрелы не проходят, однако, некоторые роботы могут этого не понимать. Например, если по
> разные стороны стены встретятся два робота (ваш и вражеский), запрограммированные на 'поиск и уничтожение
> вражеских роботов', они начнут стрелять друг в друга сквозь стену и будут делать это до тех пор, пока у вас не
> лопнет терпение.

Shots do not pass through buildings and wreckage, but some robots may not understand this: two robots on either
side of a wall, both on "search and destroy enemy robots", will shoot at each other through the wall until your
patience runs out.

> Роботы запрограммированные вами на 'поиск и уничтожение вражеских роботов', могут вам очень навредить,так как
> открывают огонь по врагу заранее, не обращая внимания на своих роботов ... При этом вместо врага они уничтожают
> своих.

Robots on "search and destroy enemy robots" open fire early, ignoring your own robots in the line of fire, and
destroy them instead of the enemy (friendly fire).

> Все роботы выглядят одинаково ... взгляните на экран радара ... Ваш катер на радаре обозначен мигающей точкой,
> точки такого же цвета, но горящие постоянно - ваши роботы, а точки другого цвета- враги.

All robots look the same; the radar tells them apart: your ship is the blinking dot, steady dots of the same
colour are your robots, dots of the other colour the enemy.

### 3.3 "ЗАХВАТ ЗАВОДОВ И БАЗ" (capturing factories and bases), verbatim

> Захватить завод очень просто - достаточно въехать во двор завода и простоять там около 45 сек. Таким же образом
> захватываются вражеские базы.

Capturing a factory is simple: drive into its yard and stand there about 45 seconds. Enemy bases are taken the same
way.

### 3.4 The components and their prices ("ХАРАКТЕРИСТИКА КОМПОНЕНТОВ"), the claims only, verbatim

| Part | Text | Price in the help | `PartCosts` (code) |
| --- | --- | --- | --- |
| ЭЛЕКТРОНИКА | "электроника позволит ему действовать более осмысленно. Кроме того, электроника повышает скорость защитной реакции робота" (acts more sensibly; raises the speed of the defensive reaction) | 3 | 3 |
| А-БОМБА | "При взрыве она разрушает все строения и роботов в пределах одного экрана" (destroys all buildings and robots within one screen) | 20 | 20 |
| ФАЗОР | "Имеет большую убойную силу, выстрел проходит через 3 экрана" (great power, the shot crosses 3 screens) | 4 | 4 |
| РАКЕТЫ | "при повреждении робота более 50% стреляет одной ракетой, теряя половину убойной силы. Выстрел проходит через 3 экрана" (a robot damaged over 50 % fires one missile, half the power; crosses 3 screens) | 4 | 4 |
| ПУШКИ | "Имеет среднюю убойную силу (как 1 ракета), выстрел проходит через 2 экрана" (medium power, like one missile; crosses 2 screens) | 2 | 2 |
| АНТИГРАВЫ | "Имеют высшую скорость и проходимость, проходя над горами и пропастями" (fastest, cross mountains and chasms) | 10 | 10 |
| ТРАКИ | "проходит через горы, но не проходит через пропасти. Скорость средняя и падает в два раза при движении через горы" (cross mountains, not chasms; medium speed, halved on mountains) | 5 | 5 |
| БИПОД | "может двигаться только по гладкой поверхности ... Скорость движения также довольно низка" (smooth ground only, slow) | **5** | **3** |

### 3.5 Robot production and programming, the rules stated

> Робот должен состоять из одного вида шасси (АШ, ТШ или БШ) и, по крайнеи мере, одного вида оружия (А, Ф, РУ,
> АУ). Установка более 3-х видов оружия или нескольких одинаковых видов оружия на одного робота не допускается.

A robot is one chassis and at least one weapon; more than 3 weapons, or two of a kind, are not allowed. (NE's rule.)

> Живучесть робота прямо пропорционально стоимости шасси и установленного оружия (не считая А-бомбы).

A robot's toughness is in proportion to the cost of its chassis and weapons (the A-bomb not counted).

> Можно выпускать не программируя до 3-х роботов подряд

Up to 3 robots may be released in a row before programming them.

> Внимание: один и тот же приказ может иметь ограниченное число роботов(обычно не более четырех)

Note: one order can be held by a limited number of robots (usually no more than four).

> Все,что для начала закупок удалось наскрести на Земле, это 20 космодолларов

All Earth could scrape together for the first purchases is 20 cosmodollars. (Start resources: NE's 20 general.)

## 4. The 2017 disk ANE_FC.TRD

The BASIC `ane_fc.B` carries after its line, inside the 174 bytes, the text (verbatim):

> KALANTAJ KONSTANTIN. UKRAINE. KRIVOY ROG. 10.05.2017

Its unpacked image is ANE's Final Cut alone (the victory sequence, the screens of `work/stage1/c1/screens.png`):
a Russian caption drawn on the first picture (read from the screen, a bitmap, not text in memory): "После долгих
ожесточенных боев армии людей наконец-то удалось разбить базу исигнианцев. Теперь их раса уничтожена!" (After
long fierce battles the human armies finally managed to smash the Isignian base. Now their race is destroyed!),
then the scroller (verbatim, spaces collapsed):

> CONGRATULATIONS! Y'VE FINALY DESTRO-YED THOSE STINKY ISIGNIA-NTS! AND NOW YOUR NATIVE PLANET AND NATION ARE FREE !
> NOW YOU ARE REAL HERO OF THE GALAXY AND FOR EVERY HUMAN BEING ALL OVER THE WORLD ! LOOSERS- ISIGNIA-NTS ARE
> COWARDLY RUNNING BACK TO THEIR DIRTY PLANET AND NOW YOU CAN BREATH DEEP AND ACCEPT FROM THE THANKFUL PEOPLE A
> LITTLE GIFT FOR GIVING THEM FREEDOM! ... GAME OVER ... (C) 1998 ETERNITY INDUSTRY

and the picture "Victory is with U!!!". No game on that disk, so no gameplay claim; the 2017 BASIC names only who
put it on a disk and when.

The same sequence is in the 1998 SCL: on a live instance from the game menu (`explore/gamemenu.szx`, `0`, 300
frames of play) `EnemyBuildings` (`$FD42`) poked to 0 ends the game as a win, and the SCL loads and plays the same
caption picture and scroller (`screens/08-final-cut-victory-scl.png`, `screens/09-final-cut-scroller-scl.png`). Its
memory then (`explore/won-bank*.bin`) against the 2017 disk's at its end (`work/images/fc-end-cpu.bin`): `$8000-$BFFF`
equal in all 16384 bytes, `$6060-$7FFF` in 8092 of 8096 (`$6218`, `$62B1-$62C7`: working bytes), `$C000-$F76C`
(bank 0 in the SCL) equal in every byte; only above `$F76C` (the depacker, the stack) differs. The 2017 disk is the 1998 Final Cut block, repacked (Hrust 1 in place of
the SCL's packer, see `docs/03-build-and-load.md`) behind a new BASIC: no new content.
