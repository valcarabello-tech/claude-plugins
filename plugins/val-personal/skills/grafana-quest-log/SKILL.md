---
name: grafana-quest-log
description: Grafana/Grot-themed weekly ops dashboard generator. Creates an interactive incident tracker styled like a Grafana dark-mode dashboard with Grot (the robot mascot), Grafana orange palette, observability language, and a tier-up alert overlay. Trigger when the user says /grafana-quest-log, "grot dashboard", "grafana ops dashboard", "deploy ops dashboard", "update grot's dashboard", or pastes a to-do list and wants it rendered in Grafana style. Weekly refresh is triggered by "deploy ops dashboard" or "refresh grot's dashboard".
---

# 🤖 Grafana Quest Log — Setup & Weekly Ritual

This skill does two things:
1. **First-time setup** — builds a Grafana-themed ops dashboard as a native macOS app
2. **Weekly ritual** — triggered by "deploy ops dashboard" — refreshes with new incidents

---

## Detecting which mode to run

- If `~/Desktop/GrotDashboard.app` does **not** exist → run **First-Time Setup**
- If `~/Desktop/GrotDashboard.app` **exists** and the user says "deploy ops dashboard" → run **Weekly Ritual**
- If `~/Desktop/grafana-quest-log.html` exists but the app doesn't → run **First-Time Setup** (rebuild the app)

---

## FIRST-TIME SETUP

### Step 1: Greet and ask for their name

Say:
> "🤖 Grot's dashboard is initializing. Before we deploy, I need one thing: **what's your operator handle?** (your name, basically)"

Wait for their name. Use it to personalize the operator line (e.g. `operator // mira`).

### Step 2: Ask for their incident list

Say:
> "Acknowledged. Now paste your task list for this week — however raw. Bullet points, stream of consciousness, half-finished thoughts. Grot will sort it into incidents."

Wait for their list.

### Step 3: Generate the HTML

Follow the **Incident Translation Rules** below to transform their list, then write the complete HTML to `~/Desktop/grafana-quest-log.html`.

Use the **HTML Template** at the bottom of this skill. Replace `YOUR_NAME` with their name (lowercase) and `REPLACE_WITH_QUESTS` with the generated QUESTS array.

### Step 4: Build the native macOS app

**A. Write the Swift source:**
```bash
mkdir -p /tmp/grotdash-build
cat > /tmp/grotdash-build/main.swift << 'SWIFT'
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
        window.title = "Grot's Ops Dashboard"
        window.minSize = NSSize(width: 400, height: 500)

        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        webView = WKWebView(frame: .zero, configuration: config)
        webView.autoresizingMask = [.width, .height]
        window.contentView = webView

        let htmlPath = NSString(string: "~/Desktop/grafana-quest-log.html").expandingTildeInPath
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
cd /tmp/grotdash-build && swiftc main.swift -framework Cocoa -framework WebKit -o GrotDashBin
```

**C. Bundle the .app:**
```bash
rm -rf ~/Desktop/GrotDashboard.app
mkdir -p ~/Desktop/GrotDashboard.app/Contents/MacOS
mkdir -p ~/Desktop/GrotDashboard.app/Contents/Resources
cp /tmp/grotdash-build/GrotDashBin ~/Desktop/GrotDashboard.app/Contents/MacOS/GrotDashboard
```

**D. Write Info.plist:**
```bash
cat > ~/Desktop/GrotDashboard.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>GrotDashboard</string>
  <key>CFBundleIdentifier</key><string>com.grafana.grotdashboard</string>
  <key>CFBundleName</key><string>Grot's Dashboard</string>
  <key>CFBundleDisplayName</key><string>Grot's Dashboard</string>
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

**E. Generate the Grot icon (orange robot on dark background):**
```bash
python3 << 'PYEOF'
import struct, zlib, os, math

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

for y in range(size):
    row = []
    for x in range(size):
        dx, dy = x - cx, y - cy
        dist = math.sqrt(dx*dx + dy*dy)
        # Dark background
        r, g, b = 17, 18, 23
        # Subtle orange glow from center
        if dist < 220:
            t = max(0, 1 - dist/220) * 0.15
            r = int(r + t*244); g = int(g + t*104)
        # Orange ring
        if 195 < dist < 210:
            t = 1 - abs(dist - 202) / 8
            r = int(r*(1-t) + 244*t); g = int(g*(1-t) + 104*t); b = int(b*(1-t)*t)
        # Robot head (rounded rect)
        hx, hy, hw, hh = cx, cy-30, 100, 80
        if abs(dx) < hw//2 and abs(dy + 30) < hh//2:
            r, g, b = 244, 104, 0
        # Eyes
        for ex in [-22, 22]:
            if math.sqrt((dx-ex)**2 + (dy+20)**2) < 12:
                r, g, b = 17, 18, 23
            if math.sqrt((dx-ex)**2 + (dy+20)**2) < 7:
                r, g, b = 250, 222, 42
        # Mouth
        if abs(dx) < 28 and abs(dy + 45) < 5:
            r, g, b = 17, 18, 23
        # Body
        if abs(dx) < 55 and 10 < dy < 80:
            r, g, b = 200, 80, 0
        # Antenna
        if abs(dx) < 5 and -100 < dy < -65:
            r, g, b = 244, 104, 0
        if math.sqrt(dx**2 + (dy+100)**2) < 10:
            r, g, b = 244, 104, 0
        row.extend([min(255,max(0,r)), min(255,max(0,g)), min(255,max(0,b))])
    pixels.append(row)

out = os.path.expanduser('~/Desktop/GrotDashboard.app/Contents/Resources/AppIcon.png')
with open(out, 'wb') as f:
    f.write(make_png(size, size, pixels))
