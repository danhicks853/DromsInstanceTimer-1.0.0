# DromsInstanceTimer

A lightweight World of Warcraft addon for the 3.3.5 client (NOT Classic) that tracks your instance entries to help you avoid hitting the 50 instances/hour server limit.

## Features
- Tracks each instance entry and shows a rolling 1-hour window.
- Minimal UI: Bar that fills as you approach the limit, or a square mode showing just the count.
- Options panel in Interface Options > AddOns for easy configuration:
  - Switch between bar and square display.
  - Adjust frame strata (layer) with a slider.
- Persistent tracking: Entries and settings are saved between sessions.
- Slash commands for quick control.

## Usage
1. **Installation:**
   - Copy the `DromsInstanceTimer` folder to your `Interface/AddOns` directory.
   - Make sure the folder contains `DromsInstanceTimer.lua` and `DromsInstanceTimer.toc`.
2. **In-game:**
   - The frame will appear when you enter an instance.
   - Use `/dit show` to show the frame, `/dit hide` to hide it.
   - Access options at `Interface Options > AddOns > DromsInstanceTimer`.
   - Change display mode, frame strata, and more from the options panel.

## Slash Commands
- `/dit show` — Show the timer UI
- `/dit hide` — Hide the timer UI
- `/dit mode bar|square` — Switch between bar and square display
- `/dit strata <strata>` — Set frame strata (BACKGROUND, LOW, MEDIUM, HIGH, DIALOG)

## How It Works
- Every time you enter an instance, the addon logs the time.
- The bar fills as you approach the 50-instance/hour limit. Each entry expires 1 hour after you entered that instance.
- All data and settings are saved between sessions.

## Requirements
- World of Warcraft 3.3.5 (WotLK, not Classic)

## Author
- Drom

---
If you encounter issues or want new features, please open an issue or contact the author.
