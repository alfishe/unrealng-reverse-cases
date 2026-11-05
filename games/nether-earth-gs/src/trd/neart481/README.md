# src/trd/neart481: the TRD's file Neart481

A 128K Nether Earth whose packed data names it "ASM COMPILATION OF ROBOT WARS/FACTORIES/ALIENS" (no author named on
the disk). `neart481.asm` is the whole file, 171 sectors: the BASIC program with its loader, and six blocks kept as
bytes (`src/res/trd/neart481/`).

| Part | Sectors | Load | What |
| --- | --- | --- | --- |
| BASIC | 0-2 | `$5D3B` | line 1 REM: `Loader` (`$5D40`) and its helpers (`LoadBlock` `$5DC3`, `DriveReset` `$5DD4`, `RomCall` `$5E0E`, `TrappedCall` `$5E13`, `Trap` `$5E29`, `FadeAttributes` `$5E2E`); lines 10-42; autostart line 10; 192 bytes of old memory |
| `ScreenBlock` | 3-14 | `$7530`, bank 0 paged | its own code: finds its address, JP stubs at `$5C94-$5C9B`, the loading screen unpacked to `$4000` |
| `Bank6Block` | 15-59 | bank 6 `$C000` | packed, unpacks in place; holds `SAMPLE_PLAYER` `$FDEC` (line 41, USR 65004: an AY sample player) |
| `Bank3Block` | 60-74 | bank 3 `$C000` | packed; holds `TITLE_TUNE` `$E1C8` (line 40, USR 57800: the tune until SPACE) |
| `Bank4Block` | 75-84 | bank 4 `$C000` | packed; its use by the game not traced |
| `Bank1Block` | 85-98 | bank 1 `$C000` | packed; its use by the game not traced |
| `GameBlock` | 99-170 | `$61A8`, bank 0 paged | packed: the game, `GAME_START` `$A600` (line 42, USR 42496) |

The flow: line 10 `CLEAR 24999`; line 20 `RANDOMIZE USR 23872` runs `Loader`, which reads each block (TR-DOS
function 5 from the next sector on), calls it (the five packed ones unpack themselves in place and return), runs
`DriveReset` and returns to BASIC through STMT-RET at the next statement: line 39 zeroes `$C4FF-$C501`, line 40
pages bank 3 and plays the title tune, 41 pages bank 6 and calls the sample player, 42 pages bank 0, fades the
screen (`FadeAttributes`, USR 24110) and starts the game.

**The packer.** The five packed blocks share one self-extractor: DI, the caller's SP into the depacker, the 192-byte
depacker copied to `$5B00` and entered by RET, the stream moved up with LDDR, bits read by POP from 16-bit words,
offsets coded as Hrust 1 codes them (3, 4, 5, 6-bit prefixes: v+1, v-1, v-9, v&31), the last 5 bytes in the
depacker's tail, EI, RET. By the code it is Hrust 1 (Dmitry Pyankov) in its self-extracting form; nothing on the
disk names it and the signature base has no entry. No unpacker / packer for this form is written yet, so the blocks
stay as bytes (`work/stage2/NOTES-trd.md`).

**Open.** A run in the emulator (Pentagon 128 + GS) ended at PC `$0048` with interrupts off after the title tune;
the stage 1 run saw a loop at `$386E`. Why is not known (the file may expect another 128K machine).
