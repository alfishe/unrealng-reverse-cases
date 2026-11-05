# NEZSEd99.W

The release's readme: an ASCII-art title, the file list, the history of the Edition, the difficulty and map claims and
the contacts; a ZX Word document in CP866, 5 384 bytes (catalogue length), 22 sectors. No program shows it: the 128 K
loader reads its first three sectors into page 3 at `$FD00` only because it reads 64 sectors in a row
([README](README.md)).

The build input is [`src/res/text/NEZSEd99.txt`](../../src/res/text/NEZSEd99.txt). The title is kept in a code block
with the TABs expanded to 8 columns (the "ZS" is drawn with the Cyrillic letters З and С). The lines justified to 64
columns are joined into paragraphs; the spelling is the author's (`обажает`, `обзац`, `рабирать`, `сыше`,
`крадчайшие`). The 248 bytes after the text in its last sector are a tool's buffer, kept as
[`src/res/text/slack/NEZSEd99.slack.bin`](../../src/res/text/README.md).

## The original

```text
                N  N EEEE TTTTT H  H EEEE RRR
                N  N E      T   H  H E    R  R
                NN N EEE    T   HHHH EEE  RRR
                N NN E      T   H  H E    R  R
                N  N EEEE   T   H  H EEEE R  R

                   EEEE  AA  RRR  TTTTT H  H
                   E    A  A R  R   T   H  H
                   EEE  AAAA RRR    T   HHHH
                   E    A  A R  R   T   H  H
                   EEEE A  A R  R   T   H  H

              ЗЗЗЗЗЗ
            ЗЗ      ЗЗ
                ЗЗЗЗ
        СССССС      ЗЗ     EEEE DDD  III TTTTT III  OO  N  N
      СС            ЗЗ     E    D  D  I    T    I  O  O N  N
      СС  ЗЗЗЗЗЗЗЗЗЗ       EEE  D  D  I    T    I  O  O NN N
      СС                   E    D  D  I    T    I  O  O N NN
        СССССССССС         EEEE DDD  III   T   III  OO  N  N
```

### NETHER EARTH ZS Edition'99

Hi! Я, Зотов Сергей, рад представить Вам свою первую серьезную работу. Это RealTime Strategy Game. Можно сказать,
это возрождение старой игры NETHER EARTH 1987 года. Мой Edition сохранил все основные черты и свойства старого
варианта игры и приобрел некоторые свои (сами поймете по ходу игры). Игра осталась 48, хотя если есть 128я память,
она будет использована. Возможен перенос игры на ленту (для тех, кто просто обажает магнитофон и для западных
юзеров, т.к. Я "закину" игру в InterNet, благо есть такая возможность). Для этого написана специальная утилита
NE_TAPER.

Сразу скажу, что в полный комплект NETHER EARTH ZS Edition'99 должны входить следующие файлы:

```text
    NEZSEd99.W - это самое описание
  ! NEZSEd99.B - сама игра
  ! NEabout .W - Об Edition'99
  ! NEdescri.W - Описания
  ! NEgreets.W - Приветы
  ! NEadvice.W - Советы бывалого игрока
    *.N        - уровни (сколько их будет не известно)
    NE_TAPER.B - утилита для перевода игры на ленту
```

ВНИМАНИЕ!!! Последовательность файлов, помеченых "!", не должна нарушаться. Это ВАЖНО для нормальной загрузки и
функциониривания игры.

Теперь немного об истории создания этого Edition. Кому не интересно, пролистайте следующий обзац.

Это началось в 1991, когда моему другу купили Sintez 2. Первый раз увидев NETHER EARTH, Я не обратил на нее особого
внимания. Тогда эта игра казалась очень сложной. Мой друг играл в нее сотнями дней (по внутренним часам). Через
несколько месяцев он научился проходить ее за пару десятков дней (сегодняшний рекорд ее прохождения - один робот, за
10 часов 50 минут). Потом Я тоже выпросил себе Speccy. Помню, Я ночами играл с NETHER EARTH! Потом на некоторое
время Я увлекся ELITE3, и о NETHER EARTH почти забыл. Но летом 1998 Я решил вплотную заняться кодированием, и
вспомнил о NETHER EARTH. А почему Я должен терпеть один и тот же уровень?!?!?! Надоело!!! И Я начал, буквально на
кусочки, рабирать эту игрушку. Главной целью была карта и как ее изменить, чтобы игра осталась работоспособной.
После множества неудачных попыток (около месяца не было успехов), Я наконец доломал карту. Но тут новая проблема!
Памяти мало! Вся 48я память в этой игре занята! Ни одного свободного байта! Пришлось делать подгрузки и отказаться
от сохранения состояний (не зачем это! см. сыше). Но! Системные переменные TR-DOS затираются. Я знал о
существовании загрузчиков без sysvars. Но ломать STS не хотелось, а другой доступной програмы с независимым
загрузчиком не было. Надо было просить у кого-то помощи. Этим кем-то оказался M.M.A. Он-то и подсказал мне где
искать исходники. За это ему ОГРОМНОЕ СПАСИБО!!! Однако когда Я рассказал ему о своих планах, он был настроем
пессимистично. Он показал мне NETHER EARTH - Адская Земля. И Я понял, что просто необходимо доделать мою работу,
причем в крадчайшие сроки. Дело в том, что Eternity Industry ничего не изменили в игре, кроме отгрузки/подгрузки
состояния игры (что, на мой взгляд, вообще лишнее, т.к. стандартная игра проходится за 11 дней! См. ADVICES). Да
еще в описании говорили о каком-то cheat'e!!! Какой там cheat?!?!?! Если только для компьютера.

