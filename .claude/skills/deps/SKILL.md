---
name: deps
description: Triages the open Dependabot PR queue — classifies each bump, checks CI and intentional pins, merges the safe ones and reports what needs a human decision
---

# Deps Skill

Works through the open Dependabot pull requests on `reckoning/reckoning`. Merges the grouped patch/minor bumps whose CI is green, and stops with a recommendation for everything else.

## When to Use

- "triage the deps", "deal with the dependabot PRs", "merge the safe dependency updates"
- Dependabot runs **weekly** (10 bundler / 5 npm / 5 github-actions).

## Repo facts

This repo's Dependabot config differs from the other repos in a way that changes the whole triage, so read this section before starting.

- **Patch and minor bumps are grouped by update-type.** `.github/dependabot.yml` defines `bundler-patch-and-minor`, `npm-patch-and-minor`, and `github-actions-all` (patterns `*`). Consequences:
  - A grouped PR is titled `bump the <group> group with N updates` and carries **no version numbers in the title**. Do not try to parse semver from it.
  - A grouped patch/minor PR is **non-major by construction** — the group is defined by `update-types: [patch, minor]`, so membership is the semver check. That is the single biggest shortcut in this repo.
  - Majors arrive as **individual, ungrouped PRs**. Any Dependabot PR here whose title names one package is therefore a major and needs a human.
  - `github-actions-all` groups by pattern, not update-type, so it **can** contain majors. Check its body.
- **`typescript` majors are ignored** in `dependabot.yml`, with a comment: TS7 moved the compiler into a native binary and reduced the main export to a version string, so `vue-tsc` cannot run on it. Drop the ignore once Volar targets `typescript/unstable/*`. You will never see a TS major PR here — that is intentional, not an oversight.
- **Squash only** (`mergeCommitAllowed: false`). Branches are deleted on merge. Auto-merge is enabled.
- `main` uses **classic branch protection** (not a ruleset, unlike the infrastructure repos) with `strict: true` — every PR must be **up to date with `main`** before it can merge. Required checks:

  ```
  ruby-lint / ruby-lint
  ruby-tests / ruby-tests (4, 0)   … (4, 1) … (4, 2) … (4, 3)
  seeds / seeds
  e2e-tests / e2e-tests
  ```

  `strict: true` is the operational headache: **every merge invalidates every other open PR.** Plan for it in step 4.
- `allow_update_branch` is **disabled**, so there is no "Update branch" button — restacking goes through `@dependabot rebase`.
- PR titles are conventional commits and become the squash subject. Never rewrite the title on merge.

---

## Workflow

### 1. Pull the queue

```bash
gh pr list --repo reckoning/reckoning --label dependencies --limit 50 \
  --json number,title,labels,mergeStateStatus \
  --jq '.[] | "\(.number)\t\(.mergeStateStatus)\t\(.title)"'
```

If the queue is empty, say so and stop.

### 2. Classify each PR

| Title shape | Class |
|-------------|-------|
| `bump the bundler-patch-and-minor group …` | patch/minor by construction |
| `bump the npm-patch-and-minor group …` | patch/minor by construction |
| `bump the github-actions-all group …` | read the body — may contain majors |
| `bump <one-package> from <old> to <new>` | **major** (ungrouped means it escaped the patch/minor group) |

Confirm rather than assume: read the body of a grouped PR to see the package list.

```bash
gh pr view <number> --repo reckoning/reckoning --json body --jq .body | head -40
```

For an ungrouped PR, apply the usual rules — and remember `old.major == 0` with a changed minor is a major too.

### 3. Run the safety gates

#### Gate A — bump class is patch or minor

Grouped patch/minor PRs pass. Ungrouped PRs are majors and go to the report.

A grouped PR is only as safe as its widest member, so if the body reveals something surprising in a patch/minor group (a package doing a breaking change inside a minor), treat it as held.

#### Gate B — CI is green

A check that never reported is not a passing check, so the gate has to assert the required contexts are *present* as well as successful — filtering the rollup for failures alone returns empty output when a workflow has not been queued yet.

```bash
gh pr view <number> --repo reckoning/reckoning \
  --json statusCheckRollup \
  --jq '
    ["ruby-lint / ruby-lint",
     "ruby-tests / ruby-tests (4, 0)", "ruby-tests / ruby-tests (4, 1)",
     "ruby-tests / ruby-tests (4, 2)", "ruby-tests / ruby-tests (4, 3)",
     "seeds / seeds", "e2e-tests / e2e-tests"] as $required
    | [.statusCheckRollup[] | select(.name != null)] as $checks
    | (($required - [$checks[].name]) | map("\(.): MISSING"))
      + [$checks[]
         | select(.conclusion != "SUCCESS" and .conclusion != "SKIPPED" and .conclusion != "NEUTRAL")
         | "\(.name): \(.conclusion // .status)"]
    | .[]'
```

