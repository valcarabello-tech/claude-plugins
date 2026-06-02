# Grafana Quest Log Skill

## Trigger phrases

**Default phrases:**
- "roll for initiative"
- "update my quest log"
- "add to my quest log"
- "new quests"
- "build my quest log"

**Custom phrase:** The user may have set a custom trigger phrase during setup. It's stored as `gql-trigger-phrase` in the app's localStorage. If the user says something that matches their custom phrase (or anything that sounds like "let's do my tasks" / "time to work"), treat it as a trigger for this skill.

When the skill runs, acknowledge the user's custom phrase if one is set — e.g. "Heard your command! Let's build your quests." — but don't require it.

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

### Step 2 — Organize AND rewrite with flavor

Group their items into logical quest categories (3–6 quests max). Each quest should have 2–8 tasks.

**IMPORTANT: Do NOT use the user's exact words.** Transform the content with personality and tone:
- Quest names should be evocative, not literal ("The Documentation Trial" not "Write docs")
- Task text should have personality, not be a verbatim copy ("Negotiate the Slack backlog" not "reply to slack messages")
- Make it feel fun — someone should smile reading their to-do list

Naming and task conventions by tone:
- **epic**: Quest names like "The Weekly Campaign", "The Documentation Trial", "The Sync Ritual". Tasks like "Vanquish the inbox backlog", "Forge the Q3 alignment doc", "Summon the cross-functional council"
- **chill**: Relaxed but still punchy. Quests like "Inbox Stuff", "The Meeting Gauntlet", "Side Quest: Research". Tasks like "Send that thing to Sarah", "Block time for the big doc", "Figure out what's happening with X"
- **grot**: Grot speaks. Quests like "Grot's Mandates", "The Sacred Scrolls of Slack", "Grot Demands These Done". Tasks like "Grot watches you write this doc", "Do not disappoint Grot with this meeting", "Grot has noted this is overdue"

Show the organized, rewritten list to the user and confirm before writing.

### Step 3 — Write directly to the file

Read `/Users/valmartin/Desktop/grafana-quest-log.html` and replace exactly this line:
```
const SEED_QUESTS = null; // ROLL_FOR_INITIATIVE
```

With the quests array on the same line, keeping the comment:
```
const SEED_QUESTS = [{"id":"q-1","name":"Quest Name","icon":"⚔️","tasks":[{"id":"t-1-1","text":"Task description"},{"id":"t-1-2","text":"Another task"}]},{"id":"q-2","name":"Another Quest","icon":"🔥","tasks":[{"id":"t-2-1","text":"Task here"}]}]; // ROLL_FOR_INITIATIVE
```

**Important rules:**
- Keep `// ROLL_FOR_INITIATIVE` at the end of the line — it's how the skill finds the line next time
- Use unique IDs: `q-1`, `q-2`, etc. for quests; `t-1-1`, `t-1-2`, `t-2-1`, etc. for tasks
- Do NOT touch any other line in the file
- Do NOT modify XP, level, or checked task data — only the quest/task structure changes
- Icons to rotate through: ⚔️ 🔥 🛡️ 📜 🗺️ 💀 🧙‍♂️ 🏆 🌟 💫

Also copy the updated file to the repo:
```
cp ~/Desktop/grafana-quest-log.html ~/claude-plugins/plugins/val-personal/skills/grafana-quest-log/grafana-quest-log.html
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
