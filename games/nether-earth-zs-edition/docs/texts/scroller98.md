# The '98 intro scroller

The one-line scroller under the '98 intro picture: the author's greeting, the story of the edition and its changes;
KOI-7 N2 text with font switches, `$DAC2-$E3C9` of the intro block (2 312 bytes, `$00` included), inside the single
file `NEZSEd.B` (sectors 2-43 of the file, read to `$C000`); signed 23.12.1998.

It is not a file of its own: the BASIC reads the intro block to `$C000-$E9FF` and the intro scrolls this text along
the bottom of the screen ([06](../06-rendering.md)). The letters are KOI-7 N2: lower-case Latin codes are drawn as
Cyrillic by the intro's font at `$E6CC`; `$01 LO HI` switches to the font at `HI LO` (`$3D00`, the ROM's, for the
Latin names and the e-mail address, then back to `$E6CC`); `$00` ends it. `python3 tools/scroller_text.py
work/media/98/intro.bin C000 DAC2` decodes it. The build resource is the intro98 part's
(`work/stage2/STATE-intro98.md`); this page is for reading. The '98 game
menu's LOAD NEW LEVEL copies 500 bytes from `$DD00`, inside this text, as if they were a map
([01](../01-game-design.md)).

The text is one line; the long runs of spaces the author put between the parts (a pause on the screen) are paragraph
breaks here. The parts in the ROM's Latin font are in italics.

## The original

Привет поклонникам Спекки! Зотов Сергей рад представить Вам новый вариант старой игры! Это моя первая работа (думаю
не самая лучшая), которую Я решился выставить на общее обозрение. Эта игрушка была одной из первых, которую Я увидел
на Спекки. Сначала она мне не понравилась, но потом... Я "резался" в нее ночами, пытаясь разгромить исигнианцев как
можно быстрее. И это у меня получилось за 11 дней (по внутренним часам). Тут-то и настал облом!!! Сотый раз играть
на одном и том же поле!!!!! :-((( Еще когда Я не знал ассемблера, Я уже хотел создать новые уровни и усложнить
игру. Но...

Время шло, Я научился кое-как кодить, но сломать игру для меня было еще НЕВОЗМОЖНО. На какое-то время игра выпала из
моего поля зрения (Я увлекся "космической жизнью" в ЭЛИТЕ). Но вот этим летом приполз Я как-то с работы и подумал: А
не сыграть ли мне во что-нибудь старенькое? И тут...

Первые попытки изменения карты были безуспешными. Я пытался изменять отгрузки, а зря - столько времени потерял!!!

Но вот пришла ко мне удача!!!

Итак, опишу изменения сделанные мной в игре. Во-первых, что бросится в глаза - английские надписи! Да. За основу Я
взял оригинальную версию. Во-вторых, Вы никогда не узнаете сколько у врага роботов (так интереснее). В-третьих,
денег Вам дают немного больше. Это связано с тем, что у врага денег просто немерено!!! Также у врага имеется
возможность модернизировать своих УЖЕ ПОСТРОЕННЫХ роботов (для сложности). И еще! Карта сделана так, что бы враг
легче проходил на Вашу територию, чем Вы на его. Данная версия не является полной. Поэтому свои пожелания можно
высказывать по тел. 58-86-08 в Самаре, или писать на *crazyzs@hotmail.com.* Я постараюсь все учесть и не забуду
упомянуть о Вас. :)

Приветы, в общем-то, передавать некому. Меня еще никто не знает. Хотя... Большой привет М.М.А. и всем Самарским
хаккерам - *Stars of Keladan.* А так же *Omega Hackers Group, Flash inc., Fatality, Arsendancy,* и всем тем кто
имеет *WEB* странички в Интернете посвященные *Speccy!*

*ZS. 23.12.1998.*

Нажмите что-нибудь...

## English translation

Greetings to Speccy fans! Sergey Zotov is glad to present to you a new version of an old game! This is my first work
(not the best, I think) that I have dared to show to the public. This game was one of the first I saw on the Speccy.
At first I did not like it, but then... I "slashed away" at it at night, trying to rout the Isignians as fast as
possible. And I managed it in 11 days (by the in-game clock). And then came the letdown!!! Playing on the same field
for the hundredth time!!!!! :-((( Even when I did not know assembler, I already wanted to make new levels and make
the game harder. But...

Time went by, I learnt to code somehow, but breaking the game was still IMPOSSIBLE for me. For a while the game fell
out of my sight (I got carried away by the "cosmic life" in ELITE). But this summer I crawled home from work one day
and thought: why not play something old? And then...

The first attempts to change the map failed. I tried to change the loads, and in vain: so much time lost!!!

But then luck came to me!!!

So, let me describe the changes I made in the game. First, what will strike the eye: the English captions! Yes. I
took the original version as the base. Second, you will never know how many robots the enemy has (it is more
interesting that way). Third, you are given a little more money. That is because the enemy's money is simply
unlimited!!! The enemy can also upgrade its ALREADY BUILT robots (for difficulty). And one more thing! The map is made
so that the enemy gets into your territory more easily than you into his. This version is not complete. So you can
tell me your wishes by phone 58-86-08 in Samara, or write to *crazyzs@hotmail.com.* I will try to take everything
into account and will not forget to mention you. :)

Greetings, on the whole, I have nobody to send. Nobody knows me yet. Though... A big hello to M.M.A. and all the
Samara hackers - *Stars of Keladan.* And also *Omega Hackers Group, Flash inc., Fatality, Arsendancy,* and all who
have *WEB* pages on the Internet devoted to the *Speccy!*

*ZS. 23.12.1998.*

Press something...