PYEOF
```

**F. Convert to .icns:**
```bash
ICONSET=$(mktemp -d)/AppIcon.iconset
mkdir -p "$ICONSET"
SRC=~/Desktop/GrotDashboard.app/Contents/Resources/AppIcon.png
for size in 16 32 64 128 256 512; do
  sips -z $size $size "$SRC" --out "$ICONSET/icon_${size}x${size}.png" > /dev/null 2>&1
  sips -z $((size*2)) $((size*2)) "$SRC" --out "$ICONSET/icon_${size}x${size}@2x.png" > /dev/null 2>&1
done
iconutil -c icns "$ICONSET" -o ~/Desktop/GrotDashboard.app/Contents/Resources/AppIcon.icns
```

**G. Launch it:**
```bash
open ~/Desktop/GrotDashboard.app
```

### Step 5: Give the user their instructions

Tell them:
> "🤖 **Grot's Ops Dashboard is deployed.**
>
> 📊 **To dock it:** right-click the app while it's open → Options → Keep in Dock.
>
> 🔄 **To refresh each week:** say **"deploy ops dashboard"** — I'll ingest your new task list and hot-patch the HTML. No rebuild needed.
>
> 🔒 If macOS blocks the app: System Settings → Privacy & Security → Open Anyway."

---

## WEEKLY RITUAL — "Deploy Ops Dashboard"

When the user says "deploy ops dashboard" or "refresh grot's dashboard":

1. Say:
   > "🤖 Grot is standing by. Paste this week's incident list — tasks, to-dos, chaos. All formats accepted."

2. Wait for their list.

3. Follow the **Incident Translation Rules** below.

4. Write the new HTML to `~/Desktop/grafana-quest-log.html` (overwrite). Replace `REPLACE_WITH_WEEK_KEY` with the current ISO week string, e.g. `'2026-W21'`. This triggers the weekly reset (clears checked items and weekly pts) while preserving total pts and tier level.

5. Run:
   ```bash
   open ~/Desktop/grafana-quest-log.html
   ```

6. Say:
   > "🤖 Dashboard deployed. Grot is monitoring. Go resolve some incidents."

---

## Incident Translation Rules

### Grouping
Cluster tasks into logical incident groups. Each major work stream = one incident. Aim for 4–8 incidents.

### Incident naming
Short, operational. Real project name + action category. Examples: "Wayfinder Incident Response", "Onboarding Pipeline", "Tangelo Alert Stream"

### Language translation
| Real world | Grafana/ops flavor |
|---|---|
| Meeting | War room / sync / on-call handoff |
| Email / message | Alert / notification / page |
| Document / page | Service manifest / runbook / spec |
| Update something | Hot-patch / redeploy / push update |
| Waiting on someone | "Pending ack from [name]" |
| Ask someone | Sync with [name] |
| Slack | Comms channel |
| Monday.com / Jira | Service registry / ticket queue |
| Ticket queue | Alert backlog |
| Investigate | Triage / probe / dig into |
| Fix a bug | Patch the regression / resolve the incident |
| Platform or tool | Use real name, light ops flavor optional |

### Incident icons
- 📡 communications, meetings, coordination
- 🏗️ structured programs, onboarding, provisioning
- 📊 data, analysis, leadership, metrics
- 🍊 always use for Tangelo-related work
- ⛺ events, external things, expeditions
- 📈 growth, stretch goals, career programs
- 🔄 recurring or rotation tasks
- 🔧 tooling, engineering, infrastructure
- 🚨 high-priority or on-fire items

---

## HTML Template

```html
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Grot's Ops Dashboard</title>
<style>
  @import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&family=JetBrains+Mono:wght@400;600;700&display=swap');
  :root {
    --bg-deep:#111217;--bg-card:#1a1c23;
    --orange:#F46800;--red:#F2495C;--blue:#5794F2;--green:#73BF69;--yellow:#FADE2A;
    --text:#D9D9D9;--text-muted:#8e8e8e;--border:rgba(255,255,255,.08);
  }
  *{box-sizing:border-box;margin:0;padding:0;}
  body{background:var(--bg-deep);color:var(--text);font-family:'Inter',sans-serif;min-height:100vh;padding:24px 16px 60px;
    background-image:linear-gradient(rgba(244,104,0,.025) 1px,transparent 1px),linear-gradient(90deg,rgba(244,104,0,.025) 1px,transparent 1px);
    background-size:40px 40px;}
  .metric-dots{position:fixed;top:0;left:0;width:100%;height:100%;pointer-events:none;z-index:0;overflow:hidden;}
  .dot{position:absolute;border-radius:50%;animation:blink var(--dur,3s) ease-in-out infinite;}
  @keyframes blink{0%,100%{opacity:.06;transform:scale(1)}50%{opacity:.25;transform:scale(1.6)}}
  .content{position:relative;z-index:1;max-width:780px;margin:0 auto;}
  .header{text-align:center;padding:28px 0 20px;}
  .grot-icon{font-size:2.4rem;display:block;margin-bottom:6px;animation:grot-float 3s ease-in-out infinite;filter:drop-shadow(0 0 14px var(--orange));}
  @keyframes grot-float{0%,100%{transform:translateY(0)}50%{transform:translateY(-5px)}}
  .header-title{font-family:'JetBrains Mono',monospace;font-size:1.55rem;font-weight:700;color:var(--orange);letter-spacing:.04em;margin-bottom:4px;text-shadow:0 0 24px rgba(244,104,0,.35);}
  .header-sub{color:var(--text-muted);font-size:.76rem;letter-spacing:.12em;text-transform:uppercase;font-family:'JetBrains Mono',monospace;}
  .status-row{display:flex;align-items:center;justify-content:center;gap:8px;margin:10px 0 4px;font-size:.74rem;font-family:'JetBrains Mono',monospace;}
  .status-dot{width:7px;height:7px;border-radius:50%;background:var(--green);box-shadow:0 0 6px var(--green);animation:status-blink 2s ease-in-out infinite;}
  @keyframes status-blink{0%,100%{opacity:1}50%{opacity:.3}}
  .status-text{color:var(--green);}
  .char-card{background:var(--bg-card);border:1px solid var(--border);border-top:2px solid var(--orange);border-radius:8px;padding:18px 22px;margin-bottom:14px;position:relative;overflow:hidden;}
  .char-card::before{content:'';position:absolute;top:0;left:0;right:0;height:40px;background:linear-gradient(180deg,rgba(244,104,0,.06),transparent);pointer-events:none;}
  .char-top{display:flex;align-items:center;gap:16px;margin-bottom:14px;}
  .level-badge{width:60px;height:60px;flex-shrink:0;background:rgba(244,104,0,.1);border:1.5px solid var(--orange);border-radius:6px;display:flex;flex-direction:column;align-items:center;justify-content:center;box-shadow:0 0 18px rgba(244,104,0,.25);}
  .level-num{font-family:'JetBrains Mono',monospace;font-size:1.45rem;font-weight:700;color:var(--orange);line-height:1;}
  .level-lbl{font-size:.46rem;color:var(--orange);letter-spacing:.12em;text-transform:uppercase;margin-top:2px;opacity:.7;font-family:'JetBrains Mono',monospace;}
  .char-info{flex:1;}
  .char-name{font-size:.62rem;color:var(--text-muted);letter-spacing:.1em;text-transform:uppercase;font-family:'JetBrains Mono',monospace;margin-bottom:2px;}
  .char-title{font-weight:600;font-size:.95rem;color:var(--text);margin-bottom:6px;}
  .char-xp-row{display:flex;justify-content:space-between;align-items:center;font-size:.7rem;color:var(--text-muted);margin-bottom:6px;font-family:'JetBrains Mono',monospace;}
  .char-xp-row span:last-child{color:var(--orange);font-weight:600;}
  .xp-bar-wrap{background:rgba(255,255,255,.06);border-radius:2px;height:6px;overflow:hidden;}
  .xp-bar-fill{height:100%;border-radius:2px;background:linear-gradient(90deg,var(--orange),var(--yellow));transition:width .6s cubic-bezier(.4,0,.2,1);position:relative;overflow:hidden;}
  .xp-bar-fill::after{content:'';position:absolute;top:0;left:-100%;width:100%;height:100%;background:linear-gradient(90deg,transparent,rgba(255,255,255,.35),transparent);animation:shimmer 2s infinite;}
  @keyframes shimmer{to{left:200%;}}
  .weekly-xp-strip{display:flex;gap:8px;}
  .wxp-box{flex:1;background:rgba(255,255,255,.025);border:1px solid var(--border);border-radius:6px;padding:10px 12px;text-align:center;transition:border-color .2s;}
  .wxp-box:hover{border-color:rgba(244,104,0,.3);}
  .wxp-val{font-family:'JetBrains Mono',monospace;font-size:1.1rem;font-weight:700;color:var(--orange);}
  .wxp-lbl{font-size:.6rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.06em;margin-top:2px;font-family:'JetBrains Mono',monospace;}
  .overall-progress{background:var(--bg-card);border:1px solid var(--border);border-radius:8px;padding:16px 22px;margin-bottom:14px;}
  .progress-header{display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;}
  .progress-label{font-family:'JetBrains Mono',monospace;font-size:.72rem;letter-spacing:.1em;color:var(--text-muted);text-transform:uppercase;}
  .progress-label .arrow{color:var(--orange);}
  .progress-pct{font-weight:700;font-size:1rem;color:var(--text);font-family:'JetBrains Mono',monospace;}
  .progress-bar-wrap{background:rgba(255,255,255,.06);border-radius:2px;height:10px;overflow:hidden;}
  .progress-bar-fill{height:100%;border-radius:2px;background:linear-gradient(90deg,var(--orange),var(--yellow));transition:width .5s cubic-bezier(.4,0,.2,1);position:relative;overflow:hidden;}
  .progress-bar-fill::after{content:'';position:absolute;top:0;left:-100%;width:100%;height:100%;background:linear-gradient(90deg,transparent,rgba(255,255,255,.3),transparent);animation:shimmer 2s infinite;}
  .reward-banner{display:none;background:rgba(115,191,105,.06);border:1px solid rgba(115,191,105,.5);border-radius:8px;padding:16px 20px;text-align:center;margin-bottom:14px;animation:green-pulse 2s ease-in-out infinite;}
  .reward-banner.show{display:block;}
  @keyframes green-pulse{0%,100%{box-shadow:0 0 0 rgba(115,191,105,0)}50%{box-shadow:0 0 20px rgba(115,191,105,.25)}}
  .reward-text{font-family:'JetBrains Mono',monospace;font-size:.82rem;color:var(--green);line-height:1.7;}
  #flash{position:fixed;inset:0;pointer-events:none;z-index:850;opacity:0;background:radial-gradient(ellipse at center,rgba(244,104,0,.35),rgba(242,73,92,.2));transition:opacity .08s;}
  #flash.pop{opacity:1;}
  @keyframes shake{0%,100%{transform:translate(0,0);}10%{transform:translate(-5px,3px);}20%{transform:translate(5px,-3px);}30%{transform:translate(-4px,4px);}40%{transform:translate(4px,-2px);}50%{transform:translate(-3px,3px);}60%{transform:translate(3px,-1px);}70%{transform:translate(-2px,2px);}80%{transform:translate(2px,-1px);}90%{transform:translate(-1px,1px);}}
  body.shaking{animation:shake .5s ease-out;}
  .emoji-burst{position:fixed;pointer-events:none;z-index:910;font-size:1.4rem;animation:emoji-fly var(--dur,.8s) ease-out forwards;}
  @keyframes emoji-fly{0%{opacity:1;transform:translate(0,0) scale(1);}100%{opacity:0;transform:translate(var(--tx),var(--ty)) scale(.4) rotate(var(--rot));}}
  .levelup-overlay{display:none;position:fixed;inset:0;z-index:1000;background:rgba(17,18,23,.9);backdrop-filter:blur(8px);align-items:center;justify-content:center;flex-direction:column;gap:12px;animation:fadein .3s ease;}
  .levelup-overlay.show{display:flex;}
  @keyframes fadein{from{opacity:0}to{opacity:1}}
  .levelup-box{background:var(--bg-card);border:1px solid var(--orange);border-top:3px solid var(--orange);border-radius:10px;padding:36px 52px;text-align:center;animation:levelup-pop .45s cubic-bezier(.175,.885,.32,1.275);box-shadow:0 0 60px rgba(244,104,0,.4),0 0 100px rgba(244,104,0,.15);position:relative;overflow:hidden;min-width:320px;}
  @keyframes levelup-pop{from{transform:scale(.6) rotate(-2deg);opacity:0}to{transform:scale(1) rotate(0deg);opacity:1}}
  .box-sparkles{position:absolute;inset:0;pointer-events:none;overflow:hidden;}
  .box-spark{position:absolute;width:3px;height:3px;border-radius:50%;animation:box-spark-anim var(--d,1.5s) ease-out var(--delay,0s) infinite;}
  @keyframes box-spark-anim{0%{opacity:0;transform:translate(var(--sx),var(--sy)) scale(0);}30%{opacity:1;transform:translate(calc(var(--sx)*1.4),calc(var(--sy)*1.4)) scale(1);}100%{opacity:0;transform:translate(calc(var(--sx)*2.5),calc(var(--sy)*2.5)) scale(0);}}
  .alert-chip{font-family:'JetBrains Mono',monospace;font-size:.6rem;letter-spacing:.2em;color:var(--red);background:rgba(242,73,92,.12);border:1px solid var(--red);display:inline-block;padding:3px 12px;border-radius:3px;margin-bottom:10px;}
  .levelup-title{font-family:'JetBrains Mono',monospace;font-size:1.5rem;font-weight:700;color:var(--text);margin:6px 0 2px;text-shadow:0 0 20px rgba(244,104,0,.5);}
  .levelup-grot{font-size:2.2rem;margin:10px 0;animation:grot-bounce 1s ease-in-out infinite alternate;}
  @keyframes grot-bounce{from{transform:translateY(0)}to{transform:translateY(-7px)}}
  .levelup-sub{font-family:'JetBrains Mono',monospace;font-size:.72rem;color:var(--text-muted);text-transform:uppercase;letter-spacing:.1em;margin-bottom:6px;}
  .levelup-rank{font-family:'JetBrains Mono',monospace;font-size:1.05rem;color:var(--orange);font-weight:700;margin:6px 0;animation:rank-glow 1.5s ease-in-out infinite alternate;}
  @keyframes rank-glow{from{text-shadow:0 0 10px rgba(244,104,0,.3)}to{text-shadow:0 0 25px rgba(244,104,0,.9),0 0 50px rgba(244,104,0,.3)}}
  .levelup-flavor{color:var(--text-muted);font-size:.78rem;margin-top:6px;font-style:italic;}
  .levelup-dismiss{margin-top:20px;font-size:.68rem;color:var(--text-muted);cursor:pointer;text-transform:uppercase;letter-spacing:.15em;border:1px solid var(--border);border-radius:4px;padding:8px 20px;display:inline-block;transition:all .2s;font-family:'JetBrains Mono',monospace;}
  .levelup-dismiss:hover{background:rgba(255,255,255,.05);color:var(--text);border-color:var(--orange);}
  @keyframes badge-pop{0%{transform:scale(1)}40%{transform:scale(1.4)}70%{transform:scale(.9)}100%{transform:scale(1)}}
  .level-badge.popping{animation:badge-pop .5s cubic-bezier(.175,.885,.32,1.275);}
  .xp-float{position:fixed;pointer-events:none;z-index:999;font-family:'JetBrains Mono',monospace;font-weight:700;font-size:.78rem;color:var(--orange);text-shadow:0 0 8px rgba(244,104,0,.8);animation:xp-rise 1.2s ease-out forwards;}
  @keyframes xp-rise{0%{opacity:1;transform:translateY(0) scale(1)}100%{opacity:0;transform:translateY(-55px) scale(.8)}}
  .quest-card{background:var(--bg-card);border:1px solid var(--border);border-left:3px solid rgba(244,104,0,.25);border-radius:8px;margin-bottom:10px;overflow:hidden;transition:border-color .3s,box-shadow .3s;}
  .quest-card.complete{border-left-color:var(--green);box-shadow:0 0 14px rgba(115,191,105,.1);}
  .quest-header{display:flex;align-items:center;justify-content:space-between;padding:13px 16px;cursor:pointer;user-select:none;gap:12px;}
  .quest-header:hover{background:rgba(255,255,255,.02);}
  .quest-left{display:flex;align-items:center;gap:12px;flex:1;min-width:0;}
  .quest-icon{font-size:1.15rem;flex-shrink:0;}
  .quest-name-wrap{flex:1;min-width:0;}
  .quest-name{font-weight:600;font-size:.87rem;color:var(--text);line-height:1.3;}
  .quest-meta{display:flex;gap:6px;align-items:center;margin-top:4px;}
  .quest-complete-badge{display:none;font-size:.58rem;background:rgba(115,191,105,.12);color:var(--green);padding:2px 8px;border-radius:3px;letter-spacing:.08em;border:1px solid rgba(115,191,105,.3);font-family:'JetBrains Mono',monospace;}
  .quest-card.complete .quest-complete-badge{display:block;}
  .quest-xp-tag{font-size:.58rem;color:var(--orange);background:rgba(244,104,0,.08);padding:2px 8px;border-radius:3px;border:1px solid rgba(244,104,0,.2);font-family:'JetBrains Mono',monospace;}
  .quest-right{display:flex;align-items:center;gap:8px;flex-shrink:0;}
  .quest-mini-progress{font-size:.72rem;color:var(--text-muted);font-weight:600;font-family:'JetBrains Mono',monospace;}
  .quest-card.complete .quest-mini-progress{color:var(--green);}
  .chevron{color:var(--text-muted);transition:transform .3s;font-size:.7rem;}
  .quest-card.open .chevron{transform:rotate(180deg);}
  .quest-prog-bar{height:2px;background:rgba(255,255,255,.04);}
  .quest-prog-fill{height:100%;background:linear-gradient(90deg,var(--orange),var(--yellow));transition:width .4s ease;}
  .quest-card.complete .quest-prog-fill{background:var(--green);}
  .task-list{display:none;padding:10px 16px 14px;border-top:1px solid var(--border);}
  .quest-card.open .task-list{display:block;}
  .task-item{display:flex;align-items:flex-start;gap:10px;padding:6px 8px;border-radius:6px;cursor:pointer;transition:background .15s;margin-bottom:2px;}
  .task-item:hover{background:rgba(255,255,255,.03);}
  .task-item.done{opacity:.42;}
  .task-cb{width:16px;height:16px;border:1.5px solid rgba(255,255,255,.18);border-radius:3px;flex-shrink:0;margin-top:2px;display:flex;align-items:center;justify-content:center;transition:all .2s;}
  .task-item.done .task-cb{background:var(--green);border-color:var(--green);}
  .task-cb-check{display:none;color:#111;font-size:10px;font-weight:800;}
  .task-item.done .task-cb-check{display:block;}
  .task-text{font-size:.85rem;line-height:1.45;color:var(--text);flex:1;}
  .task-item.done .task-text{text-decoration:line-through;color:var(--text-muted);}
  .task-xp{font-size:.6rem;color:var(--orange);flex-shrink:0;margin-top:3px;opacity:.65;font-family:'JetBrains Mono',monospace;}
  .subtask-list{padding-left:16px;}
  .subtask-item{display:flex;align-items:flex-start;gap:8px;padding:4px 8px;border-radius:5px;cursor:pointer;transition:background .15s;}
  .subtask-item:hover{background:rgba(255,255,255,.03);}
  .subtask-item.done{opacity:.38;}
  .subtask-cb{width:13px;height:13px;border:1.5px solid rgba(255,255,255,.14);border-radius:2px;flex-shrink:0;margin-top:3px;display:flex;align-items:center;justify-content:center;transition:all .2s;}
  .subtask-item.done .subtask-cb{background:var(--green);border-color:var(--green);}
  .subtask-cb-check{display:none;color:#111;font-size:8px;font-weight:800;}
  .subtask-item.done .subtask-cb-check{display:block;}
  .subtask-text{font-size:.78rem;color:var(--text-muted);line-height:1.4;flex:1;}
  .subtask-item.done .subtask-text{text-decoration:line-through;}
  .subtask-xp{font-size:.58rem;color:var(--orange);flex-shrink:0;margin-top:4px;opacity:.55;font-family:'JetBrains Mono',monospace;}
</style>
</head>
<body>
<canvas id="confetti-canvas" style="position:fixed;inset:0;pointer-events:none;z-index:900;"></canvas>
<div id="flash"></div>
<div class="metric-dots" id="metric-dots"></div>
<div class="levelup-overlay" id="levelup-overlay">
  <div class="levelup-box">
    <div class="box-sparkles" id="box-sparkles"></div>
    <div class="alert-chip">🔴 ALERT FIRING</div>
    <div class="levelup-title">TIER UPGRADE</div>
    <div class="levelup-grot">🤖</div>
    <div class="levelup-sub">Grot has promoted you to</div>
    <div class="levelup-rank" id="levelup-rank"></div>
    <div class="levelup-flavor" id="levelup-flavor"></div>
    <div class="levelup-dismiss" onclick="document.getElementById('levelup-overlay').classList.remove('show')">[ ACK · dismiss alert ]</div>
  </div>
</div>
<div class="content">
  <div class="header">
    <span class="grot-icon">🤖</span>
    <div class="header-title">Grot's Ops Dashboard</div>
    <div class="header-sub" id="week-label">Weekly Incident Tracker</div>
    <div class="status-row"><div class="status-dot"></div><span class="status-text">All systems monitored · Grot is watching</span></div>
  </div>
  <div class="char-card">
    <div class="char-top">
      <div class="level-badge"><div class="level-num" id="char-level">1</div><div class="level-lbl">TIER</div></div>
      <div class="char-info">
        <div class="char-name">operator // YOUR_NAME</div>
        <div class="char-title" id="char-title">Junior SRE</div>
        <div class="char-xp-row"><span>pts to next tier</span><span id="char-xp-label">0 / 100 pts</span></div>
        <div class="xp-bar-wrap"><div class="xp-bar-fill" id="xp-bar" style="width:0%"></div></div>
      </div>
    </div>
    <div class="weekly-xp-strip">
      <div class="wxp-box"><div class="wxp-val" id="wxp-week">0</div><div class="wxp-lbl">📊 Weekly Pts</div></div>
      <div class="wxp-box"><div class="wxp-val" id="wxp-total">0</div><div class="wxp-lbl">📈 Total Pts</div></div>
      <div class="wxp-box"><div class="wxp-val" id="wxp-quests">0</div><div class="wxp-lbl">✅ Incidents Closed</div></div>
    </div>
  </div>
  <div class="overall-progress">
    <div class="progress-header">
      <span class="progress-label"><span class="arrow">▶</span> Weekly Sprint Progress</span>
      <span class="progress-pct" id="overall-pct">0%</span>
    </div>
    <div class="progress-bar-wrap"><div class="progress-bar-fill" id="overall-bar" style="width:0%"></div></div>
  </div>
  <div class="reward-banner" id="reward-banner">
    <div class="reward-text">✅ ALL CLEAR — INCIDENTS RESOLVED<br>Grot gives two thumbs up 🤖👍👍<br>Dashboard is green. You may go touch grass.</div>
  </div>
  <div id="quests"></div>
</div>
<script>
const XP_TASK=10,XP_SUBTASK=5,XP_QUEST=25,XP_ALL=100;
const LEVELS=[
  {level:1,title:'Junior SRE',xp:0,flavor:'First on-call rotation. Grot believes in you.'},
  {level:2,title:'On-Call Responder',xp:100,flavor:'You know where the runbooks are.'},
  {level:3,title:'Dashboard Builder',xp:250,flavor:'Your panels actually have useful titles.'},
  {level:4,title:'Alert Engineer',xp:500,flavor:'You know the difference between warning and critical.'},
  {level:5,title:'SLO Architect',xp:850,flavor:'Error budgets? You eat those for breakfast.'},
  {level:6,title:'Observability Lead',xp:1300,flavor:'The org comes to you when things break.'},
  {level:7,title:'Platform Engineer',xp:1850,flavor:'You wrote the runbook others are reading.'},
  {level:8,title:'Principal SRE',xp:2500,flavor:'Incidents fear you now.'},
  {level:9,title:'Grafana Champion',xp:3300,flavor:'Grot has your portrait on the wall.'},
  {level:10,title:'Grot Ascendant',xp:4200,flavor:'You and Grot are one.'},
];
function getLevelData(xp){let c=LEVELS[0],n=LEVELS[1];for(let i=0;i<LEVELS.length;i++){if(xp>=LEVELS[i].xp){c=LEVELS[i];n=LEVELS[i+1]||null;}}return{current:c,next:n};}
const QUESTS=[REPLACE_WITH_QUESTS];
const WEEK_KEY='REPLACE_WITH_WEEK_KEY';
let checked=JSON.parse(localStorage.getItem('gql-checked')||'{}');
let openState=JSON.parse(localStorage.getItem('gql-open')||'{}');
let totalXp=parseInt(localStorage.getItem('gql-total-xp')||'0');
let weeklyXp=parseInt(localStorage.getItem('gql-weekly-xp')||'0');
let questBonuses=JSON.parse(localStorage.getItem('gql-quest-bonuses')||'[]');
let allBonus=localStorage.getItem('gql-all-bonus')==='true';
let totalQuestsCompleted=parseInt(localStorage.getItem('gql-total-quests')||'0');
const storedWeek=localStorage.getItem('gql-week-key');
if(storedWeek!==null&&storedWeek!==WEEK_KEY){weeklyXp=0;questBonuses=[];allBonus=false;checked={};openState={};}
localStorage.setItem('gql-week-key',WEEK_KEY);
function save(){localStorage.setItem('gql-checked',JSON.stringify(checked));localStorage.setItem('gql-open',JSON.stringify(openState));localStorage.setItem('gql-total-xp',totalXp);localStorage.setItem('gql-weekly-xp',weeklyXp);localStorage.setItem('gql-quest-bonuses',JSON.stringify(questBonuses));localStorage.setItem('gql-all-bonus',allBonus);localStorage.setItem('gql-total-quests',totalQuestsCompleted);}
function awardXp(amt,el){const prev=getLevelData(totalXp).current.level;totalXp+=amt;weeklyXp+=amt;save();if(getLevelData(totalXp).current.level>prev)showLevelUp(getLevelData(totalXp).current.level);if(el)floatXp('+'+amt,el);}
function floatXp(text,el){const r=el.getBoundingClientRect();const d=document.createElement('div');d.className='xp-float';d.textContent=text;d.style.left=(r.left+r.width/2-20)+'px';d.style.top=(r.top+window.scrollY-10)+'px';document.body.appendChild(d);setTimeout(()=>d.remove(),1300);}
const _cvs=document.getElementById('confetti-canvas'),_ctx=_cvs.getContext('2d');let _p=[],_aId=null;function _rsz(){_cvs.width=window.innerWidth;_cvs.height=window.innerHeight;}_rsz();window.addEventListener('resize',_rsz);
const _CL=['#F46800','#FADE2A','#73BF69','#5794F2','#F2495C','#ff9900','#ffffff'];
function _spawnC(n=180){const cx=window.innerWidth/2,cy=window.innerHeight/3;for(let i=0;i<n;i++){const a=Math.random()*Math.PI*2,sp=4+Math.random()*14;_p.push({x:cx,y:cy,vx:Math.cos(a)*sp,vy:Math.sin(a)*sp-(Math.random()*4),color:_CL[Math.floor(Math.random()*_CL.length)],shape:['circle','rect','star'][Math.floor(Math.random()*3)],size:4+Math.random()*8,rot:Math.random()*Math.PI*2,rotV:(Math.random()-.5)*.3,life:1,decay:.012+Math.random()*.012,gravity:.25+Math.random()*.2});}}
function _dStar(x,y,r){_ctx.beginPath();for(let i=0;i<5;i++){const a=(i*4*Math.PI/5)-Math.PI/2,b=((i*4+2)*Math.PI/5)-Math.PI/2;_ctx.lineTo(x+Math.cos(a)*r,y+Math.sin(a)*r);_ctx.lineTo(x+Math.cos(b)*r*.4,y+Math.sin(b)*r*.4);}_ctx.closePath();}
function _aC(){_ctx.clearRect(0,0,_cvs.width,_cvs.height);_p=_p.filter(p=>p.life>0);for(const p of _p){_ctx.save();_ctx.globalAlpha=p.life;_ctx.fillStyle=p.color;_ctx.translate(p.x,p.y);_ctx.rotate(p.rot);if(p.shape==='circle'){_ctx.beginPath();_ctx.arc(0,0,p.size/2,0,Math.PI*2);_ctx.fill();}else if(p.shape==='rect'){_ctx.fillRect(-p.size/2,-p.size/4,p.size,p.size/2);}else{_dStar(0,0,p.size/2);_ctx.fill();}_ctx.restore();p.x+=p.vx;p.y+=p.vy;p.vy+=p.gravity;p.vx*=.99;p.rot+=p.rotV;p.life-=p.decay;}if(_p.length>0)_aId=requestAnimationFrame(_aC);else _ctx.clearRect(0,0,_cvs.width,_cvs.height);}
const _EM=['🤖','📊','📈','⚡','🔔','✅','🎯','🚀','💥','🔥','🍊'];
function _eB(){const badge=document.getElementById('char-level').closest('.level-badge')||document.body;const rect=badge.getBoundingClientRect();const cx=rect.left+rect.width/2,cy=rect.top+rect.height/2;for(let i=0;i<14;i++){const el=document.createElement('div');el.className='emoji-burst';el.textContent=_EM[Math.floor(Math.random()*_EM.length)];const angle=(i/14)*Math.PI*2+(Math.random()-.5)*.4,dist=110+Math.random()*170,tx=Math.cos(angle)*dist,ty=Math.sin(angle)*dist-50;el.style.cssText=`left:${cx}px;top:${cy}px;--tx:${tx}px;--ty:${ty}px;--dur:${.6+Math.random()*.5}s;--rot:${(Math.random()-.5)*720}deg;`;document.body.appendChild(el);setTimeout(()=>el.remove(),1200);}}
function _flash(){const f=document.getElementById('flash');f.classList.add('pop');setTimeout(()=>f.classList.remove('pop'),120);}
function _shake(){document.body.classList.add('shaking');setTimeout(()=>document.body.classList.remove('shaking'),500);}
function _bSparks(){const c=document.getElementById('box-sparkles');c.innerHTML='';for(let i=0;i<16;i++){const s=document.createElement('div');s.className='box-spark';const a=Math.random()*Math.PI*2,r=25+Math.random()*20;s.style.cssText=`left:50%;top:50%;--sx:${Math.cos(a)*r}px;--sy:${Math.sin(a)*r}px;--d:${1+Math.random()}s;--delay:${Math.random()}s;background:${_CL[Math.floor(Math.random()*_CL.length)]}`;c.appendChild(s);}}
function _badgePop(lv){const badge=document.getElementById('char-level').closest('.level-badge');if(!badge)return;badge.classList.remove('popping');void badge.offsetWidth;document.getElementById('char-level').textContent=lv;badge.classList.add('popping');setTimeout(()=>badge.classList.remove('popping'),500);}
function showLevelUp(lv){const ld=LEVELS.find(l=>l.level===lv)||LEVELS[LEVELS.length-1];document.getElementById('levelup-rank').textContent='TIER '+lv+' — '+ld.title.toUpperCase();document.getElementById('levelup-flavor').textContent=ld.flavor;_flash();setTimeout(_shake,50);setTimeout(_eB,80);setTimeout(_eB,300);_spawnC(200);if(_aId)cancelAnimationFrame(_aId);_aC();setTimeout(()=>_badgePop(lv),300);_bSparks();setTimeout(()=>document.getElementById('levelup-overlay').classList.add('show'),600);}
function countItems(q){let t=0,d=0;for(const i of q.tasks){if(i.subtasks){for(const s of i.subtasks){t++;if(checked[s.id])d++;}}else{t++;if(checked[i.id])d++;}}return{total:t,done:d};}
function allSubsDone(t){return t.subtasks&&t.subtasks.every(s=>checked[s.id]);}
function questXpValue(q){let xp=0;for(const t of q.tasks){if(t.subtasks)xp+=t.subtasks.length*XP_SUBTASK;else xp+=XP_TASK;}return xp+XP_QUEST;}
function updateCharUI(){const{current,next}=getLevelData(totalXp);document.getElementById('char-level').textContent=current.level;document.getElementById('char-title').textContent=current.title;document.getElementById('wxp-week').textContent=weeklyXp.toLocaleString();document.getElementById('wxp-total').textContent=totalXp.toLocaleString();document.getElementById('wxp-quests').textContent=totalQuestsCompleted;if(next){const xi=totalXp-current.xp,xn=next.xp-current.xp;document.getElementById('char-xp-label').textContent=xi+' / '+xn+' pts';document.getElementById('xp-bar').style.width=Math.min(100,Math.round(xi/xn*100))+'%';}else{document.getElementById('char-xp-label').textContent='MAX TIER';document.getElementById('xp-bar').style.width='100%';}}
function render(){const c=document.getElementById('quests');c.innerHTML='';let gt=0,gd=0;
  for(const q of QUESTS){const{total,done}=countItems(q);gt+=total;gd+=done;const pct=total>0?Math.round(done/total*100):0;const isC=done===total&&total>0;const isO=openState[q.id]!==false;const qxp=questXpValue(q);
    if(isC&&!questBonuses.includes(q.id)){questBonuses.push(q.id);totalQuestsCompleted++;awardXp(XP_QUEST,null);}
    const card=document.createElement('div');card.className='quest-card'+(isC?' complete':'')+(isO?' open':'');card.id='quest-'+q.id;
    let th='';for(const t of q.tasks){if(t.subtasks){const pd=allSubsDone(t);th+=`<div class="task-item ${pd?'done':''}" data-task="${t.id}" data-parent="true"><div class="task-cb"><span class="task-cb-check">✓</span></div><div class="task-text">${t.text}</div></div><div class="subtask-list">`;for(const s of t.subtasks)th+=`<div class="subtask-item ${checked[s.id]?'done':''}" data-subtask="${s.id}"><div class="subtask-cb"><span class="subtask-cb-check">✓</span></div><div class="subtask-text">${s.text}</div><span class="subtask-xp">+${XP_SUBTASK}</span></div>`;th+=`</div>`;}else th+=`<div class="task-item ${checked[t.id]?'done':''}" data-task="${t.id}"><div class="task-cb"><span class="task-cb-check">✓</span></div><div class="task-text">${t.text}</div><span class="task-xp">+${XP_TASK}</span></div>`;}
    card.innerHTML=`<div class="quest-header" data-quest="${q.id}"><div class="quest-left"><span class="quest-icon">${q.icon}</span><div class="quest-name-wrap"><div class="quest-name">${q.name}</div><div class="quest-meta"><div class="quest-complete-badge">■ RESOLVED</div><span class="quest-xp-tag">+${qxp} pts</span></div></div></div><div class="quest-right"><span class="quest-mini-progress">${done}/${total}</span><span class="chevron">▼</span></div></div><div class="quest-prog-bar"><div class="quest-prog-fill" style="width:${pct}%"></div></div><div class="task-list">${th}</div>`;
    c.appendChild(card);}
  if(gd===gt&&gt>0&&!allBonus){allBonus=true;awardXp(XP_ALL,null);}
  const op=gt>0?Math.round(gd/gt*100):0;document.getElementById('overall-pct').textContent=op+'%';document.getElementById('overall-bar').style.width=op+'%';document.getElementById('reward-banner').classList.toggle('show',gd===gt&&gt>0);
  updateCharUI();attachListeners();}
function attachListeners(){
  document.querySelectorAll('.quest-header').forEach(h=>{h.addEventListener('click',()=>{const qid=h.dataset.quest;openState[qid]=!document.getElementById('quest-'+qid).classList.contains('open');save();render();});});
  document.querySelectorAll('.task-item:not([data-parent])').forEach(el=>{el.addEventListener('click',()=>{const was=!!checked[el.dataset.task];checked[el.dataset.task]=!was;if(!was)awardXp(XP_TASK,el);else{totalXp=Math.max(0,totalXp-XP_TASK);weeklyXp=Math.max(0,weeklyXp-XP_TASK);}save();render();});});
  document.querySelectorAll('.task-item[data-parent]').forEach(el=>{el.addEventListener('click',()=>{for(const q of QUESTS)for(const t of q.tasks){if(t.id===el.dataset.task&&t.subtasks){const a=t.subtasks.every(s=>checked[s.id]);t.subtasks.forEach(s=>{if(a&&checked[s.id]){totalXp=Math.max(0,totalXp-XP_SUBTASK);weeklyXp=Math.max(0,weeklyXp-XP_SUBTASK);}else if(!a&&!checked[s.id])awardXp(XP_SUBTASK,el);checked[s.id]=!a;});}};save();render();});});
  document.querySelectorAll('.subtask-item').forEach(el=>{el.addEventListener('click',e=>{e.stopPropagation();const was=!!checked[el.dataset.subtask];checked[el.dataset.subtask]=!was;if(!was)awardXp(XP_SUBTASK,el);else{totalXp=Math.max(0,totalXp-XP_SUBTASK);weeklyXp=Math.max(0,weeklyXp-XP_SUBTASK);}save();render();});});}
document.getElementById('week-label').textContent='Week of '+new Date().toLocaleDateString('en-US',{month:'long',day:'numeric',year:'numeric'});
(function spawnDots(){const c=document.getElementById('metric-dots');const cols=['#F46800','#5794F2','#73BF69','#FADE2A','#F2495C'];for(let i=0;i<55;i++){const d=document.createElement('div');d.className='dot';const sz=Math.random()*2.5+.6,col=cols[Math.floor(Math.random()*cols.length)];d.style.cssText=`width:${sz}px;height:${sz}px;left:${Math.random()*100}%;top:${Math.random()*100}%;background:${col};--dur:${2+Math.random()*5}s;animation-delay:${Math.random()*5}s`;c.appendChild(d);}})();
render();
</script>
</body>
</html>
```

---

## Task ID conventions

Short, collision-safe IDs prefixed by incident abbreviation:
- Incident 1 tasks: `i1t1`, `i1t2`, subtasks: `i1t2a`, `i1t2b`
- Incident 2 tasks: `i2t1`, `i2t2`, etc.

The localStorage key `gql-checked` persists across weeks — old IDs become orphaned and ignored.
