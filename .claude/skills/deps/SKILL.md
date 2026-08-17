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
- **Squash only** (`mergeCommitAllowed: false`). Branches are deleted on merge.
- **`main` has a merge queue.** This is the fact that shapes step 4, and it postdates the first version of this skill — do not carry over advice about serializing merges by hand.

  ```
  mergeMethod: SQUASH        mergingStrategy: ALLGREEN
  maximumEntriesToBuild: 5   maximumEntriesToMerge: 5
  ```

  The queue rebases each entry onto the tip and runs the required checks itself, so **merging one PR no longer invalidates the others** — enqueue every safe PR in one pass.
- `main` also uses **classic branch protection** (not a ruleset, unlike the infrastructure repos) with `strict: true`. Required checks:

  ```
  ruby-lint / ruby-lint
  ruby-tests / ruby-tests (4, 0)   … (4, 1) … (4, 2) … (4, 3)
  seeds / seeds
  e2e-tests / e2e-tests
  ```

  `strict: true` is still set, but the merge queue now absorbs it. It only bites for a PR you merge outside the queue.
- `allow_update_branch` is **disabled**, so there is no "Update branch" button. Restacking goes through `@dependabot rebase` — but with the queue in place you rarely need it.
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
gh api repos/reckoning/reckoning/pulls/<number>/files --paginate \
  --jq '.[] | "\(.status)\t\(.filename)"' | grep -v vendor/cache
```

Use the files API, not `gh pr diff`. Gems are vendored into `vendor/cache/*.gem`, so a bundler diff contains binary blobs and `gh pr diff` refuses with *"the diff contains terminal escape sequences"* — the grep never runs and you get no signal either way. The files listing sidesteps it.

If `Gemfile` is in the list, read what changed in it:

```bash
gh api repos/reckoning/reckoning/pulls/<number>/files --paginate \
  --jq '.[] | select(.filename == "Gemfile") | .patch'
```

- Only `Gemfile.lock` changed → fine. Note this says nothing about the bump class: most gems here are declared unversioned (`gem "active_storage_validations"`), so a **major** also lands with no `Gemfile` change. Gate A classifies; Gate C only asks whether a pin was undone.
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

`UNKNOWN` is common here — GitHub is still computing mergeability. Re-poll before deciding; do not treat it as a failure. A freshly listed queue is often all `UNKNOWN`; one re-poll usually settles it to `CLEAN`.

`BEHIND` is **not** a blocker any more — the merge queue rebases the entry itself. Enqueue it.

`DIRTY` (conflicting) → the queue cannot fix a conflict. `@dependabot recreate`.

### 4. Enqueue the safe ones

The merge queue serializes for you: it rebases each entry onto the tip, runs the required checks, and merges in order. So enqueue **every** safe PR in one pass — there is no need to merge one and `@dependabot rebase` the rest.

```bash
gh pr merge <number> --repo reckoning/reckoning
```

Pass **no merge-method flag**. With a queue configured, `--squash` / `--merge` / `--rebase` make `gh` print:

```
! The merge strategy for main is set by the merge queue
```

That line is a **notice, not an error** — `gh` exits non-zero but the PR *is* enqueued. Do not retry on seeing it. Confirm the real state rather than trusting the exit code:

```bash
gh api graphql -f query='
{
  repository(owner: "reckoning", name: "reckoning") {
    mergeQueue(branch: "main") {
      entries(first: 10) { nodes { position state pullRequest { number } } }
    }
  }
}' --jq '.data.repository.mergeQueue.entries.nodes[]
         | "\(.position) \(.state) #\(.pullRequest.number)"'
```

`AWAITING_CHECKS` / `QUEUED` both mean successfully enqueued.

The queue caps at **5 entries**; beyond that, enqueue the highest-value PRs first (the grouped ones, since one entry lands many packages) and leave the rest for the next run.

**Then stop.** Do not wait out the queue — it takes a full CI cycle per entry including e2e. Report what is enqueued and let the user check back. An entry can still fail its queue build and get ejected; that is normal and shows up as a fresh open PR on the next run.

### 5. Report

```
Queued to merge (N)
  #965  grouped  ruby  bundler-patch-and-minor — 7 updates
        stripe 19.4.0→19.5.0, sentry-{ruby,rails,sidekiq} 6.6.2→6.7.0,
        bootsnap 1.24.6→1.25.0, simplecov 1.0.3→1.1.0, …
  #964  grouped  js    npm-patch-and-minor — 4 updates
        vite 8.2.0→8.2.1, vue 3.5.40→3.5.41, puppeteer 25.5.0→25.6.0, …

Held — needs a decision (N)
  #946  major  js    pdfjs-dist 4.10.38 → 6.2.108
        Exact pin. 4.10 was a deliberate Vite migration that closed 13 high-sev
        vulns; the worker setup is coupled to that major. Two-major jump.
```

For grouped PRs, list the packages so the user can see what actually landed. For each held major, say *why* in one line and what would unblock it.

For a held major, do the legwork that makes the decision cheap — grep for the call sites and read the breaking-change list, then say how exposed this repo actually is. A major with one call site and an irrelevant breaking change is a different proposition from a coupled migration, and the user can only tell if you check. Still do not merge it unprompted.

Do not merge anything in the held list without the user saying so.

---

## Error Handling

- **`gh` not authenticated** → tell the user to run `gh auth login` and stop.
- **`! The merge strategy for main is set by the merge queue`** → not an error. The PR was enqueued; `gh` is only telling you it ignored your merge-method flag. Verify with the queue query in step 4 and move on. Drop the flag next time.
- **`gh pr diff` refuses over terminal escape sequences** → the vendored `.gem` blobs. Use the pull-files API (Gate C), not `--allow-escape-sequences`.
- **Merge rejected as out of date** → the queue handles this; just enqueue. Only outside the queue does this need `@dependabot rebase`.
- **Merge rejected** for any other reason → report it, leave the PR open, continue with the rest.
- **Queue is full (5 entries)** → enqueue the highest-value PRs and leave the rest for the next run.
- **e2e flake** → do not merge; offer `gh run rerun <run-id> --failed` and re-check.