В моем Edition несколько уровней сложности (EASY-MEDIUM-HARD-CRITICAL). И даже на EASY игра на порядок сложнее, чем
оригинал! А на некоторых картах вообще возможно играть только на EASY. На CRITICAL Я прошел только стандартную карту.

Самое главное в моем Edition, то что можно загружать различные карты-уровни (до 96 с одного диск, т.к. на экране
больше места нет, а для другого загрузчика в памяти места нет).

В связи с внесенными изменениями пришлось изменить и стартовое меню. Думаю, оно не плохо у меня получилось.

Подробнее можно прочитать в NEabout.W или в игре нажав на соответствующую надпись.

Некоторы подпрограммы переписаны заново, так что возможны глюки (хотя Я все тестировал десятки раз). Но если Вы
что-то обнаружите, свяжитесь со мной ниже указаными способами.

Вот, пожалуй, все что Я хотел Вам сказать (написать).

Пока Я не прекращаю разработку игры и обещаю, что выйдет еще хотя бы одна версия ZS Edition. Что касается уровней,
то их будет еще, по крайней мере, штук 20-30 (это очень серьезно).

Желаю удачи!

Со мной можно связаться следующими способами:

тел. (8462) 58-86-08 в Самаре.<br>
E-Mail: crazyzs@hotmail.com (предпочтительнее)<br>
или crazyzs@chat.ru

ZS, 30.01.1999

## English translation

The title reads NETHER EARTH, ZS EDITION.

### NETHER EARTH ZS Edition'99

Hi! I, Sergey Zotov, am glad to present to you my first serious work. It is a RealTime Strategy Game. You could say
it is a revival of the old 1987 game NETHER EARTH. My Edition has kept all the main features and properties of the
old version of the game and has gained some of its own (you will see as you play). The game has stayed 48K, though if
there is 128K memory, it will be used. The game can be moved to tape (for those who simply adore the tape recorder,
and for western users, since I am going to "throw" the game onto the InterNet, as I happen to have the means). A
special utility, NE_TAPER, was written for this.

Let me say at once that the full set of NETHER EARTH ZS Edition'99 must include the following files:

```text
    NEZSEd99.W - this very description
  ! NEZSEd99.B - the game itself
  ! NEabout .W - about Edition'99
  ! NEdescri.W - descriptions
  ! NEgreets.W - greetings
  ! NEadvice.W - a seasoned player's tips
    *.N        - levels (how many there will be is not known)
    NE_TAPER.B - the utility to move the game to tape
```

ATTENTION!!! The order of the files marked "!" must not be broken. It is IMPORTANT for the game to load and work
normally.

Now a little about the history of this Edition. If you are not interested, skip the next paragraph.

It began in 1991, when my friend was bought a Sintez 2. The first time I saw NETHER EARTH I paid it no
particular attention. Back then the game seemed very hard. My friend played it for hundreds of days (by the in-game
clock). In a few months he learnt to finish it in a couple of dozen days (today's record for finishing it: one robot,
in 10 hours 50 minutes). Then I too begged a Speccy for myself. I remember playing NETHER EARTH at night! Then for a
while I got carried away by ELITE3 and almost forgot NETHER EARTH. But in the summer of 1998 I decided to take up
coding seriously, and I remembered NETHER EARTH. And why should I put up with one and the same level?!?!?! Fed
up!!! And I began taking this game apart, literally to pieces. The main aim was the map, and how to change it so that
the game still worked. After many failed attempts (about a month without success), I finally cracked the map. But
then a new problem! Too little memory! All the 48K of memory is taken in this game! Not a single free byte! I had to
do extra loads and give up saving states (no need for it! see above). But! The TR-DOS system variables get
overwritten. I knew loaders without sysvars existed. But I did not want to break STS, and there was no other
available program with an independent loader. I had to ask somebody for help. That somebody was M.M.A. It was he who
told me where to look for the sources. A HUGE THANKS to him for that!!! But when I told him about my plans, he was in
a pessimistic mood. He showed me NETHER EARTH - Адская Земля (Hell Earth). And I understood that I simply had to
finish my work, and in the shortest time. The thing is that Eternity Industry changed nothing in the game except
saving / loading the game state (which in my view is needless anyway, since the standard game is finished in 11
days! See ADVICES). And their description even talked about some cheat!!! What cheat?!?!?! Only for the computer,
maybe.

My Edition has several difficulty levels (EASY-MEDIUM-HARD-CRITICAL). And even on EASY the game is an order of
magnitude harder than the original! And some maps can be played only on EASY at all. On CRITICAL I finished only the
standard map.

The main thing in my Edition is that different map-levels can be loaded (up to 96 from one disk, since there is no
more room on the screen, and no room in memory for another loader).

Because of the changes, the start menu had to change too. I think it came out not bad.

You can read more in NEabout.W, or in the game by pressing the matching caption.

Some subroutines were rewritten from scratch, so bugs are possible (though I tested everything dozens of times). But
if you find anything, contact me in the ways given below.

That is probably all I wanted to tell (write) you.

For now I am not stopping work on the game, and I promise that at least one more version of ZS Edition will come out.
As for levels, there will be at least 20-30 more of them (this is very serious).

Good luck!

You can contact me in the following ways:

phone (8462) 58-86-08 in Samara.<br>
E-Mail: crazyzs@hotmail.com (preferred)<br>
or crazyzs@chat.ru

ZS, 30.01.1999
