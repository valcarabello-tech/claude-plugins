# Grafana Quest Log — Setup Skill

## Trigger phrases
- "set up grafana quest log"
- "install grafana quest log"
- "install quest log"
- "grafana quest log setup"
- "set up quest log for me"
- "get me the quest log"

## What this skill does

Installs the Grafana Quest Log app on the user's Mac. Downloads the HTML file and the pre-built app, sets everything up, and walks the user through the one manual step (Gatekeeper bypass). Takes about 2 minutes.

---

## Instructions

### Step 1 — Greet and set expectations

Say:
> "On it! I'll download the files and set everything up. The only thing you'll need to do yourself is right-click the app to open it the first time — macOS will block it because it's not code-signed. Takes about 2 minutes."

### Step 2 — Download the HTML file to their Desktop

Run:
```bash
curl -L "https://raw.githubusercontent.com/valcarabello-tech/claude-plugins/grafana-quest-log/plugins/val-personal/skills/grafana-quest-log/grafana-quest-log.html" \
  -o ~/Desktop/grafana-quest-log.html
```

Confirm it landed:
```bash
ls -lh ~/Desktop/grafana-quest-log.html
```

If the download failed (file missing or tiny), stop and tell the user:
> "Couldn't reach the file — the repo may be private or the URL changed. Ask Val to share the files directly."

### Step 3 — Download and install the app

```bash
curl -L "https://raw.githubusercontent.com/valcarabello-tech/claude-plugins/grafana-quest-log/plugins/val-personal/skills/grafana-quest-log/GrafanaQuestLog.app.zip" \
  -o ~/Desktop/GrafanaQuestLog.app.zip

cd ~/Desktop && unzip -o GrafanaQuestLog.app.zip

# Clean up the zip
rm ~/Desktop/GrafanaQuestLog.app.zip
```

Confirm the app is there:
```bash
ls ~/Desktop/GrafanaQuestLog.app/Contents/MacOS/GrafanaQuestLog
```

### Step 4 — Remove quarantine flag

macOS adds a quarantine flag to downloaded files. Remove it so the Gatekeeper prompt is simpler:
```bash
xattr -cr ~/Desktop/GrafanaQuestLog.app
```

### Step 5 — Open in Finder and explain the one manual step

```bash
open -R ~/Desktop/GrafanaQuestLog.app
```

Then tell the user:

> "Done! Both files are on your Desktop. Here's the one thing I can't do for you:
>
> **Right-click `GrafanaQuestLog.app` → Open → click Open again.**
>
> macOS will warn you because the app isn't code-signed. This is expected — you only do it once.
>
> After that, drag the app into your Dock and you're set."

### Step 6 — Critical warning

**Always say this before finishing:**

> "⚠️ One important rule: **don't move `grafana-quest-log.html` off your Desktop.** The app reads it from that exact location. If you move it, the app will show an error. The app itself can live anywhere — Dock, Applications folder, wherever — but the HTML file stays on the Desktop."

### Step 7 — Explain first launch

> "When you open it for the first time, a setup wizard will appear. It'll ask for:
> - **Your name** — shows up in the header and window title
> - **Your vibe** — Epic (DnD quests), Chill (simple task list), or Grot Mode (Grot judges you)
> - **A trigger phrase** — the phrase you'll say to me to update your quests (anything you want: 'update grot', 'let's go', 'time to slay')
> - **Your first quests** — either type them in Quick Text mode or use the form builder
>
> After setup, just say your trigger phrase to me whenever you want to update your task list."

---

## Notes

- The binary is universal — works on Apple Silicon (M1/M2/M3/M4) and Intel Macs
- If `curl` fails because the repo is private, the user needs to get the files from Val directly (via Slack or the repo)
- If the user is on Windows or Linux, the app won't work — send them just the HTML file and tell them to open it in their browser
- If they ask about data/backups: the app auto-saves to `~/Library/Application Support/GrafanaQuestLog/backup.json` every time they complete a task. They don't need to do anything.
- If they want to update their quests later, they say their trigger phrase to Claude — that runs the `grafana-quest-log` skill (not this one)
