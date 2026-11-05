# The '99 intro scroller

The text that scrolls up in the '99 intro's right-hand panel, under the ZS EDITION 1999 logo and next to the
author's photo: the keys, a greeting, what the edition is, the machines it uses and the story of how it was made;
CP866 with CR LF and TABs, `$654F-$7587` of stage 2 (4 153 bytes, the `$00` end included), signed 28.01.1999.

Stage 2 is the first packed block of `NEZSEd99.B` (sectors 1-18, read to `$8000`, unpacked to `$61A8-$7D86`:
`work/media/99/stage2-out.bin`). The text is laid out for a 32-column panel, justified with extra spaces, paragraphs
indented by two spaces; a TAB (`$09`) indents the greeting and the signature. The build resource is the front99
part's ([`work/stage2/STATE-front99.md`](../../work/stage2/STATE-front99.md)); this page is for reading. Under the
panel a one-line colour ticker repeats "You wanted new levels? Take its!": it is not in this text (no block holds it as
ASCII), see [06](../06-rendering.md).

Below, the justified lines are joined into paragraphs; the spelling is the author's (`рабирать`, `сыше`, `програмы`).

## The original

"ENTER" - приостановить скролл.

"SPACE" - продолжить загрузку.

Привет!

Зотов Сергей (ZS) рад Вас приветствовать!

<- Это моя фотка.

Наконец-то я доделал свою первую серьезную работу! Это NETHER EARTH ZS EDITION'99!!! Можно сказать, что это remake
старой доброй игры NETHER EARTH производства 1987 года. Давно, не правда ли, это было? И за это время не появилось ни
одной RealTime стратегии, за исключением Black Raven, но это аж в 1997 году!!! 10 лет прошло! И за это время никто
не смог не то что переплюнуть, но даже повторить NETHER EARTH (опять же не считая Черного Ворона)!!!

Я не собирался переплюнуть ее (Я не настолько хороший кодер, пока), но навернуть Я ее смог (так мне, по крайней
мере, кажется). Но Вы это сами увидите.

Несколько инструкций по эксплуатации.

Я не стал раздувать игру до 128Kb, как это сделали ETERNITY INDUSTRY. Но если у Вас 128Kb, то игра будет их
использовать (она это сама определит - кого этим удивишь?). На 48Kb игра будет подгружаться, и к тому же все уровни
для игры должны находиться на том же диске, что и игра. Для 128Kb нет этого ограничения. Также возможен перенос
игры на ленту и загрузка с магнитофона. Для этого Я написал утилиту NE_TAPER (Я знаю нескольких юзеров, которые до
сих пор не обзавелись дисководами).

Все описания встроены в игру, но на диске хранятся в независимых файлах формата ZX Word (при копировании сохраняйте
порядок этих файлов, это ВАЖНО!). В них можно прочитать все подробности о игре. Здесь скажу только то, что Я
планирую выпустить еще несколько десятков дополнительных уровней к моему Edition. Могу сделать уровни на заказ.

Со всеми отзывами и предложениями можете обращаться по телефону в Самаре: 58-86-08 или писать на e-mail:
crazyzs@hotmail.com.

════════════════════════════════

А теперь традиционно история создания игры. Кому не интересно может нажать "SPACE".

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
пессимистично. А Я, все таки сделал свой Edition!!! Теперь дело за Вами - всеми теми, кто загрузил ее. Оцените!
Очень надеюсь, что получу хотя бы один звонок или электронное письмо.

Желаю Успеха!

ZS, 28.01.1999

Нажмите пробел...

## English translation

"ENTER": pause the scroll.

"SPACE": go on loading.

Hi!

Sergey Zotov (ZS) is glad to greet you!

<- This is my photo.

At last I have finished my first serious work! This is NETHER EARTH ZS EDITION'99!!! You could say it is a remake of
the good old game NETHER EARTH made in 1987. Long ago, wasn't it? And in all that time not a single RealTime strategy
game has appeared, except Black Raven, and that only in 1997!!! 10 years went by! And in all that time nobody managed
not just to outdo but even to repeat NETHER EARTH (again, not counting Black Raven)!!!

I did not mean to outdo it (I am not that good a coder, yet), but I did manage to beef it up (so it seems to me, at
least). But you will see for yourself.

A few operating instructions.

I did not blow the game up to 128Kb as ETERNITY INDUSTRY did. But if you have 128Kb, the game will use it (it finds
that out by itself: who would be surprised by that?). On 48Kb the game will load extra parts, and besides, all the
levels for the game have to be on the same disk as the game. With 128Kb there is no such limit. The game can also be
moved to tape and loaded from a tape recorder. For this I wrote the utility NE_TAPER (I know a few users who still
have not got a disk drive).

All the descriptions are built into the game, but on the disk they are kept in separate files in ZX Word format
(when copying, keep the order of these files, it is IMPORTANT!). In them you can read all the details about the game.
Here I will only say that I plan to release several dozen more levels for my Edition. I can make levels to order.

With any reviews and proposals you can call me by phone in Samara: 58-86-08, or write to e-mail: crazyzs@hotmail.com.

════════════════════════════════

And now, as is traditional, the history of how the game was made. Those not interested can press "SPACE".

It began in 1991, when my friend was bought a Sintez 2. The first time I saw NETHER EARTH I paid it no particular
attention. Back then the game seemed very hard. My friend played it for hundreds of days (by the in-game clock). In a
few months he learnt to finish it in a couple of dozen days (today's record for finishing it: one robot, in 10 hours
50 minutes). Then I too begged a Speccy for myself. I remember playing NETHER EARTH at night! Then for a while I got
carried away by ELITE3 and almost forgot NETHER EARTH. But in the summer of 1998 I decided to take up coding
seriously, and I remembered NETHER EARTH. And why should I put up with one and the same level?!?!?! Fed up!!! And I
began taking this game apart, literally to pieces. The main aim was the map, and how to change it so that the game
still worked. After many failed attempts (about a month without success), I finally cracked the map. But then a new
problem! Too little memory! All the 48K of memory is taken in this game! Not a single free byte! I had to do extra
loads and give up saving states (no need for it! see above). But! The TR-DOS system variables get overwritten. I knew
loaders without sysvars existed. But I did not want to break STS, and there was no other available program with an
independent loader. I had to ask somebody for help. That somebody was M.M.A. It was he who told me where to look for
the sources. A HUGE THANKS to him for that!!! But when I told him about my plans, he was in a pessimistic mood. And
yet I made my Edition!!! Now it is up to you, all of you who have loaded it. Judge it! I very much hope to get at
least one phone call or e-mail.

I wish you success!

ZS, 28.01.1999

Press space...
