---
name: quest-log
description: Weekly quest log generator. Creates a personalized DnD/LARP/wizard-themed interactive quest log as a native macOS desktop app. Trigger this skill when the user says /quest-log, "make my quest log", "generate my quest log", "weekly quest log", "turn my to-do list into quests", or pastes a to-do list and wants it gamified. Also triggers on the weekly update phrase "roll for initiative" — use this to refresh the quest log with a new week's tasks.
---

> 🔔 **MAINTAINER REMINDER — FOR CLAUDE:** This skill lives in two places. Whenever Val updates this file, remind her to run the sync script so coworkers get the changes too:
> ```bash
> bash ~/claude-plugins/scripts/sync-quest-log.sh
> ```
> This copies the updated SKILL.md from `main` → the shareable `quest-log` branch and pushes it. Don't let her forget!

# ⚔️ Quest Log — Setup & Weekly Ritual

This skill does two things:
1. **First-time setup** — builds a personalized native macOS app (no browser needed)
2. **Weekly ritual** — triggered by "roll for initiative" — refreshes the quest log with new tasks

---

## Detecting which mode to run

- If `~/Desktop/QuestLog.app` does **not** exist → run **First-Time Setup** (even if the user said "roll for initiative" — they're new, so set them up properly first)
- If `~/Desktop/QuestLog.app` **exists** and the user says "roll for initiative" (any capitalization) → run **Weekly Ritual**
- If `~/Desktop/quest-log.html` exists but the app doesn't → run **First-Time Setup** (rebuild the app)

---

## FIRST-TIME SETUP

### Step 1: Greet and ask for their name

Say something like:
> "⚔️ Welcome, adventurer. Before we forge your Quest Log, I need one thing: **what's your name?**"

Wait for their name. Use it to personalize the app title (e.g. "Mira's Quest Log").

### Step 2: Ask for their to-do list

Say:
> "Now paste your to-do list for this week — however messy, however long. Bullet points, paragraphs, chaotic stream of consciousness — all welcome. I'll handle the rest."

Wait for their list.

### Step 3: Generate the quest log HTML

Follow the **Quest Translation Rules** below to transform their list into quests, then write the complete HTML to `~/Desktop/quest-log.html`.

Use the **HTML Template** at the bottom of this skill — replace `YOUR_NAME` with their name and `REPLACE_WITH_QUESTS` with the generated QUESTS array.

### Step 4: Build the native macOS app

Run this exact sequence of bash commands:

**A. Write the Swift source:**
```bash
mkdir -p /tmp/questlog-build
cat > /tmp/questlog-build/main.swift << 'SWIFT'
import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let width: CGFloat = 820
        let height: CGFloat = 900
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let x = screenFrame.midX - width / 2
        let y = screenFrame.midY - height / 2

        window = NSWindow(
            contentRect: NSRect(x: x, y: y, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Quest Log"
        window.minSize = NSSize(width: 400, height: 500)

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.autoresizingMask = [.width, .height]
        window.contentView = webView

        let htmlPath = NSString(string: "~/Desktop/quest-log.html").expandingTildeInPath
        let url = URL(fileURLWithPath: htmlPath)
        webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())

        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
SWIFT
```

**B. Compile:**
```bash
cd /tmp/questlog-build && swiftc main.swift -framework Cocoa -framework WebKit -o QuestLogBin
```

If this fails, check that Xcode Command Line Tools are installed: `xcode-select --install`

**C. Bundle the .app:**
```bash
rm -rf ~/Desktop/QuestLog.app
mkdir -p ~/Desktop/QuestLog.app/Contents/MacOS
mkdir -p ~/Desktop/QuestLog.app/Contents/Resources
cp /tmp/questlog-build/QuestLogBin ~/Desktop/QuestLog.app/Contents/MacOS/QuestLog
```

**D. Write Info.plist** (replace `NAME_HERE` with the user's name):
```bash
cat > ~/Desktop/QuestLog.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>QuestLog</string>
  <key>CFBundleIdentifier</key><string>com.questlog.app</string>
  <key>CFBundleName</key><string>Quest Log</string>
  <key>CFBundleDisplayName</key><string>Quest Log</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>LSMinimumSystemVersion</key><string>12.0</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
EOF
```

**E. Generate the sword icon:**
```bash
python3 << 'PYEOF'
import struct, zlib, os, math, random

def png_chunk(t, d):
    c = t + d
    return struct.pack('>I', len(d)) + c + struct.pack('>I', zlib.crc32(c) & 0xffffffff)

def make_png(w, h, pixels):
    raw = b''
    for row in pixels:
        raw += b'\x00' + bytes(row)
    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = png_chunk(b'IHDR', struct.pack('>IIBBBBB', w, h, 8, 2, 0, 0, 0))
    idat = png_chunk(b'IDAT', zlib.compress(raw, 9))
    iend = png_chunk(b'IEND', b'')
    return sig + ihdr + idat + iend

size = 512
cx, cy = size//2, size//2
pixels = []
rng = random.Random(42)
star_set = set()
for _ in range(120):
    star_set.add((rng.randint(0, size-1), rng.randint(0, size-1)))

for y in range(size):
    row = []
    for x in range(size):
        dx, dy = x - cx, y - cy
        dist = math.sqrt(dx*dx + dy*dy)
        r, g, b = 13, 10, 26
        if dist < 240:
            t = max(0, 1 - dist/240)
            r = int(r + t*50); g = int(g + t*15); b = int(b + t*70)
        if 200 < dist < 218:
            t = 1 - abs(dist - 209) / 9
            r = int(r*(1-t) + 251*t); g = int(g*(1-t) + 191*t); b = int(b*(1-t) + 36*t)
        if (x, y) in star_set and dist > 60:
            r = min(255, r+180); g = min(255, g+180); b = min(255, b+180)
        bw = 13; tip_y = cy - 155; guard_y = cy + 25; taper_h = 35
        if tip_y <= y <= tip_y + taper_h:
            tp = (y - tip_y) / taper_h
            half = int(bw/2 * tp)
            if abs(dx) <= half:
                t = 1 - abs(dx)/max(half,1)
                r = int(r*(1-t)+210*t); g = int(g*(1-t)+205*t); b = int(b*(1-t)+255*t)
                if abs(dx) <= 2: r=min(255,r+30); g=min(255,g+30); b=min(255,b+30)
        elif tip_y + taper_h < y < guard_y:
            if abs(dx) <= bw//2:
                t = 1 - abs(dx)/(bw//2)
                r = int(r*(1-t)+210*t); g = int(g*(1-t)+205*t); b = int(b*(1-t)+255*t)
                if abs(dx) <= 2: r=min(255,r+30); g=min(255,g+30); b=min(255,b+30)
        gy_center = guard_y; gw = 60; gh = 10
        if abs(dy - (gy_center - cy)) < gh and abs(dx) < gw:
            t = (1 - abs(dy-(gy_center-cy))/gh) * (1 - abs(dx)/gw*0.3)
            r = int(r*(1-t)+251*t); g = int(g*(1-t)+191*t); b = int(b*(1-t)+36*t)
        hw = 9; hb = guard_y; he = cy + 120
        if hb < y < he and abs(dx) < hw//2:
            t = 0.7
            r = int(r*(1-t)+100*t); g = int(g*(1-t)+65*t); b = int(b*(1-t)+30*t)
            if (y - hb) % 12 < 3:
                r = int(r*0.7+180*0.3); g = int(g*0.7+130*0.3); b = int(b*0.7+20*0.3)
        pcy = cy + 128
        if math.sqrt(dx*dx + (y-pcy)**2) < 18:
            t = 0.9
            r = int(r*(1-t)+251*t); g = int(g*(1-t)+191*t); b = int(b*(1-t)+36*t)
        row.extend([min(255,max(0,r)), min(255,max(0,g)), min(255,max(0,b))])
    pixels.append(row)

out = os.path.expanduser('~/Desktop/QuestLog.app/Contents/Resources/AppIcon.png')
with open(out, 'wb') as f:
    f.write(make_png(size, size, pixels))
PYEOF
```

**F. Convert to .icns:**
```bash
ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"
SRC=~/Desktop/QuestLog.app/Contents/Resources/AppIcon.png
for size in 16 32 64 128 256 512; do
  sips -z $size $size "$SRC" --out "$ICONSET/icon_${size}x${size}.png" > /dev/null 2>&1
  sips -z $((size*2)) $((size*2)) "$SRC" --out "$ICONSET/icon_${size}x${size}@2x.png" > /dev/null 2>&1
done
iconutil -c icns "$ICONSET" -o ~/Desktop/QuestLog.app/Contents/Resources/AppIcon.icns
```

**G. Launch it:**
```bash
open ~/Desktop/QuestLog.app
```

### Step 5: Give the user their instructions

Tell them:
> "⚔️ **YOUR_NAME's Quest Log is ready.**
>
> 🗡️ **To add it to your dock:** right-click the app icon while it's open → Options → Keep in Dock. Or drag QuestLog.app from your Desktop to the dock.
>
> 🧙 **To update it each week:** come back here and say **"roll for initiative"** — I'll ask for your new to-do list and refresh everything instantly.
>
> 📜 If macOS says the app is from an unidentified developer, go to System Settings → Privacy & Security → Open Anyway."

---

## WEEKLY RITUAL — "Roll for Initiative"

When the user says "roll for initiative":

1. Say:
   > "🎲 **Initiative rolled.** A new campaign begins.
   >
   > Paste your quest list for this week, adventurer. Bullet points, chaos, stream of consciousness — whatever you've got."

2. Wait for their list.

3. Follow the **Quest Translation Rules** below to transform it.

4. Write the new HTML to `~/Desktop/quest-log.html` (overwrite the old one). When generating the HTML, replace `REPLACE_WITH_WEEK_KEY` with the ISO week string for the current week, e.g. `'2026-W21'`. Use `new Date()` to calculate it: year + `-W` + zero-padded ISO week number. This key triggers an automatic weekly reset (clears checked tasks, weekly XP, quest bonuses) while **preserving total XP and total quests completed** — the user's level never goes backward.

5. Run:
   ```bash
   open ~/Desktop/quest-log.html
   ```
   (No need to rebuild the app — it always loads from the same HTML file.)

6. Say:
   > "⚔️ Your quests for the week have been inscribed. The campaign begins. May your rolls be high and your deadlines merciful. 🎲"

---

## Quest Translation Rules

### Grouping
Cluster the user's to-do items into logical quest categories. Typical groupings:
- Each major work stream = one quest
- Sub-bullets under a parent = subtasks
- Vague items ("figure out X", "ask Y about Z") are fine — keep them
- Aim for 4–8 quests total; too many makes the log overwhelming

### Quest naming
Format: **"The [Dramatic Adjective/Name] [Noun]"**
Examples: "The Wayfinder Trials", "The Arcane Artifact", "The Tangelo Mysteries"
Make it recognizable — the user should know which real project it maps to.

### Language translation
| Real world | Quest language |
|---|---|
| Meeting | War council / Summoning |
| Email / message | Raven / dispatch / scroll |
| Document / page | Tome, grimoire, charter, codex |
| Update something | Restore / revise / reforge |
| Waiting on someone | "The scroll is held by [name]" |
| Ask someone | Seek counsel from [name] |
| Slack | The communications crystal |
| Monday.com / Jira | The registry / the ledger |
| Ticket queue | The scroll backlog |
| Investigate / figure out | Divine / decipher / unravel the mystery |
| Fix a bug | Lift the curse / mend the breach |
| Platform or tool | Its real name is fine, light flavor optional |

### Quest icons
- ⚔️ certifications, training, high-stakes deliverables
- 🏰 operations, structured programs, onboarding
- 🔮 unclear/exploratory work, mystery tasks
- 📜 documentation, follow-ups, writing
- 🧙 strategy, creative, or planning work
- 🏕️ events, external things, expeditions
- 🧗 stretch goals, growth programs, challenges
- 🔄 recurring or rotation tasks
- 🍊 always use for anything Tangelo-related

---

## HTML Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>YOUR_NAME's Quest Log</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;700&family=Nunito:wght@400;500;600;700&display=swap');
  :root {
    --bg-deep:#0d0a1a;--bg-card:#151028;--purple-light:#7c5cbf;--purple-mid:#5b3fa0;
    --teal:#4ecdc4;--teal-dark:#2a9d8f;--gold:#fbbf24;--gold-light:#fde68a;
    --text:#e8e0ff;--text-muted:#9d8ec4;--complete-glow:#4ecdc4;
    --xp-color:#a78bfa;--xp-fill:#7c3aed;
  }
  *{box-sizing:border-box;margin:0;padding:0;}
  body{background:var(--bg-deep);color:var(--text);font-family:'Nunito',sans-serif;min-height:100vh;padding:24px 16px 60px;background-image:radial-gradient(ellipse at 20% 20%,rgba(124,92,191,.15) 0%,transparent 50%),radial-gradient(ellipse at 80% 80%,rgba(78,205,196,.1) 0%,transparent 50%);}
  .stars{position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:0;overflow:hidden;}
  .star-dot{position:absolute;background:white;border-radius:50%;animation:twinkle var(--dur,3s) ease-in-out infinite;}
  @keyframes twinkle{0%,100%{opacity:.1;transform:scale(1)}50%{opacity:.8;transform:scale(1.3)}}
  .content{position:relative;z-index:1;max-width:780px;margin:0 auto;}
  .header{text-align:center;padding:28px 0 20px;}
  .header-title{font-family:'Cinzel',serif;font-size:2rem;font-weight:700;background:linear-gradient(135deg,var(--gold) 0%,var(--gold-light) 50%,var(--teal) 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;letter-spacing:.05em;margin-bottom:4px;}
  .header-sub{color:var(--text-muted);font-size:.9rem;letter-spacing:.08em;text-transform:uppercase;}
  .sparkle-row{font-size:1.2rem;margin:8px 0;letter-spacing:6px;}
  .char-card{background:var(--bg-card);border:1px solid rgba(167,139,250,0.4);border-radius:16px;padding:18px 22px;margin-bottom:16px;position:relative;overflow:hidden;}
  .char-card::before{content:'';position:absolute;inset:0;background:linear-gradient(135deg,rgba(124,92,191,.08),rgba(167,139,250,.04));}
  .char-top{display:flex;align-items:center;gap:16px;margin-bottom:14px;position:relative;}
  .level-badge{width:56px;height:56px;flex-shrink:0;background:linear-gradient(135deg,#4c1d95,#6d28d9);border:2px solid var(--xp-color);border-radius:12px;display:flex;flex-direction:column;align-items:center;justify-content:center;box-shadow:0 0 16px rgba(124,92,191,0.5);}
  .level-num{font-family:'Cinzel',serif;font-size:1.3rem;font-weight:700;color:var(--gold-light);line-height:1;}
  .level-lbl{font-size:0.55rem;color:var(--xp-color);letter-spacing:.08em;text-transform:uppercase;margin-top:1px;}
  .char-info{flex:1;}
  .char-title{font-family:'Cinzel',serif;font-size:1rem;font-weight:600;color:var(--gold-light);margin-bottom:2px;}
  .char-xp-row{display:flex;justify-content:space-between;align-items:center;font-size:0.72rem;color:var(--text-muted);margin-bottom:6px;}
  .char-xp-row span:last-child{color:var(--xp-color);font-weight:700;}
  .xp-bar-wrap{background:rgba(255,255,255,.07);border-radius:999px;height:8px;overflow:hidden;}
  .xp-bar-fill{height:100%;border-radius:999px;background:linear-gradient(90deg,#6d28d9,#a78bfa);transition:width .6s cubic-bezier(.4,0,.2,1);position:relative;overflow:hidden;}
  .xp-bar-fill::after{content:'';position:absolute;top:0;left:-100%;width:100%;height:100%;background:linear-gradient(90deg,transparent,rgba(255,255,255,.35),transparent);animation:shimmer 2s infinite;}
  .weekly-xp-strip{display:flex;gap:8px;position:relative;}
  .wxp-box{flex:1;background:rgba(255,255,255,.04);border:1px solid rgba(167,139,250,.2);border-radius:10px;padding:8px 12px;text-align:center;}
  .wxp-val{font-family:'Cinzel',serif;font-size:1.1rem;font-weight:700;color:var(--xp-color);}
  .wxp-lbl{font-size:0.62rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.06em;margin-top:1px;}
  .overall-progress{background:var(--bg-card);border:1px solid rgba(124,92,191,.3);border-radius:16px;padding:18px 22px;margin-bottom:16px;position:relative;overflow:hidden;}
  .overall-progress::before{content:'';position:absolute;inset:0;background:linear-gradient(135deg,rgba(124,92,191,.05),rgba(78,205,196,.05));}
  .progress-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:10px;position:relative;}
  .progress-label{font-family:'Cinzel',serif;font-size:.8rem;letter-spacing:.1em;color:var(--gold);text-transform:uppercase;}
  .progress-pct{font-weight:700;font-size:1.1rem;color:var(--teal);}
  .progress-bar-wrap{background:rgba(255,255,255,.07);border-radius:999px;height:12px;overflow:hidden;position:relative;}
  .progress-bar-fill{height:100%;border-radius:999px;background:linear-gradient(90deg,var(--purple-mid),var(--teal));transition:width .5s cubic-bezier(.4,0,.2,1);position:relative;overflow:hidden;}
  .progress-bar-fill::after{content:'';position:absolute;top:0;left:-100%;width:100%;height:100%;background:linear-gradient(90deg,transparent,rgba(255,255,255,.3),transparent);animation:shimmer 2s infinite;}
  @keyframes shimmer{to{left:200%;}}
  .reward-banner{display:none;background:linear-gradient(135deg,#2a1a5e,#1a3a3a);border:2px solid var(--gold);border-radius:16px;padding:20px 24px;text-align:center;margin-bottom:16px;animation:glow-pulse 2s ease-in-out infinite;}
  .reward-banner.show{display:block;}
  @keyframes glow-pulse{0%,100%{box-shadow:0 0 20px rgba(251,191,36,.3)}50%{box-shadow:0 0 40px rgba(251,191,36,.6),0 0 60px rgba(78,205,196,.3)}}
  .reward-text{font-family:'Cinzel',serif;font-size:1.1rem;color:var(--gold-light);line-height:1.6;}
  .levelup-overlay{display:none;position:fixed;inset:0;z-index:1000;background:rgba(13,10,26,.85);backdrop-filter:blur(4px);align-items:center;justify-content:center;flex-direction:column;gap:12px;animation:fadein .3s ease;}
  .levelup-overlay.show{display:flex;}
  @keyframes fadein{from{opacity:0}to{opacity:1}}
  .levelup-box{background:linear-gradient(135deg,#2d1b69,#1a3a3a);border:2px solid var(--gold);border-radius:20px;padding:40px 56px;text-align:center;animation:levelup-pop .4s cubic-bezier(.175,.885,.32,1.275);box-shadow:0 0 60px rgba(251,191,36,.4),0 0 120px rgba(124,92,191,.3);}
  @keyframes levelup-pop{from{transform:scale(.7);opacity:0}to{transform:scale(1);opacity:1}}
  .levelup-title{font-family:'Cinzel',serif;font-size:2rem;font-weight:700;color:var(--gold);margin-bottom:8px;letter-spacing:.08em;}
  .levelup-sub{font-family:'Cinzel',serif;font-size:1.1rem;color:var(--gold-light);margin-bottom:4px;}
  .levelup-rank{font-size:1.4rem;color:var(--xp-color);font-weight:700;margin:8px 0;}
  .levelup-dismiss{margin-top:20px;font-size:.8rem;color:var(--text-muted);cursor:pointer;text-transform:uppercase;letter-spacing:.1em;}
  .levelup-dismiss:hover{color:var(--text);}
  .xp-float{position:fixed;pointer-events:none;z-index:999;font-family:'Cinzel',serif;font-weight:700;font-size:.85rem;color:var(--xp-color);text-shadow:0 0 8px rgba(167,139,250,.8);animation:xp-rise 1.2s ease-out forwards;}
  @keyframes xp-rise{0%{opacity:1;transform:translateY(0) scale(1)}100%{opacity:0;transform:translateY(-60px) scale(.8)}}
  .quest-card{background:var(--bg-card);border:1px solid rgba(124,92,191,.25);border-radius:16px;margin-bottom:14px;overflow:hidden;transition:border-color .3s,box-shadow .3s;}
  .quest-card.complete{border-color:var(--complete-glow);box-shadow:0 0 24px rgba(78,205,196,.2);}
  .quest-header{display:flex;align-items:center;justify-content:space-between;padding:14px 18px;cursor:pointer;user-select:none;gap:12px;}
  .quest-header:hover{background:rgba(255,255,255,.03);}
  .quest-left{display:flex;align-items:center;gap:12px;flex:1;min-width:0;}
  .quest-icon{font-size:1.3rem;flex-shrink:0;}
  .quest-name-wrap{flex:1;min-width:0;}
  .quest-name{font-family:'Cinzel',serif;font-size:.82rem;font-weight:600;letter-spacing:.06em;color:var(--gold-light);text-transform:uppercase;line-height:1.3;}
  .quest-meta{display:flex;gap:6px;align-items:center;margin-top:3px;}
  .quest-complete-badge{display:none;font-size:.65rem;background:var(--teal-dark);color:white;padding:1px 7px;border-radius:999px;letter-spacing:.05em;}
  .quest-card.complete .quest-complete-badge{display:block;}
  .quest-xp-tag{font-size:.65rem;color:var(--xp-color);background:rgba(124,92,191,.15);padding:1px 7px;border-radius:999px;}
  .quest-right{display:flex;align-items:center;gap:8px;flex-shrink:0;}
  .quest-mini-progress{font-size:.75rem;color:var(--text-muted);font-weight:600;}
  .quest-card.complete .quest-mini-progress{color:var(--teal);}
  .chevron{color:var(--text-muted);transition:transform .3s;font-size:.75rem;}
  .quest-card.open .chevron{transform:rotate(180deg);}
  .quest-prog-bar{height:3px;background:rgba(255,255,255,.07);}
  .quest-prog-fill{height:100%;background:linear-gradient(90deg,var(--purple-light),var(--teal));transition:width .4s ease;}
  .quest-card.complete .quest-prog-fill{background:var(--teal);}
  .task-list{display:none;padding:10px 18px 14px;border-top:1px solid rgba(255,255,255,.06);}
  .quest-card.open .task-list{display:block;}
  .task-item{display:flex;align-items:flex-start;gap:10px;padding:6px 8px;border-radius:8px;cursor:pointer;transition:background .15s;margin-bottom:2px;position:relative;}
  .task-item:hover{background:rgba(255,255,255,.04);}
  .task-item.done{opacity:.5;}
  .task-cb{width:18px;height:18px;border:2px solid var(--purple-light);border-radius:4px;flex-shrink:0;margin-top:2px;display:flex;align-items:center;justify-content:center;transition:all .2s;}
  .task-item.done .task-cb{background:var(--teal);border-color:var(--teal);}
  .task-cb-check{display:none;color:white;font-size:11px;font-weight:700;}
  .task-item.done .task-cb-check{display:block;}
  .task-text{font-size:.88rem;line-height:1.4;color:var(--text);flex:1;}
  .task-item.done .task-text{text-decoration:line-through;color:var(--text-muted);}
  .task-xp{font-size:.65rem;color:var(--xp-color);flex-shrink:0;margin-top:3px;opacity:.7;}
  .subtask-list{padding-left:16px;}
  .subtask-item{display:flex;align-items:flex-start;gap:8px;padding:4px 8px;border-radius:6px;cursor:pointer;transition:background .15s;position:relative;}
  .subtask-item:hover{background:rgba(255,255,255,.04);}
  .subtask-item.done{opacity:.5;}
  .subtask-cb{width:14px;height:14px;border:2px solid rgba(124,92,191,.6);border-radius:3px;flex-shrink:0;margin-top:3px;display:flex;align-items:center;justify-content:center;transition:all .2s;}
  .subtask-item.done .subtask-cb{background:var(--teal-dark);border-color:var(--teal-dark);}
  .subtask-cb-check{display:none;color:white;font-size:9px;font-weight:700;}
  .subtask-item.done .subtask-cb-check{display:block;}
  .subtask-text{font-size:.8rem;color:var(--text-muted);line-height:1.4;flex:1;}
  .subtask-item.done .subtask-text{text-decoration:line-through;}
  .subtask-xp{font-size:.6rem;color:var(--xp-color);flex-shrink:0;margin-top:4px;opacity:.6;}
</style>
</head>
<body>
<div class="stars" id="stars"></div>
<div class="levelup-overlay" id="levelup-overlay">
  <div class="levelup-box">
    <div class="levelup-title">⚔️ LEVEL UP! ⚔️</div>
    <div class="levelup-sub">You have ascended to</div>
    <div class="levelup-rank" id="levelup-rank"></div>
    <div style="color:var(--text-muted);font-size:.85rem;margin-top:8px" id="levelup-flavor"></div>
    <div class="levelup-dismiss" onclick="document.getElementById('levelup-overlay').classList.remove('show')">[ tap to continue your quest ]</div>
  </div>
</div>
<div class="content">
  <div class="header">
    <div class="sparkle-row">⚔️ 🧙 ⚔️ 🧙 ⚔️</div>
    <div class="header-title">YOUR_NAME's Quest Log</div>
    <div class="header-sub" id="week-label">The Adventurer's Chronicle</div>
    <div class="sparkle-row">🗡️ ✦ 🛡️ ✦ 🗡️</div>
  </div>
  <div class="char-card">
    <div class="char-top">
      <div class="level-badge">
        <div class="level-num" id="char-level">1</div>
        <div class="level-lbl">Level</div>
      </div>
      <div class="char-info">
        <div class="char-title" id="char-title">Novice Adventurer</div>
        <div class="char-xp-row"><span>XP to next level</span><span id="char-xp-label">0 / 100 XP</span></div>
        <div class="xp-bar-wrap"><div class="xp-bar-fill" id="xp-bar" style="width:0%"></div></div>
      </div>
    </div>
    <div class="weekly-xp-strip">
      <div class="wxp-box"><div class="wxp-val" id="wxp-week">0</div><div class="wxp-lbl">⚔️ This Week's XP</div></div>
      <div class="wxp-box"><div class="wxp-val" id="wxp-total">0</div><div class="wxp-lbl">🏆 Total XP Earned</div></div>
      <div class="wxp-box"><div class="wxp-val" id="wxp-quests">0</div><div class="wxp-lbl">📜 Quests Completed</div></div>
    </div>
  </div>
  <div class="overall-progress">
    <div class="progress-header">
      <span class="progress-label">⚔️ Weekly Campaign</span>
      <span class="progress-pct" id="overall-pct">0%</span>
    </div>
    <div class="progress-bar-wrap"><div class="progress-bar-fill" id="overall-bar" style="width:0%"></div></div>
  </div>
  <div class="reward-banner" id="reward-banner">
    <div class="reward-text">🏆 ✨ ALL QUESTS COMPLETE ✨ 🏆<br><br><strong>The realm is saved. The party rests. You have earned your reprieve, adventurer.</strong><br>Close your grimoire and rest well. 🌙</div>
  </div>
  <div id="quests"></div>
</div>
<script>
const XP_TASK=10,XP_SUBTASK=5,XP_QUEST=25,XP_ALL=100;
const LEVELS=[
  {level:1,title:'Novice Adventurer',xp:0,flavor:'Every legend starts somewhere.'},
  {level:2,title:'Apprentice Hero',xp:100,flavor:'The road ahead grows clearer.'},
  {level:3,title:'Journeyman',xp:250,flavor:"You've earned your first scars."},
  {level:4,title:'Adept',xp:500,flavor:'Lesser foes tremble at your approach.'},
  {level:5,title:'Veteran',xp:850,flavor:'Campaigns have shaped your character.'},
  {level:6,title:'Champion',xp:1300,flavor:'The realm knows your name.'},
  {level:7,title:'Master',xp:1850,flavor:'Few can match your discipline.'},
  {level:8,title:'Archmage',xp:2500,flavor:'You bend reality to your will.'},
  {level:9,title:'Legendary',xp:3300,flavor:'Songs are sung of your deeds.'},
  {level:10,title:'Mythic Hero',xp:4200,flavor:'You have become the stuff of legend.'},
];
function getLevelData(xp){let c=LEVELS[0],n=LEVELS[1];for(let i=0;i<LEVELS.length;i++){if(xp>=LEVELS[i].xp){c=LEVELS[i];n=LEVELS[i+1]||null;}}return{current:c,next:n};}
const QUESTS=[REPLACE_WITH_QUESTS];
const WEEK_KEY='REPLACE_WITH_WEEK_KEY';
let checked=JSON.parse(localStorage.getItem('qlq-checked')||'{}');
let openState=JSON.parse(localStorage.getItem('qlq-open')||'{}');
let totalXp=parseInt(localStorage.getItem('qlq-total-xp')||'0');
let weeklyXp=parseInt(localStorage.getItem('qlq-weekly-xp')||'0');
let questBonuses=JSON.parse(localStorage.getItem('qlq-quest-bonuses')||'[]');
let allBonus=localStorage.getItem('qlq-all-bonus')==='true';
let totalQuestsCompleted=parseInt(localStorage.getItem('qlq-total-quests')||'0');
const storedWeek=localStorage.getItem('qlq-week-key');
if(storedWeek!==null&&storedWeek!==WEEK_KEY){weeklyXp=0;questBonuses=[];allBonus=false;checked={};openState={};}
localStorage.setItem('qlq-week-key',WEEK_KEY);
function save(){localStorage.setItem('qlq-checked',JSON.stringify(checked));localStorage.setItem('qlq-open',JSON.stringify(openState));localStorage.setItem('qlq-total-xp',totalXp);localStorage.setItem('qlq-weekly-xp',weeklyXp);localStorage.setItem('qlq-quest-bonuses',JSON.stringify(questBonuses));localStorage.setItem('qlq-all-bonus',allBonus);localStorage.setItem('qlq-total-quests',totalQuestsCompleted);}
function awardXp(amt,el){const prev=getLevelData(totalXp).current.level;totalXp+=amt;weeklyXp+=amt;save();if(getLevelData(totalXp).current.level>prev)showLevelUp(getLevelData(totalXp).current.level);if(el)floatXp('+'+amt+' XP',el);}
function floatXp(text,el){const r=el.getBoundingClientRect();const d=document.createElement('div');d.className='xp-float';d.textContent=text;d.style.left=(r.left+r.width/2-20)+'px';d.style.top=(r.top+window.scrollY-10)+'px';document.body.appendChild(d);setTimeout(()=>d.remove(),1300);}
function showLevelUp(lv){const ld=LEVELS.find(l=>l.level===lv)||LEVELS[LEVELS.length-1];document.getElementById('levelup-rank').textContent='Level '+lv+' — '+ld.title;document.getElementById('levelup-flavor').textContent=ld.flavor;document.getElementById('levelup-overlay').classList.add('show');}
function countItems(q){let t=0,d=0;for(const i of q.tasks){if(i.subtasks){for(const s of i.subtasks){t++;if(checked[s.id])d++;}}else{t++;if(checked[i.id])d++;}}return{total:t,done:d};}
function allSubsDone(t){return t.subtasks&&t.subtasks.every(s=>checked[s.id]);}
function questXpValue(q){let xp=0;for(const t of q.tasks){if(t.subtasks)xp+=t.subtasks.length*XP_SUBTASK;else xp+=XP_TASK;}return xp+XP_QUEST;}
function updateCharUI(){const{current,next}=getLevelData(totalXp);document.getElementById('char-level').textContent=current.level;document.getElementById('char-title').textContent=current.title;document.getElementById('wxp-week').textContent=weeklyXp.toLocaleString();document.getElementById('wxp-total').textContent=totalXp.toLocaleString();document.getElementById('wxp-quests').textContent=totalQuestsCompleted;if(next){const xi=totalXp-current.xp,xn=next.xp-current.xp;document.getElementById('char-xp-label').textContent=xi.toLocaleString()+' / '+xn.toLocaleString()+' XP';document.getElementById('xp-bar').style.width=Math.min(100,Math.round(xi/xn*100))+'%';}else{document.getElementById('char-xp-label').textContent='MAX LEVEL';document.getElementById('xp-bar').style.width='100%';}}
function render(){const c=document.getElementById('quests');c.innerHTML='';let gt=0,gd=0;
  for(const q of QUESTS){const{total,done}=countItems(q);gt+=total;gd+=done;const pct=total>0?Math.round(done/total*100):0;const isC=done===total&&total>0;const isO=openState[q.id]!==false;const qxp=questXpValue(q);
    if(isC&&!questBonuses.includes(q.id)){questBonuses.push(q.id);totalQuestsCompleted++;awardXp(XP_QUEST,null);}
    const card=document.createElement('div');card.className='quest-card'+(isC?' complete':'')+(isO?' open':'');card.id='quest-'+q.id;
    let th='';
    for(const t of q.tasks){if(t.subtasks){const pd=allSubsDone(t);th+=`<div class="task-item ${pd?'done':''}" data-task="${t.id}" data-parent="true"><div class="task-cb"><span class="task-cb-check">✓</span></div><div class="task-text">${t.text}</div></div><div class="subtask-list">`;for(const s of t.subtasks)th+=`<div class="subtask-item ${checked[s.id]?'done':''}" data-subtask="${s.id}"><div class="subtask-cb"><span class="subtask-cb-check">✓</span></div><div class="subtask-text">${s.text}</div><span class="subtask-xp">+${XP_SUBTASK}</span></div>`;th+=`</div>`;}else{th+=`<div class="task-item ${checked[t.id]?'done':''}" data-task="${t.id}"><div class="task-cb"><span class="task-cb-check">✓</span></div><div class="task-text">${t.text}</div><span class="task-xp">+${XP_TASK}</span></div>`;}}
    card.innerHTML=`<div class="quest-header" data-quest="${q.id}"><div class="quest-left"><span class="quest-icon">${q.icon}</span><div class="quest-name-wrap"><div class="quest-name">${q.name}</div><div class="quest-meta"><div class="quest-complete-badge">✦ COMPLETE ✦</div><span class="quest-xp-tag">+${qxp} XP</span></div></div></div><div class="quest-right"><span class="quest-mini-progress">${done}/${total}</span><span class="chevron">▼</span></div></div><div class="quest-prog-bar"><div class="quest-prog-fill" style="width:${pct}%"></div></div><div class="task-list">${th}</div>`;
    c.appendChild(card);}
  if(gd===gt&&gt>0&&!allBonus){allBonus=true;awardXp(XP_ALL,null);}
  const op=gt>0?Math.round(gd/gt*100):0;document.getElementById('overall-pct').textContent=op+'%';document.getElementById('overall-bar').style.width=op+'%';document.getElementById('reward-banner').classList.toggle('show',gd===gt&&gt>0);
  updateCharUI();attachListeners();}
function attachListeners(){
  document.querySelectorAll('.quest-header').forEach(h=>{h.addEventListener('click',()=>{const qid=h.dataset.quest;openState[qid]=!document.getElementById('quest-'+qid).classList.contains('open');save();render();});});
  document.querySelectorAll('.task-item:not([data-parent])').forEach(el=>{el.addEventListener('click',()=>{const was=!!checked[el.dataset.task];checked[el.dataset.task]=!was;if(!was)awardXp(XP_TASK,el);else{totalXp=Math.max(0,totalXp-XP_TASK);weeklyXp=Math.max(0,weeklyXp-XP_TASK);}save();render();});});
  document.querySelectorAll('.task-item[data-parent]').forEach(el=>{el.addEventListener('click',()=>{for(const q of QUESTS)for(const t of q.tasks){if(t.id===el.dataset.task&&t.subtasks){const a=t.subtasks.every(s=>checked[s.id]);t.subtasks.forEach(s=>{if(a&&checked[s.id]){totalXp=Math.max(0,totalXp-XP_SUBTASK);weeklyXp=Math.max(0,weeklyXp-XP_SUBTASK);}else if(!a&&!checked[s.id])awardXp(XP_SUBTASK,el);checked[s.id]=!a;});}}save();render();});});
  document.querySelectorAll('.subtask-item').forEach(el=>{el.addEventListener('click',e=>{e.stopPropagation();const was=!!checked[el.dataset.subtask];checked[el.dataset.subtask]=!was;if(!was)awardXp(XP_SUBTASK,el);else{totalXp=Math.max(0,totalXp-XP_SUBTASK);weeklyXp=Math.max(0,weeklyXp-XP_SUBTASK);}save();render();});});}
document.getElementById('week-label').textContent='Week of '+new Date().toLocaleDateString('en-US',{month:'long',day:'numeric',year:'numeric'});
(function stars(){const c=document.getElementById('stars');for(let i=0;i<80;i++){const s=document.createElement('div');s.className='star-dot';const z=Math.random()*2.5+.5;s.style.cssText=`width:${z}px;height:${z}px;left:${Math.random()*100}%;top:${Math.random()*100}%;--dur:${2+Math.random()*4}s;animation-delay:${Math.random()*4}s`;c.appendChild(s);}})();
render();
</script>
</body>
</html>
```

---

## Task ID conventions

Use short, unique, collision-safe IDs. Prefix by quest abbreviation:
- Quest 1 tasks: `q1t1`, `q1t2`, subtasks: `q1t2a`, `q1t2b`
- Quest 2 tasks: `q2t1`, `q2t2`, etc.

The localStorage key `qlq-checked` persists across weeks — it's fine, old IDs just become orphaned and ignored.
