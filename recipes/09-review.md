# 09. Review

**Answers:** is what the documents say true?

1. A review round is an agent that has not seen the case's work: give it the documents (or a part), the ground
   truth (the listing, `src/`, `orig/`, the tools) and ask for a numbered report, each finding with the claim, the
   evidence and a fix, marked VERIFIED or SUSPECTED. Read-only.
2. Check every finding yourself before editing: against the listing, the medium's bytes, or the recording (open it,
   read memory at the frames in question). A reviewer can be wrong (H.A.T.E.'s fourth round: one of 31 findings
   was not).
3. Fix in the annotation, the documents and the tools; regenerate (`mkgame.py`, `refdocs.py`); build; `check_docs`.
4. Add a WALKTHROUGH section for the round: what was asked, what was found, by kind.
5. At least two rounds, the second on what the first did not read. Then the figures checklist again.

**Done when:** a round finds nothing factual, and the case README's state says so.
