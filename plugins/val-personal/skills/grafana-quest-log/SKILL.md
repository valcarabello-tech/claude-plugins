# Grafana Quest Log Skill

## Trigger phrases
- "roll for initiative"
- "update my quest log"
- "add to my quest log"
- "new quests"
- "build my quest log"

## What this skill does

Helps the user build or update their Grafana Quest Log to-do list. Takes a brain dump of tasks, organizes them into quests and tasks, and generates a JSON import file they can load directly into the app using the Import Scroll button.

## Instructions

When triggered, follow these steps:

### Step 1 — Collect tasks
Ask the user: "What's on your plate? Brain dump everything — I'll organize it."

Let them list everything in whatever format they want. Don't interrupt.

### Step 2 — Organize
Group their items into logical quest categories (3-6 quests max). Each quest should have 2-8 tasks.

Naming conventions by tone:
- **epic**: Quest names like "The Weekly Campaign", "The Documentation Trial", "The Sync Ritual"
- **chill**: Simple names like "Meetings", "Research", "Admin", "Team stuff"
- **grot**: Names like "Grot's Mandates", "The Sacred Scrolls of Slack", "Grot Demands Action"

If unsure of tone, ask: "What tone is your quest log set to — Epic, Chill, or Grot Mode?"

### Step 3 — Generate import JSON

Output a JSON object in this exact format (all `gql-*` keys):

```json
{
  "gql-quests": "[{\"id\":\"q-1\",\"name\":\"Quest Name\",\"icon\":\"⚔️\",\"tasks\":[{\"id\":\"t-1-1\",\"text\":\"Task description\"},{\"id\":\"t-1-2\",\"text\":\"Another task\"}]},{\"id\":\"q-2\",\"name\":\"Another Quest\",\"icon\":\"🔥\",\"tasks\":[{\"id\":\"t-2-1\",\"text\":\"Task here\"}]}]",
  "gql-setup-done": "true"
}
```

**Important:**
- `gql-quests` value must be a JSON-stringified array (string inside the outer JSON)
- Use unique IDs: `q-1`, `q-2`, etc. for quests; `t-1-1`, `t-1-2`, `t-2-1`, etc. for tasks
- Do NOT include `gql-checked`, `gql-total-xp`, `gql-weekly-xp` or any XP/progress keys — those must be preserved
- Icons: ⚔️🔥🛡️📜🗺️💀🧙‍♂️🏆🌟💫 (rotate through these)

### Step 4 — Deliver

Tell the user:
1. Show them the organized quest list in a readable format first
2. Ask if they want to add/change anything
3. Once confirmed, output the JSON wrapped in a code block
4. Give instructions: "Save this as `quest-import.json`, then open your Quest Log and click **Import Scroll** (top right). Your quests will load immediately."

### Notes
- If the user says "clear my quests" or "start fresh", generate a JSON with an empty quests array and confirm before proceeding
- If the user just wants to ADD quests (not replace), ask them to first Export Scroll so you can see their current quests, then add to the existing list
- XP, level, and Grot progress are NEVER touched by this skill — only the quest/task list
