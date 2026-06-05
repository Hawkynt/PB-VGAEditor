# Agent guide — PB-VGAEditor

Working agreement for **all** coding agents (Claude Code, Codex, Copilot, …)
and human contributors working in this repository. These rules are not
optional. The full house spec lives in the `Hawkynt/project-template` repo
(`STANDARD.md`); this file is the per-repo distillation.

## What this is

A **PowerBASIC 3.5 (DOS)** mouse-driven sprite editor (`VGAMAUS.BAS` +
`.SUB` modules), companion to
[PB-SvgaLibrary](https://github.com/Hawkynt/PB-SvgaLibrary). The real compiler
only runs under DOS/DOSBox, so CI performs a structural syntax check instead
of a compile; the file-format round-trip test (`FileFormatRoundtrip.tst`)
runs under DOS and logs to `UNITTEST.LOG`.

## Commits

- **Group changes semantically/logically** — one concern per commit; one file
  format per commit when adding formats.
- **Every subject line starts with a prefix**:
  - `+` added feature/behavior
  - `-` removed feature/behavior
  - `*` changed behavior / public API
  - `#` bug fixed
  - `!` critical todo / open issue worth recording
- Never start a subject with "fix"/"bugfix"/"changed"/"modified" — the prefix
  already says it.
- **No AI traces anywhere**: no `Co-Authored-By` AI lines, no "Generated with"
  footers, no agent mentions in messages, comments, or authorship.

## The loop (always, in this order)

1. **Before committing**: run the structural check locally —
   `node .github/workflows/scripts/check-basic.mjs .` (exactly what CI runs).
   For file-format changes, run `FileFormatRoundtrip.tst` under DOSBox and
   check `UNITTEST.LOG`. Update README/CONTRIBUTING when formats or controls
   change.
2. **Commit** (rules above) and **push**.
3. **Wait for CI** and fix until green. A pushed change isn't done while the
   workflow it triggered is red.

## Syntax & style

- PowerBASIC 3.5 dialect: `BYVAL` parameters, `WORD`/`BYTE` types, `%CONST`
  equates, `FUNCTION = value` return assignment, `_` line continuation.
- **File formats follow [CONTRIBUTING.md](CONTRIBUTING.md) to the letter**:
  one `FILE_<EXT>.SUB` per format (DOS 8.3 names — extension ≤ 3 chars),
  exactly `File<Format>_Write` + `File<Format>_Read` with the
  `(fullPath AS STRING, errorMessage AS STRING)` signature.
- Four-space indentation inside blocks; guard clauses and early
  `EXIT SUB`/`EXIT FUNCTION` over deep nesting.
- Never make drawing/IO routines slower while refactoring.

## README & repo conventions

- Keep the standard frame: title (plain, no emoji) → badges → one-line `>`
  blockquote; standard sections use the fixed emoji mapping (`## ✨ Features`,
  `## 🚀 Usage`, `## 🖼️ Screenshots`, `## 🛠️ Building`, `## ❤️ Support`,
  `## 📜 License`); repo-specific sections keep consistent topical emojis.
- This is a **visual app** — keep `screenshot.png` (and the Screenshots
  section) up to date when the UI changes; capture via DOSBox.
- License is LGPL-3.0-or-later; the `## ❤️ Support` section and
  `.github/FUNDING.yml` stay intact.
