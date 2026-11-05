# NETHER+.W

**What it is.** The text file `NETHER+.W` on the game's SCL. It is the authors' history of the remake, what is new, the
thanks, the credits, the software used, the greetings and the contact address. No program reads it: it was meant for a
disk tool's text viewer.

**The file.** 12 748 bytes as UTF-8 here; on the disk it is CP866 with CR LF line ends and starts at file sector 476
([03](../03-build-and-load.md)). The build input is the plain copy
[`src/res/text/nether-plus-w.txt`](../../src/res/text/nether-plus-w.txt), which `tools/mkdisk.py` writes back
byte for byte. This page is for reading. The paragraphs are joined again where the authors broke them for a 64-column
screen, and the double spaces of their justification are single. The spelling is the authors' (`THAKS`, `вкалад`,
`Пройзводство`, `Screns`, `debuged`). Doc [08](../08-hud-and-text.md) 8.10 describes the file;
[01](../01-game-design.md) 1.13 checks its claims against the code.

## The original

```text
        ________________________/│  ___/│_______/│  ___ TM
       /  _____  __/ ____/___  /  \/  / │__  __/  \/  /
      /  __/\ / / /  __/\ __/ /      /  │ / /___\    /
      \_____/ \_\ \_____/\_\  \__/\__\__\ \_\_______/
       ─√─√─√─√─√─√─√─√─√─√ \__/ ─√─√! № d u s ┼ r y-
               P+R+O+U+D+L+Y   P+R+E+S+E+N+T+S

                   REALTIME STRATEGY GAME

         #####    #####    ###  ##  ##   #####  ######
        ##  ##   ##  ##   ## ## ## ##   ##  ## ##   ##
       ##   ##  ##   ##  ##     ####   ##   ##  ##  ##
       #######  ##   ##  ##     ## ##  #######   #####
       ##   ##   ##  ##   ## ## ##  ## ##   ##  ##  ##
       ##   ## #########   ###  ##  ## ##   ##  ##  ##
        ##                          ##  ##
  ▄▄▄▄▄▄▄▄▄▄   ▄▄▄▄▄▄▄▄▄▄  ▄       ▄     ▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄
     ▄▄▄▄▄▄▄▀ █▄▄▄▄▄▄▄    █ ▀▀▄ ▄▀▀ █ ▄▀▀      █ █         █
  ▄▄▄▄▄▄▄▄▄▄▀ ▀▄▄▄▄▄▄▄▄▄▄ █    ▀    █ █        █ ▄▀▀▀▀▀▀▀▀▀█

· ·--/\/\-A D V A N C E D   N E T H E R   E A R T H-\/\/--·  ·
```

### НЕМНОГО ИСТОРИИ

Для начала хотелось бы немного рассказать о создании этой игрушки. Кто не хочет читать эту нудную историю, советую
пролистать следующий абзац.

Примерно года 3-4 назад (сейчас уже не припомню точно), когда у меня был Spectrum 48К (конечно же с любимыми всеми нами
кассетами), один мой знакомый притащил мне кассету с новыми игрушками. И вот начался долгий и утомительный процесс
загрузки всех игрушек. А грузили мы, сейчас скажу с чего - моно-магнитофон "Электроника М327". Много мы всякой дури
просмотрели, и тут увидели скромную игру, которая была руссифицированна и не имела точного названия; помню: Базик-заголовок
назывался NETHER и все. И вот с этого дня мы все просто затащились от этой игры, играли в нее до отупения. Но вскоре этот
самый знакомый продал свой комп, а у меня как на зло, запоролась кассета с этой замечательной игрой (ну не мне Вам
говорить как порятся кассеты). Потом ко мне попала версия на английском языке и вот тогда-то я узнал полное название. Но
почему то не записал - ее мне хотелось на русском (вот дурак !). И как-то я про нее забыл.

И вот когда у меня уже появился 128-й Pentagon с дисководом, естественно, и я немного поумнел, ко мне в руки попала
ломанная дисковая версия данной игры. Она была настолько изуродована, что не подлежала никакому восстановлению. В ней
все отгрузки состояний были занулены, а вместо них поставлены RET'ы; игра ОЧЕНЬ сильно глючила, так что не было никакого
желания ее переделывать. Да хочется сказать, что эту версию делал наш местный ковровский хакер.

Немного позже этот же хакер (не буду называть его имени) выпустил еще одну версию этой игры. Эта версия оказалась еще
глючнее предыдущей, хотя там были сделаны отгрузки состояний на диск. Но для чего ? Они совсем не работали. Мы конечно же
сообщили им (это некая хакерская группа) о глюках, но как мне кажется они не собираются их признавать и ничего
переделывать не будут.

Мы решили - так дело не пойдет - надо что-то делать. Не позволим издеваться над нашей любимой игрой. Но, чтобы самим
начать переделывать эту игру, нам нужна была, боле-менее, нормальная кассетная версия. И вот начались долгие поиски, т.к.
с ломанным дерьмом мне не хотелось иметь дела. И вот вскоре Melted Snow у себя на кассетах нашел ту самую
руссифицированную версию этой игры. Нашей радости не было предела, и мы тут же начали работу над ней. И вот теперь Вы
можете видеть плод наших стараний.

