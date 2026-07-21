# SkillProof Mobile ↔ Backend Drift Audit

**Mobile app:** `skillproof-mobile` @ tag `v1.2.3` (commit `1ff358a`, 2026-07-14)
**Backend/web reference:** `skillproof` @ `main`, commit `9545945` (2026-07-19)
**Scope:** read-only comparison. No code written, no files changed.

**Legend:** `BROKEN` = app parses/calls something that no longer exists · `STALE` = works but shows outdated/incomplete data · `MISSING` = feature exists on web/API, absent on mobile · `OK` = verified in sync.

**Headline finding:** no `BROKEN` endpoints were found. The backend team has evidently been deliberate about mobile compatibility — there's a dedicated `GET /assessments/catalog/summary` built specifically as a "mobile-simplified projection" (commit `fe9c45d`), and every other endpoint the app calls (auth, profile, jobs, applications, external credentials) still matches field-for-field. The real drift is entirely in the `STALE`/`MISSING` category: badge provenance, the interviews pipeline, and some copilot message text have moved on without mobile.

---

## 1. Endpoint drift

### Auth — `OK`
| Mobile call | Backend route | Verdict |
|---|---|---|
| `POST /auth/otp/request` `{phone}` | `RequestOtpDto{phone}` → `{message}` | OK — mobile doesn't parse response |
| `POST /auth/otp/verify` `{phone,otp}` | `VerifyOtpDto` → `{accessToken,refreshToken,user}` | OK, exact field match |
| `POST /auth/google` `{code,redirectUri:''}` | `OAuthCodeDto{code,redirectUri,codeVerifier?}` → same shape | OK |
| `POST /auth/refresh` `{refreshToken}` | → `{accessToken,refreshToken}` (no `user`) | OK — mobile only reads the two token fields |
| `POST /auth/logout` `{refreshToken}` | → `{ok:true}` | OK — best-effort, unparsed |
| `GET /users/me` | full `User` incl. `profile.skillClaims{skill,badge}` | OK for auth; badge-shape gap covered in §2 |

No mismatch. Mobile also doesn't offer GitHub sign-in or the employer OAuth routes, but those are out of scope for a candidate app — not drift, just unused surface.

### Profile — `OK`, one `MISSING` footnote
- `GET /profiles/me` / `PATCH /profiles/me`: mobile's `CandidateProfile` model reads `fullName, email, headline, roleTitle, roleTitleOther, location, yearsOfExp, githubUrl, linkedinUrl, completeness`, and derives `hasResume` from `resumeS3Key`. Backend response has exactly these plus `id, userId, emailNotifications, createdAt, updatedAt, deletedAt` — all reasonably unused by a profile-edit UI. **OK.**
- The `PATCH` body mobile sends (`fullName, email, headline, roleTitle, roleTitleOther, location, yearsOfExp, githubUrl, linkedinUrl`) matches `UpdateProfileDto`'s whitelist **exactly** — important because the API's global `ValidationPipe` has `forbidNonWhitelisted`, so any stray field would 400 the whole request. No stray fields found. **OK.**
- `MISSING`: backend has added `POST /profiles/me/resume/improve` and `POST /profiles/me/resume/generate` (LLM resume tooling) since mobile's `v1.2.3`. Mobile's resume upload/parse code path is already dead (commented out, blocked on a `file_picker`/compileSdk 36 toolchain conflict per its own TODO), so these are net-new capabilities with zero mobile presence — low priority since the prerequisite upload flow isn't even wired up yet.

### Badges — see §2 (dedicated section, this is the meat of the audit)

### Assessments catalog — see §3

### Jobs — `OK`
- `GET /jobs/browse?skillId&location&remote&limit&offset` ↔ `BrowseJobsDto` — exact param match. Response `{total, jobs[]}` — mobile ignores echoed `limit`/`offset`, harmless.
- `Job.fromJson` reads `id, title, orgName, location, remote, employmentType, experienceMin, experienceMax, requiredSkills(←'skills'), alreadyApplied, description, salaryMin, salaryMax` against the backend's `PublicJob` shape — every field present and correctly renamed (`skills`→`requiredSkills`, `requiredLevel`→`level` inside `JobSkillRequirement`). **OK.** Mobile doesn't read `createdAt` (no "posted N days ago" UI) — cosmetic gap only.
- `GET /jobs/browse/:id`, `GET /jobs/matched`, `POST /jobs/:id/apply` — all field-for-field match, including the `PROFILE_INCOMPLETE`/`BADGE_REQUIRED` error codes mobile already branches on (the latter is currently a no-op since `REQUIRE_VERIFIED_BADGE_TO_APPLY` defaults false server-side, but mobile is already forward-compatible with it). **OK.**

