# trd-neart482-scroller

**What it is.** The scrolling text of the intro KIDSON of RAPEWARE CORP. put before their Russian version of Nether
Earth (December 1995): what the hack changes in the game, thanks and greetings. The intro scrolls it while it waits
for SPACE; then the game starts (`src/trd/neart482/intro.asm`).

**The file.** The TRD's file `Neart482`, inside its outer packed block: in the unpacked intro at `$78DC-$80E6`
(2059 characters, then a `$00` end mark, which the source adds), read from `$621A` and `$6221`. ASCII: the Russian
is written in Latin letters with the authors' own transliteration (below), English names in capitals. Build input:
[`src/res/text/trd-neart482-scroller.txt`](../../src/res/text/trd-neart482-scroller.txt), cut into lines at word
ends (every space is kept before the line's `|`), joined back by `tools/trd_text.py` in `tools/build_trd_extras.sh`.

The transliteration: `w` = в, `v` = ж, `^` = ч, `<` = ш, `>` = щ, `x` = ь, `` ` `` = э, `_` = ю, `q` = я, `y` = ы,
`j` = й, `h` = х, `c` = ц; the other letters as they look (a = а, b = б, ...).

## The original

As the intro holds it (one line; split here at the authors' runs of spaces, the leading 31 spaces and the trailing
11 shown as they are):

```text
                               priwet wsem poklonnikam zame^atelxnoj igry +NETHER EARTH+!
KIDSON oF RAPEWARE CORP. predlagaet wam ulu^<ennu_ wersi_ `toj igry.
tak ^to ve w nej osobennogo?,- sprosite wy.
a q otwe^u:
1. w igre neograni^ennoe kolli^estwo 'deneg'.
2. no, ^to by wam igra ne pokazalasx sli<kom prostoj, q sdelal tak, ^to wraveskie roboty wypuska_tsq na swoih bazah ne zawisimo ot togo, estx ili net u nih zahwa^ennye zawody.  pri^em wypuskaemye roboty o^enx dave ni^ego osna>eny!
3. no ne gor_jte, t.k. q e>e wwel wozmovnostx ustanowki na swoih robotow qdernoj bomby, nezawisimo ot togo, skolxko oruviq wy wyberite na swoego robota.
4. takve q uweli^il wsem robotam `nergi_ do 127!! a perwye tri robota woob>e neuqzwimy ( za iskl_^eniem qdernogo wzrywa ). ho^etsq otmetitx, ^to `ti tri robota 'stacionarno' programmiru_tsq na zahwat wraveskih baz! i ^to samoe interesnoe, esli odin iz `tih robotow pogibnet, to ego missi_ i neuqzwimostx perenimaet drugoj robot, kotoryj byl izgotowlen wsled za nim!
tak-^to igrajte, sravajtesx, razbiwajte gnusnyh insigniancew w swoe udowolxstwie!!!
ah-da!, ^utx ne zabyl!
5. w igre q ubral otgruzku i zagruzku otlovennoj igry, t.k. s^ita_, ^to `ta igra dolvna bytx projdena na odnom dyhanii! tak-^to w men_ igry klawi<a '5' movet bytx ispolxzowana kak 'START', a w igre klawi<a wygruzki ( byw<aq ) zamenena na klawi<u 'STOP' ( w principe `to to ve samoe, ^to i 'PAUSE'.
no w kompensaci_ za `to delo q isprawil opros klawi<i 'BREAK/SPACE' TAK ^TO MOvETE smelo wybiratx klawi<u 'SPACE', ne boqsx, ^to igra zawisnet!!!
nu sobstwenno ob igre i wse, ostaetsq tolxko poblagodaritx CHEMIST SOFT za ego diskowu_ ( 48/128k ) wersi_ igry, ona mne o^enx pomogla dlq raskrytiq nekotoryh sekretow `toj zame^atelxnoj igry!!!
na posledok nemnogo priwetow.
HELLO TO:
FLASH INC
PETER NOVAK
ALEX KISELEV
PRESTIGE
KSA
AIG
RED LTD
TAW
BLACK EAGLE
FFF
AND OTHERS...
BYE.....
(C)dekabrx 1995 KIDSON OF RAPEWARE CORP.
```

## In Cyrillic

```text
привет всем поклонникам замечательной игры +NETHER EARTH+!
KIDSON OF RAPEWARE CORP. предлагает вам улучшенную версию этой игры.
так что же в ней особенного?,- спросите вы.
а я отвечу:
1. в игре неограниченное колличество 'денег'.
2. но, что бы вам игра не показалась слишком простой, я сделал так, что вражеские роботы выпускаются на своих базах не зависимо от того, есть или нет у них захваченные заводы.  причем выпускаемые роботы очень даже ничего оснащены!
3. но не горюйте, т.к. я еще ввел возможность установки на своих роботов ядерной бомбы, независимо от того, сколько оружия вы выберите на своего робота.
4. также я увеличил всем роботам энергию до 127!! а первые три робота вообще неуязвимы ( за исключением ядерного взрыва ). хочется отметить, что эти три робота 'стационарно' программируются на захват вражеских баз! и что самое интересное, если один из этих роботов погибнет, то его миссию и неуязвимость перенимает другой робот, который был изготовлен вслед за ним!
так-что играйте, сражайтесь, разбивайте гнусных инсигнианцев в свое удовольствие!!!
ах-да!, чуть не забыл!
5. в игре я убрал отгрузку и загрузку отложенной игры, т.к. считаю, что эта игра должна быть пройдена на одном дыхании! так-что в меню игры клавиша '5' может быть использована как 'START', а в игре клавиша выгрузки ( бывшая ) заменена на клавишу 'STOP' ( в принципе это то же самое, что и 'PAUSE'.
но в компенсацию за это дело я исправил опрос клавиши 'BREAK/SPACE' ТАК ЧТО МОЖЕТЕ смело выбирать клавишу 'SPACE', не боясь, что игра зависнет!!!
ну собственно об игре и все, остается только поблагодарить CHEMIST SOFT за его дисковую ( 48/128k ) версию игры, она мне очень помогла для раскрытия некоторых секретов этой замечательной игры!!!
на последок немного приветов.
HELLO TO: FLASH INC, PETER NOVAK, ALEX KISELEV, PRESTIGE, KSA, AIG, RED LTD, TAW, BLACK EAGLE, FFF AND OTHERS...
BYE.....
(C)декабрь 1995 KIDSON OF RAPEWARE CORP.
```

The spelling is the author's ("колличество", "что бы", "не зависимо", "на последок"); "оF" in the original is a
lowercase Latin `o` before `F`, written `OF` here; the capitals "TAK ^TO MOvETE" are Russian too ("ТАК ЧТО МОЖЕТЕ").

## In English

```text
Greetings to all fans of the wonderful game +NETHER EARTH+!
KIDSON of RAPEWARE CORP. offers you an improved version of this game.
"So what is special about it?", you ask.
And I answer:
1. The game has an unlimited amount of "money".
2. But so that the game does not seem too easy to you, I made the enemy robots come out of their bases whether or
   not they have captured factories. And the robots they send out are quite well armed!
3. But don't despair: I have also added the option to fit your robots with a nuclear bomb, no matter how many
   weapons you choose for the robot.
4. I have also raised every robot's energy to 127!! And the first three robots are completely invulnerable (except
   to a nuclear blast). Note that these three robots are "permanently" programmed to capture enemy bases! And the
   most interesting part: if one of them dies, its mission and its invulnerability pass to another robot, the one
   built right after it!
So play, fight, smash the vile Insignians to your heart's content!!!
Oh yes!, I almost forgot!
5. I removed saving and loading a game in progress, because I think this game should be played through in one
   breath! So in the game's menu key "5" can be used as "START", and in the game the former save key is replaced
   by the "STOP" key (basically the same as "PAUSE").
But to make up for that I fixed the reading of the "BREAK/SPACE" key, SO YOU CAN boldly choose the "SPACE" key
without fear that the game will hang!!!
Well, that is really all about the game; it only remains to thank CHEMIST SOFT for their disk (48/128k) version of
the game, it helped me a lot to uncover some secrets of this wonderful game!!!
Finally, a few greetings.
HELLO TO: FLASH INC, PETER NOVAK, ALEX KISELEV, PRESTIGE, KSA, AIG, RED LTD, TAW, BLACK EAGLE, FFF AND OTHERS...
BYE.....
(C) December 1995 KIDSON OF RAPEWARE CORP.
```

The claims are the hacker's; this case does not check them against the inner game
(`src/res/trd/neart482/inner-61a8.bin`).
