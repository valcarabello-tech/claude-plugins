# Grafana Quest Log Skill

## Trigger phrases

Users pick their phrase from a fixed list during setup. All valid phrases:

**Epic tone:**
- "roll for initiative"
- "sound the war horn"
- "the campaign begins"

**Chill tone:**
- "let's get it"
- "what's on the plate"
- "time to sort things out"

**Grot Mode:**
- "update grot"
- "grot demands action"
- "grot is watching"

**Also always triggers this skill:**
- "update my quest log"
- "new quests"
- "build my quest log"

The user's chosen phrase is stored as `gql-trigger-phrase` in the app. Claude can't read it directly, but since all valid phrases are listed above, Claude will always recognize them. Acknowledge the phrase warmly when the skill runs — e.g. *"The war horn sounds! What's on your plate this week?"*

## What this skill does

Helps the user build or update their Grafana Quest Log to-do list. Takes a brain dump of tasks, organizes them into quests and tasks, then writes them directly into the HTML file. The user just refreshes — quests appear instantly. No importing, no extra steps.

## How it works

The HTML file contains a special placeholder line:
```js
const SEED_QUESTS = null; // ROLL_FOR_INITIATIVE
```

This skill replaces `null` with a real quests array. On next page load, the app reads it and loads the quests into localStorage automatically.

The HTML file lives at: `~/Desktop/grafana-quest-log.html`

---

## Instructions

### Step 1 — Collect tasks
Ask the user: "What's on your plate? Brain dump everything — I'll organize it."

Let them list everything in whatever format they want. Don't interrupt or ask clarifying questions until they're done.

### Step 2 — Organize AND rewrite with flavor IN ALL THREE TONES

‼️ **REWRITE EVERYTHING IN ALL THREE TONES. Do not copy the user's words verbatim. This is the whole point.**

Every quest name and task must have three versions: epic, chill, and grot. The user can switch between them instantly in Settings — tone switching now swaps ALL text, not just the header chrome.

Group into 3–6 quests. Each quest gets 2–8 tasks. Write all three tone versions for every name and task:

**Quest names by tone:**
| User's task | epic | chill | grot |
|---|---|---|---|
| "weekly work" | "The Weekly Campaign" | "This Week's Stuff" | "Grot's Mandates" |
| "write docs" | "The Documentation Trial" | "Write Some Docs" | "The Sacred Scrolls" |
| "meetings" | "The Sync Ritual" | "Meeting Gauntlet" | "Grot Attends These" |

**Task text by tone:**
| User's task | epic | chill | grot |
|---|---|---|---|
| "reply to slack" | "Vanquish the inbox backlog" | "Clear the Slack pile" | "Grot demands a response by EOD" |
| "write doc" | "Forge the alignment scroll" | "Write that doc" | "Grot watches you type this" |
| "team meeting" | "Summon the cross-functional council" | "Do the team meeting" | "Do not disappoint Grot with this" |

**The bar:** Each epic version should make someone smile. Each chill version should be casual and real. Each grot version should feel watched.

Show the rewritten list (one tone preview — user's current tone) and confirm before writing.

### Step 3 — Write directly to the file

Find the HTML file at `~/Desktop/grafana-quest-log.html` (expand `~` to the user's actual home directory). Replace exactly this line:
```
const SEED_QUESTS = null; // ROLL_FOR_INITIATIVE
```

With the quests array on the same line, keeping the comment:
```
const SEED_QUESTS = [{"id":"q-1","name":{"epic":"The Weekly Campaign","chill":"This Week's Stuff","grot":"Grot's Mandates"},"icon":"⚔️","tasks":[{"id":"t-1-1","text":{"epic":"Vanquish the inbox backlog","chill":"Clear the inbox","grot":"Grot demands inbox cleared"}},{"id":"t-1-2","text":{"epic":"Forge the alignment scroll","chill":"Write that doc","grot":"Grot watches you type this"}}]},{"id":"q-2","name":{"epic":"The Sync Ritual","chill":"Meeting Gauntlet","grot":"Grot Attends These"},"icon":"🔥","tasks":[{"id":"t-2-1","text":{"epic":"Summon the cross-functional council","chill":"Do the team meeting","grot":"Do not disappoint Grot with this"}}]}]; // ROLL_FOR_INITIATIVE
```

**Important rules:**
- Keep `// ROLL_FOR_INITIATIVE` at the end of the line — it's how the skill finds the line next time
- Use unique IDs: `q-1`, `q-2`, etc. for quests; `t-1-1`, `t-1-2`, `t-2-1`, etc. for tasks
- Do NOT touch any other line in the file
- Do NOT modify XP, level, or checked task data — only the quest/task structure changes
- Icons to rotate through: ⚔️ 🔥 🛡️ 📜 🗺️ 💀 🧙‍♂️ 🏆 🌟 💫

If the user has a local `~/claude-plugins/` repo with this skill in it, also sync the file:
```bash
if [ -d ~/claude-plugins/plugins/val-personal/skills/grafana-quest-log ]; then
  cp ~/Desktop/grafana-quest-log.html ~/claude-plugins/plugins/val-personal/skills/grafana-quest-log/grafana-quest-log.html
fi
```

### Step 4 — Tell the user

"Done! Refresh your Quest Log and your quests will be there. ⚔️"

---

## Notes
- If the user says "clear my quests" or "start fresh", replace with an empty array `[]` — the wizard will show again on next load
- XP, level, Grot tier, and checked tasks are NEVER touched — only the quest/task structure changes
- If the user wants to ADD quests (not replace), read the current `SEED_QUESTS` value from the file first, then append to it
- The user's custom trigger phrase is stored in the app's `localStorage` under `gql-trigger-phrase` — it's set during the wizard's first step or in the Settings panel. Claude cannot read localStorage directly, but the user chose their phrase and will use it to invoke this skill. Honor whatever phrase they use.
- The user's player name is stored as `gql-player-name` and their tone as `gql-tone` — use these when organizing quests (e.g. epic/chill/grot naming conventions)
- **Hash check**: The app uses a content hash to detect when SEED_QUESTS is new vs already applied — so in-app edits (rename, reorder, add tasks) are preserved across relaunches. Writing genuinely different quest content means the hash changes and the new quests will apply. No extra steps needed.
- **In-app editing**: Users can also manage quests directly in the app without Claude — add tasks to existing quests, rename quests, reorder quests/tasks via drag, delete tasks or whole quests. In-app edits update the current-tone version only (other tones are preserved). Mention this if they ask how to make small changes.
- **Tone-switching**: Quest names and task text are now stored as `{epic, chill, grot}` objects. Switching tone in Settings instantly swaps ALL text — no reload needed. If the user says "rewrite my quests in grot mode" (or similar), rewrite all three tones and change their saved tone to grot too: add `lsSet('gql-tone','grot')` is NOT possible from Claude — but note that the user should also update their tone in Settings to see the grot wording.
- **"Rewrite in [tone] mode"**: If a user asks to switch tone via Claude, write all 3 tone versions (as always) and remind them to also go to Settings → Tone and save to update the UI chrome.
