# Briefs: the templates

The lead gives each agent one brief and a short prompt (its id, its port base, its share of the work). These are
the templates, distilled from the briefs the nine cases ran with. After `cp -R kit/case-template games/<game>`, move
this folder into the git-ignored `work/` (`mv games/<game>/briefs games/<game>/work/briefs`), copy the brief a stage
needs next to its output (`work/stage1/BRIEF.md`, `work/docs/BRIEF.md`) and fill in every `<...>`.
[recipes/11-agents.md](../../../recipes/11-agents.md) says who gets which and how they share the machine.

| Brief | Stage | Agents | Came from |
| --- | --- | --- | --- |
| [stage1.md](stage1.md) | 1: the medium, the load, the images, a first play | 1 | advanced-nether-earth `work/BRIEF.md` |
| [stage2.md](stage2.md) | 2: the source, bit-exact, one agent | 1 | advanced-nether-earth `work/stage2`, `work/stage3/BRIEF-SOURCE.md` |
| [stage2-parts.md](stage2-parts.md) | 2: the source, one agent per part | 1 per part | nether-earth-zs-edition `work/stage2/BRIEF.md` |
| [ann-fragments.md](ann-fragments.md) | 2, one big image: annotation fragments by address range | 5-6 | nether-earth `work/ann/BRIEF*.md` |
| [figures.md](figures.md) | the figure rule (every docs brief cites it), a figure audit | any | nether-earth `work/ann/BRIEF-FIG.md` |
| [docs.md](docs.md) | docs 01-12 | 2 (A: 01-06, B: 07-12) | zynaps-gs `work/docs/BRIEF.md` and its siblings |
| [editor.md](editor.md) | the editor pass: docs/README.md, contradictions, `.ann` fixes | the lead or 1 | recipe 11 section 3 |
| [doc13.md](doc13.md) | doc 13 of a derived case, after the full reverse | the lead or 1 | recipe 10 step 8, the cases' doc 13 |

Every brief keeps the same frame: who `R`, `C` and the base `B` are; why (what is missing, measured against the
bar); the standard; the inputs; the rules (own instances, own files, no commits); the output and the report. No
path of one machine goes into a brief: name the tools by `$UNREAL_NG`, `$SJASMPLUS`, `$SKOOLKIT_VENV`
([docs/case-files.md 10](../../../docs/case-files.md#10-the-unreal-ng-side-and-the-tools)).
