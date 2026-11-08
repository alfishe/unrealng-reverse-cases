# lenslok-instructions

**What it is.** The sheet that came in the box with the Lenslok holder: "LENSLOK INSTRUCTIONS FOR USE", printed by
Firebird. There are two printings. The first has six numbered steps. The second has the same six steps reworded, two
photographs and a second round of attempts. The source is ZXDB / Spectrum Computing's `Elite_LenslokInstructions.pdf`
(two scanned pages, one per printing). It is in `work/extras/` and not committed, because the scan is not ours. The
text below was read from the scans; the PDF has no text layer. The text is English, so no translation is needed.

How the game does each step, and what the lens does to the picture, is in [lenslok.md](../lenslok.md). The notes
under each printing say where the code agrees with the sheet.

## The first printing

```text
                         LENSLOK INSTRUCTIONS FOR USE.

This quality program is protected by LENSLOK. Please read these instructions carefully before proceeding.

1)  Once the program has loaded, press 'ENTER', the screen will change and you will see three vertical lines
    appear on the screen - don't worry about anything else on the screen at this time.

2)  Place the UNFOLDED LENSLOK holder lengthways on the screen, between the two outermost vertical lines. Using the
    cursor keys '5' and '8', adjust the two outermost vertical lines until they are the same width as the LENSLOK
    holder.

3)  Fold the LENSLOK holder back, (as indicated on the holder) place the holder on the screen, (with 'TOP' on the
    holder, uppermost) and align the centre line of the lens with the vertical centre line on the screen. Now, by
    closing one eye and looking directly at the screen through the lens, you will see the letters 'O' and 'K'
    appear.

4)  If you are unable to see the letters clearly, use the adjustment keys to 'fine tune' the display until 'O' and
    'K' are seen more clearly.

5)  When you are satisfied that you can see the 'OK' message properly and whilst keeping the holder in the same
    position, press 'ENTER'.
    Two more characters will be displayed. Type these in and the protected program will run as normal.

6)  If, however you make a mistake, two more characters will be generated and you should type these two new
    characters in.
    You are allowed three attempts before the computer will reset, making it necessary to re-load the program.

LENSLOK IS A TRADEMARK OF A.S.A.P. DEVELOPMENTS.
```

**Notes.**

- Step 1 has the player press ENTER after the load. That is the ENTER the recording `c1` gives at frame 15700
  ([03-build-and-load.md](../03-build-and-load.md)). In the image, the size screen is drawn as soon as the Lenslok
  code starts.
- Steps 2 and 4: keys 5 and 8 move the two outer lines in and out. The width becomes the scale of the slices
  ([lenslok.md](../lenslok.md), 3.1).
- Steps 5 and 6: "OK" is drawn by ShowOK on the size screen. ENTER moves on to the attempt, and each attempt draws a
  new code. The three attempts are the counter `$C77E`, set to 4 and decremented before each attempt
  ([lenslok.md](../lenslok.md), 4.1).

## The second printing

```text
                         LENSLOK - INSTRUCTIONS FOR USE

This quality program is protected by LENSLOK. Please read these instructions carefully before proceeding.

1) Once the program has loaded, the screen will change and you will see three vertical lines appear on the screen
   - don't worry about anything else on the screen at this time.

2) Place the UNFOLDED LENSLOK holder lengthways on the screen, with the longside horizontal, between the two
   outermost vertical lines. Using the cursor keys '5' and '8', adjust the two outermost vertical lines until they
   are approximately 5mm either side of the LENSLOK holder.

3) Fold the LENSLOK holder so that it resembles a small 'table' with 'THIS SIDE OUT' written on its uppermost side.
   Stand the 'feet' of the holder on the television screen (see photograph 1), with the centre line of the lens in
   alignment with the vertical centre line on the screen. Now, by closing one eye and looking directly at the
   screen (sway your head slightly from side-to-side if necessary), you will see the letters 'O' and 'K' appear
   through the lens.

4) If you are unable to see the letters clearly, use the '5' and '8' keys to 'fine tune' the display until 'O' and
   'K' are seen more clearly. The 'O' will almost definately be clear, but the 'K' may take some adjusting before
   it is seen clearly.

5) When you are satisfied that you can see the 'OK' message properly and whilst keeping the holder in the same
   position, press 'ENTER'. Two more characters (letters or numbers) will be displayed. Type these in and the
   program will run as normal.

6) If, however you make a mistake, two more characters will be generated and you should type these two new
   characters in. You are allowed three attempts before the computer will return to the initial size adjustment
   screen, allowing you to obtain the correct size (instruction 2) you are then allowed 3 more attempts before the
   computer will reset making it necessary to reload the program.
```

The page has two photographs beside steps 3 and 4. In the first, a player looks through the folded holder standing
on a television, with the caption "Head at least one foot away". The second is a close view of the lens on the
screen, with the "OK" seen through it.

**Notes.**

- Step 1 no longer asks for ENTER. The image agrees: the size screen comes up with no key.
- Step 6 matches the code of this image. `Lenslok` `$C213` runs two rounds, each a size screen and up to three
  attempts, and only then resets ([lenslok.md](../lenslok.md), 4.1). The first printing describes one round.
- Step 5's "letters or numbers": the generator draws digits, upper-case and lower-case letters
  ([lenslok.md](../lenslok.md), 4.2). The live codes were "si", "60", "yo", "AV" and "Ns".
- "The 'K' may take some adjusting": the model in [lenslok.md](../lenslok.md) (3.4) shows a lens one pixel out of
  place already cutting strokes, because the narrowest slice is 3 pixels wide. Why K suffers more than O is not
  measured here.
