# Work discipline (lightweight, always-on)

For substantial work (features, refactors, multi-file changes, must-be-right deliverables):

- **Plan before code.** State the requirement and a one-line, machine-checkable acceptance *before* implementing.
- **"Done" = acceptance passed.** Run it and keep the real output as evidence — not "looks right".
- **Self-check critical output** before shipping (have it refuted / falsified, not just re-read).
- **Run the real product end-to-end** at milestones; keep evidence (logs, test output).
- **Don't stop mid-task** with unfinished work — either finish it, or say explicitly what blocks you. A finished, verified task is not mid-task: after the closing summary, idle turns (empty input / bare acknowledgment / "continue" with nothing left) get at most one short line, never repeated status filler.
- **When stuck after repeated failures**, attribute cheapest-layer-first: harness (the test) → deployment (is the new code actually running?) → product. Don't flail.