### ЧТО ЖЕ НОВОГО ПОЯВИЛОСЬ

Итак, что же нового появилось в данной версии игры. Как Вы, наверное, уже успели заметить появилась прекрасная графика,
т.е. заставочная и менюшная картинки, а также красивый final cut и не менее красивый dead end :-(. Это стало возможным
благодаря Demiurge Ash'у и Paracels'у - нашим great gfx maker'ам, за что им огромное спасибо !

Также появилась прекрасная музыка на AY'шку, за что спасибо X-Man'у и Syrus'у/EI.

Сделаны НОРМАЛЬНЫЕ load/save процедуры. За что говорю огромное спасибо Paracels'у за его TURBO WG_DRIVER. Кстати этот
драйвер обрабатывает всевозможные ошибки, возникающие при работе с диском !

Исправлены некоторые баги, которые были найдены в процессе работы над игрой.

Я решил не делать никаких cheat'ов, т.к. эту игруху очень легко пройти. Вот однажды мы сели поиграться в тестовую версию
"Advanced Nether Earth'a" и прошли ее, выпустив всего 2 или 3 робота (!), так что cheat, я думаю, здесь ни к чему.

### THAKS WORLD !

Хочу сказать огромное спасибо всем тем, кто всячески помогал мне в создании этой игры.

Во-первых, спасибо тем, кто эту игру сделал. К моему великому сожалению я не знаю кто же все-таки создал этот шедевр, но
все равно спасибо !

- Спасибо Melted Snow за предоставленную кассетную версию.
- Спасибо Spy и Crazy за бета тестинг.
- Спасибо Paracels за прекрасную графику, Turbo WG-Drive и за то, что вечно ходил вокруг и всячески надоедал мне.
- Спасибо Demiurge Ash за не менее крутую графику.
- Спасибо Senat за навороченную интруху.
- Спасибо Syrus за крутую музыку.
- Спасибо X-Man'у за не менее крутую музу.
- Ну как же не сказать спасибо себе (кроме самого себя никто не скажет) за то, что все-таки хватило терпения доделать
  эту игру до конца.

### Full, Total Creditz.

Whole project organized by D-Man from Eternity Industry.

**ИНТРУХА:**

| Who | What |
| --- | --- |
| Senat/EI | Intro coding. |
| Syrus/EI | Cool muzak. |
| Paracels/EI | graphics, some code, fixing, text. |

**HELP:**

| Who | What |
| --- | --- |
| D-Man/EI | Main coding, texts, debuged, screens in "Характеристика компонентов", Main screen. |
| Paracels/EI | Screns in "Пройзводство роботов", "Программирование роботов", "Особенности игры", Menu screen, Main screen, debuged. |
| Demiurge Ash/EI | Screens in "Описание игры" & "Credits", critics, logo "Адская Земля" in Menu screen. |
| Crazy/EI | Testing, mistakes debuged, critics. |
| X-Man | Muzak. |

**GAME:**

| Who | What |
| --- | --- |
| D-Man/EI | Add coding, disked, remixed, debuged, packed, Dead End coding & all other things. |
| Paracels/EI | Menu screen, Final Cut screen with exploded plant & "Victory with U!", critics, debuged, Load/Save procedures (full WG'93 control), Final Cut coding. |
| Demiurge Ash/EI | Title screen, screen in Dead End, critics. |
| Syrus/EI | Small muzak in Dead End. |
| Crazy/EI | Testing, critics. |
| X-Man | Muzak in game, muzak in Final Cut. |

### Software Used:

- Alasm 3.8c & 3.9 (by Alem)
- STS 5.1 & 6.2 (by Stalker)
- Xas 9.06+ & 7.432 (by Max Petrov & Creator)
- Art Studio 128+ (by J.Hutchby)
- Maxsoft Screen Packer v1.3 (by MaxSoft)
- ASC v?.?? (by ASC)
- Pro Tracker 2.4 (by GDC & PhF)
- Pro Tracker 3.1a (by GDC)
- Hrum v3.5i (by Dmitry Pyankov)

### Helloes:

Ну а теперь пришло время для приветов (куда мы без них). Сначала приветы всем нашим друзьям:

| City | Who |
| --- | --- |
| Kovrov | Melted Snow, Father Michael |
| Vladimir | MegaCode/Extreme (Exploder, Sat, Tox, Snake & Scar) |
| Voronezh | Virtual Vision Group (Rom Corp. & others) |
| Tcheboksary | Phantom Family (Andrew FER & others.) |
| Gomel | RUSH (Kvazar & others) |
| Novosibirsk | Flash inc. (Fikus & others.) |
| Armavir | Accept Corp./Mafia PC (M.O.T., Phantom Lord & others) |
| Tchaikovsky | C.I.C. (J, Y & others) |
| Rybinsk | Auryn Group/Cyber Punks Unity (Elf & others.) |
| Yoshkar-Ola | Red Ltd. (Glen & others) |
| Krasnodar | GAS 13 |
| Obolensk | Laser Software (Mr.Z, Mitchell & others) |
| Stary Oskol | Global Corp. (Dr. Max, KUM, Andy First, Alex Kerman) |
| Velikie Luki | Player & others |
| Shadrinsk | Serzh & others. |

А теперь приветы всем тем, кто внес свой большой вкалад в развитие Speccy:

Extreme, Progress, Prestige, Rush, Code Busters, Mayhem, Aliance, Antaress & other coolest unifications of best speccy
people.

### Contact Adress:

Для тех, кто хочет с нами связаться, оставляю свои координаты:

> 601901 Владимирская обл., г.Ковров,<br>
> ул.Чернышевского, д.7, кв. 17,<br>
> Калинин Дмитрий (aka D-Man/EI)

*Last Release Date: 9th of March 1998. D-Man, Eternity Industry, Kovrov Cool City.*

## In English

The art at the top reads "Eternity Industry (TM) proudly presents. Realtime strategy game. ADVANCED. Advanced Nether
Earth".

### A little history

To begin with, I would like to tell a little about how this game was made. Whoever does not want to read this boring
story, I advise to skip the next paragraph.

About 3-4 years ago (I no longer remember exactly), when I had a Spectrum 48K (with the cassettes we all loved, of
course), a friend of mine brought me a cassette of new games. And so began the long and tiring loading of all the
games. And we loaded them, I'll tell you from what, a mono tape recorder "Elektronika M327". We looked through a lot of
rubbish, and then we saw a modest game that had been translated into Russian and had no exact title; I remember the
BASIC header was called NETHER, and that was all. From that day on we were simply hooked on the game and played it
until we were dazed. But soon that same friend sold his computer, and, as luck would have it, my cassette with this
wonderful game went bad (I need not tell you how cassettes go bad). Later the English version came to me, and only
then did I learn the full title. But for some reason I did not record it: I wanted it in Russian (what a fool!). And
somehow I forgot about it.

And when I already had a 128K Pentagon with a disk drive, naturally, and had grown a little wiser, a cracked disk
version of this game fell into my hands. It was so mutilated that it was beyond any repair. All the state saves in it
were zeroed and RETs put in their place; the game glitched VERY badly, so I had no wish to rework it. And I have to
say that this version was made by our local Kovrov hacker.

A little later the same hacker (I will not name him) released another version of the game. This version turned out
even buggier than the previous one, although it did have state saves to disk. But what for? They did not work at all.
Of course we told them (it is some hacker group) about the bugs, but it seems to me they are not going to admit them
and will not fix anything.

We decided: this won't do, something must be done. We will not let them mock our favourite game. But to start
reworking the game ourselves we needed a more or less normal tape version. And so began the long search, since I did
not want to deal with cracked crap. And soon Melted Snow found that very Russian version of the game on his cassettes.
Our joy knew no bounds, and we started working on it at once. And now you can see the fruit of our efforts.

### What is new

So, what is new in this version of the game. As you have probably noticed already, there is beautiful graphics: the
title and menu pictures, and also a beautiful final cut and an equally beautiful dead end :-(. This was made possible
by Demiurge Ash and Paracels, our great gfx makers, many thanks to them!

There is also beautiful music for the AY, thanks to X-Man and Syrus/EI for it.

NORMAL load/save procedures have been made. For that I say a huge thank you to Paracels for his TURBO WG_DRIVER. By the
way, this driver handles every possible error that can happen when working with the disk!

Some bugs found while working on the game have been fixed.

I decided not to add any cheats, since this game is very easy to beat. Once we sat down to play a test version of
"Advanced Nether Earth" and beat it having launched only 2 or 3 robots (!), so a cheat, I think, is of no use here.

### Thanks, world!

I want to say a huge thank you to everyone who helped me in every way in making this game.

First of all, thanks to those who made this game. To my great regret I do not know who created this masterpiece after
all, but thanks all the same!

- Thanks to Melted Snow for the tape version.
- Thanks to Spy and Crazy for beta testing.
- Thanks to Paracels for the beautiful graphics, the Turbo WG-Drive, and for always hanging around and pestering me in
  every way.
- Thanks to Demiurge Ash for the equally cool graphics.
- Thanks to Senat for the fancy intro.
- Thanks to Syrus for the cool music.
- Thanks to X-Man for the equally cool music.
- And how can I not thank myself (nobody but me will) for having had the patience after all to finish this game.

### The credits, the software, the greetings

The credits and the software list are in English in the original. The Russian words in them are the intro
("ИНТРУХА"), the help pages "Характеристика компонентов" (the components' characteristics), "Производство роботов"
(robot production), "Программирование роботов" (programming robots), "Особенности игры" (features of the game),
"Описание игры" (game description), and the logo "Адская Земля" (Hellish Earth).

"And now it is time for the greetings (where would we be without them). First, greetings to all our friends:" (the
table). "And now greetings to all those who made a big contribution to the development of the Speccy:" (the list).

"For those who want to get in touch with us, I leave my address": 601901 Vladimir region, Kovrov, Chernyshevskogo
street, house 7, flat 17, Kalinin Dmitry (aka D-Man/EI).
