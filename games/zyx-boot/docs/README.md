# ZYX boot: the documents

| Doc | Contents |
| --- | --- |
| [1. What you see](01-overview.md) | what the boot is for, the screen and its parts, every screen from the set-up to the launch, what the user can do |
| [2. Architecture](02-architecture.md) | the machine budget, the memory map (a figure), stages from the medium to play, the frame, the main loop's call graph, the module map |
| [3. Build and load](03-build-and-load.md) | the disk and its one file, the BASIC program and the loader in its REM, how the three pieces reach memory, how the menu runs a file, the source build |
| [4. The program cycle](04-program-cycle.md) | the entry and the set-up, the IM 2 table, the main loop with no wait, the interrupt and its 256-frame cycle, the cost per frame, every timer |
| [5. The keys](05-keys.md) | ReadKeyboard every 8th frame, the letter keys, the two Sinclair joysticks, the cursor, the silenced Kempston read, SPACE, CS, SS |
| [6. The graphics](06-graphics.md) | PrintSprite and the logo, the reflection, the 34 rhombus phases, the star field, the twinkle, the glint, the corner colours, ScreenCopy |
| [7. The catalogue and the menu](07-catalogue-and-menu.md) | the TR-DOS catalogue read, which files are listed (B, and C of exactly 192 sectors, never boot), the count and the three layouts, the catalogue line, the pages (SYMBOL SHIFT, CAPS SHIFT), ShowCatalogue and its 8-frame cost, NO EXE FILES ! |
| [8. The font and the text](08-font-and-text.md) | PrintString through RST `$10`, the font, the help texts, EntryLine and the menu layout, the name spin |
| [9. Music and sound](09-music-and-sound.md) | the AY and its three writers, the ASC Sound Master player routine by routine, the module format with pattern 0 decoded by hand, samples and ornaments, the registers a frame, the tune (7704 frames, then 7764 a tune loop), SoundOff and the bell, the audio files |
| [10. The launcher and notes](10-launcher-and-notes.md) | from a key to the program: RunLetter's walk and the BASIC line it writes, FireKey, what is put back (SP, IY, HL', I, CHARS, FRAMES, IM 1), the bell and ExitFade, the loader's end and TR-DOS; the self-modifying code, tricks and quirks |
| [11. Data reference](11-data-reference.md) | every data entry (generated: `kit/refdocs.py --case .`) |
| [12. Routine reference](12-routine-reference.md) | every routine with its figures (generated) |
| [13. Variants](13-variants.md) | the 56 boots built on this menu: the family tree, all 56 in a table, the menus side by side, logos and rhombi, layout B and the code switches with their asm, the own loaders, the players and tunes with an MP3 each, the three hardest (packed, encrypted, rewritten) |

## Terms

Each term once, here; the documents link to it.

| Term | Meaning |
| --- | --- |
| deleted mark | a first byte 1 in a catalogue entry: a deleted file, or an entry RunLetter has walked past |
| EntryLine | `$B3CE`, the 22-byte RST `$10` line PrintColumn builds for each name |
| frame | 1/50 s, 71 680 T on the Pentagon; one interrupt |
| Frames | the ROM's FRAMES `$5C78`, + 1 per interrupt, set to 0 by every page draw; its low byte times the glint, the spin, the cursor colour and the keys |
| glint | the two red diagonals that cross the logo or its reflection on Frames 0-54 (LogoGlint `$6D04`) |
| near / far stars | StarsA + StarsB (10 stars of 2 x 2 pixels, 1 row a pass) / StarsC (20 of 1 pixel, a quarter row a pass) |
| pass | one run of the main loop, MainLoop `$627C`; about 2.2 a frame in the idle menu. ExitFade's 8 passes over the screen are its own (doc 10); the tune's is a tune loop |
| phase | one of the 17 precomputed pictures of a turning rhombus (0-7 narrowing, 8 empty, 9-16 mirrored); a turn shows 32 steps from them through PhaseOrder |
| position | one entry of the tune's position list: the pattern played there |
| row frame | a frame on which the player's DelayCounter runs out (every 6th): the channels may read their next events |
| ScreenCopy | `$E000-$FAFF`, the clean screen the twinkle, the glint and the spin restore from or work in |
| snapshot (Magic file) | a CODE file of exactly 192 sectors: a 48K image saved with the Beta Disk's Magic button; the menu lists it and runs it with GO TO "name" CODE |
| spin | the cursor's text turned a quarter per cell at Frames 50, 60, 70, 80 (RotateCursorName `$67C2`) |
| step | the index 0-31 of a rhombus in its turn (PhaseTopLeft etc.) |
| tune loop | the tune from position 0 to the next start of position 0: 7704 frames from MusicInit, 7764 every later time |
| twinkle | the 16 x 16 star that grows and shrinks in a random place (TwinkleStar `$6BA5`), 39 frames a twinkle |