### Applications — `OK`
- `GET /applications/me` → bare array; mobile's `Application.fromJson` reads `id, status, createdAt` and unnests `job.id/job.title/job.orgName`. Backend's `job` object also carries `employmentType, location, remote`, unused by mobile's list view — not stale, just not needed for that screen.
- No application-detail endpoint exists on the backend, and mobile doesn't call one either. Consistent — no dead call.

### External credentials — `OK` on the calls, one `STALE` field
- `POST/GET/DELETE /profiles/me/external-credentials` all match `CreateExternalCredentialDto` and the `ExternalCredential` response shape.
- `STALE`: backend's `ExternalCredential` also carries `nameMatchState` (`MATCH|MISMATCH|UNCHECKED`) and `rawMetadata.holderName`, which the web app's TS interface for this model narrows explicitly (implying the web profile page surfaces a name-match signal). Mobile's `ExternalCredential` model doesn't parse either field — if a candidate uploads a Credly credential under a different name than their profile, web can flag it and mobile silently can't.

### Auth/profile/jobs/applications summary
No breaking drift anywhere in this group. The gaps are all in the newer feature surfaces below.

---

## 2. Badge provenance — `STALE`

**What mobile currently reads** (`badges_repository.dart` + `models/badge.dart`): calls `GET /users/me`, filters `profile.skillClaims` to `status == 'VERIFIED' && badge.revokedAt == null`, and builds a `VerifiedBadge{skillClaimId, skillName, level, verifyHash, issuedAt}`. **There is no provenance field anywhere in the mobile model.**

**What the API now returns:** the `Badge` model has carried a `verifiedBy: BadgeVerificationMethod` field (`TEST | DISCUSSION`) since commit `6057994`, with an explicit, centralized precedence rule in `badge-resolver.service.ts`:
```ts
DISCUSSION: 1, TEST: 0   // higher wins; tie-break on most recent issuedAt
```
`GET /users/me`'s `profile.skillClaims[].badge` includes this `verifiedBy` field today — mobile's `BadgesRepository` already receives it in the raw JSON and simply never reads it.

**What the web reference does with it** (`Dashboard.tsx`): appends 💬 (discussion) or ✓ (test) to the badge chip, with a `title` tooltip "Verified by discussion"/"Verified by test". The precedence collapsing itself happens server-side (`BadgeResolverService.pickBest`) inside the assessments-catalog builder — but **that resolver is not visibly wired into `users.controller.ts`'s `GET /users/me`**, which does a plain Prisma `include` with no precedence pass. Worth verifying directly with the backend team: if a candidate has both a TEST and a DISCUSSION badge at the same skill+level, does `profile.skillClaims` return one row or two? If two, mobile would show a redundant/duplicate badge chip for the same skill+level today, with no way to indicate one supersedes the other.

**To consume provenance, mobile needs:**
1. Add `verifiedBy: String` (or an enum `TEST|DISCUSSION`) to `VerifiedBadge.fromJson`, reading `badge['verifiedBy']` — the field is already in the payload it fetches today.
2. A UI treatment mirroring web's chip icon/tooltip (💬 vs ✓), on the badges screen and wherever badge chips appear on Home.
3. Confirmation from the backend on the `/users/me` duplicate-claim question above before shipping, so the mobile UI doesn't need its own ad hoc precedence logic if the API already collapses it (or does need one, if it doesn't).

