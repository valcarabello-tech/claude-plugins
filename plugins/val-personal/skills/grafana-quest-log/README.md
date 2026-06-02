# Grafana Quest Log 🐸⚔️

A Grafana-themed DnD-style XP tracker that runs as a native macOS desktop app. Complete weekly quests to earn XP, level up through 100 tiers, and watch Grot evolve from baby blob to full knight.

---

## What it is

- **Self-contained HTML app** — all data (including Grot images) is embedded, no internet needed
- **100 levels** with a power XP curve — early levels come fast, later ones take real effort
- **42 Grot art tiers** — Grot's appearance upgrades every 2–3 levels as you progress
- **Weekly quests** — tasks reset each week; total XP and level progress persists
- **Completed task archiving** — finished tasks and quests collapse out of the way

## Grot images

The 42 Grot progression stickers were generated using **[Build-A-Grot Workshop](https://grot.wardbekker.com/)**, built by Ward Bekker. It's an internal AI image generator that lets you describe a Grot adventure and renders it in various styles (cartoon, pixel art, cyberpunk, watercolor, and more) using either the 3D plush or 2D illustrated Grot as a reference.

The tier sheet was generated with the **Cartoon/Anime** style using a prompt describing Grot's armor progression — starting as a plain baby blob and gradually adding armor pieces, weapons, and a cape until reaching full knight at tier 42.

> To regenerate or extend the Grot tiers, visit [grot.wardbekker.com](https://grot.wardbekker.com/) (requires Grafana SSO). Join **#social-build-a-grot** on Slack to share creations and get inspiration.

---

## Getting started

### Step 1 — Download the HTML file
Download `grafana-quest-log.html` from this repo and save it to `~/Desktop/`.

### Step 2 — Open in a browser (quickest)
```bash
open ~/Desktop/grafana-quest-log.html
```
On first load you'll see a setup wizard — enter your name, pick a tone (Epic / Chill / Grot Mode), set your trigger phrase, and add your first quests.

### Step 3 — Build the macOS app (optional but recommended)
The `.app` wraps the HTML in a native window so it lives in your Dock.

```bash
# Compile the binary
mkdir -p /tmp/gql-build
cat > /tmp/gql-build/main.swift << 'SWIFT'
import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        let width: CGFloat = 820
        let height: CGFloat = 900
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        window = NSWindow(
            contentRect: NSRect(x: screenFrame.midX - width/2, y: screenFrame.midY - height/2, width: width, height: height),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered, defer: false)
        window.title = "Grafana Quest Log"
        window.minSize = NSSize(width: 400, height: 500)
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.websiteDataStore = WKWebsiteDataStore.default()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.autoresizingMask = [.width, .height]
        window.contentView = webView
        let htmlPath = NSString(string: "~/Desktop/grafana-quest-log.html").expandingTildeInPath
        let baseURL = URL(fileURLWithPath: NSString(string: "~/Desktop/").expandingTildeInPath)
        if let html = try? String(contentsOfFile: htmlPath, encoding: .utf8) {
            webView.loadHTMLString(html, baseURL: baseURL)
        } else {
            webView.loadHTMLString("<body style='background:#111;color:#f46800;font-family:sans-serif;padding:40px'><h2>Could not load grafana-quest-log.html</h2><p>Make sure the file exists at ~/Desktop/grafana-quest-log.html</p></body>", baseURL: nil)
        }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ app: NSApplication) -> Bool { return true }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
SWIFT

swiftc /tmp/gql-build/main.swift -framework Cocoa -framework WebKit -o /tmp/gql-build/GrafanaQuestLogBin

# Bundle the app
mkdir -p ~/Desktop/GrafanaQuestLog.app/Contents/{MacOS,Resources}
cp /tmp/gql-build/GrafanaQuestLogBin ~/Desktop/GrafanaQuestLog.app/Contents/MacOS/GrafanaQuestLog
chmod +x ~/Desktop/GrafanaQuestLog.app/Contents/MacOS/GrafanaQuestLog

# Create Info.plist
cat > ~/Desktop/GrafanaQuestLog.app/Contents/Info.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key><string>GrafanaQuestLog</string>
  <key>CFBundleIdentifier</key><string>com.grafana.quest-log</string>
  <key>CFBundleName</key><string>Grafana Quest Log</string>
  <key>CFBundleDisplayName</key><string>Grafana Quest Log</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST
```

Then drag `GrafanaQuestLog.app` from your Desktop into the Dock.

> **macOS Gatekeeper warning?** Right-click the app → **Open** → click Open again. You only need to do this once.

---

## Updating quests via Claude

The quest log is designed to be updated through Claude. During setup, you choose a **trigger phrase** (e.g. "roll for initiative", "time to slay", "grot demands action") — say it to Claude and it runs the skill.

**How it works:**

1. Say your trigger phrase to Claude (or any of: "update my quest log", "new quests", "build my quest log")
2. Claude asks: *"What's on your plate? Brain dump everything."*
3. You list everything — Claude organizes it into quest categories
4. Claude shows you a preview and asks you to confirm
5. Claude edits `~/Desktop/grafana-quest-log.html` directly — you just **refresh the page** and your quests appear

Your XP, level, Grot tier, and completed tasks are never touched — only the quest/task structure changes.

> **Want to change your tone or name after setup?** Click the ⚙️ gear icon in the top right.

> **Need to re-run the setup wizard?** Open the ⚙️ settings panel → scroll to the bottom → **Reset App**.

---

## Windows / Linux

The `.app` bundle is macOS-only, but the HTML file works on any OS in any modern browser.

- **Windows**: Double-click `grafana-quest-log.html` (opens in Edge/Chrome). To pin to taskbar: open it, right-click the Chrome/Edge taskbar icon → "Pin to taskbar", then rename the shortcut to "Grafana Quest Log".
- **Linux**: `xdg-open ~/Desktop/grafana-quest-log.html`. For a launcher, create a `.desktop` file pointing to `chromium --app=file:///home/you/Desktop/grafana-quest-log.html`.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| App shows white screen | Make sure `grafana-quest-log.html` is on your Desktop. Rebuild the binary using the commands above — the binary must be recompiled if you're on a new machine. |
| "App is damaged" / Gatekeeper warning | Right-click → Open → Open. This happens because the binary isn't code-signed. |
| Quests disappeared after refresh | They're still there — the week auto-detects via ISO week number. If they're gone, Claude may have written new SEED_QUESTS. Check the ⚙️ settings. |
| Lost XP / level reset | XP and level are stored in `localStorage`. Clearing browser data or using a different browser will reset them. Use **Export Scroll** (in the ⚙️ panel) to back up. |
| Wizard shows again after quests set | Someone clicked "Reset App" or localStorage was cleared. Run your trigger phrase with Claude to restore quests. |

---

## Level progression

Grot upgrades are marked with ⬆️. XP column is the total XP needed to *reach* that level.

| Level | Title | XP to reach | Grot | Flavor |
|------:|-------|------------:|:----:|--------|
| 1 | Grot's Initiate | 0 | grot-01 ⬆️ | *Every legend starts somewhere. Grot is watching.* |
| 2 | Dashboard Greenhorn | 50 | grot-01 | *You've clicked a panel. Progress.* |
| 3 | Metric Muggle | 100 | grot-01 | *The dashboards speak, but you don't yet hear them.* |
| 4 | Alert Acknowledger | 200 | grot-02 ⬆️ | *FIRING: Your confidence. Status: Pending.* |
| 5 | Log Line Reader | 300 | grot-02 | *You can tell the timestamp from the message. Barely.* |
| 6 | Panel Page | 450 | grot-03 ⬆️ | *You've been assigned a datasource. Try not to break it.* |
| 7 | Query Squire | 600 | grot-03 | *You wrote a PromQL query. It returned something.* |
| 8 | Threshold Trainee | 750 | grot-03 | *Your first alert fired at 3am. You've been warned.* |
| 9 | Trace Foot Soldier | 950 | grot-04 ⬆️ | *The spans are starting to make sense. Sort of.* |
| 10 | Dashboard Journeyman | 1,150 | grot-04 | *You've built something someone else can use.* |
| 11 | Series Seeker | 1,350 | grot-05 ⬆️ | *You know the difference between rate() and irate().* |
| 12 | Grafana Greenhorn | 1,550 | grot-05 | *Grot has given you a name badge.* |
| 13 | Alert Forger | 1,800 | grot-05 | *You've set a P95 alert and it didn't page you immediately.* |
| 14 | Panel Artisan | 2,050 | grot-06 ⬆️ | *Your dashboards no longer make people cry.* |
| 15 | Query Craftsman | 2,350 | grot-06 | *One join. No regrets.* |
| 16 | SLO Apprentice | 2,600 | grot-07 ⬆️ | *Error budgets: understood in theory.* |
| 17 | Log Ranger | 2,900 | grot-07 | *You've tamed LogQL. Partially.* |
| 18 | Metric Shaper | 3,200 | grot-08 ⬆️ | *Your recording rules actually record.* |
| 19 | Data Warden | 3,550 | grot-08 | *You've denied a bad dashboard its place in production.* |
| 20 | Dashboard Knight | 3,850 | grot-08 | *A junior engineer asked you for help. You had answers.* |
| 21 | Trace Sentinel | 4,200 | grot-09 ⬆️ | *You've seen a flame graph and lived.* |
| 22 | Alert Commander | 4,550 | grot-09 | *Your runbooks have been read by others.* |
| 23 | Panel Guardian | 4,900 | grot-10 ⬆️ | *Three dashboards. Zero broken links.* |
| 24 | Query Defender | 5,300 | grot-10 | *You've stopped someone from using SELECT *.* |
| 25 | Observability Veteran | 5,700 | grot-10 | *Campaigns in monitoring have shaped your panels.* |
| 26 | SLO Keeper | 6,100 | grot-11 ⬆️ | *You live by the error budget. Others benefit.* |
| 27 | Hardened Analyst | 6,500 | grot-11 | *Pages don't scare you. Much.* |
| 28 | Campaign-Worn Watcher | 6,900 | grot-12 ⬆️ | *You've survived a postmortem you didn't cause.* |
| 29 | Scarred Query Ranger | 7,350 | grot-12 | *The cardinality explosion was survivable. Barely.* |
| 30 | Battle-Tested Watcher | 7,750 | grot-13 ⬆️ | *You've on-called through a major incident. And slept after.* |
| 31 | Panel Knight | 8,200 | grot-13 | *Your team trusts your dashboards in production.* |
| 32 | Alert Cavalier | 8,650 | grot-13 | *You've silenced three false alarms and fixed the real one.* |
| 33 | Query Champion | 9,150 | grot-14 ⬆️ | *Your PromQL is being copied by others.* |
| 34 | Metric Crusader | 9,600 | grot-14 | *You've standardized labeling across a whole service.* |
| 35 | Dashboard Paladin | 10,100 | grot-15 ⬆️ | *You hold the line between chaos and visibility.* |
| 36 | Trace Commander | 10,600 | grot-15 | *You've mapped a distributed system end to end.* |
| 37 | Alert Warlord | 11,100 | grot-15 | *You wrote the runbook that saved the night.* |
| 38 | Panel Overlord | 11,600 | grot-16 ⬆️ | *People tag you in dashboard reviews.* |
| 39 | Query Marshal | 12,150 | grot-16 | *Your queries have a reputation.* |
| 40 | Data Dreadnought | 12,650 | grot-17 ⬆️ | *Cardinality fears you now.* |
| 41 | Metric Mage | 13,200 | grot-17 | *You've conjured insights from raw telemetry.* |
| 42 | Panel Sorcerer | 13,750 | grot-17 | *Transformations bend to your will.* |
| 43 | Alert Enchanter | 14,300 | grot-18 ⬆️ | *Your alerts are eerily prescient.* |
| 44 | Query Wizard | 14,850 | grot-18 | *Others call your queries 'magical'. They mean it.* |
| 45 | Dashboard Archmage | 15,450 | grot-19 ⬆️ | *Few can match your dashboard discipline.* |
| 46 | Trace Diviner | 16,050 | grot-19 | *You read spans like a map of the future.* |
| 47 | SLO Seer | 16,600 | grot-20 ⬆️ | *Your error budget forecasts are never wrong.* |
| 48 | Panel Prophet | 17,200 | grot-20 | *You predicted the outage three dashboards ago.* |
| 49 | Data Oracle | 17,850 | grot-20 | *The metrics speak. You translate.* |
| 50 | Grafana Augur | 18,450 | grot-21 ⬆️ | *Halfway through the journey. Grot is proud.* |
| 51 | Dashboard Highlord | 19,050 | grot-21 | *Lesser dashboards are renamed in your honor.* |
| 52 | Panel Suzerain | 19,700 | grot-22 ⬆️ | *You've built a dashboard that outlasted three teams.* |
| 53 | Alert High Commander | 20,350 | grot-22 | *Your alert policies are canon.* |
| 54 | Query Sovereign | 21,000 | grot-22 | *Your queries run in every environment.* |
| 55 | Metric Overlord | 21,650 | grot-23 ⬆️ | *The cardinality is under control. You did that.* |
| 56 | Elder of Panels | 22,300 | grot-23 | *You remember the before-times. Before Tempo.* |
| 57 | Ancient Alert Keeper | 23,000 | grot-24 ⬆️ | *You've seen alerting systems rise and fall.* |
| 58 | Timeworn Query Sage | 23,700 | grot-24 | *Your PRs include wisdom in the comments.* |
| 59 | Grafana Elder | 24,350 | grot-25 ⬆️ | *Newer engineers seek your counsel. You give it freely.* |
| 60 | Dashboard Ancient | 25,050 | grot-25 | *Your oldest dashboard still works. No one touches it.* |
| 61 | Mythic Trace Walker | 25,750 | grot-25 | *You've correlated a trace across 14 services.* |
| 62 | Legend of Alerts | 26,500 | grot-26 ⬆️ | *An alert you wrote paged someone at 3am. It was correct.* |
| 63 | Panel of Myths | 27,200 | grot-26 | *Stories are told of your dashboard in the oncall channel.* |
| 64 | Query of Legend | 27,950 | grot-27 ⬆️ | *Your queries are taught in onboarding.* |
| 65 | Grafana Mythborn | 28,650 | grot-27 | *Grot has carved your name into the dashboard of legends.* |
| 66 | Alert Titan | 29,400 | grot-27 | *Your presence silences noisy alerts.* |
| 67 | Dashboard Colossus | 30,150 | grot-28 ⬆️ | *Teams reorganize around your dashboards.* |
| 68 | Query Titan | 30,900 | grot-28 | *PromQL rewrites itself in your presence.* |
| 69 | Metric Giant | 31,700 | grot-29 ⬆️ | *You've invented a metric that changed how people think.* |
| 70 | Panel Behemoth | 32,450 | grot-29 | *Your panels are load-bearing for the organization.* |
| 71 | Star Panel Keeper | 33,250 | grot-29 | *Your dashboards shine like constellations.* |
| 72 | Cosmic Alert Hand | 34,000 | grot-30 ⬆️ | *Alerts align with your predictions.* |
| 73 | Nebula Query Sage | 34,800 | grot-30 | *Your queries traverse the full universe of data.* |
| 74 | Galactic Dashboard Lord | 35,600 | grot-31 ⬆️ | *The org chart curves toward your dashboards.* |
| 75 | Void Metric Walker | 36,400 | grot-31 | *You've stared into the metrics. The metrics flinched.* |
| 76 | Eternal Watcher | 37,250 | grot-32 ⬆️ | *You were here before the current stack. You'll outlast it.* |
| 77 | Undying Panel Mage | 38,050 | grot-32 | *Your dashboards are pinned in channels that predate you.* |
| 78 | Immortal Alert Sage | 38,900 | grot-32 | *Your runbooks have been translated into three languages.* |
| 79 | Timeless Query Oracle | 39,750 | grot-33 ⬆️ | *Your queries have no deprecation date.* |
| 80 | Forever Dashboard Knight | 40,550 | grot-33 | *Grot has appointed you keeper of the eternal panels.* |
| 81 | Rising Panel Mage | 41,400 | grot-34 ⬆️ | *You're not just monitoring — you're transcending it.* |
| 82 | Ascending Alert God | 42,300 | grot-34 | *Lesser engineers look up. You look through the metrics.* |
| 83 | Transcendent Query Lord | 43,150 | grot-34 | *Your queries return answers before the question is asked.* |
| 84 | Elevated Metric Being | 44,000 | grot-35 ⬆️ | *You no longer write queries. You dream them.* |
| 85 | Grafana Ascendant | 44,900 | grot-35 | *Grot speaks to you in p99 latencies.* |
| 86 | Divine Panel Keeper | 45,800 | grot-36 ⬆️ | *Your panels exist beyond the reach of cardinality.* |
| 87 | Holy Alert Watcher | 46,650 | grot-36 | *No false alarm dares fire in your presence.* |
| 88 | Sacred Query Oracle | 47,550 | grot-37 ⬆️ | *Your queries are quoted in postmortems as wisdom.* |
| 89 | Blessed Data Sage | 48,450 | grot-37 | *The data bends toward meaning when you watch.* |
| 90 | Grafana Divine | 49,400 | grot-37 | *You have become the observability you sought.* |
| 91 | Supreme Alert Being | 50,300 | grot-38 ⬆️ | *Incidents resolve before you're paged.* |
| 92 | Paramount Panel God | 51,250 | grot-38 | *Panels materialize at your thought.* |
| 93 | Absolute Query Oracle | 52,150 | grot-39 ⬆️ | *There is no query you have not written.* |
| 94 | Ultimate Metric Sage | 53,100 | grot-39 | *All metrics flow from your will.* |
| 95 | Grafana Supreme | 54,050 | grot-39 | *Grot kneels. Briefly. Then goes back to monitoring.* |
| 96 | Grot's Chosen | 55,000 | grot-40 ⬆️ | *Grot has selected you from ten thousand dashboards.* |
| 97 | Grot's Champion | 55,950 | grot-40 | *You fight for visibility. And win.* |
| 98 | Grot's Herald | 56,900 | grot-41 ⬆️ | *You announce the coming of perfect observability.* |
| 99 | Grot's Voice | 57,900 | grot-41 | *The dashboards speak through you.* |
| 100 | Grot Incarnate | 58,850 | grot-42 ⬆️ | *You and Grot are one. The dashboards bow.* |
