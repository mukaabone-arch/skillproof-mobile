# Git recovery — skillproof web repo, 2026-10-05

**Do not push anything until this is resolved.** `main` is `ahead 1` of `origin/main` and
that commit is a broken partial feature.

Nothing is lost. `feat/arabic-landing` (`4c4aa42`) is untouched, and the orphaned commit
`561ff8b` is still in the reflog.

## How it happened

Two agents worked the same tree minutes apart. Reflog, oldest first:

| Ref | What |
|---|---|
| `HEAD@{9}` | `commit: wip` → `2f0f6f3` on `main` — the skill-level-names work, committed with a junk message |
| `HEAD@{8}` | checkout `main` → `demo/arabic-stakeholder`, created from `4c4aa42` |
| `HEAD@{7}` | `rebase (start): checkout main` |
| `HEAD@{6}` | `rebase (pick)` → `d772570` "Move all routes under app/[locale]/" |
| `HEAD@{5}` | `rebase (continue)` → `b726dac` "Add next-intl locale mechanism, English catalog only" |
| `HEAD@{4}` | `rebase (pick)` → `561ff8b` "Add Arabic (RTL) landing page, locale switcher and i18n drift check" |
| `HEAD@{3}` | `rebase (finish)` → `demo/arabic-stakeholder` at `561ff8b` |
| `HEAD@{2}` | **`reset: moving to HEAD~1`** — dropped `561ff8b`, left its content staged |
| `HEAD@{1}` | checkout → new branch `feat/skill-level-names` |
| `HEAD@{0}` | **`commit: e156ef8`** — committed `561ff8b`'s content under the skill-level-names message |

The reset and the commit were mine, prescribed on the assumption that `HEAD` was on
`main`. It wasn't — the rebase had moved it. My error.

## Where each piece of work is now

| Work | Location | State |
|---|---|---|
| Arabic i18n foundation, original | `feat/arabic-landing` @ `4c4aa42` | **Intact, untouched** |
| Route move under `[locale]/` | `d772570`, in `demo/arabic-stakeholder`'s history | Fine |
| next-intl mechanism | `b726dac` = tip of `demo/arabic-stakeholder` | Fine |
| Arabic landing + switcher + i18n check | `e156ef8` on `feat/skill-level-names` | **Mislabelled** |
| Skill-level-names, API side (6 files) | `2f0f6f3 wip` on `main` | **Wrong branch, junk message** |
| Skill-level-names, web side (2 files) | Inside `e156ef8` | **Wrong commit** |
| `apps/api/.env.example` change | Inside `e156ef8` | Unknown provenance — check it |
| `routing.ts`, `middleware.ts`, `routing.spec.ts` | Uncommitted working tree | **Unknown provenance — identify before touching** |

## What is actually broken

`main` @ `2f0f6f3` contains `Dashboard.tsx` reading
`applyGateProgress.levelNamesRemaining`, but **not** the `entitlements.tsx` change that
declares that field on `ApplyGate['progress']`. That's a type error, so the web build on
`main` fails.

Do not trust a green CI run on this. The API's CI reports green while six tests fail in
`auth.service.spec.ts` — the cause is still unknown and may be shared workflow config.
Run `npx next build` locally in `apps/web`.

## Recovery

Verify at each stage. Do not chain these.

### 1. Identify the uncommitted work first

```bash
git diff apps/web/i18n/routing.ts apps/web/middleware.ts
cat apps/web/i18n/routing.spec.ts
```

These are modifications on top of `e156ef8`, so they are almost certainly the demo's own
`LOCALIZED_PATHS` work. **If you wrote them, say so and commit them deliberately.** If
their origin is unclear, put them somewhere safe before anything else:

```bash
git stash push -m "uncommitted routing/middleware + routing.spec, provenance unknown" \
  apps/web/i18n/routing.ts apps/web/middleware.ts
git add apps/web/i18n/routing.spec.ts && git stash push -m "routing.spec.ts untracked"
```

Record the stash hashes that git prints. A dropped stash is only recoverable by hash.

### 2. Rebuild the skill-level-names feature complete, on its own branch

The 6 API-side files are on `main`; the 2 web-side files are inside `e156ef8`. Note the
path difference: `e156ef8` has the route **moved** under `[locale]/`, `main` does not.

```bash
git switch -c feat/skill-levels-named main
git show e156ef8:apps/web/lib/entitlements.tsx > apps/web/lib/entitlements.tsx
git show "e156ef8:apps/web/app/[locale]/jobs/[id]/page.tsx" > "apps/web/app/jobs/[id]/page.tsx"
git add -A
git commit -m "feat: surface human skill-level names instead of L1/L2/L3 codes"
```

Then prove it builds, which is the whole point of putting the 8 files back together:

```bash
cd apps/web && npx next build && cd ../..
cd apps/api && ./node_modules/.bin/tsc --noEmit -p tsconfig.json && cd ../..
```

Also check what `apps/api/.env.example` was changed to in `e156ef8` and decide which
branch it belongs on:

```bash
git show e156ef8 -- apps/api/.env.example
```

### 3. Reset `main` to origin

Only after step 2 passes its build — `2f0f6f3`'s content has to be safe on the new branch
first.

```bash
git switch main
git log origin/main..HEAD --oneline      # expect exactly: 2f0f6f3 wip
git reset --hard origin/main             # back to a08fed8
```

### 4. Rebuild the Arabic demo branch

`feat/arabic-landing` is intact, so redo the rebase rather than salvaging `561ff8b`:

```bash
git branch -m demo/arabic-stakeholder demo/arabic-stakeholder-abandoned
git switch -c demo/arabic-stakeholder feat/arabic-landing
git rebase main
```

Then delete the mislabelled branch once you've confirmed nothing unique is on it:

```bash
git log --oneline feat/skill-level-names ^demo/arabic-stakeholder ^feat/skill-levels-named
git branch -D feat/skill-level-names      # only if the above is empty
```

### 5. Restore the step-1 work

Pop the stashes onto `demo/arabic-stakeholder` and commit them with real messages.

## Afterwards

Two process points, both earned today.

**One agent per repo at a time.** The rebase and my reset ran minutes apart against the
same tree. Any recovery prescribed from outside the repo is stale by the time it executes.
If both are working, the one in the repo owns git state and the other one stays read-only.

**`wip` is not a commit message.** `2f0f6f3` was a coherent eight-file feature that looked
like junk for two hours because of its message, and that is why it got split. The commit
message is the only context the next reader gets.
