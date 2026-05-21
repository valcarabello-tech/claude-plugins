# ⚔️ Quest Log — Claude Code Skill

A Claude Code skill that turns your weekly to-do list into a DnD/LARP-themed interactive quest log — complete with a native macOS app, XP leveling, and progress tracking.

## What it does

- Translates your to-do list into quests with DnD-flavored language
- Builds a native macOS app (no browser needed — dock-pinnable!)
- **XP & leveling system** — 10 levels from Novice Adventurer to Mythic Hero
- Per-task XP floats, level-up overlay animations, progress bars per quest
- Total XP and quests completed carry over week to week
- Weekly tasks auto-reset via ISO week key detection

## Install

```bash
git clone -b quest-log https://github.com/valcarabello-tech/claude-plugins ~/quest-log
claude plugin install ~/quest-log
```

## Usage

Just say **"roll for initiative"** — that's it.

- **First time:** Claude asks your name, takes your to-do list, builds your personalized app
- **Every week after:** paste your new list and your quests refresh (XP and level carry over)

## Requirements

- Claude Code
- macOS (for the native app build)
- Xcode Command Line Tools: `xcode-select --install`
