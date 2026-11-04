# 03. Stages and packers

**Answers:** what each stage on the medium does, where its code arrives, and how packed data was made.

1. Build L1 over the whole power-on recording, then `re_session.py stages --work W`: the code arrivals (a loader in
   a REM, a screen unpacker, a depacker, the game), each with the window to build it in.
2. Build each stage in its own window (`re_session.py build --stage N --into W/<stage>`). Data reads in a window
   where an unpacker reads its input over the addresses the game later runs from say nothing about the game: take
   the game's data reads only from windows after the unpack.
3. For each packer: reimplement the unpacker in Python (`tools/depack.py`) and check its output against the
   recording's memory at the moment the unpacker returns (0 bytes differ); then write the packer
   (`tools/pack.py`) whose output is the medium's bytes, identical. Find the packer's rules from the tokens of the
   stream (run lengths, escapes, the order of choices), not by guessing a known packer.
4. Animate each unpack (`kit/memanim.py --from F:T --to F:T --step T`, `--screen-geometry` for the screen page): it
   goes in doc 3.
5. Each loader stage gets its source (`src/loader.asm`, `src/screen.asm`...) assembled with sjasmplus to the
   medium's bytes.

**Done when:** `tools/build.sh` writes the medium bit for bit, with the game image still unpacked from the original
(the source of the game replaces it in recipe 05).
