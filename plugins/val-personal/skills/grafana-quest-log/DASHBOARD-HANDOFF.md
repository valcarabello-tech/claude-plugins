# Grafana Quest Log — Shared Dashboard Handoff

**Purpose:** Build a real Grafana dashboard where the team (coworkers using the Quest Log) can see each other — a leaderboard of XP, levels, quests completed, and weekly activity. This is feature #1 from the polish backlog, intentionally deferred until the app itself was stable.

**Status:** Not started. App is otherwise working (build 11:30+, Grot Codex fixed via source-image cleaning). This doc is the cold-start brief.

---

## 1. The core problem to solve

Every person runs their **own** copy of the Quest Log. All data lives in that machine's **localStorage** (`gql-` prefixed keys) plus a local backup at `~/Library/Application Support/GrafanaQuestLog/backup.json`. There is **no shared backend** today.

So the whole challenge is: **get each person's stats out of their local app and into one central place Grafana can query.** Grafana can't read localStorage — something has to *push* the data out.

---

## 2. Data we already have (per player, in the app)

Computed in the HTML at render time, ready to send:
- `gql-player-name` → display name
- `totalXp` (`gql-total-xp`) → lifetime XP
- current **level** (derived from totalXp via `getLevelData()`)
- current **Grot tier index** (`Math.min(41, Math.floor((level-1)*41/99))`)
- `weeklyXp` (`gql-weekly-xp`) → XP this ISO week
- quests completed (`gql-total-quests` / `questBonuses.length`)
- `gql-week-key` → e.g. `2026-W24`
- `gql-tone` → epic / chill / grot
- `gql-xp-history` → `{ "2026-W23": 380, ... }` weekly totals

That's more than enough for a fun leaderboard.

---

## 3. Architecture options (pick one with Val)

**Option A — Grafana Cloud hosted metrics (recommended; Val works at Grafana Labs).**
- Each app pushes metrics to Grafana Cloud via a simple HTTP write (Graphite/Influx line protocol, or OTLP, or Prometheus remote_write).
- Metrics like `questlog_total_xp{player="Val"} 1200`, `questlog_level`, `questlog_weekly_xp`, `questlog_quests_completed`.
- Dashboard queries that datasource. Native fit, time-series built in (weekly trends for free).

**Option B — Google Sheet + Infinity datasource (zero infra).**
- App POSTs a row per player to a Sheet (via Apps Script web app or a small endpoint).
- Grafana **Infinity** datasource reads the Sheet as a table.
- Dead simple, but time-series/history is clunky.

**Option C — BigQuery (Val already has GTM Data API / `gtm-bigquery` access).**
- App POSTs to a small endpoint that inserts rows into a BQ table.
- Grafana BigQuery datasource. Great for history + SQL, more setup.

**Option D — reuse the Onboardy Cloud Run app** (Val owns it; see `reference_onboardy_app.md` in memory) as the push endpoint/proxy, then forward to any of the above.

> Recommendation: **Option A** for the real-time leaderboard feel, OR **Option B** if Val wants this done in an afternoon with no infra.

---

## 4. Where the push happens (keep the token out of the HTML)

The HTML is distributed to coworkers, so **don't embed a write token in it.** Instead:

- Add a Swift `WKScriptMessageHandler` named `pushMetrics` to the macOS app (it already has `saveBackup`, `openURL`, `setDockIcon`, `reload` — same pattern). The Swift side holds the token (in the binary; extractable but acceptable for an internal fun tool) and makes the authenticated HTTPS POST.
- In the HTML, add a debounced `pushMetrics()` JS function called at the end of `render()` (or on XP change), posting a small JSON payload via `window.webkit.messageHandlers.pushMetrics.postMessage(...)`.
- Payload shape: `{ player, level, totalXp, weeklyXp, questsCompleted, grotTier, weekKey, tone, ts }`.

Browser-only users (non-Mac, opening the raw HTML) won't have the Swift bridge — that's fine; they just won't report. Could add a fetch() fallback later if needed.

---

## 5. Decisions needed from Val (ask first)

1. **Backend choice** — A / B / C / D above.
2. **Player identity** — display name only, or name + a stable generated id (handles duplicate names)?
3. **Opt-in?** — Add a Settings toggle "Appear on the team leaderboard" (default off until they choose). Likely yes for privacy.
4. **Push cadence** — every save (debounced ~5s), or once per launch + on level-up?
5. **Who/where hosts the endpoint + token** — Grafana Cloud stack? Onboardy Cloud Run? A Sheet?
6. **Scope of audience** — just the onboarding team, or anyone with the app?

---

## 6. Dashboard to build (once data flows)

Panels:
- **Leaderboard table** — player · level · total XP · weekly XP · quests completed (sortable). Bonus: show the player's current Grot image in a cell (table cell image display / data link).
- **Top XP this week** — bar gauge.
- **Weekly XP per player over time** — time series (needs Option A or C for clean history).
- **Team totals** — stat panels: total team XP, total quests slain this week, active players.
- Optional fun: "Current Boss Battles" list, "Highest Grot tier" hall of fame.

**Tooling available to build it programmatically:** Grafana MCP tools are present in this environment — `grafana_search_dashboards`, `grafana_get_dashboard_by_uid`, `grafana_search_folders`, `grafana_grafana_api_request` (can create/update dashboards via the HTTP API), plus `gtm-bigquery` if going the BQ route. A future session can scaffold the dashboard JSON and POST it directly.

---

## 7. Concrete next steps (in order)

1. Confirm backend choice + opt-in with Val (Section 5).
2. Stand up the datasource/endpoint; obtain a **write-only** token.
3. Add Settings UI: "Appear on team leaderboard" toggle + confirm display name. Store as `gql-leaderboard-optin`.
4. Add `pushMetrics()` JS in HTML (debounced, gated on opt-in) → `window.webkit.messageHandlers.pushMetrics`.
5. Add `pushMetrics` handler in `/tmp/gql-build/main.swift` (token-holding HTTPS POST). Rebuild universal binary, re-sign, redeploy (see build steps in the main skill / session history).
6. Build the dashboard via Grafana MCP; iterate on panels.
7. Test with 2–3 coworkers, verify the leaderboard populates.

---

## 8. Key files & context

- **App HTML:** `~/Desktop/grafana-quest-log.html` (~2.8 MB, all 42 Grot images base64-embedded). Synced copy in this skill dir: `grafana-quest-log.html`.
- **Swift wrapper source:** `/tmp/gql-build/main.swift` (rebuilt as universal arm64+x86_64, ad-hoc signed; deployed to `~/Desktop/GrafanaQuestLog.app`). Message handlers + `nonPersistent` WKWebView data store live here.
- **Local backup:** `~/Library/Application Support/GrafanaQuestLog/backup.json` (mirrors all `gql-` keys; written on every save).
- **Build stamp:** `const BUILD_ID` near top of the `<script>` — bump it each change; shows at the bottom of the Grot Codex so you can confirm a fresh load.
- **Verification lesson learned (important):** offscreen WKWebView snapshots do **not** always match the live on-screen display. Verify visual changes by rendering in an actual on-screen window or via a user screenshot — not just `takeSnapshot`.
- **Related Val assets:** Onboardy Cloud Run app (`reference_onboardy_app.md`), `gtm-bigquery` skill, Grafana MCP datasource access.

---

## 9. Backlog still queued after the dashboard (from polish list)
- #3 Quest polish — level-up animation, XP particle burst, sound toggle
- #4 Smarter calendar→quest generation (recurring meeting detection, boss-battle suggestion)
- #5 Backup/restore UI (export/import the whole log as a file)
