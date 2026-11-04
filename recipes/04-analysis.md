# 04. Analysis

**Answers:** what every byte of the game is: code, data and which kind, who reads and writes it.

1. `re_session.py build --from-frame F --from-tinframe T --into work/game` over the game's window, and the same
   over each bot recording. `re_session.py interrupts` gives the interrupt handlers.
2. Work the review queue (`re_session.py call --work W review '{"op":"next"}'`): at most 40 items a page, a fact
   sheet each; resolve through `review resolve`, never edit the draft.
3. Every unknown left outside the ROM is read against the replay: what is it, why did no detector name it, which
   generic rule would. Each rule goes into unreal-ng with a fixture and a test that fails without it (worktree,
   build, filtered tests, land), then the case is built again. The WALKTHROUGH's tool-gap table gets a row: gap,
   seen as, fix (with the test names), the effect on the case.
4. The gates after each round: `re_session.py check --work W --venv SKOOLKIT_VENV --sjasmplus SJASMPLUS` (rebuild
   and assemble give the image byte for byte).

**Done when:** no unknown outside the ROM is left unexplained, the gates pass, the bugs left are understood (an
overlay of code by a buffer is a finding, not an error).
