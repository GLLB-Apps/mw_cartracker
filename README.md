# MakeWay Tracker 🏎️

A high-performance companion app for **MakeWay**, built with Flutter. This tool is designed to help players manage their car collections, track multiplayer sessions in real-time, and visualize gameplay statistics through a responsive, game-inspired interface.

## 🚀 Key Features

### 🏎️ Collection Management & Achievements
* **Achievement Tracking:** Monitor your progress toward the "Driven All Cars" Steam achievement.
* **Smart Filtering:** Quickly sort by "Not Driven" to identify remaining requirements for 100% completion.
* **Manual Entry:** Future-proof your collection by manually adding new cars as they are released in-game.
* **Progress Visualization:** Integrated progress bars provide an immediate look at your completion status.

### ⌨️ Power User Hotkeys (Quick-Action)
The app is optimized for speed so you can keep your focus on the race:
* **Collection Page:** Bind favorite cars to slots 1-10. Press **1-9** (and **0** for the 10th slot) to instantly add **+1** to the "Times Driven" count for that car.
* **Collection Page Controls:** Use per-car **+ / -** buttons to manually adjust "Times Driven".
* **Session Page:** Use keys **1-6** to instantly assign round wins to players during live sessions. Use **Shift + 1-6** to remove a round win.
* **Session Controls:** During an active session, each player row has **+ / -** buttons for manual round adjustments.
* **Round Car Tracking:** Every +1 in an active session prompts car selection and registers it to Online Most Driven statistics.
* **Navigation:** Press **ESC** to quickly end a session and save the data to your history.

### 📊 Session & Multiplayer Tracking
* **Multiplayer Support:** Manage sessions for up to 6 players.
* **Session Templates:** Save your regular racing group as a template for 1-click session starts.
* **Visual Analytics:** Compare player performance through interactive point-distribution graphs.

### 🎨 Aesthetics & Design
* **Game-Inspired UI:** The interface is meticulously designed to follow the official MakeWay aesthetic while providing a modern, clean user experience.
* **Responsive Layout:** Optimized for various window sizes, ensuring usability on both secondary monitors and smaller displays.
* **Theming:** Full support for high-contrast Light and Dark modes.
* **Custom Branding:** Features a custom MW-inspired application logo designed specifically for this project.

## 🛠️ Installation & Usage

1.  Navigate to the [Releases](https://github.com/GLLB-Apps/mw_cartracker/tags) page.
2.  Download the latest version (ZIP).
3.  Extract the folder to your preferred location.
4.  Run `mw_cartracker.exe`.

*Note: If Windows Defender flags the app, click "More Info" -> "Run Anyway" as the executable is currently unsigned.*

## Roadmap
- [x] ~~**Function Key Navigation:** Implement F1-F4 shortcuts for instantaneous switching between app modules.~~
- [x] ~~**Background Controls:** Enable keyboard shortcuts to update the app without needing to Alt+Tab out of MakeWay.~~
- [ ] **Automated Car Updates:** Remote parsing to auto-sync new car releases via a web-hosted manifest.
- [x] ~~**Auto-Updater:** Implement automatic app updates based on Git tags/releases.~~
- [ ] **Live Sync:** Real-time session synchronization logic.
- [ ] **Note Search:** Enhanced collection filtering based on user-added notes.
- [x] ~~**Session Hover Stats:** Display all driven cars + count when hovering over player session stats bar.~~
- [x] ~~**Car Selection on Stat Increment:** When adding +1 stat, prompt user to select which car was driven that round and register to statistics.~~
- [ ] **Zero Collection Handler:** When collection count is 0, open modal to select car -> decrease drive count for that car by 1.
- [x] ~~**Most Driven Car Stats:** Add statistics tab showing most driven car (separate views for Offline/Online).~~
- [ ] **Win Rate by Car:** Display percentage statistics for which car has the highest win rate.
- [x] ~~**Manual Drive Counter:** Add manual +/- buttons per car for adjusting drive counts.~~
- [ ] **Dark Mode Fix:** Resolve layout issues in dark mode for live sessions view.
- [x] ~~**Manual Round Controls:** Add +/- buttons to manually adjust won rounds for each player.~~
- [x] ~~**Keyboard Number Display:** Show visual indicators in UI mapping keyboard numbers (1-4) to corresponding players.~~


## ⚖️ Disclaimer
This is a fan-made project and is not officially affiliated with Ice Beam Games. All game-related assets and names are property of their respective owners.

---
Developed with ❤️ by **David (DawweMan)** *Find me on Discord: DawweMan*