Empty output means green: every required context reported, none of them failing or still running.

- `MISSING` → the check has not been created yet. Not a failure and not a pass — re-poll, and if it never appears, the workflow did not trigger and the PR needs a `@dependabot rebase` rather than a merge.
- A conclusion of `null` shows up as its status (`QUEUED`, `IN_PROGRESS`) — also not green.

All four `ruby-tests` shards are required — do not accept three of four, and do not accept three plus one `MISSING`.

#### Gate C — no intentional pin is being undone

For **bundler** PRs, check whether `Gemfile` itself changed:

```bash
gh pr diff <number> --repo reckoning/reckoning | grep -E '^(diff --git|[-+]gem )'
```

- Only `Gemfile.lock` changed → fine.
- A `gem` line tightening `"~> 4.0"` → `"~> 4.1"` → fine.
- An **upper bound removed or loosened** → stop and read the comment above the pin:

  ```bash
  grep -B4 'gem "<name>"' Gemfile   # unanchored: gems inside group blocks are indented
  ```

For **npm** PRs, a `package.json` change is expected on every bump. Look for an **exact** version (no `^`/`~`) — an exact pin is deliberate.

Known exact pin at the time of writing:

- **`pdfjs-dist` is pinned to `4.10.38`.** It was deliberately migrated 3.11 → 4.10 to run through Vite and close 13 high-severity vulnerabilities (`feat(deps): migrate pdfjs-dist 3.11 → 4.10 via Vite`). The worker setup is coupled to that major, so a bump to 6.x is not a version change but a second migration. Hold it.

Check `git log` for a prior manual pin or revert:

```bash
git log --oneline -5 --grep="<package-name>"
```

#### Gate D — mergeable state

`UNKNOWN` is common here — GitHub is still computing mergeability. Re-poll before deciding; do not treat it as a failure.

`BEHIND` blocks the merge outright because of `strict: true`. Restack it:

```bash
gh pr comment <number> --repo reckoning/reckoning --body "@dependabot rebase"
```

`DIRTY` (conflicting) → `@dependabot recreate`.

### 4. Merge the safe ones — one at a time

`strict: true` plus no merge queue means the queue must be **serialized**: merging one PR makes every other open PR out of date, and each rebase triggers a fresh CI run (including e2e).

The practical approach:

1. Pick the highest-value safe PR — normally the grouped `bundler-patch-and-minor` or `npm-patch-and-minor`, since one merge lands many packages.
2. Merge it. Auto-merge is enabled, so if checks are still running you can queue it:

   ```bash
   gh pr merge <number> --repo reckoning/reckoning --squash --auto
   ```

   Otherwise plain `--squash`.
3. Post `@dependabot rebase` on the remaining safe PRs.
4. **Stop there.** Do not wait out a full rebase-and-CI cycle for each remaining PR — tell the user what is pending and let them re-run the skill once CI has caught up.

Merging two or three grouped PRs per run is a good outcome in this repo. Do not try to drain the queue in one pass.

### 5. Report

```
Merged / queued (N)
  #957  grouped  ruby  bundler-patch-and-minor — 5 updates

Held — needs a decision (N)
  #952  major  ruby  active_storage_validations 3.0.5 → 4.0.0
  #946  major  js    pdfjs-dist 4.10.38 → 6.2.108
        Exact pin. 4.10 was a deliberate Vite migration that closed 13 high-sev
        vulns; the worker setup is coupled to that major. Two-major jump.

Rebasing — restacked after the merge, re-run once CI is green (N)
  #956  grouped  js  npm-patch-and-minor — 3 updates
```

For grouped PRs, list the packages so the user can see what actually landed. For each held major, say *why* in one line and what would unblock it.

Do not merge anything in the held list without the user saying so.

---

## Error Handling

- **`gh` not authenticated** → tell the user to run `gh auth login` and stop.
- **Merge rejected as out of date** → expected under `strict: true`; post `@dependabot rebase` and move on.
- **Merge rejected** for any other reason → report it, leave the PR open, continue with the rest.
- **e2e flake** → do not merge; offer `gh run rerun <run-id> --failed` and re-check.