**"SkillProof" terminology check:** grepped both repos. The string is **not stale** — it's still very much the live product name in both codebases. It appears on mobile's Home app bar, login screen, hero section copy, and status-card labels (`lib/features/home/**`, `lib/features/auth/login_screen.dart`, `lib/app.dart`), and equally on web's `CandidateNav.tsx` (`SkillProof`), `Dashboard.tsx`'s first-time welcome message ("Welcome to SkillProof"), and `app/layout.tsx`'s page title. The July 2026 "rebrand" commit (`351aa35`) changed color/accent/gray tokens only, not the product name. **No action needed here** — flagging as a non-finding since the audit brief asked to check.

---

## 3. Assessments catalog + discussion hand-off — `STALE`/`MISSING` (mixed — one piece already works)

**What mobile currently fetches/renders:** `GET /assessments/catalog/summary` → `{skills: [{skillId, skillName, relevanceCount, badgeLevel, levelState, estMinutes, state, retakeAvailableAt, webPath}]}`. This is **a different, deliberately mobile-simplified endpoint** (built in commit `fe9c45d` specifically for this app) — one card per skill, showing only the *next available* level, not the full L1–L4 progression.

**What the current API's full catalog looks like** (`GET /assessments/catalog`, what `apps/web/app/assessments/page.tsx` consumes): skill-grouped, with a `levels[]` array of 4 rows per skill, each carrying `formats[]` (`TEST`/`DISCUSSION` with duration), `earned{verifiedBy,verifyHash,issuedAt}`, `discussion{sessionId,status,insufficientProbing,retakeAvailableAt}`, and `state: EARNED|SUBSUMED|AVAILABLE|LOCKED` with `unlocksAfterLevel`/`coveredByLevel`. Mobile's summary endpoint only ever returns `state: available|in_progress|cooldown` for the single next-actionable level — it never exposes `LOCKED`/`SUBSUMED`/`EARNED` rows at all, so mobile can't show the sequential-level progression (e.g., "L3 unlocks after L2") the web catalog now visualizes.

**Discussion hand-off — the good news:** mobile *already* has the exact url_launcher pattern this needs, and it may already work for the one discussion assessment that exists today. `assessments_controller.dart` launches `webBaseUrl + entry.webPath` via `openInBrowser` (the same helper used for the badge certificate page, `badges_screen.dart:115`) — external browser, not an in-app webview, which matches the deliberate "integrity capture is browser-based" design intent. The summary endpoint's `webPath` for a discussion-only level already resolves to `/assessments/discussion/{slug}`. Since the current single discussion assessment (RAG Systems / L2) has no TEST counterpart, mobile's existing generic launch code should already surface and correctly hand off to it — **this looks like it may already work without any mobile changes**, but should be smoke-tested to confirm rather than assumed.

**Where it falls short:** the backend's summary-endpoint logic explicitly "prefers TEST format over DISCUSSION when both exist" at a level. So the moment a second discussion-eligible skill/level is added where a TEST option *also* exists, mobile's card will only ever offer the TEST path — it has no way to additionally surface "prove this by discussion for stronger evidence" the way web does for already-TEST-earned levels. That upsell entirely depends on the fuller `levels[]`/`formats[]` shape mobile doesn't fetch.

**To fully match web's current catalog behavior, mobile would need to:**
1. Switch to (or add alongside) `GET /assessments/catalog` and model the full skill→levels→formats/earned/discussion/state shape, not just the single-card summary.
2. Render level rows per skill (L1–L4) with lock/subsumed/earned states, matching web's `LevelRow` logic.
3. When a level has both a TEST and DISCUSSION format, offer both — with DISCUSSION still going through the existing `openInBrowser` hand-off, exactly as the badge certificate link does today. **No native discussion assessment should be built — browser hand-off is correct and already the working pattern.**

This is a genuinely bigger lift than badge provenance (§2), since it means changing which endpoint mobile calls, not just adding a field.

---

## 4. The interviews gap — `MISSING` (entirely)

`grep -rni interview lib/` in the mobile repo returns **zero matches**. There is no Interviews tab, screen, model, or repository anywhere in the app. The backend has built a complete candidate-facing pipeline (commit `234b1b6`, on top of `b203030`'s shortlisting and followed by `9545945`'s employer KPI dashboard).

**Candidate-facing endpoints to scope against:**

