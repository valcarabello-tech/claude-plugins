# Grafana Quest Log Skill

## Trigger phrases
- "roll for initiative"
- "update my quest log"
- "add to my quest log"
- "new quests"
- "build my quest log"

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

### Step 2 — Organize
Group their items into logical quest categories (3–6 quests max). Each quest should have 2–8 tasks. Keep task text concise but clear.

Naming conventions by tone (check `gql-tone` in the file or ask):
- **epic**: Quest names like "The Weekly Campaign", "The Documentation Trial", "The Sync Ritual"
- **chill**: Simple names like "Meetings", "Research", "Admin", "Team stuff"
- **grot**: Names like "Grot's Mandates", "The Sacred Scrolls of Slack", "Grot Demands Action"

Show the organized list to the user and confirm before writing.

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
