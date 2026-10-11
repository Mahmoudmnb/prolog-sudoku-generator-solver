# Refactor Notes

## Summary

The repository was reorganized for readability and portfolio presentation while preserving the original educational Prolog implementation. Source files now live in `src/`, sample puzzles live in `examples/`, and reports/screenshots live in `docs/`.

## Original Structure

The repository originally stored all project files in the root directory:

- `solve.pl`
- `sudoku.pl`
- `easy.pl`, `meduim.pl`, `hard.pl`, `veryHard.pl`, `input.pl`, `input1.pl`
- Screenshot PNG files in the root directory
- PDF/DOCX academic reports in the root directory

## New Structure

- `src/sudoku_solver.pl`
- `src/sudoku_generator.pl`
- `examples/easy.pl`
- `examples/medium.pl`
- `examples/hard.pl`
- `examples/very_hard.pl`
- `examples/input.pl`
- `examples/input1.pl`
- `docs/images/*.png`
- `docs/*.pdf`
- `docs/*.docx`
- `.gitignore`
- `README.md`
- `REFACTOR_NOTES.md`

## Files Renamed

- `solve.pl` -> `src/sudoku_solver.pl`
- `sudoku.pl` -> `src/sudoku_generator.pl`
- `meduim.pl` -> `examples/medium.pl`
- `meduim.png` -> `docs/images/medium.png`
- `veryHard.pl` -> `examples/very_hard.pl`
- `veryHard.png` -> `docs/images/very_hard.png`

## Files Moved

- Sample puzzle files were moved to `examples/`.
- Screenshot images were moved to `docs/images/`.
- `Aleppo University.docx`, `Aleppo University.pdf`, `Sudoku_Creation_and_Grading.pdf`, and `solve_sudoku.pdf` were moved to `docs/`.

## Predicate Naming Improvements

No internal predicates were renamed. The solver and generator use many mutually dependent predicates with cuts, dynamic `assert/1` and `retract/1`, and direct predicate calls from the generator into the solver. To avoid behavior risk, predicate names were preserved.

The filename spelling/case issues were corrected instead:

- `meduim` -> `medium`
- `veryHard` -> `very_hard`

## Documentation Improvements

- Added concise headers to `src/sudoku_solver.pl` and `src/sudoku_generator.pl`.
- Clarified the `cell/4` board representation.
- Documented the candidate representation.
- Documented solving stages: candidate initialization, single-candidate propagation, pair elimination, uniqueness checks, and repeated scan passes.
- Documented row, column, and square validation in the generator.
- Documented generation flow.
- Added a minimal `README.md` with current load paths.

## Behavior Preservation

- Sudoku solving logic was not intentionally changed.
- Candidate elimination behavior was not intentionally changed.
- Pair/uniqueness strategies were not intentionally changed.
- Sudoku generation logic was not intentionally changed.
- Random generation behavior was not intentionally changed.
- Puzzle difficulty behavior was not intentionally changed.
- Sample puzzle contents were not changed.

The only source-level behavior-adjacent change is that `src/sudoku_generator.pl` now explicitly loads `src/sudoku_solver.pl`, because it already depended on solver predicates such as `solvePuzzle/1`, `isEqual/2`, and the project-local `append/3`.

Pre-move and post-move hashes matched for all sample puzzle files, screenshots, and report documents.

## Validation Performed

Prolog runtime detection:

- `swipl --version` failed: `swipl` was not found.
- `command -v swipl` returned no runtime.
- `command -v prolog` returned no runtime.
- `command -v gprolog` returned no runtime.

Commands attempted:

```sh
swipl --version
command -v swipl
command -v prolog
command -v gprolog
swipl -q -t halt -s src/sudoku_solver.pl
```

Because no Prolog runtime is available in this environment, syntax/load validation could not be executed here.

Repository/file checks performed:

```sh
git diff --check
sha256sum examples/*.pl docs/images/*.png docs/*.pdf docs/*.docx
rg -n "meduim|veryHard|solve\\.pl|sudoku\\.pl" . -g '!.git/**'
```

`git diff --check` completed without whitespace errors. The final filename search only found expected historical references inside this notes file.

Recommended validation when SWI-Prolog is available:

```sh
swipl -q -t halt -s src/sudoku_solver.pl
swipl -q -t halt -s src/sudoku_generator.pl
swipl -q -s src/sudoku_solver.pl -s examples/easy.pl -g "solvePuzzle(R),writeln(R),halt."
```

## Potential Issues Not Changed

- `src/sudoku_solver.pl` defines a custom `append/3`, which overlaps with the common Prolog built-in/library predicate. This was preserved because the solver and generator already rely on this local definition, and renaming it would require broad changes.
- `src/sudoku_solver.pl` and `src/sudoku_generator.pl` use `not/1`. Some Prolog systems prefer `\+/1`. This was preserved to avoid changing the original style and portability assumptions.
- `src/sudoku_generator.pl` uses `fillPuzzle()` and `createPuzzle()` syntax. This may be implementation-specific in some Prolog systems. It was preserved because changing it could alter the public predicates users currently call.
- The project relies on dynamic global `cell/4` facts with `assert/1` and `retract/1`. This is order-sensitive and can leave state in the Prolog session if users load multiple samples without clearing existing cells. This was preserved because it is central to the original implementation.
- The solver may be incomplete for puzzles requiring strategies beyond the implemented candidate, pair, and uniqueness passes. This was preserved because replacing the strategy would violate the educational refactor constraint.
- The generator's difficulty behavior is tied to removing cells while checking solvability with the current solver, not to a rigorous difficulty metric. This was preserved.
- Several predicates use cuts and fail-by-arithmetic patterns such as `1=:=2`. These are unusual but were preserved because they may affect backtracking behavior.

## Remaining Technical Debt

- Add runtime validation once SWI-Prolog is installed.
- Consider adding a safe `clearPuzzle/0` helper in a future behavior-changing cleanup so sample loads do not accidentally mix `cell/4` facts.
- Consider modernizing predicate names in a future pass with compatibility wrappers and regression tests.
- Consider replacing implementation-specific zero-argument call syntax only after confirming the target Prolog runtime and expected public API.