| Method | Path | Body | Response |
|---|---|---|---|
| `GET` | `/interviews/mine` | — | `Interview[]` (see below) |
| `POST` | `/interviews/:id/respond-invite` | `{response: 'ACCEPT'\|'DECLINE'}` | `{id, stage}` |
| `POST` | `/interviews/:id/respond-offer` | `{response: 'ACCEPTED'\|'DECLINED'\|'NEGOTIATING'}` | `{id, candidateResponse}` |

`Interview` shape from `GET /interviews/mine`:
```ts
{
  id: string,
  orgName: string,
  job: { id: string, title: string } | null,
  stage: 'SHORTLISTED'|'INVITED'|'INTERVIEWING'|'OFFER'|'HIRED'|'DECLINED'|'REJECTED'|'CLOSED',
  inviteMessage: string | null,
  currentRound: { roundNumber: number, status: 'SCHEDULED'|'COMPLETED'|'PASSED'|'FAILED', channel: string | null, scheduledAt: string | null } | null,
  candidateResponse: 'ACCEPTED'|'DECLINED'|'NEGOTIATING' | null,
  updatedAt: string,
}
```
Notes for scoping (confirmed against both the API's own doc comments and the web component's matching comments, so this is deliberate, not an oversight):
- Only the **latest** round is returned — no round-history list, no total round count.
- No employer-authored `note`/`rejectReason` fields are ever returned to the candidate (server-side omission, by design).
- There is no `GET /interviews/:id` detail route — only the list plus the two action endpoints, which return small patch objects (`{id, stage}` / `{id, candidateResponse}`), not the full updated entry — a mobile client would need to patch its local list rather than refetch a detail view.
- `respond-offer` 409s once the entry has moved stage past `OFFER` — worth handling explicitly if scoping an offer-response UI.

A minimal mobile Interviews feature would need: a repository hitting `/interviews/mine`, a model matching the shape above, list/detail screens keyed off `stage` with the same label mapping web uses (`STAGE_LABELS`/`ROUND_STATUS_LABELS` in `CandidateInterviews.tsx`), and the two response actions. This is pure scoping information — no implementation done here.

---

## 5. Copilot sync — `STALE`

`copilot_panel.dart`'s doc comment states the priority order mirrors `buildCopilotMessage` in `apps/web/components/Dashboard.tsx` and asks that they be kept in sync. Comparing both in full:

**Identical (steps 3–7 of 7):** strong-match message, recurring-gap message, weak-match "still developing" message, "you're on your way" applications message, and the final fallback message are **word-for-word identical** between mobile and web, including the `kMatchStrongThreshold`/`MATCH_STRONG_THRESHOLD = 65` and `kRecurringGapMinCount`/`RECURRING_GAP_MIN_COUNT = 2` constants.

**Diverged (steps 1–2 of 7):**

1. **Step 1 (`!hasProfile`) — different copy entirely:**
   - Mobile: *"Complete your profile so employers know who they're looking at."* / CTA **"Complete your profile"**
   - Web: *"Upload your resume and I'll build your profile — that's step one to matching you with roles."* / CTA **"Build your profile"**

   Both the message and the CTA label differ. Not a logic bug, but the two surfaces say different things for the same state.

2. **Step 2 — different condition, and web has a branch mobile lacks:**
   - Mobile checks a single boolean `hasVerifiedSkill` and always shows one message: *"Earn a badge or add a credential to prove your skills."*
   - Web checks `hasBadge` (narrower — reads as SkillProof-badge-specific, not "any verified skill" broadly) **and** additionally branches on `liveAssessmentCount > 0`, showing *"You're set up. Take a verified assessment..."* when something's available vs. *"...I'll let you know the moment an assessment opens up..."* when nothing is. Mobile has no `liveAssessmentCount` concept at all, so it can't replicate this branch.
   - Worth double-checking on the mobile side exactly what feeds `hasVerifiedSkill` (not visible in the files read for this audit — likely `home_controller.dart`): if it counts external credentials as well as SkillProof badges, a candidate with only an external credential and no SkillProof badge could see **different copilot states** on mobile vs. web for the same underlying data — mobile would consider them past step 2, web would not.

**Recommendation for resync:** align step 1's copy exactly, and either drop web's `liveAssessmentCount` branch to match mobile's simpler version, or port the branch (and confirm `hasVerifiedSkill` vs `hasBadge` compute the same boolean) — whichever direction the product wants as canonical.

---

## 6. Config / base URLs — mostly `OK`, one item `UNVERIFIABLE` from this repo, one minor hygiene flag

**Mobile's production config** (`prod.json`, `run-prod.ps1`, `build-prod-apk.ps1`, and `.github/workflows/build-apk.yml` — all four agree):
```
API_BASE_URL=https://api.skillproof.flairfuture.com
WEB_BASE_URL=https://skillproof.flairfuture.com
```
These are injected via `--dart-define` at build time; `prod.json` itself isn't read by the app, it's a human cross-check doc (RELEASE.md explicitly tells releasers to diff it against the workflow's dart-define flags).

**Can't confirm these hostnames are still current from this repo.** Neither `apps/api` nor `apps/web` has any committed production hostname/deploy config — `next.config.mjs` is an empty stub, `apps/web/.env.local` only has `NEXT_PUBLIC_API_URL=http://localhost:4000`, there's no `vercel.json`/`netlify.toml`, and the CI workflow only builds, never deploys. Production DNS/hosting must be configured entirely outside this repo (a hosting platform's dashboard). **Recommend manually confirming `api.skillproof.flairfuture.com` and `skillproof.flairfuture.com` are still the live hosts** before relying on this as validated — this audit can't prove or disprove it from either repo's contents.

**Dev-only fallback defaults (won't bite in CI/prod builds, since dart-define always overrides them):**
- `lib/config/api_config.dart:13` — `API_BASE_URL` falls back to `http://10.0.2.2:4000` (standard Android-emulator loopback alias) when not overridden.
- `lib/config/api_config.dart:27` — `WEB_BASE_URL` falls back to `http://192.168.0.101:3000` — a **hardcoded personal LAN IP literal**, presumably a developer's own machine, checked into source. Harmless for builds (always overridden by dart-define in CI/release scripts) but worth a low-priority cleanup — it's dead weight in version control and mildly reveals a private network address.

---

## Prioritized punch list

**Correctness first (none found — nothing is actually broken):**
- No `BROKEN` items surfaced in this audit. Every endpoint the mobile app currently calls still exists at the same path/method with a compatible request/response shape.

**Value next (`MISSING` → `STALE`, roughly in order of candidate-facing impact):**

1. **`MISSING` — Interviews tab.** Entirely absent; candidates who get shortlisted/invited/offered have no visibility on mobile at all. Highest-value gap since it's a whole feature, not a field. Scope per §4 (`/interviews/mine`, respond-invite, respond-offer).
2. **`STALE` — Badge provenance.** `verifiedBy` (TEST/DISCUSSION) is already in the JSON mobile fetches from `GET /users/me` and is simply not read. Cheapest fix in this whole audit (one field + one icon), but first confirm with the backend whether `/users/me` can return duplicate claims for the same skill+level across methods (§2).
3. **`STALE`/`MISSING` — Assessments catalog IA.** Mobile's simplified summary endpoint hides the L1–L4 sequential-level structure and can't offer the discussion-upgrade-over-test upsell. The discussion *hand-off mechanism itself* likely already works today via the existing `openInBrowser`/`webPath` pattern — verify that first before assuming a rebuild is needed; the bigger lift is switching to the full catalog shape for level-row rendering.
4. **`STALE` — Copilot message divergence.** Step 1 copy/CTA text differs; step 2 web has a branch (`liveAssessmentCount`) mobile lacks, and the two apps may be keying off non-equivalent booleans (`hasVerifiedSkill` vs `hasBadge`). Low engineering cost, but a real user-facing inconsistency today.
5. **`STALE` — External credential name-match signal.** `nameMatchState`/`rawMetadata.holderName` unread on mobile; low priority, advisory-only field.
6. **Hygiene, no urgency:** hardcoded personal LAN IP default in `api_config.dart:27`; unverified production hostnames (can't confirm from repo, needs manual check against actual hosting config); new `resume/improve` and `resume/generate` endpoints have no mobile consumer (moot until resume upload itself is unblocked).
